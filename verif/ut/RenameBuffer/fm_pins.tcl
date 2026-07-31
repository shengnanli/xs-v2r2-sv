# =====================================================================
# RenameBuffer target-scoped matched-unread bijection pins (FM_PIN_TCL)
# ---------------------------------------------------------------------
# 7 对称 matched-unread 双射: 两侧寄存器写了但从不喂任何 module output(cone-dead),
# ref/impl 每拍逐位相等(D、reset、时钟条件均同构复刻)。层次/叶名差异令签名分析无法
# 自动配对, 故显式 set_user_match; 配合 verify_matched_unread_compare_points=true
# (target-scoped vmucp), FM 实开比较证明这 7 对恒等 → 从 unread 转 passing(非 waiver)。
#
#   (1) diffPtr flag: golden diffPtr_flag_reg = 9 位 diffPtr+commitSize 加法进位 bit8;
#       impl diff_ptr.flag 由同一 ptr_add 进位驱动。difftest 读队列只用 value → flag 无扇出。
#   (2..7) toVecExcpMod preg MSB[7] ×6: golden preg_r_reg[7] = commit 候选 pdest[7] 打一拍;
#       impl io_toVecExcpMod_preg_reg[i][7] 同源同拍。对外端口只取 [6:0] → MSB[7] 无扇出。
#
# 只 set_user_match(不约束 ref), match 后由 fm_eq.tcl 重跑 match + verify。
# =====================================================================

set T $top

# (1) diffPtr flag (struct field escaped as diff_ptr_reg\[flag])
set_user_match \
    r:/WORK/$T/diffPtr_flag_reg \
    i:/WORK/$T/u_core/diff_ptr_reg\[flag]

# (2..7) toVecExcpMod preg_r_reg[7] MSB, ports 0..5
for {set i 0} {$i < 6} {incr i} {
    set_user_match \
        r:/WORK/$T/io_toVecExcpMod_logicPhyRegMap_${i}_bits_preg_r_reg\[7] \
        i:/WORK/$T/u_core/io_toVecExcpMod_preg_reg\[$i]\[7]
}

puts "RENAMEBUFFER_PINS: 7 matched-unread bijection points pinned (1 diffPtr_flag + 6 preg_r\[7])"
