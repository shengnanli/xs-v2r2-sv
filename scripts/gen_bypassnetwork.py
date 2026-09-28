#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_bypassnetwork.py —— BypassNetwork 的机械派生区生成器（核 xs_BypassNetwork_core 是手写的）。

产出（均为 G1 golden 的机械变换，★每一条都有断言，对不上当场退出★）：
  (1) rtl/backend/BypassNetwork.sv 的 GENERATED(bypassnetwork_cfg)：每-EXU 配置表 EXU_CFG。
      不是抄来的：逐个解析 golden 里 27 个 EXU、71 个 io_toExus_*_bits_src_* 的 Mux1H 展开式，
      把每一项归类为 FORWARD/BYPASS(哪个旁路组)/REG/REGCACHE/IMM(哪个 ImmExtractor 变体或
      load 内联 U 型)/V0，再要求同一 EXU 的所有源服从同一行配置（v0 只在 src0..2、load U 型只在
      src0）。任何一项对不上 = golden 结构与核的模型不符，拒绝生成。
  (2) 同文件的 GENERATED(bypassnetwork_wrapper)：golden 同名 wrapper。端口表逐行照抄 golden
      （端口契约闸 PORTLINT_ORDER=fail），输入按核的数组接口打包，输出拆包；其余 855 个
      ExuInput 字段直连（toExus.X = fromDataPath.X），ready 反向直连——这两类也逐条核对
      golden 的 assign 原文，不是按名字猜。
  (3) verif/ut/BypassNetwork/tb.sv：双例化 UT（golden vs BypassNetwork_xs）。
  (4) verif/ut/BypassNetwork/fm_pins_pre.tcl：FM「匹配前」钉点，只消寄存器名差
      （golden bypassDataVec_r_<pos> / bypassIntWenVec_last_REG_<k> vs 核 byp_data[p][b] / rcw_wen[k]）。
      依据（实测）：不钉时 FM 签名分析把 byp_data[1]/[3] 配错（evidence/876a9668*，unmatched 128(128)、
      至少 20 个 failing 全落在 byp_data_reg[2]）。fail-closed：逐条数 set_user_match 返回值，
      拒一条或总数 != 字面 647 即 error。fp0 的 golden 高 64 位无 impl 对应（golden-only 死位），不钉。

用法: python3 scripts/gen_bypassnetwork.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（gate_all.sh 的幂等闸）。
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))
RTL = REPO / 'rtl' / 'backend' / 'BypassNetwork.sv'
TB = REPO / 'verif' / 'ut' / 'BypassNetwork' / 'tb.sv'
PINS = REPO / 'verif' / 'ut' / 'BypassNetwork' / 'fm_pins_pre.tcl'

GROUP_ORDER = ['int', 'fp', 'vf', 'mem']
# 旁路源：核里 P_* 的顺序 -> golden fromExus 名；以及 forwardOrBypassValidVec3 的 27 位位置
PRODUCERS = [('P_INT0', 'int_0_0', 0), ('P_INT1', 'int_1_0', 2), ('P_INT2', 'int_2_0', 4),
             ('P_INT3', 'int_3_0', 6), ('P_FP0', 'fp_0_0', 8), ('P_FP1', 'fp_1_0', 10),
             ('P_FP2', 'fp_2_0', 12), ('P_MEM2', 'mem_2_0', 20), ('P_MEM3', 'mem_3_0', 21),
             ('P_MEM4', 'mem_4_0', 22)]
INT_GRP_POS = [0, 2, 4, 6, 20, 21, 22]
FP_GRP_POS = [8, 10, 12]
RCW_PROD = ['int_0_0', 'int_1_0', 'int_2_0', 'int_3_0', 'mem_2_0', 'mem_3_0', 'mem_4_0']
IMM_KIND = {'ImmExtractor': 'IMM_EXT', 'ImmExtractor_2': 'IMM_EXT_2',
            'ImmExtractor_12': 'IMM_EXT_12', 'ImmExtractor_37': 'IMM_EXT_37',
            'ImmExtractor_57': 'IMM_EXT_57'}


def die(msg):
    raise SystemExit('gen_bypassnetwork: ' + msg)


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
def load_golden():
    t = (GOLDEN / 'BypassNetwork.sv').read_text()
    body = t[t.index('\nmodule BypassNetwork('):]
    body = body[:body.index('\nendmodule') + 1]
    head = body[:body.index(');\n')]
    port_lines = [l for l in head.splitlines() if re.match(r'\s*(input|output)\b', l)]
    ports = []
    for l in port_lines:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', l)
        if not m:
            die('端口行解析失败: ' + l)
        ports.append((m.group(1), int(m.group(2)) + 1 if m.group(2) else 1, m.group(3)))
    assigns = {}
    for k, v in re.findall(r'\n  assign (\w+)\s*=\s*(.*?);', body, re.S):
        if k in assigns:
            die('重复 assign ' + k)
        assigns[k] = re.sub(r'\s+', ' ', v).strip()
    wires = dict((k, re.sub(r'\s+', ' ', v).strip())
                 for k, v in re.findall(r'\n  wire\s+(?:\[\d+:0\]\s+)?(\w+)\s*=\s*(.*?);', body, re.S))
    insts = dict((n, m) for m, n in re.findall(r'\n  (\w+) (\w+) \(', body))
    inst_in = dict(re.findall(r'\n  \w+ (\w+) \(\s*\.io_in\s+\((\w+)\[', body))
    imm_in = dict((n, (a, b)) for n, a, b in re.findall(
        r'\n  ImmExtractor\w* (\w+) \(\s*\.io_in_imm\s+\((\w+)\),\s*\.io_in_immType\s+\((\w+)\)', body))
    return body, ports, port_lines, assigns, wires, insts, inst_in, imm_in


def split_top(e, op='|'):
    out, d, cur = [], 0, ''
    for ch in e:
        if ch == '(':
            d += 1
        elif ch == ')':
            d -= 1
        if ch == op and d == 0:
            out.append(cur.strip())
            cur = ''
        else:
            cur += ch
    out.append(cur.strip())
    return out


def strip_paren(e):
    e = e.strip()
    while e.startswith('(') and e.endswith(')'):
        d = 0
        for i, ch in enumerate(e):
            d += (ch == '(') - (ch == ')')
            if d == 0 and i < len(e) - 1:
                return e
        e = e[1:-1].strip()
    return e


def build():
    body, ports, port_lines, A, W, INST, INST_IN, IMM_IN = load_golden()
    pw = dict((n, w) for _, w, n in ports)
    pdir = dict((n, d) for d, _, n in ports)

    # ---- EXU 列表（顺序 = exuIdx）----
    exus = []
    for g in GROUP_ORDER:
        found = sorted(((int(i), int(j)) for i, j in
                        re.findall(r'^io_toExus_%s_(\d+)_(\d+)_valid$' % g, '\n'.join(pw), re.M)))
        exus += ['%s_%d_%d' % (g, i, j) for i, j in found]
    if len(exus) != 27:
        die('EXU 数 %d != 27' % len(exus))

    # forward/bypass 数据名 -> 生产者位置
    pos_fwd = {}
    pos_byp = {}
    for pn, ex, pos in PRODUCERS:
        pos_fwd[pos] = 'io_fromExus_%s_bits_data' % ex
        pos_byp[pos] = 'bypassDataVec_r' + ('' if pos == 0 else '_%d' % pos)
        if pos_fwd[pos] not in pw:
            die('缺旁路源端口 ' + pos_fwd[pos])

    def ext_owner(ext):
        """_forwardOrBypassValidVec3_ext_K -> (exu, src)：由它的 io_in 来自哪个 exuSources。"""
        inst = ext[1:]  # 去掉前导下划线
        wire = INST_IN.get(inst) or die('找不到 ext 实例输入 ' + inst)
        m = re.match(r"\d+'h1 << io_fromDataPath_(\w+?)_bits_exuSources_(\d)_value$", W.get(wire, ''))
        if not m:
            die('ext 输入不是 1<<exuSources: %s = %s' % (wire, W.get(wire)))
        return m.group(1), int(m.group(2))

    def cls(term, exu, s):
        term = strip_paren(term)
        m = re.match(r"(.*?) \? (.*) : \d+'h0$", term)
        if not m:
            die('%s src%d 非 cond?x:0 项: %s' % (exu, s, term[:120]))
        cond, val = m.group(1).strip(), m.group(2).strip()
        mv = re.match(r"io_fromDataPath_%s_bits_dataSources_%d_value == 4'h(\w)(.*)$" % (exu, s), cond)
        if not mv:
            mr = re.match(r'(readRegOH_\d+)$', cond)
            if mr and A.get(mr.group(1)) == \
                    "io_fromDataPath_%s_bits_dataSources_%d_value == 4'h8" % (exu, s):
                code, extra = '8', ''
            else:
                die('%s src%d 条件不认识: %s' % (exu, s, cond))
        else:
            code, extra = mv.group(1), mv.group(2).strip()
        if code in '12':
            if extra:
                die('%s src%d fwd/byp 条件带附加项' % (exu, s))
            pos_map = pos_fwd if code == '1' else pos_byp
            items = [strip_paren(x) for x in split_top(val)]
            poss, ext_set = [], set()
            for it in items:
                mi = re.match(r"(_forwardOrBypassValidVec3_ext(?:_\d+)?)_io_out\[(\d+)\] \? (\w+)(\[63:0\])? : 64'h0$", it)
                if not mi:
                    die('%s src%d fwd/byp 子项不认识: %s' % (exu, s, it))
                pos = int(mi.group(2))
                if pos_map.get(pos) != mi.group(3):
                    die('%s src%d 位置 %d 数据 %s != 期望 %s' % (exu, s, pos, mi.group(3), pos_map.get(pos)))
                poss.append(pos)
                ext_set.add(mi.group(1))
            if len(ext_set) != 1 or ext_owner(ext_set.pop()) != (exu, s):
                die('%s src%d 的 one-hot 不来自本源的 exuSources' % (exu, s))
            if poss == INT_GRP_POS:
                return ('FWD' if code == '1' else 'BYP', 'FWD_INT')
            if poss == FP_GRP_POS:
                return ('FWD' if code == '1' else 'BYP', 'FWD_FP')
            die('%s src%d 旁路组位置 %s 不是整数组/浮点组' % (exu, s, poss))
        if code == '8':
            if extra or val != 'io_fromDataPath_%s_bits_src_%d' % (exu, s):
                die('%s src%d REG 项异常: %s' % (exu, s, val))
            return ('REG', None)
        if code == '6':
            if extra or not re.match(r'io_fromDataPath_rcData_\d+_\d+_\d+$', val):
                die('%s src%d RC 项异常: %s' % (exu, s, val))
            return ('RC', val)
        if code == '4':
            mi = re.match(r'(_imm_mod(?:_\d+)?)_io_out_imm(\[63:0\])?$', val)
            if mi:
                inst = mi.group(1)[1:]
                return ('IMM', (INST[inst], IMM_IN[inst]))
            e_idx = exus.index(exu)
            load = ("{{32{io_fromDataPath_immInfo_%d_imm[31]}}, io_fromDataPath_immInfo_%d_imm[31:12], 12'h0}"
                    % (e_idx, e_idx))
            if val == load and s == 0:
                return ('IMM', ('LOAD_U', None))
            die('%s src%d IMM 项不认识: %s' % (exu, s, val))
        if code == '5':
            src3 = 'io_toExus_%s_bits_src_3' % exu
            ok = (val == A.get(src3)) or \
                 (extra.startswith('& readRegOH_') and
                  A.get(extra[2:]) == "io_fromDataPath_%s_bits_dataSources_3_value == 4'h8" % exu and
                  val == 'io_fromDataPath_%s_bits_src_3' % exu and
                  A.get(src3) == '%s ? io_fromDataPath_%s_bits_src_3 : 128\'h0' % (extra[2:], exu))
            if not ok:
                die('%s src%d V0 项不是"已选好的 src3": %s %s' % (exu, s, val, extra))
            return ('V0', None)
        die('%s src%d 未知码 %s' % (exu, s, code))

    cfg, rc_name = [], {}
    handled = set()
    for e, exu in enumerate(exus):
        srcs = sorted(int(x) for x in re.findall(r'^io_toExus_%s_bits_src_(\d)$' % exu, '\n'.join(pw), re.M))
        if srcs != list(range(len(srcs))) or not srcs:
            die('%s 源编号不连续 %s' % (exu, srcs))
        wide = {pw['io_toExus_%s_bits_src_%d' % (exu, s)] for s in srcs}
        if len(wide) != 1 or wide.pop() not in (64, 128):
            die('%s 源宽度不一致' % exu)
        is_wide = pw['io_toExus_%s_bits_src_0' % exu] == 128
        per_src = []
        for s in srcs:
            name = 'io_toExus_%s_bits_src_%d' % (exu, s)
            e_ = A[name]
            if e_.startswith('_io_'):
                e_ = A[e_]
            terms = [cls(x, exu, s) for x in split_top(e_)]
            kinds = [k for k, _ in terms]
            if len(kinds) != len(set(kinds)):
                die('%s src%d 同类项重复' % (exu, s))
            per_src.append(dict(terms))
            handled.add(name)
        fwd = {p.get('FWD') for p in per_src}
        if len(fwd) != 1 or {p.get('BYP') for p in per_src} != fwd:
            die('%s 各源旁路组不一致' % exu)
        fwd = fwd.pop() or 'FWD_NONE'
        rc = [p.get('RC') for p in per_src]
        has_rc = all(rc)
        if any(rc) and not has_rc:
            die('%s RegCache 只部分源有' % exu)
        for s, r in enumerate(rc):
            if r:
                rc_name[(e, s)] = r
        imms = {p.get('IMM') for p in per_src}
        if len(imms) != 1:
            die('%s 各源立即数来源不一致 %s' % (exu, imms))
        imm = imms.pop()
        if imm is None:
            imm_kind = 'IMM_NONE'
        elif imm[0] == 'LOAD_U':
            imm_kind = 'IMM_LOAD_U'
        else:
            imm_kind = IMM_KIND.get(imm[0]) or die('%s 未知 ImmExtractor 变体 %s' % (exu, imm[0]))
            if imm[1] != ('io_fromDataPath_immInfo_%d_imm' % e, 'io_fromDataPath_immInfo_%d_immType' % e):
                die('%s 立即数模块输入不是 immInfo_%d' % (exu, e))
        v0 = [('V0' in p) for p in per_src]
        has_v0 = any(v0)
        if has_v0 and v0 != [s < 3 for s in srcs]:
            die('%s v0 分布不是 src0..2: %s' % (exu, v0))
        for s, p in enumerate(per_src):
            if 'REG' not in p:
                die('%s src%d 缺 REG 项' % (exu, s))
        bju = ('io_toExus_%s_bits_nextPcOffset' % exu) in pw
        if bju:
            iv = A['io_toExus_%s_bits_imm' % exu]
            mi = re.match(r"64'\((_imm_mod_\d+)_io_out_imm(\[63:0\])? \+ \{59'h0, "
                          r"io_fromDataPath_%s_bits_fuType\[0\] & io_fromDataPath_%s_bits_fuOpType\[0\] "
                          r"\? 5'h0 : \{io_fromDataPath_%s_bits_ftqOffset, 1'h0\}\}\)$" % (exu, exu, exu), iv)
            if not mi or IMM_KIND.get(INST[mi.group(1)[1:]]) != imm_kind or \
                    IMM_IN[mi.group(1)[1:]][0] != 'io_fromDataPath_immInfo_%d_imm' % e:
                die('%s BJU imm 表达式不符: %s' % (exu, iv))
            nv = A['io_toExus_%s_bits_nextPcOffset' % exu]
            if nv != ("5'({1'h0, io_fromDataPath_%s_bits_ftqOffset} + {3'h0, "
                      "io_fromDataPath_%s_bits_preDecode_isRVC ? 2'h1 : 2'h2})" % (exu, exu)):
                die('%s nextPcOffset 表达式不符: %s' % (exu, nv))
            handled |= {'io_toExus_%s_bits_imm' % exu, 'io_toExus_%s_bits_nextPcOffset' % exu}
        cfg.append(dict(exu=exu, num_src=len(srcs), fwd=fwd, rc=has_rc, imm=imm_kind,
                        v0=has_v0, wide=is_wide, bju=bju))

    # ---- 旁路寄存器与 RegCache 写口：核对 golden 原文 ----
    for pn, ex, pos in PRODUCERS:
        r = pos_byp[pos]
        want = 'if (io_fromExus_%s_valid) %s <= io_fromExus_%s_bits_data;' % (ex, r, ex)
        if want not in re.sub(r'\s+', ' ', body):
            die('bypass 寄存器不符: ' + want)
    flat = re.sub(r'\s+', ' ', body)
    for k, ex in enumerate(RCW_PROD):
        reg = 'bypassIntWenVec_last_REG' + ('' if k == 0 else '_%d' % k)
        pos = dict((x, p) for _, x, p in PRODUCERS)[ex]
        if A.get('io_toDataPath_%d_wen' % k) != reg or A.get('io_toDataPath_%d_data' % k) != pos_byp[pos]:
            die('RegCache 写口 %d 连接不符' % k)
        if ('%s <= io_fromExus_%s_valid & io_fromExus_%s_bits_intWen;' % (reg, ex, ex)) not in flat \
                or ('%s <= 1\'h0;' % reg) not in flat:
            die('RegCache wen 寄存器 %d 不符' % k)
        handled |= {'io_toDataPath_%d_wen' % k, 'io_toDataPath_%d_data' % k}
    if 'io_toDataPath_7_wen' in pw:
        die('RegCache 写口多于 7 个')

    # ---- 其余输出：直连 / ready ----
    passthru, ready = [], []
    for d, w, n in ports:
        if d != 'output' or n in handled:
            continue
        rhs = A.get(n)
        if n.startswith('io_fromDataPath_') and n.endswith('_ready'):
            want = n.replace('io_fromDataPath_', 'io_toExus_')
            if rhs != want or pdir.get(want) != 'input':
                die('ready 不是反向直连: %s = %s' % (n, rhs))
            ready.append(n)
        elif n.startswith('io_toExus_'):
            want = n.replace('io_toExus_', 'io_fromDataPath_')
            if rhs != want or pw.get(want) != w:
                die('输出不是同名直连: %s = %s' % (n, rhs))
            passthru.append(n)
        else:
            die('未分类输出 ' + n)
    return dict(ports=ports, port_lines=port_lines, pw=pw, exus=exus, cfg=cfg, rc_name=rc_name,
                passthru=passthru, ready=ready)


# ---------------------------------------------------------------------------
# 发射
# ---------------------------------------------------------------------------
def b(x):
    return "1'b1" if x else "1'b0"


def emit_cfg(G):
    o = ['  // 由 scripts/gen_bypassnetwork.py 从 G1 golden 的逐源 Mux1H 展开式解析得到（勿手改）。',
         '  // 列：num_src / 旁路组 / RegCache / 立即数来源 / v0 / 128 位 / BJU',
         '  localparam exu_cfg_t EXU_CFG [NUM_EXU] = \'{']
    for e, c in enumerate(G['cfg']):
        sep = ',' if e < len(G['cfg']) - 1 else ' '
        o.append("    '{3'd%d, %-8s, %s, %-10s, %s, %s, %s}%s  // %2d %s"
                 % (c['num_src'], c['fwd'], b(c['rc']), c['imm'], b(c['v0']), b(c['wide']),
                    b(c['bju']), sep, e, c['exu']))
    o.append('  };')
    return '\n'.join(o)


def emit_wrapper(G):
    pw, exus, cfg = G['pw'], G['exus'], G['cfg']
    o = ['// =============================================================================',
         '// BypassNetwork —— golden 同名 wrapper（由 scripts/gen_bypassnetwork.py 生成，勿手改）',
         '// 端口逐行照抄 G1 golden；输入打包成核的数组接口，输出拆包；其余 ExuInput 字段直连。',
         '// =============================================================================',
         'module BypassNetwork',
         '  import bypassnetwork_pkg::*;',
         '(']
    pl = G['port_lines']
    for i, l in enumerate(pl):
        l = l.rstrip().rstrip(',')
        o.append(l + (',' if i < len(pl) - 1 else ''))
    o.append(');')
    o += ['',
          '  // ---- 核的数组接口 ----',
          '  logic [NUM_PROD-1:0]           prod_valid;',
          '  logic [NUM_PROD-1:0][XLEN-1:0] prod_data;',
          '  logic [NUM_RCW-1:0]            rcw_intWen;',
          '  logic [3:0]                    ds       [NUM_EXU][MAX_SRC];',
          '  logic [2:0]                    exu_src  [NUM_EXU][MAX_SRC];',
          '  logic [VLEN-1:0]               reg_data [NUM_EXU][MAX_SRC];',
          '  logic [XLEN-1:0]               rc_data  [NUM_EXU][MAX_SRC];',
          '  logic [31:0]                   imm_raw  [NUM_EXU];',
          '  logic [3:0]                    imm_type [NUM_EXU];',
          '  logic                          is_jump  [NUM_EXU];',
          '  logic                          op_jalr  [NUM_EXU];',
          '  logic [3:0]                    ftq_off  [NUM_EXU];',
          '  logic                          is_rvc   [NUM_EXU];',
          '  logic [VLEN-1:0]               src_out  [NUM_EXU][MAX_SRC];',
          '  logic [XLEN-1:0]               bju_imm  [NUM_EXU];',
          '  logic [4:0]                    bju_npc_off [NUM_EXU];',
          '  logic [NUM_RCW-1:0]            rcw_wen;',
          '  logic [NUM_RCW-1:0][XLEN-1:0]  rcw_data;',
          '',
          '  // ---- 旁路源 ----']
    for pn, ex, pos in PRODUCERS:
        d = 'io_fromExus_%s_bits_data' % ex
        o.append('  assign prod_valid[%s] = io_fromExus_%s_valid;' % (pn, ex))
        o.append('  assign prod_data[%s]  = %s%s;' % (pn, d, '[63:0]' if pw[d] > 64 else ''))
    for k, ex in enumerate(RCW_PROD):
        o.append('  assign rcw_intWen[%d] = io_fromExus_%s_bits_intWen;' % (k, ex))
    o.append('')
    o.append('  // ---- 消费者：逐 EXU、逐源（该 EXU 没有的源/字段接 0）----')
    for e, exu in enumerate(exus):
        c = cfg[e]
        o.append('  // %d: %s' % (e, exu))
        for s in range(5):
            ds = 'io_fromDataPath_%s_bits_dataSources_%d_value' % (exu, s)
            xs = 'io_fromDataPath_%s_bits_exuSources_%d_value' % (exu, s)
            rg = 'io_fromDataPath_%s_bits_src_%d' % (exu, s)
            has = s < c['num_src']
            if has and ds not in pw:
                die('缺 ' + ds)
            o.append('  assign ds[%d][%d]       = %s;' % (e, s, ds if has else "4'h0"))
            if xs in pw:
                if not has or c['fwd'] == 'FWD_NONE':
                    die('多出的 exuSources ' + xs)
                o.append('  assign exu_src[%d][%d]  = 3\'(%s);' % (e, s, xs))
            else:
                if has and c['fwd'] != 'FWD_NONE':
                    die('缺 ' + xs)
                o.append("  assign exu_src[%d][%d]  = 3'h0;" % (e, s))
            if has and pw[rg] != (128 if c['wide'] else 64):
                die('宽度不符 ' + rg)
            o.append('  assign reg_data[%d][%d] = %s;' % (e, s, ('VLEN\'(%s)' % rg) if has else "'0"))
            rc = G['rc_name'].get((e, s))
            o.append('  assign rc_data[%d][%d]  = %s;' % (e, s, rc if rc else "'0"))
        im = 'io_fromDataPath_immInfo_%d_imm' % e
        it = 'io_fromDataPath_immInfo_%d_immType' % e
        need_imm = c['imm'] != 'IMM_NONE'
        if need_imm != (im in pw):
            die('%s immInfo 端口与配置不符' % exu)
        if (c['imm'] not in ('IMM_NONE', 'IMM_LOAD_U')) != (it in pw):
            die('%s immType 端口与配置不符' % exu)
        o.append('  assign imm_raw[%d]  = %s;' % (e, im if im in pw else "'0"))
        o.append('  assign imm_type[%d] = %s;' % (e, it if it in pw else "'0"))
        if c['bju']:
            o.append('  assign is_jump[%d]  = io_fromDataPath_%s_bits_fuType[0];' % (e, exu))
            o.append('  assign op_jalr[%d]  = io_fromDataPath_%s_bits_fuOpType[0];' % (e, exu))
            o.append('  assign ftq_off[%d]  = io_fromDataPath_%s_bits_ftqOffset;' % (e, exu))
            o.append('  assign is_rvc[%d]   = io_fromDataPath_%s_bits_preDecode_isRVC;' % (e, exu))
        else:
            o.append("  assign is_jump[%d]  = 1'b0;" % e)
            o.append("  assign op_jalr[%d]  = 1'b0;" % e)
            o.append("  assign ftq_off[%d]  = 4'h0;" % e)
            o.append("  assign is_rvc[%d]   = 1'b0;" % e)
    o += ['',
          '  xs_BypassNetwork_core u_core (',
          '    .clock       (clock),',
          '    .reset       (reset),',
          '    .prod_valid  (prod_valid),',
          '    .prod_data   (prod_data),',
          '    .rcw_intWen  (rcw_intWen),',
          '    .ds          (ds),',
          '    .exu_src     (exu_src),',
          '    .reg_data    (reg_data),',
          '    .rc_data     (rc_data),',
          '    .imm_raw     (imm_raw),',
          '    .imm_type    (imm_type),',
          '    .is_jump     (is_jump),',
          '    .op_jalr     (op_jalr),',
          '    .ftq_off     (ftq_off),',
          '    .is_rvc      (is_rvc),',
          '    .src_out     (src_out),',
          '    .bju_imm     (bju_imm),',
          '    .bju_npc_off (bju_npc_off),',
          '    .rcw_wen     (rcw_wen),',
          '    .rcw_data    (rcw_data)',
          '  );',
          '',
          '  // ---- 核输出拆包 ----']
    for e, exu in enumerate(exus):
        c = cfg[e]
        w = 128 if c['wide'] else 64
        for s in range(c['num_src']):
            o.append('  assign io_toExus_%s_bits_src_%d = src_out[%d][%d][%d:0];' % (exu, s, e, s, w - 1))
        if c['bju']:
            o.append('  assign io_toExus_%s_bits_imm = bju_imm[%d];' % (exu, e))
            o.append('  assign io_toExus_%s_bits_nextPcOffset = bju_npc_off[%d];' % (exu, e))
    for k in range(len(RCW_PROD)):
        o.append('  assign io_toDataPath_%d_wen  = rcw_wen[%d];' % (k, k))
        o.append('  assign io_toDataPath_%d_data = rcw_data[%d];' % (k, k))
    o.append('')
    o.append('  // ---- 其余 ExuInput 字段与 valid：直连；ready：反向直连 ----')
    for n in G['passthru']:
        o.append('  assign %s = %s;' % (n, n.replace('io_toExus_', 'io_fromDataPath_')))
    for n in G['ready']:
        o.append('  assign %s = %s;' % (n, n.replace('io_fromDataPath_', 'io_toExus_')))
    o.append('endmodule')
    return '\n'.join(o)


def replace_block(text, tag, content):
    begin = '// BEGIN GENERATED(%s)' % tag
    end = '// END GENERATED'
    i = text.index(begin)
    j = text.index(end, i)
    ind = text[text.rindex('\n', 0, i) + 1:i]
    return text[:i] + begin + '\n' + content + '\n' + ind + end + text[j + len(end):]


def emit_tb(G):
    pw, cfg, exus = G['pw'], G['cfg'], G['exus']
    ins = [(w, n) for d, w, n in G['ports'] if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in G['ports'] if d == 'output']
    o = ['// =============================================================================',
         '// tb —— BypassNetwork UT：golden 与重写件(BypassNetwork_xs)逐拍双例化，比全部 %d 个输出口。' % len(outs),
         '// 由 scripts/gen_bypassnetwork.py 生成，勿手改。',
         '//',
         '// 激励：',
         '//   * dataSources.value：75% 取合法码 {0,1,2,3,4,5,6,8}（均匀），25% 全随机 4 位；',
         '//   * exuSources.value：全随机（含 0 = "无"）；valid/ready/数据/立即数：全随机，',
         '//     立即数类型 60% 取合法 selImm 码；fuType[0]/fuOpType[0] 随机 → JALR/非 JALR 都走到；',
         '//   * 暖机：前 %d 拍所有旁路源 valid=1，把两侧不复位的 bypass 寄存器写成同值再开始比；' % 4,
         '//   * reset：开头 3 拍，此后每拍 1/2000 概率打一拍（RegCache wen 寄存器的异步复位）。',
         '// 覆盖计数见仿真末尾 COVER 行（任一为 0 判失败）。',
         '// =============================================================================',
         '`timescale 1ns/1ps',
         'module tb;',
         '  int unsigned NCYCLES = 200000;',
         '  bit clk = 0;',
         '  always #5 clk = ~clk;',
         '  logic reset;',
         '  longint errors = 0, checks = 0;',
         '  logic warm;']
    for w, n in ins:
        o.append('  logic [%d:0] %s;' % (w - 1, n))
    for w, n in outs:
        o.append('  logic [%d:0] g_%s, i_%s;' % (w - 1, n, n))
    for inst, mod, pre in (('u_g', 'BypassNetwork', 'g_'), ('u_i', 'BypassNetwork_xs', 'i_')):
        o.append('  %s %s (' % (mod, inst))
        conns = ['    .clock(clk)', '    .reset(reset)']
        conns += ['    .%s(%s)' % (n, n) for w, n in ins]
        conns += ['    .%s(%s%s)' % (n, pre, n) for w, n in outs]
        o.append(',\n'.join(conns))
        o.append('  );')
    o += ['',
          "  localparam logic [3:0] DSV [8] = '{4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h8};",
          "  localparam logic [3:0] IMT [13] = '{4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h8, 4'h9, 4'hA, 4'hB, 4'hC, 4'hD, 4'hE, 4'hF};",
          '  function automatic logic [3:0] rand_ds();',
          '    return ($urandom_range(0, 3) != 0) ? DSV[$urandom_range(0, 7)] : 4\'($urandom);',
          '  endfunction',
          '  function automatic logic [127:0] r128();',
          '    return {$urandom, $urandom, $urandom, $urandom};',
          '  endfunction',
          '',
          '  task automatic drive();']
    for w, n in ins:
        if re.search(r'_dataSources_\d_value$', n):
            o.append('    %s = rand_ds();' % n)
        elif re.search(r'_immType$', n):
            o.append("    %s = ($urandom_range(0, 4) < 3) ? IMT[$urandom_range(0, 12)] : 4'($urandom);" % n)
        elif re.match(r'io_fromExus_\w+_valid$', n):
            o.append("    %s = warm ? 1'b1 : 1'($urandom);" % n)
        elif w <= 32:
            o.append("    %s = %d'($urandom);" % (n, w))
        else:
            o.append("    %s = %d'(r128());" % (n, w))
    o += ['  endtask', '']
    # 覆盖计数：直接看 golden 的输入选择码与输出
    o += ['  longint cov_fwd_int, cov_byp_int, cov_fwd_fp, cov_byp_fp, cov_v0, cov_rc, cov_imm,',
          '          cov_loadu, cov_jalr, cov_nojalr, cov_rcw;',
          '  task automatic sample_cov();']
    for e, exu in enumerate(exus):
        c = cfg[e]
        for s in range(c['num_src']):
            ds = 'io_fromDataPath_%s_bits_dataSources_%d_value' % (exu, s)
            out = 'g_io_toExus_%s_bits_src_%d' % (exu, s)
            xs = 'io_fromDataPath_%s_bits_exuSources_%d_value' % (exu, s)
            if c['fwd'] != 'FWD_NONE':
                t = 'int' if c['fwd'] == 'FWD_INT' else 'fp'
                o.append("    if (%s == 4'h1 && %s != 0 && %s != 0) cov_fwd_%s++;" % (ds, xs, out, t))
                o.append("    if (%s == 4'h2 && %s != 0 && %s != 0) cov_byp_%s++;" % (ds, xs, out, t))
            if c['v0'] and s < 3:
                o.append("    if (%s == 4'h5 && %s != 0) cov_v0++;" % (ds, out))
            if c['rc']:
                o.append("    if (%s == 4'h6 && %s != 0) cov_rc++;" % (ds, out))
            if c['imm'] == 'IMM_LOAD_U':
                o.append("    if (%s == 4'h4 && %s != 0) cov_loadu++;" % (ds, out))
            elif c['imm'] != 'IMM_NONE':
                o.append("    if (%s == 4'h4 && %s != 0) cov_imm++;" % (ds, out))
        if c['bju']:
            o.append('    if (io_fromDataPath_%s_bits_fuType[0] & io_fromDataPath_%s_bits_fuOpType[0]) cov_jalr++; else cov_nojalr++;' % (exu, exu))
    for k in range(len(RCW_PROD)):
        o.append('    if (g_io_toDataPath_%d_wen) cov_rcw++;' % k)
    o += ['  endtask', '',
          '  task automatic check();']
    for w, n in outs:
        o.append('    checks++; if (g_%s !== i_%s) begin errors++; if (errors <= 30) '
                 '$display("[%%0t] MISMATCH %s g=%%h i=%%h", $time, g_%s, i_%s); end' % (n, n, n, n, n))
    o += ['  endtask', '',
          '  initial begin',
          '    if ($value$plusargs("ncycles=%d", NCYCLES)) ;',
          "    warm = 1'b1; reset = 1'b1;",
          '    drive();',
          '    repeat (3) @(posedge clk);',
          "    #1 reset = 1'b0;",
          '    for (int cyc = 0; cyc < NCYCLES; cyc++) begin',
          "      warm = (cyc < 4);",
          '      #1 drive();',
          "      reset = ($urandom_range(0, 1999) == 0);",
          '      #3;',
          '      if (!warm) begin check(); sample_cov(); end',
          '      @(posedge clk);',
          '    end',
          '    $display("COVER fwd_int=%0d byp_int=%0d fwd_fp=%0d byp_fp=%0d v0=%0d rc=%0d imm=%0d loadu=%0d jalr=%0d nojalr=%0d rcw_wen=%0d",',
          '             cov_fwd_int, cov_byp_int, cov_fwd_fp, cov_byp_fp, cov_v0, cov_rc, cov_imm, cov_loadu,',
          '             cov_jalr, cov_nojalr, cov_rcw);',
          '    if (cov_fwd_int == 0 || cov_byp_int == 0 || cov_fwd_fp == 0 || cov_byp_fp == 0 || cov_v0 == 0 ||',
          '        cov_rc == 0 || cov_imm == 0 || cov_loadu == 0 || cov_jalr == 0 || cov_nojalr == 0 || cov_rcw == 0) begin',
          '      $display("COVER HOLE"); errors++;',
          '    end',
          '    $display("checks=%0d errors=%0d", checks, errors);',
          '    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");',
          '    $finish;',
          '  end',
          'endmodule']
    return '\n'.join(o) + '\n'


def emit_pins(G):
    body = load_golden()[0]
    width = dict((n, int(w) + 1) for w, n in
                 re.findall(r'\n  reg\s+\[(\d+):0\]\s+(bypassDataVec_r\w*);', body))
    pairs = []
    for pn, ex, pos in PRODUCERS:
        g = 'bypassDataVec_r' + ('' if pos == 0 else '_%d' % pos)
        if g not in width:
            die('golden 缺旁路寄存器 ' + g)
        p = [x[0] for x in PRODUCERS].index(pn)
        for bit in range(64):
            pairs.append(('%s_reg\\[%d\\]' % (g, bit), 'u_core/byp_data_reg\\[%d\\]\\[%d\\]' % (p, bit)))
    if len(width) != len(PRODUCERS):
        die('golden 旁路寄存器数 %d != %d' % (len(width), len(PRODUCERS)))
    for k in range(len(RCW_PROD)):
        g = 'bypassIntWenVec_last_REG' + ('' if k == 0 else '_%d' % k)
        if not re.search(r'\n  reg\s+%s;' % g, body):
            die('golden 缺 ' + g)
        pairs.append(('%s_reg' % g, 'u_core/rcw_wen_reg\\[%d\\]' % k))
    if len({i for _, i in pairs}) != len(pairs) or len({r for r, _ in pairs}) != len(pairs):
        die('钉点不是双射')
    n = len(pairs)
    o = ['# BypassNetwork FM「匹配前」钉点 —— 自动生成：scripts/gen_bypassnetwork.py（勿手改）',
         '#',
         '# 只消 golden 扁平寄存器名与核数组名之间的命名差（依据见生成器文件头 (4)）。',
         '# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。',
         '# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。',
         'set ::BN_PIN_OK 0',
         'set ::BN_PIN_BAD 0',
         'proc bn_pin {r i} {',
         '  set rr "r:/WORK/BypassNetwork/$r"',
         '  set ii "i:/WORK/BypassNetwork/$i"',
         '  if {[set_user_match $rr $ii]} { incr ::BN_PIN_OK } else {',
         '    incr ::BN_PIN_BAD',
         '    if {$::BN_PIN_BAD <= 10} { puts "BN_PIN_FAIL: $rr <-> $ii" }',
         '  }',
         '}',
         'puts "BN_PIN_BEGIN BypassNetwork expect=%d"' % n]
    o += ['bn_pin %s %s' % (r, i) for r, i in pairs]
    o += ['puts "BN_PIN_END BypassNetwork ok=$::BN_PIN_OK bad=$::BN_PIN_BAD"',
          'if {$::BN_PIN_BAD != 0} { error "BN_PIN_MISS=$::BN_PIN_BAD" }',
          'if {$::BN_PIN_OK != %d} { error "BN_PIN_COUNT=$::BN_PIN_OK expect=%d" }' % (n, n)]
    return '\n'.join(o) + '\n'


def targets():
    G = build()
    text = RTL.read_text()
    text = replace_block(text, 'bypassnetwork_cfg', emit_cfg(G))
    text = replace_block(text, 'bypassnetwork_wrapper', emit_wrapper(G))
    return {RTL: text, TB: emit_tb(G), PINS: emit_pins(G)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    args = ap.parse_args()
    drift = 0
    for path, text in targets().items():
        cur = path.read_text() if path.exists() else None
        rel = path.relative_to(REPO)
        if cur == text:
            print('gen_bypassnetwork: OK     %s' % rel)
            continue
        if args.check:
            print('gen_bypassnetwork: DRIFT  %s' % rel)
            drift += 1
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
            print('gen_bypassnetwork: WROTE  %s' % rel)
    return 1 if drift else 0


if __name__ == '__main__':
    sys.exit(main())
