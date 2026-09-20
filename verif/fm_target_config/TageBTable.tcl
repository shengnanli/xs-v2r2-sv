# vmucp 白名单条目：TageBTable
#
# 本文件 = TageBTable 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# TageBTable 加入依据(2026-09-14, worker agent/tage)：assembly(子模块两侧同源白盒,
# 唯一黑盒 array_4_ext 为已审定厂商叶子) 首跑 native SUCCEEDED / passing 381 /
# failing 0 / unmatched 0，仅 unread 10 卡住。10 点**全部** matched_nc，且 FM 自己
# 已把它们两两配好：ref 侧 10 个唯一点 ↔ impl 侧 10 个唯一点，非 matched_nc 项为 0，
# 末段名逐一相同(s1_idx_reg[1..10])，即严格双射——不是人工强配。
# 这些位是什么：golden TageBTable 把整条 11 位行索引在 s1 打了一拍
# (`reg [10:0] s1_idx; s1_idx <= io_req_bits[11:1]`)，但 s1 级**只读 bit[0]**——
# 那一位是 numBr=2 的物理/逻辑 way 反映射(s1_read 的两路交换，见 golden 391/393 行)；
# SRAM 读地址走的是 s0_idx(在 FoldedSRAMTemplate 内部自己打拍)，所以 s1_idx[10:1]
# 写入后零扇出。重写核照抄了 golden 这个结构(rtl/frontend/TageBTable.sv:321/327/342)，
# 于是两侧同为死位、同名同位置。加强后 FM 真去比这 10 点：passing 381→391、failing 仍 0。

fm_target_vmucp_allow
