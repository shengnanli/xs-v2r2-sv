# InterruptFilter FM「匹配后」钉点 —— 三族 iprios 条目数组寄存器的名字差
# ============================================================================
# 【本文件解决什么】
#   第二跑（commit 55468572，FM_MERGE_DUP=false，未钉点）：
#       native SUCCEEDED / passing 440 / failing 0 / unverified 0 / aborted 0 /
#       黑盒 0 / 无 dont_verify；Not Compared: Constant reg 53
#   只剩一行拦着：
#       85(85) Unmatched reference(implementation) compare points
#   即 fm_verdict.py 的 strict_unmatched!=0 -> PARTIAL。
#
#   这 85(85) 点全部是三族 iprios 条目寄存器，名字差只有一个来源：
#       ref   firtool 把 Reg(Vec(8, IpriosSort)) 展平成  <fam>Reg_<g>_<field>
#       impl  可读核按 per-field 数组存（CONVENTIONS 要求 SoA） <fam>Reg_<field>[<g>]
#   外加 impl 侧多一层 u_core。**结构上没有自由度**：下标就是组号 g，字段名同名，
#   位下标同号。fm_eq.tcl 自带的 auto_match_flattened_arrays 处理的是
#   `name_i_j_reg` <-> `name_reg[i][j]` 那种形状（下标在**末尾**），
#   而这里下标在**字段名中间**，规则对不上，所以它逐条 AUTO_MATCH_FAIL。
#
# 【为什么两侧都配不上、却又一定是双射】
#   这批点是 M 级（miprios）第 0/1/2/4/5/6/7 组的条目寄存器。mip 只有 11 个端口
#   （中断号 1..13），没有任何 >=14 的位，于是这些组里每一条目的 enable 恒 0，
#   整条目归零 —— 两侧都是常零寄存器（ref 报 DFF0X、impl 报 DFF0）。
#   常零寄存器的次态函数是常量，**签名分析没有区分度**，名字又对不上，
#   于是两侧各留一批孤儿。golden 保留这些常零寄存器是 firtool 的 pass 顺序决定的
#   （见 rtl/backend/InterruptFilter.sv §5 的说明），可读核照搬了同一套字段集合，
#   所以两侧一一对得上。
#
#   ★双射是**离线核对过**的，不是"数目一样就认"★：把两侧 85 个路径各自按
#   (族, 组号, 字段, 位号) 规约成 key，两个 key 集合完全相等（85 = 85，
#   差集两边都为空）。下面的形状校验把同一条判据搬进 Tcl 现场再算一遍。
#
# 【只做一件事】
#   只 set_user_match 消名差。不 dont_verify、不放宽 appvar、不约束 ref、不扩黑盒。
#   钉上之后这 85 点从"未配"变成"已配"，FM 真去证它们。
#   ★判据是 passing 必须 440 -> 525（恰好 +85）、failing 仍 0、unmatched 归 0★
#   —— passing 不增而 unmatched 归 0 = 点被吞掉，不算过。
#   钉错的后果是 FM 判不等价（响亮失败），不是静默放过，方向上是安全的。
#
# 【fail-closed】
#   下面每一步不满足就 error 退出，绝不降级成"能钉几个算几个"：
#     · 查询动词缺失
#     · 任一侧出现不符合三族形状的孤儿点
#     · 两侧 key 集合不相等（不是"数目一样"）
#     · 孤儿点数超出结构清单上界，或为 0（空转）
#     · 任何一条 set_user_match 返回 0（用**返回值**计数，不是 catch —— 判据 P4）
# ============================================================================

if {$top eq "InterruptFilter"} {

  if {[info commands report_unmatched_points] eq ""} {
    error "IF_PIN: 只读查询动词 'report_unmatched_points' 不可用 —— 拒绝硬猜名字"
  }

  # 结构清单上界：三族 iprios 条目数组寄存器的总位数（从 golden 的寄存器普查来）
  #   miprios  8*(idx6+enable1+isZero1+prioNum8) + greaterThan255 1 = 129
  #   hsiprios 同上                                                 = 129
  #   hviprios 8*(idx6+enable1+isZero1) + prioNum 8*7               = 120
  set _inventory 378

  set _rawref [lsort -unique [report_unmatched_points -reference      -list]]
  set _rawimp [lsort -unique [report_unmatched_points -implementation -list]]

  set _reRefArr {^r:/WORK/InterruptFilter/(miprios|hsiprios|hviprios)Reg_([0-9]+)_(idx|enable|isZero|prioNum)_reg(\[([0-9]+)\])?$}
  set _reRefGt  {^r:/WORK/InterruptFilter/(miprios|hsiprios)Reg_([0-9]+)_greaterThan255_reg$}
  set _reImpArr {^i:/WORK/InterruptFilter/u_core/(miprios|hsiprios|hviprios)Reg_(idx|enable|isZero|prioNum)_reg\[([0-9]+)\](\[([0-9]+)\])?$}
  set _reImpGt  {^i:/WORK/InterruptFilter/u_core/(miprios|hsiprios)Reg_greaterThan255_reg$}

  array set _R {}
  array set _I {}
  set _oddref {}
  set _oddimp {}

  foreach _p $_rawref {
    if {[regexp $_reRefArr $_p _all _fam _g _fld _b1 _b]} {
      if {$_b1 eq ""} { set _b 0 }
      set _R($_fam|$_g|$_fld|$_b) $_p
    } elseif {[regexp $_reRefGt $_p _all _fam _g]} {
      set _R($_fam|$_g|greaterThan255|0) $_p
    } else {
      lappend _oddref $_p
    }
  }
  foreach _p $_rawimp {
    if {[regexp $_reImpArr $_p _all _fam _fld _g _b1 _b]} {
      if {$_b1 eq ""} { set _b 0 }
      set _I($_fam|$_g|$_fld|$_b) $_p
    } elseif {[regexp $_reImpGt $_p _all _fam]} {
      set _I($_fam|3|greaterThan255|0) $_p
    } else {
      lappend _oddimp $_p
    }
  }

  set _bad 0
  if {[llength $_oddref] != 0} {
    puts "IF_PIN_FAIL(golden 侧出现三族之外的孤儿点): [llength $_oddref] 个"
    foreach _x $_oddref { puts "    $_x" }
    incr _bad
  }
  if {[llength $_oddimp] != 0} {
    puts "IF_PIN_FAIL(可读核侧出现三族之外的孤儿点): [llength $_oddimp] 个"
    foreach _x $_oddimp { puts "    $_x" }
    incr _bad
  }
  set _kr [lsort [array names _R]]
  set _ki [lsort [array names _I]]
  if {$_kr ne $_ki} {
    puts "IF_PIN_AUDIT: 两侧 (族,组,字段,位) key 集合不相等"
    foreach _k $_kr { if {![info exists _I($_k)]} { puts "    golden 独有: $_k -> $_R($_k)" } }
    foreach _k $_ki { if {![info exists _R($_k)]} { puts "    可读核独有: $_k -> $_I($_k)" } }
    incr _bad
  }
  if {$_bad != 0} {
    error "IF_PIN_SHAPE: 孤儿点集合与三族声明不符，拒绝钉点（bad=$_bad）"
  }

  set _want [array size _R]

  set _n 0
  set _fail {}
  foreach _k $_kr {
    if {[set_user_match $_R($_k) $_I($_k)]} {
      incr _n
    } else {
      lappend _fail "$_k : $_R($_k) <-> $_I($_k)"
    }
  }
  puts "IF_PIN: 钉点 $_n 对（孤儿点 $_want 对，结构清单上界 $_inventory）"

  if {[llength $_fail] != 0} {
    foreach _x $_fail { puts "IF_PIN_MISS: $_x" }
    error "IF_PIN_MISS: [llength $_fail] 条 set_user_match 返回 0（名字漂了？），拒绝带伤继续"
  }
  if {$_want < 1} {
    error "IF_PIN_EMPTY: 孤儿点为 0 —— 本文件在空转，钉点判据失去意义"
  }
  if {$_want > $_inventory} {
    error "IF_PIN_OVERRUN: 孤儿点 $_want 超出结构清单上界 $_inventory —— 形状变了"
  }
  if {$_n != $_want} {
    error "IF_PIN_COUNT: 钉上 $_n != 孤儿点 $_want"
  }
}
