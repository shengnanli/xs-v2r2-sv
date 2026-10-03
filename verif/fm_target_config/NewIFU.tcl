# vmucp 白名单条目：NewIFU（取指单元）
#
# 本文件 = NewIFU 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-02，agent/newifu-ptwfilter lane；跑前登记，未做任何 FM 试跑）----
#   golden 在综合口径（SYNTHESIS，XSError / XSPerfAccumulate 被关）下有 5 族没有读者的寄存器位，
#   重写核逐个照留（rtl/frontend/NewIFU.sv 文件头「怪癖」一节），两侧同为死位、同一死因：
#     (a) f3_pd_wire_<i>_{brType,isCall,isRet}   16 × 4 = 64 位
#         f2 PreDecode 的分支信息打拍；f3 用 F3Predecoder 重算的那份，寄存的这份只喂 XSError 一致性断言。
#     (b) f3_perf_info_{hit_0_except_1,miss_0_except_1,except_0} 3 位 + bank_hit_0 1 位 = 4 位
#         只喂 XSPerfAccumulate / ChiselDB。
#     (c) f2_cut_ptr_<i>[6]                      17 位
#         7 位指针取数时只用 [5:0]（_GEN_14[f2_cut_ptr_i[5:0]]）。
#     (d) f3_jump_offset_<i>[63:50]              16 × 14 = 224 位
#         64 位偏移进 PredChecker 后只用 [49:0]（pc + jumpOffset[49:0]）。
#     (e) frontendTrigger/tdataVec_<j>_tdata2[63:50]  4 × 14 = 56 位（见 FrontendTrigger.tcl）
#   合计 365 位。配对全部来自 verif/ut/NewIFU/fm_pins_pre.tcl 的机械钉点（6113 位同一套规则），
#   不是为这些位单独人工强配。
#   注：其中 (c) 里若干位（{2'b0, x[4:0]} + i 的进位位恒 0）FM 可能判成 Constant reg 而不是 unread ——
#   那样它们不产生比较点，从 unread 挪到 constant_reg，合计不变（fm_predict check 按两者之和对账）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 ⊆ 上面 5 族；unread + 落在这 5 族里的 constant_reg = 365。
#   (2) 双射：全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing = 登记模型值 9251 减去 constant_reg（docs/fm_predictions/NewIFU.json）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
