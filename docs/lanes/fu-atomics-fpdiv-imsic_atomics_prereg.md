# fu-atomics-fpdiv-imsic lane · sub=atomics（AtomicsUnit）—— 跑前登记

本文件在 **FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| worktree | `/home/eda/xs-env/wt-fu-atomics-fpdiv-imsic`（分支 `agent/fu-atomics-fpdiv-imsic`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/AtomicsUnit.sv`（1181 行 / 138 端口 / 110 reg 声明，无子模块实例） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无黑盒 |

## 1. 结构

- `rtl/memblock/AtomicsUnit.sv`：package atomicsunit_pkg（状态 enum / DCache 命令 / 触发器动作编码）+
  xs_AtomicsUnit_core（§0 寄存器 / §1 译码握手 / §2 触发器 / §3 TLB / §4 PM / §5 DCache 请求响应 /
  §6 状态机与复位域 / §7 不复位寄存器 / §8 输出）+ golden 同名 wrapper。1012 行，`_GEN_`/`_T_` = 0。
- 寄存器字段集合逐字对齐 golden 110 个 reg 声明（含 uop 的 18 个 debug/seqNum 字段、difftest 打拍 7 组、
  tdata 4 槽 × 8 字段）；复位域：只有 state/out_valid/data_valid/pdest*Valid/stdCnt/exceptionVec/trigger/
  atom_override_xtval/have_sent_first_tlb_req/tEnableVec/backendTriggerCanFireVec/feedback 两拍 valid 带异步复位，其余不复位。
- tdata 4 槽用数组（`tdata_matchType[4]` …）而非 golden 的扁平名；寄存器总数 ~110，靠 FM 签名匹配，不钉点。

## 2. UT（verif/ut/AtomicsUnit，3 seed × initreg {0,random,<seed>017} × 200k）

9 档全部 checks=12398512 errors=0 bad_cov=0（seed 7/42 那 6 档在下一次 clean rebuild 上复跑，读数在对账节追加）。
每档覆盖（seed 1 / 7 / 42）：指令 17635 / 17542 / 17470 条，其中非法 size 1107 / 1072 / 1097，
异常早退 8662 / 8611 / 8425，PM 异常 3474 / 3504 / 3555，replay 1140 / 1158 / 1213，mmio 写回 1750 / 1671 / 1678，
触发器动作 509 / 406 / 313，CASQ 第二拍写回 594 / 614 / 647；9 个状态与 25 个合法编码均过门槛，63 个输出全部见过 0/1。
暖机定式：4 触发器槽各更新一次 + 4 个 std 槽各写一次 + 跑完一条 AMOCAS.Q 与一条 LR 后才开比（WARM_DONE cyc=24）。

★一次假失败，如实记★：第一次矩阵里 seed1×initreg0 报 errors=13929，其余 8 档 0。原因是矩阵紧跟在变异之后跑，
那一档用的是 M8 变异残留的 simv（失配签名恰好是"block_lr=1 时 impl 仍发 dcache 请求"）。删 simv/csrc/ut_gen 后重编，
seed1 三档全部 errors=0。变异 harness 用 cp+mv 还原源文件，mtime 落后于 simv，make 不重编；这个坑在共享 scratch 脚本里，本子任务没改它。

变异自证（seed 7 × 20k，scratchpad 原地注入后还原）：
| 变异 | errors |
|---|---|
| M1 触发器 0 号槽 chain 不屏蔽 | 712 |
| M2 CASQ std 计数 4→3 | 279853 |
| M3 W 掩码不按地址移位 | 15953 |
| M4 W 返回数据零扩展 | 5079 |
| M5 PM 阶段漏 pmp.st | 196 |
| M6 pbmtReg 只在 TLB 命中拍采样 | **0** |
| M7 std 同 uopIdx 两口同拍时口 0 优先 | **0** |
| M8 LR 不看 block_lr | 1228 |

两个没杀掉的变异都是端口上观察不到的：
- M6：pbmtReg 只在 S_PM 那一拍被读，进 S_PM 的那个沿必然是一次 TLB 命中，命中拍两种写法写入同一个值。
  寄存器的次态函数不同，FM 会把它当成 pbmtReg 比较点抓出来，UT 抓不到。
- M7：两口同拍送同一个 uopIdx 违反 golden 的 checkOneHot 断言，tb 只给合法激励，所以不会出现。

## 3. 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/AtomicsUnit.json）

模型：expected = **4024**（golden 寄存器位 2075 + 顶层 output 位 1949），`FM_MERGE_DUP=false`。

**预计 unread（两侧对称死位，按机制分类）**，共 **62** 位：
- `tdata_<j>_tdata2[63:50]` × 4 槽 = 56：触发器比较只看低 50 位（`TriggerCmp` 对 vaddr 的 VAddrBits），高 14 位无读者；
  golden 与核都是 64 位寄存器（照抄位宽，不收窄）。
- `dcache_resp_id[5:1]` = 5：只有 bit0 进 success（Chisel `success := dcache_resp_id`，1 位截断）。
- `difftest_fuop_r[8]` = 1：difftest fuop 只取 [7:0]。

**两步证明**（都走正式 run_proof，各出 receipt）：
1. 第一跑 vmucp 关：预测 native SUCCEEDED，passing **3962**（= 4024 − 62），failing / unverified / unmatched 全 0，
   Not Compared = Unread 62（matched_nc，两侧独占 0），constant_reg 0；strict 判 PARTIAL(strict_unread!=0)。
   ★这一跑是基线，用来证明第 2 跑的 vmucp 不是空转。★
2. 第二跑 vmucp 开（`verif/fm_target_config/AtomicsUnit.tcl` + Makefile `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`）：
   预测 passing **4024**（正好 +62），unread 0，其余全 0，SUCCEEDED。
   六条：精确绑定（上面三组恰 62 位）/ 双射（62 ref ↔ 62 impl 全 matched_nc）/ 真比较（+62）/ 全零 /
   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 配置文件进 script_closure。

可能出错的地方（明写）：
1. 若第一跑 passing ≠ 3962，差额先按 receipt 的 constant_reg / unread 指认；指认不了就是核的问题，修 RTL 不改预测。
2. tdata 数组 vs 扁平名若让签名匹配配错（unmatched ≠ 0），改用 fm_pins_pre.tcl 消名差，不用 set_user_match 修错配。
3. `tdata_<j>_timing` 没有输入口、只被写 0：两侧次态都是 `~update & q`，预计不会被判常量；若被判 constant_reg 会以 4 位出现在差额里。
