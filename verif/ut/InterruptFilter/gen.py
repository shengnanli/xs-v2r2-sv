#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— 生成 rtl/backend/InterruptFilter.sv 里的机械派生区（golden 同名 wrapper）。

InterruptFilter 的 311 个端口里有 296 个是 io_in_*，绝大多数是 CSR 位域被 firtool
一位一位拆出来的标量端口（mip/mie/sip/sie/hip/hie/vsip/vsie/mideleg/hideleg 十个
64 位中断向量，就占了 250 个端口）。这一层"字段名 -> 位号"的还原完全机械：
RISC-V 规范里中断向量的**位号就是中断号**，而端口名里正好写着中断号
（SSIP=1、STIP=5、SEIP=9、LCOFIP=13、LC<n>IP=n、LPRASEIP=35、HPRASEIP=43 …）。

所以这里从 G1 golden 的端口表现读现生成，不手抄：
  · 端口表逐字来自 golden（顺序/方向/位宽都一样，端口契约闸要求）；
  · 每个 io_in_<bundle>_<field> 按上面的规则还原到 <bundle>_bits[<中断号>]；
  · 端口里没有的位补 0，**唯一的例外是 mideleg**（见 HARDWIRED_MIDELEG）。

手写区（package + xs_InterruptFilter_core）在标记之外，本脚本不碰。

用法: python3 gen.py [--check]
      --check 只比对不写盘，产物与现库不一致时 rc=1。
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/InterruptFilter.sv')
TARGET = REPO / 'rtl' / 'backend' / 'InterruptFilter.sv'
TB = HERE / 'tb.sv'

BEGIN = '// BEGIN GENERATED(wrapper)'
END = '// END GENERATED'

# 有名字的中断号（RISC-V 特权规范 + 香山的平台保留中断）
NAMED = {
    'SSI': 1, 'VSSI': 2, 'MSI': 3,
    'STI': 5, 'VSTI': 6, 'MTI': 7,
    'SEI': 9, 'VSEI': 10, 'MEI': 11, 'SGEI': 12,
    'LCOFI': 13, 'LPRASEI': 35, 'HPRASEI': 43,
}

# 收成 64 位向量的十个中断位域 bundle（位号 = 中断号）
VECTOR_BUNDLES = ['mip', 'mie', 'mideleg', 'sip', 'sie',
                  'hip', 'hie', 'hideleg', 'vsip', 'vsie']

# ★mideleg 是唯一一个"端口没给全、缺的位不是 0"的 bundle★
# golden 把 ~mideleg 的常量部分折进了掩码里，从那里读回来：
#   VSSI/VSTI/VSEI/SGEI 恒为 1（VS 级中断永远委托给 HS），
#   MSI/MTI/MEI 恒为 0（M 级中断永远不委托），
#   14..63 这些局部中断本模块看不见（mip 根本没有这些端口，与出来恒 0），端口没给就按 0。
HARDWIRED_MIDELEG = {2: 1, 6: 1, 10: 1, 12: 1, 3: 0, 7: 0, 11: 0}

# hviprios = Cat(hviprio2, hviprio1)：字段 -> 在 128 位里的位置
HVIPRIO_FIELDS = {
    'hviprio1_PrioSSI': (15, 8),
    'hviprio1_PrioSTI': (31, 24),
    'hviprio1_PrioCOI': (47, 40),
    'hviprio1_Prio14': (55, 48),
    'hviprio1_Prio15': (63, 56),
    'hviprio2_ALL': (127, 64),
}

# io_in_* 标量端口直接连到核的同名输入
DIRECT_IN = {
    'privState_PRVM': 'privState_PRVM', 'privState_V': 'privState_V',
    'mstatusMIE': 'mstatusMIE', 'sstatusSIE': 'sstatusSIE', 'vsstatusSIE': 'vsstatusSIE',
    'hvictl_VTI': 'hvictl_VTI', 'hvictl_IID': 'hvictl_IID', 'hvictl_DPR': 'hvictl_DPR',
    'hvictl_IPRIOM': 'hvictl_IPRIOM', 'hvictl_IPRIO': 'hvictl_IPRIO',
    'hstatus_VGEIN': 'hstatus_VGEIN',
    'mtopei_IPRIO': 'mtopei_IPRIO', 'stopei_IPRIO': 'stopei_IPRIO',
    'vstopei_IID': 'vstopei_IID', 'vstopei_IPRIO': 'vstopei_IPRIO',
    'debugIntr': 'debugIntr', 'debugMode': 'debugMode',
    'dcsr_STEP': 'dcsr_STEP', 'dcsr_STEPIE': 'dcsr_STEPIE',
    'miprios': 'miprios', 'hsiprios': 'hsiprios',
    'nmi': 'nmi', 'nmiVec': 'nmiVec', 'mnstatusNMIE': 'mnstatusNMIE',
    'platform_meip': 'platform_meip', 'platform_seip': 'platform_seip',
    'fromAIA_seip': 'fromAIA_seip',
    'mvienSEIE': 'mvienSEIE', 'mvipSEIP': 'mvipSEIP',
}

# golden 输出端口 -> 核的输出端口
OUT_MAP = {
    'debug': 'out_debug', 'nmi': 'out_nmi',
    'interruptVec_valid': 'out_interruptVec_valid',
    'interruptVec_bits': 'out_interruptVec_bits',
    'mtopi_IID': 'out_mtopi_IID', 'mtopi_IPRIO': 'out_mtopi_IPRIO',
    'stopi_IID': 'out_stopi_IID', 'stopi_IPRIO': 'out_stopi_IPRIO',
    'vstopi_IID': 'out_vstopi_IID', 'vstopi_IPRIO': 'out_vstopi_IPRIO',
    'virtualInterruptIsHvictlInject': 'out_virtualInterruptIsHvictlInject',
    'irToHS': 'out_irToHS', 'irToVS': 'out_irToVS',
}


def irq_of(field):
    """字段名 -> 中断号。SSIP/SSIE/SSI 都是 1；LC<n>IP/IE/I 是 n。"""
    base = field
    if field.endswith(('P', 'E')) and field[:-1].endswith('I'):
        base = field[:-1]
    m = re.fullmatch(r'LC(\d+)I', base)
    if m:
        return int(m.group(1))
    if base in NAMED:
        return NAMED[base]
    raise SystemExit('gen.py: 无法从字段名还原中断号: %r' % field)


def golden_ports():
    src = GOLDEN.read_text()
    m = re.search(r'^module InterruptFilter\(\s*$', src, re.M)
    body = src[m.end():src.index('\n);', m.end())]
    out = []
    for ln in body.split('\n'):
        mm = re.match(r'^\s*(input|output)\s+(\[\d+:\d+\]\s+)?([A-Za-z_]\w*),?\s*$', ln)
        if mm:
            out.append((mm.group(1), (mm.group(2) or '').strip(), mm.group(3)))
    return out


def build():
    ports = golden_ports()
    assert len(ports) == 311, 'golden 端口数变了: %d' % len(ports)

    L = []
    L.append(BEGIN)
    L.append('// 本段由 verif/ut/InterruptFilter/gen.py 从 G1 golden 端口表现读现生成，勿手改。')
    L.append('//')
    L.append('// golden 同名 wrapper：端口表与 golden 逐字一致（名字/方向/位宽/顺序），')
    L.append('// 体内只做一件事 —— 把按 CSR 字段名拆开的标量端口重新收成"位号 = 中断号"的')
    L.append('// 64 位中断向量，再交给可读核。')
    L.append('module InterruptFilter(')
    for i, (d, w, n) in enumerate(ports):
        comma = ',' if i + 1 < len(ports) else ''
        pad = (w + ' ') if w else ''
        L.append('  %-6s %-9s%s%s' % (d, pad, n, comma))
    L.append(');')
    L.append('')
    L.append('  // ---- 十个中断位域 bundle 还原成 64 位向量（位号 = 中断号）----------------')
    for b in VECTOR_BUNDLES:
        L.append('  logic [63:0] %s_bits;' % b)
    L.append('  // ---- AIA 的 hviprio1/hviprio2 拼成 128 位优先级数组 ---------------------')
    L.append('  logic [127:0] hviprios_bits;')
    L.append('')

    by_bundle = {b: {} for b in VECTOR_BUNDLES}
    for d, w, n in ports:
        if d != 'input' or not n.startswith('io_in_'):
            continue
        rest = n[len('io_in_'):]
        for b in VECTOR_BUNDLES:
            if rest.startswith(b + '_'):
                by_bundle[b][irq_of(rest[len(b) + 1:])] = n
                break

    for b in VECTOR_BUNDLES:
        hw = HARDWIRED_MIDELEG if b == 'mideleg' else {}
        L.append('  always_comb begin')
        L.append('    %s_bits = 64\'h0;' % b)
        if b == 'mideleg':
            L.append('    // 端口没给出的位：VS 级三个 + SGEI 恒为 1（永远委托），')
            L.append('    // M 级三个恒为 0（永远不委托）—— 见 gen.py 的 HARDWIRED_MIDELEG。')
            for bit in sorted(hw):
                L.append('    %s_bits[%d] = 1\'b%d;' % (b, bit, hw[bit]))
        for bit in sorted(by_bundle[b]):
            L.append('    %s_bits[%-2d] = %s;' % (b, bit, by_bundle[b][bit]))
        L.append('  end')
        L.append('')

    L.append('  always_comb begin')
    L.append('    hviprios_bits = 128\'h0;')
    for f, (hi, lo) in sorted(HVIPRIO_FIELDS.items(), key=lambda kv: kv[1][1]):
        L.append('    hviprios_bits[%d:%d] = io_in_%s;' % (hi, lo, f))
    L.append('  end')
    L.append('')

    L.append('  xs_InterruptFilter_core u_core (')
    conn = [('clock', 'clock'), ('reset', 'reset')]
    for b in VECTOR_BUNDLES:
        conn.append((b, b + '_bits'))
    conn.append(('hviprios', 'hviprios_bits'))
    for d, w, n in ports:
        if d == 'input' and n.startswith('io_in_'):
            rest = n[len('io_in_'):]
            if rest in DIRECT_IN:
                conn.append((DIRECT_IN[rest], n))
    for d, w, n in ports:
        if d == 'output':
            conn.append((OUT_MAP[n[len('io_out_'):]], n))
    for i, (p, s) in enumerate(conn):
        comma = ',' if i + 1 < len(conn) else ''
        L.append('    .%-34s (%s)%s' % (p, s, comma))
    L.append('  );')
    L.append('')
    L.append('endmodule')
    L.append(END)
    return '\n'.join(L) + '\n'


def build_tb():
    """tb 的机械区：311 个端口的信号声明 + 双例化 + 通用随机激励 + 逐输出比对。"""
    ports = golden_ports()
    ins = [(w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ports if d == 'output']

    L = []
    L.append(BEGIN.replace('(wrapper)', '(tb)'))
    L.append('  // 本段由 gen.py 从 G1 golden 端口表现读现生成，勿手改。')
    L.append('  // 311 个端口全按 golden 原名声明；两个 DUT 用 .* 连输入，只把 13 个输出')
    L.append('  // 显式引到 g_/i_ 两组线上。')
    L.append('')
    for w, n in ins:
        L.append('  logic %-9s%s;' % (w, n))
    L.append('')
    for w, n in outs:
        L.append('  logic %-9sg_%s, i_%s;' % (w, n, n))
    L.append('')
    L.append('  InterruptFilter u_g (.*,')
    for k, (w, n) in enumerate(outs):
        L.append('    .%s(g_%s)%s' % (n, n, ',' if k + 1 < len(outs) else ');'))
    L.append('')
    L.append('  InterruptFilter_xs u_i (.*,')
    for k, (w, n) in enumerate(outs):
        L.append('    .%s(i_%s)%s' % (n, n, ',' if k + 1 < len(outs) else ');'))
    L.append('')
    L.append('  // 通用随机激励：1 位端口按 p_one/100 的概率置 1（控制中断密度），')
    L.append('  // 多位端口全随机。感兴趣的字段由手写区的 drive() 事后改写。')
    L.append('  task automatic drive_all(input int unsigned p_one);')
    L.append('    begin')
    for w, n in ins:
        if not w:
            L.append('      %s = ($urandom_range(0, 99) < p_one);' % n)
            continue
        bits = abs(eval(w.strip('[]').replace(':', '-'))) + 1
        if bits <= 32:
            L.append('      %s = $urandom;' % n)
        elif bits <= 64:
            # $urandom 一次只给 32 位；拼两次，不能用 {2{$urandom}}（那只调一次）
            L.append('      %s = {$urandom, $urandom};' % n)
        else:
            L.append('      for (int k = 0; k < %d; k += 32) %s[k +: 32] = $urandom;'
                     % (bits, n))
    L.append('    end')
    L.append('  endtask')
    L.append('')
    L.append('  // 逐输出比对（golden 为 X 时不判，见 CONVENTIONS「不读没写过的寄存器」）')
    L.append('  task automatic check_all();')
    L.append('    begin')
    for w, n in outs:
        L.append('      `CK(g_%s, i_%s, "%s")' % (n, n, n))
    L.append('    end')
    L.append('  endtask')
    L.append(END)
    return '\n'.join(L) + '\n'


def _splice(path, text):
    old = path.read_text()
    b = BEGIN.replace('(wrapper)', '(tb)') if path.name == 'tb.sv' else BEGIN
    i = old.index(b)
    j = old.index(END, i) + len(END) + 1
    return old, old[:i] + text + old[j:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()

    rc = 0
    for path, text in ((TARGET, build()), (TB, build_tb())):
        old, new = _splice(path, text)
        if a.check:
            if new != old:
                print('gen.py --check: %s 的生成区与生成器不一致' % path)
                rc = 1
        else:
            if new != old:
                path.write_text(new)
            print('gen.py: 已刷新 %s 的生成区' % path)
    if a.check and rc == 0:
        print('gen.py --check: OK')
    return rc


if __name__ == '__main__':
    sys.exit(main())
