// diff_rat_state_bank_320x776 —— DiffRatStateBuffer 的快照存储 bank（firtool 行为级存储叶子）
// golden 对照: G1-canonical/golden-rtl/diff_rat_state_bank_320x776.sv（120 行）
// 320 项 × 776 位（一整张 difftest 重命名表），1 读口（同步使能、组合读出）/ 1 写口。
// 深度 320 不是 2 的幂：地址 9 位可表示 512，越界写在 SV 数组语义下无效、越界读为 X（照 golden）。
// R0_en=0 时读出 X（golden `R0_en ? Memory[addr] : 'x`）；调用方恒接 1。
module diff_rat_state_bank_320x776(
  input  [8:0]   R0_addr,
  input          R0_en,
  input          R0_clk,
  output [775:0] R0_data,
  input  [8:0]   W0_addr,
  input          W0_en,
  input          W0_clk,
  input  [775:0] W0_data
);
  reg [775:0] Memory [0:319];
  always @(posedge W0_clk)
    if (W0_en) Memory[W0_addr] <= W0_data;
  assign R0_data = R0_en ? Memory[R0_addr] : 776'bx;
endmodule
