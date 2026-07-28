// 自动生成：scripts/gen_fastarbiter77.py —— 勿手改
// FastArbiter_78 双例化逐拍比对: golden FastArbiter_78 vs 可读 FastArbiter_78_xs。
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
  logic [10:0] io_in_0_bits_tgtID;
  logic [10:0] io_in_0_bits_srcID;
  logic [11:0] io_in_0_bits_txnID;
  logic [4:0] io_in_0_bits_opcode;
  logic [1:0] io_in_0_bits_respErr;
  logic [2:0] io_in_0_bits_resp;
  logic [2:0] io_in_0_bits_fwdState;
  logic [2:0] io_in_0_bits_cBusy;
  logic [11:0] io_in_0_bits_dbID;
  logic [3:0] io_in_0_bits_pCrdType;
  logic [1:0] io_in_0_bits_tagOp;
  logic io_in_0_bits_traceTag;
  logic io_in_1_valid;
  logic [3:0] io_in_1_bits_qos;
  logic [10:0] io_in_1_bits_tgtID;
  logic [10:0] io_in_1_bits_srcID;
  logic [11:0] io_in_1_bits_txnID;
  logic [4:0] io_in_1_bits_opcode;
  logic [1:0] io_in_1_bits_respErr;
  logic [2:0] io_in_1_bits_resp;
  logic [2:0] io_in_1_bits_fwdState;
  logic [2:0] io_in_1_bits_cBusy;
  logic [11:0] io_in_1_bits_dbID;
  logic [3:0] io_in_1_bits_pCrdType;
  logic [1:0] io_in_1_bits_tagOp;
  logic io_in_1_bits_traceTag;
  logic io_out_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_qos;
  wire [3:0] i_io_out_bits_qos;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [10:0] g_io_out_bits_srcID;
  wire [10:0] i_io_out_bits_srcID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [4:0] g_io_out_bits_opcode;
  wire [4:0] i_io_out_bits_opcode;
  wire [1:0] g_io_out_bits_respErr;
  wire [1:0] i_io_out_bits_respErr;
  wire [2:0] g_io_out_bits_resp;
  wire [2:0] i_io_out_bits_resp;
  wire [2:0] g_io_out_bits_fwdState;
  wire [2:0] i_io_out_bits_fwdState;
  wire [2:0] g_io_out_bits_cBusy;
  wire [2:0] i_io_out_bits_cBusy;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;
  wire [3:0] g_io_out_bits_pCrdType;
  wire [3:0] i_io_out_bits_pCrdType;
  wire [1:0] g_io_out_bits_tagOp;
  wire [1:0] i_io_out_bits_tagOp;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire g_io_chosen;
  wire i_io_chosen;

  FastArbiter_78 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_respErr(io_in_0_bits_respErr),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_fwdState(io_in_0_bits_fwdState),
    .io_in_0_bits_cBusy(io_in_0_bits_cBusy),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_tagOp(io_in_0_bits_tagOp),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_qos(io_in_1_bits_qos),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_srcID(io_in_1_bits_srcID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_respErr(io_in_1_bits_respErr),
    .io_in_1_bits_resp(io_in_1_bits_resp),
    .io_in_1_bits_fwdState(io_in_1_bits_fwdState),
    .io_in_1_bits_cBusy(io_in_1_bits_cBusy),
    .io_in_1_bits_dbID(io_in_1_bits_dbID),
    .io_in_1_bits_pCrdType(io_in_1_bits_pCrdType),
    .io_in_1_bits_tagOp(io_in_1_bits_tagOp),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_srcID(g_io_out_bits_srcID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_respErr(g_io_out_bits_respErr),
    .io_out_bits_resp(g_io_out_bits_resp),
    .io_out_bits_fwdState(g_io_out_bits_fwdState),
    .io_out_bits_cBusy(g_io_out_bits_cBusy),
    .io_out_bits_dbID(g_io_out_bits_dbID),
    .io_out_bits_pCrdType(g_io_out_bits_pCrdType),
    .io_out_bits_tagOp(g_io_out_bits_tagOp),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_chosen(g_io_chosen)
  );

  FastArbiter_78_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_respErr(io_in_0_bits_respErr),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_fwdState(io_in_0_bits_fwdState),
    .io_in_0_bits_cBusy(io_in_0_bits_cBusy),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_tagOp(io_in_0_bits_tagOp),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_qos(io_in_1_bits_qos),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_srcID(io_in_1_bits_srcID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_respErr(io_in_1_bits_respErr),
    .io_in_1_bits_resp(io_in_1_bits_resp),
    .io_in_1_bits_fwdState(io_in_1_bits_fwdState),
    .io_in_1_bits_cBusy(io_in_1_bits_cBusy),
    .io_in_1_bits_dbID(io_in_1_bits_dbID),
    .io_in_1_bits_pCrdType(io_in_1_bits_pCrdType),
    .io_in_1_bits_tagOp(io_in_1_bits_tagOp),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_srcID(i_io_out_bits_srcID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_respErr(i_io_out_bits_respErr),
    .io_out_bits_resp(i_io_out_bits_resp),
    .io_out_bits_fwdState(i_io_out_bits_fwdState),
    .io_out_bits_cBusy(i_io_out_bits_cBusy),
    .io_out_bits_dbID(i_io_out_bits_dbID),
    .io_out_bits_pCrdType(i_io_out_bits_pCrdType),
    .io_out_bits_tagOp(i_io_out_bits_tagOp),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_chosen(i_io_chosen)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_qos <= 4'({$urandom});
    io_in_0_bits_tgtID <= 11'({$urandom});
    io_in_0_bits_srcID <= 11'({$urandom});
    io_in_0_bits_txnID <= 12'({$urandom});
    io_in_0_bits_opcode <= 5'({$urandom});
    io_in_0_bits_respErr <= 2'({$urandom});
    io_in_0_bits_resp <= 3'({$urandom});
    io_in_0_bits_fwdState <= 3'({$urandom});
    io_in_0_bits_cBusy <= 3'({$urandom});
    io_in_0_bits_dbID <= 12'({$urandom});
    io_in_0_bits_pCrdType <= 4'({$urandom});
    io_in_0_bits_tagOp <= 2'({$urandom});
    io_in_0_bits_traceTag <= $urandom_range(0, 1);
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_qos <= 4'({$urandom});
    io_in_1_bits_tgtID <= 11'({$urandom});
    io_in_1_bits_srcID <= 11'({$urandom});
    io_in_1_bits_txnID <= 12'({$urandom});
    io_in_1_bits_opcode <= 5'({$urandom});
    io_in_1_bits_respErr <= 2'({$urandom});
    io_in_1_bits_resp <= 3'({$urandom});
    io_in_1_bits_fwdState <= 3'({$urandom});
    io_in_1_bits_cBusy <= 3'({$urandom});
    io_in_1_bits_dbID <= 12'({$urandom});
    io_in_1_bits_pCrdType <= 4'({$urandom});
    io_in_1_bits_tagOp <= 2'({$urandom});
    io_in_1_bits_traceTag <= $urandom_range(0, 1);
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_qos)
    `CHECK(io_out_bits_tgtID)
    `CHECK(io_out_bits_srcID)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_respErr)
    `CHECK(io_out_bits_resp)
    `CHECK(io_out_bits_fwdState)
    `CHECK(io_out_bits_cBusy)
    `CHECK(io_out_bits_dbID)
    `CHECK(io_out_bits_pCrdType)
    `CHECK(io_out_bits_tagOp)
    `CHECK(io_out_bits_traceTag)
    `CHECK(io_chosen)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_qos = '0;
    io_in_0_bits_tgtID = '0;
    io_in_0_bits_srcID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_respErr = '0;
    io_in_0_bits_resp = '0;
    io_in_0_bits_fwdState = '0;
    io_in_0_bits_cBusy = '0;
    io_in_0_bits_dbID = '0;
    io_in_0_bits_pCrdType = '0;
    io_in_0_bits_tagOp = '0;
    io_in_0_bits_traceTag = '0;
    io_in_1_valid = '0;
    io_in_1_bits_qos = '0;
    io_in_1_bits_tgtID = '0;
    io_in_1_bits_srcID = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_respErr = '0;
    io_in_1_bits_resp = '0;
    io_in_1_bits_fwdState = '0;
    io_in_1_bits_cBusy = '0;
    io_in_1_bits_dbID = '0;
    io_in_1_bits_pCrdType = '0;
    io_in_1_bits_tagOp = '0;
    io_in_1_bits_traceTag = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_78 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
