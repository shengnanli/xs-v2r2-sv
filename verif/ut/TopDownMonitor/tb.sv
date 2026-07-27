// TopDownMonitor 双例化逐拍比对: golden TopDownMonitor vs 可读 TopDownMonitor_xs (随机激励).
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
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;
  logic io_dirResult_0_valid;
  logic io_dirResult_0_bits_hit;
  logic io_dirResult_0_bits_meta_prefetch;
  logic [2:0] io_dirResult_0_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_0_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_0_bits_replacerInfo_reqSource;
  logic io_dirResult_1_valid;
  logic io_dirResult_1_bits_hit;
  logic io_dirResult_1_bits_meta_prefetch;
  logic [2:0] io_dirResult_1_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_1_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_1_bits_replacerInfo_reqSource;
  logic io_dirResult_2_valid;
  logic io_dirResult_2_bits_hit;
  logic io_dirResult_2_bits_meta_prefetch;
  logic [2:0] io_dirResult_2_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_2_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_2_bits_replacerInfo_reqSource;
  logic io_dirResult_3_valid;
  logic io_dirResult_3_bits_hit;
  logic io_dirResult_3_bits_meta_prefetch;
  logic [2:0] io_dirResult_3_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_3_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_3_bits_replacerInfo_reqSource;
  logic io_msStatus_0_0_valid;
  logic [2:0] io_msStatus_0_0_bits_channel;
  logic [8:0] io_msStatus_0_0_bits_set;
  logic [30:0] io_msStatus_0_0_bits_reqTag;
  logic io_msStatus_0_0_bits_is_miss;
  logic io_msStatus_0_0_bits_is_prefetch;
  logic io_msStatus_0_1_valid;
  logic [2:0] io_msStatus_0_1_bits_channel;
  logic [8:0] io_msStatus_0_1_bits_set;
  logic [30:0] io_msStatus_0_1_bits_reqTag;
  logic io_msStatus_0_1_bits_is_miss;
  logic io_msStatus_0_1_bits_is_prefetch;
  logic io_msStatus_0_2_valid;
  logic [2:0] io_msStatus_0_2_bits_channel;
  logic [8:0] io_msStatus_0_2_bits_set;
  logic [30:0] io_msStatus_0_2_bits_reqTag;
  logic io_msStatus_0_2_bits_is_miss;
  logic io_msStatus_0_2_bits_is_prefetch;
  logic io_msStatus_0_3_valid;
  logic [2:0] io_msStatus_0_3_bits_channel;
  logic [8:0] io_msStatus_0_3_bits_set;
  logic [30:0] io_msStatus_0_3_bits_reqTag;
  logic io_msStatus_0_3_bits_is_miss;
  logic io_msStatus_0_3_bits_is_prefetch;
  logic io_msStatus_0_4_valid;
  logic [2:0] io_msStatus_0_4_bits_channel;
  logic [8:0] io_msStatus_0_4_bits_set;
  logic [30:0] io_msStatus_0_4_bits_reqTag;
  logic io_msStatus_0_4_bits_is_miss;
  logic io_msStatus_0_4_bits_is_prefetch;
  logic io_msStatus_0_5_valid;
  logic [2:0] io_msStatus_0_5_bits_channel;
  logic [8:0] io_msStatus_0_5_bits_set;
  logic [30:0] io_msStatus_0_5_bits_reqTag;
  logic io_msStatus_0_5_bits_is_miss;
  logic io_msStatus_0_5_bits_is_prefetch;
  logic io_msStatus_0_6_valid;
  logic [2:0] io_msStatus_0_6_bits_channel;
  logic [8:0] io_msStatus_0_6_bits_set;
  logic [30:0] io_msStatus_0_6_bits_reqTag;
  logic io_msStatus_0_6_bits_is_miss;
  logic io_msStatus_0_6_bits_is_prefetch;
  logic io_msStatus_0_7_valid;
  logic [2:0] io_msStatus_0_7_bits_channel;
  logic [8:0] io_msStatus_0_7_bits_set;
  logic [30:0] io_msStatus_0_7_bits_reqTag;
  logic io_msStatus_0_7_bits_is_miss;
  logic io_msStatus_0_7_bits_is_prefetch;
  logic io_msStatus_0_8_valid;
  logic [2:0] io_msStatus_0_8_bits_channel;
  logic [8:0] io_msStatus_0_8_bits_set;
  logic [30:0] io_msStatus_0_8_bits_reqTag;
  logic io_msStatus_0_8_bits_is_miss;
  logic io_msStatus_0_8_bits_is_prefetch;
  logic io_msStatus_0_9_valid;
  logic [2:0] io_msStatus_0_9_bits_channel;
  logic [8:0] io_msStatus_0_9_bits_set;
  logic [30:0] io_msStatus_0_9_bits_reqTag;
  logic io_msStatus_0_9_bits_is_miss;
  logic io_msStatus_0_9_bits_is_prefetch;
  logic io_msStatus_0_10_valid;
  logic [2:0] io_msStatus_0_10_bits_channel;
  logic [8:0] io_msStatus_0_10_bits_set;
  logic [30:0] io_msStatus_0_10_bits_reqTag;
  logic io_msStatus_0_10_bits_is_miss;
  logic io_msStatus_0_10_bits_is_prefetch;
  logic io_msStatus_0_11_valid;
  logic [2:0] io_msStatus_0_11_bits_channel;
  logic [8:0] io_msStatus_0_11_bits_set;
  logic [30:0] io_msStatus_0_11_bits_reqTag;
  logic io_msStatus_0_11_bits_is_miss;
  logic io_msStatus_0_11_bits_is_prefetch;
  logic io_msStatus_0_12_valid;
  logic [2:0] io_msStatus_0_12_bits_channel;
  logic [8:0] io_msStatus_0_12_bits_set;
  logic [30:0] io_msStatus_0_12_bits_reqTag;
  logic io_msStatus_0_12_bits_is_miss;
  logic io_msStatus_0_12_bits_is_prefetch;
  logic io_msStatus_0_13_valid;
  logic [2:0] io_msStatus_0_13_bits_channel;
  logic [8:0] io_msStatus_0_13_bits_set;
  logic [30:0] io_msStatus_0_13_bits_reqTag;
  logic io_msStatus_0_13_bits_is_miss;
  logic io_msStatus_0_13_bits_is_prefetch;
  logic io_msStatus_0_14_valid;
  logic [2:0] io_msStatus_0_14_bits_channel;
  logic [8:0] io_msStatus_0_14_bits_set;
  logic [30:0] io_msStatus_0_14_bits_reqTag;
  logic io_msStatus_0_14_bits_is_miss;
  logic io_msStatus_0_14_bits_is_prefetch;
  logic io_msStatus_0_15_valid;
  logic [2:0] io_msStatus_0_15_bits_channel;
  logic [8:0] io_msStatus_0_15_bits_set;
  logic [30:0] io_msStatus_0_15_bits_reqTag;
  logic io_msStatus_0_15_bits_is_miss;
  logic io_msStatus_0_15_bits_is_prefetch;
  logic io_msStatus_1_0_valid;
  logic [2:0] io_msStatus_1_0_bits_channel;
  logic [8:0] io_msStatus_1_0_bits_set;
  logic [30:0] io_msStatus_1_0_bits_reqTag;
  logic io_msStatus_1_0_bits_is_miss;
  logic io_msStatus_1_0_bits_is_prefetch;
  logic io_msStatus_1_1_valid;
  logic [2:0] io_msStatus_1_1_bits_channel;
  logic [8:0] io_msStatus_1_1_bits_set;
  logic [30:0] io_msStatus_1_1_bits_reqTag;
  logic io_msStatus_1_1_bits_is_miss;
  logic io_msStatus_1_1_bits_is_prefetch;
  logic io_msStatus_1_2_valid;
  logic [2:0] io_msStatus_1_2_bits_channel;
  logic [8:0] io_msStatus_1_2_bits_set;
  logic [30:0] io_msStatus_1_2_bits_reqTag;
  logic io_msStatus_1_2_bits_is_miss;
  logic io_msStatus_1_2_bits_is_prefetch;
  logic io_msStatus_1_3_valid;
  logic [2:0] io_msStatus_1_3_bits_channel;
  logic [8:0] io_msStatus_1_3_bits_set;
  logic [30:0] io_msStatus_1_3_bits_reqTag;
  logic io_msStatus_1_3_bits_is_miss;
  logic io_msStatus_1_3_bits_is_prefetch;
  logic io_msStatus_1_4_valid;
  logic [2:0] io_msStatus_1_4_bits_channel;
  logic [8:0] io_msStatus_1_4_bits_set;
  logic [30:0] io_msStatus_1_4_bits_reqTag;
  logic io_msStatus_1_4_bits_is_miss;
  logic io_msStatus_1_4_bits_is_prefetch;
  logic io_msStatus_1_5_valid;
  logic [2:0] io_msStatus_1_5_bits_channel;
  logic [8:0] io_msStatus_1_5_bits_set;
  logic [30:0] io_msStatus_1_5_bits_reqTag;
  logic io_msStatus_1_5_bits_is_miss;
  logic io_msStatus_1_5_bits_is_prefetch;
  logic io_msStatus_1_6_valid;
  logic [2:0] io_msStatus_1_6_bits_channel;
  logic [8:0] io_msStatus_1_6_bits_set;
  logic [30:0] io_msStatus_1_6_bits_reqTag;
  logic io_msStatus_1_6_bits_is_miss;
  logic io_msStatus_1_6_bits_is_prefetch;
  logic io_msStatus_1_7_valid;
  logic [2:0] io_msStatus_1_7_bits_channel;
  logic [8:0] io_msStatus_1_7_bits_set;
  logic [30:0] io_msStatus_1_7_bits_reqTag;
  logic io_msStatus_1_7_bits_is_miss;
  logic io_msStatus_1_7_bits_is_prefetch;
  logic io_msStatus_1_8_valid;
  logic [2:0] io_msStatus_1_8_bits_channel;
  logic [8:0] io_msStatus_1_8_bits_set;
  logic [30:0] io_msStatus_1_8_bits_reqTag;
  logic io_msStatus_1_8_bits_is_miss;
  logic io_msStatus_1_8_bits_is_prefetch;
  logic io_msStatus_1_9_valid;
  logic [2:0] io_msStatus_1_9_bits_channel;
  logic [8:0] io_msStatus_1_9_bits_set;
  logic [30:0] io_msStatus_1_9_bits_reqTag;
  logic io_msStatus_1_9_bits_is_miss;
  logic io_msStatus_1_9_bits_is_prefetch;
  logic io_msStatus_1_10_valid;
  logic [2:0] io_msStatus_1_10_bits_channel;
  logic [8:0] io_msStatus_1_10_bits_set;
  logic [30:0] io_msStatus_1_10_bits_reqTag;
  logic io_msStatus_1_10_bits_is_miss;
  logic io_msStatus_1_10_bits_is_prefetch;
  logic io_msStatus_1_11_valid;
  logic [2:0] io_msStatus_1_11_bits_channel;
  logic [8:0] io_msStatus_1_11_bits_set;
  logic [30:0] io_msStatus_1_11_bits_reqTag;
  logic io_msStatus_1_11_bits_is_miss;
  logic io_msStatus_1_11_bits_is_prefetch;
  logic io_msStatus_1_12_valid;
  logic [2:0] io_msStatus_1_12_bits_channel;
  logic [8:0] io_msStatus_1_12_bits_set;
  logic [30:0] io_msStatus_1_12_bits_reqTag;
  logic io_msStatus_1_12_bits_is_miss;
  logic io_msStatus_1_12_bits_is_prefetch;
  logic io_msStatus_1_13_valid;
  logic [2:0] io_msStatus_1_13_bits_channel;
  logic [8:0] io_msStatus_1_13_bits_set;
  logic [30:0] io_msStatus_1_13_bits_reqTag;
  logic io_msStatus_1_13_bits_is_miss;
  logic io_msStatus_1_13_bits_is_prefetch;
  logic io_msStatus_1_14_valid;
  logic [2:0] io_msStatus_1_14_bits_channel;
  logic [8:0] io_msStatus_1_14_bits_set;
  logic [30:0] io_msStatus_1_14_bits_reqTag;
  logic io_msStatus_1_14_bits_is_miss;
  logic io_msStatus_1_14_bits_is_prefetch;
  logic io_msStatus_1_15_valid;
  logic [2:0] io_msStatus_1_15_bits_channel;
  logic [8:0] io_msStatus_1_15_bits_set;
  logic [30:0] io_msStatus_1_15_bits_reqTag;
  logic io_msStatus_1_15_bits_is_miss;
  logic io_msStatus_1_15_bits_is_prefetch;
  logic io_msStatus_2_0_valid;
  logic [2:0] io_msStatus_2_0_bits_channel;
  logic [8:0] io_msStatus_2_0_bits_set;
  logic [30:0] io_msStatus_2_0_bits_reqTag;
  logic io_msStatus_2_0_bits_is_miss;
  logic io_msStatus_2_0_bits_is_prefetch;
  logic io_msStatus_2_1_valid;
  logic [2:0] io_msStatus_2_1_bits_channel;
  logic [8:0] io_msStatus_2_1_bits_set;
  logic [30:0] io_msStatus_2_1_bits_reqTag;
  logic io_msStatus_2_1_bits_is_miss;
  logic io_msStatus_2_1_bits_is_prefetch;
  logic io_msStatus_2_2_valid;
  logic [2:0] io_msStatus_2_2_bits_channel;
  logic [8:0] io_msStatus_2_2_bits_set;
  logic [30:0] io_msStatus_2_2_bits_reqTag;
  logic io_msStatus_2_2_bits_is_miss;
  logic io_msStatus_2_2_bits_is_prefetch;
  logic io_msStatus_2_3_valid;
  logic [2:0] io_msStatus_2_3_bits_channel;
  logic [8:0] io_msStatus_2_3_bits_set;
  logic [30:0] io_msStatus_2_3_bits_reqTag;
  logic io_msStatus_2_3_bits_is_miss;
  logic io_msStatus_2_3_bits_is_prefetch;
  logic io_msStatus_2_4_valid;
  logic [2:0] io_msStatus_2_4_bits_channel;
  logic [8:0] io_msStatus_2_4_bits_set;
  logic [30:0] io_msStatus_2_4_bits_reqTag;
  logic io_msStatus_2_4_bits_is_miss;
  logic io_msStatus_2_4_bits_is_prefetch;
  logic io_msStatus_2_5_valid;
  logic [2:0] io_msStatus_2_5_bits_channel;
  logic [8:0] io_msStatus_2_5_bits_set;
  logic [30:0] io_msStatus_2_5_bits_reqTag;
  logic io_msStatus_2_5_bits_is_miss;
  logic io_msStatus_2_5_bits_is_prefetch;
  logic io_msStatus_2_6_valid;
  logic [2:0] io_msStatus_2_6_bits_channel;
  logic [8:0] io_msStatus_2_6_bits_set;
  logic [30:0] io_msStatus_2_6_bits_reqTag;
  logic io_msStatus_2_6_bits_is_miss;
  logic io_msStatus_2_6_bits_is_prefetch;
  logic io_msStatus_2_7_valid;
  logic [2:0] io_msStatus_2_7_bits_channel;
  logic [8:0] io_msStatus_2_7_bits_set;
  logic [30:0] io_msStatus_2_7_bits_reqTag;
  logic io_msStatus_2_7_bits_is_miss;
  logic io_msStatus_2_7_bits_is_prefetch;
  logic io_msStatus_2_8_valid;
  logic [2:0] io_msStatus_2_8_bits_channel;
  logic [8:0] io_msStatus_2_8_bits_set;
  logic [30:0] io_msStatus_2_8_bits_reqTag;
  logic io_msStatus_2_8_bits_is_miss;
  logic io_msStatus_2_8_bits_is_prefetch;
  logic io_msStatus_2_9_valid;
  logic [2:0] io_msStatus_2_9_bits_channel;
  logic [8:0] io_msStatus_2_9_bits_set;
  logic [30:0] io_msStatus_2_9_bits_reqTag;
  logic io_msStatus_2_9_bits_is_miss;
  logic io_msStatus_2_9_bits_is_prefetch;
  logic io_msStatus_2_10_valid;
  logic [2:0] io_msStatus_2_10_bits_channel;
  logic [8:0] io_msStatus_2_10_bits_set;
  logic [30:0] io_msStatus_2_10_bits_reqTag;
  logic io_msStatus_2_10_bits_is_miss;
  logic io_msStatus_2_10_bits_is_prefetch;
  logic io_msStatus_2_11_valid;
  logic [2:0] io_msStatus_2_11_bits_channel;
  logic [8:0] io_msStatus_2_11_bits_set;
  logic [30:0] io_msStatus_2_11_bits_reqTag;
  logic io_msStatus_2_11_bits_is_miss;
  logic io_msStatus_2_11_bits_is_prefetch;
  logic io_msStatus_2_12_valid;
  logic [2:0] io_msStatus_2_12_bits_channel;
  logic [8:0] io_msStatus_2_12_bits_set;
  logic [30:0] io_msStatus_2_12_bits_reqTag;
  logic io_msStatus_2_12_bits_is_miss;
  logic io_msStatus_2_12_bits_is_prefetch;
  logic io_msStatus_2_13_valid;
  logic [2:0] io_msStatus_2_13_bits_channel;
  logic [8:0] io_msStatus_2_13_bits_set;
  logic [30:0] io_msStatus_2_13_bits_reqTag;
  logic io_msStatus_2_13_bits_is_miss;
  logic io_msStatus_2_13_bits_is_prefetch;
  logic io_msStatus_2_14_valid;
  logic [2:0] io_msStatus_2_14_bits_channel;
  logic [8:0] io_msStatus_2_14_bits_set;
  logic [30:0] io_msStatus_2_14_bits_reqTag;
  logic io_msStatus_2_14_bits_is_miss;
  logic io_msStatus_2_14_bits_is_prefetch;
  logic io_msStatus_2_15_valid;
  logic [2:0] io_msStatus_2_15_bits_channel;
  logic [8:0] io_msStatus_2_15_bits_set;
  logic [30:0] io_msStatus_2_15_bits_reqTag;
  logic io_msStatus_2_15_bits_is_miss;
  logic io_msStatus_2_15_bits_is_prefetch;
  logic io_msStatus_3_0_valid;
  logic [2:0] io_msStatus_3_0_bits_channel;
  logic [8:0] io_msStatus_3_0_bits_set;
  logic [30:0] io_msStatus_3_0_bits_reqTag;
  logic io_msStatus_3_0_bits_is_miss;
  logic io_msStatus_3_0_bits_is_prefetch;
  logic io_msStatus_3_1_valid;
  logic [2:0] io_msStatus_3_1_bits_channel;
  logic [8:0] io_msStatus_3_1_bits_set;
  logic [30:0] io_msStatus_3_1_bits_reqTag;
  logic io_msStatus_3_1_bits_is_miss;
  logic io_msStatus_3_1_bits_is_prefetch;
  logic io_msStatus_3_2_valid;
  logic [2:0] io_msStatus_3_2_bits_channel;
  logic [8:0] io_msStatus_3_2_bits_set;
  logic [30:0] io_msStatus_3_2_bits_reqTag;
  logic io_msStatus_3_2_bits_is_miss;
  logic io_msStatus_3_2_bits_is_prefetch;
  logic io_msStatus_3_3_valid;
  logic [2:0] io_msStatus_3_3_bits_channel;
  logic [8:0] io_msStatus_3_3_bits_set;
  logic [30:0] io_msStatus_3_3_bits_reqTag;
  logic io_msStatus_3_3_bits_is_miss;
  logic io_msStatus_3_3_bits_is_prefetch;
  logic io_msStatus_3_4_valid;
  logic [2:0] io_msStatus_3_4_bits_channel;
  logic [8:0] io_msStatus_3_4_bits_set;
  logic [30:0] io_msStatus_3_4_bits_reqTag;
  logic io_msStatus_3_4_bits_is_miss;
  logic io_msStatus_3_4_bits_is_prefetch;
  logic io_msStatus_3_5_valid;
  logic [2:0] io_msStatus_3_5_bits_channel;
  logic [8:0] io_msStatus_3_5_bits_set;
  logic [30:0] io_msStatus_3_5_bits_reqTag;
  logic io_msStatus_3_5_bits_is_miss;
  logic io_msStatus_3_5_bits_is_prefetch;
  logic io_msStatus_3_6_valid;
  logic [2:0] io_msStatus_3_6_bits_channel;
  logic [8:0] io_msStatus_3_6_bits_set;
  logic [30:0] io_msStatus_3_6_bits_reqTag;
  logic io_msStatus_3_6_bits_is_miss;
  logic io_msStatus_3_6_bits_is_prefetch;
  logic io_msStatus_3_7_valid;
  logic [2:0] io_msStatus_3_7_bits_channel;
  logic [8:0] io_msStatus_3_7_bits_set;
  logic [30:0] io_msStatus_3_7_bits_reqTag;
  logic io_msStatus_3_7_bits_is_miss;
  logic io_msStatus_3_7_bits_is_prefetch;
  logic io_msStatus_3_8_valid;
  logic [2:0] io_msStatus_3_8_bits_channel;
  logic [8:0] io_msStatus_3_8_bits_set;
  logic [30:0] io_msStatus_3_8_bits_reqTag;
  logic io_msStatus_3_8_bits_is_miss;
  logic io_msStatus_3_8_bits_is_prefetch;
  logic io_msStatus_3_9_valid;
  logic [2:0] io_msStatus_3_9_bits_channel;
  logic [8:0] io_msStatus_3_9_bits_set;
  logic [30:0] io_msStatus_3_9_bits_reqTag;
  logic io_msStatus_3_9_bits_is_miss;
  logic io_msStatus_3_9_bits_is_prefetch;
  logic io_msStatus_3_10_valid;
  logic [2:0] io_msStatus_3_10_bits_channel;
  logic [8:0] io_msStatus_3_10_bits_set;
  logic [30:0] io_msStatus_3_10_bits_reqTag;
  logic io_msStatus_3_10_bits_is_miss;
  logic io_msStatus_3_10_bits_is_prefetch;
  logic io_msStatus_3_11_valid;
  logic [2:0] io_msStatus_3_11_bits_channel;
  logic [8:0] io_msStatus_3_11_bits_set;
  logic [30:0] io_msStatus_3_11_bits_reqTag;
  logic io_msStatus_3_11_bits_is_miss;
  logic io_msStatus_3_11_bits_is_prefetch;
  logic io_msStatus_3_12_valid;
  logic [2:0] io_msStatus_3_12_bits_channel;
  logic [8:0] io_msStatus_3_12_bits_set;
  logic [30:0] io_msStatus_3_12_bits_reqTag;
  logic io_msStatus_3_12_bits_is_miss;
  logic io_msStatus_3_12_bits_is_prefetch;
  logic io_msStatus_3_13_valid;
  logic [2:0] io_msStatus_3_13_bits_channel;
  logic [8:0] io_msStatus_3_13_bits_set;
  logic [30:0] io_msStatus_3_13_bits_reqTag;
  logic io_msStatus_3_13_bits_is_miss;
  logic io_msStatus_3_13_bits_is_prefetch;
  logic io_msStatus_3_14_valid;
  logic [2:0] io_msStatus_3_14_bits_channel;
  logic [8:0] io_msStatus_3_14_bits_set;
  logic [30:0] io_msStatus_3_14_bits_reqTag;
  logic io_msStatus_3_14_bits_is_miss;
  logic io_msStatus_3_14_bits_is_prefetch;
  logic io_msStatus_3_15_valid;
  logic [2:0] io_msStatus_3_15_bits_channel;
  logic [8:0] io_msStatus_3_15_bits_set;
  logic [30:0] io_msStatus_3_15_bits_reqTag;
  logic io_msStatus_3_15_bits_is_miss;
  logic io_msStatus_3_15_bits_is_prefetch;
  logic io_latePF_0;
  logic io_latePF_1;
  logic io_latePF_2;
  logic io_latePF_3;
  logic io_debugTopDown_robHeadPaddr_valid;
  logic [35:0] io_debugTopDown_robHeadPaddr_bits;
  wire g_io_debugTopDown_l2MissMatch;
  wire i_io_debugTopDown_l2MissMatch;
  TopDownMonitor u_g (
    .io_dirResult_0_valid(io_dirResult_0_valid),
    .io_dirResult_0_bits_hit(io_dirResult_0_bits_hit),
    .io_dirResult_0_bits_meta_prefetch(io_dirResult_0_bits_meta_prefetch),
    .io_dirResult_0_bits_meta_prefetchSrc(io_dirResult_0_bits_meta_prefetchSrc),
    .io_dirResult_0_bits_replacerInfo_channel(io_dirResult_0_bits_replacerInfo_channel),
    .io_dirResult_0_bits_replacerInfo_reqSource(io_dirResult_0_bits_replacerInfo_reqSource),
    .io_dirResult_1_valid(io_dirResult_1_valid),
    .io_dirResult_1_bits_hit(io_dirResult_1_bits_hit),
    .io_dirResult_1_bits_meta_prefetch(io_dirResult_1_bits_meta_prefetch),
    .io_dirResult_1_bits_meta_prefetchSrc(io_dirResult_1_bits_meta_prefetchSrc),
    .io_dirResult_1_bits_replacerInfo_channel(io_dirResult_1_bits_replacerInfo_channel),
    .io_dirResult_1_bits_replacerInfo_reqSource(io_dirResult_1_bits_replacerInfo_reqSource),
    .io_dirResult_2_valid(io_dirResult_2_valid),
    .io_dirResult_2_bits_hit(io_dirResult_2_bits_hit),
    .io_dirResult_2_bits_meta_prefetch(io_dirResult_2_bits_meta_prefetch),
    .io_dirResult_2_bits_meta_prefetchSrc(io_dirResult_2_bits_meta_prefetchSrc),
    .io_dirResult_2_bits_replacerInfo_channel(io_dirResult_2_bits_replacerInfo_channel),
    .io_dirResult_2_bits_replacerInfo_reqSource(io_dirResult_2_bits_replacerInfo_reqSource),
    .io_dirResult_3_valid(io_dirResult_3_valid),
    .io_dirResult_3_bits_hit(io_dirResult_3_bits_hit),
    .io_dirResult_3_bits_meta_prefetch(io_dirResult_3_bits_meta_prefetch),
    .io_dirResult_3_bits_meta_prefetchSrc(io_dirResult_3_bits_meta_prefetchSrc),
    .io_dirResult_3_bits_replacerInfo_channel(io_dirResult_3_bits_replacerInfo_channel),
    .io_dirResult_3_bits_replacerInfo_reqSource(io_dirResult_3_bits_replacerInfo_reqSource),
    .io_msStatus_0_0_valid(io_msStatus_0_0_valid),
    .io_msStatus_0_0_bits_channel(io_msStatus_0_0_bits_channel),
    .io_msStatus_0_0_bits_set(io_msStatus_0_0_bits_set),
    .io_msStatus_0_0_bits_reqTag(io_msStatus_0_0_bits_reqTag),
    .io_msStatus_0_0_bits_is_miss(io_msStatus_0_0_bits_is_miss),
    .io_msStatus_0_0_bits_is_prefetch(io_msStatus_0_0_bits_is_prefetch),
    .io_msStatus_0_1_valid(io_msStatus_0_1_valid),
    .io_msStatus_0_1_bits_channel(io_msStatus_0_1_bits_channel),
    .io_msStatus_0_1_bits_set(io_msStatus_0_1_bits_set),
    .io_msStatus_0_1_bits_reqTag(io_msStatus_0_1_bits_reqTag),
    .io_msStatus_0_1_bits_is_miss(io_msStatus_0_1_bits_is_miss),
    .io_msStatus_0_1_bits_is_prefetch(io_msStatus_0_1_bits_is_prefetch),
    .io_msStatus_0_2_valid(io_msStatus_0_2_valid),
    .io_msStatus_0_2_bits_channel(io_msStatus_0_2_bits_channel),
    .io_msStatus_0_2_bits_set(io_msStatus_0_2_bits_set),
    .io_msStatus_0_2_bits_reqTag(io_msStatus_0_2_bits_reqTag),
    .io_msStatus_0_2_bits_is_miss(io_msStatus_0_2_bits_is_miss),
    .io_msStatus_0_2_bits_is_prefetch(io_msStatus_0_2_bits_is_prefetch),
    .io_msStatus_0_3_valid(io_msStatus_0_3_valid),
    .io_msStatus_0_3_bits_channel(io_msStatus_0_3_bits_channel),
    .io_msStatus_0_3_bits_set(io_msStatus_0_3_bits_set),
    .io_msStatus_0_3_bits_reqTag(io_msStatus_0_3_bits_reqTag),
    .io_msStatus_0_3_bits_is_miss(io_msStatus_0_3_bits_is_miss),
    .io_msStatus_0_3_bits_is_prefetch(io_msStatus_0_3_bits_is_prefetch),
    .io_msStatus_0_4_valid(io_msStatus_0_4_valid),
    .io_msStatus_0_4_bits_channel(io_msStatus_0_4_bits_channel),
    .io_msStatus_0_4_bits_set(io_msStatus_0_4_bits_set),
    .io_msStatus_0_4_bits_reqTag(io_msStatus_0_4_bits_reqTag),
    .io_msStatus_0_4_bits_is_miss(io_msStatus_0_4_bits_is_miss),
    .io_msStatus_0_4_bits_is_prefetch(io_msStatus_0_4_bits_is_prefetch),
    .io_msStatus_0_5_valid(io_msStatus_0_5_valid),
    .io_msStatus_0_5_bits_channel(io_msStatus_0_5_bits_channel),
    .io_msStatus_0_5_bits_set(io_msStatus_0_5_bits_set),
    .io_msStatus_0_5_bits_reqTag(io_msStatus_0_5_bits_reqTag),
    .io_msStatus_0_5_bits_is_miss(io_msStatus_0_5_bits_is_miss),
    .io_msStatus_0_5_bits_is_prefetch(io_msStatus_0_5_bits_is_prefetch),
    .io_msStatus_0_6_valid(io_msStatus_0_6_valid),
    .io_msStatus_0_6_bits_channel(io_msStatus_0_6_bits_channel),
    .io_msStatus_0_6_bits_set(io_msStatus_0_6_bits_set),
    .io_msStatus_0_6_bits_reqTag(io_msStatus_0_6_bits_reqTag),
    .io_msStatus_0_6_bits_is_miss(io_msStatus_0_6_bits_is_miss),
    .io_msStatus_0_6_bits_is_prefetch(io_msStatus_0_6_bits_is_prefetch),
    .io_msStatus_0_7_valid(io_msStatus_0_7_valid),
    .io_msStatus_0_7_bits_channel(io_msStatus_0_7_bits_channel),
    .io_msStatus_0_7_bits_set(io_msStatus_0_7_bits_set),
    .io_msStatus_0_7_bits_reqTag(io_msStatus_0_7_bits_reqTag),
    .io_msStatus_0_7_bits_is_miss(io_msStatus_0_7_bits_is_miss),
    .io_msStatus_0_7_bits_is_prefetch(io_msStatus_0_7_bits_is_prefetch),
    .io_msStatus_0_8_valid(io_msStatus_0_8_valid),
    .io_msStatus_0_8_bits_channel(io_msStatus_0_8_bits_channel),
    .io_msStatus_0_8_bits_set(io_msStatus_0_8_bits_set),
    .io_msStatus_0_8_bits_reqTag(io_msStatus_0_8_bits_reqTag),
    .io_msStatus_0_8_bits_is_miss(io_msStatus_0_8_bits_is_miss),
    .io_msStatus_0_8_bits_is_prefetch(io_msStatus_0_8_bits_is_prefetch),
    .io_msStatus_0_9_valid(io_msStatus_0_9_valid),
    .io_msStatus_0_9_bits_channel(io_msStatus_0_9_bits_channel),
    .io_msStatus_0_9_bits_set(io_msStatus_0_9_bits_set),
    .io_msStatus_0_9_bits_reqTag(io_msStatus_0_9_bits_reqTag),
    .io_msStatus_0_9_bits_is_miss(io_msStatus_0_9_bits_is_miss),
    .io_msStatus_0_9_bits_is_prefetch(io_msStatus_0_9_bits_is_prefetch),
    .io_msStatus_0_10_valid(io_msStatus_0_10_valid),
    .io_msStatus_0_10_bits_channel(io_msStatus_0_10_bits_channel),
    .io_msStatus_0_10_bits_set(io_msStatus_0_10_bits_set),
    .io_msStatus_0_10_bits_reqTag(io_msStatus_0_10_bits_reqTag),
    .io_msStatus_0_10_bits_is_miss(io_msStatus_0_10_bits_is_miss),
    .io_msStatus_0_10_bits_is_prefetch(io_msStatus_0_10_bits_is_prefetch),
    .io_msStatus_0_11_valid(io_msStatus_0_11_valid),
    .io_msStatus_0_11_bits_channel(io_msStatus_0_11_bits_channel),
    .io_msStatus_0_11_bits_set(io_msStatus_0_11_bits_set),
    .io_msStatus_0_11_bits_reqTag(io_msStatus_0_11_bits_reqTag),
    .io_msStatus_0_11_bits_is_miss(io_msStatus_0_11_bits_is_miss),
    .io_msStatus_0_11_bits_is_prefetch(io_msStatus_0_11_bits_is_prefetch),
    .io_msStatus_0_12_valid(io_msStatus_0_12_valid),
    .io_msStatus_0_12_bits_channel(io_msStatus_0_12_bits_channel),
    .io_msStatus_0_12_bits_set(io_msStatus_0_12_bits_set),
    .io_msStatus_0_12_bits_reqTag(io_msStatus_0_12_bits_reqTag),
    .io_msStatus_0_12_bits_is_miss(io_msStatus_0_12_bits_is_miss),
    .io_msStatus_0_12_bits_is_prefetch(io_msStatus_0_12_bits_is_prefetch),
    .io_msStatus_0_13_valid(io_msStatus_0_13_valid),
    .io_msStatus_0_13_bits_channel(io_msStatus_0_13_bits_channel),
    .io_msStatus_0_13_bits_set(io_msStatus_0_13_bits_set),
    .io_msStatus_0_13_bits_reqTag(io_msStatus_0_13_bits_reqTag),
    .io_msStatus_0_13_bits_is_miss(io_msStatus_0_13_bits_is_miss),
    .io_msStatus_0_13_bits_is_prefetch(io_msStatus_0_13_bits_is_prefetch),
    .io_msStatus_0_14_valid(io_msStatus_0_14_valid),
    .io_msStatus_0_14_bits_channel(io_msStatus_0_14_bits_channel),
    .io_msStatus_0_14_bits_set(io_msStatus_0_14_bits_set),
    .io_msStatus_0_14_bits_reqTag(io_msStatus_0_14_bits_reqTag),
    .io_msStatus_0_14_bits_is_miss(io_msStatus_0_14_bits_is_miss),
    .io_msStatus_0_14_bits_is_prefetch(io_msStatus_0_14_bits_is_prefetch),
    .io_msStatus_0_15_valid(io_msStatus_0_15_valid),
    .io_msStatus_0_15_bits_channel(io_msStatus_0_15_bits_channel),
    .io_msStatus_0_15_bits_set(io_msStatus_0_15_bits_set),
    .io_msStatus_0_15_bits_reqTag(io_msStatus_0_15_bits_reqTag),
    .io_msStatus_0_15_bits_is_miss(io_msStatus_0_15_bits_is_miss),
    .io_msStatus_0_15_bits_is_prefetch(io_msStatus_0_15_bits_is_prefetch),
    .io_msStatus_1_0_valid(io_msStatus_1_0_valid),
    .io_msStatus_1_0_bits_channel(io_msStatus_1_0_bits_channel),
    .io_msStatus_1_0_bits_set(io_msStatus_1_0_bits_set),
    .io_msStatus_1_0_bits_reqTag(io_msStatus_1_0_bits_reqTag),
    .io_msStatus_1_0_bits_is_miss(io_msStatus_1_0_bits_is_miss),
    .io_msStatus_1_0_bits_is_prefetch(io_msStatus_1_0_bits_is_prefetch),
    .io_msStatus_1_1_valid(io_msStatus_1_1_valid),
    .io_msStatus_1_1_bits_channel(io_msStatus_1_1_bits_channel),
    .io_msStatus_1_1_bits_set(io_msStatus_1_1_bits_set),
    .io_msStatus_1_1_bits_reqTag(io_msStatus_1_1_bits_reqTag),
    .io_msStatus_1_1_bits_is_miss(io_msStatus_1_1_bits_is_miss),
    .io_msStatus_1_1_bits_is_prefetch(io_msStatus_1_1_bits_is_prefetch),
    .io_msStatus_1_2_valid(io_msStatus_1_2_valid),
    .io_msStatus_1_2_bits_channel(io_msStatus_1_2_bits_channel),
    .io_msStatus_1_2_bits_set(io_msStatus_1_2_bits_set),
    .io_msStatus_1_2_bits_reqTag(io_msStatus_1_2_bits_reqTag),
    .io_msStatus_1_2_bits_is_miss(io_msStatus_1_2_bits_is_miss),
    .io_msStatus_1_2_bits_is_prefetch(io_msStatus_1_2_bits_is_prefetch),
    .io_msStatus_1_3_valid(io_msStatus_1_3_valid),
    .io_msStatus_1_3_bits_channel(io_msStatus_1_3_bits_channel),
    .io_msStatus_1_3_bits_set(io_msStatus_1_3_bits_set),
    .io_msStatus_1_3_bits_reqTag(io_msStatus_1_3_bits_reqTag),
    .io_msStatus_1_3_bits_is_miss(io_msStatus_1_3_bits_is_miss),
    .io_msStatus_1_3_bits_is_prefetch(io_msStatus_1_3_bits_is_prefetch),
    .io_msStatus_1_4_valid(io_msStatus_1_4_valid),
    .io_msStatus_1_4_bits_channel(io_msStatus_1_4_bits_channel),
    .io_msStatus_1_4_bits_set(io_msStatus_1_4_bits_set),
    .io_msStatus_1_4_bits_reqTag(io_msStatus_1_4_bits_reqTag),
    .io_msStatus_1_4_bits_is_miss(io_msStatus_1_4_bits_is_miss),
    .io_msStatus_1_4_bits_is_prefetch(io_msStatus_1_4_bits_is_prefetch),
    .io_msStatus_1_5_valid(io_msStatus_1_5_valid),
    .io_msStatus_1_5_bits_channel(io_msStatus_1_5_bits_channel),
    .io_msStatus_1_5_bits_set(io_msStatus_1_5_bits_set),
    .io_msStatus_1_5_bits_reqTag(io_msStatus_1_5_bits_reqTag),
    .io_msStatus_1_5_bits_is_miss(io_msStatus_1_5_bits_is_miss),
    .io_msStatus_1_5_bits_is_prefetch(io_msStatus_1_5_bits_is_prefetch),
    .io_msStatus_1_6_valid(io_msStatus_1_6_valid),
    .io_msStatus_1_6_bits_channel(io_msStatus_1_6_bits_channel),
    .io_msStatus_1_6_bits_set(io_msStatus_1_6_bits_set),
    .io_msStatus_1_6_bits_reqTag(io_msStatus_1_6_bits_reqTag),
    .io_msStatus_1_6_bits_is_miss(io_msStatus_1_6_bits_is_miss),
    .io_msStatus_1_6_bits_is_prefetch(io_msStatus_1_6_bits_is_prefetch),
    .io_msStatus_1_7_valid(io_msStatus_1_7_valid),
    .io_msStatus_1_7_bits_channel(io_msStatus_1_7_bits_channel),
    .io_msStatus_1_7_bits_set(io_msStatus_1_7_bits_set),
    .io_msStatus_1_7_bits_reqTag(io_msStatus_1_7_bits_reqTag),
    .io_msStatus_1_7_bits_is_miss(io_msStatus_1_7_bits_is_miss),
    .io_msStatus_1_7_bits_is_prefetch(io_msStatus_1_7_bits_is_prefetch),
    .io_msStatus_1_8_valid(io_msStatus_1_8_valid),
    .io_msStatus_1_8_bits_channel(io_msStatus_1_8_bits_channel),
    .io_msStatus_1_8_bits_set(io_msStatus_1_8_bits_set),
    .io_msStatus_1_8_bits_reqTag(io_msStatus_1_8_bits_reqTag),
    .io_msStatus_1_8_bits_is_miss(io_msStatus_1_8_bits_is_miss),
    .io_msStatus_1_8_bits_is_prefetch(io_msStatus_1_8_bits_is_prefetch),
    .io_msStatus_1_9_valid(io_msStatus_1_9_valid),
    .io_msStatus_1_9_bits_channel(io_msStatus_1_9_bits_channel),
    .io_msStatus_1_9_bits_set(io_msStatus_1_9_bits_set),
    .io_msStatus_1_9_bits_reqTag(io_msStatus_1_9_bits_reqTag),
    .io_msStatus_1_9_bits_is_miss(io_msStatus_1_9_bits_is_miss),
    .io_msStatus_1_9_bits_is_prefetch(io_msStatus_1_9_bits_is_prefetch),
    .io_msStatus_1_10_valid(io_msStatus_1_10_valid),
    .io_msStatus_1_10_bits_channel(io_msStatus_1_10_bits_channel),
    .io_msStatus_1_10_bits_set(io_msStatus_1_10_bits_set),
    .io_msStatus_1_10_bits_reqTag(io_msStatus_1_10_bits_reqTag),
    .io_msStatus_1_10_bits_is_miss(io_msStatus_1_10_bits_is_miss),
    .io_msStatus_1_10_bits_is_prefetch(io_msStatus_1_10_bits_is_prefetch),
    .io_msStatus_1_11_valid(io_msStatus_1_11_valid),
    .io_msStatus_1_11_bits_channel(io_msStatus_1_11_bits_channel),
    .io_msStatus_1_11_bits_set(io_msStatus_1_11_bits_set),
    .io_msStatus_1_11_bits_reqTag(io_msStatus_1_11_bits_reqTag),
    .io_msStatus_1_11_bits_is_miss(io_msStatus_1_11_bits_is_miss),
    .io_msStatus_1_11_bits_is_prefetch(io_msStatus_1_11_bits_is_prefetch),
    .io_msStatus_1_12_valid(io_msStatus_1_12_valid),
    .io_msStatus_1_12_bits_channel(io_msStatus_1_12_bits_channel),
    .io_msStatus_1_12_bits_set(io_msStatus_1_12_bits_set),
    .io_msStatus_1_12_bits_reqTag(io_msStatus_1_12_bits_reqTag),
    .io_msStatus_1_12_bits_is_miss(io_msStatus_1_12_bits_is_miss),
    .io_msStatus_1_12_bits_is_prefetch(io_msStatus_1_12_bits_is_prefetch),
    .io_msStatus_1_13_valid(io_msStatus_1_13_valid),
    .io_msStatus_1_13_bits_channel(io_msStatus_1_13_bits_channel),
    .io_msStatus_1_13_bits_set(io_msStatus_1_13_bits_set),
    .io_msStatus_1_13_bits_reqTag(io_msStatus_1_13_bits_reqTag),
    .io_msStatus_1_13_bits_is_miss(io_msStatus_1_13_bits_is_miss),
    .io_msStatus_1_13_bits_is_prefetch(io_msStatus_1_13_bits_is_prefetch),
    .io_msStatus_1_14_valid(io_msStatus_1_14_valid),
    .io_msStatus_1_14_bits_channel(io_msStatus_1_14_bits_channel),
    .io_msStatus_1_14_bits_set(io_msStatus_1_14_bits_set),
    .io_msStatus_1_14_bits_reqTag(io_msStatus_1_14_bits_reqTag),
    .io_msStatus_1_14_bits_is_miss(io_msStatus_1_14_bits_is_miss),
    .io_msStatus_1_14_bits_is_prefetch(io_msStatus_1_14_bits_is_prefetch),
    .io_msStatus_1_15_valid(io_msStatus_1_15_valid),
    .io_msStatus_1_15_bits_channel(io_msStatus_1_15_bits_channel),
    .io_msStatus_1_15_bits_set(io_msStatus_1_15_bits_set),
    .io_msStatus_1_15_bits_reqTag(io_msStatus_1_15_bits_reqTag),
    .io_msStatus_1_15_bits_is_miss(io_msStatus_1_15_bits_is_miss),
    .io_msStatus_1_15_bits_is_prefetch(io_msStatus_1_15_bits_is_prefetch),
    .io_msStatus_2_0_valid(io_msStatus_2_0_valid),
    .io_msStatus_2_0_bits_channel(io_msStatus_2_0_bits_channel),
    .io_msStatus_2_0_bits_set(io_msStatus_2_0_bits_set),
    .io_msStatus_2_0_bits_reqTag(io_msStatus_2_0_bits_reqTag),
    .io_msStatus_2_0_bits_is_miss(io_msStatus_2_0_bits_is_miss),
    .io_msStatus_2_0_bits_is_prefetch(io_msStatus_2_0_bits_is_prefetch),
    .io_msStatus_2_1_valid(io_msStatus_2_1_valid),
    .io_msStatus_2_1_bits_channel(io_msStatus_2_1_bits_channel),
    .io_msStatus_2_1_bits_set(io_msStatus_2_1_bits_set),
    .io_msStatus_2_1_bits_reqTag(io_msStatus_2_1_bits_reqTag),
    .io_msStatus_2_1_bits_is_miss(io_msStatus_2_1_bits_is_miss),
    .io_msStatus_2_1_bits_is_prefetch(io_msStatus_2_1_bits_is_prefetch),
    .io_msStatus_2_2_valid(io_msStatus_2_2_valid),
    .io_msStatus_2_2_bits_channel(io_msStatus_2_2_bits_channel),
    .io_msStatus_2_2_bits_set(io_msStatus_2_2_bits_set),
    .io_msStatus_2_2_bits_reqTag(io_msStatus_2_2_bits_reqTag),
    .io_msStatus_2_2_bits_is_miss(io_msStatus_2_2_bits_is_miss),
    .io_msStatus_2_2_bits_is_prefetch(io_msStatus_2_2_bits_is_prefetch),
    .io_msStatus_2_3_valid(io_msStatus_2_3_valid),
    .io_msStatus_2_3_bits_channel(io_msStatus_2_3_bits_channel),
    .io_msStatus_2_3_bits_set(io_msStatus_2_3_bits_set),
    .io_msStatus_2_3_bits_reqTag(io_msStatus_2_3_bits_reqTag),
    .io_msStatus_2_3_bits_is_miss(io_msStatus_2_3_bits_is_miss),
    .io_msStatus_2_3_bits_is_prefetch(io_msStatus_2_3_bits_is_prefetch),
    .io_msStatus_2_4_valid(io_msStatus_2_4_valid),
    .io_msStatus_2_4_bits_channel(io_msStatus_2_4_bits_channel),
    .io_msStatus_2_4_bits_set(io_msStatus_2_4_bits_set),
    .io_msStatus_2_4_bits_reqTag(io_msStatus_2_4_bits_reqTag),
    .io_msStatus_2_4_bits_is_miss(io_msStatus_2_4_bits_is_miss),
    .io_msStatus_2_4_bits_is_prefetch(io_msStatus_2_4_bits_is_prefetch),
    .io_msStatus_2_5_valid(io_msStatus_2_5_valid),
    .io_msStatus_2_5_bits_channel(io_msStatus_2_5_bits_channel),
    .io_msStatus_2_5_bits_set(io_msStatus_2_5_bits_set),
    .io_msStatus_2_5_bits_reqTag(io_msStatus_2_5_bits_reqTag),
    .io_msStatus_2_5_bits_is_miss(io_msStatus_2_5_bits_is_miss),
    .io_msStatus_2_5_bits_is_prefetch(io_msStatus_2_5_bits_is_prefetch),
    .io_msStatus_2_6_valid(io_msStatus_2_6_valid),
    .io_msStatus_2_6_bits_channel(io_msStatus_2_6_bits_channel),
    .io_msStatus_2_6_bits_set(io_msStatus_2_6_bits_set),
    .io_msStatus_2_6_bits_reqTag(io_msStatus_2_6_bits_reqTag),
    .io_msStatus_2_6_bits_is_miss(io_msStatus_2_6_bits_is_miss),
    .io_msStatus_2_6_bits_is_prefetch(io_msStatus_2_6_bits_is_prefetch),
    .io_msStatus_2_7_valid(io_msStatus_2_7_valid),
    .io_msStatus_2_7_bits_channel(io_msStatus_2_7_bits_channel),
    .io_msStatus_2_7_bits_set(io_msStatus_2_7_bits_set),
    .io_msStatus_2_7_bits_reqTag(io_msStatus_2_7_bits_reqTag),
    .io_msStatus_2_7_bits_is_miss(io_msStatus_2_7_bits_is_miss),
    .io_msStatus_2_7_bits_is_prefetch(io_msStatus_2_7_bits_is_prefetch),
    .io_msStatus_2_8_valid(io_msStatus_2_8_valid),
    .io_msStatus_2_8_bits_channel(io_msStatus_2_8_bits_channel),
    .io_msStatus_2_8_bits_set(io_msStatus_2_8_bits_set),
    .io_msStatus_2_8_bits_reqTag(io_msStatus_2_8_bits_reqTag),
    .io_msStatus_2_8_bits_is_miss(io_msStatus_2_8_bits_is_miss),
    .io_msStatus_2_8_bits_is_prefetch(io_msStatus_2_8_bits_is_prefetch),
    .io_msStatus_2_9_valid(io_msStatus_2_9_valid),
    .io_msStatus_2_9_bits_channel(io_msStatus_2_9_bits_channel),
    .io_msStatus_2_9_bits_set(io_msStatus_2_9_bits_set),
    .io_msStatus_2_9_bits_reqTag(io_msStatus_2_9_bits_reqTag),
    .io_msStatus_2_9_bits_is_miss(io_msStatus_2_9_bits_is_miss),
    .io_msStatus_2_9_bits_is_prefetch(io_msStatus_2_9_bits_is_prefetch),
    .io_msStatus_2_10_valid(io_msStatus_2_10_valid),
    .io_msStatus_2_10_bits_channel(io_msStatus_2_10_bits_channel),
    .io_msStatus_2_10_bits_set(io_msStatus_2_10_bits_set),
    .io_msStatus_2_10_bits_reqTag(io_msStatus_2_10_bits_reqTag),
    .io_msStatus_2_10_bits_is_miss(io_msStatus_2_10_bits_is_miss),
    .io_msStatus_2_10_bits_is_prefetch(io_msStatus_2_10_bits_is_prefetch),
    .io_msStatus_2_11_valid(io_msStatus_2_11_valid),
    .io_msStatus_2_11_bits_channel(io_msStatus_2_11_bits_channel),
    .io_msStatus_2_11_bits_set(io_msStatus_2_11_bits_set),
    .io_msStatus_2_11_bits_reqTag(io_msStatus_2_11_bits_reqTag),
    .io_msStatus_2_11_bits_is_miss(io_msStatus_2_11_bits_is_miss),
    .io_msStatus_2_11_bits_is_prefetch(io_msStatus_2_11_bits_is_prefetch),
    .io_msStatus_2_12_valid(io_msStatus_2_12_valid),
    .io_msStatus_2_12_bits_channel(io_msStatus_2_12_bits_channel),
    .io_msStatus_2_12_bits_set(io_msStatus_2_12_bits_set),
    .io_msStatus_2_12_bits_reqTag(io_msStatus_2_12_bits_reqTag),
    .io_msStatus_2_12_bits_is_miss(io_msStatus_2_12_bits_is_miss),
    .io_msStatus_2_12_bits_is_prefetch(io_msStatus_2_12_bits_is_prefetch),
    .io_msStatus_2_13_valid(io_msStatus_2_13_valid),
    .io_msStatus_2_13_bits_channel(io_msStatus_2_13_bits_channel),
    .io_msStatus_2_13_bits_set(io_msStatus_2_13_bits_set),
    .io_msStatus_2_13_bits_reqTag(io_msStatus_2_13_bits_reqTag),
    .io_msStatus_2_13_bits_is_miss(io_msStatus_2_13_bits_is_miss),
    .io_msStatus_2_13_bits_is_prefetch(io_msStatus_2_13_bits_is_prefetch),
    .io_msStatus_2_14_valid(io_msStatus_2_14_valid),
    .io_msStatus_2_14_bits_channel(io_msStatus_2_14_bits_channel),
    .io_msStatus_2_14_bits_set(io_msStatus_2_14_bits_set),
    .io_msStatus_2_14_bits_reqTag(io_msStatus_2_14_bits_reqTag),
    .io_msStatus_2_14_bits_is_miss(io_msStatus_2_14_bits_is_miss),
    .io_msStatus_2_14_bits_is_prefetch(io_msStatus_2_14_bits_is_prefetch),
    .io_msStatus_2_15_valid(io_msStatus_2_15_valid),
    .io_msStatus_2_15_bits_channel(io_msStatus_2_15_bits_channel),
    .io_msStatus_2_15_bits_set(io_msStatus_2_15_bits_set),
    .io_msStatus_2_15_bits_reqTag(io_msStatus_2_15_bits_reqTag),
    .io_msStatus_2_15_bits_is_miss(io_msStatus_2_15_bits_is_miss),
    .io_msStatus_2_15_bits_is_prefetch(io_msStatus_2_15_bits_is_prefetch),
    .io_msStatus_3_0_valid(io_msStatus_3_0_valid),
    .io_msStatus_3_0_bits_channel(io_msStatus_3_0_bits_channel),
    .io_msStatus_3_0_bits_set(io_msStatus_3_0_bits_set),
    .io_msStatus_3_0_bits_reqTag(io_msStatus_3_0_bits_reqTag),
    .io_msStatus_3_0_bits_is_miss(io_msStatus_3_0_bits_is_miss),
    .io_msStatus_3_0_bits_is_prefetch(io_msStatus_3_0_bits_is_prefetch),
    .io_msStatus_3_1_valid(io_msStatus_3_1_valid),
    .io_msStatus_3_1_bits_channel(io_msStatus_3_1_bits_channel),
    .io_msStatus_3_1_bits_set(io_msStatus_3_1_bits_set),
    .io_msStatus_3_1_bits_reqTag(io_msStatus_3_1_bits_reqTag),
    .io_msStatus_3_1_bits_is_miss(io_msStatus_3_1_bits_is_miss),
    .io_msStatus_3_1_bits_is_prefetch(io_msStatus_3_1_bits_is_prefetch),
    .io_msStatus_3_2_valid(io_msStatus_3_2_valid),
    .io_msStatus_3_2_bits_channel(io_msStatus_3_2_bits_channel),
    .io_msStatus_3_2_bits_set(io_msStatus_3_2_bits_set),
    .io_msStatus_3_2_bits_reqTag(io_msStatus_3_2_bits_reqTag),
    .io_msStatus_3_2_bits_is_miss(io_msStatus_3_2_bits_is_miss),
    .io_msStatus_3_2_bits_is_prefetch(io_msStatus_3_2_bits_is_prefetch),
    .io_msStatus_3_3_valid(io_msStatus_3_3_valid),
    .io_msStatus_3_3_bits_channel(io_msStatus_3_3_bits_channel),
    .io_msStatus_3_3_bits_set(io_msStatus_3_3_bits_set),
    .io_msStatus_3_3_bits_reqTag(io_msStatus_3_3_bits_reqTag),
    .io_msStatus_3_3_bits_is_miss(io_msStatus_3_3_bits_is_miss),
    .io_msStatus_3_3_bits_is_prefetch(io_msStatus_3_3_bits_is_prefetch),
    .io_msStatus_3_4_valid(io_msStatus_3_4_valid),
    .io_msStatus_3_4_bits_channel(io_msStatus_3_4_bits_channel),
    .io_msStatus_3_4_bits_set(io_msStatus_3_4_bits_set),
    .io_msStatus_3_4_bits_reqTag(io_msStatus_3_4_bits_reqTag),
    .io_msStatus_3_4_bits_is_miss(io_msStatus_3_4_bits_is_miss),
    .io_msStatus_3_4_bits_is_prefetch(io_msStatus_3_4_bits_is_prefetch),
    .io_msStatus_3_5_valid(io_msStatus_3_5_valid),
    .io_msStatus_3_5_bits_channel(io_msStatus_3_5_bits_channel),
    .io_msStatus_3_5_bits_set(io_msStatus_3_5_bits_set),
    .io_msStatus_3_5_bits_reqTag(io_msStatus_3_5_bits_reqTag),
    .io_msStatus_3_5_bits_is_miss(io_msStatus_3_5_bits_is_miss),
    .io_msStatus_3_5_bits_is_prefetch(io_msStatus_3_5_bits_is_prefetch),
    .io_msStatus_3_6_valid(io_msStatus_3_6_valid),
    .io_msStatus_3_6_bits_channel(io_msStatus_3_6_bits_channel),
    .io_msStatus_3_6_bits_set(io_msStatus_3_6_bits_set),
    .io_msStatus_3_6_bits_reqTag(io_msStatus_3_6_bits_reqTag),
    .io_msStatus_3_6_bits_is_miss(io_msStatus_3_6_bits_is_miss),
    .io_msStatus_3_6_bits_is_prefetch(io_msStatus_3_6_bits_is_prefetch),
    .io_msStatus_3_7_valid(io_msStatus_3_7_valid),
    .io_msStatus_3_7_bits_channel(io_msStatus_3_7_bits_channel),
    .io_msStatus_3_7_bits_set(io_msStatus_3_7_bits_set),
    .io_msStatus_3_7_bits_reqTag(io_msStatus_3_7_bits_reqTag),
    .io_msStatus_3_7_bits_is_miss(io_msStatus_3_7_bits_is_miss),
    .io_msStatus_3_7_bits_is_prefetch(io_msStatus_3_7_bits_is_prefetch),
    .io_msStatus_3_8_valid(io_msStatus_3_8_valid),
    .io_msStatus_3_8_bits_channel(io_msStatus_3_8_bits_channel),
    .io_msStatus_3_8_bits_set(io_msStatus_3_8_bits_set),
    .io_msStatus_3_8_bits_reqTag(io_msStatus_3_8_bits_reqTag),
    .io_msStatus_3_8_bits_is_miss(io_msStatus_3_8_bits_is_miss),
    .io_msStatus_3_8_bits_is_prefetch(io_msStatus_3_8_bits_is_prefetch),
    .io_msStatus_3_9_valid(io_msStatus_3_9_valid),
    .io_msStatus_3_9_bits_channel(io_msStatus_3_9_bits_channel),
    .io_msStatus_3_9_bits_set(io_msStatus_3_9_bits_set),
    .io_msStatus_3_9_bits_reqTag(io_msStatus_3_9_bits_reqTag),
    .io_msStatus_3_9_bits_is_miss(io_msStatus_3_9_bits_is_miss),
    .io_msStatus_3_9_bits_is_prefetch(io_msStatus_3_9_bits_is_prefetch),
    .io_msStatus_3_10_valid(io_msStatus_3_10_valid),
    .io_msStatus_3_10_bits_channel(io_msStatus_3_10_bits_channel),
    .io_msStatus_3_10_bits_set(io_msStatus_3_10_bits_set),
    .io_msStatus_3_10_bits_reqTag(io_msStatus_3_10_bits_reqTag),
    .io_msStatus_3_10_bits_is_miss(io_msStatus_3_10_bits_is_miss),
    .io_msStatus_3_10_bits_is_prefetch(io_msStatus_3_10_bits_is_prefetch),
    .io_msStatus_3_11_valid(io_msStatus_3_11_valid),
    .io_msStatus_3_11_bits_channel(io_msStatus_3_11_bits_channel),
    .io_msStatus_3_11_bits_set(io_msStatus_3_11_bits_set),
    .io_msStatus_3_11_bits_reqTag(io_msStatus_3_11_bits_reqTag),
    .io_msStatus_3_11_bits_is_miss(io_msStatus_3_11_bits_is_miss),
    .io_msStatus_3_11_bits_is_prefetch(io_msStatus_3_11_bits_is_prefetch),
    .io_msStatus_3_12_valid(io_msStatus_3_12_valid),
    .io_msStatus_3_12_bits_channel(io_msStatus_3_12_bits_channel),
    .io_msStatus_3_12_bits_set(io_msStatus_3_12_bits_set),
    .io_msStatus_3_12_bits_reqTag(io_msStatus_3_12_bits_reqTag),
    .io_msStatus_3_12_bits_is_miss(io_msStatus_3_12_bits_is_miss),
    .io_msStatus_3_12_bits_is_prefetch(io_msStatus_3_12_bits_is_prefetch),
    .io_msStatus_3_13_valid(io_msStatus_3_13_valid),
    .io_msStatus_3_13_bits_channel(io_msStatus_3_13_bits_channel),
    .io_msStatus_3_13_bits_set(io_msStatus_3_13_bits_set),
    .io_msStatus_3_13_bits_reqTag(io_msStatus_3_13_bits_reqTag),
    .io_msStatus_3_13_bits_is_miss(io_msStatus_3_13_bits_is_miss),
    .io_msStatus_3_13_bits_is_prefetch(io_msStatus_3_13_bits_is_prefetch),
    .io_msStatus_3_14_valid(io_msStatus_3_14_valid),
    .io_msStatus_3_14_bits_channel(io_msStatus_3_14_bits_channel),
    .io_msStatus_3_14_bits_set(io_msStatus_3_14_bits_set),
    .io_msStatus_3_14_bits_reqTag(io_msStatus_3_14_bits_reqTag),
    .io_msStatus_3_14_bits_is_miss(io_msStatus_3_14_bits_is_miss),
    .io_msStatus_3_14_bits_is_prefetch(io_msStatus_3_14_bits_is_prefetch),
    .io_msStatus_3_15_valid(io_msStatus_3_15_valid),
    .io_msStatus_3_15_bits_channel(io_msStatus_3_15_bits_channel),
    .io_msStatus_3_15_bits_set(io_msStatus_3_15_bits_set),
    .io_msStatus_3_15_bits_reqTag(io_msStatus_3_15_bits_reqTag),
    .io_msStatus_3_15_bits_is_miss(io_msStatus_3_15_bits_is_miss),
    .io_msStatus_3_15_bits_is_prefetch(io_msStatus_3_15_bits_is_prefetch),
    .io_latePF_0(io_latePF_0),
    .io_latePF_1(io_latePF_1),
    .io_latePF_2(io_latePF_2),
    .io_latePF_3(io_latePF_3),
    .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch(g_io_debugTopDown_l2MissMatch)
  );
  TopDownMonitor_xs u_i (
    .io_dirResult_0_valid(io_dirResult_0_valid),
    .io_dirResult_0_bits_hit(io_dirResult_0_bits_hit),
    .io_dirResult_0_bits_meta_prefetch(io_dirResult_0_bits_meta_prefetch),
    .io_dirResult_0_bits_meta_prefetchSrc(io_dirResult_0_bits_meta_prefetchSrc),
    .io_dirResult_0_bits_replacerInfo_channel(io_dirResult_0_bits_replacerInfo_channel),
    .io_dirResult_0_bits_replacerInfo_reqSource(io_dirResult_0_bits_replacerInfo_reqSource),
    .io_dirResult_1_valid(io_dirResult_1_valid),
    .io_dirResult_1_bits_hit(io_dirResult_1_bits_hit),
    .io_dirResult_1_bits_meta_prefetch(io_dirResult_1_bits_meta_prefetch),
    .io_dirResult_1_bits_meta_prefetchSrc(io_dirResult_1_bits_meta_prefetchSrc),
    .io_dirResult_1_bits_replacerInfo_channel(io_dirResult_1_bits_replacerInfo_channel),
    .io_dirResult_1_bits_replacerInfo_reqSource(io_dirResult_1_bits_replacerInfo_reqSource),
    .io_dirResult_2_valid(io_dirResult_2_valid),
    .io_dirResult_2_bits_hit(io_dirResult_2_bits_hit),
    .io_dirResult_2_bits_meta_prefetch(io_dirResult_2_bits_meta_prefetch),
    .io_dirResult_2_bits_meta_prefetchSrc(io_dirResult_2_bits_meta_prefetchSrc),
    .io_dirResult_2_bits_replacerInfo_channel(io_dirResult_2_bits_replacerInfo_channel),
    .io_dirResult_2_bits_replacerInfo_reqSource(io_dirResult_2_bits_replacerInfo_reqSource),
    .io_dirResult_3_valid(io_dirResult_3_valid),
    .io_dirResult_3_bits_hit(io_dirResult_3_bits_hit),
    .io_dirResult_3_bits_meta_prefetch(io_dirResult_3_bits_meta_prefetch),
    .io_dirResult_3_bits_meta_prefetchSrc(io_dirResult_3_bits_meta_prefetchSrc),
    .io_dirResult_3_bits_replacerInfo_channel(io_dirResult_3_bits_replacerInfo_channel),
    .io_dirResult_3_bits_replacerInfo_reqSource(io_dirResult_3_bits_replacerInfo_reqSource),
    .io_msStatus_0_0_valid(io_msStatus_0_0_valid),
    .io_msStatus_0_0_bits_channel(io_msStatus_0_0_bits_channel),
    .io_msStatus_0_0_bits_set(io_msStatus_0_0_bits_set),
    .io_msStatus_0_0_bits_reqTag(io_msStatus_0_0_bits_reqTag),
    .io_msStatus_0_0_bits_is_miss(io_msStatus_0_0_bits_is_miss),
    .io_msStatus_0_0_bits_is_prefetch(io_msStatus_0_0_bits_is_prefetch),
    .io_msStatus_0_1_valid(io_msStatus_0_1_valid),
    .io_msStatus_0_1_bits_channel(io_msStatus_0_1_bits_channel),
    .io_msStatus_0_1_bits_set(io_msStatus_0_1_bits_set),
    .io_msStatus_0_1_bits_reqTag(io_msStatus_0_1_bits_reqTag),
    .io_msStatus_0_1_bits_is_miss(io_msStatus_0_1_bits_is_miss),
    .io_msStatus_0_1_bits_is_prefetch(io_msStatus_0_1_bits_is_prefetch),
    .io_msStatus_0_2_valid(io_msStatus_0_2_valid),
    .io_msStatus_0_2_bits_channel(io_msStatus_0_2_bits_channel),
    .io_msStatus_0_2_bits_set(io_msStatus_0_2_bits_set),
    .io_msStatus_0_2_bits_reqTag(io_msStatus_0_2_bits_reqTag),
    .io_msStatus_0_2_bits_is_miss(io_msStatus_0_2_bits_is_miss),
    .io_msStatus_0_2_bits_is_prefetch(io_msStatus_0_2_bits_is_prefetch),
    .io_msStatus_0_3_valid(io_msStatus_0_3_valid),
    .io_msStatus_0_3_bits_channel(io_msStatus_0_3_bits_channel),
    .io_msStatus_0_3_bits_set(io_msStatus_0_3_bits_set),
    .io_msStatus_0_3_bits_reqTag(io_msStatus_0_3_bits_reqTag),
    .io_msStatus_0_3_bits_is_miss(io_msStatus_0_3_bits_is_miss),
    .io_msStatus_0_3_bits_is_prefetch(io_msStatus_0_3_bits_is_prefetch),
    .io_msStatus_0_4_valid(io_msStatus_0_4_valid),
    .io_msStatus_0_4_bits_channel(io_msStatus_0_4_bits_channel),
    .io_msStatus_0_4_bits_set(io_msStatus_0_4_bits_set),
    .io_msStatus_0_4_bits_reqTag(io_msStatus_0_4_bits_reqTag),
    .io_msStatus_0_4_bits_is_miss(io_msStatus_0_4_bits_is_miss),
    .io_msStatus_0_4_bits_is_prefetch(io_msStatus_0_4_bits_is_prefetch),
    .io_msStatus_0_5_valid(io_msStatus_0_5_valid),
    .io_msStatus_0_5_bits_channel(io_msStatus_0_5_bits_channel),
    .io_msStatus_0_5_bits_set(io_msStatus_0_5_bits_set),
    .io_msStatus_0_5_bits_reqTag(io_msStatus_0_5_bits_reqTag),
    .io_msStatus_0_5_bits_is_miss(io_msStatus_0_5_bits_is_miss),
    .io_msStatus_0_5_bits_is_prefetch(io_msStatus_0_5_bits_is_prefetch),
    .io_msStatus_0_6_valid(io_msStatus_0_6_valid),
    .io_msStatus_0_6_bits_channel(io_msStatus_0_6_bits_channel),
    .io_msStatus_0_6_bits_set(io_msStatus_0_6_bits_set),
    .io_msStatus_0_6_bits_reqTag(io_msStatus_0_6_bits_reqTag),
    .io_msStatus_0_6_bits_is_miss(io_msStatus_0_6_bits_is_miss),
    .io_msStatus_0_6_bits_is_prefetch(io_msStatus_0_6_bits_is_prefetch),
    .io_msStatus_0_7_valid(io_msStatus_0_7_valid),
    .io_msStatus_0_7_bits_channel(io_msStatus_0_7_bits_channel),
    .io_msStatus_0_7_bits_set(io_msStatus_0_7_bits_set),
    .io_msStatus_0_7_bits_reqTag(io_msStatus_0_7_bits_reqTag),
    .io_msStatus_0_7_bits_is_miss(io_msStatus_0_7_bits_is_miss),
    .io_msStatus_0_7_bits_is_prefetch(io_msStatus_0_7_bits_is_prefetch),
    .io_msStatus_0_8_valid(io_msStatus_0_8_valid),
    .io_msStatus_0_8_bits_channel(io_msStatus_0_8_bits_channel),
    .io_msStatus_0_8_bits_set(io_msStatus_0_8_bits_set),
    .io_msStatus_0_8_bits_reqTag(io_msStatus_0_8_bits_reqTag),
    .io_msStatus_0_8_bits_is_miss(io_msStatus_0_8_bits_is_miss),
    .io_msStatus_0_8_bits_is_prefetch(io_msStatus_0_8_bits_is_prefetch),
    .io_msStatus_0_9_valid(io_msStatus_0_9_valid),
    .io_msStatus_0_9_bits_channel(io_msStatus_0_9_bits_channel),
    .io_msStatus_0_9_bits_set(io_msStatus_0_9_bits_set),
    .io_msStatus_0_9_bits_reqTag(io_msStatus_0_9_bits_reqTag),
    .io_msStatus_0_9_bits_is_miss(io_msStatus_0_9_bits_is_miss),
    .io_msStatus_0_9_bits_is_prefetch(io_msStatus_0_9_bits_is_prefetch),
    .io_msStatus_0_10_valid(io_msStatus_0_10_valid),
    .io_msStatus_0_10_bits_channel(io_msStatus_0_10_bits_channel),
    .io_msStatus_0_10_bits_set(io_msStatus_0_10_bits_set),
    .io_msStatus_0_10_bits_reqTag(io_msStatus_0_10_bits_reqTag),
    .io_msStatus_0_10_bits_is_miss(io_msStatus_0_10_bits_is_miss),
    .io_msStatus_0_10_bits_is_prefetch(io_msStatus_0_10_bits_is_prefetch),
    .io_msStatus_0_11_valid(io_msStatus_0_11_valid),
    .io_msStatus_0_11_bits_channel(io_msStatus_0_11_bits_channel),
    .io_msStatus_0_11_bits_set(io_msStatus_0_11_bits_set),
    .io_msStatus_0_11_bits_reqTag(io_msStatus_0_11_bits_reqTag),
    .io_msStatus_0_11_bits_is_miss(io_msStatus_0_11_bits_is_miss),
    .io_msStatus_0_11_bits_is_prefetch(io_msStatus_0_11_bits_is_prefetch),
    .io_msStatus_0_12_valid(io_msStatus_0_12_valid),
    .io_msStatus_0_12_bits_channel(io_msStatus_0_12_bits_channel),
    .io_msStatus_0_12_bits_set(io_msStatus_0_12_bits_set),
    .io_msStatus_0_12_bits_reqTag(io_msStatus_0_12_bits_reqTag),
    .io_msStatus_0_12_bits_is_miss(io_msStatus_0_12_bits_is_miss),
    .io_msStatus_0_12_bits_is_prefetch(io_msStatus_0_12_bits_is_prefetch),
    .io_msStatus_0_13_valid(io_msStatus_0_13_valid),
    .io_msStatus_0_13_bits_channel(io_msStatus_0_13_bits_channel),
    .io_msStatus_0_13_bits_set(io_msStatus_0_13_bits_set),
    .io_msStatus_0_13_bits_reqTag(io_msStatus_0_13_bits_reqTag),
    .io_msStatus_0_13_bits_is_miss(io_msStatus_0_13_bits_is_miss),
    .io_msStatus_0_13_bits_is_prefetch(io_msStatus_0_13_bits_is_prefetch),
    .io_msStatus_0_14_valid(io_msStatus_0_14_valid),
    .io_msStatus_0_14_bits_channel(io_msStatus_0_14_bits_channel),
    .io_msStatus_0_14_bits_set(io_msStatus_0_14_bits_set),
    .io_msStatus_0_14_bits_reqTag(io_msStatus_0_14_bits_reqTag),
    .io_msStatus_0_14_bits_is_miss(io_msStatus_0_14_bits_is_miss),
    .io_msStatus_0_14_bits_is_prefetch(io_msStatus_0_14_bits_is_prefetch),
    .io_msStatus_0_15_valid(io_msStatus_0_15_valid),
    .io_msStatus_0_15_bits_channel(io_msStatus_0_15_bits_channel),
    .io_msStatus_0_15_bits_set(io_msStatus_0_15_bits_set),
    .io_msStatus_0_15_bits_reqTag(io_msStatus_0_15_bits_reqTag),
    .io_msStatus_0_15_bits_is_miss(io_msStatus_0_15_bits_is_miss),
    .io_msStatus_0_15_bits_is_prefetch(io_msStatus_0_15_bits_is_prefetch),
    .io_msStatus_1_0_valid(io_msStatus_1_0_valid),
    .io_msStatus_1_0_bits_channel(io_msStatus_1_0_bits_channel),
    .io_msStatus_1_0_bits_set(io_msStatus_1_0_bits_set),
    .io_msStatus_1_0_bits_reqTag(io_msStatus_1_0_bits_reqTag),
    .io_msStatus_1_0_bits_is_miss(io_msStatus_1_0_bits_is_miss),
    .io_msStatus_1_0_bits_is_prefetch(io_msStatus_1_0_bits_is_prefetch),
    .io_msStatus_1_1_valid(io_msStatus_1_1_valid),
    .io_msStatus_1_1_bits_channel(io_msStatus_1_1_bits_channel),
    .io_msStatus_1_1_bits_set(io_msStatus_1_1_bits_set),
    .io_msStatus_1_1_bits_reqTag(io_msStatus_1_1_bits_reqTag),
    .io_msStatus_1_1_bits_is_miss(io_msStatus_1_1_bits_is_miss),
    .io_msStatus_1_1_bits_is_prefetch(io_msStatus_1_1_bits_is_prefetch),
    .io_msStatus_1_2_valid(io_msStatus_1_2_valid),
    .io_msStatus_1_2_bits_channel(io_msStatus_1_2_bits_channel),
    .io_msStatus_1_2_bits_set(io_msStatus_1_2_bits_set),
    .io_msStatus_1_2_bits_reqTag(io_msStatus_1_2_bits_reqTag),
    .io_msStatus_1_2_bits_is_miss(io_msStatus_1_2_bits_is_miss),
    .io_msStatus_1_2_bits_is_prefetch(io_msStatus_1_2_bits_is_prefetch),
    .io_msStatus_1_3_valid(io_msStatus_1_3_valid),
    .io_msStatus_1_3_bits_channel(io_msStatus_1_3_bits_channel),
    .io_msStatus_1_3_bits_set(io_msStatus_1_3_bits_set),
    .io_msStatus_1_3_bits_reqTag(io_msStatus_1_3_bits_reqTag),
    .io_msStatus_1_3_bits_is_miss(io_msStatus_1_3_bits_is_miss),
    .io_msStatus_1_3_bits_is_prefetch(io_msStatus_1_3_bits_is_prefetch),
    .io_msStatus_1_4_valid(io_msStatus_1_4_valid),
    .io_msStatus_1_4_bits_channel(io_msStatus_1_4_bits_channel),
    .io_msStatus_1_4_bits_set(io_msStatus_1_4_bits_set),
    .io_msStatus_1_4_bits_reqTag(io_msStatus_1_4_bits_reqTag),
    .io_msStatus_1_4_bits_is_miss(io_msStatus_1_4_bits_is_miss),
    .io_msStatus_1_4_bits_is_prefetch(io_msStatus_1_4_bits_is_prefetch),
    .io_msStatus_1_5_valid(io_msStatus_1_5_valid),
    .io_msStatus_1_5_bits_channel(io_msStatus_1_5_bits_channel),
    .io_msStatus_1_5_bits_set(io_msStatus_1_5_bits_set),
    .io_msStatus_1_5_bits_reqTag(io_msStatus_1_5_bits_reqTag),
    .io_msStatus_1_5_bits_is_miss(io_msStatus_1_5_bits_is_miss),
    .io_msStatus_1_5_bits_is_prefetch(io_msStatus_1_5_bits_is_prefetch),
    .io_msStatus_1_6_valid(io_msStatus_1_6_valid),
    .io_msStatus_1_6_bits_channel(io_msStatus_1_6_bits_channel),
    .io_msStatus_1_6_bits_set(io_msStatus_1_6_bits_set),
    .io_msStatus_1_6_bits_reqTag(io_msStatus_1_6_bits_reqTag),
    .io_msStatus_1_6_bits_is_miss(io_msStatus_1_6_bits_is_miss),
    .io_msStatus_1_6_bits_is_prefetch(io_msStatus_1_6_bits_is_prefetch),
    .io_msStatus_1_7_valid(io_msStatus_1_7_valid),
    .io_msStatus_1_7_bits_channel(io_msStatus_1_7_bits_channel),
    .io_msStatus_1_7_bits_set(io_msStatus_1_7_bits_set),
    .io_msStatus_1_7_bits_reqTag(io_msStatus_1_7_bits_reqTag),
    .io_msStatus_1_7_bits_is_miss(io_msStatus_1_7_bits_is_miss),
    .io_msStatus_1_7_bits_is_prefetch(io_msStatus_1_7_bits_is_prefetch),
    .io_msStatus_1_8_valid(io_msStatus_1_8_valid),
    .io_msStatus_1_8_bits_channel(io_msStatus_1_8_bits_channel),
    .io_msStatus_1_8_bits_set(io_msStatus_1_8_bits_set),
    .io_msStatus_1_8_bits_reqTag(io_msStatus_1_8_bits_reqTag),
    .io_msStatus_1_8_bits_is_miss(io_msStatus_1_8_bits_is_miss),
    .io_msStatus_1_8_bits_is_prefetch(io_msStatus_1_8_bits_is_prefetch),
    .io_msStatus_1_9_valid(io_msStatus_1_9_valid),
    .io_msStatus_1_9_bits_channel(io_msStatus_1_9_bits_channel),
    .io_msStatus_1_9_bits_set(io_msStatus_1_9_bits_set),
    .io_msStatus_1_9_bits_reqTag(io_msStatus_1_9_bits_reqTag),
    .io_msStatus_1_9_bits_is_miss(io_msStatus_1_9_bits_is_miss),
    .io_msStatus_1_9_bits_is_prefetch(io_msStatus_1_9_bits_is_prefetch),
    .io_msStatus_1_10_valid(io_msStatus_1_10_valid),
    .io_msStatus_1_10_bits_channel(io_msStatus_1_10_bits_channel),
    .io_msStatus_1_10_bits_set(io_msStatus_1_10_bits_set),
    .io_msStatus_1_10_bits_reqTag(io_msStatus_1_10_bits_reqTag),
    .io_msStatus_1_10_bits_is_miss(io_msStatus_1_10_bits_is_miss),
    .io_msStatus_1_10_bits_is_prefetch(io_msStatus_1_10_bits_is_prefetch),
    .io_msStatus_1_11_valid(io_msStatus_1_11_valid),
    .io_msStatus_1_11_bits_channel(io_msStatus_1_11_bits_channel),
    .io_msStatus_1_11_bits_set(io_msStatus_1_11_bits_set),
    .io_msStatus_1_11_bits_reqTag(io_msStatus_1_11_bits_reqTag),
    .io_msStatus_1_11_bits_is_miss(io_msStatus_1_11_bits_is_miss),
    .io_msStatus_1_11_bits_is_prefetch(io_msStatus_1_11_bits_is_prefetch),
    .io_msStatus_1_12_valid(io_msStatus_1_12_valid),
    .io_msStatus_1_12_bits_channel(io_msStatus_1_12_bits_channel),
    .io_msStatus_1_12_bits_set(io_msStatus_1_12_bits_set),
    .io_msStatus_1_12_bits_reqTag(io_msStatus_1_12_bits_reqTag),
    .io_msStatus_1_12_bits_is_miss(io_msStatus_1_12_bits_is_miss),
    .io_msStatus_1_12_bits_is_prefetch(io_msStatus_1_12_bits_is_prefetch),
    .io_msStatus_1_13_valid(io_msStatus_1_13_valid),
    .io_msStatus_1_13_bits_channel(io_msStatus_1_13_bits_channel),
    .io_msStatus_1_13_bits_set(io_msStatus_1_13_bits_set),
    .io_msStatus_1_13_bits_reqTag(io_msStatus_1_13_bits_reqTag),
    .io_msStatus_1_13_bits_is_miss(io_msStatus_1_13_bits_is_miss),
    .io_msStatus_1_13_bits_is_prefetch(io_msStatus_1_13_bits_is_prefetch),
    .io_msStatus_1_14_valid(io_msStatus_1_14_valid),
    .io_msStatus_1_14_bits_channel(io_msStatus_1_14_bits_channel),
    .io_msStatus_1_14_bits_set(io_msStatus_1_14_bits_set),
    .io_msStatus_1_14_bits_reqTag(io_msStatus_1_14_bits_reqTag),
    .io_msStatus_1_14_bits_is_miss(io_msStatus_1_14_bits_is_miss),
    .io_msStatus_1_14_bits_is_prefetch(io_msStatus_1_14_bits_is_prefetch),
    .io_msStatus_1_15_valid(io_msStatus_1_15_valid),
    .io_msStatus_1_15_bits_channel(io_msStatus_1_15_bits_channel),
    .io_msStatus_1_15_bits_set(io_msStatus_1_15_bits_set),
    .io_msStatus_1_15_bits_reqTag(io_msStatus_1_15_bits_reqTag),
    .io_msStatus_1_15_bits_is_miss(io_msStatus_1_15_bits_is_miss),
    .io_msStatus_1_15_bits_is_prefetch(io_msStatus_1_15_bits_is_prefetch),
    .io_msStatus_2_0_valid(io_msStatus_2_0_valid),
    .io_msStatus_2_0_bits_channel(io_msStatus_2_0_bits_channel),
    .io_msStatus_2_0_bits_set(io_msStatus_2_0_bits_set),
    .io_msStatus_2_0_bits_reqTag(io_msStatus_2_0_bits_reqTag),
    .io_msStatus_2_0_bits_is_miss(io_msStatus_2_0_bits_is_miss),
    .io_msStatus_2_0_bits_is_prefetch(io_msStatus_2_0_bits_is_prefetch),
    .io_msStatus_2_1_valid(io_msStatus_2_1_valid),
    .io_msStatus_2_1_bits_channel(io_msStatus_2_1_bits_channel),
    .io_msStatus_2_1_bits_set(io_msStatus_2_1_bits_set),
    .io_msStatus_2_1_bits_reqTag(io_msStatus_2_1_bits_reqTag),
    .io_msStatus_2_1_bits_is_miss(io_msStatus_2_1_bits_is_miss),
    .io_msStatus_2_1_bits_is_prefetch(io_msStatus_2_1_bits_is_prefetch),
    .io_msStatus_2_2_valid(io_msStatus_2_2_valid),
    .io_msStatus_2_2_bits_channel(io_msStatus_2_2_bits_channel),
    .io_msStatus_2_2_bits_set(io_msStatus_2_2_bits_set),
    .io_msStatus_2_2_bits_reqTag(io_msStatus_2_2_bits_reqTag),
    .io_msStatus_2_2_bits_is_miss(io_msStatus_2_2_bits_is_miss),
    .io_msStatus_2_2_bits_is_prefetch(io_msStatus_2_2_bits_is_prefetch),
    .io_msStatus_2_3_valid(io_msStatus_2_3_valid),
    .io_msStatus_2_3_bits_channel(io_msStatus_2_3_bits_channel),
    .io_msStatus_2_3_bits_set(io_msStatus_2_3_bits_set),
    .io_msStatus_2_3_bits_reqTag(io_msStatus_2_3_bits_reqTag),
    .io_msStatus_2_3_bits_is_miss(io_msStatus_2_3_bits_is_miss),
    .io_msStatus_2_3_bits_is_prefetch(io_msStatus_2_3_bits_is_prefetch),
    .io_msStatus_2_4_valid(io_msStatus_2_4_valid),
    .io_msStatus_2_4_bits_channel(io_msStatus_2_4_bits_channel),
    .io_msStatus_2_4_bits_set(io_msStatus_2_4_bits_set),
    .io_msStatus_2_4_bits_reqTag(io_msStatus_2_4_bits_reqTag),
    .io_msStatus_2_4_bits_is_miss(io_msStatus_2_4_bits_is_miss),
    .io_msStatus_2_4_bits_is_prefetch(io_msStatus_2_4_bits_is_prefetch),
    .io_msStatus_2_5_valid(io_msStatus_2_5_valid),
    .io_msStatus_2_5_bits_channel(io_msStatus_2_5_bits_channel),
    .io_msStatus_2_5_bits_set(io_msStatus_2_5_bits_set),
    .io_msStatus_2_5_bits_reqTag(io_msStatus_2_5_bits_reqTag),
    .io_msStatus_2_5_bits_is_miss(io_msStatus_2_5_bits_is_miss),
    .io_msStatus_2_5_bits_is_prefetch(io_msStatus_2_5_bits_is_prefetch),
    .io_msStatus_2_6_valid(io_msStatus_2_6_valid),
    .io_msStatus_2_6_bits_channel(io_msStatus_2_6_bits_channel),
    .io_msStatus_2_6_bits_set(io_msStatus_2_6_bits_set),
    .io_msStatus_2_6_bits_reqTag(io_msStatus_2_6_bits_reqTag),
    .io_msStatus_2_6_bits_is_miss(io_msStatus_2_6_bits_is_miss),
    .io_msStatus_2_6_bits_is_prefetch(io_msStatus_2_6_bits_is_prefetch),
    .io_msStatus_2_7_valid(io_msStatus_2_7_valid),
    .io_msStatus_2_7_bits_channel(io_msStatus_2_7_bits_channel),
    .io_msStatus_2_7_bits_set(io_msStatus_2_7_bits_set),
    .io_msStatus_2_7_bits_reqTag(io_msStatus_2_7_bits_reqTag),
    .io_msStatus_2_7_bits_is_miss(io_msStatus_2_7_bits_is_miss),
    .io_msStatus_2_7_bits_is_prefetch(io_msStatus_2_7_bits_is_prefetch),
    .io_msStatus_2_8_valid(io_msStatus_2_8_valid),
    .io_msStatus_2_8_bits_channel(io_msStatus_2_8_bits_channel),
    .io_msStatus_2_8_bits_set(io_msStatus_2_8_bits_set),
    .io_msStatus_2_8_bits_reqTag(io_msStatus_2_8_bits_reqTag),
    .io_msStatus_2_8_bits_is_miss(io_msStatus_2_8_bits_is_miss),
    .io_msStatus_2_8_bits_is_prefetch(io_msStatus_2_8_bits_is_prefetch),
    .io_msStatus_2_9_valid(io_msStatus_2_9_valid),
    .io_msStatus_2_9_bits_channel(io_msStatus_2_9_bits_channel),
    .io_msStatus_2_9_bits_set(io_msStatus_2_9_bits_set),
    .io_msStatus_2_9_bits_reqTag(io_msStatus_2_9_bits_reqTag),
    .io_msStatus_2_9_bits_is_miss(io_msStatus_2_9_bits_is_miss),
    .io_msStatus_2_9_bits_is_prefetch(io_msStatus_2_9_bits_is_prefetch),
    .io_msStatus_2_10_valid(io_msStatus_2_10_valid),
    .io_msStatus_2_10_bits_channel(io_msStatus_2_10_bits_channel),
    .io_msStatus_2_10_bits_set(io_msStatus_2_10_bits_set),
    .io_msStatus_2_10_bits_reqTag(io_msStatus_2_10_bits_reqTag),
    .io_msStatus_2_10_bits_is_miss(io_msStatus_2_10_bits_is_miss),
    .io_msStatus_2_10_bits_is_prefetch(io_msStatus_2_10_bits_is_prefetch),
    .io_msStatus_2_11_valid(io_msStatus_2_11_valid),
    .io_msStatus_2_11_bits_channel(io_msStatus_2_11_bits_channel),
    .io_msStatus_2_11_bits_set(io_msStatus_2_11_bits_set),
    .io_msStatus_2_11_bits_reqTag(io_msStatus_2_11_bits_reqTag),
    .io_msStatus_2_11_bits_is_miss(io_msStatus_2_11_bits_is_miss),
    .io_msStatus_2_11_bits_is_prefetch(io_msStatus_2_11_bits_is_prefetch),
    .io_msStatus_2_12_valid(io_msStatus_2_12_valid),
    .io_msStatus_2_12_bits_channel(io_msStatus_2_12_bits_channel),
    .io_msStatus_2_12_bits_set(io_msStatus_2_12_bits_set),
    .io_msStatus_2_12_bits_reqTag(io_msStatus_2_12_bits_reqTag),
    .io_msStatus_2_12_bits_is_miss(io_msStatus_2_12_bits_is_miss),
    .io_msStatus_2_12_bits_is_prefetch(io_msStatus_2_12_bits_is_prefetch),
    .io_msStatus_2_13_valid(io_msStatus_2_13_valid),
    .io_msStatus_2_13_bits_channel(io_msStatus_2_13_bits_channel),
    .io_msStatus_2_13_bits_set(io_msStatus_2_13_bits_set),
    .io_msStatus_2_13_bits_reqTag(io_msStatus_2_13_bits_reqTag),
    .io_msStatus_2_13_bits_is_miss(io_msStatus_2_13_bits_is_miss),
    .io_msStatus_2_13_bits_is_prefetch(io_msStatus_2_13_bits_is_prefetch),
    .io_msStatus_2_14_valid(io_msStatus_2_14_valid),
    .io_msStatus_2_14_bits_channel(io_msStatus_2_14_bits_channel),
    .io_msStatus_2_14_bits_set(io_msStatus_2_14_bits_set),
    .io_msStatus_2_14_bits_reqTag(io_msStatus_2_14_bits_reqTag),
    .io_msStatus_2_14_bits_is_miss(io_msStatus_2_14_bits_is_miss),
    .io_msStatus_2_14_bits_is_prefetch(io_msStatus_2_14_bits_is_prefetch),
    .io_msStatus_2_15_valid(io_msStatus_2_15_valid),
    .io_msStatus_2_15_bits_channel(io_msStatus_2_15_bits_channel),
    .io_msStatus_2_15_bits_set(io_msStatus_2_15_bits_set),
    .io_msStatus_2_15_bits_reqTag(io_msStatus_2_15_bits_reqTag),
    .io_msStatus_2_15_bits_is_miss(io_msStatus_2_15_bits_is_miss),
    .io_msStatus_2_15_bits_is_prefetch(io_msStatus_2_15_bits_is_prefetch),
    .io_msStatus_3_0_valid(io_msStatus_3_0_valid),
    .io_msStatus_3_0_bits_channel(io_msStatus_3_0_bits_channel),
    .io_msStatus_3_0_bits_set(io_msStatus_3_0_bits_set),
    .io_msStatus_3_0_bits_reqTag(io_msStatus_3_0_bits_reqTag),
    .io_msStatus_3_0_bits_is_miss(io_msStatus_3_0_bits_is_miss),
    .io_msStatus_3_0_bits_is_prefetch(io_msStatus_3_0_bits_is_prefetch),
    .io_msStatus_3_1_valid(io_msStatus_3_1_valid),
    .io_msStatus_3_1_bits_channel(io_msStatus_3_1_bits_channel),
    .io_msStatus_3_1_bits_set(io_msStatus_3_1_bits_set),
    .io_msStatus_3_1_bits_reqTag(io_msStatus_3_1_bits_reqTag),
    .io_msStatus_3_1_bits_is_miss(io_msStatus_3_1_bits_is_miss),
    .io_msStatus_3_1_bits_is_prefetch(io_msStatus_3_1_bits_is_prefetch),
    .io_msStatus_3_2_valid(io_msStatus_3_2_valid),
    .io_msStatus_3_2_bits_channel(io_msStatus_3_2_bits_channel),
    .io_msStatus_3_2_bits_set(io_msStatus_3_2_bits_set),
    .io_msStatus_3_2_bits_reqTag(io_msStatus_3_2_bits_reqTag),
    .io_msStatus_3_2_bits_is_miss(io_msStatus_3_2_bits_is_miss),
    .io_msStatus_3_2_bits_is_prefetch(io_msStatus_3_2_bits_is_prefetch),
    .io_msStatus_3_3_valid(io_msStatus_3_3_valid),
    .io_msStatus_3_3_bits_channel(io_msStatus_3_3_bits_channel),
    .io_msStatus_3_3_bits_set(io_msStatus_3_3_bits_set),
    .io_msStatus_3_3_bits_reqTag(io_msStatus_3_3_bits_reqTag),
    .io_msStatus_3_3_bits_is_miss(io_msStatus_3_3_bits_is_miss),
    .io_msStatus_3_3_bits_is_prefetch(io_msStatus_3_3_bits_is_prefetch),
    .io_msStatus_3_4_valid(io_msStatus_3_4_valid),
    .io_msStatus_3_4_bits_channel(io_msStatus_3_4_bits_channel),
    .io_msStatus_3_4_bits_set(io_msStatus_3_4_bits_set),
    .io_msStatus_3_4_bits_reqTag(io_msStatus_3_4_bits_reqTag),
    .io_msStatus_3_4_bits_is_miss(io_msStatus_3_4_bits_is_miss),
    .io_msStatus_3_4_bits_is_prefetch(io_msStatus_3_4_bits_is_prefetch),
    .io_msStatus_3_5_valid(io_msStatus_3_5_valid),
    .io_msStatus_3_5_bits_channel(io_msStatus_3_5_bits_channel),
    .io_msStatus_3_5_bits_set(io_msStatus_3_5_bits_set),
    .io_msStatus_3_5_bits_reqTag(io_msStatus_3_5_bits_reqTag),
    .io_msStatus_3_5_bits_is_miss(io_msStatus_3_5_bits_is_miss),
    .io_msStatus_3_5_bits_is_prefetch(io_msStatus_3_5_bits_is_prefetch),
    .io_msStatus_3_6_valid(io_msStatus_3_6_valid),
    .io_msStatus_3_6_bits_channel(io_msStatus_3_6_bits_channel),
    .io_msStatus_3_6_bits_set(io_msStatus_3_6_bits_set),
    .io_msStatus_3_6_bits_reqTag(io_msStatus_3_6_bits_reqTag),
    .io_msStatus_3_6_bits_is_miss(io_msStatus_3_6_bits_is_miss),
    .io_msStatus_3_6_bits_is_prefetch(io_msStatus_3_6_bits_is_prefetch),
    .io_msStatus_3_7_valid(io_msStatus_3_7_valid),
    .io_msStatus_3_7_bits_channel(io_msStatus_3_7_bits_channel),
    .io_msStatus_3_7_bits_set(io_msStatus_3_7_bits_set),
    .io_msStatus_3_7_bits_reqTag(io_msStatus_3_7_bits_reqTag),
    .io_msStatus_3_7_bits_is_miss(io_msStatus_3_7_bits_is_miss),
    .io_msStatus_3_7_bits_is_prefetch(io_msStatus_3_7_bits_is_prefetch),
    .io_msStatus_3_8_valid(io_msStatus_3_8_valid),
    .io_msStatus_3_8_bits_channel(io_msStatus_3_8_bits_channel),
    .io_msStatus_3_8_bits_set(io_msStatus_3_8_bits_set),
    .io_msStatus_3_8_bits_reqTag(io_msStatus_3_8_bits_reqTag),
    .io_msStatus_3_8_bits_is_miss(io_msStatus_3_8_bits_is_miss),
    .io_msStatus_3_8_bits_is_prefetch(io_msStatus_3_8_bits_is_prefetch),
    .io_msStatus_3_9_valid(io_msStatus_3_9_valid),
    .io_msStatus_3_9_bits_channel(io_msStatus_3_9_bits_channel),
    .io_msStatus_3_9_bits_set(io_msStatus_3_9_bits_set),
    .io_msStatus_3_9_bits_reqTag(io_msStatus_3_9_bits_reqTag),
    .io_msStatus_3_9_bits_is_miss(io_msStatus_3_9_bits_is_miss),
    .io_msStatus_3_9_bits_is_prefetch(io_msStatus_3_9_bits_is_prefetch),
    .io_msStatus_3_10_valid(io_msStatus_3_10_valid),
    .io_msStatus_3_10_bits_channel(io_msStatus_3_10_bits_channel),
    .io_msStatus_3_10_bits_set(io_msStatus_3_10_bits_set),
    .io_msStatus_3_10_bits_reqTag(io_msStatus_3_10_bits_reqTag),
    .io_msStatus_3_10_bits_is_miss(io_msStatus_3_10_bits_is_miss),
    .io_msStatus_3_10_bits_is_prefetch(io_msStatus_3_10_bits_is_prefetch),
    .io_msStatus_3_11_valid(io_msStatus_3_11_valid),
    .io_msStatus_3_11_bits_channel(io_msStatus_3_11_bits_channel),
    .io_msStatus_3_11_bits_set(io_msStatus_3_11_bits_set),
    .io_msStatus_3_11_bits_reqTag(io_msStatus_3_11_bits_reqTag),
    .io_msStatus_3_11_bits_is_miss(io_msStatus_3_11_bits_is_miss),
    .io_msStatus_3_11_bits_is_prefetch(io_msStatus_3_11_bits_is_prefetch),
    .io_msStatus_3_12_valid(io_msStatus_3_12_valid),
    .io_msStatus_3_12_bits_channel(io_msStatus_3_12_bits_channel),
    .io_msStatus_3_12_bits_set(io_msStatus_3_12_bits_set),
    .io_msStatus_3_12_bits_reqTag(io_msStatus_3_12_bits_reqTag),
    .io_msStatus_3_12_bits_is_miss(io_msStatus_3_12_bits_is_miss),
    .io_msStatus_3_12_bits_is_prefetch(io_msStatus_3_12_bits_is_prefetch),
    .io_msStatus_3_13_valid(io_msStatus_3_13_valid),
    .io_msStatus_3_13_bits_channel(io_msStatus_3_13_bits_channel),
    .io_msStatus_3_13_bits_set(io_msStatus_3_13_bits_set),
    .io_msStatus_3_13_bits_reqTag(io_msStatus_3_13_bits_reqTag),
    .io_msStatus_3_13_bits_is_miss(io_msStatus_3_13_bits_is_miss),
    .io_msStatus_3_13_bits_is_prefetch(io_msStatus_3_13_bits_is_prefetch),
    .io_msStatus_3_14_valid(io_msStatus_3_14_valid),
    .io_msStatus_3_14_bits_channel(io_msStatus_3_14_bits_channel),
    .io_msStatus_3_14_bits_set(io_msStatus_3_14_bits_set),
    .io_msStatus_3_14_bits_reqTag(io_msStatus_3_14_bits_reqTag),
    .io_msStatus_3_14_bits_is_miss(io_msStatus_3_14_bits_is_miss),
    .io_msStatus_3_14_bits_is_prefetch(io_msStatus_3_14_bits_is_prefetch),
    .io_msStatus_3_15_valid(io_msStatus_3_15_valid),
    .io_msStatus_3_15_bits_channel(io_msStatus_3_15_bits_channel),
    .io_msStatus_3_15_bits_set(io_msStatus_3_15_bits_set),
    .io_msStatus_3_15_bits_reqTag(io_msStatus_3_15_bits_reqTag),
    .io_msStatus_3_15_bits_is_miss(io_msStatus_3_15_bits_is_miss),
    .io_msStatus_3_15_bits_is_prefetch(io_msStatus_3_15_bits_is_prefetch),
    .io_latePF_0(io_latePF_0),
    .io_latePF_1(io_latePF_1),
    .io_latePF_2(io_latePF_2),
    .io_latePF_3(io_latePF_3),
    .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch(i_io_debugTopDown_l2MissMatch)
  );
  task automatic drive_random_inputs();
    io_dirResult_0_valid = $urandom_range(0, 1);
    io_dirResult_0_bits_hit = $urandom_range(0, 1);
    io_dirResult_0_bits_meta_prefetch = $urandom_range(0, 1);
    io_dirResult_0_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_0_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_0_bits_replacerInfo_reqSource = 5'($urandom);
    io_dirResult_1_valid = $urandom_range(0, 1);
    io_dirResult_1_bits_hit = $urandom_range(0, 1);
    io_dirResult_1_bits_meta_prefetch = $urandom_range(0, 1);
    io_dirResult_1_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_1_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_1_bits_replacerInfo_reqSource = 5'($urandom);
    io_dirResult_2_valid = $urandom_range(0, 1);
    io_dirResult_2_bits_hit = $urandom_range(0, 1);
    io_dirResult_2_bits_meta_prefetch = $urandom_range(0, 1);
    io_dirResult_2_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_2_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_2_bits_replacerInfo_reqSource = 5'($urandom);
    io_dirResult_3_valid = $urandom_range(0, 1);
    io_dirResult_3_bits_hit = $urandom_range(0, 1);
    io_dirResult_3_bits_meta_prefetch = $urandom_range(0, 1);
    io_dirResult_3_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_3_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_3_bits_replacerInfo_reqSource = 5'($urandom);
    io_msStatus_0_0_valid = $urandom_range(0, 1);
    io_msStatus_0_0_bits_channel = 3'($urandom);
    io_msStatus_0_0_bits_set = 9'($urandom);
    io_msStatus_0_0_bits_reqTag = 31'($urandom);
    io_msStatus_0_0_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_0_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_1_valid = $urandom_range(0, 1);
    io_msStatus_0_1_bits_channel = 3'($urandom);
    io_msStatus_0_1_bits_set = 9'($urandom);
    io_msStatus_0_1_bits_reqTag = 31'($urandom);
    io_msStatus_0_1_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_1_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_2_valid = $urandom_range(0, 1);
    io_msStatus_0_2_bits_channel = 3'($urandom);
    io_msStatus_0_2_bits_set = 9'($urandom);
    io_msStatus_0_2_bits_reqTag = 31'($urandom);
    io_msStatus_0_2_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_2_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_3_valid = $urandom_range(0, 1);
    io_msStatus_0_3_bits_channel = 3'($urandom);
    io_msStatus_0_3_bits_set = 9'($urandom);
    io_msStatus_0_3_bits_reqTag = 31'($urandom);
    io_msStatus_0_3_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_3_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_4_valid = $urandom_range(0, 1);
    io_msStatus_0_4_bits_channel = 3'($urandom);
    io_msStatus_0_4_bits_set = 9'($urandom);
    io_msStatus_0_4_bits_reqTag = 31'($urandom);
    io_msStatus_0_4_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_4_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_5_valid = $urandom_range(0, 1);
    io_msStatus_0_5_bits_channel = 3'($urandom);
    io_msStatus_0_5_bits_set = 9'($urandom);
    io_msStatus_0_5_bits_reqTag = 31'($urandom);
    io_msStatus_0_5_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_5_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_6_valid = $urandom_range(0, 1);
    io_msStatus_0_6_bits_channel = 3'($urandom);
    io_msStatus_0_6_bits_set = 9'($urandom);
    io_msStatus_0_6_bits_reqTag = 31'($urandom);
    io_msStatus_0_6_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_6_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_7_valid = $urandom_range(0, 1);
    io_msStatus_0_7_bits_channel = 3'($urandom);
    io_msStatus_0_7_bits_set = 9'($urandom);
    io_msStatus_0_7_bits_reqTag = 31'($urandom);
    io_msStatus_0_7_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_7_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_8_valid = $urandom_range(0, 1);
    io_msStatus_0_8_bits_channel = 3'($urandom);
    io_msStatus_0_8_bits_set = 9'($urandom);
    io_msStatus_0_8_bits_reqTag = 31'($urandom);
    io_msStatus_0_8_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_8_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_9_valid = $urandom_range(0, 1);
    io_msStatus_0_9_bits_channel = 3'($urandom);
    io_msStatus_0_9_bits_set = 9'($urandom);
    io_msStatus_0_9_bits_reqTag = 31'($urandom);
    io_msStatus_0_9_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_9_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_10_valid = $urandom_range(0, 1);
    io_msStatus_0_10_bits_channel = 3'($urandom);
    io_msStatus_0_10_bits_set = 9'($urandom);
    io_msStatus_0_10_bits_reqTag = 31'($urandom);
    io_msStatus_0_10_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_10_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_11_valid = $urandom_range(0, 1);
    io_msStatus_0_11_bits_channel = 3'($urandom);
    io_msStatus_0_11_bits_set = 9'($urandom);
    io_msStatus_0_11_bits_reqTag = 31'($urandom);
    io_msStatus_0_11_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_11_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_12_valid = $urandom_range(0, 1);
    io_msStatus_0_12_bits_channel = 3'($urandom);
    io_msStatus_0_12_bits_set = 9'($urandom);
    io_msStatus_0_12_bits_reqTag = 31'($urandom);
    io_msStatus_0_12_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_12_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_13_valid = $urandom_range(0, 1);
    io_msStatus_0_13_bits_channel = 3'($urandom);
    io_msStatus_0_13_bits_set = 9'($urandom);
    io_msStatus_0_13_bits_reqTag = 31'($urandom);
    io_msStatus_0_13_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_13_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_14_valid = $urandom_range(0, 1);
    io_msStatus_0_14_bits_channel = 3'($urandom);
    io_msStatus_0_14_bits_set = 9'($urandom);
    io_msStatus_0_14_bits_reqTag = 31'($urandom);
    io_msStatus_0_14_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_14_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_0_15_valid = $urandom_range(0, 1);
    io_msStatus_0_15_bits_channel = 3'($urandom);
    io_msStatus_0_15_bits_set = 9'($urandom);
    io_msStatus_0_15_bits_reqTag = 31'($urandom);
    io_msStatus_0_15_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_0_15_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_0_valid = $urandom_range(0, 1);
    io_msStatus_1_0_bits_channel = 3'($urandom);
    io_msStatus_1_0_bits_set = 9'($urandom);
    io_msStatus_1_0_bits_reqTag = 31'($urandom);
    io_msStatus_1_0_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_0_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_1_valid = $urandom_range(0, 1);
    io_msStatus_1_1_bits_channel = 3'($urandom);
    io_msStatus_1_1_bits_set = 9'($urandom);
    io_msStatus_1_1_bits_reqTag = 31'($urandom);
    io_msStatus_1_1_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_1_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_2_valid = $urandom_range(0, 1);
    io_msStatus_1_2_bits_channel = 3'($urandom);
    io_msStatus_1_2_bits_set = 9'($urandom);
    io_msStatus_1_2_bits_reqTag = 31'($urandom);
    io_msStatus_1_2_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_2_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_3_valid = $urandom_range(0, 1);
    io_msStatus_1_3_bits_channel = 3'($urandom);
    io_msStatus_1_3_bits_set = 9'($urandom);
    io_msStatus_1_3_bits_reqTag = 31'($urandom);
    io_msStatus_1_3_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_3_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_4_valid = $urandom_range(0, 1);
    io_msStatus_1_4_bits_channel = 3'($urandom);
    io_msStatus_1_4_bits_set = 9'($urandom);
    io_msStatus_1_4_bits_reqTag = 31'($urandom);
    io_msStatus_1_4_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_4_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_5_valid = $urandom_range(0, 1);
    io_msStatus_1_5_bits_channel = 3'($urandom);
    io_msStatus_1_5_bits_set = 9'($urandom);
    io_msStatus_1_5_bits_reqTag = 31'($urandom);
    io_msStatus_1_5_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_5_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_6_valid = $urandom_range(0, 1);
    io_msStatus_1_6_bits_channel = 3'($urandom);
    io_msStatus_1_6_bits_set = 9'($urandom);
    io_msStatus_1_6_bits_reqTag = 31'($urandom);
    io_msStatus_1_6_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_6_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_7_valid = $urandom_range(0, 1);
    io_msStatus_1_7_bits_channel = 3'($urandom);
    io_msStatus_1_7_bits_set = 9'($urandom);
    io_msStatus_1_7_bits_reqTag = 31'($urandom);
    io_msStatus_1_7_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_7_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_8_valid = $urandom_range(0, 1);
    io_msStatus_1_8_bits_channel = 3'($urandom);
    io_msStatus_1_8_bits_set = 9'($urandom);
    io_msStatus_1_8_bits_reqTag = 31'($urandom);
    io_msStatus_1_8_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_8_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_9_valid = $urandom_range(0, 1);
    io_msStatus_1_9_bits_channel = 3'($urandom);
    io_msStatus_1_9_bits_set = 9'($urandom);
    io_msStatus_1_9_bits_reqTag = 31'($urandom);
    io_msStatus_1_9_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_9_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_10_valid = $urandom_range(0, 1);
    io_msStatus_1_10_bits_channel = 3'($urandom);
    io_msStatus_1_10_bits_set = 9'($urandom);
    io_msStatus_1_10_bits_reqTag = 31'($urandom);
    io_msStatus_1_10_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_10_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_11_valid = $urandom_range(0, 1);
    io_msStatus_1_11_bits_channel = 3'($urandom);
    io_msStatus_1_11_bits_set = 9'($urandom);
    io_msStatus_1_11_bits_reqTag = 31'($urandom);
    io_msStatus_1_11_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_11_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_12_valid = $urandom_range(0, 1);
    io_msStatus_1_12_bits_channel = 3'($urandom);
    io_msStatus_1_12_bits_set = 9'($urandom);
    io_msStatus_1_12_bits_reqTag = 31'($urandom);
    io_msStatus_1_12_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_12_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_13_valid = $urandom_range(0, 1);
    io_msStatus_1_13_bits_channel = 3'($urandom);
    io_msStatus_1_13_bits_set = 9'($urandom);
    io_msStatus_1_13_bits_reqTag = 31'($urandom);
    io_msStatus_1_13_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_13_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_14_valid = $urandom_range(0, 1);
    io_msStatus_1_14_bits_channel = 3'($urandom);
    io_msStatus_1_14_bits_set = 9'($urandom);
    io_msStatus_1_14_bits_reqTag = 31'($urandom);
    io_msStatus_1_14_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_14_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_1_15_valid = $urandom_range(0, 1);
    io_msStatus_1_15_bits_channel = 3'($urandom);
    io_msStatus_1_15_bits_set = 9'($urandom);
    io_msStatus_1_15_bits_reqTag = 31'($urandom);
    io_msStatus_1_15_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_1_15_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_0_valid = $urandom_range(0, 1);
    io_msStatus_2_0_bits_channel = 3'($urandom);
    io_msStatus_2_0_bits_set = 9'($urandom);
    io_msStatus_2_0_bits_reqTag = 31'($urandom);
    io_msStatus_2_0_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_0_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_1_valid = $urandom_range(0, 1);
    io_msStatus_2_1_bits_channel = 3'($urandom);
    io_msStatus_2_1_bits_set = 9'($urandom);
    io_msStatus_2_1_bits_reqTag = 31'($urandom);
    io_msStatus_2_1_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_1_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_2_valid = $urandom_range(0, 1);
    io_msStatus_2_2_bits_channel = 3'($urandom);
    io_msStatus_2_2_bits_set = 9'($urandom);
    io_msStatus_2_2_bits_reqTag = 31'($urandom);
    io_msStatus_2_2_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_2_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_3_valid = $urandom_range(0, 1);
    io_msStatus_2_3_bits_channel = 3'($urandom);
    io_msStatus_2_3_bits_set = 9'($urandom);
    io_msStatus_2_3_bits_reqTag = 31'($urandom);
    io_msStatus_2_3_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_3_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_4_valid = $urandom_range(0, 1);
    io_msStatus_2_4_bits_channel = 3'($urandom);
    io_msStatus_2_4_bits_set = 9'($urandom);
    io_msStatus_2_4_bits_reqTag = 31'($urandom);
    io_msStatus_2_4_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_4_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_5_valid = $urandom_range(0, 1);
    io_msStatus_2_5_bits_channel = 3'($urandom);
    io_msStatus_2_5_bits_set = 9'($urandom);
    io_msStatus_2_5_bits_reqTag = 31'($urandom);
    io_msStatus_2_5_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_5_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_6_valid = $urandom_range(0, 1);
    io_msStatus_2_6_bits_channel = 3'($urandom);
    io_msStatus_2_6_bits_set = 9'($urandom);
    io_msStatus_2_6_bits_reqTag = 31'($urandom);
    io_msStatus_2_6_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_6_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_7_valid = $urandom_range(0, 1);
    io_msStatus_2_7_bits_channel = 3'($urandom);
    io_msStatus_2_7_bits_set = 9'($urandom);
    io_msStatus_2_7_bits_reqTag = 31'($urandom);
    io_msStatus_2_7_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_7_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_8_valid = $urandom_range(0, 1);
    io_msStatus_2_8_bits_channel = 3'($urandom);
    io_msStatus_2_8_bits_set = 9'($urandom);
    io_msStatus_2_8_bits_reqTag = 31'($urandom);
    io_msStatus_2_8_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_8_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_9_valid = $urandom_range(0, 1);
    io_msStatus_2_9_bits_channel = 3'($urandom);
    io_msStatus_2_9_bits_set = 9'($urandom);
    io_msStatus_2_9_bits_reqTag = 31'($urandom);
    io_msStatus_2_9_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_9_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_10_valid = $urandom_range(0, 1);
    io_msStatus_2_10_bits_channel = 3'($urandom);
    io_msStatus_2_10_bits_set = 9'($urandom);
    io_msStatus_2_10_bits_reqTag = 31'($urandom);
    io_msStatus_2_10_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_10_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_11_valid = $urandom_range(0, 1);
    io_msStatus_2_11_bits_channel = 3'($urandom);
    io_msStatus_2_11_bits_set = 9'($urandom);
    io_msStatus_2_11_bits_reqTag = 31'($urandom);
    io_msStatus_2_11_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_11_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_12_valid = $urandom_range(0, 1);
    io_msStatus_2_12_bits_channel = 3'($urandom);
    io_msStatus_2_12_bits_set = 9'($urandom);
    io_msStatus_2_12_bits_reqTag = 31'($urandom);
    io_msStatus_2_12_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_12_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_13_valid = $urandom_range(0, 1);
    io_msStatus_2_13_bits_channel = 3'($urandom);
    io_msStatus_2_13_bits_set = 9'($urandom);
    io_msStatus_2_13_bits_reqTag = 31'($urandom);
    io_msStatus_2_13_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_13_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_14_valid = $urandom_range(0, 1);
    io_msStatus_2_14_bits_channel = 3'($urandom);
    io_msStatus_2_14_bits_set = 9'($urandom);
    io_msStatus_2_14_bits_reqTag = 31'($urandom);
    io_msStatus_2_14_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_14_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_2_15_valid = $urandom_range(0, 1);
    io_msStatus_2_15_bits_channel = 3'($urandom);
    io_msStatus_2_15_bits_set = 9'($urandom);
    io_msStatus_2_15_bits_reqTag = 31'($urandom);
    io_msStatus_2_15_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_2_15_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_0_valid = $urandom_range(0, 1);
    io_msStatus_3_0_bits_channel = 3'($urandom);
    io_msStatus_3_0_bits_set = 9'($urandom);
    io_msStatus_3_0_bits_reqTag = 31'($urandom);
    io_msStatus_3_0_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_0_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_1_valid = $urandom_range(0, 1);
    io_msStatus_3_1_bits_channel = 3'($urandom);
    io_msStatus_3_1_bits_set = 9'($urandom);
    io_msStatus_3_1_bits_reqTag = 31'($urandom);
    io_msStatus_3_1_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_1_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_2_valid = $urandom_range(0, 1);
    io_msStatus_3_2_bits_channel = 3'($urandom);
    io_msStatus_3_2_bits_set = 9'($urandom);
    io_msStatus_3_2_bits_reqTag = 31'($urandom);
    io_msStatus_3_2_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_2_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_3_valid = $urandom_range(0, 1);
    io_msStatus_3_3_bits_channel = 3'($urandom);
    io_msStatus_3_3_bits_set = 9'($urandom);
    io_msStatus_3_3_bits_reqTag = 31'($urandom);
    io_msStatus_3_3_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_3_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_4_valid = $urandom_range(0, 1);
    io_msStatus_3_4_bits_channel = 3'($urandom);
    io_msStatus_3_4_bits_set = 9'($urandom);
    io_msStatus_3_4_bits_reqTag = 31'($urandom);
    io_msStatus_3_4_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_4_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_5_valid = $urandom_range(0, 1);
    io_msStatus_3_5_bits_channel = 3'($urandom);
    io_msStatus_3_5_bits_set = 9'($urandom);
    io_msStatus_3_5_bits_reqTag = 31'($urandom);
    io_msStatus_3_5_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_5_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_6_valid = $urandom_range(0, 1);
    io_msStatus_3_6_bits_channel = 3'($urandom);
    io_msStatus_3_6_bits_set = 9'($urandom);
    io_msStatus_3_6_bits_reqTag = 31'($urandom);
    io_msStatus_3_6_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_6_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_7_valid = $urandom_range(0, 1);
    io_msStatus_3_7_bits_channel = 3'($urandom);
    io_msStatus_3_7_bits_set = 9'($urandom);
    io_msStatus_3_7_bits_reqTag = 31'($urandom);
    io_msStatus_3_7_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_7_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_8_valid = $urandom_range(0, 1);
    io_msStatus_3_8_bits_channel = 3'($urandom);
    io_msStatus_3_8_bits_set = 9'($urandom);
    io_msStatus_3_8_bits_reqTag = 31'($urandom);
    io_msStatus_3_8_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_8_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_9_valid = $urandom_range(0, 1);
    io_msStatus_3_9_bits_channel = 3'($urandom);
    io_msStatus_3_9_bits_set = 9'($urandom);
    io_msStatus_3_9_bits_reqTag = 31'($urandom);
    io_msStatus_3_9_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_9_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_10_valid = $urandom_range(0, 1);
    io_msStatus_3_10_bits_channel = 3'($urandom);
    io_msStatus_3_10_bits_set = 9'($urandom);
    io_msStatus_3_10_bits_reqTag = 31'($urandom);
    io_msStatus_3_10_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_10_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_11_valid = $urandom_range(0, 1);
    io_msStatus_3_11_bits_channel = 3'($urandom);
    io_msStatus_3_11_bits_set = 9'($urandom);
    io_msStatus_3_11_bits_reqTag = 31'($urandom);
    io_msStatus_3_11_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_11_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_12_valid = $urandom_range(0, 1);
    io_msStatus_3_12_bits_channel = 3'($urandom);
    io_msStatus_3_12_bits_set = 9'($urandom);
    io_msStatus_3_12_bits_reqTag = 31'($urandom);
    io_msStatus_3_12_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_12_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_13_valid = $urandom_range(0, 1);
    io_msStatus_3_13_bits_channel = 3'($urandom);
    io_msStatus_3_13_bits_set = 9'($urandom);
    io_msStatus_3_13_bits_reqTag = 31'($urandom);
    io_msStatus_3_13_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_13_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_14_valid = $urandom_range(0, 1);
    io_msStatus_3_14_bits_channel = 3'($urandom);
    io_msStatus_3_14_bits_set = 9'($urandom);
    io_msStatus_3_14_bits_reqTag = 31'($urandom);
    io_msStatus_3_14_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_14_bits_is_prefetch = $urandom_range(0, 1);
    io_msStatus_3_15_valid = $urandom_range(0, 1);
    io_msStatus_3_15_bits_channel = 3'($urandom);
    io_msStatus_3_15_bits_set = 9'($urandom);
    io_msStatus_3_15_bits_reqTag = 31'($urandom);
    io_msStatus_3_15_bits_is_miss = $urandom_range(0, 1);
    io_msStatus_3_15_bits_is_prefetch = $urandom_range(0, 1);
    io_latePF_0 = $urandom_range(0, 1);
    io_latePF_1 = $urandom_range(0, 1);
    io_latePF_2 = $urandom_range(0, 1);
    io_latePF_3 = $urandom_range(0, 1);
    io_debugTopDown_robHeadPaddr_valid = $urandom_range(0, 1);
    io_debugTopDown_robHeadPaddr_bits = 36'($urandom);
    // 约束: 让 reqTag/set 与 robHeadPaddr 落在小域, 提高 match 命中率
    io_debugTopDown_robHeadPaddr_bits = 36'($urandom_range(0, 255)) << 6;
    io_msStatus_0_0_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_0_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_1_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_1_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_2_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_2_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_3_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_3_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_4_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_4_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_5_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_5_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_6_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_6_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_7_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_7_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_8_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_8_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_9_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_9_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_10_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_10_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_11_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_11_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_12_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_12_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_13_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_13_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_14_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_14_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_0_15_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_0_15_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_0_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_0_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_1_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_1_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_2_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_2_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_3_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_3_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_4_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_4_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_5_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_5_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_6_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_6_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_7_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_7_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_8_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_8_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_9_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_9_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_10_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_10_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_11_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_11_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_12_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_12_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_13_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_13_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_14_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_14_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_1_15_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_1_15_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_0_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_0_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_1_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_1_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_2_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_2_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_3_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_3_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_4_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_4_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_5_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_5_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_6_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_6_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_7_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_7_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_8_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_8_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_9_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_9_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_10_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_10_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_11_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_11_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_12_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_12_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_13_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_13_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_14_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_14_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_2_15_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_2_15_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_0_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_0_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_1_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_1_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_2_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_2_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_3_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_3_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_4_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_4_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_5_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_5_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_6_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_6_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_7_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_7_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_8_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_8_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_9_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_9_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_10_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_10_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_11_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_11_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_12_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_12_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_13_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_13_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_14_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_14_bits_set = 9'($urandom_range(0, 15));
    io_msStatus_3_15_bits_reqTag = 31'($urandom_range(0, 3));
    io_msStatus_3_15_bits_set = 9'($urandom_range(0, 15));
  endtask
  task automatic check_outputs();
    `CHECK(io_debugTopDown_l2MissMatch)
  endtask
  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    io_dirResult_0_valid = '0;
    io_dirResult_0_bits_hit = '0;
    io_dirResult_0_bits_meta_prefetch = '0;
    io_dirResult_0_bits_meta_prefetchSrc = '0;
    io_dirResult_0_bits_replacerInfo_channel = '0;
    io_dirResult_0_bits_replacerInfo_reqSource = '0;
    io_dirResult_1_valid = '0;
    io_dirResult_1_bits_hit = '0;
    io_dirResult_1_bits_meta_prefetch = '0;
    io_dirResult_1_bits_meta_prefetchSrc = '0;
    io_dirResult_1_bits_replacerInfo_channel = '0;
    io_dirResult_1_bits_replacerInfo_reqSource = '0;
    io_dirResult_2_valid = '0;
    io_dirResult_2_bits_hit = '0;
    io_dirResult_2_bits_meta_prefetch = '0;
    io_dirResult_2_bits_meta_prefetchSrc = '0;
    io_dirResult_2_bits_replacerInfo_channel = '0;
    io_dirResult_2_bits_replacerInfo_reqSource = '0;
    io_dirResult_3_valid = '0;
    io_dirResult_3_bits_hit = '0;
    io_dirResult_3_bits_meta_prefetch = '0;
    io_dirResult_3_bits_meta_prefetchSrc = '0;
    io_dirResult_3_bits_replacerInfo_channel = '0;
    io_dirResult_3_bits_replacerInfo_reqSource = '0;
    io_msStatus_0_0_valid = '0;
    io_msStatus_0_0_bits_channel = '0;
    io_msStatus_0_0_bits_set = '0;
    io_msStatus_0_0_bits_reqTag = '0;
    io_msStatus_0_0_bits_is_miss = '0;
    io_msStatus_0_0_bits_is_prefetch = '0;
    io_msStatus_0_1_valid = '0;
    io_msStatus_0_1_bits_channel = '0;
    io_msStatus_0_1_bits_set = '0;
    io_msStatus_0_1_bits_reqTag = '0;
    io_msStatus_0_1_bits_is_miss = '0;
    io_msStatus_0_1_bits_is_prefetch = '0;
    io_msStatus_0_2_valid = '0;
    io_msStatus_0_2_bits_channel = '0;
    io_msStatus_0_2_bits_set = '0;
    io_msStatus_0_2_bits_reqTag = '0;
    io_msStatus_0_2_bits_is_miss = '0;
    io_msStatus_0_2_bits_is_prefetch = '0;
    io_msStatus_0_3_valid = '0;
    io_msStatus_0_3_bits_channel = '0;
    io_msStatus_0_3_bits_set = '0;
    io_msStatus_0_3_bits_reqTag = '0;
    io_msStatus_0_3_bits_is_miss = '0;
    io_msStatus_0_3_bits_is_prefetch = '0;
    io_msStatus_0_4_valid = '0;
    io_msStatus_0_4_bits_channel = '0;
    io_msStatus_0_4_bits_set = '0;
    io_msStatus_0_4_bits_reqTag = '0;
    io_msStatus_0_4_bits_is_miss = '0;
    io_msStatus_0_4_bits_is_prefetch = '0;
    io_msStatus_0_5_valid = '0;
    io_msStatus_0_5_bits_channel = '0;
    io_msStatus_0_5_bits_set = '0;
    io_msStatus_0_5_bits_reqTag = '0;
    io_msStatus_0_5_bits_is_miss = '0;
    io_msStatus_0_5_bits_is_prefetch = '0;
    io_msStatus_0_6_valid = '0;
    io_msStatus_0_6_bits_channel = '0;
    io_msStatus_0_6_bits_set = '0;
    io_msStatus_0_6_bits_reqTag = '0;
    io_msStatus_0_6_bits_is_miss = '0;
    io_msStatus_0_6_bits_is_prefetch = '0;
    io_msStatus_0_7_valid = '0;
    io_msStatus_0_7_bits_channel = '0;
    io_msStatus_0_7_bits_set = '0;
    io_msStatus_0_7_bits_reqTag = '0;
    io_msStatus_0_7_bits_is_miss = '0;
    io_msStatus_0_7_bits_is_prefetch = '0;
    io_msStatus_0_8_valid = '0;
    io_msStatus_0_8_bits_channel = '0;
    io_msStatus_0_8_bits_set = '0;
    io_msStatus_0_8_bits_reqTag = '0;
    io_msStatus_0_8_bits_is_miss = '0;
    io_msStatus_0_8_bits_is_prefetch = '0;
    io_msStatus_0_9_valid = '0;
    io_msStatus_0_9_bits_channel = '0;
    io_msStatus_0_9_bits_set = '0;
    io_msStatus_0_9_bits_reqTag = '0;
    io_msStatus_0_9_bits_is_miss = '0;
    io_msStatus_0_9_bits_is_prefetch = '0;
    io_msStatus_0_10_valid = '0;
    io_msStatus_0_10_bits_channel = '0;
    io_msStatus_0_10_bits_set = '0;
    io_msStatus_0_10_bits_reqTag = '0;
    io_msStatus_0_10_bits_is_miss = '0;
    io_msStatus_0_10_bits_is_prefetch = '0;
    io_msStatus_0_11_valid = '0;
    io_msStatus_0_11_bits_channel = '0;
    io_msStatus_0_11_bits_set = '0;
    io_msStatus_0_11_bits_reqTag = '0;
    io_msStatus_0_11_bits_is_miss = '0;
    io_msStatus_0_11_bits_is_prefetch = '0;
    io_msStatus_0_12_valid = '0;
    io_msStatus_0_12_bits_channel = '0;
    io_msStatus_0_12_bits_set = '0;
    io_msStatus_0_12_bits_reqTag = '0;
    io_msStatus_0_12_bits_is_miss = '0;
    io_msStatus_0_12_bits_is_prefetch = '0;
    io_msStatus_0_13_valid = '0;
    io_msStatus_0_13_bits_channel = '0;
    io_msStatus_0_13_bits_set = '0;
    io_msStatus_0_13_bits_reqTag = '0;
    io_msStatus_0_13_bits_is_miss = '0;
    io_msStatus_0_13_bits_is_prefetch = '0;
    io_msStatus_0_14_valid = '0;
    io_msStatus_0_14_bits_channel = '0;
    io_msStatus_0_14_bits_set = '0;
    io_msStatus_0_14_bits_reqTag = '0;
    io_msStatus_0_14_bits_is_miss = '0;
    io_msStatus_0_14_bits_is_prefetch = '0;
    io_msStatus_0_15_valid = '0;
    io_msStatus_0_15_bits_channel = '0;
    io_msStatus_0_15_bits_set = '0;
    io_msStatus_0_15_bits_reqTag = '0;
    io_msStatus_0_15_bits_is_miss = '0;
    io_msStatus_0_15_bits_is_prefetch = '0;
    io_msStatus_1_0_valid = '0;
    io_msStatus_1_0_bits_channel = '0;
    io_msStatus_1_0_bits_set = '0;
    io_msStatus_1_0_bits_reqTag = '0;
    io_msStatus_1_0_bits_is_miss = '0;
    io_msStatus_1_0_bits_is_prefetch = '0;
    io_msStatus_1_1_valid = '0;
    io_msStatus_1_1_bits_channel = '0;
    io_msStatus_1_1_bits_set = '0;
    io_msStatus_1_1_bits_reqTag = '0;
    io_msStatus_1_1_bits_is_miss = '0;
    io_msStatus_1_1_bits_is_prefetch = '0;
    io_msStatus_1_2_valid = '0;
    io_msStatus_1_2_bits_channel = '0;
    io_msStatus_1_2_bits_set = '0;
    io_msStatus_1_2_bits_reqTag = '0;
    io_msStatus_1_2_bits_is_miss = '0;
    io_msStatus_1_2_bits_is_prefetch = '0;
    io_msStatus_1_3_valid = '0;
    io_msStatus_1_3_bits_channel = '0;
    io_msStatus_1_3_bits_set = '0;
    io_msStatus_1_3_bits_reqTag = '0;
    io_msStatus_1_3_bits_is_miss = '0;
    io_msStatus_1_3_bits_is_prefetch = '0;
    io_msStatus_1_4_valid = '0;
    io_msStatus_1_4_bits_channel = '0;
    io_msStatus_1_4_bits_set = '0;
    io_msStatus_1_4_bits_reqTag = '0;
    io_msStatus_1_4_bits_is_miss = '0;
    io_msStatus_1_4_bits_is_prefetch = '0;
    io_msStatus_1_5_valid = '0;
    io_msStatus_1_5_bits_channel = '0;
    io_msStatus_1_5_bits_set = '0;
    io_msStatus_1_5_bits_reqTag = '0;
    io_msStatus_1_5_bits_is_miss = '0;
    io_msStatus_1_5_bits_is_prefetch = '0;
    io_msStatus_1_6_valid = '0;
    io_msStatus_1_6_bits_channel = '0;
    io_msStatus_1_6_bits_set = '0;
    io_msStatus_1_6_bits_reqTag = '0;
    io_msStatus_1_6_bits_is_miss = '0;
    io_msStatus_1_6_bits_is_prefetch = '0;
    io_msStatus_1_7_valid = '0;
    io_msStatus_1_7_bits_channel = '0;
    io_msStatus_1_7_bits_set = '0;
    io_msStatus_1_7_bits_reqTag = '0;
    io_msStatus_1_7_bits_is_miss = '0;
    io_msStatus_1_7_bits_is_prefetch = '0;
    io_msStatus_1_8_valid = '0;
    io_msStatus_1_8_bits_channel = '0;
    io_msStatus_1_8_bits_set = '0;
    io_msStatus_1_8_bits_reqTag = '0;
    io_msStatus_1_8_bits_is_miss = '0;
    io_msStatus_1_8_bits_is_prefetch = '0;
    io_msStatus_1_9_valid = '0;
    io_msStatus_1_9_bits_channel = '0;
    io_msStatus_1_9_bits_set = '0;
    io_msStatus_1_9_bits_reqTag = '0;
    io_msStatus_1_9_bits_is_miss = '0;
    io_msStatus_1_9_bits_is_prefetch = '0;
    io_msStatus_1_10_valid = '0;
    io_msStatus_1_10_bits_channel = '0;
    io_msStatus_1_10_bits_set = '0;
    io_msStatus_1_10_bits_reqTag = '0;
    io_msStatus_1_10_bits_is_miss = '0;
    io_msStatus_1_10_bits_is_prefetch = '0;
    io_msStatus_1_11_valid = '0;
    io_msStatus_1_11_bits_channel = '0;
    io_msStatus_1_11_bits_set = '0;
    io_msStatus_1_11_bits_reqTag = '0;
    io_msStatus_1_11_bits_is_miss = '0;
    io_msStatus_1_11_bits_is_prefetch = '0;
    io_msStatus_1_12_valid = '0;
    io_msStatus_1_12_bits_channel = '0;
    io_msStatus_1_12_bits_set = '0;
    io_msStatus_1_12_bits_reqTag = '0;
    io_msStatus_1_12_bits_is_miss = '0;
    io_msStatus_1_12_bits_is_prefetch = '0;
    io_msStatus_1_13_valid = '0;
    io_msStatus_1_13_bits_channel = '0;
    io_msStatus_1_13_bits_set = '0;
    io_msStatus_1_13_bits_reqTag = '0;
    io_msStatus_1_13_bits_is_miss = '0;
    io_msStatus_1_13_bits_is_prefetch = '0;
    io_msStatus_1_14_valid = '0;
    io_msStatus_1_14_bits_channel = '0;
    io_msStatus_1_14_bits_set = '0;
    io_msStatus_1_14_bits_reqTag = '0;
    io_msStatus_1_14_bits_is_miss = '0;
    io_msStatus_1_14_bits_is_prefetch = '0;
    io_msStatus_1_15_valid = '0;
    io_msStatus_1_15_bits_channel = '0;
    io_msStatus_1_15_bits_set = '0;
    io_msStatus_1_15_bits_reqTag = '0;
    io_msStatus_1_15_bits_is_miss = '0;
    io_msStatus_1_15_bits_is_prefetch = '0;
    io_msStatus_2_0_valid = '0;
    io_msStatus_2_0_bits_channel = '0;
    io_msStatus_2_0_bits_set = '0;
    io_msStatus_2_0_bits_reqTag = '0;
    io_msStatus_2_0_bits_is_miss = '0;
    io_msStatus_2_0_bits_is_prefetch = '0;
    io_msStatus_2_1_valid = '0;
    io_msStatus_2_1_bits_channel = '0;
    io_msStatus_2_1_bits_set = '0;
    io_msStatus_2_1_bits_reqTag = '0;
    io_msStatus_2_1_bits_is_miss = '0;
    io_msStatus_2_1_bits_is_prefetch = '0;
    io_msStatus_2_2_valid = '0;
    io_msStatus_2_2_bits_channel = '0;
    io_msStatus_2_2_bits_set = '0;
    io_msStatus_2_2_bits_reqTag = '0;
    io_msStatus_2_2_bits_is_miss = '0;
    io_msStatus_2_2_bits_is_prefetch = '0;
    io_msStatus_2_3_valid = '0;
    io_msStatus_2_3_bits_channel = '0;
    io_msStatus_2_3_bits_set = '0;
    io_msStatus_2_3_bits_reqTag = '0;
    io_msStatus_2_3_bits_is_miss = '0;
    io_msStatus_2_3_bits_is_prefetch = '0;
    io_msStatus_2_4_valid = '0;
    io_msStatus_2_4_bits_channel = '0;
    io_msStatus_2_4_bits_set = '0;
    io_msStatus_2_4_bits_reqTag = '0;
    io_msStatus_2_4_bits_is_miss = '0;
    io_msStatus_2_4_bits_is_prefetch = '0;
    io_msStatus_2_5_valid = '0;
    io_msStatus_2_5_bits_channel = '0;
    io_msStatus_2_5_bits_set = '0;
    io_msStatus_2_5_bits_reqTag = '0;
    io_msStatus_2_5_bits_is_miss = '0;
    io_msStatus_2_5_bits_is_prefetch = '0;
    io_msStatus_2_6_valid = '0;
    io_msStatus_2_6_bits_channel = '0;
    io_msStatus_2_6_bits_set = '0;
    io_msStatus_2_6_bits_reqTag = '0;
    io_msStatus_2_6_bits_is_miss = '0;
    io_msStatus_2_6_bits_is_prefetch = '0;
    io_msStatus_2_7_valid = '0;
    io_msStatus_2_7_bits_channel = '0;
    io_msStatus_2_7_bits_set = '0;
    io_msStatus_2_7_bits_reqTag = '0;
    io_msStatus_2_7_bits_is_miss = '0;
    io_msStatus_2_7_bits_is_prefetch = '0;
    io_msStatus_2_8_valid = '0;
    io_msStatus_2_8_bits_channel = '0;
    io_msStatus_2_8_bits_set = '0;
    io_msStatus_2_8_bits_reqTag = '0;
    io_msStatus_2_8_bits_is_miss = '0;
    io_msStatus_2_8_bits_is_prefetch = '0;
    io_msStatus_2_9_valid = '0;
    io_msStatus_2_9_bits_channel = '0;
    io_msStatus_2_9_bits_set = '0;
    io_msStatus_2_9_bits_reqTag = '0;
    io_msStatus_2_9_bits_is_miss = '0;
    io_msStatus_2_9_bits_is_prefetch = '0;
    io_msStatus_2_10_valid = '0;
    io_msStatus_2_10_bits_channel = '0;
    io_msStatus_2_10_bits_set = '0;
    io_msStatus_2_10_bits_reqTag = '0;
    io_msStatus_2_10_bits_is_miss = '0;
    io_msStatus_2_10_bits_is_prefetch = '0;
    io_msStatus_2_11_valid = '0;
    io_msStatus_2_11_bits_channel = '0;
    io_msStatus_2_11_bits_set = '0;
    io_msStatus_2_11_bits_reqTag = '0;
    io_msStatus_2_11_bits_is_miss = '0;
    io_msStatus_2_11_bits_is_prefetch = '0;
    io_msStatus_2_12_valid = '0;
    io_msStatus_2_12_bits_channel = '0;
    io_msStatus_2_12_bits_set = '0;
    io_msStatus_2_12_bits_reqTag = '0;
    io_msStatus_2_12_bits_is_miss = '0;
    io_msStatus_2_12_bits_is_prefetch = '0;
    io_msStatus_2_13_valid = '0;
    io_msStatus_2_13_bits_channel = '0;
    io_msStatus_2_13_bits_set = '0;
    io_msStatus_2_13_bits_reqTag = '0;
    io_msStatus_2_13_bits_is_miss = '0;
    io_msStatus_2_13_bits_is_prefetch = '0;
    io_msStatus_2_14_valid = '0;
    io_msStatus_2_14_bits_channel = '0;
    io_msStatus_2_14_bits_set = '0;
    io_msStatus_2_14_bits_reqTag = '0;
    io_msStatus_2_14_bits_is_miss = '0;
    io_msStatus_2_14_bits_is_prefetch = '0;
    io_msStatus_2_15_valid = '0;
    io_msStatus_2_15_bits_channel = '0;
    io_msStatus_2_15_bits_set = '0;
    io_msStatus_2_15_bits_reqTag = '0;
    io_msStatus_2_15_bits_is_miss = '0;
    io_msStatus_2_15_bits_is_prefetch = '0;
    io_msStatus_3_0_valid = '0;
    io_msStatus_3_0_bits_channel = '0;
    io_msStatus_3_0_bits_set = '0;
    io_msStatus_3_0_bits_reqTag = '0;
    io_msStatus_3_0_bits_is_miss = '0;
    io_msStatus_3_0_bits_is_prefetch = '0;
    io_msStatus_3_1_valid = '0;
    io_msStatus_3_1_bits_channel = '0;
    io_msStatus_3_1_bits_set = '0;
    io_msStatus_3_1_bits_reqTag = '0;
    io_msStatus_3_1_bits_is_miss = '0;
    io_msStatus_3_1_bits_is_prefetch = '0;
    io_msStatus_3_2_valid = '0;
    io_msStatus_3_2_bits_channel = '0;
    io_msStatus_3_2_bits_set = '0;
    io_msStatus_3_2_bits_reqTag = '0;
    io_msStatus_3_2_bits_is_miss = '0;
    io_msStatus_3_2_bits_is_prefetch = '0;
    io_msStatus_3_3_valid = '0;
    io_msStatus_3_3_bits_channel = '0;
    io_msStatus_3_3_bits_set = '0;
    io_msStatus_3_3_bits_reqTag = '0;
    io_msStatus_3_3_bits_is_miss = '0;
    io_msStatus_3_3_bits_is_prefetch = '0;
    io_msStatus_3_4_valid = '0;
    io_msStatus_3_4_bits_channel = '0;
    io_msStatus_3_4_bits_set = '0;
    io_msStatus_3_4_bits_reqTag = '0;
    io_msStatus_3_4_bits_is_miss = '0;
    io_msStatus_3_4_bits_is_prefetch = '0;
    io_msStatus_3_5_valid = '0;
    io_msStatus_3_5_bits_channel = '0;
    io_msStatus_3_5_bits_set = '0;
    io_msStatus_3_5_bits_reqTag = '0;
    io_msStatus_3_5_bits_is_miss = '0;
    io_msStatus_3_5_bits_is_prefetch = '0;
    io_msStatus_3_6_valid = '0;
    io_msStatus_3_6_bits_channel = '0;
    io_msStatus_3_6_bits_set = '0;
    io_msStatus_3_6_bits_reqTag = '0;
    io_msStatus_3_6_bits_is_miss = '0;
    io_msStatus_3_6_bits_is_prefetch = '0;
    io_msStatus_3_7_valid = '0;
    io_msStatus_3_7_bits_channel = '0;
    io_msStatus_3_7_bits_set = '0;
    io_msStatus_3_7_bits_reqTag = '0;
    io_msStatus_3_7_bits_is_miss = '0;
    io_msStatus_3_7_bits_is_prefetch = '0;
    io_msStatus_3_8_valid = '0;
    io_msStatus_3_8_bits_channel = '0;
    io_msStatus_3_8_bits_set = '0;
    io_msStatus_3_8_bits_reqTag = '0;
    io_msStatus_3_8_bits_is_miss = '0;
    io_msStatus_3_8_bits_is_prefetch = '0;
    io_msStatus_3_9_valid = '0;
    io_msStatus_3_9_bits_channel = '0;
    io_msStatus_3_9_bits_set = '0;
    io_msStatus_3_9_bits_reqTag = '0;
    io_msStatus_3_9_bits_is_miss = '0;
    io_msStatus_3_9_bits_is_prefetch = '0;
    io_msStatus_3_10_valid = '0;
    io_msStatus_3_10_bits_channel = '0;
    io_msStatus_3_10_bits_set = '0;
    io_msStatus_3_10_bits_reqTag = '0;
    io_msStatus_3_10_bits_is_miss = '0;
    io_msStatus_3_10_bits_is_prefetch = '0;
    io_msStatus_3_11_valid = '0;
    io_msStatus_3_11_bits_channel = '0;
    io_msStatus_3_11_bits_set = '0;
    io_msStatus_3_11_bits_reqTag = '0;
    io_msStatus_3_11_bits_is_miss = '0;
    io_msStatus_3_11_bits_is_prefetch = '0;
    io_msStatus_3_12_valid = '0;
    io_msStatus_3_12_bits_channel = '0;
    io_msStatus_3_12_bits_set = '0;
    io_msStatus_3_12_bits_reqTag = '0;
    io_msStatus_3_12_bits_is_miss = '0;
    io_msStatus_3_12_bits_is_prefetch = '0;
    io_msStatus_3_13_valid = '0;
    io_msStatus_3_13_bits_channel = '0;
    io_msStatus_3_13_bits_set = '0;
    io_msStatus_3_13_bits_reqTag = '0;
    io_msStatus_3_13_bits_is_miss = '0;
    io_msStatus_3_13_bits_is_prefetch = '0;
    io_msStatus_3_14_valid = '0;
    io_msStatus_3_14_bits_channel = '0;
    io_msStatus_3_14_bits_set = '0;
    io_msStatus_3_14_bits_reqTag = '0;
    io_msStatus_3_14_bits_is_miss = '0;
    io_msStatus_3_14_bits_is_prefetch = '0;
    io_msStatus_3_15_valid = '0;
    io_msStatus_3_15_bits_channel = '0;
    io_msStatus_3_15_bits_set = '0;
    io_msStatus_3_15_bits_reqTag = '0;
    io_msStatus_3_15_bits_is_miss = '0;
    io_msStatus_3_15_bits_is_prefetch = '0;
    io_latePF_0 = '0;
    io_latePF_1 = '0;
    io_latePF_2 = '0;
    io_latePF_3 = '0;
    io_debugTopDown_robHeadPaddr_valid = '0;
    io_debugTopDown_robHeadPaddr_bits = '0;
    repeat (2) @(posedge clock);
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
    end
    $display("TopDownMonitor checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
