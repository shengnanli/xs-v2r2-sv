# MANIFEST_RUNNER_PREP —— 305 manifest + 通用 runner + 代表性 smoke(2026-07-20)

## 三条铁律(审查要求, 落地方式)

1. **manifest 不把当前失败配置成通过**: `required_verdict` 默认 `UNVERIFIED`(未声明=不算
   签核绿灯, 非绿); 声明值只能来自 `manifest_declarations.tsv`(设计边界), **不从运行日志
   反向生成**。DCacheWrapper native FAILED 声明为 FAILED(不 assembly-升级);
   PtwCache strict_unread 声明为 PARTIAL(不切 assembly 掩盖)。
2. **契约不放宽**: proof_mode 由 Makefile 结构信号机械判定(interface_only=assembly /
   fmbb / shadow 人工声明 / 余 strict), 不为过某目标而切。unread=0 契约不变。
3. **allowlist 来自设计边界**: manifest 的 allow 只从声明来(本阶段代表目标无需非空 allow
   即达其诚实 verdict); assembly SUCCEEDED 须先声明黑盒对象边界(未做)。

## 产物

- `gen_305_manifest.py`: 枚举全部 FM 目标(generic fm-<v> 含多行 FM_VARIANTS 续行 + 6 fmbb/
  custom)。**261 条**(早期"305"为估算; 机械枚举实为 261, 审计无变体目录被漏)。
  by_mode: strict 247 / assembly 12 / shadow 2。
- `manifest_declarations.tsv`: 设计边界声明(唯一权威; 缺省 UNVERIFIED)。
- `manifest_305.json`: `{schema:fm-305-manifest-v1, canonical_baseline_id, count, entries[]}`;
  每条 target/ut_dir/makefile/make_target/entry(fm_eq.tcl|fm_eq_bb.tcl)/proof_mode/
  required_verdict/allow_ref/canonical_baseline_id。
- `run_manifest_target.sh`: manifest 驱动通用 runner。识别并冻结正确入口, 跑正确 make target,
  FM_MODE 从 manifest 注入, 落真实 fm_shell.rc, emitter 产 native facts, **同一 validator**
  (fm_sidecar_verdict.py)判定, 断言 actual==required_verdict。timeout(rc=124/无 native)→
  分类 TIMEOUT(不配成通过)。UNVERIFIED → 报告不参与绿灯。

## 代表性 smoke(6 类全覆盖 + 至少一 SUCCEEDED 正样本)

| 类别 | 目标 | mode | measured | required | 判 |
|---|---|---|---|---|---|
| **strict SUCCEEDED(正样本)** | Alu | signoff-strict | **SUCCEEDED** | SUCCEEDED | MATCH |
| strict PARTIAL | Bku | signoff-strict | PARTIAL(unread 19) | PARTIAL | MATCH |
| assembly | NewIFU | assembly | PARTIAL(无 policy) | PARTIAL | MATCH |
| fmbb | DCacheWrapper | assembly | FAILED(native FAILED) | FAILED | MATCH |
| custom fm | PtwCache | signoff-strict | PARTIAL(unread) | PARTIAL | MATCH |
| shadow | Predictor | shadow | SHADOW_CHECK | SHADOW_CHECK | MATCH |
| timeout | Alu@5s | — | TIMEOUT(rc=124) | (SUCCEEDED) | **MISMATCH(fail-closed 演示)** |

- **Alu = 真正的 sidecar 判定 SUCCEEDED 正样本**(passing 275 / unread 0-0 / 无 objects /
  无 relaxed), 满足审查"至少一个 SUCCEEDED"。
- 6 个诚实 verdict 全部与声明 MATCH; timeout 演示 runner 检出并 fail-closed(不绿)。

## 未覆盖 / 留全量 sweep

- 256 条仍 UNVERIFIED(未声明): 须逐目标测量后写 declarations(设计边界), 方可入签核绿灯。
- assembly SUCCEEDED 须声明逐对象 allowlist(NewIFU 当前诚实 PARTIAL)。
- fmbb 入口(fm_eq_bb.tcl)的 frozen/closure 角色完整绑定(Step-3B 级 provenance)未接入
  run_manifest_target.sh 的证据机制——本 runner 为**测量+断言**版; 全量签核证据(每目标
  frozen+MANIFEST+COMPLETE+语义 verifier)是 sweep 阶段工作。
- 回归: validator 115/115 + parser 48/48 + intercept 22/22。
