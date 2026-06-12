# Formality 等价性检查通用脚本
# 由 scripts/ut_common.mk 的 fm-% 目标调用，经环境变量传参：
#   FM_TOP        顶层模块名（golden 变体名；impl 侧包装层与其同名同端口）
#   FM_REF_SRCS   golden RTL 文件列表（变体 + 其子模块）
#   FM_IMPL_SRCS  手写 SV 文件列表（参数化核心 + 包装层）

set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# 寄存器无观测路径（如被 firtool 裁剪的输出对应的 valids）时不作为比对点
set_app_var verification_verify_unread_compare_points false

# Reference: Chisel 生成的 golden RTL（SYNTHESIS 关掉随机初始化 initial 块）
read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

# Implementation: 手写 SV
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

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

report_unmatched_points > fm_work/$top/unmatched.rpt
report_matched_points > fm_work/$top/matched.rpt

if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top"
} else {
    report_failing_points > fm_work/$top/failing.rpt
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"
}
exit
