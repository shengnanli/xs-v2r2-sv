# PtwCache —— FM passing 跑前登记（本文件在证明之前进库，之后不许改）

登记时的 impl 基线：`agent/ptwcache2` @ 9280f5bc3651ae07e8ad9c80b06dc8f64ac4e032
（"§17-§22：响应装配/perf/栅栏失效/bitmap wakeup 全段追清，236 个输出全驱动"）
golden：G1-canonical/golden-rtl/PtwCache.sv（45308 行，单变体）

## 模型给出的数

    python3 scripts/fm_passing_model.py --from-ut PtwCache
      regs 21088 + outs 2714 = 23802

## ★这个数不能当预测用★

两条独立的理由，任何一条单独就足以让它失去点预测的资格：

1. **merge_dup=true**（本目标没有关掉它的理由，fm_eq.tcl 默认打开）。
   模型的等式 `passing = Σ实例寄存器位 + 顶层输出位` 只在
   `verification_merge_duplicated_registers = false` 时成立。打开时 FM 会把重复
   寄存器合并成一个比较点，合并掉多少取决于设计里有多少重复结构 —— 不是能从
   golden 静态算出来的量。fm_predict.py 自己就把本目标标成 `model_applicable=false`。
   而 PtwCache 恰恰是重复结构极多的件：l0BitmapReg 一个阵列就是 64×4×8 = 2048 位
   同形寄存器，l0h/l0vpns/l0asids/l0vmids 四个 64×4 影子阵列同理。
   合并的余地大到"上界"这个词都快没意义。

2. **模型漏算了 SRAM 一路的存储位**。`fm_passing_model.py` 的实例扫描正则要求
   模块名首字母大写（`^  [A-Z]\w* inst (`），而这一路的实例是
   `sram_array_1p4x786m131s1h0l1b_ptw_l1 array (` 与 `array_10 array (` —— 全小写，
   一个都没数到。手工补算：
     · array_10_ext  ×1 ：`reg_RW0_ren`(1) + `reg_RW0_addr`(2) + `ram [3:0]` 786 位 = 3 + 3144
     · array_11_ext  ×16：(1 + 6) + `ram [63:0]` 114 位 = 7 + 7296，共 112 + 116736
   即模型少算了 ~119,880 位存储 + 115 位流水寄存器。FM 对存储阵列怎么建比较点
   （逐位 / 逐字 / 一个 memory 点）本轮没有实测依据，所以连这块补算都只是量级。

    结论：**预测带宽 = 从 ~2.4e4 到 ~1.4e5，带宽远超 30%，近乎无信息。**
    按 fm_predict.py 的规矩，本目标记 MODEL_NA，**不给点预测**。
    谎称"差不多 23802"才是最坏的选项。

## 那么这次跑前到底承诺什么

不承诺 passing 的数值，承诺**可证伪的定性判据**（跑完逐条对账）：

  P1  native 结论 = SUCCEEDED（不是 INCONCLUSIVE，不是 elaborate 失败）
  P2  failing = 0
  P3  unmatched（两侧任一）= 0 —— 结构上每个 golden 比较点都有对位
  P4  unread = 0 且 allowlist 为空（signoff-strict 的 unread 铁律）
  P5  黑盒边界为空（SRAM 一路两侧同源读 golden，见 verif/ut/PtwCache/Makefile）

★P3 是本轮最可能挂的一条★，已知的三处结构风险（都在 impl 侧，已尽力照抄，
但没有独立验证过）：
  · golden 在 stageCheck 级另存了 `ishptw` / `s2x_info` / `pte_index` 三个寄存器，
    与流水载荷 `data_1_*` 同值但是**另外三个寄存器**。impl 目前用 check_* 一份，
    ★这三点预计 unmatched★。
  · bypass 的 `bypassed_N_valid` 四份同值寄存器 —— impl 已照抄成 4 位向量，应对上。
  · wakeup 第二拍 golden 不存 tag/s2xlate —— impl 已照抄"不存"，应对上。

对账要求：跑完把实测 passing/failing/unmatched/unread 抄回本文件下方的
「跑后对账」一节，逐条标 P1..P5 命中与否；**不许回头改上面的任何一行**。

## 跑后对账

（留空，跑完补。）

## 跑后对账（2026-09-21，本轮到此为止）

★先说结论：FM 没跑完，五条 P 判据**一条都还没有结论**。下面只记已经实测到的事实。★

### 已实测

R1  两侧 elaborate + set_top 都过了（在修掉 FMR_VLOG-091 之后）。
    ★第一次尝试是死在这儿的★：三个函数（sp_level_match / sp_pick / refill_bypass）
    在函数体里直接读模块级信号，Formality 判 FMR_VLOG-091，汇总成
    `FM-262 ... were produced during link` -> `FM-156 Failed to set top design`。
    修法是把依赖写进参数表（commit 115d072b），不是抑制警告。修完 FMR_VLOG-091 归零。

R2  黑盒边界为空（P5 的前半）：SRAM 一路两侧同源读 golden，
    elaborate 日志里 SplittedSRAM_1/2、SRAMTemplate_128/129/143、
    sram_array_*_ptw_*、array_10/11(_ext)、ClockGate、MbistPipePtwL0/L1
    两侧都展开了，没有一个 FMR_ELAB-147 越界告警。
    （array_10_ext addr 2 位/深 4、array_11_ext addr 6 位/深 64，2^addr_w == depth，
      与 Makefile 里写的判据一致。）

R3  ★比较点总数 = 156,400★（`match` 阶段的进度行给出）。
    这个数**验证了跑前登记的那条判断**：模型给的 23,802 不是"差不多"，
    而是差了 6.5 倍。登记里手工补算的"模型漏了 ~119,880 位存储、真值应在
    ~2.4e4 到 ~1.4e5 之间"这条预判，方向与量级都对上了
    （156,400 略高于登记写的上界 ~1.4e5，登记里也已声明那只是量级不是点值）。
    ★这是"不给点预测"这个决定的事后验证：给了就必然是错的。★

### 没实测到（卡在哪）

    match 阶段不收敛。实测两个采样点：
      05:26  142,173 / 156,400 matched (84%)   2654 秒
      05:57  142,969 / 156,400 matched (84%)   4493 秒
    即 31 分钟只多匹配 796 个点，还剩 13,431 个未匹配。
    按这个速率补完要 ~8 小时，超出本轮时间，**没有 passing / failing /
    unmatched / unread 的最终读数**。所以 P1..P5 全部 UNDETERMINED，
    不是 PASS 也不是 FAIL。

    下一轮的三条候选（都还没验证过，写在这里当线索不当结论）：
      · FM_MERGE_DUP=false —— 现在 merge 阶段自己就跑了 7 轮 ref/impl 交替，
        关掉它同时也让 fm_passing_model 的等式重新成立（模型从 NA 变可用）；
      · 先证子件再证父 —— 把 SRAM 一路改回两侧对称黑盒（边界从"空"退成
        "SplittedSRAM_1/2 对称"），比较点会掉掉 ~12 万个存储位，
        代价是 proof_mode 从 signoff-strict 退成 assembly；
      · 查那 13,431 个未匹配点集中在哪一族 —— 需要 match 先跑完，
        或者用 report_unmatched_points 在中途取样。

    ★不许因为跑不完就放松判据★：本轮 receipt 一份都没出，
    check_lane_receipts.py 报 0 条未收录，这是对的 —— 确实什么都没证出来。

## 第 3 轮跑前登记（2026-09-22，agent/ptwcache3，本节在证明之前进库，之后不许改）

起点：main @ b804a4f00c5d3f736dbbecc8386317fadb7fdab1（PtwCache 的 RTL 与 UT 已全部合入；
impl 核 rtl/mmu/PtwCache.sv 与第 2 轮登记时逐字节相同——`git diff 9280f5bc..b804a4f0 -- rtl/mmu/PtwCache.sv`
为空，除头注释去陈旧那两笔 1107f3b7/d86efd31，后者附了"剥注释后同哈希"的复算）。
golden 不变：G1-canonical/golden-rtl/PtwCache.sv。

### 本轮唯一改动的证明语义：FM_MERGE_DUP=false

与本节**同一个 commit** 进库的 `verif/ut/PtwCache/Makefile:FM_MERGE_DUP = false`。
理由与两处核对写在 Makefile 那段注释里，不重复。它是加强不是放宽：比较点只增不减。

### 数值模型：如实说仍不适用（但比上一轮说得更清楚）

`python3 scripts/fm_predict.py model PtwCache` 现在给 **26599**（merge_dup=false ⇒ 工具判"模型适用"）。
★这个数一定是错的★，两步可复算：

1. 26599 = regs 21088 + outs 2714 + **bbin 2797**。bbin 是工具把 `array_10_ext.v`（797 入位）与
   16×`array_11_ext.v`（125 入位）当**黑盒**加上的输入位——因为 `from_ut` 只挑 `.sv` 结尾的依赖。
   而本目标两侧都**白盒**读这两个 `.v`（Makefile 的 RTL_GOLDEN_DEPS / FM_REF_DEPS 都列了它们；
   第 2 轮 fm.log 918/926 行 `Elaborating design array_10_ext / array_11_ext` 两侧都出现）。
   所以这 2797 要去掉，换成两个叶子的**寄存器位**：
       array_10_ext ×1 ： reg_RW0_ren 1 + reg_RW0_addr 2 + ram 786×4     =   3,147
       array_11_ext ×16： (reg_RW0_ren 1 + reg_RW0_addr 6 + ram 114×64)×16 = 116,848
   手工修正模型 = 21088 + 2714 + 3147 + 116848 = **143,797**。
2. 但第 2 轮（merge_dup=**true**）实测的比较点总数已经是 **156,400**，而 merge 只会把
   寄存器点合并**减少**、不会增加 ⇒ merge_dup=false 下总数 ≥ 156,400 > 143,797。
   即手工模型也至少算漏 12,603 点，**本轮跑前没指认出漏在哪**（候选：golden 里 REG_RE 没
   匹配到的声明形态；FM 对 SRAMTemplate_129/143 内部 `hold` 类锁存的建点；进度行里那个
   156,400 的口径是否含 impl 侧独有点——都没验证，写在这里只当线索）。

    结论：本轮**仍不拿任何模型数当点预测**。`fm_predict.py check` 会机械判 ABOVE_MODEL（红），
    这是预期内的、登记 JSON 的 note 已写明原因——不是跑完才发现的。
    不做的事：不改 scripts/fm_passing_model.py 去"迁就"（共享脚本，改了要全仓 recompute，
    而且改完 143,797 照样被 156,400 证伪，等于用一个错数换另一个错数）。

### 可证伪的承诺（跑完逐条对账，不许回头改本节）

  P1  native 结论 = SUCCEEDED（不是 INCONCLUSIVE，不是 elaborate 失败，不是被 kill）
  P2  failing = 0（若 failing == verification_failing_point_limit，只能写"至少 N 个、计数被截断"）
  P3  unmatched（两侧任一）= 0
  P4  unread = 0 且 allowlist 为空（signoff-strict 的 unread 铁律，任何 unread → PARTIAL）
  P5  黑盒边界为空（沿用第 2 轮 R2：SRAM 一路两侧同源 golden，无 FMR_ELAB-147）
  P6  ★数值★ 比较点总数 T ∈ [156,400, 172,040]（下界 = 第 2 轮实测且 merge 只减不增；
      上界 = 下界 ×1.10，是我拍的、可被证伪的带）；且 P2-P5 全中时 passing == T。
  P7  证明语义核对：sidecar/native_facts.json 的 appvar 读回 verification_merge_duplicated_registers=false，
      且 fm.log 里**不出现** "Merging duplicated registers" 状态行（第 2 轮出现了 5 行）。
  P8  match 阶段收敛：若仍不收敛，每 ~30 分钟记一个 (matched/T @ 秒) 采样点，减速即停、
      取样 report_unmatched_points 看未匹配点落在哪一族，不硬等。

第 2 轮的三处结构风险（stageCheck 级 ishptw / s2x_info / pte_index 另存三寄存器；
bypassed_N_valid 四份；wakeup 第二拍不存 tag）本轮 RTL 没动，风险原样带着：
★P3 仍是最可能挂的一条★。

### 跑法（如实记与规范的偏差）

`scripts/run_proof.sh` 在本 commit 上会 exit 6：它先跑 `readability_audit.py`，而 main 现在
有一条 **rtl/backend/Rob.sv 导航腐烂**（[E] 导航行号 2372/2374/2417/2419 没落在分节注释上），
不是本目标的文件、本 lane 不碰它。所以本轮**手工复现** run_proof.sh 的其余步骤：
detached clean worktree @ 本 commit → `make fm-PtwCache`（XSSV_HOME=该 worktree）→
跑前/跑后 tracked 文件整体 sha256 相等 → receipt/fm.log/sidecar 收进 evidence/<commit12>/PtwCache/
并追加 RUN_CONTEXT.tsv。跑证明期间不动那个 worktree 里的任何文件。

## 第 3 轮跑后对账

（留空，跑完补。）
