#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— 给 Entries* 的 UT 做「判别力」证明。

## 为什么要有它

`errors=0` 本身不是证据。**一个 UT 如果把 bug 注进去也不报错，它的 errors=0 没有意义。**
逐拍比对只保证"两侧一样"，保证不了"激励真把逻辑推到了那个状态"；覆盖闸能守住
"推到过"，但守不住"推到了而且比对真的看得见"。所以再加一道：往可读核里注入
若干个**真实形态**的 bug（每一个都是本轮实际踩过或差点踩到的写法），跑同一个 UT，
要求每一个都被抓出来（errors != 0 或覆盖闸红）。抓不出来的那一条，说明 UT 在那条
通路上是瞎的，必须先补激励/比对再谈签核。

注入是在**临时拷贝**上做的，仓里的 RTL 一个字节都不动。

## 用法

    python3 mutants.py EntriesAluCsrFenceDiv            # 全跑
    python3 mutants.py EntriesAluCsrFenceDiv --list     # 只列清单
    python3 mutants.py EntriesAluCsrFenceDiv --only M3  # 只跑一个
    python3 mutants.py EntriesAluCsrFenceDiv --cycles 40000

退出码 0 = 每个变异都被抓住；非零 = 有变异逃逸（UT 在那条路上没有判别力）。
"""

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
CORE = REPO / 'rtl' / 'backend' / 'xs_iq_entries_core.sv'

# (id, 说明, 原文, 改成什么)
# 每一条都对应一个**真实的写错方式**，不是随便翻个比特：
MUTANTS = [
    ('M1', 'Mux1H 写成「最后命中者覆盖」而不是按位或 —— '
           '本轮实际踩到的 bug：两路 IQ 唤醒可以同时命中同一个源，'
           '写成覆盖就丢掉另一路的 loadDependency 贡献',
     "          if (wk_iq_oh[s][w]) u_ld_dep[s] |= shift_iq_dep(iq_ld_dep[w], w);",
     "          if (wk_iq_oh[s][w]) u_ld_dep[s] = shift_iq_dep(iq_ld_dep[w], w);"),

    ('M2', 'srcLoadTransCancel 的选择向量拿成「去掉 og0 取消之后」的那份 —— '
           '本轮实际踩到的 bug：被 og0 取消的那一路不再参与 load 撤销判定，'
           'issued 会多置一次',
     "          if (wakeup_oh[s][w])\n"
     "            ld_trans_cancel[s] |= ld_should_cancel(iq_ld_dep[w], ld1_cancel, ld2_cancel);",
     "          if (wk_iq_oh[s][w])\n"
     "            ld_trans_cancel[s] |= ld_should_cancel(iq_ld_dep[w], ld1_cancel, ld2_cancel);"),

    ('M3', 'replaceRC 拿寄存器里的 regCacheIdx 去比，而不是 currentStatus 的 —— '
           '本轮实际踩到的 bug：enq 条目在入队延迟窗口里两者不同',
     "          rc_replaced[s] |= iq_wen[w] & (iq_rc_dest[w] == cur_rc_idx[s]);",
     "          rc_replaced[s] |= iq_wen[w] & (iq_rc_dest[w] == r_rc_idx[s]);"),

    ('M4', 'ShiftLoadDependency 忘了「本路唤醒自己就是某条 load 流水」那一位的常数 1',
     "      shift_iq_dep[q] = IQ_IS_LD_PIPE[w][q] ? LD_DEP_W'(1)\n"
     "                                            : LD_DEP_W'(dep[q] << 1);",
     "      shift_iq_dep[q] = LD_DEP_W'(dep[q] << 1);"),

    ('M5', 'LoadShouldCancel 只看 ld2Cancel 配 dep[1]，漏掉 ld1Cancel 配 dep[0]',
     "      ld_should_cancel |= (c1[q] & dep[q][0])\n"
     "                        | ((LD_DEP_W > 1) & c2[q] & dep[q][LD_DEP_W > 1 ? 1 : 0]);",
     "      ld_should_cancel |= ((LD_DEP_W > 1) & c2[q] & dep[q][LD_DEP_W > 1 ? 1 : 0]);"),

    ('M6', 'deqSuccess 忘了被 srcLoadCancel 门控 —— 被撤销的那拍仍当作发射成功清条目',
     "    deq_success    = resp_valid & (resp_bits == RESP_SUCCESS) & ~(|cur_ld_cancel);",
     "    deq_success    = resp_valid & (resp_bits == RESP_SUCCESS);"),

    ('M7', 'comp 条目的 canIssueBypass 没接上 —— 0 周期 IQ 唤醒的 uop 晚一拍才能发射',
     "  assign o_can_issue      = (IS_COMP ? (can_issue_plain | can_issue_bypass)\n"
     "                                     : can_issue_plain) & ~flushed;",
     "  assign o_can_issue      = can_issue_plain & ~flushed;"),

    ('M8', 'commonOut.dataSources 漏掉 forward 那一档（本拍 IQ 唤醒的源仍报寄存器堆）',
     "      o_data_src[s] = (IS_COMP & (|wakeup_oh[s])) ? DS_FORWARD\n"
     "                    : use_rc_now                  ? DS_REGCACHE\n"
     "                                                  : cur_data_src[s];",
     "      o_data_src[s] = use_rc_now ? DS_REGCACHE : cur_data_src[s];"),

    ('M9', 'exuSources 记成「第几路唤醒」而不是「第几路唤醒 + 1」'
           '（golden 的 0 表示"还没被 IQ 唤醒过"）',
     "        if (wk_iq_oh[s][w]) iq_exu_code[s] |= EXU_W'(w + 1);",
     "        if (wk_iq_oh[s][w]) iq_exu_code[s] |= EXU_W'(w);"),

    ('M10', 'comp 条目的 deqPortIdx 寄存器按「有没有 transEntry 出口」生成 —— '
            '正是从最小变体 VfdivVidiv 外推出来的那个错结论',
     "    if (NUM_DEQ_PORTS > 1) begin : g_deq_port_idx",
     "    if (KEEP_WIDE) begin : g_deq_port_idx"),

    ('M11', 'comp 条目入口的 srcLoadDependency 钉 0 —— '
            '同样是从 VfdivVidiv 外推出来的错结论',
     "      `IQE_MUX1H(x_ld_dep[e],       final_comp_sel[k][j], c_ld_dep[k],       NUM_ENQ)",
     "      x_ld_dep[e] = '0;"),

    ('M12', 'issueResp 的 4 档常量表里，timer0 那档从 BLOCK 改成 SUCCESS',
     "        resp_bits_tab[d][k]  = OG_HAS_BITS[k] ? og_resp[k][d] : OG_CONST_RESP[k];",
     "        resp_bits_tab[d][k]  = OG_HAS_BITS[k] ? og_resp[k][d]\n"
     "                             : ((k == 0) ? RESP_SUCCESS : OG_CONST_RESP[k]);"),
]


def run(cmd, cwd, env=None):
    return subprocess.run(cmd, cwd=str(cwd), env=env, shell=isinstance(cmd, str),
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('top')
    ap.add_argument('--cycles', type=int, default=30000,
                    help='每个变异跑多少拍（默认 30000，足够让所有闸都动起来）')
    ap.add_argument('--seed', type=int, default=1)
    ap.add_argument('--only')
    ap.add_argument('--list', action='store_true')
    a = ap.parse_args()

    if a.list:
        for mid, desc, _, _ in MUTANTS:
            print(f'{mid}: {desc}')
        return 0

    utdir = REPO / 'verif' / 'ut' / a.top
    core_txt = CORE.read_text()

    # 先确认所有锚点都还在（核改过之后锚点可能漂走 —— 那必须先修这里，
    # 否则"变异没注进去"会被误当成"UT 抓住了"）。
    missing = [m[0] for m in MUTANTS if core_txt.count(m[2]) != 1]
    if missing:
        sys.stderr.write(f'[FAIL] 这些变异的锚点在核里找不到或不唯一: {missing}\n'
                         f'       核改动后必须同步更新 mutants.py 的锚点。\n')
        return 1

    todo = [m for m in MUTANTS if not a.only or m[0] == a.only]
    caught, escaped = [], []

    for mid, desc, old, new in todo:
        work = pathlib.Path(tempfile.mkdtemp(prefix=f'xsv2-mut-{mid}-'))
        try:
            # UT 的 Makefile 里写死了 ../../../rtl 与 ../../../scripts，
            # 所以副本必须摆成同样的 <root>/verif/ut/<top> 层次。
            ut = work / 'verif' / 'ut' / a.top
            ut.parent.mkdir(parents=True)
            shutil.copytree(str(utdir), str(ut),
                            ignore=shutil.ignore_patterns(
                                'csrc', 'simv*', '*.log', 'ut_gen', '*.key'))
            mrtl = work / 'rtl' / 'backend'
            mrtl.mkdir(parents=True)
            shutil.copy(str(REPO / 'rtl' / 'backend' / f'{a.top}.sv'), str(mrtl))
            (mrtl / CORE.name).write_text(core_txt.replace(old, new, 1))
            os.symlink(str(REPO / 'scripts'), str(work / 'scripts'))

            r = run(['make', 'simv'], ut)
            if r.returncode != 0:
                # 编不过也算"被抓住"——变异确实改变了行为；但要记下来
                caught.append((mid, 'compile-error'))
                print(f'[{mid}] 编译失败（算抓住）: {desc}')
                continue
            r = run(['./simv', f'+ntb_random_seed={a.seed}',
                     f'+ncycles={a.cycles}', '-l', 'mut.log'], ut)
            log = (ut / 'mut.log').read_text(errors='replace')
            m = re.search(r'errors=(\d+)', log)
            errs = int(m.group(1)) if m else -1
            hole = 'COVERAGE HOLE' in log
            failed = ('TEST FAILED' in log) or (errs > 0)
            if failed:
                why = f'errors={errs}' + (' + 覆盖闸红' if hole else '')
                caught.append((mid, why))
                print(f'[{mid}] 抓住 ({why}): {desc}')
            else:
                escaped.append((mid, desc))
                print(f'[{mid}] ★逃逸★ errors={errs}: {desc}')
        finally:
            shutil.rmtree(str(work), ignore_errors=True)

    print(f'\n变异判别力: 抓住 {len(caught)}/{len(todo)}')
    if escaped:
        print('逃逸清单（UT 在这些通路上没有判别力，必须先补激励/比对）:')
        for mid, desc in escaped:
            print(f'  {mid}: {desc}')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
