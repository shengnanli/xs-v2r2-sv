# ClockGate lane（agent/clockgate）—— 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `cdb0e122`（main） |
| 工作树 | `/home/eda/xs-env/wt-clockgate`，分支 `agent/clockgate` |
| 裁定 | codex 0208 选项 B：ClockGate 作为自包含 RTL 重写并独立签核（不做 vendor boundary） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/ClockGate.sv`（14 行，只读） |
| 目标 | `ClockGate`（standalone），随后 impl 闭包含 ClockGate 的父级批量重证 |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无 fm_pins |

## 1. ClockGate

### 1.1 结构

- 唯一状态元件 = 1 个低电平透明锁存器（golden 名 `EN`，重写名 `enableLatched`），
  加一个与门 `Q = CK & latched`。0 子模块、0 黑盒。
- 重写件 `rtl/common/ClockGate.sv` 37 行，`_GEN_`/`_T_` = 0。

### 1.2 UT（verif/ut/ClockGate，seed 1/7/42 × initreg 0/random/<seed>017 × 200k 周期）

每周期 4 段（低相改 E/TE 1–3 次 / 上升沿 / 高相翻 0–3 次 / 下降沿），E/TE 变化与 CK 沿错开 ≥1ns；
每个检查点比 Q 4 态全等 + 锁存器内部值全等 + 两者都等于 tb 参考模型。先跑定向四场景
（低相更新、拉高后保持、高相 E/TE 翻转不穿透（开/关两方向）、TE 强制开门）。

```
seed=1 initreg=0 rc=0 INFO power-up (before first low phase): Q g=0 i=0 latch g=0 i=0 cover: lowUpdate=93078 holdHigh=140781 blockOn=48315 blockOff=57264 teForce=25034 pulse=125419 gated=74587 checks=1100184 errors=0 
seed=1 initreg=random rc=0 INFO power-up (before first low phase): Q g=1 i=1 latch g=1 i=1 cover: lowUpdate=93078 holdHigh=140781 blockOn=48315 blockOff=57264 teForce=25034 pulse=125419 gated=74587 checks=1100184 errors=0 
seed=1 initreg=1017 rc=0 INFO power-up (before first low phase): Q g=0 i=0 latch g=0 i=0 cover: lowUpdate=93078 holdHigh=140781 blockOn=48315 blockOff=57264 teForce=25034 pulse=125419 gated=74587 checks=1100184 errors=0 
seed=7 initreg=0 rc=0 INFO power-up (before first low phase): Q g=0 i=0 latch g=0 i=0 cover: lowUpdate=94020 holdHigh=141003 blockOn=48353 blockOff=57377 teForce=25091 pulse=124888 gated=75118 checks=1099588 errors=0 
seed=7 initreg=random rc=0 INFO power-up (before first low phase): Q g=0 i=0 latch g=0 i=0 cover: lowUpdate=94020 holdHigh=141003 blockOn=48353 blockOff=57377 teForce=25091 pulse=124888 gated=75118 checks=1099588 errors=0 
seed=7 initreg=7017 rc=0 INFO power-up (before first low phase): Q g=1 i=1 latch g=1 i=1 cover: lowUpdate=94020 holdHigh=141003 blockOn=48353 blockOff=57377 teForce=25091 pulse=124888 gated=75118 checks=1099588 errors=0 
seed=42 initreg=0 rc=0 INFO power-up (before first low phase): Q g=0 i=0 latch g=0 i=0 cover: lowUpdate=94012 holdHigh=141191 blockOn=48780 blockOff=57115 teForce=24789 pulse=124464 gated=75542 checks=1099933 errors=0 
seed=42 initreg=random rc=0 INFO power-up (before first low phase): Q g=1 i=0 latch g=1 i=0 cover: lowUpdate=94012 holdHigh=141191 blockOn=48780 blockOff=57115 teForce=24789 pulse=124464 gated=75542 checks=1099933 errors=0 
seed=42 initreg=42017 rc=0 INFO power-up (before first low phase): Q g=0 i=1 latch g=0 i=1 cover: lowUpdate=94012 holdHigh=141191 blockOn=48780 blockOff=57115 teForce=24789 pulse=124464 gated=75542 checks=1099933 errors=0
```

上电初值（第一个低相之前）只打印不计错：random 与 <seed>017 档两个实例各摇各的初值
（seed 42 实测 g=1 i=0 / g=0 i=1），是双例化 initreg 伪影；库 ICG 同样无初值。

变异自检（scratchpad，不进库，seed 1 × 20k 周期）：
M1 锁存极性反（`if (CK)`）errors=46735；M2 丢 TE errors=19589；M3 锁存器改透明组合 errors=28074；
M4 Q 不经锁存（`CK & (TE|E)`）errors=14037；M5 锁存内阻塞改非阻塞 errors=0 ——
M5 是等价变异（单条赋值，阻塞/非阻塞在锁存器里行为相同），FM 同样不区分；保留 golden 的阻塞写法。

复跑：`cd verif/ut/ClockGate && make run SEED=<1|7|42> SIM_ARGS="+ncycles=200000 +vcs+initreg+<0|random|<seed>017>"`

### 1.3 跑前预测（★跑完不许改本节★）

| 目标 | passing 预测 | 其余 |
|---|---|---|
| ClockGate | `fm_predict.py model` = **1**（regs 1 + outs 0） | failing 0 / unverified 0 / aborted 0 / unread 0 / unmatched 0 / 无黑盒 / SUCCEEDED |

### 1.4 明写可能出错的地方

1. Formality 对锁存器的处理：可能把 `EN` 当作 latch 比较点（预测按 1 个寄存器点算），
   也可能识别为 cut point / 时钟门控结构把 Q 当作组合输出比。若 passing ≠ 1，先看
   `report_compare_points` 里比较点的类型，照实记录；只要 Q 与锁存器都在比较覆盖内即可。
2. Q 是"时钟"输出：FM 可能把它视为 clock net 而不建 output 比较点（模型 outs=0 的来历），
   那样锁存器那一点就是唯一比较点。
3. 名字不同（`EN` vs `enableLatched`）：单锁存器靠签名分析应能配上；若 unmatched，
   不用 set_user_match，改走 fm_pins_pre 或对齐命名。

## 2. 父级批量重证

见本文件后续分节（公共 filelist / 生成器改为 impl 读 rtl/common/ClockGate.sv 之后登记）。

## 对账（ClockGate standalone，run `bef96c62cc68`）

| 项 | 预测 | 实测 |
|---|---|---|
| verdict | SUCCEEDED | **SUCCEEDED**（signoff-strict，native SUCCEEDED） |
| passing | 1 | **2** = LAT 1 + Port 1（DFF 0 / Cut 0 / Loop 0 / BBPin 0） |
| failing / unverified / aborted / unread / unmatched | 0 | 0 / 0 / 0 / 0（unread_points.txt 空）/ 0(0) |
| 黑盒 / dont_verify | 无 | 无 / 无 |

差额 +1 逐项指认：模型的 outs=0 把输出 Q 当成时钟网不建比较点（§1.4 第 2 条的猜测），
实际 Formality **为 Q 建了 Port 比较点**（按名配上）；锁存器 EN↔enableLatched 是
**LAT 类比较点**（签名分析配上），未被识别为 cut point。即 Q 与锁存器两者都在比较覆盖内。
3 个输入 TE/E/CK 全部配上。11 秒跑完。

复跑：`bash scripts/run_proof.sh ClockGate ClockGate < /dev/null`

### 预测差额的根因与模型修正（登记不改，差额照记）

`fm_predict.py check ClockGate` 判红（预期 1 / 实测 2 / 可指认 0）。根因是模型解析器漏数：
`fm_passing_model.OUT_RE` 只认 firtool 的 `output [h:l] name`，不认带线网类型的
`output wire Q`（golden ClockGate.sv 是 Scala 内联 SV）。已放宽为容忍 `wire|logic|reg`。
golden 里带类型的 output 头只有 ClockGate.sv 与 3 个 DPI helper（Mem1R1WHelper/SDCardHelper/FlashHelper，
都不是 FM 目标），所以这条修正只动 ClockGate 一份：`fm_predict.py recompute` 全仓 600 份登记中
ClockGate 1 -> 2「修后逐位等于实测」；另 6 份变化（Rob、TLBuffer_6/8/9/20/22）与本修正无关
（它们的 golden 头不含带类型 output），是基线上已存在的漂移，未动其登记。`--selftest` PASS。

## 2. 集成：impl 侧改读 rtl/common/ClockGate.sv（步骤 4）

- 机制：`scripts/ut_common.mk` 新增 `LOCAL_SHARED_PRIMITIVES = ClockGate.sv` 与 `localprim` 闸
  （simv 与 fm-% 前置；impl 侧 RTL_GOLDEN_DEPS 若再读 golden ClockGate.sv 即 fail）；UT 中两实例共用
  RTL_GOLDEN_DEPS 的本地件，GOLDEN_SRCS 里同名 golden 文件自动剔除。ref 侧 FM_REF_DEPS 一律不动（仍 golden）。
- 31 个 UT 目录：29 个手写 Makefile 机械替换；SRAMTemplate 由 `scripts/gen_sram_wrappers.py`、
  SRAMTemplateNewForm 由其 `gen.py` 改生成器后重生成（后者原先不支持 --check、带 --check 会直接覆写，已补）。
  合 main@bd3b7081 后复查：impl 侧读 golden ClockGate 的 = 0。全仓 295 个带 --check 的生成器改前改后结果一致。
- 冒烟（seed 1，各目录默认 initreg 档）：31/31 编译通过、errors=0；5000 拍一档里 19 个只因覆盖地板/激励量门槛
  判 FAIL（无失配），改用默认拍数复跑 19/19 PASS。
- 闭包对称闸（check_closure_symmetry --only 32 目录）：SYMMETRIC 92 / ERROR 12；12 个 ERROR 是 sv_elab
  解析不了 NUM_BANK / payload_t 等标识符，在 main@bd3b7081 上原样复现（同 12 个），与本改动无关。
- 受影响目标清单：`docs/lanes/clockgate_affected_targets.tsv`（103 个，impl 闭包从 golden ClockGate 换成本地件）。
  ★注意★ `check_shared_impl_impact.py --file rtl/common/ClockGate.sv` 只报出 ClockGate 自己：旧 receipt
  把 golden ClockGate 记成 kind=golden，不在 hash 反查范围内，所以这 103 个目标**不会被自动判 STALE**，
  须按本清单人工安排重证。父级重证由 restale-sram lane 负责（集成者调整分工）。
