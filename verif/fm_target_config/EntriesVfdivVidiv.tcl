# vmucp 白名单条目：EntriesVfdivVidiv
#
# 本文件 = EntriesVfdivVidiv 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   EntriesVfdivVidiv 加入依据(2026-09-14, PARTIAL 收口簇)：本目标的未读点不是
#          零星几个而是 2420 对 —— 发射队列条目的 uop 负载里，本变体**用不到**的
#          字段（debugInfo / exceptionVec / preDecodeInfo / pc / imm / instr /
#          ftqPtr / lqIdx / sqIdx … 共 110 个字段）只是随 uop 逐级传递，在
#          Entries 这一层没有任何输出锥。golden 把它们展平成逐字段寄存器
#          entryReg_payload_<f>_reg[b]，可读核存成一根向量 r_payload_reg[off+b]，
#          词干完全不同、又没有输出锥，FM 的名字匹配与签名分析都无从下手。
#          verif/ut/EntriesVfdivVidiv/fm_pins_pre.tcl（由 gen_fm_pins.py 从
#          gen.py 的同一张字段偏移表机械生成）在首次 match 之前逐位钉 9898 对，
#          实测 9898/9898 全部钉上、0 miss（钉不上即 error 退出，fail-closed）。
#          钉完的实测结果：native SUCCEEDED / passing 9776 / failing 0 /
#          unmatched compare points 0(0) / unmatched unread 0(0)，
#          剩下的 2420 点**全部** matched_nc，即 ref 2420 ↔ impl 2420 严格双射。
#          配套两项：FM_MERGE_DUP=false（否则 golden 侧的常数负载位被合并，
#          两侧点数根本对不齐）与可读核里删掉 golden 没有的死寄存器
#          （EnqEntry 无 blocked、comp 条目无 deqPortIdx，见 xs_iq_entries_core.sv
#          §2.6a）。打开本项后 passing 9776 -> 12136（+2360）。
#          ★ 2026-09-17 修正：此处原写 12196（+2420），是**预测值**不是实测值。
#            实测基线 f8bd195 确为 12196；但共享核修掉一个真 bug 之后降为 12136。
#            bug：o_trans_ld_dep 接的是寄存器原值 r_ld_dep，而 golden
#            （EnqEntry_18.sv:1949 / OthersEntry_164.sv:1863）接的是
#            common_srcLoadDependencyNext —— 即移位后的次态
#            （EnqEntry_18.sv:1038 = {…srcLoadDependency_0[0], 1'h0}，只读 bit0）。
#            接错时 impl 侧多读了影子的 bit1，把它撑成活的比较点；接对之后
#            bit1 两侧同为死位，60 个点（4 条目 × 15 个 [1:0] 影子寄存器 × 1 位）
#            从 Passing 落进 Not Compared/Constant reg：
#              基线 Passing DFF 10792 + Constant reg 68 = 10860
#              修后 Passing DFF 10732 + Constant reg 128 = 10860（匹配点总数不变）
#            两轮 unmatched compare points 均 0(0)，即没有任何一侧单边丢点。
#            ——数字下降是 bug 修复的结果，不是覆盖退化；**不许**为了保住 12196
#              把 RTL 还原成错的接法。

fm_target_vmucp_allow
