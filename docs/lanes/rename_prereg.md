# Rename lane（agent/rename）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `d5b637e83d1a7e9f2b3a3c06e26dd1cd6c8bd1e5`（main，`git worktree add /home/eda/xs-env/wt-rename -b agent/rename main`） |
| 工作树 | `/home/eda/xs-env/wt-rename`，分支 `agent/rename` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读，`G1-a4ea14f2…7afcf0`） |
| 目标 | `StdFreeList`(重证) / `StdFreeList_1` / `StdFreeList_2` / `StdFreeList_3` / `MEFreeList` / `Rename` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## 1. StdFreeList 家族（参数化共核 + 3 个薄变体）

### 1.1 改动与受影响集合

`rtl/backend/StdFreeList.sv` 把 SIZE/NUM_LOGIC_REGS 从 package localparam 改成核参数
（指针类型/算术随之进核），快照存储改直接例化家族共核 `xs_SnapshotGenerator_core`
（DATA_W = PTR_W+1），commit 侧 Wen 端口改名 `io_commit_info_regWen`。
`python3 scripts/check_shared_impl_impact.py --file rtl/backend/StdFreeList.sv`：
★受影响目标 1 个★ = `StdFreeList`（经由 rtl/backend/StdFreeList.sv）→ 本 lane 重证它。

三个变体的参数逐个量自 G1 golden（gen_variants.py 生成时与 stdfreelist_pkg 互证）：

| golden | SIZE（回绕常量） | NUM_LOGIC（复位初值基数） | 指针宽 | Wen | SnapshotGenerator 变体 |
|---|---|---|---|---|---|
| StdFreeList   | 158 (`10'h9E`) | 34 (`8'h22`) | 8 | fpWen  | SnapshotGenerator |
| StdFreeList_1 | 81  (`9'h51`)  | 47 (`8'h2F`) | 7 | vecWen | SnapshotGenerator_11 |
| StdFreeList_2 | 21  (`7'h15`)  | 1  (`8'h1`)  | 5 | v0Wen  | SnapshotGenerator_12 |
| StdFreeList_3 | 31  (`7'h1F`)  | 1  (`8'h1`)  | 5 | vlWen  | SnapshotGenerator_12 |

### 1.2 UT（跑前已跑，两档 × 3 seed × 200k，`checks=… errors=0` + `TEST PASSED`）

| UT | seed 1/7/42 `+vcs+initreg+random` | seed 1/7/42 `+vcs+initreg+0` |
|---|---|---|
| verif/ut/StdFreeList（重证，Makefile 补上 `SIM_ARGS += $(INITREG)`：原先两档从来没真跑过） | 200000/0 ×3 | 200000/0 ×3 |
| verif/ut/StdFreeListVariants（三变体各一对，600000 checks/次） | 600000/0 ×3 | 600000/0 ×3 |

复跑：`cd verif/ut/StdFreeListVariants && make run SEED=1 INITREG=+vcs+initreg+random`（另 `+vcs+initreg+0`；SEED=7/42）。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

| 目标 | passing 预测（模型 = golden 闭包寄存器位 + 顶层输出位） | 其余 |
|---|---|---|
| StdFreeList   | **1593**（1520 + 73；上一轮 merge_dup=true 实测也是 1593） | failing 0 / unverified 0 / unmatched 六项 0 / unread 0 / 无黑盒 / SUCCEEDED |
| StdFreeList_1 | **892**（819 + 73） | 同上 |
| StdFreeList_2 | **336**（263 + 73；lane 内试跑已得 336，见 1.4） | 同上 |
| StdFreeList_3 | **426**（353 + 73） | 同上 |

无 vmucp、无 fm_pins、无 allow/dead_ref 声明。

### 1.4 明写可能出错的地方

1. lane 内对 StdFreeList_2 做过一次**非正式**试跑（dirty 工作树，不出 receipt）：
   native SUCCEEDED passing 336 / failing 0 / unmatched 全 0 —— 与模型逐位相等。
   另外三个没试跑，若 _1（SIZE=81, 指针 7 位）出现常量寄存器折叠，差额须由 receipt 的
   `constant_reg` 指认，否则按 fail 查。
2. 家族共核改动让 StdFreeList 旧 receipt(`evidence/40ec7fc36bb8`)失效，本 lane 在新字节上重证；
   若新 passing ≠ 1593，说明参数化引入了结构差异，先查再说。

## 2. MEFreeList（整数 move-elimination 空闲列表，golden 5,884 行 / 187 端口）

### 2.1 核与 golden 差异点（考古结论，全部在 rtl/backend/MEFreeList.sv 文件头/第 9 节写明）

- 与 StdFreeList 同源(BaseFreeList)，差在：初值 {1..223,0} / tailPtr 初值 (0,223) 且回收用当前
  tailPtr、空闲计数用 tailPtrNext / archHead 只按 rfWen&~isMove 推进 / canAllocate 组合输出 /
  perf 中间两档上界是 `<=`(StdFreeList 是 `<`)。
- G1 比上一轮 golden 多 32 个 `io_debug_rat_N` 输入与 530 位 debug 影子寄存器
  (debugArchHeadPtr 两级 9+9、debugArchRAT 两级 32×8+32×8)，只喂 XSError，综合口径下两侧都是死位。
  核按同名同宽同源复刻(指针拆成 _flag/_value 标量以对齐 golden 展平名)，靠 fm_pins.tcl 按叶名
  机械配对(期望值 530 = 1+8+1+8+256+256，fail-closed 四道)，vmucp 白名单
  `verif/fm_target_config/MEFreeList.tcl` 记六条证据。
- lane 内非正式试跑(dirty，不出 receipt)：关 vmucp 基线 native SUCCEEDED passing 2186 /
  unread 530(530) → strict PARTIAL(strict_unread!=0)；开 vmucp + 钉点后 passing **2716**(+530)、
  failing 0、unmatched 六项全 0、unread 0、无黑盒、dont_verify/elab147/relaxed 皆空。

### 2.2 UT（两档 × 3 seed × 200k）

verif/ut/MEFreeList（gen_tb.py 生成，含快照暖机 + 32 项 debugArchRAT 探针）：
seed 1/7/42 × {+vcs+initreg+random, +vcs+initreg+0} = 6/6 `checks=200000 errors=0` TEST PASSED。

### 2.3 跑前预测（★跑完不许改★）

| 项 | 预测 |
|---|---|
| passing | **正好 2716**（模型 2643 + 73；试跑已得 2716） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（530 对全部由 fm_pins 钉成 matched，`MEFL_PIN_END … n=530 miss=0`） |
| 黑盒 | FM-249 No black boxes |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

可能出错：钉点脚本跑在 safe interp 里，若 `report_unmatched_points -list` 的叶名格式与试跑不同会
`error` 早退(表现为 FM 早退而不是数字小偏离)。
