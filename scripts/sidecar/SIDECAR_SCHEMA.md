# FM sidecar schema + 证明契约(2026-07-20, v7 十审版: 3A.2 四补丁 + 十审三阻塞)

> 替代"人读日志 grep"。签核判定**只读**机器可读产物;fm.log 仅诊断。
> 本文为唯一权威版本。v7 依据 Step3A.1/3A.2 实证审定: 默认 unmatched -list 为主集(GO)、
> pair 按实例集合分类(GO)、BBOUT/BBIN/PI zero-only(GO)、unread=false 冻结执行语义(GO)。

## 生命周期(双 schema,职责分离)

```
fm_shell(Tcl) ──原子写──► native_facts.json     (Tcl 只写它知道的: native verdict + 统计 + 对象 + 有效 appvars)
     │ 退出
runner ──取真实进程 rc──► 合并 expectation ──原子写──► verdict.sidecar.json(envelope)
     │
validator(fm_sidecar_verdict.py) ◄── envelope + **native_facts.json**(sha绑定+逐项一致) + expectation + actual_rc
```

- **native_facts.json**(`fm-sidecar-native-v1`,Tcl 写 tmp+rename):
  `{schema, run_id, top, native_verdict, stats, unmatched, objects, qualifications, entry_appvars}`。
  Tcl 不知道自己的进程 rc,不写 rc;不写 expectation 派生字段。
- **verdict.sidecar.json**(`fm-sidecar-envelope-v1`,runner 写 tmp+rename):
  native_facts 全部字段 + `target/variant/proof_mode/canonical_baseline_id/inputs_sha256/
  script_sha256/tool/fm_shell_rc(真实进程 rc)`。
- **validator** 除读 envelope 外,还接收 runner **再传一次**的 `actual_rc` 与外部 `expectation`,
  三方交叉(envelope 自报 rc == actual_rc == 0)。

## native facts 采集查询(冻结绑定; 除注明者外均 3A.1/3A.2 实证——
## combined unread 查询 `-not_compared -status unread` 的组合形态待 Step 3B 首个 smoke 实测,
## man 已确认两选项均存在)

| 字段 | 确切查询 |
|------|----------|
| `native_verdict` | `get_app_var verification_status`(只读; MATCHED/GUIDE 非终态→拒) |
| `objects.unmatched_ref/impl` | `report_unmatched_points -reference|-implementation -list`(**默认=主集**; 3A.2 实证 llength 与 Matching Results unmatched compare 计数精确一致; `-status none` 会净化 const 等真实 unmatched→**禁作主集**) |
| `objects.unmatched_unread_ref/impl` | `... -status unread -list` |
| `objects.matched_unread_notcompared_pairs` | `report_matched_points -not_compared -status unread -list`(**必须带 -not_compared**: 仅 -status unread 在 verify_unread=true 会话返回已验证通过的 pair, 不能再称 Not-Compared——3A.2 实证) |
| `objects.matched_dont_verify_pairs` | `report_matched_points -status dont_verify -list` |
| `objects.unmatched_dont_verify_ref/impl` | `report_unmatched_points -r|-i -status dont_verify -list` |
| `objects.unmatched_bbox_output_ref/impl` | `... -point_type bbox_output -list` |
| `objects.unmatched_bbox_input_ref/impl` | `... -point_type bbox_input -list` |
| `objects.unmatched_primary_input_ref/impl` | `... -point_type input -list` |
| `objects.matched_blackbox_pairs` | `report_matched_points -point_type bbox -list`(唯一原生 pair 来源) |
| `objects.interface_only_ref/impl` `unresolved_blackbox_ref/impl` `empty_blackbox_ref/impl` | `report_black_boxes` 严格解析(下节文法) |
| `stats` | `report_status -short` 严格解析 + 各 `-list` llength 交叉 |
| `entry_appvars` | `get_app_var` 逐项读回**有效值**(非声明值) |

计数字段 = 对应列表 `llength` 的派生值(同源同单位); 不同 status/type 集合有**重叠**
(bbox 点含于默认主集, 3A.2 bbout_probe 实证 default=none∪special-status), **不可相加**。

### report_black_boxes 文法契约(fail-closed)

- 段头两种(3A.2 实证): unresolved 实例在 `#### TECH LIBRARY - {r,i}:/FM_BBOX`;
  empty/interface-only 实例在 `#### DESIGN LIBRARY - {r,i}:/WORK`。解析器两种都必须认。
- flag 只接受 `i`(interface_only)/`u`(unresolved)/`e`(empty); **其余 s/ut/cp/ir/f/m/\*/L
  一律 ERROR**——emitter 拒产 native_facts, 整个 run 判 ERROR, 不得静默漏掉。
- **FM-184/FM-249 关系(十审纠正, 空报告实证 strict_full/black_boxes_default.out)**:
  FM-184 是报告头, **必须存在**; FM-249 **可与 FM-184 共存**表示空集, 此时**不得有任何
  实例块**; 非空时**不得有 FM-249**, 且严格验证 flag、`Instances : N of M` 的 N==M、
  精确消费 N 条路径。(此前"互斥"的说法写反——按错误文法 Step 3B 会把正常的零黑盒
  strict 会话误判 ERROR。)
- pair 的 Tcl 列表语义解析(无空格元素不带花括号); failing pair 允许空侧 `{{r:...} ""}`。

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
| `native_facts_sha256` | 小写 64-hex, **密码学绑定** native_facts.json 文件字节(validator 重算比对; native 的 verdict/stats/unmatched/objects/qualifications/entry_appvars 还须与 envelope 逐项一致; 原始 native facts 只读保留, runner 不得改写) |
| `stats` | `{passing, failing, unverified, aborted, unread_notcompared}`,各为非负 int 非 bool |
| `unmatched` | `{compare_ref, compare_impl, unread_ref, unread_impl, bbout_ref, bbout_impl}` 同上 |
| `objects` | **observed-facts 21 字段**(只装 FM 真返回的事实): 3 个 pair 列表 `matched_blackbox_pairs` / `matched_unread_notcompared_pairs` / `matched_dont_verify_pairs`(=[{ref_path,impl_path}], 仅 report_matched_points 来源允许 pair);9×2 个两侧独立排序唯一 path 列表: `interface_only_*` / `unresolved_blackbox_*` / `empty_blackbox_*` / `unmatched_*` / `unmatched_unread_*` / `unmatched_dont_verify_*` / `unmatched_bbox_output_*` / `unmatched_bbox_input_*` / `unmatched_primary_input_*`。路径须**严格在 top 之下**(禁抽象 top 自身);拒 Unicode Cc/Cf |
| `entry_appvars` | **有效值明文**(str→str): 必须键 = unread 六元组 + `hdlin_unresolved_modules` + `hdlin_interface_only` + `verification_merge_duplicated_registers`; 可选键限"允许 appvar 注册表"(见下节, 之外 → ERROR);native/envelope/expectation 三方精确一致 |
| `qualifications` | `{dont_verify_objects, elab147, relaxed_appvars}`(均为对象列表;elab147 列出被降级模块,非 bool) |

JSON 层拒:NaN/Infinity(递归)、duplicate key(object_pairs_hook)。
文件层拒:symlink/FIFO/socket 等非常规文件,sidecar 与 expectation 同规。

## entry appvars 契约(九审补丁3 + 十审阻塞2)

- **必须键 = 完整 unread 六元组 + 结构三键**(仅绑 1 个 unread 变量会"三方同漏":
  pin/custom Tcl 可改其余五个悄悄改变证明语义):
  `verification_verify_unread_compare_points` /
  `verification_verify_matched_unread_compare_points` /
  `verification_verify_unread_bbox_inputs` / `verification_verify_matched_unread_bbox_inputs` /
  `verification_verify_unread_tech_cell_pins` / `verification_verify_unread_tech_cell_pg_pins`
  + `hdlin_unresolved_modules` + `hdlin_interface_only` + `verification_merge_duplicated_registers`。
- **有限"允许 appvar 注册表"**(可出现, 按目标绑定; 覆盖当前 pin/custom Tcl 实际修改的):
  `verification_assume_reg_init` / `verification_set_undriven_signals` /
  `verification_propagate_const_reg_x` / `verification_blackbox_match_mode`。
  `verification_failing_point_limit` **仅 diagnostic-full 允许**。
  **注册表之外的键 → ERROR**(未知 proof-affecting set_app_var 不放行; emitter 侧对
  session 内全部 sourced Tcl 扫描 `set_app_var`, 名字不在注册表 → 拒产 native facts)。
- **有效值读回时点**: 所有 pin/custom Tcl 执行后、`verify` 前, 逐项 `get_app_var` 读回
  **有效值**(非声明值)写入 native facts。
- **305 统一冻结执行语义**(validator 硬编码): `verification_verify_unread_compare_points=false`
  (端口可观察功能等价; 3A.2 实证 true 会把 unmatched const 与空串配对判 FAILED, 结构上不可能过。
  **这不是 waiver**: strict 契约不变, 任一 unread 非空仍 PARTIAL——Bku 因此仍非 clean strict
  success); `hdlin_unresolved_modules=black_box`。
- **按目标绑定**(不得声称全部相同): `verification_merge_duplicated_registers`(fm_eq.tcl 真实
  读取 FM_MERGE_DUP, 声明值=实际语义——此前 Makefile 声明 false 而 Tcl 硬编码 true 的断链已修)、
  `hdlin_interface_only`(strict/shadow 下必须为空串, 非空 → ERROR)。
- **信任关系**: 无需为单个 appvar 增设 hash 字段——最终 305 manifest 绑定**整个 expectation
  文件的完整 SHA-256**, appvar 明文值经由该文件 hash 获得完整性; validator 只做三方精确
  相等 + 冻结语义/注册表检查。

### APPVAR_SPEC 值域表(十一审, 唯一权威; 枚举/默认逐页核对 V-2023.12-SP3 man cat3)

| 键 | 值域 | 冻结值/默认 | 签核效果 |
|---|---|---|---|
| unread 六元组 | `true`\|`false` | 冻结 `false,false,false,true,true,true`(fm_eq.tcl 显式全量设置, 后三者=工具默认钉死防版本漂移) | 统一执行语义, 非 waiver |
| `hdlin_unresolved_modules` | `black_box` | 冻结 `black_box` | 统一执行语义 |
| `hdlin_interface_only` | strict/shadow: 空串; assembly: 规范化 module list(裸标识符单空格分隔, 无花括号) | — | assembly 专用, policy 绑定 |
| `verification_merge_duplicated_registers` | `true`\|`false` | 按目标绑定 | 非放宽(十审 GO) |
| `verification_assume_reg_init` | `None`\|`Conservative`\|`Liberal`\|`Auto`\|`AutoMatched`(大小写不敏感) | 默认 `Auto` | **非默认=放宽**→须入 relaxed_appvars |
| `verification_set_undriven_signals` | `BINARY:X`\|`BINARY`\|`0`\|`1`\|`0:X`(X/Z 自 S-2021.06 停用不入域) | 默认 `BINARY:X` | 非默认=放宽→须入 relaxed_appvars |
| `verification_propagate_const_reg_x` | `true`\|`false` | 默认 `false` | 非默认=放宽→须入 relaxed_appvars |
| `verification_blackbox_match_mode` | `any`\|`identity` | 默认 `any` | 非默认→须入 relaxed_appvars(保守一律申报) |
| `verification_failing_point_limit` | 规范化十进制(`0`=不限, 无前导零) | 工具默认 20 | **仅 diagnostic** |

放宽值**未声明**进 `qualifications.relaxed_appvars` → ERROR(observed facts 不自洽);
声明后 strict/assembly 经 quals_any 判 PARTIAL——**不能仅靠 expectation 绑定升级 clean
success**。三方一致只证"说法一致", 值域闭环证"值合法且符合签核政策"。

## 观察事实 vs 政策映射

- **native facts 只装观察事实**; emitter 按 expectation 回填 pair = 配置自报 = 禁止。
- **id 与 waiver-pair 属 expectation policy**: allow 四类别
  `{unresolved_blackbox, interface_only, empty_blackbox, unmatched}` 各为
  [{id, ref_path, impl_path}] 映射。**双射约束**: 每类别 id/ref_path/impl_path 各自唯一;
  跨类别同 id 必须映射同 pair; 全局 ref→(impl,id)/impl→(ref,id) 唯一。
- **pair 分类**(九审): `matched_blackbox_pairs` 由 validator 按独立采集的三类实例集合分类
  (两端同属 iface / 同属 unresolved / 同属 empty);实例集合类别重叠、pair 混类/未知类/仅一端
  命中 → **ERROR**(observed facts 不自洽, 先于 policy 比对)。分类后各 pair 集与对应 policy
  **精确相等**(实例正确但 pair 为空的假绿堵死)。
  实证锚: NewIFU 21 pair↔21+21 'i' 实例、IMSIC 8↔8+8 'u'、DCacheWrapper 1↔1+1 'e'。
- **zero-only**(九审): `unmatched_bbox_output/bbox_input/primary_input` 六列表**必须为空**,
  非空一律 PARTIAL(两模式), 不被 generic allow.unmatched 吸收, 不得对称升级(FM 无原生 pair)。
- **计数绑定**(九审+十审): `compare_* == len(unmatched_*)`、`unread_* == len(unmatched_unread_*)`、
  `unread_notcompared == len(matched_unread_notcompared_pairs)`、`bbout_* ==
  len(unmatched_bbox_output_*)`; 不一致 → **ERROR(corrupt_sidecar, 所有模式)**
  (计数是列表 llength 的派生值, 自相矛盾只能是损坏/篡改; 与本文判定顺序第 5 条一致)。
- **dont_verify 观察对象**(pair+两侧点集)一律按 qualification 处理, v1 无 policy 通道。

## WAIVED 不进 sidecar(九审补丁4)

native FAILED 是**在 sidecar 结构完整性校验(类型/三方一致/count-list 绑定)通过后**的
最高优先级观察事实(损坏 sidecar 先判 ERROR; DCacheWrapper fmbb 实证: 人读日志打印 WAIVED 而
verification_status=FAILED)。**sidecar/validator 不存在可升级的 WAIVED 通道**: 管理豁免放
独立 ledger, CLI 仍非零, 305 sweep 不算通过。

## 安全读取(五/六审: TOCTOU 消除 + FIFO fail-fast)

native/envelope/expectation 一律 `os.open(O_NOFOLLOW|O_CLOEXEC|O_NONBLOCK)` 单次打开(FIFO 不阻塞挂死)+ 同 fd `fstat`(仅 regular 读, 64MB 上限)
+ 一次读 bytes;对**同一字节缓冲**同时计算 SHA 与解析 JSON。

## expectation(外部权威 manifest,不可选,同等严格校验)

`{run_id, target, top, variant, proof_mode, canonical_baseline_id, ref_digest, impl_digest,
script_digest, tool_digest, entry_appvars, allow}`。
- 身份字段 token 校验、digest 64-hex 校验与 sidecar 同规。
- `allow` 四类别(类别不可互换); **strict/shadow/diagnostic 的 allow 必须全空**。
- `entry_appvars` 同 envelope 规则(**九个必选键 + 注册表键**, 过 APPVAR_SPEC 值域),
  与 envelope/native 精确一致。
- 读取用与 sidecar 相同的 strict loader。

## validator 判定(fail-closed)

verdict ∈ {SUCCEEDED, FAILED, PARTIAL, SHADOW_CHECK, DIAGNOSTIC, UNRUN, ERROR}

1. expectation 自校验 → 不合规 ERROR。
2. envelope strict-load + 全字段强类型(appvar 必须键/注册表含内)→ 违规 ERROR。
3. expectation 精确相等(身份 6 项 + 4 digest + entry_appvars)+ 冻结语义
   (unread=false / unresolved=black_box / strict 下 interface_only 空 / diag 专属键
   只许 diagnostic)→ 违规 ERROR。
4. rc 三方交叉 → 违规 ERROR。
5. **计数-列表绑定 4 组(十审阻塞3)**: count/list 自相矛盾 = **损坏 sidecar**,
   **所有模式**(含 shadow/diagnostic, 先于 NOT_RUN/FAILED)→ ERROR。
6. native: NOT_RUN→UNRUN;FAILED/INCONCLUSIVE→FAILED(**最高优先级, 无任何升级通道**)。
7. `failing != 0` → FAILED;`passing <= 0` → ERROR(空证明)。
8. 模式:
   - **diagnostic-full** → DIAGNOSTIC;**shadow** → SHADOW_CHECK(非签核分类,
     观察事实完整保留在 sidecar 中, 不被 zero-only 改判)。
   - **zero-only 6 列表是证明政策**(非结构校验): strict/assembly 非空 → PARTIAL。
   - **signoff-strict**: unverified/aborted/unread/unmatched 计数/objects 全 21 字段/
     qualifications 任一非零/非空 → PARTIAL;否则 SUCCEEDED。
   - **assembly**: ①数量对称 ②pair 三类分类(重叠/混类/未知/单端→ERROR) ③观察集合==policy
     投影(unmatched/iface/unresolved/empty 各 ref/impl 集) ④分类 pair 集==policy(三类各自)
     ⑤qualifications 全空 —— 全部满足才 SUCCEEDED,否则 PARTIAL。

只有 `SUCCEEDED ∧ signoff-strict` = 无条件可替换等价;`SUCCEEDED ∧ assembly` = 仅本层 glue
等价(须叠加子模块各自 strict 证明)。

## Step 3B acceptance gate(十一审裁定; emitter 实现的验收线, 非冻结前置)

emitter 交付必须**实际执行并入库证据**(不能只靠静态 grep/代码审读):

1. **FM-184 状态机测试**: 空报告(FM-184+FM-249 共存, 无实例块)/ 非空(无 FM-249, flag
   严格、N==M、精确消费 N 条路径)/ 未支持 flag(s/ut/cp/ir/f/m)→ 拒产 native facts,
   三种形态各至少一个真实会话或字节级 fixture。
2. **运行期 appvar 拦截**: session 内全部 sourced Tcl(pin/custom)的 `set_app_var`
   在**运行期**被扫描/拦截, 名字不在注册表 → 拒产 native facts(演示一个真实拦截)。
3. **combined unread 查询实测**: `report_matched_points -not_compared -status unread -list`
   在 `verification_verify_unread_compare_points=false` 与 `true` 两种会话下各执行一次,
   实证其返回是否严格限于 Not-Compared(3A.2 已证仅 `-status unread` 在 true 会话
   返回已验证 pair)。
4. **真实 rc 与 readback**: sidecar 全链捕获真实进程 rc(runner 传入+envelope 自报+validator
   三方交叉), appvar 有效值经 `get_app_var` 读回(pin/custom Tcl 后、verify 前)非声明值。

## closure digest 算法(可复现定义)

- **ref/impl closure** (`inputs_sha256.*`) = `closure-v1`:该侧 FM 读入的全部源文件按
  LC_ALL=C 相对路径排序,逐文件 `relpath<TAB>size<TAB>sha256<LF>`,再追加固定顺序的语义要素行
  (`DEFINE=...`/`INCDIR=...`/`MERGE_DUP=...`/`FIELD_MAP_SHA=...`/`PINS_SHA=...`/`MODE=...`),
  对完整字节流 SHA-256。
- **script closure** (`script_sha256`) = fm_eq.tcl 与全部被 source 的 tcl(pre/pins/custom)
  按 source 顺序串接后 SHA-256。
- **tool digest** = sha256(fm_shell 实际可执行)。
- 生成器 `fm_closure_digest.py`(步4)为 expectation 与 envelope 两侧共用。
