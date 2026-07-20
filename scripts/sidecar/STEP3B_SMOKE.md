# Step 3B 首轮 smoke(2026-07-20, 冻结点 180c1a1 之上; 契约 = SIDECAR_SCHEMA.md v7 不可静默修改)

交付: 原子 emitter(`fm_native_emit.tcl`, fm_eq.tcl 三钩集成: 拦截/读回/emit)+ closure
digest 工具 + runner(`fm_sidecar_run.sh`, envelope 原子写 + validator 调用)。
生命周期按 v7: 全查询→内存解析→JSON→独占 tmp 创建(EXCL)→flush/close→**no-force rename**;
任何错误删 tmp 并 exit 4(实测两次 emit 失败均无部分产物残留)。

## acceptance gate 实测结果(四项)

### 1. FM-184 状态机 — `test_bbox_parser.tcl` 10/10(tclsh, 纯 Tcl 解析器不依赖 fm)
真实字节 4 形态: 空(Bku, FM-184+FM-249 共存, 全空)/ 'u'(IMSIC 8+8)/ 'e'(DCacheWrapper
1+1)/ 'i'(NewIFU 21+21, 两段头文法);合成负例 6: **未支持 flag 's' → ERROR**、FM-249 带
实例块、N≠M、缺 FM-184、超 N 路径、非空却无块。live 路径: bku_strict(空)与
imsic_strict('u')真实会话经同一解析器产 native facts。

### 2. 运行期 appvar 拦截 — `intercept_demo` 会话
fm_pins_pre.tcl 含 `set_app_var verification_timeout_limit`(注册表外)→ **会话运行期
exit 3, 拒产 native facts**(证据: fm.log 的 SIDECAR_ERROR 行 + RESULT=NO_NATIVE_FACTS
rc=3)。发生在 fm_shell 会话内 source 之前, 非 CI 静态 grep。

### 3. combined unread 查询 false/true 两会话(API 实证闭环)
| 会话 | `-not_compared -status unread -list` | 判定 |
|---|---|---|
| bku_strict(unread=false, 冻结语义) | **恰 1 条** Not-Compared pair(=stats.unread_notcompared=1) | PARTIAL(strict unread≠0, 审定预期) |
| bku_unread_true_probe(XSSV_HOME 探针树, script digest 如实不同) | **空**(unread 全部转正验证后严格限于 Not-Compared——对照 3A.2 裸 `-status unread` 在 true 会话返回 20 条已验证 pair) | **ERROR frozen_semantics**(readback true 被 expectation lint 拒, fail-closed 全链生效) |

### 4. 真实 rc 与 readback
- `fm_shell.rc` 由 ut_common.mk 落盘(真实进程 rc=0), envelope 自报 == actual_rc 三方交叉过。
- readback 于 pin/custom Tcl 后、verify 前逐项 `get_app_var`: bku_strict 的
  `merge_duplicated_registers=false` 为**有效值**(FM_MERGE_DUP 绑定链: Makefile 声明→
  fm_eq.tcl 读取→FM 生效→readback→三方绑定), 六元组=冻结值。

## 会话汇总(step3b-evidence/, 每会话 MANIFEST)

| 会话 | native | validator | 说明 |
|---|---|---|---|
| bku_strict | SUCCEEDED(2055p, unread 19/19, nc=1) | **PARTIAL** strict_unread | 审定预期: Bku 非 clean strict |
| bku_unread_true_probe | SUCCEEDED(2075p, unread 0/0) | **ERROR** frozen_semantics | 探针被拒=fail-closed |
| intercept_demo | (拒产) | NO_NATIVE_FACTS rc=3 | 运行期拦截 |
| imsic_strict | SUCCEEDED('u' 8+8, pairs 8) | **PARTIAL** strict_has_objects | 正式签核须 assembly+policy |

计数-列表绑定全自洽(unread 19==19、nc 1==1、compare 0==0)——emitter 按"计数=llength
派生"实现, validator 交叉通过。

## smoke 限界(诚实声明)

- expectation 由同批 digests 生成(**只验证机制链路**, 不构成外部独立钉死——外部性由
  305 manifest 绑整个 expectation 文件 SHA-256 提供)。
- emitter 尚未接线 fmbb/custom 配方(DCache/DCacheWrapper/L2TLBWrapper/MemBlock/NewCSR);
  elab147 恒 [](标准入口无 ELAB 降级, 有即 elaboration 失败拒产, 注释成文)。
- 3B 期间实证补入两条 emitter 解析放行(均有字节证据): 空 dont_verify 报告的
  `Don't verify points: None` 行; redirect 捕获尾部的命令返回值整数回显行。
