// ============================================================================
// tb —— FuBusyTableWrite 家族 UT：15 个 golden 变体与重写件逐拍双例化比对。
//
// 本族是一个 W 位的倒计时占用表（右移 + 按 fuType 置位 + 按级取消）。
// 「测到位」的判据是三件事，缺一不可：
//   1. 每个变体表的**低 W-1 位**都要取遍 0/1（最高位在 golden 里恒 0 —— 这里
//      不但不要求它取 1，反而**断言它从不为 1**，把那条死线钉住）；
//   2. 每个非空槽的 deq 置位都真的发生过；
//   3. 每个存在的取消端口（og0/og1）都真的**清掉过一个已置位的槽**
//      —— 只看 og0_valid 拉高是不够的，那可能一次也没清到东西。
//
// 激励：deq/og0/og1 三路各自独立随机拉 valid，fuType 四种轮换（全随机 / 随机
// one-hot / 只打本族有效位的 one-hot / 全 0），og1_resp 偏向 0（只有 resp==0
// 才算取消），另有约 1/3000 的单拍异步复位脉冲把复位值也纳入比对。
//
// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。
// ============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NV = 15;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;
  `define CK(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end

  localparam int W [NV] = '{3, 3, 3, 4, 3, 4, 2, 5, 4, 5, 3, 4, 2, 5, 4};
  // 每变体 4 个槽的 fuType 掩码（从 golden 解析，与 rtl 薄 wrapper 同源）
  localparam logic [34:0] SEL [NV][4] = '{
    '{35'h0, 35'h480, 35'h0, 35'h0},
    '{35'h0, 35'h4, 35'h0, 35'h0},
    '{35'h0, 35'h4, 35'h0, 35'h0},
    '{35'h800, 35'h2000, 35'h1000, 35'h0},
    '{35'h800, 35'h2000, 35'h0, 35'h0},
    '{35'h800, 35'h0, 35'h1000, 35'h0},
    '{35'h800, 35'h0, 35'h0, 35'h0},
    '{35'h0, 35'h80000, 35'h300000, 35'h2000000},
    '{35'h40000000, 35'h1000000, 35'h8040000, 35'h0},
    '{35'h0, 35'h40000000, 35'h0, 35'h40000},
    '{35'h0, 35'h1000000, 35'h0, 35'h0},
    '{35'h0, 35'h1000000, 35'h8040000, 35'h0},
    '{35'h40000000, 35'h0, 35'h0, 35'h0},
    '{35'h0, 35'h80000, 35'h0, 35'h2000000},
    '{35'h0, 35'h0, 35'h8000, 35'h0}};
  localparam logic [34:0] UNION = 35'h4b3cbc84;
  localparam bit HAS_OG0 [NV] = '{1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1};
  localparam bit HAS_OG1 [NV] = '{1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1};

  logic rst, deq_v, og0_v, og1_v;
  logic [1:0]  og1_resp;
  logic [34:0] deq_ft, og0_ft, og1_ft;

  // ---- FuBusyTableWrite : W=3 og0=1 og1=0 ----
  logic [2:0] g_FuBusyTableWrite_t, i_FuBusyTableWrite_t;
  FuBusyTableWrite u_g_FuBusyTableWrite (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_t)
  );
  FuBusyTableWrite_xs u_i_FuBusyTableWrite (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_t)
  );
  // ---- FuBusyTableWrite_22 : W=3 og0=1 og1=0 ----
  logic [2:0] g_FuBusyTableWrite_22_t, i_FuBusyTableWrite_22_t;
  FuBusyTableWrite_22 u_g_FuBusyTableWrite_22 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_22_t)
  );
  FuBusyTableWrite_22_xs u_i_FuBusyTableWrite_22 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_22_t)
  );
  // ---- FuBusyTableWrite_26 : W=3 og0=1 og1=0 ----
  logic [2:0] g_FuBusyTableWrite_26_t, i_FuBusyTableWrite_26_t;
  FuBusyTableWrite_26 u_g_FuBusyTableWrite_26 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_26_t)
  );
  FuBusyTableWrite_26_xs u_i_FuBusyTableWrite_26 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_26_t)
  );
  // ---- FuBusyTableWrite_42 : W=4 og0=1 og1=1 ----
  logic [3:0] g_FuBusyTableWrite_42_t, i_FuBusyTableWrite_42_t;
  FuBusyTableWrite_42 u_g_FuBusyTableWrite_42 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_in_og1Resp_valid (og1_v),
    .io_in_og1Resp_bits_resp (og1_resp),
    .io_in_og1Resp_bits_fuType (og1_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_42_t)
  );
  FuBusyTableWrite_42_xs u_i_FuBusyTableWrite_42 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_in_og1Resp_valid (og1_v),
    .io_in_og1Resp_bits_resp (og1_resp),
    .io_in_og1Resp_bits_fuType (og1_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_42_t)
  );
  // ---- FuBusyTableWrite_43 : W=3 og0=1 og1=0 ----
  logic [2:0] g_FuBusyTableWrite_43_t, i_FuBusyTableWrite_43_t;
  FuBusyTableWrite_43 u_g_FuBusyTableWrite_43 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_43_t)
  );
  FuBusyTableWrite_43_xs u_i_FuBusyTableWrite_43 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_43_t)
  );
  // ---- FuBusyTableWrite_52 : W=4 og0=1 og1=1 ----
  logic [3:0] g_FuBusyTableWrite_52_t, i_FuBusyTableWrite_52_t;
  FuBusyTableWrite_52 u_g_FuBusyTableWrite_52 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_in_og1Resp_valid (og1_v),
    .io_in_og1Resp_bits_resp (og1_resp),
    .io_in_og1Resp_bits_fuType (og1_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_52_t)
  );
  FuBusyTableWrite_52_xs u_i_FuBusyTableWrite_52 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_in_og1Resp_valid (og1_v),
    .io_in_og1Resp_bits_resp (og1_resp),
    .io_in_og1Resp_bits_fuType (og1_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_52_t)
  );
  // ---- FuBusyTableWrite_53 : W=2 og0=0 og1=0 ----
  logic [1:0] g_FuBusyTableWrite_53_t, i_FuBusyTableWrite_53_t;
  FuBusyTableWrite_53 u_g_FuBusyTableWrite_53 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_53_t)
  );
  FuBusyTableWrite_53_xs u_i_FuBusyTableWrite_53 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_53_t)
  );
  // ---- FuBusyTableWrite_68 : W=5 og0=1 og1=0 ----
  logic [4:0] g_FuBusyTableWrite_68_t, i_FuBusyTableWrite_68_t;
  FuBusyTableWrite_68 u_g_FuBusyTableWrite_68 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_68_t)
  );
  FuBusyTableWrite_68_xs u_i_FuBusyTableWrite_68 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_68_t)
  );
  // ---- FuBusyTableWrite_69 : W=4 og0=1 og1=0 ----
  logic [3:0] g_FuBusyTableWrite_69_t, i_FuBusyTableWrite_69_t;
  FuBusyTableWrite_69 u_g_FuBusyTableWrite_69 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_69_t)
  );
  FuBusyTableWrite_69_xs u_i_FuBusyTableWrite_69 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_69_t)
  );
  // ---- FuBusyTableWrite_71 : W=5 og0=1 og1=0 ----
  logic [4:0] g_FuBusyTableWrite_71_t, i_FuBusyTableWrite_71_t;
  FuBusyTableWrite_71 u_g_FuBusyTableWrite_71 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_71_t)
  );
  FuBusyTableWrite_71_xs u_i_FuBusyTableWrite_71 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_71_t)
  );
  // ---- FuBusyTableWrite_73 : W=3 og0=1 og1=0 ----
  logic [2:0] g_FuBusyTableWrite_73_t, i_FuBusyTableWrite_73_t;
  FuBusyTableWrite_73 u_g_FuBusyTableWrite_73 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_73_t)
  );
  FuBusyTableWrite_73_xs u_i_FuBusyTableWrite_73 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_73_t)
  );
  // ---- FuBusyTableWrite_75 : W=4 og0=1 og1=0 ----
  logic [3:0] g_FuBusyTableWrite_75_t, i_FuBusyTableWrite_75_t;
  FuBusyTableWrite_75 u_g_FuBusyTableWrite_75 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_75_t)
  );
  FuBusyTableWrite_75_xs u_i_FuBusyTableWrite_75 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_75_t)
  );
  // ---- FuBusyTableWrite_79 : W=2 og0=0 og1=0 ----
  logic [1:0] g_FuBusyTableWrite_79_t, i_FuBusyTableWrite_79_t;
  FuBusyTableWrite_79 u_g_FuBusyTableWrite_79 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_79_t)
  );
  FuBusyTableWrite_79_xs u_i_FuBusyTableWrite_79 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_79_t)
  );
  // ---- FuBusyTableWrite_80 : W=5 og0=1 og1=0 ----
  logic [4:0] g_FuBusyTableWrite_80_t, i_FuBusyTableWrite_80_t;
  FuBusyTableWrite_80 u_g_FuBusyTableWrite_80 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_80_t)
  );
  FuBusyTableWrite_80_xs u_i_FuBusyTableWrite_80 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_80_t)
  );
  // ---- FuBusyTableWrite_105 : W=4 og0=1 og1=1 ----
  logic [3:0] g_FuBusyTableWrite_105_t, i_FuBusyTableWrite_105_t;
  FuBusyTableWrite_105 u_g_FuBusyTableWrite_105 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_in_og1Resp_valid (og1_v),
    .io_in_og1Resp_bits_resp (og1_resp),
    .io_in_og1Resp_bits_fuType (og1_ft),
    .io_out_fuBusyTable (g_FuBusyTableWrite_105_t)
  );
  FuBusyTableWrite_105_xs u_i_FuBusyTableWrite_105 (
    .clock (clk),
    .reset (rst),
    .io_in_deqResp_valid (deq_v),
    .io_in_deqResp_bits_fuType (deq_ft),
    .io_in_og0Resp_valid (og0_v),
    .io_in_og0Resp_bits_fuType (og0_ft),
    .io_in_og1Resp_valid (og1_v),
    .io_in_og1Resp_bits_resp (og1_resp),
    .io_in_og1Resp_bits_fuType (og1_ft),
    .io_out_fuBusyTable (i_FuBusyTableWrite_105_t)
  );

  // ---- 覆盖桶 ----
  bit [1:0] cov_bit  [NV][5];   // 表每一位取到过 0 / 1
  bit       cov_set  [NV][4];   // 每个非空槽的 deq 置位发生过
  bit       cov_c0   [NV][4];   // og0 真的清掉过槽 s+1 上一个已置位
  bit       cov_c1   [NV][4];   // og1 真的清掉过槽 s+2 上一个已置位
  bit       top_bad  [NV];      // 最高位曾经为 1（golden 里恒 0，出现即失败）

  task automatic check();
    `CK(g_FuBusyTableWrite_t, i_FuBusyTableWrite_t, "FuBusyTableWrite.fuBusyTable")
    for (int b = 0; b < 3; b++) cov_bit[0][b][g_FuBusyTableWrite_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_t[2]) top_bad[0] = 1'b1;
    for (int sl = 0; sl < 2; sl++) begin
      if (deq_v && (|(deq_ft & SEL[0][sl]))) cov_set[0][sl] = 1'b1;
      if (og0_v && sl + 1 < 2 && (|(og0_ft & SEL[0][sl+1]))
          && g_FuBusyTableWrite_t[sl+1]) cov_c0[0][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_22_t, i_FuBusyTableWrite_22_t, "FuBusyTableWrite_22.fuBusyTable")
    for (int b = 0; b < 3; b++) cov_bit[1][b][g_FuBusyTableWrite_22_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_22_t[2]) top_bad[1] = 1'b1;
    for (int sl = 0; sl < 2; sl++) begin
      if (deq_v && (|(deq_ft & SEL[1][sl]))) cov_set[1][sl] = 1'b1;
      if (og0_v && sl + 1 < 2 && (|(og0_ft & SEL[1][sl+1]))
          && g_FuBusyTableWrite_22_t[sl+1]) cov_c0[1][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_26_t, i_FuBusyTableWrite_26_t, "FuBusyTableWrite_26.fuBusyTable")
    for (int b = 0; b < 3; b++) cov_bit[2][b][g_FuBusyTableWrite_26_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_26_t[2]) top_bad[2] = 1'b1;
    for (int sl = 0; sl < 2; sl++) begin
      if (deq_v && (|(deq_ft & SEL[2][sl]))) cov_set[2][sl] = 1'b1;
      if (og0_v && sl + 1 < 2 && (|(og0_ft & SEL[2][sl+1]))
          && g_FuBusyTableWrite_26_t[sl+1]) cov_c0[2][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_42_t, i_FuBusyTableWrite_42_t, "FuBusyTableWrite_42.fuBusyTable")
    for (int b = 0; b < 4; b++) cov_bit[3][b][g_FuBusyTableWrite_42_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_42_t[3]) top_bad[3] = 1'b1;
    for (int sl = 0; sl < 3; sl++) begin
      if (deq_v && (|(deq_ft & SEL[3][sl]))) cov_set[3][sl] = 1'b1;
      if (og0_v && sl + 1 < 3 && (|(og0_ft & SEL[3][sl+1]))
          && g_FuBusyTableWrite_42_t[sl+1]) cov_c0[3][sl] = 1'b1;
      if (og1_v && og1_resp == 2'd0 && sl + 2 < 3
          && (|(og1_ft & SEL[3][sl+2])) && g_FuBusyTableWrite_42_t[sl+2]) cov_c1[3][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_43_t, i_FuBusyTableWrite_43_t, "FuBusyTableWrite_43.fuBusyTable")
    for (int b = 0; b < 3; b++) cov_bit[4][b][g_FuBusyTableWrite_43_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_43_t[2]) top_bad[4] = 1'b1;
    for (int sl = 0; sl < 2; sl++) begin
      if (deq_v && (|(deq_ft & SEL[4][sl]))) cov_set[4][sl] = 1'b1;
      if (og0_v && sl + 1 < 2 && (|(og0_ft & SEL[4][sl+1]))
          && g_FuBusyTableWrite_43_t[sl+1]) cov_c0[4][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_52_t, i_FuBusyTableWrite_52_t, "FuBusyTableWrite_52.fuBusyTable")
    for (int b = 0; b < 4; b++) cov_bit[5][b][g_FuBusyTableWrite_52_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_52_t[3]) top_bad[5] = 1'b1;
    for (int sl = 0; sl < 3; sl++) begin
      if (deq_v && (|(deq_ft & SEL[5][sl]))) cov_set[5][sl] = 1'b1;
      if (og0_v && sl + 1 < 3 && (|(og0_ft & SEL[5][sl+1]))
          && g_FuBusyTableWrite_52_t[sl+1]) cov_c0[5][sl] = 1'b1;
      if (og1_v && og1_resp == 2'd0 && sl + 2 < 3
          && (|(og1_ft & SEL[5][sl+2])) && g_FuBusyTableWrite_52_t[sl+2]) cov_c1[5][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_53_t, i_FuBusyTableWrite_53_t, "FuBusyTableWrite_53.fuBusyTable")
    for (int b = 0; b < 2; b++) cov_bit[6][b][g_FuBusyTableWrite_53_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_53_t[1]) top_bad[6] = 1'b1;
    for (int sl = 0; sl < 1; sl++) begin
      if (deq_v && (|(deq_ft & SEL[6][sl]))) cov_set[6][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_68_t, i_FuBusyTableWrite_68_t, "FuBusyTableWrite_68.fuBusyTable")
    for (int b = 0; b < 5; b++) cov_bit[7][b][g_FuBusyTableWrite_68_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_68_t[4]) top_bad[7] = 1'b1;
    for (int sl = 0; sl < 4; sl++) begin
      if (deq_v && (|(deq_ft & SEL[7][sl]))) cov_set[7][sl] = 1'b1;
      if (og0_v && sl + 1 < 4 && (|(og0_ft & SEL[7][sl+1]))
          && g_FuBusyTableWrite_68_t[sl+1]) cov_c0[7][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_69_t, i_FuBusyTableWrite_69_t, "FuBusyTableWrite_69.fuBusyTable")
    for (int b = 0; b < 4; b++) cov_bit[8][b][g_FuBusyTableWrite_69_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_69_t[3]) top_bad[8] = 1'b1;
    for (int sl = 0; sl < 3; sl++) begin
      if (deq_v && (|(deq_ft & SEL[8][sl]))) cov_set[8][sl] = 1'b1;
      if (og0_v && sl + 1 < 3 && (|(og0_ft & SEL[8][sl+1]))
          && g_FuBusyTableWrite_69_t[sl+1]) cov_c0[8][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_71_t, i_FuBusyTableWrite_71_t, "FuBusyTableWrite_71.fuBusyTable")
    for (int b = 0; b < 5; b++) cov_bit[9][b][g_FuBusyTableWrite_71_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_71_t[4]) top_bad[9] = 1'b1;
    for (int sl = 0; sl < 4; sl++) begin
      if (deq_v && (|(deq_ft & SEL[9][sl]))) cov_set[9][sl] = 1'b1;
      if (og0_v && sl + 1 < 4 && (|(og0_ft & SEL[9][sl+1]))
          && g_FuBusyTableWrite_71_t[sl+1]) cov_c0[9][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_73_t, i_FuBusyTableWrite_73_t, "FuBusyTableWrite_73.fuBusyTable")
    for (int b = 0; b < 3; b++) cov_bit[10][b][g_FuBusyTableWrite_73_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_73_t[2]) top_bad[10] = 1'b1;
    for (int sl = 0; sl < 2; sl++) begin
      if (deq_v && (|(deq_ft & SEL[10][sl]))) cov_set[10][sl] = 1'b1;
      if (og0_v && sl + 1 < 2 && (|(og0_ft & SEL[10][sl+1]))
          && g_FuBusyTableWrite_73_t[sl+1]) cov_c0[10][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_75_t, i_FuBusyTableWrite_75_t, "FuBusyTableWrite_75.fuBusyTable")
    for (int b = 0; b < 4; b++) cov_bit[11][b][g_FuBusyTableWrite_75_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_75_t[3]) top_bad[11] = 1'b1;
    for (int sl = 0; sl < 3; sl++) begin
      if (deq_v && (|(deq_ft & SEL[11][sl]))) cov_set[11][sl] = 1'b1;
      if (og0_v && sl + 1 < 3 && (|(og0_ft & SEL[11][sl+1]))
          && g_FuBusyTableWrite_75_t[sl+1]) cov_c0[11][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_79_t, i_FuBusyTableWrite_79_t, "FuBusyTableWrite_79.fuBusyTable")
    for (int b = 0; b < 2; b++) cov_bit[12][b][g_FuBusyTableWrite_79_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_79_t[1]) top_bad[12] = 1'b1;
    for (int sl = 0; sl < 1; sl++) begin
      if (deq_v && (|(deq_ft & SEL[12][sl]))) cov_set[12][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_80_t, i_FuBusyTableWrite_80_t, "FuBusyTableWrite_80.fuBusyTable")
    for (int b = 0; b < 5; b++) cov_bit[13][b][g_FuBusyTableWrite_80_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_80_t[4]) top_bad[13] = 1'b1;
    for (int sl = 0; sl < 4; sl++) begin
      if (deq_v && (|(deq_ft & SEL[13][sl]))) cov_set[13][sl] = 1'b1;
      if (og0_v && sl + 1 < 4 && (|(og0_ft & SEL[13][sl+1]))
          && g_FuBusyTableWrite_80_t[sl+1]) cov_c0[13][sl] = 1'b1;
    end
    `CK(g_FuBusyTableWrite_105_t, i_FuBusyTableWrite_105_t, "FuBusyTableWrite_105.fuBusyTable")
    for (int b = 0; b < 4; b++) cov_bit[14][b][g_FuBusyTableWrite_105_t[b]] = 1'b1;
    if (g_FuBusyTableWrite_105_t[3]) top_bad[14] = 1'b1;
    for (int sl = 0; sl < 3; sl++) begin
      if (deq_v && (|(deq_ft & SEL[14][sl]))) cov_set[14][sl] = 1'b1;
      if (og0_v && sl + 1 < 3 && (|(og0_ft & SEL[14][sl+1]))
          && g_FuBusyTableWrite_105_t[sl+1]) cov_c0[14][sl] = 1'b1;
      if (og1_v && og1_resp == 2'd0 && sl + 2 < 3
          && (|(og1_ft & SEL[14][sl+2])) && g_FuBusyTableWrite_105_t[sl+2]) cov_c1[14][sl] = 1'b1;
    end
  endtask

  function automatic logic [34:0] rand_ft(int mode);
    int nb;
    case (mode)
      0: begin rand_ft[31:0] = $urandom; rand_ft[34:32] = $urandom; end
      1: rand_ft = 35'b1 << $urandom_range(0, 34);
      2: begin
           nb = $urandom_range(0, 34);
           while (!UNION[nb]) nb = (nb + 1) % 35;
           rand_ft = 35'b1 << nb;
         end
      default: rand_ft = '0;
    endcase
  endfunction

  task automatic drive();
    deq_v    = $urandom_range(0, 2) != 0;      // 约 2/3 的拍有发射
    og0_v    = $urandom_range(0, 2) != 0;
    og1_v    = $urandom_range(0, 2) != 0;
    og1_resp = ($urandom_range(0, 1) == 0) ? 2'd0 : $urandom_range(1, 3);
    deq_ft   = rand_ft($urandom_range(0, 3));
    og0_ft   = rand_ft($urandom_range(0, 3));
    og1_ft   = rand_ft($urandom_range(0, 3));
    rst      = ($urandom_range(0, 2999) == 0);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      top_bad[v] = 1'b0;
      for (int b = 0; b < 5; b++) cov_bit[v][b] = '0;
      for (int sl = 0; sl < 4; sl++) begin
        cov_set[v][sl] = 1'b0; cov_c0[v][sl] = 1'b0; cov_c1[v][sl] = 1'b0;
      end
    end
    rst = 1'b1; deq_v = 1'b0; og0_v = 1'b0; og1_v = 1'b0;
    og1_resp = '0; deq_ft = '0; og0_ft = '0; og1_ft = '0;
    repeat (8) @(posedge clk);
    #1; drive(); rst = 1'b0;
    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: 表位 0/1 | deq 置位 | og0/og1 真清除 | 最高位恒 0 ---");
    for (int v = 0; v < NV; v++) begin
      int nb = 0, nset = 0, want = 0, nc0 = 0, w0 = 0, nc1 = 0, w1 = 0;
      for (int b = 0; b < W[v] - 1; b++) if (cov_bit[v][b] == 2'b11) nb++;
      for (int sl = 0; sl < W[v] - 1; sl++) begin
        if (|SEL[v][sl]) begin want++; if (cov_set[v][sl]) nset++; end
        if (HAS_OG0[v] && sl + 1 < W[v] - 1 && (|SEL[v][sl+1]))
          begin w0++; if (cov_c0[v][sl]) nc0++; end
        if (HAS_OG1[v] && sl + 2 < W[v] - 1 && (|SEL[v][sl+2]))
          begin w1++; if (cov_c1[v][sl]) nc1++; end
      end
      if (nb != W[v] - 1 || nset != want || nc0 != w0 || nc1 != w1 || top_bad[v]) bad++;
      $display("  variant[%0d] W=%0d : bit01 %0d/%0d, deqset %0d/%0d, og0clr %0d/%0d, og1clr %0d/%0d, top_bad=%0b",
               v, W[v], nb, W[v]-1, nset, want, nc0, w0, nc1, w1, top_bad[v]);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
