# k3-returned lane（agent/k3-returned）—— 跑前登记

本文件在 **FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3de72b255`（claim commit `f626dcacb`） |
| 工作树 | `/home/eda/xs-env/wt-k3-returned`，分支 `agent/k3-returned` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 被证明字节 | commit `84ab6f364`（RTL + UT），本登记 commit 晚于它、早于任何 FM |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无 vmucp，无 fm_pins，无黑盒 |
| 冲突核查 | codex outbox 最新 0207 未涉及本 lane 目标；`codex/*` 与 `agent/*` 分支相对 main 的 rtl 改动里只有 newrtl-next200c 有 `IntBuffer_1/_2`（不同变体，本 lane 不碰、不依赖）；fpaddpath-sqrtblock 的 3 个 rtl 文件与本 lane 无交集；所有 worktree 的 `*_claim.md` 中这 8 个名字只出现在本 lane claim |

## 1. 目标与结构

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | 文件 | 时序 | child |
|---|---|---|---|---|---|---|
| ShiftLeftPriorityWithLZDResult_6 | 158 | 53 | 0 | rtl/backend/ | 组合 | 无 |
| ShiftLeftPriorityWithLZDResult_8 | 123 | 53 | 0 | rtl/backend/ | 组合 | 无 |
| ShiftLeftPriorityWithF64EXPResult | 155 | 54 | 0 | rtl/backend/ | 组合 | 无 |
| FarPathAdderF16Pipeline | 124 | 48 | 0 | rtl/backend/ | 2×12 位 RegEnable，无复位 | 无 |
| Std | 106 | 64 | 0 | rtl/backend/ | 组合 | 无 |
| MemExeUnit | 125 | 98 | 0 | rtl/backend/ | 组合 | Std（本 lane，两侧白盒：ref golden Std.sv，impl rtl/backend/Std.sv） |
| IntBuffer | 123 | 43 | 0 | rtl/backend/ | 1 位，异步高有效复位到 0 | 无 |
| PrefetchReceiver | 103 | 60 | 0 | rtl/l2/ | 组合 | 无 |

- shift-priority 三变体：`scripts/gen_shiftpriority_leaves3.py`（`--check` 幂等）生成，模板与已签的
  `gen_shiftpriority_leaves2.py` 同构，但旁路输出位宽与指数偏置参数化（LZD_6 W=24/5 位、LZD_8 W=11/4 位、
  F64EXP W=23/11 位偏置 0x380）。**已签的 gen_shiftpriority_leaves2.py 及其两个输出未改动**，故无需
  `check_shared_impl_impact.py`。
- FarPathAdderF16Pipeline：AW=12、stage0AdderWidth=0 的"先打拍后相加"一支；与 fpaddpath-sqrtblock 的
  FarPathF32WidenF16MixedAdderPipeline（切段一支）不共享核，不碰其文件。
- IntBuffer：rocket-chip/utility IntBuffer depth=1 cdc=false（RegNextN 初值 0），异步复位照 golden。
  newrtl-next200c 的 IntBuffer_1/_2 未合入，本文件不依赖它们。

## 2. UT（在 `84ab6f364` 字节上跑；3 seed × 3 initreg × 200k，串行）

每个 UT = golden 与 `<名>_xs` 双例化逐拍比全部输出 + tb 内独立 oracle/影子模型 + 覆盖闸（任一桶为 0 判红）。

| UT 目录 | 目标 | 9 档结果 | 覆盖（seed 1 / 7 / 42） |
|---|---|---|---|
| ShiftPriorityLeaves3 | LZD_6 / LZD_8 / F64EXP | 9/9 errors=0，各 vectors=200048（×3 模块） | 移位量直方图全桶命中：LZD_6 25 桶 min 3944/4014/3957；LZD_8 12 桶 min 8695/8688/8671；F64EXP 24 桶 min 4216/4123/4119 |
| FarPathAdderF16Pipeline | FarPathAdderF16Pipeline | 9/9 errors=0，checks 200000（+0 档）/ 199998~199999（非常量档，首次 fire 前不比） | fire 120217/119980/119995，hold 79783/80020/80005，连发 72260/72080/72053，12 位回绕进位 137781/137389/137863 |
| MemExeUnit | Std + MemExeUnit | 9/9 errors=0，各 vectors=200000 | {valid,ready} 四组合各 ~5 万 |
| IntBuffer | IntBuffer | 9/9 errors=0，checks 404040/403992/403938 | 拍间异步复位脉冲 4039/3991/3937，其中清掉高电平输出 2079/2042/1956；输入翻转 rise/fall 各 ~3.3 万 |
| PrefetchReceiver | PrefetchReceiver | 9/9 errors=0，各 vectors=200128 | {enable,valid} 四组合各 ~5 万；64 位 walking-1/0 定向 128 向量 |

initreg 三档 = `+vcs+initreg+0` / `+vcs+initreg+random` / `+vcs+initreg+<seed>017`（1017/7017/42017）。
复跑：`cd verif/ut/<UT> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

变异自证（scratchpad 拷贝，不进库；20k 拍，seed 7 × random）：11/11 被 UT 抓到 ——

| 编号 | 变异 | errors |
|---|---|---|
| SP_M1 | LZD_6 优先级反向（最低位赢） | 23546 |
| SP_M2 | F64EXP 偏置 0x380→0x37F | 40096 |
| SP_M3 | LZD_8 全零回退计数 11→10 | 6640 |
| FP_M1 | 去掉 fire 使能 | 15932 |
| FP_M2 | B 不打拍直接加 | 15930 |
| ME_M1 | Std in_ready 多与 in_valid | 15171 |
| ME_M2 | MemExeUnit sqIdx.flag 接成 robIdx.flag | 19994 |
| IB_M1 | 异步复位改同步 | 227 |
| IB_M2 | 复位值 0→1 | 442 |
| PR_M1 | set 字段错一位 | 39976 |
| PR_M2 | valid 漏与 enable | 10164 |

UT 看不见的变异：无（本批全组合或单级寄存器，状态空间被 UT 穷尽式覆盖）。

## 3. 跑前预测（★跑完不许改本节★；登记 docs/fm_predictions/<T>.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`FM_MERGE_DUP=false`，模型适用）。

| 目标 | passing 预测 | 其余 |
|---|---|---|
| ShiftLeftPriorityWithLZDResult_6 | **29**（0 + 29） | failing 0 / unverified 0 / aborted 0 / unmatched 0 / unread 0 / 黑盒 0 / SUCCEEDED |
| ShiftLeftPriorityWithLZDResult_8 | **15**（0 + 15） | 同上 |
| ShiftLeftPriorityWithF64EXPResult | **34**（0 + 34） | 同上 |
| FarPathAdderF16Pipeline | **36**（24 + 12） | 同上 |
| Std | **75**（0 + 75） | 同上 |
| MemExeUnit | **126**（0 + 126；Std 白盒、组合无寄存器） | 同上 |
| IntBuffer | **2**（1 + 1） | 同上 |
| PrefetchReceiver | **48**（0 + 48） | 同上 |

### 明写可能出错的地方

1. F64EXP 的 io_exp_result 在全部 24 个取值（0x380..0x369）里 bit10 恒 0、bit9 恒 1；LZD 系列无恒值位。
   若 FM 把恒值输出口记为 constant 而不计 passing，F64EXP 会少 2（预测 34 → 32），差额由 receipt 的常量项指认。
2. MemExeUnit 的 impl 实例名 `u_std` 与 golden `Std` 不同；子模块无状态，只影响层次名，不影响比较点数。
3. 本节没有做过任何 FM 试跑（非正式也没有），数字纯按模型登记。

## 对账（跑完追加；以上各节未改动）

证明：`bash scripts/run_proof.sh <UT> <T> < /dev/null`，signoff-strict，被证明 commit `1bf831352`
（= 登记 commit；RTL 字节同 `84ab6f364`），证据 `evidence/1bf831352049/<T>/`，收录 commit `4e5144a7b`。

| 目标 | 预测 | 实测 passing | 差 | failing | unverified | aborted | unread_nc | unmatched(ref/impl) | dont_verify/elab147/relaxed | receipt.json sha256 |
|---|---|---|---|---|---|---|---|---|---|---|
| ShiftLeftPriorityWithLZDResult_6 | 29 | 29 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `bc1220cb11ef4ee9d096ef74aa8f61768236e26453c2c7fa8f9cb1979c86746b` |
| ShiftLeftPriorityWithLZDResult_8 | 15 | 15 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `890efa2f7bf84c8b4c3983745a4aa57ba938f31cc08d8dad6af4d831a58e4f16` |
| ShiftLeftPriorityWithF64EXPResult | 34 | 34 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `7d0bfecda2afa53270f2a22a671d553aa5c2fc801e8f3bb33d26aab02d94b3de` |
| FarPathAdderF16Pipeline | 36 | 36 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `93c640e882be3bc13f5499ab3bb0dcda64392f71563817f2c7957f81a3c00fe4` |
| Std | 75 | 75 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `d18afe9ca00cee1c3ec44d0ff5140678357cf2f57a23b91ab89b1f18ff1fcb12` |
| MemExeUnit | 126 | 126 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `81c777e0cce6e8f461fc31555296a4a5f4686523b7c15abfd0d2900cabe1b5af` |
| IntBuffer | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `8ceb025435ff2d907ede7d706c8cdcdeac33e7130b19bb9466d046f3d0cfc0e5` |
| PrefetchReceiver | 48 | 48 | 0 | 0 | 0 | 0 | 0 | 0/0 | 空/空/空 | `d0b617d15bcf7a6e34e41fd79115465629b5f741e9695c6662b23125d453f010` |

- 全部 native SUCCEEDED、verdict SUCCEEDED；8/8 预测与实测逐位相等。§3 第 1 条担心的 F64EXP 恒值输出位（bit10/bit9）
  照常计入 passing，未出现差额。
- 黑盒：blackbox_out=0。Std 与三个 shift 叶的 black_boxes.rpt 列出的是同一 impl 源集合里**未被例化的兄弟模块**
  （如 Std 证明时的 MemExeUnit / xs_MemExeUnit_core，Instances : 0，标 e*），不在被验设计内。
- `python3 scripts/fm_predict.py check <8 个目标>` rc=0（全部"逐位相等"）；
  `python3 scripts/check_lane_receipts.py /home/eda/xs-env/wt-k3-returned` rc=0；
  `python3 scripts/gen_shiftpriority_leaves3.py --check` OK；`python3 scripts/readability_audit.py --quiet` rc=0。

### 因本 lane child 全绿的父级（本 lane 不做）

按 golden 例化扫描 + `docs/coverage_three_axis.tsv` 第 3 列：
- **VectorFloatDividerR64**：fpdiv_r64_block_vector、ShiftLeftPriorityWithLZDResult（PROVEN_DIRECT）+ LZD_6 ×2、LZD_8 ×4（本 lane）→ child 全绿。
- **FloatAdderWidenFormat**：ShiftLeftPriorityWithF32EXPResult ×8（PROVEN_DIRECT）+ F64EXP ×4（本 lane）→ child 全绿。
- **FarPathF16Pipeline**：Adder_18、FarShiftRightWithMuxInvFirst_18（PROVEN_DIRECT）+ FarPathAdderF16Pipeline ×2（本 lane）→ child 全绿。
- 仍未全绿：MemBlock（DCacheWrapper 等 8 个 UNPROVEN）、L2Top（BusErrorUnit/TL2CHICoupledL2/TLBuffer_13/_15/TLLogger_1/_2）、
  XSTile（IntBuffer_1/_2/L2Top/XSCore）、XSTop（多个）、Prefetcher（Arbiter4_PrefetchReq/PBestOffsetPrefetch/Pipeline_1/VBestOffsetPrefetch）。
