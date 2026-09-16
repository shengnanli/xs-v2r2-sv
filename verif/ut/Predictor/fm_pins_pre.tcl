# Predictor FM 匹配前钉点 —— GHV（256 位全局分支历史）的结构双射
# ============================================================================
# 【为什么本目标需要钉点】
#   ★本段原先写的是「匹配不终止、外推 302 天」—— 那是错的，2026-09-15 已撤回。★
#   成因：把 Formality 的匹配进度条（`NNNM/NNN (49% Matched)`）当成了线性进度。
#   它的分母约是配对数的两倍（ref+impl 两侧对象合计），**按构造到不了 100%**，
#   配完时正好停在 49% 附近。我们据此把两次跑提前杀了。
#   详见 docs/predictor_fm_scaling_wall.md（已整篇重写）与 scripts/fm_verdict.py 的文档。
#
#   实测的真实情况（带本文件的钉点那次跑）：匹配**收敛**，约 2.6 小时配完，
#     256    Compare points matched by user            ← 就是本文件钉的
#     517783 Compare points matched by name
#     2461   Compare points matched by signature analysis
#     134(6) Unmatched reference(implementation) compare points
#     1113(1826) Unmatched reference(implementation) unread points
#   随后进入 Status: Verifying...
#
#   所以钉点要解决的是那 **134+6 个未配比较点**与 **1113/1826 个未配 unread 点**，
#   与本工程其它目标同一量级（Composer 当年也要处理 6,323 个 unread 才转绿）。
#   本文件的 GHV 256 点是第一批，不是全部。
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

  # --- 0) 查询动词可用性：缺它就不许退化成硬编码 -----------------------------
  #
  # ★只用 find_cells 一个动词★（2026-09-15 实测后收窄）。
  # 原先还用了 current_design 与 find_designs。实测（90 秒探针）表明：
  #   find_cells 直接吃**全路径 pattern**，根本不需要先切 current_design
  #     find_cells {r:/WORK/Predictor/ghv_*_reg}          -> 256
  #     find_cells {i:/WORK/xs_Predictor_core/ghv_q_reg*} -> 256
  #     find_cells {i:/WORK/Predictor/*}                  -> 21 个顶层实例
  #   全程 current_design 保持进入时的 '0'（未设置），一次都没碰。
  # 用不着的权限就不该要：白名单里去掉 current_design 与 find_designs 之后，
  # codex 0163 给 current_design 附的那四条纪律也就不适用了 —— 没有上下文可改，
  # 就不会留下上下文副作用。
  #
  # ★为什么必须收窄★：current_design 的失败模式与 set_top 一模一样 ——
  # 名字非法时**不抛异常**，只打 `Error: Unknown name (FM-036)` 并把当前设计置空。
  # 我照 codex 四条纪律写的第一版就踩了：进入态其实是"未设置"('0')，
  # 我却拿 current_design "0" 去"恢复"，等于用一条报错凑出不变量，
  # 还往证明日志里塞了一条 Error。本工程为 set_top 写过 set_top_or_die，
  # 现在确认这是这套工具的**通用形状**，不是个例。
  if {[info commands find_cells] eq ""} {
    error "PREDICTOR_PIN: 只读查询动词 'find_cells' 不可用 —— 无法 discover，拒绝硬猜名字"
  }


  # --- 1) discover：两侧的点怎么枚举、钉点用哪条路径 -------------------------
  #
  # ★find_cells 的作用域语义（2026-09-15 三轮探针实测，别再猜）★
  #   F  find_cells {i:/WORK/Predictor/*}                  -> 21 个**顶层实例**
  #      （C0..C15 / Logic0_ / Logic1 / ctrl_delay / predictors / u_core）
  #   H  find_cells {i:/WORK/xs_*_core/ghv_q_reg[*]}       -> 256（**设计**作用域）
  #   G  find_cells {i:/WORK/Predictor/*/ghv_q_reg[*]}     -> 0（pattern **不跨层次**）
  #   J  find_cells {i:/WORK/Predictor/u_core/ghv_q_reg[*]}-> 0（实例路径下**枚举不到**寄存器）
  #   结论：find_cells 只在**一个设计自己的作用域内**列 cell。所以
  #     · 枚举位   用**设计**路径（H）
  #     · 钉点     必须用**实例**路径（i:/WORK/Predictor/<inst>/ghv_q_reg[n]）
  #   两者都要，且没有一个白名单动词能把"设计"映射到"实例"。
  #
  # 于是实例名用本仓的既有约定 `u_core`（单文件规范：`module xs_<M>_core` 由同名
  # wrapper 以固定实例名 u_core 例化）。★但约定只是起点，不是判据★：
  #   · 这里断言该实例**恰好存在 1 个**；
  #   · 真正的判据是下面第 4 步"256 个必须全部钉上，少一个就 error" ——
  #     约定一旦变了，set_user_match 会整片失败并响亮退出，不会静默少钉。
  set _insts [find_cells "i:/WORK/$top/u_core"]
  if {[llength $_insts] != 1} {
    error "PREDICTOR_PIN: 期望 i:/WORK/$top/u_core 恰 1 个实例，实得 [llength $_insts]: $_insts"
  }
  set _inst [lindex $_insts 0]

  # --- 2) discover 两侧的 GHV 点，逐个提取下标 ------------------------------
  # 提取器：给定 design 前缀与叶名正则，返回 "下标 -> 全路径" 数组（下标重复即报错）。
  proc _ghv_scan {pattern prefix leafrx label} {
    set _n [string length $prefix]
    array set _m {}
    foreach _c [find_cells $pattern] {
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
  array set _ref [_ghv_scan "r:/WORK/$top/ghv_*_reg" "r:/WORK/$top" \
                            {^ghv_([0-9]+)_reg$} ref]
  # 可读核: 向量，叶名 ghv_q_reg[<n>]，恰一层位下标（1 位切片）。
  # 走**设计**路径枚举（探针 H），顺便断言只有一个 xs_*_core 设计前缀。
  set _cells [find_cells "i:/WORK/xs_*_core/ghv_q_reg\[*\]"]
  set _pfx {}
  foreach _c $_cells {
    # 受限 safe interp 里**没有 file 命令**（interp create -safe 会摘掉它），
    # 所以用字符串截到最后一个 "/"，不要写 [file dirname]。
    set _d [string range $_c 0 [expr {[string last "/" $_c] - 1}]]
    if {[lsearch -exact $_pfx $_d] < 0} { lappend _pfx $_d }
  }
  if {[llength $_pfx] != 1} {
    error "PREDICTOR_PIN(impl): 期望恰 1 个 xs_*_core 设计带 ghv_q，实得 [llength $_pfx]: $_pfx"
  }
  set _core [lindex $_pfx 0]
  array set _imp [_ghv_scan "$_core/ghv_q_reg\[*\]" $_core \
                            {^ghv_q_reg\[([0-9]+)\]$} impl]

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
    # _imp 是**设计**路径（i:/WORK/xs_Predictor_core/ghv_q_reg[n]），
    # 钉点要**实例**路径：把设计前缀换成实例前缀。
    set _leaf [string range $_imp($_i) [expr {[string length $_core] + 1}] end]
    set _ipath "$_inst/$_leaf"
    if {[catch {set_user_match $_r $_ipath} _msg]} {
      incr _miss
      if {$_miss <= 10} { puts "PREDICTOR_PIN_FAIL: $_r <-> $_ipath ($_msg)" }
    } else {
      incr _n
    }
  }

  # 无需"恢复 current_design"：本文件**一次都没碰过** current_design，
  # 所以 codex 0163 的第 (1)(3)(4) 条不适用；第 (2) 条（拒绝未知/歧义选择）
  # 由上面"恰 1 个实例 / 两侧各恰 256 / 下标 0..255 完整"三处断言承担。

  puts "PREDICTOR_PINS: $_n / $_expect pinned, $_miss missed (ref=$_ref(0) impl=$_inst/...)"
  if {$_miss != 0 || $_n != $_expect} {
    error "PREDICTOR_PIN_MISS=$_miss n=$_n expect=$_expect"
  }
}
