# vmucp 白名单条目：LLPTW
#
# 本文件 = LLPTW 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-22，agent/mmu5-llptw 实测）----
# 未开 vmucp 的 strict 首跑（impl commit fdda7d0df166，evidence/fdda7d0df166/LLPTW）：
# native SUCCEEDED / passing 5595 / failing 0 / unverified 0 / aborted 0 /
# unmatched 两侧全 0 / 无黑盒 / 无 dont_verify / 无 relaxed appvar，
# 只剩 3 个 matched-unread-notcompared 点让 verdict 判 PARTIAL：
#     r:/WORK/LLPTW/REG_reg         <-> i:/WORK/LLPTW/u_core/REG_reg
#     r:/WORK/LLPTW/hpaddr_reg[48]  <-> i:/WORK/LLPTW/u_core/hpaddr_reg[48]
#     r:/WORK/LLPTW/hpaddr_reg[49]  <-> i:/WORK/LLPTW/u_core/hpaddr_reg[49]
# 三对全是 FM 自己按名配上的（叶名逐字相同，只差一层 u_core），无任何 set_user_match，
# ref 3 ↔ impl 3 严格双射，非 matched_nc 项为 0。
# 两侧同为死位、同一死因：
#   · REG = RegNext(dup_req_fire && Cat(dup_vec_wait).orR)，Chisel 里唯一读出点是
#     XSError(...)（PageTableWalker.scala），golden 与可读核都把它放在 `ifndef SYNTHESIS
#     块里；FM 两侧都带 -define SYNTHESIS 读入 ⇒ 断言整块编译掉，寄存器写了从不被读。
#   · hpaddr 是 50 位（GPAddrBits）的 RegEnable，唯一读出点 io.pmp(1).req.bits.addr 是
#     PAddrBits=48 位，两侧都只读 [47:0]，[49:48] 写了从不被读。
# 加强 = 让 FM 把这 3 点也证一遍（比较点只增不减，是加严不是放松）。
# 加强后的读数与对账写在本目标的 receipt 与 docs/fm_predictions/LLPTW.json 的 check 里。

fm_target_vmucp_allow
