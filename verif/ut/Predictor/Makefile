# Predictor UT/FM 入口 —— BPU 顶层流水与全局历史管理。
#
# Predictor 的子模块都**不是本目标**，两侧共用同一份 golden 定义，所以 UT 比的、
# FM 证的都只是 Predictor 这一层。依赖分两类，共 98 个文件：
#   · Composer 及其 5 个预测器闭包（与 verif/ut/Composer 同一份清单）+ DelayN；
#   · golden Predictor 自己例化的 6 种 PriorityMuxModule（270 个实例）。它们是纯组合
#     优先选择器(0 寄存器)，可读核把这套逻辑直接写成 ? : 优先级链，所以**只有 ref 侧**
#     用得到 —— impl 侧一个都不例化。
MODULE = Predictor

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/Predictor.sv
TB_SRCS  = tb.sv

# golden 顶层（被比对的 ref）
GOLDEN_SRCS = $(GOLDEN_RTL)/Predictor.sv

RTL_GOLDEN_DEPS = \
  $(XSSV_HOME)/rtl/common/ClockGate.sv \
  $(GOLDEN_RTL)/Composer.sv \
  $(GOLDEN_RTL)/DelayN.sv \
  $(GOLDEN_RTL)/DelayNWithValid.sv \
  $(GOLDEN_RTL)/DelayNWithValid_1.sv \
  $(GOLDEN_RTL)/DelayN_1.sv \
  $(GOLDEN_RTL)/FTB.sv \
  $(GOLDEN_RTL)/FTBBank.sv \
  $(GOLDEN_RTL)/FauFTB.sv \
  $(GOLDEN_RTL)/FauFTBWay.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_22.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_24.sv \
  $(GOLDEN_RTL)/ITTage.sv \
  $(GOLDEN_RTL)/ITTageTable.sv \
  $(GOLDEN_RTL)/ITTageTable_1.sv \
  $(GOLDEN_RTL)/ITTageTable_2.sv \
  $(GOLDEN_RTL)/ITTageTable_3.sv \
  $(GOLDEN_RTL)/ITTageTable_4.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_33.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv \
  $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv \
  $(GOLDEN_RTL)/MbistClockGateCell.sv \
  $(GOLDEN_RTL)/MbistPipeFtb.sv \
  $(GOLDEN_RTL)/MbistPipeIttage.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_1.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_2.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_3.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_4.sv \
  $(GOLDEN_RTL)/MbistPipeSc.sv \
  $(GOLDEN_RTL)/MbistPipeSc_1.sv \
  $(GOLDEN_RTL)/MbistPipeSc_2.sv \
  $(GOLDEN_RTL)/MbistPipeSc_3.sv \
  $(GOLDEN_RTL)/MbistPipeTage.sv \
  $(GOLDEN_RTL)/PriorityMuxModule.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_12.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_16.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_20.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_4.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_8.sv \
  $(GOLDEN_RTL)/RAS.sv \
  $(GOLDEN_RTL)/RASStack.sv \
  $(GOLDEN_RTL)/RegionWays.sv \
  $(GOLDEN_RTL)/SCTable.sv \
  $(GOLDEN_RTL)/SCTable_1.sv \
  $(GOLDEN_RTL)/SCTable_2.sv \
  $(GOLDEN_RTL)/SCTable_3.sv \
  $(GOLDEN_RTL)/SRAMTemplate_36.sv \
  $(GOLDEN_RTL)/SRAMTemplate_44.sv \
  $(GOLDEN_RTL)/SRAMTemplate_45.sv \
  $(GOLDEN_RTL)/SRAMTemplate_64.sv \
  $(GOLDEN_RTL)/SRAMTemplate_68.sv \
  $(GOLDEN_RTL)/SRAMTemplate_76.sv \
  $(GOLDEN_RTL)/SRAMTemplate_78.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_25.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_27.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
  $(GOLDEN_RTL)/TageBTable.sv \
  $(GOLDEN_RTL)/TageTable.sv \
  $(GOLDEN_RTL)/TageTable_1.sv \
  $(GOLDEN_RTL)/TageTable_2.sv \
  $(GOLDEN_RTL)/TageTable_3.sv \
  $(GOLDEN_RTL)/Tage_SC.sv \
  $(GOLDEN_RTL)/WrBypass.sv \
  $(GOLDEN_RTL)/WrBypass_32.sv \
  $(GOLDEN_RTL)/WrBypass_33.sv \
  $(GOLDEN_RTL)/WrBypass_41.sv \
  $(GOLDEN_RTL)/WrBypass_43.sv \
  $(GOLDEN_RTL)/array_1.sv \
  $(GOLDEN_RTL)/array_1_ext.v \
  $(GOLDEN_RTL)/array_2.sv \
  $(GOLDEN_RTL)/array_2_ext.v \
  $(GOLDEN_RTL)/array_3.sv \
  $(GOLDEN_RTL)/array_3_ext.v \
  $(GOLDEN_RTL)/array_4.sv \
  $(GOLDEN_RTL)/array_4_ext.v \
  $(GOLDEN_RTL)/array_5.sv \
  $(GOLDEN_RTL)/array_5_ext.v \
  $(GOLDEN_RTL)/array_6.sv \
  $(GOLDEN_RTL)/array_6_ext.v \
  $(GOLDEN_RTL)/data_mem_0_4x2.sv \
  $(GOLDEN_RTL)/data_mem_0_8x3.sv \
  $(GOLDEN_RTL)/data_mem_16x12.sv \
  $(GOLDEN_RTL)/data_mem_8x4.sv \
  $(GOLDEN_RTL)/sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
  $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

# FM_MERGE_DUP=false —— 本目标必须关掉「合并重复寄存器」。
#
# ★先看懂 fm.log 的阶段顺序，否则这条的证据必然测错（我错过一次）★：
#     Implementation design set to 'i:/WORK/<top>'   两侧 set_top 完成
#     Status:  Checking designs...
#     Status:  Building verification models...       <- 合并阶段在**这之后**
#     Status:  Merging duplicated registers in block ...
#     Status:  Matching...
#     **** Matching Results ****
# 所以「多久到 Building verification models」与本开关**完全无关**，拿它比是比噪声。
# 唯一有判别力的观察点是：有没有出现 Merging duplicated 行、卡在哪个 block、
# 以及最终到不到 Matching。
#
# ── A/B 实测（2026-09-15，同一 commit 82503e5，只差本文件这一行）───────────────
#
#   off : 03:45:09Z 起跑 → 04:04:03Z 进入 "Matching..."（**18 分 54 秒**），
#         全程 `Merging duplicated` 行数 = 0（整个合并阶段被跳过）。
#   on  : 04:07:09Z 起跑 → 04:27:52Z 进入合并阶段并停在
#         i:/WORK/Predictor/u_core (/WORK/xs_Predictor_core)；
#         到 04:37:35Z 在这一个 block 上已 ≥10 分钟、总计 ≥30 分钟未到 Matching。
#         （这一路到此为止 —— 结论已够，为省 license/内存主动停掉了。）
#
# ★它不是挂死，是慢 —— 跑完了★（另一路跑到终点的实测，2026-09-15）：
#     914ab81 + on : 02:57:00Z 起跑 → 05:13:04Z 进入 "Matching..." = **2 小时 16 分**
#                    其中合并阶段本身约 1 小时 22 分（03:51Z→05:13Z，57 个 block）
#   对同一阶段而言 on : off ≈ 2:16 : 0:19 ≈ **7 倍**。
#   所以本行是**省时间**的工程决定，不是「不关就跑不出来」。早先注释（含我自己）
#   用过「卡死 / 挂死」，与实测不符，已改。
#
#   旁证：ee2db10 + on 跑 0:25:11 时同样停在 i:/WORK/Predictor/u_core
#   （同样为省资源主动停掉）。三个 commit 一致指向同一个 block。
#
#   规模参考（解释为什么这么贵）：本目标 off 侧 Matching 阶段的进度条显示
#   **1,057,801 个比较点**、42 GB 内存。这不是异常，是这个闭包的体量。
#
#   复跑（off 侧就是官方 runner；on 侧只需把本行改成 true）:
#     scripts/run_proof.sh Predictor Predictor            # PROOF_COMMIT=82503e5
#     git worktree add --detach <wt> 82503e5
#     sed -i 's/^FM_MERGE_DUP = false$/FM_MERGE_DUP = true/' <wt>/verif/ut/Predictor/Makefile
#     ( cd <wt>/verif/ut/Predictor && XSSV_HOME=<wt> XSSV_INDEX_HOME=<repo> make fm-Predictor )
#   判据看 fm_work/Predictor/fm.log 里 `Merging duplicated` 的行数与末行 block。
#
# ── 上一版注释错在哪（保留记录，别再犯）─────────────────────────────────────
# 它写的是「同一 commit、同一依赖表，只切这一个开关」，实际那两个数分属**两个
# commit**：on 的 1:06:55 测在 914ab81，off 的 18:46 测在 82503e5，中间
# rtl/frontend/Predictor.sv 差 126 行。数字没编，是归属标错了；而且 18:46 那个数
# 落在合并阶段**之前**，本来就测不到这个开关。上面这组是补做的真·同 commit 对照。
#
# 成因（仍是原判断，且三个 commit 一致指向同一个 block）：耗时集中在 u_core 即可读核
# 本身，不是 Composer、不是任何 golden 子模块。本核有 12 个内容完全相同的 64 位
# predCycle 自由计数器 + 256 位 ghv 向量，结构同构且数量大，是 merge_dup 的最坏输入。
# 反证：verif/ut/Composer 用**同一份 90 文件闭包**、merge_dup 开着也能跑完并签核，
# 所以与闭包大小无关。
#
# ★关掉它不是放松证明★：不合并重复寄存器只会让比较点变多、不会变少，
# 不存在「空转过关」的风险；且该值经 FM_MERGE_DUP 入口变量真实绑定并写进 manifest。
#
# 先例：MulUnit 与 EntriesVfdivVidiv 也因「golden 侧常数/重复位被合并后两侧点数
# 对不齐」而必须 FM_MERGE_DUP=false（见 scripts/fm_eq.tcl 的证据注释）。
FM_MERGE_DUP = false

# ---------------------------------------------------------------------------
# matched-unread 加强（vmucp）——**加强，不是放宽**
# ---------------------------------------------------------------------------
# 打开后 FM 不再把「两侧都配上了、但两侧都没人读」的点当 Not-Compared 放过，
# 而是把它们当真比较点去证。Predictor 早已在 scripts/fm_eq.tcl 的精确白名单里。
#
# 依据（ecdb741 那轮 evidence/ecdb74167652/Predictor/unread_points.txt）：
#   8333 个 unread 点**全部**是 matched_nc（两侧对称配上），其中
#     7169 个在 predictors（golden Composer 实例）子树里 —— TAGE/ITTAGE/FTB 的
#          io_update_ghist_r / update_meta_r 等更新通路寄存器，两侧是**同一份**
#          golden Composer.sv，天然逐位同构；
#     1164 个在 u_core 里：pred_cycle_q 576 / s*_folded_gh 464 / s*_afhob 60 /
#          s*_ghist_ptr 12 / power_on_reset_state 1（这 1113 个由 fm_pins_pre.tcl
#          逐位钉死），外加 prev_s2 50 + upc_seg2 1（名字同构，FM 自己按名字配上的）。
#   impl 侧单边未读 585 个不受本开关影响（它们没有对家，属 PASS_DEAD_IMPL 的范畴）。
#
# ★验收判据（不增即空转，按 fail 处理）★
#   passing 必须从 520634 增到 528967（正好 +8333）；failing 仍为 0；
#   Not-Compared 的 Unread 必须归 0。passing 不增而 unread 归 0 = 点被吞掉，不算过。
#
# ── 2026-09-17 实测更正（evidence/8798034cedf7/Predictor）────────────────────
#   上面那条判据**没对上**，实测是：
#     passing 528899 / failing 17 / Not-Compared Unread 0 / 未配比较点 0(1)
#     / 未配未读点 51(635)
#   比较点总数 528899+17 = 528916 = 528967 - 51。即 8333 个 matched_nc 里有 51 个
#   不是"升成比较点"而是**掉出了配对**，落进未配未读：
#     · upc_seg2  1 位 —— 见下，已由 RTL + 第九族钉点修掉；
#     · prev_s2 jalr_target dup0 50 位 —— 仍未收，见 fm_pins_pre.tcl 文件头的
#       2026-09-17 更正段（待办，不是已解决项）。
#   所以上面括号里"prev_s2 50 + upc_seg2 1（FM 自己按名字配上的）"这句只在
#   vmucp 关着时成立：加强一打开，这 51 位的配对就掉了。
#
#   17 个 failing 的来历（全部是 Composer 里的 ..._io_update_pc_..._reg[0]）：
#   两侧读的是**同一份** golden Composer.sv，差异只可能来自喂进去的 50 位
#   io_update_bits_pc。它的 bit0 来自最低段寄存器；golden 侧
#   seg_2_value_reg[0] 落在未读类、可读核侧 upc_seg2_reg[0] 落在比较类，
#   两类之间 FM 不互配 —— 一个未配的寄存器在下游锥里就是两个互不相干的自由
#   变量，于是下游 17 个 bit0 寄存器全判不等价。
#   处置两条一起做：
#     (1) rtl/frontend/Predictor.sv 的 SEGPC_ 段去掉最低段那个 golden 没有的
#         比较器（golden `..._modified_2 = 1'h1`，源头 utility
#         SegmentedAddrNext 的 `modified.last := true.B`）；
#     (2) fm_pins_pre.tcl 加第九族，把 3 段共 50 位整族钉死，让配对与
#         读/未读分类无关（形状同第 (c) 族 predCycle）。
#
#   ★本轮复核判据★：failing 归 0；未配比较点 0(0)；比较点总数
#   528916 + 1 = 528917（+1 = seg_2[0] 由"两侧分属不同类、谁也没比"变成真比较点）；
#   未配未读点 50(635)（剩下的就是 jalr_target dup0 那 50 位 + impl 独有 585 位）。
#   ★verdict 仍会是 PARTIAL★：signoff-strict 要求 unread 归 0
#   (scripts/fm_verdict.py 的 strict_unread!=0)，而 impl 侧 585 个独有死位
#   本轮不动。这是已知残余，不是新问题。
#   —— 以上实测于 7b4a825（evidence/7b4a8253e457/Predictor/），逐条对上。
#
# ── 2026-09-18 本轮（685 个 unread 点收口）的**预登记判据** ──────────────────
#   处置方式（两条合法路径，一条没用 waiver）：
#     (1) 改 RTL 去掉可读核比 golden **多存**的 585 位死寄存器
#         folded_hist 376 / afhob 8 / prev_s2 190 / td_q 9 / do_redirect 2
#         —— 每一位都能在 golden 里指出"这里没有这个寄存器"，见
#         verif/ut/Predictor/fm_pins_pre.tcl 文件头。
#     (2) 把 golden **有**、可读核也照建了的 jalr_target dup0 那 50 位整族钉死
#         （fm_pins_pre.tcl 第 (j) 族），外加 td_q 换结构后必须整族钉的 30 位
#         （第 (k) 族）。钉点总数 2631 -> 2711。
#
#   跑之前登记，跑完逐条对账，对不上就按 fail 报，不往下推：
#     P1  failing                = 0
#     P2  未配比较点              = 0(0)
#     P3  未配未读点              = 0(0)，且 unread_points.txt 为 **0 字节**
#     P4  Not-Compared Unread    = 0
#     P5  passing = 528917 + 50  = **528967**
#         (+50 恰是 jalr_target dup0：它此前是"ref 50 + impl 50 两堆孤立未配未读点"，
#          钉成双射后被 vmucp 升成真比较点。585 位死寄存器本来就不是比较点，
#          删掉它们**不改变** passing —— 所以这里只 +50，一位不多。)
#     P6  黑盒输出 0 / dont_verify false / FM_MODE 仍是 signoff-strict
#     P7  官方 verdict 从 PARTIAL 变成**通过**（strict unread 归零后不再有
#         strict_unread!=0 这条 reason）
#   ★P5 是最有判别力的一条★：passing 若不是正好 528967 —— 少了说明有点被吞掉、
#   多了说明多出了本轮没解释的比较点 —— 两种都按 fail 处理，不许事后改判据。
#
# ── 实跑结果（bfd1afc，evidence/bfd1afc7451e/Predictor/）：七条判据全中 ──────
#   scripts/run_proof.sh Predictor Predictor
#   run_id=Predictor-20260918T105307Z-bfd1afc   dirty=False   fm_shell_rc=0
#
#     判据                    预登记              实测                 对账
#     ----------------------  ------------------  -------------------  ----
#     P1 failing              0                   0                    对
#     P2 未配比较点           0(0)                0(0)                 对
#     P3 未配未读点           0(0)/文件 0 字节     0(0)/0 字节           对
#     P4 Not-Compared Unread  0                   0                    对
#     P5 passing              528967              528967               对
#     P6 黑盒/dont_verify     0 / false           0 / false            对
#     P7 verdict              由 PARTIAL 转通过    SUCCEEDED            对
#
#   native_facts: passing 528967 / failing 0 / unverified 0 / aborted 0 /
#                 unread_notcompared 0；unmatched 六项(compare_ref, compare_impl,
#                 unread_ref, unread_impl, bbout_ref, bbout_impl)全 0。
#   fm.log 的 Matching Results 是 P5 的另一条独立来路：
#     2647 by user + 524888 by name + 1432 by signature + 0 by topology = 528967。
#     ★"Unmatched ... unread points" 那一行整行消失★（7b4a825 那轮是 50(635)）。
#   PREDICTOR_PINS: 2711 / 2711 pinned, 0 missed; audit ref=2711 imp=2711
#     (impl-only dead=0)；fm.log 里 `^ *Error:` 计数 0。
#   产物 sha256（完整 64 位）:
#     receipt.json      abb3e3b4332bccf5fbff65a59de1d50aa835cafa6a8eefbf4afb44afb4a97702
#     fm.log            35d4c44f407e209c9b37460893da6a4da6dd2894f48e3017ae5c91c430b0596c
#     unread_points.txt e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
#                       （= 空文件的 sha256；0 字节本身就是 P3）
#     unmatched.rpt     8d3a8aafa355be82a8c3c4d69314700f1b7c26007986126b8be20939a911f24d
#     black_boxes.rpt   2cd7895ceb97d3956f5deff49490daf321f5d72fd5dcb05cece3e0a6e4376922
#   证明输入 sha256:
#     rtl/frontend/Predictor.sv         34617ee9da8c0661af56ded9d7b965e283e22e50a57f9e543a9266a0de977180
#     verif/ut/Predictor/fm_pins_pre.tcl 222d458783bd3308eabc34ac7d3a2c4cf87bd05fbf6c3de323c5f7e38de78506
#
#   ★等"跑完"的锚点别钉裸字符串★（本轮又踩了一次，记在这里）：
#     `grep -qE "Verification (SUCCEEDED|FAILED)" fm.log` 在 verify 刚开始就命中 ——
#     fm_shell 把入口 Tcl 逐行回显进 fm.log，而 scripts/fm_eq.tcl 里正好有
#     `puts "FM_RESULT: Verification SUCCEEDED for $top"` 这行源码。
#     正确锚点是行首：`^FM_RESULT:` 或 `^Verification `。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

FM_VARIANTS = Predictor
FM_REF_DEPS_Predictor = ClockGate.sv Composer.sv DelayN.sv DelayNWithValid.sv \
  DelayNWithValid_1.sv DelayN_1.sv FTB.sv FTBBank.sv \
  FauFTB.sv FauFTBWay.sv FoldedSRAMTemplate.sv FoldedSRAMTemplate_1.sv \
  FoldedSRAMTemplate_20.sv FoldedSRAMTemplate_22.sv FoldedSRAMTemplate_24.sv ITTage.sv \
  ITTageTable.sv ITTageTable_1.sv ITTageTable_2.sv ITTageTable_3.sv \
  ITTageTable_4.sv IndexableCAMTemplate.sv IndexableCAMTemplate_32.sv IndexableCAMTemplate_33.sv \
  IndexableCAMTemplate_41.sv IndexableCAMTemplate_43.sv MaxPeriodFibonacciLFSR.sv MbistClockGateCell.sv \
  MbistPipeFtb.sv MbistPipeIttage.sv MbistPipeIttage_1.sv MbistPipeIttage_2.sv \
  MbistPipeIttage_3.sv MbistPipeIttage_4.sv MbistPipeSc.sv MbistPipeSc_1.sv \
  MbistPipeSc_2.sv MbistPipeSc_3.sv MbistPipeTage.sv PriorityMuxModule.sv \
  PriorityMuxModule_12.sv PriorityMuxModule_16.sv PriorityMuxModule_20.sv PriorityMuxModule_4.sv \
  PriorityMuxModule_8.sv RAS.sv RASStack.sv RegionWays.sv \
  SCTable.sv SCTable_1.sv SCTable_2.sv SCTable_3.sv \
  SRAMTemplate_36.sv SRAMTemplate_44.sv SRAMTemplate_45.sv SRAMTemplate_64.sv \
  SRAMTemplate_68.sv SRAMTemplate_76.sv SRAMTemplate_78.sv SplittedSRAMTemplate_2.sv \
  SplittedSRAMTemplate_23.sv SplittedSRAMTemplate_25.sv SplittedSRAMTemplate_27.sv SplittedSRAMTemplate_3.sv \
  SplittedSRAMTemplate_4.sv TageBTable.sv TageTable.sv TageTable_1.sv \
  TageTable_2.sv TageTable_3.sv Tage_SC.sv WrBypass.sv \
  WrBypass_32.sv WrBypass_33.sv WrBypass_41.sv WrBypass_43.sv \
  array_1.sv array_1_ext.v array_2.sv array_2_ext.v \
  array_3.sv array_3_ext.v array_4.sv array_4_ext.v \
  array_5.sv array_5_ext.v array_6.sv array_6_ext.v \
  data_mem_0_4x2.sv data_mem_0_8x3.sv data_mem_16x12.sv data_mem_8x4.sv \
  sram_array_1p128x24m6s1h0l1b_bp_sc.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
  sram_array_1p512x24m12s1h0l1b_bp_tage.sv sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2
VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# fm-pins-smoke —— 验「钉点落不落得上」，约 90 秒，不跑证明
#
# ★为什么判据里必须带 grep -c，而不是只看 SMOKE_OK★（2026-09-15 实测教训）
#   有一版 fm_pins_pre.tcl 在钉完 256 点之后又打了
#       Error: Unknown name: '0' (FM-036)
#       Information: Current design is no longer set (FM-072)
#   —— 它把 Formality 的当前设计置空了。而冒烟脚本只数钉点、不看 FM 自己报的错，
#   于是照样打印 SMOKE_OK。判别力缺口就在这里：**工具报的错不进判据，等于没报。**
#   所以这里同时要求三件事：2711/2711、SMOKE_OK、且 FM 自报错误行数为 0。
# ---------------------------------------------------------------------------
.PHONY: fm-pins-smoke
fm-pins-smoke:
	@rm -rf fm_work/pins_smoke && mkdir -p fm_work/pins_smoke
	@XSSV_HOME=$(abspath $(XSSV_HOME)) GOLDEN_RTL=$(GOLDEN_RTL) \
	  fm_shell -64 -work_path fm_work/pins_smoke \
	           -file fm_pins_smoke.tcl > fm_work/pins_smoke.log 2>&1; \
	 true
	@grep -E '^PREDICTOR_PINS|^SMOKE_OK|^SMOKE_FAIL' fm_work/pins_smoke.log || true
	@n=$$(grep -cE '^Error:|^Information: Current design' fm_work/pins_smoke.log); \
	 ok=$$(grep -c '^SMOKE_OK' fm_work/pins_smoke.log); \
	 pin=$$(grep -c '^PREDICTOR_PINS: 2711 / 2711 pinned, 0 missed' fm_work/pins_smoke.log); \
	 echo "fm-pins-smoke: SMOKE_OK=$$ok  2711/2711=$$pin  FM自报错误行=$$n"; \
	 if [ "$$ok" != 1 ] || [ "$$pin" != 1 ] || [ "$$n" != 0 ]; then \
	   echo "fm-pins-smoke: FAIL"; exit 1; fi; \
	 echo "fm-pins-smoke: PASS"
