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

## C. DataPath 本体（golden 25,618 行 / 2,426 端口；UT = verif/ut/DataPath）

### C.1 结构与子模块处置

- 可读核 `xs_DataPath_core`（rtl/backend/DataPath.sv，手写）：§1 读口仲裁请求 §2 写口撞口请求 §3 og0 能否通过（含 s0_cancel）
  §4 s0→s1 流水寄存器 §5 og0/og1 回告与取消 §6 寄存器堆写/读口（含向量异常借口）§7 og1 选源 §8 RegCache 读口
  §9 向量异常模块读回 §10 性能与 TopDown。27 个 EXU 用同一套逻辑 + `datapath_pkg` 的配置表（生成区，golden 实测）。
- og0→og1 原样打拍的字段拼成 `s1_payload_q`（5,547 位，各 EXU 一段）；字段表、端口拼/拆、62 个子模块例化都在 golden 同名 wrapper
  的生成区（`scripts/gen_datapath.py`，每个 golden 顶层寄存器 / 子模块端口连接 / 输出驱动都必须被一条已知形状解释，否则生成失败）。
- 子模块全部两侧白盒、无黑盒：本 lane 的 21 个 child（evidence/833a201786eb）、WBArbiter 家族 13 变体、RegCache、UIntExtractor_27_* ×2、
  IntRegFilePart0..3（intrf lane 已签核、已随 main 合入本分支 `3d3b68b2`，impl 用重写件——**不再是条件项**）；
  RegCache 的 6 个 GOLDEN_REUSE 子模块两侧同源 golden。
- 钉点 `verif/ut/DataPath/fm_pins_pre.tcl`（生成）：golden 顶层 1,111 个寄存器 / 9,519 位 + 重写子模块内部（寄存器堆 mem / 读地址寄存器、
  WBArbiter 反饥饿状态）共 **57,191** 位逐位 set_user_match；逐条数返回值，拒一条或总数不符即 error。RegCache 内部不钉。

### C.2 golden 自比基线（CONVENTIONS「大件动手前先量自比基线」）

scratchpad 里 golden 闭包 48 个文件逐字拷一份当 impl（`FM_MERGE_DUP=false`，不开 vmucp）：native SUCCEEDED，
passing **137,627**，failing 0，比较点 unmatched 0(0)，Unread 481（全 matched_nc），1160 s。地板 = 0 failing。

### C.3 UT（verif/ut/DataPath；9 档 × 200k 拍，结果见 §对账 C，本节不写数字）

热身 120 拍：写回口全开按顺序写满 5 类寄存器堆全部物理寄存器、RegCache 写口全开，最后 40 拍发射口全开、源全走 RegCache
（RegCache 读地址寄存器只在 ren 时更新且不复位，+vcs+initreg+<n> 档实测不这样做比对开头 3 拍会不一致）。
随机阶段：发射 valid 每 500 拍在 60/20/3% 间换档、dataSources 在 7 种里挑、redirect 5%、ld2Cancel 5%、EXU ready 85%、
向量异常借口 10%、写回 wen 50%、约每 5k 拍一次 2 拍异步复位。覆盖判据：s0_cancel / 读口仲裁失败 / 写口撞口 / 冲刷 /
ld 取消 / og1 失败 / 异常借写口 / 多候选选源 各 >100 拍，6 个 TopDown 事件 >10 拍（exec_stall >100）。

变异自证（scratchpad 拷贝，8k 拍）：M1 去掉 ld2Cancel ⇒ errors=9486；M2 success/uncertain 对调 ⇒ 161407；M3 isAfter 用 >= ⇒ 48；
M4 忽略 redirect.level ⇒ 18；M5 异常借写口不看 isV0 ⇒ 12285；M6 s0_cancel 看 regcache 而非 forward ⇒ 6961；
M8 MEMSTALL_STORE 只看 sqFull ⇒ 470（tb 加低发射率档之前是 0，据此加档）；M9 payload 只在 fire 时更新 ⇒ 758282；
M10 异常借写口只置 1 片 wen ⇒ 19609；M11 选源看错 srcType 位 ⇒ 7961；M12 imm 只在 fire 时更新 ⇒ 6918。
**UT 看不见**：M7 int_regcache_tag 去掉"槽号 < 48"守卫（改成取模）⇒ errors=0 —— 这组寄存器只给 XSPerf 用、无输出，
归 FM（vmucp 后它们是比较点）兜底，结果见 §对账 C。

### C.4 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/DataPath.json）

模型（`fm_predict.py model DataPath`）：expected = **138,279**（golden 闭包寄存器位 59,535 + 顶层 output 位 78,744），`FM_MERGE_DUP=false` 模型适用。

lane 内非正式试跑（run_id DataPath-20260928T151646Z-3d3b68b2，不出 receipt，vmucp 关）：native SUCCEEDED，passing 137,627 /
failing 0 / 比较点 unmatched 0(0) / Constant reg 150 / Unread 481（全 matched_nc）/ unmatched unread ref 21 + impl 6；1871 s、3801 MB。
impl 的 6 个是核里 always_ff 内组合临时量 `slot` 被 FM 当寄存器的伪影 —— 已改成 always_comb 的 `rc_slot`（本 commit），预期消失。
模型对账：138,279 = 137,627 + 150 + 481 + 21 ✔。

| 项 | 预测（正式 run_proof，vmucp 开，dead_ref 声明 21 点） |
|---|---|
| passing | **138,108**（= 137,627 + 481） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| 比较点 unmatched | 0(0) |
| constant_reg | 150（105 = 35 个 N=1 WBArbiter × cancelCounter 3 位；45 = loadDependency 打拍后恒 0 的低位，24 + 21） |
| unmatched unread | ref 21（= verif/dead_ref/DataPath.json，逐条相等）/ impl 0 |
| 黑盒 | 无 |
| verdict | **PASS_DEAD_REF**（signoff-strict；native SUCCEEDED） |

`fm_predict check` 口径：模型 − 实测 = 171 = constant_reg 150 + unread 21。

### C.5 明写可能出错的地方
1. vmucp 打开后 481 点里若有被 FM 判成常量的（像族 A/B 里 cancelCounter 那样），passing 会少于 138,108、constant_reg 相应增加，
   总和不变；若总和变了，那是比较点被吞掉，按红处理。
2. constant_reg 150 的分解（105 + 45）是按试跑推的，未逐点核对；若分解不同但总数相同，照实记。
3. 本体是本 lane 第一次跑正式证明，FM 时长按试跑 ~31 分钟估；超过 3 小时按规范 30 分钟采样。

### 对账 C：DataPath 本体（proof commit `19b1b6fa`，evidence/19b1b6fa6f10/DataPath/，signoff-strict，vmucp 开，dead_ref 21）

| 项 | 预测（§C.4） | 实测 |
|---|---|---|
| verdict | PASS_DEAD_REF | **PASS_DEAD_REF**（native SUCCEEDED） |
| passing | 138,108 | **138,108** |
| failing / unverified / aborted | 0 / 0 / 0 | 0 / 0 / 0（failing_truncated=false） |
| 比较点 unmatched | 0(0) | 0（unmatched_ref 0 / unmatched_impl 0） |
| constant_reg | 150 | **150**（receipt 标 constant_reg_toggle_assumed=true：FM 的 "Constant registers … initialized by some objects that were assumed to toggle" 提示，golden 自比基线同样出现） |
| unread | ref 21（dead_ref）/ impl 0 | **21**，与 verif/dead_ref/DataPath.json 逐条相等（dead_ref_points=21），impl 侧 0 —— 试跑里的 6 个 `slot` 伪影已消失 |
| 钉点 | 57,191 | DP_PIN_END ok=57191 bad=0 |
| 黑盒 / dont_verify / elab147 | 无 | 无 / false / false |

`fm_predict check DataPath`：模型 138,279 − 实测 138,108 = 171 = constant_reg 150 + unread 21，差额被指认（rc=0）。
vmucp 第 3 条：passing 137,627（试跑，vmucp 关）→ 138,108，正好 +481。FM 1,885 s / 3,780 MB。

与 §C.4 逐项一致，差 +0。§C.5 第 1 条（vmucp 后部分点转常量）未发生。

**UT 看不见的变异 M7，FM 覆盖**（scratchpad 独立 worktree，同一 commit + 变异，`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，vmucp 开，不出 receipt）：
int_regcache_tag 写入去掉"槽号 < 48"守卫、改成槽号对 48 取模 ⇒ **FAILED failing 128**（不截断，128 matched / 0 unmatched）=
`int_regcache_tag_{0..15}_reg[0..7]` ↔ `u_core/rc_tag_q_reg[0..15][0..7]`；passing 138,108 → 137,980（正好 −128）。
即这组只供 XSPerf 的寄存器在 vmucp 下确实是被比较的点，UT 看不见的改动由 FM 兜底。

UT（verif/ut/DataPath，在 `beaf800a` 字节上跑 —— 与 proof commit 的 RTL 逐字节相同，差的只有 tb 热身：见下；9 档 × 200k 拍）：

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=199959 errors=0 PASSED | checks=199959 errors=0 PASSED（★seed 1 的 random 档实为全 1 档★） | checks=199959 errors=0 PASSED |
| 7  | checks=199969 errors=0 PASSED | checks=199969 errors=0 PASSED | checks=199969 errors=0 PASSED |
| 42 | checks=199957 errors=0 PASSED | checks=199957 errors=0 PASSED | checks=199957 errors=0 PASSED |

覆盖（各档同 seed 相同，激励只由 seed 决定）：

| seed | s0cancel | rdblock | wbblock | flushkill | ldkill | og1fail | excpw | srcmux | exec_stall | anyload | store | l1 | l2 | l3 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1  | 10362 | 63470 | 61197 | 14422 | 18066 | 81085 | 68744 | 64423 | 88443 | 16571 | 31706 | 8354 | 4168 | 2113 |
| 7  | 12727 | 75424 | 72518 | 14826 | 19484 | 90449 | 68724 | 72405 | 76594 | 14102 | 27872 | 7102 | 3566 | 1759 |
| 42 | 10990 | 68275 | 65637 | 15111 | 19060 | 85928 | 68818 | 67841 | 80077 | 14371 | 29394 | 7106 | 3528 | 1771 |

**tb 更正（照实记）**：第一轮 9 档在 `19b1b6fa` 的 tb 上跑，8 档 errors=0，**seed 1 × `+vcs+initreg+1017` errors=12**：
全部是比对开头 12 拍（cyc 125..136）的 `io_toVecExcpMod_rdata_0_bits`。根因是 tb 违反契约 —— 向量异常读回选择寄存器
`RegEnable(!isV0, r.valid)` 不复位，而热身期间 r.valid 恒 0，它一直是两侧各自的随机初值（golden 同样如此）。
tb 改为热身最后 40 拍向量异常读口全开（`beaf800a`，只改 tb 与生成器，RTL 不变），重跑全部 9 档，上表即重跑结果。

复跑：`cd verif/ut/DataPath && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`；FM：`bash scripts/run_proof.sh DataPath DataPath < /dev/null`。
