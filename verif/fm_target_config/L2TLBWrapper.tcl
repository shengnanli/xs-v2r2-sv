# vmucp 白名单条目：L2TLBWrapper
#
# 本文件 = L2TLBWrapper 这一个目标的 per-target 证明数据（契约见 README.md）。
#
# ---- 加入依据（2026-10-03，agent/l2tlb-assembly，本机实测）----
# 第 3 轮配置：ref golden L2TLBWrapper+L2TLB+child 闭包；impl 重写 L2TLBWrapper + 重写 L2TLB +
# 同一 golden child 闭包；黑盒仅 ram_40x47 1/1。关闭 vmucp 的读数（evidence/0f42e91463d9/L2TLBWrapper）：
# matched-unread **1288** 对，与 L2TLB 同一集合加前缀 ptw/（ref r:/WORK/L2TLBWrapper/ptw/、
# impl i:/WORK/L2TLBWrapper/ptw/u_core/），逐对核过全是双射：1144 对后缀逐字相同或 csr_dup 字段对应，
# 144 对为 verif/ut/L2TLBWrapper/fm_pins.tcl 的钉点。外壳自己的寄存器没有一个落在 unread 里。
# 预期打开后 passing 恰增 1288、unread 归零；出现 failing 即停下诊断，不得回填白名单绕过。
#
# ---- 第 4 轮更新（2026-10-11，agent/l2tlb-gc，codex 0228 exact green_child 组合）----
# ptw（L2TLB）两侧 -interface_only 黑盒后，本层只剩外壳 glue；canary（worktree，不产 receipt）vmucp 开：
# passing 5139 = fm_predict 模型 regs 228 + outs 3589 + 黑盒输入 1322 逐位相等，matched-unread 0、unread 0。
# 即 vmucp 在本轮没有可转化的点（保留开关只为不放宽；若将来出现 matched-unread，按 standing rule 六条重新核）。
fm_target_vmucp_allow
