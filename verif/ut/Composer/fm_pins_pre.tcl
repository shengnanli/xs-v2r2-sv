# Composer FM 匹配前钉点 —— SegmentedAddrNext 影子 PC 流水的 400 个对称死位
# ============================================================================
# 【钉的是什么】
#   golden Composer 里有一条 utility.SegmentedAddrNext 的"影子 PC 流水"：把 50 位
#   取指 PC 切成三段（seg_0 = pc[49:24] 26 位、seg_1 = pc[23:12] 12 位、
#   seg_2 = pc[11:0] 12 位），s1→s2→s3 逐级打拍，且高两段"值变了才打拍"（低段的
#   modified 条件被 firtool 常量折叠成 1'h1）。PC 在 BPU 里复制成 4 份（dup），
#   于是 s2/s3 两级 × 4 份 × 50 位 = 400 个寄存器位。
#   golden 声明见 G1-canonical/golden-rtl/Composer.sv:1328-1415（段寄存器）与
#   1459-1491（两级段更新的 always 块）；可读核对应实现见
#   rtl/frontend/Composer.sv 的 xs_Composer_core §2（s2_pc_{hi,mid,lo} /
#   s3_pc_{hi,mid,lo}，均为 [NUM_DUP] 数组）。
#
# 【为什么两侧都是死位（同一死因）】
#   这条流水在本 build 里 **cone-dead**：s3 段寄存器拼出来的地址
#   （golden 的 s3_pc_dup_debug_s3_pc_addr / 可读核的 s3_pc_addr）没有任何消费者，
#   真正送出去的 io_out_s1_pc 由链头 uftb 驱动、io_out_s2/s3_pc 由链尾 ras 驱动，
#   跟这条影子流水无关；s2 段寄存器唯一的读出点就是 s3 段（以及自身的 modified
#   比较，自反馈不构成"被读"）。所以整条 s2/s3 在两侧同为零扇出。
#   它们仍是**真寄存器**（Chisel/firtool 保留、可读核照抄），FM 会枚举成点，
#   不能省、也不能靠"改结构消掉"——那会改掉 golden 的状态集。
#
# 【为什么本该配上却没配：多维数组 vs 展平命名】
#   golden（firtool 展平）: s2_pc_dup_s2_pc_seg_<seg>_value[_<dup>]_reg[bit]
#   可读核（SV 二维数组）  : u_core/s2_pc_<hi|mid|lo>_reg[dup][bit]
#   词干完全不同（seg_0/value_1 vs hi + 数组下标），层次还差一层 u_core；
#   又因为它们是 unread、不进比对，签名分析也不会去救 ⇒ 400(ref) + 400(impl)
#   unmatched unread。fm_eq.tcl 里的 auto_match_flattened_arrays 也救不了：
#   它只读 report_unmatched_points（不含 unread 类），且它的展平键
#   s2_pc_hi_<dup>_<bit>_reg 与 golden 的 s2_pc_dup_..._value_<dup>_reg[bit] 对不上。
#
# 【双射是机械的，不是人工强配】
#   对应关系由段布局唯一确定，没有自由度：
#     seg_0 <-> hi  (26 位, pc[49:24])   seg_1 <-> mid (12 位, pc[23:12])
#     seg_2 <-> lo  (12 位, pc[11:0])
#     value 无后缀 <-> dup 0；_1/_2/_3 <-> dup 1/2/3；bit 下标逐位同号
#   下面这段循环生成的 400 条 ref 路径与 400 条 impl 路径，与实测 unread 点集合
#   **精确相等**（无多、无缺，见 UT Makefile 的验收记录），即严格 400↔400 双射。
#
# 【只做一件事】
#   只 set_user_match 消名差：不 dont_verify、不约束 ref、不扩黑盒。
#   钉完配合 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true（加强，非放宽），
#   FM 会把这 400 点当真比对点去证。
#
# 【fail-closed】
#   一条都不许钉不上：钉不上说明段布局/实例名与本次 elaborate 的设计对不上，
#   那时继续跑出来的 SUCCEEDED 是假的，直接 error 退出。
# ============================================================================

if {$top eq "Composer"} {
  set _n 0
  set _miss 0
  # {seg 索引  可读核段名  位宽} —— 取自 golden Composer.sv 的段声明
  set _segs {0 hi 26 1 mid 12 2 lo 12}
  foreach _stage {2 3} {
    for {set _d 0} {$_d < 4} {incr _d} {
      # firtool 对 dup 0 不加后缀，dup 1/2/3 加 _1/_2/_3
      set _sfx [expr {$_d == 0 ? "" : "_$_d"}]
      foreach {_si _sname _w} $_segs {
        for {set _b 0} {$_b < $_w} {incr _b} {
          set _r "r:/WORK/$top/s${_stage}_pc_dup_s${_stage}_pc_seg_${_si}_value${_sfx}_reg\[$_b\]"
          set _i "i:/WORK/$top/u_core/s${_stage}_pc_${_sname}_reg\[$_d\]\[$_b\]"
          if {[catch {set_user_match $_r $_i} _msg]} {
            incr _miss
            if {$_miss <= 10} { puts "COMPOSER_PIN_FAIL: $_r <-> $_i ($_msg)" }
          } else {
            incr _n
          }
        }
      }
    }
  }
  puts "COMPOSER_PINS: $_n / 400 pinned, $_miss missed"
  if {$_miss != 0 || $_n != 400} { error "COMPOSER_PIN_MISS=$_miss n=$_n" }
}
