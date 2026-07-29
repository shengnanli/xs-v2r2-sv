# FusionDecoder 匹配前钉点(FM_PIN_PRE_TCL): golden 死寄存器 ↔ 可读核 lastFire[N] 双射。
#
# golden 里每 lane 有两个功能等价、逐拍 `<= fire_N` 的寄存器:
#   lastFire_N —— 被 firtool 为 SYNTHESIS 断言生成的 _GEN_3.. / _GEN_64.. 死 wire 读取;
#   REG_N      —— 被 firtool 死 wire _GEN_167 读取。
# 关 SYNTHESIS 后两者的读者全裁剪 => 均为 cone-dead。verification_merge_duplicated_
# registers=true(305 默认)把每 lane 的 lastFire_N 与 REG_N 合并成一个代表寄存器
# REG_N_reg(值同 fire_N)。可读核只保留语义等价的 lastFire[N](同 `<= fire[g]`)。
# 二者是同源同逻辑的完美对称双射; auto_match 因 firtool 展平名 REG_N_reg 与 SV 数组名
# lastFire_reg[N] 结构差不能自动配对, 这里显式钉。配合
# verify_matched_unread_compare_points=true 令 FM 实际逐位证明等价(passing +5), unread 归 0。
# NB: array 下标 [N] 必须转义为 \[N\], 否则 Tcl 把 [N] 当命令替换执行(safe interp 下
#     `invalid command name "N"` → fm_eq.tcl sidecar_pin_source 报错 → rc=5)。
set_user_match r:/WORK/FusionDecoder/REG_reg   i:/WORK/FusionDecoder/u_core/lastFire_reg\[0\]
set_user_match r:/WORK/FusionDecoder/REG_1_reg i:/WORK/FusionDecoder/u_core/lastFire_reg\[1\]
set_user_match r:/WORK/FusionDecoder/REG_2_reg i:/WORK/FusionDecoder/u_core/lastFire_reg\[2\]
set_user_match r:/WORK/FusionDecoder/REG_3_reg i:/WORK/FusionDecoder/u_core/lastFire_reg\[3\]
set_user_match r:/WORK/FusionDecoder/REG_4_reg i:/WORK/FusionDecoder/u_core/lastFire_reg\[4\]
