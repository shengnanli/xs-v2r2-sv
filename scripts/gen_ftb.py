#!/usr/bin/env python3
"""gen_ftb.py —— FTB 的两份机械派生物：golden 同名 wrapper + FM「匹配前」钉点。

1. rtl/frontend/FTB.sv 里 `// BEGIN GENERATED(FTB)` .. `// END GENERATED` 之间的
   golden 同名 wrapper `module FTB`：端口表逐行照抄 G1 golden（名/方向/位宽/顺序），
   每个端口按下面 port_rule() 的规则接到 xs_FTB_core 的结构化端口上；四个已签核子模块
   （ftbBank / delay2_pc_pipMod / delay2_entry_pipMod / write_valid_delay）按 golden
   同层同实例名例化，其端口按各自 golden 端口表逐个连线。
   fail-closed：golden 的每个端口必须恰好命中一条规则，否则拒绝生成。

2. verif/ut/FTB/fm_pins_pre.tcl：golden FTB 顶层每个寄存器位 set_user_match 到核里
   对应字段数组元素（firtool 扁平名 <-> 核的数组/结构体位）。只消名差，不约束 ref。
   结构体字段偏移从 SV 源里的 typedef 现解析（xs_ftb_pkg / ftb_pred_pkg），
   每个 golden 寄存器必须恰好命中一条规则、位映射必须单射，否则拒绝生成；
   运行时逐条数 set_user_match 返回值，拒一条或总数 != 字面整数即 error。

用法：python3 scripts/gen_ftb.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = os.path.join(REPO, 'rtl', 'frontend', 'FTB.sv')
PKG = os.path.join(REPO, 'rtl', 'frontend', 'frontend_common_pkg.sv')
PINS = os.path.join(REPO, 'verif', 'ut', 'FTB', 'fm_pins_pre.tcl')
NUM_DUP = 4


def fail(msg):
    raise SystemExit('gen_ftb: ' + msg)


# --------------------------------------------------------------------------
# golden 解析
# --------------------------------------------------------------------------
PORT_RE = re.compile(r'^\s*(input|output)\s+(\[(\d+):0\]\s+)?(\w+),?\s*$')


def golden_module(name):
    txt = open(os.path.join(G, name + '.sv')).read()
    m = re.search(r'^module %s\(\n(.*?)^\);\n(.*?)^endmodule' % re.escape(name), txt, re.S | re.M)
    if not m:
        fail('golden %s 找不到模块体' % name)
    ports = []
    for line in m.group(1).splitlines():
        pm = PORT_RE.match(line)
        if not pm:
            fail('golden %s 端口行解析失败: %r' % (name, line))
        ports.append((pm.group(1), int(pm.group(3)) + 1 if pm.group(3) else 1, pm.group(4)))
    return ports, m.group(2)


def golden_regs(body):
    regs = []
    for rm in re.finditer(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);', body, re.M):
        regs.append((rm.group(2), int(rm.group(1)) + 1 if rm.group(1) else 1))
    return regs


# --------------------------------------------------------------------------
# SV packed struct 解析（只认本文件用到的写法：logic [expr:0] name; / typename name;）
# --------------------------------------------------------------------------
def parse_params(txt):
    p = {}
    for m in re.finditer(r'localparam\s+int\s+unsigned\s+(\w+)\s*=\s*([^;]+);', txt):
        expr = m.group(2)
        for k, v in p.items():
            expr = re.sub(r'\b%s\b' % k, str(v), expr)
        if re.fullmatch(r'[\d\s+\-*()]+', expr):
            p[m.group(1)] = eval(expr)
    return p


def parse_structs(txt, params, structs):
    for m in re.finditer(r'typedef struct packed \{(.*?)\}\s*(\w+);', txt, re.S):
        fields = []
        for line in m.group(1).splitlines():
            line = line.split('//')[0].strip()
            if not line:
                continue
            fm = re.fullmatch(r'logic\s*(?:\[([^\]]+):0\])?\s*(\w+);', line)
            if fm:
                w = 1
                if fm.group(1):
                    expr = fm.group(1)
                    for k, v in params.items():
                        expr = re.sub(r'\b%s\b' % k, str(v), expr)
                    w = eval(expr) + 1
                fields.append((fm.group(2), w, None))
                continue
            fm = re.fullmatch(r'(\w+)\s+(\w+);', line)
            if fm and fm.group(1) in structs:
                fields.append((fm.group(2), structs[fm.group(1)]['width'], fm.group(1)))
                continue
            fields = None   # 本解析器不认的写法（如多维 packed）：该类型不可用于钉点
            break
        if fields is None:
            continue
        # packed：第一个字段在最高位
        total = sum(f[1] for f in fields)
        off, lay = total, {}
        for fname, w, sub in fields:
            off -= w
            lay[fname] = (off, w, sub)
        structs[m.group(2)] = {'width': total, 'fields': lay}


def field_slice(structs, typ, path):
    """path = ['tailSlot', 'lower'] -> (lsb, width)。"""
    base = 0
    for i, name in enumerate(path):
        f = structs[typ]['fields'].get(name)
        if f is None:
            fail('struct %s 没有字段 %s' % (typ, name))
        off, w, sub = f
        base += off
        if i < len(path) - 1:
            if sub is None:
                fail('%s.%s 不是结构体' % (typ, name))
            typ = sub
    return base, w


def load_structs():
    structs = {}
    pkg_txt = open(PKG).read()
    ftb_pkg = re.search(r'package xs_ftb_pkg;(.*?)endpackage', pkg_txt, re.S).group(1)
    params = parse_params(ftb_pkg)
    parse_structs(ftb_pkg, params, structs)
    rtl_txt = open(RTL).read()
    my_pkg = re.search(r'package ftb_pred_pkg;(.*?)endpackage', rtl_txt, re.S).group(1)
    params.update(parse_params(my_pkg))
    parse_structs(my_pkg, params, structs)
    return structs


# golden 条目字段后缀 -> 结构体路径
def entry_path(suffix):
    m = re.fullmatch(r'brSlots_0_(\w+)', suffix)
    if m:
        return ['brSlot', m.group(1)]
    m = re.fullmatch(r'tailSlot_(\w+)', suffix)
    if m:
        return ['tailSlot', m.group(1)]
    m = re.fullmatch(r'strong_bias_(\d)', suffix)
    if m:
        return ['strong_bias', int(m.group(1))]
    return [suffix]


def entry_expr(var, suffix):
    p = entry_path(suffix)
    if isinstance(p[-1], int):
        return '%s.%s[%d]' % (var, p[0], p[1])
    return var + '.' + '.'.join(p)


ENTRY_SUFFIXES = ['isCall', 'isRet', 'isJalr', 'valid', 'brSlots_0_offset', 'brSlots_0_sharing',
                  'brSlots_0_valid', 'brSlots_0_lower', 'brSlots_0_tarStat', 'tailSlot_offset',
                  'tailSlot_sharing', 'tailSlot_valid', 'tailSlot_lower', 'tailSlot_tarStat',
                  'pftAddr', 'carry', 'last_may_be_rvi_call', 'strong_bias_0', 'strong_bias_1']
ENTRY_RE = '(' + '|'.join(ENTRY_SUFFIXES) + ')'

PRED_FIELDS = {
    'br_taken_mask_0': 'br_taken_mask[0]', 'br_taken_mask_1': 'br_taken_mask[1]',
    'slot_valids_0': 'slot_valids[0]', 'slot_valids_1': 'slot_valids[1]',
    'targets_0': 'targets[0]', 'targets_1': 'targets[1]', 'jalr_target': 'targets[1]',
    'offsets_0': 'offsets[0]', 'offsets_1': 'offsets[1]',
    'fallThroughAddr': 'fall_through_addr', 'fallThroughErr': 'fall_through_err',
    'multiHit': 'multi_hit', 'is_jal': 'is_jal', 'is_jalr': 'is_jalr', 'is_call': 'is_call',
    'is_ret': 'is_ret', 'last_may_be_rvi_call': 'last_may_be_rvi_call',
    'is_br_sharing': 'is_br_sharing', 'hit': 'hit',
}


# --------------------------------------------------------------------------
# wrapper：每个 golden 端口 -> wrapper 里的一条连线语句
# --------------------------------------------------------------------------
def port_rule(d, w, n):
    """返回 (kind, text)：kind='assign' 生成 assign；'core'/'bank' 等由各自段落消费。"""
    m = re.fullmatch(r'io_in_bits_s0_pc_(\d)', n)
    if m:
        return ('assign', 'assign s0_pc[%s] = %s;' % (m.group(1), n))
    m = re.fullmatch(r'io_in_bits_resp_in_0_s([23])_full_pred_(\d)_br_taken_mask_(\d)', n)
    if m:
        return ('assign', 'assign in_s%s_taken[%s][%s] = %s;' % (m.group(1), m.group(2), m.group(3), n))
    m = re.fullmatch(r'io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_(\d)', n)
    if m:   # 由输出端口那一条消费
        return ('used_by_output', '')
    m = re.fullmatch(r'io_out_last_stage_spec_info_sc_disagree_(\d)', n)
    if m:
        return ('assign', 'assign %s = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_%s;'
                % (n, m.group(1)))
    m = re.fullmatch(r'io_out_s([23])_full_pred_(\d)_(\w+)', n)
    if m and m.group(3) in PRED_FIELDS:
        return ('assign', 'assign %s = s%s_pred[%s].%s;' % (n, m.group(1), m.group(2),
                                                         PRED_FIELDS[m.group(3)]))
    m = re.fullmatch(r'io_out_last_stage_ftb_entry_' + ENTRY_RE, n)
    if m:
        return ('assign', 'assign %s = %s;' % (n, entry_expr('last_stage_entry', m.group(1))))
    m = re.fullmatch(r'io_fauftb_entry_in_' + ENTRY_RE, n)
    if m:
        return ('assign', 'assign %s = %s;' % (entry_expr('fau_entry_in', m.group(1)), n))
    m = re.fullmatch(r'io_update_bits_ftb_entry_' + ENTRY_RE, n)
    if m:
        return ('assign', 'assign %s = %s;' % (entry_expr('update_entry_in', m.group(1)), n))
    m = re.fullmatch(r'io_s([012])_fire_(\d)', n)
    if m:
        return ('assign', 'assign s%s_fire[%s] = %s;' % (m.group(1), m.group(2), n))
    if n == 'io_s3_fire_0':
        return ('unused', '')
    m = re.fullmatch(r'io_perf_([01])_value', n)
    if m:
        sig = 'perf_commit_hit' if m.group(1) == '0' else 'perf_commit_miss'
        return ('assign', 'assign %s = {5\'h0, %s};' % (n, sig))
    if n.startswith('boreChildrenBd_') or n.startswith('sigFromSrams_'):
        return ('bank_passthrough', '')
    simple = {
        'clock': 'core', 'reset': 'core', 'io_reset_vector': 'core',
        'io_out_s1_uftbHit': 'core', 'io_out_s1_uftbHasIndirect': 'core',
        'io_out_s1_ftbCloseReq': 'core', 'io_out_last_stage_meta': 'core',
        'io_fauftb_entry_hit_in': 'core', 'io_ctrl_btb_enable': 'core', 'io_s1_ready': 'core',
        'io_update_valid': 'core', 'io_update_bits_pc': 'core', 'io_update_bits_false_hit': 'core',
        'io_update_bits_old_entry': 'core', 'io_update_bits_meta': 'core',
        'io_redirectFromIFU': 'core',
    }
    if n in simple:
        return ('core', '')
    return None


def gen_wrapper():
    ports, _ = golden_module('FTB')
    bank_ports, _ = golden_module('FTBBank')
    dly1_ports, _ = golden_module('DelayNWithValid_1')
    L = []
    A = L.append
    A('// BEGIN GENERATED(FTB) —— scripts/gen_ftb.py（端口表与连线从 G1 golden 机械生成，勿手改）')
    A('module FTB')
    A('  import xs_ftb_pkg::*;')
    A('  import ftb_pred_pkg::*;')
    A('(')
    for i, (d, w, n) in enumerate(ports):
        rng = '[%d:0] ' % (w - 1) if w > 1 else ''
        A('  %-6s logic %s%s%s' % (d, rng, n, ',' if i < len(ports) - 1 else ''))
    A(');')
    A('')
    A('  // ---- 核侧结构化信号 ----')
    A('  logic [PC_W-1:0] s0_pc       [NUM_DUP];')
    A('  logic            s0_fire     [NUM_DUP];')
    A('  logic            s1_fire     [NUM_DUP];')
    A('  logic            s2_fire     [NUM_DUP];')
    A('  logic [1:0]      in_s2_taken [NUM_DUP];')
    A('  logic [1:0]      in_s3_taken [NUM_DUP];')
    A('  ftb_pred_t       s2_pred     [NUM_DUP];')
    A('  ftb_pred_t       s3_pred     [NUM_DUP];')
    A('  ftb_entry_t      fau_entry_in, update_entry_in, last_stage_entry;')
    A('  logic            perf_commit_hit, perf_commit_miss;')
    A('  // FTBBank / 延迟件接口')
    A('  logic            bank_req_ready, bank_req_valid, bank_read_hit, bank_multi_hit;')
    A('  logic [1:0]      bank_read_way, bank_multi_way, bank_update_way, bank_write_way;')
    A('  ftb_entry_t      bank_read_entry, bank_multi_entry, bank_write_entry;')
    A('  logic            bank_u_req_valid, bank_update_hit, bank_update_access;')
    A('  logic [PC_W-1:0] bank_write_pc;')
    A('  logic            bank_write_valid, bank_write_alloc;')
    A('  logic [19:0]     bank_write_tag;')
    A('  logic            u_valid, write_valid_delay_in, write_valid_delay_out;')
    A('  logic [PC_W-1:0] delay2_pc;')
    A('  ftb_entry_t      update_entry, delay2_entry;')
    A('')
    A('  // ---- 端口 <-> 结构化信号（逐端口一条）----')
    seen = set()
    for d, w, n in ports:
        r = port_rule(d, w, n)
        if r is None:
            fail('golden 端口 %s 没有命中任何规则' % n)
        if n in seen:
            fail('重复端口 %s' % n)
        seen.add(n)
        if r[0] == 'assign':
            A('  ' + r[1])
    A('  // io_s3_fire_0：golden 里只喂 S3 fall-through 断言（非 SYNTHESIS），无功能读者')
    A('')
    A('  xs_FTB_core u_core (')
    conns = [
        ('clock', 'clock'), ('reset', 'reset'), ('reset_vector', 'io_reset_vector'),
        ('s0_pc', 's0_pc'), ('s0_fire', 's0_fire'), ('s1_fire', 's1_fire'),
        ('s2_fire', 's2_fire'), ('in_s2_taken', 'in_s2_taken'), ('in_s3_taken', 'in_s3_taken'),
        ('fau_entry_in', 'fau_entry_in'), ('fau_hit_in', 'io_fauftb_entry_hit_in'),
        ('btb_enable', 'io_ctrl_btb_enable'), ('s2_pred', 's2_pred'), ('s3_pred', 's3_pred'),
        ('s1_uftb_hit', 'io_out_s1_uftbHit'), ('s1_uftb_has_indirect', 'io_out_s1_uftbHasIndirect'),
        ('s1_close_req', 'io_out_s1_ftbCloseReq'), ('last_stage_meta', 'io_out_last_stage_meta'),
        ('last_stage_entry', 'last_stage_entry'), ('s1_ready', 'io_s1_ready'),
        ('update_valid_in', 'io_update_valid'), ('update_pc', 'io_update_bits_pc'),
        ('update_entry_in', 'update_entry_in'), ('update_false_hit_in', 'io_update_bits_false_hit'),
        ('update_old_entry_in', 'io_update_bits_old_entry'), ('update_meta_in', 'io_update_bits_meta'),
        ('redirect_from_ifu', 'io_redirectFromIFU'), ('perf_commit_hit', 'perf_commit_hit'),
        ('perf_commit_miss', 'perf_commit_miss'),
        ('bank_req_ready', 'bank_req_ready'), ('bank_req_valid', 'bank_req_valid'),
        ('bank_read_entry', 'bank_read_entry'), ('bank_read_hit', 'bank_read_hit'),
        ('bank_read_way', 'bank_read_way'), ('bank_multi_entry', 'bank_multi_entry'),
        ('bank_multi_hit', 'bank_multi_hit'), ('bank_multi_way', 'bank_multi_way'),
        ('bank_u_req_valid', 'bank_u_req_valid'), ('bank_update_hit', 'bank_update_hit'),
        ('bank_update_way', 'bank_update_way'), ('bank_update_access', 'bank_update_access'),
        ('bank_write_pc', 'bank_write_pc'), ('bank_write_valid', 'bank_write_valid'),
        ('bank_write_entry', 'bank_write_entry'), ('bank_write_tag', 'bank_write_tag'),
        ('bank_write_way', 'bank_write_way'), ('bank_write_alloc', 'bank_write_alloc'),
        ('u_valid', 'u_valid'), ('delay2_pc', 'delay2_pc'), ('update_entry', 'update_entry'),
        ('delay2_entry', 'delay2_entry'), ('write_valid_delay_in', 'write_valid_delay_in'),
        ('write_valid_delay_out', 'write_valid_delay_out'),
    ]
    for i, (p, s) in enumerate(conns):
        A('    .%-22s (%s)%s' % (p, s, ',' if i < len(conns) - 1 else ''))
    A('  );')
    A('')
    # ---- FTBBank ----
    A('  // ---- 子模块：FTBBank（512 组 x 4 路 SRAM + tag 比较 + PLRU 替换，已签核）----')
    bank_conn = []
    for d, w, n in bank_ports:
        s = None
        if n in ('clock', 'reset'):
            s = n
        elif n.startswith('boreChildrenBd_') or n.startswith('sigFromSrams_'):
            if n not in seen:
                fail('FTBBank 的 %s 在 FTB 顶层没有同名端口' % n)
            s = n
        else:
            m = re.fullmatch(r'io_read_resp_' + ENTRY_RE, n)
            if m:
                s = entry_expr('bank_read_entry', m.group(1))
            m = re.fullmatch(r'io_read_multi_entry_' + ENTRY_RE, n)
            if m:
                s = entry_expr('bank_multi_entry', m.group(1))
            m = re.fullmatch(r'io_update_write_data_bits_entry_' + ENTRY_RE, n)
            if m:
                s = entry_expr('bank_write_entry', m.group(1))
            s = s or {
                'io_s1_fire': 's1_fire[0]', 'io_req_pc_ready': 'bank_req_ready',
                'io_req_pc_valid': 'bank_req_valid', 'io_req_pc_bits': 'io_in_bits_s0_pc_0',
                'io_read_hits_valid': 'bank_read_hit', 'io_read_hits_bits': 'bank_read_way',
                'io_read_multi_hits_valid': 'bank_multi_hit',
                'io_read_multi_hits_bits': 'bank_multi_way',
                'io_u_req_pc_valid': 'bank_u_req_valid', 'io_u_req_pc_bits': 'io_update_bits_pc',
                'io_update_hits_valid': 'bank_update_hit', 'io_update_hits_bits': 'bank_update_way',
                'io_update_access': 'bank_update_access', 'io_update_pc': 'bank_write_pc',
                'io_update_write_data_valid': 'bank_write_valid',
                'io_update_write_data_bits_tag': 'bank_write_tag',
                'io_update_write_way': 'bank_write_way', 'io_update_write_alloc': 'bank_write_alloc',
            }.get(n)
        if s is None:
            fail('FTBBank 端口 %s 没有命中任何规则' % n)
        bank_conn.append((n, s))
    A('  FTBBank ftbBank (')
    for i, (p, s) in enumerate(bank_conn):
        A('    .%-52s (%s)%s' % (p, s, ',' if i < len(bank_conn) - 1 else ''))
    A('  );')
    A('')
    A('  // ---- 子模块：update pc / 条目 / "需写"标志各打两拍（已签核延迟件）----')
    A('  DelayNWithValid delay2_pc_pipMod (')
    A('    .clock       (clock),')
    A('    .reset       (reset),')
    A('    .io_in_bits  (io_update_bits_pc),')
    A('    .io_in_valid (u_valid),')
    A('    .io_out_bits (delay2_pc)')
    A('  );')
    A('')
    d1 = []
    for d, w, n in dly1_ports:
        m = re.fullmatch(r'io_in_bits_' + ENTRY_RE, n)
        if m:
            d1.append((n, entry_expr('update_entry', m.group(1))))
            continue
        m = re.fullmatch(r'io_out_bits_' + ENTRY_RE, n)
        if m:
            d1.append((n, entry_expr('delay2_entry', m.group(1))))
            continue
        s = {'clock': 'clock', 'reset': 'reset', 'io_in_valid': 'u_valid'}.get(n)
        if s is None:
            fail('DelayNWithValid_1 端口 %s 没有命中任何规则' % n)
        d1.append((n, s))
    A('  DelayNWithValid_1 delay2_entry_pipMod (')
    for i, (p, s) in enumerate(d1):
        A('    .%-32s (%s)%s' % (p, s, ',' if i < len(d1) - 1 else ''))
    A('  );')
    A('')
    A('  DelayN_1 write_valid_delay (')
    A('    .clock  (clock),')
    A('    .io_in  (write_valid_delay_in),')
    A('    .io_out (write_valid_delay_out)')
    A('  );')
    A('')
    A('endmodule')
    A('// END GENERATED(FTB)')
    return '\n'.join(L) + '\n'


# --------------------------------------------------------------------------
# fm_pins_pre.tcl
# --------------------------------------------------------------------------
TGT_FIELDS = {'higher': 'higher', 'middle': 'middle', 'higher_plus_one': 'higher_p1',
              'higher_minus_one': 'higher_m1', 'middle_plus_one': 'middle_p1',
              'middle_minus_one': 'middle_m1'}


def reg_rule(name, width, structs):
    """golden 寄存器 -> (impl 变量名, impl 下标前缀列表, 结构体类型或 None, 结构体路径)。
    返回的 bitmap(b) 给出 golden 第 b 位对应的 impl 叶子名。"""
    def vec(var, idx=None):
        pre = ''.join('[%d]' % i for i in (idx or []))
        if width == 1 and not idx:
            return lambda b: '%s_reg' % var
        if width == 1:
            return lambda b: '%s_reg%s' % (var, pre)
        return lambda b: '%s_reg%s[%d]' % (var, pre, b)

    def sfield(var, idx, typ, path):
        # FM 对 packed struct 寄存器保留字段名：<var>_reg[下标]\[字段]\[子字段][位]（实测，
        # 见 scratchpad fmq/q2.log）。字段宽度仍从 SV typedef 现解析，用来核对 golden 位宽。
        fpath = path if not isinstance(path[-1], int) else path[:-1]
        _, w = field_slice(structs, typ, fpath)
        if isinstance(path[-1], int):
            w = 1
        if w != width:
            fail('%s: golden 位宽 %d != %s.%s 位宽 %d' % (name, width, typ, path, w))
        pre = ''.join('[%d]' % i for i in idx) + ''.join('\\[%s]' % f for f in fpath)
        if isinstance(path[-1], int):
            return lambda b: '%s_reg%s[%d]' % (var, pre, path[-1])
        if width == 1:
            return lambda b: '%s_reg%s' % (var, pre)
        return lambda b: '%s_reg%s[%d]' % (var, pre, b)

    simple = {
        'modified_reset': ('modified_reset', None), 's0_close_ftb_req': ('s0_close', None),
        's1_close_ftb_req': ('s1_close', None), 's2_close_ftb_req': ('s2_close', None),
        's2_ftb_meta_c': ('pred_cycle_ftb', None), 's2_multi_hit_meta_c': ('pred_cycle_multi', None),
        's2_ftb_meta': ('s2_ftb_meta', None),
        'fauftb_ftb_entry_consistent_counter': ('consist_cnt', None),
        'update_valid': ('update_valid', None), 'update_r_false_hit': ('update_false_hit', None),
        'update_r_old_entry': ('update_old_entry', None), 'update_meta_r': ('update_meta_r', None),
        'io_out_last_stage_meta_r': ('last_stage_meta_r', None),
        'io_s1_ready_REG': ('s1_ready_block_r', None),
        'ftbBank_io_update_write_way_REG': ('write_way_r', None),
        'ftbBank_io_update_write_alloc_REG': ('write_alloc_r', None),
        # REG / REG_1 是两份恒等寄存器（都 = RegNext(s0_fire[0])），merge_dup 会在两侧各留一份：
        # 实测 ref 留 REG_1、impl 留 s0_fire_hit_perf_r。钉点按"留下的那一份互配"交叉写，
        # 否则两条钉点各有一端被合并掉而被 FM 忽略（2026-10-03 诊断跑 fm.log "Ignoring user match"）。
        # 两份逻辑完全相同，交叉配对不改变任何比较语义。
        'REG': ('s0_fire_miss_perf_r', None), 'REG_1': ('s0_fire_hit_perf_r', None),
    }
    if name in simple:
        return vec(simple[name][0])
    m = re.fullmatch(r'io_perf_([01])_value_REG(_1)?', name)
    if m:
        var = 'perf_hit_r' if m.group(1) == '0' else 'perf_miss_r'
        k = 1 if m.group(2) else 0
        return lambda b: '%s_reg[%d]' % (var, k)
    m = re.fullmatch(r's1_pc_dup_(\d)', name)
    if m:
        return vec('s1_pc', [int(m.group(1))])
    m = re.fullmatch(r's([23])_pc_dup_s[23]_pc_seg_(\d)_value(?:_(\d))?', name)
    if m:
        seg = ['hi', 'mid', 'lo'][int(m.group(2))]
        return vec('s%s_pc_%s' % (m.group(1), seg), [int(m.group(3) or 0)])
    m = re.fullmatch(r's2_fauftb_ftb_entry_hit_dup_(\d)', name)
    if m:
        return vec('s2_fau_hit', [int(m.group(1))])
    for gname, var in (('s2_fauftb_ftb_entry_dup', 's2_fau_entry'),
                       ('s2_ftbBank_dup', 's2_bank_entry'), ('s3_ftb_entry_dup', 's3_entry')):
        m = re.fullmatch(gname + r'_(\d)_' + ENTRY_RE, name)
        if m:
            dup = int(m.group(1))
            path = entry_path(m.group(2))
            if dup == 0:
                return sfield(var + '0', [], 'ftb_entry_t', path)
            return sfield(var + '_lite', [dup], 'ftb_entry_lite_t', path)
    m = re.fullmatch(r'update_r_ftb_entry_' + ENTRY_RE, name)
    if m:
        return sfield('update_entry', [], 'ftb_entry_t', entry_path(m.group(1)))
    for gname, var in (('real_s3_fallThroughErr_dup', 's3_ft_err'), ('s2_ftb_hit_dup', 's2_ftb_hit'),
                       ('s3_hit_dup', 's3_hit'), ('s3_multi_hit_dup', 's3_multi_hit')):
        m = re.fullmatch(gname + r'_(\d)', name)
        if m:
            return vec(var, [int(m.group(1))])
    m = re.fullmatch(r'io_out_s2_full_pred_(\d)_fallThroughAddr_stashed_carry', name)
    if m:
        return vec('s2_stash_carry', [int(m.group(1))])
    m = re.fullmatch(r'last_stage_pc_(%s)(?:_(\d))?' % '|'.join(TGT_FIELDS), name)
    if m:
        n = int(m.group(2) or 0)
        var, dup = ('s2_tgt', n) if n < NUM_DUP else ('s3_tgt', n - NUM_DUP)
        return sfield(var, [dup], 'tgt_base_t', [TGT_FIELDS[m.group(1)]])
    return None


def gen_pins():
    structs = load_structs()
    _, body = golden_module('FTB')
    regs = golden_regs(body)
    if not regs:
        fail('golden FTB 没解析出寄存器')
    pairs, used = [], set()
    for name, w in regs:
        f = reg_rule(name, w, structs)
        if f is None:
            fail('golden 寄存器 %s 没有命中任何映射规则' % name)
        for b in range(w):
            r = '%s_reg[%d]' % (name, b) if w > 1 else '%s_reg' % name
            i = f(b)
            if i in used:
                fail('impl 位 %s 被映射两次（非单射）' % i)
            used.add(i)
            pairs.append((r, i))
    nbits_top = len(pairs)
    # 子模块 delay2_pc_pipMod（DelayNWithValid）的两级 50 位 PC 打拍：写 FTB 只用 pc[29:1]，
    # 其余 21 位在两侧都是零扇出（unread）。FM 只给"被读"的位按签名配上，unread 的那 21 位
    # 两侧名字不同（golden data / res_bits，重写 u_core/g_chain.data_q[0] / [1]）而配不上，
    # 会成为两侧各自的 unmatched unread。这里按级逐位钉全 50 位（含已能自动配上的位，一一对应）。
    child = []
    for gname, stage in (('data', 0), ('res_bits', 1)):
        for b in range(50):
            child.append(('delay2_pc_pipMod/%s_reg[%d]' % (gname, b),
                          'delay2_pc_pipMod/u_core/g_chain.data_q_reg[%d][%d]' % (stage, b)))
    n = len(pairs) + len(child)
    L = []
    A = L.append
    A('# FTB FM「匹配前」钉点 —— 自动生成：scripts/gen_ftb.py（勿手改）')
    A('#')
    A('# 只消 golden 扁平寄存器名（firtool 按 dup/字段展开）与重写核按结构体/数组存放之间的命名鸿沟。')
    A('# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。')
    A('# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；')
    A('# 拒一条或总数不等于字面整数（= golden FTB 顶层寄存器位数）就 error（safe interp 里不用 exit）。')
    A('# 子模块内部只钉 delay2_pc_pipMod 的两级 PC 寄存器（理由见生成器）；其余交给 FM 自动配对（两侧同实例名）。')
    A('# 进 fm.log 的输出一律 ASCII。')
    A('set ::FTB_PIN_EXPECT %d' % n)
    A('set ::FTB_PIN_OK 0')
    A('set ::FTB_PIN_BAD 0')
    A('proc ftb_pin {r i} {')
    A('  ftb_pin_abs $r "u_core/$i"')
    A('}')
    A('proc ftb_pin_abs {r i} {')
    A('  if {[set_user_match "r:/WORK/FTB/$r" "i:/WORK/FTB/$i"]} { incr ::FTB_PIN_OK } else {')
    A('    incr ::FTB_PIN_BAD')
    A('    if {$::FTB_PIN_BAD <= 10} { puts "FTB_PIN_FAIL: $r <-> $i" }')
    A('  }')
    A('}')
    A('puts "FTB_PIN_BEGIN FTB expect=$::FTB_PIN_EXPECT"')
    for r, i in pairs:
        A('ftb_pin {%s} {%s}' % (r, i))   # 花括号：不做替换，FM 名里的反斜杠原样传入
    A('# ---- 子模块 delay2_pc_pipMod 的 PC 打拍寄存器（理由见生成器）----')
    for r, i in child:
        A('ftb_pin_abs {%s} {%s}' % (r, i))
    A('puts "FTB_PIN_END FTB ok=$::FTB_PIN_OK bad=$::FTB_PIN_BAD"')
    A('if {$::FTB_PIN_BAD != 0} { error "FTB_PIN_MISS=$::FTB_PIN_BAD" }')
    A('if {$::FTB_PIN_OK != %d} { error "FTB_PIN_COUNT=$::FTB_PIN_OK expect=%d" }' % (n, n))
    return '\n'.join(L) + '\n', nbits_top, sum(w for _, w in regs)


def splice(txt, gen):
    b = txt.find('// BEGIN GENERATED(FTB)')
    e = txt.find('// END GENERATED(FTB)')
    if b < 0 or e < 0:
        fail('FTB.sv 里找不到 GENERATED(FTB) 标记')
    e = txt.index('\n', e) + 1
    return txt[:b] + gen + txt[e:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只校验产物与生成结果逐字节一致')
    a = ap.parse_args()
    rtl_txt = open(RTL).read()
    if '// BEGIN GENERATED(FTB)' not in rtl_txt:
        rtl_txt = rtl_txt.rstrip('\n') + '\n\n// BEGIN GENERATED(FTB)\n// END GENERATED(FTB)\n'
    new_rtl = splice(rtl_txt, gen_wrapper())
    pins, n, nbits = gen_pins()
    if n != nbits:
        fail('钉点数 %d != golden 寄存器位数 %d' % (n, nbits))
    if a.check:
        bad = []
        if open(RTL).read() != new_rtl:
            bad.append(RTL)
        if not os.path.exists(PINS) or open(PINS).read() != pins:
            bad.append(PINS)
        if bad:
            print('DRIFT: %s 与生成结果不一致（重跑 scripts/gen_ftb.py）' % ' '.join(bad))
            return 1
        print('gen_ftb: OK（wrapper 与 %d 条钉点均与生成结果一致）' % n)
        return 0
    if open(RTL).read() != new_rtl:
        open(RTL, 'w').write(new_rtl)
    os.makedirs(os.path.dirname(PINS), exist_ok=True)
    if not os.path.exists(PINS) or open(PINS).read() != pins:
        open(PINS, 'w').write(pins)
    print('gen_ftb: wrapper 已生成；钉点 %d 位' % n)
    return 0


if __name__ == '__main__':
    sys.exit(main())
