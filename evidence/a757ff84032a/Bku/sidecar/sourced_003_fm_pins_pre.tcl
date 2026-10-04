# Bku FM 匹配前钉点 —— 顶层 func 流水寄存器的整寄存器双射（2026-09-12 诊断）
# ============================================================================
# 症状：signoff-strict 下 `make fm-Bku` 报 6(6) unmatched **unread** points：
#         Ref  r:/WORK/Bku/funcReg_reg[0,1,4,6,7,8]
#         Impl i:/WORK/Bku/u_core/func_s1_reg[0,1,4,6,7,8]
#       compare point 侧是 0(0) unmatched、3371 passing / 0 failing。
#
# 根因：**只是名字对不上**，与 FCVT 的 result_r*/mvResult_s* 同型。
#         golden  Bku.sv:170  reg [8:0] funcReg;
#                 Bku.sv:212  if (rdyVec_0 & io_in_valid) funcReg <= io_in_bits_ctrl_fuOpType;
#                 Bku.sv:215-219 只读 funcReg[5] / funcReg[3] / funcReg[2]
#         可读核  Bku.sv:237  logic [8:0] func_s1;
#                 Bku.sv:239  if (fire_s0)  func_s1 <= in_fuOpType;   (fire_s0 = in_valid & rdy_s0)
#                 Bku.sv:243-246 只读 func_s1[5] / func_s1[3] / func_s1[2]
#                 (FUNC_CRYPTO_BIT=5, FUNC_COUNT_BIT=3, FUNC_MISC_BIT=2)
#       同宽(9)、同源(fuOpType)、同使能、**死位下标集合逐位相同 {0,1,4,6,7,8}**。
#       活位 {2,3,5} 有输出锥，FM 靠 signature analysis 已经配上了；死位没有输出锥，
#       签名分析无从下手，名字词干又不同(funcReg vs func_s1)，于是两侧各剩 6 个
#       unmatched unread。
#
# 本钉点做的是**整寄存器 9 位一一对应**（不是只挑 6 个死位）：
#   - 只修名字匹配：不 dont_verify、不加黑盒、不约束 ref、不跳过任何比对点；
#   - 活位 {2,3,5} 原本由签名分析推出来，钉死后改由显式对应给出——只会更严，
#     因为若可读核真把某一位接错，钉成这个对应会让 FM **失败**而不是掩盖；
#   - pin 数必须精确 = 9，miss 必须 = 0（下面的计数行会打印出来）。
#
# 注意：钉点只把 6 个 unmatched-unread 变成 6 对 matched-unread，unread 计数会从
#       14 升到 20（14 = 共享 golden 叶子 countModule/cryptoModule 内的对称死位）。
#       要让 signoff-strict 的 unread 归零还需要 target-scoped 的
#       verification_verify_matched_unread_compare_points=true（白名单在
#       scripts/fm_eq.tcl，**本轮未申请、未开启**，留待 reviewer 裁定）。
# ============================================================================

if {$top eq "Bku"} {
  set _n 0
  set _miss 0
  for {set b 0} {$b < 9} {incr b} {
    if {[catch {set_user_match "r:/WORK/$top/funcReg_reg\[$b\]" \
                               "i:/WORK/$top/u_core/func_s1_reg\[$b\]"} _msg]} {
      incr _miss
      puts "BKU_PINS_MISS: bit $b : $_msg"
    } else {
      incr _n
    }
  }
  puts "BKU_PINS: funcReg<->func_s1 whole-register bijection pinned=$_n miss=$_miss (expect 9 / 0)"
}
