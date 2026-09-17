// =============================================================================
// tb —— CSA3_2 位宽变体家族 UT：9 个 golden 变体与重写件逐个双例化比对。
//
// 变体全是「逐位独立的全加器阵列」，位与位之间无进位链，所以**每个位位置的
// 输入空间只有 8 种**(a,b,c)。本 tb 因此不追求向量级穷举（W=70 时 2^210 不可能），
// 而是逐位统计：每个变体的每一个位位置都必须把 8 种组合走遍 —— 对逐位独立的
// 函数来说，这就是**穷举证明**，不是抽样。判据写进了 TEST PASSED。
//
// 激励：全 0 / 全 1 / 交替 / 单点游走 / 随机，覆盖进位链边界（虽然本族无进位链，
// 但同样的激励形状能直接暴露"误加了移位或跨位耦合"这类错误）。
// 本文件由 verif/ut/CSA3_2Variants/gen.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NV = 9;
  localparam int MAXW = 70;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;

  logic [MAXW-1:0] a, b, c;
  // 每个变体的两侧输出
  logic [9:0] g_CSA3_2_3956_0, g_CSA3_2_3956_1, i_CSA3_2_3956_0, i_CSA3_2_3956_1;
  logic [67:0] g_CSA3_2_3960_0, g_CSA3_2_3960_1, i_CSA3_2_3960_0, i_CSA3_2_3960_1;
  logic [12:0] g_CSA3_2_3962_0, g_CSA3_2_3962_1, i_CSA3_2_3962_0, i_CSA3_2_3962_1;
  logic [21:0] g_CSA3_2_3987_0, g_CSA3_2_3987_1, i_CSA3_2_3987_0, i_CSA3_2_3987_1;
  logic [7:0] g_CSA3_2_3988_0, g_CSA3_2_3988_1, i_CSA3_2_3988_0, i_CSA3_2_3988_1;
  logic [8:0] g_CSA3_2_3992_0, g_CSA3_2_3992_1, i_CSA3_2_3992_0, i_CSA3_2_3992_1;
  logic [10:0] g_CSA3_2_4017_0, g_CSA3_2_4017_1, i_CSA3_2_4017_0, i_CSA3_2_4017_1;
  logic [37:0] g_CSA3_2_4111_0, g_CSA3_2_4111_1, i_CSA3_2_4111_0, i_CSA3_2_4111_1;
  logic [69:0] g_CSA3_2_4173_0, g_CSA3_2_4173_1, i_CSA3_2_4173_0, i_CSA3_2_4173_1;

  CSA3_2_3956    u_g_CSA3_2_3956 (.io_in_0(a[9:0]), .io_in_1(b[9:0]), .io_in_2(c[9:0]),
                  .io_out_0(g_CSA3_2_3956_0), .io_out_1(g_CSA3_2_3956_1));
  CSA3_2_3956_xs u_i_CSA3_2_3956 (.io_in_0(a[9:0]), .io_in_1(b[9:0]), .io_in_2(c[9:0]),
                  .io_out_0(i_CSA3_2_3956_0), .io_out_1(i_CSA3_2_3956_1));
  CSA3_2_3960    u_g_CSA3_2_3960 (.io_in_0(a[67:0]), .io_in_1(b[67:0]), .io_in_2(c[67:0]),
                  .io_out_0(g_CSA3_2_3960_0), .io_out_1(g_CSA3_2_3960_1));
  CSA3_2_3960_xs u_i_CSA3_2_3960 (.io_in_0(a[67:0]), .io_in_1(b[67:0]), .io_in_2(c[67:0]),
                  .io_out_0(i_CSA3_2_3960_0), .io_out_1(i_CSA3_2_3960_1));
  CSA3_2_3962    u_g_CSA3_2_3962 (.io_in_0(a[12:0]), .io_in_1(b[12:0]), .io_in_2(c[12:0]),
                  .io_out_0(g_CSA3_2_3962_0), .io_out_1(g_CSA3_2_3962_1));
  CSA3_2_3962_xs u_i_CSA3_2_3962 (.io_in_0(a[12:0]), .io_in_1(b[12:0]), .io_in_2(c[12:0]),
                  .io_out_0(i_CSA3_2_3962_0), .io_out_1(i_CSA3_2_3962_1));
  CSA3_2_3987    u_g_CSA3_2_3987 (.io_in_0(a[21:0]), .io_in_1(b[21:0]), .io_in_2(c[21:0]),
                  .io_out_0(g_CSA3_2_3987_0), .io_out_1(g_CSA3_2_3987_1));
  CSA3_2_3987_xs u_i_CSA3_2_3987 (.io_in_0(a[21:0]), .io_in_1(b[21:0]), .io_in_2(c[21:0]),
                  .io_out_0(i_CSA3_2_3987_0), .io_out_1(i_CSA3_2_3987_1));
  CSA3_2_3988    u_g_CSA3_2_3988 (.io_in_0(a[7:0]), .io_in_1(b[7:0]), .io_in_2(c[7:0]),
                  .io_out_0(g_CSA3_2_3988_0), .io_out_1(g_CSA3_2_3988_1));
  CSA3_2_3988_xs u_i_CSA3_2_3988 (.io_in_0(a[7:0]), .io_in_1(b[7:0]), .io_in_2(c[7:0]),
                  .io_out_0(i_CSA3_2_3988_0), .io_out_1(i_CSA3_2_3988_1));
  CSA3_2_3992    u_g_CSA3_2_3992 (.io_in_0(a[8:0]), .io_in_1(b[8:0]), .io_in_2(c[8:0]),
                  .io_out_0(g_CSA3_2_3992_0), .io_out_1(g_CSA3_2_3992_1));
  CSA3_2_3992_xs u_i_CSA3_2_3992 (.io_in_0(a[8:0]), .io_in_1(b[8:0]), .io_in_2(c[8:0]),
                  .io_out_0(i_CSA3_2_3992_0), .io_out_1(i_CSA3_2_3992_1));
  CSA3_2_4017    u_g_CSA3_2_4017 (.io_in_0(a[10:0]), .io_in_1(b[10:0]), .io_in_2(c[10:0]),
                  .io_out_0(g_CSA3_2_4017_0), .io_out_1(g_CSA3_2_4017_1));
  CSA3_2_4017_xs u_i_CSA3_2_4017 (.io_in_0(a[10:0]), .io_in_1(b[10:0]), .io_in_2(c[10:0]),
                  .io_out_0(i_CSA3_2_4017_0), .io_out_1(i_CSA3_2_4017_1));
  CSA3_2_4111    u_g_CSA3_2_4111 (.io_in_0(a[37:0]), .io_in_1(b[37:0]), .io_in_2(c[37:0]),
                  .io_out_0(g_CSA3_2_4111_0), .io_out_1(g_CSA3_2_4111_1));
  CSA3_2_4111_xs u_i_CSA3_2_4111 (.io_in_0(a[37:0]), .io_in_1(b[37:0]), .io_in_2(c[37:0]),
                  .io_out_0(i_CSA3_2_4111_0), .io_out_1(i_CSA3_2_4111_1));
  CSA3_2_4173    u_g_CSA3_2_4173 (.io_in_0(a[69:0]), .io_in_1(b[69:0]), .io_in_2(c[69:0]),
                  .io_out_0(g_CSA3_2_4173_0), .io_out_1(g_CSA3_2_4173_1));
  CSA3_2_4173_xs u_i_CSA3_2_4173 (.io_in_0(a[69:0]), .io_in_1(b[69:0]), .io_in_2(c[69:0]),
                  .io_out_0(i_CSA3_2_4173_0), .io_out_1(i_CSA3_2_4173_1));

  // cov[v][i] 的第 k 位 = 变体 v 的第 i 位见过输入组合 k={a,b,c}
  logic [7:0] cov [NV][MAXW];
  int W [NV];

  task automatic drive();
    case ($urandom_range(0, 5))
      0: begin a = '0;      b = '0;      c = '0;      end
      1: begin a = '1;      b = '1;      c = '1;      end
      2: begin a = {MAXW{1'b1}} & {MAXW/2{2'b01}}; b = ~a; c = a; end
      3: begin a = 1 << $urandom_range(0, MAXW-1);
               b = 1 << $urandom_range(0, MAXW-1);
               c = 1 << $urandom_range(0, MAXW-1); end
      4: begin a = $urandom & $urandom; b = $urandom; c = ~$urandom; end
      default: begin
        for (int k = 0; k < MAXW; k += 32) begin
          a[k+:1] = $urandom; b[k+:1] = $urandom; c[k+:1] = $urandom; end
        a = {$urandom,$urandom,$urandom}; b = {$urandom,$urandom,$urandom};
        c = {$urandom,$urandom,$urandom};
      end
    endcase
  endtask

  `define CK(g,i,nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end

  task automatic check();
    `CK(g_CSA3_2_3956_0, i_CSA3_2_3956_0, "CSA3_2_3956.out0")
    `CK(g_CSA3_2_3956_1, i_CSA3_2_3956_1, "CSA3_2_3956.out1")
    for (int i = 0; i < 10; i++) cov[0][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_3960_0, i_CSA3_2_3960_0, "CSA3_2_3960.out0")
    `CK(g_CSA3_2_3960_1, i_CSA3_2_3960_1, "CSA3_2_3960.out1")
    for (int i = 0; i < 68; i++) cov[1][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_3962_0, i_CSA3_2_3962_0, "CSA3_2_3962.out0")
    `CK(g_CSA3_2_3962_1, i_CSA3_2_3962_1, "CSA3_2_3962.out1")
    for (int i = 0; i < 13; i++) cov[2][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_3987_0, i_CSA3_2_3987_0, "CSA3_2_3987.out0")
    `CK(g_CSA3_2_3987_1, i_CSA3_2_3987_1, "CSA3_2_3987.out1")
    for (int i = 0; i < 22; i++) cov[3][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_3988_0, i_CSA3_2_3988_0, "CSA3_2_3988.out0")
    `CK(g_CSA3_2_3988_1, i_CSA3_2_3988_1, "CSA3_2_3988.out1")
    for (int i = 0; i < 8; i++) cov[4][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_3992_0, i_CSA3_2_3992_0, "CSA3_2_3992.out0")
    `CK(g_CSA3_2_3992_1, i_CSA3_2_3992_1, "CSA3_2_3992.out1")
    for (int i = 0; i < 9; i++) cov[5][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_4017_0, i_CSA3_2_4017_0, "CSA3_2_4017.out0")
    `CK(g_CSA3_2_4017_1, i_CSA3_2_4017_1, "CSA3_2_4017.out1")
    for (int i = 0; i < 11; i++) cov[6][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_4111_0, i_CSA3_2_4111_0, "CSA3_2_4111.out0")
    `CK(g_CSA3_2_4111_1, i_CSA3_2_4111_1, "CSA3_2_4111.out1")
    for (int i = 0; i < 38; i++) cov[7][i][{a[i],b[i],c[i]}] = 1'b1;
    `CK(g_CSA3_2_4173_0, i_CSA3_2_4173_0, "CSA3_2_4173.out0")
    `CK(g_CSA3_2_4173_1, i_CSA3_2_4173_1, "CSA3_2_4173.out1")
    for (int i = 0; i < 70; i++) cov[8][i][{a[i],b[i],c[i]}] = 1'b1;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    W[0] = 10;
    W[1] = 68;
    W[2] = 13;
    W[3] = 22;
    W[4] = 8;
    W[5] = 9;
    W[6] = 11;
    W[7] = 38;
    W[8] = 70;
    for (int v = 0; v < NV; v++) for (int i = 0; i < MAXW; i++) cov[v][i] = 8'h0;
    drive();
    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end
    report();
    $finish;
  end

  task automatic report();
    int bad_cov = 0;
    $display("--- coverage: 每个变体每一位是否见过全部 8 种 (a,b,c) ---");
    for (int v = 0; v < NV; v++) begin
      int full = 0;
      for (int i = 0; i < W[v]; i++) if (cov[v][i] == 8'hFF) full++;
      if (full != W[v]) bad_cov++;
      $display("  variant[%0d] W=%0d : %0d/%0d 位达成 8/8 组合", v, W[v], full, W[v]);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && bad_cov == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
