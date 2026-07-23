# TLBNonBlock FM 钉点（FM 审计 2026-07）
# golden 把 PTW resp 打拍寄存器按 lane 展平命名（ptw_resp_bits_reg[_N]_<field>），
# 重写核用数组 pr_<field>_reg[N]；readResult_p_* 同理 ↔ p_<field>_reg[N]；
# 名字差异过大自动配对失败 → 显式钉。golden lane 下标：无后缀=0，_1.._3。
proc lane_suffix {n} { return [expr {$n==0 ? "" : "_$n"}] }

# ---- ptw_resp_bits_reg（pr_*）多位字段：{golden字段名 impl字段名 宽度} ----
foreach {gf if w} {
  s2_entry_tag  pr_s2_tag       38
  s1_entry_tag  pr_s1_tag       35
  s1_entry_asid pr_s1_asid      16
  s2_entry_vmid pr_s2_vmid      14
  s1_entry_vmid pr_s1_vmid      14
  s1_addr_low   pr_s1_addr_low   3
  s2xlate       pr_s2xlate       2
  s2_entry_level pr_s2_level     2
  s1_entry_level pr_s1_level     2
} {
  for {set n 0} {$n < 4} {incr n} {
    set sfx [lane_suffix $n]
    for {set b 0} {$b < $w} {incr b} {
      catch {set_user_match "r:/WORK/$top/ptw_resp_bits_reg${sfx}_${gf}_reg\[$b\]" \
                            "i:/WORK/$top/u_core/${if}_reg\[$n\]\[$b\]"}
    }
  }
}
# ---- pr 1 位字段 ----
foreach {gf if} {
  s2_entry_n      pr_s2_n
  s1_entry_n      pr_s1_n
  s1_entry_perm_g pr_s1_perm_g
} {
  for {set n 0} {$n < 4} {incr n} {
    set sfx [lane_suffix $n]
    catch {set_user_match "r:/WORK/$top/ptw_resp_bits_reg${sfx}_${gf}_reg" \
                          "i:/WORK/$top/u_core/${if}_reg\[$n\]"}
  }
}
# ---- pr s1_valididx_0..7（golden 逐位标量 ↔ impl [lane][bit]）----
for {set n 0} {$n < 4} {incr n} {
  set sfx [lane_suffix $n]
  for {set b 0} {$b < 8} {incr b} {
    catch {set_user_match "r:/WORK/$top/ptw_resp_bits_reg${sfx}_s1_valididx_${b}_reg" \
                          "i:/WORK/$top/u_core/pr_s1_valididx_reg\[$n\]\[$b\]"}
  }
}

# ---- readResult_p_*（p_*）多位字段（golden 后缀在字段名后：readResult_p_<f>[_N]）----
foreach {gf if w} {
  s2xlate  p_s2xlate  2
  s1_level p_s1_level 2
  pbmt     p_pbmt     2
} {
  for {set n 0} {$n < 4} {incr n} {
    set sfx [lane_suffix $n]
    for {set b 0} {$b < $w} {incr b} {
      catch {set_user_match "r:/WORK/$top/readResult_p_${gf}${sfx}_reg\[$b\]" \
                            "i:/WORK/$top/u_core/${if}_reg\[$n\]\[$b\]"}
    }
  }
}
# ---- p 1 位字段 ----
for {set n 0} {$n < 4} {incr n} {
  set sfx [lane_suffix $n]
  catch {set_user_match "r:/WORK/$top/readResult_p_s1_isFakePte${sfx}_reg" \
                        "i:/WORK/$top/u_core/p_s1_isFakePte_reg\[$n\]"}
  # perm/g_perm 打包 struct（impl p_perm_reg[N][field]）
  foreach f {x w v u r pf d af a} {
    catch {set_user_match "r:/WORK/$top/readResult_p_perm${sfx}_${f}_reg" \
                          "i:/WORK/$top/u_core/p_perm_reg\[$n\]\\\[$f\]"}
  }
  foreach f {x w r pf d af a} {
    catch {set_user_match "r:/WORK/$top/readResult_p_g_perm${sfx}_${f}_reg" \
                          "i:/WORK/$top/u_core/p_g_perm_reg\[$n\]\\\[$f\]"}
  }
}

# ---- lastCycleRedirect per-lane 副本（RTL 已建 lcr_*[N] 数组）----
for {set n 0} {$n < 4} {incr n} {
  set sfx [lane_suffix $n]
  catch {set_user_match "r:/WORK/$top/readResult_lastCycleRedirect_REG${sfx}_valid_reg" \
                        "i:/WORK/$top/u_core/lcr_valid_reg\[$n\]"}
  catch {set_user_match "r:/WORK/$top/readResult_lastCycleRedirect_REG${sfx}_bits_robIdx_flag_reg" \
                        "i:/WORK/$top/u_core/lcr_robIdx_flag_reg\[$n\]"}
  catch {set_user_match "r:/WORK/$top/readResult_lastCycleRedirect_REG${sfx}_bits_level_reg" \
                        "i:/WORK/$top/u_core/lcr_level_reg\[$n\]"}
  for {set b 0} {$b < 8} {incr b} {
    catch {set_user_match "r:/WORK/$top/readResult_lastCycleRedirect_REG${sfx}_bits_robIdx_value_reg\[$b\]" \
                          "i:/WORK/$top/u_core/lcr_robIdx_value_reg\[$n\]\[$b\]"}
  }
}

# ---- 预检异常打拍的双副本 REG/REG_1（lane0）…REG_6/REG_7（lane3）----
#  偶数下标（REG,REG_2,REG_4,REG_6）→ REG_pre[lane]；奇数 → REG_pre2[lane]
foreach {gr ip n} {
  REG   REG_pre 0   REG_1 REG_pre2 0
  REG_2 REG_pre 1   REG_3 REG_pre2 1
  REG_4 REG_pre 2   REG_5 REG_pre2 2
  REG_6 REG_pre 3   REG_7 REG_pre2 3
} {
  catch {set_user_match "r:/WORK/$top/${gr}_reg" "i:/WORK/$top/u_core/${ip}_reg\[$n\]"}
}
puts "TLB_PINS: applied"
