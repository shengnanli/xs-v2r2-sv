// 负测台[反向 必须拦下]：证明 xs_DelayReg_core 的端口契约不变式真会拦下
// "位宽被静默改小"。下面是 DelayReg_26 薄文件的复制品，唯一改动：
// i_mask 从 golden 的 16 位抄成 15 位（本轮已发生 3 次的事故形态——端口位宽变了、
// 逻辑一行没动、UT 按旧位宽驱动照样全绿，只有 FM 才炸）。
// 期望：PORT_BITS_IN=324 != WIDTH=325，core 在 time 0 $fatal。
// 若跑到 NEGTEST_UNREACHED，说明不变式形同虚设，Makefile 的 negtest 判 FAIL。
// ★这一半单独看是不够的★：一个"恒 $fatal"的核也会让它显示 PASS。
// 正向那一半在 negtest_ok.sv。
// 自动生成：verif/ut/DelayReg/gen_negtest.py —— 勿手改

module neg_delayreg_narrow_port(
  input         clock,
  input         reset,
  input         i_valid,
  input  [63:0] i_addr,
  input  [63:0] i_data,
  input  [63:0] i_highData,
  input  [14:0] i_mask,   // <-- 抄错：golden 是 [15:0]
  input         i_wLine,
  input         i_vecNeedSplit,
  input  [7:0]  i_eew,
  input  [15:0] i_offset,
  input  [63:0] i_pc,
  input  [9:0]  i_robidx,
  input  [7:0]  i_coreid,
  input  [7:0]  i_index,
  output        o_valid,
  output [63:0] o_addr,
  output [63:0] o_data,
  output [63:0] o_highData,
  output [15:0] o_mask,
  output        o_wLine,
  output        o_vecNeedSplit,
  output [7:0]  o_eew,
  output [15:0] o_offset,
  output [63:0] o_pc,
  output [9:0]  o_robidx,
  output [7:0]  o_coreid,
  output [7:0]  o_index,
  input         enable
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 650;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {i_valid, i_addr, i_data, i_highData, i_mask, i_wLine, i_vecNeedSplit, i_eew,
     i_offset, i_pc, i_robidx, i_coreid, i_index});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {o_valid, o_addr, o_data, o_highData, o_mask, o_wLine, o_vecNeedSplit, o_eew,
     o_offset, o_pc, o_robidx, o_coreid, o_index});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
    {i_valid, i_addr, i_data, i_highData, i_mask, i_wLine, i_vecNeedSplit, i_eew,
     i_offset, i_pc, i_robidx, i_coreid, i_index};

  xs_DelayReg_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock (clock),
    .reset (reset),
    .enable(enable),
    .d_in  (payload_in),
    .d_out (payload_out)
  );

  // 拆包：与上面的打包次序互逆。
  assign
    {o_valid, o_addr, o_data, o_highData, o_mask, o_wLine, o_vecNeedSplit, o_eew,
     o_offset, o_pc, o_robidx, o_coreid, o_index} = payload_out;

endmodule

module neg_tb;
  bit clock = 0;
  wire o_valid, o_wLine, o_vecNeedSplit;
  wire [63:0] o_addr, o_data, o_highData, o_pc;
  wire [15:0] o_mask, o_offset;
  wire [7:0]  o_eew, o_coreid, o_index;
  wire [9:0]  o_robidx;
  neg_delayreg_narrow_port u_dut (
    .clock(clock), .reset(1'b1), .enable(1'b0),
    .i_valid(1'b0), .i_addr(64'h0), .i_data(64'h0), .i_highData(64'h0),
    .i_mask(15'h0), .i_wLine(1'b0), .i_vecNeedSplit(1'b0), .i_eew(8'h0),
    .i_offset(16'h0), .i_pc(64'h0), .i_robidx(10'h0), .i_coreid(8'h0), .i_index(8'h0),
    .o_valid(o_valid), .o_addr(o_addr), .o_data(o_data), .o_highData(o_highData),
    .o_mask(o_mask), .o_wLine(o_wLine), .o_vecNeedSplit(o_vecNeedSplit), .o_eew(o_eew),
    .o_offset(o_offset), .o_pc(o_pc), .o_robidx(o_robidx), .o_coreid(o_coreid),
    .o_index(o_index)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下位宽抄错");
    $finish;
  end
endmodule
