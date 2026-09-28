# MutiLevelPrefetchFilter lane（agent/mlpf）—— 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（`git worktree add /home/eda/xs-env/wt-mlpf -b agent/mlpf 975b64e6`） |
| 工作树 | `/home/eda/xs-env/wt-mlpf`，分支 `agent/mlpf` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读）：MutiLevelPrefetchFilter.sv 10,466 行 + RRArbiterInit_6/7/8/9 |
| 目标 | `MutiLevelPrefetchFilter`（L1Prefetcher.pf_queue_filter） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无黑盒 |

## 1. 核与 golden 的对应（考古结论，全部写在 rtl/memblock/MutiLevelPrefetchFilter.sv 文件头/各节）

- 设计源 `L1PrefetchComponent.scala` class MutiLevelPrefetchFilter。核按「表项结构 → 替换 → 入表/去重 →
  TLB 查询 → L1 发出 → L2/L3 发出 → 冲刷与死寄存器」七节写；表项用 generate 块 `l1_array[i]` /
  `l2_array[i]` 表达（块名 = golden 展平数组名，FM 按名配对：`l1_array_3_tag` ↔ `l1_array[3].tag`）。
- golden 配置折掉的接口：`io.flush`（上层接 0，但 32 个 RegNext(flush) 寄存器 REG_6..37 仍在）、
  L1 请求的 `sink`（恒 SINK_L1）、`io.l3_pf_addr`（无端口，但 L3 仲裁器仍置 sent_vec）、
  RRArbiterInit_8 的 is_store 字段 —— wrapper/核里照此接常量，注释写明。
- golden-only 结构全部照抄：s1 region/hash 两份值恒等寄存器、6 个 hash_conflict 性能打拍死寄存器
  （REG/REG_1..5）、GatedValidRegNext 的「值变了才打拍」、s1_pf_bits_req_is_store 粘滞位。
- 4 个子仲裁器两侧白盒：ref = golden RRArbiterInit_{6,7,8,9}.sv，impl = rtl/common 的重写件（均已 PROVEN_DIRECT）。
- 规模：impl 1,366 行（含生成区），代码区 `_GEN_`/`_T_` = 0；readability_audit rc=0。

## 2. UT（verif/ut/MutiLevelPrefetchFilter，gen.py 生成 tb；两档 × 3 seed × 200k 拍，串行）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` |
|---|---|---|
| 1  | checks=198805 errors=0 PASS | checks=198805 errors=0 PASS |
| 7  | checks=199855 errors=0 PASS | checks=199855 errors=0 PASS |
| 42 | checks=198947 errors=0 PASS | checks=198947 errors=0 PASS |

checks < 200000：比较窗口在「两表 32 项都 alloc 过 + 各发过一次 TLB/L1 请求 + 4 拍」后才打开（见 tb 头注释；
+random 下 seed 7 首跑在第 32 拍起 10 拍 io_l2_pf_addr_bits_addr 失配 = 没写过的表项初值两侧不同，
这本身也证明 initreg+random 确实改了不复位状态）。覆盖计数（l1_fire/l2_pf/tlb_req/upd_l1/upd_l2/drop/hash_alias）
每档全部非零，见 sim_<seed>_initreg*.log。

变异体（lane 内，seed 1 +0 60k 拍）：12 个里 9 个 CAUGHT；3 个存活均有解释 ——
M1（L1 表 sink 升级分支）L1 表 sink 在可达状态恒为 SINK_L1；M2（L2 sink `<`→`<=`）只改 bit_vec 里已被 sent_vec
遮住的位，观测等价；M5（L1 may_be_replace 去掉 RegNext(valid)）需「L1 项 16 行全发完后被作废再重分配」的窄窗口，
同族的 L2 版本 M5b 被 CAUGHT。这三处都是寄存器值不同，由 FM 兜底。

复跑：`cd verif/ut/MutiLevelPrefetchFilter && make run SEED=1 INITREG=+vcs+initreg+0`（另 `+vcs+initreg+random`；SEED=7/42）；
`python3 gen.py --check`。

## 3. lane 内非正式试跑（diagnostic-full，不出证）

1. 关 vmucp：native SUCCEEDED，passing 4054 / failing 0 / unmatched compare 0 / constant_reg 32，
   unread 202 = matched_nc 201 + `1(1) Unmatched unread`（ref `REG_reg` ↔ impl `u_core/REG_0_reg`，
   SV 里数组 REG[6:37] 与标量 REG 不能同名，标量只好叫 REG_0）。
2. 加 `fm_pins.tcl`（1 对，fail-closed）+ vmucp（`verif/fm_target_config/MutiLevelPrefetchFilter.tcl`，六条证据）：
   native SUCCEEDED，passing **4256**，unmatched 全 0，unread_points 空。

## 4. 跑前预测（★跑完不许改★，登记见 docs/fm_predictions/MutiLevelPrefetchFilter.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **4288**（regs 3995 + outs 293）；实测预计 **4256**，差 32 由 receipt `constant_reg`=32 逐位指认（REG_6..REG_37 = 每项一份 RegNext(io.flush)，flush 恒 0） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`MLPF_PIN_END … n=1 expect=1`） |
| 黑盒 | 无（4 个仲裁器两侧白盒） |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

可能出错的地方：钉点跑在 sidecar safe interp 里，若 impl 路径格式与诊断跑不同会 `error` 早退（表现为 FM 早退而非数字偏离）；
constant_reg 若与 32 不同，差额须由 receipt 指认，否则按失败查。

---

# 对账（跑完追加；上文各节未改一字）
