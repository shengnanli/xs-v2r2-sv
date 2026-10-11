# memblock-asm lane（agent/memblock-asm）—— 跑前登记

本文件在 **FM official 起跑之前**提交各节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `20df9ac22`（main），工作树 `/home/eda/xs-env/wt-memblock-asm`，分支 `agent/memblock-asm` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/MemBlock.sv`（57,550 行 / 2,450 端口 / 72 实例 / 50 种 design / 本层 388 个寄存器） |
| 目标 | `MemBlock`（本体）；子证书重证见 §3 |
| 口径 | codex 0226 先例的 exact green_child：72 个直接实例全部两侧 `-interface_only`，`FM_MERGE_DUP=false`，`FM_MODE=assembly`，无 dont_verify |

冲突检查（2026-10-10）：codex outbox 最新 0226（Frontend）与 0002（课程），均不涉及 MemBlock 及其直接 child；全部 worktree 的
`docs/lanes/*_claim.md` 中 MemBlock 只出现在本 lane 认领与已放弃的 kimi-memblock 试验（39 行占位，未动）。

## 1. 重写件

- `rtl/memblock/MemBlock.sv`：
  * `xs_MemBlock_core`（手写）十五节：§1 重定向 / CSR 预取开关 / L2 hint 打拍；§2 sfence / TLB CSR 打两拍；§3 DTLB 回填
    （PTW 回应打拍广播、能被这条回应满足的缺失请求不再发 PTW、load 重放提示）；§4 访存触发器；§5 load 口 0 三方共享
    （segment 独占 DCache 口 0 / DTLB 口 0，原子指令借 DTLB 口 0）；§6 原子指令（发射分流、状态机、慢反馈）；§7 store 数据；
    §8 写回仲裁；§9 向量发射分流与打拍级冲刷；§10 Sbuffer；§11 Uncache 状态机；§12 违例回滚最老选择；§13 硬件预取；
    §14 例外地址（GenExceptionVa）；§15 顶层旁路。golden 本层 388 个寄存器逐个对应（复位域照抄 golden）。
  * `memblock_top_pkg` 与 `MemBlock` wrapper：`scripts/gen_memblock.py` 生成（`--check` 幂等，fail-closed：端口逐位同序、
    72 实例模块名 / 实例名照搬、每个子模块输入的 golden 表达式必须落进已知形状、PAIR_DESC 167 对说明、TOP_GROUPS 归组）。
    15 个"字段束"（写回包等宽总线）在 wrapper 里按字段拼装，核里整束选择；源缺字段的常量填充见生成器 FILLS 表。
- 代码区 `_GEN_` / `_T_` = 0；`python3 scripts/readability_audit.py` A~G 全 0。

## 2. UT（verif/ut/MemBlock）

双例化 golden `MemBlock` vs 派生 `MemBlock_xs`，**两侧 72 个子模块是同一份 golden 定义**（golden 子树 292 个文件，ClockGate
用本地件）——只比本层胶合与 wrapper 连线，与 FM 的 green_child 组合同构（取舍理由写在 Makefile 头）。逐拍 4 态比全部 1,431 个输出。
四相激励（M 态不翻译 / S 态 Sv39 / 全随机 / 原子·segment·重定向密集），每 1000 拍一次两拍复位脉冲（让卡住的原子 / segment
状态复位）。初值只跑 `+vcs+initreg+0` / `+1` 两个常量档（双例化下 random 会让两侧子模块各摇各的）。
覆盖闸 9 道（原子执行中 / 原子写回 / segment 独占 / PTW 回应打拍 / 违例回滚 / Uncache 忙 / load 口 1 非对齐写回 / 向量写回 /
例外挂起）+ 翻转闸 950/1431。复跑：`cd verif/ut/MemBlock && make run SEED=<1|7|42> INITREG=<0|1>`。
结果见文末对账（UT 在 commit e00faf266 的 RTL 字节上跑）。

调试中修掉的一个真问题（UT 首轮 errors≠0）：§9 的冲刷判定函数原先在函数体里直接读模块级的 io_redirect_*，连续赋值只对实参
敏感，仿真漏更新（FM 视为组合逻辑不受影响）；改为纯函数（重定向作实参）。另两处字段束常量填充（原子单元慢反馈 hit 恒 1、
nuke 回滚 level 恒 1）由 UT 首轮抓到后补进 FILLS。

## 3. 子证书（50 种直接子模块）

`fm_verdict._cert_ctx` + `_child_cert_current`（= `batch_reproof.py validate`）在本 lane HEAD 上逐个复核。基线时 50 个里
**0 个**有 tracked 证书：43 个最新合格 receipt 因 `scripts/fm_eq.tcl` 等脚本闭包变更或 RTL 闭包变更而陈旧，7 个 receipt 仍 current。
处置：
- 43 个陈旧的（除 L2TLBWrapper）在 `PROOF_COMMIT=20df9ac22` 上重证（`batch_reproof.py`，evidence/20df9ac22c5f/），全部 SUCCEEDED，
  verdict 与各自上一份合格 receipt 相同；fm_predict check 的 ★ATTENTION★ 全部是「该 target 从未登记预测文件」或模型上界
  （TLBuffer_* 的 ram 白盒未计入）——不是证明结果变化；
- TLBNonBlock 家族 impl 侧挂的 golden 子件 9 个（DelayN_7/9、TLBFA/_1/_2/_3、TlbStorageWrapper_1/2/3）同批重证；
- 7 个 receipt current 的直接出证（HPerfMonitor_3、L1Prefetcher、NewPipelineConnectPipe_34/35、PFEvent、Pipeline）+
  DCacheWrapper / Sbuffer 挂的 golden 子件 7 个（Arbiter8_MainPipeReq、ProbeEntry、WritebackEntry、WritebackEntry_15、
  StorePfWrapper、Serializer 及 L2TLB 链上可直接出证的 3 个）。
- UncoreTLQueues：FM impl 侧改为逐 variant 只读自己那份 ram（cb251a56a），TLBuffer_6..9 依赖的 10 个 Queue2 variant 在其上重证。

HEAD c6522c6a3 复核（`python3 /home/eda/xs-env/tools/batch_reproof.py validate`）：**45/50 current-valid**；不过的 5 个与原因：

| child | 原因（validate 原文） | 出路 |
|---|---|---|
| TLBuffer_7 | `impl_golden_not_fm_target:Queue2_TLBundleA_7:ram_2x406`（另 B/C/D_8/E 的 ram_2x309/373/284、ram_sink_2x10） | 集成者往 `verif/mc_memory_registry.tsv` 登记这些 ram（本 lane 不改公共登记表），然后从现有 evidence 重出 Queue2 证书 |
| TLBuffer_9 | `impl_golden_not_fm_target:Queue2_TLBundleA_15:ram_2x116`（TLBuffer_9 自己也直接挂 ram_2x116） | 同上 |
| FrontendBridge | `impl_golden_not_fm_target:FrontendBridge:ram_2x359` | 同上 |
| SMSPrefetcher | `impl_golden_not_fm_target:SMSPrefetcher:sram_array_1p32x148m74s1h0l1b_pftch_pht`（及 array_12 / 叶子 array_12_ext） | 同上（叶子按 MC_MEMORY_BLACKBOX） |
| L2TLBWrapper | 无证书：整棵 L2TLB 子树两侧白盒（40+ golden 件，其中 PtwCache 读 array_10_ext.v、SRAMTemplate_128 挂未登记的 array_10、Queue40 的 ram_16x137 not_shared…），且 `FM_INTERFACE_ONLY = ram_40x47` 与 POLICY「interface_only 恰为 green_child 集合」冲突 | 需裁定 ram_40x47 的处置，并把 L2TLB / L2TLBWrapper 改成嵌套 green_child（或其它裁定） |

拟登记的 MC 行（`mc_memory_registry.py --derive` 原样输出，class 与用途列待集成者定）：ram_2x116 / ram_2x284 / ram_2x309 /
ram_2x359 / ram_2x373 / ram_2x406 / ram_sink_2x10（1R1W firtool ram，同已登记的 ram_2x76 一类）、
sram_array_1p32x148m74s1h0l1b_pftch_pht / array_12 / array_12_ext（SMS PHT）、array_10 / sram_array_1p4x786m131s1h0l1b_ptw_l1 /
array_10_ext（L2TLB）、ram_40x47（L2TlbMissQueue）。

## 4. FM

- `verif/allow/MemBlock.json`：144 条 green_child（72 实例 × r/i），逐实例路径 + child_target + 证书 sha256（`--stamp-allow` 回填）。
- `FM_INTERFACE_ONLY` = 50 个 design（恰为 allow 的 green design 集合）。ref 读 50 个 golden child 文件（只取端口），impl 读 50 个
  重写 wrapper 及其 package 文件。
- 钉点 `verif/ut/MemBlock/fm_pins_pre.tcl`：只有本层 388 个寄存器 / 4,072 位 → u_core（gen_memblock.py 生成，字面计数）。
  没有 child 内部配对，没有诊断 matched.rpt 收割，没有 many-to-many。
- vmucp：`verif/fm_target_config/MemBlock.tcl`（7 位对称死位，六条证据见文件）。

### 4.1 canary（工作树、不产 receipt）

| 跑 | 字节 | vmucp | native | passing | failing | unmatched | unread | constant_reg | 黑盒 |
|---|---|---|---|---|---|---|---|---|---|
| canary1 | e00faf266 | 关 | SUCCEEDED | 187001 | 0 | 0(0) | 7（matched_nc） | 10 | 72 实例 × r/i |
| canary2 | e00faf266 + vmucp 配置 | 开 | SUCCEEDED | **187008** | 0 | 0(0) | 0 | 10 | 同上 |

canary1 的 fm_verdict：PARTIAL（`assembly_green_child_certificate_not_in_commit:DCacheWrapper`——当时证书尚未提交）。
钉点 4072/4072 全部被接受（MB_CORE_PIN_END ok=4072 bad=0）。canary2 用时 1855 s；fm_verdict PARTIAL（`certificate_not_in_commit:L2TLBWrapper`）。

### 4.2 预测（docs/fm_predictions/MemBlock.json，模型 187018 = 寄存器 4072 + 输出 23708 + 黑盒输入 159238）

native SUCCEEDED；passing **187008**、constant_reg **10**、failing / unverified / aborted / unmatched / unread / blackbox_out **0**；
dont_verify / elab147 / relaxed_appvars 空。187018 − 187008 = 10 = constant_reg。
**verdict 预测 PARTIAL**：§3 表里 5 个 child 证书在父 commit 上不 current（首个按 allow 顺序报出，预计 `L2TLBWrapper` 无证书）。
