# LoadUnit lane（agent/loadunit）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（main，`git worktree add /home/eda/xs-env/wt-loadunit -b agent/loadunit 975b64e6`） |
| 工作树 | `/home/eda/xs-env/wt-loadunit`，分支 `agent/loadunit` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `MemTrigger`（LoadUnit 唯一 child，先做）→ `LoadUnit` |
| 变体 | golden 只有一个 `LoadUnit`（MemBlock 里 inner_LoadUnit_0/1/2 三个实例同一模块）；`MemTrigger_3` 属 StoreUnit，不在本 lane |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. MemTrigger（golden 284 行，纯组合，无寄存器，无子模块）

### 1.1 核

`rtl/memblock/MemTrigger.sv`：`xs_MemTrigger_core`（4 触发器数组化：标量/向量命中 → 链 →
动作仲裁 → 最小编号回报）+ golden 同名 wrapper（手写打包，43 端口）。

### 1.2 UT（跑前已跑，两档 × 3 seed × 200k）

verif/ut/MemTrigger：seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`} = 6/6
`checks=200000 errors=0`、`uncovered=0` TEST PASSED。GE→GT 变异体 20k 拍内被抓住。

### 1.3 跑前预测（★跑完不许改★）

| 项 | 预测 |
|---|---|
| passing | **正好 70**（模型 = 0 寄存器 + 70 输出位：4+50+16） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 全 0（纯组合，只有端口） |
| 黑盒 | 无 |
| mode / verdict | signoff-strict / SUCCEEDED |

可能出错的地方：无寄存器、无常量折叠点，模型不应有差额；若有差额只能来自输出位被 FM 判常量，
receipt 里应能指认。

## 2. LoadUnit（golden 13,028 行 / 2429 端口 / 957 个寄存器 9361 位；唯一 child = MemTrigger）

### 2.1 核

`rtl/memblock/LoadUnit.sv`：`loadunit_pkg`（常量 / FlowSource / 纯函数）+ `xs_LoadUnit_core`（手写，
s0/s1/s2/s3 各一节，每节开头写"做什么、依赖哪些输入"）+ golden 同名 wrapper。
机械派生区（接口 struct、核端口表、整包打拍寄存器字段表、导航、wrapper）与 tb 由
`verif/ut/LoadUnit/gen_loadunit.py` 从 golden 端口表 / 寄存器表生成（`--check` 幂等；生成时核对：
每个端口恰归一组且位宽相等、golden 957 个寄存器 = 生成的 839 + 手写的 118，逐名一致）。
寄存器一律保持 golden 展平名（按名配对），`_GEN_`/`_T_` = 0。子模块 MemTrigger 两侧白盒。

### 2.2 UT

verif/ut/LoadUnit：双例化逐拍比 1027 根输出；激励与覆盖判据见 tb_template.py 文件头。
跑前已有：seed 1 × `+vcs+initreg+0` 200k `errors=0 uncovered=0`。其余 5 档在跑，结果记在对账节。
（实测注记：本机 VCS W-2024.09-SP1 运行期 `+vcs+initreg+random` 把两个实例的不复位寄存器都初始化成
全 1 —— 两侧一样；真正"各摇各的"要用 `+vcs+initreg+<seed>`，已加做 3 档并配 3000 拍 warmup。）

### 2.3 非正式试跑（scratch detached worktree @968025e4，关 vmucp，不出 receipt）

native SUCCEEDED：passing 18660 / failing 0（FM_FAILING_LIMIT=0，未截断）/ unmatched 六项 0 /
constant_reg 11 / unread_notcompared 89 → strict PARTIAL。unread 89 的逐类解释见
`verif/fm_target_config/LoadUnit.tcl`。耗时 171 s，峰值 1164 MB。

### 2.4 跑前预测（★跑完不许改★，登记见 docs/fm_predictions/LoadUnit.json）

| 项 | 预测 |
|---|---|
| passing | **正好 18749**（模型 18760 = 寄存器 9361 + 输出 9399；差额 11 = constant_reg） |
| constant_reg | 11：s1_try_ptr_chasing_last_REG、s1_kill_last_REG、io_s2_ptr_chasing_r（指针追逐关闭）、io_perf_1_value_REG{,_1}、MMIO 包三级打拍里的 debug_isNCIO / debug_isPerfCnt（各 3 位） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0 |
| 黑盒 | 无（MemTrigger 两侧白盒） |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

可能出错：vmucp 打开后这 89 个死位若在两侧的次态函数不同（本应相同——同名同源照写）会以 failing 出现，
那就是真差异，按修 RTL 处理。
