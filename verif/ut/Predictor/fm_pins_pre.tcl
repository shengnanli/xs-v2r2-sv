# Predictor FM 匹配前钉点 —— 7 族结构双射，共 2497 个点
# ============================================================================
# 【本文件解决什么】
#   官方 runner 在 commit 9ddf3b9 的实跑（evidence/9ddf3b94c946/Predictor/）里，
#   Predictor 还剩三类没收住的点：
#       134(6)  未配**比较点**       —— predCycle 128 + last_br_num_oh/brnum 6(6)
#       1113(1826) 未配**未读点**   —— folded_hist / afhob / ghist_ptr / prev_s2 …
#       7220    matched 未读点（not compared）
#   其中 7220 那批**不需要钉**：实测 7169 个在 `predictors` 子树里、两侧同名同路径
#   （receipt.json 的 matched_unread_notcompared_pairs 逐条都是 ref==impl 路径），
#   剩下 51 个在 u_core 里也已经配上了。它们缺的只是
#   FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 这个**加强**开关：打开后 FM 才
#   真去比这 7220 点，passing 必须相应增加 —— 打开而 passing 不增就是空转，不算过。
#
#   本文件负责的是前两类：把两侧**名字对不上**的点用 set_user_match 钉成双射。
#
# ============================================================================
# 【★最重要的一条：不钉会「配错对」，比「没配上」更危险★】
#   这不是猜想，是同一次实跑里两处证据对上的**实测结论**：
#
#     fm.log:1849-1854  未配的 **ref** 点里有
#                       s1_last_br_num_oh_dup_3_reg[1]  [2]
#                       s2_last_br_num_oh_dup_3_reg[1]  [2]
#     fm.log:1915-1918  失败的 **impl** 比较点里有
#                       u_core/s1_brnum_reg[1][1]  [1][2]
#                       u_core/s2_brnum_reg[1][1]  [1][2]
#
#   按可读核 :695 的 `FH_DUP [0:1] = '{1, 3}`，impl 的 s1_brnum_reg[**1**] 就是
#   **dup 3**。也就是说：impl 侧的 s1_dup3 位 1、位 2 **被 FM 配上了、而且判不等价**；
#   而它唯一结构正确的对家（ref 的 s1_dup3 位 1、位 2）**正躺在未配清单里**。
#   一个点被配上了、它的正主却没配上 —— 只能是 FM 把它配给了**别的** ref 点。
#   s2 同理。∴「FM 在这一族上配错了对」得到证实。
#
#   最可能的机制（这一步是推断，不是实测）：golden 的后缀 `dup_1` / `dup_3` 与
#   可读核的数组下标 `[0]` / `[1]` 之间没有数字对应关系，而 `dup_1` 的 "1" 恰好与
#   下标 "[1]" 字面相同 —— 于是 golden 的 dup_1 被配给了 impl 的 [1]（真身是 dup3），
#   golden 的 dup_3 找不到 "[3]" 就落空。要坐实这一步需要 report_matched_points，
#   本轮没跑（那要一次完整 match）。**但结论不依赖它**：配错对已由上面两处证据坐实，
#   而修法（把整族 24 个点全钉成结构正确的双射）对两种机制都一样有效 ——
#   set_user_match 在 match 之前生效，FM 没有机会再去猜。
#
#   ★由此得到本文件的第一原则：一族点要么整族钉，要么别钉。★
#   只钉"当前报出来没配上的那几个"会把错配留在原地（Composer 那边是另一种形状的
#   同一个坑：verif/ut/Composer/fm_pins_pre.tcl 里只钉 400 的那版，打开加强后又冒
#   出 200 个新的未配点）。
#
# ============================================================================
# 【钉哪七族 / 为什么名字会对不上】
#   共同成因：可读核把同类状态收进**带下标的数组/结构**，golden 经 firtool 展平成
#   **散装标量**。压缩比越高可读性越好，FM 的名字启发式就越认不出来 —— 这是本工程
#   核心手法的直接代价，不是缺陷。
#
#   族            golden（firtool 展平）                     可读核（数组/结构）        点数
#   ------------  ------------------------------------------ -------------------------- ----
#   ghv           ghv_<n>_reg                                ghv_q_reg[n]                256
#   brnum         s<N>_last_br_num_oh[_reg]_dup_<D>_reg[b]   s<N>_brnum[_reg]_reg[k][b]   24
#   predCycle     io_..._s<S>_full_pred_<D>_predCycle_c_reg[b] pred_cycle_q_reg[S-1][D][b] 768
#   folded_hist   s<N>_folded_gh[_reg]_dup_<D>_hist_<h>_folded_hist_reg[b]
#                                                            s<N>_folded_gh[_reg]_reg[k][h][b] 1120
#   afhob         s<N>_ahead_fh_oldest_bits[_reg]_dup_<D>_afhob_<j>_bits_<b>_reg
#                                                            s<N>_afhob[_reg]_reg[k][j][b]  184
#   ghist_ptr     s<N>_ghist_ptr[_reg]_dup_<d>_{flag_reg,value_reg[b]}
#                                                            s<N>_ghist_ptr[_reg]_reg[d]\[flag|value][b] 144
#   power_on      powerOnResetState_reg                      power_on_reset_state_reg       1
#                                                                                   合计 2497
#
#   两处命名细节（两侧各自一致，不是巧合）：
#     · s0 级的信号在两侧 RTL 里名字本来就带 `_reg` 后缀（它是"S0 保持寄存器"，
#       见可读核 :699-703 与 golden 的 s0_*_reg_dup_*），综合再补一层 `_reg`，
#       于是 s0 比 s1/s2/s3 多一个 `_reg`。本文件用 GPFX/IPFX 两个过程统一处理。
#     · dup 下标：folded_gh / afhob / brnum 只活着 dup1 与 dup3（可读核 :695
#       FH_DUP = '{1,3}，golden 侧另两份已被 firtool 消掉）。数组下标 k=0→dup1、
#       k=1→dup3。ghist_ptr 与 pc 则四份都在，下标即 dup 号。
#
# 【双射是机械的，没有自由度】
#   每一族的对应关系都由结构唯一确定：级号同号、dup 按 FH_DUP 表、hist/afhob 组号
#   同号、位下标同号。没有一处是人工强配。★产品 RTL 一个字都不改★：钉点是只服务于
#   证明的附加物，不是让可读件为了迁就 FM 把数组拆回散装寄存器（codex 0162 D2）。
#
# 【只做一件事】
#   只 set_user_match 消名差。不 dont_verify、不放宽 appvar、不约束 ref、不扩黑盒。
#   钉点只会让 FM 少猜，不会让它少证：被钉的点照样是比较点，照样要证等价。
#   钉错了的后果是 FM 判**不等价**（响亮失败），不是静默放过 —— 方向上是安全的。
#
# ============================================================================
# 【★两族有 impl 侧独有的死位，钉不了，本文件如实声明并计数★】
#   可读核为了可读性用了**等宽**的字类型 / **完整**的结构，golden 侧 firtool 则把
#   用不到的位宽和字段 DCE 掉了。于是可读核多出一批"没有 golden 对家"的死寄存器：
#
#     folded_hist  376 位 = (11 - CLEN[h]) × 2 dup × 4 级 求和
#                  可读核 `fh_word_t = logic[FH_MAX_W-1:0]` 是**定宽 11 位**（:156），
#                  这样 `folded_hist_t` 才能是 packed 数组、才能用 genvar 循环写；
#                  golden 则给每条 hist 按自己的 CLEN[h] 开位宽（4~11 位不等）。
#     afhob          8 位 = afhob 组 4 的 bits_3，golden 侧只有 bits_0..2。
#
#   这 384 位在本次实测里逐条核对过、**零例外**：受影响的 124 个 (级,dup,hist) 组里，
#   68 组只有 CLEN..10 这几位未配（其余位 FM 自己按名字配上了）、56 组整字未配，
#   没有第三种形状。核对脚本与口径见本 commit 的 commit message。
#
#   本文件对它们**不做任何事**：不钉（没有对家可钉）、更不 dont_verify。它们会留在
#   FM 的 unmatched-unread-impl 里。要真正收掉只有两条路，都超出"钉点"的权限：
#     (a) 把 fh_word_t 改成按 h 变宽 —— 违反"Predictor.sv 一个字都不许改"，
#         而且会毁掉 folded_hist_t 的 packed 数组形式与 genvar 循环，可读性大跌；
#     (b) 由 reviewer 按"impl 侧 cone-dead 超配"定性裁定（本仓既有"超配 FIFO → 缩
#         尺寸"的先例，但那是可以改 RTL 的场合）。
#   ★这是本轮**没有**收口的部分，必须上报，不能让它混在 2497 的"钉满"里当成已解决。★
#
#   同源但本文件**未钉**的还有三族（它们 golden 侧当前**零**未配，只有 impl 侧独有
#   死位，钉点帮不上忙；列在这里是为了下一轮打开加强后若发生匹配塌陷有据可查）：
#     prev_s2  190 位（jalr_target 的 dup1-3 共 150、offsets 32、
#                      fall_through_err 4、multi_hit 4 —— golden 侧整片被 DCE）
#     td_q       9 位（reasons 0/10/11，golden 只留 1..9 与 12）
#     do_redirect 2 位（level 的第 1 位、ssp 的第 4 位，golden 侧位宽更窄）
#   加上上面的 384，impl 侧独有死位合计 **585**。
#
#   两侧账目对得上（可复核）：
#     ref  未配 134(比较) + 1113(未读) = 1247
#     impl 未配   6(比较) + 1826(未读) = 1832 ，减去 585 个 impl 独有 = 1247
#   —— 正好相等。即：**除了这 585 位，两侧未配点是严格一一对应的**，本文件把其中
#   落在上述七族里的部分全部钉上。
#
# ============================================================================
# 【fail-closed】
#   2497 个一个都不许钉不上。任何一侧少一个点、多一个点，或 impl 侧独有死位的数目
#   不等于声明的 384，都直接 error 退出 —— 名字/结构一旦漂了，继续跑出来的
#   SUCCEEDED 是假的。查询动词缺失（沙箱白名单没放行）同样 error：不允许退化成
#   "照名字硬猜"。
#
# 【历史更正（别再踩）】
#   本段原先写过「匹配不终止、外推 302 天」—— 那是错的，2026-09-15 已撤回。成因是
#   把 Formality 的匹配进度条（`NNNM/NNN (49% Matched)`）当成线性进度：它的分母约是
#   配对数的两倍（ref+impl 两侧对象合计），**按构造到不了 100%**，配完时正好停在 49%
#   附近。实测匹配是收敛的，约 2.6 小时配完。详见 docs/predictor_fm_scaling_wall.md。
# ============================================================================

if {$top eq "Predictor"} {

  # --- 0) 查询动词可用性：缺它就不许退化成硬编码 -----------------------------
  #
  # ★只用 find_cells 一个动词★（2026-09-15 实测后收窄）。
  # 实测（90 秒探针）表明 find_cells 直接吃**全路径 pattern**，不需要先切
  # current_design；全程 current_design 保持进入时的 '0'（未设置），一次都没碰。
  # 用不着的权限就不该要：白名单里去掉 current_design 与 find_designs 之后，
  # 它们的失败模式（名字非法时**不抛异常**，只打 `Error: Unknown name (FM-036)`
  # 并把当前设计置空 —— 与 set_top 一模一样）也就不可能再被踩到。
  if {[info commands find_cells] eq ""} {
    error "PREDICTOR_PIN: 只读查询动词 'find_cells' 不可用 —— 无法 discover，拒绝硬猜名字"
  }

  # --- 1) discover：两侧的枚举路径与钉点路径 ---------------------------------
  #
  # ★find_cells 的作用域语义（2026-09-15 三轮探针 + 2026-09-16 全量 dump 复核）★
  #   F  find_cells {i:/WORK/Predictor/*}                  -> 21 个**顶层实例**
  #   H  find_cells {i:/WORK/xs_*_core/ghv_q_reg[*]}       -> 256（**设计**作用域）
  #   G  find_cells {i:/WORK/Predictor/*/ghv_q_reg[*]}     -> 0（pattern **不跨层次**）
  #   J  find_cells {i:/WORK/Predictor/u_core/ghv_q_reg[*]}-> 0（实例路径下**枚举不到**寄存器）
  #   结论：find_cells 只在**一个设计自己的作用域内**列 cell。所以
  #     · 枚举  用**设计**路径（golden 是 r:/WORK/Predictor 本体，可读核是 xs_*_core）
  #     · 钉点  必须用**实例**路径（i:/WORK/Predictor/u_core/<叶名>）
  #   两者都要，且没有一个白名单动词能把"设计"映射到"实例"。
  set _insts [find_cells "i:/WORK/$top/u_core"]
  if {[llength $_insts] != 1} {
    error "PREDICTOR_PIN: 期望 i:/WORK/$top/u_core 恰 1 个实例，实得 [llength $_insts]: $_insts"
  }
  set _inst [lindex $_insts 0]

  # 核**设计**前缀：从一个必然存在的叶名反推，并断言只有一个 xs_*_core 带它。
  # 实例名 u_core 是本仓单文件规范的既有约定（module xs_<M>_core 由同名 wrapper 以
  # 固定实例名 u_core 例化），但约定只是起点 —— 真正的判据是下面"2497 个必须全钉上"。
  set _pfx {}
  foreach _c [find_cells "i:/WORK/xs_*_core/ghv_q_reg\[*\]"] {
    # 受限 safe interp 里**没有 file 命令**（interp create -safe 会摘掉它），
    # 所以用字符串截到最后一个 "/"，不要写 [file dirname]。
    set _d [string range $_c 0 [expr {[string last "/" $_c] - 1}]]
    if {[lsearch -exact $_pfx $_d] < 0} { lappend _pfx $_d }
  }
  if {[llength $_pfx] != 1} {
    error "PREDICTOR_PIN: 期望恰 1 个带 ghv_q 的 xs_*_core 设计，实得 [llength $_pfx]: $_pfx"
  }
  set _core [lindex $_pfx 0]

  # --- 2) 把两侧**整个设计**的 cell 叶名建成查找表 ---------------------------
  # 一次全量枚举（golden 42824 / 可读核 41950，实测），之后所有存在性判断都是
  # O(1) 查表。这样每一族的"该有的点在不在"都是**查出来的**，不是假设出来的。
  proc _index {pattern prefix arrname} {
    upvar 1 $arrname A
    set _n [expr {[string length $prefix] + 1}]
    foreach _c [find_cells $pattern] {
      set A([string range $_c $_n end]) $_c
    }
  }
  array set _REF {}
  array set _IMP {}
  _index "r:/WORK/$top/*" "r:/WORK/$top" _REF
  _index "$_core/*"       $_core         _IMP

  # --- 3) 钉点引擎 -----------------------------------------------------------
  # 每一族都归结为"生成一串 (golden 叶名, impl 叶名) 期望对"，然后逐对：
  #   两侧都必须**存在**（否则 error：说明结构漂了，不是"这条可以跳过"）
  #   set_user_match 必须**成功**（否则 error）
  # 生成的是**期望**而不是"扫出来的"，所以少一个点会在存在性检查处响亮失败，
  # 而不是静默少钉。
  set _n 0
  set _pairs {}
  proc _pair {g i} { uplevel 1 [list lappend _pairs [list $g $i]] }

  # s0 级两侧 RTL 名字本来就带 _reg 后缀，综合再补一层 -> s0 比 s1/s2/s3 多一个 _reg
  proc _g {s name dup} {                     ;# golden 叶名前缀
    if {$s == 0} { return "s0_${name}_reg_dup_${dup}" }
    return "s${s}_${name}_dup_${dup}"
  }
  proc _i {s name} {                         ;# impl 叶名前缀（不含数组下标）
    if {$s == 0} { return "s0_${name}_reg_reg" }
    return "s${s}_${name}_reg"
  }
  # 可读核 :695  localparam FH_DUP [0:1] = '{1, 3}
  # 数组下标 k=0 -> dup 1，k=1 -> dup 3。folded_gh / afhob / brnum 三族共用。
  set FH_DUP {1 3}

  # (a) GHV —— 256 位全局分支历史环形寄存器
  #     golden 是 256 个**散装标量** reg（golden Predictor.sv:1711-1966），
  #     可读核是**一根 256 位向量** ghv_q（rtl/frontend/Predictor.sv:532，
  #     逐位写在 generate 块 g_ghv 里 :548-559）。第 n 位逐位同号对应。
  for {set b 0} {$b < 256} {incr b} {
    _pair "ghv_${b}_reg" "ghv_q_reg\[$b\]"
  }

  # (b) brnum —— "上一块进了几条分支"的 one-hot（3 位），S0..S3 每级 2 份 dup
  #     ★这一族就是上面证实"FM 配错对"的那一族，必须整族 24 个全钉★
  for {set s 0} {$s <= 3} {incr s} {
    for {set k 0} {$k <= 1} {incr k} {
      set D [lindex $FH_DUP $k]
      for {set b 0} {$b <= 2} {incr b} {
        _pair "[_g $s last_br_num_oh $D]_reg\[$b\]" "[_i $s brnum]\[$k\]\[$b\]"
      }
    }
  }

  # (c) predCycle —— 打在预测包上的 64 位时间戳，12 个自由计数器（3 级 × 4 dup）
  #     可读核 pred_cycle_q[级][dup]（:1207），级下标 0..2 对应 golden 的 s1..s3。
  #     注：可读核三个输出口都取 pred_cycle_q[0][0]（:2485-2487），golden 则各取
  #     各级的计数器 —— 12 个计数器同复位同步进、值恒等，输出口照样等价；但这让
  #     golden 的 s2/s3_pred_0 是**被读**的比较点、可读核对应的两个却是未读点。
  #     这正是那 128 个未配**比较点**的来历（其余 576 个是未配**未读点**）。
  #     两边都得钉，且要配合加强开关才能让它们落在同一类里。
  for {set s 1} {$s <= 3} {incr s} {
    for {set d 0} {$d <= 3} {incr d} {
      for {set b 0} {$b < 64} {incr b} {
        _pair "io_bpu_to_ftq_resp_bits_s${s}_full_pred_${d}_predCycle_c_reg\[$b\]" \
              "pred_cycle_q_reg\[[expr {$s - 1}]\]\[$d\]\[$b\]"
      }
    }
  }

  # (d) folded_hist —— 17 条折叠历史，每条按自己的 CLEN[h] 压到 4~11 位
  #     ★每条 hist 的位宽不写死，从 golden 侧**数出来**★：可读核用定宽 11 位的
  #     fh_word_t（:156，为了让 folded_hist_t 能是 packed 数组 + genvar 循环），
  #     golden 则按 CLEN[h] 开宽。把 CLEN 抄进本文件等于把 RTL 常数复制一份，
  #     哪天 FH_CLEN 改了就会静默钉错 —— 所以这里改为查 golden 实际有几位，
  #     并断言这几位是**从 0 连续**的（不连续说明 firtool 的展平形状变了）。
  set _W {}
  for {set h 1} {$h <= 17} {incr h} {
    set w 0
    # 注意：Tcl 里 `_REF("x")` 的键会**连引号一起**当成键名（引号只在词首才特殊），
    # 在 if/while 的 {} 表达式里还要再叠一层求值 —— 所以一律先把键算进变量再查。
    while {1} {
      set _k "[_g 0 folded_gh 1]_hist_${h}_folded_hist_reg\[$w\]"
      if {![info exists _REF($_k)]} break
      incr w
    }
    if {$w < 1 || $w > 11} {
      error "PREDICTOR_PIN(folded): hist $h 在 golden 侧数出 $w 位，超出 1..11"
    }
    lappend _W $w
  }
  for {set s 0} {$s <= 3} {incr s} {
    for {set k 0} {$k <= 1} {incr k} {
      set D [lindex $FH_DUP $k]
      for {set h 1} {$h <= 17} {incr h} {
        set w [lindex $_W [expr {$h - 1}]]
        # golden 只有低 w 位；第 w 位必须**不存在**，否则上面数出来的宽度是错的
        set _k "[_g $s folded_gh $D]_hist_${h}_folded_hist_reg\[$w\]"
        if {[info exists _REF($_k)]} {
          error "PREDICTOR_PIN(folded): s$s dup$D hist$h 位宽不是 $w（第 $w 位也存在）"
        }
        for {set b 0} {$b < $w} {incr b} {
          _pair "[_g $s folded_gh $D]_hist_${h}_folded_hist_reg\[$b\]" \
                "[_i $s folded_gh]\[$k\]\[$h\]\[$b\]"
        }
      }
    }
  }

  # (e) afhob —— ahead fh oldest bits：6 组"最老位"，每组 4 位（afhob_word_t，:158）
  #     同样从 golden 侧数每组实际位数：golden 的 afhob 组 4 只有 bits_0..2。
  set _A {}
  for {set j 0} {$j <= 5} {incr j} {
    set w 0
    while {1} {
      set _k "[_g 0 ahead_fh_oldest_bits 1]_afhob_${j}_bits_${w}_reg"
      if {![info exists _REF($_k)]} break
      incr w
    }
    if {$w < 1 || $w > 4} {
      error "PREDICTOR_PIN(afhob): 组 $j 在 golden 侧数出 $w 位，超出 1..4"
    }
    lappend _A $w
  }
  for {set s 0} {$s <= 3} {incr s} {
    for {set k 0} {$k <= 1} {incr k} {
      set D [lindex $FH_DUP $k]
      for {set j 0} {$j <= 5} {incr j} {
        set w [lindex $_A $j]
        set _k "[_g $s ahead_fh_oldest_bits $D]_afhob_${j}_bits_${w}_reg"
        if {[info exists _REF($_k)]} {
          error "PREDICTOR_PIN(afhob): s$s dup$D 组$j 位宽不是 $w（第 $w 位也存在）"
        }
        for {set b 0} {$b < $w} {incr b} {
          _pair "[_g $s ahead_fh_oldest_bits $D]_afhob_${j}_bits_${b}_reg" \
                "[_i $s afhob]\[$k\]\[$j\]\[$b\]"
        }
      }
    }
  }

  # (f) ghist_ptr —— 全局历史环形指针 {flag, value[7:0]}，四份 dup 都活着
  #     可读核是 struct（cgh_ptr_t），FM 把字段名做成**转义标识符**，叶名里带一个
  #     字面反斜杠：s0_ghist_ptr_reg_reg[0]\[flag]。原样传给 set_user_match 即可
  #     （Tcl 传的是字符串值，不会二次解析）。
  for {set s 0} {$s <= 3} {incr s} {
    for {set d 0} {$d <= 3} {incr d} {
      _pair "[_g $s ghist_ptr $d]_flag_reg" "[_i $s ghist_ptr]\[$d\]\\\[flag\]"
      for {set b 0} {$b <= 7} {incr b} {
        _pair "[_g $s ghist_ptr $d]_value_reg\[$b\]" "[_i $s ghist_ptr]\[$d\]\\\[value\]\[$b\]"
      }
    }
  }

  # (g) power_on_reset —— 纯大小写/分词差（powerOnResetState vs power_on_reset_state）
  _pair "powerOnResetState_reg" "power_on_reset_state_reg"

  # --- 4) 逐对存在性检查 + 钉点（fail-closed）--------------------------------
  set _expect 2497
  if {[llength $_pairs] != $_expect} {
    error "PREDICTOR_PIN: 生成了 [llength $_pairs] 对期望，应为 $_expect —— 生成规则写错了"
  }
  set _missref {}
  set _missimp {}
  set _fail {}
  set _dup {}
  # ★单射性：两侧各自的叶名都不许出现第二次★
  # 光靠"生成 2497 对 + 族内总点数 2497"抓不到"某点钉了两次、另一点漏了"这种形状
  # （总数仍然对得上）。这两个 _seen 数组把它堵死：加上后面的族内计数审计，
  # 才真的证明了双射 —— 单射由这里保证，满射由"消耗数 == 族内总数"保证。
  array set _seenref {}
  array set _seenimp {}
  foreach _p $_pairs {
    set _gl [lindex $_p 0]
    set _il [lindex $_p 1]
    if {[info exists _seenref($_gl)]} { lappend _dup "golden 叶名重复: $_gl" ; continue }
    if {[info exists _seenimp($_il)]} { lappend _dup "可读核叶名重复: $_il" ; continue }
    set _seenref($_gl) 1
    set _seenimp($_il) 1
    if {![info exists _REF($_gl)]} { lappend _missref $_gl ; continue }
    if {![info exists _IMP($_il)]} { lappend _missimp $_il ; continue }
    # 钉点走**实例**路径（探针 J/H：设计路径只能枚举、不能钉）
    if {[catch {set_user_match $_REF($_gl) "$_inst/$_il"} _msg]} {
      lappend _fail "$_gl <-> $_il ($_msg)"
    } else {
      incr _n
    }
  }
  foreach {_lbl _lst} [list golden侧缺点 $_missref 可读核侧缺点 $_missimp 钉点失败 $_fail 叶名重复 $_dup] {
    if {[llength $_lst] != 0} {
      puts "PREDICTOR_PIN_FAIL($_lbl): [llength $_lst] 个，前 10："
      foreach _x [lrange $_lst 0 9] { puts "    $_x" }
    }
  }

  # --- 5) 反向审计：两侧都不许有"本族里没被钉到"的漏网点 ---------------------
  # 上面第 4 步保证"生成的期望都存在"；这一步反过来保证"存在的都被生成了"。
  # 缺了这一步，生成规则漏掉一整个子族（比如某级、某个 dup）也不会被发现 ——
  # 这正是 Composer 那边"只钉 400、剩 200 打开加强后才冒出来"的形状。
  #
  # 判据：本文件覆盖的七族，在两侧各自的**族内总点数**必须等于
  #   golden : 2497（全部有对家）
  #   impl   : 2497 + 384（可读核独有死位，见文件头声明）
  proc _count {arrname rx} {
    upvar 1 $arrname A
    set c 0
    foreach k [array names A] { if {[regexp $rx $k]} { incr c } }
    return $c
  }
  # golden 侧七族的叶名形状（与上面 (a)..(g) 的生成规则一一对应）
  set _rxref {(^ghv_[0-9]+_reg$)|(^s[0-9]_last_br_num_oh(_reg)?_dup_[0-9]+_reg\[[0-9]+\]$)|(^io_bpu_to_ftq_resp_bits_s[123]_full_pred_[0-3]_predCycle_c_reg\[[0-9]+\]$)|(^s[0-9]_folded_gh(_reg)?_dup_[0-9]+_hist_[0-9]+_folded_hist_reg\[[0-9]+\]$)|(^s[0-9]_ahead_fh_oldest_bits(_reg)?_dup_[0-9]+_afhob_[0-9]+_bits_[0-9]+_reg$)|(^s[0-9]_ghist_ptr(_reg)?_dup_[0-9]+_(flag_reg$|value_reg\[[0-9]+\]$))|(^powerOnResetState_reg$)}
  # 可读核侧同七族
  set _rximp {(^ghv_q_reg\[[0-9]+\]$)|(^s[0-9]_brnum(_reg)?_reg\[[0-9]+\]\[[0-9]+\]$)|(^pred_cycle_q_reg\[[0-9]+\]\[[0-9]+\]\[[0-9]+\]$)|(^s[0-9]_folded_gh(_reg)?_reg\[[0-9]+\]\[[0-9]+\]\[[0-9]+\]$)|(^s[0-9]_afhob(_reg)?_reg\[[0-9]+\]\[[0-9]+\]\[[0-9]+\]$)|(^s[0-9]_ghist_ptr(_reg)?_reg\[[0-9]+\]\\\[(flag|value)\])|(^power_on_reset_state_reg$)}
  set _cref [_count _REF $_rxref]
  set _cimp [_count _IMP $_rximp]
  # 满射：族内每一个 golden 叶名都必须被消耗掉；可读核侧同理，只准剩下声明的死位
  set _usedref [array size _seenref]
  set _usedimp [array size _seenimp]
  set _implonly 384   ;# folded_hist 376 + afhob 8，见文件头【impl 侧独有死位】
  set _bad 0
  if {$_usedref != $_expect || $_usedimp != $_expect} {
    puts "PREDICTOR_PIN_AUDIT: 消耗的不重复叶名 golden=$_usedref 可读核=$_usedimp，应各为 $_expect"
    incr _bad
  }
  if {$_cref != $_expect} {
    puts "PREDICTOR_PIN_AUDIT: golden 侧七族共 $_cref 点，应为 $_expect（差 [expr {$_cref - $_expect}]）"
    incr _bad
  }
  if {$_cimp != [expr {$_expect + $_implonly}]} {
    puts "PREDICTOR_PIN_AUDIT: 可读核侧七族共 $_cimp 点，应为 [expr {$_expect + $_implonly}]（= $_expect 有对家 + $_implonly 独有死位，差 [expr {$_cimp - $_expect - $_implonly}]）"
    incr _bad
  }

  puts "PREDICTOR_PINS: $_n / $_expect pinned, [expr {[llength $_missref] + [llength $_missimp] + [llength $_fail] + [llength $_dup]}] missed; audit ref=$_cref imp=$_cimp (impl-only dead=$_implonly)"
  if {$_n != $_expect || [llength $_fail] != 0 || [llength $_missref] != 0 || [llength $_missimp] != 0 || [llength $_dup] != 0 || $_bad != 0} {
    error "PREDICTOR_PIN_MISS: n=$_n expect=$_expect missref=[llength $_missref] missimp=[llength $_missimp] fail=[llength $_fail] dup=[llength $_dup] audit_bad=$_bad"
  }
}
