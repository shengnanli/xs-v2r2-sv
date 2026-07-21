# INFRA_CLOSURE 轮报告(9 → 4)

单一 orchestrator/integrator 执行。本轮把 INFRA_ERROR 从 9 收到 4,全部为**如实定级**
(ERROR/NO_NATIVE_FACTS → 真 PARTIAL,FM 已证等价的差契约缺口),无强制绿、无 blackbox 绕过。

## 台账(combined_ledger.tsv, 单一 integrator 末端聚合)

| class | 数量 |
|---|---|
| SIGNOFF_PASS | 111 |
| SHADOW_CHECK | 1 |
| PROOF_GAP | **189**(←184, +5) |
| INFRA_ERROR | **4**(←9, −5) |
| UNCONFIGURED(Rob) | 1 |
| **合计** | **306**(305 configured + Rob) |

## 8 个修复(#4–#8;#4/#5 上轮起,本轮 #6/#7/#8)

| # | 目标 | 根因 | 修法 |
|---|---|---|---|
| 4 | Slice, TL2 | FM 多设计层次按**子设计名**报黑盒(`r:/WORK/Directory/mbistPl`),validator 严格 top-下判 bad_path | validator 加 `_bbpath`(允许 `[ri]:/WORK/<id>/...`,禁 `..`/ctrl),仅用于黑盒集;compare 点仍严格 top-下 |
| 5 | Ftq | `hdlin_interface_only` 多行续行留多空格,`_IFACE_RE` 只认单空格 → not_normalized | 分隔符放宽 `\s+`,每 token 仍严格标识符;tab/ctrl 仍拦 |
| 6 | Composer | golden 读 `predictor_stubs.sv`(5 预测器端口空桩)缺在 signoff 树 | `gen_composer_stubs.py` 从 golden `<M>.sv` 模块头逐字生成端口空模块(provenance=G0,与旧桩逐模块端口签名字节一致) |
| 7 | Composer | ref 侧桩路径经 ut_common.mk 前缀 `$(GOLDEN_RTL)/`,runner 外部化 GOLDEN_RTL 后 `../../verif` 断链 | ut_common.mk 加 additive `FM_REF_ABS_<名>`(绝对路径,不加前缀);Composer 桩走此变量→worktree(两侧同读) |
| 8 | DataPath | FM 本身 SUCCEEDED,但 emitter 解析非空 `report_dont_verify_points` 头(无 None,8216 点)→ fail-closed | dont_verify 对象改由权威 `-list` 派生;文本降为 header sanity + 非空⟺-list 非空交叉核验 |

**5 个恢复**(全 COMPLETE 证据,measured=PARTIAL):Slice/TL2(delta5@#4)、Ftq(delta6@#5)、
Composer(delta7@#7)、DataPath(delta7@#8)。测试:validator 123 / parser 56 / intercept 23 /
dont_verify 6 / Step-3B bad=0 全绿。

## 剩余 4 个 INFRA —— 精确诊断 + 待决

| 目标 | 分类 | 诊断 | 推荐 |
|---|---|---|---|
| **L2TlbMissQueue** | 需决策 | strict 下 golden 厂商 RAM 越界读 `FMR_ELAB-147`(`ram_40x47.sv:118`)未抑制 → FM-262 link 致命 → FM-156。**设计如此**:strict 不做 `fm_eq_full` 的全局降级 | 改共享 `fm_eq.tcl`:link 期降级 ELAB-147 → 捕获为 elab147 qualification → validator 给 **PARTIAL**(如实标未证越界安全)。波及 RAM 家族(L2TLB/PtwCache/PTW/LLPTW)+ 真实数组边界安全,**请裁示** |
| **StorePipe** | 需决策 | golden 本体真退化:`module StorePipe(input io_lsu_req_valid); wire probe=...; endmodule` = **1 入/0 出/0 比较点**;impl wrapper 亦 1 端口对称。FM-081"参考是黑盒"**正确** | 非源错、非 bypass。**请裁示**定级:如 Rob 那样移出 signoff 分母(UNCONFIGURED),或记 documented INFRA |
| **CtrlBlock** | 深度 | TIMEOUT@2402s,跑满未完 = 真·大证明(非崩溃) | 拆证明(按子层次分证)或提高时限;**请裁示**目标时限/拆分策略 |
| **LoadQueueRAR** | 深度 | TIMEOUT@2402s + RSS 12.9G = **matching 爆炸**;盲提限无用 | 先诊断 matching 策略(compare-point 匹配组合爆炸),再决定;不盲加 timeout |

## GAP 分类(189 PROOF_GAP,schema 无关,原始 facts)

| 类别 | 数量 | 含义 / 下一步 |
|---|---|---|
| ASSEMBLY_CAND(仅黑盒) | 65 | FM 已证等价+干净,仅 strict 黑盒→PARTIAL;声明 assembly 契约即翻 PASS |
| CLEAN_POLICY_GAP | 20 | native 全干净仍 PARTIAL,最接近 PASS,差契约细节 |
| QUAL_GAP(unread/unmatched) | 87 | 匹配点已证等价,有未读/未匹配点需 qualification |
| RTL_MISMATCH(=12 FAILED) | 12 | 真证明缺口(见下) |
| (含 5 个本轮恢复:Composer/DataPath 等,归入上述桶) | | |

**85 个(65+20)最高价值翻盘候选**(FM 已证等价,差契约声明)。

### 12 RTL_MISMATCH triage(供 RTL_GAP_REPAIR 排序)
- **10 个 failing=20**(=FM 默认报告上限截断,实际≥20 各):DCacheWrapper/L2TLBWrapper/L2Top/
  LoadQueueRAW/MemBlock/Rename/StoreQueue/VirtualLoadQueue/XSTile/XSTop —— 集中在**顶层装配 +
  簇**,很可能沿层次从共享子模块级联(hierarchy fan-out:如 StoreQueue 真 bug → 含它的
  MemBlock/XSTile/XSTop 全挂)。修复应**先根子模块、再验装配**。
- **2 个 failing=1**(单点精确差,最易定位):Frontend、LoadQueueUncache。

## 基础设施注记(闭环缺口)
1. **ut_common.mk 未进 script_closure.list**(grep=0)→ 本轮改它不波及冻结 digest,但这是
   closure 覆盖缺口(共享 build 脚本未追踪),**建议后补纳入 closure**。
2. **emitter(fm_native_emit.tcl)在 closure 内**→ #8 改动使其 script_digest 变更。对空
   dont_verify 目标输出字节不变(无语义回归),但严格 closure 意义上 script_digest 已变,
   **建议末端做一次全 305 digest 刷新一致性 sweep**(纯 digest,不改语义)。

## 并发/安全遵从
单一 orchestrator;同目标不并发;主树在 FM 运行期冻结,修改经提交后新 worktree 生效;
每轮独立 evidence root(delta5/6/7);重型 FM ≤2 并发,MemAvail 全程 >30G;canary 用 2400s
+ 未盲目无限延时。

## 附:timeout 桶深诊断(只读,确认推进 vs 卡死 —— 均非"提时限"可解)

| 目标 | 卡在哪阶段(fm_log 实证) | 结论 | 建议修法(非盲提限) |
|---|---|---|---|
| **LoadQueueRAR** | `Matching... 1421M/8005 (3% Matched) 1230MB/1817.97sec` | **matching 组合爆炸**:30min 仅 3%,外推 ~17h。日志注释:"层次和签名都无法配对…FTQ/IFU 扇出复制"→命名/签名歧义致匹配候选叉乘(1421M) | 加 matching hint:`fm_map/LoadQueueRAR.txt` 字段映射 或 pin 内 `set_user_match` 钉关键 ref↔impl 对应(扇出复制点),压掉候选空间。**提时限无效** |
| **CtrlBlock** | 日志止于 `Building verification models...`(从未到 Matching) | **建模阶段超时**(非匹配、非验证):40min 全耗在构建验证模型 = 设计过大/扁平化过重 | 证明分区(按子层次分证 CtrlBlock 各子块)或诊断建模为何慢(潜在深层实例爆炸)。单纯提时限风险高、收益不明 |

**DataPath**(本轮已修 #8):原非 timeout —— FM 1466s 内 Verification SUCCEEDED,是 emitter 解析
非空 dont_verify 报告的盲区,已修复 → PARTIAL。

→ timeout 桶三者:1 修复(DataPath)、2 需 proof-engineering(LoadQueueRAR matching hint /
CtrlBlock 分区),**无一是"直接调大 2400s"能解**。请裁示是否授权做 matching hint / 分区。
