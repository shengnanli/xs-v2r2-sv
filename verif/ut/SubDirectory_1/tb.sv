// 自动生成 scripts/gen_subdirectory1.py —— 勿手改
// SubDirectory_1 双例化逐拍比对: golden vs 可读 SubDirectory_1_xs。
// 偏小 set/tag 域促命中/空路/PLRU 替换全覆盖; opcode 偏向更新触发值。
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
  logic [27:0] io_read_bits_tag;
  logic [11:0] io_read_bits_set;
  logic [6:0] io_read_bits_replacerInfo_opcode;
  logic io_read_bits_replacerInfo_refill;
  logic io_tagWReq_valid;
  logic [11:0] io_tagWReq_bits_set;
  logic [3:0] io_tagWReq_bits_way;
  logic [27:0] io_tagWReq_bits_wtag;
  logic io_metaWReq_valid;
  logic [11:0] io_metaWReq_bits_set;
  logic [15:0] io_metaWReq_bits_wayOH;
  logic io_metaWReq_bits_wmeta_valid;
  logic io_metaWReq_bits_wmeta_dirty;
  wire g_io_read_ready;
  wire i_io_read_ready;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire g_io_resp_bits_hit;
  wire i_io_resp_bits_hit;
  wire [27:0] g_io_resp_bits_tag;
  wire [27:0] i_io_resp_bits_tag;
  wire [11:0] g_io_resp_bits_set;
  wire [11:0] i_io_resp_bits_set;
  wire [3:0] g_io_resp_bits_way;
  wire [3:0] i_io_resp_bits_way;
  wire g_io_resp_bits_meta_valid;
  wire i_io_resp_bits_meta_valid;
  wire g_io_resp_bits_meta_dirty;
  wire i_io_resp_bits_meta_dirty;
  wire g_io_resp_bits_error;
  wire i_io_resp_bits_error;

  SubDirectory_1 u_g (
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
    .io_resp_bits_meta_valid(g_io_resp_bits_meta_valid),
    .io_resp_bits_meta_dirty(g_io_resp_bits_meta_dirty),
    .io_resp_bits_error(g_io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_valid(io_metaWReq_bits_wmeta_valid),
    .io_metaWReq_bits_wmeta_dirty(io_metaWReq_bits_wmeta_dirty)
  );
  SubDirectory_1_xs u_i (
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
    .io_resp_bits_meta_valid(i_io_resp_bits_meta_valid),
    .io_resp_bits_meta_dirty(i_io_resp_bits_meta_dirty),
    .io_resp_bits_error(i_io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_valid(io_metaWReq_bits_wmeta_valid),
    .io_metaWReq_bits_wmeta_dirty(io_metaWReq_bits_wmeta_dirty)
  );

  task automatic drive_random();
    io_read_valid = ($urandom_range(0,1) == 0);
    io_read_bits_tag = $urandom_range(0,7);
    io_read_bits_set = $urandom_range(0,15);
    io_read_bits_replacerInfo_opcode = ($urandom_range(0,2)==0) ? (($urandom_range(0,1)==0)?7'h7:7'h26) : $urandom_range(0,127);
    io_read_bits_replacerInfo_refill = ($urandom_range(0,2) == 0);
    io_tagWReq_valid = ($urandom_range(0,3) == 0);
    io_tagWReq_bits_set = $urandom_range(0,15);
    io_tagWReq_bits_way = $urandom_range(0,15);
    io_tagWReq_bits_wtag = $urandom_range(0,7);
    io_metaWReq_valid = ($urandom_range(0,3) == 0);
    io_metaWReq_bits_set = $urandom_range(0,15);
    io_metaWReq_bits_wayOH = (16'h1 << $urandom_range(0,15));
    io_metaWReq_bits_wmeta_valid = ($urandom_range(0,1) == 0);
    io_metaWReq_bits_wmeta_dirty = ($urandom_range(0,1) == 0);
  endtask

  task automatic check_outputs();
    `CHK(io_read_ready)
    `CHK(io_resp_valid)
    `CHK(io_resp_bits_hit)
    `CHK(io_resp_bits_tag)
    `CHK(io_resp_bits_set)
    `CHK(io_resp_bits_way)
    `CHK(io_resp_bits_meta_valid)
    `CHK(io_resp_bits_meta_dirty)
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
    `IP(req_s3_replacerInfo_opcode, req_s3_replacerInfo_opcode)
    `IP(req_s3_replacerInfo_refill, req_s3_replacerInfo_refill)
    `IP(repl_state_s3, repl_state_s3)
    `IP(metaAll_s3_0_valid, metaAll_s3[0].valid)
    `IP(metaAll_s3_0_dirty, metaAll_s3[0].dirty)
    `IP(tagAll_s3_0,        tagAll_s3[0])
    `IP(metaAll_s3_1_valid, metaAll_s3[1].valid)
    `IP(metaAll_s3_1_dirty, metaAll_s3[1].dirty)
    `IP(tagAll_s3_1,        tagAll_s3[1])
    `IP(metaAll_s3_2_valid, metaAll_s3[2].valid)
    `IP(metaAll_s3_2_dirty, metaAll_s3[2].dirty)
    `IP(tagAll_s3_2,        tagAll_s3[2])
    `IP(metaAll_s3_3_valid, metaAll_s3[3].valid)
    `IP(metaAll_s3_3_dirty, metaAll_s3[3].dirty)
    `IP(tagAll_s3_3,        tagAll_s3[3])
    `IP(metaAll_s3_4_valid, metaAll_s3[4].valid)
    `IP(metaAll_s3_4_dirty, metaAll_s3[4].dirty)
    `IP(tagAll_s3_4,        tagAll_s3[4])
    `IP(metaAll_s3_5_valid, metaAll_s3[5].valid)
    `IP(metaAll_s3_5_dirty, metaAll_s3[5].dirty)
    `IP(tagAll_s3_5,        tagAll_s3[5])
    `IP(metaAll_s3_6_valid, metaAll_s3[6].valid)
    `IP(metaAll_s3_6_dirty, metaAll_s3[6].dirty)
    `IP(tagAll_s3_6,        tagAll_s3[6])
    `IP(metaAll_s3_7_valid, metaAll_s3[7].valid)
    `IP(metaAll_s3_7_dirty, metaAll_s3[7].dirty)
    `IP(tagAll_s3_7,        tagAll_s3[7])
    `IP(metaAll_s3_8_valid, metaAll_s3[8].valid)
    `IP(metaAll_s3_8_dirty, metaAll_s3[8].dirty)
    `IP(tagAll_s3_8,        tagAll_s3[8])
    `IP(metaAll_s3_9_valid, metaAll_s3[9].valid)
    `IP(metaAll_s3_9_dirty, metaAll_s3[9].dirty)
    `IP(tagAll_s3_9,        tagAll_s3[9])
    `IP(metaAll_s3_10_valid, metaAll_s3[10].valid)
    `IP(metaAll_s3_10_dirty, metaAll_s3[10].dirty)
    `IP(tagAll_s3_10,        tagAll_s3[10])
    `IP(metaAll_s3_11_valid, metaAll_s3[11].valid)
    `IP(metaAll_s3_11_dirty, metaAll_s3[11].dirty)
    `IP(tagAll_s3_11,        tagAll_s3[11])
    `IP(metaAll_s3_12_valid, metaAll_s3[12].valid)
    `IP(metaAll_s3_12_dirty, metaAll_s3[12].dirty)
    `IP(tagAll_s3_12,        tagAll_s3[12])
    `IP(metaAll_s3_13_valid, metaAll_s3[13].valid)
    `IP(metaAll_s3_13_dirty, metaAll_s3[13].dirty)
    `IP(tagAll_s3_13,        tagAll_s3[13])
    `IP(metaAll_s3_14_valid, metaAll_s3[14].valid)
    `IP(metaAll_s3_14_dirty, metaAll_s3[14].dirty)
    `IP(tagAll_s3_14,        tagAll_s3[14])
    `IP(metaAll_s3_15_valid, metaAll_s3[15].valid)
    `IP(metaAll_s3_15_dirty, metaAll_s3[15].dirty)
    `IP(tagAll_s3_15,        tagAll_s3[15])
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
    io_metaWReq_bits_wmeta_valid = '0;
    io_metaWReq_bits_wmeta_dirty = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      check_internal();
      @(posedge clock);
    end
    $display("SubDirectory_1 checks=%0d errors=%0d ierr=%0d", checks, errors, ierr);
    if (errors == 0 && ierr == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
