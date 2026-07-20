# MANIFEST_RUNNER_PREP —— 305 manifest + 通用 runner + 代表性 smoke(2026-07-20, 审查修订 v2)

## #1 目标全集对账(305 → 261 → 305)

**根因**: 初版 `variants_of` 用正则解析 `FM_VARIANTS`, 漏掉**变量引用**形式
(`FM_VARIANTS = $(VARIANTS)` / `$(INNER) $(OUTER)` / `$(SRAM_VARIANTS)`)——49 个变体
(PipelineConnect 18 / SyncDataModule 18 / SRAMTemplate 11 / SRAMTemplate_2p 2)未展开。
**修复**: 改用 `make --eval` 权威求值 `$(FM_VARIANTS)`(解析变量引用/续行/include)。

`reconcile_universe.py`(机器 diff vs 冻结 `verif/freeze/fm_targets.tsv`):
```
冻结=305 当前CONFIGURED=305 UNCONFIGURED=1['Rob']  缺失=0 新增=0  RECONCILE_DIFF=0
```
- **Rob 显式记录为 UNCONFIGURED**(有 UT 目录, 无 FM 配置)——不运行、不计通过。

## #2 signoff 要求 vs smoke 观测 分离(SIGNOFF_MANIFEST_POLICY)

manifest schema `fm-signoff-manifest-v2`:
- **required_verdict 由 proof_mode 机械派生, 不手设**:
  `signoff-strict / assembly → SUCCEEDED`;`shadow → SHADOW_CHECK`。
  **PARTIAL / FAILED / TIMEOUT / UNVERIFIED 永不作为 required_verdict**。
  派生结果: 303 SUCCEEDED(strict 291 + assembly 12)+ 2 SHADOW_CHECK。
- **config_status**: CONFIGURED(305)/ UNCONFIGURED(1=Rob); UNCONFIGURED 不运行不计。
- `manifest_declarations.tsv` 只声明**设计契约**(proof_mode 边界 + allow_ref 对象 allowlist),
  **不声明 verdict**。
- 当前观测(Bku=PARTIAL / NewIFU=PARTIAL / DCacheWrapper=FAILED / PtwCache=PARTIAL)移入
  **`smoke_expected.tsv` 的 expected_observation**(仅验 runner 机械), **明确标注为 gap**
  (未达 required=SUCCEEDED), 不进入正式 signoff requirement。

**正确流程**(审查订正, runner/manifest 强制): ①设计契约先声明 proof_mode + 对象 allowlist
→ ②required_verdict 机械派生 → ③跑 Formal → ④测量到的新对象只形成**候选变更**, 人工确认后
改声明 + 重跑, **不用同次结果反向放行**。

## runner 双模式(`run_manifest_target.sh`)

- 默认 **signoff**: 断言 measured == required_verdict(派生)。measured != required = **签核 gap**
  (诚实不绿, 非 runner 错)。
- **--smoke**: 断言 measured == expected_observation(smoke_expected.tsv), 仅验 runner 机械。
- **UNCONFIGURED** → exit 4(不运行不计)。**timeout**(rc=124/无 native)→ 分类 TIMEOUT
  (不配成通过)。

## 代表性 smoke(6 类 + SUCCEEDED 正样本; --smoke 机械全 MATCH)

| 类别 | 目标 | proof_mode | measured | required_verdict(派生) | smoke MATCH | signoff |
|---|---|---|---|---|---|---|
| strict | **Alu** | signoff-strict | **SUCCEEDED** | SUCCEEDED | ✓ | **达要求** |
| strict | Bku | signoff-strict | PARTIAL | SUCCEEDED | ✓ | **gap** |
| assembly | NewIFU | assembly | PARTIAL | SUCCEEDED | ✓ | **gap**(须声明 allowlist) |
| fmbb | DCacheWrapper | assembly | FAILED | SUCCEEDED | ✓ | **gap**(须修证明环境/RTL) |
| custom | PtwCache | signoff-strict | PARTIAL | SUCCEEDED | ✓ | **gap** |
| shadow | Predictor | shadow | SHADOW_CHECK | SHADOW_CHECK | ✓ | 达 SHADOW_CHECK(单独统计) |
| timeout | Alu@5s | — | TIMEOUT | — | (fail-closed) | — |
| unconfigured | Rob | n/a | (不运行) | N/A | exit 4 | 不计 |

**Alu 是唯一当前达到 signoff 要求(SUCCEEDED)的正样本**; 其余 5 个是诚实 gap(未达 SUCCEEDED),
反映 RTL 重写 signoff 尚未完成——**不被 manifest 配置成通过**。

## 留全量 sweep(305_SIGNOFF_SWEEP, NO-GO)

- run_manifest_target.sh 接入 Step-3B 级 frozen/closure provenance(每目标 frozen+MANIFEST+
  COMPLETE + 语义 verifier)。
- assembly SUCCEEDED 须先声明对象 allowlist(设计边界)。
- 逐目标 Formal + 契约声明; 达 SUCCEEDED 的目标才计签核绿, gap 目标回到 RTL 重写。
- 回归: validator 115/115 + parser 48/48 + intercept 22/22。
