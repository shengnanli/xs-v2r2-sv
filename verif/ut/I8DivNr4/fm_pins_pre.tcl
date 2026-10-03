# I8DivNr4 FM「匹配前」钉点 —— 除数倍数寄存器的 4 个死最高位（2026-10-03，agent/srt-divblocks）
# ============================================================================
# 症状（诊断跑，signoff-strict 口径 + vmucp=false，fm_work/I8DivNr4，commit a5e76872）：
#   native SUCCEEDED / passing 106 / failing 0 / unmatched compare points 0 /
#   constant reg 1 / 4(4) Unmatched reference(implementation) **unread** points：
#     ref   r:/WORK/I8DivNr4/const_d_reg_<k>_reg[9]          k = 0..3
#     impl  i:/WORK/I8DivNr4/u_core/const_d_reg_reg[<k>][9]
#
# 这 4 位是什么：Chisel 里 const_d = VecInit(-d + (-d<<1), -d, d, d + (d<<1))，
#   (-d<<1) 把元素宽度撑到 10 位，Vec 统一取最宽，于是四档都是 10 位寄存器；
#   但唯一的读者 IterBlockI8Nr4.io_d_cons_k 只有 9 位（golden I8DivNr4.sv 的
#   `.io_d_cons_k (const_d_reg_k[8:0])`），POST 段又只读 const_d_reg_1/2 的 [7:0]。
#   ⇒ 四档的 bit 9 在 golden 里**没有任何读者**。可读核照存同样的 10 位字段
#   （CONVENTIONS「寄存器字段集合逐字照搬」），读者也逐位相同 ⇒ 两侧同为死位，
#   k↔k 严格双射（同一档、同一位），非本 4 点的 unread 为 0。
#
# 为什么 FM 自己配不上：活位 [8:0] 有输出锥，签名分析已配好（在 106 个 passing 里）；
#   死位无输出锥只能靠名字，两侧词干不同：golden 平铺 const_d_reg_<k>，核为数组 const_d_reg[k]。
#
# 本钉点只消名差：不 dont_verify、不加黑盒、不约束 ref、不跳过任何比对点。
# 钉上后成为 matched-unread，再由 verif/fm_target_config/I8DivNr4.tcl 允许的
# verification_verify_matched_unread_compare_points=true 让 FM **真去比这 4 位**。
# fail-closed：用 set_user_match 的返回值计数（它找不到名字不抛异常），字面整数守卫，
# 中止一律 error（safe interp 里没有 exit）。
# ============================================================================
set _n 0
if {[set_user_match "r:/WORK/$top/const_d_reg_0_reg\[9\]" "i:/WORK/$top/u_core/const_d_reg_reg\[0\]\[9\]"]} { incr _n } else { puts "I8DIVNR4_PIN_FAIL: const_d_reg_0\[9\]" }
if {[set_user_match "r:/WORK/$top/const_d_reg_1_reg\[9\]" "i:/WORK/$top/u_core/const_d_reg_reg\[1\]\[9\]"]} { incr _n } else { puts "I8DIVNR4_PIN_FAIL: const_d_reg_1\[9\]" }
if {[set_user_match "r:/WORK/$top/const_d_reg_2_reg\[9\]" "i:/WORK/$top/u_core/const_d_reg_reg\[2\]\[9\]"]} { incr _n } else { puts "I8DIVNR4_PIN_FAIL: const_d_reg_2\[9\]" }
if {[set_user_match "r:/WORK/$top/const_d_reg_3_reg\[9\]" "i:/WORK/$top/u_core/const_d_reg_reg\[3\]\[9\]"]} { incr _n } else { puts "I8DIVNR4_PIN_FAIL: const_d_reg_3\[9\]" }
puts "I8DIVNR4_PINS: dead const_d_reg_k\[9\] $_n / 4 points pinned"
if {$_n != 4} { error "I8DIVNR4_PIN_COUNT=$_n expected 4" }
