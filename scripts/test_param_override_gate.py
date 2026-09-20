#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_param_override_gate.py —— check_param_override.py 的**双向**负测。

CONVENTIONS：「闸的负测必须是双向的：会报警 **和** 不会误报，缺一不可」，
以及「新写的闸第一次跑就全绿，本身就该触发怀疑」。本闸第一次跑确实就全绿
（当时 rtl/ 已经被同一个提交修好了），所以它必须自己证明两件事：

  会报警：把真实事故的形态（参数改名、例化没跟着改）种进临时 rtl 树，必须红；
  不误报：本仓真实存在的几种合法写法（带括号的维度表达式、省略 parameter 关键字
          的后续项、目标模块不在 rtl/ 里、按位置覆盖）必须绿。

每个用例都在自己的临时目录里，不碰仓库。
用法: python3 scripts/test_param_override_gate.py
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
GATE = HERE / 'check_param_override.py'

# 事故形态：核的参数叫 GOLDEN_REG_BITS，例化却写 GOLDEN_DATA_REG_BITS
CORE = '''// core
module xs_demo_core #(
  parameter int unsigned WIDTH = 1,
  parameter int unsigned STAGES = 2,
  parameter logic [(WIDTH > 0 ? WIDTH : 1)-1:0] MASK = '0,
  parameter int unsigned GOLDEN_REG_BITS = WIDTH * STAGES
)(
  input logic clock,
  input logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out
);
  localparam int unsigned NOT_OVERRIDABLE = 3;
  assign d_out = d_in;
endmodule
'''

GOOD_INST = '''// user
module demo_user(input logic clock, input logic [9:0] a, output logic [9:0] z);
  xs_demo_core #(
    .WIDTH(10), .STAGES(2), .MASK('0), .GOLDEN_REG_BITS(20)
  ) u (.clock(clock), .d_in(a), .d_out(z));
endmodule
'''

BAD_INST = GOOD_INST.replace('.GOLDEN_REG_BITS(20)', '.GOLDEN_DATA_REG_BITS(20)')

# 后续项省略 parameter 关键字（SV 允许，仍可按名覆盖）
CORE_IMPLICIT = '''// core2
module xs_demo2_core #(parameter int A = 1, B = 2)(input logic x, output logic y);
  assign y = x;
endmodule
'''
GOOD_INST_IMPLICIT = '''// user2
module demo2_user(input logic x, output logic y);
  xs_demo2_core #(.A(3), .B(4)) u (.x(x), .y(y));
endmodule
'''

# 目标模块不在这棵树里（厂商宏 / golden 件）：本闸无从判断，必须放行
FOREIGN_INST = '''// user3
module demo3_user(input logic x, output logic y);
  some_vendor_macro #(.WHATEVER_NAME(7)) u (.x(x), .y(y));
  assign y = x;
endmodule
'''

# 按位置覆盖：没有名字可核，必须放行
POSITIONAL_INST = '''// user4
module demo4_user(input logic clock, input logic [9:0] a, output logic [9:0] z);
  xs_demo_core #(10, 2, '0, 20) u (.clock(clock), .d_in(a), .d_out(z));
endmodule
'''

# 注释里写着事故形态（不是真例化）：必须放行
COMMENTED_INST = '''// user5
// 反面例子（只是注释）: xs_demo_core #(.GOLDEN_DATA_REG_BITS(20)) u (.d_in(a));
module demo5_user(input logic x, output logic y);
  assign y = x;
endmodule
'''

# 覆盖一个 localparam 名字：localparam 不可覆盖，必须报
LOCALPARAM_INST = GOOD_INST.replace('.GOLDEN_REG_BITS(20)', '.NOT_OVERRIDABLE(3)')


def run_gate(files):
    d = pathlib.Path(tempfile.mkdtemp(prefix='paramgate-'))
    try:
        for name, body in files.items():
            (d / name).write_text(body)
        r = subprocess.run([sys.executable, str(GATE), '--root', str(d)],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           universal_newlines=True)
        return r.returncode, r.stdout
    finally:
        shutil.rmtree(d, ignore_errors=True)


CASES = [
    # (说明, 文件表, 期望 rc)
    ('P1 正例：名字全对，必须绿',
     {'core.sv': CORE, 'user.sv': GOOD_INST}, 0),
    ('N1 ★事故形态★：参数改名、例化没跟着改，必须红',
     {'core.sv': CORE, 'user.sv': BAD_INST}, 1),
    ('P2 带括号的维度表达式（第一版正则在这里报过 30+ 假阳性），必须绿',
     {'core.sv': CORE, 'user.sv': GOOD_INST}, 0),
    ('P3 后续项省略 parameter 关键字，必须绿',
     {'core2.sv': CORE_IMPLICIT, 'user2.sv': GOOD_INST_IMPLICIT}, 0),
    ('P4 目标模块不在这棵树里（厂商宏/golden），不假装知道，必须绿',
     {'user3.sv': FOREIGN_INST}, 0),
    ('P5 按位置覆盖（没有名字可核），必须绿',
     {'core.sv': CORE, 'user4.sv': POSITIONAL_INST}, 0),
    ('P6 注释里的反面例子不是真例化，必须绿',
     {'core.sv': CORE, 'user5.sv': COMMENTED_INST}, 0),
    ('N2 覆盖 localparam 名字（localparam 不可覆盖），必须红',
     {'core.sv': CORE, 'user.sv': LOCALPARAM_INST}, 1),
    ('N3 空扫描不算通过（没有 .sv 时必须非零退出）',
     {}, 2),
]


def main():
    print('=== check_param_override.py 双向负测 ===')
    bad = 0
    for desc, files, want in CASES:
        rc, out = run_gate(files)
        ok = (rc == want)
        print('  %-62s rc=%d(期望 %d) %s' % (desc, rc, want, 'ok' if ok else '★不符★'))
        if not ok:
            bad += 1
            print('    ---- 闸的输出 ----')
            for ln in out.strip().splitlines():
                print('    ' + ln)
    print('PASS %d / FAIL %d' % (len(CASES) - bad, bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
