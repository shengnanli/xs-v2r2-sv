// 自动生成：scripts/gen_loadqueue.py —— 勿手改
// 28 路性能计数器打两拍后接出顶层端口，逐路展平寄存器命名镜像 golden。
// 前 18 路（0..17）为子队列给出的 6-bit 计数；后 10 路（18..27）为 full_mask /
// rollback 等 1-bit 组合条件，零扩展到 6 bit。
  assign io_perf_0_value = io_perf_0_value_REG_1;
  assign io_perf_1_value = io_perf_1_value_REG_1;
  assign io_perf_2_value = io_perf_2_value_REG_1;
  assign io_perf_3_value = io_perf_3_value_REG_1;
  assign io_perf_4_value = io_perf_4_value_REG_1;
  assign io_perf_5_value = io_perf_5_value_REG_1;
  assign io_perf_6_value = io_perf_6_value_REG_1;
  assign io_perf_7_value = io_perf_7_value_REG_1;
  assign io_perf_8_value = io_perf_8_value_REG_1;
  assign io_perf_9_value = io_perf_9_value_REG_1;
  assign io_perf_10_value = io_perf_10_value_REG_1;
  assign io_perf_11_value = io_perf_11_value_REG_1;
  assign io_perf_12_value = io_perf_12_value_REG_1;
  assign io_perf_13_value = io_perf_13_value_REG_1;
  assign io_perf_14_value = io_perf_14_value_REG_1;
  assign io_perf_15_value = io_perf_15_value_REG_1;
  assign io_perf_16_value = io_perf_16_value_REG_1;
  assign io_perf_17_value = io_perf_17_value_REG_1;
  assign io_perf_18_value = {5'h0, io_perf_18_value_REG_1};
  assign io_perf_19_value = {5'h0, io_perf_19_value_REG_1};
  assign io_perf_20_value = {5'h0, io_perf_20_value_REG_1};
  assign io_perf_21_value = {5'h0, io_perf_21_value_REG_1};
  assign io_perf_22_value = {5'h0, io_perf_22_value_REG_1};
  assign io_perf_23_value = {5'h0, io_perf_23_value_REG_1};
  assign io_perf_24_value = {5'h0, io_perf_24_value_REG_1};
  assign io_perf_25_value = {5'h0, io_perf_25_value_REG_1};
  assign io_perf_26_value = {5'h0, io_perf_26_value_REG_1};
  assign io_perf_27_value = {5'h0, io_perf_27_value_REG_1};
