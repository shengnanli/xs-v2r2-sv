# lsq lane（agent/lsq）—— 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `b083c53d`（main，`git worktree add /home/eda/xs-env/wt-lsq -b agent/lsq main`） |
| 工作树 | `/home/eda/xs-env/wt-lsq`，分支 `agent/lsq` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `LoadQueue`（golden 8,336 行 / 2,442 端口）→ `LsqWrapper`（golden 10,584 行 / 3,119 端口） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无黑盒 |
| codex 冲突 | 第 0 步查过 outbox 最新 0197（Pmpaddr/Pmaaddr/ShiftRightJam/RightShift 共 50 个）与 18 个 codex/* 分支相对 main 的改动：均不含本 lane 目标及其子孙 |

### 0.1 child 状态核实（规范 §1）

`docs/coverage_three_axis.tsv` 第 3 列：LoadQueueRAR / LoadQueueRAW / LoadQueueReplay / VirtualLoadQueue /
StoreQueue 及其全部子孙 = `PROVEN_DIRECT`。**LoadQueueUncache、LqExceptionBuffer、PipelineRegModule/_1/_2
在该表里仍是 `MISSING/UNPROVEN`**——表没有随 lquncache2 lane 的合入重算（`rewrite_coverage.proven_modules()`
只读 `docs/fm_round_*.tsv` / fastlane 台账，而这几个目标的结果还没进台账）。它们的签核证据直接核 receipt：

| 目标 | receipt | verdict | impl_closure sha 对当前字节 |
|---|---|---|---|
| LoadQueueUncache | `evidence/ff3b73fa4b35/LoadQueueUncache/receipt.json` | SUCCEEDED（passing 43321） | 25/25 一致 |
| LqExceptionBuffer | `evidence/e268a54e29da/LqExceptionBuffer/receipt.json` | SUCCEEDED（passing 1267） | 1/1 一致 |
| PipelineRegModule / _1 / _2 | `evidence/48fbfd801873/*/receipt.json` | SUCCEEDED | 3/3 一致 |

`rewrite_coverage.stale_impl_targets()` = `set()`（没有 child receipt 因 main 前进而过期）。

## 1. 结构与子模块处置

### 1.1 LoadQueue

- 可读核 `rtl/memblock/LoadQueue.sv`：`xs_LoadQueue_core`（手写：§1 异常缓冲 5 个入口 / uncache 缓冲 3 个入口的
  valid 过滤；§2 27 个性能事件 = 17 个子队列计数透传 + full_mask 8 种组合 + nuke/nack rollback，两拍不复位打出）
  + golden 同名 wrapper（GENERATED）。
- 6 个直接 child 全部两侧白盒：ref 读 golden 整棵子树（47 个文件），impl 读重写件整棵子树（53 个文件）。无黑盒。
- 生成器 `scripts/gen_lsq.py --check`（已登记 gate_all）：每个子模块端口恰好命中一条连线规则（接本层端口 /
  接兄弟的输出线 / GLUE_IN 表，表里逐字记 golden 表达式、空白归一后比对）；本层每个输出恰被驱动一次；
  本层输入除 `io_tlbReplayDelayCycleCtrl_0..3`（golden 里也无人读，生成期核对它们在 golden 里只出现在端口表）
  外都被用到。
- 钉点 `verif/ut/LoadQueue/fm_pins_pre.tcl`（生成）：本层胶水 224 位 + 5 个子队列签核时的钉点原样收割
  （tclsh 里桩执行子文件、逐对记名，前缀 `<子模块>/` 换成 `<实例名>/`）：RAR 1741 / RAW 4196 / Replay 6290 /
  exceptionBuffer 1136 / uncacheBuffer 11364，合计 **24951**，fail-closed。VirtualLoadQueue 当年自动配对，不钉。

### 1.2 LsqWrapper

- 可读核 `rtl/memblock/LsqWrapper.sv`：`lsqwrapper_pkg` + `xs_LsqWrapper_core`（手写：§1 入队拆分；§2 TLB
  重放延迟常数 {14,0,125,0}；§3 uncache 仲裁状态机 s_idle/s_load/s_store 与 robIdx 更老者优先；§4 异常地址按
  上一拍 isStore 选择，5 份 RegNext 照 golden；§5 35 个性能事件两拍）+ golden 同名 wrapper（GENERATED）。
- 直接 child：loadQueue（本 lane §1.1）、storeQueue（PROVEN_DIRECT，evidence/833cdc83077f），两侧白盒，无黑盒。
- 钉点 `verif/ut/LsqWrapper/fm_pins_pre.tcl`：本层胶水 427 位 + loadQueue 子树（= LoadQueue 那份 24951，
  加前缀 `loadQueue/`）+ storeQueue 签核钉点 60795，合计 **86173**。

## 2. UT（commit 526a006e 起的字节；tb 生成区由 gen_lsq.py 维护）

- 双例化：golden `<T>` 整棵子树 vs `<T>_xs` 整棵重写子树（derive_ut_impl 统一改名），逐拍逐位比全部输出
  （LoadQueue 1427 口 / 11364 位，LsqWrapper 1696 口 / 14682 位）。
- 激励：全输入每拍随机；*_valid 30%/10%（快/慢相每 4000 拍切换）、*_ready 85%/15%、redirect 1% 且指向最近
  24 条内；地址 60% 取自 4 地址小池；指针/编号 70% 落在 0..7；异常位 3%、重放原因位 5%；load 回写的 robIdx
  按程序序唯一递增、mmio/nc 互斥、ROB pendingPtr 取最近 0..7 条之一（避开 LoadQueueUncache 已知的 golden 自身
  死锁形状）；每 10000 拍一次 3 拍复位。
- 比较口径：`+vcs+initreg+0`（及 seed 1 × random，实测退化为全 1）→ 从第一拍起全比；其余随机初值档 → 每口
  两侧首次相等后上膛再比、`*_bits_*` 另按 golden 同组 valid 限定（报告逐个列出从未上膛的端口）。
- 冒烟（跑前）：LoadQueue seed1×initreg0×20k：checks=20000 errors=0；seed7×random×20k：errors=0，
  输出位从未翻转 2285 / 11364。LsqWrapper seed1×initreg0×20k（旧激励）：errors=0。
- 全矩阵（3 seed × {0, random, <seed>017} × 200k，串行）与 mutant 自检在 FM 跑的同时进行，结果记入文末对账。

## 3. FM 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/LoadQueue.json、LsqWrapper.json）

两段式（与 LoadQueueUncache / StoreQueue 同法）：**run A** vmucp 关 → 量出 unread 集合；**run B** 按 vmucp
standing rule 六条加 `verif/fm_target_config/<T>.tcl` 后重跑。

| 目标 | fm_predict 模型 | run A 预期 | run B 预期 |
|---|---|---|---|
| LoadQueue | **179568**（闭包寄存器 168204 + 顶层 output 11364） | native SUCCEEDED、strict PARTIAL（仅因 unread）；passing = 179568 − constant_reg − unread | SUCCEEDED；passing = 179568 − constant_reg（= A + unread，一个不多一个不少） |
| LsqWrapper | **256622**（241940 + 14682） | 同上 | 同上 |

两跑都要：failing 0 / unverified 0 / aborted 0 / unmatched 六项 0 / 无黑盒 / dont_verify [] / elab147 [] /
relaxed_appvars []。

差额的预期构成（须由 receipt 的 constant_reg / unread 逐位指认，否则判红）：
- unread（run A）≥ 子队列各自签核时的对称死位之和：RAR 6 + RAW 48 + exceptionBuffer 1 + uncacheBuffer 5 +
  Replay 177 = **237**（LoadQueue）；LsqWrapper 再加 StoreQueue 41 = **278**。另可能多出 Replay 子孙
  （LqVAddrModule / FreeList_5 / AgeDetector_38）里的死位 —— Replay 当年把它们黑盒，死位从没被量过；
  若出现，逐个列出并核对双射。
- constant_reg：子队列签核时 RAR 216 + RAW 96 + uncacheBuffer 1616 = 1928（LoadQueue 下限）；Replay 当年
  设了 `verification_assume_reg_init none`（Auto 时多 147 个 Constant reg），本 lane **不设任何 appvar**，
  所以 Replay 子树可能再多 ≤147；StoreQueue 1。

### 3.1 明写可能出错的地方

1. 规模：LoadQueue 闭包 ~17 万比较点、LsqWrapper ~25 万，FM 可能很慢；3 小时不收敛按 30 分钟采样，
   减速即停、取 unmatched 诊断。
2. StoreQueue / LoadQueueReplay / VirtualLoadQueue 当年是 `merge_dup=true` 签的，本 lane 用 false：
   合并掉的重复寄存器现在要逐个配对，可能冒出 unmatched（它们的钉点是在 merge=true 下从 unmatched 清单生成的）。
3. 收割来的钉点是子队列单独签核时的名字；父层里 ref/impl 名字只多一层实例前缀，理论上逐条命中；若有被拒，
   fail-closed 整跑报错。
4. Replay 子树的 `verification_set_undriven_signals BINARY` 当年是为黑盒 FreeList_5 边界的未驱动网线设的；
   白盒后该机制不存在，本 lane 不设。若出现 Und 类 unmatched，停下诊断，不补 appvar。
5. 本节没有做过任何 FM 试跑。
