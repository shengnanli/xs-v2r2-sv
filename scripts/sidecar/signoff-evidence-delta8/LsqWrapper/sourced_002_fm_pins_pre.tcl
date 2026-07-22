# LsqWrapper FM 模块本地钉点(FM_PIN_TCL, 匹配后 source)。
# ----------------------------------------------------------------------------
# 背景: LoadQueue/StoreQueue 两侧 interface_only 黑盒后,只剩包装级 glue 比对。
# 两处命名结构差异令 Formality 的 auto_match 误配,需显式 set_user_match:
#
#  1) perf 两级打拍:golden 用逐下标具名寄存器 io_perf_<N>_value_REG(stage1)/
#     io_perf_<N>_value_REG_1(stage2);impl 用 genvar 数组 perf_stage1_reg[N] /
#     perf_stage2_reg[N]。两种命名同构但 stem 不同(io_perf_N_value_REG vs
#     perf_stageK),auto_match 的 name_i_j 规约桥不过去,个别下标(N=1,2)被跨级
#     误配(golden stage2 配到 impl stage1)。这里对全部 36 路两级逐位钉死。
#
#  2) uncache 仲裁 FSM 状态:golden pendingstate[1:0] <-> impl unc_state_reg[1:0]
#     (同一 3 态机,IDLE/LOAD/STORE=0/1/2,复位与转移逻辑逐条对应)。
#
# 已被 auto_match 正确配对的点这里重复 set_user_match 会报错,用 catch 跳过。
# ----------------------------------------------------------------------------

proc pin_bits {rbase ibase width} {
    for {set b 0} {$b < $width} {incr b} {
        set r "r:/WORK/LsqWrapper/${rbase}\[$b\]"
        set i "i:/WORK/LsqWrapper/u_core/${ibase}\[$b\]"
        catch {set_user_match $r $i}
    }
}

# perf: 36 路 × 2 级,每路 6 bit
for {set n 0} {$n < 36} {incr n} {
    pin_bits "io_perf_${n}_value_REG_reg"   "perf_stage1_reg\[$n\]" 6
    pin_bits "io_perf_${n}_value_REG_1_reg" "perf_stage2_reg\[$n\]" 6
}

# uncache 仲裁 FSM 状态寄存器(2 bit)
pin_bits "pendingstate_reg" "unc_state_reg" 2
