// =============================================================================
// xs_ICacheCtrlUnit_core —— ICache ECC 控制 / 错误注入单元（核心）
//
// 对应 Chisel: xiangshan.frontend.icache.ICacheCtrlUnit（ICacheCtrlUnit.scala）
//
// 【它在前端的位置 / 为什么存在】
//   ICache 的 meta/data SRAM 都带 ECC。为了在硅后/仿真里验证「ECC 检错-纠错-上报」整条
//   通路，需要一个能**主动往某个 cacheline 注入 ECC 错误**的旁路单元。ICacheCtrlUnit 就是
//   它：以一条 TileLink-UL（uncached lightweight）总线挂在 ICache 旁，由 M 模式软件通过
//   读写两个 MMIO 寄存器来 (1) 开关 ECC、(2) 指定注入地址、(3) 触发一次注入。
//
//     软件 ──TileLink A/D──▶ [ RegMapper 寄存器 ] ──注入命令──▶ 注入 FSM
//                                                                  │
//                          io_metaRead ◀────读 meta 选命中路───────┤
//                          io_metaWrite/io_dataWrite ─写"中毒"项──▶ ICache SRAM
//
//   注入手段是给目标 way 的 meta 或 data 写一条 poison=1 的表项：SRAM 的写通路会按
//   poison 故意翻坏 ECC 校验位，于是下次正常读到该 line 时 ECC 就会报错。
//
// 【两大功能块】
//   1. 寄存器读写：把 RegMapper 解码出的读/写请求作用到 2 个寄存器
//        offset 0 (index 偶) -> eccctrl  : ECC 开关 + 注入控制/状态
//        offset 8 (index 奇) -> ecciaddr : 注入目标物理地址
//      并在 D 通道组合产生读回数据（AccessAckData）。
//   2. 注入 FSM (inject_state)：软件写下"注入"命令后自动执行
//        读 meta → 按 ptag 选命中路 → 写 meta 或写 data 注错。
//
// 【寄存器映射的"valid/ready"语义（RegMapper 协议）】
//   本设计端口接的是 RegMapper 把 TileLink A 通道解析后的统一请求（经一个深度 1 队列缓存）：
//     req_valid / req_is_read / req_index(=addr[6:3]) / req_wdata / req_byte_mask。
//   一次寄存器**写**只有在"请求触发(req_fire) 且 非读 且 选中该寄存器 且 字节掩码全 1"时
//   才生效（RegField 要求字段被掩码完整覆盖）；**读**总是允许，并在读完成的同拍可附带副作用
//   （读 eccctrl 会清掉已完成/出错的 istatus）。
// =============================================================================
module xs_ICacheCtrlUnit_core #(
  parameter int unsigned NWAY      = 4,   // ICache 组相联路数
  parameter int unsigned PADDR_W   = 48,  // 物理地址位宽（ecciaddr.paddr）
  parameter int unsigned PTAG_W    = 36,  // 物理 tag 位宽
  parameter int unsigned VSETIDX_W = 8,   // 虚拟 set index 位宽
  parameter int unsigned INDEX_W   = 4,   // RegMapper 寄存器索引位宽（addr[6:3]）
  parameter int unsigned DATA_W    = 64,  // TileLink data 位宽
  parameter int unsigned MASK_W    = 8    // TileLink byte mask 位宽
) (
  input  logic                 clock,
  input  logic                 reset,

  // ---- RegMapper 请求（A 通道经深度 1 队列解码后的统一形式）----
  input  logic                 req_valid,      // 队列有一笔待处理请求
  input  logic                 req_is_read,    // 1=读(Get) / 0=写(Put)
  input  logic [INDEX_W-1:0]   req_index,      // 寄存器索引 = paddr[6:3]
  input  logic [DATA_W-1:0]    req_wdata,      // 写数据
  input  logic [MASK_W-1:0]    req_byte_mask,  // 字节使能
  input  logic                 resp_ready,     // D 通道下游 ready（请求"完成"的握手条件）

  // ---- D 通道读回数据（组合产生；AccessAckData 的 payload）----
  output logic [DATA_W-1:0]    resp_rdata,

  // ---- ECC 控制输出 ----
  output logic                 io_ecc_enable,  // ECC 检查总开关 → ICache
  output logic                 io_injecting,   // 注入进行中（istatus==working）

  // ---- 注入：读 meta（取出该 set 各路的 valid/tag 以选命中路）----
  input  logic                 io_metaRead_ready,
  output logic                 io_metaRead_valid,
  output logic [VSETIDX_W-1:0] io_metaRead_bits_vSetIdx_0,
  output logic [VSETIDX_W-1:0] io_metaRead_bits_vSetIdx_1,
  input  logic [PTAG_W-1:0]    io_metaReadResp_metas_0_0_tag,
  input  logic [PTAG_W-1:0]    io_metaReadResp_metas_0_1_tag,
  input  logic [PTAG_W-1:0]    io_metaReadResp_metas_0_2_tag,
  input  logic [PTAG_W-1:0]    io_metaReadResp_metas_0_3_tag,
  input  logic                 io_metaReadResp_entryValid_0_0,
  input  logic                 io_metaReadResp_entryValid_0_1,
  input  logic                 io_metaReadResp_entryValid_0_2,
  input  logic                 io_metaReadResp_entryValid_0_3,

  // ---- 注入：写 meta（往命中路写 poison tag，注错到 meta 阵列）----
  input  logic                 io_metaWrite_ready,
  output logic                 io_metaWrite_valid,
  output logic [VSETIDX_W-1:0] io_metaWrite_bits_virIdx,
  output logic [PTAG_W-1:0]    io_metaWrite_bits_phyTag,
  output logic [NWAY-1:0]      io_metaWrite_bits_waymask,
  output logic                 io_metaWrite_bits_bankIdx,

  // ---- 注入：写 data（往命中路写 poison data，注错到 data 阵列）----
  input  logic                 io_dataWrite_ready,
  output logic                 io_dataWrite_valid,
  output logic [VSETIDX_W-1:0] io_dataWrite_bits_virIdx,
  output logic [NWAY-1:0]      io_dataWrite_bits_waymask
);

  // ---------------------------------------------------------------------------
  // eccctrl 寄存器的子字段编码（来自 Scala 的 NamedUInt 枚举）
  // ---------------------------------------------------------------------------

  // istatus：注入状态机对软件可见的"业务状态"（与下方 inject_state 区分：istatus 是
  // 软件接口语义，working 期间内部 inject_state 还会走 read/select/write 几个微步）。
  typedef enum logic [2:0] {
    INJ_STATUS_IDLE     = 3'd0,  // 空闲，可接受新的注入命令
    INJ_STATUS_WORKING  = 3'd1,  // 注入进行中（驱动 io_injecting）
    INJ_STATUS_INJECTED = 3'd2,  // 注入成功完成（读 eccctrl 后自动清回 idle）
    INJ_STATUS_ERROR    = 3'd7   // 注入因命令非法/未命中而失败（读后自动清）
  } inj_status_e;

  // ierror：当 istatus==error 时给出的失败原因
  typedef enum logic [2:0] {
    INJ_ERR_NOT_ENABLED  = 3'd0, // ECC 未开启就想注入 / 无错
    INJ_ERR_TARGET_INVAL = 3'd1, // itarget 非法（既非 meta 也非 data）
    INJ_ERR_NOT_FOUND    = 3'd2  // ecciaddr 指向的 line 不在 ICache 里（选 way 未命中）
  } inj_error_e;

  // itarget：注入目标阵列（注意 dataArray 编码为 2，1/3 为 rsvd 非法）
  typedef enum logic [1:0] {
    INJ_TARGET_META = 2'd0,
    INJ_TARGET_DATA = 2'd2
  } inj_target_e;

  // 注入 FSM 的内部微状态（istatus==working 期间逐步推进）
  typedef enum logic [2:0] {
    S_IDLE         = 3'd0,  // 等软件下注入命令（istatus 跳 working）
    S_READ_META    = 3'd1,  // 发 metaRead，读该 set 各路 meta
    S_SELECT_WAY   = 3'd2,  // 用 metaResp 比 tag 选命中路、锁存 waymask
    S_WRITE_META   = 3'd3,  // 注 meta：写 poison tag
    S_WRITE_DATA   = 3'd4   // 注 data：写 poison data
  } inject_state_e;

  // ---------------------------------------------------------------------------
  // eccctrl 寄存器：拆成有含义的字段（Chisel 的 eccctrlBundle）
  //   软件可写 enable / itarget；inject 是 write-only 触发位（读恒 0）；
  //   istatus / ierror 是 read-only 状态位（软件写被忽略）。
  // ---------------------------------------------------------------------------
  inj_error_e   ecc_inject_error;    // ierror，复位 not_enabled
  inj_status_e  ecc_inject_status;   // istatus，复位 idle
  inj_target_e  ecc_inject_target;   // itarget，复位 meta
  logic         ecc_enable;          // enable，复位 1（ECC 默认开）

  // ecciaddr 寄存器：注入目标物理地址
  logic [PADDR_W-1:0] ecc_inject_paddr;

  // 注入选中的命中路 one-hot：S_SELECT_WAY 锁存，供后续写 meta/data 用
  logic [NWAY-1:0]    inject_waymask;

  // 注入 FSM 状态
  inject_state_e      inject_state;

  // ---------------------------------------------------------------------------
  // 注入地址的字段切分（与 ICache get_idx/get_tag 一致）
  //   vSetIdx = paddr[13:6]、phyTag = paddr[47:12]、bankIdx = paddr[6]
  // ---------------------------------------------------------------------------
  logic [VSETIDX_W-1:0] inject_vset_idx;
  logic [PTAG_W-1:0]    inject_phy_tag;
  logic                 inject_bank_idx;
  assign inject_vset_idx = ecc_inject_paddr[6 +: VSETIDX_W]; // [13:6]
  assign inject_phy_tag  = ecc_inject_paddr[PADDR_W-1:12];   // [47:12]
  assign inject_bank_idx = ecc_inject_paddr[6];

  // ---------------------------------------------------------------------------
  // RegMapper 访问解码
  //   一次请求"完成"= req_valid 且 D 通道 ready（resp_ready），此时该笔出队。
  //   index[3:1]==0 选中低 2 个寄存器（index 0=eccctrl / 1=ecciaddr）；其余地址无寄存器。
  //   写需字节掩码全 1（字段被完整覆盖）；读只要任一字节使能即可。
  // ---------------------------------------------------------------------------
  logic sel_low_regs;   // 命中 eccctrl/ecciaddr 这一对寄存器
  logic req_fire;       // 该请求本拍完成
  logic write_fire;     // 完成且为写
  logic mask_full;      // 字节掩码全 1
  logic mask_any;       // 字节掩码任一位为 1

  assign sel_low_regs = (req_index[INDEX_W-1:1] == '0);
  assign req_fire     = req_valid & resp_ready;
  assign write_fire   = req_fire & ~req_is_read;
  assign mask_full    = (&req_byte_mask);
  assign mask_any     = (|req_byte_mask);

  // 对 eccctrl(index 偶) / ecciaddr(index 奇) 的合法写
  logic write_eccctrl;
  logic write_ecciaddr;
  assign write_eccctrl  = write_fire & ~req_index[0] & sel_low_regs & mask_full;
  assign write_ecciaddr = write_fire &  req_index[0] & sel_low_regs & mask_full;

  // 对 eccctrl 的读：读完成且当前 istatus 处于"已完成/出错"态时，读动作顺带清状态
  // （RegReadFn 的 ready 回调里 when(injected||error) 清回 idle/not_enabled）。
  logic read_eccctrl_clears;
  assign read_eccctrl_clears = req_fire & req_is_read & ~req_index[0] & sel_low_regs
                             & mask_any
                             & ((ecc_inject_status == INJ_STATUS_INJECTED) |
                                (ecc_inject_status == INJ_STATUS_ERROR));

  // 写 eccctrl 时的数据语义（见模块头：enable=bit0, inject=bit1, itarget=bit[3:2]）
  logic       wr_enable;       // req.enable
  logic       wr_inject;       // req.inject（write-only 触发）
  logic [1:0] wr_target;       // req.itarget
  logic       wr_target_bad;   // itarget 非法：既非 meta(0) 也非 data(2)
  assign wr_enable     = req_wdata[0];
  assign wr_inject     = req_wdata[1];
  assign wr_target     = req_wdata[3:2];
  assign wr_target_bad = (wr_target != INJ_TARGET_META) & (wr_target != INJ_TARGET_DATA);

  // 软件刚下发一条"注入"命令（inject=1 且当前 idle，否则忽略重复触发）
  logic inject_cmd;
  assign inject_cmd = write_eccctrl & wr_inject & (ecc_inject_status == INJ_STATUS_IDLE);

  // ---------------------------------------------------------------------------
  // 注入 FSM 组合量
  // ---------------------------------------------------------------------------
  // 用 metaReadResp 选命中路：该路 valid 且其 tag == 注入地址的 phyTag
  logic [NWAY-1:0] hit_waymask;
  assign hit_waymask[0] = io_metaReadResp_entryValid_0_0 & (io_metaReadResp_metas_0_0_tag == inject_phy_tag);
  assign hit_waymask[1] = io_metaReadResp_entryValid_0_1 & (io_metaReadResp_metas_0_1_tag == inject_phy_tag);
  assign hit_waymask[2] = io_metaReadResp_entryValid_0_2 & (io_metaReadResp_metas_0_2_tag == inject_phy_tag);
  assign hit_waymask[3] = io_metaReadResp_entryValid_0_3 & (io_metaReadResp_metas_0_3_tag == inject_phy_tag);

  logic inject_miss;  // select 阶段没有任何命中路 → 拒绝注入
  assign inject_miss = ~(|hit_waymask);

  // 当前是否处于"会把 ierror 置成 not_found"的情形：仅 S_SELECT_WAY 且 miss
  // （其余拍 ierror 维持原值，对齐 Scala 里只有该分支写 ierror=notFound）
  logic in_select_miss;
  assign in_select_miss = (inject_state == S_SELECT_WAY) & inject_miss;

  // 写阶段的握手完成（meta 或 data 写被下游接受）
  logic meta_write_done;
  logic data_write_done;
  assign meta_write_done = (inject_state == S_WRITE_META) & io_metaWrite_ready & io_metaWrite_valid;
  assign data_write_done = (inject_state == S_WRITE_DATA) & io_dataWrite_ready & io_dataWrite_valid;

  // ---------------------------------------------------------------------------
  // 输出 valid：注入 FSM 在对应微步驱动各通道
  // ---------------------------------------------------------------------------
  assign io_injecting       = (ecc_inject_status == INJ_STATUS_WORKING);
  assign io_metaRead_valid  = (inject_state == S_READ_META);
  assign io_metaWrite_valid = (inject_state == S_WRITE_META);
  assign io_dataWrite_valid = (inject_state == S_WRITE_DATA);

  // ===========================================================================
  // 时序：ecc_enable / ecc_inject_target —— 仅在写 eccctrl 时更新
  //   Scala: 无条件 x.enable := req.enable; x.itarget := req.itarget（在 valid 写下）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      ecc_enable        <= 1'b1;            // ECC 默认开
      ecc_inject_target <= INJ_TARGET_META;
    end
    else if (write_eccctrl) begin
      ecc_enable        <= wr_enable;
      ecc_inject_target <= inj_target_e'(wr_target);
    end
  end

  // ===========================================================================
  // 时序：ecc_inject_paddr —— 仅在写 ecciaddr 时更新
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      ecc_inject_paddr <= '0;
    else if (write_ecciaddr)
      ecc_inject_paddr <= req_wdata[PADDR_W-1:0];
  end

  // ===========================================================================
  // 时序：inject_waymask —— S_SELECT_WAY 拍锁存命中路，供后续写阶段使用
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      inject_waymask <= '0;
    else if (inject_state == S_SELECT_WAY)
      inject_waymask <= hit_waymask;
  end

  // ===========================================================================
  // 时序：注入 FSM（inject_state）
  //   idle: istatus 被命令置 working 后启动；
  //   read: metaRead 握手后进 select；
  //   select: 命中→按 itarget 去写 meta/data，未命中→回 idle（istatus 那侧记 error）；
  //   write_*: 握手完成→回 idle。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      inject_state <= S_IDLE;
    else begin
      // 注意：未列出的状态（含无法到达的 5..7）保持原值，不强制回 IDLE——
      // 这与 golden 一致（golden 对这些状态无 else 分支即保持），是 FM 等价的关键。
      case (inject_state)
        S_IDLE:
          if (ecc_inject_status == INJ_STATUS_WORKING)
            inject_state <= S_READ_META;
        S_READ_META:
          if (io_metaRead_ready & io_metaRead_valid)
            inject_state <= S_SELECT_WAY;
        S_SELECT_WAY:
          inject_state <= inject_miss ? S_IDLE
                        : (ecc_inject_target == INJ_TARGET_META) ? S_WRITE_META
                                                                 : S_WRITE_DATA;
        S_WRITE_META:
          if (meta_write_done) inject_state <= S_IDLE;
        S_WRITE_DATA:
          if (data_write_done) inject_state <= S_IDLE;
        default: ; // 保持
      endcase
    end
  end

  // ===========================================================================
  // 时序：ecc_inject_status / ecc_inject_error
  //
  //   istatus/ierror 由两路驱动，且必须共用一段以匹配 Scala 里的优先级：
  //     (A) 软件写 eccctrl 下发注入命令（inject_cmd）：
  //         - inject=1 但 enable=0 → error / not_enabled
  //         - itarget 非法           → error / target_invalid
  //         - 否则                   → working（启动 FSM）
  //         注意：Scala 用 req.enable 而非寄存器 enable 判 not_enabled。
  //     (B) 读 eccctrl 清状态（read_eccctrl_clears）：→ idle / not_enabled
  //     (C) 注入 FSM 推进：
  //         - select 且未命中        → error / not_found
  //         - write_* 握手完成        → injected
  //
  //   分块写各字段，结构对齐 golden 的条件赋值，避免 FM 把部分位判不等价。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      ecc_inject_status <= INJ_STATUS_IDLE;
      ecc_inject_error  <= INJ_ERR_NOT_ENABLED;
    end
    // (A) 软件下发注入命令
    else if (inject_cmd) begin
      if (wr_enable) begin
        // enable=1：命令合法性继续看 itarget。优先级（对齐 Scala/golden）：
        //   itarget 非法 > 同拍读清 > 注入 FSM 正处于 select-未命中（记 not_found）> 维持。
        if (wr_target_bad)
          ecc_inject_error <= INJ_ERR_TARGET_INVAL;
        else if (read_eccctrl_clears)
          ecc_inject_error <= INJ_ERR_NOT_ENABLED; // 同拍读清（极少同时发生）
        else if (in_select_miss)
          ecc_inject_error <= INJ_ERR_NOT_FOUND;   // FSM 同拍在 select 且未命中
        // else 维持原 ierror
      end
      else begin
        // enable=0 却想注入：not_enabled
        ecc_inject_error <= INJ_ERR_NOT_ENABLED;
      end
      // enable=0 或 itarget 非法 → 直接判 error，否则进 working
      ecc_inject_status <= (~wr_enable | wr_target_bad) ? INJ_STATUS_ERROR
                                                        : INJ_STATUS_WORKING;
    end
    // (B) 读 eccctrl 清状态
    else if (read_eccctrl_clears) begin
      ecc_inject_status <= INJ_STATUS_IDLE;
      ecc_inject_error  <= INJ_ERR_NOT_ENABLED;
    end
    // (C) 注入 FSM 推进
    else begin
      if (in_select_miss)
        ecc_inject_error <= INJ_ERR_NOT_FOUND;
      // istatus 转移
      unique case (inject_state)
        S_SELECT_WAY:
          if (inject_miss) ecc_inject_status <= INJ_STATUS_ERROR;
        S_WRITE_META:
          if (meta_write_done) ecc_inject_status <= INJ_STATUS_INJECTED;
        S_WRITE_DATA:
          if (data_write_done) ecc_inject_status <= INJ_STATUS_INJECTED;
        default: ;
      endcase
    end
  end

  // ===========================================================================
  // D 通道读回数据（AccessAckData payload）
  //   index 奇 → ecciaddr（{0, paddr}）；index 偶 → eccctrl 打包；其余 → 0。
  //   eccctrl 打包顺序须与软件 bundle 一致：
  //     {ierror[2:0], istatus[2:0], itarget[1:0], inject=0(读恒 0), enable}
  //
  //   用连续赋值的三目而非 if/else：当队列空槽使 req_index 为 X 时，sel_low_regs 也为 X，
  //   三目会把 X 透传到 resp_rdata（与 golden 的 X 悲观一致）；此时 D.valid=0，数据本就无意义。
  // ===========================================================================
  logic [DATA_W-1:0] rdata_eccctrl;
  logic [DATA_W-1:0] rdata_ecciaddr;
  assign rdata_eccctrl  = {{(DATA_W-10){1'b0}},
                           ecc_inject_error, ecc_inject_status, ecc_inject_target,
                           1'b0,            // inject 读恒 0
                           ecc_enable};
  assign rdata_ecciaddr = {{(DATA_W-PADDR_W){1'b0}}, ecc_inject_paddr};

  assign resp_rdata = sel_low_regs ? (req_index[0] ? rdata_ecciaddr : rdata_eccctrl)
                                   : '0;

  // ---------------------------------------------------------------------------
  // 其余直连输出
  // ---------------------------------------------------------------------------
  assign io_ecc_enable              = ecc_enable;
  assign io_metaRead_bits_vSetIdx_0 = inject_vset_idx;
  assign io_metaRead_bits_vSetIdx_1 = inject_vset_idx; // 注入只用第一条 line，两端口同 idx
  assign io_metaWrite_bits_virIdx   = inject_vset_idx;
  assign io_metaWrite_bits_phyTag   = inject_phy_tag;
  assign io_metaWrite_bits_waymask  = inject_waymask;
  assign io_metaWrite_bits_bankIdx  = inject_bank_idx;
  assign io_dataWrite_bits_virIdx   = inject_vset_idx;
  assign io_dataWrite_bits_waymask  = inject_waymask;

endmodule

// =============================================================================
// xs_Queue1_RegMapperInput —— RegMapper 输入侧深度 1 队列（skid buffer）
//
// 对应 Chisel: Queue(RegMapperInput, 1)（被 TLRegisterNode 自动插入）
//
// 【为什么需要它】
//   TLRegisterNode 在 A→D 之间放一个深度 1 的 Queue 做"打一拍"的解耦：A 通道请求先入队，
//   寄存器逻辑读队头处理，处理完（D 握手）再出队。这样寄存器读写与 TileLink 握手时序解耦，
//   且 concurrency=1（同时只在途一笔请求）。
//
// 【行为】
//   单槽：full 标志 + 一个打包寄存器 slot。
//     enq: ~full & enq_valid 时锁存 payload；
//     deq: full 时输出 payload，deq_ready & full 时出队。
//   payload 打包顺序（低→高）：read, index, data, mask, source, size
//   （source/size 是 TileLink 透传字段，回 D 通道时原样带回）。
// =============================================================================
module xs_Queue1_RegMapperInput #(
  parameter int unsigned INDEX_W  = 4,
  parameter int unsigned DATA_W   = 64,
  parameter int unsigned MASK_W   = 8,
  parameter int unsigned SOURCE_W = 3,
  parameter int unsigned SIZE_W   = 2
) (
  input  logic                 clock,
  input  logic                 reset,
  // 入队（A 通道侧）
  output logic                 io_enq_ready,
  input  logic                 io_enq_valid,
  input  logic                 io_enq_bits_read,
  input  logic [INDEX_W-1:0]   io_enq_bits_index,
  input  logic [DATA_W-1:0]    io_enq_bits_data,
  input  logic [MASK_W-1:0]    io_enq_bits_mask,
  input  logic [SOURCE_W-1:0]  io_enq_bits_extra_tlrr_extra_source,
  input  logic [SIZE_W-1:0]    io_enq_bits_extra_tlrr_extra_size,
  // 出队（寄存器逻辑侧）
  input  logic                 io_deq_ready,
  output logic                 io_deq_valid,
  output logic                 io_deq_bits_read,
  output logic [INDEX_W-1:0]   io_deq_bits_index,
  output logic [DATA_W-1:0]    io_deq_bits_data,
  output logic [MASK_W-1:0]    io_deq_bits_mask,
  output logic [SOURCE_W-1:0]  io_deq_bits_extra_tlrr_extra_source,
  output logic [SIZE_W-1:0]    io_deq_bits_extra_tlrr_extra_size
);

  // 一个槽里要存的所有字段聚成 struct（比裸位打包更可读；位序与下方 deq 拆解一致）
  typedef struct packed {
    logic [SIZE_W-1:0]   size;
    logic [SOURCE_W-1:0] source;
    logic [MASK_W-1:0]   mask;
    logic [DATA_W-1:0]   data;
    logic [INDEX_W-1:0]  index;
    logic                read;
  } reg_req_t;

  reg_req_t slot;
  logic     full;

  // 仅当槽空且上游有效时入队
  logic do_enq;
  assign do_enq = ~full & io_enq_valid;

  // 数据槽：enq 命中时锁存（无复位，与 golden 一致——靠 full 保证读出有效性）
  always_ff @(posedge clock) begin
    if (do_enq) begin
      slot.size   <= io_enq_bits_extra_tlrr_extra_size;
      slot.source <= io_enq_bits_extra_tlrr_extra_source;
      slot.mask   <= io_enq_bits_mask;
      slot.data   <= io_enq_bits_data;
      slot.index  <= io_enq_bits_index;
      slot.read   <= io_enq_bits_read;
    end
  end

  // full 标志：当"入队"与"出队"不同步发生时翻转到 do_enq
  //   do_enq==(deq_ready&full) 表示这拍同时进同时出（或都不动），槽占用不变。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      full <= 1'b0;
    else if (do_enq != (io_deq_ready & full))
      full <= do_enq;
  end

  assign io_enq_ready                        = ~full;
  assign io_deq_valid                        = full;
  assign io_deq_bits_read                    = slot.read;
  assign io_deq_bits_index                   = slot.index;
  assign io_deq_bits_data                    = slot.data;
  assign io_deq_bits_mask                    = slot.mask;
  assign io_deq_bits_extra_tlrr_extra_source = slot.source;
  assign io_deq_bits_extra_tlrr_extra_size   = slot.size;

endmodule
