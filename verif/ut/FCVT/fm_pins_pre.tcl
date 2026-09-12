# FCVT FM 匹配前钉点 —— fmv 旁路两级流水的寄存器双射（2026-09-12 反例诊断）
# ============================================================================
# 症状：signoff-strict 下 `make fm-FCVT` 报 20 个 failing compare point，
#       全部是 Ref r:/WORK/FCVT/result_r_1_reg[b] <-> Impl u_core/mvResult_s1_reg[b]，
#       且 "0 unmatched" —— 看上去像功能不等价，其实是**配对错位**。
#
# 根因：本模块的 fmv(fmv.x.w/fmv.x.d) 旁路是两级流水，两级都是 64bit、都无复位、
#       结构高度对称，只有使能不同：
#         golden : result_r  (使能 io_in_valid)      -> result_r_1 (使能 fireReg_last_r)
#         可读核 : mvResult_s1(使能 io_in_valid)      -> mvResult_s2(使能 fireReg_last)
#       两侧叶名词干完全不同(result_r* vs mvResult_s*)，Formality 的名字匹配退化成
#       「看尾部序号」：ref 的 result_r_1 与 impl 的 mvResult_s1 都带序号 1，于是被配成
#       一对，剩下的 result_r 只能与 mvResult_s2 相配 —— **恰好把两级前后颠倒**。
#       颠倒后 ref 的第 2 级对 impl 的第 1 级，自然处处不等价；因为默认
#       verification_failing_point_limit=20，报满 20 个就停，剩下 44 位落进
#       "unverified"，所以 failing 数看起来是个奇怪的 20 而不是 64。
#
# 证据：把两级按语义强制配对后（本文件所做的事），同样的两份 RTL、同样的 appvar，
#       Formality 给出 Verification SUCCEEDED / 0 failing / 0 unverified。
#       也就是说设计本身与 golden 等价，UT 三 seed × 200k 拍 errors=0 并没有漏报。
#       （反证：把可读核末级选择器改成取 mvResult_s1，UT 立刻大量 res_data 失配。）
#
# 本钉点只做「名字对不上时的一一对应」：不 dont_verify、不加黑盒、不约束 ref。
# 若哪天可读核真把两级写反了，钉成这个对应只会让 FM **失败**，不会掩盖问题。
# ============================================================================

if {$top eq "FCVT"} {
  set _n 0
  set _miss 0
  for {set b 0} {$b < 64} {incr b} {
    # 第 1 级：源按 sew 符号扩展后落寄存器
    if {[catch {set_user_match "r:/WORK/$top/result_r_reg\[$b\]" \
                               "i:/WORK/$top/u_core/mvResult_s1_reg\[$b\]"}]} {
      incr _miss
    } else {
      incr _n
    }
    # 第 2 级：对齐到写回级（fireReg_last 使能）
    if {[catch {set_user_match "r:/WORK/$top/result_r_1_reg\[$b\]" \
                               "i:/WORK/$top/u_core/mvResult_s2_reg\[$b\]"}]} {
      incr _miss
    } else {
      incr _n
    }
  }
  puts "FCVT_PINS: fmv bypass 2-stage bijection pinned=$_n miss=$_miss (expect 128 / 0)"
}
