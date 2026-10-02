# mmuleaf lane（agent/mmuleaf）—— 跑前登记

本文件在每个目标 **官方 FM（run_proof.sh）起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `d5564588`（main，`git worktree add /home/eda/xs-env/wt-mmuleaf -b agent/mmuleaf main`） |
| 工作树 | `/home/eda/xs-env/wt-mmuleaf`，分支 `agent/mmuleaf` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标（按顺序） | `StreamBitVectorArray` → `PrefetchFilter` → `TLB` → `PTWFilterEntry` → `PMP` |
| 冲突检查 | codex outbox 最新 0205（next-20 叶，均不含本 lane 目标）；claude_0204 第 6 批认领表把本 5 个目标划给 mmuleaf；codex/* 与 kimi/k3-next20 分支 diff 无本 lane 目标文件 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| 钉点生成器 | `scripts/gen_mmuleaf.py`（带 `--check`；golden 顶层寄存器逐位 set_user_match，规则表 fail-closed、单射、字面计数） |

## 1. StreamBitVectorArray（golden 2,803 行 / 0 child）

### 1.1 结构

- 设计源 `L1StreamPrefetcher.scala` class StreamBitVectorArray。可读核 `rtl/memblock/StreamBitVectorArray.sv`
  （package streambitvectorarray_pkg + xs_StreamBitVectorArray_core + golden 同名 wrapper），495 行，代码区 `_GEN_`/`_T_` = 0，
  readability_audit rc=0。golden 2,803 行。
- 表项 generate 块 `array[i]`（tag/bit_vec/active/cnt + 每项一份 RegNext(flush) `last_REG`）；PLRU 用共享辅助件
  `rtl/common/xs_PlruReplacer.sv`（golden 内联为 state_reg，状态编码与 rocket-chip PseudoLRU 一致）。
- 配置折掉的东西：io.flush（上层接 0，wrapper 给核接 1'b0）、decr_mode（ENABLE_DECR_MODE=false）、L3 预取 valid
  （enableL3StreamPrefetch=false，但 s5 载荷寄存器仍在且出现在 l2_l3 bits 上）、动态深度（USE_STREAM_FIXED_DEPTH）。
- golden-only 结构照抄：3 个断言打拍寄存器、s2_region_tag（性能计数器）、预取地址低 6 位、两份同值的 s3 valid。
- 无子模块、无黑盒。

### 1.2 UT（verif/ut/StreamBitVectorArray；3 seed × 3 档初值 × 200k 拍，串行，commit cfd0ad0d 字节）

逐拍比全部 11 根输出（118 位）；bits 在 golden 第一次发出后才开始比（不复位寄存器直接驱动，见 tb 头注释）。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=1796886 errors=0 PASS | checks=1796886 errors=0 PASS | (1017) checks=1796886 errors=0 PASS |
| 7  | checks=1799674 errors=0 PASS | checks=1799674 errors=0 PASS | (7017) checks=1799674 errors=0 PASS |
| 42 | checks=1799374 errors=0 PASS | checks=1799374 errors=0 PASS | (42017) checks=1799374 errors=0 PASS |

checks 按「每拍每根输出一次」计（约 9 次/拍）。覆盖（seed 1，各档相同）：alloc 47747 / update 66276 / 邻区激活 alloc 1665 /
L1 预取 12098 / L2 预取 12098 / 反压 5659 / 查询命中活跃 10178 / 哈希冲突 275；任一类为 0 即判 FAILED。
（seed 1 × random 档按 CONVENTIONS 实为全 1 档。）

变异自检（scratchpad，seed 1 +0，40k 拍）：14 个里 13 个 CAUGHT（哈希去一段异或 / 阈值 >= 改 > / cnt 无条件加 / 去 strict 触发 /
L2 宽度 / 去反压 / 邻区不查 cnt / 忽略 enable / sink 常量 / 查询不读 active / update 清 active / L1 深度 63 / -1 邻区写成 +1）。
存活 M5（OHToUInt 的「按位 OR」改成「取最后一个」）：表项哈希两两不同（入表去重 + s1 反压），可达状态下匹配向量恒为独热，
观测等价；FM 覆盖（组合逻辑结构比对）。

复跑：`cd verif/ut/StreamBitVectorArray && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`；`python3 scripts/gen_mmuleaf.py --check`。

### 1.3 lane 内非正式试跑（diagnostic-full，不出证）

1. 关 vmucp（commit cfd0ad0d）：native SUCCEEDED，passing 1475 / failing 0 / unmatched 全 0 / constant_reg 16，
   unread 319 全部 matched_nc（钉点 `SBVA_PIN_END ok=1692 bad=0`）；五族见 `verif/fm_target_config/StreamBitVectorArray.tcl`。
2. 开 vmucp：native SUCCEEDED，passing **1794**，unread_points 空。

### 1.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/StreamBitVectorArray.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **1810**（regs 1692 + outs 118）；实测预计 **1794**，差 16 由 receipt `constant_reg`=16 指认（last_REG/last_REG_1..15 = 每项一份 RegNext(io.flush)，flush 恒 0） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`SBVA_PIN_END … ok=1692 bad=0`） |
| 黑盒 | 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

可能出错的地方：诊断跑与官方跑只差 mode 与 detached worktree 路径；钉点路径若在 detached worktree 下格式不同会 error 早退
（表现为 FM 早退而非数字偏离）。
