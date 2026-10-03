# fu-atomics-fpdiv-imsic lane / sub=hperf —— 跑前登记（HPerfCounter_21 → HPerfMonitor_3）

★FM 起跑之前提交本文件；跑完只在文末「对账」追加，不改已提交数字★

## 0. 输入
| 项 | 值 |
|---|---|
| worktree | `/home/eda/xs-env/wt-fu-atomics-fpdiv-imsic`（agent/fu-atomics-fpdiv-imsic） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| UT | `verif/ut/HPerfMonitor_3`（两目标同 tb），seed 1/7/42 × initreg {0, random, <seed>017} × 200k 拍 |

## 1. HPerfCounter_21（golden 575 行 / 146 端口 / 12 reg；impl `rtl/common/HPerfCounter_21.sv` 380 行，`_GEN_`/`_T_` 0）
- 参数化核 `xs_HPerfCounter_core #(NUM_SETS=144, W=6)`：S1 事件选择（8 位下标查表，0 与 ≥144 读 0；第 0 号事件
  golden 无端口，wrapper 钉 0）+ 算子打拍 / S2 两两组合 / S3 最终组合 / S4 输出再打一拍；12 个寄存器全无复位（照抄 golden）。
- 变异自证（seed 7 × 20k，原地注入后恢复）：M1 查表上界 144→143 errors=1014；M2c 算子优先级 and/xor 对调 errors=102542；
  M3 下标段取 [17:9] errors=57589；M5 add 改 sub errors=27980。（M2b "op[1]&&!op[0]" 是语义等价改写、errors=0，不算逃逸。）
- **预测**：passing = **74**（寄存器位 68 = 4×6+3×5+5+2×6+6+6，+ 输出 6）；failing/unverified/unread/unmatched 全 0；SUCCEEDED。
  可能出错处：核内寄存器是数组 `events_incr_value[4]` / `event_op[3]` / `event_step_reg[2]` 对 golden 平铺名，靠签名匹配（12 个寄存器，规模小）。

## 2. HPerfMonitor_3（golden 1520 行 / 160 端口 / 16 reg；impl `rtl/common/HPerfMonitor_3.sv` 516 行，`_GEN_`/`_T_` 0）
- 核 `xs_HPerfMonitor_core #(NUM_CNT=8)`：genvar 例化 8 个 HPerfCounter_21（实例名 perfEvents_hpc，路径 `g_cnt[c].perfEvents_hpc`）
  + 每路两拍无复位打拍。child HPerfCounter_21 本 UT 自签，两侧白盒。
- 变异自证：M4 少打一拍 errors=116035。
- **预测**：passing = **688**（8×68 + 16×6 = 640 寄存器位 + 48 输出位）；其余全 0；SUCCEEDED。
  可能出错处：golden 实例名 `perfEvents_hpc_1..7` vs impl `g_cnt[1..7].perfEvents_hpc`，靠签名匹配；若 unmatched 先查配对。

UT 读数与变异/FM 对账见文末追加。

## 对账 1：首跑（evidence/d09e1997840f，impl d09e1997，vmucp=false）

| 目标 | 预测 passing | 实测 passing | 差 | unread | failing / unmatched / 黑盒 / dont_verify | 判定 |
|---|---|---|---|---|---|---|
| HPerfCounter_21 | 74 | 66 | 8 | 6↔6 未配 + matched_nc 2 | 0 / 0 / 0 / 否 | PARTIAL（native SUCCEEDED） |
| HPerfMonitor_3  | 688 | 624 | 64 | 64↔64 未配 | 0 / 0 / 0 / 否 | PARTIAL（native SUCCEEDED） |

差额逐项指认：两目标差额恰等于 unread 点数，且全部是同一族——每个计数器里
event_op_0/1/2 与 event_op_2_reg 的 [4:3]（combine 只看 op[2:0]，两侧同为 cone-dead，golden 也是 5 位）。
计数器 4 寄存器 × 2 位 = 8；监视器 8 × 8 = 64。模型把这些死位算进寄存器位，登记值本就是"开 vmucp 后"的口径。
跑前登记文本漏写了这一族（"可能出错处"只写了命名配对），如实记为预登记的遗漏，不改上面数字。

修法（按 vmucp standing rule 六条）：
1. 可读核三个算子寄存器从数组 event_op[3] 改成 golden 同名 event_op_0/1/2（计数器单跑时 FM 按名全配）。
2. verif/ut/HPerfMonitor_3/fm_pins.tcl：监视器实例路径 perfEvents_hpc[_N] ↔ g_cnt[N].perfEvents_hpc/u_core
   逐点 set_user_match，期望数 0 / 64 机械推导，缺伴 / 数目不符 / 剩余未配 全部 error。
3. verif/fm_target_config/<T>.tcl 写依据 + fm_target_vmucp_allow；Makefile 开 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS。
复跑判据：passing = 74 / 688，unread 0，failing / unmatched 0。

UT 插曲：首个 9 档矩阵 seed1×ir0 报 errors=1023757，原因是变异脚本用 mv 恢复原文件、保留旧 mtime，
make 认为 simv 比源新，跑的仍是最后一个变异体（M2c，20k 拍 102542 错 × 10 ≈ 1.02M，量级吻合）。
已删 simv/csrc 全量重编后重跑；矩阵读数见对账 2。

## 对账 2：vmucp 复跑（evidence/5a3282d30ab1，impl 5a3282d3，lane 主线续跑）

| 目标 | 预测 | 实测 | 判定 |
|---|---|---|---|
| HPerfCounter_21 | 74 | **74**（failing / unread / unmatched 0） | SUCCEEDED（receipt 见 evidence/5a3282d30ab1/HPerfCounter_21） |
| HPerfMonitor_3  | 688 | 656 + **failing 16** + unread 16↔16 未配 | **FAILED** |

HPerfMonitor_3 失配根因（不是 RTL 差异）：golden 有一个 reg 名字就叫 `event_op_2_reg`（第二级算子），
它的 DFF 单元名是 `event_op_2_reg_reg`；第一级 reg `event_op_2` 的 DFF 单元名恰好也是 `event_op_2_reg`。
于是 `perfEvents_hpc/event_op_2_reg[3]` 既是第一级的**单元**名、又是第二级 Q 端的**线**名，
不带类型的 `set_user_match` 绑到了线上 —— FM 报 "matched by user" 只有 120/160（本地诊断跑，钉点改成匹配前后），
差的 40 正是 8 × event_op_2 的 5 位；第一级死位 [4:3] 仍是未配 unread（自由割点），下游第二级 [4:3] 因此失配 16 点。
修法：钉点改成匹配前 `fm_pins_pre.tcl` + `set_user_match -type cell`（8 × 4 × 5 = 160 全钉，fail-closed），删除旧 fm_pins.tcl。
本地诊断跑（不出 receipt）：matched by user 160/160，passing **688**，SUCCEEDED。正式复跑见对账 3。

## 对账 3：正式复跑（evidence/f27d65aafd36，impl f27d65aa，钉点 fm_pins_pre.tcl -type cell）

| 目标 | 预测 | 实测 passing | failing / unread / unmatched / 黑盒 / dont_verify | 判定 | receipt sha256 |
|---|---|---|---|---|---|
| HPerfCounter_21 | 74 | **74** | 0 / 0 / 0 / 0 / 否 | SUCCEEDED | `8b025481faaa7d7fd9ac5e7a8fffc8170b9a070867ed7217c816dfc51132b870` |
| HPerfMonitor_3  | 688 | **688** | 0 / 0 / 0 / 0 / 否 | SUCCEEDED | `2b0124e7f6592cc948f9399f66be76fca9c27bead2628290013a3be516feeba7` |

`fm_predict check HPerfCounter_21 HPerfMonitor_3` 逐位相等 rc=0。钉点日志 `HPERF_PIN_PRE_END ok=160 bad=0`，FM "matched by user 160"。
UT（clean rebuild，f27d65aa 字节）：9 档全部 checks=1799928 errors=0 bad_cov=0。
已知闸状态：`scripts/pin_call_equiv.py --check` 全仓本就红（大量目标"基线表里没有"），本 lane 的两份新钉点文件也落在
"基线表里没有这一条"；其中 AtomicsUnit 的那份还报"桩环境下就抛了"——桩 `set_user_match {a b}` 不接受 `-type` 选项
（真 fm_shell `help -verbose set_user_match` 列有 `[-type port|net|cell|pin]`）。桩与基线表是共享件，本 lane 没动，留给 gatefix。
