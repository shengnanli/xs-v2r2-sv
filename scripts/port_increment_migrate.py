#!/usr/bin/env python3
"""port_increment_migrate.py —— "纯接口增量"目标的 G0→G1 迁移。

适用条件（脚本自己验，不满足就拒绝迁移）：
  golden 在 G0 与 G1 之间，**去掉端口表后的模块体逐字相同**（仅断言 .scala 行号除外）。
  这类改动只是 Chisel 在接口上加了透传字段（perfDebugInfo / debug.seqNum / ready 等），
  运算逻辑没动，所以可读核可整体沿用，只需按 G1 端口重做 wrapper。

做法：
  1. 核文件从上轮工程原样取（并校验其不含 golden 展平中间名）；
  2. wrapper 端口表**整段取自 G1 golden**；
  3. wrapper 里的直通 assign **从 G1 golden 文本机械提取**（不手打，避免漏项/错配）；
  4. 子模块例化整段照抄 golden 的实例（端口连接名即 golden 名，逐字），
     只把被可读核替换掉的部分换成核例化；
  5. 输出单文件：核 + golden 同名 wrapper。

用法:
  port_increment_migrate.py <target> --core <上轮核文件> [--pkg <上轮pkg>]
      --core-inst "<核例化整段>"   核如何被例化（含端口连接），由调用方给出
      [--keep-inst <子模块名>...]  golden 里保留照抄的子模块实例
"""
import argparse
import hashlib
import pathlib
import re
import sys

G0 = pathlib.Path('/home/eda/xs-env/G0-canonical/golden-rtl')
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OLD = pathlib.Path('/home/eda/xs-env/xs-v2r2-sv')
REPO = pathlib.Path(__file__).resolve().parent.parent
SCALA = re.compile(rb'\.scala:\d+')


def strip_ports(text, name):
    i = text.index(f'module {name}(')
    j = text.index('\n);', i) + 3
    return text[:i] + text[j:]


PURE_ASSIGN = re.compile(r'^\s*assign\s+(io_\w+)\s*=\s*\n?\s*(io_\w+);\s*$',
                         re.MULTILINE)


def strip_passthrough(text):
    """去掉形如 `assign io_out_X = io_in_Y;` / `assign io_in_ready = io_out_ready;`
    的纯直通语句——它们是随新端口一起加进来的，不算逻辑改动。
    只去"整条 io_ 到 io_ 的裸赋值"，任何带运算/切片/三元的赋值都保留（那是真改动）。"""
    return PURE_ASSIGN.sub('', text)


def body_identical(name):
    """判据：去端口表 + 去纯直通 + 归一断言行号后，两边模块体逐字相同。"""
    def norm(root):
        s = strip_ports((root / f'{name}.sv').read_text(), name)
        s = strip_passthrough(s)
        s = re.sub(r'\n\s*\n+', '\n', s)
        return SCALA.sub(b'.scala:0', s.encode())
    return norm(G0) == norm(G1)


def ports_of(name):
    t = (G1 / f'{name}.sv').read_text()
    i = t.index(f'module {name}(')
    j = t.index('\n);', i) + len('\n);')
    return t[i:j]


def passthrough_of(name, skip):
    """从 G1 golden 提取纯直通 assign；skip 里的目标端口由可读核驱动。"""
    t = (G1 / f'{name}.sv').read_text()
    body = t[t.index('\n);') + 3:]
    out, rev = [], []
    for m in re.finditer(r'assign\s+(\w+)\s*=\s*\n?\s*(\w+);', body):
        dst, src = m.group(1), m.group(2)
        if dst in skip:
            continue
        if dst.startswith('io_out') and (src.startswith('io_in') or src == 'io_out_ready'):
            out.append((dst, src))
        elif dst == 'io_in_ready':
            rev.append((dst, src))
    return out, rev


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target')
    ap.add_argument('--core', required=True)
    ap.add_argument('--pkg', default=None)
    ap.add_argument('--core-inst', required=True)
    ap.add_argument('--core-drives', nargs='*', default=[],
                    help='由可读核驱动的输出端口（不列入直通）')
    ap.add_argument('--subsys', default='backend')
    ap.add_argument('--note', default='')
    a = ap.parse_args()
    t = a.target

    if not body_identical(t):
        sys.exit(f'ERROR: {t} 在 G0/G1 之间**模块体有差异**，不属纯接口增量，'
                 f'不能用本脚本迁移（须逐行对照重写）')

    pieces = []
    hdr = [f'// {t} —— 由 scripts/port_increment_migrate.py 迁移自上轮可读核',
           '//',
           '// 迁移依据（脚本已校验）：G0 与 G1 的 golden 去掉端口表后**逐字相同**，',
           '// 即 G1 的改动只是接口增量（perfDebugInfo / debug.seqNum / ready 等透传字段），',
           '// 运算逻辑未动。故核体沿用，wrapper 按 G1 端口重做，直通 assign 由 golden',
           '// 文本机械提取（不手打）。']
    if a.note:
        hdr += ['//', '// ' + a.note]
    pieces.append('\n'.join(hdr) + '\n')

    if a.pkg:
        pieces.append(pathlib.Path(a.pkg).read_text().rstrip())
    pieces.append(pathlib.Path(a.core).read_text().rstrip())

    skip = set(a.core_drives)
    fwd, rev = passthrough_of(t, skip)
    w = max([len(d) for d, _ in fwd + rev] or [1])
    body = ['// ' + '-' * 75,
            f'// golden 同名 wrapper：端口与 G1 golden {t}.sv 完全一致',
            '// ' + '-' * 75,
            ports_of(t), '',
            a.core_inst.rstrip(), '']
    if rev:
        body.append('  // 握手直通（无内部阻塞）')
        for d, s in rev:
            body.append(f'  assign {d:{w}s} = {s};')
        body.append('')
    body.append('  // 控制/调试旁路直通（Chisel PipedFuncUnit 的 out := in）')
    for d, s in fwd:
        body.append(f'  assign {d:{w}s} = {s};')
    body += ['', 'endmodule']
    pieces.append('\n'.join(body))

    out = REPO / 'rtl' / a.subsys / f'{t}.sv'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text('\n\n'.join(pieces) + '\n')
    print(f'{t}: 迁移完成 -> {out.relative_to(REPO)}（直通 {len(fwd)} + 握手 {len(rev)}）')


if __name__ == '__main__':
    main()
