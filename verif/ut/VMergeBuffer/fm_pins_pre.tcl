# VMergeBuffer FM「匹配前」钉点 —— 由 scripts/gen_vmergebuf.py 生成，勿手改。
# 只消命名鸿沟：不约束 ref、不放宽 appvar、不扩黑盒、不 dont_verify。
# ---------------------------------------------------------------------------
# 对象：每个出队口的写回流水缓冲 NewPipelineConnectPipe_29 的 payload 寄存器。
# golden 每字段一个寄存器 data_<字段>_reg[b]，重写件（rtl/uncore/NewPipelineConnectPipe_29.sv）
# 把整个 payload 存在一个扁平的 u_core/data_reg。★实测（2026-09-28 VSMergeBufferImp 首次试跑）★：
# 不钉的话 FM 按"末段名"把 data_data_reg[0] 配到 data_reg[6] 这类错位的对子（Name(Last)），
# 整片 payload 错位 —— 与该模块单独签核时遇到的是同一个坑，这里沿用它的字段映射
# verif/ut/NewPipelineConnectPipe_29_34_35/fm_map/NewPipelineConnectPipe_29.txt
# （<字段> <起始位> <宽度>，生成时已与 golden 的 data_* 寄存器逐个对过名字与位宽）。
# 路径：ref  r:/WORK/<top>/VMergebufferPipelineConnect<d>/data_<字段>_reg[b]（1 位字段无 [b]）
#       impl i:/WORK/<top>/u_core/g_deq_pipe[<d>].VMergebufferPipelineConnect/u_core/data_reg[起始+b]
# fail-closed：每次 set_user_match 必须返回 1；配对数必须等于 1023 × 出队口数
# （VLMergeBufferImp 2 口 = 2046，VSMergeBufferImp 1 口 = 1023）。
# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。
# ---------------------------------------------------------------------------
set _mb_pipe29_fields {
    {uop_exceptionVec_3 1022 1}
    {uop_exceptionVec_4 1021 1}
    {uop_exceptionVec_5 1020 1}
    {uop_exceptionVec_6 1019 1}
    {uop_exceptionVec_7 1018 1}
    {uop_exceptionVec_13 1017 1}
    {uop_exceptionVec_15 1016 1}
    {uop_exceptionVec_19 1015 1}
    {uop_exceptionVec_21 1014 1}
    {uop_exceptionVec_23 1013 1}
    {uop_trigger 1009 4}
    {uop_fuOpType 1000 9}
    {uop_vecWen 999 1}
    {uop_v0Wen 998 1}
    {uop_vlWen 997 1}
    {uop_flushPipe 996 1}
    {uop_vpu_vill 995 1}
    {uop_vpu_vma 994 1}
    {uop_vpu_vta 993 1}
    {uop_vpu_vsew 991 2}
    {uop_vpu_vlmul 988 3}
    {uop_vpu_specVill 987 1}
    {uop_vpu_specVma 986 1}
    {uop_vpu_specVta 985 1}
    {uop_vpu_specVsew 983 2}
    {uop_vpu_specVlmul 980 3}
    {uop_vpu_vm 979 1}
    {uop_vpu_vstart 971 8}
    {uop_vpu_frm 968 3}
    {uop_vpu_fpu_isFpToVecInst 967 1}
    {uop_vpu_fpu_isFP32Instr 966 1}
    {uop_vpu_fpu_isFP64Instr 965 1}
    {uop_vpu_fpu_isReduction 964 1}
    {uop_vpu_fpu_isFoldTo1_2 963 1}
    {uop_vpu_fpu_isFoldTo1_4 962 1}
    {uop_vpu_fpu_isFoldTo1_8 961 1}
    {uop_vpu_vxrm 959 2}
    {uop_vpu_vuopIdx 952 7}
    {uop_vpu_lastUop 951 1}
    {uop_vpu_vmask 823 128}
    {uop_vpu_vl 815 8}
    {uop_vpu_nf 812 3}
    {uop_vpu_veew 810 2}
    {uop_vpu_isReverse 809 1}
    {uop_vpu_isExt 808 1}
    {uop_vpu_isNarrow 807 1}
    {uop_vpu_isDstMask 806 1}
    {uop_vpu_isOpMask 805 1}
    {uop_vpu_isMove 804 1}
    {uop_vpu_isDependOldVd 803 1}
    {uop_vpu_isWritePartVd 802 1}
    {uop_vpu_isVleff 801 1}
    {uop_psrc_2 793 8}
    {uop_pdest 785 8}
    {uop_robIdx_flag 784 1}
    {uop_robIdx_value 776 8}
    {uop_debugInfo_eliminatedMove 775 1}
    {uop_debugInfo_renameTime 711 64}
    {uop_debugInfo_dispatchTime 647 64}
    {uop_debugInfo_enqRsTime 583 64}
    {uop_debugInfo_selectTime 519 64}
    {uop_debugInfo_issueTime 455 64}
    {uop_debugInfo_writebackTime 391 64}
    {uop_debugInfo_runahead_checkpoint_id 327 64}
    {uop_debugInfo_tlbFirstReqTime 263 64}
    {uop_debugInfo_tlbRespTime 199 64}
    {uop_debug_seqNum_seqNum 143 56}
    {uop_debug_seqNum_uopIdx 135 8}
    {uop_replayInst 134 1}
    {data 6 128}
    {vdIdx 3 3}
    {vdIdxInField 0 3}
}

proc _mb_prepin {top fields} {
    if {$top eq "VLMergeBufferImp"} {
        set ndeq 2; set expect 2046
    } elseif {$top eq "VSMergeBufferImp"} {
        set ndeq 1; set expect 1023
    } else {
        error "MB_PREPIN_BAD_TOP=$top"
    }
    puts "MB_PREPIN_BEGIN top=$top expect=$expect"
    set n 0
    for {set d 0} {$d < $ndeq} {incr d} {
        foreach f $fields {
            lassign $f suf lo w
            for {set b 0} {$b < $w} {incr b} {
                if {$w == 1} {
                    set rpath "r:/WORK/$top/VMergebufferPipelineConnect$d/data_${suf}_reg"
                } else {
                    set rpath "r:/WORK/$top/VMergebufferPipelineConnect$d/data_${suf}_reg\[$b\]"
                }
                set ipath "i:/WORK/$top/u_core/g_deq_pipe\[$d\].VMergebufferPipelineConnect/u_core/data_reg\[[expr {$lo + $b}]\]"
                if {![set_user_match $rpath $ipath]} {
                    puts "MB_PREPIN_FAIL: set_user_match returned 0 for $rpath <-> $ipath"
                    error "MB_PREPIN_MISS=$rpath"
                }
                incr n
            }
        }
    }
    puts "MB_PREPIN_END top=$top n=$n expect=$expect"
    if {$n != $expect} { error "MB_PREPIN_COUNT=$n" }
}

_mb_prepin $top $_mb_pipe29_fields
