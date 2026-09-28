# DataPath lane（agent/datapath）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。盘点见 `docs/lanes/datapath_inventory.md`。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | main `0cbe4f8c`（`git worktree add /home/eda/xs-env/wt-datapath -b agent/datapath main`） |
| 工作树 | `/home/eda/xs-env/wt-datapath`，分支 `agent/datapath` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| RTL commit | `f7fdd6cb`（21 个 child 的重写件 + 两个 UT） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## A. 族 A/B：5 × *RFWBCollideChecker + 5 × *RFReadArbiter（UT = verif/ut/DataPathArb）

### A.1 结构与子模块处置

- 本层只有 WBArbiter 例化 + 常量 ready（NoWB/NoRD 输入）。文件 = 手写文件头 + `scripts/gen_datapath_arb.py`
  从 golden 例化表产出的 GENERATED 区（端口表逐行同 golden，每个例化前注明竞争者与优先级）。
- IntRFReadArbiter 里 golden 有 18 条 XSPerfAccumulate 残留的无负载线网（hasConflict / hasRead0 / hasSameAddr），
  不形成比较点，不写；生成器断言"无负载"。
- 孙级 WBArbiter 13 变体全部 PROVEN_DIRECT：**两侧白盒**（ref golden 同名件，impl `rtl/backend/WBArbiter*.sv` +
  `xs_WBArbiter_core` + `rtl/common/xs_PriorityArbSelect.sv`）。无黑盒。
- **N=1 仲裁器的对称死位**：每个 N=1 WBArbiter 的反饥饿状态 5 位（cancelCounter_0[2:0] / isFull_0 / hasFull）在父层里
  成为 unmatched unread（两侧对称死，依据见 `verif/fm_target_config/<top>.tcl`）。`verif/ut/DataPathArb/fm_pins.tcl`
  五层 fail-closed 配对，再按 vmucp standing rule 开 `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`：
  1. 精确绑定：只接受 `arbiters_<m>/{cancelCounter_0_reg[b], hasFull_reg, isFull_0_reg}` ↔ `arbiters_<m>/u_core/{cancel_cnt_q_reg[0][b], has_full_q_reg, is_full_q_reg[0]}`；
  2. 双射：钉点数 = impl unread 数 = 5 × N=1 个数（每目标字面声明），三类分计数都对；
  3. 真比较：passing 相对"不开 vmucp、不钉"基线增加 = 2 × N=1 个数（hasFull + isFull），其余 3 × N=1 落 Constant reg；
  4. 全零：failing / unverified / aborted / unmatched 全 0；
  5. 无放宽：dont_verify / elab147 / relaxed_appvars 皆空，无黑盒；
  6. 摘要：fm_pins.tcl 与 fm_target_config/<top>.tcl 进 sidecar/script_closure，receipt 记 sha256。

### A.2 UT（两例化逐拍比全部输出；9 档 × 200k 拍，在 commit `f7fdd6cb` 的字节上跑）

激励：请求 valid 按"压力档"（20/50/90/100%，每 1000 拍换档）置 1，addr 全宽随机，约每 25k 拍一次 2 拍异步复位。
覆盖（golden 侧）：conflict = 有请求被拒的拍数；starve = 有仲裁器 hasFull=1 的拍数。
VlRFWBCollideChecker 的 4 个仲裁器全是 N=1，按构造不可能冲突：判据改为"conflict 必须 == 0"。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=200013 errors=0 PASSED | checks=200013 errors=0 PASSED | checks=200013 errors=0 PASSED |
| 7  | checks=200011 errors=0 PASSED | checks=200011 errors=0 PASSED | checks=200011 errors=0 PASSED |
| 42 | checks=200011 errors=0 PASSED | checks=200011 errors=0 PASSED | checks=200011 errors=0 PASSED |

覆盖（seed 1 / initreg 0）：

| 目标 | conflict | starve |
|---|---:|---:|
| IntRFWBCollideChecker | 156915 | 58745 |
| FpRFWBCollideChecker | 141172 | 32387 |
| VfRFWBCollideChecker | 127816 | 22412 |
| V0RFWBCollideChecker | 127956 | 22385 |
| VlRFWBCollideChecker | 0（按构造） | 0（按构造） |
| IntRFReadArbiter | 167935 | 68476 |
| FpRFReadArbiter | 135537 | 28092 |
| VfRFReadArbiter | 161124 | 58922 |
| V0RFReadArbiter | 131541 | 29154 |
| VlRFReadArbiter | 131420 | 28777 |

变异自证（scratchpad 拷贝，20k 拍，不进库）：A1 交换 IntRFWBCollideChecker 写口 0 的两路优先级 ⇒ errors=14404；
A2 一个 NoWB 的常量 ready 1→0 ⇒ errors=19997；A3 IntRFReadArbiter 读口 8 的 addr 接错源 ⇒ errors=19917。三者全抓。

复跑：`cd verif/ut/DataPathArb && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

### A.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`fm_predict.py model`）。N=1 仲裁器的 cancelCounter 三位 FM 判常量。

| 目标 | N=1 个数 | 模型 | passing 预测 | constant_reg 预测 | 钉点 |
|---|---:|---:|---:|---:|---:|
| IntRFWBCollideChecker | 4 | 103 | **91** | 12 | 20 |
| FpRFWBCollideChecker | 1 | 83 | **80** | 3 | 5 |
| VfRFWBCollideChecker | 3 | 75 | **66** | 9 | 15 |
| V0RFWBCollideChecker | 3 | 75 | **66** | 9 | 15 |
| VlRFWBCollideChecker | 4 | 51 | **39** | 12 | 20 |
| IntRFReadArbiter | 3 | 273 | **264** | 9 | 15 |
| FpRFReadArbiter | 7 | 241 | **220** | 21 | 35 |
| VfRFReadArbiter | 6 | 263 | **245** | 18 | 30 |
| V0RFReadArbiter | 2 | 127 | **121** | 6 | 10 |
| VlRFReadArbiter | 2 | 127 | **121** | 6 | 10 |

其余：failing / unverified / aborted / unread / unmatched 全 0，无黑盒，SUCCEEDED（signoff-strict，vmucp 开）。
`fm_predict check` 口径：差额 = constant_reg。

试跑披露（lane 内非正式，未出 receipt，同字节）：VlRFWBCollideChecker 不钉不开 vmucp ⇒ native SUCCEEDED、passing 31、
20(20) unmatched unread；钉 + vmucp ⇒ passing 39、Constant reg 12、unread 0。IntRFReadArbiter 钉 + vmucp ⇒ passing 264、
Constant reg 9、unread 0。其余 8 个目标未试跑，数字纯按模型推。

### A.4 明写可能出错的地方

1. 其余 8 个目标里的 N=1 仲裁器若被 FM 以别的方式处理（例如 3 位里只折叠 1 位），passing 与 constant_reg 会偏离
   上表，但二者之和仍应等于模型；钉点数若不等于 5 × N=1，fm_pins.tcl 会当场 error（不出 receipt）。
2. N≥2 仲裁器的寄存器靠 FM 自动配对（单独签核时就是这样过的）；若出现 unmatched，先查配对再谈别的。

## B. 族 C/D/E：11 个寄存器堆变体（UT = verif/ut/RegfileVariants）

### B.1 结构与子模块处置

- 手写参数化核 `rtl/backend/xs_Regfile_core.sv`；11 个薄 wrapper 由 `scripts/gen_datapath_rf.py` 生成（参数全部从 golden
  实测并断言：项数、读/写口数、位宽、debug 口、读视图越界填 mem_0、0 号项复位）。叶子，无子模块、无黑盒。
- 寄存器命名：核里 `mem[i]`（unpacked）→ FM 名 `u_core/mem_reg[i][b]`，由 fm_eq.tcl 的 auto_match_flattened_arrays 与
  golden `mem_<i>_reg[b]` 配对；读地址寄存器 `read_addr_q[r]` 靠 FM 自动配对。不另设钉点。

### B.2 UT（9 档 × 200k 拍；结果见 §对账 B，本节不写数字）

定向：同拍多写口同址（Mux1H 按位或）、越界地址（Fp/V0）、同拍读写同址、Vl 0 号项异步复位（约每 2k 拍一次复位脉冲）。
暖机 64 拍按顺序写满全部项后才比对（+random / +<n> 档两侧初值不同）。
变异自证（scratchpad 拷贝，20k 拍）：R1 Mux1H 按位或 → 最后一口覆盖 ⇒ errors=628017；R2 越界读填 0 而非 mem[0] ⇒ 268672；
R3 去掉 Vl 0 号项复位 ⇒ 复位脉冲每 20k 拍一次时 **errors=0 漏检**，把 tb 复位频度加密到每 2k 拍后 ⇒ errors=21；
R4 读不打拍 ⇒ 1981901；R5 debug 读口改用打拍地址 ⇒ 19208。

### B.3 跑前预测（★跑完不许改本节★）

| 目标 | 模型（= passing 预测） | 其余 |
|---|---:|---|
| VlRegFile | **316**（32×8 + 4×5 + 输出 40） | 全 0，SUCCEEDED |
| V0RegFilePart0 / Part1 | **3092** 各 | 同上 |
| VfRegFilePart0..3 | **8660** 各 | 同上 |
| FpRegFilePart0..3 | **6408** 各 | 同上 |

试跑披露（lane 内非正式，未出 receipt，同字节）：VlRegFile passing 316、V0RegFilePart0 3092、FpRegFilePart0 6408，
皆 native SUCCEEDED、unmatched 0(0)、无 unread。Vf 与其余 Part 未试跑。

### B.4 明写可能出错的地方

1. Part1..3 与 Part0 golden 逐字相同（仅模块名），预期数字与 Part0 相同；若不同先查 FM 配对。
2. Vf 128 项 × 32 位 × 12 读口是本族最大的读视图多路选择，若 FM 时长显著超过 Fp（试跑 120 秒、931 MB），按规范 30 分钟采样。

## 对账（跑完追加，不改上文任何数字）

### 对账 A：族 A/B（proof commit `833a2017`，evidence/833a201786eb/，signoff-strict，vmucp 开）

| 目标 | passing 预测 → 实测 | constant_reg 预测 → 实测 | 钉点（fm_pins.tcl 日志） | 其余 |
|---|---|---|---|---|
| IntRFWBCollideChecker | 91 → **91** | 12 → 12 | 20（cancelCounter 12 / hasFull 4 / isFull 4） | failing / unmatched / unread 全 0 |
| FpRFWBCollideChecker | 80 → **80** | 3 → 3 | 5 | 同上 |
| VfRFWBCollideChecker | 66 → **66** | 9 → 9 | 15 | 同上 |
| V0RFWBCollideChecker | 66 → **66** | 9 → 9 | 15 | 同上 |
| VlRFWBCollideChecker | 39 → **39** | 12 → 12 | 20 | 同上 |
| IntRFReadArbiter | 264 → **264** | 9 → 9 | 15 | 同上 |
| FpRFReadArbiter | 220 → **220** | 21 → 21 | 35 | 同上 |
| VfRFReadArbiter | 245 → **245** | 18 → 18 | 30 | 同上 |
| V0RFReadArbiter | 121 → **121** | 6 → 6 | 10 | 同上 |
| VlRFReadArbiter | 121 → **121** | 6 → 6 | 10 | 同上 |

全部 native SUCCEEDED，黑盒 0，dont_verify / elab147 / relaxed_appvars 皆空。`fm_predict check` rc=0（差额 = constant_reg，逐个指认）。
与 §A.3 逐项一致，差 +0。

### 对账 B：族 C/D/E（同一 proof commit / 证据目录）

| 目标 | passing 预测 → 实测 | 其余 |
|---|---|---|
| VlRegFile | 316 → **316** | failing / unmatched / unread / constant 全 0 |
| V0RegFilePart0 / 1 | 3092 → **3092** / **3092** | 同上 |
| VfRegFilePart0..3 | 8660 → **8660** ×4 | 同上 |
| FpRegFilePart0..3 | 6408 → **6408** ×4 | 同上 |

全部 native SUCCEEDED，逐位相等（`fm_predict check` rc=0）。FpRegFilePart0 128 s / 931 MB，VfRegFilePart0 128 s / 952 MB。

UT（verif/ut/RegfileVariants，在 `f7fdd6cb` 字节上跑，9 档 × 200k 拍）：

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=200117 errors=0 PASSED | checks=200117 errors=0 PASSED | checks=200117 errors=0 PASSED |
| 7  | checks=200143 errors=0 PASSED | checks=200143 errors=0 PASSED | checks=200143 errors=0 PASSED |
| 42 | checks=200129 errors=0 PASSED | checks=200129 errors=0 PASSED | checks=200129 errors=0 PASSED |

覆盖（seed 1 / initreg 0）：同址多写 samewrite 12862..38155 拍/变体，越界 oob（Fp/V0）66487..82047，同拍读写同址 rawsame 30325..33164。
