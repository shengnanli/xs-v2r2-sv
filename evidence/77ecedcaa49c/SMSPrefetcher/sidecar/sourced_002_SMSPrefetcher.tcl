# vmucp 白名单条目：SMSPrefetcher
#
# 本文件 = SMSPrefetcher 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/sms-exublock1 lane）----
#   lane 内 diagnostic-full 诊断跑（关 vmucp、merge_dup 关、带 fm_pins_pre.tcl 前两节 3188 条钉点，未出证，
#   commit c539eab5e）：native SUCCEEDED、passing 7612、failing 0、unmatched compare 0，unread 共 1107 位：
#   (A) matched-unread 308 位 —— FM 自己配上、只是无读者：
#       · 本层 train_s0_pc 50 位：只有 [9:0] 送 StridePF（对外不可见），整组无读者；
#       · 继承自 child 签核时已入白名单的对称死位 258 位：StridePF 全部 220 位（本配置无输出口）、
#         PHT s3_region_vaddr[39:21] 19 位、PrefetchFilter s3_tlb_resp_paddr_0[9:0] 10 位、
#         SMSTrainFilter enqPtrExt_3/4 8 位、AGT s2_do_dcache_evict_last_REG 1 位；
#   (B) unmatched-unread 799 位（两侧各 799）—— SMSTrainFilter 进了本层才变死的位：pc[0]、pc[49:20]、
#       paddr[9:0]、vaddr[5:0] × (3 级重排 × 3 路 + 8 表项)。本层只读 pc[6:1]/pc[19:7]、paddr[47:10]、
#       vaddr[49:6]（pc[9:0] 另送已死的 StridePF）。无扇出签名，FM 配不上；由
#       verif/ut/SMSPrefetcher/fm_pins_pre.tcl 第 (c) 节按语义整组钉成对（scripts/gen_sms.py TF_DEAD /
#       TF_STAGES，字面 799，fail-closed；钉点集合与诊断跑的 unmatched unread 集合逐条比对两侧均精确相等）。
#   两类都是两侧结构相同的死位：golden 与重写核同名 / 同级 / 同项寄存器，同一死因。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上面 (A) 308 + (B) 799 = 1107 位，无其它。
#   (2) 双射：(A) FM 按名/签名配对；(B) 由钉点一对一（生成器断言 impl 侧单射）；ref 侧 = impl 侧 = 1107。
#   (3) 真比较：开 vmucp 后 passing 应为 7612 + 1107 = 8719 = 跑前登记的模型值（regs 8181 + outs 380 + 黑盒输入 158）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/SMSPrefetcher.json
#       声明的厂商宏叶子 array_12_ext（两侧各 1，vendor_macro，与 PatternHistoryTable 签核同一处置）。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
