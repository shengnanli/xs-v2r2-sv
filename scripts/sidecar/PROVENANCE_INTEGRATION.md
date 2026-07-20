# PROVENANCE_INTEGRATION —— provenance 级 manifest 驱动 signoff runner(2026-07-20)

## 交付: `run_signoff_target.sh`

manifest 驱动、每目标自包含证据。绑定 + fail-closed 全部落地(审查范围)。

### 每次运行绑定
- **canonical baseline ID**(manifest.canonical_baseline_id → TOOLS + envelope)。
- **完整 manifest SHA-256**(TOOLS `manifest_sha256`)。
- **该 target entry**(TOOLS `target_entry`: scripts/fm_eq.tcl 或 verif/ut/<M>/fm_eq_bb.tcl)+
  make_target + proof_mode + required_verdict + allow_ref(+ allow SHA)。

### 冻结实际入口 + 记录执行时刻 closure
- FM 在 **detached clean worktree @ IMPL_COMMIT** 执行 → 入口/emitter/validator/pin 均为
  **提交态字节**(无需另拷)。XSSV_HOME=worktree。
- 执行时刻字节快照(emitter 落 script_closure.list; 三列 orig/snap/sha256)。
- **实证**: closure 快照 sha256 == `git show IMPL_COMMIT:<entry>`——
  Alu fm_eq.tcl `2b64f307…` 一致; **DCacheWrapper fm_eq_bb.tcl `ff74f3ca…` 一致**
  (fmbb 双入口冻结均绑提交态)。
- 输入 RTL digest(REF/IMPL closure-v1, 语义行含 MANIFEST_SHA + ALLOW_SHA)、工具 digest、
  实现 commit、clean 状态(worktree head 前后==impl + dirty 0 + main dirty 0)全记 TOOLS。

### 原子生成 + fail-closed
- staging → TOOLS → MANIFEST → COMPLETE(=sha(MANIFEST))→ no-clobber rename。
- **timeout**(make_rc=124)→ TIMEOUT, RUNNER_RC=5, 不产 PASS 证据(实测 Alu@5s)。
- **缺 native facts** → NO_NATIVE_FACTS fail-closed。**rc 不一致**(envelope vs actual)→ validator ERROR。
- **CLEAN_GATE**: worktree/main 非 clean 或 HEAD 变 → CLEAN_GATE_FAIL rc=2。

### signoff 判定(唯一合法)
- 只认 **actual == required == SUCCEEDED**(strict/assembly)→ gate=PASS。
- **shadow**: required=SHADOW_CHECK, 单独统计(不算等价通过)→ gate=PASS 但归 shadow 类。
- 其余(PARTIAL/FAILED/TIMEOUT)→ gate=GAP(诚实不绿, provenance 仍产出)。

### assembly allowlist(运行前绑定)
- `allow_ref` 指向 declarations 里声明的 allowlist JSON; **运行前**校验其已提交
  (`git cat-file -e IMPL_COMMIT:allow_ref`)+ 从提交态取字节 + 记 ALLOW_SHA 入 TOOLS +
  作为 expectation.allow 传入 validator。allow_ref 未提交 → 拒运行(exit 2)。
  (当前代表目标无非空 allowlist; assembly SUCCEEDED 的对象边界属后续设计契约工作。)

## 代表性 provenance smoke(3 类, 证据入库 signoff-evidence/)

| 目标 | entry | proof | measured | required | gate | provenance |
|---|---|---|---|---|---|---|
| **Alu** | fm_eq.tcl | strict | SUCCEEDED | SUCCEEDED | **PASS** | closure==commit ✓ / manifest_sha ✓ / clean ✓ / COMPLETE ✓ |
| Predictor | fm_eq.tcl | shadow | SHADOW_CHECK | SHADOW_CHECK | PASS(shadow 单列) | 同上 ✓ |
| DCacheWrapper | **fm_eq_bb.tcl** | assembly | FAILED | SUCCEEDED | **GAP**(诚实) | **fmbb 入口 closure==commit ✓** / 全绑定 ✓ |
| Alu@5s | — | — | TIMEOUT | — | fail-closed | 不产 PASS 证据 ✓ |

- **Alu = provenance 完整的 SUCCEEDED 正样本**(达 signoff 要求)。
- DCacheWrapper 证明 fmbb 入口(fm_eq_bb.tcl)冻结/closure 绑定与 generic 一致; 其 FAILED
  是**诚实 gap**(不被配置成通过)。

## 留全量 sweep(305_SIGNOFF_SWEEP, 待裁定)

- 全 305 CONFIGURED 目标逐个 run_signoff_target.sh; 汇总 gate=PASS(SUCCEEDED)/ shadow /
  GAP 台账; UNCONFIGURED(Rob)不计。
- assembly SUCCEEDED 须先在 declarations 声明对象 allowlist(设计边界)并绑 hash。
- 回归: validator 115/115 + parser 48/48 + intercept 22/22。
