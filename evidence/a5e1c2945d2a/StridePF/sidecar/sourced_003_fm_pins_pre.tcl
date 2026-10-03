# StridePF FM「匹配前」钉点 —— 自动生成：scripts/gen_l1pf_pins.py（勿手改）
#
# 依据见生成器文件头与 verif/fm_target_config/StridePF.tcl：这些寄存器 FM 按名配不上且全是 unread，
# 不钉则 vmucp 空转。set_user_match 只声明对应，比较照比，不约束 ref、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != 210 即 error。进 fm.log 的输出一律 ASCII。
set ::L1PF_PIN_EXPECT 210
set ::L1PF_PIN_OK 0
set ::L1PF_PIN_BAD 0
proc l1pf_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/StridePF/${g}_reg" "i:/WORK/StridePF/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/StridePF/${g}_reg\[$b\]" "i:/WORK/StridePF/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::L1PF_PIN_OK } else {
      incr ::L1PF_PIN_BAD
      if {$::L1PF_PIN_BAD <= 10} { puts "L1PF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "L1PF_PIN_BEGIN StridePF expect=$::L1PF_PIN_EXPECT"
l1pf_pin prev_valid_last_REG u_core/prev_valid_reg 1
l1pf_pin state_reg u_core/u_plru/state_reg_reg 15
l1pf_pin valids_0 u_core/ent_valid_reg\[0\] 1
l1pf_pin valids_1 u_core/ent_valid_reg\[1\] 1
l1pf_pin valids_2 u_core/ent_valid_reg\[2\] 1
l1pf_pin valids_3 u_core/ent_valid_reg\[3\] 1
l1pf_pin valids_4 u_core/ent_valid_reg\[4\] 1
l1pf_pin valids_5 u_core/ent_valid_reg\[5\] 1
l1pf_pin valids_6 u_core/ent_valid_reg\[6\] 1
l1pf_pin valids_7 u_core/ent_valid_reg\[7\] 1
l1pf_pin valids_8 u_core/ent_valid_reg\[8\] 1
l1pf_pin valids_9 u_core/ent_valid_reg\[9\] 1
l1pf_pin valids_10 u_core/ent_valid_reg\[10\] 1
l1pf_pin valids_11 u_core/ent_valid_reg\[11\] 1
l1pf_pin valids_12 u_core/ent_valid_reg\[12\] 1
l1pf_pin valids_13 u_core/ent_valid_reg\[13\] 1
l1pf_pin valids_14 u_core/ent_valid_reg\[14\] 1
l1pf_pin valids_15 u_core/ent_valid_reg\[15\] 1
l1pf_pin entries_pc_0 u_core/ent_pc_reg\[0\] 10
l1pf_pin entries_pc_1 u_core/ent_pc_reg\[1\] 10
l1pf_pin entries_pc_2 u_core/ent_pc_reg\[2\] 10
l1pf_pin entries_pc_3 u_core/ent_pc_reg\[3\] 10
l1pf_pin entries_pc_4 u_core/ent_pc_reg\[4\] 10
l1pf_pin entries_pc_5 u_core/ent_pc_reg\[5\] 10
l1pf_pin entries_pc_6 u_core/ent_pc_reg\[6\] 10
l1pf_pin entries_pc_7 u_core/ent_pc_reg\[7\] 10
l1pf_pin entries_pc_8 u_core/ent_pc_reg\[8\] 10
l1pf_pin entries_pc_9 u_core/ent_pc_reg\[9\] 10
l1pf_pin entries_pc_10 u_core/ent_pc_reg\[10\] 10
l1pf_pin entries_pc_11 u_core/ent_pc_reg\[11\] 10
l1pf_pin entries_pc_12 u_core/ent_pc_reg\[12\] 10
l1pf_pin entries_pc_13 u_core/ent_pc_reg\[13\] 10
l1pf_pin entries_pc_14 u_core/ent_pc_reg\[14\] 10
l1pf_pin entries_pc_15 u_core/ent_pc_reg\[15\] 10
l1pf_pin s1_hit_last_REG u_core/s1_hit_q_reg 1
l1pf_pin s1_alloc_last_REG u_core/s1_alloc_q_reg 1
l1pf_pin s1_match_vec_0 u_core/s1_match_reg\[0\] 1
l1pf_pin s1_match_vec_1 u_core/s1_match_reg\[1\] 1
l1pf_pin s1_match_vec_2 u_core/s1_match_reg\[2\] 1
l1pf_pin s1_match_vec_3 u_core/s1_match_reg\[3\] 1
l1pf_pin s1_match_vec_4 u_core/s1_match_reg\[4\] 1
l1pf_pin s1_match_vec_5 u_core/s1_match_reg\[5\] 1
l1pf_pin s1_match_vec_6 u_core/s1_match_reg\[6\] 1
l1pf_pin s1_match_vec_7 u_core/s1_match_reg\[7\] 1
l1pf_pin s1_match_vec_8 u_core/s1_match_reg\[8\] 1
l1pf_pin s1_match_vec_9 u_core/s1_match_reg\[9\] 1
l1pf_pin s1_match_vec_10 u_core/s1_match_reg\[10\] 1
l1pf_pin s1_match_vec_11 u_core/s1_match_reg\[11\] 1
l1pf_pin s1_match_vec_12 u_core/s1_match_reg\[12\] 1
l1pf_pin s1_match_vec_13 u_core/s1_match_reg\[13\] 1
l1pf_pin s1_match_vec_14 u_core/s1_match_reg\[14\] 1
l1pf_pin s1_match_vec_15 u_core/s1_match_reg\[15\] 1
puts "L1PF_PIN_END StridePF ok=$::L1PF_PIN_OK bad=$::L1PF_PIN_BAD"
if {$::L1PF_PIN_BAD != 0} { error "L1PF_PIN_MISS=$::L1PF_PIN_BAD" }
if {$::L1PF_PIN_OK != 210} { error "L1PF_PIN_COUNT=$::L1PF_PIN_OK expect=210" }
