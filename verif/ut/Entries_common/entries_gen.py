#!/usr/bin/env python3
"""Entries* 家族薄变体文件 + UT 生成器（共享库，14 个变体共用一份代码路径）。

各变体目录下的 gen.py 只是薄壳：`from entries_gen import main; main("Entries<V>")`。
★ 这样做的理由：手工贴在生成产物上的东西会被下一次跑生成器静默删掉（本轮已踩两次），
  所以变体之间的差异一律走"从 golden 量出来的参数"，不走"在产物上手改"。

一切事实都从 G1 golden 机械提取，不接受人工转述：
  * 顶层端口表         <- golden Entries<V>.sv 的 module 头（逐行原样搬运）
  * 条目分段 / 尺寸     <- golden 里 EnqEntry/OthersEntry 的实例名与数量
  * 负载字段与位宽      <- golden EnqEntry_N.sv 的 commonOut_{entry,transEntry} 端口
  * 唤醒路由表         <- golden EnqEntry_N.sv 的 currentStatus_srcStatus_<s>_srcState
                          表达式里出现的 WB 下标 / wen 字段 / srcType 位
FM 钉点（fm_pins_pre.tcl）由同目录的 gen_fm_pins.py 生成，它复用本文件的
Variant.pl_off 字段偏移表 —— 生成 RTL 和生成钉点用的是同一张表，不会各算各的。

用法：
  python3 gen.py            # 生成
  python3 gen.py --check    # 只校验已提交产物没漂移（非零退出=漂移）
"""
import re, sys, pathlib, collections

HERE   = pathlib.Path(__file__).resolve().parent
REPO   = HERE.parents[2]
def outdir(top):
    return REPO / 'verif' / 'ut' / top
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')

PORT_RE = re.compile(
    r'^\s*(input|output)\s+(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s+)?([A-Za-z_]\w*)\s*,?\s*$')


def read(mod):
    return (GOLDEN / f'{mod}.sv').read_text()


def port_decls(mod):
    """返回 [(dir, width, name, 原始声明行去掉尾逗号)]，顺序即 golden 顺序。"""
    txt = read(mod)
    m = re.search(r'^module\s+%s\s*\(\n(.*?)^\);' % re.escape(mod), txt, re.S | re.M)
    if not m:
        sys.exit(f'解析失败：{mod} 找不到 module 头')
    out = []
    for line in m.group(1).split('\n'):
        pm = PORT_RE.match(line)
        if not pm:
            continue
        d, hi, lo, nm = pm.groups()
        if hi is not None and int(lo) != 0:
            sys.exit(f'{mod}.{nm}: 非 [n:0] 端口，生成器未覆盖')
        out.append((d, 1 if hi is None else int(hi) + 1, nm, line.rstrip().rstrip(',')))
    return out


class Variant:
    def __init__(self, top):
        self.top = top
        self.ports = port_decls(top)
        self.pmap = {n: (d, w) for d, w, n, _ in self.ports}
        txt = read(top)

        # ---- 条目分段：从实例声明里数 ----
        insts = re.findall(r'^  ([A-Za-z]\w*) (enqEntries_\d+|othersEntriesSimp_\d+'
                           r'|othersEntriesComp_\d+)\s*\(', txt, re.M)
        cnt = collections.Counter(n.rsplit('_', 1)[0] for _, n in insts)
        self.n_enq  = cnt['enqEntries']
        self.n_simp = cnt['othersEntriesSimp']
        self.n_comp = cnt['othersEntriesComp']
        self.n_ent  = self.n_enq + self.n_simp + self.n_comp
        self.enq_mod  = next(t for t, n in insts if n == 'enqEntries_0')
        self.simp_mod = next(t for t, n in insts if n == 'othersEntriesSimp_0')
        self.comp_mod = next(t for t, n in insts if n == 'othersEntriesComp_0')
        pol = re.findall(r'^  (EnqPolicy\w*) \w+\s*\(', txt, re.M)
        assert pol, f'{top}: 找不到 EnqPolicy 实例'
        self.enq_policy = pol[0]
        # 条目子模块还会例化别的 golden 模块（exuSources 的 UIntCompressor_* 就是），
        # 这些也必须进 GOLDEN_SRCS 与 FM 的 ref 依赖闭包，否则编译/证明缺件。
        known = {self.enq_mod, self.simp_mod, self.comp_mod, self.enq_policy, top}
        self.extra_mods = []
        for m in (self.enq_mod, self.simp_mod, self.comp_mod):
            for t2 in re.findall(r'^  ([A-Z][A-Za-z0-9_]*) [a-zA-Z_]\w*\s*\($',
                                 read(m), re.M):
                if t2 not in known and t2 not in self.extra_mods:
                    self.extra_mods.append(t2)

        # ---- 尺寸 ----
        self.n_deq    = sum(1 for n in self.pmap if re.fullmatch(r'io_deqSelOH_\d+_valid', n))
        self.n_regsrc = sum(1 for n in self.pmap
                            if re.fullmatch(r'io_enq_0_bits_status_srcStatus_\d+_psrc', n))
        self.n_wk     = sum(1 for n in self.pmap if re.fullmatch(r'io_wakeUpFromWB_\d+_valid', n))
        self.rob_w    = self.pmap['io_flush_bits_robIdx_value'][1]
        self.psrc_w   = self.pmap['io_enq_0_bits_status_srcStatus_0_psrc'][1]
        self.pdest_w  = self.pmap['io_wakeUpFromWB_0_bits_pdest'][1]
        self.fu_w     = self.pmap['io_fuType_0'][1]
        self.need_og2 = 'io_og2Resp_0_valid' in self.pmap
        # ---- issueResp 查找表:firtool 把 og?Resp.bits.resp 折成常量的那几档 ----
        # golden 里长这样(4 档按 issueTimer 索引，低位在右):
        #   wire [3:0][1:0] _GEN_6 = {{2'h0}, {io_og2Resp_0_bits_resp}, {2'h1}, {2'h0}};
        # 逐变体不同（Alu* 是 og1 带真 resp、og0 折成 BLOCK），所以只能从 golden 读，
        # 不能按"og2 才是真 resp"这类经验规则写死。
        # ★ golden 给**每个发射口各生成一张**表（numDeq=2 就是两张）。只读第一张
        #   等于假设"两口共用"——这正是本轮 Predictor 上踩到的那类坑（per-dup 信号
        #   部分共用部分分份，可读核写成一份、UT 完全看不见）。所以逐张读出来，
        #   把口号擦掉之后要求完全一致；不一致就必须做成按口分份的参数。
        gms = re.findall(r"wire \[3:0\]\[1:0\]\s+_GEN_\d+ = \{(.*?)\};", txt, re.S)
        assert len(gms) == self.n_deq, (
            f'{top}: issueResp 常量表 {len(gms)} 张，发射口 {self.n_deq} 个 —— 对不上')
        norm = {re.sub(r'Resp_\d+_bits', 'Resp_D_bits', g) for g in gms}
        assert len(norm) == 1, (
            f'{top}: 各发射口的 issueResp 常量表形状不同，不能当成共用一张:\n'
            + '\n'.join(gms))
        slots = [x.strip() for x in re.findall(r"\{([^{}]*)\}", gms[0])]
        assert len(slots) == 4, f'{top}: issueResp 表不是 4 档: {slots}'
        slots = slots[::-1]                      # 拼接是高位在前，翻成 timer 0..3
        self.og_has_bits, self.og_const = [], []
        for k, v in enumerate(slots):
            m2 = re.fullmatch(r"2'h([0-9a-f])", v)
            self.og_has_bits.append(0 if m2 else 1)
            self.og_const.append(int(m2.group(1), 16) if m2 else 0)
        assert self.og_has_bits[3] == 0, f'{top}: timer==3 档竟然带真 resp'

        # ---- comp 段的条目有没有 srcLoadDependency 寄存器 ----
        # ★ 不能按"comp 一律没有"写死 —— 那是从 VfdivVidiv 外推的错结论。
        #   有 ldCancel 的变体里 comp 条目是带的（实测 14/14，见字段矩阵）。
        self.comp_has_ld_dep = any(
            re.fullmatch(r'io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_\d+', n)
            for _, _, n, _ in port_decls(self.comp_mod))
        assert self.pmap['io_valid'][1] == self.n_ent, 'io_valid 宽度与条目数不符'

        # ---- 本变体保留的 FuType one-hot 位号 ----
        self.fu_bits = sorted(int(m.group(1)) for m in
                              (re.fullmatch(r'io_enq_0_bits_status_fuType_(\d+)', n)
                               for n in self.pmap) if m)

        # ---- 每路 WB 的写使能字段名 ----
        self.wk_wen = []
        for w in range(self.n_wk):
            f = [n for n in self.pmap
                 if n.startswith(f'io_wakeUpFromWB_{w}_bits_') and not n.endswith('_pdest')]
            assert len(f) == 1, f'WB{w} 的写使能字段不唯一: {f}'
            self.wk_wen.append(f[0].split('_bits_')[1])

        # ---- 负载字段：DEQ 子集在前，TRANS 独有在后 ----
        ep = port_decls(self.enq_mod)
        def sub(pfx):
            return [(n[len(pfx):], w) for d, w, n, _ in ep if n.startswith(pfx)]
        deq_pl   = sub('io_commonOut_entry_bits_payload_')
        trans_pl = sub('io_commonOut_transEntry_bits_payload_')
        # imm 在 golden 的 EntryBundle 里与 payload 并列，但存法一模一样（一组寄存器，
        # 装载时吃入队值、否则保持）——所以并进同一根负载向量，记作伪字段 '#imm'。
        # 名字加 '#' 是因为 payload 里**另有**一个真字段就叫 imm。
        self.has_imm = 'io_commonOut_entry_bits_imm' in {n for _, _, n, _ in ep}
        if self.has_imm:
            iw = next(w for d, w, n, _ in ep if n == 'io_commonOut_entry_bits_imm')
            deq_pl   = [('#imm', iw)] + deq_pl
            trans_pl = [('#imm', iw)] + trans_pl
        dnames   = {n for n, _ in deq_pl}
        self.pl_deq   = deq_pl
        self.pl_extra = [(n, w) for n, w in trans_pl if n not in dnames]
        self.pl_all   = self.pl_deq + self.pl_extra
        self.pl_off, off = {}, 0
        for n, w in self.pl_all:
            self.pl_off[n] = (off, w); off += w
        self.pl_deq_w   = sum(w for _, w in self.pl_deq)
        self.pl_trans_w = off
        # srcLoadDependency 影子：从 EnqEntry 的 transEntry status 端口量出来
        ld = [(n, w) for d, w, n, _ in ep
              if re.match(r'io_commonOut_transEntry_bits_status_srcStatus_0_'
                          r'srcLoadDependency_\d+$', n)]
        self.has_ld_dep = bool(ld)
        self.ld_pipes = len(ld) if ld else 1
        self.ld_dep_w = ld[0][1] if ld else 1

        # 顶层 deqEntry 露出的负载字段必须是条目存的那一份的**子集**。
        # ★ 不是相等:条目(EnqEntry/OthersEntry 是独立模块,端口固定)存着整份 DEQ 负载,
        #   而 Entries 顶层会把本变体用不到的字段继续 DCE 掉 —— AluCsrFenceDiv 就比
        #   条目里少 10 个。要求相等是从 VfdivVidiv(恰好相等)外推出来的。
        top_deq = {n[len('io_deqEntry_0_bits_payload_'):] for n in self.pmap
                   if n.startswith('io_deqEntry_0_bits_payload_')}
        assert top_deq <= dnames, f'顶层 deq 负载多出条目没有的字段: {top_deq - dnames}'

        # ---- 唤醒路由：从 golden 的 currentStatus_srcStatus_<s>_srcState 里提 ----
        etxt = read(self.enq_mod)
        self.src_wb, self.src_tbit = [], []
        for s in range(self.n_regsrc):
            m = re.search(r'assign currentStatus_srcStatus_%d_srcState =\n(.*?);\n' % s,
                          etxt, re.S)
            assert m, f'找不到 currentStatus_srcStatus_{s}_srcState'
            body = m.group(1)
            self.src_wb.append(sorted({int(x) for x in re.findall(
                r'io_enqDelayIn1_wakeUpFromWB_(\d+)_valid', body)}))
            tb = {int(x) for x in re.findall(
                r'entryReg_status_srcStatus_%d_srcType\[(\d+)\]' % s, body)}
            assert len(tb) == 1, f'src{s} 的 srcType 门控位不唯一: {tb}'
            self.src_tbit.append(tb.pop())
        # ignoreOldVd 用的两路 vl 写回
        ig = re.search(r'wire\s+ignoreOldVd_(\d+) =\n(.*?);\n', etxt, re.S)
        self.has_ignore = ig is not None
        if self.has_ignore:
            self.vd_src = int(ig.group(1))
            vls = sorted({int(x) for x in re.findall(r'wakeUpFromVl_(\d+)', ig.group(2))})
            assert len(vls) == 2, f'wakeUpFromVl 路数异常: {vls}'
            self.wb_vl_int, self.wb_vl_vf = vls
            self.vl_src = self.n_regsrc - 1
        else:
            self.vd_src = self.vl_src = self.wb_vl_int = self.wb_vl_vf = 0

        # ---- IQ 即时唤醒(hasIQWakeUp 子族) ----
        etxt0 = read(self.enq_mod)
        self.n_wk_iq = sum(1 for n in self.pmap
                           if re.fullmatch(r'io_wakeUpFromIQ_\d+_bits_pdest', n))
        self.exu_w   = self.pmap.get(
            'io_exuSources_0_0_value', (None, 0))[1]
        # 每路 IQ 的写使能字段名与门控 srcType 位（从 wakeupVec_<s>_<w> 表达式量）
        self.iq_wen, self.iq_tbit = [], [None] * self.n_regsrc
        self.iq_mask = [set() for _ in range(self.n_regsrc)]
        for w in range(self.n_wk_iq):
            wen = None
            for s in range(self.n_regsrc):
                m = re.search(r'(?:assign |wire\s+)wakeupVec_%d_%d =\n(.*?);\n' % (s, w),
                              etxt0, re.S)
                if not m:
                    continue
                body = m.group(1)
                tb = {int(x) for x in re.findall(
                    r'srcStatus_%d_srcType\[(\d+)\]' % s, body)}
                assert len(tb) == 1, f'IQ{w}/src{s} 的 srcType 门控位不唯一: {tb}'
                if self.iq_tbit[s] is None:
                    self.iq_tbit[s] = tb.pop()
                f = {x for x in re.findall(r'wakeUpFromIQ_%d_bits_(\w+)\b' % w, body)
                     if x not in ('pdest', 'is0Lat')}
                assert len(f) == 1, f'IQ{w} 写使能字段不唯一: {f}'
                wen = f.pop()
                self.iq_mask[s].add(w)
            if wen is not None:
                self.iq_wen.append(wen)
            else:
                self.iq_wen.append(None)
        for s in range(self.n_regsrc):
            if self.iq_tbit[s] is None:
                self.iq_tbit[s] = 0

        # og0Cancel 的**稀疏全局下标** + is0Lat 是真信号还是被折成常量
        #   cancelSel[w] = og0Cancel[og0_idx[w]] & is0Lat[w]
        #   is0lat_kind: 'real'(有端口) / 'const1'(折成真) / 'const0'(整条 cancel 被删)
        self.og0_idx, self.is0lat_kind = [], []
        for w in range(self.n_wk_iq):
            m = re.search(r'wire\s+hasWakeupIQ_srcWakeupByIQ_\d+_%d = (.*?);\n' % w,
                          etxt0, re.S)
            if not m:
                self.og0_idx.append(None); self.is0lat_kind.append('const0'); continue
            body = m.group(1)
            cs = re.search(r'~cancelSel_(\d+)\b', body)
            if cs:
                m2 = re.search(r'wire\s+cancelSel_%s =\n(.*?);\n' % cs.group(1),
                               etxt0, re.S)
                assert m2, f'找不到 cancelSel_{cs.group(1)}'
                og = re.search(r'og0Cancel_(\d+)', m2.group(1))
                assert og and 'is0Lat' in m2.group(1)
                self.og0_idx.append(int(og.group(1))); self.is0lat_kind.append('real')
            else:
                og = re.search(r'~io_commonIn_og0Cancel_(\d+)', body)
                assert og, f'IQ{w} 的取消式子看不懂: {body[:120]}'
                self.og0_idx.append(int(og.group(1))); self.is0lat_kind.append('const1')

        # ShiftLoadDependency:哪一路 IQ 唤醒自己就是第 q 条 load 流水
        # （那一位在 golden 里是常数 1，于是 shifted 信号整个不生成）
        self.iq_self_pipe = []
        for w in range(self.n_wk_iq):
            have = {int(q) for q in re.findall(
                r'shiftedWakeupLoadDependencyByIQVec_%d_(\d)\b' % w, etxt0)}
            self.iq_self_pipe.append(sorted(set(range(self.ld_pipes)) - have) if have else [])

        # fuType 的 one-hot 位集合：顶层只是把每个条目的 commonOut.fuType 直连出去，
        # 真正决定"留哪几位"的是条目模块内部。所以位集合也逐条目类型核一遍，
        # 而不是从顶层的 io_enq_*_status_fuType_<b> 端口推给三种条目共用。
        fu_rx = re.compile(r'assign io_commonOut_fuType =\s*\{(.*?)\};', re.S)

        def fu_bits_of(mod):
            m = fu_rx.search(read(mod))
            assert m, f'{mod}: 找不到 io_commonOut_fuType 的构造'
            return sorted(int(x) for x in re.findall(
                r'entryReg_status_fuType_(\d+)', m.group(1)))

        for mod in (self.enq_mod, self.simp_mod, self.comp_mod):
            got = fu_bits_of(mod)
            assert got == self.fu_bits, (
                f'{top}: {mod} 的 fuType 位集合 {got} 与顶层端口推出来的 '
                f'{self.fu_bits} 不同 —— 不能共用一份 fu_bits')

        # WB 唤醒路由也一样：三种条目各是一个独立的 golden 模块，共享核只给一份
        # SRC_WB_MASK/SRC_TYPE_BIT，所以逐模块把 (WB 路, 源, srcType 位, 写使能字段)
        # 三元组抠出来比一遍，确认真的是共用而不是分份。
        wb_rx = re.compile(
            r'wakeUpFromWB_(\d+)_bits_pdest == entryReg_status_srcStatus_(\d+)_psrc\s*'
            r'&\s*entryReg_status_srcStatus_\2_srcType\[(\d+)\]\s*'
            r'&\s*io_commonIn_wakeUpFromWB_\1_bits_(\w+)', re.S)

        def wb_triples(mod):
            return {(int(a1), int(a2), int(a3), a4)
                    for a1, a2, a3, a4 in wb_rx.findall(read(mod))}

        wb_ref = wb_triples(self.enq_mod)
        for other in (self.simp_mod, self.comp_mod):
            got = wb_triples(other)
            assert got == wb_ref, (
                f'{top}: {other} 的 WB 唤醒路由与 {self.enq_mod} 不同 '
                f'(只在前者: {sorted(wb_ref - got)[:4]}; 只在后者: {sorted(got - wb_ref)[:4]}) '
                '—— 不能共用一份 SRC_WB_MASK/SRC_TYPE_BIT')

        # ★ 上面这份 IQ 路由是从 enq 条目量的。simp/comp 是**另外两个 golden 模块**，
        #   共享核却给它们同一份参数 —— 所以必须逐条目类型确认路由一致，
        #   而不是"同一份 Chisel 生成的，应该一样"。
        for other in (self.simp_mod, self.comp_mod):
            otxt = read(other)
            for w in range(self.n_wk_iq):
                for sx in range(self.n_regsrc):
                    m = re.search(
                        r'(?:assign |wire\s+)wakeupVec_%d_%d =\n(.*?);\n' % (sx, w),
                        otxt, re.S)
                    here_on = w in self.iq_mask[sx]
                    assert bool(m) == here_on, (
                        f'{top}: {other} 的 IQ{w}->src{sx} 路由与 {self.enq_mod} 不一致')
                    if not m:
                        continue
                    tb = {int(x) for x in re.findall(
                        r'srcStatus_%d_srcType\[(\d+)\]' % sx, m.group(1))}
                    assert tb == {self.iq_tbit[sx]}, (
                        f'{top}: {other} 的 IQ{w}->src{sx} srcType 门控位与 enq 不一致')
                    f = {x for x in re.findall(
                        r'wakeUpFromIQ_%d_bits_(\w+)\b' % w, m.group(1))
                        if x not in ('pdest', 'is0Lat')}
                    assert f == {self.iq_wen[w]}, (
                        f'{top}: {other} 的 IQ{w} 写使能字段与 enq 不一致: {f}')

        # ---- 寄存器缓存 ----
        self.has_rc   = 'io_enq_0_bits_status_srcStatus_0_useRegCache' in self.pmap
        self.rc_idx_w = self.pmap.get(
            'io_enq_0_bits_status_srcStatus_0_regCacheIdx', (None, 0))[1]
        self.rc_lanes, self.rc_tbit = set(), 0
        if self.has_rc:
            m = re.search(r'wire\s+wakeupRC =\n(.*?);\n', etxt0, re.S)
            assert m, '有 regCache 却找不到 wakeupRC'
            tb = {int(x) for x in re.findall(r'srcStatus_0_srcType\[(\d+)\]', m.group(1))}
            assert len(tb) == 1
            self.rc_tbit = tb.pop()
            # ★ 每个源各有一份 wakeupRCIdx（src0 叫 wakeupRCIdx，src1 叫 wakeupRCIdx_1…）。
            #   共享核只给一个 IQ_WRITE_RC 参数，所以必须先确认各源的写 RC 路集合相同。
            lanesets = []
            for sx in range(self.n_regsrc):
                nm = 'wakeupRCIdx' if sx == 0 else f'wakeupRCIdx_{sx}'
                m = re.search(r'wire \[\d+:0\]\s+%s =\n(.*?);\n' % nm, etxt0, re.S)
                assert m, f'有 regCache 却找不到 {nm}'
                lanesets.append(frozenset(int(x) for x in re.findall(
                    r'wakeUpFromIQ_(\d+)_bits_rcDest', m.group(1))))
            assert len(set(lanesets)) == 1, (
                f'{top}: 各源的"写 regcache 的 IQ 路"集合不同 {lanesets} —— '
                '不能共用一个 IQ_WRITE_RC 参数')
            self.rc_lanes = set(lanesets[0])

        # ---- ldCancel ----
        self.n_ld_cancel = sum(1 for n in self.pmap
                               if re.fullmatch(r'io_ldCancel_\d+_ld2Cancel', n))
        self.has_ld1 = 'io_ldCancel_0_ld1Cancel' in self.pmap
        self.has_ld2 = 'io_ldCancel_0_ld2Cancel' in self.pmap

        # ---- 顶层出口有没有这几组 ----
        self.out_exu    = 'io_exuSources_0_0_value' in self.pmap
        self.out_lddep  = 'io_loadDependency_0_0' in self.pmap
        self.out_cancel = 'io_cancelDeqVec_0' in self.pmap
        self.deq_rc     = 'io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx' in self.pmap
        self.deq_lddep  = ('io_deqEntry_0_bits_status_srcStatus_0_srcLoadDependency_0'
                           in self.pmap)


    # -- 小工具 --
    def enq_pl_port(self, i, f):
        return (f'io_enq_{i}_bits_imm' if f == '#imm'
                else f'io_enq_{i}_bits_payload_{f}')

    def deq_pl_port(self, d, f):
        return (f'io_deqEntry_{d}_bits_imm' if f == '#imm'
                else f'io_deqEntry_{d}_bits_payload_{f}')

    def plslice(self, f):
        off, w = self.pl_off[f]
        return f'[{off+w-1}:{off}]' if w > 1 else f'[{off}]'


def cov_names(v):
    """本变体要守的覆盖闸清单。

    ★ 一个 UT 如果注入 bug 也不报错，它的 errors=0 没有意义。逐拍比对只保证
      「两侧一样」，保证不了「激励真把逻辑推到了那个状态」——所以每条通路各挂一个闸，
      任一为 0 判 FAIL。本家族第一版 tb 就栽在这里：200k 拍里 deq_fire 只有 2 次。
    """
    nms = ['enq_fire', 'wb_wake', 'can_issue', 'deq_fire', 'deq_clear', 'first_issue',
           'resp_succ', 'resp_block', 'resp_uncertain',
           'trans2simp', 'trans2comp', 'simp2comp', 'full', 'flush']
    if v.n_deq > 1:
        nms.append('deq_both')
    if v.has_ignore:
        nms.append('ignore_old_vd')
    if v.n_wk_iq:
        nms += ['iq_wake', 'og0_cancel', 'ld_cancel', 'ds_forward']
        if v.has_rc:
            nms += ['rc_wake', 'ds_regcache']
    if v.out_cancel:
        nms.append('cancel_deq')
    if v.out_lddep:
        nms.append('lddep_nz')
    return nms


def bitvec(bits, n):
    return f"{n}'b" + ''.join('1' if i in bits else '0' for i in range(n - 1, -1, -1))


# =============================================================================
def gen_rtl(v):
    L = []
    A = L.append
    fu_list = ', '.join(f'FuType[{b}]' for b in v.fu_bits)
    A(f'// {v.top}.sv —— 发射队列条目阵列（{v.top[len("Entries"):]} 变体）薄包装层')
    A('// -----------------------------------------------------------------------------')
    A(f'// 核体见 xs_iq_entries_core.sv（Entries* 家族共享参数化核，本文件不含逻辑分支，')
    A('// 只把 golden 的扁平端口打包成核的数组/位向量接口，并给出本变体的参数）。')
    A('//')
    A(f'// 本变体规模（全部从 G1 golden {v.top}.sv 机械量得）：')
    A(f'//   条目 {v.n_ent} = enq {v.n_enq} + simp {v.n_simp} + comp {v.n_comp}，'
      f'发射口 {v.n_deq}，源寄存器 {v.n_regsrc} 个')
    if v.n_wk_iq:
        A(f'//   WB 唤醒 {v.n_wk} 路 + IQ 即时唤醒 {v.n_wk_iq} 路'
          f'（带 og0Cancel / ldCancel×{v.n_ld_cancel} 取消网络）')
        A('//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：')
        for w in range(v.n_wk_iq):
            og = ('og0Cancel[%d]' % v.og0_idx[w]) if v.og0_idx[w] is not None else '无取消'
            A(f'//     IQ{w}: {og}, is0Lat={v.is0lat_kind[w]}'
              + (f', 自身是 load 流水 {v.iq_self_pipe[w][0]}' if v.iq_self_pipe[w] else ''))
    else:
        A(f'//   WB 唤醒 {v.n_wk} 路（无 IQ 唤醒、无 og0Cancel、无 ldCancel）')
    A(f'//   保留的 FuType one-hot 位：{fu_list}')
    A(f'//   srcLoadDependency 影子：每源 {v.ld_pipes} 条 load 流水 × {v.ld_dep_w} 位'
      + ('（comp 段也存）' if v.comp_has_ld_dep else '（comp 段没有：整条通路是死的）'))
    if v.has_rc:
        A(f'//   寄存器缓存：regCacheIdx {v.rc_idx_w} 位，写 RC 的 IQ 路 {sorted(v.rc_lanes)}')
    A(f'//   issueResp 4 档（按 issueTimer）：'
      + ', '.join(f'timer{k}=' + ('真 resp' if v.og_has_bits[k] else f"常量 2'h{v.og_const[k]:x}")
                  for k in range(4)))
    A(f'//   负载：发射口可见 {len(v.pl_deq)} 个字段 / {v.pl_deq_w} 位；'
      f'转移包另带 {len(v.pl_extra)} 个字段，共 {v.pl_trans_w} 位')
    A(f'//   golden 层次：{v.enq_mod} ×{v.n_enq} + {v.simp_mod} ×{v.n_simp}'
      f' + {v.comp_mod} ×{v.n_comp} + {v.enq_policy} ×2，本文件把它们一并扁平化。')
    A('//')
    A('// 唤醒路由（从 golden currentStatus_srcStatus_<s>_srcState 表达式机械提取）：')
    for s in range(v.n_regsrc):
        lanes = v.src_wb[s]
        A(f'//   src{s}: WB[{lanes[0]}..{lanes[-1]}]（{v.wk_wen[lanes[0]]}），'
          f'门控 srcType[{v.src_tbit[s]}]')
    A('//')
    A(f'// 自动生成：verif/ut/{v.top}/gen.py（共享库 verif/ut/Entries_common/'
      'entries_gen.py）—— 勿手改')
    A('// =============================================================================')
    A(f'module {v.top} (')
    A(',\n'.join('  ' + d.strip() for _, _, _, d in v.ports))
    A(');')
    A('')
    A('  // BEGIN GENERATED(core-inst)')
    # ---- 打包输入 ----
    A(f'  logic [{v.n_enq-1}:0][{v.pl_trans_w-1}:0] enq_payload;')
    for i in range(v.n_enq):
        terms = []
        for n, w in reversed(v.pl_all):
            src = v.enq_pl_port(i, n)
            terms.append(src if src in v.pmap else (f"{w}'h0"))
        A(f'  assign enq_payload[{i}] = {{' + ', '.join(terms) + '};')
    A('')
    A(f'  logic [{v.n_deq-1}:0][{v.pl_deq_w-1}:0] deq_payload;')
    A(f'  logic [{v.n_ent-1}:0][{len(v.fu_bits)-1}:0] fu_type_narrow;')
    A(f'  logic [{v.n_deq-1}:0][{len(v.fu_bits)-1}:0] deq_fu_type;')
    A(f'  logic [{v.n_deq-1}:0][{v.n_regsrc-1}:0][{v.psrc_w-1}:0] deq_psrc;')
    A(f'  logic [{v.n_deq-1}:0][{v.n_regsrc-1}:0][3:0] deq_src_type;')
    A(f'  logic [{v.n_deq-1}:0] deq_rob_flag;')
    A(f'  logic [{v.n_deq-1}:0][{v.rob_w-1}:0] deq_rob_value;')
    A(f'  logic [{v.n_ent-1}:0][{v.n_regsrc-1}:0][3:0] data_src;')
    ew, rw = max(1, v.exu_w), max(1, v.rc_idx_w)
    A('  // 核的这几个出口：顶层有对应端口的接有名线（后面展开），没有的接悬空线')
    A(f'  logic [{v.n_ent-1}:0][{v.n_regsrc-1}:0][{ew-1}:0] '
      + ('exu_src;' if v.out_exu else 'unused_exu_src;'))
    A(f'  logic [{v.n_ent-1}:0][{v.ld_pipes-1}:0][{v.ld_dep_w-1}:0] '
      + ('ld_dep_out;' if v.out_lddep else 'unused_ld_dep;'))
    A(f'  logic [{v.n_deq-1}:0][{v.n_regsrc-1}:0][{v.ld_pipes-1}:0][{v.ld_dep_w-1}:0] '
      + ('deq_ld_dep;' if v.deq_lddep else 'unused_deq_ld_dep;'))
    A(f'  logic [{v.n_deq-1}:0][{v.n_regsrc-1}:0][{rw-1}:0] '
      + ('deq_rc_idx;' if v.deq_rc else 'unused_deq_rc_idx;'))
    if not v.out_cancel:
        A(f'  logic [{v.n_deq-1}:0] unused_cancel_deq;')
    A('')
    # ---- 核例化 ----
    A('  xs_iq_entries_core #(')
    A(f'    .NUM_ENQ({v.n_enq}), .NUM_SIMP({v.n_simp}), .NUM_COMP({v.n_comp}),'
      f' .NUM_DEQ({v.n_deq}),')
    A(f'    .NUM_REGSRC({v.n_regsrc}), .NUM_WK_WB({v.n_wk}),'
      f' .NUM_FU_BIT({len(v.fu_bits)}),')
    A(f'    .ROB_W({v.rob_w}), .PSRC_W({v.psrc_w}), .PDEST_W({v.pdest_w}),')
    A(f'    .PL_DEQ_W({v.pl_deq_w}), .PL_TRANS_W({v.pl_trans_w}),')
    A(f'    .HAS_LD_DEP({int(v.has_ld_dep)}),'
      f' .COMP_HAS_LD_DEP({int(v.comp_has_ld_dep)}),')
    A(f'    .LD_PIPES({v.ld_pipes}), .LD_DEP_W({v.ld_dep_w}),')
    # ---- IQ 即时唤醒 / 取消网络 / 寄存器缓存 ----
    A(f'    .NUM_WK_IQ({v.n_wk_iq}), .EXU_W({max(1, v.exu_w)}),')
    if v.n_wk_iq:
        A('    .IQ_SRC_MASK({' + ', '.join(bitvec(v.iq_mask[s], v.n_wk_iq)
                                           for s in reversed(range(v.n_regsrc))) + '}),')
        A("    .IQ_TYPE_BIT({" + ', '.join(f"3'd{v.iq_tbit[s]}"
                                           for s in reversed(range(v.n_regsrc))) + '}),')
        # 第 w 路 IQ 唤醒自己就是第几条 load 流水(那一位常数 1,不左移)
        A('    .IQ_IS_LD_PIPE({' + ', '.join(
            bitvec(set(v.iq_self_pipe[w]), v.ld_pipes)
            for w in reversed(range(v.n_wk_iq))) + '}),')
        A(f'    .HAS_REG_CACHE({int(v.has_rc)}), .RC_IDX_W({max(1, v.rc_idx_w)}),')
        A('    .IQ_WRITE_RC(' + bitvec(v.rc_lanes, v.n_wk_iq)
          + f'), .RC_TYPE_BIT({v.rc_tbit}),')
    A('    .SRC_WB_MASK({' + ', '.join(bitvec(set(v.src_wb[s]), v.n_wk)
                                       for s in reversed(range(v.n_regsrc))) + '}),')
    A("    .SRC_TYPE_BIT({" + ', '.join(f"3'd{v.src_tbit[s]}"
                                        for s in reversed(range(v.n_regsrc))) + '}),')
    A(f'    .HAS_IGNORE_OLD_VD({int(v.has_ignore)}),')
    A(f'    .VD_SRC({v.vd_src}), .VL_SRC({v.vl_src}),'
      f' .WB_VL_INT({v.wb_vl_int}), .WB_VL_VF({v.wb_vl_vf}),')
    for pl, fld in (('PLB_VM', 'vpu_vm'), ('PLB_VMA', 'vpu_vma'), ('PLB_VTA', 'vpu_vta'),
                    ('PLB_IS_DEPEND_OLDVD', 'vpu_isDependOldVd'),
                    ('PLB_IS_WRITE_PARTVD', 'vpu_isWritePartVd')):
        A(f'    .{pl}({v.pl_off[fld][0]}),')
    # issueResp 的 4 档:哪档带真 resp、哪档是常量,都从 golden 的查找表量出来
    A("    .OG_HAS_BITS(4'b" + ''.join(str(b) for b in reversed(v.og_has_bits)) + '),')
    A("    .OG_CONST_RESP({" + ', '.join(f"2'h{c:x}" for c in reversed(v.og_const)) + '})')
    A('  ) u_core (')
    c = []
    c.append('.clock(clock), .reset(reset)')
    c.append('.flush_valid(io_flush_valid), .flush_rob_flag(io_flush_bits_robIdx_flag)')
    c.append('.flush_rob_value(io_flush_bits_robIdx_value), .flush_level(io_flush_bits_level)')
    c.append('.enq_valid({%s})' % ', '.join(f'io_enq_{i}_valid'
                                            for i in reversed(range(v.n_enq))))
    c.append('.enq_rob_flag({%s})' % ', '.join(f'io_enq_{i}_bits_status_robIdx_flag'
                                               for i in reversed(range(v.n_enq))))
    c.append('.enq_rob_value({%s})' % ', '.join(f'io_enq_{i}_bits_status_robIdx_value'
                                                for i in reversed(range(v.n_enq))))
    c.append('.enq_fu_type({%s})' % ', '.join(
        f'io_enq_{i}_bits_status_fuType_{b}'
        for i in reversed(range(v.n_enq)) for b in reversed(v.fu_bits)))
    for fld, port in (('psrc', 'psrc'), ('src_type', 'srcType'),
                      ('src_state', 'srcState'), ('data_src', 'dataSources_value')):
        c.append('.enq_%s({%s})' % (fld, ', '.join(
            f'io_enq_{i}_bits_status_srcStatus_{s}_{port}'
            for i in reversed(range(v.n_enq)) for s in reversed(range(v.n_regsrc)))))
    c.append('.enq_payload(enq_payload)')
    # golden 顶层没有 enq 侧的 srcLoadDependency 端口（上层 IssueQueue 恒喂 0），
    # 影子从 0 起步、逐拍左移，因此这里也钉 0。
    # 每源 × 每条 load 流水的入队影子;顶层没有这组端口的变体(上层恒喂 0)钉 0。
    def rev_srcs(fmt, idx):
        return ', '.join(fmt % (idx, sidx) for sidx in reversed(range(v.n_regsrc)))
    if f'io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0' in v.pmap:
        c.append('.enq_ld_dep({%s})' % ', '.join(
            f'io_enq_{i}_bits_status_srcStatus_{sx}_srcLoadDependency_{q}'
            for i in reversed(range(v.n_enq))
            for sx in reversed(range(v.n_regsrc))
            for q in reversed(range(v.ld_pipes))))
        # 入队瞬间那份 payload.srcLoadDependency(golden Entries.scala:140 的 RegEnable)
        c.append('.enq_pl_ld_dep({%s})' % ', '.join(
            f'io_enq_{i}_bits_payload_srcLoadDependency_{sx}_{q}'
            for i in reversed(range(v.n_enq))
            for sx in reversed(range(v.n_regsrc))
            for q in reversed(range(v.ld_pipes))))
    else:
        c.append(".enq_ld_dep('0), .enq_pl_ld_dep('0)")
    if v.has_rc:
        c.append('.enq_use_rc({%s})' % ', '.join(
            f'io_enq_{i}_bits_status_srcStatus_{sx}_useRegCache'
            for i in reversed(range(v.n_enq)) for sx in reversed(range(v.n_regsrc))))
        c.append('.enq_rc_idx({%s})' % ', '.join(
            f'io_enq_{i}_bits_status_srcStatus_{sx}_regCacheIdx'
            for i in reversed(range(v.n_enq)) for sx in reversed(range(v.n_regsrc))))
    else:
        c.append(".enq_use_rc('0), .enq_rc_idx('0)")

    if v.n_wk_iq:
        for pfx, tag in (('io_wakeUpFromIQ', 'iq'), ('io_wakeUpFromIQDelayed', 'iqd')):
            c.append('.%s_wen({%s})' % (tag, ', '.join(
                f'{pfx}_{w}_bits_{v.iq_wen[w]}' for w in reversed(range(v.n_wk_iq)))))
            c.append('.%s_pdest({%s})' % (tag, ', '.join(
                f'{pfx}_{w}_bits_pdest' for w in reversed(range(v.n_wk_iq)))))
            c.append('.%s_ld_dep({%s})' % (tag, ', '.join(
                f'{pfx}_{w}_bits_loadDependency_{q}'
                for w in reversed(range(v.n_wk_iq))
                for q in reversed(range(v.ld_pipes)))))
            if v.has_rc:
                c.append('.%s_rc_dest({%s})' % (tag, ', '.join(
                    f'{pfx}_{w}_bits_rcDest' for w in reversed(range(v.n_wk_iq)))))
            else:
                c.append(f".{tag}_rc_dest('0)")
        # og0Cancel 的**稀疏全局下标**:第 w 路唤醒配 og0Cancel[og0_idx[w]];
        # 没有取消的路钉 0。is0Lat 被折成常量的路直接给 1'b1 / 1'b0。
        c.append('.og0_cancel_sel({%s})' % ', '.join(
            (f'io_og0Cancel_{v.og0_idx[w]}' if v.og0_idx[w] is not None else "1'b0")
            for w in reversed(range(v.n_wk_iq))))
        for tag, pfx in (('iq_is0lat', 'io_wakeUpFromIQ'),
                         ('iqd_is0lat', 'io_wakeUpFromIQDelayed')):
            c.append('.%s({%s})' % (tag, ', '.join(
                (f'{pfx}_{w}_bits_is0Lat' if v.is0lat_kind[w] == 'real'
                 else ("1'b1" if v.is0lat_kind[w] == 'const1' else "1'b0"))
                for w in reversed(range(v.n_wk_iq)))))
    else:
        c.append(".iq_wen('0), .iq_pdest('0), .iq_ld_dep('0), .iq_rc_dest('0)")
        c.append(".og0_cancel_sel('0), .iq_is0lat('0), .iqd_is0lat('0)")
        c.append(".iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0)")
    for tag, fld in (('ld1_cancel', 'ld1Cancel'), ('ld2_cancel', 'ld2Cancel')):
        if f'io_ldCancel_0_{fld}' in v.pmap:
            c.append('.%s({%s})' % (tag, ', '.join(
                f'io_ldCancel_{q}_{fld}' for q in reversed(range(v.n_ld_cancel)))))
        else:
            c.append(f".{tag}('0)")
    for pfx, tag in (('io_wakeUpFromWB', 'wk'), ('io_wakeUpFromWBDelayed', 'wkd')):
        c.append('.%s_valid({%s})' % (tag, ', '.join(
            f'{pfx}_{w}_valid' for w in reversed(range(v.n_wk)))))
        c.append('.%s_wen({%s})' % (tag, ', '.join(
            f'{pfx}_{w}_bits_{v.wk_wen[w]}' for w in reversed(range(v.n_wk)))))
        c.append('.%s_pdest({%s})' % (tag, ', '.join(
            f'{pfx}_{w}_bits_pdest' for w in reversed(range(v.n_wk)))))
    # vl 的零/满长信息只有向量子族有；没有的变体整组钉 0（顶层没有这些端口）
    if 'io_vlFromIntIsZero' in v.pmap:
        c.append('.vl_int_is_zero(io_vlFromIntIsZero), .vl_int_is_vlmax(io_vlFromIntIsVlmax)')
        c.append('.vl_vf_is_zero(io_vlFromVfIsZero), .vl_vf_is_vlmax(io_vlFromVfIsVlmax)')
    else:
        c.append(".vl_int_is_zero('0), .vl_int_is_vlmax('0)")
        c.append(".vl_vf_is_zero('0), .vl_vf_is_vlmax('0)")
    # og_valid / og_resp 是 [3 档][发射口] 的二维口;没有的档钉 0。
    ogv, ogr = [], []
    for k in reversed(range(3)):
        vp, bp = f'io_og{k}Resp_%d_valid', f'io_og{k}Resp_%d_bits_resp'
        ogv.append('{%s}' % ', '.join(vp % d for d in reversed(range(v.n_deq)))
                   if (vp % 0) in v.pmap else "%d'h0" % v.n_deq)
        ogr.append('{%s}' % ', '.join(bp % d for d in reversed(range(v.n_deq)))
                   if (bp % 0) in v.pmap else "%d'h0" % (2 * v.n_deq))
    c.append('.og_valid({%s})' % ', '.join(ogv))
    c.append('.og_resp({%s})' % ', '.join(ogr))
    for tag, port in (('deq_ready', 'io_deqReady_%d'),
                      ('deq_sel_oh_valid', 'io_deqSelOH_%d_valid'),
                      ('deq_sel_oh', 'io_deqSelOH_%d_bits'),
                      ('enq_oldest_sel', 'io_enqEntryOldestSel_%d_bits'),
                      ('simp_oldest_valid', 'io_simpEntryOldestSel_%d_valid'),
                      ('simp_oldest_sel', 'io_simpEntryOldestSel_%d_bits'),
                      ('comp_oldest_valid', 'io_compEntryOldestSel_%d_valid'),
                      ('comp_oldest_sel', 'io_compEntryOldestSel_%d_bits')):
        c.append('.%s({%s})' % (tag, ', '.join(port % d for d in reversed(range(v.n_deq)))))
    c.append('.simp_deq_sel_vec({%s})' % ', '.join(
        f'io_simpEntryDeqSelVec_{i}' for i in reversed(range(v.n_enq))))
    c.append('.o_valid(io_valid), .o_issued(io_issued), .o_can_issue(io_canIssue)')
    # 本变体顶层没有 exuSources / loadDependency / cancelDeqVec / regCacheIdx 端口
    # （无 IQ 唤醒子族），核的这几个出口接到本地悬空线。
    c.append('.o_exu_src(%s), .o_ld_dep(%s)'
             % ('exu_src' if v.out_exu else 'unused_exu_src',
                'ld_dep_out' if v.out_lddep else 'unused_ld_dep'))
    c.append('.o_deq_ld_dep(%s), .o_deq_rc_idx(%s)'
             % ('deq_ld_dep' if v.deq_lddep else 'unused_deq_ld_dep',
                'deq_rc_idx' if v.deq_rc else 'unused_deq_rc_idx'))
    c.append('.o_cancel_deq(%s)'
             % ('{%s}' % ', '.join(f'io_cancelDeqVec_{d}'
                                   for d in reversed(range(v.n_deq)))
                if v.out_cancel else 'unused_cancel_deq'))
    c.append('.o_fu_type(fu_type_narrow), .o_data_src(data_src)')
    c.append('.o_is_first_issue({%s})' % ', '.join(
        f'io_isFirstIssue_{d}' for d in reversed(range(v.n_deq))))
    c.append('.o_deq_rob_flag(deq_rob_flag), .o_deq_rob_value(deq_rob_value)')
    c.append('.o_deq_fu_type(deq_fu_type), .o_deq_psrc(deq_psrc)')
    c.append('.o_deq_src_type(deq_src_type), .o_deq_payload(deq_payload)')
    c.append('.o_simp_enq_sel_vec({%s})' % ', '.join(
        f'io_simpEntryEnqSelVec_{i}' for i in reversed(range(v.n_enq))))
    c.append('.o_comp_enq_sel_vec({%s})' % ', '.join(
        f'io_compEntryEnqSelVec_{i}' for i in reversed(range(v.n_enq))))
    A(',\n'.join('    ' + x for x in c))
    A('  );')
    A('')
    # ---- 展开输出 ----
    A(f'  // fuType 输出：核只存本变体保留的 {len(v.fu_bits)} 位，'
      f'这里放回 {v.fu_w} 位 one-hot 的原位置')
    for e in range(v.n_ent):
        parts, prev = [], v.fu_w
        for b in sorted(v.fu_bits, reverse=True):
            if prev - b - 1 > 0:
                parts.append(f"{prev-b-1}'h0")
            parts.append(f'fu_type_narrow[{e}][{v.fu_bits.index(b)}]')
            prev = b
        if prev > 0:
            parts.append(f"{prev}'h0")
        A(f'  assign io_fuType_{e} = {{' + ', '.join(parts) + '};')
    A('')
    for e in range(v.n_ent):
        for s in range(v.n_regsrc):
            A(f'  assign io_dataSources_{e}_{s}_value = data_src[{e}][{s}];')
    A('')
    if v.out_exu:
        for e in range(v.n_ent):
            for s in range(v.n_regsrc):
                A(f'  assign io_exuSources_{e}_{s}_value = exu_src[{e}][{s}];')
        A('')
    if v.out_lddep:
        A('  // io.loadDependency 是**按条目**的 mergedLoadDependency（各源按位或）')
        for e in range(v.n_ent):
            for q in range(v.ld_pipes):
                A(f'  assign io_loadDependency_{e}_{q} = ld_dep_out[{e}][{q}];')
        A('')
    for d in range(v.n_deq):
        A(f'  assign io_deqEntry_{d}_bits_status_robIdx_flag  = deq_rob_flag[{d}];')
        A(f'  assign io_deqEntry_{d}_bits_status_robIdx_value = deq_rob_value[{d}];')
        for k, b in enumerate(v.fu_bits):
            A(f'  assign io_deqEntry_{d}_bits_status_fuType_{b} = deq_fu_type[{d}][{k}];')
        for s in range(v.n_regsrc):
            A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}_psrc    = deq_psrc[{d}][{s}];')
            A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}_srcType = deq_src_type[{d}][{s}];')
            if v.deq_rc:
                A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}_regCacheIdx = '
                  f'deq_rc_idx[{d}][{s}];')
            if v.deq_lddep:
                for q in range(v.ld_pipes):
                    A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}'
                      f'_srcLoadDependency_{q} = deq_ld_dep[{d}][{s}][{q}];')
        for n, w in v.pl_deq:
            port = v.deq_pl_port(d, n)
            if port in v.pmap:          # 顶层把用不到的负载字段继续 DCE 掉了
                A(f'  assign {port} = deq_payload[{d}]{v.plslice(n)};')
    A('  // END GENERATED(core-inst)')
    A('')
    A('endmodule')
    return '\n'.join(L) + '\n'


# =============================================================================
def gen_tb(v):
    ins  = [(n, w) for d, w, n, _ in v.ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(n, w) for d, w, n, _ in v.ports if d == 'output']
    L = []
    A = L.append
    A(f'// {v.top} UT —— golden {v.top} 与重写 {v.top}_xs 双例化，逐拍比对全部'
      f' {len(outs)} 个输出。')
    A('// 端口表从 G1 golden 机械提取，比对用 `CHK 宏逐端口展开，杜绝手抄漏项。')
    A('//')
    A('// ★ 调度类模块最容易出的假绿：激励根本推不动队列 —— 条目填满后没人发射，')
    A('//   200k 拍 errors=0 其实只测了「入队后卡住」这一种状态。本 tb 第一版正是这样：')
    A('//   deq_fire 在 200k 拍里只有 2 次。所以除逐拍比对外还守一组覆盖闸，任一为 0 判 FAIL：')
    A('//     enq_fire      条目真入过队')
    A('//     wb_wake       写回唤醒真的把某个未就绪的源翻成就绪（探 golden 内部线）')
    A('//     can_issue     出现过全源就绪')
    A('//     deq_fire      真发射过（时钟沿前采样：沿上 issued 一置位 canIssue 就掉了）')
    A('//     resp_succ/block/uncertain  三种发射响应都回过')
    A('//     deq_clear     发射成功真的把条目清空过')
    A('//     trans2simp / trans2comp / simp2comp  三条转移路径都走过')
    A('//     ignore_old_vd 向量专属「旧 vd 可忽略」通路被打中过')
    A('//     full / flush  阵列填满过、冲刷过')
    A('//')
    A('// ★ 第二个坑（+vcs+initreg+random 才暴露）：io_issued / io_fuType_* /')
    A('//   io_dataSources_* 是条目寄存器的**裸读**，没有被 valid 门控。条目在被写过')
    A('//   之前，golden 的 entryReg_* 和重写核的 r_* 是两组不同的寄存器，随机初始化下')
    A('//   取值必然不同 —— 不 initreg 时 golden 是 X、被 $isunknown 跳过，看不出来；')
    A('//   一开 initreg+random 就是 750 个错。所以本 tb 等到 10 个条目**每一个都被写过')
    A('//   至少一次**（ever_valid 全 1）才开始比对，并且若整轮都没等到就判 FAIL。')
    A('//')
    A('// 激励要点：')
    A('//   1) pdest/psrc 共用 8 值小池，否则唤醒永远打不中在队 uop 的源；')
    A('//   2) srcType 按各源真实的门控位给（src3 走 v0 的 bit3，其余走 bit2），')
    A('//      给错了那一路唤醒就整条哑掉；')
    A('//   3) deqSelOH 由 tb 从 golden 当拍已落定的 canIssue 里挑（纯随机 one-hot')
    A('//      命中概率 ~0），且要在时钟沿**之前**用阻塞赋值算，否则慢一拍全打空。')
    A('//')
    A('// 自动生成：verif/ut/EntriesVfdivVidiv/gen.py —— 勿手改')
    A('`timescale 1ns/1ps')
    A('')
    A('`define CHK(P) begin \\')
    A('  checks++; \\')
    A('  if (!$isunknown(g_``P) && g_``P !== i_``P) begin \\')
    A('    errors++; \\')
    A('    if (errors <= 40) $display("[ERR] t=%0t %s golden=%h impl=%h", $time, `"P`", g_``P, i_``P); \\')
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
    for nm in cov_names(v):
        A(f'  int cov_{nm} = 0;')
    A('  int cov_fail = 0;')
    A(f'  bit [{v.n_ent-1}:0] ever_valid = \'0;   // 哪些条目被写过（裸读输出只在写过后才可比）')
    A('  bit warm = 0;              // 全部条目都写过 -> 进入比对')
    A('  longint warm_cycle = -1;')
    A('  task automatic covchk(string nm, int c);')
    A('    $display("  cov %-20s = %0d", nm, c);')
    A('    if (c == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: %s == 0", nm); end')
    A('  endtask')
    A('')
    for n, w in ins:
        A(f'  logic {"" if w == 1 else f"[{w-1}:0] "}{n};')
    for n, w in outs:
        A(f'  wire {"" if w == 1 else f"[{w-1}:0] "}g_{n};')
        A(f'  wire {"" if w == 1 else f"[{w-1}:0] "}i_{n};')
    A('')
    for pfx, mod in (('g_', v.top), ('i_', v.top + '_xs')):
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
        A('  localparam int RCPOOL = 4;  // regCacheIdx 的小池，让 replaceRC 打得中')
        A('  function automatic int rnd_rc(); return $urandom_range(0, RCPOOL-1); endfunction')
    A('')
    A('  // ---- 每拍激励（负沿下非阻塞给出）----')
    A('  task automatic drive();')
    A('    io_flush_valid             <= ($urandom_range(0, 999) < 3);')
    A('    io_flush_bits_robIdx_flag  <= $urandom_range(0, 1);')
    A(f"    io_flush_bits_robIdx_value <= {v.rob_w}'($urandom_range(0, 255));")
    A('    io_flush_bits_level        <= $urandom_range(0, 1);')
    for i in range(v.n_enq):
        A(f'    // enq 槽 {i}：入队率压到 30%%，否则阵列永远满、发射通路测不到')
        A(f'    io_enq_{i}_valid <= ($urandom_range(0, 99) < 30);')
        A(f'    io_enq_{i}_bits_status_robIdx_flag  <= $urandom_range(0, 1);')
        A(f"    io_enq_{i}_bits_status_robIdx_value <= {v.rob_w}'($urandom_range(0, 255));")
        for b in v.fu_bits:
            A(f'    io_enq_{i}_bits_status_fuType_{b} <= $urandom_range(0, 1);')
        for s in range(v.n_regsrc):
            tb_ = v.src_tbit[s]
            A(f"    io_enq_{i}_bits_status_srcStatus_{s}_psrc <= {v.psrc_w}'(rnd_reg());")
            A(f'    // src{s} 的唤醒门控位是 srcType[{tb_}]，绝大多数时候给对')
            A(f"    io_enq_{i}_bits_status_srcStatus_{s}_srcType <= "
              f"($urandom_range(0,99) < 88) ? 4'h{1<<tb_:x} : 4'($urandom_range(0,15));")
            A(f'    io_enq_{i}_bits_status_srcStatus_{s}_srcState <= ($urandom_range(0, 99) < 72);')
            A(f'    io_enq_{i}_bits_status_srcStatus_{s}_dataSources_value <= '
              f"($urandom_range(0,1)) ? 4'h2 : 4'h8;")
            # ★ 这三组是派遣带进来的初值。第一版 tb 漏掉它们（整轮恒 0），
            #   于是「入队就带着影子/regcache 命中」这条入口路径从来没被激励过。
            for q in range(v.ld_pipes):
                pn = f'io_enq_{i}_bits_status_srcStatus_{s}_srcLoadDependency_{q}'
                if pn in v.pmap:
                    A(f"    {pn} <= ($urandom_range(0,99) < 25) ? "
                      f"{v.ld_dep_w}'($urandom_range(1, {(1 << v.ld_dep_w) - 1})) :"
                      f" {v.ld_dep_w}'h0;")
            if v.has_rc:
                A(f'    io_enq_{i}_bits_status_srcStatus_{s}_useRegCache <= '
                  '($urandom_range(0, 99) < 40);')
                A(f'    io_enq_{i}_bits_status_srcStatus_{s}_regCacheIdx <= '
                  f"{v.rc_idx_w}'(rnd_rc());")
        for n, w in v.pl_all:
            p = v.enq_pl_port(i, n)
            if p not in v.pmap:
                continue
            pw = v.pmap[p][1]
            # ignoreOldVd 判定要用的几位单独加权，否则那条通路几乎打不中
            bias = {'vpu_isDependOldVd': 12, 'vpu_vm': 60, 'vpu_vma': 60,
                    'vpu_vta': 60, 'vpu_isWritePartVd': 20}.get(n)
            if bias is not None:
                A(f'    {p} <= ($urandom_range(0, 99) < {bias});')
            elif pw == 1:
                A(f'    {p} <= $urandom_range(0, 1);')
            else:
                nw = (pw + 31) // 32
                A(f"    {p} <= {pw}'({{" + ', '.join(['$urandom'] * nw) + '});')
    A('    // 唤醒总线：pdest 取自小池，写使能高概率有效')
    for w in range(v.n_wk):
        A(f'    io_wakeUpFromWB_{w}_valid <= ($urandom_range(0, 99) < 35);')
        A(f'    io_wakeUpFromWB_{w}_bits_{v.wk_wen[w]} <= ($urandom_range(0, 99) < 85);')
        A(f"    io_wakeUpFromWB_{w}_bits_pdest <= {v.pdest_w}'(rnd_reg());")
    if v.has_ignore:
        A('    io_vlFromIntIsZero  <= ($urandom_range(0, 99) < 15);')
        A('    io_vlFromIntIsVlmax <= ($urandom_range(0, 99) < 55);')
        A('    io_vlFromVfIsZero   <= ($urandom_range(0, 99) < 15);')
        A('    io_vlFromVfIsVlmax  <= ($urandom_range(0, 99) < 55);')
    if v.n_wk_iq:
        A('    // IQ 即时唤醒：pdest 同样取自小池；rcDest 用更小的池，')
        A('    //   否则 replaceRC（rcDest == 本源 regCacheIdx）几乎打不中。')
        for w in range(v.n_wk_iq):
            A(f'    io_wakeUpFromIQ_{w}_bits_{v.iq_wen[w]} <= ($urandom_range(0, 99) < 30);')
            A(f"    io_wakeUpFromIQ_{w}_bits_pdest <= {v.pdest_w}'(rnd_reg());")
            if v.has_rc:
                A(f"    io_wakeUpFromIQ_{w}_bits_rcDest <= {v.rc_idx_w}'(rnd_rc());")
            for q in range(v.ld_pipes):
                A(f'    io_wakeUpFromIQ_{w}_bits_loadDependency_{q} <= '
                  f"{v.ld_dep_w}'($urandom_range(0, {(1 << v.ld_dep_w) - 1}));")
            if v.is0lat_kind[w] == 'real':
                A(f'    io_wakeUpFromIQ_{w}_bits_is0Lat <= ($urandom_range(0, 99) < 55);')
        A('    // og0Cancel：打太满就没有唤醒能过去，打太稀 cancel 分支测不到')
        for idx in sorted({x for x in v.og0_idx if x is not None}):
            A(f'    io_og0Cancel_{idx} <= ($urandom_range(0, 99) < 20);')
        for q in range(v.n_ld_cancel):
            if v.has_ld1:
                A(f'    io_ldCancel_{q}_ld1Cancel <= ($urandom_range(0, 99) < 12);')
            if v.has_ld2:
                A(f'    io_ldCancel_{q}_ld2Cancel <= ($urandom_range(0, 99) < 12);')
    A('  endtask')
    A('')
    A('  // wakeUpFromWBDelayed = wakeUpFromWB 打一拍（golden 上层 IssueQueue 就是这么接的）')
    A('  always @(posedge clock) begin')
    for w in range(v.n_wk):
        A(f'    io_wakeUpFromWBDelayed_{w}_valid <= io_wakeUpFromWB_{w}_valid;')
        A(f'    io_wakeUpFromWBDelayed_{w}_bits_{v.wk_wen[w]} <= io_wakeUpFromWB_{w}_bits_{v.wk_wen[w]};')
        A(f'    io_wakeUpFromWBDelayed_{w}_bits_pdest <= io_wakeUpFromWB_{w}_bits_pdest;')
    for w in range(v.n_wk_iq):
        for f in ([v.iq_wen[w], 'pdest'] + (['rcDest'] if v.has_rc else [])
                  + ([f'loadDependency_{q}' for q in range(v.ld_pipes)])
                  + (['is0Lat'] if v.is0lat_kind[w] == 'real' else [])):
            A(f'    io_wakeUpFromIQDelayed_{w}_bits_{f} <= io_wakeUpFromIQ_{w}_bits_{f};')
    A('  end')
    A('')
    A('  // ---- 发射/年龄选择：在输入落定之后、时钟沿之前用阻塞赋值算 ----')
    A('  //   纯随机 one-hot 命中 canIssue 的概率 ~0，所以必须从 golden 当拍已落定的')
    A('  //   canIssue 里挑；多发射口时两个口要挑**不同**的条目，否则第二个口永远空转。')
    A('  task automatic drive_deq();')
    A(f'    logic [{v.n_ent-1}:0] ci, taken;')
    A('    int pick, cnt;')
    A('    ci    = g_io_canIssue;')
    A(f"    taken = {v.n_ent}'h0;")
    for d in range(v.n_deq):
        A(f"    io_deqSelOH_{d}_valid = 1'b0;")
        A(f"    io_deqSelOH_{d}_bits  = {v.n_ent}'h0;")
        A('    cnt = $countones(ci & ~taken);')
        A('    if (cnt > 0 && $urandom_range(0, 99) < 80) begin')
        A('      pick = $urandom_range(0, cnt-1);')
        A(f'      for (int k = 0; k < {v.n_ent}; k++)')
        A('        if (ci[k] && !taken[k]) begin')
        A(f"          if (pick == 0) begin io_deqSelOH_{d}_valid = 1'b1;"
          f" io_deqSelOH_{d}_bits = {v.n_ent}'(1) << k; taken[k] = 1'b1; end")
        A('          pick--;')
        A('        end')
        A('    end')
        A(f'    io_deqReady_{d} = ($urandom_range(0, 99) < 90);')
    # issueResp：只驱动 golden 顶层真有的那几档
    for k in range(3):
        for d in range(v.n_deq):
            if f'io_og{k}Resp_{d}_valid' in v.pmap:
                A(f'    io_og{k}Resp_{d}_valid = ($urandom_range(0, 99) < '
                  f'{70 if v.og_has_bits[k] else 15});')
            if f'io_og{k}Resp_{d}_bits_resp' in v.pmap:
                A(f"    io_og{k}Resp_{d}_bits_resp = ($urandom_range(0,99) < 65) ? 2'b11 :"
                  " (($urandom_range(0,1)) ? 2'b00 : 2'b01);")
    for d in range(v.n_deq):
        A(f"    io_enqEntryOldestSel_{d}_bits   = {v.n_enq}'(1) << "
          f"$urandom_range(0, {v.n_enq-1});")
        A(f'    io_simpEntryOldestSel_{d}_valid = |g_io_valid[%d:%d];'
          % (v.n_enq + v.n_simp - 1, v.n_enq))
        A(f"    io_simpEntryOldestSel_{d}_bits  = {v.n_simp}'(1) << "
          f"$urandom_range(0, {v.n_simp-1});")
        A(f'    io_compEntryOldestSel_{d}_valid = |g_io_valid[%d:%d];'
          % (v.n_ent - 1, v.n_enq + v.n_simp))
        A(f"    io_compEntryOldestSel_{d}_bits  = {v.n_comp}'(1) << "
          f"$urandom_range(0, {v.n_comp-1});")
    for i in range(v.n_enq):
        A(f'    io_simpEntryDeqSelVec_{i} = ($urandom_range(0,99) < 65) ? '
          f"({v.n_simp}'(1) << $urandom_range(0, {v.n_simp-1})) : {v.n_simp}'h0;")
    A('  endtask')
    A('')
    A('  // ---- 覆盖采样：全在**时钟沿之前**，采的是这一拍将要生效的激励与当前状态。')
    A('  //      发射类事件必须这样采：沿上 issued 一置位，canIssue 立刻掉，事后采不到。----')
    A('  task automatic sample_cov();')
    A('    if (|{%s}) cov_enq_fire++;' % ', '.join(
        f'io_enq_{i}_valid' for i in range(v.n_enq)))
    A('    if (|g_io_canIssue) cov_can_issue++;')
    A('    if (%s) cov_deq_fire++;' % ' || '.join(
        f'(io_deqSelOH_{d}_valid && io_deqReady_{d} && '
        f'(g_io_canIssue & io_deqSelOH_{d}_bits))' for d in range(v.n_deq)))
    if v.n_deq > 1:
        A('    // 两个发射口同一拍都发射 —— 单口变体测不到的那条路')
        A('    if (%s) cov_deq_both++;' % ' && '.join(
            f'(io_deqSelOH_{d}_valid && io_deqReady_{d} && '
            f'(g_io_canIssue & io_deqSelOH_{d}_bits))' for d in range(v.n_deq)))
    A('    if (|{%s}) cov_first_issue++;' % ', '.join(
        f'g_io_isFirstIssue_{d}' for d in range(v.n_deq)))
    # resp 覆盖：取"带真 resp"的那一档
    rk = next((k for k in range(3) if v.og_has_bits[k]), None)
    assert rk is not None, '没有任何一档 issueResp 带真 resp'
    for nm, val in (('succ', "2'b11"), ('block', "2'b00"), ('uncertain', "2'b01")):
        A('    if (%s) cov_resp_%s++;' % (' || '.join(
            f'(io_og{rk}Resp_{d}_valid && io_og{rk}Resp_{d}_bits_resp == {val})'
            for d in range(v.n_deq)), nm))
    A('    if (|{%s}) cov_trans2simp++;' % ', '.join(
        f'g_io_simpEntryEnqSelVec_{i}' for i in range(v.n_enq)))
    A('    if (|{%s}) cov_trans2comp++;' % ', '.join(
        f'g_io_compEntryEnqSelVec_{i}' for i in range(v.n_enq)))
    A('    if (&g_io_valid) cov_full++;')
    A('    if (io_flush_valid) cov_flush++;')
    A('    // 白盒探针（只探 golden 侧；impl 侧的一致性由逐拍输出比对保证）')
    if v.has_ignore:
        A("    if (u_g.enqEntries_0.ignoreOldVd_%d === 1'b1 || "
          "u_g.enqEntries_1.ignoreOldVd_%d === 1'b1) cov_ignore_old_vd++;"
          % (v.vd_src, v.vd_src))
    A('    if (%s) cov_simp2comp++;' % ' || '.join(
        f"u_g.othersEntriesSimp_{j}.io_commonIn_transSel === 1'b1"
        for j in range(v.n_simp)))
    A('    // wb_wake：某个「原本未就绪」的源本拍被唤醒翻成就绪')
    A('    if (%s) cov_wb_wake++;' % ' || '.join(
        [f"(u_g.enqEntries_{i}.entryUpdate_status_srcStatus_0_srcState === 1'b1 && "
         f"u_g.enqEntries_{i}.entryReg_status_srcStatus_0_srcState === 1'b0)"
         for i in range(v.n_enq)] +
        [f"(u_g.othersEntriesSimp_{j}.entryUpdate_status_srcStatus_0_srcState === 1'b1 && "
         f"u_g.othersEntriesSimp_{j}.entryReg_status_srcStatus_0_srcState === 1'b0)"
         for j in range(v.n_simp)]))
    A('    // deq_clear：发射成功把条目清空（validReg 由 1 变 0 且不是被冲刷/转移）')
    A('    if (%s) cov_deq_clear++;' % ' || '.join(
        f"(u_g.othersEntriesComp_{j}.validReg_last_REG === 1'b1 && "
        f"u_g.othersEntriesComp_{j}.io_commonIn_issueResp_valid === 1'b1 && "
        f"u_g.othersEntriesComp_{j}.io_commonIn_issueResp_bits_resp === 2'b11)"
        for j in range(v.n_comp)))
    if v.n_wk_iq:
        ents = ([f'u_g.enqEntries_{i}' for i in range(v.n_enq)]
                + [f'u_g.othersEntriesSimp_{j}' for j in range(v.n_simp)]
                + [f'u_g.othersEntriesComp_{j}' for j in range(v.n_comp)])
        A('    // ---- IQ 唤醒子族专属：这四条全 0 就说明整条投机唤醒通路没被激励到 ----')
        A('    //   perf* 是 golden 条目自己算的观测量（顶层把它们 DCE 了，但子模块端口还在）')
        A('    if (%s) cov_iq_wake++;' % ' || '.join(
            f"{e}.io_commonOut_perfWakeupByIQ_{sx}_{w} === 1'b1"
            for e in ents for sx in range(v.n_regsrc) for w in range(v.n_wk_iq)))
        A('    if (%s) cov_og0_cancel++;' % ' || '.join(
            f"{e}.io_commonOut_perfOg0Cancel_{sx} === 1'b1"
            for e in ents for sx in range(v.n_regsrc)))
        A('    if (%s) cov_ld_cancel++;' % ' || '.join(
            f"{e}.io_commonOut_perfLdCancel_{sx} === 1'b1"
            for e in ents for sx in range(v.n_regsrc)))
        if v.has_rc:
            A('    // wakeupRC：IQ 唤醒把某个源改挂到寄存器缓存上')
            A('    if (%s) cov_rc_wake++;' % ' || '.join(
                f"{e}.wakeupRC === 1'b1" for e in ents))
        A('    // dataSources 的两个只有本子族才出现的取值：forward(1) / regcache(6)')
        A('    if (%s) cov_ds_forward++;' % ' || '.join(
            f"g_io_dataSources_{e}_{sx}_value === 4'h1"
            for e in range(v.n_ent) for sx in range(v.n_regsrc)))
        if v.has_rc:
            A('    if (%s) cov_ds_regcache++;' % ' || '.join(
                f"g_io_dataSources_{e}_{sx}_value === 4'h6"
                for e in range(v.n_ent) for sx in range(v.n_regsrc)))
    if v.out_cancel:
        A('    if (|{%s}) cov_cancel_deq++;' % ', '.join(
            f'g_io_cancelDeqVec_{d}' for d in range(v.n_deq)))
    if v.out_lddep:
        A('    // 影子非零：ldCancel 那条通路真的有东西可撤')
        A('    if (|{%s}) cov_lddep_nz++;' % ', '.join(
            f'g_io_loadDependency_{e}_{q}'
            for e in range(v.n_ent) for q in range(v.ld_pipes)))
    A('  endtask')
    A('')
    A('  longint cyc = 0;')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A("    reset = 1'b1;")
    for n, w in ins:
        A(f"    {n} = '0;")
    A('    repeat (8) @(posedge clock);')
    A("    reset = 1'b0;")
    A('    repeat (NCYCLES) begin')
    A('      @(negedge clock);')
    A('      drive();        // 非阻塞：本拍激励')
    A('      #1;             // 输入落定')
    A('      drive_deq();    // 阻塞：读已落定的 canIssue 再挑发射目标')
    A('      #1;             // 组合输出稳定')
    A('      sample_cov();   // 时钟沿之前采样')
    A('      @(posedge clock);')
    A('      #1;')
    A('      ever_valid |= g_io_valid;')
    A('      if (!warm && (&ever_valid)) begin warm = 1; warm_cycle = cyc; end')
    A('      if (warm) check_outputs();')
    A('      cyc++;')
    A('    end')
    A('')
    A(f'    $display("{v.top} checks=%0d errors=%0d warm_cycle=%0d", checks, errors, warm_cycle);')
    A('    if (!warm) begin')
    A(f'      $display("TEST FAILED (整轮都没能把 {v.n_ent} 个条目全写一遍，'
      f'裸读输出的比对从未开启)");')
    A('      $fatal(1);')
    A('    end')
    A('    $display("---- 功能覆盖 ----");')
    for nm in cov_names(v):
        A(f'    covchk("{nm}", cov_{nm});')
    A('    if (errors != 0) begin $display("TEST FAILED"); $fatal(1); end')
    A('    if (cov_fail != 0) begin $display("TEST FAILED (覆盖不足)"); $fatal(1); end')
    A(f'    if (checks < 1000 || cyc - warm_cycle < NCYCLES/2) begin')
    A('      $display("TEST FAILED (有效比对拍数过少)"); $fatal(1);')
    A('    end')
    A('    $display("TEST PASSED");')
    A('    $finish;')
    A('  end')
    A('endmodule')
    A('`undef CHK')
    return '\n'.join(L) + '\n'


FM_NOTES = {
    # 变体名 -> 该变体上实测到的 FM 点数（只写真跑过的；没跑过的不编数字）
    'EntriesVfdivVidiv':
        '# 本变体实测：merge_dup=true 时 ref unread 2250 / impl 2426 对不上；\n'
        '# 置 false 后 ref 2480 / impl 2486，差额 6 个是可读核多出的死寄存器（已修）。\n'
        '# 逐位钉点覆盖 2420 对负载位。',
}


def gen_mk(v):
    fm_note = FM_NOTES.get(v.top, '# 本变体的 FM 点数尚未实测。')
    extra_golden = ''.join(f' \\\n              $(GOLDEN_RTL)/{m}.sv' for m in v.extra_mods)
    extra_deps = ''.join(f' {m}.sv' for m in v.extra_mods)
    return f"""# {v.top} UT/FM 入口（Entries* 家族 canary）
# 重写件只有两个：家族共享参数化核 + 本变体薄文件。
# golden 的 EnqEntry/OthersEntry/EnqPolicy 都不是独立签核目标，故本重写把它们
# 一起扁平化，不放 RTL_GOLDEN_DEPS、不做黑盒；FM 侧 ref 需要它们做依赖闭包。
# 自动生成：verif/ut/{v.top}/gen.py（共享库 verif/ut/Entries_common/entries_gen.py）
# 勿手改
MODULE = {v.top}

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_iq_entries_core.sv \\
           $(RTL_DIR)/backend/{v.top}.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/{v.top}.sv \\
              $(GOLDEN_RTL)/{v.enq_mod}.sv \\
              $(GOLDEN_RTL)/{v.simp_mod}.sv \\
              $(GOLDEN_RTL)/{v.comp_mod}.sv \\
              $(GOLDEN_RTL)/{v.enq_policy}.sv{extra_golden}

FM_VARIANTS = {v.top}
FM_REF_DEPS_{v.top} = {v.enq_mod}.sv {v.simp_mod}.sv {v.comp_mod}.sv {v.enq_policy}.sv{extra_deps}

# ---------------------------------------------------------------------------
# FM 证明配置 —— 两项都是**加强**，不是放宽
# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false：与 MulUnit 同型的工具建模不对称。golden 把条目负载展平成
#   上百个逐字段寄存器，其中本变体用不到的字段整组是常数（Entries 顶层根本没有
#   对应端口 → 入口恒 0）；merge_duplicated_registers=true 时 FM 在 golden 侧把
#   这些同值寄存器合并掉，而可读核把同一份负载存在一根向量里、按位不合并，
#   于是两侧点数对不上。置 false 后两侧都逐个保留。
#   这是要求 FM 逐个而不是合并后比 —— 更严，不跳点、不黑盒、不约束 ref。
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true：配合 fm_pins_pre.tcl 的逐位钉点，
#   让 FM **真去比**那些「本变体里没有输出锥」的负载位，而不是记 Not-Compared。
#   白名单在 scripts/fm_eq.tcl（依据写在那一行紧邻的注释里），两处须同时生效。
{fm_note}
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 带 XSError/XSPerf 等非综合断言，随机激励会踩到 $fatal；两侧统一关掉。
VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 复位域：条目寄存器（entryReg_*）在 golden 里**不复位**，只有 validReg /
# enqDelayValidReg 带复位（实测 EnqEntry_*.sv 的 `if (reset)` 只钉这两个）。
# 可读核照抄了这个复位域。
#
# 不开 initreg 时，golden 侧未初始化的寄存器是 X，被 tb 的 $isunknown 跳过 ——
# 于是"照抄复位域"这件事根本没被验过（把不复位写成全复位，elaborate 和 lint
# 都不会响）。所以：
#   编译期 +vcs+initreg+random 打开这个能力（VCS 只在编译期认这个开关）；
#   运行期用 +vcs+initreg+<0|random> 选初值 —— 两种初值**都要过**，
#   只过一轮说明比对结果依赖初值。
# ★ 编译期写 +vcs+initreg+0 是错的：VCS 报 OBSL_OPT_E，那是运行期选项。★
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

# 同一个 simv，换个初值再跑一轮（不重新编译）
.PHONY: run-initreg0
run-initreg0: simv
	./simv +vcs+initreg+0 +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l sim_ir0_$(SEED).log
	@grep -q "TEST PASSED" sim_ir0_$(SEED).log && echo "=== UT PASSED ($(MODULE) initreg=0 seed=$(SEED)) ===" || {{ echo "=== UT FAILED ($(MODULE) initreg=0 seed=$(SEED)) ==="; exit 1; }}

# 变异靶子：往可读核里注入若干个**真实形态**的 bug，要求本 UT 每一个都抓得住。
# errors=0 只有在 UT 有判别力的前提下才算证据，所以这一步和 make run 同等重要。
.PHONY: mutants
mutants:
	python3 ../Entries_common/mutants.py $(MODULE) $(MUTANT_ARGS)
"""


def main(top):
    check = '--check' in sys.argv
    v = Variant(top)
    here = outdir(top)
    files = {
        REPO / 'rtl' / 'backend' / f'{v.top}.sv': gen_rtl(v),
        here / 'tb.sv':    gen_tb(v),
        here / 'Makefile': gen_mk(v),
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
        print(f'\n[{v.top}] entries={v.n_ent} (enq {v.n_enq}/simp {v.n_simp}/comp {v.n_comp}) '
              f'deq={v.n_deq} regsrc={v.n_regsrc} wb={v.n_wk} '
              f'PL_DEQ_W={v.pl_deq_w} PL_TRANS_W={v.pl_trans_w} '
              f'ports={len(v.ports)}')
        print(f'  wakeup routing: ' +
              '; '.join(f'src{s}->WB{v.src_wb[s]} type[{v.src_tbit[s]}]'
                        for s in range(v.n_regsrc)))
    return bad


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
