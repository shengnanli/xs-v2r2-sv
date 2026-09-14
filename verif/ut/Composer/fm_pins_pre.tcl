# Composer FM 匹配前钉点 —— 影子 PC 流水的 601 个对称死位
# ============================================================================
# 【钉的是什么】
#   Composer 这一层自己的全部时序状态里，有一条 cone-dead 的"影子 PC 流水"：
#     modified_reset        1 位   —— "复位刚放开"的一拍脉冲，只用来给 s1_pc 灌复位向量
#     s1_pc  [4][50]      200 位   —— s0_fire 时锁存的取指 PC，4 份 dup
#     s2_pc  [4][26+12+12] 200 位  —— utility.SegmentedAddrNext 的分段打拍（s1->s2）
#     s3_pc  [4][26+12+12] 200 位  —— 同上（s2->s3）
#   SegmentedAddrNext 把 50 位 PC 切三段（seg_0 = pc[49:24] 26 位、seg_1 = pc[23:12]
#   12 位、seg_2 = pc[11:0] 12 位），高两段"值变了才打拍"（低段的 modified 条件被
#   firtool 常量折叠成 1'h1），目的是省高位段的翻转功耗。
#   golden 声明见 G1-canonical/golden-rtl/Composer.sv:1323-1415，两级段更新的
#   always 块见同文件 1459-1491；可读核对应实现见 rtl/frontend/Composer.sv 的
#   xs_Composer_core §1/§2。
#
# 【为什么两侧都是死位（同一死因）】
#   这条流水在本 build 里整条 cone-dead：s3 段寄存器拼出来的地址
#   （golden 的 s3_pc_dup_debug_s3_pc_addr / 可读核的 s3_pc_addr）没有任何消费者，
#   真正送出去的 io_out_s1_pc 由链头 uftb 驱动、io_out_s2/s3_pc 由链尾 ras 驱动，
#   跟这条影子流水无关。往回推：s2 段唯一读出点是 s3 段，s1_pc 唯一读出点是 s2 段，
#   modified_reset 唯一读出点是 s1_pc —— 整条链零扇出（自反馈不构成"被读"）。
#   它们仍是**真寄存器**（Chisel/firtool 保留、可读核照抄），FM 会枚举成点，
#   不能省、也不能靠"改结构消掉"——那会改掉 golden 的状态集。
#
# 【为什么本该配上却没配：多维数组 vs firtool 展平命名】
#   golden（firtool 展平）: s1_pc_dup_<dup>_reg[bit]
#                           s2_pc_dup_s2_pc_seg_<seg>_value[_<dup>]_reg[bit]
#   可读核（SV 二维数组）  : u_core/s1_pc_reg[dup][bit]
#                           u_core/s2_pc_<hi|mid|lo>_reg[dup][bit]
#   词干不同（seg_0/value_1 vs hi + 数组下标），层次还差一层 u_core。
#   fm_eq.tcl 里的 auto_match_flattened_arrays 救不了：它只读
#   report_unmatched_points（不含 unread 类），且它的展平键 s2_pc_hi_<dup>_<bit>_reg
#   与 golden 的 s2_pc_dup_..._value_<dup>_reg[bit] 也对不上。
#
#   ★这里有一个实测才暴露的坑（2026-09-14，本目标）★
#   默认（不加强）跑时，s2/s3 那 400 点是 400(400) **unmatched** unread，而
#   s1_pc 的 200 点与 modified_reset 却被 FM 自己配上了、算 matched unread。
#   一旦打开 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS（未读点升级成比对点），
#   s1_pc 那 200 点的配对就**掉了**，变成新的 200(200) unmatched unread ——
#   于是只钉 400 的那一版仍然是 PARTIAL（实测 compare points 526085、
#   unmatched unread 200(200)）。结论：属于这条影子流水的点必须**整条**钉，
#   不能只钉"当前报出来没配上的那一批"。本文件因此钉满 601。
#
# 【双射是机械的，不是人工强配】
#   对应关系由结构唯一确定，没有自由度：
#     seg_0 <-> hi (26 位)  seg_1 <-> mid (12 位)  seg_2 <-> lo (12 位)
#     dup 后缀：无后缀 <-> dup 0；_1/_2/_3 <-> dup 1/2/3（s1_pc 四份都带显式下标）
#     位下标逐位同号
#   生成的 601 条 ref 路径与 601 条 impl 路径，与**未加强那次跑**实测的全部
#   Composer 本层未读点集合精确相等（无多、无缺），由
#   tools/predictor_composer/check_pin_bijection.py 机械核对。
#
# 【只做一件事】
#   只 set_user_match 消名差：不 dont_verify、不约束 ref、不扩黑盒。
#   钉完配合 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true（加强，非放宽），
#   FM 会把这 601 点当真比对点去证。
#
# 【fail-closed】
#   一条都不许钉不上：钉不上说明段布局/实例名与本次 elaborate 的设计对不上，
#   那时继续跑出来的 SUCCEEDED 是假的，直接 error 退出。
# ============================================================================

if {$top eq "Composer"} {
  set _n 0
  set _miss 0
  set _pairs {}

  # (1) 复位脉冲：叶名相同，只差 u_core 一层
  lappend _pairs [list "modified_reset_reg" "u_core/modified_reset_reg"]

  # (2) s1_pc：4 份 dup × 50 位，golden 四份都带显式下标
  for {set _d 0} {$_d < 4} {incr _d} {
    for {set _b 0} {$_b < 50} {incr _b} {
      lappend _pairs [list "s1_pc_dup_${_d}_reg\[$_b\]" "u_core/s1_pc_reg\[$_d\]\[$_b\]"]
    }
  }

  # (3) s2/s3 分段寄存器：{seg 索引  可读核段名  位宽}，取自 golden 的段声明
  set _segs {0 hi 26 1 mid 12 2 lo 12}
  foreach _stage {2 3} {
    for {set _d 0} {$_d < 4} {incr _d} {
      # firtool 对 dup 0 不加后缀，dup 1/2/3 加 _1/_2/_3
      set _sfx [expr {$_d == 0 ? "" : "_$_d"}]
      foreach {_si _sname _w} $_segs {
        for {set _b 0} {$_b < $_w} {incr _b} {
          lappend _pairs [list \
            "s${_stage}_pc_dup_s${_stage}_pc_seg_${_si}_value${_sfx}_reg\[$_b\]" \
            "u_core/s${_stage}_pc_${_sname}_reg\[$_d\]\[$_b\]"]
        }
      }
    }
  }

  foreach _p $_pairs {
    set _r "r:/WORK/$top/[lindex $_p 0]"
    set _i "i:/WORK/$top/[lindex $_p 1]"
    if {[catch {set_user_match $_r $_i} _msg]} {
      incr _miss
      if {$_miss <= 10} { puts "COMPOSER_PIN_FAIL: $_r <-> $_i ($_msg)" }
    } else {
      incr _n
    }
  }
  puts "COMPOSER_PINS: $_n / 601 pinned, $_miss missed"
  if {$_miss != 0 || $_n != 601} { error "COMPOSER_PIN_MISS=$_miss n=$_n" }
}
