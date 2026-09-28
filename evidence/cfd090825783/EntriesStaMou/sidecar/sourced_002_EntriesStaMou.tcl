# vmucp 白名单条目：EntriesStaMou
#
# 本文件 = EntriesStaMou 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-28 加，agent/entries-mem；六条证据由
#      verif/ut/Entries_common/vmucp_evidence.py 在**加强前**一次采齐，
#      加强前那一跑的 receipt：evidence/8c789148b150/EntriesStaMou/receipt.json，
#      复跑：python3 verif/ut/Entries_common/vmucp_evidence.py EntriesStaMou）----
#   [1] 两类分开：matched_nc 3076 个；unmatched unread ref=0 impl=0（合计 0）。
#       钉点在先，unmatched 本就全零，所以加强不会空转在 unmatched 上。
#   [2] 双射：ref 侧 3076 / impl 侧 3076 / 对数 3076 —— 严格 1:1。
#       构成 = enqEntries_N × 1538 + othersEntriesSimp_N × 1538（条目内只为
#       转移包存、本变体发射口看不见的死负载位；跑前登记 docs/lanes/entries_mem_prereg.md
#       按 (n_enq+n_simp)×(PL_TRANS_W−PL_DEQ_W) 预测，实测多 4，与同子族 Ldu 同形）。
#   [3] 配对方式：3076/3076 **全部**来自钉点文件，FM 自行猜配 0 对。
#       钉点共 12360 对，由 verif/ut/Entries_common/gen_fm_pins.py 从 golden 寄存器
#       声明与实例连线机械提取（不是人工列表）；matched_nc 是它的子集。
#       ★不拿钉点循环自报的计数当证据★：只有上面这条子集判定才说明钉点真生效。
#   [4] fail-closed：行首锚定 "^ *Error:" 计数 0；unmatched 六项
#       (compare/unread/bbout × ref/impl) 全零。
#   [5] 期望值（★事前写死，不是事后对着结果凑★）：
#         passing 11440 -> 14516（恰好 +3076）、failing 仍 0、
#         unread_notcompared 3076 -> 0、unmatched 保持全零。
#         且 14516 + constant_reg 14 = fm_predict 模型 14530（登记在先）。
#         **passing 不增即 FM 没真去比 = 空转，按 fail 处理。**
#   [6] qualifications：dont_verify=0 / elab147=0 / relaxed_appvars=0 三项全空；
#       matched_blackbox_pairs=0，unresolved_bb ref/impl=0/0；加强前 native=SUCCEEDED、
#       merge_dup=false。本条不加黑盒、不放宽任何 appvar。
#
#   同族先例：EntriesLdu / EntriesStdMoud 与另外 9 个 Entries* 变体走的是同一条路；
#   本条的数字全部是本目标自己实测的，没有从同族外推。

fm_target_vmucp_allow
