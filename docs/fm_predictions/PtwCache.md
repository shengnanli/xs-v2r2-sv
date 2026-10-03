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

## 第 3 轮跑后对账（2026-09-22 07:52Z 跑完；本节只填读数与纠错，不改上面任何一行）

证据：`evidence/6a102f7a5101/PtwCache/`（impl commit 6a102f7a5101ef0ccd0ff8abf477d8fa7c66e0ac，
FM_RUN_ID=PtwCache-20260922T063326Z-6a102f7a，worktree digest 跑前==跑后
512429e98b933a740f38e8bd46362f7eca794673f7763341fd4af489c0ba0364）
  receipt.json sha256  05978b67019a21b6ea5457a9a5501aa46972c2e0f81b4de8172141959ae2ce21
  fm.log sha256        041cdb6d5cd8d8d895ccd52ba0fb3d1cce9329619a42c881b2e3e09d7ced2c0c
  native_facts sha256  d42d306077bc57bae39f3797f2cfe9efc6b032edbd5cea5e72990eae5e97134c
  impl_closure[0]      rtl/mmu/PtwCache.sv 25105e164af4bb8bdf65d1fb651212c0f0851480444dff933a62e8e9c59a46e7

读数（fm.log 692-699 行的 Matched Compare Points 表 + sidecar native_facts.json）：
  native SUCCEEDED / passing 143,717（Port 2714 + DFF 141,001 + LAT 2）/ failing 0（limit 20，未截断）/
  unverified 0 / unmatched 比较点 0(0) / dont_verify 无 / 黑盒 0 /
  ★unread：matched-not-compared 20 对 + unmatched-unread ref 60 / impl 61★
  ⇒ validator **PARTIAL（reason=strict_unread!=0）**，receipt verdict=PARTIAL。
  fm_verdict 的 unread=61 是 max(20, 60, 61)。
  墙钟：elaborate 4 min、match 从 06:37Z 到 ~07:15Z（唯一采样点 142370M/284881 (46%) @2167.9 s）、
  verify 到 07:52Z；CPU 4668.8 s，峰值内存 4735 MB。

逐条对账：
  P1 SUCCEEDED         ★中★（native）。但 strict verdict 是 PARTIAL，不是 SIGNOFF 绿。
  P2 failing=0         ★中★（failing 0 < limit 20，非截断值）。
  P3 unmatched=0       ★中★（比较点两侧 0/0）—— 登记里最怕的 ishptw/s2x_info/pte_index 三点**没有**出现。
                       但未读点里有 60↔61 个 unmatched-unread，见下。
  P4 unread=0          ★不中★：20 matched_nc + 60/61 unmatched unread，allowlist 空。
  P5 黑盒空            ★中★（matched_blackbox_pairs 0、unresolved 0、无 ELAB-147）。
  P6 T∈[156400,172040] ★不中★，而且是口径错：进度行的 284,881 是**两侧对象之和**（ref 143,797 +
                       impl 141,084），不是 ref 侧比较点数；第 2 轮的 156,400 是同口径下 merge 之后的和。
                       用 ref 侧口径：passing 143,717 + matched_nc 20 + ref unmatched-unread 60 = **143,797**，
                       ★逐位等于登记里的手工模型 143,797★（regs 21088 + outs 2714 + 3147 + 116848）。
                       登记里说"手工模型仍算漏 ≥12,603"是把 284,881/156,400 当成了 ref 侧点数，那句判断错了；
                       手工模型本身是对的。"passing==T"因 unread≠0 也不中。
  P7 merge_dup 读回     ★中★：entry_appvars.verification_merge_duplicated_registers=false，
                       fm.log "Merging duplicated registers" 状态行 0（第 2 轮 5）。
  P8 收敛              ★中★：match ~38 min 跑完（第 2 轮 75 min 只到 84%），无需中途取样。

★登记里的一句错话（在此纠正，不改原文）★：第 3 轮登记写"impl 核与第 2 轮登记时逐字节相同、
git diff 为空"。实测 `git diff --stat 9280f5bc..b804a4f0 -- rtl/mmu/PtwCache.sv` = 164+/109−
（115d072b 的 FMR_VLOG-091 函数参数化修法 + 1107f3b7 头注释），剥注释后 sha256 也不同
（1e7b4ffd… vs a640e5b7…）。证明钉在 6a102f7a 的字节上，这句错话不影响证明，但它是错的。

`fm_predict.py check PtwCache`：预期 26599 / 实测 143717 / ABOVE_MODEL（红），与登记预告一致。

### unread 的三族（下一轮的对象）
  a. 20 对 matched_nc（两侧同名签名配上）：17 个 SRAM 叶子 `array_1x_ext/reg_RW0_ren_reg`（golden .v 在
     SYNTHESIS 下 RW0_rdata 直接取 ram[reg_RW0_addr]，reg_RW0_ren 无读者；两侧同一份文件）+
     `resp_res_l{1,2,3}_pre`（golden 的 io_resp_bits_prefetch 只取 sp/l0 那一路，l1/l2/l3 的 pre 无读者，impl 照抄）。
  b. 60 个 ref unmatched-unread ↔ 60 个 impl 同义点（名字/层次不同，签名为空配不上）：
     l2_N_prefetch/l3_N_prefetch ×32 ↔ l2_entry_reg[N].prefetch/l3_entry_reg[N].prefetch；
     hitPre_r/hitPre_r_1/l3Pre_r/l2Pre ↔ l3_pre_r/l2_pre_r/l3_pre_ck/l2_pre_ck；
     data_resp_r_N_entries_prefetch/l1_ramDatas_N_entries_prefetch ×4 ↔ l1_resp_r[N].prefetch/l1_ramdata[N].prefetch；
     wakeup_req_delay_tag[3..8]/wakeup_req_delay_way_info[0]/wakeup_req_way_info[0] ×8 ↔ wk_d_tag[3..8]/wk_d_way[0]/wk_way[0]
     （golden 只读 tag[2:0]/[37:9] 与 way_info[3:1]）；
     mbistPlL{0,1}/addrReg[k]、addrRdReg[k] ×12 ↔ u_mbist_l{0,1}/u_core/同名（共享核 xs_mbist_pipe_core 的位）。
  c. ★impl 独有 1 个★：`sp_hitdata_ck\[prefetch]` —— impl 把 sp 命中项整条 struct 打拍进 check 级，
     其中 prefetch 位另有 sp_pre_ck 一份在用，struct 里那一位无读者；golden 只有 spPre 一份。
     这是 impl 侧多存的死位（IMPL_DEAD），要修 RTL 消掉才能双射。

## 第 4 轮跑前登记（2026-09-27，agent/ptwcache3；本节在证明之前进库，之后不许改）

改动（与本节同一个 commit）：
  1. rtl/mmu/PtwCache.sv：sp_hit_t 去掉 prefetch 字段，sp_pre_c 改为独立的同链优先级选择
     （消掉 impl 独有死位 sp_hitdata_ck[prefetch]；行为不变，那一位本来无读者）。导航表重生。
     ★受影响 receipt★：只有 PtwCache 自己的 evidence/6a102f7a5101（PARTIAL），
     check_shared_impl_impact.py --file rtl/mmu/PtwCache.sv ⇒ 1 个目标 PtwCache。
  2. verif/ut/PtwCache/fm_pins.tcl：60 对同义死位 set_user_match，五族，fail-closed 五层判据；
     纯 tclsh 打桩喂第 3 轮实测名单：pinned 60 / 双射成立 / 家族数 32/4/4/8/12。
  3. verif/ut/PtwCache/Makefile：FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true。
  4. verif/fm_target_config/PtwCache.tcl：fm_target_vmucp_allow + 依据。
  5. docs/fm_predictions/PtwCache.json 重登记（note 里有本轮点预测）。

可证伪的承诺：
  Q1  native SUCCEEDED，validator verdict = SUCCEEDED（strict，allowlist 空）。
  Q2  failing = 0（若 == limit 只写"至少 N 个，计数被截断"）。
  Q3  unmatched 六项全零（compare/unread/bbout × ref/impl）。
  Q4  unread = 0：fm.log 有 PTWCACHE_PIN_END n=60，钉点后 matched_unread_notcompared_pairs = 80。
  Q5  ★passing = 143,797★（143,717 + 80，正好；由 vmucp 实开比较，passing 不增即空转不算过）。
  Q6  黑盒边界仍为空；appvar 读回 merge_dup=false、vmucp=true；无 dont_verify。
  Q7  UT 回归：两档 initreg × 3 seed × 200k 仍 errors=0（RTL 动了一行语义无关的死位，必须重跑）。
  Q8  `fm_predict.py check`：ABOVE_MODEL（工具缺口，预告在先）。

## 第 4 轮跑后对账

（留空，跑完补。）
