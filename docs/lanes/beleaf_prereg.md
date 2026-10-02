# beleaf lane（agent/beleaf）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `d5564588`（main，`git worktree add /home/eda/xs-env/wt-beleaf -b agent/beleaf main`） |
| 工作树 | `/home/eda/xs-env/wt-beleaf`，分支 `agent/beleaf` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | VMask → Permutation（含 child slideupVs2VdTable / slidednVs2VdTable）→ Og2ForVector → TopDownMonitor |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |
| codex/kimi 冲突 | 第 0 步已查：outbox 最新 codex_0205（RoundingUnit*/Arbiter*/result-control 7）、claude_0204 第 6 批认领表（beleaf = 本 lane 四目标）、kimi k3next30 清单；26 个 codex/* 分支相对 main 的 diff 均未触及四个目标及 slide*Vs2VdTable |
| Chisel 源 | yunsuan@9559211（= XiangShan b36a1a2a5 的 submodule 指针，工作树 clean）；coupledL2@fb546983；XiangShan `src/main/scala` |

## 1. VMask（golden 2,959 行，0 child）

### 1.1 结构

- `rtl/backend/VMask.sv`：`vmask_pkg`（7 个 opcode 常量）+ 手写核 `xs_VMask_core`
  （§1 stage0 译码/有效掩码 vs2m/本 uop 元素范围；§2 stage1 sbf·sif·sof·first 与前缀 popcount，写 vd_reg；
  §3 stage2 按 vstart/vl/v0/ma/ta 拼输出）+ 手写 wrapper（16 个端口，不需生成器）。
- 寄存器按 Scala 名一一对应（s1 打拍 22 个、vd_reg、s2 打拍 18 个），vs2m_reg_s1 用 128 位向量；
  复位域照 golden：fire_reg_s1 不复位，其余异步复位到 0。
- 无子模块、无黑盒。

### 1.2 UT（verif/ut/VMask；3 seed × 3 initreg × 200k 拍）

逐拍比 io_out_vd（128 位）；opcode 7 个 × SEW 4 档每格 >= 1000 次 fire（写进 PASS 判据），
另有 vstart>=vl / vfirst 无 1 / viota·vid 奇偶 uop / ma / ta 各 >= 1000。结果与变异见文末对账。
复跑：`cd verif/ut/VMask && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/VMask.json）

lane 内非正式试跑（commit 0455f4ad，`make fm-VMask`，vmucp 关）：native SUCCEEDED、passing 1027 / failing 0 /
unmatched 0(0)，Not Compared = Constant reg 1 + Unread 120 → strict PARTIAL。
1148 − 1027 = 121 = 120 + 1，全部可指认：
- Unread 120：全是 matched_nc，`vs1_reg_s1_reg[8..127]` 两侧同名配对。Scala 把 vs1 全宽打拍、只读 [7:0]，
  两侧同一批对称死位 → vmucp（`verif/fm_target_config/VMask.tcl`，本 commit 一并加入，Makefile 开 vmucp）。
- Constant reg 1：`ele_cnt_reg_s1[0]`（16>>vsew 恒偶），两侧都标常量。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| expected（模型） | 1148（regs 1020 + outs 128） |
| passing | **1147** |
| constant_reg | 1 |
| failing / unverified / aborted / unread_notcompared / unmatched | 0 / 0 / 0 / 0 / 0(0) |
| 黑盒 / dont_verify | 无 |
| verdict | SUCCEEDED（signoff-strict） |

### 1.4 可能出错的地方

1. vmucp 打开后若 passing 不是正好 +120，判红（空转或有额外点）。
2. 本节数字来自一次非正式试跑（上文），不是纯模型推算。

## 2. slideupVs2VdTable / slidednVs2VdTable（Permutation 的 child，golden 262 / 365 行，各 0 子模块）

### 2.1 结构

- `rtl/backend/slideupVs2VdTable.sv` / `slidednVs2VdTable.sv`：各一个手写核（把 Scala `compute_vs2_vd`
  的三角编号公式直接写成 always_comb 双/三重循环）+ golden 同名 wrapper。纯组合。
- 关键语义：Scala 用 `TruthTable(..., BitPat.N(n))` —— 缺省值是"全 0"而不是 don't-care，所以 golden 的
  QMC 化简结果在表外输入（uopIdx >= L(L+1)/2）上也是确定的 0；重写件照此输出 0。
- coverage 第 3 列原为 UNPROVEN，本 lane 先签它们，Permutation 再两侧白盒使用。

### 2.2 UT（verif/ut/SlideVs2VdTable；3 seed × 3 initreg × 200k 拍；无寄存器）

每拍一个 src，256 个输入每 256 拍穷举一遍（200k 拍 = 每个输入 781 次）；golden / 重写件 / Scala 公式 oracle 三方比。

### 2.3 跑前预测（★跑完不许改本节★）

lane 内非正式试跑（commit 0c6aecff，`make fm-*`）：两者 native SUCCEEDED，passing 6 / 7。

| 目标 | expected（模型 = 输出位） | passing 预测 | 其余 |
|---|---|---|---|
| slideupVs2VdTable | 6 | **6** | failing/unverified/aborted/unread/unmatched 全 0，无黑盒，无 dont_verify，SUCCEEDED |
| slidednVs2VdTable | 7 | **7** | 同上 |

## 3. Permutation（golden 3,264 行；child = §2 两个查表，两侧白盒）

### 3.1 结构

- `rtl/backend/Permutation.sv`：`permutation_pkg`（8 个 opcode、vcompress 的 uop 分组表）+ 手写核 `xs_Permutation_core`
  （§1 stage0：译码、slide/gather 的 uop 拆分（例化 slideupVs2VdTable / slidednVs2VdTable）、本 uop 剩余 vl/vstart、
  vrgather 字节下标、vcompress 前缀计数；§2 stage1：slide/gather 逐字节取数写 vd_reg、vcompress 压紧、tail/vstart 掩码；
  §3 stage2：vcompress ta 与计数 uop、slide/gather 的 tail/vstart 合成、vstart>=vl 保留 old_vd）+ 手写 wrapper。
- 寄存器按 Scala 名一一对应；复位域逐个照 golden（异步复位组 / 不复位组）；fire_reg0 = GatedValidRegNext。
- 宽 UInt 索引 16 项 Vec 截低 4 位（out_previous_ones_sum、vslide1down 的 vs1/vs2 字节下标）——对 golden 逐条核过。

### 3.2 UT（verif/ut/Permutation；3 seed × 3 initreg × 200k 拍）

逐拍比 io_out_vd；8 opcode × 4 SEW 每格 >= 1000 次 fire，vrgather16_sew8 >= 1000，slide 类 × 8 个 vlmul 各 >= 300，
vcompress 计数 uop >= 300，vstart>=vl >= 1000（写进 PASS 判据）。不复位的 reg1 组在第一次 fire 后 3 拍才开始比。

### 3.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/Permutation.json）

lane 内非正式试跑（commit 932b42bb，vmucp 关）：native SUCCEEDED、passing 3330 / failing 0 / unmatched 0(0)，
Not Compared = Constant reg 14 + Unread 128。3472 − 3330 = 142 = 128 + 14：
- Unread 128（matched_nc，两侧同名）：vmask_uop_reg0[127:16]（112，唯一读者只看 [15:0]）、vs1_next_reg0/reg1[127:120]
  （各 8，输出只取 [119:0]）→ vmucp（`verif/fm_target_config/Permutation.tcl`）。
- Constant 14（两侧都常量）：base_reg0[3:0]、vs2_bytes_min_reg0[3:0]、ele_cnt_reg0[0]、vlmax_bytes_reg0[0]、
  vs2_bytes_max_reg0[0]、out_previous_ones_sum_reg0[7:5]。
- 更早一次试跑（commit 76effcf4）另有 32 个 impl 独占 unread（always_comb 条件分支里的局部变量被 FM 推成 latch：
  hi/lo/vd_first），已在 932b42bb 把它们提到模块级消掉，不是放宽。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| expected（模型） | 3472（regs 3344 + outs 128） |
| passing | **3458** |
| constant_reg | 14 |
| failing / unverified / aborted / unread / unmatched | 0 / 0 / 0 / 0 / 0(0) |
| 黑盒 / dont_verify | 无 |
| verdict | SUCCEEDED（signoff-strict） |

## 4. Og2ForVector（golden 3,182 行，0 child）

### 4.1 结构

- `rtl/backend/Og2ForVector.sv`：`og2forvector_pkg`（payload 头部 3 个字段的位置手写；通道表 NCH/PW/PO/IS_MEM/IMM_CH 生成）+
  手写核 `xs_Og2ForVector_core`（每通道：上一拍 redirect 打拍、needFlush 判定、OG2 valid/payload 打拍、og2Resp；
  ImmInfo 一路）+ 生成的 wrapper（7 个通道 × 每通道 ~80 个字段拼/拆 payload）。
- `scripts/gen_og2forvector.py`（带 `--check`）同时生成 `verif/ut/Og2ForVector/fm_pins_pre.tcl`（golden 10291 个寄存器位
  逐位 set_user_match 到 `u_core/g_ch[k].*`，fail-closed：拒一条或总数 != 10291 即 error）与 tb.sv。
- 7 份"上一拍 redirect"寄存器照 golden 每通道一份（Scala 在通道循环里各调一次 RegNextWithEnable）。

### 4.2 UT（verif/ut/Og2ForVector；3 seed × 3 initreg × 200k 拍）

逐拍比全部 396 个输出端口；每通道 {进 OG2 / 被本拍 redirect 冲掉 / 被上拍 redirect 冲掉 / flushItself 命中 / block}
各 >= 1000（写进 PASS 判据）。robIdx 从 4 值小池子取，保证冲刷各分支都被打到。

### 4.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/Og2ForVector.json）

lane 内非正式试跑（commit 932b42bb）：native SUCCEEDED、passing 20628 / failing 0 / unmatched 0(0)、钉点 ok=10291 bad=0，
无常量、无 unread（signoff-strict 已判 SUCCEEDED）。

| 项 | 预测 |
|---|---|
| expected（模型） | 20628（regs 10291 + outs 10337） |
| passing | **20628** |
| constant_reg / unread | 0 / 0 |
| failing / unverified / aborted / unmatched | 0 / 0 / 0 / 0(0) |
| 钉点 | OG2_PIN_END ok=10291 bad=0 |
| verdict | SUCCEEDED（signoff-strict，不需要 vmucp） |

## 5. TopDownMonitor（golden 3,760 行，0 child，纯组合）

### 5.1 结构

- `rtl/l2/TopDownMonitor.sv`：手写核 `xs_TopDownMonitor_core`（ROB 头 64 B 块地址 vs 4 bank × 16 MSHR 的 {reqTag, set, bank}，
  valid & is_miss & robHeadPaddr.valid，取或）+ `scripts/gen_topdownmonitor.py`（带 `--check`）生成的 wrapper 与 tb。
- golden 692 个端口里只有 64×4 个 MSHR 字段 + robHeadPaddr 进逻辑；其余（dirResult/msAlloc/hitPfInMSHR/pfSent/pfLateInMSHR、
  msStatus 的 channel/is_prefetch）只喂 XSPerf* 计数器，本配置下不生成硬件（golden 0 寄存器、3000 行死线），重写件不连。
- golden 3760 行里绝大多数是这些计数器留下的无负载 popcount 死线；功能只有一个 1 位输出。

### 5.2 UT（verif/ut/TopDownMonitor；3 seed × 3 initreg × 200k 拍；无寄存器）

四种激励形状轮换（全随机 / 定向构造块地址相等 / bank 号错位 / reqTag 高 12 位非 0——golden 位宽怪癖：永不命中）；
命中 >= 20000 拍且 64 个 (bank, mshr) 各作为命中者 >= 100 次（写进 PASS 判据）。

### 5.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/TopDownMonitor.json）

lane 内非正式试跑（commit 285d6f41）：native SUCCEEDED、passing 1、其余全 0。

| 项 | 预测 |
|---|---|
| expected（模型） | 1（regs 0 + outs 1） |
| passing | **1** |
| failing / unverified / aborted / unread / unmatched / 黑盒 / dont_verify | 全 0 / 无 |
| verdict | SUCCEEDED（signoff-strict） |
