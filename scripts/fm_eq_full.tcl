# Formality 等价性检查 —— 全貌版(fm_eq.tcl + failing上限调大 + ELAB-147降级); 报告写 *_full.rpt
# 由 scripts/ut_common.mk 的 fm-% 目标调用，经环境变量传参：
#   FM_TOP        顶层模块名（golden 变体名；impl 侧包装层与其同名同端口）
#   FM_REF_SRCS   golden RTL 文件列表（变体 + 其子模块）
#   FM_IMPL_SRCS  手写 SV 文件列表（参数化核心 + 包装层）

set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# 寄存器无观测路径（如被 firtool 裁剪的输出对应的 valids）时不作为比对点
set_app_var verification_verify_unread_compare_points false

# 未解析模块（厂商 SRAM 叶子 array_ext 等外部宏）自动当黑盒——两侧一致即可，
# SRAM 内部存储不参与 wrapper 逻辑等价比对。
set_app_var hdlin_unresolved_modules black_box

# 合并由同一逻辑驱动的重复寄存器（如分 bank 的读地址扇出复制：每 bank 一份、
# 输出级一份，值完全相同）。否则两侧各有 N 个同值寄存器，名字（展平 vs generate
# 层次）和签名（值相同）都无法配对，导致大量 unmatched。FTQ/IFU 等扇出复制
# 普遍存在，作为通用默认。
#   注意：少数模块（如 LoadUnit）含大量"常量 0"的 debug/perf 死寄存器，合并 pass 会
#   在 wrapper/u_core 层次边界两侧做不对称的常量传播（golden 顶层标量 vs impl 在
#   u_core 内），把同值常量寄存器误判为 DFF0X vs DFFX 而 fail。这类模块在自己的
#   Makefile 里设 FM_MERGE_DUP=false 关掉合并即可干净比对（不影响无扇出复制的模块）。
set _merge_dup true
if {[info exists env(FM_MERGE_DUP)]} { set _merge_dup $env(FM_MERGE_DUP) }
set_app_var verification_merge_duplicated_registers $_merge_dup

# ==== 本文件为 fm_eq.tcl 的「全貌版」(FM 审计 2026-07 引入, 供重跑使用; 共享 fm_eq.tcl 未动) ====
# failing 上限: Formality 默认 verification_failing_point_limit=20 —— verify 数到 20 个失配
# 就提前中止, 大模块留下成百上千 Unverified 点未验(历史 fm.log 的 "20 failing" 只是截断视野)。
# 调大以获得 failing 全貌; 可用 FM_FAIL_LIMIT 覆盖。
set _fail_limit 5000
if {[info exists env(FM_FAIL_LIMIT)]} { set _fail_limit $env(FM_FAIL_LIMIT) }
set_app_var verification_failing_point_limit $_fail_limit

# golden 内存 RAM(ram_40x47 等)异步读越界推断告警 FMR_ELAB-147 会升级为 unsuppressed error
# 阻断 ref link(L2TLB/L2TlbMissQueue 此前从未跑成的根因)。降为 warn, 不影响等价判定。
set_mismatch_message_filter -warn FMR_ELAB-147

# 可选: 只取接口的模块名单(FM_INTERFACE_ONLY, 空格分隔)。对「两侧黑盒但 golden 里
# 黑盒输出直连另一黑盒输入」的子模块(如 NewIFU 的 F3Predecoder→PredChecker), 未解析
# 黑盒引脚方向未知会把 ref 侧连线判成多驱动→net 黑盒化(自由变量)而 impl 侧因 wrapper
# 端口方向已知不会——两侧锥不对称全 fail。把这些模块的 golden 源加进两侧文件列表并列进
# 本名单: 只保留端口方向(仍是黑盒), 消除方向猜测。
if {[info exists env(FM_INTERFACE_ONLY)]} {
  set_app_var hdlin_interface_only $env(FM_INTERFACE_ONLY)
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
match_packed_payload $top

# 模块本地「匹配前」钉点(FM_PIN_PRE_TCL, fm_rerun_full.sh 自动检测 verif/ut/<M>/fm_pins_pre.tcl):
# 在首次 match 之前 set_user_match, 避免签名分析先把 impl 点错配给别的 ref 点(错配后
# 事后 set_user_match 会失败)。与既有 FM_PIN_TCL(匹配后钉点)并存, 均为可选。
if {[info exists env(FM_PIN_PRE_TCL)] && [file exists $env(FM_PIN_PRE_TCL)]} {
    source $env(FM_PIN_PRE_TCL)
}

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

# 模块本地钉点: 若设 FM_PIN_TCL(fm_rerun_full.sh 自动检测 verif/ut/<M>/fm_pins.tcl),
# 在自动配对后 source 它做 set_user_match(处理层次/叶名差异的一一对应 unmatched), 再 match。
if {[info exists env(FM_PIN_TCL)] && [file exists $env(FM_PIN_TCL)]} {
    source $env(FM_PIN_TCL)
    match
}

report_unmatched_points > fm_work/$top/unmatched_full.rpt
report_matched_points > fm_work/$top/matched_full.rpt

if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top"
} else {
    report_failing_points > fm_work/$top/failing_full.rpt
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"
}
exit
