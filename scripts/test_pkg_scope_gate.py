#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_pkg_scope_gate.py —— check_pkg_scope.py 的负测（种病必须被抓）。

**为什么需要负测**：一道闸「跑了、退出 0」不等于「它真的会响」。本工程已经踩过一次
同形态的坑（anti-rot 两道闸交付时没接进任何 Makefile，等于不存在）。闸的价值全在
它抓得住病，所以每条判据都得有一个**故意种的病例**证明它会红。

做法：在临时目录里造一棵最小 rtl 树，用 `XSSV_RTL` 指过去（check_pkg_scope.py 支持
该覆盖），逐条判据各种一个病，要求：
  - 干净样本   -> 退出 0
  - A 包重名   -> 退出 1，且 finding 里含 DUPLICATE_PACKAGE
  - B 跨文件包 -> 退出 1，且 finding 里含 CROSS_FILE_PACKAGE
  - C $unit import -> 退出 1，且 finding 里含 UNIT_SCOPE_IMPORT
C 类另外钉两个**不该误报**的合法形态（模块头 import 的两种写法），防止闸把正确代码判红。
"""
import os
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
GATE = HERE / 'check_pkg_scope.py'

CLEAN = {
    # 公共包文件：跨文件共享包的合法落点
    'frontend/frontend_common_pkg.sv': (
        'package shared_pkg;\n  localparam int W = 8;\nendpackage\n'),
    # 合法形态 1：import 单独成行的模块头写法（PreDecode.sv 风格）
    'frontend/Foo.sv': (
        'package foo_pkg;\n  localparam int IDX = 3;\nendpackage\n\n'
        'module xs_Foo_core\n  import foo_pkg::*;\n(output logic [IDX-1:0] o);\n'
        '  assign o = \'0;\nendmodule\n'),
    # 合法形态 2：import 与 module 同行、带参数表（TlbStorageWrapper.sv 风格）
    'frontend/Bar.sv': (
        'package bar_pkg;\n  localparam int IDX = 5;\nendpackage\n\n'
        'module xs_Bar_core import bar_pkg::*; #(parameter int P = 1)\n'
        '(output logic [IDX-1:0] o);\n  assign o = \'0;\nendmodule\n\n'
        'module Bar import bar_pkg::*; (output logic [IDX-1:0] o);\n'
        '  xs_Bar_core u(.o(o));\nendmodule\n'),
    # 跨文件使用公共包 —— 合法（包住在 *_common_pkg.sv）
    'frontend/Baz.sv': (
        'module Baz\n  import shared_pkg::*;\n(output logic [W-1:0] o);\n'
        '  assign o = \'0;\nendmodule\n'),
}

CASES = [
    ('A 包重名', {'frontend/Dup.sv':
        'package foo_pkg;\n  localparam int IDX = 9;\nendpackage\n'},
     'DUPLICATE_PACKAGE'),
    ('B 跨文件共享包藏在兄弟模块文件里', {'frontend/User.sv':
        'module User\n  import foo_pkg::*;\n(output logic [IDX-1:0] o);\n'
        '  assign o = \'0;\nendmodule\n'},
     'CROSS_FILE_PACKAGE'),
    ('C $unit 作用域 import（行首）', {'frontend/Unit.sv':
        'package unit_pkg;\n  localparam int IDX = 7;\nendpackage\n\n'
        'import unit_pkg::*;\n\nmodule Unit (output logic [IDX-1:0] o);\n'
        '  assign o = \'0;\nendmodule\n'},
     'UNIT_SCOPE_IMPORT'),
    ('C $unit 作用域 import（有缩进，缩进不改作用域）', {'frontend/Unit2.sv':
        'package unit2_pkg;\n  localparam int IDX = 7;\nendpackage\n\n'
        '  import unit2_pkg::*;\n\nmodule Unit2 (output logic [IDX-1:0] o);\n'
        '  assign o = \'0;\nendmodule\n'},
     'UNIT_SCOPE_IMPORT'),
    ('C $unit 作用域 import（夹在两个模块之间）', {'frontend/Unit3.sv':
        'package unit3_pkg;\n  localparam int IDX = 7;\nendpackage\n\n'
        'module A3 (output logic o);\n  assign o = \'0;\nendmodule\n\n'
        'import unit3_pkg::*;\n\nmodule B3 (output logic [IDX-1:0] o);\n'
        '  assign o = \'0;\nendmodule\n'},
     'UNIT_SCOPE_IMPORT'),
]


def run(root):
    # python3.6 没有 capture_output/text，用 PIPE + universal_newlines
    env = dict(os.environ, XSSV_RTL=str(root))
    r = subprocess.run([sys.executable, str(GATE)], stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True, env=env)
    return r.returncode, r.stdout


def build(root, extra):
    for rel, body in list(CLEAN.items()) + list(extra.items()):
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(body)


def main():
    fails = []
    with tempfile.TemporaryDirectory() as td:
        root = pathlib.Path(td) / 'rtl'
        build(root, {})
        rc, out = run(root)
        if rc != 0:
            fails.append(f'干净样本被判红（rc={rc}）——闸在误报：\n{out}')
        else:
            print('  PASS  干净样本 rc=0（含两种合法模块头 import 写法，未误报）')

    for name, extra, marker in CASES:
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td) / 'rtl'
            build(root, extra)
            rc, out = run(root)
            if rc == 0:
                fails.append(f'负测「{name}」：种了病闸却 rc=0 —— 这道判据抓不住：\n{out}')
            elif marker not in out:
                fails.append(f'负测「{name}」：闸红了但没报 {marker}：\n{out}')
            else:
                print(f'  PASS  负测「{name}」被抓（{marker}）')

    if fails:
        print('\n=== test_pkg_scope_gate FAILED ===')
        for f in fails:
            print('  ★ ' + f)
        return 1
    print('=== test_pkg_scope_gate PASSED ===')
    return 0


if __name__ == '__main__':
    sys.exit(main())
