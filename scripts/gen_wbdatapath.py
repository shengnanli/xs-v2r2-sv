#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_wbdatapath.py —— WbDataPath 的配置表、golden 同名 wrapper 与 UT tb 生成器。

核是手写的：rtl/backend/WbDataPath.sv 里的 xs_WbDataPath_core。本脚本只产出三块机械件：
  * wbdatapath_pkg 里 `GENERATED(wbdatapath-config)`：每个 EXU 的配置（可写哪些域、每个域取
    data_k 的哪一份、是否不定延迟）与「向量执行口写整数晚一拍」的 EXU 号；
  * `GENERATED(wbdatapath-wrapper)`：golden 同名 wrapper —— 端口表照抄；扁平端口打包进核的
    数组；例化 5 个写回仲裁器与 2 个 VldMergeUnit 并按 golden 连线接好；toCtrlBlock 的 bits
    原样转交；
  * verif/ut/WbDataPath/tb.sv：golden vs 重写件双例化逐拍比全部输出。

★全部从 golden 实测，逐条断言（fail-closed）★：
  - EXU 编号 e = golden 的 fromExu 下标：Int(i,j) → Fp → Vf → Mem，按 (i,j) 升序；
    断言 toCtrlBlock_writeback_e 的每个 bits 字段都等于该 EXU 同名输入（976 条直通逐条核对）；
  - 仲裁器第 k 路 = (域 d, EXU e, data_k 份号)：取自 `<域>ArbiterInputsWire_E_valid & ..._bits_<wen>`
    与 `..._bits_data_s[...]`；断言 wen/pdest/ready 引脚指向同一个 E；
  - 不定延迟 EXU = golden 里 `io_from*_ready = fromExu_E_ready` 的那几个（其余 ready 端口恒 1）；
  - 晚一拍 EXU = golden 里 `intArbiterInputsWire_E_valid = intWrite_REG` 的那个 E；
  - VldMergeUnit 的每个 io_writeback_bits_<f> 都接同一 Mem 口的同名字段，唯一例外 vstart
    接 `{1'h0, io_fromCSR_vstart}`（golden 的 _GEN）。

用法: python3 scripts/gen_wbdatapath.py [--check]
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
CORE = 'rtl/backend/WbDataPath.sv'
TB = 'verif/ut/WbDataPath/tb.sv'
PINS = 'verif/ut/WbDataPath/fm_pins_pre.tcl'
CFG = ('  // BEGIN GENERATED(wbdatapath-config)\n', '  // END GENERATED\n')
WRP = ('// BEGIN GENERATED(wbdatapath-wrapper)\n', '// END GENERATED\n')

DOMS = ['int', 'fp', 'vf', 'v0', 'vl']
DOM_CONST = ['D_INT', 'D_FP', 'D_VEC', 'D_V0', 'D_VL']
DOM_WEN = ['intWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen']     # ExuOutput 字段名
CHK_WEN = ['rfWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen']      # 仲裁器端口字段名
CHK_INST = ['intWbArbiter', 'fpWbArbiter', 'vfWbArbiter', 'v0WbArbiter', 'vlWbArbiter']
PREG = ['toIntPreg', 'toFpPreg', 'toVfPreg', 'toV0Preg', 'toVlPreg']
MAX_SLOT = 6


def die(msg):
    sys.exit('gen_wbdatapath: ERROR: ' + msg)


def norm(s):
    return re.sub(r'\s+', ' ', s).strip()


class Golden:
    def __init__(self):
        t = (GOLDEN / 'WbDataPath.sv').read_text()
        self.body = t[t.index('\nmodule WbDataPath('):]
        hdr = self.body[:self.body.index(');\n')]
        self.port_lines, self.ports = [], {}
        for l in hdr.splitlines():
            if not re.match(r'\s*(input|output)\b', l):
                continue
            l = l.rstrip().rstrip(',')
            m = re.match(r'\s*(input|output)\s*(?:\[(\d+):0\])?\s*(\w+)$', l)
            if not m:
                die('端口行解析失败: %r' % l)
            self.port_lines.append(l)
            self.ports[m[3]] = (m[1], int(m[2]) + 1 if m[2] else 1)
        self.assigns = {}
        for m in re.finditer(r'\n  assign\s+(\w+)\s*=(.*?);', self.body, re.S):
            self.assigns[m[1]] = norm(m[2])
        self.wires = {}
        for m in re.finditer(r'\n  wire\s*(?:\[\d+:0\])?\s*(\w+)\s*=(.*?);', self.body, re.S):
            self.wires[m[1]] = norm(m[2])

    def inst(self, mod_re, name):
        m = re.search(r'\n  (' + mod_re + r') ' + name + r' \((.*?)\n  \);', self.body, re.S)
        if not m:
            die('找不到实例 %s' % name)
        conns = {}
        for a, b in re.findall(r'\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)', m[2]):
            conns[a] = norm(b)
        return m[1], conns


def build_model():
    g = Golden()
    # ---- EXU 表 ----
    exus = {}
    for n, (d, w) in g.ports.items():
        m = re.match(r'io_from(Int|Fp|Vf|Mem)Exu_(\d)_(\d)_(\w+)$', n)
        if m:
            exus.setdefault((m[1], int(m[2]), int(m[3])), {})[m[4]] = (d, w)
    order = []
    for grp in ['Int', 'Fp', 'Vf', 'Mem']:
        order += sorted(k for k in exus if k[0] == grp)
    E = []
    for e, k in enumerate(order):
        f = exus[k]
        pre = 'io_from%sExu_%d_%d' % k
        E.append(dict(e=e, key=k, pre=pre, name='%sExu_%d_%d' % k, fields=f,
                      wen=[('bits_' + w) in f for w in DOM_WEN],
                      nslot=len([x for x in f if re.fullmatch(r'bits_data_\d', x)]),
                      pdest_w=f.get('bits_pdest', ('', 0))[1]))
    num = len(E)
    # toCtrlBlock 直通逐条核对
    passthru = []
    for n, (d, w) in g.ports.items():
        m = re.match(r'io_toCtrlBlock_writeback_(\d+)_(\w+)$', n)
        if not m:
            continue
        e, f = int(m[1]), m[2]
        if e >= num:
            die('toCtrlBlock 下标 %d 超出 EXU 数' % e)
        if f == 'valid':
            continue
        src = g.assigns.get(n)
        want = '%s_%s' % (E[e]['pre'], f)
        if src != want:
            die('%s 不是直通 %s（golden = %r）' % (n, want, src))
        passthru.append((n, want))
    # 不定延迟 / ready 端口
    for x in E:
        rp = x['pre'] + '_ready'
        x['has_ready'] = rp in g.ports
        x['uncertain'] = False
        if x['has_ready']:
            src = g.assigns.get(rp)
            if src == "1'h1":
                pass
            elif src == 'fromExu_%d_ready' % x['e']:
                x['uncertain'] = True
            else:
                die('%s 的驱动看不懂: %r' % (rp, src))
        # toCtrlBlock valid 的形状必须与之吻合
        cv = g.assigns.get('io_toCtrlBlock_writeback_%d_valid' % x['e'])
        want = ('fromExu_%d_ready & %s_valid' % (x['e'], x['pre'])) if x['uncertain'] else x['pre'] + '_valid'
        if cv != want:
            die('toCtrlBlock_writeback_%d_valid = %r，预期 %r' % (x['e'], cv, want))
    # 晚一拍 EXU
    delayed = [int(m[1]) for w, v in g.wires.items()
               for m in [re.fullmatch(r'intArbiterInputsWire_(\d+)_valid', w)] if m and v == 'intWrite_REG']
    if len(delayed) != 1:
        die('晚一拍 EXU 不唯一: %s' % delayed)
    delayed = delayed[0]
    # 仲裁器
    chks = []
    for d in range(5):
        mod, c = g.inst(r'RealWBCollideChecker\w*', CHK_INST[d])
        ks = sorted({int(x) for x in re.findall(r'io_in_(\d+)_valid', ' '.join(c))})
        rows = []
        for k in ks:
            v = c['io_in_%d_valid' % k]
            mm = re.fullmatch(r'%sArbiterInputsWire_(\d+)_valid & %sArbiterInputsWire_\1_bits_%s'
                              % (DOMS[d], DOMS[d], DOM_WEN[d]), v)
            if not mm:
                die('%s io_in_%d_valid 形状不对: %r' % (CHK_INST[d], k, v))
            e = int(mm[1])
            pre = '%sArbiterInputsWire_%d_bits_' % (DOMS[d], e)
            if c.get('io_in_%d_bits_%s' % (k, CHK_WEN[d])) != pre + DOM_WEN[d]:
                die('%s io_in_%d wen 不对' % (CHK_INST[d], k))
            pd = c['io_in_%d_bits_pdest' % k]
            if not re.fullmatch(re.escape(pre + 'pdest') + r'(\[\d+:0\])?', pd):
                die('%s io_in_%d pdest 不对: %r' % (CHK_INST[d], k, pd))
            dm = re.fullmatch(re.escape(pre) + r'data_(\d)(\[\d+:0\])?', c['io_in_%d_bits_data' % k])
            if not dm:
                die('%s io_in_%d data 不对: %r' % (CHK_INST[d], k, c['io_in_%d_bits_data' % k]))
            slot = int(dm[1])
            has_rdy = ('io_in_%d_ready' % k) in c
            if has_rdy and c['io_in_%d_ready' % k] != '%sArbiterInputsWire_%d_ready' % (DOMS[d], e):
                die('%s io_in_%d ready 不对' % (CHK_INST[d], k))
            others = []
            for od in range(5):
                if od == d:
                    continue
                pn = 'io_in_%d_bits_%s' % (k, CHK_WEN[od])
                if pn in c:
                    if c[pn] not in ("1'h0", pre + DOM_WEN[od]):
                        die('%s %s 接 %r' % (CHK_INST[d], pn, c[pn]))
                    others.append((od, c[pn] == "1'h0"))
            rows.append(dict(k=k, e=e, slot=slot, has_rdy=has_rdy, others=others))
        nout = len({int(x) for x in re.findall(r'io_out_(\d+)_valid', ' '.join(c))})
        for j in range(nout):
            for f, want in (('valid', '_%s_io_out_%d_valid' % (CHK_INST[d], j)),
                            ('bits_' + CHK_WEN[d], '_%s_io_out_%d_bits_%s' % (CHK_INST[d], j, CHK_WEN[d])),
                            ('bits_pdest', 'io_%s_%d_addr' % (PREG[d], j)),
                            ('bits_data', 'io_%s_%d_data' % (PREG[d], j))):
                if c.get('io_out_%d_%s' % (j, f)) != want:
                    die('%s io_out_%d_%s 接 %r' % (CHK_INST[d], j, f, c.get('io_out_%d_%s' % (j, f))))
            if g.assigns.get('io_%s_%d_wen' % (PREG[d], j)) != \
                    '_%s_io_out_%d_bits_%s & _%s_io_out_%d_valid' % (CHK_INST[d], j, CHK_WEN[d], CHK_INST[d], j):
                die('%s_%d_wen 形状不对' % (PREG[d], j))
            if g.assigns.get('io_%s_%d_%s' % (PREG[d], j, DOM_WEN[d])) != \
                    '_%s_io_out_%d_bits_%s' % (CHK_INST[d], j, CHK_WEN[d]):
                die('%s_%d_%s 形状不对' % (PREG[d], j, DOM_WEN[d]))
        chks.append(dict(mod=mod, rows=rows, nout=nout))
    # 每个 (d,e) 至多出现一次；写入 EXU 配置
    for x in E:
        x['writes'] = [False] * 5
        x['slot'] = [0] * 5
    for d, ch in enumerate(chks):
        seen = set()
        for r in ch['rows']:
            if r['e'] in seen:
                die('%s 里 EXU %d 出现两次' % (CHK_INST[d], r['e']))
            seen.add(r['e'])
            x = E[r['e']]
            if not x['wen'][d]:
                die('EXU %d 没有 %s 字段却接到了 %s' % (r['e'], DOM_WEN[d], CHK_INST[d]))
            x['writes'][d] = True
            x['slot'][d] = r['slot']
            if r['slot'] >= x['nslot']:
                die('EXU %d 没有 data_%d' % (r['e'], r['slot']))
    # 其余 (d,e) 的 <域>ArbiterInputsWire_E_ready 在 golden 里应为 0（N 组），只核对存在性不强求
    # 向量 load 合并单元
    vlds = []
    i = 0
    while re.search(r'\n  VldMergeUnit vldMgu_%d \(' % i, g.body):
        _, c = g.inst('VldMergeUnit', 'vldMgu_%d' % i)
        mm = re.fullmatch(r'(io_fromMemExu_\d_\d)_valid', c['io_writeback_valid'])
        if not mm:
            die('vldMgu_%d valid 源看不懂' % i)
        pre = mm[1]
        e = [x['e'] for x in E if x['pre'] == pre][0]
        for p, v in c.items():
            m2 = re.fullmatch(r'io_writeback_bits_(\w+)', p)
            if m2:
                if m2[1] == 'vls_vpu_vstart':
                    if v != '_GEN' or g.wires.get('_GEN') != "{1'h0, io_fromCSR_vstart}":
                        die('vldMgu_%d vstart 源看不懂: %r' % (i, v))
                elif v != '%s_bits_%s' % (pre, m2[1]):
                    die('vldMgu_%d %s 接 %r' % (i, p, v))
            m3 = re.fullmatch(r'io_writebackAfterMerge_(\w+)', p)
            if m3 and v != '_vldMgu_%d_io_writebackAfterMerge_%s' % (i, m3[1]):
                die('vldMgu_%d %s 接 %r' % (i, p, v))
        # 合并后的这些字段才是仲裁器看到的（golden: <域>ArbiterInputsWire_E_bits_* = 合并输出）
        for d in range(5):
            if E[e]['writes'][d]:
                w = '%sArbiterInputsWire_%d_bits_%s' % (DOMS[d], e, DOM_WEN[d])
                if g.assigns.get(w) != '_vldMgu_%d_io_writebackAfterMerge_bits_%s' % (i, DOM_WEN[d]) and \
                        g.wires.get(w) != '_vldMgu_%d_io_writebackAfterMerge_bits_%s' % (i, DOM_WEN[d]):
                    die('EXU %d 的 %s 不来自 vldMgu_%d' % (e, w, i))
        vlds.append(dict(i=i, e=e, pre=pre, conns=c))
        E[e]['vld'] = i
        i += 1
    return g, E, chks, vlds, delayed, passthru


# ---------------------------------------------------------------------------
# 包里的配置表
# ---------------------------------------------------------------------------
def config(E, delayed):
    L = []
    L.append('  // EXU 配置（由 scripts/gen_wbdatapath.py 从 golden 实例连线读出；e = toCtrlBlock.writeback 下标）')
    L.append('  //   EXU_WRITES[e]    该口接到了哪些域的仲裁器（位序 {vl,v0,vec,fp,int}）')
    L.append('  //   EXU_DATA_SLOT[e] 写每个域时取 data_k 的哪一份（没接的域写 0，不用）')
    L.append('  //   EXU_UNCERTAIN[e] 不定延迟：ready 取决于仲裁结果（其余口 ready 恒 1）')
    L.append('  localparam int NUM_EXU = %d;' % len(E))
    L.append('  localparam int INT_DELAY_EXU = %d;   // %s：写整数域晚一拍（RegNext/RegEnable）'
             % (delayed, E[delayed]['name']))
    wr, sl, un = [], [], []
    for x in E:
        bits = ''.join('1' if x['writes'][d] else '0' for d in reversed(range(5)))
        wr.append("5'b%s" % bits)
        sl.append("'{%s}" % ', '.join(str(s) for s in x['slot']))
        un.append("1'b%d" % (1 if x['uncertain'] else 0))
    L.append('  //                                     e  口名          写的域')
    L.append('  localparam logic [NUM_DOM-1:0] EXU_WRITES [NUM_EXU] = \'{')
    for x, w in zip(E, wr):
        doms = [DOMS[d] for d in range(5) if x['writes'][d]] or ['-']
        L.append('    %s%s  // %2d %-12s %s' % (w, ',' if x['e'] < len(E) - 1 else ' ', x['e'], x['name'], '/'.join(doms)))
    L.append('  };')
    L.append('  localparam int EXU_DATA_SLOT [NUM_EXU][NUM_DOM] = \'{   // {int, fp, vec, v0, vl}')
    for x, s in zip(E, sl):
        L.append('    %s%s  // %2d %s' % (s, ',' if x['e'] < len(E) - 1 else ' ', x['e'], x['name']))
    L.append('  };')
    L.append('  localparam bit EXU_UNCERTAIN [NUM_EXU] = \'{')
    for x, u in zip(E, un):
        L.append('    %s%s  // %2d %s' % (u, ',' if x['e'] < len(E) - 1 else ' ', x['e'], x['name']))
    L.append('  };')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# wrapper
# ---------------------------------------------------------------------------
def wrapper(g, E, chks, vlds):
    L = []
    L.append('module WbDataPath (')
    L.append(',\n'.join(g.port_lines))
    L.append(');')
    L.append('  import wbdatapath_pkg::*;')
    L.append('')
    L.append('  // 未用输入：reset（golden 只在非综合的 assert 里用）')
    L.append('  logic [NUM_EXU-1:0]                           io_valid, wb_valid, exu_ready, ctrl_valid;')
    L.append('  logic [NUM_EXU-1:0][NUM_DOM-1:0]              wb_wen;')
    L.append('  logic [NUM_EXU-1:0][PDEST_W-1:0]              wb_pdest;')
    L.append('  logic [NUM_EXU-1:0][MAX_SLOT-1:0][DATA_W-1:0] wb_data;')
    L.append('  logic [NUM_DOM-1:0][NUM_EXU-1:0]              chk_valid, chk_wen, chk_ready;')
    L.append('  logic [NUM_DOM-1:0][NUM_EXU-1:0][PDEST_W-1:0] chk_pdest;')
    L.append('  logic [NUM_DOM-1:0][NUM_EXU-1:0][DATA_W-1:0]  chk_data;')
    L.append('  logic [NUM_DOM-1:0][MAX_PORT-1:0]             arb_valid, arb_wen, preg_wen;')
    L.append('')
    # vld 输出线
    for v in vlds:
        L.append('  // %s 的合并后写回（只接仲裁器要读的字段）' % E[v['e']]['name'])
        L.append('  logic         vld%d_valid, vld%d_vecWen, vld%d_v0Wen, vld%d_vlWen;' % ((v['i'],) * 4))
        L.append('  logic [6:0]   vld%d_pdest;' % v['i'])
        L.append('  logic [127:0] vld%d_data_0;' % v['i'])
    L.append('')
    L.append('  // ---- 1. EXU 结果打包进核的数组（golden 没有的字段接 0）----')
    for x in E:
        p = x['pre']
        L.append('  // e=%d %s' % (x['e'], x['name']))
        L.append('  assign io_valid[%d] = %s_valid;' % (x['e'], p))
        if 'vld' in x:
            i = x['vld']
            L.append('  assign wb_valid[%d] = vld%d_valid;   // 经 VldMergeUnit 打一拍' % (x['e'], i))
            wen = ['1\'b0', '1\'b0', 'vld%d_vecWen' % i, 'vld%d_v0Wen' % i, 'vld%d_vlWen' % i]
            for d in range(5):
                if x['wen'][d] and d < 2:
                    die('vld EXU 有 int/fp wen，未处理')
            L.append("  assign wb_wen[%d] = {%s};" % (x['e'], ', '.join(reversed(wen))))
            L.append("  assign wb_pdest[%d] = PDEST_W'(vld%d_pdest);" % (x['e'], i))
            L.append("  assign wb_data[%d] = {%s};" % (x['e'], ', '.join(
                ["DATA_W'(0)"] * (MAX_SLOT - 1) + ['vld%d_data_0' % i])))
            continue
        L.append('  assign wb_valid[%d] = %s_valid;' % (x['e'], p))
        wen = ['%s_bits_%s' % (p, DOM_WEN[d]) if x['wen'][d] else "1'b0" for d in range(5)]
        L.append("  assign wb_wen[%d] = {%s};" % (x['e'], ', '.join(reversed(wen))))
        L.append("  assign wb_pdest[%d] = %s;" % (x['e'], "PDEST_W'(%s_bits_pdest)" % p if x['pdest_w'] else "'0"))
        sl = ["DATA_W'(%s_bits_data_%d)" % (p, s) if s < x['nslot'] else "DATA_W'(0)" for s in range(MAX_SLOT)]
        L.append("  assign wb_data[%d] = {%s};" % (x['e'], ', '.join(reversed(sl))))
    L.append('')
    L.append('  // ---- 2. 向量 load 合并单元（vstart 取 CSR，其余字段接同一 Mem 口）----')
    for v in vlds:
        L.append('  VldMergeUnit vldMgu_%d (' % v['i'])
        cs = []
        for p, val in v['conns'].items():
            if p.startswith('io_writebackAfterMerge_'):
                f = p[len('io_writebackAfterMerge_'):]
                m = {'valid': 'valid', 'bits_data_0': 'data_0', 'bits_pdest': 'pdest',
                     'bits_vecWen': 'vecWen', 'bits_v0Wen': 'v0Wen', 'bits_vlWen': 'vlWen'}.get(f)
                cs.append('    .%s (%s)' % (p, 'vld%d_%s' % (v['i'], m) if m else ''))
            elif p == 'io_writeback_bits_vls_vpu_vstart':
                cs.append("    .%s ({1'b0, io_fromCSR_vstart})" % p)
            else:
                cs.append('    .%s (%s)' % (p, val))
        L.append(',\n'.join(cs))
        L.append('  );')
    L.append('')
    L.append('  // ---- 3. 可读核 ----')
    L.append('  xs_WbDataPath_core u_core (')
    L.append(',\n'.join('    .%s (%s)' % (n, n) for n in
                        ['clock', 'io_valid', 'wb_valid', 'wb_wen', 'wb_pdest', 'wb_data', 'chk_valid',
                         'chk_wen', 'chk_pdest', 'chk_data', 'chk_ready', 'exu_ready', 'ctrl_valid',
                         'arb_valid', 'arb_wen', 'preg_wen']))
    L.append('  );')
    L.append('')
    L.append('  // ---- 4. 五个域的写回仲裁器（第 k 路 <- EXU e，按 golden 连线）----')
    # 授权：先全部置 0（没接到该域 = Scala 的 N 组 ready:=false），再逐路覆盖
    ready_assigns = []
    for d, ch in enumerate(chks):
        W = {0: (8, 64), 1: (8, 64), 2: (7, 128), 3: (5, 128), 4: (5, 8)}[d]
        L.append('  // %s 域：%s' % (DOMS[d], '  '.join('in%d<-e%d' % (r['k'], r['e']) for r in ch['rows'])))
        if any(r['others'] for r in ch['rows']):
            L.append('  // （io_in_*_bits_<别的域 wen> 照 golden 接上，但子模块不读它们）')
        L.append('  %s %s (' % (ch['mod'], CHK_INST[d]))
        cs = []
        for r in sorted(ch['rows'], key=lambda r: -r['k']):
            k, e = r['k'], r['e']
            if r['has_rdy']:
                cs.append('    .io_in_%d_ready (chk_ready[%s][%d])' % (k, DOM_CONST[d], e))
            else:
                ready_assigns.append("  assign chk_ready[%s][%d] = 1'b1;   // 独占一个写口，恒授权" % (DOM_CONST[d], e))
            cs.append('    .io_in_%d_valid (chk_valid[%s][%d])' % (k, DOM_CONST[d], e))
            cs.append('    .io_in_%d_bits_%s (chk_wen[%s][%d])' % (k, CHK_WEN[d], DOM_CONST[d], e))
            for od, is0 in sorted(r['others']):
                src = "1'b0" if is0 else 'wb_wen[%d][%s]' % (e, DOM_CONST[od])
                cs.append('    .io_in_%d_bits_%s (%s)' % (k, CHK_WEN[od], src))
            cs.append('    .io_in_%d_bits_pdest (chk_pdest[%s][%d][%d:0])' % (k, DOM_CONST[d], e, W[0] - 1))
            cs.append('    .io_in_%d_bits_data (chk_data[%s][%d][%d:0])' % (k, DOM_CONST[d], e, W[1] - 1))
        for j in range(ch['nout']):
            cs.append('    .io_out_%d_valid (arb_valid[%s][%d])' % (j, DOM_CONST[d], j))
            cs.append('    .io_out_%d_bits_%s (arb_wen[%s][%d])' % (j, CHK_WEN[d], DOM_CONST[d], j))
            cs.append('    .io_out_%d_bits_pdest (io_%s_%d_addr)' % (j, PREG[d], j))
            cs.append('    .io_out_%d_bits_data (io_%s_%d_data)' % (j, PREG[d], j))
        L.append(',\n'.join(cs))
        L.append('  );')
        if ch['nout'] < 8:
            L.append("  assign arb_valid[%s][%d:%d] = '0;" % (DOM_CONST[d], 7, ch['nout']))
            L.append("  assign arb_wen[%s][%d:%d] = '0;" % (DOM_CONST[d], 7, ch['nout']))
    L.append('')
    L.append('  // 没接到某域仲裁器的位置：授权为 0；独占写口的那几路：恒授权')
    for d, ch in enumerate(chks):
        conn = {r['e'] for r in ch['rows']}
        for e in range(len(E)):
            if e not in conn:
                L.append("  assign chk_ready[%s][%d] = 1'b0;" % (DOM_CONST[d], e))
    L += ready_assigns
    L.append('')
    L.append('  // ---- 5. 输出：写口使能、EXU ready、ROB 通知（bits 原样转交）----')
    for d, ch in enumerate(chks):
        for j in range(ch['nout']):
            L.append('  assign io_%s_%d_wen = preg_wen[%s][%d];' % (PREG[d], j, DOM_CONST[d], j))
            L.append('  assign io_%s_%d_%s = arb_wen[%s][%d];' % (PREG[d], j, DOM_WEN[d], DOM_CONST[d], j))
    for x in E:
        if x['has_ready']:
            L.append('  assign %s_ready = exu_ready[%d];' % (x['pre'], x['e']))
    for x in E:
        L.append('  assign io_toCtrlBlock_writeback_%d_valid = ctrl_valid[%d];' % (x['e'], x['e']))
    return L


def wrapper_text(g, E, chks, vlds, passthru):
    L = wrapper(g, E, chks, vlds)
    L.append('  // toCtrlBlock.writeback[e].bits = 第 e 个 EXU 输入原样（%d 条）' % len(passthru))
    for n, src in passthru:
        L.append('  assign %s = %s;' % (n, src))
    L.append('endmodule')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
def tb(g, E, delayed):
    L = []
    L.append('// ' + '=' * 76)
    L.append('// tb —— WbDataPath UT：golden 与重写件（连同全部子模块的 golden / 重写版本）逐拍双例化比对。')
    L.append('//')
    L.append('// 激励：每个 EXU 口 valid 约 1/2，各写使能约 1/2（按口独立），其余字段每拍全随机；')
    L.append('// flush 约 1/4。无复位的寄存器（VfExe→Int 那一拍、VldMergeUnit）先灌 4 拍全 valid 再比。')
    L.append('// 覆盖（未满足即 TEST FAILED）：5 个域每个写口都真写过；4 个不定延迟口的 ready 取遍 0/1；')
    L.append('// 晚一拍那一路在整数仲裁器里赢过。')
    L.append('//')
    L.append('// 本文件由 scripts/gen_wbdatapath.py 生成，勿手改。')
    L.append('// ' + '=' * 76)
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit clock = 0; always #5 clock = ~clock;')
    L.append('  longint errors = 0, checks = 0;')
    L.append('  `define CK(g, i, nm) \\')
    L.append('    begin checks++; if ((g) !== (i)) begin errors++; \\')
    L.append('      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \\')
    L.append('    end end')
    ins = [(n, w) for n, (d, w) in g.ports.items() if d == 'input' and n != 'clock']
    outs = [(n, w) for n, (d, w) in g.ports.items() if d == 'output']
    for n, w in ins:
        L.append('  logic [%d:0] %s;' % (w - 1, n))
    for n, w in outs:
        L.append('  logic [%d:0] g_%s, i_%s;' % (w - 1, n, n))
    for side, mod in (('g', 'WbDataPath'), ('i', 'WbDataPath_xs')):
        L.append('  %s u_%s (' % (mod, side))
        cs = ['    .clock (clock)']
        for n, w in ins:
            cs.append('    .%s (%s)' % (n, n))
        for n, w in outs:
            cs.append('    .%s (%s_%s)' % (n, side, n))
        L.append(',\n'.join(cs))
        L.append('  );')
    L.append('')
    L.append('  bit warm;')
    L.append('  task automatic drive();')
    for n, w in ins:
        if re.fullmatch(r'io_from\w+Exu_\d_\d_valid', n):
            L.append("    %s = warm | ($urandom_range(0, 1) == 1);" % n)
        elif n == 'io_flush_valid':
            L.append("    %s = !warm && ($urandom_range(0, 3) == 0);" % n)
        elif n == 'reset':
            L.append("    reset = 1'b0;")
        else:
            chunks = (w + 31) // 32
            L.append('    %s = %d\'({%s});' % (n, w, ', '.join(['$urandom'] * chunks)))
    L.append('  endtask')
    L.append('')
    L.append('  task automatic compare();')
    for n, w in outs:
        L.append('    `CK(g_%s, i_%s, "%s")' % (n, n, n))
    L.append('  endtask')
    L.append('')
    # 覆盖
    L.append('  longint cov_wen [5][8];')
    L.append('  longint cov_rdy0 [%d], cov_rdy1 [%d];' % (len(E), len(E)))
    L.append('  longint cov_dly = 0;')
    L.append('  task automatic sample_cov();')
    for d in range(5):
        for j in range(8):
            n = 'io_%s_%d_wen' % (PREG[d], j)
            if n in g.ports:
                L.append('    if (g_%s) cov_wen[%d][%d]++;' % (n, d, j))
    unc = [x for x in E if x['uncertain']]
    for x in unc:
        L.append('    if (%s_valid) begin if (g_%s_ready) cov_rdy1[%d]++; else cov_rdy0[%d]++; end'
                 % (x['pre'], x['pre'], x['e'], x['e']))
    L.append('    if (u_i.chk_valid[0][%d] && u_i.chk_ready[0][%d]) cov_dly++;   // 晚一拍那一路赢了' % (delayed, delayed))
    L.append('  endtask')
    L.append('')
    L.append('  initial begin')
    L.append('    bit ok;')
    L.append('    void\'($value$plusargs("ncycles=%d", NCYCLES));')
    L.append('    for (int unsigned cyc = 0; cyc < NCYCLES; cyc++) begin')
    L.append('      warm = (cyc < 4);')
    L.append('      drive();')
    L.append('      #1;')
    L.append('      if (cyc >= 5) compare();')
    L.append('      sample_cov();')
    L.append('      @(posedge clock); #1;')
    L.append('    end')
    L.append('    ok = 1;')
    for d in range(5):
        for j in range(8):
            if ('io_%s_%d_wen' % (PREG[d], j)) in g.ports:
                L.append('    if (cov_wen[%d][%d] == 0) begin ok = 0; $display("COVER-MISS %s_%d never written"); end'
                         % (d, j, PREG[d], j))
    for x in unc:
        L.append('    if (cov_rdy0[%d] == 0 || cov_rdy1[%d] == 0) begin ok = 0; $display("COVER-MISS %s ready not toggled"); end'
                 % (x['e'], x['e'], x['name']))
    L.append('    if (cov_dly == 0) begin ok = 0; $display("COVER-MISS delayed int path never won"); end')
    L.append('    $display("COVER uncertain_ready0:%s", %s);' % (
        ''.join(' %0d' for _ in unc), ', '.join('cov_rdy0[%d]' % x['e'] for x in unc)))
    L.append('    $display("checks=%0d errors=%0d cover=%0d", checks, errors, ok);')
    L.append('    if (errors == 0 && ok) $display("TEST PASSED");')
    L.append('    else $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# FM 匹配前钉点：两个 VldMergeUnit 实例的 wbReg（golden 逐字段寄存器 <-> 重写核的 packed struct）
# ---------------------------------------------------------------------------
def pins(vlds):
    sys.path.insert(0, str(REPO / 'scripts'))
    from gen_vldmergeunit import field_path
    t = (GOLDEN / 'VldMergeUnit.sv').read_text()
    regs = []
    for m in re.finditer(r'\n  reg\s*(?:\[(\d+):0\])?\s*wbReg_bits_(\w+);', t):
        regs.append((m[2], int(m[1]) + 1 if m[1] else 1))
    if not regs:
        die('VldMergeUnit golden 里没找到 wbReg_bits_* 寄存器')
    rows = []
    for f, w in regs:
        path = field_path(f)                       # 例 vls.vpu.vmask / exceptionVec[3]
        m = re.fullmatch(r'(\w+)\[(\d+)\]', path)
        if m:                                      # exceptionVec_N：结构体里是 [23:0] 向量的第 N 位
            if w != 1:
                die('%s 宽度 %d != 1' % (f, w))
            rows.append((f, '\\[%s][%s]' % (m[1], m[2]), 1, True))
        else:
            rows.append((f, ''.join('\\[%s]' % s for s in path.split('.')), w, False))
    total = sum(w for _, _, w, _ in rows) * len(vlds)
    L = []
    L.append('# WbDataPath FM「匹配前」钉点 —— 自动生成：scripts/gen_wbdatapath.py（勿手改）')
    L.append('#')
    L.append('# 只消名差：两个 VldMergeUnit 实例里，golden 的 wbReg 是逐字段寄存器 wbReg_bits_<f>_reg，')
    L.append('# 重写核是一个 packed struct 寄存器 u_core/wb_bits_reg\\[..]\\[..]。其中大部分位在 WbDataPath')
    L.append('# 里没有读者（合并单元只把 valid/data/pdest/3 个 wen 交给仲裁器），FM 的签名分析配不上')
    L.append('# 无扇出的寄存器 —— 不钉就是两侧各 1904 个 unmatched unread。')
    L.append('# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。')
    L.append('# fail-closed：逐条数返回值，拒一条或总数不等于字面整数就 error。进 fm.log 的输出一律 ASCII。')
    L.append('set ::WBDP_PIN_EXPECT %d' % total)
    L.append('set ::WBDP_PIN_OK 0')
    L.append('set ::WBDP_PIN_BAD 0')
    L.append('proc wbdp_pin {inst g i w} {')
    L.append('  set pairs {}')
    L.append('  if {$w == 1} {')
    L.append('    lappend pairs "r:/WORK/WbDataPath/$inst/wbReg_bits_${g}_reg" "i:/WORK/WbDataPath/$inst/u_core/wb_bits_reg$i"')
    L.append('  } else {')
    L.append('    for {set b 0} {$b < $w} {incr b} {')
    L.append('      lappend pairs "r:/WORK/WbDataPath/$inst/wbReg_bits_${g}_reg\\[$b\\]" "i:/WORK/WbDataPath/$inst/u_core/wb_bits_reg$i\\[$b\\]"')
    L.append('    }')
    L.append('  }')
    L.append('  foreach {r m} $pairs {')
    L.append('    if {[set_user_match $r $m]} { incr ::WBDP_PIN_OK } else {')
    L.append('      incr ::WBDP_PIN_BAD')
    L.append('      if {$::WBDP_PIN_BAD <= 10} { puts "WBDP_PIN_FAIL: $r <-> $m" }')
    L.append('    }')
    L.append('  }')
    L.append('}')
    L.append('puts "WBDP_PIN_BEGIN WbDataPath expect=$::WBDP_PIN_EXPECT"')
    for v in vlds:
        for f, ipath, w, idx in rows:
            L.append('wbdp_pin vldMgu_%d %s {%s} %d' % (v['i'], f, ipath, w))
    L.append('puts "WBDP_PIN_END WbDataPath ok=$::WBDP_PIN_OK bad=$::WBDP_PIN_BAD"')
    L.append('if {$::WBDP_PIN_BAD != 0} { error "WBDP_PIN_MISS=$::WBDP_PIN_BAD" }')
    L.append('if {$::WBDP_PIN_OK != %d} { error "WBDP_PIN_COUNT=$::WBDP_PIN_OK expect=%d" }' % (total, total))
    return '\n'.join(L) + '\n'


def splice(text, marks, new):
    b, e = marks
    if text.count(b) != 1:
        die('GENERATED 起始标记不唯一: %r' % b)
    head, rest = text.split(b)
    idx = rest.index(e)
    return head + b + new + rest[idx:]


def build():
    g, E, chks, vlds, delayed, passthru = build_model()
    text = (REPO / CORE).read_text()
    text = splice(text, CFG, config(E, delayed))
    text = splice(text, WRP, wrapper_text(g, E, chks, vlds, passthru))
    return {CORE: text, TB: tb(g, E, delayed), PINS: pins(vlds)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    files = build()
    drift = []
    for rel, text in sorted(files.items()):
        p = REPO / rel
        old = p.read_text() if p.exists() else None
        if old == text:
            continue
        if a.check:
            drift.append(rel)
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
    if a.check:
        if drift:
            print('DRIFT: %d 个产物与生成器不一致：' % len(drift))
            for d in drift:
                print('  ' + d)
            return 1
        print('gen_wbdatapath: %d 个产物与生成器一致' % len(files))
        return 0
    print('gen_wbdatapath: 写出/校验 %d 个文件' % len(files))
    return 0


if __name__ == '__main__':
    sys.exit(main())
