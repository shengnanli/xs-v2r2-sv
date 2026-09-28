#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_datapath.py —— DataPath 的配置表、golden 同名 wrapper、FM 钉点与 UT tb。

核（xs_DataPath_core）是手写的，在 rtl/backend/DataPath.sv；本脚本只产出机械派生的部分：
  1. `// BEGIN GENERATED(dp_tables)`：27 个 EXU 的配置表（package 里的 localparam）；
  2. `// BEGIN GENERATED(dp_wrapper)`：golden 同名 wrapper —— 2,426 个端口逐行照抄 golden，
     62 个子模块按 golden 的类型/实例名例化，端口字段拼进/拆出核的数组；
  3. verif/ut/DataPath/fm_pins_pre.tcl：golden 顶层寄存器（1,111 个）逐位钉到核里的数组元素；
  4. verif/ut/DataPath/tb.sv：golden vs 重写件双例化 UT。

★所有表都从 golden **实测**并交叉断言★：golden 里每个顶层寄存器、每个子模块端口连接、每个
输出端口的驱动表达式，都必须被某一条已知形状解释；有一条解释不了就退出（fail-closed）——
这样 golden 里若还有本脚本没见过的逻辑，会在生成时就暴露，而不是在 FM 里变成一个谜。

用法: python3 scripts/gen_datapath.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（gate_all.sh 的幂等闸）。
"""
import argparse
import os
import pathlib
import re
import sys
from collections import OrderedDict

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))
RTL = REPO / 'rtl' / 'backend' / 'DataPath.sv'
UT = REPO / 'verif' / 'ut' / 'DataPath'

KINDS = ['Int', 'Fp', 'Vf', 'Mem']            # fromIQ 的拼接顺序（DataPath.scala: fromIntIQ ++ fromFpIQ ++ fromVfIQ ++ fromMemIQ）
RFS = ['int', 'fp', 'vf', 'v0', 'vl']          # 与 datapath_pkg 的 RF_INT..RF_VL 同序
RF_CAP = {'int': 'Int', 'fp': 'Fp', 'vf': 'Vf', 'v0': 'V0', 'vl': 'Vl'}
WEN_FIELD = {'int': 'rfWen', 'fp': 'fpWen', 'vf': 'vecWen', 'v0': 'v0Wen', 'vl': 'vlWen'}
RF_AW = {'int': 8, 'fp': 8, 'vf': 7, 'v0': 5, 'vl': 5}
RF_DW = {'int': 64, 'fp': 64, 'vf': 128, 'v0': 128, 'vl': 8}
RF_RD = {'int': 11, 'fp': 11, 'vf': 12, 'v0': 4, 'vl': 4}
RF_WR = {'int': 8, 'fp': 6, 'vf': 6, 'v0': 6, 'vl': 4}
RF_PARTS = {'int': 4, 'fp': 4, 'vf': 4, 'v0': 2, 'vl': 1}
MAX_SRC = 5
NUM_LDU = 3
# 向量异常模块借用的读写口（DataPath.scala: vecExcpUseVecRdPorts / VecWrPorts / V0RdPorts / v0WrPorts），生成时对照 golden 断言
EXCP_R_VF_PORT = [6, 7, 8, 9, 10, 11, 0, 1]
EXCP_R_V0_PORT = [2, 3]
EXCP_W_VF_PORT = [1, 4, 5, 3]
EXCP_W_V0_PORT = 4


def die(msg):
    sys.exit(f'gen_datapath: {msg}')


def norm(s):
    return ' '.join(s.split())


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
class Golden:
    def __init__(self):
        txt = (GOLDEN / 'DataPath.sv').read_text()
        m = re.search(r'^module DataPath\(\n(.*?)\n\);\n(.*?)^endmodule', txt, re.S | re.M)
        if not m:
            die('找不到 golden DataPath')
        self.port_lines = m.group(1).split('\n')
        self.ports = []
        for ln in self.port_lines:
            pm = re.match(r'^\s+(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', ln)
            if not pm:
                die(f'端口行不认识 {ln!r}')
            self.ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        self.pw = {n: w for d, w, n in self.ports}
        self.pd = {n: d for d, w, n in self.ports}
        body = re.sub(r'^[ ]*`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '', m.group(2), flags=re.S | re.M)
        body = re.sub(r'^[ ]*`ifndef SYNTHESIS.*?`endif // not def SYNTHESIS\n', '', body, flags=re.S | re.M)
        self.body = body
        self.defs = {}
        self.wires = {}
        for wm in re.finditer(r'^  wire\s+(\[[^\]]+\](?:\[[^\]]+\])?)?\s*(\w+)(?:\s*=\s*(.*?))?;\n', body, re.M | re.S):
            self.wires[wm.group(2)] = wm.group(1) or ''
            if wm.group(3) is not None:
                self.defs[wm.group(2)] = norm(wm.group(3))
        for am in re.finditer(r'^  assign (\w+) =\s*(.*?);\n', body, re.M | re.S):
            if am.group(1) in self.defs:
                die(f'{am.group(1)} 被定义两次')
            self.defs[am.group(1)] = norm(am.group(2))
        self.regs = OrderedDict()
        for rm in re.finditer(r'^  reg\s+(?:\[(\d+):0\])?\s*(\w+);', body, re.M):
            self.regs[rm.group(2)] = int(rm.group(1)) + 1 if rm.group(1) else 1
        self.insts = []
        for im in re.finditer(r'^  (\w+) (\w+) \(\n(.*?)\n  \);\n', body, re.M | re.S):
            conns = OrderedDict()
            for cm in re.finditer(r'\.(\w+)\s*\((.*?)\)\s*(?:,\s*$|$)', im.group(3), re.M | re.S):
                conns[cm.group(1)] = norm(cm.group(2))
            self.insts.append((im.group(1), im.group(2), conns))
        self.inst_by_name = {n: (t, c) for t, n, c in self.insts}
        self.assign = {}   # reg -> [(conds, rhs)]
        for sens, blk in re.findall(r'^  always @\((.*?)\) begin\n(.*?)^  end // always', body, re.M | re.S):
            for reg, lst in parse_always(blk).items():
                self.assign.setdefault(reg, []).extend((sens, c, e) for c, e in lst)
        if set(self.assign) != set(self.regs):
            die(f'always 里赋值的寄存器集合与声明不符: {set(self.regs) ^ set(self.assign)}')


def parse_always(text):
    """firtool 的 always 体 → {reg: [(conds, rhs)]}；conds 为自外向内的条件（'!(c)' 表示 else 分支）。"""
    res = {}
    toks = []
    buf = ''
    for ln in text.split('\n'):
        s = ln.strip()
        if not s:
            continue
        buf = (buf + ' ' + s) if buf else s
        if buf.startswith('if') or buf.startswith('else if'):
            i0 = buf.index('(')
            depth = 0
            end = None
            for i, ch in enumerate(buf[i0:], i0):
                if ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                    if depth == 0:
                        end = i
                        break
            if end is None:
                continue
            rest = buf[end + 1:].strip()
            if rest == '' or rest.startswith('begin') or rest.endswith(';'):
                toks.append(buf)
                buf = ''
            continue
        if buf in ('begin', 'end', 'else', 'else begin') or buf.startswith('end ') or buf.endswith(';'):
            toks.append(buf)
            buf = ''
    if buf:
        die(f'always 体尾部残留 {buf!r}')

    def cond_of(t):
        s = t[t.index('('):]
        depth = 0
        for j, ch in enumerate(s):
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return norm(s[1:j]), s[j + 1:].strip()
        die(f'条件不闭合 {t!r}')

    ctx = []
    blk = []
    oneshot = []
    prev = None
    for t in toks:
        if t == 'end' or t.startswith('end '):
            n = blk.pop()
            for _ in range(n):
                ctx.pop()
            continue
        if t.startswith('if') or t.startswith('else if'):
            c, rest = cond_of(t)
            conds = (['!(' + prev + ')'] if t.startswith('else') else []) + oneshot + [c]
            oneshot = []
            prev = c
            if rest.startswith('begin'):
                ctx.extend(conds)
                blk.append(len(conds))
            elif rest.endswith(';'):
                m = re.match(r'(\w+)\s*<=\s*(.*);$', rest)
                res.setdefault(m.group(1), []).append((list(ctx) + conds, norm(m.group(2))))
            else:
                oneshot = conds
            continue
        if t == 'else begin':
            ctx.append('!(' + prev + ')')
            blk.append(1)
            continue
        if t == 'else':
            oneshot = ['!(' + prev + ')']
            continue
        if t == 'begin':
            blk.append(0)
            continue
        m = re.match(r'(\w+)\s*<=\s*(.*);$', t)
        if not m:
            die(f'always 语句不认识 {t!r}')
        res.setdefault(m.group(1), []).append((list(ctx) + oneshot, norm(m.group(2))))
        oneshot = []
    return res


# ---------------------------------------------------------------------------
# EXU 模型
# ---------------------------------------------------------------------------
class Exu:
    def __init__(self, g, e, kind, i, j, gi):
        self.e, self.kind, self.i, self.j, self.g = e, kind, i, j, gi
        self.frm = f'io_from{kind}IQ_{i}_{j}_'
        self.toexu = f'io_to{"Vec" if kind == "Vf" else kind}Exu_{i}_{j}_'
        self.toiq = f'io_to{kind}IQ_{i}_{j}_'
        self.key = f'{gi}_{j}'          # golden 里 s1_toExuData_<g>_<j> / 仲裁器 io_in_<g>_<j> 的下标
        self.nsrc = len([n for d, w, n in g.ports if re.fullmatch(self.frm + r'bits_common_dataSources_\d+_value', n)])


def build_model(g):
    exus = []
    gi = 0
    for kind in KINDS:
        iqs = sorted({int(a) for a in re.findall(r'io_from%sIQ_(\d+)_\d+_' % kind, '\n'.join(n for _, _, n in g.ports))})
        for i in iqs:
            js = sorted({int(b) for b in re.findall(r'io_from%sIQ_%d_(\d+)_' % (kind, i), '\n'.join(n for _, _, n in g.ports))})
            for j in js:
                exus.append(Exu(g, len(exus), kind, i, j, gi))
            gi += 1
    if len(exus) != 27:
        die(f'EXU 数 {len(exus)} != 27')
    M = {'exus': exus}
    bykey = {x.key: x for x in exus}
    M['bykey'] = bykey
    used_defs = set()     # 被某条已知形状解释掉的 golden 定义
    M['used_defs'] = used_defs

    # ---- 读口仲裁器：RD_REQ / 地址来源 ----
    rd_req = {}     # (e,k,rf) -> addr port
    rd_ready_wire = {}
    for rf in RFS:
        inst = f'{rf}RFReadArbiter'
        typ, conns = g.inst_by_name[inst]
        if typ != f'{RF_CAP[rf]}RFReadArbiter':
            die(f'{inst} 类型 {typ}')
        for p, s in conns.items():
            m = re.fullmatch(r'io_in_(\d+)_(\d+)_(\d+)_(valid|bits_addr|ready)', p)
            if not m:
                continue
            x = bykey[f'{m.group(1)}_{m.group(2)}']
            k = int(m.group(3))
            if k >= x.nsrc:
                die(f'{inst}.{p}: 源号超出 EXU {x.e} 的源数 {x.nsrc}')
            if m.group(4) == 'valid':
                if s == "1'h0":
                    continue
                exp = f'{x.frm}valid & {x.frm}bits_common_dataSources_{k}_value[3]'
                if s != exp and g.defs.get(s) != exp:
                    die(f'{inst}.{p} = {s} = {g.defs.get(s)}，期望 {exp}')
                used_defs.add(s)
                a = conns[f'io_in_{m.group(1)}_{m.group(2)}_{k}_bits_addr']
                a = re.sub(r'\[%d:0\]$' % (RF_AW[rf] - 1), '', a)   # 端口比该堆地址宽时 golden 截低位
                if not re.fullmatch(x.frm + rf'bits_rf_{k}_\d+_addr', a):
                    die(f'{inst}.{p}: 地址 {a} 不是本源的 rf 地址端口')
                rd_req[(x.e, k, rf)] = a
            elif m.group(4) == 'bits_addr':
                v = conns[f'io_in_{m.group(1)}_{m.group(2)}_{k}_valid']
                if v == "1'h0" and s != f"{RF_AW[rf]}'h0":
                    die(f'{inst}.{p}: valid=0 但地址不是 0')
            else:
                rd_ready_wire[(x.e, k, rf)] = s
        outs = sorted(int(a) for a in re.findall(r'io_out_(\d+)_bits_addr', ' '.join(conns)))
        if outs != list(range(RF_RD[rf])):
            die(f'{inst} 输出口数 {len(outs)} != {RF_RD[rf]}')
    M['rd_req'] = rd_req
    M['rd_ready_wire'] = rd_ready_wire

    # ---- 写口撞口检查器：WB_REQ ----
    wb_req = {}
    for rf in RFS:
        inst = f'{rf}WbBusyArbiter'
        typ, conns = g.inst_by_name[inst]
        if typ != f'{RF_CAP[rf]}RFWBCollideChecker':
            die(f'{inst} 类型 {typ}')
        for p, s in conns.items():
            m = re.fullmatch(r'io_in_(\d+)_(\d+)_valid', p)
            if not m or s == "1'h0":
                continue
            x = bykey[f'{m.group(1)}_{m.group(2)}']
            exp = f'{x.frm}valid & {x.frm}bits_common_{WEN_FIELD[rf]}'
            if s != exp and g.defs.get(s) != exp:
                die(f'{inst}.{p} = {s}，期望 {exp}')
            used_defs.add(s)
            wb_req[(x.e, rf)] = f'{x.frm}bits_common_{WEN_FIELD[rf]}'
    M['wb_req'] = wb_req

    # ---- UIntExtractor：唤醒源编号 → 全局 EXU 独热 ----
    ext = {}   # (e,k) -> (inst name, type, in width)
    for typ, name, conns in g.insts:
        if not typ.startswith('UIntExtractor_27_'):
            continue
        m = re.fullmatch(r'(_exuOHNoLoad_encodedExuOH_T(?:_\d+)?)\[(\d+):1\]', conns['io_in'])
        if not m:
            die(f'{name}.io_in 形状 {conns["io_in"]}')
        src = g.defs[m.group(1)]
        sm = re.fullmatch(r"(\d+)'h1 << (io_from\w+IQ_\d+_\d+_)bits_common_exuSources_(\d+)_value", src)
        if not sm:
            die(f'{m.group(1)} = {src}')
        x = next(x for x in exus if x.frm == sm.group(2))
        if int(m.group(2)) != int(sm.group(1)) - 1:
            die(f'{name}: 截位 [{m.group(2)}:1] 与移位宽度 {sm.group(1)} 不符')
        used_defs.add(m.group(1))
        if conns['io_out'] != f'_{name}_io_out':
            die(f'{name}.io_out 接到 {conns["io_out"]}')
        ext[(x.e, int(sm.group(3)))] = (name, typ, int(m.group(2)))
    if len(ext) != 36:
        die(f'UIntExtractor 实例数 {len(ext)} != 36')
    M['ext'] = ext

    # ---- 非载入 EXU 表与 0 拍 FU 掩码 ----
    noload = []
    for i in range(64):
        d = g.defs.get(f'og0_cancel_no_load_{i}')
        if d is None:
            break
        m = re.fullmatch(r'(io_from\w+IQ_\d+_\d+_)valid & ~(\w+)', d)
        x = next(x for x in exus if x.frm == m.group(1))
        noload.append(x.e)
        used_defs.add(f'og0_cancel_no_load_{i}')
        z = g.defs[f'is_0latency_{i}']
        bits = sorted(int(b) for b in re.findall(re.escape(x.frm) + r'bits_common_fuType\[(\d+)\]', z))
        if norm(' | '.join(f'{x.frm}bits_common_fuType[{b}]' for b in re.findall(r'fuType\[(\d+)\]', z))) != z:
            die(f'is_0latency_{i} 形状 {z}')
        M.setdefault('zlat_bits', bits)
        if M['zlat_bits'] != bits:
            die('各 EXU 的 0 拍 FU 掩码不一致')
        used_defs.add(f'is_0latency_{i}')
    M['noload'] = noload
    if len(noload) != 24:
        die(f'非载入 EXU 数 {len(noload)} != 24')

    # ---- s1 寄存器：valid / payload / imm / srcType ----
    payload = {x.e: [] for x in exus}       # e -> [(reg, width, src_expr, kind)]
    imm, immtype, srctype = [], [], []
    has_lddep = {}
    for reg, w in g.regs.items():
        asg = g.assign[reg]
        m = re.fullmatch(r's1_toExuData_(\d+_\d+)_(\w+)', reg)
        if m:
            x = bykey[m.group(1)]
            if len(asg) != 1 or asg[0][1] != [f'{x.frm}valid'] or asg[0][0] != 'posedge clock':
                die(f'{reg} 的更新条件不是 s0.valid: {asg}')
            rhs = asg[0][2]
            field = m.group(2)
            src = f'{x.frm}bits_common_{field}'
            if rhs == src:
                if g.pw[src] != w:
                    die(f'{reg} 宽 {w} != 端口 {src} 宽 {g.pw[src]}')
                payload[x.e].append((reg, w, src, 'copy'))
            elif rhs == f"{{{src}[0], 1'h0}}" and field.startswith('loadDependency_'):
                payload[x.e].append((reg, w, src, 'ldshift'))
            elif rhs == f'{src}[{w - 1}:0]':
                payload[x.e].append((reg, w, src, 'low'))
            else:
                die(f'{reg} <= {rhs}（形状不认识）')
            continue
        m = re.fullmatch(r's1_immInfo_(\d+_\d+)_(imm|immType)', reg)
        if m:
            x = bykey[m.group(1)]
            if m.group(2) == 'imm':
                exp = f'{x.frm}valid ? {x.frm}bits_common_imm[31:0] : {reg}'
                if len(asg) != 1 or asg[0][1] or asg[0][2] != exp:
                    die(f'{reg}: {asg}')
                imm.append(x.e)
            else:
                if len(asg) != 1 or asg[0][1] != [f'{x.frm}valid'] or asg[0][2] != f'{x.frm}bits_immType':
                    die(f'{reg}: {asg}')
                immtype.append(x.e)
            continue
        m = re.fullmatch(r's1_srcType_r_(\d+)_(\d+)', reg)
        if m:
            x = exus[int(m.group(1))]
            k = int(m.group(2))
            if len(asg) != 1 or asg[0][1] != [f'fromIQFire_{x.key}'] or asg[0][2] != f'{x.frm}bits_srcType_{k}':
                die(f'{reg}: {asg}')
            srctype.append((x.e, k, reg))
            continue
        m = re.fullmatch(r's1_toExuValid_(\d+_\d+)', reg)
        if m:
            x = bykey[m.group(1)]
            rhs = asg[0][2]
            has_lddep[x.e] = 'ld2Cancel' in rhs
            if has_lddep[x.e]:
                exp_ld = ' | '.join(f'io_ldCancel_{i}_ld2Cancel & {x.frm}bits_common_loadDependency_{i}[1]' for i in range(NUM_LDU))
                if f'~({exp_ld})' not in rhs:
                    die(f'{reg}: ldCancel 项形状不认识')
            continue
    for x in exus:
        if x.e not in has_lddep:
            die(f'EXU {x.e} 没有 s1_toExuValid')
        ports_ld = [n for _, _, n in g.ports if n.startswith(x.frm + 'bits_common_loadDependency_')]
        if has_lddep[x.e] and len(ports_ld) != NUM_LDU:
            die(f'EXU {x.e} 有 ldCancel 项但 loadDependency 端口数 {len(ports_ld)}')
    M['payload'] = payload
    M['imm'] = imm
    M['immtype'] = immtype
    M['srctype'] = srctype
    M['has_lddep'] = has_lddep
    off = 0
    M['pl_off'] = {}
    for x in exus:
        M['pl_off'][x.e] = off
        off += sum(w for _, w, _, _ in payload[x.e])
    M['pl_total'] = off

    # ---- 选源：toExu.src_k 的驱动 ----
    rdata_name = {}   # 'intRfRdata_3' 这类中间名 → (rf, port)
    for rf in ('int', 'fp', 'vf', 'v0'):
        for p in range(RF_RD[rf]):
            parts = ', '.join(f'_{rf}RegFilePart{n}_io_readPorts_{p}_data' for n in reversed(range(RF_PARTS[rf])))
            rdata_name['{' + parts + '}'] = (rf, p)
            nm = f'{rf}RfRdata_{p}'
            if nm in g.defs:
                if g.defs[nm] != '{' + parts + '}':
                    die(f'{nm} = {g.defs[nm]}')
                rdata_name[nm] = (rf, p)
                used_defs.add(nm)
    for p in range(RF_RD['vl']):
        rdata_name[f"{{120'h0, _vlRegFile_io_readPorts_{p}_data}}"] = ('vl', p)
    for nm, d in g.defs.items():
        if re.fullmatch(r's1_vlPregRData_\d+_\d+_\d+', nm):
            if d not in rdata_name:
                die(f'{nm} = {d}')
            rdata_name[nm] = rdata_name[d]
            used_defs.add(nm)
    srcsel = {}   # (e,k) -> [(rf, port, typebit or None)]
    st_reg_idx = {reg: n for n, (_, _, reg) in enumerate(srctype)}
    for x in exus:
        for k in range(MAX_SRC):
            o = f'{x.toexu}bits_src_{k}'
            if o not in g.pd:
                continue
            d = g.defs[o]
            if d in rdata_name:
                srcsel[(x.e, k)] = [rdata_name[d] + (None,)]
                continue
            opts = []
            for term in d.split(' | '):
                tm = re.fullmatch(r"\((s1_srcType_r_\d+_\d+)\[(\d)\] \? (.*) : 64'h0\)", term)
                if not tm or tm.group(3) not in rdata_name:
                    die(f'{o} = {d}（选源形状不认识）')
                opts.append(rdata_name[tm.group(3)] + ((st_reg_idx[tm.group(1)], int(tm.group(2))),))
            srcsel[(x.e, k)] = opts
        ks = [k for (e, k) in srcsel if e == x.e]
        if ks != list(range(len(ks))):
            die(f'EXU {x.e} 的 src 端口不连续 {ks}')
    M['srcsel'] = srcsel

    # ---- og1 回告类型 ----
    unc = {}
    for x in exus:
        o = f'{x.toiq}og1resp_bits_resp'
        if o not in g.defs:
            unc[x.e] = None
            continue
        d = g.defs[o]
        fail = f'{x.key}'
        if d == f"s1_toExuValid_{x.key} & ~{x.toexu}ready ? 2'h0 : 2'h3":
            unc[x.e] = False
        elif d == f"{{1'h0, ~(s1_toExuValid_{x.key} & ~{x.toexu}ready)}}":
            unc[x.e] = True
        else:
            die(f'{o} = {d}')
    for x in exus:        # 没有 resp 端口的（Vf 调度器）按 Scala：inVfSchd ⇒ uncertain（无端口，不影响任何比较点）
        if unc[x.e] is None:
            if x.kind != 'Vf':
                die(f'EXU {x.e} 没有 og1resp.resp 端口')
            unc[x.e] = True
    M['og1_unc'] = unc

    # ---- store 单元（TopDown 的 noStoreIssued）----
    m = re.fullmatch(r'~\((.*)\)', g.assign['stallStore_REG'][0][2])
    M['store_exus'] = [bykey[f] for f in re.findall(r'fromIQFire_(\d+_\d+)', m.group(1))]

    # ---- RegCache 读口 ----
    typ, conns = g.inst_by_name['regCache']
    rc = {}
    for p, s in conns.items():
        m = re.fullmatch(r'io_readPorts_(\d+)_ren', p)
        if not m:
            continue
        n = int(m.group(1))
        sm = re.fullmatch(r'(io_from\w+IQ_\d+_\d+_)valid & (_regCacheReadReq_readPorts_\d+_ren_T(?:_\d+)?)', s)
        x = next(x for x in exus if x.frm == sm.group(1))
        dm = re.fullmatch(re.escape(x.frm) + r"bits_common_dataSources_(\d)_value == 4'h6", g.defs[sm.group(2)])
        k = int(dm.group(1))
        used_defs.add(sm.group(2))
        if conns[f'io_readPorts_{n}_addr'] != f'{x.frm}bits_rcIdx_{k}':
            die(f'RegCache 读口 {n} 地址 {conns[f"io_readPorts_{n}_addr"]}')
        rc[n] = (x.e, k, conns[f'io_readPorts_{n}_data'])
    M['rc'] = rc

    # ---- 向量异常借口：对照 golden 断言 ----
    # isV0 端口只有第 0/4 路读、第 0 路写有（其余路恒为 0，firtool 连端口删掉），wrapper 对缺的接 0
    for i in range(8):
        if (f'io_fromVecExcpMod_r_{i}_bits_isV0' in g.pd) != (i % 4 == 0):
            die(f'VecExcpMod r_{i}.isV0 端口存在性与模型不符')
    for i in range(4):
        if (f'io_fromVecExcpMod_w_{i}_bits_isV0' in g.pd) != (i % 4 == 0):
            die(f'VecExcpMod w_{i}.isV0 端口存在性与模型不符')
    for i, p in enumerate(EXCP_R_VF_PORT):
        d = g.defs.get(f'vfRfRaddr_{p}')
        cond = f'io_fromVecExcpMod_r_{i}_valid & ~io_fromVecExcpMod_r_{i}_bits_isV0' if i % 4 == 0 else f'io_fromVecExcpMod_r_{i}_valid'
        if d != f'{cond} ? io_fromVecExcpMod_r_{i}_bits_addr : _vfRFReadArbiter_io_out_{p}_bits_addr':
            die(f'vfRfRaddr_{p} = {d}')
        used_defs.add(f'vfRfRaddr_{p}')
    for j, p in enumerate(EXCP_R_V0_PORT):
        i = 4 * j
        d = g.defs.get(f'v0RfRaddr_{p}')
        if d != f'io_fromVecExcpMod_r_{i}_valid & io_fromVecExcpMod_r_{i}_bits_isV0 ? io_fromVecExcpMod_r_{i}_bits_addr[4:0] : _v0RFReadArbiter_io_out_{p}_bits_addr':
            die(f'v0RfRaddr_{p} = {d}')
        used_defs.add(f'v0RfRaddr_{p}')
    return M



# ---------------------------------------------------------------------------
# 生成 1：配置表（datapath_pkg 里的 GENERATED 区）
# ---------------------------------------------------------------------------
def exu_tag(x):
    return f'e{x.e} {x.kind}IQ{x.i}.{x.j}'


def gen_tables(M):
    ex = M['exus']
    L = []
    A = L.append
    A('  // BEGIN GENERATED(dp_tables) —— 由 scripts/gen_datapath.py 从 golden 实测，勿手改')
    A('  // 每个 EXU 的寄存器源操作数个数（dataSources 的路数）')
    A('  localparam int unsigned NUM_SRC [NUM_EXU] = \'{' + ', '.join(str(x.nsrc) for x in ex) + '};')
    A('')
    A('  // RD_REQ[e][k]：EXU e 的源 k 向哪几类寄存器堆的读口仲裁器发请求（位序 {vl,v0,vf,fp,int}）')
    A('  localparam logic [NUM_RF-1:0] RD_REQ [NUM_EXU][MAX_SRC] = \'{')
    for x in ex:
        row = []
        for k in range(MAX_SRC):
            b = ''.join('1' if (x.e, k, rf) in M['rd_req'] else '0' for rf in reversed(RFS))
            row.append(f"5'b{b}")
        A(f"    '{{{', '.join(row)}}}{',' if x.e < 26 else ''}  // {exu_tag(x)}")
    A('  };')
    A('')
    A('  // WB_REQ[e]：EXU e 的写回要向哪几类寄存器堆的写口撞口检查器申请（位序同上）')
    A('  localparam logic [NUM_RF-1:0] WB_REQ [NUM_EXU] = \'{')
    for x in ex:
        b = ''.join('1' if (x.e, rf) in M['wb_req'] else '0' for rf in reversed(RFS))
        A(f"    5'b{b}{',' if x.e < 26 else ''}  // {exu_tag(x)}")
    A('  };')
    A('')
    A('  // WAKE_SRC[e][k]：该源是 IQ 唤醒的接收方（有 exuSources，参与 s0_cancel）')
    A('  localparam bit WAKE_SRC [NUM_EXU][MAX_SRC] = \'{')
    for x in ex:
        row = ["1'b1" if (x.e, k) in M['ext'] else "1'b0" for k in range(MAX_SRC)]
        A(f"    '{{{', '.join(row)}}}{',' if x.e < 26 else ''}  // {exu_tag(x)}")
    A('  };')
    A('')
    A('  // HAS_LD_DEP[e]：该 EXU 的 uop 带 loadDependency（s1_valid 要看 ld2Cancel）')
    A('  localparam bit HAS_LD_DEP [NUM_EXU] = \'{' + ', '.join("1'b1" if M['has_lddep'][x.e] else "1'b0" for x in ex) + '};')
    A('  // OG1_UNCERTAIN[e]：og1 成功时回 uncertain（访存地址 / 向量访存 / 向量调度器）而不是 success')
    A('  localparam bit OG1_UNCERTAIN [NUM_EXU] = \'{' + ', '.join("1'b1" if M['og1_unc'][x.e] else "1'b0" for x in ex) + '};')
    A('')
    A('  // 非访存载入的 EXU（og0Cancel 只关心它们；载入单元的取消走 ldCancel）')
    A(f"  localparam int unsigned NUM_NOLOAD = {len(M['noload'])};")
    A('  localparam int unsigned NO_LOAD_EXU [NUM_NOLOAD] = \'{' + ', '.join(str(e) for e in M['noload']) + '};')
    mask = sum(1 << b for b in M['zlat_bits'])
    A(f"  // 0 拍延迟 FU 的 FuType 位（{', '.join(str(b) for b in M['zlat_bits'])}）")
    A(f"  localparam logic [FUTYPE_W-1:0] FUTYPE_0LAT_MASK = 35'h{mask:09x};")
    sm = sum(1 << x.e for x in M['store_exus'])
    A(f"  // store 地址 / store 数据单元（TopDown 的 noStoreIssued）：EXU {', '.join(str(x.e) for x in M['store_exus'])}")
    A(f"  localparam logic [NUM_EXU-1:0] STORE_EXU_MASK = 27'h{sm:07x};")
    A('')
    A('  // s0→s1 原样打拍的字段：EXU e 占 s1_payload_q[PAYLOAD_OFF[e] +: PAYLOAD_W[e]]（字段表见 wrapper）')
    A(f"  localparam int unsigned PAYLOAD_TOTAL = {M['pl_total']};")
    A('  localparam int unsigned PAYLOAD_OFF [NUM_EXU] = \'{' + ', '.join(str(M['pl_off'][x.e]) for x in ex) + '};')
    A('  localparam int unsigned PAYLOAD_W   [NUM_EXU] = \'{' + ', '.join(str(sum(w for _, w, _, _ in M['payload'][x.e])) for x in ex) + '};')
    A('')
    A('  // og1ImmInfo：只有这些 EXU 的 imm / immType 还有输出（其余被 firtool 删了）')
    A(f"  localparam int unsigned NUM_IMM = {len(M['imm'])};")
    A('  localparam int unsigned IMM_EXU [NUM_IMM] = \'{' + ', '.join(str(e) for e in M['imm']) + '};')
    A(f"  localparam int unsigned NUM_IMMTYPE = {len(M['immtype'])};")
    A('  localparam int unsigned IMMTYPE_EXU [NUM_IMMTYPE] = \'{' + ', '.join(str(e) for e in M['immtype']) + '};')
    A('  // 需要保存 srcType 的源（选源有多个候选的那些）')
    A(f"  localparam int unsigned NUM_SRCTYPE = {len(M['srctype'])};")
    A('  localparam int unsigned SRCTYPE_EXU [NUM_SRCTYPE] = \'{' + ', '.join(str(e) for e, k, r in M['srctype']) + '};')
    A('  localparam int unsigned SRCTYPE_SRC [NUM_SRCTYPE] = \'{' + ', '.join(str(k) for e, k, r in M['srctype']) + '};')
    A('')
    A('  // og1 选源：源 k 的候选 o 来自寄存器堆 SRC_RF 的读口 SRC_PORT；多候选时看 s1_srcType_q[SRC_TYPE_REG] 的 SRC_TYPE_BIT 位')
    for nm, fn in (('SRC_NOPT', lambda o: str(len(o))),):
        pass
    rows_n, rows_rf, rows_port, rows_reg, rows_bit = [], [], [], [], []
    for x in ex:
        n_, rf_, pt_, rg_, bt_ = [], [], [], [], []
        for k in range(MAX_SRC):
            o = M['srcsel'].get((x.e, k), [])
            n_.append(str(len(o)))
            oo = o + [('int', 0, None)] * (2 - len(o))
            rf_.append("'{" + ', '.join(f'RF_{rf.upper()}' for rf, _, _ in oo) + '}')
            pt_.append("'{" + ', '.join(str(p) for _, p, _ in oo) + '}')
            rg_.append(str(o[0][2][0]) if o and o[0][2] else '0')
            bt_.append("'{" + ', '.join(str(t[1]) if t else '0' for _, _, t in oo) + '}')
        rows_n.append(n_); rows_rf.append(rf_); rows_port.append(pt_); rows_reg.append(rg_); rows_bit.append(bt_)
    if any(len(M['srcsel'].get((x.e, k), [])) > 2 for x in ex for k in range(MAX_SRC)):
        die('选源候选超过 2 个')

    def arr(name, typ, dims, rows):
        A(f'  localparam {typ} {name} {dims} = \'{{')
        for x, r in zip(ex, rows):
            A(f"    '{{{', '.join(r)}}}{',' if x.e < 26 else ''}  // {exu_tag(x)}")
        A('  };')
    arr('SRC_NOPT', 'int unsigned', '[NUM_EXU][MAX_SRC]', rows_n)
    arr('SRC_RF', 'int unsigned', '[NUM_EXU][MAX_SRC][2]', rows_rf)
    arr('SRC_PORT', 'int unsigned', '[NUM_EXU][MAX_SRC][2]', rows_port)
    arr('SRC_TYPE_REG', 'int unsigned', '[NUM_EXU][MAX_SRC]', rows_reg)
    arr('SRC_TYPE_BIT', 'int unsigned', '[NUM_EXU][MAX_SRC][2]', rows_bit)
    A('')
    A('  // 向量异常模块借用的读 / 写口（DataPath.scala vecExcpUse*Ports，生成时对照 golden 断言）')
    A('  localparam int unsigned EXCP_R_VF_PORT [EXCP_R] = \'{' + ', '.join(map(str, EXCP_R_VF_PORT)) + '};')
    A('  localparam int unsigned EXCP_R_V0_PORT [EXCP_R/4] = \'{' + ', '.join(map(str, EXCP_R_V0_PORT)) + '};')
    A('  localparam int unsigned EXCP_W_VF_PORT [EXCP_W] = \'{' + ', '.join(map(str, EXCP_W_VF_PORT)) + '};')
    A(f'  localparam int unsigned EXCP_W_V0_PORT = {EXCP_W_V0_PORT};')
    A('  // END GENERATED')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# 生成 2：golden 同名 wrapper
# ---------------------------------------------------------------------------
OG_FIELD = {'robIdx_flag': 'robIdx_flag', 'robIdx_value': 'robIdx_value', 'fuType': 'fuType', 'uopIdx': 'vpu_vuopIdx'}
PERF_ZERO = re.compile(r"\d+'h0")


def gen_wrapper(g, M):
    ex = M['exus']
    L = []
    A = L.append
    A('// BEGIN GENERATED(dp_wrapper) —— 由 scripts/gen_datapath.py 从 golden 端口表与例化表产出，勿手改')
    A('module DataPath')
    A('  import datapath_pkg::*;')
    A('(')
    A('\n'.join(g.port_lines))
    A(');')
    A('')
    A('  // ---- 与核相连的信号（与 xs_DataPath_core 端口同名）----')
    decl = [
        ('redirect_t', '', 'flush'), ('logic', '[NUM_LDU-1:0]', 'ld2Cancel'),
        ('logic', '[NUM_EXU-1:0]', 's0_valid'), ('logic', '[NUM_EXU-1:0]', 's0_ready'),
        ('rob_ptr_t', '[NUM_EXU-1:0]', 's0_robIdx'), ('logic', '[NUM_EXU-1:0][FUTYPE_W-1:0]', 's0_fuType'),
        ('logic', '[NUM_EXU-1:0][MAX_SRC-1:0][3:0]', 's0_dataSrc'), ('logic', '[NUM_EXU-1:0][MAX_SRC-1:0][2:0]', 's0_exuSrc'),
        ('logic', '[NUM_EXU-1:0][NUM_LDU-1:0][1:0]', 's0_ldDep'), ('logic', '[NUM_EXU-1:0][NUM_RF-1:0]', 's0_rfWen'),
        ('logic', '[NUM_EXU-1:0][MAX_SRC-1:0][NUM_RF-1:0][PREG_W-1:0]', 's0_rfAddr'),
        ('logic', '[NUM_EXU-1:0][MAX_SRC-1:0][3:0]', 's0_srcType'), ('logic', '[NUM_EXU-1:0][31:0]', 's0_imm'),
        ('logic', '[NUM_EXU-1:0][3:0]', 's0_immType'), ('logic', '[NUM_EXU-1:0][1:0][4:0]', 's0_rcIdx'),
        ('logic', '[PAYLOAD_TOTAL-1:0]', 's0_payload'),
        ('logic', '[NUM_EXU-1:0]', 's1_valid'), ('logic', '[NUM_EXU-1:0]', 's1_exuReady'),
        ('logic', '[PAYLOAD_TOTAL-1:0]', 's1_payload'), ('logic', '[NUM_EXU-1:0][MAX_SRC-1:0][127:0]', 's1_src'),
        ('logic', '[NUM_IMM-1:0][31:0]', 's1_imm'), ('logic', '[NUM_IMMTYPE-1:0][3:0]', 's1_immType'),
        ('logic', '[NUM_EXU-1:0]', 'og0_failed'), ('logic', '[NUM_EXU-1:0][1:0]', 'og1_resp'),
        ('logic', '[NUM_EXU-1:0]', 'og1_cancel'),
        ('logic', '[NUM_RF-1:0][NUM_EXU-1:0][MAX_SRC-1:0]', 'rd_req_valid'),
        ('logic', '[NUM_RF-1:0][NUM_EXU-1:0][MAX_SRC-1:0][PREG_W-1:0]', 'rd_req_addr'),
        ('logic', '[NUM_RF-1:0][NUM_EXU-1:0][MAX_SRC-1:0]', 'rd_req_ready'),
        ('logic', '[NUM_RF-1:0][NUM_EXU-1:0]', 'wb_req_valid'), ('logic', '[NUM_RF-1:0][NUM_EXU-1:0]', 'wb_req_ready'),
        ('logic', '[NUM_EXU-1:0][MAX_SRC-1:0][6:0]', 'exuOH_local'),
        ('logic', '[NUM_EXU-1:0][MAX_SRC-1:0][NUM_EXU-1:0]', 'exuOH_global'),
    ]
    for rf in RFS:
        U = rf.upper()
        decl += [('logic', f'[{U}_RD-1:0][{U}_AW-1:0]', f'{rf}_rdArb_addr'),
                 ('logic', f'[{U}_WR-1:0]', f'{rf}Wb_wen'), ('logic', f'[{U}_WR-1:0][{U}_AW-1:0]', f'{rf}Wb_addr'),
                 ('logic', f'[{U}_WR-1:0][{U}_DW-1:0]', f'{rf}Wb_data'),
                 ('logic', f'[{U}_RD-1:0][{U}_AW-1:0]', f'{rf}_raddr'), ('logic', f'[{U}_RD-1:0][{U}_DW-1:0]', f'{rf}_rdata'),
                 ('logic', f'[{U}_WR-1:0][{U}_AW-1:0]', f'{rf}_waddr'), ('logic', f'[{U}_WR-1:0][{U}_DW-1:0]', f'{rf}_wdata')]
        if rf in ('vf', 'v0'):
            decl.append(('logic', f'[{U}_PARTS-1:0][{U}_WR-1:0]', f'{rf}_wen'))
        else:
            decl.append(('logic', f'[{U}_WR-1:0]', f'{rf}_wen'))
    decl += [('logic', '[NUM_EXU-1:0][1:0]', 'rc_ren'), ('logic', '[NUM_EXU-1:0][1:0][4:0]', 'rc_addr'),
             ('logic', '[EXCP_R-1:0]', 'excpR_valid'), ('logic', '[EXCP_R-1:0]', 'excpR_isV0'),
             ('logic', '[EXCP_R-1:0][VF_AW-1:0]', 'excpR_addr'), ('logic', '[EXCP_W-1:0]', 'excpW_valid'),
             ('logic', '[EXCP_W-1:0]', 'excpW_isV0'), ('logic', '[EXCP_W-1:0][VF_AW-1:0]', 'excpW_addr'),
             ('logic', '[EXCP_W-1:0][VF_DW-1:0]', 'excpW_data'), ('logic', '[EXCP_RVALID-1:0]', 'excpRdata_valid'),
             ('logic', '[EXCP_R-1:0][VF_DW-1:0]', 'excpRdata_bits'), ('logic', '[5:0]', 'perf_event')]
    for rf in RFS:
        if RF_PARTS[rf] > 1:
            decl.append(('logic', f'[{RF_PARTS[rf] - 1}:0][{rf.upper()}_RD-1:0][{RF_DW[rf] // RF_PARTS[rf] - 1}:0]', f'{rf}_rdataPart'))
    w1 = max(len(t) for t, _, _ in decl)
    w2 = max(len(r) for _, r, _ in decl)
    for t, r, n in decl:
        A(f'  {t.ljust(w1)} {r.ljust(w2)} {n};')
    A('')
    core_ports = ['flush', 'ld2Cancel', 's0_valid', 's0_ready', 's0_robIdx', 's0_fuType', 's0_dataSrc', 's0_exuSrc',
                  's0_ldDep', 's0_rfWen', 's0_rfAddr', 's0_srcType', 's0_imm', 's0_immType', 's0_rcIdx', 's0_payload',
                  's1_valid', 's1_exuReady', 's1_payload', 's1_src', 's1_imm', 's1_immType', 'og0_failed', 'og1_resp',
                  'og1_cancel', 'rd_req_valid', 'rd_req_addr', 'rd_req_ready'] + \
                 [f'{rf}_rdArb_addr' for rf in RFS] + ['wb_req_valid', 'wb_req_ready', 'exuOH_local', 'exuOH_global']
    for rf in RFS:
        core_ports += [f'{rf}Wb_wen', f'{rf}Wb_addr', f'{rf}Wb_data']
    for rf in RFS:
        core_ports += [f'{rf}_raddr', f'{rf}_rdata', f'{rf}_wen', f'{rf}_waddr', f'{rf}_wdata']
    core_ports += ['rc_ren', 'rc_addr', 'excpR_valid', 'excpR_isV0', 'excpR_addr', 'excpW_valid', 'excpW_isV0',
                   'excpW_addr', 'excpW_data', 'excpRdata_valid', 'excpRdata_bits']
    td = {'td_replayAllocate': 'io_topDownInfo_replayAllocate', 'td_sqFull': 'io_topDownInfo_sqFull',
          'td_sbFull': 'io_topDownInfo_sbFull', 'td_l1Miss': 'io_topDownInfo_l1Miss',
          'td_l2Miss': 'io_topDownInfo_l2TopMiss_l2Miss', 'td_l3Miss': 'io_topDownInfo_l2TopMiss_l3Miss'}
    A('  xs_DataPath_core u_core (')
    A('    .clock             (clock),')
    A('    .reset             (reset),')
    for p in core_ports:
        A(f'    .{p.ljust(17)} ({p}),')
    for p, s in td.items():
        A(f'    .{p.ljust(17)} ({s}),')
    A('    .perf_event        (perf_event)')
    A('  );')
    A('')

    # ---- 核的输入：从 golden 端口拼装 ----
    A('  // ---- og0 输入：各 EXU 的字段拼进核的数组（该 EXU 没有的字段接 0）----')
    A("  assign flush = '{valid: io_flush_valid, robIdx: '{flag: io_flush_bits_robIdx_flag, value: io_flush_bits_robIdx_value}, level: io_flush_bits_level};")
    A('  assign ld2Cancel = {' + ', '.join(f'io_ldCancel_{i}_ld2Cancel' for i in reversed(range(NUM_LDU))) + '};')
    pd = g.pd
    for x in ex:
        e = x.e
        f = x.frm
        A(f'  // {exu_tag(x)}')
        A(f'  assign s0_valid[{e}]  = {f}valid;')
        A(f"  assign s0_robIdx[{e}] = '{{flag: {f}bits_common_robIdx_flag, value: {f}bits_common_robIdx_value}};")
        A(f'  assign s0_fuType[{e}] = {f}bits_common_fuType;')
        for k in range(MAX_SRC):
            p_ds = f'{f}bits_common_dataSources_{k}_value'
            A(f"  assign s0_dataSrc[{e}][{k}] = {p_ds if p_ds in pd else chr(39) + '0'};")
            p_ex = f'{f}bits_common_exuSources_{k}_value'
            A(f"  assign s0_exuSrc[{e}][{k}] = {('3' + chr(39) + '(' + p_ex + ')') if p_ex in pd else chr(39) + '0'};")
            p_st = f'{f}bits_srcType_{k}'
            A(f"  assign s0_srcType[{e}][{k}] = {p_st if p_st in pd else chr(39) + '0'};")
            for r, rf in enumerate(RFS):
                a = M['rd_req'].get((e, k, rf))
                A(f"  assign s0_rfAddr[{e}][{k}][{r}] = {('PREG_W' + chr(39) + '(' + a + ')') if a else chr(39) + '0'};")
        for i in range(NUM_LDU):
            p_ld = f'{f}bits_common_loadDependency_{i}'
            A(f"  assign s0_ldDep[{e}][{i}] = {p_ld if p_ld in pd else chr(39) + '0'};")
        wen = []
        for rf in reversed(RFS):
            p_w = f'{f}bits_common_{WEN_FIELD[rf]}'
            wen.append(p_w if p_w in pd else "1'b0")
        A(f"  assign s0_rfWen[{e}] = {{{', '.join(wen)}}};")
        p_imm = f'{f}bits_common_imm'
        A(f"  assign s0_imm[{e}] = {(p_imm + '[31:0]') if (p_imm in pd and e in M['imm']) else chr(39) + '0'};")
        p_it = f'{f}bits_immType'
        A(f"  assign s0_immType[{e}] = {p_it if p_it in pd else chr(39) + '0'};")
        for k in range(2):
            p_rc = f'{f}bits_rcIdx_{k}'
            A(f"  assign s0_rcIdx[{e}][{k}] = {p_rc if p_rc in pd else chr(39) + '0'};")
        tex = x.toexu + 'ready'
        if tex in pd:
            A(f'  assign s1_exuReady[{e}] = {tex};')
        else:   # 向量 EXU 没有 ready 端口：golden 里它恒收（og1Cancel 恒 0）
            A(f"  assign s1_exuReady[{e}] = 1'b1;  // golden 无 ready 端口（向量 EXU 恒收）")
    A('')
    A('  // ---- s0→s1 原样打拍的字段：拼进 / 拆出 payload（EXU e 占 [PAYLOAD_OFF[e] +: PAYLOAD_W[e]]）----')
    reg_slice = {}
    for x in ex:
        off = M['pl_off'][x.e]
        A(f'  // {exu_tag(x)}：{len(M["payload"][x.e])} 个字段，{sum(w for _, w, _, _ in M["payload"][x.e])} 位')
        for reg, w, src, kind in M['payload'][x.e]:
            if kind == 'copy':
                rhs = src
            elif kind == 'ldshift':
                rhs = f"{{{src}[0], 1'b0}}   // loadDependency << 1（Bundles.scala fromIssueBundle）"
            else:
                rhs = f'{src}[{w - 1}:0]'
            fld = reg.split(f's1_toExuData_{x.key}_', 1)[1]
            A(f'  assign s0_payload[{off} +: {w}] = {rhs}' + (';' if kind != 'ldshift' else '').rstrip() if kind != 'ldshift'
              else f'  assign s0_payload[{off} +: {w}] = {{{src}[0], 1\'b0}};  // {fld}：loadDependency << 1（Bundles.scala fromIssueBundle）')
            reg_slice[reg] = f's1_payload[{off} +: {w}]'
            off += w
    A('')

    # ---- 写回口、向量异常口 ----
    A('  // ---- 写回级与向量异常模块 ----')
    for rf in RFS:
        C = RF_CAP[rf]
        n = RF_WR[rf]
        A(f'  assign {rf}Wb_wen  = {{' + ', '.join(f'io_from{C}Wb_{p}_wen' for p in reversed(range(n))) + '};')
        A(f'  assign {rf}Wb_addr = {{' + ', '.join(f'io_from{C}Wb_{p}_addr' for p in reversed(range(n))) + '};')
        A(f'  assign {rf}Wb_data = {{' + ', '.join(f'io_from{C}Wb_{p}_data' for p in reversed(range(n))) + '};')
    def vx(fmt, n, alt):
        return '{' + ', '.join((fmt.format(i) if fmt.format(i) in pd else alt) for i in reversed(range(n))) + '}'
    A('  assign excpR_valid = ' + vx('io_fromVecExcpMod_r_{}_valid', 8, "1'b0") + ';')
    A('  assign excpR_isV0  = ' + vx('io_fromVecExcpMod_r_{}_bits_isV0', 8, "1'b0") + ';  // 只有第 0/4 路有 isV0 端口，其余恒 0')
    A('  assign excpR_addr  = ' + vx('io_fromVecExcpMod_r_{}_bits_addr', 8, "7'h0") + ';')
    A('  assign excpW_valid = ' + vx('io_fromVecExcpMod_w_{}_valid', 4, "1'b0") + ';')
    A('  assign excpW_isV0  = ' + vx('io_fromVecExcpMod_w_{}_bits_isV0', 4, "1'b0") + ';  // 只有第 0 路有 isV0 端口')
    A('  assign excpW_addr  = ' + vx('io_fromVecExcpMod_w_{}_bits_newVdAddr', 4, "7'h0") + ';')
    A('  assign excpW_data  = ' + vx('io_fromVecExcpMod_w_{}_bits_newVdData', 4, "128'h0") + ';')
    A('  // 没有对应子模块端口的位置接常量（核里按 NUM_SRC / WAKE_SRC 表不会读到它们）')
    for x in ex:
        for k in range(MAX_SRC):
            if k >= x.nsrc:
                A(f"  assign rd_req_ready[{RFS.index('int')}][{x.e}][{k}] = 1'b1;")
                for rf in RFS[1:]:
                    A(f"  assign rd_req_ready[{RFS.index(rf)}][{x.e}][{k}] = 1'b1;")
            if (x.e, k) not in M['ext']:
                A(f"  assign exuOH_global[{x.e}][{k}] = '0;")
    for rf in RFS:
        if RF_PARTS[rf] > 1:
            for p in range(RF_RD[rf]):
                A(f'  assign {rf}_rdata[{p}] = {{' + ', '.join(f'{rf}_rdataPart[{n}][{p}]' for n in reversed(range(RF_PARTS[rf]))) + '};')
    A('')

    # ---- 子模块 ----
    A('  // ---- 子模块：类型与实例名与 golden 相同 ----')
    ext_of = {v[0]: (k, v) for k, v in M['ext'].items()}
    dbg_map = {}     # golden 网名 -> 本文件表达式（difftest 用）
    for typ, name, conns in g.insts:
        m = re.fullmatch(r'(int|fp|vf|v0|vl)RegFile(?:Part(\d))?', name)
        for p, s in conns.items():
            dm = re.fullmatch(r'io_debug_all_rdata_(\d+)', p)
            if m and dm:
                rf, part = m.group(1), int(m.group(2) or 0)
                dbg_map[s] = f'{rf}_debugPart{part}[{dm.group(1)}]'
    dbg_decl = {}
    for typ, name, conns in g.insts:
        m = re.fullmatch(r'(int|fp|vf|v0)RegFilePart(\d)', name)
        if m:
            n_dbg = len([p for p in conns if p.startswith('io_debug_all_rdata_')])
            first = min(int(p.rsplit('_', 1)[1]) for p in conns if p.startswith('io_debug_all_rdata_'))
            npreg = n_dbg + first
            dbg_decl[f'{m.group(1)}_debugPart{m.group(2)}'] = (npreg, RF_DW[m.group(1)] // RF_PARTS[m.group(1)])
    for nm, (npreg, w) in dbg_decl.items():
        A(f'  logic [{npreg - 1}:0][{w - 1}:0] {nm};   // debug_all_rdata（difftest）')
    A('')
    for typ, name, conns in g.insts:
        A(f'  {typ} {name} (')
        items = []
        for p, s in conns.items():
            items.append((p, conn_expr(g, M, typ, name, p, s, ext_of)))
        wp = max(len(p) for p, _ in items)
        for i, (p, e) in enumerate(items):
            A(f'    .{p.ljust(wp)} ({e}){"," if i < len(items) - 1 else ""}')
        A('  );')
    A('')

    # ---- 输出 ----
    A('  // ---- 输出 ----')
    inst_driven = set()
    for typ, name, conns in g.insts:
        for p, s in conns.items():
            if s in g.pd and g.pd[s] == 'output':
                inst_driven.add(s)
    for d, w, n in g.ports:
        if d != 'output':
            continue
        if n in inst_driven:
            continue
        A(f'  assign {n} = {out_expr(g, M, n, w, reg_slice, dbg_map)};')
    A('endmodule')
    A('// END GENERATED')
    return '\n'.join(L) + '\n'


def conn_expr(g, M, typ, name, p, s, ext_of):
    """golden 子模块端口连接 → 本 wrapper 的表达式（按端口名形状翻译，认不出即退出）。"""
    ex = M['exus']
    if p in ('clock', 'reset'):
        return p
    m = re.fullmatch(r'(int|fp|vf|v0|vl)RFReadArbiter', name)
    if m:
        rf = m.group(1)
        r = RFS.index(rf)
        pm = re.fullmatch(r'io_in_(\d+)_(\d+)_(\d+)_(valid|bits_addr|ready)', p)
        if pm:
            x = M['bykey'][f'{pm.group(1)}_{pm.group(2)}']
            k = pm.group(3)
            return {'valid': f'rd_req_valid[{r}][{x.e}][{k}]', 'bits_addr': f'rd_req_addr[{r}][{x.e}][{k}][{RF_AW[rf] - 1}:0]',
                    'ready': f'rd_req_ready[{r}][{x.e}][{k}]'}[pm.group(4)]
        pm = re.fullmatch(r'io_out_(\d+)_(valid|bits_addr)', p)
        if pm:
            return f'{rf}_rdArb_addr[{pm.group(1)}]' if pm.group(2) == 'bits_addr' else ''
        die(f'{name}.{p}')
    m = re.fullmatch(r'(int|fp|vf|v0|vl)WbBusyArbiter', name)
    if m:
        r = RFS.index(m.group(1))
        pm = re.fullmatch(r'io_in_(\d+)_(\d+)_(valid|ready)', p)
        if pm:
            x = M['bykey'][f'{pm.group(1)}_{pm.group(2)}']
            return f'wb_req_{pm.group(3)}[{r}][{x.e}]'
        if re.fullmatch(r'io_out_\d+_valid', p):
            return ''
        die(f'{name}.{p}')
    m = re.fullmatch(r'(int|fp|vf|v0|vl)RegFile(?:Part(\d))?', name)
    if m:
        rf, part = m.group(1), int(m.group(2) or 0)
        pw = RF_DW[rf] // RF_PARTS[rf]
        pm = re.fullmatch(r'io_readPorts_(\d+)_(addr|data)', p)
        if pm:
            q = pm.group(1)
            if pm.group(2) == 'addr':
                return f'{rf}_raddr[{q}]'
            return f'{rf}_rdataPart[{part}][{q}]' if RF_PARTS[rf] > 1 else f'{rf}_rdata[{q}]'
        pm = re.fullmatch(r'io_writePorts_(\d+)_(wen|addr|data)', p)
        if pm:
            q = pm.group(1)
            if pm.group(2) == 'wen':
                return f'{rf}_wen[{part}][{q}]' if rf in ('vf', 'v0') else f'{rf}_wen[{q}]'
            if pm.group(2) == 'addr':
                return f'{rf}_waddr[{q}]'
            return f'{rf}_wdata[{q}][{pw * part} +: {pw}]' if RF_PARTS[rf] > 1 else f'{rf}_wdata[{q}]'
        pm = re.fullmatch(r'io_debug_all_rdata_(\d+)', p)
        if pm:
            return f'{rf}_debugPart{part}[{pm.group(1)}]'
        if rf == 'vl' and p in ('io_debug_rports_0_addr', 'io_debug_rports_0_data'):
            if s not in g.pd:
                die(f'vlRegFile.{p} = {s}')
            return s
        die(f'{name}.{p}')
    if name == 'regCache':
        pm = re.fullmatch(r'io_readPorts_(\d+)_(ren|addr|data)', p)
        if pm:
            e, k, dat = M['rc'][int(pm.group(1))]
            return {'ren': f'rc_ren[{e}][{k}]', 'addr': f'rc_addr[{e}][{k}]', 'data': dat}[pm.group(2)]
        if s in g.pd:
            return s
        die(f'regCache.{p} = {s}')
    if typ.startswith('UIntExtractor_27_'):
        (e, k), (_, _, hi) = ext_of[name]
        if p == 'io_in':
            return f'exuOH_local[{e}][{k}][{hi - 1}:0]'
        if p == 'io_out':
            return f'exuOH_global[{e}][{k}]'
    die(f'不认识的子模块连接 {name}.{p} = {s}')


def out_expr(g, M, n, w, reg_slice, dbg_map):
    """golden 输出端口 → 本 wrapper 的驱动表达式；golden 的驱动形状必须是下列之一，否则退出。"""
    d = g.defs.get(n)
    if d is None:
        die(f'输出 {n} 在 golden 里没有驱动')
    ex = M['exus']
    if re.fullmatch(r"\d+'h[0-9A-F]+", d):
        return d                                     # 常量（perfDebugInfo 等）
    if d in reg_slice:
        return reg_slice[d]                          # s1 原样打拍的字段
    if d in g.pd and g.pd[d] == 'input':
        return d                                     # 直通（og0resp 的 s0 字段、PC 读口、toExu.pc 等）
    for x in ex:
        if n == f'{x.frm}ready':
            return f's0_ready[{x.e}]'
        if n.startswith(x.toiq):
            f = n[len(x.toiq):]
            if f == 'og0resp_valid':
                return f'og0_failed[{x.e}]'
            if f == 'og1resp_valid' and d == f's1_toExuValid_{x.key}':
                return f's1_valid[{x.e}]'
            if f == 'og1resp_bits_resp':
                return f'og1_resp[{x.e}]'
            die(f'{n} = {d}')
        if n.startswith(x.toexu):
            f = n[len(x.toexu):]
            if f == 'valid' and d == f's1_toExuValid_{x.key}':
                return f's1_valid[{x.e}]'
            sm = re.fullmatch(r'bits_src_(\d+)', f)
            if sm:
                return f's1_src[{x.e}][{sm.group(1)}][{w - 1}:0]'
            die(f'{n} = {d}')
    m = re.fullmatch(r'io_og0Cancel_(\d+)', n)
    if m:
        dm = re.fullmatch(r'og0_cancel_no_load_(\d+)', d)
        if not dm or M['noload'][int(dm.group(1))] != int(m.group(1)):
            die(f'{n} = {d}')
        return f'og0_failed[{m.group(1)}]'
    m = re.fullmatch(r'io_og1Cancel_(\d+)', n)
    if m:
        x = ex[int(m.group(1))]
        if d != f's1_toExuValid_{x.key} & ~({x.toexu}ready & s1_toExuValid_{x.key})':
            die(f'{n} = {d}')
        return f'og1_cancel[{x.e}]'
    m = re.fullmatch(r'io_og1ImmInfo_(\d+)_(imm|immType)', n)
    if m:
        x = ex[int(m.group(1))]
        if d != f's1_immInfo_{x.key}_{m.group(2)}':
            die(f'{n} = {d}')
        lst = M['imm'] if m.group(2) == 'imm' else M['immtype']
        return f's1_{m.group(2)}[{lst.index(x.e)}]'
    m = re.fullmatch(r'io_toVecExcpMod_rdata_(\d+)_(valid|bits)', n)
    if m:
        return f'excpRdata_{m.group(2)}[{m.group(1)}]'
    m = re.fullmatch(r'io_perf_(\d+)_value', n)
    if m:
        if d != f"{{5'h0, io_perf_{m.group(1)}_value_REG_1}}":
            die(f'{n} = {d}')
        return f"{{5'h0, perf_event[{m.group(1)}]}}"
    if re.fullmatch(r'gatewayIn_packed_\d+_bore', n):
        items = [t.strip() for t in d.strip('{}').split(',')]
        out = []
        for t in items:
            dd = g.defs.get(t)
            if t.endswith('_coreid') and dd == 'io_hartId':
                out.append('io_hartId')
            elif dd is not None and re.fullmatch(r"\d+'h0", dd):
                out.append(dd)
            elif dd is not None and dd.startswith('{'):
                out.append('{' + ', '.join(dbg_map[z.strip()] for z in dd.strip('{}').split(',')) + '}')
            elif t in dbg_map:
                out.append(dbg_map[t])
            else:
                die(f'{n}: 成分 {t} = {dd}')
        return '{' + ',\n    '.join(out) + '}'
    die(f'输出 {n} = {d}（形状不认识）')


# ---------------------------------------------------------------------------
# 生成 3：UT tb（golden DataPath vs 重写件 DataPath_xs 双例化）
# ---------------------------------------------------------------------------
TB_PATH = UT / 'tb.sv'
WARMUP = 120


def stim(n, w, g):
    """一个输入端口的激励表达式（热身阶段与随机阶段）。返回 (warm, rand)。"""
    def rnd(width):
        if width <= 32:
            return f"{width}'($urandom)"
        k = (width + 31) // 32
        return f"{width}'({{{', '.join(['$urandom'] * k)}}})"
    m = re.fullmatch(r'io_from(Int|Fp|Vf|V0|Vl)Wb_(\d+)_(wen|addr|data)', n)
    if m:
        rf = m.group(1).lower()
        p = int(m.group(2))
        if m.group(3) == 'wen':
            return "1'b1", "($urandom_range(0, 99) < 50)"
        if m.group(3) == 'addr':
            npreg = {'int': 224, 'fp': 192, 'vf': 128, 'v0': 22, 'vl': 32}[rf]
            return f"{w}'((cyc * {RF_WR[rf]} + {p}) % {npreg})", rnd(w)
        return rnd(w), rnd(w)
    if re.fullmatch(r'io_fromBypassNetwork_\d+_wen', n):
        return "1'b1", "($urandom_range(0, 99) < 50)"
    if re.fullmatch(r'io_from\w+IQ_\d+_\d+_valid', n):
        return "(cyc >= WARMUP - 40)", "($urandom_range(0, 99) < issue_pct)"
    if re.fullmatch(r'io_from\w+IQ_\d+_\d+_bits_common_dataSources_\d+_value', n):
        return "4'b0110", "ds_pick()"
    if n == 'io_flush_valid':
        return "1'b0", "($urandom_range(0, 99) < 5)"
    if re.fullmatch(r'io_ldCancel_\d+_ld2Cancel', n):
        return "1'b0", "($urandom_range(0, 99) < 5)"
    if re.fullmatch(r'io_to\w+Exu_\d+_\d+_ready', n):
        return "1'b1", "($urandom_range(0, 99) < 85)"
    if re.fullmatch(r'io_fromVecExcpMod_[rw]_\d+_valid', n):
        return "1'b0", "($urandom_range(0, 99) < 10)"
    return rnd(w), rnd(w)


def gen_tb(g, M):
    L = []
    A = L.append
    A('// DataPath UT —— golden DataPath 与重写件 DataPath_xs 双例化，同激励逐拍比全部输出')
    A('// ★本文件由 scripts/gen_datapath.py 生成（勿手改，--check 进闸）★')
    A('//')
    A(f'// 热身 {WARMUP} 拍：所有写回口 wen=1、地址按顺序扫遍各寄存器堆全部物理寄存器，RegCache 写口全开 ——')
    A('//   寄存器堆与 RegCache 的数据阵列都不复位，+vcs+initreg+random / +<n> 档两侧初值不同，')
    A('//   先把每一项写成确定值再开始比对。热身最后 40 拍发射口全开、源全走 RegCache：RegCache 读口的')
    A('//   地址寄存器只在 ren 时更新（不复位），也要先写一次（+vcs+initreg+<n> 档实测：不这样做，')
    A('//   比对开头 3 拍 RegCache 读数两侧不同）。')
    A('// 随机阶段：发射 valid 60%、dataSources 在 reg/regcache/forward/bypass/zero/imm/v0 里挑、')
    A('//   （发射 valid 每 500 拍在 60/20/3% 三档间换，低档才打得到 TopDown 的"发射少"事件）、')
    A('//   redirect 5%（robIdx 随机，约一半的 uop 会被判 isAfter）、ld2Cancel 5%、EXU ready 85%、')
    A('//   向量异常借口 10%、写回 wen 50%；约每 5k 拍插一次 2 拍异步复位。')
    A('// 覆盖（取重写件核内信号计数）：s0_cancel / 读口仲裁失败 / 写口撞口 / 冲刷 / ld 取消 / og1 失败 /')
    A('//   异常借写口 / store-data 多候选选源。')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A(f'  localparam int WARMUP = {WARMUP};')
    A('  bit clk = 0, rst = 1;')
    A('  int errors = 0, checks = 0, cyc = 0;')
    A('  int unsigned issue_pct = 60;   // 发射口 valid 概率：每 500 拍在 60/20/3 三档间换（低档才打得到 TopDown 的"发射少"事件）')
    A('  always #5 clk = ~clk;')
    A('')
    A('  function automatic logic [3:0] ds_pick();')
    A('    case ($urandom_range(0, 9))')
    A("      0, 1, 2, 3: return 4'b1000;   // reg")
    A("      4:          return 4'b0110;   // regcache")
    A("      5, 6:       return 4'b0001;   // forward")
    A("      7:          return 4'b0010;   // bypass")
    A("      8:          return 4'b0000;   // zero")
    A("      default:    return 4'b0100;   // imm")
    A('    endcase')
    A('  endfunction')
    A('')
    ins = [(w, n) for d, w, n in g.ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in g.ports if d == 'output']
    for w, n in ins:
        A(f'  logic [{w - 1}:0] {n};')
    for w, n in outs:
        A(f'  wire [{w - 1}:0] {n}__g, {n}__x;')
    for suf, mod in (('g', 'DataPath'), ('x', 'DataPath_xs')):
        A(f'  {mod} u_{suf} (')
        conns = ['    .clock(clk)', '    .reset(rst)'] + [f'    .{n}({n})' for _, n in ins] + [f'    .{n}({n}__{suf})' for _, n in outs]
        A(',\n'.join(conns))
        A('  );')
    A('')
    A('  always @(posedge clk) begin')
    A('    if (cyc < WARMUP) begin')
    for w, n in ins:
        A(f'      {n} <= {stim(n, w, g)[0]};')
    A('    end else begin')
    for w, n in ins:
        A(f'      {n} <= {stim(n, w, g)[1]};')
    A('    end')
    A('  end')
    A('')
    A('  // ---- 比对 ----')
    A('  always @(negedge clk) if (cyc > WARMUP + 4) begin')
    A('    checks++;')
    for w, n in outs:
        A(f'    if ({n}__g !== {n}__x) begin errors++; if (errors <= 40) $display("[cyc %0d] {n} g=%h x=%h", cyc, {n}__g, {n}__x); end')
    A('  end')
    A('')
    A('  // ---- 覆盖（重写件核内信号）----')
    A('  int cov_s0cancel = 0, cov_rdblock = 0, cov_wbblock = 0, cov_flushkill = 0, cov_ldkill = 0,')
    A('      cov_og1fail = 0, cov_excpw = 0, cov_srcmux = 0;')
    A('  int cov_perf [6] = \'{0, 0, 0, 0, 0, 0};')
    A('  always @(negedge clk) if (cyc > WARMUP + 4) begin')
    A('    if (|u_x.u_core.s0_cancel) cov_s0cancel++;')
    A('    if (|(u_x.u_core.s0_valid & ~u_x.u_core.src_not_block)) cov_rdblock++;')
    A('    if (|(u_x.u_core.s0_valid & ~u_x.u_core.wb_not_block)) cov_wbblock++;')
    A('    if (|(u_x.u_core.s0_fire & u_x.u_core.s0_flushed)) cov_flushkill++;')
    A('    if (|(u_x.u_core.s0_fire & u_x.u_core.s0_ld_cancel)) cov_ldkill++;')
    A('    if (|(u_x.u_core.s1_valid_q & ~u_x.u_core.s1_exuReady)) cov_og1fail++;')
    A('    if (|u_x.u_core.excpW_valid) cov_excpw++;')
    A('    for (int i = 0; i < 6; i++) if (u_x.u_core.perf_now[i]) cov_perf[i]++;')
    ex = M['exus']
    mux_exus = sorted({e for (e, k), o in M['srcsel'].items() if len(o) > 1})
    A('    if (' + ' | '.join(f'u_x.u_core.s1_valid_q[{e}]' for e in mux_exus) + ') cov_srcmux++;')
    A('  end')
    A('')
    A('  initial begin')
    A('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    A('    rst = 1; repeat (4) @(posedge clk); #2 rst = 0;')
    A('    repeat (NCYCLES) begin')
    A('      @(posedge clk); cyc++;')
    A('      if (cyc % 500 == 0) case ($urandom_range(0, 2)) 0: issue_pct = 60; 1: issue_pct = 20; default: issue_pct = 3; endcase')
    A('      if (cyc > WARMUP && $urandom_range(0, 4999) == 0) begin')
    A('        #2 rst = 1; @(posedge clk); cyc++; @(posedge clk); cyc++; #2 rst = 0;')
    A('      end')
    A('    end')
    A('    $display("COV s0cancel=%0d rdblock=%0d wbblock=%0d flushkill=%0d ldkill=%0d og1fail=%0d excpw=%0d srcmux=%0d",')
    A('             cov_s0cancel, cov_rdblock, cov_wbblock, cov_flushkill, cov_ldkill, cov_og1fail, cov_excpw, cov_srcmux);')
    A('    $display("COV perf exec_stall=%0d anyload=%0d store=%0d l1=%0d l2=%0d l3=%0d",')
    A('             cov_perf[0], cov_perf[1], cov_perf[2], cov_perf[3], cov_perf[4], cov_perf[5]);')
    A('    $display("checks=%0d errors=%0d", checks, errors);')
    A('    if (errors == 0 && checks > 1000 && cov_s0cancel > 100 && cov_rdblock > 100 && cov_wbblock > 100')
    A('        && cov_flushkill > 100 && cov_ldkill > 100 && cov_og1fail > 100 && cov_excpw > 100 && cov_srcmux > 100')
    A('        && cov_perf[0] > 100 && cov_perf[1] > 10 && cov_perf[2] > 10 && cov_perf[3] > 10 && cov_perf[4] > 10 && cov_perf[5] > 10)')
    A('      $display("TEST PASSED");')
    A('    else')
    A('      $display("TEST FAILED");')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# 生成 4：FM「匹配前」钉点（verif/ut/DataPath/fm_pins_pre.tcl）
# ---------------------------------------------------------------------------
PINS_PATH = UT / 'fm_pins_pre.tcl'


def golden_regs_of(mod):
    t = (GOLDEN / f'{mod}.sv').read_text()
    return [(n, int(w) + 1 if w else 1) for w, n in re.findall(r'^\s+reg\s+(?:\[(\d+):0\])?\s*(\w+);', t, re.M)]


def top_pin_map(g, M):
    """golden 顶层寄存器 → [(golden 基名, 宽, impl 基名（u_core 内）)]，每个寄存器恰好命中一条规则。"""
    ex = M['exus']
    bykey = M['bykey']
    out = []
    flush_idx = {}          # s1_flush_next_* 的后缀 -> EXU
    for x in ex:
        rhs = g.assign[f's1_toExuValid_{x.key}'][0][2]
        fm = re.search(r's1_flush_next_valid_last_REG(_\d+)?\b', rhs)
        bm = re.search(r's1_flush_next_bits_r(_\d+)?_level', rhs)
        if not fm or not bm or (fm.group(1) or '') != (bm.group(1) or ''):
            die(f's1_toExuValid_{x.key}: 找不到本 EXU 的上拍 redirect 寄存器')
        flush_idx[fm.group(1) or ''] = x.e
    wb_part = {}            # REG 名 -> (rf, part, port)
    for typ, name, conns in g.insts:
        m = re.fullmatch(r'(int|fp|vf|v0|vl)RegFile(?:Part(\d))?', name)
        if not m:
            continue
        for p, s in conns.items():
            pm = re.fullmatch(r'io_writePorts_(\d+)_wen', p)
            if pm:
                rm = re.search(r'\b(REG_\d+(?:_\d+)?)\b', s)
                if not rm:
                    die(f'{name}.{p} = {s}')
                wb_part[rm.group(1)] = (m.group(1), int(m.group(2) or 0), int(pm.group(1)))
    pl = {}
    for x in ex:
        off = M['pl_off'][x.e]
        for reg, w, _, _ in M['payload'][x.e]:
            pl[reg] = off
            off += w
    for reg, w in g.regs.items():
        asg = g.assign[reg]
        rhs = asg[-1][2]
        if reg in pl:
            out.append((reg, w, 'payload', pl[reg]))
            continue
        m = re.fullmatch(r's1_toExuValid_(\d+_\d+)', reg)
        if m:
            out.append((reg, w, f's1_valid_q_reg[{bykey[m.group(1)].e}]', None)); continue
        m = re.fullmatch(r's1_immInfo_(\d+_\d+)_(imm|immType)', reg)
        if m:
            e = bykey[m.group(1)].e
            lst = M['imm'] if m.group(2) == 'imm' else M['immtype']
            out.append((reg, w, f's1_{m.group(2)}_q_reg[{lst.index(e)}]', None)); continue
        m = re.fullmatch(r's1_srcType_r_(\d+)_(\d+)', reg)
        if m:
            i = [r for _, _, r in M['srctype']].index(reg)
            out.append((reg, w, f's1_srcType_q_reg[{i}]', None)); continue
        m = re.fullmatch(r's1_flush_next_valid_last_REG(_\d+)?', reg)
        if m:
            out.append((reg, w, f'flush_valid_q_reg[{flush_idx[m.group(1) or ""]}]', None)); continue
        m = re.fullmatch(r's1_flush_next_bits_r(_\d+)?_(robIdx_flag|robIdx_value|level)', reg)
        if m:
            e = flush_idx[m.group(1) or '']
            nm = {'robIdx_flag': 'flush_robFlag_q', 'robIdx_value': 'flush_robValue_q', 'level': 'flush_level_q'}[m.group(2)]
            out.append((reg, w, f'{nm}_reg[{e}]', None)); continue
        m = re.fullmatch(r'og0_cancel_delay_(\d+)', reg)
        if m:
            out.append((reg, w, f'og0_cancel_delay_q_reg[{m.group(1)}]', None)); continue
        m = re.fullmatch(r'IQsFireDelay_delayed_REG(?:_\d+)?', reg)
        if m:
            fm = re.fullmatch(r'fromIQFire_(\d+_\d+)', rhs)
            out.append((reg, w, f'fire_delay_q_reg[{bykey[fm.group(1)].e}]', None)); continue
        m = re.fullmatch(r'int_regcache_tag_(\d+)', reg)
        if m:
            out.append((reg, w, f'rc_tag_q_reg[{m.group(1)}]', None)); continue
        if reg == 'int_regcache_enqPtr':
            out.append((reg, w, 'rc_enq_ptr_q_reg', None)); continue
        m = re.fullmatch(r'io_toVecExcpMod_rdata_(\d+)_valid_REG', reg)
        if m:
            out.append((reg, w, f'excp_rdata_valid_q_reg[{m.group(1)}]', None)); continue
        m = re.fullmatch(r'io_toVecExcpMod_rdata_(\d+)_bits_r', reg)
        if m:
            out.append((reg, w, f'excp_read_vf_q_reg[{int(m.group(1)) // 4}]', None)); continue
        simple = {'stallStore_REG': 'no_store_q_reg', 'stallLoadDly': 'stall_load_q_reg', 'stallStoreDly': 'stall_store_q_reg'}
        if reg in simple:
            out.append((reg, w, simple[reg], None)); continue
        m = re.fullmatch(r'io_perf_(\d+)_value_REG(_1)?', reg)
        if m:
            out.append((reg, w, f'perf_q{2 if m.group(2) else 1}_reg[{m.group(1)}]', None)); continue
        # 写回级打拍：addr/data（wen 使能）与 wen 本身
        wm = re.fullmatch(r'io_from(Int|Fp|Vf|V0|Vl)Wb_(\d+)_(addr|data|wen)', rhs)
        if wm and re.fullmatch(r'r(_\d+)?|REG_\d+(_\d+)?', reg):
            rf = wm.group(1).lower()
            q = int(wm.group(2))
            if wm.group(3) == 'wen':
                rf2, part, port = wb_part[reg]
                if rf2 != rf or port != q:
                    die(f'{reg}: 写口映射不一致 {wb_part[reg]} vs {rf} {q}')
                nm = f'{rf}_wen_q_reg[{part}][{q}]' if rf in ('vf', 'v0') else f'{rf}_wen_q_reg[{q}]'
            else:
                nm = f'{rf}_w{wm.group(3)}_q_reg[{q}]'
            out.append((reg, w, nm, None)); continue
        die(f'顶层寄存器 {reg} 没有钉点规则')
    return out


def child_pin_map(g):
    """子模块内部：重写件把寄存器放进 u_core 的数组，golden 是平铺名。"""
    out = []
    for typ, name, conns in g.insts:
        m = re.fullmatch(r'(Int|Fp|Vf|V0)RegFilePart\d|VlRegFile', typ)
        if m:
            rd = 'raddr_q' if typ.startswith('Int') else 'read_addr_q'
            for reg, w in golden_regs_of(typ):
                mm = re.fullmatch(r'mem_(\d+)', reg)
                if mm:
                    out.append((f'{name}/{reg}', w, f'{name}/u_core/mem_reg[{mm.group(1)}]'))
                    continue
                mm = re.fullmatch(r'io_readPorts_(\d+)_data_REG', reg)
                if mm:
                    out.append((f'{name}/{reg}', w, f'{name}/u_core/{rd}_reg[{mm.group(1)}]'))
                    continue
                die(f'{typ}.{reg} 没有钉点规则')
        if re.fullmatch(r'\w+RFWBCollideChecker|\w+RFReadArbiter', typ):
            ct = (GOLDEN / f'{typ}.sv').read_text()
            for at, an in re.findall(r'^\s+(WBArbiter(?:_\d+)?) (arbiters_\d+) \(', ct, re.M):
                for reg, w in golden_regs_of(at):
                    mm = re.fullmatch(r'cancelCounter_(\d+)', reg)
                    if mm:
                        out.append((f'{name}/{an}/{reg}', w, f'{name}/{an}/u_core/cancel_cnt_q_reg[{mm.group(1)}]'))
                        continue
                    mm = re.fullmatch(r'isFull_(\d+)', reg)
                    if mm:
                        out.append((f'{name}/{an}/{reg}', w, f'{name}/{an}/u_core/is_full_q_reg[{mm.group(1)}]'))
                        continue
                    if reg == 'hasFull':
                        out.append((f'{name}/{an}/{reg}', w, f'{name}/{an}/u_core/has_full_q_reg'))
                        continue
                    die(f'{at}.{reg} 没有钉点规则')
    return out


def gen_pins(g, M):
    top = top_pin_map(g, M)
    child = child_pin_map(g)
    total = sum(w for _, w, _, _ in top) + sum(w for _, w, _ in child)
    L = []
    A = L.append
    A('# DataPath FM「匹配前」钉点 —— 自动生成：scripts/gen_datapath.py（勿手改）')
    A('#')
    A('# 只消 golden 平铺寄存器名与重写件数组名之间的命名鸿沟：')
    A('#   顶层：golden DataPath 的 1,111 个寄存器 ↔ 核 u_core 里的数组元素（映射规则见生成器 top_pin_map，')
    A('#         每个 golden 寄存器必须恰好命中一条规则，否则生成失败）；')
    A('#   子模块：重写的寄存器堆（mem_<i> ↔ u_core/mem_reg[i]，读地址寄存器 ↔ u_core/read_addr_q / raddr_q）')
    A('#         与 WBArbiter（cancelCounter/isFull/hasFull ↔ u_core/cancel_cnt_q/is_full_q/has_full_q）。')
    A('#   RegCache 内部不钉，交给 FM 自动配对。')
    A('# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。')
    A('# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），逐条数返回值；拒一条或总数不等于')
    A('# 字面整数就 error（safe interp 里不用 exit）。进 fm.log 的输出一律 ASCII。')
    A(f'set ::DP_PIN_EXPECT {total}')
    A('set ::DP_PIN_OK 0')
    A('set ::DP_PIN_BAD 0')
    A('proc dp_pin {g i w} {')
    A('  if {$w == 1} {')
    A('    set pairs [list "r:/WORK/DataPath/${g}_reg" "i:/WORK/DataPath/${i}"]')
    A('  } else {')
    A('    set pairs {}')
    A('    for {set b 0} {$b < $w} {incr b} {')
    A('      lappend pairs "r:/WORK/DataPath/${g}_reg\\[$b\\]" "i:/WORK/DataPath/${i}\\[$b\\]"')
    A('    }')
    A('  }')
    A('  foreach {r m} $pairs {')
    A('    if {[set_user_match $r $m]} { incr ::DP_PIN_OK } else {')
    A('      incr ::DP_PIN_BAD')
    A('      if {$::DP_PIN_BAD <= 10} { puts "DP_PIN_FAIL: $r <-> $m" }')
    A('    }')
    A('  }')
    A('}')
    A('# payload：golden 字段寄存器的第 b 位 ↔ u_core/s1_payload_q_reg[off+b]')
    A('proc dp_pin_pl {g off w} {')
    A('  for {set b 0} {$b < $w} {incr b} {')
    A('    if {$w == 1} { set r "r:/WORK/DataPath/${g}_reg" } else { set r "r:/WORK/DataPath/${g}_reg\\[$b\\]" }')
    A('    set m "i:/WORK/DataPath/u_core/s1_payload_q_reg\\[[expr {$off + $b}]\\]"')
    A('    if {[set_user_match $r $m]} { incr ::DP_PIN_OK } else {')
    A('      incr ::DP_PIN_BAD')
    A('      if {$::DP_PIN_BAD <= 10} { puts "DP_PIN_FAIL: $r <-> $m" }')
    A('    }')
    A('  }')
    A('}')
    A('puts "DP_PIN_BEGIN DataPath expect=$::DP_PIN_EXPECT"')
    for reg, w, impl, off in top:
        if impl == 'payload':
            A(f'dp_pin_pl {reg} {off} {w}')
        else:
            A(f'dp_pin {reg} u_core/{tcl_esc(impl)} {w}')
    for reg, w, impl in child:
        A(f'dp_pin {reg} {tcl_esc(impl)} {w}')
    A('puts "DP_PIN_END DataPath ok=$::DP_PIN_OK bad=$::DP_PIN_BAD"')
    A('if {$::DP_PIN_BAD != 0} { error "DP_PIN_MISS=$::DP_PIN_BAD" }')
    A(f'if {{$::DP_PIN_OK != {total}}} {{ error "DP_PIN_COUNT=$::DP_PIN_OK expect={total}" }}')
    return '\n'.join(L) + '\n'


def tcl_esc(s):
    return s.replace('[', '\\[').replace(']', '\\]')


def splice(text, begin_tag, block):
    b = text.index(begin_tag)
    b = text.rindex('\n', 0, b) + 1
    e = text.index('// END GENERATED', b)
    e = text.index('\n', e) + 1
    return text[:b] + block + text[e:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--summary', action='store_true')
    args = ap.parse_args()
    g = Golden()
    M = build_model(g)
    if args.summary:
        for x in M['exus']:
            print(f'e{x.e:2d} {x.kind:3s} {x.i}_{x.j} g{x.g:2d} nsrc={x.nsrc} payload={len(M["payload"][x.e])}f/'
                  f'{sum(w for _, w, _, _ in M["payload"][x.e])}b lddep={M["has_lddep"][x.e]} unc={M["og1_unc"][x.e]}')
        return 0
    txt = RTL.read_text()
    new = splice(txt, 'BEGIN GENERATED(dp_tables)', gen_tables(M))
    new = splice(new, 'BEGIN GENERATED(dp_wrapper)', gen_wrapper(g, M))
    outs = {RTL: new, TB_PATH: gen_tb(g, M), PINS_PATH: gen_pins(g, M)}
    drift = 0
    for path, t in outs.items():
        if path.read_text() != t if path.exists() else True:
            drift += 1
            if args.check:
                print(f'DRIFT {path.relative_to(REPO)}')
            else:
                path.write_text(t)
                print(f'wrote {path.relative_to(REPO)}')
    return 1 if (args.check and drift) else 0


if __name__ == '__main__':
    sys.exit(main())
