# PMP FM「匹配前」钉点 —— 自动生成：scripts/gen_mmuleaf.py（勿手改）
#
# 只消 golden 展平寄存器名与重写核 generate 块/数组/语义名之间的命名鸿沟（规则见生成器）。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数（= golden 顶层寄存器位数）就 error（safe interp 里不用 exit）。
# 进 fm.log 的输出一律 ASCII。
set ::PMP_PIN_EXPECT 6664
set ::PMP_PIN_OK 0
set ::PMP_PIN_BAD 0
proc pmp_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/PMP/${g}_reg" "i:/WORK/PMP/u_core/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/PMP/${g}_reg\[$b\]" "i:/WORK/PMP/u_core/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::PMP_PIN_OK } else {
      incr ::PMP_PIN_BAD
      if {$::PMP_PIN_BAD <= 10} { puts "PMP_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "PMP_PIN_BEGIN PMP expect=$::PMP_PIN_EXPECT"
pmp_pin pmpMapping_cfgMerged_0 cfg_merged_reg\[0\]\[0\] 64
pmp_pin pmpMapping_cfgMerged_1 cfg_merged_reg\[0\]\[1\] 64
pmp_pin pmpMapping_cfgMerged_2 cfg_merged_reg\[0\]\[2\] 64
pmp_pin pmpMapping_cfgMerged_3 cfg_merged_reg\[0\]\[3\] 64
pmp_pin pmpMapping_addr_0 addr_reg\[0\]\[0\] 46
pmp_pin pmpMapping_addr_1 addr_reg\[0\]\[1\] 46
pmp_pin pmpMapping_addr_2 addr_reg\[0\]\[2\] 46
pmp_pin pmpMapping_addr_3 addr_reg\[0\]\[3\] 46
pmp_pin pmpMapping_addr_4 addr_reg\[0\]\[4\] 46
pmp_pin pmpMapping_addr_5 addr_reg\[0\]\[5\] 46
pmp_pin pmpMapping_addr_6 addr_reg\[0\]\[6\] 46
pmp_pin pmpMapping_addr_7 addr_reg\[0\]\[7\] 46
pmp_pin pmpMapping_addr_8 addr_reg\[0\]\[8\] 46
pmp_pin pmpMapping_addr_9 addr_reg\[0\]\[9\] 46
pmp_pin pmpMapping_addr_10 addr_reg\[0\]\[10\] 46
pmp_pin pmpMapping_addr_11 addr_reg\[0\]\[11\] 46
pmp_pin pmpMapping_addr_12 addr_reg\[0\]\[12\] 46
pmp_pin pmpMapping_addr_13 addr_reg\[0\]\[13\] 46
pmp_pin pmpMapping_addr_14 addr_reg\[0\]\[14\] 46
pmp_pin pmpMapping_addr_15 addr_reg\[0\]\[15\] 46
pmp_pin pmpMapping_addr_16 addr_reg\[0\]\[16\] 46
pmp_pin pmpMapping_addr_17 addr_reg\[0\]\[17\] 46
pmp_pin pmpMapping_addr_18 addr_reg\[0\]\[18\] 46
pmp_pin pmpMapping_addr_19 addr_reg\[0\]\[19\] 46
pmp_pin pmpMapping_addr_20 addr_reg\[0\]\[20\] 46
pmp_pin pmpMapping_addr_21 addr_reg\[0\]\[21\] 46
pmp_pin pmpMapping_addr_22 addr_reg\[0\]\[22\] 46
pmp_pin pmpMapping_addr_23 addr_reg\[0\]\[23\] 46
pmp_pin pmpMapping_addr_24 addr_reg\[0\]\[24\] 46
pmp_pin pmpMapping_addr_25 addr_reg\[0\]\[25\] 46
pmp_pin pmpMapping_addr_26 addr_reg\[0\]\[26\] 46
pmp_pin pmpMapping_addr_27 addr_reg\[0\]\[27\] 46
pmp_pin pmpMapping_addr_28 addr_reg\[0\]\[28\] 46
pmp_pin pmpMapping_addr_29 addr_reg\[0\]\[29\] 46
pmp_pin pmpMapping_addr_30 addr_reg\[0\]\[30\] 46
pmp_pin pmpMapping_addr_31 addr_reg\[0\]\[31\] 46
pmp_pin pmpMapping_mask_0 mask_reg\[0\]\[0\] 48
pmp_pin pmpMapping_mask_1 mask_reg\[0\]\[1\] 48
pmp_pin pmpMapping_mask_2 mask_reg\[0\]\[2\] 48
pmp_pin pmpMapping_mask_3 mask_reg\[0\]\[3\] 48
pmp_pin pmpMapping_mask_4 mask_reg\[0\]\[4\] 48
pmp_pin pmpMapping_mask_5 mask_reg\[0\]\[5\] 48
pmp_pin pmpMapping_mask_6 mask_reg\[0\]\[6\] 48
pmp_pin pmpMapping_mask_7 mask_reg\[0\]\[7\] 48
pmp_pin pmpMapping_mask_8 mask_reg\[0\]\[8\] 48
pmp_pin pmpMapping_mask_9 mask_reg\[0\]\[9\] 48
pmp_pin pmpMapping_mask_10 mask_reg\[0\]\[10\] 48
pmp_pin pmpMapping_mask_11 mask_reg\[0\]\[11\] 48
pmp_pin pmpMapping_mask_12 mask_reg\[0\]\[12\] 48
pmp_pin pmpMapping_mask_13 mask_reg\[0\]\[13\] 48
pmp_pin pmpMapping_mask_14 mask_reg\[0\]\[14\] 48
pmp_pin pmpMapping_mask_15 mask_reg\[0\]\[15\] 48
pmp_pin pmpMapping_mask_16 mask_reg\[0\]\[16\] 48
pmp_pin pmpMapping_mask_17 mask_reg\[0\]\[17\] 48
pmp_pin pmpMapping_mask_18 mask_reg\[0\]\[18\] 48
pmp_pin pmpMapping_mask_19 mask_reg\[0\]\[19\] 48
pmp_pin pmpMapping_mask_20 mask_reg\[0\]\[20\] 48
pmp_pin pmpMapping_mask_21 mask_reg\[0\]\[21\] 48
pmp_pin pmpMapping_mask_22 mask_reg\[0\]\[22\] 48
pmp_pin pmpMapping_mask_23 mask_reg\[0\]\[23\] 48
pmp_pin pmpMapping_mask_24 mask_reg\[0\]\[24\] 48
pmp_pin pmpMapping_mask_25 mask_reg\[0\]\[25\] 48
pmp_pin pmpMapping_mask_26 mask_reg\[0\]\[26\] 48
pmp_pin pmpMapping_mask_27 mask_reg\[0\]\[27\] 48
pmp_pin pmpMapping_mask_28 mask_reg\[0\]\[28\] 48
pmp_pin pmpMapping_mask_29 mask_reg\[0\]\[29\] 48
pmp_pin pmpMapping_mask_30 mask_reg\[0\]\[30\] 48
pmp_pin pmpMapping_mask_31 mask_reg\[0\]\[31\] 48
pmp_pin pmaMapping_cfgMerged_0 cfg_merged_reg\[1\]\[0\] 64
pmp_pin pmaMapping_cfgMerged_1 cfg_merged_reg\[1\]\[1\] 64
pmp_pin pmaMapping_cfgMerged_2 cfg_merged_reg\[1\]\[2\] 64
pmp_pin pmaMapping_cfgMerged_3 cfg_merged_reg\[1\]\[3\] 64
pmp_pin pmaMapping_addr_0 addr_reg\[1\]\[0\] 46
pmp_pin pmaMapping_addr_1 addr_reg\[1\]\[1\] 46
pmp_pin pmaMapping_addr_2 addr_reg\[1\]\[2\] 46
pmp_pin pmaMapping_addr_3 addr_reg\[1\]\[3\] 46
pmp_pin pmaMapping_addr_4 addr_reg\[1\]\[4\] 46
pmp_pin pmaMapping_addr_5 addr_reg\[1\]\[5\] 46
pmp_pin pmaMapping_addr_6 addr_reg\[1\]\[6\] 46
pmp_pin pmaMapping_addr_7 addr_reg\[1\]\[7\] 46
pmp_pin pmaMapping_addr_8 addr_reg\[1\]\[8\] 46
pmp_pin pmaMapping_addr_9 addr_reg\[1\]\[9\] 46
pmp_pin pmaMapping_addr_10 addr_reg\[1\]\[10\] 46
pmp_pin pmaMapping_addr_11 addr_reg\[1\]\[11\] 46
pmp_pin pmaMapping_addr_12 addr_reg\[1\]\[12\] 46
pmp_pin pmaMapping_addr_13 addr_reg\[1\]\[13\] 46
pmp_pin pmaMapping_addr_14 addr_reg\[1\]\[14\] 46
pmp_pin pmaMapping_addr_15 addr_reg\[1\]\[15\] 46
pmp_pin pmaMapping_addr_16 addr_reg\[1\]\[16\] 46
pmp_pin pmaMapping_addr_17 addr_reg\[1\]\[17\] 46
pmp_pin pmaMapping_addr_18 addr_reg\[1\]\[18\] 46
pmp_pin pmaMapping_addr_19 addr_reg\[1\]\[19\] 46
pmp_pin pmaMapping_addr_20 addr_reg\[1\]\[20\] 46
pmp_pin pmaMapping_addr_21 addr_reg\[1\]\[21\] 46
pmp_pin pmaMapping_addr_22 addr_reg\[1\]\[22\] 46
pmp_pin pmaMapping_addr_23 addr_reg\[1\]\[23\] 46
pmp_pin pmaMapping_addr_24 addr_reg\[1\]\[24\] 46
pmp_pin pmaMapping_addr_25 addr_reg\[1\]\[25\] 46
pmp_pin pmaMapping_addr_26 addr_reg\[1\]\[26\] 46
pmp_pin pmaMapping_addr_27 addr_reg\[1\]\[27\] 46
pmp_pin pmaMapping_addr_28 addr_reg\[1\]\[28\] 46
pmp_pin pmaMapping_addr_29 addr_reg\[1\]\[29\] 46
pmp_pin pmaMapping_addr_30 addr_reg\[1\]\[30\] 46
pmp_pin pmaMapping_addr_31 addr_reg\[1\]\[31\] 46
pmp_pin pmaMapping_mask_0 mask_reg\[1\]\[0\] 48
pmp_pin pmaMapping_mask_1 mask_reg\[1\]\[1\] 48
pmp_pin pmaMapping_mask_2 mask_reg\[1\]\[2\] 48
pmp_pin pmaMapping_mask_3 mask_reg\[1\]\[3\] 48
pmp_pin pmaMapping_mask_4 mask_reg\[1\]\[4\] 48
pmp_pin pmaMapping_mask_5 mask_reg\[1\]\[5\] 48
pmp_pin pmaMapping_mask_6 mask_reg\[1\]\[6\] 48
pmp_pin pmaMapping_mask_7 mask_reg\[1\]\[7\] 48
pmp_pin pmaMapping_mask_8 mask_reg\[1\]\[8\] 48
pmp_pin pmaMapping_mask_9 mask_reg\[1\]\[9\] 48
pmp_pin pmaMapping_mask_10 mask_reg\[1\]\[10\] 48
pmp_pin pmaMapping_mask_11 mask_reg\[1\]\[11\] 48
pmp_pin pmaMapping_mask_12 mask_reg\[1\]\[12\] 48
pmp_pin pmaMapping_mask_13 mask_reg\[1\]\[13\] 48
pmp_pin pmaMapping_mask_14 mask_reg\[1\]\[14\] 48
pmp_pin pmaMapping_mask_15 mask_reg\[1\]\[15\] 48
pmp_pin pmaMapping_mask_16 mask_reg\[1\]\[16\] 48
pmp_pin pmaMapping_mask_17 mask_reg\[1\]\[17\] 48
pmp_pin pmaMapping_mask_18 mask_reg\[1\]\[18\] 48
pmp_pin pmaMapping_mask_19 mask_reg\[1\]\[19\] 48
pmp_pin pmaMapping_mask_20 mask_reg\[1\]\[20\] 48
pmp_pin pmaMapping_mask_21 mask_reg\[1\]\[21\] 48
pmp_pin pmaMapping_mask_22 mask_reg\[1\]\[22\] 48
pmp_pin pmaMapping_mask_23 mask_reg\[1\]\[23\] 48
pmp_pin pmaMapping_mask_24 mask_reg\[1\]\[24\] 48
pmp_pin pmaMapping_mask_25 mask_reg\[1\]\[25\] 48
pmp_pin pmaMapping_mask_26 mask_reg\[1\]\[26\] 48
pmp_pin pmaMapping_mask_27 mask_reg\[1\]\[27\] 48
pmp_pin pmaMapping_mask_28 mask_reg\[1\]\[28\] 48
pmp_pin pmaMapping_mask_29 mask_reg\[1\]\[29\] 48
pmp_pin pmaMapping_mask_30 mask_reg\[1\]\[30\] 48
pmp_pin pmaMapping_mask_31 mask_reg\[1\]\[31\] 48
pmp_pin wdata_reg wdata_reg_reg 64
pmp_pin wen_reg_last_REG addr_wen_reg\[1\]\[22\] 1
pmp_pin wen_reg_last_REG_1 addr_wen_reg\[0\]\[25\] 1
pmp_pin wen_reg_last_REG_2 addr_wen_reg\[0\]\[30\] 1
pmp_pin wen_reg_last_REG_3 addr_wen_reg\[0\]\[4\] 1
pmp_pin wen_reg_last_REG_4 addr_wen_reg\[0\]\[7\] 1
pmp_pin wen_reg_last_REG_5 addr_wen_reg\[1\]\[3\] 1
pmp_pin wen_reg_last_REG_6 addr_wen_reg\[0\]\[18\] 1
pmp_pin wen_reg_last_REG_7 addr_wen_reg\[1\]\[7\] 1
pmp_pin wen_reg_last_REG_8 cfg_wen_reg\[1\]\[2\] 1
pmp_pin wen_reg_last_REG_9 addr_wen_reg\[0\]\[1\] 1
pmp_pin wen_reg_last_REG_10 cfg_wen_reg\[0\]\[1\] 1
pmp_pin wen_reg_last_REG_11 addr_wen_reg\[1\]\[28\] 1
pmp_pin wen_reg_last_REG_12 addr_wen_reg\[0\]\[29\] 1
pmp_pin wen_reg_last_REG_13 addr_wen_reg\[1\]\[18\] 1
pmp_pin wen_reg_last_REG_14 cfg_wen_reg\[0\]\[3\] 1
pmp_pin wen_reg_last_REG_15 addr_wen_reg\[1\]\[0\] 1
pmp_pin wen_reg_last_REG_16 addr_wen_reg\[0\]\[5\] 1
pmp_pin wen_reg_last_REG_17 addr_wen_reg\[1\]\[15\] 1
pmp_pin wen_reg_last_REG_18 addr_wen_reg\[0\]\[22\] 1
pmp_pin wen_reg_last_REG_19 addr_wen_reg\[1\]\[25\] 1
pmp_pin wen_reg_last_REG_20 addr_wen_reg\[0\]\[12\] 1
pmp_pin wen_reg_last_REG_21 addr_wen_reg\[1\]\[10\] 1
pmp_pin wen_reg_last_REG_22 addr_wen_reg\[1\]\[19\] 1
pmp_pin wen_reg_last_REG_23 addr_wen_reg\[1\]\[8\] 1
pmp_pin wen_reg_last_REG_24 addr_wen_reg\[0\]\[13\] 1
pmp_pin wen_reg_last_REG_25 addr_wen_reg\[0\]\[8\] 1
pmp_pin wen_reg_last_REG_26 addr_wen_reg\[1\]\[23\] 1
pmp_pin wen_reg_last_REG_27 addr_wen_reg\[1\]\[31\] 1
pmp_pin wen_reg_last_REG_28 addr_wen_reg\[0\]\[26\] 1
pmp_pin wen_reg_last_REG_29 addr_wen_reg\[1\]\[14\] 1
pmp_pin wen_reg_last_REG_30 cfg_wen_reg\[1\]\[0\] 1
pmp_pin wen_reg_last_REG_31 addr_wen_reg\[0\]\[9\] 1
pmp_pin wen_reg_last_REG_32 addr_wen_reg\[1\]\[4\] 1
pmp_pin wen_reg_last_REG_33 addr_wen_reg\[1\]\[9\] 1
pmp_pin wen_reg_last_REG_34 addr_wen_reg\[0\]\[21\] 1
pmp_pin wen_reg_last_REG_35 addr_wen_reg\[0\]\[31\] 1
pmp_pin wen_reg_last_REG_36 addr_wen_reg\[1\]\[24\] 1
pmp_pin wen_reg_last_REG_37 addr_wen_reg\[0\]\[14\] 1
pmp_pin wen_reg_last_REG_38 addr_wen_reg\[1\]\[5\] 1
pmp_pin wen_reg_last_REG_39 addr_wen_reg\[0\]\[3\] 1
pmp_pin wen_reg_last_REG_40 addr_wen_reg\[1\]\[1\] 1
pmp_pin wen_reg_last_REG_41 addr_wen_reg\[0\]\[20\] 1
pmp_pin wen_reg_last_REG_42 cfg_wen_reg\[0\]\[2\] 1
pmp_pin wen_reg_last_REG_43 addr_wen_reg\[0\]\[15\] 1
pmp_pin wen_reg_last_REG_44 addr_wen_reg\[1\]\[30\] 1
pmp_pin wen_reg_last_REG_45 addr_wen_reg\[1\]\[13\] 1
pmp_pin wen_reg_last_REG_46 addr_wen_reg\[0\]\[0\] 1
pmp_pin wen_reg_last_REG_47 cfg_wen_reg\[1\]\[3\] 1
pmp_pin wen_reg_last_REG_48 addr_wen_reg\[0\]\[24\] 1
pmp_pin wen_reg_last_REG_49 addr_wen_reg\[0\]\[27\] 1
pmp_pin wen_reg_last_REG_50 addr_wen_reg\[1\]\[20\] 1
pmp_pin wen_reg_last_REG_51 addr_wen_reg\[0\]\[10\] 1
pmp_pin wen_reg_last_REG_52 addr_wen_reg\[1\]\[21\] 1
pmp_pin wen_reg_last_REG_53 addr_wen_reg\[1\]\[6\] 1
pmp_pin wen_reg_last_REG_54 addr_wen_reg\[0\]\[17\] 1
pmp_pin wen_reg_last_REG_55 addr_wen_reg\[0\]\[19\] 1
pmp_pin wen_reg_last_REG_56 addr_wen_reg\[0\]\[2\] 1
pmp_pin wen_reg_last_REG_57 addr_wen_reg\[1\]\[12\] 1
pmp_pin wen_reg_last_REG_58 addr_wen_reg\[1\]\[17\] 1
pmp_pin wen_reg_last_REG_59 addr_wen_reg\[1\]\[2\] 1
pmp_pin wen_reg_last_REG_60 addr_wen_reg\[1\]\[27\] 1
pmp_pin wen_reg_last_REG_61 addr_wen_reg\[1\]\[11\] 1
pmp_pin wen_reg_last_REG_62 addr_wen_reg\[0\]\[23\] 1
pmp_pin wen_reg_last_REG_63 addr_wen_reg\[0\]\[6\] 1
pmp_pin wen_reg_last_REG_64 addr_wen_reg\[1\]\[16\] 1
pmp_pin wen_reg_last_REG_65 cfg_wen_reg\[1\]\[1\] 1
pmp_pin wen_reg_last_REG_66 addr_wen_reg\[0\]\[16\] 1
pmp_pin wen_reg_last_REG_67 addr_wen_reg\[0\]\[11\] 1
pmp_pin wen_reg_last_REG_68 addr_wen_reg\[1\]\[29\] 1
pmp_pin wen_reg_last_REG_69 cfg_wen_reg\[0\]\[0\] 1
pmp_pin wen_reg_last_REG_70 addr_wen_reg\[1\]\[26\] 1
pmp_pin wen_reg_last_REG_71 addr_wen_reg\[0\]\[28\] 1
puts "PMP_PIN_END PMP ok=$::PMP_PIN_OK bad=$::PMP_PIN_BAD"
if {$::PMP_PIN_BAD != 0} { error "PMP_PIN_MISS=$::PMP_PIN_BAD" }
if {$::PMP_PIN_OK != 6664} { error "PMP_PIN_COUNT=$::PMP_PIN_OK expect=6664" }
