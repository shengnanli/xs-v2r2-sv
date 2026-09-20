// ============================================================================
// tb —— RealWBArbiter 家族 UT：9 个 golden 变体与重写件逐拍双例化比对。
//
// 本族是**纯组合**的固定优先级选择（无时钟、无寄存器），判别力只能靠覆盖：
//   1. out_valid 取遍 0/1；
//   2. **每一路都真的赢过一次**（比它编号小的全不请求、它自己请求）——
//      只比端口值不管谁赢的话，把优先级写反也可能长时间不暴露；
//   3. in_ready 逐路取遍 0/1。★第 0 路例外★：golden 里 io_in_0_ready 恒 1，
//      所以只要求它取到 1；N=1 的变体连这个端口都没有，整项跳过。
//
// 激励：每变体独立的 4 位 valid（全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 随机六种轮换），
// payload 每路独立随机（Wen 位、pdest、data 各取最大宽度后按变体切片）。
//
// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。
// ============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NV = 9;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;
  `define CK(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end

  localparam int NIN [NV] = '{3, 4, 2, 1, 2, 1, 2, 1, 1};
  localparam bit HASRDY [NV] = '{1'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0};

  logic [1:0]   wen   [4];
  logic [7:0]   pdest [4];
  logic [127:0] data  [4];
  logic [3:0]   vld   [NV];

  // ---- RealWBArbiter : N=3 payload {rfWen:1, pdest:8, data:64} ----
  logic [2:0] g_RealWBArbiter_rdy, i_RealWBArbiter_rdy;
  logic g_RealWBArbiter_ov, i_RealWBArbiter_ov;
  logic [0:0] g_RealWBArbiter_rfWen, i_RealWBArbiter_rfWen;
  logic [7:0] g_RealWBArbiter_pdest, i_RealWBArbiter_pdest;
  logic [63:0] g_RealWBArbiter_data, i_RealWBArbiter_data;
  RealWBArbiter u_g_RealWBArbiter (
    .io_in_0_ready (g_RealWBArbiter_rdy[0]),
    .io_in_0_valid (vld[0][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_in_1_ready (g_RealWBArbiter_rdy[1]),
    .io_in_1_valid (vld[0][1]),
    .io_in_1_bits_rfWen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][7:0]),
    .io_in_1_bits_data (data[1][63:0]),
    .io_in_2_ready (g_RealWBArbiter_rdy[2]),
    .io_in_2_valid (vld[0][2]),
    .io_in_2_bits_rfWen (wen[2][0]),
    .io_in_2_bits_pdest (pdest[2][7:0]),
    .io_in_2_bits_data (data[2][63:0]),
    .io_out_valid (g_RealWBArbiter_ov),
    .io_out_bits_rfWen (g_RealWBArbiter_rfWen),
    .io_out_bits_pdest (g_RealWBArbiter_pdest),
    .io_out_bits_data (g_RealWBArbiter_data)
  );
  RealWBArbiter_xs u_i_RealWBArbiter (
    .io_in_0_ready (i_RealWBArbiter_rdy[0]),
    .io_in_0_valid (vld[0][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_in_1_ready (i_RealWBArbiter_rdy[1]),
    .io_in_1_valid (vld[0][1]),
    .io_in_1_bits_rfWen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][7:0]),
    .io_in_1_bits_data (data[1][63:0]),
    .io_in_2_ready (i_RealWBArbiter_rdy[2]),
    .io_in_2_valid (vld[0][2]),
    .io_in_2_bits_rfWen (wen[2][0]),
    .io_in_2_bits_pdest (pdest[2][7:0]),
    .io_in_2_bits_data (data[2][63:0]),
    .io_out_valid (i_RealWBArbiter_ov),
    .io_out_bits_rfWen (i_RealWBArbiter_rfWen),
    .io_out_bits_pdest (i_RealWBArbiter_pdest),
    .io_out_bits_data (i_RealWBArbiter_data)
  );
  // ---- RealWBArbiter_1 : N=4 payload {rfWen:1, pdest:8, data:64} ----
  logic [3:0] g_RealWBArbiter_1_rdy, i_RealWBArbiter_1_rdy;
  logic g_RealWBArbiter_1_ov, i_RealWBArbiter_1_ov;
  logic [0:0] g_RealWBArbiter_1_rfWen, i_RealWBArbiter_1_rfWen;
  logic [7:0] g_RealWBArbiter_1_pdest, i_RealWBArbiter_1_pdest;
  logic [63:0] g_RealWBArbiter_1_data, i_RealWBArbiter_1_data;
  RealWBArbiter_1 u_g_RealWBArbiter_1 (
    .io_in_0_ready (g_RealWBArbiter_1_rdy[0]),
    .io_in_0_valid (vld[1][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_in_1_ready (g_RealWBArbiter_1_rdy[1]),
    .io_in_1_valid (vld[1][1]),
    .io_in_1_bits_rfWen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][7:0]),
    .io_in_1_bits_data (data[1][63:0]),
    .io_in_2_ready (g_RealWBArbiter_1_rdy[2]),
    .io_in_2_valid (vld[1][2]),
    .io_in_2_bits_rfWen (wen[2][0]),
    .io_in_2_bits_pdest (pdest[2][7:0]),
    .io_in_2_bits_data (data[2][63:0]),
    .io_in_3_ready (g_RealWBArbiter_1_rdy[3]),
    .io_in_3_valid (vld[1][3]),
    .io_in_3_bits_rfWen (wen[3][0]),
    .io_in_3_bits_pdest (pdest[3][7:0]),
    .io_in_3_bits_data (data[3][63:0]),
    .io_out_valid (g_RealWBArbiter_1_ov),
    .io_out_bits_rfWen (g_RealWBArbiter_1_rfWen),
    .io_out_bits_pdest (g_RealWBArbiter_1_pdest),
    .io_out_bits_data (g_RealWBArbiter_1_data)
  );
  RealWBArbiter_1_xs u_i_RealWBArbiter_1 (
    .io_in_0_ready (i_RealWBArbiter_1_rdy[0]),
    .io_in_0_valid (vld[1][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_in_1_ready (i_RealWBArbiter_1_rdy[1]),
    .io_in_1_valid (vld[1][1]),
    .io_in_1_bits_rfWen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][7:0]),
    .io_in_1_bits_data (data[1][63:0]),
    .io_in_2_ready (i_RealWBArbiter_1_rdy[2]),
    .io_in_2_valid (vld[1][2]),
    .io_in_2_bits_rfWen (wen[2][0]),
    .io_in_2_bits_pdest (pdest[2][7:0]),
    .io_in_2_bits_data (data[2][63:0]),
    .io_in_3_ready (i_RealWBArbiter_1_rdy[3]),
    .io_in_3_valid (vld[1][3]),
    .io_in_3_bits_rfWen (wen[3][0]),
    .io_in_3_bits_pdest (pdest[3][7:0]),
    .io_in_3_bits_data (data[3][63:0]),
    .io_out_valid (i_RealWBArbiter_1_ov),
    .io_out_bits_rfWen (i_RealWBArbiter_1_rfWen),
    .io_out_bits_pdest (i_RealWBArbiter_1_pdest),
    .io_out_bits_data (i_RealWBArbiter_1_data)
  );
  // ---- RealWBArbiter_2 : N=2 payload {rfWen:1, fpWen:1, pdest:8, data:64} ----
  logic [1:0] g_RealWBArbiter_2_rdy, i_RealWBArbiter_2_rdy;
  logic g_RealWBArbiter_2_ov, i_RealWBArbiter_2_ov;
  logic [0:0] g_RealWBArbiter_2_rfWen, i_RealWBArbiter_2_rfWen;
  logic [0:0] g_RealWBArbiter_2_fpWen, i_RealWBArbiter_2_fpWen;
  logic [7:0] g_RealWBArbiter_2_pdest, i_RealWBArbiter_2_pdest;
  logic [63:0] g_RealWBArbiter_2_data, i_RealWBArbiter_2_data;
  RealWBArbiter_2 u_g_RealWBArbiter_2 (
    .io_in_0_ready (g_RealWBArbiter_2_rdy[0]),
    .io_in_0_valid (vld[2][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_fpWen (wen[0][1]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_in_1_ready (g_RealWBArbiter_2_rdy[1]),
    .io_in_1_valid (vld[2][1]),
    .io_in_1_bits_rfWen (wen[1][0]),
    .io_in_1_bits_fpWen (wen[1][1]),
    .io_in_1_bits_pdest (pdest[1][7:0]),
    .io_in_1_bits_data (data[1][63:0]),
    .io_out_valid (g_RealWBArbiter_2_ov),
    .io_out_bits_rfWen (g_RealWBArbiter_2_rfWen),
    .io_out_bits_fpWen (g_RealWBArbiter_2_fpWen),
    .io_out_bits_pdest (g_RealWBArbiter_2_pdest),
    .io_out_bits_data (g_RealWBArbiter_2_data)
  );
  RealWBArbiter_2_xs u_i_RealWBArbiter_2 (
    .io_in_0_ready (i_RealWBArbiter_2_rdy[0]),
    .io_in_0_valid (vld[2][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_fpWen (wen[0][1]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_in_1_ready (i_RealWBArbiter_2_rdy[1]),
    .io_in_1_valid (vld[2][1]),
    .io_in_1_bits_rfWen (wen[1][0]),
    .io_in_1_bits_fpWen (wen[1][1]),
    .io_in_1_bits_pdest (pdest[1][7:0]),
    .io_in_1_bits_data (data[1][63:0]),
    .io_out_valid (i_RealWBArbiter_2_ov),
    .io_out_bits_rfWen (i_RealWBArbiter_2_rfWen),
    .io_out_bits_fpWen (i_RealWBArbiter_2_fpWen),
    .io_out_bits_pdest (i_RealWBArbiter_2_pdest),
    .io_out_bits_data (i_RealWBArbiter_2_data)
  );
  // ---- RealWBArbiter_3 : N=1 payload {rfWen:1, fpWen:1, pdest:8, data:64} ----
  logic g_RealWBArbiter_3_ov, i_RealWBArbiter_3_ov;
  logic [0:0] g_RealWBArbiter_3_rfWen, i_RealWBArbiter_3_rfWen;
  logic [0:0] g_RealWBArbiter_3_fpWen, i_RealWBArbiter_3_fpWen;
  logic [7:0] g_RealWBArbiter_3_pdest, i_RealWBArbiter_3_pdest;
  logic [63:0] g_RealWBArbiter_3_data, i_RealWBArbiter_3_data;
  RealWBArbiter_3 u_g_RealWBArbiter_3 (
    .io_in_0_valid (vld[3][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_fpWen (wen[0][1]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_out_valid (g_RealWBArbiter_3_ov),
    .io_out_bits_rfWen (g_RealWBArbiter_3_rfWen),
    .io_out_bits_fpWen (g_RealWBArbiter_3_fpWen),
    .io_out_bits_pdest (g_RealWBArbiter_3_pdest),
    .io_out_bits_data (g_RealWBArbiter_3_data)
  );
  RealWBArbiter_3_xs u_i_RealWBArbiter_3 (
    .io_in_0_valid (vld[3][0]),
    .io_in_0_bits_rfWen (wen[0][0]),
    .io_in_0_bits_fpWen (wen[0][1]),
    .io_in_0_bits_pdest (pdest[0][7:0]),
    .io_in_0_bits_data (data[0][63:0]),
    .io_out_valid (i_RealWBArbiter_3_ov),
    .io_out_bits_rfWen (i_RealWBArbiter_3_rfWen),
    .io_out_bits_fpWen (i_RealWBArbiter_3_fpWen),
    .io_out_bits_pdest (i_RealWBArbiter_3_pdest),
    .io_out_bits_data (i_RealWBArbiter_3_data)
  );
  // ---- RealWBArbiter_14 : N=2 payload {vecWen:1, pdest:7, data:128} ----
  logic [1:0] g_RealWBArbiter_14_rdy, i_RealWBArbiter_14_rdy;
  logic g_RealWBArbiter_14_ov, i_RealWBArbiter_14_ov;
  logic [0:0] g_RealWBArbiter_14_vecWen, i_RealWBArbiter_14_vecWen;
  logic [6:0] g_RealWBArbiter_14_pdest, i_RealWBArbiter_14_pdest;
  logic [127:0] g_RealWBArbiter_14_data, i_RealWBArbiter_14_data;
  RealWBArbiter_14 u_g_RealWBArbiter_14 (
    .io_in_0_ready (g_RealWBArbiter_14_rdy[0]),
    .io_in_0_valid (vld[4][0]),
    .io_in_0_bits_vecWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][6:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_in_1_ready (g_RealWBArbiter_14_rdy[1]),
    .io_in_1_valid (vld[4][1]),
    .io_in_1_bits_vecWen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][6:0]),
    .io_in_1_bits_data (data[1][127:0]),
    .io_out_valid (g_RealWBArbiter_14_ov),
    .io_out_bits_vecWen (g_RealWBArbiter_14_vecWen),
    .io_out_bits_pdest (g_RealWBArbiter_14_pdest),
    .io_out_bits_data (g_RealWBArbiter_14_data)
  );
  RealWBArbiter_14_xs u_i_RealWBArbiter_14 (
    .io_in_0_ready (i_RealWBArbiter_14_rdy[0]),
    .io_in_0_valid (vld[4][0]),
    .io_in_0_bits_vecWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][6:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_in_1_ready (i_RealWBArbiter_14_rdy[1]),
    .io_in_1_valid (vld[4][1]),
    .io_in_1_bits_vecWen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][6:0]),
    .io_in_1_bits_data (data[1][127:0]),
    .io_out_valid (i_RealWBArbiter_14_ov),
    .io_out_bits_vecWen (i_RealWBArbiter_14_vecWen),
    .io_out_bits_pdest (i_RealWBArbiter_14_pdest),
    .io_out_bits_data (i_RealWBArbiter_14_data)
  );
  // ---- RealWBArbiter_15 : N=1 payload {vecWen:1, pdest:7, data:128} ----
  logic g_RealWBArbiter_15_ov, i_RealWBArbiter_15_ov;
  logic [0:0] g_RealWBArbiter_15_vecWen, i_RealWBArbiter_15_vecWen;
  logic [6:0] g_RealWBArbiter_15_pdest, i_RealWBArbiter_15_pdest;
  logic [127:0] g_RealWBArbiter_15_data, i_RealWBArbiter_15_data;
  RealWBArbiter_15 u_g_RealWBArbiter_15 (
    .io_in_0_valid (vld[5][0]),
    .io_in_0_bits_vecWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][6:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_out_valid (g_RealWBArbiter_15_ov),
    .io_out_bits_vecWen (g_RealWBArbiter_15_vecWen),
    .io_out_bits_pdest (g_RealWBArbiter_15_pdest),
    .io_out_bits_data (g_RealWBArbiter_15_data)
  );
  RealWBArbiter_15_xs u_i_RealWBArbiter_15 (
    .io_in_0_valid (vld[5][0]),
    .io_in_0_bits_vecWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][6:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_out_valid (i_RealWBArbiter_15_ov),
    .io_out_bits_vecWen (i_RealWBArbiter_15_vecWen),
    .io_out_bits_pdest (i_RealWBArbiter_15_pdest),
    .io_out_bits_data (i_RealWBArbiter_15_data)
  );
  // ---- RealWBArbiter_20 : N=2 payload {v0Wen:1, pdest:5, data:128} ----
  logic [1:0] g_RealWBArbiter_20_rdy, i_RealWBArbiter_20_rdy;
  logic g_RealWBArbiter_20_ov, i_RealWBArbiter_20_ov;
  logic [0:0] g_RealWBArbiter_20_v0Wen, i_RealWBArbiter_20_v0Wen;
  logic [4:0] g_RealWBArbiter_20_pdest, i_RealWBArbiter_20_pdest;
  logic [127:0] g_RealWBArbiter_20_data, i_RealWBArbiter_20_data;
  RealWBArbiter_20 u_g_RealWBArbiter_20 (
    .io_in_0_ready (g_RealWBArbiter_20_rdy[0]),
    .io_in_0_valid (vld[6][0]),
    .io_in_0_bits_v0Wen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][4:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_in_1_ready (g_RealWBArbiter_20_rdy[1]),
    .io_in_1_valid (vld[6][1]),
    .io_in_1_bits_v0Wen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][4:0]),
    .io_in_1_bits_data (data[1][127:0]),
    .io_out_valid (g_RealWBArbiter_20_ov),
    .io_out_bits_v0Wen (g_RealWBArbiter_20_v0Wen),
    .io_out_bits_pdest (g_RealWBArbiter_20_pdest),
    .io_out_bits_data (g_RealWBArbiter_20_data)
  );
  RealWBArbiter_20_xs u_i_RealWBArbiter_20 (
    .io_in_0_ready (i_RealWBArbiter_20_rdy[0]),
    .io_in_0_valid (vld[6][0]),
    .io_in_0_bits_v0Wen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][4:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_in_1_ready (i_RealWBArbiter_20_rdy[1]),
    .io_in_1_valid (vld[6][1]),
    .io_in_1_bits_v0Wen (wen[1][0]),
    .io_in_1_bits_pdest (pdest[1][4:0]),
    .io_in_1_bits_data (data[1][127:0]),
    .io_out_valid (i_RealWBArbiter_20_ov),
    .io_out_bits_v0Wen (i_RealWBArbiter_20_v0Wen),
    .io_out_bits_pdest (i_RealWBArbiter_20_pdest),
    .io_out_bits_data (i_RealWBArbiter_20_data)
  );
  // ---- RealWBArbiter_21 : N=1 payload {v0Wen:1, pdest:5, data:128} ----
  logic g_RealWBArbiter_21_ov, i_RealWBArbiter_21_ov;
  logic [0:0] g_RealWBArbiter_21_v0Wen, i_RealWBArbiter_21_v0Wen;
  logic [4:0] g_RealWBArbiter_21_pdest, i_RealWBArbiter_21_pdest;
  logic [127:0] g_RealWBArbiter_21_data, i_RealWBArbiter_21_data;
  RealWBArbiter_21 u_g_RealWBArbiter_21 (
    .io_in_0_valid (vld[7][0]),
    .io_in_0_bits_v0Wen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][4:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_out_valid (g_RealWBArbiter_21_ov),
    .io_out_bits_v0Wen (g_RealWBArbiter_21_v0Wen),
    .io_out_bits_pdest (g_RealWBArbiter_21_pdest),
    .io_out_bits_data (g_RealWBArbiter_21_data)
  );
  RealWBArbiter_21_xs u_i_RealWBArbiter_21 (
    .io_in_0_valid (vld[7][0]),
    .io_in_0_bits_v0Wen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][4:0]),
    .io_in_0_bits_data (data[0][127:0]),
    .io_out_valid (i_RealWBArbiter_21_ov),
    .io_out_bits_v0Wen (i_RealWBArbiter_21_v0Wen),
    .io_out_bits_pdest (i_RealWBArbiter_21_pdest),
    .io_out_bits_data (i_RealWBArbiter_21_data)
  );
  // ---- RealWBArbiter_26 : N=1 payload {vlWen:1, pdest:5, data:8} ----
  logic g_RealWBArbiter_26_ov, i_RealWBArbiter_26_ov;
  logic [0:0] g_RealWBArbiter_26_vlWen, i_RealWBArbiter_26_vlWen;
  logic [4:0] g_RealWBArbiter_26_pdest, i_RealWBArbiter_26_pdest;
  logic [7:0] g_RealWBArbiter_26_data, i_RealWBArbiter_26_data;
  RealWBArbiter_26 u_g_RealWBArbiter_26 (
    .io_in_0_valid (vld[8][0]),
    .io_in_0_bits_vlWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][4:0]),
    .io_in_0_bits_data (data[0][7:0]),
    .io_out_valid (g_RealWBArbiter_26_ov),
    .io_out_bits_vlWen (g_RealWBArbiter_26_vlWen),
    .io_out_bits_pdest (g_RealWBArbiter_26_pdest),
    .io_out_bits_data (g_RealWBArbiter_26_data)
  );
  RealWBArbiter_26_xs u_i_RealWBArbiter_26 (
    .io_in_0_valid (vld[8][0]),
    .io_in_0_bits_vlWen (wen[0][0]),
    .io_in_0_bits_pdest (pdest[0][4:0]),
    .io_in_0_bits_data (data[0][7:0]),
    .io_out_valid (i_RealWBArbiter_26_ov),
    .io_out_bits_vlWen (i_RealWBArbiter_26_vlWen),
    .io_out_bits_pdest (i_RealWBArbiter_26_pdest),
    .io_out_bits_data (i_RealWBArbiter_26_data)
  );

  bit [1:0] cov_ov  [NV];
  bit [1:0] cov_rdy [NV][4];
  bit       cov_win [NV][4];    // 第 i 路真的赢过（比它小的全不请求且它请求）

  task automatic check();
    `CK(g_RealWBArbiter_ov, i_RealWBArbiter_ov, "RealWBArbiter.out_valid")
    cov_ov[0][g_RealWBArbiter_ov] = 1'b1;
    `CK(g_RealWBArbiter_rdy, i_RealWBArbiter_rdy, "RealWBArbiter.in_ready")
    for (int k = 0; k < 3; k++) cov_rdy[0][k][g_RealWBArbiter_rdy[k]] = 1'b1;
    `CK(g_RealWBArbiter_rfWen, i_RealWBArbiter_rfWen, "RealWBArbiter.rfWen")
    `CK(g_RealWBArbiter_pdest, i_RealWBArbiter_pdest, "RealWBArbiter.pdest")
    `CK(g_RealWBArbiter_data, i_RealWBArbiter_data, "RealWBArbiter.data")
    for (int k = 0; k < 3; k++)
      if (vld[0][k] && ((vld[0] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[0][k] = 1'b1;
    `CK(g_RealWBArbiter_1_ov, i_RealWBArbiter_1_ov, "RealWBArbiter_1.out_valid")
    cov_ov[1][g_RealWBArbiter_1_ov] = 1'b1;
    `CK(g_RealWBArbiter_1_rdy, i_RealWBArbiter_1_rdy, "RealWBArbiter_1.in_ready")
    for (int k = 0; k < 4; k++) cov_rdy[1][k][g_RealWBArbiter_1_rdy[k]] = 1'b1;
    `CK(g_RealWBArbiter_1_rfWen, i_RealWBArbiter_1_rfWen, "RealWBArbiter_1.rfWen")
    `CK(g_RealWBArbiter_1_pdest, i_RealWBArbiter_1_pdest, "RealWBArbiter_1.pdest")
    `CK(g_RealWBArbiter_1_data, i_RealWBArbiter_1_data, "RealWBArbiter_1.data")
    for (int k = 0; k < 4; k++)
      if (vld[1][k] && ((vld[1] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[1][k] = 1'b1;
    `CK(g_RealWBArbiter_2_ov, i_RealWBArbiter_2_ov, "RealWBArbiter_2.out_valid")
    cov_ov[2][g_RealWBArbiter_2_ov] = 1'b1;
    `CK(g_RealWBArbiter_2_rdy, i_RealWBArbiter_2_rdy, "RealWBArbiter_2.in_ready")
    for (int k = 0; k < 2; k++) cov_rdy[2][k][g_RealWBArbiter_2_rdy[k]] = 1'b1;
    `CK(g_RealWBArbiter_2_rfWen, i_RealWBArbiter_2_rfWen, "RealWBArbiter_2.rfWen")
    `CK(g_RealWBArbiter_2_fpWen, i_RealWBArbiter_2_fpWen, "RealWBArbiter_2.fpWen")
    `CK(g_RealWBArbiter_2_pdest, i_RealWBArbiter_2_pdest, "RealWBArbiter_2.pdest")
    `CK(g_RealWBArbiter_2_data, i_RealWBArbiter_2_data, "RealWBArbiter_2.data")
    for (int k = 0; k < 2; k++)
      if (vld[2][k] && ((vld[2] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[2][k] = 1'b1;
    `CK(g_RealWBArbiter_3_ov, i_RealWBArbiter_3_ov, "RealWBArbiter_3.out_valid")
    cov_ov[3][g_RealWBArbiter_3_ov] = 1'b1;
    `CK(g_RealWBArbiter_3_rfWen, i_RealWBArbiter_3_rfWen, "RealWBArbiter_3.rfWen")
    `CK(g_RealWBArbiter_3_fpWen, i_RealWBArbiter_3_fpWen, "RealWBArbiter_3.fpWen")
    `CK(g_RealWBArbiter_3_pdest, i_RealWBArbiter_3_pdest, "RealWBArbiter_3.pdest")
    `CK(g_RealWBArbiter_3_data, i_RealWBArbiter_3_data, "RealWBArbiter_3.data")
    for (int k = 0; k < 1; k++)
      if (vld[3][k] && ((vld[3] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[3][k] = 1'b1;
    `CK(g_RealWBArbiter_14_ov, i_RealWBArbiter_14_ov, "RealWBArbiter_14.out_valid")
    cov_ov[4][g_RealWBArbiter_14_ov] = 1'b1;
    `CK(g_RealWBArbiter_14_rdy, i_RealWBArbiter_14_rdy, "RealWBArbiter_14.in_ready")
    for (int k = 0; k < 2; k++) cov_rdy[4][k][g_RealWBArbiter_14_rdy[k]] = 1'b1;
    `CK(g_RealWBArbiter_14_vecWen, i_RealWBArbiter_14_vecWen, "RealWBArbiter_14.vecWen")
    `CK(g_RealWBArbiter_14_pdest, i_RealWBArbiter_14_pdest, "RealWBArbiter_14.pdest")
    `CK(g_RealWBArbiter_14_data, i_RealWBArbiter_14_data, "RealWBArbiter_14.data")
    for (int k = 0; k < 2; k++)
      if (vld[4][k] && ((vld[4] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[4][k] = 1'b1;
    `CK(g_RealWBArbiter_15_ov, i_RealWBArbiter_15_ov, "RealWBArbiter_15.out_valid")
    cov_ov[5][g_RealWBArbiter_15_ov] = 1'b1;
    `CK(g_RealWBArbiter_15_vecWen, i_RealWBArbiter_15_vecWen, "RealWBArbiter_15.vecWen")
    `CK(g_RealWBArbiter_15_pdest, i_RealWBArbiter_15_pdest, "RealWBArbiter_15.pdest")
    `CK(g_RealWBArbiter_15_data, i_RealWBArbiter_15_data, "RealWBArbiter_15.data")
    for (int k = 0; k < 1; k++)
      if (vld[5][k] && ((vld[5] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[5][k] = 1'b1;
    `CK(g_RealWBArbiter_20_ov, i_RealWBArbiter_20_ov, "RealWBArbiter_20.out_valid")
    cov_ov[6][g_RealWBArbiter_20_ov] = 1'b1;
    `CK(g_RealWBArbiter_20_rdy, i_RealWBArbiter_20_rdy, "RealWBArbiter_20.in_ready")
    for (int k = 0; k < 2; k++) cov_rdy[6][k][g_RealWBArbiter_20_rdy[k]] = 1'b1;
    `CK(g_RealWBArbiter_20_v0Wen, i_RealWBArbiter_20_v0Wen, "RealWBArbiter_20.v0Wen")
    `CK(g_RealWBArbiter_20_pdest, i_RealWBArbiter_20_pdest, "RealWBArbiter_20.pdest")
    `CK(g_RealWBArbiter_20_data, i_RealWBArbiter_20_data, "RealWBArbiter_20.data")
    for (int k = 0; k < 2; k++)
      if (vld[6][k] && ((vld[6] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[6][k] = 1'b1;
    `CK(g_RealWBArbiter_21_ov, i_RealWBArbiter_21_ov, "RealWBArbiter_21.out_valid")
    cov_ov[7][g_RealWBArbiter_21_ov] = 1'b1;
    `CK(g_RealWBArbiter_21_v0Wen, i_RealWBArbiter_21_v0Wen, "RealWBArbiter_21.v0Wen")
    `CK(g_RealWBArbiter_21_pdest, i_RealWBArbiter_21_pdest, "RealWBArbiter_21.pdest")
    `CK(g_RealWBArbiter_21_data, i_RealWBArbiter_21_data, "RealWBArbiter_21.data")
    for (int k = 0; k < 1; k++)
      if (vld[7][k] && ((vld[7] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[7][k] = 1'b1;
    `CK(g_RealWBArbiter_26_ov, i_RealWBArbiter_26_ov, "RealWBArbiter_26.out_valid")
    cov_ov[8][g_RealWBArbiter_26_ov] = 1'b1;
    `CK(g_RealWBArbiter_26_vlWen, i_RealWBArbiter_26_vlWen, "RealWBArbiter_26.vlWen")
    `CK(g_RealWBArbiter_26_pdest, i_RealWBArbiter_26_pdest, "RealWBArbiter_26.pdest")
    `CK(g_RealWBArbiter_26_data, i_RealWBArbiter_26_data, "RealWBArbiter_26.data")
    for (int k = 0; k < 1; k++)
      if (vld[8][k] && ((vld[8] & ((4'b1 << k) - 4'b1)) == 4'b0))
        cov_win[8][k] = 1'b1;
  endtask

  task automatic drive();
    for (int v = 0; v < NV; v++)
      case ($urandom_range(0, 5))
        0: vld[v] = '0;
        1: vld[v] = '1;
        2: vld[v] = 4'b1 << $urandom_range(0, 3);
        3: vld[v] = $urandom & $urandom;
        4: vld[v] = $urandom | $urandom;
        default: vld[v] = $urandom;
      endcase
    for (int i = 0; i < 4; i++) begin
      wen[i]   = $urandom;
      pdest[i] = $urandom;
      for (int b = 0; b < 128; b += 32) data[i][b+:32] = $urandom;
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      cov_ov[v] = '0;
      for (int k = 0; k < 4; k++) begin cov_rdy[v][k] = '0; cov_win[v][k] = 1'b0; end
      vld[v] = '0;
    end
    for (int i = 0; i < 4; i++) begin wen[i] = '0; pdest[i] = '0; data[i] = '0; end
    repeat (2) @(posedge clk);
    repeat (NCYCLES) begin drive(); #1; check(); @(posedge clk); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: out_valid 0/1 | 每路赢过 | ready 逐路 0/1（第 0 路恒 1）---");
    for (int v = 0; v < NV; v++) begin
      int nw = 0, nr = 0, wr = 0;
      for (int k = 0; k < NIN[v]; k++) begin
        if (cov_win[v][k]) nw++;
        if (HASRDY[v]) begin
          wr++;
          if (k == 0) begin if (cov_rdy[v][0][1]) nr++; end       // golden 恒 1
          else if (cov_rdy[v][k] == 2'b11) nr++;
        end
      end
      if (cov_ov[v] != 2'b11 || nw != NIN[v] || nr != wr) bad++;
      $display("  variant[%0d] N=%0d : out_valid=%b win %0d/%0d ready %0d/%0d",
               v, NIN[v], cov_ov[v], nw, NIN[v], nr, wr);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
