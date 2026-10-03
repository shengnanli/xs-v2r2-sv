#!/usr/bin/env python3
"""生成 VIMac64b 的双例化 UT testbench（tb.sv）。

golden VIMac64b vs 重写 VIMac64b_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），逐拍比 io_vd / io_vxsat。

激励按"操作码 × 元素宽度"组织（golden 没有 opcode 口，操作由 5 个控制位 + 两个符号位决定，
tb 按 yunsuan VimacType 的 16 个操作逐一还原成这组控制位）：
    op      vs2S vs1S highHalf isMacc isSub widen isFixP
  每拍随机抽一个 op 与一个 sew（0..3 = 8/16/32/64 位），mode==15 时控制位全随机（含非法组合）。
  数据：2/3 全随机；1/3 按元素放特殊值（0 / 全 1 / 最小负数 / 最大正数 / 随机）——
        vsmul 的饱和只在两个操作数都是最小负数时发生，纯随机打不到，所以 vsmul 另有一半的拍
        两个操作数都按 3/4 概率逐元素放最小负数。
  fire：mode<4 恒 1（背靠背），其余 1/2。
覆盖闸：16 op × 4 sew 共 64 个组合各自的 fire 计数；vsmul 的 4 种 vxrm × 4 种 sew；每种 sew 下饱和；
        加宽 × uopIdx[0]；每个输出位见过 0/1。
不复位寄存器：两级数据/控制寄存器全部不复位。arm 条件 = golden 的 fireS1（第 1 拍有效）为 1：
        此刻 S1 寄存器已装载、且下一个上升沿必然装载 S2 寄存器（fireS1 带异步复位，它为 1 说明本拍没在复位），
        所以从下一拍起两侧输出都由写入过的寄存器决定。
        （第一版用"见过 io_fire 再等两拍"：复位期间的 fire 不会让 fireS1 起来，S2 没装载就开比，
          seed 7 × random 档报 6 个假失配，是 tb 的 arm 条件错，不是 RTL。）

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

#        名字        vs2S vs1S high macc sub widen fixp
OPS = [
    ("vmul",      1, 1, 0, 0, 0, 0, 0),
    ("vwmul",     1, 1, 0, 0, 0, 1, 0),
    ("vwmulu",    0, 0, 0, 0, 0, 1, 0),
    ("vwmulsu",   1, 0, 0, 0, 0, 1, 0),
    ("vmulh",     1, 1, 1, 0, 0, 0, 0),
    ("vmulhu",    0, 0, 1, 0, 0, 0, 0),
    ("vmulhsu",   1, 0, 1, 0, 0, 0, 0),
    ("vmacc",     1, 1, 0, 1, 0, 0, 0),
    ("vwmaccu",   0, 0, 0, 1, 0, 1, 0),
    ("vwmacc",    1, 1, 0, 1, 0, 1, 0),
    ("vwmaccsu",  0, 1, 0, 1, 0, 1, 0),
    ("vwmaccus",  1, 0, 0, 1, 0, 1, 0),
    ("vnmsac",    1, 1, 0, 1, 1, 0, 0),
    ("vmadd",     1, 1, 0, 1, 0, 0, 0),
    ("vnmsub",    1, 1, 0, 1, 1, 0, 0),
    ("vsmul",     1, 1, 0, 0, 0, 0, 1),
]
SEWS = ["e8", "e16", "e32", "e64"]

DECLS = """
int unsigned vm_op;      // 本拍抽到的操作（OPS 下标；16 = 控制位全随机）
logic [1:0]  vm_sew;
function automatic logic [63:0] vm_rnd_data(input logic [1:0] sew);
  logic [63:0] d;
  int unsigned w;
  d = {$urandom, $urandom};
  w = 8 << sew;
  if ($urandom_range(0, 2) == 0) begin
    for (int e = 0; e < 64 / w; e++) begin
      logic [63:0] v;
      case ($urandom_range(0, 7))
        0:       v = 64'h0;
        1:       v = ~64'h0;
        2, 3:    v = 64'h1 << (w - 1);            // 最小负数
        4:       v = (64'h1 << (w - 1)) - 64'h1;  // 最大正数
        default: v = {$urandom, $urandom};
      endcase
      for (int b = 0; b < w; b++) d[e * w + b] = v[b];
    end
  end
  return d;
endfunction
// 每个元素 3/4 概率取最小负数：专门给 vsmul 打饱和（两个操作数同一元素都是最小负数才饱和）
function automatic logic [63:0] vm_min_heavy(input logic [1:0] sew);
  logic [63:0] d;
  int unsigned w;
  d = {$urandom, $urandom};
  w = 8 << sew;
  for (int e = 0; e < 64 / w; e++) begin
    if ($urandom_range(0, 3) != 0) begin
      for (int b = 0; b < w; b++) d[e * w + b] = (b == w - 1);
    end
  end
  return d;
endfunction
"""

STIM = ["vm_sew = 2'($urandom);",
        "vm_op  = (@mode == 15) ? 16 : $urandom_range(0, %d);" % (len(OPS) - 1),
        "@io_vs1   = vm_rnd_data(vm_sew);",
        "@io_vs2   = vm_rnd_data(vm_sew);",
        "@io_oldVd = vm_rnd_data(vm_sew);",
        "@io_fire  = (@mode < 4) ? 1'b1 : 1'($urandom);",
        "case (vm_op)"]
for k, (name, s2, s1, hi, macc, sub, widen, fixp) in enumerate(OPS):
    STIM.append("  %d: begin  // %s" % (k, name))
    STIM.append("    @io_srcType_0 = {1'b0, 1'b%d, vm_sew}; @io_srcType_1 = {1'b0, 1'b%d, vm_sew};" % (s2, s1))
    STIM.append("    @io_highHalf = 1'b%d; @io_isMacc = 1'b%d; @io_isSub = 1'b%d; @io_widen = 1'b%d; @io_isFixP = 1'b%d;"
                % (hi, macc, sub, widen, fixp))
    STIM.append("  end")
STIM.append("  default: vm_sew = @io_srcType_0[1:0];  // 全随机档：sew 以实际灌进去的为准")
STIM.append("endcase")
STIM.append("if (@io_isFixP && $urandom_range(0, 1) == 0) begin  // vsmul 饱和偏置")
STIM.append("  @io_vs1 = vm_min_heavy(vm_sew);")
STIM.append("  @io_vs2 = vm_min_heavy(vm_sew);")
STIM.append("end")

G = "vm_u_gold."
COV = []
for k, op in enumerate(OPS):
    for s, sn in enumerate(SEWS):
        COV.append(("%s_%s" % (op[0], sn), "@io_fire && vm_op == %d && vm_sew == 2'd%d" % (k, s)))
for s, sn in enumerate(SEWS):
    COV.append(("randctl_%s" % sn, "@io_fire && vm_op == 16 && vm_sew == 2'd%d" % s))
# 以下看 golden 第三级（S2）的寄存器：结果真正出来的那一拍
for s, sn in enumerate(SEWS):
    COV.append(("sat_%s" % sn, "%ssewS2_oneHot[%d] && (|@io_vxsat)" % (G, s)))
    for rm in range(4):
        COV.append(("vsmul_%s_vxrm%d" % (sn, rm),
                    "%sisFixPS2 && %ssewS2_oneHot[%d] && %svxrmS2 == 2'd%d" % (G, G, s, G, rm)))
    COV.append(("sub_%s" % sn, "%sisSubS2 && !%sisFixPS2 && %ssewS2_oneHot[%d]" % (G, G, G, s)))
    COV.append(("high_%s" % sn, "%shighHalfS2 && %ssewS2_oneHot[%d]" % (G, G, s)))
COV.append(("widen_uop_even", "%swidenS2 && !%suopIdxS2[0]" % (G, G)))
COV.append(("widen_uop_odd", "%swidenS2 && %suopIdxS2[0]" % (G, G)))
COV.append(("fire_gap", "!@io_fire"))

PAIRS = [
    Pair("VIMac64b", "vm_", clocked=True, stim="\n".join(STIM), decls=DECLS, cov=COV,
         mode_period=1000, reset_period=20000, cov_min=300, arm=[G + "fireS1_last_r"]),
]

HEADER = """自动生成：verif/ut/VIMac64b/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
VIMac64b 双例化逐拍比对：golden VIMac64b vs 重写 VIMac64b_xs，io_vd / io_vxsat 逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
