# fu-atomics-fpdiv-imsic lane（agent/fu-atomics-fpdiv-imsic）—— 跑前登记

每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `eb0400b5`，worktree `/home/eda/xs-env/wt-fu-atomics-fpdiv-imsic`（集成者预建，含认领 `f1c50ec4`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| UT | 双例化 golden vs `<M>_xs`，seed 1/7/42 × `+vcs+initreg+{0,random,<seed>017}`，各 200k 拍 |

## 1. BranchUnit（条件分支 FU，golden 405 行 / 153 端口，纯组合）

- 核 `rtl/backend/BranchUnit.sv`：xs_BranchUnit_core（§1 方向判定 BranchModule / §2 目标地址 AddrAddModule /
  §3 三种后端取指异常 / §4 redirect.valid）+ golden 同名 wrapper（29 条直通、8 条核输出、79 条常量 0 字段）。
- child：BranchModule（golden 内还有 SubModule）/ AddrAddModule，三者 PROVEN_DIRECT → 两侧白盒，无黑盒。
- UT `verif/ut/BranchUnit`：9 档全部 checks=23200000 errors=0，覆盖 24 格（6 编码 × taken × mispred）+ 10 格（5 翻译模式 × 有/无异常）
  全部 ≥ 200，恒 0 输出恰 79 个（数自 golden）。第一版激励 sv48x4 "有异常"桶为 0，补"pc 贴地址空间两端"后 ≈1800。
- 变异自证（seed 7 × 20k，scratchpad 原地注入后恢复）：M1 sv39x4 IGPF 范围 [63:41]→[63:42] errors=40（余量薄，只有 bit41 单独为 1 时才分辨）；
  M2 sext 漏 sv48 errors=3044；M3 redirect 漏 IAF errors=480；M4 sv48 IPF 比较位 47→46 errors=591。
- **预测**：passing = **1298**（模型 = 顶层 output 位 1298，寄存器 0）；failing / unverified / unread / unmatched 全 0；无黑盒；SUCCEEDED。
  登记 `docs/fm_predictions/BranchUnit.json`。可能出错处：无（纯组合、子模块已签、本节无任何试跑）。

## 2. JumpUnit（jal/jalr/auipc FU，golden 406 行 / 155 端口，纯组合）

- 核 `rtl/backend/JumpUnit.sv`：§1 pc 扩展 / §2 JumpDataModule / §3 isMisPred / §4 取指异常 / §5 redirect（auipc 不重定向）
  + wrapper（29 直通、8 核输出、2 恒 1、78 恒 0）。child JumpDataModule PROVEN_DIRECT → 两侧白盒。
- UT `verif/ut/JumpUnit`：9 档全部 checks=23400000 errors=0；覆盖 op×mispred×redirect 可达 10 格 ≥ 200 且 auipc×redirect 两格恰 0，
  5 翻译模式 × 有/无异常 ≥ 200，恒 0/恒 1 输出 78/2。
- 变异自证（seed 7 × 20k）：M1 auipc 也重定向 errors=4943；M2 isMisPred 漏 !predTaken errors=3309；M3 pc 不符号扩展 errors=6217。
- **预测**：passing = **1299**（output 位 1299，寄存器 0）；其余全 0；无黑盒；SUCCEEDED。登记 `docs/fm_predictions/JumpUnit.json`。

## 3. Mgu（向量 mask/tail 合并单元，golden 651 行 / 13 端口，纯组合）

- 核 `rtl/backend/Mgu.sv`：§1 vdIdx 与本组掩码切分（group_bits 纯函数）/ §2 通路 A 按字节合并（ByteMaskTailGen）/
  §3 通路 B 掩码结果嵌进 oldVd 段 / §4 dstMask 二选一。child ByteMaskTailGen（含 UIntToContLow1s/0s、MaskExtractor）全 PROVEN_DIRECT → 两侧白盒。
- 变异自证（seed 7 × 20k）：M1 掩码结果漏 ma errors=1668；M2 narrow 不右移 vdIdx errors=2828；M3 agnostic 写 0 errors=3140；
  M4 eew=32 的掩码切 8 位 errors=1602；M5 eew=16 段取错半 errors=1098。
- **预测**：passing = **144**（output 位 128+16，寄存器 0）；其余全 0；无黑盒；SUCCEEDED。登记 `docs/fm_predictions/Mgu.json`。
  UT 9 档读数在对账节追加。
