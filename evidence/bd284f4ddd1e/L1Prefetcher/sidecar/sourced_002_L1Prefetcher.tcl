# vmucp 白名单条目：L1Prefetcher
#
# 本文件 = L1Prefetcher 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-03，agent/fe-mem-misc）----
#   L1Prefetcher 本层只有接线与少量组合逻辑，5 个子模块两侧白盒。关 vmucp 的 lane 内诊断跑
#   （make fm-L1Prefetcher，merge_dup 关，未出证）：native SUCCEEDED，passing 8078 / failing 0 /
#   unmatched compare 0 / Constant reg 60，unread 两类，全部是两侧对称的死位：
#   (a) matched_nc 558 位（FM 按名配上）：
#       pf_queue_filter 202 —— 与 MutiLevelPrefetchFilter 单独签核时的 vmucp 集合逐项相同
#           （REG..REG_5 性能计数打拍 112 + s1_l1/l2_region 80 + s3_tlb_resp_paddr_0[9:0] 10）；
#       stream_bit_vec_array 354 —— 子模块自身的死位（array_k_tag 高 15 位 ×16 = 240、
#           s2_pf_l{1,2,3}_incr_vaddr 低 6 位 18、REG/r/r_1 6）+ 父级新增的死位：stream_lookup_resp
#           在本配置下 StrideMetaArray 不读（golden 同样悬空），于是 stream 表的整条查询流水
#           s1_lookup_tag 40 / s2_region_tag 40 / s1..s3_lookup_* 等在父级零扇出；
#       stride_meta_array 2 —— s2_vaddr 低位（与子模块单独签核时同一集合）。
#   (b) 未配上的 453 位（零扇出、名字不同）：两个训练滤波器重排序流水与 FIFO 里 pc / vaddr 中
#       下游不读的位（stride pc 15 个寄存器 × 25 位、stream vaddr 13 个寄存器 × 6 位）。
#       由 scripts/gen_l1prefetcher_pins.py 生成的 verif/ut/L1Prefetcher/fm_pins_pre.tcl 按规则逐位钉
#       （每个寄存器 50 位整体钉，共 1400 条，fail-closed）。
#   Constant reg 60：子模块里每份 RegNext(io.flush)（flush 在本配置恒 0）——MLPF REG_6..REG_37 32 位等，
#       两侧同构，与各子模块单独签核时同一类别。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上面 (a) 558 位 ∪ (b) 453 位 = 1011 位。
#   (2) 双射：1011 ref <-> 1011 impl；(a) 按名配上，(b) 由钉点配上（钉点总数字面 1400+1692+1，拒一条即 error）。
#   (3) 真比较：开 vmucp 后 passing 应为 8078 + 1011 = 9089 = fm_predict 模型 9149 − Constant reg 60。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件与两个钉点文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
