// =============================================================================
// tb —— Reduction UT：golden Reduction 与重写件 Reduction_xs 双例化，同激励逐拍比 io_out_vd；
//       另带一个独立 oracle（tb 内按 RVV 语义用整数算术算期望值，不看 RTL 结构）。
//
// 激励（每拍一组，valid 80%）：
//   opcode 90% 取 vredsum..vredxor（33..38），10% 任意 6 位；源 sew 0..3；srcType[3:2] 45% 00 / 45% 01 /
//   10% 任意；vdType 85% = 源 sew（加法时 40% 取 sew+1 走加宽），其余任意；vlmul 85% 0..3；uopIdx 50% 取 0..3、25% 取 0..15；
//   vl 偏向 0 / 窗口边界；mask 随机 / 全 1 / 全 0；数据按 64 位块取随机 / 0 / 全 1 / 0x80.. / 0x7F.. / 小值。
// 比较：
//   (1) 差分：复位释放后每拍比 golden 与重写件的 io_out_vd（任意激励，含非法组合）。
//   (2) oracle：只对"合法"指令（srcType[3]=0；非加宽时 vd sew = 源 sew；加宽只配 vredsum、源 sew<3）
//       算期望：mask/尾部元素换单位元 → alu uop 做逐元素 合并 / 归约 uop 做 vs1[0] ⊕ 全部元素 → 按 ta/vl 补尾。
//       期望值与 RTL 同样走两级流水（valid 后第 2 个时钟沿生效）。
// 覆盖（写进 PASS 判据）：归约输出 8 种运算 × 4 种 vd sew 各 >= 200；alu uop 8 种运算各 >= 200；
//   加宽 alu（sew 0/1/2）各 >= 200；vl==0、ta=0/1、mask 关元素、vl 截断元素各 >= 500；oracle 检查 >= 50000。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_checks = 0, oracle_errors = 0;
  int cyc;
  logic clock = 0;
  logic reset = 1;
  always #5 clock = ~clock;

  typedef struct packed {
    logic         valid;
    logic [5:0]   op;
    logic         vm;
    logic         ta;
    logic [2:0]   vlmul;
    logic [7:0]   vl;
    logic [5:0]   uop;
    logic [3:0]   st;
    logic [3:0]   vdt;
    logic [127:0] vs1;
    logic [127:0] vs2;
    logic [127:0] old;
    logic [127:0] mask;
  } stim_t;

  stim_t s;
  wire [127:0] out_g, out_x;

  Reduction g (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_valid            (s.valid),
    .io_in_bits_opcode_op   (s.op),
    .io_in_bits_info_vm     (s.vm),
    .io_in_bits_info_ta     (s.ta),
    .io_in_bits_info_vlmul  (s.vlmul),
    .io_in_bits_info_vl     (s.vl),
    .io_in_bits_info_uopIdx (s.uop),
    .io_in_bits_srcType_0   (s.st),
    .io_in_bits_vdType      (s.vdt),
    .io_in_bits_vs1         (s.vs1),
    .io_in_bits_vs2         (s.vs2),
    .io_in_bits_old_vd      (s.old),
    .io_in_bits_mask        (s.mask),
    .io_out_vd              (out_g)
  );
  Reduction_xs x (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_valid            (s.valid),
    .io_in_bits_opcode_op   (s.op),
    .io_in_bits_info_vm     (s.vm),
    .io_in_bits_info_ta     (s.ta),
    .io_in_bits_info_vlmul  (s.vlmul),
    .io_in_bits_info_vl     (s.vl),
    .io_in_bits_info_uopIdx (s.uop),
    .io_in_bits_srcType_0   (s.st),
    .io_in_bits_vdType      (s.vdt),
    .io_in_bits_vs1         (s.vs1),
    .io_in_bits_vs2         (s.vs2),
    .io_in_bits_old_vd      (s.old),
    .io_in_bits_mask        (s.mask),
    .io_out_vd              (out_x)
  );

  // ---------------------------------------------------------------------------
  // oracle
  // ---------------------------------------------------------------------------
  localparam int K_SUM = 0, K_MAX = 1, K_MAXU = 2, K_MIN = 3, K_MINU = 4, K_AND = 5, K_OR = 6, K_XOR = 7;
  localparam int P_RED = 0, P_ALU = 1, P_WALU = 2;

  // 覆盖计数
  longint cov_red [8][4];
  longint cov_alu [8];
  longint cov_walu [3];
  longint cov_vl0, cov_ta [2], cov_masked, cov_vlcut;

  function automatic longint unsigned wmask(int w);
    return (w == 64) ? 64'hFFFF_FFFF_FFFF_FFFF : ((64'd1 << w) - 1);
  endfunction

  function automatic longint unsigned get_elem(logic [255:0] v, int w, int e);
    return (v >> (w * e)) & wmask(w);
  endfunction

  function automatic logic [255:0] put_elem(logic [255:0] v, int w, int e, longint unsigned x);
    logic [255:0] m;
    m = 256'(wmask(w)) << (w * e);
    return (v & ~m) | ((256'(x & wmask(w))) << (w * e));
  endfunction

  function automatic longint signed sext(longint unsigned x, int w);
    return (w == 64) ? $signed(x) : $signed(x << (64 - w)) >>> (64 - w);
  endfunction

  // a < b（按 w 位有/无符号）
  function automatic bit lt(longint unsigned a, longint unsigned b, int w, bit sgn);
    if (sgn) return sext(a, w) < sext(b, w);
    else     return a < b;
  endfunction

  function automatic longint unsigned combine(int kind, longint unsigned a, longint unsigned b, int w);
    case (kind)
      K_SUM:          return (a + b) & wmask(w);
      K_MAX:          return lt(a, b, w, 1) ? b : a;
      K_MAXU:         return lt(a, b, w, 0) ? b : a;
      K_MIN:          return lt(a, b, w, 1) ? a : b;
      K_MINU:         return lt(a, b, w, 0) ? a : b;
      K_AND:          return a & b;
      K_OR:           return a | b;
      default:        return a ^ b;
    endcase
  endfunction

  function automatic longint unsigned identity(int kind, int w);
    case (kind)
      K_MAX:          return 64'd1 << (w - 1);                 // 最小负数
      K_MIN:          return wmask(w) >> 1;                     // 最大正数
      K_MINU, K_AND:  return wmask(w);
      default:        return 0;
    endcase
  endfunction

  // 返回期望 vd；legal=0 表示此组合不在 oracle 的语义范围内（只做差分）
  function automatic logic [127:0] oracle(stim_t t, output bit legal, input bit count);
    int sew, dsew, ew, dw, kind, n_uop_elem, shift, vlrem, path;
    bit sgn, widen, red, alu, walu, widen_red, any_masked, any_cut;
    logic [255:0] d;
    logic [127:0] res;
    longint unsigned r;
    sew  = t.st[1:0];
    dsew = t.vdt[1:0];
    ew   = 8 << sew;
    dw   = 8 << dsew;
    sgn  = t.st[3:2] == 2'b01;
    widen = dsew == ((sew + 1) % 4);
    case (t.op)
      6'd34:   kind = sgn ? K_MAX : K_MAXU;
      6'd35:   kind = sgn ? K_MIN : K_MINU;
      6'd36:   kind = K_AND;
      6'd37:   kind = K_OR;
      6'd38:   kind = K_XOR;
      default: kind = K_SUM;
    endcase
    legal = (t.st[3] == 1'b0) && (widen ? (kind == K_SUM && sew < 3) : (dsew == sew));
    // uop 分类（uop 拆分约定：每个 uop 处理 vs1:vs2 两个寄存器，加宽时一个）
    red  = (!widen && (t.uop == 0 || (t.vlmul == 2 && t.uop < 2) || (t.vlmul == 3 && t.uop < 4)));
    widen_red = (widen && (t.uop == 0 || (t.vlmul == 1 && t.uop < 2) || (t.vlmul == 2 && t.uop < 4)
                           || (t.vlmul == 3 && t.uop < 8)));
    red  = red || widen_red;
    alu  = !widen && ((t.vlmul == 1 && t.uop < 1) || (t.vlmul == 2 && t.uop < 3) || (t.vlmul == 3 && t.uop < 7));
    walu = widen && (t.uop == 0 || (t.vlmul == 1 && t.uop < 3) || (t.vlmul == 2 && t.uop < 7)
                     || (t.vlmul == 3 && t.uop < 15));
    // 本 uop 的元素窗口
    n_uop_elem = widen ? (128 / ew) : (256 / ew);
    shift = t.uop * n_uop_elem;
    vlrem = (t.vl >= shift) ? (t.vl - shift) : 0;
    // mask / 尾部 → 单位元
    d = {t.vs1, t.vs2};
    any_masked = 0;
    any_cut = 0;
    for (int e = 0; e < 256 / ew; e++) begin
      bit mbit, active;
      mbit   = (shift + e < 128) ? t.mask[shift + e] : 1'b0;
      active = (t.vm || mbit) && (e < vlrem);
      if (red && !active) begin
        d = put_elem(d, ew, e, identity(kind, ew));
        if (!(t.vm || mbit)) any_masked = 1;
        if (e >= vlrem && vlrem > 0) any_cut = 1;
      end
    end
    if (alu || walu) begin
      // 两两合并：高半 ⊕ 低半（加宽 uop：低 128 位的两半各自扩展）
      logic [255:0] hi, lo, rr;
      hi = '0; lo = '0; rr = '0;
      if (widen_red) begin
        for (int e = 0; e < 64 / ew; e++) begin
          longint unsigned h, l;
          h = get_elem(d, ew, 64 / ew + e);
          l = get_elem(d, ew, e);
          if (sgn) begin h = sext(h, ew); l = sext(l, ew); end
          hi = put_elem(hi, 2 * ew, e, h);
          lo = put_elem(lo, 2 * ew, e, l);
        end
      end else begin
        hi = d[255:128];
        lo = d[127:0];
      end
      for (int e = 0; e < 128 / dw; e++)
        rr = put_elem(rr, dw, e, combine(kind, get_elem(hi, dw, e), get_elem(lo, dw, e), dw));
      res = rr[127:0];
      path = walu ? P_WALU : P_ALU;
    end else begin
      // 归约：vs1[0] ⊕ vs2 的全部 vd-sew 元素
      r = get_elem({128'd0, t.vs1}, dw, 0);
      for (int e = 0; e < 128 / dw; e++) r = combine(kind, r, get_elem(d, dw, e), dw);
      if (t.vl == 0) res = t.old;
      else begin
        logic [127:0] m0;
        m0  = 128'(wmask(dw));
        res = ((t.ta ? {128{1'b1}} : t.old) & ~m0) | (128'(r) & m0);
      end
      path = P_RED;
    end
    if (count && legal) begin
      if (path == P_RED) begin
        cov_red[kind][dsew]++;
        if (t.vl == 0) cov_vl0++;
        else cov_ta[t.ta]++;
        if (any_masked) cov_masked++;
        if (any_cut) cov_vlcut++;
      end else if (path == P_ALU) cov_alu[kind]++;
      else if (widen_red) cov_walu[sew]++;
    end
    return res;
  endfunction

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  function automatic logic [63:0] rand_chunk();
    int k;
    k = $urandom_range(0, 9);
    case (k)
      0:       return 64'd0;
      1:       return '1;
      2:       return {8{8'h80}} ^ (64'($urandom) & 64'h0101_0101_0101_0101);
      3:       return {8{8'h7F}} ^ (64'($urandom) & 64'h0101_0101_0101_0101);
      4:       return 64'($urandom_range(0, 3)) << ($urandom_range(0, 7) * 8);
      default: return {$urandom, $urandom};
    endcase
  endfunction

  function automatic logic [127:0] rand_vec();
    return {rand_chunk(), rand_chunk()};
  endfunction

  function automatic stim_t gen_stim();
    stim_t t;
    int sew, k;
    t.valid = ($urandom_range(0, 99) < 80);
    t.op    = ($urandom_range(0, 9) == 0) ? 6'($urandom) : 6'($urandom_range(33, 38));
    sew     = $urandom_range(0, 3);
    k       = $urandom_range(0, 99);
    t.st    = {(k < 45) ? 2'b00 : (k < 90) ? 2'b01 : 2'($urandom), 2'(sew)};
    k       = $urandom_range(0, 99);
    if (t.op == 6'd33 && sew < 3 && k < 40) t.vdt = {2'($urandom), 2'(sew + 1)};
    else if (k < 85)                        t.vdt = {2'($urandom), 2'(sew)};
    else                                    t.vdt = 4'($urandom);
    t.vlmul = ($urandom_range(0, 99) < 85) ? 3'($urandom_range(0, 3)) : 3'($urandom);
    k       = $urandom_range(0, 99);
    t.uop   = (k < 50) ? 6'($urandom_range(0, 3)) : (k < 75) ? 6'($urandom_range(0, 15)) : 6'($urandom);
    k       = $urandom_range(0, 99);
    if (k < 15)      t.vl = 8'd0;
    else if (k < 55) t.vl = 8'(t.uop * (256 >> (3 + sew)) + $urandom_range(0, (256 >> (3 + sew)) + 2) - 1);
    else             t.vl = 8'($urandom);
    t.vm    = $urandom_range(0, 1);
    k       = $urandom_range(0, 99);
    t.mask  = (k < 20) ? '1 : (k < 30) ? '0 : rand_vec() ^ {$urandom, $urandom, $urandom, $urandom};
    t.ta    = $urandom_range(0, 1);
    t.vs1   = rand_vec();
    t.vs2   = rand_vec();
    t.old   = {$urandom, $urandom, $urandom, $urandom};
    return t;
  endfunction

  // ---------------------------------------------------------------------------
  // 期望值流水：与 RTL 相同的两级（s1 在 valid 时装，s2 在上一拍 valid 时装）
  // ---------------------------------------------------------------------------
  logic [127:0] exp_pipe, exp_out;
  bit           pipe_legal, out_legal, fire_d;
  always @(posedge clock) begin
    if (reset) begin
      pipe_legal <= 0;
      out_legal  <= 0;
    end else begin
      bit lg;
      logic [127:0] e;
      if (fire_d) begin
        exp_out   <= exp_pipe;
        out_legal <= pipe_legal;
      end
      if (s.valid) begin
        e = oracle(s, lg, 1);
        exp_pipe   <= e;
        pipe_legal <= lg;
      end
    end
    fire_d <= s.valid;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    s = '0;
    repeat (5) @(negedge clock);
    reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      // 比较（上一个时钟沿之后的稳定输出）
      if (cyc > 2) begin
        checks++;
        if (out_g !== out_x) begin
          errors++;
          if (errors <= 10) $display("[%0d] DIFF g=%h x=%h", cyc, out_g, out_x);
        end
        if (out_legal) begin
          oracle_checks++;
          if (out_x !== exp_out) begin
            oracle_errors++;
            if (oracle_errors <= 10) $display("[%0d] ORACLE exp=%h x=%h g=%h", cyc, exp_out, out_x, out_g);
          end
        end
      end
      s = gen_stim();
    end
    begin
      bit cov_ok;
      cov_ok = 1;
      for (int k = 0; k < 8; k++) begin
        for (int w = 0; w < 4; w++) begin
          if (cov_red[k][w] < 200) begin cov_ok = 0; $display("COV red[%0d][%0d]=%0d < 200", k, w, cov_red[k][w]); end
        end
        if (cov_alu[k] < 200) begin cov_ok = 0; $display("COV alu[%0d]=%0d < 200", k, cov_alu[k]); end
      end
      for (int w = 0; w < 3; w++)
        if (cov_walu[w] < 200) begin cov_ok = 0; $display("COV walu[%0d]=%0d < 200", w, cov_walu[w]); end
      if (cov_vl0 < 500 || cov_ta[0] < 500 || cov_ta[1] < 500 || cov_masked < 500 || cov_vlcut < 500) begin
        cov_ok = 0;
        $display("COV misc vl0=%0d ta0=%0d ta1=%0d masked=%0d vlcut=%0d", cov_vl0, cov_ta[0], cov_ta[1], cov_masked, cov_vlcut);
      end
      if (oracle_checks < 50000) cov_ok = 0;
      $display("COVERAGE red(kind x dsew):");
      for (int k = 0; k < 8; k++)
        $display("  kind%0d: %0d %0d %0d %0d  alu=%0d", k, cov_red[k][0], cov_red[k][1], cov_red[k][2], cov_red[k][3], cov_alu[k]);
      $display("  walu sew0/1/2 = %0d %0d %0d; vl0=%0d ta0=%0d ta1=%0d masked=%0d vlcut=%0d",
               cov_walu[0], cov_walu[1], cov_walu[2], cov_vl0, cov_ta[0], cov_ta[1], cov_masked, cov_vlcut);
      $display("checks=%0d errors=%0d oracle_checks=%0d oracle_errors=%0d cov_ok=%0d",
               checks, errors, oracle_checks, oracle_errors, cov_ok);
      if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
