#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_variants.py —— 生成 SnapshotGenerator 家族 10 个变体的薄 wrapper。

★为什么机械生成★ 这 10 个 wrapper 里没有一行是设计决策：控制核已经证明 11 份
逐字节相同（见 rtl/backend/SnapshotGenerator.sv 文件头的家族表），wrapper 要做的
只是「把 golden 的 payload 端口按声明顺序拼成一根 DATA_W 位总线、再原样拆回去」。
_6 一个变体就有 47 个 payload 字段 × 5 处（enq 打包 + 4 个槽拆包）= 235 行机械文本，
手抄漏一根线 UT 未必抓得住（漏的那根可能恰好总是 0）。所以从 **G1 golden 的端口表**
生成，并在生成时做三项机械核对（任何一项不符就拒绝生成，不是警告）：

  1. 深度恒为 4：io_snapshots_0..3 必须齐全，没有第 5 个槽；
  2. payload 同构：io_enqData 的字段后缀集合（含位宽）必须与每个
     io_snapshots_<i> 的后缀集合逐项相同 —— 这是"打包/拆包对得上"的前提；
  3. 控制端口齐全：clock/reset/io_enq/io_deq/io_redirect/io_flushVec_0..3。

用法: python3 gen_variants.py   （Makefile 不自动调用；改了本文件要手动重跑并提交）
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = REPO / 'rtl' / 'backend'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')
SNPT_NUM = 4

# 每个变体的一句话说明（payload 是什么）。**只是注释**，不参与任何生成判据；
# 生成出来的位宽/字段全部现场从 golden 端口表实测，与本表无关。
BLURB = {
    'SnapshotGenerator_1':  'RenameBuffer 指针的窄变体：{flag, value[5:0]}',
    'SnapshotGenerator_2':  'VType：{illegal, vma, vta, vsew[1:0], vlmul[2:0]}',
    'SnapshotGenerator_3':  '长度为 1 的向量，元素是 {flag, value[7:0]}',
    'SnapshotGenerator_4':  '32 个 8 位元素的向量',
    'SnapshotGenerator_5':  '34 个 8 位元素的向量',
    'SnapshotGenerator_6':  '47 个 8 位元素的向量',
    'SnapshotGenerator_7':  '长度为 1 的向量，元素是 8 位无符号数',
    'SnapshotGenerator_11': 'RenameBuffer 指针的窄变体：{flag, value[6:0]}',
    'SnapshotGenerator_12': 'RenameBuffer 指针的窄变体：{flag, value[4:0]}',
    'SnapshotGenerator_14': 'Vec(6) of {flag, value[7:0]} 与 Vec(6) of Bool 两段拼接；'
                            '★本变体的 golden 还留着 enqPtr/deqPtr/valids 输出★',
}

CTRL_IN = ['clock', 'reset', 'io_enq', 'io_deq', 'io_redirect',
           'io_flushVec_0', 'io_flushVec_1', 'io_flushVec_2', 'io_flushVec_3']
PTR_OUT = ['io_enqPtr_flag', 'io_enqPtr_value', 'io_deqPtr_flag', 'io_deqPtr_value',
           'io_valids_0', 'io_valids_1', 'io_valids_2', 'io_valids_3']


def width(rng):
    """'[7:0]' -> 8；'' -> 1。只支持 [hi:0] 形式（golden 里没有别的）。"""
    if not rng:
        return 1
    m = re.fullmatch(r'\[(\d+):0\]', rng)
    if not m:
        raise SystemExit('不认识的位宽写法: %r' % rng)
    return int(m.group(1)) + 1


def parse_ports(top):
    txt = (GOLDEN / (top + '.sv')).read_text().split('\n')
    start = next(i for i, l in enumerate(txt) if l.startswith('module %s(' % top))
    ports, i = [], start + 1
    while txt[i].rstrip() != ');':
        m = PORT_RE.match(txt[i])
        if not m:
            raise SystemExit('%s 端口行解析失败: %r' % (top, txt[i]))
        ports.append((m.group(1), m.group(2) or '', m.group(3)))
        i += 1
    return ports


def analyse(top, ports):
    """从端口表实测 payload 字段表、位宽、以及有没有 ptr/valids 输出。"""
    names = [n for _, _, n in ports]

    # 闸 3：控制端口齐全
    missing = [c for c in CTRL_IN if c not in names]
    if missing:
        raise SystemExit('%s 缺控制端口 %s —— 与家族控制核不同构，拒绝生成' % (top, missing))

    # payload 字段：io_enqData 之后的后缀（'' 表示 io_enqData 本身就是叶子）
    enq = [(n[len('io_enqData'):], r) for d, r, n in ports
           if d == 'input' and n.startswith('io_enqData')]
    if not enq:
        raise SystemExit('%s 没有 io_enqData* 端口' % top)

    # 闸 1+2：4 个槽齐全且字段表逐项同构
    for i in range(SNPT_NUM):
        pre = 'io_snapshots_%d' % i
        snp = [(n[len(pre):], r) for d, r, n in ports
               if d == 'output' and n.startswith(pre)]
        if snp != enq:
            raise SystemExit('%s 槽 %d 的字段表与 io_enqData 不同构:\n  enq=%s\n  snp=%s'
                             % (top, i, enq, snp))
    if any(n.startswith('io_snapshots_%d' % SNPT_NUM) for n in names):
        raise SystemExit('%s 有第 %d 个槽 —— 深度不是 4，本核不适用' % (top, SNPT_NUM + 1))

    has_ptr = all(p in names for p in PTR_OUT)
    if not has_ptr and any(p in names for p in PTR_OUT):
        raise SystemExit('%s 的 ptr/valids 输出只有一部分 —— 家族里没见过，拒绝生成' % top)

    dw = sum(width(r) for _, r in enq)
    return enq, dw, has_ptr


def gen(top):
    ports = parse_ports(top)
    fields, dw, has_ptr = analyse(top, ports)

    # 打包次序：**按 golden 端口声明顺序，先声明的放高位**。
    # 与 base 的 rab_ptr_t={flag,value} 一致（flag 先声明、在高位）。
    # 核不看 payload 内容，次序只要打包/拆包一致即可；这里取一个可读的约定。
    bits, lo = [], dw
    for suf, rng in fields:
        w = width(rng)
        hi = lo - 1
        lo = lo - w
        bits.append((suf, w, hi, lo))
    assert lo == 0

    L = []
    L.append('// =============================================================================')
    L.append('// %s —— SnapshotGenerator 家族变体（%s）' % (top, BLURB[top]))
    L.append('// 本文件只做参数化与端口展平；核体见 rtl/backend/SnapshotGenerator.sv')
    L.append('//   （xs_SnapshotGenerator_core，含家族 11 个变体的实测差异表与机制说明）。')
    L.append('// golden 对照：G1-canonical/golden-rtl/%s.sv（%d 端口，实测控制逻辑与' % (top, len(ports)))
    L.append('//   base 变体逐字节相同，只有 payload 位宽%s不同）。' %
             ('与 ptr/valids 输出' if has_ptr else ''))
    L.append('// payload 实测 %d 位 = %d 个字段：%s' %
             (dw, len(fields), ', '.join('%s%s' % (s or '(叶子)', r) for s, r in fields[:6])
              + (' ...' if len(fields) > 6 else '')))
    L.append('// ★本文件由 verif/ut/SnapshotGenerator/gen_variants.py 生成，改请改生成器★')
    L.append('// =============================================================================')
    L.append('module %s(' % top)
    decl = []
    for d, r, n in ports:
        decl.append('  %-6s %-8s %s' % (d, r, n))
    L.append(',\n'.join(decl))
    L.append(');')
    L.append('')
    L.append('  localparam int DW = %d;   // payload 位宽（实测自 golden 端口表）' % dw)
    L.append('')
    L.append('  logic [DW-1:0] core_enq_data;')
    L.append('  logic [DW-1:0] core_snapshots [4];')
    L.append('')
    L.append('  // 打包：golden 端口声明顺序，先声明的在高位。')
    L.append('  assign core_enq_data = {')
    L.append(',\n'.join('    io_enqData%s' % suf for suf, _, _, _ in bits))
    L.append('  };')
    L.append('')
    L.append('  xs_SnapshotGenerator_core #(.DATA_W(DW)) u_core (')
    L.append('    .clock     (clock),')
    L.append('    .reset     (reset),')
    L.append('    .enq       (io_enq),')
    L.append('    .enq_data  (core_enq_data),')
    L.append('    .deq       (io_deq),')
    L.append('    .redirect  (io_redirect),')
    L.append('    .flush_vec ({io_flushVec_3, io_flushVec_2, io_flushVec_1, io_flushVec_0}),')
    L.append('    .snapshots (core_snapshots),')
    if has_ptr:
        L.append('    // ★只有本变体的 golden 留着这三组端口★（别的变体被 firtool 消掉了）')
        L.append('    .enq_ptr   ({io_enqPtr_flag, io_enqPtr_value}),')
        L.append('    .deq_ptr   ({io_deqPtr_flag, io_deqPtr_value}),')
        L.append('    .valids    ({io_valids_3, io_valids_2, io_valids_1, io_valids_0})')
    else:
        L.append('    .enq_ptr   (),   // 本变体 golden 端口表里没有，悬空')
        L.append('    .deq_ptr   (),')
        L.append('    .valids    ()')
    L.append('  );')
    L.append('')
    L.append('  // 拆包：与上面的打包次序互逆。')
    for i in range(4):
        for suf, w, hi, lo in bits:
            sl = '[%d]' % hi if w == 1 else '[%d:%d]' % (hi, lo)
            L.append('  assign io_snapshots_%d%s = core_snapshots[%d]%s;' % (i, suf, i, sl))
    L.append('')
    L.append('endmodule')
    return '\n'.join(L) + '\n', dw, has_ptr, len(ports)


def main():
    rows = []
    for top in BLURB:
        txt, dw, has_ptr, np_ = gen(top)
        (OUT_DIR / (top + '.sv')).write_text(txt)
        rows.append((top, np_, dw, has_ptr))
    print('%-24s %6s %8s %s' % ('variant', 'ports', 'DATA_W', 'ptr/valids out'))
    for t, np_, dw, hp in rows:
        print('%-24s %6d %8d %s' % (t, np_, dw, 'yes' if hp else 'no'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
