# Step 3B smoke v4(2026-07-20, 验收四审三绕过修复后从干净实现提交重跑)

> 四审 NO-GO 的三类可复现绕过全部修复; v7 契约未动。6 会话从 tracked_dirty=0 的
> 实现提交经 detached clean worktree 执行。

## 四审三绕过修复与复验

### 1. parser 不再错接(PARSER_GATE)
- **flag↔section 类别绑定**: TECH(`/FM_BBOX`)只容 `u`;DESIGN(`/WORK`)只容 `i`/`e`
  (你四条 mispair: DESIGN+u、TECH+i、TECH+e 全拒)。
- **header 绑定唯一正确值**: 报告名必须 `black_boxes`,Reference/Implementation 必须
  `r|i:/WORK/<top>`(FM-184 前三要素未齐拒)。
- **legend 有限文法**: 16 行精确白名单(自证据字节提取),未知 legend 行拒。
- **成功终态必须恰为 TAIL**: FM-184+FM-249 缺最终整数回显不再返回六空集合;
  emitter 用 `puts [report_black_boxes]` 保证回显确定存在。

test_bbox_parser.tcl **40/40**(四审新负例 10 + 一/二/三审全保留 + 真实字节 4 形态)。

### 2. guard/快照不可被被测 Tcl 拆除(GUARD_AND_SNAPSHOT_GATE)
- **pin/custom Tcl 进受限 safe child interp**: 无 file/open/exec/source 权限;
  child 内 `set ::SIDECAR_PHASE setup` 只作用 child 自身、`trace remove` 只除 child 的
  trace——父层 guard/phase/证据目录全不可达。白名单 alias 只暴露 set_user_match /
  set_app_var(**父层 trace 照常拦**)/ get_app_var / puts / report_*;`top` 等只读上下文
  传值注入。
- **受控 source 一次读字节→快照→child 执行同一缓冲**(不再二次打开原路径);嵌套 source
  经同一受控入口(child 内 source alias → 父层 sidecar_pin_source)。
- **快照/清单台账复核**: capture 前 `sidecar_verify_snapshot_ledger` 核对快照文件字节 ==
  父内存台账、清单行数 == 台账条数(执行后篡改快照/清单拒)。

test_intercept.tcl **20/20**(child 拆 guard 无效、无 file I/O、嵌套受控、快照篡改检出、
-encoding 形态、执行时刻快照字节)。**live 三会话**:direct / dynamic(`$c ...`)/
nested(外层经受控 source alias 引用内层 fm_pins_inner.tcl,内层 illegal set_app_var)——
全部父层 execution-trace 拒产,runner rc=5。

### 3. archive checker 语义化(ARCHIVE_VERIFIER)
此前只证"清单自洽"(空 MANIFEST 六目录、篡改 TOOLS+RESULT 后重算清单均曾 rc=0)。现:
- 强制 `expected_impl_commit` 入参;
- 类型化**非空必需 pathset**(native 须 facts/envelope/expectation;reject 须刺激且
  **native_facts.json 必须缺席**);
- 严格解析 TOOLS(worktree head 前后 == impl_commit == expected,dirty 全 0,
  infra hash ≥5 且 64-hex);
- 拒 CLEAN_GATE_FAIL;**RUNNER_RC 结构化回执 == 会话类型期望 rc**。

**test_archive_check.sh**: 两个曾 rc=0 的对抗(空 MANIFEST 六目录 / 篡改 TOOLS+RESULT
自洽清单)现均 FAIL,固化为负测。

## 会话汇总(rc 契约 1/1/5/5/5/1,判定与前轮一致)
| 会话 | 判定 | rc | 关键 |
|---|---|---|---|
| bku_strict | PARTIAL(strict unread) | 1 | pin 经 child interp,BKU_PINS 打印(set_user_match 透传) |
| bku_unread_true_probe | ERROR frozen_semantics | 1 | 探针 frozen 字节入证据,script digest 独立 |
| intercept_direct/dynamic/nested | NO_NATIVE_FACTS | 5 | child guard 拒产,execution-trace |
| imsic_strict | PARTIAL(strict_has_objects) | 1 | 'u' 8+8 |

回归:validator 115/115 + parser 40/40 + intercept 20/20 + archive_check 负测。

## 限界(不变)
smoke expectation 同批 digests 只验机制链路(外部独立钉死=305 manifest 绑 expectation
文件 SHA-256);fmbb/custom 配方未接线;elab147 恒 []。
