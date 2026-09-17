#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— SSIT UT 的判别力负测（`make mutants`）。

为什么必须有它：本 UT 有**两段暖机**（见 tb.sv 头部），暖机把 1024 项全写成确定值，
天然有把「差异」一起暖掉的风险；而且 SSIT 没有输出端口，比对全靠层次探针——探针
选错地方，errors=0 一样会绿。所以这里逐个注入真 bug，要求每个都被 UT 抓出来。

十个变异分三类：
  * 复位域（M1/M2）：golden 只有 debug_valid 与三个计数/状态寄存器带异步复位。
    多给一个或少给一个，elaborate 与 lint 都不会响，只有这里响。
  * 更新优先级（M3/M4/M5/M9）：写口 0 的「更新赢地址、冲刷输」、写口 1 的同址压制
    到底拿谁的地址比、影子数组「置位压过冲刷清位」。
  * 算法本体（M6/M7/M8/M10）：store-set 的四情形分支、赢家选择、XORFold。
    其中 M8 对着的是 golden 里那处**不对称**（strict 只置 load 那一项）——照
    Chisel 的对称直觉写就会变成 M8。

变异只发生在 neg_build/（已 gitignore），**不进库**。
用法: python3 mutants.py   （或 make mutants）
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTL_REL = pathlib.Path('rtl') / 'backend' / 'SSIT.sv'
NCYCLES = '20000'

# (说明, 锚点, 替换)
MUTANTS = [
    # ★M1 必须写成「把 §9 那个块改成带异步复位」，不能写成「在 §8 的复位臂里
    #   多加一行 debug_ssid <= '0」★：后者让同一个变量被两个 always_ff 块驱动，
    #   VCS 直接 Error-[ICPD] Illegal combination of drivers 拒编 —— 那不是一个
    #   能跑的变体，只能证明编译器会拦，证明不了 UT 有没有判别力。
    #   （2026-09-17 实测踩到：拒编之后 make 停在编译步，旧的 sim_1.log 还在，
    #     harness 把上一次的 errors=0 当成本次结果，报了个假的「逃逸」。
    #     run_ut() 现在每次先删日志、并检查 make 的返回码，这条路已经堵上。）
    ('M1 给 debug_ssid 补上 golden 没有的异步复位',
     "  always_ff @(posedge clock) begin\n    if (s2_valid) begin",
     "  always_ff @(posedge clock or posedge reset) begin\n    if (reset) debug_ssid <= '0;\n    else if (s2_valid) begin"),

    ('M2 去掉 debug_valid 的异步复位（golden 有）',
     "      debug_valid   <= '0;\n      reset_counter <= '0;",
     "      reset_counter <= '0;"),

    ('M3 写口 0 优先级翻转：冲刷地址压过 load 更新',
     "  assign va_waddr_0 = upd_ld_en ? s2_ldpc : (in_flush ? reset_step[PC_W-1:0] : '0);",
     "  assign va_waddr_0 = in_flush ? reset_step[PC_W-1:0] : (upd_ld_en ? s2_ldpc : '0);"),

    ('M4 写口 1 同址压制改用「不含冲刷那一支」的地址比较',
     "  assign va_wen_1   = (va_waddr_0 != va_waddr_1) & upd_st_en;",
     "  assign va_wen_1   = ((upd_ld_en ? s2_ldpc : 10'd0) != va_waddr_1) & upd_st_en;"),

    ('M5 影子 valid：冲刷清位压过更新置位（golden 是置位赢）',
     "        debug_valid[i] <= (s2_valid & wr_hit[i]) | valid_keep[i];",
     "        debug_valid[i] <= ~step_hit[i] & ((s2_valid & wr_hit[i]) | debug_valid[i]);"),

    ('M6 情形 00 的 alloc_ssid 取大者（golden 取小者）',
     "  assign alloc_ssid  = (ld_alloc_ssid < st_alloc_ssid) ? ld_alloc_ssid : st_alloc_ssid;",
     "  assign alloc_ssid  = (ld_alloc_ssid < st_alloc_ssid) ? st_alloc_ssid : ld_alloc_ssid;"),

    ('M7 情形 11 的赢家选反（大 id 胜）',
     "  assign winner_ssid = (s2_load_old_ssid < s2_store_old_ssid) ? s2_load_old_ssid",
     "  assign winner_ssid = (s2_load_old_ssid > s2_store_old_ssid) ? s2_load_old_ssid"),

    ('M8 strict 置到 store 项而不是 load 项（照 Chisel 的对称直觉写就会这样）',
     "        debug_strict[i] <= ((sel == 2'b11) & ssid_is_same & ld_hit[i])",
     "        debug_strict[i] <= ((sel == 2'b11) & ssid_is_same & st_hit[i])"),

    ('M9 四情形分支写错：sel=01 写成写 store 侧',
     "  assign writes_ld = ~s2_load_assigned  | s2_store_assigned;   // sel ∈ {00,01,11}",
     "  assign writes_ld = ~s2_load_assigned  & ~s2_store_assigned;  // sel ∈ {00}"),

    ('M10 XORFold 折错（高低位段取反了顺序以外的错位）',
     "  assign ld_alloc_ssid = s2_ldpc[SSID_W-1:0] ^ s2_ldpc[PC_W-1:SSID_W];",
     "  assign ld_alloc_ssid = s2_ldpc[SSID_W-1:0];"),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'SSIT').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    shutil.copy(REPO / RTL_REL, BUILD / RTL_REL)
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'SSIT' / f)


def restore():
    shutil.copy(REPO / RTL_REL, BUILD / RTL_REL)


def run_ut():
    """跑一次 UT，返回 (checks, errors)；编译或仿真没跑成返回 None。

    ★先删日志再跑★：变异如果让 VCS 拒编，make 会停在编译步，**上一次的
    sim_1.log 原样留在那里**，读它就等于把上一次的结果当成这一次的——
    2026-09-17 实测靠这个假出过一次「逃逸」。
    """
    ut = BUILD / 'verif' / 'ut' / 'SSIT'
    log = ut / 'sim_1.log'
    if log.exists():
        log.unlink()
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    if not log.exists():
        return None
    m = re.search(r'checks=(\d+) errors=(\d+)', log.read_text())
    return (int(m.group(1)), int(m.group(2))) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    checks=%d errors=%d' % base)
    missed = []
    for name, old, new in MUTANTS:
        restore()
        tgt = BUILD / RTL_REL
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到，变异未生效（源码改过？请同步本文件）' % name)
            missed.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败，不算「被抓到」' % name)
            missed.append(name)
            continue
        ok = res[1] > 0
        print('  %-62s checks=%d errors=%-8d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)
    restore()
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被 UT 抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
