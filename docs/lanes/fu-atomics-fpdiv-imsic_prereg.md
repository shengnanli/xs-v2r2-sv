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

## 4. VFixPoint64b（向量定点第二级，golden 651 行 / 44 端口，纯组合）

- 核 `rtl/backend/VFixPoint64b.sv`（295 行，`_GEN_`/`_T_` 0）：§1 饱和加减 / §2 平均加减右移+舍入 / §3 缩放移位舍入位 /
  §4 Adder_chain_rnd 舍入加 1 链 / §5 窄化裁剪 32/16×2/8×4 / §6 输出。child Adder_chain_rnd PROVEN_DIRECT → 两侧白盒。
- UT `verif/ut/VFixPoint64b`：9 档（seed 1/7/42 × initreg 0/random/<seed>017）全部 checks=600000 errors=0 bad_cov=0；
  覆盖 6 定点编码 × 4 vxrm 每格 ≥500、4 种 sew × isNClip 每格 ≥500、vxsat≠0 ≥1000、全部输出位 0/1 都见过。
- 变异（seed 7 × 20k）：M1 有符号饱和条件取反 errors=3279；M2 rne 平均舍入漏 v[1] 313；M3 16 位裁剪 cout 取错字节 15（余量薄）；
  M4 sew16 最高字节判定反 475；M5 rod 缩放移位漏 ~tail 517。
- **预测**：passing = **104**（output 位，寄存器 0）；其余全 0；无黑盒。

## 5. VIntFixpAlu64b（向量整数/定点 ALU 64 位半片，golden 442 行 / 25 端口 / 47 reg 353 位，两拍流水）

- 核 `rtl/backend/VIntFixpAlu64b.sv`（251 行）：§1 VIntAdder64b + VIntMisc64b / §2 fire 使能流水寄存器（不复位，golden 同份数）/
  §3 VFixPoint64b / §4 输出选择。child 全部两侧白盒（VIntAdder64b、VIntMisc64b+CLZ_6/7/9/11 PROVEN_DIRECT；VFixPoint64b 本 lane §4）。
- UT `verif/ut/VIntFixpAlu64b`：第一次 fire 之后才比（不复位寄存器）；seed 7 × 20k 先行 errors=0；9 档读数在对账节追加。
- 变异（seed 7 × 20k）：M1 isNClip 漏"结果比源窄" errors=171；M2 isSigned 只看 bit2 3364；M3 vd 选择 misc/adder 对调 8816；
  M4 去掉 fire 使能 13269。
- **预测**：passing = **465**（寄存器 353 + output 112，merge_dup=false）；constant_reg 若出现在对账逐位指认；无黑盒。

## 6. FloatAdderF32WidenF16MixedPipeline（f32/f16/加宽 混合浮点加法 lane，golden 408 行 / 17 端口 / 17 reg，两拍流水）

- 核 `rtl/backend/FloatAdderF32WidenF16MixedPipeline.sv`（331 行）：§1 输入整形 / §2 特殊值 / §3 远近路径 /
  §5 min/max/比较/sgnj/fclass/merge/move/归约 / §4 打拍与第 1 拍选择。golden 的两份同源选择位（io_fp_c_r / io_fflags_r）照抄两份。
- ★child 处置★：FarPath/ClosePathF32WidenF16MixedPipeline 在 coverage 表是 MISSING + PROVEN_IN_CONE（本仓无重写件），
  照 `verif/ut/FAlu` 先例两侧**同读 golden**（含 6 个孙子件），不设黑盒。本证明覆盖顶层 glue 与全部控制/比较逻辑；
  far/close 数据路径内部是 golden 对 golden，**不算重写**。
- UT：两次 fire 之后才比；seed 7 × 20k 先行 errors=0；9 档读数在对账节追加。覆盖 22 个 op_code 每个 ≥500 等（tb 文件头）。
- 变异（seed 7 × 20k，clean rebuild 后）：M1 far 路径条件漏"指数差 1 且一零一非零" errors=11；M2 f16 零指数 0x66→0x67 63；
  M3 min 的 ±0 规则 16；M5 sgnjx 异或→或 54；M6 加宽 a 为零直通恒 0 199；
  **M4 fflags 用 fp_c 那份选择位 errors=0** —— 两份寄存器同源、仿真按构造不可分，归 FM（寄存器是自由变量）兜底。
  M1/M3 余量薄（11/16），点名。
- **预测**：passing = **347**（闭包寄存器 310 + output 37）；预期差额由 constant_reg 指认，至少 4 位
  （io_fflags_r_1 的低 4 位恒 0）；failing / unread / unmatched 0；无黑盒。
