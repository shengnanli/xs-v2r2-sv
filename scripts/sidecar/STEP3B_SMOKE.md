# Step 3B smoke v2(2026-07-20, 验收一审四阻塞修复后从干净实现提交 bf23893 重跑)

> v1 判定 STEP3B_ACCEPTANCE=NO-GO 的四阻塞全部修复; v7 契约未动。
> 本轮 6 会话全部从 **tracked_dirty=0 的 bf23893** 执行(TOOLS.tsv 逐会话记录
> 实际执行代码 hash + commit + dirty 计数); 证据 = staging 组装 → TOOLS.tsv →
> MANIFEST.tsv → COMPLETE(MANIFEST sha256)→ 原子 rename(no-force), 6 会话
> COMPLETE 全 OK、逐文件自校验全 0 不符(**含拒产会话, 不再缺 manifest**)。

## 四阻塞修复与复验

### 1. parser 真状态机(GATE1)
fail-closed 行分类(非空行必须命中白名单)+ section namespace(路径 side 必须与段头
side 一致)+ `Instances : N of M` 要求 N==M 且 **N>0** + 路径重复 error(禁
lsort -unique 修复)。审查 4 个独立复现全部入 fixture 复验:
缩进非空 block(rev1)/0 of 0 无 FM-249(rev2)/N=1 后顶格追加路径(rev3)/
重复路径折叠(rev4), 另加 side 不一致(rev5)/块外 block(rev6)。
**test_bbox_parser.tcl 16/16**(真实字节 4 形态 + 合成 12)。

### 2. 执行期拦截(GATE2, rename+wrapper)
静态正则扫描废弃。`rename set_app_var` + wrapper: 每次**真实执行**经唯一入口检查,
调用时记账 → readback 覆盖。
- tclsh 对抗 **test_intercept.tcl 7/7**: 动态命令名/eval/嵌套 source 三盲区全落网
  + 注释/字符串免误报 + 合法透传 + 可选键记账。
- **live fm_shell 三会话**(rename 在 fm_shell 中生效的实证):
  intercept_direct / intercept_dynamic(`set c set_app_var; $c ...`)/
  intercept_nested(pin source 内层文件)→ 全部会话运行期 exit 3 拒产,
  SIDECAR_ERROR 入证据, **runner rc=5**。

### 3. script closure 真实 provenance(GATE3)
fm_eq.tcl 运行期记账实际 source 清单 → emit 落盘 `script_closure.list` → runner 据此
算 digest。复验: probe 会话清单如实指 `/tmp/xssv_probe/scripts/fm_eq.tcl`(+探针树
emitter + 实际 pin 文件), **bku_strict 与 probe 的 script_sha256 不同**
(eba88ec4... vs 328170ab...)——v1 的"错误地相同"已消除。

### 4. runner fail-closed rc(GATE4)
契约: SUCCEEDED→0; PARTIAL/FAILED/ERROR/UNRUN→validator rc(非 0);
NO_NATIVE_FACTS→5; 基建失败→2/3/4。本轮实测:

| 会话 | 判定 | runner rc |
|---|---|---|
| bku_strict | PARTIAL(strict unread 19/19, 审定预期) | **1** |
| bku_unread_true_probe | ERROR frozen_semantics(readback true 被拒) | **1** |
| intercept_direct/dynamic/nested | NO_NATIVE_FACTS(执行期拦截拒产) | **5** |
| imsic_strict | PARTIAL(strict_has_objects, 'u' 8+8 须 assembly+policy) | **1** |

## gate-3 API 行为证据(v1 的 PASS_RAW 保持)
false 会话 combined 查询恰 1 条 Not-Compared pair(==stats.unread_notcompared);
true 探针返回**空**(unread 全转正验证后严格限于 Not-Compared; 对照 3A.2 裸
`-status unread` 返 20 条已验证 pair)。本轮 provenance 亦成立(阻塞 3 修复)。

## 限界(不变)
smoke expectation 由同批 digests 生成, 只验机制链路——外部独立钉死由 305 manifest
绑整个 expectation 文件 SHA-256 提供; fmbb/custom 配方未接线; elab147 恒 []
(标准入口无 ELAB 降级, 有即 elaboration 失败拒产)。
