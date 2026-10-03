#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— 给 OthersEntry* 的 UT 做「判别力」证明。

## 为什么要有它

`errors=0` 本身不是证据：**一个 UT 如果把 bug 注进去也不报错，它的 errors=0 没有意义。**
逐拍比对只保证「两侧一样」，保证不了「激励真把逻辑推到了那个状态」；覆盖闸守得住
「推到过」，守不住「推到了而且比对真的看得见」。所以再加一道：往可读核里注入若干个
**真实形态**的 bug，跑同一个 UT，要求每一个都被抓出来。注入在**临时拷贝**上做，
仓里的 RTL 一个字节都不动。

## 靶子从哪来

1. **家族共享的那批**直接从 `verif/ut/Entries_common/mutants.py` 的 `MUTANTS` 导入。
   理由：OthersEntry 的核体就是 `xs_iq_entry`，与 Entries* 家族**同一份**；
   在那边算「真实形态的 bug」的写法，在这边一字不差还是同一处代码。
   自己抄一份等于把靶子也复制一遍，以后两边各改各的。
   适用性判据是 `lambda v -> (适用?, 理由)`，v 就是 `entries_gen.Variant`，
   而 `OthersVariant.v` 正是它，可以直接喂进去。

2. **本 lane 新加的那批（D*）**针对 `HAS_DBG_OUT` 打开的 7 组 debug/perf 出口。
   那段代码是本 lane 往共享核里加的，Entries 侧的靶子一条也覆盖不到它
   （那边 HAS_DBG_OUT=0，整段被钉成常数 0）——新加的代码必须有自己的靶子，
   否则「12 个变体 UT 全绿」里有一段是没被验过判别力的。

## 三分桶（与 Entries 侧同规矩）

* `behavioral` —— UT 必须抓住；逃逸 = UT 在那条通路上是瞎的，判 fail。
* `structural` —— 只改结构不改行为（例如删掉一个恒 0 的死寄存器）。
  任何基于仿真的测试**按构造**都看不见，拿它判 UT 判别力是错的：跑但不计分子分母，
  闸在 FM。
* `N/A` —— 在本变体上这条变异是死的（判据必须是从 golden 量出来的变体字段，
  不许拍脑袋写 True）。不计分子分母。
* 另有 `infra` 桶：license / 磁盘一类失败与变异无关，不计分，但让整体 rc 非零
  （没跑成就是没证过，必须重跑）。
* ★编译不过★：真编译错（有 `Error-[` 且非 license 类）说明变异**没有产生电路**，
  UT 根本没跑 —— 按 0920 裁定记「无效变异体」，既不计 caught 也不进分母。

## 用法

    python3 mutants.py OthersEntry_72              # 全跑
    python3 mutants.py OthersEntry_72 --list       # 只列清单
    python3 mutants.py OthersEntry_72 --only D1
    python3 mutants.py OthersEntry_72 --cycles 40000

退出码 0 = 每个适用的行为型变异都被抓住。
"""
import argparse, os, pathlib, re, shutil, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
CORE = REPO / 'rtl' / 'backend' / 'xs_iq_entries_core.sv'
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(REPO / 'verif' / 'ut' / 'Entries_common'))
from othersentry_gen import OthersVariant                      # noqa: E402
from mutants import MUTANTS as SHARED_MUTANTS                  # noqa: E402  (Entries 侧)

# ---------------------------------------------------------------------------
# 本 lane 新加的 §2.8 debug/perf 出口专属靶子。
# 每一条都对应一个**真实的写错方式**：都是我在照着
# EntryBundles.scala:476-483 逐句翻的时候真有可能写错的那一步。
# ---------------------------------------------------------------------------
DBG_MUTANTS = [
    ('D1', 'perfLdCancel 只看 cur_ld_cancel，漏掉 ld_trans_cancel —— '
           'golden 的 srcCancelVec 是 srcLoadTransCancelVec | srcLoadCancelVec '
           '(EntryBundles.scala:198-202)，只写后一项是照着名字想当然的头号写法',
     "        assign o_dbg_perf_ld_cancel[s]    = (ld_trans_cancel[s] | cur_ld_cancel[s])\n"
     "                                          & valid_reg;",
     "        assign o_dbg_perf_ld_cancel[s]    = cur_ld_cancel[s] & valid_reg;",
     lambda ov: (ov.v.n_wk_iq > 0 and ov.n_ld_cancel > 0,
                 '要同时有 IQ 唤醒（ld_trans_cancel 才可能非 0）和 ldCancel')),

    ('D2', 'perfWakeupByWB 漏掉 isBusy(srcState) 门控 —— '
           '变成「WB 命中就计数」，而 golden 只算「把一个未就绪的源翻成就绪」',
     # 锚点跟着核走：核在 EnqEntry 修复（currentStatus 门控）后读的是 cur_src_state
     "        assign o_dbg_perf_wakeup_by_wb[s] = wk_hit[s]\n"
     "                                          & (cur_src_state[s] == SRC_BUSY)\n"
     "                                          & valid_reg;",
     "        assign o_dbg_perf_wakeup_by_wb[s] = wk_hit[s] & valid_reg;",
     lambda ov: (True, '每个变体都有 WB 唤醒')),

    ('D3', 'perfOg0Cancel 用 wk_iq_oh（已去掉取消那份）而不是 wakeup_oh —— '
           '那样 ButCancel 恒 0，这个计数器永远不动',
     "        assign o_dbg_perf_og0_cancel[s]   = (|(wakeup_oh[s] & iq_cancel)) & valid_reg;",
     "        assign o_dbg_perf_og0_cancel[s]   = (|(wk_iq_oh[s] & iq_cancel)) & valid_reg;",
     lambda ov: (ov.v.n_wk_iq > 0, '没有 IQ 唤醒的变体里这一组 golden 根本没有端口')),

    ('D4', 'entryOutTransValid 漏掉 !(flushed || deqSuccess) —— '
           '冲刷/发射成功的那一拍会被当成「转移走了」',
     "      assign o_dbg_entry_out_trans_valid = valid_reg & trans_sel\n"
     "                                         & ~(flushed | deq_success);",
     "      assign o_dbg_entry_out_trans_valid = valid_reg & trans_sel;",
     lambda ov: (ov.is_trans, 'comp 没有 transSel，golden 也没有这个端口')),

    ('D5', 'entryOutDeqValid 漏掉 validReg 门控 —— 空条目上的冲刷也会报一次出队',
     "      assign o_dbg_entry_out_deq_valid   = valid_reg & (flushed | deq_success);",
     "      assign o_dbg_entry_out_deq_valid   = (flushed | deq_success);",
     lambda ov: (True, '每个变体都有这个端口')),

    ('D6', 'perfWakeupByIQ 漏掉 validReg 门控',
     "        assign o_dbg_perf_wakeup_by_iq[s] = wk_iq_oh[s] & {IQW{valid_reg}};",
     "        assign o_dbg_perf_wakeup_by_iq[s] = wk_iq_oh[s];",
     lambda ov: (ov.v.n_wk_iq > 0, '没有 IQ 唤醒的变体里这一组 golden 根本没有端口')),

    ('D7', 'entryInValid 接成「入队且条目空」而不是直接 enq.valid',
     "      assign o_dbg_entry_in_valid        = enq_valid;",
     "      assign o_dbg_entry_in_valid        = enq_valid & ~valid_reg;",
     lambda ov: (True, '每个变体都有这个端口')),

    # ---- 向量专属：ignoreOldVd（§2.3 / §2.5）----
    # ★ 这条通路在 INT/FP 那 12 个变体上整条是死的（HAS_IGNORE_OLD_VD=0），
    #   也就是说前 12 个变体的 14/14 与 13/13 **一个字都没覆盖到它**。
    #   VEC 族是本核里第一次真正走这条路的，必须给它自己的靶子，
    #   否则「6 个向量变体全绿」里有一段没被验过判别力。
    ('V1', 'ignoreOldVd 少了「vl 不为 0」那一项 —— golden 要求 vl 被写回唤醒**且** '
           'vl 非 0；写成只看唤醒，vl==0 时会错误地把旧 vd 判成可忽略',
     "        & ((~vl_int_is_zero & vl_wk_int) | (~vl_vf_is_zero & vl_wk_vf))",
     "        & (vl_wk_int | vl_wk_vf)",
     lambda ov: (ov.v.has_ignore, '非向量变体 HAS_IGNORE_OLD_VD=0，整条通路是死的')),

    ('V2', 'ignoreOldVd 忘了 ~isDependOldVd 门控 —— 明确依赖旧 vd 的指令也被判成可忽略',
     "        & ~pl_depend_oldvd",
     "        & 1'b1",
     lambda ov: (ov.v.has_ignore, '非向量变体这条通路是死的')),

    ('V3', 'ignoreOldVd 后忘了把 srcType 清 0（golden：旧 vd 不再算源）',
     "      u_src_type[s]  = is_vd ? 4'h0 : r_src_type[s];",
     "      u_src_type[s]  = r_src_type[s];",
     lambda ov: (ov.v.has_ignore, '非向量变体 is_vd 恒 0，改了等于没改')),
]


# ---------------------------------------------------------------------------
# ★ 空变异（逻辑等价）清单 —— 从分子分母**同时**剔除，并注明理由 ★
#
# 有一类变异在本族上「改了源码但没改电路」：改掉的两个表达式在 OthersEntry 的参数
# 组合下是**同一根网**。这种变异逃逸不说明 UT 瞎，它根本没造出可观测差异。
# 按规矩：既不计 caught 也不进分母，但理由必须是**从代码里读得出来的**，
# 不许拿"我觉得等价"搪塞。每条都带一个 `proof` 闭包，跑的时候真去核对源码。
#
# ★为什么不干脆删掉这两条★ 它们在 Entries 家族（enq 条目 / simp 条目）上是活的，
# 共享靶子表必须原样导入；在这里逐条标注，比在那边删掉安全。
# ---------------------------------------------------------------------------
def _null_m3(ov, core):
    """M3: replaceRC 比 cur_rc_idx vs r_rc_idx。
    核里 cur_rc_idx[s] 先无条件赋成 r_rc_idx[s]，只在 `if (dly)` 里被改写，
    而 dly = IS_ENQ & enqd_valid_reg。OthersEntry 一律 IS_ENQ=0 ⇒ dly 恒 0
    ⇒ 两者是同一根网，改了等于没改。"""
    ok = ('      dly = IS_ENQ & enqd_valid_reg;' in core
          and '      cur_rc_idx[s]  = r_rc_idx[s];' in core)
    return ok, ('IS_ENQ=0 ⇒ dly 恒 0 ⇒ cur_rc_idx ≡ r_rc_idx'
                if ok else '源码里找不到 dly/cur_rc_idx 的那两行，空变异判定失效')


def _null_m14(ov, core):
    """M14: o_trans_ld_dep 送 u_ld_dep vs r_ld_dep。
    comp 条目（IS_TRANS=0）的 wrapper 根本不接 o_trans_*（golden 也没有
    transEntry 端口），这根输出悬空，改它改不动任何可观测量。simp 上是活的。"""
    return (not ov.is_trans), 'comp 不接 o_trans_ld_dep（golden 无 transEntry 端口），输出悬空'



# ★ 下面三条：锚点里的分支条件在 simp 上是常量，删掉整条分支与不删完全一样 ★
#   对 comp 它们都是活靶子（OthersEntry_72 上 M7/M8/M10 三条全被抓住），
#   所以不能从共享表里删掉，只能按角色标成空变异。
def _null_m7(ov, core):
    live = not ov.is_trans          # comp 才活
    return (not live), 'simp 的 IS_COMP=0 ⇒ (IS_COMP ? A : can_issue_plain) ≡ can_issue_plain'


def _null_m8(ov, core):
    live = not ov.is_trans
    return (not live), 'simp 的 IS_COMP=0 ⇒ (IS_COMP & …) ? DS_FORWARD : X ≡ X'


def _null_m10(ov, core):
    # KEEP_WIDE = IS_ENQ | IS_TRANS；simp 的 IS_TRANS=1 ⇒ KEEP_WIDE=1
    # ⇒ (KEEP_WIDE || NUM_DEQ_PORTS>1) ≡ KEEP_WIDE，把后半删掉不改变生成条件。
    return ov.is_trans, 'simp 的 KEEP_WIDE=1 ⇒ (KEEP_WIDE || NUM_DEQ_PORTS>1) ≡ KEEP_WIDE'


NULL_MUTANTS = {'M3': _null_m3, 'M14': _null_m14,
                'M7': _null_m7, 'M8': _null_m8, 'M10': _null_m10}



# ---------------------------------------------------------------------------
# ★判据也要先自证「它读的是对的那一行」★
# （CONVENTIONS 2026-09-20，TlbStorageWrapper 实测：
#   `grep -oP 'errors=\\K\\d+' | head -1` 取到的是日志**第一行**的 errors=0，
#   于是"抓到了也报成没抓到"，五个变异体的结论全反了。）
#
# 本 tb 的日志里 `errors=` 会出现两次（末尾汇总一次、TEST FAILED 那行再一次），
# 用裸 `re.search` 取的是第一个 —— 恰好是对的那个，但这属于"碰巧"。
# 这里把解析抽成函数并**取最后一次出现**，再配自测把两种坑都钉住。
# ---------------------------------------------------------------------------
def parse_sim_errors(log):
    """返回 (errors, 是否判失败)。errors 取日志里**最后一次** errors= 的值。"""
    ms = re.findall(r'errors=(\d+)', log)
    errs = int(ms[-1]) if ms else -1
    failed = ('TEST FAILED' in log) or errs > 0 or errs < 0
    return errs, failed


def selftest_parse():
    cases = [
        ('正例：只有末尾汇总一行',
         '=== 200000 cycles, checks=15399230, errors=0 ===\nTEST PASSED\n', 0, False),
        ('★多行 errors=：必须取最后一次，不是第一次★',
         'directed warmup: errors=0\n=== 200000 cycles, checks=1, errors=42 ===\n'
         'TEST FAILED (errors=42 cov_fail=0 checks=1)\n', 42, True),
        ('★首行是 0、真值在后面：裸 head -1 会在这里翻车★',
         'errors=0\nerrors=0\n=== errors=7 ===\nTEST FAILED (errors=7 ...)\n', 7, True),
        ('覆盖闸红但 errors=0：也必须判失败',
         '=== 200000 cycles, checks=1, errors=0 ===\n'
         '  *** COVERAGE HOLE: wb_wake = 3 < 3996\n'
         'TEST FAILED (errors=0 cov_fail=1 checks=1)\n', 0, True),
        ('日志里根本没有 errors=（仿真崩了）：必须判失败，不能当成 0',
         'Error-[SOMETHING] crashed\n', -1, True),
    ]
    rc = 0
    print('mutants --selftest-parse:')
    for name, log, want_e, want_f in cases:
        e, f = parse_sim_errors(log)
        ok = (e == want_e) and (f == want_f)
        print(f'  [{"OK" if ok else "FAIL"}] {name} -> errors={e} failed={f}'
              f'（期望 {want_e}/{want_f}）')
        rc |= 0 if ok else 1
    print('解析器负测', 'PASS' if rc == 0 else 'FAIL')
    return rc


def run(cmd, cwd):
    return subprocess.run(cmd, cwd=str(cwd), stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('top', nargs='?')
    ap.add_argument('--only')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--selftest-parse', action='store_true')
    ap.add_argument('--seed', type=int, default=7)
    ap.add_argument('--cycles', type=int, default=60000)
    a = ap.parse_args()
    if a.selftest_parse:
        return selftest_parse()

    ov = OthersVariant(a.top)
    utdir = REPO / 'verif' / 'ut' / a.top
    core_txt = CORE.read_text()

    # 共享靶子的适用性判据吃 Variant；本 lane 的吃 OthersVariant。统一成 (id,desc,old,new,pred,kind)
    allm = [(m[0], m[1], m[2], m[3], (lambda f: (lambda o: f(o.v)))(m[4]),
             m[5] if len(m) > 5 else 'behavioral') for m in SHARED_MUTANTS]
    allm += [(m[0], m[1], m[2], m[3], m[4], 'behavioral') for m in DBG_MUTANTS]

    # 锚点必须还在且唯一 —— 核改过之后锚点会漂，那时「变异没注进去」会被
    # 误当成「UT 抓住了」。这一步也顺带证明本 lane 的核改动没有动到
    # Entries 侧那批靶子的锚点。
    missing = [m[0] for m in allm if core_txt.count(m[2]) != 1]
    if missing:
        sys.stderr.write(f'[FAIL] 锚点找不到或不唯一: {missing}\n')
        return 1

    # ★ 锚点在不在 xs_iq_entry 里 ★
    #   共享靶子里有几条打的是**阵列层** xs_iq_entries_core 的代码
    #   （例如 M12 的 issueResp 4 档常量表）。OthersEntry 的 wrapper 只例化
    #   xs_iq_entry，不例化阵列核 —— 那几条注进去等于没注，UT 当然抓不住。
    #   把它们记成「逃逸」是冤枉 UT；所以按**锚点所在模块**机械判定，
    #   不靠人去记哪条属于哪一层。
    ent_lo = core_txt.index('module xs_iq_entry\n')
    ent_hi = core_txt.index('endmodule : xs_iq_entry')

    def in_entry(anchor):
        i = core_txt.index(anchor)
        return ent_lo < i < ent_hi

    todo, na, struct, null = [], [], [], []
    for m in allm:
        if a.only and m[0] != a.only:
            continue
        if m[0] in NULL_MUTANTS:
            is_null, why = NULL_MUTANTS[m[0]](ov, core_txt)
            if is_null:
                null.append((m, why))
                continue
        if not in_entry(m[2]):
            na.append((m, '锚点在阵列层 xs_iq_entries_core 里，'
                          'OthersEntry 的 wrapper 只例化 xs_iq_entry，注进去等于没注'))
            continue
        ok, why = m[4](ov)
        if not ok:
            na.append((m, why))
        elif m[5] == 'structural':
            struct.append((m, why))
        else:
            todo.append((m, why))
    for m, why in na:
        print(f'[{m[0]}] N/A（本变体上这条变异是死的）: {why}')
    for m, why in struct:
        print(f'[{m[0]}] 结构型（UT 按构造看不见，闸在 FM）: {m[1]}')
    for m, why in null:
        print(f'[{m[0]}] ★空变异（逻辑等价，分子分母同时剔除）★: {why}')
    if a.list:
        for m, _ in todo:
            print(f'[{m[0]}] 待跑: {m[1]}')
        return 0

    caught, escaped, infra, invalid = [], [], [], []
    for m, _why in todo:
        mid, desc, old, new = m[0], m[1], m[2], m[3]
        work = pathlib.Path(tempfile.mkdtemp(prefix=f'xsv2-oemut-{mid}-'))
        try:
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
                out = r.stdout.decode('utf-8', 'replace') if r.stdout else ''
                infra_sig = any(s in out for s in
                                ('License', 'license', 'LMGRD', 'Cannot connect',
                                 'No such feature', 'No space left'))
                if 'Error-[' in out and not infra_sig:
                    # ★0920 裁定：编不过 = 没产生电路 = UT 根本没跑 = 无效变异体★
                    #   既不计 caught 也不进分母（旧写法把它算成「抓住」，是 fail-open）
                    invalid.append((mid, '真编译错：变异没有产生电路'))
                    print(f'[{mid}] ★无效变异体（编译失败，不计分子也不计分母）★: {desc}')
                else:
                    infra.append((mid, 'license/基础设施'))
                    print(f'[{mid}] ★基础设施失败，不计入判别力★: {desc}')
                continue
            run(['./simv', f'+ntb_random_seed={a.seed}',
                 f'+ncycles={a.cycles}', '-l', 'mut.log'], ut)
            log = (ut / 'mut.log').read_text(errors='replace')
            errs, failed = parse_sim_errors(log)
            hole = 'COVERAGE HOLE' in log
            if failed:
                why = f'errors={errs}' + (' + 覆盖闸红' if hole else '')
                caught.append((mid, why))
                print(f'[{mid}] 抓住 ({why}): {desc}')
            else:
                escaped.append((mid, desc))
                print(f'[{mid}] ★逃逸★ errors={errs}: {desc}')
        finally:
            shutil.rmtree(str(work), ignore_errors=True)

    scored = len(todo) - len(infra) - len(invalid)
    print(f'\n[{a.top}] 变异判别力: 抓住 {len(caught)}/{scored} 条适用的行为型变异'
          f'（N/A {len(na)}；空变异 {len(null)} 条已从分子分母剔除；'
          f'结构型 {len(struct)} 条闸在 FM；'
          f'无效变异体 {len(invalid)} 条；基础设施失败 {len(infra)} 条）')
    rc = 0
    if infra:
        print('★基础设施失败（未证明任何事，必须重跑）:')
        for mid, why in infra:
            print(f'  {mid}: {why}')
        rc = 1
    if escaped:
        print('逃逸清单（UT 在这些通路上没有判别力）:')
        for mid, desc in escaped:
            print(f'  {mid}: {desc}')
        rc = 1
    return rc


if __name__ == '__main__':
    sys.exit(main())
