#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— TLBNonBlock 家族 UT / 覆盖闸的判别力负测（`make mutants`）。

`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。家族三个变体共用一个核
（rtl/memblock/xs_TLBNonBlock_core.sv），所以变异全部注入核，一次注入就同时考验
三个变体的双例化比对；表里每条自己声明在哪个变体上跑（有些锥体只在某个变体里存在）。

★闸的负测是双向的（CONVENTIONS）★，本文件三个方向都做：
  1. 该报警时报警：注入真 bug，要求 errors > 0；
  2. 不该报警时不报警：先跑未变异基线，要求 errors=0 且 bad_cov=0。基线不绿就
     直接退出 —— 注入后的红证明不了是注入造成的；
  3. 覆盖闸自己也要考（`--cov`）：用短到不可能跑满覆盖的拍数跑**未变异**基线，
     要求它判 TEST FAILED。一个永远绿的覆盖闸能通过第 1 条，只有这一项能逼出来。

★"变异体必须先自证改变了电路"（任务书硬要求）在本文件的落地★
  · 注入点是**精确唯一**的整行文本；`old` 在文件里出现次数不等于 1、或替换后文本
    没变，一律判 FAIL（`apply_mutant`）。保证 RTL 文本真的变了。
  · 文本变了**不等于**电路变了。本表里唯一一条文本变而电路不变的，是 E1：它把
    M7 的同一处改动打在**变体 _1** 上，而 _1 的 HAS_TLBREPLAY=0，整条 tlbreplay
    锥体被 generate 关掉（golden TLBNonBlock_1 根本没有 io_tlbreplay_* 端口，实测
    自 G1 端口表）。E1 **不计入抓取率**，它在这里的唯一作用是反过来证明：本
    harness 不会把"改了文本"当成"抓到了"。同一处改动在变体 base 上是 M7，必须红。
  · E2 是另一类：**不是逻辑等价**，而是 UT 结构上看不见（复位域），由 FM 兜底。
    tb 的 reset 拉满整拍，异步复位与同步复位在 UT 里同行为。它也不计入抓取率，
    但它有归属：`--fm` 模式把同一条打给 FM，要求 FM 判不等价。

  三条防"读到上一轮结果"的构造：
  1) 每个变异体在 neg_build/ 里**重新编译**，跑之前先删本轮日志；
  2) 编译或运行没产出日志一律判 FAIL，不继续；
  3) 抓到与否用 errors 数判，不是用退出码（Makefile 的退出码还受覆盖闸影响）。

用法:
    python3 mutants.py                  # UT 判别力（默认 60k 拍）
    python3 mutants.py --cov            # 覆盖闸自身的负测
    python3 mutants.py --fm             # FM 侧负测（只有 FM 看得见的复位域变异）
    python3 mutants.py --compile-only   # 只查锚点唯一性与可编译
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTLREL = pathlib.Path('rtl') / 'memblock'
MODULE = 'TLBNonBlock'
MUTFILE = 'xs_TLBNonBlock_core.sv'        # 家族三变体共用的核
NCYCLES = '60000'
FM_TOP = 'TLBNonBlock_2'                  # FM 负测用家族最小的一个（2286 行）

RTL_FILES = [MUTFILE, 'TLBNonBlock.sv', 'TLBNonBlock_1.sv', 'TLBNonBlock_2.sv']
UT_FILES = ['Makefile', 'gen_tb.py', 'tb.sv', 'tb_1.sv', 'tb_2.sv']

# 变体后缀 -> make 目标后缀（base 是空串）
VAR_BASE, VAR_1, VAR_2 = '', '1', '2'

# (期望, 变体, 说明, 锚点, 替换)
#   CATCH   真 bug，UT 必须报（errors > 0）
#   EQUIV   ★文本变了但电路没变★，UT 必须 errors == 0，且**不计入抓取率**
#   MISS_FM UT 结构上看不见、归 FM 管，UT 必须 errors == 0，**不计入抓取率**
MUTANTS = [
    ('CATCH', VAR_BASE,
     'M1 s1_hit 的 NAPOT tag 切片少取一位（★本轮实际抓到的那个真 bug，原样回放★）',
     "    tm[0]      = k.s1_n ? (k.s1_tag[VPNN_W-1-SECT_W : NAPOT_W-SECT_W] == vpn[VPNN_W-1:NAPOT_W])",
     "    tm[0]      = k.s1_n ? (k.s1_tag[SECT_W+1:1] == vpn[VPNN_W-1:NAPOT_W])"),

    ('CATCH', VAR_BASE,
     'M2 level_match 在 level==1 时少比一段 vpnn（超页命中范围被放大）',
     "         : (level == 2'h1) ? (tm[3] & tm[2] & tm[1])",
     "         : (level == 2'h1) ? (tm[3] & tm[2])"),

    ('CATCH', VAR_BASE,
     'M3 s1_hit 去掉 sector 的 valididx 那一项（非超页时逐页有效位不再管用）',
     "    return asid_hit & level_match(k.s1_level, tm)\n"
     "           & (super_page | k.s1_valididx[vpn[SECT_W-1:0]]);",
     "    return asid_hit & level_match(k.s1_level, tm);"),

    ('CATCH', VAR_BASE,
     'M4 s2_hit 去掉 vmid 比较（别的客户机的 G-stage 表项也算命中）',
     "    return ({2'h0, k.s2_vmid} == vmid) & level_match(k.s2_level, tm);",
     "    return level_match(k.s2_level, tm);"),

    ('CATCH', VAR_BASE,
     'M5 all_s1_hit 的页大小取大的那一级（golden 取小的：页大小以小的为准）',
     "    level       = ((k.s2xlate == ONLY_S1) | (k.s1_level < k.s2_level)) ? k.s1_level : k.s2_level;",
     "    level       = ((k.s2xlate == ONLY_S1) | (k.s1_level > k.s2_level)) ? k.s1_level : k.s2_level;"),

    ('CATCH', VAR_BASE,
     'M6 ptw_req_valid 去掉 need_gpa 抑制项（need_gpa 期间别的 lane 也去发 PTW 请求）',
     "        & ~(ptw_just_back[i] | ptw_already_back[i] | need_replay[i])\n"
     "        & ~(need_gpa & ~need_gpa_match_ptw[i] & ~resp_gpa_refill);",
     "        & ~(ptw_just_back[i] | ptw_already_back[i] | need_replay[i]);"),

    ('CATCH', VAR_BASE,
     'M7 tlbreplay 去掉 need_replay 项（拿不到 gpaddr 的那条不再叫请求方重来）',
     "              & ((ptw_just_back[i] | ptw_already_back[i] | need_replay[i])",
     "              & ((ptw_just_back[i] | ptw_already_back[i])"),

    ('CATCH', VAR_BASE,
     'M8 need_gpa 状态机把 clear_gpa / want_gpa 的优先级对调（golden 是 clear 先）',
     "      if (clear_gpa[i]) begin",
     "      if (clear_gpa[i] & ~want_gpa[i]) begin"),

    ('CATCH', VAR_BASE,
     'M9 entries 回填去掉 ~need_gpa_wire（本拍刚抢到 need_gpa 的那条也照写不误）',
     "  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa & ~need_gpa_wire\n"
     "                        & ~flush_mmu;",
     "  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa\n"
     "                        & ~flush_mmu;"),

    ('CATCH', VAR_BASE,
     'M10 PMP 地址忽略 no_translate（请求方直接给的物理地址被译出来的盖掉）',
     "    assign pmp_addr[i]  = no_translate_r[i] ? req_pmp_addr[i] : resp_paddr[i][0];",
     "    assign pmp_addr[i]  = resp_paddr[i][0];"),

    ('CATCH', VAR_BASE,
     'M11 PMP 特权模式去掉 is_prefetch 项（预取请求被按 hypervisor 的 spvp 降级）',
     "    assign pmp_mode[i]  = (req_out_is_prefetch[i] | ~is_hyper_inst[i]) ? mode_base : mode_hyp;",
     "    assign pmp_mode[i]  = (~is_hyper_inst[i]) ? mode_base : mode_hyp;"),

    ('CATCH', VAR_BASE,
     'M12 has_gpf 去掉 hit_read 门控（没命中也说"命中了却报 gpf"）',
     "    assign has_gpf[i] = hit_read[i]\n"
     "                        & (excp_gpf_ld[i][0] | excp_gpf_st[i][0] | excp_gpf_instr[i][0]);",
     "    assign has_gpf[i] =\n"
     "                          (excp_gpf_ld[i][0] | excp_gpf_st[i][0] | excp_gpf_instr[i][0]);"),

    ('CATCH', VAR_BASE,
     'M13 want_gpa 去掉 ~req_out_is_prefetch（预取也去要 gpaddr）',
     "                       & has_gpf[i] & ~need_gpa & ~req_kill[i] & ~req_out_is_prefetch[i]",
     "                       & has_gpf[i] & ~need_gpa & ~req_kill[i]"),

    ('CATCH', VAR_1,
     'M14 = M1 打在变体 _1 上（同一处真 bug，证明三个变体共用的核一改全红）',
     "    tm[0]      = k.s1_n ? (k.s1_tag[VPNN_W-1-SECT_W : NAPOT_W-SECT_W] == vpn[VPNN_W-1:NAPOT_W])",
     "    tm[0]      = k.s1_n ? (k.s1_tag[SECT_W+1:1] == vpn[VPNN_W-1:NAPOT_W])"),

    ('CATCH', VAR_1,
     'M15 被 gate 掉的 hlvx 常量写成 1（考的是"缺输入端口"那一族 mask 的下游影响：'
     '_1 两条 lane 都没有 hlvx 输入，常量一改 pmp_cmd 就会变成 CMD_RX）',
     "      always_comb req_out_hlvx[i] = 1'b0;",
     "      always_comb req_out_hlvx[i] = 1'b1;"),

    ('CATCH', VAR_BASE,
     'M16 逐 lane mask 用错下标（HAS_PRE_EXCP 取 lane0 那一位当全体）—— 模拟'
     '"掩码接线接错"这一类错误',
     "    if (HAS_PRE_EXCP[i]) begin : g_pre_excp",
     "    if (HAS_PRE_EXCP[0]) begin : g_pre_excp"),

    # ---- 下面两条不计入抓取率，理由见文件头 ----
    ('EQUIV', VAR_1,
     'E1 = M7 打在变体 _1 上：_1 的 HAS_TLBREPLAY=0，整条 tlbreplay 锥体被 generate '
     '关掉（golden TLBNonBlock_1 没有 io_tlbreplay_* 端口）—— 文本变了电路没变，'
     '★空变异，不算漏检★',
     "              & ((ptw_just_back[i] | ptw_already_back[i] | need_replay[i])",
     "              & ((ptw_just_back[i] | ptw_already_back[i])"),

    ('MISS_FM', VAR_BASE,
     'E2 need_gpa 那组寄存器的异步复位改同步复位 —— UT 结构上看不见（tb 的 reset '
     '拉满整拍，两种写法同行为），归 FM；`--fm` 那一侧有对应条目',
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset) begin\n"
     "      need_gpa              <= 1'b0;",
     "  always_ff @(posedge clock) begin\n"
     "    if (reset) begin\n"
     "      need_gpa              <= 1'b0;"),
]

# FM 侧负测：(说明, 锚点, 替换, 期望 FM 判不等价)
FM_MUTANTS = [
    ('F1 need_gpa 复位域：异步改同步（★UT 结构上看不见，归 FM★，对应 UT 表的 E2）',
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset) begin\n"
     "      need_gpa              <= 1'b0;",
     "  always_ff @(posedge clock) begin\n"
     "    if (reset) begin\n"
     "      need_gpa              <= 1'b0;",
     True),

    ('F2 s1_hit 的 NAPOT tag 切片少一位（正对照：UT 抓得到的，FM 也必须抓到）',
     "    tm[0]      = k.s1_n ? (k.s1_tag[VPNN_W-1-SECT_W : NAPOT_W-SECT_W] == vpn[VPNN_W-1:NAPOT_W])",
     "    tm[0]      = k.s1_n ? (k.s1_tag[SECT_W+1:1] == vpn[VPNN_W-1:NAPOT_W])",
     True),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / RTLREL).mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / MODULE).mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in UT_FILES:
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / MODULE / f)


def restore():
    for f in RTL_FILES:
        shutil.copy(REPO / RTLREL / f, BUILD / RTLREL / f)


def apply_mutant(tgt, base_text, old, new):
    """锚点必须**恰好出现一次**且替换后文本确实变了 —— 否则算这条变异没生效。"""
    if base_text.count(old) != 1:
        return False
    t = base_text.replace(old, new, 1)
    if t == base_text:
        return False
    tgt.write_text(t)
    return True


def run_ut(variant, ncycles=NCYCLES):
    """跑一轮某个变体的 UT。★每次先删本轮日志★，编译失败时读不到旧日志。"""
    ut = BUILD / 'verif' / 'ut' / MODULE
    log = ut / ('sim%s_1.log' % variant)
    if log.exists():
        log.unlink()
    r = subprocess.run(['make', 'run' + variant, 'SEED=1', 'NCYCLES=' + str(ncycles)],
                       cwd=str(ut), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                       universal_newlines=True)
    if not log.exists():
        return (None, r.returncode, r.stdout[-2000:])
    txt = log.read_text(errors='replace')
    m = re.search(r'checks=(\d+) errors=(\d+) bad_cov=(\d+)', txt)
    if not m:
        return (None, r.returncode, txt[-2000:])
    return ((int(m.group(1)), int(m.group(2)), int(m.group(3)), 'TEST PASSED' in txt),
            r.returncode, '')


def run_fm():
    """在 neg_build 里跑一次 FM，返回 (native_verdict, failing 数)。"""
    ut = BUILD / 'verif' / 'ut' / MODULE
    log = ut / 'fm_work' / FM_TOP / 'fm.log'
    if log.exists():
        log.unlink()
    subprocess.run(['make', 'fm-' + FM_TOP], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    if not log.exists():
        return (None, None)
    txt = log.read_text(errors='replace')
    # ★判据钉在行首★：fm_shell 把入口 Tcl 逐行回显进 fm.log，裸子串 "SUCCEEDED" /
    # "FAILED" 在任何一次跑里都能同时命中（脚本自己的 puts 里两种都写着）。
    m = re.search(r'^Verification (SUCCEEDED|FAILED|INCONCLUSIVE)', txt, re.M)
    mf = re.search(r'^Failing \(not equivalent\)((?:\s+\d+){8})\s*$', txt, re.M)
    return (m.group(1) if m else None,
            int(mf.group(1).split()[-1]) if mf else None)


def baseline(variant=VAR_BASE):
    print('=== 基线（未变异，变体 %s，%s 拍）===' % (MODULE + (('_' + variant) if variant else ''),
                                                    NCYCLES))
    base, rc, tail = run_ut(variant)
    if base is None or base[1] != 0 or base[2] != 0 or not base[3]:
        print('基线不绿（rc=%s, %s），负测无意义：\n%s' % (rc, base, tail))
        return None
    print('    checks=%d errors=%d bad_cov=%d TEST PASSED' % base[:3])
    return base


def main():
    args = sys.argv[1:]
    prepare()
    base_text = (REPO / RTLREL / MUTFILE).read_text()
    tgt = BUILD / RTLREL / MUTFILE
    ut = BUILD / 'verif' / 'ut' / MODULE

    if '--compile-only' in args:
        bad = []
        for _expect, variant, name, old, new in MUTANTS:
            restore()
            if not apply_mutant(tgt, base_text, old, new):
                print('!! %-80s ★锚点不唯一/文本未变★' % name[:80])
                bad.append(name)
                continue
            r = subprocess.run(['make', 'compile' + variant], cwd=str(ut),
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               universal_newlines=True)
            print('  %-80s %s' % (name[:80],
                                  'compiles' if r.returncode == 0 else '★编译失败★'))
            if r.returncode != 0:
                bad.append(name)
        restore()
        print('=== COMPILE-ONLY: %d/%d 可编译 ===' % (len(MUTANTS) - len(bad), len(MUTANTS)))
        return 1 if bad else 0

    if '--cov' in args:
        # 覆盖闸自身的负测：拍数短到跑不满覆盖时，未变异的核也**必须**被判失败。
        if baseline() is None:
            return 2
        res, rc, tail = run_ut(VAR_BASE, ncycles=40)
        if res is None:
            print('!! 40 拍那轮没有产生日志（rc=%s）：\n%s' % (rc, tail))
            return 1
        print('=== 覆盖闸负测：40 拍（未变异）===')
        print('    checks=%d errors=%d bad_cov=%d TEST %s'
              % (res[0], res[1], res[2], 'PASSED' if res[3] else 'FAILED'))
        restore()
        if res[1] == 0 and res[2] > 0 and not res[3]:
            print('=== COV-NEG PASSED：errors=0 但覆盖不全，闸照样判 FAILED ===')
            return 0
        print('=== COV-NEG FAILED：覆盖闸没有独立发挥作用 ===')
        return 1

    if '--fm' in args:
        print('=== FM 基线（未变异，top=%s）===' % FM_TOP)
        v, f = run_fm()
        print('    native=%s failing=%s' % (v, f))
        if v != 'SUCCEEDED' or f != 0:
            print('FM 基线就不干净，负测无意义')
            return 2
        bad = []
        for name, old, new, expect_fail in FM_MUTANTS:
            restore()
            if not apply_mutant(tgt, base_text, old, new):
                print('!! %-76s ★锚点不唯一/文本未变★' % name[:76])
                bad.append(name)
                continue
            v, f = run_fm()
            ok = (v != 'SUCCEEDED' or (f or 0) > 0) if expect_fail else \
                 (v == 'SUCCEEDED' and f == 0)
            print('  %-76s native=%-12s failing=%-5s %s'
                  % (name[:76], v, f, 'OK' if ok else '★不符预期★'))
            if not ok:
                bad.append(name)
        restore()
        if bad:
            print('=== FM-NEG FAILED ===')
            for x in bad:
                print('   ', x)
            return 1
        print('=== FM-NEG PASSED：%d/%d 条 ===' % (len(FM_MUTANTS), len(FM_MUTANTS)))
        return 0

    # 每个用到的变体各跑一次基线
    for variant in sorted({m[1] for m in MUTANTS}):
        if baseline(variant) is None:
            return 2
    bad = []
    for expect, variant, name, old, new in MUTANTS:
        restore()
        if not apply_mutant(tgt, base_text, old, new):
            print('!! %-80s ★锚点不唯一/文本未变★' % name[:80])
            bad.append(name)
            continue
        res, rc, tail = run_ut(variant)
        if res is None:
            print('!! %-76s ★没有本轮日志（编译/运行失败 rc=%s），判 FAIL★' % (name[:76], rc))
            bad.append(name)
            continue
        if expect == 'CATCH':
            ok = res[1] > 0
            tag = 'CAUGHT' if ok else '★MISSED★'
        elif expect == 'EQUIV':
            ok = res[1] == 0
            tag = ('EQUIV-ok（空变异，电路没变，不计抓取率）' if ok
                   else '★居然报了 —— 说明这条"等价"的理由是错的★')
        else:
            ok = res[1] == 0
            tag = ('MISS_FM-ok（UT 看不见，归 FM；见 --fm 的 F1）' if ok
                   else '★居然报了 —— 说明这条注释是错的★')
        print('  [%-7s %-5s] %-62s errors=%-9d %s'
              % (expect, MODULE + (('_' + variant) if variant else ''), name[:62],
                 res[1], tag))
        if not ok:
            bad.append(name)
    restore()
    if bad:
        print('=== MUTANTS FAILED：以下条目与预期不符（或根本没生效）===')
        for x in bad:
            print('   ', x)
        return 1
    ncatch = sum(1 for e, *_ in MUTANTS if e == 'CATCH')
    print('=== MUTANTS PASSED：%d/%d 条符合预期（抓取率 %d/%d；另有 %d 条不计入：'
          'EQUIV 空变异 + MISS_FM 归 FM）==='
          % (len(MUTANTS), len(MUTANTS), ncatch, ncatch, len(MUTANTS) - ncatch))
    return 0


if __name__ == '__main__':
    sys.exit(main())
