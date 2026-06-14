// =============================================================================
// xs_SRAMTemplate_core —— SRAMTemplate 功能逻辑核（单端口 + reset清零 + holdRead +
//                          MBIST bore 复用 + 内部时钟门控）
//
// 对应 Chisel: utility.sram.SRAMTemplate（hasMbist=true, singlePort=true,
//   shouldReset=true, holdRead=true, withClockGate/extraHold 隐含内部门控的变体）
//
// 设计取舍（见工程 README 的 SRAM 路线决策）：真实存储体（厂商宏 sram_array_* →
// array → array_ext）与时钟门控基元 ClockGate 是 DFT/库单元，作为黑盒由外层变体
// wrapper 例化并连到本核暴露的 RW0_* 端口；本核只复刻 SRAMTemplate 的功能 wrapper
// 逻辑（上电清零状态机、读数据保持、MBIST bore 与正常读写的多路复用），并在核内
// 例化通用的 MbistClockGateCell 产生送给宏的门控时钟。
//
// 端口命名与 golden 保持一致以便 Formality 直接匹配（macro 接口用 ram_* 前缀）。
// =============================================================================
module xs_SRAMTemplate_core #(
  parameter int unsigned SET        = 128,
  parameter int unsigned WAY        = 2,
  parameter int unsigned DATA_WIDTH = 37,   // 每 way 位宽
  parameter int unsigned BORE_AW    = 8,    // MBIST bore 地址位宽（由 MBIST 分组决定）
  localparam int unsigned AW = (SET > 1) ? $clog2(SET) : 1,
  localparam int unsigned MW = WAY * DATA_WIDTH   // 宏数据总位宽（无 bitmask）
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
  input  logic [WAY-1:0]        io_w_req_bits_waymask,
  // broadcast（DFT 控制，多数透传给宏或仅 hold/bypass/cgen 参与逻辑）
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
  // SRAM 宏接口（外层 wrapper 连到具体 sram_array_* 黑盒）
  output logic                  ram_clk,
  output logic                  ram_bypass,
  output logic                  ram_bp_clken,
  output logic [AW-1:0]         ram_addr,
  output logic                  ram_en,
  output logic                  ram_wmode,
  output logic [WAY-1:0]        ram_wmask,
  output logic [MW-1:0]         ram_wdata,
  input  logic [MW-1:0]         ram_rdata
);

  // ---- 上电清零状态机：逐 set 写 0 ----
  logic           resetState;
  logic [AW-1:0]  resetSet;

  // ---- 控制 ----
  logic ren, wckEn, rckEn, finalRamWen;
  assign io_r_req_ready = ~resetState & ~io_w_req_valid;   // 单端口：写时不接受读
  assign ren         = io_r_req_ready & io_r_req_valid;
  assign wckEn       = boreChildrenBd_bore_ack ? boreChildrenBd_bore_we
                                               : (io_w_req_valid | resetState);
  assign rckEn       = boreChildrenBd_bore_ack ? boreChildrenBd_bore_re : ren;
  assign finalRamWen = wckEn & ~io_broadcast_ram_hold;

  // ---- 读数据保持 ----
  logic           respReg;        // 闸 MBIST 读数据捕获
  logic           rdata_last_REG; // 上一拍是否在读（功能读保持）
  logic [MW-1:0]  rdata_hold;
  logic [MW-1:0]  rdataReg;       // MBIST 读数据

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resetState     <= 1'b1;
      resetSet       <= '0;
      respReg        <= 1'b0;
      rdata_last_REG <= 1'b0;
    end else begin
      resetState <= ~(resetState & (&resetSet)) & resetState;
      if (resetState) resetSet <= resetSet + AW'(1);
      respReg        <= rckEn;
      rdata_last_REG <= ren;
    end
  end

  always_ff @(posedge clock) begin
    if (rdata_last_REG) rdata_hold <= ram_rdata;
    if (respReg)        rdataReg   <= ram_rdata;
  end

  // ---- 时钟门控（通用 DFT 单元，核内例化）----
  MbistClockGateCell rcg (
    .clock         (clock),
    .mbist_writeen (wckEn),
    .mbist_readen  (rckEn),
    .mbist_req     (boreChildrenBd_bore_ack),
    .E             (rckEn | wckEn),
    .dft_cgen      (io_broadcast_cgen),
    .out_clock     (ram_clk)
  );

  // ---- 送宏的控制/数据 ----
  assign ram_bypass   = io_broadcast_ram_bypass;
  assign ram_bp_clken = io_broadcast_ram_bp_clken;
  assign ram_addr =
    boreChildrenBd_bore_ack ? boreChildrenBd_bore_addr_rd[AW-1:0]
                            : finalRamWen ? (resetState ? resetSet : io_w_req_bits_setIdx)
                                          : io_r_req_bits_setIdx;
  assign ram_en    = finalRamWen | rckEn;
  assign ram_wmode = finalRamWen;
  assign ram_wmask =
    boreChildrenBd_bore_ack ? ({WAY{boreChildrenBd_bore_selectedOH}} & boreChildrenBd_bore_wmask)
                            : (resetState ? {WAY{1'b1}} : io_w_req_bits_waymask);
  assign ram_wdata =
    boreChildrenBd_bore_ack ? boreChildrenBd_bore_wdata
                            : (resetState ? '0 : io_w_req_bits_data);

  // ---- 输出 ----
  assign io_r_resp_data = rdata_last_REG ? ram_rdata : rdata_hold;
  assign boreChildrenBd_bore_rdata = rdataReg;

endmodule
