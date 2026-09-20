// ============================================================================
// tb —— WBArbiter 家族 UT：13 个 golden 变体与重写件逐拍双例化比对。
//
// 本族 = 反饥饿计数级 + 固定优先级级。反饥饿级是整个模块唯一的状态，
// 所以「测到位」的核心判据是**每一路都真的饿到过 isFull**（只看 ready/valid
// 取遍 0/1 证明不了反饥饿那一半存在）。
//
// ★但「每一路」要先问清楚哪些路**够得着**★。把 golden 的次态方程原样搬进
//   脚本做穷举可达性分析（scripts 目录外的一次性分析，结论抄在这里），得到：
//     N=1：可达状态只有 1 个（全 0）—— finalValid_0 恒等于 io_in_0_valid
//          （isFull0=1 时第三项真、=0 时第二项真），in_ready 恒 1、永不被拒，
//          那 3 个寄存器是**死逻辑**；
//     N=2：可达 9 个状态，isFull_0 **不可达**、cancelCounter_0 最大只到 1，
//          计数饱和分支也不可达（第 1 路要攒够 6 次被拒，每一次都得第 0 路赢并
//          握手，而握手就把第 0 路的计数清零了）；
//     N=3：可达 133 个状态；N=4：1479 个 —— 两者全部可达。
//   所以覆盖要求按 N 分档，并且**反过来把不可达的也钉死**：N=1 的三个寄存器
//   必须恒 0、N=2 的 isFull_0 必须恒 0，出现非 0 即判失败。
//
// 激励：每变体独立的 4 位 valid，七种形状轮换且**每种形状连续保持 1..40 拍**
// （逐拍换形状的话状态机根本攒不起计数）。其中第 7 种是「饥饿猎手」：
// 除第 0 路外全程请求，而第 0 路**只在 golden 报 hasFull 的那一拍请求** ——
// 这是唯一能把最高优先级那一路的 cancelCounter 累加到 6 的形状（它平时一请求
// 就赢、一赢就清零）。payload（addr）每路 8 位随机；另有约 1/5000 的复位脉冲。
//
// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。
// ============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NV = 13;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;
  `define CK(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end

  localparam int NIN [NV] = '{3, 4, 2, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1};

  logic rst;
  logic [3:0] vld [NV];
  logic [7:0] pay [4];
  int mode_cur [NV], mode_hold [NV];

  // ---- WBArbiter : N=3 无 payload ----
  logic [2:0] g_WBArbiter_rdy, i_WBArbiter_rdy;
  logic g_WBArbiter_ov, i_WBArbiter_ov;
  WBArbiter u_g_WBArbiter (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_rdy[0]),
    .io_in_0_valid (vld[0][0]),
    .io_in_1_ready (g_WBArbiter_rdy[1]),
    .io_in_1_valid (vld[0][1]),
    .io_in_2_ready (g_WBArbiter_rdy[2]),
    .io_in_2_valid (vld[0][2]),
    .io_out_valid (g_WBArbiter_ov)
  );
  WBArbiter_xs u_i_WBArbiter (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_rdy[0]),
    .io_in_0_valid (vld[0][0]),
    .io_in_1_ready (i_WBArbiter_rdy[1]),
    .io_in_1_valid (vld[0][1]),
    .io_in_2_ready (i_WBArbiter_rdy[2]),
    .io_in_2_valid (vld[0][2]),
    .io_out_valid (i_WBArbiter_ov)
  );
  // ---- WBArbiter_1 : N=4 无 payload ----
  logic [3:0] g_WBArbiter_1_rdy, i_WBArbiter_1_rdy;
  logic g_WBArbiter_1_ov, i_WBArbiter_1_ov;
  WBArbiter_1 u_g_WBArbiter_1 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_1_rdy[0]),
    .io_in_0_valid (vld[1][0]),
    .io_in_1_ready (g_WBArbiter_1_rdy[1]),
    .io_in_1_valid (vld[1][1]),
    .io_in_2_ready (g_WBArbiter_1_rdy[2]),
    .io_in_2_valid (vld[1][2]),
    .io_in_3_ready (g_WBArbiter_1_rdy[3]),
    .io_in_3_valid (vld[1][3]),
    .io_out_valid (g_WBArbiter_1_ov)
  );
  WBArbiter_1_xs u_i_WBArbiter_1 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_1_rdy[0]),
    .io_in_0_valid (vld[1][0]),
    .io_in_1_ready (i_WBArbiter_1_rdy[1]),
    .io_in_1_valid (vld[1][1]),
    .io_in_2_ready (i_WBArbiter_1_rdy[2]),
    .io_in_2_valid (vld[1][2]),
    .io_in_3_ready (i_WBArbiter_1_rdy[3]),
    .io_in_3_valid (vld[1][3]),
    .io_out_valid (i_WBArbiter_1_ov)
  );
  // ---- WBArbiter_2 : N=2 无 payload ----
  logic [1:0] g_WBArbiter_2_rdy, i_WBArbiter_2_rdy;
  logic g_WBArbiter_2_ov, i_WBArbiter_2_ov;
  WBArbiter_2 u_g_WBArbiter_2 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_2_rdy[0]),
    .io_in_0_valid (vld[2][0]),
    .io_in_1_ready (g_WBArbiter_2_rdy[1]),
    .io_in_1_valid (vld[2][1]),
    .io_out_valid (g_WBArbiter_2_ov)
  );
  WBArbiter_2_xs u_i_WBArbiter_2 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_2_rdy[0]),
    .io_in_0_valid (vld[2][0]),
    .io_in_1_ready (i_WBArbiter_2_rdy[1]),
    .io_in_1_valid (vld[2][1]),
    .io_out_valid (i_WBArbiter_2_ov)
  );
  // ---- WBArbiter_3 : N=1 无 payload ----
  logic [0:0] g_WBArbiter_3_rdy, i_WBArbiter_3_rdy;
  logic g_WBArbiter_3_ov, i_WBArbiter_3_ov;
  WBArbiter_3 u_g_WBArbiter_3 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_3_rdy[0]),
    .io_in_0_valid (vld[3][0]),
    .io_out_valid (g_WBArbiter_3_ov)
  );
  WBArbiter_3_xs u_i_WBArbiter_3 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_3_rdy[0]),
    .io_in_0_valid (vld[3][0]),
    .io_out_valid (i_WBArbiter_3_ov)
  );
  // ---- WBArbiter_30 : N=2 payload addr[7:0] ----
  logic [1:0] g_WBArbiter_30_rdy, i_WBArbiter_30_rdy;
  logic g_WBArbiter_30_ov, i_WBArbiter_30_ov;
  logic [7:0] g_WBArbiter_30_b, i_WBArbiter_30_b;
  WBArbiter_30 u_g_WBArbiter_30 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_30_rdy[0]),
    .io_in_0_valid (vld[4][0]),
    .io_in_0_bits_addr (pay[0][7:0]),
    .io_in_1_ready (g_WBArbiter_30_rdy[1]),
    .io_in_1_valid (vld[4][1]),
    .io_in_1_bits_addr (pay[1][7:0]),
    .io_out_valid (g_WBArbiter_30_ov),
    .io_out_bits_addr (g_WBArbiter_30_b)
  );
  WBArbiter_30_xs u_i_WBArbiter_30 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_30_rdy[0]),
    .io_in_0_valid (vld[4][0]),
    .io_in_0_bits_addr (pay[0][7:0]),
    .io_in_1_ready (i_WBArbiter_30_rdy[1]),
    .io_in_1_valid (vld[4][1]),
    .io_in_1_bits_addr (pay[1][7:0]),
    .io_out_valid (i_WBArbiter_30_ov),
    .io_out_bits_addr (i_WBArbiter_30_b)
  );
  // ---- WBArbiter_33 : N=3 payload addr[7:0] ----
  logic [2:0] g_WBArbiter_33_rdy, i_WBArbiter_33_rdy;
  logic g_WBArbiter_33_ov, i_WBArbiter_33_ov;
  logic [7:0] g_WBArbiter_33_b, i_WBArbiter_33_b;
  WBArbiter_33 u_g_WBArbiter_33 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_33_rdy[0]),
    .io_in_0_valid (vld[5][0]),
    .io_in_0_bits_addr (pay[0][7:0]),
    .io_in_1_ready (g_WBArbiter_33_rdy[1]),
    .io_in_1_valid (vld[5][1]),
    .io_in_1_bits_addr (pay[1][7:0]),
    .io_in_2_ready (g_WBArbiter_33_rdy[2]),
    .io_in_2_valid (vld[5][2]),
    .io_in_2_bits_addr (pay[2][7:0]),
    .io_out_valid (g_WBArbiter_33_ov),
    .io_out_bits_addr (g_WBArbiter_33_b)
  );
  WBArbiter_33_xs u_i_WBArbiter_33 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_33_rdy[0]),
    .io_in_0_valid (vld[5][0]),
    .io_in_0_bits_addr (pay[0][7:0]),
    .io_in_1_ready (i_WBArbiter_33_rdy[1]),
    .io_in_1_valid (vld[5][1]),
    .io_in_1_bits_addr (pay[1][7:0]),
    .io_in_2_ready (i_WBArbiter_33_rdy[2]),
    .io_in_2_valid (vld[5][2]),
    .io_in_2_bits_addr (pay[2][7:0]),
    .io_out_valid (i_WBArbiter_33_ov),
    .io_out_bits_addr (i_WBArbiter_33_b)
  );
  // ---- WBArbiter_38 : N=1 payload addr[7:0] ----
  logic [0:0] g_WBArbiter_38_rdy, i_WBArbiter_38_rdy;
  logic g_WBArbiter_38_ov, i_WBArbiter_38_ov;
  logic [7:0] g_WBArbiter_38_b, i_WBArbiter_38_b;
  WBArbiter_38 u_g_WBArbiter_38 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_38_rdy[0]),
    .io_in_0_valid (vld[6][0]),
    .io_in_0_bits_addr (pay[0][7:0]),
    .io_out_valid (g_WBArbiter_38_ov),
    .io_out_bits_addr (g_WBArbiter_38_b)
  );
  WBArbiter_38_xs u_i_WBArbiter_38 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_38_rdy[0]),
    .io_in_0_valid (vld[6][0]),
    .io_in_0_bits_addr (pay[0][7:0]),
    .io_out_valid (i_WBArbiter_38_ov),
    .io_out_bits_addr (i_WBArbiter_38_b)
  );
  // ---- WBArbiter_52 : N=2 payload addr[6:0] ----
  logic [1:0] g_WBArbiter_52_rdy, i_WBArbiter_52_rdy;
  logic g_WBArbiter_52_ov, i_WBArbiter_52_ov;
  logic [6:0] g_WBArbiter_52_b, i_WBArbiter_52_b;
  WBArbiter_52 u_g_WBArbiter_52 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_52_rdy[0]),
    .io_in_0_valid (vld[7][0]),
    .io_in_0_bits_addr (pay[0][6:0]),
    .io_in_1_ready (g_WBArbiter_52_rdy[1]),
    .io_in_1_valid (vld[7][1]),
    .io_in_1_bits_addr (pay[1][6:0]),
    .io_out_valid (g_WBArbiter_52_ov),
    .io_out_bits_addr (g_WBArbiter_52_b)
  );
  WBArbiter_52_xs u_i_WBArbiter_52 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_52_rdy[0]),
    .io_in_0_valid (vld[7][0]),
    .io_in_0_bits_addr (pay[0][6:0]),
    .io_in_1_ready (i_WBArbiter_52_rdy[1]),
    .io_in_1_valid (vld[7][1]),
    .io_in_1_bits_addr (pay[1][6:0]),
    .io_out_valid (i_WBArbiter_52_ov),
    .io_out_bits_addr (i_WBArbiter_52_b)
  );
  // ---- WBArbiter_55 : N=3 payload addr[6:0] ----
  logic [2:0] g_WBArbiter_55_rdy, i_WBArbiter_55_rdy;
  logic g_WBArbiter_55_ov, i_WBArbiter_55_ov;
  logic [6:0] g_WBArbiter_55_b, i_WBArbiter_55_b;
  WBArbiter_55 u_g_WBArbiter_55 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_55_rdy[0]),
    .io_in_0_valid (vld[8][0]),
    .io_in_0_bits_addr (pay[0][6:0]),
    .io_in_1_ready (g_WBArbiter_55_rdy[1]),
    .io_in_1_valid (vld[8][1]),
    .io_in_1_bits_addr (pay[1][6:0]),
    .io_in_2_ready (g_WBArbiter_55_rdy[2]),
    .io_in_2_valid (vld[8][2]),
    .io_in_2_bits_addr (pay[2][6:0]),
    .io_out_valid (g_WBArbiter_55_ov),
    .io_out_bits_addr (g_WBArbiter_55_b)
  );
  WBArbiter_55_xs u_i_WBArbiter_55 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_55_rdy[0]),
    .io_in_0_valid (vld[8][0]),
    .io_in_0_bits_addr (pay[0][6:0]),
    .io_in_1_ready (i_WBArbiter_55_rdy[1]),
    .io_in_1_valid (vld[8][1]),
    .io_in_1_bits_addr (pay[1][6:0]),
    .io_in_2_ready (i_WBArbiter_55_rdy[2]),
    .io_in_2_valid (vld[8][2]),
    .io_in_2_bits_addr (pay[2][6:0]),
    .io_out_valid (i_WBArbiter_55_ov),
    .io_out_bits_addr (i_WBArbiter_55_b)
  );
  // ---- WBArbiter_58 : N=1 payload addr[6:0] ----
  logic [0:0] g_WBArbiter_58_rdy, i_WBArbiter_58_rdy;
  logic g_WBArbiter_58_ov, i_WBArbiter_58_ov;
  logic [6:0] g_WBArbiter_58_b, i_WBArbiter_58_b;
  WBArbiter_58 u_g_WBArbiter_58 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_58_rdy[0]),
    .io_in_0_valid (vld[9][0]),
    .io_in_0_bits_addr (pay[0][6:0]),
    .io_out_valid (g_WBArbiter_58_ov),
    .io_out_bits_addr (g_WBArbiter_58_b)
  );
  WBArbiter_58_xs u_i_WBArbiter_58 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_58_rdy[0]),
    .io_in_0_valid (vld[9][0]),
    .io_in_0_bits_addr (pay[0][6:0]),
    .io_out_valid (i_WBArbiter_58_ov),
    .io_out_bits_addr (i_WBArbiter_58_b)
  );
  // ---- WBArbiter_64 : N=2 payload addr[4:0] ----
  logic [1:0] g_WBArbiter_64_rdy, i_WBArbiter_64_rdy;
  logic g_WBArbiter_64_ov, i_WBArbiter_64_ov;
  logic [4:0] g_WBArbiter_64_b, i_WBArbiter_64_b;
  WBArbiter_64 u_g_WBArbiter_64 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_64_rdy[0]),
    .io_in_0_valid (vld[10][0]),
    .io_in_0_bits_addr (pay[0][4:0]),
    .io_in_1_ready (g_WBArbiter_64_rdy[1]),
    .io_in_1_valid (vld[10][1]),
    .io_in_1_bits_addr (pay[1][4:0]),
    .io_out_valid (g_WBArbiter_64_ov),
    .io_out_bits_addr (g_WBArbiter_64_b)
  );
  WBArbiter_64_xs u_i_WBArbiter_64 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_64_rdy[0]),
    .io_in_0_valid (vld[10][0]),
    .io_in_0_bits_addr (pay[0][4:0]),
    .io_in_1_ready (i_WBArbiter_64_rdy[1]),
    .io_in_1_valid (vld[10][1]),
    .io_in_1_bits_addr (pay[1][4:0]),
    .io_out_valid (i_WBArbiter_64_ov),
    .io_out_bits_addr (i_WBArbiter_64_b)
  );
  // ---- WBArbiter_65 : N=3 payload addr[4:0] ----
  logic [2:0] g_WBArbiter_65_rdy, i_WBArbiter_65_rdy;
  logic g_WBArbiter_65_ov, i_WBArbiter_65_ov;
  logic [4:0] g_WBArbiter_65_b, i_WBArbiter_65_b;
  WBArbiter_65 u_g_WBArbiter_65 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_65_rdy[0]),
    .io_in_0_valid (vld[11][0]),
    .io_in_0_bits_addr (pay[0][4:0]),
    .io_in_1_ready (g_WBArbiter_65_rdy[1]),
    .io_in_1_valid (vld[11][1]),
    .io_in_1_bits_addr (pay[1][4:0]),
    .io_in_2_ready (g_WBArbiter_65_rdy[2]),
    .io_in_2_valid (vld[11][2]),
    .io_in_2_bits_addr (pay[2][4:0]),
    .io_out_valid (g_WBArbiter_65_ov),
    .io_out_bits_addr (g_WBArbiter_65_b)
  );
  WBArbiter_65_xs u_i_WBArbiter_65 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_65_rdy[0]),
    .io_in_0_valid (vld[11][0]),
    .io_in_0_bits_addr (pay[0][4:0]),
    .io_in_1_ready (i_WBArbiter_65_rdy[1]),
    .io_in_1_valid (vld[11][1]),
    .io_in_1_bits_addr (pay[1][4:0]),
    .io_in_2_ready (i_WBArbiter_65_rdy[2]),
    .io_in_2_valid (vld[11][2]),
    .io_in_2_bits_addr (pay[2][4:0]),
    .io_out_valid (i_WBArbiter_65_ov),
    .io_out_bits_addr (i_WBArbiter_65_b)
  );
  // ---- WBArbiter_66 : N=1 payload addr[4:0] ----
  logic [0:0] g_WBArbiter_66_rdy, i_WBArbiter_66_rdy;
  logic g_WBArbiter_66_ov, i_WBArbiter_66_ov;
  logic [4:0] g_WBArbiter_66_b, i_WBArbiter_66_b;
  WBArbiter_66 u_g_WBArbiter_66 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_WBArbiter_66_rdy[0]),
    .io_in_0_valid (vld[12][0]),
    .io_in_0_bits_addr (pay[0][4:0]),
    .io_out_valid (g_WBArbiter_66_ov),
    .io_out_bits_addr (g_WBArbiter_66_b)
  );
  WBArbiter_66_xs u_i_WBArbiter_66 (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_WBArbiter_66_rdy[0]),
    .io_in_0_valid (vld[12][0]),
    .io_in_0_bits_addr (pay[0][4:0]),
    .io_out_valid (i_WBArbiter_66_ov),
    .io_out_bits_addr (i_WBArbiter_66_b)
  );

  // ---- 覆盖桶（全部从 golden 侧的内部寄存器现场取，不看重写件）----
  bit [1:0] cov_ov  [NV];
  bit [1:0] cov_rdy [NV][4];
  bit       cov_full[NV][4];   // 第 i 路饿到过 isFull
  bit [1:0] cov_hf  [NV];      // hasFull 取遍 0/1
  bit       cov_sat [NV];      // 「计数已是 7 又被拒」的饱和分支（只有 N>=3 可达）
  bit       dead_bad[NV];      // 穷举证明不可达的状态却出现了（N=1 全部 / N=2 的 isFull_0）

  task automatic check();
    `CK(g_WBArbiter_ov,  i_WBArbiter_ov,  "WBArbiter.out_valid")
    `CK(g_WBArbiter_rdy, i_WBArbiter_rdy, "WBArbiter.in_ready")
    cov_ov[0][g_WBArbiter_ov] = 1'b1;
    for (int k = 0; k < 3; k++) cov_rdy[0][k][g_WBArbiter_rdy[k]] = 1'b1;
    cov_hf[0][u_g_WBArbiter.hasFull] = 1'b1;
    if (u_g_WBArbiter.isFull_0) cov_full[0][0] = 1'b1;
    if ((&u_g_WBArbiter.cancelCounter_0) && vld[0][0] && !g_WBArbiter_rdy[0])
      cov_sat[0] = 1'b1;
    if (u_g_WBArbiter.isFull_1) cov_full[0][1] = 1'b1;
    if ((&u_g_WBArbiter.cancelCounter_1) && vld[0][1] && !g_WBArbiter_rdy[1])
      cov_sat[0] = 1'b1;
    if (u_g_WBArbiter.isFull_2) cov_full[0][2] = 1'b1;
    if ((&u_g_WBArbiter.cancelCounter_2) && vld[0][2] && !g_WBArbiter_rdy[2])
      cov_sat[0] = 1'b1;
    `CK(g_WBArbiter_1_ov,  i_WBArbiter_1_ov,  "WBArbiter_1.out_valid")
    `CK(g_WBArbiter_1_rdy, i_WBArbiter_1_rdy, "WBArbiter_1.in_ready")
    cov_ov[1][g_WBArbiter_1_ov] = 1'b1;
    for (int k = 0; k < 4; k++) cov_rdy[1][k][g_WBArbiter_1_rdy[k]] = 1'b1;
    cov_hf[1][u_g_WBArbiter_1.hasFull] = 1'b1;
    if (u_g_WBArbiter_1.isFull_0) cov_full[1][0] = 1'b1;
    if ((&u_g_WBArbiter_1.cancelCounter_0) && vld[1][0] && !g_WBArbiter_1_rdy[0])
      cov_sat[1] = 1'b1;
    if (u_g_WBArbiter_1.isFull_1) cov_full[1][1] = 1'b1;
    if ((&u_g_WBArbiter_1.cancelCounter_1) && vld[1][1] && !g_WBArbiter_1_rdy[1])
      cov_sat[1] = 1'b1;
    if (u_g_WBArbiter_1.isFull_2) cov_full[1][2] = 1'b1;
    if ((&u_g_WBArbiter_1.cancelCounter_2) && vld[1][2] && !g_WBArbiter_1_rdy[2])
      cov_sat[1] = 1'b1;
    if (u_g_WBArbiter_1.isFull_3) cov_full[1][3] = 1'b1;
    if ((&u_g_WBArbiter_1.cancelCounter_3) && vld[1][3] && !g_WBArbiter_1_rdy[3])
      cov_sat[1] = 1'b1;
    `CK(g_WBArbiter_2_ov,  i_WBArbiter_2_ov,  "WBArbiter_2.out_valid")
    `CK(g_WBArbiter_2_rdy, i_WBArbiter_2_rdy, "WBArbiter_2.in_ready")
    cov_ov[2][g_WBArbiter_2_ov] = 1'b1;
    for (int k = 0; k < 2; k++) cov_rdy[2][k][g_WBArbiter_2_rdy[k]] = 1'b1;
    cov_hf[2][u_g_WBArbiter_2.hasFull] = 1'b1;
    if (u_g_WBArbiter_2.isFull_0) cov_full[2][0] = 1'b1;
    if ((&u_g_WBArbiter_2.cancelCounter_0) && vld[2][0] && !g_WBArbiter_2_rdy[0])
      cov_sat[2] = 1'b1;
    if (u_g_WBArbiter_2.isFull_1) cov_full[2][1] = 1'b1;
    if ((&u_g_WBArbiter_2.cancelCounter_1) && vld[2][1] && !g_WBArbiter_2_rdy[1])
      cov_sat[2] = 1'b1;
    if (u_g_WBArbiter_2.isFull_0 || u_g_WBArbiter_2.cancelCounter_0 > 3'd1)
      dead_bad[2] = 1'b1;   // N=2：isFull_0 不可达、cnt_0 上界 1
    `CK(g_WBArbiter_3_ov,  i_WBArbiter_3_ov,  "WBArbiter_3.out_valid")
    `CK(g_WBArbiter_3_rdy, i_WBArbiter_3_rdy, "WBArbiter_3.in_ready")
    cov_ov[3][g_WBArbiter_3_ov] = 1'b1;
    for (int k = 0; k < 1; k++) cov_rdy[3][k][g_WBArbiter_3_rdy[k]] = 1'b1;
    cov_hf[3][u_g_WBArbiter_3.hasFull] = 1'b1;
    if (u_g_WBArbiter_3.isFull_0) cov_full[3][0] = 1'b1;
    if ((&u_g_WBArbiter_3.cancelCounter_0) && vld[3][0] && !g_WBArbiter_3_rdy[0])
      cov_sat[3] = 1'b1;
    if (u_g_WBArbiter_3.isFull_0 || u_g_WBArbiter_3.hasFull || (|u_g_WBArbiter_3.cancelCounter_0))
      dead_bad[3] = 1'b1;   // N=1：穷举可达状态只有全 0
    `CK(g_WBArbiter_30_ov,  i_WBArbiter_30_ov,  "WBArbiter_30.out_valid")
    `CK(g_WBArbiter_30_rdy, i_WBArbiter_30_rdy, "WBArbiter_30.in_ready")
    `CK(g_WBArbiter_30_b,   i_WBArbiter_30_b,   "WBArbiter_30.bits_addr")
    cov_ov[4][g_WBArbiter_30_ov] = 1'b1;
    for (int k = 0; k < 2; k++) cov_rdy[4][k][g_WBArbiter_30_rdy[k]] = 1'b1;
    cov_hf[4][u_g_WBArbiter_30.hasFull] = 1'b1;
    if (u_g_WBArbiter_30.isFull_0) cov_full[4][0] = 1'b1;
    if ((&u_g_WBArbiter_30.cancelCounter_0) && vld[4][0] && !g_WBArbiter_30_rdy[0])
      cov_sat[4] = 1'b1;
    if (u_g_WBArbiter_30.isFull_1) cov_full[4][1] = 1'b1;
    if ((&u_g_WBArbiter_30.cancelCounter_1) && vld[4][1] && !g_WBArbiter_30_rdy[1])
      cov_sat[4] = 1'b1;
    if (u_g_WBArbiter_30.isFull_0 || u_g_WBArbiter_30.cancelCounter_0 > 3'd1)
      dead_bad[4] = 1'b1;   // N=2：isFull_0 不可达、cnt_0 上界 1
    `CK(g_WBArbiter_33_ov,  i_WBArbiter_33_ov,  "WBArbiter_33.out_valid")
    `CK(g_WBArbiter_33_rdy, i_WBArbiter_33_rdy, "WBArbiter_33.in_ready")
    `CK(g_WBArbiter_33_b,   i_WBArbiter_33_b,   "WBArbiter_33.bits_addr")
    cov_ov[5][g_WBArbiter_33_ov] = 1'b1;
    for (int k = 0; k < 3; k++) cov_rdy[5][k][g_WBArbiter_33_rdy[k]] = 1'b1;
    cov_hf[5][u_g_WBArbiter_33.hasFull] = 1'b1;
    if (u_g_WBArbiter_33.isFull_0) cov_full[5][0] = 1'b1;
    if ((&u_g_WBArbiter_33.cancelCounter_0) && vld[5][0] && !g_WBArbiter_33_rdy[0])
      cov_sat[5] = 1'b1;
    if (u_g_WBArbiter_33.isFull_1) cov_full[5][1] = 1'b1;
    if ((&u_g_WBArbiter_33.cancelCounter_1) && vld[5][1] && !g_WBArbiter_33_rdy[1])
      cov_sat[5] = 1'b1;
    if (u_g_WBArbiter_33.isFull_2) cov_full[5][2] = 1'b1;
    if ((&u_g_WBArbiter_33.cancelCounter_2) && vld[5][2] && !g_WBArbiter_33_rdy[2])
      cov_sat[5] = 1'b1;
    `CK(g_WBArbiter_38_ov,  i_WBArbiter_38_ov,  "WBArbiter_38.out_valid")
    `CK(g_WBArbiter_38_rdy, i_WBArbiter_38_rdy, "WBArbiter_38.in_ready")
    `CK(g_WBArbiter_38_b,   i_WBArbiter_38_b,   "WBArbiter_38.bits_addr")
    cov_ov[6][g_WBArbiter_38_ov] = 1'b1;
    for (int k = 0; k < 1; k++) cov_rdy[6][k][g_WBArbiter_38_rdy[k]] = 1'b1;
    cov_hf[6][u_g_WBArbiter_38.hasFull] = 1'b1;
    if (u_g_WBArbiter_38.isFull_0) cov_full[6][0] = 1'b1;
    if ((&u_g_WBArbiter_38.cancelCounter_0) && vld[6][0] && !g_WBArbiter_38_rdy[0])
      cov_sat[6] = 1'b1;
    if (u_g_WBArbiter_38.isFull_0 || u_g_WBArbiter_38.hasFull || (|u_g_WBArbiter_38.cancelCounter_0))
      dead_bad[6] = 1'b1;   // N=1：穷举可达状态只有全 0
    `CK(g_WBArbiter_52_ov,  i_WBArbiter_52_ov,  "WBArbiter_52.out_valid")
    `CK(g_WBArbiter_52_rdy, i_WBArbiter_52_rdy, "WBArbiter_52.in_ready")
    `CK(g_WBArbiter_52_b,   i_WBArbiter_52_b,   "WBArbiter_52.bits_addr")
    cov_ov[7][g_WBArbiter_52_ov] = 1'b1;
    for (int k = 0; k < 2; k++) cov_rdy[7][k][g_WBArbiter_52_rdy[k]] = 1'b1;
    cov_hf[7][u_g_WBArbiter_52.hasFull] = 1'b1;
    if (u_g_WBArbiter_52.isFull_0) cov_full[7][0] = 1'b1;
    if ((&u_g_WBArbiter_52.cancelCounter_0) && vld[7][0] && !g_WBArbiter_52_rdy[0])
      cov_sat[7] = 1'b1;
    if (u_g_WBArbiter_52.isFull_1) cov_full[7][1] = 1'b1;
    if ((&u_g_WBArbiter_52.cancelCounter_1) && vld[7][1] && !g_WBArbiter_52_rdy[1])
      cov_sat[7] = 1'b1;
    if (u_g_WBArbiter_52.isFull_0 || u_g_WBArbiter_52.cancelCounter_0 > 3'd1)
      dead_bad[7] = 1'b1;   // N=2：isFull_0 不可达、cnt_0 上界 1
    `CK(g_WBArbiter_55_ov,  i_WBArbiter_55_ov,  "WBArbiter_55.out_valid")
    `CK(g_WBArbiter_55_rdy, i_WBArbiter_55_rdy, "WBArbiter_55.in_ready")
    `CK(g_WBArbiter_55_b,   i_WBArbiter_55_b,   "WBArbiter_55.bits_addr")
    cov_ov[8][g_WBArbiter_55_ov] = 1'b1;
    for (int k = 0; k < 3; k++) cov_rdy[8][k][g_WBArbiter_55_rdy[k]] = 1'b1;
    cov_hf[8][u_g_WBArbiter_55.hasFull] = 1'b1;
    if (u_g_WBArbiter_55.isFull_0) cov_full[8][0] = 1'b1;
    if ((&u_g_WBArbiter_55.cancelCounter_0) && vld[8][0] && !g_WBArbiter_55_rdy[0])
      cov_sat[8] = 1'b1;
    if (u_g_WBArbiter_55.isFull_1) cov_full[8][1] = 1'b1;
    if ((&u_g_WBArbiter_55.cancelCounter_1) && vld[8][1] && !g_WBArbiter_55_rdy[1])
      cov_sat[8] = 1'b1;
    if (u_g_WBArbiter_55.isFull_2) cov_full[8][2] = 1'b1;
    if ((&u_g_WBArbiter_55.cancelCounter_2) && vld[8][2] && !g_WBArbiter_55_rdy[2])
      cov_sat[8] = 1'b1;
    `CK(g_WBArbiter_58_ov,  i_WBArbiter_58_ov,  "WBArbiter_58.out_valid")
    `CK(g_WBArbiter_58_rdy, i_WBArbiter_58_rdy, "WBArbiter_58.in_ready")
    `CK(g_WBArbiter_58_b,   i_WBArbiter_58_b,   "WBArbiter_58.bits_addr")
    cov_ov[9][g_WBArbiter_58_ov] = 1'b1;
    for (int k = 0; k < 1; k++) cov_rdy[9][k][g_WBArbiter_58_rdy[k]] = 1'b1;
    cov_hf[9][u_g_WBArbiter_58.hasFull] = 1'b1;
    if (u_g_WBArbiter_58.isFull_0) cov_full[9][0] = 1'b1;
    if ((&u_g_WBArbiter_58.cancelCounter_0) && vld[9][0] && !g_WBArbiter_58_rdy[0])
      cov_sat[9] = 1'b1;
    if (u_g_WBArbiter_58.isFull_0 || u_g_WBArbiter_58.hasFull || (|u_g_WBArbiter_58.cancelCounter_0))
      dead_bad[9] = 1'b1;   // N=1：穷举可达状态只有全 0
    `CK(g_WBArbiter_64_ov,  i_WBArbiter_64_ov,  "WBArbiter_64.out_valid")
    `CK(g_WBArbiter_64_rdy, i_WBArbiter_64_rdy, "WBArbiter_64.in_ready")
    `CK(g_WBArbiter_64_b,   i_WBArbiter_64_b,   "WBArbiter_64.bits_addr")
    cov_ov[10][g_WBArbiter_64_ov] = 1'b1;
    for (int k = 0; k < 2; k++) cov_rdy[10][k][g_WBArbiter_64_rdy[k]] = 1'b1;
    cov_hf[10][u_g_WBArbiter_64.hasFull] = 1'b1;
    if (u_g_WBArbiter_64.isFull_0) cov_full[10][0] = 1'b1;
    if ((&u_g_WBArbiter_64.cancelCounter_0) && vld[10][0] && !g_WBArbiter_64_rdy[0])
      cov_sat[10] = 1'b1;
    if (u_g_WBArbiter_64.isFull_1) cov_full[10][1] = 1'b1;
    if ((&u_g_WBArbiter_64.cancelCounter_1) && vld[10][1] && !g_WBArbiter_64_rdy[1])
      cov_sat[10] = 1'b1;
    if (u_g_WBArbiter_64.isFull_0 || u_g_WBArbiter_64.cancelCounter_0 > 3'd1)
      dead_bad[10] = 1'b1;   // N=2：isFull_0 不可达、cnt_0 上界 1
    `CK(g_WBArbiter_65_ov,  i_WBArbiter_65_ov,  "WBArbiter_65.out_valid")
    `CK(g_WBArbiter_65_rdy, i_WBArbiter_65_rdy, "WBArbiter_65.in_ready")
    `CK(g_WBArbiter_65_b,   i_WBArbiter_65_b,   "WBArbiter_65.bits_addr")
    cov_ov[11][g_WBArbiter_65_ov] = 1'b1;
    for (int k = 0; k < 3; k++) cov_rdy[11][k][g_WBArbiter_65_rdy[k]] = 1'b1;
    cov_hf[11][u_g_WBArbiter_65.hasFull] = 1'b1;
    if (u_g_WBArbiter_65.isFull_0) cov_full[11][0] = 1'b1;
    if ((&u_g_WBArbiter_65.cancelCounter_0) && vld[11][0] && !g_WBArbiter_65_rdy[0])
      cov_sat[11] = 1'b1;
    if (u_g_WBArbiter_65.isFull_1) cov_full[11][1] = 1'b1;
    if ((&u_g_WBArbiter_65.cancelCounter_1) && vld[11][1] && !g_WBArbiter_65_rdy[1])
      cov_sat[11] = 1'b1;
    if (u_g_WBArbiter_65.isFull_2) cov_full[11][2] = 1'b1;
    if ((&u_g_WBArbiter_65.cancelCounter_2) && vld[11][2] && !g_WBArbiter_65_rdy[2])
      cov_sat[11] = 1'b1;
    `CK(g_WBArbiter_66_ov,  i_WBArbiter_66_ov,  "WBArbiter_66.out_valid")
    `CK(g_WBArbiter_66_rdy, i_WBArbiter_66_rdy, "WBArbiter_66.in_ready")
    `CK(g_WBArbiter_66_b,   i_WBArbiter_66_b,   "WBArbiter_66.bits_addr")
    cov_ov[12][g_WBArbiter_66_ov] = 1'b1;
    for (int k = 0; k < 1; k++) cov_rdy[12][k][g_WBArbiter_66_rdy[k]] = 1'b1;
    cov_hf[12][u_g_WBArbiter_66.hasFull] = 1'b1;
    if (u_g_WBArbiter_66.isFull_0) cov_full[12][0] = 1'b1;
    if ((&u_g_WBArbiter_66.cancelCounter_0) && vld[12][0] && !g_WBArbiter_66_rdy[0])
      cov_sat[12] = 1'b1;
    if (u_g_WBArbiter_66.isFull_0 || u_g_WBArbiter_66.hasFull || (|u_g_WBArbiter_66.cancelCounter_0))
      dead_bad[12] = 1'b1;   // N=1：穷举可达状态只有全 0
  endtask

  task automatic drive();
    for (int v = 0; v < NV; v++) begin
      // 形状要**连续保持**若干拍：逐拍换形状的话反饥饿计数根本攒不起来。
      if (mode_hold[v] == 0) begin
        mode_cur[v]  = $urandom_range(0, 6);
        mode_hold[v] = $urandom_range(1, 40);
      end
      mode_hold[v]--;
      case (mode_cur[v])
        0: vld[v] = '0;
        1: vld[v] = '1;
        2: vld[v] = 4'b1 << $urandom_range(0, 3);
        3: vld[v] = $urandom & $urandom;          // 稀疏
        4: vld[v] = $urandom | $urandom;          // 稠密
        5: vld[v] = $urandom;
        default: vld[v] = '1;                     // 6：饥饿猎手，第 0 位下面单独接
      endcase
    end
    if (mode_cur[0] == 6) vld[0][0] = u_g_WBArbiter.hasFull;
    if (mode_cur[1] == 6) vld[1][0] = u_g_WBArbiter_1.hasFull;
    if (mode_cur[2] == 6) vld[2][0] = u_g_WBArbiter_2.hasFull;
    if (mode_cur[3] == 6) vld[3][0] = u_g_WBArbiter_3.hasFull;
    if (mode_cur[4] == 6) vld[4][0] = u_g_WBArbiter_30.hasFull;
    if (mode_cur[5] == 6) vld[5][0] = u_g_WBArbiter_33.hasFull;
    if (mode_cur[6] == 6) vld[6][0] = u_g_WBArbiter_38.hasFull;
    if (mode_cur[7] == 6) vld[7][0] = u_g_WBArbiter_52.hasFull;
    if (mode_cur[8] == 6) vld[8][0] = u_g_WBArbiter_55.hasFull;
    if (mode_cur[9] == 6) vld[9][0] = u_g_WBArbiter_58.hasFull;
    if (mode_cur[10] == 6) vld[10][0] = u_g_WBArbiter_64.hasFull;
    if (mode_cur[11] == 6) vld[11][0] = u_g_WBArbiter_65.hasFull;
    if (mode_cur[12] == 6) vld[12][0] = u_g_WBArbiter_66.hasFull;
    for (int i = 0; i < 4; i++) pay[i] = $urandom;
    rst = ($urandom_range(0, 4999) == 0);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      cov_ov[v] = '0; cov_hf[v] = '0; dead_bad[v] = 1'b0; cov_sat[v] = 1'b0;
      mode_cur[v] = 0; mode_hold[v] = 0;
      for (int k = 0; k < 4; k++) begin cov_rdy[v][k] = '0; cov_full[v][k] = 1'b0; end
    end
    rst = 1'b1;
    for (int v = 0; v < NV; v++) vld[v] = '0;
    for (int i = 0; i < 4; i++) pay[i] = '0;
    repeat (8) @(posedge clk);
    #1; drive(); rst = 1'b0;
    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: out_valid 0/1 | ready 逐路 0/1 | isFull 逐路 | hasFull 0/1 | 饱和分支 ---");
    $display("    （可达性按 golden 次态方程穷举：N=1 全死 / N=2 只有第 1 路够得着 / N>=3 全可达）");
    for (int v = 0; v < NV; v++) begin
      int nr = 0, nf = 0, want_f = 0;
      for (int k = 0; k < NIN[v]; k++) begin
        if (NIN[v] == 1) begin if (cov_rdy[v][k][1]) nr++; end   // N=1：ready 恒 1
        else if (cov_rdy[v][k] == 2'b11) nr++;
        if (cov_full[v][k]) nf++;
      end
      want_f = (NIN[v] == 1) ? 0 : (NIN[v] == 2) ? 1 : NIN[v];
      if (NIN[v] == 2) nf = cov_full[v][1];                      // 第 0 路不可达，不计
      if (cov_ov[v] != 2'b11 || nr != NIN[v] || nf != want_f || dead_bad[v]) bad++;
      if (NIN[v] == 1) begin
        if (cov_hf[v][1]) bad++;                                 // hasFull 必须恒 0
      end else begin
        if (cov_hf[v] != 2'b11) bad++;
      end
      if (NIN[v] >= 3 && !cov_sat[v]) bad++;                     // 饱和分支只有 N>=3 可达
      if (NIN[v] <= 2 && cov_sat[v])  bad++;                     // 反向：N<=2 不该出现
      $display("  variant[%0d] N=%0d : out_valid=%b ready %0d/%0d isFull %0d/%0d hasFull=%b sat=%0b dead_bad=%0b",
               v, NIN[v], cov_ov[v], nr, NIN[v], nf, want_f, cov_hf[v], cov_sat[v], dead_bad[v]);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
