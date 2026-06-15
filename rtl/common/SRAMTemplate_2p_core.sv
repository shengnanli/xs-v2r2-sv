// =============================================================================
// xs_SRAMTemplate_2p_core —— 双端口（2p）同步 SRAM 功能核（读/写口分离 + 读写冲突缓冲）
//
// 对应 Chisel: utility.sram.SRAMTemplate（singlePort=false，带 conflictBehavior 的变体，
//   如 bp_sc / bp_tage_bt）。与单口核 xs_SRAMTemplate_core 的区别：
//   - 物理宏是 2p：独立读口 R0(clk/addr/en/data) + 写口 W0(clk/addr/en/data/mask)，
//     读写可同拍进行（不像单口 1 个 RW 口要二选一）；
//   - 因此 io_r_req_ready = ~resetState（写不再阻塞读）；读、写各有独立时钟门控；
//   - **读写冲突缓冲**：读和写同拍命中同一 set 时，直接写阵列会破坏并发读。于是把该次写
//     缓冲一拍（conflict*S1 寄存器），延后重放到阵列；其间若有读命中这个"待写"的地址，
//     就把缓冲里的数据旁路给读（bypassEnable）。这保证"写后立即读同址"看到新值，且读不被写扰动。
//
// 真实存储宏（sram_array_2p*→...→array_ext）与 ClockGate 作 DFT 黑盒，由变体 wrapper 例化，
// 连到本核暴露的 r_*/w_* 端口；本核复刻功能 wrapper 逻辑 + 核内例化 MbistClockGateCell。
// =============================================================================
module xs_SRAMTemplate_2p_core #(
  parameter int unsigned SET        = 256,
  parameter int unsigned WAY        = 4,
  parameter int unsigned DATA_WIDTH = 6,    // 每 way 位宽
  parameter int unsigned BORE_AW    = 9,
  localparam int unsigned AW = (SET > 1) ? $clog2(SET) : 1,
  localparam int unsigned MW = WAY * DATA_WIDTH
)(
  input  logic                  clock,
  input  logic                  reset,
  output logic                  io_r_req_ready,
  input  logic                  io_r_req_valid,
  input  logic [AW-1:0]         io_r_req_bits_setIdx,
  output logic [MW-1:0]         io_r_resp_data,
  input  logic                  io_w_req_valid,
  input  logic [AW-1:0]         io_w_req_bits_setIdx,
  input  logic [MW-1:0]         io_w_req_bits_data,
  input  logic [WAY-1:0]        io_w_req_bits_waymask,
  // broadcast
  input  logic                  io_broadcast_ram_hold,
  input  logic                  io_broadcast_ram_bypass,
  input  logic                  io_broadcast_ram_bp_clken,
  input  logic                  io_broadcast_cgen,
  // MBIST bore
  input  logic [BORE_AW-1:0]    boreChildrenBd_bore_addr,
  input  logic [BORE_AW-1:0]    boreChildrenBd_bore_addr_rd,
  input  logic [MW-1:0]         boreChildrenBd_bore_wdata,
  input  logic [WAY-1:0]        boreChildrenBd_bore_wmask,
  input  logic                  boreChildrenBd_bore_re,
  input  logic                  boreChildrenBd_bore_we,
  output logic [MW-1:0]         boreChildrenBd_bore_rdata,
  input  logic                  boreChildrenBd_bore_ack,
  input  logic                  boreChildrenBd_bore_selectedOH,
  // 2p SRAM 宏接口
  output logic                  ram_bypass,
  output logic                  ram_bp_clken,
  output logic                  r_clk,
  output logic [AW-1:0]         r_addr,
  output logic                  r_en,
  input  logic [MW-1:0]         r_data,
  output logic                  w_clk,
  output logic [AW-1:0]         w_addr,
  output logic                  w_en,
  output logic [MW-1:0]         w_data,
  output logic [WAY-1:0]        w_mask
);
  localparam logic [WAY-1:0] WAY_ALL1 = {WAY{1'b1}};

  // ---- 上电清零 FSM（经写口 W0 逐 set 写 0）----
  logic           resetState;
  logic [AW-1:0]  resetSet;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin resetState <= 1'b1; resetSet <= '0; end
    else begin
      resetState <= ~(resetState & (&resetSet)) & resetState;
      if (resetState) resetSet <= resetSet + AW'(1);
    end
  end

  wire bore_ack = boreChildrenBd_bore_ack;

  // ---- 读写冲突检测：同拍读写命中同一 set（且写掩码非空）----
  wire conflict_s0 = io_r_req_valid & io_w_req_valid & (|io_w_req_bits_waymask)
                   & (io_r_req_bits_setIdx == io_w_req_bits_setIdx);

  // ---- 冲突缓冲（S1）：缓冲被推迟的那次写 + 当拍读地址 ----
  logic            cbuf_valid;        // 缓冲里有一笔待重放的写
  logic [AW-1:0]   cbuf_raddr;        // 上一拍的读地址
  logic [AW-1:0]   cbuf_waddr;        // 缓冲写的目标 set
  logic [WAY-1:0]  cbuf_wmask;
  logic [MW-1:0]   cbuf_wdata;
  logic            bypass_en_r;       // 上一拍有读（用于产生 bypassEnable）

  // 本拍若有新读命中"待写地址" → 不能重放写（否则又冲突）；否则可重放
  wire cbuf_can_write = ~(io_r_req_valid & (io_r_req_bits_setIdx == cbuf_waddr));
  wire cbuf_write     = cbuf_valid & cbuf_can_write;   // 本拍把缓冲的写重放到阵列
  // 读命中"待写且尚未重放"的地址 → 把缓冲数据旁路给读
  wire bypass_en      = cbuf_valid & bypass_en_r & (cbuf_raddr == cbuf_waddr);

  // ---- 控制 ----
  wire ren   = io_r_req_ready & io_r_req_valid;
  // 写阵列：MBIST / (正常写且不冲突) / 重放缓冲写 / 清零
  wire wckEn = bore_ack ? boreChildrenBd_bore_we
                        : ((io_w_req_valid & ~conflict_s0) | cbuf_write | resetState);
  wire rckEn = bore_ack ? boreChildrenBd_bore_re : ren;
  wire finalRamWen = wckEn & ~io_broadcast_ram_hold;

  assign io_r_req_ready = ~resetState;   // 双口：写不阻塞读

  // ---- 冲突缓冲寄存器更新 ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) cbuf_valid <= 1'b0;
    else cbuf_valid <= conflict_s0 | (cbuf_valid & (~cbuf_can_write | io_w_req_valid));
  end
  always_ff @(posedge clock) begin
    if (io_r_req_valid) cbuf_raddr <= io_r_req_bits_setIdx;
    bypass_en_r <= io_r_req_valid;
    // 新冲突，或正在重放缓冲（此拍若来新写需接管缓冲槽）→ 锁存当拍写请求
    if (conflict_s0 | cbuf_write) begin
      cbuf_waddr <= io_w_req_bits_setIdx;
      cbuf_wmask <= io_w_req_bits_waymask;
      cbuf_wdata <= io_w_req_bits_data;
    end
  end

  // ---- 读数据保持 + MBIST 读捕获 ----
  logic           respReg, rdata_last_REG;
  logic [MW-1:0]  rdata_hold, rdataReg;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin respReg <= 1'b0; rdata_last_REG <= 1'b0; end
    else begin respReg <= rckEn; rdata_last_REG <= ren; end
  end

  // 读数据：命中缓冲（且该 way 被缓冲写过）则旁路缓冲数据，否则用阵列读出
  logic [MW-1:0] mem_rdata;
  always_comb begin
    for (int unsigned w = 0; w < WAY; w++)
      mem_rdata[w*DATA_WIDTH +: DATA_WIDTH] =
        (bypass_en & cbuf_wmask[w]) ? cbuf_wdata[w*DATA_WIDTH +: DATA_WIDTH]
                                    : r_data[w*DATA_WIDTH +: DATA_WIDTH];
  end

  always_ff @(posedge clock) begin
    if (rdata_last_REG) rdata_hold <= mem_rdata;
    if (respReg)        rdataReg   <= r_data;    // MBIST 读出取原始阵列数据（无冲突旁路）
  end

  // ---- 两个时钟门控：读 / 写 各一 ----
  MbistClockGateCell rcg (
    .clock(clock), .mbist_writeen(1'b0), .mbist_readen(rckEn),
    .mbist_req(bore_ack), .E(rckEn), .dft_cgen(io_broadcast_cgen), .out_clock(r_clk));
  MbistClockGateCell wcg (
    .clock(clock), .mbist_writeen(wckEn), .mbist_readen(1'b0),
    .mbist_req(bore_ack), .E(wckEn), .dft_cgen(io_broadcast_cgen), .out_clock(w_clk));

  // ---- 送宏：读口 / 写口分离 ----
  assign ram_bypass   = io_broadcast_ram_bypass;
  assign ram_bp_clken = io_broadcast_ram_bp_clken;
  assign r_addr = bore_ack ? boreChildrenBd_bore_addr_rd[AW-1:0] : io_r_req_bits_setIdx;
  assign r_en   = rckEn;
  assign w_addr = bore_ack ? boreChildrenBd_bore_addr[AW-1:0]
                : cbuf_write ? cbuf_waddr
                : resetState ? resetSet : io_w_req_bits_setIdx;
  assign w_en   = finalRamWen;
  assign w_mask = bore_ack ? ({WAY{boreChildrenBd_bore_selectedOH}} & boreChildrenBd_bore_wmask)
                : cbuf_write ? cbuf_wmask
                : resetState ? WAY_ALL1 : io_w_req_bits_waymask;
  assign w_data = bore_ack ? boreChildrenBd_bore_wdata
                : cbuf_write ? cbuf_wdata
                : resetState ? '0 : io_w_req_bits_data;

  // ---- 输出 ----
  assign io_r_resp_data            = rdata_last_REG ? mem_rdata : rdata_hold;
  assign boreChildrenBd_bore_rdata = rdataReg;

endmodule
