#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_csrtrapvalue_leaves8.py —— 族 E（8 个 CSR trap cause/tval 叶）的 wrapper 生成器。

手写部分：rtl/backend/xs_CsrTrapValue_core.sv（共享核）与每个
rtl/backend/<Module>.sv 里的文件头注释和 xs_<Module>_core 薄核。
本脚本只重写每个 <Module>.sv 里
    // BEGIN GENERATED(csrtrapvalue-leaves8)
    ...
    // END GENERATED
之间的 golden 同名 wrapper（端口表 + u_core 连线）。

★所有维度都从 golden 实测、fail-closed★：端口表逐行解析 G1 golden 并断言与
本族两亚族的期望形状逐字一致（名字/方向/位宽/顺序、trap 口前缀），golden 的
更新/复位结构也做模板核对；任何一项不符即报错退出，绝不猜。

用法: python3 scripts/gen_csrtrapvalue_leaves8.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（幂等闸）。
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
BEGIN = '// BEGIN GENERATED(csrtrapvalue-leaves8)'
END = '// END GENERATED'

# 变体表：名字 -> (亚族, trap 口前缀)。trap 口前缀取自 golden 端口名实测，
# 本表是断言基准，不是生成依据（生成依据是 golden 解析结果，两者不符即报错）。
VARIANTS = {
    'McauseModule':  ('cause', 'trapToM_mcause'),
    'ScauseModule':  ('cause', 'trapToHS_scause'),
    'VScauseModule': ('cause', 'trapToVS_vscause'),
    'MncauseModule': ('cause', 'trapToMN_mncause'),
    'MtvalModule':   ('tval',  'trapToM_mtval'),
    'StvalModule':   ('tval',  'trapToHS_stval'),
    'VStvalModule':  ('tval',  'trapToVS_vstval'),
    'Mtval2Module':  ('tval',  'trapToM_mtval2'),
}

# 期望端口表（golden 顺序）：(名字, 方向, 位宽)；trap 口前缀用 {p} 占位。
EXPECTED = {
    'cause': [
        ('clock', 'input', 1),
        ('reset', 'input', 1),
        ('w_wen', 'input', 1),
        ('w_wdata', 'input', 64),
        ('rdata', 'output', 64),
        ('regOut_Interrupt', 'output', 1),
        ('regOut_ExceptionCode', 'output', 63),
        ('{p}_valid', 'input', 1),
        ('{p}_bits_Interrupt', 'input', 1),
        ('{p}_bits_ExceptionCode', 'input', 63),
    ],
    'tval': [
        ('clock', 'input', 1),
        ('reset', 'input', 1),
        ('w_wen', 'input', 1),
        ('w_wdata', 'input', 64),
        ('rdata', 'output', 64),
        ('regOut_ALL', 'output', 64),
        ('{p}_valid', 'input', 1),
        ('{p}_bits_ALL', 'input', 64),
    ],
}

# golden 端口名 -> xs_<Module>_core 端口名
CORE_MAP = {
    'cause': {
        'clock': 'clock',
        'reset': 'reset',
        'w_wen': 'wen',
        'w_wdata': 'wdata',
        'rdata': 'rdata',
        'regOut_Interrupt': 'reg_interrupt',
        'regOut_ExceptionCode': 'reg_exception_code',
        '{p}_valid': 'trap_valid',
        '{p}_bits_Interrupt': 'trap_interrupt',
        '{p}_bits_ExceptionCode': 'trap_exception_code',
    },
    'tval': {
        'clock': 'clock',
        'reset': 'reset',
        'w_wen': 'wen',
        'w_wdata': 'wdata',
        'rdata': 'rdata',
        'regOut_ALL': 'reg_all',
        '{p}_valid': 'trap_valid',
        '{p}_bits_ALL': 'trap_tval',
    },
}

PORT_RE = re.compile(r'^\s*(input|output)\s*(?:\[(\d+):0\])?\s*(\w+),?$')


def die(msg):
    sys.exit('gen_csrtrapvalue_leaves8: ERROR: ' + msg)


def parse_golden(name, family, prefix):
    """解析 golden 端口表并核对更新/复位结构，返回 [(名字, 方向, 位宽)]（golden 顺序）。"""
    path = GOLDEN / (name + '.sv')
    if not path.exists():
        die('golden 不存在: %s' % path)
    text = path.read_text()
    m = re.search(r'\nmodule %s\((.*?)\n\);' % name, text, re.S)
    if not m:
        die('%s: 找不到 module 端口表' % name)
    ports = []
    for line in m.group(1).splitlines():
        line = line.strip()
        if not line:
            continue
        pm = PORT_RE.match(line)
        if not pm:
            die('%s: 端口行解析失败: %r' % (name, line))
        ports.append((pm.group(3), pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1))
    expected = [(p.format(p=prefix), d, w) for p, d, w in EXPECTED[family]]
    if ports != expected:
        die('%s: 端口表与 %s 亚族期望不符:\n  got=%r\n  exp=%r' % (name, family, ports, expected))
    # 结构模板核对（fail-closed）：异步复位到 0 + 双写口按位或合并。
    if 'always @(posedge clock or posedge reset)' not in text:
        die('%s: 不是异步复位 always 块' % name)
    if 'else if (w_wen | %s_valid)' % prefix not in text:
        die('%s: 写使能不是 w_wen | %s_valid' % (name, prefix))
    if family == 'cause':
        if ('%s_valid & %s_bits_Interrupt | w_wen & w_wdata[63]' % (prefix, prefix)) not in text:
            die('%s: Interrupt 更新式不符' % name)
        if ('(%s_valid ? %s_bits_ExceptionCode : 63\'h0)' % (prefix, prefix)) not in text:
            die('%s: ExceptionCode 更新式不符' % name)
    else:
        if ('(%s_valid ? %s_bits_ALL : 64\'h0)' % (prefix, prefix)) not in text:
            die('%s: ALL 更新式不符' % name)
        if '| (w_wen ? w_wdata : 64\'h0);' not in text:
            die('%s: 软件写或并项不符' % name)
    return ports


def gen_wrapper(name, family, prefix, ports):
    """由解析出的 golden 端口表生成 wrapper（端口表 + u_core 连线）。"""
    lines = [BEGIN, 'module %s (' % name]
    decls = []
    for pname, direction, width in ports:
        w = '' if width == 1 else '[%d:0] ' % (width - 1)
        decls.append('  %s logic %s%s' % (direction, w, pname))
    lines.append(',\n'.join(decls))
    lines.append(');')
    lines.append('')
    lines.append('  xs_%s_core u_core (' % name)
    conns = []
    cmap = CORE_MAP[family]
    for pname, direction, width in ports:
        core_port = cmap[pname.replace(prefix, '{p}')]
        conns.append('    .%-19s(%s)' % (core_port, pname))
    lines.append(',\n'.join(conns))
    lines.append('  );')
    lines.append('')
    lines.append('endmodule')
    lines.append(END)
    return '\n'.join(lines) + '\n'


def splice(path, region, check):
    """把 region 写进 path 的 BEGIN/END 之间；check 模式只比对。"""
    text = path.read_text()
    i = text.find(BEGIN)
    j = text.find(END)
    if i < 0 or j < 0 or j < i:
        die('%s: 找不到成对的 GENERATED 标记' % path)
    new = text[:i] + region + text[j + len(END) + 1:]
    if check:
        return new == text
    if new != text:
        path.write_text(new)
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    drift = []
    for name, (family, prefix) in VARIANTS.items():
        ports = parse_golden(name, family, prefix)
        region = gen_wrapper(name, family, prefix, ports)
        path = REPO / 'rtl' / 'backend' / (name + '.sv')
        if not path.exists():
            die('%s 不存在（手写区必须先建好）' % path)
        if not splice(path, region, args.check):
            drift.append(str(path))
    if drift:
        print('gen_csrtrapvalue_leaves8 --check: DRIFT: ' + ' '.join(drift))
        raise SystemExit(1)
    print('gen_csrtrapvalue_leaves8: %s (%d files)' %
          ('--check OK' if args.check else 'generated', len(VARIANTS)))


if __name__ == '__main__':
    main()
