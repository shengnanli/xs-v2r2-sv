// SRAMTemplate_201 —— L2 SubDirectory replacer SRAM 叶(可读重写, 含复位扫描)。
// 1 way × 15bit, 深度 2^12; 单口。特点: **复位扫描(reset-sweep)** —— 复位后逐地址写 0
// 清空整存储, 扫完转正常。array_0_0(→array_ext 硬宏)作存储边界。
module SRAMTemplate_201 (
  input         clock,
  input         reset,
  input         io_r_req_valid,
  input  [11:0] io_r_req_bits_setIdx,
  output [14:0] io_r_resp_data_0,
  input         io_w_req_valid,
  input  [11:0] io_w_req_bits_setIdx,
  input  [14:0] io_w_req_bits_data_0
);
  // 复位扫描: 复位后 reset_sweep=1, sweep_addr 从 0 逐拍自增, 每拍向 sweep_addr 写 0;
  // 扫到 sweep_addr 全 1(最后一个地址)后清 reset_sweep, 转正常读写。
  reg        reset_sweep;
  reg [11:0] sweep_addr;

  // 写占口: 扫描期或外部写都占用物理写口, 读仅在无写时进行(写优先)。
  wire        wen     = io_w_req_valid | reset_sweep;
  wire        realRen = io_r_req_valid & ~wen;
  wire [11:0] setIdx  = reset_sweep ? sweep_addr : io_w_req_bits_setIdx;

  always @(posedge clock or posedge reset)
    if (reset) begin
      reset_sweep <= 1'b1;
      sweep_addr  <= 12'h0;
    end else begin
      reset_sweep <= reset_sweep & ~(&sweep_addr);   // 扫到全1(末地址)后退出扫描
      if (reset_sweep) sweep_addr <= sweep_addr + 12'h1;
    end

  array_0_0 array_0 (
    .RW0_addr  (wen ? setIdx : io_r_req_bits_setIdx),
    .RW0_en    (realRen | wen),
    .RW0_clk   (clock),
    .RW0_wmode (wen),
    .RW0_wdata (reset_sweep ? 15'h0 : io_w_req_bits_data_0),
    .RW0_rdata (io_r_resp_data_0)
  );
endmodule
