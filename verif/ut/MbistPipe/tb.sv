// tb.sv —— MbistPipe* 家族（24 个变体）双例化 UT
//
// 24 个 golden 变体 + 24 个由 scripts/derive_ut_impl.py 派生的 <M>_xs 同时例化，
// 同一套激励，每拍逐位比全部输出。生成脚本：scripts/gen_mbist_ut.py
`timescale 1ns/1ps

module tb;

  // ---------------- 时钟 / 复位 ----------------
  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;

  int unsigned ncycles = 200000;
  longint unsigned cyc = 0;        // 复位释放后的拍数
  longint unsigned cmp_cycles = 0; // 真正参与比对的拍数
  longint unsigned checks = 0;
  longint unsigned errors = 0;
  bit               armed = 1'b0;  // 比对是否已开闸

  // ---------------- 主激励（各变体按自己的位宽取低位切片）----------------
  logic [6:0]   s_array;
  logic         s_all, s_req, s_wen, s_ren;
  logic [75:0]  s_be;
  logic [9:0]   s_addr, s_addr_rd;
  logic [147:0] s_indata;

  // ---------------- 覆盖闸 ----------------
  bit [127:0] cov_id;                    // 每个 array 编号都以 req&!all 打过
  bit [9:0]  cov_addr0, cov_addr1;      // 地址每一位都出现过 0 和 1
  bit [75:0] cov_be0, cov_be1;
  bit [147:0] cov_din0, cov_din1;
  bit cov_all_bcast, cov_idle, cov_wr, cov_rd, cov_rdwr;

  // ======================== [00] MbistPipeDCacheData ========================
  logic [71:0] v0_rd0;
  logic [71:0] v0_rd1;
  logic [71:0] v0_rd2;
  logic [71:0] v0_rd3;
  logic [71:0] v0_rd4;
  logic [71:0] v0_rd5;
  logic [71:0] v0_rd6;
  logic [71:0] v0_rd7;
  logic [71:0] v0_rd8;
  logic [71:0] v0_rd9;
  logic [71:0] v0_rd10;
  logic [71:0] v0_rd11;
  logic [71:0] v0_rd12;
  logic [71:0] v0_rd13;
  logic [71:0] v0_rd14;
  logic [71:0] v0_rd15;
  logic [71:0] v0_rd16;
  logic [71:0] v0_rd17;
  logic [71:0] v0_rd18;
  logic [71:0] v0_rd19;
  logic [71:0] v0_rd20;
  logic [71:0] v0_rd21;
  logic [71:0] v0_rd22;
  logic [71:0] v0_rd23;
  logic [71:0] v0_rd24;
  logic [71:0] v0_rd25;
  logic [71:0] v0_rd26;
  logic [71:0] v0_rd27;
  logic [71:0] v0_rd28;
  logic [71:0] v0_rd29;
  logic [71:0] v0_rd30;
  logic [71:0] v0_rd31;
  logic g0_mbist_ack;
  logic [71:0] g0_mbist_outdata;
  logic [8:0] g0_toSRAM_0_addr;
  logic [8:0] g0_toSRAM_0_addr_rd;
  logic [71:0] g0_toSRAM_0_wdata;
  logic g0_toSRAM_0_wmask;
  logic g0_toSRAM_0_re;
  logic g0_toSRAM_0_we;
  logic g0_toSRAM_0_ack;
  logic g0_toSRAM_0_selectedOH;
  logic g0_toSRAM_0_array;
  logic [8:0] g0_toSRAM_1_addr;
  logic [8:0] g0_toSRAM_1_addr_rd;
  logic [71:0] g0_toSRAM_1_wdata;
  logic g0_toSRAM_1_wmask;
  logic g0_toSRAM_1_re;
  logic g0_toSRAM_1_we;
  logic g0_toSRAM_1_ack;
  logic g0_toSRAM_1_selectedOH;
  logic g0_toSRAM_1_array;
  logic [8:0] g0_toSRAM_2_addr;
  logic [8:0] g0_toSRAM_2_addr_rd;
  logic [71:0] g0_toSRAM_2_wdata;
  logic g0_toSRAM_2_wmask;
  logic g0_toSRAM_2_re;
  logic g0_toSRAM_2_we;
  logic g0_toSRAM_2_ack;
  logic g0_toSRAM_2_selectedOH;
  logic [1:0] g0_toSRAM_2_array;
  logic [8:0] g0_toSRAM_3_addr;
  logic [8:0] g0_toSRAM_3_addr_rd;
  logic [71:0] g0_toSRAM_3_wdata;
  logic g0_toSRAM_3_wmask;
  logic g0_toSRAM_3_re;
  logic g0_toSRAM_3_we;
  logic g0_toSRAM_3_ack;
  logic g0_toSRAM_3_selectedOH;
  logic [1:0] g0_toSRAM_3_array;
  logic [8:0] g0_toSRAM_4_addr;
  logic [8:0] g0_toSRAM_4_addr_rd;
  logic [71:0] g0_toSRAM_4_wdata;
  logic g0_toSRAM_4_wmask;
  logic g0_toSRAM_4_re;
  logic g0_toSRAM_4_we;
  logic g0_toSRAM_4_ack;
  logic g0_toSRAM_4_selectedOH;
  logic [2:0] g0_toSRAM_4_array;
  logic [8:0] g0_toSRAM_5_addr;
  logic [8:0] g0_toSRAM_5_addr_rd;
  logic [71:0] g0_toSRAM_5_wdata;
  logic g0_toSRAM_5_wmask;
  logic g0_toSRAM_5_re;
  logic g0_toSRAM_5_we;
  logic g0_toSRAM_5_ack;
  logic g0_toSRAM_5_selectedOH;
  logic [2:0] g0_toSRAM_5_array;
  logic [8:0] g0_toSRAM_6_addr;
  logic [8:0] g0_toSRAM_6_addr_rd;
  logic [71:0] g0_toSRAM_6_wdata;
  logic g0_toSRAM_6_wmask;
  logic g0_toSRAM_6_re;
  logic g0_toSRAM_6_we;
  logic g0_toSRAM_6_ack;
  logic g0_toSRAM_6_selectedOH;
  logic [2:0] g0_toSRAM_6_array;
  logic [8:0] g0_toSRAM_7_addr;
  logic [8:0] g0_toSRAM_7_addr_rd;
  logic [71:0] g0_toSRAM_7_wdata;
  logic g0_toSRAM_7_wmask;
  logic g0_toSRAM_7_re;
  logic g0_toSRAM_7_we;
  logic g0_toSRAM_7_ack;
  logic g0_toSRAM_7_selectedOH;
  logic [2:0] g0_toSRAM_7_array;
  logic [8:0] g0_toSRAM_8_addr;
  logic [8:0] g0_toSRAM_8_addr_rd;
  logic [71:0] g0_toSRAM_8_wdata;
  logic g0_toSRAM_8_wmask;
  logic g0_toSRAM_8_re;
  logic g0_toSRAM_8_we;
  logic g0_toSRAM_8_ack;
  logic g0_toSRAM_8_selectedOH;
  logic [3:0] g0_toSRAM_8_array;
  logic [8:0] g0_toSRAM_9_addr;
  logic [8:0] g0_toSRAM_9_addr_rd;
  logic [71:0] g0_toSRAM_9_wdata;
  logic g0_toSRAM_9_wmask;
  logic g0_toSRAM_9_re;
  logic g0_toSRAM_9_we;
  logic g0_toSRAM_9_ack;
  logic g0_toSRAM_9_selectedOH;
  logic [3:0] g0_toSRAM_9_array;
  logic [8:0] g0_toSRAM_10_addr;
  logic [8:0] g0_toSRAM_10_addr_rd;
  logic [71:0] g0_toSRAM_10_wdata;
  logic g0_toSRAM_10_wmask;
  logic g0_toSRAM_10_re;
  logic g0_toSRAM_10_we;
  logic g0_toSRAM_10_ack;
  logic g0_toSRAM_10_selectedOH;
  logic [3:0] g0_toSRAM_10_array;
  logic [8:0] g0_toSRAM_11_addr;
  logic [8:0] g0_toSRAM_11_addr_rd;
  logic [71:0] g0_toSRAM_11_wdata;
  logic g0_toSRAM_11_wmask;
  logic g0_toSRAM_11_re;
  logic g0_toSRAM_11_we;
  logic g0_toSRAM_11_ack;
  logic g0_toSRAM_11_selectedOH;
  logic [3:0] g0_toSRAM_11_array;
  logic [8:0] g0_toSRAM_12_addr;
  logic [8:0] g0_toSRAM_12_addr_rd;
  logic [71:0] g0_toSRAM_12_wdata;
  logic g0_toSRAM_12_wmask;
  logic g0_toSRAM_12_re;
  logic g0_toSRAM_12_we;
  logic g0_toSRAM_12_ack;
  logic g0_toSRAM_12_selectedOH;
  logic [3:0] g0_toSRAM_12_array;
  logic [8:0] g0_toSRAM_13_addr;
  logic [8:0] g0_toSRAM_13_addr_rd;
  logic [71:0] g0_toSRAM_13_wdata;
  logic g0_toSRAM_13_wmask;
  logic g0_toSRAM_13_re;
  logic g0_toSRAM_13_we;
  logic g0_toSRAM_13_ack;
  logic g0_toSRAM_13_selectedOH;
  logic [3:0] g0_toSRAM_13_array;
  logic [8:0] g0_toSRAM_14_addr;
  logic [8:0] g0_toSRAM_14_addr_rd;
  logic [71:0] g0_toSRAM_14_wdata;
  logic g0_toSRAM_14_wmask;
  logic g0_toSRAM_14_re;
  logic g0_toSRAM_14_we;
  logic g0_toSRAM_14_ack;
  logic g0_toSRAM_14_selectedOH;
  logic [3:0] g0_toSRAM_14_array;
  logic [8:0] g0_toSRAM_15_addr;
  logic [8:0] g0_toSRAM_15_addr_rd;
  logic [71:0] g0_toSRAM_15_wdata;
  logic g0_toSRAM_15_wmask;
  logic g0_toSRAM_15_re;
  logic g0_toSRAM_15_we;
  logic g0_toSRAM_15_ack;
  logic g0_toSRAM_15_selectedOH;
  logic [3:0] g0_toSRAM_15_array;
  logic [8:0] g0_toSRAM_16_addr;
  logic [8:0] g0_toSRAM_16_addr_rd;
  logic [71:0] g0_toSRAM_16_wdata;
  logic g0_toSRAM_16_wmask;
  logic g0_toSRAM_16_re;
  logic g0_toSRAM_16_we;
  logic g0_toSRAM_16_ack;
  logic g0_toSRAM_16_selectedOH;
  logic [4:0] g0_toSRAM_16_array;
  logic [8:0] g0_toSRAM_17_addr;
  logic [8:0] g0_toSRAM_17_addr_rd;
  logic [71:0] g0_toSRAM_17_wdata;
  logic g0_toSRAM_17_wmask;
  logic g0_toSRAM_17_re;
  logic g0_toSRAM_17_we;
  logic g0_toSRAM_17_ack;
  logic g0_toSRAM_17_selectedOH;
  logic [4:0] g0_toSRAM_17_array;
  logic [8:0] g0_toSRAM_18_addr;
  logic [8:0] g0_toSRAM_18_addr_rd;
  logic [71:0] g0_toSRAM_18_wdata;
  logic g0_toSRAM_18_wmask;
  logic g0_toSRAM_18_re;
  logic g0_toSRAM_18_we;
  logic g0_toSRAM_18_ack;
  logic g0_toSRAM_18_selectedOH;
  logic [4:0] g0_toSRAM_18_array;
  logic [8:0] g0_toSRAM_19_addr;
  logic [8:0] g0_toSRAM_19_addr_rd;
  logic [71:0] g0_toSRAM_19_wdata;
  logic g0_toSRAM_19_wmask;
  logic g0_toSRAM_19_re;
  logic g0_toSRAM_19_we;
  logic g0_toSRAM_19_ack;
  logic g0_toSRAM_19_selectedOH;
  logic [4:0] g0_toSRAM_19_array;
  logic [8:0] g0_toSRAM_20_addr;
  logic [8:0] g0_toSRAM_20_addr_rd;
  logic [71:0] g0_toSRAM_20_wdata;
  logic g0_toSRAM_20_wmask;
  logic g0_toSRAM_20_re;
  logic g0_toSRAM_20_we;
  logic g0_toSRAM_20_ack;
  logic g0_toSRAM_20_selectedOH;
  logic [4:0] g0_toSRAM_20_array;
  logic [8:0] g0_toSRAM_21_addr;
  logic [8:0] g0_toSRAM_21_addr_rd;
  logic [71:0] g0_toSRAM_21_wdata;
  logic g0_toSRAM_21_wmask;
  logic g0_toSRAM_21_re;
  logic g0_toSRAM_21_we;
  logic g0_toSRAM_21_ack;
  logic g0_toSRAM_21_selectedOH;
  logic [4:0] g0_toSRAM_21_array;
  logic [8:0] g0_toSRAM_22_addr;
  logic [8:0] g0_toSRAM_22_addr_rd;
  logic [71:0] g0_toSRAM_22_wdata;
  logic g0_toSRAM_22_wmask;
  logic g0_toSRAM_22_re;
  logic g0_toSRAM_22_we;
  logic g0_toSRAM_22_ack;
  logic g0_toSRAM_22_selectedOH;
  logic [4:0] g0_toSRAM_22_array;
  logic [8:0] g0_toSRAM_23_addr;
  logic [8:0] g0_toSRAM_23_addr_rd;
  logic [71:0] g0_toSRAM_23_wdata;
  logic g0_toSRAM_23_wmask;
  logic g0_toSRAM_23_re;
  logic g0_toSRAM_23_we;
  logic g0_toSRAM_23_ack;
  logic g0_toSRAM_23_selectedOH;
  logic [4:0] g0_toSRAM_23_array;
  logic [8:0] g0_toSRAM_24_addr;
  logic [8:0] g0_toSRAM_24_addr_rd;
  logic [71:0] g0_toSRAM_24_wdata;
  logic g0_toSRAM_24_wmask;
  logic g0_toSRAM_24_re;
  logic g0_toSRAM_24_we;
  logic g0_toSRAM_24_ack;
  logic g0_toSRAM_24_selectedOH;
  logic [4:0] g0_toSRAM_24_array;
  logic [8:0] g0_toSRAM_25_addr;
  logic [8:0] g0_toSRAM_25_addr_rd;
  logic [71:0] g0_toSRAM_25_wdata;
  logic g0_toSRAM_25_wmask;
  logic g0_toSRAM_25_re;
  logic g0_toSRAM_25_we;
  logic g0_toSRAM_25_ack;
  logic g0_toSRAM_25_selectedOH;
  logic [4:0] g0_toSRAM_25_array;
  logic [8:0] g0_toSRAM_26_addr;
  logic [8:0] g0_toSRAM_26_addr_rd;
  logic [71:0] g0_toSRAM_26_wdata;
  logic g0_toSRAM_26_wmask;
  logic g0_toSRAM_26_re;
  logic g0_toSRAM_26_we;
  logic g0_toSRAM_26_ack;
  logic g0_toSRAM_26_selectedOH;
  logic [4:0] g0_toSRAM_26_array;
  logic [8:0] g0_toSRAM_27_addr;
  logic [8:0] g0_toSRAM_27_addr_rd;
  logic [71:0] g0_toSRAM_27_wdata;
  logic g0_toSRAM_27_wmask;
  logic g0_toSRAM_27_re;
  logic g0_toSRAM_27_we;
  logic g0_toSRAM_27_ack;
  logic g0_toSRAM_27_selectedOH;
  logic [4:0] g0_toSRAM_27_array;
  logic [8:0] g0_toSRAM_28_addr;
  logic [8:0] g0_toSRAM_28_addr_rd;
  logic [71:0] g0_toSRAM_28_wdata;
  logic g0_toSRAM_28_wmask;
  logic g0_toSRAM_28_re;
  logic g0_toSRAM_28_we;
  logic g0_toSRAM_28_ack;
  logic g0_toSRAM_28_selectedOH;
  logic [4:0] g0_toSRAM_28_array;
  logic [8:0] g0_toSRAM_29_addr;
  logic [8:0] g0_toSRAM_29_addr_rd;
  logic [71:0] g0_toSRAM_29_wdata;
  logic g0_toSRAM_29_wmask;
  logic g0_toSRAM_29_re;
  logic g0_toSRAM_29_we;
  logic g0_toSRAM_29_ack;
  logic g0_toSRAM_29_selectedOH;
  logic [4:0] g0_toSRAM_29_array;
  logic [8:0] g0_toSRAM_30_addr;
  logic [8:0] g0_toSRAM_30_addr_rd;
  logic [71:0] g0_toSRAM_30_wdata;
  logic g0_toSRAM_30_wmask;
  logic g0_toSRAM_30_re;
  logic g0_toSRAM_30_we;
  logic g0_toSRAM_30_ack;
  logic g0_toSRAM_30_selectedOH;
  logic [4:0] g0_toSRAM_30_array;
  logic [8:0] g0_toSRAM_31_addr;
  logic [8:0] g0_toSRAM_31_addr_rd;
  logic [71:0] g0_toSRAM_31_wdata;
  logic g0_toSRAM_31_wmask;
  logic g0_toSRAM_31_re;
  logic g0_toSRAM_31_we;
  logic g0_toSRAM_31_ack;
  logic g0_toSRAM_31_selectedOH;
  logic [4:0] g0_toSRAM_31_array;
  logic x0_mbist_ack;
  logic [71:0] x0_mbist_outdata;
  logic [8:0] x0_toSRAM_0_addr;
  logic [8:0] x0_toSRAM_0_addr_rd;
  logic [71:0] x0_toSRAM_0_wdata;
  logic x0_toSRAM_0_wmask;
  logic x0_toSRAM_0_re;
  logic x0_toSRAM_0_we;
  logic x0_toSRAM_0_ack;
  logic x0_toSRAM_0_selectedOH;
  logic x0_toSRAM_0_array;
  logic [8:0] x0_toSRAM_1_addr;
  logic [8:0] x0_toSRAM_1_addr_rd;
  logic [71:0] x0_toSRAM_1_wdata;
  logic x0_toSRAM_1_wmask;
  logic x0_toSRAM_1_re;
  logic x0_toSRAM_1_we;
  logic x0_toSRAM_1_ack;
  logic x0_toSRAM_1_selectedOH;
  logic x0_toSRAM_1_array;
  logic [8:0] x0_toSRAM_2_addr;
  logic [8:0] x0_toSRAM_2_addr_rd;
  logic [71:0] x0_toSRAM_2_wdata;
  logic x0_toSRAM_2_wmask;
  logic x0_toSRAM_2_re;
  logic x0_toSRAM_2_we;
  logic x0_toSRAM_2_ack;
  logic x0_toSRAM_2_selectedOH;
  logic [1:0] x0_toSRAM_2_array;
  logic [8:0] x0_toSRAM_3_addr;
  logic [8:0] x0_toSRAM_3_addr_rd;
  logic [71:0] x0_toSRAM_3_wdata;
  logic x0_toSRAM_3_wmask;
  logic x0_toSRAM_3_re;
  logic x0_toSRAM_3_we;
  logic x0_toSRAM_3_ack;
  logic x0_toSRAM_3_selectedOH;
  logic [1:0] x0_toSRAM_3_array;
  logic [8:0] x0_toSRAM_4_addr;
  logic [8:0] x0_toSRAM_4_addr_rd;
  logic [71:0] x0_toSRAM_4_wdata;
  logic x0_toSRAM_4_wmask;
  logic x0_toSRAM_4_re;
  logic x0_toSRAM_4_we;
  logic x0_toSRAM_4_ack;
  logic x0_toSRAM_4_selectedOH;
  logic [2:0] x0_toSRAM_4_array;
  logic [8:0] x0_toSRAM_5_addr;
  logic [8:0] x0_toSRAM_5_addr_rd;
  logic [71:0] x0_toSRAM_5_wdata;
  logic x0_toSRAM_5_wmask;
  logic x0_toSRAM_5_re;
  logic x0_toSRAM_5_we;
  logic x0_toSRAM_5_ack;
  logic x0_toSRAM_5_selectedOH;
  logic [2:0] x0_toSRAM_5_array;
  logic [8:0] x0_toSRAM_6_addr;
  logic [8:0] x0_toSRAM_6_addr_rd;
  logic [71:0] x0_toSRAM_6_wdata;
  logic x0_toSRAM_6_wmask;
  logic x0_toSRAM_6_re;
  logic x0_toSRAM_6_we;
  logic x0_toSRAM_6_ack;
  logic x0_toSRAM_6_selectedOH;
  logic [2:0] x0_toSRAM_6_array;
  logic [8:0] x0_toSRAM_7_addr;
  logic [8:0] x0_toSRAM_7_addr_rd;
  logic [71:0] x0_toSRAM_7_wdata;
  logic x0_toSRAM_7_wmask;
  logic x0_toSRAM_7_re;
  logic x0_toSRAM_7_we;
  logic x0_toSRAM_7_ack;
  logic x0_toSRAM_7_selectedOH;
  logic [2:0] x0_toSRAM_7_array;
  logic [8:0] x0_toSRAM_8_addr;
  logic [8:0] x0_toSRAM_8_addr_rd;
  logic [71:0] x0_toSRAM_8_wdata;
  logic x0_toSRAM_8_wmask;
  logic x0_toSRAM_8_re;
  logic x0_toSRAM_8_we;
  logic x0_toSRAM_8_ack;
  logic x0_toSRAM_8_selectedOH;
  logic [3:0] x0_toSRAM_8_array;
  logic [8:0] x0_toSRAM_9_addr;
  logic [8:0] x0_toSRAM_9_addr_rd;
  logic [71:0] x0_toSRAM_9_wdata;
  logic x0_toSRAM_9_wmask;
  logic x0_toSRAM_9_re;
  logic x0_toSRAM_9_we;
  logic x0_toSRAM_9_ack;
  logic x0_toSRAM_9_selectedOH;
  logic [3:0] x0_toSRAM_9_array;
  logic [8:0] x0_toSRAM_10_addr;
  logic [8:0] x0_toSRAM_10_addr_rd;
  logic [71:0] x0_toSRAM_10_wdata;
  logic x0_toSRAM_10_wmask;
  logic x0_toSRAM_10_re;
  logic x0_toSRAM_10_we;
  logic x0_toSRAM_10_ack;
  logic x0_toSRAM_10_selectedOH;
  logic [3:0] x0_toSRAM_10_array;
  logic [8:0] x0_toSRAM_11_addr;
  logic [8:0] x0_toSRAM_11_addr_rd;
  logic [71:0] x0_toSRAM_11_wdata;
  logic x0_toSRAM_11_wmask;
  logic x0_toSRAM_11_re;
  logic x0_toSRAM_11_we;
  logic x0_toSRAM_11_ack;
  logic x0_toSRAM_11_selectedOH;
  logic [3:0] x0_toSRAM_11_array;
  logic [8:0] x0_toSRAM_12_addr;
  logic [8:0] x0_toSRAM_12_addr_rd;
  logic [71:0] x0_toSRAM_12_wdata;
  logic x0_toSRAM_12_wmask;
  logic x0_toSRAM_12_re;
  logic x0_toSRAM_12_we;
  logic x0_toSRAM_12_ack;
  logic x0_toSRAM_12_selectedOH;
  logic [3:0] x0_toSRAM_12_array;
  logic [8:0] x0_toSRAM_13_addr;
  logic [8:0] x0_toSRAM_13_addr_rd;
  logic [71:0] x0_toSRAM_13_wdata;
  logic x0_toSRAM_13_wmask;
  logic x0_toSRAM_13_re;
  logic x0_toSRAM_13_we;
  logic x0_toSRAM_13_ack;
  logic x0_toSRAM_13_selectedOH;
  logic [3:0] x0_toSRAM_13_array;
  logic [8:0] x0_toSRAM_14_addr;
  logic [8:0] x0_toSRAM_14_addr_rd;
  logic [71:0] x0_toSRAM_14_wdata;
  logic x0_toSRAM_14_wmask;
  logic x0_toSRAM_14_re;
  logic x0_toSRAM_14_we;
  logic x0_toSRAM_14_ack;
  logic x0_toSRAM_14_selectedOH;
  logic [3:0] x0_toSRAM_14_array;
  logic [8:0] x0_toSRAM_15_addr;
  logic [8:0] x0_toSRAM_15_addr_rd;
  logic [71:0] x0_toSRAM_15_wdata;
  logic x0_toSRAM_15_wmask;
  logic x0_toSRAM_15_re;
  logic x0_toSRAM_15_we;
  logic x0_toSRAM_15_ack;
  logic x0_toSRAM_15_selectedOH;
  logic [3:0] x0_toSRAM_15_array;
  logic [8:0] x0_toSRAM_16_addr;
  logic [8:0] x0_toSRAM_16_addr_rd;
  logic [71:0] x0_toSRAM_16_wdata;
  logic x0_toSRAM_16_wmask;
  logic x0_toSRAM_16_re;
  logic x0_toSRAM_16_we;
  logic x0_toSRAM_16_ack;
  logic x0_toSRAM_16_selectedOH;
  logic [4:0] x0_toSRAM_16_array;
  logic [8:0] x0_toSRAM_17_addr;
  logic [8:0] x0_toSRAM_17_addr_rd;
  logic [71:0] x0_toSRAM_17_wdata;
  logic x0_toSRAM_17_wmask;
  logic x0_toSRAM_17_re;
  logic x0_toSRAM_17_we;
  logic x0_toSRAM_17_ack;
  logic x0_toSRAM_17_selectedOH;
  logic [4:0] x0_toSRAM_17_array;
  logic [8:0] x0_toSRAM_18_addr;
  logic [8:0] x0_toSRAM_18_addr_rd;
  logic [71:0] x0_toSRAM_18_wdata;
  logic x0_toSRAM_18_wmask;
  logic x0_toSRAM_18_re;
  logic x0_toSRAM_18_we;
  logic x0_toSRAM_18_ack;
  logic x0_toSRAM_18_selectedOH;
  logic [4:0] x0_toSRAM_18_array;
  logic [8:0] x0_toSRAM_19_addr;
  logic [8:0] x0_toSRAM_19_addr_rd;
  logic [71:0] x0_toSRAM_19_wdata;
  logic x0_toSRAM_19_wmask;
  logic x0_toSRAM_19_re;
  logic x0_toSRAM_19_we;
  logic x0_toSRAM_19_ack;
  logic x0_toSRAM_19_selectedOH;
  logic [4:0] x0_toSRAM_19_array;
  logic [8:0] x0_toSRAM_20_addr;
  logic [8:0] x0_toSRAM_20_addr_rd;
  logic [71:0] x0_toSRAM_20_wdata;
  logic x0_toSRAM_20_wmask;
  logic x0_toSRAM_20_re;
  logic x0_toSRAM_20_we;
  logic x0_toSRAM_20_ack;
  logic x0_toSRAM_20_selectedOH;
  logic [4:0] x0_toSRAM_20_array;
  logic [8:0] x0_toSRAM_21_addr;
  logic [8:0] x0_toSRAM_21_addr_rd;
  logic [71:0] x0_toSRAM_21_wdata;
  logic x0_toSRAM_21_wmask;
  logic x0_toSRAM_21_re;
  logic x0_toSRAM_21_we;
  logic x0_toSRAM_21_ack;
  logic x0_toSRAM_21_selectedOH;
  logic [4:0] x0_toSRAM_21_array;
  logic [8:0] x0_toSRAM_22_addr;
  logic [8:0] x0_toSRAM_22_addr_rd;
  logic [71:0] x0_toSRAM_22_wdata;
  logic x0_toSRAM_22_wmask;
  logic x0_toSRAM_22_re;
  logic x0_toSRAM_22_we;
  logic x0_toSRAM_22_ack;
  logic x0_toSRAM_22_selectedOH;
  logic [4:0] x0_toSRAM_22_array;
  logic [8:0] x0_toSRAM_23_addr;
  logic [8:0] x0_toSRAM_23_addr_rd;
  logic [71:0] x0_toSRAM_23_wdata;
  logic x0_toSRAM_23_wmask;
  logic x0_toSRAM_23_re;
  logic x0_toSRAM_23_we;
  logic x0_toSRAM_23_ack;
  logic x0_toSRAM_23_selectedOH;
  logic [4:0] x0_toSRAM_23_array;
  logic [8:0] x0_toSRAM_24_addr;
  logic [8:0] x0_toSRAM_24_addr_rd;
  logic [71:0] x0_toSRAM_24_wdata;
  logic x0_toSRAM_24_wmask;
  logic x0_toSRAM_24_re;
  logic x0_toSRAM_24_we;
  logic x0_toSRAM_24_ack;
  logic x0_toSRAM_24_selectedOH;
  logic [4:0] x0_toSRAM_24_array;
  logic [8:0] x0_toSRAM_25_addr;
  logic [8:0] x0_toSRAM_25_addr_rd;
  logic [71:0] x0_toSRAM_25_wdata;
  logic x0_toSRAM_25_wmask;
  logic x0_toSRAM_25_re;
  logic x0_toSRAM_25_we;
  logic x0_toSRAM_25_ack;
  logic x0_toSRAM_25_selectedOH;
  logic [4:0] x0_toSRAM_25_array;
  logic [8:0] x0_toSRAM_26_addr;
  logic [8:0] x0_toSRAM_26_addr_rd;
  logic [71:0] x0_toSRAM_26_wdata;
  logic x0_toSRAM_26_wmask;
  logic x0_toSRAM_26_re;
  logic x0_toSRAM_26_we;
  logic x0_toSRAM_26_ack;
  logic x0_toSRAM_26_selectedOH;
  logic [4:0] x0_toSRAM_26_array;
  logic [8:0] x0_toSRAM_27_addr;
  logic [8:0] x0_toSRAM_27_addr_rd;
  logic [71:0] x0_toSRAM_27_wdata;
  logic x0_toSRAM_27_wmask;
  logic x0_toSRAM_27_re;
  logic x0_toSRAM_27_we;
  logic x0_toSRAM_27_ack;
  logic x0_toSRAM_27_selectedOH;
  logic [4:0] x0_toSRAM_27_array;
  logic [8:0] x0_toSRAM_28_addr;
  logic [8:0] x0_toSRAM_28_addr_rd;
  logic [71:0] x0_toSRAM_28_wdata;
  logic x0_toSRAM_28_wmask;
  logic x0_toSRAM_28_re;
  logic x0_toSRAM_28_we;
  logic x0_toSRAM_28_ack;
  logic x0_toSRAM_28_selectedOH;
  logic [4:0] x0_toSRAM_28_array;
  logic [8:0] x0_toSRAM_29_addr;
  logic [8:0] x0_toSRAM_29_addr_rd;
  logic [71:0] x0_toSRAM_29_wdata;
  logic x0_toSRAM_29_wmask;
  logic x0_toSRAM_29_re;
  logic x0_toSRAM_29_we;
  logic x0_toSRAM_29_ack;
  logic x0_toSRAM_29_selectedOH;
  logic [4:0] x0_toSRAM_29_array;
  logic [8:0] x0_toSRAM_30_addr;
  logic [8:0] x0_toSRAM_30_addr_rd;
  logic [71:0] x0_toSRAM_30_wdata;
  logic x0_toSRAM_30_wmask;
  logic x0_toSRAM_30_re;
  logic x0_toSRAM_30_we;
  logic x0_toSRAM_30_ack;
  logic x0_toSRAM_30_selectedOH;
  logic [4:0] x0_toSRAM_30_array;
  logic [8:0] x0_toSRAM_31_addr;
  logic [8:0] x0_toSRAM_31_addr_rd;
  logic [71:0] x0_toSRAM_31_wdata;
  logic x0_toSRAM_31_wmask;
  logic x0_toSRAM_31_re;
  logic x0_toSRAM_31_we;
  logic x0_toSRAM_31_ack;
  logic x0_toSRAM_31_selectedOH;
  logic [4:0] x0_toSRAM_31_array;
  bit [31:0] cov_spread0;
  bit [71:0] cov_od0_0, cov_od1_0;
  bit cov_ack0_0, cov_ack1_0;
  MbistPipeDCacheData u_g0 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[4:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[71:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v0_rd0),
    .toSRAM_1_rdata (v0_rd1),
    .toSRAM_2_rdata (v0_rd2),
    .toSRAM_3_rdata (v0_rd3),
    .toSRAM_4_rdata (v0_rd4),
    .toSRAM_5_rdata (v0_rd5),
    .toSRAM_6_rdata (v0_rd6),
    .toSRAM_7_rdata (v0_rd7),
    .toSRAM_8_rdata (v0_rd8),
    .toSRAM_9_rdata (v0_rd9),
    .toSRAM_10_rdata (v0_rd10),
    .toSRAM_11_rdata (v0_rd11),
    .toSRAM_12_rdata (v0_rd12),
    .toSRAM_13_rdata (v0_rd13),
    .toSRAM_14_rdata (v0_rd14),
    .toSRAM_15_rdata (v0_rd15),
    .toSRAM_16_rdata (v0_rd16),
    .toSRAM_17_rdata (v0_rd17),
    .toSRAM_18_rdata (v0_rd18),
    .toSRAM_19_rdata (v0_rd19),
    .toSRAM_20_rdata (v0_rd20),
    .toSRAM_21_rdata (v0_rd21),
    .toSRAM_22_rdata (v0_rd22),
    .toSRAM_23_rdata (v0_rd23),
    .toSRAM_24_rdata (v0_rd24),
    .toSRAM_25_rdata (v0_rd25),
    .toSRAM_26_rdata (v0_rd26),
    .toSRAM_27_rdata (v0_rd27),
    .toSRAM_28_rdata (v0_rd28),
    .toSRAM_29_rdata (v0_rd29),
    .toSRAM_30_rdata (v0_rd30),
    .toSRAM_31_rdata (v0_rd31),
    .mbist_ack (g0_mbist_ack),
    .mbist_outdata (g0_mbist_outdata),
    .toSRAM_0_addr (g0_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g0_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g0_toSRAM_0_wdata),
    .toSRAM_0_wmask (g0_toSRAM_0_wmask),
    .toSRAM_0_re (g0_toSRAM_0_re),
    .toSRAM_0_we (g0_toSRAM_0_we),
    .toSRAM_0_ack (g0_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g0_toSRAM_0_selectedOH),
    .toSRAM_0_array (g0_toSRAM_0_array),
    .toSRAM_1_addr (g0_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g0_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g0_toSRAM_1_wdata),
    .toSRAM_1_wmask (g0_toSRAM_1_wmask),
    .toSRAM_1_re (g0_toSRAM_1_re),
    .toSRAM_1_we (g0_toSRAM_1_we),
    .toSRAM_1_ack (g0_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g0_toSRAM_1_selectedOH),
    .toSRAM_1_array (g0_toSRAM_1_array),
    .toSRAM_2_addr (g0_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g0_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g0_toSRAM_2_wdata),
    .toSRAM_2_wmask (g0_toSRAM_2_wmask),
    .toSRAM_2_re (g0_toSRAM_2_re),
    .toSRAM_2_we (g0_toSRAM_2_we),
    .toSRAM_2_ack (g0_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g0_toSRAM_2_selectedOH),
    .toSRAM_2_array (g0_toSRAM_2_array),
    .toSRAM_3_addr (g0_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g0_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g0_toSRAM_3_wdata),
    .toSRAM_3_wmask (g0_toSRAM_3_wmask),
    .toSRAM_3_re (g0_toSRAM_3_re),
    .toSRAM_3_we (g0_toSRAM_3_we),
    .toSRAM_3_ack (g0_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g0_toSRAM_3_selectedOH),
    .toSRAM_3_array (g0_toSRAM_3_array),
    .toSRAM_4_addr (g0_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g0_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g0_toSRAM_4_wdata),
    .toSRAM_4_wmask (g0_toSRAM_4_wmask),
    .toSRAM_4_re (g0_toSRAM_4_re),
    .toSRAM_4_we (g0_toSRAM_4_we),
    .toSRAM_4_ack (g0_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g0_toSRAM_4_selectedOH),
    .toSRAM_4_array (g0_toSRAM_4_array),
    .toSRAM_5_addr (g0_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g0_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g0_toSRAM_5_wdata),
    .toSRAM_5_wmask (g0_toSRAM_5_wmask),
    .toSRAM_5_re (g0_toSRAM_5_re),
    .toSRAM_5_we (g0_toSRAM_5_we),
    .toSRAM_5_ack (g0_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g0_toSRAM_5_selectedOH),
    .toSRAM_5_array (g0_toSRAM_5_array),
    .toSRAM_6_addr (g0_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g0_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g0_toSRAM_6_wdata),
    .toSRAM_6_wmask (g0_toSRAM_6_wmask),
    .toSRAM_6_re (g0_toSRAM_6_re),
    .toSRAM_6_we (g0_toSRAM_6_we),
    .toSRAM_6_ack (g0_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g0_toSRAM_6_selectedOH),
    .toSRAM_6_array (g0_toSRAM_6_array),
    .toSRAM_7_addr (g0_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g0_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g0_toSRAM_7_wdata),
    .toSRAM_7_wmask (g0_toSRAM_7_wmask),
    .toSRAM_7_re (g0_toSRAM_7_re),
    .toSRAM_7_we (g0_toSRAM_7_we),
    .toSRAM_7_ack (g0_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g0_toSRAM_7_selectedOH),
    .toSRAM_7_array (g0_toSRAM_7_array),
    .toSRAM_8_addr (g0_toSRAM_8_addr),
    .toSRAM_8_addr_rd (g0_toSRAM_8_addr_rd),
    .toSRAM_8_wdata (g0_toSRAM_8_wdata),
    .toSRAM_8_wmask (g0_toSRAM_8_wmask),
    .toSRAM_8_re (g0_toSRAM_8_re),
    .toSRAM_8_we (g0_toSRAM_8_we),
    .toSRAM_8_ack (g0_toSRAM_8_ack),
    .toSRAM_8_selectedOH (g0_toSRAM_8_selectedOH),
    .toSRAM_8_array (g0_toSRAM_8_array),
    .toSRAM_9_addr (g0_toSRAM_9_addr),
    .toSRAM_9_addr_rd (g0_toSRAM_9_addr_rd),
    .toSRAM_9_wdata (g0_toSRAM_9_wdata),
    .toSRAM_9_wmask (g0_toSRAM_9_wmask),
    .toSRAM_9_re (g0_toSRAM_9_re),
    .toSRAM_9_we (g0_toSRAM_9_we),
    .toSRAM_9_ack (g0_toSRAM_9_ack),
    .toSRAM_9_selectedOH (g0_toSRAM_9_selectedOH),
    .toSRAM_9_array (g0_toSRAM_9_array),
    .toSRAM_10_addr (g0_toSRAM_10_addr),
    .toSRAM_10_addr_rd (g0_toSRAM_10_addr_rd),
    .toSRAM_10_wdata (g0_toSRAM_10_wdata),
    .toSRAM_10_wmask (g0_toSRAM_10_wmask),
    .toSRAM_10_re (g0_toSRAM_10_re),
    .toSRAM_10_we (g0_toSRAM_10_we),
    .toSRAM_10_ack (g0_toSRAM_10_ack),
    .toSRAM_10_selectedOH (g0_toSRAM_10_selectedOH),
    .toSRAM_10_array (g0_toSRAM_10_array),
    .toSRAM_11_addr (g0_toSRAM_11_addr),
    .toSRAM_11_addr_rd (g0_toSRAM_11_addr_rd),
    .toSRAM_11_wdata (g0_toSRAM_11_wdata),
    .toSRAM_11_wmask (g0_toSRAM_11_wmask),
    .toSRAM_11_re (g0_toSRAM_11_re),
    .toSRAM_11_we (g0_toSRAM_11_we),
    .toSRAM_11_ack (g0_toSRAM_11_ack),
    .toSRAM_11_selectedOH (g0_toSRAM_11_selectedOH),
    .toSRAM_11_array (g0_toSRAM_11_array),
    .toSRAM_12_addr (g0_toSRAM_12_addr),
    .toSRAM_12_addr_rd (g0_toSRAM_12_addr_rd),
    .toSRAM_12_wdata (g0_toSRAM_12_wdata),
    .toSRAM_12_wmask (g0_toSRAM_12_wmask),
    .toSRAM_12_re (g0_toSRAM_12_re),
    .toSRAM_12_we (g0_toSRAM_12_we),
    .toSRAM_12_ack (g0_toSRAM_12_ack),
    .toSRAM_12_selectedOH (g0_toSRAM_12_selectedOH),
    .toSRAM_12_array (g0_toSRAM_12_array),
    .toSRAM_13_addr (g0_toSRAM_13_addr),
    .toSRAM_13_addr_rd (g0_toSRAM_13_addr_rd),
    .toSRAM_13_wdata (g0_toSRAM_13_wdata),
    .toSRAM_13_wmask (g0_toSRAM_13_wmask),
    .toSRAM_13_re (g0_toSRAM_13_re),
    .toSRAM_13_we (g0_toSRAM_13_we),
    .toSRAM_13_ack (g0_toSRAM_13_ack),
    .toSRAM_13_selectedOH (g0_toSRAM_13_selectedOH),
    .toSRAM_13_array (g0_toSRAM_13_array),
    .toSRAM_14_addr (g0_toSRAM_14_addr),
    .toSRAM_14_addr_rd (g0_toSRAM_14_addr_rd),
    .toSRAM_14_wdata (g0_toSRAM_14_wdata),
    .toSRAM_14_wmask (g0_toSRAM_14_wmask),
    .toSRAM_14_re (g0_toSRAM_14_re),
    .toSRAM_14_we (g0_toSRAM_14_we),
    .toSRAM_14_ack (g0_toSRAM_14_ack),
    .toSRAM_14_selectedOH (g0_toSRAM_14_selectedOH),
    .toSRAM_14_array (g0_toSRAM_14_array),
    .toSRAM_15_addr (g0_toSRAM_15_addr),
    .toSRAM_15_addr_rd (g0_toSRAM_15_addr_rd),
    .toSRAM_15_wdata (g0_toSRAM_15_wdata),
    .toSRAM_15_wmask (g0_toSRAM_15_wmask),
    .toSRAM_15_re (g0_toSRAM_15_re),
    .toSRAM_15_we (g0_toSRAM_15_we),
    .toSRAM_15_ack (g0_toSRAM_15_ack),
    .toSRAM_15_selectedOH (g0_toSRAM_15_selectedOH),
    .toSRAM_15_array (g0_toSRAM_15_array),
    .toSRAM_16_addr (g0_toSRAM_16_addr),
    .toSRAM_16_addr_rd (g0_toSRAM_16_addr_rd),
    .toSRAM_16_wdata (g0_toSRAM_16_wdata),
    .toSRAM_16_wmask (g0_toSRAM_16_wmask),
    .toSRAM_16_re (g0_toSRAM_16_re),
    .toSRAM_16_we (g0_toSRAM_16_we),
    .toSRAM_16_ack (g0_toSRAM_16_ack),
    .toSRAM_16_selectedOH (g0_toSRAM_16_selectedOH),
    .toSRAM_16_array (g0_toSRAM_16_array),
    .toSRAM_17_addr (g0_toSRAM_17_addr),
    .toSRAM_17_addr_rd (g0_toSRAM_17_addr_rd),
    .toSRAM_17_wdata (g0_toSRAM_17_wdata),
    .toSRAM_17_wmask (g0_toSRAM_17_wmask),
    .toSRAM_17_re (g0_toSRAM_17_re),
    .toSRAM_17_we (g0_toSRAM_17_we),
    .toSRAM_17_ack (g0_toSRAM_17_ack),
    .toSRAM_17_selectedOH (g0_toSRAM_17_selectedOH),
    .toSRAM_17_array (g0_toSRAM_17_array),
    .toSRAM_18_addr (g0_toSRAM_18_addr),
    .toSRAM_18_addr_rd (g0_toSRAM_18_addr_rd),
    .toSRAM_18_wdata (g0_toSRAM_18_wdata),
    .toSRAM_18_wmask (g0_toSRAM_18_wmask),
    .toSRAM_18_re (g0_toSRAM_18_re),
    .toSRAM_18_we (g0_toSRAM_18_we),
    .toSRAM_18_ack (g0_toSRAM_18_ack),
    .toSRAM_18_selectedOH (g0_toSRAM_18_selectedOH),
    .toSRAM_18_array (g0_toSRAM_18_array),
    .toSRAM_19_addr (g0_toSRAM_19_addr),
    .toSRAM_19_addr_rd (g0_toSRAM_19_addr_rd),
    .toSRAM_19_wdata (g0_toSRAM_19_wdata),
    .toSRAM_19_wmask (g0_toSRAM_19_wmask),
    .toSRAM_19_re (g0_toSRAM_19_re),
    .toSRAM_19_we (g0_toSRAM_19_we),
    .toSRAM_19_ack (g0_toSRAM_19_ack),
    .toSRAM_19_selectedOH (g0_toSRAM_19_selectedOH),
    .toSRAM_19_array (g0_toSRAM_19_array),
    .toSRAM_20_addr (g0_toSRAM_20_addr),
    .toSRAM_20_addr_rd (g0_toSRAM_20_addr_rd),
    .toSRAM_20_wdata (g0_toSRAM_20_wdata),
    .toSRAM_20_wmask (g0_toSRAM_20_wmask),
    .toSRAM_20_re (g0_toSRAM_20_re),
    .toSRAM_20_we (g0_toSRAM_20_we),
    .toSRAM_20_ack (g0_toSRAM_20_ack),
    .toSRAM_20_selectedOH (g0_toSRAM_20_selectedOH),
    .toSRAM_20_array (g0_toSRAM_20_array),
    .toSRAM_21_addr (g0_toSRAM_21_addr),
    .toSRAM_21_addr_rd (g0_toSRAM_21_addr_rd),
    .toSRAM_21_wdata (g0_toSRAM_21_wdata),
    .toSRAM_21_wmask (g0_toSRAM_21_wmask),
    .toSRAM_21_re (g0_toSRAM_21_re),
    .toSRAM_21_we (g0_toSRAM_21_we),
    .toSRAM_21_ack (g0_toSRAM_21_ack),
    .toSRAM_21_selectedOH (g0_toSRAM_21_selectedOH),
    .toSRAM_21_array (g0_toSRAM_21_array),
    .toSRAM_22_addr (g0_toSRAM_22_addr),
    .toSRAM_22_addr_rd (g0_toSRAM_22_addr_rd),
    .toSRAM_22_wdata (g0_toSRAM_22_wdata),
    .toSRAM_22_wmask (g0_toSRAM_22_wmask),
    .toSRAM_22_re (g0_toSRAM_22_re),
    .toSRAM_22_we (g0_toSRAM_22_we),
    .toSRAM_22_ack (g0_toSRAM_22_ack),
    .toSRAM_22_selectedOH (g0_toSRAM_22_selectedOH),
    .toSRAM_22_array (g0_toSRAM_22_array),
    .toSRAM_23_addr (g0_toSRAM_23_addr),
    .toSRAM_23_addr_rd (g0_toSRAM_23_addr_rd),
    .toSRAM_23_wdata (g0_toSRAM_23_wdata),
    .toSRAM_23_wmask (g0_toSRAM_23_wmask),
    .toSRAM_23_re (g0_toSRAM_23_re),
    .toSRAM_23_we (g0_toSRAM_23_we),
    .toSRAM_23_ack (g0_toSRAM_23_ack),
    .toSRAM_23_selectedOH (g0_toSRAM_23_selectedOH),
    .toSRAM_23_array (g0_toSRAM_23_array),
    .toSRAM_24_addr (g0_toSRAM_24_addr),
    .toSRAM_24_addr_rd (g0_toSRAM_24_addr_rd),
    .toSRAM_24_wdata (g0_toSRAM_24_wdata),
    .toSRAM_24_wmask (g0_toSRAM_24_wmask),
    .toSRAM_24_re (g0_toSRAM_24_re),
    .toSRAM_24_we (g0_toSRAM_24_we),
    .toSRAM_24_ack (g0_toSRAM_24_ack),
    .toSRAM_24_selectedOH (g0_toSRAM_24_selectedOH),
    .toSRAM_24_array (g0_toSRAM_24_array),
    .toSRAM_25_addr (g0_toSRAM_25_addr),
    .toSRAM_25_addr_rd (g0_toSRAM_25_addr_rd),
    .toSRAM_25_wdata (g0_toSRAM_25_wdata),
    .toSRAM_25_wmask (g0_toSRAM_25_wmask),
    .toSRAM_25_re (g0_toSRAM_25_re),
    .toSRAM_25_we (g0_toSRAM_25_we),
    .toSRAM_25_ack (g0_toSRAM_25_ack),
    .toSRAM_25_selectedOH (g0_toSRAM_25_selectedOH),
    .toSRAM_25_array (g0_toSRAM_25_array),
    .toSRAM_26_addr (g0_toSRAM_26_addr),
    .toSRAM_26_addr_rd (g0_toSRAM_26_addr_rd),
    .toSRAM_26_wdata (g0_toSRAM_26_wdata),
    .toSRAM_26_wmask (g0_toSRAM_26_wmask),
    .toSRAM_26_re (g0_toSRAM_26_re),
    .toSRAM_26_we (g0_toSRAM_26_we),
    .toSRAM_26_ack (g0_toSRAM_26_ack),
    .toSRAM_26_selectedOH (g0_toSRAM_26_selectedOH),
    .toSRAM_26_array (g0_toSRAM_26_array),
    .toSRAM_27_addr (g0_toSRAM_27_addr),
    .toSRAM_27_addr_rd (g0_toSRAM_27_addr_rd),
    .toSRAM_27_wdata (g0_toSRAM_27_wdata),
    .toSRAM_27_wmask (g0_toSRAM_27_wmask),
    .toSRAM_27_re (g0_toSRAM_27_re),
    .toSRAM_27_we (g0_toSRAM_27_we),
    .toSRAM_27_ack (g0_toSRAM_27_ack),
    .toSRAM_27_selectedOH (g0_toSRAM_27_selectedOH),
    .toSRAM_27_array (g0_toSRAM_27_array),
    .toSRAM_28_addr (g0_toSRAM_28_addr),
    .toSRAM_28_addr_rd (g0_toSRAM_28_addr_rd),
    .toSRAM_28_wdata (g0_toSRAM_28_wdata),
    .toSRAM_28_wmask (g0_toSRAM_28_wmask),
    .toSRAM_28_re (g0_toSRAM_28_re),
    .toSRAM_28_we (g0_toSRAM_28_we),
    .toSRAM_28_ack (g0_toSRAM_28_ack),
    .toSRAM_28_selectedOH (g0_toSRAM_28_selectedOH),
    .toSRAM_28_array (g0_toSRAM_28_array),
    .toSRAM_29_addr (g0_toSRAM_29_addr),
    .toSRAM_29_addr_rd (g0_toSRAM_29_addr_rd),
    .toSRAM_29_wdata (g0_toSRAM_29_wdata),
    .toSRAM_29_wmask (g0_toSRAM_29_wmask),
    .toSRAM_29_re (g0_toSRAM_29_re),
    .toSRAM_29_we (g0_toSRAM_29_we),
    .toSRAM_29_ack (g0_toSRAM_29_ack),
    .toSRAM_29_selectedOH (g0_toSRAM_29_selectedOH),
    .toSRAM_29_array (g0_toSRAM_29_array),
    .toSRAM_30_addr (g0_toSRAM_30_addr),
    .toSRAM_30_addr_rd (g0_toSRAM_30_addr_rd),
    .toSRAM_30_wdata (g0_toSRAM_30_wdata),
    .toSRAM_30_wmask (g0_toSRAM_30_wmask),
    .toSRAM_30_re (g0_toSRAM_30_re),
    .toSRAM_30_we (g0_toSRAM_30_we),
    .toSRAM_30_ack (g0_toSRAM_30_ack),
    .toSRAM_30_selectedOH (g0_toSRAM_30_selectedOH),
    .toSRAM_30_array (g0_toSRAM_30_array),
    .toSRAM_31_addr (g0_toSRAM_31_addr),
    .toSRAM_31_addr_rd (g0_toSRAM_31_addr_rd),
    .toSRAM_31_wdata (g0_toSRAM_31_wdata),
    .toSRAM_31_wmask (g0_toSRAM_31_wmask),
    .toSRAM_31_re (g0_toSRAM_31_re),
    .toSRAM_31_we (g0_toSRAM_31_we),
    .toSRAM_31_ack (g0_toSRAM_31_ack),
    .toSRAM_31_selectedOH (g0_toSRAM_31_selectedOH),
    .toSRAM_31_array (g0_toSRAM_31_array)
  );
  MbistPipeDCacheData_xs u_x0 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[4:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[71:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v0_rd0),
    .toSRAM_1_rdata (v0_rd1),
    .toSRAM_2_rdata (v0_rd2),
    .toSRAM_3_rdata (v0_rd3),
    .toSRAM_4_rdata (v0_rd4),
    .toSRAM_5_rdata (v0_rd5),
    .toSRAM_6_rdata (v0_rd6),
    .toSRAM_7_rdata (v0_rd7),
    .toSRAM_8_rdata (v0_rd8),
    .toSRAM_9_rdata (v0_rd9),
    .toSRAM_10_rdata (v0_rd10),
    .toSRAM_11_rdata (v0_rd11),
    .toSRAM_12_rdata (v0_rd12),
    .toSRAM_13_rdata (v0_rd13),
    .toSRAM_14_rdata (v0_rd14),
    .toSRAM_15_rdata (v0_rd15),
    .toSRAM_16_rdata (v0_rd16),
    .toSRAM_17_rdata (v0_rd17),
    .toSRAM_18_rdata (v0_rd18),
    .toSRAM_19_rdata (v0_rd19),
    .toSRAM_20_rdata (v0_rd20),
    .toSRAM_21_rdata (v0_rd21),
    .toSRAM_22_rdata (v0_rd22),
    .toSRAM_23_rdata (v0_rd23),
    .toSRAM_24_rdata (v0_rd24),
    .toSRAM_25_rdata (v0_rd25),
    .toSRAM_26_rdata (v0_rd26),
    .toSRAM_27_rdata (v0_rd27),
    .toSRAM_28_rdata (v0_rd28),
    .toSRAM_29_rdata (v0_rd29),
    .toSRAM_30_rdata (v0_rd30),
    .toSRAM_31_rdata (v0_rd31),
    .mbist_ack (x0_mbist_ack),
    .mbist_outdata (x0_mbist_outdata),
    .toSRAM_0_addr (x0_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x0_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x0_toSRAM_0_wdata),
    .toSRAM_0_wmask (x0_toSRAM_0_wmask),
    .toSRAM_0_re (x0_toSRAM_0_re),
    .toSRAM_0_we (x0_toSRAM_0_we),
    .toSRAM_0_ack (x0_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x0_toSRAM_0_selectedOH),
    .toSRAM_0_array (x0_toSRAM_0_array),
    .toSRAM_1_addr (x0_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x0_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x0_toSRAM_1_wdata),
    .toSRAM_1_wmask (x0_toSRAM_1_wmask),
    .toSRAM_1_re (x0_toSRAM_1_re),
    .toSRAM_1_we (x0_toSRAM_1_we),
    .toSRAM_1_ack (x0_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x0_toSRAM_1_selectedOH),
    .toSRAM_1_array (x0_toSRAM_1_array),
    .toSRAM_2_addr (x0_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x0_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x0_toSRAM_2_wdata),
    .toSRAM_2_wmask (x0_toSRAM_2_wmask),
    .toSRAM_2_re (x0_toSRAM_2_re),
    .toSRAM_2_we (x0_toSRAM_2_we),
    .toSRAM_2_ack (x0_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x0_toSRAM_2_selectedOH),
    .toSRAM_2_array (x0_toSRAM_2_array),
    .toSRAM_3_addr (x0_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x0_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x0_toSRAM_3_wdata),
    .toSRAM_3_wmask (x0_toSRAM_3_wmask),
    .toSRAM_3_re (x0_toSRAM_3_re),
    .toSRAM_3_we (x0_toSRAM_3_we),
    .toSRAM_3_ack (x0_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x0_toSRAM_3_selectedOH),
    .toSRAM_3_array (x0_toSRAM_3_array),
    .toSRAM_4_addr (x0_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x0_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x0_toSRAM_4_wdata),
    .toSRAM_4_wmask (x0_toSRAM_4_wmask),
    .toSRAM_4_re (x0_toSRAM_4_re),
    .toSRAM_4_we (x0_toSRAM_4_we),
    .toSRAM_4_ack (x0_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x0_toSRAM_4_selectedOH),
    .toSRAM_4_array (x0_toSRAM_4_array),
    .toSRAM_5_addr (x0_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x0_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x0_toSRAM_5_wdata),
    .toSRAM_5_wmask (x0_toSRAM_5_wmask),
    .toSRAM_5_re (x0_toSRAM_5_re),
    .toSRAM_5_we (x0_toSRAM_5_we),
    .toSRAM_5_ack (x0_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x0_toSRAM_5_selectedOH),
    .toSRAM_5_array (x0_toSRAM_5_array),
    .toSRAM_6_addr (x0_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x0_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x0_toSRAM_6_wdata),
    .toSRAM_6_wmask (x0_toSRAM_6_wmask),
    .toSRAM_6_re (x0_toSRAM_6_re),
    .toSRAM_6_we (x0_toSRAM_6_we),
    .toSRAM_6_ack (x0_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x0_toSRAM_6_selectedOH),
    .toSRAM_6_array (x0_toSRAM_6_array),
    .toSRAM_7_addr (x0_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x0_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x0_toSRAM_7_wdata),
    .toSRAM_7_wmask (x0_toSRAM_7_wmask),
    .toSRAM_7_re (x0_toSRAM_7_re),
    .toSRAM_7_we (x0_toSRAM_7_we),
    .toSRAM_7_ack (x0_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x0_toSRAM_7_selectedOH),
    .toSRAM_7_array (x0_toSRAM_7_array),
    .toSRAM_8_addr (x0_toSRAM_8_addr),
    .toSRAM_8_addr_rd (x0_toSRAM_8_addr_rd),
    .toSRAM_8_wdata (x0_toSRAM_8_wdata),
    .toSRAM_8_wmask (x0_toSRAM_8_wmask),
    .toSRAM_8_re (x0_toSRAM_8_re),
    .toSRAM_8_we (x0_toSRAM_8_we),
    .toSRAM_8_ack (x0_toSRAM_8_ack),
    .toSRAM_8_selectedOH (x0_toSRAM_8_selectedOH),
    .toSRAM_8_array (x0_toSRAM_8_array),
    .toSRAM_9_addr (x0_toSRAM_9_addr),
    .toSRAM_9_addr_rd (x0_toSRAM_9_addr_rd),
    .toSRAM_9_wdata (x0_toSRAM_9_wdata),
    .toSRAM_9_wmask (x0_toSRAM_9_wmask),
    .toSRAM_9_re (x0_toSRAM_9_re),
    .toSRAM_9_we (x0_toSRAM_9_we),
    .toSRAM_9_ack (x0_toSRAM_9_ack),
    .toSRAM_9_selectedOH (x0_toSRAM_9_selectedOH),
    .toSRAM_9_array (x0_toSRAM_9_array),
    .toSRAM_10_addr (x0_toSRAM_10_addr),
    .toSRAM_10_addr_rd (x0_toSRAM_10_addr_rd),
    .toSRAM_10_wdata (x0_toSRAM_10_wdata),
    .toSRAM_10_wmask (x0_toSRAM_10_wmask),
    .toSRAM_10_re (x0_toSRAM_10_re),
    .toSRAM_10_we (x0_toSRAM_10_we),
    .toSRAM_10_ack (x0_toSRAM_10_ack),
    .toSRAM_10_selectedOH (x0_toSRAM_10_selectedOH),
    .toSRAM_10_array (x0_toSRAM_10_array),
    .toSRAM_11_addr (x0_toSRAM_11_addr),
    .toSRAM_11_addr_rd (x0_toSRAM_11_addr_rd),
    .toSRAM_11_wdata (x0_toSRAM_11_wdata),
    .toSRAM_11_wmask (x0_toSRAM_11_wmask),
    .toSRAM_11_re (x0_toSRAM_11_re),
    .toSRAM_11_we (x0_toSRAM_11_we),
    .toSRAM_11_ack (x0_toSRAM_11_ack),
    .toSRAM_11_selectedOH (x0_toSRAM_11_selectedOH),
    .toSRAM_11_array (x0_toSRAM_11_array),
    .toSRAM_12_addr (x0_toSRAM_12_addr),
    .toSRAM_12_addr_rd (x0_toSRAM_12_addr_rd),
    .toSRAM_12_wdata (x0_toSRAM_12_wdata),
    .toSRAM_12_wmask (x0_toSRAM_12_wmask),
    .toSRAM_12_re (x0_toSRAM_12_re),
    .toSRAM_12_we (x0_toSRAM_12_we),
    .toSRAM_12_ack (x0_toSRAM_12_ack),
    .toSRAM_12_selectedOH (x0_toSRAM_12_selectedOH),
    .toSRAM_12_array (x0_toSRAM_12_array),
    .toSRAM_13_addr (x0_toSRAM_13_addr),
    .toSRAM_13_addr_rd (x0_toSRAM_13_addr_rd),
    .toSRAM_13_wdata (x0_toSRAM_13_wdata),
    .toSRAM_13_wmask (x0_toSRAM_13_wmask),
    .toSRAM_13_re (x0_toSRAM_13_re),
    .toSRAM_13_we (x0_toSRAM_13_we),
    .toSRAM_13_ack (x0_toSRAM_13_ack),
    .toSRAM_13_selectedOH (x0_toSRAM_13_selectedOH),
    .toSRAM_13_array (x0_toSRAM_13_array),
    .toSRAM_14_addr (x0_toSRAM_14_addr),
    .toSRAM_14_addr_rd (x0_toSRAM_14_addr_rd),
    .toSRAM_14_wdata (x0_toSRAM_14_wdata),
    .toSRAM_14_wmask (x0_toSRAM_14_wmask),
    .toSRAM_14_re (x0_toSRAM_14_re),
    .toSRAM_14_we (x0_toSRAM_14_we),
    .toSRAM_14_ack (x0_toSRAM_14_ack),
    .toSRAM_14_selectedOH (x0_toSRAM_14_selectedOH),
    .toSRAM_14_array (x0_toSRAM_14_array),
    .toSRAM_15_addr (x0_toSRAM_15_addr),
    .toSRAM_15_addr_rd (x0_toSRAM_15_addr_rd),
    .toSRAM_15_wdata (x0_toSRAM_15_wdata),
    .toSRAM_15_wmask (x0_toSRAM_15_wmask),
    .toSRAM_15_re (x0_toSRAM_15_re),
    .toSRAM_15_we (x0_toSRAM_15_we),
    .toSRAM_15_ack (x0_toSRAM_15_ack),
    .toSRAM_15_selectedOH (x0_toSRAM_15_selectedOH),
    .toSRAM_15_array (x0_toSRAM_15_array),
    .toSRAM_16_addr (x0_toSRAM_16_addr),
    .toSRAM_16_addr_rd (x0_toSRAM_16_addr_rd),
    .toSRAM_16_wdata (x0_toSRAM_16_wdata),
    .toSRAM_16_wmask (x0_toSRAM_16_wmask),
    .toSRAM_16_re (x0_toSRAM_16_re),
    .toSRAM_16_we (x0_toSRAM_16_we),
    .toSRAM_16_ack (x0_toSRAM_16_ack),
    .toSRAM_16_selectedOH (x0_toSRAM_16_selectedOH),
    .toSRAM_16_array (x0_toSRAM_16_array),
    .toSRAM_17_addr (x0_toSRAM_17_addr),
    .toSRAM_17_addr_rd (x0_toSRAM_17_addr_rd),
    .toSRAM_17_wdata (x0_toSRAM_17_wdata),
    .toSRAM_17_wmask (x0_toSRAM_17_wmask),
    .toSRAM_17_re (x0_toSRAM_17_re),
    .toSRAM_17_we (x0_toSRAM_17_we),
    .toSRAM_17_ack (x0_toSRAM_17_ack),
    .toSRAM_17_selectedOH (x0_toSRAM_17_selectedOH),
    .toSRAM_17_array (x0_toSRAM_17_array),
    .toSRAM_18_addr (x0_toSRAM_18_addr),
    .toSRAM_18_addr_rd (x0_toSRAM_18_addr_rd),
    .toSRAM_18_wdata (x0_toSRAM_18_wdata),
    .toSRAM_18_wmask (x0_toSRAM_18_wmask),
    .toSRAM_18_re (x0_toSRAM_18_re),
    .toSRAM_18_we (x0_toSRAM_18_we),
    .toSRAM_18_ack (x0_toSRAM_18_ack),
    .toSRAM_18_selectedOH (x0_toSRAM_18_selectedOH),
    .toSRAM_18_array (x0_toSRAM_18_array),
    .toSRAM_19_addr (x0_toSRAM_19_addr),
    .toSRAM_19_addr_rd (x0_toSRAM_19_addr_rd),
    .toSRAM_19_wdata (x0_toSRAM_19_wdata),
    .toSRAM_19_wmask (x0_toSRAM_19_wmask),
    .toSRAM_19_re (x0_toSRAM_19_re),
    .toSRAM_19_we (x0_toSRAM_19_we),
    .toSRAM_19_ack (x0_toSRAM_19_ack),
    .toSRAM_19_selectedOH (x0_toSRAM_19_selectedOH),
    .toSRAM_19_array (x0_toSRAM_19_array),
    .toSRAM_20_addr (x0_toSRAM_20_addr),
    .toSRAM_20_addr_rd (x0_toSRAM_20_addr_rd),
    .toSRAM_20_wdata (x0_toSRAM_20_wdata),
    .toSRAM_20_wmask (x0_toSRAM_20_wmask),
    .toSRAM_20_re (x0_toSRAM_20_re),
    .toSRAM_20_we (x0_toSRAM_20_we),
    .toSRAM_20_ack (x0_toSRAM_20_ack),
    .toSRAM_20_selectedOH (x0_toSRAM_20_selectedOH),
    .toSRAM_20_array (x0_toSRAM_20_array),
    .toSRAM_21_addr (x0_toSRAM_21_addr),
    .toSRAM_21_addr_rd (x0_toSRAM_21_addr_rd),
    .toSRAM_21_wdata (x0_toSRAM_21_wdata),
    .toSRAM_21_wmask (x0_toSRAM_21_wmask),
    .toSRAM_21_re (x0_toSRAM_21_re),
    .toSRAM_21_we (x0_toSRAM_21_we),
    .toSRAM_21_ack (x0_toSRAM_21_ack),
    .toSRAM_21_selectedOH (x0_toSRAM_21_selectedOH),
    .toSRAM_21_array (x0_toSRAM_21_array),
    .toSRAM_22_addr (x0_toSRAM_22_addr),
    .toSRAM_22_addr_rd (x0_toSRAM_22_addr_rd),
    .toSRAM_22_wdata (x0_toSRAM_22_wdata),
    .toSRAM_22_wmask (x0_toSRAM_22_wmask),
    .toSRAM_22_re (x0_toSRAM_22_re),
    .toSRAM_22_we (x0_toSRAM_22_we),
    .toSRAM_22_ack (x0_toSRAM_22_ack),
    .toSRAM_22_selectedOH (x0_toSRAM_22_selectedOH),
    .toSRAM_22_array (x0_toSRAM_22_array),
    .toSRAM_23_addr (x0_toSRAM_23_addr),
    .toSRAM_23_addr_rd (x0_toSRAM_23_addr_rd),
    .toSRAM_23_wdata (x0_toSRAM_23_wdata),
    .toSRAM_23_wmask (x0_toSRAM_23_wmask),
    .toSRAM_23_re (x0_toSRAM_23_re),
    .toSRAM_23_we (x0_toSRAM_23_we),
    .toSRAM_23_ack (x0_toSRAM_23_ack),
    .toSRAM_23_selectedOH (x0_toSRAM_23_selectedOH),
    .toSRAM_23_array (x0_toSRAM_23_array),
    .toSRAM_24_addr (x0_toSRAM_24_addr),
    .toSRAM_24_addr_rd (x0_toSRAM_24_addr_rd),
    .toSRAM_24_wdata (x0_toSRAM_24_wdata),
    .toSRAM_24_wmask (x0_toSRAM_24_wmask),
    .toSRAM_24_re (x0_toSRAM_24_re),
    .toSRAM_24_we (x0_toSRAM_24_we),
    .toSRAM_24_ack (x0_toSRAM_24_ack),
    .toSRAM_24_selectedOH (x0_toSRAM_24_selectedOH),
    .toSRAM_24_array (x0_toSRAM_24_array),
    .toSRAM_25_addr (x0_toSRAM_25_addr),
    .toSRAM_25_addr_rd (x0_toSRAM_25_addr_rd),
    .toSRAM_25_wdata (x0_toSRAM_25_wdata),
    .toSRAM_25_wmask (x0_toSRAM_25_wmask),
    .toSRAM_25_re (x0_toSRAM_25_re),
    .toSRAM_25_we (x0_toSRAM_25_we),
    .toSRAM_25_ack (x0_toSRAM_25_ack),
    .toSRAM_25_selectedOH (x0_toSRAM_25_selectedOH),
    .toSRAM_25_array (x0_toSRAM_25_array),
    .toSRAM_26_addr (x0_toSRAM_26_addr),
    .toSRAM_26_addr_rd (x0_toSRAM_26_addr_rd),
    .toSRAM_26_wdata (x0_toSRAM_26_wdata),
    .toSRAM_26_wmask (x0_toSRAM_26_wmask),
    .toSRAM_26_re (x0_toSRAM_26_re),
    .toSRAM_26_we (x0_toSRAM_26_we),
    .toSRAM_26_ack (x0_toSRAM_26_ack),
    .toSRAM_26_selectedOH (x0_toSRAM_26_selectedOH),
    .toSRAM_26_array (x0_toSRAM_26_array),
    .toSRAM_27_addr (x0_toSRAM_27_addr),
    .toSRAM_27_addr_rd (x0_toSRAM_27_addr_rd),
    .toSRAM_27_wdata (x0_toSRAM_27_wdata),
    .toSRAM_27_wmask (x0_toSRAM_27_wmask),
    .toSRAM_27_re (x0_toSRAM_27_re),
    .toSRAM_27_we (x0_toSRAM_27_we),
    .toSRAM_27_ack (x0_toSRAM_27_ack),
    .toSRAM_27_selectedOH (x0_toSRAM_27_selectedOH),
    .toSRAM_27_array (x0_toSRAM_27_array),
    .toSRAM_28_addr (x0_toSRAM_28_addr),
    .toSRAM_28_addr_rd (x0_toSRAM_28_addr_rd),
    .toSRAM_28_wdata (x0_toSRAM_28_wdata),
    .toSRAM_28_wmask (x0_toSRAM_28_wmask),
    .toSRAM_28_re (x0_toSRAM_28_re),
    .toSRAM_28_we (x0_toSRAM_28_we),
    .toSRAM_28_ack (x0_toSRAM_28_ack),
    .toSRAM_28_selectedOH (x0_toSRAM_28_selectedOH),
    .toSRAM_28_array (x0_toSRAM_28_array),
    .toSRAM_29_addr (x0_toSRAM_29_addr),
    .toSRAM_29_addr_rd (x0_toSRAM_29_addr_rd),
    .toSRAM_29_wdata (x0_toSRAM_29_wdata),
    .toSRAM_29_wmask (x0_toSRAM_29_wmask),
    .toSRAM_29_re (x0_toSRAM_29_re),
    .toSRAM_29_we (x0_toSRAM_29_we),
    .toSRAM_29_ack (x0_toSRAM_29_ack),
    .toSRAM_29_selectedOH (x0_toSRAM_29_selectedOH),
    .toSRAM_29_array (x0_toSRAM_29_array),
    .toSRAM_30_addr (x0_toSRAM_30_addr),
    .toSRAM_30_addr_rd (x0_toSRAM_30_addr_rd),
    .toSRAM_30_wdata (x0_toSRAM_30_wdata),
    .toSRAM_30_wmask (x0_toSRAM_30_wmask),
    .toSRAM_30_re (x0_toSRAM_30_re),
    .toSRAM_30_we (x0_toSRAM_30_we),
    .toSRAM_30_ack (x0_toSRAM_30_ack),
    .toSRAM_30_selectedOH (x0_toSRAM_30_selectedOH),
    .toSRAM_30_array (x0_toSRAM_30_array),
    .toSRAM_31_addr (x0_toSRAM_31_addr),
    .toSRAM_31_addr_rd (x0_toSRAM_31_addr_rd),
    .toSRAM_31_wdata (x0_toSRAM_31_wdata),
    .toSRAM_31_wmask (x0_toSRAM_31_wmask),
    .toSRAM_31_re (x0_toSRAM_31_re),
    .toSRAM_31_we (x0_toSRAM_31_we),
    .toSRAM_31_ack (x0_toSRAM_31_ack),
    .toSRAM_31_selectedOH (x0_toSRAM_31_selectedOH),
    .toSRAM_31_array (x0_toSRAM_31_array)
  );
  wire [3242:0] gbus0 = {g0_mbist_ack, g0_mbist_outdata, g0_toSRAM_0_addr, g0_toSRAM_0_addr_rd, g0_toSRAM_0_wdata, g0_toSRAM_0_wmask, g0_toSRAM_0_re, g0_toSRAM_0_we, g0_toSRAM_0_ack, g0_toSRAM_0_selectedOH, g0_toSRAM_0_array, g0_toSRAM_1_addr, g0_toSRAM_1_addr_rd, g0_toSRAM_1_wdata, g0_toSRAM_1_wmask, g0_toSRAM_1_re, g0_toSRAM_1_we, g0_toSRAM_1_ack, g0_toSRAM_1_selectedOH, g0_toSRAM_1_array, g0_toSRAM_2_addr, g0_toSRAM_2_addr_rd, g0_toSRAM_2_wdata, g0_toSRAM_2_wmask, g0_toSRAM_2_re, g0_toSRAM_2_we, g0_toSRAM_2_ack, g0_toSRAM_2_selectedOH, g0_toSRAM_2_array, g0_toSRAM_3_addr, g0_toSRAM_3_addr_rd, g0_toSRAM_3_wdata, g0_toSRAM_3_wmask, g0_toSRAM_3_re, g0_toSRAM_3_we, g0_toSRAM_3_ack, g0_toSRAM_3_selectedOH, g0_toSRAM_3_array, g0_toSRAM_4_addr, g0_toSRAM_4_addr_rd, g0_toSRAM_4_wdata, g0_toSRAM_4_wmask, g0_toSRAM_4_re, g0_toSRAM_4_we, g0_toSRAM_4_ack, g0_toSRAM_4_selectedOH, g0_toSRAM_4_array, g0_toSRAM_5_addr, g0_toSRAM_5_addr_rd, g0_toSRAM_5_wdata, g0_toSRAM_5_wmask, g0_toSRAM_5_re, g0_toSRAM_5_we, g0_toSRAM_5_ack, g0_toSRAM_5_selectedOH, g0_toSRAM_5_array, g0_toSRAM_6_addr, g0_toSRAM_6_addr_rd, g0_toSRAM_6_wdata, g0_toSRAM_6_wmask, g0_toSRAM_6_re, g0_toSRAM_6_we, g0_toSRAM_6_ack, g0_toSRAM_6_selectedOH, g0_toSRAM_6_array, g0_toSRAM_7_addr, g0_toSRAM_7_addr_rd, g0_toSRAM_7_wdata, g0_toSRAM_7_wmask, g0_toSRAM_7_re, g0_toSRAM_7_we, g0_toSRAM_7_ack, g0_toSRAM_7_selectedOH, g0_toSRAM_7_array, g0_toSRAM_8_addr, g0_toSRAM_8_addr_rd, g0_toSRAM_8_wdata, g0_toSRAM_8_wmask, g0_toSRAM_8_re, g0_toSRAM_8_we, g0_toSRAM_8_ack, g0_toSRAM_8_selectedOH, g0_toSRAM_8_array, g0_toSRAM_9_addr, g0_toSRAM_9_addr_rd, g0_toSRAM_9_wdata, g0_toSRAM_9_wmask, g0_toSRAM_9_re, g0_toSRAM_9_we, g0_toSRAM_9_ack, g0_toSRAM_9_selectedOH, g0_toSRAM_9_array, g0_toSRAM_10_addr, g0_toSRAM_10_addr_rd, g0_toSRAM_10_wdata, g0_toSRAM_10_wmask, g0_toSRAM_10_re, g0_toSRAM_10_we, g0_toSRAM_10_ack, g0_toSRAM_10_selectedOH, g0_toSRAM_10_array, g0_toSRAM_11_addr, g0_toSRAM_11_addr_rd, g0_toSRAM_11_wdata, g0_toSRAM_11_wmask, g0_toSRAM_11_re, g0_toSRAM_11_we, g0_toSRAM_11_ack, g0_toSRAM_11_selectedOH, g0_toSRAM_11_array, g0_toSRAM_12_addr, g0_toSRAM_12_addr_rd, g0_toSRAM_12_wdata, g0_toSRAM_12_wmask, g0_toSRAM_12_re, g0_toSRAM_12_we, g0_toSRAM_12_ack, g0_toSRAM_12_selectedOH, g0_toSRAM_12_array, g0_toSRAM_13_addr, g0_toSRAM_13_addr_rd, g0_toSRAM_13_wdata, g0_toSRAM_13_wmask, g0_toSRAM_13_re, g0_toSRAM_13_we, g0_toSRAM_13_ack, g0_toSRAM_13_selectedOH, g0_toSRAM_13_array, g0_toSRAM_14_addr, g0_toSRAM_14_addr_rd, g0_toSRAM_14_wdata, g0_toSRAM_14_wmask, g0_toSRAM_14_re, g0_toSRAM_14_we, g0_toSRAM_14_ack, g0_toSRAM_14_selectedOH, g0_toSRAM_14_array, g0_toSRAM_15_addr, g0_toSRAM_15_addr_rd, g0_toSRAM_15_wdata, g0_toSRAM_15_wmask, g0_toSRAM_15_re, g0_toSRAM_15_we, g0_toSRAM_15_ack, g0_toSRAM_15_selectedOH, g0_toSRAM_15_array, g0_toSRAM_16_addr, g0_toSRAM_16_addr_rd, g0_toSRAM_16_wdata, g0_toSRAM_16_wmask, g0_toSRAM_16_re, g0_toSRAM_16_we, g0_toSRAM_16_ack, g0_toSRAM_16_selectedOH, g0_toSRAM_16_array, g0_toSRAM_17_addr, g0_toSRAM_17_addr_rd, g0_toSRAM_17_wdata, g0_toSRAM_17_wmask, g0_toSRAM_17_re, g0_toSRAM_17_we, g0_toSRAM_17_ack, g0_toSRAM_17_selectedOH, g0_toSRAM_17_array, g0_toSRAM_18_addr, g0_toSRAM_18_addr_rd, g0_toSRAM_18_wdata, g0_toSRAM_18_wmask, g0_toSRAM_18_re, g0_toSRAM_18_we, g0_toSRAM_18_ack, g0_toSRAM_18_selectedOH, g0_toSRAM_18_array, g0_toSRAM_19_addr, g0_toSRAM_19_addr_rd, g0_toSRAM_19_wdata, g0_toSRAM_19_wmask, g0_toSRAM_19_re, g0_toSRAM_19_we, g0_toSRAM_19_ack, g0_toSRAM_19_selectedOH, g0_toSRAM_19_array, g0_toSRAM_20_addr, g0_toSRAM_20_addr_rd, g0_toSRAM_20_wdata, g0_toSRAM_20_wmask, g0_toSRAM_20_re, g0_toSRAM_20_we, g0_toSRAM_20_ack, g0_toSRAM_20_selectedOH, g0_toSRAM_20_array, g0_toSRAM_21_addr, g0_toSRAM_21_addr_rd, g0_toSRAM_21_wdata, g0_toSRAM_21_wmask, g0_toSRAM_21_re, g0_toSRAM_21_we, g0_toSRAM_21_ack, g0_toSRAM_21_selectedOH, g0_toSRAM_21_array, g0_toSRAM_22_addr, g0_toSRAM_22_addr_rd, g0_toSRAM_22_wdata, g0_toSRAM_22_wmask, g0_toSRAM_22_re, g0_toSRAM_22_we, g0_toSRAM_22_ack, g0_toSRAM_22_selectedOH, g0_toSRAM_22_array, g0_toSRAM_23_addr, g0_toSRAM_23_addr_rd, g0_toSRAM_23_wdata, g0_toSRAM_23_wmask, g0_toSRAM_23_re, g0_toSRAM_23_we, g0_toSRAM_23_ack, g0_toSRAM_23_selectedOH, g0_toSRAM_23_array, g0_toSRAM_24_addr, g0_toSRAM_24_addr_rd, g0_toSRAM_24_wdata, g0_toSRAM_24_wmask, g0_toSRAM_24_re, g0_toSRAM_24_we, g0_toSRAM_24_ack, g0_toSRAM_24_selectedOH, g0_toSRAM_24_array, g0_toSRAM_25_addr, g0_toSRAM_25_addr_rd, g0_toSRAM_25_wdata, g0_toSRAM_25_wmask, g0_toSRAM_25_re, g0_toSRAM_25_we, g0_toSRAM_25_ack, g0_toSRAM_25_selectedOH, g0_toSRAM_25_array, g0_toSRAM_26_addr, g0_toSRAM_26_addr_rd, g0_toSRAM_26_wdata, g0_toSRAM_26_wmask, g0_toSRAM_26_re, g0_toSRAM_26_we, g0_toSRAM_26_ack, g0_toSRAM_26_selectedOH, g0_toSRAM_26_array, g0_toSRAM_27_addr, g0_toSRAM_27_addr_rd, g0_toSRAM_27_wdata, g0_toSRAM_27_wmask, g0_toSRAM_27_re, g0_toSRAM_27_we, g0_toSRAM_27_ack, g0_toSRAM_27_selectedOH, g0_toSRAM_27_array, g0_toSRAM_28_addr, g0_toSRAM_28_addr_rd, g0_toSRAM_28_wdata, g0_toSRAM_28_wmask, g0_toSRAM_28_re, g0_toSRAM_28_we, g0_toSRAM_28_ack, g0_toSRAM_28_selectedOH, g0_toSRAM_28_array, g0_toSRAM_29_addr, g0_toSRAM_29_addr_rd, g0_toSRAM_29_wdata, g0_toSRAM_29_wmask, g0_toSRAM_29_re, g0_toSRAM_29_we, g0_toSRAM_29_ack, g0_toSRAM_29_selectedOH, g0_toSRAM_29_array, g0_toSRAM_30_addr, g0_toSRAM_30_addr_rd, g0_toSRAM_30_wdata, g0_toSRAM_30_wmask, g0_toSRAM_30_re, g0_toSRAM_30_we, g0_toSRAM_30_ack, g0_toSRAM_30_selectedOH, g0_toSRAM_30_array, g0_toSRAM_31_addr, g0_toSRAM_31_addr_rd, g0_toSRAM_31_wdata, g0_toSRAM_31_wmask, g0_toSRAM_31_re, g0_toSRAM_31_we, g0_toSRAM_31_ack, g0_toSRAM_31_selectedOH, g0_toSRAM_31_array};
  wire [3242:0] xbus0 = {x0_mbist_ack, x0_mbist_outdata, x0_toSRAM_0_addr, x0_toSRAM_0_addr_rd, x0_toSRAM_0_wdata, x0_toSRAM_0_wmask, x0_toSRAM_0_re, x0_toSRAM_0_we, x0_toSRAM_0_ack, x0_toSRAM_0_selectedOH, x0_toSRAM_0_array, x0_toSRAM_1_addr, x0_toSRAM_1_addr_rd, x0_toSRAM_1_wdata, x0_toSRAM_1_wmask, x0_toSRAM_1_re, x0_toSRAM_1_we, x0_toSRAM_1_ack, x0_toSRAM_1_selectedOH, x0_toSRAM_1_array, x0_toSRAM_2_addr, x0_toSRAM_2_addr_rd, x0_toSRAM_2_wdata, x0_toSRAM_2_wmask, x0_toSRAM_2_re, x0_toSRAM_2_we, x0_toSRAM_2_ack, x0_toSRAM_2_selectedOH, x0_toSRAM_2_array, x0_toSRAM_3_addr, x0_toSRAM_3_addr_rd, x0_toSRAM_3_wdata, x0_toSRAM_3_wmask, x0_toSRAM_3_re, x0_toSRAM_3_we, x0_toSRAM_3_ack, x0_toSRAM_3_selectedOH, x0_toSRAM_3_array, x0_toSRAM_4_addr, x0_toSRAM_4_addr_rd, x0_toSRAM_4_wdata, x0_toSRAM_4_wmask, x0_toSRAM_4_re, x0_toSRAM_4_we, x0_toSRAM_4_ack, x0_toSRAM_4_selectedOH, x0_toSRAM_4_array, x0_toSRAM_5_addr, x0_toSRAM_5_addr_rd, x0_toSRAM_5_wdata, x0_toSRAM_5_wmask, x0_toSRAM_5_re, x0_toSRAM_5_we, x0_toSRAM_5_ack, x0_toSRAM_5_selectedOH, x0_toSRAM_5_array, x0_toSRAM_6_addr, x0_toSRAM_6_addr_rd, x0_toSRAM_6_wdata, x0_toSRAM_6_wmask, x0_toSRAM_6_re, x0_toSRAM_6_we, x0_toSRAM_6_ack, x0_toSRAM_6_selectedOH, x0_toSRAM_6_array, x0_toSRAM_7_addr, x0_toSRAM_7_addr_rd, x0_toSRAM_7_wdata, x0_toSRAM_7_wmask, x0_toSRAM_7_re, x0_toSRAM_7_we, x0_toSRAM_7_ack, x0_toSRAM_7_selectedOH, x0_toSRAM_7_array, x0_toSRAM_8_addr, x0_toSRAM_8_addr_rd, x0_toSRAM_8_wdata, x0_toSRAM_8_wmask, x0_toSRAM_8_re, x0_toSRAM_8_we, x0_toSRAM_8_ack, x0_toSRAM_8_selectedOH, x0_toSRAM_8_array, x0_toSRAM_9_addr, x0_toSRAM_9_addr_rd, x0_toSRAM_9_wdata, x0_toSRAM_9_wmask, x0_toSRAM_9_re, x0_toSRAM_9_we, x0_toSRAM_9_ack, x0_toSRAM_9_selectedOH, x0_toSRAM_9_array, x0_toSRAM_10_addr, x0_toSRAM_10_addr_rd, x0_toSRAM_10_wdata, x0_toSRAM_10_wmask, x0_toSRAM_10_re, x0_toSRAM_10_we, x0_toSRAM_10_ack, x0_toSRAM_10_selectedOH, x0_toSRAM_10_array, x0_toSRAM_11_addr, x0_toSRAM_11_addr_rd, x0_toSRAM_11_wdata, x0_toSRAM_11_wmask, x0_toSRAM_11_re, x0_toSRAM_11_we, x0_toSRAM_11_ack, x0_toSRAM_11_selectedOH, x0_toSRAM_11_array, x0_toSRAM_12_addr, x0_toSRAM_12_addr_rd, x0_toSRAM_12_wdata, x0_toSRAM_12_wmask, x0_toSRAM_12_re, x0_toSRAM_12_we, x0_toSRAM_12_ack, x0_toSRAM_12_selectedOH, x0_toSRAM_12_array, x0_toSRAM_13_addr, x0_toSRAM_13_addr_rd, x0_toSRAM_13_wdata, x0_toSRAM_13_wmask, x0_toSRAM_13_re, x0_toSRAM_13_we, x0_toSRAM_13_ack, x0_toSRAM_13_selectedOH, x0_toSRAM_13_array, x0_toSRAM_14_addr, x0_toSRAM_14_addr_rd, x0_toSRAM_14_wdata, x0_toSRAM_14_wmask, x0_toSRAM_14_re, x0_toSRAM_14_we, x0_toSRAM_14_ack, x0_toSRAM_14_selectedOH, x0_toSRAM_14_array, x0_toSRAM_15_addr, x0_toSRAM_15_addr_rd, x0_toSRAM_15_wdata, x0_toSRAM_15_wmask, x0_toSRAM_15_re, x0_toSRAM_15_we, x0_toSRAM_15_ack, x0_toSRAM_15_selectedOH, x0_toSRAM_15_array, x0_toSRAM_16_addr, x0_toSRAM_16_addr_rd, x0_toSRAM_16_wdata, x0_toSRAM_16_wmask, x0_toSRAM_16_re, x0_toSRAM_16_we, x0_toSRAM_16_ack, x0_toSRAM_16_selectedOH, x0_toSRAM_16_array, x0_toSRAM_17_addr, x0_toSRAM_17_addr_rd, x0_toSRAM_17_wdata, x0_toSRAM_17_wmask, x0_toSRAM_17_re, x0_toSRAM_17_we, x0_toSRAM_17_ack, x0_toSRAM_17_selectedOH, x0_toSRAM_17_array, x0_toSRAM_18_addr, x0_toSRAM_18_addr_rd, x0_toSRAM_18_wdata, x0_toSRAM_18_wmask, x0_toSRAM_18_re, x0_toSRAM_18_we, x0_toSRAM_18_ack, x0_toSRAM_18_selectedOH, x0_toSRAM_18_array, x0_toSRAM_19_addr, x0_toSRAM_19_addr_rd, x0_toSRAM_19_wdata, x0_toSRAM_19_wmask, x0_toSRAM_19_re, x0_toSRAM_19_we, x0_toSRAM_19_ack, x0_toSRAM_19_selectedOH, x0_toSRAM_19_array, x0_toSRAM_20_addr, x0_toSRAM_20_addr_rd, x0_toSRAM_20_wdata, x0_toSRAM_20_wmask, x0_toSRAM_20_re, x0_toSRAM_20_we, x0_toSRAM_20_ack, x0_toSRAM_20_selectedOH, x0_toSRAM_20_array, x0_toSRAM_21_addr, x0_toSRAM_21_addr_rd, x0_toSRAM_21_wdata, x0_toSRAM_21_wmask, x0_toSRAM_21_re, x0_toSRAM_21_we, x0_toSRAM_21_ack, x0_toSRAM_21_selectedOH, x0_toSRAM_21_array, x0_toSRAM_22_addr, x0_toSRAM_22_addr_rd, x0_toSRAM_22_wdata, x0_toSRAM_22_wmask, x0_toSRAM_22_re, x0_toSRAM_22_we, x0_toSRAM_22_ack, x0_toSRAM_22_selectedOH, x0_toSRAM_22_array, x0_toSRAM_23_addr, x0_toSRAM_23_addr_rd, x0_toSRAM_23_wdata, x0_toSRAM_23_wmask, x0_toSRAM_23_re, x0_toSRAM_23_we, x0_toSRAM_23_ack, x0_toSRAM_23_selectedOH, x0_toSRAM_23_array, x0_toSRAM_24_addr, x0_toSRAM_24_addr_rd, x0_toSRAM_24_wdata, x0_toSRAM_24_wmask, x0_toSRAM_24_re, x0_toSRAM_24_we, x0_toSRAM_24_ack, x0_toSRAM_24_selectedOH, x0_toSRAM_24_array, x0_toSRAM_25_addr, x0_toSRAM_25_addr_rd, x0_toSRAM_25_wdata, x0_toSRAM_25_wmask, x0_toSRAM_25_re, x0_toSRAM_25_we, x0_toSRAM_25_ack, x0_toSRAM_25_selectedOH, x0_toSRAM_25_array, x0_toSRAM_26_addr, x0_toSRAM_26_addr_rd, x0_toSRAM_26_wdata, x0_toSRAM_26_wmask, x0_toSRAM_26_re, x0_toSRAM_26_we, x0_toSRAM_26_ack, x0_toSRAM_26_selectedOH, x0_toSRAM_26_array, x0_toSRAM_27_addr, x0_toSRAM_27_addr_rd, x0_toSRAM_27_wdata, x0_toSRAM_27_wmask, x0_toSRAM_27_re, x0_toSRAM_27_we, x0_toSRAM_27_ack, x0_toSRAM_27_selectedOH, x0_toSRAM_27_array, x0_toSRAM_28_addr, x0_toSRAM_28_addr_rd, x0_toSRAM_28_wdata, x0_toSRAM_28_wmask, x0_toSRAM_28_re, x0_toSRAM_28_we, x0_toSRAM_28_ack, x0_toSRAM_28_selectedOH, x0_toSRAM_28_array, x0_toSRAM_29_addr, x0_toSRAM_29_addr_rd, x0_toSRAM_29_wdata, x0_toSRAM_29_wmask, x0_toSRAM_29_re, x0_toSRAM_29_we, x0_toSRAM_29_ack, x0_toSRAM_29_selectedOH, x0_toSRAM_29_array, x0_toSRAM_30_addr, x0_toSRAM_30_addr_rd, x0_toSRAM_30_wdata, x0_toSRAM_30_wmask, x0_toSRAM_30_re, x0_toSRAM_30_we, x0_toSRAM_30_ack, x0_toSRAM_30_selectedOH, x0_toSRAM_30_array, x0_toSRAM_31_addr, x0_toSRAM_31_addr_rd, x0_toSRAM_31_wdata, x0_toSRAM_31_wmask, x0_toSRAM_31_re, x0_toSRAM_31_we, x0_toSRAM_31_ack, x0_toSRAM_31_selectedOH, x0_toSRAM_31_array};
  task automatic detail0();
    if (g0_mbist_ack !== x0_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.mbist_ack golden=%h impl=%h", cyc, g0_mbist_ack, x0_mbist_ack); end
    if (g0_mbist_outdata !== x0_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.mbist_outdata golden=%h impl=%h", cyc, g0_mbist_outdata, x0_mbist_outdata); end
    if (g0_toSRAM_0_addr !== x0_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_addr golden=%h impl=%h", cyc, g0_toSRAM_0_addr, x0_toSRAM_0_addr); end
    if (g0_toSRAM_0_addr_rd !== x0_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_0_addr_rd, x0_toSRAM_0_addr_rd); end
    if (g0_toSRAM_0_wdata !== x0_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_wdata golden=%h impl=%h", cyc, g0_toSRAM_0_wdata, x0_toSRAM_0_wdata); end
    if (g0_toSRAM_0_wmask !== x0_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_wmask golden=%h impl=%h", cyc, g0_toSRAM_0_wmask, x0_toSRAM_0_wmask); end
    if (g0_toSRAM_0_re !== x0_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_re golden=%h impl=%h", cyc, g0_toSRAM_0_re, x0_toSRAM_0_re); end
    if (g0_toSRAM_0_we !== x0_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_we golden=%h impl=%h", cyc, g0_toSRAM_0_we, x0_toSRAM_0_we); end
    if (g0_toSRAM_0_ack !== x0_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_ack golden=%h impl=%h", cyc, g0_toSRAM_0_ack, x0_toSRAM_0_ack); end
    if (g0_toSRAM_0_selectedOH !== x0_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_0_selectedOH, x0_toSRAM_0_selectedOH); end
    if (g0_toSRAM_0_array !== x0_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_0_array golden=%h impl=%h", cyc, g0_toSRAM_0_array, x0_toSRAM_0_array); end
    if (g0_toSRAM_1_addr !== x0_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_addr golden=%h impl=%h", cyc, g0_toSRAM_1_addr, x0_toSRAM_1_addr); end
    if (g0_toSRAM_1_addr_rd !== x0_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_1_addr_rd, x0_toSRAM_1_addr_rd); end
    if (g0_toSRAM_1_wdata !== x0_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_wdata golden=%h impl=%h", cyc, g0_toSRAM_1_wdata, x0_toSRAM_1_wdata); end
    if (g0_toSRAM_1_wmask !== x0_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_wmask golden=%h impl=%h", cyc, g0_toSRAM_1_wmask, x0_toSRAM_1_wmask); end
    if (g0_toSRAM_1_re !== x0_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_re golden=%h impl=%h", cyc, g0_toSRAM_1_re, x0_toSRAM_1_re); end
    if (g0_toSRAM_1_we !== x0_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_we golden=%h impl=%h", cyc, g0_toSRAM_1_we, x0_toSRAM_1_we); end
    if (g0_toSRAM_1_ack !== x0_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_ack golden=%h impl=%h", cyc, g0_toSRAM_1_ack, x0_toSRAM_1_ack); end
    if (g0_toSRAM_1_selectedOH !== x0_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_1_selectedOH, x0_toSRAM_1_selectedOH); end
    if (g0_toSRAM_1_array !== x0_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_1_array golden=%h impl=%h", cyc, g0_toSRAM_1_array, x0_toSRAM_1_array); end
    if (g0_toSRAM_2_addr !== x0_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_addr golden=%h impl=%h", cyc, g0_toSRAM_2_addr, x0_toSRAM_2_addr); end
    if (g0_toSRAM_2_addr_rd !== x0_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_2_addr_rd, x0_toSRAM_2_addr_rd); end
    if (g0_toSRAM_2_wdata !== x0_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_wdata golden=%h impl=%h", cyc, g0_toSRAM_2_wdata, x0_toSRAM_2_wdata); end
    if (g0_toSRAM_2_wmask !== x0_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_wmask golden=%h impl=%h", cyc, g0_toSRAM_2_wmask, x0_toSRAM_2_wmask); end
    if (g0_toSRAM_2_re !== x0_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_re golden=%h impl=%h", cyc, g0_toSRAM_2_re, x0_toSRAM_2_re); end
    if (g0_toSRAM_2_we !== x0_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_we golden=%h impl=%h", cyc, g0_toSRAM_2_we, x0_toSRAM_2_we); end
    if (g0_toSRAM_2_ack !== x0_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_ack golden=%h impl=%h", cyc, g0_toSRAM_2_ack, x0_toSRAM_2_ack); end
    if (g0_toSRAM_2_selectedOH !== x0_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_2_selectedOH, x0_toSRAM_2_selectedOH); end
    if (g0_toSRAM_2_array !== x0_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_2_array golden=%h impl=%h", cyc, g0_toSRAM_2_array, x0_toSRAM_2_array); end
    if (g0_toSRAM_3_addr !== x0_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_addr golden=%h impl=%h", cyc, g0_toSRAM_3_addr, x0_toSRAM_3_addr); end
    if (g0_toSRAM_3_addr_rd !== x0_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_3_addr_rd, x0_toSRAM_3_addr_rd); end
    if (g0_toSRAM_3_wdata !== x0_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_wdata golden=%h impl=%h", cyc, g0_toSRAM_3_wdata, x0_toSRAM_3_wdata); end
    if (g0_toSRAM_3_wmask !== x0_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_wmask golden=%h impl=%h", cyc, g0_toSRAM_3_wmask, x0_toSRAM_3_wmask); end
    if (g0_toSRAM_3_re !== x0_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_re golden=%h impl=%h", cyc, g0_toSRAM_3_re, x0_toSRAM_3_re); end
    if (g0_toSRAM_3_we !== x0_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_we golden=%h impl=%h", cyc, g0_toSRAM_3_we, x0_toSRAM_3_we); end
    if (g0_toSRAM_3_ack !== x0_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_ack golden=%h impl=%h", cyc, g0_toSRAM_3_ack, x0_toSRAM_3_ack); end
    if (g0_toSRAM_3_selectedOH !== x0_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_3_selectedOH, x0_toSRAM_3_selectedOH); end
    if (g0_toSRAM_3_array !== x0_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_3_array golden=%h impl=%h", cyc, g0_toSRAM_3_array, x0_toSRAM_3_array); end
    if (g0_toSRAM_4_addr !== x0_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_addr golden=%h impl=%h", cyc, g0_toSRAM_4_addr, x0_toSRAM_4_addr); end
    if (g0_toSRAM_4_addr_rd !== x0_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_4_addr_rd, x0_toSRAM_4_addr_rd); end
    if (g0_toSRAM_4_wdata !== x0_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_wdata golden=%h impl=%h", cyc, g0_toSRAM_4_wdata, x0_toSRAM_4_wdata); end
    if (g0_toSRAM_4_wmask !== x0_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_wmask golden=%h impl=%h", cyc, g0_toSRAM_4_wmask, x0_toSRAM_4_wmask); end
    if (g0_toSRAM_4_re !== x0_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_re golden=%h impl=%h", cyc, g0_toSRAM_4_re, x0_toSRAM_4_re); end
    if (g0_toSRAM_4_we !== x0_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_we golden=%h impl=%h", cyc, g0_toSRAM_4_we, x0_toSRAM_4_we); end
    if (g0_toSRAM_4_ack !== x0_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_ack golden=%h impl=%h", cyc, g0_toSRAM_4_ack, x0_toSRAM_4_ack); end
    if (g0_toSRAM_4_selectedOH !== x0_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_4_selectedOH, x0_toSRAM_4_selectedOH); end
    if (g0_toSRAM_4_array !== x0_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_4_array golden=%h impl=%h", cyc, g0_toSRAM_4_array, x0_toSRAM_4_array); end
    if (g0_toSRAM_5_addr !== x0_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_addr golden=%h impl=%h", cyc, g0_toSRAM_5_addr, x0_toSRAM_5_addr); end
    if (g0_toSRAM_5_addr_rd !== x0_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_5_addr_rd, x0_toSRAM_5_addr_rd); end
    if (g0_toSRAM_5_wdata !== x0_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_wdata golden=%h impl=%h", cyc, g0_toSRAM_5_wdata, x0_toSRAM_5_wdata); end
    if (g0_toSRAM_5_wmask !== x0_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_wmask golden=%h impl=%h", cyc, g0_toSRAM_5_wmask, x0_toSRAM_5_wmask); end
    if (g0_toSRAM_5_re !== x0_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_re golden=%h impl=%h", cyc, g0_toSRAM_5_re, x0_toSRAM_5_re); end
    if (g0_toSRAM_5_we !== x0_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_we golden=%h impl=%h", cyc, g0_toSRAM_5_we, x0_toSRAM_5_we); end
    if (g0_toSRAM_5_ack !== x0_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_ack golden=%h impl=%h", cyc, g0_toSRAM_5_ack, x0_toSRAM_5_ack); end
    if (g0_toSRAM_5_selectedOH !== x0_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_5_selectedOH, x0_toSRAM_5_selectedOH); end
    if (g0_toSRAM_5_array !== x0_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_5_array golden=%h impl=%h", cyc, g0_toSRAM_5_array, x0_toSRAM_5_array); end
    if (g0_toSRAM_6_addr !== x0_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_addr golden=%h impl=%h", cyc, g0_toSRAM_6_addr, x0_toSRAM_6_addr); end
    if (g0_toSRAM_6_addr_rd !== x0_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_6_addr_rd, x0_toSRAM_6_addr_rd); end
    if (g0_toSRAM_6_wdata !== x0_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_wdata golden=%h impl=%h", cyc, g0_toSRAM_6_wdata, x0_toSRAM_6_wdata); end
    if (g0_toSRAM_6_wmask !== x0_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_wmask golden=%h impl=%h", cyc, g0_toSRAM_6_wmask, x0_toSRAM_6_wmask); end
    if (g0_toSRAM_6_re !== x0_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_re golden=%h impl=%h", cyc, g0_toSRAM_6_re, x0_toSRAM_6_re); end
    if (g0_toSRAM_6_we !== x0_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_we golden=%h impl=%h", cyc, g0_toSRAM_6_we, x0_toSRAM_6_we); end
    if (g0_toSRAM_6_ack !== x0_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_ack golden=%h impl=%h", cyc, g0_toSRAM_6_ack, x0_toSRAM_6_ack); end
    if (g0_toSRAM_6_selectedOH !== x0_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_6_selectedOH, x0_toSRAM_6_selectedOH); end
    if (g0_toSRAM_6_array !== x0_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_6_array golden=%h impl=%h", cyc, g0_toSRAM_6_array, x0_toSRAM_6_array); end
    if (g0_toSRAM_7_addr !== x0_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_addr golden=%h impl=%h", cyc, g0_toSRAM_7_addr, x0_toSRAM_7_addr); end
    if (g0_toSRAM_7_addr_rd !== x0_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_7_addr_rd, x0_toSRAM_7_addr_rd); end
    if (g0_toSRAM_7_wdata !== x0_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_wdata golden=%h impl=%h", cyc, g0_toSRAM_7_wdata, x0_toSRAM_7_wdata); end
    if (g0_toSRAM_7_wmask !== x0_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_wmask golden=%h impl=%h", cyc, g0_toSRAM_7_wmask, x0_toSRAM_7_wmask); end
    if (g0_toSRAM_7_re !== x0_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_re golden=%h impl=%h", cyc, g0_toSRAM_7_re, x0_toSRAM_7_re); end
    if (g0_toSRAM_7_we !== x0_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_we golden=%h impl=%h", cyc, g0_toSRAM_7_we, x0_toSRAM_7_we); end
    if (g0_toSRAM_7_ack !== x0_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_ack golden=%h impl=%h", cyc, g0_toSRAM_7_ack, x0_toSRAM_7_ack); end
    if (g0_toSRAM_7_selectedOH !== x0_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_7_selectedOH, x0_toSRAM_7_selectedOH); end
    if (g0_toSRAM_7_array !== x0_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_7_array golden=%h impl=%h", cyc, g0_toSRAM_7_array, x0_toSRAM_7_array); end
    if (g0_toSRAM_8_addr !== x0_toSRAM_8_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_addr golden=%h impl=%h", cyc, g0_toSRAM_8_addr, x0_toSRAM_8_addr); end
    if (g0_toSRAM_8_addr_rd !== x0_toSRAM_8_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_8_addr_rd, x0_toSRAM_8_addr_rd); end
    if (g0_toSRAM_8_wdata !== x0_toSRAM_8_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_wdata golden=%h impl=%h", cyc, g0_toSRAM_8_wdata, x0_toSRAM_8_wdata); end
    if (g0_toSRAM_8_wmask !== x0_toSRAM_8_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_wmask golden=%h impl=%h", cyc, g0_toSRAM_8_wmask, x0_toSRAM_8_wmask); end
    if (g0_toSRAM_8_re !== x0_toSRAM_8_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_re golden=%h impl=%h", cyc, g0_toSRAM_8_re, x0_toSRAM_8_re); end
    if (g0_toSRAM_8_we !== x0_toSRAM_8_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_we golden=%h impl=%h", cyc, g0_toSRAM_8_we, x0_toSRAM_8_we); end
    if (g0_toSRAM_8_ack !== x0_toSRAM_8_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_ack golden=%h impl=%h", cyc, g0_toSRAM_8_ack, x0_toSRAM_8_ack); end
    if (g0_toSRAM_8_selectedOH !== x0_toSRAM_8_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_8_selectedOH, x0_toSRAM_8_selectedOH); end
    if (g0_toSRAM_8_array !== x0_toSRAM_8_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_8_array golden=%h impl=%h", cyc, g0_toSRAM_8_array, x0_toSRAM_8_array); end
    if (g0_toSRAM_9_addr !== x0_toSRAM_9_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_addr golden=%h impl=%h", cyc, g0_toSRAM_9_addr, x0_toSRAM_9_addr); end
    if (g0_toSRAM_9_addr_rd !== x0_toSRAM_9_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_9_addr_rd, x0_toSRAM_9_addr_rd); end
    if (g0_toSRAM_9_wdata !== x0_toSRAM_9_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_wdata golden=%h impl=%h", cyc, g0_toSRAM_9_wdata, x0_toSRAM_9_wdata); end
    if (g0_toSRAM_9_wmask !== x0_toSRAM_9_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_wmask golden=%h impl=%h", cyc, g0_toSRAM_9_wmask, x0_toSRAM_9_wmask); end
    if (g0_toSRAM_9_re !== x0_toSRAM_9_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_re golden=%h impl=%h", cyc, g0_toSRAM_9_re, x0_toSRAM_9_re); end
    if (g0_toSRAM_9_we !== x0_toSRAM_9_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_we golden=%h impl=%h", cyc, g0_toSRAM_9_we, x0_toSRAM_9_we); end
    if (g0_toSRAM_9_ack !== x0_toSRAM_9_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_ack golden=%h impl=%h", cyc, g0_toSRAM_9_ack, x0_toSRAM_9_ack); end
    if (g0_toSRAM_9_selectedOH !== x0_toSRAM_9_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_9_selectedOH, x0_toSRAM_9_selectedOH); end
    if (g0_toSRAM_9_array !== x0_toSRAM_9_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_9_array golden=%h impl=%h", cyc, g0_toSRAM_9_array, x0_toSRAM_9_array); end
    if (g0_toSRAM_10_addr !== x0_toSRAM_10_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_addr golden=%h impl=%h", cyc, g0_toSRAM_10_addr, x0_toSRAM_10_addr); end
    if (g0_toSRAM_10_addr_rd !== x0_toSRAM_10_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_10_addr_rd, x0_toSRAM_10_addr_rd); end
    if (g0_toSRAM_10_wdata !== x0_toSRAM_10_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_wdata golden=%h impl=%h", cyc, g0_toSRAM_10_wdata, x0_toSRAM_10_wdata); end
    if (g0_toSRAM_10_wmask !== x0_toSRAM_10_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_wmask golden=%h impl=%h", cyc, g0_toSRAM_10_wmask, x0_toSRAM_10_wmask); end
    if (g0_toSRAM_10_re !== x0_toSRAM_10_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_re golden=%h impl=%h", cyc, g0_toSRAM_10_re, x0_toSRAM_10_re); end
    if (g0_toSRAM_10_we !== x0_toSRAM_10_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_we golden=%h impl=%h", cyc, g0_toSRAM_10_we, x0_toSRAM_10_we); end
    if (g0_toSRAM_10_ack !== x0_toSRAM_10_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_ack golden=%h impl=%h", cyc, g0_toSRAM_10_ack, x0_toSRAM_10_ack); end
    if (g0_toSRAM_10_selectedOH !== x0_toSRAM_10_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_10_selectedOH, x0_toSRAM_10_selectedOH); end
    if (g0_toSRAM_10_array !== x0_toSRAM_10_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_10_array golden=%h impl=%h", cyc, g0_toSRAM_10_array, x0_toSRAM_10_array); end
    if (g0_toSRAM_11_addr !== x0_toSRAM_11_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_addr golden=%h impl=%h", cyc, g0_toSRAM_11_addr, x0_toSRAM_11_addr); end
    if (g0_toSRAM_11_addr_rd !== x0_toSRAM_11_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_11_addr_rd, x0_toSRAM_11_addr_rd); end
    if (g0_toSRAM_11_wdata !== x0_toSRAM_11_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_wdata golden=%h impl=%h", cyc, g0_toSRAM_11_wdata, x0_toSRAM_11_wdata); end
    if (g0_toSRAM_11_wmask !== x0_toSRAM_11_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_wmask golden=%h impl=%h", cyc, g0_toSRAM_11_wmask, x0_toSRAM_11_wmask); end
    if (g0_toSRAM_11_re !== x0_toSRAM_11_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_re golden=%h impl=%h", cyc, g0_toSRAM_11_re, x0_toSRAM_11_re); end
    if (g0_toSRAM_11_we !== x0_toSRAM_11_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_we golden=%h impl=%h", cyc, g0_toSRAM_11_we, x0_toSRAM_11_we); end
    if (g0_toSRAM_11_ack !== x0_toSRAM_11_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_ack golden=%h impl=%h", cyc, g0_toSRAM_11_ack, x0_toSRAM_11_ack); end
    if (g0_toSRAM_11_selectedOH !== x0_toSRAM_11_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_11_selectedOH, x0_toSRAM_11_selectedOH); end
    if (g0_toSRAM_11_array !== x0_toSRAM_11_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_11_array golden=%h impl=%h", cyc, g0_toSRAM_11_array, x0_toSRAM_11_array); end
    if (g0_toSRAM_12_addr !== x0_toSRAM_12_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_addr golden=%h impl=%h", cyc, g0_toSRAM_12_addr, x0_toSRAM_12_addr); end
    if (g0_toSRAM_12_addr_rd !== x0_toSRAM_12_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_12_addr_rd, x0_toSRAM_12_addr_rd); end
    if (g0_toSRAM_12_wdata !== x0_toSRAM_12_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_wdata golden=%h impl=%h", cyc, g0_toSRAM_12_wdata, x0_toSRAM_12_wdata); end
    if (g0_toSRAM_12_wmask !== x0_toSRAM_12_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_wmask golden=%h impl=%h", cyc, g0_toSRAM_12_wmask, x0_toSRAM_12_wmask); end
    if (g0_toSRAM_12_re !== x0_toSRAM_12_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_re golden=%h impl=%h", cyc, g0_toSRAM_12_re, x0_toSRAM_12_re); end
    if (g0_toSRAM_12_we !== x0_toSRAM_12_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_we golden=%h impl=%h", cyc, g0_toSRAM_12_we, x0_toSRAM_12_we); end
    if (g0_toSRAM_12_ack !== x0_toSRAM_12_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_ack golden=%h impl=%h", cyc, g0_toSRAM_12_ack, x0_toSRAM_12_ack); end
    if (g0_toSRAM_12_selectedOH !== x0_toSRAM_12_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_12_selectedOH, x0_toSRAM_12_selectedOH); end
    if (g0_toSRAM_12_array !== x0_toSRAM_12_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_12_array golden=%h impl=%h", cyc, g0_toSRAM_12_array, x0_toSRAM_12_array); end
    if (g0_toSRAM_13_addr !== x0_toSRAM_13_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_addr golden=%h impl=%h", cyc, g0_toSRAM_13_addr, x0_toSRAM_13_addr); end
    if (g0_toSRAM_13_addr_rd !== x0_toSRAM_13_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_13_addr_rd, x0_toSRAM_13_addr_rd); end
    if (g0_toSRAM_13_wdata !== x0_toSRAM_13_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_wdata golden=%h impl=%h", cyc, g0_toSRAM_13_wdata, x0_toSRAM_13_wdata); end
    if (g0_toSRAM_13_wmask !== x0_toSRAM_13_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_wmask golden=%h impl=%h", cyc, g0_toSRAM_13_wmask, x0_toSRAM_13_wmask); end
    if (g0_toSRAM_13_re !== x0_toSRAM_13_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_re golden=%h impl=%h", cyc, g0_toSRAM_13_re, x0_toSRAM_13_re); end
    if (g0_toSRAM_13_we !== x0_toSRAM_13_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_we golden=%h impl=%h", cyc, g0_toSRAM_13_we, x0_toSRAM_13_we); end
    if (g0_toSRAM_13_ack !== x0_toSRAM_13_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_ack golden=%h impl=%h", cyc, g0_toSRAM_13_ack, x0_toSRAM_13_ack); end
    if (g0_toSRAM_13_selectedOH !== x0_toSRAM_13_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_13_selectedOH, x0_toSRAM_13_selectedOH); end
    if (g0_toSRAM_13_array !== x0_toSRAM_13_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_13_array golden=%h impl=%h", cyc, g0_toSRAM_13_array, x0_toSRAM_13_array); end
    if (g0_toSRAM_14_addr !== x0_toSRAM_14_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_addr golden=%h impl=%h", cyc, g0_toSRAM_14_addr, x0_toSRAM_14_addr); end
    if (g0_toSRAM_14_addr_rd !== x0_toSRAM_14_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_14_addr_rd, x0_toSRAM_14_addr_rd); end
    if (g0_toSRAM_14_wdata !== x0_toSRAM_14_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_wdata golden=%h impl=%h", cyc, g0_toSRAM_14_wdata, x0_toSRAM_14_wdata); end
    if (g0_toSRAM_14_wmask !== x0_toSRAM_14_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_wmask golden=%h impl=%h", cyc, g0_toSRAM_14_wmask, x0_toSRAM_14_wmask); end
    if (g0_toSRAM_14_re !== x0_toSRAM_14_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_re golden=%h impl=%h", cyc, g0_toSRAM_14_re, x0_toSRAM_14_re); end
    if (g0_toSRAM_14_we !== x0_toSRAM_14_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_we golden=%h impl=%h", cyc, g0_toSRAM_14_we, x0_toSRAM_14_we); end
    if (g0_toSRAM_14_ack !== x0_toSRAM_14_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_ack golden=%h impl=%h", cyc, g0_toSRAM_14_ack, x0_toSRAM_14_ack); end
    if (g0_toSRAM_14_selectedOH !== x0_toSRAM_14_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_14_selectedOH, x0_toSRAM_14_selectedOH); end
    if (g0_toSRAM_14_array !== x0_toSRAM_14_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_14_array golden=%h impl=%h", cyc, g0_toSRAM_14_array, x0_toSRAM_14_array); end
    if (g0_toSRAM_15_addr !== x0_toSRAM_15_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_addr golden=%h impl=%h", cyc, g0_toSRAM_15_addr, x0_toSRAM_15_addr); end
    if (g0_toSRAM_15_addr_rd !== x0_toSRAM_15_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_15_addr_rd, x0_toSRAM_15_addr_rd); end
    if (g0_toSRAM_15_wdata !== x0_toSRAM_15_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_wdata golden=%h impl=%h", cyc, g0_toSRAM_15_wdata, x0_toSRAM_15_wdata); end
    if (g0_toSRAM_15_wmask !== x0_toSRAM_15_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_wmask golden=%h impl=%h", cyc, g0_toSRAM_15_wmask, x0_toSRAM_15_wmask); end
    if (g0_toSRAM_15_re !== x0_toSRAM_15_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_re golden=%h impl=%h", cyc, g0_toSRAM_15_re, x0_toSRAM_15_re); end
    if (g0_toSRAM_15_we !== x0_toSRAM_15_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_we golden=%h impl=%h", cyc, g0_toSRAM_15_we, x0_toSRAM_15_we); end
    if (g0_toSRAM_15_ack !== x0_toSRAM_15_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_ack golden=%h impl=%h", cyc, g0_toSRAM_15_ack, x0_toSRAM_15_ack); end
    if (g0_toSRAM_15_selectedOH !== x0_toSRAM_15_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_15_selectedOH, x0_toSRAM_15_selectedOH); end
    if (g0_toSRAM_15_array !== x0_toSRAM_15_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_15_array golden=%h impl=%h", cyc, g0_toSRAM_15_array, x0_toSRAM_15_array); end
    if (g0_toSRAM_16_addr !== x0_toSRAM_16_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_addr golden=%h impl=%h", cyc, g0_toSRAM_16_addr, x0_toSRAM_16_addr); end
    if (g0_toSRAM_16_addr_rd !== x0_toSRAM_16_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_16_addr_rd, x0_toSRAM_16_addr_rd); end
    if (g0_toSRAM_16_wdata !== x0_toSRAM_16_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_wdata golden=%h impl=%h", cyc, g0_toSRAM_16_wdata, x0_toSRAM_16_wdata); end
    if (g0_toSRAM_16_wmask !== x0_toSRAM_16_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_wmask golden=%h impl=%h", cyc, g0_toSRAM_16_wmask, x0_toSRAM_16_wmask); end
    if (g0_toSRAM_16_re !== x0_toSRAM_16_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_re golden=%h impl=%h", cyc, g0_toSRAM_16_re, x0_toSRAM_16_re); end
    if (g0_toSRAM_16_we !== x0_toSRAM_16_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_we golden=%h impl=%h", cyc, g0_toSRAM_16_we, x0_toSRAM_16_we); end
    if (g0_toSRAM_16_ack !== x0_toSRAM_16_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_ack golden=%h impl=%h", cyc, g0_toSRAM_16_ack, x0_toSRAM_16_ack); end
    if (g0_toSRAM_16_selectedOH !== x0_toSRAM_16_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_16_selectedOH, x0_toSRAM_16_selectedOH); end
    if (g0_toSRAM_16_array !== x0_toSRAM_16_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_16_array golden=%h impl=%h", cyc, g0_toSRAM_16_array, x0_toSRAM_16_array); end
    if (g0_toSRAM_17_addr !== x0_toSRAM_17_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_addr golden=%h impl=%h", cyc, g0_toSRAM_17_addr, x0_toSRAM_17_addr); end
    if (g0_toSRAM_17_addr_rd !== x0_toSRAM_17_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_17_addr_rd, x0_toSRAM_17_addr_rd); end
    if (g0_toSRAM_17_wdata !== x0_toSRAM_17_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_wdata golden=%h impl=%h", cyc, g0_toSRAM_17_wdata, x0_toSRAM_17_wdata); end
    if (g0_toSRAM_17_wmask !== x0_toSRAM_17_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_wmask golden=%h impl=%h", cyc, g0_toSRAM_17_wmask, x0_toSRAM_17_wmask); end
    if (g0_toSRAM_17_re !== x0_toSRAM_17_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_re golden=%h impl=%h", cyc, g0_toSRAM_17_re, x0_toSRAM_17_re); end
    if (g0_toSRAM_17_we !== x0_toSRAM_17_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_we golden=%h impl=%h", cyc, g0_toSRAM_17_we, x0_toSRAM_17_we); end
    if (g0_toSRAM_17_ack !== x0_toSRAM_17_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_ack golden=%h impl=%h", cyc, g0_toSRAM_17_ack, x0_toSRAM_17_ack); end
    if (g0_toSRAM_17_selectedOH !== x0_toSRAM_17_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_17_selectedOH, x0_toSRAM_17_selectedOH); end
    if (g0_toSRAM_17_array !== x0_toSRAM_17_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_17_array golden=%h impl=%h", cyc, g0_toSRAM_17_array, x0_toSRAM_17_array); end
    if (g0_toSRAM_18_addr !== x0_toSRAM_18_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_addr golden=%h impl=%h", cyc, g0_toSRAM_18_addr, x0_toSRAM_18_addr); end
    if (g0_toSRAM_18_addr_rd !== x0_toSRAM_18_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_18_addr_rd, x0_toSRAM_18_addr_rd); end
    if (g0_toSRAM_18_wdata !== x0_toSRAM_18_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_wdata golden=%h impl=%h", cyc, g0_toSRAM_18_wdata, x0_toSRAM_18_wdata); end
    if (g0_toSRAM_18_wmask !== x0_toSRAM_18_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_wmask golden=%h impl=%h", cyc, g0_toSRAM_18_wmask, x0_toSRAM_18_wmask); end
    if (g0_toSRAM_18_re !== x0_toSRAM_18_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_re golden=%h impl=%h", cyc, g0_toSRAM_18_re, x0_toSRAM_18_re); end
    if (g0_toSRAM_18_we !== x0_toSRAM_18_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_we golden=%h impl=%h", cyc, g0_toSRAM_18_we, x0_toSRAM_18_we); end
    if (g0_toSRAM_18_ack !== x0_toSRAM_18_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_ack golden=%h impl=%h", cyc, g0_toSRAM_18_ack, x0_toSRAM_18_ack); end
    if (g0_toSRAM_18_selectedOH !== x0_toSRAM_18_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_18_selectedOH, x0_toSRAM_18_selectedOH); end
    if (g0_toSRAM_18_array !== x0_toSRAM_18_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_18_array golden=%h impl=%h", cyc, g0_toSRAM_18_array, x0_toSRAM_18_array); end
    if (g0_toSRAM_19_addr !== x0_toSRAM_19_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_addr golden=%h impl=%h", cyc, g0_toSRAM_19_addr, x0_toSRAM_19_addr); end
    if (g0_toSRAM_19_addr_rd !== x0_toSRAM_19_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_19_addr_rd, x0_toSRAM_19_addr_rd); end
    if (g0_toSRAM_19_wdata !== x0_toSRAM_19_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_wdata golden=%h impl=%h", cyc, g0_toSRAM_19_wdata, x0_toSRAM_19_wdata); end
    if (g0_toSRAM_19_wmask !== x0_toSRAM_19_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_wmask golden=%h impl=%h", cyc, g0_toSRAM_19_wmask, x0_toSRAM_19_wmask); end
    if (g0_toSRAM_19_re !== x0_toSRAM_19_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_re golden=%h impl=%h", cyc, g0_toSRAM_19_re, x0_toSRAM_19_re); end
    if (g0_toSRAM_19_we !== x0_toSRAM_19_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_we golden=%h impl=%h", cyc, g0_toSRAM_19_we, x0_toSRAM_19_we); end
    if (g0_toSRAM_19_ack !== x0_toSRAM_19_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_ack golden=%h impl=%h", cyc, g0_toSRAM_19_ack, x0_toSRAM_19_ack); end
    if (g0_toSRAM_19_selectedOH !== x0_toSRAM_19_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_19_selectedOH, x0_toSRAM_19_selectedOH); end
    if (g0_toSRAM_19_array !== x0_toSRAM_19_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_19_array golden=%h impl=%h", cyc, g0_toSRAM_19_array, x0_toSRAM_19_array); end
    if (g0_toSRAM_20_addr !== x0_toSRAM_20_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_addr golden=%h impl=%h", cyc, g0_toSRAM_20_addr, x0_toSRAM_20_addr); end
    if (g0_toSRAM_20_addr_rd !== x0_toSRAM_20_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_20_addr_rd, x0_toSRAM_20_addr_rd); end
    if (g0_toSRAM_20_wdata !== x0_toSRAM_20_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_wdata golden=%h impl=%h", cyc, g0_toSRAM_20_wdata, x0_toSRAM_20_wdata); end
    if (g0_toSRAM_20_wmask !== x0_toSRAM_20_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_wmask golden=%h impl=%h", cyc, g0_toSRAM_20_wmask, x0_toSRAM_20_wmask); end
    if (g0_toSRAM_20_re !== x0_toSRAM_20_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_re golden=%h impl=%h", cyc, g0_toSRAM_20_re, x0_toSRAM_20_re); end
    if (g0_toSRAM_20_we !== x0_toSRAM_20_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_we golden=%h impl=%h", cyc, g0_toSRAM_20_we, x0_toSRAM_20_we); end
    if (g0_toSRAM_20_ack !== x0_toSRAM_20_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_ack golden=%h impl=%h", cyc, g0_toSRAM_20_ack, x0_toSRAM_20_ack); end
    if (g0_toSRAM_20_selectedOH !== x0_toSRAM_20_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_20_selectedOH, x0_toSRAM_20_selectedOH); end
    if (g0_toSRAM_20_array !== x0_toSRAM_20_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_20_array golden=%h impl=%h", cyc, g0_toSRAM_20_array, x0_toSRAM_20_array); end
    if (g0_toSRAM_21_addr !== x0_toSRAM_21_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_addr golden=%h impl=%h", cyc, g0_toSRAM_21_addr, x0_toSRAM_21_addr); end
    if (g0_toSRAM_21_addr_rd !== x0_toSRAM_21_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_21_addr_rd, x0_toSRAM_21_addr_rd); end
    if (g0_toSRAM_21_wdata !== x0_toSRAM_21_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_wdata golden=%h impl=%h", cyc, g0_toSRAM_21_wdata, x0_toSRAM_21_wdata); end
    if (g0_toSRAM_21_wmask !== x0_toSRAM_21_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_wmask golden=%h impl=%h", cyc, g0_toSRAM_21_wmask, x0_toSRAM_21_wmask); end
    if (g0_toSRAM_21_re !== x0_toSRAM_21_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_re golden=%h impl=%h", cyc, g0_toSRAM_21_re, x0_toSRAM_21_re); end
    if (g0_toSRAM_21_we !== x0_toSRAM_21_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_we golden=%h impl=%h", cyc, g0_toSRAM_21_we, x0_toSRAM_21_we); end
    if (g0_toSRAM_21_ack !== x0_toSRAM_21_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_ack golden=%h impl=%h", cyc, g0_toSRAM_21_ack, x0_toSRAM_21_ack); end
    if (g0_toSRAM_21_selectedOH !== x0_toSRAM_21_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_21_selectedOH, x0_toSRAM_21_selectedOH); end
    if (g0_toSRAM_21_array !== x0_toSRAM_21_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_21_array golden=%h impl=%h", cyc, g0_toSRAM_21_array, x0_toSRAM_21_array); end
    if (g0_toSRAM_22_addr !== x0_toSRAM_22_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_addr golden=%h impl=%h", cyc, g0_toSRAM_22_addr, x0_toSRAM_22_addr); end
    if (g0_toSRAM_22_addr_rd !== x0_toSRAM_22_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_22_addr_rd, x0_toSRAM_22_addr_rd); end
    if (g0_toSRAM_22_wdata !== x0_toSRAM_22_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_wdata golden=%h impl=%h", cyc, g0_toSRAM_22_wdata, x0_toSRAM_22_wdata); end
    if (g0_toSRAM_22_wmask !== x0_toSRAM_22_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_wmask golden=%h impl=%h", cyc, g0_toSRAM_22_wmask, x0_toSRAM_22_wmask); end
    if (g0_toSRAM_22_re !== x0_toSRAM_22_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_re golden=%h impl=%h", cyc, g0_toSRAM_22_re, x0_toSRAM_22_re); end
    if (g0_toSRAM_22_we !== x0_toSRAM_22_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_we golden=%h impl=%h", cyc, g0_toSRAM_22_we, x0_toSRAM_22_we); end
    if (g0_toSRAM_22_ack !== x0_toSRAM_22_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_ack golden=%h impl=%h", cyc, g0_toSRAM_22_ack, x0_toSRAM_22_ack); end
    if (g0_toSRAM_22_selectedOH !== x0_toSRAM_22_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_22_selectedOH, x0_toSRAM_22_selectedOH); end
    if (g0_toSRAM_22_array !== x0_toSRAM_22_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_22_array golden=%h impl=%h", cyc, g0_toSRAM_22_array, x0_toSRAM_22_array); end
    if (g0_toSRAM_23_addr !== x0_toSRAM_23_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_addr golden=%h impl=%h", cyc, g0_toSRAM_23_addr, x0_toSRAM_23_addr); end
    if (g0_toSRAM_23_addr_rd !== x0_toSRAM_23_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_23_addr_rd, x0_toSRAM_23_addr_rd); end
    if (g0_toSRAM_23_wdata !== x0_toSRAM_23_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_wdata golden=%h impl=%h", cyc, g0_toSRAM_23_wdata, x0_toSRAM_23_wdata); end
    if (g0_toSRAM_23_wmask !== x0_toSRAM_23_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_wmask golden=%h impl=%h", cyc, g0_toSRAM_23_wmask, x0_toSRAM_23_wmask); end
    if (g0_toSRAM_23_re !== x0_toSRAM_23_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_re golden=%h impl=%h", cyc, g0_toSRAM_23_re, x0_toSRAM_23_re); end
    if (g0_toSRAM_23_we !== x0_toSRAM_23_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_we golden=%h impl=%h", cyc, g0_toSRAM_23_we, x0_toSRAM_23_we); end
    if (g0_toSRAM_23_ack !== x0_toSRAM_23_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_ack golden=%h impl=%h", cyc, g0_toSRAM_23_ack, x0_toSRAM_23_ack); end
    if (g0_toSRAM_23_selectedOH !== x0_toSRAM_23_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_23_selectedOH, x0_toSRAM_23_selectedOH); end
    if (g0_toSRAM_23_array !== x0_toSRAM_23_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_23_array golden=%h impl=%h", cyc, g0_toSRAM_23_array, x0_toSRAM_23_array); end
    if (g0_toSRAM_24_addr !== x0_toSRAM_24_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_addr golden=%h impl=%h", cyc, g0_toSRAM_24_addr, x0_toSRAM_24_addr); end
    if (g0_toSRAM_24_addr_rd !== x0_toSRAM_24_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_24_addr_rd, x0_toSRAM_24_addr_rd); end
    if (g0_toSRAM_24_wdata !== x0_toSRAM_24_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_wdata golden=%h impl=%h", cyc, g0_toSRAM_24_wdata, x0_toSRAM_24_wdata); end
    if (g0_toSRAM_24_wmask !== x0_toSRAM_24_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_wmask golden=%h impl=%h", cyc, g0_toSRAM_24_wmask, x0_toSRAM_24_wmask); end
    if (g0_toSRAM_24_re !== x0_toSRAM_24_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_re golden=%h impl=%h", cyc, g0_toSRAM_24_re, x0_toSRAM_24_re); end
    if (g0_toSRAM_24_we !== x0_toSRAM_24_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_we golden=%h impl=%h", cyc, g0_toSRAM_24_we, x0_toSRAM_24_we); end
    if (g0_toSRAM_24_ack !== x0_toSRAM_24_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_ack golden=%h impl=%h", cyc, g0_toSRAM_24_ack, x0_toSRAM_24_ack); end
    if (g0_toSRAM_24_selectedOH !== x0_toSRAM_24_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_24_selectedOH, x0_toSRAM_24_selectedOH); end
    if (g0_toSRAM_24_array !== x0_toSRAM_24_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_24_array golden=%h impl=%h", cyc, g0_toSRAM_24_array, x0_toSRAM_24_array); end
    if (g0_toSRAM_25_addr !== x0_toSRAM_25_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_addr golden=%h impl=%h", cyc, g0_toSRAM_25_addr, x0_toSRAM_25_addr); end
    if (g0_toSRAM_25_addr_rd !== x0_toSRAM_25_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_25_addr_rd, x0_toSRAM_25_addr_rd); end
    if (g0_toSRAM_25_wdata !== x0_toSRAM_25_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_wdata golden=%h impl=%h", cyc, g0_toSRAM_25_wdata, x0_toSRAM_25_wdata); end
    if (g0_toSRAM_25_wmask !== x0_toSRAM_25_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_wmask golden=%h impl=%h", cyc, g0_toSRAM_25_wmask, x0_toSRAM_25_wmask); end
    if (g0_toSRAM_25_re !== x0_toSRAM_25_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_re golden=%h impl=%h", cyc, g0_toSRAM_25_re, x0_toSRAM_25_re); end
    if (g0_toSRAM_25_we !== x0_toSRAM_25_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_we golden=%h impl=%h", cyc, g0_toSRAM_25_we, x0_toSRAM_25_we); end
    if (g0_toSRAM_25_ack !== x0_toSRAM_25_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_ack golden=%h impl=%h", cyc, g0_toSRAM_25_ack, x0_toSRAM_25_ack); end
    if (g0_toSRAM_25_selectedOH !== x0_toSRAM_25_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_25_selectedOH, x0_toSRAM_25_selectedOH); end
    if (g0_toSRAM_25_array !== x0_toSRAM_25_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_25_array golden=%h impl=%h", cyc, g0_toSRAM_25_array, x0_toSRAM_25_array); end
    if (g0_toSRAM_26_addr !== x0_toSRAM_26_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_addr golden=%h impl=%h", cyc, g0_toSRAM_26_addr, x0_toSRAM_26_addr); end
    if (g0_toSRAM_26_addr_rd !== x0_toSRAM_26_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_26_addr_rd, x0_toSRAM_26_addr_rd); end
    if (g0_toSRAM_26_wdata !== x0_toSRAM_26_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_wdata golden=%h impl=%h", cyc, g0_toSRAM_26_wdata, x0_toSRAM_26_wdata); end
    if (g0_toSRAM_26_wmask !== x0_toSRAM_26_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_wmask golden=%h impl=%h", cyc, g0_toSRAM_26_wmask, x0_toSRAM_26_wmask); end
    if (g0_toSRAM_26_re !== x0_toSRAM_26_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_re golden=%h impl=%h", cyc, g0_toSRAM_26_re, x0_toSRAM_26_re); end
    if (g0_toSRAM_26_we !== x0_toSRAM_26_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_we golden=%h impl=%h", cyc, g0_toSRAM_26_we, x0_toSRAM_26_we); end
    if (g0_toSRAM_26_ack !== x0_toSRAM_26_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_ack golden=%h impl=%h", cyc, g0_toSRAM_26_ack, x0_toSRAM_26_ack); end
    if (g0_toSRAM_26_selectedOH !== x0_toSRAM_26_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_26_selectedOH, x0_toSRAM_26_selectedOH); end
    if (g0_toSRAM_26_array !== x0_toSRAM_26_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_26_array golden=%h impl=%h", cyc, g0_toSRAM_26_array, x0_toSRAM_26_array); end
    if (g0_toSRAM_27_addr !== x0_toSRAM_27_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_addr golden=%h impl=%h", cyc, g0_toSRAM_27_addr, x0_toSRAM_27_addr); end
    if (g0_toSRAM_27_addr_rd !== x0_toSRAM_27_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_27_addr_rd, x0_toSRAM_27_addr_rd); end
    if (g0_toSRAM_27_wdata !== x0_toSRAM_27_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_wdata golden=%h impl=%h", cyc, g0_toSRAM_27_wdata, x0_toSRAM_27_wdata); end
    if (g0_toSRAM_27_wmask !== x0_toSRAM_27_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_wmask golden=%h impl=%h", cyc, g0_toSRAM_27_wmask, x0_toSRAM_27_wmask); end
    if (g0_toSRAM_27_re !== x0_toSRAM_27_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_re golden=%h impl=%h", cyc, g0_toSRAM_27_re, x0_toSRAM_27_re); end
    if (g0_toSRAM_27_we !== x0_toSRAM_27_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_we golden=%h impl=%h", cyc, g0_toSRAM_27_we, x0_toSRAM_27_we); end
    if (g0_toSRAM_27_ack !== x0_toSRAM_27_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_ack golden=%h impl=%h", cyc, g0_toSRAM_27_ack, x0_toSRAM_27_ack); end
    if (g0_toSRAM_27_selectedOH !== x0_toSRAM_27_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_27_selectedOH, x0_toSRAM_27_selectedOH); end
    if (g0_toSRAM_27_array !== x0_toSRAM_27_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_27_array golden=%h impl=%h", cyc, g0_toSRAM_27_array, x0_toSRAM_27_array); end
    if (g0_toSRAM_28_addr !== x0_toSRAM_28_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_addr golden=%h impl=%h", cyc, g0_toSRAM_28_addr, x0_toSRAM_28_addr); end
    if (g0_toSRAM_28_addr_rd !== x0_toSRAM_28_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_28_addr_rd, x0_toSRAM_28_addr_rd); end
    if (g0_toSRAM_28_wdata !== x0_toSRAM_28_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_wdata golden=%h impl=%h", cyc, g0_toSRAM_28_wdata, x0_toSRAM_28_wdata); end
    if (g0_toSRAM_28_wmask !== x0_toSRAM_28_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_wmask golden=%h impl=%h", cyc, g0_toSRAM_28_wmask, x0_toSRAM_28_wmask); end
    if (g0_toSRAM_28_re !== x0_toSRAM_28_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_re golden=%h impl=%h", cyc, g0_toSRAM_28_re, x0_toSRAM_28_re); end
    if (g0_toSRAM_28_we !== x0_toSRAM_28_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_we golden=%h impl=%h", cyc, g0_toSRAM_28_we, x0_toSRAM_28_we); end
    if (g0_toSRAM_28_ack !== x0_toSRAM_28_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_ack golden=%h impl=%h", cyc, g0_toSRAM_28_ack, x0_toSRAM_28_ack); end
    if (g0_toSRAM_28_selectedOH !== x0_toSRAM_28_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_28_selectedOH, x0_toSRAM_28_selectedOH); end
    if (g0_toSRAM_28_array !== x0_toSRAM_28_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_28_array golden=%h impl=%h", cyc, g0_toSRAM_28_array, x0_toSRAM_28_array); end
    if (g0_toSRAM_29_addr !== x0_toSRAM_29_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_addr golden=%h impl=%h", cyc, g0_toSRAM_29_addr, x0_toSRAM_29_addr); end
    if (g0_toSRAM_29_addr_rd !== x0_toSRAM_29_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_29_addr_rd, x0_toSRAM_29_addr_rd); end
    if (g0_toSRAM_29_wdata !== x0_toSRAM_29_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_wdata golden=%h impl=%h", cyc, g0_toSRAM_29_wdata, x0_toSRAM_29_wdata); end
    if (g0_toSRAM_29_wmask !== x0_toSRAM_29_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_wmask golden=%h impl=%h", cyc, g0_toSRAM_29_wmask, x0_toSRAM_29_wmask); end
    if (g0_toSRAM_29_re !== x0_toSRAM_29_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_re golden=%h impl=%h", cyc, g0_toSRAM_29_re, x0_toSRAM_29_re); end
    if (g0_toSRAM_29_we !== x0_toSRAM_29_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_we golden=%h impl=%h", cyc, g0_toSRAM_29_we, x0_toSRAM_29_we); end
    if (g0_toSRAM_29_ack !== x0_toSRAM_29_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_ack golden=%h impl=%h", cyc, g0_toSRAM_29_ack, x0_toSRAM_29_ack); end
    if (g0_toSRAM_29_selectedOH !== x0_toSRAM_29_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_29_selectedOH, x0_toSRAM_29_selectedOH); end
    if (g0_toSRAM_29_array !== x0_toSRAM_29_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_29_array golden=%h impl=%h", cyc, g0_toSRAM_29_array, x0_toSRAM_29_array); end
    if (g0_toSRAM_30_addr !== x0_toSRAM_30_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_addr golden=%h impl=%h", cyc, g0_toSRAM_30_addr, x0_toSRAM_30_addr); end
    if (g0_toSRAM_30_addr_rd !== x0_toSRAM_30_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_30_addr_rd, x0_toSRAM_30_addr_rd); end
    if (g0_toSRAM_30_wdata !== x0_toSRAM_30_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_wdata golden=%h impl=%h", cyc, g0_toSRAM_30_wdata, x0_toSRAM_30_wdata); end
    if (g0_toSRAM_30_wmask !== x0_toSRAM_30_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_wmask golden=%h impl=%h", cyc, g0_toSRAM_30_wmask, x0_toSRAM_30_wmask); end
    if (g0_toSRAM_30_re !== x0_toSRAM_30_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_re golden=%h impl=%h", cyc, g0_toSRAM_30_re, x0_toSRAM_30_re); end
    if (g0_toSRAM_30_we !== x0_toSRAM_30_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_we golden=%h impl=%h", cyc, g0_toSRAM_30_we, x0_toSRAM_30_we); end
    if (g0_toSRAM_30_ack !== x0_toSRAM_30_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_ack golden=%h impl=%h", cyc, g0_toSRAM_30_ack, x0_toSRAM_30_ack); end
    if (g0_toSRAM_30_selectedOH !== x0_toSRAM_30_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_30_selectedOH, x0_toSRAM_30_selectedOH); end
    if (g0_toSRAM_30_array !== x0_toSRAM_30_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_30_array golden=%h impl=%h", cyc, g0_toSRAM_30_array, x0_toSRAM_30_array); end
    if (g0_toSRAM_31_addr !== x0_toSRAM_31_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_addr golden=%h impl=%h", cyc, g0_toSRAM_31_addr, x0_toSRAM_31_addr); end
    if (g0_toSRAM_31_addr_rd !== x0_toSRAM_31_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_addr_rd golden=%h impl=%h", cyc, g0_toSRAM_31_addr_rd, x0_toSRAM_31_addr_rd); end
    if (g0_toSRAM_31_wdata !== x0_toSRAM_31_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_wdata golden=%h impl=%h", cyc, g0_toSRAM_31_wdata, x0_toSRAM_31_wdata); end
    if (g0_toSRAM_31_wmask !== x0_toSRAM_31_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_wmask golden=%h impl=%h", cyc, g0_toSRAM_31_wmask, x0_toSRAM_31_wmask); end
    if (g0_toSRAM_31_re !== x0_toSRAM_31_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_re golden=%h impl=%h", cyc, g0_toSRAM_31_re, x0_toSRAM_31_re); end
    if (g0_toSRAM_31_we !== x0_toSRAM_31_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_we golden=%h impl=%h", cyc, g0_toSRAM_31_we, x0_toSRAM_31_we); end
    if (g0_toSRAM_31_ack !== x0_toSRAM_31_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_ack golden=%h impl=%h", cyc, g0_toSRAM_31_ack, x0_toSRAM_31_ack); end
    if (g0_toSRAM_31_selectedOH !== x0_toSRAM_31_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_selectedOH golden=%h impl=%h", cyc, g0_toSRAM_31_selectedOH, x0_toSRAM_31_selectedOH); end
    if (g0_toSRAM_31_array !== x0_toSRAM_31_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDCacheData.toSRAM_31_array golden=%h impl=%h", cyc, g0_toSRAM_31_array, x0_toSRAM_31_array); end
  endtask

  // ======================== [01] MbistPipeDcacheTag ========================
  logic [85:0] v1_rd0;
  logic [85:0] v1_rd1;
  logic [85:0] v1_rd2;
  logic [85:0] v1_rd3;
  logic [85:0] v1_rd4;
  logic [85:0] v1_rd5;
  logic [85:0] v1_rd6;
  logic [85:0] v1_rd7;
  logic g1_mbist_ack;
  logic [85:0] g1_mbist_outdata;
  logic [8:0] g1_toSRAM_0_addr;
  logic [8:0] g1_toSRAM_0_addr_rd;
  logic [85:0] g1_toSRAM_0_wdata;
  logic [1:0] g1_toSRAM_0_wmask;
  logic g1_toSRAM_0_re;
  logic g1_toSRAM_0_we;
  logic g1_toSRAM_0_ack;
  logic g1_toSRAM_0_selectedOH;
  logic [5:0] g1_toSRAM_0_array;
  logic [8:0] g1_toSRAM_1_addr;
  logic [8:0] g1_toSRAM_1_addr_rd;
  logic [85:0] g1_toSRAM_1_wdata;
  logic [1:0] g1_toSRAM_1_wmask;
  logic g1_toSRAM_1_re;
  logic g1_toSRAM_1_we;
  logic g1_toSRAM_1_ack;
  logic g1_toSRAM_1_selectedOH;
  logic [5:0] g1_toSRAM_1_array;
  logic [8:0] g1_toSRAM_2_addr;
  logic [8:0] g1_toSRAM_2_addr_rd;
  logic [85:0] g1_toSRAM_2_wdata;
  logic [1:0] g1_toSRAM_2_wmask;
  logic g1_toSRAM_2_re;
  logic g1_toSRAM_2_we;
  logic g1_toSRAM_2_ack;
  logic g1_toSRAM_2_selectedOH;
  logic [5:0] g1_toSRAM_2_array;
  logic [8:0] g1_toSRAM_3_addr;
  logic [8:0] g1_toSRAM_3_addr_rd;
  logic [85:0] g1_toSRAM_3_wdata;
  logic [1:0] g1_toSRAM_3_wmask;
  logic g1_toSRAM_3_re;
  logic g1_toSRAM_3_we;
  logic g1_toSRAM_3_ack;
  logic g1_toSRAM_3_selectedOH;
  logic [5:0] g1_toSRAM_3_array;
  logic [8:0] g1_toSRAM_4_addr;
  logic [8:0] g1_toSRAM_4_addr_rd;
  logic [85:0] g1_toSRAM_4_wdata;
  logic [1:0] g1_toSRAM_4_wmask;
  logic g1_toSRAM_4_re;
  logic g1_toSRAM_4_we;
  logic g1_toSRAM_4_ack;
  logic g1_toSRAM_4_selectedOH;
  logic [5:0] g1_toSRAM_4_array;
  logic [8:0] g1_toSRAM_5_addr;
  logic [8:0] g1_toSRAM_5_addr_rd;
  logic [85:0] g1_toSRAM_5_wdata;
  logic [1:0] g1_toSRAM_5_wmask;
  logic g1_toSRAM_5_re;
  logic g1_toSRAM_5_we;
  logic g1_toSRAM_5_ack;
  logic g1_toSRAM_5_selectedOH;
  logic [5:0] g1_toSRAM_5_array;
  logic [8:0] g1_toSRAM_6_addr;
  logic [8:0] g1_toSRAM_6_addr_rd;
  logic [85:0] g1_toSRAM_6_wdata;
  logic [1:0] g1_toSRAM_6_wmask;
  logic g1_toSRAM_6_re;
  logic g1_toSRAM_6_we;
  logic g1_toSRAM_6_ack;
  logic g1_toSRAM_6_selectedOH;
  logic [5:0] g1_toSRAM_6_array;
  logic [8:0] g1_toSRAM_7_addr;
  logic [8:0] g1_toSRAM_7_addr_rd;
  logic [85:0] g1_toSRAM_7_wdata;
  logic [1:0] g1_toSRAM_7_wmask;
  logic g1_toSRAM_7_re;
  logic g1_toSRAM_7_we;
  logic g1_toSRAM_7_ack;
  logic g1_toSRAM_7_selectedOH;
  logic [5:0] g1_toSRAM_7_array;
  logic x1_mbist_ack;
  logic [85:0] x1_mbist_outdata;
  logic [8:0] x1_toSRAM_0_addr;
  logic [8:0] x1_toSRAM_0_addr_rd;
  logic [85:0] x1_toSRAM_0_wdata;
  logic [1:0] x1_toSRAM_0_wmask;
  logic x1_toSRAM_0_re;
  logic x1_toSRAM_0_we;
  logic x1_toSRAM_0_ack;
  logic x1_toSRAM_0_selectedOH;
  logic [5:0] x1_toSRAM_0_array;
  logic [8:0] x1_toSRAM_1_addr;
  logic [8:0] x1_toSRAM_1_addr_rd;
  logic [85:0] x1_toSRAM_1_wdata;
  logic [1:0] x1_toSRAM_1_wmask;
  logic x1_toSRAM_1_re;
  logic x1_toSRAM_1_we;
  logic x1_toSRAM_1_ack;
  logic x1_toSRAM_1_selectedOH;
  logic [5:0] x1_toSRAM_1_array;
  logic [8:0] x1_toSRAM_2_addr;
  logic [8:0] x1_toSRAM_2_addr_rd;
  logic [85:0] x1_toSRAM_2_wdata;
  logic [1:0] x1_toSRAM_2_wmask;
  logic x1_toSRAM_2_re;
  logic x1_toSRAM_2_we;
  logic x1_toSRAM_2_ack;
  logic x1_toSRAM_2_selectedOH;
  logic [5:0] x1_toSRAM_2_array;
  logic [8:0] x1_toSRAM_3_addr;
  logic [8:0] x1_toSRAM_3_addr_rd;
  logic [85:0] x1_toSRAM_3_wdata;
  logic [1:0] x1_toSRAM_3_wmask;
  logic x1_toSRAM_3_re;
  logic x1_toSRAM_3_we;
  logic x1_toSRAM_3_ack;
  logic x1_toSRAM_3_selectedOH;
  logic [5:0] x1_toSRAM_3_array;
  logic [8:0] x1_toSRAM_4_addr;
  logic [8:0] x1_toSRAM_4_addr_rd;
  logic [85:0] x1_toSRAM_4_wdata;
  logic [1:0] x1_toSRAM_4_wmask;
  logic x1_toSRAM_4_re;
  logic x1_toSRAM_4_we;
  logic x1_toSRAM_4_ack;
  logic x1_toSRAM_4_selectedOH;
  logic [5:0] x1_toSRAM_4_array;
  logic [8:0] x1_toSRAM_5_addr;
  logic [8:0] x1_toSRAM_5_addr_rd;
  logic [85:0] x1_toSRAM_5_wdata;
  logic [1:0] x1_toSRAM_5_wmask;
  logic x1_toSRAM_5_re;
  logic x1_toSRAM_5_we;
  logic x1_toSRAM_5_ack;
  logic x1_toSRAM_5_selectedOH;
  logic [5:0] x1_toSRAM_5_array;
  logic [8:0] x1_toSRAM_6_addr;
  logic [8:0] x1_toSRAM_6_addr_rd;
  logic [85:0] x1_toSRAM_6_wdata;
  logic [1:0] x1_toSRAM_6_wmask;
  logic x1_toSRAM_6_re;
  logic x1_toSRAM_6_we;
  logic x1_toSRAM_6_ack;
  logic x1_toSRAM_6_selectedOH;
  logic [5:0] x1_toSRAM_6_array;
  logic [8:0] x1_toSRAM_7_addr;
  logic [8:0] x1_toSRAM_7_addr_rd;
  logic [85:0] x1_toSRAM_7_wdata;
  logic [1:0] x1_toSRAM_7_wmask;
  logic x1_toSRAM_7_re;
  logic x1_toSRAM_7_we;
  logic x1_toSRAM_7_ack;
  logic x1_toSRAM_7_selectedOH;
  logic [5:0] x1_toSRAM_7_array;
  bit [7:0] cov_spread1;
  bit [85:0] cov_od0_1, cov_od1_1;
  bit cov_ack0_1, cov_ack1_1;
  MbistPipeDcacheTag u_g1 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[85:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v1_rd0),
    .toSRAM_1_rdata (v1_rd1),
    .toSRAM_2_rdata (v1_rd2),
    .toSRAM_3_rdata (v1_rd3),
    .toSRAM_4_rdata (v1_rd4),
    .toSRAM_5_rdata (v1_rd5),
    .toSRAM_6_rdata (v1_rd6),
    .toSRAM_7_rdata (v1_rd7),
    .mbist_ack (g1_mbist_ack),
    .mbist_outdata (g1_mbist_outdata),
    .toSRAM_0_addr (g1_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g1_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g1_toSRAM_0_wdata),
    .toSRAM_0_wmask (g1_toSRAM_0_wmask),
    .toSRAM_0_re (g1_toSRAM_0_re),
    .toSRAM_0_we (g1_toSRAM_0_we),
    .toSRAM_0_ack (g1_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g1_toSRAM_0_selectedOH),
    .toSRAM_0_array (g1_toSRAM_0_array),
    .toSRAM_1_addr (g1_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g1_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g1_toSRAM_1_wdata),
    .toSRAM_1_wmask (g1_toSRAM_1_wmask),
    .toSRAM_1_re (g1_toSRAM_1_re),
    .toSRAM_1_we (g1_toSRAM_1_we),
    .toSRAM_1_ack (g1_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g1_toSRAM_1_selectedOH),
    .toSRAM_1_array (g1_toSRAM_1_array),
    .toSRAM_2_addr (g1_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g1_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g1_toSRAM_2_wdata),
    .toSRAM_2_wmask (g1_toSRAM_2_wmask),
    .toSRAM_2_re (g1_toSRAM_2_re),
    .toSRAM_2_we (g1_toSRAM_2_we),
    .toSRAM_2_ack (g1_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g1_toSRAM_2_selectedOH),
    .toSRAM_2_array (g1_toSRAM_2_array),
    .toSRAM_3_addr (g1_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g1_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g1_toSRAM_3_wdata),
    .toSRAM_3_wmask (g1_toSRAM_3_wmask),
    .toSRAM_3_re (g1_toSRAM_3_re),
    .toSRAM_3_we (g1_toSRAM_3_we),
    .toSRAM_3_ack (g1_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g1_toSRAM_3_selectedOH),
    .toSRAM_3_array (g1_toSRAM_3_array),
    .toSRAM_4_addr (g1_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g1_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g1_toSRAM_4_wdata),
    .toSRAM_4_wmask (g1_toSRAM_4_wmask),
    .toSRAM_4_re (g1_toSRAM_4_re),
    .toSRAM_4_we (g1_toSRAM_4_we),
    .toSRAM_4_ack (g1_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g1_toSRAM_4_selectedOH),
    .toSRAM_4_array (g1_toSRAM_4_array),
    .toSRAM_5_addr (g1_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g1_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g1_toSRAM_5_wdata),
    .toSRAM_5_wmask (g1_toSRAM_5_wmask),
    .toSRAM_5_re (g1_toSRAM_5_re),
    .toSRAM_5_we (g1_toSRAM_5_we),
    .toSRAM_5_ack (g1_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g1_toSRAM_5_selectedOH),
    .toSRAM_5_array (g1_toSRAM_5_array),
    .toSRAM_6_addr (g1_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g1_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g1_toSRAM_6_wdata),
    .toSRAM_6_wmask (g1_toSRAM_6_wmask),
    .toSRAM_6_re (g1_toSRAM_6_re),
    .toSRAM_6_we (g1_toSRAM_6_we),
    .toSRAM_6_ack (g1_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g1_toSRAM_6_selectedOH),
    .toSRAM_6_array (g1_toSRAM_6_array),
    .toSRAM_7_addr (g1_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g1_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g1_toSRAM_7_wdata),
    .toSRAM_7_wmask (g1_toSRAM_7_wmask),
    .toSRAM_7_re (g1_toSRAM_7_re),
    .toSRAM_7_we (g1_toSRAM_7_we),
    .toSRAM_7_ack (g1_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g1_toSRAM_7_selectedOH),
    .toSRAM_7_array (g1_toSRAM_7_array)
  );
  MbistPipeDcacheTag_xs u_x1 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[85:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v1_rd0),
    .toSRAM_1_rdata (v1_rd1),
    .toSRAM_2_rdata (v1_rd2),
    .toSRAM_3_rdata (v1_rd3),
    .toSRAM_4_rdata (v1_rd4),
    .toSRAM_5_rdata (v1_rd5),
    .toSRAM_6_rdata (v1_rd6),
    .toSRAM_7_rdata (v1_rd7),
    .mbist_ack (x1_mbist_ack),
    .mbist_outdata (x1_mbist_outdata),
    .toSRAM_0_addr (x1_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x1_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x1_toSRAM_0_wdata),
    .toSRAM_0_wmask (x1_toSRAM_0_wmask),
    .toSRAM_0_re (x1_toSRAM_0_re),
    .toSRAM_0_we (x1_toSRAM_0_we),
    .toSRAM_0_ack (x1_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x1_toSRAM_0_selectedOH),
    .toSRAM_0_array (x1_toSRAM_0_array),
    .toSRAM_1_addr (x1_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x1_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x1_toSRAM_1_wdata),
    .toSRAM_1_wmask (x1_toSRAM_1_wmask),
    .toSRAM_1_re (x1_toSRAM_1_re),
    .toSRAM_1_we (x1_toSRAM_1_we),
    .toSRAM_1_ack (x1_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x1_toSRAM_1_selectedOH),
    .toSRAM_1_array (x1_toSRAM_1_array),
    .toSRAM_2_addr (x1_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x1_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x1_toSRAM_2_wdata),
    .toSRAM_2_wmask (x1_toSRAM_2_wmask),
    .toSRAM_2_re (x1_toSRAM_2_re),
    .toSRAM_2_we (x1_toSRAM_2_we),
    .toSRAM_2_ack (x1_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x1_toSRAM_2_selectedOH),
    .toSRAM_2_array (x1_toSRAM_2_array),
    .toSRAM_3_addr (x1_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x1_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x1_toSRAM_3_wdata),
    .toSRAM_3_wmask (x1_toSRAM_3_wmask),
    .toSRAM_3_re (x1_toSRAM_3_re),
    .toSRAM_3_we (x1_toSRAM_3_we),
    .toSRAM_3_ack (x1_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x1_toSRAM_3_selectedOH),
    .toSRAM_3_array (x1_toSRAM_3_array),
    .toSRAM_4_addr (x1_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x1_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x1_toSRAM_4_wdata),
    .toSRAM_4_wmask (x1_toSRAM_4_wmask),
    .toSRAM_4_re (x1_toSRAM_4_re),
    .toSRAM_4_we (x1_toSRAM_4_we),
    .toSRAM_4_ack (x1_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x1_toSRAM_4_selectedOH),
    .toSRAM_4_array (x1_toSRAM_4_array),
    .toSRAM_5_addr (x1_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x1_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x1_toSRAM_5_wdata),
    .toSRAM_5_wmask (x1_toSRAM_5_wmask),
    .toSRAM_5_re (x1_toSRAM_5_re),
    .toSRAM_5_we (x1_toSRAM_5_we),
    .toSRAM_5_ack (x1_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x1_toSRAM_5_selectedOH),
    .toSRAM_5_array (x1_toSRAM_5_array),
    .toSRAM_6_addr (x1_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x1_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x1_toSRAM_6_wdata),
    .toSRAM_6_wmask (x1_toSRAM_6_wmask),
    .toSRAM_6_re (x1_toSRAM_6_re),
    .toSRAM_6_we (x1_toSRAM_6_we),
    .toSRAM_6_ack (x1_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x1_toSRAM_6_selectedOH),
    .toSRAM_6_array (x1_toSRAM_6_array),
    .toSRAM_7_addr (x1_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x1_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x1_toSRAM_7_wdata),
    .toSRAM_7_wmask (x1_toSRAM_7_wmask),
    .toSRAM_7_re (x1_toSRAM_7_re),
    .toSRAM_7_we (x1_toSRAM_7_we),
    .toSRAM_7_ack (x1_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x1_toSRAM_7_selectedOH),
    .toSRAM_7_array (x1_toSRAM_7_array)
  );
  wire [1014:0] gbus1 = {g1_mbist_ack, g1_mbist_outdata, g1_toSRAM_0_addr, g1_toSRAM_0_addr_rd, g1_toSRAM_0_wdata, g1_toSRAM_0_wmask, g1_toSRAM_0_re, g1_toSRAM_0_we, g1_toSRAM_0_ack, g1_toSRAM_0_selectedOH, g1_toSRAM_0_array, g1_toSRAM_1_addr, g1_toSRAM_1_addr_rd, g1_toSRAM_1_wdata, g1_toSRAM_1_wmask, g1_toSRAM_1_re, g1_toSRAM_1_we, g1_toSRAM_1_ack, g1_toSRAM_1_selectedOH, g1_toSRAM_1_array, g1_toSRAM_2_addr, g1_toSRAM_2_addr_rd, g1_toSRAM_2_wdata, g1_toSRAM_2_wmask, g1_toSRAM_2_re, g1_toSRAM_2_we, g1_toSRAM_2_ack, g1_toSRAM_2_selectedOH, g1_toSRAM_2_array, g1_toSRAM_3_addr, g1_toSRAM_3_addr_rd, g1_toSRAM_3_wdata, g1_toSRAM_3_wmask, g1_toSRAM_3_re, g1_toSRAM_3_we, g1_toSRAM_3_ack, g1_toSRAM_3_selectedOH, g1_toSRAM_3_array, g1_toSRAM_4_addr, g1_toSRAM_4_addr_rd, g1_toSRAM_4_wdata, g1_toSRAM_4_wmask, g1_toSRAM_4_re, g1_toSRAM_4_we, g1_toSRAM_4_ack, g1_toSRAM_4_selectedOH, g1_toSRAM_4_array, g1_toSRAM_5_addr, g1_toSRAM_5_addr_rd, g1_toSRAM_5_wdata, g1_toSRAM_5_wmask, g1_toSRAM_5_re, g1_toSRAM_5_we, g1_toSRAM_5_ack, g1_toSRAM_5_selectedOH, g1_toSRAM_5_array, g1_toSRAM_6_addr, g1_toSRAM_6_addr_rd, g1_toSRAM_6_wdata, g1_toSRAM_6_wmask, g1_toSRAM_6_re, g1_toSRAM_6_we, g1_toSRAM_6_ack, g1_toSRAM_6_selectedOH, g1_toSRAM_6_array, g1_toSRAM_7_addr, g1_toSRAM_7_addr_rd, g1_toSRAM_7_wdata, g1_toSRAM_7_wmask, g1_toSRAM_7_re, g1_toSRAM_7_we, g1_toSRAM_7_ack, g1_toSRAM_7_selectedOH, g1_toSRAM_7_array};
  wire [1014:0] xbus1 = {x1_mbist_ack, x1_mbist_outdata, x1_toSRAM_0_addr, x1_toSRAM_0_addr_rd, x1_toSRAM_0_wdata, x1_toSRAM_0_wmask, x1_toSRAM_0_re, x1_toSRAM_0_we, x1_toSRAM_0_ack, x1_toSRAM_0_selectedOH, x1_toSRAM_0_array, x1_toSRAM_1_addr, x1_toSRAM_1_addr_rd, x1_toSRAM_1_wdata, x1_toSRAM_1_wmask, x1_toSRAM_1_re, x1_toSRAM_1_we, x1_toSRAM_1_ack, x1_toSRAM_1_selectedOH, x1_toSRAM_1_array, x1_toSRAM_2_addr, x1_toSRAM_2_addr_rd, x1_toSRAM_2_wdata, x1_toSRAM_2_wmask, x1_toSRAM_2_re, x1_toSRAM_2_we, x1_toSRAM_2_ack, x1_toSRAM_2_selectedOH, x1_toSRAM_2_array, x1_toSRAM_3_addr, x1_toSRAM_3_addr_rd, x1_toSRAM_3_wdata, x1_toSRAM_3_wmask, x1_toSRAM_3_re, x1_toSRAM_3_we, x1_toSRAM_3_ack, x1_toSRAM_3_selectedOH, x1_toSRAM_3_array, x1_toSRAM_4_addr, x1_toSRAM_4_addr_rd, x1_toSRAM_4_wdata, x1_toSRAM_4_wmask, x1_toSRAM_4_re, x1_toSRAM_4_we, x1_toSRAM_4_ack, x1_toSRAM_4_selectedOH, x1_toSRAM_4_array, x1_toSRAM_5_addr, x1_toSRAM_5_addr_rd, x1_toSRAM_5_wdata, x1_toSRAM_5_wmask, x1_toSRAM_5_re, x1_toSRAM_5_we, x1_toSRAM_5_ack, x1_toSRAM_5_selectedOH, x1_toSRAM_5_array, x1_toSRAM_6_addr, x1_toSRAM_6_addr_rd, x1_toSRAM_6_wdata, x1_toSRAM_6_wmask, x1_toSRAM_6_re, x1_toSRAM_6_we, x1_toSRAM_6_ack, x1_toSRAM_6_selectedOH, x1_toSRAM_6_array, x1_toSRAM_7_addr, x1_toSRAM_7_addr_rd, x1_toSRAM_7_wdata, x1_toSRAM_7_wmask, x1_toSRAM_7_re, x1_toSRAM_7_we, x1_toSRAM_7_ack, x1_toSRAM_7_selectedOH, x1_toSRAM_7_array};
  task automatic detail1();
    if (g1_mbist_ack !== x1_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.mbist_ack golden=%h impl=%h", cyc, g1_mbist_ack, x1_mbist_ack); end
    if (g1_mbist_outdata !== x1_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.mbist_outdata golden=%h impl=%h", cyc, g1_mbist_outdata, x1_mbist_outdata); end
    if (g1_toSRAM_0_addr !== x1_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_addr golden=%h impl=%h", cyc, g1_toSRAM_0_addr, x1_toSRAM_0_addr); end
    if (g1_toSRAM_0_addr_rd !== x1_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_0_addr_rd, x1_toSRAM_0_addr_rd); end
    if (g1_toSRAM_0_wdata !== x1_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_wdata golden=%h impl=%h", cyc, g1_toSRAM_0_wdata, x1_toSRAM_0_wdata); end
    if (g1_toSRAM_0_wmask !== x1_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_wmask golden=%h impl=%h", cyc, g1_toSRAM_0_wmask, x1_toSRAM_0_wmask); end
    if (g1_toSRAM_0_re !== x1_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_re golden=%h impl=%h", cyc, g1_toSRAM_0_re, x1_toSRAM_0_re); end
    if (g1_toSRAM_0_we !== x1_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_we golden=%h impl=%h", cyc, g1_toSRAM_0_we, x1_toSRAM_0_we); end
    if (g1_toSRAM_0_ack !== x1_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_ack golden=%h impl=%h", cyc, g1_toSRAM_0_ack, x1_toSRAM_0_ack); end
    if (g1_toSRAM_0_selectedOH !== x1_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_0_selectedOH, x1_toSRAM_0_selectedOH); end
    if (g1_toSRAM_0_array !== x1_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_0_array golden=%h impl=%h", cyc, g1_toSRAM_0_array, x1_toSRAM_0_array); end
    if (g1_toSRAM_1_addr !== x1_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_addr golden=%h impl=%h", cyc, g1_toSRAM_1_addr, x1_toSRAM_1_addr); end
    if (g1_toSRAM_1_addr_rd !== x1_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_1_addr_rd, x1_toSRAM_1_addr_rd); end
    if (g1_toSRAM_1_wdata !== x1_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_wdata golden=%h impl=%h", cyc, g1_toSRAM_1_wdata, x1_toSRAM_1_wdata); end
    if (g1_toSRAM_1_wmask !== x1_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_wmask golden=%h impl=%h", cyc, g1_toSRAM_1_wmask, x1_toSRAM_1_wmask); end
    if (g1_toSRAM_1_re !== x1_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_re golden=%h impl=%h", cyc, g1_toSRAM_1_re, x1_toSRAM_1_re); end
    if (g1_toSRAM_1_we !== x1_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_we golden=%h impl=%h", cyc, g1_toSRAM_1_we, x1_toSRAM_1_we); end
    if (g1_toSRAM_1_ack !== x1_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_ack golden=%h impl=%h", cyc, g1_toSRAM_1_ack, x1_toSRAM_1_ack); end
    if (g1_toSRAM_1_selectedOH !== x1_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_1_selectedOH, x1_toSRAM_1_selectedOH); end
    if (g1_toSRAM_1_array !== x1_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_1_array golden=%h impl=%h", cyc, g1_toSRAM_1_array, x1_toSRAM_1_array); end
    if (g1_toSRAM_2_addr !== x1_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_addr golden=%h impl=%h", cyc, g1_toSRAM_2_addr, x1_toSRAM_2_addr); end
    if (g1_toSRAM_2_addr_rd !== x1_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_2_addr_rd, x1_toSRAM_2_addr_rd); end
    if (g1_toSRAM_2_wdata !== x1_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_wdata golden=%h impl=%h", cyc, g1_toSRAM_2_wdata, x1_toSRAM_2_wdata); end
    if (g1_toSRAM_2_wmask !== x1_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_wmask golden=%h impl=%h", cyc, g1_toSRAM_2_wmask, x1_toSRAM_2_wmask); end
    if (g1_toSRAM_2_re !== x1_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_re golden=%h impl=%h", cyc, g1_toSRAM_2_re, x1_toSRAM_2_re); end
    if (g1_toSRAM_2_we !== x1_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_we golden=%h impl=%h", cyc, g1_toSRAM_2_we, x1_toSRAM_2_we); end
    if (g1_toSRAM_2_ack !== x1_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_ack golden=%h impl=%h", cyc, g1_toSRAM_2_ack, x1_toSRAM_2_ack); end
    if (g1_toSRAM_2_selectedOH !== x1_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_2_selectedOH, x1_toSRAM_2_selectedOH); end
    if (g1_toSRAM_2_array !== x1_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_2_array golden=%h impl=%h", cyc, g1_toSRAM_2_array, x1_toSRAM_2_array); end
    if (g1_toSRAM_3_addr !== x1_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_addr golden=%h impl=%h", cyc, g1_toSRAM_3_addr, x1_toSRAM_3_addr); end
    if (g1_toSRAM_3_addr_rd !== x1_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_3_addr_rd, x1_toSRAM_3_addr_rd); end
    if (g1_toSRAM_3_wdata !== x1_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_wdata golden=%h impl=%h", cyc, g1_toSRAM_3_wdata, x1_toSRAM_3_wdata); end
    if (g1_toSRAM_3_wmask !== x1_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_wmask golden=%h impl=%h", cyc, g1_toSRAM_3_wmask, x1_toSRAM_3_wmask); end
    if (g1_toSRAM_3_re !== x1_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_re golden=%h impl=%h", cyc, g1_toSRAM_3_re, x1_toSRAM_3_re); end
    if (g1_toSRAM_3_we !== x1_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_we golden=%h impl=%h", cyc, g1_toSRAM_3_we, x1_toSRAM_3_we); end
    if (g1_toSRAM_3_ack !== x1_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_ack golden=%h impl=%h", cyc, g1_toSRAM_3_ack, x1_toSRAM_3_ack); end
    if (g1_toSRAM_3_selectedOH !== x1_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_3_selectedOH, x1_toSRAM_3_selectedOH); end
    if (g1_toSRAM_3_array !== x1_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_3_array golden=%h impl=%h", cyc, g1_toSRAM_3_array, x1_toSRAM_3_array); end
    if (g1_toSRAM_4_addr !== x1_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_addr golden=%h impl=%h", cyc, g1_toSRAM_4_addr, x1_toSRAM_4_addr); end
    if (g1_toSRAM_4_addr_rd !== x1_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_4_addr_rd, x1_toSRAM_4_addr_rd); end
    if (g1_toSRAM_4_wdata !== x1_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_wdata golden=%h impl=%h", cyc, g1_toSRAM_4_wdata, x1_toSRAM_4_wdata); end
    if (g1_toSRAM_4_wmask !== x1_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_wmask golden=%h impl=%h", cyc, g1_toSRAM_4_wmask, x1_toSRAM_4_wmask); end
    if (g1_toSRAM_4_re !== x1_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_re golden=%h impl=%h", cyc, g1_toSRAM_4_re, x1_toSRAM_4_re); end
    if (g1_toSRAM_4_we !== x1_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_we golden=%h impl=%h", cyc, g1_toSRAM_4_we, x1_toSRAM_4_we); end
    if (g1_toSRAM_4_ack !== x1_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_ack golden=%h impl=%h", cyc, g1_toSRAM_4_ack, x1_toSRAM_4_ack); end
    if (g1_toSRAM_4_selectedOH !== x1_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_4_selectedOH, x1_toSRAM_4_selectedOH); end
    if (g1_toSRAM_4_array !== x1_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_4_array golden=%h impl=%h", cyc, g1_toSRAM_4_array, x1_toSRAM_4_array); end
    if (g1_toSRAM_5_addr !== x1_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_addr golden=%h impl=%h", cyc, g1_toSRAM_5_addr, x1_toSRAM_5_addr); end
    if (g1_toSRAM_5_addr_rd !== x1_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_5_addr_rd, x1_toSRAM_5_addr_rd); end
    if (g1_toSRAM_5_wdata !== x1_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_wdata golden=%h impl=%h", cyc, g1_toSRAM_5_wdata, x1_toSRAM_5_wdata); end
    if (g1_toSRAM_5_wmask !== x1_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_wmask golden=%h impl=%h", cyc, g1_toSRAM_5_wmask, x1_toSRAM_5_wmask); end
    if (g1_toSRAM_5_re !== x1_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_re golden=%h impl=%h", cyc, g1_toSRAM_5_re, x1_toSRAM_5_re); end
    if (g1_toSRAM_5_we !== x1_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_we golden=%h impl=%h", cyc, g1_toSRAM_5_we, x1_toSRAM_5_we); end
    if (g1_toSRAM_5_ack !== x1_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_ack golden=%h impl=%h", cyc, g1_toSRAM_5_ack, x1_toSRAM_5_ack); end
    if (g1_toSRAM_5_selectedOH !== x1_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_5_selectedOH, x1_toSRAM_5_selectedOH); end
    if (g1_toSRAM_5_array !== x1_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_5_array golden=%h impl=%h", cyc, g1_toSRAM_5_array, x1_toSRAM_5_array); end
    if (g1_toSRAM_6_addr !== x1_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_addr golden=%h impl=%h", cyc, g1_toSRAM_6_addr, x1_toSRAM_6_addr); end
    if (g1_toSRAM_6_addr_rd !== x1_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_6_addr_rd, x1_toSRAM_6_addr_rd); end
    if (g1_toSRAM_6_wdata !== x1_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_wdata golden=%h impl=%h", cyc, g1_toSRAM_6_wdata, x1_toSRAM_6_wdata); end
    if (g1_toSRAM_6_wmask !== x1_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_wmask golden=%h impl=%h", cyc, g1_toSRAM_6_wmask, x1_toSRAM_6_wmask); end
    if (g1_toSRAM_6_re !== x1_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_re golden=%h impl=%h", cyc, g1_toSRAM_6_re, x1_toSRAM_6_re); end
    if (g1_toSRAM_6_we !== x1_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_we golden=%h impl=%h", cyc, g1_toSRAM_6_we, x1_toSRAM_6_we); end
    if (g1_toSRAM_6_ack !== x1_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_ack golden=%h impl=%h", cyc, g1_toSRAM_6_ack, x1_toSRAM_6_ack); end
    if (g1_toSRAM_6_selectedOH !== x1_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_6_selectedOH, x1_toSRAM_6_selectedOH); end
    if (g1_toSRAM_6_array !== x1_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_6_array golden=%h impl=%h", cyc, g1_toSRAM_6_array, x1_toSRAM_6_array); end
    if (g1_toSRAM_7_addr !== x1_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_addr golden=%h impl=%h", cyc, g1_toSRAM_7_addr, x1_toSRAM_7_addr); end
    if (g1_toSRAM_7_addr_rd !== x1_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g1_toSRAM_7_addr_rd, x1_toSRAM_7_addr_rd); end
    if (g1_toSRAM_7_wdata !== x1_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_wdata golden=%h impl=%h", cyc, g1_toSRAM_7_wdata, x1_toSRAM_7_wdata); end
    if (g1_toSRAM_7_wmask !== x1_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_wmask golden=%h impl=%h", cyc, g1_toSRAM_7_wmask, x1_toSRAM_7_wmask); end
    if (g1_toSRAM_7_re !== x1_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_re golden=%h impl=%h", cyc, g1_toSRAM_7_re, x1_toSRAM_7_re); end
    if (g1_toSRAM_7_we !== x1_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_we golden=%h impl=%h", cyc, g1_toSRAM_7_we, x1_toSRAM_7_we); end
    if (g1_toSRAM_7_ack !== x1_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_ack golden=%h impl=%h", cyc, g1_toSRAM_7_ack, x1_toSRAM_7_ack); end
    if (g1_toSRAM_7_selectedOH !== x1_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g1_toSRAM_7_selectedOH, x1_toSRAM_7_selectedOH); end
    if (g1_toSRAM_7_array !== x1_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeDcacheTag.toSRAM_7_array golden=%h impl=%h", cyc, g1_toSRAM_7_array, x1_toSRAM_7_array); end
  endtask

  // ======================== [02] MbistPipeFrontend ========================
  logic [73:0] v2_rd0;
  logic v2_ack0;
  logic [65:0] v2_rd1;
  logic v2_ack1;
  logic [65:0] v2_rd2;
  logic v2_ack2;
  logic [65:0] v2_rd3;
  logic v2_ack3;
  logic [65:0] v2_rd4;
  logic v2_ack4;
  logic [39:0] v2_rd5;
  logic v2_ack5;
  logic [23:0] v2_rd6;
  logic v2_ack6;
  logic [23:0] v2_rd7;
  logic v2_ack7;
  logic [23:0] v2_rd8;
  logic v2_ack8;
  logic [23:0] v2_rd9;
  logic v2_ack9;
  logic [23:0] v2_rd10;
  logic v2_ack10;
  logic [75:0] v2_rd11;
  logic v2_ack11;
  logic [75:0] v2_rd12;
  logic v2_ack12;
  logic [75:0] v2_rd13;
  logic v2_ack13;
  logic [75:0] v2_rd14;
  logic v2_ack14;
  logic [75:0] v2_rd15;
  logic v2_ack15;
  logic g2_mbist_ack;
  logic [75:0] g2_mbist_outdata;
  logic [1:0] g2_toNextPipeline_0_array;
  logic g2_toNextPipeline_0_all;
  logic g2_toNextPipeline_0_req;
  logic g2_toNextPipeline_0_writeen;
  logic [1:0] g2_toNextPipeline_0_be;
  logic [7:0] g2_toNextPipeline_0_addr;
  logic [73:0] g2_toNextPipeline_0_indata;
  logic g2_toNextPipeline_0_readen;
  logic [7:0] g2_toNextPipeline_0_addr_rd;
  logic [3:0] g2_toNextPipeline_1_array;
  logic g2_toNextPipeline_1_all;
  logic g2_toNextPipeline_1_req;
  logic g2_toNextPipeline_1_writeen;
  logic g2_toNextPipeline_1_be;
  logic [8:0] g2_toNextPipeline_1_addr;
  logic [65:0] g2_toNextPipeline_1_indata;
  logic g2_toNextPipeline_1_readen;
  logic [8:0] g2_toNextPipeline_1_addr_rd;
  logic [4:0] g2_toNextPipeline_2_array;
  logic g2_toNextPipeline_2_all;
  logic g2_toNextPipeline_2_req;
  logic g2_toNextPipeline_2_writeen;
  logic g2_toNextPipeline_2_be;
  logic [8:0] g2_toNextPipeline_2_addr;
  logic [65:0] g2_toNextPipeline_2_indata;
  logic g2_toNextPipeline_2_readen;
  logic [8:0] g2_toNextPipeline_2_addr_rd;
  logic [4:0] g2_toNextPipeline_3_array;
  logic g2_toNextPipeline_3_all;
  logic g2_toNextPipeline_3_req;
  logic g2_toNextPipeline_3_writeen;
  logic g2_toNextPipeline_3_be;
  logic [8:0] g2_toNextPipeline_3_addr;
  logic [65:0] g2_toNextPipeline_3_indata;
  logic g2_toNextPipeline_3_readen;
  logic [8:0] g2_toNextPipeline_3_addr_rd;
  logic [5:0] g2_toNextPipeline_4_array;
  logic g2_toNextPipeline_4_all;
  logic g2_toNextPipeline_4_req;
  logic g2_toNextPipeline_4_writeen;
  logic g2_toNextPipeline_4_be;
  logic [8:0] g2_toNextPipeline_4_addr;
  logic [65:0] g2_toNextPipeline_4_indata;
  logic g2_toNextPipeline_4_readen;
  logic [8:0] g2_toNextPipeline_4_addr_rd;
  logic [5:0] g2_toNextPipeline_5_array;
  logic g2_toNextPipeline_5_all;
  logic g2_toNextPipeline_5_req;
  logic g2_toNextPipeline_5_writeen;
  logic [3:0] g2_toNextPipeline_5_be;
  logic [9:0] g2_toNextPipeline_5_addr;
  logic [39:0] g2_toNextPipeline_5_indata;
  logic g2_toNextPipeline_5_readen;
  logic [9:0] g2_toNextPipeline_5_addr_rd;
  logic [6:0] g2_toNextPipeline_6_array;
  logic g2_toNextPipeline_6_all;
  logic g2_toNextPipeline_6_req;
  logic g2_toNextPipeline_6_writeen;
  logic [15:0] g2_toNextPipeline_6_be;
  logic [9:0] g2_toNextPipeline_6_addr;
  logic [23:0] g2_toNextPipeline_6_indata;
  logic g2_toNextPipeline_6_readen;
  logic [9:0] g2_toNextPipeline_6_addr_rd;
  logic [6:0] g2_toNextPipeline_7_array;
  logic g2_toNextPipeline_7_all;
  logic g2_toNextPipeline_7_req;
  logic g2_toNextPipeline_7_writeen;
  logic [3:0] g2_toNextPipeline_7_be;
  logic [7:0] g2_toNextPipeline_7_addr;
  logic [23:0] g2_toNextPipeline_7_indata;
  logic g2_toNextPipeline_7_readen;
  logic [7:0] g2_toNextPipeline_7_addr_rd;
  logic [6:0] g2_toNextPipeline_8_array;
  logic g2_toNextPipeline_8_all;
  logic g2_toNextPipeline_8_req;
  logic g2_toNextPipeline_8_writeen;
  logic [3:0] g2_toNextPipeline_8_be;
  logic [7:0] g2_toNextPipeline_8_addr;
  logic [23:0] g2_toNextPipeline_8_indata;
  logic g2_toNextPipeline_8_readen;
  logic [7:0] g2_toNextPipeline_8_addr_rd;
  logic [6:0] g2_toNextPipeline_9_array;
  logic g2_toNextPipeline_9_all;
  logic g2_toNextPipeline_9_req;
  logic g2_toNextPipeline_9_writeen;
  logic [3:0] g2_toNextPipeline_9_be;
  logic [7:0] g2_toNextPipeline_9_addr;
  logic [23:0] g2_toNextPipeline_9_indata;
  logic g2_toNextPipeline_9_readen;
  logic [7:0] g2_toNextPipeline_9_addr_rd;
  logic [6:0] g2_toNextPipeline_10_array;
  logic g2_toNextPipeline_10_all;
  logic g2_toNextPipeline_10_req;
  logic g2_toNextPipeline_10_writeen;
  logic [3:0] g2_toNextPipeline_10_be;
  logic [7:0] g2_toNextPipeline_10_addr;
  logic [23:0] g2_toNextPipeline_10_indata;
  logic g2_toNextPipeline_10_readen;
  logic [7:0] g2_toNextPipeline_10_addr_rd;
  logic [6:0] g2_toNextPipeline_11_array;
  logic g2_toNextPipeline_11_all;
  logic g2_toNextPipeline_11_req;
  logic g2_toNextPipeline_11_writeen;
  logic [75:0] g2_toNextPipeline_11_be;
  logic [7:0] g2_toNextPipeline_11_addr;
  logic [75:0] g2_toNextPipeline_11_indata;
  logic g2_toNextPipeline_11_readen;
  logic [7:0] g2_toNextPipeline_11_addr_rd;
  logic [6:0] g2_toNextPipeline_12_array;
  logic g2_toNextPipeline_12_all;
  logic g2_toNextPipeline_12_req;
  logic g2_toNextPipeline_12_writeen;
  logic [75:0] g2_toNextPipeline_12_be;
  logic [7:0] g2_toNextPipeline_12_addr;
  logic [75:0] g2_toNextPipeline_12_indata;
  logic g2_toNextPipeline_12_readen;
  logic [7:0] g2_toNextPipeline_12_addr_rd;
  logic [6:0] g2_toNextPipeline_13_array;
  logic g2_toNextPipeline_13_all;
  logic g2_toNextPipeline_13_req;
  logic g2_toNextPipeline_13_writeen;
  logic [75:0] g2_toNextPipeline_13_be;
  logic [7:0] g2_toNextPipeline_13_addr;
  logic [75:0] g2_toNextPipeline_13_indata;
  logic g2_toNextPipeline_13_readen;
  logic [7:0] g2_toNextPipeline_13_addr_rd;
  logic [6:0] g2_toNextPipeline_14_array;
  logic g2_toNextPipeline_14_all;
  logic g2_toNextPipeline_14_req;
  logic g2_toNextPipeline_14_writeen;
  logic [75:0] g2_toNextPipeline_14_be;
  logic [7:0] g2_toNextPipeline_14_addr;
  logic [75:0] g2_toNextPipeline_14_indata;
  logic g2_toNextPipeline_14_readen;
  logic [7:0] g2_toNextPipeline_14_addr_rd;
  logic [6:0] g2_toNextPipeline_15_array;
  logic g2_toNextPipeline_15_all;
  logic g2_toNextPipeline_15_req;
  logic g2_toNextPipeline_15_writeen;
  logic [75:0] g2_toNextPipeline_15_be;
  logic [7:0] g2_toNextPipeline_15_addr;
  logic [75:0] g2_toNextPipeline_15_indata;
  logic g2_toNextPipeline_15_readen;
  logic [7:0] g2_toNextPipeline_15_addr_rd;
  logic x2_mbist_ack;
  logic [75:0] x2_mbist_outdata;
  logic [1:0] x2_toNextPipeline_0_array;
  logic x2_toNextPipeline_0_all;
  logic x2_toNextPipeline_0_req;
  logic x2_toNextPipeline_0_writeen;
  logic [1:0] x2_toNextPipeline_0_be;
  logic [7:0] x2_toNextPipeline_0_addr;
  logic [73:0] x2_toNextPipeline_0_indata;
  logic x2_toNextPipeline_0_readen;
  logic [7:0] x2_toNextPipeline_0_addr_rd;
  logic [3:0] x2_toNextPipeline_1_array;
  logic x2_toNextPipeline_1_all;
  logic x2_toNextPipeline_1_req;
  logic x2_toNextPipeline_1_writeen;
  logic x2_toNextPipeline_1_be;
  logic [8:0] x2_toNextPipeline_1_addr;
  logic [65:0] x2_toNextPipeline_1_indata;
  logic x2_toNextPipeline_1_readen;
  logic [8:0] x2_toNextPipeline_1_addr_rd;
  logic [4:0] x2_toNextPipeline_2_array;
  logic x2_toNextPipeline_2_all;
  logic x2_toNextPipeline_2_req;
  logic x2_toNextPipeline_2_writeen;
  logic x2_toNextPipeline_2_be;
  logic [8:0] x2_toNextPipeline_2_addr;
  logic [65:0] x2_toNextPipeline_2_indata;
  logic x2_toNextPipeline_2_readen;
  logic [8:0] x2_toNextPipeline_2_addr_rd;
  logic [4:0] x2_toNextPipeline_3_array;
  logic x2_toNextPipeline_3_all;
  logic x2_toNextPipeline_3_req;
  logic x2_toNextPipeline_3_writeen;
  logic x2_toNextPipeline_3_be;
  logic [8:0] x2_toNextPipeline_3_addr;
  logic [65:0] x2_toNextPipeline_3_indata;
  logic x2_toNextPipeline_3_readen;
  logic [8:0] x2_toNextPipeline_3_addr_rd;
  logic [5:0] x2_toNextPipeline_4_array;
  logic x2_toNextPipeline_4_all;
  logic x2_toNextPipeline_4_req;
  logic x2_toNextPipeline_4_writeen;
  logic x2_toNextPipeline_4_be;
  logic [8:0] x2_toNextPipeline_4_addr;
  logic [65:0] x2_toNextPipeline_4_indata;
  logic x2_toNextPipeline_4_readen;
  logic [8:0] x2_toNextPipeline_4_addr_rd;
  logic [5:0] x2_toNextPipeline_5_array;
  logic x2_toNextPipeline_5_all;
  logic x2_toNextPipeline_5_req;
  logic x2_toNextPipeline_5_writeen;
  logic [3:0] x2_toNextPipeline_5_be;
  logic [9:0] x2_toNextPipeline_5_addr;
  logic [39:0] x2_toNextPipeline_5_indata;
  logic x2_toNextPipeline_5_readen;
  logic [9:0] x2_toNextPipeline_5_addr_rd;
  logic [6:0] x2_toNextPipeline_6_array;
  logic x2_toNextPipeline_6_all;
  logic x2_toNextPipeline_6_req;
  logic x2_toNextPipeline_6_writeen;
  logic [15:0] x2_toNextPipeline_6_be;
  logic [9:0] x2_toNextPipeline_6_addr;
  logic [23:0] x2_toNextPipeline_6_indata;
  logic x2_toNextPipeline_6_readen;
  logic [9:0] x2_toNextPipeline_6_addr_rd;
  logic [6:0] x2_toNextPipeline_7_array;
  logic x2_toNextPipeline_7_all;
  logic x2_toNextPipeline_7_req;
  logic x2_toNextPipeline_7_writeen;
  logic [3:0] x2_toNextPipeline_7_be;
  logic [7:0] x2_toNextPipeline_7_addr;
  logic [23:0] x2_toNextPipeline_7_indata;
  logic x2_toNextPipeline_7_readen;
  logic [7:0] x2_toNextPipeline_7_addr_rd;
  logic [6:0] x2_toNextPipeline_8_array;
  logic x2_toNextPipeline_8_all;
  logic x2_toNextPipeline_8_req;
  logic x2_toNextPipeline_8_writeen;
  logic [3:0] x2_toNextPipeline_8_be;
  logic [7:0] x2_toNextPipeline_8_addr;
  logic [23:0] x2_toNextPipeline_8_indata;
  logic x2_toNextPipeline_8_readen;
  logic [7:0] x2_toNextPipeline_8_addr_rd;
  logic [6:0] x2_toNextPipeline_9_array;
  logic x2_toNextPipeline_9_all;
  logic x2_toNextPipeline_9_req;
  logic x2_toNextPipeline_9_writeen;
  logic [3:0] x2_toNextPipeline_9_be;
  logic [7:0] x2_toNextPipeline_9_addr;
  logic [23:0] x2_toNextPipeline_9_indata;
  logic x2_toNextPipeline_9_readen;
  logic [7:0] x2_toNextPipeline_9_addr_rd;
  logic [6:0] x2_toNextPipeline_10_array;
  logic x2_toNextPipeline_10_all;
  logic x2_toNextPipeline_10_req;
  logic x2_toNextPipeline_10_writeen;
  logic [3:0] x2_toNextPipeline_10_be;
  logic [7:0] x2_toNextPipeline_10_addr;
  logic [23:0] x2_toNextPipeline_10_indata;
  logic x2_toNextPipeline_10_readen;
  logic [7:0] x2_toNextPipeline_10_addr_rd;
  logic [6:0] x2_toNextPipeline_11_array;
  logic x2_toNextPipeline_11_all;
  logic x2_toNextPipeline_11_req;
  logic x2_toNextPipeline_11_writeen;
  logic [75:0] x2_toNextPipeline_11_be;
  logic [7:0] x2_toNextPipeline_11_addr;
  logic [75:0] x2_toNextPipeline_11_indata;
  logic x2_toNextPipeline_11_readen;
  logic [7:0] x2_toNextPipeline_11_addr_rd;
  logic [6:0] x2_toNextPipeline_12_array;
  logic x2_toNextPipeline_12_all;
  logic x2_toNextPipeline_12_req;
  logic x2_toNextPipeline_12_writeen;
  logic [75:0] x2_toNextPipeline_12_be;
  logic [7:0] x2_toNextPipeline_12_addr;
  logic [75:0] x2_toNextPipeline_12_indata;
  logic x2_toNextPipeline_12_readen;
  logic [7:0] x2_toNextPipeline_12_addr_rd;
  logic [6:0] x2_toNextPipeline_13_array;
  logic x2_toNextPipeline_13_all;
  logic x2_toNextPipeline_13_req;
  logic x2_toNextPipeline_13_writeen;
  logic [75:0] x2_toNextPipeline_13_be;
  logic [7:0] x2_toNextPipeline_13_addr;
  logic [75:0] x2_toNextPipeline_13_indata;
  logic x2_toNextPipeline_13_readen;
  logic [7:0] x2_toNextPipeline_13_addr_rd;
  logic [6:0] x2_toNextPipeline_14_array;
  logic x2_toNextPipeline_14_all;
  logic x2_toNextPipeline_14_req;
  logic x2_toNextPipeline_14_writeen;
  logic [75:0] x2_toNextPipeline_14_be;
  logic [7:0] x2_toNextPipeline_14_addr;
  logic [75:0] x2_toNextPipeline_14_indata;
  logic x2_toNextPipeline_14_readen;
  logic [7:0] x2_toNextPipeline_14_addr_rd;
  logic [6:0] x2_toNextPipeline_15_array;
  logic x2_toNextPipeline_15_all;
  logic x2_toNextPipeline_15_req;
  logic x2_toNextPipeline_15_writeen;
  logic [75:0] x2_toNextPipeline_15_be;
  logic [7:0] x2_toNextPipeline_15_addr;
  logic [75:0] x2_toNextPipeline_15_indata;
  logic x2_toNextPipeline_15_readen;
  logic [7:0] x2_toNextPipeline_15_addr_rd;
  bit [15:0] cov_spread2;
  bit [75:0] cov_od0_2, cov_od1_2;
  bit cov_ack0_2, cov_ack1_2;
  MbistPipeFrontend u_g2 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd),
    .toNextPipeline_0_ack (v2_ack0),
    .toNextPipeline_0_outdata (v2_rd0),
    .toNextPipeline_1_ack (v2_ack1),
    .toNextPipeline_1_outdata (v2_rd1),
    .toNextPipeline_2_ack (v2_ack2),
    .toNextPipeline_2_outdata (v2_rd2),
    .toNextPipeline_3_ack (v2_ack3),
    .toNextPipeline_3_outdata (v2_rd3),
    .toNextPipeline_4_ack (v2_ack4),
    .toNextPipeline_4_outdata (v2_rd4),
    .toNextPipeline_5_ack (v2_ack5),
    .toNextPipeline_5_outdata (v2_rd5),
    .toNextPipeline_6_ack (v2_ack6),
    .toNextPipeline_6_outdata (v2_rd6),
    .toNextPipeline_7_ack (v2_ack7),
    .toNextPipeline_7_outdata (v2_rd7),
    .toNextPipeline_8_ack (v2_ack8),
    .toNextPipeline_8_outdata (v2_rd8),
    .toNextPipeline_9_ack (v2_ack9),
    .toNextPipeline_9_outdata (v2_rd9),
    .toNextPipeline_10_ack (v2_ack10),
    .toNextPipeline_10_outdata (v2_rd10),
    .toNextPipeline_11_ack (v2_ack11),
    .toNextPipeline_11_outdata (v2_rd11),
    .toNextPipeline_12_ack (v2_ack12),
    .toNextPipeline_12_outdata (v2_rd12),
    .toNextPipeline_13_ack (v2_ack13),
    .toNextPipeline_13_outdata (v2_rd13),
    .toNextPipeline_14_ack (v2_ack14),
    .toNextPipeline_14_outdata (v2_rd14),
    .toNextPipeline_15_ack (v2_ack15),
    .toNextPipeline_15_outdata (v2_rd15),
    .mbist_ack (g2_mbist_ack),
    .mbist_outdata (g2_mbist_outdata),
    .toNextPipeline_0_array (g2_toNextPipeline_0_array),
    .toNextPipeline_0_all (g2_toNextPipeline_0_all),
    .toNextPipeline_0_req (g2_toNextPipeline_0_req),
    .toNextPipeline_0_writeen (g2_toNextPipeline_0_writeen),
    .toNextPipeline_0_be (g2_toNextPipeline_0_be),
    .toNextPipeline_0_addr (g2_toNextPipeline_0_addr),
    .toNextPipeline_0_indata (g2_toNextPipeline_0_indata),
    .toNextPipeline_0_readen (g2_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (g2_toNextPipeline_0_addr_rd),
    .toNextPipeline_1_array (g2_toNextPipeline_1_array),
    .toNextPipeline_1_all (g2_toNextPipeline_1_all),
    .toNextPipeline_1_req (g2_toNextPipeline_1_req),
    .toNextPipeline_1_writeen (g2_toNextPipeline_1_writeen),
    .toNextPipeline_1_be (g2_toNextPipeline_1_be),
    .toNextPipeline_1_addr (g2_toNextPipeline_1_addr),
    .toNextPipeline_1_indata (g2_toNextPipeline_1_indata),
    .toNextPipeline_1_readen (g2_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (g2_toNextPipeline_1_addr_rd),
    .toNextPipeline_2_array (g2_toNextPipeline_2_array),
    .toNextPipeline_2_all (g2_toNextPipeline_2_all),
    .toNextPipeline_2_req (g2_toNextPipeline_2_req),
    .toNextPipeline_2_writeen (g2_toNextPipeline_2_writeen),
    .toNextPipeline_2_be (g2_toNextPipeline_2_be),
    .toNextPipeline_2_addr (g2_toNextPipeline_2_addr),
    .toNextPipeline_2_indata (g2_toNextPipeline_2_indata),
    .toNextPipeline_2_readen (g2_toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd (g2_toNextPipeline_2_addr_rd),
    .toNextPipeline_3_array (g2_toNextPipeline_3_array),
    .toNextPipeline_3_all (g2_toNextPipeline_3_all),
    .toNextPipeline_3_req (g2_toNextPipeline_3_req),
    .toNextPipeline_3_writeen (g2_toNextPipeline_3_writeen),
    .toNextPipeline_3_be (g2_toNextPipeline_3_be),
    .toNextPipeline_3_addr (g2_toNextPipeline_3_addr),
    .toNextPipeline_3_indata (g2_toNextPipeline_3_indata),
    .toNextPipeline_3_readen (g2_toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd (g2_toNextPipeline_3_addr_rd),
    .toNextPipeline_4_array (g2_toNextPipeline_4_array),
    .toNextPipeline_4_all (g2_toNextPipeline_4_all),
    .toNextPipeline_4_req (g2_toNextPipeline_4_req),
    .toNextPipeline_4_writeen (g2_toNextPipeline_4_writeen),
    .toNextPipeline_4_be (g2_toNextPipeline_4_be),
    .toNextPipeline_4_addr (g2_toNextPipeline_4_addr),
    .toNextPipeline_4_indata (g2_toNextPipeline_4_indata),
    .toNextPipeline_4_readen (g2_toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd (g2_toNextPipeline_4_addr_rd),
    .toNextPipeline_5_array (g2_toNextPipeline_5_array),
    .toNextPipeline_5_all (g2_toNextPipeline_5_all),
    .toNextPipeline_5_req (g2_toNextPipeline_5_req),
    .toNextPipeline_5_writeen (g2_toNextPipeline_5_writeen),
    .toNextPipeline_5_be (g2_toNextPipeline_5_be),
    .toNextPipeline_5_addr (g2_toNextPipeline_5_addr),
    .toNextPipeline_5_indata (g2_toNextPipeline_5_indata),
    .toNextPipeline_5_readen (g2_toNextPipeline_5_readen),
    .toNextPipeline_5_addr_rd (g2_toNextPipeline_5_addr_rd),
    .toNextPipeline_6_array (g2_toNextPipeline_6_array),
    .toNextPipeline_6_all (g2_toNextPipeline_6_all),
    .toNextPipeline_6_req (g2_toNextPipeline_6_req),
    .toNextPipeline_6_writeen (g2_toNextPipeline_6_writeen),
    .toNextPipeline_6_be (g2_toNextPipeline_6_be),
    .toNextPipeline_6_addr (g2_toNextPipeline_6_addr),
    .toNextPipeline_6_indata (g2_toNextPipeline_6_indata),
    .toNextPipeline_6_readen (g2_toNextPipeline_6_readen),
    .toNextPipeline_6_addr_rd (g2_toNextPipeline_6_addr_rd),
    .toNextPipeline_7_array (g2_toNextPipeline_7_array),
    .toNextPipeline_7_all (g2_toNextPipeline_7_all),
    .toNextPipeline_7_req (g2_toNextPipeline_7_req),
    .toNextPipeline_7_writeen (g2_toNextPipeline_7_writeen),
    .toNextPipeline_7_be (g2_toNextPipeline_7_be),
    .toNextPipeline_7_addr (g2_toNextPipeline_7_addr),
    .toNextPipeline_7_indata (g2_toNextPipeline_7_indata),
    .toNextPipeline_7_readen (g2_toNextPipeline_7_readen),
    .toNextPipeline_7_addr_rd (g2_toNextPipeline_7_addr_rd),
    .toNextPipeline_8_array (g2_toNextPipeline_8_array),
    .toNextPipeline_8_all (g2_toNextPipeline_8_all),
    .toNextPipeline_8_req (g2_toNextPipeline_8_req),
    .toNextPipeline_8_writeen (g2_toNextPipeline_8_writeen),
    .toNextPipeline_8_be (g2_toNextPipeline_8_be),
    .toNextPipeline_8_addr (g2_toNextPipeline_8_addr),
    .toNextPipeline_8_indata (g2_toNextPipeline_8_indata),
    .toNextPipeline_8_readen (g2_toNextPipeline_8_readen),
    .toNextPipeline_8_addr_rd (g2_toNextPipeline_8_addr_rd),
    .toNextPipeline_9_array (g2_toNextPipeline_9_array),
    .toNextPipeline_9_all (g2_toNextPipeline_9_all),
    .toNextPipeline_9_req (g2_toNextPipeline_9_req),
    .toNextPipeline_9_writeen (g2_toNextPipeline_9_writeen),
    .toNextPipeline_9_be (g2_toNextPipeline_9_be),
    .toNextPipeline_9_addr (g2_toNextPipeline_9_addr),
    .toNextPipeline_9_indata (g2_toNextPipeline_9_indata),
    .toNextPipeline_9_readen (g2_toNextPipeline_9_readen),
    .toNextPipeline_9_addr_rd (g2_toNextPipeline_9_addr_rd),
    .toNextPipeline_10_array (g2_toNextPipeline_10_array),
    .toNextPipeline_10_all (g2_toNextPipeline_10_all),
    .toNextPipeline_10_req (g2_toNextPipeline_10_req),
    .toNextPipeline_10_writeen (g2_toNextPipeline_10_writeen),
    .toNextPipeline_10_be (g2_toNextPipeline_10_be),
    .toNextPipeline_10_addr (g2_toNextPipeline_10_addr),
    .toNextPipeline_10_indata (g2_toNextPipeline_10_indata),
    .toNextPipeline_10_readen (g2_toNextPipeline_10_readen),
    .toNextPipeline_10_addr_rd (g2_toNextPipeline_10_addr_rd),
    .toNextPipeline_11_array (g2_toNextPipeline_11_array),
    .toNextPipeline_11_all (g2_toNextPipeline_11_all),
    .toNextPipeline_11_req (g2_toNextPipeline_11_req),
    .toNextPipeline_11_writeen (g2_toNextPipeline_11_writeen),
    .toNextPipeline_11_be (g2_toNextPipeline_11_be),
    .toNextPipeline_11_addr (g2_toNextPipeline_11_addr),
    .toNextPipeline_11_indata (g2_toNextPipeline_11_indata),
    .toNextPipeline_11_readen (g2_toNextPipeline_11_readen),
    .toNextPipeline_11_addr_rd (g2_toNextPipeline_11_addr_rd),
    .toNextPipeline_12_array (g2_toNextPipeline_12_array),
    .toNextPipeline_12_all (g2_toNextPipeline_12_all),
    .toNextPipeline_12_req (g2_toNextPipeline_12_req),
    .toNextPipeline_12_writeen (g2_toNextPipeline_12_writeen),
    .toNextPipeline_12_be (g2_toNextPipeline_12_be),
    .toNextPipeline_12_addr (g2_toNextPipeline_12_addr),
    .toNextPipeline_12_indata (g2_toNextPipeline_12_indata),
    .toNextPipeline_12_readen (g2_toNextPipeline_12_readen),
    .toNextPipeline_12_addr_rd (g2_toNextPipeline_12_addr_rd),
    .toNextPipeline_13_array (g2_toNextPipeline_13_array),
    .toNextPipeline_13_all (g2_toNextPipeline_13_all),
    .toNextPipeline_13_req (g2_toNextPipeline_13_req),
    .toNextPipeline_13_writeen (g2_toNextPipeline_13_writeen),
    .toNextPipeline_13_be (g2_toNextPipeline_13_be),
    .toNextPipeline_13_addr (g2_toNextPipeline_13_addr),
    .toNextPipeline_13_indata (g2_toNextPipeline_13_indata),
    .toNextPipeline_13_readen (g2_toNextPipeline_13_readen),
    .toNextPipeline_13_addr_rd (g2_toNextPipeline_13_addr_rd),
    .toNextPipeline_14_array (g2_toNextPipeline_14_array),
    .toNextPipeline_14_all (g2_toNextPipeline_14_all),
    .toNextPipeline_14_req (g2_toNextPipeline_14_req),
    .toNextPipeline_14_writeen (g2_toNextPipeline_14_writeen),
    .toNextPipeline_14_be (g2_toNextPipeline_14_be),
    .toNextPipeline_14_addr (g2_toNextPipeline_14_addr),
    .toNextPipeline_14_indata (g2_toNextPipeline_14_indata),
    .toNextPipeline_14_readen (g2_toNextPipeline_14_readen),
    .toNextPipeline_14_addr_rd (g2_toNextPipeline_14_addr_rd),
    .toNextPipeline_15_array (g2_toNextPipeline_15_array),
    .toNextPipeline_15_all (g2_toNextPipeline_15_all),
    .toNextPipeline_15_req (g2_toNextPipeline_15_req),
    .toNextPipeline_15_writeen (g2_toNextPipeline_15_writeen),
    .toNextPipeline_15_be (g2_toNextPipeline_15_be),
    .toNextPipeline_15_addr (g2_toNextPipeline_15_addr),
    .toNextPipeline_15_indata (g2_toNextPipeline_15_indata),
    .toNextPipeline_15_readen (g2_toNextPipeline_15_readen),
    .toNextPipeline_15_addr_rd (g2_toNextPipeline_15_addr_rd)
  );
  MbistPipeFrontend_xs u_x2 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd),
    .toNextPipeline_0_ack (v2_ack0),
    .toNextPipeline_0_outdata (v2_rd0),
    .toNextPipeline_1_ack (v2_ack1),
    .toNextPipeline_1_outdata (v2_rd1),
    .toNextPipeline_2_ack (v2_ack2),
    .toNextPipeline_2_outdata (v2_rd2),
    .toNextPipeline_3_ack (v2_ack3),
    .toNextPipeline_3_outdata (v2_rd3),
    .toNextPipeline_4_ack (v2_ack4),
    .toNextPipeline_4_outdata (v2_rd4),
    .toNextPipeline_5_ack (v2_ack5),
    .toNextPipeline_5_outdata (v2_rd5),
    .toNextPipeline_6_ack (v2_ack6),
    .toNextPipeline_6_outdata (v2_rd6),
    .toNextPipeline_7_ack (v2_ack7),
    .toNextPipeline_7_outdata (v2_rd7),
    .toNextPipeline_8_ack (v2_ack8),
    .toNextPipeline_8_outdata (v2_rd8),
    .toNextPipeline_9_ack (v2_ack9),
    .toNextPipeline_9_outdata (v2_rd9),
    .toNextPipeline_10_ack (v2_ack10),
    .toNextPipeline_10_outdata (v2_rd10),
    .toNextPipeline_11_ack (v2_ack11),
    .toNextPipeline_11_outdata (v2_rd11),
    .toNextPipeline_12_ack (v2_ack12),
    .toNextPipeline_12_outdata (v2_rd12),
    .toNextPipeline_13_ack (v2_ack13),
    .toNextPipeline_13_outdata (v2_rd13),
    .toNextPipeline_14_ack (v2_ack14),
    .toNextPipeline_14_outdata (v2_rd14),
    .toNextPipeline_15_ack (v2_ack15),
    .toNextPipeline_15_outdata (v2_rd15),
    .mbist_ack (x2_mbist_ack),
    .mbist_outdata (x2_mbist_outdata),
    .toNextPipeline_0_array (x2_toNextPipeline_0_array),
    .toNextPipeline_0_all (x2_toNextPipeline_0_all),
    .toNextPipeline_0_req (x2_toNextPipeline_0_req),
    .toNextPipeline_0_writeen (x2_toNextPipeline_0_writeen),
    .toNextPipeline_0_be (x2_toNextPipeline_0_be),
    .toNextPipeline_0_addr (x2_toNextPipeline_0_addr),
    .toNextPipeline_0_indata (x2_toNextPipeline_0_indata),
    .toNextPipeline_0_readen (x2_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (x2_toNextPipeline_0_addr_rd),
    .toNextPipeline_1_array (x2_toNextPipeline_1_array),
    .toNextPipeline_1_all (x2_toNextPipeline_1_all),
    .toNextPipeline_1_req (x2_toNextPipeline_1_req),
    .toNextPipeline_1_writeen (x2_toNextPipeline_1_writeen),
    .toNextPipeline_1_be (x2_toNextPipeline_1_be),
    .toNextPipeline_1_addr (x2_toNextPipeline_1_addr),
    .toNextPipeline_1_indata (x2_toNextPipeline_1_indata),
    .toNextPipeline_1_readen (x2_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (x2_toNextPipeline_1_addr_rd),
    .toNextPipeline_2_array (x2_toNextPipeline_2_array),
    .toNextPipeline_2_all (x2_toNextPipeline_2_all),
    .toNextPipeline_2_req (x2_toNextPipeline_2_req),
    .toNextPipeline_2_writeen (x2_toNextPipeline_2_writeen),
    .toNextPipeline_2_be (x2_toNextPipeline_2_be),
    .toNextPipeline_2_addr (x2_toNextPipeline_2_addr),
    .toNextPipeline_2_indata (x2_toNextPipeline_2_indata),
    .toNextPipeline_2_readen (x2_toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd (x2_toNextPipeline_2_addr_rd),
    .toNextPipeline_3_array (x2_toNextPipeline_3_array),
    .toNextPipeline_3_all (x2_toNextPipeline_3_all),
    .toNextPipeline_3_req (x2_toNextPipeline_3_req),
    .toNextPipeline_3_writeen (x2_toNextPipeline_3_writeen),
    .toNextPipeline_3_be (x2_toNextPipeline_3_be),
    .toNextPipeline_3_addr (x2_toNextPipeline_3_addr),
    .toNextPipeline_3_indata (x2_toNextPipeline_3_indata),
    .toNextPipeline_3_readen (x2_toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd (x2_toNextPipeline_3_addr_rd),
    .toNextPipeline_4_array (x2_toNextPipeline_4_array),
    .toNextPipeline_4_all (x2_toNextPipeline_4_all),
    .toNextPipeline_4_req (x2_toNextPipeline_4_req),
    .toNextPipeline_4_writeen (x2_toNextPipeline_4_writeen),
    .toNextPipeline_4_be (x2_toNextPipeline_4_be),
    .toNextPipeline_4_addr (x2_toNextPipeline_4_addr),
    .toNextPipeline_4_indata (x2_toNextPipeline_4_indata),
    .toNextPipeline_4_readen (x2_toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd (x2_toNextPipeline_4_addr_rd),
    .toNextPipeline_5_array (x2_toNextPipeline_5_array),
    .toNextPipeline_5_all (x2_toNextPipeline_5_all),
    .toNextPipeline_5_req (x2_toNextPipeline_5_req),
    .toNextPipeline_5_writeen (x2_toNextPipeline_5_writeen),
    .toNextPipeline_5_be (x2_toNextPipeline_5_be),
    .toNextPipeline_5_addr (x2_toNextPipeline_5_addr),
    .toNextPipeline_5_indata (x2_toNextPipeline_5_indata),
    .toNextPipeline_5_readen (x2_toNextPipeline_5_readen),
    .toNextPipeline_5_addr_rd (x2_toNextPipeline_5_addr_rd),
    .toNextPipeline_6_array (x2_toNextPipeline_6_array),
    .toNextPipeline_6_all (x2_toNextPipeline_6_all),
    .toNextPipeline_6_req (x2_toNextPipeline_6_req),
    .toNextPipeline_6_writeen (x2_toNextPipeline_6_writeen),
    .toNextPipeline_6_be (x2_toNextPipeline_6_be),
    .toNextPipeline_6_addr (x2_toNextPipeline_6_addr),
    .toNextPipeline_6_indata (x2_toNextPipeline_6_indata),
    .toNextPipeline_6_readen (x2_toNextPipeline_6_readen),
    .toNextPipeline_6_addr_rd (x2_toNextPipeline_6_addr_rd),
    .toNextPipeline_7_array (x2_toNextPipeline_7_array),
    .toNextPipeline_7_all (x2_toNextPipeline_7_all),
    .toNextPipeline_7_req (x2_toNextPipeline_7_req),
    .toNextPipeline_7_writeen (x2_toNextPipeline_7_writeen),
    .toNextPipeline_7_be (x2_toNextPipeline_7_be),
    .toNextPipeline_7_addr (x2_toNextPipeline_7_addr),
    .toNextPipeline_7_indata (x2_toNextPipeline_7_indata),
    .toNextPipeline_7_readen (x2_toNextPipeline_7_readen),
    .toNextPipeline_7_addr_rd (x2_toNextPipeline_7_addr_rd),
    .toNextPipeline_8_array (x2_toNextPipeline_8_array),
    .toNextPipeline_8_all (x2_toNextPipeline_8_all),
    .toNextPipeline_8_req (x2_toNextPipeline_8_req),
    .toNextPipeline_8_writeen (x2_toNextPipeline_8_writeen),
    .toNextPipeline_8_be (x2_toNextPipeline_8_be),
    .toNextPipeline_8_addr (x2_toNextPipeline_8_addr),
    .toNextPipeline_8_indata (x2_toNextPipeline_8_indata),
    .toNextPipeline_8_readen (x2_toNextPipeline_8_readen),
    .toNextPipeline_8_addr_rd (x2_toNextPipeline_8_addr_rd),
    .toNextPipeline_9_array (x2_toNextPipeline_9_array),
    .toNextPipeline_9_all (x2_toNextPipeline_9_all),
    .toNextPipeline_9_req (x2_toNextPipeline_9_req),
    .toNextPipeline_9_writeen (x2_toNextPipeline_9_writeen),
    .toNextPipeline_9_be (x2_toNextPipeline_9_be),
    .toNextPipeline_9_addr (x2_toNextPipeline_9_addr),
    .toNextPipeline_9_indata (x2_toNextPipeline_9_indata),
    .toNextPipeline_9_readen (x2_toNextPipeline_9_readen),
    .toNextPipeline_9_addr_rd (x2_toNextPipeline_9_addr_rd),
    .toNextPipeline_10_array (x2_toNextPipeline_10_array),
    .toNextPipeline_10_all (x2_toNextPipeline_10_all),
    .toNextPipeline_10_req (x2_toNextPipeline_10_req),
    .toNextPipeline_10_writeen (x2_toNextPipeline_10_writeen),
    .toNextPipeline_10_be (x2_toNextPipeline_10_be),
    .toNextPipeline_10_addr (x2_toNextPipeline_10_addr),
    .toNextPipeline_10_indata (x2_toNextPipeline_10_indata),
    .toNextPipeline_10_readen (x2_toNextPipeline_10_readen),
    .toNextPipeline_10_addr_rd (x2_toNextPipeline_10_addr_rd),
    .toNextPipeline_11_array (x2_toNextPipeline_11_array),
    .toNextPipeline_11_all (x2_toNextPipeline_11_all),
    .toNextPipeline_11_req (x2_toNextPipeline_11_req),
    .toNextPipeline_11_writeen (x2_toNextPipeline_11_writeen),
    .toNextPipeline_11_be (x2_toNextPipeline_11_be),
    .toNextPipeline_11_addr (x2_toNextPipeline_11_addr),
    .toNextPipeline_11_indata (x2_toNextPipeline_11_indata),
    .toNextPipeline_11_readen (x2_toNextPipeline_11_readen),
    .toNextPipeline_11_addr_rd (x2_toNextPipeline_11_addr_rd),
    .toNextPipeline_12_array (x2_toNextPipeline_12_array),
    .toNextPipeline_12_all (x2_toNextPipeline_12_all),
    .toNextPipeline_12_req (x2_toNextPipeline_12_req),
    .toNextPipeline_12_writeen (x2_toNextPipeline_12_writeen),
    .toNextPipeline_12_be (x2_toNextPipeline_12_be),
    .toNextPipeline_12_addr (x2_toNextPipeline_12_addr),
    .toNextPipeline_12_indata (x2_toNextPipeline_12_indata),
    .toNextPipeline_12_readen (x2_toNextPipeline_12_readen),
    .toNextPipeline_12_addr_rd (x2_toNextPipeline_12_addr_rd),
    .toNextPipeline_13_array (x2_toNextPipeline_13_array),
    .toNextPipeline_13_all (x2_toNextPipeline_13_all),
    .toNextPipeline_13_req (x2_toNextPipeline_13_req),
    .toNextPipeline_13_writeen (x2_toNextPipeline_13_writeen),
    .toNextPipeline_13_be (x2_toNextPipeline_13_be),
    .toNextPipeline_13_addr (x2_toNextPipeline_13_addr),
    .toNextPipeline_13_indata (x2_toNextPipeline_13_indata),
    .toNextPipeline_13_readen (x2_toNextPipeline_13_readen),
    .toNextPipeline_13_addr_rd (x2_toNextPipeline_13_addr_rd),
    .toNextPipeline_14_array (x2_toNextPipeline_14_array),
    .toNextPipeline_14_all (x2_toNextPipeline_14_all),
    .toNextPipeline_14_req (x2_toNextPipeline_14_req),
    .toNextPipeline_14_writeen (x2_toNextPipeline_14_writeen),
    .toNextPipeline_14_be (x2_toNextPipeline_14_be),
    .toNextPipeline_14_addr (x2_toNextPipeline_14_addr),
    .toNextPipeline_14_indata (x2_toNextPipeline_14_indata),
    .toNextPipeline_14_readen (x2_toNextPipeline_14_readen),
    .toNextPipeline_14_addr_rd (x2_toNextPipeline_14_addr_rd),
    .toNextPipeline_15_array (x2_toNextPipeline_15_array),
    .toNextPipeline_15_all (x2_toNextPipeline_15_all),
    .toNextPipeline_15_req (x2_toNextPipeline_15_req),
    .toNextPipeline_15_writeen (x2_toNextPipeline_15_writeen),
    .toNextPipeline_15_be (x2_toNextPipeline_15_be),
    .toNextPipeline_15_addr (x2_toNextPipeline_15_addr),
    .toNextPipeline_15_indata (x2_toNextPipeline_15_indata),
    .toNextPipeline_15_readen (x2_toNextPipeline_15_readen),
    .toNextPipeline_15_addr_rd (x2_toNextPipeline_15_addr_rd)
  );
  wire [1810:0] gbus2 = {g2_mbist_ack, g2_mbist_outdata, g2_toNextPipeline_0_array, g2_toNextPipeline_0_all, g2_toNextPipeline_0_req, g2_toNextPipeline_0_writeen, g2_toNextPipeline_0_be, g2_toNextPipeline_0_addr, g2_toNextPipeline_0_indata, g2_toNextPipeline_0_readen, g2_toNextPipeline_0_addr_rd, g2_toNextPipeline_1_array, g2_toNextPipeline_1_all, g2_toNextPipeline_1_req, g2_toNextPipeline_1_writeen, g2_toNextPipeline_1_be, g2_toNextPipeline_1_addr, g2_toNextPipeline_1_indata, g2_toNextPipeline_1_readen, g2_toNextPipeline_1_addr_rd, g2_toNextPipeline_2_array, g2_toNextPipeline_2_all, g2_toNextPipeline_2_req, g2_toNextPipeline_2_writeen, g2_toNextPipeline_2_be, g2_toNextPipeline_2_addr, g2_toNextPipeline_2_indata, g2_toNextPipeline_2_readen, g2_toNextPipeline_2_addr_rd, g2_toNextPipeline_3_array, g2_toNextPipeline_3_all, g2_toNextPipeline_3_req, g2_toNextPipeline_3_writeen, g2_toNextPipeline_3_be, g2_toNextPipeline_3_addr, g2_toNextPipeline_3_indata, g2_toNextPipeline_3_readen, g2_toNextPipeline_3_addr_rd, g2_toNextPipeline_4_array, g2_toNextPipeline_4_all, g2_toNextPipeline_4_req, g2_toNextPipeline_4_writeen, g2_toNextPipeline_4_be, g2_toNextPipeline_4_addr, g2_toNextPipeline_4_indata, g2_toNextPipeline_4_readen, g2_toNextPipeline_4_addr_rd, g2_toNextPipeline_5_array, g2_toNextPipeline_5_all, g2_toNextPipeline_5_req, g2_toNextPipeline_5_writeen, g2_toNextPipeline_5_be, g2_toNextPipeline_5_addr, g2_toNextPipeline_5_indata, g2_toNextPipeline_5_readen, g2_toNextPipeline_5_addr_rd, g2_toNextPipeline_6_array, g2_toNextPipeline_6_all, g2_toNextPipeline_6_req, g2_toNextPipeline_6_writeen, g2_toNextPipeline_6_be, g2_toNextPipeline_6_addr, g2_toNextPipeline_6_indata, g2_toNextPipeline_6_readen, g2_toNextPipeline_6_addr_rd, g2_toNextPipeline_7_array, g2_toNextPipeline_7_all, g2_toNextPipeline_7_req, g2_toNextPipeline_7_writeen, g2_toNextPipeline_7_be, g2_toNextPipeline_7_addr, g2_toNextPipeline_7_indata, g2_toNextPipeline_7_readen, g2_toNextPipeline_7_addr_rd, g2_toNextPipeline_8_array, g2_toNextPipeline_8_all, g2_toNextPipeline_8_req, g2_toNextPipeline_8_writeen, g2_toNextPipeline_8_be, g2_toNextPipeline_8_addr, g2_toNextPipeline_8_indata, g2_toNextPipeline_8_readen, g2_toNextPipeline_8_addr_rd, g2_toNextPipeline_9_array, g2_toNextPipeline_9_all, g2_toNextPipeline_9_req, g2_toNextPipeline_9_writeen, g2_toNextPipeline_9_be, g2_toNextPipeline_9_addr, g2_toNextPipeline_9_indata, g2_toNextPipeline_9_readen, g2_toNextPipeline_9_addr_rd, g2_toNextPipeline_10_array, g2_toNextPipeline_10_all, g2_toNextPipeline_10_req, g2_toNextPipeline_10_writeen, g2_toNextPipeline_10_be, g2_toNextPipeline_10_addr, g2_toNextPipeline_10_indata, g2_toNextPipeline_10_readen, g2_toNextPipeline_10_addr_rd, g2_toNextPipeline_11_array, g2_toNextPipeline_11_all, g2_toNextPipeline_11_req, g2_toNextPipeline_11_writeen, g2_toNextPipeline_11_be, g2_toNextPipeline_11_addr, g2_toNextPipeline_11_indata, g2_toNextPipeline_11_readen, g2_toNextPipeline_11_addr_rd, g2_toNextPipeline_12_array, g2_toNextPipeline_12_all, g2_toNextPipeline_12_req, g2_toNextPipeline_12_writeen, g2_toNextPipeline_12_be, g2_toNextPipeline_12_addr, g2_toNextPipeline_12_indata, g2_toNextPipeline_12_readen, g2_toNextPipeline_12_addr_rd, g2_toNextPipeline_13_array, g2_toNextPipeline_13_all, g2_toNextPipeline_13_req, g2_toNextPipeline_13_writeen, g2_toNextPipeline_13_be, g2_toNextPipeline_13_addr, g2_toNextPipeline_13_indata, g2_toNextPipeline_13_readen, g2_toNextPipeline_13_addr_rd, g2_toNextPipeline_14_array, g2_toNextPipeline_14_all, g2_toNextPipeline_14_req, g2_toNextPipeline_14_writeen, g2_toNextPipeline_14_be, g2_toNextPipeline_14_addr, g2_toNextPipeline_14_indata, g2_toNextPipeline_14_readen, g2_toNextPipeline_14_addr_rd, g2_toNextPipeline_15_array, g2_toNextPipeline_15_all, g2_toNextPipeline_15_req, g2_toNextPipeline_15_writeen, g2_toNextPipeline_15_be, g2_toNextPipeline_15_addr, g2_toNextPipeline_15_indata, g2_toNextPipeline_15_readen, g2_toNextPipeline_15_addr_rd};
  wire [1810:0] xbus2 = {x2_mbist_ack, x2_mbist_outdata, x2_toNextPipeline_0_array, x2_toNextPipeline_0_all, x2_toNextPipeline_0_req, x2_toNextPipeline_0_writeen, x2_toNextPipeline_0_be, x2_toNextPipeline_0_addr, x2_toNextPipeline_0_indata, x2_toNextPipeline_0_readen, x2_toNextPipeline_0_addr_rd, x2_toNextPipeline_1_array, x2_toNextPipeline_1_all, x2_toNextPipeline_1_req, x2_toNextPipeline_1_writeen, x2_toNextPipeline_1_be, x2_toNextPipeline_1_addr, x2_toNextPipeline_1_indata, x2_toNextPipeline_1_readen, x2_toNextPipeline_1_addr_rd, x2_toNextPipeline_2_array, x2_toNextPipeline_2_all, x2_toNextPipeline_2_req, x2_toNextPipeline_2_writeen, x2_toNextPipeline_2_be, x2_toNextPipeline_2_addr, x2_toNextPipeline_2_indata, x2_toNextPipeline_2_readen, x2_toNextPipeline_2_addr_rd, x2_toNextPipeline_3_array, x2_toNextPipeline_3_all, x2_toNextPipeline_3_req, x2_toNextPipeline_3_writeen, x2_toNextPipeline_3_be, x2_toNextPipeline_3_addr, x2_toNextPipeline_3_indata, x2_toNextPipeline_3_readen, x2_toNextPipeline_3_addr_rd, x2_toNextPipeline_4_array, x2_toNextPipeline_4_all, x2_toNextPipeline_4_req, x2_toNextPipeline_4_writeen, x2_toNextPipeline_4_be, x2_toNextPipeline_4_addr, x2_toNextPipeline_4_indata, x2_toNextPipeline_4_readen, x2_toNextPipeline_4_addr_rd, x2_toNextPipeline_5_array, x2_toNextPipeline_5_all, x2_toNextPipeline_5_req, x2_toNextPipeline_5_writeen, x2_toNextPipeline_5_be, x2_toNextPipeline_5_addr, x2_toNextPipeline_5_indata, x2_toNextPipeline_5_readen, x2_toNextPipeline_5_addr_rd, x2_toNextPipeline_6_array, x2_toNextPipeline_6_all, x2_toNextPipeline_6_req, x2_toNextPipeline_6_writeen, x2_toNextPipeline_6_be, x2_toNextPipeline_6_addr, x2_toNextPipeline_6_indata, x2_toNextPipeline_6_readen, x2_toNextPipeline_6_addr_rd, x2_toNextPipeline_7_array, x2_toNextPipeline_7_all, x2_toNextPipeline_7_req, x2_toNextPipeline_7_writeen, x2_toNextPipeline_7_be, x2_toNextPipeline_7_addr, x2_toNextPipeline_7_indata, x2_toNextPipeline_7_readen, x2_toNextPipeline_7_addr_rd, x2_toNextPipeline_8_array, x2_toNextPipeline_8_all, x2_toNextPipeline_8_req, x2_toNextPipeline_8_writeen, x2_toNextPipeline_8_be, x2_toNextPipeline_8_addr, x2_toNextPipeline_8_indata, x2_toNextPipeline_8_readen, x2_toNextPipeline_8_addr_rd, x2_toNextPipeline_9_array, x2_toNextPipeline_9_all, x2_toNextPipeline_9_req, x2_toNextPipeline_9_writeen, x2_toNextPipeline_9_be, x2_toNextPipeline_9_addr, x2_toNextPipeline_9_indata, x2_toNextPipeline_9_readen, x2_toNextPipeline_9_addr_rd, x2_toNextPipeline_10_array, x2_toNextPipeline_10_all, x2_toNextPipeline_10_req, x2_toNextPipeline_10_writeen, x2_toNextPipeline_10_be, x2_toNextPipeline_10_addr, x2_toNextPipeline_10_indata, x2_toNextPipeline_10_readen, x2_toNextPipeline_10_addr_rd, x2_toNextPipeline_11_array, x2_toNextPipeline_11_all, x2_toNextPipeline_11_req, x2_toNextPipeline_11_writeen, x2_toNextPipeline_11_be, x2_toNextPipeline_11_addr, x2_toNextPipeline_11_indata, x2_toNextPipeline_11_readen, x2_toNextPipeline_11_addr_rd, x2_toNextPipeline_12_array, x2_toNextPipeline_12_all, x2_toNextPipeline_12_req, x2_toNextPipeline_12_writeen, x2_toNextPipeline_12_be, x2_toNextPipeline_12_addr, x2_toNextPipeline_12_indata, x2_toNextPipeline_12_readen, x2_toNextPipeline_12_addr_rd, x2_toNextPipeline_13_array, x2_toNextPipeline_13_all, x2_toNextPipeline_13_req, x2_toNextPipeline_13_writeen, x2_toNextPipeline_13_be, x2_toNextPipeline_13_addr, x2_toNextPipeline_13_indata, x2_toNextPipeline_13_readen, x2_toNextPipeline_13_addr_rd, x2_toNextPipeline_14_array, x2_toNextPipeline_14_all, x2_toNextPipeline_14_req, x2_toNextPipeline_14_writeen, x2_toNextPipeline_14_be, x2_toNextPipeline_14_addr, x2_toNextPipeline_14_indata, x2_toNextPipeline_14_readen, x2_toNextPipeline_14_addr_rd, x2_toNextPipeline_15_array, x2_toNextPipeline_15_all, x2_toNextPipeline_15_req, x2_toNextPipeline_15_writeen, x2_toNextPipeline_15_be, x2_toNextPipeline_15_addr, x2_toNextPipeline_15_indata, x2_toNextPipeline_15_readen, x2_toNextPipeline_15_addr_rd};
  task automatic detail2();
    if (g2_mbist_ack !== x2_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.mbist_ack golden=%h impl=%h", cyc, g2_mbist_ack, x2_mbist_ack); end
    if (g2_mbist_outdata !== x2_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.mbist_outdata golden=%h impl=%h", cyc, g2_mbist_outdata, x2_mbist_outdata); end
    if (g2_toNextPipeline_0_array !== x2_toNextPipeline_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_array golden=%h impl=%h", cyc, g2_toNextPipeline_0_array, x2_toNextPipeline_0_array); end
    if (g2_toNextPipeline_0_all !== x2_toNextPipeline_0_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_all golden=%h impl=%h", cyc, g2_toNextPipeline_0_all, x2_toNextPipeline_0_all); end
    if (g2_toNextPipeline_0_req !== x2_toNextPipeline_0_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_req golden=%h impl=%h", cyc, g2_toNextPipeline_0_req, x2_toNextPipeline_0_req); end
    if (g2_toNextPipeline_0_writeen !== x2_toNextPipeline_0_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_0_writeen, x2_toNextPipeline_0_writeen); end
    if (g2_toNextPipeline_0_be !== x2_toNextPipeline_0_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_be golden=%h impl=%h", cyc, g2_toNextPipeline_0_be, x2_toNextPipeline_0_be); end
    if (g2_toNextPipeline_0_addr !== x2_toNextPipeline_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_addr golden=%h impl=%h", cyc, g2_toNextPipeline_0_addr, x2_toNextPipeline_0_addr); end
    if (g2_toNextPipeline_0_indata !== x2_toNextPipeline_0_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_indata golden=%h impl=%h", cyc, g2_toNextPipeline_0_indata, x2_toNextPipeline_0_indata); end
    if (g2_toNextPipeline_0_readen !== x2_toNextPipeline_0_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_readen golden=%h impl=%h", cyc, g2_toNextPipeline_0_readen, x2_toNextPipeline_0_readen); end
    if (g2_toNextPipeline_0_addr_rd !== x2_toNextPipeline_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_0_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_0_addr_rd, x2_toNextPipeline_0_addr_rd); end
    if (g2_toNextPipeline_1_array !== x2_toNextPipeline_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_array golden=%h impl=%h", cyc, g2_toNextPipeline_1_array, x2_toNextPipeline_1_array); end
    if (g2_toNextPipeline_1_all !== x2_toNextPipeline_1_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_all golden=%h impl=%h", cyc, g2_toNextPipeline_1_all, x2_toNextPipeline_1_all); end
    if (g2_toNextPipeline_1_req !== x2_toNextPipeline_1_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_req golden=%h impl=%h", cyc, g2_toNextPipeline_1_req, x2_toNextPipeline_1_req); end
    if (g2_toNextPipeline_1_writeen !== x2_toNextPipeline_1_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_1_writeen, x2_toNextPipeline_1_writeen); end
    if (g2_toNextPipeline_1_be !== x2_toNextPipeline_1_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_be golden=%h impl=%h", cyc, g2_toNextPipeline_1_be, x2_toNextPipeline_1_be); end
    if (g2_toNextPipeline_1_addr !== x2_toNextPipeline_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_addr golden=%h impl=%h", cyc, g2_toNextPipeline_1_addr, x2_toNextPipeline_1_addr); end
    if (g2_toNextPipeline_1_indata !== x2_toNextPipeline_1_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_indata golden=%h impl=%h", cyc, g2_toNextPipeline_1_indata, x2_toNextPipeline_1_indata); end
    if (g2_toNextPipeline_1_readen !== x2_toNextPipeline_1_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_readen golden=%h impl=%h", cyc, g2_toNextPipeline_1_readen, x2_toNextPipeline_1_readen); end
    if (g2_toNextPipeline_1_addr_rd !== x2_toNextPipeline_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_1_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_1_addr_rd, x2_toNextPipeline_1_addr_rd); end
    if (g2_toNextPipeline_2_array !== x2_toNextPipeline_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_array golden=%h impl=%h", cyc, g2_toNextPipeline_2_array, x2_toNextPipeline_2_array); end
    if (g2_toNextPipeline_2_all !== x2_toNextPipeline_2_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_all golden=%h impl=%h", cyc, g2_toNextPipeline_2_all, x2_toNextPipeline_2_all); end
    if (g2_toNextPipeline_2_req !== x2_toNextPipeline_2_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_req golden=%h impl=%h", cyc, g2_toNextPipeline_2_req, x2_toNextPipeline_2_req); end
    if (g2_toNextPipeline_2_writeen !== x2_toNextPipeline_2_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_2_writeen, x2_toNextPipeline_2_writeen); end
    if (g2_toNextPipeline_2_be !== x2_toNextPipeline_2_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_be golden=%h impl=%h", cyc, g2_toNextPipeline_2_be, x2_toNextPipeline_2_be); end
    if (g2_toNextPipeline_2_addr !== x2_toNextPipeline_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_addr golden=%h impl=%h", cyc, g2_toNextPipeline_2_addr, x2_toNextPipeline_2_addr); end
    if (g2_toNextPipeline_2_indata !== x2_toNextPipeline_2_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_indata golden=%h impl=%h", cyc, g2_toNextPipeline_2_indata, x2_toNextPipeline_2_indata); end
    if (g2_toNextPipeline_2_readen !== x2_toNextPipeline_2_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_readen golden=%h impl=%h", cyc, g2_toNextPipeline_2_readen, x2_toNextPipeline_2_readen); end
    if (g2_toNextPipeline_2_addr_rd !== x2_toNextPipeline_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_2_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_2_addr_rd, x2_toNextPipeline_2_addr_rd); end
    if (g2_toNextPipeline_3_array !== x2_toNextPipeline_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_array golden=%h impl=%h", cyc, g2_toNextPipeline_3_array, x2_toNextPipeline_3_array); end
    if (g2_toNextPipeline_3_all !== x2_toNextPipeline_3_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_all golden=%h impl=%h", cyc, g2_toNextPipeline_3_all, x2_toNextPipeline_3_all); end
    if (g2_toNextPipeline_3_req !== x2_toNextPipeline_3_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_req golden=%h impl=%h", cyc, g2_toNextPipeline_3_req, x2_toNextPipeline_3_req); end
    if (g2_toNextPipeline_3_writeen !== x2_toNextPipeline_3_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_3_writeen, x2_toNextPipeline_3_writeen); end
    if (g2_toNextPipeline_3_be !== x2_toNextPipeline_3_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_be golden=%h impl=%h", cyc, g2_toNextPipeline_3_be, x2_toNextPipeline_3_be); end
    if (g2_toNextPipeline_3_addr !== x2_toNextPipeline_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_addr golden=%h impl=%h", cyc, g2_toNextPipeline_3_addr, x2_toNextPipeline_3_addr); end
    if (g2_toNextPipeline_3_indata !== x2_toNextPipeline_3_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_indata golden=%h impl=%h", cyc, g2_toNextPipeline_3_indata, x2_toNextPipeline_3_indata); end
    if (g2_toNextPipeline_3_readen !== x2_toNextPipeline_3_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_readen golden=%h impl=%h", cyc, g2_toNextPipeline_3_readen, x2_toNextPipeline_3_readen); end
    if (g2_toNextPipeline_3_addr_rd !== x2_toNextPipeline_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_3_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_3_addr_rd, x2_toNextPipeline_3_addr_rd); end
    if (g2_toNextPipeline_4_array !== x2_toNextPipeline_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_array golden=%h impl=%h", cyc, g2_toNextPipeline_4_array, x2_toNextPipeline_4_array); end
    if (g2_toNextPipeline_4_all !== x2_toNextPipeline_4_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_all golden=%h impl=%h", cyc, g2_toNextPipeline_4_all, x2_toNextPipeline_4_all); end
    if (g2_toNextPipeline_4_req !== x2_toNextPipeline_4_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_req golden=%h impl=%h", cyc, g2_toNextPipeline_4_req, x2_toNextPipeline_4_req); end
    if (g2_toNextPipeline_4_writeen !== x2_toNextPipeline_4_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_4_writeen, x2_toNextPipeline_4_writeen); end
    if (g2_toNextPipeline_4_be !== x2_toNextPipeline_4_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_be golden=%h impl=%h", cyc, g2_toNextPipeline_4_be, x2_toNextPipeline_4_be); end
    if (g2_toNextPipeline_4_addr !== x2_toNextPipeline_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_addr golden=%h impl=%h", cyc, g2_toNextPipeline_4_addr, x2_toNextPipeline_4_addr); end
    if (g2_toNextPipeline_4_indata !== x2_toNextPipeline_4_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_indata golden=%h impl=%h", cyc, g2_toNextPipeline_4_indata, x2_toNextPipeline_4_indata); end
    if (g2_toNextPipeline_4_readen !== x2_toNextPipeline_4_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_readen golden=%h impl=%h", cyc, g2_toNextPipeline_4_readen, x2_toNextPipeline_4_readen); end
    if (g2_toNextPipeline_4_addr_rd !== x2_toNextPipeline_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_4_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_4_addr_rd, x2_toNextPipeline_4_addr_rd); end
    if (g2_toNextPipeline_5_array !== x2_toNextPipeline_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_array golden=%h impl=%h", cyc, g2_toNextPipeline_5_array, x2_toNextPipeline_5_array); end
    if (g2_toNextPipeline_5_all !== x2_toNextPipeline_5_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_all golden=%h impl=%h", cyc, g2_toNextPipeline_5_all, x2_toNextPipeline_5_all); end
    if (g2_toNextPipeline_5_req !== x2_toNextPipeline_5_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_req golden=%h impl=%h", cyc, g2_toNextPipeline_5_req, x2_toNextPipeline_5_req); end
    if (g2_toNextPipeline_5_writeen !== x2_toNextPipeline_5_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_5_writeen, x2_toNextPipeline_5_writeen); end
    if (g2_toNextPipeline_5_be !== x2_toNextPipeline_5_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_be golden=%h impl=%h", cyc, g2_toNextPipeline_5_be, x2_toNextPipeline_5_be); end
    if (g2_toNextPipeline_5_addr !== x2_toNextPipeline_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_addr golden=%h impl=%h", cyc, g2_toNextPipeline_5_addr, x2_toNextPipeline_5_addr); end
    if (g2_toNextPipeline_5_indata !== x2_toNextPipeline_5_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_indata golden=%h impl=%h", cyc, g2_toNextPipeline_5_indata, x2_toNextPipeline_5_indata); end
    if (g2_toNextPipeline_5_readen !== x2_toNextPipeline_5_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_readen golden=%h impl=%h", cyc, g2_toNextPipeline_5_readen, x2_toNextPipeline_5_readen); end
    if (g2_toNextPipeline_5_addr_rd !== x2_toNextPipeline_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_5_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_5_addr_rd, x2_toNextPipeline_5_addr_rd); end
    if (g2_toNextPipeline_6_array !== x2_toNextPipeline_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_array golden=%h impl=%h", cyc, g2_toNextPipeline_6_array, x2_toNextPipeline_6_array); end
    if (g2_toNextPipeline_6_all !== x2_toNextPipeline_6_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_all golden=%h impl=%h", cyc, g2_toNextPipeline_6_all, x2_toNextPipeline_6_all); end
    if (g2_toNextPipeline_6_req !== x2_toNextPipeline_6_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_req golden=%h impl=%h", cyc, g2_toNextPipeline_6_req, x2_toNextPipeline_6_req); end
    if (g2_toNextPipeline_6_writeen !== x2_toNextPipeline_6_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_6_writeen, x2_toNextPipeline_6_writeen); end
    if (g2_toNextPipeline_6_be !== x2_toNextPipeline_6_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_be golden=%h impl=%h", cyc, g2_toNextPipeline_6_be, x2_toNextPipeline_6_be); end
    if (g2_toNextPipeline_6_addr !== x2_toNextPipeline_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_addr golden=%h impl=%h", cyc, g2_toNextPipeline_6_addr, x2_toNextPipeline_6_addr); end
    if (g2_toNextPipeline_6_indata !== x2_toNextPipeline_6_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_indata golden=%h impl=%h", cyc, g2_toNextPipeline_6_indata, x2_toNextPipeline_6_indata); end
    if (g2_toNextPipeline_6_readen !== x2_toNextPipeline_6_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_readen golden=%h impl=%h", cyc, g2_toNextPipeline_6_readen, x2_toNextPipeline_6_readen); end
    if (g2_toNextPipeline_6_addr_rd !== x2_toNextPipeline_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_6_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_6_addr_rd, x2_toNextPipeline_6_addr_rd); end
    if (g2_toNextPipeline_7_array !== x2_toNextPipeline_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_array golden=%h impl=%h", cyc, g2_toNextPipeline_7_array, x2_toNextPipeline_7_array); end
    if (g2_toNextPipeline_7_all !== x2_toNextPipeline_7_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_all golden=%h impl=%h", cyc, g2_toNextPipeline_7_all, x2_toNextPipeline_7_all); end
    if (g2_toNextPipeline_7_req !== x2_toNextPipeline_7_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_req golden=%h impl=%h", cyc, g2_toNextPipeline_7_req, x2_toNextPipeline_7_req); end
    if (g2_toNextPipeline_7_writeen !== x2_toNextPipeline_7_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_7_writeen, x2_toNextPipeline_7_writeen); end
    if (g2_toNextPipeline_7_be !== x2_toNextPipeline_7_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_be golden=%h impl=%h", cyc, g2_toNextPipeline_7_be, x2_toNextPipeline_7_be); end
    if (g2_toNextPipeline_7_addr !== x2_toNextPipeline_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_addr golden=%h impl=%h", cyc, g2_toNextPipeline_7_addr, x2_toNextPipeline_7_addr); end
    if (g2_toNextPipeline_7_indata !== x2_toNextPipeline_7_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_indata golden=%h impl=%h", cyc, g2_toNextPipeline_7_indata, x2_toNextPipeline_7_indata); end
    if (g2_toNextPipeline_7_readen !== x2_toNextPipeline_7_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_readen golden=%h impl=%h", cyc, g2_toNextPipeline_7_readen, x2_toNextPipeline_7_readen); end
    if (g2_toNextPipeline_7_addr_rd !== x2_toNextPipeline_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_7_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_7_addr_rd, x2_toNextPipeline_7_addr_rd); end
    if (g2_toNextPipeline_8_array !== x2_toNextPipeline_8_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_array golden=%h impl=%h", cyc, g2_toNextPipeline_8_array, x2_toNextPipeline_8_array); end
    if (g2_toNextPipeline_8_all !== x2_toNextPipeline_8_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_all golden=%h impl=%h", cyc, g2_toNextPipeline_8_all, x2_toNextPipeline_8_all); end
    if (g2_toNextPipeline_8_req !== x2_toNextPipeline_8_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_req golden=%h impl=%h", cyc, g2_toNextPipeline_8_req, x2_toNextPipeline_8_req); end
    if (g2_toNextPipeline_8_writeen !== x2_toNextPipeline_8_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_8_writeen, x2_toNextPipeline_8_writeen); end
    if (g2_toNextPipeline_8_be !== x2_toNextPipeline_8_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_be golden=%h impl=%h", cyc, g2_toNextPipeline_8_be, x2_toNextPipeline_8_be); end
    if (g2_toNextPipeline_8_addr !== x2_toNextPipeline_8_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_addr golden=%h impl=%h", cyc, g2_toNextPipeline_8_addr, x2_toNextPipeline_8_addr); end
    if (g2_toNextPipeline_8_indata !== x2_toNextPipeline_8_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_indata golden=%h impl=%h", cyc, g2_toNextPipeline_8_indata, x2_toNextPipeline_8_indata); end
    if (g2_toNextPipeline_8_readen !== x2_toNextPipeline_8_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_readen golden=%h impl=%h", cyc, g2_toNextPipeline_8_readen, x2_toNextPipeline_8_readen); end
    if (g2_toNextPipeline_8_addr_rd !== x2_toNextPipeline_8_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_8_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_8_addr_rd, x2_toNextPipeline_8_addr_rd); end
    if (g2_toNextPipeline_9_array !== x2_toNextPipeline_9_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_array golden=%h impl=%h", cyc, g2_toNextPipeline_9_array, x2_toNextPipeline_9_array); end
    if (g2_toNextPipeline_9_all !== x2_toNextPipeline_9_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_all golden=%h impl=%h", cyc, g2_toNextPipeline_9_all, x2_toNextPipeline_9_all); end
    if (g2_toNextPipeline_9_req !== x2_toNextPipeline_9_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_req golden=%h impl=%h", cyc, g2_toNextPipeline_9_req, x2_toNextPipeline_9_req); end
    if (g2_toNextPipeline_9_writeen !== x2_toNextPipeline_9_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_9_writeen, x2_toNextPipeline_9_writeen); end
    if (g2_toNextPipeline_9_be !== x2_toNextPipeline_9_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_be golden=%h impl=%h", cyc, g2_toNextPipeline_9_be, x2_toNextPipeline_9_be); end
    if (g2_toNextPipeline_9_addr !== x2_toNextPipeline_9_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_addr golden=%h impl=%h", cyc, g2_toNextPipeline_9_addr, x2_toNextPipeline_9_addr); end
    if (g2_toNextPipeline_9_indata !== x2_toNextPipeline_9_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_indata golden=%h impl=%h", cyc, g2_toNextPipeline_9_indata, x2_toNextPipeline_9_indata); end
    if (g2_toNextPipeline_9_readen !== x2_toNextPipeline_9_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_readen golden=%h impl=%h", cyc, g2_toNextPipeline_9_readen, x2_toNextPipeline_9_readen); end
    if (g2_toNextPipeline_9_addr_rd !== x2_toNextPipeline_9_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_9_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_9_addr_rd, x2_toNextPipeline_9_addr_rd); end
    if (g2_toNextPipeline_10_array !== x2_toNextPipeline_10_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_array golden=%h impl=%h", cyc, g2_toNextPipeline_10_array, x2_toNextPipeline_10_array); end
    if (g2_toNextPipeline_10_all !== x2_toNextPipeline_10_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_all golden=%h impl=%h", cyc, g2_toNextPipeline_10_all, x2_toNextPipeline_10_all); end
    if (g2_toNextPipeline_10_req !== x2_toNextPipeline_10_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_req golden=%h impl=%h", cyc, g2_toNextPipeline_10_req, x2_toNextPipeline_10_req); end
    if (g2_toNextPipeline_10_writeen !== x2_toNextPipeline_10_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_10_writeen, x2_toNextPipeline_10_writeen); end
    if (g2_toNextPipeline_10_be !== x2_toNextPipeline_10_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_be golden=%h impl=%h", cyc, g2_toNextPipeline_10_be, x2_toNextPipeline_10_be); end
    if (g2_toNextPipeline_10_addr !== x2_toNextPipeline_10_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_addr golden=%h impl=%h", cyc, g2_toNextPipeline_10_addr, x2_toNextPipeline_10_addr); end
    if (g2_toNextPipeline_10_indata !== x2_toNextPipeline_10_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_indata golden=%h impl=%h", cyc, g2_toNextPipeline_10_indata, x2_toNextPipeline_10_indata); end
    if (g2_toNextPipeline_10_readen !== x2_toNextPipeline_10_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_readen golden=%h impl=%h", cyc, g2_toNextPipeline_10_readen, x2_toNextPipeline_10_readen); end
    if (g2_toNextPipeline_10_addr_rd !== x2_toNextPipeline_10_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_10_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_10_addr_rd, x2_toNextPipeline_10_addr_rd); end
    if (g2_toNextPipeline_11_array !== x2_toNextPipeline_11_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_array golden=%h impl=%h", cyc, g2_toNextPipeline_11_array, x2_toNextPipeline_11_array); end
    if (g2_toNextPipeline_11_all !== x2_toNextPipeline_11_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_all golden=%h impl=%h", cyc, g2_toNextPipeline_11_all, x2_toNextPipeline_11_all); end
    if (g2_toNextPipeline_11_req !== x2_toNextPipeline_11_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_req golden=%h impl=%h", cyc, g2_toNextPipeline_11_req, x2_toNextPipeline_11_req); end
    if (g2_toNextPipeline_11_writeen !== x2_toNextPipeline_11_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_11_writeen, x2_toNextPipeline_11_writeen); end
    if (g2_toNextPipeline_11_be !== x2_toNextPipeline_11_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_be golden=%h impl=%h", cyc, g2_toNextPipeline_11_be, x2_toNextPipeline_11_be); end
    if (g2_toNextPipeline_11_addr !== x2_toNextPipeline_11_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_addr golden=%h impl=%h", cyc, g2_toNextPipeline_11_addr, x2_toNextPipeline_11_addr); end
    if (g2_toNextPipeline_11_indata !== x2_toNextPipeline_11_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_indata golden=%h impl=%h", cyc, g2_toNextPipeline_11_indata, x2_toNextPipeline_11_indata); end
    if (g2_toNextPipeline_11_readen !== x2_toNextPipeline_11_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_readen golden=%h impl=%h", cyc, g2_toNextPipeline_11_readen, x2_toNextPipeline_11_readen); end
    if (g2_toNextPipeline_11_addr_rd !== x2_toNextPipeline_11_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_11_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_11_addr_rd, x2_toNextPipeline_11_addr_rd); end
    if (g2_toNextPipeline_12_array !== x2_toNextPipeline_12_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_array golden=%h impl=%h", cyc, g2_toNextPipeline_12_array, x2_toNextPipeline_12_array); end
    if (g2_toNextPipeline_12_all !== x2_toNextPipeline_12_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_all golden=%h impl=%h", cyc, g2_toNextPipeline_12_all, x2_toNextPipeline_12_all); end
    if (g2_toNextPipeline_12_req !== x2_toNextPipeline_12_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_req golden=%h impl=%h", cyc, g2_toNextPipeline_12_req, x2_toNextPipeline_12_req); end
    if (g2_toNextPipeline_12_writeen !== x2_toNextPipeline_12_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_12_writeen, x2_toNextPipeline_12_writeen); end
    if (g2_toNextPipeline_12_be !== x2_toNextPipeline_12_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_be golden=%h impl=%h", cyc, g2_toNextPipeline_12_be, x2_toNextPipeline_12_be); end
    if (g2_toNextPipeline_12_addr !== x2_toNextPipeline_12_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_addr golden=%h impl=%h", cyc, g2_toNextPipeline_12_addr, x2_toNextPipeline_12_addr); end
    if (g2_toNextPipeline_12_indata !== x2_toNextPipeline_12_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_indata golden=%h impl=%h", cyc, g2_toNextPipeline_12_indata, x2_toNextPipeline_12_indata); end
    if (g2_toNextPipeline_12_readen !== x2_toNextPipeline_12_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_readen golden=%h impl=%h", cyc, g2_toNextPipeline_12_readen, x2_toNextPipeline_12_readen); end
    if (g2_toNextPipeline_12_addr_rd !== x2_toNextPipeline_12_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_12_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_12_addr_rd, x2_toNextPipeline_12_addr_rd); end
    if (g2_toNextPipeline_13_array !== x2_toNextPipeline_13_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_array golden=%h impl=%h", cyc, g2_toNextPipeline_13_array, x2_toNextPipeline_13_array); end
    if (g2_toNextPipeline_13_all !== x2_toNextPipeline_13_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_all golden=%h impl=%h", cyc, g2_toNextPipeline_13_all, x2_toNextPipeline_13_all); end
    if (g2_toNextPipeline_13_req !== x2_toNextPipeline_13_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_req golden=%h impl=%h", cyc, g2_toNextPipeline_13_req, x2_toNextPipeline_13_req); end
    if (g2_toNextPipeline_13_writeen !== x2_toNextPipeline_13_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_13_writeen, x2_toNextPipeline_13_writeen); end
    if (g2_toNextPipeline_13_be !== x2_toNextPipeline_13_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_be golden=%h impl=%h", cyc, g2_toNextPipeline_13_be, x2_toNextPipeline_13_be); end
    if (g2_toNextPipeline_13_addr !== x2_toNextPipeline_13_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_addr golden=%h impl=%h", cyc, g2_toNextPipeline_13_addr, x2_toNextPipeline_13_addr); end
    if (g2_toNextPipeline_13_indata !== x2_toNextPipeline_13_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_indata golden=%h impl=%h", cyc, g2_toNextPipeline_13_indata, x2_toNextPipeline_13_indata); end
    if (g2_toNextPipeline_13_readen !== x2_toNextPipeline_13_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_readen golden=%h impl=%h", cyc, g2_toNextPipeline_13_readen, x2_toNextPipeline_13_readen); end
    if (g2_toNextPipeline_13_addr_rd !== x2_toNextPipeline_13_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_13_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_13_addr_rd, x2_toNextPipeline_13_addr_rd); end
    if (g2_toNextPipeline_14_array !== x2_toNextPipeline_14_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_array golden=%h impl=%h", cyc, g2_toNextPipeline_14_array, x2_toNextPipeline_14_array); end
    if (g2_toNextPipeline_14_all !== x2_toNextPipeline_14_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_all golden=%h impl=%h", cyc, g2_toNextPipeline_14_all, x2_toNextPipeline_14_all); end
    if (g2_toNextPipeline_14_req !== x2_toNextPipeline_14_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_req golden=%h impl=%h", cyc, g2_toNextPipeline_14_req, x2_toNextPipeline_14_req); end
    if (g2_toNextPipeline_14_writeen !== x2_toNextPipeline_14_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_14_writeen, x2_toNextPipeline_14_writeen); end
    if (g2_toNextPipeline_14_be !== x2_toNextPipeline_14_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_be golden=%h impl=%h", cyc, g2_toNextPipeline_14_be, x2_toNextPipeline_14_be); end
    if (g2_toNextPipeline_14_addr !== x2_toNextPipeline_14_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_addr golden=%h impl=%h", cyc, g2_toNextPipeline_14_addr, x2_toNextPipeline_14_addr); end
    if (g2_toNextPipeline_14_indata !== x2_toNextPipeline_14_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_indata golden=%h impl=%h", cyc, g2_toNextPipeline_14_indata, x2_toNextPipeline_14_indata); end
    if (g2_toNextPipeline_14_readen !== x2_toNextPipeline_14_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_readen golden=%h impl=%h", cyc, g2_toNextPipeline_14_readen, x2_toNextPipeline_14_readen); end
    if (g2_toNextPipeline_14_addr_rd !== x2_toNextPipeline_14_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_14_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_14_addr_rd, x2_toNextPipeline_14_addr_rd); end
    if (g2_toNextPipeline_15_array !== x2_toNextPipeline_15_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_array golden=%h impl=%h", cyc, g2_toNextPipeline_15_array, x2_toNextPipeline_15_array); end
    if (g2_toNextPipeline_15_all !== x2_toNextPipeline_15_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_all golden=%h impl=%h", cyc, g2_toNextPipeline_15_all, x2_toNextPipeline_15_all); end
    if (g2_toNextPipeline_15_req !== x2_toNextPipeline_15_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_req golden=%h impl=%h", cyc, g2_toNextPipeline_15_req, x2_toNextPipeline_15_req); end
    if (g2_toNextPipeline_15_writeen !== x2_toNextPipeline_15_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_writeen golden=%h impl=%h", cyc, g2_toNextPipeline_15_writeen, x2_toNextPipeline_15_writeen); end
    if (g2_toNextPipeline_15_be !== x2_toNextPipeline_15_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_be golden=%h impl=%h", cyc, g2_toNextPipeline_15_be, x2_toNextPipeline_15_be); end
    if (g2_toNextPipeline_15_addr !== x2_toNextPipeline_15_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_addr golden=%h impl=%h", cyc, g2_toNextPipeline_15_addr, x2_toNextPipeline_15_addr); end
    if (g2_toNextPipeline_15_indata !== x2_toNextPipeline_15_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_indata golden=%h impl=%h", cyc, g2_toNextPipeline_15_indata, x2_toNextPipeline_15_indata); end
    if (g2_toNextPipeline_15_readen !== x2_toNextPipeline_15_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_readen golden=%h impl=%h", cyc, g2_toNextPipeline_15_readen, x2_toNextPipeline_15_readen); end
    if (g2_toNextPipeline_15_addr_rd !== x2_toNextPipeline_15_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFrontend.toNextPipeline_15_addr_rd golden=%h impl=%h", cyc, g2_toNextPipeline_15_addr_rd, x2_toNextPipeline_15_addr_rd); end
  endtask

  // ======================== [03] MbistPipeFtb ========================
  logic [39:0] v3_rd0;
  logic [39:0] v3_rd1;
  logic [39:0] v3_rd2;
  logic [39:0] v3_rd3;
  logic [39:0] v3_rd4;
  logic [39:0] v3_rd5;
  logic [39:0] v3_rd6;
  logic [39:0] v3_rd7;
  logic g3_mbist_ack;
  logic [39:0] g3_mbist_outdata;
  logic [9:0] g3_toSRAM_0_addr;
  logic [9:0] g3_toSRAM_0_addr_rd;
  logic [39:0] g3_toSRAM_0_wdata;
  logic [3:0] g3_toSRAM_0_wmask;
  logic g3_toSRAM_0_re;
  logic g3_toSRAM_0_we;
  logic g3_toSRAM_0_ack;
  logic g3_toSRAM_0_selectedOH;
  logic [5:0] g3_toSRAM_0_array;
  logic [9:0] g3_toSRAM_1_addr;
  logic [9:0] g3_toSRAM_1_addr_rd;
  logic [39:0] g3_toSRAM_1_wdata;
  logic [3:0] g3_toSRAM_1_wmask;
  logic g3_toSRAM_1_re;
  logic g3_toSRAM_1_we;
  logic g3_toSRAM_1_ack;
  logic g3_toSRAM_1_selectedOH;
  logic [5:0] g3_toSRAM_1_array;
  logic [9:0] g3_toSRAM_2_addr;
  logic [9:0] g3_toSRAM_2_addr_rd;
  logic [39:0] g3_toSRAM_2_wdata;
  logic [3:0] g3_toSRAM_2_wmask;
  logic g3_toSRAM_2_re;
  logic g3_toSRAM_2_we;
  logic g3_toSRAM_2_ack;
  logic g3_toSRAM_2_selectedOH;
  logic [5:0] g3_toSRAM_2_array;
  logic [9:0] g3_toSRAM_3_addr;
  logic [9:0] g3_toSRAM_3_addr_rd;
  logic [39:0] g3_toSRAM_3_wdata;
  logic [3:0] g3_toSRAM_3_wmask;
  logic g3_toSRAM_3_re;
  logic g3_toSRAM_3_we;
  logic g3_toSRAM_3_ack;
  logic g3_toSRAM_3_selectedOH;
  logic [5:0] g3_toSRAM_3_array;
  logic [9:0] g3_toSRAM_4_addr;
  logic [9:0] g3_toSRAM_4_addr_rd;
  logic [39:0] g3_toSRAM_4_wdata;
  logic [3:0] g3_toSRAM_4_wmask;
  logic g3_toSRAM_4_re;
  logic g3_toSRAM_4_we;
  logic g3_toSRAM_4_ack;
  logic g3_toSRAM_4_selectedOH;
  logic [5:0] g3_toSRAM_4_array;
  logic [9:0] g3_toSRAM_5_addr;
  logic [9:0] g3_toSRAM_5_addr_rd;
  logic [39:0] g3_toSRAM_5_wdata;
  logic [3:0] g3_toSRAM_5_wmask;
  logic g3_toSRAM_5_re;
  logic g3_toSRAM_5_we;
  logic g3_toSRAM_5_ack;
  logic g3_toSRAM_5_selectedOH;
  logic [5:0] g3_toSRAM_5_array;
  logic [9:0] g3_toSRAM_6_addr;
  logic [9:0] g3_toSRAM_6_addr_rd;
  logic [39:0] g3_toSRAM_6_wdata;
  logic [3:0] g3_toSRAM_6_wmask;
  logic g3_toSRAM_6_re;
  logic g3_toSRAM_6_we;
  logic g3_toSRAM_6_ack;
  logic g3_toSRAM_6_selectedOH;
  logic [5:0] g3_toSRAM_6_array;
  logic [9:0] g3_toSRAM_7_addr;
  logic [9:0] g3_toSRAM_7_addr_rd;
  logic [39:0] g3_toSRAM_7_wdata;
  logic [3:0] g3_toSRAM_7_wmask;
  logic g3_toSRAM_7_re;
  logic g3_toSRAM_7_we;
  logic g3_toSRAM_7_ack;
  logic g3_toSRAM_7_selectedOH;
  logic [5:0] g3_toSRAM_7_array;
  logic x3_mbist_ack;
  logic [39:0] x3_mbist_outdata;
  logic [9:0] x3_toSRAM_0_addr;
  logic [9:0] x3_toSRAM_0_addr_rd;
  logic [39:0] x3_toSRAM_0_wdata;
  logic [3:0] x3_toSRAM_0_wmask;
  logic x3_toSRAM_0_re;
  logic x3_toSRAM_0_we;
  logic x3_toSRAM_0_ack;
  logic x3_toSRAM_0_selectedOH;
  logic [5:0] x3_toSRAM_0_array;
  logic [9:0] x3_toSRAM_1_addr;
  logic [9:0] x3_toSRAM_1_addr_rd;
  logic [39:0] x3_toSRAM_1_wdata;
  logic [3:0] x3_toSRAM_1_wmask;
  logic x3_toSRAM_1_re;
  logic x3_toSRAM_1_we;
  logic x3_toSRAM_1_ack;
  logic x3_toSRAM_1_selectedOH;
  logic [5:0] x3_toSRAM_1_array;
  logic [9:0] x3_toSRAM_2_addr;
  logic [9:0] x3_toSRAM_2_addr_rd;
  logic [39:0] x3_toSRAM_2_wdata;
  logic [3:0] x3_toSRAM_2_wmask;
  logic x3_toSRAM_2_re;
  logic x3_toSRAM_2_we;
  logic x3_toSRAM_2_ack;
  logic x3_toSRAM_2_selectedOH;
  logic [5:0] x3_toSRAM_2_array;
  logic [9:0] x3_toSRAM_3_addr;
  logic [9:0] x3_toSRAM_3_addr_rd;
  logic [39:0] x3_toSRAM_3_wdata;
  logic [3:0] x3_toSRAM_3_wmask;
  logic x3_toSRAM_3_re;
  logic x3_toSRAM_3_we;
  logic x3_toSRAM_3_ack;
  logic x3_toSRAM_3_selectedOH;
  logic [5:0] x3_toSRAM_3_array;
  logic [9:0] x3_toSRAM_4_addr;
  logic [9:0] x3_toSRAM_4_addr_rd;
  logic [39:0] x3_toSRAM_4_wdata;
  logic [3:0] x3_toSRAM_4_wmask;
  logic x3_toSRAM_4_re;
  logic x3_toSRAM_4_we;
  logic x3_toSRAM_4_ack;
  logic x3_toSRAM_4_selectedOH;
  logic [5:0] x3_toSRAM_4_array;
  logic [9:0] x3_toSRAM_5_addr;
  logic [9:0] x3_toSRAM_5_addr_rd;
  logic [39:0] x3_toSRAM_5_wdata;
  logic [3:0] x3_toSRAM_5_wmask;
  logic x3_toSRAM_5_re;
  logic x3_toSRAM_5_we;
  logic x3_toSRAM_5_ack;
  logic x3_toSRAM_5_selectedOH;
  logic [5:0] x3_toSRAM_5_array;
  logic [9:0] x3_toSRAM_6_addr;
  logic [9:0] x3_toSRAM_6_addr_rd;
  logic [39:0] x3_toSRAM_6_wdata;
  logic [3:0] x3_toSRAM_6_wmask;
  logic x3_toSRAM_6_re;
  logic x3_toSRAM_6_we;
  logic x3_toSRAM_6_ack;
  logic x3_toSRAM_6_selectedOH;
  logic [5:0] x3_toSRAM_6_array;
  logic [9:0] x3_toSRAM_7_addr;
  logic [9:0] x3_toSRAM_7_addr_rd;
  logic [39:0] x3_toSRAM_7_wdata;
  logic [3:0] x3_toSRAM_7_wmask;
  logic x3_toSRAM_7_re;
  logic x3_toSRAM_7_we;
  logic x3_toSRAM_7_ack;
  logic x3_toSRAM_7_selectedOH;
  logic [5:0] x3_toSRAM_7_array;
  bit [7:0] cov_spread3;
  bit [39:0] cov_od0_3, cov_od1_3;
  bit cov_ack0_3, cov_ack1_3;
  MbistPipeFtb u_g3 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr),
    .mbist_indata (s_indata[39:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd),
    .toSRAM_0_rdata (v3_rd0),
    .toSRAM_1_rdata (v3_rd1),
    .toSRAM_2_rdata (v3_rd2),
    .toSRAM_3_rdata (v3_rd3),
    .toSRAM_4_rdata (v3_rd4),
    .toSRAM_5_rdata (v3_rd5),
    .toSRAM_6_rdata (v3_rd6),
    .toSRAM_7_rdata (v3_rd7),
    .mbist_ack (g3_mbist_ack),
    .mbist_outdata (g3_mbist_outdata),
    .toSRAM_0_addr (g3_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g3_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g3_toSRAM_0_wdata),
    .toSRAM_0_wmask (g3_toSRAM_0_wmask),
    .toSRAM_0_re (g3_toSRAM_0_re),
    .toSRAM_0_we (g3_toSRAM_0_we),
    .toSRAM_0_ack (g3_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g3_toSRAM_0_selectedOH),
    .toSRAM_0_array (g3_toSRAM_0_array),
    .toSRAM_1_addr (g3_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g3_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g3_toSRAM_1_wdata),
    .toSRAM_1_wmask (g3_toSRAM_1_wmask),
    .toSRAM_1_re (g3_toSRAM_1_re),
    .toSRAM_1_we (g3_toSRAM_1_we),
    .toSRAM_1_ack (g3_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g3_toSRAM_1_selectedOH),
    .toSRAM_1_array (g3_toSRAM_1_array),
    .toSRAM_2_addr (g3_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g3_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g3_toSRAM_2_wdata),
    .toSRAM_2_wmask (g3_toSRAM_2_wmask),
    .toSRAM_2_re (g3_toSRAM_2_re),
    .toSRAM_2_we (g3_toSRAM_2_we),
    .toSRAM_2_ack (g3_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g3_toSRAM_2_selectedOH),
    .toSRAM_2_array (g3_toSRAM_2_array),
    .toSRAM_3_addr (g3_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g3_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g3_toSRAM_3_wdata),
    .toSRAM_3_wmask (g3_toSRAM_3_wmask),
    .toSRAM_3_re (g3_toSRAM_3_re),
    .toSRAM_3_we (g3_toSRAM_3_we),
    .toSRAM_3_ack (g3_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g3_toSRAM_3_selectedOH),
    .toSRAM_3_array (g3_toSRAM_3_array),
    .toSRAM_4_addr (g3_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g3_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g3_toSRAM_4_wdata),
    .toSRAM_4_wmask (g3_toSRAM_4_wmask),
    .toSRAM_4_re (g3_toSRAM_4_re),
    .toSRAM_4_we (g3_toSRAM_4_we),
    .toSRAM_4_ack (g3_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g3_toSRAM_4_selectedOH),
    .toSRAM_4_array (g3_toSRAM_4_array),
    .toSRAM_5_addr (g3_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g3_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g3_toSRAM_5_wdata),
    .toSRAM_5_wmask (g3_toSRAM_5_wmask),
    .toSRAM_5_re (g3_toSRAM_5_re),
    .toSRAM_5_we (g3_toSRAM_5_we),
    .toSRAM_5_ack (g3_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g3_toSRAM_5_selectedOH),
    .toSRAM_5_array (g3_toSRAM_5_array),
    .toSRAM_6_addr (g3_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g3_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g3_toSRAM_6_wdata),
    .toSRAM_6_wmask (g3_toSRAM_6_wmask),
    .toSRAM_6_re (g3_toSRAM_6_re),
    .toSRAM_6_we (g3_toSRAM_6_we),
    .toSRAM_6_ack (g3_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g3_toSRAM_6_selectedOH),
    .toSRAM_6_array (g3_toSRAM_6_array),
    .toSRAM_7_addr (g3_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g3_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g3_toSRAM_7_wdata),
    .toSRAM_7_wmask (g3_toSRAM_7_wmask),
    .toSRAM_7_re (g3_toSRAM_7_re),
    .toSRAM_7_we (g3_toSRAM_7_we),
    .toSRAM_7_ack (g3_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g3_toSRAM_7_selectedOH),
    .toSRAM_7_array (g3_toSRAM_7_array)
  );
  MbistPipeFtb_xs u_x3 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr),
    .mbist_indata (s_indata[39:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd),
    .toSRAM_0_rdata (v3_rd0),
    .toSRAM_1_rdata (v3_rd1),
    .toSRAM_2_rdata (v3_rd2),
    .toSRAM_3_rdata (v3_rd3),
    .toSRAM_4_rdata (v3_rd4),
    .toSRAM_5_rdata (v3_rd5),
    .toSRAM_6_rdata (v3_rd6),
    .toSRAM_7_rdata (v3_rd7),
    .mbist_ack (x3_mbist_ack),
    .mbist_outdata (x3_mbist_outdata),
    .toSRAM_0_addr (x3_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x3_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x3_toSRAM_0_wdata),
    .toSRAM_0_wmask (x3_toSRAM_0_wmask),
    .toSRAM_0_re (x3_toSRAM_0_re),
    .toSRAM_0_we (x3_toSRAM_0_we),
    .toSRAM_0_ack (x3_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x3_toSRAM_0_selectedOH),
    .toSRAM_0_array (x3_toSRAM_0_array),
    .toSRAM_1_addr (x3_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x3_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x3_toSRAM_1_wdata),
    .toSRAM_1_wmask (x3_toSRAM_1_wmask),
    .toSRAM_1_re (x3_toSRAM_1_re),
    .toSRAM_1_we (x3_toSRAM_1_we),
    .toSRAM_1_ack (x3_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x3_toSRAM_1_selectedOH),
    .toSRAM_1_array (x3_toSRAM_1_array),
    .toSRAM_2_addr (x3_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x3_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x3_toSRAM_2_wdata),
    .toSRAM_2_wmask (x3_toSRAM_2_wmask),
    .toSRAM_2_re (x3_toSRAM_2_re),
    .toSRAM_2_we (x3_toSRAM_2_we),
    .toSRAM_2_ack (x3_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x3_toSRAM_2_selectedOH),
    .toSRAM_2_array (x3_toSRAM_2_array),
    .toSRAM_3_addr (x3_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x3_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x3_toSRAM_3_wdata),
    .toSRAM_3_wmask (x3_toSRAM_3_wmask),
    .toSRAM_3_re (x3_toSRAM_3_re),
    .toSRAM_3_we (x3_toSRAM_3_we),
    .toSRAM_3_ack (x3_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x3_toSRAM_3_selectedOH),
    .toSRAM_3_array (x3_toSRAM_3_array),
    .toSRAM_4_addr (x3_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x3_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x3_toSRAM_4_wdata),
    .toSRAM_4_wmask (x3_toSRAM_4_wmask),
    .toSRAM_4_re (x3_toSRAM_4_re),
    .toSRAM_4_we (x3_toSRAM_4_we),
    .toSRAM_4_ack (x3_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x3_toSRAM_4_selectedOH),
    .toSRAM_4_array (x3_toSRAM_4_array),
    .toSRAM_5_addr (x3_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x3_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x3_toSRAM_5_wdata),
    .toSRAM_5_wmask (x3_toSRAM_5_wmask),
    .toSRAM_5_re (x3_toSRAM_5_re),
    .toSRAM_5_we (x3_toSRAM_5_we),
    .toSRAM_5_ack (x3_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x3_toSRAM_5_selectedOH),
    .toSRAM_5_array (x3_toSRAM_5_array),
    .toSRAM_6_addr (x3_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x3_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x3_toSRAM_6_wdata),
    .toSRAM_6_wmask (x3_toSRAM_6_wmask),
    .toSRAM_6_re (x3_toSRAM_6_re),
    .toSRAM_6_we (x3_toSRAM_6_we),
    .toSRAM_6_ack (x3_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x3_toSRAM_6_selectedOH),
    .toSRAM_6_array (x3_toSRAM_6_array),
    .toSRAM_7_addr (x3_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x3_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x3_toSRAM_7_wdata),
    .toSRAM_7_wmask (x3_toSRAM_7_wmask),
    .toSRAM_7_re (x3_toSRAM_7_re),
    .toSRAM_7_we (x3_toSRAM_7_we),
    .toSRAM_7_ack (x3_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x3_toSRAM_7_selectedOH),
    .toSRAM_7_array (x3_toSRAM_7_array)
  );
  wire [632:0] gbus3 = {g3_mbist_ack, g3_mbist_outdata, g3_toSRAM_0_addr, g3_toSRAM_0_addr_rd, g3_toSRAM_0_wdata, g3_toSRAM_0_wmask, g3_toSRAM_0_re, g3_toSRAM_0_we, g3_toSRAM_0_ack, g3_toSRAM_0_selectedOH, g3_toSRAM_0_array, g3_toSRAM_1_addr, g3_toSRAM_1_addr_rd, g3_toSRAM_1_wdata, g3_toSRAM_1_wmask, g3_toSRAM_1_re, g3_toSRAM_1_we, g3_toSRAM_1_ack, g3_toSRAM_1_selectedOH, g3_toSRAM_1_array, g3_toSRAM_2_addr, g3_toSRAM_2_addr_rd, g3_toSRAM_2_wdata, g3_toSRAM_2_wmask, g3_toSRAM_2_re, g3_toSRAM_2_we, g3_toSRAM_2_ack, g3_toSRAM_2_selectedOH, g3_toSRAM_2_array, g3_toSRAM_3_addr, g3_toSRAM_3_addr_rd, g3_toSRAM_3_wdata, g3_toSRAM_3_wmask, g3_toSRAM_3_re, g3_toSRAM_3_we, g3_toSRAM_3_ack, g3_toSRAM_3_selectedOH, g3_toSRAM_3_array, g3_toSRAM_4_addr, g3_toSRAM_4_addr_rd, g3_toSRAM_4_wdata, g3_toSRAM_4_wmask, g3_toSRAM_4_re, g3_toSRAM_4_we, g3_toSRAM_4_ack, g3_toSRAM_4_selectedOH, g3_toSRAM_4_array, g3_toSRAM_5_addr, g3_toSRAM_5_addr_rd, g3_toSRAM_5_wdata, g3_toSRAM_5_wmask, g3_toSRAM_5_re, g3_toSRAM_5_we, g3_toSRAM_5_ack, g3_toSRAM_5_selectedOH, g3_toSRAM_5_array, g3_toSRAM_6_addr, g3_toSRAM_6_addr_rd, g3_toSRAM_6_wdata, g3_toSRAM_6_wmask, g3_toSRAM_6_re, g3_toSRAM_6_we, g3_toSRAM_6_ack, g3_toSRAM_6_selectedOH, g3_toSRAM_6_array, g3_toSRAM_7_addr, g3_toSRAM_7_addr_rd, g3_toSRAM_7_wdata, g3_toSRAM_7_wmask, g3_toSRAM_7_re, g3_toSRAM_7_we, g3_toSRAM_7_ack, g3_toSRAM_7_selectedOH, g3_toSRAM_7_array};
  wire [632:0] xbus3 = {x3_mbist_ack, x3_mbist_outdata, x3_toSRAM_0_addr, x3_toSRAM_0_addr_rd, x3_toSRAM_0_wdata, x3_toSRAM_0_wmask, x3_toSRAM_0_re, x3_toSRAM_0_we, x3_toSRAM_0_ack, x3_toSRAM_0_selectedOH, x3_toSRAM_0_array, x3_toSRAM_1_addr, x3_toSRAM_1_addr_rd, x3_toSRAM_1_wdata, x3_toSRAM_1_wmask, x3_toSRAM_1_re, x3_toSRAM_1_we, x3_toSRAM_1_ack, x3_toSRAM_1_selectedOH, x3_toSRAM_1_array, x3_toSRAM_2_addr, x3_toSRAM_2_addr_rd, x3_toSRAM_2_wdata, x3_toSRAM_2_wmask, x3_toSRAM_2_re, x3_toSRAM_2_we, x3_toSRAM_2_ack, x3_toSRAM_2_selectedOH, x3_toSRAM_2_array, x3_toSRAM_3_addr, x3_toSRAM_3_addr_rd, x3_toSRAM_3_wdata, x3_toSRAM_3_wmask, x3_toSRAM_3_re, x3_toSRAM_3_we, x3_toSRAM_3_ack, x3_toSRAM_3_selectedOH, x3_toSRAM_3_array, x3_toSRAM_4_addr, x3_toSRAM_4_addr_rd, x3_toSRAM_4_wdata, x3_toSRAM_4_wmask, x3_toSRAM_4_re, x3_toSRAM_4_we, x3_toSRAM_4_ack, x3_toSRAM_4_selectedOH, x3_toSRAM_4_array, x3_toSRAM_5_addr, x3_toSRAM_5_addr_rd, x3_toSRAM_5_wdata, x3_toSRAM_5_wmask, x3_toSRAM_5_re, x3_toSRAM_5_we, x3_toSRAM_5_ack, x3_toSRAM_5_selectedOH, x3_toSRAM_5_array, x3_toSRAM_6_addr, x3_toSRAM_6_addr_rd, x3_toSRAM_6_wdata, x3_toSRAM_6_wmask, x3_toSRAM_6_re, x3_toSRAM_6_we, x3_toSRAM_6_ack, x3_toSRAM_6_selectedOH, x3_toSRAM_6_array, x3_toSRAM_7_addr, x3_toSRAM_7_addr_rd, x3_toSRAM_7_wdata, x3_toSRAM_7_wmask, x3_toSRAM_7_re, x3_toSRAM_7_we, x3_toSRAM_7_ack, x3_toSRAM_7_selectedOH, x3_toSRAM_7_array};
  task automatic detail3();
    if (g3_mbist_ack !== x3_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.mbist_ack golden=%h impl=%h", cyc, g3_mbist_ack, x3_mbist_ack); end
    if (g3_mbist_outdata !== x3_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.mbist_outdata golden=%h impl=%h", cyc, g3_mbist_outdata, x3_mbist_outdata); end
    if (g3_toSRAM_0_addr !== x3_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_addr golden=%h impl=%h", cyc, g3_toSRAM_0_addr, x3_toSRAM_0_addr); end
    if (g3_toSRAM_0_addr_rd !== x3_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_0_addr_rd, x3_toSRAM_0_addr_rd); end
    if (g3_toSRAM_0_wdata !== x3_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_wdata golden=%h impl=%h", cyc, g3_toSRAM_0_wdata, x3_toSRAM_0_wdata); end
    if (g3_toSRAM_0_wmask !== x3_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_wmask golden=%h impl=%h", cyc, g3_toSRAM_0_wmask, x3_toSRAM_0_wmask); end
    if (g3_toSRAM_0_re !== x3_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_re golden=%h impl=%h", cyc, g3_toSRAM_0_re, x3_toSRAM_0_re); end
    if (g3_toSRAM_0_we !== x3_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_we golden=%h impl=%h", cyc, g3_toSRAM_0_we, x3_toSRAM_0_we); end
    if (g3_toSRAM_0_ack !== x3_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_ack golden=%h impl=%h", cyc, g3_toSRAM_0_ack, x3_toSRAM_0_ack); end
    if (g3_toSRAM_0_selectedOH !== x3_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_0_selectedOH, x3_toSRAM_0_selectedOH); end
    if (g3_toSRAM_0_array !== x3_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_0_array golden=%h impl=%h", cyc, g3_toSRAM_0_array, x3_toSRAM_0_array); end
    if (g3_toSRAM_1_addr !== x3_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_addr golden=%h impl=%h", cyc, g3_toSRAM_1_addr, x3_toSRAM_1_addr); end
    if (g3_toSRAM_1_addr_rd !== x3_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_1_addr_rd, x3_toSRAM_1_addr_rd); end
    if (g3_toSRAM_1_wdata !== x3_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_wdata golden=%h impl=%h", cyc, g3_toSRAM_1_wdata, x3_toSRAM_1_wdata); end
    if (g3_toSRAM_1_wmask !== x3_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_wmask golden=%h impl=%h", cyc, g3_toSRAM_1_wmask, x3_toSRAM_1_wmask); end
    if (g3_toSRAM_1_re !== x3_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_re golden=%h impl=%h", cyc, g3_toSRAM_1_re, x3_toSRAM_1_re); end
    if (g3_toSRAM_1_we !== x3_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_we golden=%h impl=%h", cyc, g3_toSRAM_1_we, x3_toSRAM_1_we); end
    if (g3_toSRAM_1_ack !== x3_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_ack golden=%h impl=%h", cyc, g3_toSRAM_1_ack, x3_toSRAM_1_ack); end
    if (g3_toSRAM_1_selectedOH !== x3_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_1_selectedOH, x3_toSRAM_1_selectedOH); end
    if (g3_toSRAM_1_array !== x3_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_1_array golden=%h impl=%h", cyc, g3_toSRAM_1_array, x3_toSRAM_1_array); end
    if (g3_toSRAM_2_addr !== x3_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_addr golden=%h impl=%h", cyc, g3_toSRAM_2_addr, x3_toSRAM_2_addr); end
    if (g3_toSRAM_2_addr_rd !== x3_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_2_addr_rd, x3_toSRAM_2_addr_rd); end
    if (g3_toSRAM_2_wdata !== x3_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_wdata golden=%h impl=%h", cyc, g3_toSRAM_2_wdata, x3_toSRAM_2_wdata); end
    if (g3_toSRAM_2_wmask !== x3_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_wmask golden=%h impl=%h", cyc, g3_toSRAM_2_wmask, x3_toSRAM_2_wmask); end
    if (g3_toSRAM_2_re !== x3_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_re golden=%h impl=%h", cyc, g3_toSRAM_2_re, x3_toSRAM_2_re); end
    if (g3_toSRAM_2_we !== x3_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_we golden=%h impl=%h", cyc, g3_toSRAM_2_we, x3_toSRAM_2_we); end
    if (g3_toSRAM_2_ack !== x3_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_ack golden=%h impl=%h", cyc, g3_toSRAM_2_ack, x3_toSRAM_2_ack); end
    if (g3_toSRAM_2_selectedOH !== x3_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_2_selectedOH, x3_toSRAM_2_selectedOH); end
    if (g3_toSRAM_2_array !== x3_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_2_array golden=%h impl=%h", cyc, g3_toSRAM_2_array, x3_toSRAM_2_array); end
    if (g3_toSRAM_3_addr !== x3_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_addr golden=%h impl=%h", cyc, g3_toSRAM_3_addr, x3_toSRAM_3_addr); end
    if (g3_toSRAM_3_addr_rd !== x3_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_3_addr_rd, x3_toSRAM_3_addr_rd); end
    if (g3_toSRAM_3_wdata !== x3_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_wdata golden=%h impl=%h", cyc, g3_toSRAM_3_wdata, x3_toSRAM_3_wdata); end
    if (g3_toSRAM_3_wmask !== x3_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_wmask golden=%h impl=%h", cyc, g3_toSRAM_3_wmask, x3_toSRAM_3_wmask); end
    if (g3_toSRAM_3_re !== x3_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_re golden=%h impl=%h", cyc, g3_toSRAM_3_re, x3_toSRAM_3_re); end
    if (g3_toSRAM_3_we !== x3_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_we golden=%h impl=%h", cyc, g3_toSRAM_3_we, x3_toSRAM_3_we); end
    if (g3_toSRAM_3_ack !== x3_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_ack golden=%h impl=%h", cyc, g3_toSRAM_3_ack, x3_toSRAM_3_ack); end
    if (g3_toSRAM_3_selectedOH !== x3_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_3_selectedOH, x3_toSRAM_3_selectedOH); end
    if (g3_toSRAM_3_array !== x3_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_3_array golden=%h impl=%h", cyc, g3_toSRAM_3_array, x3_toSRAM_3_array); end
    if (g3_toSRAM_4_addr !== x3_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_addr golden=%h impl=%h", cyc, g3_toSRAM_4_addr, x3_toSRAM_4_addr); end
    if (g3_toSRAM_4_addr_rd !== x3_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_4_addr_rd, x3_toSRAM_4_addr_rd); end
    if (g3_toSRAM_4_wdata !== x3_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_wdata golden=%h impl=%h", cyc, g3_toSRAM_4_wdata, x3_toSRAM_4_wdata); end
    if (g3_toSRAM_4_wmask !== x3_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_wmask golden=%h impl=%h", cyc, g3_toSRAM_4_wmask, x3_toSRAM_4_wmask); end
    if (g3_toSRAM_4_re !== x3_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_re golden=%h impl=%h", cyc, g3_toSRAM_4_re, x3_toSRAM_4_re); end
    if (g3_toSRAM_4_we !== x3_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_we golden=%h impl=%h", cyc, g3_toSRAM_4_we, x3_toSRAM_4_we); end
    if (g3_toSRAM_4_ack !== x3_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_ack golden=%h impl=%h", cyc, g3_toSRAM_4_ack, x3_toSRAM_4_ack); end
    if (g3_toSRAM_4_selectedOH !== x3_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_4_selectedOH, x3_toSRAM_4_selectedOH); end
    if (g3_toSRAM_4_array !== x3_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_4_array golden=%h impl=%h", cyc, g3_toSRAM_4_array, x3_toSRAM_4_array); end
    if (g3_toSRAM_5_addr !== x3_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_addr golden=%h impl=%h", cyc, g3_toSRAM_5_addr, x3_toSRAM_5_addr); end
    if (g3_toSRAM_5_addr_rd !== x3_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_5_addr_rd, x3_toSRAM_5_addr_rd); end
    if (g3_toSRAM_5_wdata !== x3_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_wdata golden=%h impl=%h", cyc, g3_toSRAM_5_wdata, x3_toSRAM_5_wdata); end
    if (g3_toSRAM_5_wmask !== x3_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_wmask golden=%h impl=%h", cyc, g3_toSRAM_5_wmask, x3_toSRAM_5_wmask); end
    if (g3_toSRAM_5_re !== x3_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_re golden=%h impl=%h", cyc, g3_toSRAM_5_re, x3_toSRAM_5_re); end
    if (g3_toSRAM_5_we !== x3_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_we golden=%h impl=%h", cyc, g3_toSRAM_5_we, x3_toSRAM_5_we); end
    if (g3_toSRAM_5_ack !== x3_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_ack golden=%h impl=%h", cyc, g3_toSRAM_5_ack, x3_toSRAM_5_ack); end
    if (g3_toSRAM_5_selectedOH !== x3_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_5_selectedOH, x3_toSRAM_5_selectedOH); end
    if (g3_toSRAM_5_array !== x3_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_5_array golden=%h impl=%h", cyc, g3_toSRAM_5_array, x3_toSRAM_5_array); end
    if (g3_toSRAM_6_addr !== x3_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_addr golden=%h impl=%h", cyc, g3_toSRAM_6_addr, x3_toSRAM_6_addr); end
    if (g3_toSRAM_6_addr_rd !== x3_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_6_addr_rd, x3_toSRAM_6_addr_rd); end
    if (g3_toSRAM_6_wdata !== x3_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_wdata golden=%h impl=%h", cyc, g3_toSRAM_6_wdata, x3_toSRAM_6_wdata); end
    if (g3_toSRAM_6_wmask !== x3_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_wmask golden=%h impl=%h", cyc, g3_toSRAM_6_wmask, x3_toSRAM_6_wmask); end
    if (g3_toSRAM_6_re !== x3_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_re golden=%h impl=%h", cyc, g3_toSRAM_6_re, x3_toSRAM_6_re); end
    if (g3_toSRAM_6_we !== x3_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_we golden=%h impl=%h", cyc, g3_toSRAM_6_we, x3_toSRAM_6_we); end
    if (g3_toSRAM_6_ack !== x3_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_ack golden=%h impl=%h", cyc, g3_toSRAM_6_ack, x3_toSRAM_6_ack); end
    if (g3_toSRAM_6_selectedOH !== x3_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_6_selectedOH, x3_toSRAM_6_selectedOH); end
    if (g3_toSRAM_6_array !== x3_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_6_array golden=%h impl=%h", cyc, g3_toSRAM_6_array, x3_toSRAM_6_array); end
    if (g3_toSRAM_7_addr !== x3_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_addr golden=%h impl=%h", cyc, g3_toSRAM_7_addr, x3_toSRAM_7_addr); end
    if (g3_toSRAM_7_addr_rd !== x3_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g3_toSRAM_7_addr_rd, x3_toSRAM_7_addr_rd); end
    if (g3_toSRAM_7_wdata !== x3_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_wdata golden=%h impl=%h", cyc, g3_toSRAM_7_wdata, x3_toSRAM_7_wdata); end
    if (g3_toSRAM_7_wmask !== x3_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_wmask golden=%h impl=%h", cyc, g3_toSRAM_7_wmask, x3_toSRAM_7_wmask); end
    if (g3_toSRAM_7_re !== x3_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_re golden=%h impl=%h", cyc, g3_toSRAM_7_re, x3_toSRAM_7_re); end
    if (g3_toSRAM_7_we !== x3_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_we golden=%h impl=%h", cyc, g3_toSRAM_7_we, x3_toSRAM_7_we); end
    if (g3_toSRAM_7_ack !== x3_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_ack golden=%h impl=%h", cyc, g3_toSRAM_7_ack, x3_toSRAM_7_ack); end
    if (g3_toSRAM_7_selectedOH !== x3_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g3_toSRAM_7_selectedOH, x3_toSRAM_7_selectedOH); end
    if (g3_toSRAM_7_array !== x3_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeFtb.toSRAM_7_array golden=%h impl=%h", cyc, g3_toSRAM_7_array, x3_toSRAM_7_array); end
  endtask

  // ======================== [04] MbistPipeIcacheDataWay0 ========================
  logic [65:0] v4_rd0;
  logic [65:0] v4_rd1;
  logic [65:0] v4_rd2;
  logic [65:0] v4_rd3;
  logic [65:0] v4_rd4;
  logic [65:0] v4_rd5;
  logic [65:0] v4_rd6;
  logic [65:0] v4_rd7;
  logic g4_mbist_ack;
  logic [65:0] g4_mbist_outdata;
  logic [8:0] g4_toSRAM_0_addr;
  logic [8:0] g4_toSRAM_0_addr_rd;
  logic [65:0] g4_toSRAM_0_wdata;
  logic g4_toSRAM_0_wmask;
  logic g4_toSRAM_0_re;
  logic g4_toSRAM_0_we;
  logic g4_toSRAM_0_ack;
  logic g4_toSRAM_0_selectedOH;
  logic [2:0] g4_toSRAM_0_array;
  logic [8:0] g4_toSRAM_1_addr;
  logic [8:0] g4_toSRAM_1_addr_rd;
  logic [65:0] g4_toSRAM_1_wdata;
  logic g4_toSRAM_1_wmask;
  logic g4_toSRAM_1_re;
  logic g4_toSRAM_1_we;
  logic g4_toSRAM_1_ack;
  logic g4_toSRAM_1_selectedOH;
  logic [2:0] g4_toSRAM_1_array;
  logic [8:0] g4_toSRAM_2_addr;
  logic [8:0] g4_toSRAM_2_addr_rd;
  logic [65:0] g4_toSRAM_2_wdata;
  logic g4_toSRAM_2_wmask;
  logic g4_toSRAM_2_re;
  logic g4_toSRAM_2_we;
  logic g4_toSRAM_2_ack;
  logic g4_toSRAM_2_selectedOH;
  logic [2:0] g4_toSRAM_2_array;
  logic [8:0] g4_toSRAM_3_addr;
  logic [8:0] g4_toSRAM_3_addr_rd;
  logic [65:0] g4_toSRAM_3_wdata;
  logic g4_toSRAM_3_wmask;
  logic g4_toSRAM_3_re;
  logic g4_toSRAM_3_we;
  logic g4_toSRAM_3_ack;
  logic g4_toSRAM_3_selectedOH;
  logic [2:0] g4_toSRAM_3_array;
  logic [8:0] g4_toSRAM_4_addr;
  logic [8:0] g4_toSRAM_4_addr_rd;
  logic [65:0] g4_toSRAM_4_wdata;
  logic g4_toSRAM_4_wmask;
  logic g4_toSRAM_4_re;
  logic g4_toSRAM_4_we;
  logic g4_toSRAM_4_ack;
  logic g4_toSRAM_4_selectedOH;
  logic [3:0] g4_toSRAM_4_array;
  logic [8:0] g4_toSRAM_5_addr;
  logic [8:0] g4_toSRAM_5_addr_rd;
  logic [65:0] g4_toSRAM_5_wdata;
  logic g4_toSRAM_5_wmask;
  logic g4_toSRAM_5_re;
  logic g4_toSRAM_5_we;
  logic g4_toSRAM_5_ack;
  logic g4_toSRAM_5_selectedOH;
  logic [3:0] g4_toSRAM_5_array;
  logic [8:0] g4_toSRAM_6_addr;
  logic [8:0] g4_toSRAM_6_addr_rd;
  logic [65:0] g4_toSRAM_6_wdata;
  logic g4_toSRAM_6_wmask;
  logic g4_toSRAM_6_re;
  logic g4_toSRAM_6_we;
  logic g4_toSRAM_6_ack;
  logic g4_toSRAM_6_selectedOH;
  logic [3:0] g4_toSRAM_6_array;
  logic [8:0] g4_toSRAM_7_addr;
  logic [8:0] g4_toSRAM_7_addr_rd;
  logic [65:0] g4_toSRAM_7_wdata;
  logic g4_toSRAM_7_wmask;
  logic g4_toSRAM_7_re;
  logic g4_toSRAM_7_we;
  logic g4_toSRAM_7_ack;
  logic g4_toSRAM_7_selectedOH;
  logic [3:0] g4_toSRAM_7_array;
  logic x4_mbist_ack;
  logic [65:0] x4_mbist_outdata;
  logic [8:0] x4_toSRAM_0_addr;
  logic [8:0] x4_toSRAM_0_addr_rd;
  logic [65:0] x4_toSRAM_0_wdata;
  logic x4_toSRAM_0_wmask;
  logic x4_toSRAM_0_re;
  logic x4_toSRAM_0_we;
  logic x4_toSRAM_0_ack;
  logic x4_toSRAM_0_selectedOH;
  logic [2:0] x4_toSRAM_0_array;
  logic [8:0] x4_toSRAM_1_addr;
  logic [8:0] x4_toSRAM_1_addr_rd;
  logic [65:0] x4_toSRAM_1_wdata;
  logic x4_toSRAM_1_wmask;
  logic x4_toSRAM_1_re;
  logic x4_toSRAM_1_we;
  logic x4_toSRAM_1_ack;
  logic x4_toSRAM_1_selectedOH;
  logic [2:0] x4_toSRAM_1_array;
  logic [8:0] x4_toSRAM_2_addr;
  logic [8:0] x4_toSRAM_2_addr_rd;
  logic [65:0] x4_toSRAM_2_wdata;
  logic x4_toSRAM_2_wmask;
  logic x4_toSRAM_2_re;
  logic x4_toSRAM_2_we;
  logic x4_toSRAM_2_ack;
  logic x4_toSRAM_2_selectedOH;
  logic [2:0] x4_toSRAM_2_array;
  logic [8:0] x4_toSRAM_3_addr;
  logic [8:0] x4_toSRAM_3_addr_rd;
  logic [65:0] x4_toSRAM_3_wdata;
  logic x4_toSRAM_3_wmask;
  logic x4_toSRAM_3_re;
  logic x4_toSRAM_3_we;
  logic x4_toSRAM_3_ack;
  logic x4_toSRAM_3_selectedOH;
  logic [2:0] x4_toSRAM_3_array;
  logic [8:0] x4_toSRAM_4_addr;
  logic [8:0] x4_toSRAM_4_addr_rd;
  logic [65:0] x4_toSRAM_4_wdata;
  logic x4_toSRAM_4_wmask;
  logic x4_toSRAM_4_re;
  logic x4_toSRAM_4_we;
  logic x4_toSRAM_4_ack;
  logic x4_toSRAM_4_selectedOH;
  logic [3:0] x4_toSRAM_4_array;
  logic [8:0] x4_toSRAM_5_addr;
  logic [8:0] x4_toSRAM_5_addr_rd;
  logic [65:0] x4_toSRAM_5_wdata;
  logic x4_toSRAM_5_wmask;
  logic x4_toSRAM_5_re;
  logic x4_toSRAM_5_we;
  logic x4_toSRAM_5_ack;
  logic x4_toSRAM_5_selectedOH;
  logic [3:0] x4_toSRAM_5_array;
  logic [8:0] x4_toSRAM_6_addr;
  logic [8:0] x4_toSRAM_6_addr_rd;
  logic [65:0] x4_toSRAM_6_wdata;
  logic x4_toSRAM_6_wmask;
  logic x4_toSRAM_6_re;
  logic x4_toSRAM_6_we;
  logic x4_toSRAM_6_ack;
  logic x4_toSRAM_6_selectedOH;
  logic [3:0] x4_toSRAM_6_array;
  logic [8:0] x4_toSRAM_7_addr;
  logic [8:0] x4_toSRAM_7_addr_rd;
  logic [65:0] x4_toSRAM_7_wdata;
  logic x4_toSRAM_7_wmask;
  logic x4_toSRAM_7_re;
  logic x4_toSRAM_7_we;
  logic x4_toSRAM_7_ack;
  logic x4_toSRAM_7_selectedOH;
  logic [3:0] x4_toSRAM_7_array;
  bit [7:0] cov_spread4;
  bit [65:0] cov_od0_4, cov_od1_4;
  bit cov_ack0_4, cov_ack1_4;
  MbistPipeIcacheDataWay0 u_g4 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[3:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v4_rd0),
    .toSRAM_1_rdata (v4_rd1),
    .toSRAM_2_rdata (v4_rd2),
    .toSRAM_3_rdata (v4_rd3),
    .toSRAM_4_rdata (v4_rd4),
    .toSRAM_5_rdata (v4_rd5),
    .toSRAM_6_rdata (v4_rd6),
    .toSRAM_7_rdata (v4_rd7),
    .mbist_ack (g4_mbist_ack),
    .mbist_outdata (g4_mbist_outdata),
    .toSRAM_0_addr (g4_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g4_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g4_toSRAM_0_wdata),
    .toSRAM_0_wmask (g4_toSRAM_0_wmask),
    .toSRAM_0_re (g4_toSRAM_0_re),
    .toSRAM_0_we (g4_toSRAM_0_we),
    .toSRAM_0_ack (g4_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g4_toSRAM_0_selectedOH),
    .toSRAM_0_array (g4_toSRAM_0_array),
    .toSRAM_1_addr (g4_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g4_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g4_toSRAM_1_wdata),
    .toSRAM_1_wmask (g4_toSRAM_1_wmask),
    .toSRAM_1_re (g4_toSRAM_1_re),
    .toSRAM_1_we (g4_toSRAM_1_we),
    .toSRAM_1_ack (g4_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g4_toSRAM_1_selectedOH),
    .toSRAM_1_array (g4_toSRAM_1_array),
    .toSRAM_2_addr (g4_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g4_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g4_toSRAM_2_wdata),
    .toSRAM_2_wmask (g4_toSRAM_2_wmask),
    .toSRAM_2_re (g4_toSRAM_2_re),
    .toSRAM_2_we (g4_toSRAM_2_we),
    .toSRAM_2_ack (g4_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g4_toSRAM_2_selectedOH),
    .toSRAM_2_array (g4_toSRAM_2_array),
    .toSRAM_3_addr (g4_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g4_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g4_toSRAM_3_wdata),
    .toSRAM_3_wmask (g4_toSRAM_3_wmask),
    .toSRAM_3_re (g4_toSRAM_3_re),
    .toSRAM_3_we (g4_toSRAM_3_we),
    .toSRAM_3_ack (g4_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g4_toSRAM_3_selectedOH),
    .toSRAM_3_array (g4_toSRAM_3_array),
    .toSRAM_4_addr (g4_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g4_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g4_toSRAM_4_wdata),
    .toSRAM_4_wmask (g4_toSRAM_4_wmask),
    .toSRAM_4_re (g4_toSRAM_4_re),
    .toSRAM_4_we (g4_toSRAM_4_we),
    .toSRAM_4_ack (g4_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g4_toSRAM_4_selectedOH),
    .toSRAM_4_array (g4_toSRAM_4_array),
    .toSRAM_5_addr (g4_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g4_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g4_toSRAM_5_wdata),
    .toSRAM_5_wmask (g4_toSRAM_5_wmask),
    .toSRAM_5_re (g4_toSRAM_5_re),
    .toSRAM_5_we (g4_toSRAM_5_we),
    .toSRAM_5_ack (g4_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g4_toSRAM_5_selectedOH),
    .toSRAM_5_array (g4_toSRAM_5_array),
    .toSRAM_6_addr (g4_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g4_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g4_toSRAM_6_wdata),
    .toSRAM_6_wmask (g4_toSRAM_6_wmask),
    .toSRAM_6_re (g4_toSRAM_6_re),
    .toSRAM_6_we (g4_toSRAM_6_we),
    .toSRAM_6_ack (g4_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g4_toSRAM_6_selectedOH),
    .toSRAM_6_array (g4_toSRAM_6_array),
    .toSRAM_7_addr (g4_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g4_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g4_toSRAM_7_wdata),
    .toSRAM_7_wmask (g4_toSRAM_7_wmask),
    .toSRAM_7_re (g4_toSRAM_7_re),
    .toSRAM_7_we (g4_toSRAM_7_we),
    .toSRAM_7_ack (g4_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g4_toSRAM_7_selectedOH),
    .toSRAM_7_array (g4_toSRAM_7_array)
  );
  MbistPipeIcacheDataWay0_xs u_x4 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[3:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v4_rd0),
    .toSRAM_1_rdata (v4_rd1),
    .toSRAM_2_rdata (v4_rd2),
    .toSRAM_3_rdata (v4_rd3),
    .toSRAM_4_rdata (v4_rd4),
    .toSRAM_5_rdata (v4_rd5),
    .toSRAM_6_rdata (v4_rd6),
    .toSRAM_7_rdata (v4_rd7),
    .mbist_ack (x4_mbist_ack),
    .mbist_outdata (x4_mbist_outdata),
    .toSRAM_0_addr (x4_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x4_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x4_toSRAM_0_wdata),
    .toSRAM_0_wmask (x4_toSRAM_0_wmask),
    .toSRAM_0_re (x4_toSRAM_0_re),
    .toSRAM_0_we (x4_toSRAM_0_we),
    .toSRAM_0_ack (x4_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x4_toSRAM_0_selectedOH),
    .toSRAM_0_array (x4_toSRAM_0_array),
    .toSRAM_1_addr (x4_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x4_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x4_toSRAM_1_wdata),
    .toSRAM_1_wmask (x4_toSRAM_1_wmask),
    .toSRAM_1_re (x4_toSRAM_1_re),
    .toSRAM_1_we (x4_toSRAM_1_we),
    .toSRAM_1_ack (x4_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x4_toSRAM_1_selectedOH),
    .toSRAM_1_array (x4_toSRAM_1_array),
    .toSRAM_2_addr (x4_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x4_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x4_toSRAM_2_wdata),
    .toSRAM_2_wmask (x4_toSRAM_2_wmask),
    .toSRAM_2_re (x4_toSRAM_2_re),
    .toSRAM_2_we (x4_toSRAM_2_we),
    .toSRAM_2_ack (x4_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x4_toSRAM_2_selectedOH),
    .toSRAM_2_array (x4_toSRAM_2_array),
    .toSRAM_3_addr (x4_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x4_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x4_toSRAM_3_wdata),
    .toSRAM_3_wmask (x4_toSRAM_3_wmask),
    .toSRAM_3_re (x4_toSRAM_3_re),
    .toSRAM_3_we (x4_toSRAM_3_we),
    .toSRAM_3_ack (x4_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x4_toSRAM_3_selectedOH),
    .toSRAM_3_array (x4_toSRAM_3_array),
    .toSRAM_4_addr (x4_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x4_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x4_toSRAM_4_wdata),
    .toSRAM_4_wmask (x4_toSRAM_4_wmask),
    .toSRAM_4_re (x4_toSRAM_4_re),
    .toSRAM_4_we (x4_toSRAM_4_we),
    .toSRAM_4_ack (x4_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x4_toSRAM_4_selectedOH),
    .toSRAM_4_array (x4_toSRAM_4_array),
    .toSRAM_5_addr (x4_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x4_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x4_toSRAM_5_wdata),
    .toSRAM_5_wmask (x4_toSRAM_5_wmask),
    .toSRAM_5_re (x4_toSRAM_5_re),
    .toSRAM_5_we (x4_toSRAM_5_we),
    .toSRAM_5_ack (x4_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x4_toSRAM_5_selectedOH),
    .toSRAM_5_array (x4_toSRAM_5_array),
    .toSRAM_6_addr (x4_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x4_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x4_toSRAM_6_wdata),
    .toSRAM_6_wmask (x4_toSRAM_6_wmask),
    .toSRAM_6_re (x4_toSRAM_6_re),
    .toSRAM_6_we (x4_toSRAM_6_we),
    .toSRAM_6_ack (x4_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x4_toSRAM_6_selectedOH),
    .toSRAM_6_array (x4_toSRAM_6_array),
    .toSRAM_7_addr (x4_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x4_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x4_toSRAM_7_wdata),
    .toSRAM_7_wmask (x4_toSRAM_7_wmask),
    .toSRAM_7_re (x4_toSRAM_7_re),
    .toSRAM_7_we (x4_toSRAM_7_we),
    .toSRAM_7_ack (x4_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x4_toSRAM_7_selectedOH),
    .toSRAM_7_array (x4_toSRAM_7_array)
  );
  wire [806:0] gbus4 = {g4_mbist_ack, g4_mbist_outdata, g4_toSRAM_0_addr, g4_toSRAM_0_addr_rd, g4_toSRAM_0_wdata, g4_toSRAM_0_wmask, g4_toSRAM_0_re, g4_toSRAM_0_we, g4_toSRAM_0_ack, g4_toSRAM_0_selectedOH, g4_toSRAM_0_array, g4_toSRAM_1_addr, g4_toSRAM_1_addr_rd, g4_toSRAM_1_wdata, g4_toSRAM_1_wmask, g4_toSRAM_1_re, g4_toSRAM_1_we, g4_toSRAM_1_ack, g4_toSRAM_1_selectedOH, g4_toSRAM_1_array, g4_toSRAM_2_addr, g4_toSRAM_2_addr_rd, g4_toSRAM_2_wdata, g4_toSRAM_2_wmask, g4_toSRAM_2_re, g4_toSRAM_2_we, g4_toSRAM_2_ack, g4_toSRAM_2_selectedOH, g4_toSRAM_2_array, g4_toSRAM_3_addr, g4_toSRAM_3_addr_rd, g4_toSRAM_3_wdata, g4_toSRAM_3_wmask, g4_toSRAM_3_re, g4_toSRAM_3_we, g4_toSRAM_3_ack, g4_toSRAM_3_selectedOH, g4_toSRAM_3_array, g4_toSRAM_4_addr, g4_toSRAM_4_addr_rd, g4_toSRAM_4_wdata, g4_toSRAM_4_wmask, g4_toSRAM_4_re, g4_toSRAM_4_we, g4_toSRAM_4_ack, g4_toSRAM_4_selectedOH, g4_toSRAM_4_array, g4_toSRAM_5_addr, g4_toSRAM_5_addr_rd, g4_toSRAM_5_wdata, g4_toSRAM_5_wmask, g4_toSRAM_5_re, g4_toSRAM_5_we, g4_toSRAM_5_ack, g4_toSRAM_5_selectedOH, g4_toSRAM_5_array, g4_toSRAM_6_addr, g4_toSRAM_6_addr_rd, g4_toSRAM_6_wdata, g4_toSRAM_6_wmask, g4_toSRAM_6_re, g4_toSRAM_6_we, g4_toSRAM_6_ack, g4_toSRAM_6_selectedOH, g4_toSRAM_6_array, g4_toSRAM_7_addr, g4_toSRAM_7_addr_rd, g4_toSRAM_7_wdata, g4_toSRAM_7_wmask, g4_toSRAM_7_re, g4_toSRAM_7_we, g4_toSRAM_7_ack, g4_toSRAM_7_selectedOH, g4_toSRAM_7_array};
  wire [806:0] xbus4 = {x4_mbist_ack, x4_mbist_outdata, x4_toSRAM_0_addr, x4_toSRAM_0_addr_rd, x4_toSRAM_0_wdata, x4_toSRAM_0_wmask, x4_toSRAM_0_re, x4_toSRAM_0_we, x4_toSRAM_0_ack, x4_toSRAM_0_selectedOH, x4_toSRAM_0_array, x4_toSRAM_1_addr, x4_toSRAM_1_addr_rd, x4_toSRAM_1_wdata, x4_toSRAM_1_wmask, x4_toSRAM_1_re, x4_toSRAM_1_we, x4_toSRAM_1_ack, x4_toSRAM_1_selectedOH, x4_toSRAM_1_array, x4_toSRAM_2_addr, x4_toSRAM_2_addr_rd, x4_toSRAM_2_wdata, x4_toSRAM_2_wmask, x4_toSRAM_2_re, x4_toSRAM_2_we, x4_toSRAM_2_ack, x4_toSRAM_2_selectedOH, x4_toSRAM_2_array, x4_toSRAM_3_addr, x4_toSRAM_3_addr_rd, x4_toSRAM_3_wdata, x4_toSRAM_3_wmask, x4_toSRAM_3_re, x4_toSRAM_3_we, x4_toSRAM_3_ack, x4_toSRAM_3_selectedOH, x4_toSRAM_3_array, x4_toSRAM_4_addr, x4_toSRAM_4_addr_rd, x4_toSRAM_4_wdata, x4_toSRAM_4_wmask, x4_toSRAM_4_re, x4_toSRAM_4_we, x4_toSRAM_4_ack, x4_toSRAM_4_selectedOH, x4_toSRAM_4_array, x4_toSRAM_5_addr, x4_toSRAM_5_addr_rd, x4_toSRAM_5_wdata, x4_toSRAM_5_wmask, x4_toSRAM_5_re, x4_toSRAM_5_we, x4_toSRAM_5_ack, x4_toSRAM_5_selectedOH, x4_toSRAM_5_array, x4_toSRAM_6_addr, x4_toSRAM_6_addr_rd, x4_toSRAM_6_wdata, x4_toSRAM_6_wmask, x4_toSRAM_6_re, x4_toSRAM_6_we, x4_toSRAM_6_ack, x4_toSRAM_6_selectedOH, x4_toSRAM_6_array, x4_toSRAM_7_addr, x4_toSRAM_7_addr_rd, x4_toSRAM_7_wdata, x4_toSRAM_7_wmask, x4_toSRAM_7_re, x4_toSRAM_7_we, x4_toSRAM_7_ack, x4_toSRAM_7_selectedOH, x4_toSRAM_7_array};
  task automatic detail4();
    if (g4_mbist_ack !== x4_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.mbist_ack golden=%h impl=%h", cyc, g4_mbist_ack, x4_mbist_ack); end
    if (g4_mbist_outdata !== x4_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.mbist_outdata golden=%h impl=%h", cyc, g4_mbist_outdata, x4_mbist_outdata); end
    if (g4_toSRAM_0_addr !== x4_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_addr golden=%h impl=%h", cyc, g4_toSRAM_0_addr, x4_toSRAM_0_addr); end
    if (g4_toSRAM_0_addr_rd !== x4_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_0_addr_rd, x4_toSRAM_0_addr_rd); end
    if (g4_toSRAM_0_wdata !== x4_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_wdata golden=%h impl=%h", cyc, g4_toSRAM_0_wdata, x4_toSRAM_0_wdata); end
    if (g4_toSRAM_0_wmask !== x4_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_wmask golden=%h impl=%h", cyc, g4_toSRAM_0_wmask, x4_toSRAM_0_wmask); end
    if (g4_toSRAM_0_re !== x4_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_re golden=%h impl=%h", cyc, g4_toSRAM_0_re, x4_toSRAM_0_re); end
    if (g4_toSRAM_0_we !== x4_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_we golden=%h impl=%h", cyc, g4_toSRAM_0_we, x4_toSRAM_0_we); end
    if (g4_toSRAM_0_ack !== x4_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_ack golden=%h impl=%h", cyc, g4_toSRAM_0_ack, x4_toSRAM_0_ack); end
    if (g4_toSRAM_0_selectedOH !== x4_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_0_selectedOH, x4_toSRAM_0_selectedOH); end
    if (g4_toSRAM_0_array !== x4_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_0_array golden=%h impl=%h", cyc, g4_toSRAM_0_array, x4_toSRAM_0_array); end
    if (g4_toSRAM_1_addr !== x4_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_addr golden=%h impl=%h", cyc, g4_toSRAM_1_addr, x4_toSRAM_1_addr); end
    if (g4_toSRAM_1_addr_rd !== x4_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_1_addr_rd, x4_toSRAM_1_addr_rd); end
    if (g4_toSRAM_1_wdata !== x4_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_wdata golden=%h impl=%h", cyc, g4_toSRAM_1_wdata, x4_toSRAM_1_wdata); end
    if (g4_toSRAM_1_wmask !== x4_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_wmask golden=%h impl=%h", cyc, g4_toSRAM_1_wmask, x4_toSRAM_1_wmask); end
    if (g4_toSRAM_1_re !== x4_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_re golden=%h impl=%h", cyc, g4_toSRAM_1_re, x4_toSRAM_1_re); end
    if (g4_toSRAM_1_we !== x4_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_we golden=%h impl=%h", cyc, g4_toSRAM_1_we, x4_toSRAM_1_we); end
    if (g4_toSRAM_1_ack !== x4_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_ack golden=%h impl=%h", cyc, g4_toSRAM_1_ack, x4_toSRAM_1_ack); end
    if (g4_toSRAM_1_selectedOH !== x4_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_1_selectedOH, x4_toSRAM_1_selectedOH); end
    if (g4_toSRAM_1_array !== x4_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_1_array golden=%h impl=%h", cyc, g4_toSRAM_1_array, x4_toSRAM_1_array); end
    if (g4_toSRAM_2_addr !== x4_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_addr golden=%h impl=%h", cyc, g4_toSRAM_2_addr, x4_toSRAM_2_addr); end
    if (g4_toSRAM_2_addr_rd !== x4_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_2_addr_rd, x4_toSRAM_2_addr_rd); end
    if (g4_toSRAM_2_wdata !== x4_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_wdata golden=%h impl=%h", cyc, g4_toSRAM_2_wdata, x4_toSRAM_2_wdata); end
    if (g4_toSRAM_2_wmask !== x4_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_wmask golden=%h impl=%h", cyc, g4_toSRAM_2_wmask, x4_toSRAM_2_wmask); end
    if (g4_toSRAM_2_re !== x4_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_re golden=%h impl=%h", cyc, g4_toSRAM_2_re, x4_toSRAM_2_re); end
    if (g4_toSRAM_2_we !== x4_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_we golden=%h impl=%h", cyc, g4_toSRAM_2_we, x4_toSRAM_2_we); end
    if (g4_toSRAM_2_ack !== x4_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_ack golden=%h impl=%h", cyc, g4_toSRAM_2_ack, x4_toSRAM_2_ack); end
    if (g4_toSRAM_2_selectedOH !== x4_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_2_selectedOH, x4_toSRAM_2_selectedOH); end
    if (g4_toSRAM_2_array !== x4_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_2_array golden=%h impl=%h", cyc, g4_toSRAM_2_array, x4_toSRAM_2_array); end
    if (g4_toSRAM_3_addr !== x4_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_addr golden=%h impl=%h", cyc, g4_toSRAM_3_addr, x4_toSRAM_3_addr); end
    if (g4_toSRAM_3_addr_rd !== x4_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_3_addr_rd, x4_toSRAM_3_addr_rd); end
    if (g4_toSRAM_3_wdata !== x4_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_wdata golden=%h impl=%h", cyc, g4_toSRAM_3_wdata, x4_toSRAM_3_wdata); end
    if (g4_toSRAM_3_wmask !== x4_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_wmask golden=%h impl=%h", cyc, g4_toSRAM_3_wmask, x4_toSRAM_3_wmask); end
    if (g4_toSRAM_3_re !== x4_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_re golden=%h impl=%h", cyc, g4_toSRAM_3_re, x4_toSRAM_3_re); end
    if (g4_toSRAM_3_we !== x4_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_we golden=%h impl=%h", cyc, g4_toSRAM_3_we, x4_toSRAM_3_we); end
    if (g4_toSRAM_3_ack !== x4_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_ack golden=%h impl=%h", cyc, g4_toSRAM_3_ack, x4_toSRAM_3_ack); end
    if (g4_toSRAM_3_selectedOH !== x4_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_3_selectedOH, x4_toSRAM_3_selectedOH); end
    if (g4_toSRAM_3_array !== x4_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_3_array golden=%h impl=%h", cyc, g4_toSRAM_3_array, x4_toSRAM_3_array); end
    if (g4_toSRAM_4_addr !== x4_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_addr golden=%h impl=%h", cyc, g4_toSRAM_4_addr, x4_toSRAM_4_addr); end
    if (g4_toSRAM_4_addr_rd !== x4_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_4_addr_rd, x4_toSRAM_4_addr_rd); end
    if (g4_toSRAM_4_wdata !== x4_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_wdata golden=%h impl=%h", cyc, g4_toSRAM_4_wdata, x4_toSRAM_4_wdata); end
    if (g4_toSRAM_4_wmask !== x4_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_wmask golden=%h impl=%h", cyc, g4_toSRAM_4_wmask, x4_toSRAM_4_wmask); end
    if (g4_toSRAM_4_re !== x4_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_re golden=%h impl=%h", cyc, g4_toSRAM_4_re, x4_toSRAM_4_re); end
    if (g4_toSRAM_4_we !== x4_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_we golden=%h impl=%h", cyc, g4_toSRAM_4_we, x4_toSRAM_4_we); end
    if (g4_toSRAM_4_ack !== x4_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_ack golden=%h impl=%h", cyc, g4_toSRAM_4_ack, x4_toSRAM_4_ack); end
    if (g4_toSRAM_4_selectedOH !== x4_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_4_selectedOH, x4_toSRAM_4_selectedOH); end
    if (g4_toSRAM_4_array !== x4_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_4_array golden=%h impl=%h", cyc, g4_toSRAM_4_array, x4_toSRAM_4_array); end
    if (g4_toSRAM_5_addr !== x4_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_addr golden=%h impl=%h", cyc, g4_toSRAM_5_addr, x4_toSRAM_5_addr); end
    if (g4_toSRAM_5_addr_rd !== x4_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_5_addr_rd, x4_toSRAM_5_addr_rd); end
    if (g4_toSRAM_5_wdata !== x4_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_wdata golden=%h impl=%h", cyc, g4_toSRAM_5_wdata, x4_toSRAM_5_wdata); end
    if (g4_toSRAM_5_wmask !== x4_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_wmask golden=%h impl=%h", cyc, g4_toSRAM_5_wmask, x4_toSRAM_5_wmask); end
    if (g4_toSRAM_5_re !== x4_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_re golden=%h impl=%h", cyc, g4_toSRAM_5_re, x4_toSRAM_5_re); end
    if (g4_toSRAM_5_we !== x4_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_we golden=%h impl=%h", cyc, g4_toSRAM_5_we, x4_toSRAM_5_we); end
    if (g4_toSRAM_5_ack !== x4_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_ack golden=%h impl=%h", cyc, g4_toSRAM_5_ack, x4_toSRAM_5_ack); end
    if (g4_toSRAM_5_selectedOH !== x4_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_5_selectedOH, x4_toSRAM_5_selectedOH); end
    if (g4_toSRAM_5_array !== x4_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_5_array golden=%h impl=%h", cyc, g4_toSRAM_5_array, x4_toSRAM_5_array); end
    if (g4_toSRAM_6_addr !== x4_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_addr golden=%h impl=%h", cyc, g4_toSRAM_6_addr, x4_toSRAM_6_addr); end
    if (g4_toSRAM_6_addr_rd !== x4_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_6_addr_rd, x4_toSRAM_6_addr_rd); end
    if (g4_toSRAM_6_wdata !== x4_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_wdata golden=%h impl=%h", cyc, g4_toSRAM_6_wdata, x4_toSRAM_6_wdata); end
    if (g4_toSRAM_6_wmask !== x4_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_wmask golden=%h impl=%h", cyc, g4_toSRAM_6_wmask, x4_toSRAM_6_wmask); end
    if (g4_toSRAM_6_re !== x4_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_re golden=%h impl=%h", cyc, g4_toSRAM_6_re, x4_toSRAM_6_re); end
    if (g4_toSRAM_6_we !== x4_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_we golden=%h impl=%h", cyc, g4_toSRAM_6_we, x4_toSRAM_6_we); end
    if (g4_toSRAM_6_ack !== x4_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_ack golden=%h impl=%h", cyc, g4_toSRAM_6_ack, x4_toSRAM_6_ack); end
    if (g4_toSRAM_6_selectedOH !== x4_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_6_selectedOH, x4_toSRAM_6_selectedOH); end
    if (g4_toSRAM_6_array !== x4_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_6_array golden=%h impl=%h", cyc, g4_toSRAM_6_array, x4_toSRAM_6_array); end
    if (g4_toSRAM_7_addr !== x4_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_addr golden=%h impl=%h", cyc, g4_toSRAM_7_addr, x4_toSRAM_7_addr); end
    if (g4_toSRAM_7_addr_rd !== x4_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g4_toSRAM_7_addr_rd, x4_toSRAM_7_addr_rd); end
    if (g4_toSRAM_7_wdata !== x4_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_wdata golden=%h impl=%h", cyc, g4_toSRAM_7_wdata, x4_toSRAM_7_wdata); end
    if (g4_toSRAM_7_wmask !== x4_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_wmask golden=%h impl=%h", cyc, g4_toSRAM_7_wmask, x4_toSRAM_7_wmask); end
    if (g4_toSRAM_7_re !== x4_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_re golden=%h impl=%h", cyc, g4_toSRAM_7_re, x4_toSRAM_7_re); end
    if (g4_toSRAM_7_we !== x4_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_we golden=%h impl=%h", cyc, g4_toSRAM_7_we, x4_toSRAM_7_we); end
    if (g4_toSRAM_7_ack !== x4_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_ack golden=%h impl=%h", cyc, g4_toSRAM_7_ack, x4_toSRAM_7_ack); end
    if (g4_toSRAM_7_selectedOH !== x4_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g4_toSRAM_7_selectedOH, x4_toSRAM_7_selectedOH); end
    if (g4_toSRAM_7_array !== x4_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay0.toSRAM_7_array golden=%h impl=%h", cyc, g4_toSRAM_7_array, x4_toSRAM_7_array); end
  endtask

  // ======================== [05] MbistPipeIcacheDataWay1 ========================
  logic [65:0] v5_rd0;
  logic [65:0] v5_rd1;
  logic [65:0] v5_rd2;
  logic [65:0] v5_rd3;
  logic [65:0] v5_rd4;
  logic [65:0] v5_rd5;
  logic [65:0] v5_rd6;
  logic [65:0] v5_rd7;
  logic g5_mbist_ack;
  logic [65:0] g5_mbist_outdata;
  logic [8:0] g5_toSRAM_0_addr;
  logic [8:0] g5_toSRAM_0_addr_rd;
  logic [65:0] g5_toSRAM_0_wdata;
  logic g5_toSRAM_0_wmask;
  logic g5_toSRAM_0_re;
  logic g5_toSRAM_0_we;
  logic g5_toSRAM_0_ack;
  logic g5_toSRAM_0_selectedOH;
  logic [3:0] g5_toSRAM_0_array;
  logic [8:0] g5_toSRAM_1_addr;
  logic [8:0] g5_toSRAM_1_addr_rd;
  logic [65:0] g5_toSRAM_1_wdata;
  logic g5_toSRAM_1_wmask;
  logic g5_toSRAM_1_re;
  logic g5_toSRAM_1_we;
  logic g5_toSRAM_1_ack;
  logic g5_toSRAM_1_selectedOH;
  logic [3:0] g5_toSRAM_1_array;
  logic [8:0] g5_toSRAM_2_addr;
  logic [8:0] g5_toSRAM_2_addr_rd;
  logic [65:0] g5_toSRAM_2_wdata;
  logic g5_toSRAM_2_wmask;
  logic g5_toSRAM_2_re;
  logic g5_toSRAM_2_we;
  logic g5_toSRAM_2_ack;
  logic g5_toSRAM_2_selectedOH;
  logic [3:0] g5_toSRAM_2_array;
  logic [8:0] g5_toSRAM_3_addr;
  logic [8:0] g5_toSRAM_3_addr_rd;
  logic [65:0] g5_toSRAM_3_wdata;
  logic g5_toSRAM_3_wmask;
  logic g5_toSRAM_3_re;
  logic g5_toSRAM_3_we;
  logic g5_toSRAM_3_ack;
  logic g5_toSRAM_3_selectedOH;
  logic [3:0] g5_toSRAM_3_array;
  logic [8:0] g5_toSRAM_4_addr;
  logic [8:0] g5_toSRAM_4_addr_rd;
  logic [65:0] g5_toSRAM_4_wdata;
  logic g5_toSRAM_4_wmask;
  logic g5_toSRAM_4_re;
  logic g5_toSRAM_4_we;
  logic g5_toSRAM_4_ack;
  logic g5_toSRAM_4_selectedOH;
  logic [4:0] g5_toSRAM_4_array;
  logic [8:0] g5_toSRAM_5_addr;
  logic [8:0] g5_toSRAM_5_addr_rd;
  logic [65:0] g5_toSRAM_5_wdata;
  logic g5_toSRAM_5_wmask;
  logic g5_toSRAM_5_re;
  logic g5_toSRAM_5_we;
  logic g5_toSRAM_5_ack;
  logic g5_toSRAM_5_selectedOH;
  logic [4:0] g5_toSRAM_5_array;
  logic [8:0] g5_toSRAM_6_addr;
  logic [8:0] g5_toSRAM_6_addr_rd;
  logic [65:0] g5_toSRAM_6_wdata;
  logic g5_toSRAM_6_wmask;
  logic g5_toSRAM_6_re;
  logic g5_toSRAM_6_we;
  logic g5_toSRAM_6_ack;
  logic g5_toSRAM_6_selectedOH;
  logic [4:0] g5_toSRAM_6_array;
  logic [8:0] g5_toSRAM_7_addr;
  logic [8:0] g5_toSRAM_7_addr_rd;
  logic [65:0] g5_toSRAM_7_wdata;
  logic g5_toSRAM_7_wmask;
  logic g5_toSRAM_7_re;
  logic g5_toSRAM_7_we;
  logic g5_toSRAM_7_ack;
  logic g5_toSRAM_7_selectedOH;
  logic [4:0] g5_toSRAM_7_array;
  logic x5_mbist_ack;
  logic [65:0] x5_mbist_outdata;
  logic [8:0] x5_toSRAM_0_addr;
  logic [8:0] x5_toSRAM_0_addr_rd;
  logic [65:0] x5_toSRAM_0_wdata;
  logic x5_toSRAM_0_wmask;
  logic x5_toSRAM_0_re;
  logic x5_toSRAM_0_we;
  logic x5_toSRAM_0_ack;
  logic x5_toSRAM_0_selectedOH;
  logic [3:0] x5_toSRAM_0_array;
  logic [8:0] x5_toSRAM_1_addr;
  logic [8:0] x5_toSRAM_1_addr_rd;
  logic [65:0] x5_toSRAM_1_wdata;
  logic x5_toSRAM_1_wmask;
  logic x5_toSRAM_1_re;
  logic x5_toSRAM_1_we;
  logic x5_toSRAM_1_ack;
  logic x5_toSRAM_1_selectedOH;
  logic [3:0] x5_toSRAM_1_array;
  logic [8:0] x5_toSRAM_2_addr;
  logic [8:0] x5_toSRAM_2_addr_rd;
  logic [65:0] x5_toSRAM_2_wdata;
  logic x5_toSRAM_2_wmask;
  logic x5_toSRAM_2_re;
  logic x5_toSRAM_2_we;
  logic x5_toSRAM_2_ack;
  logic x5_toSRAM_2_selectedOH;
  logic [3:0] x5_toSRAM_2_array;
  logic [8:0] x5_toSRAM_3_addr;
  logic [8:0] x5_toSRAM_3_addr_rd;
  logic [65:0] x5_toSRAM_3_wdata;
  logic x5_toSRAM_3_wmask;
  logic x5_toSRAM_3_re;
  logic x5_toSRAM_3_we;
  logic x5_toSRAM_3_ack;
  logic x5_toSRAM_3_selectedOH;
  logic [3:0] x5_toSRAM_3_array;
  logic [8:0] x5_toSRAM_4_addr;
  logic [8:0] x5_toSRAM_4_addr_rd;
  logic [65:0] x5_toSRAM_4_wdata;
  logic x5_toSRAM_4_wmask;
  logic x5_toSRAM_4_re;
  logic x5_toSRAM_4_we;
  logic x5_toSRAM_4_ack;
  logic x5_toSRAM_4_selectedOH;
  logic [4:0] x5_toSRAM_4_array;
  logic [8:0] x5_toSRAM_5_addr;
  logic [8:0] x5_toSRAM_5_addr_rd;
  logic [65:0] x5_toSRAM_5_wdata;
  logic x5_toSRAM_5_wmask;
  logic x5_toSRAM_5_re;
  logic x5_toSRAM_5_we;
  logic x5_toSRAM_5_ack;
  logic x5_toSRAM_5_selectedOH;
  logic [4:0] x5_toSRAM_5_array;
  logic [8:0] x5_toSRAM_6_addr;
  logic [8:0] x5_toSRAM_6_addr_rd;
  logic [65:0] x5_toSRAM_6_wdata;
  logic x5_toSRAM_6_wmask;
  logic x5_toSRAM_6_re;
  logic x5_toSRAM_6_we;
  logic x5_toSRAM_6_ack;
  logic x5_toSRAM_6_selectedOH;
  logic [4:0] x5_toSRAM_6_array;
  logic [8:0] x5_toSRAM_7_addr;
  logic [8:0] x5_toSRAM_7_addr_rd;
  logic [65:0] x5_toSRAM_7_wdata;
  logic x5_toSRAM_7_wmask;
  logic x5_toSRAM_7_re;
  logic x5_toSRAM_7_we;
  logic x5_toSRAM_7_ack;
  logic x5_toSRAM_7_selectedOH;
  logic [4:0] x5_toSRAM_7_array;
  bit [7:0] cov_spread5;
  bit [65:0] cov_od0_5, cov_od1_5;
  bit cov_ack0_5, cov_ack1_5;
  MbistPipeIcacheDataWay1 u_g5 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[4:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v5_rd0),
    .toSRAM_1_rdata (v5_rd1),
    .toSRAM_2_rdata (v5_rd2),
    .toSRAM_3_rdata (v5_rd3),
    .toSRAM_4_rdata (v5_rd4),
    .toSRAM_5_rdata (v5_rd5),
    .toSRAM_6_rdata (v5_rd6),
    .toSRAM_7_rdata (v5_rd7),
    .mbist_ack (g5_mbist_ack),
    .mbist_outdata (g5_mbist_outdata),
    .toSRAM_0_addr (g5_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g5_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g5_toSRAM_0_wdata),
    .toSRAM_0_wmask (g5_toSRAM_0_wmask),
    .toSRAM_0_re (g5_toSRAM_0_re),
    .toSRAM_0_we (g5_toSRAM_0_we),
    .toSRAM_0_ack (g5_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g5_toSRAM_0_selectedOH),
    .toSRAM_0_array (g5_toSRAM_0_array),
    .toSRAM_1_addr (g5_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g5_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g5_toSRAM_1_wdata),
    .toSRAM_1_wmask (g5_toSRAM_1_wmask),
    .toSRAM_1_re (g5_toSRAM_1_re),
    .toSRAM_1_we (g5_toSRAM_1_we),
    .toSRAM_1_ack (g5_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g5_toSRAM_1_selectedOH),
    .toSRAM_1_array (g5_toSRAM_1_array),
    .toSRAM_2_addr (g5_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g5_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g5_toSRAM_2_wdata),
    .toSRAM_2_wmask (g5_toSRAM_2_wmask),
    .toSRAM_2_re (g5_toSRAM_2_re),
    .toSRAM_2_we (g5_toSRAM_2_we),
    .toSRAM_2_ack (g5_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g5_toSRAM_2_selectedOH),
    .toSRAM_2_array (g5_toSRAM_2_array),
    .toSRAM_3_addr (g5_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g5_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g5_toSRAM_3_wdata),
    .toSRAM_3_wmask (g5_toSRAM_3_wmask),
    .toSRAM_3_re (g5_toSRAM_3_re),
    .toSRAM_3_we (g5_toSRAM_3_we),
    .toSRAM_3_ack (g5_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g5_toSRAM_3_selectedOH),
    .toSRAM_3_array (g5_toSRAM_3_array),
    .toSRAM_4_addr (g5_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g5_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g5_toSRAM_4_wdata),
    .toSRAM_4_wmask (g5_toSRAM_4_wmask),
    .toSRAM_4_re (g5_toSRAM_4_re),
    .toSRAM_4_we (g5_toSRAM_4_we),
    .toSRAM_4_ack (g5_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g5_toSRAM_4_selectedOH),
    .toSRAM_4_array (g5_toSRAM_4_array),
    .toSRAM_5_addr (g5_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g5_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g5_toSRAM_5_wdata),
    .toSRAM_5_wmask (g5_toSRAM_5_wmask),
    .toSRAM_5_re (g5_toSRAM_5_re),
    .toSRAM_5_we (g5_toSRAM_5_we),
    .toSRAM_5_ack (g5_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g5_toSRAM_5_selectedOH),
    .toSRAM_5_array (g5_toSRAM_5_array),
    .toSRAM_6_addr (g5_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g5_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g5_toSRAM_6_wdata),
    .toSRAM_6_wmask (g5_toSRAM_6_wmask),
    .toSRAM_6_re (g5_toSRAM_6_re),
    .toSRAM_6_we (g5_toSRAM_6_we),
    .toSRAM_6_ack (g5_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g5_toSRAM_6_selectedOH),
    .toSRAM_6_array (g5_toSRAM_6_array),
    .toSRAM_7_addr (g5_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g5_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g5_toSRAM_7_wdata),
    .toSRAM_7_wmask (g5_toSRAM_7_wmask),
    .toSRAM_7_re (g5_toSRAM_7_re),
    .toSRAM_7_we (g5_toSRAM_7_we),
    .toSRAM_7_ack (g5_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g5_toSRAM_7_selectedOH),
    .toSRAM_7_array (g5_toSRAM_7_array)
  );
  MbistPipeIcacheDataWay1_xs u_x5 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[4:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v5_rd0),
    .toSRAM_1_rdata (v5_rd1),
    .toSRAM_2_rdata (v5_rd2),
    .toSRAM_3_rdata (v5_rd3),
    .toSRAM_4_rdata (v5_rd4),
    .toSRAM_5_rdata (v5_rd5),
    .toSRAM_6_rdata (v5_rd6),
    .toSRAM_7_rdata (v5_rd7),
    .mbist_ack (x5_mbist_ack),
    .mbist_outdata (x5_mbist_outdata),
    .toSRAM_0_addr (x5_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x5_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x5_toSRAM_0_wdata),
    .toSRAM_0_wmask (x5_toSRAM_0_wmask),
    .toSRAM_0_re (x5_toSRAM_0_re),
    .toSRAM_0_we (x5_toSRAM_0_we),
    .toSRAM_0_ack (x5_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x5_toSRAM_0_selectedOH),
    .toSRAM_0_array (x5_toSRAM_0_array),
    .toSRAM_1_addr (x5_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x5_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x5_toSRAM_1_wdata),
    .toSRAM_1_wmask (x5_toSRAM_1_wmask),
    .toSRAM_1_re (x5_toSRAM_1_re),
    .toSRAM_1_we (x5_toSRAM_1_we),
    .toSRAM_1_ack (x5_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x5_toSRAM_1_selectedOH),
    .toSRAM_1_array (x5_toSRAM_1_array),
    .toSRAM_2_addr (x5_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x5_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x5_toSRAM_2_wdata),
    .toSRAM_2_wmask (x5_toSRAM_2_wmask),
    .toSRAM_2_re (x5_toSRAM_2_re),
    .toSRAM_2_we (x5_toSRAM_2_we),
    .toSRAM_2_ack (x5_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x5_toSRAM_2_selectedOH),
    .toSRAM_2_array (x5_toSRAM_2_array),
    .toSRAM_3_addr (x5_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x5_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x5_toSRAM_3_wdata),
    .toSRAM_3_wmask (x5_toSRAM_3_wmask),
    .toSRAM_3_re (x5_toSRAM_3_re),
    .toSRAM_3_we (x5_toSRAM_3_we),
    .toSRAM_3_ack (x5_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x5_toSRAM_3_selectedOH),
    .toSRAM_3_array (x5_toSRAM_3_array),
    .toSRAM_4_addr (x5_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x5_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x5_toSRAM_4_wdata),
    .toSRAM_4_wmask (x5_toSRAM_4_wmask),
    .toSRAM_4_re (x5_toSRAM_4_re),
    .toSRAM_4_we (x5_toSRAM_4_we),
    .toSRAM_4_ack (x5_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x5_toSRAM_4_selectedOH),
    .toSRAM_4_array (x5_toSRAM_4_array),
    .toSRAM_5_addr (x5_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x5_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x5_toSRAM_5_wdata),
    .toSRAM_5_wmask (x5_toSRAM_5_wmask),
    .toSRAM_5_re (x5_toSRAM_5_re),
    .toSRAM_5_we (x5_toSRAM_5_we),
    .toSRAM_5_ack (x5_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x5_toSRAM_5_selectedOH),
    .toSRAM_5_array (x5_toSRAM_5_array),
    .toSRAM_6_addr (x5_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x5_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x5_toSRAM_6_wdata),
    .toSRAM_6_wmask (x5_toSRAM_6_wmask),
    .toSRAM_6_re (x5_toSRAM_6_re),
    .toSRAM_6_we (x5_toSRAM_6_we),
    .toSRAM_6_ack (x5_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x5_toSRAM_6_selectedOH),
    .toSRAM_6_array (x5_toSRAM_6_array),
    .toSRAM_7_addr (x5_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x5_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x5_toSRAM_7_wdata),
    .toSRAM_7_wmask (x5_toSRAM_7_wmask),
    .toSRAM_7_re (x5_toSRAM_7_re),
    .toSRAM_7_we (x5_toSRAM_7_we),
    .toSRAM_7_ack (x5_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x5_toSRAM_7_selectedOH),
    .toSRAM_7_array (x5_toSRAM_7_array)
  );
  wire [814:0] gbus5 = {g5_mbist_ack, g5_mbist_outdata, g5_toSRAM_0_addr, g5_toSRAM_0_addr_rd, g5_toSRAM_0_wdata, g5_toSRAM_0_wmask, g5_toSRAM_0_re, g5_toSRAM_0_we, g5_toSRAM_0_ack, g5_toSRAM_0_selectedOH, g5_toSRAM_0_array, g5_toSRAM_1_addr, g5_toSRAM_1_addr_rd, g5_toSRAM_1_wdata, g5_toSRAM_1_wmask, g5_toSRAM_1_re, g5_toSRAM_1_we, g5_toSRAM_1_ack, g5_toSRAM_1_selectedOH, g5_toSRAM_1_array, g5_toSRAM_2_addr, g5_toSRAM_2_addr_rd, g5_toSRAM_2_wdata, g5_toSRAM_2_wmask, g5_toSRAM_2_re, g5_toSRAM_2_we, g5_toSRAM_2_ack, g5_toSRAM_2_selectedOH, g5_toSRAM_2_array, g5_toSRAM_3_addr, g5_toSRAM_3_addr_rd, g5_toSRAM_3_wdata, g5_toSRAM_3_wmask, g5_toSRAM_3_re, g5_toSRAM_3_we, g5_toSRAM_3_ack, g5_toSRAM_3_selectedOH, g5_toSRAM_3_array, g5_toSRAM_4_addr, g5_toSRAM_4_addr_rd, g5_toSRAM_4_wdata, g5_toSRAM_4_wmask, g5_toSRAM_4_re, g5_toSRAM_4_we, g5_toSRAM_4_ack, g5_toSRAM_4_selectedOH, g5_toSRAM_4_array, g5_toSRAM_5_addr, g5_toSRAM_5_addr_rd, g5_toSRAM_5_wdata, g5_toSRAM_5_wmask, g5_toSRAM_5_re, g5_toSRAM_5_we, g5_toSRAM_5_ack, g5_toSRAM_5_selectedOH, g5_toSRAM_5_array, g5_toSRAM_6_addr, g5_toSRAM_6_addr_rd, g5_toSRAM_6_wdata, g5_toSRAM_6_wmask, g5_toSRAM_6_re, g5_toSRAM_6_we, g5_toSRAM_6_ack, g5_toSRAM_6_selectedOH, g5_toSRAM_6_array, g5_toSRAM_7_addr, g5_toSRAM_7_addr_rd, g5_toSRAM_7_wdata, g5_toSRAM_7_wmask, g5_toSRAM_7_re, g5_toSRAM_7_we, g5_toSRAM_7_ack, g5_toSRAM_7_selectedOH, g5_toSRAM_7_array};
  wire [814:0] xbus5 = {x5_mbist_ack, x5_mbist_outdata, x5_toSRAM_0_addr, x5_toSRAM_0_addr_rd, x5_toSRAM_0_wdata, x5_toSRAM_0_wmask, x5_toSRAM_0_re, x5_toSRAM_0_we, x5_toSRAM_0_ack, x5_toSRAM_0_selectedOH, x5_toSRAM_0_array, x5_toSRAM_1_addr, x5_toSRAM_1_addr_rd, x5_toSRAM_1_wdata, x5_toSRAM_1_wmask, x5_toSRAM_1_re, x5_toSRAM_1_we, x5_toSRAM_1_ack, x5_toSRAM_1_selectedOH, x5_toSRAM_1_array, x5_toSRAM_2_addr, x5_toSRAM_2_addr_rd, x5_toSRAM_2_wdata, x5_toSRAM_2_wmask, x5_toSRAM_2_re, x5_toSRAM_2_we, x5_toSRAM_2_ack, x5_toSRAM_2_selectedOH, x5_toSRAM_2_array, x5_toSRAM_3_addr, x5_toSRAM_3_addr_rd, x5_toSRAM_3_wdata, x5_toSRAM_3_wmask, x5_toSRAM_3_re, x5_toSRAM_3_we, x5_toSRAM_3_ack, x5_toSRAM_3_selectedOH, x5_toSRAM_3_array, x5_toSRAM_4_addr, x5_toSRAM_4_addr_rd, x5_toSRAM_4_wdata, x5_toSRAM_4_wmask, x5_toSRAM_4_re, x5_toSRAM_4_we, x5_toSRAM_4_ack, x5_toSRAM_4_selectedOH, x5_toSRAM_4_array, x5_toSRAM_5_addr, x5_toSRAM_5_addr_rd, x5_toSRAM_5_wdata, x5_toSRAM_5_wmask, x5_toSRAM_5_re, x5_toSRAM_5_we, x5_toSRAM_5_ack, x5_toSRAM_5_selectedOH, x5_toSRAM_5_array, x5_toSRAM_6_addr, x5_toSRAM_6_addr_rd, x5_toSRAM_6_wdata, x5_toSRAM_6_wmask, x5_toSRAM_6_re, x5_toSRAM_6_we, x5_toSRAM_6_ack, x5_toSRAM_6_selectedOH, x5_toSRAM_6_array, x5_toSRAM_7_addr, x5_toSRAM_7_addr_rd, x5_toSRAM_7_wdata, x5_toSRAM_7_wmask, x5_toSRAM_7_re, x5_toSRAM_7_we, x5_toSRAM_7_ack, x5_toSRAM_7_selectedOH, x5_toSRAM_7_array};
  task automatic detail5();
    if (g5_mbist_ack !== x5_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.mbist_ack golden=%h impl=%h", cyc, g5_mbist_ack, x5_mbist_ack); end
    if (g5_mbist_outdata !== x5_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.mbist_outdata golden=%h impl=%h", cyc, g5_mbist_outdata, x5_mbist_outdata); end
    if (g5_toSRAM_0_addr !== x5_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_addr golden=%h impl=%h", cyc, g5_toSRAM_0_addr, x5_toSRAM_0_addr); end
    if (g5_toSRAM_0_addr_rd !== x5_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_0_addr_rd, x5_toSRAM_0_addr_rd); end
    if (g5_toSRAM_0_wdata !== x5_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_wdata golden=%h impl=%h", cyc, g5_toSRAM_0_wdata, x5_toSRAM_0_wdata); end
    if (g5_toSRAM_0_wmask !== x5_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_wmask golden=%h impl=%h", cyc, g5_toSRAM_0_wmask, x5_toSRAM_0_wmask); end
    if (g5_toSRAM_0_re !== x5_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_re golden=%h impl=%h", cyc, g5_toSRAM_0_re, x5_toSRAM_0_re); end
    if (g5_toSRAM_0_we !== x5_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_we golden=%h impl=%h", cyc, g5_toSRAM_0_we, x5_toSRAM_0_we); end
    if (g5_toSRAM_0_ack !== x5_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_ack golden=%h impl=%h", cyc, g5_toSRAM_0_ack, x5_toSRAM_0_ack); end
    if (g5_toSRAM_0_selectedOH !== x5_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_0_selectedOH, x5_toSRAM_0_selectedOH); end
    if (g5_toSRAM_0_array !== x5_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_0_array golden=%h impl=%h", cyc, g5_toSRAM_0_array, x5_toSRAM_0_array); end
    if (g5_toSRAM_1_addr !== x5_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_addr golden=%h impl=%h", cyc, g5_toSRAM_1_addr, x5_toSRAM_1_addr); end
    if (g5_toSRAM_1_addr_rd !== x5_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_1_addr_rd, x5_toSRAM_1_addr_rd); end
    if (g5_toSRAM_1_wdata !== x5_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_wdata golden=%h impl=%h", cyc, g5_toSRAM_1_wdata, x5_toSRAM_1_wdata); end
    if (g5_toSRAM_1_wmask !== x5_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_wmask golden=%h impl=%h", cyc, g5_toSRAM_1_wmask, x5_toSRAM_1_wmask); end
    if (g5_toSRAM_1_re !== x5_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_re golden=%h impl=%h", cyc, g5_toSRAM_1_re, x5_toSRAM_1_re); end
    if (g5_toSRAM_1_we !== x5_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_we golden=%h impl=%h", cyc, g5_toSRAM_1_we, x5_toSRAM_1_we); end
    if (g5_toSRAM_1_ack !== x5_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_ack golden=%h impl=%h", cyc, g5_toSRAM_1_ack, x5_toSRAM_1_ack); end
    if (g5_toSRAM_1_selectedOH !== x5_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_1_selectedOH, x5_toSRAM_1_selectedOH); end
    if (g5_toSRAM_1_array !== x5_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_1_array golden=%h impl=%h", cyc, g5_toSRAM_1_array, x5_toSRAM_1_array); end
    if (g5_toSRAM_2_addr !== x5_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_addr golden=%h impl=%h", cyc, g5_toSRAM_2_addr, x5_toSRAM_2_addr); end
    if (g5_toSRAM_2_addr_rd !== x5_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_2_addr_rd, x5_toSRAM_2_addr_rd); end
    if (g5_toSRAM_2_wdata !== x5_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_wdata golden=%h impl=%h", cyc, g5_toSRAM_2_wdata, x5_toSRAM_2_wdata); end
    if (g5_toSRAM_2_wmask !== x5_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_wmask golden=%h impl=%h", cyc, g5_toSRAM_2_wmask, x5_toSRAM_2_wmask); end
    if (g5_toSRAM_2_re !== x5_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_re golden=%h impl=%h", cyc, g5_toSRAM_2_re, x5_toSRAM_2_re); end
    if (g5_toSRAM_2_we !== x5_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_we golden=%h impl=%h", cyc, g5_toSRAM_2_we, x5_toSRAM_2_we); end
    if (g5_toSRAM_2_ack !== x5_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_ack golden=%h impl=%h", cyc, g5_toSRAM_2_ack, x5_toSRAM_2_ack); end
    if (g5_toSRAM_2_selectedOH !== x5_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_2_selectedOH, x5_toSRAM_2_selectedOH); end
    if (g5_toSRAM_2_array !== x5_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_2_array golden=%h impl=%h", cyc, g5_toSRAM_2_array, x5_toSRAM_2_array); end
    if (g5_toSRAM_3_addr !== x5_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_addr golden=%h impl=%h", cyc, g5_toSRAM_3_addr, x5_toSRAM_3_addr); end
    if (g5_toSRAM_3_addr_rd !== x5_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_3_addr_rd, x5_toSRAM_3_addr_rd); end
    if (g5_toSRAM_3_wdata !== x5_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_wdata golden=%h impl=%h", cyc, g5_toSRAM_3_wdata, x5_toSRAM_3_wdata); end
    if (g5_toSRAM_3_wmask !== x5_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_wmask golden=%h impl=%h", cyc, g5_toSRAM_3_wmask, x5_toSRAM_3_wmask); end
    if (g5_toSRAM_3_re !== x5_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_re golden=%h impl=%h", cyc, g5_toSRAM_3_re, x5_toSRAM_3_re); end
    if (g5_toSRAM_3_we !== x5_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_we golden=%h impl=%h", cyc, g5_toSRAM_3_we, x5_toSRAM_3_we); end
    if (g5_toSRAM_3_ack !== x5_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_ack golden=%h impl=%h", cyc, g5_toSRAM_3_ack, x5_toSRAM_3_ack); end
    if (g5_toSRAM_3_selectedOH !== x5_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_3_selectedOH, x5_toSRAM_3_selectedOH); end
    if (g5_toSRAM_3_array !== x5_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_3_array golden=%h impl=%h", cyc, g5_toSRAM_3_array, x5_toSRAM_3_array); end
    if (g5_toSRAM_4_addr !== x5_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_addr golden=%h impl=%h", cyc, g5_toSRAM_4_addr, x5_toSRAM_4_addr); end
    if (g5_toSRAM_4_addr_rd !== x5_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_4_addr_rd, x5_toSRAM_4_addr_rd); end
    if (g5_toSRAM_4_wdata !== x5_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_wdata golden=%h impl=%h", cyc, g5_toSRAM_4_wdata, x5_toSRAM_4_wdata); end
    if (g5_toSRAM_4_wmask !== x5_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_wmask golden=%h impl=%h", cyc, g5_toSRAM_4_wmask, x5_toSRAM_4_wmask); end
    if (g5_toSRAM_4_re !== x5_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_re golden=%h impl=%h", cyc, g5_toSRAM_4_re, x5_toSRAM_4_re); end
    if (g5_toSRAM_4_we !== x5_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_we golden=%h impl=%h", cyc, g5_toSRAM_4_we, x5_toSRAM_4_we); end
    if (g5_toSRAM_4_ack !== x5_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_ack golden=%h impl=%h", cyc, g5_toSRAM_4_ack, x5_toSRAM_4_ack); end
    if (g5_toSRAM_4_selectedOH !== x5_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_4_selectedOH, x5_toSRAM_4_selectedOH); end
    if (g5_toSRAM_4_array !== x5_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_4_array golden=%h impl=%h", cyc, g5_toSRAM_4_array, x5_toSRAM_4_array); end
    if (g5_toSRAM_5_addr !== x5_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_addr golden=%h impl=%h", cyc, g5_toSRAM_5_addr, x5_toSRAM_5_addr); end
    if (g5_toSRAM_5_addr_rd !== x5_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_5_addr_rd, x5_toSRAM_5_addr_rd); end
    if (g5_toSRAM_5_wdata !== x5_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_wdata golden=%h impl=%h", cyc, g5_toSRAM_5_wdata, x5_toSRAM_5_wdata); end
    if (g5_toSRAM_5_wmask !== x5_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_wmask golden=%h impl=%h", cyc, g5_toSRAM_5_wmask, x5_toSRAM_5_wmask); end
    if (g5_toSRAM_5_re !== x5_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_re golden=%h impl=%h", cyc, g5_toSRAM_5_re, x5_toSRAM_5_re); end
    if (g5_toSRAM_5_we !== x5_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_we golden=%h impl=%h", cyc, g5_toSRAM_5_we, x5_toSRAM_5_we); end
    if (g5_toSRAM_5_ack !== x5_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_ack golden=%h impl=%h", cyc, g5_toSRAM_5_ack, x5_toSRAM_5_ack); end
    if (g5_toSRAM_5_selectedOH !== x5_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_5_selectedOH, x5_toSRAM_5_selectedOH); end
    if (g5_toSRAM_5_array !== x5_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_5_array golden=%h impl=%h", cyc, g5_toSRAM_5_array, x5_toSRAM_5_array); end
    if (g5_toSRAM_6_addr !== x5_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_addr golden=%h impl=%h", cyc, g5_toSRAM_6_addr, x5_toSRAM_6_addr); end
    if (g5_toSRAM_6_addr_rd !== x5_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_6_addr_rd, x5_toSRAM_6_addr_rd); end
    if (g5_toSRAM_6_wdata !== x5_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_wdata golden=%h impl=%h", cyc, g5_toSRAM_6_wdata, x5_toSRAM_6_wdata); end
    if (g5_toSRAM_6_wmask !== x5_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_wmask golden=%h impl=%h", cyc, g5_toSRAM_6_wmask, x5_toSRAM_6_wmask); end
    if (g5_toSRAM_6_re !== x5_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_re golden=%h impl=%h", cyc, g5_toSRAM_6_re, x5_toSRAM_6_re); end
    if (g5_toSRAM_6_we !== x5_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_we golden=%h impl=%h", cyc, g5_toSRAM_6_we, x5_toSRAM_6_we); end
    if (g5_toSRAM_6_ack !== x5_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_ack golden=%h impl=%h", cyc, g5_toSRAM_6_ack, x5_toSRAM_6_ack); end
    if (g5_toSRAM_6_selectedOH !== x5_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_6_selectedOH, x5_toSRAM_6_selectedOH); end
    if (g5_toSRAM_6_array !== x5_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_6_array golden=%h impl=%h", cyc, g5_toSRAM_6_array, x5_toSRAM_6_array); end
    if (g5_toSRAM_7_addr !== x5_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_addr golden=%h impl=%h", cyc, g5_toSRAM_7_addr, x5_toSRAM_7_addr); end
    if (g5_toSRAM_7_addr_rd !== x5_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g5_toSRAM_7_addr_rd, x5_toSRAM_7_addr_rd); end
    if (g5_toSRAM_7_wdata !== x5_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_wdata golden=%h impl=%h", cyc, g5_toSRAM_7_wdata, x5_toSRAM_7_wdata); end
    if (g5_toSRAM_7_wmask !== x5_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_wmask golden=%h impl=%h", cyc, g5_toSRAM_7_wmask, x5_toSRAM_7_wmask); end
    if (g5_toSRAM_7_re !== x5_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_re golden=%h impl=%h", cyc, g5_toSRAM_7_re, x5_toSRAM_7_re); end
    if (g5_toSRAM_7_we !== x5_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_we golden=%h impl=%h", cyc, g5_toSRAM_7_we, x5_toSRAM_7_we); end
    if (g5_toSRAM_7_ack !== x5_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_ack golden=%h impl=%h", cyc, g5_toSRAM_7_ack, x5_toSRAM_7_ack); end
    if (g5_toSRAM_7_selectedOH !== x5_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g5_toSRAM_7_selectedOH, x5_toSRAM_7_selectedOH); end
    if (g5_toSRAM_7_array !== x5_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay1.toSRAM_7_array golden=%h impl=%h", cyc, g5_toSRAM_7_array, x5_toSRAM_7_array); end
  endtask

  // ======================== [06] MbistPipeIcacheDataWay2 ========================
  logic [65:0] v6_rd0;
  logic [65:0] v6_rd1;
  logic [65:0] v6_rd2;
  logic [65:0] v6_rd3;
  logic [65:0] v6_rd4;
  logic [65:0] v6_rd5;
  logic [65:0] v6_rd6;
  logic [65:0] v6_rd7;
  logic g6_mbist_ack;
  logic [65:0] g6_mbist_outdata;
  logic [8:0] g6_toSRAM_0_addr;
  logic [8:0] g6_toSRAM_0_addr_rd;
  logic [65:0] g6_toSRAM_0_wdata;
  logic g6_toSRAM_0_wmask;
  logic g6_toSRAM_0_re;
  logic g6_toSRAM_0_we;
  logic g6_toSRAM_0_ack;
  logic g6_toSRAM_0_selectedOH;
  logic [4:0] g6_toSRAM_0_array;
  logic [8:0] g6_toSRAM_1_addr;
  logic [8:0] g6_toSRAM_1_addr_rd;
  logic [65:0] g6_toSRAM_1_wdata;
  logic g6_toSRAM_1_wmask;
  logic g6_toSRAM_1_re;
  logic g6_toSRAM_1_we;
  logic g6_toSRAM_1_ack;
  logic g6_toSRAM_1_selectedOH;
  logic [4:0] g6_toSRAM_1_array;
  logic [8:0] g6_toSRAM_2_addr;
  logic [8:0] g6_toSRAM_2_addr_rd;
  logic [65:0] g6_toSRAM_2_wdata;
  logic g6_toSRAM_2_wmask;
  logic g6_toSRAM_2_re;
  logic g6_toSRAM_2_we;
  logic g6_toSRAM_2_ack;
  logic g6_toSRAM_2_selectedOH;
  logic [4:0] g6_toSRAM_2_array;
  logic [8:0] g6_toSRAM_3_addr;
  logic [8:0] g6_toSRAM_3_addr_rd;
  logic [65:0] g6_toSRAM_3_wdata;
  logic g6_toSRAM_3_wmask;
  logic g6_toSRAM_3_re;
  logic g6_toSRAM_3_we;
  logic g6_toSRAM_3_ack;
  logic g6_toSRAM_3_selectedOH;
  logic [4:0] g6_toSRAM_3_array;
  logic [8:0] g6_toSRAM_4_addr;
  logic [8:0] g6_toSRAM_4_addr_rd;
  logic [65:0] g6_toSRAM_4_wdata;
  logic g6_toSRAM_4_wmask;
  logic g6_toSRAM_4_re;
  logic g6_toSRAM_4_we;
  logic g6_toSRAM_4_ack;
  logic g6_toSRAM_4_selectedOH;
  logic [4:0] g6_toSRAM_4_array;
  logic [8:0] g6_toSRAM_5_addr;
  logic [8:0] g6_toSRAM_5_addr_rd;
  logic [65:0] g6_toSRAM_5_wdata;
  logic g6_toSRAM_5_wmask;
  logic g6_toSRAM_5_re;
  logic g6_toSRAM_5_we;
  logic g6_toSRAM_5_ack;
  logic g6_toSRAM_5_selectedOH;
  logic [4:0] g6_toSRAM_5_array;
  logic [8:0] g6_toSRAM_6_addr;
  logic [8:0] g6_toSRAM_6_addr_rd;
  logic [65:0] g6_toSRAM_6_wdata;
  logic g6_toSRAM_6_wmask;
  logic g6_toSRAM_6_re;
  logic g6_toSRAM_6_we;
  logic g6_toSRAM_6_ack;
  logic g6_toSRAM_6_selectedOH;
  logic [4:0] g6_toSRAM_6_array;
  logic [8:0] g6_toSRAM_7_addr;
  logic [8:0] g6_toSRAM_7_addr_rd;
  logic [65:0] g6_toSRAM_7_wdata;
  logic g6_toSRAM_7_wmask;
  logic g6_toSRAM_7_re;
  logic g6_toSRAM_7_we;
  logic g6_toSRAM_7_ack;
  logic g6_toSRAM_7_selectedOH;
  logic [4:0] g6_toSRAM_7_array;
  logic x6_mbist_ack;
  logic [65:0] x6_mbist_outdata;
  logic [8:0] x6_toSRAM_0_addr;
  logic [8:0] x6_toSRAM_0_addr_rd;
  logic [65:0] x6_toSRAM_0_wdata;
  logic x6_toSRAM_0_wmask;
  logic x6_toSRAM_0_re;
  logic x6_toSRAM_0_we;
  logic x6_toSRAM_0_ack;
  logic x6_toSRAM_0_selectedOH;
  logic [4:0] x6_toSRAM_0_array;
  logic [8:0] x6_toSRAM_1_addr;
  logic [8:0] x6_toSRAM_1_addr_rd;
  logic [65:0] x6_toSRAM_1_wdata;
  logic x6_toSRAM_1_wmask;
  logic x6_toSRAM_1_re;
  logic x6_toSRAM_1_we;
  logic x6_toSRAM_1_ack;
  logic x6_toSRAM_1_selectedOH;
  logic [4:0] x6_toSRAM_1_array;
  logic [8:0] x6_toSRAM_2_addr;
  logic [8:0] x6_toSRAM_2_addr_rd;
  logic [65:0] x6_toSRAM_2_wdata;
  logic x6_toSRAM_2_wmask;
  logic x6_toSRAM_2_re;
  logic x6_toSRAM_2_we;
  logic x6_toSRAM_2_ack;
  logic x6_toSRAM_2_selectedOH;
  logic [4:0] x6_toSRAM_2_array;
  logic [8:0] x6_toSRAM_3_addr;
  logic [8:0] x6_toSRAM_3_addr_rd;
  logic [65:0] x6_toSRAM_3_wdata;
  logic x6_toSRAM_3_wmask;
  logic x6_toSRAM_3_re;
  logic x6_toSRAM_3_we;
  logic x6_toSRAM_3_ack;
  logic x6_toSRAM_3_selectedOH;
  logic [4:0] x6_toSRAM_3_array;
  logic [8:0] x6_toSRAM_4_addr;
  logic [8:0] x6_toSRAM_4_addr_rd;
  logic [65:0] x6_toSRAM_4_wdata;
  logic x6_toSRAM_4_wmask;
  logic x6_toSRAM_4_re;
  logic x6_toSRAM_4_we;
  logic x6_toSRAM_4_ack;
  logic x6_toSRAM_4_selectedOH;
  logic [4:0] x6_toSRAM_4_array;
  logic [8:0] x6_toSRAM_5_addr;
  logic [8:0] x6_toSRAM_5_addr_rd;
  logic [65:0] x6_toSRAM_5_wdata;
  logic x6_toSRAM_5_wmask;
  logic x6_toSRAM_5_re;
  logic x6_toSRAM_5_we;
  logic x6_toSRAM_5_ack;
  logic x6_toSRAM_5_selectedOH;
  logic [4:0] x6_toSRAM_5_array;
  logic [8:0] x6_toSRAM_6_addr;
  logic [8:0] x6_toSRAM_6_addr_rd;
  logic [65:0] x6_toSRAM_6_wdata;
  logic x6_toSRAM_6_wmask;
  logic x6_toSRAM_6_re;
  logic x6_toSRAM_6_we;
  logic x6_toSRAM_6_ack;
  logic x6_toSRAM_6_selectedOH;
  logic [4:0] x6_toSRAM_6_array;
  logic [8:0] x6_toSRAM_7_addr;
  logic [8:0] x6_toSRAM_7_addr_rd;
  logic [65:0] x6_toSRAM_7_wdata;
  logic x6_toSRAM_7_wmask;
  logic x6_toSRAM_7_re;
  logic x6_toSRAM_7_we;
  logic x6_toSRAM_7_ack;
  logic x6_toSRAM_7_selectedOH;
  logic [4:0] x6_toSRAM_7_array;
  bit [7:0] cov_spread6;
  bit [65:0] cov_od0_6, cov_od1_6;
  bit cov_ack0_6, cov_ack1_6;
  MbistPipeIcacheDataWay2 u_g6 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[4:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v6_rd0),
    .toSRAM_1_rdata (v6_rd1),
    .toSRAM_2_rdata (v6_rd2),
    .toSRAM_3_rdata (v6_rd3),
    .toSRAM_4_rdata (v6_rd4),
    .toSRAM_5_rdata (v6_rd5),
    .toSRAM_6_rdata (v6_rd6),
    .toSRAM_7_rdata (v6_rd7),
    .mbist_ack (g6_mbist_ack),
    .mbist_outdata (g6_mbist_outdata),
    .toSRAM_0_addr (g6_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g6_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g6_toSRAM_0_wdata),
    .toSRAM_0_wmask (g6_toSRAM_0_wmask),
    .toSRAM_0_re (g6_toSRAM_0_re),
    .toSRAM_0_we (g6_toSRAM_0_we),
    .toSRAM_0_ack (g6_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g6_toSRAM_0_selectedOH),
    .toSRAM_0_array (g6_toSRAM_0_array),
    .toSRAM_1_addr (g6_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g6_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g6_toSRAM_1_wdata),
    .toSRAM_1_wmask (g6_toSRAM_1_wmask),
    .toSRAM_1_re (g6_toSRAM_1_re),
    .toSRAM_1_we (g6_toSRAM_1_we),
    .toSRAM_1_ack (g6_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g6_toSRAM_1_selectedOH),
    .toSRAM_1_array (g6_toSRAM_1_array),
    .toSRAM_2_addr (g6_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g6_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g6_toSRAM_2_wdata),
    .toSRAM_2_wmask (g6_toSRAM_2_wmask),
    .toSRAM_2_re (g6_toSRAM_2_re),
    .toSRAM_2_we (g6_toSRAM_2_we),
    .toSRAM_2_ack (g6_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g6_toSRAM_2_selectedOH),
    .toSRAM_2_array (g6_toSRAM_2_array),
    .toSRAM_3_addr (g6_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g6_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g6_toSRAM_3_wdata),
    .toSRAM_3_wmask (g6_toSRAM_3_wmask),
    .toSRAM_3_re (g6_toSRAM_3_re),
    .toSRAM_3_we (g6_toSRAM_3_we),
    .toSRAM_3_ack (g6_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g6_toSRAM_3_selectedOH),
    .toSRAM_3_array (g6_toSRAM_3_array),
    .toSRAM_4_addr (g6_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g6_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g6_toSRAM_4_wdata),
    .toSRAM_4_wmask (g6_toSRAM_4_wmask),
    .toSRAM_4_re (g6_toSRAM_4_re),
    .toSRAM_4_we (g6_toSRAM_4_we),
    .toSRAM_4_ack (g6_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g6_toSRAM_4_selectedOH),
    .toSRAM_4_array (g6_toSRAM_4_array),
    .toSRAM_5_addr (g6_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g6_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g6_toSRAM_5_wdata),
    .toSRAM_5_wmask (g6_toSRAM_5_wmask),
    .toSRAM_5_re (g6_toSRAM_5_re),
    .toSRAM_5_we (g6_toSRAM_5_we),
    .toSRAM_5_ack (g6_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g6_toSRAM_5_selectedOH),
    .toSRAM_5_array (g6_toSRAM_5_array),
    .toSRAM_6_addr (g6_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g6_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g6_toSRAM_6_wdata),
    .toSRAM_6_wmask (g6_toSRAM_6_wmask),
    .toSRAM_6_re (g6_toSRAM_6_re),
    .toSRAM_6_we (g6_toSRAM_6_we),
    .toSRAM_6_ack (g6_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g6_toSRAM_6_selectedOH),
    .toSRAM_6_array (g6_toSRAM_6_array),
    .toSRAM_7_addr (g6_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g6_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g6_toSRAM_7_wdata),
    .toSRAM_7_wmask (g6_toSRAM_7_wmask),
    .toSRAM_7_re (g6_toSRAM_7_re),
    .toSRAM_7_we (g6_toSRAM_7_we),
    .toSRAM_7_ack (g6_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g6_toSRAM_7_selectedOH),
    .toSRAM_7_array (g6_toSRAM_7_array)
  );
  MbistPipeIcacheDataWay2_xs u_x6 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[4:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v6_rd0),
    .toSRAM_1_rdata (v6_rd1),
    .toSRAM_2_rdata (v6_rd2),
    .toSRAM_3_rdata (v6_rd3),
    .toSRAM_4_rdata (v6_rd4),
    .toSRAM_5_rdata (v6_rd5),
    .toSRAM_6_rdata (v6_rd6),
    .toSRAM_7_rdata (v6_rd7),
    .mbist_ack (x6_mbist_ack),
    .mbist_outdata (x6_mbist_outdata),
    .toSRAM_0_addr (x6_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x6_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x6_toSRAM_0_wdata),
    .toSRAM_0_wmask (x6_toSRAM_0_wmask),
    .toSRAM_0_re (x6_toSRAM_0_re),
    .toSRAM_0_we (x6_toSRAM_0_we),
    .toSRAM_0_ack (x6_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x6_toSRAM_0_selectedOH),
    .toSRAM_0_array (x6_toSRAM_0_array),
    .toSRAM_1_addr (x6_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x6_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x6_toSRAM_1_wdata),
    .toSRAM_1_wmask (x6_toSRAM_1_wmask),
    .toSRAM_1_re (x6_toSRAM_1_re),
    .toSRAM_1_we (x6_toSRAM_1_we),
    .toSRAM_1_ack (x6_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x6_toSRAM_1_selectedOH),
    .toSRAM_1_array (x6_toSRAM_1_array),
    .toSRAM_2_addr (x6_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x6_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x6_toSRAM_2_wdata),
    .toSRAM_2_wmask (x6_toSRAM_2_wmask),
    .toSRAM_2_re (x6_toSRAM_2_re),
    .toSRAM_2_we (x6_toSRAM_2_we),
    .toSRAM_2_ack (x6_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x6_toSRAM_2_selectedOH),
    .toSRAM_2_array (x6_toSRAM_2_array),
    .toSRAM_3_addr (x6_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x6_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x6_toSRAM_3_wdata),
    .toSRAM_3_wmask (x6_toSRAM_3_wmask),
    .toSRAM_3_re (x6_toSRAM_3_re),
    .toSRAM_3_we (x6_toSRAM_3_we),
    .toSRAM_3_ack (x6_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x6_toSRAM_3_selectedOH),
    .toSRAM_3_array (x6_toSRAM_3_array),
    .toSRAM_4_addr (x6_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x6_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x6_toSRAM_4_wdata),
    .toSRAM_4_wmask (x6_toSRAM_4_wmask),
    .toSRAM_4_re (x6_toSRAM_4_re),
    .toSRAM_4_we (x6_toSRAM_4_we),
    .toSRAM_4_ack (x6_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x6_toSRAM_4_selectedOH),
    .toSRAM_4_array (x6_toSRAM_4_array),
    .toSRAM_5_addr (x6_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x6_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x6_toSRAM_5_wdata),
    .toSRAM_5_wmask (x6_toSRAM_5_wmask),
    .toSRAM_5_re (x6_toSRAM_5_re),
    .toSRAM_5_we (x6_toSRAM_5_we),
    .toSRAM_5_ack (x6_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x6_toSRAM_5_selectedOH),
    .toSRAM_5_array (x6_toSRAM_5_array),
    .toSRAM_6_addr (x6_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x6_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x6_toSRAM_6_wdata),
    .toSRAM_6_wmask (x6_toSRAM_6_wmask),
    .toSRAM_6_re (x6_toSRAM_6_re),
    .toSRAM_6_we (x6_toSRAM_6_we),
    .toSRAM_6_ack (x6_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x6_toSRAM_6_selectedOH),
    .toSRAM_6_array (x6_toSRAM_6_array),
    .toSRAM_7_addr (x6_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x6_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x6_toSRAM_7_wdata),
    .toSRAM_7_wmask (x6_toSRAM_7_wmask),
    .toSRAM_7_re (x6_toSRAM_7_re),
    .toSRAM_7_we (x6_toSRAM_7_we),
    .toSRAM_7_ack (x6_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x6_toSRAM_7_selectedOH),
    .toSRAM_7_array (x6_toSRAM_7_array)
  );
  wire [818:0] gbus6 = {g6_mbist_ack, g6_mbist_outdata, g6_toSRAM_0_addr, g6_toSRAM_0_addr_rd, g6_toSRAM_0_wdata, g6_toSRAM_0_wmask, g6_toSRAM_0_re, g6_toSRAM_0_we, g6_toSRAM_0_ack, g6_toSRAM_0_selectedOH, g6_toSRAM_0_array, g6_toSRAM_1_addr, g6_toSRAM_1_addr_rd, g6_toSRAM_1_wdata, g6_toSRAM_1_wmask, g6_toSRAM_1_re, g6_toSRAM_1_we, g6_toSRAM_1_ack, g6_toSRAM_1_selectedOH, g6_toSRAM_1_array, g6_toSRAM_2_addr, g6_toSRAM_2_addr_rd, g6_toSRAM_2_wdata, g6_toSRAM_2_wmask, g6_toSRAM_2_re, g6_toSRAM_2_we, g6_toSRAM_2_ack, g6_toSRAM_2_selectedOH, g6_toSRAM_2_array, g6_toSRAM_3_addr, g6_toSRAM_3_addr_rd, g6_toSRAM_3_wdata, g6_toSRAM_3_wmask, g6_toSRAM_3_re, g6_toSRAM_3_we, g6_toSRAM_3_ack, g6_toSRAM_3_selectedOH, g6_toSRAM_3_array, g6_toSRAM_4_addr, g6_toSRAM_4_addr_rd, g6_toSRAM_4_wdata, g6_toSRAM_4_wmask, g6_toSRAM_4_re, g6_toSRAM_4_we, g6_toSRAM_4_ack, g6_toSRAM_4_selectedOH, g6_toSRAM_4_array, g6_toSRAM_5_addr, g6_toSRAM_5_addr_rd, g6_toSRAM_5_wdata, g6_toSRAM_5_wmask, g6_toSRAM_5_re, g6_toSRAM_5_we, g6_toSRAM_5_ack, g6_toSRAM_5_selectedOH, g6_toSRAM_5_array, g6_toSRAM_6_addr, g6_toSRAM_6_addr_rd, g6_toSRAM_6_wdata, g6_toSRAM_6_wmask, g6_toSRAM_6_re, g6_toSRAM_6_we, g6_toSRAM_6_ack, g6_toSRAM_6_selectedOH, g6_toSRAM_6_array, g6_toSRAM_7_addr, g6_toSRAM_7_addr_rd, g6_toSRAM_7_wdata, g6_toSRAM_7_wmask, g6_toSRAM_7_re, g6_toSRAM_7_we, g6_toSRAM_7_ack, g6_toSRAM_7_selectedOH, g6_toSRAM_7_array};
  wire [818:0] xbus6 = {x6_mbist_ack, x6_mbist_outdata, x6_toSRAM_0_addr, x6_toSRAM_0_addr_rd, x6_toSRAM_0_wdata, x6_toSRAM_0_wmask, x6_toSRAM_0_re, x6_toSRAM_0_we, x6_toSRAM_0_ack, x6_toSRAM_0_selectedOH, x6_toSRAM_0_array, x6_toSRAM_1_addr, x6_toSRAM_1_addr_rd, x6_toSRAM_1_wdata, x6_toSRAM_1_wmask, x6_toSRAM_1_re, x6_toSRAM_1_we, x6_toSRAM_1_ack, x6_toSRAM_1_selectedOH, x6_toSRAM_1_array, x6_toSRAM_2_addr, x6_toSRAM_2_addr_rd, x6_toSRAM_2_wdata, x6_toSRAM_2_wmask, x6_toSRAM_2_re, x6_toSRAM_2_we, x6_toSRAM_2_ack, x6_toSRAM_2_selectedOH, x6_toSRAM_2_array, x6_toSRAM_3_addr, x6_toSRAM_3_addr_rd, x6_toSRAM_3_wdata, x6_toSRAM_3_wmask, x6_toSRAM_3_re, x6_toSRAM_3_we, x6_toSRAM_3_ack, x6_toSRAM_3_selectedOH, x6_toSRAM_3_array, x6_toSRAM_4_addr, x6_toSRAM_4_addr_rd, x6_toSRAM_4_wdata, x6_toSRAM_4_wmask, x6_toSRAM_4_re, x6_toSRAM_4_we, x6_toSRAM_4_ack, x6_toSRAM_4_selectedOH, x6_toSRAM_4_array, x6_toSRAM_5_addr, x6_toSRAM_5_addr_rd, x6_toSRAM_5_wdata, x6_toSRAM_5_wmask, x6_toSRAM_5_re, x6_toSRAM_5_we, x6_toSRAM_5_ack, x6_toSRAM_5_selectedOH, x6_toSRAM_5_array, x6_toSRAM_6_addr, x6_toSRAM_6_addr_rd, x6_toSRAM_6_wdata, x6_toSRAM_6_wmask, x6_toSRAM_6_re, x6_toSRAM_6_we, x6_toSRAM_6_ack, x6_toSRAM_6_selectedOH, x6_toSRAM_6_array, x6_toSRAM_7_addr, x6_toSRAM_7_addr_rd, x6_toSRAM_7_wdata, x6_toSRAM_7_wmask, x6_toSRAM_7_re, x6_toSRAM_7_we, x6_toSRAM_7_ack, x6_toSRAM_7_selectedOH, x6_toSRAM_7_array};
  task automatic detail6();
    if (g6_mbist_ack !== x6_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.mbist_ack golden=%h impl=%h", cyc, g6_mbist_ack, x6_mbist_ack); end
    if (g6_mbist_outdata !== x6_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.mbist_outdata golden=%h impl=%h", cyc, g6_mbist_outdata, x6_mbist_outdata); end
    if (g6_toSRAM_0_addr !== x6_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_addr golden=%h impl=%h", cyc, g6_toSRAM_0_addr, x6_toSRAM_0_addr); end
    if (g6_toSRAM_0_addr_rd !== x6_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_0_addr_rd, x6_toSRAM_0_addr_rd); end
    if (g6_toSRAM_0_wdata !== x6_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_wdata golden=%h impl=%h", cyc, g6_toSRAM_0_wdata, x6_toSRAM_0_wdata); end
    if (g6_toSRAM_0_wmask !== x6_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_wmask golden=%h impl=%h", cyc, g6_toSRAM_0_wmask, x6_toSRAM_0_wmask); end
    if (g6_toSRAM_0_re !== x6_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_re golden=%h impl=%h", cyc, g6_toSRAM_0_re, x6_toSRAM_0_re); end
    if (g6_toSRAM_0_we !== x6_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_we golden=%h impl=%h", cyc, g6_toSRAM_0_we, x6_toSRAM_0_we); end
    if (g6_toSRAM_0_ack !== x6_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_ack golden=%h impl=%h", cyc, g6_toSRAM_0_ack, x6_toSRAM_0_ack); end
    if (g6_toSRAM_0_selectedOH !== x6_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_0_selectedOH, x6_toSRAM_0_selectedOH); end
    if (g6_toSRAM_0_array !== x6_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_0_array golden=%h impl=%h", cyc, g6_toSRAM_0_array, x6_toSRAM_0_array); end
    if (g6_toSRAM_1_addr !== x6_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_addr golden=%h impl=%h", cyc, g6_toSRAM_1_addr, x6_toSRAM_1_addr); end
    if (g6_toSRAM_1_addr_rd !== x6_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_1_addr_rd, x6_toSRAM_1_addr_rd); end
    if (g6_toSRAM_1_wdata !== x6_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_wdata golden=%h impl=%h", cyc, g6_toSRAM_1_wdata, x6_toSRAM_1_wdata); end
    if (g6_toSRAM_1_wmask !== x6_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_wmask golden=%h impl=%h", cyc, g6_toSRAM_1_wmask, x6_toSRAM_1_wmask); end
    if (g6_toSRAM_1_re !== x6_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_re golden=%h impl=%h", cyc, g6_toSRAM_1_re, x6_toSRAM_1_re); end
    if (g6_toSRAM_1_we !== x6_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_we golden=%h impl=%h", cyc, g6_toSRAM_1_we, x6_toSRAM_1_we); end
    if (g6_toSRAM_1_ack !== x6_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_ack golden=%h impl=%h", cyc, g6_toSRAM_1_ack, x6_toSRAM_1_ack); end
    if (g6_toSRAM_1_selectedOH !== x6_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_1_selectedOH, x6_toSRAM_1_selectedOH); end
    if (g6_toSRAM_1_array !== x6_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_1_array golden=%h impl=%h", cyc, g6_toSRAM_1_array, x6_toSRAM_1_array); end
    if (g6_toSRAM_2_addr !== x6_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_addr golden=%h impl=%h", cyc, g6_toSRAM_2_addr, x6_toSRAM_2_addr); end
    if (g6_toSRAM_2_addr_rd !== x6_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_2_addr_rd, x6_toSRAM_2_addr_rd); end
    if (g6_toSRAM_2_wdata !== x6_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_wdata golden=%h impl=%h", cyc, g6_toSRAM_2_wdata, x6_toSRAM_2_wdata); end
    if (g6_toSRAM_2_wmask !== x6_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_wmask golden=%h impl=%h", cyc, g6_toSRAM_2_wmask, x6_toSRAM_2_wmask); end
    if (g6_toSRAM_2_re !== x6_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_re golden=%h impl=%h", cyc, g6_toSRAM_2_re, x6_toSRAM_2_re); end
    if (g6_toSRAM_2_we !== x6_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_we golden=%h impl=%h", cyc, g6_toSRAM_2_we, x6_toSRAM_2_we); end
    if (g6_toSRAM_2_ack !== x6_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_ack golden=%h impl=%h", cyc, g6_toSRAM_2_ack, x6_toSRAM_2_ack); end
    if (g6_toSRAM_2_selectedOH !== x6_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_2_selectedOH, x6_toSRAM_2_selectedOH); end
    if (g6_toSRAM_2_array !== x6_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_2_array golden=%h impl=%h", cyc, g6_toSRAM_2_array, x6_toSRAM_2_array); end
    if (g6_toSRAM_3_addr !== x6_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_addr golden=%h impl=%h", cyc, g6_toSRAM_3_addr, x6_toSRAM_3_addr); end
    if (g6_toSRAM_3_addr_rd !== x6_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_3_addr_rd, x6_toSRAM_3_addr_rd); end
    if (g6_toSRAM_3_wdata !== x6_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_wdata golden=%h impl=%h", cyc, g6_toSRAM_3_wdata, x6_toSRAM_3_wdata); end
    if (g6_toSRAM_3_wmask !== x6_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_wmask golden=%h impl=%h", cyc, g6_toSRAM_3_wmask, x6_toSRAM_3_wmask); end
    if (g6_toSRAM_3_re !== x6_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_re golden=%h impl=%h", cyc, g6_toSRAM_3_re, x6_toSRAM_3_re); end
    if (g6_toSRAM_3_we !== x6_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_we golden=%h impl=%h", cyc, g6_toSRAM_3_we, x6_toSRAM_3_we); end
    if (g6_toSRAM_3_ack !== x6_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_ack golden=%h impl=%h", cyc, g6_toSRAM_3_ack, x6_toSRAM_3_ack); end
    if (g6_toSRAM_3_selectedOH !== x6_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_3_selectedOH, x6_toSRAM_3_selectedOH); end
    if (g6_toSRAM_3_array !== x6_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_3_array golden=%h impl=%h", cyc, g6_toSRAM_3_array, x6_toSRAM_3_array); end
    if (g6_toSRAM_4_addr !== x6_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_addr golden=%h impl=%h", cyc, g6_toSRAM_4_addr, x6_toSRAM_4_addr); end
    if (g6_toSRAM_4_addr_rd !== x6_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_4_addr_rd, x6_toSRAM_4_addr_rd); end
    if (g6_toSRAM_4_wdata !== x6_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_wdata golden=%h impl=%h", cyc, g6_toSRAM_4_wdata, x6_toSRAM_4_wdata); end
    if (g6_toSRAM_4_wmask !== x6_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_wmask golden=%h impl=%h", cyc, g6_toSRAM_4_wmask, x6_toSRAM_4_wmask); end
    if (g6_toSRAM_4_re !== x6_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_re golden=%h impl=%h", cyc, g6_toSRAM_4_re, x6_toSRAM_4_re); end
    if (g6_toSRAM_4_we !== x6_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_we golden=%h impl=%h", cyc, g6_toSRAM_4_we, x6_toSRAM_4_we); end
    if (g6_toSRAM_4_ack !== x6_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_ack golden=%h impl=%h", cyc, g6_toSRAM_4_ack, x6_toSRAM_4_ack); end
    if (g6_toSRAM_4_selectedOH !== x6_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_4_selectedOH, x6_toSRAM_4_selectedOH); end
    if (g6_toSRAM_4_array !== x6_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_4_array golden=%h impl=%h", cyc, g6_toSRAM_4_array, x6_toSRAM_4_array); end
    if (g6_toSRAM_5_addr !== x6_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_addr golden=%h impl=%h", cyc, g6_toSRAM_5_addr, x6_toSRAM_5_addr); end
    if (g6_toSRAM_5_addr_rd !== x6_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_5_addr_rd, x6_toSRAM_5_addr_rd); end
    if (g6_toSRAM_5_wdata !== x6_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_wdata golden=%h impl=%h", cyc, g6_toSRAM_5_wdata, x6_toSRAM_5_wdata); end
    if (g6_toSRAM_5_wmask !== x6_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_wmask golden=%h impl=%h", cyc, g6_toSRAM_5_wmask, x6_toSRAM_5_wmask); end
    if (g6_toSRAM_5_re !== x6_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_re golden=%h impl=%h", cyc, g6_toSRAM_5_re, x6_toSRAM_5_re); end
    if (g6_toSRAM_5_we !== x6_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_we golden=%h impl=%h", cyc, g6_toSRAM_5_we, x6_toSRAM_5_we); end
    if (g6_toSRAM_5_ack !== x6_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_ack golden=%h impl=%h", cyc, g6_toSRAM_5_ack, x6_toSRAM_5_ack); end
    if (g6_toSRAM_5_selectedOH !== x6_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_5_selectedOH, x6_toSRAM_5_selectedOH); end
    if (g6_toSRAM_5_array !== x6_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_5_array golden=%h impl=%h", cyc, g6_toSRAM_5_array, x6_toSRAM_5_array); end
    if (g6_toSRAM_6_addr !== x6_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_addr golden=%h impl=%h", cyc, g6_toSRAM_6_addr, x6_toSRAM_6_addr); end
    if (g6_toSRAM_6_addr_rd !== x6_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_6_addr_rd, x6_toSRAM_6_addr_rd); end
    if (g6_toSRAM_6_wdata !== x6_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_wdata golden=%h impl=%h", cyc, g6_toSRAM_6_wdata, x6_toSRAM_6_wdata); end
    if (g6_toSRAM_6_wmask !== x6_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_wmask golden=%h impl=%h", cyc, g6_toSRAM_6_wmask, x6_toSRAM_6_wmask); end
    if (g6_toSRAM_6_re !== x6_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_re golden=%h impl=%h", cyc, g6_toSRAM_6_re, x6_toSRAM_6_re); end
    if (g6_toSRAM_6_we !== x6_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_we golden=%h impl=%h", cyc, g6_toSRAM_6_we, x6_toSRAM_6_we); end
    if (g6_toSRAM_6_ack !== x6_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_ack golden=%h impl=%h", cyc, g6_toSRAM_6_ack, x6_toSRAM_6_ack); end
    if (g6_toSRAM_6_selectedOH !== x6_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_6_selectedOH, x6_toSRAM_6_selectedOH); end
    if (g6_toSRAM_6_array !== x6_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_6_array golden=%h impl=%h", cyc, g6_toSRAM_6_array, x6_toSRAM_6_array); end
    if (g6_toSRAM_7_addr !== x6_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_addr golden=%h impl=%h", cyc, g6_toSRAM_7_addr, x6_toSRAM_7_addr); end
    if (g6_toSRAM_7_addr_rd !== x6_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g6_toSRAM_7_addr_rd, x6_toSRAM_7_addr_rd); end
    if (g6_toSRAM_7_wdata !== x6_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_wdata golden=%h impl=%h", cyc, g6_toSRAM_7_wdata, x6_toSRAM_7_wdata); end
    if (g6_toSRAM_7_wmask !== x6_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_wmask golden=%h impl=%h", cyc, g6_toSRAM_7_wmask, x6_toSRAM_7_wmask); end
    if (g6_toSRAM_7_re !== x6_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_re golden=%h impl=%h", cyc, g6_toSRAM_7_re, x6_toSRAM_7_re); end
    if (g6_toSRAM_7_we !== x6_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_we golden=%h impl=%h", cyc, g6_toSRAM_7_we, x6_toSRAM_7_we); end
    if (g6_toSRAM_7_ack !== x6_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_ack golden=%h impl=%h", cyc, g6_toSRAM_7_ack, x6_toSRAM_7_ack); end
    if (g6_toSRAM_7_selectedOH !== x6_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g6_toSRAM_7_selectedOH, x6_toSRAM_7_selectedOH); end
    if (g6_toSRAM_7_array !== x6_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay2.toSRAM_7_array golden=%h impl=%h", cyc, g6_toSRAM_7_array, x6_toSRAM_7_array); end
  endtask

  // ======================== [07] MbistPipeIcacheDataWay3 ========================
  logic [65:0] v7_rd0;
  logic [65:0] v7_rd1;
  logic [65:0] v7_rd2;
  logic [65:0] v7_rd3;
  logic [65:0] v7_rd4;
  logic [65:0] v7_rd5;
  logic [65:0] v7_rd6;
  logic [65:0] v7_rd7;
  logic g7_mbist_ack;
  logic [65:0] g7_mbist_outdata;
  logic [8:0] g7_toSRAM_0_addr;
  logic [8:0] g7_toSRAM_0_addr_rd;
  logic [65:0] g7_toSRAM_0_wdata;
  logic g7_toSRAM_0_wmask;
  logic g7_toSRAM_0_re;
  logic g7_toSRAM_0_we;
  logic g7_toSRAM_0_ack;
  logic g7_toSRAM_0_selectedOH;
  logic [4:0] g7_toSRAM_0_array;
  logic [8:0] g7_toSRAM_1_addr;
  logic [8:0] g7_toSRAM_1_addr_rd;
  logic [65:0] g7_toSRAM_1_wdata;
  logic g7_toSRAM_1_wmask;
  logic g7_toSRAM_1_re;
  logic g7_toSRAM_1_we;
  logic g7_toSRAM_1_ack;
  logic g7_toSRAM_1_selectedOH;
  logic [4:0] g7_toSRAM_1_array;
  logic [8:0] g7_toSRAM_2_addr;
  logic [8:0] g7_toSRAM_2_addr_rd;
  logic [65:0] g7_toSRAM_2_wdata;
  logic g7_toSRAM_2_wmask;
  logic g7_toSRAM_2_re;
  logic g7_toSRAM_2_we;
  logic g7_toSRAM_2_ack;
  logic g7_toSRAM_2_selectedOH;
  logic [4:0] g7_toSRAM_2_array;
  logic [8:0] g7_toSRAM_3_addr;
  logic [8:0] g7_toSRAM_3_addr_rd;
  logic [65:0] g7_toSRAM_3_wdata;
  logic g7_toSRAM_3_wmask;
  logic g7_toSRAM_3_re;
  logic g7_toSRAM_3_we;
  logic g7_toSRAM_3_ack;
  logic g7_toSRAM_3_selectedOH;
  logic [4:0] g7_toSRAM_3_array;
  logic [8:0] g7_toSRAM_4_addr;
  logic [8:0] g7_toSRAM_4_addr_rd;
  logic [65:0] g7_toSRAM_4_wdata;
  logic g7_toSRAM_4_wmask;
  logic g7_toSRAM_4_re;
  logic g7_toSRAM_4_we;
  logic g7_toSRAM_4_ack;
  logic g7_toSRAM_4_selectedOH;
  logic [5:0] g7_toSRAM_4_array;
  logic [8:0] g7_toSRAM_5_addr;
  logic [8:0] g7_toSRAM_5_addr_rd;
  logic [65:0] g7_toSRAM_5_wdata;
  logic g7_toSRAM_5_wmask;
  logic g7_toSRAM_5_re;
  logic g7_toSRAM_5_we;
  logic g7_toSRAM_5_ack;
  logic g7_toSRAM_5_selectedOH;
  logic [5:0] g7_toSRAM_5_array;
  logic [8:0] g7_toSRAM_6_addr;
  logic [8:0] g7_toSRAM_6_addr_rd;
  logic [65:0] g7_toSRAM_6_wdata;
  logic g7_toSRAM_6_wmask;
  logic g7_toSRAM_6_re;
  logic g7_toSRAM_6_we;
  logic g7_toSRAM_6_ack;
  logic g7_toSRAM_6_selectedOH;
  logic [5:0] g7_toSRAM_6_array;
  logic [8:0] g7_toSRAM_7_addr;
  logic [8:0] g7_toSRAM_7_addr_rd;
  logic [65:0] g7_toSRAM_7_wdata;
  logic g7_toSRAM_7_wmask;
  logic g7_toSRAM_7_re;
  logic g7_toSRAM_7_we;
  logic g7_toSRAM_7_ack;
  logic g7_toSRAM_7_selectedOH;
  logic [5:0] g7_toSRAM_7_array;
  logic x7_mbist_ack;
  logic [65:0] x7_mbist_outdata;
  logic [8:0] x7_toSRAM_0_addr;
  logic [8:0] x7_toSRAM_0_addr_rd;
  logic [65:0] x7_toSRAM_0_wdata;
  logic x7_toSRAM_0_wmask;
  logic x7_toSRAM_0_re;
  logic x7_toSRAM_0_we;
  logic x7_toSRAM_0_ack;
  logic x7_toSRAM_0_selectedOH;
  logic [4:0] x7_toSRAM_0_array;
  logic [8:0] x7_toSRAM_1_addr;
  logic [8:0] x7_toSRAM_1_addr_rd;
  logic [65:0] x7_toSRAM_1_wdata;
  logic x7_toSRAM_1_wmask;
  logic x7_toSRAM_1_re;
  logic x7_toSRAM_1_we;
  logic x7_toSRAM_1_ack;
  logic x7_toSRAM_1_selectedOH;
  logic [4:0] x7_toSRAM_1_array;
  logic [8:0] x7_toSRAM_2_addr;
  logic [8:0] x7_toSRAM_2_addr_rd;
  logic [65:0] x7_toSRAM_2_wdata;
  logic x7_toSRAM_2_wmask;
  logic x7_toSRAM_2_re;
  logic x7_toSRAM_2_we;
  logic x7_toSRAM_2_ack;
  logic x7_toSRAM_2_selectedOH;
  logic [4:0] x7_toSRAM_2_array;
  logic [8:0] x7_toSRAM_3_addr;
  logic [8:0] x7_toSRAM_3_addr_rd;
  logic [65:0] x7_toSRAM_3_wdata;
  logic x7_toSRAM_3_wmask;
  logic x7_toSRAM_3_re;
  logic x7_toSRAM_3_we;
  logic x7_toSRAM_3_ack;
  logic x7_toSRAM_3_selectedOH;
  logic [4:0] x7_toSRAM_3_array;
  logic [8:0] x7_toSRAM_4_addr;
  logic [8:0] x7_toSRAM_4_addr_rd;
  logic [65:0] x7_toSRAM_4_wdata;
  logic x7_toSRAM_4_wmask;
  logic x7_toSRAM_4_re;
  logic x7_toSRAM_4_we;
  logic x7_toSRAM_4_ack;
  logic x7_toSRAM_4_selectedOH;
  logic [5:0] x7_toSRAM_4_array;
  logic [8:0] x7_toSRAM_5_addr;
  logic [8:0] x7_toSRAM_5_addr_rd;
  logic [65:0] x7_toSRAM_5_wdata;
  logic x7_toSRAM_5_wmask;
  logic x7_toSRAM_5_re;
  logic x7_toSRAM_5_we;
  logic x7_toSRAM_5_ack;
  logic x7_toSRAM_5_selectedOH;
  logic [5:0] x7_toSRAM_5_array;
  logic [8:0] x7_toSRAM_6_addr;
  logic [8:0] x7_toSRAM_6_addr_rd;
  logic [65:0] x7_toSRAM_6_wdata;
  logic x7_toSRAM_6_wmask;
  logic x7_toSRAM_6_re;
  logic x7_toSRAM_6_we;
  logic x7_toSRAM_6_ack;
  logic x7_toSRAM_6_selectedOH;
  logic [5:0] x7_toSRAM_6_array;
  logic [8:0] x7_toSRAM_7_addr;
  logic [8:0] x7_toSRAM_7_addr_rd;
  logic [65:0] x7_toSRAM_7_wdata;
  logic x7_toSRAM_7_wmask;
  logic x7_toSRAM_7_re;
  logic x7_toSRAM_7_we;
  logic x7_toSRAM_7_ack;
  logic x7_toSRAM_7_selectedOH;
  logic [5:0] x7_toSRAM_7_array;
  bit [7:0] cov_spread7;
  bit [65:0] cov_od0_7, cov_od1_7;
  bit cov_ack0_7, cov_ack1_7;
  MbistPipeIcacheDataWay3 u_g7 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v7_rd0),
    .toSRAM_1_rdata (v7_rd1),
    .toSRAM_2_rdata (v7_rd2),
    .toSRAM_3_rdata (v7_rd3),
    .toSRAM_4_rdata (v7_rd4),
    .toSRAM_5_rdata (v7_rd5),
    .toSRAM_6_rdata (v7_rd6),
    .toSRAM_7_rdata (v7_rd7),
    .mbist_ack (g7_mbist_ack),
    .mbist_outdata (g7_mbist_outdata),
    .toSRAM_0_addr (g7_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g7_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g7_toSRAM_0_wdata),
    .toSRAM_0_wmask (g7_toSRAM_0_wmask),
    .toSRAM_0_re (g7_toSRAM_0_re),
    .toSRAM_0_we (g7_toSRAM_0_we),
    .toSRAM_0_ack (g7_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g7_toSRAM_0_selectedOH),
    .toSRAM_0_array (g7_toSRAM_0_array),
    .toSRAM_1_addr (g7_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g7_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g7_toSRAM_1_wdata),
    .toSRAM_1_wmask (g7_toSRAM_1_wmask),
    .toSRAM_1_re (g7_toSRAM_1_re),
    .toSRAM_1_we (g7_toSRAM_1_we),
    .toSRAM_1_ack (g7_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g7_toSRAM_1_selectedOH),
    .toSRAM_1_array (g7_toSRAM_1_array),
    .toSRAM_2_addr (g7_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g7_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g7_toSRAM_2_wdata),
    .toSRAM_2_wmask (g7_toSRAM_2_wmask),
    .toSRAM_2_re (g7_toSRAM_2_re),
    .toSRAM_2_we (g7_toSRAM_2_we),
    .toSRAM_2_ack (g7_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g7_toSRAM_2_selectedOH),
    .toSRAM_2_array (g7_toSRAM_2_array),
    .toSRAM_3_addr (g7_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g7_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g7_toSRAM_3_wdata),
    .toSRAM_3_wmask (g7_toSRAM_3_wmask),
    .toSRAM_3_re (g7_toSRAM_3_re),
    .toSRAM_3_we (g7_toSRAM_3_we),
    .toSRAM_3_ack (g7_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g7_toSRAM_3_selectedOH),
    .toSRAM_3_array (g7_toSRAM_3_array),
    .toSRAM_4_addr (g7_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g7_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g7_toSRAM_4_wdata),
    .toSRAM_4_wmask (g7_toSRAM_4_wmask),
    .toSRAM_4_re (g7_toSRAM_4_re),
    .toSRAM_4_we (g7_toSRAM_4_we),
    .toSRAM_4_ack (g7_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g7_toSRAM_4_selectedOH),
    .toSRAM_4_array (g7_toSRAM_4_array),
    .toSRAM_5_addr (g7_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g7_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g7_toSRAM_5_wdata),
    .toSRAM_5_wmask (g7_toSRAM_5_wmask),
    .toSRAM_5_re (g7_toSRAM_5_re),
    .toSRAM_5_we (g7_toSRAM_5_we),
    .toSRAM_5_ack (g7_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g7_toSRAM_5_selectedOH),
    .toSRAM_5_array (g7_toSRAM_5_array),
    .toSRAM_6_addr (g7_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g7_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g7_toSRAM_6_wdata),
    .toSRAM_6_wmask (g7_toSRAM_6_wmask),
    .toSRAM_6_re (g7_toSRAM_6_re),
    .toSRAM_6_we (g7_toSRAM_6_we),
    .toSRAM_6_ack (g7_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g7_toSRAM_6_selectedOH),
    .toSRAM_6_array (g7_toSRAM_6_array),
    .toSRAM_7_addr (g7_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g7_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g7_toSRAM_7_wdata),
    .toSRAM_7_wmask (g7_toSRAM_7_wmask),
    .toSRAM_7_re (g7_toSRAM_7_re),
    .toSRAM_7_we (g7_toSRAM_7_we),
    .toSRAM_7_ack (g7_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g7_toSRAM_7_selectedOH),
    .toSRAM_7_array (g7_toSRAM_7_array)
  );
  MbistPipeIcacheDataWay3_xs u_x7 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[65:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v7_rd0),
    .toSRAM_1_rdata (v7_rd1),
    .toSRAM_2_rdata (v7_rd2),
    .toSRAM_3_rdata (v7_rd3),
    .toSRAM_4_rdata (v7_rd4),
    .toSRAM_5_rdata (v7_rd5),
    .toSRAM_6_rdata (v7_rd6),
    .toSRAM_7_rdata (v7_rd7),
    .mbist_ack (x7_mbist_ack),
    .mbist_outdata (x7_mbist_outdata),
    .toSRAM_0_addr (x7_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x7_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x7_toSRAM_0_wdata),
    .toSRAM_0_wmask (x7_toSRAM_0_wmask),
    .toSRAM_0_re (x7_toSRAM_0_re),
    .toSRAM_0_we (x7_toSRAM_0_we),
    .toSRAM_0_ack (x7_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x7_toSRAM_0_selectedOH),
    .toSRAM_0_array (x7_toSRAM_0_array),
    .toSRAM_1_addr (x7_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x7_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x7_toSRAM_1_wdata),
    .toSRAM_1_wmask (x7_toSRAM_1_wmask),
    .toSRAM_1_re (x7_toSRAM_1_re),
    .toSRAM_1_we (x7_toSRAM_1_we),
    .toSRAM_1_ack (x7_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x7_toSRAM_1_selectedOH),
    .toSRAM_1_array (x7_toSRAM_1_array),
    .toSRAM_2_addr (x7_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x7_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x7_toSRAM_2_wdata),
    .toSRAM_2_wmask (x7_toSRAM_2_wmask),
    .toSRAM_2_re (x7_toSRAM_2_re),
    .toSRAM_2_we (x7_toSRAM_2_we),
    .toSRAM_2_ack (x7_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x7_toSRAM_2_selectedOH),
    .toSRAM_2_array (x7_toSRAM_2_array),
    .toSRAM_3_addr (x7_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x7_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x7_toSRAM_3_wdata),
    .toSRAM_3_wmask (x7_toSRAM_3_wmask),
    .toSRAM_3_re (x7_toSRAM_3_re),
    .toSRAM_3_we (x7_toSRAM_3_we),
    .toSRAM_3_ack (x7_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x7_toSRAM_3_selectedOH),
    .toSRAM_3_array (x7_toSRAM_3_array),
    .toSRAM_4_addr (x7_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x7_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x7_toSRAM_4_wdata),
    .toSRAM_4_wmask (x7_toSRAM_4_wmask),
    .toSRAM_4_re (x7_toSRAM_4_re),
    .toSRAM_4_we (x7_toSRAM_4_we),
    .toSRAM_4_ack (x7_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x7_toSRAM_4_selectedOH),
    .toSRAM_4_array (x7_toSRAM_4_array),
    .toSRAM_5_addr (x7_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x7_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x7_toSRAM_5_wdata),
    .toSRAM_5_wmask (x7_toSRAM_5_wmask),
    .toSRAM_5_re (x7_toSRAM_5_re),
    .toSRAM_5_we (x7_toSRAM_5_we),
    .toSRAM_5_ack (x7_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x7_toSRAM_5_selectedOH),
    .toSRAM_5_array (x7_toSRAM_5_array),
    .toSRAM_6_addr (x7_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x7_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x7_toSRAM_6_wdata),
    .toSRAM_6_wmask (x7_toSRAM_6_wmask),
    .toSRAM_6_re (x7_toSRAM_6_re),
    .toSRAM_6_we (x7_toSRAM_6_we),
    .toSRAM_6_ack (x7_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x7_toSRAM_6_selectedOH),
    .toSRAM_6_array (x7_toSRAM_6_array),
    .toSRAM_7_addr (x7_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x7_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x7_toSRAM_7_wdata),
    .toSRAM_7_wmask (x7_toSRAM_7_wmask),
    .toSRAM_7_re (x7_toSRAM_7_re),
    .toSRAM_7_we (x7_toSRAM_7_we),
    .toSRAM_7_ack (x7_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x7_toSRAM_7_selectedOH),
    .toSRAM_7_array (x7_toSRAM_7_array)
  );
  wire [822:0] gbus7 = {g7_mbist_ack, g7_mbist_outdata, g7_toSRAM_0_addr, g7_toSRAM_0_addr_rd, g7_toSRAM_0_wdata, g7_toSRAM_0_wmask, g7_toSRAM_0_re, g7_toSRAM_0_we, g7_toSRAM_0_ack, g7_toSRAM_0_selectedOH, g7_toSRAM_0_array, g7_toSRAM_1_addr, g7_toSRAM_1_addr_rd, g7_toSRAM_1_wdata, g7_toSRAM_1_wmask, g7_toSRAM_1_re, g7_toSRAM_1_we, g7_toSRAM_1_ack, g7_toSRAM_1_selectedOH, g7_toSRAM_1_array, g7_toSRAM_2_addr, g7_toSRAM_2_addr_rd, g7_toSRAM_2_wdata, g7_toSRAM_2_wmask, g7_toSRAM_2_re, g7_toSRAM_2_we, g7_toSRAM_2_ack, g7_toSRAM_2_selectedOH, g7_toSRAM_2_array, g7_toSRAM_3_addr, g7_toSRAM_3_addr_rd, g7_toSRAM_3_wdata, g7_toSRAM_3_wmask, g7_toSRAM_3_re, g7_toSRAM_3_we, g7_toSRAM_3_ack, g7_toSRAM_3_selectedOH, g7_toSRAM_3_array, g7_toSRAM_4_addr, g7_toSRAM_4_addr_rd, g7_toSRAM_4_wdata, g7_toSRAM_4_wmask, g7_toSRAM_4_re, g7_toSRAM_4_we, g7_toSRAM_4_ack, g7_toSRAM_4_selectedOH, g7_toSRAM_4_array, g7_toSRAM_5_addr, g7_toSRAM_5_addr_rd, g7_toSRAM_5_wdata, g7_toSRAM_5_wmask, g7_toSRAM_5_re, g7_toSRAM_5_we, g7_toSRAM_5_ack, g7_toSRAM_5_selectedOH, g7_toSRAM_5_array, g7_toSRAM_6_addr, g7_toSRAM_6_addr_rd, g7_toSRAM_6_wdata, g7_toSRAM_6_wmask, g7_toSRAM_6_re, g7_toSRAM_6_we, g7_toSRAM_6_ack, g7_toSRAM_6_selectedOH, g7_toSRAM_6_array, g7_toSRAM_7_addr, g7_toSRAM_7_addr_rd, g7_toSRAM_7_wdata, g7_toSRAM_7_wmask, g7_toSRAM_7_re, g7_toSRAM_7_we, g7_toSRAM_7_ack, g7_toSRAM_7_selectedOH, g7_toSRAM_7_array};
  wire [822:0] xbus7 = {x7_mbist_ack, x7_mbist_outdata, x7_toSRAM_0_addr, x7_toSRAM_0_addr_rd, x7_toSRAM_0_wdata, x7_toSRAM_0_wmask, x7_toSRAM_0_re, x7_toSRAM_0_we, x7_toSRAM_0_ack, x7_toSRAM_0_selectedOH, x7_toSRAM_0_array, x7_toSRAM_1_addr, x7_toSRAM_1_addr_rd, x7_toSRAM_1_wdata, x7_toSRAM_1_wmask, x7_toSRAM_1_re, x7_toSRAM_1_we, x7_toSRAM_1_ack, x7_toSRAM_1_selectedOH, x7_toSRAM_1_array, x7_toSRAM_2_addr, x7_toSRAM_2_addr_rd, x7_toSRAM_2_wdata, x7_toSRAM_2_wmask, x7_toSRAM_2_re, x7_toSRAM_2_we, x7_toSRAM_2_ack, x7_toSRAM_2_selectedOH, x7_toSRAM_2_array, x7_toSRAM_3_addr, x7_toSRAM_3_addr_rd, x7_toSRAM_3_wdata, x7_toSRAM_3_wmask, x7_toSRAM_3_re, x7_toSRAM_3_we, x7_toSRAM_3_ack, x7_toSRAM_3_selectedOH, x7_toSRAM_3_array, x7_toSRAM_4_addr, x7_toSRAM_4_addr_rd, x7_toSRAM_4_wdata, x7_toSRAM_4_wmask, x7_toSRAM_4_re, x7_toSRAM_4_we, x7_toSRAM_4_ack, x7_toSRAM_4_selectedOH, x7_toSRAM_4_array, x7_toSRAM_5_addr, x7_toSRAM_5_addr_rd, x7_toSRAM_5_wdata, x7_toSRAM_5_wmask, x7_toSRAM_5_re, x7_toSRAM_5_we, x7_toSRAM_5_ack, x7_toSRAM_5_selectedOH, x7_toSRAM_5_array, x7_toSRAM_6_addr, x7_toSRAM_6_addr_rd, x7_toSRAM_6_wdata, x7_toSRAM_6_wmask, x7_toSRAM_6_re, x7_toSRAM_6_we, x7_toSRAM_6_ack, x7_toSRAM_6_selectedOH, x7_toSRAM_6_array, x7_toSRAM_7_addr, x7_toSRAM_7_addr_rd, x7_toSRAM_7_wdata, x7_toSRAM_7_wmask, x7_toSRAM_7_re, x7_toSRAM_7_we, x7_toSRAM_7_ack, x7_toSRAM_7_selectedOH, x7_toSRAM_7_array};
  task automatic detail7();
    if (g7_mbist_ack !== x7_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.mbist_ack golden=%h impl=%h", cyc, g7_mbist_ack, x7_mbist_ack); end
    if (g7_mbist_outdata !== x7_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.mbist_outdata golden=%h impl=%h", cyc, g7_mbist_outdata, x7_mbist_outdata); end
    if (g7_toSRAM_0_addr !== x7_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_addr golden=%h impl=%h", cyc, g7_toSRAM_0_addr, x7_toSRAM_0_addr); end
    if (g7_toSRAM_0_addr_rd !== x7_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_0_addr_rd, x7_toSRAM_0_addr_rd); end
    if (g7_toSRAM_0_wdata !== x7_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_wdata golden=%h impl=%h", cyc, g7_toSRAM_0_wdata, x7_toSRAM_0_wdata); end
    if (g7_toSRAM_0_wmask !== x7_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_wmask golden=%h impl=%h", cyc, g7_toSRAM_0_wmask, x7_toSRAM_0_wmask); end
    if (g7_toSRAM_0_re !== x7_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_re golden=%h impl=%h", cyc, g7_toSRAM_0_re, x7_toSRAM_0_re); end
    if (g7_toSRAM_0_we !== x7_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_we golden=%h impl=%h", cyc, g7_toSRAM_0_we, x7_toSRAM_0_we); end
    if (g7_toSRAM_0_ack !== x7_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_ack golden=%h impl=%h", cyc, g7_toSRAM_0_ack, x7_toSRAM_0_ack); end
    if (g7_toSRAM_0_selectedOH !== x7_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_0_selectedOH, x7_toSRAM_0_selectedOH); end
    if (g7_toSRAM_0_array !== x7_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_0_array golden=%h impl=%h", cyc, g7_toSRAM_0_array, x7_toSRAM_0_array); end
    if (g7_toSRAM_1_addr !== x7_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_addr golden=%h impl=%h", cyc, g7_toSRAM_1_addr, x7_toSRAM_1_addr); end
    if (g7_toSRAM_1_addr_rd !== x7_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_1_addr_rd, x7_toSRAM_1_addr_rd); end
    if (g7_toSRAM_1_wdata !== x7_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_wdata golden=%h impl=%h", cyc, g7_toSRAM_1_wdata, x7_toSRAM_1_wdata); end
    if (g7_toSRAM_1_wmask !== x7_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_wmask golden=%h impl=%h", cyc, g7_toSRAM_1_wmask, x7_toSRAM_1_wmask); end
    if (g7_toSRAM_1_re !== x7_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_re golden=%h impl=%h", cyc, g7_toSRAM_1_re, x7_toSRAM_1_re); end
    if (g7_toSRAM_1_we !== x7_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_we golden=%h impl=%h", cyc, g7_toSRAM_1_we, x7_toSRAM_1_we); end
    if (g7_toSRAM_1_ack !== x7_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_ack golden=%h impl=%h", cyc, g7_toSRAM_1_ack, x7_toSRAM_1_ack); end
    if (g7_toSRAM_1_selectedOH !== x7_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_1_selectedOH, x7_toSRAM_1_selectedOH); end
    if (g7_toSRAM_1_array !== x7_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_1_array golden=%h impl=%h", cyc, g7_toSRAM_1_array, x7_toSRAM_1_array); end
    if (g7_toSRAM_2_addr !== x7_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_addr golden=%h impl=%h", cyc, g7_toSRAM_2_addr, x7_toSRAM_2_addr); end
    if (g7_toSRAM_2_addr_rd !== x7_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_2_addr_rd, x7_toSRAM_2_addr_rd); end
    if (g7_toSRAM_2_wdata !== x7_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_wdata golden=%h impl=%h", cyc, g7_toSRAM_2_wdata, x7_toSRAM_2_wdata); end
    if (g7_toSRAM_2_wmask !== x7_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_wmask golden=%h impl=%h", cyc, g7_toSRAM_2_wmask, x7_toSRAM_2_wmask); end
    if (g7_toSRAM_2_re !== x7_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_re golden=%h impl=%h", cyc, g7_toSRAM_2_re, x7_toSRAM_2_re); end
    if (g7_toSRAM_2_we !== x7_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_we golden=%h impl=%h", cyc, g7_toSRAM_2_we, x7_toSRAM_2_we); end
    if (g7_toSRAM_2_ack !== x7_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_ack golden=%h impl=%h", cyc, g7_toSRAM_2_ack, x7_toSRAM_2_ack); end
    if (g7_toSRAM_2_selectedOH !== x7_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_2_selectedOH, x7_toSRAM_2_selectedOH); end
    if (g7_toSRAM_2_array !== x7_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_2_array golden=%h impl=%h", cyc, g7_toSRAM_2_array, x7_toSRAM_2_array); end
    if (g7_toSRAM_3_addr !== x7_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_addr golden=%h impl=%h", cyc, g7_toSRAM_3_addr, x7_toSRAM_3_addr); end
    if (g7_toSRAM_3_addr_rd !== x7_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_3_addr_rd, x7_toSRAM_3_addr_rd); end
    if (g7_toSRAM_3_wdata !== x7_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_wdata golden=%h impl=%h", cyc, g7_toSRAM_3_wdata, x7_toSRAM_3_wdata); end
    if (g7_toSRAM_3_wmask !== x7_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_wmask golden=%h impl=%h", cyc, g7_toSRAM_3_wmask, x7_toSRAM_3_wmask); end
    if (g7_toSRAM_3_re !== x7_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_re golden=%h impl=%h", cyc, g7_toSRAM_3_re, x7_toSRAM_3_re); end
    if (g7_toSRAM_3_we !== x7_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_we golden=%h impl=%h", cyc, g7_toSRAM_3_we, x7_toSRAM_3_we); end
    if (g7_toSRAM_3_ack !== x7_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_ack golden=%h impl=%h", cyc, g7_toSRAM_3_ack, x7_toSRAM_3_ack); end
    if (g7_toSRAM_3_selectedOH !== x7_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_3_selectedOH, x7_toSRAM_3_selectedOH); end
    if (g7_toSRAM_3_array !== x7_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_3_array golden=%h impl=%h", cyc, g7_toSRAM_3_array, x7_toSRAM_3_array); end
    if (g7_toSRAM_4_addr !== x7_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_addr golden=%h impl=%h", cyc, g7_toSRAM_4_addr, x7_toSRAM_4_addr); end
    if (g7_toSRAM_4_addr_rd !== x7_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_4_addr_rd, x7_toSRAM_4_addr_rd); end
    if (g7_toSRAM_4_wdata !== x7_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_wdata golden=%h impl=%h", cyc, g7_toSRAM_4_wdata, x7_toSRAM_4_wdata); end
    if (g7_toSRAM_4_wmask !== x7_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_wmask golden=%h impl=%h", cyc, g7_toSRAM_4_wmask, x7_toSRAM_4_wmask); end
    if (g7_toSRAM_4_re !== x7_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_re golden=%h impl=%h", cyc, g7_toSRAM_4_re, x7_toSRAM_4_re); end
    if (g7_toSRAM_4_we !== x7_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_we golden=%h impl=%h", cyc, g7_toSRAM_4_we, x7_toSRAM_4_we); end
    if (g7_toSRAM_4_ack !== x7_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_ack golden=%h impl=%h", cyc, g7_toSRAM_4_ack, x7_toSRAM_4_ack); end
    if (g7_toSRAM_4_selectedOH !== x7_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_4_selectedOH, x7_toSRAM_4_selectedOH); end
    if (g7_toSRAM_4_array !== x7_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_4_array golden=%h impl=%h", cyc, g7_toSRAM_4_array, x7_toSRAM_4_array); end
    if (g7_toSRAM_5_addr !== x7_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_addr golden=%h impl=%h", cyc, g7_toSRAM_5_addr, x7_toSRAM_5_addr); end
    if (g7_toSRAM_5_addr_rd !== x7_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_5_addr_rd, x7_toSRAM_5_addr_rd); end
    if (g7_toSRAM_5_wdata !== x7_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_wdata golden=%h impl=%h", cyc, g7_toSRAM_5_wdata, x7_toSRAM_5_wdata); end
    if (g7_toSRAM_5_wmask !== x7_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_wmask golden=%h impl=%h", cyc, g7_toSRAM_5_wmask, x7_toSRAM_5_wmask); end
    if (g7_toSRAM_5_re !== x7_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_re golden=%h impl=%h", cyc, g7_toSRAM_5_re, x7_toSRAM_5_re); end
    if (g7_toSRAM_5_we !== x7_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_we golden=%h impl=%h", cyc, g7_toSRAM_5_we, x7_toSRAM_5_we); end
    if (g7_toSRAM_5_ack !== x7_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_ack golden=%h impl=%h", cyc, g7_toSRAM_5_ack, x7_toSRAM_5_ack); end
    if (g7_toSRAM_5_selectedOH !== x7_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_5_selectedOH, x7_toSRAM_5_selectedOH); end
    if (g7_toSRAM_5_array !== x7_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_5_array golden=%h impl=%h", cyc, g7_toSRAM_5_array, x7_toSRAM_5_array); end
    if (g7_toSRAM_6_addr !== x7_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_addr golden=%h impl=%h", cyc, g7_toSRAM_6_addr, x7_toSRAM_6_addr); end
    if (g7_toSRAM_6_addr_rd !== x7_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_6_addr_rd, x7_toSRAM_6_addr_rd); end
    if (g7_toSRAM_6_wdata !== x7_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_wdata golden=%h impl=%h", cyc, g7_toSRAM_6_wdata, x7_toSRAM_6_wdata); end
    if (g7_toSRAM_6_wmask !== x7_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_wmask golden=%h impl=%h", cyc, g7_toSRAM_6_wmask, x7_toSRAM_6_wmask); end
    if (g7_toSRAM_6_re !== x7_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_re golden=%h impl=%h", cyc, g7_toSRAM_6_re, x7_toSRAM_6_re); end
    if (g7_toSRAM_6_we !== x7_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_we golden=%h impl=%h", cyc, g7_toSRAM_6_we, x7_toSRAM_6_we); end
    if (g7_toSRAM_6_ack !== x7_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_ack golden=%h impl=%h", cyc, g7_toSRAM_6_ack, x7_toSRAM_6_ack); end
    if (g7_toSRAM_6_selectedOH !== x7_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_6_selectedOH, x7_toSRAM_6_selectedOH); end
    if (g7_toSRAM_6_array !== x7_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_6_array golden=%h impl=%h", cyc, g7_toSRAM_6_array, x7_toSRAM_6_array); end
    if (g7_toSRAM_7_addr !== x7_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_addr golden=%h impl=%h", cyc, g7_toSRAM_7_addr, x7_toSRAM_7_addr); end
    if (g7_toSRAM_7_addr_rd !== x7_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g7_toSRAM_7_addr_rd, x7_toSRAM_7_addr_rd); end
    if (g7_toSRAM_7_wdata !== x7_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_wdata golden=%h impl=%h", cyc, g7_toSRAM_7_wdata, x7_toSRAM_7_wdata); end
    if (g7_toSRAM_7_wmask !== x7_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_wmask golden=%h impl=%h", cyc, g7_toSRAM_7_wmask, x7_toSRAM_7_wmask); end
    if (g7_toSRAM_7_re !== x7_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_re golden=%h impl=%h", cyc, g7_toSRAM_7_re, x7_toSRAM_7_re); end
    if (g7_toSRAM_7_we !== x7_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_we golden=%h impl=%h", cyc, g7_toSRAM_7_we, x7_toSRAM_7_we); end
    if (g7_toSRAM_7_ack !== x7_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_ack golden=%h impl=%h", cyc, g7_toSRAM_7_ack, x7_toSRAM_7_ack); end
    if (g7_toSRAM_7_selectedOH !== x7_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g7_toSRAM_7_selectedOH, x7_toSRAM_7_selectedOH); end
    if (g7_toSRAM_7_array !== x7_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheDataWay3.toSRAM_7_array golden=%h impl=%h", cyc, g7_toSRAM_7_array, x7_toSRAM_7_array); end
  endtask

  // ======================== [08] MbistPipeIcacheTag ========================
  logic [73:0] v8_rd0;
  logic [73:0] v8_rd1;
  logic [73:0] v8_rd2;
  logic [73:0] v8_rd3;
  logic g8_mbist_ack;
  logic [73:0] g8_mbist_outdata;
  logic [7:0] g8_toSRAM_0_addr;
  logic [7:0] g8_toSRAM_0_addr_rd;
  logic [73:0] g8_toSRAM_0_wdata;
  logic [1:0] g8_toSRAM_0_wmask;
  logic g8_toSRAM_0_re;
  logic g8_toSRAM_0_we;
  logic g8_toSRAM_0_ack;
  logic g8_toSRAM_0_selectedOH;
  logic g8_toSRAM_0_array;
  logic [7:0] g8_toSRAM_1_addr;
  logic [7:0] g8_toSRAM_1_addr_rd;
  logic [73:0] g8_toSRAM_1_wdata;
  logic [1:0] g8_toSRAM_1_wmask;
  logic g8_toSRAM_1_re;
  logic g8_toSRAM_1_we;
  logic g8_toSRAM_1_ack;
  logic g8_toSRAM_1_selectedOH;
  logic g8_toSRAM_1_array;
  logic [7:0] g8_toSRAM_2_addr;
  logic [7:0] g8_toSRAM_2_addr_rd;
  logic [73:0] g8_toSRAM_2_wdata;
  logic [1:0] g8_toSRAM_2_wmask;
  logic g8_toSRAM_2_re;
  logic g8_toSRAM_2_we;
  logic g8_toSRAM_2_ack;
  logic g8_toSRAM_2_selectedOH;
  logic [1:0] g8_toSRAM_2_array;
  logic [7:0] g8_toSRAM_3_addr;
  logic [7:0] g8_toSRAM_3_addr_rd;
  logic [73:0] g8_toSRAM_3_wdata;
  logic [1:0] g8_toSRAM_3_wmask;
  logic g8_toSRAM_3_re;
  logic g8_toSRAM_3_we;
  logic g8_toSRAM_3_ack;
  logic g8_toSRAM_3_selectedOH;
  logic [1:0] g8_toSRAM_3_array;
  logic x8_mbist_ack;
  logic [73:0] x8_mbist_outdata;
  logic [7:0] x8_toSRAM_0_addr;
  logic [7:0] x8_toSRAM_0_addr_rd;
  logic [73:0] x8_toSRAM_0_wdata;
  logic [1:0] x8_toSRAM_0_wmask;
  logic x8_toSRAM_0_re;
  logic x8_toSRAM_0_we;
  logic x8_toSRAM_0_ack;
  logic x8_toSRAM_0_selectedOH;
  logic x8_toSRAM_0_array;
  logic [7:0] x8_toSRAM_1_addr;
  logic [7:0] x8_toSRAM_1_addr_rd;
  logic [73:0] x8_toSRAM_1_wdata;
  logic [1:0] x8_toSRAM_1_wmask;
  logic x8_toSRAM_1_re;
  logic x8_toSRAM_1_we;
  logic x8_toSRAM_1_ack;
  logic x8_toSRAM_1_selectedOH;
  logic x8_toSRAM_1_array;
  logic [7:0] x8_toSRAM_2_addr;
  logic [7:0] x8_toSRAM_2_addr_rd;
  logic [73:0] x8_toSRAM_2_wdata;
  logic [1:0] x8_toSRAM_2_wmask;
  logic x8_toSRAM_2_re;
  logic x8_toSRAM_2_we;
  logic x8_toSRAM_2_ack;
  logic x8_toSRAM_2_selectedOH;
  logic [1:0] x8_toSRAM_2_array;
  logic [7:0] x8_toSRAM_3_addr;
  logic [7:0] x8_toSRAM_3_addr_rd;
  logic [73:0] x8_toSRAM_3_wdata;
  logic [1:0] x8_toSRAM_3_wmask;
  logic x8_toSRAM_3_re;
  logic x8_toSRAM_3_we;
  logic x8_toSRAM_3_ack;
  logic x8_toSRAM_3_selectedOH;
  logic [1:0] x8_toSRAM_3_array;
  bit [3:0] cov_spread8;
  bit [73:0] cov_od0_8, cov_od1_8;
  bit cov_ack0_8, cov_ack1_8;
  MbistPipeIcacheTag u_g8 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[1:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[73:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v8_rd0),
    .toSRAM_1_rdata (v8_rd1),
    .toSRAM_2_rdata (v8_rd2),
    .toSRAM_3_rdata (v8_rd3),
    .mbist_ack (g8_mbist_ack),
    .mbist_outdata (g8_mbist_outdata),
    .toSRAM_0_addr (g8_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g8_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g8_toSRAM_0_wdata),
    .toSRAM_0_wmask (g8_toSRAM_0_wmask),
    .toSRAM_0_re (g8_toSRAM_0_re),
    .toSRAM_0_we (g8_toSRAM_0_we),
    .toSRAM_0_ack (g8_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g8_toSRAM_0_selectedOH),
    .toSRAM_0_array (g8_toSRAM_0_array),
    .toSRAM_1_addr (g8_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g8_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g8_toSRAM_1_wdata),
    .toSRAM_1_wmask (g8_toSRAM_1_wmask),
    .toSRAM_1_re (g8_toSRAM_1_re),
    .toSRAM_1_we (g8_toSRAM_1_we),
    .toSRAM_1_ack (g8_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g8_toSRAM_1_selectedOH),
    .toSRAM_1_array (g8_toSRAM_1_array),
    .toSRAM_2_addr (g8_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g8_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g8_toSRAM_2_wdata),
    .toSRAM_2_wmask (g8_toSRAM_2_wmask),
    .toSRAM_2_re (g8_toSRAM_2_re),
    .toSRAM_2_we (g8_toSRAM_2_we),
    .toSRAM_2_ack (g8_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g8_toSRAM_2_selectedOH),
    .toSRAM_2_array (g8_toSRAM_2_array),
    .toSRAM_3_addr (g8_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g8_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g8_toSRAM_3_wdata),
    .toSRAM_3_wmask (g8_toSRAM_3_wmask),
    .toSRAM_3_re (g8_toSRAM_3_re),
    .toSRAM_3_we (g8_toSRAM_3_we),
    .toSRAM_3_ack (g8_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g8_toSRAM_3_selectedOH),
    .toSRAM_3_array (g8_toSRAM_3_array)
  );
  MbistPipeIcacheTag_xs u_x8 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[1:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[73:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v8_rd0),
    .toSRAM_1_rdata (v8_rd1),
    .toSRAM_2_rdata (v8_rd2),
    .toSRAM_3_rdata (v8_rd3),
    .mbist_ack (x8_mbist_ack),
    .mbist_outdata (x8_mbist_outdata),
    .toSRAM_0_addr (x8_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x8_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x8_toSRAM_0_wdata),
    .toSRAM_0_wmask (x8_toSRAM_0_wmask),
    .toSRAM_0_re (x8_toSRAM_0_re),
    .toSRAM_0_we (x8_toSRAM_0_we),
    .toSRAM_0_ack (x8_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x8_toSRAM_0_selectedOH),
    .toSRAM_0_array (x8_toSRAM_0_array),
    .toSRAM_1_addr (x8_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x8_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x8_toSRAM_1_wdata),
    .toSRAM_1_wmask (x8_toSRAM_1_wmask),
    .toSRAM_1_re (x8_toSRAM_1_re),
    .toSRAM_1_we (x8_toSRAM_1_we),
    .toSRAM_1_ack (x8_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x8_toSRAM_1_selectedOH),
    .toSRAM_1_array (x8_toSRAM_1_array),
    .toSRAM_2_addr (x8_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x8_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x8_toSRAM_2_wdata),
    .toSRAM_2_wmask (x8_toSRAM_2_wmask),
    .toSRAM_2_re (x8_toSRAM_2_re),
    .toSRAM_2_we (x8_toSRAM_2_we),
    .toSRAM_2_ack (x8_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x8_toSRAM_2_selectedOH),
    .toSRAM_2_array (x8_toSRAM_2_array),
    .toSRAM_3_addr (x8_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x8_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x8_toSRAM_3_wdata),
    .toSRAM_3_wmask (x8_toSRAM_3_wmask),
    .toSRAM_3_re (x8_toSRAM_3_re),
    .toSRAM_3_we (x8_toSRAM_3_we),
    .toSRAM_3_ack (x8_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x8_toSRAM_3_selectedOH),
    .toSRAM_3_array (x8_toSRAM_3_array)
  );
  wire [464:0] gbus8 = {g8_mbist_ack, g8_mbist_outdata, g8_toSRAM_0_addr, g8_toSRAM_0_addr_rd, g8_toSRAM_0_wdata, g8_toSRAM_0_wmask, g8_toSRAM_0_re, g8_toSRAM_0_we, g8_toSRAM_0_ack, g8_toSRAM_0_selectedOH, g8_toSRAM_0_array, g8_toSRAM_1_addr, g8_toSRAM_1_addr_rd, g8_toSRAM_1_wdata, g8_toSRAM_1_wmask, g8_toSRAM_1_re, g8_toSRAM_1_we, g8_toSRAM_1_ack, g8_toSRAM_1_selectedOH, g8_toSRAM_1_array, g8_toSRAM_2_addr, g8_toSRAM_2_addr_rd, g8_toSRAM_2_wdata, g8_toSRAM_2_wmask, g8_toSRAM_2_re, g8_toSRAM_2_we, g8_toSRAM_2_ack, g8_toSRAM_2_selectedOH, g8_toSRAM_2_array, g8_toSRAM_3_addr, g8_toSRAM_3_addr_rd, g8_toSRAM_3_wdata, g8_toSRAM_3_wmask, g8_toSRAM_3_re, g8_toSRAM_3_we, g8_toSRAM_3_ack, g8_toSRAM_3_selectedOH, g8_toSRAM_3_array};
  wire [464:0] xbus8 = {x8_mbist_ack, x8_mbist_outdata, x8_toSRAM_0_addr, x8_toSRAM_0_addr_rd, x8_toSRAM_0_wdata, x8_toSRAM_0_wmask, x8_toSRAM_0_re, x8_toSRAM_0_we, x8_toSRAM_0_ack, x8_toSRAM_0_selectedOH, x8_toSRAM_0_array, x8_toSRAM_1_addr, x8_toSRAM_1_addr_rd, x8_toSRAM_1_wdata, x8_toSRAM_1_wmask, x8_toSRAM_1_re, x8_toSRAM_1_we, x8_toSRAM_1_ack, x8_toSRAM_1_selectedOH, x8_toSRAM_1_array, x8_toSRAM_2_addr, x8_toSRAM_2_addr_rd, x8_toSRAM_2_wdata, x8_toSRAM_2_wmask, x8_toSRAM_2_re, x8_toSRAM_2_we, x8_toSRAM_2_ack, x8_toSRAM_2_selectedOH, x8_toSRAM_2_array, x8_toSRAM_3_addr, x8_toSRAM_3_addr_rd, x8_toSRAM_3_wdata, x8_toSRAM_3_wmask, x8_toSRAM_3_re, x8_toSRAM_3_we, x8_toSRAM_3_ack, x8_toSRAM_3_selectedOH, x8_toSRAM_3_array};
  task automatic detail8();
    if (g8_mbist_ack !== x8_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.mbist_ack golden=%h impl=%h", cyc, g8_mbist_ack, x8_mbist_ack); end
    if (g8_mbist_outdata !== x8_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.mbist_outdata golden=%h impl=%h", cyc, g8_mbist_outdata, x8_mbist_outdata); end
    if (g8_toSRAM_0_addr !== x8_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_addr golden=%h impl=%h", cyc, g8_toSRAM_0_addr, x8_toSRAM_0_addr); end
    if (g8_toSRAM_0_addr_rd !== x8_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g8_toSRAM_0_addr_rd, x8_toSRAM_0_addr_rd); end
    if (g8_toSRAM_0_wdata !== x8_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_wdata golden=%h impl=%h", cyc, g8_toSRAM_0_wdata, x8_toSRAM_0_wdata); end
    if (g8_toSRAM_0_wmask !== x8_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_wmask golden=%h impl=%h", cyc, g8_toSRAM_0_wmask, x8_toSRAM_0_wmask); end
    if (g8_toSRAM_0_re !== x8_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_re golden=%h impl=%h", cyc, g8_toSRAM_0_re, x8_toSRAM_0_re); end
    if (g8_toSRAM_0_we !== x8_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_we golden=%h impl=%h", cyc, g8_toSRAM_0_we, x8_toSRAM_0_we); end
    if (g8_toSRAM_0_ack !== x8_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_ack golden=%h impl=%h", cyc, g8_toSRAM_0_ack, x8_toSRAM_0_ack); end
    if (g8_toSRAM_0_selectedOH !== x8_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g8_toSRAM_0_selectedOH, x8_toSRAM_0_selectedOH); end
    if (g8_toSRAM_0_array !== x8_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_0_array golden=%h impl=%h", cyc, g8_toSRAM_0_array, x8_toSRAM_0_array); end
    if (g8_toSRAM_1_addr !== x8_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_addr golden=%h impl=%h", cyc, g8_toSRAM_1_addr, x8_toSRAM_1_addr); end
    if (g8_toSRAM_1_addr_rd !== x8_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g8_toSRAM_1_addr_rd, x8_toSRAM_1_addr_rd); end
    if (g8_toSRAM_1_wdata !== x8_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_wdata golden=%h impl=%h", cyc, g8_toSRAM_1_wdata, x8_toSRAM_1_wdata); end
    if (g8_toSRAM_1_wmask !== x8_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_wmask golden=%h impl=%h", cyc, g8_toSRAM_1_wmask, x8_toSRAM_1_wmask); end
    if (g8_toSRAM_1_re !== x8_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_re golden=%h impl=%h", cyc, g8_toSRAM_1_re, x8_toSRAM_1_re); end
    if (g8_toSRAM_1_we !== x8_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_we golden=%h impl=%h", cyc, g8_toSRAM_1_we, x8_toSRAM_1_we); end
    if (g8_toSRAM_1_ack !== x8_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_ack golden=%h impl=%h", cyc, g8_toSRAM_1_ack, x8_toSRAM_1_ack); end
    if (g8_toSRAM_1_selectedOH !== x8_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g8_toSRAM_1_selectedOH, x8_toSRAM_1_selectedOH); end
    if (g8_toSRAM_1_array !== x8_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_1_array golden=%h impl=%h", cyc, g8_toSRAM_1_array, x8_toSRAM_1_array); end
    if (g8_toSRAM_2_addr !== x8_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_addr golden=%h impl=%h", cyc, g8_toSRAM_2_addr, x8_toSRAM_2_addr); end
    if (g8_toSRAM_2_addr_rd !== x8_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g8_toSRAM_2_addr_rd, x8_toSRAM_2_addr_rd); end
    if (g8_toSRAM_2_wdata !== x8_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_wdata golden=%h impl=%h", cyc, g8_toSRAM_2_wdata, x8_toSRAM_2_wdata); end
    if (g8_toSRAM_2_wmask !== x8_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_wmask golden=%h impl=%h", cyc, g8_toSRAM_2_wmask, x8_toSRAM_2_wmask); end
    if (g8_toSRAM_2_re !== x8_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_re golden=%h impl=%h", cyc, g8_toSRAM_2_re, x8_toSRAM_2_re); end
    if (g8_toSRAM_2_we !== x8_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_we golden=%h impl=%h", cyc, g8_toSRAM_2_we, x8_toSRAM_2_we); end
    if (g8_toSRAM_2_ack !== x8_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_ack golden=%h impl=%h", cyc, g8_toSRAM_2_ack, x8_toSRAM_2_ack); end
    if (g8_toSRAM_2_selectedOH !== x8_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g8_toSRAM_2_selectedOH, x8_toSRAM_2_selectedOH); end
    if (g8_toSRAM_2_array !== x8_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_2_array golden=%h impl=%h", cyc, g8_toSRAM_2_array, x8_toSRAM_2_array); end
    if (g8_toSRAM_3_addr !== x8_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_addr golden=%h impl=%h", cyc, g8_toSRAM_3_addr, x8_toSRAM_3_addr); end
    if (g8_toSRAM_3_addr_rd !== x8_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g8_toSRAM_3_addr_rd, x8_toSRAM_3_addr_rd); end
    if (g8_toSRAM_3_wdata !== x8_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_wdata golden=%h impl=%h", cyc, g8_toSRAM_3_wdata, x8_toSRAM_3_wdata); end
    if (g8_toSRAM_3_wmask !== x8_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_wmask golden=%h impl=%h", cyc, g8_toSRAM_3_wmask, x8_toSRAM_3_wmask); end
    if (g8_toSRAM_3_re !== x8_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_re golden=%h impl=%h", cyc, g8_toSRAM_3_re, x8_toSRAM_3_re); end
    if (g8_toSRAM_3_we !== x8_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_we golden=%h impl=%h", cyc, g8_toSRAM_3_we, x8_toSRAM_3_we); end
    if (g8_toSRAM_3_ack !== x8_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_ack golden=%h impl=%h", cyc, g8_toSRAM_3_ack, x8_toSRAM_3_ack); end
    if (g8_toSRAM_3_selectedOH !== x8_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g8_toSRAM_3_selectedOH, x8_toSRAM_3_selectedOH); end
    if (g8_toSRAM_3_array !== x8_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIcacheTag.toSRAM_3_array golden=%h impl=%h", cyc, g8_toSRAM_3_array, x8_toSRAM_3_array); end
  endtask

  // ======================== [09] MbistPipeIttage ========================
  logic [75:0] v9_rd0;
  logic g9_mbist_ack;
  logic [75:0] g9_mbist_outdata;
  logic [7:0] g9_toSRAM_0_addr;
  logic [7:0] g9_toSRAM_0_addr_rd;
  logic [75:0] g9_toSRAM_0_wdata;
  logic [75:0] g9_toSRAM_0_wmask;
  logic g9_toSRAM_0_re;
  logic g9_toSRAM_0_we;
  logic g9_toSRAM_0_ack;
  logic g9_toSRAM_0_selectedOH;
  logic [6:0] g9_toSRAM_0_array;
  logic x9_mbist_ack;
  logic [75:0] x9_mbist_outdata;
  logic [7:0] x9_toSRAM_0_addr;
  logic [7:0] x9_toSRAM_0_addr_rd;
  logic [75:0] x9_toSRAM_0_wdata;
  logic [75:0] x9_toSRAM_0_wmask;
  logic x9_toSRAM_0_re;
  logic x9_toSRAM_0_we;
  logic x9_toSRAM_0_ack;
  logic x9_toSRAM_0_selectedOH;
  logic [6:0] x9_toSRAM_0_array;
  bit [0:0] cov_spread9;
  bit [75:0] cov_od0_9, cov_od1_9;
  bit cov_ack0_9, cov_ack1_9;
  MbistPipeIttage u_g9 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v9_rd0),
    .mbist_ack (g9_mbist_ack),
    .mbist_outdata (g9_mbist_outdata),
    .toSRAM_0_addr (g9_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g9_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g9_toSRAM_0_wdata),
    .toSRAM_0_wmask (g9_toSRAM_0_wmask),
    .toSRAM_0_re (g9_toSRAM_0_re),
    .toSRAM_0_we (g9_toSRAM_0_we),
    .toSRAM_0_ack (g9_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g9_toSRAM_0_selectedOH),
    .toSRAM_0_array (g9_toSRAM_0_array)
  );
  MbistPipeIttage_xs u_x9 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v9_rd0),
    .mbist_ack (x9_mbist_ack),
    .mbist_outdata (x9_mbist_outdata),
    .toSRAM_0_addr (x9_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x9_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x9_toSRAM_0_wdata),
    .toSRAM_0_wmask (x9_toSRAM_0_wmask),
    .toSRAM_0_re (x9_toSRAM_0_re),
    .toSRAM_0_we (x9_toSRAM_0_we),
    .toSRAM_0_ack (x9_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x9_toSRAM_0_selectedOH),
    .toSRAM_0_array (x9_toSRAM_0_array)
  );
  wire [255:0] gbus9 = {g9_mbist_ack, g9_mbist_outdata, g9_toSRAM_0_addr, g9_toSRAM_0_addr_rd, g9_toSRAM_0_wdata, g9_toSRAM_0_wmask, g9_toSRAM_0_re, g9_toSRAM_0_we, g9_toSRAM_0_ack, g9_toSRAM_0_selectedOH, g9_toSRAM_0_array};
  wire [255:0] xbus9 = {x9_mbist_ack, x9_mbist_outdata, x9_toSRAM_0_addr, x9_toSRAM_0_addr_rd, x9_toSRAM_0_wdata, x9_toSRAM_0_wmask, x9_toSRAM_0_re, x9_toSRAM_0_we, x9_toSRAM_0_ack, x9_toSRAM_0_selectedOH, x9_toSRAM_0_array};
  task automatic detail9();
    if (g9_mbist_ack !== x9_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.mbist_ack golden=%h impl=%h", cyc, g9_mbist_ack, x9_mbist_ack); end
    if (g9_mbist_outdata !== x9_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.mbist_outdata golden=%h impl=%h", cyc, g9_mbist_outdata, x9_mbist_outdata); end
    if (g9_toSRAM_0_addr !== x9_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_addr golden=%h impl=%h", cyc, g9_toSRAM_0_addr, x9_toSRAM_0_addr); end
    if (g9_toSRAM_0_addr_rd !== x9_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g9_toSRAM_0_addr_rd, x9_toSRAM_0_addr_rd); end
    if (g9_toSRAM_0_wdata !== x9_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_wdata golden=%h impl=%h", cyc, g9_toSRAM_0_wdata, x9_toSRAM_0_wdata); end
    if (g9_toSRAM_0_wmask !== x9_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_wmask golden=%h impl=%h", cyc, g9_toSRAM_0_wmask, x9_toSRAM_0_wmask); end
    if (g9_toSRAM_0_re !== x9_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_re golden=%h impl=%h", cyc, g9_toSRAM_0_re, x9_toSRAM_0_re); end
    if (g9_toSRAM_0_we !== x9_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_we golden=%h impl=%h", cyc, g9_toSRAM_0_we, x9_toSRAM_0_we); end
    if (g9_toSRAM_0_ack !== x9_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_ack golden=%h impl=%h", cyc, g9_toSRAM_0_ack, x9_toSRAM_0_ack); end
    if (g9_toSRAM_0_selectedOH !== x9_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g9_toSRAM_0_selectedOH, x9_toSRAM_0_selectedOH); end
    if (g9_toSRAM_0_array !== x9_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage.toSRAM_0_array golden=%h impl=%h", cyc, g9_toSRAM_0_array, x9_toSRAM_0_array); end
  endtask

  // ======================== [10] MbistPipeIttage_1 ========================
  logic [75:0] v10_rd0;
  logic g10_mbist_ack;
  logic [75:0] g10_mbist_outdata;
  logic [7:0] g10_toSRAM_0_addr;
  logic [7:0] g10_toSRAM_0_addr_rd;
  logic [75:0] g10_toSRAM_0_wdata;
  logic [75:0] g10_toSRAM_0_wmask;
  logic g10_toSRAM_0_re;
  logic g10_toSRAM_0_we;
  logic g10_toSRAM_0_ack;
  logic g10_toSRAM_0_selectedOH;
  logic [6:0] g10_toSRAM_0_array;
  logic x10_mbist_ack;
  logic [75:0] x10_mbist_outdata;
  logic [7:0] x10_toSRAM_0_addr;
  logic [7:0] x10_toSRAM_0_addr_rd;
  logic [75:0] x10_toSRAM_0_wdata;
  logic [75:0] x10_toSRAM_0_wmask;
  logic x10_toSRAM_0_re;
  logic x10_toSRAM_0_we;
  logic x10_toSRAM_0_ack;
  logic x10_toSRAM_0_selectedOH;
  logic [6:0] x10_toSRAM_0_array;
  bit [0:0] cov_spread10;
  bit [75:0] cov_od0_10, cov_od1_10;
  bit cov_ack0_10, cov_ack1_10;
  MbistPipeIttage_1 u_g10 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v10_rd0),
    .mbist_ack (g10_mbist_ack),
    .mbist_outdata (g10_mbist_outdata),
    .toSRAM_0_addr (g10_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g10_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g10_toSRAM_0_wdata),
    .toSRAM_0_wmask (g10_toSRAM_0_wmask),
    .toSRAM_0_re (g10_toSRAM_0_re),
    .toSRAM_0_we (g10_toSRAM_0_we),
    .toSRAM_0_ack (g10_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g10_toSRAM_0_selectedOH),
    .toSRAM_0_array (g10_toSRAM_0_array)
  );
  MbistPipeIttage_1_xs u_x10 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v10_rd0),
    .mbist_ack (x10_mbist_ack),
    .mbist_outdata (x10_mbist_outdata),
    .toSRAM_0_addr (x10_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x10_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x10_toSRAM_0_wdata),
    .toSRAM_0_wmask (x10_toSRAM_0_wmask),
    .toSRAM_0_re (x10_toSRAM_0_re),
    .toSRAM_0_we (x10_toSRAM_0_we),
    .toSRAM_0_ack (x10_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x10_toSRAM_0_selectedOH),
    .toSRAM_0_array (x10_toSRAM_0_array)
  );
  wire [255:0] gbus10 = {g10_mbist_ack, g10_mbist_outdata, g10_toSRAM_0_addr, g10_toSRAM_0_addr_rd, g10_toSRAM_0_wdata, g10_toSRAM_0_wmask, g10_toSRAM_0_re, g10_toSRAM_0_we, g10_toSRAM_0_ack, g10_toSRAM_0_selectedOH, g10_toSRAM_0_array};
  wire [255:0] xbus10 = {x10_mbist_ack, x10_mbist_outdata, x10_toSRAM_0_addr, x10_toSRAM_0_addr_rd, x10_toSRAM_0_wdata, x10_toSRAM_0_wmask, x10_toSRAM_0_re, x10_toSRAM_0_we, x10_toSRAM_0_ack, x10_toSRAM_0_selectedOH, x10_toSRAM_0_array};
  task automatic detail10();
    if (g10_mbist_ack !== x10_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.mbist_ack golden=%h impl=%h", cyc, g10_mbist_ack, x10_mbist_ack); end
    if (g10_mbist_outdata !== x10_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.mbist_outdata golden=%h impl=%h", cyc, g10_mbist_outdata, x10_mbist_outdata); end
    if (g10_toSRAM_0_addr !== x10_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_addr golden=%h impl=%h", cyc, g10_toSRAM_0_addr, x10_toSRAM_0_addr); end
    if (g10_toSRAM_0_addr_rd !== x10_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g10_toSRAM_0_addr_rd, x10_toSRAM_0_addr_rd); end
    if (g10_toSRAM_0_wdata !== x10_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_wdata golden=%h impl=%h", cyc, g10_toSRAM_0_wdata, x10_toSRAM_0_wdata); end
    if (g10_toSRAM_0_wmask !== x10_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_wmask golden=%h impl=%h", cyc, g10_toSRAM_0_wmask, x10_toSRAM_0_wmask); end
    if (g10_toSRAM_0_re !== x10_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_re golden=%h impl=%h", cyc, g10_toSRAM_0_re, x10_toSRAM_0_re); end
    if (g10_toSRAM_0_we !== x10_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_we golden=%h impl=%h", cyc, g10_toSRAM_0_we, x10_toSRAM_0_we); end
    if (g10_toSRAM_0_ack !== x10_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_ack golden=%h impl=%h", cyc, g10_toSRAM_0_ack, x10_toSRAM_0_ack); end
    if (g10_toSRAM_0_selectedOH !== x10_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g10_toSRAM_0_selectedOH, x10_toSRAM_0_selectedOH); end
    if (g10_toSRAM_0_array !== x10_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_1.toSRAM_0_array golden=%h impl=%h", cyc, g10_toSRAM_0_array, x10_toSRAM_0_array); end
  endtask

  // ======================== [11] MbistPipeIttage_2 ========================
  logic [75:0] v11_rd0;
  logic [75:0] v11_rd1;
  logic g11_mbist_ack;
  logic [75:0] g11_mbist_outdata;
  logic [7:0] g11_toSRAM_0_addr;
  logic [7:0] g11_toSRAM_0_addr_rd;
  logic [75:0] g11_toSRAM_0_wdata;
  logic [75:0] g11_toSRAM_0_wmask;
  logic g11_toSRAM_0_re;
  logic g11_toSRAM_0_we;
  logic g11_toSRAM_0_ack;
  logic g11_toSRAM_0_selectedOH;
  logic [6:0] g11_toSRAM_0_array;
  logic [7:0] g11_toSRAM_1_addr;
  logic [7:0] g11_toSRAM_1_addr_rd;
  logic [75:0] g11_toSRAM_1_wdata;
  logic [75:0] g11_toSRAM_1_wmask;
  logic g11_toSRAM_1_re;
  logic g11_toSRAM_1_we;
  logic g11_toSRAM_1_ack;
  logic g11_toSRAM_1_selectedOH;
  logic [6:0] g11_toSRAM_1_array;
  logic x11_mbist_ack;
  logic [75:0] x11_mbist_outdata;
  logic [7:0] x11_toSRAM_0_addr;
  logic [7:0] x11_toSRAM_0_addr_rd;
  logic [75:0] x11_toSRAM_0_wdata;
  logic [75:0] x11_toSRAM_0_wmask;
  logic x11_toSRAM_0_re;
  logic x11_toSRAM_0_we;
  logic x11_toSRAM_0_ack;
  logic x11_toSRAM_0_selectedOH;
  logic [6:0] x11_toSRAM_0_array;
  logic [7:0] x11_toSRAM_1_addr;
  logic [7:0] x11_toSRAM_1_addr_rd;
  logic [75:0] x11_toSRAM_1_wdata;
  logic [75:0] x11_toSRAM_1_wmask;
  logic x11_toSRAM_1_re;
  logic x11_toSRAM_1_we;
  logic x11_toSRAM_1_ack;
  logic x11_toSRAM_1_selectedOH;
  logic [6:0] x11_toSRAM_1_array;
  bit [1:0] cov_spread11;
  bit [75:0] cov_od0_11, cov_od1_11;
  bit cov_ack0_11, cov_ack1_11;
  MbistPipeIttage_2 u_g11 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v11_rd0),
    .toSRAM_1_rdata (v11_rd1),
    .mbist_ack (g11_mbist_ack),
    .mbist_outdata (g11_mbist_outdata),
    .toSRAM_0_addr (g11_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g11_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g11_toSRAM_0_wdata),
    .toSRAM_0_wmask (g11_toSRAM_0_wmask),
    .toSRAM_0_re (g11_toSRAM_0_re),
    .toSRAM_0_we (g11_toSRAM_0_we),
    .toSRAM_0_ack (g11_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g11_toSRAM_0_selectedOH),
    .toSRAM_0_array (g11_toSRAM_0_array),
    .toSRAM_1_addr (g11_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g11_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g11_toSRAM_1_wdata),
    .toSRAM_1_wmask (g11_toSRAM_1_wmask),
    .toSRAM_1_re (g11_toSRAM_1_re),
    .toSRAM_1_we (g11_toSRAM_1_we),
    .toSRAM_1_ack (g11_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g11_toSRAM_1_selectedOH),
    .toSRAM_1_array (g11_toSRAM_1_array)
  );
  MbistPipeIttage_2_xs u_x11 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v11_rd0),
    .toSRAM_1_rdata (v11_rd1),
    .mbist_ack (x11_mbist_ack),
    .mbist_outdata (x11_mbist_outdata),
    .toSRAM_0_addr (x11_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x11_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x11_toSRAM_0_wdata),
    .toSRAM_0_wmask (x11_toSRAM_0_wmask),
    .toSRAM_0_re (x11_toSRAM_0_re),
    .toSRAM_0_we (x11_toSRAM_0_we),
    .toSRAM_0_ack (x11_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x11_toSRAM_0_selectedOH),
    .toSRAM_0_array (x11_toSRAM_0_array),
    .toSRAM_1_addr (x11_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x11_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x11_toSRAM_1_wdata),
    .toSRAM_1_wmask (x11_toSRAM_1_wmask),
    .toSRAM_1_re (x11_toSRAM_1_re),
    .toSRAM_1_we (x11_toSRAM_1_we),
    .toSRAM_1_ack (x11_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x11_toSRAM_1_selectedOH),
    .toSRAM_1_array (x11_toSRAM_1_array)
  );
  wire [434:0] gbus11 = {g11_mbist_ack, g11_mbist_outdata, g11_toSRAM_0_addr, g11_toSRAM_0_addr_rd, g11_toSRAM_0_wdata, g11_toSRAM_0_wmask, g11_toSRAM_0_re, g11_toSRAM_0_we, g11_toSRAM_0_ack, g11_toSRAM_0_selectedOH, g11_toSRAM_0_array, g11_toSRAM_1_addr, g11_toSRAM_1_addr_rd, g11_toSRAM_1_wdata, g11_toSRAM_1_wmask, g11_toSRAM_1_re, g11_toSRAM_1_we, g11_toSRAM_1_ack, g11_toSRAM_1_selectedOH, g11_toSRAM_1_array};
  wire [434:0] xbus11 = {x11_mbist_ack, x11_mbist_outdata, x11_toSRAM_0_addr, x11_toSRAM_0_addr_rd, x11_toSRAM_0_wdata, x11_toSRAM_0_wmask, x11_toSRAM_0_re, x11_toSRAM_0_we, x11_toSRAM_0_ack, x11_toSRAM_0_selectedOH, x11_toSRAM_0_array, x11_toSRAM_1_addr, x11_toSRAM_1_addr_rd, x11_toSRAM_1_wdata, x11_toSRAM_1_wmask, x11_toSRAM_1_re, x11_toSRAM_1_we, x11_toSRAM_1_ack, x11_toSRAM_1_selectedOH, x11_toSRAM_1_array};
  task automatic detail11();
    if (g11_mbist_ack !== x11_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.mbist_ack golden=%h impl=%h", cyc, g11_mbist_ack, x11_mbist_ack); end
    if (g11_mbist_outdata !== x11_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.mbist_outdata golden=%h impl=%h", cyc, g11_mbist_outdata, x11_mbist_outdata); end
    if (g11_toSRAM_0_addr !== x11_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_addr golden=%h impl=%h", cyc, g11_toSRAM_0_addr, x11_toSRAM_0_addr); end
    if (g11_toSRAM_0_addr_rd !== x11_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g11_toSRAM_0_addr_rd, x11_toSRAM_0_addr_rd); end
    if (g11_toSRAM_0_wdata !== x11_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_wdata golden=%h impl=%h", cyc, g11_toSRAM_0_wdata, x11_toSRAM_0_wdata); end
    if (g11_toSRAM_0_wmask !== x11_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_wmask golden=%h impl=%h", cyc, g11_toSRAM_0_wmask, x11_toSRAM_0_wmask); end
    if (g11_toSRAM_0_re !== x11_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_re golden=%h impl=%h", cyc, g11_toSRAM_0_re, x11_toSRAM_0_re); end
    if (g11_toSRAM_0_we !== x11_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_we golden=%h impl=%h", cyc, g11_toSRAM_0_we, x11_toSRAM_0_we); end
    if (g11_toSRAM_0_ack !== x11_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_ack golden=%h impl=%h", cyc, g11_toSRAM_0_ack, x11_toSRAM_0_ack); end
    if (g11_toSRAM_0_selectedOH !== x11_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g11_toSRAM_0_selectedOH, x11_toSRAM_0_selectedOH); end
    if (g11_toSRAM_0_array !== x11_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_0_array golden=%h impl=%h", cyc, g11_toSRAM_0_array, x11_toSRAM_0_array); end
    if (g11_toSRAM_1_addr !== x11_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_addr golden=%h impl=%h", cyc, g11_toSRAM_1_addr, x11_toSRAM_1_addr); end
    if (g11_toSRAM_1_addr_rd !== x11_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g11_toSRAM_1_addr_rd, x11_toSRAM_1_addr_rd); end
    if (g11_toSRAM_1_wdata !== x11_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_wdata golden=%h impl=%h", cyc, g11_toSRAM_1_wdata, x11_toSRAM_1_wdata); end
    if (g11_toSRAM_1_wmask !== x11_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_wmask golden=%h impl=%h", cyc, g11_toSRAM_1_wmask, x11_toSRAM_1_wmask); end
    if (g11_toSRAM_1_re !== x11_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_re golden=%h impl=%h", cyc, g11_toSRAM_1_re, x11_toSRAM_1_re); end
    if (g11_toSRAM_1_we !== x11_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_we golden=%h impl=%h", cyc, g11_toSRAM_1_we, x11_toSRAM_1_we); end
    if (g11_toSRAM_1_ack !== x11_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_ack golden=%h impl=%h", cyc, g11_toSRAM_1_ack, x11_toSRAM_1_ack); end
    if (g11_toSRAM_1_selectedOH !== x11_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g11_toSRAM_1_selectedOH, x11_toSRAM_1_selectedOH); end
    if (g11_toSRAM_1_array !== x11_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_2.toSRAM_1_array golden=%h impl=%h", cyc, g11_toSRAM_1_array, x11_toSRAM_1_array); end
  endtask

  // ======================== [12] MbistPipeIttage_3 ========================
  logic [75:0] v12_rd0;
  logic [75:0] v12_rd1;
  logic g12_mbist_ack;
  logic [75:0] g12_mbist_outdata;
  logic [7:0] g12_toSRAM_0_addr;
  logic [7:0] g12_toSRAM_0_addr_rd;
  logic [75:0] g12_toSRAM_0_wdata;
  logic [75:0] g12_toSRAM_0_wmask;
  logic g12_toSRAM_0_re;
  logic g12_toSRAM_0_we;
  logic g12_toSRAM_0_ack;
  logic g12_toSRAM_0_selectedOH;
  logic [6:0] g12_toSRAM_0_array;
  logic [7:0] g12_toSRAM_1_addr;
  logic [7:0] g12_toSRAM_1_addr_rd;
  logic [75:0] g12_toSRAM_1_wdata;
  logic [75:0] g12_toSRAM_1_wmask;
  logic g12_toSRAM_1_re;
  logic g12_toSRAM_1_we;
  logic g12_toSRAM_1_ack;
  logic g12_toSRAM_1_selectedOH;
  logic [6:0] g12_toSRAM_1_array;
  logic x12_mbist_ack;
  logic [75:0] x12_mbist_outdata;
  logic [7:0] x12_toSRAM_0_addr;
  logic [7:0] x12_toSRAM_0_addr_rd;
  logic [75:0] x12_toSRAM_0_wdata;
  logic [75:0] x12_toSRAM_0_wmask;
  logic x12_toSRAM_0_re;
  logic x12_toSRAM_0_we;
  logic x12_toSRAM_0_ack;
  logic x12_toSRAM_0_selectedOH;
  logic [6:0] x12_toSRAM_0_array;
  logic [7:0] x12_toSRAM_1_addr;
  logic [7:0] x12_toSRAM_1_addr_rd;
  logic [75:0] x12_toSRAM_1_wdata;
  logic [75:0] x12_toSRAM_1_wmask;
  logic x12_toSRAM_1_re;
  logic x12_toSRAM_1_we;
  logic x12_toSRAM_1_ack;
  logic x12_toSRAM_1_selectedOH;
  logic [6:0] x12_toSRAM_1_array;
  bit [1:0] cov_spread12;
  bit [75:0] cov_od0_12, cov_od1_12;
  bit cov_ack0_12, cov_ack1_12;
  MbistPipeIttage_3 u_g12 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v12_rd0),
    .toSRAM_1_rdata (v12_rd1),
    .mbist_ack (g12_mbist_ack),
    .mbist_outdata (g12_mbist_outdata),
    .toSRAM_0_addr (g12_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g12_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g12_toSRAM_0_wdata),
    .toSRAM_0_wmask (g12_toSRAM_0_wmask),
    .toSRAM_0_re (g12_toSRAM_0_re),
    .toSRAM_0_we (g12_toSRAM_0_we),
    .toSRAM_0_ack (g12_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g12_toSRAM_0_selectedOH),
    .toSRAM_0_array (g12_toSRAM_0_array),
    .toSRAM_1_addr (g12_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g12_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g12_toSRAM_1_wdata),
    .toSRAM_1_wmask (g12_toSRAM_1_wmask),
    .toSRAM_1_re (g12_toSRAM_1_re),
    .toSRAM_1_we (g12_toSRAM_1_we),
    .toSRAM_1_ack (g12_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g12_toSRAM_1_selectedOH),
    .toSRAM_1_array (g12_toSRAM_1_array)
  );
  MbistPipeIttage_3_xs u_x12 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v12_rd0),
    .toSRAM_1_rdata (v12_rd1),
    .mbist_ack (x12_mbist_ack),
    .mbist_outdata (x12_mbist_outdata),
    .toSRAM_0_addr (x12_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x12_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x12_toSRAM_0_wdata),
    .toSRAM_0_wmask (x12_toSRAM_0_wmask),
    .toSRAM_0_re (x12_toSRAM_0_re),
    .toSRAM_0_we (x12_toSRAM_0_we),
    .toSRAM_0_ack (x12_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x12_toSRAM_0_selectedOH),
    .toSRAM_0_array (x12_toSRAM_0_array),
    .toSRAM_1_addr (x12_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x12_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x12_toSRAM_1_wdata),
    .toSRAM_1_wmask (x12_toSRAM_1_wmask),
    .toSRAM_1_re (x12_toSRAM_1_re),
    .toSRAM_1_we (x12_toSRAM_1_we),
    .toSRAM_1_ack (x12_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x12_toSRAM_1_selectedOH),
    .toSRAM_1_array (x12_toSRAM_1_array)
  );
  wire [434:0] gbus12 = {g12_mbist_ack, g12_mbist_outdata, g12_toSRAM_0_addr, g12_toSRAM_0_addr_rd, g12_toSRAM_0_wdata, g12_toSRAM_0_wmask, g12_toSRAM_0_re, g12_toSRAM_0_we, g12_toSRAM_0_ack, g12_toSRAM_0_selectedOH, g12_toSRAM_0_array, g12_toSRAM_1_addr, g12_toSRAM_1_addr_rd, g12_toSRAM_1_wdata, g12_toSRAM_1_wmask, g12_toSRAM_1_re, g12_toSRAM_1_we, g12_toSRAM_1_ack, g12_toSRAM_1_selectedOH, g12_toSRAM_1_array};
  wire [434:0] xbus12 = {x12_mbist_ack, x12_mbist_outdata, x12_toSRAM_0_addr, x12_toSRAM_0_addr_rd, x12_toSRAM_0_wdata, x12_toSRAM_0_wmask, x12_toSRAM_0_re, x12_toSRAM_0_we, x12_toSRAM_0_ack, x12_toSRAM_0_selectedOH, x12_toSRAM_0_array, x12_toSRAM_1_addr, x12_toSRAM_1_addr_rd, x12_toSRAM_1_wdata, x12_toSRAM_1_wmask, x12_toSRAM_1_re, x12_toSRAM_1_we, x12_toSRAM_1_ack, x12_toSRAM_1_selectedOH, x12_toSRAM_1_array};
  task automatic detail12();
    if (g12_mbist_ack !== x12_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.mbist_ack golden=%h impl=%h", cyc, g12_mbist_ack, x12_mbist_ack); end
    if (g12_mbist_outdata !== x12_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.mbist_outdata golden=%h impl=%h", cyc, g12_mbist_outdata, x12_mbist_outdata); end
    if (g12_toSRAM_0_addr !== x12_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_addr golden=%h impl=%h", cyc, g12_toSRAM_0_addr, x12_toSRAM_0_addr); end
    if (g12_toSRAM_0_addr_rd !== x12_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g12_toSRAM_0_addr_rd, x12_toSRAM_0_addr_rd); end
    if (g12_toSRAM_0_wdata !== x12_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_wdata golden=%h impl=%h", cyc, g12_toSRAM_0_wdata, x12_toSRAM_0_wdata); end
    if (g12_toSRAM_0_wmask !== x12_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_wmask golden=%h impl=%h", cyc, g12_toSRAM_0_wmask, x12_toSRAM_0_wmask); end
    if (g12_toSRAM_0_re !== x12_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_re golden=%h impl=%h", cyc, g12_toSRAM_0_re, x12_toSRAM_0_re); end
    if (g12_toSRAM_0_we !== x12_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_we golden=%h impl=%h", cyc, g12_toSRAM_0_we, x12_toSRAM_0_we); end
    if (g12_toSRAM_0_ack !== x12_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_ack golden=%h impl=%h", cyc, g12_toSRAM_0_ack, x12_toSRAM_0_ack); end
    if (g12_toSRAM_0_selectedOH !== x12_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g12_toSRAM_0_selectedOH, x12_toSRAM_0_selectedOH); end
    if (g12_toSRAM_0_array !== x12_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_0_array golden=%h impl=%h", cyc, g12_toSRAM_0_array, x12_toSRAM_0_array); end
    if (g12_toSRAM_1_addr !== x12_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_addr golden=%h impl=%h", cyc, g12_toSRAM_1_addr, x12_toSRAM_1_addr); end
    if (g12_toSRAM_1_addr_rd !== x12_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g12_toSRAM_1_addr_rd, x12_toSRAM_1_addr_rd); end
    if (g12_toSRAM_1_wdata !== x12_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_wdata golden=%h impl=%h", cyc, g12_toSRAM_1_wdata, x12_toSRAM_1_wdata); end
    if (g12_toSRAM_1_wmask !== x12_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_wmask golden=%h impl=%h", cyc, g12_toSRAM_1_wmask, x12_toSRAM_1_wmask); end
    if (g12_toSRAM_1_re !== x12_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_re golden=%h impl=%h", cyc, g12_toSRAM_1_re, x12_toSRAM_1_re); end
    if (g12_toSRAM_1_we !== x12_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_we golden=%h impl=%h", cyc, g12_toSRAM_1_we, x12_toSRAM_1_we); end
    if (g12_toSRAM_1_ack !== x12_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_ack golden=%h impl=%h", cyc, g12_toSRAM_1_ack, x12_toSRAM_1_ack); end
    if (g12_toSRAM_1_selectedOH !== x12_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g12_toSRAM_1_selectedOH, x12_toSRAM_1_selectedOH); end
    if (g12_toSRAM_1_array !== x12_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_3.toSRAM_1_array golden=%h impl=%h", cyc, g12_toSRAM_1_array, x12_toSRAM_1_array); end
  endtask

  // ======================== [13] MbistPipeIttage_4 ========================
  logic [75:0] v13_rd0;
  logic [75:0] v13_rd1;
  logic g13_mbist_ack;
  logic [75:0] g13_mbist_outdata;
  logic [7:0] g13_toSRAM_0_addr;
  logic [7:0] g13_toSRAM_0_addr_rd;
  logic [75:0] g13_toSRAM_0_wdata;
  logic [75:0] g13_toSRAM_0_wmask;
  logic g13_toSRAM_0_re;
  logic g13_toSRAM_0_we;
  logic g13_toSRAM_0_ack;
  logic g13_toSRAM_0_selectedOH;
  logic [6:0] g13_toSRAM_0_array;
  logic [7:0] g13_toSRAM_1_addr;
  logic [7:0] g13_toSRAM_1_addr_rd;
  logic [75:0] g13_toSRAM_1_wdata;
  logic [75:0] g13_toSRAM_1_wmask;
  logic g13_toSRAM_1_re;
  logic g13_toSRAM_1_we;
  logic g13_toSRAM_1_ack;
  logic g13_toSRAM_1_selectedOH;
  logic [6:0] g13_toSRAM_1_array;
  logic x13_mbist_ack;
  logic [75:0] x13_mbist_outdata;
  logic [7:0] x13_toSRAM_0_addr;
  logic [7:0] x13_toSRAM_0_addr_rd;
  logic [75:0] x13_toSRAM_0_wdata;
  logic [75:0] x13_toSRAM_0_wmask;
  logic x13_toSRAM_0_re;
  logic x13_toSRAM_0_we;
  logic x13_toSRAM_0_ack;
  logic x13_toSRAM_0_selectedOH;
  logic [6:0] x13_toSRAM_0_array;
  logic [7:0] x13_toSRAM_1_addr;
  logic [7:0] x13_toSRAM_1_addr_rd;
  logic [75:0] x13_toSRAM_1_wdata;
  logic [75:0] x13_toSRAM_1_wmask;
  logic x13_toSRAM_1_re;
  logic x13_toSRAM_1_we;
  logic x13_toSRAM_1_ack;
  logic x13_toSRAM_1_selectedOH;
  logic [6:0] x13_toSRAM_1_array;
  bit [1:0] cov_spread13;
  bit [75:0] cov_od0_13, cov_od1_13;
  bit cov_ack0_13, cov_ack1_13;
  MbistPipeIttage_4 u_g13 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v13_rd0),
    .toSRAM_1_rdata (v13_rd1),
    .mbist_ack (g13_mbist_ack),
    .mbist_outdata (g13_mbist_outdata),
    .toSRAM_0_addr (g13_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g13_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g13_toSRAM_0_wdata),
    .toSRAM_0_wmask (g13_toSRAM_0_wmask),
    .toSRAM_0_re (g13_toSRAM_0_re),
    .toSRAM_0_we (g13_toSRAM_0_we),
    .toSRAM_0_ack (g13_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g13_toSRAM_0_selectedOH),
    .toSRAM_0_array (g13_toSRAM_0_array),
    .toSRAM_1_addr (g13_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g13_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g13_toSRAM_1_wdata),
    .toSRAM_1_wmask (g13_toSRAM_1_wmask),
    .toSRAM_1_re (g13_toSRAM_1_re),
    .toSRAM_1_we (g13_toSRAM_1_we),
    .toSRAM_1_ack (g13_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g13_toSRAM_1_selectedOH),
    .toSRAM_1_array (g13_toSRAM_1_array)
  );
  MbistPipeIttage_4_xs u_x13 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[75:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v13_rd0),
    .toSRAM_1_rdata (v13_rd1),
    .mbist_ack (x13_mbist_ack),
    .mbist_outdata (x13_mbist_outdata),
    .toSRAM_0_addr (x13_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x13_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x13_toSRAM_0_wdata),
    .toSRAM_0_wmask (x13_toSRAM_0_wmask),
    .toSRAM_0_re (x13_toSRAM_0_re),
    .toSRAM_0_we (x13_toSRAM_0_we),
    .toSRAM_0_ack (x13_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x13_toSRAM_0_selectedOH),
    .toSRAM_0_array (x13_toSRAM_0_array),
    .toSRAM_1_addr (x13_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x13_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x13_toSRAM_1_wdata),
    .toSRAM_1_wmask (x13_toSRAM_1_wmask),
    .toSRAM_1_re (x13_toSRAM_1_re),
    .toSRAM_1_we (x13_toSRAM_1_we),
    .toSRAM_1_ack (x13_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x13_toSRAM_1_selectedOH),
    .toSRAM_1_array (x13_toSRAM_1_array)
  );
  wire [434:0] gbus13 = {g13_mbist_ack, g13_mbist_outdata, g13_toSRAM_0_addr, g13_toSRAM_0_addr_rd, g13_toSRAM_0_wdata, g13_toSRAM_0_wmask, g13_toSRAM_0_re, g13_toSRAM_0_we, g13_toSRAM_0_ack, g13_toSRAM_0_selectedOH, g13_toSRAM_0_array, g13_toSRAM_1_addr, g13_toSRAM_1_addr_rd, g13_toSRAM_1_wdata, g13_toSRAM_1_wmask, g13_toSRAM_1_re, g13_toSRAM_1_we, g13_toSRAM_1_ack, g13_toSRAM_1_selectedOH, g13_toSRAM_1_array};
  wire [434:0] xbus13 = {x13_mbist_ack, x13_mbist_outdata, x13_toSRAM_0_addr, x13_toSRAM_0_addr_rd, x13_toSRAM_0_wdata, x13_toSRAM_0_wmask, x13_toSRAM_0_re, x13_toSRAM_0_we, x13_toSRAM_0_ack, x13_toSRAM_0_selectedOH, x13_toSRAM_0_array, x13_toSRAM_1_addr, x13_toSRAM_1_addr_rd, x13_toSRAM_1_wdata, x13_toSRAM_1_wmask, x13_toSRAM_1_re, x13_toSRAM_1_we, x13_toSRAM_1_ack, x13_toSRAM_1_selectedOH, x13_toSRAM_1_array};
  task automatic detail13();
    if (g13_mbist_ack !== x13_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.mbist_ack golden=%h impl=%h", cyc, g13_mbist_ack, x13_mbist_ack); end
    if (g13_mbist_outdata !== x13_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.mbist_outdata golden=%h impl=%h", cyc, g13_mbist_outdata, x13_mbist_outdata); end
    if (g13_toSRAM_0_addr !== x13_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_addr golden=%h impl=%h", cyc, g13_toSRAM_0_addr, x13_toSRAM_0_addr); end
    if (g13_toSRAM_0_addr_rd !== x13_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g13_toSRAM_0_addr_rd, x13_toSRAM_0_addr_rd); end
    if (g13_toSRAM_0_wdata !== x13_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_wdata golden=%h impl=%h", cyc, g13_toSRAM_0_wdata, x13_toSRAM_0_wdata); end
    if (g13_toSRAM_0_wmask !== x13_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_wmask golden=%h impl=%h", cyc, g13_toSRAM_0_wmask, x13_toSRAM_0_wmask); end
    if (g13_toSRAM_0_re !== x13_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_re golden=%h impl=%h", cyc, g13_toSRAM_0_re, x13_toSRAM_0_re); end
    if (g13_toSRAM_0_we !== x13_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_we golden=%h impl=%h", cyc, g13_toSRAM_0_we, x13_toSRAM_0_we); end
    if (g13_toSRAM_0_ack !== x13_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_ack golden=%h impl=%h", cyc, g13_toSRAM_0_ack, x13_toSRAM_0_ack); end
    if (g13_toSRAM_0_selectedOH !== x13_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g13_toSRAM_0_selectedOH, x13_toSRAM_0_selectedOH); end
    if (g13_toSRAM_0_array !== x13_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_0_array golden=%h impl=%h", cyc, g13_toSRAM_0_array, x13_toSRAM_0_array); end
    if (g13_toSRAM_1_addr !== x13_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_addr golden=%h impl=%h", cyc, g13_toSRAM_1_addr, x13_toSRAM_1_addr); end
    if (g13_toSRAM_1_addr_rd !== x13_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g13_toSRAM_1_addr_rd, x13_toSRAM_1_addr_rd); end
    if (g13_toSRAM_1_wdata !== x13_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_wdata golden=%h impl=%h", cyc, g13_toSRAM_1_wdata, x13_toSRAM_1_wdata); end
    if (g13_toSRAM_1_wmask !== x13_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_wmask golden=%h impl=%h", cyc, g13_toSRAM_1_wmask, x13_toSRAM_1_wmask); end
    if (g13_toSRAM_1_re !== x13_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_re golden=%h impl=%h", cyc, g13_toSRAM_1_re, x13_toSRAM_1_re); end
    if (g13_toSRAM_1_we !== x13_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_we golden=%h impl=%h", cyc, g13_toSRAM_1_we, x13_toSRAM_1_we); end
    if (g13_toSRAM_1_ack !== x13_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_ack golden=%h impl=%h", cyc, g13_toSRAM_1_ack, x13_toSRAM_1_ack); end
    if (g13_toSRAM_1_selectedOH !== x13_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g13_toSRAM_1_selectedOH, x13_toSRAM_1_selectedOH); end
    if (g13_toSRAM_1_array !== x13_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeIttage_4.toSRAM_1_array golden=%h impl=%h", cyc, g13_toSRAM_1_array, x13_toSRAM_1_array); end
  endtask

  // ======================== [14] MbistPipeL2Prefetcher ========================
  logic [12:0] v14_rd0;
  logic [12:0] v14_rd1;
  logic g14_mbist_ack;
  logic [12:0] g14_mbist_outdata;
  logic [8:0] g14_toSRAM_0_addr;
  logic [8:0] g14_toSRAM_0_addr_rd;
  logic [12:0] g14_toSRAM_0_wdata;
  logic g14_toSRAM_0_wmask;
  logic g14_toSRAM_0_re;
  logic g14_toSRAM_0_we;
  logic g14_toSRAM_0_ack;
  logic g14_toSRAM_0_selectedOH;
  logic g14_toSRAM_0_array;
  logic [8:0] g14_toSRAM_1_addr;
  logic [8:0] g14_toSRAM_1_addr_rd;
  logic [12:0] g14_toSRAM_1_wdata;
  logic g14_toSRAM_1_wmask;
  logic g14_toSRAM_1_re;
  logic g14_toSRAM_1_we;
  logic g14_toSRAM_1_ack;
  logic g14_toSRAM_1_selectedOH;
  logic g14_toSRAM_1_array;
  logic x14_mbist_ack;
  logic [12:0] x14_mbist_outdata;
  logic [8:0] x14_toSRAM_0_addr;
  logic [8:0] x14_toSRAM_0_addr_rd;
  logic [12:0] x14_toSRAM_0_wdata;
  logic x14_toSRAM_0_wmask;
  logic x14_toSRAM_0_re;
  logic x14_toSRAM_0_we;
  logic x14_toSRAM_0_ack;
  logic x14_toSRAM_0_selectedOH;
  logic x14_toSRAM_0_array;
  logic [8:0] x14_toSRAM_1_addr;
  logic [8:0] x14_toSRAM_1_addr_rd;
  logic [12:0] x14_toSRAM_1_wdata;
  logic x14_toSRAM_1_wmask;
  logic x14_toSRAM_1_re;
  logic x14_toSRAM_1_we;
  logic x14_toSRAM_1_ack;
  logic x14_toSRAM_1_selectedOH;
  logic x14_toSRAM_1_array;
  bit [1:0] cov_spread14;
  bit [12:0] cov_od0_14, cov_od1_14;
  bit cov_ack0_14, cov_ack1_14;
  MbistPipeL2Prefetcher u_g14 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[0:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[12:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v14_rd0),
    .toSRAM_1_rdata (v14_rd1),
    .mbist_ack (g14_mbist_ack),
    .mbist_outdata (g14_mbist_outdata),
    .toSRAM_0_addr (g14_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g14_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g14_toSRAM_0_wdata),
    .toSRAM_0_wmask (g14_toSRAM_0_wmask),
    .toSRAM_0_re (g14_toSRAM_0_re),
    .toSRAM_0_we (g14_toSRAM_0_we),
    .toSRAM_0_ack (g14_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g14_toSRAM_0_selectedOH),
    .toSRAM_0_array (g14_toSRAM_0_array),
    .toSRAM_1_addr (g14_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g14_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g14_toSRAM_1_wdata),
    .toSRAM_1_wmask (g14_toSRAM_1_wmask),
    .toSRAM_1_re (g14_toSRAM_1_re),
    .toSRAM_1_we (g14_toSRAM_1_we),
    .toSRAM_1_ack (g14_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g14_toSRAM_1_selectedOH),
    .toSRAM_1_array (g14_toSRAM_1_array)
  );
  MbistPipeL2Prefetcher_xs u_x14 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[0:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata[12:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toSRAM_0_rdata (v14_rd0),
    .toSRAM_1_rdata (v14_rd1),
    .mbist_ack (x14_mbist_ack),
    .mbist_outdata (x14_mbist_outdata),
    .toSRAM_0_addr (x14_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x14_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x14_toSRAM_0_wdata),
    .toSRAM_0_wmask (x14_toSRAM_0_wmask),
    .toSRAM_0_re (x14_toSRAM_0_re),
    .toSRAM_0_we (x14_toSRAM_0_we),
    .toSRAM_0_ack (x14_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x14_toSRAM_0_selectedOH),
    .toSRAM_0_array (x14_toSRAM_0_array),
    .toSRAM_1_addr (x14_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x14_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x14_toSRAM_1_wdata),
    .toSRAM_1_wmask (x14_toSRAM_1_wmask),
    .toSRAM_1_re (x14_toSRAM_1_re),
    .toSRAM_1_we (x14_toSRAM_1_we),
    .toSRAM_1_ack (x14_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x14_toSRAM_1_selectedOH),
    .toSRAM_1_array (x14_toSRAM_1_array)
  );
  wire [87:0] gbus14 = {g14_mbist_ack, g14_mbist_outdata, g14_toSRAM_0_addr, g14_toSRAM_0_addr_rd, g14_toSRAM_0_wdata, g14_toSRAM_0_wmask, g14_toSRAM_0_re, g14_toSRAM_0_we, g14_toSRAM_0_ack, g14_toSRAM_0_selectedOH, g14_toSRAM_0_array, g14_toSRAM_1_addr, g14_toSRAM_1_addr_rd, g14_toSRAM_1_wdata, g14_toSRAM_1_wmask, g14_toSRAM_1_re, g14_toSRAM_1_we, g14_toSRAM_1_ack, g14_toSRAM_1_selectedOH, g14_toSRAM_1_array};
  wire [87:0] xbus14 = {x14_mbist_ack, x14_mbist_outdata, x14_toSRAM_0_addr, x14_toSRAM_0_addr_rd, x14_toSRAM_0_wdata, x14_toSRAM_0_wmask, x14_toSRAM_0_re, x14_toSRAM_0_we, x14_toSRAM_0_ack, x14_toSRAM_0_selectedOH, x14_toSRAM_0_array, x14_toSRAM_1_addr, x14_toSRAM_1_addr_rd, x14_toSRAM_1_wdata, x14_toSRAM_1_wmask, x14_toSRAM_1_re, x14_toSRAM_1_we, x14_toSRAM_1_ack, x14_toSRAM_1_selectedOH, x14_toSRAM_1_array};
  task automatic detail14();
    if (g14_mbist_ack !== x14_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.mbist_ack golden=%h impl=%h", cyc, g14_mbist_ack, x14_mbist_ack); end
    if (g14_mbist_outdata !== x14_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.mbist_outdata golden=%h impl=%h", cyc, g14_mbist_outdata, x14_mbist_outdata); end
    if (g14_toSRAM_0_addr !== x14_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_addr golden=%h impl=%h", cyc, g14_toSRAM_0_addr, x14_toSRAM_0_addr); end
    if (g14_toSRAM_0_addr_rd !== x14_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g14_toSRAM_0_addr_rd, x14_toSRAM_0_addr_rd); end
    if (g14_toSRAM_0_wdata !== x14_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_wdata golden=%h impl=%h", cyc, g14_toSRAM_0_wdata, x14_toSRAM_0_wdata); end
    if (g14_toSRAM_0_wmask !== x14_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_wmask golden=%h impl=%h", cyc, g14_toSRAM_0_wmask, x14_toSRAM_0_wmask); end
    if (g14_toSRAM_0_re !== x14_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_re golden=%h impl=%h", cyc, g14_toSRAM_0_re, x14_toSRAM_0_re); end
    if (g14_toSRAM_0_we !== x14_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_we golden=%h impl=%h", cyc, g14_toSRAM_0_we, x14_toSRAM_0_we); end
    if (g14_toSRAM_0_ack !== x14_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_ack golden=%h impl=%h", cyc, g14_toSRAM_0_ack, x14_toSRAM_0_ack); end
    if (g14_toSRAM_0_selectedOH !== x14_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g14_toSRAM_0_selectedOH, x14_toSRAM_0_selectedOH); end
    if (g14_toSRAM_0_array !== x14_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_0_array golden=%h impl=%h", cyc, g14_toSRAM_0_array, x14_toSRAM_0_array); end
    if (g14_toSRAM_1_addr !== x14_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_addr golden=%h impl=%h", cyc, g14_toSRAM_1_addr, x14_toSRAM_1_addr); end
    if (g14_toSRAM_1_addr_rd !== x14_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g14_toSRAM_1_addr_rd, x14_toSRAM_1_addr_rd); end
    if (g14_toSRAM_1_wdata !== x14_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_wdata golden=%h impl=%h", cyc, g14_toSRAM_1_wdata, x14_toSRAM_1_wdata); end
    if (g14_toSRAM_1_wmask !== x14_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_wmask golden=%h impl=%h", cyc, g14_toSRAM_1_wmask, x14_toSRAM_1_wmask); end
    if (g14_toSRAM_1_re !== x14_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_re golden=%h impl=%h", cyc, g14_toSRAM_1_re, x14_toSRAM_1_re); end
    if (g14_toSRAM_1_we !== x14_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_we golden=%h impl=%h", cyc, g14_toSRAM_1_we, x14_toSRAM_1_we); end
    if (g14_toSRAM_1_ack !== x14_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_ack golden=%h impl=%h", cyc, g14_toSRAM_1_ack, x14_toSRAM_1_ack); end
    if (g14_toSRAM_1_selectedOH !== x14_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g14_toSRAM_1_selectedOH, x14_toSRAM_1_selectedOH); end
    if (g14_toSRAM_1_array !== x14_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeL2Prefetcher.toSRAM_1_array golden=%h impl=%h", cyc, g14_toSRAM_1_array, x14_toSRAM_1_array); end
  endtask

  // ======================== [15] MbistPipeMemBlk ========================
  logic [71:0] v15_rd0;
  logic v15_ack0;
  logic [85:0] v15_rd1;
  logic v15_ack1;
  logic [89:0] v15_rd2;
  logic v15_ack2;
  logic [130:0] v15_rd3;
  logic v15_ack3;
  logic [113:0] v15_rd4;
  logic v15_ack4;
  logic [147:0] v15_rd5;
  logic v15_ack5;
  logic g15_mbist_ack;
  logic [147:0] g15_mbist_outdata;
  logic [4:0] g15_toNextPipeline_0_array;
  logic g15_toNextPipeline_0_all;
  logic g15_toNextPipeline_0_req;
  logic g15_toNextPipeline_0_writeen;
  logic g15_toNextPipeline_0_be;
  logic [8:0] g15_toNextPipeline_0_addr;
  logic [71:0] g15_toNextPipeline_0_indata;
  logic g15_toNextPipeline_0_readen;
  logic [8:0] g15_toNextPipeline_0_addr_rd;
  logic [5:0] g15_toNextPipeline_1_array;
  logic g15_toNextPipeline_1_all;
  logic g15_toNextPipeline_1_req;
  logic g15_toNextPipeline_1_writeen;
  logic [1:0] g15_toNextPipeline_1_be;
  logic [8:0] g15_toNextPipeline_1_addr;
  logic [85:0] g15_toNextPipeline_1_indata;
  logic g15_toNextPipeline_1_readen;
  logic [8:0] g15_toNextPipeline_1_addr_rd;
  logic [5:0] g15_toNextPipeline_2_array;
  logic g15_toNextPipeline_2_all;
  logic g15_toNextPipeline_2_req;
  logic g15_toNextPipeline_2_writeen;
  logic [1:0] g15_toNextPipeline_2_be;
  logic [5:0] g15_toNextPipeline_2_addr;
  logic [89:0] g15_toNextPipeline_2_indata;
  logic g15_toNextPipeline_2_readen;
  logic [5:0] g15_toNextPipeline_2_addr_rd;
  logic [5:0] g15_toNextPipeline_3_array;
  logic g15_toNextPipeline_3_all;
  logic g15_toNextPipeline_3_req;
  logic g15_toNextPipeline_3_writeen;
  logic g15_toNextPipeline_3_be;
  logic [2:0] g15_toNextPipeline_3_addr;
  logic [130:0] g15_toNextPipeline_3_indata;
  logic g15_toNextPipeline_3_readen;
  logic [2:0] g15_toNextPipeline_3_addr_rd;
  logic [6:0] g15_toNextPipeline_4_array;
  logic g15_toNextPipeline_4_all;
  logic g15_toNextPipeline_4_req;
  logic g15_toNextPipeline_4_writeen;
  logic [1:0] g15_toNextPipeline_4_be;
  logic [6:0] g15_toNextPipeline_4_addr;
  logic [113:0] g15_toNextPipeline_4_indata;
  logic g15_toNextPipeline_4_readen;
  logic [6:0] g15_toNextPipeline_4_addr_rd;
  logic [6:0] g15_toNextPipeline_5_array;
  logic g15_toNextPipeline_5_all;
  logic g15_toNextPipeline_5_req;
  logic g15_toNextPipeline_5_writeen;
  logic [1:0] g15_toNextPipeline_5_be;
  logic [5:0] g15_toNextPipeline_5_addr;
  logic [147:0] g15_toNextPipeline_5_indata;
  logic g15_toNextPipeline_5_readen;
  logic [5:0] g15_toNextPipeline_5_addr_rd;
  logic x15_mbist_ack;
  logic [147:0] x15_mbist_outdata;
  logic [4:0] x15_toNextPipeline_0_array;
  logic x15_toNextPipeline_0_all;
  logic x15_toNextPipeline_0_req;
  logic x15_toNextPipeline_0_writeen;
  logic x15_toNextPipeline_0_be;
  logic [8:0] x15_toNextPipeline_0_addr;
  logic [71:0] x15_toNextPipeline_0_indata;
  logic x15_toNextPipeline_0_readen;
  logic [8:0] x15_toNextPipeline_0_addr_rd;
  logic [5:0] x15_toNextPipeline_1_array;
  logic x15_toNextPipeline_1_all;
  logic x15_toNextPipeline_1_req;
  logic x15_toNextPipeline_1_writeen;
  logic [1:0] x15_toNextPipeline_1_be;
  logic [8:0] x15_toNextPipeline_1_addr;
  logic [85:0] x15_toNextPipeline_1_indata;
  logic x15_toNextPipeline_1_readen;
  logic [8:0] x15_toNextPipeline_1_addr_rd;
  logic [5:0] x15_toNextPipeline_2_array;
  logic x15_toNextPipeline_2_all;
  logic x15_toNextPipeline_2_req;
  logic x15_toNextPipeline_2_writeen;
  logic [1:0] x15_toNextPipeline_2_be;
  logic [5:0] x15_toNextPipeline_2_addr;
  logic [89:0] x15_toNextPipeline_2_indata;
  logic x15_toNextPipeline_2_readen;
  logic [5:0] x15_toNextPipeline_2_addr_rd;
  logic [5:0] x15_toNextPipeline_3_array;
  logic x15_toNextPipeline_3_all;
  logic x15_toNextPipeline_3_req;
  logic x15_toNextPipeline_3_writeen;
  logic x15_toNextPipeline_3_be;
  logic [2:0] x15_toNextPipeline_3_addr;
  logic [130:0] x15_toNextPipeline_3_indata;
  logic x15_toNextPipeline_3_readen;
  logic [2:0] x15_toNextPipeline_3_addr_rd;
  logic [6:0] x15_toNextPipeline_4_array;
  logic x15_toNextPipeline_4_all;
  logic x15_toNextPipeline_4_req;
  logic x15_toNextPipeline_4_writeen;
  logic [1:0] x15_toNextPipeline_4_be;
  logic [6:0] x15_toNextPipeline_4_addr;
  logic [113:0] x15_toNextPipeline_4_indata;
  logic x15_toNextPipeline_4_readen;
  logic [6:0] x15_toNextPipeline_4_addr_rd;
  logic [6:0] x15_toNextPipeline_5_array;
  logic x15_toNextPipeline_5_all;
  logic x15_toNextPipeline_5_req;
  logic x15_toNextPipeline_5_writeen;
  logic [1:0] x15_toNextPipeline_5_be;
  logic [5:0] x15_toNextPipeline_5_addr;
  logic [147:0] x15_toNextPipeline_5_indata;
  logic x15_toNextPipeline_5_readen;
  logic [5:0] x15_toNextPipeline_5_addr_rd;
  bit [5:0] cov_spread15;
  bit [147:0] cov_od0_15, cov_od1_15;
  bit cov_ack0_15, cov_ack1_15;
  MbistPipeMemBlk u_g15 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toNextPipeline_0_ack (v15_ack0),
    .toNextPipeline_0_outdata (v15_rd0),
    .toNextPipeline_1_ack (v15_ack1),
    .toNextPipeline_1_outdata (v15_rd1),
    .toNextPipeline_2_ack (v15_ack2),
    .toNextPipeline_2_outdata (v15_rd2),
    .toNextPipeline_3_ack (v15_ack3),
    .toNextPipeline_3_outdata (v15_rd3),
    .toNextPipeline_4_ack (v15_ack4),
    .toNextPipeline_4_outdata (v15_rd4),
    .toNextPipeline_5_ack (v15_ack5),
    .toNextPipeline_5_outdata (v15_rd5),
    .mbist_ack (g15_mbist_ack),
    .mbist_outdata (g15_mbist_outdata),
    .toNextPipeline_0_array (g15_toNextPipeline_0_array),
    .toNextPipeline_0_all (g15_toNextPipeline_0_all),
    .toNextPipeline_0_req (g15_toNextPipeline_0_req),
    .toNextPipeline_0_writeen (g15_toNextPipeline_0_writeen),
    .toNextPipeline_0_be (g15_toNextPipeline_0_be),
    .toNextPipeline_0_addr (g15_toNextPipeline_0_addr),
    .toNextPipeline_0_indata (g15_toNextPipeline_0_indata),
    .toNextPipeline_0_readen (g15_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (g15_toNextPipeline_0_addr_rd),
    .toNextPipeline_1_array (g15_toNextPipeline_1_array),
    .toNextPipeline_1_all (g15_toNextPipeline_1_all),
    .toNextPipeline_1_req (g15_toNextPipeline_1_req),
    .toNextPipeline_1_writeen (g15_toNextPipeline_1_writeen),
    .toNextPipeline_1_be (g15_toNextPipeline_1_be),
    .toNextPipeline_1_addr (g15_toNextPipeline_1_addr),
    .toNextPipeline_1_indata (g15_toNextPipeline_1_indata),
    .toNextPipeline_1_readen (g15_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (g15_toNextPipeline_1_addr_rd),
    .toNextPipeline_2_array (g15_toNextPipeline_2_array),
    .toNextPipeline_2_all (g15_toNextPipeline_2_all),
    .toNextPipeline_2_req (g15_toNextPipeline_2_req),
    .toNextPipeline_2_writeen (g15_toNextPipeline_2_writeen),
    .toNextPipeline_2_be (g15_toNextPipeline_2_be),
    .toNextPipeline_2_addr (g15_toNextPipeline_2_addr),
    .toNextPipeline_2_indata (g15_toNextPipeline_2_indata),
    .toNextPipeline_2_readen (g15_toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd (g15_toNextPipeline_2_addr_rd),
    .toNextPipeline_3_array (g15_toNextPipeline_3_array),
    .toNextPipeline_3_all (g15_toNextPipeline_3_all),
    .toNextPipeline_3_req (g15_toNextPipeline_3_req),
    .toNextPipeline_3_writeen (g15_toNextPipeline_3_writeen),
    .toNextPipeline_3_be (g15_toNextPipeline_3_be),
    .toNextPipeline_3_addr (g15_toNextPipeline_3_addr),
    .toNextPipeline_3_indata (g15_toNextPipeline_3_indata),
    .toNextPipeline_3_readen (g15_toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd (g15_toNextPipeline_3_addr_rd),
    .toNextPipeline_4_array (g15_toNextPipeline_4_array),
    .toNextPipeline_4_all (g15_toNextPipeline_4_all),
    .toNextPipeline_4_req (g15_toNextPipeline_4_req),
    .toNextPipeline_4_writeen (g15_toNextPipeline_4_writeen),
    .toNextPipeline_4_be (g15_toNextPipeline_4_be),
    .toNextPipeline_4_addr (g15_toNextPipeline_4_addr),
    .toNextPipeline_4_indata (g15_toNextPipeline_4_indata),
    .toNextPipeline_4_readen (g15_toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd (g15_toNextPipeline_4_addr_rd),
    .toNextPipeline_5_array (g15_toNextPipeline_5_array),
    .toNextPipeline_5_all (g15_toNextPipeline_5_all),
    .toNextPipeline_5_req (g15_toNextPipeline_5_req),
    .toNextPipeline_5_writeen (g15_toNextPipeline_5_writeen),
    .toNextPipeline_5_be (g15_toNextPipeline_5_be),
    .toNextPipeline_5_addr (g15_toNextPipeline_5_addr),
    .toNextPipeline_5_indata (g15_toNextPipeline_5_indata),
    .toNextPipeline_5_readen (g15_toNextPipeline_5_readen),
    .toNextPipeline_5_addr_rd (g15_toNextPipeline_5_addr_rd)
  );
  MbistPipeMemBlk_xs u_x15 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[8:0]),
    .mbist_indata (s_indata),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[8:0]),
    .toNextPipeline_0_ack (v15_ack0),
    .toNextPipeline_0_outdata (v15_rd0),
    .toNextPipeline_1_ack (v15_ack1),
    .toNextPipeline_1_outdata (v15_rd1),
    .toNextPipeline_2_ack (v15_ack2),
    .toNextPipeline_2_outdata (v15_rd2),
    .toNextPipeline_3_ack (v15_ack3),
    .toNextPipeline_3_outdata (v15_rd3),
    .toNextPipeline_4_ack (v15_ack4),
    .toNextPipeline_4_outdata (v15_rd4),
    .toNextPipeline_5_ack (v15_ack5),
    .toNextPipeline_5_outdata (v15_rd5),
    .mbist_ack (x15_mbist_ack),
    .mbist_outdata (x15_mbist_outdata),
    .toNextPipeline_0_array (x15_toNextPipeline_0_array),
    .toNextPipeline_0_all (x15_toNextPipeline_0_all),
    .toNextPipeline_0_req (x15_toNextPipeline_0_req),
    .toNextPipeline_0_writeen (x15_toNextPipeline_0_writeen),
    .toNextPipeline_0_be (x15_toNextPipeline_0_be),
    .toNextPipeline_0_addr (x15_toNextPipeline_0_addr),
    .toNextPipeline_0_indata (x15_toNextPipeline_0_indata),
    .toNextPipeline_0_readen (x15_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd (x15_toNextPipeline_0_addr_rd),
    .toNextPipeline_1_array (x15_toNextPipeline_1_array),
    .toNextPipeline_1_all (x15_toNextPipeline_1_all),
    .toNextPipeline_1_req (x15_toNextPipeline_1_req),
    .toNextPipeline_1_writeen (x15_toNextPipeline_1_writeen),
    .toNextPipeline_1_be (x15_toNextPipeline_1_be),
    .toNextPipeline_1_addr (x15_toNextPipeline_1_addr),
    .toNextPipeline_1_indata (x15_toNextPipeline_1_indata),
    .toNextPipeline_1_readen (x15_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd (x15_toNextPipeline_1_addr_rd),
    .toNextPipeline_2_array (x15_toNextPipeline_2_array),
    .toNextPipeline_2_all (x15_toNextPipeline_2_all),
    .toNextPipeline_2_req (x15_toNextPipeline_2_req),
    .toNextPipeline_2_writeen (x15_toNextPipeline_2_writeen),
    .toNextPipeline_2_be (x15_toNextPipeline_2_be),
    .toNextPipeline_2_addr (x15_toNextPipeline_2_addr),
    .toNextPipeline_2_indata (x15_toNextPipeline_2_indata),
    .toNextPipeline_2_readen (x15_toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd (x15_toNextPipeline_2_addr_rd),
    .toNextPipeline_3_array (x15_toNextPipeline_3_array),
    .toNextPipeline_3_all (x15_toNextPipeline_3_all),
    .toNextPipeline_3_req (x15_toNextPipeline_3_req),
    .toNextPipeline_3_writeen (x15_toNextPipeline_3_writeen),
    .toNextPipeline_3_be (x15_toNextPipeline_3_be),
    .toNextPipeline_3_addr (x15_toNextPipeline_3_addr),
    .toNextPipeline_3_indata (x15_toNextPipeline_3_indata),
    .toNextPipeline_3_readen (x15_toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd (x15_toNextPipeline_3_addr_rd),
    .toNextPipeline_4_array (x15_toNextPipeline_4_array),
    .toNextPipeline_4_all (x15_toNextPipeline_4_all),
    .toNextPipeline_4_req (x15_toNextPipeline_4_req),
    .toNextPipeline_4_writeen (x15_toNextPipeline_4_writeen),
    .toNextPipeline_4_be (x15_toNextPipeline_4_be),
    .toNextPipeline_4_addr (x15_toNextPipeline_4_addr),
    .toNextPipeline_4_indata (x15_toNextPipeline_4_indata),
    .toNextPipeline_4_readen (x15_toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd (x15_toNextPipeline_4_addr_rd),
    .toNextPipeline_5_array (x15_toNextPipeline_5_array),
    .toNextPipeline_5_all (x15_toNextPipeline_5_all),
    .toNextPipeline_5_req (x15_toNextPipeline_5_req),
    .toNextPipeline_5_writeen (x15_toNextPipeline_5_writeen),
    .toNextPipeline_5_be (x15_toNextPipeline_5_be),
    .toNextPipeline_5_addr (x15_toNextPipeline_5_addr),
    .toNextPipeline_5_indata (x15_toNextPipeline_5_indata),
    .toNextPipeline_5_readen (x15_toNextPipeline_5_readen),
    .toNextPipeline_5_addr_rd (x15_toNextPipeline_5_addr_rd)
  );
  wire [940:0] gbus15 = {g15_mbist_ack, g15_mbist_outdata, g15_toNextPipeline_0_array, g15_toNextPipeline_0_all, g15_toNextPipeline_0_req, g15_toNextPipeline_0_writeen, g15_toNextPipeline_0_be, g15_toNextPipeline_0_addr, g15_toNextPipeline_0_indata, g15_toNextPipeline_0_readen, g15_toNextPipeline_0_addr_rd, g15_toNextPipeline_1_array, g15_toNextPipeline_1_all, g15_toNextPipeline_1_req, g15_toNextPipeline_1_writeen, g15_toNextPipeline_1_be, g15_toNextPipeline_1_addr, g15_toNextPipeline_1_indata, g15_toNextPipeline_1_readen, g15_toNextPipeline_1_addr_rd, g15_toNextPipeline_2_array, g15_toNextPipeline_2_all, g15_toNextPipeline_2_req, g15_toNextPipeline_2_writeen, g15_toNextPipeline_2_be, g15_toNextPipeline_2_addr, g15_toNextPipeline_2_indata, g15_toNextPipeline_2_readen, g15_toNextPipeline_2_addr_rd, g15_toNextPipeline_3_array, g15_toNextPipeline_3_all, g15_toNextPipeline_3_req, g15_toNextPipeline_3_writeen, g15_toNextPipeline_3_be, g15_toNextPipeline_3_addr, g15_toNextPipeline_3_indata, g15_toNextPipeline_3_readen, g15_toNextPipeline_3_addr_rd, g15_toNextPipeline_4_array, g15_toNextPipeline_4_all, g15_toNextPipeline_4_req, g15_toNextPipeline_4_writeen, g15_toNextPipeline_4_be, g15_toNextPipeline_4_addr, g15_toNextPipeline_4_indata, g15_toNextPipeline_4_readen, g15_toNextPipeline_4_addr_rd, g15_toNextPipeline_5_array, g15_toNextPipeline_5_all, g15_toNextPipeline_5_req, g15_toNextPipeline_5_writeen, g15_toNextPipeline_5_be, g15_toNextPipeline_5_addr, g15_toNextPipeline_5_indata, g15_toNextPipeline_5_readen, g15_toNextPipeline_5_addr_rd};
  wire [940:0] xbus15 = {x15_mbist_ack, x15_mbist_outdata, x15_toNextPipeline_0_array, x15_toNextPipeline_0_all, x15_toNextPipeline_0_req, x15_toNextPipeline_0_writeen, x15_toNextPipeline_0_be, x15_toNextPipeline_0_addr, x15_toNextPipeline_0_indata, x15_toNextPipeline_0_readen, x15_toNextPipeline_0_addr_rd, x15_toNextPipeline_1_array, x15_toNextPipeline_1_all, x15_toNextPipeline_1_req, x15_toNextPipeline_1_writeen, x15_toNextPipeline_1_be, x15_toNextPipeline_1_addr, x15_toNextPipeline_1_indata, x15_toNextPipeline_1_readen, x15_toNextPipeline_1_addr_rd, x15_toNextPipeline_2_array, x15_toNextPipeline_2_all, x15_toNextPipeline_2_req, x15_toNextPipeline_2_writeen, x15_toNextPipeline_2_be, x15_toNextPipeline_2_addr, x15_toNextPipeline_2_indata, x15_toNextPipeline_2_readen, x15_toNextPipeline_2_addr_rd, x15_toNextPipeline_3_array, x15_toNextPipeline_3_all, x15_toNextPipeline_3_req, x15_toNextPipeline_3_writeen, x15_toNextPipeline_3_be, x15_toNextPipeline_3_addr, x15_toNextPipeline_3_indata, x15_toNextPipeline_3_readen, x15_toNextPipeline_3_addr_rd, x15_toNextPipeline_4_array, x15_toNextPipeline_4_all, x15_toNextPipeline_4_req, x15_toNextPipeline_4_writeen, x15_toNextPipeline_4_be, x15_toNextPipeline_4_addr, x15_toNextPipeline_4_indata, x15_toNextPipeline_4_readen, x15_toNextPipeline_4_addr_rd, x15_toNextPipeline_5_array, x15_toNextPipeline_5_all, x15_toNextPipeline_5_req, x15_toNextPipeline_5_writeen, x15_toNextPipeline_5_be, x15_toNextPipeline_5_addr, x15_toNextPipeline_5_indata, x15_toNextPipeline_5_readen, x15_toNextPipeline_5_addr_rd};
  task automatic detail15();
    if (g15_mbist_ack !== x15_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.mbist_ack golden=%h impl=%h", cyc, g15_mbist_ack, x15_mbist_ack); end
    if (g15_mbist_outdata !== x15_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.mbist_outdata golden=%h impl=%h", cyc, g15_mbist_outdata, x15_mbist_outdata); end
    if (g15_toNextPipeline_0_array !== x15_toNextPipeline_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_array golden=%h impl=%h", cyc, g15_toNextPipeline_0_array, x15_toNextPipeline_0_array); end
    if (g15_toNextPipeline_0_all !== x15_toNextPipeline_0_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_all golden=%h impl=%h", cyc, g15_toNextPipeline_0_all, x15_toNextPipeline_0_all); end
    if (g15_toNextPipeline_0_req !== x15_toNextPipeline_0_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_req golden=%h impl=%h", cyc, g15_toNextPipeline_0_req, x15_toNextPipeline_0_req); end
    if (g15_toNextPipeline_0_writeen !== x15_toNextPipeline_0_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_writeen golden=%h impl=%h", cyc, g15_toNextPipeline_0_writeen, x15_toNextPipeline_0_writeen); end
    if (g15_toNextPipeline_0_be !== x15_toNextPipeline_0_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_be golden=%h impl=%h", cyc, g15_toNextPipeline_0_be, x15_toNextPipeline_0_be); end
    if (g15_toNextPipeline_0_addr !== x15_toNextPipeline_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_addr golden=%h impl=%h", cyc, g15_toNextPipeline_0_addr, x15_toNextPipeline_0_addr); end
    if (g15_toNextPipeline_0_indata !== x15_toNextPipeline_0_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_indata golden=%h impl=%h", cyc, g15_toNextPipeline_0_indata, x15_toNextPipeline_0_indata); end
    if (g15_toNextPipeline_0_readen !== x15_toNextPipeline_0_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_readen golden=%h impl=%h", cyc, g15_toNextPipeline_0_readen, x15_toNextPipeline_0_readen); end
    if (g15_toNextPipeline_0_addr_rd !== x15_toNextPipeline_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_0_addr_rd golden=%h impl=%h", cyc, g15_toNextPipeline_0_addr_rd, x15_toNextPipeline_0_addr_rd); end
    if (g15_toNextPipeline_1_array !== x15_toNextPipeline_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_array golden=%h impl=%h", cyc, g15_toNextPipeline_1_array, x15_toNextPipeline_1_array); end
    if (g15_toNextPipeline_1_all !== x15_toNextPipeline_1_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_all golden=%h impl=%h", cyc, g15_toNextPipeline_1_all, x15_toNextPipeline_1_all); end
    if (g15_toNextPipeline_1_req !== x15_toNextPipeline_1_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_req golden=%h impl=%h", cyc, g15_toNextPipeline_1_req, x15_toNextPipeline_1_req); end
    if (g15_toNextPipeline_1_writeen !== x15_toNextPipeline_1_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_writeen golden=%h impl=%h", cyc, g15_toNextPipeline_1_writeen, x15_toNextPipeline_1_writeen); end
    if (g15_toNextPipeline_1_be !== x15_toNextPipeline_1_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_be golden=%h impl=%h", cyc, g15_toNextPipeline_1_be, x15_toNextPipeline_1_be); end
    if (g15_toNextPipeline_1_addr !== x15_toNextPipeline_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_addr golden=%h impl=%h", cyc, g15_toNextPipeline_1_addr, x15_toNextPipeline_1_addr); end
    if (g15_toNextPipeline_1_indata !== x15_toNextPipeline_1_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_indata golden=%h impl=%h", cyc, g15_toNextPipeline_1_indata, x15_toNextPipeline_1_indata); end
    if (g15_toNextPipeline_1_readen !== x15_toNextPipeline_1_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_readen golden=%h impl=%h", cyc, g15_toNextPipeline_1_readen, x15_toNextPipeline_1_readen); end
    if (g15_toNextPipeline_1_addr_rd !== x15_toNextPipeline_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_1_addr_rd golden=%h impl=%h", cyc, g15_toNextPipeline_1_addr_rd, x15_toNextPipeline_1_addr_rd); end
    if (g15_toNextPipeline_2_array !== x15_toNextPipeline_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_array golden=%h impl=%h", cyc, g15_toNextPipeline_2_array, x15_toNextPipeline_2_array); end
    if (g15_toNextPipeline_2_all !== x15_toNextPipeline_2_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_all golden=%h impl=%h", cyc, g15_toNextPipeline_2_all, x15_toNextPipeline_2_all); end
    if (g15_toNextPipeline_2_req !== x15_toNextPipeline_2_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_req golden=%h impl=%h", cyc, g15_toNextPipeline_2_req, x15_toNextPipeline_2_req); end
    if (g15_toNextPipeline_2_writeen !== x15_toNextPipeline_2_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_writeen golden=%h impl=%h", cyc, g15_toNextPipeline_2_writeen, x15_toNextPipeline_2_writeen); end
    if (g15_toNextPipeline_2_be !== x15_toNextPipeline_2_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_be golden=%h impl=%h", cyc, g15_toNextPipeline_2_be, x15_toNextPipeline_2_be); end
    if (g15_toNextPipeline_2_addr !== x15_toNextPipeline_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_addr golden=%h impl=%h", cyc, g15_toNextPipeline_2_addr, x15_toNextPipeline_2_addr); end
    if (g15_toNextPipeline_2_indata !== x15_toNextPipeline_2_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_indata golden=%h impl=%h", cyc, g15_toNextPipeline_2_indata, x15_toNextPipeline_2_indata); end
    if (g15_toNextPipeline_2_readen !== x15_toNextPipeline_2_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_readen golden=%h impl=%h", cyc, g15_toNextPipeline_2_readen, x15_toNextPipeline_2_readen); end
    if (g15_toNextPipeline_2_addr_rd !== x15_toNextPipeline_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_2_addr_rd golden=%h impl=%h", cyc, g15_toNextPipeline_2_addr_rd, x15_toNextPipeline_2_addr_rd); end
    if (g15_toNextPipeline_3_array !== x15_toNextPipeline_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_array golden=%h impl=%h", cyc, g15_toNextPipeline_3_array, x15_toNextPipeline_3_array); end
    if (g15_toNextPipeline_3_all !== x15_toNextPipeline_3_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_all golden=%h impl=%h", cyc, g15_toNextPipeline_3_all, x15_toNextPipeline_3_all); end
    if (g15_toNextPipeline_3_req !== x15_toNextPipeline_3_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_req golden=%h impl=%h", cyc, g15_toNextPipeline_3_req, x15_toNextPipeline_3_req); end
    if (g15_toNextPipeline_3_writeen !== x15_toNextPipeline_3_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_writeen golden=%h impl=%h", cyc, g15_toNextPipeline_3_writeen, x15_toNextPipeline_3_writeen); end
    if (g15_toNextPipeline_3_be !== x15_toNextPipeline_3_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_be golden=%h impl=%h", cyc, g15_toNextPipeline_3_be, x15_toNextPipeline_3_be); end
    if (g15_toNextPipeline_3_addr !== x15_toNextPipeline_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_addr golden=%h impl=%h", cyc, g15_toNextPipeline_3_addr, x15_toNextPipeline_3_addr); end
    if (g15_toNextPipeline_3_indata !== x15_toNextPipeline_3_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_indata golden=%h impl=%h", cyc, g15_toNextPipeline_3_indata, x15_toNextPipeline_3_indata); end
    if (g15_toNextPipeline_3_readen !== x15_toNextPipeline_3_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_readen golden=%h impl=%h", cyc, g15_toNextPipeline_3_readen, x15_toNextPipeline_3_readen); end
    if (g15_toNextPipeline_3_addr_rd !== x15_toNextPipeline_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_3_addr_rd golden=%h impl=%h", cyc, g15_toNextPipeline_3_addr_rd, x15_toNextPipeline_3_addr_rd); end
    if (g15_toNextPipeline_4_array !== x15_toNextPipeline_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_array golden=%h impl=%h", cyc, g15_toNextPipeline_4_array, x15_toNextPipeline_4_array); end
    if (g15_toNextPipeline_4_all !== x15_toNextPipeline_4_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_all golden=%h impl=%h", cyc, g15_toNextPipeline_4_all, x15_toNextPipeline_4_all); end
    if (g15_toNextPipeline_4_req !== x15_toNextPipeline_4_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_req golden=%h impl=%h", cyc, g15_toNextPipeline_4_req, x15_toNextPipeline_4_req); end
    if (g15_toNextPipeline_4_writeen !== x15_toNextPipeline_4_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_writeen golden=%h impl=%h", cyc, g15_toNextPipeline_4_writeen, x15_toNextPipeline_4_writeen); end
    if (g15_toNextPipeline_4_be !== x15_toNextPipeline_4_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_be golden=%h impl=%h", cyc, g15_toNextPipeline_4_be, x15_toNextPipeline_4_be); end
    if (g15_toNextPipeline_4_addr !== x15_toNextPipeline_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_addr golden=%h impl=%h", cyc, g15_toNextPipeline_4_addr, x15_toNextPipeline_4_addr); end
    if (g15_toNextPipeline_4_indata !== x15_toNextPipeline_4_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_indata golden=%h impl=%h", cyc, g15_toNextPipeline_4_indata, x15_toNextPipeline_4_indata); end
    if (g15_toNextPipeline_4_readen !== x15_toNextPipeline_4_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_readen golden=%h impl=%h", cyc, g15_toNextPipeline_4_readen, x15_toNextPipeline_4_readen); end
    if (g15_toNextPipeline_4_addr_rd !== x15_toNextPipeline_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_4_addr_rd golden=%h impl=%h", cyc, g15_toNextPipeline_4_addr_rd, x15_toNextPipeline_4_addr_rd); end
    if (g15_toNextPipeline_5_array !== x15_toNextPipeline_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_array golden=%h impl=%h", cyc, g15_toNextPipeline_5_array, x15_toNextPipeline_5_array); end
    if (g15_toNextPipeline_5_all !== x15_toNextPipeline_5_all) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_all golden=%h impl=%h", cyc, g15_toNextPipeline_5_all, x15_toNextPipeline_5_all); end
    if (g15_toNextPipeline_5_req !== x15_toNextPipeline_5_req) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_req golden=%h impl=%h", cyc, g15_toNextPipeline_5_req, x15_toNextPipeline_5_req); end
    if (g15_toNextPipeline_5_writeen !== x15_toNextPipeline_5_writeen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_writeen golden=%h impl=%h", cyc, g15_toNextPipeline_5_writeen, x15_toNextPipeline_5_writeen); end
    if (g15_toNextPipeline_5_be !== x15_toNextPipeline_5_be) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_be golden=%h impl=%h", cyc, g15_toNextPipeline_5_be, x15_toNextPipeline_5_be); end
    if (g15_toNextPipeline_5_addr !== x15_toNextPipeline_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_addr golden=%h impl=%h", cyc, g15_toNextPipeline_5_addr, x15_toNextPipeline_5_addr); end
    if (g15_toNextPipeline_5_indata !== x15_toNextPipeline_5_indata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_indata golden=%h impl=%h", cyc, g15_toNextPipeline_5_indata, x15_toNextPipeline_5_indata); end
    if (g15_toNextPipeline_5_readen !== x15_toNextPipeline_5_readen) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_readen golden=%h impl=%h", cyc, g15_toNextPipeline_5_readen, x15_toNextPipeline_5_readen); end
    if (g15_toNextPipeline_5_addr_rd !== x15_toNextPipeline_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeMemBlk.toNextPipeline_5_addr_rd golden=%h impl=%h", cyc, g15_toNextPipeline_5_addr_rd, x15_toNextPipeline_5_addr_rd); end
  endtask

  // ======================== [16] MbistPipePtwL0 ========================
  logic [113:0] v16_rd0;
  logic [113:0] v16_rd1;
  logic [113:0] v16_rd2;
  logic [113:0] v16_rd3;
  logic [113:0] v16_rd4;
  logic [113:0] v16_rd5;
  logic [113:0] v16_rd6;
  logic [113:0] v16_rd7;
  logic [113:0] v16_rd8;
  logic [113:0] v16_rd9;
  logic [113:0] v16_rd10;
  logic [113:0] v16_rd11;
  logic [113:0] v16_rd12;
  logic [113:0] v16_rd13;
  logic [113:0] v16_rd14;
  logic [113:0] v16_rd15;
  logic g16_mbist_ack;
  logic [113:0] g16_mbist_outdata;
  logic [6:0] g16_toSRAM_0_addr;
  logic [6:0] g16_toSRAM_0_addr_rd;
  logic [113:0] g16_toSRAM_0_wdata;
  logic [1:0] g16_toSRAM_0_wmask;
  logic g16_toSRAM_0_re;
  logic g16_toSRAM_0_we;
  logic g16_toSRAM_0_ack;
  logic g16_toSRAM_0_selectedOH;
  logic [5:0] g16_toSRAM_0_array;
  logic [6:0] g16_toSRAM_1_addr;
  logic [6:0] g16_toSRAM_1_addr_rd;
  logic [113:0] g16_toSRAM_1_wdata;
  logic [1:0] g16_toSRAM_1_wmask;
  logic g16_toSRAM_1_re;
  logic g16_toSRAM_1_we;
  logic g16_toSRAM_1_ack;
  logic g16_toSRAM_1_selectedOH;
  logic [5:0] g16_toSRAM_1_array;
  logic [6:0] g16_toSRAM_2_addr;
  logic [6:0] g16_toSRAM_2_addr_rd;
  logic [113:0] g16_toSRAM_2_wdata;
  logic [1:0] g16_toSRAM_2_wmask;
  logic g16_toSRAM_2_re;
  logic g16_toSRAM_2_we;
  logic g16_toSRAM_2_ack;
  logic g16_toSRAM_2_selectedOH;
  logic [5:0] g16_toSRAM_2_array;
  logic [6:0] g16_toSRAM_3_addr;
  logic [6:0] g16_toSRAM_3_addr_rd;
  logic [113:0] g16_toSRAM_3_wdata;
  logic [1:0] g16_toSRAM_3_wmask;
  logic g16_toSRAM_3_re;
  logic g16_toSRAM_3_we;
  logic g16_toSRAM_3_ack;
  logic g16_toSRAM_3_selectedOH;
  logic [5:0] g16_toSRAM_3_array;
  logic [6:0] g16_toSRAM_4_addr;
  logic [6:0] g16_toSRAM_4_addr_rd;
  logic [113:0] g16_toSRAM_4_wdata;
  logic [1:0] g16_toSRAM_4_wmask;
  logic g16_toSRAM_4_re;
  logic g16_toSRAM_4_we;
  logic g16_toSRAM_4_ack;
  logic g16_toSRAM_4_selectedOH;
  logic [5:0] g16_toSRAM_4_array;
  logic [6:0] g16_toSRAM_5_addr;
  logic [6:0] g16_toSRAM_5_addr_rd;
  logic [113:0] g16_toSRAM_5_wdata;
  logic [1:0] g16_toSRAM_5_wmask;
  logic g16_toSRAM_5_re;
  logic g16_toSRAM_5_we;
  logic g16_toSRAM_5_ack;
  logic g16_toSRAM_5_selectedOH;
  logic [5:0] g16_toSRAM_5_array;
  logic [6:0] g16_toSRAM_6_addr;
  logic [6:0] g16_toSRAM_6_addr_rd;
  logic [113:0] g16_toSRAM_6_wdata;
  logic [1:0] g16_toSRAM_6_wmask;
  logic g16_toSRAM_6_re;
  logic g16_toSRAM_6_we;
  logic g16_toSRAM_6_ack;
  logic g16_toSRAM_6_selectedOH;
  logic [5:0] g16_toSRAM_6_array;
  logic [6:0] g16_toSRAM_7_addr;
  logic [6:0] g16_toSRAM_7_addr_rd;
  logic [113:0] g16_toSRAM_7_wdata;
  logic [1:0] g16_toSRAM_7_wmask;
  logic g16_toSRAM_7_re;
  logic g16_toSRAM_7_we;
  logic g16_toSRAM_7_ack;
  logic g16_toSRAM_7_selectedOH;
  logic [5:0] g16_toSRAM_7_array;
  logic [6:0] g16_toSRAM_8_addr;
  logic [6:0] g16_toSRAM_8_addr_rd;
  logic [113:0] g16_toSRAM_8_wdata;
  logic [1:0] g16_toSRAM_8_wmask;
  logic g16_toSRAM_8_re;
  logic g16_toSRAM_8_we;
  logic g16_toSRAM_8_ack;
  logic g16_toSRAM_8_selectedOH;
  logic [5:0] g16_toSRAM_8_array;
  logic [6:0] g16_toSRAM_9_addr;
  logic [6:0] g16_toSRAM_9_addr_rd;
  logic [113:0] g16_toSRAM_9_wdata;
  logic [1:0] g16_toSRAM_9_wmask;
  logic g16_toSRAM_9_re;
  logic g16_toSRAM_9_we;
  logic g16_toSRAM_9_ack;
  logic g16_toSRAM_9_selectedOH;
  logic [5:0] g16_toSRAM_9_array;
  logic [6:0] g16_toSRAM_10_addr;
  logic [6:0] g16_toSRAM_10_addr_rd;
  logic [113:0] g16_toSRAM_10_wdata;
  logic [1:0] g16_toSRAM_10_wmask;
  logic g16_toSRAM_10_re;
  logic g16_toSRAM_10_we;
  logic g16_toSRAM_10_ack;
  logic g16_toSRAM_10_selectedOH;
  logic [5:0] g16_toSRAM_10_array;
  logic [6:0] g16_toSRAM_11_addr;
  logic [6:0] g16_toSRAM_11_addr_rd;
  logic [113:0] g16_toSRAM_11_wdata;
  logic [1:0] g16_toSRAM_11_wmask;
  logic g16_toSRAM_11_re;
  logic g16_toSRAM_11_we;
  logic g16_toSRAM_11_ack;
  logic g16_toSRAM_11_selectedOH;
  logic [5:0] g16_toSRAM_11_array;
  logic [6:0] g16_toSRAM_12_addr;
  logic [6:0] g16_toSRAM_12_addr_rd;
  logic [113:0] g16_toSRAM_12_wdata;
  logic [1:0] g16_toSRAM_12_wmask;
  logic g16_toSRAM_12_re;
  logic g16_toSRAM_12_we;
  logic g16_toSRAM_12_ack;
  logic g16_toSRAM_12_selectedOH;
  logic [5:0] g16_toSRAM_12_array;
  logic [6:0] g16_toSRAM_13_addr;
  logic [6:0] g16_toSRAM_13_addr_rd;
  logic [113:0] g16_toSRAM_13_wdata;
  logic [1:0] g16_toSRAM_13_wmask;
  logic g16_toSRAM_13_re;
  logic g16_toSRAM_13_we;
  logic g16_toSRAM_13_ack;
  logic g16_toSRAM_13_selectedOH;
  logic [5:0] g16_toSRAM_13_array;
  logic [6:0] g16_toSRAM_14_addr;
  logic [6:0] g16_toSRAM_14_addr_rd;
  logic [113:0] g16_toSRAM_14_wdata;
  logic [1:0] g16_toSRAM_14_wmask;
  logic g16_toSRAM_14_re;
  logic g16_toSRAM_14_we;
  logic g16_toSRAM_14_ack;
  logic g16_toSRAM_14_selectedOH;
  logic [6:0] g16_toSRAM_14_array;
  logic [6:0] g16_toSRAM_15_addr;
  logic [6:0] g16_toSRAM_15_addr_rd;
  logic [113:0] g16_toSRAM_15_wdata;
  logic [1:0] g16_toSRAM_15_wmask;
  logic g16_toSRAM_15_re;
  logic g16_toSRAM_15_we;
  logic g16_toSRAM_15_ack;
  logic g16_toSRAM_15_selectedOH;
  logic [6:0] g16_toSRAM_15_array;
  logic x16_mbist_ack;
  logic [113:0] x16_mbist_outdata;
  logic [6:0] x16_toSRAM_0_addr;
  logic [6:0] x16_toSRAM_0_addr_rd;
  logic [113:0] x16_toSRAM_0_wdata;
  logic [1:0] x16_toSRAM_0_wmask;
  logic x16_toSRAM_0_re;
  logic x16_toSRAM_0_we;
  logic x16_toSRAM_0_ack;
  logic x16_toSRAM_0_selectedOH;
  logic [5:0] x16_toSRAM_0_array;
  logic [6:0] x16_toSRAM_1_addr;
  logic [6:0] x16_toSRAM_1_addr_rd;
  logic [113:0] x16_toSRAM_1_wdata;
  logic [1:0] x16_toSRAM_1_wmask;
  logic x16_toSRAM_1_re;
  logic x16_toSRAM_1_we;
  logic x16_toSRAM_1_ack;
  logic x16_toSRAM_1_selectedOH;
  logic [5:0] x16_toSRAM_1_array;
  logic [6:0] x16_toSRAM_2_addr;
  logic [6:0] x16_toSRAM_2_addr_rd;
  logic [113:0] x16_toSRAM_2_wdata;
  logic [1:0] x16_toSRAM_2_wmask;
  logic x16_toSRAM_2_re;
  logic x16_toSRAM_2_we;
  logic x16_toSRAM_2_ack;
  logic x16_toSRAM_2_selectedOH;
  logic [5:0] x16_toSRAM_2_array;
  logic [6:0] x16_toSRAM_3_addr;
  logic [6:0] x16_toSRAM_3_addr_rd;
  logic [113:0] x16_toSRAM_3_wdata;
  logic [1:0] x16_toSRAM_3_wmask;
  logic x16_toSRAM_3_re;
  logic x16_toSRAM_3_we;
  logic x16_toSRAM_3_ack;
  logic x16_toSRAM_3_selectedOH;
  logic [5:0] x16_toSRAM_3_array;
  logic [6:0] x16_toSRAM_4_addr;
  logic [6:0] x16_toSRAM_4_addr_rd;
  logic [113:0] x16_toSRAM_4_wdata;
  logic [1:0] x16_toSRAM_4_wmask;
  logic x16_toSRAM_4_re;
  logic x16_toSRAM_4_we;
  logic x16_toSRAM_4_ack;
  logic x16_toSRAM_4_selectedOH;
  logic [5:0] x16_toSRAM_4_array;
  logic [6:0] x16_toSRAM_5_addr;
  logic [6:0] x16_toSRAM_5_addr_rd;
  logic [113:0] x16_toSRAM_5_wdata;
  logic [1:0] x16_toSRAM_5_wmask;
  logic x16_toSRAM_5_re;
  logic x16_toSRAM_5_we;
  logic x16_toSRAM_5_ack;
  logic x16_toSRAM_5_selectedOH;
  logic [5:0] x16_toSRAM_5_array;
  logic [6:0] x16_toSRAM_6_addr;
  logic [6:0] x16_toSRAM_6_addr_rd;
  logic [113:0] x16_toSRAM_6_wdata;
  logic [1:0] x16_toSRAM_6_wmask;
  logic x16_toSRAM_6_re;
  logic x16_toSRAM_6_we;
  logic x16_toSRAM_6_ack;
  logic x16_toSRAM_6_selectedOH;
  logic [5:0] x16_toSRAM_6_array;
  logic [6:0] x16_toSRAM_7_addr;
  logic [6:0] x16_toSRAM_7_addr_rd;
  logic [113:0] x16_toSRAM_7_wdata;
  logic [1:0] x16_toSRAM_7_wmask;
  logic x16_toSRAM_7_re;
  logic x16_toSRAM_7_we;
  logic x16_toSRAM_7_ack;
  logic x16_toSRAM_7_selectedOH;
  logic [5:0] x16_toSRAM_7_array;
  logic [6:0] x16_toSRAM_8_addr;
  logic [6:0] x16_toSRAM_8_addr_rd;
  logic [113:0] x16_toSRAM_8_wdata;
  logic [1:0] x16_toSRAM_8_wmask;
  logic x16_toSRAM_8_re;
  logic x16_toSRAM_8_we;
  logic x16_toSRAM_8_ack;
  logic x16_toSRAM_8_selectedOH;
  logic [5:0] x16_toSRAM_8_array;
  logic [6:0] x16_toSRAM_9_addr;
  logic [6:0] x16_toSRAM_9_addr_rd;
  logic [113:0] x16_toSRAM_9_wdata;
  logic [1:0] x16_toSRAM_9_wmask;
  logic x16_toSRAM_9_re;
  logic x16_toSRAM_9_we;
  logic x16_toSRAM_9_ack;
  logic x16_toSRAM_9_selectedOH;
  logic [5:0] x16_toSRAM_9_array;
  logic [6:0] x16_toSRAM_10_addr;
  logic [6:0] x16_toSRAM_10_addr_rd;
  logic [113:0] x16_toSRAM_10_wdata;
  logic [1:0] x16_toSRAM_10_wmask;
  logic x16_toSRAM_10_re;
  logic x16_toSRAM_10_we;
  logic x16_toSRAM_10_ack;
  logic x16_toSRAM_10_selectedOH;
  logic [5:0] x16_toSRAM_10_array;
  logic [6:0] x16_toSRAM_11_addr;
  logic [6:0] x16_toSRAM_11_addr_rd;
  logic [113:0] x16_toSRAM_11_wdata;
  logic [1:0] x16_toSRAM_11_wmask;
  logic x16_toSRAM_11_re;
  logic x16_toSRAM_11_we;
  logic x16_toSRAM_11_ack;
  logic x16_toSRAM_11_selectedOH;
  logic [5:0] x16_toSRAM_11_array;
  logic [6:0] x16_toSRAM_12_addr;
  logic [6:0] x16_toSRAM_12_addr_rd;
  logic [113:0] x16_toSRAM_12_wdata;
  logic [1:0] x16_toSRAM_12_wmask;
  logic x16_toSRAM_12_re;
  logic x16_toSRAM_12_we;
  logic x16_toSRAM_12_ack;
  logic x16_toSRAM_12_selectedOH;
  logic [5:0] x16_toSRAM_12_array;
  logic [6:0] x16_toSRAM_13_addr;
  logic [6:0] x16_toSRAM_13_addr_rd;
  logic [113:0] x16_toSRAM_13_wdata;
  logic [1:0] x16_toSRAM_13_wmask;
  logic x16_toSRAM_13_re;
  logic x16_toSRAM_13_we;
  logic x16_toSRAM_13_ack;
  logic x16_toSRAM_13_selectedOH;
  logic [5:0] x16_toSRAM_13_array;
  logic [6:0] x16_toSRAM_14_addr;
  logic [6:0] x16_toSRAM_14_addr_rd;
  logic [113:0] x16_toSRAM_14_wdata;
  logic [1:0] x16_toSRAM_14_wmask;
  logic x16_toSRAM_14_re;
  logic x16_toSRAM_14_we;
  logic x16_toSRAM_14_ack;
  logic x16_toSRAM_14_selectedOH;
  logic [6:0] x16_toSRAM_14_array;
  logic [6:0] x16_toSRAM_15_addr;
  logic [6:0] x16_toSRAM_15_addr_rd;
  logic [113:0] x16_toSRAM_15_wdata;
  logic [1:0] x16_toSRAM_15_wmask;
  logic x16_toSRAM_15_re;
  logic x16_toSRAM_15_we;
  logic x16_toSRAM_15_ack;
  logic x16_toSRAM_15_selectedOH;
  logic [6:0] x16_toSRAM_15_array;
  bit [15:0] cov_spread16;
  bit [113:0] cov_od0_16, cov_od1_16;
  bit cov_ack0_16, cov_ack1_16;
  MbistPipePtwL0 u_g16 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[6:0]),
    .mbist_indata (s_indata[113:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[6:0]),
    .toSRAM_0_rdata (v16_rd0),
    .toSRAM_1_rdata (v16_rd1),
    .toSRAM_2_rdata (v16_rd2),
    .toSRAM_3_rdata (v16_rd3),
    .toSRAM_4_rdata (v16_rd4),
    .toSRAM_5_rdata (v16_rd5),
    .toSRAM_6_rdata (v16_rd6),
    .toSRAM_7_rdata (v16_rd7),
    .toSRAM_8_rdata (v16_rd8),
    .toSRAM_9_rdata (v16_rd9),
    .toSRAM_10_rdata (v16_rd10),
    .toSRAM_11_rdata (v16_rd11),
    .toSRAM_12_rdata (v16_rd12),
    .toSRAM_13_rdata (v16_rd13),
    .toSRAM_14_rdata (v16_rd14),
    .toSRAM_15_rdata (v16_rd15),
    .mbist_ack (g16_mbist_ack),
    .mbist_outdata (g16_mbist_outdata),
    .toSRAM_0_addr (g16_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g16_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g16_toSRAM_0_wdata),
    .toSRAM_0_wmask (g16_toSRAM_0_wmask),
    .toSRAM_0_re (g16_toSRAM_0_re),
    .toSRAM_0_we (g16_toSRAM_0_we),
    .toSRAM_0_ack (g16_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g16_toSRAM_0_selectedOH),
    .toSRAM_0_array (g16_toSRAM_0_array),
    .toSRAM_1_addr (g16_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g16_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g16_toSRAM_1_wdata),
    .toSRAM_1_wmask (g16_toSRAM_1_wmask),
    .toSRAM_1_re (g16_toSRAM_1_re),
    .toSRAM_1_we (g16_toSRAM_1_we),
    .toSRAM_1_ack (g16_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g16_toSRAM_1_selectedOH),
    .toSRAM_1_array (g16_toSRAM_1_array),
    .toSRAM_2_addr (g16_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g16_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g16_toSRAM_2_wdata),
    .toSRAM_2_wmask (g16_toSRAM_2_wmask),
    .toSRAM_2_re (g16_toSRAM_2_re),
    .toSRAM_2_we (g16_toSRAM_2_we),
    .toSRAM_2_ack (g16_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g16_toSRAM_2_selectedOH),
    .toSRAM_2_array (g16_toSRAM_2_array),
    .toSRAM_3_addr (g16_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g16_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g16_toSRAM_3_wdata),
    .toSRAM_3_wmask (g16_toSRAM_3_wmask),
    .toSRAM_3_re (g16_toSRAM_3_re),
    .toSRAM_3_we (g16_toSRAM_3_we),
    .toSRAM_3_ack (g16_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g16_toSRAM_3_selectedOH),
    .toSRAM_3_array (g16_toSRAM_3_array),
    .toSRAM_4_addr (g16_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g16_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g16_toSRAM_4_wdata),
    .toSRAM_4_wmask (g16_toSRAM_4_wmask),
    .toSRAM_4_re (g16_toSRAM_4_re),
    .toSRAM_4_we (g16_toSRAM_4_we),
    .toSRAM_4_ack (g16_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g16_toSRAM_4_selectedOH),
    .toSRAM_4_array (g16_toSRAM_4_array),
    .toSRAM_5_addr (g16_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g16_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g16_toSRAM_5_wdata),
    .toSRAM_5_wmask (g16_toSRAM_5_wmask),
    .toSRAM_5_re (g16_toSRAM_5_re),
    .toSRAM_5_we (g16_toSRAM_5_we),
    .toSRAM_5_ack (g16_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g16_toSRAM_5_selectedOH),
    .toSRAM_5_array (g16_toSRAM_5_array),
    .toSRAM_6_addr (g16_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g16_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g16_toSRAM_6_wdata),
    .toSRAM_6_wmask (g16_toSRAM_6_wmask),
    .toSRAM_6_re (g16_toSRAM_6_re),
    .toSRAM_6_we (g16_toSRAM_6_we),
    .toSRAM_6_ack (g16_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g16_toSRAM_6_selectedOH),
    .toSRAM_6_array (g16_toSRAM_6_array),
    .toSRAM_7_addr (g16_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g16_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g16_toSRAM_7_wdata),
    .toSRAM_7_wmask (g16_toSRAM_7_wmask),
    .toSRAM_7_re (g16_toSRAM_7_re),
    .toSRAM_7_we (g16_toSRAM_7_we),
    .toSRAM_7_ack (g16_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g16_toSRAM_7_selectedOH),
    .toSRAM_7_array (g16_toSRAM_7_array),
    .toSRAM_8_addr (g16_toSRAM_8_addr),
    .toSRAM_8_addr_rd (g16_toSRAM_8_addr_rd),
    .toSRAM_8_wdata (g16_toSRAM_8_wdata),
    .toSRAM_8_wmask (g16_toSRAM_8_wmask),
    .toSRAM_8_re (g16_toSRAM_8_re),
    .toSRAM_8_we (g16_toSRAM_8_we),
    .toSRAM_8_ack (g16_toSRAM_8_ack),
    .toSRAM_8_selectedOH (g16_toSRAM_8_selectedOH),
    .toSRAM_8_array (g16_toSRAM_8_array),
    .toSRAM_9_addr (g16_toSRAM_9_addr),
    .toSRAM_9_addr_rd (g16_toSRAM_9_addr_rd),
    .toSRAM_9_wdata (g16_toSRAM_9_wdata),
    .toSRAM_9_wmask (g16_toSRAM_9_wmask),
    .toSRAM_9_re (g16_toSRAM_9_re),
    .toSRAM_9_we (g16_toSRAM_9_we),
    .toSRAM_9_ack (g16_toSRAM_9_ack),
    .toSRAM_9_selectedOH (g16_toSRAM_9_selectedOH),
    .toSRAM_9_array (g16_toSRAM_9_array),
    .toSRAM_10_addr (g16_toSRAM_10_addr),
    .toSRAM_10_addr_rd (g16_toSRAM_10_addr_rd),
    .toSRAM_10_wdata (g16_toSRAM_10_wdata),
    .toSRAM_10_wmask (g16_toSRAM_10_wmask),
    .toSRAM_10_re (g16_toSRAM_10_re),
    .toSRAM_10_we (g16_toSRAM_10_we),
    .toSRAM_10_ack (g16_toSRAM_10_ack),
    .toSRAM_10_selectedOH (g16_toSRAM_10_selectedOH),
    .toSRAM_10_array (g16_toSRAM_10_array),
    .toSRAM_11_addr (g16_toSRAM_11_addr),
    .toSRAM_11_addr_rd (g16_toSRAM_11_addr_rd),
    .toSRAM_11_wdata (g16_toSRAM_11_wdata),
    .toSRAM_11_wmask (g16_toSRAM_11_wmask),
    .toSRAM_11_re (g16_toSRAM_11_re),
    .toSRAM_11_we (g16_toSRAM_11_we),
    .toSRAM_11_ack (g16_toSRAM_11_ack),
    .toSRAM_11_selectedOH (g16_toSRAM_11_selectedOH),
    .toSRAM_11_array (g16_toSRAM_11_array),
    .toSRAM_12_addr (g16_toSRAM_12_addr),
    .toSRAM_12_addr_rd (g16_toSRAM_12_addr_rd),
    .toSRAM_12_wdata (g16_toSRAM_12_wdata),
    .toSRAM_12_wmask (g16_toSRAM_12_wmask),
    .toSRAM_12_re (g16_toSRAM_12_re),
    .toSRAM_12_we (g16_toSRAM_12_we),
    .toSRAM_12_ack (g16_toSRAM_12_ack),
    .toSRAM_12_selectedOH (g16_toSRAM_12_selectedOH),
    .toSRAM_12_array (g16_toSRAM_12_array),
    .toSRAM_13_addr (g16_toSRAM_13_addr),
    .toSRAM_13_addr_rd (g16_toSRAM_13_addr_rd),
    .toSRAM_13_wdata (g16_toSRAM_13_wdata),
    .toSRAM_13_wmask (g16_toSRAM_13_wmask),
    .toSRAM_13_re (g16_toSRAM_13_re),
    .toSRAM_13_we (g16_toSRAM_13_we),
    .toSRAM_13_ack (g16_toSRAM_13_ack),
    .toSRAM_13_selectedOH (g16_toSRAM_13_selectedOH),
    .toSRAM_13_array (g16_toSRAM_13_array),
    .toSRAM_14_addr (g16_toSRAM_14_addr),
    .toSRAM_14_addr_rd (g16_toSRAM_14_addr_rd),
    .toSRAM_14_wdata (g16_toSRAM_14_wdata),
    .toSRAM_14_wmask (g16_toSRAM_14_wmask),
    .toSRAM_14_re (g16_toSRAM_14_re),
    .toSRAM_14_we (g16_toSRAM_14_we),
    .toSRAM_14_ack (g16_toSRAM_14_ack),
    .toSRAM_14_selectedOH (g16_toSRAM_14_selectedOH),
    .toSRAM_14_array (g16_toSRAM_14_array),
    .toSRAM_15_addr (g16_toSRAM_15_addr),
    .toSRAM_15_addr_rd (g16_toSRAM_15_addr_rd),
    .toSRAM_15_wdata (g16_toSRAM_15_wdata),
    .toSRAM_15_wmask (g16_toSRAM_15_wmask),
    .toSRAM_15_re (g16_toSRAM_15_re),
    .toSRAM_15_we (g16_toSRAM_15_we),
    .toSRAM_15_ack (g16_toSRAM_15_ack),
    .toSRAM_15_selectedOH (g16_toSRAM_15_selectedOH),
    .toSRAM_15_array (g16_toSRAM_15_array)
  );
  MbistPipePtwL0_xs u_x16 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[6:0]),
    .mbist_indata (s_indata[113:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[6:0]),
    .toSRAM_0_rdata (v16_rd0),
    .toSRAM_1_rdata (v16_rd1),
    .toSRAM_2_rdata (v16_rd2),
    .toSRAM_3_rdata (v16_rd3),
    .toSRAM_4_rdata (v16_rd4),
    .toSRAM_5_rdata (v16_rd5),
    .toSRAM_6_rdata (v16_rd6),
    .toSRAM_7_rdata (v16_rd7),
    .toSRAM_8_rdata (v16_rd8),
    .toSRAM_9_rdata (v16_rd9),
    .toSRAM_10_rdata (v16_rd10),
    .toSRAM_11_rdata (v16_rd11),
    .toSRAM_12_rdata (v16_rd12),
    .toSRAM_13_rdata (v16_rd13),
    .toSRAM_14_rdata (v16_rd14),
    .toSRAM_15_rdata (v16_rd15),
    .mbist_ack (x16_mbist_ack),
    .mbist_outdata (x16_mbist_outdata),
    .toSRAM_0_addr (x16_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x16_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x16_toSRAM_0_wdata),
    .toSRAM_0_wmask (x16_toSRAM_0_wmask),
    .toSRAM_0_re (x16_toSRAM_0_re),
    .toSRAM_0_we (x16_toSRAM_0_we),
    .toSRAM_0_ack (x16_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x16_toSRAM_0_selectedOH),
    .toSRAM_0_array (x16_toSRAM_0_array),
    .toSRAM_1_addr (x16_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x16_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x16_toSRAM_1_wdata),
    .toSRAM_1_wmask (x16_toSRAM_1_wmask),
    .toSRAM_1_re (x16_toSRAM_1_re),
    .toSRAM_1_we (x16_toSRAM_1_we),
    .toSRAM_1_ack (x16_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x16_toSRAM_1_selectedOH),
    .toSRAM_1_array (x16_toSRAM_1_array),
    .toSRAM_2_addr (x16_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x16_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x16_toSRAM_2_wdata),
    .toSRAM_2_wmask (x16_toSRAM_2_wmask),
    .toSRAM_2_re (x16_toSRAM_2_re),
    .toSRAM_2_we (x16_toSRAM_2_we),
    .toSRAM_2_ack (x16_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x16_toSRAM_2_selectedOH),
    .toSRAM_2_array (x16_toSRAM_2_array),
    .toSRAM_3_addr (x16_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x16_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x16_toSRAM_3_wdata),
    .toSRAM_3_wmask (x16_toSRAM_3_wmask),
    .toSRAM_3_re (x16_toSRAM_3_re),
    .toSRAM_3_we (x16_toSRAM_3_we),
    .toSRAM_3_ack (x16_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x16_toSRAM_3_selectedOH),
    .toSRAM_3_array (x16_toSRAM_3_array),
    .toSRAM_4_addr (x16_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x16_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x16_toSRAM_4_wdata),
    .toSRAM_4_wmask (x16_toSRAM_4_wmask),
    .toSRAM_4_re (x16_toSRAM_4_re),
    .toSRAM_4_we (x16_toSRAM_4_we),
    .toSRAM_4_ack (x16_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x16_toSRAM_4_selectedOH),
    .toSRAM_4_array (x16_toSRAM_4_array),
    .toSRAM_5_addr (x16_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x16_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x16_toSRAM_5_wdata),
    .toSRAM_5_wmask (x16_toSRAM_5_wmask),
    .toSRAM_5_re (x16_toSRAM_5_re),
    .toSRAM_5_we (x16_toSRAM_5_we),
    .toSRAM_5_ack (x16_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x16_toSRAM_5_selectedOH),
    .toSRAM_5_array (x16_toSRAM_5_array),
    .toSRAM_6_addr (x16_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x16_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x16_toSRAM_6_wdata),
    .toSRAM_6_wmask (x16_toSRAM_6_wmask),
    .toSRAM_6_re (x16_toSRAM_6_re),
    .toSRAM_6_we (x16_toSRAM_6_we),
    .toSRAM_6_ack (x16_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x16_toSRAM_6_selectedOH),
    .toSRAM_6_array (x16_toSRAM_6_array),
    .toSRAM_7_addr (x16_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x16_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x16_toSRAM_7_wdata),
    .toSRAM_7_wmask (x16_toSRAM_7_wmask),
    .toSRAM_7_re (x16_toSRAM_7_re),
    .toSRAM_7_we (x16_toSRAM_7_we),
    .toSRAM_7_ack (x16_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x16_toSRAM_7_selectedOH),
    .toSRAM_7_array (x16_toSRAM_7_array),
    .toSRAM_8_addr (x16_toSRAM_8_addr),
    .toSRAM_8_addr_rd (x16_toSRAM_8_addr_rd),
    .toSRAM_8_wdata (x16_toSRAM_8_wdata),
    .toSRAM_8_wmask (x16_toSRAM_8_wmask),
    .toSRAM_8_re (x16_toSRAM_8_re),
    .toSRAM_8_we (x16_toSRAM_8_we),
    .toSRAM_8_ack (x16_toSRAM_8_ack),
    .toSRAM_8_selectedOH (x16_toSRAM_8_selectedOH),
    .toSRAM_8_array (x16_toSRAM_8_array),
    .toSRAM_9_addr (x16_toSRAM_9_addr),
    .toSRAM_9_addr_rd (x16_toSRAM_9_addr_rd),
    .toSRAM_9_wdata (x16_toSRAM_9_wdata),
    .toSRAM_9_wmask (x16_toSRAM_9_wmask),
    .toSRAM_9_re (x16_toSRAM_9_re),
    .toSRAM_9_we (x16_toSRAM_9_we),
    .toSRAM_9_ack (x16_toSRAM_9_ack),
    .toSRAM_9_selectedOH (x16_toSRAM_9_selectedOH),
    .toSRAM_9_array (x16_toSRAM_9_array),
    .toSRAM_10_addr (x16_toSRAM_10_addr),
    .toSRAM_10_addr_rd (x16_toSRAM_10_addr_rd),
    .toSRAM_10_wdata (x16_toSRAM_10_wdata),
    .toSRAM_10_wmask (x16_toSRAM_10_wmask),
    .toSRAM_10_re (x16_toSRAM_10_re),
    .toSRAM_10_we (x16_toSRAM_10_we),
    .toSRAM_10_ack (x16_toSRAM_10_ack),
    .toSRAM_10_selectedOH (x16_toSRAM_10_selectedOH),
    .toSRAM_10_array (x16_toSRAM_10_array),
    .toSRAM_11_addr (x16_toSRAM_11_addr),
    .toSRAM_11_addr_rd (x16_toSRAM_11_addr_rd),
    .toSRAM_11_wdata (x16_toSRAM_11_wdata),
    .toSRAM_11_wmask (x16_toSRAM_11_wmask),
    .toSRAM_11_re (x16_toSRAM_11_re),
    .toSRAM_11_we (x16_toSRAM_11_we),
    .toSRAM_11_ack (x16_toSRAM_11_ack),
    .toSRAM_11_selectedOH (x16_toSRAM_11_selectedOH),
    .toSRAM_11_array (x16_toSRAM_11_array),
    .toSRAM_12_addr (x16_toSRAM_12_addr),
    .toSRAM_12_addr_rd (x16_toSRAM_12_addr_rd),
    .toSRAM_12_wdata (x16_toSRAM_12_wdata),
    .toSRAM_12_wmask (x16_toSRAM_12_wmask),
    .toSRAM_12_re (x16_toSRAM_12_re),
    .toSRAM_12_we (x16_toSRAM_12_we),
    .toSRAM_12_ack (x16_toSRAM_12_ack),
    .toSRAM_12_selectedOH (x16_toSRAM_12_selectedOH),
    .toSRAM_12_array (x16_toSRAM_12_array),
    .toSRAM_13_addr (x16_toSRAM_13_addr),
    .toSRAM_13_addr_rd (x16_toSRAM_13_addr_rd),
    .toSRAM_13_wdata (x16_toSRAM_13_wdata),
    .toSRAM_13_wmask (x16_toSRAM_13_wmask),
    .toSRAM_13_re (x16_toSRAM_13_re),
    .toSRAM_13_we (x16_toSRAM_13_we),
    .toSRAM_13_ack (x16_toSRAM_13_ack),
    .toSRAM_13_selectedOH (x16_toSRAM_13_selectedOH),
    .toSRAM_13_array (x16_toSRAM_13_array),
    .toSRAM_14_addr (x16_toSRAM_14_addr),
    .toSRAM_14_addr_rd (x16_toSRAM_14_addr_rd),
    .toSRAM_14_wdata (x16_toSRAM_14_wdata),
    .toSRAM_14_wmask (x16_toSRAM_14_wmask),
    .toSRAM_14_re (x16_toSRAM_14_re),
    .toSRAM_14_we (x16_toSRAM_14_we),
    .toSRAM_14_ack (x16_toSRAM_14_ack),
    .toSRAM_14_selectedOH (x16_toSRAM_14_selectedOH),
    .toSRAM_14_array (x16_toSRAM_14_array),
    .toSRAM_15_addr (x16_toSRAM_15_addr),
    .toSRAM_15_addr_rd (x16_toSRAM_15_addr_rd),
    .toSRAM_15_wdata (x16_toSRAM_15_wdata),
    .toSRAM_15_wmask (x16_toSRAM_15_wmask),
    .toSRAM_15_re (x16_toSRAM_15_re),
    .toSRAM_15_we (x16_toSRAM_15_we),
    .toSRAM_15_ack (x16_toSRAM_15_ack),
    .toSRAM_15_selectedOH (x16_toSRAM_15_selectedOH),
    .toSRAM_15_array (x16_toSRAM_15_array)
  );
  wire [2356:0] gbus16 = {g16_mbist_ack, g16_mbist_outdata, g16_toSRAM_0_addr, g16_toSRAM_0_addr_rd, g16_toSRAM_0_wdata, g16_toSRAM_0_wmask, g16_toSRAM_0_re, g16_toSRAM_0_we, g16_toSRAM_0_ack, g16_toSRAM_0_selectedOH, g16_toSRAM_0_array, g16_toSRAM_1_addr, g16_toSRAM_1_addr_rd, g16_toSRAM_1_wdata, g16_toSRAM_1_wmask, g16_toSRAM_1_re, g16_toSRAM_1_we, g16_toSRAM_1_ack, g16_toSRAM_1_selectedOH, g16_toSRAM_1_array, g16_toSRAM_2_addr, g16_toSRAM_2_addr_rd, g16_toSRAM_2_wdata, g16_toSRAM_2_wmask, g16_toSRAM_2_re, g16_toSRAM_2_we, g16_toSRAM_2_ack, g16_toSRAM_2_selectedOH, g16_toSRAM_2_array, g16_toSRAM_3_addr, g16_toSRAM_3_addr_rd, g16_toSRAM_3_wdata, g16_toSRAM_3_wmask, g16_toSRAM_3_re, g16_toSRAM_3_we, g16_toSRAM_3_ack, g16_toSRAM_3_selectedOH, g16_toSRAM_3_array, g16_toSRAM_4_addr, g16_toSRAM_4_addr_rd, g16_toSRAM_4_wdata, g16_toSRAM_4_wmask, g16_toSRAM_4_re, g16_toSRAM_4_we, g16_toSRAM_4_ack, g16_toSRAM_4_selectedOH, g16_toSRAM_4_array, g16_toSRAM_5_addr, g16_toSRAM_5_addr_rd, g16_toSRAM_5_wdata, g16_toSRAM_5_wmask, g16_toSRAM_5_re, g16_toSRAM_5_we, g16_toSRAM_5_ack, g16_toSRAM_5_selectedOH, g16_toSRAM_5_array, g16_toSRAM_6_addr, g16_toSRAM_6_addr_rd, g16_toSRAM_6_wdata, g16_toSRAM_6_wmask, g16_toSRAM_6_re, g16_toSRAM_6_we, g16_toSRAM_6_ack, g16_toSRAM_6_selectedOH, g16_toSRAM_6_array, g16_toSRAM_7_addr, g16_toSRAM_7_addr_rd, g16_toSRAM_7_wdata, g16_toSRAM_7_wmask, g16_toSRAM_7_re, g16_toSRAM_7_we, g16_toSRAM_7_ack, g16_toSRAM_7_selectedOH, g16_toSRAM_7_array, g16_toSRAM_8_addr, g16_toSRAM_8_addr_rd, g16_toSRAM_8_wdata, g16_toSRAM_8_wmask, g16_toSRAM_8_re, g16_toSRAM_8_we, g16_toSRAM_8_ack, g16_toSRAM_8_selectedOH, g16_toSRAM_8_array, g16_toSRAM_9_addr, g16_toSRAM_9_addr_rd, g16_toSRAM_9_wdata, g16_toSRAM_9_wmask, g16_toSRAM_9_re, g16_toSRAM_9_we, g16_toSRAM_9_ack, g16_toSRAM_9_selectedOH, g16_toSRAM_9_array, g16_toSRAM_10_addr, g16_toSRAM_10_addr_rd, g16_toSRAM_10_wdata, g16_toSRAM_10_wmask, g16_toSRAM_10_re, g16_toSRAM_10_we, g16_toSRAM_10_ack, g16_toSRAM_10_selectedOH, g16_toSRAM_10_array, g16_toSRAM_11_addr, g16_toSRAM_11_addr_rd, g16_toSRAM_11_wdata, g16_toSRAM_11_wmask, g16_toSRAM_11_re, g16_toSRAM_11_we, g16_toSRAM_11_ack, g16_toSRAM_11_selectedOH, g16_toSRAM_11_array, g16_toSRAM_12_addr, g16_toSRAM_12_addr_rd, g16_toSRAM_12_wdata, g16_toSRAM_12_wmask, g16_toSRAM_12_re, g16_toSRAM_12_we, g16_toSRAM_12_ack, g16_toSRAM_12_selectedOH, g16_toSRAM_12_array, g16_toSRAM_13_addr, g16_toSRAM_13_addr_rd, g16_toSRAM_13_wdata, g16_toSRAM_13_wmask, g16_toSRAM_13_re, g16_toSRAM_13_we, g16_toSRAM_13_ack, g16_toSRAM_13_selectedOH, g16_toSRAM_13_array, g16_toSRAM_14_addr, g16_toSRAM_14_addr_rd, g16_toSRAM_14_wdata, g16_toSRAM_14_wmask, g16_toSRAM_14_re, g16_toSRAM_14_we, g16_toSRAM_14_ack, g16_toSRAM_14_selectedOH, g16_toSRAM_14_array, g16_toSRAM_15_addr, g16_toSRAM_15_addr_rd, g16_toSRAM_15_wdata, g16_toSRAM_15_wmask, g16_toSRAM_15_re, g16_toSRAM_15_we, g16_toSRAM_15_ack, g16_toSRAM_15_selectedOH, g16_toSRAM_15_array};
  wire [2356:0] xbus16 = {x16_mbist_ack, x16_mbist_outdata, x16_toSRAM_0_addr, x16_toSRAM_0_addr_rd, x16_toSRAM_0_wdata, x16_toSRAM_0_wmask, x16_toSRAM_0_re, x16_toSRAM_0_we, x16_toSRAM_0_ack, x16_toSRAM_0_selectedOH, x16_toSRAM_0_array, x16_toSRAM_1_addr, x16_toSRAM_1_addr_rd, x16_toSRAM_1_wdata, x16_toSRAM_1_wmask, x16_toSRAM_1_re, x16_toSRAM_1_we, x16_toSRAM_1_ack, x16_toSRAM_1_selectedOH, x16_toSRAM_1_array, x16_toSRAM_2_addr, x16_toSRAM_2_addr_rd, x16_toSRAM_2_wdata, x16_toSRAM_2_wmask, x16_toSRAM_2_re, x16_toSRAM_2_we, x16_toSRAM_2_ack, x16_toSRAM_2_selectedOH, x16_toSRAM_2_array, x16_toSRAM_3_addr, x16_toSRAM_3_addr_rd, x16_toSRAM_3_wdata, x16_toSRAM_3_wmask, x16_toSRAM_3_re, x16_toSRAM_3_we, x16_toSRAM_3_ack, x16_toSRAM_3_selectedOH, x16_toSRAM_3_array, x16_toSRAM_4_addr, x16_toSRAM_4_addr_rd, x16_toSRAM_4_wdata, x16_toSRAM_4_wmask, x16_toSRAM_4_re, x16_toSRAM_4_we, x16_toSRAM_4_ack, x16_toSRAM_4_selectedOH, x16_toSRAM_4_array, x16_toSRAM_5_addr, x16_toSRAM_5_addr_rd, x16_toSRAM_5_wdata, x16_toSRAM_5_wmask, x16_toSRAM_5_re, x16_toSRAM_5_we, x16_toSRAM_5_ack, x16_toSRAM_5_selectedOH, x16_toSRAM_5_array, x16_toSRAM_6_addr, x16_toSRAM_6_addr_rd, x16_toSRAM_6_wdata, x16_toSRAM_6_wmask, x16_toSRAM_6_re, x16_toSRAM_6_we, x16_toSRAM_6_ack, x16_toSRAM_6_selectedOH, x16_toSRAM_6_array, x16_toSRAM_7_addr, x16_toSRAM_7_addr_rd, x16_toSRAM_7_wdata, x16_toSRAM_7_wmask, x16_toSRAM_7_re, x16_toSRAM_7_we, x16_toSRAM_7_ack, x16_toSRAM_7_selectedOH, x16_toSRAM_7_array, x16_toSRAM_8_addr, x16_toSRAM_8_addr_rd, x16_toSRAM_8_wdata, x16_toSRAM_8_wmask, x16_toSRAM_8_re, x16_toSRAM_8_we, x16_toSRAM_8_ack, x16_toSRAM_8_selectedOH, x16_toSRAM_8_array, x16_toSRAM_9_addr, x16_toSRAM_9_addr_rd, x16_toSRAM_9_wdata, x16_toSRAM_9_wmask, x16_toSRAM_9_re, x16_toSRAM_9_we, x16_toSRAM_9_ack, x16_toSRAM_9_selectedOH, x16_toSRAM_9_array, x16_toSRAM_10_addr, x16_toSRAM_10_addr_rd, x16_toSRAM_10_wdata, x16_toSRAM_10_wmask, x16_toSRAM_10_re, x16_toSRAM_10_we, x16_toSRAM_10_ack, x16_toSRAM_10_selectedOH, x16_toSRAM_10_array, x16_toSRAM_11_addr, x16_toSRAM_11_addr_rd, x16_toSRAM_11_wdata, x16_toSRAM_11_wmask, x16_toSRAM_11_re, x16_toSRAM_11_we, x16_toSRAM_11_ack, x16_toSRAM_11_selectedOH, x16_toSRAM_11_array, x16_toSRAM_12_addr, x16_toSRAM_12_addr_rd, x16_toSRAM_12_wdata, x16_toSRAM_12_wmask, x16_toSRAM_12_re, x16_toSRAM_12_we, x16_toSRAM_12_ack, x16_toSRAM_12_selectedOH, x16_toSRAM_12_array, x16_toSRAM_13_addr, x16_toSRAM_13_addr_rd, x16_toSRAM_13_wdata, x16_toSRAM_13_wmask, x16_toSRAM_13_re, x16_toSRAM_13_we, x16_toSRAM_13_ack, x16_toSRAM_13_selectedOH, x16_toSRAM_13_array, x16_toSRAM_14_addr, x16_toSRAM_14_addr_rd, x16_toSRAM_14_wdata, x16_toSRAM_14_wmask, x16_toSRAM_14_re, x16_toSRAM_14_we, x16_toSRAM_14_ack, x16_toSRAM_14_selectedOH, x16_toSRAM_14_array, x16_toSRAM_15_addr, x16_toSRAM_15_addr_rd, x16_toSRAM_15_wdata, x16_toSRAM_15_wmask, x16_toSRAM_15_re, x16_toSRAM_15_we, x16_toSRAM_15_ack, x16_toSRAM_15_selectedOH, x16_toSRAM_15_array};
  task automatic detail16();
    if (g16_mbist_ack !== x16_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.mbist_ack golden=%h impl=%h", cyc, g16_mbist_ack, x16_mbist_ack); end
    if (g16_mbist_outdata !== x16_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.mbist_outdata golden=%h impl=%h", cyc, g16_mbist_outdata, x16_mbist_outdata); end
    if (g16_toSRAM_0_addr !== x16_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_addr golden=%h impl=%h", cyc, g16_toSRAM_0_addr, x16_toSRAM_0_addr); end
    if (g16_toSRAM_0_addr_rd !== x16_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_0_addr_rd, x16_toSRAM_0_addr_rd); end
    if (g16_toSRAM_0_wdata !== x16_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_wdata golden=%h impl=%h", cyc, g16_toSRAM_0_wdata, x16_toSRAM_0_wdata); end
    if (g16_toSRAM_0_wmask !== x16_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_wmask golden=%h impl=%h", cyc, g16_toSRAM_0_wmask, x16_toSRAM_0_wmask); end
    if (g16_toSRAM_0_re !== x16_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_re golden=%h impl=%h", cyc, g16_toSRAM_0_re, x16_toSRAM_0_re); end
    if (g16_toSRAM_0_we !== x16_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_we golden=%h impl=%h", cyc, g16_toSRAM_0_we, x16_toSRAM_0_we); end
    if (g16_toSRAM_0_ack !== x16_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_ack golden=%h impl=%h", cyc, g16_toSRAM_0_ack, x16_toSRAM_0_ack); end
    if (g16_toSRAM_0_selectedOH !== x16_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_0_selectedOH, x16_toSRAM_0_selectedOH); end
    if (g16_toSRAM_0_array !== x16_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_0_array golden=%h impl=%h", cyc, g16_toSRAM_0_array, x16_toSRAM_0_array); end
    if (g16_toSRAM_1_addr !== x16_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_addr golden=%h impl=%h", cyc, g16_toSRAM_1_addr, x16_toSRAM_1_addr); end
    if (g16_toSRAM_1_addr_rd !== x16_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_1_addr_rd, x16_toSRAM_1_addr_rd); end
    if (g16_toSRAM_1_wdata !== x16_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_wdata golden=%h impl=%h", cyc, g16_toSRAM_1_wdata, x16_toSRAM_1_wdata); end
    if (g16_toSRAM_1_wmask !== x16_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_wmask golden=%h impl=%h", cyc, g16_toSRAM_1_wmask, x16_toSRAM_1_wmask); end
    if (g16_toSRAM_1_re !== x16_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_re golden=%h impl=%h", cyc, g16_toSRAM_1_re, x16_toSRAM_1_re); end
    if (g16_toSRAM_1_we !== x16_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_we golden=%h impl=%h", cyc, g16_toSRAM_1_we, x16_toSRAM_1_we); end
    if (g16_toSRAM_1_ack !== x16_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_ack golden=%h impl=%h", cyc, g16_toSRAM_1_ack, x16_toSRAM_1_ack); end
    if (g16_toSRAM_1_selectedOH !== x16_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_1_selectedOH, x16_toSRAM_1_selectedOH); end
    if (g16_toSRAM_1_array !== x16_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_1_array golden=%h impl=%h", cyc, g16_toSRAM_1_array, x16_toSRAM_1_array); end
    if (g16_toSRAM_2_addr !== x16_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_addr golden=%h impl=%h", cyc, g16_toSRAM_2_addr, x16_toSRAM_2_addr); end
    if (g16_toSRAM_2_addr_rd !== x16_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_2_addr_rd, x16_toSRAM_2_addr_rd); end
    if (g16_toSRAM_2_wdata !== x16_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_wdata golden=%h impl=%h", cyc, g16_toSRAM_2_wdata, x16_toSRAM_2_wdata); end
    if (g16_toSRAM_2_wmask !== x16_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_wmask golden=%h impl=%h", cyc, g16_toSRAM_2_wmask, x16_toSRAM_2_wmask); end
    if (g16_toSRAM_2_re !== x16_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_re golden=%h impl=%h", cyc, g16_toSRAM_2_re, x16_toSRAM_2_re); end
    if (g16_toSRAM_2_we !== x16_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_we golden=%h impl=%h", cyc, g16_toSRAM_2_we, x16_toSRAM_2_we); end
    if (g16_toSRAM_2_ack !== x16_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_ack golden=%h impl=%h", cyc, g16_toSRAM_2_ack, x16_toSRAM_2_ack); end
    if (g16_toSRAM_2_selectedOH !== x16_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_2_selectedOH, x16_toSRAM_2_selectedOH); end
    if (g16_toSRAM_2_array !== x16_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_2_array golden=%h impl=%h", cyc, g16_toSRAM_2_array, x16_toSRAM_2_array); end
    if (g16_toSRAM_3_addr !== x16_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_addr golden=%h impl=%h", cyc, g16_toSRAM_3_addr, x16_toSRAM_3_addr); end
    if (g16_toSRAM_3_addr_rd !== x16_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_3_addr_rd, x16_toSRAM_3_addr_rd); end
    if (g16_toSRAM_3_wdata !== x16_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_wdata golden=%h impl=%h", cyc, g16_toSRAM_3_wdata, x16_toSRAM_3_wdata); end
    if (g16_toSRAM_3_wmask !== x16_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_wmask golden=%h impl=%h", cyc, g16_toSRAM_3_wmask, x16_toSRAM_3_wmask); end
    if (g16_toSRAM_3_re !== x16_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_re golden=%h impl=%h", cyc, g16_toSRAM_3_re, x16_toSRAM_3_re); end
    if (g16_toSRAM_3_we !== x16_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_we golden=%h impl=%h", cyc, g16_toSRAM_3_we, x16_toSRAM_3_we); end
    if (g16_toSRAM_3_ack !== x16_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_ack golden=%h impl=%h", cyc, g16_toSRAM_3_ack, x16_toSRAM_3_ack); end
    if (g16_toSRAM_3_selectedOH !== x16_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_3_selectedOH, x16_toSRAM_3_selectedOH); end
    if (g16_toSRAM_3_array !== x16_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_3_array golden=%h impl=%h", cyc, g16_toSRAM_3_array, x16_toSRAM_3_array); end
    if (g16_toSRAM_4_addr !== x16_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_addr golden=%h impl=%h", cyc, g16_toSRAM_4_addr, x16_toSRAM_4_addr); end
    if (g16_toSRAM_4_addr_rd !== x16_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_4_addr_rd, x16_toSRAM_4_addr_rd); end
    if (g16_toSRAM_4_wdata !== x16_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_wdata golden=%h impl=%h", cyc, g16_toSRAM_4_wdata, x16_toSRAM_4_wdata); end
    if (g16_toSRAM_4_wmask !== x16_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_wmask golden=%h impl=%h", cyc, g16_toSRAM_4_wmask, x16_toSRAM_4_wmask); end
    if (g16_toSRAM_4_re !== x16_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_re golden=%h impl=%h", cyc, g16_toSRAM_4_re, x16_toSRAM_4_re); end
    if (g16_toSRAM_4_we !== x16_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_we golden=%h impl=%h", cyc, g16_toSRAM_4_we, x16_toSRAM_4_we); end
    if (g16_toSRAM_4_ack !== x16_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_ack golden=%h impl=%h", cyc, g16_toSRAM_4_ack, x16_toSRAM_4_ack); end
    if (g16_toSRAM_4_selectedOH !== x16_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_4_selectedOH, x16_toSRAM_4_selectedOH); end
    if (g16_toSRAM_4_array !== x16_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_4_array golden=%h impl=%h", cyc, g16_toSRAM_4_array, x16_toSRAM_4_array); end
    if (g16_toSRAM_5_addr !== x16_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_addr golden=%h impl=%h", cyc, g16_toSRAM_5_addr, x16_toSRAM_5_addr); end
    if (g16_toSRAM_5_addr_rd !== x16_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_5_addr_rd, x16_toSRAM_5_addr_rd); end
    if (g16_toSRAM_5_wdata !== x16_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_wdata golden=%h impl=%h", cyc, g16_toSRAM_5_wdata, x16_toSRAM_5_wdata); end
    if (g16_toSRAM_5_wmask !== x16_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_wmask golden=%h impl=%h", cyc, g16_toSRAM_5_wmask, x16_toSRAM_5_wmask); end
    if (g16_toSRAM_5_re !== x16_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_re golden=%h impl=%h", cyc, g16_toSRAM_5_re, x16_toSRAM_5_re); end
    if (g16_toSRAM_5_we !== x16_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_we golden=%h impl=%h", cyc, g16_toSRAM_5_we, x16_toSRAM_5_we); end
    if (g16_toSRAM_5_ack !== x16_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_ack golden=%h impl=%h", cyc, g16_toSRAM_5_ack, x16_toSRAM_5_ack); end
    if (g16_toSRAM_5_selectedOH !== x16_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_5_selectedOH, x16_toSRAM_5_selectedOH); end
    if (g16_toSRAM_5_array !== x16_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_5_array golden=%h impl=%h", cyc, g16_toSRAM_5_array, x16_toSRAM_5_array); end
    if (g16_toSRAM_6_addr !== x16_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_addr golden=%h impl=%h", cyc, g16_toSRAM_6_addr, x16_toSRAM_6_addr); end
    if (g16_toSRAM_6_addr_rd !== x16_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_6_addr_rd, x16_toSRAM_6_addr_rd); end
    if (g16_toSRAM_6_wdata !== x16_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_wdata golden=%h impl=%h", cyc, g16_toSRAM_6_wdata, x16_toSRAM_6_wdata); end
    if (g16_toSRAM_6_wmask !== x16_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_wmask golden=%h impl=%h", cyc, g16_toSRAM_6_wmask, x16_toSRAM_6_wmask); end
    if (g16_toSRAM_6_re !== x16_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_re golden=%h impl=%h", cyc, g16_toSRAM_6_re, x16_toSRAM_6_re); end
    if (g16_toSRAM_6_we !== x16_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_we golden=%h impl=%h", cyc, g16_toSRAM_6_we, x16_toSRAM_6_we); end
    if (g16_toSRAM_6_ack !== x16_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_ack golden=%h impl=%h", cyc, g16_toSRAM_6_ack, x16_toSRAM_6_ack); end
    if (g16_toSRAM_6_selectedOH !== x16_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_6_selectedOH, x16_toSRAM_6_selectedOH); end
    if (g16_toSRAM_6_array !== x16_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_6_array golden=%h impl=%h", cyc, g16_toSRAM_6_array, x16_toSRAM_6_array); end
    if (g16_toSRAM_7_addr !== x16_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_addr golden=%h impl=%h", cyc, g16_toSRAM_7_addr, x16_toSRAM_7_addr); end
    if (g16_toSRAM_7_addr_rd !== x16_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_7_addr_rd, x16_toSRAM_7_addr_rd); end
    if (g16_toSRAM_7_wdata !== x16_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_wdata golden=%h impl=%h", cyc, g16_toSRAM_7_wdata, x16_toSRAM_7_wdata); end
    if (g16_toSRAM_7_wmask !== x16_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_wmask golden=%h impl=%h", cyc, g16_toSRAM_7_wmask, x16_toSRAM_7_wmask); end
    if (g16_toSRAM_7_re !== x16_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_re golden=%h impl=%h", cyc, g16_toSRAM_7_re, x16_toSRAM_7_re); end
    if (g16_toSRAM_7_we !== x16_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_we golden=%h impl=%h", cyc, g16_toSRAM_7_we, x16_toSRAM_7_we); end
    if (g16_toSRAM_7_ack !== x16_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_ack golden=%h impl=%h", cyc, g16_toSRAM_7_ack, x16_toSRAM_7_ack); end
    if (g16_toSRAM_7_selectedOH !== x16_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_7_selectedOH, x16_toSRAM_7_selectedOH); end
    if (g16_toSRAM_7_array !== x16_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_7_array golden=%h impl=%h", cyc, g16_toSRAM_7_array, x16_toSRAM_7_array); end
    if (g16_toSRAM_8_addr !== x16_toSRAM_8_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_addr golden=%h impl=%h", cyc, g16_toSRAM_8_addr, x16_toSRAM_8_addr); end
    if (g16_toSRAM_8_addr_rd !== x16_toSRAM_8_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_8_addr_rd, x16_toSRAM_8_addr_rd); end
    if (g16_toSRAM_8_wdata !== x16_toSRAM_8_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_wdata golden=%h impl=%h", cyc, g16_toSRAM_8_wdata, x16_toSRAM_8_wdata); end
    if (g16_toSRAM_8_wmask !== x16_toSRAM_8_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_wmask golden=%h impl=%h", cyc, g16_toSRAM_8_wmask, x16_toSRAM_8_wmask); end
    if (g16_toSRAM_8_re !== x16_toSRAM_8_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_re golden=%h impl=%h", cyc, g16_toSRAM_8_re, x16_toSRAM_8_re); end
    if (g16_toSRAM_8_we !== x16_toSRAM_8_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_we golden=%h impl=%h", cyc, g16_toSRAM_8_we, x16_toSRAM_8_we); end
    if (g16_toSRAM_8_ack !== x16_toSRAM_8_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_ack golden=%h impl=%h", cyc, g16_toSRAM_8_ack, x16_toSRAM_8_ack); end
    if (g16_toSRAM_8_selectedOH !== x16_toSRAM_8_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_8_selectedOH, x16_toSRAM_8_selectedOH); end
    if (g16_toSRAM_8_array !== x16_toSRAM_8_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_8_array golden=%h impl=%h", cyc, g16_toSRAM_8_array, x16_toSRAM_8_array); end
    if (g16_toSRAM_9_addr !== x16_toSRAM_9_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_addr golden=%h impl=%h", cyc, g16_toSRAM_9_addr, x16_toSRAM_9_addr); end
    if (g16_toSRAM_9_addr_rd !== x16_toSRAM_9_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_9_addr_rd, x16_toSRAM_9_addr_rd); end
    if (g16_toSRAM_9_wdata !== x16_toSRAM_9_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_wdata golden=%h impl=%h", cyc, g16_toSRAM_9_wdata, x16_toSRAM_9_wdata); end
    if (g16_toSRAM_9_wmask !== x16_toSRAM_9_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_wmask golden=%h impl=%h", cyc, g16_toSRAM_9_wmask, x16_toSRAM_9_wmask); end
    if (g16_toSRAM_9_re !== x16_toSRAM_9_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_re golden=%h impl=%h", cyc, g16_toSRAM_9_re, x16_toSRAM_9_re); end
    if (g16_toSRAM_9_we !== x16_toSRAM_9_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_we golden=%h impl=%h", cyc, g16_toSRAM_9_we, x16_toSRAM_9_we); end
    if (g16_toSRAM_9_ack !== x16_toSRAM_9_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_ack golden=%h impl=%h", cyc, g16_toSRAM_9_ack, x16_toSRAM_9_ack); end
    if (g16_toSRAM_9_selectedOH !== x16_toSRAM_9_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_9_selectedOH, x16_toSRAM_9_selectedOH); end
    if (g16_toSRAM_9_array !== x16_toSRAM_9_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_9_array golden=%h impl=%h", cyc, g16_toSRAM_9_array, x16_toSRAM_9_array); end
    if (g16_toSRAM_10_addr !== x16_toSRAM_10_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_addr golden=%h impl=%h", cyc, g16_toSRAM_10_addr, x16_toSRAM_10_addr); end
    if (g16_toSRAM_10_addr_rd !== x16_toSRAM_10_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_10_addr_rd, x16_toSRAM_10_addr_rd); end
    if (g16_toSRAM_10_wdata !== x16_toSRAM_10_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_wdata golden=%h impl=%h", cyc, g16_toSRAM_10_wdata, x16_toSRAM_10_wdata); end
    if (g16_toSRAM_10_wmask !== x16_toSRAM_10_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_wmask golden=%h impl=%h", cyc, g16_toSRAM_10_wmask, x16_toSRAM_10_wmask); end
    if (g16_toSRAM_10_re !== x16_toSRAM_10_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_re golden=%h impl=%h", cyc, g16_toSRAM_10_re, x16_toSRAM_10_re); end
    if (g16_toSRAM_10_we !== x16_toSRAM_10_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_we golden=%h impl=%h", cyc, g16_toSRAM_10_we, x16_toSRAM_10_we); end
    if (g16_toSRAM_10_ack !== x16_toSRAM_10_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_ack golden=%h impl=%h", cyc, g16_toSRAM_10_ack, x16_toSRAM_10_ack); end
    if (g16_toSRAM_10_selectedOH !== x16_toSRAM_10_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_10_selectedOH, x16_toSRAM_10_selectedOH); end
    if (g16_toSRAM_10_array !== x16_toSRAM_10_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_10_array golden=%h impl=%h", cyc, g16_toSRAM_10_array, x16_toSRAM_10_array); end
    if (g16_toSRAM_11_addr !== x16_toSRAM_11_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_addr golden=%h impl=%h", cyc, g16_toSRAM_11_addr, x16_toSRAM_11_addr); end
    if (g16_toSRAM_11_addr_rd !== x16_toSRAM_11_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_11_addr_rd, x16_toSRAM_11_addr_rd); end
    if (g16_toSRAM_11_wdata !== x16_toSRAM_11_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_wdata golden=%h impl=%h", cyc, g16_toSRAM_11_wdata, x16_toSRAM_11_wdata); end
    if (g16_toSRAM_11_wmask !== x16_toSRAM_11_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_wmask golden=%h impl=%h", cyc, g16_toSRAM_11_wmask, x16_toSRAM_11_wmask); end
    if (g16_toSRAM_11_re !== x16_toSRAM_11_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_re golden=%h impl=%h", cyc, g16_toSRAM_11_re, x16_toSRAM_11_re); end
    if (g16_toSRAM_11_we !== x16_toSRAM_11_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_we golden=%h impl=%h", cyc, g16_toSRAM_11_we, x16_toSRAM_11_we); end
    if (g16_toSRAM_11_ack !== x16_toSRAM_11_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_ack golden=%h impl=%h", cyc, g16_toSRAM_11_ack, x16_toSRAM_11_ack); end
    if (g16_toSRAM_11_selectedOH !== x16_toSRAM_11_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_11_selectedOH, x16_toSRAM_11_selectedOH); end
    if (g16_toSRAM_11_array !== x16_toSRAM_11_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_11_array golden=%h impl=%h", cyc, g16_toSRAM_11_array, x16_toSRAM_11_array); end
    if (g16_toSRAM_12_addr !== x16_toSRAM_12_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_addr golden=%h impl=%h", cyc, g16_toSRAM_12_addr, x16_toSRAM_12_addr); end
    if (g16_toSRAM_12_addr_rd !== x16_toSRAM_12_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_12_addr_rd, x16_toSRAM_12_addr_rd); end
    if (g16_toSRAM_12_wdata !== x16_toSRAM_12_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_wdata golden=%h impl=%h", cyc, g16_toSRAM_12_wdata, x16_toSRAM_12_wdata); end
    if (g16_toSRAM_12_wmask !== x16_toSRAM_12_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_wmask golden=%h impl=%h", cyc, g16_toSRAM_12_wmask, x16_toSRAM_12_wmask); end
    if (g16_toSRAM_12_re !== x16_toSRAM_12_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_re golden=%h impl=%h", cyc, g16_toSRAM_12_re, x16_toSRAM_12_re); end
    if (g16_toSRAM_12_we !== x16_toSRAM_12_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_we golden=%h impl=%h", cyc, g16_toSRAM_12_we, x16_toSRAM_12_we); end
    if (g16_toSRAM_12_ack !== x16_toSRAM_12_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_ack golden=%h impl=%h", cyc, g16_toSRAM_12_ack, x16_toSRAM_12_ack); end
    if (g16_toSRAM_12_selectedOH !== x16_toSRAM_12_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_12_selectedOH, x16_toSRAM_12_selectedOH); end
    if (g16_toSRAM_12_array !== x16_toSRAM_12_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_12_array golden=%h impl=%h", cyc, g16_toSRAM_12_array, x16_toSRAM_12_array); end
    if (g16_toSRAM_13_addr !== x16_toSRAM_13_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_addr golden=%h impl=%h", cyc, g16_toSRAM_13_addr, x16_toSRAM_13_addr); end
    if (g16_toSRAM_13_addr_rd !== x16_toSRAM_13_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_13_addr_rd, x16_toSRAM_13_addr_rd); end
    if (g16_toSRAM_13_wdata !== x16_toSRAM_13_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_wdata golden=%h impl=%h", cyc, g16_toSRAM_13_wdata, x16_toSRAM_13_wdata); end
    if (g16_toSRAM_13_wmask !== x16_toSRAM_13_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_wmask golden=%h impl=%h", cyc, g16_toSRAM_13_wmask, x16_toSRAM_13_wmask); end
    if (g16_toSRAM_13_re !== x16_toSRAM_13_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_re golden=%h impl=%h", cyc, g16_toSRAM_13_re, x16_toSRAM_13_re); end
    if (g16_toSRAM_13_we !== x16_toSRAM_13_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_we golden=%h impl=%h", cyc, g16_toSRAM_13_we, x16_toSRAM_13_we); end
    if (g16_toSRAM_13_ack !== x16_toSRAM_13_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_ack golden=%h impl=%h", cyc, g16_toSRAM_13_ack, x16_toSRAM_13_ack); end
    if (g16_toSRAM_13_selectedOH !== x16_toSRAM_13_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_13_selectedOH, x16_toSRAM_13_selectedOH); end
    if (g16_toSRAM_13_array !== x16_toSRAM_13_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_13_array golden=%h impl=%h", cyc, g16_toSRAM_13_array, x16_toSRAM_13_array); end
    if (g16_toSRAM_14_addr !== x16_toSRAM_14_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_addr golden=%h impl=%h", cyc, g16_toSRAM_14_addr, x16_toSRAM_14_addr); end
    if (g16_toSRAM_14_addr_rd !== x16_toSRAM_14_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_14_addr_rd, x16_toSRAM_14_addr_rd); end
    if (g16_toSRAM_14_wdata !== x16_toSRAM_14_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_wdata golden=%h impl=%h", cyc, g16_toSRAM_14_wdata, x16_toSRAM_14_wdata); end
    if (g16_toSRAM_14_wmask !== x16_toSRAM_14_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_wmask golden=%h impl=%h", cyc, g16_toSRAM_14_wmask, x16_toSRAM_14_wmask); end
    if (g16_toSRAM_14_re !== x16_toSRAM_14_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_re golden=%h impl=%h", cyc, g16_toSRAM_14_re, x16_toSRAM_14_re); end
    if (g16_toSRAM_14_we !== x16_toSRAM_14_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_we golden=%h impl=%h", cyc, g16_toSRAM_14_we, x16_toSRAM_14_we); end
    if (g16_toSRAM_14_ack !== x16_toSRAM_14_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_ack golden=%h impl=%h", cyc, g16_toSRAM_14_ack, x16_toSRAM_14_ack); end
    if (g16_toSRAM_14_selectedOH !== x16_toSRAM_14_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_14_selectedOH, x16_toSRAM_14_selectedOH); end
    if (g16_toSRAM_14_array !== x16_toSRAM_14_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_14_array golden=%h impl=%h", cyc, g16_toSRAM_14_array, x16_toSRAM_14_array); end
    if (g16_toSRAM_15_addr !== x16_toSRAM_15_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_addr golden=%h impl=%h", cyc, g16_toSRAM_15_addr, x16_toSRAM_15_addr); end
    if (g16_toSRAM_15_addr_rd !== x16_toSRAM_15_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_addr_rd golden=%h impl=%h", cyc, g16_toSRAM_15_addr_rd, x16_toSRAM_15_addr_rd); end
    if (g16_toSRAM_15_wdata !== x16_toSRAM_15_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_wdata golden=%h impl=%h", cyc, g16_toSRAM_15_wdata, x16_toSRAM_15_wdata); end
    if (g16_toSRAM_15_wmask !== x16_toSRAM_15_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_wmask golden=%h impl=%h", cyc, g16_toSRAM_15_wmask, x16_toSRAM_15_wmask); end
    if (g16_toSRAM_15_re !== x16_toSRAM_15_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_re golden=%h impl=%h", cyc, g16_toSRAM_15_re, x16_toSRAM_15_re); end
    if (g16_toSRAM_15_we !== x16_toSRAM_15_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_we golden=%h impl=%h", cyc, g16_toSRAM_15_we, x16_toSRAM_15_we); end
    if (g16_toSRAM_15_ack !== x16_toSRAM_15_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_ack golden=%h impl=%h", cyc, g16_toSRAM_15_ack, x16_toSRAM_15_ack); end
    if (g16_toSRAM_15_selectedOH !== x16_toSRAM_15_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_selectedOH golden=%h impl=%h", cyc, g16_toSRAM_15_selectedOH, x16_toSRAM_15_selectedOH); end
    if (g16_toSRAM_15_array !== x16_toSRAM_15_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL0.toSRAM_15_array golden=%h impl=%h", cyc, g16_toSRAM_15_array, x16_toSRAM_15_array); end
  endtask

  // ======================== [17] MbistPipePtwL1 ========================
  logic [130:0] v17_rd0;
  logic g17_mbist_ack;
  logic [130:0] g17_mbist_outdata;
  logic [2:0] g17_toSRAM_0_addr;
  logic [2:0] g17_toSRAM_0_addr_rd;
  logic [130:0] g17_toSRAM_0_wdata;
  logic g17_toSRAM_0_wmask;
  logic g17_toSRAM_0_re;
  logic g17_toSRAM_0_we;
  logic g17_toSRAM_0_ack;
  logic [5:0] g17_toSRAM_0_selectedOH;
  logic [5:0] g17_toSRAM_0_array;
  logic x17_mbist_ack;
  logic [130:0] x17_mbist_outdata;
  logic [2:0] x17_toSRAM_0_addr;
  logic [2:0] x17_toSRAM_0_addr_rd;
  logic [130:0] x17_toSRAM_0_wdata;
  logic x17_toSRAM_0_wmask;
  logic x17_toSRAM_0_re;
  logic x17_toSRAM_0_we;
  logic x17_toSRAM_0_ack;
  logic [5:0] x17_toSRAM_0_selectedOH;
  logic [5:0] x17_toSRAM_0_array;
  bit [0:0] cov_spread17;
  bit [130:0] cov_od0_17, cov_od1_17;
  bit cov_ack0_17, cov_ack1_17;
  MbistPipePtwL1 u_g17 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[2:0]),
    .mbist_indata (s_indata[130:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[2:0]),
    .toSRAM_0_rdata (v17_rd0),
    .mbist_ack (g17_mbist_ack),
    .mbist_outdata (g17_mbist_outdata),
    .toSRAM_0_addr (g17_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g17_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g17_toSRAM_0_wdata),
    .toSRAM_0_wmask (g17_toSRAM_0_wmask),
    .toSRAM_0_re (g17_toSRAM_0_re),
    .toSRAM_0_we (g17_toSRAM_0_we),
    .toSRAM_0_ack (g17_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g17_toSRAM_0_selectedOH),
    .toSRAM_0_array (g17_toSRAM_0_array)
  );
  MbistPipePtwL1_xs u_x17 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array[5:0]),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[0:0]),
    .mbist_addr (s_addr[2:0]),
    .mbist_indata (s_indata[130:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[2:0]),
    .toSRAM_0_rdata (v17_rd0),
    .mbist_ack (x17_mbist_ack),
    .mbist_outdata (x17_mbist_outdata),
    .toSRAM_0_addr (x17_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x17_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x17_toSRAM_0_wdata),
    .toSRAM_0_wmask (x17_toSRAM_0_wmask),
    .toSRAM_0_re (x17_toSRAM_0_re),
    .toSRAM_0_we (x17_toSRAM_0_we),
    .toSRAM_0_ack (x17_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x17_toSRAM_0_selectedOH),
    .toSRAM_0_array (x17_toSRAM_0_array)
  );
  wire [284:0] gbus17 = {g17_mbist_ack, g17_mbist_outdata, g17_toSRAM_0_addr, g17_toSRAM_0_addr_rd, g17_toSRAM_0_wdata, g17_toSRAM_0_wmask, g17_toSRAM_0_re, g17_toSRAM_0_we, g17_toSRAM_0_ack, g17_toSRAM_0_selectedOH, g17_toSRAM_0_array};
  wire [284:0] xbus17 = {x17_mbist_ack, x17_mbist_outdata, x17_toSRAM_0_addr, x17_toSRAM_0_addr_rd, x17_toSRAM_0_wdata, x17_toSRAM_0_wmask, x17_toSRAM_0_re, x17_toSRAM_0_we, x17_toSRAM_0_ack, x17_toSRAM_0_selectedOH, x17_toSRAM_0_array};
  task automatic detail17();
    if (g17_mbist_ack !== x17_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.mbist_ack golden=%h impl=%h", cyc, g17_mbist_ack, x17_mbist_ack); end
    if (g17_mbist_outdata !== x17_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.mbist_outdata golden=%h impl=%h", cyc, g17_mbist_outdata, x17_mbist_outdata); end
    if (g17_toSRAM_0_addr !== x17_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_addr golden=%h impl=%h", cyc, g17_toSRAM_0_addr, x17_toSRAM_0_addr); end
    if (g17_toSRAM_0_addr_rd !== x17_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g17_toSRAM_0_addr_rd, x17_toSRAM_0_addr_rd); end
    if (g17_toSRAM_0_wdata !== x17_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_wdata golden=%h impl=%h", cyc, g17_toSRAM_0_wdata, x17_toSRAM_0_wdata); end
    if (g17_toSRAM_0_wmask !== x17_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_wmask golden=%h impl=%h", cyc, g17_toSRAM_0_wmask, x17_toSRAM_0_wmask); end
    if (g17_toSRAM_0_re !== x17_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_re golden=%h impl=%h", cyc, g17_toSRAM_0_re, x17_toSRAM_0_re); end
    if (g17_toSRAM_0_we !== x17_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_we golden=%h impl=%h", cyc, g17_toSRAM_0_we, x17_toSRAM_0_we); end
    if (g17_toSRAM_0_ack !== x17_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_ack golden=%h impl=%h", cyc, g17_toSRAM_0_ack, x17_toSRAM_0_ack); end
    if (g17_toSRAM_0_selectedOH !== x17_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g17_toSRAM_0_selectedOH, x17_toSRAM_0_selectedOH); end
    if (g17_toSRAM_0_array !== x17_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipePtwL1.toSRAM_0_array golden=%h impl=%h", cyc, g17_toSRAM_0_array, x17_toSRAM_0_array); end
  endtask

  // ======================== [18] MbistPipeSc ========================
  logic [23:0] v18_rd0;
  logic [23:0] v18_rd1;
  logic g18_mbist_ack;
  logic [23:0] g18_mbist_outdata;
  logic [7:0] g18_toSRAM_0_addr;
  logic [7:0] g18_toSRAM_0_addr_rd;
  logic [23:0] g18_toSRAM_0_wdata;
  logic [3:0] g18_toSRAM_0_wmask;
  logic g18_toSRAM_0_re;
  logic g18_toSRAM_0_we;
  logic g18_toSRAM_0_ack;
  logic g18_toSRAM_0_selectedOH;
  logic [6:0] g18_toSRAM_0_array;
  logic [7:0] g18_toSRAM_1_addr;
  logic [7:0] g18_toSRAM_1_addr_rd;
  logic [23:0] g18_toSRAM_1_wdata;
  logic [3:0] g18_toSRAM_1_wmask;
  logic g18_toSRAM_1_re;
  logic g18_toSRAM_1_we;
  logic g18_toSRAM_1_ack;
  logic g18_toSRAM_1_selectedOH;
  logic [6:0] g18_toSRAM_1_array;
  logic x18_mbist_ack;
  logic [23:0] x18_mbist_outdata;
  logic [7:0] x18_toSRAM_0_addr;
  logic [7:0] x18_toSRAM_0_addr_rd;
  logic [23:0] x18_toSRAM_0_wdata;
  logic [3:0] x18_toSRAM_0_wmask;
  logic x18_toSRAM_0_re;
  logic x18_toSRAM_0_we;
  logic x18_toSRAM_0_ack;
  logic x18_toSRAM_0_selectedOH;
  logic [6:0] x18_toSRAM_0_array;
  logic [7:0] x18_toSRAM_1_addr;
  logic [7:0] x18_toSRAM_1_addr_rd;
  logic [23:0] x18_toSRAM_1_wdata;
  logic [3:0] x18_toSRAM_1_wmask;
  logic x18_toSRAM_1_re;
  logic x18_toSRAM_1_we;
  logic x18_toSRAM_1_ack;
  logic x18_toSRAM_1_selectedOH;
  logic [6:0] x18_toSRAM_1_array;
  bit [1:0] cov_spread18;
  bit [23:0] cov_od0_18, cov_od1_18;
  bit cov_ack0_18, cov_ack1_18;
  MbistPipeSc u_g18 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v18_rd0),
    .toSRAM_1_rdata (v18_rd1),
    .mbist_ack (g18_mbist_ack),
    .mbist_outdata (g18_mbist_outdata),
    .toSRAM_0_addr (g18_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g18_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g18_toSRAM_0_wdata),
    .toSRAM_0_wmask (g18_toSRAM_0_wmask),
    .toSRAM_0_re (g18_toSRAM_0_re),
    .toSRAM_0_we (g18_toSRAM_0_we),
    .toSRAM_0_ack (g18_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g18_toSRAM_0_selectedOH),
    .toSRAM_0_array (g18_toSRAM_0_array),
    .toSRAM_1_addr (g18_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g18_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g18_toSRAM_1_wdata),
    .toSRAM_1_wmask (g18_toSRAM_1_wmask),
    .toSRAM_1_re (g18_toSRAM_1_re),
    .toSRAM_1_we (g18_toSRAM_1_we),
    .toSRAM_1_ack (g18_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g18_toSRAM_1_selectedOH),
    .toSRAM_1_array (g18_toSRAM_1_array)
  );
  MbistPipeSc_xs u_x18 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v18_rd0),
    .toSRAM_1_rdata (v18_rd1),
    .mbist_ack (x18_mbist_ack),
    .mbist_outdata (x18_mbist_outdata),
    .toSRAM_0_addr (x18_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x18_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x18_toSRAM_0_wdata),
    .toSRAM_0_wmask (x18_toSRAM_0_wmask),
    .toSRAM_0_re (x18_toSRAM_0_re),
    .toSRAM_0_we (x18_toSRAM_0_we),
    .toSRAM_0_ack (x18_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x18_toSRAM_0_selectedOH),
    .toSRAM_0_array (x18_toSRAM_0_array),
    .toSRAM_1_addr (x18_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x18_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x18_toSRAM_1_wdata),
    .toSRAM_1_wmask (x18_toSRAM_1_wmask),
    .toSRAM_1_re (x18_toSRAM_1_re),
    .toSRAM_1_we (x18_toSRAM_1_we),
    .toSRAM_1_ack (x18_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x18_toSRAM_1_selectedOH),
    .toSRAM_1_array (x18_toSRAM_1_array)
  );
  wire [134:0] gbus18 = {g18_mbist_ack, g18_mbist_outdata, g18_toSRAM_0_addr, g18_toSRAM_0_addr_rd, g18_toSRAM_0_wdata, g18_toSRAM_0_wmask, g18_toSRAM_0_re, g18_toSRAM_0_we, g18_toSRAM_0_ack, g18_toSRAM_0_selectedOH, g18_toSRAM_0_array, g18_toSRAM_1_addr, g18_toSRAM_1_addr_rd, g18_toSRAM_1_wdata, g18_toSRAM_1_wmask, g18_toSRAM_1_re, g18_toSRAM_1_we, g18_toSRAM_1_ack, g18_toSRAM_1_selectedOH, g18_toSRAM_1_array};
  wire [134:0] xbus18 = {x18_mbist_ack, x18_mbist_outdata, x18_toSRAM_0_addr, x18_toSRAM_0_addr_rd, x18_toSRAM_0_wdata, x18_toSRAM_0_wmask, x18_toSRAM_0_re, x18_toSRAM_0_we, x18_toSRAM_0_ack, x18_toSRAM_0_selectedOH, x18_toSRAM_0_array, x18_toSRAM_1_addr, x18_toSRAM_1_addr_rd, x18_toSRAM_1_wdata, x18_toSRAM_1_wmask, x18_toSRAM_1_re, x18_toSRAM_1_we, x18_toSRAM_1_ack, x18_toSRAM_1_selectedOH, x18_toSRAM_1_array};
  task automatic detail18();
    if (g18_mbist_ack !== x18_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.mbist_ack golden=%h impl=%h", cyc, g18_mbist_ack, x18_mbist_ack); end
    if (g18_mbist_outdata !== x18_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.mbist_outdata golden=%h impl=%h", cyc, g18_mbist_outdata, x18_mbist_outdata); end
    if (g18_toSRAM_0_addr !== x18_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_addr golden=%h impl=%h", cyc, g18_toSRAM_0_addr, x18_toSRAM_0_addr); end
    if (g18_toSRAM_0_addr_rd !== x18_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g18_toSRAM_0_addr_rd, x18_toSRAM_0_addr_rd); end
    if (g18_toSRAM_0_wdata !== x18_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_wdata golden=%h impl=%h", cyc, g18_toSRAM_0_wdata, x18_toSRAM_0_wdata); end
    if (g18_toSRAM_0_wmask !== x18_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_wmask golden=%h impl=%h", cyc, g18_toSRAM_0_wmask, x18_toSRAM_0_wmask); end
    if (g18_toSRAM_0_re !== x18_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_re golden=%h impl=%h", cyc, g18_toSRAM_0_re, x18_toSRAM_0_re); end
    if (g18_toSRAM_0_we !== x18_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_we golden=%h impl=%h", cyc, g18_toSRAM_0_we, x18_toSRAM_0_we); end
    if (g18_toSRAM_0_ack !== x18_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_ack golden=%h impl=%h", cyc, g18_toSRAM_0_ack, x18_toSRAM_0_ack); end
    if (g18_toSRAM_0_selectedOH !== x18_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g18_toSRAM_0_selectedOH, x18_toSRAM_0_selectedOH); end
    if (g18_toSRAM_0_array !== x18_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_0_array golden=%h impl=%h", cyc, g18_toSRAM_0_array, x18_toSRAM_0_array); end
    if (g18_toSRAM_1_addr !== x18_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_addr golden=%h impl=%h", cyc, g18_toSRAM_1_addr, x18_toSRAM_1_addr); end
    if (g18_toSRAM_1_addr_rd !== x18_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g18_toSRAM_1_addr_rd, x18_toSRAM_1_addr_rd); end
    if (g18_toSRAM_1_wdata !== x18_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_wdata golden=%h impl=%h", cyc, g18_toSRAM_1_wdata, x18_toSRAM_1_wdata); end
    if (g18_toSRAM_1_wmask !== x18_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_wmask golden=%h impl=%h", cyc, g18_toSRAM_1_wmask, x18_toSRAM_1_wmask); end
    if (g18_toSRAM_1_re !== x18_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_re golden=%h impl=%h", cyc, g18_toSRAM_1_re, x18_toSRAM_1_re); end
    if (g18_toSRAM_1_we !== x18_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_we golden=%h impl=%h", cyc, g18_toSRAM_1_we, x18_toSRAM_1_we); end
    if (g18_toSRAM_1_ack !== x18_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_ack golden=%h impl=%h", cyc, g18_toSRAM_1_ack, x18_toSRAM_1_ack); end
    if (g18_toSRAM_1_selectedOH !== x18_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g18_toSRAM_1_selectedOH, x18_toSRAM_1_selectedOH); end
    if (g18_toSRAM_1_array !== x18_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc.toSRAM_1_array golden=%h impl=%h", cyc, g18_toSRAM_1_array, x18_toSRAM_1_array); end
  endtask

  // ======================== [19] MbistPipeSc_1 ========================
  logic [23:0] v19_rd0;
  logic [23:0] v19_rd1;
  logic g19_mbist_ack;
  logic [23:0] g19_mbist_outdata;
  logic [7:0] g19_toSRAM_0_addr;
  logic [7:0] g19_toSRAM_0_addr_rd;
  logic [23:0] g19_toSRAM_0_wdata;
  logic [3:0] g19_toSRAM_0_wmask;
  logic g19_toSRAM_0_re;
  logic g19_toSRAM_0_we;
  logic g19_toSRAM_0_ack;
  logic g19_toSRAM_0_selectedOH;
  logic [6:0] g19_toSRAM_0_array;
  logic [7:0] g19_toSRAM_1_addr;
  logic [7:0] g19_toSRAM_1_addr_rd;
  logic [23:0] g19_toSRAM_1_wdata;
  logic [3:0] g19_toSRAM_1_wmask;
  logic g19_toSRAM_1_re;
  logic g19_toSRAM_1_we;
  logic g19_toSRAM_1_ack;
  logic g19_toSRAM_1_selectedOH;
  logic [6:0] g19_toSRAM_1_array;
  logic x19_mbist_ack;
  logic [23:0] x19_mbist_outdata;
  logic [7:0] x19_toSRAM_0_addr;
  logic [7:0] x19_toSRAM_0_addr_rd;
  logic [23:0] x19_toSRAM_0_wdata;
  logic [3:0] x19_toSRAM_0_wmask;
  logic x19_toSRAM_0_re;
  logic x19_toSRAM_0_we;
  logic x19_toSRAM_0_ack;
  logic x19_toSRAM_0_selectedOH;
  logic [6:0] x19_toSRAM_0_array;
  logic [7:0] x19_toSRAM_1_addr;
  logic [7:0] x19_toSRAM_1_addr_rd;
  logic [23:0] x19_toSRAM_1_wdata;
  logic [3:0] x19_toSRAM_1_wmask;
  logic x19_toSRAM_1_re;
  logic x19_toSRAM_1_we;
  logic x19_toSRAM_1_ack;
  logic x19_toSRAM_1_selectedOH;
  logic [6:0] x19_toSRAM_1_array;
  bit [1:0] cov_spread19;
  bit [23:0] cov_od0_19, cov_od1_19;
  bit cov_ack0_19, cov_ack1_19;
  MbistPipeSc_1 u_g19 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v19_rd0),
    .toSRAM_1_rdata (v19_rd1),
    .mbist_ack (g19_mbist_ack),
    .mbist_outdata (g19_mbist_outdata),
    .toSRAM_0_addr (g19_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g19_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g19_toSRAM_0_wdata),
    .toSRAM_0_wmask (g19_toSRAM_0_wmask),
    .toSRAM_0_re (g19_toSRAM_0_re),
    .toSRAM_0_we (g19_toSRAM_0_we),
    .toSRAM_0_ack (g19_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g19_toSRAM_0_selectedOH),
    .toSRAM_0_array (g19_toSRAM_0_array),
    .toSRAM_1_addr (g19_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g19_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g19_toSRAM_1_wdata),
    .toSRAM_1_wmask (g19_toSRAM_1_wmask),
    .toSRAM_1_re (g19_toSRAM_1_re),
    .toSRAM_1_we (g19_toSRAM_1_we),
    .toSRAM_1_ack (g19_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g19_toSRAM_1_selectedOH),
    .toSRAM_1_array (g19_toSRAM_1_array)
  );
  MbistPipeSc_1_xs u_x19 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v19_rd0),
    .toSRAM_1_rdata (v19_rd1),
    .mbist_ack (x19_mbist_ack),
    .mbist_outdata (x19_mbist_outdata),
    .toSRAM_0_addr (x19_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x19_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x19_toSRAM_0_wdata),
    .toSRAM_0_wmask (x19_toSRAM_0_wmask),
    .toSRAM_0_re (x19_toSRAM_0_re),
    .toSRAM_0_we (x19_toSRAM_0_we),
    .toSRAM_0_ack (x19_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x19_toSRAM_0_selectedOH),
    .toSRAM_0_array (x19_toSRAM_0_array),
    .toSRAM_1_addr (x19_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x19_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x19_toSRAM_1_wdata),
    .toSRAM_1_wmask (x19_toSRAM_1_wmask),
    .toSRAM_1_re (x19_toSRAM_1_re),
    .toSRAM_1_we (x19_toSRAM_1_we),
    .toSRAM_1_ack (x19_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x19_toSRAM_1_selectedOH),
    .toSRAM_1_array (x19_toSRAM_1_array)
  );
  wire [134:0] gbus19 = {g19_mbist_ack, g19_mbist_outdata, g19_toSRAM_0_addr, g19_toSRAM_0_addr_rd, g19_toSRAM_0_wdata, g19_toSRAM_0_wmask, g19_toSRAM_0_re, g19_toSRAM_0_we, g19_toSRAM_0_ack, g19_toSRAM_0_selectedOH, g19_toSRAM_0_array, g19_toSRAM_1_addr, g19_toSRAM_1_addr_rd, g19_toSRAM_1_wdata, g19_toSRAM_1_wmask, g19_toSRAM_1_re, g19_toSRAM_1_we, g19_toSRAM_1_ack, g19_toSRAM_1_selectedOH, g19_toSRAM_1_array};
  wire [134:0] xbus19 = {x19_mbist_ack, x19_mbist_outdata, x19_toSRAM_0_addr, x19_toSRAM_0_addr_rd, x19_toSRAM_0_wdata, x19_toSRAM_0_wmask, x19_toSRAM_0_re, x19_toSRAM_0_we, x19_toSRAM_0_ack, x19_toSRAM_0_selectedOH, x19_toSRAM_0_array, x19_toSRAM_1_addr, x19_toSRAM_1_addr_rd, x19_toSRAM_1_wdata, x19_toSRAM_1_wmask, x19_toSRAM_1_re, x19_toSRAM_1_we, x19_toSRAM_1_ack, x19_toSRAM_1_selectedOH, x19_toSRAM_1_array};
  task automatic detail19();
    if (g19_mbist_ack !== x19_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.mbist_ack golden=%h impl=%h", cyc, g19_mbist_ack, x19_mbist_ack); end
    if (g19_mbist_outdata !== x19_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.mbist_outdata golden=%h impl=%h", cyc, g19_mbist_outdata, x19_mbist_outdata); end
    if (g19_toSRAM_0_addr !== x19_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_addr golden=%h impl=%h", cyc, g19_toSRAM_0_addr, x19_toSRAM_0_addr); end
    if (g19_toSRAM_0_addr_rd !== x19_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g19_toSRAM_0_addr_rd, x19_toSRAM_0_addr_rd); end
    if (g19_toSRAM_0_wdata !== x19_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_wdata golden=%h impl=%h", cyc, g19_toSRAM_0_wdata, x19_toSRAM_0_wdata); end
    if (g19_toSRAM_0_wmask !== x19_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_wmask golden=%h impl=%h", cyc, g19_toSRAM_0_wmask, x19_toSRAM_0_wmask); end
    if (g19_toSRAM_0_re !== x19_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_re golden=%h impl=%h", cyc, g19_toSRAM_0_re, x19_toSRAM_0_re); end
    if (g19_toSRAM_0_we !== x19_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_we golden=%h impl=%h", cyc, g19_toSRAM_0_we, x19_toSRAM_0_we); end
    if (g19_toSRAM_0_ack !== x19_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_ack golden=%h impl=%h", cyc, g19_toSRAM_0_ack, x19_toSRAM_0_ack); end
    if (g19_toSRAM_0_selectedOH !== x19_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g19_toSRAM_0_selectedOH, x19_toSRAM_0_selectedOH); end
    if (g19_toSRAM_0_array !== x19_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_0_array golden=%h impl=%h", cyc, g19_toSRAM_0_array, x19_toSRAM_0_array); end
    if (g19_toSRAM_1_addr !== x19_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_addr golden=%h impl=%h", cyc, g19_toSRAM_1_addr, x19_toSRAM_1_addr); end
    if (g19_toSRAM_1_addr_rd !== x19_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g19_toSRAM_1_addr_rd, x19_toSRAM_1_addr_rd); end
    if (g19_toSRAM_1_wdata !== x19_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_wdata golden=%h impl=%h", cyc, g19_toSRAM_1_wdata, x19_toSRAM_1_wdata); end
    if (g19_toSRAM_1_wmask !== x19_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_wmask golden=%h impl=%h", cyc, g19_toSRAM_1_wmask, x19_toSRAM_1_wmask); end
    if (g19_toSRAM_1_re !== x19_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_re golden=%h impl=%h", cyc, g19_toSRAM_1_re, x19_toSRAM_1_re); end
    if (g19_toSRAM_1_we !== x19_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_we golden=%h impl=%h", cyc, g19_toSRAM_1_we, x19_toSRAM_1_we); end
    if (g19_toSRAM_1_ack !== x19_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_ack golden=%h impl=%h", cyc, g19_toSRAM_1_ack, x19_toSRAM_1_ack); end
    if (g19_toSRAM_1_selectedOH !== x19_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g19_toSRAM_1_selectedOH, x19_toSRAM_1_selectedOH); end
    if (g19_toSRAM_1_array !== x19_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_1.toSRAM_1_array golden=%h impl=%h", cyc, g19_toSRAM_1_array, x19_toSRAM_1_array); end
  endtask

  // ======================== [20] MbistPipeSc_2 ========================
  logic [23:0] v20_rd0;
  logic [23:0] v20_rd1;
  logic g20_mbist_ack;
  logic [23:0] g20_mbist_outdata;
  logic [7:0] g20_toSRAM_0_addr;
  logic [7:0] g20_toSRAM_0_addr_rd;
  logic [23:0] g20_toSRAM_0_wdata;
  logic [3:0] g20_toSRAM_0_wmask;
  logic g20_toSRAM_0_re;
  logic g20_toSRAM_0_we;
  logic g20_toSRAM_0_ack;
  logic g20_toSRAM_0_selectedOH;
  logic [6:0] g20_toSRAM_0_array;
  logic [7:0] g20_toSRAM_1_addr;
  logic [7:0] g20_toSRAM_1_addr_rd;
  logic [23:0] g20_toSRAM_1_wdata;
  logic [3:0] g20_toSRAM_1_wmask;
  logic g20_toSRAM_1_re;
  logic g20_toSRAM_1_we;
  logic g20_toSRAM_1_ack;
  logic g20_toSRAM_1_selectedOH;
  logic [6:0] g20_toSRAM_1_array;
  logic x20_mbist_ack;
  logic [23:0] x20_mbist_outdata;
  logic [7:0] x20_toSRAM_0_addr;
  logic [7:0] x20_toSRAM_0_addr_rd;
  logic [23:0] x20_toSRAM_0_wdata;
  logic [3:0] x20_toSRAM_0_wmask;
  logic x20_toSRAM_0_re;
  logic x20_toSRAM_0_we;
  logic x20_toSRAM_0_ack;
  logic x20_toSRAM_0_selectedOH;
  logic [6:0] x20_toSRAM_0_array;
  logic [7:0] x20_toSRAM_1_addr;
  logic [7:0] x20_toSRAM_1_addr_rd;
  logic [23:0] x20_toSRAM_1_wdata;
  logic [3:0] x20_toSRAM_1_wmask;
  logic x20_toSRAM_1_re;
  logic x20_toSRAM_1_we;
  logic x20_toSRAM_1_ack;
  logic x20_toSRAM_1_selectedOH;
  logic [6:0] x20_toSRAM_1_array;
  bit [1:0] cov_spread20;
  bit [23:0] cov_od0_20, cov_od1_20;
  bit cov_ack0_20, cov_ack1_20;
  MbistPipeSc_2 u_g20 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v20_rd0),
    .toSRAM_1_rdata (v20_rd1),
    .mbist_ack (g20_mbist_ack),
    .mbist_outdata (g20_mbist_outdata),
    .toSRAM_0_addr (g20_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g20_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g20_toSRAM_0_wdata),
    .toSRAM_0_wmask (g20_toSRAM_0_wmask),
    .toSRAM_0_re (g20_toSRAM_0_re),
    .toSRAM_0_we (g20_toSRAM_0_we),
    .toSRAM_0_ack (g20_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g20_toSRAM_0_selectedOH),
    .toSRAM_0_array (g20_toSRAM_0_array),
    .toSRAM_1_addr (g20_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g20_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g20_toSRAM_1_wdata),
    .toSRAM_1_wmask (g20_toSRAM_1_wmask),
    .toSRAM_1_re (g20_toSRAM_1_re),
    .toSRAM_1_we (g20_toSRAM_1_we),
    .toSRAM_1_ack (g20_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g20_toSRAM_1_selectedOH),
    .toSRAM_1_array (g20_toSRAM_1_array)
  );
  MbistPipeSc_2_xs u_x20 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v20_rd0),
    .toSRAM_1_rdata (v20_rd1),
    .mbist_ack (x20_mbist_ack),
    .mbist_outdata (x20_mbist_outdata),
    .toSRAM_0_addr (x20_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x20_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x20_toSRAM_0_wdata),
    .toSRAM_0_wmask (x20_toSRAM_0_wmask),
    .toSRAM_0_re (x20_toSRAM_0_re),
    .toSRAM_0_we (x20_toSRAM_0_we),
    .toSRAM_0_ack (x20_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x20_toSRAM_0_selectedOH),
    .toSRAM_0_array (x20_toSRAM_0_array),
    .toSRAM_1_addr (x20_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x20_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x20_toSRAM_1_wdata),
    .toSRAM_1_wmask (x20_toSRAM_1_wmask),
    .toSRAM_1_re (x20_toSRAM_1_re),
    .toSRAM_1_we (x20_toSRAM_1_we),
    .toSRAM_1_ack (x20_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x20_toSRAM_1_selectedOH),
    .toSRAM_1_array (x20_toSRAM_1_array)
  );
  wire [134:0] gbus20 = {g20_mbist_ack, g20_mbist_outdata, g20_toSRAM_0_addr, g20_toSRAM_0_addr_rd, g20_toSRAM_0_wdata, g20_toSRAM_0_wmask, g20_toSRAM_0_re, g20_toSRAM_0_we, g20_toSRAM_0_ack, g20_toSRAM_0_selectedOH, g20_toSRAM_0_array, g20_toSRAM_1_addr, g20_toSRAM_1_addr_rd, g20_toSRAM_1_wdata, g20_toSRAM_1_wmask, g20_toSRAM_1_re, g20_toSRAM_1_we, g20_toSRAM_1_ack, g20_toSRAM_1_selectedOH, g20_toSRAM_1_array};
  wire [134:0] xbus20 = {x20_mbist_ack, x20_mbist_outdata, x20_toSRAM_0_addr, x20_toSRAM_0_addr_rd, x20_toSRAM_0_wdata, x20_toSRAM_0_wmask, x20_toSRAM_0_re, x20_toSRAM_0_we, x20_toSRAM_0_ack, x20_toSRAM_0_selectedOH, x20_toSRAM_0_array, x20_toSRAM_1_addr, x20_toSRAM_1_addr_rd, x20_toSRAM_1_wdata, x20_toSRAM_1_wmask, x20_toSRAM_1_re, x20_toSRAM_1_we, x20_toSRAM_1_ack, x20_toSRAM_1_selectedOH, x20_toSRAM_1_array};
  task automatic detail20();
    if (g20_mbist_ack !== x20_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.mbist_ack golden=%h impl=%h", cyc, g20_mbist_ack, x20_mbist_ack); end
    if (g20_mbist_outdata !== x20_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.mbist_outdata golden=%h impl=%h", cyc, g20_mbist_outdata, x20_mbist_outdata); end
    if (g20_toSRAM_0_addr !== x20_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_addr golden=%h impl=%h", cyc, g20_toSRAM_0_addr, x20_toSRAM_0_addr); end
    if (g20_toSRAM_0_addr_rd !== x20_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g20_toSRAM_0_addr_rd, x20_toSRAM_0_addr_rd); end
    if (g20_toSRAM_0_wdata !== x20_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_wdata golden=%h impl=%h", cyc, g20_toSRAM_0_wdata, x20_toSRAM_0_wdata); end
    if (g20_toSRAM_0_wmask !== x20_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_wmask golden=%h impl=%h", cyc, g20_toSRAM_0_wmask, x20_toSRAM_0_wmask); end
    if (g20_toSRAM_0_re !== x20_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_re golden=%h impl=%h", cyc, g20_toSRAM_0_re, x20_toSRAM_0_re); end
    if (g20_toSRAM_0_we !== x20_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_we golden=%h impl=%h", cyc, g20_toSRAM_0_we, x20_toSRAM_0_we); end
    if (g20_toSRAM_0_ack !== x20_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_ack golden=%h impl=%h", cyc, g20_toSRAM_0_ack, x20_toSRAM_0_ack); end
    if (g20_toSRAM_0_selectedOH !== x20_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g20_toSRAM_0_selectedOH, x20_toSRAM_0_selectedOH); end
    if (g20_toSRAM_0_array !== x20_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_0_array golden=%h impl=%h", cyc, g20_toSRAM_0_array, x20_toSRAM_0_array); end
    if (g20_toSRAM_1_addr !== x20_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_addr golden=%h impl=%h", cyc, g20_toSRAM_1_addr, x20_toSRAM_1_addr); end
    if (g20_toSRAM_1_addr_rd !== x20_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g20_toSRAM_1_addr_rd, x20_toSRAM_1_addr_rd); end
    if (g20_toSRAM_1_wdata !== x20_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_wdata golden=%h impl=%h", cyc, g20_toSRAM_1_wdata, x20_toSRAM_1_wdata); end
    if (g20_toSRAM_1_wmask !== x20_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_wmask golden=%h impl=%h", cyc, g20_toSRAM_1_wmask, x20_toSRAM_1_wmask); end
    if (g20_toSRAM_1_re !== x20_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_re golden=%h impl=%h", cyc, g20_toSRAM_1_re, x20_toSRAM_1_re); end
    if (g20_toSRAM_1_we !== x20_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_we golden=%h impl=%h", cyc, g20_toSRAM_1_we, x20_toSRAM_1_we); end
    if (g20_toSRAM_1_ack !== x20_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_ack golden=%h impl=%h", cyc, g20_toSRAM_1_ack, x20_toSRAM_1_ack); end
    if (g20_toSRAM_1_selectedOH !== x20_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g20_toSRAM_1_selectedOH, x20_toSRAM_1_selectedOH); end
    if (g20_toSRAM_1_array !== x20_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_2.toSRAM_1_array golden=%h impl=%h", cyc, g20_toSRAM_1_array, x20_toSRAM_1_array); end
  endtask

  // ======================== [21] MbistPipeSc_3 ========================
  logic [23:0] v21_rd0;
  logic [23:0] v21_rd1;
  logic g21_mbist_ack;
  logic [23:0] g21_mbist_outdata;
  logic [7:0] g21_toSRAM_0_addr;
  logic [7:0] g21_toSRAM_0_addr_rd;
  logic [23:0] g21_toSRAM_0_wdata;
  logic [3:0] g21_toSRAM_0_wmask;
  logic g21_toSRAM_0_re;
  logic g21_toSRAM_0_we;
  logic g21_toSRAM_0_ack;
  logic g21_toSRAM_0_selectedOH;
  logic [6:0] g21_toSRAM_0_array;
  logic [7:0] g21_toSRAM_1_addr;
  logic [7:0] g21_toSRAM_1_addr_rd;
  logic [23:0] g21_toSRAM_1_wdata;
  logic [3:0] g21_toSRAM_1_wmask;
  logic g21_toSRAM_1_re;
  logic g21_toSRAM_1_we;
  logic g21_toSRAM_1_ack;
  logic g21_toSRAM_1_selectedOH;
  logic [6:0] g21_toSRAM_1_array;
  logic x21_mbist_ack;
  logic [23:0] x21_mbist_outdata;
  logic [7:0] x21_toSRAM_0_addr;
  logic [7:0] x21_toSRAM_0_addr_rd;
  logic [23:0] x21_toSRAM_0_wdata;
  logic [3:0] x21_toSRAM_0_wmask;
  logic x21_toSRAM_0_re;
  logic x21_toSRAM_0_we;
  logic x21_toSRAM_0_ack;
  logic x21_toSRAM_0_selectedOH;
  logic [6:0] x21_toSRAM_0_array;
  logic [7:0] x21_toSRAM_1_addr;
  logic [7:0] x21_toSRAM_1_addr_rd;
  logic [23:0] x21_toSRAM_1_wdata;
  logic [3:0] x21_toSRAM_1_wmask;
  logic x21_toSRAM_1_re;
  logic x21_toSRAM_1_we;
  logic x21_toSRAM_1_ack;
  logic x21_toSRAM_1_selectedOH;
  logic [6:0] x21_toSRAM_1_array;
  bit [1:0] cov_spread21;
  bit [23:0] cov_od0_21, cov_od1_21;
  bit cov_ack0_21, cov_ack1_21;
  MbistPipeSc_3 u_g21 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v21_rd0),
    .toSRAM_1_rdata (v21_rd1),
    .mbist_ack (g21_mbist_ack),
    .mbist_outdata (g21_mbist_outdata),
    .toSRAM_0_addr (g21_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g21_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g21_toSRAM_0_wdata),
    .toSRAM_0_wmask (g21_toSRAM_0_wmask),
    .toSRAM_0_re (g21_toSRAM_0_re),
    .toSRAM_0_we (g21_toSRAM_0_we),
    .toSRAM_0_ack (g21_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g21_toSRAM_0_selectedOH),
    .toSRAM_0_array (g21_toSRAM_0_array),
    .toSRAM_1_addr (g21_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g21_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g21_toSRAM_1_wdata),
    .toSRAM_1_wmask (g21_toSRAM_1_wmask),
    .toSRAM_1_re (g21_toSRAM_1_re),
    .toSRAM_1_we (g21_toSRAM_1_we),
    .toSRAM_1_ack (g21_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g21_toSRAM_1_selectedOH),
    .toSRAM_1_array (g21_toSRAM_1_array)
  );
  MbistPipeSc_3_xs u_x21 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[3:0]),
    .mbist_addr (s_addr[7:0]),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[7:0]),
    .toSRAM_0_rdata (v21_rd0),
    .toSRAM_1_rdata (v21_rd1),
    .mbist_ack (x21_mbist_ack),
    .mbist_outdata (x21_mbist_outdata),
    .toSRAM_0_addr (x21_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x21_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x21_toSRAM_0_wdata),
    .toSRAM_0_wmask (x21_toSRAM_0_wmask),
    .toSRAM_0_re (x21_toSRAM_0_re),
    .toSRAM_0_we (x21_toSRAM_0_we),
    .toSRAM_0_ack (x21_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x21_toSRAM_0_selectedOH),
    .toSRAM_0_array (x21_toSRAM_0_array),
    .toSRAM_1_addr (x21_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x21_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x21_toSRAM_1_wdata),
    .toSRAM_1_wmask (x21_toSRAM_1_wmask),
    .toSRAM_1_re (x21_toSRAM_1_re),
    .toSRAM_1_we (x21_toSRAM_1_we),
    .toSRAM_1_ack (x21_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x21_toSRAM_1_selectedOH),
    .toSRAM_1_array (x21_toSRAM_1_array)
  );
  wire [134:0] gbus21 = {g21_mbist_ack, g21_mbist_outdata, g21_toSRAM_0_addr, g21_toSRAM_0_addr_rd, g21_toSRAM_0_wdata, g21_toSRAM_0_wmask, g21_toSRAM_0_re, g21_toSRAM_0_we, g21_toSRAM_0_ack, g21_toSRAM_0_selectedOH, g21_toSRAM_0_array, g21_toSRAM_1_addr, g21_toSRAM_1_addr_rd, g21_toSRAM_1_wdata, g21_toSRAM_1_wmask, g21_toSRAM_1_re, g21_toSRAM_1_we, g21_toSRAM_1_ack, g21_toSRAM_1_selectedOH, g21_toSRAM_1_array};
  wire [134:0] xbus21 = {x21_mbist_ack, x21_mbist_outdata, x21_toSRAM_0_addr, x21_toSRAM_0_addr_rd, x21_toSRAM_0_wdata, x21_toSRAM_0_wmask, x21_toSRAM_0_re, x21_toSRAM_0_we, x21_toSRAM_0_ack, x21_toSRAM_0_selectedOH, x21_toSRAM_0_array, x21_toSRAM_1_addr, x21_toSRAM_1_addr_rd, x21_toSRAM_1_wdata, x21_toSRAM_1_wmask, x21_toSRAM_1_re, x21_toSRAM_1_we, x21_toSRAM_1_ack, x21_toSRAM_1_selectedOH, x21_toSRAM_1_array};
  task automatic detail21();
    if (g21_mbist_ack !== x21_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.mbist_ack golden=%h impl=%h", cyc, g21_mbist_ack, x21_mbist_ack); end
    if (g21_mbist_outdata !== x21_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.mbist_outdata golden=%h impl=%h", cyc, g21_mbist_outdata, x21_mbist_outdata); end
    if (g21_toSRAM_0_addr !== x21_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_addr golden=%h impl=%h", cyc, g21_toSRAM_0_addr, x21_toSRAM_0_addr); end
    if (g21_toSRAM_0_addr_rd !== x21_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g21_toSRAM_0_addr_rd, x21_toSRAM_0_addr_rd); end
    if (g21_toSRAM_0_wdata !== x21_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_wdata golden=%h impl=%h", cyc, g21_toSRAM_0_wdata, x21_toSRAM_0_wdata); end
    if (g21_toSRAM_0_wmask !== x21_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_wmask golden=%h impl=%h", cyc, g21_toSRAM_0_wmask, x21_toSRAM_0_wmask); end
    if (g21_toSRAM_0_re !== x21_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_re golden=%h impl=%h", cyc, g21_toSRAM_0_re, x21_toSRAM_0_re); end
    if (g21_toSRAM_0_we !== x21_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_we golden=%h impl=%h", cyc, g21_toSRAM_0_we, x21_toSRAM_0_we); end
    if (g21_toSRAM_0_ack !== x21_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_ack golden=%h impl=%h", cyc, g21_toSRAM_0_ack, x21_toSRAM_0_ack); end
    if (g21_toSRAM_0_selectedOH !== x21_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g21_toSRAM_0_selectedOH, x21_toSRAM_0_selectedOH); end
    if (g21_toSRAM_0_array !== x21_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_0_array golden=%h impl=%h", cyc, g21_toSRAM_0_array, x21_toSRAM_0_array); end
    if (g21_toSRAM_1_addr !== x21_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_addr golden=%h impl=%h", cyc, g21_toSRAM_1_addr, x21_toSRAM_1_addr); end
    if (g21_toSRAM_1_addr_rd !== x21_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g21_toSRAM_1_addr_rd, x21_toSRAM_1_addr_rd); end
    if (g21_toSRAM_1_wdata !== x21_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_wdata golden=%h impl=%h", cyc, g21_toSRAM_1_wdata, x21_toSRAM_1_wdata); end
    if (g21_toSRAM_1_wmask !== x21_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_wmask golden=%h impl=%h", cyc, g21_toSRAM_1_wmask, x21_toSRAM_1_wmask); end
    if (g21_toSRAM_1_re !== x21_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_re golden=%h impl=%h", cyc, g21_toSRAM_1_re, x21_toSRAM_1_re); end
    if (g21_toSRAM_1_we !== x21_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_we golden=%h impl=%h", cyc, g21_toSRAM_1_we, x21_toSRAM_1_we); end
    if (g21_toSRAM_1_ack !== x21_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_ack golden=%h impl=%h", cyc, g21_toSRAM_1_ack, x21_toSRAM_1_ack); end
    if (g21_toSRAM_1_selectedOH !== x21_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g21_toSRAM_1_selectedOH, x21_toSRAM_1_selectedOH); end
    if (g21_toSRAM_1_array !== x21_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSc_3.toSRAM_1_array golden=%h impl=%h", cyc, g21_toSRAM_1_array, x21_toSRAM_1_array); end
  endtask

  // ======================== [22] MbistPipeSms ========================
  logic [147:0] v22_rd0;
  logic g22_mbist_ack;
  logic [147:0] g22_mbist_outdata;
  logic [5:0] g22_toSRAM_0_addr;
  logic [5:0] g22_toSRAM_0_addr_rd;
  logic [147:0] g22_toSRAM_0_wdata;
  logic [1:0] g22_toSRAM_0_wmask;
  logic g22_toSRAM_0_re;
  logic g22_toSRAM_0_we;
  logic g22_toSRAM_0_ack;
  logic g22_toSRAM_0_selectedOH;
  logic [6:0] g22_toSRAM_0_array;
  logic x22_mbist_ack;
  logic [147:0] x22_mbist_outdata;
  logic [5:0] x22_toSRAM_0_addr;
  logic [5:0] x22_toSRAM_0_addr_rd;
  logic [147:0] x22_toSRAM_0_wdata;
  logic [1:0] x22_toSRAM_0_wmask;
  logic x22_toSRAM_0_re;
  logic x22_toSRAM_0_we;
  logic x22_toSRAM_0_ack;
  logic x22_toSRAM_0_selectedOH;
  logic [6:0] x22_toSRAM_0_array;
  bit [0:0] cov_spread22;
  bit [147:0] cov_od0_22, cov_od1_22;
  bit cov_ack0_22, cov_ack1_22;
  MbistPipeSms u_g22 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[5:0]),
    .mbist_indata (s_indata),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[5:0]),
    .toSRAM_0_rdata (v22_rd0),
    .mbist_ack (g22_mbist_ack),
    .mbist_outdata (g22_mbist_outdata),
    .toSRAM_0_addr (g22_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g22_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g22_toSRAM_0_wdata),
    .toSRAM_0_wmask (g22_toSRAM_0_wmask),
    .toSRAM_0_re (g22_toSRAM_0_re),
    .toSRAM_0_we (g22_toSRAM_0_we),
    .toSRAM_0_ack (g22_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g22_toSRAM_0_selectedOH),
    .toSRAM_0_array (g22_toSRAM_0_array)
  );
  MbistPipeSms_xs u_x22 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[1:0]),
    .mbist_addr (s_addr[5:0]),
    .mbist_indata (s_indata),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd[5:0]),
    .toSRAM_0_rdata (v22_rd0),
    .mbist_ack (x22_mbist_ack),
    .mbist_outdata (x22_mbist_outdata),
    .toSRAM_0_addr (x22_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x22_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x22_toSRAM_0_wdata),
    .toSRAM_0_wmask (x22_toSRAM_0_wmask),
    .toSRAM_0_re (x22_toSRAM_0_re),
    .toSRAM_0_we (x22_toSRAM_0_we),
    .toSRAM_0_ack (x22_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x22_toSRAM_0_selectedOH),
    .toSRAM_0_array (x22_toSRAM_0_array)
  );
  wire [321:0] gbus22 = {g22_mbist_ack, g22_mbist_outdata, g22_toSRAM_0_addr, g22_toSRAM_0_addr_rd, g22_toSRAM_0_wdata, g22_toSRAM_0_wmask, g22_toSRAM_0_re, g22_toSRAM_0_we, g22_toSRAM_0_ack, g22_toSRAM_0_selectedOH, g22_toSRAM_0_array};
  wire [321:0] xbus22 = {x22_mbist_ack, x22_mbist_outdata, x22_toSRAM_0_addr, x22_toSRAM_0_addr_rd, x22_toSRAM_0_wdata, x22_toSRAM_0_wmask, x22_toSRAM_0_re, x22_toSRAM_0_we, x22_toSRAM_0_ack, x22_toSRAM_0_selectedOH, x22_toSRAM_0_array};
  task automatic detail22();
    if (g22_mbist_ack !== x22_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.mbist_ack golden=%h impl=%h", cyc, g22_mbist_ack, x22_mbist_ack); end
    if (g22_mbist_outdata !== x22_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.mbist_outdata golden=%h impl=%h", cyc, g22_mbist_outdata, x22_mbist_outdata); end
    if (g22_toSRAM_0_addr !== x22_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_addr golden=%h impl=%h", cyc, g22_toSRAM_0_addr, x22_toSRAM_0_addr); end
    if (g22_toSRAM_0_addr_rd !== x22_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g22_toSRAM_0_addr_rd, x22_toSRAM_0_addr_rd); end
    if (g22_toSRAM_0_wdata !== x22_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_wdata golden=%h impl=%h", cyc, g22_toSRAM_0_wdata, x22_toSRAM_0_wdata); end
    if (g22_toSRAM_0_wmask !== x22_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_wmask golden=%h impl=%h", cyc, g22_toSRAM_0_wmask, x22_toSRAM_0_wmask); end
    if (g22_toSRAM_0_re !== x22_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_re golden=%h impl=%h", cyc, g22_toSRAM_0_re, x22_toSRAM_0_re); end
    if (g22_toSRAM_0_we !== x22_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_we golden=%h impl=%h", cyc, g22_toSRAM_0_we, x22_toSRAM_0_we); end
    if (g22_toSRAM_0_ack !== x22_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_ack golden=%h impl=%h", cyc, g22_toSRAM_0_ack, x22_toSRAM_0_ack); end
    if (g22_toSRAM_0_selectedOH !== x22_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g22_toSRAM_0_selectedOH, x22_toSRAM_0_selectedOH); end
    if (g22_toSRAM_0_array !== x22_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeSms.toSRAM_0_array golden=%h impl=%h", cyc, g22_toSRAM_0_array, x22_toSRAM_0_array); end
  endtask

  // ======================== [23] MbistPipeTage ========================
  logic [15:0] v23_rd0;
  logic [23:0] v23_rd1;
  logic [23:0] v23_rd2;
  logic [23:0] v23_rd3;
  logic [23:0] v23_rd4;
  logic [15:0] v23_rd5;
  logic [23:0] v23_rd6;
  logic [23:0] v23_rd7;
  logic [23:0] v23_rd8;
  logic [23:0] v23_rd9;
  logic [15:0] v23_rd10;
  logic [23:0] v23_rd11;
  logic [23:0] v23_rd12;
  logic [23:0] v23_rd13;
  logic [23:0] v23_rd14;
  logic [15:0] v23_rd15;
  logic [23:0] v23_rd16;
  logic [23:0] v23_rd17;
  logic [23:0] v23_rd18;
  logic [23:0] v23_rd19;
  logic [7:0] v23_rd20;
  logic [7:0] v23_rd21;
  logic [7:0] v23_rd22;
  logic [7:0] v23_rd23;
  logic g23_mbist_ack;
  logic [23:0] g23_mbist_outdata;
  logic [8:0] g23_toSRAM_0_addr;
  logic [8:0] g23_toSRAM_0_addr_rd;
  logic [15:0] g23_toSRAM_0_wdata;
  logic [15:0] g23_toSRAM_0_wmask;
  logic g23_toSRAM_0_re;
  logic g23_toSRAM_0_we;
  logic g23_toSRAM_0_ack;
  logic g23_toSRAM_0_selectedOH;
  logic [5:0] g23_toSRAM_0_array;
  logic [9:0] g23_toSRAM_1_addr;
  logic [9:0] g23_toSRAM_1_addr_rd;
  logic [23:0] g23_toSRAM_1_wdata;
  logic [1:0] g23_toSRAM_1_wmask;
  logic g23_toSRAM_1_re;
  logic g23_toSRAM_1_we;
  logic g23_toSRAM_1_ack;
  logic g23_toSRAM_1_selectedOH;
  logic [5:0] g23_toSRAM_1_array;
  logic [9:0] g23_toSRAM_2_addr;
  logic [9:0] g23_toSRAM_2_addr_rd;
  logic [23:0] g23_toSRAM_2_wdata;
  logic [1:0] g23_toSRAM_2_wmask;
  logic g23_toSRAM_2_re;
  logic g23_toSRAM_2_we;
  logic g23_toSRAM_2_ack;
  logic g23_toSRAM_2_selectedOH;
  logic [5:0] g23_toSRAM_2_array;
  logic [9:0] g23_toSRAM_3_addr;
  logic [9:0] g23_toSRAM_3_addr_rd;
  logic [23:0] g23_toSRAM_3_wdata;
  logic [1:0] g23_toSRAM_3_wmask;
  logic g23_toSRAM_3_re;
  logic g23_toSRAM_3_we;
  logic g23_toSRAM_3_ack;
  logic g23_toSRAM_3_selectedOH;
  logic [5:0] g23_toSRAM_3_array;
  logic [9:0] g23_toSRAM_4_addr;
  logic [9:0] g23_toSRAM_4_addr_rd;
  logic [23:0] g23_toSRAM_4_wdata;
  logic [1:0] g23_toSRAM_4_wmask;
  logic g23_toSRAM_4_re;
  logic g23_toSRAM_4_we;
  logic g23_toSRAM_4_ack;
  logic g23_toSRAM_4_selectedOH;
  logic [5:0] g23_toSRAM_4_array;
  logic [8:0] g23_toSRAM_5_addr;
  logic [8:0] g23_toSRAM_5_addr_rd;
  logic [15:0] g23_toSRAM_5_wdata;
  logic [15:0] g23_toSRAM_5_wmask;
  logic g23_toSRAM_5_re;
  logic g23_toSRAM_5_we;
  logic g23_toSRAM_5_ack;
  logic g23_toSRAM_5_selectedOH;
  logic [5:0] g23_toSRAM_5_array;
  logic [9:0] g23_toSRAM_6_addr;
  logic [9:0] g23_toSRAM_6_addr_rd;
  logic [23:0] g23_toSRAM_6_wdata;
  logic [1:0] g23_toSRAM_6_wmask;
  logic g23_toSRAM_6_re;
  logic g23_toSRAM_6_we;
  logic g23_toSRAM_6_ack;
  logic g23_toSRAM_6_selectedOH;
  logic [5:0] g23_toSRAM_6_array;
  logic [9:0] g23_toSRAM_7_addr;
  logic [9:0] g23_toSRAM_7_addr_rd;
  logic [23:0] g23_toSRAM_7_wdata;
  logic [1:0] g23_toSRAM_7_wmask;
  logic g23_toSRAM_7_re;
  logic g23_toSRAM_7_we;
  logic g23_toSRAM_7_ack;
  logic g23_toSRAM_7_selectedOH;
  logic [5:0] g23_toSRAM_7_array;
  logic [9:0] g23_toSRAM_8_addr;
  logic [9:0] g23_toSRAM_8_addr_rd;
  logic [23:0] g23_toSRAM_8_wdata;
  logic [1:0] g23_toSRAM_8_wmask;
  logic g23_toSRAM_8_re;
  logic g23_toSRAM_8_we;
  logic g23_toSRAM_8_ack;
  logic g23_toSRAM_8_selectedOH;
  logic [5:0] g23_toSRAM_8_array;
  logic [9:0] g23_toSRAM_9_addr;
  logic [9:0] g23_toSRAM_9_addr_rd;
  logic [23:0] g23_toSRAM_9_wdata;
  logic [1:0] g23_toSRAM_9_wmask;
  logic g23_toSRAM_9_re;
  logic g23_toSRAM_9_we;
  logic g23_toSRAM_9_ack;
  logic g23_toSRAM_9_selectedOH;
  logic [5:0] g23_toSRAM_9_array;
  logic [8:0] g23_toSRAM_10_addr;
  logic [8:0] g23_toSRAM_10_addr_rd;
  logic [15:0] g23_toSRAM_10_wdata;
  logic [15:0] g23_toSRAM_10_wmask;
  logic g23_toSRAM_10_re;
  logic g23_toSRAM_10_we;
  logic g23_toSRAM_10_ack;
  logic g23_toSRAM_10_selectedOH;
  logic [5:0] g23_toSRAM_10_array;
  logic [9:0] g23_toSRAM_11_addr;
  logic [9:0] g23_toSRAM_11_addr_rd;
  logic [23:0] g23_toSRAM_11_wdata;
  logic [1:0] g23_toSRAM_11_wmask;
  logic g23_toSRAM_11_re;
  logic g23_toSRAM_11_we;
  logic g23_toSRAM_11_ack;
  logic g23_toSRAM_11_selectedOH;
  logic [5:0] g23_toSRAM_11_array;
  logic [9:0] g23_toSRAM_12_addr;
  logic [9:0] g23_toSRAM_12_addr_rd;
  logic [23:0] g23_toSRAM_12_wdata;
  logic [1:0] g23_toSRAM_12_wmask;
  logic g23_toSRAM_12_re;
  logic g23_toSRAM_12_we;
  logic g23_toSRAM_12_ack;
  logic g23_toSRAM_12_selectedOH;
  logic [5:0] g23_toSRAM_12_array;
  logic [9:0] g23_toSRAM_13_addr;
  logic [9:0] g23_toSRAM_13_addr_rd;
  logic [23:0] g23_toSRAM_13_wdata;
  logic [1:0] g23_toSRAM_13_wmask;
  logic g23_toSRAM_13_re;
  logic g23_toSRAM_13_we;
  logic g23_toSRAM_13_ack;
  logic g23_toSRAM_13_selectedOH;
  logic [5:0] g23_toSRAM_13_array;
  logic [9:0] g23_toSRAM_14_addr;
  logic [9:0] g23_toSRAM_14_addr_rd;
  logic [23:0] g23_toSRAM_14_wdata;
  logic [1:0] g23_toSRAM_14_wmask;
  logic g23_toSRAM_14_re;
  logic g23_toSRAM_14_we;
  logic g23_toSRAM_14_ack;
  logic g23_toSRAM_14_selectedOH;
  logic [5:0] g23_toSRAM_14_array;
  logic [8:0] g23_toSRAM_15_addr;
  logic [8:0] g23_toSRAM_15_addr_rd;
  logic [15:0] g23_toSRAM_15_wdata;
  logic [15:0] g23_toSRAM_15_wmask;
  logic g23_toSRAM_15_re;
  logic g23_toSRAM_15_we;
  logic g23_toSRAM_15_ack;
  logic g23_toSRAM_15_selectedOH;
  logic [5:0] g23_toSRAM_15_array;
  logic [9:0] g23_toSRAM_16_addr;
  logic [9:0] g23_toSRAM_16_addr_rd;
  logic [23:0] g23_toSRAM_16_wdata;
  logic [1:0] g23_toSRAM_16_wmask;
  logic g23_toSRAM_16_re;
  logic g23_toSRAM_16_we;
  logic g23_toSRAM_16_ack;
  logic g23_toSRAM_16_selectedOH;
  logic [5:0] g23_toSRAM_16_array;
  logic [9:0] g23_toSRAM_17_addr;
  logic [9:0] g23_toSRAM_17_addr_rd;
  logic [23:0] g23_toSRAM_17_wdata;
  logic [1:0] g23_toSRAM_17_wmask;
  logic g23_toSRAM_17_re;
  logic g23_toSRAM_17_we;
  logic g23_toSRAM_17_ack;
  logic g23_toSRAM_17_selectedOH;
  logic [5:0] g23_toSRAM_17_array;
  logic [9:0] g23_toSRAM_18_addr;
  logic [9:0] g23_toSRAM_18_addr_rd;
  logic [23:0] g23_toSRAM_18_wdata;
  logic [1:0] g23_toSRAM_18_wmask;
  logic g23_toSRAM_18_re;
  logic g23_toSRAM_18_we;
  logic g23_toSRAM_18_ack;
  logic g23_toSRAM_18_selectedOH;
  logic [5:0] g23_toSRAM_18_array;
  logic [9:0] g23_toSRAM_19_addr;
  logic [9:0] g23_toSRAM_19_addr_rd;
  logic [23:0] g23_toSRAM_19_wdata;
  logic [1:0] g23_toSRAM_19_wmask;
  logic g23_toSRAM_19_re;
  logic g23_toSRAM_19_we;
  logic g23_toSRAM_19_ack;
  logic g23_toSRAM_19_selectedOH;
  logic [5:0] g23_toSRAM_19_array;
  logic [8:0] g23_toSRAM_20_addr;
  logic [8:0] g23_toSRAM_20_addr_rd;
  logic [7:0] g23_toSRAM_20_wdata;
  logic [3:0] g23_toSRAM_20_wmask;
  logic g23_toSRAM_20_re;
  logic g23_toSRAM_20_we;
  logic g23_toSRAM_20_ack;
  logic g23_toSRAM_20_selectedOH;
  logic [6:0] g23_toSRAM_20_array;
  logic [8:0] g23_toSRAM_21_addr;
  logic [8:0] g23_toSRAM_21_addr_rd;
  logic [7:0] g23_toSRAM_21_wdata;
  logic [3:0] g23_toSRAM_21_wmask;
  logic g23_toSRAM_21_re;
  logic g23_toSRAM_21_we;
  logic g23_toSRAM_21_ack;
  logic g23_toSRAM_21_selectedOH;
  logic [6:0] g23_toSRAM_21_array;
  logic [8:0] g23_toSRAM_22_addr;
  logic [8:0] g23_toSRAM_22_addr_rd;
  logic [7:0] g23_toSRAM_22_wdata;
  logic [3:0] g23_toSRAM_22_wmask;
  logic g23_toSRAM_22_re;
  logic g23_toSRAM_22_we;
  logic g23_toSRAM_22_ack;
  logic g23_toSRAM_22_selectedOH;
  logic [6:0] g23_toSRAM_22_array;
  logic [8:0] g23_toSRAM_23_addr;
  logic [8:0] g23_toSRAM_23_addr_rd;
  logic [7:0] g23_toSRAM_23_wdata;
  logic [3:0] g23_toSRAM_23_wmask;
  logic g23_toSRAM_23_re;
  logic g23_toSRAM_23_we;
  logic g23_toSRAM_23_ack;
  logic g23_toSRAM_23_selectedOH;
  logic [6:0] g23_toSRAM_23_array;
  logic x23_mbist_ack;
  logic [23:0] x23_mbist_outdata;
  logic [8:0] x23_toSRAM_0_addr;
  logic [8:0] x23_toSRAM_0_addr_rd;
  logic [15:0] x23_toSRAM_0_wdata;
  logic [15:0] x23_toSRAM_0_wmask;
  logic x23_toSRAM_0_re;
  logic x23_toSRAM_0_we;
  logic x23_toSRAM_0_ack;
  logic x23_toSRAM_0_selectedOH;
  logic [5:0] x23_toSRAM_0_array;
  logic [9:0] x23_toSRAM_1_addr;
  logic [9:0] x23_toSRAM_1_addr_rd;
  logic [23:0] x23_toSRAM_1_wdata;
  logic [1:0] x23_toSRAM_1_wmask;
  logic x23_toSRAM_1_re;
  logic x23_toSRAM_1_we;
  logic x23_toSRAM_1_ack;
  logic x23_toSRAM_1_selectedOH;
  logic [5:0] x23_toSRAM_1_array;
  logic [9:0] x23_toSRAM_2_addr;
  logic [9:0] x23_toSRAM_2_addr_rd;
  logic [23:0] x23_toSRAM_2_wdata;
  logic [1:0] x23_toSRAM_2_wmask;
  logic x23_toSRAM_2_re;
  logic x23_toSRAM_2_we;
  logic x23_toSRAM_2_ack;
  logic x23_toSRAM_2_selectedOH;
  logic [5:0] x23_toSRAM_2_array;
  logic [9:0] x23_toSRAM_3_addr;
  logic [9:0] x23_toSRAM_3_addr_rd;
  logic [23:0] x23_toSRAM_3_wdata;
  logic [1:0] x23_toSRAM_3_wmask;
  logic x23_toSRAM_3_re;
  logic x23_toSRAM_3_we;
  logic x23_toSRAM_3_ack;
  logic x23_toSRAM_3_selectedOH;
  logic [5:0] x23_toSRAM_3_array;
  logic [9:0] x23_toSRAM_4_addr;
  logic [9:0] x23_toSRAM_4_addr_rd;
  logic [23:0] x23_toSRAM_4_wdata;
  logic [1:0] x23_toSRAM_4_wmask;
  logic x23_toSRAM_4_re;
  logic x23_toSRAM_4_we;
  logic x23_toSRAM_4_ack;
  logic x23_toSRAM_4_selectedOH;
  logic [5:0] x23_toSRAM_4_array;
  logic [8:0] x23_toSRAM_5_addr;
  logic [8:0] x23_toSRAM_5_addr_rd;
  logic [15:0] x23_toSRAM_5_wdata;
  logic [15:0] x23_toSRAM_5_wmask;
  logic x23_toSRAM_5_re;
  logic x23_toSRAM_5_we;
  logic x23_toSRAM_5_ack;
  logic x23_toSRAM_5_selectedOH;
  logic [5:0] x23_toSRAM_5_array;
  logic [9:0] x23_toSRAM_6_addr;
  logic [9:0] x23_toSRAM_6_addr_rd;
  logic [23:0] x23_toSRAM_6_wdata;
  logic [1:0] x23_toSRAM_6_wmask;
  logic x23_toSRAM_6_re;
  logic x23_toSRAM_6_we;
  logic x23_toSRAM_6_ack;
  logic x23_toSRAM_6_selectedOH;
  logic [5:0] x23_toSRAM_6_array;
  logic [9:0] x23_toSRAM_7_addr;
  logic [9:0] x23_toSRAM_7_addr_rd;
  logic [23:0] x23_toSRAM_7_wdata;
  logic [1:0] x23_toSRAM_7_wmask;
  logic x23_toSRAM_7_re;
  logic x23_toSRAM_7_we;
  logic x23_toSRAM_7_ack;
  logic x23_toSRAM_7_selectedOH;
  logic [5:0] x23_toSRAM_7_array;
  logic [9:0] x23_toSRAM_8_addr;
  logic [9:0] x23_toSRAM_8_addr_rd;
  logic [23:0] x23_toSRAM_8_wdata;
  logic [1:0] x23_toSRAM_8_wmask;
  logic x23_toSRAM_8_re;
  logic x23_toSRAM_8_we;
  logic x23_toSRAM_8_ack;
  logic x23_toSRAM_8_selectedOH;
  logic [5:0] x23_toSRAM_8_array;
  logic [9:0] x23_toSRAM_9_addr;
  logic [9:0] x23_toSRAM_9_addr_rd;
  logic [23:0] x23_toSRAM_9_wdata;
  logic [1:0] x23_toSRAM_9_wmask;
  logic x23_toSRAM_9_re;
  logic x23_toSRAM_9_we;
  logic x23_toSRAM_9_ack;
  logic x23_toSRAM_9_selectedOH;
  logic [5:0] x23_toSRAM_9_array;
  logic [8:0] x23_toSRAM_10_addr;
  logic [8:0] x23_toSRAM_10_addr_rd;
  logic [15:0] x23_toSRAM_10_wdata;
  logic [15:0] x23_toSRAM_10_wmask;
  logic x23_toSRAM_10_re;
  logic x23_toSRAM_10_we;
  logic x23_toSRAM_10_ack;
  logic x23_toSRAM_10_selectedOH;
  logic [5:0] x23_toSRAM_10_array;
  logic [9:0] x23_toSRAM_11_addr;
  logic [9:0] x23_toSRAM_11_addr_rd;
  logic [23:0] x23_toSRAM_11_wdata;
  logic [1:0] x23_toSRAM_11_wmask;
  logic x23_toSRAM_11_re;
  logic x23_toSRAM_11_we;
  logic x23_toSRAM_11_ack;
  logic x23_toSRAM_11_selectedOH;
  logic [5:0] x23_toSRAM_11_array;
  logic [9:0] x23_toSRAM_12_addr;
  logic [9:0] x23_toSRAM_12_addr_rd;
  logic [23:0] x23_toSRAM_12_wdata;
  logic [1:0] x23_toSRAM_12_wmask;
  logic x23_toSRAM_12_re;
  logic x23_toSRAM_12_we;
  logic x23_toSRAM_12_ack;
  logic x23_toSRAM_12_selectedOH;
  logic [5:0] x23_toSRAM_12_array;
  logic [9:0] x23_toSRAM_13_addr;
  logic [9:0] x23_toSRAM_13_addr_rd;
  logic [23:0] x23_toSRAM_13_wdata;
  logic [1:0] x23_toSRAM_13_wmask;
  logic x23_toSRAM_13_re;
  logic x23_toSRAM_13_we;
  logic x23_toSRAM_13_ack;
  logic x23_toSRAM_13_selectedOH;
  logic [5:0] x23_toSRAM_13_array;
  logic [9:0] x23_toSRAM_14_addr;
  logic [9:0] x23_toSRAM_14_addr_rd;
  logic [23:0] x23_toSRAM_14_wdata;
  logic [1:0] x23_toSRAM_14_wmask;
  logic x23_toSRAM_14_re;
  logic x23_toSRAM_14_we;
  logic x23_toSRAM_14_ack;
  logic x23_toSRAM_14_selectedOH;
  logic [5:0] x23_toSRAM_14_array;
  logic [8:0] x23_toSRAM_15_addr;
  logic [8:0] x23_toSRAM_15_addr_rd;
  logic [15:0] x23_toSRAM_15_wdata;
  logic [15:0] x23_toSRAM_15_wmask;
  logic x23_toSRAM_15_re;
  logic x23_toSRAM_15_we;
  logic x23_toSRAM_15_ack;
  logic x23_toSRAM_15_selectedOH;
  logic [5:0] x23_toSRAM_15_array;
  logic [9:0] x23_toSRAM_16_addr;
  logic [9:0] x23_toSRAM_16_addr_rd;
  logic [23:0] x23_toSRAM_16_wdata;
  logic [1:0] x23_toSRAM_16_wmask;
  logic x23_toSRAM_16_re;
  logic x23_toSRAM_16_we;
  logic x23_toSRAM_16_ack;
  logic x23_toSRAM_16_selectedOH;
  logic [5:0] x23_toSRAM_16_array;
  logic [9:0] x23_toSRAM_17_addr;
  logic [9:0] x23_toSRAM_17_addr_rd;
  logic [23:0] x23_toSRAM_17_wdata;
  logic [1:0] x23_toSRAM_17_wmask;
  logic x23_toSRAM_17_re;
  logic x23_toSRAM_17_we;
  logic x23_toSRAM_17_ack;
  logic x23_toSRAM_17_selectedOH;
  logic [5:0] x23_toSRAM_17_array;
  logic [9:0] x23_toSRAM_18_addr;
  logic [9:0] x23_toSRAM_18_addr_rd;
  logic [23:0] x23_toSRAM_18_wdata;
  logic [1:0] x23_toSRAM_18_wmask;
  logic x23_toSRAM_18_re;
  logic x23_toSRAM_18_we;
  logic x23_toSRAM_18_ack;
  logic x23_toSRAM_18_selectedOH;
  logic [5:0] x23_toSRAM_18_array;
  logic [9:0] x23_toSRAM_19_addr;
  logic [9:0] x23_toSRAM_19_addr_rd;
  logic [23:0] x23_toSRAM_19_wdata;
  logic [1:0] x23_toSRAM_19_wmask;
  logic x23_toSRAM_19_re;
  logic x23_toSRAM_19_we;
  logic x23_toSRAM_19_ack;
  logic x23_toSRAM_19_selectedOH;
  logic [5:0] x23_toSRAM_19_array;
  logic [8:0] x23_toSRAM_20_addr;
  logic [8:0] x23_toSRAM_20_addr_rd;
  logic [7:0] x23_toSRAM_20_wdata;
  logic [3:0] x23_toSRAM_20_wmask;
  logic x23_toSRAM_20_re;
  logic x23_toSRAM_20_we;
  logic x23_toSRAM_20_ack;
  logic x23_toSRAM_20_selectedOH;
  logic [6:0] x23_toSRAM_20_array;
  logic [8:0] x23_toSRAM_21_addr;
  logic [8:0] x23_toSRAM_21_addr_rd;
  logic [7:0] x23_toSRAM_21_wdata;
  logic [3:0] x23_toSRAM_21_wmask;
  logic x23_toSRAM_21_re;
  logic x23_toSRAM_21_we;
  logic x23_toSRAM_21_ack;
  logic x23_toSRAM_21_selectedOH;
  logic [6:0] x23_toSRAM_21_array;
  logic [8:0] x23_toSRAM_22_addr;
  logic [8:0] x23_toSRAM_22_addr_rd;
  logic [7:0] x23_toSRAM_22_wdata;
  logic [3:0] x23_toSRAM_22_wmask;
  logic x23_toSRAM_22_re;
  logic x23_toSRAM_22_we;
  logic x23_toSRAM_22_ack;
  logic x23_toSRAM_22_selectedOH;
  logic [6:0] x23_toSRAM_22_array;
  logic [8:0] x23_toSRAM_23_addr;
  logic [8:0] x23_toSRAM_23_addr_rd;
  logic [7:0] x23_toSRAM_23_wdata;
  logic [3:0] x23_toSRAM_23_wmask;
  logic x23_toSRAM_23_re;
  logic x23_toSRAM_23_we;
  logic x23_toSRAM_23_ack;
  logic x23_toSRAM_23_selectedOH;
  logic [6:0] x23_toSRAM_23_array;
  bit [23:0] cov_spread23;
  bit [23:0] cov_od0_23, cov_od1_23;
  bit cov_ack0_23, cov_ack1_23;
  MbistPipeTage u_g23 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[15:0]),
    .mbist_addr (s_addr),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd),
    .toSRAM_0_rdata (v23_rd0),
    .toSRAM_1_rdata (v23_rd1),
    .toSRAM_2_rdata (v23_rd2),
    .toSRAM_3_rdata (v23_rd3),
    .toSRAM_4_rdata (v23_rd4),
    .toSRAM_5_rdata (v23_rd5),
    .toSRAM_6_rdata (v23_rd6),
    .toSRAM_7_rdata (v23_rd7),
    .toSRAM_8_rdata (v23_rd8),
    .toSRAM_9_rdata (v23_rd9),
    .toSRAM_10_rdata (v23_rd10),
    .toSRAM_11_rdata (v23_rd11),
    .toSRAM_12_rdata (v23_rd12),
    .toSRAM_13_rdata (v23_rd13),
    .toSRAM_14_rdata (v23_rd14),
    .toSRAM_15_rdata (v23_rd15),
    .toSRAM_16_rdata (v23_rd16),
    .toSRAM_17_rdata (v23_rd17),
    .toSRAM_18_rdata (v23_rd18),
    .toSRAM_19_rdata (v23_rd19),
    .toSRAM_20_rdata (v23_rd20),
    .toSRAM_21_rdata (v23_rd21),
    .toSRAM_22_rdata (v23_rd22),
    .toSRAM_23_rdata (v23_rd23),
    .mbist_ack (g23_mbist_ack),
    .mbist_outdata (g23_mbist_outdata),
    .toSRAM_0_addr (g23_toSRAM_0_addr),
    .toSRAM_0_addr_rd (g23_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (g23_toSRAM_0_wdata),
    .toSRAM_0_wmask (g23_toSRAM_0_wmask),
    .toSRAM_0_re (g23_toSRAM_0_re),
    .toSRAM_0_we (g23_toSRAM_0_we),
    .toSRAM_0_ack (g23_toSRAM_0_ack),
    .toSRAM_0_selectedOH (g23_toSRAM_0_selectedOH),
    .toSRAM_0_array (g23_toSRAM_0_array),
    .toSRAM_1_addr (g23_toSRAM_1_addr),
    .toSRAM_1_addr_rd (g23_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (g23_toSRAM_1_wdata),
    .toSRAM_1_wmask (g23_toSRAM_1_wmask),
    .toSRAM_1_re (g23_toSRAM_1_re),
    .toSRAM_1_we (g23_toSRAM_1_we),
    .toSRAM_1_ack (g23_toSRAM_1_ack),
    .toSRAM_1_selectedOH (g23_toSRAM_1_selectedOH),
    .toSRAM_1_array (g23_toSRAM_1_array),
    .toSRAM_2_addr (g23_toSRAM_2_addr),
    .toSRAM_2_addr_rd (g23_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (g23_toSRAM_2_wdata),
    .toSRAM_2_wmask (g23_toSRAM_2_wmask),
    .toSRAM_2_re (g23_toSRAM_2_re),
    .toSRAM_2_we (g23_toSRAM_2_we),
    .toSRAM_2_ack (g23_toSRAM_2_ack),
    .toSRAM_2_selectedOH (g23_toSRAM_2_selectedOH),
    .toSRAM_2_array (g23_toSRAM_2_array),
    .toSRAM_3_addr (g23_toSRAM_3_addr),
    .toSRAM_3_addr_rd (g23_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (g23_toSRAM_3_wdata),
    .toSRAM_3_wmask (g23_toSRAM_3_wmask),
    .toSRAM_3_re (g23_toSRAM_3_re),
    .toSRAM_3_we (g23_toSRAM_3_we),
    .toSRAM_3_ack (g23_toSRAM_3_ack),
    .toSRAM_3_selectedOH (g23_toSRAM_3_selectedOH),
    .toSRAM_3_array (g23_toSRAM_3_array),
    .toSRAM_4_addr (g23_toSRAM_4_addr),
    .toSRAM_4_addr_rd (g23_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (g23_toSRAM_4_wdata),
    .toSRAM_4_wmask (g23_toSRAM_4_wmask),
    .toSRAM_4_re (g23_toSRAM_4_re),
    .toSRAM_4_we (g23_toSRAM_4_we),
    .toSRAM_4_ack (g23_toSRAM_4_ack),
    .toSRAM_4_selectedOH (g23_toSRAM_4_selectedOH),
    .toSRAM_4_array (g23_toSRAM_4_array),
    .toSRAM_5_addr (g23_toSRAM_5_addr),
    .toSRAM_5_addr_rd (g23_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (g23_toSRAM_5_wdata),
    .toSRAM_5_wmask (g23_toSRAM_5_wmask),
    .toSRAM_5_re (g23_toSRAM_5_re),
    .toSRAM_5_we (g23_toSRAM_5_we),
    .toSRAM_5_ack (g23_toSRAM_5_ack),
    .toSRAM_5_selectedOH (g23_toSRAM_5_selectedOH),
    .toSRAM_5_array (g23_toSRAM_5_array),
    .toSRAM_6_addr (g23_toSRAM_6_addr),
    .toSRAM_6_addr_rd (g23_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (g23_toSRAM_6_wdata),
    .toSRAM_6_wmask (g23_toSRAM_6_wmask),
    .toSRAM_6_re (g23_toSRAM_6_re),
    .toSRAM_6_we (g23_toSRAM_6_we),
    .toSRAM_6_ack (g23_toSRAM_6_ack),
    .toSRAM_6_selectedOH (g23_toSRAM_6_selectedOH),
    .toSRAM_6_array (g23_toSRAM_6_array),
    .toSRAM_7_addr (g23_toSRAM_7_addr),
    .toSRAM_7_addr_rd (g23_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (g23_toSRAM_7_wdata),
    .toSRAM_7_wmask (g23_toSRAM_7_wmask),
    .toSRAM_7_re (g23_toSRAM_7_re),
    .toSRAM_7_we (g23_toSRAM_7_we),
    .toSRAM_7_ack (g23_toSRAM_7_ack),
    .toSRAM_7_selectedOH (g23_toSRAM_7_selectedOH),
    .toSRAM_7_array (g23_toSRAM_7_array),
    .toSRAM_8_addr (g23_toSRAM_8_addr),
    .toSRAM_8_addr_rd (g23_toSRAM_8_addr_rd),
    .toSRAM_8_wdata (g23_toSRAM_8_wdata),
    .toSRAM_8_wmask (g23_toSRAM_8_wmask),
    .toSRAM_8_re (g23_toSRAM_8_re),
    .toSRAM_8_we (g23_toSRAM_8_we),
    .toSRAM_8_ack (g23_toSRAM_8_ack),
    .toSRAM_8_selectedOH (g23_toSRAM_8_selectedOH),
    .toSRAM_8_array (g23_toSRAM_8_array),
    .toSRAM_9_addr (g23_toSRAM_9_addr),
    .toSRAM_9_addr_rd (g23_toSRAM_9_addr_rd),
    .toSRAM_9_wdata (g23_toSRAM_9_wdata),
    .toSRAM_9_wmask (g23_toSRAM_9_wmask),
    .toSRAM_9_re (g23_toSRAM_9_re),
    .toSRAM_9_we (g23_toSRAM_9_we),
    .toSRAM_9_ack (g23_toSRAM_9_ack),
    .toSRAM_9_selectedOH (g23_toSRAM_9_selectedOH),
    .toSRAM_9_array (g23_toSRAM_9_array),
    .toSRAM_10_addr (g23_toSRAM_10_addr),
    .toSRAM_10_addr_rd (g23_toSRAM_10_addr_rd),
    .toSRAM_10_wdata (g23_toSRAM_10_wdata),
    .toSRAM_10_wmask (g23_toSRAM_10_wmask),
    .toSRAM_10_re (g23_toSRAM_10_re),
    .toSRAM_10_we (g23_toSRAM_10_we),
    .toSRAM_10_ack (g23_toSRAM_10_ack),
    .toSRAM_10_selectedOH (g23_toSRAM_10_selectedOH),
    .toSRAM_10_array (g23_toSRAM_10_array),
    .toSRAM_11_addr (g23_toSRAM_11_addr),
    .toSRAM_11_addr_rd (g23_toSRAM_11_addr_rd),
    .toSRAM_11_wdata (g23_toSRAM_11_wdata),
    .toSRAM_11_wmask (g23_toSRAM_11_wmask),
    .toSRAM_11_re (g23_toSRAM_11_re),
    .toSRAM_11_we (g23_toSRAM_11_we),
    .toSRAM_11_ack (g23_toSRAM_11_ack),
    .toSRAM_11_selectedOH (g23_toSRAM_11_selectedOH),
    .toSRAM_11_array (g23_toSRAM_11_array),
    .toSRAM_12_addr (g23_toSRAM_12_addr),
    .toSRAM_12_addr_rd (g23_toSRAM_12_addr_rd),
    .toSRAM_12_wdata (g23_toSRAM_12_wdata),
    .toSRAM_12_wmask (g23_toSRAM_12_wmask),
    .toSRAM_12_re (g23_toSRAM_12_re),
    .toSRAM_12_we (g23_toSRAM_12_we),
    .toSRAM_12_ack (g23_toSRAM_12_ack),
    .toSRAM_12_selectedOH (g23_toSRAM_12_selectedOH),
    .toSRAM_12_array (g23_toSRAM_12_array),
    .toSRAM_13_addr (g23_toSRAM_13_addr),
    .toSRAM_13_addr_rd (g23_toSRAM_13_addr_rd),
    .toSRAM_13_wdata (g23_toSRAM_13_wdata),
    .toSRAM_13_wmask (g23_toSRAM_13_wmask),
    .toSRAM_13_re (g23_toSRAM_13_re),
    .toSRAM_13_we (g23_toSRAM_13_we),
    .toSRAM_13_ack (g23_toSRAM_13_ack),
    .toSRAM_13_selectedOH (g23_toSRAM_13_selectedOH),
    .toSRAM_13_array (g23_toSRAM_13_array),
    .toSRAM_14_addr (g23_toSRAM_14_addr),
    .toSRAM_14_addr_rd (g23_toSRAM_14_addr_rd),
    .toSRAM_14_wdata (g23_toSRAM_14_wdata),
    .toSRAM_14_wmask (g23_toSRAM_14_wmask),
    .toSRAM_14_re (g23_toSRAM_14_re),
    .toSRAM_14_we (g23_toSRAM_14_we),
    .toSRAM_14_ack (g23_toSRAM_14_ack),
    .toSRAM_14_selectedOH (g23_toSRAM_14_selectedOH),
    .toSRAM_14_array (g23_toSRAM_14_array),
    .toSRAM_15_addr (g23_toSRAM_15_addr),
    .toSRAM_15_addr_rd (g23_toSRAM_15_addr_rd),
    .toSRAM_15_wdata (g23_toSRAM_15_wdata),
    .toSRAM_15_wmask (g23_toSRAM_15_wmask),
    .toSRAM_15_re (g23_toSRAM_15_re),
    .toSRAM_15_we (g23_toSRAM_15_we),
    .toSRAM_15_ack (g23_toSRAM_15_ack),
    .toSRAM_15_selectedOH (g23_toSRAM_15_selectedOH),
    .toSRAM_15_array (g23_toSRAM_15_array),
    .toSRAM_16_addr (g23_toSRAM_16_addr),
    .toSRAM_16_addr_rd (g23_toSRAM_16_addr_rd),
    .toSRAM_16_wdata (g23_toSRAM_16_wdata),
    .toSRAM_16_wmask (g23_toSRAM_16_wmask),
    .toSRAM_16_re (g23_toSRAM_16_re),
    .toSRAM_16_we (g23_toSRAM_16_we),
    .toSRAM_16_ack (g23_toSRAM_16_ack),
    .toSRAM_16_selectedOH (g23_toSRAM_16_selectedOH),
    .toSRAM_16_array (g23_toSRAM_16_array),
    .toSRAM_17_addr (g23_toSRAM_17_addr),
    .toSRAM_17_addr_rd (g23_toSRAM_17_addr_rd),
    .toSRAM_17_wdata (g23_toSRAM_17_wdata),
    .toSRAM_17_wmask (g23_toSRAM_17_wmask),
    .toSRAM_17_re (g23_toSRAM_17_re),
    .toSRAM_17_we (g23_toSRAM_17_we),
    .toSRAM_17_ack (g23_toSRAM_17_ack),
    .toSRAM_17_selectedOH (g23_toSRAM_17_selectedOH),
    .toSRAM_17_array (g23_toSRAM_17_array),
    .toSRAM_18_addr (g23_toSRAM_18_addr),
    .toSRAM_18_addr_rd (g23_toSRAM_18_addr_rd),
    .toSRAM_18_wdata (g23_toSRAM_18_wdata),
    .toSRAM_18_wmask (g23_toSRAM_18_wmask),
    .toSRAM_18_re (g23_toSRAM_18_re),
    .toSRAM_18_we (g23_toSRAM_18_we),
    .toSRAM_18_ack (g23_toSRAM_18_ack),
    .toSRAM_18_selectedOH (g23_toSRAM_18_selectedOH),
    .toSRAM_18_array (g23_toSRAM_18_array),
    .toSRAM_19_addr (g23_toSRAM_19_addr),
    .toSRAM_19_addr_rd (g23_toSRAM_19_addr_rd),
    .toSRAM_19_wdata (g23_toSRAM_19_wdata),
    .toSRAM_19_wmask (g23_toSRAM_19_wmask),
    .toSRAM_19_re (g23_toSRAM_19_re),
    .toSRAM_19_we (g23_toSRAM_19_we),
    .toSRAM_19_ack (g23_toSRAM_19_ack),
    .toSRAM_19_selectedOH (g23_toSRAM_19_selectedOH),
    .toSRAM_19_array (g23_toSRAM_19_array),
    .toSRAM_20_addr (g23_toSRAM_20_addr),
    .toSRAM_20_addr_rd (g23_toSRAM_20_addr_rd),
    .toSRAM_20_wdata (g23_toSRAM_20_wdata),
    .toSRAM_20_wmask (g23_toSRAM_20_wmask),
    .toSRAM_20_re (g23_toSRAM_20_re),
    .toSRAM_20_we (g23_toSRAM_20_we),
    .toSRAM_20_ack (g23_toSRAM_20_ack),
    .toSRAM_20_selectedOH (g23_toSRAM_20_selectedOH),
    .toSRAM_20_array (g23_toSRAM_20_array),
    .toSRAM_21_addr (g23_toSRAM_21_addr),
    .toSRAM_21_addr_rd (g23_toSRAM_21_addr_rd),
    .toSRAM_21_wdata (g23_toSRAM_21_wdata),
    .toSRAM_21_wmask (g23_toSRAM_21_wmask),
    .toSRAM_21_re (g23_toSRAM_21_re),
    .toSRAM_21_we (g23_toSRAM_21_we),
    .toSRAM_21_ack (g23_toSRAM_21_ack),
    .toSRAM_21_selectedOH (g23_toSRAM_21_selectedOH),
    .toSRAM_21_array (g23_toSRAM_21_array),
    .toSRAM_22_addr (g23_toSRAM_22_addr),
    .toSRAM_22_addr_rd (g23_toSRAM_22_addr_rd),
    .toSRAM_22_wdata (g23_toSRAM_22_wdata),
    .toSRAM_22_wmask (g23_toSRAM_22_wmask),
    .toSRAM_22_re (g23_toSRAM_22_re),
    .toSRAM_22_we (g23_toSRAM_22_we),
    .toSRAM_22_ack (g23_toSRAM_22_ack),
    .toSRAM_22_selectedOH (g23_toSRAM_22_selectedOH),
    .toSRAM_22_array (g23_toSRAM_22_array),
    .toSRAM_23_addr (g23_toSRAM_23_addr),
    .toSRAM_23_addr_rd (g23_toSRAM_23_addr_rd),
    .toSRAM_23_wdata (g23_toSRAM_23_wdata),
    .toSRAM_23_wmask (g23_toSRAM_23_wmask),
    .toSRAM_23_re (g23_toSRAM_23_re),
    .toSRAM_23_we (g23_toSRAM_23_we),
    .toSRAM_23_ack (g23_toSRAM_23_ack),
    .toSRAM_23_selectedOH (g23_toSRAM_23_selectedOH),
    .toSRAM_23_array (g23_toSRAM_23_array)
  );
  MbistPipeTage_xs u_x23 (
    .clock (clock), .reset (reset),
    .mbist_array (s_array),
    .mbist_all (s_all),
    .mbist_req (s_req),
    .mbist_writeen (s_wen),
    .mbist_be (s_be[15:0]),
    .mbist_addr (s_addr),
    .mbist_indata (s_indata[23:0]),
    .mbist_readen (s_ren),
    .mbist_addr_rd (s_addr_rd),
    .toSRAM_0_rdata (v23_rd0),
    .toSRAM_1_rdata (v23_rd1),
    .toSRAM_2_rdata (v23_rd2),
    .toSRAM_3_rdata (v23_rd3),
    .toSRAM_4_rdata (v23_rd4),
    .toSRAM_5_rdata (v23_rd5),
    .toSRAM_6_rdata (v23_rd6),
    .toSRAM_7_rdata (v23_rd7),
    .toSRAM_8_rdata (v23_rd8),
    .toSRAM_9_rdata (v23_rd9),
    .toSRAM_10_rdata (v23_rd10),
    .toSRAM_11_rdata (v23_rd11),
    .toSRAM_12_rdata (v23_rd12),
    .toSRAM_13_rdata (v23_rd13),
    .toSRAM_14_rdata (v23_rd14),
    .toSRAM_15_rdata (v23_rd15),
    .toSRAM_16_rdata (v23_rd16),
    .toSRAM_17_rdata (v23_rd17),
    .toSRAM_18_rdata (v23_rd18),
    .toSRAM_19_rdata (v23_rd19),
    .toSRAM_20_rdata (v23_rd20),
    .toSRAM_21_rdata (v23_rd21),
    .toSRAM_22_rdata (v23_rd22),
    .toSRAM_23_rdata (v23_rd23),
    .mbist_ack (x23_mbist_ack),
    .mbist_outdata (x23_mbist_outdata),
    .toSRAM_0_addr (x23_toSRAM_0_addr),
    .toSRAM_0_addr_rd (x23_toSRAM_0_addr_rd),
    .toSRAM_0_wdata (x23_toSRAM_0_wdata),
    .toSRAM_0_wmask (x23_toSRAM_0_wmask),
    .toSRAM_0_re (x23_toSRAM_0_re),
    .toSRAM_0_we (x23_toSRAM_0_we),
    .toSRAM_0_ack (x23_toSRAM_0_ack),
    .toSRAM_0_selectedOH (x23_toSRAM_0_selectedOH),
    .toSRAM_0_array (x23_toSRAM_0_array),
    .toSRAM_1_addr (x23_toSRAM_1_addr),
    .toSRAM_1_addr_rd (x23_toSRAM_1_addr_rd),
    .toSRAM_1_wdata (x23_toSRAM_1_wdata),
    .toSRAM_1_wmask (x23_toSRAM_1_wmask),
    .toSRAM_1_re (x23_toSRAM_1_re),
    .toSRAM_1_we (x23_toSRAM_1_we),
    .toSRAM_1_ack (x23_toSRAM_1_ack),
    .toSRAM_1_selectedOH (x23_toSRAM_1_selectedOH),
    .toSRAM_1_array (x23_toSRAM_1_array),
    .toSRAM_2_addr (x23_toSRAM_2_addr),
    .toSRAM_2_addr_rd (x23_toSRAM_2_addr_rd),
    .toSRAM_2_wdata (x23_toSRAM_2_wdata),
    .toSRAM_2_wmask (x23_toSRAM_2_wmask),
    .toSRAM_2_re (x23_toSRAM_2_re),
    .toSRAM_2_we (x23_toSRAM_2_we),
    .toSRAM_2_ack (x23_toSRAM_2_ack),
    .toSRAM_2_selectedOH (x23_toSRAM_2_selectedOH),
    .toSRAM_2_array (x23_toSRAM_2_array),
    .toSRAM_3_addr (x23_toSRAM_3_addr),
    .toSRAM_3_addr_rd (x23_toSRAM_3_addr_rd),
    .toSRAM_3_wdata (x23_toSRAM_3_wdata),
    .toSRAM_3_wmask (x23_toSRAM_3_wmask),
    .toSRAM_3_re (x23_toSRAM_3_re),
    .toSRAM_3_we (x23_toSRAM_3_we),
    .toSRAM_3_ack (x23_toSRAM_3_ack),
    .toSRAM_3_selectedOH (x23_toSRAM_3_selectedOH),
    .toSRAM_3_array (x23_toSRAM_3_array),
    .toSRAM_4_addr (x23_toSRAM_4_addr),
    .toSRAM_4_addr_rd (x23_toSRAM_4_addr_rd),
    .toSRAM_4_wdata (x23_toSRAM_4_wdata),
    .toSRAM_4_wmask (x23_toSRAM_4_wmask),
    .toSRAM_4_re (x23_toSRAM_4_re),
    .toSRAM_4_we (x23_toSRAM_4_we),
    .toSRAM_4_ack (x23_toSRAM_4_ack),
    .toSRAM_4_selectedOH (x23_toSRAM_4_selectedOH),
    .toSRAM_4_array (x23_toSRAM_4_array),
    .toSRAM_5_addr (x23_toSRAM_5_addr),
    .toSRAM_5_addr_rd (x23_toSRAM_5_addr_rd),
    .toSRAM_5_wdata (x23_toSRAM_5_wdata),
    .toSRAM_5_wmask (x23_toSRAM_5_wmask),
    .toSRAM_5_re (x23_toSRAM_5_re),
    .toSRAM_5_we (x23_toSRAM_5_we),
    .toSRAM_5_ack (x23_toSRAM_5_ack),
    .toSRAM_5_selectedOH (x23_toSRAM_5_selectedOH),
    .toSRAM_5_array (x23_toSRAM_5_array),
    .toSRAM_6_addr (x23_toSRAM_6_addr),
    .toSRAM_6_addr_rd (x23_toSRAM_6_addr_rd),
    .toSRAM_6_wdata (x23_toSRAM_6_wdata),
    .toSRAM_6_wmask (x23_toSRAM_6_wmask),
    .toSRAM_6_re (x23_toSRAM_6_re),
    .toSRAM_6_we (x23_toSRAM_6_we),
    .toSRAM_6_ack (x23_toSRAM_6_ack),
    .toSRAM_6_selectedOH (x23_toSRAM_6_selectedOH),
    .toSRAM_6_array (x23_toSRAM_6_array),
    .toSRAM_7_addr (x23_toSRAM_7_addr),
    .toSRAM_7_addr_rd (x23_toSRAM_7_addr_rd),
    .toSRAM_7_wdata (x23_toSRAM_7_wdata),
    .toSRAM_7_wmask (x23_toSRAM_7_wmask),
    .toSRAM_7_re (x23_toSRAM_7_re),
    .toSRAM_7_we (x23_toSRAM_7_we),
    .toSRAM_7_ack (x23_toSRAM_7_ack),
    .toSRAM_7_selectedOH (x23_toSRAM_7_selectedOH),
    .toSRAM_7_array (x23_toSRAM_7_array),
    .toSRAM_8_addr (x23_toSRAM_8_addr),
    .toSRAM_8_addr_rd (x23_toSRAM_8_addr_rd),
    .toSRAM_8_wdata (x23_toSRAM_8_wdata),
    .toSRAM_8_wmask (x23_toSRAM_8_wmask),
    .toSRAM_8_re (x23_toSRAM_8_re),
    .toSRAM_8_we (x23_toSRAM_8_we),
    .toSRAM_8_ack (x23_toSRAM_8_ack),
    .toSRAM_8_selectedOH (x23_toSRAM_8_selectedOH),
    .toSRAM_8_array (x23_toSRAM_8_array),
    .toSRAM_9_addr (x23_toSRAM_9_addr),
    .toSRAM_9_addr_rd (x23_toSRAM_9_addr_rd),
    .toSRAM_9_wdata (x23_toSRAM_9_wdata),
    .toSRAM_9_wmask (x23_toSRAM_9_wmask),
    .toSRAM_9_re (x23_toSRAM_9_re),
    .toSRAM_9_we (x23_toSRAM_9_we),
    .toSRAM_9_ack (x23_toSRAM_9_ack),
    .toSRAM_9_selectedOH (x23_toSRAM_9_selectedOH),
    .toSRAM_9_array (x23_toSRAM_9_array),
    .toSRAM_10_addr (x23_toSRAM_10_addr),
    .toSRAM_10_addr_rd (x23_toSRAM_10_addr_rd),
    .toSRAM_10_wdata (x23_toSRAM_10_wdata),
    .toSRAM_10_wmask (x23_toSRAM_10_wmask),
    .toSRAM_10_re (x23_toSRAM_10_re),
    .toSRAM_10_we (x23_toSRAM_10_we),
    .toSRAM_10_ack (x23_toSRAM_10_ack),
    .toSRAM_10_selectedOH (x23_toSRAM_10_selectedOH),
    .toSRAM_10_array (x23_toSRAM_10_array),
    .toSRAM_11_addr (x23_toSRAM_11_addr),
    .toSRAM_11_addr_rd (x23_toSRAM_11_addr_rd),
    .toSRAM_11_wdata (x23_toSRAM_11_wdata),
    .toSRAM_11_wmask (x23_toSRAM_11_wmask),
    .toSRAM_11_re (x23_toSRAM_11_re),
    .toSRAM_11_we (x23_toSRAM_11_we),
    .toSRAM_11_ack (x23_toSRAM_11_ack),
    .toSRAM_11_selectedOH (x23_toSRAM_11_selectedOH),
    .toSRAM_11_array (x23_toSRAM_11_array),
    .toSRAM_12_addr (x23_toSRAM_12_addr),
    .toSRAM_12_addr_rd (x23_toSRAM_12_addr_rd),
    .toSRAM_12_wdata (x23_toSRAM_12_wdata),
    .toSRAM_12_wmask (x23_toSRAM_12_wmask),
    .toSRAM_12_re (x23_toSRAM_12_re),
    .toSRAM_12_we (x23_toSRAM_12_we),
    .toSRAM_12_ack (x23_toSRAM_12_ack),
    .toSRAM_12_selectedOH (x23_toSRAM_12_selectedOH),
    .toSRAM_12_array (x23_toSRAM_12_array),
    .toSRAM_13_addr (x23_toSRAM_13_addr),
    .toSRAM_13_addr_rd (x23_toSRAM_13_addr_rd),
    .toSRAM_13_wdata (x23_toSRAM_13_wdata),
    .toSRAM_13_wmask (x23_toSRAM_13_wmask),
    .toSRAM_13_re (x23_toSRAM_13_re),
    .toSRAM_13_we (x23_toSRAM_13_we),
    .toSRAM_13_ack (x23_toSRAM_13_ack),
    .toSRAM_13_selectedOH (x23_toSRAM_13_selectedOH),
    .toSRAM_13_array (x23_toSRAM_13_array),
    .toSRAM_14_addr (x23_toSRAM_14_addr),
    .toSRAM_14_addr_rd (x23_toSRAM_14_addr_rd),
    .toSRAM_14_wdata (x23_toSRAM_14_wdata),
    .toSRAM_14_wmask (x23_toSRAM_14_wmask),
    .toSRAM_14_re (x23_toSRAM_14_re),
    .toSRAM_14_we (x23_toSRAM_14_we),
    .toSRAM_14_ack (x23_toSRAM_14_ack),
    .toSRAM_14_selectedOH (x23_toSRAM_14_selectedOH),
    .toSRAM_14_array (x23_toSRAM_14_array),
    .toSRAM_15_addr (x23_toSRAM_15_addr),
    .toSRAM_15_addr_rd (x23_toSRAM_15_addr_rd),
    .toSRAM_15_wdata (x23_toSRAM_15_wdata),
    .toSRAM_15_wmask (x23_toSRAM_15_wmask),
    .toSRAM_15_re (x23_toSRAM_15_re),
    .toSRAM_15_we (x23_toSRAM_15_we),
    .toSRAM_15_ack (x23_toSRAM_15_ack),
    .toSRAM_15_selectedOH (x23_toSRAM_15_selectedOH),
    .toSRAM_15_array (x23_toSRAM_15_array),
    .toSRAM_16_addr (x23_toSRAM_16_addr),
    .toSRAM_16_addr_rd (x23_toSRAM_16_addr_rd),
    .toSRAM_16_wdata (x23_toSRAM_16_wdata),
    .toSRAM_16_wmask (x23_toSRAM_16_wmask),
    .toSRAM_16_re (x23_toSRAM_16_re),
    .toSRAM_16_we (x23_toSRAM_16_we),
    .toSRAM_16_ack (x23_toSRAM_16_ack),
    .toSRAM_16_selectedOH (x23_toSRAM_16_selectedOH),
    .toSRAM_16_array (x23_toSRAM_16_array),
    .toSRAM_17_addr (x23_toSRAM_17_addr),
    .toSRAM_17_addr_rd (x23_toSRAM_17_addr_rd),
    .toSRAM_17_wdata (x23_toSRAM_17_wdata),
    .toSRAM_17_wmask (x23_toSRAM_17_wmask),
    .toSRAM_17_re (x23_toSRAM_17_re),
    .toSRAM_17_we (x23_toSRAM_17_we),
    .toSRAM_17_ack (x23_toSRAM_17_ack),
    .toSRAM_17_selectedOH (x23_toSRAM_17_selectedOH),
    .toSRAM_17_array (x23_toSRAM_17_array),
    .toSRAM_18_addr (x23_toSRAM_18_addr),
    .toSRAM_18_addr_rd (x23_toSRAM_18_addr_rd),
    .toSRAM_18_wdata (x23_toSRAM_18_wdata),
    .toSRAM_18_wmask (x23_toSRAM_18_wmask),
    .toSRAM_18_re (x23_toSRAM_18_re),
    .toSRAM_18_we (x23_toSRAM_18_we),
    .toSRAM_18_ack (x23_toSRAM_18_ack),
    .toSRAM_18_selectedOH (x23_toSRAM_18_selectedOH),
    .toSRAM_18_array (x23_toSRAM_18_array),
    .toSRAM_19_addr (x23_toSRAM_19_addr),
    .toSRAM_19_addr_rd (x23_toSRAM_19_addr_rd),
    .toSRAM_19_wdata (x23_toSRAM_19_wdata),
    .toSRAM_19_wmask (x23_toSRAM_19_wmask),
    .toSRAM_19_re (x23_toSRAM_19_re),
    .toSRAM_19_we (x23_toSRAM_19_we),
    .toSRAM_19_ack (x23_toSRAM_19_ack),
    .toSRAM_19_selectedOH (x23_toSRAM_19_selectedOH),
    .toSRAM_19_array (x23_toSRAM_19_array),
    .toSRAM_20_addr (x23_toSRAM_20_addr),
    .toSRAM_20_addr_rd (x23_toSRAM_20_addr_rd),
    .toSRAM_20_wdata (x23_toSRAM_20_wdata),
    .toSRAM_20_wmask (x23_toSRAM_20_wmask),
    .toSRAM_20_re (x23_toSRAM_20_re),
    .toSRAM_20_we (x23_toSRAM_20_we),
    .toSRAM_20_ack (x23_toSRAM_20_ack),
    .toSRAM_20_selectedOH (x23_toSRAM_20_selectedOH),
    .toSRAM_20_array (x23_toSRAM_20_array),
    .toSRAM_21_addr (x23_toSRAM_21_addr),
    .toSRAM_21_addr_rd (x23_toSRAM_21_addr_rd),
    .toSRAM_21_wdata (x23_toSRAM_21_wdata),
    .toSRAM_21_wmask (x23_toSRAM_21_wmask),
    .toSRAM_21_re (x23_toSRAM_21_re),
    .toSRAM_21_we (x23_toSRAM_21_we),
    .toSRAM_21_ack (x23_toSRAM_21_ack),
    .toSRAM_21_selectedOH (x23_toSRAM_21_selectedOH),
    .toSRAM_21_array (x23_toSRAM_21_array),
    .toSRAM_22_addr (x23_toSRAM_22_addr),
    .toSRAM_22_addr_rd (x23_toSRAM_22_addr_rd),
    .toSRAM_22_wdata (x23_toSRAM_22_wdata),
    .toSRAM_22_wmask (x23_toSRAM_22_wmask),
    .toSRAM_22_re (x23_toSRAM_22_re),
    .toSRAM_22_we (x23_toSRAM_22_we),
    .toSRAM_22_ack (x23_toSRAM_22_ack),
    .toSRAM_22_selectedOH (x23_toSRAM_22_selectedOH),
    .toSRAM_22_array (x23_toSRAM_22_array),
    .toSRAM_23_addr (x23_toSRAM_23_addr),
    .toSRAM_23_addr_rd (x23_toSRAM_23_addr_rd),
    .toSRAM_23_wdata (x23_toSRAM_23_wdata),
    .toSRAM_23_wmask (x23_toSRAM_23_wmask),
    .toSRAM_23_re (x23_toSRAM_23_re),
    .toSRAM_23_we (x23_toSRAM_23_we),
    .toSRAM_23_ack (x23_toSRAM_23_ack),
    .toSRAM_23_selectedOH (x23_toSRAM_23_selectedOH),
    .toSRAM_23_array (x23_toSRAM_23_array)
  );
  wire [1324:0] gbus23 = {g23_mbist_ack, g23_mbist_outdata, g23_toSRAM_0_addr, g23_toSRAM_0_addr_rd, g23_toSRAM_0_wdata, g23_toSRAM_0_wmask, g23_toSRAM_0_re, g23_toSRAM_0_we, g23_toSRAM_0_ack, g23_toSRAM_0_selectedOH, g23_toSRAM_0_array, g23_toSRAM_1_addr, g23_toSRAM_1_addr_rd, g23_toSRAM_1_wdata, g23_toSRAM_1_wmask, g23_toSRAM_1_re, g23_toSRAM_1_we, g23_toSRAM_1_ack, g23_toSRAM_1_selectedOH, g23_toSRAM_1_array, g23_toSRAM_2_addr, g23_toSRAM_2_addr_rd, g23_toSRAM_2_wdata, g23_toSRAM_2_wmask, g23_toSRAM_2_re, g23_toSRAM_2_we, g23_toSRAM_2_ack, g23_toSRAM_2_selectedOH, g23_toSRAM_2_array, g23_toSRAM_3_addr, g23_toSRAM_3_addr_rd, g23_toSRAM_3_wdata, g23_toSRAM_3_wmask, g23_toSRAM_3_re, g23_toSRAM_3_we, g23_toSRAM_3_ack, g23_toSRAM_3_selectedOH, g23_toSRAM_3_array, g23_toSRAM_4_addr, g23_toSRAM_4_addr_rd, g23_toSRAM_4_wdata, g23_toSRAM_4_wmask, g23_toSRAM_4_re, g23_toSRAM_4_we, g23_toSRAM_4_ack, g23_toSRAM_4_selectedOH, g23_toSRAM_4_array, g23_toSRAM_5_addr, g23_toSRAM_5_addr_rd, g23_toSRAM_5_wdata, g23_toSRAM_5_wmask, g23_toSRAM_5_re, g23_toSRAM_5_we, g23_toSRAM_5_ack, g23_toSRAM_5_selectedOH, g23_toSRAM_5_array, g23_toSRAM_6_addr, g23_toSRAM_6_addr_rd, g23_toSRAM_6_wdata, g23_toSRAM_6_wmask, g23_toSRAM_6_re, g23_toSRAM_6_we, g23_toSRAM_6_ack, g23_toSRAM_6_selectedOH, g23_toSRAM_6_array, g23_toSRAM_7_addr, g23_toSRAM_7_addr_rd, g23_toSRAM_7_wdata, g23_toSRAM_7_wmask, g23_toSRAM_7_re, g23_toSRAM_7_we, g23_toSRAM_7_ack, g23_toSRAM_7_selectedOH, g23_toSRAM_7_array, g23_toSRAM_8_addr, g23_toSRAM_8_addr_rd, g23_toSRAM_8_wdata, g23_toSRAM_8_wmask, g23_toSRAM_8_re, g23_toSRAM_8_we, g23_toSRAM_8_ack, g23_toSRAM_8_selectedOH, g23_toSRAM_8_array, g23_toSRAM_9_addr, g23_toSRAM_9_addr_rd, g23_toSRAM_9_wdata, g23_toSRAM_9_wmask, g23_toSRAM_9_re, g23_toSRAM_9_we, g23_toSRAM_9_ack, g23_toSRAM_9_selectedOH, g23_toSRAM_9_array, g23_toSRAM_10_addr, g23_toSRAM_10_addr_rd, g23_toSRAM_10_wdata, g23_toSRAM_10_wmask, g23_toSRAM_10_re, g23_toSRAM_10_we, g23_toSRAM_10_ack, g23_toSRAM_10_selectedOH, g23_toSRAM_10_array, g23_toSRAM_11_addr, g23_toSRAM_11_addr_rd, g23_toSRAM_11_wdata, g23_toSRAM_11_wmask, g23_toSRAM_11_re, g23_toSRAM_11_we, g23_toSRAM_11_ack, g23_toSRAM_11_selectedOH, g23_toSRAM_11_array, g23_toSRAM_12_addr, g23_toSRAM_12_addr_rd, g23_toSRAM_12_wdata, g23_toSRAM_12_wmask, g23_toSRAM_12_re, g23_toSRAM_12_we, g23_toSRAM_12_ack, g23_toSRAM_12_selectedOH, g23_toSRAM_12_array, g23_toSRAM_13_addr, g23_toSRAM_13_addr_rd, g23_toSRAM_13_wdata, g23_toSRAM_13_wmask, g23_toSRAM_13_re, g23_toSRAM_13_we, g23_toSRAM_13_ack, g23_toSRAM_13_selectedOH, g23_toSRAM_13_array, g23_toSRAM_14_addr, g23_toSRAM_14_addr_rd, g23_toSRAM_14_wdata, g23_toSRAM_14_wmask, g23_toSRAM_14_re, g23_toSRAM_14_we, g23_toSRAM_14_ack, g23_toSRAM_14_selectedOH, g23_toSRAM_14_array, g23_toSRAM_15_addr, g23_toSRAM_15_addr_rd, g23_toSRAM_15_wdata, g23_toSRAM_15_wmask, g23_toSRAM_15_re, g23_toSRAM_15_we, g23_toSRAM_15_ack, g23_toSRAM_15_selectedOH, g23_toSRAM_15_array, g23_toSRAM_16_addr, g23_toSRAM_16_addr_rd, g23_toSRAM_16_wdata, g23_toSRAM_16_wmask, g23_toSRAM_16_re, g23_toSRAM_16_we, g23_toSRAM_16_ack, g23_toSRAM_16_selectedOH, g23_toSRAM_16_array, g23_toSRAM_17_addr, g23_toSRAM_17_addr_rd, g23_toSRAM_17_wdata, g23_toSRAM_17_wmask, g23_toSRAM_17_re, g23_toSRAM_17_we, g23_toSRAM_17_ack, g23_toSRAM_17_selectedOH, g23_toSRAM_17_array, g23_toSRAM_18_addr, g23_toSRAM_18_addr_rd, g23_toSRAM_18_wdata, g23_toSRAM_18_wmask, g23_toSRAM_18_re, g23_toSRAM_18_we, g23_toSRAM_18_ack, g23_toSRAM_18_selectedOH, g23_toSRAM_18_array, g23_toSRAM_19_addr, g23_toSRAM_19_addr_rd, g23_toSRAM_19_wdata, g23_toSRAM_19_wmask, g23_toSRAM_19_re, g23_toSRAM_19_we, g23_toSRAM_19_ack, g23_toSRAM_19_selectedOH, g23_toSRAM_19_array, g23_toSRAM_20_addr, g23_toSRAM_20_addr_rd, g23_toSRAM_20_wdata, g23_toSRAM_20_wmask, g23_toSRAM_20_re, g23_toSRAM_20_we, g23_toSRAM_20_ack, g23_toSRAM_20_selectedOH, g23_toSRAM_20_array, g23_toSRAM_21_addr, g23_toSRAM_21_addr_rd, g23_toSRAM_21_wdata, g23_toSRAM_21_wmask, g23_toSRAM_21_re, g23_toSRAM_21_we, g23_toSRAM_21_ack, g23_toSRAM_21_selectedOH, g23_toSRAM_21_array, g23_toSRAM_22_addr, g23_toSRAM_22_addr_rd, g23_toSRAM_22_wdata, g23_toSRAM_22_wmask, g23_toSRAM_22_re, g23_toSRAM_22_we, g23_toSRAM_22_ack, g23_toSRAM_22_selectedOH, g23_toSRAM_22_array, g23_toSRAM_23_addr, g23_toSRAM_23_addr_rd, g23_toSRAM_23_wdata, g23_toSRAM_23_wmask, g23_toSRAM_23_re, g23_toSRAM_23_we, g23_toSRAM_23_ack, g23_toSRAM_23_selectedOH, g23_toSRAM_23_array};
  wire [1324:0] xbus23 = {x23_mbist_ack, x23_mbist_outdata, x23_toSRAM_0_addr, x23_toSRAM_0_addr_rd, x23_toSRAM_0_wdata, x23_toSRAM_0_wmask, x23_toSRAM_0_re, x23_toSRAM_0_we, x23_toSRAM_0_ack, x23_toSRAM_0_selectedOH, x23_toSRAM_0_array, x23_toSRAM_1_addr, x23_toSRAM_1_addr_rd, x23_toSRAM_1_wdata, x23_toSRAM_1_wmask, x23_toSRAM_1_re, x23_toSRAM_1_we, x23_toSRAM_1_ack, x23_toSRAM_1_selectedOH, x23_toSRAM_1_array, x23_toSRAM_2_addr, x23_toSRAM_2_addr_rd, x23_toSRAM_2_wdata, x23_toSRAM_2_wmask, x23_toSRAM_2_re, x23_toSRAM_2_we, x23_toSRAM_2_ack, x23_toSRAM_2_selectedOH, x23_toSRAM_2_array, x23_toSRAM_3_addr, x23_toSRAM_3_addr_rd, x23_toSRAM_3_wdata, x23_toSRAM_3_wmask, x23_toSRAM_3_re, x23_toSRAM_3_we, x23_toSRAM_3_ack, x23_toSRAM_3_selectedOH, x23_toSRAM_3_array, x23_toSRAM_4_addr, x23_toSRAM_4_addr_rd, x23_toSRAM_4_wdata, x23_toSRAM_4_wmask, x23_toSRAM_4_re, x23_toSRAM_4_we, x23_toSRAM_4_ack, x23_toSRAM_4_selectedOH, x23_toSRAM_4_array, x23_toSRAM_5_addr, x23_toSRAM_5_addr_rd, x23_toSRAM_5_wdata, x23_toSRAM_5_wmask, x23_toSRAM_5_re, x23_toSRAM_5_we, x23_toSRAM_5_ack, x23_toSRAM_5_selectedOH, x23_toSRAM_5_array, x23_toSRAM_6_addr, x23_toSRAM_6_addr_rd, x23_toSRAM_6_wdata, x23_toSRAM_6_wmask, x23_toSRAM_6_re, x23_toSRAM_6_we, x23_toSRAM_6_ack, x23_toSRAM_6_selectedOH, x23_toSRAM_6_array, x23_toSRAM_7_addr, x23_toSRAM_7_addr_rd, x23_toSRAM_7_wdata, x23_toSRAM_7_wmask, x23_toSRAM_7_re, x23_toSRAM_7_we, x23_toSRAM_7_ack, x23_toSRAM_7_selectedOH, x23_toSRAM_7_array, x23_toSRAM_8_addr, x23_toSRAM_8_addr_rd, x23_toSRAM_8_wdata, x23_toSRAM_8_wmask, x23_toSRAM_8_re, x23_toSRAM_8_we, x23_toSRAM_8_ack, x23_toSRAM_8_selectedOH, x23_toSRAM_8_array, x23_toSRAM_9_addr, x23_toSRAM_9_addr_rd, x23_toSRAM_9_wdata, x23_toSRAM_9_wmask, x23_toSRAM_9_re, x23_toSRAM_9_we, x23_toSRAM_9_ack, x23_toSRAM_9_selectedOH, x23_toSRAM_9_array, x23_toSRAM_10_addr, x23_toSRAM_10_addr_rd, x23_toSRAM_10_wdata, x23_toSRAM_10_wmask, x23_toSRAM_10_re, x23_toSRAM_10_we, x23_toSRAM_10_ack, x23_toSRAM_10_selectedOH, x23_toSRAM_10_array, x23_toSRAM_11_addr, x23_toSRAM_11_addr_rd, x23_toSRAM_11_wdata, x23_toSRAM_11_wmask, x23_toSRAM_11_re, x23_toSRAM_11_we, x23_toSRAM_11_ack, x23_toSRAM_11_selectedOH, x23_toSRAM_11_array, x23_toSRAM_12_addr, x23_toSRAM_12_addr_rd, x23_toSRAM_12_wdata, x23_toSRAM_12_wmask, x23_toSRAM_12_re, x23_toSRAM_12_we, x23_toSRAM_12_ack, x23_toSRAM_12_selectedOH, x23_toSRAM_12_array, x23_toSRAM_13_addr, x23_toSRAM_13_addr_rd, x23_toSRAM_13_wdata, x23_toSRAM_13_wmask, x23_toSRAM_13_re, x23_toSRAM_13_we, x23_toSRAM_13_ack, x23_toSRAM_13_selectedOH, x23_toSRAM_13_array, x23_toSRAM_14_addr, x23_toSRAM_14_addr_rd, x23_toSRAM_14_wdata, x23_toSRAM_14_wmask, x23_toSRAM_14_re, x23_toSRAM_14_we, x23_toSRAM_14_ack, x23_toSRAM_14_selectedOH, x23_toSRAM_14_array, x23_toSRAM_15_addr, x23_toSRAM_15_addr_rd, x23_toSRAM_15_wdata, x23_toSRAM_15_wmask, x23_toSRAM_15_re, x23_toSRAM_15_we, x23_toSRAM_15_ack, x23_toSRAM_15_selectedOH, x23_toSRAM_15_array, x23_toSRAM_16_addr, x23_toSRAM_16_addr_rd, x23_toSRAM_16_wdata, x23_toSRAM_16_wmask, x23_toSRAM_16_re, x23_toSRAM_16_we, x23_toSRAM_16_ack, x23_toSRAM_16_selectedOH, x23_toSRAM_16_array, x23_toSRAM_17_addr, x23_toSRAM_17_addr_rd, x23_toSRAM_17_wdata, x23_toSRAM_17_wmask, x23_toSRAM_17_re, x23_toSRAM_17_we, x23_toSRAM_17_ack, x23_toSRAM_17_selectedOH, x23_toSRAM_17_array, x23_toSRAM_18_addr, x23_toSRAM_18_addr_rd, x23_toSRAM_18_wdata, x23_toSRAM_18_wmask, x23_toSRAM_18_re, x23_toSRAM_18_we, x23_toSRAM_18_ack, x23_toSRAM_18_selectedOH, x23_toSRAM_18_array, x23_toSRAM_19_addr, x23_toSRAM_19_addr_rd, x23_toSRAM_19_wdata, x23_toSRAM_19_wmask, x23_toSRAM_19_re, x23_toSRAM_19_we, x23_toSRAM_19_ack, x23_toSRAM_19_selectedOH, x23_toSRAM_19_array, x23_toSRAM_20_addr, x23_toSRAM_20_addr_rd, x23_toSRAM_20_wdata, x23_toSRAM_20_wmask, x23_toSRAM_20_re, x23_toSRAM_20_we, x23_toSRAM_20_ack, x23_toSRAM_20_selectedOH, x23_toSRAM_20_array, x23_toSRAM_21_addr, x23_toSRAM_21_addr_rd, x23_toSRAM_21_wdata, x23_toSRAM_21_wmask, x23_toSRAM_21_re, x23_toSRAM_21_we, x23_toSRAM_21_ack, x23_toSRAM_21_selectedOH, x23_toSRAM_21_array, x23_toSRAM_22_addr, x23_toSRAM_22_addr_rd, x23_toSRAM_22_wdata, x23_toSRAM_22_wmask, x23_toSRAM_22_re, x23_toSRAM_22_we, x23_toSRAM_22_ack, x23_toSRAM_22_selectedOH, x23_toSRAM_22_array, x23_toSRAM_23_addr, x23_toSRAM_23_addr_rd, x23_toSRAM_23_wdata, x23_toSRAM_23_wmask, x23_toSRAM_23_re, x23_toSRAM_23_we, x23_toSRAM_23_ack, x23_toSRAM_23_selectedOH, x23_toSRAM_23_array};
  task automatic detail23();
    if (g23_mbist_ack !== x23_mbist_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.mbist_ack golden=%h impl=%h", cyc, g23_mbist_ack, x23_mbist_ack); end
    if (g23_mbist_outdata !== x23_mbist_outdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.mbist_outdata golden=%h impl=%h", cyc, g23_mbist_outdata, x23_mbist_outdata); end
    if (g23_toSRAM_0_addr !== x23_toSRAM_0_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_addr golden=%h impl=%h", cyc, g23_toSRAM_0_addr, x23_toSRAM_0_addr); end
    if (g23_toSRAM_0_addr_rd !== x23_toSRAM_0_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_0_addr_rd, x23_toSRAM_0_addr_rd); end
    if (g23_toSRAM_0_wdata !== x23_toSRAM_0_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_wdata golden=%h impl=%h", cyc, g23_toSRAM_0_wdata, x23_toSRAM_0_wdata); end
    if (g23_toSRAM_0_wmask !== x23_toSRAM_0_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_wmask golden=%h impl=%h", cyc, g23_toSRAM_0_wmask, x23_toSRAM_0_wmask); end
    if (g23_toSRAM_0_re !== x23_toSRAM_0_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_re golden=%h impl=%h", cyc, g23_toSRAM_0_re, x23_toSRAM_0_re); end
    if (g23_toSRAM_0_we !== x23_toSRAM_0_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_we golden=%h impl=%h", cyc, g23_toSRAM_0_we, x23_toSRAM_0_we); end
    if (g23_toSRAM_0_ack !== x23_toSRAM_0_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_ack golden=%h impl=%h", cyc, g23_toSRAM_0_ack, x23_toSRAM_0_ack); end
    if (g23_toSRAM_0_selectedOH !== x23_toSRAM_0_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_0_selectedOH, x23_toSRAM_0_selectedOH); end
    if (g23_toSRAM_0_array !== x23_toSRAM_0_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_0_array golden=%h impl=%h", cyc, g23_toSRAM_0_array, x23_toSRAM_0_array); end
    if (g23_toSRAM_1_addr !== x23_toSRAM_1_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_addr golden=%h impl=%h", cyc, g23_toSRAM_1_addr, x23_toSRAM_1_addr); end
    if (g23_toSRAM_1_addr_rd !== x23_toSRAM_1_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_1_addr_rd, x23_toSRAM_1_addr_rd); end
    if (g23_toSRAM_1_wdata !== x23_toSRAM_1_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_wdata golden=%h impl=%h", cyc, g23_toSRAM_1_wdata, x23_toSRAM_1_wdata); end
    if (g23_toSRAM_1_wmask !== x23_toSRAM_1_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_wmask golden=%h impl=%h", cyc, g23_toSRAM_1_wmask, x23_toSRAM_1_wmask); end
    if (g23_toSRAM_1_re !== x23_toSRAM_1_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_re golden=%h impl=%h", cyc, g23_toSRAM_1_re, x23_toSRAM_1_re); end
    if (g23_toSRAM_1_we !== x23_toSRAM_1_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_we golden=%h impl=%h", cyc, g23_toSRAM_1_we, x23_toSRAM_1_we); end
    if (g23_toSRAM_1_ack !== x23_toSRAM_1_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_ack golden=%h impl=%h", cyc, g23_toSRAM_1_ack, x23_toSRAM_1_ack); end
    if (g23_toSRAM_1_selectedOH !== x23_toSRAM_1_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_1_selectedOH, x23_toSRAM_1_selectedOH); end
    if (g23_toSRAM_1_array !== x23_toSRAM_1_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_1_array golden=%h impl=%h", cyc, g23_toSRAM_1_array, x23_toSRAM_1_array); end
    if (g23_toSRAM_2_addr !== x23_toSRAM_2_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_addr golden=%h impl=%h", cyc, g23_toSRAM_2_addr, x23_toSRAM_2_addr); end
    if (g23_toSRAM_2_addr_rd !== x23_toSRAM_2_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_2_addr_rd, x23_toSRAM_2_addr_rd); end
    if (g23_toSRAM_2_wdata !== x23_toSRAM_2_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_wdata golden=%h impl=%h", cyc, g23_toSRAM_2_wdata, x23_toSRAM_2_wdata); end
    if (g23_toSRAM_2_wmask !== x23_toSRAM_2_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_wmask golden=%h impl=%h", cyc, g23_toSRAM_2_wmask, x23_toSRAM_2_wmask); end
    if (g23_toSRAM_2_re !== x23_toSRAM_2_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_re golden=%h impl=%h", cyc, g23_toSRAM_2_re, x23_toSRAM_2_re); end
    if (g23_toSRAM_2_we !== x23_toSRAM_2_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_we golden=%h impl=%h", cyc, g23_toSRAM_2_we, x23_toSRAM_2_we); end
    if (g23_toSRAM_2_ack !== x23_toSRAM_2_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_ack golden=%h impl=%h", cyc, g23_toSRAM_2_ack, x23_toSRAM_2_ack); end
    if (g23_toSRAM_2_selectedOH !== x23_toSRAM_2_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_2_selectedOH, x23_toSRAM_2_selectedOH); end
    if (g23_toSRAM_2_array !== x23_toSRAM_2_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_2_array golden=%h impl=%h", cyc, g23_toSRAM_2_array, x23_toSRAM_2_array); end
    if (g23_toSRAM_3_addr !== x23_toSRAM_3_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_addr golden=%h impl=%h", cyc, g23_toSRAM_3_addr, x23_toSRAM_3_addr); end
    if (g23_toSRAM_3_addr_rd !== x23_toSRAM_3_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_3_addr_rd, x23_toSRAM_3_addr_rd); end
    if (g23_toSRAM_3_wdata !== x23_toSRAM_3_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_wdata golden=%h impl=%h", cyc, g23_toSRAM_3_wdata, x23_toSRAM_3_wdata); end
    if (g23_toSRAM_3_wmask !== x23_toSRAM_3_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_wmask golden=%h impl=%h", cyc, g23_toSRAM_3_wmask, x23_toSRAM_3_wmask); end
    if (g23_toSRAM_3_re !== x23_toSRAM_3_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_re golden=%h impl=%h", cyc, g23_toSRAM_3_re, x23_toSRAM_3_re); end
    if (g23_toSRAM_3_we !== x23_toSRAM_3_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_we golden=%h impl=%h", cyc, g23_toSRAM_3_we, x23_toSRAM_3_we); end
    if (g23_toSRAM_3_ack !== x23_toSRAM_3_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_ack golden=%h impl=%h", cyc, g23_toSRAM_3_ack, x23_toSRAM_3_ack); end
    if (g23_toSRAM_3_selectedOH !== x23_toSRAM_3_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_3_selectedOH, x23_toSRAM_3_selectedOH); end
    if (g23_toSRAM_3_array !== x23_toSRAM_3_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_3_array golden=%h impl=%h", cyc, g23_toSRAM_3_array, x23_toSRAM_3_array); end
    if (g23_toSRAM_4_addr !== x23_toSRAM_4_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_addr golden=%h impl=%h", cyc, g23_toSRAM_4_addr, x23_toSRAM_4_addr); end
    if (g23_toSRAM_4_addr_rd !== x23_toSRAM_4_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_4_addr_rd, x23_toSRAM_4_addr_rd); end
    if (g23_toSRAM_4_wdata !== x23_toSRAM_4_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_wdata golden=%h impl=%h", cyc, g23_toSRAM_4_wdata, x23_toSRAM_4_wdata); end
    if (g23_toSRAM_4_wmask !== x23_toSRAM_4_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_wmask golden=%h impl=%h", cyc, g23_toSRAM_4_wmask, x23_toSRAM_4_wmask); end
    if (g23_toSRAM_4_re !== x23_toSRAM_4_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_re golden=%h impl=%h", cyc, g23_toSRAM_4_re, x23_toSRAM_4_re); end
    if (g23_toSRAM_4_we !== x23_toSRAM_4_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_we golden=%h impl=%h", cyc, g23_toSRAM_4_we, x23_toSRAM_4_we); end
    if (g23_toSRAM_4_ack !== x23_toSRAM_4_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_ack golden=%h impl=%h", cyc, g23_toSRAM_4_ack, x23_toSRAM_4_ack); end
    if (g23_toSRAM_4_selectedOH !== x23_toSRAM_4_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_4_selectedOH, x23_toSRAM_4_selectedOH); end
    if (g23_toSRAM_4_array !== x23_toSRAM_4_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_4_array golden=%h impl=%h", cyc, g23_toSRAM_4_array, x23_toSRAM_4_array); end
    if (g23_toSRAM_5_addr !== x23_toSRAM_5_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_addr golden=%h impl=%h", cyc, g23_toSRAM_5_addr, x23_toSRAM_5_addr); end
    if (g23_toSRAM_5_addr_rd !== x23_toSRAM_5_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_5_addr_rd, x23_toSRAM_5_addr_rd); end
    if (g23_toSRAM_5_wdata !== x23_toSRAM_5_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_wdata golden=%h impl=%h", cyc, g23_toSRAM_5_wdata, x23_toSRAM_5_wdata); end
    if (g23_toSRAM_5_wmask !== x23_toSRAM_5_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_wmask golden=%h impl=%h", cyc, g23_toSRAM_5_wmask, x23_toSRAM_5_wmask); end
    if (g23_toSRAM_5_re !== x23_toSRAM_5_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_re golden=%h impl=%h", cyc, g23_toSRAM_5_re, x23_toSRAM_5_re); end
    if (g23_toSRAM_5_we !== x23_toSRAM_5_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_we golden=%h impl=%h", cyc, g23_toSRAM_5_we, x23_toSRAM_5_we); end
    if (g23_toSRAM_5_ack !== x23_toSRAM_5_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_ack golden=%h impl=%h", cyc, g23_toSRAM_5_ack, x23_toSRAM_5_ack); end
    if (g23_toSRAM_5_selectedOH !== x23_toSRAM_5_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_5_selectedOH, x23_toSRAM_5_selectedOH); end
    if (g23_toSRAM_5_array !== x23_toSRAM_5_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_5_array golden=%h impl=%h", cyc, g23_toSRAM_5_array, x23_toSRAM_5_array); end
    if (g23_toSRAM_6_addr !== x23_toSRAM_6_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_addr golden=%h impl=%h", cyc, g23_toSRAM_6_addr, x23_toSRAM_6_addr); end
    if (g23_toSRAM_6_addr_rd !== x23_toSRAM_6_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_6_addr_rd, x23_toSRAM_6_addr_rd); end
    if (g23_toSRAM_6_wdata !== x23_toSRAM_6_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_wdata golden=%h impl=%h", cyc, g23_toSRAM_6_wdata, x23_toSRAM_6_wdata); end
    if (g23_toSRAM_6_wmask !== x23_toSRAM_6_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_wmask golden=%h impl=%h", cyc, g23_toSRAM_6_wmask, x23_toSRAM_6_wmask); end
    if (g23_toSRAM_6_re !== x23_toSRAM_6_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_re golden=%h impl=%h", cyc, g23_toSRAM_6_re, x23_toSRAM_6_re); end
    if (g23_toSRAM_6_we !== x23_toSRAM_6_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_we golden=%h impl=%h", cyc, g23_toSRAM_6_we, x23_toSRAM_6_we); end
    if (g23_toSRAM_6_ack !== x23_toSRAM_6_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_ack golden=%h impl=%h", cyc, g23_toSRAM_6_ack, x23_toSRAM_6_ack); end
    if (g23_toSRAM_6_selectedOH !== x23_toSRAM_6_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_6_selectedOH, x23_toSRAM_6_selectedOH); end
    if (g23_toSRAM_6_array !== x23_toSRAM_6_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_6_array golden=%h impl=%h", cyc, g23_toSRAM_6_array, x23_toSRAM_6_array); end
    if (g23_toSRAM_7_addr !== x23_toSRAM_7_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_addr golden=%h impl=%h", cyc, g23_toSRAM_7_addr, x23_toSRAM_7_addr); end
    if (g23_toSRAM_7_addr_rd !== x23_toSRAM_7_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_7_addr_rd, x23_toSRAM_7_addr_rd); end
    if (g23_toSRAM_7_wdata !== x23_toSRAM_7_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_wdata golden=%h impl=%h", cyc, g23_toSRAM_7_wdata, x23_toSRAM_7_wdata); end
    if (g23_toSRAM_7_wmask !== x23_toSRAM_7_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_wmask golden=%h impl=%h", cyc, g23_toSRAM_7_wmask, x23_toSRAM_7_wmask); end
    if (g23_toSRAM_7_re !== x23_toSRAM_7_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_re golden=%h impl=%h", cyc, g23_toSRAM_7_re, x23_toSRAM_7_re); end
    if (g23_toSRAM_7_we !== x23_toSRAM_7_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_we golden=%h impl=%h", cyc, g23_toSRAM_7_we, x23_toSRAM_7_we); end
    if (g23_toSRAM_7_ack !== x23_toSRAM_7_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_ack golden=%h impl=%h", cyc, g23_toSRAM_7_ack, x23_toSRAM_7_ack); end
    if (g23_toSRAM_7_selectedOH !== x23_toSRAM_7_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_7_selectedOH, x23_toSRAM_7_selectedOH); end
    if (g23_toSRAM_7_array !== x23_toSRAM_7_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_7_array golden=%h impl=%h", cyc, g23_toSRAM_7_array, x23_toSRAM_7_array); end
    if (g23_toSRAM_8_addr !== x23_toSRAM_8_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_addr golden=%h impl=%h", cyc, g23_toSRAM_8_addr, x23_toSRAM_8_addr); end
    if (g23_toSRAM_8_addr_rd !== x23_toSRAM_8_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_8_addr_rd, x23_toSRAM_8_addr_rd); end
    if (g23_toSRAM_8_wdata !== x23_toSRAM_8_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_wdata golden=%h impl=%h", cyc, g23_toSRAM_8_wdata, x23_toSRAM_8_wdata); end
    if (g23_toSRAM_8_wmask !== x23_toSRAM_8_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_wmask golden=%h impl=%h", cyc, g23_toSRAM_8_wmask, x23_toSRAM_8_wmask); end
    if (g23_toSRAM_8_re !== x23_toSRAM_8_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_re golden=%h impl=%h", cyc, g23_toSRAM_8_re, x23_toSRAM_8_re); end
    if (g23_toSRAM_8_we !== x23_toSRAM_8_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_we golden=%h impl=%h", cyc, g23_toSRAM_8_we, x23_toSRAM_8_we); end
    if (g23_toSRAM_8_ack !== x23_toSRAM_8_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_ack golden=%h impl=%h", cyc, g23_toSRAM_8_ack, x23_toSRAM_8_ack); end
    if (g23_toSRAM_8_selectedOH !== x23_toSRAM_8_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_8_selectedOH, x23_toSRAM_8_selectedOH); end
    if (g23_toSRAM_8_array !== x23_toSRAM_8_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_8_array golden=%h impl=%h", cyc, g23_toSRAM_8_array, x23_toSRAM_8_array); end
    if (g23_toSRAM_9_addr !== x23_toSRAM_9_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_addr golden=%h impl=%h", cyc, g23_toSRAM_9_addr, x23_toSRAM_9_addr); end
    if (g23_toSRAM_9_addr_rd !== x23_toSRAM_9_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_9_addr_rd, x23_toSRAM_9_addr_rd); end
    if (g23_toSRAM_9_wdata !== x23_toSRAM_9_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_wdata golden=%h impl=%h", cyc, g23_toSRAM_9_wdata, x23_toSRAM_9_wdata); end
    if (g23_toSRAM_9_wmask !== x23_toSRAM_9_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_wmask golden=%h impl=%h", cyc, g23_toSRAM_9_wmask, x23_toSRAM_9_wmask); end
    if (g23_toSRAM_9_re !== x23_toSRAM_9_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_re golden=%h impl=%h", cyc, g23_toSRAM_9_re, x23_toSRAM_9_re); end
    if (g23_toSRAM_9_we !== x23_toSRAM_9_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_we golden=%h impl=%h", cyc, g23_toSRAM_9_we, x23_toSRAM_9_we); end
    if (g23_toSRAM_9_ack !== x23_toSRAM_9_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_ack golden=%h impl=%h", cyc, g23_toSRAM_9_ack, x23_toSRAM_9_ack); end
    if (g23_toSRAM_9_selectedOH !== x23_toSRAM_9_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_9_selectedOH, x23_toSRAM_9_selectedOH); end
    if (g23_toSRAM_9_array !== x23_toSRAM_9_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_9_array golden=%h impl=%h", cyc, g23_toSRAM_9_array, x23_toSRAM_9_array); end
    if (g23_toSRAM_10_addr !== x23_toSRAM_10_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_addr golden=%h impl=%h", cyc, g23_toSRAM_10_addr, x23_toSRAM_10_addr); end
    if (g23_toSRAM_10_addr_rd !== x23_toSRAM_10_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_10_addr_rd, x23_toSRAM_10_addr_rd); end
    if (g23_toSRAM_10_wdata !== x23_toSRAM_10_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_wdata golden=%h impl=%h", cyc, g23_toSRAM_10_wdata, x23_toSRAM_10_wdata); end
    if (g23_toSRAM_10_wmask !== x23_toSRAM_10_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_wmask golden=%h impl=%h", cyc, g23_toSRAM_10_wmask, x23_toSRAM_10_wmask); end
    if (g23_toSRAM_10_re !== x23_toSRAM_10_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_re golden=%h impl=%h", cyc, g23_toSRAM_10_re, x23_toSRAM_10_re); end
    if (g23_toSRAM_10_we !== x23_toSRAM_10_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_we golden=%h impl=%h", cyc, g23_toSRAM_10_we, x23_toSRAM_10_we); end
    if (g23_toSRAM_10_ack !== x23_toSRAM_10_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_ack golden=%h impl=%h", cyc, g23_toSRAM_10_ack, x23_toSRAM_10_ack); end
    if (g23_toSRAM_10_selectedOH !== x23_toSRAM_10_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_10_selectedOH, x23_toSRAM_10_selectedOH); end
    if (g23_toSRAM_10_array !== x23_toSRAM_10_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_10_array golden=%h impl=%h", cyc, g23_toSRAM_10_array, x23_toSRAM_10_array); end
    if (g23_toSRAM_11_addr !== x23_toSRAM_11_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_addr golden=%h impl=%h", cyc, g23_toSRAM_11_addr, x23_toSRAM_11_addr); end
    if (g23_toSRAM_11_addr_rd !== x23_toSRAM_11_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_11_addr_rd, x23_toSRAM_11_addr_rd); end
    if (g23_toSRAM_11_wdata !== x23_toSRAM_11_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_wdata golden=%h impl=%h", cyc, g23_toSRAM_11_wdata, x23_toSRAM_11_wdata); end
    if (g23_toSRAM_11_wmask !== x23_toSRAM_11_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_wmask golden=%h impl=%h", cyc, g23_toSRAM_11_wmask, x23_toSRAM_11_wmask); end
    if (g23_toSRAM_11_re !== x23_toSRAM_11_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_re golden=%h impl=%h", cyc, g23_toSRAM_11_re, x23_toSRAM_11_re); end
    if (g23_toSRAM_11_we !== x23_toSRAM_11_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_we golden=%h impl=%h", cyc, g23_toSRAM_11_we, x23_toSRAM_11_we); end
    if (g23_toSRAM_11_ack !== x23_toSRAM_11_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_ack golden=%h impl=%h", cyc, g23_toSRAM_11_ack, x23_toSRAM_11_ack); end
    if (g23_toSRAM_11_selectedOH !== x23_toSRAM_11_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_11_selectedOH, x23_toSRAM_11_selectedOH); end
    if (g23_toSRAM_11_array !== x23_toSRAM_11_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_11_array golden=%h impl=%h", cyc, g23_toSRAM_11_array, x23_toSRAM_11_array); end
    if (g23_toSRAM_12_addr !== x23_toSRAM_12_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_addr golden=%h impl=%h", cyc, g23_toSRAM_12_addr, x23_toSRAM_12_addr); end
    if (g23_toSRAM_12_addr_rd !== x23_toSRAM_12_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_12_addr_rd, x23_toSRAM_12_addr_rd); end
    if (g23_toSRAM_12_wdata !== x23_toSRAM_12_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_wdata golden=%h impl=%h", cyc, g23_toSRAM_12_wdata, x23_toSRAM_12_wdata); end
    if (g23_toSRAM_12_wmask !== x23_toSRAM_12_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_wmask golden=%h impl=%h", cyc, g23_toSRAM_12_wmask, x23_toSRAM_12_wmask); end
    if (g23_toSRAM_12_re !== x23_toSRAM_12_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_re golden=%h impl=%h", cyc, g23_toSRAM_12_re, x23_toSRAM_12_re); end
    if (g23_toSRAM_12_we !== x23_toSRAM_12_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_we golden=%h impl=%h", cyc, g23_toSRAM_12_we, x23_toSRAM_12_we); end
    if (g23_toSRAM_12_ack !== x23_toSRAM_12_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_ack golden=%h impl=%h", cyc, g23_toSRAM_12_ack, x23_toSRAM_12_ack); end
    if (g23_toSRAM_12_selectedOH !== x23_toSRAM_12_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_12_selectedOH, x23_toSRAM_12_selectedOH); end
    if (g23_toSRAM_12_array !== x23_toSRAM_12_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_12_array golden=%h impl=%h", cyc, g23_toSRAM_12_array, x23_toSRAM_12_array); end
    if (g23_toSRAM_13_addr !== x23_toSRAM_13_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_addr golden=%h impl=%h", cyc, g23_toSRAM_13_addr, x23_toSRAM_13_addr); end
    if (g23_toSRAM_13_addr_rd !== x23_toSRAM_13_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_13_addr_rd, x23_toSRAM_13_addr_rd); end
    if (g23_toSRAM_13_wdata !== x23_toSRAM_13_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_wdata golden=%h impl=%h", cyc, g23_toSRAM_13_wdata, x23_toSRAM_13_wdata); end
    if (g23_toSRAM_13_wmask !== x23_toSRAM_13_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_wmask golden=%h impl=%h", cyc, g23_toSRAM_13_wmask, x23_toSRAM_13_wmask); end
    if (g23_toSRAM_13_re !== x23_toSRAM_13_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_re golden=%h impl=%h", cyc, g23_toSRAM_13_re, x23_toSRAM_13_re); end
    if (g23_toSRAM_13_we !== x23_toSRAM_13_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_we golden=%h impl=%h", cyc, g23_toSRAM_13_we, x23_toSRAM_13_we); end
    if (g23_toSRAM_13_ack !== x23_toSRAM_13_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_ack golden=%h impl=%h", cyc, g23_toSRAM_13_ack, x23_toSRAM_13_ack); end
    if (g23_toSRAM_13_selectedOH !== x23_toSRAM_13_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_13_selectedOH, x23_toSRAM_13_selectedOH); end
    if (g23_toSRAM_13_array !== x23_toSRAM_13_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_13_array golden=%h impl=%h", cyc, g23_toSRAM_13_array, x23_toSRAM_13_array); end
    if (g23_toSRAM_14_addr !== x23_toSRAM_14_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_addr golden=%h impl=%h", cyc, g23_toSRAM_14_addr, x23_toSRAM_14_addr); end
    if (g23_toSRAM_14_addr_rd !== x23_toSRAM_14_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_14_addr_rd, x23_toSRAM_14_addr_rd); end
    if (g23_toSRAM_14_wdata !== x23_toSRAM_14_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_wdata golden=%h impl=%h", cyc, g23_toSRAM_14_wdata, x23_toSRAM_14_wdata); end
    if (g23_toSRAM_14_wmask !== x23_toSRAM_14_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_wmask golden=%h impl=%h", cyc, g23_toSRAM_14_wmask, x23_toSRAM_14_wmask); end
    if (g23_toSRAM_14_re !== x23_toSRAM_14_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_re golden=%h impl=%h", cyc, g23_toSRAM_14_re, x23_toSRAM_14_re); end
    if (g23_toSRAM_14_we !== x23_toSRAM_14_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_we golden=%h impl=%h", cyc, g23_toSRAM_14_we, x23_toSRAM_14_we); end
    if (g23_toSRAM_14_ack !== x23_toSRAM_14_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_ack golden=%h impl=%h", cyc, g23_toSRAM_14_ack, x23_toSRAM_14_ack); end
    if (g23_toSRAM_14_selectedOH !== x23_toSRAM_14_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_14_selectedOH, x23_toSRAM_14_selectedOH); end
    if (g23_toSRAM_14_array !== x23_toSRAM_14_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_14_array golden=%h impl=%h", cyc, g23_toSRAM_14_array, x23_toSRAM_14_array); end
    if (g23_toSRAM_15_addr !== x23_toSRAM_15_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_addr golden=%h impl=%h", cyc, g23_toSRAM_15_addr, x23_toSRAM_15_addr); end
    if (g23_toSRAM_15_addr_rd !== x23_toSRAM_15_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_15_addr_rd, x23_toSRAM_15_addr_rd); end
    if (g23_toSRAM_15_wdata !== x23_toSRAM_15_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_wdata golden=%h impl=%h", cyc, g23_toSRAM_15_wdata, x23_toSRAM_15_wdata); end
    if (g23_toSRAM_15_wmask !== x23_toSRAM_15_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_wmask golden=%h impl=%h", cyc, g23_toSRAM_15_wmask, x23_toSRAM_15_wmask); end
    if (g23_toSRAM_15_re !== x23_toSRAM_15_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_re golden=%h impl=%h", cyc, g23_toSRAM_15_re, x23_toSRAM_15_re); end
    if (g23_toSRAM_15_we !== x23_toSRAM_15_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_we golden=%h impl=%h", cyc, g23_toSRAM_15_we, x23_toSRAM_15_we); end
    if (g23_toSRAM_15_ack !== x23_toSRAM_15_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_ack golden=%h impl=%h", cyc, g23_toSRAM_15_ack, x23_toSRAM_15_ack); end
    if (g23_toSRAM_15_selectedOH !== x23_toSRAM_15_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_15_selectedOH, x23_toSRAM_15_selectedOH); end
    if (g23_toSRAM_15_array !== x23_toSRAM_15_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_15_array golden=%h impl=%h", cyc, g23_toSRAM_15_array, x23_toSRAM_15_array); end
    if (g23_toSRAM_16_addr !== x23_toSRAM_16_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_addr golden=%h impl=%h", cyc, g23_toSRAM_16_addr, x23_toSRAM_16_addr); end
    if (g23_toSRAM_16_addr_rd !== x23_toSRAM_16_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_16_addr_rd, x23_toSRAM_16_addr_rd); end
    if (g23_toSRAM_16_wdata !== x23_toSRAM_16_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_wdata golden=%h impl=%h", cyc, g23_toSRAM_16_wdata, x23_toSRAM_16_wdata); end
    if (g23_toSRAM_16_wmask !== x23_toSRAM_16_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_wmask golden=%h impl=%h", cyc, g23_toSRAM_16_wmask, x23_toSRAM_16_wmask); end
    if (g23_toSRAM_16_re !== x23_toSRAM_16_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_re golden=%h impl=%h", cyc, g23_toSRAM_16_re, x23_toSRAM_16_re); end
    if (g23_toSRAM_16_we !== x23_toSRAM_16_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_we golden=%h impl=%h", cyc, g23_toSRAM_16_we, x23_toSRAM_16_we); end
    if (g23_toSRAM_16_ack !== x23_toSRAM_16_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_ack golden=%h impl=%h", cyc, g23_toSRAM_16_ack, x23_toSRAM_16_ack); end
    if (g23_toSRAM_16_selectedOH !== x23_toSRAM_16_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_16_selectedOH, x23_toSRAM_16_selectedOH); end
    if (g23_toSRAM_16_array !== x23_toSRAM_16_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_16_array golden=%h impl=%h", cyc, g23_toSRAM_16_array, x23_toSRAM_16_array); end
    if (g23_toSRAM_17_addr !== x23_toSRAM_17_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_addr golden=%h impl=%h", cyc, g23_toSRAM_17_addr, x23_toSRAM_17_addr); end
    if (g23_toSRAM_17_addr_rd !== x23_toSRAM_17_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_17_addr_rd, x23_toSRAM_17_addr_rd); end
    if (g23_toSRAM_17_wdata !== x23_toSRAM_17_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_wdata golden=%h impl=%h", cyc, g23_toSRAM_17_wdata, x23_toSRAM_17_wdata); end
    if (g23_toSRAM_17_wmask !== x23_toSRAM_17_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_wmask golden=%h impl=%h", cyc, g23_toSRAM_17_wmask, x23_toSRAM_17_wmask); end
    if (g23_toSRAM_17_re !== x23_toSRAM_17_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_re golden=%h impl=%h", cyc, g23_toSRAM_17_re, x23_toSRAM_17_re); end
    if (g23_toSRAM_17_we !== x23_toSRAM_17_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_we golden=%h impl=%h", cyc, g23_toSRAM_17_we, x23_toSRAM_17_we); end
    if (g23_toSRAM_17_ack !== x23_toSRAM_17_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_ack golden=%h impl=%h", cyc, g23_toSRAM_17_ack, x23_toSRAM_17_ack); end
    if (g23_toSRAM_17_selectedOH !== x23_toSRAM_17_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_17_selectedOH, x23_toSRAM_17_selectedOH); end
    if (g23_toSRAM_17_array !== x23_toSRAM_17_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_17_array golden=%h impl=%h", cyc, g23_toSRAM_17_array, x23_toSRAM_17_array); end
    if (g23_toSRAM_18_addr !== x23_toSRAM_18_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_addr golden=%h impl=%h", cyc, g23_toSRAM_18_addr, x23_toSRAM_18_addr); end
    if (g23_toSRAM_18_addr_rd !== x23_toSRAM_18_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_18_addr_rd, x23_toSRAM_18_addr_rd); end
    if (g23_toSRAM_18_wdata !== x23_toSRAM_18_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_wdata golden=%h impl=%h", cyc, g23_toSRAM_18_wdata, x23_toSRAM_18_wdata); end
    if (g23_toSRAM_18_wmask !== x23_toSRAM_18_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_wmask golden=%h impl=%h", cyc, g23_toSRAM_18_wmask, x23_toSRAM_18_wmask); end
    if (g23_toSRAM_18_re !== x23_toSRAM_18_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_re golden=%h impl=%h", cyc, g23_toSRAM_18_re, x23_toSRAM_18_re); end
    if (g23_toSRAM_18_we !== x23_toSRAM_18_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_we golden=%h impl=%h", cyc, g23_toSRAM_18_we, x23_toSRAM_18_we); end
    if (g23_toSRAM_18_ack !== x23_toSRAM_18_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_ack golden=%h impl=%h", cyc, g23_toSRAM_18_ack, x23_toSRAM_18_ack); end
    if (g23_toSRAM_18_selectedOH !== x23_toSRAM_18_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_18_selectedOH, x23_toSRAM_18_selectedOH); end
    if (g23_toSRAM_18_array !== x23_toSRAM_18_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_18_array golden=%h impl=%h", cyc, g23_toSRAM_18_array, x23_toSRAM_18_array); end
    if (g23_toSRAM_19_addr !== x23_toSRAM_19_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_addr golden=%h impl=%h", cyc, g23_toSRAM_19_addr, x23_toSRAM_19_addr); end
    if (g23_toSRAM_19_addr_rd !== x23_toSRAM_19_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_19_addr_rd, x23_toSRAM_19_addr_rd); end
    if (g23_toSRAM_19_wdata !== x23_toSRAM_19_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_wdata golden=%h impl=%h", cyc, g23_toSRAM_19_wdata, x23_toSRAM_19_wdata); end
    if (g23_toSRAM_19_wmask !== x23_toSRAM_19_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_wmask golden=%h impl=%h", cyc, g23_toSRAM_19_wmask, x23_toSRAM_19_wmask); end
    if (g23_toSRAM_19_re !== x23_toSRAM_19_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_re golden=%h impl=%h", cyc, g23_toSRAM_19_re, x23_toSRAM_19_re); end
    if (g23_toSRAM_19_we !== x23_toSRAM_19_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_we golden=%h impl=%h", cyc, g23_toSRAM_19_we, x23_toSRAM_19_we); end
    if (g23_toSRAM_19_ack !== x23_toSRAM_19_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_ack golden=%h impl=%h", cyc, g23_toSRAM_19_ack, x23_toSRAM_19_ack); end
    if (g23_toSRAM_19_selectedOH !== x23_toSRAM_19_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_19_selectedOH, x23_toSRAM_19_selectedOH); end
    if (g23_toSRAM_19_array !== x23_toSRAM_19_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_19_array golden=%h impl=%h", cyc, g23_toSRAM_19_array, x23_toSRAM_19_array); end
    if (g23_toSRAM_20_addr !== x23_toSRAM_20_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_addr golden=%h impl=%h", cyc, g23_toSRAM_20_addr, x23_toSRAM_20_addr); end
    if (g23_toSRAM_20_addr_rd !== x23_toSRAM_20_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_20_addr_rd, x23_toSRAM_20_addr_rd); end
    if (g23_toSRAM_20_wdata !== x23_toSRAM_20_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_wdata golden=%h impl=%h", cyc, g23_toSRAM_20_wdata, x23_toSRAM_20_wdata); end
    if (g23_toSRAM_20_wmask !== x23_toSRAM_20_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_wmask golden=%h impl=%h", cyc, g23_toSRAM_20_wmask, x23_toSRAM_20_wmask); end
    if (g23_toSRAM_20_re !== x23_toSRAM_20_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_re golden=%h impl=%h", cyc, g23_toSRAM_20_re, x23_toSRAM_20_re); end
    if (g23_toSRAM_20_we !== x23_toSRAM_20_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_we golden=%h impl=%h", cyc, g23_toSRAM_20_we, x23_toSRAM_20_we); end
    if (g23_toSRAM_20_ack !== x23_toSRAM_20_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_ack golden=%h impl=%h", cyc, g23_toSRAM_20_ack, x23_toSRAM_20_ack); end
    if (g23_toSRAM_20_selectedOH !== x23_toSRAM_20_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_20_selectedOH, x23_toSRAM_20_selectedOH); end
    if (g23_toSRAM_20_array !== x23_toSRAM_20_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_20_array golden=%h impl=%h", cyc, g23_toSRAM_20_array, x23_toSRAM_20_array); end
    if (g23_toSRAM_21_addr !== x23_toSRAM_21_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_addr golden=%h impl=%h", cyc, g23_toSRAM_21_addr, x23_toSRAM_21_addr); end
    if (g23_toSRAM_21_addr_rd !== x23_toSRAM_21_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_21_addr_rd, x23_toSRAM_21_addr_rd); end
    if (g23_toSRAM_21_wdata !== x23_toSRAM_21_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_wdata golden=%h impl=%h", cyc, g23_toSRAM_21_wdata, x23_toSRAM_21_wdata); end
    if (g23_toSRAM_21_wmask !== x23_toSRAM_21_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_wmask golden=%h impl=%h", cyc, g23_toSRAM_21_wmask, x23_toSRAM_21_wmask); end
    if (g23_toSRAM_21_re !== x23_toSRAM_21_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_re golden=%h impl=%h", cyc, g23_toSRAM_21_re, x23_toSRAM_21_re); end
    if (g23_toSRAM_21_we !== x23_toSRAM_21_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_we golden=%h impl=%h", cyc, g23_toSRAM_21_we, x23_toSRAM_21_we); end
    if (g23_toSRAM_21_ack !== x23_toSRAM_21_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_ack golden=%h impl=%h", cyc, g23_toSRAM_21_ack, x23_toSRAM_21_ack); end
    if (g23_toSRAM_21_selectedOH !== x23_toSRAM_21_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_21_selectedOH, x23_toSRAM_21_selectedOH); end
    if (g23_toSRAM_21_array !== x23_toSRAM_21_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_21_array golden=%h impl=%h", cyc, g23_toSRAM_21_array, x23_toSRAM_21_array); end
    if (g23_toSRAM_22_addr !== x23_toSRAM_22_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_addr golden=%h impl=%h", cyc, g23_toSRAM_22_addr, x23_toSRAM_22_addr); end
    if (g23_toSRAM_22_addr_rd !== x23_toSRAM_22_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_22_addr_rd, x23_toSRAM_22_addr_rd); end
    if (g23_toSRAM_22_wdata !== x23_toSRAM_22_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_wdata golden=%h impl=%h", cyc, g23_toSRAM_22_wdata, x23_toSRAM_22_wdata); end
    if (g23_toSRAM_22_wmask !== x23_toSRAM_22_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_wmask golden=%h impl=%h", cyc, g23_toSRAM_22_wmask, x23_toSRAM_22_wmask); end
    if (g23_toSRAM_22_re !== x23_toSRAM_22_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_re golden=%h impl=%h", cyc, g23_toSRAM_22_re, x23_toSRAM_22_re); end
    if (g23_toSRAM_22_we !== x23_toSRAM_22_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_we golden=%h impl=%h", cyc, g23_toSRAM_22_we, x23_toSRAM_22_we); end
    if (g23_toSRAM_22_ack !== x23_toSRAM_22_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_ack golden=%h impl=%h", cyc, g23_toSRAM_22_ack, x23_toSRAM_22_ack); end
    if (g23_toSRAM_22_selectedOH !== x23_toSRAM_22_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_22_selectedOH, x23_toSRAM_22_selectedOH); end
    if (g23_toSRAM_22_array !== x23_toSRAM_22_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_22_array golden=%h impl=%h", cyc, g23_toSRAM_22_array, x23_toSRAM_22_array); end
    if (g23_toSRAM_23_addr !== x23_toSRAM_23_addr) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_addr golden=%h impl=%h", cyc, g23_toSRAM_23_addr, x23_toSRAM_23_addr); end
    if (g23_toSRAM_23_addr_rd !== x23_toSRAM_23_addr_rd) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_addr_rd golden=%h impl=%h", cyc, g23_toSRAM_23_addr_rd, x23_toSRAM_23_addr_rd); end
    if (g23_toSRAM_23_wdata !== x23_toSRAM_23_wdata) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_wdata golden=%h impl=%h", cyc, g23_toSRAM_23_wdata, x23_toSRAM_23_wdata); end
    if (g23_toSRAM_23_wmask !== x23_toSRAM_23_wmask) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_wmask golden=%h impl=%h", cyc, g23_toSRAM_23_wmask, x23_toSRAM_23_wmask); end
    if (g23_toSRAM_23_re !== x23_toSRAM_23_re) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_re golden=%h impl=%h", cyc, g23_toSRAM_23_re, x23_toSRAM_23_re); end
    if (g23_toSRAM_23_we !== x23_toSRAM_23_we) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_we golden=%h impl=%h", cyc, g23_toSRAM_23_we, x23_toSRAM_23_we); end
    if (g23_toSRAM_23_ack !== x23_toSRAM_23_ack) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_ack golden=%h impl=%h", cyc, g23_toSRAM_23_ack, x23_toSRAM_23_ack); end
    if (g23_toSRAM_23_selectedOH !== x23_toSRAM_23_selectedOH) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_selectedOH golden=%h impl=%h", cyc, g23_toSRAM_23_selectedOH, x23_toSRAM_23_selectedOH); end
    if (g23_toSRAM_23_array !== x23_toSRAM_23_array) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%0d MbistPipeTage.toSRAM_23_array golden=%h impl=%h", cyc, g23_toSRAM_23_array, x23_toSRAM_23_array); end
  endtask

  localparam longint unsigned N_OUT_PORTS = 1542;   // 24 个变体的输出端口总数

  // ---------------- 每拍比对 ----------------
  task automatic compare_all();
    bit bad;
    bad = 1'b0;
    if (gbus0 !== xbus0) begin bad = 1'b1; detail0(); end
    if (gbus1 !== xbus1) begin bad = 1'b1; detail1(); end
    if (gbus2 !== xbus2) begin bad = 1'b1; detail2(); end
    if (gbus3 !== xbus3) begin bad = 1'b1; detail3(); end
    if (gbus4 !== xbus4) begin bad = 1'b1; detail4(); end
    if (gbus5 !== xbus5) begin bad = 1'b1; detail5(); end
    if (gbus6 !== xbus6) begin bad = 1'b1; detail6(); end
    if (gbus7 !== xbus7) begin bad = 1'b1; detail7(); end
    if (gbus8 !== xbus8) begin bad = 1'b1; detail8(); end
    if (gbus9 !== xbus9) begin bad = 1'b1; detail9(); end
    if (gbus10 !== xbus10) begin bad = 1'b1; detail10(); end
    if (gbus11 !== xbus11) begin bad = 1'b1; detail11(); end
    if (gbus12 !== xbus12) begin bad = 1'b1; detail12(); end
    if (gbus13 !== xbus13) begin bad = 1'b1; detail13(); end
    if (gbus14 !== xbus14) begin bad = 1'b1; detail14(); end
    if (gbus15 !== xbus15) begin bad = 1'b1; detail15(); end
    if (gbus16 !== xbus16) begin bad = 1'b1; detail16(); end
    if (gbus17 !== xbus17) begin bad = 1'b1; detail17(); end
    if (gbus18 !== xbus18) begin bad = 1'b1; detail18(); end
    if (gbus19 !== xbus19) begin bad = 1'b1; detail19(); end
    if (gbus20 !== xbus20) begin bad = 1'b1; detail20(); end
    if (gbus21 !== xbus21) begin bad = 1'b1; detail21(); end
    if (gbus22 !== xbus22) begin bad = 1'b1; detail22(); end
    if (gbus23 !== xbus23) begin bad = 1'b1; detail23(); end
    checks += N_OUT_PORTS;
    cmp_cycles++;
    if (bad && errors < 20) $display("  [MISMATCH] cyc=%0d 见上方逐端口明细", cyc);
  endtask

  // ---------------- 覆盖累计 ----------------
  task automatic sample_cov();
    if (s_req && !s_all && (s_ren || s_wen)) cov_id[s_array] = 1'b1;
    if (s_all) cov_all_bcast = 1'b1;
    if (!s_req && !s_all) cov_idle = 1'b1;
    if (s_wen && !s_ren) cov_wr = 1'b1;
    if (s_ren && !s_wen) cov_rd = 1'b1;
    if (s_ren && s_wen)  cov_rdwr = 1'b1;
    cov_addr0 |= ~(s_addr & s_addr_rd); cov_addr1 |= (s_addr | s_addr_rd);
    cov_be0   |= ~s_be;                 cov_be1   |= s_be;
    cov_din0  |= ~s_indata;             cov_din1  |= s_indata;
    cov_spread0 |= {(g0_toSRAM_31_re | g0_toSRAM_31_we), (g0_toSRAM_30_re | g0_toSRAM_30_we), (g0_toSRAM_29_re | g0_toSRAM_29_we), (g0_toSRAM_28_re | g0_toSRAM_28_we), (g0_toSRAM_27_re | g0_toSRAM_27_we), (g0_toSRAM_26_re | g0_toSRAM_26_we), (g0_toSRAM_25_re | g0_toSRAM_25_we), (g0_toSRAM_24_re | g0_toSRAM_24_we), (g0_toSRAM_23_re | g0_toSRAM_23_we), (g0_toSRAM_22_re | g0_toSRAM_22_we), (g0_toSRAM_21_re | g0_toSRAM_21_we), (g0_toSRAM_20_re | g0_toSRAM_20_we), (g0_toSRAM_19_re | g0_toSRAM_19_we), (g0_toSRAM_18_re | g0_toSRAM_18_we), (g0_toSRAM_17_re | g0_toSRAM_17_we), (g0_toSRAM_16_re | g0_toSRAM_16_we), (g0_toSRAM_15_re | g0_toSRAM_15_we), (g0_toSRAM_14_re | g0_toSRAM_14_we), (g0_toSRAM_13_re | g0_toSRAM_13_we), (g0_toSRAM_12_re | g0_toSRAM_12_we), (g0_toSRAM_11_re | g0_toSRAM_11_we), (g0_toSRAM_10_re | g0_toSRAM_10_we), (g0_toSRAM_9_re | g0_toSRAM_9_we), (g0_toSRAM_8_re | g0_toSRAM_8_we), (g0_toSRAM_7_re | g0_toSRAM_7_we), (g0_toSRAM_6_re | g0_toSRAM_6_we), (g0_toSRAM_5_re | g0_toSRAM_5_we), (g0_toSRAM_4_re | g0_toSRAM_4_we), (g0_toSRAM_3_re | g0_toSRAM_3_we), (g0_toSRAM_2_re | g0_toSRAM_2_we), (g0_toSRAM_1_re | g0_toSRAM_1_we), (g0_toSRAM_0_re | g0_toSRAM_0_we)};
    cov_od0_0 |= ~g0_mbist_outdata; cov_od1_0 |= g0_mbist_outdata;
    if (g0_mbist_ack) cov_ack1_0 = 1'b1; else cov_ack0_0 = 1'b1;
    cov_spread1 |= {(g1_toSRAM_7_re | g1_toSRAM_7_we), (g1_toSRAM_6_re | g1_toSRAM_6_we), (g1_toSRAM_5_re | g1_toSRAM_5_we), (g1_toSRAM_4_re | g1_toSRAM_4_we), (g1_toSRAM_3_re | g1_toSRAM_3_we), (g1_toSRAM_2_re | g1_toSRAM_2_we), (g1_toSRAM_1_re | g1_toSRAM_1_we), (g1_toSRAM_0_re | g1_toSRAM_0_we)};
    cov_od0_1 |= ~g1_mbist_outdata; cov_od1_1 |= g1_mbist_outdata;
    if (g1_mbist_ack) cov_ack1_1 = 1'b1; else cov_ack0_1 = 1'b1;
    cov_spread2 |= {(g2_toNextPipeline_15_readen | g2_toNextPipeline_15_writeen), (g2_toNextPipeline_14_readen | g2_toNextPipeline_14_writeen), (g2_toNextPipeline_13_readen | g2_toNextPipeline_13_writeen), (g2_toNextPipeline_12_readen | g2_toNextPipeline_12_writeen), (g2_toNextPipeline_11_readen | g2_toNextPipeline_11_writeen), (g2_toNextPipeline_10_readen | g2_toNextPipeline_10_writeen), (g2_toNextPipeline_9_readen | g2_toNextPipeline_9_writeen), (g2_toNextPipeline_8_readen | g2_toNextPipeline_8_writeen), (g2_toNextPipeline_7_readen | g2_toNextPipeline_7_writeen), (g2_toNextPipeline_6_readen | g2_toNextPipeline_6_writeen), (g2_toNextPipeline_5_readen | g2_toNextPipeline_5_writeen), (g2_toNextPipeline_4_readen | g2_toNextPipeline_4_writeen), (g2_toNextPipeline_3_readen | g2_toNextPipeline_3_writeen), (g2_toNextPipeline_2_readen | g2_toNextPipeline_2_writeen), (g2_toNextPipeline_1_readen | g2_toNextPipeline_1_writeen), (g2_toNextPipeline_0_readen | g2_toNextPipeline_0_writeen)};
    cov_od0_2 |= ~g2_mbist_outdata; cov_od1_2 |= g2_mbist_outdata;
    if (g2_mbist_ack) cov_ack1_2 = 1'b1; else cov_ack0_2 = 1'b1;
    cov_spread3 |= {(g3_toSRAM_7_re | g3_toSRAM_7_we), (g3_toSRAM_6_re | g3_toSRAM_6_we), (g3_toSRAM_5_re | g3_toSRAM_5_we), (g3_toSRAM_4_re | g3_toSRAM_4_we), (g3_toSRAM_3_re | g3_toSRAM_3_we), (g3_toSRAM_2_re | g3_toSRAM_2_we), (g3_toSRAM_1_re | g3_toSRAM_1_we), (g3_toSRAM_0_re | g3_toSRAM_0_we)};
    cov_od0_3 |= ~g3_mbist_outdata; cov_od1_3 |= g3_mbist_outdata;
    if (g3_mbist_ack) cov_ack1_3 = 1'b1; else cov_ack0_3 = 1'b1;
    cov_spread4 |= {(g4_toSRAM_7_re | g4_toSRAM_7_we), (g4_toSRAM_6_re | g4_toSRAM_6_we), (g4_toSRAM_5_re | g4_toSRAM_5_we), (g4_toSRAM_4_re | g4_toSRAM_4_we), (g4_toSRAM_3_re | g4_toSRAM_3_we), (g4_toSRAM_2_re | g4_toSRAM_2_we), (g4_toSRAM_1_re | g4_toSRAM_1_we), (g4_toSRAM_0_re | g4_toSRAM_0_we)};
    cov_od0_4 |= ~g4_mbist_outdata; cov_od1_4 |= g4_mbist_outdata;
    if (g4_mbist_ack) cov_ack1_4 = 1'b1; else cov_ack0_4 = 1'b1;
    cov_spread5 |= {(g5_toSRAM_7_re | g5_toSRAM_7_we), (g5_toSRAM_6_re | g5_toSRAM_6_we), (g5_toSRAM_5_re | g5_toSRAM_5_we), (g5_toSRAM_4_re | g5_toSRAM_4_we), (g5_toSRAM_3_re | g5_toSRAM_3_we), (g5_toSRAM_2_re | g5_toSRAM_2_we), (g5_toSRAM_1_re | g5_toSRAM_1_we), (g5_toSRAM_0_re | g5_toSRAM_0_we)};
    cov_od0_5 |= ~g5_mbist_outdata; cov_od1_5 |= g5_mbist_outdata;
    if (g5_mbist_ack) cov_ack1_5 = 1'b1; else cov_ack0_5 = 1'b1;
    cov_spread6 |= {(g6_toSRAM_7_re | g6_toSRAM_7_we), (g6_toSRAM_6_re | g6_toSRAM_6_we), (g6_toSRAM_5_re | g6_toSRAM_5_we), (g6_toSRAM_4_re | g6_toSRAM_4_we), (g6_toSRAM_3_re | g6_toSRAM_3_we), (g6_toSRAM_2_re | g6_toSRAM_2_we), (g6_toSRAM_1_re | g6_toSRAM_1_we), (g6_toSRAM_0_re | g6_toSRAM_0_we)};
    cov_od0_6 |= ~g6_mbist_outdata; cov_od1_6 |= g6_mbist_outdata;
    if (g6_mbist_ack) cov_ack1_6 = 1'b1; else cov_ack0_6 = 1'b1;
    cov_spread7 |= {(g7_toSRAM_7_re | g7_toSRAM_7_we), (g7_toSRAM_6_re | g7_toSRAM_6_we), (g7_toSRAM_5_re | g7_toSRAM_5_we), (g7_toSRAM_4_re | g7_toSRAM_4_we), (g7_toSRAM_3_re | g7_toSRAM_3_we), (g7_toSRAM_2_re | g7_toSRAM_2_we), (g7_toSRAM_1_re | g7_toSRAM_1_we), (g7_toSRAM_0_re | g7_toSRAM_0_we)};
    cov_od0_7 |= ~g7_mbist_outdata; cov_od1_7 |= g7_mbist_outdata;
    if (g7_mbist_ack) cov_ack1_7 = 1'b1; else cov_ack0_7 = 1'b1;
    cov_spread8 |= {(g8_toSRAM_3_re | g8_toSRAM_3_we), (g8_toSRAM_2_re | g8_toSRAM_2_we), (g8_toSRAM_1_re | g8_toSRAM_1_we), (g8_toSRAM_0_re | g8_toSRAM_0_we)};
    cov_od0_8 |= ~g8_mbist_outdata; cov_od1_8 |= g8_mbist_outdata;
    if (g8_mbist_ack) cov_ack1_8 = 1'b1; else cov_ack0_8 = 1'b1;
    cov_spread9 |= {(g9_toSRAM_0_re | g9_toSRAM_0_we)};
    cov_od0_9 |= ~g9_mbist_outdata; cov_od1_9 |= g9_mbist_outdata;
    if (g9_mbist_ack) cov_ack1_9 = 1'b1; else cov_ack0_9 = 1'b1;
    cov_spread10 |= {(g10_toSRAM_0_re | g10_toSRAM_0_we)};
    cov_od0_10 |= ~g10_mbist_outdata; cov_od1_10 |= g10_mbist_outdata;
    if (g10_mbist_ack) cov_ack1_10 = 1'b1; else cov_ack0_10 = 1'b1;
    cov_spread11 |= {(g11_toSRAM_1_re | g11_toSRAM_1_we), (g11_toSRAM_0_re | g11_toSRAM_0_we)};
    cov_od0_11 |= ~g11_mbist_outdata; cov_od1_11 |= g11_mbist_outdata;
    if (g11_mbist_ack) cov_ack1_11 = 1'b1; else cov_ack0_11 = 1'b1;
    cov_spread12 |= {(g12_toSRAM_1_re | g12_toSRAM_1_we), (g12_toSRAM_0_re | g12_toSRAM_0_we)};
    cov_od0_12 |= ~g12_mbist_outdata; cov_od1_12 |= g12_mbist_outdata;
    if (g12_mbist_ack) cov_ack1_12 = 1'b1; else cov_ack0_12 = 1'b1;
    cov_spread13 |= {(g13_toSRAM_1_re | g13_toSRAM_1_we), (g13_toSRAM_0_re | g13_toSRAM_0_we)};
    cov_od0_13 |= ~g13_mbist_outdata; cov_od1_13 |= g13_mbist_outdata;
    if (g13_mbist_ack) cov_ack1_13 = 1'b1; else cov_ack0_13 = 1'b1;
    cov_spread14 |= {(g14_toSRAM_1_re | g14_toSRAM_1_we), (g14_toSRAM_0_re | g14_toSRAM_0_we)};
    cov_od0_14 |= ~g14_mbist_outdata; cov_od1_14 |= g14_mbist_outdata;
    if (g14_mbist_ack) cov_ack1_14 = 1'b1; else cov_ack0_14 = 1'b1;
    cov_spread15 |= {(g15_toNextPipeline_5_readen | g15_toNextPipeline_5_writeen), (g15_toNextPipeline_4_readen | g15_toNextPipeline_4_writeen), (g15_toNextPipeline_3_readen | g15_toNextPipeline_3_writeen), (g15_toNextPipeline_2_readen | g15_toNextPipeline_2_writeen), (g15_toNextPipeline_1_readen | g15_toNextPipeline_1_writeen), (g15_toNextPipeline_0_readen | g15_toNextPipeline_0_writeen)};
    cov_od0_15 |= ~g15_mbist_outdata; cov_od1_15 |= g15_mbist_outdata;
    if (g15_mbist_ack) cov_ack1_15 = 1'b1; else cov_ack0_15 = 1'b1;
    cov_spread16 |= {(g16_toSRAM_15_re | g16_toSRAM_15_we), (g16_toSRAM_14_re | g16_toSRAM_14_we), (g16_toSRAM_13_re | g16_toSRAM_13_we), (g16_toSRAM_12_re | g16_toSRAM_12_we), (g16_toSRAM_11_re | g16_toSRAM_11_we), (g16_toSRAM_10_re | g16_toSRAM_10_we), (g16_toSRAM_9_re | g16_toSRAM_9_we), (g16_toSRAM_8_re | g16_toSRAM_8_we), (g16_toSRAM_7_re | g16_toSRAM_7_we), (g16_toSRAM_6_re | g16_toSRAM_6_we), (g16_toSRAM_5_re | g16_toSRAM_5_we), (g16_toSRAM_4_re | g16_toSRAM_4_we), (g16_toSRAM_3_re | g16_toSRAM_3_we), (g16_toSRAM_2_re | g16_toSRAM_2_we), (g16_toSRAM_1_re | g16_toSRAM_1_we), (g16_toSRAM_0_re | g16_toSRAM_0_we)};
    cov_od0_16 |= ~g16_mbist_outdata; cov_od1_16 |= g16_mbist_outdata;
    if (g16_mbist_ack) cov_ack1_16 = 1'b1; else cov_ack0_16 = 1'b1;
    cov_spread17 |= {(g17_toSRAM_0_re | g17_toSRAM_0_we)};
    cov_od0_17 |= ~g17_mbist_outdata; cov_od1_17 |= g17_mbist_outdata;
    if (g17_mbist_ack) cov_ack1_17 = 1'b1; else cov_ack0_17 = 1'b1;
    cov_spread18 |= {(g18_toSRAM_1_re | g18_toSRAM_1_we), (g18_toSRAM_0_re | g18_toSRAM_0_we)};
    cov_od0_18 |= ~g18_mbist_outdata; cov_od1_18 |= g18_mbist_outdata;
    if (g18_mbist_ack) cov_ack1_18 = 1'b1; else cov_ack0_18 = 1'b1;
    cov_spread19 |= {(g19_toSRAM_1_re | g19_toSRAM_1_we), (g19_toSRAM_0_re | g19_toSRAM_0_we)};
    cov_od0_19 |= ~g19_mbist_outdata; cov_od1_19 |= g19_mbist_outdata;
    if (g19_mbist_ack) cov_ack1_19 = 1'b1; else cov_ack0_19 = 1'b1;
    cov_spread20 |= {(g20_toSRAM_1_re | g20_toSRAM_1_we), (g20_toSRAM_0_re | g20_toSRAM_0_we)};
    cov_od0_20 |= ~g20_mbist_outdata; cov_od1_20 |= g20_mbist_outdata;
    if (g20_mbist_ack) cov_ack1_20 = 1'b1; else cov_ack0_20 = 1'b1;
    cov_spread21 |= {(g21_toSRAM_1_re | g21_toSRAM_1_we), (g21_toSRAM_0_re | g21_toSRAM_0_we)};
    cov_od0_21 |= ~g21_mbist_outdata; cov_od1_21 |= g21_mbist_outdata;
    if (g21_mbist_ack) cov_ack1_21 = 1'b1; else cov_ack0_21 = 1'b1;
    cov_spread22 |= {(g22_toSRAM_0_re | g22_toSRAM_0_we)};
    cov_od0_22 |= ~g22_mbist_outdata; cov_od1_22 |= g22_mbist_outdata;
    if (g22_mbist_ack) cov_ack1_22 = 1'b1; else cov_ack0_22 = 1'b1;
    cov_spread23 |= {(g23_toSRAM_23_re | g23_toSRAM_23_we), (g23_toSRAM_22_re | g23_toSRAM_22_we), (g23_toSRAM_21_re | g23_toSRAM_21_we), (g23_toSRAM_20_re | g23_toSRAM_20_we), (g23_toSRAM_19_re | g23_toSRAM_19_we), (g23_toSRAM_18_re | g23_toSRAM_18_we), (g23_toSRAM_17_re | g23_toSRAM_17_we), (g23_toSRAM_16_re | g23_toSRAM_16_we), (g23_toSRAM_15_re | g23_toSRAM_15_we), (g23_toSRAM_14_re | g23_toSRAM_14_we), (g23_toSRAM_13_re | g23_toSRAM_13_we), (g23_toSRAM_12_re | g23_toSRAM_12_we), (g23_toSRAM_11_re | g23_toSRAM_11_we), (g23_toSRAM_10_re | g23_toSRAM_10_we), (g23_toSRAM_9_re | g23_toSRAM_9_we), (g23_toSRAM_8_re | g23_toSRAM_8_we), (g23_toSRAM_7_re | g23_toSRAM_7_we), (g23_toSRAM_6_re | g23_toSRAM_6_we), (g23_toSRAM_5_re | g23_toSRAM_5_we), (g23_toSRAM_4_re | g23_toSRAM_4_we), (g23_toSRAM_3_re | g23_toSRAM_3_we), (g23_toSRAM_2_re | g23_toSRAM_2_we), (g23_toSRAM_1_re | g23_toSRAM_1_we), (g23_toSRAM_0_re | g23_toSRAM_0_we)};
    cov_od0_23 |= ~g23_mbist_outdata; cov_od1_23 |= g23_mbist_outdata;
    if (g23_mbist_ack) cov_ack1_23 = 1'b1; else cov_ack0_23 = 1'b1;
  endtask

  // ---------------- 覆盖闸判定 ----------------
  function automatic int unsigned cov_gate();
    int unsigned bad;
    bad = 0;
    if (!(&cov_id))    begin bad++; $display("  [COV FAIL] 有 array 编号从未以 req&!all 打过: %b", cov_id); end
    if (!(&cov_addr0) || !(&cov_addr1)) begin bad++; $display("  [COV FAIL] 地址位未全翻转 zero=%b one=%b", cov_addr0, cov_addr1); end
    if (!(&cov_be0) || !(&cov_be1))     begin bad++; $display("  [COV FAIL] be 位未全翻转"); end
    if (!(&cov_din0) || !(&cov_din1))   begin bad++; $display("  [COV FAIL] indata 位未全翻转"); end
    if (!cov_all_bcast) begin bad++; $display("  [COV FAIL] all 广播从未出现"); end
    if (!cov_idle)      begin bad++; $display("  [COV FAIL] 空闲拍从未出现"); end
    if (!cov_wr || !cov_rd || !cov_rdwr) begin bad++; $display("  [COV FAIL] 读/写/读写并发组合未覆盖全"); end
    if (!(&cov_spread0)) begin bad++; $display("  [COV FAIL] MbistPipeDCacheData 有 child 从未被铺开: %b", cov_spread0); end
    if (!(&cov_od0_0) || !(&cov_od1_0)) begin bad++; $display("  [COV FAIL] MbistPipeDCacheData mbist_outdata 有位未翻转"); end
    if (!cov_ack0_0 || !cov_ack1_0) begin bad++; $display("  [COV FAIL] MbistPipeDCacheData mbist_ack 未两态"); end
    if (!(&cov_spread1)) begin bad++; $display("  [COV FAIL] MbistPipeDcacheTag 有 child 从未被铺开: %b", cov_spread1); end
    if (!(&cov_od0_1) || !(&cov_od1_1)) begin bad++; $display("  [COV FAIL] MbistPipeDcacheTag mbist_outdata 有位未翻转"); end
    if (!cov_ack0_1 || !cov_ack1_1) begin bad++; $display("  [COV FAIL] MbistPipeDcacheTag mbist_ack 未两态"); end
    if (!(&cov_spread2)) begin bad++; $display("  [COV FAIL] MbistPipeFrontend 有 child 从未被铺开: %b", cov_spread2); end
    if (!(&cov_od0_2) || !(&cov_od1_2)) begin bad++; $display("  [COV FAIL] MbistPipeFrontend mbist_outdata 有位未翻转"); end
    if (!cov_ack0_2 || !cov_ack1_2) begin bad++; $display("  [COV FAIL] MbistPipeFrontend mbist_ack 未两态"); end
    if (!(&cov_spread3)) begin bad++; $display("  [COV FAIL] MbistPipeFtb 有 child 从未被铺开: %b", cov_spread3); end
    if (!(&cov_od0_3) || !(&cov_od1_3)) begin bad++; $display("  [COV FAIL] MbistPipeFtb mbist_outdata 有位未翻转"); end
    if (!cov_ack0_3 || !cov_ack1_3) begin bad++; $display("  [COV FAIL] MbistPipeFtb mbist_ack 未两态"); end
    if (!(&cov_spread4)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay0 有 child 从未被铺开: %b", cov_spread4); end
    if (!(&cov_od0_4) || !(&cov_od1_4)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay0 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_4 || !cov_ack1_4) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay0 mbist_ack 未两态"); end
    if (!(&cov_spread5)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay1 有 child 从未被铺开: %b", cov_spread5); end
    if (!(&cov_od0_5) || !(&cov_od1_5)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay1 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_5 || !cov_ack1_5) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay1 mbist_ack 未两态"); end
    if (!(&cov_spread6)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay2 有 child 从未被铺开: %b", cov_spread6); end
    if (!(&cov_od0_6) || !(&cov_od1_6)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay2 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_6 || !cov_ack1_6) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay2 mbist_ack 未两态"); end
    if (!(&cov_spread7)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay3 有 child 从未被铺开: %b", cov_spread7); end
    if (!(&cov_od0_7) || !(&cov_od1_7)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay3 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_7 || !cov_ack1_7) begin bad++; $display("  [COV FAIL] MbistPipeIcacheDataWay3 mbist_ack 未两态"); end
    if (!(&cov_spread8)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheTag 有 child 从未被铺开: %b", cov_spread8); end
    if (!(&cov_od0_8) || !(&cov_od1_8)) begin bad++; $display("  [COV FAIL] MbistPipeIcacheTag mbist_outdata 有位未翻转"); end
    if (!cov_ack0_8 || !cov_ack1_8) begin bad++; $display("  [COV FAIL] MbistPipeIcacheTag mbist_ack 未两态"); end
    if (!(&cov_spread9)) begin bad++; $display("  [COV FAIL] MbistPipeIttage 有 child 从未被铺开: %b", cov_spread9); end
    if (!(&cov_od0_9) || !(&cov_od1_9)) begin bad++; $display("  [COV FAIL] MbistPipeIttage mbist_outdata 有位未翻转"); end
    if (!cov_ack0_9 || !cov_ack1_9) begin bad++; $display("  [COV FAIL] MbistPipeIttage mbist_ack 未两态"); end
    if (!(&cov_spread10)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_1 有 child 从未被铺开: %b", cov_spread10); end
    if (!(&cov_od0_10) || !(&cov_od1_10)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_1 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_10 || !cov_ack1_10) begin bad++; $display("  [COV FAIL] MbistPipeIttage_1 mbist_ack 未两态"); end
    if (!(&cov_spread11)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_2 有 child 从未被铺开: %b", cov_spread11); end
    if (!(&cov_od0_11) || !(&cov_od1_11)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_2 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_11 || !cov_ack1_11) begin bad++; $display("  [COV FAIL] MbistPipeIttage_2 mbist_ack 未两态"); end
    if (!(&cov_spread12)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_3 有 child 从未被铺开: %b", cov_spread12); end
    if (!(&cov_od0_12) || !(&cov_od1_12)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_3 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_12 || !cov_ack1_12) begin bad++; $display("  [COV FAIL] MbistPipeIttage_3 mbist_ack 未两态"); end
    if (!(&cov_spread13)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_4 有 child 从未被铺开: %b", cov_spread13); end
    if (!(&cov_od0_13) || !(&cov_od1_13)) begin bad++; $display("  [COV FAIL] MbistPipeIttage_4 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_13 || !cov_ack1_13) begin bad++; $display("  [COV FAIL] MbistPipeIttage_4 mbist_ack 未两态"); end
    if (!(&cov_spread14)) begin bad++; $display("  [COV FAIL] MbistPipeL2Prefetcher 有 child 从未被铺开: %b", cov_spread14); end
    if (!(&cov_od0_14) || !(&cov_od1_14)) begin bad++; $display("  [COV FAIL] MbistPipeL2Prefetcher mbist_outdata 有位未翻转"); end
    if (!cov_ack0_14 || !cov_ack1_14) begin bad++; $display("  [COV FAIL] MbistPipeL2Prefetcher mbist_ack 未两态"); end
    if (!(&cov_spread15)) begin bad++; $display("  [COV FAIL] MbistPipeMemBlk 有 child 从未被铺开: %b", cov_spread15); end
    if (!(&cov_od0_15) || !(&cov_od1_15)) begin bad++; $display("  [COV FAIL] MbistPipeMemBlk mbist_outdata 有位未翻转"); end
    if (!cov_ack0_15 || !cov_ack1_15) begin bad++; $display("  [COV FAIL] MbistPipeMemBlk mbist_ack 未两态"); end
    if (!(&cov_spread16)) begin bad++; $display("  [COV FAIL] MbistPipePtwL0 有 child 从未被铺开: %b", cov_spread16); end
    if (!(&cov_od0_16) || !(&cov_od1_16)) begin bad++; $display("  [COV FAIL] MbistPipePtwL0 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_16 || !cov_ack1_16) begin bad++; $display("  [COV FAIL] MbistPipePtwL0 mbist_ack 未两态"); end
    if (!(&cov_spread17)) begin bad++; $display("  [COV FAIL] MbistPipePtwL1 有 child 从未被铺开: %b", cov_spread17); end
    if (!(&cov_od0_17) || !(&cov_od1_17)) begin bad++; $display("  [COV FAIL] MbistPipePtwL1 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_17 || !cov_ack1_17) begin bad++; $display("  [COV FAIL] MbistPipePtwL1 mbist_ack 未两态"); end
    if (!(&cov_spread18)) begin bad++; $display("  [COV FAIL] MbistPipeSc 有 child 从未被铺开: %b", cov_spread18); end
    if (!(&cov_od0_18) || !(&cov_od1_18)) begin bad++; $display("  [COV FAIL] MbistPipeSc mbist_outdata 有位未翻转"); end
    if (!cov_ack0_18 || !cov_ack1_18) begin bad++; $display("  [COV FAIL] MbistPipeSc mbist_ack 未两态"); end
    if (!(&cov_spread19)) begin bad++; $display("  [COV FAIL] MbistPipeSc_1 有 child 从未被铺开: %b", cov_spread19); end
    if (!(&cov_od0_19) || !(&cov_od1_19)) begin bad++; $display("  [COV FAIL] MbistPipeSc_1 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_19 || !cov_ack1_19) begin bad++; $display("  [COV FAIL] MbistPipeSc_1 mbist_ack 未两态"); end
    if (!(&cov_spread20)) begin bad++; $display("  [COV FAIL] MbistPipeSc_2 有 child 从未被铺开: %b", cov_spread20); end
    if (!(&cov_od0_20) || !(&cov_od1_20)) begin bad++; $display("  [COV FAIL] MbistPipeSc_2 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_20 || !cov_ack1_20) begin bad++; $display("  [COV FAIL] MbistPipeSc_2 mbist_ack 未两态"); end
    if (!(&cov_spread21)) begin bad++; $display("  [COV FAIL] MbistPipeSc_3 有 child 从未被铺开: %b", cov_spread21); end
    if (!(&cov_od0_21) || !(&cov_od1_21)) begin bad++; $display("  [COV FAIL] MbistPipeSc_3 mbist_outdata 有位未翻转"); end
    if (!cov_ack0_21 || !cov_ack1_21) begin bad++; $display("  [COV FAIL] MbistPipeSc_3 mbist_ack 未两态"); end
    if (!(&cov_spread22)) begin bad++; $display("  [COV FAIL] MbistPipeSms 有 child 从未被铺开: %b", cov_spread22); end
    if (!(&cov_od0_22) || !(&cov_od1_22)) begin bad++; $display("  [COV FAIL] MbistPipeSms mbist_outdata 有位未翻转"); end
    if (!cov_ack0_22 || !cov_ack1_22) begin bad++; $display("  [COV FAIL] MbistPipeSms mbist_ack 未两态"); end
    if (!(&cov_spread23)) begin bad++; $display("  [COV FAIL] MbistPipeTage 有 child 从未被铺开: %b", cov_spread23); end
    if (!(&cov_od0_23) || !(&cov_od1_23)) begin bad++; $display("  [COV FAIL] MbistPipeTage mbist_outdata 有位未翻转"); end
    if (!cov_ack0_23 || !cov_ack1_23) begin bad++; $display("  [COV FAIL] MbistPipeTage mbist_ack 未两态"); end
    return bad;
  endfunction

  // ---------------- 激励 ----------------
  task automatic drive_random();
    s_array   = $urandom_range(0, 127);
    s_all     = ($urandom_range(0, 15) == 0);   // 广播是少数派
    s_req     = ($urandom_range(0, 9) != 0);
    s_wen     = $urandom_range(0, 1);
    s_ren     = $urandom_range(0, 1);
    s_be = {$urandom, $urandom, $urandom};
    s_indata = {$urandom, $urandom, $urandom, $urandom, $urandom};
    s_addr    = $urandom;
    s_addr_rd = $urandom;
  endtask

  // 定向阶段：把 128 个 array 编号逐个扫一遍，并让地址/数据/be 走全 0、全 1、
  // 逐位游走三种图形——MBIST 地址位宽是本家族最容易写错的地方（G1 里普遍是
  // 按最大 id 算出来的最小位宽），不把每一位都打到就等于没验位宽。
  task automatic drive_directed(input int unsigned k);
    int unsigned phase, idx;
    phase = (k / 128) % 6;
    idx   = k % 128;
    s_array   = idx[6:0];
    s_req     = 1'b1;
    s_all     = (phase == 5);
    s_wen     = (phase != 1);
    s_ren     = (phase != 2);
    case (phase)
      0: begin s_addr = '0; s_addr_rd = '0; s_be = '0; s_indata = '0; end
      1: begin s_addr = '1; s_addr_rd = '1; s_be = '1; s_indata = '1; end
      2: begin s_addr = 10'(1) << (idx % 10); s_addr_rd = 10'(1) << ((idx+3) % 10);
           s_be = 76'(1) << (idx % 76); s_indata = 148'(1) << (idx % 148); end
      3: begin s_addr = ~(10'(1) << (idx % 10)); s_addr_rd = '1;
           s_be = ~(76'(1) << (idx % 76)); s_indata = ~(148'(1) << (idx % 148)); end
      default: begin s_addr = $urandom; s_addr_rd = $urandom;
           s_be = {$urandom, $urandom, $urandom}; s_indata = {$urandom, $urandom, $urandom, $urandom, $urandom}; end
    endcase
  endtask

  task automatic drive_children();
    v0_rd0 = {$urandom, $urandom, $urandom};
    v0_rd1 = {$urandom, $urandom, $urandom};
    v0_rd2 = {$urandom, $urandom, $urandom};
    v0_rd3 = {$urandom, $urandom, $urandom};
    v0_rd4 = {$urandom, $urandom, $urandom};
    v0_rd5 = {$urandom, $urandom, $urandom};
    v0_rd6 = {$urandom, $urandom, $urandom};
    v0_rd7 = {$urandom, $urandom, $urandom};
    v0_rd8 = {$urandom, $urandom, $urandom};
    v0_rd9 = {$urandom, $urandom, $urandom};
    v0_rd10 = {$urandom, $urandom, $urandom};
    v0_rd11 = {$urandom, $urandom, $urandom};
    v0_rd12 = {$urandom, $urandom, $urandom};
    v0_rd13 = {$urandom, $urandom, $urandom};
    v0_rd14 = {$urandom, $urandom, $urandom};
    v0_rd15 = {$urandom, $urandom, $urandom};
    v0_rd16 = {$urandom, $urandom, $urandom};
    v0_rd17 = {$urandom, $urandom, $urandom};
    v0_rd18 = {$urandom, $urandom, $urandom};
    v0_rd19 = {$urandom, $urandom, $urandom};
    v0_rd20 = {$urandom, $urandom, $urandom};
    v0_rd21 = {$urandom, $urandom, $urandom};
    v0_rd22 = {$urandom, $urandom, $urandom};
    v0_rd23 = {$urandom, $urandom, $urandom};
    v0_rd24 = {$urandom, $urandom, $urandom};
    v0_rd25 = {$urandom, $urandom, $urandom};
    v0_rd26 = {$urandom, $urandom, $urandom};
    v0_rd27 = {$urandom, $urandom, $urandom};
    v0_rd28 = {$urandom, $urandom, $urandom};
    v0_rd29 = {$urandom, $urandom, $urandom};
    v0_rd30 = {$urandom, $urandom, $urandom};
    v0_rd31 = {$urandom, $urandom, $urandom};
    v1_rd0 = {$urandom, $urandom, $urandom};
    v1_rd1 = {$urandom, $urandom, $urandom};
    v1_rd2 = {$urandom, $urandom, $urandom};
    v1_rd3 = {$urandom, $urandom, $urandom};
    v1_rd4 = {$urandom, $urandom, $urandom};
    v1_rd5 = {$urandom, $urandom, $urandom};
    v1_rd6 = {$urandom, $urandom, $urandom};
    v1_rd7 = {$urandom, $urandom, $urandom};
    v2_rd0 = {$urandom, $urandom, $urandom};
    v2_ack0 = $urandom_range(0, 1);
    v2_rd1 = {$urandom, $urandom, $urandom};
    v2_ack1 = $urandom_range(0, 1);
    v2_rd2 = {$urandom, $urandom, $urandom};
    v2_ack2 = $urandom_range(0, 1);
    v2_rd3 = {$urandom, $urandom, $urandom};
    v2_ack3 = $urandom_range(0, 1);
    v2_rd4 = {$urandom, $urandom, $urandom};
    v2_ack4 = $urandom_range(0, 1);
    v2_rd5 = {$urandom, $urandom};
    v2_ack5 = $urandom_range(0, 1);
    v2_rd6 = {$urandom};
    v2_ack6 = $urandom_range(0, 1);
    v2_rd7 = {$urandom};
    v2_ack7 = $urandom_range(0, 1);
    v2_rd8 = {$urandom};
    v2_ack8 = $urandom_range(0, 1);
    v2_rd9 = {$urandom};
    v2_ack9 = $urandom_range(0, 1);
    v2_rd10 = {$urandom};
    v2_ack10 = $urandom_range(0, 1);
    v2_rd11 = {$urandom, $urandom, $urandom};
    v2_ack11 = $urandom_range(0, 1);
    v2_rd12 = {$urandom, $urandom, $urandom};
    v2_ack12 = $urandom_range(0, 1);
    v2_rd13 = {$urandom, $urandom, $urandom};
    v2_ack13 = $urandom_range(0, 1);
    v2_rd14 = {$urandom, $urandom, $urandom};
    v2_ack14 = $urandom_range(0, 1);
    v2_rd15 = {$urandom, $urandom, $urandom};
    v2_ack15 = $urandom_range(0, 1);
    v3_rd0 = {$urandom, $urandom};
    v3_rd1 = {$urandom, $urandom};
    v3_rd2 = {$urandom, $urandom};
    v3_rd3 = {$urandom, $urandom};
    v3_rd4 = {$urandom, $urandom};
    v3_rd5 = {$urandom, $urandom};
    v3_rd6 = {$urandom, $urandom};
    v3_rd7 = {$urandom, $urandom};
    v4_rd0 = {$urandom, $urandom, $urandom};
    v4_rd1 = {$urandom, $urandom, $urandom};
    v4_rd2 = {$urandom, $urandom, $urandom};
    v4_rd3 = {$urandom, $urandom, $urandom};
    v4_rd4 = {$urandom, $urandom, $urandom};
    v4_rd5 = {$urandom, $urandom, $urandom};
    v4_rd6 = {$urandom, $urandom, $urandom};
    v4_rd7 = {$urandom, $urandom, $urandom};
    v5_rd0 = {$urandom, $urandom, $urandom};
    v5_rd1 = {$urandom, $urandom, $urandom};
    v5_rd2 = {$urandom, $urandom, $urandom};
    v5_rd3 = {$urandom, $urandom, $urandom};
    v5_rd4 = {$urandom, $urandom, $urandom};
    v5_rd5 = {$urandom, $urandom, $urandom};
    v5_rd6 = {$urandom, $urandom, $urandom};
    v5_rd7 = {$urandom, $urandom, $urandom};
    v6_rd0 = {$urandom, $urandom, $urandom};
    v6_rd1 = {$urandom, $urandom, $urandom};
    v6_rd2 = {$urandom, $urandom, $urandom};
    v6_rd3 = {$urandom, $urandom, $urandom};
    v6_rd4 = {$urandom, $urandom, $urandom};
    v6_rd5 = {$urandom, $urandom, $urandom};
    v6_rd6 = {$urandom, $urandom, $urandom};
    v6_rd7 = {$urandom, $urandom, $urandom};
    v7_rd0 = {$urandom, $urandom, $urandom};
    v7_rd1 = {$urandom, $urandom, $urandom};
    v7_rd2 = {$urandom, $urandom, $urandom};
    v7_rd3 = {$urandom, $urandom, $urandom};
    v7_rd4 = {$urandom, $urandom, $urandom};
    v7_rd5 = {$urandom, $urandom, $urandom};
    v7_rd6 = {$urandom, $urandom, $urandom};
    v7_rd7 = {$urandom, $urandom, $urandom};
    v8_rd0 = {$urandom, $urandom, $urandom};
    v8_rd1 = {$urandom, $urandom, $urandom};
    v8_rd2 = {$urandom, $urandom, $urandom};
    v8_rd3 = {$urandom, $urandom, $urandom};
    v9_rd0 = {$urandom, $urandom, $urandom};
    v10_rd0 = {$urandom, $urandom, $urandom};
    v11_rd0 = {$urandom, $urandom, $urandom};
    v11_rd1 = {$urandom, $urandom, $urandom};
    v12_rd0 = {$urandom, $urandom, $urandom};
    v12_rd1 = {$urandom, $urandom, $urandom};
    v13_rd0 = {$urandom, $urandom, $urandom};
    v13_rd1 = {$urandom, $urandom, $urandom};
    v14_rd0 = {$urandom};
    v14_rd1 = {$urandom};
    v15_rd0 = {$urandom, $urandom, $urandom};
    v15_ack0 = $urandom_range(0, 1);
    v15_rd1 = {$urandom, $urandom, $urandom};
    v15_ack1 = $urandom_range(0, 1);
    v15_rd2 = {$urandom, $urandom, $urandom};
    v15_ack2 = $urandom_range(0, 1);
    v15_rd3 = {$urandom, $urandom, $urandom, $urandom, $urandom};
    v15_ack3 = $urandom_range(0, 1);
    v15_rd4 = {$urandom, $urandom, $urandom, $urandom};
    v15_ack4 = $urandom_range(0, 1);
    v15_rd5 = {$urandom, $urandom, $urandom, $urandom, $urandom};
    v15_ack5 = $urandom_range(0, 1);
    v16_rd0 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd1 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd2 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd3 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd4 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd5 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd6 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd7 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd8 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd9 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd10 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd11 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd12 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd13 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd14 = {$urandom, $urandom, $urandom, $urandom};
    v16_rd15 = {$urandom, $urandom, $urandom, $urandom};
    v17_rd0 = {$urandom, $urandom, $urandom, $urandom, $urandom};
    v18_rd0 = {$urandom};
    v18_rd1 = {$urandom};
    v19_rd0 = {$urandom};
    v19_rd1 = {$urandom};
    v20_rd0 = {$urandom};
    v20_rd1 = {$urandom};
    v21_rd0 = {$urandom};
    v21_rd1 = {$urandom};
    v22_rd0 = {$urandom, $urandom, $urandom, $urandom, $urandom};
    v23_rd0 = {$urandom};
    v23_rd1 = {$urandom};
    v23_rd2 = {$urandom};
    v23_rd3 = {$urandom};
    v23_rd4 = {$urandom};
    v23_rd5 = {$urandom};
    v23_rd6 = {$urandom};
    v23_rd7 = {$urandom};
    v23_rd8 = {$urandom};
    v23_rd9 = {$urandom};
    v23_rd10 = {$urandom};
    v23_rd11 = {$urandom};
    v23_rd12 = {$urandom};
    v23_rd13 = {$urandom};
    v23_rd14 = {$urandom};
    v23_rd15 = {$urandom};
    v23_rd16 = {$urandom};
    v23_rd17 = {$urandom};
    v23_rd18 = {$urandom};
    v23_rd19 = {$urandom};
    v23_rd20 = {$urandom};
    v23_rd21 = {$urandom};
    v23_rd22 = {$urandom};
    v23_rd23 = {$urandom};
  endtask

  // ---------------- 主流程 ----------------
  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    s_array = '0; s_all = 1'b0; s_req = 1'b0; s_wen = 1'b0; s_ren = 1'b0;
    s_be = '0; s_addr = '0; s_addr_rd = '0; s_indata = '0;
    drive_children();
    repeat (4) @(posedge clock);
    reset = 1'b0;
    // 开闸前先打两拍 all 广播读：中间节点的 pipelineDataOutReg 在 golden 里
    // **没有复位**，上电是随机值，两侧随机数不同。先用 activated=1 的拍把它
    // 载成同一个确定值，之后所有比对都是无条件的（没有 X 跳过守卫）。
    @(negedge clock);
    s_all = 1'b1; s_req = 1'b1; s_ren = 1'b1; s_wen = 1'b1;
    @(posedge clock); @(negedge clock);
    drive_children();
    @(posedge clock); @(negedge clock);
    armed = 1'b1;

    for (int unsigned i = 0; i < ncycles; i++) begin
      drive_children();
      if (i < 1536) drive_directed(i);   // 前 1536 拍走定向图形
      else          drive_random();
      sample_cov();
      @(posedge clock);
      #1;
      cyc++;
      compare_all();
      @(negedge clock);
    end

    finish_report();
  end

  task automatic finish_report();
    longint unsigned expect_checks;
    int unsigned covbad;
    expect_checks = N_OUT_PORTS * cmp_cycles;
    covbad = cov_gate();
    $display("=== MbistPipe family UT ===");
    $display("  variants   = 24 (22 leaf + 2 node)");
    $display("  cycles     = %0d", cmp_cycles);
    $display("  out ports  = %0d", N_OUT_PORTS);
    $display("  checks     = %0d", checks);
    $display("  expected   = %0d  (out ports x cycles)", expect_checks);
    $display("  errors     = %0d", errors);
    $display("  cov fails  = %0d", covbad);
    if (checks != expect_checks) begin
      $display("=== TEST FAILED: checks(%0d) != 输出端口数 x 拍数(%0d) —— 有比对被静默跳过 ===",
               checks, expect_checks);
      $fatal(1, "check accounting mismatch");
    end
    if (errors != 0) begin
      $display("=== TEST FAILED: errors=%0d ===", errors); $fatal(1, "mismatch");
    end
    if (covbad != 0) begin
      $display("=== TEST FAILED: 覆盖闸未过 (%0d 项) ===", covbad); $fatal(1, "coverage");
    end
    $display("=== TEST PASSED ===");
    $finish;
  endtask

endmodule
