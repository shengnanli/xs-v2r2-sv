#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— 为 IssueQueue* 家族生成 UT（verif/ut/<V>/{tb.sv,Makefile}）

tb = golden <V> 与重写 <V>_xs 双例化、同激励，逐拍比对**全部**输出口。端口表从 G1 golden
机械提取；激励按端口名分类（见 STIM），不是逐位均匀随机 —— 均匀随机推不动发射队列：
  * pdest / psrc 共用 8 值小池（含 0），否则唤醒永远打不中队里的源；
  * srcType 从 {0, Xp, Fp, Vp, V0, Vl, 随机} 里挑，psrc==0 时的 x0 / v0 特判才会被打到；
  * enq.fuType 90% 取本 IQ 保留 FuType 位里的 one-hot（否则进了队也没有发射口接收）；
  * robIdx 围着一个缓慢前进的游标取值，redirect 冲刷才会命中在队指令；
  * og0/og1(/og2) resp、取消、忙表输入各自独立点亮。
比对口径：
  * `+cmp_all`（INITREG=0 档由 Makefile 自动加）：复位释放后**每拍比全部输出**；
  * 其余档（随机初值）：未复位寄存器（条目负载、deqDelay 负载）两侧初值不同，所以
    io_deqDelay_<d>_bits_* 只在 golden io_deqDelay_<d>_valid=1 时比；其余输出等条目阵列
    每一项都被写过（ever_valid 全 1）才开始比，整轮没等到判 FAIL。
覆盖闸（任一为 0 判 FAIL）：入队、各口出队、comp/simp/enq 三段各被选中过、cancelDeq、
冲刷、deqDelay 非 ready、（有 MWQ 时）唤醒出口有效。

用法: python3 gen_tb.py <V> [--check]
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(REPO / 'scripts'))
import gen_iq  # noqa: E402


def stim(n, w, P):
    """按端口名给激励表达式（在 negedge 块里赋值）。"""
    rnd = f"{w}'($urandom)" if w <= 32 else f"{{{', '.join(['$urandom'] * ((w + 31) // 32))}}}"
    if n == 'io_flush_valid':
        return 'pct(2)'
    if re.fullmatch(r'io_enq_\d+_valid', n):
        return 'pct(60)'
    if re.fullmatch(r'io_enq_\d+_bits_fuType', n):
        return 'enq_fu_type()'
    if re.search(r'_srcType_\d+$', n) and n.startswith('io_enq'):
        return 'pick_src_type()'
    if re.search(r'(_psrc_\d+|_pdest|_bits_pdest)$', n):
        return f"{w}'(pick_preg())"
    if re.search(r'_srcState_\d+$', n):
        # 源多（FP 3 个 / VEC 5 个）时 50% 就绪几乎凑不齐全就绪，队列堵死、发射极少（VEC 实测 200k 拍仅 ~2.7k 次）
        return 'pct(50)' if P['N_SRC'] <= 2 else 'pct(80)'
    if re.search(r'robIdx_value$', n):
        return f"{w}'(rob_cursor + $urandom_range(0, 12))"
    if re.fullmatch(r'io_og[012]Resp_\d+_valid', n):
        return 'pct(40)'
    if re.fullmatch(r'io_wakeupFrom\w+_valid', n):
        return 'pct(35)'
    if re.fullmatch(r'io_wakeupFromIQ(Delayed)?_\d+_bits_(rf|fp|vec|v0|vl)Wen', n):
        return 'pct(35)'
    if re.fullmatch(r'io_og[01]Cancel_\d+', n):
        return 'pct(10)'
    if re.fullmatch(r'io_ldCancel_\d+_ld[12]Cancel', n):
        return 'pct(10)'
    if re.fullmatch(r'io_deqDelay_\d+_ready', n):
        return 'pct(85)'
    return rnd


def gen(v):
    c = gen_iq.Ctx(v)
    P, en = gen_iq.measure(c)
    ins = [(w, n) for d, w, n in c.ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in c.ports if d == 'output']
    keep = [b for b in range(35) if any(a >> b & 1 for a in P['ACCEPT'])]
    has_mwq = any(m.startswith('MultiWakeupQueue') for m, _, _ in c.insts)
    has_cancel = 'deqSelValidVec_0' in c.wires   # 只有带 load 取消网络的变体才有 cancelDeqVec
    ND, N = P['N_DEQ'], P['N_ENTRIES']
    L = []
    L.append(f'// {v} UT —— golden {v} 与重写 {v}_xs 双例化，逐拍比对全部 {len(outs)} 个输出。')
    L.append('// 激励与比对口径见 verif/ut/IssueQueue_common/gen_tb.py 文件头。')
    L.append('// 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改')
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
    L.append('')
    for w, n in ins:
        L.append(f'  logic {gen_iq.sv_w(w)}{n};')
    for w, n in outs:
        L.append(f'  wire {gen_iq.sv_w(w)}g_{n}, i_{n};')
    L.append('')
    for side, mod in (('g', v), ('i', v + '_xs')):
        L.append(f'  {mod} u_{side} (')
        items = ['.clock(clock)', '.reset(reset)'] + [f'.{n}({n})' for _, n in ins] + \
                [f'.{n}({side}_{n})' for _, n in outs]
        L.append(',\n'.join('    ' + x for x in items))
        L.append('  );')
    L.append('')
    L.append('  function automatic logic pct(int p); return $urandom_range(0, 99) < p; endfunction')
    L.append('  // 物理寄存器号小池：85% 取 0..7（唤醒才打得中），15% 取 0x80..0x83'
             '（最高位为 1：检验 psrc==0 按端口全宽判）')
    L.append('  function automatic logic [7:0] pick_preg();')
    L.append("    return pct(85) ? 8'($urandom_range(0, 7)) : 8'($urandom_range(128, 131));")
    L.append('  endfunction')
    L.append('  function automatic logic [3:0] pick_src_type();')
    L.append('    int r = $urandom_range(0, 9);')
    L.append("    case (r) 0: return 4'h0; 1, 2, 3: return 4'h1; 4: return 4'h2; 5: return 4'h4;")
    L.append("      6: return 4'h8; default: return 4'($urandom); endcase")
    L.append('  endfunction')
    kl = ', '.join(str(b) for b in keep)
    L.append('  function automatic logic [34:0] enq_fu_type();')
    L.append(f'    int keep [{len(keep)}] = \'{{{kl}}};')
    L.append("    if (pct(90)) return 35'h1 << keep[$urandom_range(0, " + str(len(keep) - 1) + ')];')
    L.append("    return {3'($urandom), $urandom};")
    L.append('  endfunction')
    L.append('')
    L.append('  // ---- 激励：下降沿给 ----')
    L.append('  always @(negedge clock) begin')
    L.append('    if (pct(25)) rob_cursor = rob_cursor + 1;')
    for w, n in ins:
        L.append(f'    {n} = {stim(n, w, P)};')
    L.append('  end')
    L.append('')
    # ---- 比对 ----
    L.append(f'  bit [{N - 1}:0] ever_valid = 0;')
    L.append('  bit warm = 0;')
    L.append('  task automatic chk(string nm, logic [1023:0] g, logic [1023:0] i, bit gate);')
    L.append('    if (!gate) return;')
    L.append('    checks++;')
    L.append('    if (g !== i) begin')
    L.append('      errors++;')
    L.append('      if (errors <= 40) $display("[ERR] t=%0t %s golden=%h impl=%h", $time, nm, g, i);')
    L.append('    end')
    L.append('  endtask')
    cov = ['enq_fire', 'flush', 'sel_comp', 'sel_simp', 'sel_enq', 'dly_not_ready'] + \
          (['cancel_deq'] if has_cancel else []) + \
          [f'deq{d}' for d in range(ND)] + (['wk_out'] if has_mwq else [])
    for k in cov:
        L.append(f'  longint cov_{k} = 0;')
    L.append('  always @(posedge clock) begin')
    L.append('    #4;')
    L.append('    if (!reset) begin')
    L.append(f'      ever_valid |= u_g._entries_io_valid;')
    L.append("      if (&ever_valid) warm = 1;")
    for w, n in outs:
        m = re.fullmatch(r'io_deqDelay_(\d+)_bits_\w+', n)
        gate = f'cmp_all || (warm && g_io_deqDelay_{m.group(1)}_valid)' if m else 'cmp_all || warm'
        L.append(f'      chk("{n}", g_{n}, i_{n}, {gate});')
    # 覆盖
    L.append('      if ((io_enq_0_valid && g_io_enq_0_ready) || (io_enq_1_valid && g_io_enq_1_ready)) cov_enq_fire++;')
    L.append('      if (io_flush_valid) cov_flush++;')
    for d in range(ND):
        lo_s, lo_c = P['N_ENQ'], P['N_ENQ'] + P['N_SIMP']
        L.append(f'      if (u_g.deqBeforeDly_{d}_valid) begin')
        L.append(f'        cov_deq{d}++;')
        L.append(f'        if (|u_g.deqBeforeDly_{d}_bits_addrOH[{N - 1}:{lo_c}]) cov_sel_comp++;')
        L.append(f'        else if (|u_g.deqBeforeDly_{d}_bits_addrOH[{lo_c - 1}:{lo_s}]) cov_sel_simp++;')
        L.append('        else cov_sel_enq++;')
        L.append('      end')
        if has_cancel:
            L.append(f'      if (u_g.deqSelValidVec_{d} && !u_g.deqBeforeDly_{d}_valid) cov_cancel_deq++;')
        L.append(f'      if (g_io_deqDelay_{d}_valid && !io_deqDelay_{d}_ready) cov_dly_not_ready++;')
    if has_mwq:
        L.append('      if (g_io_wakeupToIQ_0_valid) cov_wk_out++;')
    L.append('    end')
    L.append('  end')
    L.append('')
    L.append('  initial begin')
    L.append('    int bad;')
    L.append('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    L.append('    if ($test$plusargs("cmp_all")) cmp_all = 1;')
    L.append('    reset = 1; repeat (5) @(posedge clock); @(negedge clock); reset = 0;')
    L.append('    repeat (NCYCLES) @(posedge clock);')
    L.append('    bad = (errors != 0);')
    L.append('    if (!warm && !cmp_all) begin bad = 1; $display("*** 条目阵列没有全部被写过，随机初值档无法比对"); end')
    for k in cov:
        L.append(f'    $display("  cov %-14s = %0d", "{k}", cov_{k});')
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
    mods = []
    for m, _, _ in c.insts:
        if m not in mods:
            mods.append(m)
    # 子模块在 golden 里自己的依赖（Entries 的 EnqEntry/OthersEntry…、MWQ 的 PipeWithFlush…）
    def gdeps(m, acc):
        _, body = gen_iq.module_text(m)
        for sub in re.findall(r'^  ([A-Z]\w*) \w+ \($', body, re.M):
            if sub not in acc:
                acc.append(sub)
                gdeps(sub, acc)
        return acc
    gold = []
    for m in mods:
        if m not in gold:
            gold.append(m)
        for s in gdeps(m, []):
            if s not in gold:
                gold.append(s)
    impl = rtl_closure(v)
    vm = ('\n# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/' + v + '.tcl\n'
          'FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true\n') \
        if (REPO / 'verif' / 'fm_target_config' / f'{v}.tcl').exists() else ''
    rtl_list = (' \\\n' + ' ' * 11).join('$(RTL_DIR)/' + x for x in impl)
    return f'''MODULE = {v}

# {v}（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   {' '.join(gold)}
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = {rtl_list}
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/{v}.sv {' '.join('$(GOLDEN_RTL)/' + g + '.sv' for g in gold)}

FM_VARIANTS = {v}
FM_REF_DEPS_{v} = {' '.join(g + '.sv' for g in gold)}

FM_MERGE_DUP = false
{vm}
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
'''


_MODIDX = None


def rtl_closure(v):
    """impl 侧文件闭包：从 wrapper 出发，按例化关系在 rtl/ 里传递地找声明文件（机械，不手列）。"""
    global _MODIDX
    if _MODIDX is None:
        _MODIDX = {}
        for f in sorted((REPO / 'rtl').rglob('*.sv')):
            for m in re.findall(r'^module\s+(\w+)', f.read_text(errors='replace'), re.M):
                _MODIDX.setdefault(m, f.relative_to(REPO / 'rtl').as_posix())
    order, todo = [], [v]
    while todo:
        m = todo.pop(0)
        f = _MODIDX.get(m)
        if f is None:
            raise SystemExit(f'gen_tb: rtl/ 里找不到模块 {m}')
        if f in order:
            continue
        order.append(f)
        txt = (REPO / 'rtl' / f).read_text()
        for sub in re.findall(r'^\s*(\w+)\s+(?:#\s*\(.*?\)\s*)?\w+\s*\(', txt, re.M | re.S):
            if sub in _MODIDX and sub not in ('module',) and _MODIDX[sub] not in order:
                todo.append(sub)
    return order


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
                print(f'gen_tb --check: {p} 不一致'); bad = 1
        else:
            d.mkdir(parents=True, exist_ok=True)
            p.write_text(t)
            print(f'gen_tb: 写 {p}')
    if a.check and not bad:
        print(f'gen_tb --check: {a.variant} OK')
    return bad


if __name__ == '__main__':
    sys.exit(main())
