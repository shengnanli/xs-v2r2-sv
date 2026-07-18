# FM 证明分类台账 (FM STATUS LEDGER)

> 回应 2026-07-18 专家审查:**不把 scoped/shadow/assembly 结果一律叫"等价"**。
> 本台账按证明强度分类,配套 [`GOLDEN_MANIFEST.md`](GOLDEN_MANIFEST.md)(golden 冻结)使用。
> 结果仅在 golden 字节 hash 与 `golden.sha256` 一致时有效。

## 分类定义(证明强度递减)

| 类别 | 含义 | 可否作"可读核可替换 golden"的依据 |
|------|------|-----------------------------------|
| **REPLACEMENT_EQ** | 手写可读核**真实驱动全部对外输出**,原生 `Verification SUCCEEDED`,只用 set_user_match 钉状态点对应(不约束 ref、无 dont-verify 功能点排除) | ✅ 是 |
| **ASSEMBLY_EQ** | 顶层装配层:子模块两侧**同名黑盒/interface-only**,只证明**本层互联 glue** 等价;子模块内部另行(各自模块)证明 | ⚠️ 仅证 glue,须叠加子模块各自证明 |
| **SHADOW_CHECK** | 可读核**不驱动对外功能输出**(golden body 复制在驱动),可读核仅作伴随/探针比对 | ❌ 否,不证明可替换 |
| **PARTIAL_WAIVED** | 原生成功但有**功能点排除(dont-verify)/unmatched BBPin/配置差异/ELAB 降级/waiver**,证明范围受限 | ⚠️ 受限,须逐项 allowlist 后评估 |
| **FAILED / UNRUN / VACUOUS** | 未取得终态成功(仍有 failing / 被中止 / reference 为空壳无比对点) | ❌ 否 |

## 范围声明(诚实口径)

- 全仓 **232 个** UT 目录有 fm 目标;本台账覆盖的是 **44 个变体**——即在**当前冻结 golden 基线**上有 `fm_full.log` 的那批。
- 其余约 **188 个目标**目前**只有旧 golden 基线日志或无日志**(如 LoadQueueRAR/RAW、Rename、VirtualLoadQueue、XSTile、XSTop 完全无 FM 日志)→ 记为 **UNRUN_ON_FROZEN**,等待"同一冻结基线全量重跑"(签核第 5 腿)。
- 因此**不能**说"整仓除三个外都与 golden 等价"。当前可主张的是下表 44 个变体的**分类结论**。

## 一、REPLACEMENT_EQ(可读核真驱动 + 原生 SUCCEEDED)—— 24

Bku · BankedDataArray · IBuffer · ICacheMissUnit · IPrefetchPipe · LLPTW · LoadMisalignBuffer ·
LoadQueue · LoadQueueReplay · LoadQueueUncache¹ · LoadUnit · LqExceptionBuffer · MainPipe ·
MissQueue · PTW · PtwCache · RenameBuffer · Sbuffer² · Slice · StoreExceptionBuffer ·
StoreMisalignBuffer · Tage_SC² · TLBNonBlock² · Uncache · Ftq

- ¹ LoadQueueUncache:2 个 probe 边界 dont-verify(非功能观测网),其余全等价。
- ² Sbuffer(StorePfWrapper 预取)/Tage_SC(TageBTable/MbistPipe SRAM)/TLBNonBlock:含**外部 SRAM/预取子模块两侧同名黑盒**,主体逻辑为真替换。
- 注:这些的 UT 三种子(1/7/42)逐拍 errors=0,FM 原生 SUCCEEDED、0 failing/0 unverified。ELAB-147 降级(见下)对含厂商 RAM 的模块(L2Tlb 家族)是一处**待收紧**的全局告警降级,严格签核需证明指针可达范围。

## 二、ASSEMBLY_EQ(装配层,子模块黑盒,仅证 glue)—— 9

| 模块 | 黑盒的子模块 |
|------|--------------|
| Backend | BypassNetwork / DataPath / CtrlBlock / WbDataPath / ...(FM_INTERFACE_ONLY) |
| LsqWrapper | LoadQueue / StoreQueue(FM_INTERFACE_ONLY) |
| L2TLB | PtwCache / PTW / LLPTW / HPTW / L2TlbMissQueue / L2TlbPrefetch(FM_INTERFACE_ONLY) |
| OpenLLC | RXRSP_4 / RXDAT_4(FM_INTERFACE_ONLY)+ Slice_4 黑盒 |
| TL2CHICoupledL2 | RequestBuffer(FM_INTERFACE_ONLY)+ MMIOBridge/Slice 孙模块 |
| L2Top | inner_l2cache(TL2CHICoupledL2)子模块黑盒 + 死高位 dont-verify |
| MemBlock | 全子模块 memblock_stub 黑盒(fmbb) |
| DCacheWrapper | DCache 黑盒(fmbb) |
| L2TLBWrapper | L2TLB 黑盒(fmbb) |
| Composer | 各预测器子模块黑盒 |

> 装配层证明**只保证本层互联/流水 glue 等价**,不等于整模块功能等价——须叠加各子模块自身的 REPLACEMENT/PARTIAL 证明。CtrlBlock/DataPath 等在 Backend 里是黑盒,其自身证明见各自条目。

## 三、SHADOW_CHECK(可读核不驱动输出,只伴随比对)—— 2

| 模块 | 证据 |
|------|------|
| **Frontend** | `Frontend_wrapper.sv:9576` 明写"可读核 xs_Frontend_core(校验伴随;纯增量,**不影响对外功能**)";对外输出由复制的 golden body `inner_*` 驱动。FM SUCCEEDED **不证明可读核可替换 Frontend**。 |
| **Predictor** | `Predictor_wrapper.sv` 含 **7956 处 `_GEN_/_T_`**(golden body 复制驱动输出),可读核 `xs_Predictor_core` 仅伴随。**当前不在冻结基线重跑集**(无 fm_full.log)。 |

> 这两个必须停止以其 FM "PASS" 主张可读性替换;可读核要真正接管对外输出后才能升级为 REPLACEMENT。

## 四、PARTIAL_WAIVED(原生成功但范围受限)—— 3

| 模块 | 受限原因 |
|------|----------|
| **DataPath** | fm_pins 用 5 段 `set_dont_verify_points` **排除数千 difftest 架构寄存器观测点**(io_value/io_coreid)。功能读口等价,但**不能称 difftest 可观测状态全等价**。 |
| **XSCore** | impl 侧 **31196 个 unmatched BBPin**(两侧配置不一致,Makefile 已诚实注明"基线漂移不参与判定")→ scoped/partial proof,非全等价。 |
| **L2TlbMissQueue** | 含厂商 RAM 越界读的 `FMR_ELAB-147` 被 `fm_eq_full.tcl` **全局降级为 warning**;严格签核应证明指针可达范围或用严格内存模型,不能全局忽略。(同类降级影响 L2TLB/PtwCache/PTW/LLPTW 等 RAM 家族。) |

## 五、FAILED / UNRUN / VACUOUS —— 3(+ 约 188 UNRUN_ON_FROZEN)

| 模块 | 状态 |
|------|------|
| **StoreQueue** | **FAILED**,当前 1487 failing(per-entry committed/completed 需改成 golden gather-mux 形式);UT 三种子过。 |
| **CtrlBlock** | **UNRUN**,FM 被 SIGTERM 中止无终态;RTL 修复已在但未确认(且 UT 收尾结果为空,须重查)。 |
| **StorePipe** | **VACUOUS**,golden 在本配置被 firtool 消成空壳(0 输出/0 寄存器),reference 被读成 blackbox → `Verification NOT RUN`,0 比对点;wrapper 与 golden 逐字一致。不是等价失败,但也**不构成等价证明**。 |
| 其余 ~188 目标 | **UNRUN_ON_FROZEN**:只有旧基线日志或无日志(LoadQueueRAR/RAW/Rename/VirtualLoadQueue/XSTile/XSTop 等)。待全量重跑。 |

## 汇总口径(替代"38/43 SUCCEEDED、只剩三个")

> 在当前冻结基线上重跑的 44 个变体中:**24 REPLACEMENT_EQ + 9 ASSEMBLY_EQ + 2 SHADOW_CHECK + 3 PARTIAL_WAIVED + 3 FAILED/UNRUN/VACUOUS**。
> 全仓 232 个 fm 目标里另有约 188 个 **UNRUN_ON_FROZEN**。
> 距发布级签核仍需:SHADOW/PARTIAL 升级或如实定级、逐对象 blackbox/dont-verify allowlist、ELAB-147 严格化、全量重跑 + 机器可读摘要(见 [`fm-signoff-gaps`] 与签核 7 步)。
