# FM sidecar schema + 证明契约(2026-07-19, v3 三审统一版)

> 替代"人读日志 grep"。签核判定**只读**机器可读产物;fm.log 仅诊断。
> 本文为唯一权威版本(旧 v1/v2 描述已废,不再有"Tcl 直接写最终 sidecar"的说法)。

## 生命周期(双 schema,职责分离)

```
fm_shell(Tcl) ──原子写──► native_facts.json     (Tcl 只写它知道的: native verdict + 统计 + 对象)
     │ 退出
runner ──取真实进程 rc──► 合并 expectation ──原子写──► verdict.sidecar.json(envelope)
     │
validator(fm_sidecar_verdict.py) ◄── envelope + expectation + actual_rc(runner 再传一次交叉)
```

- **native_facts.json**(`fm-sidecar-native-v1`,Tcl 写 tmp+rename):
  `{schema, run_id, top, native_verdict, stats, unmatched, objects, qualifications}`。
  Tcl 不知道自己的进程 rc,不写 rc;不写 expectation 派生字段。
- **verdict.sidecar.json**(`fm-sidecar-envelope-v1`,runner 写 tmp+rename):
  native_facts 全部字段 + `target/variant/proof_mode/canonical_baseline_id/inputs_sha256/
  script_sha256/tool/fm_shell_rc(真实进程 rc)`。
- **validator** 除读 envelope 外,还接收 runner **再传一次**的 `actual_rc` 与外部 `expectation`,
  三方交叉(envelope 自报 rc == actual_rc == 0)。

## envelope 字段(全部必填,缺任一/多任一 → ERROR)

| 字段 | 类型约束 |
|------|----------|
| `schema` | `"fm-sidecar-envelope-v1"` |
| `run_id` / `target` / `top` / `variant` / `canonical_baseline_id` | **token**: 非空 str,`^[A-Za-z0-9][A-Za-z0-9_.\-]*$`,无 `..`(路径遍历/空串/整数一律拒) |
| `proof_mode` | `signoff-strict` / `assembly` / `shadow` / `diagnostic-full` |
| `inputs_sha256` | `{ref_srcs_digest, impl_srcs_digest}`,各为**小写 64-hex** |
| `script_sha256` / `tool.fm_shell_digest` | 小写 64-hex |
| `fm_shell_rc` | `int` 且非 `bool` |
| `native_verdict` | `SUCCEEDED`/`FAILED`/`INCONCLUSIVE`/`NOT_RUN` |
| `stats` | `{passing, failing, unverified, aborted, unread_notcompared}`,各为非负 int 非 bool |
| `unmatched` | `{compare_ref, compare_impl, unread_ref, unread_impl, bbout_ref, bbout_impl}` 同上 |
| `objects` | `{blackbox_ref, blackbox_impl, interface_only, unmatched_ref, unmatched_impl}`,各为**排序·唯一·token 列表** |
| `qualifications` | `{dont_verify_objects, elab147, relaxed_appvars}`(均为对象列表;elab147 列出被降级模块,非 bool) |

JSON 层拒:NaN/Infinity(递归)、duplicate key(object_pairs_hook)。
文件层拒:symlink/FIFO/socket 等非常规文件(lstat),sidecar 与 expectation 同规。

## 对象名 canonical mapping

sidecar/allowlist 中对象名为 **canonical 名**:剥去 `r:/WORK/<top>/` 与 `i:/WORK/<top>/` 前缀、
实例路径归一为 golden 模块名(如 `r:/WORK/Backend/inner_ctrlBlock` 与 `i:/WORK/Backend/u_core/ctrl`
都归一为模块名 `CtrlBlock`)。归一由 Tcl emitter(步3)完成;validator 只做 token 格式校验,
两侧同名即视为同对象。

## expectation(外部权威 manifest,不可选,同等严格校验)

`{run_id, target, top, variant, proof_mode, canonical_baseline_id, ref_digest, impl_digest,
script_digest, tool_digest, allow}`。
- 身份字段 token 校验、digest 64-hex 校验与 sidecar 同规(**两侧同错不再互证**:即便 sidecar 与
  expectation 同用空 target/整数 run_id,也先在各自类型校验被拒)。
- `allow` **按资格类别**声明:`{blackbox: [...], interface_only: [...], unmatched: [...]}`
  (扁平列表已废——类别不可互换)。
- **strict/shadow/diagnostic 的 allow 三类必须全空**,非空 → ERROR。
- 读取用与 sidecar 相同的 strict loader(dup-key/NaN/symlink 拒)。

## validator 判定(fail-closed)

verdict ∈ {SUCCEEDED, FAILED, PARTIAL, SHADOW_CHECK, DIAGNOSTIC, UNRUN, ERROR}

1. expectation 自校验(上节)→ 不合规 ERROR。
2. envelope strict-load + 全字段强类型 → 违规 ERROR。
3. expectation 精确相等(身份 6 项 + 4 digest)→ 不等 ERROR。
4. rc 三方交叉: `envelope.fm_shell_rc == 0 ∧ actual_rc == 0 ∧ 相等` → 违规 ERROR。
5. native: NOT_RUN→UNRUN;FAILED/INCONCLUSIVE→FAILED。
6. `failing != 0` → FAILED(native 矛盾打回);`passing <= 0` → ERROR(空证明)。
7. 模式:
   - **diagnostic-full** → DIAGNOSTIC(永不 signoff);**shadow** → SHADOW_CHECK。
   - **signoff-strict**: unverified/aborted/unread(全三源)/unmatched(4 计数)/objects(全五类)/
     qualifications(全三类)任一非零/非空 → PARTIAL;否则 SUCCEEDED。
   - **assembly**: ①数量对称 `compare_ref==compare_impl ∧ bbout_ref==bbout_impl`
     ②对象对称 `unmatched_ref==unmatched_impl ∧ blackbox_ref==blackbox_impl`
     ③数量-对象证据一致(`bool(count)==bool(objects)`,只有数量没有身份 → PARTIAL)
     ④分类精确相等 `blackbox==allow.blackbox ∧ interface_only==allow.interface_only ∧
       unmatched==allow.unmatched`(非子集,类别不可互换)
     ⑤qualifications 全空 —— 全部满足才 SUCCEEDED,否则 PARTIAL。

所有非 SUCCEEDED 返回都携带**非 None 的 reason**(v2 的 `{"reason":..., **q}` 覆盖 bug 已修,
一律 `{**q, "reason": ...}`)。

只有 `SUCCEEDED ∧ signoff-strict` = 无条件可替换等价;`SUCCEEDED ∧ assembly` = 仅本层 glue
等价(须叠加子模块各自 strict 证明)。

## closure digest 算法(可复现定义)

- **ref/impl closure** (`inputs_sha256.*`) = `closure-v1`:该侧 FM 读入的全部源文件按
  LC_ALL=C 相对路径排序,逐文件 `relpath<TAB>size<TAB>sha256<LF>`,再追加固定顺序的语义要素行
  (`DEFINE=...`/`INCDIR=...`/`MERGE_DUP=...`/`FIELD_MAP_SHA=...`/`PINS_SHA=...`/`MODE=...`),
  对完整字节流 SHA-256。
- **script closure** (`script_sha256`) = fm_eq.tcl 与全部被 source 的 tcl(pre/pins/custom)
  按 source 顺序串接后 SHA-256。
- **tool digest** = sha256(fm_shell 实际可执行)。
- 生成器 `fm_closure_digest.py`(步4)为 expectation 与 envelope 两侧共用。
