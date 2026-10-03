# vmucp 白名单条目：FAlu
#
# 本文件 = FAlu 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# FAlu / FCVT / MulUnit 加入依据(2026-09-14, PARTIAL 收口簇)：三者的共同形态是
# **未读点全部落在两侧同源 elaborate 的 golden 叶子里**——ref 与 impl 读的是
# G1-canonical 下同一份文件(FALU_LEAVES / FCVT_LEAVES / MUL_LEAVES 见各 UT
# Makefile)，因此 unread 的对称性是**按构造**成立的，不是人工配出来的：
#   FAlu  (strict native SUCCEEDED / passing 2462 / failing 0 / unmatched 0 /
#          unread 4)：4 点全 matched_nc，ref 4 ↔ impl 4，非 matched_nc 项为 0。
#          内容 = fudian 浮点加法器里被下游丢弃的最高/最低位：
#          F32Adder/F64Adder 的 U_close_path/U_CS4_io_adder_op0_r[23]/[52]
#          (ClosePathF32WidenF16MixedPipeline.sv:111 / ...F64Widen...:CS4 op0 的
#          MSB，加法器内部不取)、U_close_path/U_Lshift_io_src_r[24](同上，25 位
#          左移源的 MSB)、U_far_path/U_FS1/io_result_r_2[0]
#          (FarPathF32WidenF16MixedAdderPipeline.sv:97 拼接后被丢弃的 LSB)。
#   FCVT  (strict native SUCCEEDED / passing 2509 / failing 0 / unmatched 0 /
#          unread 5)：5 点全 matched_nc，ref 5 ↔ impl 5。内容 = FP_INCVT.sv:167
#          的 fcvtmodTrueExpReg[4:0]——该寄存器只有 [10:5] 被读(FP_INCVT.sv:600
#          `|(fcvtmodTrueExpReg[10:5])`)，低 5 位两侧同为死位。
#   MulUnit(strict + FM_MERGE_DUP=false, native SUCCEEDED / passing 4537 /
#          failing 0 / unmatched 0 / unread 7)：7 点全 matched_nc，ref 7 ↔ impl 7。
#          内容 = ArrayMulDataModule.sv 的部分积寄存器 r_2303/2304/2306/
#          2558/2559/2560/2561 —— 送进 C22/C53 压缩器后该位的进位/和被后级丢弃，
#          两侧同一份 golden 文件，同为死位。
# 三者打开后必须复验「passing 恰好 +4 / +5 / +7 且 failing 仍为 0」——
# passing 不增即说明 FM 没真去比，那是空转，不算过(见本轮证据 evidence/)。

# ---- 2026-10-03 fpaddpath-sqrtblock lane：far/close 子树 impl 改读重写件后 ----
# 上述同一组死位两侧名字不再相同（golden firtool 名 vs 重写核字段名），且无扇出签名 → FM 配不上（unmatched unread），
# vmucp 单开空转。由本目标 UT 目录的 fm_pins.tcl 字面钉 4 对（含恒 0 的 U_CS4_io_adder_op1_r_reg[23]，钉上后归回
# constant_reg），再交 vmucp 实比；判据仍是上面六条（passing 与上一版 receipt 相同、failing/unmatched 全 0）。

fm_target_vmucp_allow
