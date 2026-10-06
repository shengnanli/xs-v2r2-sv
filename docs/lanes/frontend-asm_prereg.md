# frontend-asm lane（agent/frontend-asm）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3a1acb92`（main 8200177b + 认领），工作树 `/home/eda/xs-env/wt-frontend-asm`，分支 `agent/frontend-asm` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | ICacheBuffer / InstrUncacheBuffer / ICacheCtrlBuffer / MuxBundle（叶）、FDPrefetcherMonitor（NO_OUTPUT）、Frontend（本体） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

冲突检查（2026-10-04）：codex outbox 最新 0210（ram_78x15 / Queue40）、0209、0208 均不涉及本 lane 目标与其 child；
全部 worktree 的 `docs/lanes/*_claim.md|*_prereg.md` 里本 lane 6 个模块名只出现在 dcache 系 prereg 的
FDPrefetcherMonitor 处置说明（§3）与本 lane 认领文件；Frontend 的 child PFEvent / HPerfMonitor 属
backend-misc lane，已合入 main 并已签（evidence/6038c4afbc60）。

## 1. FrontendBridge 三个 TL 两级缓冲（ICacheBuffer / InstrUncacheBuffer / ICacheCtrlBuffer）

### 1.1 结构与子模块处置

- Scala `mem/MemBlock.scala`：FrontendBridge 里三个 `TLBufferNode`，A/D 两通道各套两层 `BufferParams.default`
  （= `Queue(2, pipe=false, flow=false)`），首尾相接。InstrUncacheBuffer 在缓冲之后把 opcode/size/source/mask/data
  重新钉成常量（端口被 firtool 删掉）；ICacheBuffer / InstrUncacheBuffer 的 D 口恒接收（第二级 deq_ready=1）。
- 重写件：`rtl/memblock/{ICacheBuffer,InstrUncacheBuffer,ICacheCtrlBuffer}.sv`（手写，无核：本层只有 4 个队列的首尾连接
  与入口常量；入口常量用具名 localparam 讲清含义）。golden 行数 257 / 245 / 243，impl 204 / 188 / 181，`_GEN_`/`_T_` 均 0。
- child：Queue2_TLBundleA_8/D_7、A_12/D_13、A_10/D_11 —— 全部已签（evidence/1fda02fae0f1，receipt impl 闭包与当前字节一致）。
  处置 = **两侧白盒**：ref golden Queue2_*，impl 重写件 `rtl/uncore/Queue2_*.sv` + 共享核 `rtl/common/xs_ChiselQueue_core.sv`；
  `ram_2xN` 是 golden 行为级叶子，两侧同源 inline（同 verif/ut/UncoreTLQueues，codex 0151 D60）。无黑盒。

### 1.2 UT（verif/ut/FrontendBridgeBuffers；tb 由 gen.py → scripts/gen_l2slice_ut.py 生成，`make gencheck` 幂等）

三个目标同一 tb 各自双例化（golden `<T>` vs 派生 `<T>_xs`），逐拍 4 态比全部输出；ram 不复位，首沿前把 golden
各 Queue2 的 Memory 抄给重写侧。出口 ready 每 2000 拍在快出(75%)/慢出(25%)间切换。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED |
| 7  | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED |
| 42 | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED |

（checks = 200k 拍 × 50 个输出端口。seed 1 × random 实为全 1 档，见 CONVENTIONS。）
覆盖（seed 7 random）：12 个 Queue2 每个 进队 / 出队 均 7.2 万 ~ 10 万拍；有 ready 的链"满且被挡"
2.7 万 ~ 7.0 万拍；翻转 20/20、12/12、18/18。D 口恒接收的两条 D 链"满"结构不可达（golden 同），不设满闸。
判据自证（scratchpad 变异，不进库，seed 7 random）：M1 reqSource 1→2 ⇒ errors=199998；M2 ICacheBuffer D 第二级
deq_ready 1→d_mid_valid ⇒ 525434；M3 InstrUncacheBuffer 第二级 NC/MM 位对调 ⇒ 100391；M4 ICacheCtrlBuffer D 入口
sink 0→opcode[0] ⇒ 100084；M5 ICacheCtrlBuffer D 第二级 deq_ready 换成 1 ⇒ 555054。5/5 抓到。

复跑：`cd verif/ut/FrontendBridgeBuffers && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 试跑（diagnostic-full，vmucp 关，efac4c05 字节，不产 receipt）

| 目标 | native | passing | unread（全 matched_nc，两侧同路径） | constant_reg | failing / unmatched | 模型 |
|---|---|---|---|---|---|---|
| ICacheBuffer       | SUCCEEDED | 2844 | 52  | 307 | 0 / 0 | 3203 = 2844+52+307 |
| InstrUncacheBuffer | SUCCEEDED | 612  | 277 | 83  | 0 / 0 | 972 = 612+277+83 |
| ICacheCtrlBuffer   | SUCCEEDED | 976  | 16  | 5   | 0 / 0 | 997 = 976+16+5 |

unread 全是 Queue2 ram 里"写入但出口无人读"的字段位（D 的 param/sink、A 的 param/corrupt、InstrUncacheBuffer 第二级
被 Scala 钉常量的字段），两侧逐字同路径 → 按 vmucp standing rule 六条开 vmucp（`verif/fm_target_config/<T>.tcl`）。

### 1.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/<T>.json）

| 目标 | 模型（寄存器位 + 输出位） | passing 预测（vmucp 开） | 差额指认 | 其余 |
|---|---|---|---|---|
| ICacheBuffer       | 3203（2572 + 631） | **2896** = 2844 + 52 | constant_reg 307 | failing/unverified/unmatched/unread 全 0，无黑盒，SUCCEEDED |
| InstrUncacheBuffer | 972（848 + 124）   | **889** = 612 + 277  | constant_reg 83  | 同上 |
| ICacheCtrlBuffer   | 997（800 + 197）   | **992** = 976 + 16   | constant_reg 5   | 同上 |

可能出错的地方：vmucp 打开后若部分 unread 点被 FM 改判为常量，passing 会少于预测、constant_reg 等量增加（差额仍可指认）；
若 passing 不增，即 vmucp 空转，判红。

## 2. MuxBundle（rtl/frontend/MuxBundle.sv 已有重写件，补 receipt）

### 2.1 现状与原因

- 重写件 93a518eb 起就在（参数化核 xs_MuxBundle_core + golden 同名 wrapper），d2b3624d 修过 ELAB-147。
  `docs/fm_round_20260914.tsv` 有一轮 SUCCEEDED（passing 71），但那是 receipt 体系之前的结果；
  `docs/receipt_harvest.tsv` 里唯一一份（wt-err3:d2b3624d2fcd）标 SUPERSEDED，evidence/ 下没有任何 MuxBundle receipt
  → 轴二无 PROVEN_DIRECT。没有任何人在新体系下给它出过证。（`coverage_three_axis.tsv` 轴一写 GOLDEN_REUSE 是
  `golden_reuse_set()` 按 basename 收集 RTL_GOLDEN_DEPS 的副作用：ICacheMissUnit / ICache 的 Makefile 把**仓内**
  rtl/frontend/MuxBundle.sv 放进了 RTL_GOLDEN_DEPS；那是派生表，本 lane 不改。）
- 本 lane 只改 `verif/ut/MuxBundle/Makefile`：补 initreg 三档口径、`FM_MERGE_DUP=false`（0 寄存器，不改比较点，只让模型严格适用）、
  `PORTLINT_ORDER=fail`。RTL 不动。golden 230 行，impl 202 行，`_GEN_`/`_T_` 0。

### 2.2 UT（verif/ut/MuxBundle）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |
| 7  | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |
| 42 | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |

覆盖（seed 7）：sel 0..9 各 1.58 万 ~ 1.66 万次，越界 37456，out_ready=0 99744，选中路 valid=1/0 100268/99732，70 位载荷全翻转。
`make negtest` PASSED（source 基址抄错运行期 $fatal）。变异：MB1 sel==1 落到第 0 路 ⇒ errors=15877；MB2 in_ready 不看 out_ready ⇒ 73062。

### 2.3 跑前预测

| 目标 | 模型 | passing 预测 | 其余 |
|---|---|---|---|
| MuxBundle | 71（0 + 71） | **71** | 0 寄存器；failing/unmatched/unread 0；无 vmucp、无钉点、无黑盒；SUCCEEDED |

## 3. FDPrefetcherMonitor（NO_OUTPUT，按 dcache_prereg §1.4 先例，不跑 FM）

- golden（111 行）在本配置 0 输出 0 寄存器（`io.pf_ctrl := DontCare`，计数器只供 XSPerf，firtool 全删），体内只剩 3 条无人读的
  PopCount。重写件 `rtl/memblock/FDPrefetcherMonitor.sv`（46 行）：逐位一致的 10 个输入端口 + 同形 3 条无观察者加法
  （1998a657b dcachebody 补上，理由：空模块会被 FM 当黑盒，父级 DCache 多出 impl 侧黑盒）。代码区 `_GEN_`/`_T_` 0。
- 现状核对（本 lane）：当前字节 sha256 `8a144954837b7e4e3ac3eb9280753333bd9f3634a1735f75f421ed0a4302c015`；
  绑定它的 receipt：DCache（evidence/0dc9c4532cf5、68d1a0932a12、ce9d0692bc8e、f009d7b3c6d1，SUCCEEDED）与 DCacheLeaves 四件
  （evidence/4464d4e059b0）全部与当前字节一致；evidence/414ed06a79c5 下五份是 PopCount 补行之前的旧字节（已被 4464d4e0 重证取代）。
  端口契约 `make -C verif/ut/DCacheLeaves portlint-fdp`。
- 处置：照先例**不列 FM_VARIANTS、不出 receipt**；形式上无比较点（与 StorePipe 同类），正确性由端口契约 + 父级 DCache 闭包证明承担。
  本 lane 不需要新裁定。


## 4. Frontend（前端顶层装配）

### 4.1 历史与路线

- "Frontend = 真 shadow 核（SHADOW_CHECK）"是**上一轮（xs-v2r2-sv / G0）**的结论：那时 Frontend.sv 的输出由 golden 本体副本驱动、
  可读核只伴随比对（native SUCCEEDED passing≈48971，proof_mode=shadow）。本轮（G1）仓里**没有** Frontend 的任何重写件、UT 目录或
  receipt（`docs/coverage_three_axis.tsv`：MISSING / UNPROVEN），旧结论不适用，本 lane 从零做。
- 路线：**整棵前端子树两侧白盒**——ref = golden Frontend + 185 个 golden 子树模块；impl = 重写件 Frontend（可读核 + 生成 wrapper）+
  子树里 163 个非存储模块**全部用已签核重写件**（各自 evidence 里都有与当前字节一致的绿 receipt，清单由
  `/tmp/.../closure.py` 机械算出，落在 verif/ut/Frontend/Makefile 的 RTL_SRCS）。两侧同读 golden 的只剩存储宏链
  sram_array_* / array_* 与 MbistClockGateCell；ClockGate 用本地件（codex 0208）。唯一黑盒是宏内叶子 array_*_ext（84 个/侧，
  verif/vendor_boundary.tsv 已审 vendor_sram_leaf）→ FM_MODE=assembly + verif/allow/Frontend.json。不用 green_child 证书路线。

### 4.2 重写件

- `rtl/frontend/Frontend.sv`（8619 行，`_GEN_`/`_T_` 0，可读性审计 A~G 全 0）：
  * `xs_Frontend_core`（手写，466 行）七节：§1 重定向打一拍分发给 IBuffer；§2 sfence 两拍、ICache 预取开关 / fence.i 一拍；
    §3 FTQ→IFU/ICache 取指请求联合握手；§4 wfi safe；§5 ICache ECC 上报两拍；§6 性能事件两拍；§7 指令流自检（checkPcMem 64×50
    + 三组跨拍记录，只喂 `ifndef SYNTHESIS 断言，照 golden 一位不少）。寄存器复位域逐个对齐 golden（只有自检三个 valid 异步复位）。
  * `Frontend` wrapper：`scripts/gen_frontend.py` 生成（带 `--check`），fail-closed 规则见生成器头：端口逐位同序、23 个实例照搬、
    每个连接表达式必须落进已知形状（顶层口 / 子模块输出线 / MBIST 具名线 / 常量 / 核输出 / 探针悬空），实例间每一对连接都要有
    一句说明（PAIR_DESC），按 §A 预测取指主干 / §B 翻译与权限 / §C CSR 与 wfi 延迟 / §D 性能 / §E MBIST 分节。
- golden 10,940 行 → impl 8,619 行（其中生成区约 8,100 行是 5,630 个端口连接的逐行展开）。

### 4.3 UT（verif/ut/Frontend；tb 由 gen.py → scripts/gen_l2slice_ut.py 生成）

双例化 golden Frontend（golden 子树）vs Frontend_xs（**整棵子树都是重写件**，派生 _xs），逐拍 4 态比全部 195 个输出。
激励按 5000 拍分四相：M 态顺序取指 / S 态 Sv39 + 随机 PTW 回包 / 全随机 / 频繁重定向 + MMIO 取指（复位向量落在 PMA 的可执行
不可缓存区）。initreg 三档沿用 DCache 先例：`0`（全设计 0）、`glue`（子模块 0、两侧 Frontend 本层随机，种子 SEED）、
`glue017`（种子 <SEED>017）；双例化下全设计 random 会让两侧 SRAM/表项各摇各的初值，比出来的是初值噪声。
（`+vcs+initreg+config` 的实例档已用 UCLI 实测生效：两侧 sfence_s1_addr / check_pc_mem[5] 在 0 时刻为不同的随机值。）

UT 结果（commit 5312439b，RTL 与 fd925bcf 相同；每档 200k 拍，checks = 200k × 195）：

| seed | `0` | `glue` | `glue017` |
|---|---|---|---|
| 1  | checks=39000000 errors=0 PASSED（翻转 152/195） | 同左 | 同左 |
| 7  | checks=39000000 errors=0 PASSED（152/195） | 同左 | 同左 |
| 42 | checks=39000000 errors=0 PASSED（153/195） | 同左 | 同左 |

覆盖（initreg 0 档）：取指请求三方握手 25513 / 27608 / 28741 次；IBuffer→后端 out_0 fire 50175 / 55817 / 56772；
后端重定向冲刷 26664 / 26762 / 26544；MMIO 取指请求 80 / 16 / 148；ITLB→PTW 52160 / 52399 / 52225；FTQ 重定向 BPU
26800 / 26802 / 26680；ICache ECC 错误 2 / 1 / 1；自检 (b) taken 目标跨拍记录 2471 / 605 / 706；(c) not-taken 跨拍记录
300 / 90 / 314（seed 1 / 7 / 42）。自检 (a) 的跨拍记录 0 次（要 BPU 预测出 taken 的条件分支），不设闸，由 FM 覆盖。
翻转闸 152：未翻转的 43 个输出逐一列在 verif/ut/Frontend/gen.py（12 个 debug_seqNum 在 golden 里恒 0；其余 31 个未逐一追查原因）。

判据自证（scratchpad 变异，不进库，seed 7 initreg 0，40k 拍）：M2 sfence 少打一拍 ⇒ errors=21077；M3 ECC 上报去掉
report_to_beu 门控 ⇒ 1；M4 性能事件少打一拍 ⇒ 689；M5 IBuffer.flush 接成 ControlRedirect 标志 ⇒ 668396 —— 抓到。
**UT 抓不到的三个**：M1 取指握手去掉 ICache.ready（激励下 IFU ready 时 ICache 也总 ready）、M6 wfi safe 去掉 InstrUncache
的 safe（wfiReq 与 MMIO 在途从未同时出现）、M7 checkPcMem 永不写（自检只喂断言、无观察者）——前两个在输出锥里，FM 逐点证明；
M7 的寄存器两侧都是无读者对称死位，FM 开 vmucp 后逐位真比。
复跑：`cd verif/ut/Frontend && make derive && touch ut_gen/*.sv && make run SEED=<1|7|42> INITREG=<0|glue|glue017>`
（ut_common 的 derive 规则对 160 个派生文件逐个触发全量派生，派生幂等不改 mtime，先显式派生一次再 touch，否则每次 make 白跑 ~1.5 小时。）

### 4.4 FM 的配对（为什么要 15 万条钉点）

golden 自比基线（golden 闭包对其逐字副本，FM_MERGE_DUP=false，array_*_ext 两侧黑盒）：native SUCCEEDED，passing 124,020，
failing 0，unread 49,746（全 matched_nc），constant_reg 2,884，2,272 s / 5.2 GB；passing + unread + constant = 176,650 =
fm_predict 模型（寄存器 166,444 + 输出 4,478 + 黑盒输入 5,728），地板 0 failing。

整棵子树换成重写件后，首次诊断（无钉点、诊断脚本关签名分析）23,138(22,576) 个比较点未配对；fm_eq.tcl 全流程（签名分析开）
也只配上几百到一千个，且签名分析会交叉配错（DelayN_7、IPrefetchPipe waymask，见 4.5）。钉点 `verif/ut/Frontend/fm_pins_pre.tcl`
（scripts/gen_frontend.py 生成，四节、全部字面、逐条数返回值、拒一条即 error）：
1. 顶层胶合寄存器 3,612 位（golden 115 个 inner_* 寄存器 → u_core，映射表 CORE_REGS 必须覆盖 golden 本层全部 reg）；
2. 子树钉点重定位 102,654 条：34 个已签子目标自己的钉点脚本（tclsh 打桩执行取字面对；Predictor 的发现式脚本在诊断 FM 里执行录成
   predictor_pins.tsv，2711/2711），按实例对应表（UCLI 从双例化 simv 导出层次 → fe_inst_map.tsv）改写成 Frontend 实例路径；
   ★不能用设计作用域路径：实测设计被例化两次时 set_user_match 返回 1 却不生效★；钉点源证明时 impl 侧读 golden 的子模块内部的
   钉点（如 Composer 当年读 golden SRAMTemplate / ClockGate）判为过期剔除（1,445 条）；
3. 子树自配对录制 46,833 条：对未配对点所在的 67 个设计各单独跑一次 FM 匹配（同一套重写件），把 FM 自己给出的配对录成
   harvest_pins.tsv 再按实例重定位（-type cell，避开 golden "x_reg 单元 / x_reg 线网"同名的 FM-013）。
4. 恒等副本 / 多源配对类 798 次多对多 set_user_match（verif/ut/Frontend/dup_groups.tsv；identify_duplicate_registers -by_structure
   的同侧副本组 + 第二/三节里与之相连的钉点并查集成类，整类一次给出）。

### 4.5 诊断跑记录（scratchpad，不产 receipt；同一 RTL 字节 fd925bcf，钉点按 commit 递进）

| 跑 | 设置 | 配对结果 | verify |
|---|---|---|---|
| match14 | merge_dup=false，一对多分段 | 828(286) 未配对，292 条 "Ignoring user match: more than one reference object" | — |
| match15 | merge_dup=true，同一套钉点（去第四节） | 4017(819) 未配对；35149 条钉点指向被合并掉的对象被丢 | — |
| match16 | merge_dup=false + user_match_enable_many_to_many_matching | 11(0)，0 条被丢 | — |
| match17 | 同上 + 补录 11 个，fm_eq.tcl 全流程 | 0(0)；unread 4766(34)（DelayN_7 被签名分析交叉配错） | failing 20（上限截断），unverified 131801 |
| match18 | + DelayN_7 显式钉住（438 对），failing 不限 | 0(0)；unread 4732(0) | passing 109054 / failing 58959（分段一对一配错，analyze_points 指认） |
| match19 | 第四节改整类多对多（FM 先证同侧等价） | 0(0)；798/798 组预证明通过；unread 4732(0) | **passing 167630 / failing 383 / aborted 0 / unverified 0** |
| match20 | + IPrefetchPipe waymask 改取 merge=true 录制；+ pc_mem 低 6 位存储位类（384 组预证明全失败、被删） | 0(0)；unread 4732(0) | **passing 168007 / failing 6 / aborted 0 / unverified 0**，constant_reg 2680；6 个全是 toPrefetchPc_nextLineAddr[5:0]（见 4.6） |

unread 4732(0) 全在 golden 侧：4582 位 = 子目标自己的 PASS_DEAD_REF 声明（Ftq 4276 / Tage_SC 192 / HPerfCounter 64 / FTBBank 50）按实例
重定位后逐条相同，另 150 位 = ftbBank req_pc_reg / _2 / _3（与 FTBBank.json 的 _1 同为断言专用 PC 副本，FTBBank 自签 merge=true 时
并成 _1）。声明 verif/dead_ref/Frontend.json（4732 条，按诊断观测写出；正式跑观测须与之精确相等，否则 PARTIAL）。
对模型：176650 − (168007 + 6) − 4732 − 2680 = **1225** 位指认不了 —— 正是多对多配对类里被 FM "Moved loads" 并掉、不再单独成比较点的
ref 副本（match20 日志 3788 行 Moved loads，含 impl 侧）。fm_predict 目前不认这一项。

### 4.6 ★正式证明前需要集成者裁定的两件事（本 lane 不改共享脚本 / 已签共享核）★

1. **user_match_enable_many_to_many_matching 不在 sidecar appvar 注册表里**（scripts/sidecar/fm_native_emit.tcl 的
   SIDECAR_APPVAR_REQUIRED/OPTIONAL、scripts/fm_eq.tcl 的 FM_TARGET_APPVAR_ALLOWED、SIDECAR_SCHEMA.md APPVAR_SPEC）：
   钉点里 set_app_var 会被运行期拦截 exit 3，fm_target_appvar 也只许 OPTIONAL 四项。它不放宽比较——玩具实测：
   3 个 ref 副本对 1 个 impl → 16 点全 passing；把其中一个 ref 副本改成不等价（a_1 <= d ^ e）→ FM 报
   "Many-to-many matching: Verify failed for a_1 to a / Deleting failing many_to_many user match"，点变未配对、下游 4 点 failing。
   副作用：被并掉的 ref 副本不再各自成比较点（"Moved loads of X to Y"），fm_predict 的 merge=false 模型（176650）会出现
   与合并类成员数相等的、constant_reg + unread 指认不了的余额 —— 需要模型认这一项，或改判 MODEL_NA。
2. **6 个 failing 根在已签共享核 rtl/frontend/Ftq.sv**（2306-2318 行）：可读核的 toPrefetchPc_nextLineAddr[5:0] 直接取
   startAddr 那一路（注释写明是为了 Ftq 自签 merge_dup=true 时与 golden 合并后的形状一致）；golden 读的是 ftq_pc_mem 里单独存的
   nextLineAddr[5:0]。两者只在"每个条目写入时 nextLineAddr[5:0] == startAddr[5:0]"这条可达状态不变量下相等。
   Frontend 层 merge_dup=false 证不出（多对多预证明对带自保持环的存储位一律失败，match20/21 384 组全删）。
   可选路线：(a) Frontend 改 merge_dup=true（match15 实测到 Matching 3 小时 7.4GB，且要整套改用 merge=true 录制的配对，
   未收敛）；(b) Ftq.sv 改成照 golden 读存储的 nextLineAddr[5:0]（动已签共享核 + 要重签 Ftq）；(c) 其它裁定。


## 5. codex 0226：Frontend 改走 exact green_child —— 第一步：八个直接 child 的证书闭包重证（★跑前登记，跑完不许改本节★）

0226 定 Frontend 为八个直接实例的 green_child 组合（inner_bpu=Predictor、inner_ftq=Ftq、inner_icache=ICache、inner_ifu=NewIFU、
inner_ibuffer=IBuffer、inner_instrUncache=InstrUncache、inner_itlb=TLB、inner_itlbRepeater1=PTWFilter）。§4 的全展开 + 15 万条收割钉点路线作废。

现状（HEAD=80d35d8c0，`scripts/proof_certificate.py` 的 validate_certificate_current 逐个复核，scratchpad certcheck.py / certtree.py）：
八个 child 都**没有 tracked 证书**；仓里最新的合格 receipt 全部失效 —— 主因 scripts/fm_eq.tcl 在它们之后改过（script_closure_changed），
另 ICache a7279429 的 xs_SRAMTemplate_core.sv 闭包变了、TLB 6571efce 缺 RUN_CONTEXT（非 run_proof 产出）。
而且 Predictor / Ftq / ICache 的 impl 闭包里两侧共读 golden 子模块（Composer、FTB、SyncDataModuleTemplate*…），按 0222 §3d
这些 golden 必须是持有合格证书的独立 FM target（递归）或已登记的 MC 存储契约。递归展开后要出证书的 target 共 **96 个**（下表），
全部在同一个钉住的 commit 上用 `PROOF_COMMIT=<c> bash scripts/run_proof.sh <ut> <T> < /dev/null` 重跑（不改它们的 RTL / Makefile / 钉点）。
它们 impl 闭包里的 sram_array_* / array* / data_mem_* 存储层按 verif/mc_memory_registry.tsv 的推导模板逐条登记（mc_memory_registry.py --derive / --check），
登记在跑完、出证书之前提交（登记表不在任何 target 的 script closure 里）。

预测：每个 target 的 passing / verdict 与它上一份合格 receipt 相同（重跑只因脚本闭包变化，RTL 与钉点未动）。

| target | UT 目录 | 预测 verdict | 预测 passing | 上一份 receipt | 上次用时 s |
|---|---|---|---|---|---|
| ClockGate | ClockGate | SUCCEEDED | 2 | evidence/bef96c62cc68 | 11 |
| DelayN | DelayN | SUCCEEDED | 10 | evidence/f0bcd42e8a81 | 44 |
| DelayNWithValid | DelayNWithValid | SUCCEEDED | 151 | evidence/7a881579fe64 | 45 |
| DelayNWithValid_1 | DelayNWithValid | SUCCEEDED | 181 | evidence/7a881579fe64 | 45 |
| DelayN_1 | DelayN | SUCCEEDED | 3 | evidence/f0bcd42e8a81 | 44 |
| MbistClockGateCell | MbistClockGateCell | SUCCEEDED | 2 | evidence/2948215a047b | 10 |
| MbistPipeFtb | MbistPipe | SUCCEEDED | 707 | evidence/40ec7fc36bb8 | 48 |
| SRAMTemplate_36 | SRAMTemplate | SUCCEEDED | 189 | evidence/68d1a0932a12 | 11 |
| SplittedSRAMTemplate_2 | SplittedSRAMTemplate | SUCCEEDED | 1505 | evidence/68d1a0932a12 | 64 |
| FTB | FTB | PASS_DEAD_REF | 8605 | evidence/d37248da1db4 | 173 |
| FTBBank | FTBBank | PASS_DEAD_REF | 3276 | evidence/f40deba9439d | 152 |
| FoldedSRAMTemplate | FoldedSRAMTemplate | SUCCEEDED | 113 | evidence/68d1a0932a12 | 14 |
| FoldedSRAMTemplate_1 | FoldedSRAMTemplate | SUCCEEDED | 148 | evidence/68d1a0932a12 | 11 |
| FoldedSRAMTemplate_20 | FoldedSRAMTemplate | SUCCEEDED | 109 | evidence/68d1a0932a12 | 12 |
| FoldedSRAMTemplate_22 | FoldedSRAMTemplate | SUCCEEDED | 443 | evidence/68d1a0932a12 | 33 |
| FoldedSRAMTemplate_24 | FoldedSRAMTemplate | SUCCEEDED | 846 | evidence/68d1a0932a12 | 35 |
| IndexableCAMTemplate_32 | IndexableCAMTemplate | SUCCEEDED | 96 | evidence/40ec7fc36bb8 | 45 |
| IndexableCAMTemplate_41 | IndexableCAMTemplate | SUCCEEDED | 36 | evidence/40ec7fc36bb8 | 60 |
| IndexableCAMTemplate_43 | IndexableCAMTemplate | SUCCEEDED | 40 | evidence/40ec7fc36bb8 | 44 |
| RAS | RASTop | SUCCEEDED | 6592 | evidence/7f8365cc79ab | 60 |
| RASStack | RAS | SUCCEEDED | 3018 | evidence/40ec7fc36bb8 | 99 |
| SRAMTemplate_44 | SRAMTemplate | SUCCEEDED | 120 | evidence/68d1a0932a12 | 11 |
| SRAMTemplate_45 | SRAMTemplate | SUCCEEDED | 148 | evidence/68d1a0932a12 | 11 |
| SRAMTemplate_64 | SRAMTemplate | SUCCEEDED | 58 | evidence/68d1a0932a12 | 11 |
| SRAMTemplate_76 | SRAMTemplate | SUCCEEDED | 478 | evidence/68d1a0932a12 | 11 |
| SRAMTemplate_78 | SRAMTemplate | SUCCEEDED | 478 | evidence/68d1a0932a12 | 11 |
| SplittedSRAMTemplate_23 | SplittedSRAMTemplate | SUCCEEDED | 110 | evidence/68d1a0932a12 | 13 |
| SplittedSRAMTemplate_25 | SplittedSRAMTemplate | SUCCEEDED | 478 | evidence/68d1a0932a12 | 13 |
| SplittedSRAMTemplate_27 | SplittedSRAMTemplate | SUCCEEDED | 955 | evidence/68d1a0932a12 | 13 |
| SplittedSRAMTemplate_3 | SplittedSRAMTemplate | SUCCEEDED | 120 | evidence/68d1a0932a12 | 14 |
| SplittedSRAMTemplate_4 | SplittedSRAMTemplate | SUCCEEDED | 148 | evidence/68d1a0932a12 | 11 |
| WrBypass_32 | WrBypass | SUCCEEDED | 158 | evidence/40ec7fc36bb8 | 47 |
| WrBypass_41 | WrBypass | SUCCEEDED | 50 | evidence/40ec7fc36bb8 | 51 |
| WrBypass_43 | WrBypass | SUCCEEDED | 54 | evidence/40ec7fc36bb8 | 46 |
| Composer | Composer | PASS_DEAD_REF | 42060 | evidence/be19d6a02dba | 601 |
| FauFTB | FauFTB | SUCCEEDED | 5660 | evidence/cee2812229bf | 157 |
| FauFTBWay | FauFTBWay | SUCCEEDED | 139 | evidence/40ec7fc36bb8 | 64 |
| ITTage | ITTage | SUCCEEDED | 10426 | evidence/68d1a0932a12 | 118 |
| ITTageTable | ITTageTable | SUCCEEDED | 682 | evidence/c6573076c5ba | 14 |
| ITTageTable_1 | ITTageTable_1 | SUCCEEDED | 682 | evidence/c6573076c5ba | 20 |
| ITTageTable_2 | ITTageTable_2 | SUCCEEDED | 1014 | evidence/c6573076c5ba | 18 |
| ITTageTable_3 | ITTageTable_3 | SUCCEEDED | 1014 | evidence/c6573076c5ba | 15 |
| ITTageTable_4 | ITTageTable_4 | SUCCEEDED | 1014 | evidence/c6573076c5ba | 15 |
| IndexableCAMTemplate | IndexableCAMTemplate | SUCCEEDED | 80 | evidence/40ec7fc36bb8 | 45 |
| IndexableCAMTemplate_33 | IndexableCAMTemplate | SUCCEEDED | 144 | evidence/40ec7fc36bb8 | 62 |
| MaxPeriodFibonacciLFSR | MaxPeriodFibonacciLFSR | SUCCEEDED | 30 | evidence/1b420e2033a9 | 11 |
| MbistPipeIttage | MbistPipe | SUCCEEDED | 435 | evidence/40ec7fc36bb8 | 59 |
| MbistPipeIttage_1 | MbistPipe | SUCCEEDED | 435 | evidence/40ec7fc36bb8 | 46 |
| MbistPipeIttage_2 | MbistPipe | SUCCEEDED | 614 | evidence/40ec7fc36bb8 | 46 |
| MbistPipeIttage_3 | MbistPipe | SUCCEEDED | 614 | evidence/40ec7fc36bb8 | 46 |
| MbistPipeIttage_4 | MbistPipe | SUCCEEDED | 614 | evidence/40ec7fc36bb8 | 47 |
| MbistPipeSc | MbistPipe | SUCCEEDED | 190 | evidence/40ec7fc36bb8 | 46 |
| MbistPipeSc_1 | MbistPipe | SUCCEEDED | 190 | evidence/40ec7fc36bb8 | 46 |
| MbistPipeSc_2 | MbistPipe | SUCCEEDED | 190 | evidence/40ec7fc36bb8 | 46 |
| MbistPipeSc_3 | MbistPipe | SUCCEEDED | 190 | evidence/40ec7fc36bb8 | 46 |
| MbistPipeTage | MbistPipe | SUCCEEDED | 1396 | evidence/40ec7fc36bb8 | 49 |
| PriorityMuxModule | PriorityMuxModule | SUCCEEDED | 50 | evidence/40ec7fc36bb8 | 45 |
| PriorityMuxModule_12 | PriorityMuxModule | SUCCEEDED | 23 | evidence/40ec7fc36bb8 | 45 |
| PriorityMuxModule_16 | PriorityMuxModule | SUCCEEDED | 3 | evidence/40ec7fc36bb8 | 44 |
| PriorityMuxModule_20 | PriorityMuxModule | SUCCEEDED | 1 | evidence/40ec7fc36bb8 | 44 |
| PriorityMuxModule_4 | PriorityMuxModule | SUCCEEDED | 140 | evidence/40ec7fc36bb8 | 48 |
| PriorityMuxModule_8 | PriorityMuxModule | SUCCEEDED | 9 | evidence/40ec7fc36bb8 | 47 |
| RegionWays | RegionWays | SUCCEEDED | 680 | evidence/1b420e2033a9 | 19 |
| SCTable | SCTable | SUCCEEDED | 1123 | evidence/68d1a0932a12 | 30 |
| SCTable_1 | SCTable | SUCCEEDED | 1123 | evidence/68d1a0932a12 | 26 |
| SCTable_2 | SCTable | SUCCEEDED | 1123 | evidence/68d1a0932a12 | 28 |
| SCTable_3 | SCTable | SUCCEEDED | 1123 | evidence/68d1a0932a12 | 47 |
| SRAMTemplate_68 | SRAMTemplate | SUCCEEDED | 145 | evidence/68d1a0932a12 | 8 |
| TageBTable | TageBTable | SUCCEEDED | 396 | evidence/c6573076c5ba | 14 |
| TageTable | TageTable | PASS_DEAD_REF | 797 | evidence/f811f8d51f92 | 48 |
| WrBypass | WrBypass | SUCCEEDED | 124 | evidence/40ec7fc36bb8 | 47 |
| TageTable_1 | TageTable | PASS_DEAD_REF | 1585 | evidence/e0bc44bf9a73 | 73 |
| TageTable_2 | TageTable | PASS_DEAD_REF | 1585 | evidence/e0bc44bf9a73 | 81 |
| TageTable_3 | TageTable | PASS_DEAD_REF | 1585 | evidence/e0bc44bf9a73 | 85 |
| Tage_SC | Tage_SC | PASS_DEAD_REF | 16112 | evidence/68d1a0932a12 | 554 |
| WrBypass_33 | WrBypass | SUCCEEDED | 398 | evidence/40ec7fc36bb8 | 51 |
| Predictor | Predictor | SUCCEEDED | 528967 | evidence/bfd1afc7451e | 17619 |
| DataModule_FtqPC_16entry | SyncDataModule | SUCCEEDED | 2168 | evidence/25cdce831a66 | 58 |
| DataModule__16entry | SyncDataModule | SUCCEEDED | 1504 | evidence/25cdce831a66 | 52 |
| DataModule__16entry_12 | SyncDataModule | SUCCEEDED | 1570 | evidence/25cdce831a66 | 55 |
| DataModule__16entry_4 | SyncDataModule | SUCCEEDED | 9792 | evidence/25cdce831a66 | 98 |
| DataModule__16entry_8 | SyncDataModule | SUCCEEDED | 250 | evidence/25cdce831a66 | 48 |
| FTBEntryGen | FTBEntryGen | SUCCEEDED | 72 | evidence/f40deba9439d | 47 |
| FtqPcMemWrapper | FtqPcMemWrapper | SUCCEEDED | 7166 | evidence/25cdce831a66 | 163 |
| SyncDataModuleTemplate_FtqPC_64entry | SyncDataModule | SUCCEEDED | 7166 | evidence/8b9c32ee57dd | 97 |
| SyncDataModuleTemplate__64entry | SyncDataModule | SUCCEEDED | 5743 | evidence/8b9c32ee57dd | 50 |
| SyncDataModuleTemplate__64entry_1 | SyncDataModule | SUCCEEDED | 38029 | evidence/8b9c32ee57dd | 294 |
| SyncDataModuleTemplate__64entry_2 | SyncDataModule | SUCCEEDED | 955 | evidence/8b9c32ee57dd | 17 |
| SyncDataModuleTemplate__64entry_3 | SyncDataModule | SUCCEEDED | 5999 | evidence/8b9c32ee57dd | 48 |
| Ftq | Ftq | PASS_DEAD_REF | 66481 | evidence/ff4dfe24f181 | 2423 |
| ICache | ICache | SUCCEEDED | 21174 | evidence/a72794293f57 | 1057 |
| NewIFU | NewIFU | SUCCEEDED | 9247 | evidence/48bc44efbe64 | 205 |
| IBuffer | IBuffer | SUCCEEDED | 7908 | evidence/5c7eec56325a | 944 |
| InstrUncache | InstrUncache | SUCCEEDED | 205 | evidence/40ace84c0bea | 45 |
| TLB | TLB | SUCCEEDED | 11118 | evidence/6571efce8ce6 | 983 |
| PTWFilter | PTWFilter | SUCCEEDED | 1077 | evidence/48bc44efbe64 | 61 |

## 6. Frontend official（codex 0226 exact green_child 组合）—— 跑前登记（★跑完不许改本节★）

### 6.1 证明形态
- green_child（两侧 `-interface_only`，verif/allow/Frontend.json 16 条，逐 r/i 实例路径 + child_target + 证书 sha256 写死）：
  inner_bpu=Predictor、inner_ftq=Ftq、inner_icache=ICache、inner_ifu=NewIFU、inner_ibuffer=IBuffer、inner_instrUncache=InstrUncache、
  inner_itlb=TLB、inner_itlbRepeater1=PTWFilter；`FM_INTERFACE_ONLY` 恰为这 8 个 design。
- 两侧白盒：Frontend 本层 glue（466 行可读核）+ 10 种非 green 直接子模块（DelayN_7/8/13、PMP、PMPChecker_2×5、PTWRepeaterNB、PFEvent、
  HPerfMonitor、MbistPipeFrontend、MbistIntfFrontend）。ref 21 个 G1 文件（含 8 个 green child 的端口定义），impl 29 个重写件
  （含 8 个 green wrapper，定义 package 的文件排前）。两侧不共读任何 golden 存储模型。
- 钉点 verif/ut/Frontend/fm_pins_pre.tcl（scripts/gen_frontend.py，`--check` 幂等）：一、顶层胶合寄存器 3612 位；二、白盒子模块内部配对
  9064 条（PMP 6664 / PTWRepeaterNB 312 由各自签核钉点重定位，PFEvent 1464 / DelayN_8 548 / MbistPipeFrontend 76 由源码结构推出）。
  以前的「子树钉点重定位 / 自配对收割 / 副本配对类」约 15 万条与 5 个数据文件（harvest_pins.tsv、dup_groups.tsv、predictor_pins.tsv、
  fe_inst_map.tsv、fe_impl_hier.tsv）全部删除（误随 e9be8cd8b 一起提交，提交说明没写，这里补记）。
  第二节对 canary1 的 FM 自动配对逐条交叉核对：6750 条与 FM 一致、0 条不一致，其余 2314 条是对称无读者位（FM 不做函数配对）。
- vmucp：verif/fm_target_config/Frontend.tcl（5516 对，六条证据）；dead_ref：verif/dead_ref/Frontend.json（64 位，HPerfMonitor 同一批）。

### 6.2 canary（同一字节、工作树、不产 receipt）
| 跑 | 形态 | native | passing | failing | unmatched | unread | constant_reg | 黑盒 |
|---|---|---|---|---|---|---|---|---|
| canary1 | 只有顶层钉点 | FAILED | 27845 | 10（inner_pmp wdata_reg，PMP 内部配错） | 0(0) | 2378(2314) | 183 | 8 design × r/i |
| canary2 | + 第二节 9064，vmucp 开 | SUCCEEDED | **30093** | 0 | 0(0) | 64(0)（全是 dead_ref） | **259** | 8 design × r/i |
| canary3 | 同 canary2，vmucp 关 | SUCCEEDED | 24577 | 0 | 0(0) | 5516 matched_nc + 64 | 259 | 同上 |
canary2 用时 345 s。黑盒报告（FM-184）两侧恰为 8 个 `i` 属性 design，各 1 个实例（另有 12 个 0 实例的参数化核 `e *` 条目，未例化）。

### 6.3 预测（docs/fm_predictions/Frontend.json，模型 30418）
native SUCCEEDED；passing **30093**、constant_reg **259**、failing / unverified / aborted / unmatched / blackbox_out **0**、unread = dead_ref 64 位；
dont_verify / elab147 / relaxed_appvars 空。30418 − 30093 = 325 = 259 + 64 + **2**：那 2 位是模型的 BB_IN_RE 把 golden Ftq.sv / NewIFU.sv 注释里的
"input that" 各数成一个黑盒输入位（scripts/fm_passing_model.py 扫模块体全文）——实际比较点没有它们，fm_predict check 会因此报余额 2。
**verdict 预测 PARTIAL**：八个 green child 证书里 7 个在父 commit 上 current-valid，inner_bpu=Predictor 递归复核不过
（`green_child_impl_golden_not_fm_target:Composer:data_mem_8x4`，另 FTB / FTBBank 报 external_dependency_spurious），见 6.4。

### 6.4 证书链现状（scripts/proof_certificate.validate_certificate_current，HEAD=d91546585 复核）
96 个 target 里 90 个 CURRENT；不过的 6 个全在 Predictor 链上，两个原因都在公共核心，本 lane 不改：
1. data_mem_8x4（G1 firtool 2R1W 带 2 段写掩码的 ram）推导不出 MC 模板（mc_memory_registry.py：not_single_instance），也不是 FM target；
   Composer / TageBTable / Tage_SC 的 impl 闭包两侧共读 golden WrBypass_32 → 带上它（Predictor 经由 Composer）。
2. proof_certificate.validate_impl_golden_certified 的 `_seen` 在递归里共享：FTB 自己的 MC 对象 array_1 / sram_array_1p512x40m10s1h0l1b_bp_ftb
   先在递归到 SRAMTemplate_36 时被记进 `_seen`，回到 FTB 本层就被跳过、不计 hit，于是 FTB / FTBBank 的
   external_dependency=MC_MEMORY_CONTRACT 被判 spurious（证书本身如实）。

## 7. 集成者裁定后的收尾（2026-10-06）

1. **validator 修复**（0bad09974，scripts/proof_certificate.py 由本 lane 单 owner）：validate_impl_golden_certified 里 MC 命中改为按当前层计，
   `_seen` 只用于证书递归的去重 / 防环。负测在 test_proof_certificate_grandchild「正例2」：本层与 golden 子层共用同一 MC 对象，
   旧实现报 green_child_external_dependency_spurious、新实现放行；SABOTAGE_GC 元负例仍抓到；test_proof_certificate / _nested 22 /
   _grandchild 6 / test_audit_ram_manual_review / test_audit_ram_memory_model 15 全过。修后 FTB / FTBBank 证书 CURRENT（证书未重出）。
2. **data_mem_8x4 走路线 (b)**（80c887760）：Composer / TageBTable / Tage_SC / Predictor 的 FM impl 侧改读已签重写件 WrBypass_32（target-specific，
   UT 闭包不变）；Predictor 另把 golden WrBypass / IndexableCAMTemplate（与重写核文件同名模块冲突）和 WrBypass_33（例化 data_mem_16x12，
   同样推导不出 MC 模板）一并换成已签重写件（三者均持 current 证书）。Composer 的 child_pairs/Tage_SC.tsv 按新配置的 Tage_SC FM 配对重抽（bb871960e，
   151 条 tage/bt/wrbypass 换名，总数 14262 不变），钉点重生成、`--check` OK。
   预测 = 各自已登记的 docs/fm_predictions（本节写于 TageBTable / Tage_SC / Composer 重证之后、Predictor 重证完成之前；登记文件早于这些证明）：
   TageBTable 396、Tage_SC 16112（PASS_DEAD_REF）、Composer 42060（PASS_DEAD_REF）、Predictor 528967。
   实测（PROOF_COMMIT=bb871960e，evidence/bb871960e9ea/）：TageBTable SUCCEEDED 396、Tage_SC PASS_DEAD_REF 16112、Composer PASS_DEAD_REF 42060，
   fm_predict check 三个 rc=0；证书重出（9058b0b2c），递归复核 CURRENT。

## 对账

### 第一批：三个 FrontendBridge 缓冲 + MuxBundle（run_proof @ 3390b6ba，evidence/3390b6ba80a9/<目标>/）

| 目标 | 预测 passing | 实测 passing | 差 | failing / unverified / unmatched / unread / 黑盒 / dont_verify | constant_reg | receipt.json sha256 |
|---|---|---|---|---|---|---|
| ICacheBuffer       | 2896 | **2896** | 0 | 0 / 0 / 0(0) / 0 / 无 / 无 | 307 | `b1572189e526bbc173a4aa6b24ff4ac5d1b58581c6a6b9da4c290fae5128e496` |
| InstrUncacheBuffer | 889  | **889**  | 0 | 0 / 0 / 0(0) / 0 / 无 / 无 | 83  | `46bd4087f0e771fa62f0557fb7d4542d66b3df18834ed2041caff075f9553494` |
| ICacheCtrlBuffer   | 992  | **992**  | 0 | 0 / 0 / 0(0) / 0 / 无 / 无 | 5   | `403b03056450c8cecb157dd516ef98243634ea467147751fa3b2bf870561961b` |
| MuxBundle          | 71   | **71**   | 0 | 0 / 0 / 0(0) / 0 / 无 / 无 | 0   | `00d150bcaafdc9c86926fc1f61a7d5c80d78e94cd0953f020dcff63f67e006b8` |

全部 native SUCCEEDED、signoff-strict 判 SUCCEEDED。vmucp 第 3 条：passing 2844→2896（+52）、612→889（+277）、976→992（+16），
正好等于试跑 unread 数；unread 归 0。`python3 scripts/fm_predict.py check ICacheBuffer InstrUncacheBuffer ICacheCtrlBuffer MuxBundle`
rc=0（模型 − 实测 = constant_reg，逐项指认）。

复跑：`bash scripts/run_proof.sh FrontendBridgeBuffers ICacheBuffer InstrUncacheBuffer ICacheCtrlBuffer < /dev/null`；
`bash scripts/run_proof.sh MuxBundle MuxBundle < /dev/null`。

### 第二批：codex 0226 证书链重证（§5）+ Frontend official（§6）

**§5 重证 96 个 target**（PROOF_COMMIT=7b1dd37ba，evidence/7b1dd37bad70/<T>/，全部 rc=0）：95 个 verdict 与 passing 与 §5 表逐个相同；
1 个不同——**TageTable：§5 表写 797，实测 1585**。§5 表的"上一份 receipt"取错了：f811f8d51f92 早于 e7882180b（Tage 去 green_child 改两侧
同源白盒），之后 TageTable 的已登记预测 docs/fm_predictions/TageTable.json 与 1585 一致（`fm_predict.py check TageTable` rc=0）。这是本 lane 登记表的抄录错误，不是证明的变化。
Predictor 528967 / 16114 s，Ftq PASS_DEAD_REF 66481 / 2732 s，ICache 21174 / 1229 s。
之后 SRAMTemplate / SplittedSRAMTemplate / FoldedSRAMTemplate 的 18 个前端 variant 改成各自只读真用到的 MC 模型（0591d79d6），在 evidence/0591d79d6132/ 重证，
passing 与上一份逐个相同（189/120/148/58/145/478/478、1505/110/478/955/120/148、113/148/109/443/846）。证书 96 份（verif/proof_certificates/）。

**§6 Frontend official**（bash scripts/run_proof.sh Frontend Frontend，commit 27112f2ee，evidence/27112f2ee5cd/Frontend/，347 s）：

| 项 | 预测 | 实测 |
|---|---|---|
| native | SUCCEEDED | SUCCEEDED |
| passing | 30093 | **30093** |
| constant_reg | 259 | 259 |
| failing / unverified / aborted / unmatched / blackbox_out | 0 | 0 / — / — / 0(0) / 0 |
| unread | 64（= dead_ref） | 64 |
| verdict | PARTIAL（Predictor 证书链） | **PARTIAL**：assembly_green_child_impl_golden_not_fm_target:Composer:data_mem_8x4 |

fm_verdict 拒绝出 receipt（receipt.json 不存在，证据目录只有 fm.log / sidecar / 报告），故无 receipt sha256，也不能跑 fm_predict check / 出 Frontend 证书。
剩余：§6.4 的两项公共核心改动（MC 模板覆盖 2R1W 带掩码 ram，或 Composer/TageBTable/Tage_SC/Predictor 不再共读 golden WrBypass_32；
validate_impl_golden_certified 的 `_seen` 共享）落地后，按 PROOF_COMMIT 重出受影响 child 的证书、重写 allow 的 Predictor sha，再跑一次 official。

