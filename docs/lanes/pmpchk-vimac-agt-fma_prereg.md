# pmpchk-vimac-agt-fma lane（agent/pmpchk-vimac-agt-fma）—— 跑前登记

本文件在每个目标 **正式 FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。
目标 4（BoothEncoderF64F32F16_3 / VectorFloatFMA）单独登记在 `pmpchk-vimac-agt-fma_fma_prereg.md`。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3e77f50f`，认领 commit `7530a489` / `41689cdb`（追加 PMPChecker、PMPChecker_2） |
| 工作树 | `/home/eda/xs-env/wt-pmpchk-vimac-agt-fma`，分支 `agent/pmpchk-vimac-agt-fma` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无黑盒 |

★本文件里的"非正式试跑"都是在 lane 工作树里直接 `make fm-<T>`（不经 run_proof、不出正式 receipt）得到的；
它们只用来定预测与 vmucp 预案，不是证据。★

## 1. PMPChecker 家族（PMPChecker / PMPChecker_2 / PMPChecker_12，共用核 xs_PMPChecker_core）

### 1.1 结构

- 三者是同一个 Scala 类 `PMPChecker(lgMaxSize, sameCycle, leaveHitMux)` 的三种构造参数：
  `PMPChecker`（L2TLB，sameCycle，纯组合）/ `PMPChecker_2`（Frontend，结果打一拍）/
  `PMPChecker_12`（MemBlock，leaveHitMux：命中位 + 权限 + cmd 打一拍）。
- 可读核 `rtl/backend/xs_PMPChecker_core.sv`（参数 SAME_CYCLE / LEAVE_HIT_MUX / RESP_USED）；
  三个薄 wrapper 与钉点由 `scripts/gen_pmpchecker.py` 生成（带 `--check`）。无子模块、无黑盒。
- `verif/ut/PMPChecker/fm_pins_pre.tcl`：只对 PMPChecker_12 生效，326 位 golden 寄存器逐位
  set_user_match 到核的字段数组（fail-closed：拒一条或总数 != 326 即 error）。
  依据（实测）：不钉时非正式试跑 `62(62) unmatched`、failing 至少 20（截断）——
  golden 的 `res_pmp_r_33_<i>_cfg_r` 被 FM 按名字错配；钉后 unmatched 0(0)。
  PMPChecker（无寄存器）/ PMPChecker_2（2 个寄存器）不钉，FM 自己配。

### 1.2 UT（verif/ut/PMPChecker，三对同测）

逐拍比三个变体的全部输出（3 + 2 + 5 个口）。结果与覆盖计数见文末对账（跑完追加）。
变异自检（scratchpad，20k 拍，第一版 tb）暴露了 tb 的两个盲区，已在登记前补激励：
- TOR 下界 `>=` 改 `>` 抓不到：请求地址低 12 位随机，永远不等于"上一项基址" ⇒ 补"1/4 请求落在区边界"；
- 调试段上界 `<=` 改 `<` 抓不到：打不到 0x38020fff 这个点 ⇒ 补调试段四个边界点；
- 命中位寄存器复位域三个变异抓不到：20k 拍里 arm 之后没有复位事件 ⇒ PMPChecker_12 复位周期改 800 拍。
补完后的变异结果见对账。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

| 目标 | 模型 expected | 预测 passing | 其余 |
|---|---|---|---|
| PMPChecker    | 3（regs 0 + outs 3）     | **3**   | failing 0 / unverified 0 / unmatched 0(0) / unread 0 / constant_reg 0 / 无黑盒 / SUCCEEDED |
| PMPChecker_2  | 4（regs 2 + outs 2）     | **4**   | 同上 |
| PMPChecker_12 | 331（regs 326 + outs 5） | **331** | 同上；钉点 `PMPCHK_PIN_END ... ok=326 bad=0` |

非正式试跑（2026-10-02）：三者 native SUCCEEDED，passing 3 / 4 / 331，unread 0，Not Compared 空。
无 vmucp、无 allow / dead_ref 声明。

### 1.4 明写可能出错的地方

1. PMPChecker_2 的两个结果寄存器在核里是 `g_resp_reg.g_bit[k].g_used.resp_q`，与 golden 的
   `io_resp_r_instr / io_resp_r_mmio` 名字毫无相似处，靠签名配对；试跑配上了，若正式跑 unmatched，先查这里。
2. 正式跑在 detached worktree 里做，路径不同；钉点用的是 `r:/WORK/...` 逻辑路径，不受影响。

## 2. VIMac64b（golden 2,509 行 / 18 端口，0 child）

### 2.1 结构

- 单文件 `rtl/backend/VIMac64b.sv`：xs_VIMac64b_core（§S0 Booth + 34 个加数 + Wallace 前 5 层 /
  §S1 Wallace 后 3 层 + 分段加法 / §S2 取结果、vsmul 舍入饱和、取负）+ golden 同名 wrapper。无子模块、无黑盒、无钉点。
- 寄存器逐个对齐 golden：fire_s1（异步复位）；S0->S1 的 6×128 位 Wallace 中间结果、sew one-hot 4 位、
  highHalf / widen / uopIdx[5:0] / vxrm / isSub / isFixP；S1->S2 的 128 位和与同一组控制。

### 2.2 UT（verif/ut/VIMac64b）

逐拍比 io_vd / io_vxsat。16 个操作 × 4 种 sew = 64 个组合各自计数。结果见对账。

### 2.3 一个被 FM 抓到、UT 结构上看不见的真失配（已修，登记前）

第一次非正式试跑：native **FAILED**，passing 500，failing 至少 20（截断，全在 `io_vd`）。
根因：`sewS2_oneHot` 是不复位的 4 位寄存器，FM 把它当自由状态（可以不是 one-hot）；golden 的
`walOutRnd` / `rndInc` 是 Mux1H（各路按位或），重写核第一版写成"后一个 if 覆盖前一个"，
在非 one-hot 状态下两者不同。UT 里 sew 由 2 位编码译出、永远 one-hot，所以九档全绿也看不见。
修法：对齐 golden，改成按位或（`|=`）。修后试跑 SUCCEEDED。

### 2.4 跑前预测（★跑完不许改本节★）

模型 expected = 1001（regs 929 + outs 72）。
非正式试跑（修后字节，vmucp 关）：native SUCCEEDED，passing 911 / failing 0 / unmatched 0(0)，
Not Compared = Constant reg 80 + Unread 10 对。1001 − 911 = 90 = 80 + 10，全部可指认：
- **Constant reg 80**：全在 `wallaceOut_mid_reg_{1,2,3,4}` 的低位（1 / 8 / 19 / 53 位 —— 取自 matched.rpt 的 DFF0 计数），
  两侧同一批位。来源：进位加数左移后低位恒 0、高层部分积在低位恒 0，FM 判成常量寄存器不出比较点。
- **Unread 10**：`uopIdxS1[5:1]` 与 `uopIdxS2[5:1]`，两侧对称死位（只有 bit0 被读），依据见
  `verif/fm_target_config/VIMac64b.tcl`。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **921**（= 模型 1001 − constant_reg 80） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 80 |
| 黑盒 | 无 |
| verdict | SUCCEEDED（signoff-strict） |

`fm_predict check` 的对账口径：差额 80 应由 receipt 的 constant_reg=80 指认。

## 3. ActiveGenerationTable（golden 2,002 行 / 36 端口，0 child）

### 3.1 结构

- 单文件 `rtl/memblock/ActiveGenerationTable.sv`：activegenerationtable_pkg + xs_ActiveGenerationTable_core
  （§S0 查表 / §S1 update·alloc、活跃判定、送 PHT 的项 / §S2 输出）+ golden 同名 wrapper。
- PLRU 用共享辅助件 `rtl/common/xs_PlruReplacer.sv`（golden 里是本模块的 `state_reg`，Chisel 内联）；
  ref 侧没有对应模块，FM 把 `u_core/u_plru/state_reg` 与 golden `state_reg` 配对（试跑已配上）。无黑盒、无钉点。
- 表项按字段 SoA 存，与 golden 的 16×9 个扁平寄存器一一对应。

### 3.2 UT（verif/ut/ActiveGenerationTable）

逐拍比全部 17 个输出口，26 项功能覆盖计数。结果见对账。
变异自检（scratchpad，30k 拍，+random 档）：18 个里 14 个被抓；4 个 UT 看不见，逐个说明 FM 是否兜底：
- M12（has_been 不看"本拍有项被换出"）：s1_update 与 s1_replacing 同拍为真是不可达状态
  （update 要求 S0 有 lookup，而 alloc 与 update 互斥、dcache 驱逐要求 S0 没有 lookup），UT 按构造产生不出来；
  FM 把寄存器当自由状态，覆盖。
- M13（PLRU 路号的按位或编码改优先级编码）：多项同时命中不可达；FM 覆盖。
- M15（死寄存器 s2_do_evict_q 接常量）：没人读；FM 由 vmucp 的那 1 个比较点覆盖。
- M17（valid 异步复位改同步）：tb 的复位脉冲总跨一个上升沿，且 valid 不直通输出；复位域由 FM 覆盖。

### 3.3 跑前预测（★跑完不许改本节★）

模型 expected = 1730（regs 1564 + outs 166）。
非正式试跑（commit 0ae2a186 字节，vmucp 关）：native SUCCEEDED，passing 1729 / failing 0 / unmatched 0(0)，
Not Compared = Unread 1 对（`s2_do_dcache_evict_last_REG` <-> `u_core/s2_do_evict_q`），Constant reg 0。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **1730**（= 模型，差额 0） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 0 |
| 黑盒 | 无 |
| verdict | SUCCEEDED（signoff-strict） |

### 3.4 明写可能出错的地方

1. PLRU 状态在 impl 里多一层 `u_plru`，golden 没有这层；若正式跑出现 15 个 unmatched，就是它。
2. `FMR_VLOG-063`（signed -> unsigned 赋值告警）两处来自 `WAY_W'(i)` / `OFFSET_W'(...)` 的 int 截位，试跑不影响结论。

## 对账 A（2026-10-02，正式 run_proof @76a7067b，evidence/76a7067be695/）

| 目标 | native | passing | failing | unmatched | unread | constant_reg | verdict | 与 §预测 |
|---|---|---|---|---|---|---|---|---|
| PMPChecker    | SUCCEEDED | 3   | 0 | 0(0) | 0 | — | SUCCEEDED | 逐位相等 |
| PMPChecker_2  | SUCCEEDED | 4   | 0 | 0(0) | 0 | — | SUCCEEDED | 逐位相等 |
| PMPChecker_12 | SUCCEEDED | 331 | 0 | 0(0) | 0 | — | SUCCEEDED | 逐位相等（钉点 ok=326 bad=0） |
| VIMac64b      | SUCCEEDED | 911 | 0 | 0(0) | 10 | 80 | **PARTIAL**(strict_unread!=0) | passing 没按 §2.4 涨到 921 |
| ActiveGenerationTable | SUCCEEDED | 1729 | 0 | 0(0) | 1 | 0 | **PARTIAL**(strict_unread!=0) | passing 没按 §3.3 涨到 1730 |

VIMac64b / ActiveGenerationTable 的 vmucp 没起作用，原因（从 receipt 与 fm.log 读出）：
appvar `verification_verify_matched_unread_compare_points` 已为 true（receipt.proof_config.entry_appvars_readback），
但那 10 + 1 个死位在 FM 里是 **unmatched-unread**（`report_unmatched_points -status unread` 列出两侧各 10 / 1 个；
"Not Compared" 表里没有 Unread 行，passing 的 DFF 列是 839 = 929 − 80 − 10）—— FM 默认不给 unread 点配对，
vmucp 只比 matched 的 unread 点。§2.4 / §3.3 把"FM 自己配上"写成了事实，错了：试跑的 unread_points.txt
本来就是 unmatched 列表，我没分辨 matched_nc 与 unmatched-unread。
修法（与 LoadQueueRAW 同一条路）：加 `fm_pins_pre.tcl` 把这几个寄存器 set_user_match 成 matched 点
（VIMac64b 钉 uopIdxS1/S2 整 6 位 × 2 = 12，fail-closed；AGT 钉 1 位），其余预测数字不变。
钉后非正式试跑：VIMac64b SUCCEEDED passing **921** / unread 0 / constant_reg 80；
ActiveGenerationTable SUCCEEDED passing **1730** / unread 0。正式复跑见对账 B。

## 对账 B（正式 run_proof @e7a91a91，evidence/e7a91a910053/）

| 目标 | verdict | passing | failing | unmatched | unread | constant_reg | 预测 | 差额指认 |
|---|---|---|---|---|---|---|---|---|
| VIMac64b | SUCCEEDED | 921 | 0 | 0(0) | 0 | 80 | 921 | 1001−921 = 80 = constant_reg |
| ActiveGenerationTable | SUCCEEDED | 1730 | 0 | 0(0) | 0 | 0 | 1730 | 0 |

`python3 scripts/fm_predict.py check VIMac64b ActiveGenerationTable` → 全部对上。
