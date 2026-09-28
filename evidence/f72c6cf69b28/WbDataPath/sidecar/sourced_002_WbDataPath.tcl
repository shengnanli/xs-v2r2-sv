# vmucp 白名单条目：WbDataPath（写回数据通路，agent/wbbyp lane）
#
# 本文件 = WbDataPath 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/wbbyp，三次非正式试跑，均 FM_MODE=diagnostic-full、不产 receipt）----
#   试跑 1（commit 8afcd62f 字节，无钉点、vmucp 关）：native SUCCEEDED / failing 0 /
#     unmatched compare points 0(0)（Matching：20718 by name + 438 by signature），
#     但 Unmatched unread points = 3269(1904)（该次 fm.log 已被后续试跑覆盖，passing 未留存）：
#       ref 1365 = golden-only cone-dead（VfExu_0_1 写整数那一拍的整条 ExuOutput 锁存，
#                  impl 只锁被读的 73 位；逐位声明在 verif/dead_ref/WbDataPath.json，PASS_DEAD_REF）；
#       ref 1904 / impl 1904 = 两个 VldMergeUnit 实例里 wbReg 在 WbDataPath 中无读者的位
#                  （每实例 952 位：合并单元只把 valid/data_0/pdest/vecWen/v0Wen/vlWen 交给仲裁器，
#                   VldMgu 只读 vmask[15:0] 等 11 个字段；送 ROB 的 bits 取自 io 口原样）。
#       后者是**对称**死位（两侧同为 VldMergeUnit 的 wbReg，golden 逐字段、impl 为 packed struct），
#       但因无扇出，FM 签名分析配不上 —— 先要 fm_pins_pre.tcl 把它们配起来，vmucp 才不空转。
#   试跑 3（加钉点、vmucp 关 —— 加强前基线）：native SUCCEEDED / passing 21156 / Constant reg 2 /
#     unread: matched_nc 1904 + ref 1365。
#   试跑 2（加 verif/ut/WbDataPath/fm_pins_pre.tcl：2268 位 set_user_match 全部成功；vmucp 开）：
#     native SUCCEEDED / failing 0 / unmatched 0(0) / passing 23060 / Constant reg 2 /
#     Unmatched unread = 1365(0)（全为上面那 1365 个 golden-only 位）/ matched_nc 0。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：被加强的 matched-unread 点 = vldMgu_{0,1} 的 wbReg 中 952 位 × 2 = 1904，
#       由 fm_pins_pre.tcl（gen_wbdatapath.py 生成，字面计数 2268、fail-closed）逐位配对。
#   (2) 双射：1904 ref <-> 1904 impl，按字段名逐位一一对应（生成器单射断言），两侧独占 0。
#   (3) 真比较：同一套钉点下 vmucp 关 -> 开，passing 21156 -> 23060，正好 +1904
#       （试跑 3 vs 试跑 2；登记于 docs/lanes/wbbyp_prereg.md §3）。
#   (4) 全零：failing / unverified / aborted / unmatched compare points 全 0；
#       唯一残余是 1365 个 golden-only unread，走 PASS_DEAD_REF（声明与观测精确相等）。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒（全部子模块两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
