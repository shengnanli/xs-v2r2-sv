# agent/newrtl-next20 lane —— 预登记（prereg）：20 个可读叶目标

基线：xs-v2-sv `main` @ `2787eb13`（台账重算：合入 codex 20 数学叶、GrantBuffer）。
worktree：`/home/eda/xs-env/wt-newrtl-next20`，分支 `agent/newrtl-next20`。
20 个目标全部来自冻结 G1 XSTop design universe（`docs/g1_configured_universe.tsv`
逐名核过 `in_universe=yes`；`docs/coverage_three_axis.tsv` 全部 `MISSING/UNPROVEN`，
即无同名重写件、无任何证书）。

## 排除对账（机械）

- Kimi `k3next30_prereg.md` 全部 30 个目标（SelBlock_v4/SpecBlock_v4/IterBlock_v4{,_4,_6}、
  I8DivNr4、ShiftLeftPriorityWithLZDResult_{6,8}、ShiftLeftPriorityWithF64EXPResult、
  FarPathAdderF16Pipeline、14 个 CSR 叶、Std/MemExeUnit/NCBOrderAddressCAM_1/IntBuffer/
  ClockCrossingReg_w64/PrefetchReceiver）：与本 20 个**零重叠**（逐名 `grep -wF` 核对）。
- Claude 0193–0198 在途认领（ctrlblock、datapath、lquncache2、iqfam、dcache、l2slice
  各 lane 的 docs/lanes/*.md）：与本 20 个零重叠。
- Codex 各在途 lane（csr35fmt、pmpaddr*、pmaaddr*、result7、rounding8、small3*、
  amoalu、arbiter5、arith*、compare6、csr10b/10c/15、leaves15/50、math20 等
  worktree 的 docs/lanes/*.md）：与本 20 个零重叠。
- `.agent-bridge/inbox+outbox` 全量历史消息：对 708 个 MISSING/UNPROVEN 模块名做
  `rg -wF` 全扫，凡在任何消息/任何 lane 文档中出现过的名字一律排除（含 G0 轮历史
  提及，从保守）；本 20 个均不在命中集中。
- 全部父模块（VFixPoint64b、ExeUnit_7/ExeUnit_9、VIPU、VIntFixpAlu64b、NewCSR、
  Pipeline_1/2/3/10/11、AXI4UserYanker_2）均 MISSING/UNPROVEN 且本轮无人认领 ——
  目标不是任何已重写模块的吸收子模块，无 hier 冲突。
- 文件隔离：每目标一个新 `rtl/<subsys>/<Module>.sv`；四个新 `verif/ut/<Family>/`；
  每族一个新 `scripts/gen_*.py`（确定性 + `--check` 幂等）。不改共享核、gate_all、
  台账、fm_target_config。
- 依赖处置：DivUnit 的 SRT16DividerDataModule、FDivSqrt 的 FloatDivider 未签核，
  UT 侧经 `RTL_GOLDEN_DEPS` 两侧共用同一份 golden 行为模型，FM 侧 ref/impl 同源自
  闭包（两侧白盒同源），不吸收、不改写。其余 18 个目标均为 0 子模块叶。

## 精确目标清单（20，四族）

### 族 A —— 算术/向量运算叶（5），UT 目录 `ArithVecLeaves5`

| # | 模块 | golden 行数 | golden 子模块 | 解锁父 |
|---|---|---:|---|---|
| 1 | Adder_chain_rnd | 191 | 无 | VFixPoint64b |
| 2 | DivUnit | 292 | SRT16DividerDataModule（两侧同源白盒） | ExeUnit_7 |
| 3 | FDivSqrt | 319 | FloatDivider（两侧同源白盒） | ExeUnit_9 |
| 4 | VIAluDecoder | 281 | 无 | VIPU |
| 5 | VIntAdder64b | 436 | 无 | VIntFixpAlu64b |

### 族 B —— CSR 控制/计数叶（5），UT 目录 `CsrCtlLeaves5`

| # | 模块 | golden 行数 | 子模块 | 解锁父 |
|---|---|---:|---|---|
| 6 | FcsrModule | 178 | 无 | NewCSR |
| 7 | DcsrModule | 262 | 无 | NewCSR |
| 8 | VcsrModule | 136 | 无 | NewCSR |
| 9 | McycleModule | 133 | 无 | NewCSR |
| 10 | MinstretModule | 134 | 无 | NewCSR |

### 族 C —— PMP cfg 变体族（5），UT 目录 `PmpcfgLeaves5`

| # | 模块 | golden 行数 | 子模块 | 解锁父 |
|---|---|---:|---|---|
| 11 | Pmp0cfgModule | 160 | 无 | NewCSR |
| 12 | Pmp1cfgModule | 160 | 无 | NewCSR |
| 13 | Pmp2cfgModule | 160 | 无 | NewCSR |
| 14 | Pmp3cfgModule | 160 | 无 | NewCSR |
| 15 | Pmp4cfgModule | 160 | 无 | NewCSR |

同族同构：一个参数化核 + 每变体薄 wrapper（按 CONVENTIONS 变体家族规范）。

### 族 D —— 深度 1 队列叶（5），UT 目录 `Depth1QueueLeaves5`

| # | 模块 | golden 行数 | 子模块 | 解锁父 |
|---|---|---:|---|---|
| 16 | Queue1_PrefetchReq | 161 | 无 | Pipeline_1（SMS 预取流水） |
| 17 | Queue1_PrefetchResp | 143 | 无 | Pipeline_3 |
| 18 | Queue1_PrefetchTrain | 167 | 无 | Pipeline_2 |
| 19 | Queue1_UInt32 | 134 | 无 | Pipeline_10 / Pipeline_11 |
| 20 | Queue1_BundleMap | 139 | 无 | AXI4UserYanker_2 |

同族同构：depth=1 的 valid/ready 寄存的队列，一个参数化核 + 薄 wrapper。

## 验收（逐目标，不达成不记完成）

- 生成器 ×4 确定性 + `--check` 幂等。
- `make portlint` 20/20 端口契约。
- golden 双例化差分 UT：6 个 seed，每 seed ≥200,000 拍/向量，errors=0；
  带 toggle/fire 覆盖闸，杜绝"DUT 没动也全绿"。
- official detached-clean-worktree FM（`scripts/run_proof.sh`，signoff-strict）：
  20/20 native SUCCEEDED；failing/unverified/aborted/unread/unmatched/
  blackbox/dont_verify 全零。失配只改 RTL 重证，不 waiver、不降级、不扩黑盒。
- prereg / 实现 / evidence 分开提交；receipt 绑定 clean committed 字节；
  结束时工作树 clean。
- 目标一经登记不静默减少/替换；受阻目标保留为 BLOCKED 并如实报告最小反例与根因。
