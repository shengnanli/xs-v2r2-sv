# vmucp 白名单条目：MainPipe（DCache 主流水）
#
# 本文件 = MainPipe 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-28, agent/dmainpipe lane 内 diagnostic-full 试跑，未出 receipt）----
# 首跑（vmucp 关、无钉点）：native SUCCEEDED / passing 8955 / failing 0 / unmatched compare 0(0) /
# 无黑盒 / 无 dont_verify；剩下两类让 strict 判 PARTIAL 的点：
#   (a) matched-unread 65 = FM 自己按名 1<->1 配上的两侧对称死位：
#       debug_sc_fail_addr[47:0] 48 + debug_sc_addr_match_fail_cnt[7:0] 8（只喂 XSError）、
#       s3_req.addr[5:0] 6（只被上面两个 debug 寄存器读）、s3_req.vaddr[49:48] 2（写口地址只取 [47:0]）、
#       s2_repl_pf[0] 1（is_from_l1_prefetch 只看 >1，即 [2:1]）。
#   (b) unmatched unread 16(16) = 名字不同的同一批死寄存器，由 verif/ut/MainPipe/fm_pins_pre.tcl
#       逐项写死配对（REG_2..6 <-> chk_*_q、io_replace_way_set_valid_last_REG <-> s0_fire_q_replway、
#       s1_extra_meta_r_{access,prefetch} <-> s1_extra_meta_hold.{access,prefetch}、
#       s3_error_paddr_beu_r[5:0] <-> s3_error_paddr_beu_q[5:0]），钉后变成 matched-unread。
# 两侧同为死位、同一死因（可读核照 golden 逐个保留这些寄存器，同复位/同次态，见 MainPipe.sv §8）。
# vmucp 六条：精确绑定（配对表逐项写死、计数 fail-closed）/ 双射（16+65 全部一对一）/
#   FM 实比（passing 应 8955 -> 9036 = +65+16）/ 加强后 failing 须仍为 0 / 无 dont_verify、
#   无新黑盒 / 摘要写在本文件与 docs/lanes/dmainpipe_prereg.md。
# 另有 1 个 Constant reg（两侧各 1，FM assumed-to-toggle 折叠），不计 passing。

fm_target_vmucp_allow
