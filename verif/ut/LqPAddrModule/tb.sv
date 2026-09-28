// LqPAddrModule UT —— golden 与重写件双例化，逐拍比全部 288 个输出口
//   （release CAM 72 位 + releaseViolation CAM 3 × 72 位）
//
// 定向打的点（纯均匀随机打不到或打到了也看不出）：
//  (1) 同拍多写口撞同一条目：Mux1H 的"按位或"语义（上游保证不撞，golden 仅有非综合断言）；
//  (2) CAM 命中要常见：写数据与查询键都取自 6 个值的小池子（池子慢慢漂移），
//      否则 16 位键几乎永不命中，比对的全是 0；
//  (3) 0 级写延迟：写在本拍时钟沿落进条目，同拍的 CAM 看到的是旧值、下一拍看到新值；
//  (4) 越界写地址（72..127，约 2%）：one-hot 译码落在 bank 切片之外，谁也不写。
//
// ★暖机（WARMUP）：本模块全部寄存器不复位。+vcs+initreg+random 下 golden 与重写件的
//   随机初值不同，比对"谁也没写过的条目"必然不一致 —— 那是不复位状态本身没有定义。
//   所以先用 WARMUP 拍把 72 个条目全部写一遍（3 口并行，24 拍写完）再开始比对。
`timescale 1ns/1ps
module tb;
  localparam int N = 72;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        wen [3];
  logic [6:0]  waddr [3];
  logic [15:0] wdata [3];
  logic [15:0] relMdata;
  logic [15:0] vioMdata [3];

  logic [71:0] g_rel, i_rel;
  logic [71:0] g_vio [3], i_vio [3];

  // ---- 双例化：golden（原名）与重写件（_xs 后缀，由 derive_ut_impl.py 派生）----
  LqPAddrModule g_u (
    .clock(clk), .reset(rst),
    .io_wen_0(wen[0]), .io_wen_1(wen[1]), .io_wen_2(wen[2]),
    .io_waddr_0(waddr[0]), .io_waddr_1(waddr[1]), .io_waddr_2(waddr[2]),
    .io_wdata_0(wdata[0]), .io_wdata_1(wdata[1]), .io_wdata_2(wdata[2]),
    .io_releaseMdata_2(relMdata),
    .io_releaseViolationMdata_0(vioMdata[0]), .io_releaseViolationMdata_1(vioMdata[1]),
    .io_releaseViolationMdata_2(vioMdata[2]),
    .io_releaseMmask_2_0(g_rel[0]), .io_releaseMmask_2_1(g_rel[1]), .io_releaseMmask_2_2(g_rel[2]),
    .io_releaseMmask_2_3(g_rel[3]), .io_releaseMmask_2_4(g_rel[4]), .io_releaseMmask_2_5(g_rel[5]),
    .io_releaseMmask_2_6(g_rel[6]), .io_releaseMmask_2_7(g_rel[7]), .io_releaseMmask_2_8(g_rel[8]),
    .io_releaseMmask_2_9(g_rel[9]), .io_releaseMmask_2_10(g_rel[10]), .io_releaseMmask_2_11(g_rel[11]),
    .io_releaseMmask_2_12(g_rel[12]), .io_releaseMmask_2_13(g_rel[13]), .io_releaseMmask_2_14(g_rel[14]),
    .io_releaseMmask_2_15(g_rel[15]), .io_releaseMmask_2_16(g_rel[16]), .io_releaseMmask_2_17(g_rel[17]),
    .io_releaseMmask_2_18(g_rel[18]), .io_releaseMmask_2_19(g_rel[19]), .io_releaseMmask_2_20(g_rel[20]),
    .io_releaseMmask_2_21(g_rel[21]), .io_releaseMmask_2_22(g_rel[22]), .io_releaseMmask_2_23(g_rel[23]),
    .io_releaseMmask_2_24(g_rel[24]), .io_releaseMmask_2_25(g_rel[25]), .io_releaseMmask_2_26(g_rel[26]),
    .io_releaseMmask_2_27(g_rel[27]), .io_releaseMmask_2_28(g_rel[28]), .io_releaseMmask_2_29(g_rel[29]),
    .io_releaseMmask_2_30(g_rel[30]), .io_releaseMmask_2_31(g_rel[31]), .io_releaseMmask_2_32(g_rel[32]),
    .io_releaseMmask_2_33(g_rel[33]), .io_releaseMmask_2_34(g_rel[34]), .io_releaseMmask_2_35(g_rel[35]),
    .io_releaseMmask_2_36(g_rel[36]), .io_releaseMmask_2_37(g_rel[37]), .io_releaseMmask_2_38(g_rel[38]),
    .io_releaseMmask_2_39(g_rel[39]), .io_releaseMmask_2_40(g_rel[40]), .io_releaseMmask_2_41(g_rel[41]),
    .io_releaseMmask_2_42(g_rel[42]), .io_releaseMmask_2_43(g_rel[43]), .io_releaseMmask_2_44(g_rel[44]),
    .io_releaseMmask_2_45(g_rel[45]), .io_releaseMmask_2_46(g_rel[46]), .io_releaseMmask_2_47(g_rel[47]),
    .io_releaseMmask_2_48(g_rel[48]), .io_releaseMmask_2_49(g_rel[49]), .io_releaseMmask_2_50(g_rel[50]),
    .io_releaseMmask_2_51(g_rel[51]), .io_releaseMmask_2_52(g_rel[52]), .io_releaseMmask_2_53(g_rel[53]),
    .io_releaseMmask_2_54(g_rel[54]), .io_releaseMmask_2_55(g_rel[55]), .io_releaseMmask_2_56(g_rel[56]),
    .io_releaseMmask_2_57(g_rel[57]), .io_releaseMmask_2_58(g_rel[58]), .io_releaseMmask_2_59(g_rel[59]),
    .io_releaseMmask_2_60(g_rel[60]), .io_releaseMmask_2_61(g_rel[61]), .io_releaseMmask_2_62(g_rel[62]),
    .io_releaseMmask_2_63(g_rel[63]), .io_releaseMmask_2_64(g_rel[64]), .io_releaseMmask_2_65(g_rel[65]),
    .io_releaseMmask_2_66(g_rel[66]), .io_releaseMmask_2_67(g_rel[67]), .io_releaseMmask_2_68(g_rel[68]),
    .io_releaseMmask_2_69(g_rel[69]), .io_releaseMmask_2_70(g_rel[70]), .io_releaseMmask_2_71(g_rel[71]),
    .io_releaseViolationMmask_0_0(g_vio[0][0]), .io_releaseViolationMmask_0_1(g_vio[0][1]), .io_releaseViolationMmask_0_2(g_vio[0][2]),
    .io_releaseViolationMmask_0_3(g_vio[0][3]), .io_releaseViolationMmask_0_4(g_vio[0][4]), .io_releaseViolationMmask_0_5(g_vio[0][5]),
    .io_releaseViolationMmask_0_6(g_vio[0][6]), .io_releaseViolationMmask_0_7(g_vio[0][7]), .io_releaseViolationMmask_0_8(g_vio[0][8]),
    .io_releaseViolationMmask_0_9(g_vio[0][9]), .io_releaseViolationMmask_0_10(g_vio[0][10]), .io_releaseViolationMmask_0_11(g_vio[0][11]),
    .io_releaseViolationMmask_0_12(g_vio[0][12]), .io_releaseViolationMmask_0_13(g_vio[0][13]), .io_releaseViolationMmask_0_14(g_vio[0][14]),
    .io_releaseViolationMmask_0_15(g_vio[0][15]), .io_releaseViolationMmask_0_16(g_vio[0][16]), .io_releaseViolationMmask_0_17(g_vio[0][17]),
    .io_releaseViolationMmask_0_18(g_vio[0][18]), .io_releaseViolationMmask_0_19(g_vio[0][19]), .io_releaseViolationMmask_0_20(g_vio[0][20]),
    .io_releaseViolationMmask_0_21(g_vio[0][21]), .io_releaseViolationMmask_0_22(g_vio[0][22]), .io_releaseViolationMmask_0_23(g_vio[0][23]),
    .io_releaseViolationMmask_0_24(g_vio[0][24]), .io_releaseViolationMmask_0_25(g_vio[0][25]), .io_releaseViolationMmask_0_26(g_vio[0][26]),
    .io_releaseViolationMmask_0_27(g_vio[0][27]), .io_releaseViolationMmask_0_28(g_vio[0][28]), .io_releaseViolationMmask_0_29(g_vio[0][29]),
    .io_releaseViolationMmask_0_30(g_vio[0][30]), .io_releaseViolationMmask_0_31(g_vio[0][31]), .io_releaseViolationMmask_0_32(g_vio[0][32]),
    .io_releaseViolationMmask_0_33(g_vio[0][33]), .io_releaseViolationMmask_0_34(g_vio[0][34]), .io_releaseViolationMmask_0_35(g_vio[0][35]),
    .io_releaseViolationMmask_0_36(g_vio[0][36]), .io_releaseViolationMmask_0_37(g_vio[0][37]), .io_releaseViolationMmask_0_38(g_vio[0][38]),
    .io_releaseViolationMmask_0_39(g_vio[0][39]), .io_releaseViolationMmask_0_40(g_vio[0][40]), .io_releaseViolationMmask_0_41(g_vio[0][41]),
    .io_releaseViolationMmask_0_42(g_vio[0][42]), .io_releaseViolationMmask_0_43(g_vio[0][43]), .io_releaseViolationMmask_0_44(g_vio[0][44]),
    .io_releaseViolationMmask_0_45(g_vio[0][45]), .io_releaseViolationMmask_0_46(g_vio[0][46]), .io_releaseViolationMmask_0_47(g_vio[0][47]),
    .io_releaseViolationMmask_0_48(g_vio[0][48]), .io_releaseViolationMmask_0_49(g_vio[0][49]), .io_releaseViolationMmask_0_50(g_vio[0][50]),
    .io_releaseViolationMmask_0_51(g_vio[0][51]), .io_releaseViolationMmask_0_52(g_vio[0][52]), .io_releaseViolationMmask_0_53(g_vio[0][53]),
    .io_releaseViolationMmask_0_54(g_vio[0][54]), .io_releaseViolationMmask_0_55(g_vio[0][55]), .io_releaseViolationMmask_0_56(g_vio[0][56]),
    .io_releaseViolationMmask_0_57(g_vio[0][57]), .io_releaseViolationMmask_0_58(g_vio[0][58]), .io_releaseViolationMmask_0_59(g_vio[0][59]),
    .io_releaseViolationMmask_0_60(g_vio[0][60]), .io_releaseViolationMmask_0_61(g_vio[0][61]), .io_releaseViolationMmask_0_62(g_vio[0][62]),
    .io_releaseViolationMmask_0_63(g_vio[0][63]), .io_releaseViolationMmask_0_64(g_vio[0][64]), .io_releaseViolationMmask_0_65(g_vio[0][65]),
    .io_releaseViolationMmask_0_66(g_vio[0][66]), .io_releaseViolationMmask_0_67(g_vio[0][67]), .io_releaseViolationMmask_0_68(g_vio[0][68]),
    .io_releaseViolationMmask_0_69(g_vio[0][69]), .io_releaseViolationMmask_0_70(g_vio[0][70]), .io_releaseViolationMmask_0_71(g_vio[0][71]),
    .io_releaseViolationMmask_1_0(g_vio[1][0]), .io_releaseViolationMmask_1_1(g_vio[1][1]), .io_releaseViolationMmask_1_2(g_vio[1][2]),
    .io_releaseViolationMmask_1_3(g_vio[1][3]), .io_releaseViolationMmask_1_4(g_vio[1][4]), .io_releaseViolationMmask_1_5(g_vio[1][5]),
    .io_releaseViolationMmask_1_6(g_vio[1][6]), .io_releaseViolationMmask_1_7(g_vio[1][7]), .io_releaseViolationMmask_1_8(g_vio[1][8]),
    .io_releaseViolationMmask_1_9(g_vio[1][9]), .io_releaseViolationMmask_1_10(g_vio[1][10]), .io_releaseViolationMmask_1_11(g_vio[1][11]),
    .io_releaseViolationMmask_1_12(g_vio[1][12]), .io_releaseViolationMmask_1_13(g_vio[1][13]), .io_releaseViolationMmask_1_14(g_vio[1][14]),
    .io_releaseViolationMmask_1_15(g_vio[1][15]), .io_releaseViolationMmask_1_16(g_vio[1][16]), .io_releaseViolationMmask_1_17(g_vio[1][17]),
    .io_releaseViolationMmask_1_18(g_vio[1][18]), .io_releaseViolationMmask_1_19(g_vio[1][19]), .io_releaseViolationMmask_1_20(g_vio[1][20]),
    .io_releaseViolationMmask_1_21(g_vio[1][21]), .io_releaseViolationMmask_1_22(g_vio[1][22]), .io_releaseViolationMmask_1_23(g_vio[1][23]),
    .io_releaseViolationMmask_1_24(g_vio[1][24]), .io_releaseViolationMmask_1_25(g_vio[1][25]), .io_releaseViolationMmask_1_26(g_vio[1][26]),
    .io_releaseViolationMmask_1_27(g_vio[1][27]), .io_releaseViolationMmask_1_28(g_vio[1][28]), .io_releaseViolationMmask_1_29(g_vio[1][29]),
    .io_releaseViolationMmask_1_30(g_vio[1][30]), .io_releaseViolationMmask_1_31(g_vio[1][31]), .io_releaseViolationMmask_1_32(g_vio[1][32]),
    .io_releaseViolationMmask_1_33(g_vio[1][33]), .io_releaseViolationMmask_1_34(g_vio[1][34]), .io_releaseViolationMmask_1_35(g_vio[1][35]),
    .io_releaseViolationMmask_1_36(g_vio[1][36]), .io_releaseViolationMmask_1_37(g_vio[1][37]), .io_releaseViolationMmask_1_38(g_vio[1][38]),
    .io_releaseViolationMmask_1_39(g_vio[1][39]), .io_releaseViolationMmask_1_40(g_vio[1][40]), .io_releaseViolationMmask_1_41(g_vio[1][41]),
    .io_releaseViolationMmask_1_42(g_vio[1][42]), .io_releaseViolationMmask_1_43(g_vio[1][43]), .io_releaseViolationMmask_1_44(g_vio[1][44]),
    .io_releaseViolationMmask_1_45(g_vio[1][45]), .io_releaseViolationMmask_1_46(g_vio[1][46]), .io_releaseViolationMmask_1_47(g_vio[1][47]),
    .io_releaseViolationMmask_1_48(g_vio[1][48]), .io_releaseViolationMmask_1_49(g_vio[1][49]), .io_releaseViolationMmask_1_50(g_vio[1][50]),
    .io_releaseViolationMmask_1_51(g_vio[1][51]), .io_releaseViolationMmask_1_52(g_vio[1][52]), .io_releaseViolationMmask_1_53(g_vio[1][53]),
    .io_releaseViolationMmask_1_54(g_vio[1][54]), .io_releaseViolationMmask_1_55(g_vio[1][55]), .io_releaseViolationMmask_1_56(g_vio[1][56]),
    .io_releaseViolationMmask_1_57(g_vio[1][57]), .io_releaseViolationMmask_1_58(g_vio[1][58]), .io_releaseViolationMmask_1_59(g_vio[1][59]),
    .io_releaseViolationMmask_1_60(g_vio[1][60]), .io_releaseViolationMmask_1_61(g_vio[1][61]), .io_releaseViolationMmask_1_62(g_vio[1][62]),
    .io_releaseViolationMmask_1_63(g_vio[1][63]), .io_releaseViolationMmask_1_64(g_vio[1][64]), .io_releaseViolationMmask_1_65(g_vio[1][65]),
    .io_releaseViolationMmask_1_66(g_vio[1][66]), .io_releaseViolationMmask_1_67(g_vio[1][67]), .io_releaseViolationMmask_1_68(g_vio[1][68]),
    .io_releaseViolationMmask_1_69(g_vio[1][69]), .io_releaseViolationMmask_1_70(g_vio[1][70]), .io_releaseViolationMmask_1_71(g_vio[1][71]),
    .io_releaseViolationMmask_2_0(g_vio[2][0]), .io_releaseViolationMmask_2_1(g_vio[2][1]), .io_releaseViolationMmask_2_2(g_vio[2][2]),
    .io_releaseViolationMmask_2_3(g_vio[2][3]), .io_releaseViolationMmask_2_4(g_vio[2][4]), .io_releaseViolationMmask_2_5(g_vio[2][5]),
    .io_releaseViolationMmask_2_6(g_vio[2][6]), .io_releaseViolationMmask_2_7(g_vio[2][7]), .io_releaseViolationMmask_2_8(g_vio[2][8]),
    .io_releaseViolationMmask_2_9(g_vio[2][9]), .io_releaseViolationMmask_2_10(g_vio[2][10]), .io_releaseViolationMmask_2_11(g_vio[2][11]),
    .io_releaseViolationMmask_2_12(g_vio[2][12]), .io_releaseViolationMmask_2_13(g_vio[2][13]), .io_releaseViolationMmask_2_14(g_vio[2][14]),
    .io_releaseViolationMmask_2_15(g_vio[2][15]), .io_releaseViolationMmask_2_16(g_vio[2][16]), .io_releaseViolationMmask_2_17(g_vio[2][17]),
    .io_releaseViolationMmask_2_18(g_vio[2][18]), .io_releaseViolationMmask_2_19(g_vio[2][19]), .io_releaseViolationMmask_2_20(g_vio[2][20]),
    .io_releaseViolationMmask_2_21(g_vio[2][21]), .io_releaseViolationMmask_2_22(g_vio[2][22]), .io_releaseViolationMmask_2_23(g_vio[2][23]),
    .io_releaseViolationMmask_2_24(g_vio[2][24]), .io_releaseViolationMmask_2_25(g_vio[2][25]), .io_releaseViolationMmask_2_26(g_vio[2][26]),
    .io_releaseViolationMmask_2_27(g_vio[2][27]), .io_releaseViolationMmask_2_28(g_vio[2][28]), .io_releaseViolationMmask_2_29(g_vio[2][29]),
    .io_releaseViolationMmask_2_30(g_vio[2][30]), .io_releaseViolationMmask_2_31(g_vio[2][31]), .io_releaseViolationMmask_2_32(g_vio[2][32]),
    .io_releaseViolationMmask_2_33(g_vio[2][33]), .io_releaseViolationMmask_2_34(g_vio[2][34]), .io_releaseViolationMmask_2_35(g_vio[2][35]),
    .io_releaseViolationMmask_2_36(g_vio[2][36]), .io_releaseViolationMmask_2_37(g_vio[2][37]), .io_releaseViolationMmask_2_38(g_vio[2][38]),
    .io_releaseViolationMmask_2_39(g_vio[2][39]), .io_releaseViolationMmask_2_40(g_vio[2][40]), .io_releaseViolationMmask_2_41(g_vio[2][41]),
    .io_releaseViolationMmask_2_42(g_vio[2][42]), .io_releaseViolationMmask_2_43(g_vio[2][43]), .io_releaseViolationMmask_2_44(g_vio[2][44]),
    .io_releaseViolationMmask_2_45(g_vio[2][45]), .io_releaseViolationMmask_2_46(g_vio[2][46]), .io_releaseViolationMmask_2_47(g_vio[2][47]),
    .io_releaseViolationMmask_2_48(g_vio[2][48]), .io_releaseViolationMmask_2_49(g_vio[2][49]), .io_releaseViolationMmask_2_50(g_vio[2][50]),
    .io_releaseViolationMmask_2_51(g_vio[2][51]), .io_releaseViolationMmask_2_52(g_vio[2][52]), .io_releaseViolationMmask_2_53(g_vio[2][53]),
    .io_releaseViolationMmask_2_54(g_vio[2][54]), .io_releaseViolationMmask_2_55(g_vio[2][55]), .io_releaseViolationMmask_2_56(g_vio[2][56]),
    .io_releaseViolationMmask_2_57(g_vio[2][57]), .io_releaseViolationMmask_2_58(g_vio[2][58]), .io_releaseViolationMmask_2_59(g_vio[2][59]),
    .io_releaseViolationMmask_2_60(g_vio[2][60]), .io_releaseViolationMmask_2_61(g_vio[2][61]), .io_releaseViolationMmask_2_62(g_vio[2][62]),
    .io_releaseViolationMmask_2_63(g_vio[2][63]), .io_releaseViolationMmask_2_64(g_vio[2][64]), .io_releaseViolationMmask_2_65(g_vio[2][65]),
    .io_releaseViolationMmask_2_66(g_vio[2][66]), .io_releaseViolationMmask_2_67(g_vio[2][67]), .io_releaseViolationMmask_2_68(g_vio[2][68]),
    .io_releaseViolationMmask_2_69(g_vio[2][69]), .io_releaseViolationMmask_2_70(g_vio[2][70]), .io_releaseViolationMmask_2_71(g_vio[2][71])
  );
  LqPAddrModule_xs i_u (
    .clock(clk), .reset(rst),
    .io_wen_0(wen[0]), .io_wen_1(wen[1]), .io_wen_2(wen[2]),
    .io_waddr_0(waddr[0]), .io_waddr_1(waddr[1]), .io_waddr_2(waddr[2]),
    .io_wdata_0(wdata[0]), .io_wdata_1(wdata[1]), .io_wdata_2(wdata[2]),
    .io_releaseMdata_2(relMdata),
    .io_releaseViolationMdata_0(vioMdata[0]), .io_releaseViolationMdata_1(vioMdata[1]),
    .io_releaseViolationMdata_2(vioMdata[2]),
    .io_releaseMmask_2_0(i_rel[0]), .io_releaseMmask_2_1(i_rel[1]), .io_releaseMmask_2_2(i_rel[2]),
    .io_releaseMmask_2_3(i_rel[3]), .io_releaseMmask_2_4(i_rel[4]), .io_releaseMmask_2_5(i_rel[5]),
    .io_releaseMmask_2_6(i_rel[6]), .io_releaseMmask_2_7(i_rel[7]), .io_releaseMmask_2_8(i_rel[8]),
    .io_releaseMmask_2_9(i_rel[9]), .io_releaseMmask_2_10(i_rel[10]), .io_releaseMmask_2_11(i_rel[11]),
    .io_releaseMmask_2_12(i_rel[12]), .io_releaseMmask_2_13(i_rel[13]), .io_releaseMmask_2_14(i_rel[14]),
    .io_releaseMmask_2_15(i_rel[15]), .io_releaseMmask_2_16(i_rel[16]), .io_releaseMmask_2_17(i_rel[17]),
    .io_releaseMmask_2_18(i_rel[18]), .io_releaseMmask_2_19(i_rel[19]), .io_releaseMmask_2_20(i_rel[20]),
    .io_releaseMmask_2_21(i_rel[21]), .io_releaseMmask_2_22(i_rel[22]), .io_releaseMmask_2_23(i_rel[23]),
    .io_releaseMmask_2_24(i_rel[24]), .io_releaseMmask_2_25(i_rel[25]), .io_releaseMmask_2_26(i_rel[26]),
    .io_releaseMmask_2_27(i_rel[27]), .io_releaseMmask_2_28(i_rel[28]), .io_releaseMmask_2_29(i_rel[29]),
    .io_releaseMmask_2_30(i_rel[30]), .io_releaseMmask_2_31(i_rel[31]), .io_releaseMmask_2_32(i_rel[32]),
    .io_releaseMmask_2_33(i_rel[33]), .io_releaseMmask_2_34(i_rel[34]), .io_releaseMmask_2_35(i_rel[35]),
    .io_releaseMmask_2_36(i_rel[36]), .io_releaseMmask_2_37(i_rel[37]), .io_releaseMmask_2_38(i_rel[38]),
    .io_releaseMmask_2_39(i_rel[39]), .io_releaseMmask_2_40(i_rel[40]), .io_releaseMmask_2_41(i_rel[41]),
    .io_releaseMmask_2_42(i_rel[42]), .io_releaseMmask_2_43(i_rel[43]), .io_releaseMmask_2_44(i_rel[44]),
    .io_releaseMmask_2_45(i_rel[45]), .io_releaseMmask_2_46(i_rel[46]), .io_releaseMmask_2_47(i_rel[47]),
    .io_releaseMmask_2_48(i_rel[48]), .io_releaseMmask_2_49(i_rel[49]), .io_releaseMmask_2_50(i_rel[50]),
    .io_releaseMmask_2_51(i_rel[51]), .io_releaseMmask_2_52(i_rel[52]), .io_releaseMmask_2_53(i_rel[53]),
    .io_releaseMmask_2_54(i_rel[54]), .io_releaseMmask_2_55(i_rel[55]), .io_releaseMmask_2_56(i_rel[56]),
    .io_releaseMmask_2_57(i_rel[57]), .io_releaseMmask_2_58(i_rel[58]), .io_releaseMmask_2_59(i_rel[59]),
    .io_releaseMmask_2_60(i_rel[60]), .io_releaseMmask_2_61(i_rel[61]), .io_releaseMmask_2_62(i_rel[62]),
    .io_releaseMmask_2_63(i_rel[63]), .io_releaseMmask_2_64(i_rel[64]), .io_releaseMmask_2_65(i_rel[65]),
    .io_releaseMmask_2_66(i_rel[66]), .io_releaseMmask_2_67(i_rel[67]), .io_releaseMmask_2_68(i_rel[68]),
    .io_releaseMmask_2_69(i_rel[69]), .io_releaseMmask_2_70(i_rel[70]), .io_releaseMmask_2_71(i_rel[71]),
    .io_releaseViolationMmask_0_0(i_vio[0][0]), .io_releaseViolationMmask_0_1(i_vio[0][1]), .io_releaseViolationMmask_0_2(i_vio[0][2]),
    .io_releaseViolationMmask_0_3(i_vio[0][3]), .io_releaseViolationMmask_0_4(i_vio[0][4]), .io_releaseViolationMmask_0_5(i_vio[0][5]),
    .io_releaseViolationMmask_0_6(i_vio[0][6]), .io_releaseViolationMmask_0_7(i_vio[0][7]), .io_releaseViolationMmask_0_8(i_vio[0][8]),
    .io_releaseViolationMmask_0_9(i_vio[0][9]), .io_releaseViolationMmask_0_10(i_vio[0][10]), .io_releaseViolationMmask_0_11(i_vio[0][11]),
    .io_releaseViolationMmask_0_12(i_vio[0][12]), .io_releaseViolationMmask_0_13(i_vio[0][13]), .io_releaseViolationMmask_0_14(i_vio[0][14]),
    .io_releaseViolationMmask_0_15(i_vio[0][15]), .io_releaseViolationMmask_0_16(i_vio[0][16]), .io_releaseViolationMmask_0_17(i_vio[0][17]),
    .io_releaseViolationMmask_0_18(i_vio[0][18]), .io_releaseViolationMmask_0_19(i_vio[0][19]), .io_releaseViolationMmask_0_20(i_vio[0][20]),
    .io_releaseViolationMmask_0_21(i_vio[0][21]), .io_releaseViolationMmask_0_22(i_vio[0][22]), .io_releaseViolationMmask_0_23(i_vio[0][23]),
    .io_releaseViolationMmask_0_24(i_vio[0][24]), .io_releaseViolationMmask_0_25(i_vio[0][25]), .io_releaseViolationMmask_0_26(i_vio[0][26]),
    .io_releaseViolationMmask_0_27(i_vio[0][27]), .io_releaseViolationMmask_0_28(i_vio[0][28]), .io_releaseViolationMmask_0_29(i_vio[0][29]),
    .io_releaseViolationMmask_0_30(i_vio[0][30]), .io_releaseViolationMmask_0_31(i_vio[0][31]), .io_releaseViolationMmask_0_32(i_vio[0][32]),
    .io_releaseViolationMmask_0_33(i_vio[0][33]), .io_releaseViolationMmask_0_34(i_vio[0][34]), .io_releaseViolationMmask_0_35(i_vio[0][35]),
    .io_releaseViolationMmask_0_36(i_vio[0][36]), .io_releaseViolationMmask_0_37(i_vio[0][37]), .io_releaseViolationMmask_0_38(i_vio[0][38]),
    .io_releaseViolationMmask_0_39(i_vio[0][39]), .io_releaseViolationMmask_0_40(i_vio[0][40]), .io_releaseViolationMmask_0_41(i_vio[0][41]),
    .io_releaseViolationMmask_0_42(i_vio[0][42]), .io_releaseViolationMmask_0_43(i_vio[0][43]), .io_releaseViolationMmask_0_44(i_vio[0][44]),
    .io_releaseViolationMmask_0_45(i_vio[0][45]), .io_releaseViolationMmask_0_46(i_vio[0][46]), .io_releaseViolationMmask_0_47(i_vio[0][47]),
    .io_releaseViolationMmask_0_48(i_vio[0][48]), .io_releaseViolationMmask_0_49(i_vio[0][49]), .io_releaseViolationMmask_0_50(i_vio[0][50]),
    .io_releaseViolationMmask_0_51(i_vio[0][51]), .io_releaseViolationMmask_0_52(i_vio[0][52]), .io_releaseViolationMmask_0_53(i_vio[0][53]),
    .io_releaseViolationMmask_0_54(i_vio[0][54]), .io_releaseViolationMmask_0_55(i_vio[0][55]), .io_releaseViolationMmask_0_56(i_vio[0][56]),
    .io_releaseViolationMmask_0_57(i_vio[0][57]), .io_releaseViolationMmask_0_58(i_vio[0][58]), .io_releaseViolationMmask_0_59(i_vio[0][59]),
    .io_releaseViolationMmask_0_60(i_vio[0][60]), .io_releaseViolationMmask_0_61(i_vio[0][61]), .io_releaseViolationMmask_0_62(i_vio[0][62]),
    .io_releaseViolationMmask_0_63(i_vio[0][63]), .io_releaseViolationMmask_0_64(i_vio[0][64]), .io_releaseViolationMmask_0_65(i_vio[0][65]),
    .io_releaseViolationMmask_0_66(i_vio[0][66]), .io_releaseViolationMmask_0_67(i_vio[0][67]), .io_releaseViolationMmask_0_68(i_vio[0][68]),
    .io_releaseViolationMmask_0_69(i_vio[0][69]), .io_releaseViolationMmask_0_70(i_vio[0][70]), .io_releaseViolationMmask_0_71(i_vio[0][71]),
    .io_releaseViolationMmask_1_0(i_vio[1][0]), .io_releaseViolationMmask_1_1(i_vio[1][1]), .io_releaseViolationMmask_1_2(i_vio[1][2]),
    .io_releaseViolationMmask_1_3(i_vio[1][3]), .io_releaseViolationMmask_1_4(i_vio[1][4]), .io_releaseViolationMmask_1_5(i_vio[1][5]),
    .io_releaseViolationMmask_1_6(i_vio[1][6]), .io_releaseViolationMmask_1_7(i_vio[1][7]), .io_releaseViolationMmask_1_8(i_vio[1][8]),
    .io_releaseViolationMmask_1_9(i_vio[1][9]), .io_releaseViolationMmask_1_10(i_vio[1][10]), .io_releaseViolationMmask_1_11(i_vio[1][11]),
    .io_releaseViolationMmask_1_12(i_vio[1][12]), .io_releaseViolationMmask_1_13(i_vio[1][13]), .io_releaseViolationMmask_1_14(i_vio[1][14]),
    .io_releaseViolationMmask_1_15(i_vio[1][15]), .io_releaseViolationMmask_1_16(i_vio[1][16]), .io_releaseViolationMmask_1_17(i_vio[1][17]),
    .io_releaseViolationMmask_1_18(i_vio[1][18]), .io_releaseViolationMmask_1_19(i_vio[1][19]), .io_releaseViolationMmask_1_20(i_vio[1][20]),
    .io_releaseViolationMmask_1_21(i_vio[1][21]), .io_releaseViolationMmask_1_22(i_vio[1][22]), .io_releaseViolationMmask_1_23(i_vio[1][23]),
    .io_releaseViolationMmask_1_24(i_vio[1][24]), .io_releaseViolationMmask_1_25(i_vio[1][25]), .io_releaseViolationMmask_1_26(i_vio[1][26]),
    .io_releaseViolationMmask_1_27(i_vio[1][27]), .io_releaseViolationMmask_1_28(i_vio[1][28]), .io_releaseViolationMmask_1_29(i_vio[1][29]),
    .io_releaseViolationMmask_1_30(i_vio[1][30]), .io_releaseViolationMmask_1_31(i_vio[1][31]), .io_releaseViolationMmask_1_32(i_vio[1][32]),
    .io_releaseViolationMmask_1_33(i_vio[1][33]), .io_releaseViolationMmask_1_34(i_vio[1][34]), .io_releaseViolationMmask_1_35(i_vio[1][35]),
    .io_releaseViolationMmask_1_36(i_vio[1][36]), .io_releaseViolationMmask_1_37(i_vio[1][37]), .io_releaseViolationMmask_1_38(i_vio[1][38]),
    .io_releaseViolationMmask_1_39(i_vio[1][39]), .io_releaseViolationMmask_1_40(i_vio[1][40]), .io_releaseViolationMmask_1_41(i_vio[1][41]),
    .io_releaseViolationMmask_1_42(i_vio[1][42]), .io_releaseViolationMmask_1_43(i_vio[1][43]), .io_releaseViolationMmask_1_44(i_vio[1][44]),
    .io_releaseViolationMmask_1_45(i_vio[1][45]), .io_releaseViolationMmask_1_46(i_vio[1][46]), .io_releaseViolationMmask_1_47(i_vio[1][47]),
    .io_releaseViolationMmask_1_48(i_vio[1][48]), .io_releaseViolationMmask_1_49(i_vio[1][49]), .io_releaseViolationMmask_1_50(i_vio[1][50]),
    .io_releaseViolationMmask_1_51(i_vio[1][51]), .io_releaseViolationMmask_1_52(i_vio[1][52]), .io_releaseViolationMmask_1_53(i_vio[1][53]),
    .io_releaseViolationMmask_1_54(i_vio[1][54]), .io_releaseViolationMmask_1_55(i_vio[1][55]), .io_releaseViolationMmask_1_56(i_vio[1][56]),
    .io_releaseViolationMmask_1_57(i_vio[1][57]), .io_releaseViolationMmask_1_58(i_vio[1][58]), .io_releaseViolationMmask_1_59(i_vio[1][59]),
    .io_releaseViolationMmask_1_60(i_vio[1][60]), .io_releaseViolationMmask_1_61(i_vio[1][61]), .io_releaseViolationMmask_1_62(i_vio[1][62]),
    .io_releaseViolationMmask_1_63(i_vio[1][63]), .io_releaseViolationMmask_1_64(i_vio[1][64]), .io_releaseViolationMmask_1_65(i_vio[1][65]),
    .io_releaseViolationMmask_1_66(i_vio[1][66]), .io_releaseViolationMmask_1_67(i_vio[1][67]), .io_releaseViolationMmask_1_68(i_vio[1][68]),
    .io_releaseViolationMmask_1_69(i_vio[1][69]), .io_releaseViolationMmask_1_70(i_vio[1][70]), .io_releaseViolationMmask_1_71(i_vio[1][71]),
    .io_releaseViolationMmask_2_0(i_vio[2][0]), .io_releaseViolationMmask_2_1(i_vio[2][1]), .io_releaseViolationMmask_2_2(i_vio[2][2]),
    .io_releaseViolationMmask_2_3(i_vio[2][3]), .io_releaseViolationMmask_2_4(i_vio[2][4]), .io_releaseViolationMmask_2_5(i_vio[2][5]),
    .io_releaseViolationMmask_2_6(i_vio[2][6]), .io_releaseViolationMmask_2_7(i_vio[2][7]), .io_releaseViolationMmask_2_8(i_vio[2][8]),
    .io_releaseViolationMmask_2_9(i_vio[2][9]), .io_releaseViolationMmask_2_10(i_vio[2][10]), .io_releaseViolationMmask_2_11(i_vio[2][11]),
    .io_releaseViolationMmask_2_12(i_vio[2][12]), .io_releaseViolationMmask_2_13(i_vio[2][13]), .io_releaseViolationMmask_2_14(i_vio[2][14]),
    .io_releaseViolationMmask_2_15(i_vio[2][15]), .io_releaseViolationMmask_2_16(i_vio[2][16]), .io_releaseViolationMmask_2_17(i_vio[2][17]),
    .io_releaseViolationMmask_2_18(i_vio[2][18]), .io_releaseViolationMmask_2_19(i_vio[2][19]), .io_releaseViolationMmask_2_20(i_vio[2][20]),
    .io_releaseViolationMmask_2_21(i_vio[2][21]), .io_releaseViolationMmask_2_22(i_vio[2][22]), .io_releaseViolationMmask_2_23(i_vio[2][23]),
    .io_releaseViolationMmask_2_24(i_vio[2][24]), .io_releaseViolationMmask_2_25(i_vio[2][25]), .io_releaseViolationMmask_2_26(i_vio[2][26]),
    .io_releaseViolationMmask_2_27(i_vio[2][27]), .io_releaseViolationMmask_2_28(i_vio[2][28]), .io_releaseViolationMmask_2_29(i_vio[2][29]),
    .io_releaseViolationMmask_2_30(i_vio[2][30]), .io_releaseViolationMmask_2_31(i_vio[2][31]), .io_releaseViolationMmask_2_32(i_vio[2][32]),
    .io_releaseViolationMmask_2_33(i_vio[2][33]), .io_releaseViolationMmask_2_34(i_vio[2][34]), .io_releaseViolationMmask_2_35(i_vio[2][35]),
    .io_releaseViolationMmask_2_36(i_vio[2][36]), .io_releaseViolationMmask_2_37(i_vio[2][37]), .io_releaseViolationMmask_2_38(i_vio[2][38]),
    .io_releaseViolationMmask_2_39(i_vio[2][39]), .io_releaseViolationMmask_2_40(i_vio[2][40]), .io_releaseViolationMmask_2_41(i_vio[2][41]),
    .io_releaseViolationMmask_2_42(i_vio[2][42]), .io_releaseViolationMmask_2_43(i_vio[2][43]), .io_releaseViolationMmask_2_44(i_vio[2][44]),
    .io_releaseViolationMmask_2_45(i_vio[2][45]), .io_releaseViolationMmask_2_46(i_vio[2][46]), .io_releaseViolationMmask_2_47(i_vio[2][47]),
    .io_releaseViolationMmask_2_48(i_vio[2][48]), .io_releaseViolationMmask_2_49(i_vio[2][49]), .io_releaseViolationMmask_2_50(i_vio[2][50]),
    .io_releaseViolationMmask_2_51(i_vio[2][51]), .io_releaseViolationMmask_2_52(i_vio[2][52]), .io_releaseViolationMmask_2_53(i_vio[2][53]),
    .io_releaseViolationMmask_2_54(i_vio[2][54]), .io_releaseViolationMmask_2_55(i_vio[2][55]), .io_releaseViolationMmask_2_56(i_vio[2][56]),
    .io_releaseViolationMmask_2_57(i_vio[2][57]), .io_releaseViolationMmask_2_58(i_vio[2][58]), .io_releaseViolationMmask_2_59(i_vio[2][59]),
    .io_releaseViolationMmask_2_60(i_vio[2][60]), .io_releaseViolationMmask_2_61(i_vio[2][61]), .io_releaseViolationMmask_2_62(i_vio[2][62]),
    .io_releaseViolationMmask_2_63(i_vio[2][63]), .io_releaseViolationMmask_2_64(i_vio[2][64]), .io_releaseViolationMmask_2_65(i_vio[2][65]),
    .io_releaseViolationMmask_2_66(i_vio[2][66]), .io_releaseViolationMmask_2_67(i_vio[2][67]), .io_releaseViolationMmask_2_68(i_vio[2][68]),
    .io_releaseViolationMmask_2_69(i_vio[2][69]), .io_releaseViolationMmask_2_70(i_vio[2][70]), .io_releaseViolationMmask_2_71(i_vio[2][71])
  );

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  logic [15:0] pool [6];
  function automatic logic [15:0] rnd_key();
    return ($urandom_range(0, 19) == 0) ? 16'($urandom) : pool[$urandom_range(0, 5)];
  endfunction

  localparam int WARMUP = 24;
  int cyc;
  wire warm = (cyc >= WARMUP);
  int cov_collide, cov_oob, cov_hit_rel, cov_hit_vio, cov_multi_hit;

  always @(negedge clk) begin
    if (rst) cyc <= 0; else cyc <= cyc + 1;
  end

  always @(negedge clk) begin
    if (rst) begin
      for (int w = 0; w < 3; w++) begin
        wen[w] <= 1'b0; waddr[w] <= '0; wdata[w] <= '0; vioMdata[w] <= '0;
      end
      relMdata <= '0;
    end else if (!warm) begin
      // 暖机：cyc=0..23 按 3 口并行写满 0..71
      for (int w = 0; w < 3; w++) begin
        wen[w]   <= 1'b1;
        waddr[w] <= 7'(cyc * 3 + w);
        wdata[w] <= rnd_key();
      end
    end else begin
      int a0;
      a0 = $urandom_range(0, N-1);
      case ($urandom_range(0, 19))
        // 定向撞地址：2 口或 3 口同拍写同一条目 → 只有"按位或"对得上
        0, 1: begin
          wen[0] <= 1'b1; wen[1] <= 1'b1; wen[2] <= ($urandom_range(0, 1) == 1);
          waddr[0] <= 7'(a0); waddr[1] <= 7'(a0);
          waddr[2] <= ($urandom_range(0, 1) == 1) ? 7'(a0) : 7'($urandom_range(0, N-1));
          cov_collide <= cov_collide + 1;
        end
        2: begin   // 越界地址
          for (int w = 0; w < 3; w++) begin
            wen[w]   <= 1'b1;
            waddr[w] <= 7'($urandom_range(N, 127));
          end
          cov_oob <= cov_oob + 1;
        end
        default: begin
          for (int w = 0; w < 3; w++) begin
            wen[w]   <= ($urandom_range(0, 2) != 0);
            waddr[w] <= 7'($urandom_range(0, N-1));
          end
        end
      endcase
      for (int w = 0; w < 3; w++) begin
        wdata[w]    <= rnd_key();
        vioMdata[w] <= rnd_key();
      end
      relMdata <= rnd_key();
      if ($urandom_range(0, 499) == 0) pool[$urandom_range(0, 5)] <= 16'($urandom);
    end
  end

  // ---------------------------------------------------------------------------
  // 比对
  // ---------------------------------------------------------------------------
  `define CHK(nm, g, i) \
    if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, g, i); end

  always @(negedge clk) if (!rst && warm) begin
    #4; checks++;
    `CHK("releaseMmask_2", g_rel, i_rel)
    if (|g_rel) cov_hit_rel++;
    for (int c = 0; c < 3; c++) begin
      `CHK($sformatf("releaseViolationMmask_%0d", c), g_vio[c], i_vio[c])
      if (|g_vio[c]) cov_hit_vio++;
      if ($countones(g_vio[c]) > 1) cov_multi_hit++;
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int i = 0; i < 6; i++) pool[i] = 16'($urandom);
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("COV collide=%0d oob=%0d hit_release=%0d hit_violation=%0d multi_hit=%0d",
             cov_collide, cov_oob, cov_hit_rel, cov_hit_vio, cov_multi_hit);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_collide > 100 && cov_oob > 100
        && cov_hit_rel > 1000 && cov_hit_vio > 1000)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
