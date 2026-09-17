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

sys.path.insert(0, str(HERE))
import entries_gen as _gen                                         # noqa: E402

# (id, 说明, 原文, 改成什么, 适用性判据)
#
# 每一条都对应一个**真实的写错方式**，不是随便翻个比特。
#
# ★适用性判据是必填项，而且必须是从 golden 量出来的变体字段★
#   有些变异在某个变体上**根本改不动行为**：例如把 ld1Cancel 那一项删掉，而本变体的
#   golden 压根没有 ld1Cancel 端口（矩阵 ldCancel_ld1=0），那一项恒 0。这种情况下
#   "UT 没报错"不是 UT 瞎，而是变异本身是死的。两者必须分开记，否则这道靶子
#   自己就成了"看起来在验、实际没在验"：
#     - 不适用 -> 记 N/A，并且用**变体字段**说明它为什么是死的，不许拍脑袋写 True；
#     - 适用却逃逸 -> 判失败，说明 UT 在那条通路上确实没有判别力。
#   判据写成 lambda v -> (适用?, 理由)，v 就是 entries_gen.Variant。
MUTANTS = [
    ('M1', 'Mux1H 写成「最后命中者覆盖」而不是按位或 —— '
           '本轮实际踩到的 bug：两路 IQ 唤醒可以同时命中同一个源，'
           '写成覆盖就丢掉另一路的 loadDependency 贡献',
     "          if (wk_iq_oh[s][w]) u_ld_dep[s] |= shift_iq_dep(iq_ld_dep[w], w);",
     "          if (wk_iq_oh[s][w]) u_ld_dep[s] = shift_iq_dep(iq_ld_dep[w], w);",
     lambda v: (v.n_wk_iq > 0, '没有 IQ 唤醒的变体里 wk_iq_oh 恒 0，这条是死的')),

    ('M2', 'srcLoadTransCancel 的选择向量拿成「去掉 og0 取消之后」的那份 —— '
           '本轮实际踩到的 bug：被 og0 取消的那一路不再参与 load 撤销判定，'
           'issued 会多置一次',
     "          if (wakeup_oh[s][w])\n"
     "            ld_trans_cancel[s] |= ld_should_cancel(iq_ld_dep[w], ld1_cancel, ld2_cancel);",
     "          if (wk_iq_oh[s][w])\n"
     "            ld_trans_cancel[s] |= ld_should_cancel(iq_ld_dep[w], ld1_cancel, ld2_cancel);",
     lambda v: (v.n_wk_iq > 0 and v.n_ld_cancel > 0,
                '要同时有 IQ 唤醒和 ldCancel 这条才活')),

    ('M3', 'replaceRC 拿寄存器里的 regCacheIdx 去比，而不是 currentStatus 的 —— '
           '本轮实际踩到的 bug：enq 条目在入队延迟窗口里两者不同',
     "          rc_replaced[s] |= iq_wen[w] & (iq_rc_dest[w] == cur_rc_idx[s]);",
     "          rc_replaced[s] |= iq_wen[w] & (iq_rc_dest[w] == r_rc_idx[s]);",
     lambda v: (v.has_rc, '没有 regcache 的变体里 rc_replaced 够不到任何输出')),

    ('M4', 'ShiftLoadDependency 忘了「本路唤醒自己就是某条 load 流水」那一位的常数 1',
     "      shift_iq_dep[q] = IQ_IS_LD_PIPE[w][q] ? LD_DEP_W'(1)\n"
     "                                            : LD_DEP_W'(dep[q] << 1);",
     "      shift_iq_dep[q] = LD_DEP_W'(dep[q] << 1);",
     lambda v: (any(v.iq_self_pipe),
                '没有哪一路 IQ 唤醒自己是 load 流水时，这一位本来就不是常数 1')),

    ('M5', 'LoadShouldCancel 只看 ld2Cancel 配 dep[1]，漏掉 ld1Cancel 配 dep[0]',
     "      ld_should_cancel |= (c1[q] & dep[q][0])\n"
     "                        | ((LD_DEP_W > 1) & c2[q] & dep[q][LD_DEP_W > 1 ? 1 : 0]);",
     "      ld_should_cancel |= ((LD_DEP_W > 1) & c2[q] & dep[q][LD_DEP_W > 1 ? 1 : 0]);",
     lambda v: (v.has_ld1,
                'golden 顶层没有 io_ldCancel_*_ld1Cancel 端口（矩阵 ldCancel_ld1=0），'
                'c1 恒 0，删掉这一项改不动任何行为 —— 这条要靠 Ldu/StaMou/StdMoud 去证')),

    ('M6', 'deqSuccess 忘了被 srcLoadCancel 门控 —— 被撤销的那拍仍当作发射成功清条目',
     "    deq_success    = resp_valid & (resp_bits == RESP_SUCCESS) & ~(|cur_ld_cancel);",
     "    deq_success    = resp_valid & (resp_bits == RESP_SUCCESS);",
     lambda v: (v.n_ld_cancel > 0, '没有 ldCancel 的变体里 cur_ld_cancel 恒 0')),

    ('M7', 'comp 条目的 canIssueBypass 没接上 —— 0 周期 IQ 唤醒的 uop 晚一拍才能发射',
     "  assign o_can_issue      = (IS_COMP ? (can_issue_plain | can_issue_bypass)\n"
     "                                     : can_issue_plain) & ~flushed;",
     "  assign o_can_issue      = can_issue_plain & ~flushed;",
     lambda v: (v.n_wk_iq > 0, 'canIssueBypass 只在有 IQ 唤醒时才与 canIssue 不同')),

    ('M8', 'commonOut.dataSources 漏掉 forward 那一档（本拍 IQ 唤醒的源仍报寄存器堆）',
     "      o_data_src[s] = (IS_COMP & (|wakeup_oh[s])) ? DS_FORWARD\n"
     "                    : use_rc_now                  ? DS_REGCACHE\n"
     "                                                  : cur_data_src[s];",
     "      o_data_src[s] = use_rc_now ? DS_REGCACHE : cur_data_src[s];",
     lambda v: (v.n_wk_iq > 0, 'forward 档只有 IQ 唤醒子族才出现')),

    ('M9', 'exuSources 记成「第几路唤醒」而不是「第几路唤醒 + 1」'
           '（golden 的 0 表示"还没被 IQ 唤醒过"）',
     "        if (wk_iq_oh[s][w]) iq_exu_code[s] |= EXU_W'(w + 1);",
     "        if (wk_iq_oh[s][w]) iq_exu_code[s] |= EXU_W'(w);",
     lambda v: (v.n_wk_iq > 0 and v.out_exu, '没有 exuSources 出口就看不见')),

    ('M10', 'deqPortIdx 只按「有没有 transEntry 出口」生成 —— 丢掉"双发射口时 '
            'comp 也要有"这一半，我第一次栽的方向',
     "    if (KEEP_WIDE || NUM_DEQ_PORTS > 1) begin : g_deq_port_idx",
     "    if (KEEP_WIDE) begin : g_deq_port_idx",
     lambda v: (v.n_deq == 2, '单发射口变体里 comp 本来就没有这个寄存器')),

    # ★ 结构型：UT 按构造看不见，靶子不拿它判 UT 的判别力 ★
    ('M13', 'deqPortIdx 只按发射口数生成 —— 反过来把 enq/simp 的也删了，'
            '我第二次栽的方向（UT 六轮全绿，是 FM 的 FM-036 Unknown name 抓出来的）',
     "    if (KEEP_WIDE || NUM_DEQ_PORTS > 1) begin : g_deq_port_idx",
     "    if (NUM_DEQ_PORTS > 1) begin : g_deq_port_idx",
     lambda v: (v.n_deq == 1,
                '双发射口变体里这个条件恒真，删掉 KEEP_WIDE 那一半不改变任何东西'),
     'structural'),

    ('M11', 'comp 条目入口的 srcLoadDependency 钉 0 —— '
            '同样是从 VfdivVidiv 外推出来的错结论',
     "      `IQE_MUX1H(x_ld_dep[e],       final_comp_sel[k][j], c_ld_dep[k],       NUM_ENQ)",
     "      x_ld_dep[e] = '0;",
     lambda v: (v.comp_has_ld_dep, 'comp 段本来就没有这组寄存器时，钉 0 是对的')),

    ('M14', 'transEntry 的 srcLoadDependency 送**寄存器原值**而不是移位后的次态 —— '
            '这是共享核里真实存在过的 bug（基线 f8bd195 就是这么写的）。'
            'golden 是 commonOut.transEntry…srcLoadDependency := common_srcLoadDependencyNext，'
            '基线送的是 r_ld_dep。VfdivVidiv 上整条影子恒 0 所以看不出来，'
            '有 ldCancel 的变体上就是转移下去的依赖少移一拍。',
     "  assign o_trans_ld_dep       = u_ld_dep;",
     "  assign o_trans_ld_dep       = r_ld_dep;",
     lambda v: (v.n_ld_cancel > 0,
                '没有 ldCancel 的变体里影子恒 0，寄存器原值与移位后的次态都是 0')),

    ('M12', 'issueResp 的 4 档常量表里，timer0 那档从 BLOCK 改成 SUCCESS',
     "        resp_bits_tab[d][k]  = OG_HAS_BITS[k] ? og_resp[k][d] : OG_CONST_RESP[k];",
     "        resp_bits_tab[d][k]  = OG_HAS_BITS[k] ? og_resp[k][d]\n"
     "                             : ((k == 0) ? RESP_SUCCESS : OG_CONST_RESP[k]);",
     lambda v: (True, 'issueResp 的 timer0 档每个变体都用')),
]


def run(cmd, cwd, env=None):
    return subprocess.run(cmd, cwd=str(cwd), env=env, shell=isinstance(cmd, str),
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('top', nargs='?', default='EntriesAluCsrFenceDiv')
    ap.add_argument('--cycles', type=int, default=30000,
                    help='每个变异跑多少拍（默认 30000，足够让所有闸都动起来）')
    ap.add_argument('--seed', type=int, default=1)
    ap.add_argument('--only')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--selftest-regcheck', action='store_true',
                    help='只跑寄存器双射核对的负测（证明那道闸会响）')
    a = ap.parse_args()

    if a.selftest_regcheck:
        return selftest_regcheck()

    if a.list:
        for m in MUTANTS:
            kind = m[5] if len(m) > 5 else 'behavioral'
            print(f'{m[0]} [{kind}]: {m[1]}')
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

    v0 = _gen.Variant(a.top)
    todo, na = [], []
    # kind: 'behavioral'（默认，UT 必须抓住）/ 'structural'
    #   ★ structural = 只改结构不改行为（例如删掉一个恒 0 的死寄存器）。
    #     任何基于仿真的测试**按构造**都看不见它 —— 拿它去判 UT 的判别力是错的。
    #     它的闸是 FM（FM-036 Unknown name / unmatched point），本轮 Vfdiv 回归
    #     正是这么抓到的。所以单列一桶，跑但不计入判别力分子分母。
    todo, na, struct = [], [], []
    for m in MUTANTS:
        if a.only and m[0] != a.only:
            continue
        ok, why = m[4](v0)
        kind = m[5] if len(m) > 5 else 'behavioral'
        if not ok:
            na.append((m, why))
        elif kind == 'structural':
            struct.append((m, why))
        else:
            todo.append((m, why))
    for m, why in na:
        print(f'[{m[0]}] N/A（本变体上这条变异是死的）: {why}')
    for m, why in struct:
        print(f'[{m[0]}] 结构型（UT 按构造看不见，闸在 FM）: {m[1]}')

    caught, escaped = [], []

    for m, _why in todo:
        mid, desc, old, new = m[0], m[1], m[2], m[3]
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

    print(f'\n变异判别力: 抓住 {len(caught)}/{len(todo)} 条适用的行为型变异'
          f'（{len(na)} 条在本变体上是死的记 N/A；'
          f'{len(struct)} 条是结构型、UT 按构造看不见，闸在 FM）')
    if escaped:
        print('逃逸清单（UT 在这些通路上没有判别力，必须先补激励/比对）:')
        for mid, desc in escaped:
            print(f'  {mid}: {desc}')
        return 1
    return 0




# ---------------------------------------------------------------------------
# 寄存器双射核对的负测 —— 闸必须证明它会响
#
# 本文件第一版把 ld1Cancel / og0Cancel 两行写成 (cond, cond)：拿同一个派生属性
# 跟自己比，恒真、永远不会响。跑基线全绿、看起来一切正常，是负测把它抓出来的。
# 所以这条负测跟着闸一起提交：闸改了必须重跑，它不响就是闸坏了。
#
#     python3 mutants.py --selftest-regcheck
# ---------------------------------------------------------------------------
def selftest_regcheck():
    import gen_fm_pins as P
    bad = []
    for top in ('EntriesAluCsrFenceDiv', 'EntriesVfdivVidiv'):
        v = _gen.Variant(top)
        if P.check_reg_bijection(v):
            bad.append(f'{top}: 基线就报错，闸本身有问题')
    v = _gen.Variant('EntriesAluCsrFenceDiv')
    # (属性, 注入值, 期望报出的关键字)
    cases = [('has_ld1', True, 'ld1Cancel'),
             ('n_deq', 1, 'deqPortIdx(comp)'),
             ('n_ld_cancel', 0, 'ld2Cancel'),
             ('comp_has_ld_dep', False, 'srcLoadDependency(comp)'),
             ('has_rc', False, 'useRegCache')]
    for attr, val, kw in cases:
        old = getattr(v, attr)
        setattr(v, attr, val)
        got = P.check_reg_bijection(v)
        setattr(v, attr, old)
        if not any(kw in g for g in got):
            bad.append(f'注入 {attr}={val} 后闸没响（期望提到 {kw}）—— 该条判据是空的')
    for b in bad:
        print('[FAIL] ' + b)
    print('regcheck 负测:', 'PASS' if not bad else 'FAIL')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
