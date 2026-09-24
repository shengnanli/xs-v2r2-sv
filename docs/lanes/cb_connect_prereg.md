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
