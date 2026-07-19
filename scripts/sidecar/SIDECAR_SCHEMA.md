# FM sidecar schema + 证明契约(2026-07-19, v6 六审版: observed-facts 模型)

> 替代"人读日志 grep"。签核判定**只读**机器可读产物;fm.log 仅诊断。
> 本文为唯一权威版本(旧 v1/v2 描述已废,不再有"Tcl 直接写最终 sidecar"的说法)。

## 生命周期(双 schema,职责分离)

```
fm_shell(Tcl) ──原子写──► native_facts.json     (Tcl 只写它知道的: native verdict + 统计 + 对象)
     │ 退出
runner ──取真实进程 rc──► 合并 expectation ──原子写──► verdict.sidecar.json(envelope)
     │
validator(fm_sidecar_verdict.py) ◄── envelope + **native_facts.json**(sha绑定+逐项一致) + expectation + actual_rc
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
| `native_facts_sha256` | 小写 64-hex, **密码学绑定** native_facts.json 文件字节(validator 重算比对; native 的 verdict/stats/unmatched/objects/qualifications 还须与 envelope 逐项一致; 原始 native facts 只读保留, runner 不得改写) |
| `stats` | `{passing, failing, unverified, aborted, unread_notcompared}`,各为非负 int 非 bool |
| `unmatched` | `{compare_ref, compare_impl, unread_ref, unread_impl, bbout_ref, bbout_impl}` 同上 |
| `objects` | **observed-facts 七字段**(只装 FM 真返回的事实): `matched_blackbox_pairs`=[{ref_path,impl_path}](唯一允许 pair 的字段, 来自 report_matched_points);`interface_only_ref/impl`、`unresolved_blackbox_ref/impl`、`unmatched_ref/impl`=两侧**独立**排序唯一 path 列表(report_unmatched_points 按定义无 pair)。路径须**严格在 top 之下**(`r:/WORK/<top>/...`,禁抽象 top 自身);拒 Unicode Cc/Cf |
| `qualifications` | `{dont_verify_objects, elab147, relaxed_appvars}`(均为对象列表;elab147 列出被降级模块,非 bool) |

JSON 层拒:NaN/Infinity(递归)、duplicate key(object_pairs_hook)。
文件层拒:symlink/FIFO/socket 等非常规文件(lstat),sidecar 与 expectation 同规。

## 观察事实 vs 政策映射(六审: 彻底分离)

Formality 文档区分: `report_matched_points` 返回**真实 ref/impl pair**;`report_unmatched_points`
只返回两侧**独立** point 列表——unmatched 按定义没有工具原生 pair。因此:
- **native facts 只装观察事实**: matched_blackbox_pairs(仅此字段有 pair)+ 六个独立集合。
  emitter 若按 FM_INTERFACE_ONLY/expectation 回填 pair = 配置自报 = 自我验证, 禁止。
- **id 与 waiver-pair 属 expectation policy**: allow 各类别为 [{id, ref_path, impl_path}] 映射
  (人工批准的对应关系)。**双射约束**: 每类别 id/ref_path/impl_path 各自唯一;
  跨类别同 id 必须映射同 pair(one-to-many/many-to-one/重复 pair 双 id/跨类别 id 冲突全拒)。
- **assembly 判定** = 观察集合 == policy 投影(unmatched/interface_only/unresolved_bb 的
  ref/impl 集各自对映射投影精确相等)+ matched pairs == policy 声明 pair + **计数覆盖**
  (compare count ≥ unmatched 对象数, 2 映射 count=1 拒)+ 数量对称 + bool 一致。

## 安全读取(五/六审: TOCTOU 消除 + FIFO fail-fast)

native/envelope/expectation 一律 `os.open(O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK)` 单次打开(FIFO 不阻塞挂死)+ 同 fd `fstat`(仅 regular 读, 64MB 上限)
+ 一次读 bytes;对**同一字节缓冲**同时计算 SHA 与解析 JSON(不再两次独立打开——杜绝
"哈希的是 A、解析的是 B"替换窗口)。O_NOFOLLOW 使 symlink 在打开层即拒。

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
   - **assembly**: ①数量对称 ②观察集合==policy投影(unmatched/interface_only/unresolved_bb
     各 ref/impl 集对映射投影精确相等) ③matched_blackbox_pairs==policy声明pair ④计数覆盖
     (compare≥unmatched对象数) ⑤qualifications全空 —— 全部满足才 SUCCEEDED,否则 PARTIAL。

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
