# vmucp 白名单条目：FrontendTrigger（前端取指断点触发器）
#
# 本文件 = FrontendTrigger 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-02，agent/newifu-ptwfilter lane；跑前登记，未做任何 FM 试跑）----
#   golden 的 tdataVec_<j>_tdata2 是 64 位寄存器（CSR tdata2 全宽写入），而比较只用 VAddrBits=50 位：
#   tdata2[49:5] 进高位比较器、tdata2[4:0] 进低位比较器，[63:50] 没有任何读者。4 个触发器 × 14 位 = 56 位。
#   重写核照抄 64 位（rtl/frontend/FrontendTrigger.sv 的 tdata_tdata2_q[j]，不收窄），是同一批死位、同一死因。
#   配对来自 verif/ut/FrontendTrigger/fm_pins_pre.tcl 的机械钉点（与其余 240 位同一条规则
#   tdataVec_<j>_<field> -> tdata_<field>_q[j]），不是为这 56 位单独人工强配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = tdata_tdata2_q[j][63:50]，j ∈ {0..3}，恰好 56 位。
#   (2) 双射：56 ref <-> 56 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing = 登记模型值 360 减去 constant_reg（docs/fm_predictions/FrontendTrigger.json；
#       预计 constant_reg = 4，即 4 个恒 0 的 timing 位），其中 56 来自本条。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
