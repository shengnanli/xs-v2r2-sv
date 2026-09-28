#!/usr/bin/env python3
"""gen_l2_sinkc.py —— SinkC 的机械部分：TaskBundle 结构体与 golden 同名 wrapper。

可读核 xs_SinkC_core 在 rtl/uncore/SinkC.sv 里手写，本脚本**不碰**；它只原地替换同一文件的
GENERATED(task_t) / GENERATED(wrapper) 两个区：

  task_t   io_task_bits_* 的 94 个字段（顺序、位宽逐字取自 golden），并核对 RRArbiterInit_16（taskArb）的
           io_in_0_bits_* / io_out_bits_* 字段表与之完全相同。第一个字段放最高位；`alias` 写成 alias_。
  wrapper  端口按 golden；taskArb 按 golden 实例名例化（4 路 = 核的 taskBuf，出口 bits 直连 io_task_bits_*）；
           msInfo_<i>_* 打包成核的数组口。
不生成 FM 钉点（同类的 RequestArb / RequestBuffer 实测 FM 能自己配上结构体与数组寄存器；若第一跑出现落单，
再按实测名字补）。

用法：python3 scripts/gen_l2_sinkc.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = os.path.join(REPO, 'rtl', 'uncore', 'SinkC.sv')
MOD = 'SinkC'
SV_KEYWORDS = {'alias'}
N_BUF, N_MSHR = 4, 16
MS_F = ['valid', 'set', 'reqTag', 'blockRefill']


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('module %s(' % mod)
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def fname(f):
    return f + '_' if f in SV_KEYWORDS else f


def fields(P, prefix):
    return [(n[len(prefix):], w) for _, w, n in P if n.startswith(prefix)]


def build():
    P = ports(MOD)
    T = fields(P, 'io_task_bits_')
    assert len(T) == 94, len(T)
    AP = ports('RRArbiterInit_16')
    for k in range(N_BUF):
        assert fields(AP, 'io_in_%d_bits_' % k) == T, 'taskArb io_in_%d 字段表不同' % k
    assert fields(AP, 'io_out_bits_') == T, 'taskArb io_out 字段表不同'
    names = {n for _, _, n in P}
    for f in MS_F:
        for i in range(N_MSHR):
            assert 'io_msInfo_%d_%s' % (i, 'valid' if f == 'valid' else 'bits_' + f) in names, (f, i)
    return P, T


def emit_struct(T):
    L = ['  // TaskBundle（%d 个字段，%d 位）：字段顺序与位宽逐字取自 golden 端口 io_task_bits_*' % (len(T), sum(w for _, w in T)),
         '  typedef struct packed {']
    for f, w in T:
        L.append('    logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), fname(f)))
    L.append('  } task_t;')
    return '\n'.join(L)


def emit_wrapper(P, T):
    L = []
    W = L.append
    W('module %s' % MOD)
    W('  import sinkc_pkg::*;')
    W('(')
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    W('  logic  arbIn_valid [N_BUF];')
    W('  task_t arbIn_task  [N_BUF];')
    W('  logic  arbIn_ready [N_BUF];')
    W('  logic [255:0] bufResp [2];')
    W('')
    ms = [('ms_' + f, "'{" + ', '.join('io_msInfo_%d_%s' % (i, 'valid' if f == 'valid' else 'bits_' + f)
                                     for i in range(N_MSHR)) + '}') for f in MS_F]
    conns = [('clock', 'clock'), ('reset', 'reset'),
             ('c_valid', 'io_c_valid'), ('c_ready', 'io_c_ready'), ('c_opcode', 'io_c_bits_opcode'),
             ('c_param', 'io_c_bits_param'), ('c_size', 'io_c_bits_size'), ('c_source', 'io_c_bits_source'),
             ('c_address', 'io_c_bits_address'), ('c_data', 'io_c_bits_data'), ('c_corrupt', 'io_c_bits_corrupt'),
             ('arbIn_valid', 'arbIn_valid'), ('arbIn_task', 'arbIn_task'), ('arbIn_ready', 'arbIn_ready'),
             ('arbOut_valid', 'io_task_valid'), ('arbOut_set', 'io_task_bits_set'), ('arbOut_tag', 'io_task_bits_tag'),
             ('arbOut_opcode', 'io_task_bits_opcode'), ('arbOut_bufIdx', 'io_task_bits_bufIdx'),
             ('task_ready', 'io_task_ready'),
             ('resp_valid', 'io_resp_valid'), ('resp_set', 'io_resp_set'), ('resp_tag', 'io_resp_tag'),
             ('resp_last', 'io_resp_respInfo_last'), ('resp_denied', 'io_resp_respInfo_denied'),
             ('resp_corrupt', 'io_resp_respInfo_corrupt'),
             ('releaseBufWrite_valid', 'io_releaseBufWrite_valid'),
             ('releaseBufWrite_data', 'io_releaseBufWrite_bits_data_data'),
             ('bufResp_data', 'bufResp'),
             ('refillBufWrite_valid', 'io_refillBufWrite_valid'), ('refillBufWrite_id', 'io_refillBufWrite_bits_id'),
             ('refillBufWrite_data', 'io_refillBufWrite_bits_data_data')] + ms
    W('  xs_SinkC_core u_core (')
    W(',\n'.join('    .%-22s (%s)' % c for c in conns))
    W('  );')
    W('')
    W('  assign io_resp_respInfo_opcode = io_c_bits_opcode;')
    W('  assign io_resp_respInfo_param  = io_c_bits_param;')
    W('  assign io_bufResp_data_0 = bufResp[0];')
    W('  assign io_bufResp_data_1 = bufResp[1];')
    W('')
    W('  // 4 项 Release 任务轮转仲裁（出口直接就是 io_task）')
    W('  RRArbiterInit_16 taskArb (')
    ac = [('clock', 'clock'), ('reset', 'reset')]
    for k in range(N_BUF):
        ac += [('io_in_%d_ready' % k, 'arbIn_ready[%d]' % k), ('io_in_%d_valid' % k, 'arbIn_valid[%d]' % k)]
        for f, _ in T:
            ac.append(('io_in_%d_bits_%s' % (k, f), 'arbIn_task[%d].%s' % (k, fname(f))))
    ac += [('io_out_ready', 'io_task_ready'), ('io_out_valid', 'io_task_valid')]
    for f, _ in T:
        ac.append(('io_out_bits_%s' % f, 'io_task_bits_%s' % f))
    W(',\n'.join('    .%-40s (%s)' % c for c in ac))
    W('  );')
    W('')
    W('endmodule')
    return '\n'.join(L)


def replace_region(txt, tag, body):
    b = re.search(r'(// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(// END GENERATED\(%s\))' % (tag, tag), txt, re.S)
    assert b, '找不到 GENERATED(%s) 区' % tag
    indent = re.match(r'\s*', txt[txt.rfind('\n', 0, b.start()) + 1:]).group(0)
    return txt[:b.start()] + b.group(1) + body + '\n' + indent + b.group(3) + txt[b.end():]


def with_nav(txt):
    if txt.count('\n') + 1 <= 1500:
        return txt
    import tempfile
    import pathlib
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import gen_file_nav
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d) / 'SinkC.sv'
        tmp.write_text(txt)
        gen_file_nav.apply(tmp)
        return tmp.read_text()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    P, T = build()
    cur = open(RTL).read()
    new = replace_region(cur, 'task_t', emit_struct(T))
    new = replace_region(new, 'wrapper', emit_wrapper(P, T))
    new = with_nav(new)
    if a.check:
        if cur != new:
            print('DRIFT: %s' % RTL)
            return 1
        return 0
    if cur != new:
        open(RTL, 'w').write(new)
    print('SinkC: task_t %d 字段 / %d 位' % (len(T), sum(w for _, w in T)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
