# Formality ç­ä»·æ§æ£æ¥éç¨èæ¬
# ç± scripts/ut_common.mk ç fm-% ç®æ è°ç¨ï¼ç»ç¯å¢åéä¼ åï¼
#   FM_TOP        é¡¶å±æ¨¡ååï¼golden åä½åï¼impl ä¾§åè£å±ä¸å¶åååç«¯å£ï¼
#   FM_REF_SRCS   golden RTL æä»¶åè¡¨ï¼åä½ + å¶å­æ¨¡åï¼
#   FM_IMPL_SRCS  æå SV æä»¶åè¡¨ï¼åæ°åæ ¸å¿ + åè£å±ï¼

set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# ----------------------------------------------------------------------------
# Step 3B sidecar emitter(FM_SIDECAR_OUT éç©ºæ¶å¯ç¨; å¥çº¦ = SIDECAR_SCHEMA.md v7 å»ç»ç):
# source åç«å³å¯¹å°è¢« source çæ¨¡åæ¬å° Tcl å**è¿è¡æ appvar æ¦æª**(set_app_var åå­
# ä¸å¨æ³¨åè¡¨ â exit 3, æäº§ native facts)ã
# ----------------------------------------------------------------------------
set SIDECAR_ON 0
if {[info exists env(FM_SIDECAR_OUT)] && [string trim $env(FM_SIDECAR_OUT)] ne ""} {
    set _entry [file normalize [info script]]
    set _emit  [file join [file dirname $_entry] sidecar fm_native_emit.tcl]
    source $_emit
    set SIDECAR_ON 1
    # 3Béªæ¶ä¸å®¡: script closure = **æ§è¡æ¶å»å­èå¿«ç§**(sidecar_register_script æè¢«
    # æ§è¡æä»¶çå­èå³æ¶æ·å¥ FM_SIDECAR_OUT å¹¶è¿½å æ¸å; source trace å¯¹åµå¥äº¦è§¦å,
    # è§£æ -encoding å½¢å¼)ãå¥å£ä¸ emitter é source è½½å¥, å¨æ­¤æ¾å¼ç»è®°å¿«ç§ã
    # appvar æ¦æª = execution trace å å¨å½ä»¤æ¬èº« + phase(match åå»ç»)+ ååå²ã
    set ::SIDECAR_SOURCED {}
    sidecar_register_script $_entry
    sidecar_register_script $_emit
    sidecar_install_appvar_guard
}

# ----------------------------------------------------------------------------
# FM_MODE é¨æ§(2026-07 å¯ä¸æå¨å¥å£, äºå®¡): è¯ææ¨¡å¼å³å®åè®¸åªäºæ¾å®½ææ®µã
#   signoff-strict(é»è®¤): ç¦ interface_only(assembly ä¸ç¨ææ®µ); ä¸¥æ ¼å¤å®äº¤ fm_verdict.pyã
#   assembly: åè®¸**å£°æçå¯¹ç§°é»ç** FM_INTERFACE_ONLY(ä»è¯æ¬å± glue)ã
#   diagnostic-full: ç± fm_eq_full.tcl æ¿æ(ELAB éçº§/æ¾å®½ä¸é), æ°¸ä¸ç­¾æ ¸ã
#   shadow: å strict(å¯è¯»æ ¸ä¸é©±å¨è¾åº, å¤å®å½ SHADOW_CHECK)ã
# è¯æ­è½åæ°¸ä¸è¿ signoff: strict ä¸ FM_INTERFACE_ONLY éç©ºå³æ¥ééåº(fail-closed)ã
# ----------------------------------------------------------------------------
set _fmmode "signoff-strict"
if {[info exists env(FM_MODE)]} { set _fmmode $env(FM_MODE) }
switch -- $_fmmode {
  "assembly" {
    if {[info exists env(FM_INTERFACE_ONLY)] && [string trim $env(FM_INTERFACE_ONLY)] ne ""} {
      set_app_var hdlin_interface_only $env(FM_INTERFACE_ONLY)
    }
  }
  "signoff-strict" - "shadow" {
    if {[info exists env(FM_INTERFACE_ONLY)] && [string trim $env(FM_INTERFACE_ONLY)] ne ""} {
      puts "FM_MODE_ERROR: $_fmmode æç» FM_INTERFACE_ONLY(assembly ä¸ç¨ææ®µ)"
      exit 3
    }
  }
  default {
    puts "FM_MODE_ERROR: æªç¥ FM_MODE=$_fmmode"
    exit 3
  }
}

# å¯å­å¨æ è§æµè·¯å¾ï¼å¦è¢« firtool è£åªçè¾åºå¯¹åºç validsï¼æ¶ä¸ä½ä¸ºæ¯å¯¹ç¹ã
# åä¸å®¡: unread å­åç»**æ¾å¼å¨éè®¾ç½®**(305 ç»ä¸å»ç»æ§è¡è¯­ä¹, ä¸è®©å·¥å·é»è®¤ä»£æ¿å£°æ;
# emitter äºå¨é¨ pin/custom Tcl æ§è¡åãverify åéé¡¹ get_app_var è¯»åææå¼)ã
# åä¸é¡¹ true å³å·¥å·é»è®¤(man cat3 éé¡µæ ¸å¯¹), æ¾å¼éæ­»é²çæ¬æ¼ç§»ã
set_app_var verification_verify_unread_compare_points false
set_app_var verification_verify_matched_unread_compare_points false
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true

# æªè§£ææ¨¡åï¼åå SRAM å¶å­ array_ext ç­å¤é¨å®ï¼èªå¨å½é»çââä¸¤ä¾§ä¸è´å³å¯ï¼
# SRAM åé¨å­å¨ä¸åä¸ wrapper é»è¾ç­ä»·æ¯å¯¹ã
set_app_var hdlin_unresolved_modules black_box

# åå¹¶ç±åä¸é»è¾é©±å¨çéå¤å¯å­å¨ï¼å¦å bank çè¯»å°åæåºå¤å¶ï¼æ¯ bank ä¸ä»½ã
# è¾åºçº§ä¸ä»½ï¼å¼å®å¨ç¸åï¼ãå¦åä¸¤ä¾§åæ N ä¸ªåå¼å¯å­å¨ï¼åå­ï¼å±å¹³ vs generate
# å±æ¬¡ï¼åç­¾åï¼å¼ç¸åï¼é½æ æ³éå¯¹ï¼å¯¼è´å¤§é unmatchedãFTQ/IFU ç­æåºå¤å¶
# æ®éå­å¨ï¼é»è®¤ trueã
# ä¹å®¡(3A.2 å®¡å®è¡¥ä¸3): è¯¥å¼ç± FM_MERGE_DUP å¥å£åéçå®ç»å®ââæ­¤å Makefile å£°æ
# FM_MERGE_DUP=false èè¿éç¡¬ç¼ç  true, manifest å£°ç§°å¼ä¸å®éè¯æè¯­ä¹è±è(fail-closed:
# éæ³å¼éåº, ä¸éé»åè½)ã
set _mergedup "true"
if {[info exists env(FM_MERGE_DUP)] && [string trim $env(FM_MERGE_DUP)] ne ""} {
    set _mergedup [string trim $env(FM_MERGE_DUP)]
}
switch -- $_mergedup {
  "true" - "false" { set_app_var verification_merge_duplicated_registers $_mergedup }
  default {
    puts "FM_MODE_ERROR: FM_MERGE_DUP éæ³å¼ $_mergedup"
    exit 3
  }
}

# Reference: Chisel çæç golden RTLï¼SYNTHESIS å³æéæºåå§å initial åï¼
read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

# Implementation: æå SV
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

# ----------------------------------------------------------------------------
# å­æ®µæ å°éå¯¹ï¼å¨é¦æ¬¡ match ä¹åå¨ééæ­»ï¼ï¼å½æåæ ¸å¿ææ´ä¸ª payload æåè¿ä¸ä¸ª
# æå¹³å¯å­å¨ data_regï¼è golden ç¨éå­æ®µå¯å­å¨ data_<suffix> æ¶ï¼ç­å®½å­æ®µä¼ä»¤ç­¾å
# åæäº§çæ­§ä¹ãä¸ä¼å¨éæ° match æ¶äºç¸æä¹±ãçæå¨è¾åºã<suffix> <lo> <width>ã
# æ å°ï¼FM_FIELD_MAPï¼ï¼è¿éæ®æ­¤æ ref ç data_<suffix>_reg[b] éä½ set_user_match
# å° impl ç u_core/data_reg[lo+b]ï¼ä½¿åç»­ match åªéå¤ç valid ç­é payload å¯å­å¨ã
# ä¾ PipelineConnect ååç»­æå¹³ payload æ¨¡åå¤ç¨ã
# ----------------------------------------------------------------------------
proc match_packed_payload { top } {
    if {![info exists ::env(FM_FIELD_MAP)] || ![file exists $::env(FM_FIELD_MAP)]} return
    set fh [open $::env(FM_FIELD_MAP) r]
    set n 0
    foreach ln [split [read $fh] "\n"] {
        if {![regexp {^(\S+)\s+(\d+)\s+(\d+)$} $ln -> suf lo w]} continue
        for {set b 0} {$b < $w} {incr b} {
            set ipath "i:/WORK/$top/u_core/data_reg\[[expr {$lo + $b}]\]"
            # å¤ä½å­æ®µ golden åä¸º data_<suf>_reg[b]ï¼1 ä½å­æ®µå¯è½æ ä¸æ 
            set cands [list "r:/WORK/$top/data_${suf}_reg\[$b\]"]
            if {$w == 1} { lappend cands "r:/WORK/$top/data_${suf}_reg" }
            foreach rpath $cands {
                if {![catch {set_user_match $rpath $ipath}]} { incr n; break }
            }
        }
    }
    close $fh
    if {$n > 0} { puts "PACKED_MATCH: $n points pinned" }
}
# æ¨¡åæ¬å°ãå¹éåãéç¹(FM_PIN_PRE_TCL, å¯é): é¦æ¬¡ match åé set_user_match çå¯¹è±¡ã
# åå®¡: sidecar ä¸ pin ä»£ç è¿åé safe child interp(sidecar_pin_source: ä¸æ¬¡è¯»åâå¿«ç§
# âchild æ§è¡åä¸ç¼å²; æ¿ä¸å°ç¶å± guard/trace/è¯æ®ç®å½; åµå¥ source èµ°åä¸åæ§å¥å£)ã
if {[info exists env(FM_PIN_PRE_TCL)] && [file exists $env(FM_PIN_PRE_TCL)]} {
    if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_PRE_TCL) } else { source $env(FM_PIN_PRE_TCL) }
}
match_packed_payload $top

match

# ----------------------------------------------------------------------------
# èªå¨éå¯¹ Chisel å±å¹³å½åä¸ SV æ°ç»å½åçå¯å­å¨ï¼
#   ref:  name_1_0_reg / array_0_reg[2]   ï¼firtool æ Vec å±å¹³æå¸¦ä¸æ åç¼çæ éåï¼
#   impl: name_reg[1][0] / array_reg[0][2]ï¼SV æ°ç»å¯å­å¨ï¼
# åå­è¿æ»¤å¹éä¸äºè¿ç§ç»æå·®å¼ï¼æ¡ç®é´é»è¾å¯¹ç§°æ¶ç­¾ååæä¹å¸¸å¤±è´¥ï¼å æ­¤æ
# å½åè§åæ¾å¼ set_user_matchãimpl è·¯å¾ä¼ä¾æ¬¡å°è¯ï¼åå±æ¬¡ãé¡¶å±ä¸æå¥
# u_coreï¼åä½åè£å±ä¾ååæ°åæ ¸å¿çåºå®å®ä¾åï¼ã
# ----------------------------------------------------------------------------
proc auto_match_flattened_arrays { top } {
    redirect -variable um_txt {report_unmatched_points}

    # æ¶éä¸¤ä¾§æªå¹é DFFï¼impl ä¾§å»ºç«ãå±å¹³ç­ä»·å â å®éè·¯å¾ãæ¥æ¾è¡¨ã
    # å±å¹³ç­ä»·å = å»æ i:/WORK/<top> åç¼å u_core å±æ¬¡ãæ°ç»ä¸æ æ¹æ _i åç¼ï¼
    # ä¸ ref ä¾§ç firtool å±å¹³å¶å­ååæï¼å¯ç´æ¥å­ç¬¦ä¸²æ¯å¯¹ã
    array set impl_lut {}
    set refs {}
    foreach line [split $um_txt "\n"] {
        if {[regexp {Ref\s+DFF\S*\s+(r:\S+)} $line -> rpath]} {
            lappend refs $rpath
        } elseif {[regexp {Impl\s+DFF\S*\s+(i:\S+)} $line -> ipath]} {
            set rel $ipath
            regsub "^i:/WORK/${top}/" $rel "" rel
            regsub "^u_core/" $rel "" rel
            # name_reg[1][0] -> name_1_0_regï¼ä¿çæåä¸ä¸ªä½ä¸æ ï¼å¤ä½å¯å­å¨ï¼
            set key $rel
            regexp {^(.*?)((?:\[\d+\])*)$} $rel -> stem bits
            set idxs ""
            set blist [regexp -all -inline {\d+} $bits]
            if {[regexp {^(.*)_reg$} $stem -> nm]} {
                # ä½ä¸æ ä¸ªæ°ä¸ ref ä¾§å¶å­çå±å¹³ç»´åº¦ç±åå­æ¯å¯¹èªç¶å¯¹é½ï¼
                # åå¨è½¬æ name_i_j_reg å½¢å¼ï¼åå¨æ¯å¯¹æ¶åè®¸ ref å¸¦ä¸ä¸ª [bit] å°¾å·´
                foreach b $blist { append idxs "_$b" }
                set key "${nm}${idxs}_reg"
            }
            set impl_lut($key) $ipath
        }
    }

    set n 0
    foreach rpath $refs {
        set leaf [file tail $rpath]
        set dir  [file dirname $rpath]
        regsub "^r:/WORK/${top}" $dir "" relhier
        regsub {^/} $relhier "" relhier
        # ref å¶å­å¯è½å¸¦ä½ä¸æ å°¾å·´ï¼array_0_reg[2]
        regexp {^(.*?)((?:\[\d+\])*)$} $leaf -> base bit
        set bitidx ""
        foreach b [regexp -all -inline {\d+} $bit] { set bitidx "_$b" }
        # åé keyï¼æ ref å±å¹³åï¼å«å¯éä½ä¸æ ï¼è§çº¦æ name_i_j_reg
        set cand ""
        if {[regexp {^(.*)_reg$} $base -> nm]} {
            set cand "${nm}${bitidx}_reg"
        }
        set hit ""
        foreach key [list $cand $base] {
            if {$key ne "" && [info exists impl_lut($key)]} { set hit $key; break }
        }
        if {$hit eq ""} { puts "AUTO_MATCH_FAIL: $rpath"; continue }
        set ipath $impl_lut($hit)
        if {[catch {set_user_match $rpath $ipath} msg]} {
            puts "AUTO_MATCH_FAIL: $rpath <-> $ipath ($msg)"
        } else {
            puts "AUTO_MATCH: $rpath <-> $ipath"
            unset impl_lut($hit)
            incr n
        }
    }
    if {$n > 0} { match }
}
auto_match_flattened_arrays $top

# æ¨¡åæ¬å°ãå¹éåãéç¹(FM_PIN_TCL, å¯é): å±æ¬¡/å¶åå·®å¼çä¸ä¸å¯¹åº(åª set_user_match, ä¸çº¦æ ref)ã
if {[info exists env(FM_PIN_TCL)] && [file exists $env(FM_PIN_TCL)]} {
    if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_TCL) } else { source $env(FM_PIN_TCL) }
    match
}

report_unmatched_points > fm_work/$top/unmatched.rpt
report_matched_points > fm_work/$top/matched.rpt

# sidecar: appvar ææå¼è¯»åââå¨é¨ pin/custom Tcl ä¹åãverify ä¹å(schema v7 å¥çº¦)
if {$SIDECAR_ON} { sidecar_capture_appvars }

if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top"
} else {
    report_failing_points > fm_work/$top/failing.rpt
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"
}
# sidecar: å¨æ¥è¯¢âåå­è§£æâåå­å native_facts.json(ä»»ä½éè¯¯å  tmp å¹¶ exit 4)
if {$SIDECAR_ON} { sidecar_emit $top }
exit
