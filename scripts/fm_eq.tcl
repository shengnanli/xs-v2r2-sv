# Formality 等价性检查通用脚本
# 由 scripts/ut_common.mk 的 fm-% 目标调用，经环境变量传参：
#   FM_TOP        顶层模块名（golden 变体名；impl 侧包装层与其同名同端口）
#   FM_REF_SRCS   golden RTL 文件列表（变体 + 其子模块）
#   FM_IMPL_SRCS  手写 SV 文件列表（参数化核心 + 包装层）

set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# ----------------------------------------------------------------------------
# Step 3B sidecar emitter(FM_SIDECAR_OUT 非空时启用; 契约 = SIDECAR_SCHEMA.md v7 冻结版):
# source 后立即对将被 source 的模块本地 Tcl 做**运行期 appvar 拦截**(set_app_var 名字
# 不在注册表 → exit 3, 拒产 native facts)。
# ----------------------------------------------------------------------------
set SIDECAR_ON 0
if {[info exists env(FM_SIDECAR_OUT)] && [string trim $env(FM_SIDECAR_OUT)] ne ""} {
    set _entry [file normalize [info script]]
    set _emit  [file join [file dirname $_entry] sidecar fm_native_emit.tcl]
    source $_emit
    set SIDECAR_ON 1
    # 3B验收三审: script closure = **执行时刻字节快照**(sidecar_register_script 把被
    # 执行文件的字节即时拷入 FM_SIDECAR_OUT 并追加清单; source trace 对嵌套亦触发,
    # 解析 -encoding 形式)。入口与 emitter 非 source 载入, 在此显式登记快照。
    # appvar 拦截 = execution trace 加在命令本身 + phase(match 后冻结)+ 写历史。
    set ::SIDECAR_SOURCED {}
    sidecar_register_script $_entry
    sidecar_register_script $_emit
    sidecar_install_appvar_guard
}

# ----------------------------------------------------------------------------
# FM_MODE 门控(2026-07 唯一权威入口, 二审): 证明模式决定允许哪些放宽手段。
#   signoff-strict(默认): 禁 interface_only(assembly 专用手段); 严格判定交 fm_verdict.py。
#   assembly: 允许**声明的对称黑盒** FM_INTERFACE_ONLY(仅证本层 glue)。
#   diagnostic-full: 由 fm_eq_full.tcl 承担(ELAB 降级/放宽上限), 永不签核。
#   shadow: 同 strict(可读核不驱动输出, 判定归 SHADOW_CHECK)。
# 诊断能力永不进 signoff: strict 下 FM_INTERFACE_ONLY 非空即报错退出(fail-closed)。
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
      puts "FM_MODE_ERROR: $_fmmode 拒绝 FM_INTERFACE_ONLY(assembly 专用手段)"
      exit 3
    }
  }
  default {
    puts "FM_MODE_ERROR: 未知 FM_MODE=$_fmmode"
    exit 3
  }
}

# 寄存器无观测路径（如被 firtool 裁剪的输出对应的 valids）时不作为比对点。
# 十一审: unread 六元组**显式全量设置**(305 统一冻结执行语义, 不让工具默认代替声明;
# emitter 于全部 pin/custom Tcl 执行后、verify 前逐项 get_app_var 读回有效值)。
# 后三项 true 即工具默认(man cat3 逐页核对), 显式钉死防版本漂移。
set_app_var verification_verify_unread_compare_points false
# LoadQueueUncache target-scoped strengthening: verify matched unread compare
# points instead of accepting them as Not-Compared.  The signoff runner obtains
# this value from the committed declaration/manifest and binds it into input
# provenance.  It is deliberately not a waiver: true asks FM to prove *more*.
set _verify_matched_unread_compare_points "false"
if {[info exists env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)] &&
    [string trim $env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)] ne ""} {
    set _verify_matched_unread_compare_points \
        [string trim $env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)]
}
switch -- $_verify_matched_unread_compare_points {
  "true" {
    if {$top ni {LoadQueueUncache FastArbiter_46 FastArbiter_47 FastArbiter_27 FastArbiter_44 ICacheCtrlUnit ICacheDataArray IPrefetchPipe DivUnit FDivSqrt InstrMMIOEntry InstrUncache TXDAT_4 FAlu FCVT IssueQueueStdMoud MulUnit TXREQ TlbStorageWrapper TlbStorageWrapper_1 IssueQueueStaMou IssueQueueLdu TXDAT Scheduler_1 Scheduler Scheduler_3 MSHR TageBTable Directory SCTable SCTable_1 SCTable_2 SCTable_3 Tage_SC ITTage FauFTB FTBBank FTB Composer EntriesAluCsrFenceDiv Bku SourceB}} {
      puts "FM_MODE_ERROR: matched-unread strengthening 仅允许精确白名单, 当前 $top"
      exit 3
    }
  }
  "false" { }
  default {
    puts "FM_MODE_ERROR: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS 非法值 $_verify_matched_unread_compare_points"
    exit 3
  }
}
set_app_var verification_verify_matched_unread_compare_points \
    $_verify_matched_unread_compare_points
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true

# 未解析模块（厂商 SRAM 叶子 array_ext 等外部宏）自动当黑盒——两侧一致即可，
# SRAM 内部存储不参与 wrapper 逻辑等价比对。
set_app_var hdlin_unresolved_modules black_box

# 合并由同一逻辑驱动的重复寄存器（如分 bank 的读地址扇出复制：每 bank 一份、
# 输出级一份，值完全相同）。否则两侧各有 N 个同值寄存器，名字（展平 vs generate
# 层次）和签名（值相同）都无法配对，导致大量 unmatched。FTQ/IFU 等扇出复制
# 普遍存在，默认 true。
# 九审(3A.2 审定补丁3): 该值由 FM_MERGE_DUP 入口变量真实绑定——此前 Makefile 声明
# FM_MERGE_DUP=false 而这里硬编码 true, manifest 声称值与实际证明语义脱节(fail-closed:
# 非法值退出, 不静默回落)。
set _mergedup "true"
if {[info exists env(FM_MERGE_DUP)] && [string trim $env(FM_MERGE_DUP)] ne ""} {
    set _mergedup [string trim $env(FM_MERGE_DUP)]
}
switch -- $_mergedup {
  "true" - "false" { set_app_var verification_merge_duplicated_registers $_mergedup }
  default {
    puts "FM_MODE_ERROR: FM_MERGE_DUP 非法值 $_mergedup"
    exit 3
  }
}

# Reference: Chisel 生成的 golden RTL（SYNTHESIS 关掉随机初始化 initial 块）
read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

# Implementation: 手写 SV
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

# ----------------------------------------------------------------------------
# 字段映射配对（在首次 match 之前全量钉死）：当手写核心把整个 payload 打包进一个
# 扁平寄存器 data_reg，而 golden 用逐字段寄存器 data_<suffix> 时，等宽字段会令签名
# 分析产生歧义、且会在重新 match 时互相搅乱。生成器输出「<suffix> <lo> <width>」
# 映射（FM_FIELD_MAP），这里据此把 ref 的 data_<suffix>_reg[b] 逐位 set_user_match
# 到 impl 的 u_core/data_reg[lo+b]，使后续 match 只需处理 valid 等非 payload 寄存器。
# 供 PipelineConnect 及后续扁平 payload 模块复用。
# ----------------------------------------------------------------------------
proc match_packed_payload { top } {
    if {![info exists ::env(FM_FIELD_MAP)] || ![file exists $::env(FM_FIELD_MAP)]} return
    set fh [open $::env(FM_FIELD_MAP) r]
    set n 0
    foreach ln [split [read $fh] "\n"] {
        if {![regexp {^(\S+)\s+(\d+)\s+(\d+)$} $ln -> suf lo w]} continue
        for {set b 0} {$b < $w} {incr b} {
            set ipath "i:/WORK/$top/u_core/data_reg\[[expr {$lo + $b}]\]"
            # 多位字段 golden 名为 data_<suf>_reg[b]；1 位字段可能无下标
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
# 模块本地「匹配前」钉点(FM_PIN_PRE_TCL, 可选): 首次 match 前需 set_user_match 的对象。
# 四审: sidecar 下 pin 代码进受限 safe child interp(sidecar_pin_source: 一次读取→快照
# →child 执行同一缓冲; 拿不到父层 guard/trace/证据目录; 嵌套 source 走同一受控入口)。
if {[info exists env(FM_PIN_PRE_TCL)] && [file exists $env(FM_PIN_PRE_TCL)]} {
    if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_PRE_TCL) } else { source $env(FM_PIN_PRE_TCL) }
}
match_packed_payload $top

match

# ----------------------------------------------------------------------------
# 自动配对 Chisel 展平命名与 SV 数组命名的寄存器：
#   ref:  name_1_0_reg / array_0_reg[2]   （firtool 把 Vec 展平成带下标后缀的标量名）
#   impl: name_reg[1][0] / array_reg[0][2]（SV 数组寄存器）
# 名字过滤匹配不了这种结构差异；条目间逻辑对称时签名分析也常失败，因此按
# 命名规则显式 set_user_match。impl 路径会依次尝试：原层次、顶层下插入
# u_core（变体包装层例化参数化核心的固定实例名）。
# ----------------------------------------------------------------------------
proc auto_match_flattened_arrays { top } {
    redirect -variable um_txt {report_unmatched_points}

    # 收集两侧未匹配 DFF；impl 侧建立「展平等价名 → 实际路径」查找表。
    # 展平等价名 = 去掉 i:/WORK/<top> 前缀和 u_core 层次、数组下标改成 _i 后缀，
    # 与 ref 侧的 firtool 展平叶子名同构，可直接字符串比对。
    array set impl_lut {}
    set refs {}
    foreach line [split $um_txt "\n"] {
        if {[regexp {Ref\s+DFF\S*\s+(r:\S+)} $line -> rpath]} {
            lappend refs $rpath
        } elseif {[regexp {Impl\s+DFF\S*\s+(i:\S+)} $line -> ipath]} {
            set rel $ipath
            regsub "^i:/WORK/${top}/" $rel "" rel
            regsub "^u_core/" $rel "" rel
            # name_reg[1][0] -> name_1_0_reg；保留最后一个位下标（多位寄存器）
            set key $rel
            regexp {^(.*?)((?:\[\d+\])*)$} $rel -> stem bits
            set idxs ""
            set blist [regexp -all -inline {\d+} $bits]
            if {[regexp {^(.*)_reg$} $stem -> nm]} {
                # 位下标个数与 ref 侧叶子的展平维度由名字比对自然对齐：
                # 先全转成 name_i_j_reg 形式，再在比对时允许 ref 带一个 [bit] 尾巴
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
        # ref 叶子可能带位下标尾巴：array_0_reg[2]
        regexp {^(.*?)((?:\[\d+\])*)$} $leaf -> base bit
        set bitidx ""
        foreach b [regexp -all -inline {\d+} $bit] { set bitidx "_$b" }
        # 候选 key：把 ref 展平名（含可选位下标）规约成 name_i_j_reg
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

# 模块本地「匹配后」钉点(FM_PIN_TCL, 可选): 层次/叶名差异的一一对应(只 set_user_match, 不约束 ref)。
if {[info exists env(FM_PIN_TCL)] && [file exists $env(FM_PIN_TCL)]} {
    if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_TCL) } else { source $env(FM_PIN_TCL) }
    match
}

report_unmatched_points > fm_work/$top/unmatched.rpt
report_matched_points > fm_work/$top/matched.rpt

# sidecar: appvar 有效值读回——全部 pin/custom Tcl 之后、verify 之前(schema v7 契约)
if {$SIDECAR_ON} { sidecar_capture_appvars }

if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top"
} else {
    report_failing_points > fm_work/$top/failing.rpt
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"
}
# sidecar: 全查询→内存解析→原子写 native_facts.json(任何错误删 tmp 并 exit 4)
if {$SIDECAR_ON} { sidecar_emit $top }
exit
