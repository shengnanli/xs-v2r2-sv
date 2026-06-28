// 自动生成 scripts/gen_sinka.py —— 勿手改
// SinkA 双例化逐拍比对: golden SinkA vs 可读重写 SinkA_xs (纯组合)。
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
  logic io_a_valid;
  logic [3:0] io_a_bits_opcode;
  logic [2:0] io_a_bits_param;
  logic [2:0] io_a_bits_size;
  logic [6:0] io_a_bits_source;
  logic [47:0] io_a_bits_address;
  logic [4:0] io_a_bits_user_reqSource;
  logic [1:0] io_a_bits_user_alias;
  logic [43:0] io_a_bits_user_vaddr;
  logic io_a_bits_user_needHint;
  logic io_a_bits_echo_isKeyword;
  logic io_a_bits_corrupt;
  logic io_prefetchReq_valid;
  logic [32:0] io_prefetchReq_bits_tag;
  logic [8:0] io_prefetchReq_bits_set;
  logic [43:0] io_prefetchReq_bits_vaddr;
  logic io_prefetchReq_bits_needT;
  logic [6:0] io_prefetchReq_bits_source;
  logic [4:0] io_prefetchReq_bits_pfSource;
  logic io_task_ready;
  wire g_io_a_ready;
  wire i_io_a_ready;
  wire g_io_prefetchReq_ready;
  wire i_io_prefetchReq_ready;
  wire g_io_task_valid;
  wire i_io_task_valid;
  wire [8:0] g_io_task_bits_set;
  wire [8:0] i_io_task_bits_set;
  wire [30:0] g_io_task_bits_tag;
  wire [30:0] i_io_task_bits_tag;
  wire [5:0] g_io_task_bits_off;
  wire [5:0] i_io_task_bits_off;
  wire [1:0] g_io_task_bits_alias;
  wire [1:0] i_io_task_bits_alias;
  wire [43:0] g_io_task_bits_vaddr;
  wire [43:0] i_io_task_bits_vaddr;
  wire g_io_task_bits_isKeyword;
  wire i_io_task_bits_isKeyword;
  wire [3:0] g_io_task_bits_opcode;
  wire [3:0] i_io_task_bits_opcode;
  wire [2:0] g_io_task_bits_param;
  wire [2:0] i_io_task_bits_param;
  wire [2:0] g_io_task_bits_size;
  wire [2:0] i_io_task_bits_size;
  wire [6:0] g_io_task_bits_sourceId;
  wire [6:0] i_io_task_bits_sourceId;
  wire g_io_task_bits_corrupt;
  wire i_io_task_bits_corrupt;
  wire g_io_task_bits_fromL2pft;
  wire i_io_task_bits_fromL2pft;
  wire g_io_task_bits_needHint;
  wire i_io_task_bits_needHint;
  wire [4:0] g_io_task_bits_reqSource;
  wire [4:0] i_io_task_bits_reqSource;

  SinkA u_g (
    .clock(clock),
    .reset(reset),
    .io_a_ready(g_io_a_ready),
    .io_a_valid(io_a_valid),
    .io_a_bits_opcode(io_a_bits_opcode),
    .io_a_bits_param(io_a_bits_param),
    .io_a_bits_size(io_a_bits_size),
    .io_a_bits_source(io_a_bits_source),
    .io_a_bits_address(io_a_bits_address),
    .io_a_bits_user_reqSource(io_a_bits_user_reqSource),
    .io_a_bits_user_alias(io_a_bits_user_alias),
    .io_a_bits_user_vaddr(io_a_bits_user_vaddr),
    .io_a_bits_user_needHint(io_a_bits_user_needHint),
    .io_a_bits_echo_isKeyword(io_a_bits_echo_isKeyword),
    .io_a_bits_corrupt(io_a_bits_corrupt),
    .io_prefetchReq_ready(g_io_prefetchReq_ready),
    .io_prefetchReq_valid(io_prefetchReq_valid),
    .io_prefetchReq_bits_tag(io_prefetchReq_bits_tag),
    .io_prefetchReq_bits_set(io_prefetchReq_bits_set),
    .io_prefetchReq_bits_vaddr(io_prefetchReq_bits_vaddr),
    .io_prefetchReq_bits_needT(io_prefetchReq_bits_needT),
    .io_prefetchReq_bits_source(io_prefetchReq_bits_source),
    .io_prefetchReq_bits_pfSource(io_prefetchReq_bits_pfSource),
    .io_task_ready(io_task_ready),
    .io_task_valid(g_io_task_valid),
    .io_task_bits_set(g_io_task_bits_set),
    .io_task_bits_tag(g_io_task_bits_tag),
    .io_task_bits_off(g_io_task_bits_off),
    .io_task_bits_alias(g_io_task_bits_alias),
    .io_task_bits_vaddr(g_io_task_bits_vaddr),
    .io_task_bits_isKeyword(g_io_task_bits_isKeyword),
    .io_task_bits_opcode(g_io_task_bits_opcode),
    .io_task_bits_param(g_io_task_bits_param),
    .io_task_bits_size(g_io_task_bits_size),
    .io_task_bits_sourceId(g_io_task_bits_sourceId),
    .io_task_bits_corrupt(g_io_task_bits_corrupt),
    .io_task_bits_fromL2pft(g_io_task_bits_fromL2pft),
    .io_task_bits_needHint(g_io_task_bits_needHint),
    .io_task_bits_reqSource(g_io_task_bits_reqSource)
  );
  SinkA_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_a_ready(i_io_a_ready),
    .io_a_valid(io_a_valid),
    .io_a_bits_opcode(io_a_bits_opcode),
    .io_a_bits_param(io_a_bits_param),
    .io_a_bits_size(io_a_bits_size),
    .io_a_bits_source(io_a_bits_source),
    .io_a_bits_address(io_a_bits_address),
    .io_a_bits_user_reqSource(io_a_bits_user_reqSource),
    .io_a_bits_user_alias(io_a_bits_user_alias),
    .io_a_bits_user_vaddr(io_a_bits_user_vaddr),
    .io_a_bits_user_needHint(io_a_bits_user_needHint),
    .io_a_bits_echo_isKeyword(io_a_bits_echo_isKeyword),
    .io_a_bits_corrupt(io_a_bits_corrupt),
    .io_prefetchReq_ready(i_io_prefetchReq_ready),
    .io_prefetchReq_valid(io_prefetchReq_valid),
    .io_prefetchReq_bits_tag(io_prefetchReq_bits_tag),
    .io_prefetchReq_bits_set(io_prefetchReq_bits_set),
    .io_prefetchReq_bits_vaddr(io_prefetchReq_bits_vaddr),
    .io_prefetchReq_bits_needT(io_prefetchReq_bits_needT),
    .io_prefetchReq_bits_source(io_prefetchReq_bits_source),
    .io_prefetchReq_bits_pfSource(io_prefetchReq_bits_pfSource),
    .io_task_ready(io_task_ready),
    .io_task_valid(i_io_task_valid),
    .io_task_bits_set(i_io_task_bits_set),
    .io_task_bits_tag(i_io_task_bits_tag),
    .io_task_bits_off(i_io_task_bits_off),
    .io_task_bits_alias(i_io_task_bits_alias),
    .io_task_bits_vaddr(i_io_task_bits_vaddr),
    .io_task_bits_isKeyword(i_io_task_bits_isKeyword),
    .io_task_bits_opcode(i_io_task_bits_opcode),
    .io_task_bits_param(i_io_task_bits_param),
    .io_task_bits_size(i_io_task_bits_size),
    .io_task_bits_sourceId(i_io_task_bits_sourceId),
    .io_task_bits_corrupt(i_io_task_bits_corrupt),
    .io_task_bits_fromL2pft(i_io_task_bits_fromL2pft),
    .io_task_bits_needHint(i_io_task_bits_needHint),
    .io_task_bits_reqSource(i_io_task_bits_reqSource)
  );

  task automatic drive_random();
    io_a_valid = ($urandom_range(0,1) == 0);
    io_a_bits_opcode = $urandom_range(2,7);
    io_a_bits_param = $urandom;
    io_a_bits_size = $urandom;
    io_a_bits_source = $urandom;
    io_a_bits_address = {$urandom, $urandom};
    io_a_bits_user_reqSource = $urandom;
    io_a_bits_user_alias = $urandom;
    io_a_bits_user_vaddr = {$urandom, $urandom};
    io_a_bits_user_needHint = $urandom;
    io_a_bits_echo_isKeyword = $urandom;
    io_a_bits_corrupt = $urandom;
    io_prefetchReq_valid = ($urandom_range(0,1) == 0);
    io_prefetchReq_bits_tag = {$urandom, $urandom};
    io_prefetchReq_bits_set = $urandom;
    io_prefetchReq_bits_vaddr = {$urandom, $urandom};
    io_prefetchReq_bits_needT = $urandom;
    io_prefetchReq_bits_source = $urandom;
    io_prefetchReq_bits_pfSource = $urandom_range(0,15);
    io_task_ready = ($urandom_range(0,3) != 0);
  endtask

  task automatic check_outputs();
    `CHK(io_a_ready)
    `CHK(io_prefetchReq_ready)
    `CHK(io_task_valid)
    `CHK(io_task_bits_set)
    `CHK(io_task_bits_tag)
    `CHK(io_task_bits_off)
    `CHK(io_task_bits_alias)
    `CHK(io_task_bits_vaddr)
    `CHK(io_task_bits_isKeyword)
    `CHK(io_task_bits_opcode)
    `CHK(io_task_bits_param)
    `CHK(io_task_bits_size)
    `CHK(io_task_bits_sourceId)
    `CHK(io_task_bits_corrupt)
    `CHK(io_task_bits_fromL2pft)
    `CHK(io_task_bits_needHint)
    `CHK(io_task_bits_reqSource)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_a_valid = '0;
    io_a_bits_opcode = '0;
    io_a_bits_param = '0;
    io_a_bits_size = '0;
    io_a_bits_source = '0;
    io_a_bits_address = '0;
    io_a_bits_user_reqSource = '0;
    io_a_bits_user_alias = '0;
    io_a_bits_user_vaddr = '0;
    io_a_bits_user_needHint = '0;
    io_a_bits_echo_isKeyword = '0;
    io_a_bits_corrupt = '0;
    io_prefetchReq_valid = '0;
    io_prefetchReq_bits_tag = '0;
    io_prefetchReq_bits_set = '0;
    io_prefetchReq_bits_vaddr = '0;
    io_prefetchReq_bits_needT = '0;
    io_prefetchReq_bits_source = '0;
    io_prefetchReq_bits_pfSource = '0;
    io_task_ready = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("SinkA checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
