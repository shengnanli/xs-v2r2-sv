# pmpchk-vimac-agt-fma lane —— BoothEncoderF64F32F16_3 / VectorFloatFMA 跑前登记

本文件只管本 lane 的第 4 个目标（先 `BoothEncoderF64F32F16_3`，再 `VectorFloatFMA`），由子 agent 维护；
同 lane 另三个目标（PMPChecker 家族 / VIMac64b / ActiveGenerationTable）的登记在 `pmpchk-vimac-agt-fma_prereg.md`。
每个目标 **FM 正式起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 工作树 / 分支 | `/home/eda/xs-env/wt-pmpchk-vimac-agt-fma`，`agent/pmpchk-vimac-agt-fma`（与父 agent 共用，只碰自己的路径） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| Scala | `/home/eda/xs-env/XiangShan/yunsuan/src/main/scala/yunsuan/vector/VectorFloatFMA.scala` |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 正式证明 | `PROOF_COMMIT=<commit> bash scripts/run_proof.sh <ut> <T> < /dev/null`（工作树里有父 agent 的未提交文件，钉 commit 跑） |

## 1. BoothEncoderF64F32F16_3

### 1.1 结构与子模块处置

- golden 1076 行 / 31 端口，纯组合，0 子模块、0 寄存器。Scala 是 `BoothEncoderF64F32F16(width=53, is_addend_expand_1bit=true)`：
  27 个 Booth-4 数字三种格式共用；f64 一条通道、f32 两条、f16 四条，各通道的加数摆在 107 位里互不重叠的一段。
- 可读核 `rtl/backend/BoothEncoderF64F32F16_3.sv`（252 行，`_GEN_`/`_T_<数字>` 0 命中）：
  `xs_BoothAddendLane #(W, N)`（一条通道：W 位被乘数 + N 个已译码数字 -> N 个 2W+1 位加数，奇/偶宽度的末项各一种写法）
  × 7 个实例（53 / 24×2 / 11×4）+ `xs_BoothEncoderF64F32F16_core`（乘数重排、27 个译码器、按格式选出）+ golden 同名 wrapper。
  另一个变体 `BoothEncoderF64F32F16`（标量 FloatFMA 用，不在本 lane 认领清单里）没有做。
- 无黑盒。

### 1.2 UT（verif/ut/BoothEncoderF64F32F16_3；seed 1/7/42 × initreg 0 / random / `<seed>017`，各 200k 拍）

逐拍比 27 个 107 位加数（2889 位里按结构算出 1338 位三种格式下都是同一个常量，豁免"见过 0/1"；其余 1551 位必须见过 0 和 1）。
九档全部 `checks=5399784 errors=0 cov_fail=0 TEST PASSED`（纯组合，三档 initreg 读数相同是预期的）。
这九档在提交 `58594896` 之前的工作树上跑（`git diff 58594896 -- rtl/backend/BoothEncoderF64F32F16_3.sv verif/ut/BoothEncoderF64F32F16_3` 为空，字节相同）。

覆盖（seed 1 × initreg 0）：f64 65599 拍 / f32 65362 / f16 65791 / 两个格式位同时为 1（fp64 优先）3240；
27 个数字 × {+1, +2, -1, -2} 共 105 个计数（第 26 个数字不可能为负、第 0 个不可能为 +2，这 3 项按结构不设），最小 8560、最大 99866。

复跑：`bash <scratchpad>/pmpchk-vimac-agt-fma/ut9.sh BoothEncoderF64F32F16_3`，或单档
`cd verif/ut/BoothEncoderF64F32F16_3 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

变异自证（scratchpad，不进库）：结果见文末「对账」。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/BoothEncoderF64F32F16_3.json）

模型：expected = **2889**（寄存器位 0 + 顶层 output 位 27×107 = 2889），`FM_MERGE_DUP=false` 模型适用。

| 项 | 预测 |
|---|---|
| passing | **2889** |
| failing / unverified / aborted / unread | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 0（没有寄存器） |
| 黑盒 / dont_verify | 无 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

无 vmucp、无 fm_pins、无 allow / dead_ref 声明。

### 1.4 明写可能出错的地方

1. **做过一次 lane 内非正式试跑**（提交前的工作树，与 `58594896` 字节相同；`cd verif/ut/BoothEncoderF64F32F16_3 && make fm-BoothEncoderF64F32F16_3 < /dev/null`，
   因工作树 dirty 不出 receipt）：native SUCCEEDED，passing 2889 / failing 0 / unmatched 0。所以上表不是盲测，是"照试跑结果登记"。
2. 2889 个输出位里有 1338 位是常量（两侧同为常量 0/1）。FM 对"两侧都是常量的输出口"仍计比较点（试跑 passing 就是 2889），
   若正式跑里 passing 少了，先查是不是这批常量口的计数口径变了，而不是 RTL。
3. 可读核用了参数化子模块 + `localparam` 非打包数组做通道表（`F32_SIG_LSB[l]` 之类）下标 generate 变量；试跑已证明 FM 能展开。
