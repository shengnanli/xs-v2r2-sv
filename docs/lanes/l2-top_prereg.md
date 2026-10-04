# l2-top lane（agent/l2-top）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `ce53b9176`（main 0af8e1726 + claim；worktree 由集成者预建） |
| 工作树 | `/home/eda/xs-env/wt-l2-top`，分支 `agent/l2-top` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `Prefetcher`、`TL2CHICoupledL2`、`L2Top`（自底向上） |
| 口径 | `FM_MERGE_DUP=false`（fm_predict 模型严格适用）；无 dont_verify；黑盒只许 verif/allow/<T>.json 逐对象声明 |

### 0.1 child 核实（`python3 scripts/coverage_three_axis.py` 在本 worktree 重算后读第 3 列；派生表本身未提交）

仓里的 `docs/coverage_three_axis.tsv` 是旧的（早于 l2-link / l2-mem-parents / uncore-queues 合并），重算后：
三个目标的 golden 闭包里每个 child 都是 `PROVEN_DIRECT`（含此前表里写 UNPROVEN 的 PBestOffsetPrefetch /
VBestOffsetPrefetch / LinkMonitor / MMIOBridge / Queue78_PCrdGranted / TLBuffer_13 / TLBuffer_15）。
child 一律两侧白盒：ref 读 golden，impl 读本仓重写件（不走 green_child 证书路线）。

## 1. Prefetcher（golden 521 行 / 69 端口；TL2CHICoupledL2.prefetcher）

### 1.1 结构

- `rtl/l2/Prefetcher.sv`（536 行）：手写胶合核 `xs_Prefetcher_core`（§1 使能、§2 训练过滤、§3 回填分发、§4 出口让路、
  §5 recv_addr 两拍延迟）+ golden 同名顶层（7 个 child，实例名同 golden）。`_GEN_` / `_T_` = 0。
- child（全部 PROVEN_DIRECT，两侧白盒）：PBestOffsetPrefetch、VBestOffsetPrefetch、PrefetchReceiver、MbistPipeL2Prefetcher、
  PrefetchQueue、Pipeline_1（含 Queue1_PrefetchReq）、Arbiter4_PrefetchReq。
- 黑盒：只有厂商 SRAM 叶子 `array_13_ext`（pbop / vbop 的 rrTable 各 1，两侧对称，vendor_boundary 已审定）→
  `verif/allow/Prefetcher.json`（由诊断跑 black_boxes.rpt 经 `scripts/declare_allow.py` 生成，4 个对象）。

### 1.2 UT（verif/ut/Prefetcher，gen.py 生成 tb；200k 拍，每拍比全部 17 个输出端口、173 位）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | armed 36089 / checks=2786487 errors=0 | 同左 | 同左 |
| 7  | armed 102086 / checks=1664538 errors=0 | 同左 | 同左 |
| 42 | armed 26096 / checks=2956368 errors=0 | 同左 | 同左 |

全部 cov_fail=0（每个输出位见过 0/1，豁免只有 vbop 的 TLB 请求常量字段；另 13 个覆盖计数各 ≥5）。
arm = pbop / vbop 内部不复位寄存器各自第一次被写（沿用两个 child UT 的 arm 条件）+ pipe 第一次出数；
arm 前不比。arm 点三档 initreg 相同（arm 条件只看 golden，与初值无关）。
变异（scratchpad 脚本，seed 42 initreg 0、60k 拍，不进库）7/9 被抓：去训练过滤 errors=154884；vbop ready 恒 1 49988；
pbop 不让 vbop 9156；recv_addr 只延 1 拍 123198；第 2 级数据锁存使能错接 36330；vbop 使能不看 master 3573；
pfRcv 使能只延 1 拍 71185。未抓 2 个：回填分发 PBOP/BOP 互换（resp 只影响 BOP 打分的时机，60k 拍内输出不可分）、
pfRcv_en 复位值 1→0（只影响复位后 2 拍内恰好有 recv_addr 的情形）——两者都改变寄存器次态 / child 输入函数，
由 FM（merge_dup=false 逐寄存器比较）覆盖。
复跑：`cd verif/ut/Prefetcher && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`
（UT 跑完后 rtl/l2/Prefetcher.sv 只改过一行注释：「文件导航」→「本文件导航」，可读性闸 E 类要求的字样。）

### 1.3 跑前预测（★跑完不许改本节★，docs/fm_predictions/Prefetcher.json）

模型 expected = **9301**（`python3 scripts/fm_predict.py model Prefetcher`）。

诊断跑（`make fm-Prefetcher FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，关 vmucp、带 884 位 child 钉点，未出证）：
native SUCCEEDED，passing **8325** / failing 0 / unmatched compare 0；unread = matched-unread **900**（pbop/vbop 内 884 +
vbop s1_newFullAddr 6 + mbistPl addrReg 9 / addrRdReg 1）+ 两侧各 **76** 位 unmatched-unread（recv_addr 延迟 44、
pftQueue valids_0..30 31、mbistPl beReg 1）。8325 + 900 + 76 = 9301 = 模型。

正式跑配置：钉点 960 位（`scripts/gen_prefetcher_pins.py`，884 + 76）+ vmucp 开（`verif/fm_target_config/Prefetcher.tcl` 六条证据）。

| 目标 | passing 预测 | 其余 |
|---|---|---|
| Prefetcher | **9301** | failing 0 / unverified 0 / aborted 0 / unmatched 全 0 / unread 0 / 黑盒 = allow 声明的 4 个 array_13_ext / 无 dont_verify / SUCCEEDED |
