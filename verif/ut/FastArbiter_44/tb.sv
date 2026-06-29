// 自动生成：scripts/gen_fastarbiter.py —— 勿手改
// FastArbiter_44 双例化逐拍比对: golden FastArbiter_44 vs 可读 FastArbiter_44_xs。
// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic io_in_0_valid;
  logic [11:0] io_in_0_bits_txnID;
  logic [10:0] io_in_0_bits_fwdNID;
  logic [11:0] io_in_0_bits_fwdTxnID;
  logic [4:0] io_in_0_bits_opcode;
  logic [44:0] io_in_0_bits_addr;
  logic io_in_0_bits_doNotGoToSD;
  logic io_in_0_bits_retToSrc;
  logic io_in_1_valid;
  logic [11:0] io_in_1_bits_txnID;
  logic [10:0] io_in_1_bits_fwdNID;
  logic [11:0] io_in_1_bits_fwdTxnID;
  logic [4:0] io_in_1_bits_opcode;
  logic [44:0] io_in_1_bits_addr;
  logic io_in_1_bits_doNotGoToSD;
  logic io_in_1_bits_retToSrc;
  logic io_in_2_valid;
  logic [11:0] io_in_2_bits_txnID;
  logic [10:0] io_in_2_bits_fwdNID;
  logic [11:0] io_in_2_bits_fwdTxnID;
  logic [4:0] io_in_2_bits_opcode;
  logic [44:0] io_in_2_bits_addr;
  logic io_in_2_bits_doNotGoToSD;
  logic io_in_2_bits_retToSrc;
  logic io_in_3_valid;
  logic [11:0] io_in_3_bits_txnID;
  logic [10:0] io_in_3_bits_fwdNID;
  logic [11:0] io_in_3_bits_fwdTxnID;
  logic [4:0] io_in_3_bits_opcode;
  logic [44:0] io_in_3_bits_addr;
  logic io_in_3_bits_doNotGoToSD;
  logic io_in_3_bits_retToSrc;
  logic io_out_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [10:0] g_io_out_bits_fwdNID;
  wire [10:0] i_io_out_bits_fwdNID;
  wire [11:0] g_io_out_bits_fwdTxnID;
  wire [11:0] i_io_out_bits_fwdTxnID;
  wire [4:0] g_io_out_bits_opcode;
  wire [4:0] i_io_out_bits_opcode;
  wire [44:0] g_io_out_bits_addr;
  wire [44:0] i_io_out_bits_addr;
  wire g_io_out_bits_doNotGoToSD;
  wire i_io_out_bits_doNotGoToSD;
  wire g_io_out_bits_retToSrc;
  wire i_io_out_bits_retToSrc;
  wire [1:0] g_io_chosen;
  wire [1:0] i_io_chosen;

  FastArbiter_44 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_fwdNID(io_in_0_bits_fwdNID),
    .io_in_0_bits_fwdTxnID(io_in_0_bits_fwdTxnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_doNotGoToSD(io_in_0_bits_doNotGoToSD),
    .io_in_0_bits_retToSrc(io_in_0_bits_retToSrc),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_fwdNID(io_in_1_bits_fwdNID),
    .io_in_1_bits_fwdTxnID(io_in_1_bits_fwdTxnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_doNotGoToSD(io_in_1_bits_doNotGoToSD),
    .io_in_1_bits_retToSrc(io_in_1_bits_retToSrc),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_fwdNID(io_in_2_bits_fwdNID),
    .io_in_2_bits_fwdTxnID(io_in_2_bits_fwdTxnID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_doNotGoToSD(io_in_2_bits_doNotGoToSD),
    .io_in_2_bits_retToSrc(io_in_2_bits_retToSrc),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_fwdNID(io_in_3_bits_fwdNID),
    .io_in_3_bits_fwdTxnID(io_in_3_bits_fwdTxnID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_doNotGoToSD(io_in_3_bits_doNotGoToSD),
    .io_in_3_bits_retToSrc(io_in_3_bits_retToSrc),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_fwdNID(g_io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID(g_io_out_bits_fwdTxnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_addr(g_io_out_bits_addr),
    .io_out_bits_doNotGoToSD(g_io_out_bits_doNotGoToSD),
    .io_out_bits_retToSrc(g_io_out_bits_retToSrc),
    .io_chosen(g_io_chosen)
  );

  FastArbiter_44_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_fwdNID(io_in_0_bits_fwdNID),
    .io_in_0_bits_fwdTxnID(io_in_0_bits_fwdTxnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_doNotGoToSD(io_in_0_bits_doNotGoToSD),
    .io_in_0_bits_retToSrc(io_in_0_bits_retToSrc),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_fwdNID(io_in_1_bits_fwdNID),
    .io_in_1_bits_fwdTxnID(io_in_1_bits_fwdTxnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_doNotGoToSD(io_in_1_bits_doNotGoToSD),
    .io_in_1_bits_retToSrc(io_in_1_bits_retToSrc),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_fwdNID(io_in_2_bits_fwdNID),
    .io_in_2_bits_fwdTxnID(io_in_2_bits_fwdTxnID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_doNotGoToSD(io_in_2_bits_doNotGoToSD),
    .io_in_2_bits_retToSrc(io_in_2_bits_retToSrc),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_fwdNID(io_in_3_bits_fwdNID),
    .io_in_3_bits_fwdTxnID(io_in_3_bits_fwdTxnID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_doNotGoToSD(io_in_3_bits_doNotGoToSD),
    .io_in_3_bits_retToSrc(io_in_3_bits_retToSrc),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_fwdNID(i_io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID(i_io_out_bits_fwdTxnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_addr(i_io_out_bits_addr),
    .io_out_bits_doNotGoToSD(i_io_out_bits_doNotGoToSD),
    .io_out_bits_retToSrc(i_io_out_bits_retToSrc),
    .io_chosen(i_io_chosen)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_txnID <= 12'({$urandom});
    io_in_0_bits_fwdNID <= 11'({$urandom});
    io_in_0_bits_fwdTxnID <= 12'({$urandom});
    io_in_0_bits_opcode <= 5'({$urandom});
    io_in_0_bits_addr <= 45'({$urandom, $urandom});
    io_in_0_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_in_0_bits_retToSrc <= $urandom_range(0, 1);
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_txnID <= 12'({$urandom});
    io_in_1_bits_fwdNID <= 11'({$urandom});
    io_in_1_bits_fwdTxnID <= 12'({$urandom});
    io_in_1_bits_opcode <= 5'({$urandom});
    io_in_1_bits_addr <= 45'({$urandom, $urandom});
    io_in_1_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_in_1_bits_retToSrc <= $urandom_range(0, 1);
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_2_bits_txnID <= 12'({$urandom});
    io_in_2_bits_fwdNID <= 11'({$urandom});
    io_in_2_bits_fwdTxnID <= 12'({$urandom});
    io_in_2_bits_opcode <= 5'({$urandom});
    io_in_2_bits_addr <= 45'({$urandom, $urandom});
    io_in_2_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_in_2_bits_retToSrc <= $urandom_range(0, 1);
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_3_bits_txnID <= 12'({$urandom});
    io_in_3_bits_fwdNID <= 11'({$urandom});
    io_in_3_bits_fwdTxnID <= 12'({$urandom});
    io_in_3_bits_opcode <= 5'({$urandom});
    io_in_3_bits_addr <= 45'({$urandom, $urandom});
    io_in_3_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_in_3_bits_retToSrc <= $urandom_range(0, 1);
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_fwdNID)
    `CHECK(io_out_bits_fwdTxnID)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_addr)
    `CHECK(io_out_bits_doNotGoToSD)
    `CHECK(io_out_bits_retToSrc)
    `CHECK(io_chosen)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_fwdNID = '0;
    io_in_0_bits_fwdTxnID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_addr = '0;
    io_in_0_bits_doNotGoToSD = '0;
    io_in_0_bits_retToSrc = '0;
    io_in_1_valid = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_fwdNID = '0;
    io_in_1_bits_fwdTxnID = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_addr = '0;
    io_in_1_bits_doNotGoToSD = '0;
    io_in_1_bits_retToSrc = '0;
    io_in_2_valid = '0;
    io_in_2_bits_txnID = '0;
    io_in_2_bits_fwdNID = '0;
    io_in_2_bits_fwdTxnID = '0;
    io_in_2_bits_opcode = '0;
    io_in_2_bits_addr = '0;
    io_in_2_bits_doNotGoToSD = '0;
    io_in_2_bits_retToSrc = '0;
    io_in_3_valid = '0;
    io_in_3_bits_txnID = '0;
    io_in_3_bits_fwdNID = '0;
    io_in_3_bits_fwdTxnID = '0;
    io_in_3_bits_opcode = '0;
    io_in_3_bits_addr = '0;
    io_in_3_bits_doNotGoToSD = '0;
    io_in_3_bits_retToSrc = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_44 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
