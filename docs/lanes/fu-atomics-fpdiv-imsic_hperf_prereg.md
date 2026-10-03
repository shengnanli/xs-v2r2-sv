# fu-atomics-fpdiv-imsic lane / sub=hperf —— 跑前登记（HPerfCounter_21 → HPerfMonitor_3）

★FM 起跑之前提交本文件；跑完只在文末「对账」追加，不改已提交数字★

## 0. 输入
| 项 | 值 |
|---|---|
| worktree | `/home/eda/xs-env/wt-fu-atomics-fpdiv-imsic`（agent/fu-atomics-fpdiv-imsic） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| UT | `verif/ut/HPerfMonitor_3`（两目标同 tb），seed 1/7/42 × initreg {0, random, <seed>017} × 200k 拍 |

## 1. HPerfCounter_21（golden 575 行 / 146 端口 / 12 reg；impl `rtl/common/HPerfCounter_21.sv` 380 行，`_GEN_`/`_T_` 0）
- 参数化核 `xs_HPerfCounter_core #(NUM_SETS=144, W=6)`：S1 事件选择（8 位下标查表，0 与 ≥144 读 0；第 0 号事件
  golden 无端口，wrapper 钉 0）+ 算子打拍 / S2 两两组合 / S3 最终组合 / S4 输出再打一拍；12 个寄存器全无复位（照抄 golden）。
- 变异自证（seed 7 × 20k，原地注入后恢复）：M1 查表上界 144→143 errors=1014；M2c 算子优先级 and/xor 对调 errors=102542；
  M3 下标段取 [17:9] errors=57589；M5 add 改 sub errors=27980。（M2b "op[1]&&!op[0]" 是语义等价改写、errors=0，不算逃逸。）
- **预测**：passing = **74**（寄存器位 68 = 4×6+3×5+5+2×6+6+6，+ 输出 6）；failing/unverified/unread/unmatched 全 0；SUCCEEDED。
  可能出错处：核内寄存器是数组 `events_incr_value[4]` / `event_op[3]` / `event_step_reg[2]` 对 golden 平铺名，靠签名匹配（12 个寄存器，规模小）。

## 2. HPerfMonitor_3（golden 1520 行 / 160 端口 / 16 reg；impl `rtl/common/HPerfMonitor_3.sv` 516 行，`_GEN_`/`_T_` 0）
- 核 `xs_HPerfMonitor_core #(NUM_CNT=8)`：genvar 例化 8 个 HPerfCounter_21（实例名 perfEvents_hpc，路径 `g_cnt[c].perfEvents_hpc`）
  + 每路两拍无复位打拍。child HPerfCounter_21 本 UT 自签，两侧白盒。
- 变异自证：M4 少打一拍 errors=116035。
- **预测**：passing = **688**（8×68 + 16×6 = 640 寄存器位 + 48 输出位）；其余全 0；SUCCEEDED。
  可能出错处：golden 实例名 `perfEvents_hpc_1..7` vs impl `g_cnt[1..7].perfEvents_hpc`，靠签名匹配；若 unmatched 先查配对。

UT 读数与变异/FM 对账见文末追加。
