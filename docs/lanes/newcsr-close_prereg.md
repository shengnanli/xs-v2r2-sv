# newcsr-close lane（agent/newcsr-close）—— 跑前登记

本文件各节在**对应目标的 FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `e07b563e`（集成者预建 worktree + claim） |
| 工作树 | `/home/eda/xs-env/wt-newcsr-close`，分支 `agent/newcsr-close` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. 第一批：6 个叶 + CSRPermitModule

### 1.1 现状核查（为什么 5 个已有重写件没有有效 receipt）

VSstatusModule / VSiselectModule / VstartModule / VStimecmpModule / VtypeModule /
VirtualLevelPermitModule 的 rtl 来自 `5ccd73c6 newrtl-next200c: checkpoint recovered readable leaf
implementation`（那条 lane 崩溃后恢复的检查点）。仓里**没有任何 UT Makefile 的 FM_VARIANTS 含这 6 个名字**，
`docs/receipt_harvest.tsv` 也没有它们的行 —— 即从未建 UT、从未跑 FM，不是证过又 stale。
本 lane 新建 `verif/ut/NewcsrLeaves6` 补 UT + FM；RTL 只做两处改动：
VirtualLevelPermitModule 按 Scala 规则名重写成"一条规则一个 wire"（可读性，逻辑不变），
另 5 个只在文件头补 Scala 出处。

CSRPermitModule 之前没有重写件（MISSING），本 lane 新写：汇总逻辑手写，6 个子模块例化
（实例名同 golden、端口直连）。子模块两侧白盒：5 个已签（PROVEN_DIRECT）+ VirtualLevelPermitModule
本批签。

### 1.2 UT

- `verif/ut/NewcsrLeaves6`：6 对双例化，417 位输出逐拍比；9 档（seed 1/7/42 × initreg 0/random/<seed>017）
  各 200k 拍 errors=0；19/19 输出端口有翻转；13 类事件计数全部 >= NCYCLES/400。
  变异 10/10 抓到（VSstatus VS 优先级 / SIE 的 DTE 门控 / vstart 非零才置脏；VSiselect IMSIC 窗口边界；
  Vstart 清零条件；Vtype VILL 复位值；VStimecmp 低位；VLP 的 0x154 空洞 / VU 的 hcounteren / stimecmp wen）。
- `verif/ut/CSRPermitModule`：1 对双例化（各带 6 子模块），9 个 1 位输出逐拍比；9 档各 200k 拍 errors=0；
  9 个输出都取过 0 和 1；EX_II/EX_VI 的"直接"与"仅间接"路径、xRet 路径各 >= NCYCLES/1000。
  变异 5/5 抓到（间接结果的 direct 门控 / II 优先于 VI / direct_illegal 漏 VI / csrAccess 漏 ren / hasLegalWen 漏 VI）。

### 1.3 跑前预测（★跑完不许改本节★；登记见 docs/fm_predictions/*.json）

模型 = golden 寄存器位 + 顶层 output 位（`fm_predict.py model`，merge_dup=false）。

| 目标 | passing 预测 | 其余 |
|---|---|---|
| VSstatusModule | 84 (10+74) | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| VSiselectModule | 91 (13+78) | 同上 |
| VstartModule | 78 (7+71) | 同上 |
| VStimecmpModule | 192 (64+128) | 同上 |
| VtypeModule | 73 (9+64) | 同上 |
| VirtualLevelPermitModule | 2 (0+2) | 同上 |
| CSRPermitModule | 9 (0+9) | 同上（6 子模块两侧白盒，纯组合） |

### 1.4 明写可能出错的地方

1. VSstatus：impl 把 SDT 读出写成 `menvcfg_DTE & henvcfg_DTE & sdt_q`（两处），golden 同式；
   若 FM 把 rdata 里的常量位（38'h100 段，含 UXL=2）与 impl 拼接位序配错，会表现为 rdata 某位 failing。
2. Vtype 的 VILL 复位为 1：若 FM 把 impl 侧常量折叠后报 constant_reg，passing 会少 —— 差额按 receipt 指认。
3. 纯组合目标（VLP、CSRPermit）的 passing 只数输出位；子模块里的逻辑不产生额外比较点。

## 2. 第二批：NewCSR（★本节在 NewCSR 的 official FM 起跑之前提交★）

### 2.1 现状核查

仓（xs-v2-sv）里**没有** NewCSR 的重写件；任务描述里的 `rtl/backend/NewCSR.sv`/`scripts/gen_newcsr.py`/
"92 对称死 reg bijection" 都属于上一代工程 xs-v2r2-sv（V2R2 golden，296 端口，inst.svh 套壳），
golden 版本不同（G1 NewCSR 347 端口），不能复用。本 lane 从头写：

- `rtl/backend/NewCSR.sv`：手写胶合逻辑（特权态机、地址命中/写使能表、读数据与 regOut Mux、
  提交信息打拍、中断/HPM、trap 事件、触发器链、请求状态机与输出保持、flushPipe、状态/TLB/译码/AIA/difftest 输出）
  + 四段 GENERATED 连线（端口表、410 个实例输出线、277 个 regOut 字段打包视图、410 个实例）。
- `scripts/gen_newcsr.py`（带 `--check`）：只生成连线；含运算符的子模块连接一律映射到手写区的一根线（fail-closed）。
- child：379 种全部两侧白盒。impl 侧用 docs/coverage_three_axis.tsv 的 PROVEN_DIRECT 重写件 + 本 lane 新签的 6 叶与
  CSRPermitModule + HPerfMonitor_1（backend-misc 已出 PASS_DEAD_REF receipt evidence/6038c4afbc60）。
  PrintCommitIDModule 是纯仿真打印（codex 0205：不造空洞 FM 绿，不计 proven），两侧共读 golden .v。
  CommitIDModule 维持 codex 0205 裁定（端口契约 + UT，不计 proven），本 lane 不改。

### 2.2 UT（verif/ut/NewCSR）

双例化，4849 位输出逐拍比；预热写遍 337 个合法 CSR 地址（含 debug 模式下的 dpc/dscratch*、4 组触发器 tdata2），
每 NCYCLES/10 复位重预热；覆盖闸见 tb.sv 文件头。@ee5ca867 已跑 seed1/7 六档 200k errors=0（最终字节的 9 档在证明后补跑，结果追加在对账节）。

### 2.3 跑前预测（★跑完不许改本节★；docs/fm_predictions/NewCSR.json）

| 项 | 预测 |
|---|---|
| 模型 expected | 19847（regs 14951 + outs 4849） |
| passing | 19278 ~ 19362（诊断跑 19193 + fm_pins 钉上的 intrMod 85 点；mtopei/stopeiChange_REG 的 84 个常零位改同名后，或进 passing 或进 constant_reg） |
| unread（ref） | 142，全部在 verif/dead_ref/NewCSR.json 里逐条声明（继承子模块 80 + difftest trapNO 高位 62）；impl unread 0 |
| failing / unverified / unmatched / 黑盒 / dont_verify | 0 / 0 / 0 / 0 / 无 |
| verdict | PASS_DEAD_REF（native SUCCEEDED） |
| fm_predict check | passing + constant_reg + unread == 19847 |

### 2.4 明写可能出错的地方

1. fm_pins.tcl 是 fail-closed 的：若 intrMod 之外还有孤儿点（例如诊断跑里靠签名配上的重复寄存器换了配法），会直接 error，不出 receipt。
2. golden 的重复寄存器（每消费者一套的提交信息打拍、difftest 变化检测的两份 RegNext）与 impl 同构，靠签名区分；
   若签名配不上会表现为 unmatched，修法是改名或补钉点，不动逻辑。
3. 规模：诊断跑 1h+（匹配阶段占大头，机器负载 18/32）；按 30 分钟采样，3 小时不收敛即停。
