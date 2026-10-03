# vmucp 白名单条目：Slice_1（CoupledL2 tl2chi L2 slice 装配，agent/slice lane）
#
# 本文件 = Slice_1 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（agent/slice，诊断跑 diag3 = commit 39234527 + 钉点，merge_dup=false，vmucp 关）----
#   native SUCCEEDED：passing 60373 / failing 0 / unverified 0 / unmatched compare 0(0)，
#   Not Compared = Constant reg 1528 + Unread 7796（matched_nc，两侧都配上、都没人读）。
#   这些 unread 是各 child 单独签核时已登记的对称死位之并（MSHR validCnt/timer/*_ts、MSHRCtl timers、
#   FastArbiter pendingMask[0]、TXDAT/RXSNP 的 off[3:0] 等，见各 child 的 fm_target_config），
#   加上本层不读的 child 输出把其驱动锥变成死锥的那部分（golden 与重写件同名同宽保留，同一批没有读者的位）。
#   正式跑的精确集合、双射与 passing 增量以 evidence/ 下 receipt 与 docs/lanes/slice_prereg.md 对账为准。
#
# ---- 六条证据 ----
#   (1) 精确绑定：unread 点集合 = receipt 的 unread_points.txt（matched_nc）。
#   (2) 双射：matched_nc 两侧一一配对，两侧独占 0（钉点只消名差，见 verif/ut/Slice/fm_pins_pre.tcl）。
#   (3) 真比较：passing 恰 +unread 数（相对 vmucp 关的诊断跑）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；黑盒只有已审定的 array_*_ext 与 ram_10x89。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
