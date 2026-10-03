// =============================================================================
// tb —— FpAddPathF32W16 UT：三个目标各自 golden 与重写件（<名>_xs）双例化，同时钟同激励逐拍比。
//   FarPathF32WidenF16MixedAdderPipeline  —— 输入 A/B 独立随机（含全 1、进位链边界）
//   FarPathF32WidenF16MixedPipeline       —— 与 close path 共用 fp_a / fp_b / round_mode / res_is_f32
//   ClosePathF32WidenF16MixedPipeline
// 两侧的 child 不同：golden 实例读 golden child，重写件读重写 child（*_xs），所以这里同时回归了整棵子树。
//
// 复位域：全部寄存器 RegEnable(fire)、不复位，且每个寄存器在每次 fire 都被写——第一次 fire 之后两侧
//   状态全确定，所以 tb 从"出现过一次 fire"的下一拍起每拍比全部输出（+random 档两侧上电值不同）。
// 激励（fire 3/4）：res_is_f32 1/2；f32 操作数按布局造，f16 操作数按父级的铺法造（{s, 3'b0, e5, m10, 13'b0}），
//   另 1/8 全 32 位随机（不在任何前提下，两侧也必须一致）。指数关系轮换：相等 / 差 1 / 差 2..30 / 任意；
//   指数形状含 0（非规格数）、1、全 1 附近（上溢）；尾数含随机 / 全 1 / 与对方仅差低位（大量抵消）。
// 覆盖（写进 PASS 判据，按重写件内部信号统计）：close 五个候选选择 sel_cs0..4 各 >= 200；far 的
//   正常/溢出 × 不进位/进位四格各 >= 200、上溢 >= 50、移位溢出 >= 200；三档舍入相关 rm 0..4 都出现；
//   每个输出位都见过 0 和 1（far fflags 的 NV/DZ/UF 与 close fflags 的高 4 位是 golden 字面 0，只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 激励 ----
  logic        fire;
  logic [24:0] add_A, add_B;
  logic [31:0] fp_a, fp_b;
  logic        is_sub;
  logic [2:0]  round_mode;
  logic        res_is_f32;

  // ---- AdderPipeline ----
  logic [24:0] g_add_res, i_add_res;
  FarPathF32WidenF16MixedAdderPipeline u_g_add (.clock(clock), .io_fire(fire), .io_A(add_A), .io_B(add_B), .io_result(g_add_res));
  FarPathF32WidenF16MixedAdderPipeline_xs u_i_add (.clock(clock), .io_fire(fire), .io_A(add_A), .io_B(add_B), .io_result(i_add_res));

  // ---- FarPath ----
  logic [31:0] g_far_c, i_far_c;
  logic [4:0]  g_far_ff, i_far_ff;
  logic [7:0]  g_far_abs, i_far_abs;
  logic        g_far_bg, i_far_bg;
  FarPathF32WidenF16MixedPipeline u_g_far (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(g_far_c), .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(g_far_ff),
    .io_absEaSubEb(g_far_abs), .io_res_is_f32(res_is_f32), .io_isEfp_bGreater(g_far_bg));
  FarPathF32WidenF16MixedPipeline_xs u_i_far (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(i_far_c), .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(i_far_ff),
    .io_absEaSubEb(i_far_abs), .io_res_is_f32(res_is_f32), .io_isEfp_bGreater(i_far_bg));

  // ---- ClosePath ----
  logic [31:0] g_close_c, i_close_c;
  logic [4:0]  g_close_ff, i_close_ff;
  logic [24:0] g_close_cs1, i_close_cs1;
  ClosePathF32WidenF16MixedPipeline u_g_close (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(g_close_c), .io_round_mode(round_mode), .io_fflags(g_close_ff), .io_res_is_f32(res_is_f32),
    .io_CS1(g_close_cs1));
  ClosePathF32WidenF16MixedPipeline_xs u_i_close (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(i_close_c), .io_round_mode(round_mode), .io_fflags(i_close_ff), .io_res_is_f32(res_is_f32),
    .io_CS1(i_close_cs1));

  // ---- 比较与逐位翻转覆盖 ----
  localparam int N_OUT = 9;
  logic [31:0] seen0 [N_OUT], seen1 [N_OUT];
  logic [31:0] must  [N_OUT];      // 要求见过 1 的位（golden 字面 0 的位不要求）
  initial begin
    for (int k = 0; k < N_OUT; k++) begin seen0[k] = '0; seen1[k] = '0; end
    must[0] = 32'h01FF_FFFF;       // add_res 25 位
    must[1] = 32'hFFFF_FFFF;       // far fp_c
    must[2] = 32'h0000_0005;       // far fflags：仅 OF(bit2) / NX(bit0)
    must[3] = 32'h0000_00FF;       // far absEaSubEb
    must[4] = 32'h0000_0001;       // far isEfp_bGreater
    must[5] = 32'hFFFF_FFFF;       // close fp_c
    must[6] = 32'h0000_0001;       // close fflags：仅 NX
    must[7] = 32'h01FF_FFFF;       // close CS1
    must[8] = 32'h0;               // 占位
  end
  `define CMP(k, g, i, w, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      seen1[k] |= 32'(g); seen0[k] |= ~32'(g) & ((64'd1 << (w)) - 1); end
  task automatic compare_all();
    `CMP(0, g_add_res, i_add_res, 25, "add.io_result")
    `CMP(1, g_far_c, i_far_c, 32, "far.io_fp_c")
    `CMP(2, g_far_ff, i_far_ff, 5, "far.io_fflags")
    `CMP(3, g_far_abs, i_far_abs, 8, "far.io_absEaSubEb")
    `CMP(4, g_far_bg, i_far_bg, 1, "far.io_isEfp_bGreater")
    `CMP(5, g_close_c, i_close_c, 32, "close.io_fp_c")
    `CMP(6, g_close_ff, i_close_ff, 5, "close.io_fflags")
    `CMP(7, g_close_cs1, i_close_cs1, 25, "close.io_CS1")
  endtask

  // ---- 操作数构造 ----
  function automatic logic [7:0] pick_exp(input bit f32);
    int r = $urandom_range(0, 9);
    logic [7:0] emax = f32 ? 8'hFF : 8'h1F;
    case (r)
      0: return 8'h00;
      1: return 8'h01;
      2: return emax;
      3: return emax - 8'h1;
      4: return emax - 8'(1 + $urandom_range(0, 1));
      5: return 8'($urandom_range(2, 26));
      default: return f32 ? 8'($urandom) : 8'($urandom_range(0, 31));
    endcase
  endfunction
  function automatic logic [22:0] pick_mant(input bit f32);
    logic [22:0] m = 23'($urandom);
    case ($urandom_range(0, 5))
      0: m = '1;
      1: m = '0;
      2: m = 23'(1) << $urandom_range(0, 22);
      default: ;
    endcase
    return f32 ? m : {m[22:13], 13'h0};
  endfunction
  function automatic logic [31:0] pack(input bit f32, input logic s, input logic [7:0] e, input logic [22:0] m);
    return f32 ? {s, e, m} : {s, 3'b000, e[4:0], m[22:13], 13'h0};
  endfunction

  task automatic drive();
    logic [7:0]  ea, eb;
    logic [22:0] ma, mb;
    bit f32;
    fire       = ($urandom_range(0, 3) != 0);
    round_mode = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    is_sub     = $urandom;
    res_is_f32 = $urandom;
    f32 = res_is_f32;
    // AdderPipeline：一半随机，一半打进位链边界
    case ($urandom_range(0, 3))
      0: begin add_A = 25'($urandom); add_B = 25'($urandom); end
      1: begin add_A = {7'($urandom), 18'h3FFFF}; add_B = {7'($urandom), 18'(1 + $urandom_range(0, 3))}; end
      2: begin add_A = 25'h1FFFFFF; add_B = 25'($urandom_range(0, 3)); end
      default: begin add_A = 25'($urandom); add_B = ~add_A + 25'($urandom_range(0, 2)); end
    endcase
    // 浮点：1/8 完全随机
    if ($urandom_range(0, 7) == 0) begin
      fp_a = $urandom; fp_b = $urandom;
      return;
    end
    ea = pick_exp(f32);
    ma = pick_mant(f32);
    case ($urandom_range(0, 4))
      0: eb = ea;                                                      // 相等
      1: eb = ($urandom & 1) ? ea + 8'h1 : ea - 8'h1;                  // 差 1
      2: eb = ($urandom & 1) ? ea + 8'($urandom_range(2, 30)) : ea - 8'($urandom_range(2, 30));
      3: eb = ea ^ 8'h1;
      default: eb = pick_exp(f32);
    endcase
    if (!f32) eb = {3'b000, eb[4:0]};
    case ($urandom_range(0, 3))
      0: mb = ma ^ (f32 ? 23'($urandom_range(0, 7)) : {10'($urandom_range(0, 7)), 13'h0});  // 低位微差：大量抵消
      1: mb = ma;
      default: mb = pick_mant(f32);
    endcase
    fp_a = pack(f32, $urandom, ea, ma);
    fp_b = pack(f32, $urandom, eb, mb);
  endtask

  // ---- 覆盖（重写件内部信号；第 1 拍的量在 fire 之后一拍才有意义，直接按拍累计即可）----
  int cov_sel [5];
  int cov_far [4];
  int cov_of, cov_shift_out, cov_rm [8];
  int fires = 0;
  task automatic sample_cov();
    if (u_i_close.u_core.sel_cs0) cov_sel[0]++;
    if (u_i_close.u_core.sel_cs1) cov_sel[1]++;
    if (u_i_close.u_core.sel_cs2) cov_sel[2]++;
    if (u_i_close.u_core.sel_cs3) cov_sel[3]++;
    if (u_i_close.u_core.sel_cs4) cov_sel[4]++;
    if (u_i_far.u_core.sel_normal_keep)   cov_far[0]++;
    if (u_i_far.u_core.sel_normal_up)     cov_far[1]++;
    if (u_i_far.u_core.sel_overflow_keep) cov_far[2]++;
    if (u_i_far.u_core.sel_overflow_up)   cov_far[3]++;
    if (u_i_far.u_core.overflow) cov_of++;
    if (u_i_far.u_core.shift_out_of_range) cov_shift_out++;
    cov_rm[round_mode]++;
  endtask

  initial begin
    bit armed = 0;
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    fire = 0; add_A = 0; add_B = 0; fp_a = 0; fp_b = 0; is_sub = 0; round_mode = 0; res_is_f32 = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      drive();
      #1;
      if (armed) begin compare_all(); sample_cov(); end
      @(posedge clock);
      if (fire) begin armed = 1; fires++; end
      #1;
    end
    for (int k = 0; k < 5; k++) if (cov_sel[k] < 200) begin cov_ok = 0; $display("COV FAIL close sel_cs%0d=%0d", k, cov_sel[k]); end
    for (int k = 0; k < 4; k++) if (cov_far[k] < 200) begin cov_ok = 0; $display("COV FAIL far case%0d=%0d", k, cov_far[k]); end
    if (cov_of < 50) begin cov_ok = 0; $display("COV FAIL far overflow=%0d", cov_of); end
    if (cov_shift_out < 200) begin cov_ok = 0; $display("COV FAIL far shift_out=%0d", cov_shift_out); end
    for (int k = 0; k < 5; k++) if (cov_rm[k] == 0) begin cov_ok = 0; $display("COV FAIL rm%0d", k); end
    for (int k = 0; k < 8; k++) begin
      if ((seen1[k] & must[k]) != must[k]) begin cov_ok = 0; $display("COV FAIL out%0d bits never 1: %h", k, must[k] & ~seen1[k]); end
    end
    $display("COVERAGE close sel=%0d/%0d/%0d/%0d/%0d far keepN/upN/keepO/upO=%0d/%0d/%0d/%0d of=%0d shift_out=%0d fires=%0d",
             cov_sel[0], cov_sel[1], cov_sel[2], cov_sel[3], cov_sel[4], cov_far[0], cov_far[1], cov_far[2], cov_far[3],
             cov_of, cov_shift_out, fires);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
