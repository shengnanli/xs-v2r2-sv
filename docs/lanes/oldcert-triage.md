# oldcert-triage lane（codex 0242 裁定 3）

分支 `agent/oldcert-triage`，基于 main `ff7650336`。不改 rtl/、fm_eq.tcl、current-valid 判据、派生表、G0/G1。

## 1. 名单复核

在本分支 HEAD `134793ec5`（= ff7650336 + claim）上用 `batch_reproof.py validate` 逐张复核 tracked 证书：
**504 张证书，330 张 current-valid，174 张不是**。与 integrator 基线名单（`tmp-ah/validate_base.txt`，175 个）
逐行 diff 只差一行 `schema-v1`：

- `schema-v1` 那一行 **不是证书**。`verif/proof_certificates/schema-v1.json` 是 schema 文件
  （`proof_status.NON_CERT`），基线名单把目录里的文件名都列了进去，validator 当然答 `green_child_not_fm_target:schema-v1`。
  这是名单的问题，不是证书失效。实际失效 174 张，不是 175 张。

174 张的原因：173 张 `green_child_script_closure_changed:<T>:scripts/fm_eq.tcl`（169 张记的是 fm_eq.tcl `b253f9ec`，
即 ac12dddbd 时的版本；最后一次改动是 28c7c3b90），1 张 `green_child_closure_changed:SplittedSRAM:rtl/common/xs_SRAMTemplate_core.sv`。

## 2. 方法（机械，`scripts/oldcert_triage.py`，生成 `docs/oldcert_triage.tsv`）

对每张失效证书 T 机械查三项（判据全文在脚本 docstring 里）：

- **(i) 台账引用**：`rewrite_coverage.proven_modules()` 的来源（fm_round_*.tsv / fastlane_ledger.tsv）、
  `coverage_three_axis.tsv` 的 formal 列、已跟踪绿 receipt 份数、`proven_in_cone_verified.tsv`。
  ★两个覆盖率脚本**都不读证书**★：rewrite_coverage 读 round 台账 + 已跟踪 receipt 的 impl 闭包（只查 impl 字节有没有变，
  不查脚本闭包）；coverage_three_axis 轴二读 receipt。所以 174 张全都还被记作 `PROVEN_DIRECT`。(i) 对每一张都成立，
  靠它区分不出用途。
- **(ii) 依赖方**：其他证书 allow 里 `green_child` 的 child_target；其他证书 impl 闭包里挂着的 `golden-rtl/T.sv`
  （`validate_impl_golden_certified` 走的那条边）；`verif/allow/*.json` 里还没有证书的父目标的 green_child 声明。
- **(iii) 已被 current-valid 父白盒覆盖**，WB1–WB6 六条全满足才算：WB1 父 current-valid；WB2 从父的 variant 出发，
  在 G1 golden 例化图里能到达 T（只走父 golden 闭包里的模块，遇到父 allow 声明的 design 就截断）；WB3 golden T.sv 的 sha 一致；
  WB4 T 自己用到的 rtl/ 文件（从 module T 出发按例化可达，加上 package 和 include）的 path+sha 都在父 impl 闭包里，
  且父 impl 闭包没有挂 golden T.sv；WB5 父是 strict（不允许黑盒），或者是 assembly 且 T 不在父 allow 里；
  WB6 父 impl 闭包的 rtl/ 里确实有例化 T 的语句。

分类：有活跃依赖方 → REQUIRED；否则 (iii) 成立 → HISTORICAL；否则 (i) 成立 → REQUIRED；三项都不成立 → ORPHAN（实际 0 张）。
活跃依赖方指：依赖方本身 current-valid，或依赖方本身是 REQUIRED，或依赖方是没有证书、也没被 current-valid 父白盒覆盖的父目标。

## 3. 分类结果（HEAD 134793ec5，重证前）

| 类别 | 证书数 | golden 行 |
|---|---|---|
| HISTORICAL | 171 | 37,036 |
| REQUIRED | 3 | 899 |
| ORPHAN | 0 | 0 |

HISTORICAL 按最近的白盒父分（每张只有 1 个父满足 WB1–WB6）：

| 白盒父 | 张数 | golden 行 | 被覆盖的 |
|---|---|---|---|
| ExuBlock | 149 | 24,363 | NewCSR 字段模块（Mhpmcounter*/Hpmcounter*/Pma*cfg/Pmp*cfg/Iprio*/H*/M*/S* 及 SstcInterruptGen、TrapInstMod、TrapTvalMod）、Dispatcher/_1/_4/_5/_7、HPerfCounter_8 |
| ExuBlock_2 | 6 | 1,534 | Dispatcher_13–17、Mgtu |
| ExuBlock_1 | 3 | 684 | Dispatcher_8/9/10 |
| LsqWrapper | 5 | 8,399 | AgeDetector_38、FreeList_5、LqVAddrModule、DelayNWithValid_152/155 |
| L2Top | 3 | 660 | BusErrorUnit、TLLogger_1/2 |
| TL2CHICoupledL2 | 2 | 428 | Queue1_CHIDAT/CHIRSP |
| Frontend / HPerfMonitor_2 | 1 / 1 | 290 / 399 | HPerfCounter / HPerfCounter_13 |
| BitmapCache | 1 | 279 | MbistBitmapCache |

逐张的父、依赖方、引用见 `docs/oldcert_triage.tsv`。

其中 LoadQueueReplay 的 allow 把 AgeDetector_38 / FreeList_5 / LqVAddrModule 声明为 green_child，但 LoadQueueReplay
**没有证书**，它本身被 LsqWrapper（strict、current-valid）白盒展开，golden LoadQueueReplay.sv 和 rtl LoadQueueReplay.sv
都在 LsqWrapper 的闭包里。所以这些声明目前没有任何 current-valid 证明在用，不算活跃依赖。
DelayNWithValid_152/155 唯一的依赖方是 LqVAddrModule（impl_golden 边），LqVAddrModule 本身是 HISTORICAL，所以这两张也一样。

### REQUIRED（3 张）

| target | 原因 | 为什么 REQUIRED |
|---|---|---|
| Serializer | fm_eq.tcl 变了 | **Sbuffer（current-valid）impl 侧挂 golden Serializer.sv**，靠这张证书背书（impl_golden 边） |
| SpillRegister_7 | fm_eq.tcl 变了 | G1 里只有 NCBDownstreamAR_1 例化它，而 NCBDownstreamAR_1 没有 current-valid 父；没有白盒父，覆盖率台账记它 PROVEN_DIRECT |
| SplittedSRAM | impl 闭包变了 | 见 §5 |

## 4. 重证结果（PROOF_COMMIT 10f43d709656，官方 run_proof，batch_reproof `--jobs 3`）

跑前给 SpillRegister_7 补了 fm_predict 登记（10f43d709，expected=99，merge_dup=true，模型不适用）。
Serializer 和 SplittedSRAM 的登记已经在 HEAD 里，按当前模型复算一致（5 / 1480）。

| target | 模式 | verdict | passing | 预测 | receipt sha256 | 新证书 sha256 | 旧证书 sha256 |
|---|---|---|---|---|---|---|---|
| Serializer | signoff-strict | SUCCEEDED | 5 | ok | cb5ca3fba709f906… | b7af613ed0b2c7c1bba81422993707ed8779d8cc4b5a4688ab3cf28850a9f018 | 91e866c6062d30a3… |
| SpillRegister_7 | signoff-strict | SUCCEEDED | 99 | ok | a8c7b9147fb8a248… | 1f3a1213240398ea26c127866b58e48bcba30841adea3e5dabc92b696d652b7c | 45819bedbf3cf065… |
| SplittedSRAM | assembly | SUCCEEDED | 1480 | ok | 33f88be0121a7bad… | 0d52a64e94d6002c80960a004d84f68da0a88ced94476e1baf94c45a0d9bde97 | 5fa3eab977b67782… |

三张都是 failing 0 / unverified 0 / unread_notcompared 0，passing 和旧证书一样。evidence 在 `evidence/10f43d709656/`，提交 a1d118812。
三张都不在任何 allow 的 green_child 里（Serializer 走的是 impl_golden 边，不引用证书 sha），所以不需要重盖 allow。
在 a1d118812 上复核：这 3 张，加上 Sbuffer / StorePfWrapper / BitmapCache / TL2CHICoupledL2 / L2Top，全部 current-valid。

## 5. 两项特殊原因

- **SplittedSRAM `closure_changed`**：证书是 fe-mem-misc lane 在 bd284f4dd 上出的（10-11），当时的 `xs_SRAMTemplate_core.sv`
  是 `55b51e13`（5336c4989 的版本）。D1 改动 8c16962b3（"holdRead 关时不生成 rdata_last_REG"）10-04 经 fb453850a 进 main，
  但 bd284f4dd 不是它的后代：那个 lane 从更早的 main 分出去，证书在 lane 合入后才进 main。
  所以这张证书**从来没有证过 main 上的字节**，是真正的 impl 变更，不是脚本更新。BitmapCache（strict、current-valid）用的是新字节。
  覆盖率直接引用它，重证成本也低，所以归 REQUIRED 并已重证（1480，与旧证书一致）。
- **`not_fm_target:schema-v1`**：见 §1。不是证书，是名单伪影；validate 名单应该排除 `schema-v1` / `POLICY`
  （本 lane 的 `scripts/oldcert_triage.py` 用的是 `git ls-files` 加 NON_CERT 过滤）。

## 6. current-valid 与历史 PASS 分开报告

| 口径 | 证书数 | golden 行（每张证书 variant 所在 G1 文件行数，变体各算） |
|---|---|---|
| current-valid（a1d118812，重证后） | **333** | **1,313,658** |
| 历史 PASS（HISTORICAL，不计入 current-valid） | 171 | 37,036 |
| 合计 tracked 证书 | 504 | — |

重证前（134793ec5）是 330 张 / 1,312,759 行 current-valid。

## 7. HISTORICAL 的排除方案

- current-valid 计数本来就不含它们（validator 判 False），**判据不用改**。需要排除的是那些按 receipt 记绿的口径：
  `coverage_three_axis` 轴二的 PROVEN_DIRECT、`rewrite_coverage` 的 proven（round 台账 + receipt 只查 impl 字节）。
  这 171 张在那里仍然按自己过期的 receipt 记 PROVEN_DIRECT。
- 本 lane 的实现：`docs/oldcert_triage.tsv` 的 `action=exclude_from_current_valid(superseded_by=<父>)`，
  依据在 `whitebox_parent` 列（WB1–WB6 的结果）。任何需要「current-valid 证书数」的报告，按「本表 HISTORICAL 行不计」来算。
- **提案，没有实现，需要先批**：让 coverage_three_axis 轴二 / rewrite_coverage 的 proven 改为要求证书 current-valid；
  不是 current-valid、但满足 WB1–WB6 的，记 `PROVEN_IN_CONE(superseded_by=P)`，不再记 PROVEN_DIRECT。
  这会改台账脚本和派生表，按指示停在这里报告。注意 WB2 只证明 T 在父证明里被例化、没有被黑盒，不证明 T 的每个输出都是父的
  compare point。例如 ExuBlock 是 PASS_DEAD_REF，有 258 个 golden-only 未读点，全在 exus_7 下，其中 40 个在
  csr/csrMod/hpmHc perfEvents。所以这一档不能直接抄进 `proven_in_cone_verified.tsv` 去计行数（codex 0238 裁定 2）。

## 8. 发现（validator，没有修改）

`validate_impl_golden_certified`（impl 侧挂 golden 的递归边）只要求被挂的那个模块有 tracked、schema 合格、verdict 合格、
golden 字节一致的证书，**不要求那张证书 current-valid**（不复算它的脚本闭包和 impl 闭包）。实测：Serializer 证书的脚本闭包
已经过期，Sbuffer 照样判 current-valid。本 lane 重证 Serializer 后，这个具体缺口已经补上，但判据本身的口子还在。
它属于 current-valid 判据，按指示不动，报给 integrator / codex。

## 9. 触及 reproof-chain 边界

- 158 张 HISTORICAL 的白盒父是 ExuBlock / ExuBlock_1 / ExuBlock_2（属 reproof-chain lane）。只是引用它们当前的 current-valid 状态，
  没有重证它们。如果 reproof-chain 改 `rtl/backend/VSstatusModule.sv` / `TrapEntryVSEventModule.sv`（都在 ExuBlock 闭包里），
  在 ExuBlock 重证之前，这 158 张的排除依据会暂时失效，重跑 `scripts/oldcert_triage.py` 就能看到。
- REQUIRED 的 3 张依赖链都不往上走到 ExuBlock/Backend/XSCore/XSTile/NewCSR/CSR/ExeUnit_7，失效名单里也没有 TrapEntry*/VS* 叶子。
- NewCSR 没有证书。它的字段模块现在是靠 ExuBlock 的 strict 白盒证明覆盖的。
