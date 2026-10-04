#!/usr/bin/env python3
"""生成 RAS 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden RAS（+ golden RASStack）vs RAS_xs（+ 重写 RASStack_xs），全部 236 个输出逐拍逐位比较。
激励偏置（让栈真的被推、弹、取消、回滚、提交）：
  * s2 / s3 的第 2 份预测 3/4 时间造成"命中、分支槽没跳、尾槽是 taken 的跳转、不共享"的形状，
    is_call / is_ret / is_jalr 随机 ⇒ hit_taken_on_call / _ret 大量出现；s3 的 fallThroughErr 1/8；
  * s2 与 s3 的 call/ret 各自独立抽 ⇒ s3 与 s2 不一致（cancel + missed push/pop）常发生；
  * s0/s1/s2/s3 fire 各约 1/2，s3_redirect 1/8，ctrl.ras_enable 15/16；
  * redirect 1/16（快照字段随机，level / pd 各位随机）；update 1/4，3/4 时间是"尾槽跳转"形状、
    cfi_idx 一半等于尾槽 offset ⇒ commit push / pop 都走到；
  * s0_pc 的高 / 中段 3/4 时间取自 4 个固定值 ⇒ 分段地址寄存器"段不变就不写"的分支两边都走。
不复位的寄存器（s1_pc 由复位后第一拍装 reset_vector；s3 快照、redirect / update 锁存值、栈的写旁路项）
在 s2_fire(2) / redirect / update 各至少出现过一次之后再比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

P = "io_in_bits_resp_in_0_"

DECLS = """
logic [25:0] r_hi_pool [4];
logic [11:0] r_mid_pool [4];
initial for (int i = 0; i < 4; i++) begin r_hi_pool[i] = 26'($urandom); r_mid_pool[i] = 12'($urandom); end
"""

stim = []
for d in range(4):
    stim.append("if ($urandom_range(0, 3) != 0) begin @io_in_bits_s0_pc_%d[49:24] = r_hi_pool[$urandom_range(0, 3)]; "
                "@io_in_bits_s0_pc_%d[23:12] = r_mid_pool[$urandom_range(0, 3)]; end" % (d, d))
for s in ("s2", "s3"):
    f = P + s + "_full_pred_2_"
    stim += [
        "if ($urandom_range(0, 3) != 0) begin   // %s：尾槽 taken 跳转的形状" % s,
        "  @%shit = 1'b1;" % f,
        "  @%sslot_valids_1 = 1'b1;" % f,
        "  @%sis_br_sharing = 1'b0;" % f,
        "  @%sbr_taken_mask_0 = ($urandom_range(0, 3) == 0);" % f,
        "end",
    ]
stim += [
    "@%ss3_full_pred_2_fallThroughErr = ($urandom_range(0, 7) == 0);" % P,
    "@io_ctrl_ras_enable = ($urandom_range(0, 15) != 0);",
    "@io_s3_redirect_2 = ($urandom_range(0, 7) == 0);",
    "@io_redirect_valid = ($urandom_range(0, 15) == 0);",
    "@io_update_valid = ($urandom_range(0, 3) == 0);",
    "if ($urandom_range(0, 3) != 0) begin",
    "  @io_update_bits_ftb_entry_tailSlot_valid = 1'b1;",
    "  @io_update_bits_jmp_taken = 1'b1;",
    "  @io_update_bits_cfi_idx_valid = 1'b1;",
    "  if ($urandom_range(0, 1)) @io_update_bits_cfi_idx_bits = @io_update_bits_ftb_entry_tailSlot_offset;",
    "end",
]

COV = [
    ("spec_push", "r_u_gold.s2_spec_push"),
    ("spec_pop", "r_u_gold.s2_spec_pop"),
    ("s3_cancel", "r_u_gold.s3_cancel_probe"),
    ("near_overflow", "r_u_gold._RASStack_io_spec_near_overflow"),
    ("redirect_call", "r_u_gold.RASStack.io_redirect_valid && r_u_gold.RASStack.io_redirect_isCall"),
    ("redirect_ret", "r_u_gold.RASStack.io_redirect_valid && r_u_gold.RASStack.io_redirect_isRet"),
    ("commit_push", "r_u_gold.RASStack.io_commit_push_valid"),
    ("commit_pop", "r_u_gold.RASStack.io_commit_pop_valid"),
    ("s2_ret_target", "@%ss2_full_pred_2_is_ret && @io_ctrl_ras_enable" % P),
    ("s2_seg_hold", "@io_s1_fire_0 && r_u_gold.s2_pc_dup_s2_pc_seg_0_value == r_u_gold.s1_pc_dup_0[49:24]"),
    ("reset_mid", "@reset && cyc > 100"),
]

PAIRS = [Pair("RAS", "r_", clocked=True, stim="\n".join(stim), cov=COV, decls=DECLS,
              reset_period=2000, cov_min=20,
              # last_stage_meta 只有低 10 位有内容，高 506 位恒 0
              exempt=["io_out_last_stage_meta[%d]" % b for b in range(10, 516)],
              arm=["@io_s2_fire_2", "@io_redirect_valid", "@io_update_valid"], arm_delay=2)]

HEADER = """自动生成：verif/ut/RASTop/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
RAS 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
