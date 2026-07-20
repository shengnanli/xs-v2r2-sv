# Step 3B smoke v3(2026-07-20, 验收二审四阻塞修复后从干净实现提交 194737e 重跑)

> 二审 NO-GO 的四签核级阻塞全部修复; v7 契约未动。6 会话从 tracked_dirty=0 的
> 194737e 执行。

## 二审四阻塞修复与复验

### 1. parser 完整 phase 文法(GATE1)
`PRE→MARKED→(EMPTY | SEC_HEAD→SEC_TABLE→BLOCKS)`: marker 只认 `Information:` 整行且
计数唯一(**重复 FM-184/FM-249 拒**); section 头限定 `(TECH|DESIGN) LIBRARY - [ri]:/路径`
(**BANANA LIBRARY / i:garbage 拒**); **FM-249 空报告夹带任何 section/block/内容拒**;
缺 Type 表头/缺分隔/悬空 section/零 block section/未知 Information 行全拒。
二审三复现 + 新负例共 10 个入 fixture, **test_bbox_parser.tcl 26/26**(真实字节 4 形态保持通过)。

### 2. appvar guard 无旁路 + phase/写历史(GATE2)
一审 rename+wrapper 的暴露别名已消除——**execution trace 加在 set_app_var 命令本身**:
`__sidecar_real_set_app_var` 不复存在(测试钉死), enter-trace 报错时命令**不执行**
(非法值不生效, 测试断言生效表未变)。新增约束:
- **phase**: trace `match` → 首次 match 后 proof appvar 冻结("先放宽-match-恢复默认"堵死);
- **写历史**: 同名变值重写拒(幂等同值放行); readback 逐项核对==写历史末值(纵深防御)。
**test_intercept.tcl 13/13**; live 三会话(direct/dynamic/nested)全部 execution-trace
拒产(SIDECAR_ERROR 注明 execution-trace), runner rc=5。

### 3. 真实完整 script closure(GATE3)
`trace add execution source` **运行期递归记账所有 source**(嵌套亦触发, tclsh 测试断言
outer+inner 双双入清单; live bku_strict 清单 = 入口+emitter+fm_pins.tcl)。
runner 语义行对齐冻结算法**固定顺序** `DEFINE/INCDIR/MERGE_DUP/FIELD_MAP_SHA/PINS_SHA/MODE`
(自创 SCRIPT_CLOSURE_SHA 已删); PINS_SHA=实际 source 的 pin 闭包 concat sha。
probe 与 bku_strict 的 script_sha256 不同(provenance 保持成立)。

### 4. 提交态证据自包含(GATE4)
- 日志入提交: 证据内改名 `fm_log.txt`(.gitignore 的 `*.log` 不再排除), 6 会话全有。
- **刺激绑定**: runner 预跑提取 FM_PIN_PRE/PIN_TCL 并 copy 入 staging
  (`stimulus_*.tcl`)——**拒产会话的三类刺激全部入证据**(direct/dynamic/nested 可独立
  区分; nested 外层自生成内层文件, 刺激完全由被绑定的外层决定)。
- `step3b_archive_check.sh <commit>`: 从 commit 做 **clean archive** 逐会话验
  MANIFEST 每文件 size/sha + COMPLETE, 结果入库(ARCHIVE_CHECK.txt)。

## 会话汇总(全部审定预期)

| 会话 | 判定 | runner rc | 关键证据 |
|---|---|---|---|
| bku_strict | PARTIAL(strict unread 19/19) | 1 | nc_unread=1 条(gate-3 false 腿) |
| bku_unread_true_probe | ERROR frozen_semantics | 1 | nc_unread 空(gate-3 true 腿); script digest 独立 |
| intercept_direct/dynamic/nested | NO_NATIVE_FACTS | 5 | execution-trace 拒产 + 刺激绑定 |
| imsic_strict | PARTIAL(strict_has_objects) | 1 | 'u' 8+8 + 8 pairs |

回归: validator 115/115 + parser 26/26 + intercept 13/13。

## 限界(不变)
smoke expectation 同批 digests 只验机制链路(外部独立钉死=305 manifest 绑 expectation
文件 SHA-256); fmbb/custom 配方未接线; elab147 恒 [](标准入口无 ELAB 降级)。
