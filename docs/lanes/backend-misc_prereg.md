# backend-misc lane（agent/backend-misc）—— 跑前登记

本文件在 **正式 FM（scripts/run_proof.sh）起跑之前**提交；跑完只在文末「对账」追加，★不改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `1ce47a77a` + 认领 `68eedb817`（worktree `/home/eda/xs-env/wt-backend-misc`，分支 `agent/backend-misc`，认领 `docs/lanes/backend-misc_claim.md`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒；child 全部 PROVEN_DIRECT → 两侧白盒（ref golden / impl 重写件） |
| 冲突检查 | codex outbox 最新 0209、codex/* 分支相对 main 的 rtl 改动、全部 worktree 的 `*_claim.md`/`*_prereg.md` 精确模块名：本 lane 12 个目标无他人认领或改动（fpu-parents / misc-core 的 prereg 只"列而不做"） |
| 分工 | VecExcpDataMergeModule / Reduction / FloatDividerR64 / FloatAdderF16Pipeline + FarPathFloatAdderF64WidenPipeline 由本 lane 的 4 个 fork 助手在 scratchpad 的 git clone 里起草 RTL+UT（不跑 FM），cherry-pick 进本分支；其余 7 个与全部 FM / 登记由 lane 主体做 |

## 1. 目标一览（结构、child、行数）

| 目标 | golden 行 / `_GEN_`+`_T_` | impl 文件 / 行 / `_GEN_`+`_T_` | child（两侧白盒） | UT 目录 |
|---|---|---|---|---|
| CryptoModule | 138 / 0 | rtl/backend/CryptoModule.sv / 57 / 0 | HashModule, BlockCipherModule | CryptoModule |
| StorePfWrapper | 97 / 0 | rtl/memblock/StorePfWrapper.sv / 27 / 0 | Serializer | StorePfWrapper |
| VectorFloatDivider | 161 / 0 | rtl/backend/VectorFloatDivider.sv / 85 / 0 | VectorFloatDividerR64 子树、fpsqrt_vector_r16 子树 | VectorFloatDivider |
| PFEvent | 288 / 0 | rtl/backend/PFEvent.sv / 87 / 0 | perfEventsModule ×24 | PFEvent |
| HPerfMonitor | 737 / 0 | rtl/common/HPerfMonitor.sv / 612 / 0 | HPerfCounter ×8（xs_HPerfCounter_core） | HPerfMonitor |
| HPerfMonitor_1 | 596 / 0 | rtl/common/HPerfMonitor_1.sv / 492 / 0 | HPerfCounter_8 ×5（xs_HPerfCounter_core） | HPerfMonitor |
| HPerfMonitor_2 | 1088 / 0 | rtl/common/HPerfMonitor_2.sv / 963 / 0 | HPerfCounter_13 ×8（xs_HPerfCounter_core） | HPerfMonitor |
| VecExcpDataMergeModule | 1825 / 609 | rtl/backend/VecExcpDataMergeModule.sv / 731 / 0 | DelayN_13, GetE8OffsetInVreg, NfMappedElemIdx | VecExcpDataMergeModule |
| FloatDividerR64 | 766 / 167 | rtl/backend/FloatDividerR64.sv / 589 / 0 | fpdiv_r64_block 子树, ShiftLeftPriorityWithLZDResult ×2 | FloatDividerR64 |
| Reduction | 1394 / 422 | rtl/backend/Reduction.sv / 700 / 0 | CSA3to2_124/125/127/132, CSA4to2_15/16, compare_2to1/_2, compare_3to1/_1/_2/_6（+Adder_xb*） | Reduction |
| FloatAdderF16Pipeline | 319 / 31 | rtl/backend/FloatAdderF16Pipeline.sv / 318 / 0 | ClosePathF16Pipeline 子树, FarPathF16Pipeline 子树 | FloatAdderF16Pipeline |
| FarPathFloatAdderF64WidenPipeline | 319 / 21 | rtl/backend/FarPathFloatAdderF64WidenPipeline.sv / 300 / 0 | Adder ×2, FarShiftRightWithMuxInvFirst ×2, FarPathAdderF64WidenPipeline ×2 | FarPathFloatAdderF64WidenPipeline |

共享核 / 公共 filelist 未改（xs_HPerfCounter_core 与 xs_HPerfCounter_idx8_core 均未动：HPerfMonitor/_1/_2 的 child 是 HPerfCounter/_8/_13，
挂的是 xs_HPerfCounter_core，照 golden 选）。新生成器 `scripts/gen_hperfmon.py`（三个 HPerfMonitor 变体的端口表与例化连线，带 `--check`，幂等）。

## 2. 证明配置（新增的 per-target 文件，均在本文件提交之前已入库）

| 目标 | 钉点 | vmucp（fm_target_config） | dead_ref | appvar |
|---|---|---|---|---|
| CryptoModule | — | CryptoModule.tcl：funcReg[0..3,5..8] 8 位对称死位 | — | — |
| StorePfWrapper | — | StorePfWrapper.tcl：serializer 死指针 5 位（零扇出，同 Serializer） | — | verification_assume_reg_init none（同 Serializer.tcl，加强） |
| HPerfMonitor / _1 / _2 | — | — | verif/dead_ref/<T>.json：每计数器 event_op_{0,1,2,2_reg}[4:3] 8 点，64 / 40 / 64 | — |
| VecExcpDataMergeModule | verif/ut/VecExcpDataMergeModule/fm_pins_pre.tcl（750 位） | — | — | — |
| FloatDividerR64 | — | FloatDividerR64.tcl：fp_format_onehot_q[2] 1 位 | — | — |
| Reduction | verif/ut/Reduction/fm_pins_pre.tcl（817 位） | Reduction.tcl：vdType_reg_s1[3:2] 2 位 | — | — |
| FloatAdderF16Pipeline | verif/ut/FloatAdderF16Pipeline/fm_pins.tcl（3 对） | FloatAdderF16Pipeline.tcl：close 子树既有对称死位 | — | — |
| 其余 | — | — | — | — |

## 3. 跑前预测（★跑完不许改本节★；登记 JSON 见 docs/fm_predictions/<T>.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model <T> --ut <UT>`）。
**如实声明**：下表预测值全部经过 lane 内非正式试跑（`make fm-<T>`，活动工作树、
不出正式 receipt）校准；试跑暴露并已修掉两处 RTL 问题（见 §4），修后的试跑读数即下表"试跑"列。

| 目标 | 模型 | 预测 passing | constant_reg | unread / failing / unmatched | 预期判定 | 试跑（commit） |
|---|---:|---:|---:|---|---|---|
| CryptoModule | 703 | **703** | 0 | 0 / 0 / 0 | SUCCEEDED | 703（9166c27） |
| StorePfWrapper | 5 | **5** | 0 | 0 / 0 / 0 | SUCCEEDED | 5（9166c27） |
| VectorFloatDivider | 1090 | **1089** | 1 | 0 / 0 / 0 | SUCCEEDED | 1089 + const 1（9166c27） |
| PFEvent | 3000 | **3000** | 0 | 0 / 0 / 0 | SUCCEEDED | 3000（9166c27） |
| HPerfMonitor | 688 | **624** | 0 | unread 64（全 ref，= dead_ref 声明）/ 0 / 0 | PASS_DEAD_REF | 624 + unread 64 ref（9166c27，声明前 PARTIAL） |
| HPerfMonitor_1 | 430 | **390** | 0 | unread 40 ref / 0 / 0 | PASS_DEAD_REF | 390（9166c27+声明） |
| HPerfMonitor_2 | 688 | **624** | 0 | unread 64 ref / 0 / 0 | PASS_DEAD_REF | 624（9166c27+声明） |
| VecExcpDataMergeModule | 1363 | **1363** | 0 | 0 / 0 / 0 | SUCCEEDED | 1363（修后，d32f9a1 字节） |
| FloatDividerR64 | 437 | **410** | 27 | 0 / 0 / 0 | SUCCEEDED | 410 + const 27（vmucp 开） |
| Reduction | 945 | **945** | 0 | 0 / 0 / 0 | SUCCEEDED | 945（修后，vmucp 开） |
| FloatAdderF16Pipeline | 230 | **225** | 5 | 0 / 0 / 0 | SUCCEEDED | 225 + const 5 |
| FarPathFloatAdderF64WidenPipeline | 442 | **442** | 0 | 0 / 0 / 0 | SUCCEEDED | 442（327fe30） |

全部：无黑盒、dont_verify / elab147 / relaxed_appvars 空。差额逐项指认：
- VectorFloatDivider 1：child 子树内既有常量位（试跑 constant_reg=1）。
- HPerfMonitor 族 64/40/64：child HPerfCounter* 的 event_op[4:3]（golden 5 位只读 [2:0]；已签 child 自己就是 PASS_DEAD_REF 8 点）。
- FloatDividerR64 27：frac_divisor_q_60bit[2:0]（每次写 0）+ f_r_s_q_72bit[11:0] + f_r_c_q_72bit[11:0]（初值与迭代块输出低 12 位恒 0），两侧对称。
- FloatAdderF16Pipeline 5：io_fflags_r_1[3:0] 两侧字面 0 + close 子树 op1[10]（child 签核时同一位）。

## 4. 试跑暴露、已修的 RTL 问题（均在登记之前修复并补 UT）

1. VecExcpDataMergeModule：always_ff / always_comb 循环体内的 `int` 局部量（rabLoc/ratLoc/vdRab/vdRat）被 FM 推成 192 个
   impl-only 寄存器位（unread impl 192，passing 已等于模型）。改为 always_comb 预算 rabVd/ratVd 数组与常数下标表达式。
2. Reduction：alu 进位链在同一 always_comb 里自读自写 cout（FMR_VLOG-929）且 sel_lo 动态下标可越界（FMR_ELAB-147），
   set_top 失败。改为 genvar 连续赋值 + 4 位下标（恒在 0..15）。
二者 UT 均在修后字节上 9 档重跑（结果见对账）。

## 5. UT（9 档：seed 1/7/42 串行 × `+vcs+initreg+0` / `+vcs+initreg+random` / `+vcs+initreg+<seed>017`，各 200k 拍）

复跑：`cd verif/ut/<UT> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。读数、覆盖、变异在对账节追加（本节不写数字）。
独立 oracle：CryptoModule（Zknh/Zksh 哈希定义式）、PFEvent（mhpmevent 布局 + OPTYPE WARL）、HPerfMonitor 族（HardwarePerfMonitor 语义）、
VectorFloatDivider（IEEE 除法 + 新写的宽整数开方）、FloatDividerR64（IEEE 除法）、Reduction（整数归约语义）、两个加法器（IEEE 加减等）；
StorePfWrapper（层次探针 + 状态注入）与 VecExcpDataMergeModule 只做差分。

## 6. 正式证明命令

`bash scripts/run_proof.sh <UT> <T...> < /dev/null`，同时最多 2 个。

## 对账 1：正式证明（run_proof.sh，impl commit `6038c4afb` = 登记 commit，登记早于证明；receipt 入库 `d0fa8332f`）

| 目标 | 预测 | 实测 passing | constant_reg | unread / failing / unmatched | 黑盒 / dont_verify | 判定 | receipt.json sha256 |
|---|---:|---:|---:|---|---|---|---|
| CryptoModule | 703 | **703** | 0 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `dffe7971b722824fbebbe81edd0cd5992bd9f385d325f17a19e4b5da6bfbca9e` |
| StorePfWrapper | 5 | **5** | 0 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `9a9522daf75f2b80889b87b076a417b064b33db5a6bdf23dd2c6d941d350f69b` |
| VectorFloatDivider | 1089 | **1089** | 1 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `be6782c0a160d89f04e54647e38c193256ce89865efd0f19c48a54b7d0810b06` |
| PFEvent | 3000 | **3000** | 0 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `db41aa7145749a09d96797367fde3e74999cda1375e6dfb64ced0d49395d53b3` |
| HPerfMonitor | 624 | **624** | 0 | 64 ref（= dead_ref）/ 0 / 0 | 0 / 否 | PASS_DEAD_REF | `8ff9a9a8709e382efc1ad39badda467060c7946235e219787f52b39105f712d2` |
| HPerfMonitor_1 | 390 | **390** | 0 | 40 ref（= dead_ref）/ 0 / 0 | 0 / 否 | PASS_DEAD_REF | `ef67ee17c4a2cbedd69f54aa815fdc93ca106e5cc76240a510501b677384b7f0` |
| HPerfMonitor_2 | 624 | **624** | 0 | 64 ref（= dead_ref）/ 0 / 0 | 0 / 否 | PASS_DEAD_REF | `cbc007137e99ad9776847a5dedf00f5f033ceb0389c7ae1bf362a116c34f4c1b` |
| VecExcpDataMergeModule | 1363 | **1363** | 0 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `23c5721845466cce847dab94e0eb5542cce34459670abc25c1034e87e3512814` |
| FloatDividerR64 | 410 | **410** | 27 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `d1ae3481807989d86617e7f23ea0fe9e0ca42133f94a85d6b2a8ce3a3454e975` |
| Reduction | 945 | **945** | 0 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `b9564ae6dcd8776c85497548343271d9b9e1a20e80620c20667ffb8924cfec58` |
| FloatAdderF16Pipeline | 225 | **225** | 5 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `d0f366974a0e3d63d420e9660bf1f5a21ca34ebfe0f3deda7012d3fdaf5b5cf9` |
| FarPathFloatAdderF64WidenPipeline | 442 | **442** | 0 | 0 / 0 / 0 | 0 / 否 | SUCCEEDED | `dce82fe5e2ebc38c49d80a41bbfda3fd920696825c46f4112ea837107974c185` |

`python3 scripts/fm_predict.py check <12 个目标>` rc=0「全部对上」（5 个逐位相等之外，差额全部由 receipt 的 constant_reg / unread 指认）；
`python3 scripts/check_lane_receipts.py /home/eda/xs-env/wt-backend-misc` rc=0。
插曲：PFEvent / VectorFloatDivider 第一次 run_proof 因根分区写满（`No space left on device`，git worktree add 失败，未进 FM）没跑起来，
删掉本 lane 自己的 4 个 fork clone 腾出空间、`TMPDIR` 指到 /home 后同一 commit 重跑通过。

## 对账 2：UT 9 档（lane 分支字节，seed 串行，各 200k 拍）

全部 108 档 TEST PASSED、errors=0（每目标 9 档；HPerfMonitor 族三对同 tb）：

| UT | checks/档（seed 1 / 7 / 42） | 独立 oracle | 覆盖（seed 1，均写进 PASS 判据） |
|---|---|---|---|
| CryptoModule | 199992 ×3 | 哈希 51483 次 0 错 | 10 条哈希指令各 ≥5043；选哈希/选密码 99586/100406；保持拍 50285 |
| StorePfWrapper | 200000 ×3 | —（层次探针 + 状态注入） | 32 种注入值各 ≥200；回绕 30630；复位 4024 |
| VectorFloatDivider | 799928 / 799954 / 799968 | 15124 / 15142 / 15084 次 0 错（除法 + 开方） | div 结果六类 8582/3260/1629/2564/1118/1057；sqrt 四类 12075/5026/451/890；flush 中途 914；违规发起 2915 |
| PFEvent | 4799808 ×3 | 199992 拍 0 错 | 24 副本各被写；越界地址写 12433；OPTYPE 拒收 22195 |
| HPerfMonitor（三对） | 4199664 ×3 | 三变体各 199995 拍 0 错 | op2 四种 ≥1000（ADD 37238 等）；缺槽 25256 / 越界 29526（_1 无缺槽，越界 73829） |
| VecExcpDataMergeModule | 6398720 ×3（修后字节 d32f9a1） | — | 状态五态全到（见 fork 报告） |
| FloatDividerR64 | 799982 / 799990 / 799992 | 32530 / 32527 / 32390 次 0 错 | 3 格式 × 5 rm；结果六类与五标志 |
| Reduction | 199997 ×3（修后字节 d32f9a1） | 170004 / 170040 / 170170 次 0 错 | 8 运算 × 4 sew ≥1725 |
| FloatAdderF16Pipeline | 199999 / 199998 / 199999 | 0 错 | 22 op 各 ≥1000 |
| FarPathFloatAdderF64WidenPipeline | 399999 / 399997 / 399999 | 0 错 | 四种进位/溢出路径 |

同一 seed 的三个 initreg 档读数相同：各 tb 都在全部不复位寄存器被写过之后才开始比（暖机 / arm），initreg 只影响比较窗口之前。
VecExcpDataMergeModule 修前字节（9166c27）的 9 档也全过（6398720 ×9）。

变异自证（scratchpad 拷贝，seed 7 / initreg 0 / 20k 拍，独立施变，不进库），lane 主体 7 个目标 11/11 被差分抓到：
C1 选择位 [4]→[3] 15735（oracle 4190）；C2 用当拍 io_func 选 12659（2649）；C3 funcReg 去掉使能 3063（613）；
P1 基址 0x323→0x324 957488（oracle 478744）；P2 写使能去掉 valid 658388（329194）；
H1 HPerfMonitor_2 第 3 路少打一拍 36676（18342）；H2 HPerfMonitor_1 第 4 计数器接 hpm_event_3 38246（19128）；
V1 start_ready 与→或 16967；V2 开方格式不减 1 10501（oracle 792）；V3 结果按 sqrt 优先二选一 16625；S1 serializer 不接复位 400。
fork 目标的变异（VecExcp 6/7、FDivR64 5/6、Reduction 8/8、F16 5/5、F64W 4/4）见各 fork 报告；UT 漏网的两个
（VecExcp M5 hasReadRf 写优先级反转——等价变异；FDivR64 M5 sticky_correct 去 rem_is_not_zero——随机打不到）由 FM 覆盖（两目标 FM 全过）。
