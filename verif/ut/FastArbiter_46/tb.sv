// 自动生成：scripts/gen_fastarbiter.py —— 勿手改
// FastArbiter_46 双例化逐拍比对: golden FastArbiter_46 vs 可读 FastArbiter_46_xs。
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
  logic [10:0] io_in_0_bits_tgtID;
  logic [10:0] io_in_0_bits_srcID;
  logic [11:0] io_in_0_bits_txnID;
  logic [10:0] io_in_0_bits_homeNID;
  logic [3:0] io_in_0_bits_opcode;
  logic [2:0] io_in_0_bits_resp;
  logic [3:0] io_in_0_bits_dataSource;
  logic [11:0] io_in_0_bits_dbID;
  logic [1:0] io_in_0_bits_dataID;
  logic [31:0] io_in_0_bits_be;
  logic [255:0] io_in_0_bits_data;
  logic [31:0] io_in_0_bits_dataCheck;
  logic io_in_1_valid;
  logic [10:0] io_in_1_bits_tgtID;
  logic [10:0] io_in_1_bits_srcID;
  logic [11:0] io_in_1_bits_txnID;
  logic [10:0] io_in_1_bits_homeNID;
  logic [3:0] io_in_1_bits_opcode;
  logic [2:0] io_in_1_bits_resp;
  logic [3:0] io_in_1_bits_dataSource;
  logic [11:0] io_in_1_bits_dbID;
  logic [1:0] io_in_1_bits_dataID;
  logic [31:0] io_in_1_bits_be;
  logic [255:0] io_in_1_bits_data;
  logic [31:0] io_in_1_bits_dataCheck;
  logic io_in_2_valid;
  logic [10:0] io_in_2_bits_tgtID;
  logic [10:0] io_in_2_bits_srcID;
  logic [11:0] io_in_2_bits_txnID;
  logic [10:0] io_in_2_bits_homeNID;
  logic [3:0] io_in_2_bits_opcode;
  logic [2:0] io_in_2_bits_resp;
  logic [3:0] io_in_2_bits_dataSource;
  logic [11:0] io_in_2_bits_dbID;
  logic [1:0] io_in_2_bits_dataID;
  logic [31:0] io_in_2_bits_be;
  logic [255:0] io_in_2_bits_data;
  logic [31:0] io_in_2_bits_dataCheck;
  logic io_in_3_valid;
  logic [10:0] io_in_3_bits_tgtID;
  logic [10:0] io_in_3_bits_srcID;
  logic [11:0] io_in_3_bits_txnID;
  logic [10:0] io_in_3_bits_homeNID;
  logic [3:0] io_in_3_bits_opcode;
  logic [2:0] io_in_3_bits_resp;
  logic [3:0] io_in_3_bits_dataSource;
  logic [11:0] io_in_3_bits_dbID;
  logic [1:0] io_in_3_bits_dataID;
  logic [31:0] io_in_3_bits_be;
  logic [255:0] io_in_3_bits_data;
  logic [31:0] io_in_3_bits_dataCheck;
  logic io_out_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [10:0] g_io_out_bits_srcID;
  wire [10:0] i_io_out_bits_srcID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [10:0] g_io_out_bits_homeNID;
  wire [10:0] i_io_out_bits_homeNID;
  wire [3:0] g_io_out_bits_opcode;
  wire [3:0] i_io_out_bits_opcode;
  wire [2:0] g_io_out_bits_resp;
  wire [2:0] i_io_out_bits_resp;
  wire [3:0] g_io_out_bits_dataSource;
  wire [3:0] i_io_out_bits_dataSource;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;
  wire [1:0] g_io_out_bits_dataID;
  wire [1:0] i_io_out_bits_dataID;
  wire [31:0] g_io_out_bits_be;
  wire [31:0] i_io_out_bits_be;
  wire [255:0] g_io_out_bits_data;
  wire [255:0] i_io_out_bits_data;
  wire [31:0] g_io_out_bits_dataCheck;
  wire [31:0] i_io_out_bits_dataCheck;
  wire [1:0] g_io_chosen;
  wire [1:0] i_io_chosen;

  FastArbiter_46 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(io_in_0_bits_homeNID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_dataSource(io_in_0_bits_dataSource),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_dataID(io_in_0_bits_dataID),
    .io_in_0_bits_be(io_in_0_bits_be),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_dataCheck(io_in_0_bits_dataCheck),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_srcID(io_in_1_bits_srcID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_homeNID(io_in_1_bits_homeNID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_resp(io_in_1_bits_resp),
    .io_in_1_bits_dataSource(io_in_1_bits_dataSource),
    .io_in_1_bits_dbID(io_in_1_bits_dbID),
    .io_in_1_bits_dataID(io_in_1_bits_dataID),
    .io_in_1_bits_be(io_in_1_bits_be),
    .io_in_1_bits_data(io_in_1_bits_data),
    .io_in_1_bits_dataCheck(io_in_1_bits_dataCheck),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_srcID(io_in_2_bits_srcID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_homeNID(io_in_2_bits_homeNID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_resp(io_in_2_bits_resp),
    .io_in_2_bits_dataSource(io_in_2_bits_dataSource),
    .io_in_2_bits_dbID(io_in_2_bits_dbID),
    .io_in_2_bits_dataID(io_in_2_bits_dataID),
    .io_in_2_bits_be(io_in_2_bits_be),
    .io_in_2_bits_data(io_in_2_bits_data),
    .io_in_2_bits_dataCheck(io_in_2_bits_dataCheck),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_srcID(io_in_3_bits_srcID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_homeNID(io_in_3_bits_homeNID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_resp(io_in_3_bits_resp),
    .io_in_3_bits_dataSource(io_in_3_bits_dataSource),
    .io_in_3_bits_dbID(io_in_3_bits_dbID),
    .io_in_3_bits_dataID(io_in_3_bits_dataID),
    .io_in_3_bits_be(io_in_3_bits_be),
    .io_in_3_bits_data(io_in_3_bits_data),
    .io_in_3_bits_dataCheck(io_in_3_bits_dataCheck),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_srcID(g_io_out_bits_srcID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_homeNID(g_io_out_bits_homeNID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_resp(g_io_out_bits_resp),
    .io_out_bits_dataSource(g_io_out_bits_dataSource),
    .io_out_bits_dbID(g_io_out_bits_dbID),
    .io_out_bits_dataID(g_io_out_bits_dataID),
    .io_out_bits_be(g_io_out_bits_be),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_dataCheck(g_io_out_bits_dataCheck),
    .io_chosen(g_io_chosen)
  );

  FastArbiter_46_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(io_in_0_bits_homeNID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_dataSource(io_in_0_bits_dataSource),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_dataID(io_in_0_bits_dataID),
    .io_in_0_bits_be(io_in_0_bits_be),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_dataCheck(io_in_0_bits_dataCheck),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_srcID(io_in_1_bits_srcID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_homeNID(io_in_1_bits_homeNID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_resp(io_in_1_bits_resp),
    .io_in_1_bits_dataSource(io_in_1_bits_dataSource),
    .io_in_1_bits_dbID(io_in_1_bits_dbID),
    .io_in_1_bits_dataID(io_in_1_bits_dataID),
    .io_in_1_bits_be(io_in_1_bits_be),
    .io_in_1_bits_data(io_in_1_bits_data),
    .io_in_1_bits_dataCheck(io_in_1_bits_dataCheck),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_srcID(io_in_2_bits_srcID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_homeNID(io_in_2_bits_homeNID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_resp(io_in_2_bits_resp),
    .io_in_2_bits_dataSource(io_in_2_bits_dataSource),
    .io_in_2_bits_dbID(io_in_2_bits_dbID),
    .io_in_2_bits_dataID(io_in_2_bits_dataID),
    .io_in_2_bits_be(io_in_2_bits_be),
    .io_in_2_bits_data(io_in_2_bits_data),
    .io_in_2_bits_dataCheck(io_in_2_bits_dataCheck),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_srcID(io_in_3_bits_srcID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_homeNID(io_in_3_bits_homeNID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_resp(io_in_3_bits_resp),
    .io_in_3_bits_dataSource(io_in_3_bits_dataSource),
    .io_in_3_bits_dbID(io_in_3_bits_dbID),
    .io_in_3_bits_dataID(io_in_3_bits_dataID),
    .io_in_3_bits_be(io_in_3_bits_be),
    .io_in_3_bits_data(io_in_3_bits_data),
    .io_in_3_bits_dataCheck(io_in_3_bits_dataCheck),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_srcID(i_io_out_bits_srcID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_homeNID(i_io_out_bits_homeNID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_resp(i_io_out_bits_resp),
    .io_out_bits_dataSource(i_io_out_bits_dataSource),
    .io_out_bits_dbID(i_io_out_bits_dbID),
    .io_out_bits_dataID(i_io_out_bits_dataID),
    .io_out_bits_be(i_io_out_bits_be),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_dataCheck(i_io_out_bits_dataCheck),
    .io_chosen(i_io_chosen)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_tgtID <= 11'({$urandom});
    io_in_0_bits_srcID <= 11'({$urandom});
    io_in_0_bits_txnID <= 12'({$urandom});
    io_in_0_bits_homeNID <= 11'({$urandom});
    io_in_0_bits_opcode <= 4'({$urandom});
    io_in_0_bits_resp <= 3'({$urandom});
    io_in_0_bits_dataSource <= 4'({$urandom});
    io_in_0_bits_dbID <= 12'({$urandom});
    io_in_0_bits_dataID <= 2'({$urandom});
    io_in_0_bits_be <= 32'({$urandom});
    io_in_0_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_0_bits_dataCheck <= 32'({$urandom});
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_tgtID <= 11'({$urandom});
    io_in_1_bits_srcID <= 11'({$urandom});
    io_in_1_bits_txnID <= 12'({$urandom});
    io_in_1_bits_homeNID <= 11'({$urandom});
    io_in_1_bits_opcode <= 4'({$urandom});
    io_in_1_bits_resp <= 3'({$urandom});
    io_in_1_bits_dataSource <= 4'({$urandom});
    io_in_1_bits_dbID <= 12'({$urandom});
    io_in_1_bits_dataID <= 2'({$urandom});
    io_in_1_bits_be <= 32'({$urandom});
    io_in_1_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_1_bits_dataCheck <= 32'({$urandom});
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_2_bits_tgtID <= 11'({$urandom});
    io_in_2_bits_srcID <= 11'({$urandom});
    io_in_2_bits_txnID <= 12'({$urandom});
    io_in_2_bits_homeNID <= 11'({$urandom});
    io_in_2_bits_opcode <= 4'({$urandom});
    io_in_2_bits_resp <= 3'({$urandom});
    io_in_2_bits_dataSource <= 4'({$urandom});
    io_in_2_bits_dbID <= 12'({$urandom});
    io_in_2_bits_dataID <= 2'({$urandom});
    io_in_2_bits_be <= 32'({$urandom});
    io_in_2_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_2_bits_dataCheck <= 32'({$urandom});
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_3_bits_tgtID <= 11'({$urandom});
    io_in_3_bits_srcID <= 11'({$urandom});
    io_in_3_bits_txnID <= 12'({$urandom});
    io_in_3_bits_homeNID <= 11'({$urandom});
    io_in_3_bits_opcode <= 4'({$urandom});
    io_in_3_bits_resp <= 3'({$urandom});
    io_in_3_bits_dataSource <= 4'({$urandom});
    io_in_3_bits_dbID <= 12'({$urandom});
    io_in_3_bits_dataID <= 2'({$urandom});
    io_in_3_bits_be <= 32'({$urandom});
    io_in_3_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_in_3_bits_dataCheck <= 32'({$urandom});
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_tgtID)
    `CHECK(io_out_bits_srcID)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_homeNID)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_resp)
    `CHECK(io_out_bits_dataSource)
    `CHECK(io_out_bits_dbID)
    `CHECK(io_out_bits_dataID)
    `CHECK(io_out_bits_be)
    `CHECK(io_out_bits_data)
    `CHECK(io_out_bits_dataCheck)
    `CHECK(io_chosen)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_tgtID = '0;
    io_in_0_bits_srcID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_homeNID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_resp = '0;
    io_in_0_bits_dataSource = '0;
    io_in_0_bits_dbID = '0;
    io_in_0_bits_dataID = '0;
    io_in_0_bits_be = '0;
    io_in_0_bits_data = '0;
    io_in_0_bits_dataCheck = '0;
    io_in_1_valid = '0;
    io_in_1_bits_tgtID = '0;
    io_in_1_bits_srcID = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_homeNID = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_resp = '0;
    io_in_1_bits_dataSource = '0;
    io_in_1_bits_dbID = '0;
    io_in_1_bits_dataID = '0;
    io_in_1_bits_be = '0;
    io_in_1_bits_data = '0;
    io_in_1_bits_dataCheck = '0;
    io_in_2_valid = '0;
    io_in_2_bits_tgtID = '0;
    io_in_2_bits_srcID = '0;
    io_in_2_bits_txnID = '0;
    io_in_2_bits_homeNID = '0;
    io_in_2_bits_opcode = '0;
    io_in_2_bits_resp = '0;
    io_in_2_bits_dataSource = '0;
    io_in_2_bits_dbID = '0;
    io_in_2_bits_dataID = '0;
    io_in_2_bits_be = '0;
    io_in_2_bits_data = '0;
    io_in_2_bits_dataCheck = '0;
    io_in_3_valid = '0;
    io_in_3_bits_tgtID = '0;
    io_in_3_bits_srcID = '0;
    io_in_3_bits_txnID = '0;
    io_in_3_bits_homeNID = '0;
    io_in_3_bits_opcode = '0;
    io_in_3_bits_resp = '0;
    io_in_3_bits_dataSource = '0;
    io_in_3_bits_dbID = '0;
    io_in_3_bits_dataID = '0;
    io_in_3_bits_be = '0;
    io_in_3_bits_data = '0;
    io_in_3_bits_dataCheck = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_46 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
