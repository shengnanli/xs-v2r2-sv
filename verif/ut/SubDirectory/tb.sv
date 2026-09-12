// 自动生成 scripts/gen_subdirectory.py —— 勿手改
// SubDirectory 双例化逐拍比对: golden SubDirectory vs 可读 SubDirectory_xs。
// 偏小 set/tag 域促命中与空路/随机替换路全覆盖。
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
  logic io_read_valid;
  logic [29:0] io_read_bits_tag;
  logic [9:0] io_read_bits_set;
  logic [6:0] io_read_bits_replacerInfo_opcode;
  logic io_read_bits_replacerInfo_refill;
  logic io_tagWReq_valid;
  logic [9:0] io_tagWReq_bits_set;
  logic [3:0] io_tagWReq_bits_way;
  logic [29:0] io_tagWReq_bits_wtag;
  logic io_metaWReq_valid;
  logic [9:0] io_metaWReq_bits_set;
  logic [9:0] io_metaWReq_bits_wayOH;
  logic io_metaWReq_bits_wmeta_0_valid;
  wire g_io_read_ready;
  wire i_io_read_ready;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire g_io_resp_bits_hit;
  wire i_io_resp_bits_hit;
  wire [29:0] g_io_resp_bits_tag;
  wire [29:0] i_io_resp_bits_tag;
  wire [9:0] g_io_resp_bits_set;
  wire [9:0] i_io_resp_bits_set;
  wire [3:0] g_io_resp_bits_way;
  wire [3:0] i_io_resp_bits_way;
  wire g_io_resp_bits_meta_0_valid;
  wire i_io_resp_bits_meta_0_valid;
  wire g_io_resp_bits_error;
  wire i_io_resp_bits_error;

  SubDirectory u_g (
    .clock(clock),
    .reset(reset),
    .io_read_ready(g_io_read_ready),
    .io_read_valid(io_read_valid),
    .io_read_bits_tag(io_read_bits_tag),
    .io_read_bits_set(io_read_bits_set),
    .io_read_bits_replacerInfo_opcode(io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_refill(io_read_bits_replacerInfo_refill),
    .io_resp_valid(g_io_resp_valid),
    .io_resp_bits_hit(g_io_resp_bits_hit),
    .io_resp_bits_tag(g_io_resp_bits_tag),
    .io_resp_bits_set(g_io_resp_bits_set),
    .io_resp_bits_way(g_io_resp_bits_way),
    .io_resp_bits_meta_0_valid(g_io_resp_bits_meta_0_valid),
    .io_resp_bits_error(g_io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_0_valid(io_metaWReq_bits_wmeta_0_valid)
  );
  SubDirectory_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_read_ready(i_io_read_ready),
    .io_read_valid(io_read_valid),
    .io_read_bits_tag(io_read_bits_tag),
    .io_read_bits_set(io_read_bits_set),
    .io_read_bits_replacerInfo_opcode(io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_refill(io_read_bits_replacerInfo_refill),
    .io_resp_valid(i_io_resp_valid),
    .io_resp_bits_hit(i_io_resp_bits_hit),
    .io_resp_bits_tag(i_io_resp_bits_tag),
    .io_resp_bits_set(i_io_resp_bits_set),
    .io_resp_bits_way(i_io_resp_bits_way),
    .io_resp_bits_meta_0_valid(i_io_resp_bits_meta_0_valid),
    .io_resp_bits_error(i_io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_0_valid(io_metaWReq_bits_wmeta_0_valid)
  );

  task automatic drive_random();
    io_read_valid = ($urandom_range(0,1) == 0);
    io_read_bits_tag = $urandom_range(0,7);
    io_read_bits_set = $urandom_range(0,15);
    io_read_bits_replacerInfo_opcode = $urandom;
    io_read_bits_replacerInfo_refill = $urandom;
    io_tagWReq_valid = ($urandom_range(0,3) == 0);
    io_tagWReq_bits_set = $urandom_range(0,15);
    io_tagWReq_bits_way = $urandom_range(0,9);
    io_tagWReq_bits_wtag = $urandom_range(0,7);
    io_metaWReq_valid = ($urandom_range(0,3) == 0);
    io_metaWReq_bits_set = $urandom_range(0,15);
    io_metaWReq_bits_wayOH = (10'h1 << $urandom_range(0,9));
    io_metaWReq_bits_wmeta_0_valid = ($urandom_range(0,1) == 0);
  endtask

  task automatic check_outputs();
    `CHK(io_read_ready)
    `CHK(io_resp_valid)
    `CHK(io_resp_bits_hit)
    `CHK(io_resp_bits_tag)
    `CHK(io_resp_bits_set)
    `CHK(io_resp_bits_way)
    `CHK(io_resp_bits_meta_0_valid)
    `CHK(io_resp_bits_error)
  endtask

  int ierr = 0;
  `define IP(GP, IP) begin \
    if (!$isunknown(u_g.GP)) begin \
      if (u_g.GP !== u_i.u_core.IP) begin \
        ierr++; \
        if (ierr <= 40) $display("[%0t] IPROBE-DIFF %s g=%0h i=%0h", $time, `"GP`", u_g.GP, u_i.u_core.IP); \
      end \
    end \
  end
  task automatic check_internal();
    `IP(resetFinish, resetFinish)
    `IP(resetIdx, resetIdx)
    `IP(reqValid_s2, reqValid_s2)
    `IP(req_s2_tag, req_s2_tag)
    `IP(req_s2_set, req_s2_set)
    `IP(reqValid_s3, reqValid_s3)
    `IP(req_s3_tag, req_s3_tag)
    `IP(req_s3_set, req_s3_set)
    `IP(metaValidVec_0, metaValidVec[0])
    `IP(tagAll_s3_0,    tagAll_s3[0])
    `IP(metaValidVec_1, metaValidVec[1])
    `IP(tagAll_s3_1,    tagAll_s3[1])
    `IP(metaValidVec_2, metaValidVec[2])
    `IP(tagAll_s3_2,    tagAll_s3[2])
    `IP(metaValidVec_3, metaValidVec[3])
    `IP(tagAll_s3_3,    tagAll_s3[3])
    `IP(metaValidVec_4, metaValidVec[4])
    `IP(tagAll_s3_4,    tagAll_s3[4])
    `IP(metaValidVec_5, metaValidVec[5])
    `IP(tagAll_s3_5,    tagAll_s3[5])
    `IP(metaValidVec_6, metaValidVec[6])
    `IP(tagAll_s3_6,    tagAll_s3[6])
    `IP(metaValidVec_7, metaValidVec[7])
    `IP(tagAll_s3_7,    tagAll_s3[7])
    `IP(metaValidVec_8, metaValidVec[8])
    `IP(tagAll_s3_8,    tagAll_s3[8])
    `IP(metaValidVec_9, metaValidVec[9])
    `IP(tagAll_s3_9,    tagAll_s3[9])
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_read_valid = '0;
    io_read_bits_tag = '0;
    io_read_bits_set = '0;
    io_read_bits_replacerInfo_opcode = '0;
    io_read_bits_replacerInfo_refill = '0;
    io_tagWReq_valid = '0;
    io_tagWReq_bits_set = '0;
    io_tagWReq_bits_way = '0;
    io_tagWReq_bits_wtag = '0;
    io_metaWReq_valid = '0;
    io_metaWReq_bits_set = '0;
    io_metaWReq_bits_wayOH = '0;
    io_metaWReq_bits_wmeta_0_valid = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("SubDirectory checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
