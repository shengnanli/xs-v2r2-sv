// stateBankTags_320x3 —— DiffRatStateBuffer 的「槽在哪个 bank」标签存储（firtool 行为级存储叶子）
// golden 对照: G1-canonical/golden-rtl/stateBankTags_320x3.sv（148 行）
// 320 项 × 3 位，1 读口 / 6 写口（每路 rename 一个）。同拍多口写同址时**后面的口赢**
// （golden 同一 always 块内 W0..W5 顺序非阻塞赋值）；深度 320 非 2 的幂，越界写无效、越界读为 X。
module stateBankTags_320x3(
  input  [8:0] R0_addr,
  input        R0_en,
  input        R0_clk,
  output [2:0] R0_data,
  input  [8:0] W0_addr, input W0_en, input W0_clk, input [2:0] W0_data,
  input  [8:0] W1_addr, input W1_en, input W1_clk, input [2:0] W1_data,
  input  [8:0] W2_addr, input W2_en, input W2_clk, input [2:0] W2_data,
  input  [8:0] W3_addr, input W3_en, input W3_clk, input [2:0] W3_data,
  input  [8:0] W4_addr, input W4_en, input W4_clk, input [2:0] W4_data,
  input  [8:0] W5_addr, input W5_en, input W5_clk, input [2:0] W5_data
);
  reg [2:0] Memory [0:319];
  always @(posedge W0_clk) begin
    if (W0_en) Memory[W0_addr] <= W0_data;
    if (W1_en) Memory[W1_addr] <= W1_data;
    if (W2_en) Memory[W2_addr] <= W2_data;
    if (W3_en) Memory[W3_addr] <= W3_data;
    if (W4_en) Memory[W4_addr] <= W4_data;
    if (W5_en) Memory[W5_addr] <= W5_data;
  end
  assign R0_data = R0_en ? Memory[R0_addr] : 3'bx;
endmodule
