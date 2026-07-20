# Step 3B smoke v5(2026-07-20, 验收五审三门修复后从干净实现提交重跑)

> 五审 NO-GO 的三门(PARSER_GATE / SNAPSHOT_CLOSURE_GATE / ARCHIVE_VERIFIER)全部修复;
> v7 契约未动。证据 6 会话从 tracked_dirty=0 的实现提交经 detached clean worktree 执行。
> 锚: implementation_commit=0bfb2d0c, evidence_commit=0fcd1fe8, verifier=98f95ec。

## 五审三门修复与复验

### 1. parser 不接受过滤/畸形报告(PARSER_GATE)
- **拒绝所有 option header**: 全量 `report_black_boxes` 无 option 续行;`-interface_only`
  等过滤报告带 ` -option` 续行 → 拒(防隐藏 unresolved/empty 类)。真实 iface 过滤报告
  实测被拒;'i' flag 正样本改用**默认全量报告**(assembly_iface 的 black_boxes_default)。
- **header 五字段各恰一次 + 顺序固定**(Report/Reference/Implementation/Version/Date):
  乱序/重复拒。
- **TAIL 恰单行且严格 == "1"**:0/-7/多整数拒(emitter 改回 plain `redirect`——
  report_black_boxes 自身 stdout 以单 "1" 收尾,五审实证;puts 包裹会产生两个 "1")。

test_bbox_parser.tcl **48/48**(五审新负例 7 + 一~四审全保留 + 真实字节)。

### 2. snapshot closure 绑真实原始字节(SNAPSHOT_CLOSURE_GATE)
- **`open rb` 原样字节快照 + digest**:消除 locale 二次编码(此前默认编码读再
  convertto utf-8,致中文 UTF-8 字节二次编码,frozen 与 snapshot hash 不同);
  **实测 frozen fm_eq.tcl 与其 snapshot hash 现完全一致**。
- pin 执行按 UTF-8 解码**同一缓冲**(`interp eval [encoding convertfrom utf-8 $rawbytes]`)。
- ledger 记 `{orig, snap, sha256(原始字节)}` 全内容;`sidecar_verify_snapshot_ledger`
  逐字段 + 顺序 + 唯一 + 快照实际字节 hash 核对(**不再只比行数——A/B 两行都改指 A 现拒**)。
- runner 复算每快照 sha256 == 台账 hash(不符 → INFRA_FAIL);closure list 3 列。

test_intercept.tcl **21/21**(+ AA 篡改检出:closure_row_mismatch)。

### 3. archive verifier 语义化(ARCHIVE_VERIFIER)
`step3b_archive_verify.py`(Python,`.sh` exec 委托):
- JSON 严格解析(native={} / 非法 JSON 拒);
- TOOLS 严格 schema:键唯一;`worktree_head_pre/post == impl_commit == expected`;
  tracked_dirty 全 0;**infra 行 sha256 逐条 == `git show <expected>:<相对路径>`**(绑定
  真实提交字节,≥5 条);
- **三个 native 会话实跑提交态 validator**,交叉 verdict == 期望(PARTIAL/ERROR/PARTIAL);
- fm_shell_rc 三处一致(envelope/文件/0);native_facts_sha256 绑定;
- reject 会话:native_facts 缺席 + RUNNER_RC==5 + NO_NATIVE_FACTS + untracked==注入刺激数;
- 集合精确相等 + symlink 拒。

**test_archive_check.sh 5/5**:四类曾 rc=0 的伪造全 FAIL(空 MANIFEST 六目录 /
篡改 TOOLS 自洽清单 / **伪造 native JSON={}+rc=999+RESULT** / reject 塞 native_facts)
+ 真实证据正样本 PASS。

## 会话汇总(rc 契约 1/1/5/5/5/1)
| 会话 | 判定 | rc | 关键 |
|---|---|---|---|
| bku_strict | PARTIAL(strict unread) | 1 | pin 经 child interp,BKU_PINS 打印 |
| bku_unread_true_probe | ERROR frozen_semantics | 1 | script digest 独立 |
| intercept_direct/dynamic/nested | NO_NATIVE_FACTS | 5 | child guard 拒产 |
| imsic_strict | PARTIAL(strict_has_objects) | 1 | 'u' 8+8 |

语义 archive 验证:6 会话 bad=0;全六会话 main_tracked_dirty=0、head 前后一致。
回归:validator 115/115 + parser 48/48 + intercept 21/21 + archive 5/5。

## 限界(不变)
smoke expectation 同批 digests 只验机制链路(外部独立钉死=305 manifest 绑 expectation
文件 SHA-256);fmbb/custom 配方未接线;elab147 恒 []。
