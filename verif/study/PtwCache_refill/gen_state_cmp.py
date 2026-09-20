#!/usr/bin/env python3
"""gen_state_cmp.py —— 生成 tb.sv 里 `compare_state()` 这一段（纯机械的层次引用对照表）。

为什么要有这个生成器：PtwCache 的核内状态被 firtool 展平成了几百个标量寄存器
（l3_0_tag / l1asids_0_0 / state_vec_1_63 …），而重写核里它们是 struct 数组。
这张两侧路径对照表一根都不能错，但里面没有任何设计判断，手敲只会引入抄写错误。

★本文件不做任何等价性判断★：它抄的是两侧的层次路径，抄对了不等于状态对了。

用法:
    python3 gen_state_cmp.py            # 原地改写 tb.sv 的 GENERATED(state_cmp) 段
    python3 gen_state_cmp.py --check    # 只校验该段与重算结果逐字节一致
"""
import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
TB = HERE / 'tb.sv'
BEGIN = '  // BEGIN GENERATED(state_cmp)'
END = '  // END GENERATED(state_cmp)'

G = 'dut_g.'
I = 'dut_i.u_core.'

L3_N = L2_N = SP_N = 16
L1_SETS, L1_WAYS = 4, 2
L0_SETS, L0_WAYS = 64, 4


def emit():
    o = [BEGIN,
         '  // 由 gen_state_cmp.py 生成（golden 展平标量 <-> 重写核 struct 数组的路径对照）。',
         '  // 手改这段会被下次生成覆盖；要改请改生成器。',
         '  task automatic compare_state();']

    def c(name, g, i):
        o.append('    chk("%s", %s%s, %s%s);' % (name, G, g, I, i))

    # 位向量：l0v/l0g 是 256 位，chk 只收 64 位，切成 4 段比。
    for nm in ('l3v', 'l2v', 'l1v', 'spv', 'l3g', 'l2g', 'l1g', 'spg'):
        c(nm, nm, nm)
    for nm in ('l0v', 'l0g'):
        for k in range(4):
            c('%s[%d]' % (nm, k), '%s[%d:%d]' % (nm, 64 * k + 63, 64 * k),
              '%s[%d:%d]' % (nm, 64 * k + 63, 64 * k))

    # 替换状态
    c('plru_l3', 'state_reg', 'plru_l3')
    c('plru_l2', 'state_reg_1', 'plru_l2')
    c('plru_sp', 'state_reg_4', 'plru_sp')
    for s in range(L1_SETS):
        c('plru_l1[%d]' % s, 'state_vec_%d' % s, 'plru_l1[%d]' % s)
    for s in range(L0_SETS):
        c('plru_l0[%d]' % s, 'state_vec_1_%d' % s, 'plru_l0[%d]' % s)

    # l3 / l2 / sp 表项与 h
    for i in range(L3_N):
        for f in ('tag', 'asid', 'vmid', 'ppn', 'prefetch'):
            c('l3[%d].%s' % (i, f), 'l3_%d_%s' % (i, f), 'l3_entry[%d].%s' % (i, f))
        c('l3h[%d]' % i, 'l3h_%d' % i, 'l3h[%d]' % i)
    for i in range(L2_N):
        for f in ('tag', 'asid', 'vmid', 'pbmt', 'ppn', 'prefetch'):
            c('l2[%d].%s' % (i, f), 'l2_%d_%s' % (i, f), 'l2_entry[%d].%s' % (i, f))
        c('l2h[%d]' % i, 'l2h_%d' % i, 'l2h[%d]' % i)
    for i in range(SP_N):
        for f in ('tag', 'asid', 'vmid', 'n', 'pbmt', 'ppn', 'level', 'prefetch', 'v'):
            c('sp[%d].%s' % (i, f), 'sp_%d_%s' % (i, f), 'sp_entry[%d].%s' % (i, f))
        for p in ('d', 'a', 'g', 'u', 'x', 'w', 'r'):
            c('sp[%d].perm.%s' % (i, p), 'sp_%d_perm_%s' % (i, p),
              'sp_entry[%d].perm.%s' % (i, p))
        c('sph[%d]' % i, 'sph_%d' % i, 'sph[%d]' % i)

    # l1 / l0 的影子元数据
    for s in range(L1_SETS):
        for w in range(L1_WAYS):
            c('l1h[%d][%d]' % (s, w), 'l1h_%d_%d' % (s, w), 'l1h[%d][%d]' % (s, w))
            c('l1asids[%d][%d]' % (s, w), 'l1asids_%d_%d' % (s, w), 'l1asids[%d][%d]' % (s, w))
            c('l1vmids[%d][%d]' % (s, w), 'l1vmids_%d_%d' % (s, w), 'l1vmids[%d][%d]' % (s, w))
    for s in range(L0_SETS):
        for w in range(L0_WAYS):
            c('l0h[%d][%d]' % (s, w), 'l0h_%d_%d' % (s, w), 'l0h[%d][%d]' % (s, w))
            c('l0asids[%d][%d]' % (s, w), 'l0asids_%d_%d' % (s, w), 'l0asids[%d][%d]' % (s, w))
            c('l0vmids[%d][%d]' % (s, w), 'l0vmids_%d_%d' % (s, w), 'l0vmids[%d][%d]' % (s, w))
            c('l0vpns[%d][%d]' % (s, w), 'l0vpns_%d_%d' % (s, w), 'l0vpns[%d][%d]' % (s, w))

    o.append('  endtask')
    o.append(END)
    return '\n'.join(o) + '\n'


def splice(text):
    b = text.index(BEGIN)
    e = text.index(END) + len(END) + 1
    return text[:b] + emit() + text[e:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    cur = TB.read_text()
    if BEGIN not in cur or END not in cur:
        print('gen_state_cmp: tb.sv 里找不到 GENERATED(state_cmp) 标记（fail-closed）')
        return 1
    new = splice(cur)
    if a.check:
        if new != cur:
            print('gen_state_cmp --check: DRIFT —— tb.sv 与重算结果不一致')
            return 1
        print('gen_state_cmp --check: 逐字节一致')
        return 0
    TB.write_text(new)
    print('gen_state_cmp: 已写回 tb.sv（%d 行对照）' % emit().count('chk('))
    return 0


if __name__ == '__main__':
    sys.exit(main())
