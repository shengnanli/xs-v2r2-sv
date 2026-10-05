# exublock2 lane（agent/exublock2）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `e1c779848` 之上的认领 commit `24229b85b`（`docs/lanes/exublock2_claim.md`） |
| 工作树 | `/home/eda/xs-env/wt-exublock2`，分支 `agent/exublock2` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 认领目标 | `ExeUnit_13` / `_14` / `_15` / `_16` / `_17` → `ExuBlock_2` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒；vmucp 逐目标白名单（`verif/fm_target_config/<T>.tcl`） |
| 冲突核对 | codex outbox 最新 0215、全部 `codex/*` 分支、全部 worktree 的 `*_claim.md` / `*_prereg.md` 逐名 grep：6 个目标无他人认领 / 改动（`fpu-parents_misc3_prereg.md` 里的 ExeUnit_13 只是「父未签」提及） |

### 0.1 child 签核核实（receipt impl_closure / golden_closure 逐文件 sha256 对当前字节）

| child | receipt | 结论 |
|---|---|---|
| VFMA | evidence/0ff9bafc9912/VFMA | SUCCEEDED，闭包一致 |
| VIAluFix | evidence/65d1243f7a9c/VIAluFix | SUCCEEDED，闭包一致 |
| VFAlu | evidence/f60583b94598/VFAlu | SUCCEEDED，闭包一致 |
| VFDivSqrt | evidence/462112cae72a/VFDivSqrt | SUCCEEDED，闭包一致 |
| VIDiv | evidence/9193a2e0077d/VIDiv | SUCCEEDED，闭包一致 |
| VPPU | evidence/d65d2da418a4/VPPU | SUCCEEDED，闭包一致 |
| VCVT_8 | evidence/0cb325757095/VCVT_8 | SUCCEEDED，闭包一致 |
| VSetRvfWvf | evidence/b5084fb3e0ed/VSetRvfWvf | SUCCEEDED，闭包一致 |
| ClockGate | evidence/bef96c62cc68/ClockGate | SUCCEEDED，闭包一致 |
| Dispatcher_13..17 | evidence/{fa200b1c,92a50405}-200c-final/Dispatcher_1[3-7] | SUCCEEDED，闭包一致 |
| **VIMacU** | 无 | **未重写、未签核**（rtl 里没有，任何分支 / claim 都没有）→ ExeUnit_13 阻塞 |
| **VIPU** | 无 | **未重写、未签核** → ExeUnit_14 阻塞 |

⇒ 本 lane 只做 ExeUnit_15 / 16 / 17；ExeUnit_13、ExeUnit_14 与其父 ExuBlock_2 阻塞，停下报告，不做。

### 0.2 生成器

wrapper 与钉点由 `scripts/gen_exeunit.py` 生成。exublock0 lane 在同一文件上有未合入 main 的改动（ExeUnit_7），
按任务书**本分支暂不提交 gen_exeunit.py / gen_exeunits_ut.py 的改动**：新增能力在 exublock0 版本之上开发（草稿留在
lane scratch），待 exublock0 合入 main 后 `git merge main` 再提交，并要求届时 `--check` 对本分支已提交的 wrapper /
钉点 / tb **逐字节不变**（老变体 ExeUnit / _1 / _4 / _5 / _8 / _9 / _10 已验 `--check` 不变）。新增能力：
- 向量外壳的 `dataPipe_<s>_src_<k>`（源操作数随 inPipe 打拍）计入字段保留规则；
- 连线表达式的两种改位宽外形：低位截取 `x[h:0]`、高位补零 `{n'h0, x}`；
- 写回字段比输出口宽时 golden 的低位截取 `x[ow-1:0]`（FU pdest 9 位 → 写回口 7 位）——★原生成器在这里会写出
  `{-1'h0, x}`（VCS 不报错、整个 Mux1H 拼包错位），UT 首轮 ExeUnit_17 / _15 大量失配即此，已修并加 fail-closed 检查★；
- 子 FU 钉点文件可以是多份（VFAlu 匹配前 1104 + 匹配后 34），支持 `set_user_match -type cell`；
- `tcl_esc` 先转义反斜杠（VIDiv 打包结构体寄存器名 `outCtrl_r_reg\[vuopIdx][b]`）。

## 1. 结构

| 目标 | FU | golden 行 | impl 行 | `_GEN_`/`_T_` | 子模块 |
|---|---|---|---|---|---|
| ExeUnit_15 | Vfma(VFMA, 延迟 3) / VialuFix(VIAluFix, 延迟 1)，inPipe 3 级 | 976 | 586 | 0 / 0 | 全部两侧白盒 |
| ExeUnit_16 | Vfalu(VFAlu, 延迟 1)，inPipe 1 级 | 528 | 348 | 0 / 0 | 全部两侧白盒 |
| ExeUnit_17 | Vfdiv(VFDivSqrt) / Vidiv(VIDiv)，均不定延迟，busy | 753 | 563 | 0 / 0 | 全部两侧白盒 |

共享核 `rtl/backend/xs_ExeUnit_core.sv` **未改**（字节同 main）。UT：`verif/ut/<T>`，tb 由 gen_exeunits_ut.py 的
ExeUnit 家族通用配置生成；复跑 `cd verif/ut/<T> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

## 2. ExeUnit_16 / ExeUnit_17（本节先于这两个目标的 official FM 提交）

### 2.1 UT（3 seed × 3 档 initreg × 200k 拍，串行，全部 errors=0、TEST PASSED）

| 目标 | seed 1：0 / random / 1017 | seed 7：0 / random / 7017 | seed 42：0 / random / 42017 | 每档 checks |
|---|---|---|---|---|
| ExeUnit_16 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 5,199,662 |
| ExeUnit_17 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 4,799,496 |

覆盖（seed 1 / 7 / 42 的 *017 档等，均过门槛 >1000）：
- ExeUnit_16：in 97010 / out 97054 / 反压 9682 / 冲刷 16381 / 无 FU 命中 17889 / 门控开 177670 / 关 22318；
- ExeUnit_17：in {8233, 8210} / out {5785, 5620} / 反压 1111 / 冲刷 12110 / 无 FU 18232 / 门控开 229872 / 关 170092 / busy 167374
  （seed 7：反压 1087；seed 42：1150 —— 反压门槛余量小，长延迟除法器外壳 busy 拦截使 out.valid 拍数少）。

变异自检（`scratchpad/exublock2/mut.py`，沙箱 = UT 目录与 wrapper 副本，仓库 RTL 不被触碰；seed 7 × random × 20k 拍）：
- ExeUnit_16 3/3 抓到：M1 dataPipe_1_src_2 接成 src_3（75684）/ M2 data_src_4 取 [15:8]（16）/ M3 第 1 级 src_4 改读本拍（29152）；
- ExeUnit_17 2/2 抓到：M1 写回 pdest 取 [7:1]（549）/ M2 Mux1H 选择位对调（20483）；
  M3（Vfdiv 的 pdest 补位 1'h0 → 1'h1）UT errors=0 —— 只进 FU 锁存的 pdest[7]，外壳写回口只取 [6:0]，结构上不可见；
  由 FM 覆盖（pdest_r[7] 两侧整组钉点 + vmucp 实比，见下；FM 实测见对账）。

### 2.2 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/<T>.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（merge_dup=false 下严格）。数字取自诊断跑（diagnostic-full，不产 receipt）。

| 目标 | 模型 expected | 预测 passing | 预测 constant_reg | vmucp 前 unread | 钉点 | 其余 |
|---|---|---|---|---|---|---|
| ExeUnit_16 | 6512（5331 + 1181） | **6150** | 362 | 148（全 matched_nc，开 vmucp 后计入 passing） | fm_pins_pre.tcl 3250 | failing / unverified / unmatched 0，无黑盒，SUCCEEDED |
| ExeUnit_17 | 17135（16084 + 1051） | **17123** | 12 | 104 matched_nc + 2 钉上后归常量 | fm_pins_pre.tcl 1632 | 同上 |

依据：
- ExeUnit_16 诊断跑（vmucp=false）：passing 6002 / constant 362 / unread 148 = inPipe_1_1_src_4[127:8] 120 + Vfalu mgu vdIdx[6:3] 4 +
  VectorFloatAdder 子实例对称死位 24；6002 + 148 + 362 = 6512。钉点 3250 = 外壳寄存器 446 + VFAlu 匹配前 1104 + 匹配后 34 +
  外壳附加 1666（gen_exeunit.py `_VFALU_*` 语义表：进外壳后 FM 签名分析配不上的 595 个 ref DFF 与远路加法器交换律对称的两个加数，
  按重写件源码逐行注明的 golden 对应名整寄存器钉；与 VFAlu 自签核 FM matched.rpt 的配对逐位一致）。
- ExeUnit_17 诊断跑（vmucp=true，白名单 verif/fm_target_config/ExeUnit_17.tcl）：passing 17123 / constant 12 / unread_notcompared 0，
  17123 + 12 = 17135。vmucp=false 时 passing 17019、unread 106（104 matched_nc + 2 unmatched 的 pdest_r[7]，已钉）。

### 2.3 补登（ExeUnit_16 重证前提交；2.2 节数字不改）

ExeUnit_16 首次 official 跑（commit `0bff177c2`，evidence/0bff177c2290/ExeUnit_16，SUCCEEDED passing 6150 / constant 362，
与预测逐位一致）的 fm.log 里 `Set a match` 只有 3246 条，钉点文件自报接受 3250：外壳附加的 VFAlu `_VFALU_F32` 表
（U_FS1 io_result_r_2 ↔ lo_sum_q 全 18 位）与 VFAlu 匹配后钉点里的 4 对（各实例 U_FS1 io_result_r_2[0]）重复，FM 对重复
的 set_user_match 返回 1 但不打印。生成器改为跳过与子 FU 原钉点重复的外壳附加对，钉点文件 3250 → **3246**（期望 = 真实
Set a match 数），其余不变；用新钉点重证，预测不变（passing 6150 / constant 362）。旧 receipt 不入库。

## 对账（跑后追加）

### ExeUnit_16 —— evidence/286da6e8f076/ExeUnit_16（commit `286da6e8f`，run_proof.sh，signoff-strict，vmucp=true）

| 项 | 预测 | 实测 |
|---|---|---|
| native | SUCCEEDED | SUCCEEDED |
| passing | 6150 | **6150** |
| constant_reg | 362 | 362 |
| failing / unverified / aborted / unmatched / unread_notcompared | 0 | 0 / 0 / 0 / 0 / 0 |
| 黑盒 / dont_verify / elab147 | 无 | 无 / 无 / 无 |
| 钉点 | 3246 | PIN_END ok=3246 bad=0；fm.log `Set a match` 3246 |

vmucp 六条：精确绑定（诊断跑 unread 148 点，名单见 ExeUnit_16.tcl）/ 双射（148 ref ↔ 148 impl，全 matched_nc）/
真比较（passing 6002 → 6150，恰 +148）/ 全零 / 无 dont_verify、无黑盒 / 本文件进 receipt script_closure。
`fm_predict.py check ExeUnit_16`：差额 362 = constant_reg 362，rc=0。

### ExeUnit_17 —— evidence/0bff177c2290/ExeUnit_17（commit `0bff177c2`，同口径）

| 项 | 预测 | 实测 |
|---|---|---|
| native | SUCCEEDED | SUCCEEDED |
| passing | 17123 | **17123** |
| constant_reg | 12 | 12 |
| failing / unverified / aborted / unmatched / unread_notcompared | 0 | 0 / 0 / 0 / 0 / 0 |
| 黑盒 / dont_verify / elab147 | 无 | 无 / 无 / 无 |
| 钉点 | 1632 | PIN_END ok=1632 bad=0；fm.log `Set a match` 1632 |

vmucp 六条：精确绑定（104 matched_nc + 2 个钉上的 pdest_r[7]）/ 双射 / 真比较（17019 → 17123，+104；两个 pdest[7] 输入恒 0、
归 constant_reg）/ 全零 / 无 dont_verify、无黑盒 / 本文件进 script_closure。`fm_predict.py check ExeUnit_17`：差额 12 = constant_reg 12，rc=0。

变异 ExeUnit_17 M3（Vfdiv pdest 补位 1'h0 → 1'h1）的 FM 实测：在沙箱里对变异体跑同口径 FM，**SUCCEEDED passing 17123**
—— pdest[7] 两侧都是常量寄存器且无读者，到不了任何输出口，这是边界上的**等价变异**（不是 UT / FM 的漏检）；记为 EQUIV，不计分母。

## 3. ExeUnit_15（本节先于该目标的 official FM 提交；生成器已在 main 61f5d3df 之上提交，`--check` 全变体逐字节不变）

### 3.1 UT（3 seed × 3 档 initreg × 200k，串行，全部 errors=0、TEST PASSED，每档 checks 4,999,475）

| seed 1：0 / random / 1017 | seed 7：0 / random / 7017 | seed 42：0 / random / 42017 |
|---|---|---|
| 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |

覆盖：seed 1 in {50858, 49820} / out {43500, 48435} / 反压 8153 / 冲刷 16432 / 无 FU 17986 / 门控开 275604 / 关 124366；
seed 7、42 的 *017 档同量级（反压 8326 / 8081）。
（首轮 9 档在旧 wrapper 上 errors≈949k：生成器写出 `{-1'h0, pdest}`，见 §0.2；修后整轮重跑，上表为重跑结果。）

变异自检（同 §2.1 方法）：M1 Vfma 第 3 级 pdest 改读第 1 级（4136）/ M3 Mux1H 选择位对调（126371）/ M4 Vfma validPipe_3 改读第 2 级（41628）
3/3 抓到；M2 VialuFix 第 1 级 pdest 补位 1'h0 → 1'h1：UT 0 —— 与 ExeUnit_17 M3 同类（只进 FU 锁存的 pdest[7]，无读者到不了输出口），
按 §对账里 ExeUnit_17 M3 的 FM 实测结论记为等价变异。

### 3.2 跑前预测（★跑完不许改★，docs/fm_predictions/ExeUnit_15.json）

| 模型 expected | 预测 passing | 预测 constant_reg | vmucp 前 unread | 钉点 | 其余 |
|---|---|---|---|---|---|
| 9166（8114 + 1052） | **8960** | 206 | 388（全 matched_nc） | fm_pins_pre.tcl 4830（外壳 1322 + VFMA 3508；fm.log Set a match 4830） | failing / unverified / unmatched 0，无黑盒，SUCCEEDED |

依据：诊断跑（vmucp=false）passing 8572 / constant 206 / unread 388（inPipe 三级 src_4[127:8] 360 + vuopIdx[6:3] 12 + 第 2、3 级 fuOpType
除 bit4 外 16，见 verif/fm_target_config/ExeUnit_15.tcl）；8572 + 388 + 206 = 9166。

### ExeUnit_15 —— evidence/72b8d871e573/ExeUnit_15（commit `72b8d871e`，run_proof.sh，signoff-strict，vmucp=true）

| 项 | 预测 | 实测 |
|---|---|---|
| native | SUCCEEDED | SUCCEEDED |
| passing | 8960 | **8960** |
| constant_reg | 206 | 206 |
| failing / unverified / aborted / unmatched / unread_notcompared | 0 | 0 / 0 / 0 / 0 / 0 |
| 黑盒 / dont_verify / elab147 | 无 | 无 / 无 / 无 |
| 钉点 | 4830 | PIN_END ok=4830 bad=0；fm.log `Set a match` 4830 |

vmucp 六条：精确绑定（388 点，ExeUnit_15.tcl）/ 双射 / 真比较（8572 → 8960，恰 +388）/ 全零 / 无 dont_verify、无黑盒 /
本文件进 script_closure。`fm_predict.py check ExeUnit_15`：差额 206 = constant_reg 206，rc=0。
