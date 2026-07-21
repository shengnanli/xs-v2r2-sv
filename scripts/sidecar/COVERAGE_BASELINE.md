# 305 signoff sweep —— 第一份可信覆盖基线(2026-07-20)

冻结锚: implementation_commit=566a851 / canonical G0-89fe69e8… / manifest_sha256=256902c1… /
305 CONFIGURED + Rob UNCONFIGURED。并行 P=6, 每目标独立 provenance 证据(signoff-evidence/,
67MB), 单一冻结判定路径(fm_sidecar_verdict.py), 全程未改 RTL/manifest/proof_mode/allowlist。

## 五类台账(总数守恒 305 = OK)

| 类别 | 数量 | 细分 |
|---|---|---|
| **SIGNOFF_PASS**(达签核要求 SUCCEEDED) | **53** | 真可替换等价, 可信绿 |
| SHADOW_CHECK(shadow 单列) | 1 | Predictor |
| **PROOF_GAP**(RTL 重写真缺口) | **104** | PARTIAL 92 + FAILED 11 + ERROR 1 |
| **INFRA_TIMEOUT** | **147** | 见下根因 |
| UNCONFIGURED(不入分母) | 1 | Rob |

## 关键判读: INFRA 147 不是 147 个模块坏

根因量化:
| INFRA 根因 | 数量 | 性质 |
|---|---|---|
| **emitter bbox parser 太严**(组合 flag 如 `e *`) | **124** | 我基础设施单一 bug; 扩 parser 即救回, **非模块缺陷** |
| 模块 Tcl/setup 错(invalid command 等) | 9 | 少数目标 harness 问题 |
| golden ref 未读入(FM-045) | 2 | golden 依赖建立问题 |
| TIMEOUT(大模块 >900s) | 5 | Backend/CtrlBlock/DataPath/LoadQueueRAR/RenameBuffer |
| 其他 | 7 | 待细查 |

**坐实**: 8 个已知曾 FM-verified-passing 的模块(WrBypass / SyncDataModule / PipelineConnect /
SRAMTemplate / IssueQueueAluCsrFenceDiv / StoreQueue / LoadQueue / EntriesAluMulBkuBrhJmp)
现全被同一 parser 卡成 NO_NATIVE_FACTS——不是它们退化, 是 parser 遇到全宇宙报告里
Step-3B 样本没有的组合 flag 就 fail-closed。诚实归 INFRA(没冒充通过)。

## 真实覆盖状态(诚实)

- **可信绿 = 53 SIGNOFF_PASS**(单一冻结判定 + provenance, 伪造不了)。含: 全部 CHI flit
  转换(Decoupled2LCredit/LCredit2Decoupled/RXREQ/RXDAT/RXRSP/TXREQ/TXRSP/TXSNP)、
  多个 Arbiter/Xbar、Alu/BranchUnit/JumpUnit/FMA、FreeList/RenameTable/MSHRSelector 等。
- **证明/契约缺口 = 103 PROOF_GAP**(PARTIAL/FAILED; **未逐个诊断前不认定为 RTL 不等价**——多数含黑盒/unread, 须 assembly+policy 或 RTL 收敛才判): Bku/DCache/NewCSR/StoreQueue 簇的
  PARTIAL, 及 XSTop/XSTile/MemBlock/Frontend/Rename 等 FAILED。这是回去改 RTL 的清单。
- **124 INFRA(parser)= 覆盖盲区**, 修 parser 后重跑才知真 verdict(多半会落入 PASS 或 GAP)。

## 后续(baseline 后, 按审查纪律逐步)

1. **修 emitter bbox parser 支持组合 flag**(如 `e *`/`u *`/`i *`)→ 重跑那 124 → 覆盖盲区消除。
   (这是 baseline 后第一项 infra 修复; 会改 impl commit, 属新一轮。)
2. 9 个模块 Tcl/setup 错、2 个 FM-045、7 个其他 → 逐个查 harness。
3. 5 个 TIMEOUT → 加大 timeout 或拆分。
4. 104 PROOF_GAP → 按影响面排 RTL 修复顺序(与 [[benchmark-parity-goal]] 对齐)。

sweep 工具: run_305_parallel.sh(P6 并行)/ sweep_worker.sh / run_signoff_target.sh(provenance)/
reconcile_universe.py(对账)。台账: sweep_ledger.tsv(每目标一行终态)。


## 台账语义纠正(审查要求, 2026-07-20)

- **ERROR 1(TL2CHICoupledL2)→ INFRA_ERROR**(非 PROOF_GAP): FM-036 pin 引用不存在寄存器
  perfStage_reg[39][5], 是 proof harness 问题非 RTL 不等价。
- **PARTIAL/FAILED 是证明/契约缺口, 未诊断前不认定为 RTL 错误**(多含对称黑盒/unread,
  strict 下必 PARTIAL, 不代表 RTL 不等价)。
- **唯一可信结论: 53 真绿(可替换等价); 其余尚未签核, 不等于 RTL 不等价。**
- 纠正后守恒: SIGNOFF_PASS 53 / SHADOW_CHECK 1 / PROOF_GAP 103 / INFRA_ERROR 148 /
  UNCONFIGURED 1 = 305(sweep_ledger_corrected.tsv)。

## 124 覆盖盲区根因(窄范围, 已实证)

**全部 124 是单一组合 flag `e *`**(empty + unlinked, Formality legend: `* = Unlinked
design module`)。另 5 个是 golden ref 未读(`<None>` top)。`*` 是**修饰符**(与主类 i/u/e
共现), 非独立语义。parser 只需支持"主类 + 文档化修饰符 {*}", 不泛化为"忽略未知 flag"。
