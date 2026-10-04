# exeunits lane（agent/exeunits）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `1ce47a77a` 之上的认领 commit `86ef411b5`（`docs/lanes/exeunits_claim.md`） |
| 工作树 | `/home/eda/xs-env/wt-exeunits`，分支 `agent/exeunits` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | 叶子 `VSetRiWvf` / `IntFPToVec` / `CVT64` / `IntToFP_3` → 外壳 `ExeUnit` / `_1` / `_4` / `_5` / `_8` / `_9` / `_10` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 冲突核对 | codex outbox 最新 0209 与全部 `codex/*` 分支、全部 worktree 的 `*_claim.md` / `*_prereg.md` 逐名 grep：11 个目标名无他人认领 / 改动（k3next20 / newrtl_next20 / vectorcvt-tree 的 prereg 里出现的 IntToFP_3 / ExeUnit_5 / ExeUnit_9 / CVT64 只是「父模块 / 参照」提及，均标 MISSING/UNPROVEN 无人认领） |

UT 统一：`verif/ut/<T>`，tb 由 `scripts/gen_exeunits_ut.py` 从 golden 端口表生成（`--check` 幂等），
双例化 golden vs 重写 `_xs`，**每拍比较全部输出口**（`!==`）；3 seed × 3 档 initreg × 200k 拍，串行；
覆盖门槛写进 PASS 判据（任一不足即 TEST FAILED）。
复跑：`cd verif/ut/<T> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

变异自检：`scratchpad/exeunits/mut.py`（沙箱 = rtl 副本，仓库 RTL 不被触碰），seed 7 × random × 20k 拍。

## 1. 叶子四个

### 1.1 结构

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | 写法 |
|---|---|---|---|---|
| VSetRiWvf | 214 | 208 | 0 | 新核 `xs_VSetRiWvf_core`；复用已签 `vset_pkg`（backend_common_pkg.sv，**未改**）的计算函数；golden 的 VsetModule 两侧语义相同但 impl 不例化（同 VSetRiWi / VSetRvfWvf） |
| IntFPToVec | 218 | 175 | 0 | 新核 `xs_IntFPToVec_core`（fli 三表 + 标量选源 + 复制 / NaN-box / 规范 NaN），FliH/S/D 表为已签重写件两侧白盒 |
| CVT64 | 224 | 183 | 0 | 新核 `xs_CVT64_core`（isVectorCvt=false：只 FP_INCVT + 本层「源非 NaN-box ⇒ 规范 NaN」），寄存器与 golden 同名；与 CVT64_1（向量实例）结构不同，不共核 |
| IntToFP_3 | 309 | 299 | 0 | 新核 `xs_IntToFP_3_core`（valid 链 / 反压链 / 两级使能 / perf payload，写法同已签 FCVT）；IntToFPDataModule 子树全为已签重写件 |

子模块全部两侧白盒（impl 读重写件、ref 读 golden），无黑盒、无同源共享件。

### 1.2 UT（各 3 seed × 3 档 × 200k，全部 errors=0）

| 目标 | seed 1：0 / random / 1017 | seed 7：0 / random / 7017 | seed 42：0 / random / 42017 | 每档 checks |
|---|---|---|---|---|
| VSetRiWvf | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 5,399,946 |
| IntFPToVec | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 4,199,958 |
| IntToFP_3 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 4,199,748 |
| CVT64 | 见 1.2.1 | | | 399,980 |

覆盖（seed 1）：
- VSetRiWvf：vl=0 78452 / vl=VLMAX 13780 / vtype 写 49969 / 非法 69929 / 合法 30053 / 中间 vl 7750；
- IntFPToVec：fli h/s/d 20362/33976/20511，复制且换规范 NaN 11818 / 复制原值 10561 / fmv 40243 / 立即数 53580 / 原样 31225；
- IntToFP_3：fire 133199 / 写回 126042 / 反压 9792 / 转换 66526 / fmv 66673 / f16/f32/f64 43445/43010/43381 / 动态 rm 26470；
- CVT64：规范 NaN（整数目的 / 浮点目的 / fround）19058/9635/7132，f2i 71057 / i2f 36165 / f2f 32523 / fround 24189 / fcvtmod 9434。

1.2.1 CVT64 的寄存器在 UT 跑完后改成与 golden 同名（`2faf43e28`，纯改名，逻辑字节外无改动），9 档在该 commit 上
重跑中，结果与改名前（9/9 errors=0，同上覆盖数）一并在对账里落数。

变异自检：VSetRiWvf 4/4 抓到（M1 vtype 写口判据 8070 / M2 vlmax 未取下界 478 / M3 AVL 选源 172 / M4 非法时 vma 未清 6924）；
IntFPToVec 3/5 抓到（M2 e16 规范 NaN 常数 370 / M4 fli.s 未 NaN-box 3395 / M5 丢 validPipe(0) 5091），
M1（fli 时仍按 isImm 选源）与 M3（fmv 判据丢 ~needDup）**是等价变异**：fli 优先级高于 isImm、needDup 优先级高于 fmv，
被改的项都被更高优先级的分支遮蔽，errors=0 符合预期（FM 同理判等价）；
IntToFP_3 4/4（M1 valid 链加 ready 门控 13386 / M2 第 2 级使能丢 validPipe(1) 2437 / M3 payload 第 1 级不看 ready 11395 /
M4 写回丢 validPipe(2) 1425）；CVT64 在改名后重跑，对账落数。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/<T>.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（merge_dup=false 下严格）。

| 目标 | 模型 expected | 预测 passing | 预测 constant_reg | unread | vmucp | 其余 |
|---|---|---|---|---|---|---|
| VSetRiWvf | 736（0 + 736） | **736** | 0 | 0 | 否 | failing / unverified / unmatched 0，无黑盒，SUCCEEDED |
| IntFPToVec | 791（0 + 791） | **791** | 0 | 0 | 否 | 同上 |
| CVT64 | 572（503 + 69） | **545** | 27 | 5（全 matched_nc，vmucp 开后计入比较） | 是（verif/fm_target_config/CVT64.tcl） | 同上 |
| IntToFP_3 | 2158（1427 + 731） | **2158** | 0 | 0 | 否 | 同上 |

依据：
- CVT64 的 constant_reg 27 取自 FP_INCVT 单独签核（evidence/96363f56a451/FP_INCVT：passing 467 + constant 27 = 模型 494）与
  FCVT 父级（evidence/b8c893dad053/FCVT：constant 27）；CVT64 自己的 78 个寄存器位都不是常量（s2 规范值每一位都能被 u32/u64
  的全 1 置位）。isFpToVecInst 在本实例恒 1，若因此多出常量寄存器，差额会出现在 constant_reg 里、由 fm_predict check 指认。
- IntToFP_3：IntToFPDataModule 单独签核 passing 212 = 模型 212（无常量寄存器），本层寄存器（valid 链 2 + perf/seq payload 2×641）均非常量。
- 无 fm_pins：叶子的寄存器要么与 golden 同名（CVT64），要么是已签 FCVT 同款写法（IntToFP_3 的 vldThisFu / perfVec），预期名字匹配可配上；
  若出现 unmatched，先补 fail-closed 钉点再重跑，并在对账里写明。本节未做任何 FM 试跑。

复跑：`bash scripts/run_proof.sh <T> <T> < /dev/null`（UT 目录名与目标同名）。
