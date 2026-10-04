# NewCSR FM「匹配后」钉点 —— 子模块 intrMod（InterruptFilter）里三族 iprios 条目寄存器的名字差
# ============================================================================
# 与 verif/ut/InterruptFilter/fm_pins.tcl 是同一件事（那份是 InterruptFilter 单独签核时用的，
# 判据、形状校验、fail-closed 逐条照搬），只是路径多了一层 NewCSR/intrMod/：
#   ref   r:/WORK/NewCSR/intrMod/<fam>Reg_<g>_<field>_reg[<b>]
#   impl  i:/WORK/NewCSR/intrMod/u_core/<fam>Reg_<field>_reg[<g>][<b>]
# InterruptFilter 重写件把 Reg(Vec(8, IpriosSort)) 按字段存成数组（SoA），golden 按组展平；
# 第 0/1/2/4/5/6/7 组的条目寄存器两侧都是常零寄存器，签名分析没有区分度、名字又对不上，
# 所以在父级 NewCSR 的证明里同样各留一批孤儿（lane 诊断跑实测 85(85)）。
# 只 set_user_match 消名差：不 dont_verify、不放宽 appvar、不约束、不扩黑盒。
# 钉上之后这批点被 FM 真去证（passing 应恰好增加孤儿数，unmatched 归 0）。
# 任一侧出现三族之外的孤儿点 -> 直接 error（不降级成"能钉几个算几个"）。
# ============================================================================

if {$top eq "NewCSR"} {

  if {[info commands report_unmatched_points] eq ""} {
    error "NEWCSR_INTRMOD_PIN: query verb report_unmatched_points unavailable - refuse to guess names"
  }

  # 结构清单上界：三族 iprios 条目数组寄存器的总位数（从 golden 的寄存器普查来）
  #   miprios  8*(idx6+enable1+isZero1+prioNum8) + greaterThan255 1 = 129
  #   hsiprios 同上                                                 = 129
  #   hviprios 8*(idx6+enable1+isZero1) + prioNum 8*7               = 120
  set _inventory 378

  set _rawref [lsort -unique [report_unmatched_points -reference      -list]]
  set _rawimp [lsort -unique [report_unmatched_points -implementation -list]]

  set _reRefArr {^r:/WORK/NewCSR/intrMod/(miprios|hsiprios|hviprios)Reg_([0-9]+)_(idx|enable|isZero|prioNum)_reg(\[([0-9]+)\])?$}
  set _reRefGt  {^r:/WORK/NewCSR/intrMod/(miprios|hsiprios)Reg_([0-9]+)_greaterThan255_reg$}
  set _reImpArr {^i:/WORK/NewCSR/intrMod/u_core/(miprios|hsiprios|hviprios)Reg_(idx|enable|isZero|prioNum)_reg\[([0-9]+)\](\[([0-9]+)\])?$}
  set _reImpGt  {^i:/WORK/NewCSR/intrMod/u_core/(miprios|hsiprios)Reg_greaterThan255_reg$}

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
    puts "NEWCSR_INTRMOD_PIN_FAIL: ref side has [llength $_oddref] orphan point(s) outside the 3 iprios families"
    foreach _x $_oddref { puts "    $_x" }
    incr _bad
  }
  if {[llength $_oddimp] != 0} {
    puts "NEWCSR_INTRMOD_PIN_FAIL: impl side has [llength $_oddimp] orphan point(s) outside the 3 iprios families"
    foreach _x $_oddimp { puts "    $_x" }
    incr _bad
  }
  set _kr [lsort [array names _R]]
  set _ki [lsort [array names _I]]
  if {$_kr ne $_ki} {
    puts "NEWCSR_INTRMOD_PIN_AUDIT: key sets (family,group,field,bit) differ between the two sides"
    foreach _k $_kr { if {![info exists _I($_k)]} { puts "    ref only : $_k -> $_R($_k)" } }
    foreach _k $_ki { if {![info exists _R($_k)]} { puts "    impl only: $_k -> $_I($_k)" } }
    incr _bad
  }
  if {$_bad != 0} {
    error "NEWCSR_INTRMOD_PIN_SHAPE: orphan set does not match the declared 3 families, refuse to pin (bad=$_bad)"
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
  puts "NEWCSR_INTRMOD_PIN: pinned $_n pair(s); orphans $_want; structural inventory upper bound $_inventory"

  if {[llength $_fail] != 0} {
    foreach _x $_fail { puts "NEWCSR_INTRMOD_PIN_MISS: $_x" }
    error "NEWCSR_INTRMOD_PIN_MISS: [llength $_fail] set_user_match call(s) returned 0 (names drifted?), refuse to continue"
  }
  if {$_want < 1} {
    error "NEWCSR_INTRMOD_PIN_EMPTY: zero orphans - this pin file is a no-op, the criterion is meaningless"
  }
  if {$_want > $_inventory} {
    error "NEWCSR_INTRMOD_PIN_OVERRUN: orphans $_want exceed structural inventory $_inventory - shape changed"
  }
  if {$_n != $_want} {
    error "NEWCSR_INTRMOD_PIN_COUNT: pinned $_n != orphans $_want"
  }
}
