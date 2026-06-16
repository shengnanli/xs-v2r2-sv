// 自动生成：scripts/gen_loadqueue.py —— 勿手改
// 28 路性能计数器打两拍后接出顶层端口。
// 前 18 路（0..17）为子队列给出的 6-bit 计数；后 10 路（18..27）为 full_mask /
// rollback 等 1-bit 组合条件，零扩展到 6 bit。
  assign io_perf_0_value = perf_stage2[0];
  assign io_perf_1_value = perf_stage2[1];
  assign io_perf_2_value = perf_stage2[2];
  assign io_perf_3_value = perf_stage2[3];
  assign io_perf_4_value = perf_stage2[4];
  assign io_perf_5_value = perf_stage2[5];
  assign io_perf_6_value = perf_stage2[6];
  assign io_perf_7_value = perf_stage2[7];
  assign io_perf_8_value = perf_stage2[8];
  assign io_perf_9_value = perf_stage2[9];
  assign io_perf_10_value = perf_stage2[10];
  assign io_perf_11_value = perf_stage2[11];
  assign io_perf_12_value = perf_stage2[12];
  assign io_perf_13_value = perf_stage2[13];
  assign io_perf_14_value = perf_stage2[14];
  assign io_perf_15_value = perf_stage2[15];
  assign io_perf_16_value = perf_stage2[16];
  assign io_perf_17_value = perf_stage2[17];
  assign io_perf_18_value = {5'h0, perf_stage2[18][0]};
  assign io_perf_19_value = {5'h0, perf_stage2[19][0]};
  assign io_perf_20_value = {5'h0, perf_stage2[20][0]};
  assign io_perf_21_value = {5'h0, perf_stage2[21][0]};
  assign io_perf_22_value = {5'h0, perf_stage2[22][0]};
  assign io_perf_23_value = {5'h0, perf_stage2[23][0]};
  assign io_perf_24_value = {5'h0, perf_stage2[24][0]};
  assign io_perf_25_value = {5'h0, perf_stage2[25][0]};
  assign io_perf_26_value = {5'h0, perf_stage2[26][0]};
  assign io_perf_27_value = {5'h0, perf_stage2[27][0]};
