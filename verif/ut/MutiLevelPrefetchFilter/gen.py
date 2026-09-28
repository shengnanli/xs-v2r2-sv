#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— MutiLevelPrefetchFilter 的机械派生区与 UT tb。

rtl/memblock/MutiLevelPrefetchFilter.sv 里有四段 `BEGIN GENERATED(<tag>)` 区，全部没有设计
决策、只是长长的逐口连线，所以从 G1 golden 的端口表机械生成：

  ports             wrapper 的端口表：逐字取自 golden MutiLevelPrefetchFilter 的端口声明
  tlb_req_arb       RRArbiterInit_7（32 路 TLB 请求仲裁）的例化连线
  l1_pf_req_arb     RRArbiterInit_8（16 路 L1 预取仲裁）的例化连线
  l2_l3_pf_req_arb  RRArbiterInit_9 / RRArbiterInit_6（L2 / L3 预取仲裁）的例化连线

仲裁器的端口表从 golden 的 RRArbiterInit_{6,7,8,9}.sv 读出；每个端口都必须被下面的
映射规则认领，认领不了（或有规则没用上）就拒绝生成 —— 端口表变了一定会红，不会悄悄漏线。

另生成 verif/ut/MutiLevelPrefetchFilter/tb.sv：golden 与重写件双例化、同激励逐拍比对全部输出。

用法：
    python3 gen.py            # 生成（幂等：内容不变不写文件）
    python3 gen.py --check    # 产物与生成器不一致则非零退出
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
RTL = REPO / 'rtl' / 'memblock' / 'MutiLevelPrefetchFilter.sv'
TB = HERE / 'tb.sv'
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
TOP = 'MutiLevelPrefetchFilter'
TAG = 'verif/ut/MutiLevelPrefetchFilter/gen.py'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')


def die(msg):
    sys.stderr.write('gen.py: ' + msg + '\n')
    sys.exit(2)


def golden_ports(mod):
    """返回 [(方向, 位宽, 名字, 原始行)]，顺序与 golden 声明一致。"""
    text = (GOLDEN / (mod + '.sv')).read_text()
    m = re.search(r'^module\s+%s\s*\((.*?)^\);' % re.escape(mod), text, re.S | re.M)
    if not m:
        die('golden 里找不到 module %s' % mod)
    out = []
    for ln in m.group(1).splitlines():
        if not ln.strip():
            continue
        pm = PORT_RE.match(ln)
        if not pm:
            die('%s 端口行解析不了：%r' % (mod, ln))
        d, hi, name = pm.groups()
        out.append((d, int(hi) + 1 if hi else 1, name, ln.rstrip().rstrip(',')))
    return out


# -----------------------------------------------------------------------------
# 1. wrapper 端口表
# -----------------------------------------------------------------------------
def gen_ports():
    ps = golden_ports(TOP)
    lines = []
    for k, (_, _, _, raw) in enumerate(ps):
        lines.append(raw + (',' if k < len(ps) - 1 else ''))
    return lines


# -----------------------------------------------------------------------------
# 2. 仲裁器例化：每个端口按规则认领，规则 = (正则, 连线模板)
# -----------------------------------------------------------------------------
def arb_instance(mod, inst, rules):
    ps = golden_ports(mod)
    used = set()
    conns = []
    for _, _, name, _ in ps:
        hit = None
        for ri, (pat, tmpl) in enumerate(rules):
            mm = re.fullmatch(pat, name)
            if mm:
                hit = (ri, tmpl.format(*mm.groups()))
                break
        if hit is None:
            die('%s 的端口 %s 没有映射规则' % (mod, name))
        used.add(hit[0])
        conns.append((name, hit[1]))
    unused = [rules[i][0] for i in range(len(rules)) if i not in used]
    if unused:
        die('%s 有规则没用上（golden 端口表变了？）：%s' % (mod, unused))
    w = max(len(n) for n, _ in conns)
    lines = ['%s %s (' % (mod, inst)]
    for k, (n, c) in enumerate(conns):
        lines.append('  .%s (%s)%s' % (n.ljust(w), c, ',' if k < len(conns) - 1 else ''))
    lines.append(');')
    return lines


def gen_tlb_arb():
    return arb_instance('RRArbiterInit_7', 'tlb_req_arb', [
        (r'clock', 'clock'),
        (r'reset', 'reset'),
        (r'io_in_(\d+)_ready', 'tlb_in_ready[{0}]'),
        (r'io_in_(\d+)_valid', 'tlb_in_valid[{0}]'),
        (r'io_in_(\d+)_bits_vaddr', 'tlb_in_vaddr[{0}]'),
        (r'io_out_valid', 'tlb_arb_out_valid'),
        (r'io_out_bits_vaddr', 'tlb_arb_out_vaddr'),
    ])


def gen_l1_arb():
    return arb_instance('RRArbiterInit_8', 'l1_pf_req_arb', [
        (r'clock', 'clock'),
        (r'reset', 'reset'),
        (r'io_in_(\d+)_ready', ''),                       # 各路 ready 本模块不看
        (r'io_in_(\d+)_valid', 'l1_arb_in_valid[{0}]'),
        (r'io_in_(\d+)_bits_req_paddr', 'l1_arb_in_bits[{0}].paddr'),
        (r'io_in_(\d+)_bits_req_alias', 'l1_arb_in_bits[{0}].alias_'),
        (r'io_in_(\d+)_bits_req_confidence', 'l1_arb_in_bits[{0}].confidence'),
        (r'io_in_(\d+)_bits_req_pf_source_value', 'l1_arb_in_bits[{0}].pf_source_value'),
        (r'io_out_ready', 'l1_arb_out_ready'),
        (r'io_out_valid', 'l1_arb_out_valid'),
        (r'io_out_bits_req_paddr', 'l1_arb_out_paddr'),
        (r'io_out_bits_req_alias', 'l1_arb_out_alias'),
        (r'io_out_bits_req_confidence', 'l1_arb_out_confidence'),
        (r'io_out_bits_req_pf_source_value', 'l1_arb_out_pf_source_value'),
        (r'io_chosen', 'l1_pf_chosen'),
    ])


def gen_l2_l3_arb():
    l2 = arb_instance('RRArbiterInit_9', 'l2_pf_req_arb', [
        (r'clock', 'clock'),
        (r'reset', 'reset'),
        (r'io_in_(\d+)_valid', 'l2_arb_in_valid[{0}]'),
        (r'io_in_(\d+)_bits_req_addr', 'l2_pf_addr_e[{0}]'),
        (r'io_in_(\d+)_bits_req_source', 'l2_reqsource[{0}]'),
        (r'io_out_valid', 'l2_arb_out_valid'),
        (r'io_out_bits_req_addr', 'l2_arb_out_addr'),
        (r'io_out_bits_req_source', 'l2_arb_out_source'),
        (r'io_chosen', 'l2_arb_chosen'),
    ])
    l3 = arb_instance('RRArbiterInit_6', 'l3_pf_req_arb', [
        (r'clock', 'clock'),
        (r'reset', 'reset'),
        (r'io_in_(\d+)_ready', ''),
        (r'io_in_(\d+)_valid', 'l3_arb_in_valid[{0}]'),
        (r'io_in_(\d+)_bits', 'l2_pf_addr_e[{0}]'),     # 发往 L3 的地址与 L2 的同一个算法
        (r'io_out_valid', 'l3_arb_out_valid'),
        (r'io_out_bits', 'l3_pf_addr'),
        (r'io_chosen', 'l3_arb_chosen'),
    ])
    return l2 + [''] + l3


def splice(text, tag, body, indent):
    pat = re.compile(r'(^[ \t]*// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(^[ \t]*// END GENERATED[^\n]*\n)'
                     % re.escape(tag), re.S | re.M)
    m = pat.search(text)
    if not m:
        die('RTL 里找不到 GENERATED(%s) 区' % tag)
    block = ''.join((indent + l if l else '') + '\n' for l in body)
    return text[:m.start(2)] + block + text[m.end(2):]


def gen_rtl(text):
    text = splice(text, 'ports', gen_ports(), '')
    text = splice(text, 'tlb_req_arb', gen_tlb_arb(), '  ')
    text = splice(text, 'l1_pf_req_arb', gen_l1_arb(), '  ')
    text = splice(text, 'l2_l3_pf_req_arb', gen_l2_l3_arb(), '  ')
    return text


# -----------------------------------------------------------------------------
# 3. tb
# -----------------------------------------------------------------------------
TB_HEAD = '''\
// =============================================================================
// MutiLevelPrefetchFilter UT —— golden MutiLevelPrefetchFilter 对重写 MutiLevelPrefetchFilter_xs
// 双例化，同激励逐拍比对全部 {nout} 根输出（{noutbits} 位）。
// 本文件由 {tag} 生成（幂等），不要手改。
//
// 激励要点（判别力来自哪里）：
//   · 区域地址从一个小池子里取（每 seed 32 个），让「命中已有项 → update」「不中 → alloc」都常见；
//     另有 1/8 的请求只改 region[39:25] —— 哈希不看这些位，专打「哈希相同、区域不同」的冲突路径；
//   · 负载分相：每 1024 拍换一次两路请求的发送概率（0/15/45/85%），让表有满有空、有替换有闲置；
//   · TLB 用一个 1 拍延迟的回应模型接住 golden 的 io_tlb_req_req（偶尔丢回应 / 凭空回应），
//     miss / 三种异常 / pbmt / PMP 都有小概率，物理地址 85% 落在 PmemRanges 里；
//   · l2 请求的 sink 取 L2/L3 为主，也给 L1 和非法值 3；io_l1_req_ready / io_enable 随机；
//   · 偶发 3 拍复位脉冲（复位期间两侧都不比）。
// 比较窗口：+vcs+initreg+random 下两侧的不复位寄存器初值各摇各的（双例化的已知性质），
//   其中 s1_pf_bits_* 与 s1_tlb_req_bits_* 直接连输出、要等第一次发出才被覆盖；
//   L2/L3 仲裁器在没有候选时照样把某一路（无效项）的地址摆在 io_l2_pf_addr_bits_* 上，
//   那是没写过的表项内容（seed 7 实测：第 32 拍起 10 拍 io_l2_pf_addr_bits_addr 两侧不同）。
//   所以复位释放后先等：golden 各发出过一次 TLB 请求与一次 L1 预取、且两张表的 32 项
//   每一项都被 alloc 过（valid 曾经为 1），再加 4 拍，之后逐拍全比，直到结束。
//   这段等待在 +0 档下同样生效，只影响开头几百～几千拍（checks 数照实打印）。
// 覆盖判据：比较窗口内 L1 预取 / L2 预取 / TLB 请求 / 表命中(update) / TLB 回填作废 等事件
//   每一类都必须发生过，否则本轮 errors=0 不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;
'''


def gen_tb():
    ps = golden_ports(TOP)
    ins = [(w, n) for d, w, n, _ in ps if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n, _ in ps if d == 'output']
    L = []
    L.append(TB_HEAD.format(nout=len(outs), noutbits=sum(w for w, _ in outs), tag=TAG).rstrip('\n'))
    L.append('')
    L.append('  // ---- 输入（两个 DUT 共用）----')
    L.append('  logic reset;')
    for w, n in ins:
        L.append('  logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n))
    L.append('')
    L.append('  // ---- 输出：g_ = golden，x_ = 重写 ----')
    for w, n in outs:
        dim = '[%d:0] ' % (w - 1) if w > 1 else ''
        L.append('  logic %sg_%s, x_%s;' % (dim, n, n))
    L.append('')
    for inst, mod, pfx in (('g_dut', TOP, 'g_'), ('x_dut', TOP + '_xs', 'x_')):
        L.append('  %s %s (' % (mod, inst))
        conns = ['.clock(clk)', '.reset(reset)']
        conns += ['.%s(%s)' % (n, n) for _, n in ins]
        conns += ['.%s(%s%s)' % (n, pfx, n) for _, n in outs]
        for k, c in enumerate(conns):
            L.append('    %s%s' % (c, ',' if k < len(conns) - 1 else ''))
        L.append('  );')
        L.append('')
    L.append('  // ---- 逐拍比较全部输出 ----')
    L.append('  task automatic compare_outputs();')
    L.append('    checks++;')
    for _, n in outs:
        L.append('    if (g_%s !== x_%s) begin errors++; if (errors < 20) '
                 '$display("MISMATCH @%%0t %s g=%%h x=%%h", $time, g_%s, x_%s); end'
                 % (n, n, n, n, n))
    L.append('  endtask')
    L.append('')
    gv = ', '.join('g_dut.%s_valids_%d' % (t, i) for t in ('l2', 'l1') for i in range(15, -1, -1))
    L.append(TB_BODY.replace('{{g_valids}}', '{' + gv + '}').rstrip('\n'))
    return '\n'.join(L) + '\n'


TB_BODY = r'''
  // ---- 激励 ----
  logic [39:0] pool [32];
  int unsigned load_l1, load_l2;          // 当前相位的两路请求概率（%）
  bit          l1_req_is_alias;           // 本拍 L1 请求是不是「只改了高位」的那种

  function automatic logic [39:0] pick_region(output bit is_alias);
    int p = $urandom_range(0, 99);
    logic [39:0] r = pool[$urandom_range(0, 31)];
    is_alias = (p < 12);
    if (p < 12)      r[39:25] = 15'($urandom);                // 哈希相同、区域不同
    else if (p < 20) r = {8'($urandom), 32'($urandom)};       // 全随机
    return r;
  endfunction

  function automatic logic [15:0] pick_bitvec();
    int p = $urandom_range(0, 99);
    if (p < 3)  return 16'h0;
    if (p < 25) return 16'h1 << $urandom_range(0, 15);
    if (p < 35) return 16'hFFFF;
    return 16'($urandom);
  endfunction

  function automatic logic [2:0] pick_source();
    int p = $urandom_range(0, 99);
    if (p < 40) return 3'd3;       // stream
    if (p < 75) return 3'd2;       // stride
    return 3'($urandom);
  endfunction

  function automatic logic [1:0] pick_sink();
    int p = $urandom_range(0, 99);
    if (p < 45) return 2'd1;       // L2
    if (p < 90) return 2'd2;       // L3
    if (p < 97) return 2'd0;       // L1（上游不会给 L2 表发 L1，但端口是自由的）
    return 2'd3;                   // 非法编码
  endfunction

  // TLB 回应模型：golden 在第 t 拍发请求，第 t+1 拍回应（偶尔丢 / 凭空多一个）
  logic tlb_req_q = 1'b0;
  always @(posedge clk) tlb_req_q <= g_io_tlb_req_req_valid;

  task automatic drive_inputs(longint c);
    bit dummy_alias;
    if (c % 1024 == 0) begin
      int ph = $urandom_range(0, 3);
      load_l1 = (ph == 0) ? 0 : (ph == 1) ? 15 : (ph == 2) ? 45 : 85;
      ph = $urandom_range(0, 3);
      load_l2 = (ph == 0) ? 0 : (ph == 1) ? 15 : (ph == 2) ? 45 : 85;
    end
    io_enable                  = ($urandom_range(0, 99) < 92);
    io_confidence              = 1'($urandom);
    io_l1_prefetch_req_valid   = ($urandom_range(0, 99) < load_l1);
    io_l1_prefetch_req_bits_region       = pick_region(l1_req_is_alias);
    io_l1_prefetch_req_bits_bit_vec      = pick_bitvec();
    io_l1_prefetch_req_bits_source_value = pick_source();
    io_l2_l3_prefetch_req_valid = ($urandom_range(0, 99) < load_l2);
    io_l2_l3_prefetch_req_bits_region       = pick_region(dummy_alias);
    io_l2_l3_prefetch_req_bits_bit_vec      = pick_bitvec();
    io_l2_l3_prefetch_req_bits_sink         = pick_sink();
    io_l2_l3_prefetch_req_bits_source_value = pick_source();
    // TLB 回应
    io_tlb_req_resp_valid = tlb_req_q ? ($urandom_range(0, 99) < 95) : ($urandom_range(0, 99) < 2);
    if ($urandom_range(0, 99) < 85) begin            // 落在 PmemRanges [0x8000_0000, 0x800_0000_0000)
      io_tlb_req_resp_bits_paddr_0 = {5'h0, 11'($urandom), 32'($urandom)};
      if (io_tlb_req_resp_bits_paddr_0 < 48'h8000_0000) io_tlb_req_resp_bits_paddr_0[31] = 1'b1;
    end else begin
      io_tlb_req_resp_bits_paddr_0 = {16'($urandom), 32'($urandom)};
    end
    io_tlb_req_resp_bits_pbmt_0        = ($urandom_range(0, 99) < 85) ? 2'd0 : 2'($urandom);
    io_tlb_req_resp_bits_miss          = ($urandom_range(0, 99) < 15);
    io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 99) < 3);
    io_tlb_req_resp_bits_excp_0_pf_ld  = ($urandom_range(0, 99) < 3);
    io_tlb_req_resp_bits_excp_0_af_ld  = ($urandom_range(0, 99) < 3);
    io_pmp_resp_ld   = ($urandom_range(0, 99) < 3);
    io_pmp_resp_mmio = ($urandom_range(0, 99) < 3);
    io_l1_req_ready  = ($urandom_range(0, 99) < 75);
  endtask

  // ---- 覆盖事件（golden 侧计数，比较窗口内）----
  longint n_l1_fire, n_l2_pf, n_tlb_req, n_update_l1, n_update_l2, n_drop, n_hash_alias;
  task automatic collect_cov();
    if (g_io_l1_req_valid && io_l1_req_ready) n_l1_fire++;
    if (g_io_l2_pf_addr_valid)                n_l2_pf++;
    if (g_io_tlb_req_req_valid)               n_tlb_req++;
    if (g_dut.s1_l1_valid && g_dut.s1_l1_hit) n_update_l1++;
    if (g_dut.s1_l2_valid && g_dut.s1_l2_hit) n_update_l2++;
    if (g_dut.s3_drop)                        n_drop++;
    if (io_l1_prefetch_req_valid && l1_req_is_alias && g_dut.s0_l1_can_accept) n_hash_alias++;
  endtask

  // 两张表每一项是否被 alloc 过（热身判据，见文件头）
  logic [31:0] ever_valid = '0;
  always @(posedge clk) ever_valid <= ever_valid | {{g_valids}};

  initial begin
    bit warm_tlb, warm_l1;
    int warm_cnt;
    bit cmp_on;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 32; i++) pool[i] = {8'($urandom), 32'($urandom)};
    load_l1 = 45; load_l2 = 45;
    warm_tlb = 0; warm_l1 = 0; warm_cnt = 0; cmp_on = 0;
    reset = 1;
    drive_inputs(1);
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 0; c < NCYCLES; c++) begin
      // 偶发复位脉冲：拉 3 拍，期间不比；不复位寄存器两侧保持相同，复位后不必重新热身
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(c); @(negedge clk); end
        reset = 0;
      end
      drive_inputs(c);
      #1;
      if (g_io_tlb_req_req_valid) warm_tlb = 1;
      if (g_io_l1_req_valid)      warm_l1  = 1;
      if (warm_tlb && warm_l1 && (&ever_valid) && !cmp_on) begin
        warm_cnt++;
        if (warm_cnt > 4) cmp_on = 1;
      end
      if (cmp_on) begin compare_outputs(); collect_cov(); end
      @(negedge clk);
    end
    $display("=== COVERAGE (MutiLevelPrefetchFilter) === checks=%0d l1_fire=%0d l2_pf=%0d tlb_req=%0d upd_l1=%0d upd_l2=%0d drop=%0d hash_alias=%0d",
             checks, n_l1_fire, n_l2_pf, n_tlb_req, n_update_l1, n_update_l2, n_drop, n_hash_alias);
    if (checks < NCYCLES - 2000 || n_l1_fire == 0 || n_l2_pf == 0 || n_tlb_req == 0 ||
        n_update_l1 == 0 || n_update_l2 == 0 || n_drop == 0 || n_hash_alias == 0) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
'''


def main(argv):
    check = '--check' in argv
    outputs = {RTL: gen_rtl(RTL.read_text()), TB: gen_tb()}
    bad = []
    for path, text in outputs.items():
        old = path.read_text() if path.exists() else None
        if old != text:
            if check:
                bad.append(path)
            else:
                path.write_text(text)
                print('gen.py: 写入 %s' % path.relative_to(REPO))
    if check:
        if bad:
            print('gen.py --check: 以下产物与生成器不一致：')
            for p in bad:
                print('  ' + str(p.relative_to(REPO)))
            return 1
        print('gen.py --check: %d 个产物与生成器一致' % len(outputs))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
