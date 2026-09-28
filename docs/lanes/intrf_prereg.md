# IntRegFilePart lane（agent/intrf）—— 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `9f15cac9`（main，`git worktree add /home/eda/xs-env/wt-intrf -b agent/intrf main`） |
| 工作树 | `/home/eda/xs-env/wt-intrf`，分支 `agent/intrf` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `IntRegFilePart0` / `IntRegFilePart1` / `IntRegFilePart2` / `IntRegFilePart3` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无 vmucp |
| codex 冲突 | 查过（outbox 最近 20 条 + 15 个 `codex/*` 分支 diff 里无 RegFile 路径）：无 |

## 1. 结构与子模块处置

- golden 四个文件各 7,012 行，**逐行相同，只差第 87 行模块名**（`scripts/gen_intregfile.py` 生成时逐行核对，
  差一行即失败；负测：改 Part2 一行 ⇒ 生成器报"224 行不同"拒绝）。四片的差异只在上层接哪 16 位，本模块内看不见。
- golden 0 个子模块例化（自包含叶子）⇒ 无 child、无黑盒、无 `FM_REF_DEPS_*`。
- 可读核 `rtl/backend/xs_IntRegFilePart_core.sv`（手写）：§1 写（8 口 × 223 行 one-hot 命中 + Mux1H **按位或**）、
  §2 读（11 口，地址打一拍 `raddr_q`，下一拍组合查表）、§3 256 项读视图（[0] 与 [224..255] 常零）、§4 debug 直出。
  寄存器阵列 `mem[1:223]`（没有 0 号，与 golden 没有 `mem_0` 一致）。
- 四个 wrapper `rtl/backend/IntRegFilePart{0..3}.sv` 整文件由生成器产出（端口表逐字取 golden）；
  生成器同时核对：寄存器表恰为 {mem_1..223 ×16, io_readPorts_<r>_data_REG ×8}、写数据是 Mux1H 按位或形状（非嵌套三目）、
  命中常数 == 行号、读出 = `_GEN_0[打拍地址]`、`_GEN_0` = {32 个常零, mem_223..mem_1, 0}、debug_i = mem_i。
  每条核对都做过一次负测（改 golden 副本一处 ⇒ 生成器报对应错误）。
- FM「匹配前」钉点 `verif/ut/IntRegFilePart/fm_pins_pre.tcl`（生成器产出）：
  `mem_<k>_reg[b]` ↔ `u_core/mem_reg[k][b]`（223×16）+ `io_readPorts_<r>_data_REG_reg[b]` ↔ `u_core/raddr_q_reg[r][b]`（11×8），
  逐条数 `set_user_match` 返回值，拒一条或总数 != 3656 即 error。只消名差，不约束 ref。
  ★本 lane 在登记前**没有做过任何 FM 试跑**（非正式试跑也没有）★，钉点路径名是按本仓既有惯例（`<arr>_reg[i][b]`）推的，
  若 FM 对非零起始下标的非打包数组命名不同，钉点会 error（fail-closed），届时修钉点重跑，本节数字不改。

## 2. UT（verif/ut/IntRegFilePart；4 对双例化，3 seed × 3 档 × 200k 拍）

- 比对两层：golden vs 重写（11 读口 + 223 debug，4 对，每拍 936 个比较）；golden vs tb 影子模型（钉死 Mux1H 或、x0/越界 0、读延迟 1 拍）。
- 不复位寄存器门控：`INITREG=0` 档传 `+cmp_all` 全比；random / `<seed>017` 两档只比写过的行与已驱动过的读地址寄存器。
- 激励：x0 4%、越界 6%、热点地址 30%；约 10% 的拍强制 2~3 个写口同址；约 20% 的读口读本拍正在写的地址；
  写使能率每 5000 拍在 15/50/90% 间切换。
- 负测 `mutants.py`（scratchpad 副本，5k 拍，`+vcs+initreg+7017`）：9/9 被抓 ——
  M1 同址多写改后口覆盖 136610、M2 读不打拍 211074、M3 加同拍旁路 32087、M4 越界读回绕 12870、M5 x0 读 mem[1] 8860、
  M6 漏最后一个写口 605266、M7 Part2 debug_5 接错 4809、M8 Part3 读口 9/10 地址对调 9511、M9 行 223 不看 wen 2474。
  （首版 tb 在 negedge 先比后驱动，M2 漏抓 —— 比对时刻打拍地址与当拍地址恰好相等；已改为驱动后 #1 再比，才抓到。）
- 结果见 §对账（跑完追加）。

复跑：`cd verif/ut/IntRegFilePart && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`；`make mutants`；`make gencheck`。

## 3. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/IntRegFilePart{0..3}.json）

模型：expected = golden 寄存器位 3656（223×16 + 11×8）+ 顶层 output 位 3744（11×16 + 223×16）= **7400**，
`FM_MERGE_DUP=false` 模型适用。四个目标相同。

| 项 | 预测（每个目标，正式 run_proof） |
|---|---|
| passing | **7400** |
| failing / unverified / aborted | 0 / 0 / 0 |
| unmatched | 0(0) |
| unread（含 matched_nc） | 0 —— 每个 mem 位都直出到 debug 端口，读地址寄存器 8 位全部参与 256 项查表 |
| constant_reg | 0 |
| 黑盒 / dont_verify | 无 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

## 4. 明写可能出错的地方

1. 钉点路径名（见 §1 末条）。
2. `reset` 两侧都无负载：预期为 unread 输入端口而非比较点，不计入模型；若 FM 把它报成 unread 点并判 PARTIAL，按实测处理、不改本节。
3. 若 passing 少了 16 的整倍数，先查 debug 输出/ mem 行的配对，而不是改 RTL。
