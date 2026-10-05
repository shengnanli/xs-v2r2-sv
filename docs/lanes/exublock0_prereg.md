# exublock0 lane（agent/exublock0）—— 跑前登记

本文件在每个目标 **official FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3296853c`（worktree `/home/eda/xs-env/wt-exublock0`，分支 `agent/exublock0`，认领 commit `b47b4178`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `ExeUnit_7`（§1）、`ExuBlock`（§2） |
| 口径 | `FM_MERGE_DUP=false`、无 dont_verify、无放宽 appvar、无黑盒；signoff-strict；vmucp 白名单 + PASS_DEAD_REF 声明 |
| UT | 双例化 golden vs `_xs`，每拍全部输出逐位 `!==`；seed 1/7/42 × `+vcs+initreg+0` / `random` / `<seed>017`，各 200k 拍，串行 |

child 状态（receipt verdict；`docs/coverage_three_axis.tsv` 里 CSR 仍是 UNPROVEN —— 派生表未重生成，以 receipt 为准，本 lane 不改派生表）：
CSR `evidence/86c70db32986` PASS_DEAD_REF；Fence `evidence/466d169f9875` PASS_DEAD_REF；DivUnit `evidence/c2fc93f125d3` SUCCEEDED；
Dispatcher_7 `evidence/92a50405-200c-final` SUCCEEDED；DelayN_214/215 `evidence/eee60602a12f` SUCCEEDED；ClockGate 本地签核件（codex 0208）；
ExeUnit `evidence/bbd73158a339`、ExeUnit_1/_4 `evidence/41366b7e2f9c`、ExeUnit_5 `evidence/f5b39c39e043` SUCCEEDED。

## 1. ExeUnit_7（golden 2400 行）

### 1.1 结构与子模块处置

- wrapper `rtl/backend/ExeUnit_7.sv`（1711 行，`_GEN_`/`_T_` = 0）由 `scripts/gen_exeunit.py` 新增变体生成；外壳控制逻辑
  （busy 一次一条、Div 的不定延迟门控、写回 Mux1H）全部复用**未改**的共享核 `rtl/backend/xs_ExeUnit_core.sv` / `xs_ExeUnit_wbsel`。
  生成器为 ExeUnit_7 加的三样（已签 7 个变体 `--check` 字节不变）：
  (1) 常开门控：csr / Fence 是不定延迟但 ckAlwaysEn，ClockGate.E=1'h1，核里按无门控链给参数、wrapper 直接接 1'b1；
  (2) 辅助实例：Scala `DelayN(exuio.exception, 2)` / `DelayN(exuio.robDeqPtr, 2)` 两个 DelayN_214/215 原样例化；
  (3) 致命错误上报 HasCriticalErrors 的 `RegNext(RegNext(error))`：新共享件 `rtl/common/xs_CriticalErrorDelay_core.sv`（32 行）。
  另：redirect（Scala 过滤后单元素 Mux1H）与 isPerfCnt（全体 FU 相或，只有 csr 有）按 Scala 语义直连。
- child 两侧白盒：csr = CSR 整棵子树（照搬 verif/ut/CSR 的文件表与两侧共读 golden 件）、Fence、Div = DivUnit（孩子读重写件）、
  in1ToN = Dispatcher_7、DelayN_214/215、ClockGate。无黑盒。
- FM 钉点：
  * `verif/ut/ExeUnit_7/fm_pins_pre.tcl`（静态，字面 5873）：外壳寄存器 13 位（busy / robIdx 快照 / Div 门控 / io_error 两拍）+
    外壳附加整族：Div 死位 6、Fence 操作码 9、CSR 进外壳后签名配不上的整族（imsic eies_1..3 / eithreshold / rdata_d、PMP/PMA 地址各
    32×46、isPerfCnt 两拍、mvip.SSIP、sie.SSIE）5838、DelayN_214 第 2 级 gpaddr[63:56] 8。全部按结构整族写定（不是照孤儿名单抄），
    依据见 gen_exeunit.py EXTRA_CHILD_PINS 注释。
  * `verif/ut/ExeUnit_7/fm_pins.tcl`（动态，匹配后）：CSR 的 verif/ut/CSR/fm_pins.tcl 机械改前缀照搬（四族，fail-closed）。
    ★新动态钉点文件：夹具 fm_pins_fixture.tcl 按 official 跑的真实 fm.log 生成并核对后再提交（见对账）★。

### 1.2 UT（verif/ut/ExeUnit_7，tb 由 gen.py 生成；RTL 字节 = commit 28d32f0d1，ExeUnit_7.sv 自 bd3eb55f1 未变）

激励照搬 CSR UT（合法地址表、WARL 偏置、系统指令、trap / 中断 / MSI / NMIE 救援），uop 从 ExeUnit 扁平口进：fuType 82% csr / 6% Fence
（只发合法 op —— 非法 op 会卡死 Fence，而 Dispatcher_7 的 in.ready 是三个 FU ready 的与）/ 9% Div / 3% 随机；暖机 = 写遍 337 个
合法 CSR、进 debug、写触发器、dpc/dscratch、dret、trap、mret；**csr 收下后的下一拍保持同一条 uop 字段**（NewCSR 写使能晚一拍、
取当拍地址/数据，golden 行为）；暖机完成且 Fence 收过一条后 arm。翻转闸：外壳自己产出的口（写回 Mux1H、busy、io_error…）每位
须见 0/1；子 FU 直连口（csrio / redirect / gatewayIn / fenceio）与 VS 态 ecall 位按机理豁免、照比。

- seed=1 initreg=0 checks=57980295 errors=0 cov_fail=0 TEST PASSED
- seed=1 initreg=random checks=57980295 errors=0 cov_fail=0 TEST PASSED
- seed=1 initreg=1017 checks=57980295 errors=0 cov_fail=0 TEST PASSED
- seed=7 initreg=0 checks=57980295 errors=0 cov_fail=0 TEST PASSED
- seed=7 initreg=random checks=57980295 errors=0 cov_fail=0 TEST PASSED
- seed=7 initreg=7017 checks=57980295 errors=0 cov_fail=0 TEST PASSED
- seed=42 initreg=0 checks=57984369 errors=0 cov_fail=0 TEST PASSED
- seed=42 initreg=random checks=57984369 errors=0 cov_fail=0 TEST PASSED
- seed=42 initreg=42017 checks=57984369 errors=0 cov_fail=0 TEST PASSED

覆盖（seed 7 × random，全部 >= 100）：csr_fire 27894 / fence_fire 1842 / div_fire 2975 / busy 143729 / flush 命中在途 4291 / 反压 7703 /
trap 进 M 1 602 / mret 309 / 合法 CSR 写 9184 / EX_II 16932 / 重定向 5884 / MSI 9921。

变异自检（seed 7 × random × 20k 拍，独立 worktree 改完即弃）：E1 错误打拍少一级 errors=178；E2 csr 门控 E 接成 lat0 探针 1212679；
E3 csr exception 绕过 DelayN 267331；E4 isPerfCnt 断开 19245；E5 flushPipe Mux1H 去掉 Fence 成员 99。5/5 抓到。

复跑：`cd verif/ut/ExeUnit_7 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 诊断跑（如实记；diagnostic-full，关 vmucp，@28d32f0d1，未出证）

前三次诊断跑分别撞到：CSR 动态钉点族外孤儿 4921/4915（进外壳后签名配不上的整族 → 补静态钉点）、Fence struct 寄存器名
（FM 名为 uop_reg[fuOpType][b]，fm_shell find_cells 实查）、mvip.SSIP / sie.SSIE 2 个。第四次：
native SUCCEEDED，passing 30245，failing 0，unmatched compare 0，constant_reg 1011，CSR 动态钉点 661/661；unread：ref-only 266、
impl-only 8、matched_nc 20。ref-only 266 = CSR 190 + Fence 68（两 child dead_ref 逐条）+ DelayN_214 第 2 级 gpaddr[63:56] 8
（impl-only 8 是其对家 → 已补钉点）；matched_nc 20 = Div 6 + DelayN_214 14。

### 1.4 跑前预测（★跑完不许改本节★；docs/fm_predictions/ExeUnit_7.json）

| 项 | 预测 |
|---|---|
| 模型 expected | 31589（regs 25348 + outs 6194 + 模型误计的 PrintCommitIDModule 黑盒 47） |
| passing | **30273**（30245 + vmucp 28 对） |
| constant_reg / unread | 1011 / 258（ref，= verif/dead_ref/ExeUnit_7.json 逐条；impl 0） |
| passing + constant_reg + unread | 31542 = 模型 - 47 |
| failing / unverified / unmatched / 黑盒 / dont_verify | 0 / 0 / 0 / 0 / 无 |
| verdict | PASS_DEAD_REF（native SUCCEEDED） |
| fm_predict check | 预计报余额 47（同 CSR 登记的已知模型偏差） |

可能出错：(1) 若 passing = 30265，说明 DelayN_214 那 8 对没被钉成 matched（钉点会 error，不会静默）；(2) 若 CSR 动态钉点孤儿数与
诊断跑（661）不同，钉点文件 fail-closed 报错，不改判据改钉点。

## 2. ExuBlock（golden 3634 行）

### 2.1 结构与子模块处置

- wrapper `rtl/backend/ExuBlock.sv`（2478 行，`_GEN_`/`_T_` = 0）由 `scripts/gen_exublock.py` 新增变体生成（ExuBlock_1 `--check` 字节不变）。
  本层时序逻辑只有两样：frm 打拍 1 份（**未改**的共享核 `xs_ExuBlock_core`）、exus_7 的 io_error 再打两拍（共享件
  `xs_CriticalErrorDelay_core`，与 ExeUnit_7 同一个件）。CSR 的 instrAddrTransType 从 exus_7 的 csrio 出来直通顶层口并送 brh/jmp 所在
  ExeUnit（纯连线）；perf（alu/brh fire PopCount 分布）在综合口径被删，golden 只剩无读者的 *_probe / _GEN* 线，生成器核验无读者。
- 8 个直接 child 两侧白盒：exus/exus_2 = ExeUnit、exus_1/exus_3 = ExeUnit_1、exus_4/exus_6 = ExeUnit_4、exus_5 = ExeUnit_5、
  exus_7 = ExeUnit_7（evidence/52257043735e，PASS_DEAD_REF）；闭包 = 五个 ExeUnit UT Makefile 文件表的并集。无黑盒。
- FM 钉点：`fm_pins_pre.tcl`（字面 6089 = frm 3 + ExeUnit 70×2 + ExeUnit_1 10×2 + ExeUnit_5 53 + ExeUnit_7 5873；ExeUnit_7 那份
  尚未进 docs/pin_call_seq.tsv，条数与其签核 fm.log 的 `EXEUNIT_7_PIN_END ok=5873 bad=0 expect=5873` 核对，见 gen_exublock.py
  PENDING_PIN_LOGS）；`fm_pins.tcl`（动态）= ExeUnit_7 的 fm_pins.tcl 机械改前缀（/WORK/ExeUnit_7/ -> /WORK/ExuBlock/exus_7/）。

### 2.2 UT（verif/ut/ExuBlock，tb 由 gen.py 生成；RTL 字节 = commit 522570437，ExuBlock.sv 自 9a7c74f51 未变）

exus_7 口与全部 CSR 环境口照搬 ExeUnit_7 的 csr_exu_parts（激励 / 暖机 / arm / 覆盖），其余 7 口同 ExuBlock_1 套路（fuType 85% 取
Dispatcher acceptVec 编码、valid 60%、robIdx 窄范围、48 拍暖机）。翻转闸豁免全部按机理：exus_7 上 ExeUnit_7 tb 豁免的直连口；
无 busy 外壳的 in.ready；`{64'h0,..}` 高 64 位；ExeUnit_5 data_5[63:8]（VSetRiWvf res_data = {56'h0, vl}）；i2f fflags 的 UF/DZ/NV；
写回 Mux1H 全部成员 FU 在 golden 里把该字段赋常量的口（BranchUnit/JumpUnit 的 redirect.cfiUpdate 历史字段等）。
9 档读数见文末对账（official FM 与 UT 并行跑，同一 RTL 字节）。

### 2.3 诊断跑（如实记；diagnostic-full，关 vmucp，@28d32f0d1，未出证，钉点 6081 条全部生效）

native SUCCEEDED、passing 52729、failing 0、unmatched compare 0、constant_reg 1985；CSR 动态钉点 661/661；unread：ref-only 266
（= ExeUnit_7 dead_ref 258 加前缀 + exus_7 DelayN_214 第 2 级 gpaddr[63:56] 8）、impl-only 8（其对家）、matched_nc 74
（exus/exus_2 各 27 = ExeUnit 白名单、exus_7 Div 6 + DelayN_214 14）。那次 ExeUnit_7 钉点还没补 gpaddr 8 对，现已继承。

### 2.4 跑前预测（★跑完不许改本节★；docs/fm_predictions/ExuBlock.json）

| 项 | 预测 |
|---|---|
| 模型 expected | 55101（regs 40954 + outs 14100 + 模型误计 PrintCommitIDModule 黑盒 47） |
| passing | **52811**（52729 + vmucp 82 对） |
| constant_reg / unread | 1985 / 258（ref，= verif/dead_ref/ExuBlock.json 逐条） |
| failing / unverified / unmatched / 黑盒 / dont_verify | 0 / 0 / 0 / 0 / 无 |
| verdict | PASS_DEAD_REF（native SUCCEEDED） |
| fm_predict check | 预计报余额 47（已知模型偏差） |

## 3. 对账（跑后追加；上文各节未改）

### 3.1 ExeUnit_7（evidence/52257043735e，@522570437）
- verdict PASS_DEAD_REF：native SUCCEEDED，passing 30273，failing 0，unverified 0，unmatched 0，unread(ref) 258 = dead_ref 逐条相等，
  constant_reg 1011，无黑盒，无 dont_verify；钉点 pre 5873/5873、CSR 动态 661/661。与 §1.4 预测逐项相等（差 0）。
- vmucp 六条：(1) unread 只剩 258 ref = 声明；(2) 28 对一对一；(3) passing 30245 → 30273 恰 +28；(4) 全零；(5) 无放宽、无黑盒；
  (6) fm_target_config/ExeUnit_7.tcl 与钉点文件进 sidecar script_closure。
- `fm_predict check`：余额 47 = PrintCommitIDModule 模型偏差（§1.4 事先写明），工具按 fail 报。
- receipt sha256 `58e8d50ecf9aa88ba221836b732620561897c773ad19388a12e12cfe44876e0c`。
- 动态钉点夹具 `verif/ut/ExeUnit_7/fm_pins_fixture.tcl`：照该 fm.log 的 661 条 Set a match 抄入；tclsh 桩跑 fm_pins.tcl 的调用序列与
  fm.log 逐条相同（661/661）。
- 勘误（非预测数字）：§1.2 覆盖行「trap 进 M 1 602」应为「trap 进 M 602」。

### 3.2 ExuBlock（evidence/0da19ca59ab5，@0da19ca59）
- verdict PASS_DEAD_REF：native SUCCEEDED，passing 52811，failing 0，unverified 0，unmatched 0，unread(ref) 258 = dead_ref 逐条相等，
  constant_reg 1985，无黑盒，无 dont_verify；钉点 pre 6089/6089、CSR 动态 661/661。与 §2.4 预测逐项相等（差 0）。4310 s。
- vmucp 六条：(1) unread 只剩 258 ref = 声明；(2) 82 对一对一；(3) passing 52729 → 52811 恰 +82；(4) 全零；(5) 无放宽、无黑盒；(6) 进 script_closure。
- `fm_predict check`：余额 47 = PrintCommitIDModule 模型偏差（§2.4 事先写明）。
- receipt sha256 `d4946d3e7a661b79e013e478e85d382d75f07c3a6e6c510899b1cd1fa9bc27ee`。
- 第一次起跑因 proof worktree 路径长（TMPDIR=/home/eda/xs-env/tmp-exublock0）make 配方超 /bin/sh 单参数上限（Argument list too long），
  未进 FM；改 TMPDIR=/tmp/exb0 重跑即上表（同一 commit）。
- 动态钉点夹具 `verif/ut/ExuBlock/fm_pins_fixture.tcl`：照该 fm.log 661 条抄入，桩序列与 fm.log 逐条相同（661/661）。
