# fmbb/custom recipe 接入 sidecar(FMBBCUSTOM_WIRING, 2026-07-20)

## 绕过面穷举(不止已列五名)

`grep -l fm_shell verif/ut/*/Makefile*` + 独立判绿扫描 → **6 处**绕过 sidecar 的 recipe:

| 目标 | recipe | 入口 | 原判绿(已删) |
|---|---|---|---|
| DCache | `fmbb` | fm_eq_bb.tcl | `grep -q SUCCEEDED` |
| DCacheWrapper | `fmbb` | fm_eq_bb.tcl | `grep -q SUCCEEDED` + **WAIVED** 分支 |
| L2TLBWrapper | `fmbb` | fm_eq_bb.tcl | `grep -q SUCCEEDED` |
| MemBlock | `fmbb` | fm_eq_bb.tcl | `grep -q SUCCEEDED` |
| NewCSR | `fmbb` | fm_eq_bb.tcl | `grep -q SUCCEEDED` |
| **PtwCache** | `fm`(custom) | fm_eq.tcl | `grep -q SUCCEEDED` |

排除项(扫描命中但非 FM 判绿):L1FlagMetaArray / PMPChecker / TLBFA / TlbStorageWrapper
仅 UT `TEST PASSED` grep,无自定义 FM target(走 ut_common.mk 通用 fm-% 或无 FM)。

## 统一接入(不改 RTL / proof_mode / allowlist)

**fm_eq_bb.tcl(5)**: 加 sidecar 钩子——补全 unread 六元组(此前只设 verify_unread)+
`FM_SIDECAR_OUT` 门控下 source `fm_native_emit.tcl`、注册入口+emitter、装执行 trace guard、
verify 前 `sidecar_capture_appvars`、verify 后 `sidecar_emit`。native_verdict 取
`verification_status`——**WAIVED 打印对判定无效**(DCacheWrapper 的 perf 假阳性 waiver
在 sidecar 下如实记 FAILED)。

**recipe(6)**: ①行首 `[ -n "$FM_SIDECAR_OUT" ]` 硬闸(无 sidecar 拒执行, 杜绝独立判绿);
②env 加 `XSSV_HOME`/`FM_RUN_ID`;③fm_shell 后落**真实 rc** 到 `$FM_SIDECAR_OUT/fm_shell.rc`;
④**删两条 `grep -q SUCCEEDED`/WAIVED 判绿**, 判定统一归 `fm_sidecar_verdict.py`。
PtwCache 已用 fm_eq.tcl(本就 sidecar-wired), 仅去 grep + 落 rc + 门控。

## 附带修复(接入过程实证)

- **blackbox_match_mode 规范化**: FM 把 `identity`→`Identity`(首字母大写, fm_shell 实测)。
  移除 capture 时 "history(set 参数)==readback" 检查(FM 规范化致误判; 安全性由 validator
  三方绑定 + 执行 trace 每 set 必记 + phase 冻结 + 变值拒 承担);APPVAR_SPEC 该键改 enum_ci;
  emitter relaxed 计算对该键 ci 规范化。
- **pair 排序**: `report_matched_points -not_compared -status unread -list` 多对时 Tcl `lsort`
  整对字符串序 ≠ validator 的 Python `sorted((ref,impl))`(impl 含花括号/多对暴露, PtwCache)。
  `sidecar_pairs_sorted` 改按 `"$r\n$i"` 键排序(路径无换行, \n<任何路径字符 → 等价元组序)。

## 代表性 smoke(正反各一, `fmbb_sidecar_smoke.sh`)

| 会话 | NEG_GUARD(无sidecar拒) | native | POS(同一validator) | NEG_TAMPER(改native) |
|---|---|---|---|---|
| DCacheWrapper(fmbb) | PASS | FAILED | **FAILED** native_failed(WAIVED grep-green 已死) | ERROR sha_mismatch |
| PtwCache(custom fm) | PASS | SUCCEEDED | **PARTIAL** strict_unread(grep-SUCCEEDED 已死) | ERROR sha_mismatch |

两者的诚实 verdict(FAILED/PARTIAL)替代了原 grep/WAIVED 绿灯——证明接线消除独立判绿、
统一走 emitter+真实 rc+同一 validator。

## 未覆盖(留 305_SWEEP)

- 这些 fmbb 层是 assembly 证明(黑盒互联), 当前默认 signoff-strict + 无 allowlist → 诚实
  PARTIAL/FAILED。要得 SUCCEEDED 须在 305 manifest 里设 proof_mode=assembly + 逐对象 policy
  (本阶段严格不改 proof_mode/allowlist)。
- 全量 305 runner 对 fmbb 入口(fm_eq_bb.tcl 非 scripts/)的冻结/角色绑定, 属 305 阶段。
- 回归: validator 115/115 + parser 48/48 + intercept 20/20; Step 3B 证据(01543f0@edbcd2ab)
  无回归 bad=0 + 负测 21/21(emitter 改动不影响其冻结 expected commit)。
