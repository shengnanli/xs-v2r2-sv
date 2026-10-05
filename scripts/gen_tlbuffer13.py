#!/usr/bin/env python3
"""gen_tlbuffer13.py —— TLBuffer_13 golden 同名 wrapper 的机械派生区生成器。

TLBuffer_13 = 4 个完全相同的 TL-C 五通道缓冲 bank（L2Top.inner_buffer，4 个 L2 slice 各一条）。
可读部分是手写的 `xs_TLBuffer_13_bank`（rtl/memblock/TLBuffer_13.sv，本脚本不碰）；
本脚本只生成文件末尾 `// BEGIN GENERATED(TLBuffer_13)` … `// END GENERATED(TLBuffer_13)` 之间的
golden 同名 wrapper：golden 端口表（原顺序、一行一个）+ 4 个 bank 例化（逐端口按名连线）。

fail-closed 校验（任一不满足即退出非零、不写盘）：
  1. golden 端口除 clock/reset 外全部形如 auto_{in|out}_<b>_<rest>，b ∈ {0,1,2,3}；
  2. 4 个 bank 的 (方向, 位宽, <in|out>_<rest>) 集合完全相同；
  3. 手写 bank 模块的端口表与上面这个集合逐项相等（名、方向、位宽），不多不少；
  4. 生成区每个 golden 端口恰好出现在一个 bank 例化里一次。

用法: python3 scripts/gen_tlbuffer13.py [--check]   （--check 只比对不写盘）
"""
import os
import pathlib
import re
import sys

GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = REPO / 'rtl' / 'memblock' / 'TLBuffer_13.sv'
TOP = 'TLBuffer_13'
BANK = 'xs_TLBuffer_13_bank'
NBANK = 4
BEGIN = '// BEGIN GENERATED(TLBuffer_13) —— scripts/gen_tlbuffer13.py 生成，勿手改'
END = '// END GENERATED(TLBuffer_13)'
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:logic\s+)?(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*(//.*)?$')


def die(msg):
    sys.stderr.write(f'gen_tlbuffer13: {msg}\n')
    sys.exit(2)


def ports_of(text, mod):
    m = re.search(r'^module\s+%s\b[^(]*\((.*?)\n\);' % re.escape(mod), text, re.S | re.M)
    if not m:
        die(f'找不到 module {mod}')
    out = []
    for ln in m.group(1).splitlines():
        if not ln.strip() or ln.strip().startswith('//') or ln.strip().startswith('import'):
            continue
        pm = PORT_RE.match(ln)
        if not pm:
            die(f'{mod}: 端口行解析失败: {ln!r}')
        out.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return out


def main():
    check = '--check' in sys.argv[1:]
    gold = ports_of(pathlib.Path(GOLDEN, TOP + '.sv').read_text(), TOP)
    banks = {b: [] for b in range(NBANK)}
    for d, w, n in gold:
        if n in ('clock', 'reset'):
            continue
        m = re.match(r'^auto_(in|out)_(\d)_(\w+)$', n)
        if not m or int(m.group(2)) not in banks:
            die(f'golden 端口 {n} 不属于任何 bank')
        banks[int(m.group(2))].append((d, w, f'{m.group(1)}_{m.group(3)}'))
    ref = sorted(banks[0])
    for b in range(1, NBANK):
        if sorted(banks[b]) != ref:
            die(f'bank {b} 的端口集合与 bank 0 不同')
    text = RTL.read_text()
    bank_ports = [p for p in ports_of(text, BANK) if p[2] not in ('clock', 'reset')]
    if sorted(bank_ports) != ref:
        extra = set(bank_ports) - set(ref)
        miss = set(ref) - set(bank_ports)
        die(f'{BANK} 端口表与 golden 单 bank 端口不一致：多 {sorted(extra)[:5]} 缺 {sorted(miss)[:5]}')

    L = [BEGIN, '//', f'// golden 同名 wrapper：{len(gold)} 个端口按 golden 原顺序；4 个 bank 例化逐端口按名连线',
         f'// （auto_<in|out>_<b>_<x> -> bank b 的 <in|out>_<x>）。bank 内容见上面的 {BANK}。',
         f'module {TOP} (']
    for i, (d, w, n) in enumerate(gold):
        rng = f'[{w - 1}:0] ' if w > 1 else ''
        L.append(f'  {d:<6} logic {rng:<8}{n}{"," if i < len(gold) - 1 else ""}')
    L.append(');')
    used = 0
    for b in range(NBANK):
        L.append('')
        L.append(f'  {BANK} u_bank_{b} (')
        conns = [('clock', 'clock'), ('reset', 'reset')]
        for d, w, n in ports_of(text, BANK):
            if n in ('clock', 'reset'):
                continue
            side, rest = n.split('_', 1)
            conns.append((n, f'auto_{side}_{b}_{rest}'))
            used += 1
        wd = max(len(a) for a, _ in conns)
        L.append(',\n'.join(f'    .{a.ljust(wd)} ({t})' for a, t in conns))
        L.append('  );')
    if used != len(gold) - 2:
        die(f'连线数 {used} != golden 非时钟端口数 {len(gold) - 2}')
    L.append('endmodule')
    L.append(END)
    region = '\n'.join(L) + '\n'

    i, j = text.find(BEGIN), text.find(END)
    if i < 0 or j < 0 or j < i:
        die('rtl 文件里找不到 BEGIN/END GENERATED(TLBuffer_13) 标记')
    new = text[:i] + region + text[j + len(END) + 1:]
    if check:
        if new != text:
            print(f'DRIFT: {RTL}')
            return 1
        print(f'gen_tlbuffer13: {RTL.name} OK（{len(gold)} 端口，{NBANK} bank × {len(ref)}）')
        return 0
    RTL.write_text(new)
    print(f'gen_tlbuffer13: wrote {RTL}（{len(gold)} 端口，{NBANK} bank × {len(ref)}）')
    return 0


if __name__ == '__main__':
    sys.exit(main())
