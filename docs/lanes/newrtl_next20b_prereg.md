# agent/newrtl-next20b lane —— 预登记（prereg）：第三批 20 个可读叶目标

基线：xs-v2-sv `main` @ `2787eb13`（台账重算：合入 codex 20 数学叶、GrantBuffer）。
worktree：`/home/eda/xs-env/wt-newrtl-next20b`，分支 `agent/newrtl-next20b`。
本批为 newrtl-next20（`agent/newrtl-next20`，20/20 已签核完成）之后的第三批，
与其**零目标重叠**（该批 20 个名字列入排除集逐名核对）。
20 个目标全部来自冻结 G1 XSTop design universe（`in_universe=yes, new_target`；
`coverage_three_axis.tsv` 全部 `MISSING/UNPROVEN`）。

## 排除对账（机械）

- Kimi `k3next30_prereg.md` 全部 30 个目标：零重叠。
- 本 Agent 上一批 newrtl-next20 的 20 个目标：零重叠（显式列入排除集）。
- Claude 0193–0198 在途 lane、Codex 全部在途 lane worktree 的 docs/lanes/*.md：
  对 708 个 MISSING/UNPROVEN 模块名 `rg -wF` 全扫，命中者一律排除；
  本 20 个不在任何命中集中。
- `.agent-bridge/inbox+outbox` 全量历史消息同法全扫（含 G0 轮历史提及，从保守）：
  本 20 个零命中。
- 全部父模块（NewCSR、NCBDownstream{AW,AR,W}{,_1}、TLFragmenter{,_1}、
  TLWidthWidget_1）均 MISSING/UNPROVEN 且本轮无人认领；目标不是任何已重写
  模块的吸收子模块，无 hier 冲突。
- 文件隔离：每目标一个新 `rtl/<subsys>/<Module>.sv`；三个新 `verif/ut/<Family>/`；
  每族一个新 `scripts/gen_*.py`。不改共享核、gate_all、台账、fm_target_config
  中其他目标的条目。
- 依赖处置：20 个目标全部 0 子模块（已逐一用实例化关系扫描核实），无闭包问题。

## 精确目标清单（20，三族）

### 族 E —— CSR trap 原因/陷阱值寄存器（8），UT 目录 `CsrCauseTvalLeaves8`

| # | 模块 | golden 行数 | 子模块 | 解锁父 |
|---|---|---:|---|---|
| 1 | McauseModule | 144 | 无 | NewCSR |
| 2 | ScauseModule | 144 | 无 | NewCSR |
| 3 | VScauseModule | 144 | 无 | NewCSR |
| 4 | MncauseModule | 144 | 无 | NewCSR |
| 5 | MtvalModule | 132 | 无 | NewCSR |
| 6 | StvalModule | 132 | 无 | NewCSR |
| 7 | VStvalModule | 132 | 无 | NewCSR |
| 8 | Mtval2Module | 132 | 无 | NewCSR |

同构变体族（trap 时由 trap 口装载、软件口可写、中断位拼接）：一个参数化核 +
薄 wrapper，核体零复制。

### 族 F —— CSR trap 向量/返回地址寄存器（7），UT 目录 `CsrEpcTvecLeaves7`

| # | 模块 | golden 行数 | 子模块 | 解锁父 |
|---|---|---:|---|---|
| 9 | MepcModule | 132 | 无 | NewCSR |
| 10 | SepcModule | 132 | 无 | NewCSR |
| 11 | VSepcModule | 132 | 无 | NewCSR |
| 12 | MnepcModule | 132 | 无 | NewCSR |
| 13 | MtvecModule | 140 | 无 | NewCSR |
| 14 | StvecModule | 140 | 无 | NewCSR |
| 15 | VStvecModule | 140 | 无 | NewCSR |

同构变体族（epc 系列为 trap 口装载的 64 位寄存器；tvec 系列带 base/mode
WARL 低位处理）：参数化核 + 薄 wrapper。

### 族 G —— 总线缓冲叶（5），UT 目录 `BusBufferLeaves5`

| # | 模块 | golden 行数 | 子模块 | 解锁父 |
|---|---|---:|---|---|
| 16 | SpillRegister | 201 | 无 | NCBDownstreamAW / NCBDownstreamAR |
| 17 | SpillRegister_2 | 192 | 无 | NCBDownstreamW / NCBDownstreamW_1 |
| 18 | SpillRegister_6 | 210 | 无 | NCBDownstreamAW_1 / NCBDownstreamAR_1 |
| 19 | Repeater_1 | 217 | 无 | TLFragmenter / TLFragmenter_1 |
| 20 | Repeater_2 | 221 | 无 | TLWidthWidget_1 |

SpillRegister 三个是 skid buffer 变体；Repeater 两个是 TileLink 握手 repeat
变体。一族一核，变体薄 wrapper。

## 验收（逐目标，不达成不记完成）

- 生成器 ×3 确定性 + `--check` 幂等。
- `make portlint` 20/20 端口契约。
- golden 双例化差分 UT：6 seeds × ≥200,000 拍，errors=0，带 toggle/fire 覆盖闸。
- official detached-clean-worktree FM（`scripts/run_proof.sh`，signoff-strict）：
  20/20 native SUCCEEDED；failing/unverified/aborted/unread/unmatched/
  blackbox/dont_verify 全零。失配只改 RTL 重证，不 waiver、不降级、不扩黑盒；
  matched_nc/unmatched unread 死位按既有机制（位级依据白名单 + vmucp 加强）
  处置并写明复核判据。
- prereg / 实现 / evidence 分开提交；receipt 绑定 clean committed 字节；
  结束时工作树 clean。
- 目标一经登记不静默减少/替换；受阻目标保留为 BLOCKED 并如实报告最小反例与根因。
