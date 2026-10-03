# vmucp 白名单条目：StridePF
#
# 本文件 = StridePF 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/l1prefetch-tables lane) ----
#   本配置下 golden StridePF **没有任何输出端口**（SMSPrefetcher 把 stride_en 接 0、s2_gen_req 未接，
#   firtool 把整条预取生成通路连同 vaddr/paddr/stride_en 端口裁掉），只剩 220 位寄存器
#   （去抖 prev_valid/prev_pc、valids×16、entries_pc×16×10、s1 打拍×2、s1_match_vec×16、PLRU 15 位）。
#   首跑(evidence/c30ff0182ac6/StridePF)：0 比较点，220 位全为 unread（10 matched_nc + 210 unmatched），
#   sidecar 报 nonfinal_verification_status —— 不开 vmucp 时这个目标的证明是**空的**。
#   开 vmucp + verif/ut/StridePF/fm_pins_pre.tcl（scripts/gen_stridepf_pins.py 生成，210 位，fail-closed）
#   让 FM 逐个比较全部 220 个寄存器的次态函数：这是本目标唯一非空的等价判据。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = golden 全部 220 位寄存器（golden 无输出，无其它比较点）。
#   (2) 双射：10 位 prev_pc 按名配上；210 位由 fm_pins_pre.tcl 逐位钉（生成器断言单射、
#       期望字面 210，运行期逐条数返回值）。
#   (3) 真比较：开 vmucp 后 passing 应为 0 + 220 = 220 = 模型 220（outs 0）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；PLRU 是 rtl/common/xs_PlruReplacer
#       白盒例化（golden 内联），无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
