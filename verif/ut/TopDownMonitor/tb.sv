// =============================================================================
// tb —— TopDownMonitor UT（自动生成：scripts/gen_topdownmonitor.py，勿手改）
// golden TopDownMonitor 与重写件 TopDownMonitor_xs 双例化，纯组合，每拍一组新输入，比 l2MissMatch。
// 激励：所有输入每拍随机；另外按拍轮换四种定向形状，让命中/不命中两边都被打到：
//   0 全随机（几乎不命中）；1 挑一个 (bank, mshr)，把 reqTag 高 12 位清 0、令其块地址 == ROB 头块地址
//   （valid/is_miss/robHead.valid 随机，命中与"差一个条件"都会出现）；2 同 1 但 bank 号错位（地址差在低 2 位）；
//   3 同 1 但 reqTag 高 12 位置非 0（golden 的位宽怪癖：永远不命中）。
// 覆盖（写进 PASS 判据）：命中 >= 20000 拍，且 64 个 (bank, mshr) 位置各自作为命中者 >= 100 次。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  logic [0:0] io_dirResult_0_valid;
  logic [0:0] io_dirResult_0_bits_hit;
  logic [0:0] io_dirResult_0_bits_meta_prefetch;
  logic [2:0] io_dirResult_0_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_0_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_0_bits_replacerInfo_reqSource;
  logic [0:0] io_dirResult_1_valid;
  logic [0:0] io_dirResult_1_bits_hit;
  logic [0:0] io_dirResult_1_bits_meta_prefetch;
  logic [2:0] io_dirResult_1_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_1_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_1_bits_replacerInfo_reqSource;
  logic [0:0] io_dirResult_2_valid;
  logic [0:0] io_dirResult_2_bits_hit;
  logic [0:0] io_dirResult_2_bits_meta_prefetch;
  logic [2:0] io_dirResult_2_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_2_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_2_bits_replacerInfo_reqSource;
  logic [0:0] io_dirResult_3_valid;
  logic [0:0] io_dirResult_3_bits_hit;
  logic [0:0] io_dirResult_3_bits_meta_prefetch;
  logic [2:0] io_dirResult_3_bits_meta_prefetchSrc;
  logic [2:0] io_dirResult_3_bits_replacerInfo_channel;
  logic [4:0] io_dirResult_3_bits_replacerInfo_reqSource;
  logic [0:0] io_msStatus_0_0_valid;
  logic [2:0] io_msStatus_0_0_bits_channel;
  logic [8:0] io_msStatus_0_0_bits_set;
  logic [30:0] io_msStatus_0_0_bits_reqTag;
  logic [0:0] io_msStatus_0_0_bits_is_miss;
  logic [0:0] io_msStatus_0_0_bits_is_prefetch;
  logic [0:0] io_msStatus_0_1_valid;
  logic [2:0] io_msStatus_0_1_bits_channel;
  logic [8:0] io_msStatus_0_1_bits_set;
  logic [30:0] io_msStatus_0_1_bits_reqTag;
  logic [0:0] io_msStatus_0_1_bits_is_miss;
  logic [0:0] io_msStatus_0_1_bits_is_prefetch;
  logic [0:0] io_msStatus_0_2_valid;
  logic [2:0] io_msStatus_0_2_bits_channel;
  logic [8:0] io_msStatus_0_2_bits_set;
  logic [30:0] io_msStatus_0_2_bits_reqTag;
  logic [0:0] io_msStatus_0_2_bits_is_miss;
  logic [0:0] io_msStatus_0_2_bits_is_prefetch;
  logic [0:0] io_msStatus_0_3_valid;
  logic [2:0] io_msStatus_0_3_bits_channel;
  logic [8:0] io_msStatus_0_3_bits_set;
  logic [30:0] io_msStatus_0_3_bits_reqTag;
  logic [0:0] io_msStatus_0_3_bits_is_miss;
  logic [0:0] io_msStatus_0_3_bits_is_prefetch;
  logic [0:0] io_msStatus_0_4_valid;
  logic [2:0] io_msStatus_0_4_bits_channel;
  logic [8:0] io_msStatus_0_4_bits_set;
  logic [30:0] io_msStatus_0_4_bits_reqTag;
  logic [0:0] io_msStatus_0_4_bits_is_miss;
  logic [0:0] io_msStatus_0_4_bits_is_prefetch;
  logic [0:0] io_msStatus_0_5_valid;
  logic [2:0] io_msStatus_0_5_bits_channel;
  logic [8:0] io_msStatus_0_5_bits_set;
  logic [30:0] io_msStatus_0_5_bits_reqTag;
  logic [0:0] io_msStatus_0_5_bits_is_miss;
  logic [0:0] io_msStatus_0_5_bits_is_prefetch;
  logic [0:0] io_msStatus_0_6_valid;
  logic [2:0] io_msStatus_0_6_bits_channel;
  logic [8:0] io_msStatus_0_6_bits_set;
  logic [30:0] io_msStatus_0_6_bits_reqTag;
  logic [0:0] io_msStatus_0_6_bits_is_miss;
  logic [0:0] io_msStatus_0_6_bits_is_prefetch;
  logic [0:0] io_msStatus_0_7_valid;
  logic [2:0] io_msStatus_0_7_bits_channel;
  logic [8:0] io_msStatus_0_7_bits_set;
  logic [30:0] io_msStatus_0_7_bits_reqTag;
  logic [0:0] io_msStatus_0_7_bits_is_miss;
  logic [0:0] io_msStatus_0_7_bits_is_prefetch;
  logic [0:0] io_msStatus_0_8_valid;
  logic [2:0] io_msStatus_0_8_bits_channel;
  logic [8:0] io_msStatus_0_8_bits_set;
  logic [30:0] io_msStatus_0_8_bits_reqTag;
  logic [0:0] io_msStatus_0_8_bits_is_miss;
  logic [0:0] io_msStatus_0_8_bits_is_prefetch;
  logic [0:0] io_msStatus_0_9_valid;
  logic [2:0] io_msStatus_0_9_bits_channel;
  logic [8:0] io_msStatus_0_9_bits_set;
  logic [30:0] io_msStatus_0_9_bits_reqTag;
  logic [0:0] io_msStatus_0_9_bits_is_miss;
  logic [0:0] io_msStatus_0_9_bits_is_prefetch;
  logic [0:0] io_msStatus_0_10_valid;
  logic [2:0] io_msStatus_0_10_bits_channel;
  logic [8:0] io_msStatus_0_10_bits_set;
  logic [30:0] io_msStatus_0_10_bits_reqTag;
  logic [0:0] io_msStatus_0_10_bits_is_miss;
  logic [0:0] io_msStatus_0_10_bits_is_prefetch;
  logic [0:0] io_msStatus_0_11_valid;
  logic [2:0] io_msStatus_0_11_bits_channel;
  logic [8:0] io_msStatus_0_11_bits_set;
  logic [30:0] io_msStatus_0_11_bits_reqTag;
  logic [0:0] io_msStatus_0_11_bits_is_miss;
  logic [0:0] io_msStatus_0_11_bits_is_prefetch;
  logic [0:0] io_msStatus_0_12_valid;
  logic [2:0] io_msStatus_0_12_bits_channel;
  logic [8:0] io_msStatus_0_12_bits_set;
  logic [30:0] io_msStatus_0_12_bits_reqTag;
  logic [0:0] io_msStatus_0_12_bits_is_miss;
  logic [0:0] io_msStatus_0_12_bits_is_prefetch;
  logic [0:0] io_msStatus_0_13_valid;
  logic [2:0] io_msStatus_0_13_bits_channel;
  logic [8:0] io_msStatus_0_13_bits_set;
  logic [30:0] io_msStatus_0_13_bits_reqTag;
  logic [0:0] io_msStatus_0_13_bits_is_miss;
  logic [0:0] io_msStatus_0_13_bits_is_prefetch;
  logic [0:0] io_msStatus_0_14_valid;
  logic [2:0] io_msStatus_0_14_bits_channel;
  logic [8:0] io_msStatus_0_14_bits_set;
  logic [30:0] io_msStatus_0_14_bits_reqTag;
  logic [0:0] io_msStatus_0_14_bits_is_miss;
  logic [0:0] io_msStatus_0_14_bits_is_prefetch;
  logic [0:0] io_msStatus_0_15_valid;
  logic [2:0] io_msStatus_0_15_bits_channel;
  logic [8:0] io_msStatus_0_15_bits_set;
  logic [30:0] io_msStatus_0_15_bits_reqTag;
  logic [0:0] io_msStatus_0_15_bits_is_miss;
  logic [0:0] io_msStatus_0_15_bits_is_prefetch;
  logic [0:0] io_msStatus_1_0_valid;
  logic [2:0] io_msStatus_1_0_bits_channel;
  logic [8:0] io_msStatus_1_0_bits_set;
  logic [30:0] io_msStatus_1_0_bits_reqTag;
  logic [0:0] io_msStatus_1_0_bits_is_miss;
  logic [0:0] io_msStatus_1_0_bits_is_prefetch;
  logic [0:0] io_msStatus_1_1_valid;
  logic [2:0] io_msStatus_1_1_bits_channel;
  logic [8:0] io_msStatus_1_1_bits_set;
  logic [30:0] io_msStatus_1_1_bits_reqTag;
  logic [0:0] io_msStatus_1_1_bits_is_miss;
  logic [0:0] io_msStatus_1_1_bits_is_prefetch;
  logic [0:0] io_msStatus_1_2_valid;
  logic [2:0] io_msStatus_1_2_bits_channel;
  logic [8:0] io_msStatus_1_2_bits_set;
  logic [30:0] io_msStatus_1_2_bits_reqTag;
  logic [0:0] io_msStatus_1_2_bits_is_miss;
  logic [0:0] io_msStatus_1_2_bits_is_prefetch;
  logic [0:0] io_msStatus_1_3_valid;
  logic [2:0] io_msStatus_1_3_bits_channel;
  logic [8:0] io_msStatus_1_3_bits_set;
  logic [30:0] io_msStatus_1_3_bits_reqTag;
  logic [0:0] io_msStatus_1_3_bits_is_miss;
  logic [0:0] io_msStatus_1_3_bits_is_prefetch;
  logic [0:0] io_msStatus_1_4_valid;
  logic [2:0] io_msStatus_1_4_bits_channel;
  logic [8:0] io_msStatus_1_4_bits_set;
  logic [30:0] io_msStatus_1_4_bits_reqTag;
  logic [0:0] io_msStatus_1_4_bits_is_miss;
  logic [0:0] io_msStatus_1_4_bits_is_prefetch;
  logic [0:0] io_msStatus_1_5_valid;
  logic [2:0] io_msStatus_1_5_bits_channel;
  logic [8:0] io_msStatus_1_5_bits_set;
  logic [30:0] io_msStatus_1_5_bits_reqTag;
  logic [0:0] io_msStatus_1_5_bits_is_miss;
  logic [0:0] io_msStatus_1_5_bits_is_prefetch;
  logic [0:0] io_msStatus_1_6_valid;
  logic [2:0] io_msStatus_1_6_bits_channel;
  logic [8:0] io_msStatus_1_6_bits_set;
  logic [30:0] io_msStatus_1_6_bits_reqTag;
  logic [0:0] io_msStatus_1_6_bits_is_miss;
  logic [0:0] io_msStatus_1_6_bits_is_prefetch;
  logic [0:0] io_msStatus_1_7_valid;
  logic [2:0] io_msStatus_1_7_bits_channel;
  logic [8:0] io_msStatus_1_7_bits_set;
  logic [30:0] io_msStatus_1_7_bits_reqTag;
  logic [0:0] io_msStatus_1_7_bits_is_miss;
  logic [0:0] io_msStatus_1_7_bits_is_prefetch;
  logic [0:0] io_msStatus_1_8_valid;
  logic [2:0] io_msStatus_1_8_bits_channel;
  logic [8:0] io_msStatus_1_8_bits_set;
  logic [30:0] io_msStatus_1_8_bits_reqTag;
  logic [0:0] io_msStatus_1_8_bits_is_miss;
  logic [0:0] io_msStatus_1_8_bits_is_prefetch;
  logic [0:0] io_msStatus_1_9_valid;
  logic [2:0] io_msStatus_1_9_bits_channel;
  logic [8:0] io_msStatus_1_9_bits_set;
  logic [30:0] io_msStatus_1_9_bits_reqTag;
  logic [0:0] io_msStatus_1_9_bits_is_miss;
  logic [0:0] io_msStatus_1_9_bits_is_prefetch;
  logic [0:0] io_msStatus_1_10_valid;
  logic [2:0] io_msStatus_1_10_bits_channel;
  logic [8:0] io_msStatus_1_10_bits_set;
  logic [30:0] io_msStatus_1_10_bits_reqTag;
  logic [0:0] io_msStatus_1_10_bits_is_miss;
  logic [0:0] io_msStatus_1_10_bits_is_prefetch;
  logic [0:0] io_msStatus_1_11_valid;
  logic [2:0] io_msStatus_1_11_bits_channel;
  logic [8:0] io_msStatus_1_11_bits_set;
  logic [30:0] io_msStatus_1_11_bits_reqTag;
  logic [0:0] io_msStatus_1_11_bits_is_miss;
  logic [0:0] io_msStatus_1_11_bits_is_prefetch;
  logic [0:0] io_msStatus_1_12_valid;
  logic [2:0] io_msStatus_1_12_bits_channel;
  logic [8:0] io_msStatus_1_12_bits_set;
  logic [30:0] io_msStatus_1_12_bits_reqTag;
  logic [0:0] io_msStatus_1_12_bits_is_miss;
  logic [0:0] io_msStatus_1_12_bits_is_prefetch;
  logic [0:0] io_msStatus_1_13_valid;
  logic [2:0] io_msStatus_1_13_bits_channel;
  logic [8:0] io_msStatus_1_13_bits_set;
  logic [30:0] io_msStatus_1_13_bits_reqTag;
  logic [0:0] io_msStatus_1_13_bits_is_miss;
  logic [0:0] io_msStatus_1_13_bits_is_prefetch;
  logic [0:0] io_msStatus_1_14_valid;
  logic [2:0] io_msStatus_1_14_bits_channel;
  logic [8:0] io_msStatus_1_14_bits_set;
  logic [30:0] io_msStatus_1_14_bits_reqTag;
  logic [0:0] io_msStatus_1_14_bits_is_miss;
  logic [0:0] io_msStatus_1_14_bits_is_prefetch;
  logic [0:0] io_msStatus_1_15_valid;
  logic [2:0] io_msStatus_1_15_bits_channel;
  logic [8:0] io_msStatus_1_15_bits_set;
  logic [30:0] io_msStatus_1_15_bits_reqTag;
  logic [0:0] io_msStatus_1_15_bits_is_miss;
  logic [0:0] io_msStatus_1_15_bits_is_prefetch;
  logic [0:0] io_msStatus_2_0_valid;
  logic [2:0] io_msStatus_2_0_bits_channel;
  logic [8:0] io_msStatus_2_0_bits_set;
  logic [30:0] io_msStatus_2_0_bits_reqTag;
  logic [0:0] io_msStatus_2_0_bits_is_miss;
  logic [0:0] io_msStatus_2_0_bits_is_prefetch;
  logic [0:0] io_msStatus_2_1_valid;
  logic [2:0] io_msStatus_2_1_bits_channel;
  logic [8:0] io_msStatus_2_1_bits_set;
  logic [30:0] io_msStatus_2_1_bits_reqTag;
  logic [0:0] io_msStatus_2_1_bits_is_miss;
  logic [0:0] io_msStatus_2_1_bits_is_prefetch;
  logic [0:0] io_msStatus_2_2_valid;
  logic [2:0] io_msStatus_2_2_bits_channel;
  logic [8:0] io_msStatus_2_2_bits_set;
  logic [30:0] io_msStatus_2_2_bits_reqTag;
  logic [0:0] io_msStatus_2_2_bits_is_miss;
  logic [0:0] io_msStatus_2_2_bits_is_prefetch;
  logic [0:0] io_msStatus_2_3_valid;
  logic [2:0] io_msStatus_2_3_bits_channel;
  logic [8:0] io_msStatus_2_3_bits_set;
  logic [30:0] io_msStatus_2_3_bits_reqTag;
  logic [0:0] io_msStatus_2_3_bits_is_miss;
  logic [0:0] io_msStatus_2_3_bits_is_prefetch;
  logic [0:0] io_msStatus_2_4_valid;
  logic [2:0] io_msStatus_2_4_bits_channel;
  logic [8:0] io_msStatus_2_4_bits_set;
  logic [30:0] io_msStatus_2_4_bits_reqTag;
  logic [0:0] io_msStatus_2_4_bits_is_miss;
  logic [0:0] io_msStatus_2_4_bits_is_prefetch;
  logic [0:0] io_msStatus_2_5_valid;
  logic [2:0] io_msStatus_2_5_bits_channel;
  logic [8:0] io_msStatus_2_5_bits_set;
  logic [30:0] io_msStatus_2_5_bits_reqTag;
  logic [0:0] io_msStatus_2_5_bits_is_miss;
  logic [0:0] io_msStatus_2_5_bits_is_prefetch;
  logic [0:0] io_msStatus_2_6_valid;
  logic [2:0] io_msStatus_2_6_bits_channel;
  logic [8:0] io_msStatus_2_6_bits_set;
  logic [30:0] io_msStatus_2_6_bits_reqTag;
  logic [0:0] io_msStatus_2_6_bits_is_miss;
  logic [0:0] io_msStatus_2_6_bits_is_prefetch;
  logic [0:0] io_msStatus_2_7_valid;
  logic [2:0] io_msStatus_2_7_bits_channel;
  logic [8:0] io_msStatus_2_7_bits_set;
  logic [30:0] io_msStatus_2_7_bits_reqTag;
  logic [0:0] io_msStatus_2_7_bits_is_miss;
  logic [0:0] io_msStatus_2_7_bits_is_prefetch;
  logic [0:0] io_msStatus_2_8_valid;
  logic [2:0] io_msStatus_2_8_bits_channel;
  logic [8:0] io_msStatus_2_8_bits_set;
  logic [30:0] io_msStatus_2_8_bits_reqTag;
  logic [0:0] io_msStatus_2_8_bits_is_miss;
  logic [0:0] io_msStatus_2_8_bits_is_prefetch;
  logic [0:0] io_msStatus_2_9_valid;
  logic [2:0] io_msStatus_2_9_bits_channel;
  logic [8:0] io_msStatus_2_9_bits_set;
  logic [30:0] io_msStatus_2_9_bits_reqTag;
  logic [0:0] io_msStatus_2_9_bits_is_miss;
  logic [0:0] io_msStatus_2_9_bits_is_prefetch;
  logic [0:0] io_msStatus_2_10_valid;
  logic [2:0] io_msStatus_2_10_bits_channel;
  logic [8:0] io_msStatus_2_10_bits_set;
  logic [30:0] io_msStatus_2_10_bits_reqTag;
  logic [0:0] io_msStatus_2_10_bits_is_miss;
  logic [0:0] io_msStatus_2_10_bits_is_prefetch;
  logic [0:0] io_msStatus_2_11_valid;
  logic [2:0] io_msStatus_2_11_bits_channel;
  logic [8:0] io_msStatus_2_11_bits_set;
  logic [30:0] io_msStatus_2_11_bits_reqTag;
  logic [0:0] io_msStatus_2_11_bits_is_miss;
  logic [0:0] io_msStatus_2_11_bits_is_prefetch;
  logic [0:0] io_msStatus_2_12_valid;
  logic [2:0] io_msStatus_2_12_bits_channel;
  logic [8:0] io_msStatus_2_12_bits_set;
  logic [30:0] io_msStatus_2_12_bits_reqTag;
  logic [0:0] io_msStatus_2_12_bits_is_miss;
  logic [0:0] io_msStatus_2_12_bits_is_prefetch;
  logic [0:0] io_msStatus_2_13_valid;
  logic [2:0] io_msStatus_2_13_bits_channel;
  logic [8:0] io_msStatus_2_13_bits_set;
  logic [30:0] io_msStatus_2_13_bits_reqTag;
  logic [0:0] io_msStatus_2_13_bits_is_miss;
  logic [0:0] io_msStatus_2_13_bits_is_prefetch;
  logic [0:0] io_msStatus_2_14_valid;
  logic [2:0] io_msStatus_2_14_bits_channel;
  logic [8:0] io_msStatus_2_14_bits_set;
  logic [30:0] io_msStatus_2_14_bits_reqTag;
  logic [0:0] io_msStatus_2_14_bits_is_miss;
  logic [0:0] io_msStatus_2_14_bits_is_prefetch;
  logic [0:0] io_msStatus_2_15_valid;
  logic [2:0] io_msStatus_2_15_bits_channel;
  logic [8:0] io_msStatus_2_15_bits_set;
  logic [30:0] io_msStatus_2_15_bits_reqTag;
  logic [0:0] io_msStatus_2_15_bits_is_miss;
  logic [0:0] io_msStatus_2_15_bits_is_prefetch;
  logic [0:0] io_msStatus_3_0_valid;
  logic [2:0] io_msStatus_3_0_bits_channel;
  logic [8:0] io_msStatus_3_0_bits_set;
  logic [30:0] io_msStatus_3_0_bits_reqTag;
  logic [0:0] io_msStatus_3_0_bits_is_miss;
  logic [0:0] io_msStatus_3_0_bits_is_prefetch;
  logic [0:0] io_msStatus_3_1_valid;
  logic [2:0] io_msStatus_3_1_bits_channel;
  logic [8:0] io_msStatus_3_1_bits_set;
  logic [30:0] io_msStatus_3_1_bits_reqTag;
  logic [0:0] io_msStatus_3_1_bits_is_miss;
  logic [0:0] io_msStatus_3_1_bits_is_prefetch;
  logic [0:0] io_msStatus_3_2_valid;
  logic [2:0] io_msStatus_3_2_bits_channel;
  logic [8:0] io_msStatus_3_2_bits_set;
  logic [30:0] io_msStatus_3_2_bits_reqTag;
  logic [0:0] io_msStatus_3_2_bits_is_miss;
  logic [0:0] io_msStatus_3_2_bits_is_prefetch;
  logic [0:0] io_msStatus_3_3_valid;
  logic [2:0] io_msStatus_3_3_bits_channel;
  logic [8:0] io_msStatus_3_3_bits_set;
  logic [30:0] io_msStatus_3_3_bits_reqTag;
  logic [0:0] io_msStatus_3_3_bits_is_miss;
  logic [0:0] io_msStatus_3_3_bits_is_prefetch;
  logic [0:0] io_msStatus_3_4_valid;
  logic [2:0] io_msStatus_3_4_bits_channel;
  logic [8:0] io_msStatus_3_4_bits_set;
  logic [30:0] io_msStatus_3_4_bits_reqTag;
  logic [0:0] io_msStatus_3_4_bits_is_miss;
  logic [0:0] io_msStatus_3_4_bits_is_prefetch;
  logic [0:0] io_msStatus_3_5_valid;
  logic [2:0] io_msStatus_3_5_bits_channel;
  logic [8:0] io_msStatus_3_5_bits_set;
  logic [30:0] io_msStatus_3_5_bits_reqTag;
  logic [0:0] io_msStatus_3_5_bits_is_miss;
  logic [0:0] io_msStatus_3_5_bits_is_prefetch;
  logic [0:0] io_msStatus_3_6_valid;
  logic [2:0] io_msStatus_3_6_bits_channel;
  logic [8:0] io_msStatus_3_6_bits_set;
  logic [30:0] io_msStatus_3_6_bits_reqTag;
  logic [0:0] io_msStatus_3_6_bits_is_miss;
  logic [0:0] io_msStatus_3_6_bits_is_prefetch;
  logic [0:0] io_msStatus_3_7_valid;
  logic [2:0] io_msStatus_3_7_bits_channel;
  logic [8:0] io_msStatus_3_7_bits_set;
  logic [30:0] io_msStatus_3_7_bits_reqTag;
  logic [0:0] io_msStatus_3_7_bits_is_miss;
  logic [0:0] io_msStatus_3_7_bits_is_prefetch;
  logic [0:0] io_msStatus_3_8_valid;
  logic [2:0] io_msStatus_3_8_bits_channel;
  logic [8:0] io_msStatus_3_8_bits_set;
  logic [30:0] io_msStatus_3_8_bits_reqTag;
  logic [0:0] io_msStatus_3_8_bits_is_miss;
  logic [0:0] io_msStatus_3_8_bits_is_prefetch;
  logic [0:0] io_msStatus_3_9_valid;
  logic [2:0] io_msStatus_3_9_bits_channel;
  logic [8:0] io_msStatus_3_9_bits_set;
  logic [30:0] io_msStatus_3_9_bits_reqTag;
  logic [0:0] io_msStatus_3_9_bits_is_miss;
  logic [0:0] io_msStatus_3_9_bits_is_prefetch;
  logic [0:0] io_msStatus_3_10_valid;
  logic [2:0] io_msStatus_3_10_bits_channel;
  logic [8:0] io_msStatus_3_10_bits_set;
  logic [30:0] io_msStatus_3_10_bits_reqTag;
  logic [0:0] io_msStatus_3_10_bits_is_miss;
  logic [0:0] io_msStatus_3_10_bits_is_prefetch;
  logic [0:0] io_msStatus_3_11_valid;
  logic [2:0] io_msStatus_3_11_bits_channel;
  logic [8:0] io_msStatus_3_11_bits_set;
  logic [30:0] io_msStatus_3_11_bits_reqTag;
  logic [0:0] io_msStatus_3_11_bits_is_miss;
  logic [0:0] io_msStatus_3_11_bits_is_prefetch;
  logic [0:0] io_msStatus_3_12_valid;
  logic [2:0] io_msStatus_3_12_bits_channel;
  logic [8:0] io_msStatus_3_12_bits_set;
  logic [30:0] io_msStatus_3_12_bits_reqTag;
  logic [0:0] io_msStatus_3_12_bits_is_miss;
  logic [0:0] io_msStatus_3_12_bits_is_prefetch;
  logic [0:0] io_msStatus_3_13_valid;
  logic [2:0] io_msStatus_3_13_bits_channel;
  logic [8:0] io_msStatus_3_13_bits_set;
  logic [30:0] io_msStatus_3_13_bits_reqTag;
  logic [0:0] io_msStatus_3_13_bits_is_miss;
  logic [0:0] io_msStatus_3_13_bits_is_prefetch;
  logic [0:0] io_msStatus_3_14_valid;
  logic [2:0] io_msStatus_3_14_bits_channel;
  logic [8:0] io_msStatus_3_14_bits_set;
  logic [30:0] io_msStatus_3_14_bits_reqTag;
  logic [0:0] io_msStatus_3_14_bits_is_miss;
  logic [0:0] io_msStatus_3_14_bits_is_prefetch;
  logic [0:0] io_msStatus_3_15_valid;
  logic [2:0] io_msStatus_3_15_bits_channel;
  logic [8:0] io_msStatus_3_15_bits_set;
  logic [30:0] io_msStatus_3_15_bits_reqTag;
  logic [0:0] io_msStatus_3_15_bits_is_miss;
  logic [0:0] io_msStatus_3_15_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_0_valid;
  logic [2:0] io_msAlloc_0_0_bits_channel;
  logic [0:0] io_msAlloc_0_0_bits_is_miss;
  logic [0:0] io_msAlloc_0_0_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_1_valid;
  logic [2:0] io_msAlloc_0_1_bits_channel;
  logic [0:0] io_msAlloc_0_1_bits_is_miss;
  logic [0:0] io_msAlloc_0_1_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_2_valid;
  logic [2:0] io_msAlloc_0_2_bits_channel;
  logic [0:0] io_msAlloc_0_2_bits_is_miss;
  logic [0:0] io_msAlloc_0_2_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_3_valid;
  logic [2:0] io_msAlloc_0_3_bits_channel;
  logic [0:0] io_msAlloc_0_3_bits_is_miss;
  logic [0:0] io_msAlloc_0_3_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_4_valid;
  logic [2:0] io_msAlloc_0_4_bits_channel;
  logic [0:0] io_msAlloc_0_4_bits_is_miss;
  logic [0:0] io_msAlloc_0_4_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_5_valid;
  logic [2:0] io_msAlloc_0_5_bits_channel;
  logic [0:0] io_msAlloc_0_5_bits_is_miss;
  logic [0:0] io_msAlloc_0_5_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_6_valid;
  logic [2:0] io_msAlloc_0_6_bits_channel;
  logic [0:0] io_msAlloc_0_6_bits_is_miss;
  logic [0:0] io_msAlloc_0_6_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_7_valid;
  logic [2:0] io_msAlloc_0_7_bits_channel;
  logic [0:0] io_msAlloc_0_7_bits_is_miss;
  logic [0:0] io_msAlloc_0_7_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_8_valid;
  logic [2:0] io_msAlloc_0_8_bits_channel;
  logic [0:0] io_msAlloc_0_8_bits_is_miss;
  logic [0:0] io_msAlloc_0_8_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_9_valid;
  logic [2:0] io_msAlloc_0_9_bits_channel;
  logic [0:0] io_msAlloc_0_9_bits_is_miss;
  logic [0:0] io_msAlloc_0_9_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_10_valid;
  logic [2:0] io_msAlloc_0_10_bits_channel;
  logic [0:0] io_msAlloc_0_10_bits_is_miss;
  logic [0:0] io_msAlloc_0_10_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_11_valid;
  logic [2:0] io_msAlloc_0_11_bits_channel;
  logic [0:0] io_msAlloc_0_11_bits_is_miss;
  logic [0:0] io_msAlloc_0_11_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_12_valid;
  logic [2:0] io_msAlloc_0_12_bits_channel;
  logic [0:0] io_msAlloc_0_12_bits_is_miss;
  logic [0:0] io_msAlloc_0_12_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_13_valid;
  logic [2:0] io_msAlloc_0_13_bits_channel;
  logic [0:0] io_msAlloc_0_13_bits_is_miss;
  logic [0:0] io_msAlloc_0_13_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_14_valid;
  logic [2:0] io_msAlloc_0_14_bits_channel;
  logic [0:0] io_msAlloc_0_14_bits_is_miss;
  logic [0:0] io_msAlloc_0_14_bits_is_prefetch;
  logic [0:0] io_msAlloc_0_15_valid;
  logic [2:0] io_msAlloc_0_15_bits_channel;
  logic [0:0] io_msAlloc_0_15_bits_is_miss;
  logic [0:0] io_msAlloc_0_15_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_0_valid;
  logic [2:0] io_msAlloc_1_0_bits_channel;
  logic [0:0] io_msAlloc_1_0_bits_is_miss;
  logic [0:0] io_msAlloc_1_0_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_1_valid;
  logic [2:0] io_msAlloc_1_1_bits_channel;
  logic [0:0] io_msAlloc_1_1_bits_is_miss;
  logic [0:0] io_msAlloc_1_1_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_2_valid;
  logic [2:0] io_msAlloc_1_2_bits_channel;
  logic [0:0] io_msAlloc_1_2_bits_is_miss;
  logic [0:0] io_msAlloc_1_2_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_3_valid;
  logic [2:0] io_msAlloc_1_3_bits_channel;
  logic [0:0] io_msAlloc_1_3_bits_is_miss;
  logic [0:0] io_msAlloc_1_3_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_4_valid;
  logic [2:0] io_msAlloc_1_4_bits_channel;
  logic [0:0] io_msAlloc_1_4_bits_is_miss;
  logic [0:0] io_msAlloc_1_4_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_5_valid;
  logic [2:0] io_msAlloc_1_5_bits_channel;
  logic [0:0] io_msAlloc_1_5_bits_is_miss;
  logic [0:0] io_msAlloc_1_5_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_6_valid;
  logic [2:0] io_msAlloc_1_6_bits_channel;
  logic [0:0] io_msAlloc_1_6_bits_is_miss;
  logic [0:0] io_msAlloc_1_6_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_7_valid;
  logic [2:0] io_msAlloc_1_7_bits_channel;
  logic [0:0] io_msAlloc_1_7_bits_is_miss;
  logic [0:0] io_msAlloc_1_7_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_8_valid;
  logic [2:0] io_msAlloc_1_8_bits_channel;
  logic [0:0] io_msAlloc_1_8_bits_is_miss;
  logic [0:0] io_msAlloc_1_8_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_9_valid;
  logic [2:0] io_msAlloc_1_9_bits_channel;
  logic [0:0] io_msAlloc_1_9_bits_is_miss;
  logic [0:0] io_msAlloc_1_9_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_10_valid;
  logic [2:0] io_msAlloc_1_10_bits_channel;
  logic [0:0] io_msAlloc_1_10_bits_is_miss;
  logic [0:0] io_msAlloc_1_10_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_11_valid;
  logic [2:0] io_msAlloc_1_11_bits_channel;
  logic [0:0] io_msAlloc_1_11_bits_is_miss;
  logic [0:0] io_msAlloc_1_11_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_12_valid;
  logic [2:0] io_msAlloc_1_12_bits_channel;
  logic [0:0] io_msAlloc_1_12_bits_is_miss;
  logic [0:0] io_msAlloc_1_12_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_13_valid;
  logic [2:0] io_msAlloc_1_13_bits_channel;
  logic [0:0] io_msAlloc_1_13_bits_is_miss;
  logic [0:0] io_msAlloc_1_13_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_14_valid;
  logic [2:0] io_msAlloc_1_14_bits_channel;
  logic [0:0] io_msAlloc_1_14_bits_is_miss;
  logic [0:0] io_msAlloc_1_14_bits_is_prefetch;
  logic [0:0] io_msAlloc_1_15_valid;
  logic [2:0] io_msAlloc_1_15_bits_channel;
  logic [0:0] io_msAlloc_1_15_bits_is_miss;
  logic [0:0] io_msAlloc_1_15_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_0_valid;
  logic [2:0] io_msAlloc_2_0_bits_channel;
  logic [0:0] io_msAlloc_2_0_bits_is_miss;
  logic [0:0] io_msAlloc_2_0_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_1_valid;
  logic [2:0] io_msAlloc_2_1_bits_channel;
  logic [0:0] io_msAlloc_2_1_bits_is_miss;
  logic [0:0] io_msAlloc_2_1_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_2_valid;
  logic [2:0] io_msAlloc_2_2_bits_channel;
  logic [0:0] io_msAlloc_2_2_bits_is_miss;
  logic [0:0] io_msAlloc_2_2_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_3_valid;
  logic [2:0] io_msAlloc_2_3_bits_channel;
  logic [0:0] io_msAlloc_2_3_bits_is_miss;
  logic [0:0] io_msAlloc_2_3_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_4_valid;
  logic [2:0] io_msAlloc_2_4_bits_channel;
  logic [0:0] io_msAlloc_2_4_bits_is_miss;
  logic [0:0] io_msAlloc_2_4_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_5_valid;
  logic [2:0] io_msAlloc_2_5_bits_channel;
  logic [0:0] io_msAlloc_2_5_bits_is_miss;
  logic [0:0] io_msAlloc_2_5_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_6_valid;
  logic [2:0] io_msAlloc_2_6_bits_channel;
  logic [0:0] io_msAlloc_2_6_bits_is_miss;
  logic [0:0] io_msAlloc_2_6_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_7_valid;
  logic [2:0] io_msAlloc_2_7_bits_channel;
  logic [0:0] io_msAlloc_2_7_bits_is_miss;
  logic [0:0] io_msAlloc_2_7_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_8_valid;
  logic [2:0] io_msAlloc_2_8_bits_channel;
  logic [0:0] io_msAlloc_2_8_bits_is_miss;
  logic [0:0] io_msAlloc_2_8_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_9_valid;
  logic [2:0] io_msAlloc_2_9_bits_channel;
  logic [0:0] io_msAlloc_2_9_bits_is_miss;
  logic [0:0] io_msAlloc_2_9_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_10_valid;
  logic [2:0] io_msAlloc_2_10_bits_channel;
  logic [0:0] io_msAlloc_2_10_bits_is_miss;
  logic [0:0] io_msAlloc_2_10_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_11_valid;
  logic [2:0] io_msAlloc_2_11_bits_channel;
  logic [0:0] io_msAlloc_2_11_bits_is_miss;
  logic [0:0] io_msAlloc_2_11_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_12_valid;
  logic [2:0] io_msAlloc_2_12_bits_channel;
  logic [0:0] io_msAlloc_2_12_bits_is_miss;
  logic [0:0] io_msAlloc_2_12_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_13_valid;
  logic [2:0] io_msAlloc_2_13_bits_channel;
  logic [0:0] io_msAlloc_2_13_bits_is_miss;
  logic [0:0] io_msAlloc_2_13_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_14_valid;
  logic [2:0] io_msAlloc_2_14_bits_channel;
  logic [0:0] io_msAlloc_2_14_bits_is_miss;
  logic [0:0] io_msAlloc_2_14_bits_is_prefetch;
  logic [0:0] io_msAlloc_2_15_valid;
  logic [2:0] io_msAlloc_2_15_bits_channel;
  logic [0:0] io_msAlloc_2_15_bits_is_miss;
  logic [0:0] io_msAlloc_2_15_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_0_valid;
  logic [2:0] io_msAlloc_3_0_bits_channel;
  logic [0:0] io_msAlloc_3_0_bits_is_miss;
  logic [0:0] io_msAlloc_3_0_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_1_valid;
  logic [2:0] io_msAlloc_3_1_bits_channel;
  logic [0:0] io_msAlloc_3_1_bits_is_miss;
  logic [0:0] io_msAlloc_3_1_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_2_valid;
  logic [2:0] io_msAlloc_3_2_bits_channel;
  logic [0:0] io_msAlloc_3_2_bits_is_miss;
  logic [0:0] io_msAlloc_3_2_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_3_valid;
  logic [2:0] io_msAlloc_3_3_bits_channel;
  logic [0:0] io_msAlloc_3_3_bits_is_miss;
  logic [0:0] io_msAlloc_3_3_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_4_valid;
  logic [2:0] io_msAlloc_3_4_bits_channel;
  logic [0:0] io_msAlloc_3_4_bits_is_miss;
  logic [0:0] io_msAlloc_3_4_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_5_valid;
  logic [2:0] io_msAlloc_3_5_bits_channel;
  logic [0:0] io_msAlloc_3_5_bits_is_miss;
  logic [0:0] io_msAlloc_3_5_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_6_valid;
  logic [2:0] io_msAlloc_3_6_bits_channel;
  logic [0:0] io_msAlloc_3_6_bits_is_miss;
  logic [0:0] io_msAlloc_3_6_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_7_valid;
  logic [2:0] io_msAlloc_3_7_bits_channel;
  logic [0:0] io_msAlloc_3_7_bits_is_miss;
  logic [0:0] io_msAlloc_3_7_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_8_valid;
  logic [2:0] io_msAlloc_3_8_bits_channel;
  logic [0:0] io_msAlloc_3_8_bits_is_miss;
  logic [0:0] io_msAlloc_3_8_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_9_valid;
  logic [2:0] io_msAlloc_3_9_bits_channel;
  logic [0:0] io_msAlloc_3_9_bits_is_miss;
  logic [0:0] io_msAlloc_3_9_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_10_valid;
  logic [2:0] io_msAlloc_3_10_bits_channel;
  logic [0:0] io_msAlloc_3_10_bits_is_miss;
  logic [0:0] io_msAlloc_3_10_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_11_valid;
  logic [2:0] io_msAlloc_3_11_bits_channel;
  logic [0:0] io_msAlloc_3_11_bits_is_miss;
  logic [0:0] io_msAlloc_3_11_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_12_valid;
  logic [2:0] io_msAlloc_3_12_bits_channel;
  logic [0:0] io_msAlloc_3_12_bits_is_miss;
  logic [0:0] io_msAlloc_3_12_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_13_valid;
  logic [2:0] io_msAlloc_3_13_bits_channel;
  logic [0:0] io_msAlloc_3_13_bits_is_miss;
  logic [0:0] io_msAlloc_3_13_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_14_valid;
  logic [2:0] io_msAlloc_3_14_bits_channel;
  logic [0:0] io_msAlloc_3_14_bits_is_miss;
  logic [0:0] io_msAlloc_3_14_bits_is_prefetch;
  logic [0:0] io_msAlloc_3_15_valid;
  logic [2:0] io_msAlloc_3_15_bits_channel;
  logic [0:0] io_msAlloc_3_15_bits_is_miss;
  logic [0:0] io_msAlloc_3_15_bits_is_prefetch;
  logic [0:0] io_hitPfInMSHR_0_valid;
  logic [2:0] io_hitPfInMSHR_0_bits;
  logic [0:0] io_hitPfInMSHR_1_valid;
  logic [2:0] io_hitPfInMSHR_1_bits;
  logic [0:0] io_hitPfInMSHR_2_valid;
  logic [2:0] io_hitPfInMSHR_2_bits;
  logic [0:0] io_hitPfInMSHR_3_valid;
  logic [2:0] io_hitPfInMSHR_3_bits;
  logic [0:0] io_pfSent_0_valid;
  logic [4:0] io_pfSent_0_bits;
  logic [0:0] io_pfSent_1_valid;
  logic [4:0] io_pfSent_1_bits;
  logic [0:0] io_pfSent_2_valid;
  logic [4:0] io_pfSent_2_bits;
  logic [0:0] io_pfSent_3_valid;
  logic [4:0] io_pfSent_3_bits;
  logic [0:0] io_pfLateInMSHR_0_valid;
  logic [4:0] io_pfLateInMSHR_0_bits;
  logic [0:0] io_pfLateInMSHR_1_valid;
  logic [4:0] io_pfLateInMSHR_1_bits;
  logic [0:0] io_pfLateInMSHR_2_valid;
  logic [4:0] io_pfLateInMSHR_2_bits;
  logic [0:0] io_pfLateInMSHR_3_valid;
  logic [4:0] io_pfLateInMSHR_3_bits;
  logic [0:0] io_debugTopDown_robHeadPaddr_valid;
  logic [35:0] io_debugTopDown_robHeadPaddr_bits;
  logic g_out, i_out;
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
    .io_msAlloc_0_0_valid(io_msAlloc_0_0_valid),
    .io_msAlloc_0_0_bits_channel(io_msAlloc_0_0_bits_channel),
    .io_msAlloc_0_0_bits_is_miss(io_msAlloc_0_0_bits_is_miss),
    .io_msAlloc_0_0_bits_is_prefetch(io_msAlloc_0_0_bits_is_prefetch),
    .io_msAlloc_0_1_valid(io_msAlloc_0_1_valid),
    .io_msAlloc_0_1_bits_channel(io_msAlloc_0_1_bits_channel),
    .io_msAlloc_0_1_bits_is_miss(io_msAlloc_0_1_bits_is_miss),
    .io_msAlloc_0_1_bits_is_prefetch(io_msAlloc_0_1_bits_is_prefetch),
    .io_msAlloc_0_2_valid(io_msAlloc_0_2_valid),
    .io_msAlloc_0_2_bits_channel(io_msAlloc_0_2_bits_channel),
    .io_msAlloc_0_2_bits_is_miss(io_msAlloc_0_2_bits_is_miss),
    .io_msAlloc_0_2_bits_is_prefetch(io_msAlloc_0_2_bits_is_prefetch),
    .io_msAlloc_0_3_valid(io_msAlloc_0_3_valid),
    .io_msAlloc_0_3_bits_channel(io_msAlloc_0_3_bits_channel),
    .io_msAlloc_0_3_bits_is_miss(io_msAlloc_0_3_bits_is_miss),
    .io_msAlloc_0_3_bits_is_prefetch(io_msAlloc_0_3_bits_is_prefetch),
    .io_msAlloc_0_4_valid(io_msAlloc_0_4_valid),
    .io_msAlloc_0_4_bits_channel(io_msAlloc_0_4_bits_channel),
    .io_msAlloc_0_4_bits_is_miss(io_msAlloc_0_4_bits_is_miss),
    .io_msAlloc_0_4_bits_is_prefetch(io_msAlloc_0_4_bits_is_prefetch),
    .io_msAlloc_0_5_valid(io_msAlloc_0_5_valid),
    .io_msAlloc_0_5_bits_channel(io_msAlloc_0_5_bits_channel),
    .io_msAlloc_0_5_bits_is_miss(io_msAlloc_0_5_bits_is_miss),
    .io_msAlloc_0_5_bits_is_prefetch(io_msAlloc_0_5_bits_is_prefetch),
    .io_msAlloc_0_6_valid(io_msAlloc_0_6_valid),
    .io_msAlloc_0_6_bits_channel(io_msAlloc_0_6_bits_channel),
    .io_msAlloc_0_6_bits_is_miss(io_msAlloc_0_6_bits_is_miss),
    .io_msAlloc_0_6_bits_is_prefetch(io_msAlloc_0_6_bits_is_prefetch),
    .io_msAlloc_0_7_valid(io_msAlloc_0_7_valid),
    .io_msAlloc_0_7_bits_channel(io_msAlloc_0_7_bits_channel),
    .io_msAlloc_0_7_bits_is_miss(io_msAlloc_0_7_bits_is_miss),
    .io_msAlloc_0_7_bits_is_prefetch(io_msAlloc_0_7_bits_is_prefetch),
    .io_msAlloc_0_8_valid(io_msAlloc_0_8_valid),
    .io_msAlloc_0_8_bits_channel(io_msAlloc_0_8_bits_channel),
    .io_msAlloc_0_8_bits_is_miss(io_msAlloc_0_8_bits_is_miss),
    .io_msAlloc_0_8_bits_is_prefetch(io_msAlloc_0_8_bits_is_prefetch),
    .io_msAlloc_0_9_valid(io_msAlloc_0_9_valid),
    .io_msAlloc_0_9_bits_channel(io_msAlloc_0_9_bits_channel),
    .io_msAlloc_0_9_bits_is_miss(io_msAlloc_0_9_bits_is_miss),
    .io_msAlloc_0_9_bits_is_prefetch(io_msAlloc_0_9_bits_is_prefetch),
    .io_msAlloc_0_10_valid(io_msAlloc_0_10_valid),
    .io_msAlloc_0_10_bits_channel(io_msAlloc_0_10_bits_channel),
    .io_msAlloc_0_10_bits_is_miss(io_msAlloc_0_10_bits_is_miss),
    .io_msAlloc_0_10_bits_is_prefetch(io_msAlloc_0_10_bits_is_prefetch),
    .io_msAlloc_0_11_valid(io_msAlloc_0_11_valid),
    .io_msAlloc_0_11_bits_channel(io_msAlloc_0_11_bits_channel),
    .io_msAlloc_0_11_bits_is_miss(io_msAlloc_0_11_bits_is_miss),
    .io_msAlloc_0_11_bits_is_prefetch(io_msAlloc_0_11_bits_is_prefetch),
    .io_msAlloc_0_12_valid(io_msAlloc_0_12_valid),
    .io_msAlloc_0_12_bits_channel(io_msAlloc_0_12_bits_channel),
    .io_msAlloc_0_12_bits_is_miss(io_msAlloc_0_12_bits_is_miss),
    .io_msAlloc_0_12_bits_is_prefetch(io_msAlloc_0_12_bits_is_prefetch),
    .io_msAlloc_0_13_valid(io_msAlloc_0_13_valid),
    .io_msAlloc_0_13_bits_channel(io_msAlloc_0_13_bits_channel),
    .io_msAlloc_0_13_bits_is_miss(io_msAlloc_0_13_bits_is_miss),
    .io_msAlloc_0_13_bits_is_prefetch(io_msAlloc_0_13_bits_is_prefetch),
    .io_msAlloc_0_14_valid(io_msAlloc_0_14_valid),
    .io_msAlloc_0_14_bits_channel(io_msAlloc_0_14_bits_channel),
    .io_msAlloc_0_14_bits_is_miss(io_msAlloc_0_14_bits_is_miss),
    .io_msAlloc_0_14_bits_is_prefetch(io_msAlloc_0_14_bits_is_prefetch),
    .io_msAlloc_0_15_valid(io_msAlloc_0_15_valid),
    .io_msAlloc_0_15_bits_channel(io_msAlloc_0_15_bits_channel),
    .io_msAlloc_0_15_bits_is_miss(io_msAlloc_0_15_bits_is_miss),
    .io_msAlloc_0_15_bits_is_prefetch(io_msAlloc_0_15_bits_is_prefetch),
    .io_msAlloc_1_0_valid(io_msAlloc_1_0_valid),
    .io_msAlloc_1_0_bits_channel(io_msAlloc_1_0_bits_channel),
    .io_msAlloc_1_0_bits_is_miss(io_msAlloc_1_0_bits_is_miss),
    .io_msAlloc_1_0_bits_is_prefetch(io_msAlloc_1_0_bits_is_prefetch),
    .io_msAlloc_1_1_valid(io_msAlloc_1_1_valid),
    .io_msAlloc_1_1_bits_channel(io_msAlloc_1_1_bits_channel),
    .io_msAlloc_1_1_bits_is_miss(io_msAlloc_1_1_bits_is_miss),
    .io_msAlloc_1_1_bits_is_prefetch(io_msAlloc_1_1_bits_is_prefetch),
    .io_msAlloc_1_2_valid(io_msAlloc_1_2_valid),
    .io_msAlloc_1_2_bits_channel(io_msAlloc_1_2_bits_channel),
    .io_msAlloc_1_2_bits_is_miss(io_msAlloc_1_2_bits_is_miss),
    .io_msAlloc_1_2_bits_is_prefetch(io_msAlloc_1_2_bits_is_prefetch),
    .io_msAlloc_1_3_valid(io_msAlloc_1_3_valid),
    .io_msAlloc_1_3_bits_channel(io_msAlloc_1_3_bits_channel),
    .io_msAlloc_1_3_bits_is_miss(io_msAlloc_1_3_bits_is_miss),
    .io_msAlloc_1_3_bits_is_prefetch(io_msAlloc_1_3_bits_is_prefetch),
    .io_msAlloc_1_4_valid(io_msAlloc_1_4_valid),
    .io_msAlloc_1_4_bits_channel(io_msAlloc_1_4_bits_channel),
    .io_msAlloc_1_4_bits_is_miss(io_msAlloc_1_4_bits_is_miss),
    .io_msAlloc_1_4_bits_is_prefetch(io_msAlloc_1_4_bits_is_prefetch),
    .io_msAlloc_1_5_valid(io_msAlloc_1_5_valid),
    .io_msAlloc_1_5_bits_channel(io_msAlloc_1_5_bits_channel),
    .io_msAlloc_1_5_bits_is_miss(io_msAlloc_1_5_bits_is_miss),
    .io_msAlloc_1_5_bits_is_prefetch(io_msAlloc_1_5_bits_is_prefetch),
    .io_msAlloc_1_6_valid(io_msAlloc_1_6_valid),
    .io_msAlloc_1_6_bits_channel(io_msAlloc_1_6_bits_channel),
    .io_msAlloc_1_6_bits_is_miss(io_msAlloc_1_6_bits_is_miss),
    .io_msAlloc_1_6_bits_is_prefetch(io_msAlloc_1_6_bits_is_prefetch),
    .io_msAlloc_1_7_valid(io_msAlloc_1_7_valid),
    .io_msAlloc_1_7_bits_channel(io_msAlloc_1_7_bits_channel),
    .io_msAlloc_1_7_bits_is_miss(io_msAlloc_1_7_bits_is_miss),
    .io_msAlloc_1_7_bits_is_prefetch(io_msAlloc_1_7_bits_is_prefetch),
    .io_msAlloc_1_8_valid(io_msAlloc_1_8_valid),
    .io_msAlloc_1_8_bits_channel(io_msAlloc_1_8_bits_channel),
    .io_msAlloc_1_8_bits_is_miss(io_msAlloc_1_8_bits_is_miss),
    .io_msAlloc_1_8_bits_is_prefetch(io_msAlloc_1_8_bits_is_prefetch),
    .io_msAlloc_1_9_valid(io_msAlloc_1_9_valid),
    .io_msAlloc_1_9_bits_channel(io_msAlloc_1_9_bits_channel),
    .io_msAlloc_1_9_bits_is_miss(io_msAlloc_1_9_bits_is_miss),
    .io_msAlloc_1_9_bits_is_prefetch(io_msAlloc_1_9_bits_is_prefetch),
    .io_msAlloc_1_10_valid(io_msAlloc_1_10_valid),
    .io_msAlloc_1_10_bits_channel(io_msAlloc_1_10_bits_channel),
    .io_msAlloc_1_10_bits_is_miss(io_msAlloc_1_10_bits_is_miss),
    .io_msAlloc_1_10_bits_is_prefetch(io_msAlloc_1_10_bits_is_prefetch),
    .io_msAlloc_1_11_valid(io_msAlloc_1_11_valid),
    .io_msAlloc_1_11_bits_channel(io_msAlloc_1_11_bits_channel),
    .io_msAlloc_1_11_bits_is_miss(io_msAlloc_1_11_bits_is_miss),
    .io_msAlloc_1_11_bits_is_prefetch(io_msAlloc_1_11_bits_is_prefetch),
    .io_msAlloc_1_12_valid(io_msAlloc_1_12_valid),
    .io_msAlloc_1_12_bits_channel(io_msAlloc_1_12_bits_channel),
    .io_msAlloc_1_12_bits_is_miss(io_msAlloc_1_12_bits_is_miss),
    .io_msAlloc_1_12_bits_is_prefetch(io_msAlloc_1_12_bits_is_prefetch),
    .io_msAlloc_1_13_valid(io_msAlloc_1_13_valid),
    .io_msAlloc_1_13_bits_channel(io_msAlloc_1_13_bits_channel),
    .io_msAlloc_1_13_bits_is_miss(io_msAlloc_1_13_bits_is_miss),
    .io_msAlloc_1_13_bits_is_prefetch(io_msAlloc_1_13_bits_is_prefetch),
    .io_msAlloc_1_14_valid(io_msAlloc_1_14_valid),
    .io_msAlloc_1_14_bits_channel(io_msAlloc_1_14_bits_channel),
    .io_msAlloc_1_14_bits_is_miss(io_msAlloc_1_14_bits_is_miss),
    .io_msAlloc_1_14_bits_is_prefetch(io_msAlloc_1_14_bits_is_prefetch),
    .io_msAlloc_1_15_valid(io_msAlloc_1_15_valid),
    .io_msAlloc_1_15_bits_channel(io_msAlloc_1_15_bits_channel),
    .io_msAlloc_1_15_bits_is_miss(io_msAlloc_1_15_bits_is_miss),
    .io_msAlloc_1_15_bits_is_prefetch(io_msAlloc_1_15_bits_is_prefetch),
    .io_msAlloc_2_0_valid(io_msAlloc_2_0_valid),
    .io_msAlloc_2_0_bits_channel(io_msAlloc_2_0_bits_channel),
    .io_msAlloc_2_0_bits_is_miss(io_msAlloc_2_0_bits_is_miss),
    .io_msAlloc_2_0_bits_is_prefetch(io_msAlloc_2_0_bits_is_prefetch),
    .io_msAlloc_2_1_valid(io_msAlloc_2_1_valid),
    .io_msAlloc_2_1_bits_channel(io_msAlloc_2_1_bits_channel),
    .io_msAlloc_2_1_bits_is_miss(io_msAlloc_2_1_bits_is_miss),
    .io_msAlloc_2_1_bits_is_prefetch(io_msAlloc_2_1_bits_is_prefetch),
    .io_msAlloc_2_2_valid(io_msAlloc_2_2_valid),
    .io_msAlloc_2_2_bits_channel(io_msAlloc_2_2_bits_channel),
    .io_msAlloc_2_2_bits_is_miss(io_msAlloc_2_2_bits_is_miss),
    .io_msAlloc_2_2_bits_is_prefetch(io_msAlloc_2_2_bits_is_prefetch),
    .io_msAlloc_2_3_valid(io_msAlloc_2_3_valid),
    .io_msAlloc_2_3_bits_channel(io_msAlloc_2_3_bits_channel),
    .io_msAlloc_2_3_bits_is_miss(io_msAlloc_2_3_bits_is_miss),
    .io_msAlloc_2_3_bits_is_prefetch(io_msAlloc_2_3_bits_is_prefetch),
    .io_msAlloc_2_4_valid(io_msAlloc_2_4_valid),
    .io_msAlloc_2_4_bits_channel(io_msAlloc_2_4_bits_channel),
    .io_msAlloc_2_4_bits_is_miss(io_msAlloc_2_4_bits_is_miss),
    .io_msAlloc_2_4_bits_is_prefetch(io_msAlloc_2_4_bits_is_prefetch),
    .io_msAlloc_2_5_valid(io_msAlloc_2_5_valid),
    .io_msAlloc_2_5_bits_channel(io_msAlloc_2_5_bits_channel),
    .io_msAlloc_2_5_bits_is_miss(io_msAlloc_2_5_bits_is_miss),
    .io_msAlloc_2_5_bits_is_prefetch(io_msAlloc_2_5_bits_is_prefetch),
    .io_msAlloc_2_6_valid(io_msAlloc_2_6_valid),
    .io_msAlloc_2_6_bits_channel(io_msAlloc_2_6_bits_channel),
    .io_msAlloc_2_6_bits_is_miss(io_msAlloc_2_6_bits_is_miss),
    .io_msAlloc_2_6_bits_is_prefetch(io_msAlloc_2_6_bits_is_prefetch),
    .io_msAlloc_2_7_valid(io_msAlloc_2_7_valid),
    .io_msAlloc_2_7_bits_channel(io_msAlloc_2_7_bits_channel),
    .io_msAlloc_2_7_bits_is_miss(io_msAlloc_2_7_bits_is_miss),
    .io_msAlloc_2_7_bits_is_prefetch(io_msAlloc_2_7_bits_is_prefetch),
    .io_msAlloc_2_8_valid(io_msAlloc_2_8_valid),
    .io_msAlloc_2_8_bits_channel(io_msAlloc_2_8_bits_channel),
    .io_msAlloc_2_8_bits_is_miss(io_msAlloc_2_8_bits_is_miss),
    .io_msAlloc_2_8_bits_is_prefetch(io_msAlloc_2_8_bits_is_prefetch),
    .io_msAlloc_2_9_valid(io_msAlloc_2_9_valid),
    .io_msAlloc_2_9_bits_channel(io_msAlloc_2_9_bits_channel),
    .io_msAlloc_2_9_bits_is_miss(io_msAlloc_2_9_bits_is_miss),
    .io_msAlloc_2_9_bits_is_prefetch(io_msAlloc_2_9_bits_is_prefetch),
    .io_msAlloc_2_10_valid(io_msAlloc_2_10_valid),
    .io_msAlloc_2_10_bits_channel(io_msAlloc_2_10_bits_channel),
    .io_msAlloc_2_10_bits_is_miss(io_msAlloc_2_10_bits_is_miss),
    .io_msAlloc_2_10_bits_is_prefetch(io_msAlloc_2_10_bits_is_prefetch),
    .io_msAlloc_2_11_valid(io_msAlloc_2_11_valid),
    .io_msAlloc_2_11_bits_channel(io_msAlloc_2_11_bits_channel),
    .io_msAlloc_2_11_bits_is_miss(io_msAlloc_2_11_bits_is_miss),
    .io_msAlloc_2_11_bits_is_prefetch(io_msAlloc_2_11_bits_is_prefetch),
    .io_msAlloc_2_12_valid(io_msAlloc_2_12_valid),
    .io_msAlloc_2_12_bits_channel(io_msAlloc_2_12_bits_channel),
    .io_msAlloc_2_12_bits_is_miss(io_msAlloc_2_12_bits_is_miss),
    .io_msAlloc_2_12_bits_is_prefetch(io_msAlloc_2_12_bits_is_prefetch),
    .io_msAlloc_2_13_valid(io_msAlloc_2_13_valid),
    .io_msAlloc_2_13_bits_channel(io_msAlloc_2_13_bits_channel),
    .io_msAlloc_2_13_bits_is_miss(io_msAlloc_2_13_bits_is_miss),
    .io_msAlloc_2_13_bits_is_prefetch(io_msAlloc_2_13_bits_is_prefetch),
    .io_msAlloc_2_14_valid(io_msAlloc_2_14_valid),
    .io_msAlloc_2_14_bits_channel(io_msAlloc_2_14_bits_channel),
    .io_msAlloc_2_14_bits_is_miss(io_msAlloc_2_14_bits_is_miss),
    .io_msAlloc_2_14_bits_is_prefetch(io_msAlloc_2_14_bits_is_prefetch),
    .io_msAlloc_2_15_valid(io_msAlloc_2_15_valid),
    .io_msAlloc_2_15_bits_channel(io_msAlloc_2_15_bits_channel),
    .io_msAlloc_2_15_bits_is_miss(io_msAlloc_2_15_bits_is_miss),
    .io_msAlloc_2_15_bits_is_prefetch(io_msAlloc_2_15_bits_is_prefetch),
    .io_msAlloc_3_0_valid(io_msAlloc_3_0_valid),
    .io_msAlloc_3_0_bits_channel(io_msAlloc_3_0_bits_channel),
    .io_msAlloc_3_0_bits_is_miss(io_msAlloc_3_0_bits_is_miss),
    .io_msAlloc_3_0_bits_is_prefetch(io_msAlloc_3_0_bits_is_prefetch),
    .io_msAlloc_3_1_valid(io_msAlloc_3_1_valid),
    .io_msAlloc_3_1_bits_channel(io_msAlloc_3_1_bits_channel),
    .io_msAlloc_3_1_bits_is_miss(io_msAlloc_3_1_bits_is_miss),
    .io_msAlloc_3_1_bits_is_prefetch(io_msAlloc_3_1_bits_is_prefetch),
    .io_msAlloc_3_2_valid(io_msAlloc_3_2_valid),
    .io_msAlloc_3_2_bits_channel(io_msAlloc_3_2_bits_channel),
    .io_msAlloc_3_2_bits_is_miss(io_msAlloc_3_2_bits_is_miss),
    .io_msAlloc_3_2_bits_is_prefetch(io_msAlloc_3_2_bits_is_prefetch),
    .io_msAlloc_3_3_valid(io_msAlloc_3_3_valid),
    .io_msAlloc_3_3_bits_channel(io_msAlloc_3_3_bits_channel),
    .io_msAlloc_3_3_bits_is_miss(io_msAlloc_3_3_bits_is_miss),
    .io_msAlloc_3_3_bits_is_prefetch(io_msAlloc_3_3_bits_is_prefetch),
    .io_msAlloc_3_4_valid(io_msAlloc_3_4_valid),
    .io_msAlloc_3_4_bits_channel(io_msAlloc_3_4_bits_channel),
    .io_msAlloc_3_4_bits_is_miss(io_msAlloc_3_4_bits_is_miss),
    .io_msAlloc_3_4_bits_is_prefetch(io_msAlloc_3_4_bits_is_prefetch),
    .io_msAlloc_3_5_valid(io_msAlloc_3_5_valid),
    .io_msAlloc_3_5_bits_channel(io_msAlloc_3_5_bits_channel),
    .io_msAlloc_3_5_bits_is_miss(io_msAlloc_3_5_bits_is_miss),
    .io_msAlloc_3_5_bits_is_prefetch(io_msAlloc_3_5_bits_is_prefetch),
    .io_msAlloc_3_6_valid(io_msAlloc_3_6_valid),
    .io_msAlloc_3_6_bits_channel(io_msAlloc_3_6_bits_channel),
    .io_msAlloc_3_6_bits_is_miss(io_msAlloc_3_6_bits_is_miss),
    .io_msAlloc_3_6_bits_is_prefetch(io_msAlloc_3_6_bits_is_prefetch),
    .io_msAlloc_3_7_valid(io_msAlloc_3_7_valid),
    .io_msAlloc_3_7_bits_channel(io_msAlloc_3_7_bits_channel),
    .io_msAlloc_3_7_bits_is_miss(io_msAlloc_3_7_bits_is_miss),
    .io_msAlloc_3_7_bits_is_prefetch(io_msAlloc_3_7_bits_is_prefetch),
    .io_msAlloc_3_8_valid(io_msAlloc_3_8_valid),
    .io_msAlloc_3_8_bits_channel(io_msAlloc_3_8_bits_channel),
    .io_msAlloc_3_8_bits_is_miss(io_msAlloc_3_8_bits_is_miss),
    .io_msAlloc_3_8_bits_is_prefetch(io_msAlloc_3_8_bits_is_prefetch),
    .io_msAlloc_3_9_valid(io_msAlloc_3_9_valid),
    .io_msAlloc_3_9_bits_channel(io_msAlloc_3_9_bits_channel),
    .io_msAlloc_3_9_bits_is_miss(io_msAlloc_3_9_bits_is_miss),
    .io_msAlloc_3_9_bits_is_prefetch(io_msAlloc_3_9_bits_is_prefetch),
    .io_msAlloc_3_10_valid(io_msAlloc_3_10_valid),
    .io_msAlloc_3_10_bits_channel(io_msAlloc_3_10_bits_channel),
    .io_msAlloc_3_10_bits_is_miss(io_msAlloc_3_10_bits_is_miss),
    .io_msAlloc_3_10_bits_is_prefetch(io_msAlloc_3_10_bits_is_prefetch),
    .io_msAlloc_3_11_valid(io_msAlloc_3_11_valid),
    .io_msAlloc_3_11_bits_channel(io_msAlloc_3_11_bits_channel),
    .io_msAlloc_3_11_bits_is_miss(io_msAlloc_3_11_bits_is_miss),
    .io_msAlloc_3_11_bits_is_prefetch(io_msAlloc_3_11_bits_is_prefetch),
    .io_msAlloc_3_12_valid(io_msAlloc_3_12_valid),
    .io_msAlloc_3_12_bits_channel(io_msAlloc_3_12_bits_channel),
    .io_msAlloc_3_12_bits_is_miss(io_msAlloc_3_12_bits_is_miss),
    .io_msAlloc_3_12_bits_is_prefetch(io_msAlloc_3_12_bits_is_prefetch),
    .io_msAlloc_3_13_valid(io_msAlloc_3_13_valid),
    .io_msAlloc_3_13_bits_channel(io_msAlloc_3_13_bits_channel),
    .io_msAlloc_3_13_bits_is_miss(io_msAlloc_3_13_bits_is_miss),
    .io_msAlloc_3_13_bits_is_prefetch(io_msAlloc_3_13_bits_is_prefetch),
    .io_msAlloc_3_14_valid(io_msAlloc_3_14_valid),
    .io_msAlloc_3_14_bits_channel(io_msAlloc_3_14_bits_channel),
    .io_msAlloc_3_14_bits_is_miss(io_msAlloc_3_14_bits_is_miss),
    .io_msAlloc_3_14_bits_is_prefetch(io_msAlloc_3_14_bits_is_prefetch),
    .io_msAlloc_3_15_valid(io_msAlloc_3_15_valid),
    .io_msAlloc_3_15_bits_channel(io_msAlloc_3_15_bits_channel),
    .io_msAlloc_3_15_bits_is_miss(io_msAlloc_3_15_bits_is_miss),
    .io_msAlloc_3_15_bits_is_prefetch(io_msAlloc_3_15_bits_is_prefetch),
    .io_hitPfInMSHR_0_valid(io_hitPfInMSHR_0_valid),
    .io_hitPfInMSHR_0_bits(io_hitPfInMSHR_0_bits),
    .io_hitPfInMSHR_1_valid(io_hitPfInMSHR_1_valid),
    .io_hitPfInMSHR_1_bits(io_hitPfInMSHR_1_bits),
    .io_hitPfInMSHR_2_valid(io_hitPfInMSHR_2_valid),
    .io_hitPfInMSHR_2_bits(io_hitPfInMSHR_2_bits),
    .io_hitPfInMSHR_3_valid(io_hitPfInMSHR_3_valid),
    .io_hitPfInMSHR_3_bits(io_hitPfInMSHR_3_bits),
    .io_pfSent_0_valid(io_pfSent_0_valid),
    .io_pfSent_0_bits(io_pfSent_0_bits),
    .io_pfSent_1_valid(io_pfSent_1_valid),
    .io_pfSent_1_bits(io_pfSent_1_bits),
    .io_pfSent_2_valid(io_pfSent_2_valid),
    .io_pfSent_2_bits(io_pfSent_2_bits),
    .io_pfSent_3_valid(io_pfSent_3_valid),
    .io_pfSent_3_bits(io_pfSent_3_bits),
    .io_pfLateInMSHR_0_valid(io_pfLateInMSHR_0_valid),
    .io_pfLateInMSHR_0_bits(io_pfLateInMSHR_0_bits),
    .io_pfLateInMSHR_1_valid(io_pfLateInMSHR_1_valid),
    .io_pfLateInMSHR_1_bits(io_pfLateInMSHR_1_bits),
    .io_pfLateInMSHR_2_valid(io_pfLateInMSHR_2_valid),
    .io_pfLateInMSHR_2_bits(io_pfLateInMSHR_2_bits),
    .io_pfLateInMSHR_3_valid(io_pfLateInMSHR_3_valid),
    .io_pfLateInMSHR_3_bits(io_pfLateInMSHR_3_bits),
    .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch(g_out)
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
    .io_msAlloc_0_0_valid(io_msAlloc_0_0_valid),
    .io_msAlloc_0_0_bits_channel(io_msAlloc_0_0_bits_channel),
    .io_msAlloc_0_0_bits_is_miss(io_msAlloc_0_0_bits_is_miss),
    .io_msAlloc_0_0_bits_is_prefetch(io_msAlloc_0_0_bits_is_prefetch),
    .io_msAlloc_0_1_valid(io_msAlloc_0_1_valid),
    .io_msAlloc_0_1_bits_channel(io_msAlloc_0_1_bits_channel),
    .io_msAlloc_0_1_bits_is_miss(io_msAlloc_0_1_bits_is_miss),
    .io_msAlloc_0_1_bits_is_prefetch(io_msAlloc_0_1_bits_is_prefetch),
    .io_msAlloc_0_2_valid(io_msAlloc_0_2_valid),
    .io_msAlloc_0_2_bits_channel(io_msAlloc_0_2_bits_channel),
    .io_msAlloc_0_2_bits_is_miss(io_msAlloc_0_2_bits_is_miss),
    .io_msAlloc_0_2_bits_is_prefetch(io_msAlloc_0_2_bits_is_prefetch),
    .io_msAlloc_0_3_valid(io_msAlloc_0_3_valid),
    .io_msAlloc_0_3_bits_channel(io_msAlloc_0_3_bits_channel),
    .io_msAlloc_0_3_bits_is_miss(io_msAlloc_0_3_bits_is_miss),
    .io_msAlloc_0_3_bits_is_prefetch(io_msAlloc_0_3_bits_is_prefetch),
    .io_msAlloc_0_4_valid(io_msAlloc_0_4_valid),
    .io_msAlloc_0_4_bits_channel(io_msAlloc_0_4_bits_channel),
    .io_msAlloc_0_4_bits_is_miss(io_msAlloc_0_4_bits_is_miss),
    .io_msAlloc_0_4_bits_is_prefetch(io_msAlloc_0_4_bits_is_prefetch),
    .io_msAlloc_0_5_valid(io_msAlloc_0_5_valid),
    .io_msAlloc_0_5_bits_channel(io_msAlloc_0_5_bits_channel),
    .io_msAlloc_0_5_bits_is_miss(io_msAlloc_0_5_bits_is_miss),
    .io_msAlloc_0_5_bits_is_prefetch(io_msAlloc_0_5_bits_is_prefetch),
    .io_msAlloc_0_6_valid(io_msAlloc_0_6_valid),
    .io_msAlloc_0_6_bits_channel(io_msAlloc_0_6_bits_channel),
    .io_msAlloc_0_6_bits_is_miss(io_msAlloc_0_6_bits_is_miss),
    .io_msAlloc_0_6_bits_is_prefetch(io_msAlloc_0_6_bits_is_prefetch),
    .io_msAlloc_0_7_valid(io_msAlloc_0_7_valid),
    .io_msAlloc_0_7_bits_channel(io_msAlloc_0_7_bits_channel),
    .io_msAlloc_0_7_bits_is_miss(io_msAlloc_0_7_bits_is_miss),
    .io_msAlloc_0_7_bits_is_prefetch(io_msAlloc_0_7_bits_is_prefetch),
    .io_msAlloc_0_8_valid(io_msAlloc_0_8_valid),
    .io_msAlloc_0_8_bits_channel(io_msAlloc_0_8_bits_channel),
    .io_msAlloc_0_8_bits_is_miss(io_msAlloc_0_8_bits_is_miss),
    .io_msAlloc_0_8_bits_is_prefetch(io_msAlloc_0_8_bits_is_prefetch),
    .io_msAlloc_0_9_valid(io_msAlloc_0_9_valid),
    .io_msAlloc_0_9_bits_channel(io_msAlloc_0_9_bits_channel),
    .io_msAlloc_0_9_bits_is_miss(io_msAlloc_0_9_bits_is_miss),
    .io_msAlloc_0_9_bits_is_prefetch(io_msAlloc_0_9_bits_is_prefetch),
    .io_msAlloc_0_10_valid(io_msAlloc_0_10_valid),
    .io_msAlloc_0_10_bits_channel(io_msAlloc_0_10_bits_channel),
    .io_msAlloc_0_10_bits_is_miss(io_msAlloc_0_10_bits_is_miss),
    .io_msAlloc_0_10_bits_is_prefetch(io_msAlloc_0_10_bits_is_prefetch),
    .io_msAlloc_0_11_valid(io_msAlloc_0_11_valid),
    .io_msAlloc_0_11_bits_channel(io_msAlloc_0_11_bits_channel),
    .io_msAlloc_0_11_bits_is_miss(io_msAlloc_0_11_bits_is_miss),
    .io_msAlloc_0_11_bits_is_prefetch(io_msAlloc_0_11_bits_is_prefetch),
    .io_msAlloc_0_12_valid(io_msAlloc_0_12_valid),
    .io_msAlloc_0_12_bits_channel(io_msAlloc_0_12_bits_channel),
    .io_msAlloc_0_12_bits_is_miss(io_msAlloc_0_12_bits_is_miss),
    .io_msAlloc_0_12_bits_is_prefetch(io_msAlloc_0_12_bits_is_prefetch),
    .io_msAlloc_0_13_valid(io_msAlloc_0_13_valid),
    .io_msAlloc_0_13_bits_channel(io_msAlloc_0_13_bits_channel),
    .io_msAlloc_0_13_bits_is_miss(io_msAlloc_0_13_bits_is_miss),
    .io_msAlloc_0_13_bits_is_prefetch(io_msAlloc_0_13_bits_is_prefetch),
    .io_msAlloc_0_14_valid(io_msAlloc_0_14_valid),
    .io_msAlloc_0_14_bits_channel(io_msAlloc_0_14_bits_channel),
    .io_msAlloc_0_14_bits_is_miss(io_msAlloc_0_14_bits_is_miss),
    .io_msAlloc_0_14_bits_is_prefetch(io_msAlloc_0_14_bits_is_prefetch),
    .io_msAlloc_0_15_valid(io_msAlloc_0_15_valid),
    .io_msAlloc_0_15_bits_channel(io_msAlloc_0_15_bits_channel),
    .io_msAlloc_0_15_bits_is_miss(io_msAlloc_0_15_bits_is_miss),
    .io_msAlloc_0_15_bits_is_prefetch(io_msAlloc_0_15_bits_is_prefetch),
    .io_msAlloc_1_0_valid(io_msAlloc_1_0_valid),
    .io_msAlloc_1_0_bits_channel(io_msAlloc_1_0_bits_channel),
    .io_msAlloc_1_0_bits_is_miss(io_msAlloc_1_0_bits_is_miss),
    .io_msAlloc_1_0_bits_is_prefetch(io_msAlloc_1_0_bits_is_prefetch),
    .io_msAlloc_1_1_valid(io_msAlloc_1_1_valid),
    .io_msAlloc_1_1_bits_channel(io_msAlloc_1_1_bits_channel),
    .io_msAlloc_1_1_bits_is_miss(io_msAlloc_1_1_bits_is_miss),
    .io_msAlloc_1_1_bits_is_prefetch(io_msAlloc_1_1_bits_is_prefetch),
    .io_msAlloc_1_2_valid(io_msAlloc_1_2_valid),
    .io_msAlloc_1_2_bits_channel(io_msAlloc_1_2_bits_channel),
    .io_msAlloc_1_2_bits_is_miss(io_msAlloc_1_2_bits_is_miss),
    .io_msAlloc_1_2_bits_is_prefetch(io_msAlloc_1_2_bits_is_prefetch),
    .io_msAlloc_1_3_valid(io_msAlloc_1_3_valid),
    .io_msAlloc_1_3_bits_channel(io_msAlloc_1_3_bits_channel),
    .io_msAlloc_1_3_bits_is_miss(io_msAlloc_1_3_bits_is_miss),
    .io_msAlloc_1_3_bits_is_prefetch(io_msAlloc_1_3_bits_is_prefetch),
    .io_msAlloc_1_4_valid(io_msAlloc_1_4_valid),
    .io_msAlloc_1_4_bits_channel(io_msAlloc_1_4_bits_channel),
    .io_msAlloc_1_4_bits_is_miss(io_msAlloc_1_4_bits_is_miss),
    .io_msAlloc_1_4_bits_is_prefetch(io_msAlloc_1_4_bits_is_prefetch),
    .io_msAlloc_1_5_valid(io_msAlloc_1_5_valid),
    .io_msAlloc_1_5_bits_channel(io_msAlloc_1_5_bits_channel),
    .io_msAlloc_1_5_bits_is_miss(io_msAlloc_1_5_bits_is_miss),
    .io_msAlloc_1_5_bits_is_prefetch(io_msAlloc_1_5_bits_is_prefetch),
    .io_msAlloc_1_6_valid(io_msAlloc_1_6_valid),
    .io_msAlloc_1_6_bits_channel(io_msAlloc_1_6_bits_channel),
    .io_msAlloc_1_6_bits_is_miss(io_msAlloc_1_6_bits_is_miss),
    .io_msAlloc_1_6_bits_is_prefetch(io_msAlloc_1_6_bits_is_prefetch),
    .io_msAlloc_1_7_valid(io_msAlloc_1_7_valid),
    .io_msAlloc_1_7_bits_channel(io_msAlloc_1_7_bits_channel),
    .io_msAlloc_1_7_bits_is_miss(io_msAlloc_1_7_bits_is_miss),
    .io_msAlloc_1_7_bits_is_prefetch(io_msAlloc_1_7_bits_is_prefetch),
    .io_msAlloc_1_8_valid(io_msAlloc_1_8_valid),
    .io_msAlloc_1_8_bits_channel(io_msAlloc_1_8_bits_channel),
    .io_msAlloc_1_8_bits_is_miss(io_msAlloc_1_8_bits_is_miss),
    .io_msAlloc_1_8_bits_is_prefetch(io_msAlloc_1_8_bits_is_prefetch),
    .io_msAlloc_1_9_valid(io_msAlloc_1_9_valid),
    .io_msAlloc_1_9_bits_channel(io_msAlloc_1_9_bits_channel),
    .io_msAlloc_1_9_bits_is_miss(io_msAlloc_1_9_bits_is_miss),
    .io_msAlloc_1_9_bits_is_prefetch(io_msAlloc_1_9_bits_is_prefetch),
    .io_msAlloc_1_10_valid(io_msAlloc_1_10_valid),
    .io_msAlloc_1_10_bits_channel(io_msAlloc_1_10_bits_channel),
    .io_msAlloc_1_10_bits_is_miss(io_msAlloc_1_10_bits_is_miss),
    .io_msAlloc_1_10_bits_is_prefetch(io_msAlloc_1_10_bits_is_prefetch),
    .io_msAlloc_1_11_valid(io_msAlloc_1_11_valid),
    .io_msAlloc_1_11_bits_channel(io_msAlloc_1_11_bits_channel),
    .io_msAlloc_1_11_bits_is_miss(io_msAlloc_1_11_bits_is_miss),
    .io_msAlloc_1_11_bits_is_prefetch(io_msAlloc_1_11_bits_is_prefetch),
    .io_msAlloc_1_12_valid(io_msAlloc_1_12_valid),
    .io_msAlloc_1_12_bits_channel(io_msAlloc_1_12_bits_channel),
    .io_msAlloc_1_12_bits_is_miss(io_msAlloc_1_12_bits_is_miss),
    .io_msAlloc_1_12_bits_is_prefetch(io_msAlloc_1_12_bits_is_prefetch),
    .io_msAlloc_1_13_valid(io_msAlloc_1_13_valid),
    .io_msAlloc_1_13_bits_channel(io_msAlloc_1_13_bits_channel),
    .io_msAlloc_1_13_bits_is_miss(io_msAlloc_1_13_bits_is_miss),
    .io_msAlloc_1_13_bits_is_prefetch(io_msAlloc_1_13_bits_is_prefetch),
    .io_msAlloc_1_14_valid(io_msAlloc_1_14_valid),
    .io_msAlloc_1_14_bits_channel(io_msAlloc_1_14_bits_channel),
    .io_msAlloc_1_14_bits_is_miss(io_msAlloc_1_14_bits_is_miss),
    .io_msAlloc_1_14_bits_is_prefetch(io_msAlloc_1_14_bits_is_prefetch),
    .io_msAlloc_1_15_valid(io_msAlloc_1_15_valid),
    .io_msAlloc_1_15_bits_channel(io_msAlloc_1_15_bits_channel),
    .io_msAlloc_1_15_bits_is_miss(io_msAlloc_1_15_bits_is_miss),
    .io_msAlloc_1_15_bits_is_prefetch(io_msAlloc_1_15_bits_is_prefetch),
    .io_msAlloc_2_0_valid(io_msAlloc_2_0_valid),
    .io_msAlloc_2_0_bits_channel(io_msAlloc_2_0_bits_channel),
    .io_msAlloc_2_0_bits_is_miss(io_msAlloc_2_0_bits_is_miss),
    .io_msAlloc_2_0_bits_is_prefetch(io_msAlloc_2_0_bits_is_prefetch),
    .io_msAlloc_2_1_valid(io_msAlloc_2_1_valid),
    .io_msAlloc_2_1_bits_channel(io_msAlloc_2_1_bits_channel),
    .io_msAlloc_2_1_bits_is_miss(io_msAlloc_2_1_bits_is_miss),
    .io_msAlloc_2_1_bits_is_prefetch(io_msAlloc_2_1_bits_is_prefetch),
    .io_msAlloc_2_2_valid(io_msAlloc_2_2_valid),
    .io_msAlloc_2_2_bits_channel(io_msAlloc_2_2_bits_channel),
    .io_msAlloc_2_2_bits_is_miss(io_msAlloc_2_2_bits_is_miss),
    .io_msAlloc_2_2_bits_is_prefetch(io_msAlloc_2_2_bits_is_prefetch),
    .io_msAlloc_2_3_valid(io_msAlloc_2_3_valid),
    .io_msAlloc_2_3_bits_channel(io_msAlloc_2_3_bits_channel),
    .io_msAlloc_2_3_bits_is_miss(io_msAlloc_2_3_bits_is_miss),
    .io_msAlloc_2_3_bits_is_prefetch(io_msAlloc_2_3_bits_is_prefetch),
    .io_msAlloc_2_4_valid(io_msAlloc_2_4_valid),
    .io_msAlloc_2_4_bits_channel(io_msAlloc_2_4_bits_channel),
    .io_msAlloc_2_4_bits_is_miss(io_msAlloc_2_4_bits_is_miss),
    .io_msAlloc_2_4_bits_is_prefetch(io_msAlloc_2_4_bits_is_prefetch),
    .io_msAlloc_2_5_valid(io_msAlloc_2_5_valid),
    .io_msAlloc_2_5_bits_channel(io_msAlloc_2_5_bits_channel),
    .io_msAlloc_2_5_bits_is_miss(io_msAlloc_2_5_bits_is_miss),
    .io_msAlloc_2_5_bits_is_prefetch(io_msAlloc_2_5_bits_is_prefetch),
    .io_msAlloc_2_6_valid(io_msAlloc_2_6_valid),
    .io_msAlloc_2_6_bits_channel(io_msAlloc_2_6_bits_channel),
    .io_msAlloc_2_6_bits_is_miss(io_msAlloc_2_6_bits_is_miss),
    .io_msAlloc_2_6_bits_is_prefetch(io_msAlloc_2_6_bits_is_prefetch),
    .io_msAlloc_2_7_valid(io_msAlloc_2_7_valid),
    .io_msAlloc_2_7_bits_channel(io_msAlloc_2_7_bits_channel),
    .io_msAlloc_2_7_bits_is_miss(io_msAlloc_2_7_bits_is_miss),
    .io_msAlloc_2_7_bits_is_prefetch(io_msAlloc_2_7_bits_is_prefetch),
    .io_msAlloc_2_8_valid(io_msAlloc_2_8_valid),
    .io_msAlloc_2_8_bits_channel(io_msAlloc_2_8_bits_channel),
    .io_msAlloc_2_8_bits_is_miss(io_msAlloc_2_8_bits_is_miss),
    .io_msAlloc_2_8_bits_is_prefetch(io_msAlloc_2_8_bits_is_prefetch),
    .io_msAlloc_2_9_valid(io_msAlloc_2_9_valid),
    .io_msAlloc_2_9_bits_channel(io_msAlloc_2_9_bits_channel),
    .io_msAlloc_2_9_bits_is_miss(io_msAlloc_2_9_bits_is_miss),
    .io_msAlloc_2_9_bits_is_prefetch(io_msAlloc_2_9_bits_is_prefetch),
    .io_msAlloc_2_10_valid(io_msAlloc_2_10_valid),
    .io_msAlloc_2_10_bits_channel(io_msAlloc_2_10_bits_channel),
    .io_msAlloc_2_10_bits_is_miss(io_msAlloc_2_10_bits_is_miss),
    .io_msAlloc_2_10_bits_is_prefetch(io_msAlloc_2_10_bits_is_prefetch),
    .io_msAlloc_2_11_valid(io_msAlloc_2_11_valid),
    .io_msAlloc_2_11_bits_channel(io_msAlloc_2_11_bits_channel),
    .io_msAlloc_2_11_bits_is_miss(io_msAlloc_2_11_bits_is_miss),
    .io_msAlloc_2_11_bits_is_prefetch(io_msAlloc_2_11_bits_is_prefetch),
    .io_msAlloc_2_12_valid(io_msAlloc_2_12_valid),
    .io_msAlloc_2_12_bits_channel(io_msAlloc_2_12_bits_channel),
    .io_msAlloc_2_12_bits_is_miss(io_msAlloc_2_12_bits_is_miss),
    .io_msAlloc_2_12_bits_is_prefetch(io_msAlloc_2_12_bits_is_prefetch),
    .io_msAlloc_2_13_valid(io_msAlloc_2_13_valid),
    .io_msAlloc_2_13_bits_channel(io_msAlloc_2_13_bits_channel),
    .io_msAlloc_2_13_bits_is_miss(io_msAlloc_2_13_bits_is_miss),
    .io_msAlloc_2_13_bits_is_prefetch(io_msAlloc_2_13_bits_is_prefetch),
    .io_msAlloc_2_14_valid(io_msAlloc_2_14_valid),
    .io_msAlloc_2_14_bits_channel(io_msAlloc_2_14_bits_channel),
    .io_msAlloc_2_14_bits_is_miss(io_msAlloc_2_14_bits_is_miss),
    .io_msAlloc_2_14_bits_is_prefetch(io_msAlloc_2_14_bits_is_prefetch),
    .io_msAlloc_2_15_valid(io_msAlloc_2_15_valid),
    .io_msAlloc_2_15_bits_channel(io_msAlloc_2_15_bits_channel),
    .io_msAlloc_2_15_bits_is_miss(io_msAlloc_2_15_bits_is_miss),
    .io_msAlloc_2_15_bits_is_prefetch(io_msAlloc_2_15_bits_is_prefetch),
    .io_msAlloc_3_0_valid(io_msAlloc_3_0_valid),
    .io_msAlloc_3_0_bits_channel(io_msAlloc_3_0_bits_channel),
    .io_msAlloc_3_0_bits_is_miss(io_msAlloc_3_0_bits_is_miss),
    .io_msAlloc_3_0_bits_is_prefetch(io_msAlloc_3_0_bits_is_prefetch),
    .io_msAlloc_3_1_valid(io_msAlloc_3_1_valid),
    .io_msAlloc_3_1_bits_channel(io_msAlloc_3_1_bits_channel),
    .io_msAlloc_3_1_bits_is_miss(io_msAlloc_3_1_bits_is_miss),
    .io_msAlloc_3_1_bits_is_prefetch(io_msAlloc_3_1_bits_is_prefetch),
    .io_msAlloc_3_2_valid(io_msAlloc_3_2_valid),
    .io_msAlloc_3_2_bits_channel(io_msAlloc_3_2_bits_channel),
    .io_msAlloc_3_2_bits_is_miss(io_msAlloc_3_2_bits_is_miss),
    .io_msAlloc_3_2_bits_is_prefetch(io_msAlloc_3_2_bits_is_prefetch),
    .io_msAlloc_3_3_valid(io_msAlloc_3_3_valid),
    .io_msAlloc_3_3_bits_channel(io_msAlloc_3_3_bits_channel),
    .io_msAlloc_3_3_bits_is_miss(io_msAlloc_3_3_bits_is_miss),
    .io_msAlloc_3_3_bits_is_prefetch(io_msAlloc_3_3_bits_is_prefetch),
    .io_msAlloc_3_4_valid(io_msAlloc_3_4_valid),
    .io_msAlloc_3_4_bits_channel(io_msAlloc_3_4_bits_channel),
    .io_msAlloc_3_4_bits_is_miss(io_msAlloc_3_4_bits_is_miss),
    .io_msAlloc_3_4_bits_is_prefetch(io_msAlloc_3_4_bits_is_prefetch),
    .io_msAlloc_3_5_valid(io_msAlloc_3_5_valid),
    .io_msAlloc_3_5_bits_channel(io_msAlloc_3_5_bits_channel),
    .io_msAlloc_3_5_bits_is_miss(io_msAlloc_3_5_bits_is_miss),
    .io_msAlloc_3_5_bits_is_prefetch(io_msAlloc_3_5_bits_is_prefetch),
    .io_msAlloc_3_6_valid(io_msAlloc_3_6_valid),
    .io_msAlloc_3_6_bits_channel(io_msAlloc_3_6_bits_channel),
    .io_msAlloc_3_6_bits_is_miss(io_msAlloc_3_6_bits_is_miss),
    .io_msAlloc_3_6_bits_is_prefetch(io_msAlloc_3_6_bits_is_prefetch),
    .io_msAlloc_3_7_valid(io_msAlloc_3_7_valid),
    .io_msAlloc_3_7_bits_channel(io_msAlloc_3_7_bits_channel),
    .io_msAlloc_3_7_bits_is_miss(io_msAlloc_3_7_bits_is_miss),
    .io_msAlloc_3_7_bits_is_prefetch(io_msAlloc_3_7_bits_is_prefetch),
    .io_msAlloc_3_8_valid(io_msAlloc_3_8_valid),
    .io_msAlloc_3_8_bits_channel(io_msAlloc_3_8_bits_channel),
    .io_msAlloc_3_8_bits_is_miss(io_msAlloc_3_8_bits_is_miss),
    .io_msAlloc_3_8_bits_is_prefetch(io_msAlloc_3_8_bits_is_prefetch),
    .io_msAlloc_3_9_valid(io_msAlloc_3_9_valid),
    .io_msAlloc_3_9_bits_channel(io_msAlloc_3_9_bits_channel),
    .io_msAlloc_3_9_bits_is_miss(io_msAlloc_3_9_bits_is_miss),
    .io_msAlloc_3_9_bits_is_prefetch(io_msAlloc_3_9_bits_is_prefetch),
    .io_msAlloc_3_10_valid(io_msAlloc_3_10_valid),
    .io_msAlloc_3_10_bits_channel(io_msAlloc_3_10_bits_channel),
    .io_msAlloc_3_10_bits_is_miss(io_msAlloc_3_10_bits_is_miss),
    .io_msAlloc_3_10_bits_is_prefetch(io_msAlloc_3_10_bits_is_prefetch),
    .io_msAlloc_3_11_valid(io_msAlloc_3_11_valid),
    .io_msAlloc_3_11_bits_channel(io_msAlloc_3_11_bits_channel),
    .io_msAlloc_3_11_bits_is_miss(io_msAlloc_3_11_bits_is_miss),
    .io_msAlloc_3_11_bits_is_prefetch(io_msAlloc_3_11_bits_is_prefetch),
    .io_msAlloc_3_12_valid(io_msAlloc_3_12_valid),
    .io_msAlloc_3_12_bits_channel(io_msAlloc_3_12_bits_channel),
    .io_msAlloc_3_12_bits_is_miss(io_msAlloc_3_12_bits_is_miss),
    .io_msAlloc_3_12_bits_is_prefetch(io_msAlloc_3_12_bits_is_prefetch),
    .io_msAlloc_3_13_valid(io_msAlloc_3_13_valid),
    .io_msAlloc_3_13_bits_channel(io_msAlloc_3_13_bits_channel),
    .io_msAlloc_3_13_bits_is_miss(io_msAlloc_3_13_bits_is_miss),
    .io_msAlloc_3_13_bits_is_prefetch(io_msAlloc_3_13_bits_is_prefetch),
    .io_msAlloc_3_14_valid(io_msAlloc_3_14_valid),
    .io_msAlloc_3_14_bits_channel(io_msAlloc_3_14_bits_channel),
    .io_msAlloc_3_14_bits_is_miss(io_msAlloc_3_14_bits_is_miss),
    .io_msAlloc_3_14_bits_is_prefetch(io_msAlloc_3_14_bits_is_prefetch),
    .io_msAlloc_3_15_valid(io_msAlloc_3_15_valid),
    .io_msAlloc_3_15_bits_channel(io_msAlloc_3_15_bits_channel),
    .io_msAlloc_3_15_bits_is_miss(io_msAlloc_3_15_bits_is_miss),
    .io_msAlloc_3_15_bits_is_prefetch(io_msAlloc_3_15_bits_is_prefetch),
    .io_hitPfInMSHR_0_valid(io_hitPfInMSHR_0_valid),
    .io_hitPfInMSHR_0_bits(io_hitPfInMSHR_0_bits),
    .io_hitPfInMSHR_1_valid(io_hitPfInMSHR_1_valid),
    .io_hitPfInMSHR_1_bits(io_hitPfInMSHR_1_bits),
    .io_hitPfInMSHR_2_valid(io_hitPfInMSHR_2_valid),
    .io_hitPfInMSHR_2_bits(io_hitPfInMSHR_2_bits),
    .io_hitPfInMSHR_3_valid(io_hitPfInMSHR_3_valid),
    .io_hitPfInMSHR_3_bits(io_hitPfInMSHR_3_bits),
    .io_pfSent_0_valid(io_pfSent_0_valid),
    .io_pfSent_0_bits(io_pfSent_0_bits),
    .io_pfSent_1_valid(io_pfSent_1_valid),
    .io_pfSent_1_bits(io_pfSent_1_bits),
    .io_pfSent_2_valid(io_pfSent_2_valid),
    .io_pfSent_2_bits(io_pfSent_2_bits),
    .io_pfSent_3_valid(io_pfSent_3_valid),
    .io_pfSent_3_bits(io_pfSent_3_bits),
    .io_pfLateInMSHR_0_valid(io_pfLateInMSHR_0_valid),
    .io_pfLateInMSHR_0_bits(io_pfLateInMSHR_0_bits),
    .io_pfLateInMSHR_1_valid(io_pfLateInMSHR_1_valid),
    .io_pfLateInMSHR_1_bits(io_pfLateInMSHR_1_bits),
    .io_pfLateInMSHR_2_valid(io_pfLateInMSHR_2_valid),
    .io_pfLateInMSHR_2_bits(io_pfLateInMSHR_2_bits),
    .io_pfLateInMSHR_3_valid(io_pfLateInMSHR_3_valid),
    .io_pfLateInMSHR_3_bits(io_pfLateInMSHR_3_bits),
    .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch(i_out)
  );
  int hit_cnt = 0, hit_pos [4][16];

  task automatic drive();
    io_dirResult_0_valid = 1'($urandom);
    io_dirResult_0_bits_hit = 1'($urandom);
    io_dirResult_0_bits_meta_prefetch = 1'($urandom);
    io_dirResult_0_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_0_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_0_bits_replacerInfo_reqSource = 5'($urandom);
    io_dirResult_1_valid = 1'($urandom);
    io_dirResult_1_bits_hit = 1'($urandom);
    io_dirResult_1_bits_meta_prefetch = 1'($urandom);
    io_dirResult_1_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_1_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_1_bits_replacerInfo_reqSource = 5'($urandom);
    io_dirResult_2_valid = 1'($urandom);
    io_dirResult_2_bits_hit = 1'($urandom);
    io_dirResult_2_bits_meta_prefetch = 1'($urandom);
    io_dirResult_2_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_2_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_2_bits_replacerInfo_reqSource = 5'($urandom);
    io_dirResult_3_valid = 1'($urandom);
    io_dirResult_3_bits_hit = 1'($urandom);
    io_dirResult_3_bits_meta_prefetch = 1'($urandom);
    io_dirResult_3_bits_meta_prefetchSrc = 3'($urandom);
    io_dirResult_3_bits_replacerInfo_channel = 3'($urandom);
    io_dirResult_3_bits_replacerInfo_reqSource = 5'($urandom);
    io_msStatus_0_0_valid = 1'($urandom);
    io_msStatus_0_0_bits_channel = 3'($urandom);
    io_msStatus_0_0_bits_set = 9'($urandom);
    io_msStatus_0_0_bits_reqTag = 31'($urandom);
    io_msStatus_0_0_bits_is_miss = 1'($urandom);
    io_msStatus_0_0_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_1_valid = 1'($urandom);
    io_msStatus_0_1_bits_channel = 3'($urandom);
    io_msStatus_0_1_bits_set = 9'($urandom);
    io_msStatus_0_1_bits_reqTag = 31'($urandom);
    io_msStatus_0_1_bits_is_miss = 1'($urandom);
    io_msStatus_0_1_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_2_valid = 1'($urandom);
    io_msStatus_0_2_bits_channel = 3'($urandom);
    io_msStatus_0_2_bits_set = 9'($urandom);
    io_msStatus_0_2_bits_reqTag = 31'($urandom);
    io_msStatus_0_2_bits_is_miss = 1'($urandom);
    io_msStatus_0_2_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_3_valid = 1'($urandom);
    io_msStatus_0_3_bits_channel = 3'($urandom);
    io_msStatus_0_3_bits_set = 9'($urandom);
    io_msStatus_0_3_bits_reqTag = 31'($urandom);
    io_msStatus_0_3_bits_is_miss = 1'($urandom);
    io_msStatus_0_3_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_4_valid = 1'($urandom);
    io_msStatus_0_4_bits_channel = 3'($urandom);
    io_msStatus_0_4_bits_set = 9'($urandom);
    io_msStatus_0_4_bits_reqTag = 31'($urandom);
    io_msStatus_0_4_bits_is_miss = 1'($urandom);
    io_msStatus_0_4_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_5_valid = 1'($urandom);
    io_msStatus_0_5_bits_channel = 3'($urandom);
    io_msStatus_0_5_bits_set = 9'($urandom);
    io_msStatus_0_5_bits_reqTag = 31'($urandom);
    io_msStatus_0_5_bits_is_miss = 1'($urandom);
    io_msStatus_0_5_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_6_valid = 1'($urandom);
    io_msStatus_0_6_bits_channel = 3'($urandom);
    io_msStatus_0_6_bits_set = 9'($urandom);
    io_msStatus_0_6_bits_reqTag = 31'($urandom);
    io_msStatus_0_6_bits_is_miss = 1'($urandom);
    io_msStatus_0_6_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_7_valid = 1'($urandom);
    io_msStatus_0_7_bits_channel = 3'($urandom);
    io_msStatus_0_7_bits_set = 9'($urandom);
    io_msStatus_0_7_bits_reqTag = 31'($urandom);
    io_msStatus_0_7_bits_is_miss = 1'($urandom);
    io_msStatus_0_7_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_8_valid = 1'($urandom);
    io_msStatus_0_8_bits_channel = 3'($urandom);
    io_msStatus_0_8_bits_set = 9'($urandom);
    io_msStatus_0_8_bits_reqTag = 31'($urandom);
    io_msStatus_0_8_bits_is_miss = 1'($urandom);
    io_msStatus_0_8_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_9_valid = 1'($urandom);
    io_msStatus_0_9_bits_channel = 3'($urandom);
    io_msStatus_0_9_bits_set = 9'($urandom);
    io_msStatus_0_9_bits_reqTag = 31'($urandom);
    io_msStatus_0_9_bits_is_miss = 1'($urandom);
    io_msStatus_0_9_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_10_valid = 1'($urandom);
    io_msStatus_0_10_bits_channel = 3'($urandom);
    io_msStatus_0_10_bits_set = 9'($urandom);
    io_msStatus_0_10_bits_reqTag = 31'($urandom);
    io_msStatus_0_10_bits_is_miss = 1'($urandom);
    io_msStatus_0_10_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_11_valid = 1'($urandom);
    io_msStatus_0_11_bits_channel = 3'($urandom);
    io_msStatus_0_11_bits_set = 9'($urandom);
    io_msStatus_0_11_bits_reqTag = 31'($urandom);
    io_msStatus_0_11_bits_is_miss = 1'($urandom);
    io_msStatus_0_11_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_12_valid = 1'($urandom);
    io_msStatus_0_12_bits_channel = 3'($urandom);
    io_msStatus_0_12_bits_set = 9'($urandom);
    io_msStatus_0_12_bits_reqTag = 31'($urandom);
    io_msStatus_0_12_bits_is_miss = 1'($urandom);
    io_msStatus_0_12_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_13_valid = 1'($urandom);
    io_msStatus_0_13_bits_channel = 3'($urandom);
    io_msStatus_0_13_bits_set = 9'($urandom);
    io_msStatus_0_13_bits_reqTag = 31'($urandom);
    io_msStatus_0_13_bits_is_miss = 1'($urandom);
    io_msStatus_0_13_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_14_valid = 1'($urandom);
    io_msStatus_0_14_bits_channel = 3'($urandom);
    io_msStatus_0_14_bits_set = 9'($urandom);
    io_msStatus_0_14_bits_reqTag = 31'($urandom);
    io_msStatus_0_14_bits_is_miss = 1'($urandom);
    io_msStatus_0_14_bits_is_prefetch = 1'($urandom);
    io_msStatus_0_15_valid = 1'($urandom);
    io_msStatus_0_15_bits_channel = 3'($urandom);
    io_msStatus_0_15_bits_set = 9'($urandom);
    io_msStatus_0_15_bits_reqTag = 31'($urandom);
    io_msStatus_0_15_bits_is_miss = 1'($urandom);
    io_msStatus_0_15_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_0_valid = 1'($urandom);
    io_msStatus_1_0_bits_channel = 3'($urandom);
    io_msStatus_1_0_bits_set = 9'($urandom);
    io_msStatus_1_0_bits_reqTag = 31'($urandom);
    io_msStatus_1_0_bits_is_miss = 1'($urandom);
    io_msStatus_1_0_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_1_valid = 1'($urandom);
    io_msStatus_1_1_bits_channel = 3'($urandom);
    io_msStatus_1_1_bits_set = 9'($urandom);
    io_msStatus_1_1_bits_reqTag = 31'($urandom);
    io_msStatus_1_1_bits_is_miss = 1'($urandom);
    io_msStatus_1_1_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_2_valid = 1'($urandom);
    io_msStatus_1_2_bits_channel = 3'($urandom);
    io_msStatus_1_2_bits_set = 9'($urandom);
    io_msStatus_1_2_bits_reqTag = 31'($urandom);
    io_msStatus_1_2_bits_is_miss = 1'($urandom);
    io_msStatus_1_2_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_3_valid = 1'($urandom);
    io_msStatus_1_3_bits_channel = 3'($urandom);
    io_msStatus_1_3_bits_set = 9'($urandom);
    io_msStatus_1_3_bits_reqTag = 31'($urandom);
    io_msStatus_1_3_bits_is_miss = 1'($urandom);
    io_msStatus_1_3_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_4_valid = 1'($urandom);
    io_msStatus_1_4_bits_channel = 3'($urandom);
    io_msStatus_1_4_bits_set = 9'($urandom);
    io_msStatus_1_4_bits_reqTag = 31'($urandom);
    io_msStatus_1_4_bits_is_miss = 1'($urandom);
    io_msStatus_1_4_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_5_valid = 1'($urandom);
    io_msStatus_1_5_bits_channel = 3'($urandom);
    io_msStatus_1_5_bits_set = 9'($urandom);
    io_msStatus_1_5_bits_reqTag = 31'($urandom);
    io_msStatus_1_5_bits_is_miss = 1'($urandom);
    io_msStatus_1_5_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_6_valid = 1'($urandom);
    io_msStatus_1_6_bits_channel = 3'($urandom);
    io_msStatus_1_6_bits_set = 9'($urandom);
    io_msStatus_1_6_bits_reqTag = 31'($urandom);
    io_msStatus_1_6_bits_is_miss = 1'($urandom);
    io_msStatus_1_6_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_7_valid = 1'($urandom);
    io_msStatus_1_7_bits_channel = 3'($urandom);
    io_msStatus_1_7_bits_set = 9'($urandom);
    io_msStatus_1_7_bits_reqTag = 31'($urandom);
    io_msStatus_1_7_bits_is_miss = 1'($urandom);
    io_msStatus_1_7_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_8_valid = 1'($urandom);
    io_msStatus_1_8_bits_channel = 3'($urandom);
    io_msStatus_1_8_bits_set = 9'($urandom);
    io_msStatus_1_8_bits_reqTag = 31'($urandom);
    io_msStatus_1_8_bits_is_miss = 1'($urandom);
    io_msStatus_1_8_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_9_valid = 1'($urandom);
    io_msStatus_1_9_bits_channel = 3'($urandom);
    io_msStatus_1_9_bits_set = 9'($urandom);
    io_msStatus_1_9_bits_reqTag = 31'($urandom);
    io_msStatus_1_9_bits_is_miss = 1'($urandom);
    io_msStatus_1_9_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_10_valid = 1'($urandom);
    io_msStatus_1_10_bits_channel = 3'($urandom);
    io_msStatus_1_10_bits_set = 9'($urandom);
    io_msStatus_1_10_bits_reqTag = 31'($urandom);
    io_msStatus_1_10_bits_is_miss = 1'($urandom);
    io_msStatus_1_10_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_11_valid = 1'($urandom);
    io_msStatus_1_11_bits_channel = 3'($urandom);
    io_msStatus_1_11_bits_set = 9'($urandom);
    io_msStatus_1_11_bits_reqTag = 31'($urandom);
    io_msStatus_1_11_bits_is_miss = 1'($urandom);
    io_msStatus_1_11_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_12_valid = 1'($urandom);
    io_msStatus_1_12_bits_channel = 3'($urandom);
    io_msStatus_1_12_bits_set = 9'($urandom);
    io_msStatus_1_12_bits_reqTag = 31'($urandom);
    io_msStatus_1_12_bits_is_miss = 1'($urandom);
    io_msStatus_1_12_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_13_valid = 1'($urandom);
    io_msStatus_1_13_bits_channel = 3'($urandom);
    io_msStatus_1_13_bits_set = 9'($urandom);
    io_msStatus_1_13_bits_reqTag = 31'($urandom);
    io_msStatus_1_13_bits_is_miss = 1'($urandom);
    io_msStatus_1_13_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_14_valid = 1'($urandom);
    io_msStatus_1_14_bits_channel = 3'($urandom);
    io_msStatus_1_14_bits_set = 9'($urandom);
    io_msStatus_1_14_bits_reqTag = 31'($urandom);
    io_msStatus_1_14_bits_is_miss = 1'($urandom);
    io_msStatus_1_14_bits_is_prefetch = 1'($urandom);
    io_msStatus_1_15_valid = 1'($urandom);
    io_msStatus_1_15_bits_channel = 3'($urandom);
    io_msStatus_1_15_bits_set = 9'($urandom);
    io_msStatus_1_15_bits_reqTag = 31'($urandom);
    io_msStatus_1_15_bits_is_miss = 1'($urandom);
    io_msStatus_1_15_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_0_valid = 1'($urandom);
    io_msStatus_2_0_bits_channel = 3'($urandom);
    io_msStatus_2_0_bits_set = 9'($urandom);
    io_msStatus_2_0_bits_reqTag = 31'($urandom);
    io_msStatus_2_0_bits_is_miss = 1'($urandom);
    io_msStatus_2_0_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_1_valid = 1'($urandom);
    io_msStatus_2_1_bits_channel = 3'($urandom);
    io_msStatus_2_1_bits_set = 9'($urandom);
    io_msStatus_2_1_bits_reqTag = 31'($urandom);
    io_msStatus_2_1_bits_is_miss = 1'($urandom);
    io_msStatus_2_1_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_2_valid = 1'($urandom);
    io_msStatus_2_2_bits_channel = 3'($urandom);
    io_msStatus_2_2_bits_set = 9'($urandom);
    io_msStatus_2_2_bits_reqTag = 31'($urandom);
    io_msStatus_2_2_bits_is_miss = 1'($urandom);
    io_msStatus_2_2_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_3_valid = 1'($urandom);
    io_msStatus_2_3_bits_channel = 3'($urandom);
    io_msStatus_2_3_bits_set = 9'($urandom);
    io_msStatus_2_3_bits_reqTag = 31'($urandom);
    io_msStatus_2_3_bits_is_miss = 1'($urandom);
    io_msStatus_2_3_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_4_valid = 1'($urandom);
    io_msStatus_2_4_bits_channel = 3'($urandom);
    io_msStatus_2_4_bits_set = 9'($urandom);
    io_msStatus_2_4_bits_reqTag = 31'($urandom);
    io_msStatus_2_4_bits_is_miss = 1'($urandom);
    io_msStatus_2_4_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_5_valid = 1'($urandom);
    io_msStatus_2_5_bits_channel = 3'($urandom);
    io_msStatus_2_5_bits_set = 9'($urandom);
    io_msStatus_2_5_bits_reqTag = 31'($urandom);
    io_msStatus_2_5_bits_is_miss = 1'($urandom);
    io_msStatus_2_5_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_6_valid = 1'($urandom);
    io_msStatus_2_6_bits_channel = 3'($urandom);
    io_msStatus_2_6_bits_set = 9'($urandom);
    io_msStatus_2_6_bits_reqTag = 31'($urandom);
    io_msStatus_2_6_bits_is_miss = 1'($urandom);
    io_msStatus_2_6_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_7_valid = 1'($urandom);
    io_msStatus_2_7_bits_channel = 3'($urandom);
    io_msStatus_2_7_bits_set = 9'($urandom);
    io_msStatus_2_7_bits_reqTag = 31'($urandom);
    io_msStatus_2_7_bits_is_miss = 1'($urandom);
    io_msStatus_2_7_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_8_valid = 1'($urandom);
    io_msStatus_2_8_bits_channel = 3'($urandom);
    io_msStatus_2_8_bits_set = 9'($urandom);
    io_msStatus_2_8_bits_reqTag = 31'($urandom);
    io_msStatus_2_8_bits_is_miss = 1'($urandom);
    io_msStatus_2_8_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_9_valid = 1'($urandom);
    io_msStatus_2_9_bits_channel = 3'($urandom);
    io_msStatus_2_9_bits_set = 9'($urandom);
    io_msStatus_2_9_bits_reqTag = 31'($urandom);
    io_msStatus_2_9_bits_is_miss = 1'($urandom);
    io_msStatus_2_9_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_10_valid = 1'($urandom);
    io_msStatus_2_10_bits_channel = 3'($urandom);
    io_msStatus_2_10_bits_set = 9'($urandom);
    io_msStatus_2_10_bits_reqTag = 31'($urandom);
    io_msStatus_2_10_bits_is_miss = 1'($urandom);
    io_msStatus_2_10_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_11_valid = 1'($urandom);
    io_msStatus_2_11_bits_channel = 3'($urandom);
    io_msStatus_2_11_bits_set = 9'($urandom);
    io_msStatus_2_11_bits_reqTag = 31'($urandom);
    io_msStatus_2_11_bits_is_miss = 1'($urandom);
    io_msStatus_2_11_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_12_valid = 1'($urandom);
    io_msStatus_2_12_bits_channel = 3'($urandom);
    io_msStatus_2_12_bits_set = 9'($urandom);
    io_msStatus_2_12_bits_reqTag = 31'($urandom);
    io_msStatus_2_12_bits_is_miss = 1'($urandom);
    io_msStatus_2_12_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_13_valid = 1'($urandom);
    io_msStatus_2_13_bits_channel = 3'($urandom);
    io_msStatus_2_13_bits_set = 9'($urandom);
    io_msStatus_2_13_bits_reqTag = 31'($urandom);
    io_msStatus_2_13_bits_is_miss = 1'($urandom);
    io_msStatus_2_13_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_14_valid = 1'($urandom);
    io_msStatus_2_14_bits_channel = 3'($urandom);
    io_msStatus_2_14_bits_set = 9'($urandom);
    io_msStatus_2_14_bits_reqTag = 31'($urandom);
    io_msStatus_2_14_bits_is_miss = 1'($urandom);
    io_msStatus_2_14_bits_is_prefetch = 1'($urandom);
    io_msStatus_2_15_valid = 1'($urandom);
    io_msStatus_2_15_bits_channel = 3'($urandom);
    io_msStatus_2_15_bits_set = 9'($urandom);
    io_msStatus_2_15_bits_reqTag = 31'($urandom);
    io_msStatus_2_15_bits_is_miss = 1'($urandom);
    io_msStatus_2_15_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_0_valid = 1'($urandom);
    io_msStatus_3_0_bits_channel = 3'($urandom);
    io_msStatus_3_0_bits_set = 9'($urandom);
    io_msStatus_3_0_bits_reqTag = 31'($urandom);
    io_msStatus_3_0_bits_is_miss = 1'($urandom);
    io_msStatus_3_0_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_1_valid = 1'($urandom);
    io_msStatus_3_1_bits_channel = 3'($urandom);
    io_msStatus_3_1_bits_set = 9'($urandom);
    io_msStatus_3_1_bits_reqTag = 31'($urandom);
    io_msStatus_3_1_bits_is_miss = 1'($urandom);
    io_msStatus_3_1_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_2_valid = 1'($urandom);
    io_msStatus_3_2_bits_channel = 3'($urandom);
    io_msStatus_3_2_bits_set = 9'($urandom);
    io_msStatus_3_2_bits_reqTag = 31'($urandom);
    io_msStatus_3_2_bits_is_miss = 1'($urandom);
    io_msStatus_3_2_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_3_valid = 1'($urandom);
    io_msStatus_3_3_bits_channel = 3'($urandom);
    io_msStatus_3_3_bits_set = 9'($urandom);
    io_msStatus_3_3_bits_reqTag = 31'($urandom);
    io_msStatus_3_3_bits_is_miss = 1'($urandom);
    io_msStatus_3_3_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_4_valid = 1'($urandom);
    io_msStatus_3_4_bits_channel = 3'($urandom);
    io_msStatus_3_4_bits_set = 9'($urandom);
    io_msStatus_3_4_bits_reqTag = 31'($urandom);
    io_msStatus_3_4_bits_is_miss = 1'($urandom);
    io_msStatus_3_4_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_5_valid = 1'($urandom);
    io_msStatus_3_5_bits_channel = 3'($urandom);
    io_msStatus_3_5_bits_set = 9'($urandom);
    io_msStatus_3_5_bits_reqTag = 31'($urandom);
    io_msStatus_3_5_bits_is_miss = 1'($urandom);
    io_msStatus_3_5_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_6_valid = 1'($urandom);
    io_msStatus_3_6_bits_channel = 3'($urandom);
    io_msStatus_3_6_bits_set = 9'($urandom);
    io_msStatus_3_6_bits_reqTag = 31'($urandom);
    io_msStatus_3_6_bits_is_miss = 1'($urandom);
    io_msStatus_3_6_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_7_valid = 1'($urandom);
    io_msStatus_3_7_bits_channel = 3'($urandom);
    io_msStatus_3_7_bits_set = 9'($urandom);
    io_msStatus_3_7_bits_reqTag = 31'($urandom);
    io_msStatus_3_7_bits_is_miss = 1'($urandom);
    io_msStatus_3_7_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_8_valid = 1'($urandom);
    io_msStatus_3_8_bits_channel = 3'($urandom);
    io_msStatus_3_8_bits_set = 9'($urandom);
    io_msStatus_3_8_bits_reqTag = 31'($urandom);
    io_msStatus_3_8_bits_is_miss = 1'($urandom);
    io_msStatus_3_8_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_9_valid = 1'($urandom);
    io_msStatus_3_9_bits_channel = 3'($urandom);
    io_msStatus_3_9_bits_set = 9'($urandom);
    io_msStatus_3_9_bits_reqTag = 31'($urandom);
    io_msStatus_3_9_bits_is_miss = 1'($urandom);
    io_msStatus_3_9_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_10_valid = 1'($urandom);
    io_msStatus_3_10_bits_channel = 3'($urandom);
    io_msStatus_3_10_bits_set = 9'($urandom);
    io_msStatus_3_10_bits_reqTag = 31'($urandom);
    io_msStatus_3_10_bits_is_miss = 1'($urandom);
    io_msStatus_3_10_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_11_valid = 1'($urandom);
    io_msStatus_3_11_bits_channel = 3'($urandom);
    io_msStatus_3_11_bits_set = 9'($urandom);
    io_msStatus_3_11_bits_reqTag = 31'($urandom);
    io_msStatus_3_11_bits_is_miss = 1'($urandom);
    io_msStatus_3_11_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_12_valid = 1'($urandom);
    io_msStatus_3_12_bits_channel = 3'($urandom);
    io_msStatus_3_12_bits_set = 9'($urandom);
    io_msStatus_3_12_bits_reqTag = 31'($urandom);
    io_msStatus_3_12_bits_is_miss = 1'($urandom);
    io_msStatus_3_12_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_13_valid = 1'($urandom);
    io_msStatus_3_13_bits_channel = 3'($urandom);
    io_msStatus_3_13_bits_set = 9'($urandom);
    io_msStatus_3_13_bits_reqTag = 31'($urandom);
    io_msStatus_3_13_bits_is_miss = 1'($urandom);
    io_msStatus_3_13_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_14_valid = 1'($urandom);
    io_msStatus_3_14_bits_channel = 3'($urandom);
    io_msStatus_3_14_bits_set = 9'($urandom);
    io_msStatus_3_14_bits_reqTag = 31'($urandom);
    io_msStatus_3_14_bits_is_miss = 1'($urandom);
    io_msStatus_3_14_bits_is_prefetch = 1'($urandom);
    io_msStatus_3_15_valid = 1'($urandom);
    io_msStatus_3_15_bits_channel = 3'($urandom);
    io_msStatus_3_15_bits_set = 9'($urandom);
    io_msStatus_3_15_bits_reqTag = 31'($urandom);
    io_msStatus_3_15_bits_is_miss = 1'($urandom);
    io_msStatus_3_15_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_0_valid = 1'($urandom);
    io_msAlloc_0_0_bits_channel = 3'($urandom);
    io_msAlloc_0_0_bits_is_miss = 1'($urandom);
    io_msAlloc_0_0_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_1_valid = 1'($urandom);
    io_msAlloc_0_1_bits_channel = 3'($urandom);
    io_msAlloc_0_1_bits_is_miss = 1'($urandom);
    io_msAlloc_0_1_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_2_valid = 1'($urandom);
    io_msAlloc_0_2_bits_channel = 3'($urandom);
    io_msAlloc_0_2_bits_is_miss = 1'($urandom);
    io_msAlloc_0_2_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_3_valid = 1'($urandom);
    io_msAlloc_0_3_bits_channel = 3'($urandom);
    io_msAlloc_0_3_bits_is_miss = 1'($urandom);
    io_msAlloc_0_3_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_4_valid = 1'($urandom);
    io_msAlloc_0_4_bits_channel = 3'($urandom);
    io_msAlloc_0_4_bits_is_miss = 1'($urandom);
    io_msAlloc_0_4_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_5_valid = 1'($urandom);
    io_msAlloc_0_5_bits_channel = 3'($urandom);
    io_msAlloc_0_5_bits_is_miss = 1'($urandom);
    io_msAlloc_0_5_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_6_valid = 1'($urandom);
    io_msAlloc_0_6_bits_channel = 3'($urandom);
    io_msAlloc_0_6_bits_is_miss = 1'($urandom);
    io_msAlloc_0_6_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_7_valid = 1'($urandom);
    io_msAlloc_0_7_bits_channel = 3'($urandom);
    io_msAlloc_0_7_bits_is_miss = 1'($urandom);
    io_msAlloc_0_7_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_8_valid = 1'($urandom);
    io_msAlloc_0_8_bits_channel = 3'($urandom);
    io_msAlloc_0_8_bits_is_miss = 1'($urandom);
    io_msAlloc_0_8_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_9_valid = 1'($urandom);
    io_msAlloc_0_9_bits_channel = 3'($urandom);
    io_msAlloc_0_9_bits_is_miss = 1'($urandom);
    io_msAlloc_0_9_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_10_valid = 1'($urandom);
    io_msAlloc_0_10_bits_channel = 3'($urandom);
    io_msAlloc_0_10_bits_is_miss = 1'($urandom);
    io_msAlloc_0_10_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_11_valid = 1'($urandom);
    io_msAlloc_0_11_bits_channel = 3'($urandom);
    io_msAlloc_0_11_bits_is_miss = 1'($urandom);
    io_msAlloc_0_11_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_12_valid = 1'($urandom);
    io_msAlloc_0_12_bits_channel = 3'($urandom);
    io_msAlloc_0_12_bits_is_miss = 1'($urandom);
    io_msAlloc_0_12_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_13_valid = 1'($urandom);
    io_msAlloc_0_13_bits_channel = 3'($urandom);
    io_msAlloc_0_13_bits_is_miss = 1'($urandom);
    io_msAlloc_0_13_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_14_valid = 1'($urandom);
    io_msAlloc_0_14_bits_channel = 3'($urandom);
    io_msAlloc_0_14_bits_is_miss = 1'($urandom);
    io_msAlloc_0_14_bits_is_prefetch = 1'($urandom);
    io_msAlloc_0_15_valid = 1'($urandom);
    io_msAlloc_0_15_bits_channel = 3'($urandom);
    io_msAlloc_0_15_bits_is_miss = 1'($urandom);
    io_msAlloc_0_15_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_0_valid = 1'($urandom);
    io_msAlloc_1_0_bits_channel = 3'($urandom);
    io_msAlloc_1_0_bits_is_miss = 1'($urandom);
    io_msAlloc_1_0_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_1_valid = 1'($urandom);
    io_msAlloc_1_1_bits_channel = 3'($urandom);
    io_msAlloc_1_1_bits_is_miss = 1'($urandom);
    io_msAlloc_1_1_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_2_valid = 1'($urandom);
    io_msAlloc_1_2_bits_channel = 3'($urandom);
    io_msAlloc_1_2_bits_is_miss = 1'($urandom);
    io_msAlloc_1_2_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_3_valid = 1'($urandom);
    io_msAlloc_1_3_bits_channel = 3'($urandom);
    io_msAlloc_1_3_bits_is_miss = 1'($urandom);
    io_msAlloc_1_3_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_4_valid = 1'($urandom);
    io_msAlloc_1_4_bits_channel = 3'($urandom);
    io_msAlloc_1_4_bits_is_miss = 1'($urandom);
    io_msAlloc_1_4_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_5_valid = 1'($urandom);
    io_msAlloc_1_5_bits_channel = 3'($urandom);
    io_msAlloc_1_5_bits_is_miss = 1'($urandom);
    io_msAlloc_1_5_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_6_valid = 1'($urandom);
    io_msAlloc_1_6_bits_channel = 3'($urandom);
    io_msAlloc_1_6_bits_is_miss = 1'($urandom);
    io_msAlloc_1_6_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_7_valid = 1'($urandom);
    io_msAlloc_1_7_bits_channel = 3'($urandom);
    io_msAlloc_1_7_bits_is_miss = 1'($urandom);
    io_msAlloc_1_7_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_8_valid = 1'($urandom);
    io_msAlloc_1_8_bits_channel = 3'($urandom);
    io_msAlloc_1_8_bits_is_miss = 1'($urandom);
    io_msAlloc_1_8_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_9_valid = 1'($urandom);
    io_msAlloc_1_9_bits_channel = 3'($urandom);
    io_msAlloc_1_9_bits_is_miss = 1'($urandom);
    io_msAlloc_1_9_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_10_valid = 1'($urandom);
    io_msAlloc_1_10_bits_channel = 3'($urandom);
    io_msAlloc_1_10_bits_is_miss = 1'($urandom);
    io_msAlloc_1_10_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_11_valid = 1'($urandom);
    io_msAlloc_1_11_bits_channel = 3'($urandom);
    io_msAlloc_1_11_bits_is_miss = 1'($urandom);
    io_msAlloc_1_11_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_12_valid = 1'($urandom);
    io_msAlloc_1_12_bits_channel = 3'($urandom);
    io_msAlloc_1_12_bits_is_miss = 1'($urandom);
    io_msAlloc_1_12_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_13_valid = 1'($urandom);
    io_msAlloc_1_13_bits_channel = 3'($urandom);
    io_msAlloc_1_13_bits_is_miss = 1'($urandom);
    io_msAlloc_1_13_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_14_valid = 1'($urandom);
    io_msAlloc_1_14_bits_channel = 3'($urandom);
    io_msAlloc_1_14_bits_is_miss = 1'($urandom);
    io_msAlloc_1_14_bits_is_prefetch = 1'($urandom);
    io_msAlloc_1_15_valid = 1'($urandom);
    io_msAlloc_1_15_bits_channel = 3'($urandom);
    io_msAlloc_1_15_bits_is_miss = 1'($urandom);
    io_msAlloc_1_15_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_0_valid = 1'($urandom);
    io_msAlloc_2_0_bits_channel = 3'($urandom);
    io_msAlloc_2_0_bits_is_miss = 1'($urandom);
    io_msAlloc_2_0_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_1_valid = 1'($urandom);
    io_msAlloc_2_1_bits_channel = 3'($urandom);
    io_msAlloc_2_1_bits_is_miss = 1'($urandom);
    io_msAlloc_2_1_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_2_valid = 1'($urandom);
    io_msAlloc_2_2_bits_channel = 3'($urandom);
    io_msAlloc_2_2_bits_is_miss = 1'($urandom);
    io_msAlloc_2_2_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_3_valid = 1'($urandom);
    io_msAlloc_2_3_bits_channel = 3'($urandom);
    io_msAlloc_2_3_bits_is_miss = 1'($urandom);
    io_msAlloc_2_3_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_4_valid = 1'($urandom);
    io_msAlloc_2_4_bits_channel = 3'($urandom);
    io_msAlloc_2_4_bits_is_miss = 1'($urandom);
    io_msAlloc_2_4_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_5_valid = 1'($urandom);
    io_msAlloc_2_5_bits_channel = 3'($urandom);
    io_msAlloc_2_5_bits_is_miss = 1'($urandom);
    io_msAlloc_2_5_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_6_valid = 1'($urandom);
    io_msAlloc_2_6_bits_channel = 3'($urandom);
    io_msAlloc_2_6_bits_is_miss = 1'($urandom);
    io_msAlloc_2_6_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_7_valid = 1'($urandom);
    io_msAlloc_2_7_bits_channel = 3'($urandom);
    io_msAlloc_2_7_bits_is_miss = 1'($urandom);
    io_msAlloc_2_7_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_8_valid = 1'($urandom);
    io_msAlloc_2_8_bits_channel = 3'($urandom);
    io_msAlloc_2_8_bits_is_miss = 1'($urandom);
    io_msAlloc_2_8_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_9_valid = 1'($urandom);
    io_msAlloc_2_9_bits_channel = 3'($urandom);
    io_msAlloc_2_9_bits_is_miss = 1'($urandom);
    io_msAlloc_2_9_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_10_valid = 1'($urandom);
    io_msAlloc_2_10_bits_channel = 3'($urandom);
    io_msAlloc_2_10_bits_is_miss = 1'($urandom);
    io_msAlloc_2_10_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_11_valid = 1'($urandom);
    io_msAlloc_2_11_bits_channel = 3'($urandom);
    io_msAlloc_2_11_bits_is_miss = 1'($urandom);
    io_msAlloc_2_11_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_12_valid = 1'($urandom);
    io_msAlloc_2_12_bits_channel = 3'($urandom);
    io_msAlloc_2_12_bits_is_miss = 1'($urandom);
    io_msAlloc_2_12_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_13_valid = 1'($urandom);
    io_msAlloc_2_13_bits_channel = 3'($urandom);
    io_msAlloc_2_13_bits_is_miss = 1'($urandom);
    io_msAlloc_2_13_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_14_valid = 1'($urandom);
    io_msAlloc_2_14_bits_channel = 3'($urandom);
    io_msAlloc_2_14_bits_is_miss = 1'($urandom);
    io_msAlloc_2_14_bits_is_prefetch = 1'($urandom);
    io_msAlloc_2_15_valid = 1'($urandom);
    io_msAlloc_2_15_bits_channel = 3'($urandom);
    io_msAlloc_2_15_bits_is_miss = 1'($urandom);
    io_msAlloc_2_15_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_0_valid = 1'($urandom);
    io_msAlloc_3_0_bits_channel = 3'($urandom);
    io_msAlloc_3_0_bits_is_miss = 1'($urandom);
    io_msAlloc_3_0_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_1_valid = 1'($urandom);
    io_msAlloc_3_1_bits_channel = 3'($urandom);
    io_msAlloc_3_1_bits_is_miss = 1'($urandom);
    io_msAlloc_3_1_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_2_valid = 1'($urandom);
    io_msAlloc_3_2_bits_channel = 3'($urandom);
    io_msAlloc_3_2_bits_is_miss = 1'($urandom);
    io_msAlloc_3_2_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_3_valid = 1'($urandom);
    io_msAlloc_3_3_bits_channel = 3'($urandom);
    io_msAlloc_3_3_bits_is_miss = 1'($urandom);
    io_msAlloc_3_3_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_4_valid = 1'($urandom);
    io_msAlloc_3_4_bits_channel = 3'($urandom);
    io_msAlloc_3_4_bits_is_miss = 1'($urandom);
    io_msAlloc_3_4_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_5_valid = 1'($urandom);
    io_msAlloc_3_5_bits_channel = 3'($urandom);
    io_msAlloc_3_5_bits_is_miss = 1'($urandom);
    io_msAlloc_3_5_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_6_valid = 1'($urandom);
    io_msAlloc_3_6_bits_channel = 3'($urandom);
    io_msAlloc_3_6_bits_is_miss = 1'($urandom);
    io_msAlloc_3_6_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_7_valid = 1'($urandom);
    io_msAlloc_3_7_bits_channel = 3'($urandom);
    io_msAlloc_3_7_bits_is_miss = 1'($urandom);
    io_msAlloc_3_7_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_8_valid = 1'($urandom);
    io_msAlloc_3_8_bits_channel = 3'($urandom);
    io_msAlloc_3_8_bits_is_miss = 1'($urandom);
    io_msAlloc_3_8_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_9_valid = 1'($urandom);
    io_msAlloc_3_9_bits_channel = 3'($urandom);
    io_msAlloc_3_9_bits_is_miss = 1'($urandom);
    io_msAlloc_3_9_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_10_valid = 1'($urandom);
    io_msAlloc_3_10_bits_channel = 3'($urandom);
    io_msAlloc_3_10_bits_is_miss = 1'($urandom);
    io_msAlloc_3_10_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_11_valid = 1'($urandom);
    io_msAlloc_3_11_bits_channel = 3'($urandom);
    io_msAlloc_3_11_bits_is_miss = 1'($urandom);
    io_msAlloc_3_11_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_12_valid = 1'($urandom);
    io_msAlloc_3_12_bits_channel = 3'($urandom);
    io_msAlloc_3_12_bits_is_miss = 1'($urandom);
    io_msAlloc_3_12_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_13_valid = 1'($urandom);
    io_msAlloc_3_13_bits_channel = 3'($urandom);
    io_msAlloc_3_13_bits_is_miss = 1'($urandom);
    io_msAlloc_3_13_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_14_valid = 1'($urandom);
    io_msAlloc_3_14_bits_channel = 3'($urandom);
    io_msAlloc_3_14_bits_is_miss = 1'($urandom);
    io_msAlloc_3_14_bits_is_prefetch = 1'($urandom);
    io_msAlloc_3_15_valid = 1'($urandom);
    io_msAlloc_3_15_bits_channel = 3'($urandom);
    io_msAlloc_3_15_bits_is_miss = 1'($urandom);
    io_msAlloc_3_15_bits_is_prefetch = 1'($urandom);
    io_hitPfInMSHR_0_valid = 1'($urandom);
    io_hitPfInMSHR_0_bits = 3'($urandom);
    io_hitPfInMSHR_1_valid = 1'($urandom);
    io_hitPfInMSHR_1_bits = 3'($urandom);
    io_hitPfInMSHR_2_valid = 1'($urandom);
    io_hitPfInMSHR_2_bits = 3'($urandom);
    io_hitPfInMSHR_3_valid = 1'($urandom);
    io_hitPfInMSHR_3_bits = 3'($urandom);
    io_pfSent_0_valid = 1'($urandom);
    io_pfSent_0_bits = 5'($urandom);
    io_pfSent_1_valid = 1'($urandom);
    io_pfSent_1_bits = 5'($urandom);
    io_pfSent_2_valid = 1'($urandom);
    io_pfSent_2_bits = 5'($urandom);
    io_pfSent_3_valid = 1'($urandom);
    io_pfSent_3_bits = 5'($urandom);
    io_pfLateInMSHR_0_valid = 1'($urandom);
    io_pfLateInMSHR_0_bits = 5'($urandom);
    io_pfLateInMSHR_1_valid = 1'($urandom);
    io_pfLateInMSHR_1_bits = 5'($urandom);
    io_pfLateInMSHR_2_valid = 1'($urandom);
    io_pfLateInMSHR_2_bits = 5'($urandom);
    io_pfLateInMSHR_3_valid = 1'($urandom);
    io_pfLateInMSHR_3_bits = 5'($urandom);
    io_debugTopDown_robHeadPaddr_valid = 1'($urandom);
    io_debugTopDown_robHeadPaddr_bits = {$urandom, $urandom};
  endtask

  // 把 (b, m) 号 MSHR 的块地址设成与 ROB 头一致（mode 2：bank 号错位；mode 3：tag 高位非 0）
  task automatic aim(int b, int m, int mode);
    logic [29:0] blk;
    logic [1:0]  bank;
    logic        force_on;
    blk  = io_debugTopDown_robHeadPaddr_bits[35:6];
    bank = (mode == 2) ? 2'(b + 1) : 2'(b);
    blk[1:0] = bank;
    io_debugTopDown_robHeadPaddr_bits[7:6] = bank;
    force_on = (mode == 1) && ($urandom_range(0, 1) == 1);   // 一半拍把三个使能条件都置 1
    if (force_on) io_debugTopDown_robHeadPaddr_valid = 1'b1;
    case (b * 16 + m)
      0: begin io_msStatus_0_0_bits_set = blk[10:2]; io_msStatus_0_0_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_0_valid = 1'b1; io_msStatus_0_0_bits_is_miss = 1'b1; end end
      1: begin io_msStatus_0_1_bits_set = blk[10:2]; io_msStatus_0_1_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_1_valid = 1'b1; io_msStatus_0_1_bits_is_miss = 1'b1; end end
      2: begin io_msStatus_0_2_bits_set = blk[10:2]; io_msStatus_0_2_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_2_valid = 1'b1; io_msStatus_0_2_bits_is_miss = 1'b1; end end
      3: begin io_msStatus_0_3_bits_set = blk[10:2]; io_msStatus_0_3_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_3_valid = 1'b1; io_msStatus_0_3_bits_is_miss = 1'b1; end end
      4: begin io_msStatus_0_4_bits_set = blk[10:2]; io_msStatus_0_4_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_4_valid = 1'b1; io_msStatus_0_4_bits_is_miss = 1'b1; end end
      5: begin io_msStatus_0_5_bits_set = blk[10:2]; io_msStatus_0_5_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_5_valid = 1'b1; io_msStatus_0_5_bits_is_miss = 1'b1; end end
      6: begin io_msStatus_0_6_bits_set = blk[10:2]; io_msStatus_0_6_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_6_valid = 1'b1; io_msStatus_0_6_bits_is_miss = 1'b1; end end
      7: begin io_msStatus_0_7_bits_set = blk[10:2]; io_msStatus_0_7_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_7_valid = 1'b1; io_msStatus_0_7_bits_is_miss = 1'b1; end end
      8: begin io_msStatus_0_8_bits_set = blk[10:2]; io_msStatus_0_8_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_8_valid = 1'b1; io_msStatus_0_8_bits_is_miss = 1'b1; end end
      9: begin io_msStatus_0_9_bits_set = blk[10:2]; io_msStatus_0_9_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_9_valid = 1'b1; io_msStatus_0_9_bits_is_miss = 1'b1; end end
      10: begin io_msStatus_0_10_bits_set = blk[10:2]; io_msStatus_0_10_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_10_valid = 1'b1; io_msStatus_0_10_bits_is_miss = 1'b1; end end
      11: begin io_msStatus_0_11_bits_set = blk[10:2]; io_msStatus_0_11_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_11_valid = 1'b1; io_msStatus_0_11_bits_is_miss = 1'b1; end end
      12: begin io_msStatus_0_12_bits_set = blk[10:2]; io_msStatus_0_12_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_12_valid = 1'b1; io_msStatus_0_12_bits_is_miss = 1'b1; end end
      13: begin io_msStatus_0_13_bits_set = blk[10:2]; io_msStatus_0_13_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_13_valid = 1'b1; io_msStatus_0_13_bits_is_miss = 1'b1; end end
      14: begin io_msStatus_0_14_bits_set = blk[10:2]; io_msStatus_0_14_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_14_valid = 1'b1; io_msStatus_0_14_bits_is_miss = 1'b1; end end
      15: begin io_msStatus_0_15_bits_set = blk[10:2]; io_msStatus_0_15_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_0_15_valid = 1'b1; io_msStatus_0_15_bits_is_miss = 1'b1; end end
      16: begin io_msStatus_1_0_bits_set = blk[10:2]; io_msStatus_1_0_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_0_valid = 1'b1; io_msStatus_1_0_bits_is_miss = 1'b1; end end
      17: begin io_msStatus_1_1_bits_set = blk[10:2]; io_msStatus_1_1_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_1_valid = 1'b1; io_msStatus_1_1_bits_is_miss = 1'b1; end end
      18: begin io_msStatus_1_2_bits_set = blk[10:2]; io_msStatus_1_2_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_2_valid = 1'b1; io_msStatus_1_2_bits_is_miss = 1'b1; end end
      19: begin io_msStatus_1_3_bits_set = blk[10:2]; io_msStatus_1_3_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_3_valid = 1'b1; io_msStatus_1_3_bits_is_miss = 1'b1; end end
      20: begin io_msStatus_1_4_bits_set = blk[10:2]; io_msStatus_1_4_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_4_valid = 1'b1; io_msStatus_1_4_bits_is_miss = 1'b1; end end
      21: begin io_msStatus_1_5_bits_set = blk[10:2]; io_msStatus_1_5_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_5_valid = 1'b1; io_msStatus_1_5_bits_is_miss = 1'b1; end end
      22: begin io_msStatus_1_6_bits_set = blk[10:2]; io_msStatus_1_6_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_6_valid = 1'b1; io_msStatus_1_6_bits_is_miss = 1'b1; end end
      23: begin io_msStatus_1_7_bits_set = blk[10:2]; io_msStatus_1_7_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_7_valid = 1'b1; io_msStatus_1_7_bits_is_miss = 1'b1; end end
      24: begin io_msStatus_1_8_bits_set = blk[10:2]; io_msStatus_1_8_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_8_valid = 1'b1; io_msStatus_1_8_bits_is_miss = 1'b1; end end
      25: begin io_msStatus_1_9_bits_set = blk[10:2]; io_msStatus_1_9_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_9_valid = 1'b1; io_msStatus_1_9_bits_is_miss = 1'b1; end end
      26: begin io_msStatus_1_10_bits_set = blk[10:2]; io_msStatus_1_10_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_10_valid = 1'b1; io_msStatus_1_10_bits_is_miss = 1'b1; end end
      27: begin io_msStatus_1_11_bits_set = blk[10:2]; io_msStatus_1_11_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_11_valid = 1'b1; io_msStatus_1_11_bits_is_miss = 1'b1; end end
      28: begin io_msStatus_1_12_bits_set = blk[10:2]; io_msStatus_1_12_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_12_valid = 1'b1; io_msStatus_1_12_bits_is_miss = 1'b1; end end
      29: begin io_msStatus_1_13_bits_set = blk[10:2]; io_msStatus_1_13_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_13_valid = 1'b1; io_msStatus_1_13_bits_is_miss = 1'b1; end end
      30: begin io_msStatus_1_14_bits_set = blk[10:2]; io_msStatus_1_14_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_14_valid = 1'b1; io_msStatus_1_14_bits_is_miss = 1'b1; end end
      31: begin io_msStatus_1_15_bits_set = blk[10:2]; io_msStatus_1_15_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_1_15_valid = 1'b1; io_msStatus_1_15_bits_is_miss = 1'b1; end end
      32: begin io_msStatus_2_0_bits_set = blk[10:2]; io_msStatus_2_0_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_0_valid = 1'b1; io_msStatus_2_0_bits_is_miss = 1'b1; end end
      33: begin io_msStatus_2_1_bits_set = blk[10:2]; io_msStatus_2_1_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_1_valid = 1'b1; io_msStatus_2_1_bits_is_miss = 1'b1; end end
      34: begin io_msStatus_2_2_bits_set = blk[10:2]; io_msStatus_2_2_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_2_valid = 1'b1; io_msStatus_2_2_bits_is_miss = 1'b1; end end
      35: begin io_msStatus_2_3_bits_set = blk[10:2]; io_msStatus_2_3_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_3_valid = 1'b1; io_msStatus_2_3_bits_is_miss = 1'b1; end end
      36: begin io_msStatus_2_4_bits_set = blk[10:2]; io_msStatus_2_4_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_4_valid = 1'b1; io_msStatus_2_4_bits_is_miss = 1'b1; end end
      37: begin io_msStatus_2_5_bits_set = blk[10:2]; io_msStatus_2_5_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_5_valid = 1'b1; io_msStatus_2_5_bits_is_miss = 1'b1; end end
      38: begin io_msStatus_2_6_bits_set = blk[10:2]; io_msStatus_2_6_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_6_valid = 1'b1; io_msStatus_2_6_bits_is_miss = 1'b1; end end
      39: begin io_msStatus_2_7_bits_set = blk[10:2]; io_msStatus_2_7_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_7_valid = 1'b1; io_msStatus_2_7_bits_is_miss = 1'b1; end end
      40: begin io_msStatus_2_8_bits_set = blk[10:2]; io_msStatus_2_8_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_8_valid = 1'b1; io_msStatus_2_8_bits_is_miss = 1'b1; end end
      41: begin io_msStatus_2_9_bits_set = blk[10:2]; io_msStatus_2_9_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_9_valid = 1'b1; io_msStatus_2_9_bits_is_miss = 1'b1; end end
      42: begin io_msStatus_2_10_bits_set = blk[10:2]; io_msStatus_2_10_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_10_valid = 1'b1; io_msStatus_2_10_bits_is_miss = 1'b1; end end
      43: begin io_msStatus_2_11_bits_set = blk[10:2]; io_msStatus_2_11_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_11_valid = 1'b1; io_msStatus_2_11_bits_is_miss = 1'b1; end end
      44: begin io_msStatus_2_12_bits_set = blk[10:2]; io_msStatus_2_12_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_12_valid = 1'b1; io_msStatus_2_12_bits_is_miss = 1'b1; end end
      45: begin io_msStatus_2_13_bits_set = blk[10:2]; io_msStatus_2_13_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_13_valid = 1'b1; io_msStatus_2_13_bits_is_miss = 1'b1; end end
      46: begin io_msStatus_2_14_bits_set = blk[10:2]; io_msStatus_2_14_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_14_valid = 1'b1; io_msStatus_2_14_bits_is_miss = 1'b1; end end
      47: begin io_msStatus_2_15_bits_set = blk[10:2]; io_msStatus_2_15_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_2_15_valid = 1'b1; io_msStatus_2_15_bits_is_miss = 1'b1; end end
      48: begin io_msStatus_3_0_bits_set = blk[10:2]; io_msStatus_3_0_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_0_valid = 1'b1; io_msStatus_3_0_bits_is_miss = 1'b1; end end
      49: begin io_msStatus_3_1_bits_set = blk[10:2]; io_msStatus_3_1_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_1_valid = 1'b1; io_msStatus_3_1_bits_is_miss = 1'b1; end end
      50: begin io_msStatus_3_2_bits_set = blk[10:2]; io_msStatus_3_2_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_2_valid = 1'b1; io_msStatus_3_2_bits_is_miss = 1'b1; end end
      51: begin io_msStatus_3_3_bits_set = blk[10:2]; io_msStatus_3_3_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_3_valid = 1'b1; io_msStatus_3_3_bits_is_miss = 1'b1; end end
      52: begin io_msStatus_3_4_bits_set = blk[10:2]; io_msStatus_3_4_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_4_valid = 1'b1; io_msStatus_3_4_bits_is_miss = 1'b1; end end
      53: begin io_msStatus_3_5_bits_set = blk[10:2]; io_msStatus_3_5_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_5_valid = 1'b1; io_msStatus_3_5_bits_is_miss = 1'b1; end end
      54: begin io_msStatus_3_6_bits_set = blk[10:2]; io_msStatus_3_6_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_6_valid = 1'b1; io_msStatus_3_6_bits_is_miss = 1'b1; end end
      55: begin io_msStatus_3_7_bits_set = blk[10:2]; io_msStatus_3_7_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_7_valid = 1'b1; io_msStatus_3_7_bits_is_miss = 1'b1; end end
      56: begin io_msStatus_3_8_bits_set = blk[10:2]; io_msStatus_3_8_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_8_valid = 1'b1; io_msStatus_3_8_bits_is_miss = 1'b1; end end
      57: begin io_msStatus_3_9_bits_set = blk[10:2]; io_msStatus_3_9_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_9_valid = 1'b1; io_msStatus_3_9_bits_is_miss = 1'b1; end end
      58: begin io_msStatus_3_10_bits_set = blk[10:2]; io_msStatus_3_10_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_10_valid = 1'b1; io_msStatus_3_10_bits_is_miss = 1'b1; end end
      59: begin io_msStatus_3_11_bits_set = blk[10:2]; io_msStatus_3_11_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_11_valid = 1'b1; io_msStatus_3_11_bits_is_miss = 1'b1; end end
      60: begin io_msStatus_3_12_bits_set = blk[10:2]; io_msStatus_3_12_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_12_valid = 1'b1; io_msStatus_3_12_bits_is_miss = 1'b1; end end
      61: begin io_msStatus_3_13_bits_set = blk[10:2]; io_msStatus_3_13_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_13_valid = 1'b1; io_msStatus_3_13_bits_is_miss = 1'b1; end end
      62: begin io_msStatus_3_14_bits_set = blk[10:2]; io_msStatus_3_14_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_14_valid = 1'b1; io_msStatus_3_14_bits_is_miss = 1'b1; end end
      63: begin io_msStatus_3_15_bits_set = blk[10:2]; io_msStatus_3_15_bits_reqTag = {(mode == 3) ? 12'($urandom | 1) : 12'd0, blk[29:11]};
          if (force_on) begin io_msStatus_3_15_valid = 1'b1; io_msStatus_3_15_bits_is_miss = 1'b1; end end
    endcase
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (hit_pos[b, m]) hit_pos[b][m] = 0;
    for (int c = 0; c < NCYCLES; c++) begin
      int mode, b, m;
      drive();
      mode = c % 4; b = $urandom_range(0, 3); m = $urandom_range(0, 15);
      if (mode != 0) aim(b, m, mode);
      #1;
      checks++;
      if (g_out !== i_out) begin errors++; if (errors <= 40) $display("[%0d] MISMATCH l2MissMatch golden=%b impl=%b mode=%0d b=%0d m=%0d", c, g_out, i_out, mode, b, m); end
      if (g_out) begin hit_cnt++; if (mode == 1) hit_pos[b][m]++; end
      #1;
    end
    begin
      int bad = 0, minp = 1 << 30;
      foreach (hit_pos[b, m]) begin if (hit_pos[b][m] < minp) minp = hit_pos[b][m]; if (hit_pos[b][m] < 100) bad++; end
      if (hit_cnt < 20000) bad++;
      $display("--- coverage: hits=%0d per-(bank,mshr) hits min=%0d", hit_cnt, minp);
      $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
      if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
