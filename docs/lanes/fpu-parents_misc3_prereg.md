# fpu-parents lane · misc3 group（agent/fpu-parents）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3f23a91cb`（worktree `/home/eda/xs-env/wt-fpu-parents`，分支 `agent/fpu-parents`，认领 `docs/lanes/fpu-parents_claim.md`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 设计源 | `yunsuan/vector/VectorFloatFMA.scala`（CSA4to2）、`yunsuan/vector/VectorFloatAdder.scala`（FloatAdderWidenFormat）、`xiangshan/backend/fu/wrapper/VPPU.scala` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒 |
| 冲突检查 | codex outbox / codex 分支 / 全部 worktree claim+prereg / 全部分支 rtl diff 均无本 group 目标（主 agent 认领前已查）；child `ShiftLeftPriorityWithF64EXPResult` 归 agent/k3-returned，已签核入 main（evidence/1bf831352049），coverage 表该行写 UNPROVEN 是表未刷新 |

## 1. 结构与 child 处置

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | child（两侧白盒：ref golden 件 / impl 本仓重写件） | UT 目录 |
|---|---:|---:|---:|---|---|
| CSA4to2 | 431 | 73 | 0 | 无（纯组合） | `verif/ut/CSA4to2` |
| FloatAdderWidenFormat | 334 | 166 | 0 | ShiftLeftPriorityWithF32EXPResult ×8（evidence/96c3fe112cb4）、ShiftLeftPriorityWithF64EXPResult ×4（evidence/1bf831352049）；纯组合 | `verif/ut/FloatAdderWidenFormat` |
| VPPU | 350 | 330 | 0 | Permutation（evidence/e7e43874c72f，含 slideup/slidednVs2VdTable）、VPermSrcTypeModule（evidence/a6592249b2e0） | `verif/ut/VPPU` |

- CSA4to2：参数化核 `xs_CSA4to2_core #(WIDTH)`（两级全加 + 按列奇偶交错输出，照 Scala）。与 codex 的 `CSA4to2_16`（8 位，另一份写法）不共享核——那份已签，不动。
- FloatAdderWidenFormat：单元素加宽件 `xs_FloatAdderWidenFormat_widen #(IS_F16)`（规格数重偏置 / 非规格数经 child 归一化）× 12 + 按 uop_idx 选高/低半。
- VPPU：§1 valid/ready 两级链 + perf/seqNum 两级（struct 数组，与 VCVT_8 重写件同口径）、§2 Permutation 输入准备（vmvnr 用编码 EMUL 顶 vlmul、vcompress 前两个 uop 清掩码）、§3 写回。golden 非 SYNTHESIS 的 `assert(fuOpType==dummy)` 不写（同 VCVT_8 / FCVT）。

## 2. UT（golden 与 `<名>_xs` 双例化，200k 拍，9 档 = seed 1/7/42 × `+vcs+initreg+0` / `random` / `<seed>017`）

| 目标 | UT 字节 commit | 9 档结果 | 读数（seed 1） |
|---|---|---|---|
| CSA4to2 | `d292c1bad` | 9/9 errors=0 PASSED | checks=200000、独立 oracle（(a+b+c+d) mod 2^107 == sum+car）200000 次；逐列局部输入组合 13584/13584 全见（第 1..106 列各 128 种 + 第 0 列 16 种 = 逐列穷举） |
| FloatAdderWidenFormat | `5effc756b`（tb 修激励后） | 9/9 errors=0 PASSED | checks=1200000；独立 IEEE oracle（仿真器 shortreal/real 转换）f16→f32 585969 次、f32→f64 365544 次；Inf/NaN 145916、零 102571（只差分，见 rtl 头怪癖）；非规格数 f16 10 种移位量 6921..50329、f32 23 种移位量 738..23941；源高/低半互异 195624 拍；每个非结构恒 0 输出位见过 0/1 |
| VPPU | `d292c1bad` | 9/9 errors=0 PASSED（checks 599991–599995） | 16 个 VpermType 编码各 7781..8195 次 fire；vmvnr 32274；vcompress 清掩码/不清 726/7330；exceptionVec_2 0/1 100324/99676；in_ready=0 10928 拍、第 2 级 payload 停顿 10928 拍 |

复跑：`cd verif/ut/<UT> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 2.1 变异自检（scratch 副本，不碰工作树 rtl；seed 1、20k 拍）

| 目标 | 变异 | 结果 |
|---|---|---|
| CSA4to2 | M1 第二级进位选 c 代替 d / M2 第 50 列奇偶交错反了 / M3 第 0 列进位入改 1 | 全 CAUGHT（errors 37132 / 10764 / 40000） |
| FloatAdderWidenFormat | M1b 重偏置前缀 0111→0110 / M2 非规格尾数不丢移出位 / M3b b_f64 的 uop_idx 反选 / M4 非规格判据只看低 4 位 | 全 CAUGHT（70498 / 51480 / 38153 / 2736） |
| VPPU | M2 第 2 级 payload 不受 ready 门控 / M3 exceptionVec 取 ctrl.vstart / M4 vmvnr 的 EMUL 拼错位 | CAUGHT（1460 / 9928 / 197） |
| VPPU | M1 vcompress 清掩码条件 [6:1]→[6:2]、M5 永不清、M6 只清 uop 2/3 | ★SURVIVED（200k 拍也活）★ |

★两处照实记★：
1. **tb 自身的坑（已修）**：FloatAdderWidenFormat 首版 tb 写 `{mk16(), mk16(), mk16(), mk16()}`，实测 VCS（W-2024.09-SP1，-sverilog）对同一拼接里重复的用户函数调用**只求值一次**（四个半字完全相同；独立小例 `{f(),f(),f(),f()}` 打出 `79a679a679a679a6`）。于是"uop_idx 选高/低半"类错误看不见，M3（b_f64 反选）首轮 SURVIVED。修法：逐个调用存进变量再拼，并把"高/低半互异 >= 一半拍"写进 PASS 判据；修后 M3b CAUGHT，9 档在 `5effc756b` 上重跑。首轮 M1（只改到了文件头注释里的同一串文本）是变异体没改到代码，换锚点重做为 M1b。
2. **VPPU 清掩码逻辑在 UT 上不可观测**：读 `yunsuan/vector/VectorPerm/Permutation.scala`，掩码只经 `vmask_byte_strb_reg0` 用于 vrgather / vslide*，vcompress 路径根本不读掩码 ⇒ VPPU 那条"vcompress 前两个 uop 清掩码"对 io_out_vd 是死逻辑（golden 照抄）。但它改变 Permutation 内寄存器 `vmask_uop_reg0` 的装载值，而该寄存器是 FM 比较点 ⇒ M1/M5/M6 这类错由 FM 覆盖，UT 结构上看不见。

## 3. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model <T> --ut <UT>`）。

| 目标 | 模型 | 预测 constant_reg | 预测 unread（vmucp 前） | 预测 passing | 其余 |
|---|---:|---:|---:|---:|---|
| CSA4to2 | 214（0 + 214） | 0 | 0 | **214** | 不开 vmucp |
| FloatAdderWidenFormat | 256（0 + 256） | 0 | 0 | **256**（含 110 个两侧结构恒 0 的输出位，输出端口照常是比较点） | 不开 vmucp |
| VPPU | 5419（4628 + 791；4628 = 本层 1284 + Permutation 3344） | 14（Permutation 自己签核时的 14 位：base_reg0[3:0]、vs2_bytes_min_reg0[3:0]、ele_cnt_reg0[0]、vlmax_bytes_reg0[0]、vs2_bytes_max_reg0[0]、out_previous_ones_sum_reg0[7:5]） | 128（Permutation 内对称死位，见 `verif/fm_target_config/VPPU.tcl`） | **5405**（vmucp 开） | 不开 vmucp 时应为 5277 + unread 128 |

全部：failing 0 / unverified 0 / unmatched 六项 0 / 黑盒 0 / dont_verify 无 / SUCCEEDED。

### 3.1 明写可能出错的地方

1. VPPU：本层把 Permutation 的输入收窄了（opcode 高 3 位恒 0、vs2Type 高 2 位恒 0、vs1Type 只取三种形状），
   Permutation 内可能因此多出新的常量寄存器 ⇒ constant_reg 可能 > 14、passing 相应 < 5405。我查过 golden
   Permutation 没有寄存器直接存这些高位，所以登记 14；若偏离，按 FM 的 Not Compared 名单逐个指认，不改登记。
2. VPPU 的 128 个死位跨了一层 u_core（ref `VPPU/vperms/...`，impl `VPPU/u_core/u_vperms/u_core/...`），若 FM 没按名配上
   （变成 unmatched unread，fpaddpath 先例），vmucp 会空转——那时停下补钉点，不改判据。
3. 本节登记前没做过任何 FM 试跑。

## 对账（证明 commit `d65d2da41`，登记 commit 同一个——登记在证明之前提交、证明钉在它上）

| 目标 | 结果 | 模型 / 预测 / 实测 passing | constant_reg | failing / unverified / unread / unmatched | 黑盒 / dont_verify | receipt.json sha256 |
|---|---|---|---:|---|---|---|
| CSA4to2 | SUCCEEDED | 214 / 214 / **214**（逐位相等） | 0 | 0 / 0 / 0 / 0 | 0 / 无 | `5c644f8f7cd4eed4f341ef50e159e4aeec83865692b77915a4e75a42d9b711cf` |
| FloatAdderWidenFormat | SUCCEEDED | 256 / 256 / **256**（逐位相等） | 0 | 0 / 0 / 0 / 0 | 0 / 无 | `1446da66fee6863f1894b26100ba7f07b2d5879348b3ec82baa8758201dcdd1b` |
| VPPU | SUCCEEDED | 5419 / 5405 / **5405** | 14 | 0 / 0 / 0（vmucp 开）/ 0 | 0 / 无 | `41d7df2ccc7885d035d2fb9866de094613012422c02b574021ad579fd3d3118f` |

- receipt 路径：`evidence/d65d2da418a4/{CSA4to2,FloatAdderWidenFormat,VPPU}/receipt.json`（`git add -f`，commit `df97b6602`）。
- `python3 scripts/fm_predict.py check CSA4to2 FloatAdderWidenFormat VPPU` rc=0（VPPU 差 14 = constant_reg 14，与登记一致）。
- VPPU vmucp 六条：(1)(2) 128 个死位全部按名配上（5402 by name + 3 by signature，unmatched 0、unread_ref/impl 0，未用钉点）；
  (3) 本轮没跑 vmucp 关的对照，改用等价判据：passing = 模型 5419 − constant_reg 14 = 5405 ⇒ 全部非常量寄存器位（含 128 个死位）都成了 passing 比较点、unread 0；
  (4) 全零；(5) dont_verify / elab147 / 黑盒全空；(6) `sidecar/sourced_002_VPPU.tcl` 进 script_closure。
  constant_reg 只核了个数（14 = 登记），逐名未取（未跑 diagnostic）。

复跑：`PROOF_COMMIT=d65d2da41 bash scripts/run_proof.sh <CSA4to2|FloatAdderWidenFormat|VPPU> <同名> < /dev/null`

## 父级（只列不做）

| 目标 | 父级 | 处置与原因 |
|---|---|---|
| FloatAdderWidenFormat | VectorFloatAdder（coverage MISSING/UNPROVEN） | 父未签，无可重证；将来签 VectorFloatAdder 时 impl 直接读本重写件 |
| VPPU | ExeUnit_13（MISSING/UNPROVEN） | 父未签，无可重证 |
| CSA4to2 | CSA_Nto2With3to2MainPipeline、FMA、VectorFloatFMA | 三者的 UT Makefile 正被未合入 main 的 agent/misc-core 改动（它重写了 CSA_Nto2…，并把 CSA4to2 写成"两侧同源 golden"）；本 lane 改同一批 Makefile 必冲突、且对方证据会过期 ⇒ 待 misc-core 合入 main 后，把 `CSA4to2.sv` 从这三处的 RTL_GOLDEN_DEPS 移到 RTL_SRCS（impl 读重写件）再重证 |
