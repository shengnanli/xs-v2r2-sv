#!/usr/bin/env python3
"""生成 CSA_Nto2With3to2MainPipeline 的双例化 UT testbench（tb.sv）。

golden CSA_Nto2With3to2MainPipeline vs 重写 CSA_Nto2With3to2MainPipeline_xs（scripts/dual_tb_lib.py，
端口表读 G1 golden），逐拍比 out_sum / out_car 两个 107 位输出。

激励：fire 约 3/4 的拍为 1；27 个加数按 mode 分段偏置——全随机 / 稀疏（每个加数只留少数几位）/
  大量全 1（压出长进位链）/ 像 Booth 部分积那样高位补 1 的形状。
arm：寄存器不复位，第一次 fire 之后才开始比（两侧初值 +vcs+initreg+random 下各摇各的）。
覆盖闸：fire=0 / fire=1 的拍数；每个输出位见过 0 和 1（out_car[0] 结构恒 0，豁免——CSA4to2 的
  最低进位位是常数 0）；out_sum[1] 同样结构恒 0（末级 4:2 的 bit0 进位 = in_d[0] 或 cin，两者都是
  上一级进位输出的最低位 = 0）。
时钟：dual_tb_lib 的 clocked pair 要求有 reset 端口，本模块没有，所以按非时钟 pair 生成，
  clock 端口自己驱动：每个 negedge（灌激励时）拉低，tb 时钟的 posedge 拉高 —— 与 tb 时钟同相，
  比较点（negedge 后 4ns）仍在下一个上升沿之前。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
always @(posedge clk) tb.csa_clock = 1'b1;   // 本模块无 reset 端口，时钟自己驱动（见 gen.py 文件头）
function automatic logic [106:0] csa_rnd(input int unsigned mode);
  logic [106:0] v;
  v = {$urandom, $urandom, $urandom, $urandom};
  case (mode % 4)
    0: ;                                                    // 全随机
    1: v = v & {$urandom, $urandom, $urandom, $urandom}
             & {$urandom, $urandom, $urandom, $urandom};    // 稀疏
    2: v = ($urandom_range(0, 3) == 0) ? '1 : v;            // 常有全 1
    default: v = v | ({107{1'b1}} << $urandom_range(20, 106)); // 高位补 1（Booth 形状）
  endcase
  return v;
endfunction
"""

STIM = "@clock = 1'b0;\n@io_fire = ($urandom_range(0, 3) != 0);\n" + "".join(
    "@io_in_%d = csa_rnd(csa_mode);\n" % i for i in range(27))

COV = [("fire_hi", "@io_fire"), ("fire_lo", "!@io_fire")]

PAIRS = [
    Pair("CSA_Nto2With3to2MainPipeline", "csa_", clocked=False, stim=STIM, decls=DECLS, cov=COV,
         exempt=["io_out_car[0]", "io_out_sum[1]"], arm=["@io_fire"], mode_period=500, cov_min=1000),
]

HEADER = """自动生成：verif/ut/CSA_Nto2With3to2MainPipeline/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
CSA_Nto2With3to2MainPipeline 双例化逐拍比对：golden vs 重写 CSA_Nto2With3to2MainPipeline_xs。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
