#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_ctrlblock.py —— CtrlBlock 装配层 wrapper 与写回 lane 描述表的生成器。

CtrlBlock（golden 57,635 行 / 8288 端口 / 22 个 child 实例 / 16,966 条 child 引脚连线）
的可读核 xs_CtrlBlock_core 用 struct/数组端口，手写；而
  * golden 同名 wrapper 的 8288 个扁平端口、
  * 22 个 child 的引脚连线（其中 6755 条是顶层端口直连、7887 条是 child 之间直连），
  * 顶层扁平端口 ↔ 核 struct 端口的装包/拆包，
  * 27 路写回口的字段保留描述表 WB_LANE（golden firtool 逐路 DCE 的结果），
全是 golden 端口表 / 寄存器表 / 例化表的机械函数。手抄这 3 万行正是上一轮
CtrlBlock（xs-signoff 8 月）废掉的原因（inst.svh 卡死、816 条 payload glue 从未重写）。

本脚本现场解析 golden，把上面四样写进 rtl/backend/CtrlBlock.sv 的
`// BEGIN GENERATED(<tag>)` .. `// END GENERATED` 区域（wb_lane_table / wrapper_ports /
wrapper_body），手写区一个字不碰。

★fail-closed★：
  · 每条 child 引脚必须落进恰好一种处置：clock/reset、顶层端口直连、child 之间直连、
    golden 标 unused、或按引脚名的显式规则映射到核端口路径；映射后的路径必须能在
    ctrlblock_pkg 的 struct 定义里逐级解析（成员名、数组下标、位宽都核对）。
  · 核输入 struct 的每个叶子必须恰好被驱动一次（child 出口或顶层输入）；允许接 0 的
    叶子只能是 TIE0_ALLOW 里显式列出的那些（golden 里对应常量 0 的字段，见文件头 Q5）。
  · 顶层每个 output 端口必须要么被某个 child 引脚直接驱动、要么由核驱动（golden 尾部
    assign），二者必居其一。
  · WB_LANE 表的每个字段组要么整组保留要么整组没有（不许半组），data 段宽度、
    exceptionVec 位掩码、writebackNums 位宽逐项与 golden 寄存器表相等。
  · --check：重新生成并与文件现状逐字节比对，漂移即非零退出（进 gate_all.sh 的生成器幂等闸）。

用法：
  python3 scripts/gen_ctrlblock.py            # 写入
  python3 scripts/gen_ctrlblock.py --check    # 幂等闸
  python3 scripts/gen_ctrlblock.py --report   # 打印分类统计与 WB_LANE 表
"""
import argparse
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
G1 = pathlib.Path(os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical') / 'golden-rtl'
GOLDEN = G1 / 'CtrlBlock.sv'
RTL = REPO / 'rtl' / 'backend' / 'CtrlBlock.sv'

TOP = 'CtrlBlock'
WB_N = 27
DECODE_W = 6
EXC_N = 24


def die(msg):
    sys.stderr.write('gen_ctrlblock: ERROR: %s\n' % msg)
    sys.exit(1)


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
class Golden(object):
    def __init__(self, text):
        self.text = text
        lines = text.split('\n')
        self.lines = lines
        m = re.search(r'^module CtrlBlock\((.*?)\n\);', text, re.S | re.M)
        if not m:
            die('golden 模块头解析失败')
        self.ports = []            # (dir, width, name) 按源序
        for ln in m.group(1).split('\n'):
            pm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
            if pm:
                self.ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        self.port_w = {n: w for d, w, n in self.ports}
        self.port_dir = {n: d for d, w, n in self.ports}
        if len(self.ports) != 8288:
            die('golden 端口数 %d != 8288' % len(self.ports))
        body_start = text.index('\n);', m.start()) + 3
        body = text[body_start:]
        # 寄存器（含折行声明）
        self.regs = collections.OrderedDict()
        for w, n in re.findall(r'^\s*reg\s+(?:\[(\d+):0\]\s*)?\n?\s*(\w+)\s*;', body, re.M):
            self.regs[n] = int(w) + 1 if w else 1
        # child 出口 wire 声明（含折行）
        self.wire_w = {}
        for w, n in re.findall(r'^\s*wire\s+(?:\[(\d+):0\]\s*)?\n?\s*(_\w+)\s*;', body, re.M):
            self.wire_w[n] = int(w) + 1 if w else 1
        # 实例引脚表
        inst_re = re.compile(r'^  ([A-Za-z_]\w*) ([A-Za-z_]\w*) \($')
        self.insts = []            # (type, name)
        self.pins = collections.OrderedDict()   # (inst, pin) -> expr（多行合并）
        i = 0
        cur = None
        first_inst = None
        while i < len(lines):
            ln = lines[i]
            mm = inst_re.match(ln)
            if mm:
                cur = (mm.group(1), mm.group(2))
                self.insts.append(cur)
                if first_inst is None:
                    first_inst = i
                i += 1
                continue
            if cur and ln.strip().startswith('.'):
                buf = ln
                while not re.search(r'\)\s*,?\s*$', buf) or buf.count('(') > buf.count(')'):
                    i += 1
                    buf += '\n' + lines[i]
                pm = re.match(r'\s*\.(\w+)\s*\((.*)\)\s*,?\s*$', buf, re.S)
                self.pins[(cur[1], pm.group(1))] = ' '.join(pm.group(2).split())
            elif ln.strip() == ');':
                cur = None
            i += 1
        if len(self.insts) != 22:
            die('golden 实例数 %d != 22' % len(self.insts))
        # 只保留真正的 child 出口线 `_<实例>_<引脚>`（golden 还有 _probe/_genSnapshot_T_12 这类内部线）
        inst_names = [n for t_, n in self.insts]
        pin_exprs = set(self.pins.values())
        self.wire_w = collections.OrderedDict((n, w) for n, w in self.wire_w.items()
                                              if any(n.startswith('_%s_io_' % i) for i in inst_names) or n in pin_exprs)
        self.inst_type = dict((n, t) for t, n in self.insts)
        # 尾部 assign（最后一个实例之后）
        last = max(idx for idx, ln in enumerate(lines) if inst_re.match(ln))
        tail = '\n'.join(lines[last:])
        self.tail_assign = collections.OrderedDict()
        for lhs, rhs in re.findall(r'^\s*assign\s+(\w+)\s*=\s*(.*?);', tail, re.S | re.M):
            self.tail_assign[lhs] = ' '.join(rhs.split())
        # 非例化区的文本（glue 逻辑），用于判定顶层输入是否被核消费
        # 顶层 output 直接等于顶层 input / child wire 的 assign 是纯连线，不算 glue
        self.passthrough = collections.OrderedDict((l, r) for l, r in self.tail_assign.items()
                                                    if (r in self.port_dir and self.port_dir[r] == 'input') or r in self.wire_w)
        glue_tail = '\n'.join(ln for ln in tail.split('\n')
                              if not any(ln.strip().startswith('assign %s ' % l) for l in self.passthrough))
        self.glue_text = body[:body.index('\n  %s %s (' % self.insts[0])] + '\n' + glue_tail
        # always 块里 io_perf / io_error 的来源
        self.perf_src = collections.OrderedDict()
        for n, src in re.findall(r'io_perf_(\d+)_value_REG <= (_\w+);', body):
            self.perf_src[int(n)] = src
        self.error_src = re.findall(r'io_error_0_REG <= (_\w+);', body)
        # writebackNums 各口的同组集合
        self.nums_group = {}
        for m2 in re.finditer(r'delayedNotFlushedWriteBackNums_delayed_bits_r(?:_(\d+))? <=\s*(.*?);', body, re.S):
            lane = int(m2.group(1)) if m2.group(1) else 0
            rhs = m2.group(2).strip()
            if re.match(r'^_\w+$', rhs):   # 折成了一根中间 wire：取它的定义
                wm = re.search(r'wire\s+(?:\[[^\]]+\]\s*)?' + re.escape(rhs) + r'\s*=\s*(.*?);', body, re.S)
                if not wm:
                    die('writebackNums lane %d 的中间 wire %s 找不到定义' % (lane, rhs))
                rhs = wm.group(1)
            grp = set(int(x) for x in re.findall(r'io_fromWB_wbData_(\d+)_valid', rhs))
            self.nums_group[lane] = grp

    def is_child_wire(self, e):
        return e in self.wire_w

    def child_output_pins(self):
        """child 的输出引脚：表达式是 `_<inst>_<pin>` 形的 wire、或直连顶层输出端口、或 unused。"""
        out = []
        for (inst, pin), e in self.pins.items():
            if e == '_%s_%s' % (inst, pin) or (e in self.port_dir and self.port_dir[e] == 'output') or e == '/* unused */':
                out.append((inst, pin, e))
        return out


# ---------------------------------------------------------------------------
# ctrlblock_pkg 的类型树（从 rtl 文件现场解析，位宽/成员名以它为准）
# ---------------------------------------------------------------------------
class Types(object):
    def __init__(self, text):
        self.params = {}
        for n, v in re.findall(r"localparam\s+int\s+(\w+)\s*=\s*([^;]+);", text):
            try:
                self.params[n] = int(eval(v.replace("'h", '0x').split('//')[0], {}, dict(self.params)))
            except Exception:
                pass
        self.structs = collections.OrderedDict()   # name -> [(mname, elem_type, dims)]
        for body, name in re.findall(r'typedef\s+struct\s+packed\s*\{(.*?)\}\s*(\w+)\s*;', text, re.S):
            members = []
            for ln in body.split('\n'):
                ln = ln.split('//')[0].strip()
                if not ln:
                    continue
                for decl in ln.split(';'):
                    decl = decl.strip()
                    if not decl:
                        continue
                    mm = re.match(r'(\w+)\s*((?:\[[^\]]+\]\s*)*)\s*(.+)$', decl)
                    if not mm:
                        die('struct %s 成员解析失败: %r' % (name, decl))
                    et, dims, names = mm.group(1), mm.group(2), mm.group(3)
                    dl = [self._dim(d) for d in re.findall(r'\[([^\]]+)\]', dims)]
                    for mn in [x.strip() for x in names.split(',')]:
                        members.append((mn, et, dl))
            self.structs[name] = members

    def _dim(self, d):
        hi, lo = d.split(':')
        return self.ev(hi) - self.ev(lo) + 1

    def ev(self, e):
        return int(eval(e, {}, dict(self.params)))

    def width(self, et, dims):
        w = 1
        for d in dims:
            w *= d
        if et == 'logic':
            return w
        return w * self.struct_width(et)

    def struct_width(self, name):
        return sum(self.width(et, dl) for mn, et, dl in self.structs[name])

    def leaves(self, et, dims, prefix):
        """枚举叶子：(路径, 位宽)。数组按下标展开；logic 向量是一个叶子。"""
        if dims:
            out = []
            for k in range(dims[0]):
                out += self.leaves(et, dims[1:], '%s[%d]' % (prefix, k))
            return out
        if et == 'logic':
            return [(prefix, 1)]
        out = []
        for mn, met, mdl in self.structs[et]:
            if met == 'logic':
                out += self._logic_leaves(mdl, '%s.%s' % (prefix, mn))
            else:
                out += self.leaves(met, mdl, '%s.%s' % (prefix, mn))
        return out

    def _logic_leaves(self, dims, prefix):
        """logic 多维数组：除最后一维（位向量）外逐维展开成独立叶子。"""
        if len(dims) <= 1:
            return [(prefix, dims[0] if dims else 1)]
        out = []
        for k in range(dims[0]):
            out += self._logic_leaves(dims[1:], '%s[%d]' % (prefix, k))
        return out

    def resolve(self, et, dims, rest):
        """把扁平名 rest（'_' 连接）解析成 struct 路径，返回 (path_suffix, width)；失败返回 None。
        规则：数组维吃数字 token；struct 成员按最长名匹配；logic 向量允许再吃一个数字做位选。"""
        if dims:
            mm = re.match(r'(\d+)(?:_(.*))?$', rest)
            if not mm:
                return None
            k = int(mm.group(1))
            if k >= dims[0]:
                return None
            r = self.resolve(et, dims[1:], mm.group(2) or '')
            if r is None:
                return None
            return ('[%d]%s' % (k, r[0]), r[1])
        if et == 'logic':
            if rest == '':
                return ('', 1)
            return None
        if rest == '':
            return ('', self.struct_width(et))
        best = None
        for mn, met, mdl in self.structs[et]:
            if rest == mn or rest.startswith(mn + '_'):
                sub = rest[len(mn):].lstrip('_')
                if met == 'logic':
                    # logic 数组/向量：逐维吃数字 token（最后一维吃掉 = 位选）
                    idx = []
                    s = sub
                    ok = True
                    while s and len(idx) < len(mdl):
                        m3 = re.match(r'^(\d+)(?:_(.*))?$', s)
                        if not m3 or int(m3.group(1)) >= mdl[len(idx)]:
                            ok = False
                            break
                        idx.append(int(m3.group(1)))
                        s = m3.group(2) or ''
                    if ok and s == '':
                        wrem = 1
                        for d in mdl[len(idx):]:
                            wrem *= d
                        cand = ('.%s%s' % (mn, ''.join('[%d]' % k for k in idx)), wrem)
                    else:
                        cand = None
                else:
                    r = self.resolve(met, mdl, sub)
                    cand = ('.%s%s' % (mn, r[0]), r[1]) if r else None
                if cand and (best is None or len(mn) > best[2]):
                    best = (cand[0], cand[1], len(mn))
        return (best[0], best[1]) if best else None


# ---------------------------------------------------------------------------
# 名字规范化：golden 扁平名 → 与 ctrlblock_pkg 成员名一致的扁平名
# ---------------------------------------------------------------------------
ALIASES = [
    (r'folded_hist_hist_(\d+)_folded_hist', r'folded_hist_hist_\1'),
    (r'afhob_afhob_(\d+)_bits_(\d+)', r'afhob_\1_\2'),
    (r'redirect_bits_', r'redirect_'),
    (r'_bits_pd_', r'_bits_preDecodeInfo_'),
    (r'_bits_backendException$', r'_bits_isFetchMalAddr'),
]


def canon(name):
    for a, b in ALIASES:
        name = re.sub(a, b, name)
    return name


# ---------------------------------------------------------------------------
# 顶层端口 ↔ 核 io_in / io_out 的前缀表
# ---------------------------------------------------------------------------
IN_PREFIX = [
    (r'^io_frontend_cfVec_(\d)_bits_(.*)$', r'cfVec_\1_bits_\2'),
    (r'^io_frontend_cfVec_(\d)_valid$', r'cfVec_\1_valid'),
    (r'^io_frontend_fromFtq_(.*)$', r'fromFtq_\1'),
    (r'^io_csrCtrl_(fusion_enable|wfi_enable|singlestep)$', r'csrCtrl_\1'),
    (r'^io_fromCSR_traceCSR_(lastPriv|currentPriv)$', r'traceCSR_\1'),
    (r'^io_fromCSR_instrAddrTransType_(.*)$', r'instrAddrTransType_\1'),
    (r'^io_fromMem_violation_valid$', r'violation_valid'),
    (r'^io_fromMem_violation_bits_(.*)$', r'violation_bits_\1'),
    (r'^io_toDataPath_pcToDataPathIO_fromDataPathValid_(\d)$', r'fromDataPathValid_\1'),
    (r'^io_toDataPath_pcToDataPathIO_fromDataPathFtqPtr_(\d)_value$', r'fromDataPathFtqPtr_\1'),
    (r'^io_robio_csr_trapTarget_(.*)$', r'trapTarget_\1'),
    (r'^io_toDecode_vstart$', r'vstart'),
    (r'^io_fromWB_wbData_(\d+)_(.*)$', r'wb_\1_\2'),
]
OUT_PREFIX = [
    (r'^io_frontend_toFtq_rob_commits_(\d)_(.*)$', r'toFtq_rob_commits_\1_\2'),
    (r'^io_frontend_toFtq_redirect_valid$', r'toFtq_redirect_valid'),
    (r'^io_frontend_toFtq_redirect_bits_cfiUpdate_(.*)$', r'toFtq_redirect_cfiUpdate_\1'),
    (r'^io_frontend_toFtq_redirect_bits_(.*)$', r'toFtq_redirect_\1'),
    (r'^io_frontend_toFtq_ftqIdxAhead_0_valid$', r'toFtq_ftqIdxAhead0_valid'),
    (r'^io_frontend_toFtq_ftqIdxAhead_0_bits_value$', r'toFtq_ftqIdxAhead0_value'),
    (r'^io_frontend_toFtq_ftqIdxSelOH_bits$', r'toFtq_ftqIdxSelOH'),
    (r'^io_frontend_cfVec_(\d)_ready$', r'cfVec_ready_\1'),
    (r'^io_frontend_canAccept$', r'canAccept'),
    (r'^io_redirect_valid$', r'redirect_valid'),
    (r'^io_redirect_bits_robIdx_(flag|value)$', r'redirect_robIdx_\1'),
    (r'^io_redirect_bits_level$', r'redirect_level'),
    (r'^io_redirect_bits_isVlsException$', r'redirect_isVlsException'),
    (r'^io_to(IssueBlock|DataPath|ExuBlock)_flush_valid$', r'flush_valid'),
    (r'^io_to(IssueBlock|DataPath|ExuBlock)_flush_bits_(.*)$', r'flush_bits_\2'),
    (r'^io_toDataPath_pcToDataPathIO_toDataPathTargetPC_(\d)$', r'toDataPathTargetPC_\1'),
    (r'^io_robio_exception_bits_pc$', r'exception_pc'),
    (r'^io_robio_csr_perfinfo_retiredInstr$', r'retiredInstr'),
    (r'^io_toVecExcpMod_ratOldPest_(v0|vec)OldVdPdest_(\d)_(valid|bits)$', r'\1OldVdPdest_\2_\3'),
    (r'^io_traceCoreInterface_toEncoder_priv$', r'trace_priv'),
    (r'^io_error_0$', r'error0'),
]


def map_prefix(table, name):
    for a, b in table:
        if re.match(a, name):
            return re.sub(a, b, name)
    return None


# ---------------------------------------------------------------------------
# child 引脚（核 → child 入口）规则：按引脚名映射到核端口表达式（\N 为 regex 组）
#   'T:<type>' 表示剩余部分要在该 struct 类型里解析
# ---------------------------------------------------------------------------
REDIRECT_RULES = [
    (r'^io_redirect_valid$', 'io_out.redirect_valid'),
    (r'^io_redirect_bits_robIdx_(flag|value)$', r'io_out.redirect_robIdx.\1'),
    (r'^io_redirect_bits_level$', 'io_out.redirect_level'),
    (r'^io_redirect_bits_isVlsException$', 'io_out.redirect_isVlsException'),
]
IN_RULES = {
    'rob': REDIRECT_RULES + [
        (r'^io_redirect_bits_cfiUpdate_isMisPred$', 'rob_i.redirect_isMisPred'),
        (r'^io_enq_req_(\d)_valid$', r'rob_i.enq_req[\1].valid'),
        (r'^io_enq_req_(\d)_bits_(.*)$', r'rob_i.enq_req[\1].bits|T:dyn_inst_t|\2'),
        (r'^io_snpt_(useSnpt|snptSelect|snptDeq)$', r'rob_i.snpt_\1'),
        (r'^io_snpt_flushVec_(\d)$', r'rob_i.snpt_flushVec[\1]'),
        (r'^io_vstartIsZero$', 'rob_i.vstartIsZero'),
        (r'^io_wfi_enable$', 'rob_i.wfi_enable'),
        (r'^io_writeback_(\d+)_valid$', r'rob_i.writeback[\1].valid'),
        (r'^io_writeback_(\d+)_bits_(.*)$', r'rob_i.writeback[\1].bits|T:exu_output_t|\2'),
        (r'^io_exuWriteback_(\d+)_valid$', r'rob_i.exuWriteback_valid[\1]'),
        (r'^io_exuWriteback_(\d+)_bits_(.*)$', r'rob_i.writeback[\1].bits|T:exu_output_t|\2'),
        (r'^io_writebackNums_(\d+)_bits$', r'rob_i.writebackNums[\1]'),
        (r'^io_writebackNeedFlush_(\d+)$', 'NEEDFLUSH'),
    ],
    'dispatch': [
        (r'^io_renameIn_(\d)_valid$', r'dispatch_i.renameIn_valid[\1]'),
        (r'^io_renameIn_(\d)_bits_fuType$', r'dispatch_i.renameIn_fuType[\1]'),
        (r'^io_renameIn_(\d)_bits_fuOpType$', r'dispatch_i.renameIn_fuOpType[\1]'),
        (r'^io_enqRob_canAccept$', 'dispatch_i.enqRob_canAccept'),
        (r'^io_enqRob_isEmpty$', 'dispatch_i.enqRob_isEmpty'),
        (r'^io_singleStep$', 'dispatch_i.singleStep'),
    ] + REDIRECT_RULES,
    'decode': [
        (r'^io_redirect$', 'decode_i.redirect'),
        (r'^io_in_(\d)_valid$', r'decode_i.in[\1].valid'),
        (r'^io_in_(\d)_bits_(.*)$', r'decode_i.in[\1].bits|T:static_inst_t|\2'),
        (r'^io_fusion_(\d)$', r'decode_i.fusion[\1]'),
        (r'^io_backendCanAccept$', 'decode_i.backendCanAccept'),
        (r'^io_csrCtrl_(singlestep|fusion_enable|wfi_enable)$', r'decode_i.csrCtrl.\1'),
    ],
    'fusionDecoder': [
        (r'^io_disableFusion$', 'fusion_i.disableFusion'),
        (r'^io_in_(\d)_valid$', r'fusion_i.in_valid[\1]'),
    ],
    'rat': [
        (r'^io_renameUpdates_(\d)_valid$', r'rat_i.renameUpdates_valid[\1]'),
        (r'^io_snpt_(snptEnq|snptDeq|useSnpt|snptSelect)$', r'rat_i.snpt_\1'),
        (r'^io_snpt_flushVec_(\d)$', r'rat_i.snpt_flushVec[\1]'),
        (r'^io_redirect$', 'rat_i.redirect'),
    ],
    'rename': [
        (r'^io_redirect_valid$', 'rename_i.redirect_valid'),
        (r'^io_redirect_bits_robIdx_(flag|value)$', r'rename_i.redirect_robIdx.\1'),
        (r'^io_redirect_bits_level$', 'rename_i.redirect_level'),
        (r'^io_redirect_bits_(debugIsCtrl|debugIsMemVio)$', r'rename_i.redirect_\1'),
        (r'^io_in_(\d)_valid$', r'rename_i.in[\1].valid'),
        (r'^io_in_(\d)_bits_(srcType_1|lsrc_1|selImm|commitType|fuType|fuOpType)$', r'rename_i.in[\1].\2'),
        (r'^io_snpt_(snptDeq|useSnpt|snptSelect)$', r'rename_i.snpt_\1'),
        (r'^io_snpt_flushVec_(\d)$', r'rename_i.snpt_flushVec[\1]'),
        (r'^io_snptLastEnq_valid$', 'rename_i.snptLastEnq_valid'),
        (r'^io_snptLastEnq_bits_(flag|value)$', r'rename_i.snptLastEnq_bits.\1'),
        (r'^io_snptIsFull$', 'rename_i.snptIsFull'),
        (r'^io_singleStep$', 'rename_i.singleStep'),
    ],
    'redirectGen': [
        (r'^io_oldestExuRedirect_valid$', 'redirectgen_i.oldestExuRedirect_valid'),
        (r'^io_oldestExuRedirect_bits_(.*)$', r'redirectgen_i.oldestExuRedirect_bits|T:exu_redirect_t|\1'),
        (r'^io_oldestExuRedirectIsCSR$', 'redirectgen_i.oldestExuRedirectIsCSR'),
        (r'^io_instrAddrTransType_(.*)$', r'redirectgen_i.instrAddrTransType.\1'),
        (r'^io_oldestExuOutPredecode_(.*)$', r'redirectgen_i.oldestExuOutPredecode.\1'),
        (r'^io_loadReplay_valid$', 'redirectgen_i.loadReplay_valid'),
        (r'^io_loadReplay_bits_cfiUpdate_(pc|target)$', 'redirectgen_i.loadReplay_pc'),
        (r'^io_loadReplay_bits_(.*)$', r'redirectgen_i.loadReplay_bits|T:mem_violation_t|\1'),
        (r'^io_memPredPcRead_data$', 'redirectgen_i.memPredPcRead_data'),
        (r'^io_robFlush_valid$', 'redirectgen_i.robFlush_valid'),
        (r'^io_robFlush_bits_(.*)$', r'redirectgen_i.robFlush_bits|T:rob_flush_t|\1'),
    ],
    'pcMem': [
        (r'^io_ren_(\d+)$', r'pcmem_i.ren[\1]'),
        (r'^io_raddr_(\d+)$', r'pcmem_i.raddr[\1]'),
        (r'^io_wen_0$', 'pcmem_i.wen'),
        (r'^io_waddr_0$', 'pcmem_i.waddr'),
        (r'^io_wdata_0_startAddr$', 'pcmem_i.wdata_startAddr'),
    ],
    'memCtrl': [
        (r'^io_mdpFoldPcVecVld_(\d)$', r'memctrl_i.mdpFoldPcVecVld[\1]'),
        (r'^io_mdpFlodPcVec_(\d)$', r'memctrl_i.mdpFlodPcVec[\1]'),
    ],
    'snpt': [
        (r'^io_enq$', 'snpt_i.enq'),
        (r'^io_deq$', 'snpt_i.deq'),
        (r'^io_redirect$', 'snpt_i.redirect'),
        (r'^io_flushVec_(\d)$', r'snpt_i.flushVec[\1]'),
    ],
    'renamePipeDispatch': [
        (r'^io_in_0_bits_snapshot$', 'pgc_i.in0_snapshot'),
        (r'^io_flush$', 'io_out.redirect_valid'),
    ],
    's5_flushFromRobValidAhead_delay': [
        (r'^io_in$', 'delay_s5flush_in'),
    ],
}
for _k in range(DECODE_W):
    IN_RULES['decodePipeRenameModule' + ('' if _k == 0 else '_%d' % _k)] = [(r'^io_isFlush$', 'pipe_isFlush')]

# child 出口 → 核输入 struct 叶子
OUT_RULES = {
    'rob': [
        (r'^io_flushOut_valid$', 'rob_o.flushOut_valid'),
        (r'^io_flushOut_bits_(.*)$', r'rob_o.flushOut_bits|T:rob_flush_t|\1'),
        (r'^io_commits_isCommit$', 'rob_o.commits_isCommit'),
        (r'^io_commits_commitValid_(\d)$', r'rob_o.commits_commitValid[\1]'),
        (r'^io_commits_robIdx_(\d)_(flag|value)$', r'rob_o.commits_robIdx[\1].\2'),
        (r'^io_commits_info_(\d)_(commitType|ftqIdx_flag|ftqIdx_value|ftqOffset)$', r'rob_o.commits_info[\1]|T:commit_to_ftq_t|\2'),
        (r'^io_rabCommits_isCommit$', 'rob_o.rabCommits_isCommit'),
        (r'^io_rabCommits_isWalk$', 'rob_o.rabCommits_isWalk'),
        (r'^io_rabCommits_commitValid_(\d)$', r'rob_o.rabCommits_commitValid[\1]'),
        (r'^io_rabCommits_info_(\d)_(v0Wen|vecWen)$', r'rob_o.rabCommits_\2[\1]'),
        (r'^io_enq_(canAccept|canAcceptForDispatch|isEmpty)$', r'rob_o.enq_\1'),
        (r'^io_exception_valid$', 'rob_o.exception_valid'),
        (r'^io_csr_perfinfo_retiredInstr$', 'rob_o.retiredInstr'),
        (r'^io_error_0$', 'rob_o.error0'),
    ],
    'redirectGen': [
        (r'^io_stage2Redirect_valid$', 'redirectgen_o.stage2_valid'),
        (r'^io_stage2Redirect_bits_(.*)$', r'redirectgen_o.stage2_bits|T:redirect_t|\1'),
        (r'^io_stage2oldestOH$', 'redirectgen_o.stage2oldestOH'),
    ],
    'dispatch': [
        (r'^io_enqRob_req_(\d)_valid$', r'dispatch_o.enqRob_req[\1].valid'),
        (r'^io_enqRob_req_(\d)_bits_(.*)$', r'dispatch_o.enqRob_req[\1].bits|T:dyn_inst_t|\2'),
    ],
    'decode': [
        (r'^io_in_(\d)_ready$', r'decode_o.in_ready[\1]'),
        (r'^io_out_(\d)_valid$', r'decode_o.out_valid[\1]'),
        (r'^io_out_(\d)_bits_exceptionVec_(\d+)$', r'decode_o.out_exceptionVec[\1][\2]'),
        (r'^io_out_(\d)_bits_trigger$', r'decode_o.out_trigger[\1]'),
    ],
    'fusionDecoder': [
        (r'^io_out_(\d)_valid$', r'fusion_o.out[\1].valid'),
        (r'^io_out_(\d)_bits_(fuType_valid|fuOpType_valid|fuOpType_bits|src2Type_valid|lsrc2_valid|lsrc2_bits|selImm_valid|selImm_bits)$', r'fusion_o.out[\1].\2'),
        (r'^io_clear_(\d)$', r'fusion_o.clear[\1]'),
    ],
    'rename': [
        (r'^io_out_(\d)_valid$', r'rename_o.out_valid[\1]'),
        (r'^io_out_(\d)_bits_snapshot$', r'rename_o.out_snapshot[\1]'),
    ],
    'rat': [
        (r'^io_(v0|vec)_old_pdest_(\d)$', r'rat_o.\1_old_pdest[\2]'),
    ],
    'snpt': [
        (r'^io_valids_(\d)$', r'snpt_o.valids[\1]'),
        (r'^io_snapshots_(\d)_robIdx_(\d)_(flag|value)$', r'snpt_o.snapshots[\1].robIdx[\2].\3'),
        (r'^io_snapshots_(\d)_isCFI_(\d)$', r'snpt_o.snapshots[\1].isCFI[\2]'),
        (r'^io_(enqPtr|deqPtr)_(flag|value)$', r'snpt_o.\1.\2'),
    ],
    'pcMem': [
        (r'^io_rdata_(\d+)_startAddr$', r'pcmem_o.rdata_startAddr[\1]'),
    ],
    'renamePipeDispatch': [
        (r'^io_in_(\d)_ready$', r'pgc_o.in_ready[\1]'),
    ],
    'trace': [
        (r'^io_out_toEncoder_blocks_0_bits_tracePipe_itype$', 'trace_o.block0_itype'),
        (r'^io_out_toPcMem_blocks_(\d)_valid$', r'trace_o.toPcMem_valid[\1]'),
        (r'^io_out_toPcMem_blocks_(\d)_bits_ftqIdx_value$', r'trace_o.toPcMem_ftqIdx_value[\1]'),
    ],
    's5_flushFromRobValidAhead_delay': [(r'^io_out$', 'delay_o.s5_flushFromRobValidAhead')],
    's5_csrIsTrap_delay': [(r'^io_out$', 'delay_o.s5_csrIsTrap')],
}
for _k in range(DECODE_W):
    OUT_RULES['decodePipeRenameModule' + ('' if _k == 0 else '_%d' % _k)] = [
        (r'^io_out_valid$', 'pipe_o[%d].out_valid' % _k),
        (r'^io_in_ready$', 'pipe_o[%d].in_ready' % _k),
        (r'^io_out_bits_(ftqPtr_value|ftqOffset|isMove|fuType|fuOpType|srcType_1|lsrc_1|selImm|commitType|foldpc)$', r'pipe_o[%d].\1' % _k),
    ]

# 核输入 struct 里允许接常量 0 的叶子（golden 里这些字段在 NewDispatch 没有出口，寄存器装的是 0：见文件头 Q5）
TIE0_ALLOW = [
    r'^dispatch_o\.enqRob_req\[\d\]\.bits\.debugInfo_(dispatchTime|enqRsTime|selectTime|issueTime|writebackTime)$',
    r'^dispatch_o\.enqRob_req\[\d\]\.bits\.(lqIdx_value|sqIdx_value)$',
    r'^dispatch_o\.enqRob_req\[[1-5]\]\.bits\.snapshot$',
    r'^dispatch_o\.enqRob_req\[\d\]\.bits\.replayInst$',
    r'^dispatch_o\.enqRob_req\[\d\]\.bits\.exceptionVec\[\d+\]$',   # 不在 ENQ_EXC_KEEP 里的位
    r'^io_in\.wb\[\d+\]\.bits\..*$',                                 # 每口没有的字段（WB_LANE 描述表管它们）
    r'^io_in\.cfVec\[\d\]\.bits\.exceptionVec\[\d+\]$',             # 前端只带 1/2/12/20 四位异常
    r'^fusion_o\.clear\[0\]$',                                        # 第 0 路没有 clear 出口
]

CORE_PORTS = [
    ('input', 'cb_in_t', 'io_in'), ('output', 'cb_out_t', 'io_out'),
    ('input', 'rob_out_t', 'rob_o'), ('output', 'rob_in_t', 'rob_i'),
    ('input', 'redirectgen_out_t', 'redirectgen_o'), ('output', 'redirectgen_in_t', 'redirectgen_i'),
    ('input', 'dispatch_out_t', 'dispatch_o'), ('output', 'dispatch_in_t', 'dispatch_i'),
    ('input', 'decode_out_t', 'decode_o'), ('output', 'decode_in_t', 'decode_i'),
    ('input', 'pipe_out_t[6]', 'pipe_o'), ('output', 'logic', 'pipe_isFlush'),
    ('input', 'fusion_out_t', 'fusion_o'), ('output', 'fusion_in_t', 'fusion_i'),
    ('input', 'rename_out_t', 'rename_o'), ('output', 'rename_in_t', 'rename_i'),
    ('input', 'rat_out_t', 'rat_o'), ('output', 'rat_in_t', 'rat_i'),
    ('input', 'snpt_out_t', 'snpt_o'), ('output', 'snpt_in_t', 'snpt_i'),
    ('input', 'pcmem_out_t', 'pcmem_o'), ('output', 'pcmem_in_t', 'pcmem_i'),
    ('output', 'memctrl_in_t', 'memctrl_i'),
    ('input', 'pgc_out_t', 'pgc_o'), ('output', 'pgc_in_t', 'pgc_i'),
    ('input', 'delay_out_t', 'delay_o'), ('output', 'logic', 'delay_s5flush_in'),
    ('input', 'trace_out_t', 'trace_o'),
    ('input', 'logic[65][6]', 'perf_in'),
]


# ---------------------------------------------------------------------------
# WB_LANE 描述表
# ---------------------------------------------------------------------------
GROUPS = collections.OrderedDict([
    ('has_robidx_flag', ['robIdx_flag']),
    ('has_pdest', ['pdest']),
    ('has_intwen', ['intWen']), ('has_fpwen', ['fpWen']), ('has_vecwen', ['vecWen', 'v0Wen']),
    ('has_vlwen', ['vlWen']), ('has_vxsat', ['vxsat']),
    ('has_fflags', ['fflags', 'wflags']),
    ('has_redir_lite', ['redirect_valid', 'redirect_bits_cfiUpdate_taken', 'redirect_bits_cfiUpdate_isMisPred']),
    ('has_flushpipe', ['flushPipe']), ('has_satpflushpipe', ['satpFlushPipe']), ('has_replay', ['replay']),
    ('has_lqidx', ['lqIdx_flag', 'lqIdx_value']), ('has_sqidx', ['sqIdx_flag', 'sqIdx_value']),
    ('has_trigger', ['trigger']),
    ('has_predecode', ['predecodeInfo_valid', 'predecodeInfo_isRVC', 'predecodeInfo_brType', 'predecodeInfo_isCall', 'predecodeInfo_isRet']),
    ('has_perfcnt', ['debug_isPerfCnt']),
    ('has_dbgmem', ['debug_isMMIO', 'debug_isNCIO', 'debug_paddr', 'debug_vaddr']),
    ('has_dbglong', ['debugInfo_eliminatedMove', 'debugInfo_renameTime', 'debugInfo_dispatchTime',
                     'debugInfo_runahead_checkpoint_id', 'debugInfo_tlbFirstReqTime', 'debugInfo_tlbRespTime',
                     'debug_seqNum_seqNum', 'debug_seqNum_uopIdx']),
    ('has_vls', ['vls_' + x for x in ['isIndexed', 'isMasked', 'isStrided', 'isVecLoad', 'isVlm', 'isWhole', 'oldVdPsrc', 'vdIdx', 'vdIdxInField']]
              + ['vls_vpu_fpu_' + x for x in ['isFP32Instr', 'isFP64Instr', 'isFoldTo1_2', 'isFoldTo1_4', 'isFoldTo1_8', 'isFpToVecInst', 'isReduction']]
              + ['vls_vpu_' + x for x in ['frm', 'isDependOldVd', 'isDstMask', 'isExt', 'isMove', 'isNarrow', 'isOpMask', 'isReverse', 'isVleff',
                                          'isWritePartVd', 'lastUop', 'nf', 'specVill', 'specVlmul', 'specVma', 'specVsew', 'specVta', 'veew',
                                          'vill', 'vl', 'vlmul', 'vm', 'vma', 'vmask', 'vsew', 'vstart', 'vta', 'vuopIdx', 'vxrm']]),
])
BASE_FIELDS = ['robIdx_value', 'debugInfo_enqRsTime', 'debugInfo_selectTime', 'debugInfo_issueTime']


def lane_table(g):
    per = collections.defaultdict(dict)   # lane -> field -> width
    for n, w in g.regs.items():
        m = re.match(r'delayedNotFlushedWriteBack_delayed_bits_r(?:_(\d+))?_(.+)$', n)
        if m:
            per[int(m.group(1)) if m.group(1) else 0][m.group(2)] = w
    timers = [n for n in g.regs if n.startswith('delayedNotFlushedWriteBack_delayed_bits_debugInfo_writebackTime_c')]
    valid_regs = [n for n in g.regs if re.match(r'delayedNotFlushedWriteBack_delayed_valid_last_REG(_\d+)?$', n)]
    nums_regs = dict((int(m.group(1)) if m.group(1) else 0, w) for n, w in g.regs.items()
                     for m in [re.match(r'delayedNotFlushedWriteBackNums_delayed_bits_r(?:_(\d+))?$', n)] if m)
    # has_valid：Rob 消费的 io_writeback_N_valid
    has_valid = set(int(m.group(1)) for (inst, pin) in g.pins for m in [re.match(r'io_writeback_(\d+)_valid$', pin)] if inst == 'rob' and m)
    if len(has_valid) != len(valid_regs):
        die('writeback valid 寄存器数 %d 与 Rob 消费口数 %d 不符' % (len(valid_regs), len(has_valid)))
    need_exc = set()
    for (inst, pin), e in g.pins.items():
        if inst == 'rob' and pin.startswith('io_writebackNeedFlush_'):
            lanes = set(int(x) for x in re.findall(r'delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_', e))
            if len(lanes) != 1:
                die('writebackNeedFlush %s 的 lane 不唯一: %s' % (pin, lanes))
            need_exc |= lanes
    csr_lanes = set(int(m.group(1)) for n in g.port_w for m in [re.match(r'io_fromWB_wbData_(\d+)_bits_redirect_bits_cfiUpdate_backendIAF$', n)] if m)
    exu_lanes = sorted(l for l in per if 'redirect_valid' in per[l])
    table = []
    for lane in range(WB_N):
        f = per[lane]
        used = set()
        row = collections.OrderedDict()
        dw = []
        for k in range(6):
            key = 'data_%d' % k
            dw.append(f.get(key, 0))
            used.add(key)
        row['data_w'] = dw
        base = [x in f for x in BASE_FIELDS]
        if all(base):
            row['has_base'] = 1
            used |= set(BASE_FIELDS)
        elif base == [True, False, False, False]:
            row['has_base'] = 0
            used.add('robIdx_value')
        else:
            die('lane %d 基本字段不完整: %s' % (lane, base))
        for gname, fields in GROUPS.items():
            pres = [x in f for x in fields]
            if all(pres):
                row[gname] = 1
                used |= set(fields)
            elif not any(pres):
                row[gname] = 0
            else:
                die('lane %d 字段组 %s 半保留: %s' % (lane, gname, list(zip(fields, pres))))
        # redirect 其余字段（只 CSR 口）
        rfull = [x for x in f if x.startswith('redirect_bits_') and x not in GROUPS['has_redir_lite']]
        row['has_redir_full'] = 1 if rfull else 0
        used |= set(rfull)
        mask = 0
        for x in f:
            m = re.match(r'exceptionVec_(\d+)$', x)
            if m:
                mask |= 1 << int(m.group(1))
                used.add(x)
        row['exc_mask'] = mask
        row['need_exc_gen'] = 1 if lane in need_exc else 0
        row['has_valid'] = 1 if lane in has_valid else 0
        row['has_csr'] = 1 if lane in csr_lanes else 0
        grp = g.nums_group.get(lane, set())
        gm = 0
        for x in grp:
            gm |= 1 << x
        row['same_group'] = gm
        nw = nums_regs.get(lane, 0)
        if grp:
            exp = max(1, (len(grp) + 1).bit_length() - 1 + (0 if ((len(grp) + 1) & (len(grp))) == 0 else 1))
            # log2Ceil(n+1)
            exp = 0
            while (1 << exp) < len(grp) + 1:
                exp += 1
            if exp != nw:
                die('lane %d writebackNums 位宽 golden=%d 模型=%d (组 %s)' % (lane, nw, exp, sorted(grp)))
        elif nw:
            die('lane %d 有 writebackNums 寄存器却没有同组集合' % lane)
        row['nums_w'] = nw
        left = set(f) - used
        if left:
            die('lane %d 有未归类的 golden 寄存器字段: %s' % (lane, sorted(left)))
        if row['has_redir_full'] and not row['has_csr']:
            die('lane %d 有完整 redirect 却不是 CSR 口' % lane)
        table.append(row)
    if len(timers) != sum(1 for r in table if r['has_base']):
        die('writebackTime 计数器数 %d != has_base 口数' % len(timers))
    return table, exu_lanes, csr_lanes


def fmt_lane_table(table, exu_lanes, csr_lanes):
    out = []
    out.append('  // 27 路写回口各自保留了哪些字段：从 golden 的 delayedNotFlushedWriteBack_* 寄存器表核出，')
    out.append('  // 每口一行；data_w 六段各自的寄存器位宽，exc_mask 是 exceptionVec 保留位，')
    out.append('  // same_group 是 writebackNums 可同 robIdx 计数的口集合（27 位掩码）。')
    out.append('  localparam int EXU_REDIR_LANE [EXU_REDIR_N] = \'{%s};   // 带 redirect 的写回口' % ', '.join(str(x) for x in exu_lanes))
    oh = 0
    for j, l in enumerate(exu_lanes):
        if l in csr_lanes:
            oh |= 1 << j
    out.append("  localparam logic [EXU_REDIR_N-1:0] EXU_REDIR_CSR_OH = %d'b%s;   // 其中哪一个是 CSR 口" % (len(exu_lanes), format(oh, '0%db' % len(exu_lanes))))
    out.append('  localparam wb_lane_shape_t WB_LANE [WB_N] = \'{')
    keys = ['has_base'] + list(GROUPS.keys()) + ['has_redir_full']
    for lane, r in enumerate(table):
        flags = ', '.join('%s:1\'b%d' % (k, r[k]) for k in keys)
        line = ("    '{data_w:{%s}, %s, exc_mask:24'h%06X, need_exc_gen:1'b%d, has_valid:1'b%d, has_csr:1'b%d, "
                "same_group:27'h%07X, nums_w:4'd%d}%s   // lane %d") % (
            ', '.join("8'd%d" % w for w in reversed(r['data_w'])), flags, r['exc_mask'], r['need_exc_gen'],
            r['has_valid'], r['has_csr'], r['same_group'], r['nums_w'], ',' if lane != WB_N - 1 else '', lane)
        out.append(line)
    out.append('  };')
    return '\n'.join(out)


# ---------------------------------------------------------------------------
# wrapper 生成
# ---------------------------------------------------------------------------
def apply_rules(rules, pin):
    for a, b in rules:
        if re.match(a, pin):
            return re.sub(a, b, pin)
    return None


class Gen(object):
    def __init__(self, g, ty):
        self.g = g
        self.ty = ty
        self.stats = collections.Counter()
        self.warn_direct_with_rule = []
        self.core_in_driven = {}      # leaf path -> source expr
        self.bits_driven = {}         # vector leaf -> 已驱动的位集合
        self.tie0 = []

    def core_type(self, name):
        for d, t, n in CORE_PORTS:
            if n == name:
                return t
        die('核端口 %s 不存在' % name)

    def resolve_path(self, spec):
        """'base|T:type|rest' 或纯路径 → (expr, width or None)"""
        if '|T:' in spec:
            base, t, rest = spec.split('|')
            t = t[2:]
            r = self.ty.resolve(t, [], canon(rest))
            if r is None:
                die('无法在 %s 里解析 %r（来自 %s）' % (t, rest, spec))
            return base + r[0], r[1]
        return spec, None

    def leaf_width_of(self, path):
        """核端口叶子的位宽（用于对 golden 表达式做切片）。"""
        m = re.match(r'^(\w+)(.*)$', path)
        port = m.group(1)
        t = self.core_type(port)
        rest = m.group(2)
        dims = []
        mm = re.match(r'^(\w+)\[(\d+)\]$', t)
        if mm:
            t, dims = mm.group(1), [int(mm.group(2))]
        if t == 'logic':
            return 1
        if t.startswith('logic['):
            return 6
        # 走一遍 leaves 找
        for p, w in self.ty.leaves(t, dims, port):
            if p == path:
                return w
        # 可能是 struct 级路径（整个子 struct）：用 resolve 反推不易，返回 None
        return None

    # ---- child 引脚 ----
    def pin_expr(self, inst, pin, e):
        g = self.g
        if e in ('clock', 'reset'):
            self.stats['clk'] += 1
            return e
        rule = apply_rules(IN_RULES.get(inst, []), pin)
        is_plain = (e in g.port_w) or g.is_child_wire(e)
        if rule is not None:
            if is_plain:
                self.warn_direct_with_rule.append('%s.%s <= %s' % (inst, pin, e))
            self.stats['core'] += 1
            if rule == 'NEEDFLUSH':
                lanes = set(int(x) for x in re.findall(r'delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_', e))
                return 'rob_i.writebackNeedFlush[%d]' % lanes.pop()
            path, w = self.resolve_path(rule)
            # golden 表达式是寄存器且核叶子更宽（data_0 128→64）：切片
            if e in g.regs and w is not None and w > g.regs[e]:
                path = '%s[%d:0]' % (path, g.regs[e] - 1)
            return path
        if e == '/* unused */':
            self.stats['unused'] += 1
            return e
        if e in g.port_w:
            self.stats['top_port'] += 1
            return e
        if g.is_child_wire(e):
            self.stats['child_wire'] += 1
            return e[1:]
        # 纯连线表达式（切片/零扩展/拼接）：只含 child wire / 顶层端口 / 常量
        idents = set(re.findall(r'[A-Za-z_]\w*', e))
        bad = [x for x in idents if not (x in g.port_w or g.is_child_wire(x) or re.match(r'^\d*$', x) or x[0] == 'h' and re.match(r'^h[0-9a-fA-F]+$', x))]
        if not bad:
            self.stats['wiring_expr'] += 1
            return re.sub(r'\b(_\w+)\b', lambda m: m.group(1)[1:] if g.is_child_wire(m.group(1)) else m.group(1), e)
        die('child 引脚 %s.%s 的表达式没有规则覆盖: %s' % (inst, pin, e[:120]))

    def drive_core_in(self, path, src):
        if path in self.core_in_driven:
            die('核输入叶子 %s 被驱动两次（%s / %s）' % (path, self.core_in_driven[path], src))
        self.core_in_driven[path] = src
        m = re.match(r'^(.*)\[(\d+)\]$', path)
        if m:
            self.bits_driven.setdefault(m.group(1), set()).add(int(m.group(2)))

    def cover_leaves(self, leaves, L):
        """叶子全覆盖：整体被驱动 → ok；向量部分位被驱动 → 其余位接 0；都没有 → 整体接 0。接 0 必须在 TIE0_ALLOW 里。"""
        for p, w in leaves:
            if p in self.core_in_driven:
                continue
            if p in self.bits_driven:
                for b in range(w):
                    if b not in self.bits_driven[p]:
                        pb = '%s[%d]' % (p, b)
                        if not any(re.match(a, pb) for a in TIE0_ALLOW):
                            die('叶子位 %s 没有来源且不在 TIE0_ALLOW' % pb)
                        self.tie0.append(pb)
                        L.append("  assign %s = 1'b0;" % pb)
                continue
            if not any(re.match(a, p) for a in TIE0_ALLOW):
                die('叶子 %s 没有来源且不在 TIE0_ALLOW' % p)
            self.tie0.append(p)
            L.append("  assign %s = '0;" % p)

    def build(self):
        g, ty = self.g, self.ty
        L = []
        # ---- 端口 ----
        ports = []
        for d, w, n in g.ports:
            ww = '' if w == 1 else '[%d:0] ' % (w - 1)
            ports.append('  %-6s %s%s' % (d, ww, n))
        port_text = ',\n'.join(ports)

        # ---- child 出口 wire ----
        L.append('  // ---- child 出口线（名字 = golden 的 _<实例>_<引脚> 去掉前导下划线） ----')
        for n in sorted(g.wire_w, key=lambda x: list(g.wire_w).index(x)):
            w = g.wire_w[n]
            L.append('  logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), n[1:]))
        # ---- 核端口线 ----
        L.append('')
        L.append('  // ---- 可读核的 struct 端口 ----')
        for d, t, n in CORE_PORTS:
            mm = re.match(r'^(\w+)\[(\d+)\]$', t)
            if t.startswith('logic['):
                L.append('  logic [PERF_N-1:0][5:0] %s;' % n)
            elif mm:
                L.append('  %s %s [%s];' % (mm.group(1), n, mm.group(2)))
            else:
                L.append('  %s %s;' % (t, n))

        # ---- 顶层输入 → io_in ----
        L.append('')
        L.append('  // ---- 顶层输入装进 io_in（核没消费的输入不在 cb_in_t 里，直接接 child） ----')
        in_leaves = ty.leaves('cb_in_t', [], 'io_in')
        leaf_set = dict(in_leaves)
        used_in = set()
        for d, w, n in g.ports:
            if d != 'input':
                continue
            flat = map_prefix(IN_PREFIX, n)
            if flat is None:
                continue
            r = ty.resolve('cb_in_t', [], canon(flat))
            if r is None:
                die('顶层输入 %s → %s 在 cb_in_t 里解析不到' % (n, flat))
            path = 'io_in' + r[0]
            src = n
            if r[1] != w:
                if r[1] > w and n.endswith('_pdest') or re.search(r'_data_\d$', n):
                    src = "%d'(%s)" % (r[1], n)   # pdest 7→8、data 128 位口位宽一致时不会走到这里
                else:
                    die('顶层输入 %s 位宽 %d 与 %s 位宽 %d 不符' % (n, w, path, r[1]))
            self.drive_core_in(path, src)
            L.append('  assign %s = %s;' % (path, src))
            used_in.add(path)
        # 没被顶层输入驱动的 io_in 叶子 → 0（只许是每口没有的写回字段、前端不带的异常位）
        self.cover_leaves(in_leaves, L)
        # 核是否消费了它没拿到的顶层输入？（glue 文本里出现的输入端口都得有映射）
        glue_ids = set(re.findall(r'\b(io_\w+)\b', g.glue_text))
        for d, w, n in g.ports:
            if d == 'input' and n in glue_ids and map_prefix(IN_PREFIX, n) is None:
                die('golden glue 用到了顶层输入 %s，但 IN_PREFIX 没有映射' % n)

        # ---- child 出口 → 核输入 ----
        L.append('')
        L.append('  // ---- child 出口装进核的输入 struct ----')
        for inst, pin, e in g.child_output_pins():
            rule = apply_rules(OUT_RULES.get(inst, []), pin)
            if rule is None:
                continue
            path, w = self.resolve_path(rule)
            if e == '/* unused */':
                die('child 出口 %s.%s 核要用但 golden 标 unused' % (inst, pin))
            src = e[1:] if g.is_child_wire(e) else e
            self.drive_core_in(path, src)
            L.append('  assign %s = %s;' % (path, src))
        # perf
        perf_idx = sorted(g.perf_src)
        if len(perf_idx) != 65:
            die('perf 口数 %d != 65' % len(perf_idx))
        for k, n in enumerate(perf_idx):
            L.append('  assign perf_in[%d] = %s;   // io_perf_%d' % (k, g.perf_src[n][1:], n))
        # 核输入叶子全覆盖检查
        for d, t, n in CORE_PORTS:
            if d != 'input' or n in ('io_in', 'perf_in'):
                continue
            mm = re.match(r'^(\w+)\[(\d+)\]$', t)
            dims = [int(mm.group(2))] if mm else []
            tt = mm.group(1) if mm else t
            self.cover_leaves(ty.leaves(tt, dims, n), L)

        # ---- child 实例 ----
        L.append('')
        L.append('  // ---- 22 个 child 实例（引脚连线：顶层端口直连 / child 之间直连 / 核端口） ----')
        for typ, inst in g.insts:
            L.append('  %s %s (' % (typ, inst))
            conns = []
            for (i2, pin), e in g.pins.items():
                if i2 != inst:
                    continue
                conns.append('    .%s(%s)' % (pin, self.pin_expr(inst, pin, e)))
            L.append(',\n'.join(conns))
            L.append('  );')

        # ---- 核实例 ----
        L.append('')
        L.append('  xs_CtrlBlock_core u_core (')
        cl = ['    .clock(clock)', '    .reset(reset)']
        for d, t, n in CORE_PORTS:
            cl.append('    .%s(%s)' % (n, n))
        L.append(',\n'.join(cl))
        L.append('  );')

        # ---- 顶层输出 ----
        L.append('')
        L.append('  // ---- 由核驱动的顶层输出（golden 尾部 assign 的对应物） ----')
        driven_direct = set()
        for (inst, pin), e in g.pins.items():
            if e in g.port_dir and g.port_dir[e] == 'output':
                driven_direct.add(e)
        perf_pos = dict((n, k) for k, n in enumerate(perf_idx))
        for d, w, n in g.ports:
            if d != 'output':
                continue
            if n in driven_direct:
                if n in g.tail_assign:
                    die('顶层输出 %s 既被 child 直连又有 assign' % n)
                continue
            if n not in g.tail_assign:
                die('顶层输出 %s 没有驱动' % n)
            if n in g.passthrough:
                r_ = g.passthrough[n]
                L.append('  assign %s = %s;' % (n, r_[1:] if r_ in g.wire_w else r_))
                continue
            mp = re.match(r'^io_perf_(\d+)_value$', n)
            if mp:
                L.append('  assign %s = io_out.perf[%d];' % (n, perf_pos[int(mp.group(1))]))
                continue
            flat = map_prefix(OUT_PREFIX, n)
            if flat is None:
                die('顶层输出 %s（golden: %s）没有 OUT_PREFIX 映射' % (n, g.tail_assign[n][:80]))
            r = ty.resolve('cb_out_t', [], canon(flat))
            if r is None:
                die('顶层输出 %s → %s 在 cb_out_t 里解析不到' % (n, flat))
            if r[1] != w:
                die('顶层输出 %s 位宽 %d 与 io_out%s 位宽 %d 不符' % (n, w, r[0], r[1]))
            L.append('  assign %s = io_out%s;' % (n, r[0]))
        body_text = '\n'.join(L)
        return port_text, body_text


def splice(text, tag, new):
    b = '  // BEGIN GENERATED(%s)\n' % tag
    e = '  // END GENERATED'
    i = text.index(b) + len(b)
    j = text.index(e, i)
    return text[:i] + new + '\n' + text[j:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--report', action='store_true')
    args = ap.parse_args()
    g = Golden(GOLDEN.read_text())
    cur = RTL.read_text()
    ty = Types(cur)
    table, exu_lanes, csr_lanes = lane_table(g)
    lane_text = fmt_lane_table(table, exu_lanes, csr_lanes)
    gen = Gen(g, ty)
    port_text, body_text = gen.build()
    new = splice(cur, 'wb_lane_table', lane_text)
    new = splice(new, 'wrapper_ports', port_text)
    new = splice(new, 'wrapper_body', body_text)
    if args.report or args.check:
        print('pins: %s' % dict(gen.stats))
        print('tie0 leaves: %d' % len(gen.tie0))
        if gen.warn_direct_with_rule:
            print('pins with rule but golden is a plain wire (core must reproduce): %d' % len(gen.warn_direct_with_rule))
            for x in gen.warn_direct_with_rule[:40]:
                print('   ', x)
    if args.check:
        if new != cur:
            print('gen_ctrlblock --check: 生成物与文件不一致（漂移）')
            return 1
        print('gen_ctrlblock --check: OK')
        return 0
    if new != cur:
        RTL.write_text(new)
        print('gen_ctrlblock: 写入 %s（%d 行）' % (RTL, new.count('\n')))
    else:
        print('gen_ctrlblock: 无变化')
    return 0


if __name__ == '__main__':
    sys.exit(main())
