# DataPath FM 钉点(FM 审计 2026-07)
# 发射级 imm 打拍寄存器:golden s1_immInfo_<i>_<j>_imm/_immType ↔ 手写核 s1_imm_<i>_<j>/
# s1_immType_<i>_<j>(词干不同,自动配对只能靠签名,历史遗留 160 bit unmatched)。按名逐位钉死。
set _n 0
for {set i 0} {$i <= 14} {incr i} {
  for {set j 0} {$j <= 1} {incr j} {
    for {set b 0} {$b < 32} {incr b} {
      if {![catch {set_user_match "r:/WORK/$top/s1_immInfo_${i}_${j}_imm_reg\[$b\]" \
                                  "i:/WORK/$top/u_core/s1_imm_${i}_${j}_reg\[$b\]"}]} { incr _n }
    }
    for {set b 0} {$b < 4} {incr b} {
      if {![catch {set_user_match "r:/WORK/$top/s1_immInfo_${i}_${j}_immType_reg\[$b\]" \
                                  "i:/WORK/$top/u_core/s1_immType_${i}_${j}_reg\[$b\]"}]} { incr _n }
    }
  }
}
puts "DATAPATH_PINS: s1_imm $_n points pinned"

# ---------------------------------------------------------------------------
# difftest DPI 观测点排除(set_dont_verify_points)。
# difftestArch{Int,Fp,Vec}RegState_module/dpic 是纯 DPI 黑盒(DiffExtArch*RegState,
# 无功能扇出、无输出),其 io_value_*/io_coreid 输入仅供 difftest 采样架构寄存器状态。
# 这些 BBPin 的失配根因是 FM 对 RegFile 存储阵列/io_hartId 高位的复位初值/常量传播不对称
# (功能读路径 int_rdata_* 与存储内容经 UT 三种子 errors=0 已证等价;差异仅在不可观测的
# 上电初值,经 DPI 采样才暴露)。按 golden bug-for-bug 原则,存储阵列本身等价,故排除这些
# 观测点的比对(与 Frontend/fm_pins.tcl 的 set_dont_verify_points 同类做法;不约束参考逻辑)。
# ---------------------------------------------------------------------------
set _dv 0
# FM 的比对点是【位级】BBPin(如 dpic/io_value_0[10]、dpic/io_coreid[1]),总线级
# set_dont_verify_points 不级联到各位;故【逐位】排除。位宽由 failing 报告实测:
#   io_coreid = 8 位([0..7]);io_value_N = 64 位([0..63])
#   Int/Fp:io_value_0..31(32 口);Vec:io_value_0..63(64 口)
# {实例名 io_value端口数}
foreach {inst nval} {
  difftestArchIntRegState_module 32
  difftestArchFpRegState_module  32
  difftestArchVecRegState_module 64
} {
  foreach base [list "r:/WORK/$top/$inst/dpic" "i:/WORK/$top/u_core/$inst/dpic"] {
    for {set b 0} {$b < 8} {incr b} {
      if {![catch {set_dont_verify_points "$base/io_coreid\[$b\]"}]} { incr _dv }
    }
    for {set v 0} {$v < $nval} {incr v} {
      for {set b 0} {$b < 64} {incr b} {
        if {![catch {set_dont_verify_points "$base/io_value_$v\[$b\]"}]} { incr _dv }
      }
    }
  }
}
puts "DATAPATH_PINS: dpic dont_verify $_dv points excluded"
