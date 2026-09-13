// 自动生成：verif/ut/PriorityMuxModule/gen.py（读 G1 golden）—— 勿手改
// PriorityMuxModule 家族 6 变体双例化逐拍比对：
//   golden <V> vs 可读重写 <V>_xs（同一个 xs_PriorityMuxModule_core 设不同参）。
// 被测语义：纯组合优先级选择——最高优先级的有效 sel 决定输出，全无效取兜底源。
// 激励：sel 位图按"稀疏 / 单热 / 全 0 / 全随机"混合，保证每一路都真的被选中过，
//   也保证兜底路被走到；各路源数据逐位随机。
// 覆盖闸（纯组合小模块最容易假绿）：每个变体都必须
//   (1) 有效比对次数 >= COV_MIN；
//   (2) **每一路** sel 单独胜出的次数 >= COV_MIN，兜底路命中次数也 >= COV_MIN
//       —— 只跑到一两条分支就报 errors=0 的 tb 在这里会被判 FAIL；
//   (3) 每一个输出位都被观察到过 1 和 0。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  int cov_fail = 0;
  always #5 clock = ~clock;

  // ---- PriorityMuxModule: 4 路 + 兜底 / 载荷 50 位 / 1 字段 ----
  logic [3:0] pm0_sel;
  logic [199:0] pm0_src;
  logic [49:0] pm0_dflt;
  wire  [49:0] g_pm0_res;
  wire  [49:0] i_pm0_res;
  logic [49:0] pm0_ones, pm0_zeros;
  int   pm0_checks, pm0_dflt_hit;
  int   pm0_way_hit [4];
  PriorityMuxModule u_g_pm0 (
    .s2_target_sel(pm0_sel[3]),
    .s1_target_sel(pm0_sel[2]),
    .s3_target_sel(pm0_sel[1]),
    .redirect_target_sel(pm0_sel[0]),
    .s2_target_src(pm0_src[199:150]),
    .s1_target_src(pm0_src[149:100]),
    .s3_target_src(pm0_src[99:50]),
    .redirect_target_src(pm0_src[49:0]),
    .stallPC_src(pm0_dflt[49:0]),
    .out_res(g_pm0_res[49:0])
  );
  PriorityMuxModule_xs u_i_pm0 (
    .s2_target_sel(pm0_sel[3]),
    .s1_target_sel(pm0_sel[2]),
    .s3_target_sel(pm0_sel[1]),
    .redirect_target_sel(pm0_sel[0]),
    .s2_target_src(pm0_src[199:150]),
    .s1_target_src(pm0_src[149:100]),
    .s3_target_src(pm0_src[99:50]),
    .redirect_target_src(pm0_src[49:0]),
    .stallPC_src(pm0_dflt[49:0]),
    .out_res(i_pm0_res[49:0])
  );

  // ---- PriorityMuxModule_4: 4 路 + 兜底 / 载荷 140 位 / 17 字段 ----
  logic [3:0] pm4_sel;
  logic [559:0] pm4_src;
  logic [139:0] pm4_dflt;
  wire  [139:0] g_pm4_res;
  wire  [139:0] i_pm4_res;
  logic [139:0] pm4_ones, pm4_zeros;
  int   pm4_checks, pm4_dflt_hit;
  int   pm4_way_hit [4];
  PriorityMuxModule_4 u_g_pm4 (
    .s2_FGH_sel(pm4_sel[3]),
    .s1_FGH_sel(pm4_sel[2]),
    .s3_FGH_sel(pm4_sel[1]),
    .redirect_FGHT_sel(pm4_sel[0]),
    .s2_FGH_src_hist_17_folded_hist(pm4_src[559:549]),
    .s2_FGH_src_hist_16_folded_hist(pm4_src[548:538]),
    .s2_FGH_src_hist_15_folded_hist(pm4_src[537:531]),
    .s2_FGH_src_hist_14_folded_hist(pm4_src[530:523]),
    .s2_FGH_src_hist_13_folded_hist(pm4_src[522:514]),
    .s2_FGH_src_hist_12_folded_hist(pm4_src[513:510]),
    .s2_FGH_src_hist_11_folded_hist(pm4_src[509:502]),
    .s2_FGH_src_hist_10_folded_hist(pm4_src[501:493]),
    .s2_FGH_src_hist_9_folded_hist(pm4_src[492:486]),
    .s2_FGH_src_hist_8_folded_hist(pm4_src[485:478]),
    .s2_FGH_src_hist_7_folded_hist(pm4_src[477:471]),
    .s2_FGH_src_hist_6_folded_hist(pm4_src[470:462]),
    .s2_FGH_src_hist_5_folded_hist(pm4_src[461:455]),
    .s2_FGH_src_hist_4_folded_hist(pm4_src[454:447]),
    .s2_FGH_src_hist_3_folded_hist(pm4_src[446:439]),
    .s2_FGH_src_hist_2_folded_hist(pm4_src[438:431]),
    .s2_FGH_src_hist_1_folded_hist(pm4_src[430:420]),
    .s1_FGH_src_hist_17_folded_hist(pm4_src[419:409]),
    .s1_FGH_src_hist_16_folded_hist(pm4_src[408:398]),
    .s1_FGH_src_hist_15_folded_hist(pm4_src[397:391]),
    .s1_FGH_src_hist_14_folded_hist(pm4_src[390:383]),
    .s1_FGH_src_hist_13_folded_hist(pm4_src[382:374]),
    .s1_FGH_src_hist_12_folded_hist(pm4_src[373:370]),
    .s1_FGH_src_hist_11_folded_hist(pm4_src[369:362]),
    .s1_FGH_src_hist_10_folded_hist(pm4_src[361:353]),
    .s1_FGH_src_hist_9_folded_hist(pm4_src[352:346]),
    .s1_FGH_src_hist_8_folded_hist(pm4_src[345:338]),
    .s1_FGH_src_hist_7_folded_hist(pm4_src[337:331]),
    .s1_FGH_src_hist_6_folded_hist(pm4_src[330:322]),
    .s1_FGH_src_hist_5_folded_hist(pm4_src[321:315]),
    .s1_FGH_src_hist_4_folded_hist(pm4_src[314:307]),
    .s1_FGH_src_hist_3_folded_hist(pm4_src[306:299]),
    .s1_FGH_src_hist_2_folded_hist(pm4_src[298:291]),
    .s1_FGH_src_hist_1_folded_hist(pm4_src[290:280]),
    .s3_FGH_src_hist_17_folded_hist(pm4_src[279:269]),
    .s3_FGH_src_hist_16_folded_hist(pm4_src[268:258]),
    .s3_FGH_src_hist_15_folded_hist(pm4_src[257:251]),
    .s3_FGH_src_hist_14_folded_hist(pm4_src[250:243]),
    .s3_FGH_src_hist_13_folded_hist(pm4_src[242:234]),
    .s3_FGH_src_hist_12_folded_hist(pm4_src[233:230]),
    .s3_FGH_src_hist_11_folded_hist(pm4_src[229:222]),
    .s3_FGH_src_hist_10_folded_hist(pm4_src[221:213]),
    .s3_FGH_src_hist_9_folded_hist(pm4_src[212:206]),
    .s3_FGH_src_hist_8_folded_hist(pm4_src[205:198]),
    .s3_FGH_src_hist_7_folded_hist(pm4_src[197:191]),
    .s3_FGH_src_hist_6_folded_hist(pm4_src[190:182]),
    .s3_FGH_src_hist_5_folded_hist(pm4_src[181:175]),
    .s3_FGH_src_hist_4_folded_hist(pm4_src[174:167]),
    .s3_FGH_src_hist_3_folded_hist(pm4_src[166:159]),
    .s3_FGH_src_hist_2_folded_hist(pm4_src[158:151]),
    .s3_FGH_src_hist_1_folded_hist(pm4_src[150:140]),
    .redirect_FGHT_src_hist_17_folded_hist(pm4_src[139:129]),
    .redirect_FGHT_src_hist_16_folded_hist(pm4_src[128:118]),
    .redirect_FGHT_src_hist_15_folded_hist(pm4_src[117:111]),
    .redirect_FGHT_src_hist_14_folded_hist(pm4_src[110:103]),
    .redirect_FGHT_src_hist_13_folded_hist(pm4_src[102:94]),
    .redirect_FGHT_src_hist_12_folded_hist(pm4_src[93:90]),
    .redirect_FGHT_src_hist_11_folded_hist(pm4_src[89:82]),
    .redirect_FGHT_src_hist_10_folded_hist(pm4_src[81:73]),
    .redirect_FGHT_src_hist_9_folded_hist(pm4_src[72:66]),
    .redirect_FGHT_src_hist_8_folded_hist(pm4_src[65:58]),
    .redirect_FGHT_src_hist_7_folded_hist(pm4_src[57:51]),
    .redirect_FGHT_src_hist_6_folded_hist(pm4_src[50:42]),
    .redirect_FGHT_src_hist_5_folded_hist(pm4_src[41:35]),
    .redirect_FGHT_src_hist_4_folded_hist(pm4_src[34:27]),
    .redirect_FGHT_src_hist_3_folded_hist(pm4_src[26:19]),
    .redirect_FGHT_src_hist_2_folded_hist(pm4_src[18:11]),
    .redirect_FGHT_src_hist_1_folded_hist(pm4_src[10:0]),
    .stallFGH_src_hist_17_folded_hist(pm4_dflt[139:129]),
    .stallFGH_src_hist_16_folded_hist(pm4_dflt[128:118]),
    .stallFGH_src_hist_15_folded_hist(pm4_dflt[117:111]),
    .stallFGH_src_hist_14_folded_hist(pm4_dflt[110:103]),
    .stallFGH_src_hist_13_folded_hist(pm4_dflt[102:94]),
    .stallFGH_src_hist_12_folded_hist(pm4_dflt[93:90]),
    .stallFGH_src_hist_11_folded_hist(pm4_dflt[89:82]),
    .stallFGH_src_hist_10_folded_hist(pm4_dflt[81:73]),
    .stallFGH_src_hist_9_folded_hist(pm4_dflt[72:66]),
    .stallFGH_src_hist_8_folded_hist(pm4_dflt[65:58]),
    .stallFGH_src_hist_7_folded_hist(pm4_dflt[57:51]),
    .stallFGH_src_hist_6_folded_hist(pm4_dflt[50:42]),
    .stallFGH_src_hist_5_folded_hist(pm4_dflt[41:35]),
    .stallFGH_src_hist_4_folded_hist(pm4_dflt[34:27]),
    .stallFGH_src_hist_3_folded_hist(pm4_dflt[26:19]),
    .stallFGH_src_hist_2_folded_hist(pm4_dflt[18:11]),
    .stallFGH_src_hist_1_folded_hist(pm4_dflt[10:0]),
    .out_res_hist_17_folded_hist(g_pm4_res[139:129]),
    .out_res_hist_16_folded_hist(g_pm4_res[128:118]),
    .out_res_hist_15_folded_hist(g_pm4_res[117:111]),
    .out_res_hist_14_folded_hist(g_pm4_res[110:103]),
    .out_res_hist_13_folded_hist(g_pm4_res[102:94]),
    .out_res_hist_12_folded_hist(g_pm4_res[93:90]),
    .out_res_hist_11_folded_hist(g_pm4_res[89:82]),
    .out_res_hist_10_folded_hist(g_pm4_res[81:73]),
    .out_res_hist_9_folded_hist(g_pm4_res[72:66]),
    .out_res_hist_8_folded_hist(g_pm4_res[65:58]),
    .out_res_hist_7_folded_hist(g_pm4_res[57:51]),
    .out_res_hist_6_folded_hist(g_pm4_res[50:42]),
    .out_res_hist_5_folded_hist(g_pm4_res[41:35]),
    .out_res_hist_4_folded_hist(g_pm4_res[34:27]),
    .out_res_hist_3_folded_hist(g_pm4_res[26:19]),
    .out_res_hist_2_folded_hist(g_pm4_res[18:11]),
    .out_res_hist_1_folded_hist(g_pm4_res[10:0])
  );
  PriorityMuxModule_4_xs u_i_pm4 (
    .s2_FGH_sel(pm4_sel[3]),
    .s1_FGH_sel(pm4_sel[2]),
    .s3_FGH_sel(pm4_sel[1]),
    .redirect_FGHT_sel(pm4_sel[0]),
    .s2_FGH_src_hist_17_folded_hist(pm4_src[559:549]),
    .s2_FGH_src_hist_16_folded_hist(pm4_src[548:538]),
    .s2_FGH_src_hist_15_folded_hist(pm4_src[537:531]),
    .s2_FGH_src_hist_14_folded_hist(pm4_src[530:523]),
    .s2_FGH_src_hist_13_folded_hist(pm4_src[522:514]),
    .s2_FGH_src_hist_12_folded_hist(pm4_src[513:510]),
    .s2_FGH_src_hist_11_folded_hist(pm4_src[509:502]),
    .s2_FGH_src_hist_10_folded_hist(pm4_src[501:493]),
    .s2_FGH_src_hist_9_folded_hist(pm4_src[492:486]),
    .s2_FGH_src_hist_8_folded_hist(pm4_src[485:478]),
    .s2_FGH_src_hist_7_folded_hist(pm4_src[477:471]),
    .s2_FGH_src_hist_6_folded_hist(pm4_src[470:462]),
    .s2_FGH_src_hist_5_folded_hist(pm4_src[461:455]),
    .s2_FGH_src_hist_4_folded_hist(pm4_src[454:447]),
    .s2_FGH_src_hist_3_folded_hist(pm4_src[446:439]),
    .s2_FGH_src_hist_2_folded_hist(pm4_src[438:431]),
    .s2_FGH_src_hist_1_folded_hist(pm4_src[430:420]),
    .s1_FGH_src_hist_17_folded_hist(pm4_src[419:409]),
    .s1_FGH_src_hist_16_folded_hist(pm4_src[408:398]),
    .s1_FGH_src_hist_15_folded_hist(pm4_src[397:391]),
    .s1_FGH_src_hist_14_folded_hist(pm4_src[390:383]),
    .s1_FGH_src_hist_13_folded_hist(pm4_src[382:374]),
    .s1_FGH_src_hist_12_folded_hist(pm4_src[373:370]),
    .s1_FGH_src_hist_11_folded_hist(pm4_src[369:362]),
    .s1_FGH_src_hist_10_folded_hist(pm4_src[361:353]),
    .s1_FGH_src_hist_9_folded_hist(pm4_src[352:346]),
    .s1_FGH_src_hist_8_folded_hist(pm4_src[345:338]),
    .s1_FGH_src_hist_7_folded_hist(pm4_src[337:331]),
    .s1_FGH_src_hist_6_folded_hist(pm4_src[330:322]),
    .s1_FGH_src_hist_5_folded_hist(pm4_src[321:315]),
    .s1_FGH_src_hist_4_folded_hist(pm4_src[314:307]),
    .s1_FGH_src_hist_3_folded_hist(pm4_src[306:299]),
    .s1_FGH_src_hist_2_folded_hist(pm4_src[298:291]),
    .s1_FGH_src_hist_1_folded_hist(pm4_src[290:280]),
    .s3_FGH_src_hist_17_folded_hist(pm4_src[279:269]),
    .s3_FGH_src_hist_16_folded_hist(pm4_src[268:258]),
    .s3_FGH_src_hist_15_folded_hist(pm4_src[257:251]),
    .s3_FGH_src_hist_14_folded_hist(pm4_src[250:243]),
    .s3_FGH_src_hist_13_folded_hist(pm4_src[242:234]),
    .s3_FGH_src_hist_12_folded_hist(pm4_src[233:230]),
    .s3_FGH_src_hist_11_folded_hist(pm4_src[229:222]),
    .s3_FGH_src_hist_10_folded_hist(pm4_src[221:213]),
    .s3_FGH_src_hist_9_folded_hist(pm4_src[212:206]),
    .s3_FGH_src_hist_8_folded_hist(pm4_src[205:198]),
    .s3_FGH_src_hist_7_folded_hist(pm4_src[197:191]),
    .s3_FGH_src_hist_6_folded_hist(pm4_src[190:182]),
    .s3_FGH_src_hist_5_folded_hist(pm4_src[181:175]),
    .s3_FGH_src_hist_4_folded_hist(pm4_src[174:167]),
    .s3_FGH_src_hist_3_folded_hist(pm4_src[166:159]),
    .s3_FGH_src_hist_2_folded_hist(pm4_src[158:151]),
    .s3_FGH_src_hist_1_folded_hist(pm4_src[150:140]),
    .redirect_FGHT_src_hist_17_folded_hist(pm4_src[139:129]),
    .redirect_FGHT_src_hist_16_folded_hist(pm4_src[128:118]),
    .redirect_FGHT_src_hist_15_folded_hist(pm4_src[117:111]),
    .redirect_FGHT_src_hist_14_folded_hist(pm4_src[110:103]),
    .redirect_FGHT_src_hist_13_folded_hist(pm4_src[102:94]),
    .redirect_FGHT_src_hist_12_folded_hist(pm4_src[93:90]),
    .redirect_FGHT_src_hist_11_folded_hist(pm4_src[89:82]),
    .redirect_FGHT_src_hist_10_folded_hist(pm4_src[81:73]),
    .redirect_FGHT_src_hist_9_folded_hist(pm4_src[72:66]),
    .redirect_FGHT_src_hist_8_folded_hist(pm4_src[65:58]),
    .redirect_FGHT_src_hist_7_folded_hist(pm4_src[57:51]),
    .redirect_FGHT_src_hist_6_folded_hist(pm4_src[50:42]),
    .redirect_FGHT_src_hist_5_folded_hist(pm4_src[41:35]),
    .redirect_FGHT_src_hist_4_folded_hist(pm4_src[34:27]),
    .redirect_FGHT_src_hist_3_folded_hist(pm4_src[26:19]),
    .redirect_FGHT_src_hist_2_folded_hist(pm4_src[18:11]),
    .redirect_FGHT_src_hist_1_folded_hist(pm4_src[10:0]),
    .stallFGH_src_hist_17_folded_hist(pm4_dflt[139:129]),
    .stallFGH_src_hist_16_folded_hist(pm4_dflt[128:118]),
    .stallFGH_src_hist_15_folded_hist(pm4_dflt[117:111]),
    .stallFGH_src_hist_14_folded_hist(pm4_dflt[110:103]),
    .stallFGH_src_hist_13_folded_hist(pm4_dflt[102:94]),
    .stallFGH_src_hist_12_folded_hist(pm4_dflt[93:90]),
    .stallFGH_src_hist_11_folded_hist(pm4_dflt[89:82]),
    .stallFGH_src_hist_10_folded_hist(pm4_dflt[81:73]),
    .stallFGH_src_hist_9_folded_hist(pm4_dflt[72:66]),
    .stallFGH_src_hist_8_folded_hist(pm4_dflt[65:58]),
    .stallFGH_src_hist_7_folded_hist(pm4_dflt[57:51]),
    .stallFGH_src_hist_6_folded_hist(pm4_dflt[50:42]),
    .stallFGH_src_hist_5_folded_hist(pm4_dflt[41:35]),
    .stallFGH_src_hist_4_folded_hist(pm4_dflt[34:27]),
    .stallFGH_src_hist_3_folded_hist(pm4_dflt[26:19]),
    .stallFGH_src_hist_2_folded_hist(pm4_dflt[18:11]),
    .stallFGH_src_hist_1_folded_hist(pm4_dflt[10:0]),
    .out_res_hist_17_folded_hist(i_pm4_res[139:129]),
    .out_res_hist_16_folded_hist(i_pm4_res[128:118]),
    .out_res_hist_15_folded_hist(i_pm4_res[117:111]),
    .out_res_hist_14_folded_hist(i_pm4_res[110:103]),
    .out_res_hist_13_folded_hist(i_pm4_res[102:94]),
    .out_res_hist_12_folded_hist(i_pm4_res[93:90]),
    .out_res_hist_11_folded_hist(i_pm4_res[89:82]),
    .out_res_hist_10_folded_hist(i_pm4_res[81:73]),
    .out_res_hist_9_folded_hist(i_pm4_res[72:66]),
    .out_res_hist_8_folded_hist(i_pm4_res[65:58]),
    .out_res_hist_7_folded_hist(i_pm4_res[57:51]),
    .out_res_hist_6_folded_hist(i_pm4_res[50:42]),
    .out_res_hist_5_folded_hist(i_pm4_res[41:35]),
    .out_res_hist_4_folded_hist(i_pm4_res[34:27]),
    .out_res_hist_3_folded_hist(i_pm4_res[26:19]),
    .out_res_hist_2_folded_hist(i_pm4_res[18:11]),
    .out_res_hist_1_folded_hist(i_pm4_res[10:0])
  );

  // ---- PriorityMuxModule_8: 4 路 + 兜底 / 载荷 9 位 / 2 字段 ----
  logic [3:0] pm8_sel;
  logic [35:0] pm8_src;
  logic [8:0] pm8_dflt;
  wire  [8:0] g_pm8_res;
  wire  [8:0] i_pm8_res;
  logic [8:0] pm8_ones, pm8_zeros;
  int   pm8_checks, pm8_dflt_hit;
  int   pm8_way_hit [4];
  PriorityMuxModule_8 u_g_pm8 (
    .s2_GHPtr_sel(pm8_sel[3]),
    .s1_GHPtr_sel(pm8_sel[2]),
    .s3_GHPtr_sel(pm8_sel[1]),
    .redirect_GHPtr_sel(pm8_sel[0]),
    .s2_GHPtr_src_flag(pm8_src[35]),
    .s2_GHPtr_src_value(pm8_src[34:27]),
    .s1_GHPtr_src_flag(pm8_src[26]),
    .s1_GHPtr_src_value(pm8_src[25:18]),
    .s3_GHPtr_src_flag(pm8_src[17]),
    .s3_GHPtr_src_value(pm8_src[16:9]),
    .redirect_GHPtr_src_flag(pm8_src[8]),
    .redirect_GHPtr_src_value(pm8_src[7:0]),
    .stallGHPtr_src_flag(pm8_dflt[8]),
    .stallGHPtr_src_value(pm8_dflt[7:0]),
    .out_res_flag(g_pm8_res[8]),
    .out_res_value(g_pm8_res[7:0])
  );
  PriorityMuxModule_8_xs u_i_pm8 (
    .s2_GHPtr_sel(pm8_sel[3]),
    .s1_GHPtr_sel(pm8_sel[2]),
    .s3_GHPtr_sel(pm8_sel[1]),
    .redirect_GHPtr_sel(pm8_sel[0]),
    .s2_GHPtr_src_flag(pm8_src[35]),
    .s2_GHPtr_src_value(pm8_src[34:27]),
    .s1_GHPtr_src_flag(pm8_src[26]),
    .s1_GHPtr_src_value(pm8_src[25:18]),
    .s3_GHPtr_src_flag(pm8_src[17]),
    .s3_GHPtr_src_value(pm8_src[16:9]),
    .redirect_GHPtr_src_flag(pm8_src[8]),
    .redirect_GHPtr_src_value(pm8_src[7:0]),
    .stallGHPtr_src_flag(pm8_dflt[8]),
    .stallGHPtr_src_value(pm8_dflt[7:0]),
    .out_res_flag(i_pm8_res[8]),
    .out_res_value(i_pm8_res[7:0])
  );

  // ---- PriorityMuxModule_12: 4 路 + 兜底 / 载荷 23 位 / 23 字段 ----
  logic [3:0] pm12_sel;
  logic [91:0] pm12_src;
  logic [22:0] pm12_dflt;
  wire  [22:0] g_pm12_res;
  wire  [22:0] i_pm12_res;
  logic [22:0] pm12_ones, pm12_zeros;
  int   pm12_checks, pm12_dflt_hit;
  int   pm12_way_hit [4];
  PriorityMuxModule_12 u_g_pm12 (
    .s2_AFHOB_sel(pm12_sel[3]),
    .s1_AFHOB_sel(pm12_sel[2]),
    .s3_AFHOB_sel(pm12_sel[1]),
    .redirect_AFHOB_sel(pm12_sel[0]),
    .s2_AFHOB_src_afhob_5_bits_0(pm12_src[91]),
    .s2_AFHOB_src_afhob_5_bits_1(pm12_src[90]),
    .s2_AFHOB_src_afhob_5_bits_2(pm12_src[89]),
    .s2_AFHOB_src_afhob_5_bits_3(pm12_src[88]),
    .s2_AFHOB_src_afhob_4_bits_0(pm12_src[87]),
    .s2_AFHOB_src_afhob_4_bits_1(pm12_src[86]),
    .s2_AFHOB_src_afhob_4_bits_2(pm12_src[85]),
    .s2_AFHOB_src_afhob_3_bits_0(pm12_src[84]),
    .s2_AFHOB_src_afhob_3_bits_1(pm12_src[83]),
    .s2_AFHOB_src_afhob_3_bits_2(pm12_src[82]),
    .s2_AFHOB_src_afhob_3_bits_3(pm12_src[81]),
    .s2_AFHOB_src_afhob_2_bits_0(pm12_src[80]),
    .s2_AFHOB_src_afhob_2_bits_1(pm12_src[79]),
    .s2_AFHOB_src_afhob_2_bits_2(pm12_src[78]),
    .s2_AFHOB_src_afhob_2_bits_3(pm12_src[77]),
    .s2_AFHOB_src_afhob_1_bits_0(pm12_src[76]),
    .s2_AFHOB_src_afhob_1_bits_1(pm12_src[75]),
    .s2_AFHOB_src_afhob_1_bits_2(pm12_src[74]),
    .s2_AFHOB_src_afhob_1_bits_3(pm12_src[73]),
    .s2_AFHOB_src_afhob_0_bits_0(pm12_src[72]),
    .s2_AFHOB_src_afhob_0_bits_1(pm12_src[71]),
    .s2_AFHOB_src_afhob_0_bits_2(pm12_src[70]),
    .s2_AFHOB_src_afhob_0_bits_3(pm12_src[69]),
    .s1_AFHOB_src_afhob_5_bits_0(pm12_src[68]),
    .s1_AFHOB_src_afhob_5_bits_1(pm12_src[67]),
    .s1_AFHOB_src_afhob_5_bits_2(pm12_src[66]),
    .s1_AFHOB_src_afhob_5_bits_3(pm12_src[65]),
    .s1_AFHOB_src_afhob_4_bits_0(pm12_src[64]),
    .s1_AFHOB_src_afhob_4_bits_1(pm12_src[63]),
    .s1_AFHOB_src_afhob_4_bits_2(pm12_src[62]),
    .s1_AFHOB_src_afhob_3_bits_0(pm12_src[61]),
    .s1_AFHOB_src_afhob_3_bits_1(pm12_src[60]),
    .s1_AFHOB_src_afhob_3_bits_2(pm12_src[59]),
    .s1_AFHOB_src_afhob_3_bits_3(pm12_src[58]),
    .s1_AFHOB_src_afhob_2_bits_0(pm12_src[57]),
    .s1_AFHOB_src_afhob_2_bits_1(pm12_src[56]),
    .s1_AFHOB_src_afhob_2_bits_2(pm12_src[55]),
    .s1_AFHOB_src_afhob_2_bits_3(pm12_src[54]),
    .s1_AFHOB_src_afhob_1_bits_0(pm12_src[53]),
    .s1_AFHOB_src_afhob_1_bits_1(pm12_src[52]),
    .s1_AFHOB_src_afhob_1_bits_2(pm12_src[51]),
    .s1_AFHOB_src_afhob_1_bits_3(pm12_src[50]),
    .s1_AFHOB_src_afhob_0_bits_0(pm12_src[49]),
    .s1_AFHOB_src_afhob_0_bits_1(pm12_src[48]),
    .s1_AFHOB_src_afhob_0_bits_2(pm12_src[47]),
    .s1_AFHOB_src_afhob_0_bits_3(pm12_src[46]),
    .s3_AFHOB_src_afhob_5_bits_0(pm12_src[45]),
    .s3_AFHOB_src_afhob_5_bits_1(pm12_src[44]),
    .s3_AFHOB_src_afhob_5_bits_2(pm12_src[43]),
    .s3_AFHOB_src_afhob_5_bits_3(pm12_src[42]),
    .s3_AFHOB_src_afhob_4_bits_0(pm12_src[41]),
    .s3_AFHOB_src_afhob_4_bits_1(pm12_src[40]),
    .s3_AFHOB_src_afhob_4_bits_2(pm12_src[39]),
    .s3_AFHOB_src_afhob_3_bits_0(pm12_src[38]),
    .s3_AFHOB_src_afhob_3_bits_1(pm12_src[37]),
    .s3_AFHOB_src_afhob_3_bits_2(pm12_src[36]),
    .s3_AFHOB_src_afhob_3_bits_3(pm12_src[35]),
    .s3_AFHOB_src_afhob_2_bits_0(pm12_src[34]),
    .s3_AFHOB_src_afhob_2_bits_1(pm12_src[33]),
    .s3_AFHOB_src_afhob_2_bits_2(pm12_src[32]),
    .s3_AFHOB_src_afhob_2_bits_3(pm12_src[31]),
    .s3_AFHOB_src_afhob_1_bits_0(pm12_src[30]),
    .s3_AFHOB_src_afhob_1_bits_1(pm12_src[29]),
    .s3_AFHOB_src_afhob_1_bits_2(pm12_src[28]),
    .s3_AFHOB_src_afhob_1_bits_3(pm12_src[27]),
    .s3_AFHOB_src_afhob_0_bits_0(pm12_src[26]),
    .s3_AFHOB_src_afhob_0_bits_1(pm12_src[25]),
    .s3_AFHOB_src_afhob_0_bits_2(pm12_src[24]),
    .s3_AFHOB_src_afhob_0_bits_3(pm12_src[23]),
    .redirect_AFHOB_src_afhob_5_bits_0(pm12_src[22]),
    .redirect_AFHOB_src_afhob_5_bits_1(pm12_src[21]),
    .redirect_AFHOB_src_afhob_5_bits_2(pm12_src[20]),
    .redirect_AFHOB_src_afhob_5_bits_3(pm12_src[19]),
    .redirect_AFHOB_src_afhob_4_bits_0(pm12_src[18]),
    .redirect_AFHOB_src_afhob_4_bits_1(pm12_src[17]),
    .redirect_AFHOB_src_afhob_4_bits_2(pm12_src[16]),
    .redirect_AFHOB_src_afhob_3_bits_0(pm12_src[15]),
    .redirect_AFHOB_src_afhob_3_bits_1(pm12_src[14]),
    .redirect_AFHOB_src_afhob_3_bits_2(pm12_src[13]),
    .redirect_AFHOB_src_afhob_3_bits_3(pm12_src[12]),
    .redirect_AFHOB_src_afhob_2_bits_0(pm12_src[11]),
    .redirect_AFHOB_src_afhob_2_bits_1(pm12_src[10]),
    .redirect_AFHOB_src_afhob_2_bits_2(pm12_src[9]),
    .redirect_AFHOB_src_afhob_2_bits_3(pm12_src[8]),
    .redirect_AFHOB_src_afhob_1_bits_0(pm12_src[7]),
    .redirect_AFHOB_src_afhob_1_bits_1(pm12_src[6]),
    .redirect_AFHOB_src_afhob_1_bits_2(pm12_src[5]),
    .redirect_AFHOB_src_afhob_1_bits_3(pm12_src[4]),
    .redirect_AFHOB_src_afhob_0_bits_0(pm12_src[3]),
    .redirect_AFHOB_src_afhob_0_bits_1(pm12_src[2]),
    .redirect_AFHOB_src_afhob_0_bits_2(pm12_src[1]),
    .redirect_AFHOB_src_afhob_0_bits_3(pm12_src[0]),
    .stallAFHOB_src_afhob_5_bits_0(pm12_dflt[22]),
    .stallAFHOB_src_afhob_5_bits_1(pm12_dflt[21]),
    .stallAFHOB_src_afhob_5_bits_2(pm12_dflt[20]),
    .stallAFHOB_src_afhob_5_bits_3(pm12_dflt[19]),
    .stallAFHOB_src_afhob_4_bits_0(pm12_dflt[18]),
    .stallAFHOB_src_afhob_4_bits_1(pm12_dflt[17]),
    .stallAFHOB_src_afhob_4_bits_2(pm12_dflt[16]),
    .stallAFHOB_src_afhob_3_bits_0(pm12_dflt[15]),
    .stallAFHOB_src_afhob_3_bits_1(pm12_dflt[14]),
    .stallAFHOB_src_afhob_3_bits_2(pm12_dflt[13]),
    .stallAFHOB_src_afhob_3_bits_3(pm12_dflt[12]),
    .stallAFHOB_src_afhob_2_bits_0(pm12_dflt[11]),
    .stallAFHOB_src_afhob_2_bits_1(pm12_dflt[10]),
    .stallAFHOB_src_afhob_2_bits_2(pm12_dflt[9]),
    .stallAFHOB_src_afhob_2_bits_3(pm12_dflt[8]),
    .stallAFHOB_src_afhob_1_bits_0(pm12_dflt[7]),
    .stallAFHOB_src_afhob_1_bits_1(pm12_dflt[6]),
    .stallAFHOB_src_afhob_1_bits_2(pm12_dflt[5]),
    .stallAFHOB_src_afhob_1_bits_3(pm12_dflt[4]),
    .stallAFHOB_src_afhob_0_bits_0(pm12_dflt[3]),
    .stallAFHOB_src_afhob_0_bits_1(pm12_dflt[2]),
    .stallAFHOB_src_afhob_0_bits_2(pm12_dflt[1]),
    .stallAFHOB_src_afhob_0_bits_3(pm12_dflt[0]),
    .out_res_afhob_5_bits_0(g_pm12_res[22]),
    .out_res_afhob_5_bits_1(g_pm12_res[21]),
    .out_res_afhob_5_bits_2(g_pm12_res[20]),
    .out_res_afhob_5_bits_3(g_pm12_res[19]),
    .out_res_afhob_4_bits_0(g_pm12_res[18]),
    .out_res_afhob_4_bits_1(g_pm12_res[17]),
    .out_res_afhob_4_bits_2(g_pm12_res[16]),
    .out_res_afhob_3_bits_0(g_pm12_res[15]),
    .out_res_afhob_3_bits_1(g_pm12_res[14]),
    .out_res_afhob_3_bits_2(g_pm12_res[13]),
    .out_res_afhob_3_bits_3(g_pm12_res[12]),
    .out_res_afhob_2_bits_0(g_pm12_res[11]),
    .out_res_afhob_2_bits_1(g_pm12_res[10]),
    .out_res_afhob_2_bits_2(g_pm12_res[9]),
    .out_res_afhob_2_bits_3(g_pm12_res[8]),
    .out_res_afhob_1_bits_0(g_pm12_res[7]),
    .out_res_afhob_1_bits_1(g_pm12_res[6]),
    .out_res_afhob_1_bits_2(g_pm12_res[5]),
    .out_res_afhob_1_bits_3(g_pm12_res[4]),
    .out_res_afhob_0_bits_0(g_pm12_res[3]),
    .out_res_afhob_0_bits_1(g_pm12_res[2]),
    .out_res_afhob_0_bits_2(g_pm12_res[1]),
    .out_res_afhob_0_bits_3(g_pm12_res[0])
  );
  PriorityMuxModule_12_xs u_i_pm12 (
    .s2_AFHOB_sel(pm12_sel[3]),
    .s1_AFHOB_sel(pm12_sel[2]),
    .s3_AFHOB_sel(pm12_sel[1]),
    .redirect_AFHOB_sel(pm12_sel[0]),
    .s2_AFHOB_src_afhob_5_bits_0(pm12_src[91]),
    .s2_AFHOB_src_afhob_5_bits_1(pm12_src[90]),
    .s2_AFHOB_src_afhob_5_bits_2(pm12_src[89]),
    .s2_AFHOB_src_afhob_5_bits_3(pm12_src[88]),
    .s2_AFHOB_src_afhob_4_bits_0(pm12_src[87]),
    .s2_AFHOB_src_afhob_4_bits_1(pm12_src[86]),
    .s2_AFHOB_src_afhob_4_bits_2(pm12_src[85]),
    .s2_AFHOB_src_afhob_3_bits_0(pm12_src[84]),
    .s2_AFHOB_src_afhob_3_bits_1(pm12_src[83]),
    .s2_AFHOB_src_afhob_3_bits_2(pm12_src[82]),
    .s2_AFHOB_src_afhob_3_bits_3(pm12_src[81]),
    .s2_AFHOB_src_afhob_2_bits_0(pm12_src[80]),
    .s2_AFHOB_src_afhob_2_bits_1(pm12_src[79]),
    .s2_AFHOB_src_afhob_2_bits_2(pm12_src[78]),
    .s2_AFHOB_src_afhob_2_bits_3(pm12_src[77]),
    .s2_AFHOB_src_afhob_1_bits_0(pm12_src[76]),
    .s2_AFHOB_src_afhob_1_bits_1(pm12_src[75]),
    .s2_AFHOB_src_afhob_1_bits_2(pm12_src[74]),
    .s2_AFHOB_src_afhob_1_bits_3(pm12_src[73]),
    .s2_AFHOB_src_afhob_0_bits_0(pm12_src[72]),
    .s2_AFHOB_src_afhob_0_bits_1(pm12_src[71]),
    .s2_AFHOB_src_afhob_0_bits_2(pm12_src[70]),
    .s2_AFHOB_src_afhob_0_bits_3(pm12_src[69]),
    .s1_AFHOB_src_afhob_5_bits_0(pm12_src[68]),
    .s1_AFHOB_src_afhob_5_bits_1(pm12_src[67]),
    .s1_AFHOB_src_afhob_5_bits_2(pm12_src[66]),
    .s1_AFHOB_src_afhob_5_bits_3(pm12_src[65]),
    .s1_AFHOB_src_afhob_4_bits_0(pm12_src[64]),
    .s1_AFHOB_src_afhob_4_bits_1(pm12_src[63]),
    .s1_AFHOB_src_afhob_4_bits_2(pm12_src[62]),
    .s1_AFHOB_src_afhob_3_bits_0(pm12_src[61]),
    .s1_AFHOB_src_afhob_3_bits_1(pm12_src[60]),
    .s1_AFHOB_src_afhob_3_bits_2(pm12_src[59]),
    .s1_AFHOB_src_afhob_3_bits_3(pm12_src[58]),
    .s1_AFHOB_src_afhob_2_bits_0(pm12_src[57]),
    .s1_AFHOB_src_afhob_2_bits_1(pm12_src[56]),
    .s1_AFHOB_src_afhob_2_bits_2(pm12_src[55]),
    .s1_AFHOB_src_afhob_2_bits_3(pm12_src[54]),
    .s1_AFHOB_src_afhob_1_bits_0(pm12_src[53]),
    .s1_AFHOB_src_afhob_1_bits_1(pm12_src[52]),
    .s1_AFHOB_src_afhob_1_bits_2(pm12_src[51]),
    .s1_AFHOB_src_afhob_1_bits_3(pm12_src[50]),
    .s1_AFHOB_src_afhob_0_bits_0(pm12_src[49]),
    .s1_AFHOB_src_afhob_0_bits_1(pm12_src[48]),
    .s1_AFHOB_src_afhob_0_bits_2(pm12_src[47]),
    .s1_AFHOB_src_afhob_0_bits_3(pm12_src[46]),
    .s3_AFHOB_src_afhob_5_bits_0(pm12_src[45]),
    .s3_AFHOB_src_afhob_5_bits_1(pm12_src[44]),
    .s3_AFHOB_src_afhob_5_bits_2(pm12_src[43]),
    .s3_AFHOB_src_afhob_5_bits_3(pm12_src[42]),
    .s3_AFHOB_src_afhob_4_bits_0(pm12_src[41]),
    .s3_AFHOB_src_afhob_4_bits_1(pm12_src[40]),
    .s3_AFHOB_src_afhob_4_bits_2(pm12_src[39]),
    .s3_AFHOB_src_afhob_3_bits_0(pm12_src[38]),
    .s3_AFHOB_src_afhob_3_bits_1(pm12_src[37]),
    .s3_AFHOB_src_afhob_3_bits_2(pm12_src[36]),
    .s3_AFHOB_src_afhob_3_bits_3(pm12_src[35]),
    .s3_AFHOB_src_afhob_2_bits_0(pm12_src[34]),
    .s3_AFHOB_src_afhob_2_bits_1(pm12_src[33]),
    .s3_AFHOB_src_afhob_2_bits_2(pm12_src[32]),
    .s3_AFHOB_src_afhob_2_bits_3(pm12_src[31]),
    .s3_AFHOB_src_afhob_1_bits_0(pm12_src[30]),
    .s3_AFHOB_src_afhob_1_bits_1(pm12_src[29]),
    .s3_AFHOB_src_afhob_1_bits_2(pm12_src[28]),
    .s3_AFHOB_src_afhob_1_bits_3(pm12_src[27]),
    .s3_AFHOB_src_afhob_0_bits_0(pm12_src[26]),
    .s3_AFHOB_src_afhob_0_bits_1(pm12_src[25]),
    .s3_AFHOB_src_afhob_0_bits_2(pm12_src[24]),
    .s3_AFHOB_src_afhob_0_bits_3(pm12_src[23]),
    .redirect_AFHOB_src_afhob_5_bits_0(pm12_src[22]),
    .redirect_AFHOB_src_afhob_5_bits_1(pm12_src[21]),
    .redirect_AFHOB_src_afhob_5_bits_2(pm12_src[20]),
    .redirect_AFHOB_src_afhob_5_bits_3(pm12_src[19]),
    .redirect_AFHOB_src_afhob_4_bits_0(pm12_src[18]),
    .redirect_AFHOB_src_afhob_4_bits_1(pm12_src[17]),
    .redirect_AFHOB_src_afhob_4_bits_2(pm12_src[16]),
    .redirect_AFHOB_src_afhob_3_bits_0(pm12_src[15]),
    .redirect_AFHOB_src_afhob_3_bits_1(pm12_src[14]),
    .redirect_AFHOB_src_afhob_3_bits_2(pm12_src[13]),
    .redirect_AFHOB_src_afhob_3_bits_3(pm12_src[12]),
    .redirect_AFHOB_src_afhob_2_bits_0(pm12_src[11]),
    .redirect_AFHOB_src_afhob_2_bits_1(pm12_src[10]),
    .redirect_AFHOB_src_afhob_2_bits_2(pm12_src[9]),
    .redirect_AFHOB_src_afhob_2_bits_3(pm12_src[8]),
    .redirect_AFHOB_src_afhob_1_bits_0(pm12_src[7]),
    .redirect_AFHOB_src_afhob_1_bits_1(pm12_src[6]),
    .redirect_AFHOB_src_afhob_1_bits_2(pm12_src[5]),
    .redirect_AFHOB_src_afhob_1_bits_3(pm12_src[4]),
    .redirect_AFHOB_src_afhob_0_bits_0(pm12_src[3]),
    .redirect_AFHOB_src_afhob_0_bits_1(pm12_src[2]),
    .redirect_AFHOB_src_afhob_0_bits_2(pm12_src[1]),
    .redirect_AFHOB_src_afhob_0_bits_3(pm12_src[0]),
    .stallAFHOB_src_afhob_5_bits_0(pm12_dflt[22]),
    .stallAFHOB_src_afhob_5_bits_1(pm12_dflt[21]),
    .stallAFHOB_src_afhob_5_bits_2(pm12_dflt[20]),
    .stallAFHOB_src_afhob_5_bits_3(pm12_dflt[19]),
    .stallAFHOB_src_afhob_4_bits_0(pm12_dflt[18]),
    .stallAFHOB_src_afhob_4_bits_1(pm12_dflt[17]),
    .stallAFHOB_src_afhob_4_bits_2(pm12_dflt[16]),
    .stallAFHOB_src_afhob_3_bits_0(pm12_dflt[15]),
    .stallAFHOB_src_afhob_3_bits_1(pm12_dflt[14]),
    .stallAFHOB_src_afhob_3_bits_2(pm12_dflt[13]),
    .stallAFHOB_src_afhob_3_bits_3(pm12_dflt[12]),
    .stallAFHOB_src_afhob_2_bits_0(pm12_dflt[11]),
    .stallAFHOB_src_afhob_2_bits_1(pm12_dflt[10]),
    .stallAFHOB_src_afhob_2_bits_2(pm12_dflt[9]),
    .stallAFHOB_src_afhob_2_bits_3(pm12_dflt[8]),
    .stallAFHOB_src_afhob_1_bits_0(pm12_dflt[7]),
    .stallAFHOB_src_afhob_1_bits_1(pm12_dflt[6]),
    .stallAFHOB_src_afhob_1_bits_2(pm12_dflt[5]),
    .stallAFHOB_src_afhob_1_bits_3(pm12_dflt[4]),
    .stallAFHOB_src_afhob_0_bits_0(pm12_dflt[3]),
    .stallAFHOB_src_afhob_0_bits_1(pm12_dflt[2]),
    .stallAFHOB_src_afhob_0_bits_2(pm12_dflt[1]),
    .stallAFHOB_src_afhob_0_bits_3(pm12_dflt[0]),
    .out_res_afhob_5_bits_0(i_pm12_res[22]),
    .out_res_afhob_5_bits_1(i_pm12_res[21]),
    .out_res_afhob_5_bits_2(i_pm12_res[20]),
    .out_res_afhob_5_bits_3(i_pm12_res[19]),
    .out_res_afhob_4_bits_0(i_pm12_res[18]),
    .out_res_afhob_4_bits_1(i_pm12_res[17]),
    .out_res_afhob_4_bits_2(i_pm12_res[16]),
    .out_res_afhob_3_bits_0(i_pm12_res[15]),
    .out_res_afhob_3_bits_1(i_pm12_res[14]),
    .out_res_afhob_3_bits_2(i_pm12_res[13]),
    .out_res_afhob_3_bits_3(i_pm12_res[12]),
    .out_res_afhob_2_bits_0(i_pm12_res[11]),
    .out_res_afhob_2_bits_1(i_pm12_res[10]),
    .out_res_afhob_2_bits_2(i_pm12_res[9]),
    .out_res_afhob_2_bits_3(i_pm12_res[8]),
    .out_res_afhob_1_bits_0(i_pm12_res[7]),
    .out_res_afhob_1_bits_1(i_pm12_res[6]),
    .out_res_afhob_1_bits_2(i_pm12_res[5]),
    .out_res_afhob_1_bits_3(i_pm12_res[4]),
    .out_res_afhob_0_bits_0(i_pm12_res[3]),
    .out_res_afhob_0_bits_1(i_pm12_res[2]),
    .out_res_afhob_0_bits_2(i_pm12_res[1]),
    .out_res_afhob_0_bits_3(i_pm12_res[0])
  );

  // ---- PriorityMuxModule_16: 4 路 + 兜底 / 载荷 3 位 / 1 字段 ----
  logic [3:0] pm16_sel;
  logic [11:0] pm16_src;
  logic [2:0] pm16_dflt;
  wire  [2:0] g_pm16_res;
  wire  [2:0] i_pm16_res;
  logic [2:0] pm16_ones, pm16_zeros;
  int   pm16_checks, pm16_dflt_hit;
  int   pm16_way_hit [4];
  PriorityMuxModule_16 u_g_pm16 (
    .s2_BrNumOH_sel(pm16_sel[3]),
    .s1_BrNumOH_sel(pm16_sel[2]),
    .s3_BrNumOH_sel(pm16_sel[1]),
    .redirect_BrNumOH_sel(pm16_sel[0]),
    .s2_BrNumOH_src(pm16_src[11:9]),
    .s1_BrNumOH_src(pm16_src[8:6]),
    .s3_BrNumOH_src(pm16_src[5:3]),
    .redirect_BrNumOH_src(pm16_src[2:0]),
    .stallBrNumOH_src(pm16_dflt[2:0]),
    .out_res(g_pm16_res[2:0])
  );
  PriorityMuxModule_16_xs u_i_pm16 (
    .s2_BrNumOH_sel(pm16_sel[3]),
    .s1_BrNumOH_sel(pm16_sel[2]),
    .s3_BrNumOH_sel(pm16_sel[1]),
    .redirect_BrNumOH_sel(pm16_sel[0]),
    .s2_BrNumOH_src(pm16_src[11:9]),
    .s1_BrNumOH_src(pm16_src[8:6]),
    .s3_BrNumOH_src(pm16_src[5:3]),
    .redirect_BrNumOH_src(pm16_src[2:0]),
    .stallBrNumOH_src(pm16_dflt[2:0]),
    .out_res(i_pm16_res[2:0])
  );

  // ---- PriorityMuxModule_20: 3 路 + 兜底 / 载荷 1 位 / 1 字段 ----
  logic [2:0] pm20_sel;
  logic [2:0] pm20_src;
  logic [0:0] pm20_dflt;
  wire  [0:0] g_pm20_res;
  wire  [0:0] i_pm20_res;
  logic [0:0] pm20_ones, pm20_zeros;
  int   pm20_checks, pm20_dflt_hit;
  int   pm20_way_hit [3];
  PriorityMuxModule_20 u_g_pm20 (
    .s2_new_bit_0_sel(pm20_sel[2]),
    .s1_new_bit_0_sel(pm20_sel[1]),
    .s3_new_bit_0_sel(pm20_sel[0]),
    .s2_new_bit_0_src(pm20_src[2]),
    .s1_new_bit_0_src(pm20_src[1]),
    .s3_new_bit_0_src(pm20_src[0]),
    .redirect_new_bit_0_src(pm20_dflt[0]),
    .out_res(g_pm20_res[0])
  );
  PriorityMuxModule_20_xs u_i_pm20 (
    .s2_new_bit_0_sel(pm20_sel[2]),
    .s1_new_bit_0_sel(pm20_sel[1]),
    .s3_new_bit_0_sel(pm20_sel[0]),
    .s2_new_bit_0_src(pm20_src[2]),
    .s1_new_bit_0_src(pm20_src[1]),
    .s3_new_bit_0_src(pm20_src[0]),
    .redirect_new_bit_0_src(pm20_dflt[0]),
    .out_res(i_pm20_res[0])
  );


  // sel 位图：全 0（走兜底）/ 单热（逐路胜出）/ 稀疏 / 全随机 四种混合
  function automatic int unsigned pick_sel(int unsigned nw);
    int unsigned v;
    case ($urandom_range(0, 3))
      0: v = 0;
      1: v = 1 << $urandom_range(0, nw - 1);
      2: v = $urandom & $urandom;
      default: v = $urandom;
    endcase
    return v & ((1 << nw) - 1);
  endfunction

  task automatic drive_random_inputs();
    pm0_sel = 4'(pick_sel(4));
    for (int b = 0; b < 200; b++) pm0_src[b]  = 1'($urandom);
    for (int b = 0; b < 50; b++)    pm0_dflt[b] = 1'($urandom);
    pm4_sel = 4'(pick_sel(4));
    for (int b = 0; b < 560; b++) pm4_src[b]  = 1'($urandom);
    for (int b = 0; b < 140; b++)    pm4_dflt[b] = 1'($urandom);
    pm8_sel = 4'(pick_sel(4));
    for (int b = 0; b < 36; b++) pm8_src[b]  = 1'($urandom);
    for (int b = 0; b < 9; b++)    pm8_dflt[b] = 1'($urandom);
    pm12_sel = 4'(pick_sel(4));
    for (int b = 0; b < 92; b++) pm12_src[b]  = 1'($urandom);
    for (int b = 0; b < 23; b++)    pm12_dflt[b] = 1'($urandom);
    pm16_sel = 4'(pick_sel(4));
    for (int b = 0; b < 12; b++) pm16_src[b]  = 1'($urandom);
    for (int b = 0; b < 3; b++)    pm16_dflt[b] = 1'($urandom);
    pm20_sel = 3'(pick_sel(3));
    for (int b = 0; b < 3; b++) pm20_src[b]  = 1'($urandom);
    for (int b = 0; b < 1; b++)    pm20_dflt[b] = 1'($urandom);
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_pm0_res)) begin
      checks++; pm0_checks++;
      pm0_ones  |= g_pm0_res;
      pm0_zeros |= ~g_pm0_res;
      if (pm0_sel == '0) pm0_dflt_hit++;
      else for (int w = 4 - 1; w >= 0; w--)
        if (pm0_sel[w]) begin pm0_way_hit[w]++; break; end
      if (g_pm0_res !== i_pm0_res) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PriorityMuxModule sel=%0b g=%0h i=%0h",
                   $time, pm0_sel, g_pm0_res, i_pm0_res);
      end
    end
    if (!$isunknown(g_pm4_res)) begin
      checks++; pm4_checks++;
      pm4_ones  |= g_pm4_res;
      pm4_zeros |= ~g_pm4_res;
      if (pm4_sel == '0) pm4_dflt_hit++;
      else for (int w = 4 - 1; w >= 0; w--)
        if (pm4_sel[w]) begin pm4_way_hit[w]++; break; end
      if (g_pm4_res !== i_pm4_res) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PriorityMuxModule_4 sel=%0b g=%0h i=%0h",
                   $time, pm4_sel, g_pm4_res, i_pm4_res);
      end
    end
    if (!$isunknown(g_pm8_res)) begin
      checks++; pm8_checks++;
      pm8_ones  |= g_pm8_res;
      pm8_zeros |= ~g_pm8_res;
      if (pm8_sel == '0) pm8_dflt_hit++;
      else for (int w = 4 - 1; w >= 0; w--)
        if (pm8_sel[w]) begin pm8_way_hit[w]++; break; end
      if (g_pm8_res !== i_pm8_res) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PriorityMuxModule_8 sel=%0b g=%0h i=%0h",
                   $time, pm8_sel, g_pm8_res, i_pm8_res);
      end
    end
    if (!$isunknown(g_pm12_res)) begin
      checks++; pm12_checks++;
      pm12_ones  |= g_pm12_res;
      pm12_zeros |= ~g_pm12_res;
      if (pm12_sel == '0) pm12_dflt_hit++;
      else for (int w = 4 - 1; w >= 0; w--)
        if (pm12_sel[w]) begin pm12_way_hit[w]++; break; end
      if (g_pm12_res !== i_pm12_res) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PriorityMuxModule_12 sel=%0b g=%0h i=%0h",
                   $time, pm12_sel, g_pm12_res, i_pm12_res);
      end
    end
    if (!$isunknown(g_pm16_res)) begin
      checks++; pm16_checks++;
      pm16_ones  |= g_pm16_res;
      pm16_zeros |= ~g_pm16_res;
      if (pm16_sel == '0) pm16_dflt_hit++;
      else for (int w = 4 - 1; w >= 0; w--)
        if (pm16_sel[w]) begin pm16_way_hit[w]++; break; end
      if (g_pm16_res !== i_pm16_res) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PriorityMuxModule_16 sel=%0b g=%0h i=%0h",
                   $time, pm16_sel, g_pm16_res, i_pm16_res);
      end
    end
    if (!$isunknown(g_pm20_res)) begin
      checks++; pm20_checks++;
      pm20_ones  |= g_pm20_res;
      pm20_zeros |= ~g_pm20_res;
      if (pm20_sel == '0) pm20_dflt_hit++;
      else for (int w = 3 - 1; w >= 0; w--)
        if (pm20_sel[w]) begin pm20_way_hit[w]++; break; end
      if (g_pm20_res !== i_pm20_res) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PriorityMuxModule_20 sel=%0b g=%0h i=%0h",
                   $time, pm20_sel, g_pm20_res, i_pm20_res);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    pm0_sel = '0; pm0_src = '0; pm0_dflt = '0; pm0_ones = '0; pm0_zeros = '0; pm0_checks = 0; pm0_dflt_hit = 0;
    for (int w = 0; w < 4; w++) pm0_way_hit[w] = 0;
    pm4_sel = '0; pm4_src = '0; pm4_dflt = '0; pm4_ones = '0; pm4_zeros = '0; pm4_checks = 0; pm4_dflt_hit = 0;
    for (int w = 0; w < 4; w++) pm4_way_hit[w] = 0;
    pm8_sel = '0; pm8_src = '0; pm8_dflt = '0; pm8_ones = '0; pm8_zeros = '0; pm8_checks = 0; pm8_dflt_hit = 0;
    for (int w = 0; w < 4; w++) pm8_way_hit[w] = 0;
    pm12_sel = '0; pm12_src = '0; pm12_dflt = '0; pm12_ones = '0; pm12_zeros = '0; pm12_checks = 0; pm12_dflt_hit = 0;
    for (int w = 0; w < 4; w++) pm12_way_hit[w] = 0;
    pm16_sel = '0; pm16_src = '0; pm16_dflt = '0; pm16_ones = '0; pm16_zeros = '0; pm16_checks = 0; pm16_dflt_hit = 0;
    for (int w = 0; w < 4; w++) pm16_way_hit[w] = 0;
    pm20_sel = '0; pm20_src = '0; pm20_dflt = '0; pm20_ones = '0; pm20_zeros = '0; pm20_checks = 0; pm20_dflt_hit = 0;
    for (int w = 0; w < 3; w++) pm20_way_hit[w] = 0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("PriorityMuxModule family checks=%0d errors=%0d", checks, errors);
    $write("  PriorityMuxModule: checks=%0d dflt_hit=%0d way_hit=",
           pm0_checks, pm0_dflt_hit);
    for (int w = 4 - 1; w >= 0; w--) $write("%0d ", pm0_way_hit[w]);
    $display("ones=%0d/50 zeros=%0d/50", $countones(pm0_ones), $countones(pm0_zeros));
    if (pm0_checks < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule 有效比对只有 %0d 次", pm0_checks); cov_fail++;
    end
    if (pm0_dflt_hit < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule 兜底路只命中 %0d 次", pm0_dflt_hit); cov_fail++;
    end
    for (int w = 0; w < 4; w++)
      if (pm0_way_hit[w] < COV_MIN) begin
        $display("COVERAGE FAIL: PriorityMuxModule 第 %0d 路只胜出 %0d 次", 4-1-w, pm0_way_hit[w]);
        cov_fail++;
      end
    if (!(&pm0_ones) || !(&pm0_zeros)) begin
      $display("COVERAGE FAIL: PriorityMuxModule 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    $write("  PriorityMuxModule_4: checks=%0d dflt_hit=%0d way_hit=",
           pm4_checks, pm4_dflt_hit);
    for (int w = 4 - 1; w >= 0; w--) $write("%0d ", pm4_way_hit[w]);
    $display("ones=%0d/140 zeros=%0d/140", $countones(pm4_ones), $countones(pm4_zeros));
    if (pm4_checks < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_4 有效比对只有 %0d 次", pm4_checks); cov_fail++;
    end
    if (pm4_dflt_hit < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_4 兜底路只命中 %0d 次", pm4_dflt_hit); cov_fail++;
    end
    for (int w = 0; w < 4; w++)
      if (pm4_way_hit[w] < COV_MIN) begin
        $display("COVERAGE FAIL: PriorityMuxModule_4 第 %0d 路只胜出 %0d 次", 4-1-w, pm4_way_hit[w]);
        cov_fail++;
      end
    if (!(&pm4_ones) || !(&pm4_zeros)) begin
      $display("COVERAGE FAIL: PriorityMuxModule_4 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    $write("  PriorityMuxModule_8: checks=%0d dflt_hit=%0d way_hit=",
           pm8_checks, pm8_dflt_hit);
    for (int w = 4 - 1; w >= 0; w--) $write("%0d ", pm8_way_hit[w]);
    $display("ones=%0d/9 zeros=%0d/9", $countones(pm8_ones), $countones(pm8_zeros));
    if (pm8_checks < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_8 有效比对只有 %0d 次", pm8_checks); cov_fail++;
    end
    if (pm8_dflt_hit < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_8 兜底路只命中 %0d 次", pm8_dflt_hit); cov_fail++;
    end
    for (int w = 0; w < 4; w++)
      if (pm8_way_hit[w] < COV_MIN) begin
        $display("COVERAGE FAIL: PriorityMuxModule_8 第 %0d 路只胜出 %0d 次", 4-1-w, pm8_way_hit[w]);
        cov_fail++;
      end
    if (!(&pm8_ones) || !(&pm8_zeros)) begin
      $display("COVERAGE FAIL: PriorityMuxModule_8 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    $write("  PriorityMuxModule_12: checks=%0d dflt_hit=%0d way_hit=",
           pm12_checks, pm12_dflt_hit);
    for (int w = 4 - 1; w >= 0; w--) $write("%0d ", pm12_way_hit[w]);
    $display("ones=%0d/23 zeros=%0d/23", $countones(pm12_ones), $countones(pm12_zeros));
    if (pm12_checks < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_12 有效比对只有 %0d 次", pm12_checks); cov_fail++;
    end
    if (pm12_dflt_hit < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_12 兜底路只命中 %0d 次", pm12_dflt_hit); cov_fail++;
    end
    for (int w = 0; w < 4; w++)
      if (pm12_way_hit[w] < COV_MIN) begin
        $display("COVERAGE FAIL: PriorityMuxModule_12 第 %0d 路只胜出 %0d 次", 4-1-w, pm12_way_hit[w]);
        cov_fail++;
      end
    if (!(&pm12_ones) || !(&pm12_zeros)) begin
      $display("COVERAGE FAIL: PriorityMuxModule_12 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    $write("  PriorityMuxModule_16: checks=%0d dflt_hit=%0d way_hit=",
           pm16_checks, pm16_dflt_hit);
    for (int w = 4 - 1; w >= 0; w--) $write("%0d ", pm16_way_hit[w]);
    $display("ones=%0d/3 zeros=%0d/3", $countones(pm16_ones), $countones(pm16_zeros));
    if (pm16_checks < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_16 有效比对只有 %0d 次", pm16_checks); cov_fail++;
    end
    if (pm16_dflt_hit < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_16 兜底路只命中 %0d 次", pm16_dflt_hit); cov_fail++;
    end
    for (int w = 0; w < 4; w++)
      if (pm16_way_hit[w] < COV_MIN) begin
        $display("COVERAGE FAIL: PriorityMuxModule_16 第 %0d 路只胜出 %0d 次", 4-1-w, pm16_way_hit[w]);
        cov_fail++;
      end
    if (!(&pm16_ones) || !(&pm16_zeros)) begin
      $display("COVERAGE FAIL: PriorityMuxModule_16 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    $write("  PriorityMuxModule_20: checks=%0d dflt_hit=%0d way_hit=",
           pm20_checks, pm20_dflt_hit);
    for (int w = 3 - 1; w >= 0; w--) $write("%0d ", pm20_way_hit[w]);
    $display("ones=%0d/1 zeros=%0d/1", $countones(pm20_ones), $countones(pm20_zeros));
    if (pm20_checks < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_20 有效比对只有 %0d 次", pm20_checks); cov_fail++;
    end
    if (pm20_dflt_hit < COV_MIN) begin
      $display("COVERAGE FAIL: PriorityMuxModule_20 兜底路只命中 %0d 次", pm20_dflt_hit); cov_fail++;
    end
    for (int w = 0; w < 3; w++)
      if (pm20_way_hit[w] < COV_MIN) begin
        $display("COVERAGE FAIL: PriorityMuxModule_20 第 %0d 路只胜出 %0d 次", 3-1-w, pm20_way_hit[w]);
        cov_fail++;
      end
    if (!(&pm20_ones) || !(&pm20_zeros)) begin
      $display("COVERAGE FAIL: PriorityMuxModule_20 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
