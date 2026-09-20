#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— RenameBuffer / SnapshotGenerator UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只有在「注入真 bug 时 UT 会红」的前提下才有意义。本轮
工程里已经踩过多次「看起来在验、实际没在验」——最典型的是给每个输入每拍独立均匀
随机，结果队列永远进不了满/回滚的状态，3 seed × 200k 拍什么都没验到。

做法：把 rtl/ 与本目录复制进 neg_build/（已在 .gitignore 里，**变异不进库**），
逐个注入一个真 bug，跑 20k 拍，要求每个都被 UT 抓出来（errors > 0）。

★ 变异选型 ★ 每个都对准一条「照 Chisel 字面写 / 照直觉写就会写错」的地方：
  M1/M2  复位值不是 0（指针 0,1,..,5；allowEnqueue 复位为 1）；
  M3     ★复位域★：给 golden **没有**复位的 256 项缓冲表加上复位。
         它只有在「暖机之后还打 reset 脉冲」时才可观测 ——
         是「比对窗口必须盖住复位事件」这条规矩的守卫；
  M4     回滚结束那拍拉回队尾用的是 walkPtrNext 不是 walkPtr（差一拍）；
  M5     s_special_walk 的结束阈值差一（<=6 vs <6）；
  M6     提交/回滚读口选反（s_special_walk 走的是**提交**指针）；
  M7     deqPtrOH 推进量不看状态（s_walk 期间也跟着走）；
  M8     robWalkEndReg 没被 redirect 清掉（golden 写的是 ~redirect & (walkEnd | reg)）；
  M9     commitValid 的比较写成 >=（差一）；
  M10    队列占用量同 flag 分支写成 9 位减法（golden 是 8 位减法后零扩展）——
         只有在 tb 把队列灌到 enqPtr 越过 deqPtr 时才看得见；
  M11    SnapshotGenerator：flush 修复 enqPtr 的 qualified[0] 形状写成与 [1]/[2]
         一样（即把 Chisel 那处 zip 笔误「修好」）；
  M12    SnapshotGenerator：valids 的更新优先级翻转（置压过清）。

★ 已知**测不出来**的五类改动（诚实记下，不在 MUTANTS 里凑数）★
五条都**实测过**：各自注入后跟 20k 拍（SEED=1, initreg=random），
compared=1666560 errors=0 —— 即 UT 对它们零判别力。
  (a) 把提交读口的 one-hot 影子寄存器 deqPtrOH 换成 buffer_q[deqPtr.value+i]：
      两者在本 tb 里恒等（deqPtrOH 异步复位成 256'h1、deqPtr 复位成 0，此后
      同步推进），仿真**永远**看不出差别；实测 20k 拍 errors=0。
      不许合并这条是 FM 口径的要求（合并后 golden 的 deqPtrOH 少一个比对点），
      不是 UT 能守住的。
  (b) 越界默认项（enq_ptr_lookup[6]/[7]、deq_ptr_oh_rot[7]）：下标不可达，
      任何取值都测不出来。照抄 golden 只为与 golden 逐位同构。
  (c) ★给 walkPtr 加复位★：walkPtr 只在 state==s_walk 时被读（commits.info 走
      walkCandidates），而**每次进 s_walk 都会把它从快照或 deqPtrNext 重新赋值**，
      所以 s_idle 期间那个「保持着的陈旧值」永远没人读。结论：这一位的复位域
      **仿真管不住**，只能靠 FM（多一个复位比对点）。实测依据：把
      `walk_ptr_q <= walk_ptr_next` 改成 `<= reset ? '0 : walk_ptr_next`，
      20k 拍 errors=0。tb 的暖机里仍然把它写成确定值（无害，且不依赖这条结论）。
  (e) ★redirect 且 useSnpt 时 vecLoadExcp 是「保持」还是「收输入」★：
      vecLoadExcp_valid 只在 state==s_special_walk 时被读（算 toVecExcpMod 的 valid），
      而**进 s_special_walk 的唯一路径是 redirect 且 !useSnpt，那一拍它本就被
      输入覆写**，所以 useSnpt 那条分支留下的差异永远活不到被读的时刻。
      实测：把空 then 分支改成「无条件收输入」，20k 拍 errors=0。
      它是 golden 的寄存器，FM 会比到；UT 比不到。
  (d) ★缓冲表写端口优先级★：golden 的 if/else-if 链是 req[5] 优先，但
      allocatePtrVec[w] = enqPtr + popcount(realNeedAlloc[0..w-1])，**两路都真要占格时
      指针不可能相等**，所以冲突压根不存在，优先级怎么排都一样。
      实测：把 §10 的 w 升序改成降序（变成 req[0] 胜），20k 拍 errors=0。
      照抄 golden 的排序只为与 golden 同构。

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

RB = 'RenameBuffer.sv'
SG = 'SnapshotGenerator.sv'

# (说明, 改哪个文件, 锚点, 替换)
MUTANTS = [
    ('M1 enqPtrVec 复位值写成全 0（golden 是 0,1,2,3,4,5）', RB,
     "      for (int i = 0; i < RENAME_W; i++) enq_ptr_value_q[i] <= PTR_W'(i);",
     "      for (int i = 0; i < RENAME_W; i++) enq_ptr_value_q[i] <= PTR_W'(0);"),

    ('M2 allowEnqueue 复位值写成 0（golden 是 1）', RB,
     "      allow_enq_q          <= 1'b1;",
     "      allow_enq_q          <= 1'b0;"),

    # ★实测踩到的坑（2026-09-17）★：M3 最早写成「在 §9 的复位臂里多写一句
    # buffer_q <= 0」。那样 buffer_q 被**两个 always_ff 块**驱动，VCS 不报错，
    # 跟在后面的 §10 块赢，变异根本没生效 —— errors=0 看起来像「UT 漏检」，
    # 实际上是「负测自己是空的」。改成在 §10 块**内**加同步复位才是真变异。
    ('M3 ★复位域★ 给 256 项缓冲表加复位（golden 不复位）', RB,
     "      if (real_need_alloc[w]) buffer_q[alloc_ptr[w]] <= req[w].info;",
     "      if (reset) begin for (int e = 0; e < RAB_SIZE; e++) buffer_q[e] <= '0; end\n      else if (real_need_alloc[w]) buffer_q[alloc_ptr[w]] <= req[w].info;"),

    ('M4 s_walk→s_idle 拉回队尾时用 walkPtr 而非 walkPtrNext（差一拍）', RB,
     "  assign enq_ptr_next = (state_q == S_WALK && state_next == S_IDLE)\n                      ? walk_ptr_next",
     "  assign enq_ptr_next = (state_q == S_WALK && state_next == S_IDLE)\n                      ? walk_ptr_q"),

    ('M5 s_special_walk 结束阈值差一（<=6 写成 <6）', RB,
     "  assign special_walk_end_next = (special_walk_size_q <= SIZE_W'(COMMIT_W));",
     "  assign special_walk_end_next = (special_walk_size_q <  SIZE_W'(COMMIT_W));"),

    ('M6 提交/回滚读口选反（s_special_walk 应当走提交指针）', RB,
     "      commits_info[i] = commits_is_commit ? commit_cand[i] : walk_cand[i];",
     "      commits_info[i] = commits_is_walk ? walk_cand[i] : commit_cand[i];"),

    ('M7 deqPtrOH 推进量不看状态（s_walk 期间也跟着走）', RB,
     "      deq_ptr_oh_q <= deq_ptr_oh_rot[deq_ptr_steps];",
     "      deq_ptr_oh_q <= deq_ptr_oh_rot[commit_count];"),

    ('M8 robWalkEndReg 不被 redirect 清掉（golden 是 ~redirect & (…)）', RB,
     "      rob_walk_end_q <= ~redirect_valid & (rob_walk_end | rob_walk_end_q);",
     "      rob_walk_end_q <= (rob_walk_end | rob_walk_end_q);"),

    ('M9 commitValid 比较差一（> 写成 >=）', RB,
     "      commits_commit_valid[i] = ((state_q == S_IDLE)         & (commit_size_q       > SIZE_W'(i)))",
     "      commits_commit_valid[i] = ((state_q == S_IDLE)         & (commit_size_q       >= SIZE_W'(i)))"),

    ('M10 占用量同 flag 分支写成 9 位减法（golden 是 8 位减法后零扩展）', RB,
     "        ? {1'b0, PTR_W'(enq_ptr_value_q[0] - deq_ptr_value_q[0])}",
     "        ? ((PTR_W+1)'(enq_ptr_value_q[0]) - (PTR_W+1)'(deq_ptr_value_q[0]))"),

    ('M11 Snapshot：把 Chisel 那处 zip 笔误「修好」（qualified[0] 与 [1][2] 同形）', SG,
     "    qualified[0] = ~snpt_valids_q[cand[0].value] | flush_vec[cand[0].value];",
     "    qualified[0] = snpt_valids_q[cand[0].value]\n                 & (~snpt_valids_q[cand[0].value] | flush_vec[cand[0].value]);"),

    ('M12 Snapshot：valids 更新优先级翻转（置压过清）', SG,
     "        snpt_valids_q[i] <=\n            ~(flush_vec[i] | (deq_fire & (snpt_deq_ptr_q.value == SNPT_PTR_W'(i))))\n          & (enq_sel[i] | snpt_valids_q[i]);",
     "        snpt_valids_q[i] <=\n            enq_sel[i]\n          | (~(flush_vec[i] | (deq_fire & (snpt_deq_ptr_q.value == SNPT_PTR_W'(i))))\n             & snpt_valids_q[i]);"),
]

RTL = [RB, SG]
NCYCLES = '20000'


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'RenameBuffer').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'RenameBuffer' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'RenameBuffer'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    # 只看 errors：20k 拍下部分覆盖项（门限按 200k 定）本来就达不到，
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
        print('  %-64s compared=%d errors=%-8d %s'
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
