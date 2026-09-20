// SplittedSRAM_2.sv —— PtwCache 的 l0：level-0 叶子 PTE（4KB 页）扇区缓存（SplittedSRAM 家族变体，规模 64 set × 4 way × 456 bit/entry）。
// 本变体参数：tagLen=29、hasPerm=true、ReservedBits=4、waySplit=2、dataSplit=8
//   ⇒ 拆成 16 块内层 SRAM，每块 2 路 × 57 bit（way 维 2 组 × data 维 8 段）。
// 本层无任何寄存器：只做 PtwEntries 的打包/切分/归并，存储与读时序在内层
// SRAMTemplate_* 及其下的厂商 SRAM 宏里。核体见 SplittedSRAM_ptw_core.sv。
// 自动生成：scripts/gen_splittedsram.py（端口表与内层例化连线逐字取自 G1 golden）—— 勿手改。
// 本文件导航（共 2416 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L1049  参数与阵列侧总线
//   L1094  打包/切分核 u_core：写侧接线
//   L1497  16 块内层 SRAM：每块自带一套 MBIST bore 与 sigFromSrams 广播
//   L1501  内层 SRAM #0：array_0_0_0
//   L1535  内层 SRAM #1：array_0_0_1
//   L1569  内层 SRAM #2：array_0_0_2
//   L1603  内层 SRAM #3：array_0_0_3
//   L1637  内层 SRAM #4：array_0_0_4
//   L1671  内层 SRAM #5：array_0_0_5
//   L1705  内层 SRAM #6：array_0_0_6
//   L1739  内层 SRAM #7：array_0_0_7
//   L1773  内层 SRAM #8：array_0_1_0
//   L1807  内层 SRAM #9：array_0_1_1
//   L1841  内层 SRAM #10：array_0_1_2
//   L1875  内层 SRAM #11：array_0_1_3
//   L1909  内层 SRAM #12：array_0_1_4
//   L1943  内层 SRAM #13：array_0_1_5
//   L1977  内层 SRAM #14：array_0_1_6
//   L2011  内层 SRAM #15：array_0_1_7
//   L2046  读出回填：把核给出的 struct 字段摊回 golden 的扁平输出端口
//

module SplittedSRAM_2(
  input          clock,
  input          reset,
  input          io_r_req_valid,
  input  [5:0]   io_r_req_bits_setIdx,
  output [28:0]  io_r_resp_data_0_entries_tag,
  output [15:0]  io_r_resp_data_0_entries_asid,
  output [13:0]  io_r_resp_data_0_entries_vmid,
  output [1:0]   io_r_resp_data_0_entries_pbmts_0,
  output [1:0]   io_r_resp_data_0_entries_pbmts_1,
  output [1:0]   io_r_resp_data_0_entries_pbmts_2,
  output [1:0]   io_r_resp_data_0_entries_pbmts_3,
  output [1:0]   io_r_resp_data_0_entries_pbmts_4,
  output [1:0]   io_r_resp_data_0_entries_pbmts_5,
  output [1:0]   io_r_resp_data_0_entries_pbmts_6,
  output [1:0]   io_r_resp_data_0_entries_pbmts_7,
  output [37:0]  io_r_resp_data_0_entries_ppns_0,
  output [37:0]  io_r_resp_data_0_entries_ppns_1,
  output [37:0]  io_r_resp_data_0_entries_ppns_2,
  output [37:0]  io_r_resp_data_0_entries_ppns_3,
  output [37:0]  io_r_resp_data_0_entries_ppns_4,
  output [37:0]  io_r_resp_data_0_entries_ppns_5,
  output [37:0]  io_r_resp_data_0_entries_ppns_6,
  output [37:0]  io_r_resp_data_0_entries_ppns_7,
  output         io_r_resp_data_0_entries_vs_0,
  output         io_r_resp_data_0_entries_vs_1,
  output         io_r_resp_data_0_entries_vs_2,
  output         io_r_resp_data_0_entries_vs_3,
  output         io_r_resp_data_0_entries_vs_4,
  output         io_r_resp_data_0_entries_vs_5,
  output         io_r_resp_data_0_entries_vs_6,
  output         io_r_resp_data_0_entries_vs_7,
  output         io_r_resp_data_0_entries_onlypf_0,
  output         io_r_resp_data_0_entries_onlypf_1,
  output         io_r_resp_data_0_entries_onlypf_2,
  output         io_r_resp_data_0_entries_onlypf_3,
  output         io_r_resp_data_0_entries_onlypf_4,
  output         io_r_resp_data_0_entries_onlypf_5,
  output         io_r_resp_data_0_entries_onlypf_6,
  output         io_r_resp_data_0_entries_onlypf_7,
  output         io_r_resp_data_0_entries_perms_0_d,
  output         io_r_resp_data_0_entries_perms_0_a,
  output         io_r_resp_data_0_entries_perms_0_g,
  output         io_r_resp_data_0_entries_perms_0_u,
  output         io_r_resp_data_0_entries_perms_0_x,
  output         io_r_resp_data_0_entries_perms_0_w,
  output         io_r_resp_data_0_entries_perms_0_r,
  output         io_r_resp_data_0_entries_perms_1_d,
  output         io_r_resp_data_0_entries_perms_1_a,
  output         io_r_resp_data_0_entries_perms_1_g,
  output         io_r_resp_data_0_entries_perms_1_u,
  output         io_r_resp_data_0_entries_perms_1_x,
  output         io_r_resp_data_0_entries_perms_1_w,
  output         io_r_resp_data_0_entries_perms_1_r,
  output         io_r_resp_data_0_entries_perms_2_d,
  output         io_r_resp_data_0_entries_perms_2_a,
  output         io_r_resp_data_0_entries_perms_2_g,
  output         io_r_resp_data_0_entries_perms_2_u,
  output         io_r_resp_data_0_entries_perms_2_x,
  output         io_r_resp_data_0_entries_perms_2_w,
  output         io_r_resp_data_0_entries_perms_2_r,
  output         io_r_resp_data_0_entries_perms_3_d,
  output         io_r_resp_data_0_entries_perms_3_a,
  output         io_r_resp_data_0_entries_perms_3_g,
  output         io_r_resp_data_0_entries_perms_3_u,
  output         io_r_resp_data_0_entries_perms_3_x,
  output         io_r_resp_data_0_entries_perms_3_w,
  output         io_r_resp_data_0_entries_perms_3_r,
  output         io_r_resp_data_0_entries_perms_4_d,
  output         io_r_resp_data_0_entries_perms_4_a,
  output         io_r_resp_data_0_entries_perms_4_g,
  output         io_r_resp_data_0_entries_perms_4_u,
  output         io_r_resp_data_0_entries_perms_4_x,
  output         io_r_resp_data_0_entries_perms_4_w,
  output         io_r_resp_data_0_entries_perms_4_r,
  output         io_r_resp_data_0_entries_perms_5_d,
  output         io_r_resp_data_0_entries_perms_5_a,
  output         io_r_resp_data_0_entries_perms_5_g,
  output         io_r_resp_data_0_entries_perms_5_u,
  output         io_r_resp_data_0_entries_perms_5_x,
  output         io_r_resp_data_0_entries_perms_5_w,
  output         io_r_resp_data_0_entries_perms_5_r,
  output         io_r_resp_data_0_entries_perms_6_d,
  output         io_r_resp_data_0_entries_perms_6_a,
  output         io_r_resp_data_0_entries_perms_6_g,
  output         io_r_resp_data_0_entries_perms_6_u,
  output         io_r_resp_data_0_entries_perms_6_x,
  output         io_r_resp_data_0_entries_perms_6_w,
  output         io_r_resp_data_0_entries_perms_6_r,
  output         io_r_resp_data_0_entries_perms_7_d,
  output         io_r_resp_data_0_entries_perms_7_a,
  output         io_r_resp_data_0_entries_perms_7_g,
  output         io_r_resp_data_0_entries_perms_7_u,
  output         io_r_resp_data_0_entries_perms_7_x,
  output         io_r_resp_data_0_entries_perms_7_w,
  output         io_r_resp_data_0_entries_perms_7_r,
  output         io_r_resp_data_0_entries_prefetch,
  output [28:0]  io_r_resp_data_1_entries_tag,
  output [15:0]  io_r_resp_data_1_entries_asid,
  output [13:0]  io_r_resp_data_1_entries_vmid,
  output [1:0]   io_r_resp_data_1_entries_pbmts_0,
  output [1:0]   io_r_resp_data_1_entries_pbmts_1,
  output [1:0]   io_r_resp_data_1_entries_pbmts_2,
  output [1:0]   io_r_resp_data_1_entries_pbmts_3,
  output [1:0]   io_r_resp_data_1_entries_pbmts_4,
  output [1:0]   io_r_resp_data_1_entries_pbmts_5,
  output [1:0]   io_r_resp_data_1_entries_pbmts_6,
  output [1:0]   io_r_resp_data_1_entries_pbmts_7,
  output [37:0]  io_r_resp_data_1_entries_ppns_0,
  output [37:0]  io_r_resp_data_1_entries_ppns_1,
  output [37:0]  io_r_resp_data_1_entries_ppns_2,
  output [37:0]  io_r_resp_data_1_entries_ppns_3,
  output [37:0]  io_r_resp_data_1_entries_ppns_4,
  output [37:0]  io_r_resp_data_1_entries_ppns_5,
  output [37:0]  io_r_resp_data_1_entries_ppns_6,
  output [37:0]  io_r_resp_data_1_entries_ppns_7,
  output         io_r_resp_data_1_entries_vs_0,
  output         io_r_resp_data_1_entries_vs_1,
  output         io_r_resp_data_1_entries_vs_2,
  output         io_r_resp_data_1_entries_vs_3,
  output         io_r_resp_data_1_entries_vs_4,
  output         io_r_resp_data_1_entries_vs_5,
  output         io_r_resp_data_1_entries_vs_6,
  output         io_r_resp_data_1_entries_vs_7,
  output         io_r_resp_data_1_entries_onlypf_0,
  output         io_r_resp_data_1_entries_onlypf_1,
  output         io_r_resp_data_1_entries_onlypf_2,
  output         io_r_resp_data_1_entries_onlypf_3,
  output         io_r_resp_data_1_entries_onlypf_4,
  output         io_r_resp_data_1_entries_onlypf_5,
  output         io_r_resp_data_1_entries_onlypf_6,
  output         io_r_resp_data_1_entries_onlypf_7,
  output         io_r_resp_data_1_entries_perms_0_d,
  output         io_r_resp_data_1_entries_perms_0_a,
  output         io_r_resp_data_1_entries_perms_0_g,
  output         io_r_resp_data_1_entries_perms_0_u,
  output         io_r_resp_data_1_entries_perms_0_x,
  output         io_r_resp_data_1_entries_perms_0_w,
  output         io_r_resp_data_1_entries_perms_0_r,
  output         io_r_resp_data_1_entries_perms_1_d,
  output         io_r_resp_data_1_entries_perms_1_a,
  output         io_r_resp_data_1_entries_perms_1_g,
  output         io_r_resp_data_1_entries_perms_1_u,
  output         io_r_resp_data_1_entries_perms_1_x,
  output         io_r_resp_data_1_entries_perms_1_w,
  output         io_r_resp_data_1_entries_perms_1_r,
  output         io_r_resp_data_1_entries_perms_2_d,
  output         io_r_resp_data_1_entries_perms_2_a,
  output         io_r_resp_data_1_entries_perms_2_g,
  output         io_r_resp_data_1_entries_perms_2_u,
  output         io_r_resp_data_1_entries_perms_2_x,
  output         io_r_resp_data_1_entries_perms_2_w,
  output         io_r_resp_data_1_entries_perms_2_r,
  output         io_r_resp_data_1_entries_perms_3_d,
  output         io_r_resp_data_1_entries_perms_3_a,
  output         io_r_resp_data_1_entries_perms_3_g,
  output         io_r_resp_data_1_entries_perms_3_u,
  output         io_r_resp_data_1_entries_perms_3_x,
  output         io_r_resp_data_1_entries_perms_3_w,
  output         io_r_resp_data_1_entries_perms_3_r,
  output         io_r_resp_data_1_entries_perms_4_d,
  output         io_r_resp_data_1_entries_perms_4_a,
  output         io_r_resp_data_1_entries_perms_4_g,
  output         io_r_resp_data_1_entries_perms_4_u,
  output         io_r_resp_data_1_entries_perms_4_x,
  output         io_r_resp_data_1_entries_perms_4_w,
  output         io_r_resp_data_1_entries_perms_4_r,
  output         io_r_resp_data_1_entries_perms_5_d,
  output         io_r_resp_data_1_entries_perms_5_a,
  output         io_r_resp_data_1_entries_perms_5_g,
  output         io_r_resp_data_1_entries_perms_5_u,
  output         io_r_resp_data_1_entries_perms_5_x,
  output         io_r_resp_data_1_entries_perms_5_w,
  output         io_r_resp_data_1_entries_perms_5_r,
  output         io_r_resp_data_1_entries_perms_6_d,
  output         io_r_resp_data_1_entries_perms_6_a,
  output         io_r_resp_data_1_entries_perms_6_g,
  output         io_r_resp_data_1_entries_perms_6_u,
  output         io_r_resp_data_1_entries_perms_6_x,
  output         io_r_resp_data_1_entries_perms_6_w,
  output         io_r_resp_data_1_entries_perms_6_r,
  output         io_r_resp_data_1_entries_perms_7_d,
  output         io_r_resp_data_1_entries_perms_7_a,
  output         io_r_resp_data_1_entries_perms_7_g,
  output         io_r_resp_data_1_entries_perms_7_u,
  output         io_r_resp_data_1_entries_perms_7_x,
  output         io_r_resp_data_1_entries_perms_7_w,
  output         io_r_resp_data_1_entries_perms_7_r,
  output         io_r_resp_data_1_entries_prefetch,
  output [28:0]  io_r_resp_data_2_entries_tag,
  output [15:0]  io_r_resp_data_2_entries_asid,
  output [13:0]  io_r_resp_data_2_entries_vmid,
  output [1:0]   io_r_resp_data_2_entries_pbmts_0,
  output [1:0]   io_r_resp_data_2_entries_pbmts_1,
  output [1:0]   io_r_resp_data_2_entries_pbmts_2,
  output [1:0]   io_r_resp_data_2_entries_pbmts_3,
  output [1:0]   io_r_resp_data_2_entries_pbmts_4,
  output [1:0]   io_r_resp_data_2_entries_pbmts_5,
  output [1:0]   io_r_resp_data_2_entries_pbmts_6,
  output [1:0]   io_r_resp_data_2_entries_pbmts_7,
  output [37:0]  io_r_resp_data_2_entries_ppns_0,
  output [37:0]  io_r_resp_data_2_entries_ppns_1,
  output [37:0]  io_r_resp_data_2_entries_ppns_2,
  output [37:0]  io_r_resp_data_2_entries_ppns_3,
  output [37:0]  io_r_resp_data_2_entries_ppns_4,
  output [37:0]  io_r_resp_data_2_entries_ppns_5,
  output [37:0]  io_r_resp_data_2_entries_ppns_6,
  output [37:0]  io_r_resp_data_2_entries_ppns_7,
  output         io_r_resp_data_2_entries_vs_0,
  output         io_r_resp_data_2_entries_vs_1,
  output         io_r_resp_data_2_entries_vs_2,
  output         io_r_resp_data_2_entries_vs_3,
  output         io_r_resp_data_2_entries_vs_4,
  output         io_r_resp_data_2_entries_vs_5,
  output         io_r_resp_data_2_entries_vs_6,
  output         io_r_resp_data_2_entries_vs_7,
  output         io_r_resp_data_2_entries_onlypf_0,
  output         io_r_resp_data_2_entries_onlypf_1,
  output         io_r_resp_data_2_entries_onlypf_2,
  output         io_r_resp_data_2_entries_onlypf_3,
  output         io_r_resp_data_2_entries_onlypf_4,
  output         io_r_resp_data_2_entries_onlypf_5,
  output         io_r_resp_data_2_entries_onlypf_6,
  output         io_r_resp_data_2_entries_onlypf_7,
  output         io_r_resp_data_2_entries_perms_0_d,
  output         io_r_resp_data_2_entries_perms_0_a,
  output         io_r_resp_data_2_entries_perms_0_g,
  output         io_r_resp_data_2_entries_perms_0_u,
  output         io_r_resp_data_2_entries_perms_0_x,
  output         io_r_resp_data_2_entries_perms_0_w,
  output         io_r_resp_data_2_entries_perms_0_r,
  output         io_r_resp_data_2_entries_perms_1_d,
  output         io_r_resp_data_2_entries_perms_1_a,
  output         io_r_resp_data_2_entries_perms_1_g,
  output         io_r_resp_data_2_entries_perms_1_u,
  output         io_r_resp_data_2_entries_perms_1_x,
  output         io_r_resp_data_2_entries_perms_1_w,
  output         io_r_resp_data_2_entries_perms_1_r,
  output         io_r_resp_data_2_entries_perms_2_d,
  output         io_r_resp_data_2_entries_perms_2_a,
  output         io_r_resp_data_2_entries_perms_2_g,
  output         io_r_resp_data_2_entries_perms_2_u,
  output         io_r_resp_data_2_entries_perms_2_x,
  output         io_r_resp_data_2_entries_perms_2_w,
  output         io_r_resp_data_2_entries_perms_2_r,
  output         io_r_resp_data_2_entries_perms_3_d,
  output         io_r_resp_data_2_entries_perms_3_a,
  output         io_r_resp_data_2_entries_perms_3_g,
  output         io_r_resp_data_2_entries_perms_3_u,
  output         io_r_resp_data_2_entries_perms_3_x,
  output         io_r_resp_data_2_entries_perms_3_w,
  output         io_r_resp_data_2_entries_perms_3_r,
  output         io_r_resp_data_2_entries_perms_4_d,
  output         io_r_resp_data_2_entries_perms_4_a,
  output         io_r_resp_data_2_entries_perms_4_g,
  output         io_r_resp_data_2_entries_perms_4_u,
  output         io_r_resp_data_2_entries_perms_4_x,
  output         io_r_resp_data_2_entries_perms_4_w,
  output         io_r_resp_data_2_entries_perms_4_r,
  output         io_r_resp_data_2_entries_perms_5_d,
  output         io_r_resp_data_2_entries_perms_5_a,
  output         io_r_resp_data_2_entries_perms_5_g,
  output         io_r_resp_data_2_entries_perms_5_u,
  output         io_r_resp_data_2_entries_perms_5_x,
  output         io_r_resp_data_2_entries_perms_5_w,
  output         io_r_resp_data_2_entries_perms_5_r,
  output         io_r_resp_data_2_entries_perms_6_d,
  output         io_r_resp_data_2_entries_perms_6_a,
  output         io_r_resp_data_2_entries_perms_6_g,
  output         io_r_resp_data_2_entries_perms_6_u,
  output         io_r_resp_data_2_entries_perms_6_x,
  output         io_r_resp_data_2_entries_perms_6_w,
  output         io_r_resp_data_2_entries_perms_6_r,
  output         io_r_resp_data_2_entries_perms_7_d,
  output         io_r_resp_data_2_entries_perms_7_a,
  output         io_r_resp_data_2_entries_perms_7_g,
  output         io_r_resp_data_2_entries_perms_7_u,
  output         io_r_resp_data_2_entries_perms_7_x,
  output         io_r_resp_data_2_entries_perms_7_w,
  output         io_r_resp_data_2_entries_perms_7_r,
  output         io_r_resp_data_2_entries_prefetch,
  output [28:0]  io_r_resp_data_3_entries_tag,
  output [15:0]  io_r_resp_data_3_entries_asid,
  output [13:0]  io_r_resp_data_3_entries_vmid,
  output [1:0]   io_r_resp_data_3_entries_pbmts_0,
  output [1:0]   io_r_resp_data_3_entries_pbmts_1,
  output [1:0]   io_r_resp_data_3_entries_pbmts_2,
  output [1:0]   io_r_resp_data_3_entries_pbmts_3,
  output [1:0]   io_r_resp_data_3_entries_pbmts_4,
  output [1:0]   io_r_resp_data_3_entries_pbmts_5,
  output [1:0]   io_r_resp_data_3_entries_pbmts_6,
  output [1:0]   io_r_resp_data_3_entries_pbmts_7,
  output [37:0]  io_r_resp_data_3_entries_ppns_0,
  output [37:0]  io_r_resp_data_3_entries_ppns_1,
  output [37:0]  io_r_resp_data_3_entries_ppns_2,
  output [37:0]  io_r_resp_data_3_entries_ppns_3,
  output [37:0]  io_r_resp_data_3_entries_ppns_4,
  output [37:0]  io_r_resp_data_3_entries_ppns_5,
  output [37:0]  io_r_resp_data_3_entries_ppns_6,
  output [37:0]  io_r_resp_data_3_entries_ppns_7,
  output         io_r_resp_data_3_entries_vs_0,
  output         io_r_resp_data_3_entries_vs_1,
  output         io_r_resp_data_3_entries_vs_2,
  output         io_r_resp_data_3_entries_vs_3,
  output         io_r_resp_data_3_entries_vs_4,
  output         io_r_resp_data_3_entries_vs_5,
  output         io_r_resp_data_3_entries_vs_6,
  output         io_r_resp_data_3_entries_vs_7,
  output         io_r_resp_data_3_entries_onlypf_0,
  output         io_r_resp_data_3_entries_onlypf_1,
  output         io_r_resp_data_3_entries_onlypf_2,
  output         io_r_resp_data_3_entries_onlypf_3,
  output         io_r_resp_data_3_entries_onlypf_4,
  output         io_r_resp_data_3_entries_onlypf_5,
  output         io_r_resp_data_3_entries_onlypf_6,
  output         io_r_resp_data_3_entries_onlypf_7,
  output         io_r_resp_data_3_entries_perms_0_d,
  output         io_r_resp_data_3_entries_perms_0_a,
  output         io_r_resp_data_3_entries_perms_0_g,
  output         io_r_resp_data_3_entries_perms_0_u,
  output         io_r_resp_data_3_entries_perms_0_x,
  output         io_r_resp_data_3_entries_perms_0_w,
  output         io_r_resp_data_3_entries_perms_0_r,
  output         io_r_resp_data_3_entries_perms_1_d,
  output         io_r_resp_data_3_entries_perms_1_a,
  output         io_r_resp_data_3_entries_perms_1_g,
  output         io_r_resp_data_3_entries_perms_1_u,
  output         io_r_resp_data_3_entries_perms_1_x,
  output         io_r_resp_data_3_entries_perms_1_w,
  output         io_r_resp_data_3_entries_perms_1_r,
  output         io_r_resp_data_3_entries_perms_2_d,
  output         io_r_resp_data_3_entries_perms_2_a,
  output         io_r_resp_data_3_entries_perms_2_g,
  output         io_r_resp_data_3_entries_perms_2_u,
  output         io_r_resp_data_3_entries_perms_2_x,
  output         io_r_resp_data_3_entries_perms_2_w,
  output         io_r_resp_data_3_entries_perms_2_r,
  output         io_r_resp_data_3_entries_perms_3_d,
  output         io_r_resp_data_3_entries_perms_3_a,
  output         io_r_resp_data_3_entries_perms_3_g,
  output         io_r_resp_data_3_entries_perms_3_u,
  output         io_r_resp_data_3_entries_perms_3_x,
  output         io_r_resp_data_3_entries_perms_3_w,
  output         io_r_resp_data_3_entries_perms_3_r,
  output         io_r_resp_data_3_entries_perms_4_d,
  output         io_r_resp_data_3_entries_perms_4_a,
  output         io_r_resp_data_3_entries_perms_4_g,
  output         io_r_resp_data_3_entries_perms_4_u,
  output         io_r_resp_data_3_entries_perms_4_x,
  output         io_r_resp_data_3_entries_perms_4_w,
  output         io_r_resp_data_3_entries_perms_4_r,
  output         io_r_resp_data_3_entries_perms_5_d,
  output         io_r_resp_data_3_entries_perms_5_a,
  output         io_r_resp_data_3_entries_perms_5_g,
  output         io_r_resp_data_3_entries_perms_5_u,
  output         io_r_resp_data_3_entries_perms_5_x,
  output         io_r_resp_data_3_entries_perms_5_w,
  output         io_r_resp_data_3_entries_perms_5_r,
  output         io_r_resp_data_3_entries_perms_6_d,
  output         io_r_resp_data_3_entries_perms_6_a,
  output         io_r_resp_data_3_entries_perms_6_g,
  output         io_r_resp_data_3_entries_perms_6_u,
  output         io_r_resp_data_3_entries_perms_6_x,
  output         io_r_resp_data_3_entries_perms_6_w,
  output         io_r_resp_data_3_entries_perms_6_r,
  output         io_r_resp_data_3_entries_perms_7_d,
  output         io_r_resp_data_3_entries_perms_7_a,
  output         io_r_resp_data_3_entries_perms_7_g,
  output         io_r_resp_data_3_entries_perms_7_u,
  output         io_r_resp_data_3_entries_perms_7_x,
  output         io_r_resp_data_3_entries_perms_7_w,
  output         io_r_resp_data_3_entries_perms_7_r,
  output         io_r_resp_data_3_entries_prefetch,
  input          io_w_req_valid,
  input  [5:0]   io_w_req_bits_setIdx,
  input  [28:0]  io_w_req_bits_data_0_entries_tag,
  input  [15:0]  io_w_req_bits_data_0_entries_asid,
  input  [13:0]  io_w_req_bits_data_0_entries_vmid,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_0,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_1,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_2,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_3,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_4,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_5,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_6,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_7,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_0,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_1,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_2,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_3,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_4,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_5,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_6,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_7,
  input          io_w_req_bits_data_0_entries_vs_0,
  input          io_w_req_bits_data_0_entries_vs_1,
  input          io_w_req_bits_data_0_entries_vs_2,
  input          io_w_req_bits_data_0_entries_vs_3,
  input          io_w_req_bits_data_0_entries_vs_4,
  input          io_w_req_bits_data_0_entries_vs_5,
  input          io_w_req_bits_data_0_entries_vs_6,
  input          io_w_req_bits_data_0_entries_vs_7,
  input          io_w_req_bits_data_0_entries_onlypf_0,
  input          io_w_req_bits_data_0_entries_onlypf_1,
  input          io_w_req_bits_data_0_entries_onlypf_2,
  input          io_w_req_bits_data_0_entries_onlypf_3,
  input          io_w_req_bits_data_0_entries_onlypf_4,
  input          io_w_req_bits_data_0_entries_onlypf_5,
  input          io_w_req_bits_data_0_entries_onlypf_6,
  input          io_w_req_bits_data_0_entries_onlypf_7,
  input          io_w_req_bits_data_0_entries_perms_0_d,
  input          io_w_req_bits_data_0_entries_perms_0_a,
  input          io_w_req_bits_data_0_entries_perms_0_g,
  input          io_w_req_bits_data_0_entries_perms_0_u,
  input          io_w_req_bits_data_0_entries_perms_0_x,
  input          io_w_req_bits_data_0_entries_perms_0_w,
  input          io_w_req_bits_data_0_entries_perms_0_r,
  input          io_w_req_bits_data_0_entries_perms_1_d,
  input          io_w_req_bits_data_0_entries_perms_1_a,
  input          io_w_req_bits_data_0_entries_perms_1_g,
  input          io_w_req_bits_data_0_entries_perms_1_u,
  input          io_w_req_bits_data_0_entries_perms_1_x,
  input          io_w_req_bits_data_0_entries_perms_1_w,
  input          io_w_req_bits_data_0_entries_perms_1_r,
  input          io_w_req_bits_data_0_entries_perms_2_d,
  input          io_w_req_bits_data_0_entries_perms_2_a,
  input          io_w_req_bits_data_0_entries_perms_2_g,
  input          io_w_req_bits_data_0_entries_perms_2_u,
  input          io_w_req_bits_data_0_entries_perms_2_x,
  input          io_w_req_bits_data_0_entries_perms_2_w,
  input          io_w_req_bits_data_0_entries_perms_2_r,
  input          io_w_req_bits_data_0_entries_perms_3_d,
  input          io_w_req_bits_data_0_entries_perms_3_a,
  input          io_w_req_bits_data_0_entries_perms_3_g,
  input          io_w_req_bits_data_0_entries_perms_3_u,
  input          io_w_req_bits_data_0_entries_perms_3_x,
  input          io_w_req_bits_data_0_entries_perms_3_w,
  input          io_w_req_bits_data_0_entries_perms_3_r,
  input          io_w_req_bits_data_0_entries_perms_4_d,
  input          io_w_req_bits_data_0_entries_perms_4_a,
  input          io_w_req_bits_data_0_entries_perms_4_g,
  input          io_w_req_bits_data_0_entries_perms_4_u,
  input          io_w_req_bits_data_0_entries_perms_4_x,
  input          io_w_req_bits_data_0_entries_perms_4_w,
  input          io_w_req_bits_data_0_entries_perms_4_r,
  input          io_w_req_bits_data_0_entries_perms_5_d,
  input          io_w_req_bits_data_0_entries_perms_5_a,
  input          io_w_req_bits_data_0_entries_perms_5_g,
  input          io_w_req_bits_data_0_entries_perms_5_u,
  input          io_w_req_bits_data_0_entries_perms_5_x,
  input          io_w_req_bits_data_0_entries_perms_5_w,
  input          io_w_req_bits_data_0_entries_perms_5_r,
  input          io_w_req_bits_data_0_entries_perms_6_d,
  input          io_w_req_bits_data_0_entries_perms_6_a,
  input          io_w_req_bits_data_0_entries_perms_6_g,
  input          io_w_req_bits_data_0_entries_perms_6_u,
  input          io_w_req_bits_data_0_entries_perms_6_x,
  input          io_w_req_bits_data_0_entries_perms_6_w,
  input          io_w_req_bits_data_0_entries_perms_6_r,
  input          io_w_req_bits_data_0_entries_perms_7_d,
  input          io_w_req_bits_data_0_entries_perms_7_a,
  input          io_w_req_bits_data_0_entries_perms_7_g,
  input          io_w_req_bits_data_0_entries_perms_7_u,
  input          io_w_req_bits_data_0_entries_perms_7_x,
  input          io_w_req_bits_data_0_entries_perms_7_w,
  input          io_w_req_bits_data_0_entries_perms_7_r,
  input          io_w_req_bits_data_0_entries_prefetch,
  input  [28:0]  io_w_req_bits_data_1_entries_tag,
  input  [15:0]  io_w_req_bits_data_1_entries_asid,
  input  [13:0]  io_w_req_bits_data_1_entries_vmid,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_0,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_1,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_2,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_3,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_4,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_5,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_6,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_7,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_0,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_1,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_2,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_3,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_4,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_5,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_6,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_7,
  input          io_w_req_bits_data_1_entries_vs_0,
  input          io_w_req_bits_data_1_entries_vs_1,
  input          io_w_req_bits_data_1_entries_vs_2,
  input          io_w_req_bits_data_1_entries_vs_3,
  input          io_w_req_bits_data_1_entries_vs_4,
  input          io_w_req_bits_data_1_entries_vs_5,
  input          io_w_req_bits_data_1_entries_vs_6,
  input          io_w_req_bits_data_1_entries_vs_7,
  input          io_w_req_bits_data_1_entries_onlypf_0,
  input          io_w_req_bits_data_1_entries_onlypf_1,
  input          io_w_req_bits_data_1_entries_onlypf_2,
  input          io_w_req_bits_data_1_entries_onlypf_3,
  input          io_w_req_bits_data_1_entries_onlypf_4,
  input          io_w_req_bits_data_1_entries_onlypf_5,
  input          io_w_req_bits_data_1_entries_onlypf_6,
  input          io_w_req_bits_data_1_entries_onlypf_7,
  input          io_w_req_bits_data_1_entries_perms_0_d,
  input          io_w_req_bits_data_1_entries_perms_0_a,
  input          io_w_req_bits_data_1_entries_perms_0_g,
  input          io_w_req_bits_data_1_entries_perms_0_u,
  input          io_w_req_bits_data_1_entries_perms_0_x,
  input          io_w_req_bits_data_1_entries_perms_0_w,
  input          io_w_req_bits_data_1_entries_perms_0_r,
  input          io_w_req_bits_data_1_entries_perms_1_d,
  input          io_w_req_bits_data_1_entries_perms_1_a,
  input          io_w_req_bits_data_1_entries_perms_1_g,
  input          io_w_req_bits_data_1_entries_perms_1_u,
  input          io_w_req_bits_data_1_entries_perms_1_x,
  input          io_w_req_bits_data_1_entries_perms_1_w,
  input          io_w_req_bits_data_1_entries_perms_1_r,
  input          io_w_req_bits_data_1_entries_perms_2_d,
  input          io_w_req_bits_data_1_entries_perms_2_a,
  input          io_w_req_bits_data_1_entries_perms_2_g,
  input          io_w_req_bits_data_1_entries_perms_2_u,
  input          io_w_req_bits_data_1_entries_perms_2_x,
  input          io_w_req_bits_data_1_entries_perms_2_w,
  input          io_w_req_bits_data_1_entries_perms_2_r,
  input          io_w_req_bits_data_1_entries_perms_3_d,
  input          io_w_req_bits_data_1_entries_perms_3_a,
  input          io_w_req_bits_data_1_entries_perms_3_g,
  input          io_w_req_bits_data_1_entries_perms_3_u,
  input          io_w_req_bits_data_1_entries_perms_3_x,
  input          io_w_req_bits_data_1_entries_perms_3_w,
  input          io_w_req_bits_data_1_entries_perms_3_r,
  input          io_w_req_bits_data_1_entries_perms_4_d,
  input          io_w_req_bits_data_1_entries_perms_4_a,
  input          io_w_req_bits_data_1_entries_perms_4_g,
  input          io_w_req_bits_data_1_entries_perms_4_u,
  input          io_w_req_bits_data_1_entries_perms_4_x,
  input          io_w_req_bits_data_1_entries_perms_4_w,
  input          io_w_req_bits_data_1_entries_perms_4_r,
  input          io_w_req_bits_data_1_entries_perms_5_d,
  input          io_w_req_bits_data_1_entries_perms_5_a,
  input          io_w_req_bits_data_1_entries_perms_5_g,
  input          io_w_req_bits_data_1_entries_perms_5_u,
  input          io_w_req_bits_data_1_entries_perms_5_x,
  input          io_w_req_bits_data_1_entries_perms_5_w,
  input          io_w_req_bits_data_1_entries_perms_5_r,
  input          io_w_req_bits_data_1_entries_perms_6_d,
  input          io_w_req_bits_data_1_entries_perms_6_a,
  input          io_w_req_bits_data_1_entries_perms_6_g,
  input          io_w_req_bits_data_1_entries_perms_6_u,
  input          io_w_req_bits_data_1_entries_perms_6_x,
  input          io_w_req_bits_data_1_entries_perms_6_w,
  input          io_w_req_bits_data_1_entries_perms_6_r,
  input          io_w_req_bits_data_1_entries_perms_7_d,
  input          io_w_req_bits_data_1_entries_perms_7_a,
  input          io_w_req_bits_data_1_entries_perms_7_g,
  input          io_w_req_bits_data_1_entries_perms_7_u,
  input          io_w_req_bits_data_1_entries_perms_7_x,
  input          io_w_req_bits_data_1_entries_perms_7_w,
  input          io_w_req_bits_data_1_entries_perms_7_r,
  input          io_w_req_bits_data_1_entries_prefetch,
  input  [28:0]  io_w_req_bits_data_2_entries_tag,
  input  [15:0]  io_w_req_bits_data_2_entries_asid,
  input  [13:0]  io_w_req_bits_data_2_entries_vmid,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_0,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_1,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_2,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_3,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_4,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_5,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_6,
  input  [1:0]   io_w_req_bits_data_2_entries_pbmts_7,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_0,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_1,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_2,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_3,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_4,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_5,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_6,
  input  [37:0]  io_w_req_bits_data_2_entries_ppns_7,
  input          io_w_req_bits_data_2_entries_vs_0,
  input          io_w_req_bits_data_2_entries_vs_1,
  input          io_w_req_bits_data_2_entries_vs_2,
  input          io_w_req_bits_data_2_entries_vs_3,
  input          io_w_req_bits_data_2_entries_vs_4,
  input          io_w_req_bits_data_2_entries_vs_5,
  input          io_w_req_bits_data_2_entries_vs_6,
  input          io_w_req_bits_data_2_entries_vs_7,
  input          io_w_req_bits_data_2_entries_onlypf_0,
  input          io_w_req_bits_data_2_entries_onlypf_1,
  input          io_w_req_bits_data_2_entries_onlypf_2,
  input          io_w_req_bits_data_2_entries_onlypf_3,
  input          io_w_req_bits_data_2_entries_onlypf_4,
  input          io_w_req_bits_data_2_entries_onlypf_5,
  input          io_w_req_bits_data_2_entries_onlypf_6,
  input          io_w_req_bits_data_2_entries_onlypf_7,
  input          io_w_req_bits_data_2_entries_perms_0_d,
  input          io_w_req_bits_data_2_entries_perms_0_a,
  input          io_w_req_bits_data_2_entries_perms_0_g,
  input          io_w_req_bits_data_2_entries_perms_0_u,
  input          io_w_req_bits_data_2_entries_perms_0_x,
  input          io_w_req_bits_data_2_entries_perms_0_w,
  input          io_w_req_bits_data_2_entries_perms_0_r,
  input          io_w_req_bits_data_2_entries_perms_1_d,
  input          io_w_req_bits_data_2_entries_perms_1_a,
  input          io_w_req_bits_data_2_entries_perms_1_g,
  input          io_w_req_bits_data_2_entries_perms_1_u,
  input          io_w_req_bits_data_2_entries_perms_1_x,
  input          io_w_req_bits_data_2_entries_perms_1_w,
  input          io_w_req_bits_data_2_entries_perms_1_r,
  input          io_w_req_bits_data_2_entries_perms_2_d,
  input          io_w_req_bits_data_2_entries_perms_2_a,
  input          io_w_req_bits_data_2_entries_perms_2_g,
  input          io_w_req_bits_data_2_entries_perms_2_u,
  input          io_w_req_bits_data_2_entries_perms_2_x,
  input          io_w_req_bits_data_2_entries_perms_2_w,
  input          io_w_req_bits_data_2_entries_perms_2_r,
  input          io_w_req_bits_data_2_entries_perms_3_d,
  input          io_w_req_bits_data_2_entries_perms_3_a,
  input          io_w_req_bits_data_2_entries_perms_3_g,
  input          io_w_req_bits_data_2_entries_perms_3_u,
  input          io_w_req_bits_data_2_entries_perms_3_x,
  input          io_w_req_bits_data_2_entries_perms_3_w,
  input          io_w_req_bits_data_2_entries_perms_3_r,
  input          io_w_req_bits_data_2_entries_perms_4_d,
  input          io_w_req_bits_data_2_entries_perms_4_a,
  input          io_w_req_bits_data_2_entries_perms_4_g,
  input          io_w_req_bits_data_2_entries_perms_4_u,
  input          io_w_req_bits_data_2_entries_perms_4_x,
  input          io_w_req_bits_data_2_entries_perms_4_w,
  input          io_w_req_bits_data_2_entries_perms_4_r,
  input          io_w_req_bits_data_2_entries_perms_5_d,
  input          io_w_req_bits_data_2_entries_perms_5_a,
  input          io_w_req_bits_data_2_entries_perms_5_g,
  input          io_w_req_bits_data_2_entries_perms_5_u,
  input          io_w_req_bits_data_2_entries_perms_5_x,
  input          io_w_req_bits_data_2_entries_perms_5_w,
  input          io_w_req_bits_data_2_entries_perms_5_r,
  input          io_w_req_bits_data_2_entries_perms_6_d,
  input          io_w_req_bits_data_2_entries_perms_6_a,
  input          io_w_req_bits_data_2_entries_perms_6_g,
  input          io_w_req_bits_data_2_entries_perms_6_u,
  input          io_w_req_bits_data_2_entries_perms_6_x,
  input          io_w_req_bits_data_2_entries_perms_6_w,
  input          io_w_req_bits_data_2_entries_perms_6_r,
  input          io_w_req_bits_data_2_entries_perms_7_d,
  input          io_w_req_bits_data_2_entries_perms_7_a,
  input          io_w_req_bits_data_2_entries_perms_7_g,
  input          io_w_req_bits_data_2_entries_perms_7_u,
  input          io_w_req_bits_data_2_entries_perms_7_x,
  input          io_w_req_bits_data_2_entries_perms_7_w,
  input          io_w_req_bits_data_2_entries_perms_7_r,
  input          io_w_req_bits_data_2_entries_prefetch,
  input  [28:0]  io_w_req_bits_data_3_entries_tag,
  input  [15:0]  io_w_req_bits_data_3_entries_asid,
  input  [13:0]  io_w_req_bits_data_3_entries_vmid,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_0,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_1,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_2,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_3,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_4,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_5,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_6,
  input  [1:0]   io_w_req_bits_data_3_entries_pbmts_7,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_0,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_1,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_2,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_3,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_4,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_5,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_6,
  input  [37:0]  io_w_req_bits_data_3_entries_ppns_7,
  input          io_w_req_bits_data_3_entries_vs_0,
  input          io_w_req_bits_data_3_entries_vs_1,
  input          io_w_req_bits_data_3_entries_vs_2,
  input          io_w_req_bits_data_3_entries_vs_3,
  input          io_w_req_bits_data_3_entries_vs_4,
  input          io_w_req_bits_data_3_entries_vs_5,
  input          io_w_req_bits_data_3_entries_vs_6,
  input          io_w_req_bits_data_3_entries_vs_7,
  input          io_w_req_bits_data_3_entries_onlypf_0,
  input          io_w_req_bits_data_3_entries_onlypf_1,
  input          io_w_req_bits_data_3_entries_onlypf_2,
  input          io_w_req_bits_data_3_entries_onlypf_3,
  input          io_w_req_bits_data_3_entries_onlypf_4,
  input          io_w_req_bits_data_3_entries_onlypf_5,
  input          io_w_req_bits_data_3_entries_onlypf_6,
  input          io_w_req_bits_data_3_entries_onlypf_7,
  input          io_w_req_bits_data_3_entries_perms_0_d,
  input          io_w_req_bits_data_3_entries_perms_0_a,
  input          io_w_req_bits_data_3_entries_perms_0_g,
  input          io_w_req_bits_data_3_entries_perms_0_u,
  input          io_w_req_bits_data_3_entries_perms_0_x,
  input          io_w_req_bits_data_3_entries_perms_0_w,
  input          io_w_req_bits_data_3_entries_perms_0_r,
  input          io_w_req_bits_data_3_entries_perms_1_d,
  input          io_w_req_bits_data_3_entries_perms_1_a,
  input          io_w_req_bits_data_3_entries_perms_1_g,
  input          io_w_req_bits_data_3_entries_perms_1_u,
  input          io_w_req_bits_data_3_entries_perms_1_x,
  input          io_w_req_bits_data_3_entries_perms_1_w,
  input          io_w_req_bits_data_3_entries_perms_1_r,
  input          io_w_req_bits_data_3_entries_perms_2_d,
  input          io_w_req_bits_data_3_entries_perms_2_a,
  input          io_w_req_bits_data_3_entries_perms_2_g,
  input          io_w_req_bits_data_3_entries_perms_2_u,
  input          io_w_req_bits_data_3_entries_perms_2_x,
  input          io_w_req_bits_data_3_entries_perms_2_w,
  input          io_w_req_bits_data_3_entries_perms_2_r,
  input          io_w_req_bits_data_3_entries_perms_3_d,
  input          io_w_req_bits_data_3_entries_perms_3_a,
  input          io_w_req_bits_data_3_entries_perms_3_g,
  input          io_w_req_bits_data_3_entries_perms_3_u,
  input          io_w_req_bits_data_3_entries_perms_3_x,
  input          io_w_req_bits_data_3_entries_perms_3_w,
  input          io_w_req_bits_data_3_entries_perms_3_r,
  input          io_w_req_bits_data_3_entries_perms_4_d,
  input          io_w_req_bits_data_3_entries_perms_4_a,
  input          io_w_req_bits_data_3_entries_perms_4_g,
  input          io_w_req_bits_data_3_entries_perms_4_u,
  input          io_w_req_bits_data_3_entries_perms_4_x,
  input          io_w_req_bits_data_3_entries_perms_4_w,
  input          io_w_req_bits_data_3_entries_perms_4_r,
  input          io_w_req_bits_data_3_entries_perms_5_d,
  input          io_w_req_bits_data_3_entries_perms_5_a,
  input          io_w_req_bits_data_3_entries_perms_5_g,
  input          io_w_req_bits_data_3_entries_perms_5_u,
  input          io_w_req_bits_data_3_entries_perms_5_x,
  input          io_w_req_bits_data_3_entries_perms_5_w,
  input          io_w_req_bits_data_3_entries_perms_5_r,
  input          io_w_req_bits_data_3_entries_perms_6_d,
  input          io_w_req_bits_data_3_entries_perms_6_a,
  input          io_w_req_bits_data_3_entries_perms_6_g,
  input          io_w_req_bits_data_3_entries_perms_6_u,
  input          io_w_req_bits_data_3_entries_perms_6_x,
  input          io_w_req_bits_data_3_entries_perms_6_w,
  input          io_w_req_bits_data_3_entries_perms_6_r,
  input          io_w_req_bits_data_3_entries_perms_7_d,
  input          io_w_req_bits_data_3_entries_perms_7_a,
  input          io_w_req_bits_data_3_entries_perms_7_g,
  input          io_w_req_bits_data_3_entries_perms_7_u,
  input          io_w_req_bits_data_3_entries_perms_7_x,
  input          io_w_req_bits_data_3_entries_perms_7_w,
  input          io_w_req_bits_data_3_entries_perms_7_r,
  input          io_w_req_bits_data_3_entries_prefetch,
  input  [3:0]   io_w_req_bits_waymask,
  input  [6:0]   boreChildrenBd_bore_addr,
  input  [6:0]   boreChildrenBd_bore_addr_rd,
  input  [113:0] boreChildrenBd_bore_wdata,
  input  [1:0]   boreChildrenBd_bore_wmask,
  input          boreChildrenBd_bore_re,
  input          boreChildrenBd_bore_we,
  output [113:0] boreChildrenBd_bore_rdata,
  input          boreChildrenBd_bore_ack,
  input          boreChildrenBd_bore_selectedOH,
  input  [5:0]   boreChildrenBd_bore_array,
  input  [6:0]   boreChildrenBd_bore_1_addr,
  input  [6:0]   boreChildrenBd_bore_1_addr_rd,
  input  [113:0] boreChildrenBd_bore_1_wdata,
  input  [1:0]   boreChildrenBd_bore_1_wmask,
  input          boreChildrenBd_bore_1_re,
  input          boreChildrenBd_bore_1_we,
  output [113:0] boreChildrenBd_bore_1_rdata,
  input          boreChildrenBd_bore_1_ack,
  input          boreChildrenBd_bore_1_selectedOH,
  input  [5:0]   boreChildrenBd_bore_1_array,
  input  [6:0]   boreChildrenBd_bore_2_addr,
  input  [6:0]   boreChildrenBd_bore_2_addr_rd,
  input  [113:0] boreChildrenBd_bore_2_wdata,
  input  [1:0]   boreChildrenBd_bore_2_wmask,
  input          boreChildrenBd_bore_2_re,
  input          boreChildrenBd_bore_2_we,
  output [113:0] boreChildrenBd_bore_2_rdata,
  input          boreChildrenBd_bore_2_ack,
  input          boreChildrenBd_bore_2_selectedOH,
  input  [5:0]   boreChildrenBd_bore_2_array,
  input  [6:0]   boreChildrenBd_bore_3_addr,
  input  [6:0]   boreChildrenBd_bore_3_addr_rd,
  input  [113:0] boreChildrenBd_bore_3_wdata,
  input  [1:0]   boreChildrenBd_bore_3_wmask,
  input          boreChildrenBd_bore_3_re,
  input          boreChildrenBd_bore_3_we,
  output [113:0] boreChildrenBd_bore_3_rdata,
  input          boreChildrenBd_bore_3_ack,
  input          boreChildrenBd_bore_3_selectedOH,
  input  [5:0]   boreChildrenBd_bore_3_array,
  input  [6:0]   boreChildrenBd_bore_4_addr,
  input  [6:0]   boreChildrenBd_bore_4_addr_rd,
  input  [113:0] boreChildrenBd_bore_4_wdata,
  input  [1:0]   boreChildrenBd_bore_4_wmask,
  input          boreChildrenBd_bore_4_re,
  input          boreChildrenBd_bore_4_we,
  output [113:0] boreChildrenBd_bore_4_rdata,
  input          boreChildrenBd_bore_4_ack,
  input          boreChildrenBd_bore_4_selectedOH,
  input  [5:0]   boreChildrenBd_bore_4_array,
  input  [6:0]   boreChildrenBd_bore_5_addr,
  input  [6:0]   boreChildrenBd_bore_5_addr_rd,
  input  [113:0] boreChildrenBd_bore_5_wdata,
  input  [1:0]   boreChildrenBd_bore_5_wmask,
  input          boreChildrenBd_bore_5_re,
  input          boreChildrenBd_bore_5_we,
  output [113:0] boreChildrenBd_bore_5_rdata,
  input          boreChildrenBd_bore_5_ack,
  input          boreChildrenBd_bore_5_selectedOH,
  input  [5:0]   boreChildrenBd_bore_5_array,
  input  [6:0]   boreChildrenBd_bore_6_addr,
  input  [6:0]   boreChildrenBd_bore_6_addr_rd,
  input  [113:0] boreChildrenBd_bore_6_wdata,
  input  [1:0]   boreChildrenBd_bore_6_wmask,
  input          boreChildrenBd_bore_6_re,
  input          boreChildrenBd_bore_6_we,
  output [113:0] boreChildrenBd_bore_6_rdata,
  input          boreChildrenBd_bore_6_ack,
  input          boreChildrenBd_bore_6_selectedOH,
  input  [5:0]   boreChildrenBd_bore_6_array,
  input  [6:0]   boreChildrenBd_bore_7_addr,
  input  [6:0]   boreChildrenBd_bore_7_addr_rd,
  input  [113:0] boreChildrenBd_bore_7_wdata,
  input  [1:0]   boreChildrenBd_bore_7_wmask,
  input          boreChildrenBd_bore_7_re,
  input          boreChildrenBd_bore_7_we,
  output [113:0] boreChildrenBd_bore_7_rdata,
  input          boreChildrenBd_bore_7_ack,
  input          boreChildrenBd_bore_7_selectedOH,
  input  [5:0]   boreChildrenBd_bore_7_array,
  input  [6:0]   boreChildrenBd_bore_8_addr,
  input  [6:0]   boreChildrenBd_bore_8_addr_rd,
  input  [113:0] boreChildrenBd_bore_8_wdata,
  input  [1:0]   boreChildrenBd_bore_8_wmask,
  input          boreChildrenBd_bore_8_re,
  input          boreChildrenBd_bore_8_we,
  output [113:0] boreChildrenBd_bore_8_rdata,
  input          boreChildrenBd_bore_8_ack,
  input          boreChildrenBd_bore_8_selectedOH,
  input  [5:0]   boreChildrenBd_bore_8_array,
  input  [6:0]   boreChildrenBd_bore_9_addr,
  input  [6:0]   boreChildrenBd_bore_9_addr_rd,
  input  [113:0] boreChildrenBd_bore_9_wdata,
  input  [1:0]   boreChildrenBd_bore_9_wmask,
  input          boreChildrenBd_bore_9_re,
  input          boreChildrenBd_bore_9_we,
  output [113:0] boreChildrenBd_bore_9_rdata,
  input          boreChildrenBd_bore_9_ack,
  input          boreChildrenBd_bore_9_selectedOH,
  input  [5:0]   boreChildrenBd_bore_9_array,
  input  [6:0]   boreChildrenBd_bore_10_addr,
  input  [6:0]   boreChildrenBd_bore_10_addr_rd,
  input  [113:0] boreChildrenBd_bore_10_wdata,
  input  [1:0]   boreChildrenBd_bore_10_wmask,
  input          boreChildrenBd_bore_10_re,
  input          boreChildrenBd_bore_10_we,
  output [113:0] boreChildrenBd_bore_10_rdata,
  input          boreChildrenBd_bore_10_ack,
  input          boreChildrenBd_bore_10_selectedOH,
  input  [5:0]   boreChildrenBd_bore_10_array,
  input  [6:0]   boreChildrenBd_bore_11_addr,
  input  [6:0]   boreChildrenBd_bore_11_addr_rd,
  input  [113:0] boreChildrenBd_bore_11_wdata,
  input  [1:0]   boreChildrenBd_bore_11_wmask,
  input          boreChildrenBd_bore_11_re,
  input          boreChildrenBd_bore_11_we,
  output [113:0] boreChildrenBd_bore_11_rdata,
  input          boreChildrenBd_bore_11_ack,
  input          boreChildrenBd_bore_11_selectedOH,
  input  [5:0]   boreChildrenBd_bore_11_array,
  input  [6:0]   boreChildrenBd_bore_12_addr,
  input  [6:0]   boreChildrenBd_bore_12_addr_rd,
  input  [113:0] boreChildrenBd_bore_12_wdata,
  input  [1:0]   boreChildrenBd_bore_12_wmask,
  input          boreChildrenBd_bore_12_re,
  input          boreChildrenBd_bore_12_we,
  output [113:0] boreChildrenBd_bore_12_rdata,
  input          boreChildrenBd_bore_12_ack,
  input          boreChildrenBd_bore_12_selectedOH,
  input  [5:0]   boreChildrenBd_bore_12_array,
  input  [6:0]   boreChildrenBd_bore_13_addr,
  input  [6:0]   boreChildrenBd_bore_13_addr_rd,
  input  [113:0] boreChildrenBd_bore_13_wdata,
  input  [1:0]   boreChildrenBd_bore_13_wmask,
  input          boreChildrenBd_bore_13_re,
  input          boreChildrenBd_bore_13_we,
  output [113:0] boreChildrenBd_bore_13_rdata,
  input          boreChildrenBd_bore_13_ack,
  input          boreChildrenBd_bore_13_selectedOH,
  input  [5:0]   boreChildrenBd_bore_13_array,
  input  [6:0]   boreChildrenBd_bore_14_addr,
  input  [6:0]   boreChildrenBd_bore_14_addr_rd,
  input  [113:0] boreChildrenBd_bore_14_wdata,
  input  [1:0]   boreChildrenBd_bore_14_wmask,
  input          boreChildrenBd_bore_14_re,
  input          boreChildrenBd_bore_14_we,
  output [113:0] boreChildrenBd_bore_14_rdata,
  input          boreChildrenBd_bore_14_ack,
  input          boreChildrenBd_bore_14_selectedOH,
  input  [6:0]   boreChildrenBd_bore_14_array,
  input  [6:0]   boreChildrenBd_bore_15_addr,
  input  [6:0]   boreChildrenBd_bore_15_addr_rd,
  input  [113:0] boreChildrenBd_bore_15_wdata,
  input  [1:0]   boreChildrenBd_bore_15_wmask,
  input          boreChildrenBd_bore_15_re,
  input          boreChildrenBd_bore_15_we,
  output [113:0] boreChildrenBd_bore_15_rdata,
  input          boreChildrenBd_bore_15_ack,
  input          boreChildrenBd_bore_15_selectedOH,
  input  [6:0]   boreChildrenBd_bore_15_array,
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen,
  input          sigFromSrams_bore_1_ram_hold,
  input          sigFromSrams_bore_1_ram_bypass,
  input          sigFromSrams_bore_1_ram_bp_clken,
  input          sigFromSrams_bore_1_ram_aux_clk,
  input          sigFromSrams_bore_1_ram_aux_ckbp,
  input          sigFromSrams_bore_1_ram_mcp_hold,
  input          sigFromSrams_bore_1_cgen,
  input          sigFromSrams_bore_2_ram_hold,
  input          sigFromSrams_bore_2_ram_bypass,
  input          sigFromSrams_bore_2_ram_bp_clken,
  input          sigFromSrams_bore_2_ram_aux_clk,
  input          sigFromSrams_bore_2_ram_aux_ckbp,
  input          sigFromSrams_bore_2_ram_mcp_hold,
  input          sigFromSrams_bore_2_cgen,
  input          sigFromSrams_bore_3_ram_hold,
  input          sigFromSrams_bore_3_ram_bypass,
  input          sigFromSrams_bore_3_ram_bp_clken,
  input          sigFromSrams_bore_3_ram_aux_clk,
  input          sigFromSrams_bore_3_ram_aux_ckbp,
  input          sigFromSrams_bore_3_ram_mcp_hold,
  input          sigFromSrams_bore_3_cgen,
  input          sigFromSrams_bore_4_ram_hold,
  input          sigFromSrams_bore_4_ram_bypass,
  input          sigFromSrams_bore_4_ram_bp_clken,
  input          sigFromSrams_bore_4_ram_aux_clk,
  input          sigFromSrams_bore_4_ram_aux_ckbp,
  input          sigFromSrams_bore_4_ram_mcp_hold,
  input          sigFromSrams_bore_4_cgen,
  input          sigFromSrams_bore_5_ram_hold,
  input          sigFromSrams_bore_5_ram_bypass,
  input          sigFromSrams_bore_5_ram_bp_clken,
  input          sigFromSrams_bore_5_ram_aux_clk,
  input          sigFromSrams_bore_5_ram_aux_ckbp,
  input          sigFromSrams_bore_5_ram_mcp_hold,
  input          sigFromSrams_bore_5_cgen,
  input          sigFromSrams_bore_6_ram_hold,
  input          sigFromSrams_bore_6_ram_bypass,
  input          sigFromSrams_bore_6_ram_bp_clken,
  input          sigFromSrams_bore_6_ram_aux_clk,
  input          sigFromSrams_bore_6_ram_aux_ckbp,
  input          sigFromSrams_bore_6_ram_mcp_hold,
  input          sigFromSrams_bore_6_cgen,
  input          sigFromSrams_bore_7_ram_hold,
  input          sigFromSrams_bore_7_ram_bypass,
  input          sigFromSrams_bore_7_ram_bp_clken,
  input          sigFromSrams_bore_7_ram_aux_clk,
  input          sigFromSrams_bore_7_ram_aux_ckbp,
  input          sigFromSrams_bore_7_ram_mcp_hold,
  input          sigFromSrams_bore_7_cgen,
  input          sigFromSrams_bore_8_ram_hold,
  input          sigFromSrams_bore_8_ram_bypass,
  input          sigFromSrams_bore_8_ram_bp_clken,
  input          sigFromSrams_bore_8_ram_aux_clk,
  input          sigFromSrams_bore_8_ram_aux_ckbp,
  input          sigFromSrams_bore_8_ram_mcp_hold,
  input          sigFromSrams_bore_8_cgen,
  input          sigFromSrams_bore_9_ram_hold,
  input          sigFromSrams_bore_9_ram_bypass,
  input          sigFromSrams_bore_9_ram_bp_clken,
  input          sigFromSrams_bore_9_ram_aux_clk,
  input          sigFromSrams_bore_9_ram_aux_ckbp,
  input          sigFromSrams_bore_9_ram_mcp_hold,
  input          sigFromSrams_bore_9_cgen,
  input          sigFromSrams_bore_10_ram_hold,
  input          sigFromSrams_bore_10_ram_bypass,
  input          sigFromSrams_bore_10_ram_bp_clken,
  input          sigFromSrams_bore_10_ram_aux_clk,
  input          sigFromSrams_bore_10_ram_aux_ckbp,
  input          sigFromSrams_bore_10_ram_mcp_hold,
  input          sigFromSrams_bore_10_cgen,
  input          sigFromSrams_bore_11_ram_hold,
  input          sigFromSrams_bore_11_ram_bypass,
  input          sigFromSrams_bore_11_ram_bp_clken,
  input          sigFromSrams_bore_11_ram_aux_clk,
  input          sigFromSrams_bore_11_ram_aux_ckbp,
  input          sigFromSrams_bore_11_ram_mcp_hold,
  input          sigFromSrams_bore_11_cgen,
  input          sigFromSrams_bore_12_ram_hold,
  input          sigFromSrams_bore_12_ram_bypass,
  input          sigFromSrams_bore_12_ram_bp_clken,
  input          sigFromSrams_bore_12_ram_aux_clk,
  input          sigFromSrams_bore_12_ram_aux_ckbp,
  input          sigFromSrams_bore_12_ram_mcp_hold,
  input          sigFromSrams_bore_12_cgen,
  input          sigFromSrams_bore_13_ram_hold,
  input          sigFromSrams_bore_13_ram_bypass,
  input          sigFromSrams_bore_13_ram_bp_clken,
  input          sigFromSrams_bore_13_ram_aux_clk,
  input          sigFromSrams_bore_13_ram_aux_ckbp,
  input          sigFromSrams_bore_13_ram_mcp_hold,
  input          sigFromSrams_bore_13_cgen,
  input          sigFromSrams_bore_14_ram_hold,
  input          sigFromSrams_bore_14_ram_bypass,
  input          sigFromSrams_bore_14_ram_bp_clken,
  input          sigFromSrams_bore_14_ram_aux_clk,
  input          sigFromSrams_bore_14_ram_aux_ckbp,
  input          sigFromSrams_bore_14_ram_mcp_hold,
  input          sigFromSrams_bore_14_cgen,
  input          sigFromSrams_bore_15_ram_hold,
  input          sigFromSrams_bore_15_ram_bypass,
  input          sigFromSrams_bore_15_ram_bp_clken,
  input          sigFromSrams_bore_15_ram_aux_clk,
  input          sigFromSrams_bore_15_ram_aux_ckbp,
  input          sigFromSrams_bore_15_ram_mcp_hold,
  input          sigFromSrams_bore_15_cgen
);

  // --------------------------------------------------------------------------
  // 参数与阵列侧总线
  // --------------------------------------------------------------------------
  localparam int NUM        = 8;
  localparam int TAG_W      = 29;
  localparam int ASID_W     = 16;
  localparam int VMID_W     = 14;
  localparam int PBMT_W     = 2;
  localparam int PPN_W      = 38;
  localparam int PERM_W     = 7;
  localparam int WAY        = 4;
  localparam int WAY_SPLIT  = 2;
  localparam int DATA_SPLIT = 8;
  localparam int WAY_PER    = WAY / WAY_SPLIT;          // = 2
  localparam int NARR       = WAY_SPLIT * DATA_SPLIT;   // = 16
  localparam int SLICE_W    = 57;                // = ENTRY_W(456) / DATA_SPLIT

  // 阵列侧总线：下标 n = way 组号 * DATA_SPLIT + data 段号，
  // 与 golden 的实例名 array_0_<组>_<段>、bore 编号 boreChildrenBd_bore_<n> 同序。
  wire [NARR-1:0][WAY_PER-1:0]              arr_waymask;
  wire [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_wdata;
  wire [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_rdata;

  // 写入的 PtwEntries 字段，按 [路][Vec 下标] 聚成数组（核的位向量口按此序）
  wire [WAY-1:0][TAG_W-1:0]            wr_tag;
  wire [WAY-1:0][ASID_W-1:0]           wr_asid;
  wire [WAY-1:0][VMID_W-1:0]           wr_vmid;
  wire [WAY-1:0][NUM-1:0][PBMT_W-1:0]  wr_pbmt;
  wire [WAY-1:0][NUM-1:0][PPN_W-1:0]   wr_ppn;
  wire [WAY-1:0][NUM-1:0]              wr_vs;
  wire [WAY-1:0][NUM-1:0]              wr_onlypf;
  wire [WAY-1:0][NUM-1:0][PERM_W-1:0]  wr_perm;
  wire [WAY-1:0]                       wr_pref;

  // 读出的 PtwEntries 字段，按 [路][Vec 下标] 聚成数组（核的位向量口按此序）
  wire [WAY-1:0][TAG_W-1:0]            rd_tag;
  wire [WAY-1:0][ASID_W-1:0]           rd_asid;
  wire [WAY-1:0][VMID_W-1:0]           rd_vmid;
  wire [WAY-1:0][NUM-1:0][PBMT_W-1:0]  rd_pbmt;
  wire [WAY-1:0][NUM-1:0][PPN_W-1:0]   rd_ppn;
  wire [WAY-1:0][NUM-1:0]              rd_vs;
  wire [WAY-1:0][NUM-1:0]              rd_onlypf;
  wire [WAY-1:0][NUM-1:0][PERM_W-1:0]  rd_perm;
  wire [WAY-1:0]                       rd_pref;

  // --------------------------------------------------------------------------
  // 打包/切分核 u_core：写侧接线（路号高者在高位、Vec 下标大者在高位）
  // 写侧字段收集：golden 的扁平端口 → [路][下标] 数组
  assign wr_tag [0] = io_w_req_bits_data_0_entries_tag;
  assign wr_asid[0] = io_w_req_bits_data_0_entries_asid;
  assign wr_vmid[0] = io_w_req_bits_data_0_entries_vmid;
  assign wr_pref[0] = io_w_req_bits_data_0_entries_prefetch;
  assign wr_pbmt[0][0] = io_w_req_bits_data_0_entries_pbmts_0;
  assign wr_pbmt[0][1] = io_w_req_bits_data_0_entries_pbmts_1;
  assign wr_pbmt[0][2] = io_w_req_bits_data_0_entries_pbmts_2;
  assign wr_pbmt[0][3] = io_w_req_bits_data_0_entries_pbmts_3;
  assign wr_pbmt[0][4] = io_w_req_bits_data_0_entries_pbmts_4;
  assign wr_pbmt[0][5] = io_w_req_bits_data_0_entries_pbmts_5;
  assign wr_pbmt[0][6] = io_w_req_bits_data_0_entries_pbmts_6;
  assign wr_pbmt[0][7] = io_w_req_bits_data_0_entries_pbmts_7;
  assign wr_ppn [0][0] = io_w_req_bits_data_0_entries_ppns_0;
  assign wr_ppn [0][1] = io_w_req_bits_data_0_entries_ppns_1;
  assign wr_ppn [0][2] = io_w_req_bits_data_0_entries_ppns_2;
  assign wr_ppn [0][3] = io_w_req_bits_data_0_entries_ppns_3;
  assign wr_ppn [0][4] = io_w_req_bits_data_0_entries_ppns_4;
  assign wr_ppn [0][5] = io_w_req_bits_data_0_entries_ppns_5;
  assign wr_ppn [0][6] = io_w_req_bits_data_0_entries_ppns_6;
  assign wr_ppn [0][7] = io_w_req_bits_data_0_entries_ppns_7;
  assign wr_vs  [0][0] = io_w_req_bits_data_0_entries_vs_0;
  assign wr_vs  [0][1] = io_w_req_bits_data_0_entries_vs_1;
  assign wr_vs  [0][2] = io_w_req_bits_data_0_entries_vs_2;
  assign wr_vs  [0][3] = io_w_req_bits_data_0_entries_vs_3;
  assign wr_vs  [0][4] = io_w_req_bits_data_0_entries_vs_4;
  assign wr_vs  [0][5] = io_w_req_bits_data_0_entries_vs_5;
  assign wr_vs  [0][6] = io_w_req_bits_data_0_entries_vs_6;
  assign wr_vs  [0][7] = io_w_req_bits_data_0_entries_vs_7;
  assign wr_onlypf[0][0] = io_w_req_bits_data_0_entries_onlypf_0;
  assign wr_onlypf[0][1] = io_w_req_bits_data_0_entries_onlypf_1;
  assign wr_onlypf[0][2] = io_w_req_bits_data_0_entries_onlypf_2;
  assign wr_onlypf[0][3] = io_w_req_bits_data_0_entries_onlypf_3;
  assign wr_onlypf[0][4] = io_w_req_bits_data_0_entries_onlypf_4;
  assign wr_onlypf[0][5] = io_w_req_bits_data_0_entries_onlypf_5;
  assign wr_onlypf[0][6] = io_w_req_bits_data_0_entries_onlypf_6;
  assign wr_onlypf[0][7] = io_w_req_bits_data_0_entries_onlypf_7;
  assign wr_perm[0][0] = {io_w_req_bits_data_0_entries_perms_0_d,
                          io_w_req_bits_data_0_entries_perms_0_a,
                          io_w_req_bits_data_0_entries_perms_0_g,
                          io_w_req_bits_data_0_entries_perms_0_u,
                          io_w_req_bits_data_0_entries_perms_0_x,
                          io_w_req_bits_data_0_entries_perms_0_w,
                          io_w_req_bits_data_0_entries_perms_0_r};
  assign wr_perm[0][1] = {io_w_req_bits_data_0_entries_perms_1_d,
                          io_w_req_bits_data_0_entries_perms_1_a,
                          io_w_req_bits_data_0_entries_perms_1_g,
                          io_w_req_bits_data_0_entries_perms_1_u,
                          io_w_req_bits_data_0_entries_perms_1_x,
                          io_w_req_bits_data_0_entries_perms_1_w,
                          io_w_req_bits_data_0_entries_perms_1_r};
  assign wr_perm[0][2] = {io_w_req_bits_data_0_entries_perms_2_d,
                          io_w_req_bits_data_0_entries_perms_2_a,
                          io_w_req_bits_data_0_entries_perms_2_g,
                          io_w_req_bits_data_0_entries_perms_2_u,
                          io_w_req_bits_data_0_entries_perms_2_x,
                          io_w_req_bits_data_0_entries_perms_2_w,
                          io_w_req_bits_data_0_entries_perms_2_r};
  assign wr_perm[0][3] = {io_w_req_bits_data_0_entries_perms_3_d,
                          io_w_req_bits_data_0_entries_perms_3_a,
                          io_w_req_bits_data_0_entries_perms_3_g,
                          io_w_req_bits_data_0_entries_perms_3_u,
                          io_w_req_bits_data_0_entries_perms_3_x,
                          io_w_req_bits_data_0_entries_perms_3_w,
                          io_w_req_bits_data_0_entries_perms_3_r};
  assign wr_perm[0][4] = {io_w_req_bits_data_0_entries_perms_4_d,
                          io_w_req_bits_data_0_entries_perms_4_a,
                          io_w_req_bits_data_0_entries_perms_4_g,
                          io_w_req_bits_data_0_entries_perms_4_u,
                          io_w_req_bits_data_0_entries_perms_4_x,
                          io_w_req_bits_data_0_entries_perms_4_w,
                          io_w_req_bits_data_0_entries_perms_4_r};
  assign wr_perm[0][5] = {io_w_req_bits_data_0_entries_perms_5_d,
                          io_w_req_bits_data_0_entries_perms_5_a,
                          io_w_req_bits_data_0_entries_perms_5_g,
                          io_w_req_bits_data_0_entries_perms_5_u,
                          io_w_req_bits_data_0_entries_perms_5_x,
                          io_w_req_bits_data_0_entries_perms_5_w,
                          io_w_req_bits_data_0_entries_perms_5_r};
  assign wr_perm[0][6] = {io_w_req_bits_data_0_entries_perms_6_d,
                          io_w_req_bits_data_0_entries_perms_6_a,
                          io_w_req_bits_data_0_entries_perms_6_g,
                          io_w_req_bits_data_0_entries_perms_6_u,
                          io_w_req_bits_data_0_entries_perms_6_x,
                          io_w_req_bits_data_0_entries_perms_6_w,
                          io_w_req_bits_data_0_entries_perms_6_r};
  assign wr_perm[0][7] = {io_w_req_bits_data_0_entries_perms_7_d,
                          io_w_req_bits_data_0_entries_perms_7_a,
                          io_w_req_bits_data_0_entries_perms_7_g,
                          io_w_req_bits_data_0_entries_perms_7_u,
                          io_w_req_bits_data_0_entries_perms_7_x,
                          io_w_req_bits_data_0_entries_perms_7_w,
                          io_w_req_bits_data_0_entries_perms_7_r};
  assign wr_tag [1] = io_w_req_bits_data_1_entries_tag;
  assign wr_asid[1] = io_w_req_bits_data_1_entries_asid;
  assign wr_vmid[1] = io_w_req_bits_data_1_entries_vmid;
  assign wr_pref[1] = io_w_req_bits_data_1_entries_prefetch;
  assign wr_pbmt[1][0] = io_w_req_bits_data_1_entries_pbmts_0;
  assign wr_pbmt[1][1] = io_w_req_bits_data_1_entries_pbmts_1;
  assign wr_pbmt[1][2] = io_w_req_bits_data_1_entries_pbmts_2;
  assign wr_pbmt[1][3] = io_w_req_bits_data_1_entries_pbmts_3;
  assign wr_pbmt[1][4] = io_w_req_bits_data_1_entries_pbmts_4;
  assign wr_pbmt[1][5] = io_w_req_bits_data_1_entries_pbmts_5;
  assign wr_pbmt[1][6] = io_w_req_bits_data_1_entries_pbmts_6;
  assign wr_pbmt[1][7] = io_w_req_bits_data_1_entries_pbmts_7;
  assign wr_ppn [1][0] = io_w_req_bits_data_1_entries_ppns_0;
  assign wr_ppn [1][1] = io_w_req_bits_data_1_entries_ppns_1;
  assign wr_ppn [1][2] = io_w_req_bits_data_1_entries_ppns_2;
  assign wr_ppn [1][3] = io_w_req_bits_data_1_entries_ppns_3;
  assign wr_ppn [1][4] = io_w_req_bits_data_1_entries_ppns_4;
  assign wr_ppn [1][5] = io_w_req_bits_data_1_entries_ppns_5;
  assign wr_ppn [1][6] = io_w_req_bits_data_1_entries_ppns_6;
  assign wr_ppn [1][7] = io_w_req_bits_data_1_entries_ppns_7;
  assign wr_vs  [1][0] = io_w_req_bits_data_1_entries_vs_0;
  assign wr_vs  [1][1] = io_w_req_bits_data_1_entries_vs_1;
  assign wr_vs  [1][2] = io_w_req_bits_data_1_entries_vs_2;
  assign wr_vs  [1][3] = io_w_req_bits_data_1_entries_vs_3;
  assign wr_vs  [1][4] = io_w_req_bits_data_1_entries_vs_4;
  assign wr_vs  [1][5] = io_w_req_bits_data_1_entries_vs_5;
  assign wr_vs  [1][6] = io_w_req_bits_data_1_entries_vs_6;
  assign wr_vs  [1][7] = io_w_req_bits_data_1_entries_vs_7;
  assign wr_onlypf[1][0] = io_w_req_bits_data_1_entries_onlypf_0;
  assign wr_onlypf[1][1] = io_w_req_bits_data_1_entries_onlypf_1;
  assign wr_onlypf[1][2] = io_w_req_bits_data_1_entries_onlypf_2;
  assign wr_onlypf[1][3] = io_w_req_bits_data_1_entries_onlypf_3;
  assign wr_onlypf[1][4] = io_w_req_bits_data_1_entries_onlypf_4;
  assign wr_onlypf[1][5] = io_w_req_bits_data_1_entries_onlypf_5;
  assign wr_onlypf[1][6] = io_w_req_bits_data_1_entries_onlypf_6;
  assign wr_onlypf[1][7] = io_w_req_bits_data_1_entries_onlypf_7;
  assign wr_perm[1][0] = {io_w_req_bits_data_1_entries_perms_0_d,
                          io_w_req_bits_data_1_entries_perms_0_a,
                          io_w_req_bits_data_1_entries_perms_0_g,
                          io_w_req_bits_data_1_entries_perms_0_u,
                          io_w_req_bits_data_1_entries_perms_0_x,
                          io_w_req_bits_data_1_entries_perms_0_w,
                          io_w_req_bits_data_1_entries_perms_0_r};
  assign wr_perm[1][1] = {io_w_req_bits_data_1_entries_perms_1_d,
                          io_w_req_bits_data_1_entries_perms_1_a,
                          io_w_req_bits_data_1_entries_perms_1_g,
                          io_w_req_bits_data_1_entries_perms_1_u,
                          io_w_req_bits_data_1_entries_perms_1_x,
                          io_w_req_bits_data_1_entries_perms_1_w,
                          io_w_req_bits_data_1_entries_perms_1_r};
  assign wr_perm[1][2] = {io_w_req_bits_data_1_entries_perms_2_d,
                          io_w_req_bits_data_1_entries_perms_2_a,
                          io_w_req_bits_data_1_entries_perms_2_g,
                          io_w_req_bits_data_1_entries_perms_2_u,
                          io_w_req_bits_data_1_entries_perms_2_x,
                          io_w_req_bits_data_1_entries_perms_2_w,
                          io_w_req_bits_data_1_entries_perms_2_r};
  assign wr_perm[1][3] = {io_w_req_bits_data_1_entries_perms_3_d,
                          io_w_req_bits_data_1_entries_perms_3_a,
                          io_w_req_bits_data_1_entries_perms_3_g,
                          io_w_req_bits_data_1_entries_perms_3_u,
                          io_w_req_bits_data_1_entries_perms_3_x,
                          io_w_req_bits_data_1_entries_perms_3_w,
                          io_w_req_bits_data_1_entries_perms_3_r};
  assign wr_perm[1][4] = {io_w_req_bits_data_1_entries_perms_4_d,
                          io_w_req_bits_data_1_entries_perms_4_a,
                          io_w_req_bits_data_1_entries_perms_4_g,
                          io_w_req_bits_data_1_entries_perms_4_u,
                          io_w_req_bits_data_1_entries_perms_4_x,
                          io_w_req_bits_data_1_entries_perms_4_w,
                          io_w_req_bits_data_1_entries_perms_4_r};
  assign wr_perm[1][5] = {io_w_req_bits_data_1_entries_perms_5_d,
                          io_w_req_bits_data_1_entries_perms_5_a,
                          io_w_req_bits_data_1_entries_perms_5_g,
                          io_w_req_bits_data_1_entries_perms_5_u,
                          io_w_req_bits_data_1_entries_perms_5_x,
                          io_w_req_bits_data_1_entries_perms_5_w,
                          io_w_req_bits_data_1_entries_perms_5_r};
  assign wr_perm[1][6] = {io_w_req_bits_data_1_entries_perms_6_d,
                          io_w_req_bits_data_1_entries_perms_6_a,
                          io_w_req_bits_data_1_entries_perms_6_g,
                          io_w_req_bits_data_1_entries_perms_6_u,
                          io_w_req_bits_data_1_entries_perms_6_x,
                          io_w_req_bits_data_1_entries_perms_6_w,
                          io_w_req_bits_data_1_entries_perms_6_r};
  assign wr_perm[1][7] = {io_w_req_bits_data_1_entries_perms_7_d,
                          io_w_req_bits_data_1_entries_perms_7_a,
                          io_w_req_bits_data_1_entries_perms_7_g,
                          io_w_req_bits_data_1_entries_perms_7_u,
                          io_w_req_bits_data_1_entries_perms_7_x,
                          io_w_req_bits_data_1_entries_perms_7_w,
                          io_w_req_bits_data_1_entries_perms_7_r};
  assign wr_tag [2] = io_w_req_bits_data_2_entries_tag;
  assign wr_asid[2] = io_w_req_bits_data_2_entries_asid;
  assign wr_vmid[2] = io_w_req_bits_data_2_entries_vmid;
  assign wr_pref[2] = io_w_req_bits_data_2_entries_prefetch;
  assign wr_pbmt[2][0] = io_w_req_bits_data_2_entries_pbmts_0;
  assign wr_pbmt[2][1] = io_w_req_bits_data_2_entries_pbmts_1;
  assign wr_pbmt[2][2] = io_w_req_bits_data_2_entries_pbmts_2;
  assign wr_pbmt[2][3] = io_w_req_bits_data_2_entries_pbmts_3;
  assign wr_pbmt[2][4] = io_w_req_bits_data_2_entries_pbmts_4;
  assign wr_pbmt[2][5] = io_w_req_bits_data_2_entries_pbmts_5;
  assign wr_pbmt[2][6] = io_w_req_bits_data_2_entries_pbmts_6;
  assign wr_pbmt[2][7] = io_w_req_bits_data_2_entries_pbmts_7;
  assign wr_ppn [2][0] = io_w_req_bits_data_2_entries_ppns_0;
  assign wr_ppn [2][1] = io_w_req_bits_data_2_entries_ppns_1;
  assign wr_ppn [2][2] = io_w_req_bits_data_2_entries_ppns_2;
  assign wr_ppn [2][3] = io_w_req_bits_data_2_entries_ppns_3;
  assign wr_ppn [2][4] = io_w_req_bits_data_2_entries_ppns_4;
  assign wr_ppn [2][5] = io_w_req_bits_data_2_entries_ppns_5;
  assign wr_ppn [2][6] = io_w_req_bits_data_2_entries_ppns_6;
  assign wr_ppn [2][7] = io_w_req_bits_data_2_entries_ppns_7;
  assign wr_vs  [2][0] = io_w_req_bits_data_2_entries_vs_0;
  assign wr_vs  [2][1] = io_w_req_bits_data_2_entries_vs_1;
  assign wr_vs  [2][2] = io_w_req_bits_data_2_entries_vs_2;
  assign wr_vs  [2][3] = io_w_req_bits_data_2_entries_vs_3;
  assign wr_vs  [2][4] = io_w_req_bits_data_2_entries_vs_4;
  assign wr_vs  [2][5] = io_w_req_bits_data_2_entries_vs_5;
  assign wr_vs  [2][6] = io_w_req_bits_data_2_entries_vs_6;
  assign wr_vs  [2][7] = io_w_req_bits_data_2_entries_vs_7;
  assign wr_onlypf[2][0] = io_w_req_bits_data_2_entries_onlypf_0;
  assign wr_onlypf[2][1] = io_w_req_bits_data_2_entries_onlypf_1;
  assign wr_onlypf[2][2] = io_w_req_bits_data_2_entries_onlypf_2;
  assign wr_onlypf[2][3] = io_w_req_bits_data_2_entries_onlypf_3;
  assign wr_onlypf[2][4] = io_w_req_bits_data_2_entries_onlypf_4;
  assign wr_onlypf[2][5] = io_w_req_bits_data_2_entries_onlypf_5;
  assign wr_onlypf[2][6] = io_w_req_bits_data_2_entries_onlypf_6;
  assign wr_onlypf[2][7] = io_w_req_bits_data_2_entries_onlypf_7;
  assign wr_perm[2][0] = {io_w_req_bits_data_2_entries_perms_0_d,
                          io_w_req_bits_data_2_entries_perms_0_a,
                          io_w_req_bits_data_2_entries_perms_0_g,
                          io_w_req_bits_data_2_entries_perms_0_u,
                          io_w_req_bits_data_2_entries_perms_0_x,
                          io_w_req_bits_data_2_entries_perms_0_w,
                          io_w_req_bits_data_2_entries_perms_0_r};
  assign wr_perm[2][1] = {io_w_req_bits_data_2_entries_perms_1_d,
                          io_w_req_bits_data_2_entries_perms_1_a,
                          io_w_req_bits_data_2_entries_perms_1_g,
                          io_w_req_bits_data_2_entries_perms_1_u,
                          io_w_req_bits_data_2_entries_perms_1_x,
                          io_w_req_bits_data_2_entries_perms_1_w,
                          io_w_req_bits_data_2_entries_perms_1_r};
  assign wr_perm[2][2] = {io_w_req_bits_data_2_entries_perms_2_d,
                          io_w_req_bits_data_2_entries_perms_2_a,
                          io_w_req_bits_data_2_entries_perms_2_g,
                          io_w_req_bits_data_2_entries_perms_2_u,
                          io_w_req_bits_data_2_entries_perms_2_x,
                          io_w_req_bits_data_2_entries_perms_2_w,
                          io_w_req_bits_data_2_entries_perms_2_r};
  assign wr_perm[2][3] = {io_w_req_bits_data_2_entries_perms_3_d,
                          io_w_req_bits_data_2_entries_perms_3_a,
                          io_w_req_bits_data_2_entries_perms_3_g,
                          io_w_req_bits_data_2_entries_perms_3_u,
                          io_w_req_bits_data_2_entries_perms_3_x,
                          io_w_req_bits_data_2_entries_perms_3_w,
                          io_w_req_bits_data_2_entries_perms_3_r};
  assign wr_perm[2][4] = {io_w_req_bits_data_2_entries_perms_4_d,
                          io_w_req_bits_data_2_entries_perms_4_a,
                          io_w_req_bits_data_2_entries_perms_4_g,
                          io_w_req_bits_data_2_entries_perms_4_u,
                          io_w_req_bits_data_2_entries_perms_4_x,
                          io_w_req_bits_data_2_entries_perms_4_w,
                          io_w_req_bits_data_2_entries_perms_4_r};
  assign wr_perm[2][5] = {io_w_req_bits_data_2_entries_perms_5_d,
                          io_w_req_bits_data_2_entries_perms_5_a,
                          io_w_req_bits_data_2_entries_perms_5_g,
                          io_w_req_bits_data_2_entries_perms_5_u,
                          io_w_req_bits_data_2_entries_perms_5_x,
                          io_w_req_bits_data_2_entries_perms_5_w,
                          io_w_req_bits_data_2_entries_perms_5_r};
  assign wr_perm[2][6] = {io_w_req_bits_data_2_entries_perms_6_d,
                          io_w_req_bits_data_2_entries_perms_6_a,
                          io_w_req_bits_data_2_entries_perms_6_g,
                          io_w_req_bits_data_2_entries_perms_6_u,
                          io_w_req_bits_data_2_entries_perms_6_x,
                          io_w_req_bits_data_2_entries_perms_6_w,
                          io_w_req_bits_data_2_entries_perms_6_r};
  assign wr_perm[2][7] = {io_w_req_bits_data_2_entries_perms_7_d,
                          io_w_req_bits_data_2_entries_perms_7_a,
                          io_w_req_bits_data_2_entries_perms_7_g,
                          io_w_req_bits_data_2_entries_perms_7_u,
                          io_w_req_bits_data_2_entries_perms_7_x,
                          io_w_req_bits_data_2_entries_perms_7_w,
                          io_w_req_bits_data_2_entries_perms_7_r};
  assign wr_tag [3] = io_w_req_bits_data_3_entries_tag;
  assign wr_asid[3] = io_w_req_bits_data_3_entries_asid;
  assign wr_vmid[3] = io_w_req_bits_data_3_entries_vmid;
  assign wr_pref[3] = io_w_req_bits_data_3_entries_prefetch;
  assign wr_pbmt[3][0] = io_w_req_bits_data_3_entries_pbmts_0;
  assign wr_pbmt[3][1] = io_w_req_bits_data_3_entries_pbmts_1;
  assign wr_pbmt[3][2] = io_w_req_bits_data_3_entries_pbmts_2;
  assign wr_pbmt[3][3] = io_w_req_bits_data_3_entries_pbmts_3;
  assign wr_pbmt[3][4] = io_w_req_bits_data_3_entries_pbmts_4;
  assign wr_pbmt[3][5] = io_w_req_bits_data_3_entries_pbmts_5;
  assign wr_pbmt[3][6] = io_w_req_bits_data_3_entries_pbmts_6;
  assign wr_pbmt[3][7] = io_w_req_bits_data_3_entries_pbmts_7;
  assign wr_ppn [3][0] = io_w_req_bits_data_3_entries_ppns_0;
  assign wr_ppn [3][1] = io_w_req_bits_data_3_entries_ppns_1;
  assign wr_ppn [3][2] = io_w_req_bits_data_3_entries_ppns_2;
  assign wr_ppn [3][3] = io_w_req_bits_data_3_entries_ppns_3;
  assign wr_ppn [3][4] = io_w_req_bits_data_3_entries_ppns_4;
  assign wr_ppn [3][5] = io_w_req_bits_data_3_entries_ppns_5;
  assign wr_ppn [3][6] = io_w_req_bits_data_3_entries_ppns_6;
  assign wr_ppn [3][7] = io_w_req_bits_data_3_entries_ppns_7;
  assign wr_vs  [3][0] = io_w_req_bits_data_3_entries_vs_0;
  assign wr_vs  [3][1] = io_w_req_bits_data_3_entries_vs_1;
  assign wr_vs  [3][2] = io_w_req_bits_data_3_entries_vs_2;
  assign wr_vs  [3][3] = io_w_req_bits_data_3_entries_vs_3;
  assign wr_vs  [3][4] = io_w_req_bits_data_3_entries_vs_4;
  assign wr_vs  [3][5] = io_w_req_bits_data_3_entries_vs_5;
  assign wr_vs  [3][6] = io_w_req_bits_data_3_entries_vs_6;
  assign wr_vs  [3][7] = io_w_req_bits_data_3_entries_vs_7;
  assign wr_onlypf[3][0] = io_w_req_bits_data_3_entries_onlypf_0;
  assign wr_onlypf[3][1] = io_w_req_bits_data_3_entries_onlypf_1;
  assign wr_onlypf[3][2] = io_w_req_bits_data_3_entries_onlypf_2;
  assign wr_onlypf[3][3] = io_w_req_bits_data_3_entries_onlypf_3;
  assign wr_onlypf[3][4] = io_w_req_bits_data_3_entries_onlypf_4;
  assign wr_onlypf[3][5] = io_w_req_bits_data_3_entries_onlypf_5;
  assign wr_onlypf[3][6] = io_w_req_bits_data_3_entries_onlypf_6;
  assign wr_onlypf[3][7] = io_w_req_bits_data_3_entries_onlypf_7;
  assign wr_perm[3][0] = {io_w_req_bits_data_3_entries_perms_0_d,
                          io_w_req_bits_data_3_entries_perms_0_a,
                          io_w_req_bits_data_3_entries_perms_0_g,
                          io_w_req_bits_data_3_entries_perms_0_u,
                          io_w_req_bits_data_3_entries_perms_0_x,
                          io_w_req_bits_data_3_entries_perms_0_w,
                          io_w_req_bits_data_3_entries_perms_0_r};
  assign wr_perm[3][1] = {io_w_req_bits_data_3_entries_perms_1_d,
                          io_w_req_bits_data_3_entries_perms_1_a,
                          io_w_req_bits_data_3_entries_perms_1_g,
                          io_w_req_bits_data_3_entries_perms_1_u,
                          io_w_req_bits_data_3_entries_perms_1_x,
                          io_w_req_bits_data_3_entries_perms_1_w,
                          io_w_req_bits_data_3_entries_perms_1_r};
  assign wr_perm[3][2] = {io_w_req_bits_data_3_entries_perms_2_d,
                          io_w_req_bits_data_3_entries_perms_2_a,
                          io_w_req_bits_data_3_entries_perms_2_g,
                          io_w_req_bits_data_3_entries_perms_2_u,
                          io_w_req_bits_data_3_entries_perms_2_x,
                          io_w_req_bits_data_3_entries_perms_2_w,
                          io_w_req_bits_data_3_entries_perms_2_r};
  assign wr_perm[3][3] = {io_w_req_bits_data_3_entries_perms_3_d,
                          io_w_req_bits_data_3_entries_perms_3_a,
                          io_w_req_bits_data_3_entries_perms_3_g,
                          io_w_req_bits_data_3_entries_perms_3_u,
                          io_w_req_bits_data_3_entries_perms_3_x,
                          io_w_req_bits_data_3_entries_perms_3_w,
                          io_w_req_bits_data_3_entries_perms_3_r};
  assign wr_perm[3][4] = {io_w_req_bits_data_3_entries_perms_4_d,
                          io_w_req_bits_data_3_entries_perms_4_a,
                          io_w_req_bits_data_3_entries_perms_4_g,
                          io_w_req_bits_data_3_entries_perms_4_u,
                          io_w_req_bits_data_3_entries_perms_4_x,
                          io_w_req_bits_data_3_entries_perms_4_w,
                          io_w_req_bits_data_3_entries_perms_4_r};
  assign wr_perm[3][5] = {io_w_req_bits_data_3_entries_perms_5_d,
                          io_w_req_bits_data_3_entries_perms_5_a,
                          io_w_req_bits_data_3_entries_perms_5_g,
                          io_w_req_bits_data_3_entries_perms_5_u,
                          io_w_req_bits_data_3_entries_perms_5_x,
                          io_w_req_bits_data_3_entries_perms_5_w,
                          io_w_req_bits_data_3_entries_perms_5_r};
  assign wr_perm[3][6] = {io_w_req_bits_data_3_entries_perms_6_d,
                          io_w_req_bits_data_3_entries_perms_6_a,
                          io_w_req_bits_data_3_entries_perms_6_g,
                          io_w_req_bits_data_3_entries_perms_6_u,
                          io_w_req_bits_data_3_entries_perms_6_x,
                          io_w_req_bits_data_3_entries_perms_6_w,
                          io_w_req_bits_data_3_entries_perms_6_r};
  assign wr_perm[3][7] = {io_w_req_bits_data_3_entries_perms_7_d,
                          io_w_req_bits_data_3_entries_perms_7_a,
                          io_w_req_bits_data_3_entries_perms_7_g,
                          io_w_req_bits_data_3_entries_perms_7_u,
                          io_w_req_bits_data_3_entries_perms_7_x,
                          io_w_req_bits_data_3_entries_perms_7_w,
                          io_w_req_bits_data_3_entries_perms_7_r};

  // --------------------------------------------------------------------------
  xs_SplittedSRAM_ptw_core #(
    .NUM(NUM), .TAG_W(TAG_W), .ASID_W(ASID_W), .VMID_W(VMID_W),
    .PBMT_W(PBMT_W), .PPN_W(PPN_W), .PERM_W(PERM_W),
    .HAS_PERM(1), .RSVD_W(4),
    .WAY(WAY), .WAY_SPLIT(WAY_SPLIT), .DATA_SPLIT(DATA_SPLIT)
  ) u_core (
    .w_tag       (wr_tag),
    .w_asid      (wr_asid),
    .w_vmid      (wr_vmid),
    .w_pbmts     (wr_pbmt),
    .w_ppns      (wr_ppn),
    .w_vs        (wr_vs),
    .w_onlypf    (wr_onlypf),
    .w_perms     (wr_perm),
    .w_prefetch  (wr_pref),
    .w_waymask   (io_w_req_bits_waymask),
    .r_tag       (rd_tag),
    .r_asid      (rd_asid),
    .r_vmid      (rd_vmid),
    .r_pbmts     (rd_pbmt),
    .r_ppns      (rd_ppn),
    .r_vs        (rd_vs),
    .r_onlypf    (rd_onlypf),
    .r_perms     (rd_perm),
    .r_prefetch  (rd_pref),
    .arr_waymask (arr_waymask),
    .arr_wdata   (arr_wdata),
    .arr_rdata   (arr_rdata)
  );

  // --------------------------------------------------------------------------
  // 16 块内层 SRAM：每块自带一套 MBIST bore 与 sigFromSrams 广播
  // ★是分份不是共用★：编号照 golden 原样，抄错一根就是静默的真 bug。
  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  // 内层 SRAM #0：array_0_0_0（way 组 0，data 段 0，bore/sigFromSrams 编号 0）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[0][0]),
    .io_r_resp_data_1               (arr_rdata[0][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[0][0]),
    .io_w_req_bits_data_1           (arr_wdata[0][1]),
    .io_w_req_bits_waymask          (arr_waymask[0]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #1：array_0_0_1（way 组 0，data 段 1，bore/sigFromSrams 编号 1）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[1][0]),
    .io_r_resp_data_1               (arr_rdata[1][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[1][0]),
    .io_w_req_bits_data_1           (arr_wdata[1][1]),
    .io_w_req_bits_waymask          (arr_waymask[1]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_1_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_1_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_1_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_1_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_1_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_1_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_1_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #2：array_0_0_2（way 组 0，data 段 2，bore/sigFromSrams 编号 2）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[2][0]),
    .io_r_resp_data_1               (arr_rdata[2][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[2][0]),
    .io_w_req_bits_data_1           (arr_wdata[2][1]),
    .io_w_req_bits_waymask          (arr_waymask[2]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_2_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_2_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_2_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_2_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_2_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_2_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_2_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_2_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #3：array_0_0_3（way 组 0，data 段 3，bore/sigFromSrams 编号 3）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[3][0]),
    .io_r_resp_data_1               (arr_rdata[3][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[3][0]),
    .io_w_req_bits_data_1           (arr_wdata[3][1]),
    .io_w_req_bits_waymask          (arr_waymask[3]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_3_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_3_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_3_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_3_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_3_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_3_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_3_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_3_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #4：array_0_0_4（way 组 0，data 段 4，bore/sigFromSrams 编号 4）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_4 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[4][0]),
    .io_r_resp_data_1               (arr_rdata[4][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[4][0]),
    .io_w_req_bits_data_1           (arr_wdata[4][1]),
    .io_w_req_bits_waymask          (arr_waymask[4]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_4_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_4_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_4_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_4_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_4_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_4_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_4_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_4_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_4_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_4_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_4_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_4_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_4_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_4_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #5：array_0_0_5（way 组 0，data 段 5，bore/sigFromSrams 编号 5）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_5 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[5][0]),
    .io_r_resp_data_1               (arr_rdata[5][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[5][0]),
    .io_w_req_bits_data_1           (arr_wdata[5][1]),
    .io_w_req_bits_waymask          (arr_waymask[5]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_5_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_5_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_5_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_5_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_5_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_5_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_5_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_5_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_5_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_5_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_5_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_5_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_5_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_5_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #6：array_0_0_6（way 组 0，data 段 6，bore/sigFromSrams 编号 6）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_6 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[6][0]),
    .io_r_resp_data_1               (arr_rdata[6][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[6][0]),
    .io_w_req_bits_data_1           (arr_wdata[6][1]),
    .io_w_req_bits_waymask          (arr_waymask[6]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_6_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_6_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_6_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_6_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_6_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_6_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_6_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_6_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_6_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_6_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_6_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_6_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_6_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_6_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #7：array_0_0_7（way 组 0，data 段 7，bore/sigFromSrams 编号 7）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_0_7 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[7][0]),
    .io_r_resp_data_1               (arr_rdata[7][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[7][0]),
    .io_w_req_bits_data_1           (arr_wdata[7][1]),
    .io_w_req_bits_waymask          (arr_waymask[7]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_7_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_7_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_7_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_7_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_7_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_7_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_7_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_7_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_7_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_7_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_7_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_7_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_7_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_7_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #8：array_0_1_0（way 组 1，data 段 0，bore/sigFromSrams 编号 8）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_1_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[8][0]),
    .io_r_resp_data_1               (arr_rdata[8][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[8][0]),
    .io_w_req_bits_data_1           (arr_wdata[8][1]),
    .io_w_req_bits_waymask          (arr_waymask[8]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_8_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_8_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_8_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_8_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_8_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_8_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_8_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_8_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_8_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_8_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_8_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_8_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_8_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_8_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #9：array_0_1_1（way 组 1，data 段 1，bore/sigFromSrams 编号 9）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_1_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[9][0]),
    .io_r_resp_data_1               (arr_rdata[9][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[9][0]),
    .io_w_req_bits_data_1           (arr_wdata[9][1]),
    .io_w_req_bits_waymask          (arr_waymask[9]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_9_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_9_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_9_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_9_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_9_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_9_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_9_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_9_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_9_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_9_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_9_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_9_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_9_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_9_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #10：array_0_1_2（way 组 1，data 段 2，bore/sigFromSrams 编号 10）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_1_2 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[10][0]),
    .io_r_resp_data_1               (arr_rdata[10][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[10][0]),
    .io_w_req_bits_data_1           (arr_wdata[10][1]),
    .io_w_req_bits_waymask          (arr_waymask[10]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_10_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_10_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_10_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_10_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_10_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_10_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_10_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_10_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_10_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_10_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_10_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_10_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_10_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_10_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_10_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #11：array_0_1_3（way 组 1，data 段 3，bore/sigFromSrams 编号 11）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_1_3 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[11][0]),
    .io_r_resp_data_1               (arr_rdata[11][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[11][0]),
    .io_w_req_bits_data_1           (arr_wdata[11][1]),
    .io_w_req_bits_waymask          (arr_waymask[11]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_11_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_11_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_11_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_11_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_11_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_11_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_11_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_11_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_11_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_11_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_11_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_11_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_11_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_11_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_11_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_11_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_11_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #12：array_0_1_4（way 组 1，data 段 4，bore/sigFromSrams 编号 12）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_1_4 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[12][0]),
    .io_r_resp_data_1               (arr_rdata[12][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[12][0]),
    .io_w_req_bits_data_1           (arr_wdata[12][1]),
    .io_w_req_bits_waymask          (arr_waymask[12]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_12_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_12_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_12_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_12_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_12_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_12_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_12_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_12_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_12_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_12_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_12_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_12_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_12_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_12_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_12_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_12_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_12_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #13：array_0_1_5（way 组 1，data 段 5，bore/sigFromSrams 编号 13）
  // --------------------------------------------------------------------------
  SRAMTemplate_129 array_0_1_5 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[13][0]),
    .io_r_resp_data_1               (arr_rdata[13][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[13][0]),
    .io_w_req_bits_data_1           (arr_wdata[13][1]),
    .io_w_req_bits_waymask          (arr_waymask[13]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_13_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_13_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_13_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_13_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_13_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_13_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_13_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_13_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_13_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_13_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_13_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_13_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_13_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_13_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_13_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_13_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_13_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #14：array_0_1_6（way 组 1，data 段 6，bore/sigFromSrams 编号 14）
  // --------------------------------------------------------------------------
  SRAMTemplate_143 array_0_1_6 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[14][0]),
    .io_r_resp_data_1               (arr_rdata[14][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[14][0]),
    .io_w_req_bits_data_1           (arr_wdata[14][1]),
    .io_w_req_bits_waymask          (arr_waymask[14]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_14_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_14_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_14_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_14_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_14_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_14_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_14_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_14_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_14_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_14_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_14_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_14_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_14_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_14_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_14_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_14_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_14_array)
  );
  // --------------------------------------------------------------------------
  // 内层 SRAM #15：array_0_1_7（way 组 1，data 段 7，bore/sigFromSrams 编号 15）
  // --------------------------------------------------------------------------
  SRAMTemplate_143 array_0_1_7 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[15][0]),
    .io_r_resp_data_1               (arr_rdata[15][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[15][0]),
    .io_w_req_bits_data_1           (arr_wdata[15][1]),
    .io_w_req_bits_waymask          (arr_waymask[15]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_15_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_15_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_15_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_15_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_15_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_15_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_15_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_15_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_15_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_15_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_15_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_15_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_15_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_15_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_15_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_15_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_15_array)
  );

  // --------------------------------------------------------------------------
  // 读出回填：把核给出的 struct 字段摊回 golden 的扁平输出端口
  // --------------------------------------------------------------------------
  assign io_r_resp_data_0_entries_tag = rd_tag[0];
  assign io_r_resp_data_0_entries_asid = rd_asid[0];
  assign io_r_resp_data_0_entries_vmid = rd_vmid[0];
  assign io_r_resp_data_0_entries_pbmts_0 = rd_pbmt[0][0];
  assign io_r_resp_data_0_entries_pbmts_1 = rd_pbmt[0][1];
  assign io_r_resp_data_0_entries_pbmts_2 = rd_pbmt[0][2];
  assign io_r_resp_data_0_entries_pbmts_3 = rd_pbmt[0][3];
  assign io_r_resp_data_0_entries_pbmts_4 = rd_pbmt[0][4];
  assign io_r_resp_data_0_entries_pbmts_5 = rd_pbmt[0][5];
  assign io_r_resp_data_0_entries_pbmts_6 = rd_pbmt[0][6];
  assign io_r_resp_data_0_entries_pbmts_7 = rd_pbmt[0][7];
  assign io_r_resp_data_0_entries_ppns_0 = rd_ppn[0][0];
  assign io_r_resp_data_0_entries_ppns_1 = rd_ppn[0][1];
  assign io_r_resp_data_0_entries_ppns_2 = rd_ppn[0][2];
  assign io_r_resp_data_0_entries_ppns_3 = rd_ppn[0][3];
  assign io_r_resp_data_0_entries_ppns_4 = rd_ppn[0][4];
  assign io_r_resp_data_0_entries_ppns_5 = rd_ppn[0][5];
  assign io_r_resp_data_0_entries_ppns_6 = rd_ppn[0][6];
  assign io_r_resp_data_0_entries_ppns_7 = rd_ppn[0][7];
  assign io_r_resp_data_0_entries_vs_0 = rd_vs[0][0];
  assign io_r_resp_data_0_entries_vs_1 = rd_vs[0][1];
  assign io_r_resp_data_0_entries_vs_2 = rd_vs[0][2];
  assign io_r_resp_data_0_entries_vs_3 = rd_vs[0][3];
  assign io_r_resp_data_0_entries_vs_4 = rd_vs[0][4];
  assign io_r_resp_data_0_entries_vs_5 = rd_vs[0][5];
  assign io_r_resp_data_0_entries_vs_6 = rd_vs[0][6];
  assign io_r_resp_data_0_entries_vs_7 = rd_vs[0][7];
  assign io_r_resp_data_0_entries_onlypf_0 = rd_onlypf[0][0];
  assign io_r_resp_data_0_entries_onlypf_1 = rd_onlypf[0][1];
  assign io_r_resp_data_0_entries_onlypf_2 = rd_onlypf[0][2];
  assign io_r_resp_data_0_entries_onlypf_3 = rd_onlypf[0][3];
  assign io_r_resp_data_0_entries_onlypf_4 = rd_onlypf[0][4];
  assign io_r_resp_data_0_entries_onlypf_5 = rd_onlypf[0][5];
  assign io_r_resp_data_0_entries_onlypf_6 = rd_onlypf[0][6];
  assign io_r_resp_data_0_entries_onlypf_7 = rd_onlypf[0][7];
  assign io_r_resp_data_0_entries_perms_0_d = rd_perm[0][0][6];
  assign io_r_resp_data_0_entries_perms_0_a = rd_perm[0][0][5];
  assign io_r_resp_data_0_entries_perms_0_g = rd_perm[0][0][4];
  assign io_r_resp_data_0_entries_perms_0_u = rd_perm[0][0][3];
  assign io_r_resp_data_0_entries_perms_0_x = rd_perm[0][0][2];
  assign io_r_resp_data_0_entries_perms_0_w = rd_perm[0][0][1];
  assign io_r_resp_data_0_entries_perms_0_r = rd_perm[0][0][0];
  assign io_r_resp_data_0_entries_perms_1_d = rd_perm[0][1][6];
  assign io_r_resp_data_0_entries_perms_1_a = rd_perm[0][1][5];
  assign io_r_resp_data_0_entries_perms_1_g = rd_perm[0][1][4];
  assign io_r_resp_data_0_entries_perms_1_u = rd_perm[0][1][3];
  assign io_r_resp_data_0_entries_perms_1_x = rd_perm[0][1][2];
  assign io_r_resp_data_0_entries_perms_1_w = rd_perm[0][1][1];
  assign io_r_resp_data_0_entries_perms_1_r = rd_perm[0][1][0];
  assign io_r_resp_data_0_entries_perms_2_d = rd_perm[0][2][6];
  assign io_r_resp_data_0_entries_perms_2_a = rd_perm[0][2][5];
  assign io_r_resp_data_0_entries_perms_2_g = rd_perm[0][2][4];
  assign io_r_resp_data_0_entries_perms_2_u = rd_perm[0][2][3];
  assign io_r_resp_data_0_entries_perms_2_x = rd_perm[0][2][2];
  assign io_r_resp_data_0_entries_perms_2_w = rd_perm[0][2][1];
  assign io_r_resp_data_0_entries_perms_2_r = rd_perm[0][2][0];
  assign io_r_resp_data_0_entries_perms_3_d = rd_perm[0][3][6];
  assign io_r_resp_data_0_entries_perms_3_a = rd_perm[0][3][5];
  assign io_r_resp_data_0_entries_perms_3_g = rd_perm[0][3][4];
  assign io_r_resp_data_0_entries_perms_3_u = rd_perm[0][3][3];
  assign io_r_resp_data_0_entries_perms_3_x = rd_perm[0][3][2];
  assign io_r_resp_data_0_entries_perms_3_w = rd_perm[0][3][1];
  assign io_r_resp_data_0_entries_perms_3_r = rd_perm[0][3][0];
  assign io_r_resp_data_0_entries_perms_4_d = rd_perm[0][4][6];
  assign io_r_resp_data_0_entries_perms_4_a = rd_perm[0][4][5];
  assign io_r_resp_data_0_entries_perms_4_g = rd_perm[0][4][4];
  assign io_r_resp_data_0_entries_perms_4_u = rd_perm[0][4][3];
  assign io_r_resp_data_0_entries_perms_4_x = rd_perm[0][4][2];
  assign io_r_resp_data_0_entries_perms_4_w = rd_perm[0][4][1];
  assign io_r_resp_data_0_entries_perms_4_r = rd_perm[0][4][0];
  assign io_r_resp_data_0_entries_perms_5_d = rd_perm[0][5][6];
  assign io_r_resp_data_0_entries_perms_5_a = rd_perm[0][5][5];
  assign io_r_resp_data_0_entries_perms_5_g = rd_perm[0][5][4];
  assign io_r_resp_data_0_entries_perms_5_u = rd_perm[0][5][3];
  assign io_r_resp_data_0_entries_perms_5_x = rd_perm[0][5][2];
  assign io_r_resp_data_0_entries_perms_5_w = rd_perm[0][5][1];
  assign io_r_resp_data_0_entries_perms_5_r = rd_perm[0][5][0];
  assign io_r_resp_data_0_entries_perms_6_d = rd_perm[0][6][6];
  assign io_r_resp_data_0_entries_perms_6_a = rd_perm[0][6][5];
  assign io_r_resp_data_0_entries_perms_6_g = rd_perm[0][6][4];
  assign io_r_resp_data_0_entries_perms_6_u = rd_perm[0][6][3];
  assign io_r_resp_data_0_entries_perms_6_x = rd_perm[0][6][2];
  assign io_r_resp_data_0_entries_perms_6_w = rd_perm[0][6][1];
  assign io_r_resp_data_0_entries_perms_6_r = rd_perm[0][6][0];
  assign io_r_resp_data_0_entries_perms_7_d = rd_perm[0][7][6];
  assign io_r_resp_data_0_entries_perms_7_a = rd_perm[0][7][5];
  assign io_r_resp_data_0_entries_perms_7_g = rd_perm[0][7][4];
  assign io_r_resp_data_0_entries_perms_7_u = rd_perm[0][7][3];
  assign io_r_resp_data_0_entries_perms_7_x = rd_perm[0][7][2];
  assign io_r_resp_data_0_entries_perms_7_w = rd_perm[0][7][1];
  assign io_r_resp_data_0_entries_perms_7_r = rd_perm[0][7][0];
  assign io_r_resp_data_0_entries_prefetch = rd_pref[0];
  assign io_r_resp_data_1_entries_tag = rd_tag[1];
  assign io_r_resp_data_1_entries_asid = rd_asid[1];
  assign io_r_resp_data_1_entries_vmid = rd_vmid[1];
  assign io_r_resp_data_1_entries_pbmts_0 = rd_pbmt[1][0];
  assign io_r_resp_data_1_entries_pbmts_1 = rd_pbmt[1][1];
  assign io_r_resp_data_1_entries_pbmts_2 = rd_pbmt[1][2];
  assign io_r_resp_data_1_entries_pbmts_3 = rd_pbmt[1][3];
  assign io_r_resp_data_1_entries_pbmts_4 = rd_pbmt[1][4];
  assign io_r_resp_data_1_entries_pbmts_5 = rd_pbmt[1][5];
  assign io_r_resp_data_1_entries_pbmts_6 = rd_pbmt[1][6];
  assign io_r_resp_data_1_entries_pbmts_7 = rd_pbmt[1][7];
  assign io_r_resp_data_1_entries_ppns_0 = rd_ppn[1][0];
  assign io_r_resp_data_1_entries_ppns_1 = rd_ppn[1][1];
  assign io_r_resp_data_1_entries_ppns_2 = rd_ppn[1][2];
  assign io_r_resp_data_1_entries_ppns_3 = rd_ppn[1][3];
  assign io_r_resp_data_1_entries_ppns_4 = rd_ppn[1][4];
  assign io_r_resp_data_1_entries_ppns_5 = rd_ppn[1][5];
  assign io_r_resp_data_1_entries_ppns_6 = rd_ppn[1][6];
  assign io_r_resp_data_1_entries_ppns_7 = rd_ppn[1][7];
  assign io_r_resp_data_1_entries_vs_0 = rd_vs[1][0];
  assign io_r_resp_data_1_entries_vs_1 = rd_vs[1][1];
  assign io_r_resp_data_1_entries_vs_2 = rd_vs[1][2];
  assign io_r_resp_data_1_entries_vs_3 = rd_vs[1][3];
  assign io_r_resp_data_1_entries_vs_4 = rd_vs[1][4];
  assign io_r_resp_data_1_entries_vs_5 = rd_vs[1][5];
  assign io_r_resp_data_1_entries_vs_6 = rd_vs[1][6];
  assign io_r_resp_data_1_entries_vs_7 = rd_vs[1][7];
  assign io_r_resp_data_1_entries_onlypf_0 = rd_onlypf[1][0];
  assign io_r_resp_data_1_entries_onlypf_1 = rd_onlypf[1][1];
  assign io_r_resp_data_1_entries_onlypf_2 = rd_onlypf[1][2];
  assign io_r_resp_data_1_entries_onlypf_3 = rd_onlypf[1][3];
  assign io_r_resp_data_1_entries_onlypf_4 = rd_onlypf[1][4];
  assign io_r_resp_data_1_entries_onlypf_5 = rd_onlypf[1][5];
  assign io_r_resp_data_1_entries_onlypf_6 = rd_onlypf[1][6];
  assign io_r_resp_data_1_entries_onlypf_7 = rd_onlypf[1][7];
  assign io_r_resp_data_1_entries_perms_0_d = rd_perm[1][0][6];
  assign io_r_resp_data_1_entries_perms_0_a = rd_perm[1][0][5];
  assign io_r_resp_data_1_entries_perms_0_g = rd_perm[1][0][4];
  assign io_r_resp_data_1_entries_perms_0_u = rd_perm[1][0][3];
  assign io_r_resp_data_1_entries_perms_0_x = rd_perm[1][0][2];
  assign io_r_resp_data_1_entries_perms_0_w = rd_perm[1][0][1];
  assign io_r_resp_data_1_entries_perms_0_r = rd_perm[1][0][0];
  assign io_r_resp_data_1_entries_perms_1_d = rd_perm[1][1][6];
  assign io_r_resp_data_1_entries_perms_1_a = rd_perm[1][1][5];
  assign io_r_resp_data_1_entries_perms_1_g = rd_perm[1][1][4];
  assign io_r_resp_data_1_entries_perms_1_u = rd_perm[1][1][3];
  assign io_r_resp_data_1_entries_perms_1_x = rd_perm[1][1][2];
  assign io_r_resp_data_1_entries_perms_1_w = rd_perm[1][1][1];
  assign io_r_resp_data_1_entries_perms_1_r = rd_perm[1][1][0];
  assign io_r_resp_data_1_entries_perms_2_d = rd_perm[1][2][6];
  assign io_r_resp_data_1_entries_perms_2_a = rd_perm[1][2][5];
  assign io_r_resp_data_1_entries_perms_2_g = rd_perm[1][2][4];
  assign io_r_resp_data_1_entries_perms_2_u = rd_perm[1][2][3];
  assign io_r_resp_data_1_entries_perms_2_x = rd_perm[1][2][2];
  assign io_r_resp_data_1_entries_perms_2_w = rd_perm[1][2][1];
  assign io_r_resp_data_1_entries_perms_2_r = rd_perm[1][2][0];
  assign io_r_resp_data_1_entries_perms_3_d = rd_perm[1][3][6];
  assign io_r_resp_data_1_entries_perms_3_a = rd_perm[1][3][5];
  assign io_r_resp_data_1_entries_perms_3_g = rd_perm[1][3][4];
  assign io_r_resp_data_1_entries_perms_3_u = rd_perm[1][3][3];
  assign io_r_resp_data_1_entries_perms_3_x = rd_perm[1][3][2];
  assign io_r_resp_data_1_entries_perms_3_w = rd_perm[1][3][1];
  assign io_r_resp_data_1_entries_perms_3_r = rd_perm[1][3][0];
  assign io_r_resp_data_1_entries_perms_4_d = rd_perm[1][4][6];
  assign io_r_resp_data_1_entries_perms_4_a = rd_perm[1][4][5];
  assign io_r_resp_data_1_entries_perms_4_g = rd_perm[1][4][4];
  assign io_r_resp_data_1_entries_perms_4_u = rd_perm[1][4][3];
  assign io_r_resp_data_1_entries_perms_4_x = rd_perm[1][4][2];
  assign io_r_resp_data_1_entries_perms_4_w = rd_perm[1][4][1];
  assign io_r_resp_data_1_entries_perms_4_r = rd_perm[1][4][0];
  assign io_r_resp_data_1_entries_perms_5_d = rd_perm[1][5][6];
  assign io_r_resp_data_1_entries_perms_5_a = rd_perm[1][5][5];
  assign io_r_resp_data_1_entries_perms_5_g = rd_perm[1][5][4];
  assign io_r_resp_data_1_entries_perms_5_u = rd_perm[1][5][3];
  assign io_r_resp_data_1_entries_perms_5_x = rd_perm[1][5][2];
  assign io_r_resp_data_1_entries_perms_5_w = rd_perm[1][5][1];
  assign io_r_resp_data_1_entries_perms_5_r = rd_perm[1][5][0];
  assign io_r_resp_data_1_entries_perms_6_d = rd_perm[1][6][6];
  assign io_r_resp_data_1_entries_perms_6_a = rd_perm[1][6][5];
  assign io_r_resp_data_1_entries_perms_6_g = rd_perm[1][6][4];
  assign io_r_resp_data_1_entries_perms_6_u = rd_perm[1][6][3];
  assign io_r_resp_data_1_entries_perms_6_x = rd_perm[1][6][2];
  assign io_r_resp_data_1_entries_perms_6_w = rd_perm[1][6][1];
  assign io_r_resp_data_1_entries_perms_6_r = rd_perm[1][6][0];
  assign io_r_resp_data_1_entries_perms_7_d = rd_perm[1][7][6];
  assign io_r_resp_data_1_entries_perms_7_a = rd_perm[1][7][5];
  assign io_r_resp_data_1_entries_perms_7_g = rd_perm[1][7][4];
  assign io_r_resp_data_1_entries_perms_7_u = rd_perm[1][7][3];
  assign io_r_resp_data_1_entries_perms_7_x = rd_perm[1][7][2];
  assign io_r_resp_data_1_entries_perms_7_w = rd_perm[1][7][1];
  assign io_r_resp_data_1_entries_perms_7_r = rd_perm[1][7][0];
  assign io_r_resp_data_1_entries_prefetch = rd_pref[1];
  assign io_r_resp_data_2_entries_tag = rd_tag[2];
  assign io_r_resp_data_2_entries_asid = rd_asid[2];
  assign io_r_resp_data_2_entries_vmid = rd_vmid[2];
  assign io_r_resp_data_2_entries_pbmts_0 = rd_pbmt[2][0];
  assign io_r_resp_data_2_entries_pbmts_1 = rd_pbmt[2][1];
  assign io_r_resp_data_2_entries_pbmts_2 = rd_pbmt[2][2];
  assign io_r_resp_data_2_entries_pbmts_3 = rd_pbmt[2][3];
  assign io_r_resp_data_2_entries_pbmts_4 = rd_pbmt[2][4];
  assign io_r_resp_data_2_entries_pbmts_5 = rd_pbmt[2][5];
  assign io_r_resp_data_2_entries_pbmts_6 = rd_pbmt[2][6];
  assign io_r_resp_data_2_entries_pbmts_7 = rd_pbmt[2][7];
  assign io_r_resp_data_2_entries_ppns_0 = rd_ppn[2][0];
  assign io_r_resp_data_2_entries_ppns_1 = rd_ppn[2][1];
  assign io_r_resp_data_2_entries_ppns_2 = rd_ppn[2][2];
  assign io_r_resp_data_2_entries_ppns_3 = rd_ppn[2][3];
  assign io_r_resp_data_2_entries_ppns_4 = rd_ppn[2][4];
  assign io_r_resp_data_2_entries_ppns_5 = rd_ppn[2][5];
  assign io_r_resp_data_2_entries_ppns_6 = rd_ppn[2][6];
  assign io_r_resp_data_2_entries_ppns_7 = rd_ppn[2][7];
  assign io_r_resp_data_2_entries_vs_0 = rd_vs[2][0];
  assign io_r_resp_data_2_entries_vs_1 = rd_vs[2][1];
  assign io_r_resp_data_2_entries_vs_2 = rd_vs[2][2];
  assign io_r_resp_data_2_entries_vs_3 = rd_vs[2][3];
  assign io_r_resp_data_2_entries_vs_4 = rd_vs[2][4];
  assign io_r_resp_data_2_entries_vs_5 = rd_vs[2][5];
  assign io_r_resp_data_2_entries_vs_6 = rd_vs[2][6];
  assign io_r_resp_data_2_entries_vs_7 = rd_vs[2][7];
  assign io_r_resp_data_2_entries_onlypf_0 = rd_onlypf[2][0];
  assign io_r_resp_data_2_entries_onlypf_1 = rd_onlypf[2][1];
  assign io_r_resp_data_2_entries_onlypf_2 = rd_onlypf[2][2];
  assign io_r_resp_data_2_entries_onlypf_3 = rd_onlypf[2][3];
  assign io_r_resp_data_2_entries_onlypf_4 = rd_onlypf[2][4];
  assign io_r_resp_data_2_entries_onlypf_5 = rd_onlypf[2][5];
  assign io_r_resp_data_2_entries_onlypf_6 = rd_onlypf[2][6];
  assign io_r_resp_data_2_entries_onlypf_7 = rd_onlypf[2][7];
  assign io_r_resp_data_2_entries_perms_0_d = rd_perm[2][0][6];
  assign io_r_resp_data_2_entries_perms_0_a = rd_perm[2][0][5];
  assign io_r_resp_data_2_entries_perms_0_g = rd_perm[2][0][4];
  assign io_r_resp_data_2_entries_perms_0_u = rd_perm[2][0][3];
  assign io_r_resp_data_2_entries_perms_0_x = rd_perm[2][0][2];
  assign io_r_resp_data_2_entries_perms_0_w = rd_perm[2][0][1];
  assign io_r_resp_data_2_entries_perms_0_r = rd_perm[2][0][0];
  assign io_r_resp_data_2_entries_perms_1_d = rd_perm[2][1][6];
  assign io_r_resp_data_2_entries_perms_1_a = rd_perm[2][1][5];
  assign io_r_resp_data_2_entries_perms_1_g = rd_perm[2][1][4];
  assign io_r_resp_data_2_entries_perms_1_u = rd_perm[2][1][3];
  assign io_r_resp_data_2_entries_perms_1_x = rd_perm[2][1][2];
  assign io_r_resp_data_2_entries_perms_1_w = rd_perm[2][1][1];
  assign io_r_resp_data_2_entries_perms_1_r = rd_perm[2][1][0];
  assign io_r_resp_data_2_entries_perms_2_d = rd_perm[2][2][6];
  assign io_r_resp_data_2_entries_perms_2_a = rd_perm[2][2][5];
  assign io_r_resp_data_2_entries_perms_2_g = rd_perm[2][2][4];
  assign io_r_resp_data_2_entries_perms_2_u = rd_perm[2][2][3];
  assign io_r_resp_data_2_entries_perms_2_x = rd_perm[2][2][2];
  assign io_r_resp_data_2_entries_perms_2_w = rd_perm[2][2][1];
  assign io_r_resp_data_2_entries_perms_2_r = rd_perm[2][2][0];
  assign io_r_resp_data_2_entries_perms_3_d = rd_perm[2][3][6];
  assign io_r_resp_data_2_entries_perms_3_a = rd_perm[2][3][5];
  assign io_r_resp_data_2_entries_perms_3_g = rd_perm[2][3][4];
  assign io_r_resp_data_2_entries_perms_3_u = rd_perm[2][3][3];
  assign io_r_resp_data_2_entries_perms_3_x = rd_perm[2][3][2];
  assign io_r_resp_data_2_entries_perms_3_w = rd_perm[2][3][1];
  assign io_r_resp_data_2_entries_perms_3_r = rd_perm[2][3][0];
  assign io_r_resp_data_2_entries_perms_4_d = rd_perm[2][4][6];
  assign io_r_resp_data_2_entries_perms_4_a = rd_perm[2][4][5];
  assign io_r_resp_data_2_entries_perms_4_g = rd_perm[2][4][4];
  assign io_r_resp_data_2_entries_perms_4_u = rd_perm[2][4][3];
  assign io_r_resp_data_2_entries_perms_4_x = rd_perm[2][4][2];
  assign io_r_resp_data_2_entries_perms_4_w = rd_perm[2][4][1];
  assign io_r_resp_data_2_entries_perms_4_r = rd_perm[2][4][0];
  assign io_r_resp_data_2_entries_perms_5_d = rd_perm[2][5][6];
  assign io_r_resp_data_2_entries_perms_5_a = rd_perm[2][5][5];
  assign io_r_resp_data_2_entries_perms_5_g = rd_perm[2][5][4];
  assign io_r_resp_data_2_entries_perms_5_u = rd_perm[2][5][3];
  assign io_r_resp_data_2_entries_perms_5_x = rd_perm[2][5][2];
  assign io_r_resp_data_2_entries_perms_5_w = rd_perm[2][5][1];
  assign io_r_resp_data_2_entries_perms_5_r = rd_perm[2][5][0];
  assign io_r_resp_data_2_entries_perms_6_d = rd_perm[2][6][6];
  assign io_r_resp_data_2_entries_perms_6_a = rd_perm[2][6][5];
  assign io_r_resp_data_2_entries_perms_6_g = rd_perm[2][6][4];
  assign io_r_resp_data_2_entries_perms_6_u = rd_perm[2][6][3];
  assign io_r_resp_data_2_entries_perms_6_x = rd_perm[2][6][2];
  assign io_r_resp_data_2_entries_perms_6_w = rd_perm[2][6][1];
  assign io_r_resp_data_2_entries_perms_6_r = rd_perm[2][6][0];
  assign io_r_resp_data_2_entries_perms_7_d = rd_perm[2][7][6];
  assign io_r_resp_data_2_entries_perms_7_a = rd_perm[2][7][5];
  assign io_r_resp_data_2_entries_perms_7_g = rd_perm[2][7][4];
  assign io_r_resp_data_2_entries_perms_7_u = rd_perm[2][7][3];
  assign io_r_resp_data_2_entries_perms_7_x = rd_perm[2][7][2];
  assign io_r_resp_data_2_entries_perms_7_w = rd_perm[2][7][1];
  assign io_r_resp_data_2_entries_perms_7_r = rd_perm[2][7][0];
  assign io_r_resp_data_2_entries_prefetch = rd_pref[2];
  assign io_r_resp_data_3_entries_tag = rd_tag[3];
  assign io_r_resp_data_3_entries_asid = rd_asid[3];
  assign io_r_resp_data_3_entries_vmid = rd_vmid[3];
  assign io_r_resp_data_3_entries_pbmts_0 = rd_pbmt[3][0];
  assign io_r_resp_data_3_entries_pbmts_1 = rd_pbmt[3][1];
  assign io_r_resp_data_3_entries_pbmts_2 = rd_pbmt[3][2];
  assign io_r_resp_data_3_entries_pbmts_3 = rd_pbmt[3][3];
  assign io_r_resp_data_3_entries_pbmts_4 = rd_pbmt[3][4];
  assign io_r_resp_data_3_entries_pbmts_5 = rd_pbmt[3][5];
  assign io_r_resp_data_3_entries_pbmts_6 = rd_pbmt[3][6];
  assign io_r_resp_data_3_entries_pbmts_7 = rd_pbmt[3][7];
  assign io_r_resp_data_3_entries_ppns_0 = rd_ppn[3][0];
  assign io_r_resp_data_3_entries_ppns_1 = rd_ppn[3][1];
  assign io_r_resp_data_3_entries_ppns_2 = rd_ppn[3][2];
  assign io_r_resp_data_3_entries_ppns_3 = rd_ppn[3][3];
  assign io_r_resp_data_3_entries_ppns_4 = rd_ppn[3][4];
  assign io_r_resp_data_3_entries_ppns_5 = rd_ppn[3][5];
  assign io_r_resp_data_3_entries_ppns_6 = rd_ppn[3][6];
  assign io_r_resp_data_3_entries_ppns_7 = rd_ppn[3][7];
  assign io_r_resp_data_3_entries_vs_0 = rd_vs[3][0];
  assign io_r_resp_data_3_entries_vs_1 = rd_vs[3][1];
  assign io_r_resp_data_3_entries_vs_2 = rd_vs[3][2];
  assign io_r_resp_data_3_entries_vs_3 = rd_vs[3][3];
  assign io_r_resp_data_3_entries_vs_4 = rd_vs[3][4];
  assign io_r_resp_data_3_entries_vs_5 = rd_vs[3][5];
  assign io_r_resp_data_3_entries_vs_6 = rd_vs[3][6];
  assign io_r_resp_data_3_entries_vs_7 = rd_vs[3][7];
  assign io_r_resp_data_3_entries_onlypf_0 = rd_onlypf[3][0];
  assign io_r_resp_data_3_entries_onlypf_1 = rd_onlypf[3][1];
  assign io_r_resp_data_3_entries_onlypf_2 = rd_onlypf[3][2];
  assign io_r_resp_data_3_entries_onlypf_3 = rd_onlypf[3][3];
  assign io_r_resp_data_3_entries_onlypf_4 = rd_onlypf[3][4];
  assign io_r_resp_data_3_entries_onlypf_5 = rd_onlypf[3][5];
  assign io_r_resp_data_3_entries_onlypf_6 = rd_onlypf[3][6];
  assign io_r_resp_data_3_entries_onlypf_7 = rd_onlypf[3][7];
  assign io_r_resp_data_3_entries_perms_0_d = rd_perm[3][0][6];
  assign io_r_resp_data_3_entries_perms_0_a = rd_perm[3][0][5];
  assign io_r_resp_data_3_entries_perms_0_g = rd_perm[3][0][4];
  assign io_r_resp_data_3_entries_perms_0_u = rd_perm[3][0][3];
  assign io_r_resp_data_3_entries_perms_0_x = rd_perm[3][0][2];
  assign io_r_resp_data_3_entries_perms_0_w = rd_perm[3][0][1];
  assign io_r_resp_data_3_entries_perms_0_r = rd_perm[3][0][0];
  assign io_r_resp_data_3_entries_perms_1_d = rd_perm[3][1][6];
  assign io_r_resp_data_3_entries_perms_1_a = rd_perm[3][1][5];
  assign io_r_resp_data_3_entries_perms_1_g = rd_perm[3][1][4];
  assign io_r_resp_data_3_entries_perms_1_u = rd_perm[3][1][3];
  assign io_r_resp_data_3_entries_perms_1_x = rd_perm[3][1][2];
  assign io_r_resp_data_3_entries_perms_1_w = rd_perm[3][1][1];
  assign io_r_resp_data_3_entries_perms_1_r = rd_perm[3][1][0];
  assign io_r_resp_data_3_entries_perms_2_d = rd_perm[3][2][6];
  assign io_r_resp_data_3_entries_perms_2_a = rd_perm[3][2][5];
  assign io_r_resp_data_3_entries_perms_2_g = rd_perm[3][2][4];
  assign io_r_resp_data_3_entries_perms_2_u = rd_perm[3][2][3];
  assign io_r_resp_data_3_entries_perms_2_x = rd_perm[3][2][2];
  assign io_r_resp_data_3_entries_perms_2_w = rd_perm[3][2][1];
  assign io_r_resp_data_3_entries_perms_2_r = rd_perm[3][2][0];
  assign io_r_resp_data_3_entries_perms_3_d = rd_perm[3][3][6];
  assign io_r_resp_data_3_entries_perms_3_a = rd_perm[3][3][5];
  assign io_r_resp_data_3_entries_perms_3_g = rd_perm[3][3][4];
  assign io_r_resp_data_3_entries_perms_3_u = rd_perm[3][3][3];
  assign io_r_resp_data_3_entries_perms_3_x = rd_perm[3][3][2];
  assign io_r_resp_data_3_entries_perms_3_w = rd_perm[3][3][1];
  assign io_r_resp_data_3_entries_perms_3_r = rd_perm[3][3][0];
  assign io_r_resp_data_3_entries_perms_4_d = rd_perm[3][4][6];
  assign io_r_resp_data_3_entries_perms_4_a = rd_perm[3][4][5];
  assign io_r_resp_data_3_entries_perms_4_g = rd_perm[3][4][4];
  assign io_r_resp_data_3_entries_perms_4_u = rd_perm[3][4][3];
  assign io_r_resp_data_3_entries_perms_4_x = rd_perm[3][4][2];
  assign io_r_resp_data_3_entries_perms_4_w = rd_perm[3][4][1];
  assign io_r_resp_data_3_entries_perms_4_r = rd_perm[3][4][0];
  assign io_r_resp_data_3_entries_perms_5_d = rd_perm[3][5][6];
  assign io_r_resp_data_3_entries_perms_5_a = rd_perm[3][5][5];
  assign io_r_resp_data_3_entries_perms_5_g = rd_perm[3][5][4];
  assign io_r_resp_data_3_entries_perms_5_u = rd_perm[3][5][3];
  assign io_r_resp_data_3_entries_perms_5_x = rd_perm[3][5][2];
  assign io_r_resp_data_3_entries_perms_5_w = rd_perm[3][5][1];
  assign io_r_resp_data_3_entries_perms_5_r = rd_perm[3][5][0];
  assign io_r_resp_data_3_entries_perms_6_d = rd_perm[3][6][6];
  assign io_r_resp_data_3_entries_perms_6_a = rd_perm[3][6][5];
  assign io_r_resp_data_3_entries_perms_6_g = rd_perm[3][6][4];
  assign io_r_resp_data_3_entries_perms_6_u = rd_perm[3][6][3];
  assign io_r_resp_data_3_entries_perms_6_x = rd_perm[3][6][2];
  assign io_r_resp_data_3_entries_perms_6_w = rd_perm[3][6][1];
  assign io_r_resp_data_3_entries_perms_6_r = rd_perm[3][6][0];
  assign io_r_resp_data_3_entries_perms_7_d = rd_perm[3][7][6];
  assign io_r_resp_data_3_entries_perms_7_a = rd_perm[3][7][5];
  assign io_r_resp_data_3_entries_perms_7_g = rd_perm[3][7][4];
  assign io_r_resp_data_3_entries_perms_7_u = rd_perm[3][7][3];
  assign io_r_resp_data_3_entries_perms_7_x = rd_perm[3][7][2];
  assign io_r_resp_data_3_entries_perms_7_w = rd_perm[3][7][1];
  assign io_r_resp_data_3_entries_perms_7_r = rd_perm[3][7][0];
  assign io_r_resp_data_3_entries_prefetch = rd_pref[3];
endmodule
