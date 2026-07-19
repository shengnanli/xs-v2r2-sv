# FM 终态 sidecar schema + 证明契约(2026-07-19)

> 替代脆弱的"人读日志 grep"——由 Tcl 在 verify 后**原子写**一份机器可读终态。签核判定**只**读 sidecar,
> 人读日志(fm.log)仅作诊断。任何异常/缺字段/run-id 不匹配 → ERROR(fail-closed)。

## sidecar 文件

- 每次 FM 运行产出 `fm_work/<variant>/verdict.sidecar.json`(Tcl 写 tmp 后 rename)。
- 与之配对: runner 传入的 `expected_run_id`(env `FM_RUN_ID`)必须与 sidecar 内 `run_id` 精确一致。

## schema(全部字段必填, 缺任一 → ERROR)

| 字段 | 类型 | 含义 |
|------|------|------|
| `schema` | str | 固定 `"fm-sidecar-v1"` |
| `run_id` | str | 本次运行唯一 ID(runner 生成, 传 Tcl; sidecar 回写; validator 交叉) |
| `target` | str | UT 目录名 |
| `top` | str | FM_TOP(golden 变体名) |
| `variant` | str | 变体名(= work_path 名) |
| `proof_mode` | str | `signoff-strict` / `assembly` / `shadow` / `diagnostic-full` |
| `canonical_baseline_id` | str | 绑定 canonical golden(须 == ledger 的 baseline_id) |
| `inputs_sha256` | obj | `{ref_srcs_digest, impl_srcs_digest}`(源文件集聚合 hash) |
| `script_sha256` | str | fm_eq.tcl 自身 hash |
| `tool` | obj | `{fm_shell_version}` |
| `fm_shell_rc` | int | fm_shell 进程退出码(runner 填, Tcl 不知道自己的 rc → 由 runner 合并) |
| `native_verdict` | str | Formality 原生 `verify` 返回(`SUCCEEDED`/`FAILED`/`INCONCLUSIVE`/`NOT_RUN`) |
| `stats` | obj | `{passing, failing, unverified, aborted, unread_notcompared}`(整数) |
| `unmatched` | obj | `{compare_ref, compare_impl, unread_ref, unread_impl, bbout_ref, bbout_impl}` |
| `qualifications` | obj | `{dont_verify_objects:[...], elab147:bool, blackbox_objects:[...], interface_only:[...]}` |

> `fm_shell_rc` 与 `native_verdict` 双轨:Tcl 写 native_verdict(它能拿到 `verify` 返回);
> runner 在 fm_shell 退出后把进程 rc 合并进 sidecar(原子 re-write)。validator 两者都查。

## validator 判定(fail-closed, 见 fm_sidecar_verdict.py)

verdict ∈ {SUCCEEDED, FAILED, WAIVED, PARTIAL, SHADOW_CHECK, DIAGNOSTIC, UNRUN, ERROR}

前置(任一不满足 → ERROR):
1. sidecar 存在、JSON 可解析、`schema == "fm-sidecar-v1"`、**全部字段齐全**(缺字段=ERROR,不按零)。
2. `run_id == expected_run_id`(旧日志/串目录 → 不匹配 → ERROR)。
3. `canonical_baseline_id == ledger.baseline_id`(非 canonical 基线 → ERROR)。
4. `expected_top` 给定时 `top == expected_top`(wrong top → ERROR)。
5. `fm_shell_rc == 0`(非零 → ERROR)。
6. `native_verdict`:`NOT_RUN` → UNRUN;`FAILED`/`INCONCLUSIVE` → FAILED(与后续数字一致性交叉)。

数字闸门(native SUCCEEDED 后):
7. `stats.failing != 0` → FAILED(即便 native 说 SUCCEEDED, 矛盾即打回)。
8. `stats.passing <= 0` → ERROR(空证明)。

模式规则(固化):
- **signoff-strict**: 要求 failing/unverified/unread(notcompared+两侧 unmatched-unread)/unmatched(两侧)/aborted 全 0;
  passing>0;`blackbox_objects` 空;`dont_verify_objects` 空;`elab147==false`。否则 PARTIAL。
- **assembly**: 只允许 manifest **精确声明**的对象集(interface_only)且两侧**对称**(compare_ref==compare_impl 等);
  声明外的 unmatched/blackbox → PARTIAL;unverified/aborted/unread 非 0 → PARTIAL。
- **shadow**: 一律 SHADOW_CHECK(可读核不驱动输出)。
- **diagnostic-full**: 一律 DIAGNOSTIC(**永不** signoff)。

只有 `verdict=SUCCEEDED ∧ proof_mode=signoff-strict ∧ qualifications 全空` = 无条件可替换等价。
`assembly SUCCEEDED` = 仅本层 glue 等价(须叠加子模块各自 strict 证明)。

## 二审修订(强类型 + 外部 expectation 权威 + rc 交叉 + 对象身份)

validator 签名改为 `verdict(sidecar_path, expectation, actual_rc)`:
- **expectation = 外部权威 manifest(不可选)**: run_id/target/top/variant/proof_mode/
  canonical_baseline_id/ref_digest/impl_digest/script_digest/tool_digest/allow_objects。
  sidecar 每项须与之**精确相等**(非子集、非可选)。
- **actual_rc = runner 获取的真实进程 rc**(不信 sidecar 自报)。生命周期:
  Tcl→native_facts.json → fm_shell 退出 → runner 取真实 rc → runner+expectation→verdict.sidecar.json。
  validator 要求 `fm_shell_rc(自报)==0 ∧ actual_rc==0 ∧ 两者相等`。
- **强类型**: JSON 拒 NaN/Infinity(递归)、duplicate-key(object_pairs_hook);计数须 `int 且非 bool 且≥0`;
  hash 须完整**小写 64-hex**;对象数组须**排序·唯一·非空字符串**;stats/unmatched/objects/qualifications/
  inputs_sha256/tool 嵌套字段集**精确**。
- **对象身份**(assembly): sidecar 新增 `objects{blackbox_ref,blackbox_impl,interface_only,
  unmatched_ref,unmatched_impl}`。assembly SUCCEEDED 要求 ref/impl 对象集对称 **且**
  `declared(blackbox_ref∪interface_only∪unmatched_ref) == allow_objects`(精确相等, 非子集)。
- **strict 补齐**: `objects` 任一非空、`qualifications.{dont_verify_objects,elab147,relaxed_appvars}`
  任一非空 → PARTIAL。`elab147` 改为**对象列表**(哪些模块被 ELAB 降级), 非 bool。

## hash 算法定义(审查点 6, 避免"字段存在但不可复现")

- **ref/impl closure digest** (`inputs_sha256.*`) = `closure-v1`:
  对该侧 FM 读入的**全部源文件**(golden ref 变体+依赖 / impl 核+wrapper+所有 `include 的 .svh),
  按 **LC_ALL=C 相对路径排序**, 每文件输出 `relpath<TAB>size<TAB>sha256(content)<LF>`,
  再对完整字节流 SHA-256。**并把编译期决定输出的要素纳入**: `+define` 宏集、`+incdir` 集、
  FM_MERGE_DUP、FM_FIELD_MAP 内容、fm_pins*.tcl 内容、mode ——这些作为附加行
  `KEY=<value 或 sha256>` 追加进同一字节流(固定顺序), 保证"相同 digest ⇒ 相同 FM 输入语义"。
- **script closure digest** (`script_sha256`) = sha256(fm_eq.tcl) ⊕ 所有被 source 的 tcl
  (fm_pins_pre/fm_pins/custom recipe 内联 tcl)按序串接。
- **tool digest** (`tool.fm_shell_digest`) = sha256(fm_shell 可执行实际路径)。
- 生成器 `fm_closure_digest.py`(步4实现)产出这些 digest, expectation 与 sidecar 两侧都用它, 天然可复现。
