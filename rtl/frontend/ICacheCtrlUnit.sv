// 手写可读 SV：ICache 控制单元核心 —— xs_ICacheCtrlUnit_core
//
// 功能：通过 TileLink-UL 寄存器映射（RegMapper）暴露 ECC 控制/注入接口。
//   - 三组寄存器（按 8 字节地址索引 index = addr[6:3]）：
//       index 0 -> eccctrl  (enable / itarget / istatus / ierror)
//       index 1 -> ecciaddr (paddr[47:0])
//       index>=2 (本配置仅用到 0/1) -> iwaymask（只读回 0，注入选中的 waymask 在内部）
//   - 写 eccctrl.inject=1 触发 ECC 注入 FSM（istate）：
//       读 meta -> 比较 ptag 选 way -> 写 meta 或写 data 注错。
//
// 寄存器名沿用 golden（eccctrl_*/ecciaddr_paddr/iwaymask/istate）以便 Formality 配对。
// 端口名与 golden ICacheCtrlUnit 完全一致。RegMapper 的输入队列在外层例化
// （Queue1_RegMapperInput_3），核心通过 deq 通道与之交互。

module xs_ICacheCtrlUnit_core #(
  parameter NWAY      = 4,   // ICache 路数
  parameter PADDR_W   = 48,  // 物理地址位宽（ecciaddr）
  parameter PTAG_W    = 36,  // 物理 tag 位宽
  parameter VSETIDX_W = 8,   // 虚 set index 位宽
  parameter INDEX_W   = 4,   // RegMapper 寄存器索引位宽
  parameter DATA_W    = 64,  // TileLink data 位宽
  parameter MASK_W    = 8    // TileLink mask 位宽
) (
  input                  clock,
  input                  reset,

  // ---- RegMapper 输出队列 deq 侧（A 通道经队列解码后的请求）----
  input                  out_deq_valid,
  input                  out_deq_bits_read,
  input  [INDEX_W-1:0]   out_deq_bits_index,
  input  [DATA_W-1:0]    out_deq_bits_data,
  input  [MASK_W-1:0]    out_deq_bits_mask,
  input                  auto_in_d_ready,        // D 通道下游 ready

  // ---- D 通道读响应数据（由本核心组合产生）----
  output [DATA_W-1:0]    auto_in_d_bits_data,

  // ---- ECC 状态/注入接口 ----
  output                 io_ecc_enable,
  output                 io_injecting,

  // meta 读
  input                  io_metaRead_ready,
  output                 io_metaRead_valid,
  output [VSETIDX_W-1:0] io_metaRead_bits_vSetIdx_0,
  output [VSETIDX_W-1:0] io_metaRead_bits_vSetIdx_1,
  input  [PTAG_W-1:0]    io_metaReadResp_metas_0_0_tag,
  input  [PTAG_W-1:0]    io_metaReadResp_metas_0_1_tag,
  input  [PTAG_W-1:0]    io_metaReadResp_metas_0_2_tag,
  input  [PTAG_W-1:0]    io_metaReadResp_metas_0_3_tag,
  input                  io_metaReadResp_entryValid_0_0,
  input                  io_metaReadResp_entryValid_0_1,
  input                  io_metaReadResp_entryValid_0_2,
  input                  io_metaReadResp_entryValid_0_3,

  // meta 写（注错到 tag）
  input                  io_metaWrite_ready,
  output                 io_metaWrite_valid,
  output [VSETIDX_W-1:0] io_metaWrite_bits_virIdx,
  output [PTAG_W-1:0]    io_metaWrite_bits_phyTag,
  output [NWAY-1:0]      io_metaWrite_bits_waymask,
  output                 io_metaWrite_bits_bankIdx,

  // data 写（注错到 data）
  input                  io_dataWrite_ready,
  output                 io_dataWrite_valid,
  output [VSETIDX_W-1:0] io_dataWrite_bits_virIdx,
  output [NWAY-1:0]      io_dataWrite_bits_waymask
);

  // ----------------------------------------------------------------------
  // eccctrl 位定义（写 data[0]=enable/inject 触发位、data[1]=注入使能、
  //                  data[3:2]=itarget）
  //   itarget == 0 -> 注 meta（tag）；否则注 data
  // istatus 编码：0=idle, 1=working(injecting), 2=injected(done ok),
  //               7=error/non-inject 完成
  // ierror  编码：0=无错, 1=参数非法, 2=未命中
  // ----------------------------------------------------------------------
  localparam [2:0] ST_IDLE     = 3'h0;
  localparam [2:0] ST_WORKING  = 3'h1;
  localparam [2:0] ST_INJECTED = 3'h2;
  localparam [2:0] ST_ERROR    = 3'h7;

  localparam [2:0] IERR_NONE  = 3'h0;
  localparam [2:0] IERR_PARAM = 3'h1;
  localparam [2:0] IERR_MISS  = 3'h2;

  // 注入 FSM 状态
  localparam [2:0] INJ_IDLE   = 3'h0;  // 等待 injecting
  localparam [2:0] INJ_READ   = 3'h1;  // 发 meta 读
  localparam [2:0] INJ_SELECT = 3'h2;  // 比较 tag 选 way
  localparam [2:0] INJ_WMETA  = 3'h3;  // 写 meta
  localparam [2:0] INJ_WDATA  = 3'h4;  // 写 data

  // ----------------------------------------------------------------------
  // 寄存器声明（名字沿用 golden）
  // ----------------------------------------------------------------------
  reg  [2:0]         eccctrl_ierror;
  reg  [2:0]         eccctrl_istatus;
  reg  [1:0]         eccctrl_itarget;
  reg                eccctrl_enable;
  reg  [PADDR_W-1:0] ecciaddr_paddr;
  reg  [NWAY-1:0]    iwaymask;
  reg  [2:0]         istate;

  // ----------------------------------------------------------------------
  // 状态/输出译码
  // ----------------------------------------------------------------------
  wire io_injecting_0     = (eccctrl_istatus == ST_WORKING);
  wire io_metaRead_valid_0  = (istate == INJ_READ);
  wire io_metaWrite_valid_0 = (istate == INJ_WMETA);
  wire io_dataWrite_valid_0 = (istate == INJ_WDATA);

  // ----------------------------------------------------------------------
  // RegMapper 写/读触发条件
  //   - index[3:1]==0 选中 eccctrl(index0) 或 ecciaddr(index1)
  //   - 字节使能须全 1（&mask）才认作合法寄存器写
  //   - 写命中(out_f_woready)：index0、全掩码、deq 握手且非读
  // ----------------------------------------------------------------------
  wire        sel_lowregs   = (out_deq_bits_index[3:1] == 3'h0); // index ∈ {0,1}
  wire        deq_fire      = out_deq_valid & auto_in_d_ready;
  wire        deq_fire_wr   = deq_fire & ~out_deq_bits_read;

  wire [DATA_W-1:0] out_backMask = {
    {8{out_deq_bits_mask[7]}}, {8{out_deq_bits_mask[6]}},
    {8{out_deq_bits_mask[5]}}, {8{out_deq_bits_mask[4]}},
    {8{out_deq_bits_mask[3]}}, {8{out_deq_bits_mask[2]}},
    {8{out_deq_bits_mask[1]}}, {8{out_deq_bits_mask[0]}}
  };
  wire all_mask = (&out_backMask);

  // 写 eccctrl（index0）：全掩码、index 偶、命中低寄存器区
  wire write_eccctrl = deq_fire_wr & ~out_deq_bits_index[0] & sel_lowregs & all_mask;
  // 写 ecciaddr（index1）
  wire write_ecciaddr = deq_fire_wr & out_deq_bits_index[0] & sel_lowregs & all_mask;

  // 读 eccctrl 且 istatus 处于完成态（2 或 7）：读动作清状态/错误
  wire read_eccctrl_done = deq_fire & out_deq_bits_read & ~out_deq_bits_index[0]
                           & sel_lowregs & (|out_backMask)
                           & (eccctrl_istatus == ST_INJECTED | (&eccctrl_istatus));

  // 写 eccctrl 数据语义
  wire wdata_inject_bit = out_deq_bits_data[0]; // enable & inject 触发
  wire wdata_inj_en     = out_deq_bits_data[1]; // 注入命令使能
  // itarget 非法判定：data[3:2] 非 0 且非 2（合法仅 0=meta, 2=data）
  wire itarget_illegal  = (|out_deq_bits_data[3:2]) & (out_deq_bits_data[3:2] != 2'h2);

  // ----------------------------------------------------------------------
  // 注入 FSM 中间量
  // ----------------------------------------------------------------------
  wire st_idle    = (istate == INJ_IDLE);
  wire st_read    = (istate == INJ_READ);
  wire st_select  = (istate == INJ_SELECT);

  // 比较 ptag 选中命中的 way（entryValid 且 tag 匹配 ecciaddr 的 ptag 段）
  wire [NWAY-1:0] waymask = {
    io_metaReadResp_entryValid_0_3 & (io_metaReadResp_metas_0_3_tag == ecciaddr_paddr[PADDR_W-1:12]),
    io_metaReadResp_entryValid_0_2 & (io_metaReadResp_metas_0_2_tag == ecciaddr_paddr[PADDR_W-1:12]),
    io_metaReadResp_entryValid_0_1 & (io_metaReadResp_metas_0_1_tag == ecciaddr_paddr[PADDR_W-1:12]),
    io_metaReadResp_entryValid_0_0 & (io_metaReadResp_metas_0_0_tag == ecciaddr_paddr[PADDR_W-1:12])
  };
  wire no_hit = (waymask == {NWAY{1'b0}});

  // 是否处于「不更新 ierror=MISS」的状态（idle/read，或不是 select-且-miss）
  wire idle_or_read = st_idle | st_read;
  wire keep_ierror  = idle_or_read | ~(st_select & no_hit);

  // 写阶段握手完成（meta 或 data 写）
  wire inj_write_done =
      (istate == INJ_WMETA) ? (io_metaWrite_ready & io_metaWrite_valid_0)
                            : (istate == INJ_WDATA) & io_dataWrite_ready & io_dataWrite_valid_0;

  // ----------------------------------------------------------------------
  // 寄存器更新：eccctrl_ierror / eccctrl_istatus
  //   结构对齐 golden，避免 FM 把条件赋值判不等价。
  // ----------------------------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      eccctrl_ierror  <= IERR_NONE;
      eccctrl_istatus <= ST_IDLE;
    end
    else begin
      if (write_eccctrl & wdata_inj_en & (eccctrl_istatus == ST_IDLE)) begin
        // 软件下发注入命令
        if (wdata_inject_bit) begin
          if (itarget_illegal)
            eccctrl_ierror <= IERR_PARAM;
          else if (read_eccctrl_done)
            eccctrl_ierror <= IERR_NONE;
          else if (keep_ierror) begin
            // 保持
          end
          else
            eccctrl_ierror <= IERR_MISS;
        end
        else
          eccctrl_ierror <= IERR_NONE;
        eccctrl_istatus <= (~wdata_inject_bit | itarget_illegal) ? ST_ERROR : ST_WORKING;
      end
      else if (read_eccctrl_done) begin
        // 读完成态：清错、回 idle
        eccctrl_ierror  <= IERR_NONE;
        eccctrl_istatus <= ST_IDLE;
      end
      else begin
        if (keep_ierror) begin
          // 保持
        end
        else
          eccctrl_ierror <= IERR_MISS;
        if (~idle_or_read) begin
          if (st_select) begin
            if (no_hit)
              eccctrl_istatus <= ST_ERROR;
          end
          else if (inj_write_done)
            eccctrl_istatus <= ST_INJECTED;
        end
      end
    end
  end

  // ----------------------------------------------------------------------
  // eccctrl_itarget / eccctrl_enable：仅写 eccctrl 时更新
  // ----------------------------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      eccctrl_itarget <= 2'h0;
      eccctrl_enable  <= 1'h1;
    end
    else if (write_eccctrl) begin
      eccctrl_itarget <= out_deq_bits_data[3:2];
      eccctrl_enable  <= out_deq_bits_data[0];
    end
  end

  // ----------------------------------------------------------------------
  // ecciaddr_paddr：仅写 ecciaddr 时更新
  // ----------------------------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset)
      ecciaddr_paddr <= {PADDR_W{1'b0}};
    else if (write_ecciaddr)
      ecciaddr_paddr <= out_deq_bits_data[PADDR_W-1:0];
  end

  // ----------------------------------------------------------------------
  // iwaymask：在 select 态锁存命中 waymask
  // ----------------------------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset)
      iwaymask <= {NWAY{1'b0}};
    else if (st_select)
      iwaymask <= waymask;
  end

  // ----------------------------------------------------------------------
  // 注入 FSM：istate
  // ----------------------------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset)
      istate <= INJ_IDLE;
    else begin
      if (st_idle) begin
        if (io_injecting_0)
          istate <= INJ_READ;
      end
      else if (st_read) begin
        if (io_metaRead_ready & io_metaRead_valid_0)
          istate <= INJ_SELECT;
      end
      else if (st_select)
        istate <= no_hit ? INJ_IDLE
                         : (eccctrl_itarget == 2'h0) ? INJ_WMETA : INJ_WDATA;
      else if (inj_write_done)
        istate <= INJ_IDLE;
    end
  end

  // ----------------------------------------------------------------------
  // D 通道读数据：index1 回 ecciaddr，index0 回 eccctrl 打包，其它回 0
  //   eccctrl 打包：{..., ierror, istatus, itarget, 1'h0, enable}
  // ----------------------------------------------------------------------
  assign auto_in_d_bits_data =
      sel_lowregs
        ? (out_deq_bits_index[0]
             ? {{(DATA_W-PADDR_W){1'b0}}, ecciaddr_paddr}
             : {{(DATA_W-10){1'b0}}, eccctrl_ierror, eccctrl_istatus,
                eccctrl_itarget, 1'h0, eccctrl_enable})
        : {DATA_W{1'b0}};

  // ----------------------------------------------------------------------
  // 输出赋值
  // ----------------------------------------------------------------------
  assign io_ecc_enable               = eccctrl_enable;
  assign io_injecting                = io_injecting_0;
  assign io_metaRead_valid           = io_metaRead_valid_0;
  assign io_metaRead_bits_vSetIdx_0  = ecciaddr_paddr[13:6];
  assign io_metaRead_bits_vSetIdx_1  = ecciaddr_paddr[13:6];
  assign io_metaWrite_valid          = io_metaWrite_valid_0;
  assign io_metaWrite_bits_virIdx    = ecciaddr_paddr[13:6];
  assign io_metaWrite_bits_phyTag    = ecciaddr_paddr[PADDR_W-1:12];
  assign io_metaWrite_bits_waymask   = iwaymask;
  assign io_metaWrite_bits_bankIdx   = ecciaddr_paddr[6];
  assign io_dataWrite_valid          = io_dataWrite_valid_0;
  assign io_dataWrite_bits_virIdx    = ecciaddr_paddr[13:6];
  assign io_dataWrite_bits_waymask   = iwaymask;

endmodule

// ----------------------------------------------------------------------------
// RegMapper 输入队列（深度 1）—— golden 同名 Queue1_RegMapperInput_3 的可读重写
//   单槽 skid buffer：full 标志 + 81:0 打包寄存器。
//   payload 打包顺序（低->高）：read, index[4], data[64], mask[8], source[3], size[2]
// ----------------------------------------------------------------------------
module xs_Queue1_RegMapperInput #(
  parameter INDEX_W  = 4,
  parameter DATA_W   = 64,
  parameter MASK_W   = 8,
  parameter SOURCE_W = 3,
  parameter SIZE_W   = 2
) (
  input                 clock,
  input                 reset,
  output                io_enq_ready,
  input                 io_enq_valid,
  input                 io_enq_bits_read,
  input  [INDEX_W-1:0]  io_enq_bits_index,
  input  [DATA_W-1:0]   io_enq_bits_data,
  input  [MASK_W-1:0]   io_enq_bits_mask,
  input  [SOURCE_W-1:0] io_enq_bits_extra_tlrr_extra_source,
  input  [SIZE_W-1:0]   io_enq_bits_extra_tlrr_extra_size,
  input                 io_deq_ready,
  output                io_deq_valid,
  output                io_deq_bits_read,
  output [INDEX_W-1:0]  io_deq_bits_index,
  output [DATA_W-1:0]   io_deq_bits_data,
  output [MASK_W-1:0]   io_deq_bits_mask,
  output [SOURCE_W-1:0] io_deq_bits_extra_tlrr_extra_source,
  output [SIZE_W-1:0]   io_deq_bits_extra_tlrr_extra_size
);

  localparam RAM_W = SIZE_W + SOURCE_W + MASK_W + DATA_W + INDEX_W + 1;

  reg [RAM_W-1:0] ram;
  reg             full;

  wire do_enq = ~full & io_enq_valid;

  // 数据槽：enq 命中时锁存打包后的 payload
  always @(posedge clock) begin
    if (do_enq)
      ram <= {io_enq_bits_extra_tlrr_extra_size,
              io_enq_bits_extra_tlrr_extra_source,
              io_enq_bits_mask,
              io_enq_bits_data,
              io_enq_bits_index,
              io_enq_bits_read};
  end

  // full 标志：enq 与 (deq_ready & full) 不同步时才翻转为 do_enq
  always @(posedge clock or posedge reset) begin
    if (reset)
      full <= 1'h0;
    else if (~(do_enq == (io_deq_ready & full)))
      full <= do_enq;
  end

  assign io_enq_ready = ~full;
  assign io_deq_valid = full;
  assign io_deq_bits_read                    = ram[0];
  assign io_deq_bits_index                   = ram[INDEX_W:1];
  assign io_deq_bits_data                    = ram[INDEX_W+DATA_W:INDEX_W+1];
  assign io_deq_bits_mask                    = ram[INDEX_W+DATA_W+MASK_W:INDEX_W+DATA_W+1];
  assign io_deq_bits_extra_tlrr_extra_source = ram[INDEX_W+DATA_W+MASK_W+SOURCE_W:INDEX_W+DATA_W+MASK_W+1];
  assign io_deq_bits_extra_tlrr_extra_size   = ram[RAM_W-1:INDEX_W+DATA_W+MASK_W+SOURCE_W+1];

endmodule
