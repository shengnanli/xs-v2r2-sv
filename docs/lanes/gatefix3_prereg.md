# gatefix3 lane（agent/gatefix3）—— 跑前登记

本文件在重证 **FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `18359395`（next200c 合入后），worktree `/home/eda/xs-env/wt-gatefix3` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | `signoff-strict`，与原签核相同的 per-target 配置（`verif/fm_target_config/HPerfCounter_21.tcl` / `HPerfMonitor_3.tcl` 不改），无新增 allow / dont_verify / 黑盒 |

## 1. 同名模块处置

### 1.1 VSegmentTrigger（删 rtl/backend 副本）

- `rtl/memblock/VSegmentTrigger.sv`：storeunit-vsplit lane 2026-10-02 签核（receipt `evidence/7b1acd0b334d/VSegmentTrigger`，
  VSegmentUnit 也经它两侧白盒），MemTrigger 共享核的薄 wrapper，`coverage_three_axis.tsv` 登记的就是这一份。
- `rtl/backend/VSegmentTrigger.sv`：next200c 2026-10-02 新写的第二份独立实现，**无任何 receipt / UT Makefile / 生成器引用**
  （`check_shared_impl_impact.py --file` = 0 目标）。
- 处置：删 backend 副本。memblock 份字节不动 → 无目标需重证。

### 1.2 xs_HPerfCounter_core（HPerfCounter_21 内嵌核改名 xs_HPerfCounter_idx8_core）

两份是**不同的核**（不是同一份的拷贝）：
- `rtl/backend/xs_HPerfCounter_core.sv`（next200c，`gen_bus_hperf_200c.py` 生成）：显式事件表 `TABLE_SIZE`、
  `EVENT_INDEX_BITS` 位下标、算子寄存器只存 [2:0]；被 HPerfCounter / HPerfCounter_8 / HPerfCounter_13 / BusErrorUnit
  共 4 份 receipt 依赖（前三者 PASS_DEAD_REF，[4:3] golden-only 死位）。
- `rtl/common/HPerfCounter_21.sv` 内嵌（fu-atomics lane 2026-10-02 签核，更早）：`NUM_SETS`/`W`、8 位下标越界读 0、
  算子寄存器保留 golden 5 位（vmucp 两侧比较）；被 HPerfCounter_21 / HPerfMonitor_3 共 2 份 receipt 依赖。
- 两侧参数表不同，"谁先编译谁赢"是真隐患（参数覆盖闸：HPerfCounter_21.sv:377 的 NUM_SETS/W 被解析到 backend 核）。
- 取舍：合并成一份核会改变其中一族的证明形态（vmucp ↔ PASS_DEAD_REF）且两族都要重证；改名只动一个文件。
  "更早签核"指向保留 HPerfCounter_21，"更多 receipt"指向保留 backend；按最小重证面（2 vs 4 目标 + 生成器）
  改 HPerfCounter_21 内嵌核名为 `xs_HPerfCounter_idx8_core`，实例名 `u_core` 与寄存器名全不变 → FM 匹配、钉点
  （`verif/ut/HPerfMonitor_3/fm_pins_pre.tcl` 按实例路径）不受影响。
- 受影响目标（`python3 scripts/check_shared_impl_impact.py --file rtl/common/HPerfCounter_21.sv`）：HPerfCounter_21、HPerfMonitor_3。

## 2. 重证预测（沿用原登记，模型不变：改名不增减寄存器 / 输出位）

| 目标 | UT | 预测 passing | 判据 |
|---|---|---|---|
| HPerfCounter_21 | HPerfMonitor_3 | 74 | failing / unread / unmatched 0，无黑盒、无 dont_verify，SUCCEEDED |
| HPerfMonitor_3  | HPerfMonitor_3 | 688 | 同上；钉点 `HPERF_PIN_PRE_END ok=160 bad=0` |

UT：`verif/ut/HPerfMonitor_3`，seed 1/7/42 × `+vcs+initreg+0` / `random` / `<seed>017`，各 200k 拍，串行，期望 errors=0。

## 3. 生成器幂等（rtl 不动，生成器回灌已签字节）

- `scripts/gen_bus_hperf_200c.py`：emit_hperf_core 文本补上 rtl 已有的第 3 行注释（97762aa34 可读性改动未回灌）。
- `scripts/gen_pmacfg_leaves8.py`：CORE_TEXT 换成 rtl 现行 `xs_Pmacfg_core.sv`（按 PMA_INDEX 的逐项架构复位值；
  旧文本是统一复位 0 的早期版本，与 33 个 Pma*cfgModule receipt 所签字节不符）。

## 4. 对账（跑后追加）

UT `verif/ut/HPerfMonitor_3`（两目标同 tb，9 个 DUT 对比较），串行 9 档全 `checks=1799928 errors=0 bad_cov=0 TEST PASSED`：

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | errors=0 | errors=0 | errors=0（1017） |
| 7  | errors=0 | errors=0 | errors=0（7017） |
| 42 | errors=0 | errors=0 | errors=0（42017） |

FM（`bash scripts/run_proof.sh HPerfMonitor_3 HPerfCounter_21 HPerfMonitor_3 < /dev/null`，impl commit `b13bd7dd76f6`，signoff-strict，vmucp=true）：

| 目标 | 预测 | 实测 passing | failing / unmatched / 黑盒 / dont_verify | 判定 | receipt.json sha256 |
|---|---|---|---|---|---|
| HPerfCounter_21 | 74 | **74** | 0 / 0 / 0 / 否 | SUCCEEDED | `43034eda5646b1aba145479a436e28793a024be9fe15a54b8e5592b387a56288` |
| HPerfMonitor_3  | 688 | **688** | 0 / 0 / 0 / 否 | SUCCEEDED | `3830dae5b8924b3afcf90d0ec2a8d60b8a128edc131a2949930968ce414058ee` |

钉点 `HPERF_PIN_PRE_END HPerfMonitor_3 ok=160 bad=0 expect=160`，FM "160 Compare points matched by user"。
`fm_predict.py check HPerfCounter_21 HPerfMonitor_3` 逐位相等 rc=0。与原签核（74 / 688）完全一致：改名不影响证明。
