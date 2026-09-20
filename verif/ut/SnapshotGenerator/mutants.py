#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— SnapshotGenerator **家族** UT 的判别力负测（`make mutants`）。

`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。
做法：把 rtl/ 与本目录复制进 neg_build/（已在 .gitignore 里，**变异不进库**），
逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来（errors > 0）。

★ 变异选型 ★
  M1  ★复位域★ 给 4 个快照槽加复位（golden 不复位）——只有在「暖机之后还打
      reset 脉冲」时才可观测，是那条规矩的守卫；
  M2  把 Chisel 那处 zip 笔误「修好」：qualified[0] 与 [1][2] 同形。
      ★这正是照 Chisel 语义（而不是照 golden 展开）写就会掉进去的坑★；
  M3  valids 更新优先级翻转（置压过清）；
  M4  队满判据的 flag 比较写反（!= 写成 ==）⇒ 满时不再丢弃；
  M5  deq 不受 redirect 门控；
  M6  flush 重算 enqPtr 的候选优先级反过来（高下标优先）；
  M7  valids 的清除拿 enqPtr 比（应当拿 deqPtr 比）。
  ---- 以下是家族 wrapper 层（M1..M7 都在共享核里，动的是 11 个变体的公共部分）----
  M8  _6（47 字段、最宽的一个）拆包时把槽 2 的两个相邻字段错位一格；
  M9  _14 的 valids 输出位序倒过来 —— ★这是全家族唯一有 ptr/valids 输出的变体★，
      本条专门守住"那 8 根端口真的在比对里"；
  M10 _2（VType）打包时把 vsew 与 vlmul 的次序对调。

★ 双向 ★ 只证"该报的报"是不够的：一个恒报警的 tb 也能让 M1..M10 全 CAUGHT。
所以最后一条 N1 是**期望不报**的等价改写（把 _12 的打包/拆包约定整体换成
"先声明的放低位"，pack 与 unpack 同时改 ⇒ 电路一模一样）。
N1 若报出 error，说明 tb 在对"实现细节"而不是"端口行为"下断言，同样算负测失败。

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
SG = 'SnapshotGenerator.sv'
V2, V6, V12, V14 = ('SnapshotGenerator_%s.sv' % n for n in ('2', '6', '12', '14'))
# 家族 11 个变体的文件（负测要把它们全复制进 neg_build，否则编不过）
FAMILY = [SG] + ['SnapshotGenerator_%d.sv' % n for n in (1, 2, 3, 4, 5, 6, 7, 11, 12, 14)]

MUTANTS = [
    # ★实测踩到的坑（2026-09-17）★：本条最早写成「在 §5 的复位臂里多写一句
    # snapshots_q <= '0」。那样 snapshots_q 被**两个 always_ff 块**驱动，VCS 不报错，
    # 跟在后面的 §6 块赢，变异根本没生效 —— 跟了一轮 errors=0，看起来像「UT 漏检」，
    # 实际上是「负测自己是空的」。改成在 §6 块**内**加同步复位才是真变异。
    ('M1 ★复位域★ 给 4 个快照槽加复位（golden 不复位）', SG,
     "      if (enq_sel[i]) snapshots_q[i] <= enq_data;",
     "      if (reset) snapshots_q[i] <= '0;\n      else if (enq_sel[i]) snapshots_q[i] <= enq_data;"),

    ('M2 把 Chisel 的 zip 笔误「修好」：qualified[0] 与 [1][2] 同形', SG,
     "    qualified[0] = ~snpt_valids_q[cand[0].value] | flush_vec[cand[0].value];",
     "    qualified[0] = snpt_valids_q[cand[0].value]\n                 & (~snpt_valids_q[cand[0].value] | flush_vec[cand[0].value]);"),

    ('M3 valids 更新优先级翻转（置压过清）', SG,
     "        snpt_valids_q[i] <=\n            ~(flush_vec[i] | (deq_fire & (snpt_deq_ptr_q.value == SNPT_PTR_W'(i))))\n          & (enq_sel[i] | snpt_valids_q[i]);",
     "        snpt_valids_q[i] <=\n            enq_sel[i]\n          | (~(flush_vec[i] | (deq_fire & (snpt_deq_ptr_q.value == SNPT_PTR_W'(i))))\n             & snpt_valids_q[i]);"),

    ('M4 队满判据的 flag 比较写反（满时不再丢弃 enq）', SG,
     "  assign full  = (snpt_enq_ptr_q.flag != snpt_deq_ptr_q.flag)",
     "  assign full  = (snpt_enq_ptr_q.flag == snpt_deq_ptr_q.flag)"),

    ('M5 deq 不受 redirect 门控', SG,
     "  assign deq_fire = ~redirect & deq;",
     "  assign deq_fire = deq;"),

    ('M6 flush 重算 enqPtr 的候选优先级反过来（高下标优先）', SG,
     "    for (int k = SNPT_NUM-2; k >= 0; k--)           // 倒着覆盖 = 低下标优先\n      if (qualified[k]) new_enq_ptr = cand[k];",
     "    for (int k = 0; k <= SNPT_NUM-2; k++)\n      if (qualified[k]) new_enq_ptr = cand[k];"),

    ('M7 valids 的清除拿 enqPtr 比（应当拿 deqPtr 比）', SG,
     "            ~(flush_vec[i] | (deq_fire & (snpt_deq_ptr_q.value == SNPT_PTR_W'(i))))",
     "            ~(flush_vec[i] | (deq_fire & (snpt_enq_ptr_q.value == SNPT_PTR_W'(i))))"),
    # ---- 家族 wrapper 层 ----
    ('M8 _6 拆包时槽 2 的两个相邻字段错位一格', V6,
     "  assign io_snapshots_2_10 = core_snapshots[2][295:288];",
     "  assign io_snapshots_2_10 = core_snapshots[2][287:280];"),

    ('M9 ★_14 独有★ valids 输出位序倒过来', V14,
     "    .valids    ({io_valids_3, io_valids_2, io_valids_1, io_valids_0})",
     "    .valids    ({io_valids_0, io_valids_1, io_valids_2, io_valids_3})"),

    ('M10 _2 打包时 vsew 与 vlmul 次序对调', V2,
     "    io_enqData_vsew,\n    io_enqData_vlmul",
     "    io_enqData_vlmul,\n    io_enqData_vsew"),
]

# ★双向负测的另一侧★：期望 **errors == 0** 的等价改写。
# 把 _12 的打包约定整体翻转（先声明的改放低位），pack 与 unpack 同时改，
# 电路完全不变。tb 若在这里报错，就说明它在对内部实现细节下断言。
NOOPS = [
    ('N1 _12 打包约定整体翻转（pack+unpack 同时改，电路不变）', V12, [
        ("  assign core_enq_data = {\n    io_enqData_flag,\n    io_enqData_value\n  };",
         "  assign core_enq_data = {\n    io_enqData_value,\n    io_enqData_flag\n  };"),
    ] + [x for i in range(4) for x in (
        ("  assign io_snapshots_%d_flag = core_snapshots[%d][5];" % (i, i),
         "  assign io_snapshots_%d_flag = core_snapshots[%d][0];" % (i, i)),
        ("  assign io_snapshots_%d_value = core_snapshots[%d][4:0];" % (i, i),
         "  assign io_snapshots_%d_value = core_snapshots[%d][5:1];" % (i, i)),
    )]),
]

NCYCLES = '20000'


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'SnapshotGenerator').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    for f in FAMILY:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'SnapshotGenerator' / f)


def restore():
    for f in FAMILY:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'SnapshotGenerator'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    # 只看 errors：20k 拍下部分覆盖项本来就达不到门限（门限按 200k 定），
    # 负测判据是「变异有没有被逐拍比对抓到」，与覆盖门限无关。
    m = re.search(r'compared=(\d+)\s+errors=(\d+)', log.read_text())
    return (int(m.group(1)), int(m.group(2))) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    compared=%d errors=%d' % base)
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
        print('  %-58s compared=%d errors=%-8d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)
    # ---- 双向的另一侧：等价改写必须 **不** 报警 ----
    false_alarm = []
    for name, fname, edits in NOOPS:
        restore()
        tgt = BUILD / 'rtl' / 'backend' / fname
        t = tgt.read_text()
        ok_anchor = True
        for old, new in edits:
            if old not in t:
                print('!! %s：锚点没找到 %r' % (name, old[:50]))
                ok_anchor = False
                break
            t = t.replace(old, new, 1)
        if not ok_anchor:
            false_alarm.append(name + '（锚点失配）')
            continue
        tgt.write_text(t)
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败' % name)
            false_alarm.append(name + '（编译失败）')
            continue
        ok = res[1] == 0
        print('  %-58s compared=%d errors=%-8d %s'
              % (name, res[0], res[1], 'CLEAN(预期)' if ok else '★FALSE ALARM★'))
        if not ok:
            false_alarm.append(name)

    restore()
    if false_alarm:
        print('=== 负测失败：等价改写被误报（闸是"恒报警"的，CAUGHT 不算数）===')
        for m in false_alarm:
            print('   ', m)
        return 1
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d/%d 个变异全部被抓到，%d/%d 个等价改写全部未误报 ==='
          % (len(MUTANTS), len(MUTANTS), len(NOOPS), len(NOOPS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
