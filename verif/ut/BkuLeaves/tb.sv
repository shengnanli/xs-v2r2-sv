// =============================================================================
// tb —— BkuLeaves UT：Bku 的四个运算叶子 CountModule / ClmulModule / MiscModule / HashModule，
//   各自 golden 与重写件（<名>_xs）双例化，同时钟同激励逐拍比全部输出；
//   另配一个 tb 内的**独立 oracle**（按 RISC-V 规范逐条指令直接算，不看两侧 RTL 的结构），
//   golden 与重写件的输出都要等于 oracle（oracle 同时也被 golden 校验）。
//
// 时序：四个模块都是"io_regEnable 时拍下输入，之后输出组合地由寄存器决定"。tb 在每次
//   regEnable 时把输入快照存进 oracle 的 last_*，从第一次 regEnable 的下一拍起每拍比。
//   第一次 regEnable 之前寄存器未写（+random 档两侧上电值不同），不比。
//   所有寄存器在每次 regEnable 都被写，所以第一次之后两侧状态全确定。
//
// 激励：regEnable 3/4；func 3/4 取本块合法编码、1/4 全 9 位随机（越界编码两侧也必须一致）；
//   src 形状轮换：全随机 / 全 0 / 全 1 / 随机右移（造各种前导零）/ 随机左移（造尾随零）/
//   单个 1 / 稀疏 / 稠密；xperm 的下标字节一半落在 0..7、一半越界。
// 覆盖（写进 PASS 判据）：clz/ctz 的 64 位结果 0..64 全部出现、clzw/ctzw 0..32 全部出现、
//   cpop 结果 >= 60 种；clmul 三段 + 越界 func 各 >= 1000；xperm.b 越界字节 >= 1000；
//   hash 十种函数各 >= 1000；每个输出位都见过 0 和 1（Count 的高 57 位是结构常 0，只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 激励 ----
  logic        en;
  logic [63:0] src0, src1;
  logic [8:0]  func_cnt, func_clm, func_misc, func_hash;

  // ---- DUT 对 ----
  logic [63:0] g_cnt, i_cnt, g_clm, i_clm, g_misc, i_misc, g_hash, i_hash;
  CountModule    u_g_cnt  (.clock(clock), .io_src(src0), .io_func(func_cnt), .io_regEnable(en), .io_out(g_cnt));
  CountModule_xs u_i_cnt  (.clock(clock), .io_src(src0), .io_func(func_cnt), .io_regEnable(en), .io_out(i_cnt));
  ClmulModule    u_g_clm  (.clock(clock), .io_src_0(src0), .io_src_1(src1), .io_func(func_clm), .io_regEnable(en), .io_out(g_clm));
  ClmulModule_xs u_i_clm  (.clock(clock), .io_src_0(src0), .io_src_1(src1), .io_func(func_clm), .io_regEnable(en), .io_out(i_clm));
  MiscModule     u_g_misc (.clock(clock), .io_src_0(src0), .io_src_1(src1), .io_func(func_misc), .io_regEnable(en), .io_out(g_misc));
  MiscModule_xs  u_i_misc (.clock(clock), .io_src_0(src0), .io_src_1(src1), .io_func(func_misc), .io_regEnable(en), .io_out(i_misc));
  HashModule     u_g_hash (.clock(clock), .io_src(src0), .io_func(func_hash), .io_regEnable(en), .io_out(g_hash));
  HashModule_xs  u_i_hash (.clock(clock), .io_src(src0), .io_func(func_hash), .io_regEnable(en), .io_out(i_hash));

  // ===========================================================================
  // 独立 oracle（按指令语义直接算）
  // ===========================================================================
  function automatic int clz_n(input logic [63:0] x, input int n);   // 低 n 位里的前导零
    for (int b = n - 1; b >= 0; b--) if (x[b]) return n - 1 - b;
    return n;
  endfunction
  function automatic int ctz_n(input logic [63:0] x, input int n);
    for (int b = 0; b < n; b++) if (x[b]) return b;
    return n;
  endfunction
  function automatic int popc_n(input logic [63:0] x, input int n);
    int c = 0;
    for (int b = 0; b < n; b++) c += x[b];
    return c;
  endfunction
  // Count：func 只解码 bit2(cpop) / bit1(ctz) / bit0(W)，其余位不看（与 BKUOpType 对齐）
  function automatic logic [63:0] ref_count(input logic [63:0] x, input logic [8:0] f);
    int n = f[0] ? 32 : 64;
    if (f[2]) return 64'(popc_n(x, n));
    if (f[1]) return 64'(ctz_n(x, n));
    return 64'(clz_n(x, n));
  endfunction
  function automatic logic [127:0] clmul_full(input logic [63:0] a, input logic [63:0] b);
    logic [127:0] p = '0;
    for (int i = 0; i < 64; i++) if (a[i]) p ^= ({64'h0, b} << i);
    return p;
  endfunction
  function automatic logic [63:0] ref_clmul(input logic [63:0] a, input logic [63:0] b, input logic [8:0] f);
    logic [127:0] p = clmul_full(a, b);
    if (f == 9'd1) return p[127:64];      // clmulh
    if (f == 9'd2) return p[126:63];      // clmulr
    return p[63:0];                       // clmul（及任何其它编码）
  endfunction
  function automatic logic [63:0] ref_xperm(input logic [63:0] tbl, input logic [63:0] idx, input bit is_b);
    logic [63:0] r = '0;
    int w = is_b ? 8 : 4;
    for (int i = 0; i < 64 / w; i++) begin
      longint k = (idx >> (i * w)) & ((64'd1 << w) - 1);
      if (k < 64 / w) r |= ((tbl >> (k * w)) & ((64'd1 << w) - 1)) << (i * w);
    end
    return r;
  endfunction
  function automatic logic [31:0] rol32(input logic [31:0] x, input int n);
    return (x << n) | (x >> (32 - n));
  endfunction
  function automatic logic [31:0] r32(input logic [31:0] x, input int n);
    return (x >> n) | (x << (32 - n));
  endfunction
  function automatic logic [63:0] r64(input logic [63:0] x, input int n);
    return (x >> n) | (x << (64 - n));
  endfunction
  function automatic logic [63:0] sx(input logic [31:0] x);
    return {{32{x[31]}}, x};
  endfunction
  function automatic logic [63:0] ref_hash(input logic [63:0] x, input logic [8:0] f);
    logic [31:0] w = x[31:0];
    if (f[3]) return f[0] ? sx(w ^ rol32(w, 15) ^ rol32(w, 23))     // SM3 P1（规范写法）
                          : sx(w ^ rol32(w, 9)  ^ rol32(w, 17));    // SM3 P0
    case (f[2:0])
      3'd0: return sx(r32(w, 2) ^ r32(w, 13) ^ r32(w, 22));
      3'd1: return sx(r32(w, 6) ^ r32(w, 11) ^ r32(w, 25));
      3'd2: return sx(r32(w, 7) ^ r32(w, 18) ^ (w >> 3));
      3'd3: return sx(r32(w, 17) ^ r32(w, 19) ^ (w >> 10));
      3'd4: return r64(x, 28) ^ r64(x, 34) ^ r64(x, 39);
      3'd5: return r64(x, 14) ^ r64(x, 18) ^ r64(x, 41);
      3'd6: return r64(x, 1) ^ r64(x, 8) ^ (x >> 7);
      default: return r64(x, 19) ^ r64(x, 61) ^ (x >> 6);
    endcase
  endfunction

  // ===========================================================================
  // 比较 + 覆盖
  // ===========================================================================
  logic [63:0] seen0 [4], seen1 [4];
  logic [63:0] last_src0, last_src1;
  logic [8:0]  last_fcnt, last_fclm, last_fmisc, last_fhash;
  bit          armed = 0;
  bit          seen_clz [65], seen_ctz [65], seen_clzw [33], seen_ctzw [33], seen_cpop [65];
  int          n_clm [4];          // clmul / clmulh / clmulr / 其它编码
  int          n_xpb_oob = 0;      // xperm.b 越界字节
  int          n_hash [10];

  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      seen1[k] |= (g); seen0[k] |= ~(g); end
  `define ORC(g, r, nm) \
    begin oracle_checks++; if ((g) !== (r)) begin errors++; \
      if (errors <= 30) $display("[%0d] ORACLE %s golden=%h oracle=%h", cyc, nm, (g), (r)); end end

  task automatic compare_all();
    logic [63:0] r;
    `CMP(0, g_cnt, i_cnt, "Count.io_out")
    `CMP(1, g_clm, i_clm, "Clmul.io_out")
    `CMP(2, g_misc, i_misc, "Misc.io_out")
    `CMP(3, g_hash, i_hash, "Hash.io_out")
    r = ref_count(last_src0, last_fcnt);  `ORC(g_cnt, r, "Count")
    r = ref_clmul(last_src0, last_src1, last_fclm); `ORC(g_clm, r, "Clmul")
    r = ref_xperm(last_src0, last_src1, last_fmisc[0]); `ORC(g_misc, r, "Misc")
    r = ref_hash(last_src0, last_fhash); `ORC(g_hash, r, "Hash")
  endtask

  // 每次 regEnable 记一次覆盖（以被拍下的那一组输入为准）
  task automatic note_coverage();
    int v;
    v = int'(ref_count(src0, func_cnt));
    if (func_cnt[2])      seen_cpop[func_cnt[0] ? 0 : v] = 1;   // 只统计 64 位 cpop 的值种类
    else if (func_cnt[1]) begin if (func_cnt[0]) seen_ctzw[v] = 1; else seen_ctz[v] = 1; end
    else                  begin if (func_cnt[0]) seen_clzw[v] = 1; else seen_clz[v] = 1; end
    n_clm[(func_clm <= 9'd2) ? int'(func_clm) : 3]++;
    if (func_misc[0]) for (int i = 0; i < 8; i++) if (|src1[8*i+3 +: 5]) n_xpb_oob++;
    n_hash[func_hash[3] ? 8 + func_hash[0] : func_hash[2:0]]++;
  endtask

  // ===========================================================================
  // 激励
  // ===========================================================================
  function automatic logic [63:0] pick_src();
    logic [63:0] x = {$urandom, $urandom};
    case ($urandom_range(0, 9))
      0: return '0;
      1: return '1;
      2: return x >> $urandom_range(0, 64);                       // 前导零
      3: return x << $urandom_range(0, 64);                       // 尾随零
      4: return 64'd1 << $urandom_range(0, 63);                   // 单个 1
      5: return x & {$urandom, $urandom} & {$urandom, $urandom};  // 稀疏
      6: return x | {$urandom, $urandom} | {$urandom, $urandom};  // 稠密
      7: return {32'($urandom_range(0, 1) ? 32'h0 : $urandom), 32'($urandom) >> $urandom_range(0, 32)};
      default: return x;
    endcase
  endfunction
  function automatic logic [63:0] pick_index();
    logic [63:0] x = {$urandom, $urandom};
    if ($urandom_range(0, 1)) return x & 64'h0707_0707_0707_0707;   // xperm.b 全在界内
    return x;
  endfunction
  function automatic logic [8:0] pick_func(input logic [8:0] legal [], input int n);
    if ($urandom_range(0, 3) == 0) return 9'($urandom);
    return legal[$urandom_range(0, n - 1)];
  endfunction

  logic [8:0] F_CNT  [] = '{9'b001000, 9'b001001, 9'b001010, 9'b001011, 9'b001100, 9'b001101};
  logic [8:0] F_CLM  [] = '{9'b000000, 9'b000001, 9'b000010};
  logic [8:0] F_MISC [] = '{9'b000100, 9'b000101};
  logic [8:0] F_HASH [] = '{9'b110000, 9'b110001, 9'b110010, 9'b110011, 9'b110100,
                            9'b110101, 9'b110110, 9'b110111, 9'b111000, 9'b111001};

  task automatic drive();
    en        = ($urandom_range(0, 3) != 0);
    src0      = pick_src();
    src1      = ($urandom_range(0, 2) == 0) ? pick_index() : pick_src();
    func_cnt  = pick_func(F_CNT, 6);
    func_clm  = pick_func(F_CLM, 3);
    func_misc = pick_func(F_MISC, 2);
    func_hash = pick_func(F_HASH, 10);
  endtask

  // 每拍：negedge 换输入；posedge 后 #1 —— 若这一拍 en=1 则寄存器刚拍下这组输入，
  // 更新 oracle 快照；从第一次 en 起每拍比较（输出只由寄存器决定）。
  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < 4; k++) begin seen0[k] = '0; seen1[k] = '0; end
    foreach (n_clm[k]) n_clm[k] = 0;
    foreach (n_hash[k]) n_hash[k] = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive();
      @(posedge clock);
      #1;
      if (en) begin
        last_src0 = src0; last_src1 = src1;
        last_fcnt = func_cnt; last_fclm = func_clm; last_fmisc = func_misc; last_fhash = func_hash;
        note_coverage();
        armed = 1;
      end
      if (armed) compare_all();
    end
    report();
    $finish;
  end

  // ===========================================================================
  // 收尾：覆盖门槛 + 判定
  // ===========================================================================
  task automatic report();
    int cov_fail = 0, n;
    n = 0; foreach (seen_clz[v])  n += seen_clz[v];  $display("COV clz values   = %0d / 65", n); if (n != 65) cov_fail++;
    n = 0; foreach (seen_ctz[v])  n += seen_ctz[v];  $display("COV ctz values   = %0d / 65", n); if (n != 65) cov_fail++;
    n = 0; foreach (seen_clzw[v]) n += seen_clzw[v]; $display("COV clzw values  = %0d / 33", n); if (n != 33) cov_fail++;
    n = 0; foreach (seen_ctzw[v]) n += seen_ctzw[v]; $display("COV ctzw values  = %0d / 33", n); if (n != 33) cov_fail++;
    n = 0; foreach (seen_cpop[v]) n += seen_cpop[v]; $display("COV cpop values  = %0d (>=60)", n); if (n < 60) cov_fail++;
    $display("COV clmul/clmulh/clmulr/other = %0d/%0d/%0d/%0d", n_clm[0], n_clm[1], n_clm[2], n_clm[3]);
    foreach (n_clm[k]) if (n_clm[k] < 1000) cov_fail++;
    $display("COV xperm.b out-of-range bytes = %0d", n_xpb_oob); if (n_xpb_oob < 1000) cov_fail++;
    $write("COV hash funcs ="); foreach (n_hash[k]) $write(" %0d", n_hash[k]); $display("");
    foreach (n_hash[k]) if (n_hash[k] < 1000) cov_fail++;
    // 每个输出位都见过 0/1；Count 高 57 位结构常 0 只要求见过 0
    for (int k = 0; k < 4; k++) begin
      logic [63:0] need1 = (k == 0) ? 64'h7F : '1;
      if (seen0[k] !== '1 || (seen1[k] & need1) !== need1) begin
        cov_fail++; $display("COV toggle out%0d seen0=%h seen1=%h", k, seen0[k], seen1[k]);
      end
    end
    $display("checks=%0d oracle_checks=%0d errors=%0d cov_fail=%0d", checks, oracle_checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
