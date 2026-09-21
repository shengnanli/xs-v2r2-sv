# vmucp 白名单条目：EntriesStdMoud
#
# 本文件 = EntriesStdMoud 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-21 加；六条证据由 verif/ut/Entries_common/vmucp_evidence.py
#      在**加强前**一次采齐，复跑：python3 vmucp_evidence.py EntriesStdMoud）----
#   [1] 两类分开：matched_nc 3160 个；unmatched unread ref=0 impl=0（合计 0）。
#       ★ vmucp 只作用于 matched 的点；unmatched unread 非 0 时单开 vmucp 必然空转，
#         所以顺序是"先配对(钉点) 后加强"。本变体钉点在先，unmatched 本就全零。
#   [2] 双射：ref 侧 3160 / impl 侧 3160 / 对数 3160 —— 严格 1:1。
#       构成 = enqEntries_N × 1580 + othersEntriesSimp_N × 1580（条目内的死负载位）。
#   [3] 配对方式：3160/3160 **全部**来自钉点文件，FM 自行猜配 0 对。
#       钉点共 12108 对，由 verif/ut/Entries_common/gen_fm_pins.py 从 golden 实例连线
#       机械提取（不是人工列表）；matched_nc 是它的子集 —— 故无一对是人工强配
#       或 FM 名字启发式的产物。
#       ★不拿钉点循环自报的 "0 threw" 当证据★：set_user_match 对不存在的名字
#         fail-open，只有上面这条子集判定才说明钉点真生效。
#   [4] fail-closed：行首锚定 "^ *Error:" 计数 0；unmatched 六项
#       (compare/unread/bbout × ref/impl) 全零。
#   [5] 期望值（★事前写死，不是事后对着结果凑★）：
#         passing 10879 -> 14039（恰好 +3160）、failing 仍 0、unread_notcompared 3160 -> 0、
#         unmatched 保持全零。**passing 不增即 FM 没真去比 = 空转，按 fail 处理。**
#   [6] qualifications：dont_verify=0 / elab147=0 / relaxed_appvars=0 三项全空；
#       matched_blackbox_pairs=0，unresolved_bb ref/impl=0/0；本轮 native=SUCCEEDED、
#       merge_dup=false。本条不加黑盒、不放宽任何 appvar。
#
#   同族先例：EntriesAluCsrFenceDiv（+6220）与另外 8 个 Entries* 变体走的是同一条路；
#   本条的数字全部是本目标自己实测的，没有从同族外推。

fm_target_vmucp_allow
