// 自动生成: scripts/gen_queue1.py —— 勿手改
// RRArbiterInit_11 双例化逐拍比对: golden RRArbiterInit_11 vs 可读 RRArbiterInit_11_xs (随机激励).
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
  logic [6:0] io_in_0_bits_opcode;
  logic [2:0] io_in_0_bits_size;
  logic [47:0] io_in_0_bits_addr;
  logic io_in_0_bits_allowRetry;
  logic [1:0] io_in_0_bits_order;
  logic [3:0] io_in_0_bits_pCrdType;
  logic io_in_0_bits_memAttr_device;
  logic io_in_0_bits_memAttr_ewa;
  logic io_in_1_valid;
  logic [11:0] io_in_1_bits_txnID;
  logic [6:0] io_in_1_bits_opcode;
  logic [2:0] io_in_1_bits_size;
  logic [47:0] io_in_1_bits_addr;
  logic io_in_1_bits_allowRetry;
  logic [1:0] io_in_1_bits_order;
  logic [3:0] io_in_1_bits_pCrdType;
  logic io_in_1_bits_memAttr_device;
  logic io_in_1_bits_memAttr_ewa;
  logic io_in_2_valid;
  logic [11:0] io_in_2_bits_txnID;
  logic [6:0] io_in_2_bits_opcode;
  logic [2:0] io_in_2_bits_size;
  logic [47:0] io_in_2_bits_addr;
  logic io_in_2_bits_allowRetry;
  logic [1:0] io_in_2_bits_order;
  logic [3:0] io_in_2_bits_pCrdType;
  logic io_in_2_bits_memAttr_device;
  logic io_in_2_bits_memAttr_ewa;
  logic io_in_3_valid;
  logic [11:0] io_in_3_bits_txnID;
  logic [6:0] io_in_3_bits_opcode;
  logic [2:0] io_in_3_bits_size;
  logic [47:0] io_in_3_bits_addr;
  logic io_in_3_bits_allowRetry;
  logic [1:0] io_in_3_bits_order;
  logic [3:0] io_in_3_bits_pCrdType;
  logic io_in_3_bits_memAttr_device;
  logic io_in_3_bits_memAttr_ewa;
  logic io_in_4_valid;
  logic [11:0] io_in_4_bits_txnID;
  logic [6:0] io_in_4_bits_opcode;
  logic [2:0] io_in_4_bits_size;
  logic [47:0] io_in_4_bits_addr;
  logic io_in_4_bits_allowRetry;
  logic [1:0] io_in_4_bits_order;
  logic [3:0] io_in_4_bits_pCrdType;
  logic io_in_4_bits_memAttr_device;
  logic io_in_4_bits_memAttr_ewa;
  logic io_in_5_valid;
  logic [11:0] io_in_5_bits_txnID;
  logic [6:0] io_in_5_bits_opcode;
  logic [2:0] io_in_5_bits_size;
  logic [47:0] io_in_5_bits_addr;
  logic io_in_5_bits_allowRetry;
  logic [1:0] io_in_5_bits_order;
  logic [3:0] io_in_5_bits_pCrdType;
  logic io_in_5_bits_memAttr_device;
  logic io_in_5_bits_memAttr_ewa;
  logic io_in_6_valid;
  logic [11:0] io_in_6_bits_txnID;
  logic [6:0] io_in_6_bits_opcode;
  logic [2:0] io_in_6_bits_size;
  logic [47:0] io_in_6_bits_addr;
  logic io_in_6_bits_allowRetry;
  logic [1:0] io_in_6_bits_order;
  logic [3:0] io_in_6_bits_pCrdType;
  logic io_in_6_bits_memAttr_device;
  logic io_in_6_bits_memAttr_ewa;
  logic io_in_7_valid;
  logic [11:0] io_in_7_bits_txnID;
  logic [6:0] io_in_7_bits_opcode;
  logic [2:0] io_in_7_bits_size;
  logic [47:0] io_in_7_bits_addr;
  logic io_in_7_bits_allowRetry;
  logic [1:0] io_in_7_bits_order;
  logic [3:0] io_in_7_bits_pCrdType;
  logic io_in_7_bits_memAttr_device;
  logic io_in_7_bits_memAttr_ewa;
  logic io_out_ready;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_in_2_ready;
  wire i_io_in_2_ready;
  wire g_io_in_3_ready;
  wire i_io_in_3_ready;
  wire g_io_in_4_ready;
  wire i_io_in_4_ready;
  wire g_io_in_5_ready;
  wire i_io_in_5_ready;
  wire g_io_in_6_ready;
  wire i_io_in_6_ready;
  wire g_io_in_7_ready;
  wire i_io_in_7_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [6:0] g_io_out_bits_opcode;
  wire [6:0] i_io_out_bits_opcode;
  wire [2:0] g_io_out_bits_size;
  wire [2:0] i_io_out_bits_size;
  wire [47:0] g_io_out_bits_addr;
  wire [47:0] i_io_out_bits_addr;
  wire g_io_out_bits_allowRetry;
  wire i_io_out_bits_allowRetry;
  wire [1:0] g_io_out_bits_order;
  wire [1:0] i_io_out_bits_order;
  wire [3:0] g_io_out_bits_pCrdType;
  wire [3:0] i_io_out_bits_pCrdType;
  wire g_io_out_bits_memAttr_device;
  wire i_io_out_bits_memAttr_device;
  wire g_io_out_bits_memAttr_ewa;
  wire i_io_out_bits_memAttr_ewa;
  RRArbiterInit_11 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_order(io_in_0_bits_order),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_device(io_in_0_bits_memAttr_device),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_size(io_in_1_bits_size),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_allowRetry(io_in_1_bits_allowRetry),
    .io_in_1_bits_order(io_in_1_bits_order),
    .io_in_1_bits_pCrdType(io_in_1_bits_pCrdType),
    .io_in_1_bits_memAttr_device(io_in_1_bits_memAttr_device),
    .io_in_1_bits_memAttr_ewa(io_in_1_bits_memAttr_ewa),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_size(io_in_2_bits_size),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_allowRetry(io_in_2_bits_allowRetry),
    .io_in_2_bits_order(io_in_2_bits_order),
    .io_in_2_bits_pCrdType(io_in_2_bits_pCrdType),
    .io_in_2_bits_memAttr_device(io_in_2_bits_memAttr_device),
    .io_in_2_bits_memAttr_ewa(io_in_2_bits_memAttr_ewa),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_size(io_in_3_bits_size),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_allowRetry(io_in_3_bits_allowRetry),
    .io_in_3_bits_order(io_in_3_bits_order),
    .io_in_3_bits_pCrdType(io_in_3_bits_pCrdType),
    .io_in_3_bits_memAttr_device(io_in_3_bits_memAttr_device),
    .io_in_3_bits_memAttr_ewa(io_in_3_bits_memAttr_ewa),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_size(io_in_4_bits_size),
    .io_in_4_bits_addr(io_in_4_bits_addr),
    .io_in_4_bits_allowRetry(io_in_4_bits_allowRetry),
    .io_in_4_bits_order(io_in_4_bits_order),
    .io_in_4_bits_pCrdType(io_in_4_bits_pCrdType),
    .io_in_4_bits_memAttr_device(io_in_4_bits_memAttr_device),
    .io_in_4_bits_memAttr_ewa(io_in_4_bits_memAttr_ewa),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_size(io_in_5_bits_size),
    .io_in_5_bits_addr(io_in_5_bits_addr),
    .io_in_5_bits_allowRetry(io_in_5_bits_allowRetry),
    .io_in_5_bits_order(io_in_5_bits_order),
    .io_in_5_bits_pCrdType(io_in_5_bits_pCrdType),
    .io_in_5_bits_memAttr_device(io_in_5_bits_memAttr_device),
    .io_in_5_bits_memAttr_ewa(io_in_5_bits_memAttr_ewa),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_size(io_in_6_bits_size),
    .io_in_6_bits_addr(io_in_6_bits_addr),
    .io_in_6_bits_allowRetry(io_in_6_bits_allowRetry),
    .io_in_6_bits_order(io_in_6_bits_order),
    .io_in_6_bits_pCrdType(io_in_6_bits_pCrdType),
    .io_in_6_bits_memAttr_device(io_in_6_bits_memAttr_device),
    .io_in_6_bits_memAttr_ewa(io_in_6_bits_memAttr_ewa),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_size(io_in_7_bits_size),
    .io_in_7_bits_addr(io_in_7_bits_addr),
    .io_in_7_bits_allowRetry(io_in_7_bits_allowRetry),
    .io_in_7_bits_order(io_in_7_bits_order),
    .io_in_7_bits_pCrdType(io_in_7_bits_pCrdType),
    .io_in_7_bits_memAttr_device(io_in_7_bits_memAttr_device),
    .io_in_7_bits_memAttr_ewa(io_in_7_bits_memAttr_ewa),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_size(g_io_out_bits_size),
    .io_out_bits_addr(g_io_out_bits_addr),
    .io_out_bits_allowRetry(g_io_out_bits_allowRetry),
    .io_out_bits_order(g_io_out_bits_order),
    .io_out_bits_pCrdType(g_io_out_bits_pCrdType),
    .io_out_bits_memAttr_device(g_io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa(g_io_out_bits_memAttr_ewa)
  );
  RRArbiterInit_11_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_order(io_in_0_bits_order),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_device(io_in_0_bits_memAttr_device),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_size(io_in_1_bits_size),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_allowRetry(io_in_1_bits_allowRetry),
    .io_in_1_bits_order(io_in_1_bits_order),
    .io_in_1_bits_pCrdType(io_in_1_bits_pCrdType),
    .io_in_1_bits_memAttr_device(io_in_1_bits_memAttr_device),
    .io_in_1_bits_memAttr_ewa(io_in_1_bits_memAttr_ewa),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_size(io_in_2_bits_size),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_allowRetry(io_in_2_bits_allowRetry),
    .io_in_2_bits_order(io_in_2_bits_order),
    .io_in_2_bits_pCrdType(io_in_2_bits_pCrdType),
    .io_in_2_bits_memAttr_device(io_in_2_bits_memAttr_device),
    .io_in_2_bits_memAttr_ewa(io_in_2_bits_memAttr_ewa),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_size(io_in_3_bits_size),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_allowRetry(io_in_3_bits_allowRetry),
    .io_in_3_bits_order(io_in_3_bits_order),
    .io_in_3_bits_pCrdType(io_in_3_bits_pCrdType),
    .io_in_3_bits_memAttr_device(io_in_3_bits_memAttr_device),
    .io_in_3_bits_memAttr_ewa(io_in_3_bits_memAttr_ewa),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_size(io_in_4_bits_size),
    .io_in_4_bits_addr(io_in_4_bits_addr),
    .io_in_4_bits_allowRetry(io_in_4_bits_allowRetry),
    .io_in_4_bits_order(io_in_4_bits_order),
    .io_in_4_bits_pCrdType(io_in_4_bits_pCrdType),
    .io_in_4_bits_memAttr_device(io_in_4_bits_memAttr_device),
    .io_in_4_bits_memAttr_ewa(io_in_4_bits_memAttr_ewa),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_size(io_in_5_bits_size),
    .io_in_5_bits_addr(io_in_5_bits_addr),
    .io_in_5_bits_allowRetry(io_in_5_bits_allowRetry),
    .io_in_5_bits_order(io_in_5_bits_order),
    .io_in_5_bits_pCrdType(io_in_5_bits_pCrdType),
    .io_in_5_bits_memAttr_device(io_in_5_bits_memAttr_device),
    .io_in_5_bits_memAttr_ewa(io_in_5_bits_memAttr_ewa),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_size(io_in_6_bits_size),
    .io_in_6_bits_addr(io_in_6_bits_addr),
    .io_in_6_bits_allowRetry(io_in_6_bits_allowRetry),
    .io_in_6_bits_order(io_in_6_bits_order),
    .io_in_6_bits_pCrdType(io_in_6_bits_pCrdType),
    .io_in_6_bits_memAttr_device(io_in_6_bits_memAttr_device),
    .io_in_6_bits_memAttr_ewa(io_in_6_bits_memAttr_ewa),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_size(io_in_7_bits_size),
    .io_in_7_bits_addr(io_in_7_bits_addr),
    .io_in_7_bits_allowRetry(io_in_7_bits_allowRetry),
    .io_in_7_bits_order(io_in_7_bits_order),
    .io_in_7_bits_pCrdType(io_in_7_bits_pCrdType),
    .io_in_7_bits_memAttr_device(io_in_7_bits_memAttr_device),
    .io_in_7_bits_memAttr_ewa(io_in_7_bits_memAttr_ewa),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_size(i_io_out_bits_size),
    .io_out_bits_addr(i_io_out_bits_addr),
    .io_out_bits_allowRetry(i_io_out_bits_allowRetry),
    .io_out_bits_order(i_io_out_bits_order),
    .io_out_bits_pCrdType(i_io_out_bits_pCrdType),
    .io_out_bits_memAttr_device(i_io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa(i_io_out_bits_memAttr_ewa)
  );
  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_txnID <= 12'($urandom);
    io_in_0_bits_opcode <= 7'($urandom);
    io_in_0_bits_size <= 3'($urandom);
    io_in_0_bits_addr <= 48'($urandom);
    io_in_0_bits_allowRetry <= $urandom_range(0, 1);
    io_in_0_bits_order <= 2'($urandom);
    io_in_0_bits_pCrdType <= 4'($urandom);
    io_in_0_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_txnID <= 12'($urandom);
    io_in_1_bits_opcode <= 7'($urandom);
    io_in_1_bits_size <= 3'($urandom);
    io_in_1_bits_addr <= 48'($urandom);
    io_in_1_bits_allowRetry <= $urandom_range(0, 1);
    io_in_1_bits_order <= 2'($urandom);
    io_in_1_bits_pCrdType <= 4'($urandom);
    io_in_1_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_1_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_2_bits_txnID <= 12'($urandom);
    io_in_2_bits_opcode <= 7'($urandom);
    io_in_2_bits_size <= 3'($urandom);
    io_in_2_bits_addr <= 48'($urandom);
    io_in_2_bits_allowRetry <= $urandom_range(0, 1);
    io_in_2_bits_order <= 2'($urandom);
    io_in_2_bits_pCrdType <= 4'($urandom);
    io_in_2_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_2_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_3_bits_txnID <= 12'($urandom);
    io_in_3_bits_opcode <= 7'($urandom);
    io_in_3_bits_size <= 3'($urandom);
    io_in_3_bits_addr <= 48'($urandom);
    io_in_3_bits_allowRetry <= $urandom_range(0, 1);
    io_in_3_bits_order <= 2'($urandom);
    io_in_3_bits_pCrdType <= 4'($urandom);
    io_in_3_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_3_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_4_valid <= $urandom_range(0, 1);
    io_in_4_bits_txnID <= 12'($urandom);
    io_in_4_bits_opcode <= 7'($urandom);
    io_in_4_bits_size <= 3'($urandom);
    io_in_4_bits_addr <= 48'($urandom);
    io_in_4_bits_allowRetry <= $urandom_range(0, 1);
    io_in_4_bits_order <= 2'($urandom);
    io_in_4_bits_pCrdType <= 4'($urandom);
    io_in_4_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_4_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_5_valid <= $urandom_range(0, 1);
    io_in_5_bits_txnID <= 12'($urandom);
    io_in_5_bits_opcode <= 7'($urandom);
    io_in_5_bits_size <= 3'($urandom);
    io_in_5_bits_addr <= 48'($urandom);
    io_in_5_bits_allowRetry <= $urandom_range(0, 1);
    io_in_5_bits_order <= 2'($urandom);
    io_in_5_bits_pCrdType <= 4'($urandom);
    io_in_5_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_5_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_6_valid <= $urandom_range(0, 1);
    io_in_6_bits_txnID <= 12'($urandom);
    io_in_6_bits_opcode <= 7'($urandom);
    io_in_6_bits_size <= 3'($urandom);
    io_in_6_bits_addr <= 48'($urandom);
    io_in_6_bits_allowRetry <= $urandom_range(0, 1);
    io_in_6_bits_order <= 2'($urandom);
    io_in_6_bits_pCrdType <= 4'($urandom);
    io_in_6_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_6_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_7_valid <= $urandom_range(0, 1);
    io_in_7_bits_txnID <= 12'($urandom);
    io_in_7_bits_opcode <= 7'($urandom);
    io_in_7_bits_size <= 3'($urandom);
    io_in_7_bits_addr <= 48'($urandom);
    io_in_7_bits_allowRetry <= $urandom_range(0, 1);
    io_in_7_bits_order <= 2'($urandom);
    io_in_7_bits_pCrdType <= 4'($urandom);
    io_in_7_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_7_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_out_ready <= $urandom_range(0, 1);
  endtask
  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_in_4_ready)
    `CHECK(io_in_5_ready)
    `CHECK(io_in_6_ready)
    `CHECK(io_in_7_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_size)
    `CHECK(io_out_bits_addr)
    `CHECK(io_out_bits_allowRetry)
    `CHECK(io_out_bits_order)
    `CHECK(io_out_bits_pCrdType)
    `CHECK(io_out_bits_memAttr_device)
    `CHECK(io_out_bits_memAttr_ewa)
  endtask
  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_size = '0;
    io_in_0_bits_addr = '0;
    io_in_0_bits_allowRetry = '0;
    io_in_0_bits_order = '0;
    io_in_0_bits_pCrdType = '0;
    io_in_0_bits_memAttr_device = '0;
    io_in_0_bits_memAttr_ewa = '0;
    io_in_1_valid = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_size = '0;
    io_in_1_bits_addr = '0;
    io_in_1_bits_allowRetry = '0;
    io_in_1_bits_order = '0;
    io_in_1_bits_pCrdType = '0;
    io_in_1_bits_memAttr_device = '0;
    io_in_1_bits_memAttr_ewa = '0;
    io_in_2_valid = '0;
    io_in_2_bits_txnID = '0;
    io_in_2_bits_opcode = '0;
    io_in_2_bits_size = '0;
    io_in_2_bits_addr = '0;
    io_in_2_bits_allowRetry = '0;
    io_in_2_bits_order = '0;
    io_in_2_bits_pCrdType = '0;
    io_in_2_bits_memAttr_device = '0;
    io_in_2_bits_memAttr_ewa = '0;
    io_in_3_valid = '0;
    io_in_3_bits_txnID = '0;
    io_in_3_bits_opcode = '0;
    io_in_3_bits_size = '0;
    io_in_3_bits_addr = '0;
    io_in_3_bits_allowRetry = '0;
    io_in_3_bits_order = '0;
    io_in_3_bits_pCrdType = '0;
    io_in_3_bits_memAttr_device = '0;
    io_in_3_bits_memAttr_ewa = '0;
    io_in_4_valid = '0;
    io_in_4_bits_txnID = '0;
    io_in_4_bits_opcode = '0;
    io_in_4_bits_size = '0;
    io_in_4_bits_addr = '0;
    io_in_4_bits_allowRetry = '0;
    io_in_4_bits_order = '0;
    io_in_4_bits_pCrdType = '0;
    io_in_4_bits_memAttr_device = '0;
    io_in_4_bits_memAttr_ewa = '0;
    io_in_5_valid = '0;
    io_in_5_bits_txnID = '0;
    io_in_5_bits_opcode = '0;
    io_in_5_bits_size = '0;
    io_in_5_bits_addr = '0;
    io_in_5_bits_allowRetry = '0;
    io_in_5_bits_order = '0;
    io_in_5_bits_pCrdType = '0;
    io_in_5_bits_memAttr_device = '0;
    io_in_5_bits_memAttr_ewa = '0;
    io_in_6_valid = '0;
    io_in_6_bits_txnID = '0;
    io_in_6_bits_opcode = '0;
    io_in_6_bits_size = '0;
    io_in_6_bits_addr = '0;
    io_in_6_bits_allowRetry = '0;
    io_in_6_bits_order = '0;
    io_in_6_bits_pCrdType = '0;
    io_in_6_bits_memAttr_device = '0;
    io_in_6_bits_memAttr_ewa = '0;
    io_in_7_valid = '0;
    io_in_7_bits_txnID = '0;
    io_in_7_bits_opcode = '0;
    io_in_7_bits_size = '0;
    io_in_7_bits_addr = '0;
    io_in_7_bits_allowRetry = '0;
    io_in_7_bits_order = '0;
    io_in_7_bits_pCrdType = '0;
    io_in_7_bits_memAttr_device = '0;
    io_in_7_bits_memAttr_ewa = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("RRArbiterInit_11 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED"); $finish;
    end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHECK
