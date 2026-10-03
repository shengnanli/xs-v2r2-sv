#!/usr/bin/env python3
"""生成 SRT16DividerDataModule 的双例化 UT testbench（tb.sv）。

golden SRT16DividerDataModule vs 重写 SRT16DividerDataModule_xs（scripts/dual_tb_lib.py，
端口表读 G1 golden），每拍全部输出逐位 !==；子模块 CSA3_2_* / RightShifter 两侧各自用
golden / 重写件（重写侧经 derive 改名 _xs）。
激励：
  * 握手：in_valid 3/4，out_ready 1/2，kill_w 1/16，kill_r 1/200（在飞请求被冲掉，回 idle）；
  * 操作数按 mode 切换：全随机 64 位 / 16 位以内小数（迭代次数少）/ 除数取 0、1、-1
    （special 路径）/ 被除数取 INT64_MIN、除数 -1（溢出）/ 32 位符号扩展值（W 指令）/
    被除数小于除数（aTooSmall）/ 整除（余数 0，含负被除数——needCorr 与右移补位的 r==0 分支）；sign / isHi / isW 每拍随机。
不复位寄存器：rFinal / qFinal 在第一次走到 s_post_1 之前两侧初值不同，而 out_data 不看
out_valid 直接由它们组合出 ⇒ arm = golden 第一次进入 s_post_1，之后再等 1 拍开比。
覆盖：special 路径、迭代路径、kill_r 打断、needCorr 修正、奇 / 偶迭代步、isHi、isW。
用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

G = "sd_u_gold."
STIM = """
@io_valid = ($urandom_range(0, 3) != 0);
@io_out_ready = $urandom_range(0, 1);
@io_kill_w = ($urandom_range(0, 15) == 0);
@io_kill_r = ($urandom_range(0, 199) == 0);
case (@mode % 8)
  0: ;                                                         // 全随机
  1: begin @io_src_0 = 64'($urandom_range(0, 65535)); @io_src_1 = 64'($urandom_range(1, 300)); end
  2: begin
    case ($urandom_range(0, 2))
      0: @io_src_1 = 64'd0;
      1: @io_src_1 = 64'd1;
      default: @io_src_1 = '1;
    endcase
  end
  3: begin @io_src_0 = 64'h8000_0000_0000_0000; @io_src_1 = '1; end
  4: begin @io_src_0 = 64'($signed(32'($urandom))); @io_src_1 = 64'($signed(32'($urandom) >>> $urandom_range(0, 30))); end
  5: begin @io_src_0 = 64'($urandom_range(0, 1000)); @io_src_1 = {$urandom, $urandom}; end
  6: begin @io_src_0 = {$urandom, $urandom}; @io_src_1 = {$urandom, $urandom} >> $urandom_range(0, 63); end
  default: begin                                               // 整除：余数为 0（含负被除数）
    @io_src_1 = 64'($urandom_range(1, 1 << 20));
    @io_src_0 = @io_src_1 * 64'($urandom_range(0, 1 << 30));
    if ($urandom_range(0, 1)) @io_src_0 = -@io_src_0;
    if ($urandom_range(0, 3) == 0) @io_src_1 = -@io_src_1;
  end
endcase
"""
COV = [
    ("special", G + "state[2] && " + G + "special"),
    ("iter", G + "state[3]"),
    ("kill_inflight", "@io_kill_r && !" + G + "state[0]"),
    ("need_corr", G + "state[5] && !" + G + "specialReg && " + G + "needCorr"),
    ("finish_hi", "@io_out_valid && @io_out_ready && @io_isHi"),
    ("finish_w", "@io_out_valid && @io_out_ready && @io_isW"),
    ("d_zero", G + "state[2] && " + G + "dIsZero"),
]

PAIRS = [
    Pair("SRT16DividerDataModule", "sd_", clocked=True, stim=STIM, cov=COV, mode_period=700,
         reset_period=60000, cov_min=200, arm=[G + "state[5]"], arm_delay=1),
]

HEADER = """自动生成：verif/ut/SRT16DividerDataModule/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
SRT16DividerDataModule 双例化逐拍比对：golden vs 重写 _xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
