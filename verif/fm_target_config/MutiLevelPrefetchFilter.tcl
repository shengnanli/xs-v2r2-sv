# vmucp 白名单条目：MutiLevelPrefetchFilter
#
# 本文件 = MutiLevelPrefetchFilter 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-09-28，agent/mlpf lane) ----
#   关 vmucp 的诊断跑(diagnostic-full，不出证)：native SUCCEEDED passing 4054 / failing 0 /
#   unmatched compare 0，unread 202 = matched_nc 201 + 两侧各 1 个未配对(REG_reg / REG_0_reg，
#   由 verif/ut/MutiLevelPrefetchFilter/fm_pins.tcl 钉成一对)。这 202 对全部是两侧对称的死位，
#   分三族，全部由 golden 自身结构决定、重写核逐一照抄：
#     (a) 性能计数器打拍 112 位：REG(1)/REG_1(40)/REG_2(15) = RegNext(s1_l1_valid/region/region_hash)，
#         REG_3/REG_4/REG_5 同构于 L2 表 —— 喂 l1/l2_hash_conflict XSPerfAccumulate，综合口径下计数器被删；
#     (b) s1_l1_region / s1_l2_region 各 40 位：RegEnable(req.region)，唯一读者是 (a) 的 REG_1/REG_4
#         （写表用的是值恒等的另一份 s1_l*_prefetch_req_region）；
#     (c) s3_tlb_resp_paddr_0[9:0] 10 位：回填只取 paddr[47:10] 作物理 region，低 10 位无读者。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面三族恰好 202 位(112 + 80 + 10)。
#   (2) 双射：202 ref <-> 202 impl，201 对按名配上，1 对由 fm_pins.tcl 钉(期望值字面 1，fail-closed)。
#   (3) 真比较：开 vmucp 后 passing 应为 4054 + 202 = 4256 = 模型 4288 - constant_reg 32
#       (32 = REG_6..REG_37，每项一份 RegNext(io.flush)，flush 在本配置恒 0)。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；4 个仲裁器两侧白盒，无黑盒。
#   (6) 摘要：本文件与 fm_pins.tcl 都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
