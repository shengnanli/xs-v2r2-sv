# LoadUnit FM 钉点（FM 审计 2026-07）
# 1) s2_in excVec 的 5/13 两位签名对称（laf/lpf 锥结构同构），签名匹配曾交叉错配
#    （golden _5 ↔ impl [13]），需先回 setup 清掉签名配对、显式钉正后由脚本重新 match。
# 2) trigger[1]（action 低位差异位）与两级 vecActive 副本自动配对失败，显式钉。
# 3) mmio 影子链 debug_isNCIO/isPerfCnt 为常量 0 打拍链（初值 X），FM 对 ref 判 DFF0X
#    删除、对 impl 判 DFFX 保留（不对称），set_constant 双侧钉 0（须 setup 模式）。
setup

# ---- excVec 5/13 钉正 ----
catch {set_user_match "r:/WORK/$top/s2_in_r_uop_exceptionVec_13_reg" \
                      "i:/WORK/$top/u_core/s2_in_excVec_reg\[13\]"}
catch {set_user_match "r:/WORK/$top/s2_in_r_uop_exceptionVec_5_reg" \
                      "i:/WORK/$top/u_core/s2_in_excVec_reg\[5\]"}
catch {set_user_match "r:/WORK/$top/s3_in_uop_exceptionVec_13_reg" \
                      "i:/WORK/$top/u_core/s3_in_excVec_reg\[13\]"}
catch {set_user_match "r:/WORK/$top/s3_in_uop_exceptionVec_5_reg" \
                      "i:/WORK/$top/u_core/s3_in_excVec_reg\[5\]"}

# ---- trigger（4 位）逐位钉（[2:3] 在 MERGE_DUP=false 下应恢复为比对点）----
for {set b 0} {$b < 4} {incr b} {
  catch {set_user_match "r:/WORK/$top/s2_in_r_uop_trigger_reg\[$b\]" \
                        "i:/WORK/$top/u_core/s2_in_trigger_reg\[$b\]"}
  catch {set_user_match "r:/WORK/$top/s3_in_uop_trigger_reg\[$b\]" \
                        "i:/WORK/$top/u_core/s3_in_trigger_reg\[$b\]"}
}

# ---- vecActive 两份副本（异步复位版 / 无复位版）----
catch {set_user_match "r:/WORK/$top/s1_vecActive_reg" \
                      "i:/WORK/$top/u_core/s1_vecActive_reg"}
catch {set_user_match "r:/WORK/$top/s1_in_r_vecActive_reg" \
                      "i:/WORK/$top/u_core/s1_in_vecActive_reg"}

# ---- perf 打拍链（双份 s0_fire 链 + 常量 0 链）1:1 ----
foreach {rp ip} {
  io_perf_0_value_REG_reg   perf0_d_reg
  io_perf_0_value_REG_1_reg perf0_dd_reg
  io_perf_1_value_REG_reg   perf1_d_reg
  io_perf_1_value_REG_1_reg perf1_dd_reg
  io_perf_3_value_REG_reg   perf3_d_reg
  io_perf_3_value_REG_1_reg perf3_dd_reg
} {
  catch {set_user_match "r:/WORK/$top/$rp" "i:/WORK/$top/u_core/$ip"}
}

# NOTE(deadref-contract-B, codex_0089): the previous line
#   catch {set_app_var verification_assume_reg_init none}
# was REMOVED. Empirically it masked NOTHING: with the FM default
# (verification_assume_reg_init auto) the LoadUnit native proof is still
# SUCCEEDED with failing=0, unmatched=0, unread_impl=0 and the SAME 89
# golden-only cone-dead unread_ref residual. The relax only turned a handful
# of no-reset init points from "compared-equivalent" into "compared" (passing
# 7714->7705) and, critically, registered a spurious relaxed_appvars
# qualification that forced PARTIAL. There is no impl over-wide register /
# multi-driver / undriven-signal asymmetry to fix (impl side is 100% clean).
# The residual 89 points are declared golden-only cone-dead in
# verif/signoff/dead_ref/LoadUnit.json (vec-vaddr page-scale high bits, assertion
# registers, dangling dontTouch debug wires). Removing the relax makes the proof
# a clean strict PASS_DEAD_REF with zero qualifications.
puts "LOADUNIT_PINS: applied (no relaxed appvars)"
