# verif/sim —— 整芯片（SimTop + difftest + NEMU）仿真泳道

> 当前整芯片对拍（只换 XSTile、逐拍 trace 比对、Verdi 调试构建）的使用说明见 `docs/fullchip_sim.md`；本文是历史泳道记录。

## 一句话

`scripts/full_elab.sh` 证明的是「整芯片 **XSTop** 在 `+define+SYNTHESIS` 下能 elaborate」。
**仿真是另一次完全不同的编译**：top 是 `tb_top` → `SimTop` → `XSTop`，
**不定义 SYNTHESIS**、定义 `DIFFTEST`，走 difftest 官方 VCS 流。
前者 0 error 不蕴含后者能编，实测也确实不蕴含（见下）。

## 三个编译维度的差别

| | full_elab.sh | 本泳道（仿真） |
|---|---|---|
| top | `XSTop` | `tb_top`（difftest）→ `SimTop` → `XSTop` |
| `SYNTHESIS` | **定义** | **不定义**（golden 的断言/随机初值/DPI 全部生效） |
| `DIFFTEST` | 无 | 定义（DPI-C 架构状态导出） |
| 寄存器初值 | — | `+vcs+initreg+random` + `RANDOMIZE_*`（golden 默认配置） |
| `SimTop.sv` | 不参与 | 参与，且带 9897 条层次引用（见下） |

## 已知阻塞：SimTop 的 9897 条 perfCnt_bore 层次引用（XMR）

golden `SimTop.sv` 里 `LogPerfEndpoint logEndpoint(...)` 这一个例化，用 **9897 条
绝对层次引用** 把模块**内部**信号直接引上来，例如：

```
.perfCnt_bore_3 (SimTop.cpu.l_soc.core_with_l2.core.frontend.inner_icache.mainPipe._GEN_0),
.perfCnt_bore_11(SimTop.cpu.l_soc.core_with_l2.core.frontend.inner_icache.missUnit._priorityFIFO_io_enq_valid_T_probe),
```

被引的名字是 firtool 产物（`_GEN_n` / `_T_n_probe` / `*_probe`），**重写件里根本不存在
同名内部信号**，于是整芯片仿真编译直接
`Error-[XMRE] Cross-module reference resolution error` 报死。
这是**端口级 bore（`gatewayIn_packed_bore` / `sigFromSrams_bore_*`，docs 里已登记）
之外的另一套机制**，此前未在本仓登记过。

`LogPerfEndpoint` 共 9903 个端口，**全部是 input**（无任何 output），是纯观测 sink；
perfCnt 只喂性能计数器，不参与 difftest 架构状态比对。所以本泳道的处理是：
在**自己的工作区**生成 `SimTop.sv` 的打补丁副本，把这 9897 条 XMR 接成常量 `'0`。
**不改 golden（只读）、不改 `rtl/`**。补丁由 `run_fullchip.sh setup impl` 机械生成，可复算。

> 代价（如实记）：impl 侧的性能计数器全灭。架构行为与 difftest 判定不受影响，
> 但「perf 计数与 golden 一致」这条不在本轮验收范围内了。

## perf 观测重绑（codex 0160 P2）—— 另一条路径，不动上面那条

上面的全接 `'0` 只对**功能 smoke** 成立，对 **perf 验证不成立**（codex 0160 原话：
「not an acceptable permanent solution for performance validation」）。
所以另起一条并行路径，**不改 `run_fullchip.sh` 现有行为**：

```bash
verif/sim/run_perfbind.sh setup            # 生成重绑 SimTop（工作区 /home/eda/xs-env/sim-work-perfbind）
verif/sim/run_perfbind.sh build impl
verif/sim/run_perfbind.sh run   impl  <workload.bin> <max-cycles>
verif/sim/run_perfbind.sh run   golden <workload.bin> <max-cycles>
verif/sim/run_perfbind.sh compare <golden assert.log> <impl assert.log>
```

生成器是 `scripts/perf_rebind.py`，分档由 `scripts/perf_tier.py` 另算（都进
`gate_all.sh` 的幂等闸）：

| 表 | 是什么 |
|---|---|
| `docs/perf_bore_map.tsv` | 9897 条 XMR **逐条**的绑定与证据等级 |
| `docs/perf_bore_unbound.tsv` | 没绑上的 bore（perf_rebind 的口径） |
| `docs/perf_rep_counters.tsv` | 代表性计数器组（先验这一组，再谈大面积比对） |
| `docs/perf_tier_ledger.tsv` | **每个计数器一行**的分档（codex 0162 D3），25888 行 |
| `docs/perf_gap_ledger.tsv` | **测不了**的计数器逐条台账 + 解除条件，599 行 |
| `docs/perf_mismatch_ledger.tsv` | 实测每一条不等的逐条裁定（WAIVED / BLOCKING） |

绑定分五级，证据强度不同，**不混着报**（判据写在 `perf_rebind.py` 头部）：
`T0_UNCHANGED`（原样）/ `T1_PATH_REBIND`（只有路径变了，逐位同一根线）/
`T2_CONE_PORT`、`T2_CONE_PORT_CHILD`（golden 组合锥原样复制，叶子重指到重写层次的
**端口**——端口是 FM 的比较边界）/ `T3_REG_LEAF`、`T4_OPEN`（**判不准，如实留白**）。

### 分档（codex 0162 D3）—— 判据在 `scripts/perf_tier.py`

"绑上了没有"和"这条差异挡不挡里程碑"是两个问题。后者按 D3 分档，判据**从 golden
RTL 现场算**，不靠名字猜：

| 档 | 判据（机器可判） | 要求 | 条数 |
|---|---|---|---|
| `A_FUNC_ASSERT` | golden 的 `[ERROR]` 断言 | 必须相等 | 369 |
| `B_CONTROL` | 至少一条 bore 观测的线（拆掉 firtool 探针拷贝后）**被本模块可综合逻辑读**、或本身是端口、或喂给子实例的输入端口 | 必须相等 | 13332 |
| `C_DIAG` | 全部 bore 观测的线都没有读者 —— 把这些计数器整条拿掉网表逐位不变 | 显式归类后允许不同 | 10308 |
| `D_CONST` | 打印的实参是 golden 字面量（如 `util_underflow` 印的就是 `64'h0`） | 恒等 | 876 |
| `D_INVARIANT` | 反向闭包里一条 bore 都没有（如 `util_sampled` = 采样拍数） | 同 dump 时刻下恒等 | 1003 |
| `X_UNRESOLVED` | 上面都判不出来 | ★闸红★ | **0** |

**软件可见的 PMU 自动落进 `B_CONTROL`**：hpm 事件在 golden 里走 `io_perf_*` 输出端口，
观测它的 bore 必然"被读"。两个实测例子（都可以直接翻 golden 复核）：

```
StdFreeList.sv:978   wire [7:0] freeRegCntReg_probe = freeRegCntReg;   ← bore 观测点
StdFreeList.sv:999   io_perf_0_value_REG <= freeRegCntReg < 8'h27;     ← 同一根线喂 hpm
StdFreeList.sv:979   wire empty = freeRegCntReg == 8'h0;               ← 还喂控制
```

`FTB.perfEvents_0_2_probe` 同理。所以不需要另写一条按名字认 PMU 的判据，也就不会漏。

三个**踩过的坑**（前两个写进了负测 `scripts/test_perf_tier_gate.py` 第 11/12 条，
且做过变异验证 —— 把修复各回退一次，对应的负测都当场红）：

* 不剥 `` `ifndef SYNTHESIS `` 段，一根只在断言里出现过的线会被误判成"馈入控制"；
* 不查**子实例端口方向**，`.io_commits_info_0_debug_pc (_probe)` 这种"子模块**输出**
  驱动本模块网线"会被当成"有人读"—— `rob: robHeadPC` 因此一度被误判成 B_CONTROL
  并挡住里程碑，而它其实是 Rob 的 debug 输出、CtrlBlock 里无人读；
* 直方图的桶只在 `if (perfCnt_bore_N > …)` 的**条件**里提到那条 bore。不跟条件的话，
  整族桶会被算成"不依赖任何 bore"，该排除的就不会被排除。

另外记一条**不是坑但值得知道**的：15 条断言在 golden 里条件就是
`wire _GEN_15 = (`PRINTF_COND_) & 1'h0;` —— 恒 0，永远不会响（itlb/dtlb 的
non-block、LoadUnit 的 merge buffer、l2tlb cache 的 ecc）。台账里这些行的
criterion 是 `assert_cond_no_bore`，不要读成"漏掉了 bore"。

### 实测（CoreMark 2-iteration，两侧同为 20000 拍，2026-09-14 跑，2026-09-15 重判）

golden 用纯 golden simv，impl 用重绑 SimTop 的 simv，**同一条命令、同一个 workload、
同一个 max-cycles**。两侧各打出 27921 行 `[PERF ]`，dump 时刻都在 cycle 19999。

复跑（输入 sha256 见 `docs/perf_mismatch_ledger.tsv` 头部）：

```bash
python3 scripts/perf_compare.py \
  /home/eda/xs-env/sim-work/perfbind-runs/golden_cm20k/assert.log \
  /home/eda/xs-env/sim-work-perfbind/impl/run/cm20k/assert.log \
  --all --emit-mismatch docs/perf_mismatch_ledger.tsv
```

| | 结果 |
|---|---|
| 代表性组（`docs/perf_rep_counters.tsv`，21 条） | MATCH 18 / MISMATCH 0 / EXCLUDED 3 / MISSING 0 |
| 全量（25427 个计数器） | **MATCH 24814 / MISMATCH 24 / EXCLUDED 589 / MISSING 0** |
| MISMATCH 裁定 | **WAIVED 24 / BLOCKING 0**（全部 C_DIAG 且持有模块未重写） |
| golden 断言 | 0 条 `[ERROR]`；impl 也是 0 条 |

> 与上一版（MATCH 24811 / EXCLUDED 592）的差别是 **3 条**：
> `ftq: {backend_redirect,bpu_update,ifu_redirect}_latency_sampled`。
> 旧的 `also_feeds` 按"同族"整片排除，把这三条也扫了进去；而它们是
> **NSamples 计数器**，由另一条已绑上的 bore 驱动，两侧实测 382/382、2732/2732、
> 284/284 —— 是真测到的相等，不该排除。`perf_tier.py` 改用 LogPerfEndpoint 内部的
> **反向数据流闭包**（连 `if` 条件一起跟），所以只排该排的。新排除集合是旧集合的
> **真子集**（0 条新增），没有把任何假零放回 MATCH。

★ 24 条 MISMATCH 逐条裁定见 `docs/perf_mismatch_ledger.tsv` ★。全部 `C_DIAG`，
持有它们的 7 个 golden 模块（CtrlBlock / Tage_SC / MainPipe / MissEntry / StoreQueue /
StreamBitVectorArray / StrideMetaArray）本轮**都没有被重写**，所以按 D3 豁免，
不挡当前里程碑。集中在三处：

  * `bpu.predictors.tage`：6 条，全部恰好 ±1029 —— TAGE 的 provider 选择与 SC 的
    agree/disagree 在 1029 次预测上与 golden 不同（`bank_0_tage_provided_at_pred`
    总数相同，变的是**哪张表**提供）；
  * `l1PrefetcherOpt`（stream_bit_vec_array / stride_meta_array）：10 条直方图；
  * 零星：`dcache.mainPipe: replace_unused_prefetch`（0 vs 4467）、
    `storeQueue: vaddr_match_failed`（24 vs 11）、
    `missQueue.entries_*: load_miss_penalty_to_use`（±1）、`rob: robHeadPC`。

**豁免是有有效期的**：`scripts/check_perf_tier.py` 每次跑闸都用 `rtl/**/*.sv` 现场
重算 `owner_rewritten`。Tage_SC 一旦被重写，那 6 条当场从 WAIVED 翻成 BLOCKING、
闸变红（负测 `scripts/test_perf_tier_gate.py` 第 1 条就钉的这个）。

> 这条**比 codex D3 的最后一句更严**，是有意的。D3 说 "identity of an internal
> provider table need not match unless it affects a control/performance-contract
> output" —— 按字面，模块重写之后 C_DIAG 仍可不同。这里不照搬，因为本工程的上位
> 目标是与 golden **bug-for-bug** 一致（"良性差异文档化"这条路线被否决过）。
> 翻红之后的正确处置不是放宽判据，而是拿出"该差异不影响任何 control/perf-contract
> 输出"的正面证据，带着证据改 `verdict_of` 并同步改负测 —— 一次有记录的判据变更，
> 好过一个谁都能随手绕过的开关。

### ★589 条 EXCLUDED 是一本待办台账，不是"通过"★

`docs/perf_gap_ledger.tsv` 逐条记了：属于哪一档、哪几条 bore 没绑上、bore 的
tier、持有模块、**以及什么条件下能解除排除**。按档拆开看，结论比"EXCLUDED 592"
难看得多，也诚实得多：

| | 条数 | 意味着 |
|---|---|---|
| `B_CONTROL` 且 GAP | **427** | 这些是**必须相等**的计数器，而本轮**根本没测** |
| `C_DIAG` 且 GAP | 162 | 允许不同的，也没测 |
| `A_FUNC_ASSERT` 且 GAP | 10 | 断言条件没绑上 = 这 10 条断言在 impl 侧**不会响** |

未绑 bore 的分布：`T3_REG_LEAF` 548 条（golden 组合锥展到内部寄存器，寄存器不是
FM 的比较边界，机器判不出对应物）、`T4_OPEN` 51 条（perf_rebind 的 firtool 方言
解析没闭合，是工具的洞）。

持有模块：`Ftq` 296 / `StdFreeList` 168 / `EntriesVfdivVidiv` 50 / `LCredit2Decoupled*` 47 /
`FTBBank` 16 / `SourceB` 16 / 其余零星。**其中 564 条的持有模块本轮已经重写了**
（`owner_rewritten=yes`）—— 也就是说这个缺口不是"还没动的模块"，而是
"动过、但内部观测点绑不回去"。这是下一波要收的口子。

另外，`ftq: commit_num_inst_mean` 在 golden 侧印了、impl 侧没印（`*_mean` 由
`NSamples != 0` 守着，而 impl 的 NSamples 是假零）。它本来就在 GAP 集合里，
所以 `MISSING` 仍是 0 —— 但这正说明"接零"会一路传染到**打印与否**。

### 随机初值这个解释已排除（证据强于上一版记的）

golden 自己换一个 `+ntb_random_seed=987654321` 再跑一遍，两份 `assert.log`
**逐字节相同**（`sha256 6ceb4c0d99a048ad622035f392194dd1212dedff8457a42074e9371ea930ae39`，
两份一致），不只是"25427 个计数器一个都没变"。VCS 也确认种子被吃了：
`Note-[VIUNRD] initreg using ntb_random_seed ... +ntb_random_seed=987654321`。
（诚实的保留仍在：这证明**这份 simv 的输出对 initreg 种子不敏感**，
不等于证明 `$random` 被扰动过。）

### perf 打印怎么才会出现

`LogPerfEndpoint` 的 `io_logEnable = timer >= logCtrl_begin && timer < logCtrl_end`，
两个值来自 difftest 的 `+b=` / `+e=`，**默认 begin=end=0，所以一行都不打**。
必须给 `+e=<大数>`。dump 时刻由 difftest 在 GOODTRAP/EXCEED/FAIL 或 `+max-cycles`
最后一拍触发。打印走 `$fwrite(32'h80000002)` = **stderr** —— 所以 `[PERF ]` 落在
`assert.log`，不在 `sim.log`。（这两条都踩过，写在这里省下一次空跑。）

## 用法

```bash
verif/sim/run_fullchip.sh build golden     # golden 对照基线（不打补丁）
verif/sim/run_fullchip.sh build impl       # 重写件优先 + SimTop 打补丁
verif/sim/run_fullchip.sh run   golden     # coremark-2-iteration + NEMU difftest
verif/sim/run_fullchip.sh run   impl
```

工作区默认 `/home/eda/xs-env/sim-work/{golden,impl}`（`SIMW=` 可改），
不落在任何 git worktree 里。

## 里程碑怎么读

- **出时钟**：`tb_top` 自己产生，`initial #100 reset=0`。
- **复位释放**：仿真时间 100ns。
- **第一条指令提交（retirement）**：日志出现
  `The first instruction of core 0 has commited. Difftest enabled.`
  判据在 difftest C++ 侧：`commit[0].pc == FIRST_INST_ADDRESS`(0x10000000)。
  超时则是 `The first instruction of core 0 at 0x10000000 does not commit after N cycles.`
  —— **本工程踩过一次坑**：这条超时信息曾经不是 DUT 坏，而是 golden RTL 生成时
  `--enable-difftest` 没生效、commit pc 恒 0（见 memory `golden-coremark-difftest.md`）。
  G1-canonical 已复核：`DiffExtInstrCommit` 的 `io_pc [63:0]` 端口在、
  `GatewayEndpoint.sv` 里接的是真信号 `_validated_module_out_bits_6_bits_pc`，**不是常量**。
- **终点**：`HIT GOOD TRAP` + `DIFFTEST WORKLOAD DONE at cycle N`（golden 上一轮 = 6492）。
- **功能失配**：difftest 打 `Mismatch detected ...` 并 dump ref/dut 寄存器对照。

## 运行必需参数

`+ram_size=8589934592`（8GiB）—— 默认 8TB 会让 NEMU `init_mem` 崩。

## 这 9897 条里到底断了多少（`verif/sim/bore_audit.py` 机械可复算）

```
XMR 总数: 9897
   9126  信号存在-golden模块      <- 指向未重写模块，正常解析
    507  信号缺失-重写模块        <- 重写件里没有同名内部信号
    262  路径中断(实例名对不上)   <- 重写件里没有同名**子实例**
      2  信号存在-重写模块        <- 偶然同名
```

即 **771 条探针指向重写模块，其中 769 条断**（7.8%）。涉及 36 个重写模块，头部：

| 断的条数 | 模块 | 断法 |
|---|---|---|
| 89 | `Ftq` | 内部信号名 |
| 52 | `SinkA` | 内部信号名 |
| 50 | `EntriesVfdivVidiv` | 内部信号名 |
| 49×4 | `TageTable{,_1,_2,_3}` | 内部信号名 |
| 35 | `OpenLLC` | 子实例 `rnLinkMonitor`/`snLinkMonitor` 不存在 |
| 20 | `FTBBank` | 内部信号名 |
| 16+9 | `ICache` | 子实例 `mainPipe`/`prefetcher` 不存在 + 内部信号名 |
| 50 | `WritebackQueue` | 子实例 `entries_0..9` 不存在 |
| 7 | `LinkMonitor` | 子实例 `LCredit2Decoupled_rxsnp` 不存在 |

「子实例不存在」这一类说明重写件不只是内部**信号**改名，**子模块划分本身**也变了
（如 `WritebackQueue` 的 10 个 `entries_N` 单条目子模块被合进了阵列写法）。
所以「按 golden 保留探针名」这条路对这类模块不是改名能解决的，得改结构。

---

# 2026-09-14 第一轮实跑结果

## 结论先行

**重写整芯片能复位、能出时钟、能提交指令，并且在最小体系结构测试上与 golden
逐周期一致。** 目前**没有**发现任何功能失配。

## 途中踩到的两个真阻塞（都不是 DUT 的问题，但不修就一步也跑不了）

### 阻塞 1：SimTop 的 9897 条 perfCnt_bore 层次引用

见上文。处理：本工作区生成打补丁的 SimTop 副本（不改 golden、不改 `rtl/`）。
**只有 impl 侧需要**；golden 侧用原版 SimTop。

### 阻塞 2：★golden 环境自己是坏的★ —— `XiangShan/build/generated-src` 与 `build/rtl` 不是同一次生成

- `build/rtl/*`（= G1-canonical golden-rtl，逐字节相同）生成于 **2026-09-09 21:40**，
  命令带 `--enable-difftest`。
- `build/generated-src/*`（difftest 的 DPI C++ 胶水）却是 **22:01** 写的，
  `difftest_profile.json` 里记的命令是
  `--target-dir build_xstop/rtl --fpga-platform --disable-all --remove-assert`
  —— 那是 20 分钟后另一次 **FPGA/RELEASE** 形态的生成，把 generated-src 覆盖了
  （difftest 的 `FileControl.scala` 把 generated-src 硬编码写到 `$NOOP_HOME/build/generated-src`，
  不跟 `--target-dir` 走）。
- 后果：golden RTL 例化 27 种 `DummyDPICWrapper_*`，而这份 dpic 只提供 21 个函数，
  且其中 3 个（`Phy*RegState` / `*RenameTable`）RTL 根本不用。缺的 12 个里就有
  `ArchIntRegState` / `ArchFpRegState` / `CommitData` / `StoreEvent` …
  **golden 自己一跑就死**：
  `Error-[DPI-DIFNF] ... 'v_difftest_ArchFpRegState' does not exist`，Time 2287 ns。
- 还有第二层坑：`difftest-state.h` 的**结构体布局**也跟着变了。只换 generated-src
  再增量重编，VCS 只重编了 `difftest-dpic.cpp`，`difftest.cpp`/`diffstate.cpp` 等
  **沿用旧头文件编出来的 .o**，于是出现"整数寄存器对得上、pc 和浮点寄存器是随机值"的
  假失配（`pc ... right=0x10000000, wrong=0x002d002c002d002c`）和裸 segfault。
  必须**显式删掉那 48 个 C++ .o 强制重编**（RTL 的 .o 不能删，否则 55 分钟白编）。

**修法（本泳道做的）**：用 `make sim-verilog CONFIG=KunminghuV2Config` 在隔离目录
（`NOOP_HOME=`/`BUILD_DIR=` 都指向 `sim-work/regen`）重新生成一份，取它的 generated-src。
**顺带证明了 G1-canonical 可复现**：重新生成的 2061 个文件里 **2057 个与 G1 逐字节相同**，
4 个差异分别是 `SimTop.fir`（dump 格式）、`metadata/`（本次未生成）、
`CommitIDModule.sv` 与 `NewCSR.sv`（只差内嵌的 git SHA：`133d7dc4b` vs `b36a1a2a5`）。

> **给 golden/基线 owner 的账**：`G1-canonical/` **不含 generated-src**，
> 因此**这份"唯一 golden 对照"目前不足以复现一次仿真**——必须另外重生成 DPI 胶水。
> 建议把 generated-src（6 个文件、约 120KB）纳入 canonical 包并记进 MANIFEST。

## 里程碑（coremark-2-iteration，difftest + NEMU）

| 里程碑 | golden | impl（重写件优先） |
|---|---|---|
| 出时钟（`tb_top` `always #1`） | ✅ | ✅ |
| 复位释放（100 ns = cycle 50） | ✅ | ✅ |
| **第一条指令提交** `The first instruction of core 0 has commited. Difftest enabled.` | ✅ | ✅ |
| 走完 bootrom → 跳 0x80000000 → 跑到负载 UART 输出 `Running CoreMark for 2 iterations` | ✅ | ✅ |
| difftest 逐指令锁步（NEMU）无失配 | ✅ | ✅ |

## 最小既有体系结构测试：`flash_recursion_test.bin`（跑到终点）

| | golden | impl |
|---|---|---|
| 结果 | `HIT GOOD TRAP at pc = 0xe` | `HIT GOOD TRAP at pc = 0xe` |
| instrCnt | 289 | **289** |
| cycleCnt | 4,642 | **4,642** |
| IPC | 0.062258 | **0.062258** |
| `DIFFTEST WORKLOAD DONE at cycle` | 4649 | **4649** |
| difftest 失配 | 0 | **0** |

**逐周期一致**。这是本工程第一次把重写整芯片跑到一个体系结构测试的终点。
（该测试自带一次 `HIT CRITICAL ERROR: please check if software cause a double trap`，
golden 侧同样出现，是负载行为不是 DUT 差异。）

## 为什么 coremark 没跑到终点

实测仿真速度 **≈75 cycle/s**（`+max-cycles=20000` 用了 267 s）。difftest 的 vcs.mk 固定带
`-debug_access+all` + verdi PLI，整芯片下极慢。coremark 2 迭代远不止 memory 里记的
"cycle 6492"（那个数字与本次实测对不上，**存疑**），按 IPC~1 估要千万级周期
= 数十小时。所以本轮只能给"跑了多少周期无失配"，不能给 coremark 的 GOOD TRAP。
要跑完 coremark 得先编一版**去掉 `-debug_access+all` 的快 simv**（需要改 difftest 的
vcs.mk 或用 `EXTRA` 覆盖，未验证）。

## 顺手抓到的一个 rtl/ 问题（**没改，交给对应 owner**）

`rtl/uncore/SubDirectory.sv:60` 与 `rtl/uncore/SubDirectory_1.sv:61` 里有
`` `timescale 1ns/1ps ``。golden 侧没有任何 timescale 指令。后果：impl 整芯片编译的
时间精度被这两个文件改成 1ns/1ps（golden 侧是 1ns/1ns），**而且生效范围取决于文件顺序**。
本轮结果未受影响（周期数完全一致），但这是个与 golden 的编译差异 + 顺序相关的隐患。

`rtl/backend/RegCache.sv:150` 的 7 条 SIOB（`rcidx_delay[(0-1)][*]`）在**仿真**里
不像综合那样只是 lint：越界读返回 X。本例中 `(s==0)?:` 的条件是 genvar 常量，
VCS 会常量折叠，实测无影响；但清理 owner 值得知道仿真语义上的区别。

## nexus-am cputest：33 个小体系结构测试，**33/33 逐周期一致**

coremark 跑不完（~75 cycle/s），所以本轮改用 nexus-am 的 33 个 cputest：每个约
100~10000 条指令、4300~13800 周期，单次 ~33s，并行 12 路约 6 分钟出全表。
负载现编（本机只有 `riscv64-none-linux-gnu-` 工具链，nexus-am 默认找
`riscv64-unknown-linux-gnu-`，必须显式覆盖 `CROSS_COMPILE`）：

```bash
export AM_HOME=/home/eda/xs-env/nexus-am NOOP_HOME=/home/eda/xs-env/XiangShan
export PATH=/home/eda/xs-env/XiangShan/riscstar-toolchain-15.2-r1-x86_64-riscv64-none-linux-gnu/bin:$PATH
cd $AM_HOME/tests/cputest && make ARCH=riscv64-xs CROSS_COMPILE=riscv64-none-linux-gnu-
verif/sim/run_cputest.sh 12
```

**结果：33/33 全部 `HIT GOOD TRAP`，golden 与 impl 的 `instrCnt` 与 `cycleCnt`
逐项完全相同，两侧 difftest 失配数均为 0。** 全表见
`verif/sim/evidence/cputest_golden_vs_impl.tsv`。覆盖 add/sub/mul/div、longlong、
移位/位操作、符号扩展、**非对齐访存**、load-store、分支/switch、递归、
快排/冒泡/选择排序、矩阵乘、字符串与 printf（走 UART MMIO）。

**所以：本轮没有找到任何功能失配。** 不是"没跑到"，是"跑了、比了、一致"。

## coremark 定量补充：两侧各跑满 100,000 周期，失配 0

`+max-cycles=100000`，两侧同一负载 `coremark-2-iteration.bin` + NEMU 锁步：

| | golden | impl |
|---|---|---|
| 到达周期 | `EXCEEDED MAX CYCLE: 100000` | `EXCEEDED MAX CYCLE: 100000` |
| difftest 失配 / BAD TRAP | 0 | **0** |
| 墙钟 | 2273 s | 2329 s |

即：重写整芯片在 coremark 上**连续 10 万周期逐指令与 NEMU 一致**，没有任何架构状态偏差。
（`copy_and_run.bin` 实为 1 迭代 coremark，两侧都到 `jump to ram_start / Running CoreMark
for 1 iterations` 后被 1800s 墙钟超时截断，同样零失配，但没有终点结论。）

## 本轮没做到的（如实）

1. **coremark / microbench / linux 没有跑到终点**。瓶颈是仿真速度（~75 cycle/s），
   不是功能。要跑完得先编一版去掉 `-debug_access+all` + verdi PLI 的快 simv
   （difftest 的 `vcs.mk` 里写死，需在**本工作区的 difftest 副本**里改，未尝试）。
2. **impl 侧的性能计数器全灭**（9897 条 perfCnt_bore 接了 '0）。因此"perf 与 golden 一致"
   这条**完全没有验证**。要验证必须走层次重绑，或改用端口级导出。
3. **没有跑打过同样补丁的 golden 作对照**。理由：impl（打补丁）与 golden（没打补丁）在
   33 个 cputest 上逐周期相同，已经反证补丁不影响架构行为；但严格说这是推论不是实测。
4. 只跑了单核（`NUM_CORES=1`）、只跑了 KunminghuV2Config、没跑带 MMU/中断/多核的负载
   （cputest 全是 M 模式裸程序；`flash_recursion_test` 碰了一次 double-trap 路径）。
5. 没测中断/PLIC/CLINT/L2 一致性等需要长跑或多核才触发的路径。

---

# 2026-09-14 第二轮：快 simv 泳道（去 `-debug_access+all`）

## 先纠正上一轮 README 与工单里的两处事实

1. **「`-debug_access+all` + verdi PLI」里没有 verdi PLI。**
   `sim-work/*/build.log` 第 6 行的真实 vcs 命令行里不含任何 `-P .../novas.tab .../pli.a`。
   difftest `vcs.mk` 只在 `ifeq ($(CONSIDER_FSDB),1)` 里追加 verdi PLI，而本流程从未
   设过 `CONSIDER_FSDB`。**慢的原因只有 `-debug_access+all` 一条。**

2. **「~75 cycle/s」是 20k 周期那次的口径。** 两个数都真实，但用于估长跑的应该是
   100k 那次：golden `2272.750 s / 100000 cycle = 44.0 cycle/s`，
   impl `2328.720 s / 100000 cycle = 42.9 cycle/s`。
   (20k 那次 261.810 s → 76.4 cycle/s，因为前 2 万周期是 bootrom，活动量低；
   两点之间的边际速率是 `80000/(2272.75-261.81) = 39.8 cycle/s`。)

## `run_fullchip.sh` 有两个「跑一次就崩」的 bug（已修）

上一轮提交的脚本在本机 `/bin/bash 4.4.20` 下**一步也跑不了**，说明它没有被端到端复跑过：

1. `local side=$1 dd=$SIMW/$side` —— bash 在调用 `local` 之前先对整行做词展开，
   此时 `side` 尚未赋值，`set -u` 立刻 `side: unbound variable` 退出。
   `setup()` / `build()` / `run()` 三个函数全中。
2. `setup impl` 不幂等 —— impl 分支把 `build/rtl` 做成**真目录**（逐文件软链），
   第二次跑时 `ln -sfn "$GOLDEN_RTL" "$dd/build/rtl"` 不会替换目录，而是在**目录里面**
   建一个 `golden-rtl` 链接；紧接着 `rm -f "$dd/build/rtl"` 报 `Is a directory` 退出。

## 快 simv 到底改了什么

工作区 `/home/eda/xs-env/sim-fast`（与 `sim-work` 完全隔离，不在任何 git worktree 里）。
`verif/sim/run_fastsim.sh` 机械地生成一份 difftest 副本并打两个补丁，
**`diff -rq` 证明整个副本只有这两个文件与 stock 不同**：

1. `vcs.mk`：删 `-debug_access+all`；`-j200` → `-j16`（只影响编译并行度，
   两侧并行编译时防止 400 个 gcc 打爆内存）。
2. `src/test/vsrc/vcs/top.v`：`$vcdplusfile`/`$vcdpluson` 两行换成报错提示。
   **这是必须的**：这两个 VPD 系统任务只在 `-debug_access` 下才被定义，哪怕运行期
   被 `if ($test$plusargs("dump-wave"))` 门住，VCS 也在**编译期**直接报
   `Error-[UST] Undefined System Task call to '$vcdpluson'`，`simv` 根本编不出来。

两侧实际 vcs 命令行的差分（路径归一化后，`verif/sim/results/vcs_flag_diff.txt`）**只有两行**：

```
< -debug_access+all
< -j200
> -j16
```

也就是说 `+define+DIFFTEST` / `+define+VCS` / `RANDOMIZE_{GARBAGE_ASSIGN,INVALID_ASSIGN,
MEM_INIT,REG_INIT}` / `RANDOMIZE_DELAY=1` / `UNIT_DELAY` / `no_warning` /
`+vcs+initreg+random` / `-timescale=1ns/1ns` / `+lint=TFIPC-L` **一个没动**，
golden 与 impl 两侧用的是同一份 `vcs.mk`、同一套开关。

**代价（如实记）：快 simv 没有任何波形能力。** 撞到失配要看波形，得回 `sim-work` 的慢 simv 复现。

## 负载

| 负载 | 来源 | 说明 |
|---|---|---|
| `coremark-2-iteration.bin` | `XiangShan/ready-to-run/`（原封不动） | `ITERATIONS=2`，`TOTAL_DATA_SIZE=2000`，`PERFORMANCE_RUN` |
| `dhrystone.bin` | `nexus-am/apps/dhrystone` 重建 | **改了一个常量**：`NUMBER_OF_RUNS` 500000 → 1000 |
| `flash_recursion_test.bin` | `XiangShan/ready-to-run/` | 冒烟对照，慢 simv 上已有已知结果 |

> Dhrystone 为什么必须减次数：`dry.c:362` 只给 `__ARCH_RISCV64_XS_SOUTHLAKE*`
> 走「reduced for fast test」的 1000 次，`ARCH=riscv64-xs` 走 500000 次
> ≈ 1.7e8 条指令，RTL 仿真在任何速率下都跑不完。这里**只把那个常量改成仓库自己给
> 快测试准备的 1000**（`sim-fast/workloads-src/dhrystone/dry.c`，与上游逐行 diff 只有这一行），
> 不定义 `__ARCH_RISCV64_XS_SOUTHLAKE`（那个宏还会改 `xs.h`/`clint.c` 的内存映射，
> 等于换平台）。所以本轮的 Dhrystone 结论是**减次数的 Dhrystone 跑到终点**，
> 不是标准 500000 次。

## 结论（2026-09-14 快 simv 泳道）

**CoreMark 与 Dhrystone 两侧都跑到了终点（`HIT GOOD TRAP`），架构输出逐字节相同，
difftest 失配 0。** 这是本工程第一次把重写整芯片跑完真正的 benchmark。

| | CoreMark (2 iterations) | Dhrystone (1000 runs) |
|---|---|---|
| golden 结果 | `HIT GOOD TRAP at pc = 0x80001ca0` | `HIT GOOD TRAP at pc = 0x80000da4` |
| impl 结果 | **同上** | **同上** |
| instrCnt | 663,692 / **663,692** | 429,370 / **429,370** |
| cycleCnt | 320,376 / **320,376** | 147,946 / **147,946** |
| IPC（difftest 口径） | 2.071603 / **2.071603** | 2.902208 / **2.902208** |
| `DIFFTEST WORKLOAD DONE at cycle` | 320,383 / **320,383** | 147,953 / **147,953** |
| difftest 失配 | **0 / 0** | **0 / 0** |
| `assert.log` | 0 字节 / 0 字节 | 0 字节 / 0 字节 |
| 归一化日志正文 | **22 行逐行相同** | **18 行逐行相同** |

CoreMark 的自校验 CRC 两侧完全一致（这是 CoreMark 自己的正确性判据）：

```
CoreMark Size    : 666        Total time (ms)  : 2542      Iterations : 2
seedcrc          : 0xe9f5
[0]crclist       : 0xe714     [0]crcmatrix : 0x1fd7
[0]crcstate      : 0x8e3a     [0]crcfinal  : 0x72be
CoreMark Iterations/Sec 786
```

Dhrystone 同样两侧一致：`Dhrystone PASS` / `19269680.000000 Dhrystones_Per_Second` /
`10967.375977 DMIPS` / `5.483688 DMIPS/MHZ`，以及负载自己从 CSR 读出的
`cycle 103790 inst 418220 ipc 4.029483`。

> 注意这些 `Total time (ms)` / `DMIPS` / `cycle/inst` 是**负载自己读 `mcycle`/`minstret`
> 架构 CSR** 算出来的，属于架构状态（difftest 也在比对的东西），
> **不是**被接成 `'0` 的 `LogPerfEndpoint` perfCnt。两侧一致这件事本身也是一条架构级证据。

冒烟对照（`flash_recursion_test`）：快 simv 给出与慢 simv **完全相同**的
`HIT GOOD TRAP @0xe / instrCnt 289 / cycleCnt 4,642 / DONE at 4649`
—— 证明去掉 `-debug_access+all` 没有改变行为。

## 加速比实测

**这是仿真器吞吐，不是 RTL 内部 perf 计数器**（impl 侧 769 条 perfCnt XMR 接了 `'0`，
按 codex 0160 的要求不拿它当性能证据）。

标定用的是与慢 simv 完全同一条件：同一负载 `coremark-2-iteration.bin`、
同一 `+max-cycles=100000`、同样两侧并行两个进程。

| 负载 / 条件 | 侧 | cycles | 快 CPU(s) | 快 cycle/s | 慢 CPU(s) | 慢 cycle/s | **加速** |
|---|---|---|---|---|---|---|---|
| coremark `+max-cycles=100000`（标定，2 进程） | golden | 100,000 | 1125.15 | 88.9 | 2272.75 | 44.0 | **2.02x** |
| 同上 | impl | 100,000 | 857.41 | 116.6 | 2328.72 | 42.9 | **2.72x** |
| flash_recursion（短跑，启动开销占大头） | golden | 4,642 | 12.19 | 380.8 | 20.82 | 223.0 | 1.71x |
| 同上 | impl | 4,642 | 8.47 | 548.1 | 21.00 | 221.0 | 2.48x |
| coremark 跑到终点（4 进程并发） | golden | 320,376 | 3354.85 | 95.5 | — | — | — |
| 同上 | impl | 320,376 | 2558.44 | 125.2 | — | — | — |
| dhrystone 跑到终点（4 进程并发） | golden | 147,946 | 1747.49 | 84.7 | — | — | — |
| 同上 | impl | 147,946 | 1261.45 | 117.3 | — | — | — |

墙钟：两侧并行编译 17.7 min（21:43:20 → 22:01:00）；coremark 两侧并行 3415 s；
dhrystone 两侧并行 1795 s。

两个观察，如实记：

* **只有 ~2x，不是数量级。** `-debug_access+all` 是这条流程里唯一的 debug 开关
  （没有 verdi PLI 可去），去掉它就到头了。再想快只能动 VCS 的优化档
  （`+rad` 等，需另外的 license 且要重新验一遍行为），本轮**没做**。
* **impl 比 golden 快 ~30%**（857 vs 1125 s）。原因是 impl 的 SimTop 把 9897 条
  perfCnt XMR 接成了 `'0`，VCS 因此可以把大量跨模块观测优化掉。
  慢 simv 上两侧几乎一样快（2272 vs 2328 s），是因为 `-debug_access+all`
  本来就禁掉了这类优化。**所以这个 30% 不是「重写件更快」，是补丁的副作用。**

## 顺带修正一条 memory

`golden-coremark-difftest.md` 记的「coremark HIT GOOD TRAP 在 cycle 6492」**是错的**。
实测 `coremark-2-iteration.bin` 走到 `HIT GOOD TRAP` 需要 **320,376 cycle /
663,692 条指令**，`DIFFTEST WORKLOAD DONE at cycle 320383`。
（6492 那个数更像是某个小负载的数字被记串了。上一轮 README 已经对它存疑，这里给出实测值。）

## 本轮没做到的（如实）

1. **Dhrystone 是减次数版（1000 runs，不是上游默认的 500000）。** 理由见上（500000 次
   ≈ 1.7e8 条指令，任何速率下都跑不完）。标准次数的 Dhrystone **没跑**。
2. **microbench / linux 没跑。** 只跑了 coremark + dhrystone + flash_recursion。
3. **加速比只有 2.0~2.7x**，没有尝试 `+rad` 等更激进的 VCS 优化档。
4. **快 simv 没有波形能力。** 真撞上失配要回 `sim-work` 的慢 simv 复现。
   本轮没撞上，所以这条没被真正考验过。
5. **impl 侧 perf 计数器仍然全灭**（9897 条 XMR 接 `'0`）—— 归 perf 重绑泳道。
   本轮给出的一切性能数字要么是仿真器吞吐，要么是负载自己读架构 CSR 得到的，
   都不是 RTL perf 计数器。
6. `rtl/uncore/SubDirectory{,_1}.sv` 的 `` `timescale 1ns/1ps `` 仍在（归 collateral 泳道）：
   症状是 impl 侧 `$finish at simulation time` 是 ps、golden 是 ns。
   cycleCnt 两侧相同，说明它没影响架构行为，但编译期时间精度差异还在。
7. 单核、KunminghuV2Config、M 模式裸程序；没测中断/PLIC/多核/一致性长跑。

## 证据落盘（`verif/sim/results/`，`evidence/` 被 .gitignore 忽略所以换了目录名）

| 文件 | 内容 |
|---|---|
| `fastsim_bench_results.tsv` | 两侧 x 4 负载的 trap/instrCnt/cycleCnt/IPC/失配数/assert 字节/CPU 时间/cycle-per-sec/加速比 |
| `coremark_{golden,impl}.log` | CoreMark 跑完的完整 sim.log（去 ANSI） |
| `dhrystone_{golden,impl}.log` | Dhrystone 跑完的完整 sim.log |
| `flashrec_{golden,impl}.log` | 冒烟对照 |
| `vcs_flag_diff.txt` | 慢/快 simv 的 vcs 命令行差分（**只有两行**） |
| `difftest_vcs.mk.patch.txt` | difftest 副本的 vcs.mk 补丁 |
| `difftest_top.v.patch.txt` | difftest 副本的 top.v 补丁（去 VPD 系统任务） |
| `dhrystone_dry.c.patch.txt` | dhrystone 负载的唯一改动（`NUMBER_OF_RUNS` 500000→1000） |

复跑：

```bash
verif/sim/run_fastsim.sh build golden
verif/sim/run_fastsim.sh build impl
verif/sim/run_fastsim.sh bench /home/eda/xs-env/sim-fast/workloads/coremark-2-iteration.bin coremark 50000000
verif/sim/run_fastsim.sh bench /home/eda/xs-env/sim-fast/workloads/dhrystone.bin           dhrystone 50000000
```
