# CtrlBlock 译码族 lane（agent/cb-decunit）—— 跑前登记

本文件在 **FM 起跑之前**提交。跑完在文件末尾追加「对账」一节，★不修改本节任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `main` @ `68752dc1`（Merge commit 'de57f058'） |
| 工作树 | `/home/eda/xs-env/wt-cb-decunit`，分支 `agent/cb-decunit` |
| 实现 commit | `b8c053d4`（RTL + 生成器 + UT）；本登记 commit 见 git log |
| 目标 1 | `DecodeUnit`（golden 6,252 行 / 172 端口 / 0 寄存器；DecodeStage 例化 6 次，同一模块） |
| 目标 2 | `VTypeGen`（golden 312 行 / 39 端口 / 16 位寄存器；子模块 VsetModule 125 行，一并白盒） |
| 实现 | `rtl/backend/DecodeUnit.sv`（3,344 行，其中译码表/端口/struct/接线由 `verif/ut/DecodeUnit/gen.py` 生成）、`rtl/backend/VTypeGen.sv`（199 行，VsetModule 以 `vset_pkg` 纯函数内联） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 证明模式 | signoff-strict；两目标 `FM_MERGE_DUP=false`（加强/让模型适用，不是放宽）；vmucp 默认关；无 allow / dead_ref / pin 文件 |
| 子模块处理 | DecodeUnit：FPDecoder / UopInfoGen（+ 两张 NumOfUop 表）两侧各自 elaborate，ref 侧 golden 文件、impl 侧本工程已签核的重写件，**无黑盒**。VTypeGen：ref 侧 golden VsetModule.sv 随顶层 elaborate，impl 侧无例化（vset_pkg 函数），**无黑盒**。 |

## 1. 结构（决定预测的事实）

**DecodeUnit**：纯组合。golden 0 个寄存器、0 个 always 块；子模块 FPDecoder / UopInfoGen /
strdiedLSNumOfUopTable / indexedLSNumOfUopTable 也都是纯组合（各自签核时 regs=0）。
输出端口 125 个 / 442 位。译码表 717 行由生成器从 Scala 现场读出，与 golden 的 717 条
`_decodedInst_decoder_T_N = <slice> == <const>` 匹配项按表序**逐条对过账**（`gen.py` 每次
运行都做；不等则非零退出）。表序优先下 PAUSE 被 FENCE 整个遮住，两侧同样不可达。

**VTypeGen**：golden 2 组寄存器 vtypeArch / vtypeSpec，各 {illegal, vma, vta, vsew[1:0], vlmul[2:0]} = 8 位，
共 16 位，同一个 `always @(posedge clock or posedge reset)`，复位值 illegal=1。impl 同样两个
`vtype_t` 寄存器（8 位 struct），同异步复位、同次态。输出端口 5 个 / 8 位。golden 子模块
VsetModule 的 `io_out_vconfig_vl` / `io_out_vlmax` 在 VTypeGen 里悬空（`/* unused */`）——纯组合
cone-dead，不是寄存器，不产生比较点。

## 2. 预测（★跑完不许改本节★）

`python3 scripts/fm_predict.py model <target>`（两目标 merge_dup=false，模型适用）：

| 目标 | 寄存器位 | 输出端口位 | **预测 passing** | failing | unmatched | unread | constant_reg |
|---|---|---|---|---|---|---|---|
| DecodeUnit | 0 | 442 | **442** | 0 | 0/0 | 0 | 0 |
| VTypeGen | 16 | 8 | **24** | 0 | 0/0 | 0 | 0 |

可接受偏差：**0**。没有任何预先可指认的差额项（两目标都不该有常量寄存器、不该有 matched-unread）。
任何差额都按失配处理：修 RTL 对齐 golden 再回 UT，不找解释去圆。

### ★反向出口★

- DecodeUnit failing > 0 ⇒ 最可能是（a）`casez` 里 z 位 localparam 在 FM 里的通配语义与 VCS 不同，
  或（b）某个 fuOpType 常量求值错（yunsuan 注释陈旧那类，UT 已覆盖 716/716 可达表项应该拦得住）。
  逐点诊断（`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`），不放宽。若 failing 恰为 20，只能写"至少 20，计数被截断"。
- DecodeUnit 出现 unmatched / unread ⇒ 子模块闭包两侧不对称（例如 impl 侧漏了某张表），照实报。
- VTypeGen 出现 ref 侧 unmatched/unread 落在 `vsetModule/*` ⇒ 我对"vl/vlmax 是 cone-dead 组合逻辑、不产生比较点"的判断错了，
  照实报，不走 vmucp/allow。
- VTypeGen constant_reg > 0 ⇒ FM 把某个 vtype 位判成了常量，说明两侧次态不一致（真失配），停下诊断。

## 3. UT 证据（跑前）

VTypeGen：seed 1/7/42 × `+vcs+initreg+0` / `+random`，各 200k 拍，6 轮全部 `errors=0`
（checks 199,992/轮；覆盖 seed 1：vset 172,378 / illegal 134,953 / hasVsetvl 12,432 / walk 23,438 /
walkToArch 20,394 / specUpdate 92,739 / vsetvl_seen 13,781；两档日志 md5 不同）。
复跑：`cd verif/ut/VTypeGen && make compile && make run SEED=<s> INITREG=+vcs+initreg+<0|random>`。

DecodeUnit：seed 1 × `+vcs+initreg+0` × 20k 拍 `errors=0`，716/716 可达表项全部命中；
3 seed × 2 档 × 200k 的全量在跑，结果在对账节补记（登记时不许改本节）。
复跑：`cd verif/ut/DecodeUnit && python3 gen.py --check && make compile && make run SEED=<s> INITREG=+vcs+initreg+<0|random>`。

## 4. 对账（impl commit `2897a7dbeeb5bb981a0d5f6a2a6fff7489d6bee6`，即登记 commit；RTL 字节与 b8c053d4 相同）

证据 `evidence/2897a7dbeeb5/{DecodeUnit,VTypeGen}/`（receipt.json sha256：
DecodeUnit `9477e9444f4b14ec57aa8ff2be7e83c008114f36c1355a7ae4a68fb2fa21242b`，
VTypeGen `3604640151002ae429fb1783274b6badaaf00c82840136fae84f6ad5ef33879c`）。

impl_closure sha256：`rtl/backend/DecodeUnit.sv` `aaaabf4c75789c734ab6da6a500f4f494633f6ce56d75aa9e0011c0a98bde52c`、
`rtl/backend/FPDecoder.sv` `088ef87c8c88300d3aa77fac0122512156d6746f7f5a58bef3683f4c381a64b4`、
`rtl/backend/UopInfoGen.sv` `71ae245137afac81a776166e54e2c798ad304ee8541bae290ea63621304beded`；
`rtl/backend/VTypeGen.sv` `c94689d79592a6574dcf10e21fbf7e8318afd41dceb03b7bd0265aa43bb84067`、
`rtl/backend/backend_common_pkg.sv` `f404f8ee5d07d1dd5641a9aab807b29e58ac560529c03fb05f92cd742263b87b`。
golden：DecodeUnit.sv `da56d422…c35d58d`、VTypeGen.sv `3d1ee107…b7a495559`、VsetModule.sv `9eb34d3c…29126b87`（全串在 receipt 里）。

| 项 | DecodeUnit 预测 | 实测 | 判 | VTypeGen 预测 | 实测 | 判 |
|---|---|---|---|---|---|---|
| verdict（signoff-strict） | SUCCEEDED | **SUCCEEDED** | ok | SUCCEEDED | **SUCCEEDED** | ok |
| passing | 442 | 442（442 按名配对 / 0 按签名） | 差 0 | 24 | 24 | 差 0 |
| failing | 0 | 0（failing_truncated=false） | ok | 0 | 0 | ok |
| unverified | 0 | 0 | ok | 0 | 0 | ok |
| unmatched ref/impl | 0/0 | 0/0 | ok | 0/0 | 0/0 | ok |
| unread | 0 | 0（unread_points.txt 空） | ok | 0 | 0 | ok |
| constant_reg | 0 | 无 | ok | 0 | 无 | ok |
| 黑盒 | 0 | 0（FM-249 "No black boxes"） | ok | 0 | 0 | ok |
| dont_verify / elab147 / appvar 放宽 | 无 | 全空；merge_dup=false 读回一致 | ok | 无 | 全空 | ok |

反向出口一条都没触发。FM 资源：DecodeUnit 273 s / 1089 MB；VTypeGen < 867 MB 地板。

UT（登记时未跑完的补记）：DecodeUnit seed 1/7/42 × `+vcs+initreg+0` / `+random`，各 200k 拍，6 轮全部
`errors=0`、checks 200,000/轮、716/716 可达表项全部命中（seed 1 的 +random 那轮第一次因三个并行
simv 共用一个 `simv.daidir` 撞出 VFS_SDB_ERROR 未起跑，单独重跑后绿；两档日志 md5 不同）。

复跑：`PROOF_COMMIT=2897a7dbeeb5bb981a0d5f6a2a6fff7489d6bee6 bash scripts/run_proof.sh DecodeUnit DecodeUnit`、
`PROOF_COMMIT=2897a7dbeeb5bb981a0d5f6a2a6fff7489d6bee6 bash scripts/run_proof.sh VTypeGen VTypeGen`。
