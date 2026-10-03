# storeunit-vsplit lane（agent/storeunit-vsplit）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `eec71f5c`（集成者预建 worktree + 认领文件） |
| 工作树 | `/home/eda/xs-env/wt-storeunit-vsplit`，分支 `agent/storeunit-vsplit` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标（按序） | `MemTrigger_3` → `StoreUnit` → `VSSplit*`/`VLSplit*` → `VSegmentTrigger`/`VSegmentUnit` |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. MemTrigger_3（golden 338 行，纯组合，无寄存器，无子模块）

### 1.1 核（★改了共享核★）

`rtl/memblock/MemTrigger.sv` 的 `xs_MemTrigger_core` 加 `isCbo` 输入与缓存行比较一支（`cboHit`），
端口 `load` 改名 `rwEnable`；LOAD wrapper（`MemTrigger`）把 `isCbo` 钉 0，逻辑锥不变。
新薄文件 `rtl/memblock/MemTrigger_3.sv`（STORE wrapper：`isPrf` 钉 0，`triggerMask` 悬空）。

`python3 scripts/check_shared_impl_impact.py --file rtl/memblock/MemTrigger.sv` ⇒ 受影响 2 个已签目标：
`MemTrigger`、`LoadUnit`，本 lane 一并重证（预测照搬它们原登记：70 / 18749，不应变）。

### 1.2 UT（跑前已跑）

verif/ut/MemTrigger_3：seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`, `+vcs+initreg+<seed>017`}
= 9/9 `checks=200000 errors=0 uncovered=0`。覆盖桶：每触发器 标量/向量/canFire/链上触发/被选中 ≥1，
cboHit × {EQ,GE,LT} 各 ≥1，三种 action 各 ≥1。
变异体（cbo GE 支 `cacheLineLast`→`cacheLineBase`）：20k 拍 `errors=478` 被抓。
回归 verif/ut/MemTrigger seed 7 两档 `errors=0`，compile.log AOUP=0。

### 1.3 跑前预测（★跑完不许改★）

| 项 | MemTrigger_3 | MemTrigger（重证） | LoadUnit（重证） |
|---|---|---|---|
| passing | **正好 54**（0 寄存器 + 输出 4+50） | 正好 70 | 正好 18749 |
| failing / unverified / aborted / unread_notcompared | 0/0/0/0 | 0/0/0/0 | 0/0/0/0 |
| unmatched | 全 0 | 全 0 | 全 0 |
| 黑盒 | 无 | 无 | 无 |
| verdict | signoff-strict SUCCEEDED | 同 | 同（vmucp=true，constant_reg 11） |

可能出错：核的 `triggerMask` 输出在 MemTrigger_3 里悬空——它是组合输出不是寄存器，不应产生
impl-only 比较点；若 FM 报 impl 侧 unread/unmatched，就把 mask 输出挂参数关掉。

## 2. StoreUnit（golden 2,203 行 / 447 端口 / 233 个寄存器 4021 位；唯一 child = MemTrigger_3）

### 2.1 核

`rtl/memblock/StoreUnit.sv`：`storeunit_pkg`（常量 / 译码与掩码小函数 / 接口 struct）+ `xs_StoreUnit_core`
（手写，s0 / s1 / s2 / s3+sx 各一节，每节开头写"做什么、依赖哪些输入"）+ golden 同名 wrapper。
机械派生区（接口 struct、核端口表、MemTrigger_3 例化、整包打拍寄存器字段表、导航、wrapper）与 tb 由
`scripts/gen_storeunit.py` 从 golden 端口表 / 寄存器表生成（`--check` 幂等；生成时核对：每个端口恰归一组
且同名字段位宽一致、golden 233 个寄存器 = 生成的 199 + 手写的 34 逐名一致、代码区无 firtool 展平名）。
寄存器一律保持 golden 展平名（FM 按名配对，无钉点）。子模块 MemTrigger_3 两侧白盒。
行数：golden 2,203 / impl 2,768（其中手写核约 700 行，其余是生成的 struct / 寄存器表 / wrapper 拆装）；
`_GEN_` / `_T_<n>` = 0 / 0。

本配置下 golden 里消失的东西（核里不写，文件头有说明）：store 硬件预取一路、DCache 写意图查询除
req_valid 外的端口、stout/vecstout.ready（恒 1 ⇒ ready 链恒通，核里保留写法、常量 `STOUT_READY`）、
vec_isFirstIssue（恒 1）、debug_ls、性能计数器。

### 2.2 UT（跑前已跑）

verif/ut/StoreUnit：双例化逐拍比 250 根输出。seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`,
`+vcs+initreg+<seed>017`}（非常量档 warmup 3000 拍）= 9/9 `checks=200000 errors=0 uncovered=0`。
28 个覆盖桶均有下限（三路来源 fire、s0 杀、cbo、跨 16B / 16B 内非对齐、needReplay、TLB miss 杀、
触发器断点 / debug、非对齐入队 / 被拒、s2 MMIO 杀、异常、访问异常、非对齐异常、revoke、缓冲回写、
不写回、s3/sx 杀、stout / vecstout、反馈命中 / 未命中）。
（跑完后只改过文件头导航的行号注释；proof commit 上再补跑一档确认，结果记在对账节。）

变异体（seed 1 × initreg+0 × 20k 拍，每个先确认文本变了且能编过）：

| 变异 | errors | 判定 |
|---|---|---|
| M1 needFlush 去掉 level 相等项 | 331 | CAUGHT |
| M2 s1_kill 不排除向量 | 89976 | CAUGHT |
| M3 异常掩码去掉 bit19 | 4033 | CAUGHT |
| M4 s2_frm_mab_vec 复位值 1→0 | 2 | CAUGHT（余量薄，换 seed 可能漏；复位域归 FM） |
| M5 s1_vecActive 复位值 1→0 | 0 | ★UT 漏（s1_valid 置位前必被写过）★ → FM 诊断跑实测 failing 1（passing 7482） |
| M6 基掩码 h 档 3→1 | 1186 | CAUGHT |
| M7 misalign_cango 去掉 needReplay | 18902 | CAUGHT |
| M8 needReplay 去掉 uopIdx 比较 | 5 | CAUGHT（余量薄） |
| M9 checkfullva 去掉向量 | 4283 | CAUGHT |
| M10 vstart 移位量写死 | 17485 | CAUGHT |
| M11 revoke 去掉 TLB miss 打拍项 | 2752 | CAUGHT |
| M13 访问异常去掉 cbo-MMIO 项 | 2190 | CAUGHT |
| M14 first_set_byte 漏一位 | 450 | CAUGHT |

### 2.3 非正式试跑（活动工作树未提交字节，`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，关 vmucp，不出 receipt）

native SUCCEEDED：passing 7399 / failing 0（未截断）/ unmatched 六项 0 / constant_reg 0 /
unread_notcompared 84（全部 matched_nc，两侧对称）→ strict 会判 PARTIAL。84 的逐类解释见
`verif/fm_target_config/StoreUnit.tcl`。耗时约 1 分钟，峰值低于 867 MB 地板。

### 2.4 跑前预测（★跑完不许改★，登记见 docs/fm_predictions/StoreUnit.json）

| 项 | 预测 |
|---|---|
| passing | **正好 7483**（模型 7483 = 寄存器 4021 + 输出 3462；差额 0） |
| constant_reg | 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0 |
| 黑盒 | 无（MemTrigger_3 两侧白盒） |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

可能出错：vmucp 打开后这 84 个死位若两侧次态函数不同会以 failing 出现，那就是真差异，按修 RTL 处理。

## 对账（跑后追加，不改上面任何数字）


## 3. VSplit 家族（7 个目标：skidBufferConnect / V{L,S}SplitPipelineImp / V{L,S}SplitBufferImp / V{L,S}SplitImp）

### 3.1 认领补充

`skidBufferConnect`（golden 1,265 行 / 278 端口 / 183 寄存器）是 VLSplitImp 与 VSSplitImp 共同的 child，
`docs/coverage_three_axis.tsv` 为 MISSING/UNPROVEN、无人认领（查过 `git worktree list` 各分支的 rtl 与 claim 文件），
按规范"UNPROVEN 的 child 本 lane 先重写签核"纳入本 lane（已追加到认领文件）。

### 3.2 核与 wrapper

| 文件 | 内容 | golden 行数 → impl 行数 |
|---|---|---|
| `rtl/memblock/vlsu_pkg.sv` | 向量访存公共包：常量、译码 / 掩码 / 步长 / 下标小函数、生成的接口 struct（uop_t / vls_t / …） | — / 421 |
| `rtl/memblock/VLSplitPipelineImp.sv` | `xs_VSplitPipeline_core`（手写，s0 译码 / s1 偏移与握手，`IS_VSTORE` 参数）+ load wrapper（生成） | 1,102 → 1,178 |
| `rtl/memblock/VSSplitPipelineImp.sv` | store 变体薄文件（wrapper 生成） | 1,090 → 808 |
| `rtl/memblock/VLSplitBufferImp.sv` | `xs_VSplitBuffer_core`（手写，§1–§5；store 的 vstd / 非对齐门控与 load 的 stop-and-wait 在 generate 分支）+ load wrapper | 1,470 → 1,665 |
| `rtl/memblock/VSSplitBufferImp.sv` | store 变体薄文件 | 1,539 → 1,336 |
| `rtl/memblock/skidBufferConnect.sv` | `xs_SkidBuffer_core`（手写：状态机与握手）+ wrapper（生成：逐字段暂存 + 二选一） | 1,265 → 907 |
| `rtl/memblock/VLSplitImp.sv` | `xs_VSplitImp_core`（手写胶水：skid 冲刷条件）+ load 装配壳（生成：三个子模块例化连线） | 2,316 → 1,595 |
| `rtl/memblock/VSSplitImp.sv` | store 装配壳 | 2,333 → 1,560 |

`_GEN_` / `_T_<n>` 全部 0 / 0。生成器 `scripts/gen_vsplit.py`（`--check` 幂等；公共件 `scripts/xs_structgen.py`）。
寄存器放置：核里是控制寄存器；整包 payload 寄存器（s1_in_r_* / uopq_* / dataBuffer_*）在各变体 wrapper 的生成段里
（两个变体 golden 的字段集合不同，字段集合照 golden 现数），核给出使能与装载值、读回 struct。寄存器全部保持
golden 展平名，FM 按名配对，无钉点。生成时核对：端口归组与位宽、golden 寄存器 = 生成 ∪ 核手写（逐名）、
skid 的 dataBuffer/out/in 字段一一对应、装配壳每个 pin 的连接只能是本层端口 / 子模块输出线 / 胶水核输出。

与 golden 对齐时查实的怪癖（都写在核注释里）：
1. 拆分流水 s1 的 unit-stride "usMaskLowActive" 取的是 usMask 高半（命名与 Chisel 一致，照抄）；
2. 拆分缓冲把 `uopq.usLowBitsAddr` 这个寄存器叫 `regOffset`（firtool 采用了 Chisel val 名），生成器用别名表处理；
3. load 拆分缓冲的 io.out.valid 不含 addrAligned（misalignedCanGo 恒真），store 的含非对齐缓冲门控；
4. 装配壳 skid 的 flush 看 "新 uop 正在进 skid" 还是 "skid 里的那条"；
5. skid 的 182 个暂存字段里 93 个上游恒 0（端口被消掉），但寄存器与输出端口还在：存 0、直通 0。

### 3.3 UT（`verif/ut/<目标>` 7 个目录，tb 由生成器生成）

跑前已跑：7 个目标各 seed 1 × `+vcs+initreg+0` × 20k 拍 `errors=0 uncovered=0`（首次即过，故按规矩做变异体自证）。
3 seed × 3 initreg × 200k 的矩阵与变异体矩阵在跑，结果记在对账节（跑在 proof commit 的同一份 RTL 字节上）。
覆盖桶：拆分流水 19 个（三种 mop、整寄存器 / mask 型 / segment / 特殊 indexed、nack、kill、
unit-stride 一次 / 两次访问、部分重放、等合并缓冲、被下游堵）；拆分缓冲 16+4 个（入队 / 占用时入队 / 入队被冲、
活跃发射 / 跳过、拆完、cancel、unit-stride 不拆 / 第二次、indexed / strided / 累加步长、部分重放、首活跃元素、
堵、指针绕回；load 加 stop-and-wait 四态，store 加 vstd / 已发数据 / 非对齐堵 / 非对齐放行）；skid 7 个；
装配壳 12+1 个。

### 3.4 非正式试跑（活动工作树未提交字节，`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，关 vmucp，不出 receipt）

| 目标 | passing | failing | unmatched | constant_reg | unread（全部 matched_nc） |
|---|---|---|---|---|---|
| skidBufferConnect | 3267 | 0 | 0 | 284（93 个恒 0 暂存字段） | 0 |
| VLSplitPipelineImp | 3895 | 0 | 0 | 1（s1_in_r_sew[2]） | 0 |
| VSSplitPipelineImp | 3887 | 0 | 0 | 1 | 0 |
| VLSplitBufferImp | 3076 | 0 | 0 | 0 | 78 |
| VSSplitBufferImp | 3422 | 0 | 0 | 0 | 80 |
| VLSplitImp | 7039 | 0 | 0 | 1 | 293 |
| VSSplitImp | 7572 | 0 | 0 | 1 | 100 |

unread 的逐类解释见 `verif/fm_target_config/{VLSplitBufferImp,VSSplitBufferImp,VLSplitImp,VSSplitImp}.tcl`。

### 3.5 跑前预测（★跑完不许改★，登记见 docs/fm_predictions/*.json）

| 目标 | 模型 expected | 预测 passing | 差额指认 | vmucp | 其余 |
|---|---|---|---|---|---|
| skidBufferConnect | 3551 | **3267** | constant_reg 284 | 否 | failing/unverified/aborted/unread 0，unmatched 六项 0，无黑盒，SUCCEEDED |
| VLSplitPipelineImp | 3896 | **3895** | constant_reg 1 | 否 | 同上 |
| VSSplitPipelineImp | 3888 | **3887** | constant_reg 1 | 否 | 同上 |
| VLSplitBufferImp | 3154 | **3154** | 0 | 是（+78） | 同上 |
| VSSplitBufferImp | 3502 | **3502** | 0 | 是（+80） | 同上 |
| VLSplitImp | 7333 | **7332** | constant_reg 1 | 是（+293） | 同上（三个子模块两侧白盒） |
| VSSplitImp | 7673 | **7672** | constant_reg 1 | 是（+100） | 同上 |

可能出错：vmucp 打开后对称死位若两侧次态不同会变 failing（那是真差异，修 RTL）；装配壳里子模块的
generate 分支寄存器（g_vload / g_vstore）若 FM 不能按名配上会落到签名匹配——试跑里 unmatched 已是 0。

## 4. VSegmentUnit（golden 3,556 行 / 240 端口 / 436 寄存器）+ VSegmentTrigger（219 行 / 41 端口 / 纯组合）

### 4.1 核

- `rtl/memblock/VSegmentTrigger.sv`：MemTrigger 共享核的第三个薄 wrapper（memType 现选 load/store 使能位，
  isCbo / isPrf / mask 钉 0，只留 triggerAction 输出）。UT `verif/ut/VSegmentTrigger`。
- `rtl/memblock/vsegment_pkg.sv`：segment 单元的接口 struct（生成）。
- `rtl/memblock/VSegmentUnit.sv`：`xs_VSegmentUnit_core`（手写 §1–§9：14 态状态机、逐元素地址与非对齐拆分、
  异常规则、load 数据拼接、store 送 sbuffer、指针推进、fof、写回）+ wrapper（生成：端口拆装 + payload 寄存器：
  uopq×8 / data×8 / stride×8 / instMicroOp.uop / fofBuffer（异步复位）/ 写回与反馈打拍，字段集合照 golden 现数）。
  golden 3,556 → impl 2,835 行；`_GEN_` / `_T_<n>` 0 / 0。生成器 `scripts/gen_vsegmentunit.py`（`--check`）。
  子模块两侧白盒：VSegmentTrigger（本 lane）、NewPipelineConnectPipe_33（已签核）。

与 golden 对齐时查实的怪癖（都写在核注释里）：instMicroOp.mask 用的是上一条指令留在 instMicroOp 里的
vm / vl / vstart（Chisel 读寄存器）；splitPtrOffset 与写回的 vdIdxInField 用的是入口 uop 的 fuOpType/lmul/emul；
触发器断点位改 trigger 时读的是寄存器旧值；instMicroOp.vstart 恒 0；第一条 uop 到达那一拍 stateNext 仍是 idle
时 instMicroOpValid 不置位，紧跟的下一条 uop 会再锁存一次（tb 的串内指令级字段因此必须一致）。

### 4.2 UT

VSegmentTrigger：seed 1/7/42 × 3 档 = 9/9 `checks=200000 errors=0 uncovered=0`（已跑完）。
VSegmentUnit（`verif/ut/VSegmentUnit`，37 个覆盖桶：14 个状态、TLB/DCache 重试、非对齐三种、跨 16B 两半、
三类异常、cache 错误、fof 压掉的异常、触发器两种动作、三种 mop、多 field、写回 / fof 写回 / 反馈 / 异常上报、
指针绕回）：跑前已跑 seed 1 × `+vcs+initreg+0` × 50k 与 seed 7 × `+vcs+initreg+random` × 30k 均
`errors=0 uncovered=0`；3×3×200k 矩阵与变异体在跑，记在对账节。

### 4.3 非正式试跑（关 vmucp，不出 receipt）

VSegmentTrigger：passing 4 / failing 0 / unmatched 0。
VSegmentUnit：native SUCCEEDED passing 12677 / failing 0 / unmatched 0 / constant_reg 1（instMicroOp_alignedType[2]）/
unread 22（全部 matched_nc，解释见 `verif/fm_target_config/VSegmentUnit.tcl`）；12434 按名 + 243 按签名配对；
耗时 2 分钟。

### 4.4 跑前预测（★跑完不许改★）

| 目标 | 模型 expected | 预测 passing | 差额指认 | vmucp | 其余 |
|---|---|---|---|---|---|
| VSegmentTrigger | 4 | **4** | 0 | 否 | 全零，SUCCEEDED |
| VSegmentUnit | 12700 | **12699** | constant_reg 1 | 是（+22） | failing/unverified/aborted/unread 0，unmatched 六项 0，无黑盒，SUCCEEDED |

### 对账 A：MemTrigger_3 / MemTrigger / LoadUnit（proof commit `2ef95566`，`evidence/2ef9556668e5/`）

| 目标 | 预测 passing | 实测 | failing/unverified/aborted | unmatched | constant_reg | 黑盒 / dont_verify | verdict | receipt.json sha256 |
|---|---|---|---|---|---|---|---|---|
| MemTrigger_3 | 54 | **54** | 0/0/0 | 0/0 | — | 0 / 无 | SUCCEEDED | `752d0ae574fac93e2d7ac4beddec151fc7a9fd2d0aa6153fd68c9cdd08b43516` |
| MemTrigger（重证） | 70 | **70** | 0/0/0 | 0/0 | — | 0 / 无 | SUCCEEDED | `0434e8114052a06062ba1d5ae0819bddd7534eec56b5bdab72e08e80d68c486f` |
| LoadUnit（重证） | 18749 | **18749** | 0/0/0 | 0/0 | 11 | 0 / 无 | SUCCEEDED | `6c6f969f3e683abe90245495353c0874d054d8d0e8285a4e12c7e121a44102bd` |

差额：三个都是 0。§1.3 写的风险（核的 `triggerMask` 输出在 MemTrigger_3 里悬空）没有发生：unmatched_impl 为空。
impl_closure：`MemTrigger.sv b9363f477dda…`、`MemTrigger_3.sv c9d684cbcb1e…`、`LoadUnit.sv c8d36a9b699c…`（未改）。
复跑：`PROOF_COMMIT=2ef95566 bash scripts/run_proof.sh <MemTrigger_3|MemTrigger|LoadUnit> <同名> < /dev/null`；
`python3 scripts/fm_predict.py check MemTrigger_3 MemTrigger LoadUnit`（rc=0）。

### 对账 B：StoreUnit（proof commit `519a79aa`，`evidence/519a79aab030/StoreUnit/`）

| 项 | 预测 | 实测 |
|---|---|---|
| passing | 7483 | **7483**（逐位相等） |
| failing / unverified / aborted | 0/0/0 | 0/0/0 |
| unread_notcompared | 0 | 0（vmucp 把 84 个对称死位转成 passing：7399 → 7483，正好 +84） |
| unmatched ref / impl | 0/0 | 0/0 |
| constant_reg | 0 | 无 |
| 黑盒 / dont_verify | 无 | 0 / 无 |
| verdict | SUCCEEDED | SUCCEEDED（signoff-strict） |

receipt.json sha256：`3e55c8fbdf7f309fdba6b5647c6f8276cdd3e60425717abb895a4f9c56214a78`；
impl_closure：`StoreUnit.sv e47d01ec61cb…` + `MemTrigger.sv` / `MemTrigger_3.sv`（同上）。
proof commit 上补跑的 UT 一档：seed 7 × `+vcs+initreg+random` `checks=200000 errors=0 uncovered=0`
（与 §2.2 的 9 档相比 RTL 只差文件头导航行号注释）。
复跑：`PROOF_COMMIT=519a79aa bash scripts/run_proof.sh StoreUnit StoreUnit < /dev/null`；
UT：`cd verif/ut/StoreUnit && make run SEED=<1|7|42> INITREG=<+vcs+initreg+0|+vcs+initreg+random|+vcs+initreg+<seed>017>`；
`python3 scripts/gen_storeunit.py --check`；`python3 scripts/fm_predict.py check StoreUnit`（rc=0）。

### 更正（跑证明之前，不改上面任何预测数字）：commit 7b1acd0b 混进了一个变异体

`rtl/memblock/VLSplitBufferImp.sv` 在 7b1acd0b 里的 store SQ 指针加法是变异体 B10（`ptrValue = 7'(sqSum[5:0])`，
丢了 56 项环形回绕）：提交时后台变异 harness 正在改同一个文件，`git add` 收进了变异中的字节。
影响面：只有含该文件的目标（VLSplitBufferImp / VSSplitBufferImp / VLSplitImp / VSSplitImp）；在 7b1acd0b 上
已出 receipt 的 VSegmentTrigger / skidBufferConnect / VLSplitPipelineImp / VSSplitPipelineImp 的 impl_closure
不含该文件，仍有效。下一个 commit 改回原文（`ptrWrap ? sqDiff : sqSum`），上述 4 个目标与 VSegmentUnit 在新 commit
上出证明；变异 / UT 矩阵作业今后不与 commit 并行（已扫描全部 rtl/memblock：其余文件无变异体文本残留）。

### 对账 C：VSplit 家族 7 目标 + VSegmentTrigger + VSegmentUnit

proof commit：VSegmentTrigger / skidBufferConnect / VLSplitPipelineImp / VSSplitPipelineImp 在 `7b1acd0b`
（impl_closure 不含被变异体污染的 VLSplitBufferImp.sv，见上节更正）；其余 5 个在 `a29b47bd`。全部 signoff-strict，
failing / unverified / aborted / unmatched 全 0，dont_verify 无，黑盒 0。`fm_predict.py check` 9 个目标 rc=0「全部对上」。

| 目标 | 预测 | 实测 passing | constant_reg | vmucp | receipt.json sha256 |
|---|---|---|---|---|---|
| VSegmentTrigger | 4 | **4** | — | 否 | `a6525426e288d103a3a591c3f052c7262a00148c7e6d243b66cb620d6bb89fda` |
| skidBufferConnect | 3267 | **3267** | 284 | 否 | `73d31b8ac0173645ac5079cdec38b183e19fb805901f7242cce2fb5daa9f8589` |
| VLSplitPipelineImp | 3895 | **3895** | 1 | 否 | `d0a698c5e9c3ccd61a0a38d22f260e2ce471051af07dc55a91ef3f4257a507d5` |
| VSSplitPipelineImp | 3887 | **3887** | 1 | 否 | `ed892c79acb50fed3a6930610fa9764cd83bff01f449c0b14cc4c8ecace770e0` |
| VLSplitBufferImp | 3154 | **3154** | — | 是 | `c70f18730843ca83def821e8620459a69b0dd9f4f67b15978ea6cad4989f6568` |
| VSSplitBufferImp | 3502 | **3502** | — | 是 | `5bfd6108e25e154fba35f260225225f34b02e63707b661ec49b7fd8e59833ea0` |
| VLSplitImp | 7332 | **7332** | 1 | 是 | `191210d8d81f7370b1450b7770c731a5fea49a97a65e7e4812464ffff7e0849f` |
| VSSplitImp | 7672 | **7672** | 1 | 是 | `5f6eb3a5ef61eb8308f32440f9483c0379fa7d445ea27cb4b385947f85eed850` |
| VSegmentUnit | 12699 | **12699** | 1 | 是 | `2b9c0f96650ec0c7be660c3884bfc47af9d581c58ff27634996ea81d3d8988cd` |

差额全部为 0；每个 vmucp 目标的 passing 增量正好等于试跑的 unread 数（78 / 80 / 293 / 100 / 22）。

UT（a29b47bd 字节，工作树 clean）：8 个目录（7 个拆分家族 + VSegmentUnit）× seed 1/7/42 × {+0, +random, +<seed>017}
= 72/72 `checks=200000 errors=0 uncovered=0`；VSegmentTrigger 9/9 同（见 §4.2）。

变异体（seed 1 × +0 × 20k 拍；先确认 OLD 文本恰出现一次、编译失败判 COMPILE_FAIL）：
- 拆分流水 11 个：两个变体各 11/11 CAUGHT（P7 在 vlsu_pkg 上另跑，560 CAUGHT）。
- 拆分缓冲 15 个：store 变体 13 CAUGHT；B11（LQ 回绕）/ B12（stop-and-wait）只在 load 变体的 generate 分支里，
  load 变体 CAUGHT（9292 / 726867）。load 变体 MISSED 的 B6 / B10 / B13 / B14 都在 store 专属路径（load 里不可观测），
  store 变体分别 CAUGHT（341835 / 8774 / 59 / 2125；B13 余量薄）。B3（index 取 16 位那一档）在 vlsu_pkg 上 67498 CAUGHT。
- skid 3/3 CAUGHT。
- 装配壳 S1 / S2 两个变体 UT 都 MISSED → FM 诊断跑：S1 SUCCEEDED（等价变异体：skid 空态时输出口就是输入口，
  两种取法同值），S2（冲刷判定去掉 level 相等项）FAILED failing 1 —— FM 覆盖。
- VSegmentUnit 20 个：13 CAUGHT；7 个 UT MISSED，FM 诊断跑：V9 failing 4 / V14 failing 8 / V15 failing 8 /
  V16 failing 22 / V17（复位值）failing 1 —— FM 覆盖；V5（高 8 字节窗口改成整体右移 64+8k）与 V11（curPtr 翻转少一个
  条件，被前一分支的复位优先覆盖）FM SUCCEEDED，属等价变异体。V9 / V16 漏在 UT 是因为 tb 只在单元空闲时起新指令，
  "入口 uop 与在做的指令不同"的情形不出现（这正是 golden 用入口字段的怪癖），归 FM 管。
