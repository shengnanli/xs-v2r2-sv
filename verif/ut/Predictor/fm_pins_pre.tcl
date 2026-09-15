# Predictor FM 匹配前钉点 —— GHV（256 位全局分支历史）的结构双射
# ============================================================================
# 【为什么本目标需要钉点：这是一条实测结论，不是预防性优化】
#   Predictor 的 FM 匹配阶段**不终止**（docs/predictor_fm_scaling_wall.md）。
#   实测速率：头 59 分钟靠名字批量配上 52 万点（146.5 点/秒），随后两段各掉约两个
#   数量级 —— 0.950 点/秒，再到 **0.021 点/秒**（31 分钟只配上 38 个点）。按末段
#   外推，剩余 53.5 万点要约 302 天。内存 42 GB 稳定、CPU ~98%，既不是内存也不是
#   死锁：是匹配算法本身在这个规模上不收敛。
#
#   全工程 14 个目标有 fm_pins_pre.tcl，**规模最大的 Predictor 恰恰一个都没有**。
#   剩下那 53.5 万点没有任何名字线索，FM 只能逐个试结构签名。
#
# 【钉的是什么】
#   GHV = 全局分支历史向量，256 位环形寄存器（HIST_LEN）。
#     golden : reg ghv_0; … reg ghv_255;      256 个**散装标量** reg
#              G1-canonical/golden-rtl/Predictor.sv:1711-1966
#     可读核 : logic [255:0] ghv_q;           **一根 256 位向量**
#              rtl/frontend/Predictor.sv:532，逐位写在 generate 块 g_ghv 里（:548-559）
#   两侧是同一批 256 个 1 位触发器，只是一个散装、一个成向量。压缩比越高可读性越好，
#   Formality 的名字启发式就越认不出来 —— 这正是本工程核心手法的直接代价。
#
# 【双射是机械的，没有自由度】
#   第 n 位 golden ghv_<n> ←→ 可读核 ghv_q[n]。下标同号，逐位一一对应，
#   两侧都是 1 位 DFF（没有位宽要对齐的余地）。
#   ★产品 RTL 一个字都不改★：钉点是**只服务于证明的附加物**，不是让可读件
#   为了迁就 FM 而把向量拆回 256 个散装寄存器（codex 0162 D2）。
#
# 【为什么是 discover 而不是照着猜名字】
#   我**不知道** Formality 会把这两侧叫成什么 —— golden 是 ghv_0 还是 ghv_0_reg、
#   可读核是 u_core/ghv_q_reg[0] 还是 generate 作用域里的名字，都不是能从 RTL 直接
#   读出来的，它取决于本次 elaborate。所以本文件不写死任何一侧的层次：
#     · 核设计名   由 find_designs {i:/WORK/xs_*_core} 查出来（须恰 1 个）
#     · 核实例路径 由 find_cells -of_objectID <核设计> -type design 查出来（须恰 1 个）
#     · 两侧的 256 个点 由 find_cells 逐个枚举 + 正则提取下标
#   然后**断言**：两侧各恰 256 个、下标 0..255 完整、无重复、都是 1 位 —— 再按下标配对。
#   猜错名字会在断言处响亮地失败，而不是静默少钉几个。
#
#   （查得到的名字实测记录，2026-09-15，官方 runner 实跑于 commit da93a13：
#      ref  r:/WORK/Predictor/ghv_<n>_reg          n=0..255，恰 256 个
#      impl i:/WORK/Predictor/u_core/ghv_q_reg[<n>] n=0..255，恰 256 个
#    这组数只是**旁证**，本文件不依赖它 —— 上面三步每次跑都重新查一遍。）
#
# 【只做一件事】
#   只 set_user_match 消名差。不放宽任何比较、不约束 ref、不加黑盒、不动 appvar。
#   钉点只会让 FM 少猜，不会让它少证：被钉的点照样是比较点，照样要证等价。
#
# 【fail-closed】
#   256 个一个都不许钉不上。钉不上说明名字/结构与本次 elaborate 对不上，
#   那时继续跑出来的 SUCCEEDED 是假的 —— 直接 error 退出。
#   查询动词缺失（沙箱白名单没放行）同样 error：不允许退化成"照名字硬猜"。
# ============================================================================

if {$top eq "Predictor"} {
  set _expect 256

  # --- 0) 查询动词可用性：缺任何一个都不许退化成硬编码 -----------------------
  foreach _c {current_design find_cells find_designs} {
    if {[info commands $_c] eq ""} {
      error "PREDICTOR_PIN: 只读查询动词 '$_c' 不可用 —— 无法 discover，拒绝硬猜名字"
    }
  }

  # --- 1) discover 可读核的设计名与实例路径 ---------------------------------
  set _cores [find_designs "i:/WORK/xs_*_core"]
  if {[llength $_cores] != 1} {
    error "PREDICTOR_PIN: 期望恰 1 个 xs_*_core 设计，实得 [llength $_cores]: $_cores"
  }
  set _core [lindex $_cores 0]

  current_design "i:/WORK/$top"
  set _insts [find_cells -of_objectID $_core -type design]
  if {[llength $_insts] != 1} {
    error "PREDICTOR_PIN: 期望 $_core 在 i:/WORK/$top 下恰 1 个实例，实得 [llength $_insts]: $_insts"
  }
  set _inst [lindex $_insts 0]

  # --- 2) discover 两侧的 GHV 点，逐个提取下标 ------------------------------
  # 提取器：给定 design 前缀与叶名正则，返回 "下标 -> 全路径" 数组（下标重复即报错）。
  proc _ghv_scan {prefix leafrx label} {
    set _n [string length $prefix]
    array set _m {}
    foreach _c [find_cells] {
      if {[string range $_c 0 $_n] ne "$prefix/"} continue
      set _leaf [string range $_c [expr {$_n + 1}] end]
      if {![regexp $leafrx $_leaf -> _i]} continue
      # 下标按**字符串**做键：若真出现 ghv_007 这种写法，它不会被当成 7，
      # 而是在下面 0..255 完整性断言处露出来（少一个下标 → error）。
      if {[info exists _m($_i)]} {
        error "PREDICTOR_PIN($label): 下标 $_i 重复：$_m($_i) 与 $_c"
      }
      set _m($_i) $_c
    }
    return [array get _m]
  }

  # golden: 散装标量，叶名 ghv_<n>_reg，**不带位下标**（1 位 reg）
  # find_cells 只列 current_design 的 cell，所以每侧扫描前都要先切过去。
  current_design "r:/WORK/$top"
  array set _ref [_ghv_scan "r:/WORK/$top" {^ghv_([0-9]+)_reg$} ref]
  # 可读核: 向量，叶名 ghv_q_reg[<n>]，恰一层位下标（1 位切片）
  current_design $_core
  array set _imp [_ghv_scan $_core {^ghv_q_reg\[([0-9]+)\]$} impl]

  # --- 3) 断言：两侧各恰 256、下标 0..255 完整、无缺无多 ---------------------
  foreach {_label _arr} [list ref [array names _ref] impl [array names _imp]] {
    if {[llength $_arr] != $_expect} {
      error "PREDICTOR_PIN($_label): 期望 $_expect 个 GHV 点，实得 [llength $_arr]"
    }
  }
  for {set _i 0} {$_i < $_expect} {incr _i} {
    if {![info exists _ref($_i)]} { error "PREDICTOR_PIN(ref): 缺下标 $_i" }
    if {![info exists _imp($_i)]} { error "PREDICTOR_PIN(impl): 缺下标 $_i" }
  }

  # --- 4) 逐位钉点（impl 用**实例路径**，不是设计路径）----------------------
  set _n 0
  set _miss 0
  for {set _i 0} {$_i < $_expect} {incr _i} {
    set _r $_ref($_i)
    # 把 "i:/WORK/xs_Predictor_core/ghv_q_reg[3]" 换成 "i:/WORK/Predictor/u_core/ghv_q_reg[3]"
    set _leaf [string range $_imp($_i) [expr {[string length $_core] + 1}] end]
    set _ipath "$_inst/$_leaf"
    if {[catch {set_user_match $_r $_ipath} _msg]} {
      incr _miss
      if {$_miss <= 10} { puts "PREDICTOR_PIN_FAIL: $_r <-> $_ipath ($_msg)" }
    } else {
      incr _n
    }
  }

  # 恢复 current_design：进本文件时 fm_eq.tcl 刚 set_top 过 impl 顶层，
  # 后续步骤按那个上下文继续（本文件不该留下副作用）。
  current_design "i:/WORK/$top"

  puts "PREDICTOR_PINS: $_n / $_expect pinned, $_miss missed (ref=$_ref(0) impl=$_inst/...)"
  if {$_miss != 0 || $_n != $_expect} {
    error "PREDICTOR_PIN_MISS=$_miss n=$_n expect=$_expect"
  }
}
