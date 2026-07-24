# DataPath FM 钉点(FM 审计 2026-07)
# 发射级 imm 打拍寄存器:golden s1_immInfo_<i>_<j>_imm/_immType ↔ 手写核 s1_imm_<i>_<j>/
# s1_immType_<i>_<j>(词干不同,自动配对只能靠签名,历史遗留 160 bit unmatched)。按名逐位钉死。
set _n 0
for {set i 0} {$i <= 14} {incr i} {
  for {set j 0} {$j <= 1} {incr j} {
    for {set b 0} {$b < 32} {incr b} {
      if {![catch {set_user_match "r:/WORK/$top/s1_immInfo_${i}_${j}_imm_reg\[$b\]" \
                                  "i:/WORK/$top/u_core/s1_imm_${i}_${j}_reg\[$b\]"}]} { incr _n }
    }
    for {set b 0} {$b < 4} {incr b} {
      if {![catch {set_user_match "r:/WORK/$top/s1_immInfo_${i}_${j}_immType_reg\[$b\]" \
                                  "i:/WORK/$top/u_core/s1_immType_${i}_${j}_reg\[$b\]"}]} { incr _n }
    }
  }
}
puts "DATAPATH_PINS: s1_imm $_n points pinned"

# STD 端口 srcType 打拍寄存器:golden 用全局 EXU 索引命名(25=MemIQ_7, 26=MemIQ_8),
# 手写核用 Mem 相对索引(17/18)。二者同为 RegEnable(fromIQFire)寄存的 4 位 srcType,
# 值恒等(选 int|fp rdata 送 io_toMemExu_7/8_bits_src_0),仅名字词干不同 → 自动配对失败
# 报 golden-only unread_ref。逐位钉死双射(只 set_user_match,不约束 ref 逻辑)。
set _ns 0
foreach {gi ii} {25 17 26 18} {
  for {set b 0} {$b < 4} {incr b} {
    if {![catch {set_user_match "r:/WORK/$top/s1_srcType_r_${gi}_0_reg\[$b\]" \
                                "i:/WORK/$top/u_core/s1_srctype_${ii}_0_0_reg\[$b\]"}]} { incr _ns }
  }
}
puts "DATAPATH_PINS: s1_srcType $_ns points pinned"
