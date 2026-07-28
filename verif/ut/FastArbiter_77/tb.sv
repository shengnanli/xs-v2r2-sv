// 自动生成：scripts/gen_fastarbiter77.py —— 勿手改
// FastArbiter_77 双例化逐拍比对: golden FastArbiter_77 vs 可读 FastArbiter_77_xs。
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
  logic [3:0] io_in_0_bits_qos;
  logic [10:0] io_in_0_bits_srcID;
  logic [11:0] io_in_0_bits_txnID;
  logic [10:0] io_in_0_bits_fwdNID;
  logic [11:0] io_in_0_bits_fwdTxnID;
  logic [4:0] io_in_0_bits_opcode;
  logic [44:0] io_in_0_bits_addr;
  logic io_in_0_bits_ns;
  logic io_in_0_bits_doNotGoToSD;
  logic io_in_0_bits_retToSrc;
  logic io_in_0_bits_traceTag;
  logic io_in_0_bits_mpam_perfMonGroup;
  logic [8:0] io_in_0_bits_mpam_partID;
  logic io_in_0_bits_mpam_mpamNS;
  logic io_in_1_valid;
  logic [3:0] io_in_1_bits_qos;
  logic [10:0] io_in_1_bits_srcID;
  logic [11:0] io_in_1_bits_txnID;
  logic [10:0] io_in_1_bits_fwdNID;
  logic [11:0] io_in_1_bits_fwdTxnID;
  logic [4:0] io_in_1_bits_opcode;
  logic [44:0] io_in_1_bits_addr;
  logic io_in_1_bits_ns;
  logic io_in_1_bits_doNotGoToSD;
  logic io_in_1_bits_retToSrc;
  logic io_in_1_bits_traceTag;
  logic io_in_1_bits_mpam_perfMonGroup;
  logic [8:0] io_in_1_bits_mpam_partID;
  logic io_in_1_bits_mpam_mpamNS;
  logic io_out_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_qos;
  wire [3:0] i_io_out_bits_qos;
  wire [10:0] g_io_out_bits_srcID;
  wire [10:0] i_io_out_bits_srcID;
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
  wire g_io_out_bits_ns;
  wire i_io_out_bits_ns;
  wire g_io_out_bits_doNotGoToSD;
  wire i_io_out_bits_doNotGoToSD;
  wire g_io_out_bits_retToSrc;
  wire i_io_out_bits_retToSrc;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire g_io_out_bits_mpam_perfMonGroup;
  wire i_io_out_bits_mpam_perfMonGroup;
  wire [8:0] g_io_out_bits_mpam_partID;
  wire [8:0] i_io_out_bits_mpam_partID;
  wire g_io_out_bits_mpam_mpamNS;
  wire i_io_out_bits_mpam_mpamNS;
  wire g_io_chosen;
  wire i_io_chosen;

  FastArbiter_77 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_fwdNID(io_in_0_bits_fwdNID),
    .io_in_0_bits_fwdTxnID(io_in_0_bits_fwdTxnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_ns(io_in_0_bits_ns),
    .io_in_0_bits_doNotGoToSD(io_in_0_bits_doNotGoToSD),
    .io_in_0_bits_retToSrc(io_in_0_bits_retToSrc),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_mpam_perfMonGroup(io_in_0_bits_mpam_perfMonGroup),
    .io_in_0_bits_mpam_partID(io_in_0_bits_mpam_partID),
    .io_in_0_bits_mpam_mpamNS(io_in_0_bits_mpam_mpamNS),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_qos(io_in_1_bits_qos),
    .io_in_1_bits_srcID(io_in_1_bits_srcID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_fwdNID(io_in_1_bits_fwdNID),
    .io_in_1_bits_fwdTxnID(io_in_1_bits_fwdTxnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_ns(io_in_1_bits_ns),
    .io_in_1_bits_doNotGoToSD(io_in_1_bits_doNotGoToSD),
    .io_in_1_bits_retToSrc(io_in_1_bits_retToSrc),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_in_1_bits_mpam_perfMonGroup(io_in_1_bits_mpam_perfMonGroup),
    .io_in_1_bits_mpam_partID(io_in_1_bits_mpam_partID),
    .io_in_1_bits_mpam_mpamNS(io_in_1_bits_mpam_mpamNS),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_srcID(g_io_out_bits_srcID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_fwdNID(g_io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID(g_io_out_bits_fwdTxnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_addr(g_io_out_bits_addr),
    .io_out_bits_ns(g_io_out_bits_ns),
    .io_out_bits_doNotGoToSD(g_io_out_bits_doNotGoToSD),
    .io_out_bits_retToSrc(g_io_out_bits_retToSrc),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_out_bits_mpam_perfMonGroup(g_io_out_bits_mpam_perfMonGroup),
    .io_out_bits_mpam_partID(g_io_out_bits_mpam_partID),
    .io_out_bits_mpam_mpamNS(g_io_out_bits_mpam_mpamNS),
    .io_chosen(g_io_chosen)
  );

  FastArbiter_77_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_fwdNID(io_in_0_bits_fwdNID),
    .io_in_0_bits_fwdTxnID(io_in_0_bits_fwdTxnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_ns(io_in_0_bits_ns),
    .io_in_0_bits_doNotGoToSD(io_in_0_bits_doNotGoToSD),
    .io_in_0_bits_retToSrc(io_in_0_bits_retToSrc),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_mpam_perfMonGroup(io_in_0_bits_mpam_perfMonGroup),
    .io_in_0_bits_mpam_partID(io_in_0_bits_mpam_partID),
    .io_in_0_bits_mpam_mpamNS(io_in_0_bits_mpam_mpamNS),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_qos(io_in_1_bits_qos),
    .io_in_1_bits_srcID(io_in_1_bits_srcID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_fwdNID(io_in_1_bits_fwdNID),
    .io_in_1_bits_fwdTxnID(io_in_1_bits_fwdTxnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_ns(io_in_1_bits_ns),
    .io_in_1_bits_doNotGoToSD(io_in_1_bits_doNotGoToSD),
    .io_in_1_bits_retToSrc(io_in_1_bits_retToSrc),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_in_1_bits_mpam_perfMonGroup(io_in_1_bits_mpam_perfMonGroup),
    .io_in_1_bits_mpam_partID(io_in_1_bits_mpam_partID),
    .io_in_1_bits_mpam_mpamNS(io_in_1_bits_mpam_mpamNS),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_srcID(i_io_out_bits_srcID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_fwdNID(i_io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID(i_io_out_bits_fwdTxnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_addr(i_io_out_bits_addr),
    .io_out_bits_ns(i_io_out_bits_ns),
    .io_out_bits_doNotGoToSD(i_io_out_bits_doNotGoToSD),
    .io_out_bits_retToSrc(i_io_out_bits_retToSrc),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_out_bits_mpam_perfMonGroup(i_io_out_bits_mpam_perfMonGroup),
    .io_out_bits_mpam_partID(i_io_out_bits_mpam_partID),
    .io_out_bits_mpam_mpamNS(i_io_out_bits_mpam_mpamNS),
    .io_chosen(i_io_chosen)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_qos <= 4'({$urandom});
    io_in_0_bits_srcID <= 11'({$urandom});
    io_in_0_bits_txnID <= 12'({$urandom});
    io_in_0_bits_fwdNID <= 11'({$urandom});
    io_in_0_bits_fwdTxnID <= 12'({$urandom});
    io_in_0_bits_opcode <= 5'({$urandom});
    io_in_0_bits_addr <= 45'({$urandom, $urandom});
    io_in_0_bits_ns <= $urandom_range(0, 1);
    io_in_0_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_in_0_bits_retToSrc <= $urandom_range(0, 1);
    io_in_0_bits_traceTag <= $urandom_range(0, 1);
    io_in_0_bits_mpam_perfMonGroup <= $urandom_range(0, 1);
    io_in_0_bits_mpam_partID <= 9'({$urandom});
    io_in_0_bits_mpam_mpamNS <= $urandom_range(0, 1);
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_qos <= 4'({$urandom});
    io_in_1_bits_srcID <= 11'({$urandom});
    io_in_1_bits_txnID <= 12'({$urandom});
    io_in_1_bits_fwdNID <= 11'({$urandom});
    io_in_1_bits_fwdTxnID <= 12'({$urandom});
    io_in_1_bits_opcode <= 5'({$urandom});
    io_in_1_bits_addr <= 45'({$urandom, $urandom});
    io_in_1_bits_ns <= $urandom_range(0, 1);
    io_in_1_bits_doNotGoToSD <= $urandom_range(0, 1);
    io_in_1_bits_retToSrc <= $urandom_range(0, 1);
    io_in_1_bits_traceTag <= $urandom_range(0, 1);
    io_in_1_bits_mpam_perfMonGroup <= $urandom_range(0, 1);
    io_in_1_bits_mpam_partID <= 9'({$urandom});
    io_in_1_bits_mpam_mpamNS <= $urandom_range(0, 1);
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_qos)
    `CHECK(io_out_bits_srcID)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_fwdNID)
    `CHECK(io_out_bits_fwdTxnID)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_addr)
    `CHECK(io_out_bits_ns)
    `CHECK(io_out_bits_doNotGoToSD)
    `CHECK(io_out_bits_retToSrc)
    `CHECK(io_out_bits_traceTag)
    `CHECK(io_out_bits_mpam_perfMonGroup)
    `CHECK(io_out_bits_mpam_partID)
    `CHECK(io_out_bits_mpam_mpamNS)
    `CHECK(io_chosen)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_qos = '0;
    io_in_0_bits_srcID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_fwdNID = '0;
    io_in_0_bits_fwdTxnID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_addr = '0;
    io_in_0_bits_ns = '0;
    io_in_0_bits_doNotGoToSD = '0;
    io_in_0_bits_retToSrc = '0;
    io_in_0_bits_traceTag = '0;
    io_in_0_bits_mpam_perfMonGroup = '0;
    io_in_0_bits_mpam_partID = '0;
    io_in_0_bits_mpam_mpamNS = '0;
    io_in_1_valid = '0;
    io_in_1_bits_qos = '0;
    io_in_1_bits_srcID = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_fwdNID = '0;
    io_in_1_bits_fwdTxnID = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_addr = '0;
    io_in_1_bits_ns = '0;
    io_in_1_bits_doNotGoToSD = '0;
    io_in_1_bits_retToSrc = '0;
    io_in_1_bits_traceTag = '0;
    io_in_1_bits_mpam_perfMonGroup = '0;
    io_in_1_bits_mpam_partID = '0;
    io_in_1_bits_mpam_mpamNS = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_77 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
