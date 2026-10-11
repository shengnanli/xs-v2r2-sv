# vmucp 白名单条目：MEFreeList
#
# 本文件 = MEFreeList 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-09-27，agent/rename lane) ----
#   golden MEFreeList 在 backendParams.debugEn=true 下带 530 位 debug 影子寄存器：
#     debugArchHeadPtr_REG_{flag,value}  9 位   = RegNext(archHeadPtr, 0)
#     debugArchHeadPtr_{flag,value}      9 位   = RegNext(上一级, 0)
#     debugArchRAT_REG_0..31             256 位 = RegNext(io_debug_rat, 0)
#     debugArchRAT_0..31                 256 位 = RegNext(上一级, 0)
#   它们唯一的读者是 XSError("Integer physical register should be in either arch RAT
#   or arch free list")，综合口径(`define SYNTHESIS，FM 两侧同口径)下断言不存在，
#   于是整条链没有任何可观测扇出 —— golden 侧是死位。
#   重写核(rtl/backend/MEFreeList.sv 第 9 节)按同名、同宽、同源、同复位复刻它们，
#   两侧对称；配对靠 scripts/fm_eq.tcl 的 auto_match_flattened_arrays 结构性规则
#   (debugArchRAT_REG_9_reg[7] <-> u_core/debugArchRAT_REG_reg[9][7]；指针拆成
#   _flag/_value 标量与 golden 展平名同形)，不是人工强配，无 fm_pins。
#   ★为什么不能删★：删掉就是 golden-only 死位，signoff-strict 直接 PARTIAL；
#   ★为什么要 vmucp★：关 vmucp 时它们是 530 个 matched-unread-not-compared 点，
#   strict 口径任何 unread 都判 PARTIAL；开 vmucp 让 FM 多证这 530 个点。
#
# ---- 六条证据(两轮实测都在 lane 内同一份字节上跑；正式数字以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 4 族恰好 530 位，逐位来自 golden `reg` 声明
#       (9+9+32×8+32×8)，fm_work/MEFreeList/unread_points.txt 逐行可核。
#   (2) 双射配对：530 ref <-> 530 impl 全部 matched_nc，ref 侧独占 0、impl 侧独占 0。
#   (3) 真比较：passing 2186(关 vmucp 基线) -> 2716(开 vmucp)，正好 +530；不增即空转。
#   (4) 全零：failing 0 / unverified 0 / aborted 0 / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；
#       hdlin_unresolved_modules=black_box 下 report_black_boxes 为 FM-249 No black boxes。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：下次复跑就看 passing 正好 2716、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
