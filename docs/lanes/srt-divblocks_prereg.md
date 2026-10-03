# srt-divblocks lane（agent/srt-divblocks）—— 跑前登记

本文件在 **FM 起跑之前**提交 §0–§4；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `10f9c48d`（main `3de72b25` + 认领 commit），实现 commit `1c8c99ad` |
| 工作树 | `/home/eda/xs-env/wt-srt-divblocks`，分支 `agent/srt-divblocks` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `SelBlock_v4`、`SpecBlock_v4` → `IterBlock_v4` / `IterBlock_v4_4` / `IterBlock_v4_6`；`I8DivNr4` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（fm_predict 模型严格适用），allowlist 空，无 dont_verify，无黑盒 |
| 冲突核查 | codex outbox 最近 5 条与 26 个 `codex/*` 分支 `diff main...` 均无本 lane 目标/child；全部 worktree 的 `*_claim.md`/`*_prereg.md` 精确名只命中 kimi `k3next30_prereg.md`（已于 2026-10-03 释放回池，无半成品 RTL）与本 lane claim；全部分支 rtl 改动无同名文件 |
| Scala | `XiangShan/yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala`（SelBlock_v4 / SpecBlock_v4 / IterBlock_v4）、`I8DivNr4.scala` |

## 1. 结构与子模块处置

| 目标 | golden 行 | impl 行（文件） | `_GEN_`/`_T_` | golden 子模块 → impl |
|---|---:|---:|---:|---|
| SelBlock_v4 | 190 | 196（`rtl/backend/SelBlock_v4.sv`） | 0 | CSA3_2_3988 ×4、SignDec ×1 |
| SpecBlock_v4 | 500 | 372（`rtl/backend/SpecBlock_v4.sv`） | 0 | CSA3_2_3992 ×24、SignDec ×5 |
| IterBlock_v4 | 459 | 677（`rtl/backend/IterBlock_v4.sv`，含家族核） | 0 | SelBlock_v4、SpecBlock_v4、CSA3_2_3987 ×2、CSA3_2_4017、Conversion ×2 |
| IterBlock_v4_4 | 459 | 362（薄 wrapper，BIT_WIDTH=32） | 0 | 同上，CSA3_2_4111 ×2、Conversion_8 ×2 |
| IterBlock_v4_6 | 459 | 362（薄 wrapper，BIT_WIDTH=64） | 0 | 同上，CSA3_2_4173 ×2、Conversion_12 ×2 |
| I8DivNr4 | 246 | 221（`rtl/backend/I8DivNr4.sv`） | 0 | IterBlockI8Nr4 ×1 |

- 子模块 CSA3_2_{3987,3988,3992,4017,4111,4173}、SignDec、Conversion{,_8,_12}、IterBlockI8Nr4 在
  `docs/coverage_three_axis.tsv` 均为 `PROVEN_DIRECT` ⇒ **两侧白盒**：ref 用 golden 同名件，impl 用本仓重写件。
  IterBlock 的 SelBlock_v4 / SpecBlock_v4 两个 child 是本 lane 目标，同样两侧白盒（ref golden、impl 本 lane 重写件）。
- 核全部手写；SelBlock/SpecBlock/IterBlock 的 golden 同名 wrapper 与 IterBlock 核里 selB/specB 的扁平端口连线由
  `scripts/gen_srt_divblocks.py` 生成（fail-closed：每个 golden 端口恰好命中一条形状规则、核数组每个元素恰好被覆盖，
  或列在 TIE0；带 `--check`）。IterBlock 家族：一个参数化核 `xs_IterBlock_v4_core #(BIT_WIDTH)`，按位宽 generate
  选子模块编号；golden 优化掉的 `io_iter_cons_2` / `io_spec_r2ud_2`（q=0 时 −0·d，父级恒连 0）在 wrapper 接 0。
- I8DivNr4 寄存器字段集合逐字照搬 golden（`const_d_reg` 四档 10 位、`stateReg` 6 位），只有 stateReg 异步复位。
- 本 lane 无 `fm_pins*.tcl`、无 `verif/allow`、无 `verif/dead_ref` 声明。

## 2. SRT 原理与位宽（学习用摘要，详见各文件头）

- radix-16 = 每拍两个 radix-4 商位 q1、q2，商位集 {-2..+2}（最小冗余 ρ=2/3），独热编码第 i 位 = 商位 2−i。
- **商位选择（SelBlock）**：上一拍留下的 4 对 carry-save 比较值（估计 − 阈值 m_k），本拍各做一次 8 位进位加法取符号，
  4 个符号（温度计码）经 SignDec 译出 q1；同时用 q2 选比较常数，为下一拍准备新的 4 对（3+5 位格式）。
- **投机余数（SpecBlock）**：q2 依赖 q1，串起来太慢 ⇒ 上一拍就对 q1 的 5 种可能各算 4 对比较值（3+6 位格式），
  本拍 5 个 SignDec 并行出候选 q2，等 q1 到再独热一选；同时为下一拍对 5 种可能再各备一套（20 对）。
- **迭代合成（IterBlock）**：余数宽 W = BIT_WIDTH+6（1 符号 + 2 移位余量 + 3 对齐），carry-save 两步更新
  w1 = 4w + (−q1·d)、w2 = 4·w1 + (−q2·d)，出口 ×4；另从 4w 截 11 位（3+8）+ (−16·q1·d) 截断过一级 11 位 CSA，
  得到 16·w1 的短估计，高 8 位喂 SelBlock、低 9 位喂 SpecBlock；商用两级 on-the-fly conversion（A=Q、B=Q−1）。
- **I8DivNr4**：8 位不用 SRT，非恢复余数法 radix-4（每拍 2 位、4 拍），PRE 取绝对值/特殊情况/预存 {−3d,−d,+d,+3d}，
  POST 负余数 +d 修正、按符号取补。

## 3. UT

UT 与 FM 在**同一份 RTL 字节**（实现 commit `1c8c99ad`）上跑；本登记提交时 UT 九档仍在后台串行跑，
读数与覆盖在文末 §6 追加（追加不改本节）。已知的 20k 拍试跑（seed 1 / initreg 0）：块级 4.12M 次比对 0 错，
三条系统车道共 2908 次 oracle 对照 0 错（只因每车道 ops_done<1000 的下限判 FAILED，属拍数不足，非错误）。
- `verif/ut/SRT16IterBlocks`：(A) 五块各自 golden vs `_xs` 每拍随机全输入比全输出；(B) golden SRT16Divint{,_4,_6} vs
  「同一 golden 父级、IterBlock 子树换成重写件」对拍 + 独立 RISC-V 除法 oracle（除零/负数/最小值÷-1/各 SEW）。
- `verif/ut/I8DivNr4`：golden vs `_xs` 对拍 + 同一 oracle（SEW=8）。
- 档位：seed 1/7/42 × `+vcs+initreg+0` / `+vcs+initreg+random` / `+vcs+initreg+<seed>017`，各 200k 拍，seed 串行。

## 4. 跑前预测（★跑完不许改本节★，登记 `docs/fm_predictions/<T>.json`）

模型 = golden 闭包寄存器位 + 顶层 output 位（`FM_MERGE_DUP=false`）。

| 目标 | expected | 预测 passing | 其余 |
|---|---:|---:|---|
| SelBlock_v4 | 69 | **69** | 纯组合；failing/unverified/unmatched/unread/黑盒全 0；SUCCEEDED |
| SpecBlock_v4 | 365 | **365** | 同上 |
| IterBlock_v4 | 500 | **500** | 同上 |
| IterBlock_v4_4 | 564 | **564** | 同上 |
| IterBlock_v4_6 | 692 | **692** | 同上 |
| I8DivNr4 | 111 | **104–106**（见下） | failing 0；unread 2–3 ⇒ 不开 vmucp 时 strict 判 PARTIAL |

I8DivNr4 差额模型（预期全部落在 constant_reg + unread 上）：
- 恒 0 寄存器位：`const_d_reg_1[9]`、`const_d_reg_2[9]`、`const_d_reg_2[8]`（3 位）；`stateReg[5]`（复位 0、每个写入分支都写 0、
  否则保持）若被 FM 判常量则为第 4 位。
- golden 无读者的位：`const_d_reg_0[9]`（−3d 的第 10 位）、`const_d_reg_3[9]`（+3d 的第 10 位）——两侧都照存、都不读，
  对称死位；`stateReg[5]` 若不判常量则为第 3 个 unread。
- 因此计划两跑：**基线跑**（在工作树 `make fm-I8DivNr4 FM_MODE=diagnostic-full`，不进 evidence、不签核；不开 vmucp，预期 SUCCEEDED + unread 2–3 ⇒ 若按 strict 判为 PARTIAL，reason=unread）→ 按 vmucp standing
  rule 六条建 `verif/fm_target_config/I8DivNr4.tcl`（精确绑定/双射/passing 正好增 unread 数/全零/无 dont_verify 无新黑盒/摘要），
  在第二跑前把复核判据补登到本文件 §5，再跑签核跑。若 unread 点 unmatched（数组名 vs golden 平铺名），先用 fm_pins_pre.tcl 钉成对再开 vmucp。

### 4.1 明写可能出错的地方

1. 纯组合目标的恒 0 输出位（carry 左移补的 0、nxt_iterB 低 2/3 位）是否计入 passing：本登记按"计入"预测；
   若 FM 把它们记为别的类别，差额应正好等于这些位数（SelBlock 4、SpecBlock 20、IterBlock 每变体 4+5+... 逐项指认）。
2. IterBlock 核里 specB 的 `q_j` 接自己的 `q_j_2` 输出（golden 同此接法，非组合环）；若 FM 报 loop，即属此处。
3. I8DivNr4 的 `const_d_reg[0:3]` 数组名与 golden 平铺 `const_d_reg_0..3` 的配对靠 FM 名字匹配；若 unmatched，属命名而非逻辑。
4. 本节之前**没有做过任何 FM 试跑**（含诊断跑）。

## 5. I8DivNr4 补登（签核跑之前提交；§4 的数字不改）

基线诊断跑（`make fm-I8DivNr4 FM_MODE=diagnostic-full`，commit `a5e76872`，不进 evidence）：
native SUCCEEDED / passing **106** / failing 0 / unmatched compare 0 / constant reg **1** / unread **4**（4(4) unmatched）。
对 §4 预测（104–106，unread 2–3）：passing 落在区间上沿；**unread 4 超出预测 2–3**——`const_d_reg_1[9]`、`const_d_reg_2[9]`
我预测 FM 会判常量，实际 FM 不对无读者的寄存器做常量归类，它们和 `const_d_reg_0[9]`/`const_d_reg_3[9]` 一样记作 unread；
被判常量的 1 位不是这两位（`stateReg[5]` 或 `const_d_reg_2[8]` 之一，未单独指认）。106 + 1 + 4 = 111 = expected，差额全部指认。
4 个 unread 是 unmatched（golden 平铺 `const_d_reg_<k>_reg[9]` vs 核数组 `u_core/const_d_reg_reg[<k>][9]`），故：
1. `verif/ut/I8DivNr4/fm_pins_pre.tcl`：4 对 set_user_match（返回值计数、字面守卫 4、error 中止）——诊断跑 4/4 pinned，
   4 对全部转为 matched-unread，unmatched 各项 0；
2. `verif/fm_target_config/I8DivNr4.tcl`（`fm_target_vmucp_allow`）+ Makefile `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true`
   ——诊断跑 passing 110 / unread 0 / constant reg 1。

**签核跑复核判据**（`bash scripts/run_proof.sh I8DivNr4 I8DivNr4`）：verdict SUCCEEDED，passing **110**（= 106 + 4），failing 0，
unread 0，unmatched 全 0，constant_reg 1，blackbox 0，dont_verify false，fm.log 含 `I8DIVNR4_PINS: dead const_d_reg_k[9] 4 / 4 points pinned`。
fm_predict 对账：expected 111 − actual 110 = 1 = constant_reg 1 + unread 0。

## 6. 对账（跑完追加）

### 6.1 UT（RTL 字节 = `1c8c99ad`；九档串行，每档 200k 拍，全部 TEST PASSED）

| UT | seed | initreg 0 / random / <seed>017 | 每档读数 |
|---|---|---|---|
| SRT16IterBlocks | 1 | PASS / PASS / PASS（1017） | 块级 41,200,000 次比对 0 错；车道 oracle 28,756 次 0 错 |
| SRT16IterBlocks | 7 | PASS / PASS / PASS（7017） | 41,200,000 / 28,369，0 错 |
| SRT16IterBlocks | 42 | PASS / PASS / PASS（42017） | 41,200,000 / 29,033，0 错 |
| I8DivNr4 | 1 | PASS / PASS / PASS | 对拍 199,996 拍 / oracle 10,105 次，0 错 |
| I8DivNr4 | 7 | PASS / PASS / PASS | 199,996 / 9,937，0 错 |
| I8DivNr4 | 42 | PASS / PASS / PASS | 199,996 / 10,062，0 错 |

同一 seed 下三档读数逐字相同：车道只在 valid 时比商/余数，而所有在 valid 之前被读的寄存器都先被 PRE 态写定，
上电初值不可观测——三档全绿在这里**证明不了复位域**，复位域由 FM（stateReg 异步复位、其余无复位，逐寄存器配对比较）把关。
覆盖（seed 1 / initreg 0）：块级 golden q1 出 +2/+1/0/-1/-2 = 34563/21725/43830/22110/33998（另多热 43774），q2 含全 0 13612；
车道 SRT16Divint sew0/1 = 4849/4812，_4 sew0/1/2 = 3179/3074/3142，_6 sew0..3 = 2395/2375/2500/2430；
每车道除零 ~700–780、x=0 ~710–760、最小值÷-1 221–238、负被除数 ~2000、负除数 ~2000、余数非零 ~7000、|x|<|d| ~4400；
I8DivNr4 除零 737 / 最小值÷-1 192 / 有符号 5095。复跑：`cd verif/ut/<SRT16IterBlocks|I8DivNr4> && make run SEED=<s> INITREG=<0|random|<s>017>`。

### 6.2 变异自检（scratch 沙箱，seed 1 / 20k 拍，不进库）

16 个变异体 14 个 CAUGHT。SRT 块 10/10：M1（Sel Mux1H 改优先级）与 M5（Spec 末级 Mux1H 改覆盖）**只被块级多热激励抓到**，
系统车道 0 错（真实运行里商位总是独热）——这正是块级随机激励存在的理由。I8DivNr4 6 个里 2 个 MISSED：
- M11 去掉 `rem_adjust` 的 `~early_finish_q`：可达状态里提前结束时 `iter_w_reg[8]` 恒为 0（PRE 写 `{1'b0, …}` 后直达 POST），
  UT 结构上看不见；FM 对寄存器做自由状态比较，`early_finish_q=1 ∧ iter_w_reg[8]=1` 下次态不同 ⇒ 由 FM 覆盖。
- M16 `early_finish` 去掉 `x_zero`：x=0 时必有 x_small（|d|>0）或 d_zero，该项在 golden 里逻辑冗余，变异体与原设计**组合等价**，不是漏检。

### 6.3 FM 对账（official，signoff-strict，无黑盒、无 dont_verify、allowlist 空）

| 目标 | 预测 | 实测 passing | failing | unread | unmatched | constant | 差额指认 | receipt |
|---|---:|---:|---:|---:|---:|---:|---|---|
| SelBlock_v4 | 69 | 69 | 0 | 0 | 0 | 0 | 逐位相等 | `evidence/fa5bddf408ca/SelBlock_v4` |
| SpecBlock_v4 | 365 | 365 | 0 | 0 | 0 | 0 | 逐位相等 | `evidence/fa5bddf408ca/SpecBlock_v4` |
| IterBlock_v4 | 500 | 500 | 0 | 0 | 0 | 0 | 逐位相等 | `evidence/fa5bddf408ca/IterBlock_v4` |
| IterBlock_v4_4 | 564 | 564 | 0 | 0 | 0 | 0 | 逐位相等 | `evidence/fa5bddf408ca/IterBlock_v4_4` |
| IterBlock_v4_6 | 692 | 692 | 0 | 0 | 0 | 0 | 逐位相等 | `evidence/fa5bddf408ca/IterBlock_v4_6` |
| I8DivNr4 | 104–106（§4）/ 110（§5） | 110 | 0 | 0 | 0 | 1 | 111−110 = constant 1 | `evidence/d88649508e8c/I8DivNr4` |

§4.1 风险 1（恒 0 输出位计入 passing）：实测计入，差额 0。风险 2（specB 自环）：未报 loop。风险 3（数组名配对）：活位自动配上，
4 个死位需钉点（§5）。§4 对 I8DivNr4 unread 的预测（2–3）错了——实际 4，原因见 §5。
`python3 scripts/fm_predict.py check <6 个目标>`：全部对上；`python3 scripts/check_lane_receipts.py /home/eda/xs-env/wt-srt-divblocks` rc=0。

### 6.4 父级 child 状态（本 lane 不做父级）

- SRT16Divint：IterBlock_v4（本 lane 签）+ SRT4qdsCons（PROVEN_DIRECT）⇒ child 全绿。
- SRT16Divint_4：IterBlock_v4_4 + SRT4qdsCons ⇒ 全绿。SRT16Divint_6：IterBlock_v4_6 + SRT4qdsCons ⇒ 全绿。
- IterBlock 闭包内的孙级 SelBlock_v4 / SpecBlock_v4（本 lane 签）、CSA3_2_*、SignDec、Conversion*（PROVEN_DIRECT）全绿。
- 本 UT 的系统车道已经把三个 golden 父级各换上重写的 IterBlock 子树跑了 ~9.5k 次/seed 真实除法，可作父级 UT 的起点。
