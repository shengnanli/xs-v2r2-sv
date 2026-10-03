# MainPipe FM「匹配前」钉点 —— 只消 16 个死寄存器位的命名差，不约束 ref、不放宽 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 对象：golden 与可读核里各有同一批"综合口径下没有读者"的寄存器（两侧同源同宽照抄），
# 死位没有扇出锥，签名分析配不上，名字又不同，于是首跑（lane 内 diagnostic 试跑，
# native SUCCEEDED passing 8955 / failing 0）报 `16(16) Unmatched reference(implementation)
# unread points`。逐个对照 golden 与 rtl/memblock/MainPipe.sv：
#   REG_2   <- RegNext(s1_fire && PopCount(s1_way_en) > 1)            = chk_multi_way_q
#   REG_3   <- RegNext(!(s2 同时去 s3 / 去 MQ / 回 MQ))                 = chk_s2_exclusive_q
#   REG_4   <- RegNext(tag_write.valid && !tag_write_intend)             = chk_tag_write_q
#   REG_5   <- RegNext(!tag_write.valid || !s3_req.replace)              = chk_tag_write_repl_q
#   REG_6   <- RegNext(!data_write.valid || !s3_req.replace)             = chk_data_write_repl_q
#     （以上 5 个只被 `ifndef SYNTHESIS 的断言读）
#   io_replace_way_set_valid_last_REG <- RegNext(s0_fire)，端口已被 DCE = s0_fire_q_replway
#   s1_extra_meta_r_access / _prefetch[2:0] <- s1 extra meta 保持寄存器里只喂性能计数的字段
#                                                              = s1_extra_meta_hold.access / .prefetch
#   s3_error_paddr_beu_r[5:0] <- 错误地址低 6 位（输出取块地址，低 6 位恒拼 0） = s3_error_paddr_beu_q[5:0]
# 配对表逐项写死（不猜名字），每一次 set_user_match 必须返回 1，总数必须等于字面 16。
# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。
# ---------------------------------------------------------------------------
proc _mp_pre_pin_dead { } {
    set _expect 16
    set r "r:/WORK/MainPipe"
    set i "i:/WORK/MainPipe/u_core"
    set pairs [list \
        "$r/REG_2_reg"                               "$i/chk_multi_way_q_reg" \
        "$r/REG_3_reg"                               "$i/chk_s2_exclusive_q_reg" \
        "$r/REG_4_reg"                               "$i/chk_tag_write_q_reg" \
        "$r/REG_5_reg"                               "$i/chk_tag_write_repl_q_reg" \
        "$r/REG_6_reg"                               "$i/chk_data_write_repl_q_reg" \
        "$r/io_replace_way_set_valid_last_REG_reg"   "$i/s0_fire_q_replway_reg" \
        "$r/s1_extra_meta_r_access_reg"              "$i/s1_extra_meta_hold_reg\\\[access\]" \
        "$r/s1_extra_meta_r_prefetch_reg\[0\]"       "$i/s1_extra_meta_hold_reg\\\[prefetch\]\[0\]" \
        "$r/s1_extra_meta_r_prefetch_reg\[1\]"       "$i/s1_extra_meta_hold_reg\\\[prefetch\]\[1\]" \
        "$r/s1_extra_meta_r_prefetch_reg\[2\]"       "$i/s1_extra_meta_hold_reg\\\[prefetch\]\[2\]" \
        "$r/s3_error_paddr_beu_r_reg\[0\]"           "$i/s3_error_paddr_beu_q_reg\[0\]" \
        "$r/s3_error_paddr_beu_r_reg\[1\]"           "$i/s3_error_paddr_beu_q_reg\[1\]" \
        "$r/s3_error_paddr_beu_r_reg\[2\]"           "$i/s3_error_paddr_beu_q_reg\[2\]" \
        "$r/s3_error_paddr_beu_r_reg\[3\]"           "$i/s3_error_paddr_beu_q_reg\[3\]" \
        "$r/s3_error_paddr_beu_r_reg\[4\]"           "$i/s3_error_paddr_beu_q_reg\[4\]" \
        "$r/s3_error_paddr_beu_r_reg\[5\]"           "$i/s3_error_paddr_beu_q_reg\[5\]" ]
    puts "MP_PREPIN_BEGIN MainPipe expect=$_expect"
    set n 0
    foreach {rp ip} $pairs {
        if {![set_user_match $rp $ip]} {
            puts "MP_PREPIN_FAIL: set_user_match returned 0 for $rp <-> $ip"
            error "MP_PREPIN_MISS=$rp"
        }
        incr n
    }
    puts "MP_PREPIN_END MainPipe n=$n expect=$_expect"
    if {$n != $_expect} {
        puts "MP_PREPIN_ERROR: pinned $n but expected $_expect"
        error "MP_PREPIN_COUNT=$n"
    }
}
_mp_pre_pin_dead
