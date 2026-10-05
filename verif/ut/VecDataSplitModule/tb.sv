// =============================================================================
// tb —— VecDataSplitModule UT：golden 与重写件（VecDataSplitModule_xs）双例化，同输入逐拍比全部 30 个输出。
// 独立 oracle：第 k 个 W 位元素 = in[W*k +: W]（RVV 小端元素排列），在 tb 里逐元素取位后与重写件比。
// 激励：均匀随机 128 位，夹杂全 0 / 全 1 / 单热 / 交替 8 位块，确保每个输出位都见过 0 和 1（写进 PASS 判据）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_errors = 0;
  logic [127:0] in;
  logic [15:0][7:0]  g8,  i8;
  logic [7:0][15:0]  g16, i16;
  logic [3:0][31:0]  g32, i32;
  logic [1:0][63:0]  g64, i64;

  VecDataSplitModule u_g (.io_inVecData(in),
    .io_outVec8b_0(g8[0]), .io_outVec8b_1(g8[1]), .io_outVec8b_2(g8[2]), .io_outVec8b_3(g8[3]),
    .io_outVec8b_4(g8[4]), .io_outVec8b_5(g8[5]), .io_outVec8b_6(g8[6]), .io_outVec8b_7(g8[7]),
    .io_outVec8b_8(g8[8]), .io_outVec8b_9(g8[9]), .io_outVec8b_10(g8[10]), .io_outVec8b_11(g8[11]),
    .io_outVec8b_12(g8[12]), .io_outVec8b_13(g8[13]), .io_outVec8b_14(g8[14]), .io_outVec8b_15(g8[15]),
    .io_outVec16b_0(g16[0]), .io_outVec16b_1(g16[1]), .io_outVec16b_2(g16[2]), .io_outVec16b_3(g16[3]),
    .io_outVec16b_4(g16[4]), .io_outVec16b_5(g16[5]), .io_outVec16b_6(g16[6]), .io_outVec16b_7(g16[7]),
    .io_outVec32b_0(g32[0]), .io_outVec32b_1(g32[1]), .io_outVec32b_2(g32[2]), .io_outVec32b_3(g32[3]),
    .io_outVec64b_0(g64[0]), .io_outVec64b_1(g64[1]));
  VecDataSplitModule_xs u_i (.io_inVecData(in),
    .io_outVec8b_0(i8[0]), .io_outVec8b_1(i8[1]), .io_outVec8b_2(i8[2]), .io_outVec8b_3(i8[3]),
    .io_outVec8b_4(i8[4]), .io_outVec8b_5(i8[5]), .io_outVec8b_6(i8[6]), .io_outVec8b_7(i8[7]),
    .io_outVec8b_8(i8[8]), .io_outVec8b_9(i8[9]), .io_outVec8b_10(i8[10]), .io_outVec8b_11(i8[11]),
    .io_outVec8b_12(i8[12]), .io_outVec8b_13(i8[13]), .io_outVec8b_14(i8[14]), .io_outVec8b_15(i8[15]),
    .io_outVec16b_0(i16[0]), .io_outVec16b_1(i16[1]), .io_outVec16b_2(i16[2]), .io_outVec16b_3(i16[3]),
    .io_outVec16b_4(i16[4]), .io_outVec16b_5(i16[5]), .io_outVec16b_6(i16[6]), .io_outVec16b_7(i16[7]),
    .io_outVec32b_0(i32[0]), .io_outVec32b_1(i32[1]), .io_outVec32b_2(i32[2]), .io_outVec32b_3(i32[3]),
    .io_outVec64b_0(i64[0]), .io_outVec64b_1(i64[1]));

  logic [127:0] seen0_8 = '0, seen1_8 = '0, seen0_16 = '0, seen1_16 = '0;
  logic [127:0] seen0_32 = '0, seen1_32 = '0, seen0_64 = '0, seen1_64 = '0;

  task automatic check();
    bit bad;
    checks++;
    if (g8 !== i8 || g16 !== i16 || g32 !== i32 || g64 !== i64) begin
      errors++;
      if (errors <= 20) $display("MISMATCH in=%h g8=%h i8=%h g16=%h i16=%h g32=%h i32=%h g64=%h i64=%h",
                                 in, g8, i8, g16, i16, g32, i32, g64, i64);
    end
    bad = 0;
    for (int k = 0; k < 16; k++) if (i8[k]  !== in[8*k  +: 8])  bad = 1;
    for (int k = 0; k < 8;  k++) if (i16[k] !== in[16*k +: 16]) bad = 1;
    for (int k = 0; k < 4;  k++) if (i32[k] !== in[32*k +: 32]) bad = 1;
    for (int k = 0; k < 2;  k++) if (i64[k] !== in[64*k +: 64]) bad = 1;
    if (bad) begin
      oracle_errors++;
      if (oracle_errors <= 20) $display("ORACLE in=%h i8=%h i16=%h i32=%h i64=%h", in, i8, i16, i32, i64);
    end
    seen1_8 |= g8;  seen0_8 |= ~g8;  seen1_16 |= g16; seen0_16 |= ~g16;
    seen1_32 |= g32; seen0_32 |= ~g32; seen1_64 |= g64; seen0_64 |= ~g64;
  endtask

  initial begin
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int cyc = 0; cyc < NCYCLES; cyc++) begin
      case ($urandom_range(0, 9))
        0: in = '0;
        1: in = '1;
        2: in = 128'(1) << $urandom_range(0, 127);
        3: in = {16{8'($urandom)}};
        default: in = {$urandom, $urandom, $urandom, $urandom};
      endcase
      #1 check();
      #9;
    end
    if (seen1_8 != '1 || seen0_8 != '1 || seen1_16 != '1 || seen0_16 != '1 ||
        seen1_32 != '1 || seen0_32 != '1 || seen1_64 != '1 || seen0_64 != '1) begin
      cov_ok = 0; $display("COV FAIL: 有输出位没见过 0 或 1");
    end
    $display("ORACLE oracle_errors=%0d", oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
