// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// RXDAT 双例化逐拍比对: golden RXDAT vs 可读重写 RXDAT_xs。
`timescale 1ns/1ps
`define CHK(SIG) begin \
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
  bit clock = 0; bit reset; int errors = 0; int checks = 0;
  always #5 clock = ~clock;
  logic io_out_valid;
  logic [11:0] io_out_bits_txnID;
  logic [10:0] io_out_bits_homeNID;
  logic [3:0] io_out_bits_opcode;
  logic [1:0] io_out_bits_respErr;
  logic [2:0] io_out_bits_resp;
  logic [11:0] io_out_bits_dbID;
  logic [1:0] io_out_bits_dataID;
  logic io_out_bits_traceTag;
  logic [255:0] io_out_bits_data;
  logic [31:0] io_out_bits_dataCheck;
  logic [3:0] io_out_bits_poison;
  wire g_io_in_valid;
  wire i_io_in_valid;
  wire [7:0] g_io_in_mshrId;
  wire [7:0] i_io_in_mshrId;
  wire g_io_in_respInfo_last;
  wire i_io_in_respInfo_last;
  wire g_io_in_respInfo_corrupt;
  wire i_io_in_respInfo_corrupt;
  wire [6:0] g_io_in_respInfo_chiOpcode;
  wire [6:0] i_io_in_respInfo_chiOpcode;
  wire [10:0] g_io_in_respInfo_homeNID;
  wire [10:0] i_io_in_respInfo_homeNID;
  wire [11:0] g_io_in_respInfo_dbID;
  wire [11:0] i_io_in_respInfo_dbID;
  wire [2:0] g_io_in_respInfo_resp;
  wire [2:0] i_io_in_respInfo_resp;
  wire [1:0] g_io_in_respInfo_respErr;
  wire [1:0] i_io_in_respInfo_respErr;
  wire g_io_in_respInfo_traceTag;
  wire i_io_in_respInfo_traceTag;
  wire g_io_in_respInfo_dataCheckErr;
  wire i_io_in_respInfo_dataCheckErr;
  wire g_io_refillBufWrite_valid;
  wire i_io_refillBufWrite_valid;
  wire [7:0] g_io_refillBufWrite_bits_id;
  wire [7:0] i_io_refillBufWrite_bits_id;
  wire [511:0] g_io_refillBufWrite_bits_data_data;
  wire [511:0] i_io_refillBufWrite_bits_data_data;
  wire [1:0] g_io_refillBufWrite_bits_beatMask;
  wire [1:0] i_io_refillBufWrite_bits_beatMask;

  RXDAT u_g (
    .clock(clock),
    .reset(reset),
    .io_out_valid(io_out_valid),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_homeNID(io_out_bits_homeNID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_respErr(io_out_bits_respErr),
    .io_out_bits_resp(io_out_bits_resp),
    .io_out_bits_dbID(io_out_bits_dbID),
    .io_out_bits_dataID(io_out_bits_dataID),
    .io_out_bits_traceTag(io_out_bits_traceTag),
    .io_out_bits_data(io_out_bits_data),
    .io_out_bits_dataCheck(io_out_bits_dataCheck),
    .io_out_bits_poison(io_out_bits_poison),
    .io_in_valid(g_io_in_valid),
    .io_in_mshrId(g_io_in_mshrId),
    .io_in_respInfo_last(g_io_in_respInfo_last),
    .io_in_respInfo_corrupt(g_io_in_respInfo_corrupt),
    .io_in_respInfo_chiOpcode(g_io_in_respInfo_chiOpcode),
    .io_in_respInfo_homeNID(g_io_in_respInfo_homeNID),
    .io_in_respInfo_dbID(g_io_in_respInfo_dbID),
    .io_in_respInfo_resp(g_io_in_respInfo_resp),
    .io_in_respInfo_respErr(g_io_in_respInfo_respErr),
    .io_in_respInfo_traceTag(g_io_in_respInfo_traceTag),
    .io_in_respInfo_dataCheckErr(g_io_in_respInfo_dataCheckErr),
    .io_refillBufWrite_valid(g_io_refillBufWrite_valid),
    .io_refillBufWrite_bits_id(g_io_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data(g_io_refillBufWrite_bits_data_data),
    .io_refillBufWrite_bits_beatMask(g_io_refillBufWrite_bits_beatMask)
  );
  RXDAT_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_out_valid(io_out_valid),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_homeNID(io_out_bits_homeNID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_respErr(io_out_bits_respErr),
    .io_out_bits_resp(io_out_bits_resp),
    .io_out_bits_dbID(io_out_bits_dbID),
    .io_out_bits_dataID(io_out_bits_dataID),
    .io_out_bits_traceTag(io_out_bits_traceTag),
    .io_out_bits_data(io_out_bits_data),
    .io_out_bits_dataCheck(io_out_bits_dataCheck),
    .io_out_bits_poison(io_out_bits_poison),
    .io_in_valid(i_io_in_valid),
    .io_in_mshrId(i_io_in_mshrId),
    .io_in_respInfo_last(i_io_in_respInfo_last),
    .io_in_respInfo_corrupt(i_io_in_respInfo_corrupt),
    .io_in_respInfo_chiOpcode(i_io_in_respInfo_chiOpcode),
    .io_in_respInfo_homeNID(i_io_in_respInfo_homeNID),
    .io_in_respInfo_dbID(i_io_in_respInfo_dbID),
    .io_in_respInfo_resp(i_io_in_respInfo_resp),
    .io_in_respInfo_respErr(i_io_in_respInfo_respErr),
    .io_in_respInfo_traceTag(i_io_in_respInfo_traceTag),
    .io_in_respInfo_dataCheckErr(i_io_in_respInfo_dataCheckErr),
    .io_refillBufWrite_valid(i_io_refillBufWrite_valid),
    .io_refillBufWrite_bits_id(i_io_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data(i_io_refillBufWrite_bits_data_data),
    .io_refillBufWrite_bits_beatMask(i_io_refillBufWrite_bits_beatMask)
  );

  task automatic drive_random();
    io_out_valid = ($urandom_range(0,1) == 0);
    io_out_bits_txnID = $urandom;
    io_out_bits_homeNID = $urandom;
    io_out_bits_opcode = $urandom;
    io_out_bits_respErr = $urandom;
    io_out_bits_resp = $urandom;
    io_out_bits_dbID = $urandom;
    io_out_bits_dataID = $urandom;
    io_out_bits_traceTag = $urandom;
    io_out_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_out_bits_dataCheck = $urandom;
    io_out_bits_poison = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_in_valid)
    `CHK(io_in_mshrId)
    `CHK(io_in_respInfo_last)
    `CHK(io_in_respInfo_corrupt)
    `CHK(io_in_respInfo_chiOpcode)
    `CHK(io_in_respInfo_homeNID)
    `CHK(io_in_respInfo_dbID)
    `CHK(io_in_respInfo_resp)
    `CHK(io_in_respInfo_respErr)
    `CHK(io_in_respInfo_traceTag)
    `CHK(io_in_respInfo_dataCheckErr)
    `CHK(io_refillBufWrite_valid)
    `CHK(io_refillBufWrite_bits_id)
    `CHK(io_refillBufWrite_bits_data_data)
    `CHK(io_refillBufWrite_bits_beatMask)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_out_valid = '0;
    io_out_bits_txnID = '0;
    io_out_bits_homeNID = '0;
    io_out_bits_opcode = '0;
    io_out_bits_respErr = '0;
    io_out_bits_resp = '0;
    io_out_bits_dbID = '0;
    io_out_bits_dataID = '0;
    io_out_bits_traceTag = '0;
    io_out_bits_data = '0;
    io_out_bits_dataCheck = '0;
    io_out_bits_poison = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("RXDAT checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
