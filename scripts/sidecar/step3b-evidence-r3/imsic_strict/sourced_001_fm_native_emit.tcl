# fm-sidecar-native-v1 åå­ emitter(Step 3B, å¥çº¦=SIDECAR_SCHEMA.md v7å»ç»ç, 180c1a1)ã
# ç± fm_eq.tcl å¨ FM_SIDECAR_OUT éç©ºæ¶ sourceãèè´£:
#   â  è¿è¡æ appvar æ¦æª: source pin/custom Tcl åæ«æå¶ set_app_var, ä¸å¨æ³¨åè¡¨ â exit 3
#      (æäº§ native facts, ééæ grepââåçå¨ä¼è¯è¿è¡æ)ã
#   â¡ appvar ææå¼è¯»å: å¨é¨ pin/custom Tcl åãverify åéé¡¹ get_app_varã
#   â¢ verify åå¨æ¥è¯¢âåå­è§£æâJSONâç¬å  tmp åå»ºâflush/closeâno-force rename;
#      ä»»ä½éè¯¯å  tmp å¹¶ exit 4(æ é¨åäº§ç©)ã
# æ¬æä»¶ç bbox è§£æå¨ä¸ºçº¯ Tcl(ä¸ä¾èµ fm å½ä»¤), ä¾ tclsh fixture æµè¯(acceptance gate 1)ã

# ---------------- æ³¨åè¡¨(ä¸ validator APPVAR_SPEC é®é¢ä¸è´) ----------------
set SIDECAR_APPVAR_REQUIRED {
    verification_verify_unread_compare_points
    verification_verify_matched_unread_compare_points
    verification_verify_unread_bbox_inputs
    verification_verify_matched_unread_bbox_inputs
    verification_verify_unread_tech_cell_pins
    verification_verify_unread_tech_cell_pg_pins
    hdlin_unresolved_modules
    hdlin_interface_only
    verification_merge_duplicated_registers
}
set SIDECAR_APPVAR_OPTIONAL {
    verification_assume_reg_init
    verification_set_undriven_signals
    verification_propagate_const_reg_x
    verification_blackbox_match_mode
}
set SIDECAR_APPVAR_DIAG_ONLY { verification_failing_point_limit }
# æ¾å®½åºçº¿(éé»è®¤å¼ â relaxed_appvars; ci é¡¹å­å°å)
array set SIDECAR_APPVAR_DEFAULT {
    verification_assume_reg_init        auto
    verification_set_undriven_signals   BINARY:X
    verification_propagate_const_reg_x  false
    verification_blackbox_match_mode    any
}
set SIDECAR_EXTRA_KEYS {}   ;# æ¦æªæ«æä¸­åç°çæ³¨åè¡¨åå¯éé®(ä¼è¢«è¯»åå¹¶å¥ entry_appvars)

# ---------------- â  æ§è¡æ appvar æ¦æª(3B éªæ¶äºå®¡éå) ----------------
# ä¸å®¡ rename+wrapper è¢«è£å®å¯ç»è¿(æ´é²çåçå«å __sidecar_real_set_app_var å¯ç´å¼,
# çæå´ä¸è¿ readback/history)ãäºå®¡æ¹ä¸º **execution trace å å¨å½ä»¤æ¬èº«**:
#   trace add execution set_app_var enter ââ æ è®º wrapper/å«å/å¨æå/eval/åµå¥ source,
#   ä»»ä½çå®æ§è¡é½è§¦å trace(ä¸åå­å¨æ´é²çæè·¯å½ä»¤)ã
# å¹¶å  phase/ååå²çº¦æ:
#   - é¦æ¬¡ match ä¹åç¦æ­¢åæ¹ proof appvar(phase_violation)ââå µ"åæ¾å®½ãmatchãåæ¢å¤"ã
#   - åååå¼éå â æ(rewrite_changed_value); åå¼å¹ç­éåæ¾è¡ã
#   - readback(capture)æ¶éé¡¹æ ¸å¯¹ get_app_var == ååå²æ«å¼(history_mismatch æ)ã
proc sidecar_intercept_fail {reason} {
    puts "SIDECAR_ERROR: runtime_appvar_intercept $reason (execution-trace)"
    exit 3
}
proc sidecar_appvar_trace {cmd op} {
    set name [lindex $cmd 1]; set val [lindex $cmd 2]
    set allowed [concat $::SIDECAR_APPVAR_REQUIRED $::SIDECAR_APPVAR_OPTIONAL \
                        $::SIDECAR_APPVAR_DIAG_ONLY]
    if {[lsearch -exact $allowed $name] < 0} {
        sidecar_intercept_fail "not-in-registry:$name"; return
    }
    if {$::SIDECAR_PHASE ne "setup"} {
        sidecar_intercept_fail "phase_violation_after_match:$name"; return
    }
    if {[info exists ::SIDECAR_AV_HISTORY($name)] && $::SIDECAR_AV_HISTORY($name) ne $val} {
        sidecar_intercept_fail "rewrite_changed_value:$name"; return
    }
    set ::SIDECAR_AV_HISTORY($name) $val
    if {[lsearch -exact $::SIDECAR_APPVAR_REQUIRED $name] < 0 &&
        [lsearch -exact $::SIDECAR_EXTRA_KEYS $name] < 0} {
        lappend ::SIDECAR_EXTRA_KEYS $name
    }
}
proc sidecar_match_trace {cmd op} { set ::SIDECAR_PHASE matched }
# ä¸å®¡: script closure è®°è´¦ = **æ§è¡æ¶å»å­èå¿«ç§**(æ¶é¤"æ§è¡Aãäºååå¸B"ç TOCTOU):
# æ¯æ¬¡ source å¨ enter-trace æ¶æç®æ æä»¶å­èåæ ·æ·å¥ $FM_SIDECAR_OUT/sourced_NNN_<name>,
# å¹¶å³æ¶è¿½å  script_closure.list è¡(orig<TAB>snapshot)ãrunner åªå¯¹å¿«ç§å­èå digestã
# æäº§ä¼è¯(æ¦æª exit)ä¹å·²çä¸å¥å£/emitter/pin çå¿«ç§ã
proc sidecar_snapshot_buffer {origpath buf} {
    # å¿«ç§è½ç + å³æ¶æ¸å + **ç¶è§£éå¨åå­å°è´¦**(child ä¸å¯è¾¾; capture åå¤æ ¸)
    if {![info exists ::env(FM_SIDECAR_OUT)] || $::env(FM_SIDECAR_OUT) eq ""} return
    set out $::env(FM_SIDECAR_OUT)
    if {![info exists ::SIDECAR_SRC_SEQ]} { set ::SIDECAR_SRC_SEQ 0 }
    set snap [format "sourced_%03d_%s" $::SIDECAR_SRC_SEQ [file tail $origpath]]
    incr ::SIDECAR_SRC_SEQ
    set fh [open "$out/$snap" wb]
    puts -nonewline $fh [encoding convertto utf-8 $buf]
    close $fh
    set fh [open "$out/script_closure.list" a]
    puts $fh "$origpath\t$snap"; close $fh
    lappend ::SIDECAR_LEDGER [list $snap $buf]
    lappend ::SIDECAR_SOURCED $origpath
}
proc sidecar_register_script {path} {
    set p [file normalize $path]
    set in [open $p r]; set buf [read $in]; close $in
    sidecar_snapshot_buffer $p $buf
}
proc sidecar_source_trace {cmd op} {
    # ä¸å®¡: è§£æä¸¤ç§åæ³å½¢å¼ `source file` / `source -encoding enc file`(æä»¶å=æ«å),
    # ä¸ååºå®ååæ°1(é£ä¼æ -encoding è®°æè·¯å¾)ã(ç¶å± source ä»å¥å£èªèº«ä½¿ç¨)
    sidecar_register_script [lindex $cmd end]
}
# ---------------- åå®¡: pin/custom Tcl è¿åé child interpreter ----------------
# åè§£éå¨æ§è¡è¢«è£å®å¯æé¤ guard(set ::SIDECAR_PHASE / trace remove)å¹¶è¦çå¿«ç§ã
# ç° pin ä»£ç å¨ **safe child interp** ä¸­æ§è¡: æ  file/open/exec/source æé, æ¿ä¸å°
# ç¶å± globals/trace/rename ç®¡çæä¸è¯æ®ç®å½; ç½åå alias åªæ´é²
# set_user_match / set_app_var(ç¶å± trace ç§å¸¸æ¦)/ get_app_var / putsã
# åæ§ source: **ä¸æ¬¡è¯»åå­è â å¿«ç§ â å¨ child æ§è¡åä¸ç¼å²**(ä¸åäºæ¬¡æå¼åè·¯å¾);
# åµå¥ source ç» alias èµ°åä¸åæ§å¥å£ã
proc sidecar_pin_source {path} {
    if {![info exists ::SIDECAR_PIN_INTERP]} {
        set ::SIDECAR_PIN_INTERP [interp create -safe]
        # ç½åå alias: åªæ´é²è¯æç¸å³ç fm å½ä»¤(safe interp å·²éè file/open/exec/socket)
        foreach c {set_user_match set_app_var get_app_var puts report_unmatched_points \
                   report_matched_points set_constant remove_constant} {
            if {[info commands $c] ne ""} {
                interp alias $::SIDECAR_PIN_INTERP $c {} $c
            }
        }
        interp alias $::SIDECAR_PIN_INTERP source {} sidecar_pin_source
        # pin ä»£ç å¼ç¨çåªè¯»ä¸ä¸æåé(top ç­); åªä¼ å¼, ä¸ç»ç¶å±å½åç©ºé´è®¿é®æ
        if {[uplevel #0 {info exists top}]} {
            interp eval $::SIDECAR_PIN_INTERP [list set top [uplevel #0 {set top}]]
        }
    }
    set p [file normalize $path]
    set in [open $p r]; set buf [read $in]; close $in
    sidecar_snapshot_buffer $p $buf
    interp eval $::SIDECAR_PIN_INTERP $buf
}
proc sidecar_verify_snapshot_ledger {} {
    # åå®¡: æ§è¡å® pin åå¤æ ¸ââå¿«ç§æä»¶å­èä¸ç¶åå­å°è´¦ä¸è´, æ¸åè¡æ°ä¸è´
    if {![info exists ::env(FM_SIDECAR_OUT)] || $::env(FM_SIDECAR_OUT) eq ""} return
    set out $::env(FM_SIDECAR_OUT)
    if {![info exists ::SIDECAR_LEDGER]} { set ::SIDECAR_LEDGER {} }
    foreach ent $::SIDECAR_LEDGER {
        lassign $ent snap buf
        if {![file exists "$out/$snap"]} { sidecar_intercept_fail "snapshot_missing:$snap" }
        set in [open "$out/$snap" rb]; set got [read $in]; close $in
        if {$got ne [encoding convertto utf-8 $buf]} {
            sidecar_intercept_fail "snapshot_tampered:$snap"
        }
    }
    set in [open "$out/script_closure.list" r]; set lst [read $in]; close $in
    set nl [llength [lsearch -all -regexp [split $lst "\n"] {\S}]]
    if {$nl != [llength $::SIDECAR_LEDGER]} {
        sidecar_intercept_fail "closure_list_tampered:${nl}!=[llength $::SIDECAR_LEDGER]"
    }
}
proc sidecar_install_appvar_guard {} {
    if {[info exists ::SIDECAR_GUARD_ON]} return
    set ::SIDECAR_GUARD_ON 1
    set ::SIDECAR_PHASE setup
    array set ::SIDECAR_AV_HISTORY {}
    trace add execution set_app_var enter sidecar_appvar_trace
    trace add execution source enter sidecar_source_trace
    if {[info commands match] ne ""} { trace add execution match enter sidecar_match_trace }
}

# ---------------- â¡ ææå¼è¯»å(verify å)+ ååå²/å¿«ç§å°è´¦ä¸è´æ§æ ¸å¯¹ ----------------
proc sidecar_capture_appvars {} {
    sidecar_verify_snapshot_ledger
    foreach k [concat $::SIDECAR_APPVAR_REQUIRED $::SIDECAR_EXTRA_KEYS] {
        set ::SIDECAR_AV($k) [get_app_var $k]
    }
    # äºå®¡: readback å¿é¡»ä¸å·²è®°å½åå¥ä¸è´(trace ä¹å¤ä¸å¯è½æåå¥; æ­¤æ ¸å¯¹æ¯çºµæ·±é²å¾¡)
    foreach k [array names ::SIDECAR_AV_HISTORY] {
        if {[get_app_var $k] ne $::SIDECAR_AV_HISTORY($k)} {
            sidecar_intercept_fail "appvar_history_mismatch:$k"
        }
    }
}

# ---------------- JSON ç¼ç (æå, è½¬ä¹ \ " ä¸æ§å¶å­ç¬¦) ----------------
proc sidecar_jstr {s} {
    set out ""
    foreach ch [split $s ""] {
        scan $ch %c code
        if {$ch eq "\\"} { append out "\\\\" } \
        elseif {$ch eq "\""} { append out "\\\"" } \
        elseif {$code < 0x20} { append out [format "\\u%04x" $code] } \
        else { append out $ch }
    }
    return "\"$out\""
}
proc sidecar_jlist {lst} {
    set parts {}
    foreach e $lst { lappend parts [sidecar_jstr $e] }
    return "\[[join $parts ,]\]"
}
proc sidecar_jpairs {pairs} {
    # pairs: å·²æåºç {ref impl} åè¡¨
    set parts {}
    foreach p $pairs {
        lappend parts "{\"ref_path\":[sidecar_jstr [lindex $p 0]],\"impl_path\":[sidecar_jstr [lindex $p 1]]}"
    }
    return "\[[join $parts ,]\]"
}

# ---------------- bbox æ¥åè§£æ(çº¯ Tcl, FM-184 ç¶ææº, fail-closed) ----------------
# è¿å 6 åç´ åè¡¨: iface_ref iface_impl unres_ref unres_impl empty_ref empty_impl
# éè¯¯ä»¥ error æåº(è°ç¨æ¹å³å®å  tmp/exit)ãå¥çº¦(v7): FM-184 å¿é¡»å­å¨; FM-249 å¯å±å­
# =ç©ºé(ä¸å¾æå®ä¾å); éç©ºä¸å¾æ FM-249; flag åªè®¤ i/u/e; Instances N==M ä¸ç²¾ç¡®æ¶è´¹ N æ¡ã
# ä¸¥æ ¼ phase ææ³ç¶ææº(3B éªæ¶äºå®¡éå)ãä¸åå"å¨å± marker æç´¢+è¡ç½åå":
# æ¯è¡å¨**å½å phase** åå¤åæ³æ§, marker è®¡æ°å¯ä¸, section å¤´éå® TECH|DESIGN ä¸
# ([ri]):/è·¯å¾, FM-249 ç©ºæ¥åä¸å¾å¤¹å¸¦ä»»ä½ sectionã
#   PRE          : æ¥åå¤´(æçº¿/å­æ®µ/éé¡¹ç»­è¡) â å¯ä¸ FM-184 â MARKED
#   MARKED       : å¯éå¯ä¸ FM-249(âEMPTY ç»æ); å¾ä¾æ¡; banner; section å¤´ â SEC_HEAD
#   EMPTY        : åªåè®¸å°¾é¨æ´æ°åæ¾/ç©ºè¡(å¤¹å¸¦ section/block â error)
#   SEC_HEAD     : å¿é¡» Type è¡¨å¤´ â SEC_TABLE(ç¼ºè¡¨å¤´ â error)
#   SEC_TABLE    : å¿é¡» ---- åé â BLOCKS(ç¼ºåé â error)
#   BLOCKS       : flag å(Instances N==M>0, ç²¾ç¡® N æ¡è·¯å¾, side==section, ç¦éå¤);
#                  banner/æ° section å¤´/å°¾é¨æ´æ°åæ¾ãsection å 0 block â errorã
# ä¸å®¡å é: marker é**å®æ´è§èææ¬**(ä¼ªé  Information è¡ä¸åè¢«è®¤ä½ markerââ
# è½å° unknown_information_line æ); section é TECHâ/FM_BBOXãDESIGNâ/WORK éå¯¹;
# æ´æ°åæ¾è¿ TAIL ç»æ(å¶åä»»ä½åå®¹æ); (side,path) **è·¨ i/u/e ç±»å«å¨å±æé**ã
set SIDECAR_FM184_TEXT "Information: Reporting black boxes for current reference and implementation designs. (FM-184)"
set SIDECAR_FM249_TEXT "Information: No 'black boxes' matched current 'reference and implementation designs'. (FM-249)"
# åå®¡: legend æéææ³ââåªæ¥åä»¥ä¸**ç²¾ç¡®è¡**(èªè¯æ®å­èéè¡æå)
set SIDECAR_LEGEND_LINES {
    { ___________________________________________________}
    {|                                                   |}
    {|  Legend:                                          |}
    {|           Black Box Attributes                    |}
    {|              s = Set with set_black_box command   |}
    {|              i = Module read with -interface_only |}
    {|              u = Unresolved design module         |}
    {|              e = Empty design module              |}
    {|              * = Unlinked design module           |}
    {|             ut = Unread tech cells pins           |}
    {|              L = Linked to non-black box design   |}
    {|             cp = Cutpoint blackbox                |}
    {|             ir = Internal rounded blackbox        |}
    {|              f = Formality Power Model            |}
    {|              m = Technology Macro cell (.db)      |}
    {|___________________________________________________|}
}
proc sidecar_parse_black_boxes {txt top} {
    array set acc {ir {} ii {} ur {} ui {} er {} ei {}}
    array set seen {}
    set fm184 0; set fm249 0
    set saw_report 0; set saw_ref 0; set saw_impl 0
    set phase PRE
    set cur_side ""; set cur_kind ""; set sec_blocks 0; set total_blocks 0
    set lines [split $txt "\n"]
    set n [llength $lines]
    set i 0
    while {$i < $n} {
        set ln [string trimright [lindex $lines $i]]
        if {[string trim $ln] eq ""} { incr i; continue }
        # ---- marker(å®æ´è§èææ¬ç²¾ç¡®å¹é; è®¡æ°å¯ä¸; è¦æ± header ä¸è¦ç´ å·²æ ¸å¯¹) ----
        if {$ln eq $::SIDECAR_FM184_TEXT} {
            if {$fm184} { error "bbox_duplicate_FM184" }
            if {$phase ne "PRE"} { error "bbox_FM184_wrong_phase:$phase" }
            if {!($saw_report && $saw_ref && $saw_impl)} { error "bbox_header_incomplete_before_FM184" }
            set fm184 1; set phase MARKED; incr i; continue
        }
        if {$ln eq $::SIDECAR_FM249_TEXT} {
            if {$fm249} { error "bbox_duplicate_FM249" }
            if {$phase ne "MARKED"} { error "bbox_FM249_wrong_phase:$phase" }
            set fm249 1; set phase EMPTY; incr i; continue
        }
        if {[regexp {^Information:} $ln]} { error "bbox_unknown_information_line:$ln" }
        switch -- $phase {
            PRE {
                # åå®¡: header ç»å®å¯ä¸ä¸æ­£ç¡®çæ¥ååä¸ top
                if {[regexp {^\*+$} $ln]} { incr i; continue }
                if {[regexp {^Report\s+:\s+(\S+)$} $ln -> rn]} {
                    if {$rn ne "black_boxes"} { error "bbox_wrong_report_name:$rn" }
                    set saw_report 1; incr i; continue
                }
                if {[regexp {^Reference\s+:\s+(\S+)$} $ln -> rv]} {
                    if {$rv ne "r:/WORK/$top"} { error "bbox_wrong_reference_top:$rv" }
                    set saw_ref 1; incr i; continue
                }
                if {[regexp {^Implementation\s+:\s+(\S+)$} $ln -> iv]} {
                    if {$iv ne "i:/WORK/$top"} { error "bbox_wrong_implementation_top:$iv" }
                    set saw_impl 1; incr i; continue
                }
                if {[regexp {^Version\s+:\s+\S+$} $ln] || [regexp {^Date\s+:\s+.+$} $ln] || \
                    [regexp {^\s+-\S+$} $ln]} { incr i; continue }
                error "bbox_PRE_unparsed:$ln"
            }
            EMPTY {
                if {[string is integer -strict [string trim $ln]]} { set phase TAIL; incr i; continue }
                error "bbox_empty_report_with_content:$ln"
            }
            TAIL {
                # ç»æ: åªå®¹è®¸éå¤çæ´æ°åæ¾
                if {[string is integer -strict [string trim $ln]]} { incr i; continue }
                error "bbox_content_after_tail_echo:$ln"
            }
            MARKED - BLOCKS {
                if {$phase eq "MARKED" && \
                    ([string match { _*} $ln] || [string match {|*} $ln])} {
                    # åå®¡: legend æéææ³ââéç²¾ç¡®å·²ç¥è¡æ
                    if {$ln ni $::SIDECAR_LEGEND_LINES} { error "bbox_unknown_legend_line:$ln" }
                    incr i; continue
                }
                if {[regexp {^#+$} $ln]} { incr i; continue }
                if {[regexp {^####\s+(TECH|DESIGN)\s+LIBRARY\s+-\s+([ri]):(/\S+)$} $ln -> kind s root]} {
                    if {!(($kind eq "TECH" && $root eq "/FM_BBOX") || \
                          ($kind eq "DESIGN" && $root eq "/WORK"))} {
                        error "bbox_section_kind_root_mismatch:$kind$root"
                    }
                    if {$phase eq "BLOCKS" && $sec_blocks == 0} { error "bbox_section_without_blocks" }
                    set cur_side $s; set cur_kind $kind; set sec_blocks 0; set phase SEC_HEAD; incr i; continue
                }
                if {[regexp {^####} $ln]} { error "bbox_bad_section_header:$ln" }
                if {[string is integer -strict [string trim $ln]]} {
                    if {$phase eq "BLOCKS" && $sec_blocks == 0} { error "bbox_section_without_blocks" }
                    set phase TAIL; incr i; continue
                }
                if {$phase ne "BLOCKS"} { error "bbox_${phase}_unparsed:$ln" }
                # ---- BLOCKS: flag å ----
                if {![regexp {^(\S{1,2})\s+(\S+)$} $ln -> flag dname]} {
                    error "bbox_BLOCKS_unparsed:$ln"
                }
                if {$flag ni {i u e}} { error "bbox_unsupported_flag:${flag}:${dname}" }
                # åå®¡: flag ä¸ section ç±»å«ç»å®ââTECH(/FM_BBOX)åªå®¹ u(æªè§£æ);
                # DESIGN(/WORK)åªå®¹ i/e(interface_only/empty æ¯å·²è¯»å¥è®¾è®¡åºçæ¨¡å)
                if {$cur_kind eq "TECH" && $flag ne "u"} {
                    error "bbox_flag_section_mismatch:${flag}_in_TECH"
                }
                if {$cur_kind eq "DESIGN" && $flag ni {i e}} {
                    error "bbox_flag_section_mismatch:${flag}_in_DESIGN"
                }
                set j [expr {$i+1}]
                while {$j < $n && [string trim [lindex $lines $j]] eq ""} { incr j }
                if {$j >= $n || ![regexp {^\s+Instances\s*:\s*(\d+)\s+of\s+(\d+)$} \
                                  [string trimright [lindex $lines $j]] -> N M]} {
                    error "bbox_${dname}_missing_instances_line"
                }
                if {$N != $M} { error "bbox_${dname}_instances_N_ne_M:${N}_of_${M}" }
                if {$N == 0} { error "bbox_${dname}_instances_zero_block" }
                set k [expr {$j+1}]
                set sep 0
                while {$k < $n && [regexp {^\s*-+\s*$} [lindex $lines $k]]} { set sep 1; incr k }
                if {!$sep} { error "bbox_${dname}_missing_separator" }
                set got 0
                while {$k < $n && $got < $N} {
                    set raw [string trimright [lindex $lines $k]]
                    if {[string trim $raw] eq ""} { break }
                    if {![regexp {^\s+([ri]):(/\S+)$} $raw -> side rest]} {
                        error "bbox_${dname}_bad_path:[string trim $raw]"
                    }
                    if {$side ne $cur_side} {
                        error "bbox_${dname}_path_side_mismatch:${side}!=${cur_side}"
                    }
                    set pl "${side}:${rest}"
                    # ä¸å®¡: (side,path) å¨å±å¯ä¸ââåä¸è·¯å¾è·¨ i/u/e ç±»å«éå¤äº¦æ
                    if {[info exists seen($side,$pl)]} { error "bbox_${dname}_duplicate_path:$pl" }
                    set seen($side,$pl) 1
                    lappend acc($flag$side) $pl
                    incr got; incr k
                }
                if {$got != $N} { error "bbox_${dname}_path_count:${got}!=${N}" }
                if {$k < $n && [regexp {^\s+[ri]:/} [lindex $lines $k]]} {
                    error "bbox_${dname}_extra_path_beyond_N"
                }
                incr sec_blocks; incr total_blocks
                set i $k
                continue
            }
            SEC_HEAD {
                if {[regexp {^#+$} $ln]} { incr i; continue }   ;# banner ä¸æ²¿
                if {[regexp {^Type\s+Design Name$} $ln]} { set phase SEC_TABLE; incr i; continue }
                error "bbox_section_missing_table_header:$ln"
            }
            SEC_TABLE {
                if {[regexp {^----\s+-+$} $ln]} { set phase BLOCKS; incr i; continue }
                error "bbox_section_missing_separator:$ln"
            }
        }
    }
    if {!$fm184} { error "bbox_report_missing_FM184" }
    # åå®¡: æåç»æå¿é¡»**æ°ä¸º TAIL**(ç¼ºæç»æ´æ°åæ¾ç"ç©ºæ¥å"äº¦æ)
    if {$phase ne "TAIL"} { error "bbox_end_phase_not_TAIL:$phase" }
    if {!$fm249 && $total_blocks == 0} { error "bbox_nonempty_claim_but_no_blocks" }
    return [list [lsort $acc(ir)] [lsort $acc(ii)] [lsort $acc(ur)] [lsort $acc(ui)] \
                 [lsort $acc(er)] [lsort $acc(ei)]]
}

# ---------------- pair åè¡¨è§æ´ ----------------
proc sidecar_pairs_sorted {raw} {
    # raw: fm -list è¿åç {{ref impl} ...}; ç©ºä¾§("")æ(matched è¯­å¢ä¸åºåºç°)
    set out {}
    foreach p $raw {
        if {[llength $p] != 2} { error "pair_not_2elem:$p" }
        set r [lindex $p 0]; set i [lindex $p 1]
        if {$r eq "" || $i eq ""} { error "pair_empty_side:$p" }
        lappend out [list $r $i]
    }
    return [lsort $out]
}

# ---------------- â¢ æ±éä¸åå­å ----------------
proc sidecar_emit {top} {
    if {![info exists ::env(FM_SIDECAR_OUT)] || $::env(FM_SIDECAR_OUT) eq ""} return
    set ::SIDECAR_TMP ""
    if {[catch {sidecar_emit_inner $top} msg]} {
        if {$::SIDECAR_TMP ne ""} { catch {file delete $::SIDECAR_TMP} }
        puts "SIDECAR_ERROR: emit_failed: $msg"
        exit 4
    }
    puts "SIDECAR_NATIVE_FACTS_WRITTEN"
}

proc sidecar_emit_inner {top} {
    set out $::env(FM_SIDECAR_OUT)
    if {![info exists ::env(FM_RUN_ID)]} { error "missing_FM_RUN_ID" }
    set run_id $::env(FM_RUN_ID)

    # native verdict(åªè¯» app var; éç»æ MATCHED/GUIDE â æ)
    set nv [get_app_var verification_status]
    switch -- $nv {
        "SUCCEEDED" - "FAILED" - "INCONCLUSIVE" {}
        "NOT RUN" { set nv "NOT_RUN" }
        default { error "nonfinal_verification_status:$nv" }
    }

    # å»ç»æ¥è¯¢(v7 ééè¡¨)
    set l_pass   [report_passing_points -list]
    set l_fail   [report_failing_points -list]
    set l_unver  [report_unverified_points -list]
    set l_abort  [report_aborted_points -list]
    set l_nc_unr [report_matched_points -not_compared -status unread -list]
    set l_m_bbox [report_matched_points -point_type bbox -list]
    set l_m_dv   [report_matched_points -status dont_verify -list]
    set um_ref     [lsort -unique [report_unmatched_points -reference -list]]
    set um_impl    [lsort -unique [report_unmatched_points -implementation -list]]
    set um_unr_r   [lsort -unique [report_unmatched_points -reference -status unread -list]]
    set um_unr_i   [lsort -unique [report_unmatched_points -implementation -status unread -list]]
    set um_dv_r    [lsort -unique [report_unmatched_points -reference -status dont_verify -list]]
    set um_dv_i    [lsort -unique [report_unmatched_points -implementation -status dont_verify -list]]
    set um_bbo_r   [lsort -unique [report_unmatched_points -reference -point_type bbox_output -list]]
    set um_bbo_i   [lsort -unique [report_unmatched_points -implementation -point_type bbox_output -list]]
    set um_bbi_r   [lsort -unique [report_unmatched_points -reference -point_type bbox_input -list]]
    set um_bbi_i   [lsort -unique [report_unmatched_points -implementation -point_type bbox_input -list]]
    set um_pi_r    [lsort -unique [report_unmatched_points -reference -point_type input -list]]
    set um_pi_i    [lsort -unique [report_unmatched_points -implementation -point_type input -list]]

    # gate-3 æ¢éè¯æ®(éå¥çº¦æä»¶): combined unread æ¥è¯¢åå§è¿å
    set fh [open "$out/probe_nc_unread.list" w]
    puts -nonewline $fh $l_nc_unr; close $fh
    # (script_closure.list å·²ç± sidecar_register_script å¨æ¯æ¬¡ source æ¶**å³æ¶**è½ç,
    #  è¿åæ§è¡æ¶å»å­èå¿«ç§ sourced_NNN_*; æäº§ä¼è¯åæ ·çç)

    # black_boxes(FM-184 ç¶ææº; puts è¿åå¼ä¿è¯ TAIL ç»æåæ¾ç¡®å®å­å¨)
    redirect -variable bb_txt {puts [report_black_boxes]}
    lassign [sidecar_parse_black_boxes $bb_txt $top] if_r if_i un_r un_i em_r em_i

    # dont_verify ç¨æ·éç½®æ¥å: éç©ºä¸æ æ³è§£æ â fail-closed
    redirect -variable dv_txt {report_dont_verify_points}
    set dv_objs {}
    foreach ln [split $dv_txt "\n"] {
        set t [string trim $ln]
        if {$t eq "" || [regexp {^\*+$} $t] || [regexp {^(Report|Reference|Implementation|Version|Date)\s} $t]} continue
        if {[regexp {FM-\d+} $t]} continue
        if {[regexp {^Don't verify points:\s*None$} $t]} continue   ;# ç©ºéæ åè¡(3B å®è¯)
        if {[string is integer -strict $t]} continue   ;# redirect å«å½ä»¤è¿åå¼åæ¾(3A/3B å®è¯)
        error "dont_verify_report_unparsed_line:$t"
    }

    # entry appvars(verify åå·²æè·)
    if {![info exists ::SIDECAR_AV]} { error "appvars_not_captured_before_verify" }
    set relaxed {}
    foreach k [array names ::SIDECAR_AV] {
        if {[info exists ::SIDECAR_APPVAR_DEFAULT($k)]} {
            set d $::SIDECAR_APPVAR_DEFAULT($k)
            set v $::SIDECAR_AV($k)
            if {$k eq "verification_assume_reg_init"} { set v [string tolower $v] }
            if {$v ne $d} { lappend relaxed $k }
        }
    }
    set av_parts {}
    foreach k [lsort [array names ::SIDECAR_AV]] {
        lappend av_parts "[sidecar_jstr $k]:[sidecar_jstr $::SIDECAR_AV($k)]"
    }

    # JSON ç»è£(è®¡æ°=ååè¡¨ llength, åæºååä½)
    set J "{"
    append J "\"schema\":\"fm-sidecar-native-v1\","
    append J "\"run_id\":[sidecar_jstr $run_id],\"top\":[sidecar_jstr $top],"
    append J "\"native_verdict\":[sidecar_jstr $nv],"
    append J "\"stats\":{\"passing\":[llength $l_pass],\"failing\":[llength $l_fail],"
    append J "\"unverified\":[llength $l_unver],\"aborted\":[llength $l_abort],"
    append J "\"unread_notcompared\":[llength $l_nc_unr]},"
    append J "\"unmatched\":{\"compare_ref\":[llength $um_ref],\"compare_impl\":[llength $um_impl],"
    append J "\"unread_ref\":[llength $um_unr_r],\"unread_impl\":[llength $um_unr_i],"
    append J "\"bbout_ref\":[llength $um_bbo_r],\"bbout_impl\":[llength $um_bbo_i]},"
    append J "\"objects\":{"
    append J "\"matched_blackbox_pairs\":[sidecar_jpairs [sidecar_pairs_sorted $l_m_bbox]],"
    append J "\"matched_unread_notcompared_pairs\":[sidecar_jpairs [sidecar_pairs_sorted $l_nc_unr]],"
    append J "\"matched_dont_verify_pairs\":[sidecar_jpairs [sidecar_pairs_sorted $l_m_dv]],"
    append J "\"interface_only_ref\":[sidecar_jlist $if_r],\"interface_only_impl\":[sidecar_jlist $if_i],"
    append J "\"unresolved_blackbox_ref\":[sidecar_jlist $un_r],\"unresolved_blackbox_impl\":[sidecar_jlist $un_i],"
    append J "\"empty_blackbox_ref\":[sidecar_jlist $em_r],\"empty_blackbox_impl\":[sidecar_jlist $em_i],"
    append J "\"unmatched_ref\":[sidecar_jlist $um_ref],\"unmatched_impl\":[sidecar_jlist $um_impl],"
    append J "\"unmatched_unread_ref\":[sidecar_jlist $um_unr_r],\"unmatched_unread_impl\":[sidecar_jlist $um_unr_i],"
    append J "\"unmatched_dont_verify_ref\":[sidecar_jlist $um_dv_r],\"unmatched_dont_verify_impl\":[sidecar_jlist $um_dv_i],"
    append J "\"unmatched_bbox_output_ref\":[sidecar_jlist $um_bbo_r],\"unmatched_bbox_output_impl\":[sidecar_jlist $um_bbo_i],"
    append J "\"unmatched_bbox_input_ref\":[sidecar_jlist $um_bbi_r],\"unmatched_bbox_input_impl\":[sidecar_jlist $um_bbi_i],"
    append J "\"unmatched_primary_input_ref\":[sidecar_jlist $um_pi_r],\"unmatched_primary_input_impl\":[sidecar_jlist $um_pi_i]},"
    append J "\"qualifications\":{\"dont_verify_objects\":[sidecar_jlist [lsort -unique $dv_objs]],"
    append J "\"elab147\":\[\],"
    append J "\"relaxed_appvars\":[sidecar_jlist [lsort -unique $relaxed]]},"
    append J "\"entry_appvars\":{[join $av_parts ,]}"
    append J "}"

    # åå­å: ç¬å  tmp åå»º â flush/close â no-force rename
    file mkdir $out
    set ::SIDECAR_TMP "$out/native_facts.json.tmp.[pid]"
    set fh [open $::SIDECAR_TMP {WRONLY CREAT EXCL} 0644]
    puts -nonewline $fh $J
    flush $fh
    close $fh
    set final "$out/native_facts.json"
    if {[file exists $final]} { error "native_facts_already_exists_no_force" }
    file rename $::SIDECAR_TMP $final
    set ::SIDECAR_TMP ""
}
