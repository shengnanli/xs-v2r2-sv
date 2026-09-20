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

## ★ 本轮实测：UT 按构造看不见的那一类差异 ★

canary(`EntriesAluCsrFenceDiv`) 的 FM 从 1030 failing 收到 0，中间修掉的三个缺陷
**没有一个**是 UT 抓出来的。UT 当时的成绩是 3 seed × 2 initreg × 200k cycle、
23 条覆盖闸全部非零、`errors=0`。三个缺陷是同一个物种：
**golden 的不规则，被我抹成了规则。**

| # | 我写的 | golden | 为什么仿真看不见 | 真正的闸 |
|---|--------|--------|------------------|----------|
| 1 | 一组共享的 delay 寄存器 | **每个 enq 条目一组**（同源、逐拍逐位相同） | 两者是同一个函数，没有任何输入能把它们分开 | `gen_fm_pins.check_reg_bijection`（两侧 DFF 名单做差集）+ FM |
| 2 | 保留 `ld1Cancel` 项（`c1` 经寄存器） | 本变体**没有**这个端口 | `c1` 对本变体恒 0，多出来的是一条锥边，不是一个值 | 同上：差集里多出一个 impl-only 寄存器 |
| 3 | `dataSources` 出口写 `== DS_REG` | **`value[3]` 位测试** | 仅在非法编码 `4'b1001..1111` 上不同，而入队通路造不出这些编码 | FM failing points（实测 192 个）；靶子里记作 M15 |

**关键结论：这不是激励密度不够，加 seed / 加 cycle 一轮都救不回来。**
三条各自的不可达理由不同，但都不在仿真的输入分布里：

  1. 值恒等。两组寄存器在每一拍每一位都相等，差别只在**结构**（有几组），
     而结构从端口上观测不到。要区分它们，得观测寄存器的身份而不是它的值。
  2. ★常 0 的寄存器 ≠ 常量★。FM 不对寄存器做常量折叠：多一个寄存器就是多一条
     锥边，哪怕它恒 0。仿真只看值，值一样就一样。要让它非 0，需要的是**另一个
     有 ld1Cancel 端口的变体**，而不是本变体上跑更久。
  3. 差异集合与可达集合不相交。`dataSources` 的合法编码由入队通路决定，
     `4'b1001..1111` 永远不会出现；要让 UT 看见，UT 得去驱动一个违反入队契约的
     输入——那已经不是"测得更狠"，是测一个设计上不存在的场景。

所以这三条的闸**只能是 FM**，把它们记进 UT 的判别力分子分母是错的
（见下面 MUTANTS 里的 `structural` 桶）。反过来说：UT 的 `errors=0` 在它能看见的
范围内仍然有效，它证的是"可达行为等价"；FM 证的是"可证等价"。
★值恒等 ≠ 可证等价★——这一轮的三个缺陷就是这句话的三个实例。


## 用法

    python3 mutants.py EntriesAluCsrFenceDiv            # 全跑
    python3 mutants.py EntriesAluCsrFenceDiv --list     # 只列清单
    python3 mutants.py EntriesAluCsrFenceDiv --only M3  # 只跑一个
    python3 mutants.py EntriesAluCsrFenceDiv --cycles 40000

退出码 0 = 每个**计分的**变异都被抓住；非零 = 有变异逃逸，或出现了不计分但必须
有人处理的样本（基础设施失败 / 无效变异体）。

## 四个桶（0920 裁定后）

| 桶 | 什么情况 | 计分？ | rc |
|---|---|---|---|
| `caught`  | UT 报错/覆盖闸红；或**声明**了 COMPILE_FAIL 期望且确实编不过 | 分子+分母 | 0 |
| `escaped` | 变异注进去了、UT 没反应 —— UT 在那条路上是瞎的 | 分母 | ★非零★ |
| `infra`   | license / 磁盘 / 排队，或编不过却无 `Error-[` 无法归因 | **都不进** | ★非零★ |
| `invalid` | 真编译错但**没有**声明期望 ⇒ 没产生电路 | **都不进** | ★非零★ |

★`invalid` 是 0920 裁定新加的第三类，别把它并进 `caught`★：
变异体矩阵量的是 **UT 的判别力**。编不过意味着 UT 根本没跑，它对"UT 能不能抓住"
一个字都没证明；记成 caught 等于拿**工具链的能力**冒充 UT 的能力 —— 与 infra
灌水是同一个病，只是水源不同。它也和本仓既有规矩同源：「变异体必须先自证改变
了电路」——一个编不过的变异体**根本没有产生电路**，连自证的前提都不成立，
和逻辑等价的空变异一样，应当剔除并附理由（这里附的是**完整编译错误原文**，
那就是"靶子写错了"的直接证据）。
**不判 FAIL**：FAIL 留给"harness 本身坏了"；靶子写错了修靶子即可。

边界：某个靶子如果**故意**要测"这种写法会不会被工具链拦下"，给它第 7 元
`'compile_fail'`，它就走 `caught` —— 那是**声明了期望**的正常路径。

计分规则不会自己报警（分母悄悄变小只会让成绩变好看），所以它自带负测：
`python3 mutants.py --selftest-classify`（毫秒级，不占 VCS/license，含元负例）。
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
     lambda v: (v.n_wk_iq > 0 and v.iq_has_ld_dep,
                '要有 IQ 唤醒**而且** IQ 唤醒总线真的带 loadDependency，这条才活。'
                '★2026-09-20 实测更正★：原判据只写 v.n_wk_iq > 0，于是三个 Falu* 变体'
                '（n_wk_iq=3 但 iq_has_ld_dep=False）被判成"适用"，跑出来是"逃逸"。'
                '查下去是**空变异**：薄层把 .enq_ld_dep/.iq_ld_dep/.iqd_ld_dep 全接 \'0，'
                'golden Entries 顶层连一个 srcLoadDependency/loadDependency 端口都没有，'
                '所以 `x |= 0` 与 `x = 0` 在累加器本来就是 0 时完全一样。'
                '★不是推理，是 FM 证的★：把 M1 注进核跑 FM，'
                'passing 15934 / failing 0 / unread 0，与未变异逐个相同 ⇒ 电路没变。'
                '同源判据见 M2（它一开始就要求 n_wk_iq>0 and n_ld_cancel>0）。')),

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
     "      ld_should_cancel |= (HAS_LD1_CANCEL & c1[q] & dep[q][0])\n"
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

    ('M15', 'dataSources 出口用 `== DS_REG` 相等比较，而不是 golden 的 `value[3]` '
            '位测试 —— 两者只在非法编码 4\'b1001..1111 上不同，入队通路造不出这些'
            '编码，所以仿真永远看不出；FM 逐取值比就失配（实测 192 个点 = '
            '24 条目 × 2 源 × 4 位）',
     "      use_rc_now = HAS_REG_CACHE & cur_use_rc[s] & cur_data_src[s][3];",
     "      use_rc_now = HAS_REG_CACHE & cur_use_rc[s] & (cur_data_src[s] == DS_REG);",
     lambda v: (v.has_rc, '没有 regcache 的变体里 use_rc_now 恒 0，这条是死的'),
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


# ---------------------------------------------------------------------------
# 编译失败的三分类（0920 裁定）—— 抽成**纯函数**，这样它的负测不用占 VCS/license
#
#   'caught'  仅当本靶子**声明**了 expect_compile_fail：编不过是它的正常路径
#   'invalid' 真编译错但没声明期望 ⇒ ★无效变异体：没产生电路，分子分母同时剔除★
#   'infra'   license / 磁盘 / 排队等与变异无关的失败，或编不过却无 Error-[ 无法归因
#
# 为什么 'invalid' 不是 caught：变异体矩阵量的是 **UT 的判别力**；编不过意味着
# UT 根本没跑，它对"UT 能不能抓住"一个字都没证明。记成 caught 是拿工具链的能力
# 冒充 UT 的能力 —— 与 infra 灌水同病，只是水源不同。
# 为什么 'invalid' 不判 FAIL：FAIL 留给"harness 本身坏了"；靶子写错了修靶子即可。
# ---------------------------------------------------------------------------
INFRA_SIGS = ('License', 'license', 'LMGRD', 'Cannot connect',
              'No such feature', 'No space left')


def classify_compile_failure(out, expect_compile_fail=False):
    infra_sig = any(s in out for s in INFRA_SIGS) or (
        'queue' in out.lower() and 'lic' in out.lower())
    real_err = 'Error-[' in out
    if infra_sig or not real_err:
        return ('infra', 'license/基础设施' if infra_sig
                else '编译失败但无 Error-[，无法归因')
    if expect_compile_fail:
        return ('caught', 'compile-fail(符合声明的期望)')
    return ('invalid', '编不过，未产生电路')


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
    ap.add_argument('--check', action='store_true',
                    help='只做静态自检：锚点唯一命中 + 每条适用性判据可求值。'
                         '便宜，适合进门禁；真跑变异很贵。')
    ap.add_argument('--selftest-check', action='store_true',
                    help='负测 --check 本身：注入锚点漂移/判据引用空字段，要求都被抓住。'
                         '★一道门禁如果注入故障也不报警，它的 rc=0 没有意义★')
    ap.add_argument('--selftest-regcheck', action='store_true',
                    help='只跑寄存器双射核对的负测（证明那道闸会响）')
    ap.add_argument('--selftest-classify', action='store_true',
                    help='负测编译失败三分类（0920 裁定）。不占 VCS/license，毫秒级。'
                         '★"无效变异体不计分"这条规矩本身也要能证明自己在工作★')
    a = ap.parse_args()

    if a.selftest_check:
        # 与 --selftest-regcheck 同一个道理：门禁必须先证明自己会响。
        import contextlib, io
        orig = list(MUTANTS)
        def _run():
            g = globals()
            saved, g['_ns'] = None, None
            sys.argv = ['mutants.py', a.top, '--check']
            with contextlib.redirect_stderr(io.StringIO()) as e, \
                 contextlib.redirect_stdout(io.StringIO()):
                rc = main()
            return rc, e.getvalue().strip()
        cases, fails = [], 0
        g = globals()
        g['MUTANTS'] = orig
        cases.append(('baseline 未注入', 0, _run()[0]))
        b = list(orig[0]); b[2] = b[2] + ' /* drifted */'
        g['MUTANTS'] = [tuple(b)] + orig[1:]
        cases.append(('注入 锚点漂走', 1, _run()[0]))
        b = list(orig[0]); b[4] = lambda v: (v.no_such_field, 'x')
        g['MUTANTS'] = [tuple(b)] + orig[1:]
        cases.append(('注入 判据引用空字段', 1, _run()[0]))
        g['MUTANTS'] = orig
        cases.append(('还原', 0, _run()[0]))
        for name, want, got in cases:
            ok = want == got
            fails += not ok
            print(f'  {name:24s} rc={got} 期望 {want}  {"OK" if ok else "★FAIL★"}')
        print(f'check 负测: {"PASS" if not fails else "FAIL"}')
        return 1 if fails else 0

    if a.check:
        # ★为什么单列一个便宜的自检★
        # 下面那道锚点检查在 --list 的提前 return 之后，只有"真跑变异"才会走到，
        # 而真跑一轮很贵。结果就是：核一改，锚点可能已经漂走好几天没人知道，
        # 期间"变异没注进去"会被读成"UT 抓住了"——靶子自己变成空转。
        # 实测踩到过：修缺陷#2（给 ld1Cancel 项加 HAS_LD1_CANCEL 门）那一刻，
        # M5 的锚点当场失效，0 命中。所以把它做成 O(ms) 的独立门禁。
        core_txt = CORE.read_text()
        bad = [m[0] for m in MUTANTS if core_txt.count(m[2]) != 1]
        v0 = _gen.Variant(a.top)
        undef = []
        for m in MUTANTS:
            try:
                m[4](v0)
            except Exception as e:                       # 判据引用了不存在的字段
                undef.append(f'{m[0]}:{e}')
        if bad or undef:
            if bad:
                sys.stderr.write(f'[FAIL] 锚点在核里找不到或不唯一: {bad}\n')
            if undef:
                sys.stderr.write(f'[FAIL] 适用性判据求值失败: {undef}\n')
            return 1
        print(f'mutants --check: {len(MUTANTS)} 条锚点全部唯一命中，'
              f'适用性判据全部可求值 ({a.top})')
        return 0

    if a.selftest_classify:
        return selftest_classify()

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

    # caught/escaped 计分；infra（基础设施失败）与 invalid（编不过、未产生电路）
    # 都**不计分**，但都让整体 rc 非零 —— 不计分不等于可以忽略。
    caught, escaped, infra, invalid = [], [], [], []

    for m, _why in todo:
        mid, desc, old, new = m[0], m[1], m[2], m[3]
        # 第 7 元（可选）= 'compile_fail'：本靶子**声明**它期望编不过。
        expect_compile_fail = (len(m) > 6 and m[6] == 'compile_fail')
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
                # ★这里原先是 fail-open★
                #   原写法把"编不过"一律算作"被抓住"，理由是变异确实改变了行为。
                #   但**基础设施失败也编不过**：VCS license 抢不到、磁盘满、
                #   工具排队超时——这些与变异无关，却会被记成一次成功的判别，
                #   把靶子的分子凭空抬高。实测触发条件很常见：靶子和正跑的 UT
                #   并行时就在抢同一批 license。
                #   所以改成三分：真编译错(有 Error-[ 且非 license 类) 才算抓住；
                #   基础设施失败单列 infra 桶，并让整体 rc 非零（必须重跑），
                #   绝不静默计入。
                out = r.stdout.decode('utf-8', 'replace') if r.stdout else ''
                kind, why_c = classify_compile_failure(out, expect_compile_fail)
                if kind == 'caught':
                    # ★边界（0920 裁定）★：**声明了** COMPILE_FAIL 期望的靶子——
                    # 它测的就是"这种写法会不会被工具链拦下"（如 elaborate 期位宽
                    # 不变式），编不过是它的正常路径，照常计分。
                    caught.append((mid, why_c))
                    print(f'[{mid}] 抓住 (编译失败, 正是本靶子声明的期望): {desc}')
                elif kind == 'invalid':
                    # ★0920 裁定：真编译错**不算 caught**，也不判 FAIL，而是第三类
                    #   「无效变异体」——分子分母同时剔除。★
                    #   理由：变异体矩阵量的是 **UT 的判别力**。编不过意味着 UT
                    #   根本没跑，它对"UT 能不能抓住"一个字都没证明；记成 caught
                    #   是拿**工具链的能力**去冒充 UT 的能力，与 infra 灌水同病，
                    #   只是水源不同。
                    #   而且它与本仓既有规矩同源：「变异体必须先自证改变了电路」——
                    #   一个编不过的变异体**根本没有产生电路**，连自证的前提都不成立,
                    #   和逻辑等价的空变异一样，应当剔除并附理由。
                    errs = [l for l in out.split('\n') if 'Error-[' in l]
                    invalid.append((mid, desc, errs, out))
                    print(f'[{mid}] ★无效变异体（编不过，未产生电路）—— '
                          f'分子分母同时剔除★: {desc}')
                    for l in errs[:3]:
                        print(f'        {l.strip()}')
                else:
                    infra.append((mid, why_c))
                    print(f'[{mid}] ★基础设施失败，不计入判别力★（{why_c}）: {desc}')
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

    # ★分母★：适用的行为型变异，减去两类"根本没证过任何事"的
    #   —— infra（没跑成）与 invalid（没产生电路）。两者都不许留在分母里，
    #   否则 "抓住 N/M" 里的 M 是虚的。
    scored = len(todo) - len(infra) - len(invalid)
    print(f'\n变异判别力: 抓住 {len(caught)}/{scored} 条适用的行为型变异'
          f'（{len(na)} 条在本变体上是死的记 N/A；'
          f'{len(struct)} 条是结构型、UT 按构造看不见，闸在 FM；'
          f'{len(infra)} 条基础设施失败、不计分）')
    print(f'无效变异体（编不过，未产生电路）: {len(invalid)}'
          + ('  ← 分子分母同时剔除，须修靶子后重跑' if invalid else ''))
    rc = 0
    if invalid:
        # 0920 裁定：不判 FAIL（FAIL 留给"harness 本身坏了"），但 rc 非零 ——
        # 靶子写错了要有人去修，不能静默。这里**记录完整编译错误原文**，
        # 因为它就是"这个靶子写错了"的直接证据。
        print('★无效变异体明细（编译错误原文；这是靶子写错了的直接证据）:')
        for mid, desc, errs, out in invalid:
            print(f'  {mid}: {desc}')
            for l in errs:
                print(f'      {l.rstrip()}')
            if not errs:
                print('      （无 Error-[ 行，见下方原始输出尾部）')
                print('      ' + out.strip()[-500:].replace('\n', '\n      '))
        rc = 1
    if infra:
        # 不计分不等于可以忽略：没跑成就是没证过，必须重跑，否则"抓住 N/N"
        # 是在一个被悄悄缩小的分母上得到的。
        print('★基础设施失败（未证明任何事，必须重跑这几条）:')
        for mid, why in infra:
            print(f'  {mid}: {why}')
        rc = 1
    if escaped:
        print('逃逸清单 —— ★先别急着说"UT 瞎了"★:')
        print('  本仓规矩是「变异体必须先自证改变了电路」。逃逸有两种，处置完全相反：')
        print('   (a) 变异真的改了电路、UT 没看见 ⇒ UT 在那条通路上没判别力，补激励/比对；')
        print('   (b) ★变异根本没改电路（空变异）⇒ 是 applicability 判据写松了，改判据★。')
        print('  判别方法（便宜且可复核）：把该变异注进核跑一次 FM。')
        print('    FM 与未变异**逐个相同**（passing/failing/unread）⇒ 电路没变 ⇒ (b)；')
        print('    FM 出现 failing/点数变化                        ⇒ 电路变了 ⇒ (a)。')
        print('  2026-09-20 实测过一次 (b)：M1 在三个 Falu* 上"逃逸"，FM 证明是空变异，')
        print('  修的是 M1 的判据（加 iq_has_ld_dep），不是 UT。')
        for mid, desc in escaped:
            print(f'  {mid}: {desc}')
        rc = 1
    return rc




# ---------------------------------------------------------------------------
# 编译失败三分类的负测（0920 裁定配套）
#
# 这条规矩改的是**计分**——分子分母同时剔除一类样本。计分规则出错不会报警，
# 只会让"抓住 N/M"悄悄变好看，所以它必须自带负测，而且要有元负例：
# 把判据变成"什么都算 caught"，正例必须转红。
#
#     python3 mutants.py --selftest-classify
# ---------------------------------------------------------------------------
def selftest_classify():
    VCS_ERR = "Error-[SE] Syntax error\n  Following verilog source has syntax error :\n"
    LIC_ERR = "Error-[LIC] License checkout failed\n  Cannot connect to License Server\n"
    QUIET   = "make: *** [simv] Error 1\n"        # 编不过但没有 Error-[

    cases = [
        # (名字, out, 声明期望编不过?, 期望分类, 这一例证明了什么)
        ('真编译错/未声明期望', VCS_ERR, False, 'invalid',
         '★裁定的正例：不许记成 caught★'),
        ('真编译错/声明了期望', VCS_ERR, True,  'caught',
         '边界：声明了 COMPILE_FAIL 的靶子照常计分'),
        ('license 失败',        LIC_ERR, False, 'infra',
         'license 里也含 Error-[，不许被当成无效变异体'),
        ('license 失败/声明期望', LIC_ERR, True, 'infra',
         '★声明了期望也不能把 license 失败洗成 caught★'),
        ('编不过但无 Error-[',  QUIET,   False, 'infra',
         '无法归因的一律进 infra，不许猜'),
    ]
    rc = 0
    print('mutants --selftest-classify:')
    for name, out, exp_cf, want, why in cases:
        got, _ = classify_compile_failure(out, exp_cf)
        ok = got == want
        rc |= 0 if ok else 1
        print(f'  {name:22s} -> {got:8s} 期望 {want:8s} {"OK" if ok else "★FAIL★"}   {why}')

    # ★元负例★：把判据换成"什么都算 caught"，上面第一行必须转红。
    # 没有这一行，前五行在一个 `return ("caught", ...)` 的假判据上**同样可能全绿**。
    g = globals()
    real = g['classify_compile_failure']
    g['classify_compile_failure'] = lambda out, e=False: ('caught', 'blanket')
    got, _ = classify_compile_failure(VCS_ERR, False)
    g['classify_compile_failure'] = real
    meta_ok = (got != 'invalid')
    rc |= 0 if meta_ok else 1
    print(f'  {"meta_blanket":22s} -> {got:8s} '
          f'{"PASS（判据被换掉后正例确实转红）" if meta_ok else "★FAIL：判据恒绿，上面五行什么也不证明★"}')
    print('classify 负测:', 'PASS' if rc == 0 else 'FAIL')
    return rc


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
             ('has_rc', False, 'useRegCache'),
             ('n_enq', 1, '打拍'),          # 打拍寄存器份数 != NUM_ENQ
             ('n_ld_cancel', 2, 'ld2Cancel')]
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
