# vmucp 白名单条目：ICacheMetaArray
#
# 本文件 = ICacheMetaArray 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   ICacheMetaArray 加入依据(2026-09-14, PARTIAL 收口簇)：把 tag SRAM 子树两侧
#          同源 elaborate 之后（见该 UT Makefile），native SUCCEEDED / passing 2491 /
#          failing 0 / unmatched 0，只剩 9 个 matched_nc，ref 9 ↔ impl 9、
#          非 matched_nc 项为 0。9 点全在 mbistPl（MbistPipeIcacheTag，两侧读同一份
#          golden 文件、路径逐字相同）：
#            addrReg_reg[7:0]  —— MBIST 写地址。MbistPipeIcacheTag.sv:239 把它送到
#              toSRAM_*_addr，接到 SplittedSRAMTemplate 的 boreChildrenBd_bore_addr；
#              而该端口在 SplittedSRAMTemplate.sv 里**声明了却没有任何使用**，
#              整条写地址在本层无读者。
#            addrRdReg_reg[7]  —— MBIST 读地址最高位。读地址确实往下传，但本宏
#              （sram_array_1p128x74m37s1h0l1b_icsh_tag → array_ext）深 128、
#              地址只有 7 位，bit7 到不了存储阵列。
#          这 9 位在 SRAM 黑盒时期是"黑盒输入"因而算被读；白盒化后才暴露出来，
#          属于 golden 自身的死位，两侧同构。打开后 passing 应 2491 -> 2500。

fm_target_vmucp_allow
