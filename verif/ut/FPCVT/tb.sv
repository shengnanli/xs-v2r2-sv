// =============================================================================
// tb —— FPCVT UT：golden FPCVT 与重写件 FPCVT_xs 双例化，同时钟同激励逐拍比 io_result / io_fflags。
//
// ★UT 限度★：CVT64 本仓尚无已入 main 的重写件，两侧共用 golden CVT64 定义（RTL_GOLDEN_DEPS），它例化的
//   FP_INCVT 在两侧也都解析到 golden 那份（重写件被 derive 改名成 FP_INCVT_xs，没人例化它）。所以本 UT 回归的是
//   本层的两张宽度译码表（经 CVT64 的全部可观测行为）；FP_INCVT 重写件的替换由 FM 兜底（impl 容器里 CVT64 例化的
//   FP_INCVT 解析到重写件）。
// 独立 oracle：按 Scala TruthTable（yunsuan/scalar/Convert.scala）在 tb 里另写一张表，逐拍比重写核的 input1H /
//   output1H（层次探针 u_i.u_core），16 种 {opType[4:3], sew} 组合都要出现。
// 复位域：CVT64 内一部分寄存器异步复位、一部分 RegEnable(fire) 不复位；复位撤销后前 WARM 拍连发 fire，
//   把不复位寄存器写成确定值再开始比（+random / <seed>017 档两侧上电值不同）。随机穿插复位。
// 激励：九成取标量 FCVT 实际会发的 opType（f2i / i2f / f2f / fround / fcvtmod，编码同 exeunits CVT64 UT 的池），
//   一成全随机；sew 随机；浮点源取定向特殊值池（0 / ±Inf / qNaN / sNaN / 最小非规格数 / 1.0 / 最大有限数），
//   一半合法 NaN-boxing、一半高位随机；rm 3/4 合法。
// 覆盖（写进 PASS 判据）：16 种 {宽度关系, sew} 各 >= 1000 拍；f2i / i2f / f2f / fround / fcvtmod 各 >= 1000 次 fire；
//   io_result 64 位每位都见过 0 和 1；io_fflags 除 DZ（转换不产生除零，golden 恒 0）外每位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARM = 10;
  localparam int RESET_ODDS = 20000;
  longint errors = 0, checks = 0, oracle_errors = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic        fire, isFcvtmod;
  logic [63:0] src;
  logic [7:0]  opType;
  logic [1:0]  sew, isFround;
  logic [2:0]  rm;
  logic [63:0] g_res, i_res;
  logic [4:0]  g_ff, i_ff;

  FPCVT u_g (.clock(clock), .reset(reset), .io_fire(fire), .io_src(src), .io_opType(opType), .io_sew(sew),
             .io_rm(rm), .io_isFround(isFround), .io_isFcvtmod(isFcvtmod), .io_result(g_res), .io_fflags(g_ff));
  FPCVT_xs u_i (.clock(clock), .reset(reset), .io_fire(fire), .io_src(src), .io_opType(opType), .io_sew(sew),
                .io_rm(rm), .io_isFround(isFround), .io_isFcvtmod(isFcvtmod), .io_result(i_res), .io_fflags(i_ff));

  // ---- 独立 oracle：Scala TruthTable（{宽度关系, sew} -> {源宽度独热, 结果宽度独热}，bit0..3 = 8/16/32/64）----
  function automatic logic [7:0] width_table(input logic [1:0] w, input logic [1:0] s);
    case ({w, s})
      4'b00_01: return {4'b0010, 4'b0010};   // 同宽 16
      4'b00_10: return {4'b0100, 4'b0100};   // 同宽 32
      4'b00_11: return {4'b1000, 4'b1000};   // 同宽 64
      4'b01_00: return {4'b0001, 4'b0010};   // 加宽 8 -> 16
      4'b01_01: return {4'b0010, 4'b0100};   // 加宽 16 -> 32
      4'b01_10: return {4'b0100, 4'b1000};   // 加宽 32 -> 64
      4'b10_00: return {4'b0010, 4'b0001};   // 变窄 16 -> 8
      4'b10_01: return {4'b0100, 4'b0010};   // 变窄 32 -> 16
      4'b10_10: return {4'b1000, 4'b0100};   // 变窄 64 -> 32
      4'b11_01: return {4'b0010, 4'b1000};   // f16 -> f64 / i64 / ui64
      4'b11_11: return {4'b1000, 4'b0010};   // f64 -> f16
      default:  return 8'h00;
    endcase
  endfunction

  function automatic logic [63:0] fp_pick(int w);
    logic [63:0] v;
    int k;
    k = $urandom_range(0, 9);
    v = {$urandom(), $urandom()};
    case (w)
      16: case (k) 0: v[15:0] = 16'h0000; 1: v[15:0] = 16'h7C00; 2: v[15:0] = 16'hFC00; 3: v[15:0] = 16'h7E00;
                   4: v[15:0] = 16'h7D00; 5: v[15:0] = 16'h0001; 6: v[15:0] = 16'h3C00; 7: v[15:0] = 16'h7BFF;
                   default: ; endcase
      32: case (k) 0: v[31:0] = 32'h0; 1: v[31:0] = 32'h7F800000; 2: v[31:0] = 32'hFF800000;
                   3: v[31:0] = 32'h7FC00000; 4: v[31:0] = 32'h7FA00000; 5: v[31:0] = 32'h1;
                   6: v[31:0] = 32'h3F800000; 7: v[31:0] = 32'h7F7FFFFF; default: ; endcase
      default: case (k) 0: v = 64'h0; 1: v = 64'h7FF0000000000000; 2: v = 64'hFFF0000000000000;
                   3: v = 64'h7FF8000000000000; 4: v = 64'h7FF4000000000000; 5: v = 64'h1;
                   6: v = 64'h3FF0000000000000; 7: v = 64'h7FEFFFFFFFFFFFFF; default: ; endcase
    endcase
    return v;
  endfunction

  // 标量 FCVT 会送进来的 opType：f2i / i2f / f2f / fround / fcvtmod
  logic [7:0] cvt_pool [26] = '{8'h80, 8'h81, 8'h86, 8'h87, 8'h88, 8'h89, 8'h8E, 8'h8F, 8'h90, 8'h91,
                                8'h98, 8'h99, 8'h42, 8'h43, 8'h4A, 8'h4B, 8'h52, 8'h53, 8'hC8, 8'hD0,
                                8'hD4, 8'hD8, 8'hC0, 8'hC4, 8'h96, 8'h97};

  task automatic drive();
    int iw;
    logic [7:0] w1h;
    fire      = ($urandom_range(0, 9) < 7) || (cyc < WARM);
    src       = {$urandom, $urandom};
    opType    = $urandom;
    sew       = $urandom;
    rm        = ($urandom_range(0, 3) != 0) ? 3'($urandom_range(0, 4)) : 3'($urandom);
    isFround  = $urandom;
    isFcvtmod = $urandom;
    if ($urandom_range(0, 9) != 0) begin
      opType    = cvt_pool[$urandom_range(0, 25)];
      isFround  = (opType == 8'hC0) ? 2'b01 : (opType == 8'hC4) ? 2'b10 : 2'b00;
      isFcvtmod = (opType == 8'h91) && $urandom_range(0, 1);
      if ($urandom_range(0, 19) == 0) isFround = $urandom;
      w1h = width_table(opType[4:3], sew);
      iw = w1h[5] ? 16 : w1h[6] ? 32 : 64;
      if (opType[7]) begin
        src = fp_pick(iw);
        if ($urandom_range(0, 1)) begin
          if (iw == 16) src[63:16] = '1;
          if (iw == 32) src[63:32] = '1;
        end
      end
    end
  endtask

  logic [63:0] seen0_r = '0, seen1_r = '0;
  logic [4:0]  seen0_f = '0, seen1_f = '0;
  int cov_combo [16];
  longint c_f2i = 0, c_i2f = 0, c_f2f = 0, c_fround = 0, c_fcvtmod = 0;

  initial begin
    bit ok = 1;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1;
    cyc = 0;
    drive();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      reset = (cyc < 5) || ($urandom_range(0, RESET_ODDS - 1) == 0);
      drive();
      #1;
      // 独立 oracle：本层译码表（组合，与本拍输入对应）
      if ({u_i.u_core.input1H, u_i.u_core.output1H} !== width_table(opType[4:3], sew)) begin
        oracle_errors++;
        if (oracle_errors <= 20) $display("[%0d] ORACLE w=%b sew=%b got in=%b out=%b", cyc, opType[4:3], sew,
                                          u_i.u_core.input1H, u_i.u_core.output1H);
      end
      cov_combo[{opType[4:3], sew}]++;
      if (fire) begin
        if (opType[7] && !opType[6]) c_f2i++;
        if (!opType[7]) c_i2f++;
        if (opType[7] && opType[6]) c_f2f++;
        if (|isFround) c_fround++;
        if (isFcvtmod) c_fcvtmod++;
      end
      // 差分：暖机后每拍比（输出由寄存器驱动，与本拍输入无关）
      if (cyc >= WARM + 5) begin
        checks++;
        if (g_res !== i_res || g_ff !== i_ff) begin
          errors++;
          if (errors <= 30) $display("[%0d] MISMATCH result g=%h i=%h fflags g=%b i=%b", cyc, g_res, i_res, g_ff, i_ff);
        end
        seen1_r |= g_res; seen0_r |= ~g_res; seen1_f |= g_ff; seen0_f |= ~g_ff;
      end
    end
    for (int k = 0; k < 16; k++) if (cov_combo[k] < 1000) begin ok = 0; $display("COV FAIL combo %b : %0d", 4'(k), cov_combo[k]); end
    if (c_f2i < 1000 || c_i2f < 1000 || c_f2f < 1000 || c_fround < 1000 || c_fcvtmod < 1000) begin
      ok = 0; $display("COV FAIL f2i=%0d i2f=%0d f2f=%0d fround=%0d fcvtmod=%0d", c_f2i, c_i2f, c_f2f, c_fround, c_fcvtmod);
    end
    if (seen1_r != '1 || seen0_r != '1) begin ok = 0; $display("COV FAIL result bits 1=%h 0=%h", seen1_r, seen0_r); end
    if (seen1_f != 5'b10111 || seen0_f != '1) begin ok = 0; $display("COV FAIL fflags bits 1=%b 0=%b", seen1_f, seen0_f); end
    $display("COVERAGE f2i=%0d i2f=%0d f2f=%0d fround=%0d fcvtmod=%0d", c_f2i, c_i2f, c_f2f, c_fround, c_fcvtmod);
    $display("ORACLE oracle_errors=%0d", oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
