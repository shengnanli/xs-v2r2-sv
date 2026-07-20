# Bku FM éç¹:golden ä¸å¤ funcReg(åå¼å¯æ¬,ç­¾åæ­§ä¹)ä¸éåæ ¸ func_reg ä¸ä¸å¯¹åº,
# å å±æ¬¡å+å¶åå·®å¼èªå¨éå¯¹å¤±è´¥ â éä½ set_user_matchãå®½åº¦: clmul 6 / crypto 1 / cipher 6ã
foreach {rp ip w} {
  clmulModule/funcReg_reg                     u_core/u_clmul/func_reg_reg           9
  cryptoModule/funcReg_reg                    u_core/u_crypto/func_reg_reg          1
  cryptoModule/blockCipherModule/funcReg_reg  u_core/u_crypto/u_cipher/func_reg_reg 9
} {
  for {set b 0} {$b < $w} {incr b} {
    set rl "r:/WORK/$top/${rp}\[$b\]"; set il "i:/WORK/$top/${ip}\[$b\]"
    if {[catch {set_user_match $rl $il} m]} {
      # 1 ä½å¯å­å¨å¯è½æ ä¸æ 
      catch {set_user_match "r:/WORK/$top/$rp" "i:/WORK/$top/$ip"}
    }
  }
}
puts "BKU_PINS: funcReg pinned"
