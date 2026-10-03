#!/usr/bin/env python3
"""gen_tlxbar5_wrapper.py —— TLXbar_5（L2Top 的 l1_xbar，3 主 × 4 从 TileLink-C 交叉开关）的 golden 同名 wrapper。

核 xs_TLXbar_5_core 的端口是 tlxbar5_pkg 里按通道打包的结构体数组；本脚本从 golden 端口表生成
rtl/uncore/TLXbar_5.sv 里 `// BEGIN GENERATED(tlxbar5_wrapper)` … `// END GENERATED` 之间的 wrapper
（手写区不碰）。拆拼规则：
  * 结构体字段表（名字、位宽）写在下面的 FIELDS 里，必须与 tlxbar5_pkg 一致（生成时按 golden 端口逐名核对：
    主口缺的字段填 0，从口不缺字段；位宽不同只允许 source / sink 这两个加前缀的字段）；
  * 主口 source 零扩展到 7 位后 OR 上前缀（前缀从 golden 的 `wire [6:0] in_k_a_bits_source = {3'h5, ...}` 现读）；
    从口 D/B 的 source 回主口时截到主口位宽；
  * 从口 sink 零扩展到 10 位后 OR 上前缀 (3-k)<<8（同样从 golden 的 `out_k_d_bits_sink = {2'h3, ...}` 现读）；
    主口 E 的 sink 送从口时截到 8 位；
  * 主口 D 没有的输出字段（in1/in2 的 echo_isKeyword）丢弃；
  * 反向全覆盖：golden 每个端口都必须落进已知形状。

用法：python3 scripts/gen_tlxbar5_wrapper.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
MOD = 'TLXbar_5'
OUT = os.path.join(REPO, 'rtl', 'uncore', MOD + '.sv')
NUM_IN, NUM_OUT = 3, 4
BEGIN, END = '// BEGIN GENERATED(tlxbar5_wrapper)', '// END GENERATED'

# 与 tlxbar5_pkg 的结构体逐字段一致（名字 -> 位宽）
FIELDS = {
    'a': [('opcode', 4), ('param', 3), ('size', 3), ('source', 7), ('address', 48), ('user_reqSource', 5),
          ('user_alias', 2), ('user_vaddr', 44), ('user_needHint', 1), ('echo_isKeyword', 1), ('mask', 32),
          ('data', 256), ('corrupt', 1)],
    'b': [('opcode', 3), ('param', 2), ('size', 3), ('source', 7), ('address', 48), ('mask', 32), ('data', 256),
          ('corrupt', 1)],
    'c': [('opcode', 3), ('param', 3), ('size', 3), ('source', 7), ('address', 48), ('user_reqSource', 5),
          ('user_alias', 2), ('user_vaddr', 44), ('user_needHint', 1), ('echo_isKeyword', 1), ('data', 256),
          ('corrupt', 1)],
    'd': [('opcode', 4), ('param', 2), ('size', 3), ('source', 7), ('sink', 10), ('denied', 1),
          ('echo_isKeyword', 1), ('data', 256), ('corrupt', 1)],
    'e': [('sink', 10)],
}
# 通道方向：主口发（in -> out）还是从口发
MASTER_SENDS = {'a': True, 'b': False, 'c': True, 'd': False, 'e': True}
SOURCE_BASE_NAME = {0: 'SOURCE_BASE_DCACHE', 1: 'SOURCE_BASE_ICACHE', 2: 'SOURCE_BASE_PTW'}


def ports():
    t = open(os.path.join(G, MOD + '.sv')).read()
    i = t.index('\nmodule %s(' % MOD) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            raise SystemExit('端口行解析失败: %r' % line)
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t


def emit():
    P, gtxt = ports()
    names = {n: (d, w) for d, w, n in P}
    used = set()

    def take(n):
        assert n in names, n
        used.add(n)
        return names[n][1]

    # ---- 从 golden 现读前缀常量 ----
    src_base = {}
    for k in range(NUM_IN):
        m = re.search(r"wire \[6:0\]\s+in_%d_a_bits_source = \{(\d+)'h([0-9a-fA-F]+), auto_in_%d_a_bits_source\};" % (k, k), gtxt)
        assert m, 'golden 里找不到 in_%d 的 source 前缀' % k
        src_base[k] = int(m.group(2), 16) << (7 - int(m.group(1)))
    assert src_base == {0: 0x00, 1: 0x50, 2: 0x40}, src_base          # 与 tlxbar5_pkg 的 SOURCE_BASE_* 一致
    for o in range(NUM_OUT):
        m = re.search(r"wire \[9:0\]\s+out_%d_d_bits_sink = \{2'h(\d), auto_out_%d_d_bits_sink\};" % (o, o), gtxt)
        assert m and int(m.group(1)) == NUM_OUT - 1 - o, 'golden 里 out_%d 的 sink 前缀不是 %d' % (o, NUM_OUT - 1 - o)

    L = []
    W = L.append
    W('module %s' % MOD)
    W('  import tlxbar5_pkg::*;')
    W('(')
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    W('  logic  [NUM_IN-1:0]  in_a_valid, in_a_ready, in_d_ready, in_d_valid;')
    W('  tl_a_t in_a_bits [NUM_IN];')
    W('  tl_d_t in_d_bits [NUM_IN];')
    W('  logic  in0_b_valid, in0_c_ready, in0_e_ready;')
    W('  tl_b_t in0_b_bits;')
    W('  tl_c_t in0_c_bits;')
    W('  tl_e_t in0_e_bits;')
    W('  logic  [NUM_OUT-1:0] out_a_ready, out_a_valid, out_b_ready, out_b_valid, out_c_ready, out_c_valid,')
    W('                       out_d_ready, out_d_valid, out_e_ready, out_e_valid;')
    W('  tl_a_t out_a_bits [NUM_OUT];')
    W('  tl_b_t out_b_bits [NUM_OUT];')
    W('  tl_c_t out_c_bits [NUM_OUT];')
    W('  tl_d_t out_d_bits [NUM_OUT];')
    W('  tl_e_t out_e_bits [NUM_OUT];')

    def pack(ch, pfx, vec, side, idx):
        """把 pfx_bits_* 端口打进结构体 vec；side='in' 主口 / 'out' 从口。"""
        items = []
        for f, w in FIELDS[ch]:
            pn = '%s_bits_%s' % (pfx, f)
            if pn not in names:
                assert side == 'in', '%s 从口缺字段 %s' % (pfx, f)
                items.append('%s: \'0 /* 本口无 */' % f)
                continue
            pw = take(pn)
            if f == 'source' and side == 'in':
                assert pw <= w
                items.append('%s: %s | SOURCE_W\'(%s)' % (f, SOURCE_BASE_NAME[idx], pn))
            elif f == 'sink' and side == 'out':
                assert pw <= w
                items.append('%s: sink_base(%d) | SINK_W\'(%s)' % (f, idx, pn))
            else:
                assert pw == w, (pn, pw, w)
                items.append('%s: %s' % (f, pn))
        W('  assign %s = \'{%s};' % (vec, (',\n' + ' ' * (12 + len(vec))).join(items)))

    def unpack(ch, pfx, vec, side):
        for f, w in FIELDS[ch]:
            pn = '%s_bits_%s' % (pfx, f)
            if pn not in names:
                assert side == 'in', '%s 从口缺字段 %s' % (pfx, f)
                W('  // %s.%s：本口无此输出，丢弃' % (vec, f))
                continue
            pw = take(pn)
            if pw < w:
                assert f in ('source', 'sink'), (pn, pw, w)
                W('  assign %s = %s.%s[%d:0];' % (pn, vec, f, pw - 1))
            else:
                assert pw == w, (pn, pw, w)
                W('  assign %s = %s.%s;' % (pn, vec, f))

    # ---- 主口 ----
    for k in range(NUM_IN):
        W('')
        W('  // ===== 主口 in%d%s =====' % (k, {0: '（DCache，TL-C 五通道）', 1: '（ICache）', 2: '（PTW）'}[k]))
        for ch in 'abcde':
            pfx = 'auto_in_%d_%s' % (k, ch)
            if pfx + '_valid' not in names:
                continue
            take(pfx + '_valid'); take(pfx + '_ready')
            if ch in 'ad':
                vec_v = 'in_%s_valid[%d]' % (ch, k)
                vec_r = 'in_%s_ready[%d]' % (ch, k)
                vec_b = 'in_%s_bits[%d]' % (ch, k)
            else:
                assert k == 0, (k, ch)
                vec_v, vec_r, vec_b = 'in0_%s_valid' % ch, 'in0_%s_ready' % ch, 'in0_%s_bits' % ch
            if MASTER_SENDS[ch]:
                W('  assign %s = %s;' % (vec_v, pfx + '_valid'))
                W('  assign %s = %s;' % (pfx + '_ready', vec_r))
                pack(ch, pfx, vec_b, 'in', k)
            else:
                W('  assign %s = %s;' % (vec_r, pfx + '_ready'))
                W('  assign %s = %s;' % (pfx + '_valid', vec_v))
                unpack(ch, pfx, vec_b, 'in')
    # ---- 从口 ----
    for o in range(NUM_OUT):
        W('')
        W('  // ===== 从口 out%d（L2 bank %d：address[7:6] == %d，sink 前缀 %d）=====' % (o, o, o, NUM_OUT - 1 - o))
        for ch in 'abcde':
            pfx = 'auto_out_%d_%s' % (o, ch)
            take(pfx + '_valid'); take(pfx + '_ready')
            vec_v, vec_r, vec_b = 'out_%s_valid[%d]' % (ch, o), 'out_%s_ready[%d]' % (ch, o), 'out_%s_bits[%d]' % (ch, o)
            if MASTER_SENDS[ch]:
                W('  assign %s = %s;' % (vec_r, pfx + '_ready'))
                W('  assign %s = %s;' % (pfx + '_valid', vec_v))
                unpack(ch, pfx, vec_b, 'out')
            else:
                W('  assign %s = %s;' % (vec_v, pfx + '_valid'))
                W('  assign %s = %s;' % (pfx + '_ready', vec_r))
                pack(ch, pfx, vec_b, 'out', o)
    take('clock'); take('reset')
    assert used == set(names), sorted(set(names) - used)[:5]

    W('')
    W('  xs_TLXbar_5_core u_core (')
    W('    .clock(clock), .reset(reset),')
    W('    .in_a_valid(in_a_valid), .in_a_ready(in_a_ready), .in_a_bits(in_a_bits),')
    W('    .in_d_ready(in_d_ready), .in_d_valid(in_d_valid), .in_d_bits(in_d_bits),')
    W('    .in0_b_ready(auto_in_0_b_ready), .in0_b_valid(in0_b_valid), .in0_b_bits(in0_b_bits),')
    W('    .in0_c_valid(auto_in_0_c_valid), .in0_c_ready(in0_c_ready), .in0_c_bits(in0_c_bits),')
    W('    .in0_e_valid(auto_in_0_e_valid), .in0_e_ready(in0_e_ready), .in0_e_bits(in0_e_bits),')
    W('    .out_a_ready(out_a_ready), .out_a_valid(out_a_valid), .out_a_bits(out_a_bits),')
    W('    .out_b_ready(out_b_ready), .out_b_valid(out_b_valid), .out_b_bits(out_b_bits),')
    W('    .out_c_ready(out_c_ready), .out_c_valid(out_c_valid), .out_c_bits(out_c_bits),')
    W('    .out_d_ready(out_d_ready), .out_d_valid(out_d_valid), .out_d_bits(out_d_bits),')
    W('    .out_e_ready(out_e_ready), .out_e_valid(out_e_valid), .out_e_bits(out_e_bits)')
    W('  );')
    W('')
    W('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    cur = open(OUT).read()
    i = cur.index(BEGIN) + len(BEGIN) + 1
    j = cur.index(END)
    new = cur[:i] + emit() + cur[j:]
    if a.check:
        if cur != new:
            print('DRIFT: %s' % OUT)
            return 1
        print('OK: %s' % OUT)
        return 0
    if cur != new:
        open(OUT, 'w').write(new)
        print('wrote %s' % OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
