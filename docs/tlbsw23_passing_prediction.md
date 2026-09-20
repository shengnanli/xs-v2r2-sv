# TlbStorageWrapper_2 / _3 —— FM passing 预登记（跑前写死）

★本文件在**任何一次 TlbStorageWrapper_2/_3 的 FM 跑之前**写定并提交。★
事后改这里的数字等于没有预测，所以它的 sha256 一并记进证据。

## 模型

    passing(目标) = 目标证明闭包内的**触发器位数** + 目标**顶层 output 端口位数**

比较点 = 每个触发器一位 + 每个顶层输出一位。内层子模块的输出在父层变成内部网，
**不是**比较点 —— 所以 TlbStorageWrapper_N 的 passing 里没有 TLBFA_N 的 output 位，
只有它的触发器位。

    passing(TlbStorageWrapper_N) = ff(TLBFA_N) + ff(wrapper 自己 = 47) + out_bits(TlbStorageWrapper_N)

其中 47 = Tree-PLRU 状态 refill_idx_state_reg[46:0]，四个变体都一样。

## 自校准（不照抄别人的口径：先用**本家族已签核的 4 个点**验模型）

量法可复跑（只读 golden，与仓库状态无关）：
    python3 scripts/tlbsw_passing_model.py

| 模块 | out_bits | ff_bits | 模型值 | 已签核实测 | 命中 |
|---|---|---|---|---|---|
| TLBFA               | 186 | 7996 | 8182 | 8182（agent/tlbfa 010231d） | ✓ |
| TLBFA_1             | 388 | 8275 | 8663 | 8663（同上） | ✓ |
| TLBFA_2             | 132 | 8101 | 8233 | 8233（同上） | ✓ |
| TLBFA_3             | 128 | 8101 | 8229 | 8229（同上） | ✓ |
| TlbStorageWrapper   | 165 | 47 + 7996 | 8208 | 8208（evidence/f40deba9439d） | ✓ |
| TlbStorageWrapper_1 | 360 | 47 + 8275 | 8682 | 8682（同上） | ✓ |

6/6 逐位命中，其中 TlbStorageWrapper / _1 两行是**跨层次**（父 wrapper + 子阵列）
的校准点，正是 _2/_3 要用的那个形状。

## ★预测★

| 目标 | 预测 passing | 分解 |
|---|---|---|
| **TlbStorageWrapper_2** | **8266** | ff(TLBFA_2) 8101 + 47 + out 118 |
| **TlbStorageWrapper_3** | **8262** | ff(TLBFA_3) 8101 + 47 + out 114 |

其余预测：failing=0 / unverified=0 / aborted=0 / unmatched=0 / unread_notcompared=0，
native SUCCEEDED，无 dont_verify、无黑盒。

## 预测会错在哪（先写下来，免得事后找补）

- 若 FM 把 `merge_duplicated_registers` 合掉了一些寄存器 ⇒ passing **偏低**。
  本 UT 声明 `FM_MERGE_DUP=false`，所以预期不发生。
- 若重写核比 golden **多**寄存器（超配 FIFO 之类）⇒ impl 侧多出的点要么配不上
  （unmatched）要么是 unread，两种都会让判决不是干净 SUCCEEDED。本家族核是
  47 位 PLRU + TLBFA_N，与 golden 一一对应，预期不发生。
- 若 `_2` 与 `_3` 的端口不对称（`io_r_resp_{0,1}_bits_s2xlate_0` 只在 _2 有）被
  "补齐成对称"，两个数会变成相同 ⇒ **预测 8266 ≠ 8262 这 4 位之差本身就是一条判据**。
