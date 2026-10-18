# ledger-0238：三轴轴一优先级 + incl_cone（Rob 逐条核验）

codex 0238 两条裁定的落地记录。分支 `agent/ledger-0238`，基于 main `dabf1cda0`。
派生表（`docs/*.tsv`）**不在本分支提交**，由集成者用新生成器重出；下面的数字是本 worktree 本地重算的。

## 裁定 1：`coverage_three_axis.py` 轴一

**问题**：旧逻辑 `a1 = 'GOLDEN_REUSE' if m in reuse else floor...`，`reuse` 取自所有 UT 的
`RTL_GOLDEN_DEPS`。XSCore/XSTile 的 UT 把 golden 整棵子树当仿真依赖读进来，于是 1600 个模块
被盖成 GOLDEN_REUSE，其中 1561 个 rtl/ 里有定义 —— 轴一不再回答「有没有可读实现」。

**改法**：

- 判档顺序 `axis1()`：VENDOR_BOUNDARY > rtl/ 有定义走 rewritten_floor > impl 侧读 golden → GOLDEN_REUSE > MISSING。
  rtl/ 有定义但 floor 判 SKELETON/PARTIAL_DRIVE 的照 floor 落档，不会被抬成 REWRITTEN。
- 新列 `golden_used_by`（第 5 列）：impl 侧仍直接读该模块 golden 文件的
  - `ut:<目录>` —— UT 的 `RTL_GOLDEN_DEPS`，**用 make 展开**（旧正则漏了 35 个 `$(addprefix ...)` 间接写法，
    还把 `$(XSSV_HOME)/rtl/...`、`$(RTL_DIR)/...` 本地件当成 golden 记账）；按路径里有 `/golden-rtl/` 认 golden；
  - `fm:<top>` —— 已跟踪、通过、非 provisional/dirty 的 receipt，每个 top 取最新一份（run_id 时间戳），
    `impl_closure` 里 `kind=golden` 的条目。
  这一列非空的 run 都**不是纯重写 run**；「rtl 有定义」不是它被实际用上的证据。
- 正反测 `scripts/test_coverage_three_axis_priority.py`（20 条，进 gate_all）。

**前后对比**（分母 1814；核内 = XSTile 闭包里的 1563 个）：

| 轴一档 | 旧·全体 | 新·全体 | 旧·核内 | 新·核内 |
|---|---|---|---|---|
| REWRITTEN | 37 | 1568 | 1 | 1529 |
| MACRO_OPAQUE | 0 | 21 | 0 | 21 |
| NO_OUTPUT | 0（表里 1，见注） | 10 | 0 | 10 |
| GOLDEN_REUSE | 1601（表里 1600） | 76 | 1559 | 0 |
| MISSING | 173 | 136 | 0 | 0 |
| VENDOR_BOUNDARY | 3 | 3 | 3 | 3 |

- 跳转：GOLDEN_REUSE→REWRITTEN 1531、→MACRO_OPAQUE 21、→NO_OUTPUT 10；GOLDEN_REUSE 留 39（全核外，无 rtl 定义）；
  **MISSING→GOLDEN_REUSE 37**（全核外，全是 `ut:OpenLLC` 经 `$(addprefix ...)` 读的 golden，旧正则漏记）。
- 注：main 上已提交的表里 PrintCommitIDModule 是 NO_OUTPUT，HEAD 旧脚本重跑却得 GOLDEN_REUSE ——
  旧正则把 XSCore 的 `$(XSSV_HOME)/rtl/common/PrintCommitIDModule.sv`（本地件）当 golden 记了。新脚本得 NO_OUTPUT、golden_used_by 为空。
- golden_used_by 非空 1652 个，其中 rtl/ 有定义 1573 个（有实现、但仍有 run 读 golden，主要是 ut:XSCore / ut:XSTile）。
  Rob 一行：`Rob  REWRITTEN  PROVEN_IN_CONE  rtl/backend/Rob.sv  ut:XSCore,ut:XSTile`。

## 裁定 2：`rewrite_coverage.py` 新增 `incore_golden_lines_proven_incl_cone`

原行 `incore_golden_lines_proven 3082317/3349310 92.0` 不动。新行只在它之上加
`verif/proven_in_cone_verified.tsv` 里 status=VERIFIED 且 `scripts/proven_in_cone.py` 的 R1-R10 机械复核全过的模块：

| 判据 | 内容 |
|---|---|
| R1 | receipt 已跟踪、字节 sha256 == 登记值 |
| R2 | receipt 通过、非 provisional、非 dirty、top == parent |
| R3 | parent 是当前 proven（绿判决且不 STALE_IMPL） |
| R4 | impl_closure 有 {impl_file, kind=repo, sha} 且当前字节未变；该模块没有另一个 golden 来源 |
| R5 | golden_closure 有 golden_file 且 sha 匹配 |
| R6 | impl_file 声明了该 module，且过了 rewritten_floor |
| R7 | 那次 run 的 black_boxes.rpt 两侧都没有它 |
| R8 | 那次 run 的 allow（`path@impl_commit`，sha 须等于 receipt 记录）没有 design == 它 |
| R9 | fm.log：ref 加载 golden_file、impl 加载 impl_file、`Elaborating design <m>` ≥ 2 次 |
| R10 | 它自己不是直接 proven（不重复计） |

不读 coverage_three_axis 的 PROVEN_IN_CONE（closure 文件名 − 当前 allow，只能当候选）。父级装配里被黑盒的
child 由 child 自己的证明覆盖、已在原行里；父级 impl 侧仍用 golden 的 child 不收。
正反测 `scripts/test_proven_in_cone.py`（22 条：每条判据一个单点变异反例 + 真仓 Rob 复核，进 gate_all）。

**结果**：`incore_golden_lines_proven_incl_cone 3348544/3349310 100.0`（= 3082317 + Rob 266227；99.98%，
一位小数印成 100.0，所以台账里逐个列出剩下的 7 个 / 766 行：CommitIDModule 97、FDPrefetcherMonitor 111、
PrintCommitIDModule 14、StorePipe 93、diff_rat_state_bank_320x776 120、dt_pcTransType_160x2 183、stateBankTags_320x3 148）。

## Rob 核验证据（本轮只核 Rob）

父级 run：CtrlBlock `run_id=CtrlBlock-20261011T035232Z-9df1c6fb0`，
`impl_commit=9df1c6fb0545c07f2673c2c13b220d00629bd31a`（是 HEAD 的祖先），`impl_worktree_dirty=false`，
`provisional=false`，`fm_mode=assembly`，`verify_matched_unread_compare_points=true`，
verdict **PASS_DEAD_REF**（native SUCCEEDED；passing 324714 / failing 0 / unmatched 0 / unverified 0 / aborted 0；
dont_verify 无；unread 16 = dead_ref 16）。同目标另两份 receipt（27fd6722e959、a757ff84032a）也是 PASS_DEAD_REF，
Rob.sv sha 相同；名单登记最新一份。

| 证据件 | 路径 | sha256 |
|---|---|---|
| receipt | `evidence/9df1c6fb0545/CtrlBlock/receipt.json` | `de3308eb29958ca63794c90b95ee892a7abaf16993438080c4573e5241d8c87d` |
| 黑盒报告 | `evidence/9df1c6fb0545/CtrlBlock/black_boxes.rpt` | `8b6f5a49ba45d2951504067a916aa34a63901fb69bbba96cdca9d1786725c78a` |
| FM 日志 | `evidence/9df1c6fb0545/CtrlBlock/fm.log` | `990da472989d3ce95e3473936746fb19159e86b8e8bd56b5857926ba69129050` |
| unread 点 | `evidence/9df1c6fb0545/CtrlBlock/unread_points.txt` | `f732601eeb0acad109dbc53e806ca1b884cd0f004f38e5a995f3d740e30db541` |
| allow@run | `verif/allow/CtrlBlock.json@9df1c6fb0545` | `b1d03d207d57418ee371fd082253406f69ec3d9edd107fc8d121b00e3f428c1b`（= receipt 记录） |
| dead_ref@run | `verif/dead_ref/CtrlBlock.json@9df1c6fb0545` | `6b69721f903dbf0ca03b3d2242076b7cc8b5fd31ebc0daeab08d616be2d33f04`（= receipt 记录） |
| impl Rob | `rtl/backend/Rob.sv`（run 时 = 9df1c6fb0545 = 当前 HEAD） | `f24abb526efcd0fdb445e58ed6fea368fdf0f96447026aac29e81f95aec8b9cb` |
| impl CtrlBlock | `rtl/backend/CtrlBlock.sv`（同上） | `ec45e3d7e49772eee91ea4e5e4ebb70b1e089c6d7a97aae1f85d5fc0377e1292` |
| golden Rob | `golden-rtl/Rob.sv`（266227 行，1 个 module） | `4aa8838b95283d5aa1f46161e4abf96de764a6c6cbaff09f189a829ae601f130` |
| golden CtrlBlock | `golden-rtl/CtrlBlock.sv` | `7ee17302dccb4fa04f495795096d7ac12d95acf2ec0d1bf0df7a1a394e277ac0` |

逐项：

1. **例化**：golden `CtrlBlock.sv:27064` 与 impl `rtl/backend/CtrlBlock.sv:21127` 都是 `Rob rob (`；
   FM 层次两侧同为 `/WORK/CtrlBlock/rob`（impl 内层核 `rob/u_core` = `xs_Rob_core`）。
   fm.log:384 ref 加载 golden Rob.sv、:500 ref `Elaborating design Rob`；:590 impl 加载
   `.../xsv2-proof-*/rtl/backend/Rob.sv`、:683 impl `Elaborating design Rob`。
2. **impl 选的是可读 RTL**：receipt `impl_closure` 里 `rtl/backend/Rob.sv kind=repo sha=f24abb52…`，
   没有任何 `Rob.sv` 的 golden 条目；该文件无 `` `include ``（不是 svh 套壳），rewritten_floor 判 REWRITTEN 667/667。
3. **没被黑盒**：black_boxes.rpt 两侧库里只有 `diff_rat_state_bank_320x776`×6、`stateBankTags_320x3`、
   `dt_pcTransType_160x2`（`rob/dt_pcTransType_ext`，Rob 内部的存储叶子，interface-only，不算 Rob 的行）与若干 0 实例的空 design；
   没有 Rob。allow@run 的 16 个对象全是这 8 个存储实例的两侧对，没有 Rob；`hdlin_interface_only` 也不含 Rob。
4. **compare points 在范围内**：fm.log:158894 `OE_PIN_BEGIN Rob expect=168720` 到 :665055
   `OE_PIN_END Rob n=168720 miss=0`，168720 个 `rob/...` ↔ `rob/u_core/...` 用户钉点全部命中；verify 后
   failing/unmatched/unverified/aborted 全 0。16 个 unread 全在 ref 侧 `rob/walkCycle_reg[0:7]`、
   `rob/waitRabWalkCycle_reg[0:7]`，dead_ref 判为 golden-only 的 perf 自环（只给 SimTop perf XMR 用，不在任何输出锥里），impl 侧没有对应寄存器。
5. **不计的部分**：Rob 的 golden child 在 impl 侧仍是 golden（receipt impl_closure kind=golden）：
   RenameBuffer、VTypeBuffer、SnapshotGenerator_3、NewRobDeqPtrWrapper、RobEnqPtrWrapper、CommitStuckCounter；
   ExceptionGen 在 impl 侧是 `rtl/backend/ExceptionGen.sv`。它们都**不**因这份 run 进 incl_cone（名单只有 Rob 一行，
   只加 golden Rob.sv 的 266227 行）；它们各自的 proven 状态照原口径算。

**机械复核不了、由本记录担保的**：第 4 条里「钉点覆盖的就是 Rob 的全部可比对点」与 dead_ref 的语义判断。
R1-R10 守的是「证据没被换掉、没被黑盒、两侧都 elaborate 了、impl 选的是这份可读 RTL」。
