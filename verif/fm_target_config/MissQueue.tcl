# vmucp 白名单条目：MissQueue（DCache miss 队列：16 MSHR + CMOUnit + 流水寄存器 + 通道仲裁）
#
# 本文件 = MissQueue 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28, agent/missq lane 内 diagnostic-full 试跑，未出 receipt）----
# 首跑（vmucp 关、无钉点，Matching 后按自己 PID 停掉）：matched by name 20103 / by signature 8767 /
#   unmatched compare 159(149) / unmatched unread 3462(3472) / 无黑盒 / 无 dont_verify。
#   unread 的来源（两侧对称、同一死因，可读件照 golden 逐个保留）：
#   · 16 个 MissEntry 各 209 位只喂断言/性能计数的死寄存器（MissEntry 单独签核时同一批，
#     见 verif/fm_target_config/MissEntry.tcl）；
#   · CMOUnit req_address[63:48]（见 verif/fm_target_config/CMOUnit.tcl）；
#   · 顶层 REG（assert(RegNext(PopCount(secondary_ready_vec) <= 1 || !req.valid))）与
#     max_inflight[4:0]（XSPerfAccumulate）。
#   名字不同的由 verif/ut/MissQueue/fm_pins_pre.tcl（scripts/gen_missq.py 生成）逐项配对。
# vmucp 六条：精确绑定（配对表逐项写死、计数 fail-closed）/ 双射（全部一对一）/
#   FM 实比（加强后 passing 须恰好增加 unread 点数）/ 加强后 failing 须仍为 0 /
#   无 dont_verify、无新黑盒 / 摘要写在本文件与 docs/lanes/missq_prereg.md。

fm_target_vmucp_allow
