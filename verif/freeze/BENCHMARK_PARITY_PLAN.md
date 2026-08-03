# 整芯片 Benchmark Parity 收口计划

> **终极验收目标(硬指标)**:用**全部重写核**装配的整芯片跑 **dhrystone + coremark**,
> 结果与 golden **一模一样**(分数/输出/trap **且** 逐周期 cycle 数一致)。
> 逐拍一致要求端到端 **REPLACEMENT_EQ**(FM 位级等价 bug-for-bug)+ 忠实装配 + difftest/NEMU lockstep 实证。
> 配套 [`FM_STATUS.md`](FM_STATUS.md)(分类)+ [`GOLDEN_MANIFEST.md`](GOLDEN_MANIFEST.md)(冻结)。

## 原理(为什么这能保证一致)

整芯片每个核 REPLACEMENT_EQ(可读核真驱动输出 + 原生 SUCCEEDED + 无 scoped 排除)
+ 装配层等价 ⇒ 同复位/内存/激励下逐拍 == golden ⇒ benchmark 一致。**缺的是完整性,不是原理。**

## ⚠ 并列硬约束:可读性 + 文档质量(不可为对齐 golden 牺牲)

重写 RTL 的**首要目的是学习**。parity 与**可读性/文档质量并列**,任何 FM 收口都必须同时满足:
- 代码可读:typedef struct/enum、function、genvar/for 各 >0;`grep -E "_GEN_|_T_[0-9]|RANDOMIZE"` = 0(代码区);行数 ≪ golden;领域命名而非匿名临时名。
- `.svh` 不套壳(`grep -hcE "_GEN_|_T_[0-9]" *.svh` ≈ 0)。
- 每模块配高质量中文设计文档(设计意图/流水分节/领域命名,适合学习)。
- **FM 对齐 golden 必须用可读写法达成**:如复位域对齐 → 清晰的 `always_ff` + 注释说明为何异步/无复位,**不是**抄 golden 的匿名临时名或把 golden body 抽进 svh 套壳。
- **红线**:绝不为换取 FM pass 而退回 golden-body 套壳(这正是当前 SHADOW 的病根)。
- **契合点**:消 SHADOW(下方 P0)恰是可读性关键战场——让可读核真接管输出 = 同时达成"可替换 + 可读",一举两得。
- **验收 = parity 达成 且 可读性/文档闸门通过**(缺一不可)。

## 缺口清单(按 critical path 优先级)

### P0 — SHADOW_CHECK(可读核未驱动输出,最致命,取指/预测在关键路径)

| 模块 | 实情 | 收口路径 | 工程量 |
|------|------|----------|--------|
| **Frontend** | `Frontend.sv` 是真可读核(0 forbidden),但 wrapper 对外 11 个输出 assign **全由 golden body `inner_` 驱动**,可读核并联作伴随 | 把对外输出从 `inner_` 切到 `xs_Frontend_core`,补齐可读核缺的输出逻辑,证 REPLACEMENT_EQ | 大(取决可读核完备度) |
| **Predictor** | wrapper 疑为 golden body 套壳(7956 `_GEN_/_T_`),可读核 `Predictor.sv`(13400 行)可能未接入 | 确认可读核完备度→接管输出→证等价;或子模块级(各预测器已 REPLACEMENT)组合 | 大 |

### P1 — FAILED / UNRUN(主干未证等价)

| 模块 | 状态 | 收口 |
|------|------|------|
| **StoreQueue** | FM FAILED,1487 failing(per-entry committed/completed 需改 golden gather-mux) | 改 RTL 对齐 golden + UT 回归 → REPLACEMENT_EQ |
| **CtrlBlock** | FM UNRUN(被中止);UT 收尾结果为空(UT 本身可能有问题) | 先查 UT 为何空 → 跑通 UT → 重跑 FM 收敛 |

### P2 — ASSEMBLY_EQ 顶层(只证 glue,子模块黑盒)

Backend / MemBlock / DCache(Wrapper)/ LsqWrapper / L2TLB / L2Top / OpenLLC / TL2CHICoupledL2 / Composer(+ L2TLBWrapper)。
- 收口:每个黑盒子模块自身须 REPLACEMENT_EQ(多数已在,盘点后列缺的);装配层 glue 已 SUCCEEDED。
- 整芯片 XSCore/XSTile/XSTop 也是装配层,同理。

### P3 — PARTIAL_WAIVED(scoped 排除)

| 模块 | 受限 | 收口 |
|------|------|------|
| **DataPath** | 排除数千 difftest 架构寄存器观测点 | 逐对象 allowlist(difftest 观测非功能路径,可论证豁免)或非 difftest 基线消除 |
| **XSCore** | 31196 unmatched BBPin(配置漂移) | 对齐两侧配置消除 unmatched,或 allowlist 后评估 |
| **L2TlbMissQueue** | ELAB-147 全局降级 | 证明指针可达范围 / 严格内存模型 |

### P4 — UNRUN_ON_FROZEN(全量 sweep 后填实)

全仓 228 fm 目标,sweep 前只 43 有冻结基线日志。**本次全量 sweep 结果见 `fm_ledger.tsv`**,把余下目标的真实 verdict 补齐(此段 sweep 完成后填数)。

## 装配 + 实证(收口最后两步)

1. **装配整芯片**:从全部重写核生成 SimTop/XSTop(现有 ST 是 17 模块局部替换 @coremark 6492,判据 `grep -c _probe golden = 0`;带 probe bore 的模块——含 Frontend/Predictor 类——当时替不进,须先解决 SHADOW)。
2. **difftest + NEMU 跑 coremark/dhrystone**:逐指令 lockstep + 同 cycle == golden。这是"一模一样"的最直接实证,FM 是其形式化背书。环境:`+ram_size=8589934592`,coremark HIT GOOD TRAP @6492。

## 里程碑判据

- **M1**:SHADOW 清零(Frontend/Predictor → REPLACEMENT_EQ)。
- **M2**:FAILED/UNRUN 清零(StoreQueue/CtrlBlock → 通过)。
- **M3**:整芯片所有核 REPLACEMENT_EQ,ASSEMBLY 子模块全配齐,PARTIAL 排除项 allowlist/消除。
- **M4**:整芯片从全重写核装配 + difftest 跑 coremark == golden@6492、dhrystone == golden。
- **验收**:M4 达成 = "重写 RTL 跑 benchmark 与 golden 一模一样" 成立。
