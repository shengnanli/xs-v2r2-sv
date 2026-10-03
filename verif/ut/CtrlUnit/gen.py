#!/usr/bin/env python3
"""生成 CtrlUnit 目录的双例化 UT testbench（tb.sv）。

两对（scripts/dual_tb_lib.py，端口表读 G1 golden）：
  Queue1_RegMapperInput_6  深度 1 队列；随机 enq/deq，覆盖 同拍进出/满/空。
  CtrlUnit                 DCache 伪错误注入控制器（子模块两侧白盒：golden 用 golden 件，
                           重写侧用本仓 Queue1_RegMapperInput_6 / NewPipelineConnectPipe_27）。
    激励：A 通道随机 Get/Put；index 偏向 0..9（2/3 概率），字节掩码 3/4 概率全 1；
    写 ctrl 时 ese 偏 1、comp/ede/persist/bank 随机；写 delay 时值偏小（0..15），
    使 counter 能减到 0 → 注入实际发生。
    覆盖：tag/data 两通道 fire、延迟递减、fire 后 counter 重装、各寄存器写、读、出口背压。
队列数据槽 / 出口打拍载荷不复位：+random 档两侧初值不同，用 arm 条件（各自被写过一次）之后才比。
auto_in_d_bits_opcode[3:1] 恒 0（{3'h0, read}），豁免 0/1 覆盖。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

Q_COV = [
    ("enq", "@io_enq_valid && @io_enq_ready"),
    ("deq", "@io_deq_valid && @io_deq_ready"),
    ("full_stall", "@io_deq_valid && !@io_deq_ready && @io_enq_valid"),
]

CU_STIM = """
if (@mode[0]) @auto_in_a_bits_opcode = ($urandom_range(0, 1) ? 4'h4 : 4'h0);
if ($urandom_range(0, 2) != 0) @auto_in_a_bits_address[6:3] = 4'($urandom_range(0, 9));
if ($urandom_range(0, 3) != 0) @auto_in_a_bits_mask = 8'hFF;
if (@auto_in_a_bits_address[6:3] == 4'd0) begin
  @auto_in_a_bits_data[0] = ($urandom_range(0, 3) != 0);      // ese
  if (@mode[1]) @auto_in_a_bits_data[2] = 1'b0;                // ede 关的阶段
end
if (@auto_in_a_bits_address[6:3] == 4'd1 && $urandom_range(0, 7) != 0)
  @auto_in_a_bits_data = 64'($urandom_range(0, 15));
if (@mode[3:2] == 2'd0) @auto_in_a_valid = ($urandom_range(0, 15) == 0);  // 少访问，让注入跑起来
"""

CU_COV = [
    ("fire_tag", "cu_u_gold._CtrlUnitPseudoErrorPipelineConnect0_io_in_ready && cu_u_gold.pseudoError_gen_0_valid"),
    ("fire_data", "cu_u_gold._CtrlUnitPseudoErrorPipelineConnect1_io_in_ready && cu_u_gold.pseudoError_gen_1_valid"),
    ("count_down", "cu_u_gold.ctrlRegs_0[0] && cu_u_gold.ctrlRegs_0[2] && (|cu_u_gold.counterRegs_0)"),
    ("reload_persist", "(cu_u_gold._GEN_0 || cu_u_gold._GEN_1) && cu_u_gold.ctrlRegs_0[1] && cu_u_gold.ctrlRegs_0[2]"),
    ("write_ctrl", "cu_u_gold._out_wofireMux_T_2 && cu_u_gold._out_back_q_io_deq_bits_index == 4'h0 && (&cu_u_gold.out_backMask)"),
    ("write_delay", "cu_u_gold._out_wofireMux_T_2 && cu_u_gold._out_back_q_io_deq_bits_index == 4'h1 && (&cu_u_gold.out_backMask)"),
    ("write_mask7", "cu_u_gold._out_wofireMux_T_2 && cu_u_gold._out_back_q_io_deq_bits_index == 4'h9 && (&cu_u_gold.out_backMask)"),
    ("write_partial", "cu_u_gold._out_wofireMux_T_2 && !(&cu_u_gold.out_backMask)"),
    ("read", "@auto_in_d_valid && @auto_in_d_ready && @auto_in_d_bits_opcode[0]"),
    ("out0_stall", "@io_pseudoError_0_valid && !@io_pseudoError_0_ready"),
    ("out1_stall", "@io_pseudoError_1_valid && !@io_pseudoError_1_ready"),
]

PAIRS = [
    Pair("Queue1_RegMapperInput_6", "q_", clocked=True, cov=Q_COV,
         reset_period=20000, cov_min=1000,
         arm=["@io_enq_valid && @io_enq_ready"]),
    # arm：队列数据槽、两级出口打拍的载荷寄存器都不复位，各自被写过一次之后两侧才一致
    Pair("CtrlUnit", "cu_", clocked=True, stim=CU_STIM, cov=CU_COV,
         mode_period=3000, reset_period=50000, cov_min=100,
         exempt=["auto_in_d_bits_opcode[1]", "auto_in_d_bits_opcode[2]", "auto_in_d_bits_opcode[3]"],
         arm=["@auto_in_a_valid && @auto_in_a_ready",
              "cu_u_gold._CtrlUnitPseudoErrorPipelineConnect0_io_in_ready && cu_u_gold.pseudoError_gen_0_valid",
              "cu_u_gold._CtrlUnitPseudoErrorPipelineConnect1_io_in_ready && cu_u_gold.pseudoError_gen_1_valid"]),
]

HEADER = """自动生成：verif/ut/CtrlUnit/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
CtrlUnit / Queue1_RegMapperInput_6 双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
