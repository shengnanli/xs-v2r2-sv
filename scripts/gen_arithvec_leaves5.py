#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_arithvec_leaves5.py —— 族 A（算术/向量运算叶）5 个目标的 wrapper 生成器。

对 rtl/backend/{Adder_chain_rnd,DivUnit,FDivSqrt,VIAluDecoder,VIntAdder64b}.sv
里的 `// BEGIN GENERATED(wrapper)` / `// END GENERATED(wrapper)` 区域做原地替换，
生成 golden 同名 wrapper：端口表逐位照抄 G1 golden（同名同宽同方向同顺序），
内部只做「golden 扁平端口 <-> xs_<M>_core 语义端口」的拆装与例化连线。

fail-closed 自检（任何一条不满足都拒绝生成）：
  * golden 端口表里的每个端口恰好被映射消费一次；
  * 核端口表里的每个端口恰好被映射消费一次；
  * 标量映射两侧位宽/方向一致；vec 映射各位宽度之和等于核端口宽；
    arr 映射元素宽等于核数组元素宽、个数等于数组长度；
  * 找不到 GENERATED(wrapper) 标记 -> 拒绝。

--check：只比对不写；内容不变退出 0，会变退出 1。
"""
import argparse
import os
import pathlib
import re

REPO = pathlib.Path(__file__).resolve().parents[1]
GOLDEN_DIR = pathlib.Path(os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical')) / 'golden-rtl'
RTL_DIR = REPO / 'rtl/backend'

GOLDEN_PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')
CORE_PORT_RE = re.compile(
    r'^\s*(input|output)\s+logic\s*(?:\[(\d+):0\])?\s*(\w+)(?:\s*\[(\d+)\])?\s*,?\s*$')

# 每个模块的映射规则：
#   scalars: golden 端口名 -> 核端口名（位宽必须相等，方向必须一致）
#   vec:     核端口名 -> (golden 端口名模板 % i, [下标列表])；核端口是压缩向量，
#            按模板列出的 golden 端口**按下标列表顺序从低到高**拼接
#   arr:     核端口名 -> (golden 端口名模板 % i, [下标列表])；核端口是 unpacked
#            数组，元素一一对应
def _perf_map(prefix_g, prefix_c):
    """perfDebugInfo/debug_seqNum 整组的机械映射（in_/out_ 两侧共用同一张表）。"""
    fields = [
        ('eliminatedMove', 'eliminated_move', 1),
        ('renameTime', 'rename_time', 64),
        ('dispatchTime', 'dispatch_time', 64),
        ('enqRsTime', 'enq_rs_time', 64),
        ('selectTime', 'select_time', 64),
        ('issueTime', 'issue_time', 64),
        ('writebackTime', 'writeback_time', 64),
        ('runahead_checkpoint_id', 'runahead_checkpoint_id', 64),
        ('tlbFirstReqTime', 'tlb_first_req_time', 64),
        ('tlbRespTime', 'tlb_resp_time', 64),
    ]
    m = {}
    for g, c, _ in fields:
        m['%s_perfDebugInfo_%s' % (prefix_g, g)] = '%s_perf_%s' % (prefix_c, c)
    m['%s_debug_seqNum_seqNum' % prefix_g] = '%s_dbg_seq_num' % prefix_c
    m['%s_debug_seqNum_uopIdx' % prefix_g] = '%s_dbg_uop_idx' % prefix_c
    return m


SPECS = {
    'Adder_chain_rnd': {
        'scalars': {
            'io_isNClip': 'is_nclip',
            'io_sew_oneHot': 'sew_one_hot',
        },
        'vec': {
            'rnd_inc':   ('io_rndInc_%d', list(range(0, 8))),
            'cout':      ('io_cout_%d', list(range(0, 7))),
            'all_ones':  ('io_all_1s_%d', list(range(1, 8))),
            'all_zeros': ('io_all_0s_%d', list(range(1, 8))),
        },
        'arr': {
            'din':  ('io_din_%d', list(range(0, 8))),
            'dout': ('io_dout_%d', list(range(0, 8))),
        },
    },
    'VIAluDecoder': {
        'scalars': {
            'io_in_fuOpType': 'fu_op_type',
            'io_out_opcode': 'opcode',
            'io_out_srcType2': 'src_type2',
            'io_out_vdType': 'vd_type',
        },
        'vec': {},
        'arr': {},
    },
    'VIntAdder64b': {
        'scalars': {
            'io_opcode_op': 'opcode_op',
            'io_info_vm': 'info_vm',
            'io_info_ma': 'info_ma',
            'io_info_uopIdx': 'info_uop_idx',
            'io_srcType_1': 'src_type1',
            'io_vdType': 'vd_type',
            'io_vs1': 'vs1',
            'io_vs2': 'vs2',
            'io_vmask': 'vmask',
            'io_oldVd': 'old_vd',
            'io_isSub': 'is_sub',
            'io_widen': 'widen',
            'io_widen_vs2': 'widen_vs2',
            'io_vd': 'vd',
            'io_cmpOut': 'cmp_out',
        },
        'vec': {
            'fixp_cout': ('io_toFixP_cout_%d', list(range(0, 8))),
            'fixp_vd':   ('io_toFixP_vd_%d', list(range(0, 8))),
            'fixp_vs2h': ('io_toFixP_vs2H_%d', list(range(0, 8))),
            'fixp_vs1h': ('io_toFixP_vs1H_%d', list(range(0, 8))),
        },
        'arr': {},
    },
    'DivUnit': {
        'scalars': dict(
            {
                'clock': 'clock',
                'reset': 'reset',
                'io_flush_valid': 'flush_valid',
                'io_flush_bits_robIdx_flag': 'flush_rob_flag',
                'io_flush_bits_robIdx_value': 'flush_rob_value',
                'io_flush_bits_level': 'flush_level',
                'io_in_ready': 'in_ready',
                'io_in_valid': 'in_valid',
                'io_in_bits_ctrl_fuOpType': 'in_fu_op_type',
                'io_in_bits_ctrl_robIdx_flag': 'in_rob_flag',
                'io_in_bits_ctrl_robIdx_value': 'in_rob_value',
                'io_in_bits_ctrl_pdest': 'in_pdest',
                'io_in_bits_ctrl_rfWen': 'in_rf_wen',
                'io_in_bits_data_src_1': 'in_src1',
                'io_in_bits_data_src_0': 'in_src0',
                'io_out_ready': 'out_ready',
                'io_out_valid': 'out_valid',
                'io_out_bits_ctrl_robIdx_flag': 'out_rob_flag',
                'io_out_bits_ctrl_robIdx_value': 'out_rob_value',
                'io_out_bits_ctrl_pdest': 'out_pdest',
                'io_out_bits_ctrl_rfWen': 'out_rf_wen',
                'io_out_bits_res_data': 'out_res_data',
            },
            **_perf_map('io_in_bits', 'in'),
            **_perf_map('io_out_bits', 'out'),
        ),
        'vec': {},
        'arr': {},
    },
    'FDivSqrt': {
        'scalars': dict(
            {
                'clock': 'clock',
                'reset': 'reset',
                'io_flush_valid': 'flush_valid',
                'io_flush_bits_robIdx_flag': 'flush_rob_flag',
                'io_flush_bits_robIdx_value': 'flush_rob_value',
                'io_flush_bits_level': 'flush_level',
                'io_in_ready': 'in_ready',
                'io_in_valid': 'in_valid',
                'io_in_bits_ctrl_fuOpType': 'in_fu_op_type',
                'io_in_bits_ctrl_robIdx_flag': 'in_rob_flag',
                'io_in_bits_ctrl_robIdx_value': 'in_rob_value',
                'io_in_bits_ctrl_pdest': 'in_pdest',
                'io_in_bits_ctrl_fpWen': 'in_fp_wen',
                'io_in_bits_ctrl_fpu_wflags': 'in_fpu_wflags',
                'io_in_bits_ctrl_fpu_fmt': 'in_fpu_fmt',
                'io_in_bits_ctrl_fpu_rm': 'in_fpu_rm',
                'io_in_bits_data_src_1': 'in_src1',
                'io_in_bits_data_src_0': 'in_src0',
                'io_out_ready': 'out_ready',
                'io_out_valid': 'out_valid',
                'io_out_bits_ctrl_robIdx_flag': 'out_rob_flag',
                'io_out_bits_ctrl_robIdx_value': 'out_rob_value',
                'io_out_bits_ctrl_pdest': 'out_pdest',
                'io_out_bits_ctrl_fpWen': 'out_fp_wen',
                'io_out_bits_ctrl_fpu_wflags': 'out_fpu_wflags',
                'io_out_bits_res_data': 'out_res_data',
                'io_out_bits_res_fflags': 'out_res_fflags',
                'io_frm': 'frm',
            },
            **_perf_map('io_in_bits', 'in'),
            **_perf_map('io_out_bits', 'out'),
        ),
        'vec': {},
        'arr': {},
    },
}

BEGIN = '// BEGIN GENERATED(wrapper) —— scripts/gen_arithvec_leaves5.py 生成，勿手改'
END = '// END GENERATED(wrapper)'


def die(mod, msg):
    raise SystemExit('gen_arithvec_leaves5: ★拒绝生成★ [%s] %s' % (mod, msg))


def golden_ports(mod):
    text = (GOLDEN_DIR / (mod + '.sv')).read_text()
    m = re.search(r'^module %s\((.*?)\n\);' % mod, text, re.S | re.M)
    if not m:
        die(mod, 'golden 里找不到模块端口表')
    ports = []
    for line in m.group(1).splitlines():
        if not line.strip():
            continue
        pm = GOLDEN_PORT_RE.match(line)
        if not pm:
            die(mod, '不认识的 golden 端口行: %r' % line)
        w = int(pm.group(2)) + 1 if pm.group(2) else 1
        ports.append((pm.group(3), pm.group(1), w))
    return ports


def core_ports(mod, text):
    core = 'xs_%s_core' % mod
    m = re.search(r'^module %s\s*\((.*?)\n\);' % core, text, re.S | re.M)
    if not m:
        die(mod, '文件里找不到核模块 %s 的端口表' % core)
    ports = []
    for line in m.group(1).splitlines():
        line = line.split('//')[0]
        if not line.strip():
            continue
        pm = CORE_PORT_RE.match(line)
        if not pm:
            die(mod, '不认识的核端口行（生成器只认最简声明风格）: %r' % line)
        w = int(pm.group(2)) + 1 if pm.group(2) else 1
        arr = int(pm.group(4)) if pm.group(4) else None
        ports.append((pm.group(3), pm.group(1), w, arr))
    return ports


def build_wrapper(mod, spec, gports, cports):
    gmap = {n: (d, w) for n, d, w in gports}
    cmap = {n: (d, w, a) for n, d, w, a in cports}
    # ---- 组装 golden 端口 -> 核端口 的全映射并做穷尽核对 ----
    consumed_golden = set()
    consumed_core = set()
    scalar_conn = []      # (core_port, golden_port)
    vec_pack = []         # (core_port, dir, total_w, [(golden_port, w)])（按下标升序）
    arr_pack = []         # (core_port, dir, elem_w, count, [golden_port])

    for g, c in spec['scalars'].items():
        if g not in gmap:
            die(mod, '标量映射的 golden 端口 %s 不存在' % g)
        if c not in cmap:
            die(mod, '标量映射的核端口 %s 不存在' % c)
        gd, gw = gmap[g]
        cd, cw, ca = cmap[c]
        if gd != cd:
            die(mod, '端口 %s/%s 方向不符（%s vs %s）' % (g, c, gd, cd))
        if gw != cw:
            die(mod, '端口 %s/%s 位宽不符（%d vs %d）' % (g, c, gw, cw))
        if ca is not None:
            die(mod, '核端口 %s 是数组，不能用标量映射' % c)
        consumed_golden.add(g)
        consumed_core.add(c)
        scalar_conn.append((c, g))

    for c, (fmt, idxs) in spec['vec'].items():
        if c not in cmap:
            die(mod, 'vec 映射的核端口 %s 不存在' % c)
        cd, cw, ca = cmap[c]
        if ca is not None:
            die(mod, '核端口 %s 是数组，应走 arr 映射' % c)
        elems = []
        total = 0
        for i in idxs:
            g = fmt % i
            if g not in gmap:
                die(mod, 'vec 映射的 golden 端口 %s 不存在' % g)
            gd, gw = gmap[g]
            if gd != cd:
                die(mod, 'vec %s 的 golden 端口 %s 方向 %s 与核 %s 不符' % (c, g, gd, cd))
            if g in consumed_golden:
                die(mod, 'golden 端口 %s 被重复消费' % g)
            consumed_golden.add(g)
            elems.append((g, gw))
            total += gw
        if total != cw:
            die(mod, 'vec %s 位宽和 %d 与核端口宽 %d 不符' % (c, total, cw))
        consumed_core.add(c)
        vec_pack.append((c, cd, cw, elems))

    for c, (fmt, idxs) in spec['arr'].items():
        if c not in cmap:
            die(mod, 'arr 映射的核端口 %s 不存在' % c)
        cd, cw, ca = cmap[c]
        if ca is None:
            die(mod, '核端口 %s 不是数组，不能用 arr 映射' % c)
        if len(idxs) != ca:
            die(mod, 'arr %s 元素数 %d 与核数组长度 %d 不符' % (c, len(idxs), ca))
        elems = []
        for i in idxs:
            g = fmt % i
            if g not in gmap:
                die(mod, 'arr 映射的 golden 端口 %s 不存在' % g)
            gd, gw = gmap[g]
            if gd != cd:
                die(mod, 'arr %s 的 golden 端口 %s 方向 %s 与核 %s 不符' % (c, g, gd, cd))
            if gw != cw:
                die(mod, 'arr %s 元素宽 %d 与核元素宽 %d 不符' % (c, gw, cw))
            if g in consumed_golden:
                die(mod, 'golden 端口 %s 被重复消费' % g)
            consumed_golden.add(g)
            elems.append(g)
        consumed_core.add(c)
        arr_pack.append((c, cd, cw, ca, elems))

    left_g = sorted(set(gmap) - consumed_golden)
    left_c = sorted(set(cmap) - consumed_core)
    if left_g:
        die(mod, '以下 golden 端口没被映射消费: %r' % left_g)
    if left_c:
        die(mod, '以下核端口没被映射消费: %r' % left_c)

    # ---- 生成 wrapper ----
    out = []
    out.append('module %s(' % mod)
    for k, (n, d, w) in enumerate(gports):
        rng = '' if w == 1 else '[%d:0] ' % (w - 1)
        out.append('  %-6s %s%s%s' % (d, rng, n, ',' if k + 1 < len(gports) else ''))
    out.append(');')
    out.append('')

    if vec_pack or arr_pack:
        out.append('  // ---- golden 扁平端口 <-> 核语义端口的拆装（生成）----')
    for c, d, w, elems in vec_pack:
        out.append('  logic [%d:0] %s;' % (w - 1, c))
    for c, d, w, cnt, elems in arr_pack:
        out.append('  logic [%d:0] %s [%d];' % (w - 1, c, cnt))
    if vec_pack or arr_pack:
        out.append('')
    for c, d, w, elems in vec_pack:
        cat = ', '.join(g for g, _ in reversed(elems))
        if d == 'input':
            out.append('  assign %s = {%s};' % (c, cat))
        else:
            out.append('  assign {%s} = %s;' % (cat, c))
    for c, d, w, cnt, elems in arr_pack:
        for k, g in enumerate(elems):
            if d == 'input':
                out.append('  assign %s[%d] = %s;' % (c, k, g))
            else:
                out.append('  assign %s = %s[%d];' % (g, c, k))
    if vec_pack or arr_pack:
        out.append('')

    out.append('  xs_%s_core u_core (' % mod)
    conns = []
    for n, d, w, a in cports:
        if any(c == n for c, _ in scalar_conn):
            g = next(g for c, g in scalar_conn if c == n)
            conns.append('    .%s (%s)' % (n, g))
        else:
            conns.append('    .%s (%s)' % (n, n))
    out.append(',\n'.join(conns))
    out.append('  );')
    out.append('endmodule')
    return '\n'.join(out) + '\n'


def replace_region(text, body):
    pat = re.compile(re.escape(BEGIN) + r'\n.*?' + re.escape(END), re.S)
    m = pat.search(text)
    if not m:
        raise SystemExit('gen_arithvec_leaves5: ★拒绝生成★ 找不到 GENERATED(wrapper) 标记')
    return text[:m.start()] + BEGIN + '\n' + body + END + text[m.end():]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()

    drift = []
    for mod, spec in SPECS.items():
        path = RTL_DIR / (mod + '.sv')
        text = path.read_text()
        gports = golden_ports(mod)
        cports = core_ports(mod, text)
        body = build_wrapper(mod, spec, gports, cports)
        new = replace_region(text, body)
        if args.check:
            if new != text:
                drift.append(str(path))
        elif new != text:
            path.write_text(new)
            print('写入 %s' % path.relative_to(REPO))

    if drift:
        print('gen_arithvec_leaves5 --check: DRIFT: ' + ' '.join(drift))
        raise SystemExit(1)
    if args.check:
        print('gen_arithvec_leaves5 --check: OK (%d files)' % len(SPECS))


if __name__ == '__main__':
    main()
