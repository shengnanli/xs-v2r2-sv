# LoadQueueRAW lane（agent/lqraw）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（main，`git worktree add /home/eda/xs-env/wt-lqraw -b agent/lqraw 975b64e6`） |
| 工作树 | `/home/eda/xs-env/wt-lqraw`，分支 `agent/lqraw` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `LqMaskModule` / `LqPAddrModule_1`（child，叶子阵列）→ `LoadQueueRAW`（本体） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## 1. LqMaskModule / LqPAddrModule_1（共用核 xs_LqRawDataCam_core）

### 1.1 结构与子模块处置

- 两者都是 Chisel `LqRawDataModule` 基类的子类：32 项 × {16 位掩码 / 24 位部分 paddr}，
  3 写口（分 8 bank、打 1 拍写入、Mux1H 按位或）+ 2 个 violation CAM 口。golden 的读口与
  release CAM 已被 firtool 消掉（父级没接）。可读核 `rtl/memblock/xs_LqRawDataCam_core.sv`
  参数化 DATA_W 与 CAM 规则（LINE_CAM）；两个薄 wrapper 由 `scripts/gen_lqraw.py` 生成（带 `--check`，已登记 gate_all）。
- 每个 wrapper 72 个延迟件（24 × {DelayN_13, DelayNWithValid_52, DelayNWithValid_103 或 _55}）。
  查 `docs/coverage_three_axis.tsv`：四者全部 `PROVEN_DIRECT`。处置 = **两侧白盒**：
  ref 用 golden 同名件，impl 用本仓重写件（`rtl/common/DelayN_13.sv` 等 + `xs_DelayN_core` / `xs_DelayNWithValid_core`）。
  无黑盒。

### 1.2 UT（verif/ut/LqRawCam，两对同测；两档 × 3 seed × 200k）

逐拍比两模块全部 128 个输出口（2×32 位命中向量 × 2 模块）；暖机 32 拍写满 32 项后才开始比。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` |
|---|---|---|
| 1  | checks=199968 errors=0 PASSED | checks=199968 errors=0 PASSED |
| 7  | checks=199968 errors=0 PASSED | checks=199968 errors=0 PASSED |
| 42 | checks=199968 errors=0 PASSED | checks=199968 errors=0 PASSED |

覆盖（seed 1）：写口撞地址 20167 拍、掩码 CAM 命中 359827、地址 CAM 命中 324827、其中 checkLine=1 命中 119726。
判据自证（scratchpad 变异，不进库）：M1 把 checkLine 的"或"改"与" ⇒ errors=32368；
M2 把 Mux1H 按位或改优先级 ⇒ errors=21121（各 20k 拍）。

复跑：`cd verif/ut/LqRawCam && make run SEED=<1|7|42> INITREG=<0|random>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

| 目标 | passing 预测（模型 = golden 闭包寄存器位 + 顶层 output 位） | 其余 |
|---|---|---|
| LqMaskModule    | **1080**（1016 + 64；1016 = 32×16 条目 + 24×(4+1+16) 延迟件） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |
| LqPAddrModule_1 | **1528**（1464 + 64；1464 = 32×24 条目 + 24×(4+1+24) 延迟件） | 同上 |

无 vmucp、无 fm_pins、无 allow/dead_ref 声明。

### 1.4 明写可能出错的地方

1. 两侧延迟件实例路径名不同（golden 扁平 `sx_*_<3b+w>`，impl `u_core/g_bank[b].g_wport[w].*`），
   靠 FM 的名字/签名匹配配对。LqVAddrModule（同一套基类、同样的 generate 命名）已签过，
   预期同样配得上；若出现 unmatched，先查配对再谈别的。
2. 写数据延迟件同一写口 8 份逐位恒等：已关 merge_dup，预期不合并、每份各一个比较点。
   若 passing 少了恰好 21×DATA_W 的倍数，就是合并/配对问题而不是 RTL 问题。
3. 本节没有做过任何 FM 试跑（非正式试跑也没有），数字纯按模型登记。

## 2. LoadQueueRAW（本体，golden 10,261 行 / 100 端口）

### 2.1 结构与子模块处置

- 可读核 `rtl/memblock/LoadQueueRAW.sv`：package loadqueueraw_pkg + xs_LoadQueueRAW_core（§1 入队 / §2 槽状态 /
  §3 出队与 revoke / §4 违例检测与两级选最老 / §5 输出与 perf）+ golden 同名 wrapper。wrapper 与两块 CAM 的扁平
  例化在 GENERATED 区，由 `scripts/gen_lqraw.py` 生成（端口映射表 fail-closed：每个 golden 端口恰好命中一条规则）。
- 寄存器全部按字段 SoA 存（与 golden 扁平寄存器一一对应），结构体只用于组合逻辑。
- golden 直接 child 7 实例 / 6 种全部白盒，impl 用本仓已签核重写件：LqPAddrModule_1 / LqMaskModule（本 lane，
  evidence/341d7e6f14cf）、FreeList_4（rtl/memblock/FreeList.sv 家族核）、DelayN_297 ×2、DelayNWithValid_148/149 ×2，
  以及 CAM 内部的 DelayN_13 / DelayNWithValid_52/55/103。无黑盒。
- FM「匹配前」钉点 `verif/ut/LoadQueueRAW/fm_pins_pre.tcl`（gen_lqraw.py 生成）：golden 顶层 552 个寄存器 / 4196 位
  逐位 set_user_match 到核里的字段数组元素；每个 golden 寄存器恰好命中一条映射规则、映射是单射，否则生成失败；
  运行时逐条数返回值，拒一条或总数 != 4196 即 error。只消名差，不约束 ref。
  依据（实测）：不钉时第一次非正式试跑 Matching 45 分钟未结束（按自己 PID 停掉）；钉后 Matching 约 1 分钟结束，
  0(0) unmatched。child 内部不钉。

### 2.2 UT（verif/ut/LoadQueueRAW；两档 × 3 seed × 200k，在 commit 5459f781 的字节上跑）

逐拍比全部 38 个输出口；不复位寄存器驱动的 rollback bits 在 +random 档按"写过一次"门控（tb 文件头）。
结果见 §对账 C（跑完追加，本节不写数字）。
变异自证（scratchpad，50k 拍）：去掉组级"上一拍 redirect"过滤 ⇒ errors=11655；两两比较反向 ⇒ errors=2794；
**UT 看不见的两处**：M2 revoke 不查 allocated、M3 datavalid 多口写优先级反向 ⇒ UT errors=0
（需要 FreeList 同拍把同一槽发给两口 / 对已释放槽 revoke —— tb 按构造产生不出来），归 FM 兜底，见 §2.4。

### 2.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/LoadQueueRAW.json）

模型：expected = 7326（golden 闭包寄存器位 7116 + 顶层 output 位 210），`FM_MERGE_DUP=false` 模型适用。

lane 内非正式试跑（commit 5459f781 同字节，make fm-LoadQueueRAW，不出正式 receipt，vmucp 关）实测：
native SUCCEEDED，passing 7182 / failing 0 / unverified 0 / unmatched 0(0)，Not Compared：
Constant reg 96 + Unread 48。7326 − 7182 = 144 = 96 + 48，全部可指认：
- **Constant reg 96**：全在 FreeList_4 内部，两侧逐位对称 —— ref `freeList/freeSlotOH_next_nextVec_{0..3}_r_reg` 各 24 位 ↔
  impl `freeList/u_core/freeSlotOHReg_reg` 96 位（matched.rpt 里两侧都标 DFF0/DFF1 类常量）。属 FM 常量折叠，不进比较点。
- **Unread 48**：全是 `matched_nc`，两侧独占 0：ref `detectedRollback_paddrModule_io_violationMdata_{0,1}_r_reg[b]` ↔
  impl `u_core/st_paddr_q_reg[{0,1}][b]`，b ∈ {0..3, 28..47}，恰好 2 × 24 位。
  原因：Chisel `genPartialPAddr(RegEnable(storeIn.paddr, valid))` 先按 48 位全宽打拍、再切 [27:4] 送 CAM，
  golden 与重写核同一个寄存器、同一批死位（照抄 golden 位宽，不收窄 —— 收窄会变成 golden-only 死位）。

**vmucp 预案（按 standing rule 六条，本 commit 同时加入 `verif/fm_target_config/LoadQueueRAW.tcl` 并在 Makefile 开 vmucp）**：
1. 精确绑定：unread 点集合 = st_paddr_q[s][3:0] ∪ [47:28]，s ∈ {0,1}，恰好 48 位；
2. 双射：48 ref ↔ 48 impl 全部 matched_nc（FM 自己按钉点配上），两侧独占 0；
3. 真比较：passing 7182 → **7230**（正好 +48）；不增即空转、判红；
4. 全零：failing / unverified / aborted / unmatched 全 0；
5. 无放宽：dont_verify / elab147 / relaxed_appvars 皆空，无黑盒；
6. 摘要：配置文件进 sidecar/script_closure.list，receipt 记其 sha256。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **7230**（= 模型 7326 − constant_reg 96） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 96（FreeList_4 内 freeSlotOH，两侧对称） |
| 黑盒 | 无 |
| verdict | SUCCEEDED（signoff-strict） |

`fm_predict check` 的对账口径：差额 96 应由 receipt 的 constant_reg=96 指认。

### 2.4 明写可能出错的地方
1. 钉点名形状（`_reg\[s\]\[b\]`）若与正式 run 的工作树不同会早退（error），不会静默。
2. M2/M3 的 FM 覆盖：allocated_* / datavalid_* 都在 passing 的 DFF 比较点里（D 端函数被逐点比较），
   预期 M2/M3 注入后 FM failing 恰好落在 allocated_* / datavalid_*；实测结果见 §对账（scratchpad 变异 worktree，diagnostic-full，不出 receipt）。

## 对账（跑完追加，不改上文任何数字）

### A. LqMaskModule / LqPAddrModule_1（proof commit 341d7e6f，evidence/341d7e6f14cf/）
signoff-strict native SUCCEEDED：LqMaskModule passing **1080** / LqPAddrModule_1 passing **1528**，
failing / unverified / aborted / unread / unmatched 全 0，无黑盒实例，无 dont_verify。
预测 1080 / 1528，差 **+0 / +0**（`fm_predict check` rc=0）。

### B. LoadQueueRAW（proof commit 9d8eede3，evidence/9d8eede3b9f3/LoadQueueRAW/）
signoff-strict、vmucp 开：native SUCCEEDED passing **7230** / failing 0 / unverified 0 / aborted 0 /
unread_notcompared 0 / unmatched 0(0)，constant_reg 96，dont_verify/elab147/relaxed_appvars 皆空，黑盒实例 0，
钉点 `LQRAW_PIN_END ok=4196 bad=0`，fm_target_config/LoadQueueRAW.tcl 在 script_closure 里。
与 §2.3 预测逐项一致；模型 7326 − 实测 7230 = 96 = receipt constant_reg 96（`fm_predict check` rc=0，差额被指认）。

### C. LoadQueueRAW UT（在 5459f781 字节上跑；5459f781..9d8eede3 之间 rtl/ 与 tb 无改动）
| seed | `+vcs+initreg+0` | `+vcs+initreg+random` |
|---|---|---|
| 1  | checks=200000 errors=0 PASSED（rollback 5674/5587） | checks=200000 errors=0 PASSED |
| 7  | checks=200000 errors=0 PASSED（rollback 5603/5505） | checks=200000 errors=0 PASSED |
| 42 | checks=200000 errors=0 PASSED（rollback 5593/5565） | checks=200000 errors=0 PASSED |

### D. UT 看不见的两处变异，FM 是否覆盖（scratchpad 独立 worktree，diagnostic-full、FAILING_LIMIT=0，不出 receipt）
| 变异 | UT（50k 拍） | FM |
|---|---|---|
| M2 revoke 不查 `allocated[lastAllocIndex]` | errors=0 | **FAILED failing 64**（不截断）= 32 × `u_core/allocated_reg[i]` + 32 × `freeList/u_core/freeMask_reg[i]`；passing 7182→7118 |
| M3 datavalid 多口写优先级反向 | errors=0 | **FAILED failing 32**（不截断）= 32 × `u_core/datavalid_reg[i]`；passing 7182→7150 |
即 allocated_* / datavalid_* 的 D 端函数确实在 passing 比较点里，这两类改动由 FM 兜底。
