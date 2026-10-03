# misc-core lane（agent/misc-core）—— 跑前登记

本文件在 FM 正式证明（`scripts/run_proof.sh`，signoff-strict / 父级沿用各自口径）**之前**提交；
跑完在文末「对账」追加，★不修改已提交分节的任何数字★。数字登记同时写在 `docs/fm_predictions/<T>.json`。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3cd470621`（认领 commit `11acdfa8e`） |
| 工作树 | `/home/eda/xs-env/wt-misc-core`，分支 `agent/misc-core` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 重写 commit | `6a0853dea`（FMA 子树）/ `28914da15`（BlockCipherModule）/ `75d834e10`（ExceptionGen） |
| 认领目标 | ExceptionGen、BoothEncoderF64F32F16、CSA_Nto2With3to2MainPipeline、FloatFMA、BlockCipherModule |
| 重证父级 | FMA、VectorFloatFMA、BoothEncoderF64F32F16_3（核搬家）、Bku、CtrlBlock |

冲突检查（规范 §0）：codex outbox 最近 3 条与 26 个 codex 分支的 rtl 改动均不含本 lane 目标；
各 worktree 的 `*_claim.md` 无同名认领（`*_prereg.md` 里的命中都是已合入 main 的旧 lane 把它们当 child 提及）。
认领清单外**未新增**目标：孙辈 `CSA4to2`（coverage 第 3 列 PROVEN_IN_CONE / GOLDEN_REUSE，无重写件）两侧同源 golden，不重写。

## 1. 目标与子模块处置

| 目标 | golden 行 | 重写文件（行） | child 处置 |
|---|---|---|---|
| BoothEncoderF64F32F16 | 816 | `rtl/backend/BoothEncoderF64F32F16.sv`（266，家族核 + 标量 wrapper） | 叶子 |
| BoothEncoderF64F32F16_3 | 1076 | `rtl/backend/BoothEncoderF64F32F16_3.sv`（79，薄 wrapper，PACKED=1） | 叶子 |
| CSA_Nto2With3to2MainPipeline | 364 | `rtl/backend/CSA_Nto2With3to2MainPipeline.sv`（151） | CSA3to2×19 两侧白盒（ref golden / impl 重写件，PROVEN_DIRECT）；CSA4to2×3 两侧同源 golden |
| FloatFMA | 3027 | `rtl/backend/FloatFMA.sv`（986） | Booth / CSA_Nto2 / CSA3to2 全部两侧白盒（ref golden / impl 重写件） |
| BlockCipherModule | 3995 | `rtl/backend/BlockCipherModule.sv`（556） | 叶子 |
| ExceptionGen | 2636 | `rtl/backend/ExceptionGen.sv`（1520，wrapper 由 `scripts/gen_exceptiongen.py` 生成） | 叶子 |

无黑盒（父级 CtrlBlock 沿用它既有的 8 个存储叶子接口黑盒），无 dont_verify，allowlist 空。
`_GEN_` / `_T_` 代码区命中：六个文件全部 0。

### 关于父级"两侧是否同读 golden 件"（任务要求先查）

- **Rob**：`verif/ut/Rob/Makefile` 的 FM 把 8 个 child（含 ExceptionGen）全部做**对称黑盒**，两侧都不读 golden ExceptionGen 的体 ⇒ Rob 的证明与本 lane 无关，**不重证**。
- **CtrlBlock**：`verif/ut/CtrlBlock/closure.mk` 把 ExceptionGen 列在 GOLDEN_CLOSURE_SHARED（两侧同源 golden）⇒ 这是真正"两侧同读 golden ExceptionGen"的证明，改为 ref golden / impl 重写件后重证。
- **FMA**：FloatFMA 闭包 5 个文件两侧同源 ⇒ 改两侧白盒重证。**VectorFloatFMA**：CSA_Nto2With3to2MainPipeline 两侧同源 ⇒ 改两侧白盒重证。
- **Bku**：CryptoModule（无重写件）下的 BlockCipherModule 两侧同源 ⇒ 改两侧白盒重证（CryptoModule / HashModule 等仍同源）。
- `scripts/check_shared_impl_impact.py`：本 lane 新增的 rtl 文件不在任何已跟踪 receipt 的 impl_closure 里（0 个受影响）；
  被改的已有文件只有 `rtl/backend/BoothEncoderF64F32F16_3.sv`（受影响 = BoothEncoderF64F32F16_3 与 VectorFloatFMA，都在本 lane 重证清单里）。

### FM 钉点

- `verif/ut/{CSA_Nto2With3to2MainPipeline,FloatFMA,FMA}/fm_pins_pre.tcl`：`scripts/gen_fma_pins.py` 生成（带 `--check`），
  golden 每个寄存器恰好命中一条规则、单射、运行时逐条数 set_user_match 返回值（error 不用 exit）。
  依据（实测，lane 内非正式 diagnostic-full 试跑，不出 receipt）：不钉时 CSA 4(4) unmatched（树最低位的常 0 位签名分析配不上）、
  FloatFMA 123(123) unmatched，且由此连带 713 个 failing。
- `verif/ut/VectorFloatFMA/fm_pins_pre.tcl`：`scripts/gen_vfma.py` 末尾追加 U_CSAnto2 的 4 条（428 位）。
- BlockCipherModule / ExceptionGen：不钉（非正式试跑签名分析全配上，0 unmatched）。

### FM 试跑抓到的两处 RTL 偏差（已改，UT 看不见）

FloatFMA 第一版按"只影响用不到的高位"简化了两处共享电路，非正式 FM 判 failing（各格式的 `adder_*_reg1` 在非当拍格式时存的值不同）：
1. S1 的 3:2 进位输入要按向量通道边界清 58（f32）/ 26、58、84（f16）位（文件头怪癖 6）；
2. c 高段的"加 1"是一个按当拍格式三选一的共用 59 位加法器，三条通路取它的低段（怪癖 7）。
两处都只改变**不可观测**的每格式寄存器内容，所以 UT（逐拍比输出 + oracle）结构上看不见；变异自证见 §2 的 fma_m2。

## 2. UT（在重写 commit 的字节上跑；各档读数跑完写进「对账」，本节不写数字）

| UT | 比对 | 档位 |
|---|---|---|
| BoothEncoderF64F32F16 / _3 | 27 个 107 位加数逐位；覆盖：27 数字 × {+1,+2,-1,-2}、每输出位见 0/1（结构常量位按格式算出后豁免） | 3 seed × {+0, random, <seed>017} |
| CSA_Nto2With3to2MainPipeline | out_sum / out_car；首次 fire 后 arm | 同上 |
| FloatFMA | 双例化逐拍 + **独立 IEEE 754 oracle**（整数有效数精确乘加 + 一次舍入，tininess after rounding，RISC-V NaN 规则；f16/f32/f64；fmul 为纯乘法） | 同上 |
| BlockCipherModule | 双例化逐拍 + 查表参考模型（AES S 盒 tb 内按 FIPS-197 现算，SM4 用 GB/T 32907 表 1）逐条判 golden + **标准向量**：FIPS-197 C.1 AES-128 加 / 解密、GB/T 32907 附录 A 例 1 SM4（经 aes64*/sm4* 指令序列算出，比对标准密文） | 同上 |
| ExceptionGen | 双例化逐拍全部 io_state_*；覆盖 s1 替换 / 同指令合并 / 收 enq / 冲刷 | 同上 |
| 父级 FMA、Bku | 各自既有 tb；Makefile 没接 initreg 机制，按既有口径 3 seed | seed 1/7/42 |
| 父级 VectorFloatFMA | 既有 tb | 3 seed × 3 档 |
| 父级 CtrlBlock | 既有 tb（INITREG 变量是完整 plusarg） | 3 seed × {+vcs+initreg+0, +vcs+initreg+1} |

Bku 的 UT 测不到重写件（CryptoModule 是两侧共用的 golden 定义，例化的 BlockCipherModule 两侧都解析到 golden），
本层替换由 FM 兜底；重写件本身的 UT 在 `verif/ut/BlockCipherModule`。

变异自证（scratchpad 独立树，20k 拍，seed 1，initreg 0）：

| 变异 | UT errors |
|---|---|
| fma_m1：RNE 去掉"尾数最低位"项（就近舍入偶数规则坏） | 6 |
| fma_m2：去掉 S1 进位输入的通道边界清位（怪癖 6） | **0**（UT 结构上看不见，见 §1；非正式 FM 判 failing） |
| bcm_m1：aes64ks1i 第 8 项轮常数 0x1B→0x1C | 51 |
| bcm_m2：SM4 结果循环移位只看 func[0] | 4950 |
| eg_m1：同 robIdx 时 vuopIdx 比较反向 | 2889 |
| eg_m2：同指令合并时 flushPipe 不再被异常向量压住 | 836 |
| csa_m1：第 4 层 4:2 的 c / d 输入接反 | 39984 |
| booth_m1：第 5 个 Booth 数字的 -2 译码删掉 | 3812 |

## 3. 跑前预测（★跑完不许改本节★）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model <T>`；FMA / Bku 本次把 `FM_MERGE_DUP` 改成 false——加强，比较点只增不减——模型才适用）。

| 目标 | 模型 | 预测 passing | constant_reg | unread / 其它 | 判决 | 依据 |
|---|---|---|---|---|---|---|
| BoothEncoderF64F32F16 | 2889 | **2889** | 0 | 0 | SUCCEEDED | 非正式试跑 2889 |
| BoothEncoderF64F32F16_3 | 2889 | **2889** | 0 | 0 | SUCCEEDED | 上一轮 receipt 2889 |
| CSA_Nto2With3to2MainPipeline | 642 | **638** | 4 | 0 | SUCCEEDED | 非正式试跑 638+4 |
| FloatFMA | 1705 | **1600** | 105 | 0 | SUCCEEDED | 非正式试跑 1600+105 |
| FMA | 4293 | **4188** | 105 | 0 | SUCCEEDED | 非正式试跑 4188+105 |
| VectorFloatFMA | 1838 | **1735** | 103 | 0 | SUCCEEDED | 上一轮 receipt 1735+103（本轮未试跑） |
| BlockCipherModule | 630 | **630** | 0 | 0 | SUCCEEDED | 非正式试跑 630 |
| Bku | 3879 | **3423** | 456 | vmucp 白名单 20 个 funcReg 死位（既有 fm_target_config/Bku.tcl）计入 passing，unread_notcompared 0 | SUCCEEDED | 非正式 diagnostic 试跑 3403 + unread 20 + 456 |
| ExceptionGen | 718 | **718** | 0 | 0 | SUCCEEDED | 非正式试跑 718 |
| CtrlBlock | 327974 | **324714** | 3244 | ref 侧 unread 16（dead_ref 声明不变） | PASS_DEAD_REF | 与上一轮 receipt 27fd6722e959 相同；**预期耗时约 11.5 小时**（上一轮 41021 s） |

所有目标：failing / unverified / aborted / unmatched 全 0，dont_verify / elab147 / relaxed appvar 皆空，无新增黑盒。

## 4. 明写可能出错的地方

1. VectorFloatFMA 没做非正式试跑：U_CSAnto2 换成重写件后，若向量版里压缩树的常量位集合与标量版不同，constant_reg 会偏离 103（passing 等额反向偏离），这种偏差可由 receipt 的 constant_reg 指认。
2. CtrlBlock 里 ExceptionGen 不钉点：独立证明时签名分析全配上，但在 30 万比较点的上下文里未必；若出现 unmatched，先查 rob/exceptionGen 的配对。
3. CtrlBlock 证明 11 小时级；若 3 小时无进展迹象按规范采样诊断，必要时停下报告。

## 对账（跑完追加，不改上文任何数字）
