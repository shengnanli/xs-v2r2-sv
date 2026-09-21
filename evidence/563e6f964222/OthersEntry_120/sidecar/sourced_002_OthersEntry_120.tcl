# vmucp 白名单条目：OthersEntry_120
#
# 本文件 = OthersEntry_120 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# OthersEntry_88 / _104 / _120 加入依据(2026-09-20, agent/othersentry 实测)：
# 三个都是 FP 族的 simp 条目。钉点后(verif/ut/<变体>/fm_pins_pre.tcl，1407 对)
# strict 跑 native SUCCEEDED / failing 0 / unmatched 六项全 0，只剩 unread 9 卡住。
# 9 点**全部** matched_nc，ref 侧 9 个唯一点 ↔ impl 侧 9 个唯一点、非 matched_nc
# 项为 0，严格双射；而且这 9 对正是钉点文件自己钉上去的，不是 FM 猜配：
#   ref  entryReg_status_srcStatus_<s>_srcLoadDependency_<q>_reg[1]
#   impl u_entry/r_ld_dep_reg[s][q][1]            (s,q in 0..2, 共 9 对)
# 死因两侧同源、结构性的：FP 族 golden **一个 ldCancel 端口都没有**
# (verif/ut/OthersEntry_field_matrix/matrix.tsv 的 nLdCancel / ld1Cancel /
#  ld2Cancel / ldDep_pipes 四行在这几列全 0，可 gen_matrix.py --check 复算)，
# 于是 LoadShouldCancel 整条不生成，srcLoadDependency 影子的 bit[1] 没有读出点；
# 次态是左移(bit1' = bit0)，而 transEntry 露的是**次态**不是寄存器，
# 所以寄存器 bit1 是纯写入位 —— golden 与可读核同为死位，不是人工强配。
# ★复核判据(跑前预登记)★ 加强后 passing 必须**恰好 +9**：
#   OthersEntry_88  3519 -> 3528 / _104 3511 -> 3520 / _120 3507 -> 3516，
#   三个都正好等于 predict.py 的模型上界；unread 归 0、failing 仍 0、unmatched 全 0。
#   passing 不增而 unread 归 0 = 点被吞掉，不算过。

fm_target_vmucp_allow
