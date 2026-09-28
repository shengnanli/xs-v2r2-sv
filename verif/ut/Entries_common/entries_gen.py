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
WEN_ORDER = ['rfWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen']   # 与核里 WEN_* 编号一致


def wenpack(pfx, w, present):
    """把第 w 路唤醒的 wen 字段按核里的 WEN_* 顺序打成一根 5 位向量。

    该窗口没有的字段填 1'b0 —— ★但核**不会**去读它★：核按 *_WEN_PRESENT 参数
    在 elaborate 期就把整项连同它的 srcType 位一起剪掉，所以锥里不会多出常 0 的边
    （喂 0 与剪掉不等价，同型教训见核里 HAS_LD1_CANCEL 的注释）。
    这里填 0 只是为了让向量位宽对齐，不承担任何逻辑含义。
    """
    return '{' + ', '.join(
        (f'{pfx}_{w}_bits_{f}' if f in present else "1'b0")
        for f in reversed(WEN_ORDER)) + '}'


def wenvec(present):
    """把「这条总线这个窗口有哪些 wen 字段」编成核认的 5 位常量。"""
    bits = ''.join('1' if w in present else '0' for w in reversed(WEN_ORDER))
    return f"5'b{bits}"


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



# kind 展开成 (srcType 位, wen 字段) 对表 —— 逐字照搬 Bundles.scala:325-348
KIND_PAIRS = {
    0: [(1, 'fpWen'), (0, 'rfWen'), (2, 'vecWen')],   # MK_GP : wakeUp
    1: [(3, 'v0Wen')],                                 # MK_V0 : wakeUpV0 ★isV0★
    2: [(2, 'vlWen')],                                 # MK_VL : wakeUpVl
}


class Variant:
    def _check_pairs(self, s, body, bus, wenkey):
        """核对「模型展开的对表」== 「golden 里实测的对表」，对不上当场失败。

        ★这是 E1 的安全带★：模型（kind × 该窗口存在哪些 wen）一旦与某个新变体的
        golden 不符，这里当场红，而不是悄悄生成一份错的 RTL 等 FM 去发现。
        """
        want = sorted((b, w) for b, w in KIND_PAIRS[self.src_kind[s]]
                      if w in self.wen_present[wenkey])
        got = sorted({(int(b), w) for b, w in re.findall(
            r'srcStatus_%d_srcType\[(\d)\] & io_%s_\d+_bits_(\w+Wen)'
            % (s, bus), re.sub(r'\s+', ' ', body))})
        if got and got != want:
            sys.exit(f'{self.top} src{s} @{bus}: 唤醒对表与模型不符\n'
                     f'  模型={want}\n  实测={got}\n'
                     f'  该窗口存在的 wen={sorted(self.wen_present[wenkey])}\n'
                     f'  —— 模型见 Bundles.scala:325-348 / EntryBundles.scala:185,241')

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
        # ★ `=` 与 `{` 之间可能换行(firtool 按 80 列折行)：Ldu/StaMou/StdMoud/
        #   VlduVstu* 五个变体正是折行的，原来写死 `" = {"` 会把这张表数成 0 张，
        #   然后在"表数 != 发射口数"那条断言上失败 —— 看起来像"家族维度不支持"，
        #   其实只是抽取正则不认折行。用 \s* 两边都放开。
        gms = re.findall(r"wire \[3:0\]\[1:0\]\s+_GEN_\d+\s*=\s*\{(.*?)\};", txt, re.S)
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

        # ---- 每路 WB 的写使能字段名（★逐路一个**列表**，不是一个名字★） ----
        # 旧写法断言"每路只有一个写使能字段"。那是从单 wen 变体外推出来的假设：
        # MEM 族一条 lane 同时带 rfWen/fpWen/vecWen，VlduVstu 更是五个全带
        # （判别轴见 verif/ut/Entries_field_matrix/wakeup_axis.md）。
        # 断言留着会让那 5 个访存变体连 Variant() 都构造不出来。
        self.wk_wen_lanes = []
        for w in range(self.n_wk):
            f = sorted(n.split('_bits_')[1] for n in self.pmap
                       if n.startswith(f'io_wakeUpFromWB_{w}_bits_')
                       and n.endswith('Wen'))
            assert f, f'WB{w} 一个写使能字段都没有'
            self.wk_wen_lanes.append(f)
        # 兼容旧引用：单 wen 时就是那一个名字；多 wen 时取第一个**只用于注释/激励**，
        # 逻辑一律走 wen_lane（逐路集合）与 *_WEN_PRESENT（剪项）。
        self.wk_wen = [f[0] for f in self.wk_wen_lanes]

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
        # ★ IQ 唤醒总线上的 loadDependency 要**单独量**，不能从 has_ld_dep 推。
        #   FP 族（FaluFmac / FaluFmacFdiv / FaluFcvtF2vFmacFdiv）有 IQ 即时唤醒
        #   但整条 load 依赖通路是死的，golden 的 io_wakeUpFromIQ_* 上根本没有
        #   loadDependency 端口 —— 原来这里按 `if v.n_wk_iq:` 无条件发 ld_dep，
        #   生成的 tb 引用了不存在的端口，VCS 直接 Identifier-not-declared。
        #   ★ 曾想写成断言「IQ 总线有 ⟺ 条目有」——**实测是假的**：FP 族的条目
        #     确实有 srcLoadDependency 寄存器(EnqEntry_12:637 等，3 流水 x 2 位，
        #     next 正常移位)，只是 IQ 总线不带、Entries 顶层也不露 io_loadDependency。
        #     所以这条只能独立量，不能从 has_ld_dep 推。
        #     （字段矩阵 ldDep_pipes 那一行量的是**顶层**，不是条目；两者不同义。）
        self.iq_has_ld_dep = 'io_wakeUpFromIQ_0_bits_loadDependency_0' in self.pmap


        # 顶层 deqEntry 露出的负载字段必须是条目存的那一份的**子集**。
        # ★ 不是相等:条目(EnqEntry/OthersEntry 是独立模块,端口固定)存着整份 DEQ 负载,
        #   而 Entries 顶层会把本变体用不到的字段继续 DCE 掉 —— AluCsrFenceDiv 就比
        #   条目里少 10 个。要求相等是从 VfdivVidiv(恰好相等)外推出来的。
        top_deq = {n[len('io_deqEntry_0_bits_payload_'):] for n in self.pmap
                   if n.startswith('io_deqEntry_0_bits_payload_')}
        assert top_deq <= dnames, f'顶层 deq 负载多出条目没有的字段: {top_deq - dnames}'

        # ---- 唤醒匹配的 kind 与每条总线每个窗口的 wen 字段（E1/E2） ----
        # 模型逐字照搬 Chisel：
        #   Bundles.scala:325-348   wakeUp / wakeUpV0 / wakeUpVl 三个函数、三张对表
        #   EntryBundles.scala:185-193(WB) 与 :241-249(IQ)  按源分工，
        #                           且**只在 numRegSrc==5 时分**
        # 这里只量两样东西，其余由核按模型展开：
        #   (a) 每个源用哪种 kind —— 完全由 n_regsrc 决定，不用从 RTL 猜
        #   (b) 每条总线**每个窗口**上存在哪些 wen 端口 —— 逐个从 golden 端口表量
        # ★(b) 必须按窗口分开量★：firtool 对当拍/延迟两条总线独立 DCE，
        #   实测 EnqEntry_30(StdMoud) 的 IQ 当拍只有 rfWen、延迟窗口还有 fpWen。
        # 模型与 14 个变体逐源逐窗口的实测对表完全一致，
        # 复跑 evidence/e1-wakeup-pair-tables/extract_probe.py
        # ★wen 字段是**逐路**的,不是整条总线一样★(向量变体实测):
        #   WB[0..5] 只有 vecWen、WB[6..11] 只有 v0Wen、WB[12..15] 只有 vlWen。
        #   所以:
        #     连线(wenpack)  用**逐路**的集合 —— 引用不存在的端口会被端口闸当场抓住
        #     剪项(*_WEN_PRESENT) 用**整条总线的并集** —— 它只跟 kind 求交,
        #       而 SRC_WB_MASK 已经把每个源限制在带它那个字段的那几路上,
        #       所以并集与逐路在匹配结果上等价(并集∩kind 给出的项集是对的)。
        _etxt_ws = re.sub(r'\s+', ' ', read(self.enq_mod))
        def _wen_by_lane(bus):
            d = {}
            for w, f in re.findall(r'input +io_%s_(\d+)_bits_(\w+Wen)' % bus, _etxt_ws):
                if f in WEN_ORDER:
                    d.setdefault(int(w), set()).add(f)
            return d
        self.wen_lane = {k: _wen_by_lane(b) for k, b in (
            ('wb',  'commonIn_wakeUpFromWB'),  ('wbd', 'enqDelayIn1_wakeUpFromWB'),
            ('iq',  'commonIn_wakeUpFromIQ'),  ('iqd', 'enqDelayIn1_wakeUpFromIQ'))}
        self.wen_present = {k: set().union(*v.values()) if v else set()
                            for k, v in self.wen_lane.items()}
        # 每源的 kind：0=MK_GP 1=MK_V0 2=MK_VL
        self.src_kind = ([0, 0, 0, 1, 2] if self.n_regsrc == 5
                         else [0] * self.n_regsrc)

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
            # ★不再要求"门控位唯一"★：访存族一个源要三对(fp|rf|vec)，
            #   多位是**正常**的。改成核对「实测对表 == 模型展开」，
            #   对不上就当场失败——比"唯一"这个旧假设强，也不会放行错模型。
            self._check_pairs(s, body, 'enqDelayIn1_wakeUpFromWB', 'wbd')
            tb = {int(x) for x in re.findall(
                r'entryReg_status_srcStatus_%d_srcType\[(\d+)\]' % s, body)}
            self.src_tbit.append(sorted(tb)[0] if tb else 0)
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
                if self.iq_tbit[s] is None:
                    self.iq_tbit[s] = sorted(tb)[0] if tb else 0
                f = {x for x in re.findall(r'wakeUpFromIQ_%d_bits_(\w+)\b' % w, body)
                     if x not in ('pdest', 'is0Lat')}
                # 同上：一个源可以有多个 wen 项，不再要求唯一
                wen = sorted(f)[0] if f else None
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
                    # ★改成比「对表集合」，不是比"那一个门控位/那一个 wen"★：
                    #   多 wen 的变体上一个源本来就有多对，旧写法会把它判成不一致。
                    #   这里仍然是**逐条目类型核对**（simp/comp 是另外两个 golden
                    #   模块），只是把判据从"唯一值相等"换成"对表相等"。
                    pair_here = {(int(b), wn) for b, wn in re.findall(
                        r'srcStatus_%d_srcType\[(\d)\] & io_\w+_\d+_bits_(\w+Wen)' % sx,
                        re.sub(r'\s+', ' ', m.group(1)))}
                    pair_enq = {(b, wn) for b, wn in KIND_PAIRS[self.src_kind[sx]]
                                if wn in self.wen_present['iq']}
                    assert not pair_here or pair_here == pair_enq, (
                        f'{top}: {other} 的 IQ{w}->src{sx} 唤醒对表与 enq 不一致: '
                        f'{sorted(pair_here)} vs {sorted(pair_enq)}')

        # ★ og0 取消映射也必须逐条目类型核 ★
        # 这份映射我只从 enq 条目提取，而 simp/comp 是**另外两个 golden 模块**。
        # 上一轮 deqPortIdx 的 bug 就是"核了一种就推及三种"，这里不能重犯：
        # golden 在这一段有三处不规则同时存在（is0Lat 只门控 lane 0/1；
        # og0Cancel 下标取偶数位 0/2/4/6；lane 4-6 完全无取消），
        # 只要任一条目类型与 enq 不同，共享核那份参数就是错的。
        for other in (self.simp_mod, self.comp_mod):
            otxt = read(other)
            for w in range(self.n_wk_iq):
                m = re.search(r'wire\s+hasWakeupIQ_srcWakeupByIQ_\d+_%d = (.*?);\n' % w,
                              otxt, re.S)
                if m is None:
                    assert self.og0_idx[w] is None, (
                        f'{top}: {other} 的 IQ{w} 无 og0 取消，但 {self.enq_mod} 有')
                    continue
                body = m.group(1)
                cs = re.search(r'~cancelSel_(\d+)\b', body)
                if cs:
                    m2 = re.search(r'wire\s+cancelSel_%s =\n(.*?);\n' % cs.group(1),
                                   otxt, re.S)
                    og = int(re.search(r'og0Cancel_(\d+)', m2.group(1)).group(1))
                    kind = 'real' if 'is0Lat' in m2.group(1) else 'const1'
                else:
                    og = int(re.search(r'~io_commonIn_og0Cancel_(\d+)', body).group(1))
                    kind = 'const1'
                assert og == self.og0_idx[w] and kind == self.is0lat_kind[w], (
                    f'{top}: {other} 的 IQ{w} 取消映射 (og0Cancel_{og}, {kind}) 与 '
                    f'{self.enq_mod} 的 (og0Cancel_{self.og0_idx[w]}, '
                    f'{self.is0lat_kind[w]}) 不一致')

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
        # 条目子模块的 perf* 观测口：tb 的覆盖闸靠层次引用读它们。
        # ★ 不能按「有 IQ 唤醒就有 perfLdCancel」推：FP 族(EnqEntry_12 等)有
        #   perfWakeupByIQ/perfOg0Cancel 但**没有** perfLdCancel（整条 ldCancel
        #   通路不存在）。照推会让 tb 引用不存在的层次名，VCS 报 XMRE。
        self.has_perf_ld_cancel = 'io_commonOut_perfLdCancel_0' in {
            n for _, _, n, _ in port_decls(self.enq_mod)}
        self.out_exu    = 'io_exuSources_0_0_value' in self.pmap
        self.out_lddep  = 'io_loadDependency_0_0' in self.pmap
        self.out_cancel = 'io_cancelDeqVec_0' in self.pmap
        self.deq_rc     = 'io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx' in self.pmap
        self.deq_lddep  = ('io_deqEntry_0_bits_status_srcStatus_0_srcLoadDependency_0'
                           in self.pmap)
        # tb 的 srcType 激励形态（见 gen_tb 的「E1 专门激励」）。只对本轮新接入的
        # 访存变体打开：已签核变体的 tb 逐字不变。
        self.tb_mix_src_type = top in ('EntriesStaMou', 'EntriesVlduVstu',
                                       'EntriesVlduVstuVseglduVsegstu')

        # ---- 访存向量状态组(核的 HAS_VEC_MEM,见核 §2.6c) ----
        # 判据取**条目模块**里有没有 entryReg_status_vecMem_* 寄存器,
        # 并要求三种条目一致(共享核给三种条目同一个 HAS_VEC_MEM)。
        vm_in = ['entryReg_status_vecMem_sqIdx_flag' in read(m)
                 for m in (self.enq_mod, self.simp_mod, self.comp_mod)]
        assert len(set(vm_in)) == 1, (
            f'{top}: 三种条目的 status.vecMem 有无不一致 {vm_in} —— 核只有一个 HAS_VEC_MEM')
        self.has_vec_mem = vm_in[0]
        self.vm_sq_w = self.vm_lq_w = self.vm_nlse_w = 1
        self.vr_mask_w = self.vr_mbidx_w = 1
        if self.has_vec_mem:
            def w_of(n):
                assert n in self.pmap, f'{top}: 访存向量变体缺端口 {n}'
                return self.pmap[n][1]
            self.vm_sq_w   = 1 + w_of('io_enq_0_bits_status_vecMem_sqIdx_value')
            self.vm_lq_w   = 1 + w_of('io_enq_0_bits_status_vecMem_lqIdx_value')
            self.vm_nlse_w = w_of('io_enq_0_bits_status_vecMem_numLsElem')
            self.vr_mask_w  = w_of('io_og0Resp_0_bits_vecReplayMask')
            self.vr_mbidx_w = w_of('io_og0Resp_0_bits_vecReplayMbIdx')
            assert w_of('io_vecMemIn_lqDeqPtr_value') + 1 == self.vm_lq_w
            # og 响应里的三样:核假设 og0..og2 三档都是真端口、timer==3 档恒 0。
            # 逐张核对 golden 的查找表形状，不对就当场失败而不是生成错的 RTL。
            for fld in ('isVecPartReplay', 'vecReplayMask', 'vecReplayMbIdx'):
                tabs = re.findall(r'wire \[3:0\](?:\[\d+:0\])?\s+_GEN_\d+\s*=\s*'
                                  r'(\{[^;]*?io_og0Resp_0_bits_%s[^;]*?\});' % fld, txt, re.S)
                assert len(tabs) == 1, f'{top}: og 表 {fld} 找到 {len(tabs)} 张'
                slots = [x.strip() for x in re.findall(r'\{([^{}]*)\}', tabs[0])][::-1]
                want = [f'io_og{k}Resp_0_bits_{fld}' for k in range(3)]
                assert slots[:3] == want and re.fullmatch(r"\d+'h0", slots[3]), (
                    f'{top}: og 表 {fld} 形状不是 {{0, og2, og1, og0}}: {slots}')
        # isVleff 在负载里的位置(blocked 的判据要读它;comp 条目只存 DEQ 子集)
        self.plb_is_vleff = 0
        if self.has_vec_mem:
            off, w = self.pl_off['vpu_isVleff']
            assert w == 1 and off < self.pl_deq_w, 'vpu_isVleff 不在 DEQ 负载里'
            self.plb_is_vleff = off

        # ---- needFeedBack:阵列层的访存响应(核的 MEM_RESP_MODE,见核 §5a) ----
        # 从 golden enqEntries_0 实例的 issueResp_valid 连线表达式判形态：
        #   `…issueTimerRead[1] ? …`        -> 1 (StaMou)
        #   `(&…issueTimerRead) ? hitRespsVec…` -> 2 (访存向量)
        m = re.search(r'\.io_commonIn_issueResp_valid\s*\((.*?)\),\n\s*\.io_commonIn_issueResp_bits_resp',
                      txt, re.S)
        assert m, f'{top}: 找不到 enqEntries_0 的 issueResp_valid 连线'
        rv = re.sub(r'\s+', ' ', m.group(1))
        self.mem_srcs = []
        self.plb_sq_flag = self.plb_sq_value = self.plb_lq_flag = self.plb_lq_value = 0
        self.sq_val_w = self.lq_val_w = 1
        if 'issueTimerRead[1] ?' in rv:
            self.mem_resp_mode = 1
            src = re.findall(r'(io_\w+)_valid &', rv)
            assert len(src) == 1, f'{top}: StaMou 形响应来源不唯一 {src}'
            self.mem_srcs = src
        elif re.search(r'\(&_enqEntries_0_io_commonOut_issueTimerRead\) \? hitRespsVec', rv):
            self.mem_resp_mode = 2
            hs = sorted((int(k), s) for k, s in re.findall(
                r'wire\s+hitRespsVec_(\d) =\s*(io_\w+)_valid &', txt))
            assert [k for k, _ in hs] == list(range(len(hs))) and hs, f'{top}: hitRespsVec 解析失败'
            self.mem_srcs = [s for _, s in hs]
        else:
            self.mem_resp_mode = 0
        if self.mem_resp_mode:
            for s in self.mem_srcs:
                assert f'{s}_bits_sqIdx_flag' in self.pmap, f'{top}: {s} 没有 sqIdx'
            self.sq_val_w = self.pmap[f'{self.mem_srcs[0]}_bits_sqIdx_value'][1]
            self.plb_sq_flag  = self.pl_off['sqIdx_flag'][0]
            self.plb_sq_value = self.pl_off['sqIdx_value'][0]
            assert self.pl_off['sqIdx_value'][1] == self.sq_val_w
            if self.mem_resp_mode == 2:
                self.lq_val_w = self.pmap[f'{self.mem_srcs[0]}_bits_lqIdx_value'][1]
                self.plb_lq_flag  = self.pl_off['lqIdx_flag'][0]
                self.plb_lq_value = self.pl_off['lqIdx_value'][0]
                assert self.pl_off['lqIdx_value'][1] == self.lq_val_w
            for f in ('sqIdx_flag', 'sqIdx_value', 'lqIdx_flag', 'lqIdx_value'):
                if f in self.pl_off:
                    assert self.pl_off[f][0] + self.pl_off[f][1] <= self.pl_deq_w, (
                        f'{top}: payload.{f} 不在 DEQ 负载里,comp 条目读不到')


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
        nms += ['iq_wake', 'og0_cancel']
        # ld_cancel 闸只在条目真有 perfLdCancel 观测口时才立（见 has_perf_ld_cancel）
        if v.has_perf_ld_cancel:
            nms.append('ld_cancel')
        nms.append('ds_forward')
        if v.has_rc:
            nms += ['rc_wake', 'ds_regcache']
    if v.out_cancel:
        nms.append('cancel_deq')
    if v.out_lddep:
        nms.append('lddep_nz')
    if v.mem_resp_mode:
        # 访存流水的响应真的在它那一档打回过条目（且命中）
        nms += ['mem_resp', 'mem_resp_succ']
    if v.has_vec_mem:
        nms += ['vec_blocked', 'vec_part_replay', 'vec_replay_mask']
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
    if v.mem_resp_mode:
        A(f'//   needFeedBack：MEM_RESP_MODE={v.mem_resp_mode}，访存响应来源 '
          + ' / '.join(s[len('io_'):] for s in v.mem_srcs)
          + ('（issueTimer[1] 时改用，按 sqIdx 命中）' if v.mem_resp_mode == 1
             else '（issueTimer==3 时各路按位或，按 sqIdx 与 lqIdx 同时命中）'))
    if v.has_vec_mem:
        A(f'//   访存向量状态组：vecMem = {{numLsElem {v.vm_nlse_w}, lqIdx {v.vm_lq_w}, '
          f'sqIdx {v.vm_sq_w}}} 位，vecReplayMask {v.vr_mask_w} 位 / MbIdx {v.vr_mbidx_w} 位，'
          'blocked 为真逻辑（三种条目都有）')
    A(f'//   负载：发射口可见 {len(v.pl_deq)} 个字段 / {v.pl_deq_w} 位；'
      f'转移包另带 {len(v.pl_extra)} 个字段，共 {v.pl_trans_w} 位')
    A(f'//   golden 层次：{v.enq_mod} ×{v.n_enq} + {v.simp_mod} ×{v.n_simp}'
      f' + {v.comp_mod} ×{v.n_comp} + {v.enq_policy} ×2，本文件把它们一并扁平化。')
    A('//')
    A('// 唤醒路由（从 golden currentStatus_srcStatus_<s>_srcState 表达式机械提取）：')
    for s in range(v.n_regsrc):
        lanes = v.src_wb[s]
        _pairs = sorted((b, wn) for b, wn in KIND_PAIRS[v.src_kind[s]]
                        if wn in v.wen_present['wb'])
        A(f'//   src{s}: WB[{lanes[0]}..{lanes[-1]}]，匹配 '
          + ' | '.join(f'srcType[{b}]&{wn}' for b, wn in _pairs))
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
    if v.has_vec_mem:
        A(f'  logic [{v.n_deq-1}:0][{v.vm_sq_w + v.vm_lq_w + v.vm_nlse_w - 1}:0] deq_vm;'
          '   // {numLsElem, lqIdx, sqIdx}')
        A(f'  logic [{v.n_deq-1}:0] deq_vpr;')
        A(f'  logic [{v.n_deq-1}:0][{v.vr_mask_w-1}:0] deq_vr_mask;')
        A(f'  logic [{v.n_deq-1}:0][{v.vr_mbidx_w-1}:0] deq_vr_mbidx;')
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
    # ★ 顶层有没有 ldCancel 端口 —— 决定阵列层那两组寄存器生不生成。
    #   与 HAS_LD_DEP 不是一回事：VfdivVidiv 有影子寄存器但没有 ldCancel。
    A(f'    .HAS_LD_CANCEL({int(v.n_ld_cancel > 0)}),'
      f' .HAS_LD1_CANCEL({int(v.has_ld1)}),')
    A(f'    .LD_PIPES({v.ld_pipes}), .LD_DEP_W({v.ld_dep_w}),')
    # ---- IQ 即时唤醒 / 取消网络 / 寄存器缓存 ----
    A(f'    .NUM_WK_IQ({v.n_wk_iq}), .EXU_W({max(1, v.exu_w)}),')
    if v.n_wk_iq:
        A('    .IQ_SRC_MASK({' + ', '.join(bitvec(v.iq_mask[s], v.n_wk_iq)
                                           for s in reversed(range(v.n_regsrc))) + '}),')
        A('    .IQ_WEN_PRESENT(' + wenvec(v.wen_present['iq']) + '),')
        A('    .IQD_WEN_PRESENT(' + wenvec(v.wen_present['iqd']) + '),')
        # 第 w 路 IQ 唤醒自己就是第几条 load 流水(那一位常数 1,不左移)
        A('    .IQ_IS_LD_PIPE({' + ', '.join(
            bitvec(set(v.iq_self_pipe[w]), v.ld_pipes)
            for w in reversed(range(v.n_wk_iq))) + '}),')
        # 哪几路 IQ 唤醒真有 og0Cancel 源（golden 的 og0Cancel 是稀疏的）
        A('    .OG0_HAS_SRC(' + bitvec(
            {w for w in range(v.n_wk_iq) if v.og0_idx[w] is not None}, v.n_wk_iq) + '),')
        A(f'    .HAS_REG_CACHE({int(v.has_rc)}), .RC_IDX_W({max(1, v.rc_idx_w)}),')
        A('    .IQ_WRITE_RC(' + bitvec(v.rc_lanes, v.n_wk_iq)
          + f'), .RC_TYPE_BIT({v.rc_tbit}),')
    A('    .SRC_WB_MASK({' + ', '.join(bitvec(set(v.src_wb[s]), v.n_wk)
                                       for s in reversed(range(v.n_regsrc))) + '}),')
    A("    .SRC_MATCH_KIND({" + ', '.join(f"2'd{v.src_kind[s]}"
                                        for s in reversed(range(v.n_regsrc))) + '}),')
    A('    .WB_WEN_PRESENT(' + wenvec(v.wen_present['wb']) + '),')
    A('    .WBD_WEN_PRESENT(' + wenvec(v.wen_present['wbd']) + '),')
    A(f'    .HAS_IGNORE_OLD_VD({int(v.has_ignore)}),')
    A(f'    .VD_SRC({v.vd_src}), .VL_SRC({v.vl_src}),'
      f' .WB_VL_INT({v.wb_vl_int}), .WB_VL_VF({v.wb_vl_vf}),')
    for pl, fld in (('PLB_VM', 'vpu_vm'), ('PLB_VMA', 'vpu_vma'), ('PLB_VTA', 'vpu_vta'),
                    ('PLB_IS_DEPEND_OLDVD', 'vpu_isDependOldVd'),
                    ('PLB_IS_WRITE_PARTVD', 'vpu_isWritePartVd')):
        A(f'    .{pl}({v.pl_off[fld][0]}),')
    # issueResp 的 4 档:哪档带真 resp、哪档是常量,都从 golden 的查找表量出来
    A("    .OG_HAS_BITS(4'b" + ''.join(str(b) for b in reversed(v.og_has_bits)) + '),')
    if v.has_vec_mem or v.mem_resp_mode:
        A("    .OG_CONST_RESP({" + ', '.join(f"2'h{c:x}" for c in reversed(v.og_const)) + '}),')
    else:
        A("    .OG_CONST_RESP({" + ', '.join(f"2'h{c:x}" for c in reversed(v.og_const)) + '})')
    if v.has_vec_mem:
        A(f'    .HAS_VEC_MEM(1), .VM_SQ_W({v.vm_sq_w}), .VM_LQ_W({v.vm_lq_w}),'
          f' .VM_NLSE_W({v.vm_nlse_w}),')
        A(f'    .VR_MASK_W({v.vr_mask_w}), .VR_MBIDX_W({v.vr_mbidx_w}),'
          f' .PLB_IS_VLEFF({v.plb_is_vleff})' + (',' if v.mem_resp_mode else ''))
    if v.mem_resp_mode:
        A(f'    .MEM_RESP_MODE({v.mem_resp_mode}), .NUM_MEM_SRC({len(v.mem_srcs)}),'
          f' .SQ_VAL_W({v.sq_val_w}), .LQ_VAL_W({v.lq_val_w}),')
        A(f'    .PLB_SQ_FLAG({v.plb_sq_flag}), .PLB_SQ_VALUE({v.plb_sq_value}),'
          f' .PLB_LQ_FLAG({v.plb_lq_flag}), .PLB_LQ_VALUE({v.plb_lq_value})')
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
    if v.has_vec_mem:
        c.append('.enq_blocked({%s})' % ', '.join(
            f'io_enq_{i}_bits_status_blocked' for i in reversed(range(v.n_enq))))
        # status.vecMem 打包成 {numLsElem, lqIdx{flag,value}, sqIdx{flag,value}}
        c.append('.enq_vm({%s})' % ', '.join(
            f'io_enq_{i}_bits_status_vecMem_{f}' for i in reversed(range(v.n_enq))
            for f in ('numLsElem', 'lqIdx_flag', 'lqIdx_value', 'sqIdx_flag', 'sqIdx_value')))
        c.append('.lq_deq_ptr({io_vecMemIn_lqDeqPtr_flag, io_vecMemIn_lqDeqPtr_value})')
    else:
        c.append(".enq_blocked('0), .enq_vm('0), .lq_deq_ptr('0)")

    if v.n_wk_iq:
        for pfx, tag in (('io_wakeUpFromIQ', 'iq'), ('io_wakeUpFromIQDelayed', 'iqd')):
            c.append('.%s_wen({%s})' % (tag, ', '.join(
                wenpack(pfx, w, v.wen_lane['iq' if tag == 'iq' else 'iqd'].get(w, set()))
                for w in reversed(range(v.n_wk_iq)))))
            c.append('.%s_pdest({%s})' % (tag, ', '.join(
                f'{pfx}_{w}_bits_pdest' for w in reversed(range(v.n_wk_iq)))))
            if v.iq_has_ld_dep:
                c.append('.%s_ld_dep({%s})' % (tag, ', '.join(
                    f'{pfx}_{w}_bits_loadDependency_{q}'
                    for w in reversed(range(v.n_wk_iq))
                    for q in reversed(range(v.ld_pipes)))))
            else:
                c.append(f".{tag}_ld_dep('0)")
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
            wenpack(pfx, w, v.wen_lane['wb' if tag == 'wk' else 'wbd'].get(w, set()))
            for w in reversed(range(v.n_wk)))))
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
    if v.has_vec_mem:
        for tag, fld in (('og_vpr', 'isVecPartReplay'), ('og_vr_mask', 'vecReplayMask'),
                         ('og_vr_mbidx', 'vecReplayMbIdx')):
            c.append('.%s({%s})' % (tag, ', '.join(
                '{%s}' % ', '.join(f'io_og{k}Resp_{d}_bits_{fld}'
                                   for d in reversed(range(v.n_deq)))
                for k in reversed(range(3)))))
    else:
        c.append(".og_vpr('0), .og_vr_mask('0), .og_vr_mbidx('0)")
    if v.mem_resp_mode:
        # 下标 m = golden hitRespsVec_m 的来源顺序（高位在前拼接）
        ms = list(reversed(v.mem_srcs))
        c.append('.mem_valid({%s})' % ', '.join(f'{s}_valid' for s in ms))
        c.append('.mem_resp({%s})' % ', '.join(f'{s}_bits_resp' for s in ms))
        c.append('.mem_sq_idx({%s})' % ', '.join(
            f'{{{s}_bits_sqIdx_flag, {s}_bits_sqIdx_value}}' for s in ms))
        if v.mem_resp_mode == 2:
            c.append('.mem_lq_idx({%s})' % ', '.join(
                f'{{{s}_bits_lqIdx_flag, {s}_bits_lqIdx_value}}' for s in ms))
            c.append('.mem_vpr({%s})' % ', '.join(f'{s}_bits_isVecPartReplay' for s in ms))
            c.append('.mem_vr_mask({%s})' % ', '.join(f'{s}_bits_vecReplayMask' for s in ms))
            c.append('.mem_vr_mbidx({%s})' % ', '.join(f'{s}_bits_vecReplayMbIdx' for s in ms))
        else:
            # StaMou 形：命中只比 sqIdx，响应只带 resp
            c.append(".mem_lq_idx('0), .mem_vpr('0), .mem_vr_mask('0), .mem_vr_mbidx('0)")
    else:
        c.append(".mem_valid('0), .mem_resp('0), .mem_sq_idx('0), .mem_lq_idx('0)")
        c.append(".mem_vpr('0), .mem_vr_mask('0), .mem_vr_mbidx('0)")
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
    if v.has_vec_mem:
        c.append('.o_deq_vm(deq_vm), .o_deq_vpr(deq_vpr)')
        c.append('.o_deq_vr_mask(deq_vr_mask), .o_deq_vr_mbidx(deq_vr_mbidx)')
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
            # ★ 逐端口判在不在 golden 里，不许按「口 0 有、口 1 也该有」补齐。
            #   FaluFmacFdiv / FaluFcvtF2vFmacFdiv 实测：发射口 0 露
            #   srcStatus_0/1/2，发射口 1 只露 0/1 —— 第 2 源在口 1 上没有读者，
            #   firtool 把那两个端口消掉了。补齐成对称 = 造 golden 没有的端口。
            for fld, arr in (('psrc   ', 'deq_psrc'), ('srcType', 'deq_src_type')):
                pn = f'io_deqEntry_{d}_bits_status_srcStatus_{s}_{fld.strip()}'
                if pn in v.pmap:
                    A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}_{fld} '
                      f'= {arr}[{d}][{s}];')
            if v.deq_rc:
                A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}_regCacheIdx = '
                  f'deq_rc_idx[{d}][{s}];')
            if v.deq_lddep:
                for q in range(v.ld_pipes):
                    A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}'
                      f'_srcLoadDependency_{q} = deq_ld_dep[{d}][{s}][{q}];')
        if v.has_vec_mem:
            sq, lq, ne = v.vm_sq_w, v.vm_lq_w, v.vm_nlse_w
            pre = f'io_deqEntry_{d}_bits_status_'
            A(f'  assign {pre}vecMem_sqIdx_value = deq_vm[{d}][{sq-2}:0];')
            A(f'  assign {pre}vecMem_sqIdx_flag  = deq_vm[{d}][{sq-1}];')
            A(f'  assign {pre}vecMem_lqIdx_value = deq_vm[{d}][{sq+lq-2}:{sq}];')
            A(f'  assign {pre}vecMem_lqIdx_flag  = deq_vm[{d}][{sq+lq-1}];')
            A(f'  assign {pre}vecMem_numLsElem   = deq_vm[{d}][{sq+lq+ne-1}:{sq+lq}];')
            A(f'  assign {pre}isVecPartReplay    = deq_vpr[{d}];')
            A(f'  assign {pre}vecReplayMask      = deq_vr_mask[{d}];')
            A(f'  assign {pre}vecReplayMbIdx     = deq_vr_mbidx[{d}];')
        for n, w in v.pl_deq:
            port = v.deq_pl_port(d, n)
            if port in v.pmap:          # 顶层把用不到的负载字段继续 DCE 掉了
                A(f'  assign {port} = deq_payload[{d}]{v.plslice(n)};')
    # ---- golden 顶层自己也不读的输入 ----
    # firtool 保留了这些端口（契约要求同名同宽），但 golden Entries<V> 里除了端口声明
    # 再没有任何读者（例：vecLdIn.resp 的 robIdx/fuType/uopIdx —— 命中只比 sqIdx/lqIdx）。
    # 这里把它们显式收进一根无人读的线：表示"逐个查过、确实不用"，而不是漏接。
    # 判据是机械的：golden 源文件里该名字只出现 1 次（= 端口声明本身）。
    body_so_far = '\n'.join(L)
    body_so_far = body_so_far.split(');', 1)[1] if ');' in body_so_far else body_so_far
    gtxt = read(v.top)
    dead_in = [n for d, w, n, _ in v.ports if d == 'input'
               and not re.search(r'\b%s\b' % re.escape(n), body_so_far)]
    for n in dead_in:
        cnt = len(re.findall(r'\b%s\b' % re.escape(n), gtxt))
        assert cnt == 1, f'{v.top}: 输入 {n} 在 golden 里有读者（出现 {cnt} 次）却没接'
    if dead_in:
        A('')
        A('  // golden 顶层也不读的输入（golden 源里只有端口声明、没有读者）：')
        A('  // 显式收拢在这里，表示逐个查过、确实不用，而不是漏接。')
        A('  wire unused_golden_dead_inputs = ^{')
        A(',\n'.join('    ' + n for n in dead_in))
        A('  };')
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
    if v.mem_resp_mode or v.has_vec_mem:
        A('  localparam int IDXPOOL = 4;  // sqIdx/lqIdx/lqDeqPtr 的小池，让访存响应与 blocked 打得中')
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
            if v.tb_mix_src_type:
                # ★E1 专门激励★：一个源的匹配种类（MK_GP/MK_V0/MK_VL）决定它听哪几对
                #   (srcType 位, wen)。只给"对"的那一位，永远打不到「srcType 与 wen
                #   种类交叉」的情形——而把三张对表并成一张的错法恰恰只在交叉时才露。
                #   所以：70% 在本源的合法位里均匀挑，30% 给 4 位全随机（含交叉/多位）。
                bits = sorted(b for b, wn in KIND_PAIRS[v.src_kind[s]]
                              if wn in v.wen_present['wb'])
                assert bits == list(range(bits[0], bits[-1] + 1)), bits
                pick = (f"4'h{1 << bits[0]:x}" if len(bits) == 1 else
                        f"(4'h1 << $urandom_range({bits[0]}, {bits[-1]}))")
                A(f'    // src{s} 的匹配种类 kind={v.src_kind[s]}，合法门控位 {bits}')
                A(f"    io_enq_{i}_bits_status_srcStatus_{s}_srcType <= "
                  f"($urandom_range(0,99) < 70) ? {pick} : 4'($urandom_range(0,15));")
            else:
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
            if v.has_vec_mem and n == 'vpu_isVleff':
                bias = 40
            if v.mem_resp_mode and n in ('sqIdx_value', 'lqIdx_value'):
                # 访存响应按 sqIdx/lqIdx 命中条目：两侧共用小池，否则永远打不中
                A(f"    {p} <= {pw}'($urandom_range(0, IDXPOOL-1));")
                continue
            if v.mem_resp_mode and n in ('sqIdx_flag', 'lqIdx_flag'):
                A(f"    {p} <= ($urandom_range(0, 99) < 20);")
                continue
            if bias is not None:
                A(f'    {p} <= ($urandom_range(0, 99) < {bias});')
            elif pw == 1:
                A(f'    {p} <= $urandom_range(0, 1);')
            else:
                nw = (pw + 31) // 32
                A(f"    {p} <= {pw}'({{" + ', '.join(['$urandom'] * nw) + '});')
    if v.has_vec_mem:
        A('    // 访存向量状态组的派遣值：lqIdx 与 lqDeqPtr 共用小池，blocked 才有真次态可测')
        for i in range(v.n_enq):
            pre = f'io_enq_{i}_bits_status_'
            A(f'    {pre}blocked <= ($urandom_range(0, 99) < 10);')
            A(f"    {pre}vecMem_sqIdx_flag  <= ($urandom_range(0, 99) < 20);")
            A(f"    {pre}vecMem_sqIdx_value <= {v.vm_sq_w-1}'($urandom_range(0, IDXPOOL-1));")
            A(f"    {pre}vecMem_lqIdx_flag  <= ($urandom_range(0, 99) < 20);")
            A(f"    {pre}vecMem_lqIdx_value <= {v.vm_lq_w-1}'($urandom_range(0, IDXPOOL-1));")
            A(f"    {pre}vecMem_numLsElem   <= {v.vm_nlse_w}'($urandom);")
        A("    io_vecMemIn_lqDeqPtr_flag  <= ($urandom_range(0, 99) < 20);")
        A(f"    io_vecMemIn_lqDeqPtr_value <= {v.vm_lq_w-1}'($urandom_range(0, IDXPOOL-1));")
    if v.mem_resp_mode:
        A('    // 访存流水的响应：sqIdx/lqIdx 与条目负载共用小池')
        for s in v.mem_srcs:
            A(f'    {s}_valid <= ($urandom_range(0, 99) < 45);')
            for n, (d, w) in sorted((n, v.pmap[n]) for n in v.pmap
                                    if n.startswith(s + '_bits_')):
                f = n[len(s) + 6:]
                if f in ('sqIdx_value', 'lqIdx_value'):
                    A(f"    {n} <= {w}'($urandom_range(0, IDXPOOL-1));")
                elif f in ('sqIdx_flag', 'lqIdx_flag'):
                    A(f"    {n} <= ($urandom_range(0, 99) < 20);")
                elif f == 'resp':
                    A(f"    {n} <= ($urandom_range(0,99) < 60) ? 2'b11 :"
                      " (($urandom_range(0,1)) ? 2'b00 : 2'b01);")
                elif f == 'isVecPartReplay':
                    A(f"    {n} <= ($urandom_range(0, 99) < 30);")
                elif w == 1:
                    A(f'    {n} <= $urandom_range(0, 1);')
                else:
                    A(f"    {n} <= {w}'({{" + ', '.join(['$urandom'] * ((w + 31) // 32)) + '});')
    A('    // 唤醒总线：pdest 取自小池，写使能高概率有效')
    for w in range(v.n_wk):
        A(f'    io_wakeUpFromWB_{w}_valid <= ($urandom_range(0, 99) < 35);')
        for _f in v.wk_wen_lanes[w]:
            A(f'    io_wakeUpFromWB_{w}_bits_{_f} <= ($urandom_range(0, 99) < 85);')
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
            if v.iq_has_ld_dep:
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
        for _f in v.wk_wen_lanes[w]:
            A(f'    io_wakeUpFromWBDelayed_{w}_bits_{_f} <= io_wakeUpFromWB_{w}_bits_{_f};')
        A(f'    io_wakeUpFromWBDelayed_{w}_bits_pdest <= io_wakeUpFromWB_{w}_bits_pdest;')
    for w in range(v.n_wk_iq):
        for f in ([v.iq_wen[w], 'pdest'] + (['rcDest'] if v.has_rc else [])
                  + ([f'loadDependency_{q}' for q in range(v.ld_pipes)]
                     if v.iq_has_ld_dep else [])
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
            if v.has_vec_mem:
                A(f'    io_og{k}Resp_{d}_bits_isVecPartReplay = ($urandom_range(0, 99) < 25);')
                A(f"    io_og{k}Resp_{d}_bits_vecReplayMask = {v.vr_mask_w}'($urandom);")
                A(f"    io_og{k}Resp_{d}_bits_vecReplayMbIdx = {v.vr_mbidx_w}'($urandom);")
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
        if v.has_perf_ld_cancel:
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
    ents_all = ([f'u_g.enqEntries_{i}' for i in range(v.n_enq)]
                + [f'u_g.othersEntriesSimp_{j}' for j in range(v.n_simp)]
                + [f'u_g.othersEntriesComp_{j}' for j in range(v.n_comp)])
    if v.mem_resp_mode:
        win = ('io_commonOut_issueTimerRead[1]' if v.mem_resp_mode == 1
               else '(&{e}.io_commonOut_issueTimerRead)')
        def w_of(e):
            return (f'{e}.' + win) if v.mem_resp_mode == 1 else win.format(e=e)
        A('    // 访存响应窗口里条目真的收到了（命中的）响应')
        A('    if (%s) cov_mem_resp++;' % ' || '.join(
            f"({e}.io_commonIn_issueResp_valid === 1'b1 && {w_of(e)} === 1'b1)"
            for e in ents_all))
        A('    if (%s) cov_mem_resp_succ++;' % ' || '.join(
            f"({e}.io_commonIn_issueResp_valid === 1'b1 && {w_of(e)} === 1'b1 && "
            f"{e}.io_commonIn_issueResp_bits_resp === 2'b11)"
            for e in ents_all))
    if v.has_vec_mem:
        A('    // 访存向量状态组：blocked 真的挡过、isVecPartReplay / mask 真的被响应改写过')
        A('    if (%s) cov_vec_blocked++;' % ' || '.join(
            f"({e}.validReg_last_REG === 1'b1 && {e}.entryReg_status_blocked === 1'b1)"
            for e in ents_all))
        A('    if (%s) cov_vec_part_replay++;' % ' || '.join(
            f"({e}.validReg_last_REG === 1'b1 && {e}.entryReg_status_isVecPartReplay === 1'b1)"
            for e in ents_all))
        A('    if (%s) cov_vec_replay_mask++;' % ' || '.join(
            f"({e}.validReg_last_REG === 1'b1 && {e}.io_commonIn_issueResp_bits_isVecPartReplay === 1'b1)"
            for e in ents_all))
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
    'EntriesLdu':
        '# 本变体实测（2026-09-21，signoff-strict）：加强前 native SUCCEEDED\n'
        '# passing 12171 / failing 0 / unmatched 六项全 0 / 黑盒输出 0，\n'
        '# 余 2980 未读点**全部** matched_nc，两侧严格 1:1，且 2980/2980 都来自\n'
        '# 钉点文件（12648 对，FM 自行猜配 0 对）——构成 = enqEntries_N 1490 位\n'
        '# + othersEntriesSimp_N 1490 位的条目内死负载。\n'
        '# 加强后期望 passing 12171 -> 15151（恰好 +2980）、unread 归 0、failing 仍 0；\n'
        '# 不增即空转，按 fail 处理。',
    'EntriesStdMoud':
        '# 本变体实测（2026-09-21，signoff-strict）：加强前 native SUCCEEDED\n'
        '# passing 10879 / failing 0 / unmatched 六项全 0 / 黑盒输出 0，\n'
        '# 余 3160 未读点**全部** matched_nc，两侧严格 1:1，且 3160/3160 都来自\n'
        '# 钉点文件（12108 对，FM 自行猜配 0 对）——构成 = enqEntries_N 1580 位\n'
        '# + othersEntriesSimp_N 1580 位的条目内死负载。\n'
        '# 加强后期望 passing 10879 -> 14039（恰好 +3160）、unread 归 0、failing 仍 0；\n'
        '# 不增即空转，按 fail 处理。',
    'EntriesStaMou':
        '# 本变体实测（2026-09-28，signoff-strict，impl 8c789148）：加强前 native SUCCEEDED\n'
        '# passing 11440 / failing 0 / unmatched 六项全 0 / 黑盒输出 0，\n'
        '# 余 3076 未读点**全部** matched_nc，两侧严格 1:1，且 3076/3076 都来自\n'
        '# 钉点文件（12360 对，FM 自行猜配 0 对）——构成 = enqEntries_N 1538 位\n'
        '# + othersEntriesSimp_N 1538 位的条目内死负载。\n'
        '# 加强后期望 passing 11440 -> 14516（恰好 +3076）、unread 归 0、failing 仍 0；\n'
        '# 不增即空转，按 fail 处理。',
    'EntriesVlduVstu':
        '# 本变体实测（2026-09-28，signoff-strict，impl 8c789148）：加强前 native SUCCEEDED\n'
        '# passing 16162 / failing 0 / unmatched 六项全 0 / 黑盒输出 0，\n'
        '# 余 2288 未读点**全部** matched_nc，两侧严格 1:1，且 2288/2288 都来自\n'
        '# 钉点文件（15224 对，FM 自行猜配 0 对）——构成 = enqEntries_N 1144 位\n'
        '# + othersEntriesSimp_N 1144 位的条目内死负载。\n'
        '# 加强后期望 passing 16162 -> 18450（恰好 +2288）、unread 归 0、failing 仍 0；\n'
        '# 不增即空转，按 fail 处理。',
    'EntriesVlduVstuVseglduVsegstu':
        '# 本变体实测（2026-09-28，signoff-strict，impl 8c789148）：加强前 native SUCCEEDED\n'
        '# passing 16196 / failing 0 / unmatched 六项全 0 / 黑盒输出 0，\n'
        '# 余 2288 未读点**全部** matched_nc，两侧严格 1:1，且 2288/2288 都来自\n'
        '# 钉点文件（15224 对，FM 自行猜配 0 对）——构成 = enqEntries_N 1144 位\n'
        '# + othersEntriesSimp_N 1144 位的条目内死负载。\n'
        '# 加强后期望 passing 16196 -> 18484（恰好 +2288）、unread 归 0、failing 仍 0；\n'
        '# 不增即空转，按 fail 处理。',
    'EntriesAluCsrFenceDiv':
        '# 本变体实测(2026-09-17, 钉点 20308 对)：native SUCCEEDED /\n'
        '# passing 18781 / failing 0 / unverified 0 / aborted 0 /\n'
        '# unmatched 六项全 0 / 黑盒输出 0 / qualifications 三项全空。\n'
        '# 余 6220 未读点**全部** matched_nc，两侧严格 1:1，且 6220/6220 都来自\n'
        '# 钉点文件（FM 自行猜配 0 对）——构成 = 8 条目(2 enq + 6 simp) x 776 位\n'
        '# 死负载 + 12 个 enqDelay 影子位。另有 Constant reg 12，不计入 unread，\n'
        '# 也不拦 verdict（fm_verdict.py 的 PARTIAL 判据只看\n'
        '# unverified/unmatched/aborted/unread 四项）。\n'
        '# ★ 仍缺 vmucp 白名单：加强后期望 passing 18781 -> 25001（恰好 +6220）、\n'
        '#   unread 归 0、failing 仍 0；不增即空转，按 fail 处理。',
}


# 哪些变体已经进了 scripts/fm_eq.tcl 的 matched-unread 加强白名单。
# ★ 这是 reviewer 的文件、reviewer 的决定：没进白名单的目标把这项设成 true，
#   fm_eq.tcl 会 FM_MODE_ERROR 直接 exit 3（fail-closed，但白跑一次）。
#   所以默认 false；要开必须先请示、由 reviewer 把目标加进那张白名单。
FM_VMUCP_WHITELISTED = {
    'EntriesVfdivVidiv',
    # 2026-09-17 reviewer 在 main acda25e 把 canary 加进 fm_eq.tcl 的白名单
    # （42 项）。两边必须同时生效，且**顺序不能反**：这边先开而白名单没开，
    # fm_eq.tcl 会 FM_MODE_ERROR exit 3，白跑一次 44 秒（已踩过）。
    'EntriesAluCsrFenceDiv',
    # 2026-09-20 本轮一次性加 7 个：六条证据由 vmucp_evidence.py 逐个采齐
    # （七个都打印"申请条件齐备"），依据与实测数字写在 scripts/fm_eq.tcl
    # 白名单旁边那段注释里。★两边必须同时生效，顺序不能反★。
    'EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v',
    'EntriesAluMulBkuBrhJmp',
    'EntriesFaluFcvtF2vFmacFdiv',
    'EntriesFaluFmac',
    'EntriesFaluFmacFdiv',
    'EntriesVfmaVialuFixVfalu',
    'EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf',
    # 2026-09-21 本轮加最后 2 个（家族 11 个变体至此全员）：六条证据同样由
    # vmucp_evidence.py 在**加强前**采齐，两个都打印"申请条件齐备"；依据与
    # 事前写死的期望值在 verif/fm_target_config/<top>.tcl 里逐条写明。
    # ★白名单已随 D57 拆进 per-target 文件，所以"两边同时生效"现在是指
    #   这张表 + verif/fm_target_config/<top>.tcl，两者缺一 fm_eq.tcl 会 exit 3。★
    'EntriesLdu',
    'EntriesStdMoud',
    # 2026-09-28 agent/entries-mem 加访存三变体（家族 14 个至此全员）：六条证据由
    # vmucp_evidence.py 在**加强前**采齐（加强前 receipt 在 evidence/8c789148b150/），
    # 依据与事前写死的期望值在 verif/fm_target_config/<top>.tcl 里逐条写明。
    'EntriesStaMou',
    'EntriesVlduVstu',
    'EntriesVlduVstuVseglduVsegstu',
}


def gen_mk(v):
    fm_note = FM_NOTES.get(v.top, '# 本变体的 FM 点数尚未实测。')
    vmucp = 'true' if v.top in FM_VMUCP_WHITELISTED else 'false'
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
#   白名单在 verif/fm_target_config/<top>.tcl（依据就写在那份文件里），两处须同时生效。
{fm_note}
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = {vmucp}

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


def port_gate(v, rtl, tb):
    """端口闸，**两个方向都要核**（CONVENTIONS「闸的负测必须是双向的」）。

    方向一（漏接）：golden 的每个端口都必须在生成的 wrapper 体里出现。
        只做这一半时，生成器悄悄漏掉 io_fromMem_* 这种整组端口也不会响。
    方向二（凭空造）：生成件里出现的每个 io_* 标识符都必须是 golden 真有的端口。
        ★ 这一半是被 FaluFmac 顶出来的：FP 族的 IQ 唤醒总线上没有
          loadDependency 端口，而 tb 生成器按 `if n_wk_iq:` 无条件驱动它，
          方向一照样满分（golden 端口一个没漏），VCS 才在编译期报
          Identifier-not-declared。只做方向一 = 只验证了"它会响"。
    返回问题列表，空表示两个方向都干净。
    """
    bad = []
    body = rtl.split(');', 1)[1]           # 去掉端口声明块本身
    missing = [n for n in v.pmap if not re.search(r'\b%s\b' % re.escape(n), body)]
    if missing:
        bad.append(f'wrapper 未接的 golden 端口 {len(missing)} 个: {sorted(missing)[:6]}')
    # 方向二的作用域要划准，否则就是个**恒报警**的闸（第一版正是：它把
    # 条目子模块的 io_commonIn_*/io_commonOut_*、以及 firtool 折行折断的
    # `io_dataSources_` 这种半截名一并报了，两个已签核变体全红）。
    # 只核**与 golden 顶层端口同族**的名字：族 = 第一个下划线段（io_wakeUpFromIQ、
    # io_fromMem…）。族在 golden 里根本不存在 ⇒ 那是子模块端口或注释，不归本闸管；
    # 名字以 `_` 结尾 ⇒ 折行折断的半截标识符，跳过。
    fams = {n.split('_')[1] for n in v.pmap if '_' in n[3:]}
    for tag, txt in (('wrapper', rtl), ('tb', tb)):
        used = {m.group(1) for m in re.finditer(r'\b(?:g_)?(io_[A-Za-z0-9_]+)\b', txt)}
        alien = sorted(n for n in used
                       if n not in v.pmap and not n.endswith('_')
                       and '_' in n[3:] and n.split('_')[1] in fams)
        if alien:
            bad.append(f'{tag} 引用了 golden 没有的端口 {len(alien)} 个: {alien[:6]}')

    # 方向三：tb 的覆盖闸靠**层次引用**读 golden 条目子模块内部
    # （u_g.enqEntries_0.io_commonOut_perfLdCancel_0 之类）。这些名字既不在顶层
    # 端口表里，也不由本生成器声明，方向一/二都够不着 —— 而 FP 族恰恰没有
    # perfLdCancel，VCS 要到编译期才以 XMRE 报出来。
    # 判据：被引用的名字必须在**那个子模块的 golden 源文件**里出现过。
    inst_mod = {'enqEntries': v.enq_mod, 'othersEntriesSimp': v.simp_mod,
                'othersEntriesComp': v.comp_mod}
    cache = {}
    dangling = []
    for m in re.finditer(r'u_g\.([A-Za-z]+)_(\d+)\.([A-Za-z_]\w*)', tb):
        mod = inst_mod.get(m.group(1))
        if mod is None:
            dangling.append(f'{m.group(1)}_{m.group(2)}(未知实例)'); continue
        if mod not in cache:
            cache[mod] = read(mod)
        if not re.search(r'\b%s\b' % re.escape(m.group(3)), cache[mod]):
            dangling.append(f'{mod}.{m.group(3)}')
    if dangling:
        uniq = sorted(set(dangling))
        bad.append(f'tb 层次引用了子模块没有的名字 {len(uniq)} 个: {uniq[:6]}')
    return bad


def main(top):
    check = '--check' in sys.argv
    v = Variant(top)
    here = outdir(top)
    rtl, tb = gen_rtl(v), gen_tb(v)
    for msg in port_gate(v, rtl, tb):
        print(f'PORT-GATE FAIL [{top}]: {msg}')
    if port_gate(v, rtl, tb):
        return 1
    files = {
        REPO / 'rtl' / 'backend' / f'{v.top}.sv': rtl,
        here / 'tb.sv':    tb,
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
