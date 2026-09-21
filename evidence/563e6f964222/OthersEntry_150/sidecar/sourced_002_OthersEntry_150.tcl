# vmucp 白名单条目：OthersEntry_150
#
# 本文件 = OthersEntry_150 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# OthersEntry_164 加入依据(2026-09-20, 同一 lane 实测)：与上面三个 FP simp
# **同因同型**，只是源数 3 -> 5，于是死位 9 个 -> 15 个(5 源 x 3 pipe)。
# 钉点后 strict 跑 native SUCCEEDED / failing 0 / unmatched 六项全 0，只剩 unread 15；
# 15 点**全部** matched_nc、ref 15 <-> impl 15 严格双射，且都是钉点文件自己钉上的：
#   ref  entryReg_status_srcStatus_<s>_srcLoadDependency_<q>_reg[1]
#   impl u_entry/r_ld_dep_reg[s][q][1]            (s in 0..4, q in 0..2)
# 死因两侧同源、结构性的：VEC 族 golden 同样**一个 ldCancel 端口都没有**
# (verif/ut/OthersEntry_field_matrix/matrix.tsv 的 nLdCancel / ld1Cancel /
#  ld2Cancel / ldDep_pipes 在 _164/_166 两列全 0)，LoadShouldCancel 整条不生成，
# 影子 bit[1] 没有读出点；次态左移(bit1'=bit0)，transEntry 露的是次态不是寄存器
# ⇒ 寄存器 bit1 是纯写入位。
# OthersEntry_150 / _136 与 _164 **同因同型**(都是 VEC 族 simp，5 源 x 3 pipe = 15 死位，
# 同样 nLdCancel/ld1Cancel/ld2Cancel/ldDep_pipes 四行全 0)，一并加入。
# ★复核判据(跑前预登记)★ 加强后 passing 必须**恰好 +15**：
#   _164 3777 -> 3792 / _150 3782 -> 3797 / _136 3844 -> 3859，
# 三个都正好等于 predict.py 的模型上界；unread 归 0、failing 仍 0、unmatched 全 0。

fm_target_vmucp_allow
