# TL2CHICoupledL2 「匹配前」钉点(FM_PIN_PRE_TCL): 首次 match 前 set_user_match。
# ---------------------------------------------------------------------------
# GrantData 多拍「首拍/后续拍」跟踪寄存器(每 slice 一个, ×4)的双射配对。
# golden: grant_data_fire_first_r_counter{,_1,_2,_3}(firtool 展平 1-bit reg,
#         `counter <= _grant_data_source_T & ~counter` 逐拍翻转)
# impl  : u_core/grantBeatRest_reg[0..3](本层 glue 的 4-bit 数组, 逐 slice
#         `grantBeatRest[i] <= grantBeatRest[i] ? 0 : opcode[0]` 同一翻转语义)
# 二者同功能, 名字不同(flat _N_reg vs SV 数组 _reg[N]), 两侧都 unread(只喂
# GrantData 组合路由门控, 无观测扇出) → 签名/名字均无法自动配对。
# ★必须在首次 match 前配对★: 否则首个 Matching Results 块会报
# "4(4) Unmatched reference(implementation) unread points"(grantBeat 未配对),
# 而末个匹配块 unread=0 时该行整体消失 → fm_verdict.py `_unmatch_pair` 取全文
# 最后一次匹配, 会误读陈旧首块的 4(4)。pre-match 配对令全程无此行。
# 配对后由 vmucp=true 实际比较这 4 对(证明 MORE); UT 200k 拍 errors=0 已实证值级一致。
set _g 0
set _ridx [list "" "_1" "_2" "_3"]
for {set s 0} {$s < 4} {incr s} {
  set rp "r:/WORK/$top/grant_data_fire_first_r_counter[lindex $_ridx $s]_reg"
  set ip "i:/WORK/$top/u_core/grantBeatRest_reg\[$s\]"
  if {![catch {set_user_match $rp $ip}]} { incr _g } else {
    puts "TL2CHI_PREPINS: grantBeat pair FAIL s=$s ($rp <-> $ip)"
  }
}
puts "TL2CHI_PREPINS: grantBeat $_g pairs pinned (pre-match)"
