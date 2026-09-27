# vmucp 白名单条目：Rename
#
# 本文件 = Rename 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-09-27，agent/rename lane) ----
#   Rename 整证把 5 个 FreeList 白盒展开。其中 intFreeList(MEFreeList)带 530 位只喂
#   XSError 的 debug 影子寄存器(debugArchHeadPtr 两级 9+9 位 + debugArchRAT 两级 32×8+32×8 位，
#   源头是 Rename 的 io_debug_int_rat_0..31 输入)，综合口径下两侧都是死位 —— 与
#   verif/fm_target_config/MEFreeList.tcl 是同一族点，只是层次多了一级 intFreeList/。
#   Rename 自身没有别的 unread 点(所有寄存器都有读者：perf 两级流水到输出、renameTime 到输出、
#   debugRedirect_* 进 stallReason、robIdxHead/lastCycleMisprediction/notInSameSnpt/
#   lastCycleCreateSnpt/freeReq_REG/freePhyReg_REG 都进主逻辑)。
#   配对靠 verif/ut/Rename/fm_pins.tcl(与 MEFreeList 的同一套叶名规则，期望值 530，fail-closed)，
#   不是人工强配。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 4 族恰好 530 位(9+9+256+256)。
#   (2) 双射：530 ref <-> 530 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing = 登记模型值(docs/fm_predictions/Rename.json)，比关 vmucp 基线多 530。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；FM-249 No black boxes。
#   (6) 摘要：本文件与 fm_pins.tcl 都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
