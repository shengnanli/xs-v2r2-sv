#!/usr/bin/env python3
"""mutants.py —— BusyTable 家族 UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。本轮
工程里已经踩过多次「看起来在验、实际没在验」——最典型的是给每个输入每拍独立均匀
随机，结果队列永远进不了满/顺序提交的状态，3 seed × 200k 拍什么都没验到。

做法：把 rtl/ 与本目录复制进 neg_build/（已在 .gitignore 里，**变异不进库**），
逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来（errors > 0）。
七个变异各对准一条本模块真实容易写错的地方，其中 M1/M2/M5 正是 golden 与 Chisel
字面不一致的那三处——照 Chisel 写就会变成这三个变异之一；M1/M8/M9 三个一起钉住
「读口越界」这一族语义（忙位得 0、依赖得第 0 项、旁路不看越界，三者各不相同）。

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

# (说明, 改哪个文件, 锚点, 替换)
MUTANTS = [
    ('M1 越界读 loadDependency 返回 0（golden 是返回第 0 项）',
     'xs_BusyTable_core.sv',
     "        assign dep_by_req[q] = load_dep[0];   // \u2605\u8d8a\u754c\u586b\u7b2c 0 \u9879,\u4e0d\u662f 0\u2605",
     "        assign dep_by_req[q] = '0;"),
    ('M2 取消 Int 表 0 号项特判（x0 会被分配置忙）',
     'xs_BusyTable_core.sv',
     "        if (ZERO_ALWAYS_READY && p == 0) begin",
     "        if (ZERO_ALWAYS_READY && p == 99999) begin"),
    ('M3 更新优先级翻转：置忙压过清忙',
     'xs_BusyTable_core.sv',
     "          if (busy_en[p]) busy[p] <= ~busy_clr[p] & (busy_set[p] | busy[p]);",
     "          if (busy_en[p]) busy[p] <= busy_set[p] | (~busy_clr[p] & busy[p]);"),
    ('M4 loadDependency 老化方向错（右移而非左移）',
     'xs_BusyTable_core.sv',
     "              load_dep[p][j] <= {load_dep[p][j][LD_DEP_W-2:0], 1'b0};",
     "              load_dep[p][j] <= {1'b0, load_dep[p][j][LD_DEP_W-1:1]};"),
    ('M5 wakeUpInt_2 的 is0Lat 折向取反（1→0，og0Cancel_4 门控消失）',
     'BusyTable.sv',
     ".wk_is0lat   ({1'b0, 1'b0, 1'b0, 1'b1, 1'b1,",
     ".wk_is0lat   ({1'b0, 1'b0, 1'b0, 1'b1, 1'b0,"),
    ('M6 vlmaxTable 不取反存储',
     'xs_BusyTable_core.sv',
     "              vlmax_table[p]   <= ~vl_from_int_is_vlmax;",
     "              vlmax_table[p]   <= vl_from_int_is_vlmax;"),
    ('M7 唤醒时装载 loadDependency 漏掉 mem 三路（Mux1H 只留前 4 路）',
     'xs_BusyTable_core.sv',
     "          for (int i = 0; i < WK_SLOTS; i++)",
     "          for (int i = 0; i < 4; i++)"),
    ('M8 忙位越界读成「忙」（golden 的 `table>>req` 越界得 0 = 就绪）',
     'xs_BusyTable_core.sv',
     "  assign busy_by_req = {{(256 - NUM_PREGS){1'b0}}, busy};",
     "  assign busy_by_req = {{(256 - NUM_PREGS){1'b1}}, busy};"),
    ('M9 读口分配旁路被限制在表内（golden 的旁路是全 8 位比较，不看越界）',
     'xs_BusyTable_core.sv',
     "      assign alloc_bypass[a] = alloc_valid[a] & (alloc_preg[a] == read_req[r]);",
     "      assign alloc_bypass[a] = (read_req[r] < PREG_IDX_W'(NUM_PREGS)) & alloc_valid[a] & (alloc_preg[a] == read_req[r]);"),
]

RTL = ['xs_BusyTable_core.sv', 'BusyTable.sv', 'BusyTable_1.sv',
       'BusyTable_2.sv', 'BusyTable_3.sv', 'VlBusyTable.sv']
NCYCLES = '20000'


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'BusyTable').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'BusyTable' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'BusyTable'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
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
    for name, fname, old, new in MUTANTS:
        restore()
        tgt = BUILD / 'rtl' / 'backend' / fname
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
        print('  %-60s checks=%d errors=%-7d %s'
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
