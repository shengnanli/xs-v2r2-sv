# Bku FM 钉点:golden 三处 funcReg(同值副本,签名歧义)与重写核 func_reg 一一对应,
# 因层次名+叶名差异自动配对失败 → 逐位 set_user_match。宽度: clmul 6 / crypto 1 / cipher 6。
foreach {rp ip w} {
  clmulModule/funcReg_reg                     u_core/u_clmul/func_reg_reg           9
  cryptoModule/funcReg_reg                    u_core/u_crypto/func_reg_reg          1
  cryptoModule/blockCipherModule/funcReg_reg  u_core/u_crypto/u_cipher/func_reg_reg 9
} {
  for {set b 0} {$b < $w} {incr b} {
    set rl "r:/WORK/$top/${rp}\[$b\]"; set il "i:/WORK/$top/${ip}\[$b\]"
    if {[catch {set_user_match $rl $il} m]} {
      # 1 位寄存器可能无下标
      catch {set_user_match "r:/WORK/$top/$rp" "i:/WORK/$top/$ip"}
    }
  }
}
puts "BKU_PINS: funcReg pinned"
