#!/usr/bin/env python3
"""mutants.py —— AgeDetector 家族 UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
本模块尤其容易出现"看起来在验、其实没验"——年龄矩阵只在「两口同拍进队」
「canIssue 里有多个候选」这些事件上才分得出对错，激励一旦退化成均匀随机，
整轮 errors=0 什么都不说明。

做法：把 rtl/ 与本目录复制进 neg_build/（已 gitignore，**变异不进库**），
逐个注入一处改动，跑 40k 拍，读 tb 末行的合计 `checks=.. errors=..`。

★两类条目，缺一不可（CONVENTIONS：闸的负测必须双向）★
  CATCH  —— 真 bug，UT 必须报（errors > 0）。
  EQUIV  —— 文本改了、电路**等价**，UT 必须**不报**（errors == 0）。
            它防的是"恒红的 harness"：一个每次都喊 CAUGHT 的负测毫无价值。
            这里选的等价改动是「去掉 age 寄存器的时钟使能」：使能关闭时
            nextAge 的第 (4) 条恰好等于寄存器现值，所以使能是冗余的
            （golden 仍然有这个使能，重写件照抄，不因为它冗余就删——
             见 CONVENTIONS「看起来冗余的结构一份都不许少」）。

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
CORE = 'xs_AgeDetector_core.sv'

# (期望, 说明, 文件, 锚点, 替换)
MUTANTS = [
    ('CATCH', 'M1 同拍多口进队的"更靠前的口"含自身（q<k 写成 q<=k）', CORE,
     "        for (int q = 0; q < k; q++) lower |= io_enq[q][i];",
     "        for (int q = 0; q <= k; q++) lower |= io_enq[q][i];"),
    ('CATCH', 'M2 只有 i 进队时置 1（规则 (2) 应为 0，即新条目比谁都晚）', CORE,
     "        else if (isEnq[i])       nextAge[age_idx(i, j)] = 1'b0;                  // (2)",
     "        else if (isEnq[i])       nextAge[age_idx(i, j)] = 1'b1;                  // (2)"),
    ('CATCH', 'M3 对角线 get_age(i,i) 取 0（golden 是常量 1）', CORE,
     "        else if (i == j) ageFull[i][j] = 1'b1;",
     "        else if (i == j) ageFull[i][j] = 1'b0;"),
    ('CATCH', 'M4 下三角漏取反（get_age(i>j) 应是 !age(j)(i)）', CORE,
     "        else             ageFull[i][j] = ~age[age_idx(j, i)];",
     "        else             ageFull[i][j] = age[age_idx(j, i)];"),
    ('CATCH', 'M5 输出漏掉"自己得是候选"这一项（& canIssue(i)）', CORE,
     "        io_out[d][i] = oldest & io_canIssue[d][i];",
     "        io_out[d][i] = oldest;"),
    ('CATCH', 'M6 复位值取 1（golden 全部 RegInit(false.B)）', CORE,
     "      for (int k = 0; k < NUM_AGE; k++) age[k] <= 1'b0;",
     "      for (int k = 0; k < NUM_AGE; k++) age[k] <= 1'b1;"),
    ('CATCH', 'M7 时钟使能漏掉 j 侧（只有 i 进队才更新）', CORE,
     "          if (isEnq[i] | isEnq[j]) age[age_idx(i, j)] <= nextAge[age_idx(i, j)];",
     "          if (isEnq[i]) age[age_idx(i, j)] <= nextAge[age_idx(i, j)];"),
    ('EQUIV', 'E1 去掉时钟使能（使能关时 nextAge 恰等于现值 ⇒ 电路等价，UT 必须不报）', CORE,
     "          if (isEnq[i] | isEnq[j]) age[age_idx(i, j)] <= nextAge[age_idx(i, j)];",
     "          age[age_idx(i, j)] <= nextAge[age_idx(i, j)];"),
]

RTL = [CORE, 'AgeDetector.sv', 'AgeDetector_1.sv', 'AgeDetector_8.sv',
       'AgeDetector_9.sv', 'AgeDetector_12.sv', 'AgeDetector_13.sv',
       'AgeDetector_15.sv', 'AgeDetector_19.sv', 'AgeDetector_21.sv']
NCYCLES = '40000'


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'AgeDetector').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'AgeDetector' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    """返回 (checks, errors)；编译或运行失败返回 None（make run 每次先删日志，
    所以读不到日志就是这一轮真的没跑出来，不会捡到上一个变异的结果）。"""
    ut = BUILD / 'verif' / 'ut' / 'AgeDetector'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    m = re.search(r'^checks=(\d+) errors=(\d+)', log.read_text(), re.M)
    return (int(m.group(1)), int(m.group(2))) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    checks=%d errors=%d' % base)

    bad = []
    for expect, name, fname, old, new in MUTANTS:
        restore()
        tgt = BUILD / 'rtl' / 'backend' / fname
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到，变异未生效（核改过？请同步本文件）' % name)
            bad.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败，不算结论' % name)
            bad.append(name)
            continue
        if expect == 'CATCH':
            ok = res[1] > 0
            tag = 'CAUGHT' if ok else '*** MISSED ***'
        else:
            ok = res[1] == 0
            tag = 'EQUIV-ok' if ok else '*** EQUIV 却报错，说明它并不等价 ***'
        print('  %-62s checks=%d errors=%-8d %s' % (name, res[0], res[1], tag))
        if not ok:
            bad.append(name)
    restore()
    if bad:
        print('=== MUTANTS FAILED ===')
        for m in bad:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d 个变异全部符合预期（7 CATCH + 1 EQUIV）===' % len(MUTANTS))
    return 0


if __name__ == '__main__':
    sys.exit(main())
