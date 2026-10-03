# fu-atomics-fpdiv-imsic lane · sub=vfof —— VfofBuffer 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 工作树 | `/home/eda/xs-env/wt-fu-atomics-fpdiv-imsic`，分支 `agent/fu-atomics-fpdiv-imsic` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/VfofBuffer.sv`（876 行 / 193 端口 / 56 reg，无子模块） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |

## 1. 结构

- `rtl/memblock/VfofBuffer.sv`：package `vfofbuffer_pkg`（uop 载荷 packed struct 53 字段 729 位，字段顺序 = golden reg 声明顺序；写回口 struct）
  + `xs_VfofBuffer_core`（§1 入队选择 / §2 写回聚合取最老 / §3 出队与 valid / 状态更新）+ golden 同名 wrapper（打包/拆包）。
- 寄存器集合逐字对齐 golden：entries_uop（53 字段 729 位）+ entries_vl 8 + entries_hasException 1 + valid 1 = **739 位**，全部异步复位到 0。
- golden 里 4 条 XSError 只是 assert（`ifndef SYNTHESIS`），不进逻辑；UT/FM 都定义 SYNTHESIS。

## 2. UT（verif/ut/VfofBuffer；3 seed × initreg {0, random, <seed>017} × 200k）

逐拍比全部 56 个输出；覆盖桶（golden 内部信号计数，下限 NCYCLES/400）：出队 fire / 两写回口同时命中 /
写回更新 vl / 写回带异常 / 条目被 redirect 冲掉 / 非空时 lastUop 刷新 uop / 入队被 redirect 取消。
seed 7 × 20k 先行：checks=1120000 errors=0，fire=1784 both_hit=214 wb_update=1807 wb_exc=746 redirect_kill=343 refresh=1590 enq_cancel=196。
9 档正式读数在「对账」追加。

变异自证（seed 7 × 20k，`$SCR/mutrun.sh` 原地注入后恢复）：
M1 取最老时漏"口 0 带异常"条件 errors=318；M2 写回更新不看 hasException errors=6590；
M3 非空时 lastUop 不刷新 uop errors=622394；M4 needFlush 漏 level（flushItself）errors=15806；
M5 写回更新与入队初始化优先级互换 errors=0 —— **等价变异**：wb_update 要求 valid=1、入队初始化要求 valid=0，两者互斥，交换顺序不改变电路，不计为 UT 漏检。

## 3. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/VfofBuffer.json）

| 项 | 预测 |
|---|---|
| passing | **1605**（模型：寄存器位 739 + 顶层 output 位 866；`FM_MERGE_DUP=false` 模型适用） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 0（每个寄存器都有真次态；若出现则在对账指认） |
| 黑盒 / dont_verify / vmucp / fm_pins | 无 / 无 / 不开 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

## 4. 明写可能出错的地方

1. impl 的 uop 载荷是一个 729 位 packed struct 寄存器（`entries_uop_reg[b]`），golden 是 53 个扁平寄存器
   （`entries_uop_<field>_reg[b]`），名字对不上，只能靠 FM 签名匹配。本节没做任何 FM 试跑。
   若出现 unmatched，补 `verif/ut/VfofBuffer/fm_pins_pre.tcl`（按 struct 字段偏移机械生成、fail-closed）重跑，并在对账里写明。
2. golden 的 `entries_hasException` 次态是两层 if/else 折叠成的 `~_GEN_7 & entries_hasException`，重写按 Scala 的两个 when 写；UT 逐拍比过（M2/M5 见上）。

## 对账（跑后追加）

- FM（run `VfofBuffer-20261003T010534Z-27afa08c`，证明 commit `27afa08c` = 登记 commit）：native SUCCEEDED，
  passing **1605**（预测 1605，差 0）、failing 0、unmatched 0(0)、unread_points 空、黑盒 0、dont_verify 无、vmucp 关。
  证据 `evidence/27afa08caf5a/VfofBuffer/`（receipt.json sha256 `7ca7310edd40a1c7cce9c27343976b3c457ea0aed62d7952acf9350c0b22eef6`）。
  `python3 scripts/fm_predict.py check VfofBuffer` → 逐位相等，rc=0。§4 担心的 struct 寄存器名失配没有出现，未加 fm_pins。
- UT 9 档全部 checks=11200000 errors=0 bad_cov=0（三种 initreg 读数同 seed 逐位相同，符合"全异步复位"）：

| seed | fire | both_hit | wb_update | wb_exc | redirect_kill | refresh | enq_cancel |
|---|---|---|---|---|---|---|---|
| 1 | 18075 | 2344 | 18320 | 7749 | 3185 | 16021 | 1924 |
| 7 | 18015 | 2267 | 17913 | 7496 | 3182 | 16034 | 1863 |
| 42 | 18115 | 2312 | 18036 | 7537 | 3180 | 16066 | 1867 |
