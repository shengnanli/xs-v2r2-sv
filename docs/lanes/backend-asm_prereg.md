# backend-asm lane（agent/backend-asm）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `20df9ac22`（main）+ 认领 `9df1c6fb0`，工作树 `/home/eda/xs-env/wt-backend-asm`，分支 `agent/backend-asm` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/Backend.sv`（79,590 行 / 2,365 端口 / 46 实例 31 种 / 本层 420 个寄存器 1,297 位）（只读） |
| 目标 | Backend（后端顶层装配） |
| 证明形态 | codex 0226 exact green_child 组合（同 Frontend）：31 种直接子模块全部 green_child，两侧 `-interface_only` |
| 口径 | `FM_MODE=assembly`，`FM_MERGE_DUP=false`，无 dont_verify / 无 vmucp / 无 dead_ref |

冲突检查（2026-10-10）：codex outbox 最新 0002（课程网页更新）、0226（Frontend）均不涉及 Backend；codex/* 分支只动叶子算术 / CSR / PMA·PMP 叶子。

## 1. 重写件

- `rtl/backend/Backend.sv`：
  * `xs_Backend_core`（手写，约 590 行）八节：§1 SoC 输入打拍（中断 / MSI / CLINT / L2 刷新，RegNext / RegEnable）；
    §2 CSR 回送与 TopDown / difftest 打拍、关键错误；§3 vsetvl vtype 暂存（异步复位）与写 CSR 的 vtype 选择；
    §4 写回端口（派遣忙表清除 wen&&xWen、给调度器的晚一拍写回）；§5 唤醒总线晚一拍（只造 golden 里有读者的字段）；
    §6 访存写回字段（load intWen、Vldu 寻址类型译码）；§7 27 个发射流水的 rightOutFire / isFlush（needFlush + load 取消
    + Vldu 超时）、Vldu 超时计数器（异步复位）/ 更老 uop / 发射回应、ROB 头访存发射；§8 访存 uop 的 pc。
  * `Backend` wrapper：`scripts/gen_backend.py` 生成（`--check` 幂等，fail-closed 规则见生成器头）。纯连线形状（直连 / 位截取 /
    高位补零 / golden 具名别名线）在 wrapper，有运算或寄存器的一律进 u_core；46 实例模块名与实例名照搬；每对实例连接有说明。
- 钉点 `verif/ut/Backend/fm_pins_pre.tcl`：只有本层 420 个 golden 寄存器 → u_core 寄存器（1,297 位，逐条数返回值）。不碰 child 内部，
  不读诊断 matched.rpt，没有多对多。
- 规模：golden 79,590 行 → impl 47,7xx 行（核约 590 行，其余是生成区 3.0 万个端口连接的逐行展开）。`_GEN_`/`_T_` 0，readability_audit rc=0。

## 2. UT（verif/ut/Backend；tb 由 gen.py → scripts/gen_l2slice_ut.py 生成）

双例化 golden Backend（golden 子树 978 个模块）vs Backend_xs（31 种直接子模块都换成各自签核 UT 的重写件 —— 860 个重写文件，
即 31 个子 UT 目录 RTL_SRCS 的并集；两侧共读的是各子 UT 本来就两侧共用的 golden 件 93 个与未被重写的 golden 叶子）。
逐拍 4 态比全部 1,008 个输出。初值档只用常量 0 / 1（双例化不用 initreg random）。
取舍：并集派生一次 22 分钟、编译 15 分钟；复跑必须 `make derive` 一次后 `touch ut_gen/*.sv`，再 `make run ... -o derive -o simv`
（ut_common 的 derive 是 .PHONY 的 order-only 前置，否则每次 run 都重派生 22 分钟）。

## 3. 子证书（31 种直接子模块的 current-valid 链）

递归闭包（各 child receipt 的 impl 侧 golden 依赖）共 120 个 target。HEAD 上复核：
- 已 current（直接出证 / 已有证书）：DelayN_1（已有）+ 17 个（aa1702a37）+ FPCVT（160a9b854）。
- 其余 99 个 receipt 因 `scripts/fm_eq.tcl` 在其后改过（script_closure_changed）或缺 RUN_CONTEXT 而陈旧，
  用 `/home/eda/xs-env/tools/batch_reproof.py run --commit 9df1c6fb0 --jobs 4 --tag be` 在 PROOF_COMMIT=9df1c6fb0 上重证。
  实测（PROOF_COMMIT=9df1c6fb0，evidence/9df1c6fb0545/，9a6f85e14 提交）：已完成 98 个，verdict 与 passing **与各自上一份 receipt 逐个相同**；
  其中 57 行 fm_predict 标 MISMATCH 全是「登记文件不在 git」的老目标（集成者确认非真失配）；NewPipelineConnectPipe_10 的证书按集成者通知
  手工从自己的 evidence 出（batch 日志名截断串号）。ExuBlock_1 receipt（1e7fbcc94d3c）在 FloatAdder 等证书入库后 current，直接出证（1f1547d2b）。
  CtrlBlock 仍在跑（上次 36035 s）。在 HEAD 9a6f85e14 上 `batch_reproof.py validate` 119 个（除 CtrlBlock）除 ExuBlock / ExuBlock_1 外全部 current（ExuBlock_1 随后补证）。
  重证大户（上一份 receipt 用时）：CtrlBlock 36035 s、DecodeStage 5142、Scheduler_3 4744、Scheduler 4717、ExuBlock_2 4124、
  NewDispatch 2115、VTypeBuffer 1959（已 current 未重跑）、DataPath 1885、Scheduler_1 1706、DecodeUnitComp 1684、Scheduler_2 1680。
- ★两个结构性阻塞（需集成者裁定，见报告）★：
  1. CtrlBlock：其证明把 3 个非 2 次幂 RAM（dt_pcTransType_160x2 / diff_rat_state_bank_320x776 / stateBankTags_320x3）两侧
     `-interface_only`（APPROVED_MEMORY_MACRO_MODEL）——validate_certificate_current 要求 hdlin_interface_only 恰为 green_child 集合
     （→ `green_child_interface_only_not_declared_set`），且这三个 golden 既非 FM target 也不在 MC 登记表（dt_pcTransType_160x2 /
     stateBankTags_320x3 多读口，mc_memory_registry 推导 `not_single_instance`；diff_rat_state_bank 可推导）。
  2. ExuBlock：impl 闭包两侧共读 golden `PrintCommitIDModule.v`（无输出、只有 `ifndef SYNTHESIS 的 $fwrite），
     validate_impl_golden_certified 对非 .sv 直接判 `green_child_impl_golden_unexpected_path`。

## 4. FM canary（工作树、不产 receipt，414dfdfc3 + 核函数修正）

| 跑 | native | passing | failing | unmatched | unread | constant_reg | 黑盒 |
|---|---|---|---|---|---|---|---|
| canary1 | ERROR | — | — | — | — | — | impl set_top 失败：核里两个 function 读模块级变量（FMR_VLOG-091）→ 改为全部经参数传入 |
| canary2 | SUCCEEDED | **280043** | 0 | 0(0) | 0 | 0 | 92 对象 = 46 实例 × r/i，全为 `i` 属性 |

钉点 BE_CORE_PIN_END ok=1297 bad=0。匹配：1297 user + 278746 name + 0 signature；passing 构成 BBPin 209806 / Port 68940 / DFF 1297。
`fm_predict.py model Backend`：expected 280043（regs 1297 + outs 68940 + 黑盒输入 209806），模型适用。

## 5. official 预测（★跑完不许改本节★，登记 docs/fm_predictions/Backend.json）

native SUCCEEDED；passing **280043**、constant_reg **0**、failing / unverified / aborted / unmatched / blackbox_out / unread **0**；
dont_verify / elab147 / relaxed_appvars 空；黑盒 92 对象（allow 逐条）。
verdict：31 个 green child 证书全部 current-valid 时 SUCCEEDED；CtrlBlock / ExuBlock 阻塞未解时 PARTIAL（`assembly_green_child_*`）。

## 对账
