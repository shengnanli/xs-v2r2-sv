# CtrlBlock 流水连接族 lane（agent/cb-connect）—— 跑前登记

本文件在 **FM 起跑之前**提交。跑完在文件末尾追加「对账」一节，★不修改本节任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `main` @ `6d46cb6c`（Merge branch 'agent/icpipes'） |
| 工作树 | `/home/eda/xs-env/wt-cb-connect`，分支 `agent/cb-connect` |
| 实现 commit | `3e1fdb41993e4136844234ec6555c79f1c6f42c9`（生成器 + RTL + UT） |
| 目标 1 | `PipelineConnectPipe`（golden 848 行 / 235 端口；CtrlBlock 例化 6 次，同一模块） |
| 目标 2 | `PipeGroupConnect`（golden 5039 行 / 1626 端口；CtrlBlock 例化 1 次） |
| 实现 | `rtl/backend/PipelineConnectPipe.sv`、`rtl/backend/PipeGroupConnect.sv`（`scripts/gen_cb_connect.py` 生成） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 证明模式 | signoff-strict，默认 appvar（merge_dup=true、vmucp=false），无 allow / dead_ref / pin 文件 |

## 1. 结构（决定预测的事实，全部由生成器机械核对过）

**PipelineConnectPipe**：golden 121 个寄存器 = valid(1) + 120 个 `data_<f>`（617 位）。
其中 107 个从 `io_in_bits_<f>` 装载，13 个只有出口没有入口（`data_x <= 0` / `~leftFire & data_x`），
impl 把这 13 个字段放进 payload、入口恒接 `'0`，寄存器一一对应。输出端口 122 个 / 619 位。

**PipeGroupConnect**：golden 805 个寄存器 = validVec(6) + 799 个 `dataVec_<i>_<f>`（4405 位），
lane 0 134 字段 / 735 位（含 snapshot），lane 1~5 各 133 字段 / 734 位。impl 6 个 slot 各一个
`data` 寄存器，宽度按 lane 取。输出端口 811 个 / 4417 位（6 个 in_ready 是同一根 canAcc，FM 仍按 6 个端口点计）。

## 2. 预测（★跑完不许改本节★）

`python3 scripts/fm_predict.py model <target>`（merge_dup=true 时工具自标 MODEL_NA，但这两个件
**没有任何两个寄存器的输入锥相同**——每个 data 位的 D 端都是各自独立的输入端口位或各自的 Q，
合并无从发生；同族先例 NewPipelineConnectPipe_29 在 merge_dup=true 下实测 2049 = 模型 1024+1025 分毫不差）：

| 目标 | 寄存器位 | 输出端口位 | **预测 passing** | failing | unmatched | unread |
|---|---|---|---|---|---|---|
| PipelineConnectPipe | 618 | 619 | **1237** | 0 | 0 | 0 |
| PipeGroupConnect | 4411 | 4417 | **8828** | 0 | 0 | 0 |

可接受偏差：**0**。唯一允许的指认项是 receipt 里的 `constant_reg`——若 FM 把 PipelineConnectPipe
那 13 个"只装 0"的寄存器（166 位）判成常量而不产生比较点，passing 会恰好少 166（两侧同判，
仍 SUCCEEDED），差额必须**逐位等于** `constant_reg`；除此之外任何差额都算失配，不找第二个解释去圆。

### ★反向出口★

- impl 侧出现 unmatched / unread 点，且落在 `u_core/data_reg[…]` 的那 166 个恒 0 位上 ⇒
  我对"golden 保留了这批寄存器"的判断错了（它们应当是 impl-only 的死寄存器），**照实报，不走 vmucp 加强**。
- PipeGroupConnect 若 lane 1~5 出现 impl-only 的 `snapshot` 位 ⇒ 两种 struct 的处理错了，照实报。
- failing > 0 ⇒ 不是"打拍连接件"这个前提有问题就是 X 语义差（`if (fire)` vs golden 三目），逐点诊断，不放宽。

## 3. UT 证据（跑前已达标）

PipelineConnectPipe：seed 1/7/42 × `+vcs+initreg+0` / `+1`，各 200k 拍，6 轮全部 `errors=0`
（checks 24,400,000/轮；覆盖 fire 82561 / backpr 67480 / hold 58378 / deq 58144 / owrite 48156 /
flush 290 / flush&fire 200 / payload 逐位 0-1 全覆盖，seed 1 initreg+0）；negtest 两例 elaborate 期 FEST 拦下。
复跑：`cd verif/ut/PipelineConnectPipe && make compile && make run SEED=<s> INITREG=+vcs+initreg+<0|1> && make negtest`。

PipeGroupConnect：同一套命令，结果在对账节补记（登记时 seed 1/7 initreg+0 已 `errors=0`，其余轮在跑）。

## 4. 对账 —— PipelineConnectPipe 第 1 轮（impl commit `f615eb8a5e0d332794a342acab7d391f3ad2dee2`）

证据 `evidence/f615eb8a5e0d/PipelineConnectPipe/`（receipt sha256
`64db08911d1902fe073800e3cdd733e8cfd1097cb7cc534cf0c66850a64e16cf`，
impl_closure[0] = rtl/backend/PipelineConnectPipe.sv `736b4e3bb617820bb9b54047ef2992a1069b56c37135bdc1875376a7626e3445`）：

| 项 | 预测 | 实测 | 判 |
|---|---|---|---|
| native | SUCCEEDED | SUCCEEDED | ok |
| passing | 1237 | **1071**（Port 619 + DFF 452） | 差 166 |
| failing | 0 | 0 | ok |
| unmatched | 0 | **ref 6 / impl 0** | ★失配 |
| constant_reg | 0（允许指认项） | 1 | — |
| verdict | SIGNOFF | **PARTIAL**（strict_unmatched!=0） | ★ |

差额 166 = 恰好那 13 个"只装 0"字段的位数（160 位 mux 形态 + 6 位 `~leftFire & data_x` 形态）：
FM 把它们判成 constrained-0X 常量寄存器（DFF0X），不产生比较点——这条在 §2 的"允许指认项"里，
但 `constant_reg` 只记了 1 而不是 166，原因是 merge_dup=true 把同形态常量寄存器合并成一个代表：
golden 侧 160 个 mux 形态 → 1 个代表，5 个 and 形态各自独立（次态依赖各自的 Q，输入锥不同）；
impl 侧 166 位同一形态 → 1 个代表。两侧代表数 1 vs 6，于是 6 个 ref 代表成孤儿
（unmatched.rpt：data_lsrc_3_reg[0] + isFP64Instr/isFpToVecInst/isReduction/isMove/lastUop 五个 1 位寄存器）。
§2 反向出口第一条（"impl 侧出现 unmatched/unread 落在恒 0 位"）**没有触发**——孤儿全在 ref 侧、impl 侧 0，
说明 golden 确实保留了这批寄存器、impl 也有对应物，只是工具合并口径两侧不一致。

**不是 RTL 差异**：两种写法的次态函数都是 `~fire & Q`。处置为加强（不黑盒、不跳点、不放宽 appvar）：
1. 目标域 `FM_MERGE_DUP = false`（verif/ut/PipelineConnectPipe/Makefile）——逐个比而不是合并后比；
2. `fm_map/PipelineConnectPipe.txt`（生成器产出）把 golden 617 个 data 位与 `u_core/data_reg[bit]` 的双射
   `set_user_match` 钉死，常量寄存器不再靠签名猜配。

## 5. 第 2 轮跑前登记（★跑完不许改本节★）

| 目标 | 预测 passing | failing | unmatched | unread | constant_reg |
|---|---|---|---|---|---|
| PipelineConnectPipe（merge_dup=false + 钉点） | **1071**（不变） | 0 | 0/0 | 0 | **166** |
| PipeGroupConnect（默认配置，无钉点；无常量寄存器） | **8828** | 0 | 0/0 | 0 | 0 |

反向出口：PipelineConnectPipe 若 passing 变成 1237（常量寄存器被逐个比了）也算过——但要写明；
若 unmatched 仍非 0，说明钉点没生效（fm.log 里必须出现 `PACKED_MATCH: 617 points pinned`），停下诊断。
PipeGroupConnect 若 lane 1~5 出现 impl-only 位或 unmatched 非 0，照实报（见 §2 反向出口）。

## 6. 对账 —— PipelineConnectPipe 第 2 轮（impl commit `e47e713399e05b918c80dc5a4dc8674964d007e2`）

证据 `evidence/e47e713399e0/PipelineConnectPipe/`（receipt sha256
`d673c343365032858023cb775018a3191f3cbc3eaa0a4dc2f23760eb56b08510`；
impl_closure[0] = rtl/backend/PipelineConnectPipe.sv `736b4e3bb617820bb9b54047ef2992a1069b56c37135bdc1875376a7626e3445`，
与第 1 轮逐字节相同——RTL 一个字节没动，变的只有证明配置；golden
`2d62c0bd805eab55e7140815362fd13f62982d7e48db5b05422c11cb870cf0fe`）：

| 项 | §5 预测 | 实测 | 判 |
|---|---|---|---|
| verdict | SUCCEEDED（signoff-strict） | **SUCCEEDED** | ok |
| passing | 1071 | 1071（Port 619 + DFF 452） | 差 0 |
| failing | 0 | 0 | ok |
| unmatched | 0/0 | 0/0（compare/unread/bbout 六项全零） | ok |
| constant_reg | 166 | 166 | ok |
| 钉点 | `PACKED_MATCH: 617 points pinned` | 617 | ok |
| appvar | merge_dup=false | readback `false` | ok |
| qualifications | 空 | dont_verify/elab147/relaxed 全空，无黑盒 | ok |

复跑：`PROOF_COMMIT=e47e713399e05b918c80dc5a4dc8674964d007e2 bash scripts/run_proof.sh PipelineConnectPipe PipelineConnectPipe`。
第 1 轮（PARTIAL）的证据 `evidence/f615eb8a5e0d/PipelineConnectPipe/` 一并收进库，供审阅对照。
