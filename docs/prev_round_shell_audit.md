# 上一轮（xs-v2r2-sv）重写件审计：真重写 vs golden 套壳

**用途**：本轮在决定哪些模块可以从上一轮移植、哪些必须白手起家。这份表是那个决策的依据。

产物：
- `docs/prev_round_shell_audit_files.tsv` —— 逐文件（1,111 个）
- `docs/prev_round_shell_audit_modules.tsv` —— 按 golden 模块聚合（729 个）
- `docs/prev_round_shell_audit.manifest.json` —— 输入路径 / 计数 / 全部 64 位 sha256
- `scripts/prev_round_shell_audit.py` —— 生成脚本，幂等，带 `--selftest` 双向负测

---

## 0. 复跑

```sh
# 判据自测（双向负测：会认的要认，不会认的一个都不许认）
python3 scripts/prev_round_shell_audit.py --selftest      # 27 checks, 0 failures

# 被审对象：上一轮
python3 scripts/prev_round_shell_audit.py \
    --impl-root /home/eda/xs-env/xs-v2r2-sv/rtl \
    --golden     /home/eda/xs-env/G0-canonical/golden-rtl \
    --golden-new /home/eda/xs-env/G1-canonical/golden-rtl \
    --ledger   docs/coverage_three_axis.tsv \
    --universe docs/g1_configured_universe.tsv \
    --incore-root XSTile \
    --out-files   docs/prev_round_shell_audit_files.tsv \
    --out-modules docs/prev_round_shell_audit_modules.tsv \
    --manifest    docs/prev_round_shell_audit.manifest.json

# 对照组：本轮自己（阈值就是从这里量出来的）
python3 scripts/prev_round_shell_audit.py \
    --impl-root rtl --golden /home/eda/xs-env/G1-canonical/golden-rtl \
    --golden-new /home/eda/xs-env/G1-canonical/golden-rtl \
    --ledger docs/coverage_three_axis.tsv \
    --universe docs/g1_configured_universe.tsv --incore-root XSTile \
    --out-files   <tmp>/ctrl_files.tsv \
    --out-modules <tmp>/ctrl_modules.tsv \
    --manifest    <tmp>/ctrl_manifest.json
```

### 输入 commit / 产物 hash（全 64 位）

| 项 | 值 |
|---|---|
| 被审仓库 | `/home/eda/xs-env/xs-v2r2-sv` @ `873760bb25a1a228149efc6863a298e86f257906` (master) |
| 对照 golden | `/home/eda/xs-env/G0-canonical/golden-rtl` @ `4f37f7ed53bfd0b4d5b04c1057757e78ff7bedca` |
| 本轮 golden | `/home/eda/xs-env/G1-canonical/golden-rtl` @ `4f37f7ed53bfd0b4d5b04c1057757e78ff7bedca` |
| 对照组仓库 | 本 worktree `rtl/`（基线 `d15abdb85f43fd22921ef178cd8f2f37bd2c3ebd`） |
| `scripts/prev_round_shell_audit.py` | `eb0858815390b9ff2d5ea3ba88040dbc0d5fe4f47ac49c604252e040ee1d17e6` |
| `docs/prev_round_shell_audit_files.tsv` | `a2e86925cdd87543435b306806c31d5a46de72b0b1131723b5fa3bfe8a0eb4ae` |
| `docs/prev_round_shell_audit_modules.tsv` | `0e115249b2840f3e49a733149636b96528409a339ed8eb07310cacb6a6c8ab94` |
| 对照组 files.tsv | `dc5dfeaf0c21323f10ed0b834591d6137ad0720069195accf34c2b298cbe4a8e` |
| 对照组 modules.tsv | `e6516006aaddea2a95db41c5927bac07a556236526af06de79a7caa36a9c7a04` |

> G0 与 G1 的 golden-rtl 指向**同一个 commit**，但目录内容不同（G0 1,802 个 `.sv`，
> G1 1,999 个）—— 说明 golden-rtl 是生成产物目录，commit 只标了生成时的源码版本，
> 不能拿 commit 相同当成 golden 相同。本审计一律按**文件内容 sha256** 判 G0/G1 异同。

---

## 1. 判据从哪来

全部沿用本轮已有口径，一个字没自创：

- `FORBIDDEN = \b_(GEN|T)(_\d+)?\b`、`codelines()`（去注释 / 去端口表 / 去结构行）、
  逐字重合行五分类 `classify_line()` —— 逐字抄自 `scripts/prev_round_verbatim_scan.py`，
  它自己又抄自 `scripts/readability_audit.py` 的 G 类。
- 逐字率 `0.45` 是 coordinator 给 `prev_round_verbatim_scan.py` 定的那条
  （其 manifest `threshold: 0.45`），原样沿用以便对账。

**新增一条宽口径**：`readability_audit.py` 的 `FORBIDDEN` 要求下划线前是非单词字符，
于是 firtool 极常见的 `_deqPtr_T_1`、`_ghv_wens_60_T` 这种「前缀 + `_T_n`」**一个都不算**。
本脚本另加 `FIRTOOL_TEMP = [A-Za-z0-9_]*_(?:GEN|T)(?:_\d+)?\b`，两个口径都进 TSV，互为交叉验证。

---

## 2. 对照组量出来的「干净」基线

对照组 = **本轮 `rtl/` 全部 420 个文件 / 154,412 行 / 393 个 golden 模块**，
含用户点名的已签核干净件：`DelayReg` 家族 ×11、`StdFreeList`、`UncacheEntry` ×16、
`RASStack`、`WrBypass`。

| 指标 | 对照组实测 |
|---|---|
| gate_A（窄口径 `_GEN_`/`_T_n`）命中 | **0**（420 个文件逐个为 0，max = 0.00/100 行） |
| firtool（宽口径）命中 | **0**（同上） |
| 实质逐字率 加权 | 545 / 31,302 = **1.74 %** |
| 实质逐字率 按模块（限可比行 ≥30） | p50 0.000 / p90 0.048 / p95 0.121 / p99 0.290 / **max 0.3009** |

**max 0.3009 是 `UncacheEntry`：658 条可比行里 198 条与 G1 golden 逐字相同。**
这条推翻了「逐字率高 = 抄」的直觉 —— 写得干净、结构贴 golden 的件，逐字率也能到 0.30。
所以干净上界不能拍在 0.10，只能拍在对照组实测的天花板之上。

对照组里可比行 <30 的小模块（`LevelGateway` 2 行 / 0.40、`SinkA` 7 行 / 0.33）逐字率可以很高，
那是**写法唯一**造成的，不是抄 —— 所以逐字率在小样本上不判。

---

## 3. 分档定义

| 档 | 判据 | 理由出处 |
|---|---|---|
| **T0_CLEAN_REWRITE** | firtool 命中 = 0，且实质逐字率 ≤ **0.31** | 0 是对照组硬实测；0.31 在对照组实测 max 0.3009 之上，使对照组 393 个模块**无一**落到 T0 之外 |
| **T1_PARTIAL_SHELL** | firtool 命中 > 0（任意），或逐字率 ∈ (0.31, 0.45] | 对照组 firtool 恒 0，>0 本身已越线 |
| **T2_MOSTLY_GOLDEN_TEXT** | 逐字率 > **0.45**，或 firtool 密度 ≥ **10/100 行** | 0.45 = 本工程既有阈值；10/100 的依据见下 |
| **T3_VACUOUS_SHELL** | 存在 golden 同名模块，但体是空的（无 assign / 无 always / 无例化） | 电路上等于没做 |
| **T5_CORE_ONLY_NO_WRAPPER** | 只有 `xs_X_core`（核里有真逻辑），**没有** golden 同名模块 | 差一层壳，不是空壳 |
| **T4_TOO_SMALL_TO_JUDGE** | 可比行 < 30 且 firtool = 0 | 对照组证明小样本逐字率无判别力；如实说判不了比硬判诚实 |

`10/100 行` 的依据：上一轮 24 个 firtool 非零模块，密度排下来是
`36.73 / 23.89 / 20.63` 然后**直接掉到 4.82`**，中间一个空档。这三个
（`VLMergeBufferImp` / `Predictor` / `MMIOBridgeEntry`）已逐段人工核过（见 §5），确认是 golden 原文。

### 分档器的假阳性检验

把分档器跑在**对照组**（本轮已签核代码）上，结果：

```
T0_CLEAN_REWRITE 178 | T4_TOO_SMALL_TO_JUDGE 214 | T3_VACUOUS_SHELL 1
T1 / T2 / T5：0 个
```

唯一那个 T3 是 `StorePipe`，且脚本自动标了 `golden_also_vacuous=yes` ——
G1 golden 的 `StorePipe.sv` 自己就是 93 行空体（该配置下被 firtool DCE 的死码），
重写件是空壳是**对的**。这是一个已知真阳性，等于给 T3 判据做了一次实证。
**对照组零假阳性。**

---

## 4. 结果

上一轮在 `rtl/` 下对 **729 个 golden 模块**有实现件。

| 档 | 模块数 | 实现行数 | 对应 G0 golden 行数 | 其中核内（XSTile 闭包） |
|---|---:|---:|---:|---:|
| T0_CLEAN_REWRITE | **232** | 363,304 | 1,247,753 | 195 |
| T1_PARTIAL_SHELL | **18** | 67,507 | 73,055 | 17 |
| T2_MOSTLY_GOLDEN_TEXT | **39** | 105,173 | 130,411 | 37 |
| T3_VACUOUS_SHELL | **2** | 4,790 | 220,966 | 2 |
| T5_CORE_ONLY_NO_WRAPPER | **14** | 1,703 | 6,689 | 13 |
| T4_TOO_SMALL_TO_JUDGE | **424** | 54,379 | 118,962 | 367 |

（行数按「实现单元」算 = 根 `.sv` + 其 `\`include` 闭包 + `import` 到的 `_pkg.sv`；
一个文件塞了 N 个 golden 模块时改为只量该模块自己的 module 体，`scope` 列标明。）

### ★ 核心结论：`.svh` **不是** golden 逻辑原文的藏身处（前提假设被推翻）

任务的前提是「上一轮用 `.svh` 套壳把 golden 原文藏进 include」。量下来**不是这样**。

202 个 `.svh` / 204,373 行，与对应 golden 文件逐行比（原始口径：去注释、去空行，
不做任何结构过滤）：

| | `.svh` | `.sv` |
|---|---:|---:|
| 原始非注释非空行 | 199,801 | 457,949 |
| 其中与 golden **逐字相同** | 41,534（20.8 %） | 138,955（30.3 %） |
| ↳ 端口表 / 声明 / 结构行 | 28,772（69.3 %） | 79,749（57.4 %） |
| ↳ 折行后的实例连线值 `(sig),` | 7,742（18.6 %） | 4,090（2.9 %） |
| ↳ 纯直通 / 拼接元素 / 常量钉死 | 1,362（3.3 %） | 17,583（12.7 %） |
| ↳ **实质逻辑行（这才是「照抄逻辑」）** | **3,658（8.8 %）** | **37,533（27.0 %）** |

换成密度：`.svh` 的实质照抄行 = 3,658 / 199,801 = **1.83 %**；
`.sv` = 37,533 / 457,949 = **8.19 %**。按「可比代码行」算是 13.9 % 对 25.0 %。
**`.svh` 的照抄密度只有 `.sv` 的一半上下 —— golden 原文集中在 `.sv`，不在 `.svh`。**

人工核过两个最大的 `.svh`：
- `backend/backend_logic.svh`（171 真逻辑行、与 golden 逐字重合 0）：是真手写的
  `always_ff` 打拍 glue，只是把 golden 的扁平名当作输入信号名引用。
- `backend/ctrlblock_enqpack.svh`（732 行）：整篇是
  `logic _dispatch_io_enqRob_req_0_bits_pdest;` 一类的实例输出线声明。

`.svh` 的真问题是**另一个**，而且更隐蔽：它让这 204,373 行（占上一轮 `rtl/` 的 29 %）
**整体绕过了可读性闸** —— `scripts/readability_audit.py` 只扫 `.sv`，
`scripts/prev_round_verbatim_scan.py` 的 `rglob('*.sv')` 也一行没扫过（其 manifest
`n_files: 909` 就是证据）。是**审计盲点**，不是藏赃点。本轮「禁止 `.svh` include」
这条规矩挡掉的是盲点，不是赃物。

### 真正的 golden 原文在 `.sv` 里，而且高度集中

按文件：

| | 文件数 | 行数 | 可比代码行 | gate_A | firtool | 实质逐字重合 |
|---|---:|---:|---:|---:|---:|---:|
| `.sv` | 909 | 497,752 | 150,782 | 3,147 | 13,958 | 37,664 |
| `.svh` | 202 | 204,373 | 26,319 | 122 | 555 | 3,658 |

**1,111 个文件里只有 28 个** firtool 命中非零；其中 3 个（`Predictor_wrapper.sv`、
`VLMergeBufferImp.sv`、`memblock` 下 `MMIOBridgeEntry`）就占了绝大部分。

## 5. 人工抽样（密度只是信号，不是判决）

### 5.1 高密度 → 确认是 golden 原文

**`frontend/Predictor_wrapper.sv`**（44,604 行，firtool 23.9/100）
```
4133:  wire             _ghv_wens_60_T =
```
独立复核（不用本脚本的口径，直接逐行比）：
```
impl 非空非注释行 44,593；其中逐字出现在 G0 golden Predictor.sv 里的：43,945 → 98.55 %
```
**结论：这是 golden 的副本，不是重写。** 与已有记录「Frontend = 真 shadow 核」一致。

**`memblock/VLMergeBufferImp.sv`**（6,804 行，firtool 36.7/100，逐字率仅 0.385）
```
328:  wire  _GEN_26 = _GEN_25 | _GEN_4;
520:  {{entries[15].mask}, ... {entries[0].mask}};
```
golden 的 `_GEN_n` 链原封不动留着，只把数组访问改写成 `entries[i].mask`。
**这是「高密度 + 中等逐字率」的典型：批量重命名压低了逐字率，但中间名网络暴露了出处。**
—— 正好印证方法学要求里「低逐字率不等于干净」那条。

### 5.2 低密度但压缩比接近 1 → 抽查

**`MemBlock`**（9 文件 / 6 svh / 33,407 行，g0 31,138，firtool 451，逐字率 0.2711 → T1）
用不依赖结构过滤器的原始口径复算：33,230 行非注释行里 **29,171 行（87.8 %）逐字出现在
golden MemBlock.sv**。差别在于这 29k 行绝大部分是端口表与实例连线（结构必然），
所以按本工程口径判 T1 而不是 T2。**但对「能不能移植」这个决策，实情是：
MemBlock 的实现件里只有约 3k 行是自己写的东西，其余是 golden 形状的连线表。**

**`Slice` 家族**（8 文件 / 5 svh / 8,280 行，svh 占 ~87 %，逐字率 0.1667 → T0）：
用原始口径（不做结构过滤）复算只有 140 / 8,125 = 1.7 % 与 golden 逐字相同。
**svh 多 ≠ 抄**，这一族是真写的。

**`Backend`**（8 文件 / 5 svh / 23,046 行）：原始口径 284 / 22,852 = **1.2 %**。干净。
**`CtrlBlock`**（16 文件 / 13 svh / 30,945 行）：原始口径 866 / 29,406 = **2.9 %**。干净。
—— 这两个是上一轮 `.svh` 用得最狠的模块，也正是「svh 多 ≠ 抄」最直接的反例。

### 5.3 判错了、被人工推翻的两处（都已修进脚本）

1. 首版把 `l2/Queue1_UInt32.sv`、`l2/PBestOffset_children.sv` 里的
   `OffsetScoreTable` / `RecentRequestTable` / `DelayQueue` 判成 **T3 空壳**。
   人工打开 `Queue1_UInt32.sv` 当场推翻 —— 它有 `always @(posedge clock)`、有 `assign`，
   逻辑是真的；真实情况是这些文件**只声明 `xs_X_core`，没有 golden 同名模块**。
   已另开 **T5_CORE_ONLY_NO_WRAPPER** 档，14 个模块从 T3 挪过去。
2. 首版 `_INST_HDR` 把左括号写成可选，端口表末行 `  output io_error_0`（无逗号）
   被当成例化头 → `Rob_wrapper.sv` 这个 3,313 行空模块判成「有例化」，整档判错。
   已加 `--selftest` 双向负测，并**反向验证过负测能抓到这个 bug**
   （把正则改回可选，selftest 立刻报 `例化头误认: '  output io_error_0'` + `空端口表模块被判成真实现`）。

---

## 6. ★ 最刺眼的一条：`Rob` 是个空模块 ★

```
backend/Rob_wrapper.sv   3,313 行
  非注释非空行 3,237
  assign 0 个 / always 0 个 / 例化 0 个
  第 19 行 module Rob( ... 第 3,312 行 endmodule —— 中间全是端口声明
  第 3,266 行：  //   xs_Rob_core u_core ( ... );   ← 核的例化**被注释掉了**
backend/Rob.sv           1,055 行，module xs_Rob_core，**全仓没有任何一处例化它**
```

对应 G0 golden `Rob.sv` = 220,873 行。
本轮台账里 `Rob` 仍是 `MISSING`，且在核内。

> 复跑：
> `grep -c '^\s*assign ' rtl/backend/Rob_wrapper.sv` → 0
> `grep -rn 'xs_Rob_core' rtl --include='*.sv' --include='*.svh'` → 只有声明行 + 一行注释

---

## 7. 本轮核内仍缺、且上一轮做过的模块

条件：`in_core=yes`（G1 golden 从 `XSTile` 实例图可达，闭包 1,662 个模块）
且 `docs/coverage_three_axis.tsv` 里 `rewrite_coverage=MISSING`
且上一轮有实现件 —— 共 **470 个**。

| 档 | 个数 | G0 行数 | G0 与 G1 逐字节相同 |
|---|---:|---:|---:|
| T0_CLEAN_REWRITE（可移植） | **120** | 823,138 | 7 / 120 |
| T1_PARTIAL_SHELL | 16 | 71,619 | 6 / 16 |
| T2_MOSTLY_GOLDEN_TEXT（**别移植**） | 37 | 124,329 | 8 / 37 |
| T3_VACUOUS_SHELL | 1（`Rob`） | 220,873 | 0 / 1 |
| T5_CORE_ONLY_NO_WRAPPER | 10 | 4,730 | 6 / 10 |
| T4_TOO_SMALL_TO_JUDGE | 286 | 70,448 | 160 / 286 |

**G0 与 G1 在这 470 个里绝大多数不是逐字节相同的**（T0 档只有 7/120 相同），
所以「上一轮做过」离「可以直接搬」还差一次逐模块的 G0↔G1 差异确认。
逐模块的 `g0_lines / g1_lines / g0_eq_g1` 三列在 modules.tsv 里。

### T0 里体量最大的 15 个（最值得先看移植）

| 模块 | 上一轮实现行 | G0 | G1 | G0==G1 | svh 文件数 |
|---|---:|---:|---:|:---:|---:|
| StoreQueue | 5,811 | 63,614 | 77,145 | no | 10 |
| LoadQueueReplay | 2,548 | 55,469 | 138,860 | no | 8 |
| CtrlBlock | 30,945 | 41,426 | 57,635 | no | 13 |
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | 1,495 | 35,141 | 69,994 | no | 0 |
| Backend | 23,046 | 34,100 | 79,590 | no | 5 |
| EntriesAluMulBkuBrhJmp | 1,432 | 28,787 | 64,348 | no | 0 |
| Sbuffer | 1,589 | 21,725 | 22,215 | no | 0 |
| RenameTable_2 | 2,140 | 21,082 | 5,030 | no | 0 |
| RenameTable_1 | 2,077 | 20,909 | 3,952 | no | 0 |
| RenameTable | 2,238 | 20,548 | 3,655 | no | 0 |
| NewDispatch | 11,914 | 20,468 | 100,983 | no | 3 |
| PtwCache | 4,348 | 19,600 | 45,308 | no | 6 |
| DataPath | 14,454 | 18,124 | 25,618 | no | 5 |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 1,548 | 17,125 | 41,795 | no | 0 |
| MSHRCtl | 7,230 | 14,467 | 14,590 | no | 0 |

★ 注意 `RenameTable` 三兄弟：G0 两万行，G1 只剩 3,655 / 3,952 / 5,030 行 ——
G1 里这个模块被大改过（很可能 SRAM 被切出去了）。**「上一轮做过」在这里几乎没有价值。**
反过来 `NewDispatch` G0 20,468 → G1 100,983，是反方向的大改。
每一个都得先看 G0↔G1 差异，再决定移植还是重写。

### T1 里核内仍缺的 16 个（有 firtool 残留或逐字率偏高，移植前先清）

`MemBlock` `NewCSR` `DecodeUnit` `LoadUnit` `FusionDecoder` `VSegmentUnit`
`Og2ForVector` `PrefetchQueue` `CSR` `VSieModule` `VSipModule` `SipModule`
`HPerfCounter_13` `CSRPermitModule` `SretEventModule` `TrapEntryDEventModule`

### T2 里核内仍缺的 37 个（**别按「上一轮做过」当资产**）

`Predictor`(44,818) `DCache`(23,644) `InterruptFilter`(12,816) `VLMergeBufferImp`(8,604)
`RenameTableWrapper`(8,005) `TL2CHICoupledL2`(6,469) `L2Top`(3,620) `WbDataPath`(3,002)
`VecExcpDataMergeModule`(1,825) `AtomicsUnit`(1,025) `SieModule`(877) `MvipModule`(834)
`HvipModule`(818) `PMAEntryHandleModule`(705) `PMPEntryHandleModule`(635) `MvienModule`(543)
`HvienModule`(525) `TrapHandleModule`(509) `MMIOBridgeEntry`(505) `MStatusModule`(449)
`TrapEntryHSEventModule`(315) `Debug`(306) `TrapEntryMEventModule`(287) `HPerfCounter_8`(286)
`TrapEntryVSEventModule`(280) `MieModule`(272) `DcsrModule`(267) `VSstatusModule`(263)
`MhpmeventModule`(249) `SpfctlModule`(235) `perfEventsModule`(220) `HstatusModule`(215)
`HenvcfgModule`(195) `MenvcfgModule`(186) `SbpctlModule`(179) `SmblockctlModule`(179)
`TrapEntryMNEventModule`(167)
（括号里是 G0 行数。其中 27 个是 NewCSR 的 field module，逐字率普遍 0.5~0.85。）

---

## 8. 移植前必须知道的两个额外坑

1. **模块外 `import`（`$unit` 作用域跨文件泄漏）**：上一轮 `rtl/` 有 **29 个文件**
   把 `import <pkg>::*;` 写在 module 之外。本轮 `rtl/` 是 **0 个**
   （CONVENTIONS 明文禁止，`scripts/check_pkg_scope.py` 判据 C 把守）。
   核内仍缺的 470 个里有 **15 个**带这个问题，含 `CtrlBlock` / `Backend` / `NewCSR` /
   `DataPath` / `NewDispatch` / `XSCore` / `Slice`×4 / `TL2CHICoupledL2` / `L2Top` /
   `NewIFU` / `MissQueue` / `XSTile`。
   逐字搬过来会直接触本轮的闸。
   复跑：`grep -rlE '^import [A-Za-z_][A-Za-z_0-9]* *::' --include='*.sv' --include='*.svh' <repo>/rtl | wc -l`
   （上一轮 29，本轮 0）

2. **上一轮版本库里有工具派生态**：`rtl/xstop/.XSTop.sv.swp` 是**被 git 跟踪的 vim 交换文件**。
   复跑：`cd /home/eda/xs-env/xs-v2r2-sv && git ls-files | grep -E '\.swp$'`
   （这正是本轮 `scripts/check_no_tool_scratch.py` 要挡的那类东西。）
   另：`rtl/backend/InterruptFilter_xs.sv`（10,800 行）是 UT 派生的 `_xs` 改名副本，
   和 `InterruptFilter.sv`（10,797 行）并存在 `rtl/` 里；`rtl/` 下共 4 个 `_xs` 模块。

---

## 9. 哪些结论有证据、哪些没有

**有证据（可复跑 + 有 hash）**

- 全部逐文件 / 逐模块的行数、密度、逐字率 —— TSV + manifest，脚本带自测。
- 对照组基线（firtool 恒 0；逐字率 max 0.3009）—— 对照组 TSV，hash 在上表。
- 分档器在对照组上零假阳性 —— 对照组 TSV 的 tier 列。
- `Rob` 是空模块 —— 上面给了三条独立可复跑的 grep。
- `Predictor_wrapper.sv` 98.55 % 逐字来自 golden —— 独立于本脚本口径的逐行比对。
- `.svh` 逐字重合 71 / 199,801 —— 独立原始口径复算。
- 26 个模块外 import；被跟踪的 `.swp` —— 单行 grep / `git ls-files`。

**没有证据 / 是判断，不是事实**

- **档位名字里的价值判断**（「可移植」「别移植」）是我的建议，不是测量结果。
  测量结果只有密度、逐字率、空壳与否这三样。
- **T4（424 个，其中核内 367 个）没有结论**。判据在这个尺寸上没有判别力，
  如实标成「判不了」。要定性只能逐个人工看，本次没做。
- **人工抽样只覆盖了 9 个模块**（Predictor / VLMergeBufferImp / MemBlock / Slice /
  Backend / CtrlBlock / Rob / Queue1_UInt32 / backend_logic.svh + ctrlblock_enqpack.svh）。
  T0 档 232 个模块里只人工看了 4 个，**T0 不等于已验证干净**。
- **本审计完全没碰功能正确性**。「逐字率低」只说明不是抄的，不说明写对了。
  UT / FM 的结论一律以本轮台账为准，本表不构成任何正确性判断。
- G0/G1 差异只比了**行数与文件 sha256**，没有做语义 diff；`g0_eq_g1=no`
  只意味着「文件不逐字节相同」，可能只是重编号。`docs/g0g1_renames.tsv` 已记过一批纯重编号。

## 10. 与已有台账的口径差异（不是矛盾，是覆盖面不同）

`docs/prev_round_verbatim.tsv`（manifest `n_files: 909`，阈值 0.45，命中 30）
只扫 `.sv`、只看 ≥60 真逻辑行的文件，且按**文件**报。
本表扫 `.sv` + `.svh`（1,111 个）、按 **golden 模块**报、并加了空壳 / 差壳 / 小样本三档。
两份都在，谁也不替代谁；对同一个文件的逐字率，两边应该对得上（口径函数是同一份代码）。
