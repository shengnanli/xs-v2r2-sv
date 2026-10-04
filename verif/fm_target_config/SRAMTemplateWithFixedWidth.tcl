# vmucp 白名单条目：SRAMTemplateWithFixedWidth
#
# 本文件 = SRAMTemplateWithFixedWidth 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-03，agent/fe-mem-misc）----
#   关 vmucp 的 lane 内诊断跑（make fm-SRAMTemplateWithFixedWidth，未出证）：native SUCCEEDED，passing 350 / failing 0 /
#   unmatched compare 0，unread 两侧各 1 个**未配上**（零扇出点不做签名分析、名字不同）：
#     ref  r:/WORK/SRAMTemplateWithFixedWidth/srams_0/rdata_hold_data_0_reg[65]
#     impl i:/WORK/SRAMTemplateWithFixedWidth/srams_0/u_core/rdata_hold_reg[65]
#   成因：本层把 65 位数据零扩展成 66 位写进单块 SRAM、读回截掉最高位；内层 SRAMTemplate_4（holdRead）的
#   读保持寄存器照存 66 位，最高位没有读者。golden 与重写件同一结构、同一死位。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {srams_0 读保持寄存器 [65]}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl，由 verif/ut/SRAMTemplateWithFixedWidth/fm_pins.tcl 钉成一对（字面 1，fail-closed）。
#   (3) 真比较：开 vmucp 后 passing 应为 350 + 1 = 351 = fm_predict 模型。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/SRAMTemplateWithFixedWidth.json
#       声明的厂商宏叶子 array_0_ext（两侧各 1，vendor_macro）。
#   (6) 摘要：本文件与 fm_pins.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
