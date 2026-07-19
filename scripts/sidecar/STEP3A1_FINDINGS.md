# Step 3A.1 补测实证结果(2026-07-19)

> 审查批准的小范围补测。三类会话全部从 **clean xs-signoff 入口**(committed ut_common.mk/fm_eq.tcl,
> FM_MODE 门控)+ **canonical golden**(GOLDEN_RTL 覆盖,不动 worktree symlink)执行:
> `strict_pass`(Bku+pins→**SUCCEEDED**)/ `native_failed`(Bku 去 pins→**FAILED**)/
> `assembly_iface`(NewIFU,FM_INTERFACE_ONLY 5 模块,**非空 interface_only 报告**)。
> 证据: 每会话 53 文件(每 query 的 .ret/.out/.rc 原始字节)+ MANIFEST(sha256)+ ENV + commit 锚,
> 全部入库 step3a1-evidence/。

## 首要收获: clean 入口抓获真洞(已修复)

提交态 `fm_eq.tcl` **不 source FM_PIN_TCL**(pin-source 补丁此前只落 dirty worktree 未提交)——
"唯一权威入口"提交不完整,clean 入口首跑 strict Bku 即 native FAILED(与去 pins 会话产物同尺寸
实证 pins 未生效)。已补 pre/post pin hooks 入库(`1af77ec`),复跑 strict_pass → **SUCCEEDED**。

## 字段 → API 表(v2, 完整绑定)

| native 字段 | 确切命令 | 实证 |
|---|---|---|
| `native_verdict` | `get_app_var verification_status`(只读) | 实测返回 `SUCCEEDED`/`FAILED` 字串;合法值 SUCCEEDED/FAILED/INCONCLUSIVE/MATCHED/NOT RUN/GUIDE(man cat3);**MATCHED/GUIDE 非终态须拒** |
| `matched_blackbox_pairs` | `report_matched_points -point_type bbox -list`(审查指定,官方结构化) | **Tcl 返回值** pair 列表;NewIFU 实测 20 对 `{r:/WORK/NewIFU/expanders_0 {i:/.../u}}`——**Tcl 列表格式:无空格元素不带花括号**,解析必须用 Tcl 列表语义非 brace 正则 |
| `unmatched_ref/impl`(纯 compare 点) | `report_unmatched_points -reference|-implementation -status none -list` | **关键单位发现**: 无 `-status` 的 `-list` 混含 const 寄存器(SUCCEEDED Bku 实测 impl 455 点=其 456 Constant reg)——与"Unmatched compare points R(I)"计数**单位不符**;`-status none`= "all except special types"(排 const/unread/dont_verify)才是与计数同单位的纯 compare 集 |
| `unread` 点集 | `... -status unread -list` | man 实证:默认报告排除 unread,须显式 `-status unread` |
| `dont_verify` 点集(qualification) | `... -status dont_verify -list` | **qualification 采集 API 找到**(原缺口) |
| `bbout`(黑盒输出点) | `... -point_type bbox_output -list` | **bbout 单位对齐 API 找到**——点数与实例数之辩由此消解:直接采集 bbox_output 点集 |
| `unresolved_blackbox_*` / `interface_only_*` | `report_black_boxes -unresolved|-interface_only` + `redirect -variable` | **完整原始字节已入库**(NewIFU 非空 iface 4201B):FM 标准头 + FM-184 + **完整 Legend 图例**(s/i/u/e/*/ut/L/cp/ir/f/m,i=interface_only、u=unresolved 实证)+ 模块块 + `Instances : N of M` + 两侧实例路径;空集=FM-249 |
| stats 交叉 | `report_status -short` + 末次汇总表 | 双源交叉可行(status_short 实测含 `Status: FAILED/SUCCEEDED`) |

## 文法闭环证据(审查三审要求)

- 非空 interface_only 报告完整字节: `step3a1-evidence/assembly_iface/black_boxes_iface.out`(4201B)。
- Legend 全图例入库 → 严格解析可锚定:未知 flag 拒、FM-184/FM-249 互斥、`Instances : N of M` 断言 N==M 且精确消费 N 条路径。
- `redirect -variable` 捕获已实证(.out 文件为完整正文,非返回值"1")。

## Ftq 澄清(审查判定采纳)

3A 的 Ftq 会话来自 dirty 旧入口(无 FM_MODE/interface_only)非有效 assembly 会话;其 2(ref)/0(impl)
unmatched **不能进 allowlist**(assembly 契约要求对称)——只能修 RTL/pin 或保留 PARTIAL。

## schema 冻结前的遗留设计决定(交审查)

1. `unmatched` 计数字段与分类点集的对应:建议 native facts 按 `-status none/unread/dont_verify`
   + `-point_type bbox_output` 分类采集,计数=各自 `llength`(同一来源,天然同单位,不再依赖
   汇总表交叉)。汇总表仅留 stats(passing/failing/…)。
2. matched pairs 归属(unresolved vs interface_only vs 并集):3A.1 实证 NewIFU 的 bbox matched
   pairs 是 interface_only 模块实例(expanders=RVCExpander)——归属可由 pair 路径对 black_boxes
   报告实例集的成员测试分类;或 schema 分两类 matched pairs。**待审查裁决**。
3. bbout 安全规则(审查建议 assembly 要求 bbout_ref==bbout_impl==0)与 bbox_output 点集采集的
   关系:有了 `-point_type bbox_output -list`,可直接以点集对称+声明覆盖判定。**待审查裁决**。
