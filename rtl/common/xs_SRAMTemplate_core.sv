// =============================================================================
// xs_SRAMTemplate_core —— SRAMTemplate 功能逻辑核（单端口，整个变体家族共用一份）
//
// 对应 Chisel: utility.sram.SRAMTemplate（hasMbist=true, singlePort=true）。
//
// 设计取舍（见工程 README 的 SRAM 路线决策）：真实存储体（厂商宏 sram_array_* →
// array → array_ext）与时钟门控基元 ClockGate 是 DFT/库单元，作为黑盒由外层变体
// wrapper 例化并连到本核暴露的 ram_* 端口；本核只复刻 SRAMTemplate 的功能 wrapper
// 逻辑（上电清零状态机、读数据保持、写掩码展开、MBIST bore 与正常读写的多路复用、
// 时钟门控使能的产生）。
//
// 端口命名与 golden 保持一致以便 Formality 直接匹配（macro 接口用 ram_* 前缀）。
//
// ---- 本文件的四组能力开关（后四个是 G1 新增，默认值等于旧行为）----------------
//   ENABLE_RESET / ENABLE_HOLDREAD / ENABLE_CLOCKGATE / EXTRA_RESET / USE_BITMASK
//       旧有开关，语义见各自参数注释。
//   MASK_SEG_W    宏写掩码粒度细于 way 时的“掩码复制”（见 §写掩码）。
//   BORE_NSEG     MBIST bore 口窄于宏、一次只盖一段时的“分段 bore”（见 §MBIST）。
//   EXT_CLOCKGATE 时钟门控单元外置（见 §时钟门控）。
//   MCP_HOLD      多周期宏(s1h1l2)的隔拍门控与 2 拍读延迟（见 §多周期宏）。
// =============================================================================
module xs_SRAMTemplate_core #(
  parameter int unsigned SET        = 128,
  parameter int unsigned WAY        = 2,
  parameter int unsigned DATA_WIDTH = 37,   // 每 way 位宽
  parameter int unsigned BORE_AW    = 8,    // MBIST bore 地址位宽（由 MBIST 分组决定）
  parameter bit          ENABLE_RESET     = 1'b1,  // 上电清零 FSM
  parameter bit          ENABLE_HOLDREAD  = 1'b1,  // 读数据保持
  parameter bit          ENABLE_CLOCKGATE = 1'b1,  // 内部时钟门控（否则 ram_clk 直连 clock）
  parameter bit          EXTRA_RESET      = 1'b0,  // 额外复位口（重触发清零 FSM，如 TAGE useful 表）
  parameter bit          USE_BITMASK      = 1'b0,  // 1: per-bit 写掩码(MW位)；0: per-way(WAY位)

  // ---- 写掩码复制：宏的掩码粒度（位）。0 = 每 way 恰好一位，不复制（旧行为）----
  // 例 ptw_l1：宏 786 位按 131 位分 6 段，但只有 2 个 way（每 way 393 位 = 3 段），
  // 于是一个 way 的掩码位要复制 3 份盖住自己那 3 段，否则写一个 way 会连带写坏隔壁。
  parameter int unsigned MASK_SEG_W = 0,

  // ---- 分段 MBIST bore：bore 数据口只有宏的 1/BORE_NSEG 宽，一次盖一段 ----
  // 1 = bore 口覆盖整个宏（旧行为）。
  parameter int unsigned BORE_NSEG = 1,

  // ---- 时钟门控外置：本核只导出使能，门控好的时钟从 io_mbistCgCtl_rclk 收回 ----
  parameter bit          EXT_CLOCKGATE = 1'b0,

  // ---- 多周期宏：门控使能隔拍脉冲 + 读数据晚 2 拍回来 ----
  parameter bit          MCP_HOLD = 1'b0,

  localparam int unsigned AW  = (SET > 1) ? $clog2(SET) : 1,
  localparam int unsigned MW  = WAY * DATA_WIDTH,      // 宏数据总位宽
  // io_w_mask（功能写口）的宽度：per-bit 时是 MW，否则每 way 一位
  localparam int unsigned IN_MASK_W = USE_BITMASK ? MW : WAY,
  // 宏写掩码一位管多少数据位。默认 = 一个 way（per-way）或 1 位（per-bit）
  localparam int unsigned SEG_W   = (MASK_SEG_W == 0) ? (MW / IN_MASK_W) : MASK_SEG_W,
  localparam int unsigned WMASK_W = MW / SEG_W,        // 宏写掩码位宽
  localparam int unsigned MASK_REP = WMASK_W / IN_MASK_W,  // 每位功能掩码复制几份
  // MBIST bore 数据口宽度 / 掩码口宽度
  localparam int unsigned BORE_DW    = MW / BORE_NSEG,
  localparam int unsigned BORE_MSK_W = (BORE_NSEG == 1) ? WMASK_W : 1
)(
  input  logic                  clock,
  input  logic                  reset,
  // 读请求
  output logic                  io_r_req_ready,
  input  logic                  io_r_req_valid,
  input  logic [AW-1:0]         io_r_req_bits_setIdx,
  output logic [MW-1:0]         io_r_resp_data,        // {way(WAY-1)..way0}
  // 写请求
  input  logic                  io_w_req_valid,
  input  logic [AW-1:0]         io_w_req_bits_setIdx,
  input  logic [MW-1:0]         io_w_req_bits_data,    // {way(WAY-1)..way0}
  input  logic [IN_MASK_W-1:0]  io_w_mask,             // per-way(WAY) 或 per-bit(MW) 写掩码
  // 清零完成：golden 有的变体把它叫 io_resetDone，有的当 io_w_req_ready 用（同一根线）
  output logic                  io_resetDone,
  // broadcast（DFT 控制，多数透传给宏或仅 hold/bypass/cgen 参与逻辑）
  input  logic                  io_broadcast_ram_hold,
  input  logic                  io_broadcast_ram_bypass,
  input  logic                  io_broadcast_ram_bp_clken,
  input  logic                  io_broadcast_cgen,
  input  logic                  io_extra_reset,        // EXTRA_RESET=1 时有效，否则接 1'b0
  // 外置时钟门控接口（EXT_CLOCKGATE=1 时有效，否则三个输出悬空、rclk 不接）
  output logic                  io_mbistCgCtl_en,
  output logic                  io_mbistCgCtl_rckEn,
  output logic                  io_mbistCgCtl_wckEn,
  input  logic                  io_mbistCgCtl_rclk,
  // MBIST bore
  input  logic [BORE_AW-1:0]    boreChildrenBd_bore_addr,
  input  logic [BORE_AW-1:0]    boreChildrenBd_bore_addr_rd,
  input  logic [BORE_DW-1:0]    boreChildrenBd_bore_wdata,
  input  logic [BORE_MSK_W-1:0] boreChildrenBd_bore_wmask,
  input  logic                  boreChildrenBd_bore_re,
  input  logic                  boreChildrenBd_bore_we,
  output logic [BORE_DW-1:0]    boreChildrenBd_bore_rdata,
  input  logic                  boreChildrenBd_bore_ack,
  input  logic [BORE_NSEG-1:0]  boreChildrenBd_bore_selectedOH,
  // SRAM 宏接口（外层 wrapper 连到具体 sram_array_* 黑盒）
  output logic                  ram_clk,
  output logic                  ram_bypass,
  output logic                  ram_bp_clken,
  output logic [AW-1:0]         ram_addr,
  output logic                  ram_en,
  output logic                  ram_wmode,
  output logic [WMASK_W-1:0]    ram_wmask,
  output logic [MW-1:0]         ram_wdata,
  input  logic [MW-1:0]         ram_rdata
);

  // ---- 上电清零状态机：逐 set 写 0 ----
  logic           resetState;
  logic [AW-1:0]  resetSet;

  // ---- 控制 ----
  // ramRen/ramWen：送给宏的读/写请求（决定 ram_en / ram_wmode / ram_addr）。
  // rckEn/wckEn  ：送给时钟门控的使能。非多周期宏两者相等；多周期宏见 §多周期宏。
  logic ren, ramRen, ramWen, rckEn, wckEn, finalRamWen;
  // 单端口：写时不接受读；带 reset 时清零期间也不接受读
  assign io_resetDone   = ENABLE_RESET ? ~resetState : 1'b1;
  assign io_r_req_ready = io_resetDone & ~io_w_req_valid;
  assign ren         = io_r_req_ready & io_r_req_valid;
  assign ramWen      = boreChildrenBd_bore_ack ? boreChildrenBd_bore_we
                       : (io_w_req_valid | (ENABLE_RESET ? resetState : 1'b0));
  assign ramRen      = boreChildrenBd_bore_ack ? boreChildrenBd_bore_re : ren;
  assign finalRamWen = ramWen & ~io_broadcast_ram_hold;

  // ---- 读数据保持 ----
  logic           respCapture;    // 本拍宏读数据到齐，可以打进 MBIST 读数据寄存器
  logic           readLast;       // 上一拍是功能读（holdRead 用）
  logic [MW-1:0]  rdata_hold;
  logic [MW-1:0]  rdataReg;       // MBIST 读数据

  generate
  if (ENABLE_RESET) begin : g_reset
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        resetState <= 1'b1;
        resetSet   <= '0;
      end else begin
        // extra_reset 重触发清零；否则正常推进（清满 SET 个 set 后退出）
        resetState <= (EXTRA_RESET & io_extra_reset) | (~(resetState & (&resetSet)) & resetState);
        if (resetState) resetSet <= resetSet + AW'(1);
      end
    end
  end else begin : g_noreset
    assign resetState = 1'b0;
    assign resetSet   = '0;
  end
  endgenerate

  // =========================================================================
  // §多周期宏（MCP_HOLD）
  // 名字里带 s1h1l2 的宏要求地址/使能保持两拍、时钟只在其中一拍翻转。做法是把
  // 送门控的使能变成“隔拍脉冲”：使能寄存器存上一拍的脉冲，请求持续拉高时脉冲
  // 就在 1/0 之间交替，于是宏时钟两拍才走一个沿。宏的 en/wmode/addr 仍用未整形
  // 的 ramRen/ramWen，这样地址在两拍里都稳。读数据因此晚一个门控沿回来，
  // respReg 相应从 1 位变成 2 深移位。
  // =========================================================================
  generate
  if (MCP_HOLD) begin : g_mcp
    logic       rckEnReg, wckEnReg;
    logic [1:0] respReg;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        rckEnReg <= 1'b0;
        wckEnReg <= 1'b0;
        respReg  <= 2'b00;
      end else begin
        rckEnReg <= rckEn;
        wckEnReg <= wckEn;
        respReg  <= rckEn ? 2'b10 : {1'b0, respReg[1]};
      end
    end
    assign rckEn       = ramRen & ~rckEnReg;
    assign wckEn       = ramWen & ~wckEnReg;
    assign respCapture = respReg[0];
    assign readLast    = 1'b0;   // MCP 形态不用 holdRead
  end else begin : g_nomcp
    logic respReg;
    logic rdata_last_REG;        // 上一拍是否在读（功能读保持）
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        respReg        <= 1'b0;
        rdata_last_REG <= 1'b0;
      end else begin
        respReg        <= rckEn;
        // holdRead 关闭时 rdata_last_REG 是死状态(rdata_hold 不更新), 让它与 respReg 同方程
        // (rckEn), merge_duplicated_registers 合并掉→消 golden 无对应的 unread; holdRead 开
        // 时保持 ren(该路 live, 不动其 MBIST 行为)。参数守卫, 非全局改。
        rdata_last_REG <= ENABLE_HOLDREAD ? ren : rckEn;
      end
    end
    assign rckEn       = ramRen;
    assign wckEn       = ramWen;
    assign respCapture = respReg;
    assign readLast    = rdata_last_REG;
  end
  endgenerate

  always_ff @(posedge clock) begin
    if (ENABLE_HOLDREAD && readLast) rdata_hold <= ram_rdata;
    if (respCapture)                 rdataReg   <= ram_rdata;
  end

  // =========================================================================
  // §时钟门控
  // 三种形态：
  //   EXT_CLOCKGATE=1  门控单元不在本模块里。上层（SplittedSRAM / L2 Slice）把同
  //                    一组 SRAM 的门控时钟合并共享——省面积，也让 MBIST 能用一套
  //                    控制统一开关整组——所以本模块只把使能导出去(io_mbistCgCtl_*)，
  //                    再从 io_mbistCgCtl_rclk 把已经门控好的时钟收回来喂宏。
  //   ENABLE_CLOCKGATE=1 门控单元在本模块内例化（通用 DFT 单元，不是可读逻辑）。
  //   两者都 0          宏时钟直连 clock。
  // =========================================================================
  assign io_mbistCgCtl_en    = boreChildrenBd_bore_ack;
  assign io_mbistCgCtl_rckEn = rckEn;
  assign io_mbistCgCtl_wckEn = wckEn;

  generate
  if (EXT_CLOCKGATE) begin : g_extcg
    assign ram_clk = io_mbistCgCtl_rclk;
  end else if (ENABLE_CLOCKGATE) begin : g_cg
    MbistClockGateCell rcg (
      .clock         (clock),
      .mbist_writeen (wckEn),
      .mbist_readen  (rckEn),
      .mbist_req     (boreChildrenBd_bore_ack),
      .E             (rckEn | wckEn),
      .dft_cgen      (io_broadcast_cgen),
      .out_clock     (ram_clk)
    );
  end else begin : g_nocg
    assign ram_clk = clock;
  end
  endgenerate

  // =========================================================================
  // §写掩码
  // 功能写口给的是“每 way 一位”（per-bit 模式则是每位一位），宏要的是“每个掩码段
  // 一位”。段宽 SEG_W 可能比一个 way 窄，这时把一位掩码复制 MASK_REP 份盖住它自己
  // 的那几段。MASK_REP=1（绝大多数变体）时下面这行就是纯透传。
  // =========================================================================
  logic [WMASK_W-1:0] wmaskExpanded;
  for (genvar s = 0; s < int'(WMASK_W); s++) begin : g_wmask
    assign wmaskExpanded[s] = io_w_mask[s / int'(MASK_REP)];
  end

  // =========================================================================
  // §MBIST
  // MBIST 的 bore 口按“分组数据宽度”切，和宏本身的宽度不一定对齐，于是有两种形态：
  //   BORE_NSEG=1  bore 口覆盖整个宏。selectedOH 只有 1 位（“这一组里选中了本 SRAM”），
  //                逐段掩码由 bore_wmask 给（宽 WMASK_W）。
  //   BORE_NSEG>1  bore 口只有宏的 1/N 宽，一次盖一段。selectedOH 每段一位（选中哪一段），
  //                bore_wmask 退化成 1 位（这一段整段写/不写）；写数据要复制 N 份，靠
  //                掩码挑出真正要落的那一段；读回则要按写入时锁存的 selectedOH 把
  //                对应那一段切出来。此形态下 BORE_NSEG == WMASK_W（段即掩码段）。
  // =========================================================================
  logic [WMASK_W-1:0] boreWmaskExpanded;
  logic [MW-1:0]      boreWdataExpanded;

  generate
  if (BORE_NSEG == 1) begin : g_bore_full
    assign boreWmaskExpanded = {WMASK_W{boreChildrenBd_bore_selectedOH[0]}}
                               & boreChildrenBd_bore_wmask;
    assign boreWdataExpanded = boreChildrenBd_bore_wdata;
    assign boreChildrenBd_bore_rdata = rdataReg;
  end else begin : g_bore_seg
    logic [BORE_NSEG-1:0] selectOHReg;   // 读回时用的段选择：与 rdataReg 同拍锁存
    logic [BORE_DW-1:0]   boreRdataSel;

    assign boreWmaskExpanded = boreChildrenBd_bore_selectedOH
                               & {BORE_NSEG{boreChildrenBd_bore_wmask[0]}};
    assign boreWdataExpanded = {BORE_NSEG{boreChildrenBd_bore_wdata}};

    always_ff @(posedge clock) begin
      if (respCapture) selectOHReg <= boreChildrenBd_bore_selectedOH;
    end

    always_comb begin
      boreRdataSel = '0;
      for (int unsigned s = 0; s < BORE_NSEG; s++)
        boreRdataSel |= {BORE_DW{selectOHReg[s]}} & rdataReg[s*BORE_DW +: BORE_DW];
    end
    assign boreChildrenBd_bore_rdata = boreRdataSel;
  end
  endgenerate

  // ---- 送宏的控制/数据 ----
  assign ram_bypass   = io_broadcast_ram_bypass;
  assign ram_bp_clken = io_broadcast_ram_bp_clken;
  assign ram_addr =
    boreChildrenBd_bore_ack ? boreChildrenBd_bore_addr_rd[AW-1:0]
                            : finalRamWen ? (resetState ? resetSet : io_w_req_bits_setIdx)
                                          : io_r_req_bits_setIdx;
  assign ram_en    = finalRamWen | ramRen;
  assign ram_wmode = finalRamWen;
  assign ram_wmask =
    boreChildrenBd_bore_ack ? boreWmaskExpanded
                            : (resetState ? {WMASK_W{1'b1}} : wmaskExpanded);
  assign ram_wdata =
    boreChildrenBd_bore_ack ? boreWdataExpanded
                            : (resetState ? '0 : io_w_req_bits_data);

  // ---- 输出 ----
  // holdRead：非读拍输出保持上次读值；关闭时直接透出宏读数据
  assign io_r_resp_data = ENABLE_HOLDREAD ? (readLast ? ram_rdata : rdata_hold)
                                          : ram_rdata;

endmodule
