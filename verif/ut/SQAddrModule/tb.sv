// =============================================================================
// verif/ut/SQAddrModule/tb.sv —— 家族两个变体一起做 golden 双例化逐拍比对
// -----------------------------------------------------------------------------
// 一个 tb 同时带 SQAddrModule(48 位,带 rlineflag 读口)与 SQAddrModule_1
// (50 位,不带),因为它们共享同一个参数化核 —— 只测一个等于只证了一半。
//
// 本模块有判别力的边界(纯均匀随机全都打不到,必须定向):
//   B1 ★前递 CAM 真的命中★ —— 地址若均匀随机,48 位里高 42 位相等的概率是 2^-42,
//      整轮一次都不会命中,168 条比较式等于没验。这里用**小地址池**保证高位常相等。
//   B2 lineflag=1 的条目 —— 置位后跳过 vword 比较,只要同 line 就命中
//   B3 mask 与 forwardDataMask **恰好无交集** —— 同 line 同 vword 但字节不重叠,
//      必须不命中(这条最容易写成"同 vword 就命中")
//   B4 ★读地址越界(56..63)→ 落到条目 0,不是落到 0★
//   B5 两个写口同址(优先级:口 1 胜口 0)—— golden 带断言禁止,故关断言故意打
//   B6 ★中途复位脉冲★ —— 不打的话"给 168 个不复位寄存器加了复位"完全不可观测
//
// 复位后先"全条目预热写",把 168 个不复位寄存器写满再开比对。
//
// ---------------------------------------------------------------------------
// ★ 判别力证据:注入真 bug 必须被报出来 ★
// ---------------------------------------------------------------------------
// 5 个变异体各只改 rtl/memblock/SQAddrModule.sv 一处。★变异体不进库★,
// 这里记配方与实测数字(seed=1 / 20000 拍):
//
//   A1 越界读落到条目 1 而不是条目 0(clamp_idx `: 0`→`: 1`)   → errors=7322
//   A2 写口优先级反转(§2.2 的 for 改倒序)                      → errors=4249
//   A3 前递漏掉 lineflag 项(去掉 `|| lineflag[j]`)            → errors=94325
//   A4 给 168 个不复位寄存器加复位                              → errors=10611
//   A5 字节掩码交集判据改成恒真(去掉 `|(mask & fdmask)`)       → errors=59598
//
// 同一条件下未变异版本 errors=0 / checks=418509。
//
// ★ 一条测不到的形态,必须明说 ★:把 rdata_addr_r 与 rlineflag_addr_r 这**两份
//   值永远相同**的读地址寄存器合并成一份,UT **抓不到**(行为逐拍相同)。
//   它只改寄存器集合,靠 FM 的比较点计数暴露 —— 这是留给 Formal 的,不是 UT 的活。
// =============================================================================
`timescale 1ns/1ps
module tb;

  localparam int NE = 56;
  localparam int NW = 2;
  localparam int NR = 2;
  localparam int NF = 3;
  localparam int W0 = 48;   // SQAddrModule
  localparam int W1 = 50;   // SQAddrModule_1

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // --- 共享激励(地址/使能/掩码两变体共用,只有数据位宽不同)---
  logic [5:0]  raddr [NR];
  logic        wen   [NW];
  logic [5:0]  waddr [NW];
  logic [15:0] wmask [NW];
  logic        wlineflag [NW];
  logic [15:0] fdmask [NF];
  logic [W0-1:0] wdata0 [NW], fmdata0 [NF];
  logic [W1-1:0] wdata1 [NW], fmdata1 [NF];

  // --- 变体 0 输出 ---
  logic [W0-1:0] g0_rdata [NR], i0_rdata [NR];
  logic          g0_rlf   [NR], i0_rlf   [NR];
  logic [NE-1:0] g0_mm    [NF], i0_mm    [NF];
  // --- 变体 1 输出(无 rlineflag)---
  logic [W1-1:0] g1_rdata [NR], i1_rdata [NR];
  logic [NE-1:0] g1_mm    [NF], i1_mm    [NF];

  // 4 个例化(golden/impl × 2 变体)见下 —— 每个带 168 个扁平 forwardMmask
  // 端口,共 672 行连线,由 scratchpad/gen_sqaddr_tb.py 机械生成。
  SQAddrModule g_u0 (
    .clock(clk),
    .reset(rst),
    .io_raddr_0(raddr[0]),
    .io_raddr_1(raddr[1]),
    .io_rdata_0(g0_rdata[0]),
    .io_rdata_1(g0_rdata[1]),
    .io_rlineflag_0(g0_rlf[0]),
    .io_rlineflag_1(g0_rlf[1]),
    .io_wen_0(wen[0]),
    .io_wen_1(wen[1]),
    .io_waddr_0(waddr[0]),
    .io_waddr_1(waddr[1]),
    .io_wdata_0(wdata0[0]),
    .io_wdata_1(wdata0[1]),
    .io_wmask_0(wmask[0]),
    .io_wmask_1(wmask[1]),
    .io_wlineflag_0(wlineflag[0]),
    .io_wlineflag_1(wlineflag[1]),
    .io_forwardMdata_0(fmdata0[0]),
    .io_forwardMdata_1(fmdata0[1]),
    .io_forwardMdata_2(fmdata0[2]),
    .io_forwardDataMask_0(fdmask[0]),
    .io_forwardDataMask_1(fdmask[1]),
    .io_forwardDataMask_2(fdmask[2]),
    .io_forwardMmask_0_0(g0_mm[0][0]),
    .io_forwardMmask_0_1(g0_mm[0][1]),
    .io_forwardMmask_0_2(g0_mm[0][2]),
    .io_forwardMmask_0_3(g0_mm[0][3]),
    .io_forwardMmask_0_4(g0_mm[0][4]),
    .io_forwardMmask_0_5(g0_mm[0][5]),
    .io_forwardMmask_0_6(g0_mm[0][6]),
    .io_forwardMmask_0_7(g0_mm[0][7]),
    .io_forwardMmask_0_8(g0_mm[0][8]),
    .io_forwardMmask_0_9(g0_mm[0][9]),
    .io_forwardMmask_0_10(g0_mm[0][10]),
    .io_forwardMmask_0_11(g0_mm[0][11]),
    .io_forwardMmask_0_12(g0_mm[0][12]),
    .io_forwardMmask_0_13(g0_mm[0][13]),
    .io_forwardMmask_0_14(g0_mm[0][14]),
    .io_forwardMmask_0_15(g0_mm[0][15]),
    .io_forwardMmask_0_16(g0_mm[0][16]),
    .io_forwardMmask_0_17(g0_mm[0][17]),
    .io_forwardMmask_0_18(g0_mm[0][18]),
    .io_forwardMmask_0_19(g0_mm[0][19]),
    .io_forwardMmask_0_20(g0_mm[0][20]),
    .io_forwardMmask_0_21(g0_mm[0][21]),
    .io_forwardMmask_0_22(g0_mm[0][22]),
    .io_forwardMmask_0_23(g0_mm[0][23]),
    .io_forwardMmask_0_24(g0_mm[0][24]),
    .io_forwardMmask_0_25(g0_mm[0][25]),
    .io_forwardMmask_0_26(g0_mm[0][26]),
    .io_forwardMmask_0_27(g0_mm[0][27]),
    .io_forwardMmask_0_28(g0_mm[0][28]),
    .io_forwardMmask_0_29(g0_mm[0][29]),
    .io_forwardMmask_0_30(g0_mm[0][30]),
    .io_forwardMmask_0_31(g0_mm[0][31]),
    .io_forwardMmask_0_32(g0_mm[0][32]),
    .io_forwardMmask_0_33(g0_mm[0][33]),
    .io_forwardMmask_0_34(g0_mm[0][34]),
    .io_forwardMmask_0_35(g0_mm[0][35]),
    .io_forwardMmask_0_36(g0_mm[0][36]),
    .io_forwardMmask_0_37(g0_mm[0][37]),
    .io_forwardMmask_0_38(g0_mm[0][38]),
    .io_forwardMmask_0_39(g0_mm[0][39]),
    .io_forwardMmask_0_40(g0_mm[0][40]),
    .io_forwardMmask_0_41(g0_mm[0][41]),
    .io_forwardMmask_0_42(g0_mm[0][42]),
    .io_forwardMmask_0_43(g0_mm[0][43]),
    .io_forwardMmask_0_44(g0_mm[0][44]),
    .io_forwardMmask_0_45(g0_mm[0][45]),
    .io_forwardMmask_0_46(g0_mm[0][46]),
    .io_forwardMmask_0_47(g0_mm[0][47]),
    .io_forwardMmask_0_48(g0_mm[0][48]),
    .io_forwardMmask_0_49(g0_mm[0][49]),
    .io_forwardMmask_0_50(g0_mm[0][50]),
    .io_forwardMmask_0_51(g0_mm[0][51]),
    .io_forwardMmask_0_52(g0_mm[0][52]),
    .io_forwardMmask_0_53(g0_mm[0][53]),
    .io_forwardMmask_0_54(g0_mm[0][54]),
    .io_forwardMmask_0_55(g0_mm[0][55]),
    .io_forwardMmask_1_0(g0_mm[1][0]),
    .io_forwardMmask_1_1(g0_mm[1][1]),
    .io_forwardMmask_1_2(g0_mm[1][2]),
    .io_forwardMmask_1_3(g0_mm[1][3]),
    .io_forwardMmask_1_4(g0_mm[1][4]),
    .io_forwardMmask_1_5(g0_mm[1][5]),
    .io_forwardMmask_1_6(g0_mm[1][6]),
    .io_forwardMmask_1_7(g0_mm[1][7]),
    .io_forwardMmask_1_8(g0_mm[1][8]),
    .io_forwardMmask_1_9(g0_mm[1][9]),
    .io_forwardMmask_1_10(g0_mm[1][10]),
    .io_forwardMmask_1_11(g0_mm[1][11]),
    .io_forwardMmask_1_12(g0_mm[1][12]),
    .io_forwardMmask_1_13(g0_mm[1][13]),
    .io_forwardMmask_1_14(g0_mm[1][14]),
    .io_forwardMmask_1_15(g0_mm[1][15]),
    .io_forwardMmask_1_16(g0_mm[1][16]),
    .io_forwardMmask_1_17(g0_mm[1][17]),
    .io_forwardMmask_1_18(g0_mm[1][18]),
    .io_forwardMmask_1_19(g0_mm[1][19]),
    .io_forwardMmask_1_20(g0_mm[1][20]),
    .io_forwardMmask_1_21(g0_mm[1][21]),
    .io_forwardMmask_1_22(g0_mm[1][22]),
    .io_forwardMmask_1_23(g0_mm[1][23]),
    .io_forwardMmask_1_24(g0_mm[1][24]),
    .io_forwardMmask_1_25(g0_mm[1][25]),
    .io_forwardMmask_1_26(g0_mm[1][26]),
    .io_forwardMmask_1_27(g0_mm[1][27]),
    .io_forwardMmask_1_28(g0_mm[1][28]),
    .io_forwardMmask_1_29(g0_mm[1][29]),
    .io_forwardMmask_1_30(g0_mm[1][30]),
    .io_forwardMmask_1_31(g0_mm[1][31]),
    .io_forwardMmask_1_32(g0_mm[1][32]),
    .io_forwardMmask_1_33(g0_mm[1][33]),
    .io_forwardMmask_1_34(g0_mm[1][34]),
    .io_forwardMmask_1_35(g0_mm[1][35]),
    .io_forwardMmask_1_36(g0_mm[1][36]),
    .io_forwardMmask_1_37(g0_mm[1][37]),
    .io_forwardMmask_1_38(g0_mm[1][38]),
    .io_forwardMmask_1_39(g0_mm[1][39]),
    .io_forwardMmask_1_40(g0_mm[1][40]),
    .io_forwardMmask_1_41(g0_mm[1][41]),
    .io_forwardMmask_1_42(g0_mm[1][42]),
    .io_forwardMmask_1_43(g0_mm[1][43]),
    .io_forwardMmask_1_44(g0_mm[1][44]),
    .io_forwardMmask_1_45(g0_mm[1][45]),
    .io_forwardMmask_1_46(g0_mm[1][46]),
    .io_forwardMmask_1_47(g0_mm[1][47]),
    .io_forwardMmask_1_48(g0_mm[1][48]),
    .io_forwardMmask_1_49(g0_mm[1][49]),
    .io_forwardMmask_1_50(g0_mm[1][50]),
    .io_forwardMmask_1_51(g0_mm[1][51]),
    .io_forwardMmask_1_52(g0_mm[1][52]),
    .io_forwardMmask_1_53(g0_mm[1][53]),
    .io_forwardMmask_1_54(g0_mm[1][54]),
    .io_forwardMmask_1_55(g0_mm[1][55]),
    .io_forwardMmask_2_0(g0_mm[2][0]),
    .io_forwardMmask_2_1(g0_mm[2][1]),
    .io_forwardMmask_2_2(g0_mm[2][2]),
    .io_forwardMmask_2_3(g0_mm[2][3]),
    .io_forwardMmask_2_4(g0_mm[2][4]),
    .io_forwardMmask_2_5(g0_mm[2][5]),
    .io_forwardMmask_2_6(g0_mm[2][6]),
    .io_forwardMmask_2_7(g0_mm[2][7]),
    .io_forwardMmask_2_8(g0_mm[2][8]),
    .io_forwardMmask_2_9(g0_mm[2][9]),
    .io_forwardMmask_2_10(g0_mm[2][10]),
    .io_forwardMmask_2_11(g0_mm[2][11]),
    .io_forwardMmask_2_12(g0_mm[2][12]),
    .io_forwardMmask_2_13(g0_mm[2][13]),
    .io_forwardMmask_2_14(g0_mm[2][14]),
    .io_forwardMmask_2_15(g0_mm[2][15]),
    .io_forwardMmask_2_16(g0_mm[2][16]),
    .io_forwardMmask_2_17(g0_mm[2][17]),
    .io_forwardMmask_2_18(g0_mm[2][18]),
    .io_forwardMmask_2_19(g0_mm[2][19]),
    .io_forwardMmask_2_20(g0_mm[2][20]),
    .io_forwardMmask_2_21(g0_mm[2][21]),
    .io_forwardMmask_2_22(g0_mm[2][22]),
    .io_forwardMmask_2_23(g0_mm[2][23]),
    .io_forwardMmask_2_24(g0_mm[2][24]),
    .io_forwardMmask_2_25(g0_mm[2][25]),
    .io_forwardMmask_2_26(g0_mm[2][26]),
    .io_forwardMmask_2_27(g0_mm[2][27]),
    .io_forwardMmask_2_28(g0_mm[2][28]),
    .io_forwardMmask_2_29(g0_mm[2][29]),
    .io_forwardMmask_2_30(g0_mm[2][30]),
    .io_forwardMmask_2_31(g0_mm[2][31]),
    .io_forwardMmask_2_32(g0_mm[2][32]),
    .io_forwardMmask_2_33(g0_mm[2][33]),
    .io_forwardMmask_2_34(g0_mm[2][34]),
    .io_forwardMmask_2_35(g0_mm[2][35]),
    .io_forwardMmask_2_36(g0_mm[2][36]),
    .io_forwardMmask_2_37(g0_mm[2][37]),
    .io_forwardMmask_2_38(g0_mm[2][38]),
    .io_forwardMmask_2_39(g0_mm[2][39]),
    .io_forwardMmask_2_40(g0_mm[2][40]),
    .io_forwardMmask_2_41(g0_mm[2][41]),
    .io_forwardMmask_2_42(g0_mm[2][42]),
    .io_forwardMmask_2_43(g0_mm[2][43]),
    .io_forwardMmask_2_44(g0_mm[2][44]),
    .io_forwardMmask_2_45(g0_mm[2][45]),
    .io_forwardMmask_2_46(g0_mm[2][46]),
    .io_forwardMmask_2_47(g0_mm[2][47]),
    .io_forwardMmask_2_48(g0_mm[2][48]),
    .io_forwardMmask_2_49(g0_mm[2][49]),
    .io_forwardMmask_2_50(g0_mm[2][50]),
    .io_forwardMmask_2_51(g0_mm[2][51]),
    .io_forwardMmask_2_52(g0_mm[2][52]),
    .io_forwardMmask_2_53(g0_mm[2][53]),
    .io_forwardMmask_2_54(g0_mm[2][54]),
    .io_forwardMmask_2_55(g0_mm[2][55])
  );
  SQAddrModule_xs i_u0 (
    .clock(clk),
    .reset(rst),
    .io_raddr_0(raddr[0]),
    .io_raddr_1(raddr[1]),
    .io_rdata_0(i0_rdata[0]),
    .io_rdata_1(i0_rdata[1]),
    .io_rlineflag_0(i0_rlf[0]),
    .io_rlineflag_1(i0_rlf[1]),
    .io_wen_0(wen[0]),
    .io_wen_1(wen[1]),
    .io_waddr_0(waddr[0]),
    .io_waddr_1(waddr[1]),
    .io_wdata_0(wdata0[0]),
    .io_wdata_1(wdata0[1]),
    .io_wmask_0(wmask[0]),
    .io_wmask_1(wmask[1]),
    .io_wlineflag_0(wlineflag[0]),
    .io_wlineflag_1(wlineflag[1]),
    .io_forwardMdata_0(fmdata0[0]),
    .io_forwardMdata_1(fmdata0[1]),
    .io_forwardMdata_2(fmdata0[2]),
    .io_forwardDataMask_0(fdmask[0]),
    .io_forwardDataMask_1(fdmask[1]),
    .io_forwardDataMask_2(fdmask[2]),
    .io_forwardMmask_0_0(i0_mm[0][0]),
    .io_forwardMmask_0_1(i0_mm[0][1]),
    .io_forwardMmask_0_2(i0_mm[0][2]),
    .io_forwardMmask_0_3(i0_mm[0][3]),
    .io_forwardMmask_0_4(i0_mm[0][4]),
    .io_forwardMmask_0_5(i0_mm[0][5]),
    .io_forwardMmask_0_6(i0_mm[0][6]),
    .io_forwardMmask_0_7(i0_mm[0][7]),
    .io_forwardMmask_0_8(i0_mm[0][8]),
    .io_forwardMmask_0_9(i0_mm[0][9]),
    .io_forwardMmask_0_10(i0_mm[0][10]),
    .io_forwardMmask_0_11(i0_mm[0][11]),
    .io_forwardMmask_0_12(i0_mm[0][12]),
    .io_forwardMmask_0_13(i0_mm[0][13]),
    .io_forwardMmask_0_14(i0_mm[0][14]),
    .io_forwardMmask_0_15(i0_mm[0][15]),
    .io_forwardMmask_0_16(i0_mm[0][16]),
    .io_forwardMmask_0_17(i0_mm[0][17]),
    .io_forwardMmask_0_18(i0_mm[0][18]),
    .io_forwardMmask_0_19(i0_mm[0][19]),
    .io_forwardMmask_0_20(i0_mm[0][20]),
    .io_forwardMmask_0_21(i0_mm[0][21]),
    .io_forwardMmask_0_22(i0_mm[0][22]),
    .io_forwardMmask_0_23(i0_mm[0][23]),
    .io_forwardMmask_0_24(i0_mm[0][24]),
    .io_forwardMmask_0_25(i0_mm[0][25]),
    .io_forwardMmask_0_26(i0_mm[0][26]),
    .io_forwardMmask_0_27(i0_mm[0][27]),
    .io_forwardMmask_0_28(i0_mm[0][28]),
    .io_forwardMmask_0_29(i0_mm[0][29]),
    .io_forwardMmask_0_30(i0_mm[0][30]),
    .io_forwardMmask_0_31(i0_mm[0][31]),
    .io_forwardMmask_0_32(i0_mm[0][32]),
    .io_forwardMmask_0_33(i0_mm[0][33]),
    .io_forwardMmask_0_34(i0_mm[0][34]),
    .io_forwardMmask_0_35(i0_mm[0][35]),
    .io_forwardMmask_0_36(i0_mm[0][36]),
    .io_forwardMmask_0_37(i0_mm[0][37]),
    .io_forwardMmask_0_38(i0_mm[0][38]),
    .io_forwardMmask_0_39(i0_mm[0][39]),
    .io_forwardMmask_0_40(i0_mm[0][40]),
    .io_forwardMmask_0_41(i0_mm[0][41]),
    .io_forwardMmask_0_42(i0_mm[0][42]),
    .io_forwardMmask_0_43(i0_mm[0][43]),
    .io_forwardMmask_0_44(i0_mm[0][44]),
    .io_forwardMmask_0_45(i0_mm[0][45]),
    .io_forwardMmask_0_46(i0_mm[0][46]),
    .io_forwardMmask_0_47(i0_mm[0][47]),
    .io_forwardMmask_0_48(i0_mm[0][48]),
    .io_forwardMmask_0_49(i0_mm[0][49]),
    .io_forwardMmask_0_50(i0_mm[0][50]),
    .io_forwardMmask_0_51(i0_mm[0][51]),
    .io_forwardMmask_0_52(i0_mm[0][52]),
    .io_forwardMmask_0_53(i0_mm[0][53]),
    .io_forwardMmask_0_54(i0_mm[0][54]),
    .io_forwardMmask_0_55(i0_mm[0][55]),
    .io_forwardMmask_1_0(i0_mm[1][0]),
    .io_forwardMmask_1_1(i0_mm[1][1]),
    .io_forwardMmask_1_2(i0_mm[1][2]),
    .io_forwardMmask_1_3(i0_mm[1][3]),
    .io_forwardMmask_1_4(i0_mm[1][4]),
    .io_forwardMmask_1_5(i0_mm[1][5]),
    .io_forwardMmask_1_6(i0_mm[1][6]),
    .io_forwardMmask_1_7(i0_mm[1][7]),
    .io_forwardMmask_1_8(i0_mm[1][8]),
    .io_forwardMmask_1_9(i0_mm[1][9]),
    .io_forwardMmask_1_10(i0_mm[1][10]),
    .io_forwardMmask_1_11(i0_mm[1][11]),
    .io_forwardMmask_1_12(i0_mm[1][12]),
    .io_forwardMmask_1_13(i0_mm[1][13]),
    .io_forwardMmask_1_14(i0_mm[1][14]),
    .io_forwardMmask_1_15(i0_mm[1][15]),
    .io_forwardMmask_1_16(i0_mm[1][16]),
    .io_forwardMmask_1_17(i0_mm[1][17]),
    .io_forwardMmask_1_18(i0_mm[1][18]),
    .io_forwardMmask_1_19(i0_mm[1][19]),
    .io_forwardMmask_1_20(i0_mm[1][20]),
    .io_forwardMmask_1_21(i0_mm[1][21]),
    .io_forwardMmask_1_22(i0_mm[1][22]),
    .io_forwardMmask_1_23(i0_mm[1][23]),
    .io_forwardMmask_1_24(i0_mm[1][24]),
    .io_forwardMmask_1_25(i0_mm[1][25]),
    .io_forwardMmask_1_26(i0_mm[1][26]),
    .io_forwardMmask_1_27(i0_mm[1][27]),
    .io_forwardMmask_1_28(i0_mm[1][28]),
    .io_forwardMmask_1_29(i0_mm[1][29]),
    .io_forwardMmask_1_30(i0_mm[1][30]),
    .io_forwardMmask_1_31(i0_mm[1][31]),
    .io_forwardMmask_1_32(i0_mm[1][32]),
    .io_forwardMmask_1_33(i0_mm[1][33]),
    .io_forwardMmask_1_34(i0_mm[1][34]),
    .io_forwardMmask_1_35(i0_mm[1][35]),
    .io_forwardMmask_1_36(i0_mm[1][36]),
    .io_forwardMmask_1_37(i0_mm[1][37]),
    .io_forwardMmask_1_38(i0_mm[1][38]),
    .io_forwardMmask_1_39(i0_mm[1][39]),
    .io_forwardMmask_1_40(i0_mm[1][40]),
    .io_forwardMmask_1_41(i0_mm[1][41]),
    .io_forwardMmask_1_42(i0_mm[1][42]),
    .io_forwardMmask_1_43(i0_mm[1][43]),
    .io_forwardMmask_1_44(i0_mm[1][44]),
    .io_forwardMmask_1_45(i0_mm[1][45]),
    .io_forwardMmask_1_46(i0_mm[1][46]),
    .io_forwardMmask_1_47(i0_mm[1][47]),
    .io_forwardMmask_1_48(i0_mm[1][48]),
    .io_forwardMmask_1_49(i0_mm[1][49]),
    .io_forwardMmask_1_50(i0_mm[1][50]),
    .io_forwardMmask_1_51(i0_mm[1][51]),
    .io_forwardMmask_1_52(i0_mm[1][52]),
    .io_forwardMmask_1_53(i0_mm[1][53]),
    .io_forwardMmask_1_54(i0_mm[1][54]),
    .io_forwardMmask_1_55(i0_mm[1][55]),
    .io_forwardMmask_2_0(i0_mm[2][0]),
    .io_forwardMmask_2_1(i0_mm[2][1]),
    .io_forwardMmask_2_2(i0_mm[2][2]),
    .io_forwardMmask_2_3(i0_mm[2][3]),
    .io_forwardMmask_2_4(i0_mm[2][4]),
    .io_forwardMmask_2_5(i0_mm[2][5]),
    .io_forwardMmask_2_6(i0_mm[2][6]),
    .io_forwardMmask_2_7(i0_mm[2][7]),
    .io_forwardMmask_2_8(i0_mm[2][8]),
    .io_forwardMmask_2_9(i0_mm[2][9]),
    .io_forwardMmask_2_10(i0_mm[2][10]),
    .io_forwardMmask_2_11(i0_mm[2][11]),
    .io_forwardMmask_2_12(i0_mm[2][12]),
    .io_forwardMmask_2_13(i0_mm[2][13]),
    .io_forwardMmask_2_14(i0_mm[2][14]),
    .io_forwardMmask_2_15(i0_mm[2][15]),
    .io_forwardMmask_2_16(i0_mm[2][16]),
    .io_forwardMmask_2_17(i0_mm[2][17]),
    .io_forwardMmask_2_18(i0_mm[2][18]),
    .io_forwardMmask_2_19(i0_mm[2][19]),
    .io_forwardMmask_2_20(i0_mm[2][20]),
    .io_forwardMmask_2_21(i0_mm[2][21]),
    .io_forwardMmask_2_22(i0_mm[2][22]),
    .io_forwardMmask_2_23(i0_mm[2][23]),
    .io_forwardMmask_2_24(i0_mm[2][24]),
    .io_forwardMmask_2_25(i0_mm[2][25]),
    .io_forwardMmask_2_26(i0_mm[2][26]),
    .io_forwardMmask_2_27(i0_mm[2][27]),
    .io_forwardMmask_2_28(i0_mm[2][28]),
    .io_forwardMmask_2_29(i0_mm[2][29]),
    .io_forwardMmask_2_30(i0_mm[2][30]),
    .io_forwardMmask_2_31(i0_mm[2][31]),
    .io_forwardMmask_2_32(i0_mm[2][32]),
    .io_forwardMmask_2_33(i0_mm[2][33]),
    .io_forwardMmask_2_34(i0_mm[2][34]),
    .io_forwardMmask_2_35(i0_mm[2][35]),
    .io_forwardMmask_2_36(i0_mm[2][36]),
    .io_forwardMmask_2_37(i0_mm[2][37]),
    .io_forwardMmask_2_38(i0_mm[2][38]),
    .io_forwardMmask_2_39(i0_mm[2][39]),
    .io_forwardMmask_2_40(i0_mm[2][40]),
    .io_forwardMmask_2_41(i0_mm[2][41]),
    .io_forwardMmask_2_42(i0_mm[2][42]),
    .io_forwardMmask_2_43(i0_mm[2][43]),
    .io_forwardMmask_2_44(i0_mm[2][44]),
    .io_forwardMmask_2_45(i0_mm[2][45]),
    .io_forwardMmask_2_46(i0_mm[2][46]),
    .io_forwardMmask_2_47(i0_mm[2][47]),
    .io_forwardMmask_2_48(i0_mm[2][48]),
    .io_forwardMmask_2_49(i0_mm[2][49]),
    .io_forwardMmask_2_50(i0_mm[2][50]),
    .io_forwardMmask_2_51(i0_mm[2][51]),
    .io_forwardMmask_2_52(i0_mm[2][52]),
    .io_forwardMmask_2_53(i0_mm[2][53]),
    .io_forwardMmask_2_54(i0_mm[2][54]),
    .io_forwardMmask_2_55(i0_mm[2][55])
  );
  SQAddrModule_1 g_u1 (
    .clock(clk),
    .reset(rst),
    .io_raddr_0(raddr[0]),
    .io_raddr_1(raddr[1]),
    .io_rdata_0(g1_rdata[0]),
    .io_rdata_1(g1_rdata[1]),
    .io_wen_0(wen[0]),
    .io_wen_1(wen[1]),
    .io_waddr_0(waddr[0]),
    .io_waddr_1(waddr[1]),
    .io_wdata_0(wdata1[0]),
    .io_wdata_1(wdata1[1]),
    .io_wmask_0(wmask[0]),
    .io_wmask_1(wmask[1]),
    .io_wlineflag_0(wlineflag[0]),
    .io_wlineflag_1(wlineflag[1]),
    .io_forwardMdata_0(fmdata1[0]),
    .io_forwardMdata_1(fmdata1[1]),
    .io_forwardMdata_2(fmdata1[2]),
    .io_forwardDataMask_0(fdmask[0]),
    .io_forwardDataMask_1(fdmask[1]),
    .io_forwardDataMask_2(fdmask[2]),
    .io_forwardMmask_0_0(g1_mm[0][0]),
    .io_forwardMmask_0_1(g1_mm[0][1]),
    .io_forwardMmask_0_2(g1_mm[0][2]),
    .io_forwardMmask_0_3(g1_mm[0][3]),
    .io_forwardMmask_0_4(g1_mm[0][4]),
    .io_forwardMmask_0_5(g1_mm[0][5]),
    .io_forwardMmask_0_6(g1_mm[0][6]),
    .io_forwardMmask_0_7(g1_mm[0][7]),
    .io_forwardMmask_0_8(g1_mm[0][8]),
    .io_forwardMmask_0_9(g1_mm[0][9]),
    .io_forwardMmask_0_10(g1_mm[0][10]),
    .io_forwardMmask_0_11(g1_mm[0][11]),
    .io_forwardMmask_0_12(g1_mm[0][12]),
    .io_forwardMmask_0_13(g1_mm[0][13]),
    .io_forwardMmask_0_14(g1_mm[0][14]),
    .io_forwardMmask_0_15(g1_mm[0][15]),
    .io_forwardMmask_0_16(g1_mm[0][16]),
    .io_forwardMmask_0_17(g1_mm[0][17]),
    .io_forwardMmask_0_18(g1_mm[0][18]),
    .io_forwardMmask_0_19(g1_mm[0][19]),
    .io_forwardMmask_0_20(g1_mm[0][20]),
    .io_forwardMmask_0_21(g1_mm[0][21]),
    .io_forwardMmask_0_22(g1_mm[0][22]),
    .io_forwardMmask_0_23(g1_mm[0][23]),
    .io_forwardMmask_0_24(g1_mm[0][24]),
    .io_forwardMmask_0_25(g1_mm[0][25]),
    .io_forwardMmask_0_26(g1_mm[0][26]),
    .io_forwardMmask_0_27(g1_mm[0][27]),
    .io_forwardMmask_0_28(g1_mm[0][28]),
    .io_forwardMmask_0_29(g1_mm[0][29]),
    .io_forwardMmask_0_30(g1_mm[0][30]),
    .io_forwardMmask_0_31(g1_mm[0][31]),
    .io_forwardMmask_0_32(g1_mm[0][32]),
    .io_forwardMmask_0_33(g1_mm[0][33]),
    .io_forwardMmask_0_34(g1_mm[0][34]),
    .io_forwardMmask_0_35(g1_mm[0][35]),
    .io_forwardMmask_0_36(g1_mm[0][36]),
    .io_forwardMmask_0_37(g1_mm[0][37]),
    .io_forwardMmask_0_38(g1_mm[0][38]),
    .io_forwardMmask_0_39(g1_mm[0][39]),
    .io_forwardMmask_0_40(g1_mm[0][40]),
    .io_forwardMmask_0_41(g1_mm[0][41]),
    .io_forwardMmask_0_42(g1_mm[0][42]),
    .io_forwardMmask_0_43(g1_mm[0][43]),
    .io_forwardMmask_0_44(g1_mm[0][44]),
    .io_forwardMmask_0_45(g1_mm[0][45]),
    .io_forwardMmask_0_46(g1_mm[0][46]),
    .io_forwardMmask_0_47(g1_mm[0][47]),
    .io_forwardMmask_0_48(g1_mm[0][48]),
    .io_forwardMmask_0_49(g1_mm[0][49]),
    .io_forwardMmask_0_50(g1_mm[0][50]),
    .io_forwardMmask_0_51(g1_mm[0][51]),
    .io_forwardMmask_0_52(g1_mm[0][52]),
    .io_forwardMmask_0_53(g1_mm[0][53]),
    .io_forwardMmask_0_54(g1_mm[0][54]),
    .io_forwardMmask_0_55(g1_mm[0][55]),
    .io_forwardMmask_1_0(g1_mm[1][0]),
    .io_forwardMmask_1_1(g1_mm[1][1]),
    .io_forwardMmask_1_2(g1_mm[1][2]),
    .io_forwardMmask_1_3(g1_mm[1][3]),
    .io_forwardMmask_1_4(g1_mm[1][4]),
    .io_forwardMmask_1_5(g1_mm[1][5]),
    .io_forwardMmask_1_6(g1_mm[1][6]),
    .io_forwardMmask_1_7(g1_mm[1][7]),
    .io_forwardMmask_1_8(g1_mm[1][8]),
    .io_forwardMmask_1_9(g1_mm[1][9]),
    .io_forwardMmask_1_10(g1_mm[1][10]),
    .io_forwardMmask_1_11(g1_mm[1][11]),
    .io_forwardMmask_1_12(g1_mm[1][12]),
    .io_forwardMmask_1_13(g1_mm[1][13]),
    .io_forwardMmask_1_14(g1_mm[1][14]),
    .io_forwardMmask_1_15(g1_mm[1][15]),
    .io_forwardMmask_1_16(g1_mm[1][16]),
    .io_forwardMmask_1_17(g1_mm[1][17]),
    .io_forwardMmask_1_18(g1_mm[1][18]),
    .io_forwardMmask_1_19(g1_mm[1][19]),
    .io_forwardMmask_1_20(g1_mm[1][20]),
    .io_forwardMmask_1_21(g1_mm[1][21]),
    .io_forwardMmask_1_22(g1_mm[1][22]),
    .io_forwardMmask_1_23(g1_mm[1][23]),
    .io_forwardMmask_1_24(g1_mm[1][24]),
    .io_forwardMmask_1_25(g1_mm[1][25]),
    .io_forwardMmask_1_26(g1_mm[1][26]),
    .io_forwardMmask_1_27(g1_mm[1][27]),
    .io_forwardMmask_1_28(g1_mm[1][28]),
    .io_forwardMmask_1_29(g1_mm[1][29]),
    .io_forwardMmask_1_30(g1_mm[1][30]),
    .io_forwardMmask_1_31(g1_mm[1][31]),
    .io_forwardMmask_1_32(g1_mm[1][32]),
    .io_forwardMmask_1_33(g1_mm[1][33]),
    .io_forwardMmask_1_34(g1_mm[1][34]),
    .io_forwardMmask_1_35(g1_mm[1][35]),
    .io_forwardMmask_1_36(g1_mm[1][36]),
    .io_forwardMmask_1_37(g1_mm[1][37]),
    .io_forwardMmask_1_38(g1_mm[1][38]),
    .io_forwardMmask_1_39(g1_mm[1][39]),
    .io_forwardMmask_1_40(g1_mm[1][40]),
    .io_forwardMmask_1_41(g1_mm[1][41]),
    .io_forwardMmask_1_42(g1_mm[1][42]),
    .io_forwardMmask_1_43(g1_mm[1][43]),
    .io_forwardMmask_1_44(g1_mm[1][44]),
    .io_forwardMmask_1_45(g1_mm[1][45]),
    .io_forwardMmask_1_46(g1_mm[1][46]),
    .io_forwardMmask_1_47(g1_mm[1][47]),
    .io_forwardMmask_1_48(g1_mm[1][48]),
    .io_forwardMmask_1_49(g1_mm[1][49]),
    .io_forwardMmask_1_50(g1_mm[1][50]),
    .io_forwardMmask_1_51(g1_mm[1][51]),
    .io_forwardMmask_1_52(g1_mm[1][52]),
    .io_forwardMmask_1_53(g1_mm[1][53]),
    .io_forwardMmask_1_54(g1_mm[1][54]),
    .io_forwardMmask_1_55(g1_mm[1][55]),
    .io_forwardMmask_2_0(g1_mm[2][0]),
    .io_forwardMmask_2_1(g1_mm[2][1]),
    .io_forwardMmask_2_2(g1_mm[2][2]),
    .io_forwardMmask_2_3(g1_mm[2][3]),
    .io_forwardMmask_2_4(g1_mm[2][4]),
    .io_forwardMmask_2_5(g1_mm[2][5]),
    .io_forwardMmask_2_6(g1_mm[2][6]),
    .io_forwardMmask_2_7(g1_mm[2][7]),
    .io_forwardMmask_2_8(g1_mm[2][8]),
    .io_forwardMmask_2_9(g1_mm[2][9]),
    .io_forwardMmask_2_10(g1_mm[2][10]),
    .io_forwardMmask_2_11(g1_mm[2][11]),
    .io_forwardMmask_2_12(g1_mm[2][12]),
    .io_forwardMmask_2_13(g1_mm[2][13]),
    .io_forwardMmask_2_14(g1_mm[2][14]),
    .io_forwardMmask_2_15(g1_mm[2][15]),
    .io_forwardMmask_2_16(g1_mm[2][16]),
    .io_forwardMmask_2_17(g1_mm[2][17]),
    .io_forwardMmask_2_18(g1_mm[2][18]),
    .io_forwardMmask_2_19(g1_mm[2][19]),
    .io_forwardMmask_2_20(g1_mm[2][20]),
    .io_forwardMmask_2_21(g1_mm[2][21]),
    .io_forwardMmask_2_22(g1_mm[2][22]),
    .io_forwardMmask_2_23(g1_mm[2][23]),
    .io_forwardMmask_2_24(g1_mm[2][24]),
    .io_forwardMmask_2_25(g1_mm[2][25]),
    .io_forwardMmask_2_26(g1_mm[2][26]),
    .io_forwardMmask_2_27(g1_mm[2][27]),
    .io_forwardMmask_2_28(g1_mm[2][28]),
    .io_forwardMmask_2_29(g1_mm[2][29]),
    .io_forwardMmask_2_30(g1_mm[2][30]),
    .io_forwardMmask_2_31(g1_mm[2][31]),
    .io_forwardMmask_2_32(g1_mm[2][32]),
    .io_forwardMmask_2_33(g1_mm[2][33]),
    .io_forwardMmask_2_34(g1_mm[2][34]),
    .io_forwardMmask_2_35(g1_mm[2][35]),
    .io_forwardMmask_2_36(g1_mm[2][36]),
    .io_forwardMmask_2_37(g1_mm[2][37]),
    .io_forwardMmask_2_38(g1_mm[2][38]),
    .io_forwardMmask_2_39(g1_mm[2][39]),
    .io_forwardMmask_2_40(g1_mm[2][40]),
    .io_forwardMmask_2_41(g1_mm[2][41]),
    .io_forwardMmask_2_42(g1_mm[2][42]),
    .io_forwardMmask_2_43(g1_mm[2][43]),
    .io_forwardMmask_2_44(g1_mm[2][44]),
    .io_forwardMmask_2_45(g1_mm[2][45]),
    .io_forwardMmask_2_46(g1_mm[2][46]),
    .io_forwardMmask_2_47(g1_mm[2][47]),
    .io_forwardMmask_2_48(g1_mm[2][48]),
    .io_forwardMmask_2_49(g1_mm[2][49]),
    .io_forwardMmask_2_50(g1_mm[2][50]),
    .io_forwardMmask_2_51(g1_mm[2][51]),
    .io_forwardMmask_2_52(g1_mm[2][52]),
    .io_forwardMmask_2_53(g1_mm[2][53]),
    .io_forwardMmask_2_54(g1_mm[2][54]),
    .io_forwardMmask_2_55(g1_mm[2][55])
  );
  SQAddrModule_1_xs i_u1 (
    .clock(clk),
    .reset(rst),
    .io_raddr_0(raddr[0]),
    .io_raddr_1(raddr[1]),
    .io_rdata_0(i1_rdata[0]),
    .io_rdata_1(i1_rdata[1]),
    .io_wen_0(wen[0]),
    .io_wen_1(wen[1]),
    .io_waddr_0(waddr[0]),
    .io_waddr_1(waddr[1]),
    .io_wdata_0(wdata1[0]),
    .io_wdata_1(wdata1[1]),
    .io_wmask_0(wmask[0]),
    .io_wmask_1(wmask[1]),
    .io_wlineflag_0(wlineflag[0]),
    .io_wlineflag_1(wlineflag[1]),
    .io_forwardMdata_0(fmdata1[0]),
    .io_forwardMdata_1(fmdata1[1]),
    .io_forwardMdata_2(fmdata1[2]),
    .io_forwardDataMask_0(fdmask[0]),
    .io_forwardDataMask_1(fdmask[1]),
    .io_forwardDataMask_2(fdmask[2]),
    .io_forwardMmask_0_0(i1_mm[0][0]),
    .io_forwardMmask_0_1(i1_mm[0][1]),
    .io_forwardMmask_0_2(i1_mm[0][2]),
    .io_forwardMmask_0_3(i1_mm[0][3]),
    .io_forwardMmask_0_4(i1_mm[0][4]),
    .io_forwardMmask_0_5(i1_mm[0][5]),
    .io_forwardMmask_0_6(i1_mm[0][6]),
    .io_forwardMmask_0_7(i1_mm[0][7]),
    .io_forwardMmask_0_8(i1_mm[0][8]),
    .io_forwardMmask_0_9(i1_mm[0][9]),
    .io_forwardMmask_0_10(i1_mm[0][10]),
    .io_forwardMmask_0_11(i1_mm[0][11]),
    .io_forwardMmask_0_12(i1_mm[0][12]),
    .io_forwardMmask_0_13(i1_mm[0][13]),
    .io_forwardMmask_0_14(i1_mm[0][14]),
    .io_forwardMmask_0_15(i1_mm[0][15]),
    .io_forwardMmask_0_16(i1_mm[0][16]),
    .io_forwardMmask_0_17(i1_mm[0][17]),
    .io_forwardMmask_0_18(i1_mm[0][18]),
    .io_forwardMmask_0_19(i1_mm[0][19]),
    .io_forwardMmask_0_20(i1_mm[0][20]),
    .io_forwardMmask_0_21(i1_mm[0][21]),
    .io_forwardMmask_0_22(i1_mm[0][22]),
    .io_forwardMmask_0_23(i1_mm[0][23]),
    .io_forwardMmask_0_24(i1_mm[0][24]),
    .io_forwardMmask_0_25(i1_mm[0][25]),
    .io_forwardMmask_0_26(i1_mm[0][26]),
    .io_forwardMmask_0_27(i1_mm[0][27]),
    .io_forwardMmask_0_28(i1_mm[0][28]),
    .io_forwardMmask_0_29(i1_mm[0][29]),
    .io_forwardMmask_0_30(i1_mm[0][30]),
    .io_forwardMmask_0_31(i1_mm[0][31]),
    .io_forwardMmask_0_32(i1_mm[0][32]),
    .io_forwardMmask_0_33(i1_mm[0][33]),
    .io_forwardMmask_0_34(i1_mm[0][34]),
    .io_forwardMmask_0_35(i1_mm[0][35]),
    .io_forwardMmask_0_36(i1_mm[0][36]),
    .io_forwardMmask_0_37(i1_mm[0][37]),
    .io_forwardMmask_0_38(i1_mm[0][38]),
    .io_forwardMmask_0_39(i1_mm[0][39]),
    .io_forwardMmask_0_40(i1_mm[0][40]),
    .io_forwardMmask_0_41(i1_mm[0][41]),
    .io_forwardMmask_0_42(i1_mm[0][42]),
    .io_forwardMmask_0_43(i1_mm[0][43]),
    .io_forwardMmask_0_44(i1_mm[0][44]),
    .io_forwardMmask_0_45(i1_mm[0][45]),
    .io_forwardMmask_0_46(i1_mm[0][46]),
    .io_forwardMmask_0_47(i1_mm[0][47]),
    .io_forwardMmask_0_48(i1_mm[0][48]),
    .io_forwardMmask_0_49(i1_mm[0][49]),
    .io_forwardMmask_0_50(i1_mm[0][50]),
    .io_forwardMmask_0_51(i1_mm[0][51]),
    .io_forwardMmask_0_52(i1_mm[0][52]),
    .io_forwardMmask_0_53(i1_mm[0][53]),
    .io_forwardMmask_0_54(i1_mm[0][54]),
    .io_forwardMmask_0_55(i1_mm[0][55]),
    .io_forwardMmask_1_0(i1_mm[1][0]),
    .io_forwardMmask_1_1(i1_mm[1][1]),
    .io_forwardMmask_1_2(i1_mm[1][2]),
    .io_forwardMmask_1_3(i1_mm[1][3]),
    .io_forwardMmask_1_4(i1_mm[1][4]),
    .io_forwardMmask_1_5(i1_mm[1][5]),
    .io_forwardMmask_1_6(i1_mm[1][6]),
    .io_forwardMmask_1_7(i1_mm[1][7]),
    .io_forwardMmask_1_8(i1_mm[1][8]),
    .io_forwardMmask_1_9(i1_mm[1][9]),
    .io_forwardMmask_1_10(i1_mm[1][10]),
    .io_forwardMmask_1_11(i1_mm[1][11]),
    .io_forwardMmask_1_12(i1_mm[1][12]),
    .io_forwardMmask_1_13(i1_mm[1][13]),
    .io_forwardMmask_1_14(i1_mm[1][14]),
    .io_forwardMmask_1_15(i1_mm[1][15]),
    .io_forwardMmask_1_16(i1_mm[1][16]),
    .io_forwardMmask_1_17(i1_mm[1][17]),
    .io_forwardMmask_1_18(i1_mm[1][18]),
    .io_forwardMmask_1_19(i1_mm[1][19]),
    .io_forwardMmask_1_20(i1_mm[1][20]),
    .io_forwardMmask_1_21(i1_mm[1][21]),
    .io_forwardMmask_1_22(i1_mm[1][22]),
    .io_forwardMmask_1_23(i1_mm[1][23]),
    .io_forwardMmask_1_24(i1_mm[1][24]),
    .io_forwardMmask_1_25(i1_mm[1][25]),
    .io_forwardMmask_1_26(i1_mm[1][26]),
    .io_forwardMmask_1_27(i1_mm[1][27]),
    .io_forwardMmask_1_28(i1_mm[1][28]),
    .io_forwardMmask_1_29(i1_mm[1][29]),
    .io_forwardMmask_1_30(i1_mm[1][30]),
    .io_forwardMmask_1_31(i1_mm[1][31]),
    .io_forwardMmask_1_32(i1_mm[1][32]),
    .io_forwardMmask_1_33(i1_mm[1][33]),
    .io_forwardMmask_1_34(i1_mm[1][34]),
    .io_forwardMmask_1_35(i1_mm[1][35]),
    .io_forwardMmask_1_36(i1_mm[1][36]),
    .io_forwardMmask_1_37(i1_mm[1][37]),
    .io_forwardMmask_1_38(i1_mm[1][38]),
    .io_forwardMmask_1_39(i1_mm[1][39]),
    .io_forwardMmask_1_40(i1_mm[1][40]),
    .io_forwardMmask_1_41(i1_mm[1][41]),
    .io_forwardMmask_1_42(i1_mm[1][42]),
    .io_forwardMmask_1_43(i1_mm[1][43]),
    .io_forwardMmask_1_44(i1_mm[1][44]),
    .io_forwardMmask_1_45(i1_mm[1][45]),
    .io_forwardMmask_1_46(i1_mm[1][46]),
    .io_forwardMmask_1_47(i1_mm[1][47]),
    .io_forwardMmask_1_48(i1_mm[1][48]),
    .io_forwardMmask_1_49(i1_mm[1][49]),
    .io_forwardMmask_1_50(i1_mm[1][50]),
    .io_forwardMmask_1_51(i1_mm[1][51]),
    .io_forwardMmask_1_52(i1_mm[1][52]),
    .io_forwardMmask_1_53(i1_mm[1][53]),
    .io_forwardMmask_1_54(i1_mm[1][54]),
    .io_forwardMmask_1_55(i1_mm[1][55]),
    .io_forwardMmask_2_0(i1_mm[2][0]),
    .io_forwardMmask_2_1(i1_mm[2][1]),
    .io_forwardMmask_2_2(i1_mm[2][2]),
    .io_forwardMmask_2_3(i1_mm[2][3]),
    .io_forwardMmask_2_4(i1_mm[2][4]),
    .io_forwardMmask_2_5(i1_mm[2][5]),
    .io_forwardMmask_2_6(i1_mm[2][6]),
    .io_forwardMmask_2_7(i1_mm[2][7]),
    .io_forwardMmask_2_8(i1_mm[2][8]),
    .io_forwardMmask_2_9(i1_mm[2][9]),
    .io_forwardMmask_2_10(i1_mm[2][10]),
    .io_forwardMmask_2_11(i1_mm[2][11]),
    .io_forwardMmask_2_12(i1_mm[2][12]),
    .io_forwardMmask_2_13(i1_mm[2][13]),
    .io_forwardMmask_2_14(i1_mm[2][14]),
    .io_forwardMmask_2_15(i1_mm[2][15]),
    .io_forwardMmask_2_16(i1_mm[2][16]),
    .io_forwardMmask_2_17(i1_mm[2][17]),
    .io_forwardMmask_2_18(i1_mm[2][18]),
    .io_forwardMmask_2_19(i1_mm[2][19]),
    .io_forwardMmask_2_20(i1_mm[2][20]),
    .io_forwardMmask_2_21(i1_mm[2][21]),
    .io_forwardMmask_2_22(i1_mm[2][22]),
    .io_forwardMmask_2_23(i1_mm[2][23]),
    .io_forwardMmask_2_24(i1_mm[2][24]),
    .io_forwardMmask_2_25(i1_mm[2][25]),
    .io_forwardMmask_2_26(i1_mm[2][26]),
    .io_forwardMmask_2_27(i1_mm[2][27]),
    .io_forwardMmask_2_28(i1_mm[2][28]),
    .io_forwardMmask_2_29(i1_mm[2][29]),
    .io_forwardMmask_2_30(i1_mm[2][30]),
    .io_forwardMmask_2_31(i1_mm[2][31]),
    .io_forwardMmask_2_32(i1_mm[2][32]),
    .io_forwardMmask_2_33(i1_mm[2][33]),
    .io_forwardMmask_2_34(i1_mm[2][34]),
    .io_forwardMmask_2_35(i1_mm[2][35]),
    .io_forwardMmask_2_36(i1_mm[2][36]),
    .io_forwardMmask_2_37(i1_mm[2][37]),
    .io_forwardMmask_2_38(i1_mm[2][38]),
    .io_forwardMmask_2_39(i1_mm[2][39]),
    .io_forwardMmask_2_40(i1_mm[2][40]),
    .io_forwardMmask_2_41(i1_mm[2][41]),
    .io_forwardMmask_2_42(i1_mm[2][42]),
    .io_forwardMmask_2_43(i1_mm[2][43]),
    .io_forwardMmask_2_44(i1_mm[2][44]),
    .io_forwardMmask_2_45(i1_mm[2][45]),
    .io_forwardMmask_2_46(i1_mm[2][46]),
    .io_forwardMmask_2_47(i1_mm[2][47]),
    .io_forwardMmask_2_48(i1_mm[2][48]),
    .io_forwardMmask_2_49(i1_mm[2][49]),
    .io_forwardMmask_2_50(i1_mm[2][50]),
    .io_forwardMmask_2_51(i1_mm[2][51]),
    .io_forwardMmask_2_52(i1_mm[2][52]),
    .io_forwardMmask_2_53(i1_mm[2][53]),
    .io_forwardMmask_2_54(i1_mm[2][54]),
    .io_forwardMmask_2_55(i1_mm[2][55])
  );

  // ---------------------------------------------------------------------------
  // 地址产生:小池子保证 CAM 常命中
  // ---------------------------------------------------------------------------
  // 地址布局 [DW-1:6]=line 号 | [5:4]=vword 号 | [3:0]=字节偏移
  // line 号只从 6 个值里挑 → 高位频繁相等 → linehit 真的发生。
  localparam int NLINE = 6;
  logic [W0-7:0] line_pool0 [NLINE];
  logic [W1-7:0] line_pool1 [NLINE];

  function automatic logic [W0-1:0] mk_addr0(input int li, input int vw, input int bo);
    return {line_pool0[li], 2'(vw), 4'(bo)};
  endfunction
  function automatic logic [W1-1:0] mk_addr1(input int li, input int vw, input int bo);
    return {line_pool1[li], 2'(vw), 4'(bo)};
  endfunction

  // 稀疏字节掩码:让"同 line 同 vword 但字节无交集"这一类真的出现(B3)。
  function automatic logic [15:0] mk_bmask();
    int r; logic [15:0] m;
    r = $urandom_range(0, 99); m = '0;
    if (r < 30)      m = 16'h1 << $urandom_range(0, 15);   // 单字节
    else if (r < 50) m = 16'h000F << (4 * $urandom_range(0, 3));
    else if (r < 60) m = '1;
    else if (r < 65) m = '0;
    else             m = 16'($urandom);
    return m;
  endfunction

  function automatic logic [5:0] pick_addr();
    int r;
    r = $urandom_range(0, 99);
    if (r < 8)       return 6'(56 + $urandom_range(0, 7));   // B4 越界
    else if (r < 45) return 6'($urandom_range(0, 7));
    else if (r < 70) return 6'(48 + $urandom_range(0, 7));
    else             return 6'($urandom_range(0, 55));
  endfunction

  // ---------------------------------------------------------------------------
  int cov_cam_hit = 0, cov_lineflag_hit = 0, cov_mask_disjoint = 0;
  int cov_oob_read = 0, cov_wr_collide = 0, cov_mid_reset = 0, cov_cam_miss = 0;

  bit warm = 1;
  int warm_i = 0;

  always @(negedge clk) begin
    if (rst) begin
      for (int w = 0; w < NW; w++) begin
        wen[w] <= 1'b0; waddr[w] <= '0; wmask[w] <= '0; wlineflag[w] <= 1'b0;
        wdata0[w] <= '0; wdata1[w] <= '0;
      end
      for (int r = 0; r < NR; r++) raddr[r] <= '0;
      for (int f = 0; f < NF; f++) begin fdmask[f] <= '0; fmdata0[f] <= '0; fmdata1[f] <= '0; end
      // 中途复位不重做预热:阵列不复位。
      if (warm_i < NE) begin warm_i <= 0; warm <= 1; end
    end else if (warm_i < NE) begin
      // 预热:把 data/mask/lineflag 共 168 个不复位寄存器全部写一遍
      wen[0] <= 1'b1; waddr[0] <= 6'(warm_i);
      wdata0[0] <= mk_addr0($urandom_range(0, NLINE-1), $urandom_range(0,3), $urandom_range(0,15));
      wdata1[0] <= mk_addr1($urandom_range(0, NLINE-1), $urandom_range(0,3), $urandom_range(0,15));
      wmask[0] <= mk_bmask();
      wlineflag[0] <= ($urandom_range(0, 99) < 20);   // 约 20% 是整行写
      wen[1] <= 1'b0;
      for (int r = 0; r < NR; r++) raddr[r] <= '0;
      warm_i <= warm_i + 1;
    end else begin
      if (warm_i < NE + 2) warm_i <= warm_i + 1; else warm <= 0;

      for (int w = 0; w < NW; w++) begin
        wen[w]       <= $urandom_range(0, 1);
        wdata0[w]    <= mk_addr0($urandom_range(0, NLINE-1), $urandom_range(0,3), $urandom_range(0,15));
        wdata1[w]    <= mk_addr1($urandom_range(0, NLINE-1), $urandom_range(0,3), $urandom_range(0,15));
        wmask[w]     <= mk_bmask();
        wlineflag[w] <= ($urandom_range(0, 99) < 20);   // B2
      end
      waddr[0] <= pick_addr();
      // ★ B5:约 8% 的拍子两个写口撞同址,专门打优先级 ★
      if ($urandom_range(0, 99) < 8) waddr[1] <= waddr[0];
      else                           waddr[1] <= pick_addr();

      for (int r = 0; r < NR; r++) raddr[r] <= pick_addr();

      // 前递查询地址同样出自小池子 → B1 命中真的发生
      for (int f = 0; f < NF; f++) begin
        fmdata0[f] <= mk_addr0($urandom_range(0, NLINE-1), $urandom_range(0,3), $urandom_range(0,15));
        fmdata1[f] <= mk_addr1($urandom_range(0, NLINE-1), $urandom_range(0,3), $urandom_range(0,15));
        fdmask[f]  <= mk_bmask();
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 覆盖统计
  // ---------------------------------------------------------------------------
  always @(posedge clk) if (!rst && !warm) begin
    for (int r = 0; r < NR; r++) if (raddr[r] >= 56) cov_oob_read++;
    if (wen[0] && wen[1] && waddr[0] == waddr[1]) cov_wr_collide++;
    for (int f = 0; f < NF; f++) begin
      if (|g0_mm[f]) cov_cam_hit++; else cov_cam_miss++;
      for (int e = 0; e < NE; e++) begin
        // B2:命中且该条目是整行写
        if (g0_mm[f][e] && g_u0.lineflag_0 !== 1'bx && e == 0 && g_u0.lineflag_0) cov_lineflag_hit++;
        // B3:同 line 同 vword 但字节掩码无交集 → 必须不命中(除非 lineflag)
        if (e == 0 &&
            fmdata0[f][W0-1:6] == g_u0.data_0[W0-1:6] &&
            fmdata0[f][5:4]    == g_u0.data_0[5:4] &&
            (g_u0.mask_0 & fdmask[f]) == '0 && !g_u0.lineflag_0)
          cov_mask_disjoint++;
      end
    end
  end

  // ---------------------------------------------------------------------------
  `define CK(nm, g, i) \
    begin checks++; \
      if ((g) !== (i)) begin errors++; \
        if (errors <= 60) $display("[%0t] %s g=%h i=%h", $time, nm, (g), (i)); end end

  always @(negedge clk) if (!rst && !warm) begin
    #4;
    for (int r = 0; r < NR; r++) begin
      `CK($sformatf("v0.rdata[%0d]", r), g0_rdata[r], i0_rdata[r])
      `CK($sformatf("v0.rlineflag[%0d]", r), g0_rlf[r], i0_rlf[r])
      `CK($sformatf("v1.rdata[%0d]", r), g1_rdata[r], i1_rdata[r])
    end
    for (int f = 0; f < NF; f++) begin
      `CK($sformatf("v0.mmask[%0d]", f), g0_mm[f], i0_mm[f])
      `CK($sformatf("v1.mmask[%0d]", f), g1_mm[f], i1_mm[f])
    end
    // 内部状态:阵列(不复位)与两份读地址寄存器(异步复位,且**必须是两份**)
    `CK("v0.data_0",    g_u0.data_0,    i_u0.u_core.data[0])
    `CK("v0.mask_0",    g_u0.mask_0,    i_u0.u_core.mask[0])
    `CK("v0.lineflag0", g_u0.lineflag_0,i_u0.u_core.lineflag[0])
    `CK("v0.data_55",   g_u0.data_55,   i_u0.u_core.data[55])
    `CK("v0.rdaddr0",   g_u0.io_rdata_0_next_r,     i_u0.u_core.rdata_addr_r[0])
    `CK("v0.rlfaddr0",  g_u0.io_rlineflag_0_next_r, i_u0.u_core.g_rlineflag.rlineflag_addr_r[0])
    `CK("v1.data_0",    g_u1.data_0,    i_u1.u_core.data[0])
    `CK("v1.lineflag0", g_u1.lineflag_0,i_u1.u_core.lineflag[0])
    `CK("v1.rdaddr0",   g_u1.io_rdata_0_next_r,     i_u1.u_core.rdata_addr_r[0])
  end

  // ---------------------------------------------------------------------------
  initial begin
    for (int k = 0; k < NLINE; k++) begin
      line_pool0[k] = (W0-6)'($urandom);
      line_pool1[k] = (W1-6)'($urandom);
    end
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    fork
      forever begin   // ★ B6 中途复位脉冲 ★
        repeat (2800 + $urandom_range(0, 400)) @(posedge clk);
        rst = 1; cov_mid_reset++; repeat (2) @(posedge clk); rst = 0;
      end
    join_none
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("COVERAGE cam_hit=%0d cam_miss=%0d lineflag_hit=%0d mask_disjoint=%0d",
             cov_cam_hit, cov_cam_miss, cov_lineflag_hit, cov_mask_disjoint);
    $display("COVERAGE oob_read=%0d wr_collide=%0d mid_reset=%0d",
             cov_oob_read, cov_wr_collide, cov_mid_reset);
    if (errors == 0 && checks > 1000 &&
        cov_cam_hit > 100 && cov_cam_miss > 100 && cov_lineflag_hit > 10 &&
        cov_mask_disjoint > 10 && cov_oob_read > 100 && cov_wr_collide > 100 &&
        cov_mid_reset > 2)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
