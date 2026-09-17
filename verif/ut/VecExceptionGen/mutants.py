#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— VecExceptionGen UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只在「注入真 bug 时 UT 会红」的前提下才有意义。本模块
是一张纯组合的译码表，最容易「看着在验、其实没验」——32 位指令字均匀随机时，
落进任何一条向量编码的概率约 1e-4，200k 拍下来每条指令平均命中不到 1 次。

做法：把 rtl/ 与本目录复制进 neg_build/（已 gitignore，**变异不进库**），
逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来（errors > 0）。
本文件分两类变异：

**MUTANTS —— 必须被抓到**（13 条），对准本模块真实容易写错的地方：
  - M1  vd 区间上界的 5 位截断（写宽一位就不回绕了）；
  - M2~M6 把 `<=` 写成 `<`/`==`、`>` 写成 `>=` 这类差一错误；
  - M7  把 vstart 判据的作用域从「向量算术」放大到「向量算术+访存」；
  - M8  漏掉 vmsbf/vmsif/vmsof 的 v0 重叠例外；
  - M9  在**生成区**删掉一条指令（VLE64FF_V），检验「按指令池打激励」确实
        能分辨单条指令的归类错误；
  - M10 把 wrapper 的 vs1/vs2 两路 srcType 接反（端口 lint 看不见这种错）；
  - M11 把 BitPat 的 `b?01` 抄成 `b001`（丢掉那个无关位）；
  - M12 vd 的 EEW 在加宽指令上漏 +1；
  - M13 NFtoLmul 取错指令域（vmv<N>r.v 的 nf 在 inst[19:15] 而不是 inst[31:29]）。

**EXPECTED_MISSED —— 预期抓不到，且必须抓不到**（3 条）。
第一轮负测实测发现有三条变异 UT 抓不到。追下去发现不是激励不够，而是它们在
**输出上不可观测**（论证逐条写在 EXPECTED_MISSED 里）。把它们留在这里，
是把论证钉成可复跑的断言：哪天被抓到了，说明论证被推翻，脚本报失败。
★这同时更正了 RTL 文件头一开始的说法★：那里原本写「照字面统一成一种就是真
bug」，实测不成立 —— 已改。

★同样重要：报告每个变异的 errors 数★。余量薄的（errors 只有几十）换个 seed
就可能漏，下面的输出逐个列出，不要读成「判别力均匀」。

用法: python3 mutants.py      （或 make mutants）
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTL = ['VecExceptionGen.sv']
NCYCLES = '200000'

MUTANTS = [
    # ★这条变异本身返工过一次，留个记号★：第一版写成
    #   `wire [4:0] vd_reg_hi_arith = 5'(...8 位算式...)`
    # —— 目标线仍是 5 位、外面又套了一层 5'()，等于**什么都没改**，于是「抓不到」。
    # 真正要动的是 vd_reg_hi 这一侧：让它直接用 8 位算式，绕过 5 位中间量。
    # 教训：变异必须自己先确认「确实改变了电路」，否则 MISSED 是假的。
    ('M1 vd 上界不做 5 位截断（vd+2^EMUL-1 ≥ 32 时不再回绕）',
     "  wire [7:0] vd_reg_hi = (is_ls_stride | is_ls_index) ? (seg_regmax - 8'd1)\n"
     "                                                     : {3'b0, vd_reg_hi_arith};",
     "  wire [7:0] vd_reg_hi = (is_ls_stride | is_ls_index) ? (seg_regmax - 8'd1)\n"
     "                       : ({3'b0, fld_vd} + {4'b0, lmul_to_regnum(vd_emul)} - 8'd1);"),
    ('M2 vsext/vzext.vf4 的 EEW 判据 `SEW<=1` 写成 `SEW==1`',
     "| (is_int_ext4 & (vsew <= 2'd1))",
     "| (is_int_ext4 & (vsew == 2'd1))"),
    ('M3 vsext/vzext.vf8 的 EMUL 判据 `LMUL<=3` 写成 `LMUL<3`',
     "| (is_int_ext8 & (lmul <= 3'd3))",
     "| (is_int_ext8 & (lmul < 3'd3))"),
    ('M4 访存 EMUL 上界 `>` 写成 `>=`',
     "| (ls_emul > (sew_z4 + 4'd7)));",
     "| (ls_emul >= (sew_z4 + 4'd7)));"),
    ('M5 段访存寄存器总数上界 `>8` 写成 `>=8`',
     "& ((seg_regnum > 7'd8) | (seg_regmax > 8'd32));",
     "& ((seg_regnum >= 7'd8) | (seg_regmax > 8'd32));"),
    ('M6 重叠例外 3 的 `EMUL>=1`（编码>=4）写成 `>=2`（编码>=5）',
     "& (vs1_emul >= 4'd4) & (vd_reg_hi == {2'b0, vs1_reg_hi})",
     "& (vs1_emul >= 4'd5) & (vd_reg_hi == {2'b0, vs1_reg_hi})"),
    ('M7 vstart 判据作用域扩大到向量访存（应只管向量算术）',
     "wire vstart_illegal = is_varith & (|vstart);",
     "wire vstart_illegal = is_varith_mem & (|vstart);"),
    ('M8 漏掉 vmsbf/vmsif/vmsof 的 v0 重叠例外',
     "wire v0_allow_overlap = (vd_is_mask | vd_is_single) & ~is_mask_set;",
     "wire v0_allow_overlap = (vd_is_mask | vd_is_single);"),
    ('M9 指令池里删掉一条 VLE64FF_V（生成区：单条指令归类错）',
     "    | bitpat_match(inst, 32'h1DF0707F, 32'h01007007);  // VLE64FF_V",
     "    | 1'b0;  // VLE64FF_V"),
    ('M10 wrapper 把 vs1/vs2 两路 srcType 接反',
     "    .src_type_vs1  (io_decodedInst_srcType_0),\n"
     "    .src_type_vs2  (io_decodedInst_srcType_1),",
     "    .src_type_vs1  (io_decodedInst_srcType_1),\n"
     "    .src_type_vs2  (io_decodedInst_srcType_0),"),
    ('M11 浮点判据把 BitPat 的 `b?01` 抄成 `b001`（丢掉那个无关位）',
     "wire is_fp_arith   = (inst[13:12] == 2'b01) & (inst[6:0] == 7'h57);",
     "wire is_fp_arith   = (inst[14:12] == 3'b001) & (inst[6:0] == 7'h57);"),
    ('M12 vd 的 EEW 在加宽指令上漏了 +1',
     "                          : (is_vd_widening | is_red_widening) ? (vsew + 2'd1) : vsew;",
     "                          : (is_vd_widening | is_red_widening) ? vsew : vsew;"),
    ('M13 vs2Emul 的 NFtoLmul 取错域（vmv<N>r.v 的 nf 在 inst[19:15]，不是 inst[31:29]）',
     "(vs2_emul_sel == 4'h2) ? {1'b0, nf_to_lmul(fld_vs1[2:0])} :",
     "(vs2_emul_sel == 4'h2) ? {1'b0, nf_to_lmul(fld_nf)}       :"),
]

# ★预期抓不到的变异★：这三条是**真的**改了 RTL，但在输出上不可观测。
# 它们留在这里不是为了「凑数」，而是把「为什么抓不到」的论证钉成可复跑的断言：
# 哪天它们被抓到了，说明下面的论证被推翻（Chisel 上游改了、或者论证本身错了），
# 脚本会当成失败报出来。
EXPECTED_MISSED = [
    ('X1 vs2Emul 的 LMUL+1 不做 3 位截断（照 `+&` 写）',
     "(vs2_emul_sel == 4'h4) ? {1'b0, lmul_p1[2:0]}          :",
     "(vs2_emul_sel == 4'h4) ? lmul_p1                       :",
     'sel==4\'h4 ⟺ vs2 宽源或收窄；这两类指令都在 vd 加宽/收窄清单里，'
     '而两种写法只在 LMUL=7 时取值不同，那时 wn_emul_ill 已把输出拉到 1。'),
    ('X2 vs1Emul 的 gather 支做了 3 位截断（照普通 `+` 写）',
     ": is_vrgather16 ? (lmul_p1 - sew_z4)   // \u26054 \u4f4d,\u4e0d\u622a\u65ad\u2605",
     ": is_vrgather16 ? {1'b0, 3'(lmul_p1 - sew_z4)}",
     '两种写法只在 lmul_p1 < sew（即 LMUL < SEW）时取值不同，'
     '而那正是 gather16_emul_ill 的触发条件，输出已恒为 1。'),
    ('X3 NFtoLmul 的「不命中得 0」改成 4',
     "(nf == 3'd7) ? 3'd7 : 3'd0;",
     "(nf == 3'd7) ? 3'd7 : 3'd4;",
     'NFtoLmul 只被 vmv<N>r.v 与整寄存器访存两类调用，而这两类的 BitPat 把 nf 域'
     '钉成 care 位，取值只能是 0/1/3/7 —— 默认分支不可达。'),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'VecExceptionGen').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'VecExceptionGen' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'VecExceptionGen'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    txt = log.read_text()
    m = re.search(r'TEST (?:PASSED|FAILED) errors=(\d+) \(checks=(\d+)\)', txt)
    if m:
        return (int(m.group(2)), int(m.group(1)))
    m = re.search(r'TEST PASSED \(checks=(\d+)\)', txt)
    return (int(m.group(1)), 0) if m else None


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
        tgt = BUILD / 'rtl' / 'backend' / 'VecExceptionGen.sv'
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
        print('  %-52s checks=%d errors=%-8d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)
    print('=== 预期抓不到的变异（论证见本文件 EXPECTED_MISSED）===')
    unexpected = []
    for name, old, new, why in EXPECTED_MISSED:
        restore()
        tgt = BUILD / 'rtl' / 'backend' / 'VecExceptionGen.sv'
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到' % name)
            unexpected.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败' % name)
            unexpected.append(name)
            continue
        ok = (res[1] == 0)
        print('  %-52s checks=%d errors=%-8d %s'
              % (name, res[0], res[1], 'MISSED(\u5982\u9884\u671f)' if ok else '\u2605UNEXPECTEDLY CAUGHT\u2605'))
        print('        \u8bba\u8bc1\uff1a%s' % why)
        if not ok:
            unexpected.append(name)
    restore()
    rc = 0
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        rc = 1
    else:
        print('=== %d/%d 个「应当抓到」的变异全部被 UT 抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    if unexpected:
        print('=== 论证被推翻：以下「预期抓不到」的变异竟然被抓到了 ===')
        for m in unexpected:
            print('   ', m)
        rc = 1
    else:
        print('=== %d/%d 个「预期抓不到」的变异确实没被抓到（论证成立）==='
              % (len(EXPECTED_MISSED), len(EXPECTED_MISSED)))
    return rc


if __name__ == '__main__':
    sys.exit(main())
