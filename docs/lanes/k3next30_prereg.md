# kimi/k3-next20 lane —— 第二批预登记（prereg）：30 个可读叶/闭包目标

基线：`kimi/k3-next20` @ 64847042（含本 lane 第一批 20 个 FPU 叶及其 evidence）。
30 个目标全部来自冻结 G1 XSTop design universe（`docs/g1_configured_universe.tsv`
逐名核过 `in_universe=yes, new_target`；`docs/coverage_three_axis.tsv` 全部
`MISSING/UNPROVEN`，即无同名重写件、无任何证书）。

## 排除对账（机械）

- 本 lane 第一批 20 个（r4_qds 系列、IntToFP 闭包、ShiftLeftPriorityWith{F32EXPResult,
  LZDResult}）：无重叠。
- codex_0204/0205 已完成未集成 20 个（AluResSel 等 result/control 7、RoundingUnit
  系列 8、Arbiter2/4 系列 5）：无重叠。
- Claude 0193–0198 在途认领（ctrlblock、datapath、lquncache2、iqfam、dcache、
  l2slice）：无重叠。
- 对 `.agent-bridge/outbox+inbox` 全部消息逐名 `grep -w`：仅 MemExeUnit、IntBuffer、
  PrefetchReceiver 三个名字命中 2026-07 的 G0 轮历史消息（codex_0074/0078、
  claude_0053/0071）。G0 轮 receipt/认领一律不继承（codex 0139 §2/§5），且均为
  已完成/已终结的历史轮次，非本轮 ACTIVE 认领 —— 判定可领。
- 全部父模块（SRT16Divint{,_4,_6}、VectorFloatDividerR64、FloatAdderWidenFormat、
  FarPathF16Pipeline、NewCSR、CSRPermitModule、MemExeUnit→MemBlock、NCB200_1、
  L2Top/XSTile/XSTop、AsyncQueueSink_3、Prefetcher）均 MISSING/UNPROVEN 且本轮
  无人认领 —— 目标不是任何已重写模块的吸收子模块，无 hier 冲突。
- 文件隔离：每目标一个新 `rtl/<subsys>/<Module>.sv`；四个新
  `verif/ut/<Family>/`；四个新 `scripts/gen_*.py`。不改共享核、gate_all、台账、
  fm_target_config（生成器幂等闸自动扫描，无需登记）。
- 依赖处置：SelBlock_v4/SpecBlock_v4 的 SignDec、IterBlock_v4* 的
  Conversion{,_8,_12} 与 CSA3_2_*、I8DivNr4 的 IterBlockI8Nr4 均已在 main/本
  分支签核，impl 侧直接例化同名 wrapper，ref 侧 golden 闭包（两侧白盒）。

## 精确目标清单（30，四族）

### 族 A —— SRT 整数除法闭包（6），UT 目录 `SRT16DivClosure6`

| # | 模块 | golden 行数 | golden 子模块（状态） | 解锁父 |
|---|---|---:|---|---|
| 1 | SelBlock_v4 | 190 | CSA3_2_3988(已签)、SignDec(已签) | SRT16Divint{,_4,_6} |
| 2 | SpecBlock_v4 | 500 | CSA3_2_3992(已签)、SignDec(已签) | 同上 |
| 3 | IterBlock_v4 | 459 | Conversion、CSA3_2_3987/4017（均已签）、SelBlock_v4、SpecBlock_v4 | 同上 |
| 4 | IterBlock_v4_4 | 459 | Conversion_8、CSA3_2_4017/4111（已签）、SelBlock_v4、SpecBlock_v4 | 同上 |
| 5 | IterBlock_v4_6 | 459 | Conversion_12、CSA3_2_4017/4173（已签）、SelBlock_v4、SpecBlock_v4 | 同上 |
| 6 | I8DivNr4 | 246 | IterBlockI8Nr4（本 lane 已签） | 自身即父级 |

### 族 B —— FP 规格化 shift-priority / far-path 叶（4），UT 目录 `FpnormLeaves4`

| # | 模块 | golden 行数 | 父 |
|---|---|---:|---|
| 7 | ShiftLeftPriorityWithLZDResult_6 | 158 | VectorFloatDividerR64 |
| 8 | ShiftLeftPriorityWithLZDResult_8 | 123 | VectorFloatDividerR64 |
| 9 | ShiftLeftPriorityWithF64EXPResult | 155 | FloatAdderWidenFormat |
| 10 | FarPathAdderF16Pipeline | 124（含时序寄存器） | FarPathF16Pipeline |

### 族 C —— CSR 寄存器叶（14），UT 目录 `CsrLeaves14`

| # | 模块 | # | 模块 |
|---|---|---|---|
| 11 | cycleModule | 18 | VSscratchModule |
| 12 | instretModule | 19 | MnscratchModule |
| 13 | HipModule | 20 | Dscratch0Module |
| 14 | HieModule | 21 | Dscratch1Module |
| 15 | HgeieModule | 22 | ScontextModule |
| 16 | MscratchModule | 23 | TselectModule |
| 17 | SscratchModule | 24 | PrivilegePermitModule |

全部 0 子模块、105–130 行、父为 NewCSR / CSRPermitModule（均未认领）；
codex 已签 70 个同类 CSR 叶，配方成熟。

### 族 D —— 流水线/缓冲叶（6），UT 目录 `PipeBufferLeaves6`

| # | 模块 | golden 行数 | 父 | 备注 |
|---|---|---:|---|---|
| 25 | Std | 106 | MemExeUnit | store-data 直通pipe |
| 26 | MemExeUnit | 125 | MemBlock | 子 Std（#25） |
| 27 | NCBOrderAddressCAM_1 | 93 | NCB200_1 | 保序 CAM |
| 28 | IntBuffer | 123 | L2Top/XSTile/XSTop | 中断缓冲（时序） |
| 29 | ClockCrossingReg_w64 | 121 | AsyncQueueSink_3 | 跨时钟寄存器（时序） |
| 30 | PrefetchReceiver | 103 | Prefetcher | L2 预取接收 |

## 验收（逐目标，不达成不记完成）

- 生成器 ×4 确定性 + `--check` 幂等。
- `make portlint` 30/30 端口契约。
- golden 双例化差分 UT + 族内独立 oracle：>= 6 seeds，每 seed >= 200,000 向量，
  errors=0；含定向边界（CSR 读写/特权级/写掩码全角、除法器全符号/零除/边界商、
  CAM 空/满/命中序、跨时钟复位、priority 全零/单热/多热）。
- official detached-clean-worktree FM（run_proof.sh，signoff-strict）：
  30/30 native SUCCEEDED；failing/unverified/aborted/unread/unmatched/
  blackbox/dont_verify 全零；MAKE_RC 全 0。失配只改 RTL 重证，不 waiver、
  不降级、不扩黑盒。
- prereg / 实现 / evidence 分开提交；receipt 绑定 clean committed 字节；
  结束时工作树 clean。
- 目标一经登记不静默减少/替换；受阻目标保留并如实报告。
