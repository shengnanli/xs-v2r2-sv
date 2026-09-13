#!/usr/bin/env python3
"""Entries* 家族薄变体文件 + UT 生成器（预研 canary：EntriesVfdivVidiv）。

一切事实都从 G1 golden 机械提取，不接受人工转述：
  * 顶层端口表         <- golden Entries<V>.sv 的 module 头（逐行原样搬运）
  * 条目分段 / 尺寸     <- golden 里 EnqEntry/OthersEntry 的实例名与数量
  * 负载字段与位宽      <- golden EnqEntry_N.sv 的 commonOut_{entry,transEntry} 端口
  * 唤醒路由表         <- golden EnqEntry_N.sv 的 currentStatus_srcStatus_<s>_srcState
                          表达式里出现的 WB 下标 / wen 字段 / srcType 位
用法：
  python3 gen.py            # 生成
  python3 gen.py --check    # 只校验已提交产物没漂移（非零退出=漂移）
"""
import re, sys, pathlib, collections

HERE   = pathlib.Path(__file__).resolve().parent
REPO   = HERE.parents[2]
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

        # 顶层 deqEntry 露出的负载字段必须与 EnqEntry 的 entry 出口一致
        top_deq = {n[len('io_deqEntry_0_bits_payload_'):] for n in self.pmap
                   if n.startswith('io_deqEntry_0_bits_payload_')}
        assert top_deq == dnames, f'deq 负载字段集不一致: {top_deq ^ dnames}'

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

    # -- 小工具 --
    def plslice(self, f):
        off, w = self.pl_off[f]
        return f'[{off+w-1}:{off}]' if w > 1 else f'[{off}]'


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
    A(f'//   WB 唤醒 {v.n_wk} 路（无 IQ 唤醒、无 og0/og1Cancel、无 ldCancel —— '
      f'本变体是全家族最简的一个）')
    A(f'//   保留的 FuType one-hot 位：{fu_list}（VFDIV 向量浮点除/开方、VIDIV 向量整数除）')
    A(f'//   srcLoadDependency 影子：每源 {v.ld_pipes} 条 load 流水 × {v.ld_dep_w} 位'
      f'（本变体无 ldCancel，恒 0，只为与 golden 寄存器结构对齐）')
    A(f'//   负载：发射口可见 {len(v.pl_deq)} 个字段 / {v.pl_deq_w} 位；'
      f'转移包另带 {len(v.pl_extra)} 个字段，共 {v.pl_trans_w} 位')
    A(f'//   golden 层次：{v.enq_mod} ×{v.n_enq} + {v.simp_mod} ×{v.n_simp}'
      f' + {v.comp_mod} ×{v.n_comp} + EnqPolicy ×2，本文件把它们一并扁平化。')
    A('//')
    A('// 唤醒路由（从 golden currentStatus_srcStatus_<s>_srcState 表达式机械提取）：')
    for s in range(v.n_regsrc):
        lanes = v.src_wb[s]
        A(f'//   src{s}: WB[{lanes[0]}..{lanes[-1]}]（{v.wk_wen[lanes[0]]}），'
          f'门控 srcType[{v.src_tbit[s]}]')
    A('//')
    A('// 自动生成：verif/ut/EntriesVfdivVidiv/gen.py —— 勿手改')
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
            src = f'io_enq_{i}_bits_payload_{n}'
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
    A('')
    # ---- 核例化 ----
    A('  xs_iq_entries_core #(')
    A(f'    .NUM_ENQ({v.n_enq}), .NUM_SIMP({v.n_simp}), .NUM_COMP({v.n_comp}),'
      f' .NUM_DEQ({v.n_deq}),')
    A(f'    .NUM_REGSRC({v.n_regsrc}), .NUM_WK_WB({v.n_wk}),'
      f' .NUM_FU_BIT({len(v.fu_bits)}),')
    A(f'    .ROB_W({v.rob_w}), .PSRC_W({v.psrc_w}), .PDEST_W({v.pdest_w}),')
    A(f'    .PL_DEQ_W({v.pl_deq_w}), .PL_TRANS_W({v.pl_trans_w}),')
    A(f'    .HAS_LD_DEP({int(v.has_ld_dep)}), .LD_PIPES({v.ld_pipes}),'
      f' .LD_DEP_W({v.ld_dep_w}),')
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
    A(f'    .NEED_OG2_RESP({int(v.need_og2)})')
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
    c.append(".enq_ld_dep('0)")
    for pfx, tag in (('io_wakeUpFromWB', 'wk'), ('io_wakeUpFromWBDelayed', 'wkd')):
        c.append('.%s_valid({%s})' % (tag, ', '.join(
            f'{pfx}_{w}_valid' for w in reversed(range(v.n_wk)))))
        c.append('.%s_wen({%s})' % (tag, ', '.join(
            f'{pfx}_{w}_bits_{v.wk_wen[w]}' for w in reversed(range(v.n_wk)))))
        c.append('.%s_pdest({%s})' % (tag, ', '.join(
            f'{pfx}_{w}_bits_pdest' for w in reversed(range(v.n_wk)))))
    c.append('.vl_int_is_zero(io_vlFromIntIsZero), .vl_int_is_vlmax(io_vlFromIntIsVlmax)')
    c.append('.vl_vf_is_zero(io_vlFromVfIsZero), .vl_vf_is_vlmax(io_vlFromVfIsVlmax)')
    for tag, port in (('og0_valid', 'io_og0Resp_%d_valid'),
                      ('og1_valid', 'io_og1Resp_%d_valid'),
                      ('og2_valid', 'io_og2Resp_%d_valid'),
                      ('og2_resp',  'io_og2Resp_%d_bits_resp')):
        if (port % 0) in v.pmap:
            c.append('.%s({%s})' % (tag, ', '.join(port % d
                                                   for d in reversed(range(v.n_deq)))))
        else:
            c.append(f".{tag}('0)")
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
    for d in range(v.n_deq):
        A(f'  assign io_deqEntry_{d}_bits_status_robIdx_flag  = deq_rob_flag[{d}];')
        A(f'  assign io_deqEntry_{d}_bits_status_robIdx_value = deq_rob_value[{d}];')
        for k, b in enumerate(v.fu_bits):
            A(f'  assign io_deqEntry_{d}_bits_status_fuType_{b} = deq_fu_type[{d}][{k}];')
        for s in range(v.n_regsrc):
            A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}_psrc    = deq_psrc[{d}][{s}];')
            A(f'  assign io_deqEntry_{d}_bits_status_srcStatus_{s}_srcType = deq_src_type[{d}][{s}];')
        for n, w in v.pl_deq:
            A(f'  assign io_deqEntry_{d}_bits_payload_{n} = deq_payload[{d}]{v.plslice(n)};')
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
    A('  int cov_enq_fire = 0, cov_wb_wake = 0, cov_can_issue = 0, cov_deq_fire = 0;')
    A('  int cov_deq_clear = 0, cov_first_issue = 0;')
    A('  int cov_resp_succ = 0, cov_resp_block = 0, cov_resp_uncertain = 0;')
    A('  int cov_trans2simp = 0, cov_trans2comp = 0, cov_simp2comp = 0;')
    A('  int cov_ignore_old_vd = 0, cov_full = 0, cov_flush = 0;')
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
        for n, w in v.pl_all:
            p = f'io_enq_{i}_bits_payload_{n}'
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
    A('    io_vlFromIntIsZero  <= ($urandom_range(0, 99) < 15);')
    A('    io_vlFromIntIsVlmax <= ($urandom_range(0, 99) < 55);')
    A('    io_vlFromVfIsZero   <= ($urandom_range(0, 99) < 15);')
    A('    io_vlFromVfIsVlmax  <= ($urandom_range(0, 99) < 55);')
    A('  endtask')
    A('')
    A('  // wakeUpFromWBDelayed = wakeUpFromWB 打一拍（golden 上层 IssueQueue 就是这么接的）')
    A('  always @(posedge clock) begin')
    for w in range(v.n_wk):
        A(f'    io_wakeUpFromWBDelayed_{w}_valid <= io_wakeUpFromWB_{w}_valid;')
        A(f'    io_wakeUpFromWBDelayed_{w}_bits_{v.wk_wen[w]} <= io_wakeUpFromWB_{w}_bits_{v.wk_wen[w]};')
        A(f'    io_wakeUpFromWBDelayed_{w}_bits_pdest <= io_wakeUpFromWB_{w}_bits_pdest;')
    A('  end')
    A('')
    A('  // ---- 发射/年龄选择：在输入落定之后、时钟沿之前用阻塞赋值算 ----')
    A('  task automatic drive_deq();')
    A(f'    logic [{v.n_ent-1}:0] ci;')
    A('    int pick, cnt;')
    A('    ci  = g_io_canIssue;')
    A('    cnt = $countones(ci);')
    A("    io_deqSelOH_0_valid = 1'b0;")
    A(f"    io_deqSelOH_0_bits  = {v.n_ent}'h0;")
    A('    if (cnt > 0 && $urandom_range(0, 99) < 80) begin')
    A('      pick = $urandom_range(0, cnt-1);')
    A(f'      for (int k = 0; k < {v.n_ent}; k++)')
    A('        if (ci[k]) begin')
    A("          if (pick == 0) begin io_deqSelOH_0_valid = 1'b1;"
      f" io_deqSelOH_0_bits = {v.n_ent}'(1) << k; end")
    A('          pick--;')
    A('        end')
    A('    end')
    A('    io_deqReady_0          = ($urandom_range(0, 99) < 90);')
    A('    io_og0Resp_0_valid     = ($urandom_range(0, 99) < 15);')
    A('    io_og1Resp_0_valid     = ($urandom_range(0, 99) < 15);')
    A('    io_og2Resp_0_valid     = ($urandom_range(0, 99) < 70);')
    A("    io_og2Resp_0_bits_resp = ($urandom_range(0,99) < 65) ? 2'b11 :"
      " (($urandom_range(0,1)) ? 2'b00 : 2'b01);")
    A(f"    io_enqEntryOldestSel_0_bits   = {v.n_enq}'(1) << $urandom_range(0, {v.n_enq-1});")
    A('    io_simpEntryOldestSel_0_valid = |g_io_valid[%d:%d];'
      % (v.n_enq + v.n_simp - 1, v.n_enq))
    A(f"    io_simpEntryOldestSel_0_bits  = {v.n_simp}'(1) << $urandom_range(0, {v.n_simp-1});")
    A('    io_compEntryOldestSel_0_valid = |g_io_valid[%d:%d];'
      % (v.n_ent - 1, v.n_enq + v.n_simp))
    A(f"    io_compEntryOldestSel_0_bits  = {v.n_comp}'(1) << $urandom_range(0, {v.n_comp-1});")
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
    A('    if (io_deqSelOH_0_valid && io_deqReady_0 && '
      '(g_io_canIssue & io_deqSelOH_0_bits)) cov_deq_fire++;')
    A('    if (g_io_isFirstIssue_0) cov_first_issue++;')
    A("    if (io_og2Resp_0_valid && io_og2Resp_0_bits_resp == 2'b11) cov_resp_succ++;")
    A("    if (io_og2Resp_0_valid && io_og2Resp_0_bits_resp == 2'b00) cov_resp_block++;")
    A("    if (io_og2Resp_0_valid && io_og2Resp_0_bits_resp == 2'b01) cov_resp_uncertain++;")
    A('    if (|{%s}) cov_trans2simp++;' % ', '.join(
        f'g_io_simpEntryEnqSelVec_{i}' for i in range(v.n_enq)))
    A('    if (|{%s}) cov_trans2comp++;' % ', '.join(
        f'g_io_compEntryEnqSelVec_{i}' for i in range(v.n_enq)))
    A('    if (&g_io_valid) cov_full++;')
    A('    if (io_flush_valid) cov_flush++;')
    A('    // 白盒探针（只探 golden 侧；impl 侧的一致性由逐拍输出比对保证）')
    A("    if (u_g.enqEntries_0.ignoreOldVd_2 === 1'b1 || "
      "u_g.enqEntries_1.ignoreOldVd_2 === 1'b1) cov_ignore_old_vd++;")
    A('    if (%s) cov_simp2comp++;' % ' || '.join(
        f'u_g.othersEntriesSimp_{j}.io_commonIn_transSel === 1\'b1' for j in range(v.n_simp)))
    A('    // wb_wake：某个「原本未就绪」的源本拍被唤醒翻成就绪')
    A('    if (%s) cov_wb_wake++;' % ' || '.join(
        [f'(u_g.enqEntries_{i}.entryUpdate_status_srcStatus_0_srcState === 1\'b1 && '
         f'u_g.enqEntries_{i}.entryReg_status_srcStatus_0_srcState === 1\'b0)'
         for i in range(v.n_enq)] +
        [f'(u_g.othersEntriesSimp_{j}.entryUpdate_status_srcStatus_0_srcState === 1\'b1 && '
         f'u_g.othersEntriesSimp_{j}.entryReg_status_srcStatus_0_srcState === 1\'b0)'
         for j in range(v.n_simp)]))
    A('    // deq_clear：发射成功把条目清空（validReg 由 1 变 0 且不是被冲刷/转移）')
    A('    if (%s) cov_deq_clear++;' % ' || '.join(
        f"(u_g.othersEntriesComp_{j}.validReg_last_REG === 1'b1 && "
        f"u_g.othersEntriesComp_{j}.io_commonIn_issueResp_valid === 1'b1 && "
        f"u_g.othersEntriesComp_{j}.io_commonIn_issueResp_bits_resp === 2'b11)"
        for j in range(v.n_comp)))
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
    for nm in ('enq_fire', 'wb_wake', 'can_issue', 'deq_fire', 'deq_clear', 'first_issue',
               'resp_succ', 'resp_block', 'resp_uncertain',
               'trans2simp', 'trans2comp', 'simp2comp',
               'ignore_old_vd', 'full', 'flush'):
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


def gen_mk(v):
    return f"""# {v.top} UT/FM 入口（Entries* 家族 canary）
# 重写件只有两个：家族共享参数化核 + 本变体薄文件。
# golden 的 EnqEntry/OthersEntry/EnqPolicy 都不是独立签核目标，故本重写把它们
# 一起扁平化，不放 RTL_GOLDEN_DEPS、不做黑盒；FM 侧 ref 需要它们做依赖闭包。
# 自动生成：verif/ut/{v.top}/gen.py —— 勿手改
MODULE = {v.top}

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_iq_entries_core.sv \\
           $(RTL_DIR)/backend/{v.top}.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/{v.top}.sv \\
              $(GOLDEN_RTL)/{v.enq_mod}.sv \\
              $(GOLDEN_RTL)/{v.simp_mod}.sv \\
              $(GOLDEN_RTL)/{v.comp_mod}.sv \\
              $(GOLDEN_RTL)/EnqPolicy_18.sv

FM_VARIANTS = {v.top}
FM_REF_DEPS_{v.top} = {v.enq_mod}.sv {v.simp_mod}.sv {v.comp_mod}.sv EnqPolicy_18.sv

include ../../../scripts/ut_common.mk

# golden 带 XSError/XSPerf 等非综合断言，随机激励会踩到 $fatal；两侧统一关掉。
VCS += +define+SYNTHESIS
"""


def main():
    check = '--check' in sys.argv
    v = Variant('EntriesVfdivVidiv')
    files = {
        REPO / 'rtl' / 'backend' / f'{v.top}.sv': gen_rtl(v),
        HERE / 'tb.sv':    gen_tb(v),
        HERE / 'Makefile': gen_mk(v),
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
    sys.exit(main())
