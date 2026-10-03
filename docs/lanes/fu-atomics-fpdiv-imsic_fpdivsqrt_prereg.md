# fu-atomics-fpdiv-imsic lane · sub=fpdivsqrt（fpdiv_r64_block_vector / fpsqrt_vector_r16）—— 跑前登记

每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。
通用输入（基线、golden、口径、UT 档位）同 `fu-atomics-fpdiv-imsic_prereg.md` §0。

## 1. fpdiv_r64_block_vector（向量浮点除法 3×基 4 迭代块，golden 1312 行 / 34 端口 / 0 reg，纯组合）

- 核 `rtl/backend/fpdiv_r64_block_vector.sv`（641 行）：§0 通道几何表（f64 1×60 位 @12 / f32 2×31 位 @5,41 / f16 4×18 位 @0,18,36,54）
  与纯函数工具（lane_of / pack72 / div_mul / div7 / div8 / win7 / win8 / fmux / dmux）→ §1 除数倍数 72 位打包 → §2 s0 级 200 位 CSA 三格式并排投机
  （字段 = {通道, 1'b0}，按格式抽取再 Mux1H 合并）→ §3 级间打包（×4 重打包；f16 通道 3/2 carry 候选 q∈{+2,+1,0} 最低位强制 0 的怪癖）
  → §4 s1 级 72 位 CSA + 7 个投机 qds（f16×4 / f32×2 / f64×1 按格式选）→ §5 s2 级 + 由 s0 结果投机的 qds → §6 输出。
  golden 的 is_vec 已被 firtool 折成常量 1，端口表无此信号。多热/全 0 的 fp_format 为非法输入，golden 的 Mux1H 按位或，核逐处照抄
  （含"f64 分支用打包后的 divisor_mul、f32/f16 用原始除数片"这类只在多热下可见的不对称）。
- child：CSA3to2_20 ×4 / CSA3to2_24 ×8 / r4_qds_v2 ×4 / r4_qds_v2_spec ×11，全部 PROVEN_DIRECT → 两侧白盒，无黑盒；实例名与 golden 一致。
- UT `verif/ut/fpdiv_r64_block_vector`：fp_format 八成 one-hot、一成全 0、一成任意 3 位；余数/除数四种形状 + 1/8 规格化尾数；
  覆盖 = 3 格式 × 3 级 × 5 商位 45 格 ≥ 200 + 全 0/多热格式各 ≥ 200 + 全部 256 个输出位 0/1 都见过。seed 7 × 20k 先行 errors=0；9 档读数在对账节追加。
- 变异自证（seed 7 × 20k，scratchpad 原地注入后恢复）：M1 f64 补码 +1 掩码去掉 errors=8159；M2 f16 通道 3/2 的 LSB 强制 0 怪癖去掉 errors=17
  （只在多热格式下可见，余量薄，FM 全取值域兜底）；M3 通道 1 的 s1 商位不按 f32 选 errors=16871；M4 8 位窗错位 1 位 errors=66462；
  M5 s2 商位 q=0 候选改用原始字段（而非 Mux1H 后向量）errors=1435（同样只在多热下可见）。
- **预测**：passing = **256**（模型 = 顶层 output 位 256，寄存器 0，`FM_MERGE_DUP=false`）；failing / unverified / unread / unmatched 全 0；
  无黑盒；无 dont_verify；SUCCEEDED。登记 `docs/fm_predictions/fpdiv_r64_block_vector.json`。
  可能出错处：(a) FM 对 (s+c)+d 与 s+(c+d) 的 7/8 位模加——核已照 golden 的结合顺序逐通道写，预期无差；(b) 本节无任何 FM 试跑。

## 2. fpsqrt_vector_r16（向量浮点开方器顶层，golden 1014 行 / 12 端口 / 57 个 reg 共 441 位，时序件）

- 核 `rtl/backend/fpsqrt_vector_r16.sv`（474 行）：§0 寄存器集合逐字对齐 golden（57 个，只有 fsm_q 异步复位）→ §1 操作数预解码
  （四通道分类 / 指数 / 前导零 / 结果指数预算）→ §2 迭代初始化（第一位根三选一、初始冗余余数、r4_qds_cg 首拍常数；PRE_0 直通
  f64 规格数，其余经 PRE_1 用暂存在 rt_q/rt_m1_q/mask_q 里的左移尾数）→ §3 child fpsqrt_r16_block → §4 状态机 + 寄存器更新
  → §5 后处理（四通道并排加判余数符号、xor/or 判 sticky、按 rm 舍入、根减一的"加一"复用根的加法器、组装结果与 fflags）。
  golden 里 vector_mode_i≡1、fp_aIsFpCanonicalNAN≡0 已被折叠（res_is_sqrt_2 / early_finish / 标量结果通路消失）。
- child：lzc / lzc_3 / lzc_4 ×2 / r4_qds_cg ×4 PROVEN_DIRECT → 两侧白盒；**fpsqrt_r16_block（3575 行）无重写件**（coverage PROVEN_IN_CONE），
  照 `verif/ut/ArithVecLeaves5` 先例走 `RTL_GOLDEN_DEPS` 两侧同读 golden（连同其内部的 r4_qds / r4_qds_spec；其内部的 r4_qds_cg 在 impl 侧
  绑到本仓重写件、ref 侧绑 golden，两者 PROVEN_DIRECT）。无黑盒。★本目标的 proven 口径因此是"顶层 + 已签 child 真逻辑 + 迭代块 golden 复用"，
  迭代块本身不计入本 lane 的重写量。★
- UT `verif/ut/fpsqrt_vector_r16`：sequential 双例化；结果/fflags 只在 finish_valid_o=1 时比（其余寄存器不复位，tb 契约见文件头）；
  覆盖 = 3 格式 × 5 rm ≥ 100 次 finish、通道 0 的 8 类操作数 × 3 格式 ≥ 50、余数为负 ≥ 100、舍入进位 ≥ 30、flush 打断迭代 ≥ 20、
  全部 84 个输出位 0/1 都见过。seed 7 × 20k（initreg 0 与 random）先行 errors=0；9 档读数在对账节追加。
- 变异自证（seed 7 × 20k）：M1 need_2_cycles 漏 f64 非规格数 errors=1061；M2 根减一 RUP 不进位 errors=133；M4 负 qNaN 判 invalid errors=16；
  **UT 看不见的三处**：M3 f64 sticky 范围少 1 位 errors=0（需要余数只在该位非零）、M5 PRE_0 need_2 路径 mask_q[12:4] 不保留而清零 errors=0、
  M6 同路径 iter_num_q[3:2] 清零 errors=0（M5/M6 在 PRE_1 被整体覆盖，仿真按构造不可见）—— 三者都是寄存器 D 端函数或输出锥的差异，归 FM 兜底。
- **预测**：passing = **527**（模型 = golden 闭包寄存器位 441 + 顶层 output 位 86，`FM_MERGE_DUP=false`）；failing / unverified / unread /
  unmatched 全 0；无黑盒；无 dont_verify；SUCCEEDED。登记 `docs/fm_predictions/fpsqrt_vector_r16.json`。
  可能出错处：(a) 核把 golden 的扁平标量寄存器（out_sign_0_q … m_pos_2_for_nxt_cycle_s0_qds_3_q）收成向量/数组（out_sign_q[k]、m_pos_2_q[k]），
  名字不同，靠 FM 签名匹配配对；57 个寄存器规模小，预期能配上，配不上再补 fm_pins_pre.tcl；(b) 若 FM 把某些 D 端恒常量的位判 constant_reg，
  差额应由 receipt 的 constant_reg 指认；(c) 本节无任何 FM 试跑。
