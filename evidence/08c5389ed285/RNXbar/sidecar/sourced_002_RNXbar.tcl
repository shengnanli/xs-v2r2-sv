# vmucp 白名单条目：RNXbar
#
# 本文件 = RNXbar 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# RNXbar / SNXbar 加入依据(2026-09-14, agent/arb)：strict 首跑均 native SUCCEEDED /
# failing 0 / unmatched 0，只剩 unread 卡住 —— RNXbar 3 点、SNXbar 2 点，**全部**
# matched_nc 且严格双射(ref 唯一点 ↔ impl 唯一点，非 matched_nc 项为 0)。
# 这些点全部落在 **golden 自己的** FastArbiter 变体内部(RNXbar: _43/_26/_45;
# SNXbar: _46/_45)，而这些 FastArbiter 由 RTL_GOLDEN_DEPS 两侧同源 elaborate ——
# ref 与 impl 读同一份 golden 文件、同一实例名，双射是结构性的而非人工强配。
# 死位本身是 FastArbiter 轮转仲裁的常量折叠：
#   rrGrantMask <= {|chosenOH[2:0], |chosenOH[1:0], chosenOH[0], 1'h0}  ← bit0 恒 0，
#   而 pendingMask[0] 的唯一读出点是 rrGrantMask[0] & pendingMask[0] ⇒ 无观测路径。
# 两侧同为死位，加强后 FM 实比这几个点，passing 增、failing 仍 0。

fm_target_vmucp_allow
