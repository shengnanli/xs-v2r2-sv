#!/usr/bin/env python3
"""EnqEntry* 家族（14 变体）薄变体文件 + UT 生成器（共享库）。

===============================================================================
★ 开工前的判断：EnqEntry 与 OthersEntry 共用一个核吗？—— 共用，且核不必改 ★
===============================================================================

结论：**复用** `rtl/backend/xs_iq_entries_core.sv` 里的 `xs_iq_entry`，
本 lane **一个字都不改那个文件**（它同时被 agent/othersentry 与 agent/entries-rest3
在动）。EnqEntry* 只生成薄 wrapper：例化 `xs_iq_entry`，参数 `IS_ENQ=1`。

依据（全部是本 lane 自己量的，不是继承的数字）：

1. 端口差异只有一组，而且那一组核**已经有对应的输入端口**。
   `EnqEntry`(641 端口) vs `OthersEntry`(580 端口)，逐名 diff：
     只在 EnqEntry（+69）：`io_enqDelayIn1_*` 整组
         = wakeUpFromWB 4 路 ×3 + wakeUpFromIQ 7 路 ×(pdest/rfWen/rcDest/3×loadDep)
           + is0Lat 2 路 + og0Cancel{0,2,4,6} + ldCancel{0,1,2}_ld2Cancel
           + srcLoadDependency 2 源 ×3 流水
     只在 OthersEntry（−8）：`enq.bits.status` 的 blocked/issued/firstIssue/
         issueTimer/deqPortIdx/srcStatus_*_exuSources_value，以及 `commonOut.enqReady`
   其余 572 个端口逐名相同。
   而 `xs_iq_entry` 的端口表里**本来就有**这一组的收点：
     `wkd_valid/wkd_wen/wkd_pdest`、`iqd_wen/iqd_pdest/iqd_ld_dep/iqd_rc_dest/
      iqd_cancel`、`ld1d_cancel/ld2d_cancel`、`enqd_self_ld_dep`
   —— 核里注释写得很清楚「后者只有 IS_ENQ 用」。OthersEntry 的 wrapper 把它们钉 0，
   EnqEntry 的 wrapper 把它们接到 `io_enqDelayIn1_*`。**加线不改核。**

2. IS_ENQ 这条分支核里已经实现完了（不是留白）。逐条对着 golden 核过：
     core:638  `enq_ready = ~valid_reg | trans_sel;`
     golden EnqEntry.sv:1011
             `common_enqReady = ~validReg_last_REG | io_commonIn_transSel;`   同
     core:640  `load_now = IS_ENQ ? (enq_valid & enq_ready) : enq_valid;`
     core:732-734 装载时 issued=0 / firstIssue=0 / issueTimer=3（正是 golden
             EnqEntry 少掉那几个 enq.status 输入端口的原因）
     core:777  IS_ENQ 无 blocked 寄存器
     core:831  `g_enq_delay` —— 入队延迟窗口 `enqd_valid_reg`
   也就是说核里的 IS_ENQ 路径本来就是照着 golden EnqEntry 写的（Entries* 家族的
   9 个变体已签核，每个里面都例化着 NUM_ENQ 份 IS_ENQ=1 的条目）。
   本族做的是把同一份逻辑**单独封成 golden 同名模块**，而不是写新逻辑。

3. golden 侧 Chisel 本来就是一份逻辑两次单态化：`EnqEntry.scala` 与
   `OthersEntry.scala` 的模块体都只调 `EntryBundles` 的
   CommonWireConnect / EntryRegCommonConnect / CommonOutConnect，差别是 `isEnq`。
   （这条是 othersentry_gen.py 的开工判断，本 lane 复核过 Scala 仍如此。）

4. 参数表不必重量：`entries_gen.Variant` 的唤醒路由、og0 映射、负载偏移表
   **本来就是从 EnqEntry 量出来的**（Variant.__init__ 里 `ep = port_decls(self.enq_mod)`，
   `enq_mod` 就是本族的模块），OthersEntry 反倒是"借用"那份并逐条断言一致。
   所以本生成器用 `Variant(parent)` 是走回了数据的源头，不是二次外推。

结论的边界（诚实记下来，别让它被外推）：
  * 「核够用」是对**父级 Entries 变体已实现**的那 9 个 EnqEntry 说的
    （EnqEntry / _4 / _6 / _8 / _10 / _12 / _14 / _16 / _18）。
  * 另外 5 个（_20 StaMou / _24 Ldu / _30 StdMoud / EnqEntryVecMem* ）的父级
    Entries 变体本仓尚未实现，核 §11 明确列了它们缺的维度（isVecMemIQ 的
    blocked 真逻辑、needFeedBackSqIdx、bypass2 分支）。这 5 个**不在本 lane 范围**，
    要做必须先补核 —— 而补核要跨 lane 协调，不能在这里顺手改。

===============================================================================
★ 唯一的拦路石：核里有一行对 IS_ENQ 是错的（本 lane 不许改那个文件，已上报）★
===============================================================================

现象（本 lane 实测，EnqEntry 变体，seed=1，200k 拍）：
  逐拍比对 58,199,418 次，errors=2682，**全部集中在 io_commonOut_perfWakeupByWB_0/1
  这一组**，其余 640 个输出一个错都没有。

根因（逐字对着 golden）：
  golden EnqEntry.sv:3258
    assign io_commonOut_perfWakeupByWB_0 =
      (|_GEN) & ~currentStatus_srcStatus_0_srcState & validReg_last_REG;
                 ^^^^^^^^^^^^^ 用的是 **currentStatus**（入队延迟窗口打过补丁的那份）
  xs_iq_entries_core.sv §2.8
    assign o_dbg_perf_wakeup_by_wb[s] = wk_hit[s]
                                      & (r_src_state[s] == SRC_BUSY)   <- 裸寄存器
                                      & valid_reg;
  `(|_GEN)` 与核的 `wk_hit[s]` 同义（都是**当拍** WB 总线的命中向量，实测一致）；
  差别只在门控用的是 currentStatus 还是 entryReg。
  OthersEntry / Entries 上两者恒等（没有延迟窗口），所以这条错到今天才暴露。

需要的改动（一行）：
    -                                      & (r_src_state[s] == SRC_BUSY)
    +                                      & (cur_src_state[s] == SRC_BUSY)

对另外两条 lane 是 no-op，两重证据：
  (1) 结构上：core 里 `dly = IS_ENQ & enqd_valid_reg`，而 IS_ENQ=0 时
      `assign enqd_valid_reg = 1'b0`（g_no_enq_delay 支），故
      `cur_src_state[s] = dly ? (...) : r_src_state[s]` 常量折叠成 r_src_state[s]。
  (2) 实测：把补丁打在 scratch 副本上（仓库文件未动）重跑另外两条 lane 的既有 UT，
      OthersEntry / OthersEntry_6 / EntriesVfdivVidiv seed=1 全部 TEST PASSED。
  打上补丁后 EnqEntry 的 errors 2682 -> 0。

★ 本 lane 没有改 rtl/backend/xs_iq_entries_core.sv（它同时被 agent/othersentry 与
  agent/entries-rest3 在动）。这一行由谁来改、改在哪条分支上，需要上层协调。
  在它落地之前，本族 9 个变体的 UT/FM 都会且只会在 perfWakeupByWB 上红。★

===============================================================================

用法：
  python3 gen.py            # 生成
  python3 gen.py --check    # 只校验已提交产物没漂移（非零退出=漂移）
"""
import re, sys, pathlib

HERE   = pathlib.Path(__file__).resolve().parent
REPO   = HERE.parents[2]
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
sys.path.insert(0, str(REPO / 'verif' / 'ut' / 'Entries_common'))
from entries_gen import (Variant, port_decls, read, bitvec,   # noqa: E402
                          wenpack, wenvec)


# 父级 Entries 变体已在本仓实现、因而本 lane 敢做的那几个（见文件头「结论的边界」）。
IMPLEMENTED_PARENTS = {
    'EntriesAluMulBkuBrhJmp', 'EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v',
    'EntriesAluCsrFenceDiv', 'EntriesFaluFcvtF2vFmacFdiv', 'EntriesFaluFmacFdiv',
    'EntriesFaluFmac', 'EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf',
    'EntriesVfmaVialuFixVfalu', 'EntriesVfdivVidiv',
}


def parents():
    """EnqEntry 变体 -> (parent Entries 变体, 例化份数)。
    从 golden Entries*.sv 的 `enqEntries_<i>` 实例名反查，是角色的唯一权威依据。"""
    res = {}
    for f in sorted(GOLDEN.glob('Entries*.sv')):
        txt = f.read_text()
        for t, n in re.findall(r'^  ([A-Za-z]\w*) (enqEntries_\d+)\s*\(', txt, re.M):
            cur = res.setdefault(t, [f.stem, 0])
            assert cur[0] == f.stem, f'{t} 的父级不唯一'
            cur[1] += 1
    return {k: tuple(v) for k, v in res.items()}


class EnqVariant:
    def __init__(self, mod):
        self.mod = mod
        self.parent, self.count = parents()[mod]
        if self.parent not in IMPLEMENTED_PARENTS:
            sys.exit(
                f'{mod}: 父级 {self.parent} 在本仓尚未实现，'
                f'xs_iq_entries_core.sv §11 列的维度还缺 —— 不在本 lane 范围。')
        self.v = Variant(self.parent)          # 家族参数（含三模块一致性断言）
        v = self.v
        assert mod == v.enq_mod, f'{mod}: 与 Variant 里的 enq_mod {v.enq_mod} 对不上'
        self.ports = port_decls(mod)
        self.pmap  = {n: (d, w) for d, w, n, _ in self.ports}
        has = lambda n: n in self.pmap

        # ---- 角色断言：enq 条目「产出 transEntry 但自己不是 IS_TRANS」 ----
        # KEEP_WIDE = IS_ENQ | IS_TRANS，所以 enq 也存整包负载、也露 transEntry；
        # 但 trans_sel 对 enq 的意义是「我被搬走了」-> enqReady/clear，不是 IS_TRANS。
        assert has('io_commonOut_transEntry_valid'), f'{mod}: enq 条目竟无 transEntry'
        assert has('io_commonIn_transSel'), f'{mod}: enq 条目竟无 transSel'
        # ★ golden 的 EnqEntry 没有 commonOut.enqReady 端口（实测 14/14 都没有）：
        #   enqReady 在 Entries 那一层是由别处算的，条目内部只自用。核照样算，
        #   出口接悬空线。
        assert not has('io_commonOut_enqReady'), (
            f'{mod}: 竟然有 enqReady 端口 —— 与实测 14/14 都没有不符，先查清再动')
        # ★ 入队时被强制的那几个状态位，golden 上不该有对应输入端口 ★
        #   （core:732-734 把 issued/firstIssue/issueTimer 钉成 0/0/3，
        #     core:777 IS_ENQ 无 blocked 寄存器）
        for f in ('blocked', 'issued', 'firstIssue', 'issueTimer', 'deqPortIdx'):
            assert not has(f'io_commonIn_enq_bits_status_{f}'), (
                f'{mod}: 有 enq.status.{f} 输入 —— 与 IS_ENQ 的强制装载不符')

        # ---- 逐模块才会不同的那几样 ----
        self.has_ld_dep = has(
            'io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0')
        self.has_deq_port = has('io_commonOut_deqPortIdxRead')
        assert self.has_deq_port == (v.n_deq == 2), (
            f'{mod}: deqPortIdxRead={self.has_deq_port} 但父级 numDeq={v.n_deq}'
            ' —— 这条对应关系是矩阵实测的，不成立就说明有新维度')
        self.n_ld_cancel = sum(1 for n in self.pmap
                               if re.fullmatch(r'io_commonIn_ldCancel_\d+_ld2Cancel', n))
        self.has_ld1 = has('io_commonIn_ldCancel_0_ld1Cancel')
        assert self.has_ld1 == v.has_ld1, f'{mod}: ld1Cancel 与父级不一致'
        assert self.n_ld_cancel == v.n_ld_cancel, f'{mod}: ldCancel 条数与父级不一致'

        # ---- 入队延迟窗口（本族专属）----
        # 每一组都逐个量，不从「当拍那组有」推出「延迟那组也有」。
        self.dly_wb = sum(1 for n in self.pmap
                          if re.fullmatch(r'io_enqDelayIn1_wakeUpFromWB_\d+_valid', n))
        self.dly_iq = sum(1 for n in self.pmap
                          if re.fullmatch(r'io_enqDelayIn1_wakeUpFromIQ_\d+_bits_pdest', n))
        assert self.dly_wb == v.n_wk, (
            f'{mod}: 延迟 WB {self.dly_wb} 路 != 当拍 {v.n_wk} 路')
        assert self.dly_iq == v.n_wk_iq, (
            f'{mod}: 延迟 IQ {self.dly_iq} 路 != 当拍 {v.n_wk_iq} 路')
        self.dly_has_ld_dep = has('io_enqDelayIn1_wakeUpFromIQ_0_bits_loadDependency_0')
        self.dly_has_rc     = has('io_enqDelayIn1_wakeUpFromIQ_0_bits_rcDest')
        self.dly_n_ld_cancel = sum(
            1 for n in self.pmap
            if re.fullmatch(r'io_enqDelayIn1_ldCancel_\d+_ld2Cancel', n))
        self.dly_has_ld1 = has('io_enqDelayIn1_ldCancel_0_ld1Cancel')
        self.dly_self_ld = has('io_enqDelayIn1_srcLoadDependency_0_0')
        # 延迟侧 og0Cancel 的下标集合必须与当拍侧一致（两侧走同一张路由表）
        dly_og = {int(m.group(1)) for m in
                  (re.fullmatch(r'io_enqDelayIn1_og0Cancel_(\d+)', n) for n in self.pmap)
                  if m}
        cur_og = {v.og0_idx[w] for w in range(v.n_wk_iq) if v.og0_idx[w] is not None}
        assert dly_og == cur_og, (
            f'{mod}: 延迟侧 og0Cancel 下标 {sorted(dly_og)} != 当拍侧 {sorted(cur_og)}')

        # ---- 负载：条目自己的端口就是权威（Variant 量的正是本模块，必须相同）----
        def pl(pfx):
            return [(n[len(pfx):], w) for d, w, n, _ in self.ports if n.startswith(pfx)]
        deq_pl = pl('io_commonOut_entry_bits_payload_')
        if has('io_commonOut_entry_bits_imm'):
            deq_pl = [('#imm', self.pmap['io_commonOut_entry_bits_imm'][1])] + deq_pl
        assert deq_pl == v.pl_deq, f'{mod}: DEQ 负载字段与 Variant 的表不同'

    # ---- 端口名小工具 ----
    def has(self, n):
        return n in self.pmap

    def ipl(self, f):
        return ('io_commonIn_enq_bits_imm' if f == '#imm'
                else f'io_commonIn_enq_bits_payload_{f}')

    def opl(self, which, f):
        pfx = 'entry' if which == 'deq' else 'transEntry'
        return (f'io_commonOut_{pfx}_bits_imm' if f == '#imm'
                else f'io_commonOut_{pfx}_bits_payload_{f}')


# =============================================================================
def gen_rtl(ov):
    v, L = ov.v, []
    A = L.append
    n_src, n_wk, n_iq = v.n_regsrc, v.n_wk, v.n_wk_iq
    nfu = len(v.fu_bits)

    A(f'// {ov.mod}.sv —— 发射队列**入队条目**（{ov.parent[len("Entries"):]} 变体）薄包装层')
    A('// -----------------------------------------------------------------------------')
    A('// 核体见 xs_iq_entries_core.sv 的 `xs_iq_entry`（Entries*/OthersEntry*/EnqEntry*')
    A('// 三族共享的参数化单条目核）。本文件不含逻辑分支，只做端口摊平 + 设参数。')
    A('//')
    A('// 在流水线里的位置：派遣(dispatch)来的新 uop 落在**入队条目**上。它与其它条目')
    A('// 的三处差别（核里由 IS_ENQ=1 表达）：')
    A('//   1) 装载条件带 enqReady（= 本条目空 或 本拍正被搬走）；')
    A('//   2) 装载时 issued=0 / firstIssue=0 / issueTimer=3 强制写入，而不是从上一级')
    A('//      的 transEntry 继承 —— 所以 golden 这个模块没有 enq.status.issued 等端口；')
    A('//   3) 多一拍「入队延迟唤醒」窗口：入队后的**下一拍**再用 io_enqDelayIn1_* 这组')
    A('//      延迟总线补一次唤醒匹配（派遣与唤醒总线之间差一拍，不补就会漏唤醒）。')
    A(f'//   golden 里由 {ov.parent} 例化 {ov.count} 份（实例名 enqEntries_*）。')
    A('//')
    A('// 本变体规模（家族参数取自 verif/ut/Entries_common/entries_gen.py 的')
    A(f'//   Variant("{ov.parent}") —— 那张表本来就是从本模块量出来的）：')
    A(f'//   源寄存器 {n_src} 个，发射口 {v.n_deq} 个'
      f'（deqPortIdxRead {"有" if ov.has_deq_port else "无"}）')
    if n_iq:
        A(f'//   WB 唤醒 {n_wk} 路（{v.wk_wen[0]}）+ IQ 即时唤醒 {n_iq} 路'
          f'；延迟窗口同宽（WB {ov.dly_wb} / IQ {ov.dly_iq}）')
        A('//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：')
        for w in range(n_iq):
            og = f'og0Cancel[{v.og0_idx[w]}]' if v.og0_idx[w] is not None else '无取消'
            A(f'//     IQ{w}: {og}, is0Lat={v.is0lat_kind[w]}'
              + (f', 自身是 load 流水 {v.iq_self_pipe[w][0]}' if v.iq_self_pipe[w] else ''))
    else:
        A(f'//   WB 唤醒 {n_wk} 路（无 IQ 唤醒、无 og0Cancel）；延迟窗口同宽')
    A('//   保留的 FuType one-hot 位：' + ', '.join(f'FuType[{b}]' for b in v.fu_bits))
    A('//   srcLoadDependency 影子：'
      + (f'每源 {v.ld_pipes} 条 load 流水 × {v.ld_dep_w} 位' if ov.has_ld_dep
         else '本条目没有（整条通路在 golden 里是死的，被 firtool 删干净）'))
    A(f'//   负载：发射口可见 {len(v.pl_deq)} 个字段 / {v.pl_deq_w} 位'
      f'；转移包另带 {len(v.pl_extra)} 个字段，共 {v.pl_trans_w} 位')
    A('//')
    A('// ★ 没有 commonOut.enqReady 端口 ★：核里照样算 enq_ready（装载条件要用），')
    A('//   但 golden 的 EnqEntry 不把它露出来（实测 14/14 变体都没有），故接悬空线。')
    A('//')
    A('// ★ HAS_DBG_OUT=1 ★：golden 的 CommonOutBundle 有 7 组 debug/perf 输出')
    A('//   （EntryBundles.scala:155-161 / :476-483）。它们在 Entries 那一层被 firtool')
    A('//   消掉，所以共享核默认不产出；条目单独成模块时它们是真端口，故这里打开。')
    A('//')
    A(f'// 自动生成：verif/ut/{ov.mod}/gen.py（共享库 verif/ut/EnqEntry_common/'
      'enqentry_gen.py）—— 勿手改')
    A('// =============================================================================')
    A(f'module {ov.mod} (')
    A(',\n'.join('  ' + d.strip() for _, _, _, d in ov.ports))
    A(');')
    A('')
    A('  // BEGIN GENERATED(core-inst)')

    # ---- 入队负载打包（低位在右，顺序 = Variant.pl_all 的偏移表）----
    A(f'  // 入队负载按 Variant 的偏移表拼成一根 {v.pl_trans_w} 位向量（transEntry 整包：')
    A('  // KEEP_WIDE = IS_ENQ | IS_TRANS，enq 条目要把整包交给下一级）')
    A(f'  logic [{v.pl_trans_w-1}:0] enq_payload;')
    A('  // 一字段一行 + 比特区间 —— 这张表就是「负载字段 -> 比特位置」的地图，')
    A('  // fm_pins_pre.tcl 的钉点用的是同一张 Variant.pl_off，两边不会各算各的。')
    A('  assign enq_payload = {')
    rows = []
    for n, w in reversed(v.pl_all):
        off, _ = v.pl_off[n]
        rng = f'[{off+w-1}:{off}]' if w > 1 else f'[{off}]'
        pn = ov.ipl(n)
        rows.append(((pn if ov.has(pn) else f"{w}'h0"), rng, n))
    wid = max(len(r[0]) for r in rows)
    for i, (expr, rng, nm) in enumerate(rows):
        comma = '' if i == len(rows) - 1 else ','
        A(f'    {expr}{comma}'.ljust(wid + 5) + f'// {rng} {nm}')
    A('  };')
    A('')
    ew, rw = max(1, v.exu_w), max(1, v.rc_idx_w)
    A(f'  logic [{nfu-1}:0] fu_type_narrow;')
    A(f'  logic [{n_src-1}:0][3:0] data_src;')
    A(f'  logic [{n_src-1}:0][{ew-1}:0] exu_src;')
    A(f'  logic [{v.pl_deq_w-1}:0] ety_payload;')
    A(f'  logic [{n_src-1}:0][{v.psrc_w-1}:0] ety_psrc;')
    A(f'  logic [{n_src-1}:0][3:0] ety_src_type;')
    A(f'  logic [{n_src-1}:0][{max(1,v.ld_pipes)-1}:0][{max(1,v.ld_dep_w)-1}:0] ety_ld_dep;')
    A(f'  logic [{n_src-1}:0][{rw-1}:0] ety_rc_idx;')
    A(f'  logic [{v.pl_trans_w-1}:0] trans_payload;')
    A(f'  logic [{n_src-1}:0][{v.psrc_w-1}:0] trans_psrc;')
    A(f'  logic [{n_src-1}:0][3:0] trans_src_type, trans_data_src;')
    A(f'  logic [{n_src-1}:0] trans_src_state, trans_use_rc;')
    A(f'  logic [{n_src-1}:0][{max(1,v.ld_pipes)-1}:0][{max(1,v.ld_dep_w)-1}:0]'
      ' trans_ld_dep;')
    A(f'  logic [{n_src-1}:0][{ew-1}:0] trans_exu_src;')
    A(f'  logic [{n_src-1}:0][{rw-1}:0] trans_rc_idx;')
    A(f'  logic [{nfu-1}:0] trans_fu_type;')
    A('  // golden 的 EnqEntry 不露 enqReady（核内部自用）')
    A('  logic unused_enq_ready;')
    if not ov.has('io_commonOut_transEntry_bits_status_blocked'):
        A('  // enq 条目没有 blocked 寄存器（核 §2.6a：IS_ENQ 时次态恒 0）')
        A('  logic unused_trans_blocked;')
    if not ov.has_deq_port:
        A('  logic unused_deq_port_idx;')
    if not ov.has('io_commonOut_transEntry_bits_status_deqPortIdx'):
        A('  logic unused_trans_deq_port;')
    if not ov.has('io_commonOut_cancelBypass'):
        A('  logic unused_cancel_bypass;')
    for nm, port in (('ld_cancel', 'perfLdCancel'), ('og0_cancel', 'perfOg0Cancel'),
                     ('wakeup_by_wb', 'perfWakeupByWB')):
        if not ov.has(f'io_commonOut_{port}_0'):
            A(f'  logic [{n_src-1}:0] unused_dbg_{nm};')
    if not ov.has('io_commonOut_perfWakeupByIQ_0_0'):
        A(f'  logic [{n_src-1}:0][{max(1,n_iq)-1}:0] unused_dbg_wakeup_by_iq;')
    A('')
    return L, (v, n_src, n_wk, n_iq, nfu, ew, rw)


def wrap_long(text, width=96):
    """把生成结果里过长的行按 ", " 折行（纯格式化：SystemVerilog 里空白不敏感）。

    ★为什么非折不可★：本轮的目的是「让人能读」。不折的话向量族的
    `.wk_pdest({...16 路...})` 和负载拼接会变成几百到两万字符的一行 ——
    在编辑器里根本没法读，diff 也没法看。
    """
    out = []
    for line in text.split('\n'):
        if len(line) <= width or '//' in line:
            out.append(line)
            continue
        ind = len(line) - len(line.lstrip())
        pad = ' ' * (ind + 4)
        cur = ''
        for tok in re.split(r'(?<=,) ', line):
            if cur and len(cur) + 1 + len(tok) > width:
                out.append(cur)
                cur = pad + tok
            else:
                cur = tok if not cur else cur + ' ' + tok
        out.append(cur)
    return '\n'.join(out)


def gen_rtl_body(ov, L, ctx):
    v, n_src, n_wk, n_iq, nfu, ew, rw = ctx
    A = L.append
    p = lambda n, dflt: (n if ov.has(n) else dflt)
    rev = lambda fmt, n: ', '.join(fmt % i for i in reversed(range(n)))

    # ---------------- 参数 ----------------
    A('  xs_iq_entry #(')
    A('    // ★ IS_ENQ=1：装载带 enqReady、强制 issued/firstIssue/issueTimer、')
    A('    //   无 blocked 寄存器、多一拍入队延迟唤醒窗口（核 §2.4/§2.6/§2.6a/§2.6b）')
    A('    .IS_ENQ(1), .IS_TRANS(0), .IS_COMP(1),')
    A(f'    .NUM_DEQ_PORTS({v.n_deq}),')
    A(f'    .NUM_REGSRC({n_src}), .NUM_WK_WB({n_wk}), .NUM_FU_BIT({nfu}),')
    A(f'    .ROB_W({v.rob_w}), .PSRC_W({v.psrc_w}), .PDEST_W({v.pdest_w}),')
    A(f'    .PL_DEQ_W({v.pl_deq_w}), .PL_TRANS_W({v.pl_trans_w}),')
    A(f'    .HAS_LD_DEP({int(ov.has_ld_dep)}), .HAS_LD1_CANCEL({int(ov.has_ld1)}),')
    A(f'    .LD_PIPES({v.ld_pipes}), .LD_DEP_W({v.ld_dep_w}),')
    A(f'    .NUM_WK_IQ({n_iq}), .EXU_W({ew}),')
    if n_iq:
        A('    .IQ_SRC_MASK({' + ', '.join(bitvec(v.iq_mask[s], n_iq)
                                           for s in reversed(range(n_src))) + '}),')
        # E1/E2：唤醒匹配 = 「按源分份的 kind」×「按窗口分份的 wen 存在性」。
        # 两个窗口各量各的：firtool 对当拍/延迟两条总线独立 DCE，实测不一定相同。
        A('    .IQ_WEN_PRESENT(' + wenvec(v.wen_present['iq']) + '),')
        A('    .IQD_WEN_PRESENT(' + wenvec(v.wen_present['iqd']) + '),')
        A('    .IQ_IS_LD_PIPE({' + ', '.join(
            bitvec(set(v.iq_self_pipe[w]), v.ld_pipes)
            for w in reversed(range(n_iq))) + '}),')
        A(f'    .HAS_REG_CACHE({int(v.has_rc)}), .RC_IDX_W({rw}),')
        A('    .IQ_WRITE_RC(' + bitvec(v.rc_lanes, n_iq)
          + f'), .RC_TYPE_BIT({v.rc_tbit}),')
    A('    .SRC_WB_MASK({' + ', '.join(bitvec(set(v.src_wb[s]), n_wk)
                                       for s in reversed(range(n_src))) + '}),')
    A("    .SRC_MATCH_KIND({" + ', '.join(f"2'd{v.src_kind[s]}"
                                        for s in reversed(range(n_src))) + '}),')
    A('    .WB_WEN_PRESENT(' + wenvec(v.wen_present['wb']) + '),')
    A('    .WBD_WEN_PRESENT(' + wenvec(v.wen_present['wbd']) + '),')
    A(f'    .HAS_IGNORE_OLD_VD({int(v.has_ignore)}),')
    A(f'    .VD_SRC({v.vd_src}), .VL_SRC({v.vl_src}),'
      f' .WB_VL_INT({v.wb_vl_int}), .WB_VL_VF({v.wb_vl_vf}),')
    for pl, fld in (('PLB_VM', 'vpu_vm'), ('PLB_VMA', 'vpu_vma'), ('PLB_VTA', 'vpu_vta'),
                    ('PLB_IS_DEPEND_OLDVD', 'vpu_isDependOldVd'),
                    ('PLB_IS_WRITE_PARTVD', 'vpu_isWritePartVd')):
        A(f'    .{pl}({v.pl_off[fld][0]}),')
    A('    // ★ 条目单独成模块时 golden 有这 7 组 debug/perf 输出，故打开')
    A('    .HAS_DBG_OUT(1)')
    A('  ) u_entry (')

    # ---------------- 连接 ----------------
    c = []
    c.append('.clock(clock), .reset(reset)')
    c.append('.flush_valid(io_commonIn_flush_valid)')
    c.append('.flush_rob_flag(io_commonIn_flush_bits_robIdx_flag)')
    c.append('.flush_rob_value(io_commonIn_flush_bits_robIdx_value)')
    c.append('.flush_level(io_commonIn_flush_bits_level)')
    c.append('.enq_valid(io_commonIn_enq_valid)')
    c.append('.enq_rob_flag(io_commonIn_enq_bits_status_robIdx_flag)')
    c.append('.enq_rob_value(io_commonIn_enq_bits_status_robIdx_value)')
    c.append('.enq_fu_type({%s})' % ', '.join(
        f'io_commonIn_enq_bits_status_fuType_{b}' for b in reversed(v.fu_bits)))
    for tag, fld in (('psrc', 'psrc'), ('src_type', 'srcType'),
                     ('src_state', 'srcState'), ('data_src', 'dataSources_value')):
        c.append('.enq_%s({%s})' % (tag, ', '.join(
            f'io_commonIn_enq_bits_status_srcStatus_{s}_{fld}'
            for s in reversed(range(n_src)))))
    c.append('  // ★ IS_ENQ 装载时这五个由核强制（issued=0/firstIssue=0/issueTimer=3，')
    c.append('  //   blocked 无寄存器、deqPortIdx 清 0），golden 也正因此没有这几个输入')
    c.append(".enq_blocked('0), .enq_issued('0), .enq_first_issue('0)")
    c.append(".enq_issue_timer('0), .enq_deq_port_idx('0)")
    c.append('.enq_payload(enq_payload)')
    if ov.has_ld_dep:
        c.append('.enq_ld_dep({%s})' % ', '.join(
            f'io_commonIn_enq_bits_status_srcStatus_{s}_srcLoadDependency_{q}'
            for s in reversed(range(n_src)) for q in reversed(range(v.ld_pipes))))
    else:
        c.append(".enq_ld_dep('0)")
    c.append('  // exuSources 入队值：enq 条目是 uop 的第一站，还没被任何 IQ 唤醒过')
    c.append("  //   （golden 也没有 enq.status.srcStatus.exuSources 输入端口）")
    c.append(".enq_exu_src('0)")
    for tag, fld in (('use_rc', 'useRegCache'), ('rc_idx', 'regCacheIdx')):
        nm = f'io_commonIn_enq_bits_status_srcStatus_0_{fld}'
        c.append('.enq_%s({%s})' % (tag, ', '.join(
            f'io_commonIn_enq_bits_status_srcStatus_{s}_{fld}'
            for s in reversed(range(n_src)))) if ov.has(nm) else f".enq_{tag}('0)")
    # ---- WB 唤醒：当拍 + 入队延迟窗口（本族专属，两组都接真信号）----
    c.append('.wk_valid({%s})' % rev('io_commonIn_wakeUpFromWB_%d_valid', n_wk))
    # E1/E2：wen 不再是"每路一位"，而是按核里 WEN_* 顺序打成的 5 位向量；
    # 该窗口没有的字段填 1'b0，核按 *_WEN_PRESENT 在 elaborate 期整项剪掉（不是喂 0）。
    # ★逐路★取存在集合：实测同一条总线上各路带的字段并不相同。
    for _wk_key, _wk_pfx in (('wb', 'io_commonIn_wakeUpFromWB'),
                             ('wbd', 'io_enqDelayIn1_wakeUpFromWB')):
        for w in range(n_wk):
            for _f in v.wen_lane[_wk_key].get(w, set()):
                assert ov.has(f'{_wk_pfx}_{w}_bits_{_f}'), (
                    f'{ov.mod}: {_wk_pfx}{w} 的写使能字段 {_f} 在本模块端口表里不存在')
    c.append('.wk_wen({%s})' % ', '.join(
        wenpack('io_commonIn_wakeUpFromWB', w, v.wen_lane['wb'].get(w, set()))
        for w in reversed(range(n_wk))))
    c.append('.wk_pdest({%s})' % rev('io_commonIn_wakeUpFromWB_%d_bits_pdest', n_wk))
    c.append('  // ★ 入队延迟窗口（IS_ENQ 专属）：派遣与唤醒总线差一拍，入队后的下一拍')
    c.append('  //   用这组延迟总线再匹配一次，否则那一拍的唤醒会被整个漏掉。')
    c.append('.wkd_valid({%s})' % rev('io_enqDelayIn1_wakeUpFromWB_%d_valid', n_wk))
    c.append('.wkd_wen({%s})' % ', '.join(
        wenpack('io_enqDelayIn1_wakeUpFromWB', w, v.wen_lane['wbd'].get(w, set()))
        for w in reversed(range(n_wk))))
    c.append('.wkd_pdest({%s})' % rev('io_enqDelayIn1_wakeUpFromWB_%d_bits_pdest', n_wk))
    if n_iq:
        def iq_group(pfx, d):
            # d = '' (当拍总线 iq_*) 或 'd' (延迟窗口总线 iqd_*)
            g = []
            _iqk = 'iq' if d == '' else 'iqd'
            g.append('.iq%s_wen({%s})' % (d, ', '.join(
                wenpack(f'{pfx}_wakeUpFromIQ', w,
                        {f for f in v.wen_lane[_iqk].get(w, set())
                         if ov.has(f'{pfx}_wakeUpFromIQ_{w}_bits_{f}')})
                for w in reversed(range(n_iq)))))
            g.append('.iq%s_pdest({%s})' % (d, ', '.join(
                f'{pfx}_wakeUpFromIQ_{w}_bits_pdest' for w in reversed(range(n_iq)))))
            if ov.has(f'{pfx}_wakeUpFromIQ_0_bits_loadDependency_0'):
                g.append('.iq%s_ld_dep({%s})' % (d, ', '.join(
                    f'{pfx}_wakeUpFromIQ_{w}_bits_loadDependency_{q}'
                    for w in reversed(range(n_iq))
                    for q in reversed(range(v.ld_pipes)))))
            else:
                g.append(f".iq{d}_ld_dep('0)")
            g.append('.iq%s_rc_dest({%s})' % (d, ', '.join(
                f'{pfx}_wakeUpFromIQ_{w}_bits_rcDest' for w in reversed(range(n_iq))))
                if ov.has(f'{pfx}_wakeUpFromIQ_0_bits_rcDest')
                else f".iq{d}_rc_dest('0)")
            # iq_cancel[w] = og0Cancel[第 w 路的全局 exu 下标] & is0Lat[w]
            g.append('.iq%s_cancel({%s})' % (d, ', '.join(
                ("1'b0" if v.og0_idx[w] is None else
                 (f'({pfx}_og0Cancel_{v.og0_idx[w]} & '
                  f'{pfx}_wakeUpFromIQ_{w}_bits_is0Lat)'
                  if v.is0lat_kind[w] == 'real'
                  else f'{pfx}_og0Cancel_{v.og0_idx[w]}'))
                for w in reversed(range(n_iq)))))
            return g
        c.append('  // iq_cancel[w] = og0Cancel[第 w 路的全局 exu 下标] & is0Lat[w]；')
        c.append('  // og0Cancel 的下标是稀疏的，is0Lat 有的路被 firtool 折成常量。')
        c += iq_group('io_commonIn', '')
        c.append('  // 延迟窗口的 IQ 总线：路数/下标映射与当拍侧同（构造时已断言）')
        c += iq_group('io_enqDelayIn1', 'd')
    else:
        c.append(".iq_wen('0), .iq_pdest('0), .iq_ld_dep('0), .iq_rc_dest('0)")
        c.append(".iq_cancel('0)")
        c.append(".iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0)")
        c.append(".iqd_cancel('0)")
    for tag, fld, pfx in (('ld1_cancel', 'ld1Cancel', 'io_commonIn'),
                          ('ld2_cancel', 'ld2Cancel', 'io_commonIn'),
                          ('ld1d_cancel', 'ld1Cancel', 'io_enqDelayIn1'),
                          ('ld2d_cancel', 'ld2Cancel', 'io_enqDelayIn1')):
        n = ov.dly_n_ld_cancel if pfx == 'io_enqDelayIn1' else ov.n_ld_cancel
        if ov.has(f'{pfx}_ldCancel_0_{fld}'):
            c.append('.%s({%s})' % (tag, ', '.join(
                f'{pfx}_ldCancel_{q}_{fld}' for q in reversed(range(n)))))
        else:
            c.append(f".{tag}('0)")
    c.append('  // ★ 延迟窗口判「本源影子该不该撤」用的是 Entries 在入队瞬间存下的那份')
    c.append('  //   （golden Entries.scala:140 的 RegEnable），条目这一层是输入端口。')
    if ov.dly_self_ld:
        c.append('.enqd_self_ld_dep({%s})' % ', '.join(
            f'io_enqDelayIn1_srcLoadDependency_{s}_{q}'
            for s in reversed(range(n_src)) for q in reversed(range(v.ld_pipes))))
    else:
        c.append(".enqd_self_ld_dep('0)")
    for tag, fld in (('vl_int_is_zero', 'vlFromIntIsZero'),
                     ('vl_int_is_vlmax', 'vlFromIntIsVlmax'),
                     ('vl_vf_is_zero', 'vlFromVfIsZero'),
                     ('vl_vf_is_vlmax', 'vlFromVfIsVlmax')):
        c.append('.%s(%s)' % (tag, p(f'io_commonIn_{fld}', "1'b0")))
    c.append('.deq_sel(io_commonIn_deqSel)')
    c.append('.deq_port_idx_write(%s)' % p('io_commonIn_deqPortIdxWrite', "1'b0"))
    c.append('.resp_valid(io_commonIn_issueResp_valid)')
    c.append('.resp_bits(io_commonIn_issueResp_bits_resp)')
    c.append('  // enq 条目的 transSel = 「本拍被搬到 simp/comp 去了」-> enqReady/clear')
    c.append('.trans_sel(io_commonIn_transSel)')
    # ---- 输出 ----
    c.append('.o_valid(io_commonOut_valid), .o_issued(io_commonOut_issued)')
    c.append('.o_can_issue(io_commonOut_canIssue)')
    c.append('.o_cancel_bypass(%s)' % ('io_commonOut_cancelBypass'
                                       if ov.has('io_commonOut_cancelBypass')
                                       else 'unused_cancel_bypass'))
    c.append('.o_is_first_issue(io_commonOut_isFirstIssue)')
    c.append('.o_fu_type(fu_type_narrow), .o_data_src(data_src)')
    c.append('.o_issue_timer(io_commonOut_issueTimerRead)')
    c.append('.o_deq_port_idx(%s)' % ('io_commonOut_deqPortIdxRead'
                                      if ov.has_deq_port else 'unused_deq_port_idx'))
    c.append('.o_enq_ready(unused_enq_ready)')
    c.append('.o_ety_rob_flag(io_commonOut_entry_bits_status_robIdx_flag)')
    c.append('.o_ety_rob_value(io_commonOut_entry_bits_status_robIdx_value)')
    c.append('.o_ety_psrc(ety_psrc), .o_ety_src_type(ety_src_type)')
    c.append('.o_ety_payload(ety_payload), .o_ety_ld_dep(ety_ld_dep)')
    c.append('.o_ety_rc_idx(ety_rc_idx), .o_exu_src(exu_src)')
    c.append('.o_trans_valid(io_commonOut_transEntry_valid)')
    c.append('.o_trans_rob_flag(io_commonOut_transEntry_bits_status_robIdx_flag)')
    c.append('.o_trans_rob_value(io_commonOut_transEntry_bits_status_robIdx_value)')
    for tag in ('trans_fu_type', 'trans_psrc', 'trans_src_type', 'trans_src_state',
                'trans_data_src', 'trans_payload', 'trans_ld_dep', 'trans_exu_src',
                'trans_use_rc', 'trans_rc_idx'):
        c.append(f'.o_{tag}({tag})')
    for tag, port, un in (('trans_blocked', 'blocked', 'unused_trans_blocked'),
                          ('trans_issued', 'issued', None),
                          ('trans_first_issue', 'firstIssue', None),
                          ('trans_issue_timer', 'issueTimer', None),
                          ('trans_deq_port_idx', 'deqPortIdx', 'unused_trans_deq_port')):
        full = f'io_commonOut_transEntry_bits_status_{port}'
        assert ov.has(full) or un, f'{ov.mod}: transEntry.status.{port} 缺失且无悬空线'
        c.append('.o_%s(%s)' % (tag, full if ov.has(full) else un))
    # ---- debug / perf ----
    c.append('  // golden 的 7 组 debug/perf 输出（EntryBundles.scala:476-483）')
    c.append('.o_dbg_entry_in_valid(io_commonOut_entryInValid)')
    c.append('.o_dbg_entry_out_deq_valid(io_commonOut_entryOutDeqValid)')
    c.append('.o_dbg_entry_out_trans_valid(io_commonOut_entryOutTransValid)')
    for tag, port in (('ld_cancel', 'perfLdCancel'), ('og0_cancel', 'perfOg0Cancel'),
                      ('wakeup_by_wb', 'perfWakeupByWB')):
        if ov.has(f'io_commonOut_{port}_0'):
            c.append('.o_dbg_perf_%s({%s})' % (tag, ', '.join(
                f'io_commonOut_{port}_{s}' for s in reversed(range(n_src)))))
        else:
            c.append(f'.o_dbg_perf_{tag}(unused_dbg_{tag})')
    if ov.has('io_commonOut_perfWakeupByIQ_0_0'):
        c.append('.o_dbg_perf_wakeup_by_iq({%s})' % ', '.join(
            f'io_commonOut_perfWakeupByIQ_{s}_{w}'
            for s in reversed(range(n_src)) for w in reversed(range(n_iq))))
    else:
        c.append('.o_dbg_perf_wakeup_by_iq(unused_dbg_wakeup_by_iq)')
    # 连接表里夹着注释行：注释不带逗号，真连接之间才有逗号。
    lines = []
    for x in c:
        lines.append((None if x.lstrip().startswith('//') else 'c', '    ' + x.strip()
                      if x.lstrip().startswith('//') else '    ' + x))
    last = max(i for i, (k, _) in enumerate(lines) if k == 'c')
    A('\n'.join(s + (',' if k == 'c' and i < last else '')
                for i, (k, s) in enumerate(lines)))
    A('  );')
    A('')

    # ---------------- 展开输出 ----------------
    A(f'  // fuType 出口：核只存本变体保留的 {nfu} 位，这里放回 {v.fu_w} 位 one-hot 的原位置')
    parts, prev = [], v.fu_w
    for b in sorted(v.fu_bits, reverse=True):
        if prev - b - 1 > 0:
            parts.append(f"{prev-b-1}'h0")
        parts.append(f'fu_type_narrow[{v.fu_bits.index(b)}]')
        prev = b
    if prev > 0:
        parts.append(f"{prev}'h0")
    A('  assign io_commonOut_fuType = {' + ', '.join(parts) + '};')
    A('')
    for s in range(n_src):
        A(f'  assign io_commonOut_dataSources_{s}_value = data_src[{s}];')
        if ov.has(f'io_commonOut_exuSources_{s}_value'):
            A(f'  assign io_commonOut_exuSources_{s}_value = exu_src[{s}];')
    A('')
    A('  // commonOut.entry.bits.status —— fuType 与 commonOut.fuType 同一组寄存器')
    for k, b in enumerate(v.fu_bits):
        nm = f'io_commonOut_entry_bits_status_fuType_{b}'
        if ov.has(nm):
            A(f'  assign {nm} = fu_type_narrow[{k}];')
    for s in range(n_src):
        for nm, rhs in ((f'io_commonOut_entry_bits_status_srcStatus_{s}_psrc',
                         f'ety_psrc[{s}]'),
                        (f'io_commonOut_entry_bits_status_srcStatus_{s}_srcType',
                         f'ety_src_type[{s}]'),
                        (f'io_commonOut_entry_bits_status_srcStatus_{s}_regCacheIdx',
                         f'ety_rc_idx[{s}]')):
            if ov.has(nm):
                A(f'  assign {nm} = {rhs};')
        for q in range(v.ld_pipes):
            nm = (f'io_commonOut_entry_bits_status_srcStatus_{s}'
                  f'_srcLoadDependency_{q}')
            if ov.has(nm):
                A(f'  assign {nm} = ety_ld_dep[{s}][{q}];')
    for n, w in v.pl_deq:
        nm = ov.opl('deq', n)
        if ov.has(nm):
            A(f'  assign {nm} = ety_payload{v.plslice(n)};')
    A('')
    A('  // commonOut.transEntry —— 交给下一级（simp/comp）的整包（= entryUpdate）')
    for k, b in enumerate(v.fu_bits):
        nm = f'io_commonOut_transEntry_bits_status_fuType_{b}'
        if ov.has(nm):
            A(f'  assign {nm} = trans_fu_type[{k}];')
    for s in range(n_src):
        for fld, rhs in (('psrc', f'trans_psrc[{s}]'),
                         ('srcType', f'trans_src_type[{s}]'),
                         ('srcState', f'trans_src_state[{s}]'),
                         ('dataSources_value', f'trans_data_src[{s}]'),
                         ('exuSources_value', f'trans_exu_src[{s}]'),
                         ('useRegCache', f'trans_use_rc[{s}]'),
                         ('regCacheIdx', f'trans_rc_idx[{s}]')):
            nm = f'io_commonOut_transEntry_bits_status_srcStatus_{s}_{fld}'
            if ov.has(nm):
                A(f'  assign {nm} = {rhs};')
        for q in range(v.ld_pipes):
            nm = (f'io_commonOut_transEntry_bits_status_srcStatus_{s}'
                  f'_srcLoadDependency_{q}')
            if ov.has(nm):
                A(f'  assign {nm} = trans_ld_dep[{s}][{q}];')
    for n, w in v.pl_all:
        nm = ov.opl('trans', n)
        if ov.has(nm):
            A(f'  assign {nm} = trans_payload{v.plslice(n)};')
    A('  // END GENERATED(core-inst)')
    A('')
    A('endmodule')
    return wrap_long('\n'.join(L)) + '\n'


# ---------------------------------------------------------------------------
# 覆盖桶的**逐桶**下限（按 200k 拍标定，运行时按 NCYCLES 线性缩放）。
#
# ★为什么不能用一个统一下限★：各桶的天然发生率差两个数量级，统一下限对发生率高
#   的桶等于没有（OthersEntry lane 的 +nopool 负测当场证过：三个桶塌一到两个数量级
#   仍高于统一下限 100）。所以逐桶标定。
#
# ★本表的来源★ = 本 lane 自己跑出来的 EnqEntry* 实测最小值再除以 4（见下面注释里
#   逐桶记的实测值）。标定跑法：9 变体 × 3 seed × 2 initreg × 200k 拍。
#   ★在标定完成之前这张表是 1（= 只判非零），那种状态下**不许提交**★
#   —— 只判非零的闸抓不到"激励塌了一个数量级"，正是 CONVENTIONS 要抓的形态。
# ★标定状态★：**已标定**（2026-09-20）。下面每一条的来源逐个记在行尾注释里：
#   跑法 = 9 变体 x 3 seed(1/7/42) x 2 initreg(random/0) x 200k 拍 = 54 次跑，
#   取该桶在**所有跑到它的那些次**里的最小值，再 // 4（留余量：下限是要抓
#   "塌一个数量级"，不是卡在实测值上让正常波动变红）。
#   行尾的「N 次跑」小于 54 的桶是**变体相关**的（cov_names 按变体给桶）：
#     ld_cancel_hit / rc_hit 只有 INT 那 3 个有，ignore_old_vd 只有向量那 3 个有，
#     iq_wake / og0_cancel_hit 只有有 IQ 唤醒的 6 个有。
#   表由 verif/ut/EnqEntry_common/calibrate_cov.py 从实跑日志机械算出，勿手改。
#
# ★标定数据是在"共享核那一行还没修"的仓库现状上跑的，这不影响标定★：
#   覆盖桶数的是激励打到的事件，而 perfWakeupByWB 那个错掉的 perf 输出不回灌
#   任何状态。已实测对照：同一 seed 下仓库现状与打了核补丁的一次性副本，
#   两份日志的 cov 行**逐字节相同**（见 CORE_BLOCKER.md）。
#
# ★标定前这张表是"只判非零"，实测它**不响**★（+nopool 负测，EnqEntry seed=1）：
#   wb_wake 10111->788 / iq_wake 41213->1569 / og0_cancel_hit 4810->168 /
#   enq_delay_wake 22633->1117（塌 13~29 倍），而闸报 cov_fail=0 —— 一条都没抓到。
#   标定后这四条的下限分别是 2527 / 7111 / 301 / 5658，都高于退化值。
COV_CALIBRATED = True
COV_MIN_200K = {
    'can_issue': 5129,         # 实测最小 20518 @ EnqEntry_16 seed=7 initreg=random（54 次跑）
    'deq_clear': 3055,         # 实测最小 12222 @ EnqEntry_4 seed=42 initreg=random（54 次跑）
    'deq_fire': 3609,          # 实测最小 14436 @ EnqEntry_16 seed=7 initreg=random（54 次跑）
    'enq_delay_wake': 5658,    # 实测最小 22633 @ EnqEntry_4 seed=1 initreg=random（54 次跑）
    'enq_delay_win': 9641,     # 实测最小 38566 @ EnqEntry_4 seed=1 initreg=random（54 次跑）
    'enq_fire': 17403,         # 实测最小 69615 @ EnqEntry_6 seed=1 initreg=random（54 次跑）
    'enq_while_valid': 10116,  # 实测最小 40466 @ EnqEntry_18 seed=42 initreg=random（54 次跑）
    'flush_hit': 106,          # 实测最小 427 @ EnqEntry_8 seed=42 initreg=random（54 次跑）
    'ignore_old_vd': 28780,    # 实测最小 115123 @ EnqEntry_18 seed=1 initreg=random（18 次跑）
    'iq_wake': 7111,           # 实测最小 28446 @ EnqEntry_12 seed=42 initreg=random（36 次跑）
    'ld_cancel_hit': 5246,     # 实测最小 20987 @ EnqEntry seed=1 initreg=random（18 次跑）
    'og0_cancel_hit': 301,     # 实测最小 1206 @ EnqEntry_10 seed=1 initreg=random（36 次跑）
    'rc_hit': 31939,           # 实测最小 127756 @ EnqEntry seed=7 initreg=random（18 次跑）
    'resp_block': 5742,        # 实测最小 22971 @ EnqEntry_14 seed=1 initreg=random（54 次跑）
    'resp_succ': 5787,         # 实测最小 23148 @ EnqEntry_4 seed=42 initreg=random（54 次跑）
    'resp_uncertain': 5744,    # 实测最小 22977 @ EnqEntry_6 seed=42 initreg=random（54 次跑）
    'trans_fire': 2200,        # 实测最小 8802 @ EnqEntry_10 seed=42 initreg=random（54 次跑）
    'wb_wake': 2527,           # 实测最小 10111 @ EnqEntry seed=1 initreg=random（54 次跑）
}


def cov_names(ov):
    """本变体要守的覆盖闸。逐项都要在 200k 拍里达标，否则判 FAIL。

    单条目比阵列更容易出假绿：只要 tb 不让它入队/发射/被唤醒，逐拍比对全是
    「两边都空」的平凡相等。所以这些闸不是装饰，是 errors=0 能不能当证据的前提。
    ★本族多两个闸★：enq_delay_win / enq_delay_wake —— 入队延迟唤醒窗口是
    EnqEntry 相对 OthersEntry 唯一的新逻辑，它不被激励打到的话，本族与
    OthersEntry 就没有区别，UT 等于没测到新东西。"""
    v = ov.v
    nm = ['enq_fire', 'wb_wake', 'can_issue', 'deq_fire',
          'resp_succ', 'resp_block', 'resp_uncertain', 'deq_clear', 'flush_hit',
          'trans_fire', 'enq_while_valid',
          'enq_delay_win', 'enq_delay_wake']
    if v.n_wk_iq:
        nm += ['iq_wake', 'og0_cancel_hit']
    if v.n_ld_cancel:
        nm += ['ld_cancel_hit']
    if v.has_rc:
        nm += ['rc_hit']
    if v.has_ignore:
        nm += ['ignore_old_vd']
    return nm


def gen_tb(ov):
    v = ov.v
    ins  = [(n, w) for d, w, n, _ in ov.ports
            if d == 'input' and n not in ('clock', 'reset')]
    outs = [(n, w) for d, w, n, _ in ov.ports if d == 'output']
    n_src, n_wk, n_iq = v.n_regsrc, v.n_wk, v.n_wk_iq
    L = []
    A = L.append
    dec = lambda w: '' if w == 1 else f'[{w-1}:0] '

    A(f'// {ov.mod} UT —— golden {ov.mod} 与重写 {ov.mod}_xs 双例化，'
      f'逐拍比对全部 {len(outs)} 个输出。')
    A('// 端口表从 G1 golden 机械提取，比对用 `CHK 宏逐端口展开，杜绝手抄漏项。')
    A('//')
    A('// ★ 单条目最容易出的假绿：激励根本没让它动 ★')
    A('//   条目不入队 / 不被唤醒 / 不发射时，两边输出都是「空条目」的平凡相等，')
    A('//   200k 拍 errors=0 什么也证明不了。所以除逐拍比对外还守一组覆盖闸')
    A('//   （见文件末 finish 里的 covchk），低于下限判 FAIL：')
    for nm in cov_names(ov):
        A(f'//     {nm}')
    A('//')
    A('// ★ 本族专属的闸：enq_delay_win / enq_delay_wake ★')
    A('//   入队延迟唤醒窗口是 EnqEntry 相对 OthersEntry 唯一的新逻辑。窗口只在')
    A('//   「入队成功」的下一拍开着（golden: enqDelayValidReg <= enq.valid && enqReady），')
    A('//   而 enqReady = 条目空 或 本拍被搬走。窗口开着时还得有一路延迟唤醒真打中')
    A('//   刚入队那个 uop 的源，这条通路才被走到 —— 两个闸分别守这两件事。')
    A('//   窗口条件由 tb 从 golden 的 commonOut.valid + 自己发的激励算出来（纯激励侧')
    A('//   记账，不是给 DUT 建模）。')
    A('//')
    A('// ★ 第二个坑（+vcs+initreg+random 才暴露）★')
    A('//   io_commonOut_issued / fuType / dataSources 是条目寄存器的**裸读**，')
    A('//   没有被 valid 门控。条目被写过之前，golden 的 entryReg_* 与重写核的 r_*')
    A('//   是两组不同的寄存器，随机初值下必然不同 —— 不开 initreg 时 golden 是 X、')
    A('//   被 $isunknown 跳过，看不出来；一开 initreg+random 就是一片错。')
    A('//   所以本 tb 等条目**被写过至少一次**（warm）才开始比对，')
    A('//   并且若整轮都没等到就判 FAIL（等不到 = 这一轮什么也没测）。')
    A('//')
    A('// 激励要点：')
    A('//   1) pdest/psrc 共用 8 值小池，否则唤醒永远打不中在队 uop 的源；')
    A('//      当拍总线与延迟总线共用同一个池，否则延迟窗口那条通路照样打不中。')
    A('//   2) srcType 按各源真实的门控位给，给错了那一路唤醒整条哑掉；')
    A('//   3) deqSel / transSel 在时钟沿**之前**用阻塞赋值从 golden 当拍已落定的')
    A('//      canIssue / valid 算出来，否则慢一拍全打空。')
    A(f'// 自动生成：verif/ut/{ov.mod}/gen.py（共享库 verif/ut/EnqEntry_common/'
      'enqentry_gen.py）—— 勿手改')
    A('`timescale 1ns/1ps')
    A('')
    A('`define CHK(P) begin \\')
    A('  checks++; \\')
    A('  if (!$isunknown(g_``P) && g_``P !== i_``P) begin \\')
    A('    errors++; \\')
    A('    if (errors <= 40) $display("[ERR] t=%0t %s golden=%h impl=%h", $time, '
      '`"P`", g_``P, i_``P); \\')
    A('  end \\')
    A('end')
    A('')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clock = 0;')
    A('  bit reset;')
    A('  int errors = 0;')
    A('  longint checks = 0;')
    A('  always #5 clock = ~clock;')
    A('')
    for nm in cov_names(ov):
        A(f'  int cov_{nm} = 0;')
    A('  int cov_fail = 0;')
    A('  int MINCOV[string];   // 逐桶下限（见 enqentry_gen.py 的 COV_MIN_200K）')
    A('  bit warm = 0;              // 条目被写过 -> 进入比对')
    A('  longint warm_cycle = -1;')
    # ★下限按拍数缩放必须走 64 位★（2026-09-20 实测，agent/enqentry）
    # 原先是 18 份逐条展开的 `((NCYCLES * <下限>) / 200000) > 0 ? ... : 1`，
    # 而 NCYCLES 是 `int unsigned`（32 位）——> 下限一超过 2^32/200000 ≈ 21474，
    # 乘法**静默回绕**。实测 rc_hit 下限 31939：200000*31939 = 6,387,800,000
    # 回绕成 2,092,832,704，除回来变 10464，日志里印的就是 "(min 10464)"。
    # ★标定之前这张表全是 1，乘法永远不会溢出，所以这个 bug 一直看不见★ ——
    # 是标定把它暴露出来的。这里换成一个 64 位中间量的函数，18 处共用一份。
    A('  // 下限按拍数缩放：**64 位中间量**。NCYCLES 是 int unsigned(32 位)，')
    A('  // 下限一旦超过 2^32/200000 ≈ 21474，32 位乘法会静默回绕（实测 rc_hit')
    A('  // 31939 被印成 10464）。longint 中间量把这条路堵死。')
    A('  function automatic int scale_min(int unsigned n, int base);')
    A('    longint v;')
    A('    v = (longint\'(n) * base) / 200000;')
    A('    return (v > 0) ? int\'(v) : 1;')
    A('  endfunction')
    A('  task automatic covchk(string nm, int c);')
    A('    int lo = MINCOV[nm];')
    A('    $display("  cov %-20s = %0d  (min %0d)", nm, c, lo);')
    A('    if (c < lo) begin')
    A('      cov_fail++;')
    A('      $display("  *** COVERAGE HOLE: %s = %0d < %0d", nm, c, lo);')
    A('    end')
    A('  endtask')
    A('')
    for n, w in ins:
        A(f'  logic {dec(w)}{n};')
    for n, w in outs:
        A(f'  wire {dec(w)}g_{n};')
        A(f'  wire {dec(w)}i_{n};')
    A('')
    for pfx, mod in (('g_', ov.mod), ('i_', ov.mod + '_xs')):
        A(f'  {mod} u_{pfx[0]} (')
        conn = ['    .clock(clock)', '    .reset(reset)']
        conn += [f'    .{n}({n})' for n, _ in ins]
        conn += [f'    .{n}({pfx}{n})' for n, _ in outs]
        A(',\n'.join(conn))
        A('  );')
        A('')
    A('  task automatic check_outputs();')
    for n, _ in outs:
        A(f'    `CHK({n})')
    A('  endtask')
    A('')
    A('  localparam int POOL = 8;   // pdest/psrc 共用的小池，保证唤醒能打中')
    A('  // *** +nopool：覆盖闸的双向负测开关 ***')
    A('  //   把小池换成整个 psrc 空间，唤醒就几乎永远打不中在队 uop 的源。')
    A('  //   电路一个字没改，只是激励退化 —— 这一轮**必须**把覆盖闸打红。')
    A('  bit nopool = 0;')
    A('  function automatic int rnd_reg();')
    A(f"    return nopool ? $urandom_range(0, {(1 << v.psrc_w) - 1})")
    A('                  : $urandom_range(0, POOL-1);')
    A('  endfunction')
    if v.has_rc:
        A('  localparam int RCPOOL = 4;  // regCacheIdx 小池，让 replaceRC 打得中')
        A('  function automatic int rnd_rc(); return $urandom_range(0, RCPOOL-1);'
          ' endfunction')
    A('')
    A('  // ---- 每拍激励（负沿下非阻塞给出）----')
    A('  task automatic drive();')
    A('    io_commonIn_flush_valid            <= ($urandom_range(0, 999) < 4);')
    A('    io_commonIn_flush_bits_robIdx_flag <= $urandom_range(0, 1);')
    A(f"    io_commonIn_flush_bits_robIdx_value <= {v.rob_w}'($urandom_range(0, 255));")
    A('    io_commonIn_flush_bits_level       <= $urandom_range(0, 1);')
    A('    // 入队率 35%：太高则条目永远刚写过，唤醒/发射通路测不到')
    A('    io_commonIn_enq_valid <= ($urandom_range(0, 99) < 35);')
    A('    io_commonIn_enq_bits_status_robIdx_flag  <= $urandom_range(0, 1);')
    A(f"    io_commonIn_enq_bits_status_robIdx_value <= {v.rob_w}'"
      "($urandom_range(0, 255));")
    for b in v.fu_bits:
        A(f'    io_commonIn_enq_bits_status_fuType_{b} <= $urandom_range(0, 1);')
    for s in range(n_src):
        tb_ = v.src_tbit[s]
        A(f"    io_commonIn_enq_bits_status_srcStatus_{s}_psrc <= "
          f"{v.psrc_w}'(rnd_reg());")
        A(f'    // src{s} 的 WB 唤醒门控位是 srcType[{tb_}]，绝大多数时候给对')
        A(f"    io_commonIn_enq_bits_status_srcStatus_{s}_srcType <= "
          f"($urandom_range(0,99) < 88) ? 4'h{1 << tb_:x} : 4'($urandom_range(0,15));")
        A(f'    io_commonIn_enq_bits_status_srcStatus_{s}_srcState <= '
          '($urandom_range(0, 99) < 60);')
        A(f'    io_commonIn_enq_bits_status_srcStatus_{s}_dataSources_value <= '
          "($urandom_range(0,1)) ? 4'h2 : 4'h8;")
        for q in range(v.ld_pipes):
            pn = (f'io_commonIn_enq_bits_status_srcStatus_{s}'
                  f'_srcLoadDependency_{q}')
            if ov.has(pn):
                A(f"    {pn} <= ($urandom_range(0,99) < 25) ? "
                  f"{v.ld_dep_w}'($urandom_range(1, {(1 << v.ld_dep_w) - 1})) :"
                  f" {v.ld_dep_w}'h0;")
        pn = f'io_commonIn_enq_bits_status_srcStatus_{s}_useRegCache'
        if ov.has(pn):
            A(f'    {pn} <= ($urandom_range(0, 99) < 40);')
            A(f'    io_commonIn_enq_bits_status_srcStatus_{s}_regCacheIdx <= '
              f"{v.rc_idx_w}'(rnd_rc());")
    A('    // 入队负载：逐字段随机（负载是一大排寄存器，装载时整份吃进来）')
    for n, w in v.pl_all:
        pp = ov.ipl(n)
        if ov.has(pp):
            A(f"    {pp} <= {w}'($urandom());" if w <= 32
              else f"    {pp} <= {{$urandom(), $urandom(), $urandom()}};")
    A('    // 唤醒总线：当拍一组 + 入队延迟窗口一组（本族专属），两组共用同一个小池')
    for pfx in ('io_commonIn', 'io_enqDelayIn1'):
        for w in range(n_wk):
            A(f'    {pfx}_wakeUpFromWB_{w}_valid <= ($urandom_range(0, 99) < 55);')
            A(f'    {pfx}_wakeUpFromWB_{w}_bits_{v.wk_wen[w]} <= '
              '($urandom_range(0, 99) < 85);')
            A(f"    {pfx}_wakeUpFromWB_{w}_bits_pdest <= {v.pdest_w}'(rnd_reg());")
        for w in range(n_iq):
            if v.iq_wen[w] and ov.has(f'{pfx}_wakeUpFromIQ_{w}_bits_{v.iq_wen[w]}'):
                A(f'    {pfx}_wakeUpFromIQ_{w}_bits_{v.iq_wen[w]} <= '
                  '($urandom_range(0, 99) < 30);')
            A(f"    {pfx}_wakeUpFromIQ_{w}_bits_pdest <= {v.pdest_w}'(rnd_reg());")
            for q in range(v.ld_pipes):
                pn = f'{pfx}_wakeUpFromIQ_{w}_bits_loadDependency_{q}'
                if ov.has(pn):
                    A(f"    {pn} <= {v.ld_dep_w}'($urandom_range(0, "
                      f"{(1 << v.ld_dep_w) - 1}));")
            pn = f'{pfx}_wakeUpFromIQ_{w}_bits_is0Lat'
            if ov.has(pn):
                A(f'    {pn} <= ($urandom_range(0, 99) < 60);')
            pn = f'{pfx}_wakeUpFromIQ_{w}_bits_rcDest'
            if ov.has(pn):
                A(f"    {pn} <= {v.rc_idx_w}'(rnd_rc());")
        for idx in sorted({v.og0_idx[w] for w in range(n_iq)
                           if v.og0_idx[w] is not None}):
            pn = f'{pfx}_og0Cancel_{idx}'
            if ov.has(pn):
                A(f'    {pn} <= ($urandom_range(0, 99) < 20);')
        for q in range(max(ov.n_ld_cancel, ov.dly_n_ld_cancel)):
            for fld in ('ld1Cancel', 'ld2Cancel'):
                pn = f'{pfx}_ldCancel_{q}_{fld}'
                if ov.has(pn):
                    A(f'    {pn} <= ($urandom_range(0, 99) < 15);')
    A('    // enqDelayIn1.srcLoadDependency：Entries 在入队瞬间存下的那份影子')
    for s in range(n_src):
        for q in range(v.ld_pipes):
            pn = f'io_enqDelayIn1_srcLoadDependency_{s}_{q}'
            if ov.has(pn):
                A(f"    {pn} <= ($urandom_range(0,99) < 25) ? "
                  f"{v.ld_dep_w}'($urandom_range(1, {(1 << v.ld_dep_w) - 1})) :"
                  f" {v.ld_dep_w}'h0;")
    for pn in ('vlFromIntIsZero', 'vlFromIntIsVlmax',
               'vlFromVfIsZero', 'vlFromVfIsVlmax'):
        if ov.has(f'io_commonIn_{pn}'):
            A(f'    io_commonIn_{pn} <= ($urandom_range(0, 99) < 35);')
    if ov.has('io_commonIn_deqPortIdxWrite'):
        A('    io_commonIn_deqPortIdxWrite <= ($urandom_range(0, 99) < 30);')
    A('    // issueResp：三种响应都要回到（BLOCK=0 / UNCERTAIN=1 / SUCCESS=3）')
    A('    io_commonIn_issueResp_valid <= ($urandom_range(0, 99) < 35);')
    A("    io_commonIn_issueResp_bits_resp <= "
      "(2'($urandom_range(0, 2)) == 2'd2) ? 2'd3 : 2'($urandom_range(0, 1));")
    A('  endtask')
    A('')
    A('  // ---- deqSel / transSel：必须在时钟沿之前按 golden 当拍的输出算 ----')
    A('  // 纯随机给的话命中 canIssue 的概率极低，发射通路整轮不动（假绿的头号来源）。')
    A('  task automatic drive_sel();')
    A('    io_commonIn_deqSel = g_io_commonOut_canIssue && ($urandom_range(0, 99) < 70);')
    A('    io_commonIn_transSel = g_io_commonOut_valid && ($urandom_range(0, 99) < 25);')
    A('  endtask')
    A('')
    return L


def gen_tb_tail(ov, L):
    v = ov.v
    A = L.append
    n_src, n_wk, n_iq = v.n_regsrc, v.n_wk, v.n_wk_iq
    g = lambda n: 'g_io_commonOut_' + n
    A('  // ---- 入队延迟窗口的激励侧记账 ----')
    A('  // golden: enqDelayValidReg <= enq.valid && enqReady，enqReady = !valid || transSel。')
    A('  // valid 就是 commonOut.valid（golden 的输出），transSel/enq_valid 是本 tb 发的，')
    A('  // 所以窗口条件可以在 tb 里**从激励和 golden 输出**算出来，不需要给 DUT 建模。')
    A('  bit dly_win = 0;            // 本拍窗口开着')
    A('  bit will_load;              // 本拍沿上条目会被装载')
    A(f"  logic [{v.psrc_w-1}:0] eq_psrc  [{n_src}];   // 开窗那次入队的 psrc")
    A(f'  logic [3:0]            eq_stype [{n_src}];   // 开窗那次入队的 srcType')
    A('  bit dly_hit;')
    A('')
    A('  // ---- 覆盖统计（在时钟沿前采样，"沿上一变就看不见了"）----')
    A('  task automatic sample_cov();')
    A('    if (io_commonIn_enq_valid) cov_enq_fire++;')
    A(f'    if ({g("canIssue")}) cov_can_issue++;')
    A(f'    if (io_commonIn_deqSel && {g("canIssue")}) cov_deq_fire++;')
    A('    if (io_commonIn_issueResp_valid) begin')
    A("      case (io_commonIn_issueResp_bits_resp)")
    A("        2'd3: cov_resp_succ++;")
    A("        2'd0: cov_resp_block++;")
    A("        2'd1: cov_resp_uncertain++;")
    A('        default: ;')
    A('      endcase')
    A('    end')
    A(f'    if ({g("entryOutDeqValid")}) cov_deq_clear++;')
    A(f'    if (io_commonIn_flush_valid && {g("valid")}) cov_flush_hit++;')
    A('    // wb_wake：写回唤醒真把一个**未就绪**的源翻成就绪（探 golden 的 perf 出口，')
    A('    //   它的定义正是 srcWakeupByWB && isBusy(srcState) && validReg）')
    A('    if (%s) cov_wb_wake++;' % ' || '.join(
        g(f'perfWakeupByWB_{s}') for s in range(n_src)))
    A(f'    if ({g("entryOutTransValid")}) cov_trans_fire++;')
    A(f'    if (io_commonIn_enq_valid && {g("valid")}) cov_enq_while_valid++;')
    if n_iq:
        A('    if (%s) cov_iq_wake++;' % ' || '.join(
            g(f'perfWakeupByIQ_{s}_{w}') for s in range(n_src) for w in range(n_iq)))
        A('    if (%s) cov_og0_cancel_hit++;' % ' || '.join(
            g(f'perfOg0Cancel_{s}') for s in range(n_src)))
    if ov.n_ld_cancel:
        A('    if (%s) cov_ld_cancel_hit++;' % ' || '.join(
            g(f'perfLdCancel_{s}') for s in range(n_src)))
    if v.has_rc:
        A('    if (%s) cov_rc_hit++;' % ' || '.join(
            f'io_commonIn_enq_bits_status_srcStatus_{s}_useRegCache'
            for s in range(n_src)))
    if v.has_ignore:
        A('    if (io_commonIn_vlFromIntIsZero || io_commonIn_vlFromVfIsZero)'
          ' cov_ignore_old_vd++;')
    A('    // --- 本族专属：入队延迟唤醒窗口 ---')
    A('    if (dly_win) begin')
    A('      cov_enq_delay_win++;')
    A('      dly_hit = 1\'b0;')
    A('      // 延迟总线里有没有一路真打中刚入队那个 uop 的源（路由表与核的参数同源）')
    for s in range(n_src):
        for w in sorted(set(v.src_wb[s])):
            A(f'      if (io_enqDelayIn1_wakeUpFromWB_{w}_valid'
              f' && io_enqDelayIn1_wakeUpFromWB_{w}_bits_{v.wk_wen[w]}'
              f' && eq_stype[{s}][{v.src_tbit[s]}]'
              f" && io_enqDelayIn1_wakeUpFromWB_{w}_bits_pdest"
              f" == {v.pdest_w}'(eq_psrc[{s}])) dly_hit = 1'b1;")
        for w in sorted(v.iq_mask[s]):
            if not v.iq_wen[w]:
                continue
            A(f'      if (io_enqDelayIn1_wakeUpFromIQ_{w}_bits_{v.iq_wen[w]}'
              f' && eq_stype[{s}][{v.iq_tbit[s]}]'
              f" && io_enqDelayIn1_wakeUpFromIQ_{w}_bits_pdest"
              f" == {v.pdest_w}'(eq_psrc[{s}])) dly_hit = 1'b1;")
    A('      if (dly_hit) cov_enq_delay_wake++;')
    A('    end')
    A('    // 窗口寄存器的次态：本拍沿上装载成功 -> 下一拍开窗')
    A(f'    will_load = io_commonIn_enq_valid'
      f' && (!{g("valid")} || io_commonIn_transSel);')
    A('    if (will_load) begin')
    for s in range(n_src):
        A(f'      eq_psrc[{s}]  <= '
          f'io_commonIn_enq_bits_status_srcStatus_{s}_psrc;')
        A(f'      eq_stype[{s}] <= '
          f'io_commonIn_enq_bits_status_srcStatus_{s}_srcType;')
    A('    end')
    A('    dly_win = will_load;')
    A('  endtask')
    A('')
    A('  longint cyc = 0;')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    nopool = $test$plusargs("nopool");')
    for nm in cov_names(ov):
        A('    MINCOV["%s"] = scale_min(NCYCLES, %d);' % (nm, COV_MIN_200K[nm]))
    A('    if (nopool) $display("*** +nopool: 覆盖闸负测模式（激励退化，闸必须红）***");')
    A('    reset = 1;')
    A('    drive();')
    A("    io_commonIn_deqSel = 1'b0;")
    A("    io_commonIn_transSel = 1'b0;")
    A('    repeat (4) @(posedge clock);')
    A('    reset = 0;')
    A('    forever begin')
    A('      @(negedge clock);')
    A('      drive();')
    A('      #1 drive_sel();     // 用当拍已落定的 golden 输出算选择信号')
    A('      sample_cov();')
    A('      @(posedge clock);')
    A('      #1;')
    A('      cyc++;')
    A('      // warm：条目被写过之后，裸读输出才有可比性（见文件头第二个坑）')
    A('      if (!warm && io_commonIn_enq_valid) begin warm = 1; warm_cycle = cyc; end')
    A('      if (warm) check_outputs();')
    A('      if (cyc >= NCYCLES) begin')
    A('        $display("=== %0d cycles, checks=%0d, errors=%0d ===", cyc, checks, errors);')
    A('        $display("  warm_cycle = %0d", warm_cycle);')
    A('        if (warm_cycle < 0) begin')
    A('          $display("  *** 整轮都没等到条目被写过 —— 这一轮什么也没测");')
    A('          cov_fail++;')
    A('        end')
    for nm in cov_names(ov):
        A(f'        covchk("{nm}", cov_{nm});')
    A('        if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");')
    A('        else $display("TEST FAILED (errors=%0d cov_fail=%0d checks=%0d)",'
      ' errors, cov_fail, checks);')
    A('        $finish;')
    A('      end')
    A('    end')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


# =============================================================================
def check_port_refs(ov, rtl):
    """★ 生成出来的 wrapper 里，凡是形如 io_* 的标识符都必须是 golden 真有的端口 ★

    为什么非有不可：SystemVerilog 里引用一个没声明的名字，VCS 会**静默**建一根
    隐式 1 位线（0 Error 0 Warning），那根线没人驱动，于是整条通路是 X。
    OthersEntry lane 第一版就栽在这里（无条件引用了 FP 族没有的
    `io_commonIn_wakeUpFromIQ_<w>_bits_loadDependency_<q>`，编译 rc=0、lint 干净，
    UT 才在 96307 个 X 上炸出来）。本族的延迟总线端口更容易踩同一个坑，所以照搬这道闸。
    """
    declared = {n for _, _, n, _ in ov.ports}
    body = '\n'.join(l.split('//')[0] for l in rtl.split('\n'))
    used = set(re.findall(r'\bio_[A-Za-z0-9_]+', body))
    bad = sorted(used - declared)
    if bad:
        raise AssertionError(
            f'{ov.mod}: wrapper 引用了 golden 没有的端口名（VCS 会静默建隐式线 -> X）：'
            + ', '.join(bad[:8]) + (f' …共 {len(bad)} 个' if len(bad) > 8 else ''))
    return len(used)


def check_tb_port_refs(ov, tb):
    """tb 同理：引用 golden 没有的端口名 -> VCS 静默建隐式线。"""
    declared = {n for _, _, n, _ in ov.ports}
    body = '\n'.join(l.split('//')[0] for l in tb.split('\n'))
    used = {n for n in re.findall(r'\bio_[A-Za-z0-9_]+', body)}
    bad = sorted(used - declared)
    if bad:
        raise AssertionError(f'{ov.mod}: tb 引用了 golden 没有的端口名：' + ', '.join(bad[:8]))
    return len(used)


# ---------------------------------------------------------------------------
# vmucp（verify_matched_unread_compare_points）已挣到的变体。
#
# ★这是加强不是放宽★：true 让 FM **真去比**那些「本变体里没有输出锥」的点，
# 而不是记 Not-Compared。加入依据按 standing rule 的六条逐条落实（精确绑定 /
# 双射配对 / FM 实开比较 passing 增 / 全零 / 无 dont_verify 无新黑盒 / manifest 摘要），
# 数字写在下面，**先跑出来再填**，不许预填。
VMUCP = set()


def gen_mk(ov):
    sub = sorted({t for t in re.findall(
        r'^  ([A-Z][A-Za-z0-9_]*) [a-zA-Z_]\w*\s*\($', read(ov.mod), re.M)})
    extra_golden = ''.join(f' \\\n              $(GOLDEN_RTL)/{m}.sv' for m in sub)
    extra_deps = ' '.join(f'{m}.sv' for m in sub)
    vmucp = 'true' if ov.mod in VMUCP else 'false'
    vmucp_note = (
        '# ★vmucp=true（加强，不是放宽）★：依据与预登记数字见\n'
        '#   verif/ut/EnqEntry_common/enqentry_gen.py 的 VMUCP 表。'
        if vmucp == 'true' else
        '# 本变体未用 vmucp：首跑 unread 即为 0（跑出来不是 0 就停下诊断，不许改这一行凑绿）。')
    return f"""# {ov.mod} UT/FM 入口（EnqEntry* 家族：{ov.parent[len('Entries'):]} 的入队条目）
# 重写件只有两个：三族共享的参数化单条目核 + 本变体薄文件。
# 核体是 xs_iq_entries_core.sv 里的 xs_iq_entry —— 与 Entries*/OthersEntry* 家族
# **同一份**，不复制（CONVENTIONS「变体家族：核体绝不复制」）。本族只是把它以
# IS_ENQ=1 单独封成 golden 同名模块，并把 io_enqDelayIn1_* 接到核已有的延迟总线入口。
# 自动生成：verif/ut/{ov.mod}/gen.py
#   （共享库 verif/ut/EnqEntry_common/enqentry_gen.py）
# 勿手改
MODULE = {ov.mod}

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_iq_entries_core.sv \\
           $(RTL_DIR)/backend/{ov.mod}.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/{ov.mod}.sv{extra_golden}

FM_VARIANTS = {ov.mod}
FM_REF_DEPS_{ov.mod} = {extra_deps}

# ---------------------------------------------------------------------------
# FM 证明配置 —— 与 Entries*/OthersEntry* 家族同因同配，两项都是**加强**不是放宽
# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false：golden 把条目负载展平成上百个逐字段寄存器，其中本变体
#   用不到的字段整组是常数；merge_duplicated_registers=true 时 FM 在 golden 侧
#   把这些同值寄存器合并掉，而可读核把同一份负载存在一根向量里、按位不合并，
#   于是两侧点数对不上。置 false 后两侧都逐个保留 —— 要求逐个比而不是合并后比。
FM_MERGE_DUP = false
{vmucp_note}
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = {vmucp}

include ../../../scripts/ut_common.mk

# golden 带 XSError/XSPerf 等非综合断言，随机激励会踩到 $fatal；两侧统一关掉。
VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 复位域：条目寄存器（entryReg_*）在 golden 里**不复位**，只有 validReg 与
# enqDelayValidReg 带复位（实测 {ov.mod}.sv 的 `if (reset)` 只钉这两个）。可读核照抄。
#
# 不开 initreg 时 golden 侧未初始化的寄存器是 X，被 tb 的 $isunknown 跳过 ——
# 「照抄复位域」这件事根本没被验过。所以编译期 +vcs+initreg+random 打开能力，
# 运行期用 +vcs+initreg+<0|random> 选初值，两种初值都要过。
# ★ 编译期写 +vcs+initreg+0 是错的：VCS 报 OBSL_OPT_E，那是运行期选项。★
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0: simv
	./simv +vcs+initreg+0 +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l sim_ir0_$(SEED).log
	@grep -q "TEST PASSED" sim_ir0_$(SEED).log && echo "=== UT PASSED ($(MODULE) initreg=0 seed=$(SEED)) ===" || {{ echo "=== UT FAILED ($(MODULE) initreg=0 seed=$(SEED)) ==="; exit 1; }}
"""


def gen_stub(ov):
    return (f'#!/usr/bin/env python3\n'
            f'"""{ov.mod} 的生成入口（薄壳）。真正的代码在共享库里，'
            f'本族各变体共用一份代码路径。"""\n'
            f'import sys, pathlib\n'
            f'sys.path.insert(0, str(pathlib.Path(__file__).resolve()'
            f'.parents[1] / "EnqEntry_common"))\n'
            f'from enqentry_gen import main\n'
            f'sys.exit(main("{ov.mod}"))\n')


def gen_pins_stub(mod):
    return (
        "#!/usr/bin/env python3\n"
        "# 薄壳: 真正的代码在 verif/ut/EnqEntry_common/gen_fm_pins.py\n"
        "import sys, pathlib\n"
        "sys.path.insert(0, str(pathlib.Path(__file__).resolve()"
        ".parents[1] / 'EnqEntry_common'))\n"
        "from gen_fm_pins import main\n"
        "sys.exit(main('%s'))\n" % mod)


def main(mod):
    check = '--check' in sys.argv
    if not COV_CALIBRATED and '--uncalibrated' not in sys.argv:
        sys.exit('COV_MIN_200K 尚未标定 —— 只判非零的闸抓不到激励塌陷，拒绝生成。\n'
                 '标定跑法：--uncalibrated 生成一版，跑 3 seed x 2 initreg x 200k，\n'
                 '取各桶族内最小值/4 填表，再把 COV_CALIBRATED 翻 True 重新生成。\n'
                 '★标定版产物不许提交★')
    ov = EnqVariant(mod)
    L, ctx = gen_rtl(ov)
    rtl = gen_rtl_body(ov, L, ctx)
    n_ref = check_port_refs(ov, rtl)
    tb = gen_tb_tail(ov, gen_tb(ov))
    check_tb_port_refs(ov, tb)
    here = REPO / 'verif' / 'ut' / mod
    files = {
        REPO / 'rtl' / 'backend' / f'{mod}.sv': rtl,
        here / 'tb.sv':    tb,
        here / 'Makefile': gen_mk(ov),
        here / 'gen.py':   gen_stub(ov),
        here / 'gen_fm_pins.py': gen_pins_stub(mod),
    }
    bad = 0
    # ★ 必须按**路径**导入，不能 `import gen_fm_pins` ★
    #   本模块把 Entries_common 插进了 sys.path（为了 import entries_gen），
    #   而那边也有一个同名的 gen_fm_pins.py —— 裸 import 会拿到 Entries 的那份。
    import importlib.util as _ilu
    _spec = _ilu.spec_from_file_location(
        'ee_gen_fm_pins', str(HERE / 'gen_fm_pins.py'))
    gen_fm_pins = _ilu.module_from_spec(_spec)
    _spec.loader.exec_module(gen_fm_pins)
    if check:
        argv_save = list(sys.argv)
        sys.argv = [sys.argv[0], '--check']
        bad |= gen_fm_pins.main(mod)
        sys.argv = argv_save
    else:
        gen_fm_pins.main(mod)
    for p, txt in files.items():
        if check:
            if not p.exists() or p.read_text() != txt:
                print(f'DRIFT: {p}'); bad = 1
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(txt)
            print(f'wrote {p} ({txt.count(chr(10))} lines)')
    if not check:
        v = ov.v
        print(f'  端口引用闸：{n_ref} 个 io_* 引用全部落在 golden 端口表内')
        print(f'\n[{mod}] enq of {ov.parent} x{ov.count}  '
              f'regsrc={v.n_regsrc} wb={v.n_wk} iq={v.n_wk_iq} '
              f'PL_DEQ_W={v.pl_deq_w} PL_TRANS_W={v.pl_trans_w} '
              f'ports={len(ov.ports)}')
    return bad


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
