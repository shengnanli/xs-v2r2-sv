// =============================================================================
// tb —— FpAddPathF64W UT：f64 加法器的两个路径件，golden 与重写件（<名>_xs）双例化，同时钟同激励逐拍比。
//   FarPathAdderF64WidenPipeline         —— 54 位打拍加法器：A/B 独立随机（含全 1、进位链边界）
//   ClosePathFloatAdderF64WidenPipeline  —— f64 close path
// 两侧 child 不同：golden 实例读 golden child（ClosePathAdder/_2、CloseShiftLeftWithMux），重写件读重写 child
//   （*_xs），所以同时回归了整棵子树。
//
// 独立 oracle（fp_add_oracle_pkg，纯整数算术）：
//   - 加法器：io_result == (上次 fire 的 A + B) mod 2^54。
//   - close path：在它的前提域内（两操作数指数均非全 1、|Ea - Eb| <= 1、rm ∈ 0..4），
//     fp_c == round_rm( sign_a · (|a| - |b|) )，fflags == {4'b0, NX}；CS1 == {0,sig_b} - {0,sig_a}（54 位）。
//     域外（1/8 完全随机、非法 rm）只做 golden 对比。
// 复位域：全部寄存器 RegEnable(fire)、不复位，且每次 fire 每个寄存器都被写——第一次 fire 之后两侧状态全确定，
//   所以从"出现过一次 fire"起每拍比全部输出（+random 档两侧上电值不同）。
// 激励（fire 3/4）：指数关系 相等 / 差 1 / 0 对 1；指数形状含 0、1、2、53/54/55（下限掩码边界）、
//   全 1 附近；尾数 随机 / 全 1 / 全 0 / 单 1 / 与对方仅差低位（大量抵消、恰好抵消）。
// 覆盖（写进 PASS 判据，按重写件内部信号统计）：sel_cs0..4 各 >= 200；oracle 比对 >= 50000；
//   精确为 0 >= 200；非规格数结果 >= 200；下限位命中 >= 200；NX >= 200；rm 0..4 都出现；
//   每个输出位都见过 0 和 1（close fflags 高 4 位是 golden 字面 0，只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  import fp_add_oracle_pkg::*;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 激励 ----
  logic        fire;
  logic [53:0] add_A, add_B;
  logic [63:0] fp_a, fp_b;
  logic [2:0]  round_mode;

  // ---- 加法器 ----
  logic [53:0] g_add_res, i_add_res;
  FarPathAdderF64WidenPipeline u_g_add (.clock(clock), .io_fire(fire), .io_A(add_A), .io_B(add_B), .io_result(g_add_res));
  FarPathAdderF64WidenPipeline_xs u_i_add (.clock(clock), .io_fire(fire), .io_A(add_A), .io_B(add_B), .io_result(i_add_res));

  // ---- close path ----
  logic [63:0] g_c, i_c;
  logic [4:0]  g_ff, i_ff;
  logic [53:0] g_cs1, i_cs1;
  ClosePathFloatAdderF64WidenPipeline u_g_close (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(g_c), .io_round_mode(round_mode), .io_fflags(g_ff), .io_CS1(g_cs1));
  ClosePathFloatAdderF64WidenPipeline_xs u_i_close (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(i_c), .io_round_mode(round_mode), .io_fflags(i_ff), .io_CS1(i_cs1));

  // ---- golden 对比与逐位翻转覆盖 ----
  localparam int N_OUT = 4;
  logic [63:0] seen0 [N_OUT], seen1 [N_OUT], must [N_OUT];
  initial begin
    for (int k = 0; k < N_OUT; k++) begin seen0[k] = '0; seen1[k] = '0; end
    must[0] = 64'h003F_FFFF_FFFF_FFFF;   // add_res 54 位
    must[1] = '1;                        // close fp_c
    must[2] = 64'h1;                     // close fflags：仅 NX
    must[3] = 64'h003F_FFFF_FFFF_FFFF;   // CS1
  end
  `define CMP(k, g, i, w, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      seen1[k] |= 64'(g); seen0[k] |= ~64'(g) & ((w) == 64 ? '1 : ((64'd1 << (w)) - 1)); end
  task automatic compare_all();
    `CMP(0, g_add_res, i_add_res, 54, "add.io_result")
    `CMP(1, g_c, i_c, 64, "close.io_fp_c")
    `CMP(2, g_ff, i_ff, 5, "close.io_fflags")
    `CMP(3, g_cs1, i_cs1, 54, "close.io_CS1")
  endtask

  // ---- oracle：对照上一次 fire 的输入 ----
  logic [53:0] last_A, last_B;
  logic [63:0] last_a, last_b;
  logic [2:0]  last_rm;
  int cov_zero = 0, cov_subn = 0, cov_nx = 0;
  task automatic oracle_check();
    fp_res_t r;
    logic [10:0] ea, eb;
    logic [53:0] cs1_exp;
    if (g_add_res !== 54'(last_A + last_B)) begin
      errors++; if (errors <= 30) $display("[%0d] ORACLE add golden=%h expect=%h", cyc, g_add_res, 54'(last_A + last_B));
    end
    // CS1 是组合输出，对照当前输入
    cs1_exp = {1'b0, |fp_b[62:52], fp_b[51:0]} - {1'b0, |fp_a[62:52], fp_a[51:0]};
    if (g_cs1 !== cs1_exp) begin
      errors++; if (errors <= 30) $display("[%0d] ORACLE CS1 golden=%h expect=%h", cyc, g_cs1, cs1_exp);
    end
    ea = last_a[62:52]; eb = last_b[62:52];
    if (ea == 11'h7FF || eb == 11'h7FF || last_rm > 3'd4) return;
    if (!((ea == eb) || (ea == eb + 11'd1) || (eb == ea + 11'd1))) return;
    oracle_checks++;
    r = exact_add(53, 11, last_a[63], ea, last_a[51:0], ~last_a[63], eb, last_b[51:0], last_rm);
    if (g_c !== r.bits || g_ff !== {4'b0, r.nx}) begin
      errors++;
      if (errors <= 30) $display("[%0d] ORACLE close a=%h b=%h rm=%0d golden=%h/%b expect=%h/%b", cyc,
                                 last_a, last_b, last_rm, g_c, g_ff, r.bits, {4'b0, r.nx});
    end
    if (r.bits[62:0] == 0) cov_zero++;
    if (r.bits[62:52] == 0 && r.bits[51:0] != 0) cov_subn++;
    if (r.nx) cov_nx++;
  endtask

  // ---- 操作数构造 ----
  function automatic logic [10:0] pick_exp();
    case ($urandom_range(0, 11))
      0: return 11'h000;
      1: return 11'h001;
      2: return 11'h002;
      3: return 11'(52 + $urandom_range(0, 3));
      4: return 11'h7FF;
      5: return 11'h7FE;
      6: return 11'($urandom_range(3, 60));
      default: return 11'($urandom);
    endcase
  endfunction
  function automatic logic [51:0] pick_mant();
    logic [51:0] m = {$urandom, $urandom};
    case ($urandom_range(0, 5))
      0: m = '1;
      1: m = '0;
      2: m = 52'(1) << $urandom_range(0, 51);
      default: ;
    endcase
    return m;
  endfunction

  task automatic drive();
    logic [10:0] ea, eb;
    logic [51:0] ma, mb;
    fire       = ($urandom_range(0, 3) != 0);
    round_mode = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    case ($urandom_range(0, 3))
      0: begin add_A = {$urandom, $urandom}; add_B = {$urandom, $urandom}; end
      1: begin add_A = {22'($urandom), 32'hFFFF_FFFF}; add_B = 54'(1 + $urandom_range(0, 3)); end
      2: begin add_A = '1; add_B = 54'($urandom_range(0, 3)); end
      default: begin add_A = {$urandom, $urandom}; add_B = ~add_A + 54'($urandom_range(0, 2)); end
    endcase
    if ($urandom_range(0, 7) == 0) begin
      fp_a = {$urandom, $urandom}; fp_b = {$urandom, $urandom};
      return;
    end
    ea = pick_exp();
    ma = pick_mant();
    case ($urandom_range(0, 4))
      0, 1: eb = ea;
      2: eb = ea + 11'h1;
      3: eb = ea - 11'h1;
      default: eb = (ea <= 11'h1) ? 11'(ea ^ 11'h1) : ea ^ 11'h1;   // 0 对 1 / 相邻
    endcase
    case ($urandom_range(0, 4))
      0: mb = ma ^ 52'($urandom_range(0, 7));                     // 低位微差：大量抵消
      1: mb = ma;                                                 // 恰好抵消（指数相等时）
      2: mb = ma ^ (52'(1) << $urandom_range(0, 51));
      default: mb = pick_mant();
    endcase
    fp_a = {1'($urandom), ea, ma};
    fp_b = {1'($urandom), eb, mb};
  endtask

  // ---- 覆盖（重写件内部信号）----
  int cov_sel [5];
  int cov_floor = 0, cov_rm [8];
  int fires = 0;
  task automatic sample_cov();
    if (u_i_close.u_core.sel_cs0) cov_sel[0]++;
    if (u_i_close.u_core.sel_cs1) cov_sel[1]++;
    if (u_i_close.u_core.sel_cs2) cov_sel[2]++;
    if (u_i_close.u_core.sel_cs3) cov_sel[3]++;
    if (u_i_close.u_core.sel_cs4) cov_sel[4]++;
    if (|u_i_close.u_core.floor_hit_q) cov_floor++;
    cov_rm[round_mode]++;
  endtask

  initial begin
    bit armed = 0;
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < 5; k++) cov_sel[k] = 0;
    for (int k = 0; k < 8; k++) cov_rm[k] = 0;
    fire = 0; add_A = 0; add_B = 0; fp_a = 0; fp_b = 0; round_mode = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      drive();
      #1;
      if (armed) begin compare_all(); oracle_check(); sample_cov(); end
      @(posedge clock);
      if (fire) begin
        armed = 1; fires++;
        last_A = add_A; last_B = add_B; last_a = fp_a; last_b = fp_b; last_rm = round_mode;
      end
      #1;
    end
    for (int k = 0; k < 5; k++) if (cov_sel[k] < 200) begin cov_ok = 0; $display("COV FAIL sel_cs%0d=%0d", k, cov_sel[k]); end
    if (oracle_checks < 50000) begin cov_ok = 0; $display("COV FAIL oracle_checks=%0d", oracle_checks); end
    if (cov_zero < 200) begin cov_ok = 0; $display("COV FAIL exact zero=%0d", cov_zero); end
    if (cov_subn < 200) begin cov_ok = 0; $display("COV FAIL subnormal=%0d", cov_subn); end
    if (cov_floor < 200) begin cov_ok = 0; $display("COV FAIL floor hit=%0d", cov_floor); end
    if (cov_nx < 200) begin cov_ok = 0; $display("COV FAIL nx=%0d", cov_nx); end
    for (int k = 0; k < 5; k++) if (cov_rm[k] == 0) begin cov_ok = 0; $display("COV FAIL rm%0d", k); end
    for (int k = 0; k < N_OUT; k++) begin
      if ((seen1[k] & must[k]) != must[k]) begin cov_ok = 0; $display("COV FAIL out%0d bits never 1: %h", k, must[k] & ~seen1[k]); end
    end
    $display("COVERAGE sel=%0d/%0d/%0d/%0d/%0d oracle=%0d zero=%0d subnormal=%0d floor_hit=%0d nx=%0d fires=%0d",
             cov_sel[0], cov_sel[1], cov_sel[2], cov_sel[3], cov_sel[4], oracle_checks, cov_zero, cov_subn,
             cov_floor, cov_nx, fires);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
