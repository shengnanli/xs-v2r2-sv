// 负测台：证明 xs_DelayN_core 的端口契约不变式真会拦下"位宽被静默改小"。
// 下面是 DelayN_9 薄文件的复制品，唯一改动：io_in_bits_addr 从 golden 的 50 位
// 抄成 49 位（本轮已发生 3 次的事故形态——端口位宽变了、逻辑一行没动、UT 按旧
// 位宽驱动照样全绿，只有 FM 才炸）。
// 期望：PORT_BITS_IN=71 != WIDTH=72，core 在 time 0 $fatal。
// 若跑到 NEGTEST_UNREACHED，说明不变式形同虚设，Makefile 的 negtest 目标判 FAIL。
module neg_delayn_narrow_port(
  input         clock,
  input         io_in_valid,
  input         io_in_bits_rs1,
  input         io_in_bits_rs2,
  input  [48:0] io_in_bits_addr,   // <-- 抄错：golden 是 [49:0]
  input  [15:0] io_in_bits_id,
  input         io_in_bits_flushPipe,
  input         io_in_bits_hv,
  input         io_in_bits_hg,
  output        io_out_valid,
  output        io_out_bits_rs1,
  output        io_out_bits_rs2,
  output [49:0] io_out_bits_addr,
  output [15:0] io_out_bits_id,
  output        io_out_bits_flushPipe,
  output        io_out_bits_hv,
  output        io_out_bits_hg
);
  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 144;
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_valid, io_in_bits_rs1, io_in_bits_rs2, io_in_bits_addr, io_in_bits_id,
     io_in_bits_flushPipe, io_in_bits_hv, io_in_bits_hg});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_valid, io_out_bits_rs1, io_out_bits_rs2, io_out_bits_addr, io_out_bits_id,
     io_out_bits_flushPipe, io_out_bits_hv, io_out_bits_hg});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_valid, io_in_bits_rs1, io_in_bits_rs2, io_in_bits_addr, io_in_bits_id,
     io_in_bits_flushPipe, io_in_bits_hv, io_in_bits_hg};

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock(clock),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
    {io_out_valid, io_out_bits_rs1, io_out_bits_rs2, io_out_bits_addr, io_out_bits_id,
     io_out_bits_flushPipe, io_out_bits_hv, io_out_bits_hg} = payload_out;
endmodule

module neg_tb;
  bit clock = 0;
  wire o_valid, o_rs1, o_rs2, o_fp, o_hv, o_hg;
  wire [49:0] o_addr;
  wire [15:0] o_id;
  neg_delayn_narrow_port u_dut (
    .clock(clock),
    .io_in_valid(1'b0), .io_in_bits_rs1(1'b0), .io_in_bits_rs2(1'b0),
    .io_in_bits_addr(49'h0), .io_in_bits_id(16'h0), .io_in_bits_flushPipe(1'b0),
    .io_in_bits_hv(1'b0), .io_in_bits_hg(1'b0),
    .io_out_valid(o_valid), .io_out_bits_rs1(o_rs1), .io_out_bits_rs2(o_rs2),
    .io_out_bits_addr(o_addr), .io_out_bits_id(o_id), .io_out_bits_flushPipe(o_fp),
    .io_out_bits_hv(o_hv), .io_out_bits_hg(o_hg)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下位宽抄错");
    $finish;
  end
endmodule
