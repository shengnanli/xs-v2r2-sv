# wbbyp lane（agent/wbbyp）—— 跑前登记（A 部分：WbDataPath 及其 child）

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。B 部分（BypassNetwork / ImmExtractor_2 / _37）
在分支 agent/wbbyp-b 上另记 `docs/lanes/wbbyp_b_prereg.md`。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `4728f823`（main，`git worktree add /home/eda/xs-env/wt-wbbyp -b agent/wbbyp main`） |
| 工作树 | `/home/eda/xs-env/wt-wbbyp`，分支 `agent/wbbyp` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | RealWBCollideChecker / _1 / _2 / _3 / _4（child）→ ByteMaskTailGen / VldMgu / VldMergeUnit（child 链）→ WbDataPath（本体） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| codex 冲突检查 | outbox 最新 codex_0197（50 个 Pmp/Pma/ShiftRightJam 叶子）与各 codex/* 分支 diff：均不含本 lane 目标 |

## 1. RealWBCollideChecker 家族（5 变体，共用核 xs_RealWBCollideChecker_core）

### 1.1 结构与子模块处置

- golden 5 变体都是**纯装配**：把 N 路写回请求按「写口号」分组，每组例化一个
  RealWBArbiter_* 做组内固定优先级仲裁（Scala `WbArbiter.scala` class RealWBCollideChecker）。
- 可读核 `rtl/backend/RealWBCollideChecker.sv`（xs_RealWBCollideChecker_core）：参数 = 分组表
  GROUP[j][k] + 组宽 GROUP_N[j]，组内仲裁直接用共享法则 `rtl/common/xs_PriorityArbSelect.sv`
  （与已签的 RealWBArbiter 家族同一件）。**impl 不例化 RealWBArbiter_\***；ref 侧 golden
  子仲裁器原件进 FM_REF_DEPS（两侧均白盒，FM 比展平后的组合锥），**无黑盒**。
- wrapper（基变体在核文件 GENERATED 区，_1.._4 薄文件）由 `scripts/gen_realwbcc.py` 生成（`--check`
  已登记 gate_all）：端口表照抄 golden；分组表从 golden `arbiters_j` 实例连线逐条读出并断言
  （每路输入恰属一组；组内第 k 名的 wen/pdest/data/ready 都接同一输入；有 ready 端口 ⇔ 组宽 >= 2）。
- 别的域 wen 输入（int 变体的 fpWen ×5、fp 变体的 rfWen ×8）golden 里进了子仲裁器、出口悬空，
  impl 不接（两侧都是无扇出输入，不产生比较点）。

### 1.2 UT（verif/ut/RealWBCollideChecker；五变体同测，commit 1a7f20a4 的字节）

逐拍比 5 变体全部输出（每拍 153 个输出口）。seed × initreg 三档 × 200k 拍：

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=30600000 errors=0 | checks=30600000 errors=0 | (1017) checks=30600000 errors=0 |
| 7  | checks=30600000 errors=0 | checks=30600000 errors=0 | (7017) checks=30600000 errors=0 |
| 42 | checks=30600000 errors=0 | checks=30600000 errors=0 | (42017) checks=30600000 errors=0 |

纯组合、无 clock/reset：三档 initreg 必然同结果，跑它只为钉住「没有隐藏状态」。
覆盖（tb 内判据，未满足即 TEST FAILED）：每一路输入都在自己组里赢过；每个 ready 端口取到过 1，
非组首的取到过 0。seed 1 / 20k 拍的赢次最少的一路（int in9，组内第 4 名）= 738 次。

mutant 自检（seed 7、20k 拍，改 rtl 后跑、git checkout 还原）：
M1 int 组 1 优先级互换 ⇒ errors=27113；M2 组内成员倒序取 ⇒ 166884；
M3 ready 全取组首授权 ⇒ 112731；M4 int 出口 3 的 wen 接成 pdest[0] ⇒ 10086。四个全抓。

复跑：`cd verif/ut/RealWBCollideChecker && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/RealWBCollideChecker*.json）

模型 = golden 闭包寄存器位（0）+ 顶层 output 位：

| 目标 | passing 预测 | 构成 | 其余 |
|---|---|---|---|
| RealWBCollideChecker   | **603** | 8 写口 × (1+1+8+64) + 11 个 ready | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| RealWBCollideChecker_1 | **454** | 6 × (1+1+8+64) + 10 个 ready | 同上 |
| RealWBCollideChecker_2 | **828** | 6 × (1+1+7+128) + 6 个 ready | 同上 |
| RealWBCollideChecker_3 | **816** | 6 × (1+1+5+128) + 6 个 ready | 同上 |
| RealWBCollideChecker_4 | **60**  | 4 × (1+1+5+8) | 同上 |

### 1.4 明写可能出错的地方

1. 核的 `parameter int GROUP [NUM_OUT][MAX_G]`（二维 unpacked int 参数）在 VCS 里过了，
   Formality 读 SV 能否吃下未实测；若 elaborate 报错，改成一维打平表（只改表示，不改电路），重新登记本节以下的「对账」说明。
2. 常数输出（组首 ready 恒 1）预期计入 passing（输出端口本身是比较点）；若 FM 把它们归为
   常量而不计，passing 会比预测少恰好常数 ready 个数（int 4 / fp 5 / vec 3 / v0 3 / vl 0）。
3. 本节没有做过任何 FM 试跑。

## 对账（跑后追加）

### RealWBCollideChecker 家族（证明 commit 1d3825d9，`bash scripts/run_proof.sh RealWBCollideChecker <5 targets> < /dev/null`）

| 目标 | 预测 | 实测 passing | 差 | failing | unverified | unmatched | unread | 黑盒 | dont_verify | native | receipt.json sha256 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RealWBCollideChecker   | 603 | 603 | 0 | 0 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED | a82c21b3d5a0c4bf0506dedb967d9e1e7f293ef6a13a53c8f26a54932d24e9a7 |
| RealWBCollideChecker_1 | 454 | 454 | 0 | 0 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED | e52795ddf1ce0d963ef4562c25e890fc897aad33bd0f58567a278c821488b2d4 |
| RealWBCollideChecker_2 | 828 | 828 | 0 | 0 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED | 17540596bd3cd38e540be173886f2b616a6a97b1e16711b0cb28375b1dd825b1 |
| RealWBCollideChecker_3 | 816 | 816 | 0 | 0 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED | 6794c4d91d83765c292431779e36d00dd4967e38aeadce8c8c6698bce22dc57c |
| RealWBCollideChecker_4 | 60  | 60  | 0 | 0 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED | 40ca7fe0e2c0967dbb7cbe1ed1f31861c38f44be93107bc375db8b9df666ee30 |

`fm_predict.py check` 全部逐位相等（rc=0）。§1.4 的两条风险都没发生：二维 int 参数 FM 照常 elaborate；
常数 ready 计入 passing。receipt：`evidence/1d3825d96fc7/<target>/`。

## 2. 向量 load 合并链：UIntToContLow1s / UIntToContLow0s → ByteMaskTailGen → VldMgu → VldMergeUnit

### 2.1 结构与子模块处置

- 这条链是 WbDataPath 的 child VldMergeUnit（×2）连同其全部未签孙级（盘点：VldMgu / ByteMaskTailGen /
  UIntToContLow0s / UIntToContLow1s 均 MISSING/UNPROVEN；MaskExtractor 已 PROVEN_DIRECT，两侧白盒直接用）。
- UIntToContLow1s/0s：温度计码，dataOut[i] = (i < n) / (i >= n)，255 位，每位一个比较（golden 为 firtool
  展开的 ~475 行嵌套拼接）。
- ByteMaskTailGen：`xs_ByteMaskTailGen_core`，按 Scala 分四步（元素号→字节号、body/tail 段、mask 展开、空区间清零）；
  golden 的 prestart 段（dontTouch 调试线，无读者）不画，少一个 UIntToContLow1s 实例（无比较点）。
- VldMgu：`xs_VldMgu_core`，按字节三选一；子模块 ByteMaskTailGen。
- VldMergeUnit：`vldmergeunit_pkg`（写回字段嵌套结构体 vld_wb_t）+ `xs_VldMergeUnit_core`（needFlush、wbReg 打一拍、
  合并、vlWen 例外）；wrapper 由 `scripts/gen_vldmergeunit.py` 生成（端口→结构体成员按前缀规则映射，单射断言）。
  ★寄存器是一整个 packed struct（1134 位）+ valid★，与 golden 的 97 个逐字段寄存器名字不同。
- 全部无黑盒：ref = golden 本体 + golden 子模块原件；impl = RTL_SRCS 全部重写件。

### 2.2 UT（verif/ut/VldMergeUnit；五对同测，commit 38eef391 的字节）

每拍比五对全部输出（UIntToContLow1s/0s 各 255、ByteMaskTailGen 32、VldMgu 128、VldMergeUnit 97 个端口；
VldMergeUnit 前 5 拍灌 valid 不比）。seed × 三档 initreg × 200k 拍：

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=20399515 errors=0 | checks=20399515 errors=0 | (1017) checks=20399515 errors=0 |
| 7  | checks=20399515 errors=0 | checks=20399515 errors=0 | (7017) checks=20399515 errors=0 |
| 42 | checks=20399515 errors=0 | checks=20399515 errors=0 | (42017) checks=20399515 errors=0 |

覆盖（seed 1 / 200k，tb 判据：active>0、agnostic>0、合并改写了数据>0、被冲刷吃掉>0）：
vstart>=vl 空区间 34189 拍、activeEn 非零 64904、agnosticEn 非零 57002、合并后 data 与原 data 不同 25926、
flush 吃掉 25173、vlWen 旁路 49787。

mutant 自检（seed 7、20k 拍）：M1 Low1s `<`→`<=` ⇒ errors=21232；M2 Low0s `>=`→`>` ⇒ 24100；
M3 ByteMaskTailGen 空区间 `>=`→`>` ⇒ 136；M4 tail agnostic 取 vma ⇒ 6984；M5 VldMgu 0xFF→0x00 ⇒ 9716；
M6 VldMgu 索引访存元素宽互换 ⇒ 12111；M7 needFlush 去掉 level 门控 ⇒ 173；M8 去掉 vlWen 旁路 ⇒ 1380；
M9 ta 去掉 isMasked ⇒ 491。九个全抓。

复跑：`cd verif/ut/VldMergeUnit && make run SEED=<s> INITREG=<0|random|<s>017>`

### 2.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/）

| 目标 | passing 预测 | 构成 | 其余 |
|---|---|---|---|
| UIntToContLow1s | **255**  | 255 输出 | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| UIntToContLow0s | **255**  | 255 输出 | 同上 |
| ByteMaskTailGen | **32**   | 32 输出 | 同上 |
| VldMgu          | **128**  | 128 输出 | 同上 |
| VldMergeUnit    | **2270** | 1135 寄存器位 + 1135 输出位 | 同上 |

### 2.4 明写可能出错的地方

1. VldMergeUnit 的 impl 寄存器是 packed struct（FM 里叫 `u_core/wb_bits_reg[N]`），golden 是逐字段
   `wbReg_bits_<f>_reg`。每个寄存器位都直接驱动一个输出端口，预期 FM 靠签名/拓扑配得上；若 Matching
   卡住或出现 unmatched，改为生成 fm_pins_pre.tcl（逐位一一对应、字面计数），不改电路。
2. golden ByteMaskTailGen 多一个无读者的 UIntToContLow1s 实例（prestart 段）：纯组合、无比较点，预期不影响计数。
3. 本节没有做过任何 FM 试跑。
