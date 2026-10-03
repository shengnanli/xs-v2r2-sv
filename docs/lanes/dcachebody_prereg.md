# DCache 本体 lane（agent/dcachebody）—— 跑前登记

本文件在 FM 正式起跑**之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | main `d5564588`（`git worktree add /home/eda/xs-env/wt-dcachebody -b agent/dcachebody main`） |
| 冲突检查 | codex outbox 最新 0205（next-20 叶子）/ 0204 / 0199（BankedDataArray 裁定）；codex/* 与 kimi/* 分支均未碰 DCache 及其子树 |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/DCache.sv`（23,854 行 / 627 端口 / 376 寄存器 1716 位，只读） |
| 目标 | `DCache`（assembly 口径：两侧白盒整棵子树，唯一黑盒是审定的厂商 SRAM 叶子） |
| Scala | `src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala` class DCacheImp |

## 1. 结构与子模块处置

- 可读核 `rtl/memblock/DCache.sv`：`dcache_pkg`（常量 / TileLink opcode / 树形 PLRU 两个函数）+
  `xs_DCache_core`（手写，按通道分节 §1 D 通道 / §2 B 通道 / §3 L2 提示 / §4 阵列口胶水 / §5 256×4 路 PLRU /
  §6 MainPipe 回应打拍 / §7 错误上报 / §8 预取统计 / §9 性能事件）+ golden 同名 wrapper。
- wrapper 的端口表、40 个子模块实例（实例名 / 端口顺序同 golden）、核例化、输出 assign 全部由
  `scripts/gen_dcache.py --check` 从 golden 机械生成；规则 fail-closed（每个子模块端口恰好命中一条：
  本层端口 / 子模块输出线 / `/* unused */` / GLUE_IN 表；GLUE_IN / GLUE_OUT 表逐字记 golden 表达式，漂了即失败）。
  `_GEN_`/`_T_` = 0。
- 寄存器全部 SoA（`plru_state[256]`、`perf_q1/q2[40]`、`err_src_*[4]`、`fwd_d_beat_cnt[3]`），
  1716 位与 golden 逐位一一对应（钉点见 §3）。
- 子模块（22 类 / 40 实例）：查 `docs/coverage_three_axis.tsv`，除 StorePipe / FDPrefetcherMonitor 外全部
  `PROVEN_DIRECT`；闭包里的 Arbiter8_MainPipeReq / ProbeEntry / WritebackEntry / WritebackEntry_15 是
  `GOLDEN_REUSE/PROVEN_IN_CONE`（两侧同一份 golden 文件）。处置 = **两侧白盒**：ref 读 golden 闭包 53 个文件
  （`FM_REF_DEPS_DCache`，字面文件名），impl 读重写件（`RTL_GOLDEN_DEPS`）。
- **StorePipe ×2 / FDPrefetcherMonitor**：golden 本配置下 0 输出、0 寄存器（StorePipe 是已知
  EXPLICITLY_UNPROVABLE 死码 stub，`docs/fm_predictions/StorePipe.json`；FDPrefetcherMonitor 已有端口壳重写
  + portlint）。两侧照 golden 例化、照 golden 接线，**不产生任何比较点**；没有为它们加黑盒、没有 dont_verify。
- **黑盒**：只有厂商 SRAM 叶子 `array_7_ext` ×32（BankedDataArray 内）与 `array_8_ext` ×8（DuplicatedTagArray 内），
  不进 FM 源（unresolved = 黑盒）。`verif/allow/DCache.json` 由生成器从两个子模块已审定的 allow 文件逐条收割、
  路径换到 `DCache/<实例名>/` 之下；按 codex 0199 只收子模块顶层之下的实例（辅助 design root 不收），
  字面计数每侧 32 + 8。

## 2. UT（verif/ut/DCache）

双例化 golden `DCache` vs `DCache_xs`，两侧例化同一份子模块重写件，只比本层；逐拍比全部 219 个输出口。
激励：30 行地址池（6 set × 5 tag，> 4 路 → 反复替换写回）、3 条 load 流水、store、原子（LR 加权）、CMO、
L2 模型（Acquire→GrantData/Grant/CBOAck，Release→ReleaseAck，偶发 Probe / denied / corrupt / 非法 opcode 噪声）、
CtrlUnit 伪 ECC 注入。胶水事件覆盖闸见 tb 末尾。
初值档：`0`（全设计 +vcs+initreg+0，全比）、`glue` / `glue017`（`+vcs+initreg+config`：子模块 0、两侧本层随机，
种子 = SEED / SEED017）。**不用全设计 `+vcs+initreg+random`**：子模块两侧同码、各摇各的初值（含 SRAM 阵列内容），
比出来的只是初值噪声（L2TLB lane 实测）；glue 档的本层随机已由 tb 的 `[INITREG]` 行自证（两侧不同、跨种子不同）。
结果见文末对账（跑完追加）。

## 3. FM 钉点（verif/ut/DCache/fm_pins_pre.tcl，gen_dcache.py 生成）

组成：本层胶水 1716（golden 寄存器表逐位、单射、位宽核对）+ parent_dead 1048（子模块内部在本层才变死的对称寄存器：
mainPipe status_dup 720 / missQueue vaddr 低位 85 + CMOUnit 地址高位 16 / probeQueue vaddr 低位 45 / accessArray 读口 idx 128 /
prefetchArray 读口 3 48 / bloomFilter 回应 6）+ 子模块签核时自己的钉点原样收割（cacheCtrlOpt 1040 / bankedDataArray 4683 /
mainPipe 16 / missQueue 4174），合计 12677；fail-closed 计数。bankedDataArray 的 32 条 respReg 钉点改配 impl respReg
（子模块签核时 merge_dup=true 把 respReg 并进了 rdata_last_REG；本目标 merge_dup=false，见 gen_dcache.py retarget_bda_resp）。
签核时无钉点文件的子模块逐个列在 `CHILD_NO_PINS`，生成器核对它们的 UT 目录里确实没有钉点文件。

## 4. 跑前预测（★跑完不许改本节★）

### 4.1 diagnostic 试跑记录（不出 receipt）
| 跑 | 设置 | matching | 结果 |
|---|---|---|---|
| D1 | merge_dup=false，vmucp 关，钉点 11629 | unmatched compare 0(60)，unmatched unread 1048(1038) | 未到 verify（定位用） |
| D2 | merge_dup=true，vmucp 开，钉点 12677 | unmatched 2(50) | FAILED：failing 49（golden 侧合并 r_miss/r_replay、mainPipe s1_req 等，impl 合不上） |
| D3 | merge_dup=false，vmucp 开，钉点 12677（BDA respReg 未改配） | unmatched 0(0)，unread 0(40) | FAILED：failing 2304 = 32×72 BDA rdataReg（使能 respReg 未配对）；passing 79782，constant_reg 411 |
D1 的 60 个 impl 未配对点：50 个 = 子模块在本层变死的寄存器（已由 parent_dead 钉点归零），10 个 = fdpMonitor 黑盒脚
（重写件原为空模块，FM 当黑盒；已照 golden 补三条无读者 PopCount，D2/D3 不再出现）。matching 用时约 50 分钟（无需降速诊断）。

### 4.2 正式 run_proof 预测（★跑完不许改本节★，登记 docs/fm_predictions/DCache.json）
| 项 | 预测 |
|---|---|
| passing | **82086**（= 模型 82495 − constant_reg 411 + 2；+2 是 FM 报 BBPin 3450 而模型 3448，未指认，照实登记） |
| failing / unverified / aborted | 0 / 0 / 0 |
| unmatched compare | 0(0) |
| unread | ref 0 / impl **40**（matched_nc 全部由 vmucp 真比较） |
| constant_reg | 411 |
| 黑盒 | array_7_ext ×32 + array_8_ext ×8（两侧），verif/allow/DCache.json |
| dont_verify / elab147 / relaxed appvar | 无 |
| verdict | native SUCCEEDED；**判定 PARTIAL**（impl 独有 unread 40，见 4.3） |

### 4.3 明写剩余阻塞（不在本 lane 权限内）
impl 独有 unread 40 = 共享核 `rtl/common/xs_SRAMTemplate_core.sv` 的 `g_nomcp.rdata_last_REG`：holdRead 关闭时它与 respReg
同方程、无读者、golden 无对应寄存器；BankedDataArray 内 32 个、DuplicatedTagArray 内 8 个。子模块签核时靠 merge_dup=true 合掉，
本目标必须 merge_dup=false（D2）。消除它要改共享核（holdRead 关时不生成该寄存器），会动 43 个 SRAM wrapper 的 impl 闭包、
牵动已签目标重签，需集成者裁定。本 lane 不改。

## 对账（跑完追加，不改上文任何数字）

### A. 正式 FM（proof commit 87e3cdf8，evidence/87e3cdf8490e/DCache/，receipt.json sha256 d2133bb9e6a7d8bc79f7db955d26f4509849152f8abc2a0ccf4386aa75497bc2）
assembly、vmucp 开、merge_dup=false：native **SUCCEEDED**，passing **82086**（= §4.2 预测，差 0），failing 0 / unverified 0 /
aborted 0 / unmatched 0(0)，constant_reg 411，dont_verify/elab147/relaxed appvar 皆空，钉点 DC_PREPIN_END n=12677。
判定 **PARTIAL**，两条原因（都不是 RTL 失配）：
1. impl 独有 unread 40 = 共享核 xs_SRAMTemplate_core 的 rdata_last_REG（§4.3，预测到）；
2. `assembly_bbox_set_mismatch: extra=4, observed_not_declared=i:/WORK/DCache/stu_0`：两侧的 StorePipe（stu_0 / stu_1）
   在 golden 与重写件里都是**空模块**（0 输出、0 寄存器），FM 自动把空模块当黑盒（black_boxes.rpt 属性 e），两侧各 2 个。
   **跑前没有预见到**。按任务要求不为 StorePipe 加黑盒声明；golden 侧不可改，这 4 个黑盒在任何 impl 写法下都存在，
   需集成者裁定是否允许一个「空模块（无输出）」类的 allow 对象。
`fm_predict check`：模型 82495 − 实测 82086 = 409；工具按 constant_reg 411 + unread 40 = 451 指认，余额 −42 判红。
实际构成：409 = 411（constant_reg）− 2（FM BBPin 3450 比模型 3448 多 2，未指认）；unread 40 是 impl 独有寄存器，
不在 golden 模型里，不该进指认额 —— 工具口径与本目标不符，照实记录为红。

### B. UT（9/9，各 200k 拍）
seed 1/7/42 × {initreg 0, glue, glue017}：全部 checks=199977 errors=0 TEST PASSED cov_fail=0
（seed 1 档在 9f69ce34，seed 7/42 档在 1998a657；两者之间 rtl/memblock/DCache.sv 与 tb 未改，只有 FDPrefetcherMonitor 补无读者组合线）。
seed 1 / initreg 0 覆盖：D→MissQueue 41026、ReleaseAck 13489、非法 opcode 412、forward_D 两拍末拍 19190、probe 被挡 23977、
PLRU 同组多口 14276、原子回 LSU 1436、store replay 3592、release 14901、LR 保留集作废 40、四路错误各 3786..5933、
pf good/bad 1655/115、同拍预取标志 3、伪 ECC tag/data ready 158347/58008。
"原子回应只给 MissQueue" 0（MainPipe 的 atomic_resp 只在 AMO 来源拉高，结构上不可达）。

### C. 变异自检（seed 7 / initreg 0 / 30k 拍）
CAUGHT 6：M1 CBOAck 不归 MissQueue（32684）、M2 PLRU 折叠顺序反（1484493）、M3 错误优先级 ldu0 先（1129）、
M4 forward_D last 丢 isKeyword（36315）、M5 perf 只打一拍（208364）、M9 保留集作废丢 lrsc valid（10）。
SURVIVED 3：M6 probe 别名位取 address[13:12]（tb 的 L2 模型按构造让 data[2:1]=paddr[13:12]，UT 看不见；FM 逐点比较覆盖）；
M7 原子回应不查 source（非 AMO 来源结构上不可达，UT/FM 都等价——等价变异）；
M8 fdp useful_prefetch 门控改动（FDPrefetcherMonitor 0 输出，golden 同样无观察者：UT 与 FM 都不可观测）。
