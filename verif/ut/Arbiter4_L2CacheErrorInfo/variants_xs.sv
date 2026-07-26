// UT 变体(_xs 顶层), 内容同 rtl 包装层, 仅顶层名加 _xs 后缀。
// 4 输入固定优先级仲裁器可读实现: xs_arbiter4_core.
// golden Arbiter4_L2CacheErrorInfo: 无 ready/chosen 端口 (无背压), payload =
// {bits_valid(1), bits_address(46)}。核的 ready/chosen 输出悬空不用。
module Arbiter4_L2CacheErrorInfo_xs(
  input         io_in_0_valid,
  input         io_in_0_bits_valid,
  input  [45:0] io_in_0_bits_address,
  input         io_in_1_valid,
  input         io_in_1_bits_valid,
  input  [45:0] io_in_1_bits_address,
  input         io_in_2_valid,
  input         io_in_2_bits_valid,
  input  [45:0] io_in_2_bits_address,
  input         io_in_3_valid,
  input         io_in_3_bits_valid,
  input  [45:0] io_in_3_bits_address,
  output        io_out_valid,
  output        io_out_bits_valid,
  output [45:0] io_out_bits_address
);
  // ---- 4 输入固定优先级仲裁器: xs_arbiter4_core (WIDTH=47) ----
  localparam int unsigned W = 47;
  logic [3:0]   c_valids;
  logic [3:0]   c_readies;   // 悬空 (golden 无 ready 端口)
  logic [W-1:0] c_pin [4];
  logic [W-1:0] c_pout;
  logic [1:0]   c_chosen;    // 悬空 (golden 无 chosen 端口)
  wire          c_out_valid;

  assign c_valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign c_pin[0] = {io_in_0_bits_valid, io_in_0_bits_address};
  assign c_pin[1] = {io_in_1_bits_valid, io_in_1_bits_address};
  assign c_pin[2] = {io_in_2_bits_valid, io_in_2_bits_address};
  assign c_pin[3] = {io_in_3_bits_valid, io_in_3_bits_address};

  xs_arbiter4_core #(.WIDTH(W)) u_core (
    .valids(c_valids), .out_ready(1'b1), .pin(c_pin),
    .readies(c_readies), .out_valid(c_out_valid), .pout(c_pout), .chosen(c_chosen)
  );

  assign io_out_valid       = c_out_valid;
  assign io_out_bits_valid  = c_pout[46];
  assign io_out_bits_address = c_pout[45:0];
endmodule
