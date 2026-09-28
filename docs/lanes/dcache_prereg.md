# dcache lane（agent/dcache）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `785649ac`（main，`git worktree add /home/eda/xs-env/wt-dcache -b agent/dcache main`） |
| 工作树 | `/home/eda/xs-env/wt-dcache`，分支 `agent/dcache` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | DCache（golden 23,854 行）的未签核 child → DCache 本体 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |
| codex 冲突 | 第 0 步已查：outbox 最新 codex_0197（50 个 Pmpaddr/Pmaaddr31/ShiftRightJam*/RightShift*）与 18 个 codex/* 分支对 main 的 diff 均未触及本 lane 任何目标及其 child |

## 1. 第一批：小 child（纯组合 / 小状态机）

### 1.1 结构与子模块处置

| 目标 | 重写件 | 说明 | child |
|---|---|---|---|
| Arbiter1_TagWriteReq | rtl/memblock/Arbiter1_TagWriteReq.sv | 单入 Arbiter = 直通 | 无 |
| Arbiter1_L1BankedDataWriteReq | rtl/memblock/Arbiter1_L1BankedDataWriteReq.sv | 同上（数据半边） | 无 |
| Arbiter1_L1BankedDataWriteReqCtrl（×8 例化） | rtl/memblock/Arbiter1_L1BankedDataWriteReqCtrl.sv | 同上（地址半边） | 无 |
| TreeArbiter | rtl/memblock/TreeArbiter.sv | 复用 `xs_FixedPriorityArbiter_core`（核未改）；缺字段填 0 | 无 |
| MissReadyGen | rtl/memblock/MissReadyGen.sv | 逐口 ready = MQ ready & 无更高优先级 valid | 无 |
| PrefetcherMonitor | rtl/memblock/PrefetcherMonitor.sv | 窗口计数 + 开关状态机 | 无 |
| FDPrefetcherMonitor | rtl/memblock/FDPrefetcherMonitor.sv | golden 0 输出 0 寄存器（见 §1.4） | 无 |
| Queue1_RegMapperInput_6 | rtl/memblock/Queue1_RegMapperInput_6.sv | 薄变体，核 `xs_Queue1_RegMapperInput`（rtl/frontend/ICacheCtrlUnit.sv，与 _5 共用，核未改） | 无 |
| CtrlUnit | rtl/memblock/CtrlUnit.sv | 伪错误注入寄存器外设 | Queue1_RegMapperInput_6（本 lane）、NewPipelineConnectPipe_27 ×2（PROVEN_DIRECT）→ 两侧白盒 |
| CounterFilter | rtl/memblock/CounterFilter.sv | 15 项去重 FIFO | 无 |

`xs_FixedPriorityArbiter_core` 要求 NUM_IN>=2，三个单入仲裁器不用核（与已签的 Arbiter1_InsUncacheResp 同法）。

### 1.2 UT（3 seed × 3 initreg × 200k 拍，全部串行）

tb 由各目录 gen.py 生成（共用 `scripts/dual_tb_lib.py`：端口表读 golden、每拍逐位 `!==` 比全部输出、
每个输出位须见过 0/1、各对分支计数闸；不复位数据寄存器用 arm 条件"写过一次后才比"）。

| UT 目录 | 目标 | commit | 9 档结果 |
|---|---|---|---|
| DCacheLeaves | 3×Arbiter1 / TreeArbiter / MissReadyGen / PrefetcherMonitor / FDPrefetcherMonitor | aec7dfd6 | 9/9 checks=11399544 errors=0 cov_fail=0 |
| CtrlUnit | CtrlUnit（+ Queue1 回归对） | aec7dfd6 | 9/9 errors=0 cov_fail=0（checks 6755814..6788782） |
| Queue1_RegMapperInput_6 | Queue1_RegMapperInput_6 | 0354a9ea | 见对账 |
| CounterFilter | CounterFilter | 0354a9ea | 见对账 |

覆盖（seed 42 random 档）：TreeArbiter 各路胜出 68457/44105/30532/23307、无人请求 33591、背压 83555；
MissReadyGen 被压住 25280/12658/6345；PrefetcherMonitor 及时性窗口结束 149、有效性窗口结束 130、
trigger_disable 45、只 late_hit 27、late_miss 压住 late_hit 95、退避恢复 1；
CtrlUnit tag/data 通道 fire 14378/16187、延迟递减 13271、persist 重装 2373、写 ctrl/delay/mask7 1839/1946/1828、
部分字节写 7037、读 12342。
UT 结构上到不了的：PrefetcherMonitor 的 conf_reset（要连续低置信 200000 拍），归 FM。

UT 抓到并已修的真错：PrefetcherMonitor 初稿 `N'(~enable)`（按赋值语境先扩位再取反，得 0x3FFFE 而非 0/1），
seed 1 第 120489 拍 enable 失配。

复跑：`cd verif/ut/<目录> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 expected = golden 闭包寄存器位 + 顶层 output 位（merge_dup=false）。

| 目标 | expected | passing 预测 | 其余 |
|---|---|---|---|
| Arbiter1_TagWriteReq | 49 | **49** | failing/unverified/unmatched/unread 全 0，无黑盒，SUCCEEDED |
| Arbiter1_L1BankedDataWriteReq | 521 | **521** | 同上 |
| Arbiter1_L1BankedDataWriteReqCtrl | 53 | **53** | 同上 |
| TreeArbiter | 981 | **981** | 同上 |
| MissReadyGen | 412 | **412** | 同上 |
| PrefetcherMonitor | 96 | **96** | 同上 |
| Queue1_RegMapperInput_6 | 169 | **169** | 同上 |
| CounterFilter | 204 | **204** | 同上 |
| CtrlUnit | 2493 | **2493** | vmucp 开（verif/fm_target_config/CtrlUnit.tcl）：unread 455 → 0；钉点 1040/1040；其余全 0 |

非正式试跑（活动工作树 `make fm-*`，不出 receipt）：CtrlUnit（vmucp 关）2038 + unread 455（钉点前全部
unmatched unread，钉后全部 matched_nc），vmucp 开 2493；Queue1_RegMapperInput_6 169；CounterFilter 204。
其余 6 个未试跑，数字纯按模型。

### 1.4 FDPrefetcherMonitor 与 StorePipe 的处置（不跑 FM）

- **FDPrefetcherMonitor**：golden 在 KunminghuV2Config 下 0 输出、0 寄存器（`io.pf_ctrl := DontCare`，
  全部计数器只供 XSPerf，firtool 全删），FM 无比较点。重写件只保留逐位一致的端口表；
  端口契约 `make -C verif/ut/DCacheLeaves portlint-fdp`；两侧在 UT 里一起 elaborate。
  不列入 FM_VARIANTS，不出 receipt，台账如实保持 UNPROVEN（与 StorePipe 同类）。
- **StorePipe**：仓里已有处置记录——`docs/fm_predictions/StorePipe.json`（model_applicable=false）、
  `docs/closure_symmetry_ledger.tsv`（SPECIAL：golden 为 DCE 塌缩探针壳）、rtl/memblock/StorePipe.sv（NO_OUTPUT，
  wrapper 与 golden 同为 1 输入 0 输出）。照记录办，本 lane 不硬证。

## 对账

（跑完追加）

### 第一批对账（run_proof @ 414ed06a，evidence/414ed06a79c5/<目标>/）

UT 补记：Queue1_RegMapperInput_6 在 0354a9ea 的 9 档里有一项覆盖闸（同拍进出）结构上不可能
（enq_ready = ~full，deq 只在 full 时）→ 9/9 cov_fail=1；66215d30 去掉该项、改为中途复位覆盖，
重跑 9/9 checks=1599936 errors=0 cov_fail=0。CounterFilter @ 0354a9ea 9/9 checks=599976 errors=0 cov_fail=0。

| 目标 | 预测 passing | 实测 passing | 差 | failing / unmatched / unread / 黑盒 / dont_verify | receipt.json sha256 |
|---|---|---|---|---|---|
| Arbiter1_TagWriteReq | 49 | 49 | 0 | 0 / 0 / 0 / 无 / false | `9fabe86d2d3907e85fcf8aae3308d5cda183c6f60cb1c1774535a29580437ff4` |
| Arbiter1_L1BankedDataWriteReq | 521 | 521 | 0 | 同上 | `ea3cbb54e73e6375b9ed156319063ba4a4005eb87a63489194512eec06cd76a8` |
| Arbiter1_L1BankedDataWriteReqCtrl | 53 | 53 | 0 | 同上 | `8095bdf3eb1d4a417738e2e9264bf253953ae4eb415b242bc05d32b04ecc467b` |
| TreeArbiter | 981 | 981 | 0 | 同上 | `e6cff906e9ad16f674738cf49523da43f4d7a96238c27ebd2a510a91d49e8b42` |
| MissReadyGen | 412 | 412 | 0 | 同上 | `a32ca698792409734191e89ecc1b9e529d094d691f1f6342908236ecabf485a3` |
| PrefetcherMonitor | 96 | 96 | 0 | 同上 | `6b46a188dfdfa60aae0cb0d6b4e23e2d50f913caa09c1adfd6e6d4d1a8e043eb` |
| Queue1_RegMapperInput_6 | 169 | 169 | 0 | 同上 | `608bd3906477cf686e2fa3e4973501c60d3a5f8111540d2fb20c83aa1164ad5c` |
| CounterFilter | 204 | 204 | 0 | 同上 | `1443facfc655e80ea9d5c125bf21f335a5f01aeaf0c1e925dc8e0c56f13e152b` |
| CtrlUnit | 2493 | 2493 | 0 | 0 / 0 / 0（vmucp 实比 455）/ 两侧白盒 / false | `07294d5481ebeab3f90f479974c4e3ef61a1548421f5d0ceb00195cb782572e8` |

全部 native SUCCEEDED、verdict SUCCEEDED（signoff-strict）；`fm_predict.py check` 9/9「全部对上」。
复跑：`bash scripts/run_proof.sh DCacheLeaves <6 个目标> < /dev/null`、
`bash scripts/run_proof.sh {Queue1_RegMapperInput_6,CounterFilter,CtrlUnit} <同名> < /dev/null`
（PROOF_COMMIT=414ed06a）。

变异自检（scratch 沙箱，seed 7 random 30k 拍；短跑下覆盖闸必然不满，只看 errors）：
DCacheLeaves 9 个：8 CAUGHT；L9（PrefetcherMonitor 低置信计数改加 ~enable）SURVIVED ——
enable 与 confidence 在 3 万拍内同进同退（分叉要到 10 万拍的退避恢复），归 FM（下一状态函数不同，寄存器比较点必失配）。
CtrlUnit 5 个：4 CAUGHT；C5（tag 通道打拍件第 3 组掩码接错）SURVIVED —— 那组输出在 CtrlUnit 里悬空，
UT 结构上看不见；FM 经钉点 + vmucp 真比较这 455 位，覆盖之。
CounterFilter 5 个：4 CAUGHT；F5（入队写项口序反转）为等价变异（同拍各口分配指针两两不同，不会写同一项）。

## 2. 第二批：LoadPipe / TagSRAMBank / TagArray / DuplicatedTagArray（跑前登记，FM 起跑前提交）

### 2.1 结构与子模块处置

| 目标 | 重写件 | child 处置 |
|---|---|---|
| LoadPipe（×3 例化） | rtl/memblock/LoadPipe.sv（loadpipe_pkg：权限表 growStarter / SECDED 检错 / OHToUInt；§1..§6 按 s0..s3 分节） | 无子模块 |
| TagSRAMBank | rtl/memblock/TagSRAMBank.sv（上电逐组清零 + 单口写优先） | SRAMTemplate_116（PROVEN_DIRECT）两侧白盒；其下 sram_array_*_dcsh_tag / array_8 / MbistClockGateCell / ClockGate 两侧同源；唯一黑盒 array_8_ext（vendor_boundary 已审定） |
| TagArray | rtl/memblock/TagArray.sv（2 个 TagSRAMBank 拼 4 路） | TagSRAMBank（本 lane）+ 同上 |
| DuplicatedTagArray | rtl/memblock/DuplicatedTagArray.sv（沿用已有重写核；本 lane 只改注释） | TagArray/TagSRAMBank（本 lane）、MbistPipeDcacheTag（PROVEN_DIRECT，rtl/dft）、SRAMTemplate_116；黑盒只有 array_8_ext ×8 |

DuplicatedTagArray 上一版 impl 直接读 golden TagArray/TagSRAMBank/SRAMTemplate_116/MbistPipeDcacheTag
（golden 逻辑复用），本批起 impl 侧全部换成重写件。

三个 SRAM 目标的 FM 口径：`FM_MODE=assembly`（黑盒逐对象声明 verif/allow/<目标>.json，declare_allow.py
由实跑生成，只含 array_8_ext，class=vendor_macro），**merge_dup 保持工具默认（开）**：共享核
xs_SRAMTemplate_core 的 rdata_last_REG 在 holdRead 关时与 respReg 同方程，靠合并消掉（关掉合并时实测
TagSRAMBank 1 / TagArray 2 / DuplicatedTagArray 8 个 impl 独有 unread）；与 SRAMTemplate_* 自身签核同口径。
代价：fm_predict 模型对这三个目标判 MODEL_NA（不给绿也不给红），预测按试跑数字登记。

### 2.2 UT

| UT 目录 | 目标 | commit | 结果 |
|---|---|---|---|
| LoadPipe | LoadPipe | bdd4281b | 9/9 errors=0 cov_fail=0（checks 14999025..14999100） |
| TagArray | TagSRAMBank + TagArray | 见对账 | seed 7 random 试跑 checks=2197049 errors=0 |
| DuplicatedTagArray | DuplicatedTagArray | 见对账 | seed 7 random 试跑 checks=3794908 errors=0 |

LoadPipe 覆盖（seed 42 random）：s1 命中 57171 / 命中无权限 4812、s2 真缺失 27774、miss 发出 14116、
no_mshr 8398、data nack 20515、tag ECC 错 28276、BtoT 3692 / BtoT 占路失败 962、handled 6039、
tag 伪错误 2883、128 位数据错 2735、预取命中计数 14068 / 被过滤 13983、污染 3037。
UT 结构上恒 0 的输出位（行地址低 6 位、perf 高 5 位）豁免 0/1 覆盖。

### 2.3 跑前预测（★跑完不许改本节★）

| 目标 | passing 预测 | 其余 | 依据 |
|---|---|---|---|
| LoadPipe | **1311**，constant_reg **1**（REG_4 恒 1） | vmucp 开（62 对对称死位，verif/fm_target_config/LoadPipe.tcl）→ unread 0；failing/unmatched 0；无黑盒；signoff-strict SUCCEEDED | 模型 1312 = regs 554 + outs 758；非正式试跑 1311 + const 1 |
| TagSRAMBank | **369** | assembly；黑盒 2（array_8_ext 两侧各 1）；unread 0；failing/unmatched 0 | 试跑（merge 默认）369 |
| TagArray | **737** | assembly；黑盒 4；其余同上 | 试跑 737 |
| DuplicatedTagArray | **2460** | assembly；黑盒 16；vmucp 开（10 对 MBIST 地址打拍死位）→ unread 0 | 试跑 2460 |

### 第二批对账（run_proof @ b25ad3da，evidence/b25ad3da9f18/<目标>/）

UT 9 档：LoadPipe @ bdd4281b 9/9 errors=0 cov_fail=0；TagArray（TagSRAMBank+TagArray 两对）@ b25ad3da 9/9 errors=0
cov_fail=0（checks 2196988..2197051）；DuplicatedTagArray @ b25ad3da 9/9 errors=0 cov_fail=0（checks 3794851..3794908；
跑时工作树有与本目标无关的未跟踪 rtl/memblock/DataSRAMBank*.sv，本目标闭包文件未改）。

| 目标 | 预测 | 实测 | 差 | 其余 | receipt.json sha256 |
|---|---|---|---|---|---|
| LoadPipe | 1311 + const 1 | passing 1311，constant_reg 1 | 0 | signoff-strict；failing/unmatched/unread 0；无黑盒；vmucp 实比 61 | `ae13f8cd79300b0a2c7b8d5acc56fc6dac21b836b5e6dcd807f5e9de0aa934a7` |
| TagSRAMBank | 369 | 369 | 0 | assembly；黑盒 2（array_8_ext）；unread 0 | `eb553b56f225776dc291f94c85884f7a288e8a715da9cb2c0694527dd8bbffac` |
| TagArray | 737 | 737 | 0 | assembly；黑盒 4；unread 0 | `8d77bda801fa9880b6cca7cbfcd14786e681ff418566f5d428153e627c2126e3` |
| DuplicatedTagArray | 2460 | 2460 | 0 | assembly；黑盒 16；vmucp 实比 10；unread 0 | `bd34b7bf457db0e62eef5da626050b62e0927f9c5f02c99089684a435fa8b12e` |

全部 verdict SUCCEEDED；`fm_predict.py check` 4/4「全部对上」（后三者模型 MODEL_NA，按登记数字对账）。
复跑：`PROOF_COMMIT=b25ad3da bash scripts/run_proof.sh {LoadPipe LoadPipe | TagArray TagSRAMBank TagArray | DuplicatedTagArray DuplicatedTagArray} < /dev/null`

## 3. 第三批：DataSRAMBank 家族（DataSRAMBank / _1 / _2 / _4）（跑前登记，FM 起跑前提交）

### 3.1 结构与子模块处置

- 可读核 `xs_DataSRAMBank_core`（写使能按路译码 + "写最多一路"检查）在 rtl/memblock/DataSRAMBank.sv；
  4 个 wrapper 由 `scripts/gen_datasrambank.py`（--check）从 golden 端口表与 golden 的 SRAMTemplate 例化生成
  （DataSRAMBank.sv 里是 GENERATED 区，_1/_2/_4 整文件）。变体差别只有"每路例化哪个 SRAMTemplate_N"
  （84/86、88、92、100——MBIST array id 位宽不同）与 bore*_array 端口位宽。
- child：SRAMTemplate_84/86/88/92/100（PROVEN_DIRECT）两侧白盒；其下 sram_array_1p256x72m72s1h0l1b_dcsh_dat /
  array_7 / MbistClockGateCell / ClockGate 两侧同源；唯一黑盒 array_7_ext ×4（vendor_boundary 已审定），
  声明 verif/allow/DataSRAMBank*.json（declare_allow.py 由试跑生成，各 8 个对象 = 两侧各 4）。
- FM：assembly、merge_dup 默认、vmucp 开（唯一 unread = 断言寄存器 REG，verif/fm_target_config/DataSRAMBank*.tcl）。

### 3.2 UT（verif/ut/DataSRAMBank，4 对同 tb）

阵列无上电清零：tb 前 400 拍把 0..7 组各路写满、MBIST 关，读写地址（含 MBIST 地址）压到 0..7，
之后才比（arm）。试跑中 seed 7 random 曾报失配，定位为 tb 的 MBIST 随机地址读到**没写过**的组
（两侧厂商宏行为模型各自随机初值），把 MBIST 地址也压到 0..7 后消失——不是 RTL 差异。
9 档结果见对账。

### 3.3 跑前预测（★跑完不许改本节★）

| 目标 | passing 预测 | 其余 |
|---|---|---|
| DataSRAMBank | **1205** | assembly；黑盒 8（array_7_ext 两侧各 4）；vmucp 后 unread 0；failing/unmatched 0 |
| DataSRAMBank_1 | **1205** | 同上 |
| DataSRAMBank_2 | **1205** | 同上 |
| DataSRAMBank_4 | **1205** | 同上 |

依据：非正式试跑（DataSRAMBank/_1 vmucp 关 1204 + unread 1；_2/_4 vmucp 开 1205）；模型 1205（MODEL_NA，merge 开）。

### 第三批对账（run_proof @ 754c1d99，evidence/754c1d99ea72/<目标>/）

UT：DataSRAMBank（4 对同 tb）@ 8554930b 9/9 checks=6387104 errors=0 cov_fail=0。

| 目标 | 预测 | 实测 passing | 差 | 其余 | receipt.json sha256 |
|---|---|---|---|---|---|
| DataSRAMBank | 1205 | 1205 | 0 | assembly；黑盒 8（array_7_ext）；unread 0（vmucp 实比 REG） | `43f1c0e1588bae9f8f321246e6d49a32c2700bc9ea680ec11ff25a398c150bb9` |
| DataSRAMBank_1 | 1205 | 1205 | 0 | 同上 | `8f621beb05a9ba9f59e90c52e96160549a3a358dd7f06283599076281a4a6661` |
| DataSRAMBank_2 | 1205 | 1205 | 0 | 同上 | `f87b2c0e2ad268f980621cc806faa1f43db92af94e580ea4acb6212fdee5f94f` |
| DataSRAMBank_4 | 1205 | 1205 | 0 | 同上 | `b161aa8983f16c37b3a37725889601bdea113b130eb2059329ddcc0f371ccb21` |

全部 verdict SUCCEEDED；`fm_predict.py check` 4/4「全部对上」。
复跑：`PROOF_COMMIT=754c1d99 bash scripts/run_proof.sh DataSRAMBank DataSRAMBank DataSRAMBank_1 DataSRAMBank_2 DataSRAMBank_4 < /dev/null`
