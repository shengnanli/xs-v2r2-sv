# vmucp 白名单条目：Directory
#
# 本文件 = Directory 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/l2slice lane，commit f6806ac5 上的正式跑，vmucp 关）----
#   证据：evidence/f6806ac59aae/Directory（assembly，allow 精确相等：array_14_ext x4 + array_15/16/17_ext 各 1，x2 侧）
#   passing 1926 / failing 0 / unverified 0 / unmatched 0(0)，unread 27 -> 判 PARTIAL(assembly_unread!=0)。
#   与跑前登记（docs/lanes/l2slice_prereg.md 7.4 第二跑：unread 27 全 matched_nc）逐位相等。
#   27 个 unread 点全是 matched_nc（两侧独占 0），逐类：
#     r:req_s2_wayMask_reg[b] / req_s3_wayMask_reg[b]  <-> i:u_core/同名_reg[b]            b in 0..7（16）
#     r:mbistPl/addrReg_reg[b]                         <-> i:mbistPl/u_core/u_ctrl/addrReg_reg[b]    b in 0..9（10）
#     r:mbistPl/addrRdReg_reg[9]                       <-> i:mbistPl/u_core/u_ctrl/addrRdReg_reg[9]            （1）
#   为什么是对称死位：
#     wayMask：DirRead.wayMask 在 Scala 里只被 XSPerf("choose_busy_way") 读（选路那段用 wayMask 的代码被注释掉），
#       综合网表里 s2/s3 两级寄存器仍在但没有读者；重写照 golden 保留。
#     mbistPl 地址位：MBIST 叶子送给 tag/meta/repl/orgb 四类 SRAMTemplate 的 bore 口不用这些位，父层语境下无读者；
#       叶子单独签核时它们是被读的。
#   配对：由 verif/ut/Directory/fm_pins_pre.tcl 按名钉（11 位，只对 slice 0：旧手写件 L2Directory 多一层 u_ctrl）；其余 FM 按名自动配。
#   另：本目录 FM_MERGE_DUP 取默认 true（共享 SRAM 核的 rdata_last_REG 靠 merge 合并，见 Makefile 注释）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上表 27 位。
#   (2) 双射：27 ref <-> 27 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 1926 -> 1953，正好 +27；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒集合与 allow 精确相等，无新黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 1953、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
