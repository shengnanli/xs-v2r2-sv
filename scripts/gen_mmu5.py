#!/usr/bin/env python3
"""gen_mmu5.py —— 生成 L2TLB 五个 child（HPTW / BitmapCache / PTW / Bitmap / LLPTW）里
**纯机械**的三段：可读核的端口表、golden 同名 wrapper、UT tb 的双例化骨架。

为什么要有这个生成器：这五个模块的边界是 firtool 展平过的（PTW 419 根、LLPTW 163 根标量
端口），一根都不能错，但里面没有任何设计判断，靠手敲只会引入抄写错误。所以：

  * rtl/mmu/<M>.sv 里
      // BEGIN GENERATED(core_ports)  … // END GENERATED(core_ports)   核的端口表
      // BEGIN GENERATED(wrapper)     … // END GENERATED(wrapper)      整个 wrapper 模块
  * verif/ut/<M>/tb.sv 里
      // BEGIN GENERATED(harness)     … // END GENERATED(harness)
      信号声明 + golden/impl 双例化 + 逐拍比全部输出的 compare_outputs()
  三段都从 G1 golden 的端口表逐根抄出来；手写区（核体、激励）本脚本不碰。

★本文件不做任何等价性判断★：它抄的是 golden 的端口拓扑，抄对了不等于逻辑对了。

用法:
    python3 scripts/gen_mmu5.py <Module> [...]     # 原地改写上述 GENERATED 段
    python3 scripts/gen_mmu5.py --check            # 只校验全部已落地模块的产物逐字节一致
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('GOLDEN_RTL',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
MODULES = ['HPTW', 'BitmapCache', 'PTW', 'Bitmap', 'LLPTW']

PORT_RE = re.compile(r'^\s+(input|output)\s+(\[[^\]]*\]\s+)?(\w+),?\s*$')


def golden_ports(mod):
    """[(dir, range_str_or_'', name)]，按 golden 端口表原顺序。"""
    lines = (GOLDEN / (mod + '.sv')).read_text().split('\n')
    out = []
    inside = False
    for ln in lines:
        if re.match(r'^module\s+' + re.escape(mod) + r'\s*\(', ln):
            inside = True
            continue
        if not inside:
            continue
        if ln.strip() == ');':
            break
        m = PORT_RE.match(ln)
        if not m:
            raise SystemExit('端口行解析不了（fail-closed）: %r' % ln)
        out.append((m.group(1), (m.group(2) or '').strip(), m.group(3)))
    if not out:
        raise SystemExit('golden %s 没解析到端口' % mod)
    return out


def fmt_port_decl(direction, rng, name, last):
    d = 'input ' if direction == 'input' else 'output'
    r = (rng + ' ') if rng else ''
    return '  %s logic %-8s%s%s' % (d, r, name, '' if last else ',')


def core_ports_block(ports):
    lines = ['  // BEGIN GENERATED(core_ports) —— 由 gen_mmu5.py 从 golden 端口表逐根抄出']
    for i, (d, r, n) in enumerate(ports):
        lines.append(fmt_port_decl(d, r, n, i == len(ports) - 1))
    lines.append('  // END GENERATED(core_ports)')
    return '\n'.join(lines)


def wrapper_block(mod, ports):
    w = max(len(n) for _, _, n in ports)
    lines = ['// BEGIN GENERATED(wrapper) —— 由 gen_mmu5.py 生成：%s 的 golden 同名 wrapper，' % mod,
             '// 端口与 G1 golden 逐位同名，纯透传到 xs_%s_core（无任何逻辑）。' % mod,
             'module %s(' % mod]
    for i, (d, r, n) in enumerate(ports):
        lines.append(fmt_port_decl(d, r, n, i == len(ports) - 1))
    lines.append(');')
    lines.append('  xs_%s_core u_core (' % mod)
    for i, (d, r, n) in enumerate(ports):
        lines.append('    .%-*s (%s)%s' % (w, n, n, '' if i == len(ports) - 1 else ','))
    lines.append('  );')
    lines.append('endmodule')
    lines.append('// END GENERATED(wrapper)')
    return '\n'.join(lines)


def harness_block(mod, ports):
    ins = [(r, n) for d, r, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(r, n) for d, r, n in ports if d == 'output']
    w = max(len(n) for _, _, n in ports)
    L = ['  // BEGIN GENERATED(harness) —— 由 gen_mmu5.py 生成：信号声明 / 双例化 / 输出逐拍比对',
         '  logic clock, reset;']
    for r, n in ins:
        L.append('  logic %s%s;' % ((r + ' ') if r else '', n))
    for r, n in outs:
        L.append('  logic %sg_%s, i_%s;' % ((r + ' ') if r else '', n, n))

    def inst(mname, iname, pre):
        L.append('  %s %s (' % (mname, iname))
        L.append('    .clock(clock), .reset(reset),')
        conns = []
        for d, r, n in ports:
            if n in ('clock', 'reset'):
                continue
            conns.append('    .%-*s (%s%s)' % (w, n, pre if d == 'output' else '', n))
        L.append(',\n'.join(conns))
        L.append('  );')
    inst(mod, 'u_g', 'g_')
    inst(mod + '_xs', 'u_i', 'i_')
    L.append('  // 逐拍比全部 %d 个输出（golden 端口表逐根量出，不手抄）' % len(outs))
    L.append('  task automatic compare_outputs(input int cyc);')
    for r, n in outs:
        L.append('    checks++; if (g_%s !== i_%s) begin errors++; if (errors <= 20)' % (n, n))
        L.append('      $display("MISMATCH cyc=%%0d %s g=%%h i=%%h", cyc, g_%s, i_%s); end' % (n, n, n))
    L.append('  endtask')
    L.append('  // END GENERATED(harness)')
    return '\n'.join(L)


def splice(text, tag, block, path):
    begin = '// BEGIN GENERATED(%s)' % tag
    end = '// END GENERATED(%s)' % tag
    b = text.find(begin)
    e = text.find(end)
    if b < 0 or e < 0:
        raise SystemExit('%s 里没有 %s 标记（手写区先放好标记再跑生成器）' % (path, tag))
    # 标记行首的缩进属于块本身（生成块自带缩进），替换范围从 begin 行首到 end 行尾
    b0 = text.rfind('\n', 0, b) + 1
    e1 = text.find('\n', e)
    return text[:b0] + block + text[e1:]


def targets(mod):
    return [(REPO / 'rtl' / 'mmu' / (mod + '.sv'), [('core_ports', core_ports_block), ('wrapper', wrapper_block)]),
            (REPO / 'verif' / 'ut' / mod / 'tb.sv', [('harness', harness_block)])]


def render(mod):
    ports = golden_ports(mod)
    out = []
    for path, blocks in targets(mod):
        if not path.exists():
            continue
        text = path.read_text()
        for tag, fn in blocks:
            blk = fn(ports) if tag == 'core_ports' else fn(mod, ports)
            text = splice(text, tag, blk, path)
        out.append((path, text))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('modules', nargs='*')
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    mods = a.modules or MODULES
    drift = 0
    for mod in mods:
        for path, text in render(mod):
            cur = path.read_text()
            if a.check:
                if cur != text:
                    print('DRIFT: %s 的生成段与重算结果不一致' % path)
                    drift += 1
                else:
                    print('OK: %s' % path.relative_to(REPO))
            elif cur != text:
                path.write_text(text)
                print('wrote %s' % path.relative_to(REPO))
            else:
                print('unchanged %s' % path.relative_to(REPO))
    return 1 if drift else 0


if __name__ == '__main__':
    sys.exit(main())
