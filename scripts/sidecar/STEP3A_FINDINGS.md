# Step 3A: Formality 查询 smoke 实证结果(2026-07-19)

> **SUPERSEDED(2026-07-20)**: 本文为 Step 3A 探索期发现记录, 其中 API/文法结论已被审定修正并冻结进 `SIDECAR_SCHEMA.md`(v7 权威)。冲突处一律以 SIDECAR_SCHEMA.md 为准(已知被修正点: 3A1 的"455 单位不符"是 off-by-one; FM-184/FM-249 非互斥)。

> 审查批准 STEP3A=GO。在 **Bku(signoff-strict)** 与 **Ftq(assembly)** 的真实 FM 会话
> (标准 fm_eq.tcl,verify 完成后)执行 16 个候选查询,dump 原始输出。
> 工具: Formality V-2023.12-SP3。原始产物: /tmp/step3a_{Bku,Ftq}/(16+16 dump + 完整 fm.log)。

## 字段 → API 表(实证)

| native 字段 | 确切命令 | 返回语义(实测) | 失败行为 |
|---|---|---|---|
| `matched_blackbox_pairs` | `report_matched_points -list` | **Tcl 返回值** = pair 列表,元素形如 `{{r:/WORK/<top>/...} {i:/WORK/<top>/...}}`(Bku 280KB/Ftq 2.09MB)。**含全部 matched 点**(DFF/Port/BBPin),无类型字段 → 过滤出黑盒 pair 须与 black_boxes 实例路径前缀交叉(Step 3B 设计点,见下) | rc=0 即使空;rc≠0 → 不写 native_facts |
| `unmatched_ref` | `report_unmatched_points -reference -list` | **Tcl 返回值** = 换行分隔 point names(Ftq 实测 2 点: `copied_last_cycle_bpu_in_REG_5/6_reg`;空=空串) | 同上 |
| `unmatched_impl` | `report_unmatched_points -implementation -list` | 同上(Ftq 实测空串——两侧独立,真实不对称数据) | 同上 |
| `unresolved_blackbox_*` | `report_black_boxes -unresolved` | **stdout 报告**(返回值仅"1")→ 必须 `redirect -variable` 捕获。格式: FM 标准头(`Report : black_boxes` + Reference/Implementation/Version/Date)+ `FM-184` info + 逐模块块: 标志列(`u`=unresolved)+ 模块名 + `Instances : N of M` + **两侧**实例路径(r:/ 与 i:/,Ftq 实测 30 行 i:/) | 空集 = **`FM-249` info 行**(可解析空标记);无 FM-184/FM-249 任一 → 解析 ERROR → 不写 native_facts |
| `interface_only_*` | `report_black_boxes -interface_only` | 同上格式;Ftq 实测 FM-249(本会话 interface_only 未生效——FM_MODE 未设时 fm_eq.tcl 门控拒注入,数据点见下) | 同上 |
| `stats.*`(passing/failing/…) | 末次汇总表(既有解析)+ `report_status` | stdout;沿用 envelope 层已验证的表解析 | 表缺失 → ERROR |
| `unmatched.compare_*` 等计数 | `R(I) Unmatched ... compare points` 行 | **与 -list 点名单同单位**:Ftq 实测 ref 2 点 = 列表 2 行(计数↔列表精确相等可交叉,validator 七审规则获得实证支撑) | — |

## 死路(实证排除)

- `find_cells -filter "is_black_box==true"`:**CMD-010 unknown option '-filter'**——本版 fm_shell 无此 filter 语法,结构化 find 路径不可用。
- `report_black_boxes` **无 -list**(help 实证单行 usage);只能 stdout 报告 + 严格文法解析。
- 默认(无 -list)的 report_matched/unmatched_points:stdout 人读表,返回值"1"——不用。

## Step 3B 设计点(冻结 schema 前须定)

1. **黑盒 pair 过滤**:`report_matched_points -list` 无类型字段。matched_blackbox_pairs 的采集 = 全 matched pair 中**路径落在 black_boxes 报告实例路径之下**的子集(前缀匹配);两份数据同会话采集,fail-closed:black_boxes 解析失败则整体不产出。
2. **文法严格性**:black_boxes 报告解析须锚定 FM-184(有报告)/FM-249(空)标记,标志列仅认已知值(`u` 等,遇未知标志 → ERROR)。
3. **原子性**:任一查询 rc≠0 或解析失败 → **不 rename** native_facts.json(tmp 丢弃),不默认空集合继续。

## 顺带实证发现(影响 305 manifest)

Ftq 在标准 `make fm` 会话有 **2 个真实 unmatched ref 点**(merge-family 副本)——在 sidecar 规则下
Ftq 需在 assembly allowlist 声明这 2 点(或修 RTL/pin),否则 PARTIAL。这是 observed-facts 模型
第一次在真实目标上产生可执行的整改信号。
