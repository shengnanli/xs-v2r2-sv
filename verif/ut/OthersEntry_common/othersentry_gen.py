#!/usr/bin/env python3
"""OthersEntry* 家族（24 变体）薄变体文件 + UT 生成器（共享库）。

## 这一族是什么

`OthersEntry(isComp)` = 发射队列里**非入队**的条目
（`src/main/scala/xiangshan/backend/issue/OthersEntry.scala`）。
它的模块体只有四句，全在 `EntryBundles.scala`，而 `EnqEntry.scala` 调的是**同样四句**
（只是 `isEnq=true`）—— 所以 golden 的 EnqEntry / OthersEntry 本来就是一份逻辑的
两次单态化，本仓的 `rtl/backend/xs_iq_entries_core.sv` 里的 `xs_iq_entry` 就是那份逻辑。

因此本生成器**不造第二个核**：每个变体只生成一个薄 wrapper，例化 `xs_iq_entry`，
把 golden 的扁平端口打包成核的数组接口，并给出本变体的参数。

## 参数从哪来（★不是我自己再量一遍★）

家族参数（唤醒路由、og0 取消映射、负载字段偏移、fuType 位集合……）一律从
`verif/ut/Entries_common/entries_gen.py` 的 `Variant(<parent Entries 变体>)` 取。
那份代码在构造时**已经逐条断言** enq / simp / comp 三个 golden 模块共用同一套路由
（见它里面 `wb_triples` / IQ 路由 / og0 映射三段 assert）——也就是说
「OthersEntry 能用 Entries 那套参数」这件事是被它的断言钉住的，不是我这里的假设。
只有**逐模块才会不同**的几样（有没有 transEntry / deqPortIdx / srcLoadDependency /
ldCancel 端口）才在本文件里从 OthersEntry 自己的端口表量。

用法：
  python3 gen.py            # 生成
  python3 gen.py --check    # 只校验已提交产物没漂移（非零退出=漂移）
"""
import re, sys, pathlib, collections

HERE   = pathlib.Path(__file__).resolve().parent
REPO   = HERE.parents[2]
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
sys.path.insert(0, str(REPO / 'verif' / 'ut' / 'Entries_common'))
from entries_gen import Variant, port_decls, read, bitvec   # noqa: E402


def parents():
    """OthersEntry 变体 -> (parent Entries 变体, 'simp'|'comp', 例化份数)。
    从 golden Entries*.sv 的实例名反查，是角色的唯一权威依据。"""
    res = {}
    for f in sorted(GOLDEN.glob('Entries*.sv')):
        txt = f.read_text()
        for t, n in re.findall(
                r'^  ([A-Za-z]\w*) (othersEntriesSimp_\d+|othersEntriesComp_\d+)\s*\(',
                txt, re.M):
            if t.startswith('OthersEntryVecMem'):
                continue                      # VecMem 是另一族，不在本生成器范围
            role = 'simp' if 'Simp' in n else 'comp'
            cur = res.setdefault(t, [f.stem, role, 0])
            assert cur[0] == f.stem and cur[1] == role, f'{t} 角色/父级不唯一'
            cur[2] += 1
    return {k: tuple(v) for k, v in res.items()}


class OthersVariant:
    def __init__(self, mod):
        self.mod = mod
        self.parent, self.role, self.count = parents()[mod]
        self.v = Variant(self.parent)          # 家族参数（含三模块一致性断言）
        v = self.v
        assert mod == (v.simp_mod if self.role == 'simp' else v.comp_mod), \
            f'{mod}: 角色 {self.role} 与 Variant 里的 simp/comp 对不上'
        self.ports = port_decls(mod)
        self.pmap  = {n: (d, w) for d, w, n, _ in self.ports}
        has = lambda n: n in self.pmap

        self.is_trans = (self.role == 'simp')
        # ---- 只有逐模块才会不同的那几样 ----
        self.has_ld_dep = has(
            'io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0')
        self.has_deq_port = has('io_commonOut_deqPortIdxRead')
        assert self.has_deq_port == (v.n_deq == 2), (
            f'{mod}: deqPortIdxRead={self.has_deq_port} 但父级 numDeq={v.n_deq}'
            ' —— 这条对应关系是矩阵实测的，不成立就说明有新维度')
        assert has('io_commonIn_transSel') == self.is_trans, \
            f'{mod}: transSel 与角色不符'
        assert has('io_commonOut_transEntry_valid') == self.is_trans, \
            f'{mod}: transEntry 与角色不符'
        # ldCancel 端口在条目上逐条给（io_commonIn_ldCancel_<q>_ld{1,2}Cancel）
        self.n_ld_cancel = sum(1 for n in self.pmap
                               if re.fullmatch(r'io_commonIn_ldCancel_\d+_ld2Cancel', n))
        self.has_ld1 = has('io_commonIn_ldCancel_0_ld1Cancel')
        assert self.has_ld1 == v.has_ld1, f'{mod}: ld1Cancel 与父级不一致'
        assert self.n_ld_cancel == v.n_ld_cancel, f'{mod}: ldCancel 条数与父级不一致'
        # 负载：条目自己的端口就是权威（Variant 从 EnqEntry 量的那份必须相同）
        def pl(pfx):
            return [(n[len(pfx):], w) for d, w, n, _ in self.ports if n.startswith(pfx)]
        deq_pl = pl('io_commonOut_entry_bits_payload_')
        if has('io_commonOut_entry_bits_imm'):
            deq_pl = [('#imm', self.pmap['io_commonOut_entry_bits_imm'][1])] + deq_pl
        assert deq_pl == v.pl_deq, (
            f'{mod}: DEQ 负载字段与 {v.enq_mod} 不同 —— 不能共用 Variant 的偏移表\n'
            f'  只在条目: {sorted(set(deq_pl) - set(v.pl_deq))[:4]}\n'
            f'  只在 enq: {sorted(set(v.pl_deq) - set(deq_pl))[:4]}')
        if self.is_trans:
            tr = pl('io_commonOut_transEntry_bits_payload_')
            if has('io_commonOut_transEntry_bits_imm'):
                tr = [('#imm', self.pmap['io_commonOut_transEntry_bits_imm'][1])] + tr
            dn = {n for n, _ in deq_pl}
            assert [(n, w) for n, w in tr if n not in dn] == v.pl_extra, \
                f'{mod}: TRANS 独有负载字段与 {v.enq_mod} 不同'

    # ---- 端口名小工具 ----
    def has(self, n):
        return n in self.pmap

    def ipl(self, f):
        """入队负载字段 f 对应的 golden 输入端口名（'#imm' 是并进来的伪字段）"""
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
    role_cn = '简单条目 simp（可被提级，产出 transEntry）' if ov.is_trans \
              else '复杂条目 comp（终端，发射从这里走）'

    A(f'// {ov.mod}.sv —— 发射队列单条目（{ov.parent[len("Entries"):]} 变体的 '
      f'{ov.role}）薄包装层')
    A('// -----------------------------------------------------------------------------')
    A('// 核体见 xs_iq_entries_core.sv 的 `xs_iq_entry`（Entries*/OthersEntry*/EnqEntry*')
    A('// 三族共享的参数化单条目核）。本文件不含逻辑分支，只做端口摊平 + 设参数。')
    A('//')
    A('// 在流水线里的位置：一条等待发射的 uop 占一个条目。条目每拍监听写回(WB)与')
    A('// IQ 即时唤醒总线，把命中的源置就绪；「全源就绪 && 未发射 && 未阻塞 && 未冲刷」')
    A('// 即 canIssue，上层 Entries 在 canIssue 的条目里按年龄选最老的发射。')
    A(f'// 本条目角色：{role_cn}')
    A(f'//   golden 里由 {ov.parent} 例化 {ov.count} 份'
      f'（实例名 othersEntries{"Simp" if ov.is_trans else "Comp"}_*）。')
    A('//')
    A('// 本变体规模（家族参数取自 verif/ut/Entries_common/entries_gen.py 的')
    A(f'//   Variant("{ov.parent}")，那份代码已断言 enq/simp/comp 三个 golden 模块')
    A('//   共用同一套唤醒路由与 og0 取消映射；逐模块才会不同的几样在本文件里另量）：')
    A(f'//   源寄存器 {n_src} 个，发射口 {v.n_deq} 个'
      f'（deqPortIdxRead {"有" if ov.has_deq_port else "无"}）')
    if n_iq:
        A(f'//   WB 唤醒 {n_wk} 路（{v.wk_wen[0]}）+ IQ 即时唤醒 {n_iq} 路')
        A('//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：')
        for w in range(n_iq):
            og = f'og0Cancel[{v.og0_idx[w]}]' if v.og0_idx[w] is not None else '无取消'
            A(f'//     IQ{w}: {og}, is0Lat={v.is0lat_kind[w]}'
              + (f', 自身是 load 流水 {v.iq_self_pipe[w][0]}' if v.iq_self_pipe[w] else ''))
    else:
        A(f'//   WB 唤醒 {n_wk} 路（无 IQ 唤醒、无 og0Cancel）')
    A(f'//   保留的 FuType one-hot 位：'
      + ', '.join(f'FuType[{b}]' for b in v.fu_bits))
    A(f'//   srcLoadDependency 影子：'
      + (f'每源 {v.ld_pipes} 条 load 流水 × {v.ld_dep_w} 位' if ov.has_ld_dep
         else '本条目没有（整条通路在 golden 里是死的，被 firtool 删干净）'))
    A(f'//   负载：发射口可见 {len(v.pl_deq)} 个字段 / {v.pl_deq_w} 位'
      + (f'；转移包另带 {len(v.pl_extra)} 个字段，共 {v.pl_trans_w} 位'
         if ov.is_trans else '（comp 不产出 transEntry，只存这一份）'))
    A('//')
    A('// ★ HAS_DBG_OUT=1 ★：golden 的 CommonOutBundle 有 7 组 debug/perf 输出')
    A('//   （EntryBundles.scala:155-161 / :476-483）。它们在 Entries 那一层被 firtool')
    A('//   消掉，所以共享核默认不产出；条目单独成模块时它们是真端口，故这里打开。')
    A('//')
    A(f'// 自动生成：verif/ut/{ov.mod}/gen.py（共享库 verif/ut/OthersEntry_common/'
      'othersentry_gen.py）—— 勿手改')
    A('// =============================================================================')
    A(f'module {ov.mod} (')
    A(',\n'.join('  ' + d.strip() for _, _, _, d in ov.ports))
    A(');')
    A('')
    A('  // BEGIN GENERATED(core-inst)')

    # ---- 入队负载打包（低位在右，顺序 = Variant.pl_all 的偏移表）----
    plw = v.pl_trans_w if ov.is_trans else v.pl_deq_w
    pl_fields = v.pl_all if ov.is_trans else v.pl_deq
    A(f'  // 入队负载按 Variant 的偏移表拼成一根 {plw} 位向量'
      f'（{"transEntry 整包" if ov.is_trans else "只存发射口可见那份"}）')
    A(f'  logic [{v.pl_trans_w-1}:0] enq_payload;')
    terms = []
    for n, w in reversed(v.pl_all):
        p = ov.ipl(n)
        terms.append(p if ov.has(p) else f"{w}'h0")
    A('  assign enq_payload = {' + ', '.join(terms) + '};')
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
    if ov.is_trans:
        A(f'  logic [{v.pl_trans_w-1}:0] trans_payload;')
        A(f'  logic [{n_src-1}:0][{v.psrc_w-1}:0] trans_psrc;')
        A(f'  logic [{n_src-1}:0][3:0] trans_src_type, trans_data_src;')
        A(f'  logic [{n_src-1}:0] trans_src_state, trans_use_rc;')
        A(f'  logic [{n_src-1}:0][{max(1,v.ld_pipes)-1}:0][{max(1,v.ld_dep_w)-1}:0]'
          ' trans_ld_dep;')
        A(f'  logic [{n_src-1}:0][{ew-1}:0] trans_exu_src;')
        A(f'  logic [{n_src-1}:0][{rw-1}:0] trans_rc_idx;')
        A(f'  logic [{nfu-1}:0] trans_fu_type;')
    else:
        A('  // comp 不产出 transEntry：核的这组出口接悬空线（golden 同样没有这些端口）')
        A(f'  logic [{v.pl_trans_w-1}:0] unused_trans_payload;')
        A(f'  logic [{n_src-1}:0][{v.psrc_w-1}:0] unused_trans_psrc;')
        A(f'  logic [{n_src-1}:0][3:0] unused_trans_src_type, unused_trans_data_src;')
        A(f'  logic [{n_src-1}:0] unused_trans_src_state, unused_trans_use_rc;')
        A(f'  logic [{n_src-1}:0][{max(1,v.ld_pipes)-1}:0][{max(1,v.ld_dep_w)-1}:0]'
          ' unused_trans_ld_dep;')
        A(f'  logic [{n_src-1}:0][{ew-1}:0] unused_trans_exu_src;')
        A(f'  logic [{n_src-1}:0][{rw-1}:0] unused_trans_rc_idx;')
        A(f'  logic [{nfu-1}:0] unused_trans_fu_type;')
        A('  logic unused_trans_valid, unused_trans_rob_flag, unused_trans_blocked;')
        A('  logic unused_trans_issued, unused_trans_first_issue, unused_trans_deq_port;')
        A(f'  logic [{v.rob_w-1}:0] unused_trans_rob_value;')
        A('  logic [1:0] unused_trans_issue_timer;')
        A('  logic unused_enq_ready, unused_trans_out_valid;')
    if not ov.has_deq_port:
        A('  logic unused_deq_port_idx;')
    if not ov.has('io_commonOut_cancelBypass'):
        A('  logic unused_cancel_bypass;')
    if not ov.is_trans:
        A('  logic unused_dbg_trans_valid;')
    # 没有 IQ 唤醒的变体：golden 的 CommonOutBundle 里这三组是
    # Option.when(hasIQWakeUp)，整组不存在 —— 核的出口接悬空线
    for nm, port in (('ld_cancel', 'perfLdCancel'), ('og0_cancel', 'perfOg0Cancel'),
                     ('wakeup_by_wb', 'perfWakeupByWB')):
        if not ov.has(f'io_commonOut_{port}_0'):
            A(f'  logic [{n_src-1}:0] unused_dbg_{nm};')
    if not ov.has('io_commonOut_perfWakeupByIQ_0_0'):
        A(f'  logic [{n_src-1}:0][{max(1,n_iq)-1}:0] unused_dbg_wakeup_by_iq;')
    A('')
    return L, (v, n_src, n_wk, n_iq, nfu, ew, rw)


def gen_rtl_body(ov, L, ctx):
    v, n_src, n_wk, n_iq, nfu, ew, rw = ctx
    A = L.append
    p = lambda n, dflt: (n if ov.has(n) else dflt)
    rev = lambda fmt, n: ', '.join(fmt % i for i in reversed(range(n)))

    # ---------------- 参数 ----------------
    A('  xs_iq_entry #(')
    A(f'    .IS_ENQ(0), .IS_TRANS({int(ov.is_trans)}), .IS_COMP({int(not ov.is_trans)}),')
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
        A("    .IQ_TYPE_BIT({" + ', '.join(f"3'd{v.iq_tbit[s]}"
                                           for s in reversed(range(n_src))) + '}),')
        A('    .IQ_IS_LD_PIPE({' + ', '.join(
            bitvec(set(v.iq_self_pipe[w]), v.ld_pipes)
            for w in reversed(range(n_iq))) + '}),')
        A(f'    .HAS_REG_CACHE({int(v.has_rc)}), .RC_IDX_W({rw}),')
        A('    .IQ_WRITE_RC(' + bitvec(v.rc_lanes, n_iq)
          + f'), .RC_TYPE_BIT({v.rc_tbit}),')
    A('    .SRC_WB_MASK({' + ', '.join(bitvec(set(v.src_wb[s]), n_wk)
                                       for s in reversed(range(n_src))) + '}),')
    A("    .SRC_TYPE_BIT({" + ', '.join(f"3'd{v.src_tbit[s]}"
                                        for s in reversed(range(n_src))) + '}),')
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
    c.append('.enq_blocked(io_commonIn_enq_bits_status_blocked)')
    c.append('.enq_issued(io_commonIn_enq_bits_status_issued)')
    c.append('.enq_first_issue(io_commonIn_enq_bits_status_firstIssue)')
    c.append('.enq_issue_timer(io_commonIn_enq_bits_status_issueTimer)')
    c.append('.enq_deq_port_idx(%s)'
             % p('io_commonIn_enq_bits_status_deqPortIdx', "1'b0"))
    c.append('.enq_payload(enq_payload)')
    if ov.has_ld_dep:
        c.append('.enq_ld_dep({%s})' % ', '.join(
            f'io_commonIn_enq_bits_status_srcStatus_{s}_srcLoadDependency_{q}'
            for s in reversed(range(n_src)) for q in reversed(range(v.ld_pipes))))
    else:
        c.append(".enq_ld_dep('0)")
    for tag, fld in (('exu_src', 'exuSources_value'), ('use_rc', 'useRegCache'),
                     ('rc_idx', 'regCacheIdx')):
        nm = f'io_commonIn_enq_bits_status_srcStatus_0_{fld}'
        c.append('.enq_%s({%s})' % (tag, ', '.join(
            f'io_commonIn_enq_bits_status_srcStatus_{s}_{fld}'
            for s in reversed(range(n_src)))) if ov.has(nm) else f".enq_{tag}('0)")
    # WB 唤醒：当拍总线接真信号，入队延迟窗口是 enq 条目专属，这里全钉 0
    c.append('.wk_valid({%s})' % rev('io_commonIn_wakeUpFromWB_%d_valid', n_wk))
    for w in range(n_wk):
        assert ov.has(f'io_commonIn_wakeUpFromWB_{w}_bits_{v.wk_wen[w]}'), (
            f'{ov.mod}: WB{w} 的写使能字段 {v.wk_wen[w]} 在本模块端口表里不存在')
    c.append('.wk_wen({%s})' % ', '.join(
        f'io_commonIn_wakeUpFromWB_{w}_bits_{v.wk_wen[w]}'
        for w in reversed(range(n_wk))))
    c.append('.wk_pdest({%s})' % rev('io_commonIn_wakeUpFromWB_%d_bits_pdest', n_wk))
    c.append('  // ★ 入队延迟窗口只有 EnqEntry 有（IS_ENQ=1）；OthersEntry 的 golden')
    c.append('  //   根本没有 wakeUpFromWBDelayed / enqDelay 这组端口，故整组钉 0')
    c.append(".wkd_valid('0), .wkd_wen('0), .wkd_pdest('0)")
    if n_iq:
        # ★ 每一路的写使能字段名逐路量（v.iq_wen[w] 可能是 None：那一路
        #   在 golden 里根本没有到任何源的路由，整路是死的）
        c.append('.iq_wen({%s})' % ', '.join(
            (f'io_commonIn_wakeUpFromIQ_{w}_bits_{v.iq_wen[w]}'
             if v.iq_wen[w] and ov.has(
                 f'io_commonIn_wakeUpFromIQ_{w}_bits_{v.iq_wen[w]}') else "1'b0")
            for w in reversed(range(n_iq))))
        c.append('.iq_pdest({%s})' % rev('io_commonIn_wakeUpFromIQ_%d_bits_pdest', n_iq))
        # ★ IQ 唤醒带不带 loadDependency 是**逐族**的：INT/MEM 族带，FP 族不带。
        #   第一版这里无条件引用了 FP 族没有的端口名 —— VCS 会**静默**建一根隐式
        #   线（0 Error 0 Warning），于是 impl 侧整条影子通路是 X。
        #   现在由 check_port_refs() 兜底：引用 golden 没有的端口名直接生成失败。
        if ov.has('io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0'):
            c.append('.iq_ld_dep({%s})' % ', '.join(
                f'io_commonIn_wakeUpFromIQ_{w}_bits_loadDependency_{q}'
                for w in reversed(range(n_iq)) for q in reversed(range(v.ld_pipes))))
        else:
            c.append(".iq_ld_dep('0)")
        c.append('.iq_rc_dest({%s})' % rev(
            'io_commonIn_wakeUpFromIQ_%d_bits_rcDest', n_iq)
            if ov.has('io_commonIn_wakeUpFromIQ_0_bits_rcDest') else ".iq_rc_dest('0)")
        c.append('  // iq_cancel[w] = og0Cancel[第 w 路的全局 exu 下标] & is0Lat[w]；')
        c.append('  // og0Cancel 的下标是稀疏的，is0Lat 有的路被 firtool 折成常量。')
        c.append('.iq_cancel({%s})' % ', '.join(
            ("1'b0" if v.og0_idx[w] is None else
             (f'(io_commonIn_og0Cancel_{v.og0_idx[w]} & '
              f'io_commonIn_wakeUpFromIQ_{w}_bits_is0Lat)'
              if v.is0lat_kind[w] == 'real'
              else f'io_commonIn_og0Cancel_{v.og0_idx[w]}'))
            for w in reversed(range(n_iq))))
        c.append(".iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0)")
        c.append(".iqd_cancel('0)")
    else:
        c.append(".iq_wen('0), .iq_pdest('0), .iq_ld_dep('0), .iq_rc_dest('0)")
        c.append(".iq_cancel('0)")
        c.append(".iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0)")
        c.append(".iqd_cancel('0)")
    for tag, fld in (('ld1_cancel', 'ld1Cancel'), ('ld2_cancel', 'ld2Cancel')):
        if ov.has(f'io_commonIn_ldCancel_0_{fld}'):
            c.append('.%s({%s})' % (tag, ', '.join(
                f'io_commonIn_ldCancel_{q}_{fld}'
                for q in reversed(range(ov.n_ld_cancel)))))
        else:
            c.append(f".{tag}('0)")
    c.append(".ld1d_cancel('0), .ld2d_cancel('0), .enqd_self_ld_dep('0)")
    for tag, fld in (('vl_int_is_zero', 'vlFromIntIsZero'),
                     ('vl_int_is_vlmax', 'vlFromIntIsVlmax'),
                     ('vl_vf_is_zero', 'vlFromVfIsZero'),
                     ('vl_vf_is_vlmax', 'vlFromVfIsVlmax')):
        c.append('.%s(%s)' % (tag, p(f'io_commonIn_{fld}', "1'b0")))
    c.append('.deq_sel(io_commonIn_deqSel)')
    c.append('.deq_port_idx_write(%s)' % p('io_commonIn_deqPortIdxWrite', "1'b0"))
    c.append('.resp_valid(io_commonIn_issueResp_valid)')
    c.append('.resp_bits(io_commonIn_issueResp_bits_resp)')
    c.append('.trans_sel(%s)' % p('io_commonIn_transSel', "1'b0"))
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
    c.append('.o_enq_ready(%s)' % ('io_commonOut_enqReady' if ov.is_trans
                                   else 'unused_enq_ready'))
    c.append('.o_ety_rob_flag(io_commonOut_entry_bits_status_robIdx_flag)')
    c.append('.o_ety_rob_value(io_commonOut_entry_bits_status_robIdx_value)')
    c.append('.o_ety_psrc(ety_psrc), .o_ety_src_type(ety_src_type)')
    c.append('.o_ety_payload(ety_payload), .o_ety_ld_dep(ety_ld_dep)')
    c.append('.o_ety_rc_idx(ety_rc_idx), .o_exu_src(exu_src)')
    tp = (lambda s: s) if ov.is_trans else (lambda s: 'unused_' + s)
    c.append('.o_trans_valid(%s)' % ('io_commonOut_transEntry_valid' if ov.is_trans
                                     else 'unused_trans_out_valid'))
    c.append('.o_trans_rob_flag(%s)'
             % ('io_commonOut_transEntry_bits_status_robIdx_flag' if ov.is_trans
                else 'unused_trans_rob_flag'))
    c.append('.o_trans_rob_value(%s)'
             % ('io_commonOut_transEntry_bits_status_robIdx_value' if ov.is_trans
                else 'unused_trans_rob_value'))
    for tag in ('trans_fu_type', 'trans_psrc', 'trans_src_type', 'trans_src_state',
                'trans_data_src', 'trans_payload', 'trans_ld_dep', 'trans_exu_src',
                'trans_use_rc', 'trans_rc_idx'):
        c.append(f'.o_{tag}({tp(tag)})')
    for tag, port in (('trans_blocked', 'blocked'), ('trans_issued', 'issued'),
                      ('trans_first_issue', 'firstIssue'),
                      ('trans_issue_timer', 'issueTimer'),
                      ('trans_deq_port_idx', 'deqPortIdx')):
        full = f'io_commonOut_transEntry_bits_status_{port}'
        c.append('.o_%s(%s)' % (tag, full if ov.has(full)
                                else 'unused_' + tag.replace('deq_port_idx', 'deq_port')))
    # ---- debug / perf ----
    c.append('  // golden 的 7 组 debug/perf 输出（EntryBundles.scala:476-483）')
    c.append('.o_dbg_entry_in_valid(io_commonOut_entryInValid)')
    c.append('.o_dbg_entry_out_deq_valid(io_commonOut_entryOutDeqValid)')
    c.append('.o_dbg_entry_out_trans_valid(%s)'
             % ('io_commonOut_entryOutTransValid' if ov.is_trans
                else 'unused_dbg_trans_valid'))
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
    lines, pend = [], []
    for x in c:
        if x.lstrip().startswith('//'):
            lines.append((None, '    ' + x.strip()))
        else:
            lines.append(('c', '    ' + x))
    last = max(i for i, (k, _) in enumerate(lines) if k == 'c')
    A('\n'.join(s + (',' if k == 'c' and i < last else '')
                for i, (k, s) in enumerate(lines)))
    A('  );')
    A('')

    # ---------------- 展开输出 ----------------
    A(f'  // fuType 出口：核只存本变体保留的 {nfu} 位，这里放回 {v.fu_w} 位'
      ' one-hot 的原位置')
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
    if ov.is_trans:
        A('')
        A('  // commonOut.transEntry —— 交给下一级的整包（= entryUpdate）')
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
    return '\n'.join(L) + '\n'


# =============================================================================
def cov_names(ov):
    """本变体要守的覆盖闸。逐项都要在 200k 拍里非零，否则判 FAIL。

    单条目比阵列更容易出假绿：只要 tb 不让它入队/发射/被唤醒，逐拍比对全是
    「两边都空」的平凡相等。所以这些闸不是装饰，是 errors=0 能不能当证据的前提。"""
    v = ov.v
    nm = ['enq_fire', 'wb_wake', 'can_issue', 'deq_fire',
          'resp_succ', 'resp_block', 'resp_uncertain', 'deq_clear', 'flush_hit']
    if ov.is_trans:
        nm += ['trans_fire', 'enq_while_valid']   # 转移走 / 满位时被顶替
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
    A('//   （见文件末 finish 里的 covchk），任一为 0 判 FAIL：')
    for nm in cov_names(ov):
        A(f'//     {nm}')
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
    A(f'//   1) pdest/psrc 共用 {8} 值小池，否则唤醒永远打不中在队 uop 的源；')
    A('//   2) srcType 按各源真实的门控位给，给错了那一路唤醒整条哑掉；')
    A('//   3) deqSel / transSel 在时钟沿**之前**用阻塞赋值从 golden 当拍已落定的')
    A('//      canIssue 算出来，否则慢一拍全打空（纯随机命中概率极低）。')
    A('//')
    A(f'// 自动生成：verif/ut/{ov.mod}/gen.py（共享库 verif/ut/OthersEntry_common/'
      'othersentry_gen.py）—— 勿手改')
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
    A('  bit warm = 0;              // 条目被写过 -> 进入比对')
    A('  longint warm_cycle = -1;')
    A('  task automatic covchk(string nm, int c);')
    A('    $display("  cov %-20s = %0d", nm, c);')
    A('    if (c == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: %s == 0", nm); end')
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
    A('  function automatic int rnd_reg(); return $urandom_range(0, POOL-1); endfunction')
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
        pn = f'io_commonIn_enq_bits_status_srcStatus_{s}_exuSources_value'
        if ov.has(pn):
            A(f"    {pn} <= {v.exu_w}'($urandom_range(0, {v.n_wk_iq}));")
        pn = f'io_commonIn_enq_bits_status_srcStatus_{s}_useRegCache'
        if ov.has(pn):
            A(f'    {pn} <= ($urandom_range(0, 99) < 40);')
            A(f'    io_commonIn_enq_bits_status_srcStatus_{s}_regCacheIdx <= '
              f"{v.rc_idx_w}'(rnd_rc());")
    for pn, expr in (('blocked', '($urandom_range(0, 99) < 10)'),
                     ('issued', '($urandom_range(0, 99) < 20)'),
                     ('firstIssue', '$urandom_range(0, 1)'),
                     ('issueTimer', "2'($urandom_range(0, 3))"),
                     ('deqPortIdx', '$urandom_range(0, 1)')):
        n = f'io_commonIn_enq_bits_status_{pn}'
        if ov.has(n):
            A(f'    {n} <= {expr};')
    A('    // 入队负载：逐字段随机（负载是一大排寄存器，装载时整份吃进来）')
    for n, w in v.pl_all:
        p = ov.ipl(n)
        if ov.has(p):
            A(f"    {p} <= {w}'($urandom());" if w <= 32
              else f"    {p} <= {{$urandom(), $urandom(), $urandom()}};")
    for w in range(n_wk):
        A(f'    io_commonIn_wakeUpFromWB_{w}_valid <= ($urandom_range(0, 99) < 55);')
        A(f'    io_commonIn_wakeUpFromWB_{w}_bits_{v.wk_wen[w]} <= '
          '($urandom_range(0, 99) < 85);')
        A(f"    io_commonIn_wakeUpFromWB_{w}_bits_pdest <= "
          f"{v.pdest_w}'(rnd_reg());")
    for w in range(n_iq):
        if v.iq_wen[w]:
            A(f'    io_commonIn_wakeUpFromIQ_{w}_bits_{v.iq_wen[w]} <= '
              '($urandom_range(0, 99) < 30);')
        A(f"    io_commonIn_wakeUpFromIQ_{w}_bits_pdest <= {v.pdest_w}'(rnd_reg());")
        for q in range(v.ld_pipes):
            pn = f'io_commonIn_wakeUpFromIQ_{w}_bits_loadDependency_{q}'
            if ov.has(pn):
                A(f"    {pn} <= {v.ld_dep_w}'($urandom_range(0, "
                  f"{(1 << v.ld_dep_w) - 1}));")
        pn = f'io_commonIn_wakeUpFromIQ_{w}_bits_is0Lat'
        if ov.has(pn):
            A(f'    {pn} <= ($urandom_range(0, 99) < 60);')
        pn = f'io_commonIn_wakeUpFromIQ_{w}_bits_rcDest'
        if ov.has(pn):
            A(f"    {pn} <= {v.rc_idx_w}'(rnd_rc());")
    for idx in sorted({v.og0_idx[w] for w in range(n_iq)
                       if v.og0_idx[w] is not None}):
        A(f'    io_commonIn_og0Cancel_{idx} <= ($urandom_range(0, 99) < 20);')
    for q in range(ov.n_ld_cancel):
        for fld in ('ld1Cancel', 'ld2Cancel'):
            pn = f'io_commonIn_ldCancel_{q}_{fld}'
            if ov.has(pn):
                A(f'    {pn} <= ($urandom_range(0, 99) < 15);')
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
    A('  // ---- deqSel / transSel：必须在时钟沿之前按 golden 当拍的 canIssue 算 ----')
    A('  // 纯随机给的话命中 canIssue 的概率极低，发射通路整轮不动（假绿的头号来源）。')
    A('  task automatic drive_sel();')
    A('    io_commonIn_deqSel = g_io_commonOut_canIssue && ($urandom_range(0, 99) < 70);')
    if ov.is_trans:
        A('    io_commonIn_transSel = g_io_commonOut_valid && ($urandom_range(0, 99) < 25);')
    A('  endtask')
    A('')
    return L


def gen_tb_tail(ov, L):
    v = ov.v
    A = L.append
    n_iq = v.n_wk_iq
    g = lambda n: 'g_io_commonOut_' + n
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
        g(f'perfWakeupByWB_{s}') for s in range(v.n_regsrc)))
    if ov.is_trans:
        A(f'    if ({g("entryOutTransValid")}) cov_trans_fire++;')
        A(f'    if (io_commonIn_enq_valid && {g("valid")}) cov_enq_while_valid++;')
    if n_iq:
        A('    if (%s) cov_iq_wake++;' % ' || '.join(
            g(f'perfWakeupByIQ_{s}_{w}')
            for s in range(v.n_regsrc) for w in range(n_iq)))
        A('    if (%s) cov_og0_cancel_hit++;' % ' || '.join(
            g(f'perfOg0Cancel_{s}') for s in range(v.n_regsrc)))
    if ov.n_ld_cancel:
        A('    if (%s) cov_ld_cancel_hit++;' % ' || '.join(
            g(f'perfLdCancel_{s}') for s in range(v.n_regsrc)))
    if v.has_rc:
        A('    if (%s) cov_rc_hit++;' % ' || '.join(
            f'io_commonIn_enq_bits_status_srcStatus_{s}_useRegCache'
            for s in range(v.n_regsrc)))
    if v.has_ignore:
        A('    // ignoreOldVd 走的是 vl 写回那两路；这里只统计条件成立的拍数')
        A('    if (io_commonIn_vlFromIntIsZero || io_commonIn_vlFromVfIsZero)'
          ' cov_ignore_old_vd++;')
    A('  endtask')
    A('')
    A('  longint cyc = 0;')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    reset = 1;')
    A('    drive();')
    A("    io_commonIn_deqSel = 1'b0;")
    if ov.is_trans:
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
    A('      // drive() 用非阻塞在负沿给值，到这里 io_commonIn_enq_valid 仍是刚才')
    A('      // 那一拍的取值 —— 它为 1 就说明本拍沿上条目被整份写过了。')
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
    本生成器第一版就栽在这里：无条件引用了 FP 族没有的
    `io_commonIn_wakeUpFromIQ_<w>_bits_loadDependency_<q>`，
    编译 rc=0、lint 干净，UT 才在 96307 个 X 上炸出来 —— 而且只在 simp 变体上炸
    （comp 不产出 transEntry，那条影子没有出口，X 被 DCE 掉了），
    很容易被当成「simp 的某处逻辑写错了」去查。

    所以这里反过来钉死：引用集合必须 ⊆ golden 端口集合。
    做过负测：verif/ut/OthersEntry_common/test_port_ref_gate.py
    """
    declared = {n for _, _, n, _ in ov.ports} | {'io'}   # 'io' 不会单独出现，占位
    # 只看端口连接与右值里的标识符，注释行不算（注释里会写端口名举例）
    body = '\n'.join(l.split('//')[0] for l in rtl.split('\n'))
    used = set(re.findall(r'\bio_[A-Za-z0-9_]+', body))
    bad = sorted(used - declared)
    if bad:
        raise AssertionError(
            f'{ov.mod}: wrapper 引用了 golden 没有的端口名（VCS 会静默建隐式线 -> X）：'
            + ', '.join(bad[:8]) + (f' …共 {len(bad)} 个' if len(bad) > 8 else ''))
    return len(used)


# =============================================================================
def gen_mk(ov):
    v = ov.v
    # 条目模块自己例化的 golden 子模块（exuSources 的 UIntCompressor_*）。
    # 重写核把它内联了，所以 UT 的 golden 侧与 FM 的 ref 侧都要带上它做闭包。
    sub = sorted({t for t in re.findall(
        r'^  ([A-Z][A-Za-z0-9_]*) [a-zA-Z_]\w*\s*\($', read(ov.mod), re.M)})
    extra_golden = ''.join(f' \\\n              $(GOLDEN_RTL)/{m}.sv' for m in sub)
    extra_deps = ' '.join(f'{m}.sv' for m in sub)
    return f"""# {ov.mod} UT/FM 入口（OthersEntry* 家族：{ov.parent[len('Entries'):]} 的 {ov.role}）
# 重写件只有两个：三族共享的参数化单条目核 + 本变体薄文件。
# 核体是 xs_iq_entries_core.sv 里的 xs_iq_entry —— 与 Entries* 家族**同一份**，
# 不复制（CONVENTIONS「变体家族：核体绝不复制」）。
# 自动生成：verif/ut/{ov.mod}/gen.py
#   （共享库 verif/ut/OthersEntry_common/othersentry_gen.py）
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
# FM 证明配置 —— 与 Entries* 家族同因同配，两项都是**加强**不是放宽
# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false：golden 把条目负载展平成上百个逐字段寄存器，其中本变体
#   用不到的字段整组是常数；merge_duplicated_registers=true 时 FM 在 golden 侧
#   把这些同值寄存器合并掉，而可读核把同一份负载存在一根向量里、按位不合并，
#   于是两侧点数对不上。置 false 后两侧都逐个保留 —— 要求逐个比而不是合并后比。
FM_MERGE_DUP = false
# 本变体的 FM 点数尚未实测；预测登记在 verif/ut/{ov.mod}/PREDICT.txt。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = false

include ../../../scripts/ut_common.mk

# golden 带 XSError/XSPerf 等非综合断言，随机激励会踩到 $fatal；两侧统一关掉。
VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 复位域：条目寄存器（entryReg_*）在 golden 里**不复位**，只有 validReg 带复位
# （实测 {ov.mod}.sv 的 `if (reset)` 只钉这一个）。可读核照抄。
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

# 变异靶子：往可读核里注入若干个**真实形态**的 bug，要求本 UT 每一个都抓得住。
.PHONY: mutants
mutants:
	python3 ../OthersEntry_common/mutants.py $(MODULE) $(MUTANT_ARGS)
"""


def gen_stub(ov):
    return (f'#!/usr/bin/env python3\n'
            f'"""{ov.mod} 的生成入口（薄壳）。真正的代码在共享库里，'
            f'24 个变体共用一份代码路径。"""\n'
            f'import sys, pathlib\n'
            f'sys.path.insert(0, str(pathlib.Path(__file__).resolve()'
            f'.parents[1] / "OthersEntry_common"))\n'
            f'from othersentry_gen import main\n'
            f'sys.exit(main("{ov.mod}"))\n')


def main(mod):
    check = '--check' in sys.argv
    ov = OthersVariant(mod)
    L, ctx = gen_rtl(ov)
    rtl = gen_rtl_body(ov, L, ctx)
    n_ref = check_port_refs(ov, rtl)
    tb = gen_tb_tail(ov, gen_tb(ov))
    here = REPO / 'verif' / 'ut' / mod
    files = {
        REPO / 'rtl' / 'backend' / f'{mod}.sv': rtl,
        here / 'tb.sv':    tb,
        here / 'Makefile': gen_mk(ov),
        here / 'gen.py':   gen_stub(ov),
    }
    bad = 0
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
        print(f'\n[{mod}] {ov.role} of {ov.parent} x{ov.count}  '
              f'regsrc={v.n_regsrc} wb={v.n_wk} iq={v.n_wk_iq} '
              f'PL_DEQ_W={v.pl_deq_w} PL_TRANS_W={v.pl_trans_w} '
              f'ports={len(ov.ports)}')
    return bad


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
