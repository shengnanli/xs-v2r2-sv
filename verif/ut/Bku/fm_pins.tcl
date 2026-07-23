# Bku FM 钉点(匹配后 set_user_match, 不约束 ref, 非 dont_verify/非 waiver)。
#
# golden Bku 顶层 + 4 个子单元(CountModule/ClmulModule/CryptoModule/BlockCipherModule)
# 各自声明一份 `reg [8:0] funcReg`, 全部锁存同一 io_func(=fuOpType) 副本。可读核对应
# 5 份 `func_reg`(顶层 u_core + u_count/u_clmul/u_crypto/u_crypto/u_cipher)。
#
# 每个模块的 result-mux 只读该 funcReg 的一个子集位:
#   top Bku       读 [5]/[3]/[2]        → [0][1][4][6][7][8] 两侧对称死
#   CountModule   读 [2]/[1]/[0]        → [3]..[8]            两侧对称死
#   CryptoModule  读 [4]                → [0]..[3][5]..[8]    两侧对称死
#   ClmulModule   整字比较(func_reg==..) → 只低位有效, 高位对称死
#   BlockCipher   整字比较(func_reg==..) → 部分位对称死
# 未读位在两侧都无扇出(bug-for-bug 对称 cone-dead)。因层次名(cryptoModule vs
# u_core/u_crypto)+ 叶名(funcReg vs func_reg)差异, auto_match_flattened_arrays 配不上,
# 故这里对 5 模块 × 9 位逐位显式双射 set_user_match。配合 vmucp=true, FM 会实际比较
# 这些 matched 点并证明恒相等(同源同拍锁存 fuOpType), 死位从 unread 转入 passing。
#
# 映射表: {ref 相对路径}  {impl 相对路径}  {位宽}
foreach {rp ip w} {
  funcReg_reg                                 u_core/func_reg_reg                   9
  countModule/funcReg_reg                     u_core/u_count/func_reg_reg           9
  clmulModule/funcReg_reg                     u_core/u_clmul/func_reg_reg           9
  cryptoModule/funcReg_reg                    u_core/u_crypto/func_reg_reg          9
  cryptoModule/blockCipherModule/funcReg_reg  u_core/u_crypto/u_cipher/func_reg_reg 9
} {
  for {set b 0} {$b < $w} {incr b} {
    set rl "r:/WORK/$top/${rp}\[$b\]"; set il "i:/WORK/$top/${ip}\[$b\]"
    if {[catch {set_user_match $rl $il} m]} {
      # 1 位寄存器可能无下标(此处均为 9 位, 保留兜底)
      catch {set_user_match "r:/WORK/$top/$rp" "i:/WORK/$top/$ip"}
    }
  }
}
puts "BKU_PINS: 5x funcReg (top/count/clmul/crypto/cipher) x 9-bit pinned"
