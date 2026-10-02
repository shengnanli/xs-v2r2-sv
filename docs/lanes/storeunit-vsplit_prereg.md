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
