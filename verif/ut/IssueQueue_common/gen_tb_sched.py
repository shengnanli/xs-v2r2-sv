#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb_sched.py —— 为 Scheduler* 生成 UT（verif/ut/<S>/{tb.sv,Makefile}）

tb = golden <S> 与重写 <S>_xs 双例化、同激励，逐拍比对全部输出。激励按端口名分类
（与 gen_tb.py 同一套思路，端口名换成调度器的：fromDispatch / *WriteBack* / fromDataPath / …）：
  * 每个 Dispatch 口的 fuType 90% 取**该口所连 IQ** 保留 FuType 位里的 one-hot（从 golden 实例连线查）；
  * pdest / psrc / 写回 addr 共用 8 值小池；srcState 就绪概率按所连 IQ 的源数（>2 源 80%，否则 50%）；
  * robIdx 围着缓慢前进的游标取值；各类响应 / 取消 / 写使能独立点亮；DataPath 的 ready 85%。
比对口径同 gen_tb.py：`+cmp_all`（INITREG=0 档）每拍比全部输出；随机初值档里 io_toDataPathAfterDelay_*_bits_*
只在对应 valid=1 时比，其余输出等所有 IQ 的条目阵列都被写过才开始比。
覆盖闸：每个 IQ 都入过队、每个出队口都发射过、冲刷出现过。

用法: python3 gen_tb_sched.py <S> [--check]
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(REPO / 'scripts'))
sys.path.insert(0, str(HERE))
import gen_iq   # noqa: E402
import gen_tb   # noqa: E402


def gen(v):
    c = gen_iq.Ctx(v)
    ins = [(w, n) for d, w, n in c.ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in c.ports if d == 'output']
    # Dispatch 口 k -> 所连 IQ 的 (保留 FuType 位, 源数)
    port_iq = {}
    iq_facts = {}
    for mod, inst, conns in c.insts:
        ci = gen_iq.Ctx(mod)
        P, _ = gen_iq.measure(ci)
        keep = [b for b in range(35) if any(a >> b & 1 for a in P['ACCEPT'])]
        iq_facts[inst] = (keep, P['N_SRC'], P['N_DEQ'])
        for p, e in conns:
            m = re.fullmatch(r'io_enq_\d+_bits_fuType', p)
            mm = re.fullmatch(r'io_fromDispatch_uops_(\d+)_bits_fuType', e)
            if m and mm:
                port_iq.setdefault(int(mm.group(1)), inst)

    def stim(n, w):
        rnd = f"{w}'($urandom)" if w <= 32 else f"{{{', '.join(['$urandom'] * ((w + 31) // 32))}}}"
        m = re.fullmatch(r'io_fromDispatch_uops_(\d+)_(.*)', n)
        if re.search(r'flush_valid$', n):
            return 'pct(2)'
        if m:
            k, f = int(m.group(1)), m.group(2)
            inst = port_iq.get(k)
            keep, nsrc, _ = iq_facts[inst] if inst else ([0], 2, 1)
            if f == 'valid':
                return 'pct(60)'
            if f == 'bits_fuType':
                kl = ', '.join(str(b) for b in keep)
                return f"(pct(90) ? (35'h1 << pick_of('{{{kl}}}, {len(keep)})) : {{3'($urandom), $urandom}})"
            if re.fullmatch(r'bits_srcType_\d+', f):
                return 'pick_src_type()'
            if re.fullmatch(r'bits_(psrc_\d+|pdest)', f):
                return f"{w}'(pick_preg())"
            if re.fullmatch(r'bits_srcState_\d+', f):
                return 'pct(50)' if nsrc <= 2 else 'pct(80)'
            if f == 'bits_robIdx_value':
                return f"{w}'(rob_cursor + $urandom_range(0, 12))"
            if f == 'bits_isDropAmocasSta':
                return 'pct(10)'
            return rnd
        if re.search(r'robIdx_value$', n):
            return f"{w}'(rob_cursor + $urandom_range(0, 12))"
        if re.search(r'(_addr|_pdest)$', n) and w <= 8:
            return f"{w}'(pick_preg())"
        if re.search(r'og[012]resp_valid$', n) or re.search(r'Resp_\d+_valid$', n):
            return 'pct(40)'
        if re.search(r'(_wen|Wen)$', n) or re.search(r'wakeupVec(Delayed)?_\d+_valid$', n):
            return 'pct(35)'
        if re.search(r'Cancel(_\d+)?$', n):
            return 'pct(10)'
        if re.search(r'_ready$', n):
            return 'pct(85)'
        return rnd

    L = []
    L.append(f'// {v} UT —— golden {v} 与重写 {v}_xs 双例化，逐拍比对全部 {len(outs)} 个输出。')
    L.append('// 激励与比对口径见 verif/ut/IssueQueue_common/gen_tb_sched.py 文件头。')
    L.append('// 自动生成：verif/ut/IssueQueue_common/gen_tb_sched.py —— 勿手改')
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit clock = 0;')
    L.append('  bit reset = 1;')
    L.append('  bit cmp_all = 0;')
    L.append('  always #5 clock = ~clock;')
    L.append('  longint checks = 0;')
    L.append('  longint errors = 0;')
    L.append('  logic [8:0] rob_cursor = 0;')
    for w, n in ins:
        L.append(f'  logic {gen_iq.sv_w(w)}{n};')
    for w, n in outs:
        L.append(f'  wire {gen_iq.sv_w(w)}g_{n}, i_{n};')
    for side, mod in (('g', v), ('i', v + '_xs')):
        L.append(f'  {mod} u_{side} (')
        items = ['.clock(clock)', '.reset(reset)'] + [f'.{n}({n})' for _, n in ins] + \
                [f'.{n}({side}_{n})' for _, n in outs]
        L.append(',\n'.join('    ' + x for x in items))
        L.append('  );')
    L.append('  function automatic logic pct(int p); return $urandom_range(0, 99) < p; endfunction')
    L.append("  function automatic logic [7:0] pick_preg(); return 8'($urandom_range(0, 7)); endfunction")
    L.append('  function automatic int pick_of(int list [], int n); return list[$urandom_range(0, n - 1)]; endfunction')
    L.append('  function automatic logic [3:0] pick_src_type();')
    L.append('    int r = $urandom_range(0, 9);')
    L.append("    case (r) 0: return 4'h0; 1, 2, 3: return 4'h1; 4: return 4'h2; 5: return 4'h4;")
    L.append("      6: return 4'h8; default: return 4'($urandom); endcase")
    L.append('  endfunction')
    L.append('  always @(negedge clock) begin')
    L.append('    if (pct(25)) rob_cursor = rob_cursor + 1;')
    for w, n in ins:
        L.append(f'    {n} = {stim(n, w)};')
    L.append('  end')
    iqs = [inst for _, inst, _ in c.insts]
    for inst in iqs:
        L.append(f'  bit ever_{inst} = 0;')
    L.append('  bit warm = 0;')
    L.append('  task automatic chk(string nm, logic [1023:0] g, logic [1023:0] i, bit gate);')
    L.append('    if (!gate) return;')
    L.append('    checks++;')
    L.append('    if (g !== i) begin')
    L.append('      errors++;')
    L.append('      if (errors <= 40) $display("[ERR] t=%0t %s golden=%h impl=%h", $time, nm, g, i);')
    L.append('    end')
    L.append('  endtask')
    deqs = sorted({m.group(1) for _, n in outs for m in [re.fullmatch(r'io_toDataPathAfterDelay_(\d+_\d+)_valid', n)] if m})
    for inst in iqs:
        L.append(f'  longint cov_enq_{inst} = 0;')
    for d in deqs:
        L.append(f'  longint cov_deq_{d} = 0;')
    L.append('  longint cov_flush = 0;')
    L.append('  always @(posedge clock) begin')
    L.append('    #4;')
    L.append('    if (!reset) begin')
    for inst in iqs:
        L.append(f'      if (&u_g.{inst}._entries_io_valid) ever_{inst} = 1;')
    L.append('      if (' + ' && '.join(f'ever_{i}' for i in iqs) + ') warm = 1;')
    for w, n in outs:
        m = re.fullmatch(r'io_toDataPathAfterDelay_(\d+_\d+)_bits_\w+', n)
        gate = f'cmp_all || (warm && g_io_toDataPathAfterDelay_{m.group(1)}_valid)' if m else 'cmp_all || warm'
        L.append(f'      chk("{n}", g_{n}, i_{n}, {gate});')
    for inst in iqs:
        L.append(f'      if ((u_g.{inst}.io_enq_0_valid && u_g.{inst}.io_enq_0_ready) || '
                 f'(u_g.{inst}.io_enq_1_valid && u_g.{inst}.io_enq_1_ready)) cov_enq_{inst}++;')
    for d in deqs:
        L.append(f'      if (g_io_toDataPathAfterDelay_{d}_valid) cov_deq_{d}++;')
    fl = [n for _, n in ins if n.endswith('flush_valid')]
    L.append(f'      if ({fl[0]}) cov_flush++;')
    L.append('    end')
    L.append('  end')
    L.append('  initial begin')
    L.append('    int bad;')
    L.append('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    L.append('    if ($test$plusargs("cmp_all")) cmp_all = 1;')
    L.append('    reset = 1; repeat (5) @(posedge clock); @(negedge clock); reset = 0;')
    L.append('    repeat (NCYCLES) @(posedge clock);')
    L.append('    bad = (errors != 0);')
    L.append('    if (!warm && !cmp_all) begin bad = 1; $display("*** 条目阵列没有全部被写过，随机初值档无法比对"); end')
    for k in [f'enq_{i}' for i in iqs] + [f'deq_{d}' for d in deqs] + ['flush']:
        L.append(f'    $display("  cov %-40s = %0d", "{k}", cov_{k});')
        L.append(f'    if (cov_{k} == 0) begin bad = 1; $display("  *** COVERAGE HOLE: {k}"); end')
    L.append('    $display("cmp_all=%0d warm=%0d", cmp_all, warm);')
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (!bad) $display("TEST PASSED"); else $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def makefile(v):
    c = gen_iq.Ctx(v)
    gold = []

    def gdeps(m):
        _, body = gen_iq.module_text(m)
        for sub in re.findall(r'^  ([A-Z]\w*) \w+ \($', body, re.M):
            if sub not in gold:
                gold.append(sub)
                gdeps(sub)
    gdeps(v)
    impl = gen_tb.rtl_closure(v)
    rtl_list = (' \\\n' + ' ' * 11).join('$(RTL_DIR)/' + x for x in impl)
    return f'''MODULE = {v}

# {v}（调度器）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   {' '.join(gold)}
# 自动生成：verif/ut/IssueQueue_common/gen_tb_sched.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = {rtl_list}
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/{v}.sv {' '.join('$(GOLDEN_RTL)/' + g + '.sv' for g in gold)}

FM_VARIANTS = {v}
FM_REF_DEPS_{v} = {' '.join(g + '.sv' for g in gold)}

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
'''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('variant')
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    d = REPO / 'verif' / 'ut' / a.variant
    files = {d / 'tb.sv': gen(a.variant), d / 'Makefile': makefile(a.variant)}
    bad = 0
    for p, t in files.items():
        if a.check:
            if not p.exists() or p.read_text() != t:
                print(f'gen_tb_sched --check: {p} 不一致')
                bad = 1
        else:
            d.mkdir(parents=True, exist_ok=True)
            p.write_text(t)
            print(f'gen_tb_sched: 写 {p}')
    if a.check and not bad:
        print(f'gen_tb_sched --check: {a.variant} OK')
    return bad


if __name__ == '__main__':
    sys.exit(main())
