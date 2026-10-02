#!/usr/bin/env python3
"""gen_pmpcfg_leaves5.py —— 生成 Pmp{0..4}cfgModule 五个薄 wrapper 的端口表区。

族 C（PMP cfg 变体族）：5 个 golden Pmp{0..4}cfgModule 去模块名后逐字节相同
（本脚本每次运行都重新断言这一点，端口表逐变体互相比对），全族共用
rtl/backend/xs_Pmpcfg_core.sv（无参数核），wrapper 只做端口名转接。

本脚本做的事：
  1. 解析 golden Pmp0cfgModule.sv 的端口表，并断言其余 4 个变体的端口表逐项相同；
  2. 把 rtl/backend/Pmp<N>cfgModule.sv 里 BEGIN/END GENERATED 标记之间的内容
     替换为该端口表；文件不存在时用模板整建（含文件头注释与核例化）；
  3. 手写区（标记之外）绝不触碰；--check 只比对不写，漂移即非零退出。

用法: python3 scripts/gen_pmpcfg_leaves5.py [--check]
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GOLDEN = Path('/home/eda/xs-env/G1-canonical/golden-rtl')
RTL_DIR = REPO / 'rtl' / 'backend'
SLOTS = range(5)
BEGIN = '// BEGIN GENERATED(pmpcfg_wrapper)'
END = '// END GENERATED'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')


def golden_ports(slot):
    """从 golden 解析端口表：[(dir, msb 或 None, name), ...]，按声明顺序。"""
    txt = (GOLDEN / f'Pmp{slot}cfgModule.sv').read_text()
    i = txt.index(f'module Pmp{slot}cfgModule(')
    j = txt.index('\n);', i)
    out = []
    for line in txt[i:j].splitlines()[1:]:
        m = PORT_RE.match(line)
        assert m, f'Pmp{slot}cfgModule: 无法解析的端口行: {line!r}'
        out.append((m.group(1), int(m.group(2)) if m.group(2) else None, m.group(3)))
    assert out, f'Pmp{slot}cfgModule: 端口表为空'
    return out


def fmt_port(direction, msb, name, last):
    width = f'[{msb}:0]' if msb is not None else ''
    comma = '' if last else ','
    return f'  {direction:<6} logic {width:<8}{name}{comma}'


def generated_region(ports):
    lines = [fmt_port(d, w, n, i == len(ports) - 1)
             for i, (d, w, n) in enumerate(ports)]
    return BEGIN + '\n' + '\n'.join(lines) + '\n' + END


def template(slot, ports):
    return f'''// Pmp{slot}cfgModule.sv —— NewCSR 的 PMP 配置条目 {slot}（pmpcfg 寄存器字节 {slot}）薄 wrapper
// 位置：父模块 NewCSR 的 pmpcfgs 序列第 {slot} 项；条目索引只体现在模块名与父模块的
//   地址译码上。五个变体 Pmp0..4cfgModule 的 golden 去模块名后逐字节相同（已 diff
//   核实，生成器每次重跑都会再断言一次），故全族共用无参数核，本文件只做端口名转接。
// 核体见 rtl/backend/xs_Pmpcfg_core.sv（WARL：A 写 2 落 3；R=0 且 W=1 时 W 不更新；
//   异步复位清 0；rdata = {{L, 2'b0, A, X, W, R}}）。
// 端口表在 BEGIN/END GENERATED 区内，由 scripts/gen_pmpcfg_leaves5.py 生成，勿手改。
module Pmp{slot}cfgModule (
{generated_region(ports)}
);
  xs_Pmpcfg_core u_core (
    .clk     (clock),
    .rst     (reset),
    .wr_en   (w_wen),
    .wr_data (w_wdata),
    .rd_data (rdata),
    .cfg_r   (regOut_R),
    .cfg_w   (regOut_W),
    .cfg_x   (regOut_X),
    .cfg_a   (regOut_A),
    .cfg_l   (regOut_L)
  );
endmodule
'''


def regenerate(path, slot, ports):
    """有标记区就原地替换；文件不存在则整建。返回新文本。"""
    region = generated_region(ports)
    if not path.exists():
        return template(slot, ports)
    txt = path.read_text()
    b = txt.find(BEGIN)
    e = txt.find(END)
    assert b != -1 and e != -1 and b < e, f'{path}: 缺 BEGIN/END GENERATED 标记'
    return txt[:b] + region + txt[e + len(END):]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()

    # 全族同构断言：5 个 golden 变体的端口表必须逐项相同，否则不允许共用核。
    per_slot = {s: golden_ports(s) for s in SLOTS}
    base = per_slot[0]
    for s in SLOTS:
        assert per_slot[s] == base, \
            f'Pmp{s}cfgModule 端口表与 Pmp0cfgModule 不同：变体不再同构，需人工复查'

    drift = []
    for s in SLOTS:
        path = RTL_DIR / f'Pmp{s}cfgModule.sv'
        new = regenerate(path, s, base)
        if args.check:
            if not path.exists() or path.read_text() != new:
                drift.append(str(path))
        else:
            if not path.exists() or path.read_text() != new:
                path.write_text(new)
    if drift:
        print('gen_pmpcfg_leaves5 --check: DRIFT: ' + ' '.join(drift))
        raise SystemExit(1)
    if args.check:
        print(f'gen_pmpcfg_leaves5 --check: OK ({len(list(SLOTS))} files)')


if __name__ == '__main__':
    main()
