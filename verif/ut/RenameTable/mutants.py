#!/usr/bin/env python3
"""mutants.py —— RenameTable 家族 UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
本模块的坑集中在**优先级方向**上，而且两个方向是反的：
  · 投机写命中同一格时，**口号大的赢**（ParallelPriorityMux 把两个 Vec 都 reverse 了）；
  · old_pdest 的同址旁路只看**更小的口号**（MuxCase 的候选表是 take(i).reverse）。
把其中一处"对齐"成另一处，功能看着都很合理，只有激励真的撞出同址多写时才分得出。
所以激励必须把地址挤进窄窗口（见 tb 头注释），负测则要把这两个方向各拧一次。

做法：把 rtl/ 与本目录复制进 neg_build/（已 gitignore，**变异不进库**），
逐个注入一处改动，跑 20k 拍，读 tb 末行的合计 `checks=.. errors=..`。

★两类条目，缺一不可（CONVENTIONS：闸的负测必须双向）★
  CATCH —— 真 bug，UT 必须报（errors > 0）。
  EQUIV —— 文本改了、电路等价，UT 必须**不报**（防"恒红的 harness"）。
           E1 换 arch_table 写循环的内外层：两种写法下"对某一格而言最后命中的
           写口赢"都成立，所以电路一模一样。
           E2 把 N_ENTRIES 份 `spec_redirect_q` 合成共享的一份 —— 这条特意留着，
           因为它**恰好是 UT 看不见而 FM 一定报的那类差异**（Entries canary 实测
           同物种 846 failing）。它在这里的身份是"UT 能力边界的样本"，
           **不是"可以顺手合并"**：golden 里就是 N 份，一份都不许少。

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
CORE = 'RenameTable.sv'
RTL = [CORE, 'RenameTable_1.sv', 'RenameTable_2.sv', 'RenameTable_3.sv',
       'SnapshotGenerator.sv', 'SnapshotGenerator_4.sv', 'SnapshotGenerator_5.sv',
       'SnapshotGenerator_6.sv', 'SnapshotGenerator_7.sv']
NCYCLES = '20000'

MUTANTS = [
    ('CATCH', 'M1 投机写优先级反向（改成口号小的赢）', CORE,
     "      for (int j = 1; j < N_WRITE; j++)\n"
     "        if (matchVec[i][j]) wMatch[i] = t1_wSpec_data[j];",
     "      for (int j = N_WRITE - 1; j >= 1; j--)\n"
     "        if (matchVec[i][j]) wMatch[i] = t1_wSpec_data[j];"),
    ('CATCH', 'M2 old_pdest 的同址旁路看了**所有**口而不是只看更小的口号', CORE,
     "      for (int k = 0; k < w; k++)\n"
     "        if (io_archWritePorts_wen[k] && io_archWritePorts_addr[k] == io_archWritePorts_addr[w])",
     "      for (int k = 0; k < N_WRITE; k++)\n"
     "        if (io_archWritePorts_wen[k] && io_archWritePorts_addr[k] == io_archWritePorts_addr[w])"),
    ('CATCH', 'M3 need_free 漏掉"与更低口号重复"的抑制', CORE,
     "      need_free_next[w] = notInArch & ~dup;",
     "      need_free_next[w] = notInArch;"),
    ('CATCH', 'M4 spec_table 次态把投机写排到冲刷恢复前面（优先级倒置）', CORE,
     "        if (spec_redirect_q[i])   spec_table[i] <= restore_src[i];\n"
     "        else if (|matchVec[i])    spec_table[i] <= wMatch[i];",
     "        if (|matchVec[i])         spec_table[i] <= wMatch[i];\n"
     "        else if (spec_redirect_q[i]) spec_table[i] <= restore_src[i];"),
    ('CATCH', 'M5 旁路判定在 hold 时比的是本拍读地址而不是锁存地址', CORE,
     "                                ? io_specWritePorts_addr[j] == t1_raddr[r]",
     "                                ? io_specWritePorts_addr[j] == io_readPorts_addr[r]"),
    ('CATCH', 'M6 arch_table 写优先级反向（改成口号小的赢）', CORE,
     "        for (int w = 0; w < N_WRITE; w++)\n"
     "          if (io_archWritePorts_wen[w] && io_archWritePorts_addr[w] == AW'(e))",
     "        for (int w = N_WRITE - 1; w >= 0; w--)\n"
     "          if (io_archWritePorts_wen[w] && io_archWritePorts_addr[w] == AW'(e))"),
    ('CATCH', 'M7 io_redirect 不清 t1_wSpec（冲刷那拍的投机写还会落到表上）', CORE,
     "        t1_wSpec_wen[w]  <= 1'b0;\n"
     "        t1_wSpec_data[w] <= 8'h0;",
     "        t1_wSpec_wen[w]  <= io_specWritePorts_wen[w];\n"
     "        t1_wSpec_data[w] <= io_specWritePorts_data[w];"),
    ('CATCH', 'M8 diffRatBase 导的是 spec_table 现值而不是次态', CORE,
     "    assign io_diffRatBase[k] = spec_next[DIFF_OFF + k];",
     "    assign io_diffRatBase[k] = spec_table[DIFF_OFF + k];"),
    ('CATCH', 'M9 快照恢复源恒取 arch_table（useSnpt 那条路没了）', CORE,
     "      restore_src[i] = t2_snpt_useSnpt ? snpt_rdata[t2_snpt_sel][i] : arch_table[i];",
     "      restore_src[i] = arch_table[i];"),
    ('EQUIV', 'E1 arch_table 写循环换内外层（对每一格仍是最后命中的口赢 ⇒ 电路等价）', CORE,
     "      for (int e = 0; e < N_ENTRIES; e++)\n"
     "        for (int w = 0; w < N_WRITE; w++)\n"
     "          if (io_archWritePorts_wen[w] && io_archWritePorts_addr[w] == AW'(e))\n"
     "            arch_table[e] <= io_archWritePorts_data[w];",
     "      for (int w = 0; w < N_WRITE; w++)\n"
     "        for (int e = 0; e < N_ENTRIES; e++)\n"
     "          if (io_archWritePorts_wen[w] && io_archWritePorts_addr[w] == AW'(e))\n"
     "            arch_table[e] <= io_archWritePorts_data[w];"),
    ('EQUIV', 'E2 N 份 spec_redirect_q 合成共享一份（★UT 按构造看不见，FM 一定报★）', CORE,
     "      spec_next[i] = spec_redirect_q[i] ? restore_src[i]",
     "      spec_next[i] = spec_redirect_q[0] ? restore_src[i]"),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'RenameTable').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'RenameTable' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    """返回 (checks, errors)；编译或运行失败返回 None（make run 每次先删日志）。"""
    ut = BUILD / 'verif' / 'ut' / 'RenameTable'
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
        ok = (res[1] > 0) if expect == 'CATCH' else (res[1] == 0)
        tag = ('CAUGHT' if ok else '*** MISSED ***') if expect == 'CATCH' \
              else ('EQUIV-ok' if ok else '*** EQUIV 却报错，说明它并不等价 ***')
        print('  %-64s checks=%d errors=%-9d %s' % (name, res[0], res[1], tag))
        if not ok:
            bad.append(name)
    restore()
    if bad:
        print('=== MUTANTS FAILED ===')
        for m in bad:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d 个变异全部符合预期（9 CATCH + 2 EQUIV）===' % len(MUTANTS))
    return 0


if __name__ == '__main__':
    sys.exit(main())
