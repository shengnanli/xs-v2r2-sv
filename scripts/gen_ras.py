#!/usr/bin/env python3
"""gen_ras.py —— RAS 的两份机械派生物：golden 同名 wrapper + FM「匹配前」钉点。

1. rtl/frontend/RAS.sv 里 `// BEGIN GENERATED(RAS)` .. `// END GENERATED(RAS)` 之间的 golden 同名
   wrapper `module RAS`：端口表逐行照抄 G1 golden（名/方向/位宽/顺序）；每个端口按 port_rule()
   恰好命中一条规则（接到 xs_RAS_core 的结构化端口、原样直通到同名输出、或接到 RASStack），
   命不中或命中多条即拒绝生成。子模块 RASStack 按 golden 同层同名（实例名 RASStack）例化在
   wrapper 里，端口按 golden RASStack 端口表逐个连线，同样 fail-closed。

2. verif/ut/RASTop/fm_pins_pre.tcl：golden RAS 顶层每个寄存器位 set_user_match 到核里对应的
   数组元素 / 结构体位（firtool 扁平名 <-> 可读核的数组/结构体）。只消名差，不约束 ref。
   每个 golden 寄存器必须恰好命中一条规则、位映射必须单射，否则拒绝生成；运行时逐条数
   set_user_match 返回值，拒一条或总数 != 字面整数即 error。

用法：python3 scripts/gen_ras.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = os.path.join(REPO, 'rtl', 'frontend', 'RAS.sv')
PINS = os.path.join(REPO, 'verif', 'ut', 'RASTop', 'fm_pins_pre.tcl')
NUM_DUP = 4
PORT_RE = re.compile(r'^\s*(input|output)\s+(\[(\d+):0\]\s+)?(\w+),?\s*$')


def fail(msg):
    raise SystemExit('gen_ras: ' + msg)


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
    body = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '', m.group(2), flags=re.S)
    return ports, body


# --------------------------------------------------------------------------
# wrapper 端口规则：端口名 -> 连接表达式
#   core_in[cport]  : list of (pos, golden port) 拼成核输入（位置由下标决定）
#   assigns         : 输出端口 = 表达式
# --------------------------------------------------------------------------
PRED_FIELDS = ['br_taken_mask_1', 'br_taken_mask_0', 'slot_valids_1', 'slot_valids_0',
               'is_br_sharing', 'hit', 'is_call', 'is_ret', 'is_jalr', 'fallThroughErr']
SNAP_FIELDS = ['ssp', 'sctr', 'TOSW_flag', 'TOSW_value', 'TOSR_flag', 'TOSR_value',
               'NOS_flag', 'NOS_value']


def build_wrapper(ports, stack_ports):
    P = {n: (d, w) for d, w, n in ports}
    used = {}

    def use(n, why):
        if n not in P:
            fail('golden RAS 没有端口 %s（规则 %s）' % (n, why))
        if n in used:
            fail('端口 %s 被两条规则认领：%s / %s' % (n, used[n], why))
        used[n] = why
        return n

    pin = 'io_in_bits_resp_in_0_'
    core = []      # (核端口, 连接表达式)
    out_assign = []

    def vec(fmt, why):
        return '{' + ', '.join(use(fmt % d, why) for d in reversed(range(NUM_DUP))) + '}'

    core.append(('reset_vector', use('io_reset_vector', 'reset_vector')))
    core.append(('ras_enable', use('io_ctrl_ras_enable', 'ras_enable')))
    core.append(('s0_fire', vec('io_s0_fire_%d', 's0_fire')))
    core.append(('s1_fire', vec('io_s1_fire_%d', 's1_fire')))
    core.append(('s2_fire', vec('io_s2_fire_%d', 's2_fire')))
    core.append(('s3_fire', use('io_s3_fire_2', 's3_fire')))
    core.append(('s3_redirect', use('io_s3_redirect_2', 's3_redirect')))
    core.append(('s0_pc', vec('io_in_bits_s0_pc_%d', 's0_pc')))
    core.append(('s2_pc', vec('io_out_s2_pc_%d', 's2_pc')))
    core.append(('s3_pc', vec('io_out_s3_pc_%d', 's3_pc')))

    # s2 / s3 判 call/ret 用第 2 份复制的预测字段（这些输入端口同时也直通到同名输出）
    shared_in = {}
    for s in ('s2', 's3'):
        flds = []
        for f in PRED_FIELDS:
            n = '%s%s_full_pred_2_%s' % (pin, s, f)
            flds.append(n)
            shared_in[n] = True
        core.append(('%s_pred' % s, '{' + ', '.join(flds) + '}'))
    core.append(('s2_fall_through_addr', pin + 's2_full_pred_2_fallThroughAddr'))
    core.append(('s2_last_may_be_rvi_call', pin + 's2_full_pred_2_last_may_be_rvi_call'))
    shared_in[pin + 's2_full_pred_2_fallThroughAddr'] = True
    shared_in[pin + 's2_full_pred_2_last_may_be_rvi_call'] = True

    for s in ('s2', 's3'):
        core.append(('%s_jalr_target_in' % s, vec(pin + s + '_full_pred_%d_jalr_target', s + '_jalr_in')))
        core.append(('%s_last_target_in' % s, vec(pin + s + '_full_pred_%d_targets_1', s + '_tgt1_in')))
        core.append(('%s_jalr_target_out' % s, vec('io_out_' + s + '_full_pred_%d_jalr_target', s + '_jalr_out')))
        core.append(('%s_last_target_out' % s, vec('io_out_' + s + '_full_pred_%d_targets_1', s + '_tgt1_out')))

    core.append(('last_stage_meta', use('io_out_last_stage_meta', 'meta')))
    core.append(('last_stage_snap', '{' + ', '.join(use('io_out_last_stage_spec_info_' + f, 'snap_out')
                                                     for f in SNAP_FIELDS) + '}'))
    core.append(('last_stage_top_addr', use('io_out_last_stage_spec_info_topAddr', 'top')))

    rd = 'io_redirect_bits_'
    core.append(('redirect_valid', use('io_redirect_valid', 'rd')))
    core.append(('redirect_level', use(rd + 'level', 'rd')))
    core.append(('redirect_pc', use(rd + 'cfiUpdate_pc', 'rd')))
    core.append(('redirect_pd_valid', use(rd + 'cfiUpdate_pd_valid', 'rd')))
    core.append(('redirect_pd_is_rvc', use(rd + 'cfiUpdate_pd_isRVC', 'rd')))
    core.append(('redirect_pd_is_call', use(rd + 'cfiUpdate_pd_isCall', 'rd')))
    core.append(('redirect_pd_is_ret', use(rd + 'cfiUpdate_pd_isRet', 'rd')))
    core.append(('redirect_snap', '{' + ', '.join(use(rd + 'cfiUpdate_' + f, 'rd_snap') for f in SNAP_FIELDS) + '}'))

    up = 'io_update_bits_'
    core.append(('update_valid', use('io_update_valid', 'upd')))
    core.append(('update_entry_is_call', use(up + 'ftb_entry_isCall', 'upd')))
    core.append(('update_entry_is_ret', use(up + 'ftb_entry_isRet', 'upd')))
    core.append(('update_tail_slot_offset', use(up + 'ftb_entry_tailSlot_offset', 'upd')))
    core.append(('update_tail_slot_valid', use(up + 'ftb_entry_tailSlot_valid', 'upd')))
    core.append(('update_cfi_idx_valid', use(up + 'cfi_idx_valid', 'upd')))
    core.append(('update_cfi_idx_bits', use(up + 'cfi_idx_bits', 'upd')))
    core.append(('update_jmp_taken', use(up + 'jmp_taken', 'upd')))
    core.append(('update_meta', use(up + 'meta', 'upd')))

    # 核 <-> RASStack 的内部线
    core += [
        ('stack_top_addr', 'stack_top_addr'),
        ('stack_snap', 'stack_snap'),
        ('stack_near_overflow', 'stack_near_overflow'),
        ('stack_spec_push', 'stack_spec_push'),
        ('stack_spec_pop', 'stack_spec_pop'),
        ('stack_spec_push_addr', 'stack_spec_push_addr'),
        ('stack_s3_cancel', 'stack_s3_cancel'),
        ('stack_s3_snap', 'stack_s3_snap'),
        ('stack_s3_missed_pop', 'stack_s3_missed_pop'),
        ('stack_s3_missed_push', 'stack_s3_missed_push'),
        ('stack_s3_push_addr', 'stack_s3_push_addr'),
        ('stack_commit_valid', 'stack_commit_valid'),
        ('stack_commit_push', 'stack_commit_push'),
        ('stack_commit_pop', 'stack_commit_pop'),
        ('stack_commit_tosw', 'stack_commit_tosw'),
        ('stack_commit_ssp', 'stack_commit_ssp'),
        ('stack_redirect_valid', 'stack_redirect_valid'),
        ('stack_redirect_is_call', 'stack_redirect_is_call'),
        ('stack_redirect_is_ret', 'stack_redirect_is_ret'),
        ('stack_redirect_snap', 'stack_redirect_snap'),
        ('stack_redirect_call_addr', 'stack_redirect_call_addr'),
    ]

    # 其余输出：io_out_<x> 原样直通 io_in_bits_resp_in_0_<x>
    for d, w, n in ports:
        if d != 'output' or n in used:
            continue
        if not n.startswith('io_out_'):
            fail('输出端口 %s 没有规则' % n)
        src = pin + n[len('io_out_'):]
        if src not in P or P[src] != ('input', w):
            fail('输出 %s 找不到同宽直通源 %s' % (n, src))
        use(n, 'passthrough_out')
        if src not in used:
            use(src, 'passthrough_in')
        elif used[src] != 'passthrough_in':
            fail('直通源 %s 已被 %s 认领' % (src, used[src]))
        out_assign.append((n, src))
    # 判 call/ret 用的第 2 份字段：既进核又直通（golden 的 is_call/is_ret 等也有同名输出）
    for n in shared_in:
        if n in used:
            continue
        use(n, 'core_only_in')
    missing = [n for _, _, n in ports if n not in used and n not in ('clock', 'reset')]
    if missing:
        fail('golden 端口无规则认领: %s' % missing[:10])

    # RASStack 连线
    stack_map = {
        'clock': 'clock', 'reset': 'reset',
        'io_spec_push_valid': 'stack_spec_push', 'io_spec_pop_valid': 'stack_spec_pop',
        'io_spec_push_addr': 'stack_spec_push_addr',
        'io_s2_fire': 'io_s2_fire_2', 'io_s3_fire': 'io_s3_fire_2',
        'io_s3_cancel': 'stack_s3_cancel',
        'io_s3_missed_pop': 'stack_s3_missed_pop', 'io_s3_missed_push': 'stack_s3_missed_push',
        'io_s3_pushAddr': 'stack_s3_push_addr', 'io_spec_pop_addr': 'stack_top_addr',
        'io_commit_valid': 'stack_commit_valid', 'io_commit_push_valid': 'stack_commit_push',
        'io_commit_pop_valid': 'stack_commit_pop',
        'io_commit_meta_TOSW_flag': 'stack_commit_tosw.flag',
        'io_commit_meta_TOSW_value': 'stack_commit_tosw.value',
        'io_commit_meta_ssp': 'stack_commit_ssp',
        'io_redirect_valid': 'stack_redirect_valid', 'io_redirect_isCall': 'stack_redirect_is_call',
        'io_redirect_isRet': 'stack_redirect_is_ret', 'io_redirect_callAddr': 'stack_redirect_call_addr',
        'io_spec_near_overflow': 'stack_near_overflow',
    }
    snapf = {'ssp': 'ssp', 'sctr': 'sctr', 'TOSW_flag': 'tosw.flag', 'TOSW_value': 'tosw.value',
             'TOSR_flag': 'tosr.flag', 'TOSR_value': 'tosr.value', 'NOS_flag': 'nos.flag',
             'NOS_value': 'nos.value'}
    for f, sf in snapf.items():
        stack_map['io_s3_meta_' + f] = 'stack_s3_snap.' + sf
        stack_map['io_redirect_meta_' + f] = 'stack_redirect_snap.' + sf
        stack_map['io_' + f] = 'stack_snap.' + sf
    sconn = []
    for d, w, n in stack_ports:
        if n not in stack_map:
            fail('RASStack 端口 %s 无连线规则' % n)
        sconn.append((n, stack_map.pop(n)))
    if stack_map:
        fail('RASStack 连线规则多余: %s' % sorted(stack_map))
    return core, out_assign, sconn


def emit_wrapper(ports, core, out_assign, sconn):
    L = ['// BEGIN GENERATED(RAS) —— scripts/gen_ras.py',
         'module RAS',
         '  import ras_pred_pkg::*;',
         '(']
    L.append(',\n'.join('  %-6s logic %s%s' % (d, ('[%d:0]' % (w - 1)).ljust(8) if w > 1 else ' ' * 8, n)
                        for d, w, n in ports))
    L.append(');')
    L.append('')
    L.append('  // 核 <-> RASStack')
    L += ['  logic [PC_W-1:0]  stack_top_addr, stack_spec_push_addr, stack_s3_push_addr, stack_redirect_call_addr;',
          '  ras_snap_t        stack_snap, stack_s3_snap, stack_redirect_snap;',
          '  ras_pred_ptr_t    stack_commit_tosw;',
          '  logic [SSP_W-1:0] stack_commit_ssp;',
          '  logic             stack_near_overflow, stack_spec_push, stack_spec_pop, stack_s3_cancel;',
          '  logic             stack_s3_missed_pop, stack_s3_missed_push;',
          '  logic             stack_commit_valid, stack_commit_push, stack_commit_pop;',
          '  logic             stack_redirect_valid, stack_redirect_is_call, stack_redirect_is_ret;',
          '']
    L.append('  xs_RAS_core u_core (')
    conns = [('clock', 'clock'), ('reset', 'reset')] + core
    L.append(',\n'.join('    .%-24s (%s)' % c for c in conns))
    L.append('  );')
    L.append('')
    L.append('  RASStack RASStack (')
    L.append(',\n'.join('    .%-27s (%s)' % c for c in sconn))
    L.append('  );')
    L.append('')
    L.append('  // 本层不改动的预测字段：原样直通')
    for n, s in out_assign:
        L.append('  assign %s = %s;' % (n, s))
    L.append('')
    L.append('endmodule')
    L.append('// END GENERATED(RAS)')
    return '\n'.join(L) + '\n'


# --------------------------------------------------------------------------
# 钉点：golden 寄存器 -> 核内名字
# --------------------------------------------------------------------------
# 结构体寄存器在 FM 里的名字是按字段展开的：<名>_reg\[字段]\[子字段][位]（单比特字段不带 [位]）
SNAP_FIELD = {'ssp': ('ssp',), 'sctr': ('sctr',), 'TOSW_flag': ('tosw', 'flag'), 'TOSW_value': ('tosw', 'value'),
              'TOSR_flag': ('tosr', 'flag'), 'TOSR_value': ('tosr', 'value'),
              'NOS_flag': ('nos', 'flag'), 'NOS_value': ('nos', 'value')}
SNAP_W = {'ssp': 4, 'sctr': 3, 'TOSW_flag': 1, 'TOSW_value': 5, 'TOSR_flag': 1, 'TOSR_value': 5,
          'NOS_flag': 1, 'NOS_value': 5}


def sfield(reg, path, b):
    """结构体位的 FM 名字：reg_reg\[f1]\[f2][b]。"""
    n = reg + '_reg' + ''.join('\\[%s]' % f for f in path)
    return n if b is None else '%s[%d]' % (n, b)


def reg_rule(name, w):
    """-> [(golden 位名, impl 位名)]，命不中返回 None。"""
    def bits(gn, f):
        if w == 1:
            return [('%s_reg' % gn, f(None))]
        return [('%s_reg[%d]' % (gn, b), f(b)) for b in range(w)]

    simple = {
        'modified_reset': 'modified_reset', 's3_top': 's3_top', 's3_spec_new_addr': 's3_push_addr',
        's3_pushed_in_s2': 's3_pushed_in_s2', 's3_popped_in_s2': 's3_popped_in_s2',
        'redirect_next_valid_last_REG': 'rd_valid', 'redirect_next_bits_r_level': 'rd_level',
        'redirect_next_bits_r_cfiUpdate_pc': 'rd_pc',
        'redirect_next_bits_r_cfiUpdate_pd_valid': 'rd_pd_valid',
        'redirect_next_bits_r_cfiUpdate_pd_isRVC': 'rd_pd_is_rvc',
        'redirect_next_bits_r_cfiUpdate_pd_isCall': 'rd_pd_is_call',
        'redirect_next_bits_r_cfiUpdate_pd_isRet': 'rd_pd_is_ret',
        'updateValid': 'upd_valid', 'update_r_ftb_entry_isCall': 'upd_is_call',
        'update_r_ftb_entry_isRet': 'upd_is_ret',
        'update_r_ftb_entry_tailSlot_offset': 'upd_tail_offset',
        'update_r_ftb_entry_tailSlot_valid': 'upd_tail_valid',
        'update_r_cfi_idx_valid': 'upd_cfi_valid', 'update_r_cfi_idx_bits': 'upd_cfi_idx',
        'update_r_jmp_taken': 'upd_jmp_taken', 'updateMeta_ssp': 'upd_ssp',
    }
    if name in simple:
        i = simple[name]
        return bits(name, lambda b: '%s_reg' % i if b is None else '%s_reg[%d]' % (i, b))
    if name == 'updateMeta_TOSW_flag':
        return bits(name, lambda b: sfield('upd_tosw', ('flag',), None))
    if name == 'updateMeta_TOSW_value':
        return bits(name, lambda b: sfield('upd_tosw', ('value',), b))
    m = re.fullmatch(r's1_pc_dup_(\d)', name)
    if m:
        d = int(m.group(1))
        return bits(name, lambda b: 's1_pc_reg[%d][%d]' % (d, b))
    m = re.fullmatch(r's([23])_pc_dup_s\1_pc_seg_([012])_value(?:_(\d))?', name)
    if m:
        st, seg, d = m.group(1), int(m.group(2)), int(m.group(3) or 0)
        seg_name = ['hi', 'mid', 'lo'][seg]
        return bits(name, lambda b: 's%s_pc_%s_reg[%d][%d]' % (st, seg_name, d, b))
    for pre, i in (('s3_meta_', 's3_snap'), ('redirect_next_bits_r_cfiUpdate_', 'rd_snap')):
        f = name[len(pre):]
        if name.startswith(pre) and f in SNAP_FIELD:
            if SNAP_W[f] != w:
                fail('%s 宽度 %d != 快照字段宽 %d' % (name, w, SNAP_W[f]))
            return bits(name, lambda b, f=f, i=i: sfield(i, SNAP_FIELD[f], b))
    return None


def build_pins(body):
    regs = [(m.group(2), int(m.group(1)) + 1 if m.group(1) else 1)
            for m in re.finditer(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);', body, re.M)]
    pairs, seen = [], set()
    for n, w in regs:
        r = reg_rule(n, w)
        if r is None:
            fail('golden 寄存器 %s 无映射规则' % n)
        for g, i in r:
            if i in seen:
                fail('映射非单射：%s 被两次映射' % i)
            seen.add(i)
            pairs.append((g, i))
    L = ['# RAS FM「匹配前」钉点 —— 自动生成：scripts/gen_ras.py（勿手改）',
         '#',
         '# 只消 golden 扁平寄存器名（firtool 按 dup / 字段展开）与可读核数组 / 结构体之间的命名鸿沟。',
         '# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。',
         '# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），逐条数返回值；',
         '# 拒一条或总数不等于字面整数（= golden RAS 顶层寄存器位数）就 error（safe interp 里不用 exit）。',
         '# 子模块 RASStack 内部不钉（两侧同实例名，单独签核时也未用钉点）。进 fm.log 的输出一律 ASCII。',
         'set ::RAS_PIN_EXPECT %d' % len(pairs),
         'set ::RAS_PIN_OK 0',
         'set ::RAS_PIN_BAD 0',
         'proc ras_pin {r i} {',
         '  if {[set_user_match "r:/WORK/RAS/$r" "i:/WORK/RAS/u_core/$i"]} { incr ::RAS_PIN_OK } else {',
         '    incr ::RAS_PIN_BAD',
         '    if {$::RAS_PIN_BAD <= 10} { puts "RAS_PIN_FAIL: $r <-> $i" }',
         '  }',
         '}',
         'puts "RAS_PIN_BEGIN RAS expect=$::RAS_PIN_EXPECT"']
    for g, i in pairs:
        L.append('ras_pin {%s} {%s}' % (g, i))
    L += ['puts "RAS_PIN_END RAS ok=$::RAS_PIN_OK bad=$::RAS_PIN_BAD expect=$::RAS_PIN_EXPECT"',
          'if {$::RAS_PIN_BAD != 0 || $::RAS_PIN_OK != %d} {' % len(pairs),
          '  error "RAS_PIN_COUNT ok=$::RAS_PIN_OK bad=$::RAS_PIN_BAD"',
          '}']
    return '\n'.join(L) + '\n', len(pairs)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    ports, body = golden_module('RAS')
    stack_ports, _ = golden_module('RASStack')
    core, out_assign, sconn = build_wrapper(ports, stack_ports)
    wrap = emit_wrapper(ports, core, out_assign, sconn)
    src = open(RTL).read()
    i = src.index('// BEGIN GENERATED(RAS)')
    j = src.index('// END GENERATED(RAS)') + len('// END GENERATED(RAS)\n')
    new = src[:i] + wrap + src[j:]
    pins, npins = build_pins(body)
    bad = 0
    for p, t in ((RTL, new), (PINS, pins)):
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != t:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != t:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, 'w').write(t)
    print('RAS wrapper: %d 端口 / %d 直通 / %d 核连线；钉点 %d 位' % (len(ports), len(out_assign), len(core), npins))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
