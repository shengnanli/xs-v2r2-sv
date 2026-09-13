# allow_gen —— assembly expected 黑盒集合的**独立**生成器（codex 0150 强制两阶段·阶段 1）

codex 0150 明令禁止「`declare_allow.py` 从**同一次** `black_boxes.rpt` 生成权威声明」
（循环论证：用一次运行的结果去配置那次运行通过）。本目录只做**阶段 1**：

* expected set 只从三样东西产生，**绝不读** `black_boxes.rpt` / `native_facts.json` / `fm.log`：
  1. **elaboration 元数据** —— `verif/ut/<dir>/Makefile` 里 `fm-%` 配方实际传给 `fm_eq.tcl` 的
     `FM_REF_SRCS = $(GOLDEN_RTL)/<top>.sv + FM_REF_DEPS_<top>` 与
     `FM_IMPL_SRCS = RTL_SRCS + RTL_GOLDEN_DEPS`，由 `make --eval` 自己展开，不手抄；
  2. **设计源** —— 上述文件的 module/instance 层次图，由 `sv_elab.py`（轻量 elaborator：
     参数求值 + generate-for/if 作用域展开）解析；
  3. **冻结 registry** —— `verif/vendor_boundary.tsv`（当前 20 条 `array_*_ext`），只用于**分类**，
     不参与产生集合。
* 判据来自 `scripts/fm_eq.tcl`：`hdlin_unresolved_modules = black_box`，且只 `read_sverilog`
  显式文件列表、不设任何库搜索路径 ⇒ **黑盒 ⟺ 被例化但其模块类型不在该侧读入文件集里**。

阶段 2（重跑 native Formal、要求 observed 与 expected 精确相等、gate 全零）**不在本目录做**，
由 integrator 在 clean freeze commit 之后执行。

## 生成器可信度：52/52 交叉校验

`validate_generator.py` 拿本生成器的输出与仓库里**已被接受**的 52 份 `verif/allow/*.json`
逐条比对（`(side, design, path)` 三元组全等），结果 **MATCH 52 / MISMATCH 0**，
其中包含双层 generate 下标（`g_wb_bank[i].g_wb_br[j].bank_wrbypass`，TageTable×4）
与单层（`g_split[0..7].array_inst`，SplittedSRAMTemplate_2）两种最难的形态。

第二重旁证：`TageBTable/Makefile`、`ICacheMetaArray/Makefile`、`SubDirectory*/Makefile`、
`IMSICGateWay/Makefile` 里**在跑 FM 之前**人工写下的预期边界注释，与本生成器的输出逐个吻合。

## 文件

| 文件 | 说明 |
|---|---|
| `sv_hier.py` | 词法剥离 + 例化识别的基础件 |
| `sv_elab.py` | 轻量 elaborator：参数/localparam 求值、generate-for/if 作用域、层次 DFS |
| `gen_expected.py` | 取 Makefile 的 elaboration 元数据 + 解析两侧层次图 |
| `report_expected.py` | 产出 `expected_sets.json` 与分类概览 |
| `write_allow.py` | 把 expected set 落成 `verif/allow/<top>.json`（schema/排序与 `declare_allow.py` 一致；registry 外一律拒绝落盘） |
| `validate_generator.py` | 对 52 份已接受声明做交叉校验 |
| `audit_vs_observed.py` | expected × 历史 `black_boxes.rpt` 对照（报告只作**候选审计表**） |
| `expected/<top>.tsv` | 每个目标一份 expected set，含来源与依据 |
| `classification.tsv` | 17 个目标逐个的边界分类与 STOP 原因 |
| `registry_gaps.tsv` | registry 缺项集中报告（待 QUESTION） |
| `a1_vendor_evidence.tsv` | 已落盘 8 份 A1 声明的逐条依据 |
| `audit_expected_vs_observed.tsv` / `audit_detail.txt` | 对照结果 |

## registry 完整性（一并报告的问题）

codex 0148 §A1 要求 registry 条目含「module/type、来源/供应商或宏模型依据、
**端口签名/参数签名**、**body/hash 规则**与 rationale」。当前 `verif/vendor_boundary.tsv`
只有 `design_pattern / kind / rationale` 三列，**缺端口签名与 hash 规则**。
本批没有改这张冻结表；缺的字段以 `a1_vendor_evidence.tsv` 的形式随声明附上，供审定。

## 复跑

```bash
cd <repo>
python3 verif/allow_gen/report_expected.py        # 重建 expected_sets.json
python3 verif/allow_gen/validate_generator.py     # 52/52 自检
python3 verif/allow_gen/write_allow.py <targets>  # 落盘（仅 registry 内的边界）
python3 verif/allow_gen/audit_vs_observed.py      # 对照历史报告
```
