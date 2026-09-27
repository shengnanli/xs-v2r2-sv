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

### 1.5 首跑结果与追加（不改 1.3 的数字）

evidence/e9987342c6f9（proof commit `e9987342c6f999366067241997bc89a07e1bd02a`）：
StdFreeList 1593 / StdFreeList_2 336 / StdFreeList_3 426 三个 SUCCEEDED 逐位等于模型；
**StdFreeList_1 PARTIAL**：native SUCCEEDED passing 890、failing 0、unmatched 全 0，但
unread_notcompared 2 = `freeRegCntReg_reg[1:0]`（两侧 matched_nc）。原因：SIZE=81 的
四分位边界 20/40/60 都是 4 的倍数，低 2 位不进任何比较，golden 与核同为死位。
处置：`verif/fm_target_config/StdFreeList_1.tcl` 加 vmucp 白名单（六条证据在文件里），
Makefile 只对该 target 开 vmucp；预测不变仍是 **892**（= 890 + 2，且 = 模型值）。

## 3. Rename（重命名流水，golden 7,139 行 / 1881 端口；CtrlBlock 直接 child）

### 3.1 考古结论与核

- 上一轮(G0/V2R2)有 T0_CLEAN_REWRITE 的 Rename 核(xs-v2r2-sv rtl/backend/Rename.sv 1274 行，
  vmucp 批签核过)。G1 golden 端口差异(`diff` 归一化端口表)：新增 ~25 个纯直通字段
  (vxrm/frm/debug_fuType/pc/foldpc/debug_seqNum/numUops/vuopIdx/vl/preDecodeInfo_{valid,isCall,isRet}/
  satpFlushFirstFetchFault/vpu_fpu_{isFP32Instr,isFP64Instr,isFpToVecInst,isReduction}/vpu_{isMove,isReverse,lastUop})，
  新增 3 个计算输出：`numUops`(与 numWB 同一压缩规则)、`debug_sim_trig`(mask & instr==SIM_TRIG HINT 32'hDFA92013，
  Scala b172fb91e)、`isMove`(= eliminatedMove，Scala 11ba71483)，新增 `io_debug_int_rat_0..31` 输入直喂 intFreeList。
  只读 CSR 豁免白名单按 G1 CSROoORead.scala 重写(waitForward 27 个 / blockBackward 15 个，与 golden 常量逐个核对)。
- 本轮核 rtl/backend/Rename.sv：package rename_pkg + xs_Rename_core(手写，含 12 节注释与导航) +
  golden 同名 wrapper(verif/ut/Rename/gen_rename.py 从 G1 端口表生成，生成时三项机械核对：输入字段↔struct
  成员/位宽全覆盖、输出字段∈计算表∪直通、其余端口与固定映射表严格相等)。子模块 CompressUnit/MEFreeList/
  StdFreeList×4/SnapshotGenerator 全部白盒例化本仓已签核的重写件。
- ★wrapper 生成器坑(实测)★：直接接核同名端口的标量原先生成 `assign x = x;`（自驱动 → X），UT 在第 4 拍
  canOut 变 X；修法：同名端口不写 assign。

### 3.2 UT（verif/ut/Rename，gen_rename.py 生成；两档 × 3 seed × 200k）

激励：ldest/lsrc 窄域 0..8(抬高同拍旁路命中率)、srcType one-hot 采样、instr 10% csrr 形态(白名单内外 32 个 CSR
地址池)+2% SIM_TRIG、fuType 偏置 alu/ldu/fence/jmp/向量访存/vfalu/vipu/csr、uopSplitType 偏置 AMOCAS、
64 拍确定性快照暖机(五个 FreeList 的快照槽 payload 不复位；golden 侧被 initreg 随机化而重写侧 unpacked 数组不被
initreg 覆盖 → 没写过的槽被 useSnpt 选中就 X)。比对 1,020 个输出口全部 + robIdxHead 与五个 FreeList headPtrOH 探针。
结果：seed 1/7/42 × {+vcs+initreg+random, +vcs+initreg+0} `checks=200000 errors=0` TEST PASSED（见 §对账 D）。

### 3.3 lane 内非正式试跑（dirty，不出 receipt）与两处钉点

1. 首跑：native SUCCEEDED passing 11153 / failing 0，但 **50(50) unmatched compare points**：
   ref 剩 `io_perf_20..29_value_REG_reg[5:1]`、impl 剩 `perfFl_REG_reg[0..9][5:1]`(= io_perf_10..19)。
   两侧结构逐位相同(perf 高 5 位都是 D 端恒 0 的不复位寄存器)，但 FM 的"常量寄存器(assumed-to-toggle 初值)"
   折叠是逐侧独立做的，各折掉不同的一半 → 各剩 50 个配不上的常量点。修法：`fm_pins_pre.tcl` 在首次 match 前按
   机械规则把 200 个位(20 路 × 2 级 × 5 位)逐一 set_user_match(fail-closed：返回值必须为 1、总数字面 200)。
2. debug 影子寄存器：`fm_pins.tcl` 与 MEFreeList 同一套叶名规则，期望值 530；实测记录：没有 pre-pin 那一轮
   FM 签名分析自己配上了 512 位 RAT、unread 只剩 18；加 pre-pin 后回到 530（签名分析结果随匹配状态变），
   脚本按 pre-pin 在场的口径写死 530。
3. 加两处钉点后：native SUCCEEDED **passing 11153 / failing 0 / unverified 0 / unmatched 六项 0 / unread 0**，
   `constant_reg` 200，dont_verify/elab147/relaxed_appvars 皆空，无黑盒。

### 3.4 跑前预测（★跑完不许改★）

| 项 | 预测 |
|---|---|
| passing | 模型 **11353**（6336 + 5017，登记 docs/fm_predictions/Rename.json）；实测预计 **11153**，差 200 由 receipt `constant_reg`=200 逐位指认（= 20 路 perf × 2 级 × [5:1]，两侧折叠后的常量对） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`RN_PREPIN_END … n=200`，`RN_PIN_END … n=530 miss=0`） |
| 黑盒 | FM-249 No black boxes |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |
