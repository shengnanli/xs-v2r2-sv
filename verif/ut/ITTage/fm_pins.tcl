# ITTage FM 钉点:golden s2_pc_dup_s2_pc_seg_1_value 的低 8 位[7:0]是调试流水复制位
# (喂 s3 调试寄存器链 → 被 FM 判为 compare point,非 unread),而重写核对应
# s2_pc_seg_1[7:0] 存而不读(region 只用 seg_1[11:8])。两侧 read-status 非对称 → 自动
# 签名/名字配对失败,残留 8 个 unmatched reference compare point。逐位 set_user_match
# 精确 1:1 双射(两侧同为 RegEnable(s1_pc_dup[0][23:12], s1_fire) → 值恒等),配对后经
# verify_matched_unread_compare_points(vmucp)实际比较 → passing,compare_ref→0。
for {set b 0} {$b < 8} {incr b} {
  set rl "r:/WORK/$top/s2_pc_dup_s2_pc_seg_1_value_reg\[$b\]"
  set il "i:/WORK/$top/u_core/s2_pc_seg_1_reg\[$b\]"
  if {[catch {set_user_match $rl $il} m]} {
    puts "ITTAGE_PINS_WARN: $rl <-> $il : $m"
  }
}
puts "ITTAGE_PINS: s2_pc_seg_1\[7:0\] pinned (8 bijective pairs)"
