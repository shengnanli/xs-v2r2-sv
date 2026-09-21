// =============================================================================
// SQAddrModule_xs.sv —— StoreQueue_xs 地址阵列(paddr/vaddr 两个单态化变体的共享核)
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/mem/lsqueue/StoreQueueData.scala
//        class SQAddrModule_xs(dataWidth, numEntries, numRead, numWrite, numForward)
// golden 对照:G1 golden-rtl/SQAddrModule_xs.sv(2048 行) 与 SQAddrModule_1_xs.sv(1967 行)
//
// 【它是干什么的】
// StoreQueue_xs 里每条 store 的地址存在这里。它不是普通 RAM,而是一个**带 CAM 的
// 寄存器阵列**:除了同步读口(给出队用),还有 3 个"前递比较口"——load 拿自己的
// 地址进来,同拍和全部 56 条 store 的地址并行比对,输出 56 位命中掩码,上层据此
// 决定 store-to-load 前递。
//
//   写口 2 个:直写(**不流水**,与 SQData8Module_xs 的两拍写路径不同)
//   读口 2 个:同步读,读地址打一拍(GatedRegNext)
//   前递口 3 个:纯组合 CAM,不打拍、不看 valid
//
// 【★ 家族:SQAddrModule_xs 与 SQAddrModule_1_xs 是同一设计的两个单态化变体 ★】
// 实测差异**只有两条**(把两份 golden 归一化后逐行 diff,残差为 0):
//   (a) DATA_WIDTH:48(paddrModule,物理地址) vs 50(vaddrModule,虚地址)
//   (b) rlineflag **读口**:SQAddrModule_xs 有 io_rlineflag_0/1 输出,_1 没有
// 除此之外条目数、读/写/前递口数、断言、位切片全部一致,故做成一个核 + 两个薄
// wrapper,核体不复制。
//
// ★ 对 (b) 的一条重要澄清(推翻"_1 里没有 lineflag"的直觉)★:
//   _1 里 lineflag **寄存器仍然在**(56 个),io_wlineflag_0/1 输入也仍然在,
//   而且 168 条前递比较式里都用到了 lineflag[j]。被 firtool DCE 掉的**只有读侧**:
//   两个 io_rlineflag_* 输出端口、它们的 64 深读 mux、以及两个读地址寄存器。
//   所以参数叫 HAS_RLINEFLAG_OUT(只管输出),不叫 HAS_LINEFLAG。
//   照"_1 没有 lineflag"去写会把 168 条前递式全写错。
//
// 【★ 复位域:168 个完全不复位 + 2~4 个异步复位,零交集 ★】
//   data[56] / mask[56] / lineflag[56] —— 裸 always @(posedge clock),**没有复位**
//       (Chisel 侧是裸 Reg(Vec(...)),不是 RegInit)
//   读地址寄存器 —— always @(posedge clock or posedge reset),**异步复位**
//       SQAddrModule_xs 4 个,SQAddrModule_1_xs 2 个
//   把不复位的那 168 个写成复位是真 bug:elaborate / lint 都不报,只有 FM 抓得到。
//
// 【★ 读地址寄存器是"两份独立寄存器",不许合并 ★】
//   Chisel 里 io.rdata(i) 和 io.rlineflag(i) 各自写了一次 GatedRegNext(io.raddr(i)),
//   于是 golden 里 io_rdata_0_next_r 与 io_rlineflag_0_next_r 是**两个寄存器**,
//   值永远相同。看着冗余,但这是 golden 的寄存器集合:合成一份 → FM 少一个比较点;
//   反过来在 _1 里补齐第二份 → 多出两个没人读的死寄存器 → unread → PARTIAL。
//   所以这里用 generate 精确控制:HAS_RLINEFLAG_OUT=1 才生成第二份。
//
// 【★ 越界读落到条目 0,不是落到 0 ★】
//   raddr 是 6 bit(64 种编码)而条目只有 56 个。firtool 把 Vec 读展成 64 深 mux,
//   56..63 这 8 个槽填的是 **data[0]**,不是常数 0。按"没查到就是 0"写是真 bug。
//   见 §2.5。
//
// 【更新优先级】同一条目同拍被两个写口写:**写口 1 胜过写口 0**。
//   golden 形状是 if(wen_1 && waddr_1==k) ... else if(wen_0 && waddr_0==k) ...,
//   对应 Chisel 里 for(i) when(io.wen(i)) 的"后写者胜"。下面用 for 循环内的
//   阻塞语义复现同一形状。注意本模块带断言禁止同址双写(见 §2.7),所以这条
//   优先级在合法激励下不可观测——但 FM 要逐位证,必须与 golden 一致。
// =============================================================================

// -----------------------------------------------------------------------------
// §1 家族共享常量(与变体无关的尺寸)
// -----------------------------------------------------------------------------
package sq_addr_module_pkg;

  // 全部从 G1 golden 端口表机械量得,不取 Chisel 默认值。
  localparam int NUM_ENTRIES = 56;  // StoreQueueSize
  localparam int ADDR_W      = 6;   // log2Up(56) —— 注意 2**6=64 > 56,见 §2.5
  localparam int NUM_READ    = 2;
  localparam int NUM_WRITE   = 2;
  localparam int NUM_FWD     = 3;
  localparam int MASK_W      = 16;  // VLEN/8

  // 地址分段(HasDCacheParameters)。前递比较按这两个边界切三段:
  //   [DW-1 : LINE_OFF]      —— cache line 号,必须相等(linehit)
  //   [LINE_OFF-1 : VWORD_OFF] —— line 内的 128 bit vword 号
  //   [VWORD_OFF-1 : 0]      —— vword 内的字节偏移,由 mask 位覆盖,不参与比较
  localparam int LINE_OFF  = 6;  // DCacheLineOffset  —— 64 B cache line
  localparam int VWORD_OFF = 4;  // DCacheVWordOffset —— 16 B vword

endpackage

// -----------------------------------------------------------------------------
// §2 xs_SQAddrModule_core —— 家族共享参数化核
// -----------------------------------------------------------------------------
module xs_SQAddrModule_core
  import sq_addr_module_pkg::*;
#(
  // 地址位宽:48 = PAddrBits(paddrModule);50 = VAddrBits+1(vaddrModule)
  parameter int DATA_WIDTH = 48,
  // 是否引出 rlineflag 读口。0 时既不引出端口,也**不生成**那一份读地址寄存器
  // ——生成了没人读就是死寄存器,FM 会判 unread。见文件头。
  parameter bit HAS_RLINEFLAG_OUT = 1'b1
) (
  input  logic                    clock,
  input  logic                    reset,

  // 同步读口:地址打一拍后出数据
  input  logic [ADDR_W-1:0]       raddr     [NUM_READ],
  output logic [DATA_WIDTH-1:0]   rdata     [NUM_READ],
  output logic                    rlineflag [NUM_READ],   // HAS_RLINEFLAG_OUT=0 时恒 0

  // 写口(直写,不流水)
  input  logic                    wen       [NUM_WRITE],
  input  logic [ADDR_W-1:0]       waddr     [NUM_WRITE],
  input  logic [DATA_WIDTH-1:0]   wdata     [NUM_WRITE],
  input  logic [MASK_W-1:0]       wmask     [NUM_WRITE],
  input  logic                    wlineflag [NUM_WRITE],

  // 前递比较口(纯组合 CAM)
  input  logic [DATA_WIDTH-1:0]   forwardMdata    [NUM_FWD],
  input  logic [MASK_W-1:0]       forwardDataMask [NUM_FWD],
  output logic [NUM_ENTRIES-1:0]  forwardMmask    [NUM_FWD]
);

  // ---------------------------------------------------------------------------
  // §2.1 阵列状态(★全部不复位★)
  // ---------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] data     [NUM_ENTRIES];
  logic [MASK_W-1:0]     mask     [NUM_ENTRIES];
  // lineflag=1 表示这条 store 覆盖**整条 cache line**(cbo / 整行写)。
  // 置位后前递比较跳过 line 内的 vword 比较,只要 line 号相同就算命中。
  logic                  lineflag [NUM_ENTRIES];

  // ---------------------------------------------------------------------------
  // §2.2 写口(★写口 1 胜过写口 0★)
  // ---------------------------------------------------------------------------
  // for 内阻塞语义 = 后写者胜 = golden 的 if(口1)/else if(口0) 同形。
  always_ff @(posedge clock) begin
    for (int e = 0; e < NUM_ENTRIES; e++)
      for (int w = 0; w < NUM_WRITE; w++)
        if (wen[w] && waddr[w] == ADDR_W'(e)) begin
          data[e]     <= wdata[w];
          mask[e]     <= wmask[w];
          lineflag[e] <= wlineflag[w];
        end
  end

  // ---------------------------------------------------------------------------
  // §2.3 读地址寄存器(★异步复位;两份独立,不许合并★)
  // ---------------------------------------------------------------------------
  // golden 的 `if (~(raddr == r)) r <= raddr` 是 GatedRegNext 的降级形式
  // (值没变就不打拍,省翻转功耗)。与无条件 r <= raddr 值等价,这里照抄 golden 形状。
  logic [ADDR_W-1:0] rdata_addr_r [NUM_READ];

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      for (int i = 0; i < NUM_READ; i++) rdata_addr_r[i] <= '0;
    else
      for (int i = 0; i < NUM_READ; i++)
        if (raddr[i] != rdata_addr_r[i]) rdata_addr_r[i] <= raddr[i];
  end

  // ---------------------------------------------------------------------------
  // §2.4 同步读(★越界落到条目 0★)
  // ---------------------------------------------------------------------------
  // raddr 6 bit(64 种编码)而条目只有 56 个。golden 把 Vec 读展成一张 **64 项**的
  // 表,越界的 56..63 这 8 槽填的是 **data[0]**(firtool 对 Vec 越界读的展开方式),
  // 不是常数 0。这里照抄那张表,再用 6 位地址直接取。
  //
  // ★ 不要写成 data[idx < NUM_ENTRIES ? idx : 0] ★
  //   那样值是对的,但 Formality 的静态分析不做边界传播,会判
  //   FMR_ELAB-147(索引可能越界)→ 拒绝 link(FM-262)→ set_top 失败(FM-156)。
  //   实测踩过一次。正确修法是**把表补齐到 2**ADDR_W 项**(下面两个 for 都在界内,
  //   地址位宽与表深度精确相等,按构造不可能越界),不是去抑制那条消息。
  //   附带好处:这个形状本来就更贴近 golden 的 _GEN。
  localparam int READ_SLOTS = 1 << ADDR_W;   // 64

  logic [DATA_WIDTH-1:0] data_rtbl [READ_SLOTS];
  always_comb begin
    for (int k = 0;           k < NUM_ENTRIES; k++) data_rtbl[k] = data[k];
    for (int k = NUM_ENTRIES; k < READ_SLOTS;  k++) data_rtbl[k] = data[0];  // 越界槽
  end

  always_comb
    for (int i = 0; i < NUM_READ; i++) rdata[i] = data_rtbl[rdata_addr_r[i]];

  // ---------------------------------------------------------------------------
  // §2.5 rlineflag 读口(只有 SQAddrModule_xs 变体有)
  // ---------------------------------------------------------------------------
  // ★ 这里是第二份读地址寄存器 ★:与 §2.3 那份**值永远相同**,但 golden 里确实是
  // 两个独立寄存器(Chisel 两处各写了一次 GatedRegNext)。合并成一份 → FM 少一个
  // 比较点;反过来在 _1 变体里也生成 → 多出两个没人读的死寄存器 → unread → PARTIAL。
  // 所以整块(寄存器 + 输出)一起放进 generate,由参数精确控制存在与否。
  if (HAS_RLINEFLAG_OUT) begin : g_rlineflag
    logic [ADDR_W-1:0] rlineflag_addr_r [NUM_READ];

    always_ff @(posedge clock or posedge reset) begin
      if (reset)
        for (int i = 0; i < NUM_READ; i++) rlineflag_addr_r[i] <= '0;
      else
        for (int i = 0; i < NUM_READ; i++)
          if (raddr[i] != rlineflag_addr_r[i]) rlineflag_addr_r[i] <= raddr[i];
    end

    // 同 §2.4:补齐到 64 项再取,越界槽填 lineflag[0]。
    logic lineflag_rtbl [READ_SLOTS];
    always_comb begin
      for (int k = 0;           k < NUM_ENTRIES; k++) lineflag_rtbl[k] = lineflag[k];
      for (int k = NUM_ENTRIES; k < READ_SLOTS;  k++) lineflag_rtbl[k] = lineflag[0];
    end

    for (genvar i = 0; i < NUM_READ; i++)
      assign rlineflag[i] = lineflag_rtbl[rlineflag_addr_r[i]];
  end else begin : g_no_rlineflag
    // 本变体不引出 rlineflag:不生成寄存器,也不生成读通路。
    for (genvar i = 0; i < NUM_READ; i++) assign rlineflag[i] = 1'b0;
  end

  // ---------------------------------------------------------------------------
  // §2.6 前递 CAM(纯组合,3 个口 × 56 条目)
  // ---------------------------------------------------------------------------
  // 命中 = 同一条 cache line,且(同一个 128 bit vword 且字节掩码有交集,
  //        或者这条 store 是整行写)。
  // ★注意这里**不看任何 valid**★:哪条条目算数由上层的 needForward 决定,
  //   本模块只做纯地址比较。
  always_comb begin
    for (int i = 0; i < NUM_FWD; i++) begin
      for (int j = 0; j < NUM_ENTRIES; j++) begin
        automatic logic linehit;
        automatic logic hit128bit;
        linehit   = forwardMdata[i][DATA_WIDTH-1:LINE_OFF] == data[j][DATA_WIDTH-1:LINE_OFF];
        hit128bit = (forwardMdata[i][LINE_OFF-1:VWORD_OFF] == data[j][LINE_OFF-1:VWORD_OFF])
                    && |(mask[j] & forwardDataMask[i]);
        forwardMmask[i][j] = linehit && (hit128bit || lineflag[j]);
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2.7 接口契约断言(StoreQueueData.scala:88)
  // ---------------------------------------------------------------------------
  // 本阵列是 DataModuleTemplate 风格的多写口寄存器堆,上游必须保证同拍两个写口
  // 不落在同一条目。违反时 §2.2 的优先级会生效,但那不是设计意图。
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (~reset)
      for (int i = 0; i < NUM_WRITE; i++)
        for (int j = i + 1; j < NUM_WRITE; j++)
          assert (!(wen[i] && wen[j] && waddr[i] == waddr[j]))
            else $fatal(1, "SQAddrModule_xs: write port %0d and %0d collide on entry %0d",
                        i, j, waddr[i]);
  end
`endif

endmodule

// -----------------------------------------------------------------------------
// §3 SQAddrModule_xs —— golden 同名薄 wrapper(paddrModule 变体)
// -----------------------------------------------------------------------------
// DATA_WIDTH=48(PAddrBits),引出 rlineflag 读口。
// 端口名/顺序/位宽逐位对齐 G1 golden。

module SQAddrModule_xs(
  input          clock,
  input          reset,
  input  [5:0]   io_raddr_0,
  input  [5:0]   io_raddr_1,
  output [47:0]  io_rdata_0,
  output [47:0]  io_rdata_1,
  output         io_rlineflag_0,
  output         io_rlineflag_1,
  input          io_wen_0,
  input          io_wen_1,
  input  [5:0]   io_waddr_0,
  input  [5:0]   io_waddr_1,
  input  [47:0]  io_wdata_0,
  input  [47:0]  io_wdata_1,
  input  [15:0]  io_wmask_0,
  input  [15:0]  io_wmask_1,
  input          io_wlineflag_0,
  input          io_wlineflag_1,
  input  [47:0]  io_forwardMdata_0,
  input  [47:0]  io_forwardMdata_1,
  input  [47:0]  io_forwardMdata_2,
  input  [15:0]  io_forwardDataMask_0,
  input  [15:0]  io_forwardDataMask_1,
  input  [15:0]  io_forwardDataMask_2,
  output         io_forwardMmask_0_0,
  output         io_forwardMmask_0_1,
  output         io_forwardMmask_0_2,
  output         io_forwardMmask_0_3,
  output         io_forwardMmask_0_4,
  output         io_forwardMmask_0_5,
  output         io_forwardMmask_0_6,
  output         io_forwardMmask_0_7,
  output         io_forwardMmask_0_8,
  output         io_forwardMmask_0_9,
  output         io_forwardMmask_0_10,
  output         io_forwardMmask_0_11,
  output         io_forwardMmask_0_12,
  output         io_forwardMmask_0_13,
  output         io_forwardMmask_0_14,
  output         io_forwardMmask_0_15,
  output         io_forwardMmask_0_16,
  output         io_forwardMmask_0_17,
  output         io_forwardMmask_0_18,
  output         io_forwardMmask_0_19,
  output         io_forwardMmask_0_20,
  output         io_forwardMmask_0_21,
  output         io_forwardMmask_0_22,
  output         io_forwardMmask_0_23,
  output         io_forwardMmask_0_24,
  output         io_forwardMmask_0_25,
  output         io_forwardMmask_0_26,
  output         io_forwardMmask_0_27,
  output         io_forwardMmask_0_28,
  output         io_forwardMmask_0_29,
  output         io_forwardMmask_0_30,
  output         io_forwardMmask_0_31,
  output         io_forwardMmask_0_32,
  output         io_forwardMmask_0_33,
  output         io_forwardMmask_0_34,
  output         io_forwardMmask_0_35,
  output         io_forwardMmask_0_36,
  output         io_forwardMmask_0_37,
  output         io_forwardMmask_0_38,
  output         io_forwardMmask_0_39,
  output         io_forwardMmask_0_40,
  output         io_forwardMmask_0_41,
  output         io_forwardMmask_0_42,
  output         io_forwardMmask_0_43,
  output         io_forwardMmask_0_44,
  output         io_forwardMmask_0_45,
  output         io_forwardMmask_0_46,
  output         io_forwardMmask_0_47,
  output         io_forwardMmask_0_48,
  output         io_forwardMmask_0_49,
  output         io_forwardMmask_0_50,
  output         io_forwardMmask_0_51,
  output         io_forwardMmask_0_52,
  output         io_forwardMmask_0_53,
  output         io_forwardMmask_0_54,
  output         io_forwardMmask_0_55,
  output         io_forwardMmask_1_0,
  output         io_forwardMmask_1_1,
  output         io_forwardMmask_1_2,
  output         io_forwardMmask_1_3,
  output         io_forwardMmask_1_4,
  output         io_forwardMmask_1_5,
  output         io_forwardMmask_1_6,
  output         io_forwardMmask_1_7,
  output         io_forwardMmask_1_8,
  output         io_forwardMmask_1_9,
  output         io_forwardMmask_1_10,
  output         io_forwardMmask_1_11,
  output         io_forwardMmask_1_12,
  output         io_forwardMmask_1_13,
  output         io_forwardMmask_1_14,
  output         io_forwardMmask_1_15,
  output         io_forwardMmask_1_16,
  output         io_forwardMmask_1_17,
  output         io_forwardMmask_1_18,
  output         io_forwardMmask_1_19,
  output         io_forwardMmask_1_20,
  output         io_forwardMmask_1_21,
  output         io_forwardMmask_1_22,
  output         io_forwardMmask_1_23,
  output         io_forwardMmask_1_24,
  output         io_forwardMmask_1_25,
  output         io_forwardMmask_1_26,
  output         io_forwardMmask_1_27,
  output         io_forwardMmask_1_28,
  output         io_forwardMmask_1_29,
  output         io_forwardMmask_1_30,
  output         io_forwardMmask_1_31,
  output         io_forwardMmask_1_32,
  output         io_forwardMmask_1_33,
  output         io_forwardMmask_1_34,
  output         io_forwardMmask_1_35,
  output         io_forwardMmask_1_36,
  output         io_forwardMmask_1_37,
  output         io_forwardMmask_1_38,
  output         io_forwardMmask_1_39,
  output         io_forwardMmask_1_40,
  output         io_forwardMmask_1_41,
  output         io_forwardMmask_1_42,
  output         io_forwardMmask_1_43,
  output         io_forwardMmask_1_44,
  output         io_forwardMmask_1_45,
  output         io_forwardMmask_1_46,
  output         io_forwardMmask_1_47,
  output         io_forwardMmask_1_48,
  output         io_forwardMmask_1_49,
  output         io_forwardMmask_1_50,
  output         io_forwardMmask_1_51,
  output         io_forwardMmask_1_52,
  output         io_forwardMmask_1_53,
  output         io_forwardMmask_1_54,
  output         io_forwardMmask_1_55,
  output         io_forwardMmask_2_0,
  output         io_forwardMmask_2_1,
  output         io_forwardMmask_2_2,
  output         io_forwardMmask_2_3,
  output         io_forwardMmask_2_4,
  output         io_forwardMmask_2_5,
  output         io_forwardMmask_2_6,
  output         io_forwardMmask_2_7,
  output         io_forwardMmask_2_8,
  output         io_forwardMmask_2_9,
  output         io_forwardMmask_2_10,
  output         io_forwardMmask_2_11,
  output         io_forwardMmask_2_12,
  output         io_forwardMmask_2_13,
  output         io_forwardMmask_2_14,
  output         io_forwardMmask_2_15,
  output         io_forwardMmask_2_16,
  output         io_forwardMmask_2_17,
  output         io_forwardMmask_2_18,
  output         io_forwardMmask_2_19,
  output         io_forwardMmask_2_20,
  output         io_forwardMmask_2_21,
  output         io_forwardMmask_2_22,
  output         io_forwardMmask_2_23,
  output         io_forwardMmask_2_24,
  output         io_forwardMmask_2_25,
  output         io_forwardMmask_2_26,
  output         io_forwardMmask_2_27,
  output         io_forwardMmask_2_28,
  output         io_forwardMmask_2_29,
  output         io_forwardMmask_2_30,
  output         io_forwardMmask_2_31,
  output         io_forwardMmask_2_32,
  output         io_forwardMmask_2_33,
  output         io_forwardMmask_2_34,
  output         io_forwardMmask_2_35,
  output         io_forwardMmask_2_36,
  output         io_forwardMmask_2_37,
  output         io_forwardMmask_2_38,
  output         io_forwardMmask_2_39,
  output         io_forwardMmask_2_40,
  output         io_forwardMmask_2_41,
  output         io_forwardMmask_2_42,
  output         io_forwardMmask_2_43,
  output         io_forwardMmask_2_44,
  output         io_forwardMmask_2_45,
  output         io_forwardMmask_2_46,
  output         io_forwardMmask_2_47,
  output         io_forwardMmask_2_48,
  output         io_forwardMmask_2_49,
  output         io_forwardMmask_2_50,
  output         io_forwardMmask_2_51,
  output         io_forwardMmask_2_52,
  output         io_forwardMmask_2_53,
  output         io_forwardMmask_2_54,
  output         io_forwardMmask_2_55
);

  localparam int DW = 48;

  logic [5:0]    raddr     [2];
  logic [DW-1:0] rdata     [2];
  logic          rlineflag [2];
  logic          wen       [2];
  logic [5:0]    waddr     [2];
  logic [DW-1:0] wdata     [2];
  logic [15:0]   wmask     [2];
  logic          wlineflag [2];
  logic [DW-1:0] forwardMdata    [3];
  logic [15:0]   forwardDataMask [3];
  logic [55:0]   forwardMmask    [3];

  always_comb begin
    raddr[0]           = io_raddr_0;
    raddr[1]           = io_raddr_1;
    wen[0]             = io_wen_0;
    waddr[0]           = io_waddr_0;
    wdata[0]           = io_wdata_0;
    wmask[0]           = io_wmask_0;
    wlineflag[0]       = io_wlineflag_0;
    wen[1]             = io_wen_1;
    waddr[1]           = io_waddr_1;
    wdata[1]           = io_wdata_1;
    wmask[1]           = io_wmask_1;
    wlineflag[1]       = io_wlineflag_1;
    forwardMdata[0]    = io_forwardMdata_0;
    forwardDataMask[0] = io_forwardDataMask_0;
    forwardMdata[1]    = io_forwardMdata_1;
    forwardDataMask[1] = io_forwardDataMask_1;
    forwardMdata[2]    = io_forwardMdata_2;
    forwardDataMask[2] = io_forwardDataMask_2;
  end

  xs_SQAddrModule_core #(
    .DATA_WIDTH        (48),
    .HAS_RLINEFLAG_OUT (1'b1)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .raddr           (raddr),
    .rdata           (rdata),
    .rlineflag       (rlineflag),
    .wen             (wen),
    .waddr           (waddr),
    .wdata           (wdata),
    .wmask           (wmask),
    .wlineflag       (wlineflag),
    .forwardMdata    (forwardMdata),
    .forwardDataMask (forwardDataMask),
    .forwardMmask    (forwardMmask)
  );

  assign io_rdata_0 = rdata[0];
  assign io_rdata_1 = rdata[1];
  assign io_rlineflag_0 = rlineflag[0];
  assign io_rlineflag_1 = rlineflag[1];

  // 前递命中掩码:核里是 3 个 56 位向量,golden 摊平成 168 个 1 位输出。
  assign io_forwardMmask_0_0 = forwardMmask[0][0];
  assign io_forwardMmask_0_1 = forwardMmask[0][1];
  assign io_forwardMmask_0_2 = forwardMmask[0][2];
  assign io_forwardMmask_0_3 = forwardMmask[0][3];
  assign io_forwardMmask_0_4 = forwardMmask[0][4];
  assign io_forwardMmask_0_5 = forwardMmask[0][5];
  assign io_forwardMmask_0_6 = forwardMmask[0][6];
  assign io_forwardMmask_0_7 = forwardMmask[0][7];
  assign io_forwardMmask_0_8 = forwardMmask[0][8];
  assign io_forwardMmask_0_9 = forwardMmask[0][9];
  assign io_forwardMmask_0_10 = forwardMmask[0][10];
  assign io_forwardMmask_0_11 = forwardMmask[0][11];
  assign io_forwardMmask_0_12 = forwardMmask[0][12];
  assign io_forwardMmask_0_13 = forwardMmask[0][13];
  assign io_forwardMmask_0_14 = forwardMmask[0][14];
  assign io_forwardMmask_0_15 = forwardMmask[0][15];
  assign io_forwardMmask_0_16 = forwardMmask[0][16];
  assign io_forwardMmask_0_17 = forwardMmask[0][17];
  assign io_forwardMmask_0_18 = forwardMmask[0][18];
  assign io_forwardMmask_0_19 = forwardMmask[0][19];
  assign io_forwardMmask_0_20 = forwardMmask[0][20];
  assign io_forwardMmask_0_21 = forwardMmask[0][21];
  assign io_forwardMmask_0_22 = forwardMmask[0][22];
  assign io_forwardMmask_0_23 = forwardMmask[0][23];
  assign io_forwardMmask_0_24 = forwardMmask[0][24];
  assign io_forwardMmask_0_25 = forwardMmask[0][25];
  assign io_forwardMmask_0_26 = forwardMmask[0][26];
  assign io_forwardMmask_0_27 = forwardMmask[0][27];
  assign io_forwardMmask_0_28 = forwardMmask[0][28];
  assign io_forwardMmask_0_29 = forwardMmask[0][29];
  assign io_forwardMmask_0_30 = forwardMmask[0][30];
  assign io_forwardMmask_0_31 = forwardMmask[0][31];
  assign io_forwardMmask_0_32 = forwardMmask[0][32];
  assign io_forwardMmask_0_33 = forwardMmask[0][33];
  assign io_forwardMmask_0_34 = forwardMmask[0][34];
  assign io_forwardMmask_0_35 = forwardMmask[0][35];
  assign io_forwardMmask_0_36 = forwardMmask[0][36];
  assign io_forwardMmask_0_37 = forwardMmask[0][37];
  assign io_forwardMmask_0_38 = forwardMmask[0][38];
  assign io_forwardMmask_0_39 = forwardMmask[0][39];
  assign io_forwardMmask_0_40 = forwardMmask[0][40];
  assign io_forwardMmask_0_41 = forwardMmask[0][41];
  assign io_forwardMmask_0_42 = forwardMmask[0][42];
  assign io_forwardMmask_0_43 = forwardMmask[0][43];
  assign io_forwardMmask_0_44 = forwardMmask[0][44];
  assign io_forwardMmask_0_45 = forwardMmask[0][45];
  assign io_forwardMmask_0_46 = forwardMmask[0][46];
  assign io_forwardMmask_0_47 = forwardMmask[0][47];
  assign io_forwardMmask_0_48 = forwardMmask[0][48];
  assign io_forwardMmask_0_49 = forwardMmask[0][49];
  assign io_forwardMmask_0_50 = forwardMmask[0][50];
  assign io_forwardMmask_0_51 = forwardMmask[0][51];
  assign io_forwardMmask_0_52 = forwardMmask[0][52];
  assign io_forwardMmask_0_53 = forwardMmask[0][53];
  assign io_forwardMmask_0_54 = forwardMmask[0][54];
  assign io_forwardMmask_0_55 = forwardMmask[0][55];
  assign io_forwardMmask_1_0 = forwardMmask[1][0];
  assign io_forwardMmask_1_1 = forwardMmask[1][1];
  assign io_forwardMmask_1_2 = forwardMmask[1][2];
  assign io_forwardMmask_1_3 = forwardMmask[1][3];
  assign io_forwardMmask_1_4 = forwardMmask[1][4];
  assign io_forwardMmask_1_5 = forwardMmask[1][5];
  assign io_forwardMmask_1_6 = forwardMmask[1][6];
  assign io_forwardMmask_1_7 = forwardMmask[1][7];
  assign io_forwardMmask_1_8 = forwardMmask[1][8];
  assign io_forwardMmask_1_9 = forwardMmask[1][9];
  assign io_forwardMmask_1_10 = forwardMmask[1][10];
  assign io_forwardMmask_1_11 = forwardMmask[1][11];
  assign io_forwardMmask_1_12 = forwardMmask[1][12];
  assign io_forwardMmask_1_13 = forwardMmask[1][13];
  assign io_forwardMmask_1_14 = forwardMmask[1][14];
  assign io_forwardMmask_1_15 = forwardMmask[1][15];
  assign io_forwardMmask_1_16 = forwardMmask[1][16];
  assign io_forwardMmask_1_17 = forwardMmask[1][17];
  assign io_forwardMmask_1_18 = forwardMmask[1][18];
  assign io_forwardMmask_1_19 = forwardMmask[1][19];
  assign io_forwardMmask_1_20 = forwardMmask[1][20];
  assign io_forwardMmask_1_21 = forwardMmask[1][21];
  assign io_forwardMmask_1_22 = forwardMmask[1][22];
  assign io_forwardMmask_1_23 = forwardMmask[1][23];
  assign io_forwardMmask_1_24 = forwardMmask[1][24];
  assign io_forwardMmask_1_25 = forwardMmask[1][25];
  assign io_forwardMmask_1_26 = forwardMmask[1][26];
  assign io_forwardMmask_1_27 = forwardMmask[1][27];
  assign io_forwardMmask_1_28 = forwardMmask[1][28];
  assign io_forwardMmask_1_29 = forwardMmask[1][29];
  assign io_forwardMmask_1_30 = forwardMmask[1][30];
  assign io_forwardMmask_1_31 = forwardMmask[1][31];
  assign io_forwardMmask_1_32 = forwardMmask[1][32];
  assign io_forwardMmask_1_33 = forwardMmask[1][33];
  assign io_forwardMmask_1_34 = forwardMmask[1][34];
  assign io_forwardMmask_1_35 = forwardMmask[1][35];
  assign io_forwardMmask_1_36 = forwardMmask[1][36];
  assign io_forwardMmask_1_37 = forwardMmask[1][37];
  assign io_forwardMmask_1_38 = forwardMmask[1][38];
  assign io_forwardMmask_1_39 = forwardMmask[1][39];
  assign io_forwardMmask_1_40 = forwardMmask[1][40];
  assign io_forwardMmask_1_41 = forwardMmask[1][41];
  assign io_forwardMmask_1_42 = forwardMmask[1][42];
  assign io_forwardMmask_1_43 = forwardMmask[1][43];
  assign io_forwardMmask_1_44 = forwardMmask[1][44];
  assign io_forwardMmask_1_45 = forwardMmask[1][45];
  assign io_forwardMmask_1_46 = forwardMmask[1][46];
  assign io_forwardMmask_1_47 = forwardMmask[1][47];
  assign io_forwardMmask_1_48 = forwardMmask[1][48];
  assign io_forwardMmask_1_49 = forwardMmask[1][49];
  assign io_forwardMmask_1_50 = forwardMmask[1][50];
  assign io_forwardMmask_1_51 = forwardMmask[1][51];
  assign io_forwardMmask_1_52 = forwardMmask[1][52];
  assign io_forwardMmask_1_53 = forwardMmask[1][53];
  assign io_forwardMmask_1_54 = forwardMmask[1][54];
  assign io_forwardMmask_1_55 = forwardMmask[1][55];
  assign io_forwardMmask_2_0 = forwardMmask[2][0];
  assign io_forwardMmask_2_1 = forwardMmask[2][1];
  assign io_forwardMmask_2_2 = forwardMmask[2][2];
  assign io_forwardMmask_2_3 = forwardMmask[2][3];
  assign io_forwardMmask_2_4 = forwardMmask[2][4];
  assign io_forwardMmask_2_5 = forwardMmask[2][5];
  assign io_forwardMmask_2_6 = forwardMmask[2][6];
  assign io_forwardMmask_2_7 = forwardMmask[2][7];
  assign io_forwardMmask_2_8 = forwardMmask[2][8];
  assign io_forwardMmask_2_9 = forwardMmask[2][9];
  assign io_forwardMmask_2_10 = forwardMmask[2][10];
  assign io_forwardMmask_2_11 = forwardMmask[2][11];
  assign io_forwardMmask_2_12 = forwardMmask[2][12];
  assign io_forwardMmask_2_13 = forwardMmask[2][13];
  assign io_forwardMmask_2_14 = forwardMmask[2][14];
  assign io_forwardMmask_2_15 = forwardMmask[2][15];
  assign io_forwardMmask_2_16 = forwardMmask[2][16];
  assign io_forwardMmask_2_17 = forwardMmask[2][17];
  assign io_forwardMmask_2_18 = forwardMmask[2][18];
  assign io_forwardMmask_2_19 = forwardMmask[2][19];
  assign io_forwardMmask_2_20 = forwardMmask[2][20];
  assign io_forwardMmask_2_21 = forwardMmask[2][21];
  assign io_forwardMmask_2_22 = forwardMmask[2][22];
  assign io_forwardMmask_2_23 = forwardMmask[2][23];
  assign io_forwardMmask_2_24 = forwardMmask[2][24];
  assign io_forwardMmask_2_25 = forwardMmask[2][25];
  assign io_forwardMmask_2_26 = forwardMmask[2][26];
  assign io_forwardMmask_2_27 = forwardMmask[2][27];
  assign io_forwardMmask_2_28 = forwardMmask[2][28];
  assign io_forwardMmask_2_29 = forwardMmask[2][29];
  assign io_forwardMmask_2_30 = forwardMmask[2][30];
  assign io_forwardMmask_2_31 = forwardMmask[2][31];
  assign io_forwardMmask_2_32 = forwardMmask[2][32];
  assign io_forwardMmask_2_33 = forwardMmask[2][33];
  assign io_forwardMmask_2_34 = forwardMmask[2][34];
  assign io_forwardMmask_2_35 = forwardMmask[2][35];
  assign io_forwardMmask_2_36 = forwardMmask[2][36];
  assign io_forwardMmask_2_37 = forwardMmask[2][37];
  assign io_forwardMmask_2_38 = forwardMmask[2][38];
  assign io_forwardMmask_2_39 = forwardMmask[2][39];
  assign io_forwardMmask_2_40 = forwardMmask[2][40];
  assign io_forwardMmask_2_41 = forwardMmask[2][41];
  assign io_forwardMmask_2_42 = forwardMmask[2][42];
  assign io_forwardMmask_2_43 = forwardMmask[2][43];
  assign io_forwardMmask_2_44 = forwardMmask[2][44];
  assign io_forwardMmask_2_45 = forwardMmask[2][45];
  assign io_forwardMmask_2_46 = forwardMmask[2][46];
  assign io_forwardMmask_2_47 = forwardMmask[2][47];
  assign io_forwardMmask_2_48 = forwardMmask[2][48];
  assign io_forwardMmask_2_49 = forwardMmask[2][49];
  assign io_forwardMmask_2_50 = forwardMmask[2][50];
  assign io_forwardMmask_2_51 = forwardMmask[2][51];
  assign io_forwardMmask_2_52 = forwardMmask[2][52];
  assign io_forwardMmask_2_53 = forwardMmask[2][53];
  assign io_forwardMmask_2_54 = forwardMmask[2][54];
  assign io_forwardMmask_2_55 = forwardMmask[2][55];

endmodule
