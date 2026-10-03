# vmucp 白名单条目：FloatAdderF32WidenF16MixedPipeline
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（首跑 evidence/5a3282d30ab1/FloatAdderF32WidenF16MixedPipeline，impl commit 5a3282d3，vmucp 关）----
# signoff-strict native SUCCEEDED：passing 324 / failing 0 / unmatched 0 / 无黑盒 / 无 dont_verify，
# constant_reg 20，unread 3 → strict 判 PARTIAL(strict_unread!=0)。
# 3 个 unread 点全是 matched_nc（ref 3 ↔ impl 3，两侧独占 0），且全部落在**两侧同读的 golden 子树**里
# （UT Makefile 的 FPADD_GOLDEN_SUBTREE 同时进 RTL_GOLDEN_DEPS 与 FM_REF_DEPS），对称性按构造成立：
#   U_close_path/U_CS4_io_adder_op0_r_reg[23]   —— close path CS4 加法器 op0 的 MSB，加法器内部不取
#   U_close_path/U_Lshift_io_src_r_reg[24]      —— 25 位左移源的 MSB，不取
#   U_far_path/U_FS1/io_result_r_2_reg[0]       —— 拼接后被丢弃的 LSB
# 与 verif/fm_target_config/FAlu.tcl 记录的同三点同源（FAlu 的 F32Adder 例化的正是这两条路径）。
# 六条：精确绑定（恰这 3 点）/ 双射（3 ↔ 3 matched_nc）/ 真比较（passing 324 → 327，正好 +3）/
#   全零（failing / unverified / unmatched 0）/ 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 /
#   本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
