# Step 3A.2 补测实证结果(2026-07-20)

> 3A.1 审定(PARTIAL_PASS)后的补空。5 会话全部 clean 入口 + canonical golden;
> 证据链修复: session.tcl+smoke.tcl 本体入证据(hash 进 MANIFEST), 大文件规则
> **先于** MANIFEST 生成(>100KB → `<f>.fullhash`(name/size/sha256)+`<f>.sample`, 原件删除,
> 显式分名不冒充), MANIFEST 最后生成+runner 末尾自校验(5 会话全部 不符=0)。
> 3A.1 的三份 manifest 已同步修复(截断文件改名 .sample, manifest 重建, 自校验=0)。

## 0. 认错记录(审定采纳)

3A.1 findings 的"455 单位不符"结论**错误**: 是行数统计+文件末尾无换行的 off-by-one。
本次直接用 Tcl `llength` 采集(smoke v3 的 SMOKE 行输出 ret_llen), 实证:

| 会话 | default -list llength (ref/impl) | Matching Results |
|---|---|---|
| strict_full | 1 / 456 | 1(456) |
| bbout_probe | 579 / 204 | (失败会话) |

**默认 -list 与 unmatched compare 计数精确一致, 是主集。**

## 1. 决定 1 实证: 分类原始集合(本次实际执行, 3A.1 只是纸面声称)

strict_full(Bku, SUCCEEDED)分解:

| 查询 | ref | impl | 结论 |
|---|---|---|---|
| default | 1 | 456 | 主集 |
| `-status const` | 1 | 456 | **Bku 的全部 default unmatched 都是 const 寄存器** |
| `-status none` | 0 | 0 | 审定的拒绝理由被实证坐实: none 把真实 unmatched 全过滤 → Bku 会被净化成 0/0 假绿 |
| `-status unread` | 17 | 17 | unread 集独立于 default(default 不含 unread) |
| `-status dont_verify` | 0 | 0 | rc=0 语法可用 |
| `-point_type bbox_output/bbox_input/input/port` | 0 | 0 | rc=0 全部合法枚举(本设计空) |
| matched `-status unread` -list | 3 对 | | **Not-Compared unread pair API 可用** |

bbout_probe(仅 impl 侧 `set_black_box xs_bku_clmul` 的标注探针, FAILED)给出**非空 bbox 点型样本**:
`unm_impl_bbout=64 / unm_impl_bbin=139 / unm_ref_bbout=0`(非对称如设计), 且
default(204) = none(204) + const(0), ref default(579) = none(578) + const(1)
→ **default = none ∪ special-status, bbox 点型点含于 default** 的包含关系实证。

## 2. 决定 2 实证: 非空 unresolved + fmbb empty 样本(冻结前置样本齐)

- **unresolved_sample(IMSIC, SUCCEEDED)**: 'u' flag 实证; **8 matched bbox pair ↔ 8+8
  'u' 实例精确一致**(IntFile×7+IMSICGateWay)——pair-实例覆盖关系从 interface_only(NewIFU
  21↔21+21)扩展到 unresolved 类。完整报告字节入库。
- **fmbb_empty(DCacheWrapper fmbb 配方)**: DCache 两侧 **'e' (Empty design module)** flag 实证
  → empty_blackbox 类真实存在, schema 须有此类(fmbb 入册前提)。matched bbox pair 1 对
  ↔ 1+1 'e' 实例。
- **文法关键差异(解析器必须处理)**: unresolved 实例列在 `#### TECH LIBRARY - {r,i}:/FM_BBOX`
  段; empty/iface 实例列在 `#### DESIGN LIBRARY - {r,i}:/WORK` 段。段头不同, 不能只认一种。
- **fmbb 会话同时抓到 waiver fail-open 现场**: FM_RESULT 打印 `Verification WAIVED`
  而 `verification_status=FAILED`——sidecar 化后 native_verdict 将如实记 FAILED,
  waiver 只能作为 expectation policy 的显式 WAIVED 判定, 不可能再冒充 SUCCEEDED。

## 3. fm_eq.tcl:40 契约冲突的实证解答(strict_unread_on 探针)

`verification_verify_unread_compare_points true` 下 Bku strict → **FAILED, 唯一失败点
`{{r:/WORK/Bku/clmulModule/mul3_0_reg[100]} ""}`**——即那个 unmatched const 寄存器,
FM 把它与**空串**配对后判失败(无 impl 对应物, 结构上不可能通过; 这也实证 failing pair
的 Tcl 文法允许空侧, 解析器必须处理)。同时 17/17 unread 点全部转正被 match(unm_unread
→0/0, matched_unread 3→20 对)且全部验证通过——真实逻辑无差异, 失败仅来自该 const。

**结论与建议(交审查裁决)**: `false` 不宜按 per-run relaxed_appvars 记(否则所有 strict
永远 PARTIAL), 也不能开 `true`(把"impl 须复刻不可读常量寄存器"变成无法满足的义务)。
建议: 把该 appvar 定为**入口冻结基线**(schema 记 entry_appvars 及其 hash, 全 305 一致),
同时 native facts 强制采集 unread 三集合(unm_unread_ref/impl + matched_unread pairs),
policy 可按模块显式上限/清单约束——不隐藏, 但不误伤。

## 4. schema v8 native facts 采集清单(按决定 1-3, 待冻结)

全部来自本次实际执行过的查询(每项: 原始 Tcl list + count=llength):

```
unmatched_ref/impl                 report_unmatched_points -r|-i -list            (主集)
unmatched_unread_ref/impl          ... -status unread -list
matched_unread_pairs               report_matched_points -status unread -list
matched_dontv_pairs                report_matched_points -status dont_verify -list
unmatched_dontv_ref/impl           report_unmatched_points -r|-i -status dont_verify -list
unmatched_bbout_ref/impl           ... -point_type bbox_output -list              (v1: 必须 [])
unmatched_bbin_ref/impl            ... -point_type bbox_input -list               (v1: 必须 [])
unmatched_pi_ref/impl              ... -point_type input -list                    (v1: 必须 [])
matched_blackbox_pairs             report_matched_points -point_type bbox -list   (唯一原生 pair)
bb 实例三类集合                     report_black_boxes 严格解析('i'/'u'/'e' 段, 两段头文法)
native_verdict                     get_app_var verification_status
stats                              report_status -short 严格解析 + 各 -list llength 交叉
```

注: 不同 status/type 集合有重叠(bbox 点含于 default), **不可相加**——各集合独立记录、
独立与 policy 比对。

## 5. validator v8 已按决定 2/3 落地(先于冻结堵审查点名的两个假绿)

- 决定 3: assembly `bbout_ref/impl` **zero-only**(对称非零也 PARTIAL); 原对称即过已删。
- 决定 2: `matched_blackbox_pairs` 保留唯一原生观察事实; validator 按独立实例集合分类
  (两端同属 iface / 两端同属 unresolved; 类别重叠/混类/未知/单端 → ERROR, 先于 policy
  比对); 分类后 pair 集分别与 policy **精确相等**(interface-only 实例正确但 pair 为空
  的假绿堵死)。`allow.blackbox` 改名 `allow.unresolved_blackbox`。
- 测试 81/81(73 累计 + 8 个 v8 对抗: 两个点名假绿 + 混类/单端/重叠/未知类/正样本×2)。
