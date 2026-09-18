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
  · MISS_STIM（M2 / M8 / M9）是第三类：**立项时按 CATCH 写，被实测推翻**。
    它们既不是等价、也不是"UT 结构上看不见"，而是**这套激励区分不出来**
    （20k 与 200k 两轮都 errors=0，两个数都在各自条目里记着）。
    每条都写清了"为什么这套激励碰不到"以及"要抓它得把激励改成什么样"，
    并在 `--fm` 里有对应的 F3/F4/F5 —— 它们不是等价变异，所以 FM 必须判不等价。
    ★这一类不许悄悄删掉，也不许改成 EQUIV★：改成 EQUIV 就是把"没测到"说成"不用测"。

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
import json
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

    ('MISS_STIM', VAR_BASE,
     'M2 level_match 在 level==1 时少比一段 vpnn（超页命中范围被放大）。★立项按 CATCH 写，被实测推翻（20k 与 200k 两轮都 errors=0）★。原因是激励的区分度不够、不是拍数不够：tm[1] 比的是 vpn[17:9]，而 vpn 池是 8 个**互相独立的随机 38 位数**，两条不同的 vpn 在 [37:18] 上相同的概率约 2^-20 —— 也就是说 level==1 时去掉 tm[1]，命中判定的结果几乎永远不变。要抓它得把 vpn 池改成**近邻**（高位段相同、只差某一段低位）。归 FM，见 --fm 的 F3',
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

    ('MISS_STIM', VAR_BASE,
     'M8 need_gpa 状态机把 clear_gpa / want_gpa 的优先级对调（golden 是 clear 先）。★立项按 CATCH 写，被实测推翻（20k 与 200k 两轮都 errors=0）★。clear_gpa 与 want_gpa 同拍为真才有区别：clear_gpa 的三项里，need_gpa_robidx_valid 与 need_gpa 基本同进同出，而 want_gpa 要求 ~need_gpa。唯一的缝是 second_clear 只清 need_gpa 不清 need_gpa_robidx_valid —— 随机激励 200k 拍没撞上。**不是等价**（那条缝真实存在），所以归 FM，见 --fm 的 F4',
     "      if (clear_gpa[i]) begin",
     "      if (clear_gpa[i] & ~want_gpa[i]) begin"),

    ('MISS_STIM', VAR_BASE,
     'M9 entries 回填去掉 ~need_gpa_wire（本拍刚抢到 need_gpa 的那条也照写不误）。★立项按 CATCH 写，被实测推翻（20k 与 200k 两轮都 errors=0）★。要 need_gpa_wire 与一次可回填的 ptw_resp 同拍：need_gpa_wire 实测 200k 拍只出现 183 次，还要同时满足 ~get_gpa & ~need_gpa & ~flush_mmu 且这次多写的表项后来真的被查到。**不是等价**，只是概率太低，归 FM，见 --fm 的 F5',
     "  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa & ~need_gpa_wire\n"
     "                        & ~flush_mmu;",
     "  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa\n"
     "                        & ~flush_mmu;"),


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

    ('MISS_FM', VAR_2,
     'M16 逐 lane mask 用错下标（HAS_PRE_EXCP 取 lane0 那一位当全体）。'
     '★这条被自己的实测改过两次，过程比结论有用★：'
     '(1) 一开始放在 base 上按 CATCH 写 —— base 的 HAS_PRE_EXCP 全是 1，[i] 与 [0] 恒等，'
     '    纯空变异，errors=0；'
     '(2) 挪到 _2（HAS_PRE_EXCP=2b01，lane1 那一位会翻）后仍然 errors=0。查清楚了：'
     '    _2 的 lane1 没有 checkfullva 输入（wrapper 灌 0），于是 va_checking[1] 恒 0、'
     '    pre_fault[1] 恒 0 —— 多出来的那组寄存器**值恒为 0**，对输出没有任何影响。'
     '所以它不是功能差异，而是 **compare point 集合**的差异：native FM 也看不见'
     '（failing 恒 0），只有 validator 的 strict unmatched 看得见。'
     '这正是本轮那 18 个 impl-only 点的形状，归 FM 的 F6。',
     "    if (HAS_PRE_EXCP[i]) begin : g_pre_excp",
     "    if (HAS_PRE_EXCP[0]) begin : g_pre_excp"),

    # ---- 下面几条不计入抓取率，理由逐条写在自己身上 ----
    ('EQUIV', VAR_BASE,
     'E0 PMP 地址那个 no_translate 三目运算去掉 —— ★立项时按 CATCH 写，被实测推翻，'
     '查完发现是 golden 自己的恒等冗余★：port_xlate_en 里有 `& ~use_req_s1_paddr`，'
     '而 use_req_s1_paddr 与 no_translate_r 是 golden 写了两遍的同值寄存器。'
     '于是 no_translate_r=1 时 port_xlate_en 必为 0，resp_paddr[0] 走 not_xlate_paddr，'
     '而 not_xlate_paddr 在 use_req_s1_paddr=1 时正好就是 req_pmp_addr —— 两边恒等。'
     'UT 与 FM 都不该报，实测 UT errors=0。',
     "    assign pmp_addr[i]  = no_translate_r[i] ? req_pmp_addr[i] : resp_paddr[i][0];",
     "    assign pmp_addr[i]  = resp_paddr[i][0];"),


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

# FM 侧负测：(说明, 锚点, 替换, 期望被抓, 判据种类)
#   判据种类 'failing'   —— FM 必须判不等价（native FAILED 或 failing>0）
#   判据种类 'unmatched' —— 只改 compare point 集合，native 看不见，
#                           要看 sidecar 的 unmatched.compare_impl > 0
FM_MUTANTS = [
    ('F1 need_gpa 复位域：异步改同步（★UT 结构上看不见，归 FM★，对应 UT 表的 E2）',
     "  always_ff @(posedge clock or posedge reset) begin\n"
     "    if (reset) begin\n"
     "      need_gpa              <= 1'b0;",
     "  always_ff @(posedge clock) begin\n"
     "    if (reset) begin\n"
     "      need_gpa              <= 1'b0;",
     True, 'failing'),

    ('F2 s1_hit 的 NAPOT tag 切片少一位（正对照：UT 抓得到的，FM 也必须抓到）',
     "    tm[0]      = k.s1_n ? (k.s1_tag[VPNN_W-1-SECT_W : NAPOT_W-SECT_W] == vpn[VPNN_W-1:NAPOT_W])",
     "    tm[0]      = k.s1_n ? (k.s1_tag[SECT_W+1:1] == vpn[VPNN_W-1:NAPOT_W])",
     True, 'failing'),

    # 下面三条是 UT 表里的 MISS_STIM：UT 的激励区分不出来（已实测到 200k），
    # 它们不是等价变异，所以**必须**由 FM 兜住。这三条就是那句"归 FM"的兑现。
    ('F3 = UT 的 M2（level_match 在 level==1 时少比一段 vpnn）',
     "         : (level == 2'h1) ? (tm[3] & tm[2] & tm[1])",
     "         : (level == 2'h1) ? (tm[3] & tm[2])",
     True, 'failing'),

    ('F4 = UT 的 M8（need_gpa 状态机 clear_gpa / want_gpa 优先级对调）',
     "      if (clear_gpa[i]) begin",
     "      if (clear_gpa[i] & ~want_gpa[i]) begin",
     True, 'failing'),

    ('F5 = UT 的 M9（entries 回填去掉 ~need_gpa_wire）',
     "  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa & ~need_gpa_wire\n"
     "                        & ~flush_mmu;",
     "  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa\n"
     "                        & ~flush_mmu;",
     True, 'failing'),

    # F6 与上面五条不是同一类：它只改 compare point 集合，不改功能。
    # native FM 的 failing 恒 0，所以判据必须看 unmatched.compare_impl。
    ('F6 = UT 的 M16（HAS_PRE_EXCP 取错下标，_2 的 lane1 多出一组恒 0 的寄存器）',
     "    if (HAS_PRE_EXCP[i]) begin : g_pre_excp",
     "    if (HAS_PRE_EXCP[0]) begin : g_pre_excp",
     True, 'unmatched'),
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


def run_fm(top=None):
    """在 neg_build 里跑一次 FM，返回 (native_verdict, failing 数, impl-only 比较点数)。

    ★为什么要第三个数★：有一类变异（M16/F6）只改 **compare point 集合**、不改功能 ——
    native FM 的 failing 恒 0，看 native 会以为"没抓到"。真正看得见它的是
    sidecar 里的 unmatched.compare_impl（validator 的 strict 判据就读这个）。
    """
    top = top or FM_TOP
    ut = BUILD / 'verif' / 'ut' / MODULE
    log = ut / 'fm_work' / top / 'fm.log'
    nf = ut / 'fm_work' / top / 'sidecar' / 'native_facts.json'
    if log.exists():
        log.unlink()
    if nf.exists():
        nf.unlink()
    subprocess.run(['make', 'fm-' + top], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    if not log.exists():
        return (None, None, None)
    txt = log.read_text(errors='replace')
    # ★判据钉在行首★：fm_shell 把入口 Tcl 逐行回显进 fm.log，裸子串 "SUCCEEDED" /
    # "FAILED" 在任何一次跑里都能同时命中（脚本自己的 puts 里两种都写着）。
    m = re.search(r'^Verification (SUCCEEDED|FAILED|INCONCLUSIVE)', txt, re.M)
    mf = re.search(r'^Failing \(not equivalent\)((?:\s+\d+){8})\s*$', txt, re.M)
    unm = None
    if nf.exists():
        try:
            unm = json.load(open(str(nf)))['unmatched']['compare_impl']
        except Exception:
            unm = None
    return (m.group(1) if m else None,
            int(mf.group(1).split()[-1]) if mf else None,
            unm)


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
        v, f, u = run_fm()
        print('    native=%s failing=%s unmatched_impl=%s' % (v, f, u))
        if v != 'SUCCEEDED' or f != 0 or u not in (0, None):
            print('FM 基线就不干净，负测无意义')
            return 2
        bad = []
        for name, old, new, expect_fail, kind in FM_MUTANTS:
            restore()
            if not apply_mutant(tgt, base_text, old, new):
                print('!! %-70s ★锚点不唯一/文本未变★' % name[:70])
                bad.append(name)
                continue
            v, f, u = run_fm()
            if kind == 'unmatched':
                hit = (u or 0) > 0
            else:
                hit = (v != 'SUCCEEDED' or (f or 0) > 0)
            ok = hit if expect_fail else not hit
            print('  %-70s native=%-11s failing=%-5s unmatched_impl=%-5s %s'
                  % (name[:70], v, f, u, 'OK' if ok else '★不符预期★'))
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
        elif expect == 'MISS_STIM':
            ok = res[1] == 0
            tag = ('MISS_STIM-ok（UT 的激励区分不出来，已实测到 200k；不是等价，归 FM）' if ok
                   else '★居然报了 —— 说明"UT 抓不到"这条结论过期了，把它改回 CATCH★')
        elif expect == 'EQUIV':
            ok = res[1] == 0
            tag = ('EQUIV-ok（空变异，电路没变，不计抓取率）' if ok
                   else '★居然报了 —— 说明这条"等价"的理由是错的★')
        else:
            ok = res[1] == 0
            tag = ('MISS_FM-ok（UT 看不见，归 FM；见 --fm 的 F1 / F6）' if ok
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
    nstim = sum(1 for e, *_ in MUTANTS if e == 'MISS_STIM')
    nequiv = sum(1 for e, *_ in MUTANTS if e == 'EQUIV')
    nfm = sum(1 for e, *_ in MUTANTS if e == 'MISS_FM')
    print('=== MUTANTS PASSED：%d/%d 条与声明相符 ==='
          % (len(MUTANTS), len(MUTANTS)))
    print('    UT 抓取率 %d/%d（CATCH 全部 errors>0）' % (ncatch, ncatch))
    print('    不计入抓取率：EQUIV %d 条（已证空变异）/ MISS_FM %d 条（UT 结构上看不见）'
          ' / MISS_STIM %d 条（激励区分不出来，已实测到 200k，归 FM 的 F3/F4/F5）'
          % (nequiv, nfm, nstim))
    return 0


if __name__ == '__main__':
    sys.exit(main())
