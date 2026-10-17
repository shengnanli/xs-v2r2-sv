# ExuBlock FM「匹配后」钉点 —— 自动生成：scripts/gen_exublock.py gen_dyn_pins（勿手改）
#
# child 签核用的动态钉点文件（匹配后按 report_unmatched_points 现场配对、fail-closed）整份照搬，
# 只做两处机械替换：点名前缀 /WORK/<child 类型>/ -> /WORK/<本变体>/<实例名>/，守卫 $top eq "<child 类型>" -> 本变体。
#   exus_7（ExeUnit_7）<- verif/ut/ExeUnit_7/fm_pins.tcl：前缀替换 20 处，守卫 1 处

# ==== exus_7（ExeUnit_7）：verif/ut/ExeUnit_7/fm_pins.tcl 改前缀 ====
# ExeUnit_7 FM「匹配后」钉点 —— 自动生成：scripts/gen_exeunit.py gen_dyn_pins（勿手改）
#
# 子 FU 签核用的动态钉点文件（匹配后按 report_unmatched_points 现场配对、fail-closed）整份照搬，
# 只做两处机械替换：点名前缀 /WORK/<FU 类型>/ -> /WORK/<本变体>/<实例名>/，守卫 $top eq "<FU 类型>" -> 本变体。
# 族的定义、自检与 error 判据一字未改（见原文件头）。
#   csr（CSR）<- verif/ut/CSR/fm_pins.tcl：前缀替换 20 处，守卫 1 处

# ==== csr（CSR）：verif/ut/CSR/fm_pins.tcl 改前缀 ====
# CSR FM「匹配后」钉点 —— 四族名字差（全部是重写件里数组/生成块命名 vs golden 展平命名）
# ============================================================================
# 族 1  csrMod/intrMod（InterruptFilter）的 iprios 条目寄存器：同 verif/ut/InterruptFilter/fm_pins.tcl、
#       verif/ut/NewCSR/fm_pins.tcl，路径多两层 CSR/csrMod/。两侧都是常零寄存器，签名分析无区分度。
#         ref  r:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/<fam>Reg_<g>_<field>_reg[<b>]
#         impl i:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/u_core/<fam>Reg_<field>_reg[<g>][<b>]
# 族 2  csrMod 的 difftest 计数器溢出变化检测寄存器（每个计数器两份 RegNext，golden 展平成 58 个）：
#         ref  r:/WORK/ExuBlock/exus_7/csr/csrMod/diffMhpmeventOverflowEvent_valid_REG[_<n>]_reg   （n=0 时无后缀）
#         impl i:/WORK/ExuBlock/exus_7/csr/csrMod/overflow_fall_q_reg[<k>]（n=2k） / overflow_rise_q_reg[<k>]（n=2k+1）
#       golden 里 REG_2k 判下降、REG_2k+1 判上升（rtl/backend/NewCSR.sv §16 照留两份）；两份功能完全相同，
#       在 CSR 这层签名分析分不开（NewCSR 单独证明时靠签名配上了）。钉错了的后果是 FM 判不等价，不会静默放过。
# 族 3  imsic 里 9 个 IntFile 的 eidelivery 高 63 位（常零寄存器，两侧都在）：
#         ref  r:/WORK/ExuBlock/exus_7/csr/imsic/imsic/intFile[_<k>]/eidelivery_reg[<b>]          （k=0 时无后缀）
#         impl i:/WORK/ExuBlock/exus_7/csr/imsic/imsic/u_core/g_file[<k>].intFile/u_core/eidelivery_reg[<b>]
# 族 4  其余常零/同构寄存器在 CSR 这层签名分不开的几处（诊断跑实测各 18 点）：
#         csrMod/intrMod 的 delayedIntrVec_delay 链   ref …/delayedIntrVec_delay/REG[_<n>]_reg[<b>]
#                                                     impl …/u_core/delayedIntrVec_delay/u_core/g_chain.stage_reg[<n>][<b>]
#         imsic 9 个 IntFile 的 eies_0（第 0 字使能）  ref …/intFile[_<k>]/eies_0_reg[<b>]
#                                                     impl …/u_core/g_file[<k>].intFile/u_core/eies_reg[0][<b>]
#         csrMod 的跳转目标 raiseIGPF 保持位         ref …/io_out_bits_targetPc_r_raiseIGPF_reg
#                                                     impl …/target_igpf_q_reg
# 只 set_user_match 消名差：不 dont_verify、不放宽 appvar、不约束、不扩黑盒。
# fail-closed：两侧 key 集合必须完全相等；出现三族之外的孤儿点 -> error。
# ============================================================================

if {$top eq "ExuBlock"} {
  if {[info commands report_unmatched_points] eq ""} {
    error "CSR_PIN: query verb report_unmatched_points unavailable - refuse to guess names"
  }
  set _rawref [lsort -unique [report_unmatched_points -reference      -list]]
  set _rawimp [lsort -unique [report_unmatched_points -implementation -list]]

  set _reRefIp  {^r:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/(miprios|hsiprios|hviprios)Reg_([0-9]+)_(idx|enable|isZero|prioNum)_reg(\[([0-9]+)\])?$}
  set _reRefGt  {^r:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/(miprios|hsiprios)Reg_([0-9]+)_greaterThan255_reg$}
  set _reImpIp  {^i:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/u_core/(miprios|hsiprios|hviprios)Reg_(idx|enable|isZero|prioNum)_reg\[([0-9]+)\](\[([0-9]+)\])?$}
  set _reImpGt  {^i:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/u_core/(miprios|hsiprios)Reg_greaterThan255_reg$}
  set _reRefOv  {^r:/WORK/ExuBlock/exus_7/csr/csrMod/diffMhpmeventOverflowEvent_valid_REG(_([0-9]+))?_reg$}
  set _reImpOv  {^i:/WORK/ExuBlock/exus_7/csr/csrMod/overflow_(fall|rise)_q_reg\[([0-9]+)\]$}
  set _reRefEd  {^r:/WORK/ExuBlock/exus_7/csr/imsic/imsic/intFile(_([0-9]+))?/eidelivery_reg\[([0-9]+)\]$}
  set _reRefDl  {^r:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/delayedIntrVec_delay/REG(_([0-9]+))?_reg\[([0-9]+)\]$}
  set _reImpDl  {^i:/WORK/ExuBlock/exus_7/csr/csrMod/intrMod/u_core/delayedIntrVec_delay/u_core/g_chain\.stage_reg\[([0-9]+)\]\[([0-9]+)\]$}
  set _reRefEs  {^r:/WORK/ExuBlock/exus_7/csr/imsic/imsic/intFile(_([0-9]+))?/eies_0_reg\[([0-9]+)\]$}
  set _reImpEs  {^i:/WORK/ExuBlock/exus_7/csr/imsic/imsic/u_core/g_file\[([0-9]+)\]\.intFile/u_core/eies_reg\[0\]\[([0-9]+)\]$}
  set _refIgpf  {r:/WORK/ExuBlock/exus_7/csr/csrMod/io_out_bits_targetPc_r_raiseIGPF_reg}
  set _impIgpf  {i:/WORK/ExuBlock/exus_7/csr/csrMod/target_igpf_q_reg}
  set _reImpEd  {^i:/WORK/ExuBlock/exus_7/csr/imsic/imsic/u_core/g_file\[([0-9]+)\]\.intFile/u_core/eidelivery_reg\[([0-9]+)\]$}

  array set _R {}
  array set _I {}
  set _oddref {}
  set _oddimp {}
  foreach _p $_rawref {
    if {[regexp $_reRefIp $_p _all _fam _g _fld _b1 _b]} {
      if {$_b1 eq ""} { set _b 0 }
      set _R(ip|$_fam|$_g|$_fld|$_b) $_p
    } elseif {[regexp $_reRefGt $_p _all _fam _g]} {
      set _R(ip|$_fam|$_g|greaterThan255|0) $_p
    } elseif {[regexp $_reRefOv $_p _all _s _n]} {
      if {$_s eq ""} { set _n 0 }
      set _R(ov|$_n) $_p
    } elseif {[regexp $_reRefEd $_p _all _s _k _b]} {
      if {$_s eq ""} { set _k 0 }
      set _R(ed|$_k|$_b) $_p
    } elseif {[regexp $_reRefDl $_p _all _s _n _b]} {
      if {$_s eq ""} { set _n 0 }
      set _R(dl|$_n|$_b) $_p
    } elseif {[regexp $_reRefEs $_p _all _s _k _b]} {
      if {$_s eq ""} { set _k 0 }
      set _R(es|$_k|$_b) $_p
    } elseif {$_p eq $_refIgpf} {
      set _R(igpf) $_p
    } else {
      lappend _oddref $_p
    }
  }
  foreach _p $_rawimp {
    if {[regexp $_reImpIp $_p _all _fam _fld _g _b1 _b]} {
      if {$_b1 eq ""} { set _b 0 }
      set _I(ip|$_fam|$_g|$_fld|$_b) $_p
    } elseif {[regexp $_reImpGt $_p _all _fam]} {
      set _I(ip|$_fam|3|greaterThan255|0) $_p
    } elseif {[regexp $_reImpOv $_p _all _dir _k]} {
      set _n [expr {2 * $_k + ($_dir eq "rise" ? 1 : 0)}]
      set _I(ov|$_n) $_p
    } elseif {[regexp $_reImpEd $_p _all _k _b]} {
      set _I(ed|$_k|$_b) $_p
    } elseif {[regexp $_reImpDl $_p _all _n _b]} {
      set _I(dl|$_n|$_b) $_p
    } elseif {[regexp $_reImpEs $_p _all _k _b]} {
      set _I(es|$_k|$_b) $_p
    } elseif {$_p eq $_impIgpf} {
      set _I(igpf) $_p
    } else {
      lappend _oddimp $_p
    }
  }

  set _bad 0
  foreach {_side _lst} [list ref $_oddref impl $_oddimp] {
    if {[llength $_lst] != 0} {
      puts "CSR_PIN_ODD: $_side side has [llength $_lst] orphan point(s) outside the declared families"
      foreach _x $_lst { puts "    $_x" }
      incr _bad
    }
  }
  set _kr [lsort [array names _R]]
  set _ki [lsort [array names _I]]
  if {$_kr ne $_ki} {
    puts "CSR_PIN_AUDIT: key sets differ between the two sides"
    foreach _k $_kr { if {![info exists _I($_k)]} { puts "    ref only : $_k -> $_R($_k)" } }
    foreach _k $_ki { if {![info exists _R($_k)]} { puts "    impl only: $_k -> $_I($_k)" } }
    incr _bad
  }
  if {$_bad != 0} {
    error "CSR_PIN_SHAPE: orphan set does not match the declared families, refuse to pin (bad=$_bad)"
  }

  set _n 0
  set _want 0
  set _fail {}
  foreach _k $_kr {
    if {![info exists _I($_k)]} { continue }
    incr _want
    if {[set_user_match $_R($_k) $_I($_k)]} {
      incr _n
    } else {
      lappend _fail "$_k : $_R($_k) <-> $_I($_k)"
    }
  }
  puts "CSR_PIN: pinned $_n pair(s) of $_want"
  if {[llength $_fail] != 0} {
    foreach _x $_fail { puts "CSR_PIN_MISS: $_x" }
    error "CSR_PIN_MISS: [llength $_fail] set_user_match call(s) returned 0 (names drifted?), refuse to continue"
  }
  if {$_want < 1} {
    error "CSR_PIN_EMPTY: zero orphans - this pin file is a no-op"
  }
  if {$_n != $_want} {
    error "CSR_PIN_COUNT: pinned $_n != orphans $_want"
  }
}
