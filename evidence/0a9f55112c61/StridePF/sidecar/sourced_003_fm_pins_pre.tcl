# StridePF FM「匹配前」钉点 —— 自动生成：scripts/gen_stridepf_pins.py（勿手改）
#
# golden 无输出端口，比较点全是寄存器（全 unread，靠 vmucp 比较），故全部寄存器必须配对。
# 只消扁平名与数组名的命名差：set_user_match 只声明对应，比较照比，不约束 ref、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != 210 即 error。prev_pc 10 位按名自动配对，不钉。
# 进 fm.log 的输出一律 ASCII。
set ::SPF_PIN_EXPECT 210
set ::SPF_PIN_OK 0
set ::SPF_PIN_BAD 0
proc stridepf_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/StridePF/${g}_reg" "i:/WORK/StridePF/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/StridePF/${g}_reg\[$b\]" "i:/WORK/StridePF/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::SPF_PIN_OK } else {
      incr ::SPF_PIN_BAD
      if {$::SPF_PIN_BAD <= 10} { puts "SPF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "SPF_PIN_BEGIN StridePF expect=$::SPF_PIN_EXPECT"
stridepf_pin prev_valid_last_REG u_core/prev_valid_reg 1
stridepf_pin state_reg u_core/u_plru/state_reg_reg 15
stridepf_pin valids_0 u_core/ent_valid_reg\[0\] 1
stridepf_pin valids_1 u_core/ent_valid_reg\[1\] 1
stridepf_pin valids_2 u_core/ent_valid_reg\[2\] 1
stridepf_pin valids_3 u_core/ent_valid_reg\[3\] 1
stridepf_pin valids_4 u_core/ent_valid_reg\[4\] 1
stridepf_pin valids_5 u_core/ent_valid_reg\[5\] 1
stridepf_pin valids_6 u_core/ent_valid_reg\[6\] 1
stridepf_pin valids_7 u_core/ent_valid_reg\[7\] 1
stridepf_pin valids_8 u_core/ent_valid_reg\[8\] 1
stridepf_pin valids_9 u_core/ent_valid_reg\[9\] 1
stridepf_pin valids_10 u_core/ent_valid_reg\[10\] 1
stridepf_pin valids_11 u_core/ent_valid_reg\[11\] 1
stridepf_pin valids_12 u_core/ent_valid_reg\[12\] 1
stridepf_pin valids_13 u_core/ent_valid_reg\[13\] 1
stridepf_pin valids_14 u_core/ent_valid_reg\[14\] 1
stridepf_pin valids_15 u_core/ent_valid_reg\[15\] 1
stridepf_pin entries_pc_0 u_core/ent_pc_reg\[0\] 10
stridepf_pin entries_pc_1 u_core/ent_pc_reg\[1\] 10
stridepf_pin entries_pc_2 u_core/ent_pc_reg\[2\] 10
stridepf_pin entries_pc_3 u_core/ent_pc_reg\[3\] 10
stridepf_pin entries_pc_4 u_core/ent_pc_reg\[4\] 10
stridepf_pin entries_pc_5 u_core/ent_pc_reg\[5\] 10
stridepf_pin entries_pc_6 u_core/ent_pc_reg\[6\] 10
stridepf_pin entries_pc_7 u_core/ent_pc_reg\[7\] 10
stridepf_pin entries_pc_8 u_core/ent_pc_reg\[8\] 10
stridepf_pin entries_pc_9 u_core/ent_pc_reg\[9\] 10
stridepf_pin entries_pc_10 u_core/ent_pc_reg\[10\] 10
stridepf_pin entries_pc_11 u_core/ent_pc_reg\[11\] 10
stridepf_pin entries_pc_12 u_core/ent_pc_reg\[12\] 10
stridepf_pin entries_pc_13 u_core/ent_pc_reg\[13\] 10
stridepf_pin entries_pc_14 u_core/ent_pc_reg\[14\] 10
stridepf_pin entries_pc_15 u_core/ent_pc_reg\[15\] 10
stridepf_pin s1_hit_last_REG u_core/s1_hit_q_reg 1
stridepf_pin s1_alloc_last_REG u_core/s1_alloc_q_reg 1
stridepf_pin s1_match_vec_0 u_core/s1_match_reg\[0\] 1
stridepf_pin s1_match_vec_1 u_core/s1_match_reg\[1\] 1
stridepf_pin s1_match_vec_2 u_core/s1_match_reg\[2\] 1
stridepf_pin s1_match_vec_3 u_core/s1_match_reg\[3\] 1
stridepf_pin s1_match_vec_4 u_core/s1_match_reg\[4\] 1
stridepf_pin s1_match_vec_5 u_core/s1_match_reg\[5\] 1
stridepf_pin s1_match_vec_6 u_core/s1_match_reg\[6\] 1
stridepf_pin s1_match_vec_7 u_core/s1_match_reg\[7\] 1
stridepf_pin s1_match_vec_8 u_core/s1_match_reg\[8\] 1
stridepf_pin s1_match_vec_9 u_core/s1_match_reg\[9\] 1
stridepf_pin s1_match_vec_10 u_core/s1_match_reg\[10\] 1
stridepf_pin s1_match_vec_11 u_core/s1_match_reg\[11\] 1
stridepf_pin s1_match_vec_12 u_core/s1_match_reg\[12\] 1
stridepf_pin s1_match_vec_13 u_core/s1_match_reg\[13\] 1
stridepf_pin s1_match_vec_14 u_core/s1_match_reg\[14\] 1
stridepf_pin s1_match_vec_15 u_core/s1_match_reg\[15\] 1
puts "SPF_PIN_END StridePF ok=$::SPF_PIN_OK bad=$::SPF_PIN_BAD"
if {$::SPF_PIN_BAD != 0} { error "SPF_PIN_MISS=$::SPF_PIN_BAD" }
if {$::SPF_PIN_OK != 210} { error "SPF_PIN_COUNT=$::SPF_PIN_OK expect=210" }
