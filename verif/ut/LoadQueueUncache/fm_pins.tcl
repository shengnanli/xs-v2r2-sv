# LoadQueueUncache FM 钉点（FM 审计 2026-07）
# golden 对 io_redirect 的 s2 冲刷检查每 lane 打一份**无使能** RegNext 副本
# （s2_valid_REG_1/3/5_{valid,bits}）；重写核以 per-lane 数组 redirect_s2_nc_*[i]
# 1:1 对齐（FM 不接受 n-to-1 钉点，故 RTL 建了同构副本）。层次/叶名差异自动配对
# 常失败，这里显式钉死。带使能的 lastCycleRedirect_bits_r ↔ redirect_d1_reg[bits]
# 名称/签名可自动配对，不钉。lastCycleRedirect_valid_REG（无使能 valid 第 4 份副本）
# ↔ redirect_d1_reg[valid]。
foreach {rp lane} {s2_valid_REG_1 0 s2_valid_REG_3 1 s2_valid_REG_5 2} {
  catch {set_user_match "r:/WORK/$top/${rp}_valid_reg" \
                        "i:/WORK/$top/u_core/redirect_s2_nc_valid_reg\[$lane\]"}
  catch {set_user_match "r:/WORK/$top/${rp}_bits_robIdx_flag_reg" \
                        "i:/WORK/$top/u_core/redirect_s2_nc_flag_reg\[$lane\]"}
  catch {set_user_match "r:/WORK/$top/${rp}_bits_level_reg" \
                        "i:/WORK/$top/u_core/redirect_s2_nc_level_reg\[$lane\]"}
  for {set b 0} {$b < 8} {incr b} {
    catch {set_user_match "r:/WORK/$top/${rp}_bits_robIdx_value_reg\[$b\]" \
                          "i:/WORK/$top/u_core/redirect_s2_nc_value_reg\[$lane\]\[$b\]"}
  }
}
catch {set_user_match "r:/WORK/$top/lastCycleRedirect_valid_REG_reg" \
                      "i:/WORK/$top/u_core/redirect_d1_reg\\\[valid\]"}

# freeList 黑盒（未给 FM 模块定义 → 引脚方向未知）的 io_empty 输出脚：两侧均无消费
# （golden 只把它接到悬空 _probe 线；重写核连到未读的 free_empty），但方向未知使 FM
# 把它当可验证比对点且两侧"驱动"均为悬空 → 误报。功能上该脚无任何 fanout，安全跳过。
catch {set_dont_verify_points "r:/WORK/$top/freeList/io_empty"}
catch {set_dont_verify_points "i:/WORK/$top/u_core/u_freelist/io_empty"}
puts "LQU_PINS: per-lane redirect copies pinned + io_empty dont-verify"
