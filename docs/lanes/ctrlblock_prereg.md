# CtrlBlock lane（agent/ctrlblock）—— 跑前登记

本文件在 **FM 起跑之前**提交。跑完在文件末尾追加「对账」一节，★不修改本节任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `main` @ `d987e601`（PipeGroupConnect signoff-strict SUCCEEDED） |
| 工作树 | `/home/eda/xs-env/wt-ctrlblock`，分支 `agent/ctrlblock` |
| 目标 | `CtrlBlock`（golden 57,635 行 / 8288 端口 / 22 个 child 实例 / 16 类 child；闭包 83 个模块 633,268 行） |
| 实现 | `rtl/backend/CtrlBlock.sv`（单文件：ctrlblock_pkg → xs_CtrlBlock_core → wrapper CtrlBlock，38,306 行，其中 wrapper 的端口表/连线/WB_LANE 表由 `scripts/gen_ctrlblock.py` 生成） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读，`G1-a4ea14f2…`） |
| 证明模式 | assembly；`FM_MERGE_DUP=false`（加强）；`FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`（加强，依据 `verif/fm_target_config/CtrlBlock.tcl`） |
| 钉点 | `verif/ut/CtrlBlock/fm_pins_pre.tcl`（glue 2022 寄存器 / 25852 位，匹配前双射）+ `fm_pins.tcl`（Rob 168720 位，`verif/ut/Rob/fm_pins.tcl` 下移一层），都由 `scripts/gen_ctrlblock_pins.py` 生成 |
| 边界声明 | `verif/allow/CtrlBlock.json`（12 个 green_child 实例★不填 certificate_sha256★ + 8 个 APPROVED_MEMORY_MACRO_MODEL 候选实例） |

## 1. 边界（决定预测的事实）

| child | 实例 | 处置 | 依据 |
|---|---|---|---|
| Rob | rob | **两侧白盒**（ref golden Rob.sv 266,227 行；impl rtl/backend/Rob.sv 重写件） | codex 0169 D3 验收口径第 3 条：CtrlBlock 是 448 位 `debug_otherPdest` 悬空输出的第一个可观测边界，golden 把 56 个输出接成 unused |
| RenameBuffer / VTypeBuffer / SnapshotGenerator_3 / ExceptionGen / NewRobDeqPtrWrapper / RobEnqPtrWrapper / CommitStuckCounter | rob/* | 两侧同源 golden 白盒 | Rob 的 child，UNCHANGED_GOLDEN_DEP |
| dt_pcTransType_160x2 | rob/dt_pcTransType_ext | 两侧接口黑盒（APPROVED_MEMORY_MACRO_MODEL 候选） | 深度 160，inline 触发 FMR_ELAB-147 → set_top 失败（本 lane 实测） |
| DecodeStage / FusionDecoder / Rename / RenameTableWrapper / RedirectGenerator / Trace / MemCtrl / GPAMem / NewDispatch | decode / fusionDecoder / rename / rat / redirectGen / trace / memCtrl / gpaMem / dispatch | 两侧同源 golden 白盒（含各自闭包） | 仍由 agent/cb-decode、agent/cb-rename、agent/newdispatch3 重写中；UNCHANGED_GOLDEN_DEP，合入 main 后按 STALE 规则重跑 |
| diff_rat_state_bank_320x776 ×6 / stateBankTags_320x3 | rat/diffRatBuffer/* | 两侧接口黑盒（APPROVED_MEMORY_MACRO_MODEL 候选） | 深度 320，同上（diff_rat_state_bank 单模块 elaborate 300 s 超时） |
| SyncDataModuleTemplate_BackendPC_64entry / SnapshotGenerator_14 / DelayN_15 ×2 / DelayN_17 / PipelineConnectPipe ×6 / PipeGroupConnect | pcMem / snpt / s5_* / io_toTop_cpuHalt_delay / decodePipeRenameModule* / renamePipeDispatch | 两侧接口黑盒，allow 记 green_child | 已签核绿；证书 freeze 时铸；只能记「在 CtrlBlock 上下文中已被覆盖」 |

## 2. 预测（★跑完不许改本节★）

`python3 scripts/fm_predict.py model CtrlBlock`（`docs/fm_predictions/CtrlBlock.json`；模型 = 白盒闭包寄存器位 + 顶层输出位 + 黑盒输入引脚位；merge_dup=false 故模型适用）：

| 项 | 值 |
|---|---|
| 白盒闭包寄存器位 | 254,008 |
| 顶层输出端口位 | 57,119 |
| 黑盒输入引脚位（20 个实例） | 12,437 |
| **模型 passing（上界）** | **323,564** |
| failing / unverified / aborted | 0 / 0 / 0 |
| unmatched（ref / impl） | 0 / 0 |
| unread（vmucp 开启后） | 0 |
| 黑盒对象 | 40（20 实例 × 两侧），与 allow 精确相等 |
| native | SUCCEEDED |
| validator | PARTIAL，理由 `assembly_green_child_*`（12 个 green_child 实例无证书）——这是**预期的条件绿终态**，不是失败 |

可指认的差额（passing 低于模型的部分，必须逐位对得上）：
1. **−448**：golden Rob 的 `robDeqGroup_*_debug_otherPdest_*` 56 个寄存器 / 448 位在 golden 里无驱动，两侧都不是比较点（Rob 自比基线实测，`evidence/rob-selfcompare-4aa8838b/`）；impl 重写件把它们钉成常量 0。★receipt 的 constant_reg 不会记它们★。
2. **constant_reg**（receipt 直读，golden 侧 D 端恒 0 / hold-clear 的寄存器）：enqRob 六路的 debugInfo 六个时间戳（6×6×64=2304）与 lqIdx/sqIdx（6×13=78）装的是常量 0（Q5）；lane1..5 的 snapshot（5）与六路 replayInst（6）是 `~valid & q`；写回口 `pdest` 寄存器第 7 位（13 路，输入只 7 位）；decodeBuf 与 enqRob 里 impl 侧按掩码恒 0 的异常位只在 impl 侧且同为常量，不产生比较点。两侧同判、SUCCEEDED 不受影响；**差额必须逐位等于 constant_reg**。
3. 除此之外任何差额都算失配，不找第二个解释去圆。

### ★反向出口★

- unmatched 落在 `u_core/g_wb[...]`：WB_LANE 描述表与 golden 逐路寄存器集合有出入 → 照实报、修表（生成器 fail-closed 的判据漏了什么）。
- `CB_PIN_END … miss≠0` 或 `ROB_PINS_FAIL`：钉点名字与 Formality 实际点名不符，证明中止（fail-closed），先修名字再跑。
- failing > 0 且集中在 `decodeBuf*` / `flushVecNext` / `ftqIdxAhead`：与上一轮 xs-signoff 的 4 个 failing 簇同形，逐点诊断（`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，诊断日志不出 receipt）。
- Rob 白盒展开后 match/verify 超过 3 小时仍未结束：按 30 分钟采样，减速即停、取 `report_unmatched_points` 诊断，不硬等。

## 3. UT 证据（跑前）

`cd verif/ut/CtrlBlock && make compile && make run SEED=<s> INITREG=+vcs+initreg+<0|1>`（tb 读 +ncycles，ut_common 下发 200000）。
双例化 CtrlBlock（golden）vs CtrlBlock_xs（重写，含 Rob/pcMem/DelayN/PCP/PGC 重写件），6729 个输出逐拍比对，golden 侧 X 跳过。
3000 拍冒烟（seed 1，initreg+0）：checks=20,180,271 errors=0，distinct_diverging_ports=0/6729。
3 seed × 2 档（+0/+1）× 200k 拍：在对账节补记。

## 4. 对账：第 1 轮官方证明（commit ebf657d2，evidence/ebf657d20722/CtrlBlock，未入库）

`bash scripts/run_proof.sh CtrlBlock CtrlBlock < /dev/null`，端到端 9.69 h（match 至 14:37，verify 14:37→17:05 匀速，未触发 3 h 减速停）。

| 项 | 预测 | 实测 | 判 |
|---|---|---|---|
| native | SUCCEEDED | SUCCEEDED | ✔ |
| passing | ≤ 323,564 | 315,865 | 见下 |
| failing / unverified / aborted | 0/0/0 | 0/0/0 | ✔ |
| unmatched ref/impl | 0/0 | 0/0 | ✔ |
| unread | 0 | **130**（ref 16 + impl 114） | ✘ 预测漏了 |
| 黑盒对象 | 40 | 40（20 对，与 allow 精确相等） | ✔ |
| dont_verify / elab147 / 放宽 appvar | 无 | 无 | ✔ |
| validator | PARTIAL(assembly_green_child_*) | PARTIAL `assembly_green_child_certificate_not_in_commit:SyncDataModuleTemplate_BackendPC_64entry`；make_receipt 同因拒绝出 receipt（MAKE_RC=2） | ✔（条件绿终态） |

passing 差额 323,564 − 315,865 = **7,699 = 448 + 7,235 + 16**：
1. −448：golden Rob `debug_otherPdest` 悬空，与预测一致；
2. −7,235：receipt 口径的 constant_reg（fm.log "Not Compared / Constant reg 7235"），与预测的类别一致（本轮未出 receipt，数字取自 fm.log 汇总表）；
3. **−16：预测里没有**。golden Rob.sv 的 `walkCycle` / `waitRabWalkCycle`（2×8 位 perf 探针计数器）只写自身，唯一外部读者是 SimTop 的 perf XMR bore，在 CtrlBlock 边界是 golden-only cone-dead；重写件没有这两个寄存器 ⇒ ref 侧 unmatched-unread，不是比较点。模型把它们算进了 golden 寄存器位。处置：`verif/dead_ref/CtrlBlock.json`（declare_dead_ref.py 由本轮观测生成，commit 1ba708b8）。

unread impl 114 = decodeBuf 6×{异常位 3,22} + enqRob 6×(ENQ_EXC_KEEP 之外 17 位)：第 6 步"无条件写 0"没让它们消失，FM 仍点名为寄存器。处置：commit 78e1a775 把这两组寄存器拆成「体 + 保留异常位逐位 generate」，golden 没有的位在 impl 里也不再有寄存器。

## 5. 第 2 轮登记（合入 main 231b615d 之后，起跑前提交；★跑完不许改本节★）

边界变化（其余同第 1 节）：

| child | 实例 | 第 1 轮 | 第 2 轮 |
|---|---|---|---|
| SyncDataModuleTemplate_BackendPC_64entry | pcMem | green_child 接口黑盒 | 两侧白盒（ref golden + DataModule_BackendPC_16entry；impl rtl/common 重写件） |
| DelayN_15 ×2 / DelayN_17 | s5_* / io_toTop_cpuHalt_delay | green_child 接口黑盒 | 两侧白盒（impl 重写件） |
| PipelineConnectPipe ×6 | decodePipeRenameModule* | green_child 接口黑盒 | 两侧白盒（impl 重写件；payload 617 位/实例按 PCP 签核用的字段映射匹配前钉点，共 3,702） |
| PipeGroupConnect | renamePipeDispatch | green_child 接口黑盒 | 两侧白盒（impl 重写件） |
| SnapshotGenerator_14 | snpt | green_child 接口黑盒 | 两侧同源 golden 白盒（重写件撞名，UT 一直用 golden 体） |
| 3 个存储叶子（8 实例） | rob/dt_pcTransType_ext、rat/diffRatBuffer/* | 接口黑盒 | 不变；diff_rat_state_bank_320x776 / stateBankTags_320x3 已在 main 入表，**dt_pcTransType_160x2 仍未入表** |

理由：D57 证书要求 `certificate.impl_commit == POLICY.freeze_commit`，而 `verif/proof_certificates/POLICY.json` 的 freeze_commit 仍是 null ⇒ green_child 在任何 commit 上都过不了 validator，make_receipt 也拒绝出 receipt（第 1 轮实测）。白盒展开是收窄黑盒，不是放宽。

预测（`python3 scripts/fm_predict.py model CtrlBlock`，docs/fm_predictions/CtrlBlock.json）：

| 项 | 值 |
|---|---|
| 白盒闭包寄存器位 | 266,268 |
| 顶层输出端口位 | 57,119 |
| 黑盒输入引脚位（8 个实例） | 5,035 |
| **模型 passing（上界）** | **328,422** |
| failing / unverified / aborted | 0 / 0 / 0 |
| unmatched（ref / impl） | 0 / 0 |
| unread | ref 16（恰为 verif/dead_ref/CtrlBlock.json 的 16 条）/ impl 0 |
| 黑盒对象 | 16（8 实例 × 两侧），与 allow 精确相等 |
| 钉点 | CB_PIN 25,852 miss 0；PCP_PIN 3,702 miss 0；Rob OE_PIN 168,720 miss 0 |
| native | SUCCEEDED |
| validator | PASS_DEAD_REF（assembly）；receipt 出得来 |

可指认差额：passing = 328,422 − 448 − 16 − constant_reg，**差额必须逐位等于 448 + 16 + receipt.constant_reg**；constant_reg ≥ 第 1 轮的 7,235（新展开的 child 内若有常量寄存器只会增加，增量须在 receipt 里逐位指认到这些 child）。其他任何差额都算失配。

反向出口（在第 2 节之外新增）：
- unmatched 落在 `decodePipeRenameModule*/`、`pcMem/`、`renamePipeDispatch/`、`s5_*`/`io_toTop_cpuHalt_delay`：重写件内部名在 CtrlBlock 上下文按名/签名对不上 → 照各自签核时的点名补钉点，不放宽。
- `PCP_PIN_END … miss≠0`：字段映射的 golden 点名与层次不符，证明中止，先修名字。
- 已知条件项（不是失配，照实报）：dt_pcTransType_160x2 的 APPROVED_MEMORY_MACRO_MODEL 类别未经 codex 入表；9 个 child 仍同源 golden。

## 6. 第 3 轮登记（起跑前提交；★跑完不许改本节★）

### 6.1 第 2 轮现场（e8c9b2fb，`/tmp/xsv2-proof-cGJP0H`，fm_shell_exec PID 54656，仍在 verify，结果另见第 7 节）

match 结束（08:16）即可读到的事实，已足以判定第 2 轮**不可能**出绿 receipt：

| 项 | 第 2 轮预测 | 第 2 轮 match 实测 |
|---|---|---|
| unmatched compare 点 | 0/0 | **12(12)**：全在 pcMem，ref `raddr_dup_2{,_1,_3}_reg[3:0]` ↔ impl `g_bank[{0,1,3}].raddr_dup_reg[2][3:0]` |
| unread | ref 16 / impl 0 | **ref 168 / impl 152**：16 条 Rob（已声明）+ 152 对 pcMem 读地址复制寄存器 |

根因：pcMem 改两侧白盒后，golden 4 bank × 15 口的读地址复制寄存器 `raddr_dup_P[_b]` 与出口选 bank 的
`raddr_dup / raddr_dup_15..28` 互为按位复制、签名相同，FM 签名匹配把 bank 配错/配不上。
★这是第 5 节反向出口「unmatched 落在 pcMem/ → 补钉点，不放宽」的情形★。修法：commit 365a5902
（`render_pcmem`，450 位匹配前一一钉死，fail-closed）。RTL 未改。

### 6.2 边界与模型

边界与第 5 节第 2 轮完全相同（pcMem 多了 450 位钉点，别无变化）。main 0cbe4f8c 合入（28ef638f）对证明闭包与证明链脚本零差异。
9 个 child 的重写件均已 PROVEN_DIRECT，但本轮仍两侧同源 golden（下移 9 套钉点/fixture 属下一步，见 Makefile 注释）。

模型改进（commit 见 git log，早于本登记）：`fm_passing_model` 判据 3——无驱动的 `reg` 不算触发器。全 golden 仅命中
Rob `debug_otherPdest` 56×8 = 448 位，正是第 1 轮差额里那 448；其余 155 份登记 recompute 不变。

| 项 | 值 |
|---|---|
| 白盒闭包寄存器位 | 265,820（= 266,268 − 448） |
| 顶层输出端口位 | 57,119 |
| 黑盒输入引脚位（8 实例） | 5,035 |
| **模型 passing（上界）** | **327,974** |
| failing / unverified / aborted | 0 / 0 / 0 |
| unmatched ref / impl | 0 / 0 |
| unread | ref 16（= verif/dead_ref/CtrlBlock.json 16 条）/ impl 0 |
| 黑盒对象 | 16，与 allow 精确相等 |
| 钉点 | CB_PIN 25,852、PCP_PIN 3,702、PCMEM_PIN 450、Rob 168,720，miss 全 0 |
| native / validator | SUCCEEDED / PASS_DEAD_REF，receipt 出得来 |

**passing 必须 = 327,974 − 16 − receipt.constant_reg**（`fm_predict.py check` 的 EXPLAINED 判据）；constant_reg ≥ 7,235，
超出第 1 轮的部分须能落到本轮新展开的 pcMem/DelayN/PCP/PGC 内。其他任何差额都算失配。

### 6.3 UT（本轮 RTL 与 e8c9b2fb 逐字节相同）

`derive_ut_impl.py` 重派生与 `verif/ut/CtrlBlock/ut_gen` diff 为空，simv 未重编；第 2 轮 UT 即本轮 UT：
3 seed × {`+vcs+initreg+0`, `+vcs+initreg+1`} × 200k 拍，每档 checks=1,345,793,271 errors=0。

`+vcs+initreg+random`（seed 7）与 `+vcs+initreg+7017` 两档**对双例化 UT 不适用**，实测对照：

| 3000 拍冒烟 seed 7 | golden vs 重写 | golden vs golden（对照，CtrlBlock_xs 只是 `CtrlBlock u(.*)` 壳） |
|---|---|---|
| `+vcs+initreg+0` | errors 0 | errors 0 |
| `+vcs+initreg+random` | 4,035,982 | 3,945,288 |
| `+vcs+initreg+7017` | 3,537,768 | 3,633,694 |

两个 golden 实例彼此都对不上 ⇒ 失配来自两实例各摇各的未复位存储初值（Rob/pcMem 等 payload），与重写无关；
这正是 ut_common.mk / 本 Makefile 注明「双例化只用 +0/+1 常量档」的原因。

## 7. 第 2 轮对账（e8c9b2fb，PID 54656 跑完，11.95 h；`evidence/e8c9b2fb4de8/CtrlBlock`，receipt sha256 ce477fab…cad96，未入库）

| 项 | 第 2 轮预测 | 实测 | 判 |
|---|---|---|---|
| native | SUCCEEDED | **FAILED** | ✘ |
| passing | 328,422 − 448 − 16 − constant_reg | 277,012 | 不可比（verify 在第 20 个失败点停下，unverified 47,518） |
| failing | 0 | **≥ 20（截断）**：全是 `redirectGen/io_memPredUpdate_stpc_r_reg[*]` | ✘ |
| unmatched | 0/0 | 12(12)（pcMem 读地址，见 §6.1） | ✘ |
| unread | ref 16 / impl 0 | ref 168 / impl 152 | ✘ |
| constant_reg | ≥ 7,235 | 3,244（verify 半途停，非完整规模） | — |

failing 根因：`stpc_r` 是 redirectGen 从 pcMem **读口 1 的数据**算出的 10 位哈希（golden RedirectGenerator.sv:807）。
pcMem 自己签核时存储体 3,200 位与写口复制寄存器是钉了的（`verif/ut/SyncDataModule/fm_pins_pre.tcl`），
第 2 轮搬进 CtrlBlock 时一位没搬，4 个 bank 结构相同的存储体只能靠签名匹配、bank 配错。★第 5 节反向出口「unmatched/失配落在 pcMem/
→ 照它签核时的点名补钉点」的情形★，不是 RTL 失配（UT 1.3G 次比较 errors=0；pcMem 独立签核 SUCCEEDED）。

## 8. 第 3 轮登记补充（起跑前提交，追加于第 6 节之后；★不改第 6 节★）

`render_pcmem` 在读地址 450 位之外补钉 **写口复制寄存器 4×(1+6+50)=228 位** 与 **存储体 4×16×50=3,200 位**，PCMEM_PIN 共 **3,878**（fail-closed：
golden 名/宽/驱动/喂给哪个 dataBanks_b 逐条核对）。点名先在 pcMem 独立 FM 上实测（scratchpad，diagnostic-full，钉同一份映射）：
PCMEM_PIN_END n=3878 miss=0，Verification SUCCEEDED，passing 4,448，unmatched 0/0。
第 6.2 节的预测数字不变（钉点不改变比较点集合）：passing = 327,974 − 16 − receipt.constant_reg，failing/unverified/unmatched 0，unread ref 16/impl 0。
