# restale-sram lane（agent/restale-sram）—— 跑前登记

本文件在任何 FM 起跑**之前**提交；跑完在文末「对账」追加，★不修改本节任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `be72d6a1f`（含 codex 0206 D1：`rtl/common/xs_SRAMTemplate_core.sv` 在 MCP_HOLD=0 && ENABLE_HOLDREAD=0 时不再生成 `rdata_last_REG`） |
| 工作树 | `/home/eda/xs-env/wt-restale-sram`，分支 `agent/restale-sram` |
| 目标集 | `rewrite_coverage.stale_impl_targets()` 在 be72d6a1 上的 90 个 |
| 范围 | 只重证，不改 rtl/；新 failing/unmatched/unread 即停、报首个最小反例（codex 0206 停止条件） |
| 复跑 | `bash scripts/run_proof.sh <ut> <target...> < /dev/null`（`PROOF_COMMIT` 钉在本登记之后的 commit） |

## 1. 陈旧原因（逐份 receipt 对 impl_closure 复算 sha256）

- 84 个：唯一不一致文件 = `rtl/common/xs_SRAMTemplate_core.sv`（D1）。
- 6 个（DCacheLeaves：Arbiter1_L1BankedDataWriteReq / Arbiter1_L1BankedDataWriteReqCtrl / Arbiter1_TagWriteReq /
  MissReadyGen / PrefetcherMonitor / TreeArbiter）：唯一不一致文件 = `rtl/memblock/FDPrefetcherMonitor.sv`
  （1998a657b dcachebody 补 golden 残留 PopCount），**不是 D1**。FDPrefetcherMonitor 不在 DCacheLeaves 的 FM_VARIANTS，
  只是共编进闭包；6 个目标本身不例化它 ⇒ 同样预测不变。

## 2. 预测（规则）

D1 只删 impl 独有、与 respReg 同方程的死寄存器 rdata_last_REG。旧 receipt 里它已被
`verification_merge_duplicated_registers=true` 与 respReg 合并（或在 strict 目标里不形成独立比较点），
**全部 90 份旧 receipt 的 unread_impl / unmatched 均为 0**，所以：

- **passing_new = passing_old**（逐目标见下表，差额预测 0）；
- failing / unverified / aborted / unmatched(ref,impl) = 0；unread_impl = 0（旧值即 0，不存在"归零"项）；
- verdict 不变（89 个 SUCCEEDED + Tage_SC PASS_DEAD_REF，其 golden-only unread_ref=192 不变）。
- 阶段 2（ClockGate 重写合入后）的目标：ClockGate 换成重写件对父级 passing 预测同样无影响（latch+与门，非比较点寄存器）；若有差异如实报告。

`fm_predict.py register` 已为原先缺登记的 48 个目标补登（全部 merge_dup=true ⇒ MODEL_NA，模型不适用；
本 lane 的判据是上表的"与旧 receipt 相同"）。

## 3. 逐目标

阶段：P1 = UT Makefile 不读 ClockGate.sv（现在跑）；P2 = 读 ClockGate.sv（等 agent/clockgate 合入 main 后跑）。

| target | ut | 阶段 | 旧 receipt | 旧 verdict | 旧 passing | 旧 unread_impl | 预测 passing | 预测 unread_impl |
|---|---|---|---|---|---|---|---|---|
| Arbiter1_L1BankedDataWriteReq | DCacheLeaves | P1 | `evidence/414ed06a79c5/Arbiter1_L1BankedDataWriteReq/receipt.json` | SUCCEEDED | 521 | 0 | 521 | 0 |
| Arbiter1_L1BankedDataWriteReqCtrl | DCacheLeaves | P1 | `evidence/414ed06a79c5/Arbiter1_L1BankedDataWriteReqCtrl/receipt.json` | SUCCEEDED | 53 | 0 | 53 | 0 |
| Arbiter1_TagWriteReq | DCacheLeaves | P1 | `evidence/414ed06a79c5/Arbiter1_TagWriteReq/receipt.json` | SUCCEEDED | 49 | 0 | 49 | 0 |
| BankedDataArray | BankedDataArray | P2 | `evidence/0b523bc0d2bb/BankedDataArray/receipt.json` | SUCCEEDED | 10342 | 0 | 10342 | 0 |
| DataSRAMBank | DataSRAMBank | P2 | `evidence/754c1d99ea72/DataSRAMBank/receipt.json` | SUCCEEDED | 1205 | 0 | 1205 | 0 |
| DataSRAMBank_1 | DataSRAMBank | P2 | `evidence/754c1d99ea72/DataSRAMBank_1/receipt.json` | SUCCEEDED | 1205 | 0 | 1205 | 0 |
| DataSRAMBank_2 | DataSRAMBank | P2 | `evidence/754c1d99ea72/DataSRAMBank_2/receipt.json` | SUCCEEDED | 1205 | 0 | 1205 | 0 |
| DataSRAMBank_4 | DataSRAMBank | P2 | `evidence/754c1d99ea72/DataSRAMBank_4/receipt.json` | SUCCEEDED | 1205 | 0 | 1205 | 0 |
| Directory | Directory | P1 | `evidence/f49dee3e7949/Directory/receipt.json` | SUCCEEDED | 1953 | 0 | 1953 | 0 |
| Directory_1 | Directory | P1 | `evidence/f49dee3e7949/Directory_1/receipt.json` | SUCCEEDED | 1954 | 0 | 1954 | 0 |
| Directory_2 | Directory | P1 | `evidence/f49dee3e7949/Directory_2/receipt.json` | SUCCEEDED | 1954 | 0 | 1954 | 0 |
| Directory_3 | Directory | P1 | `evidence/f49dee3e7949/Directory_3/receipt.json` | SUCCEEDED | 1955 | 0 | 1955 | 0 |
| DuplicatedTagArray | DuplicatedTagArray | P2 | `evidence/b25ad3da9f18/DuplicatedTagArray/receipt.json` | SUCCEEDED | 2460 | 0 | 2460 | 0 |
| FoldedSRAMTemplate | FoldedSRAMTemplate | P2 | `evidence/62fccb92c825/FoldedSRAMTemplate/receipt.json` | SUCCEEDED | 113 | 0 | 113 | 0 |
| FoldedSRAMTemplate_1 | FoldedSRAMTemplate | P2 | `evidence/62fccb92c825/FoldedSRAMTemplate_1/receipt.json` | SUCCEEDED | 148 | 0 | 148 | 0 |
| FoldedSRAMTemplate_20 | FoldedSRAMTemplate | P2 | `evidence/62fccb92c825/FoldedSRAMTemplate_20/receipt.json` | SUCCEEDED | 109 | 0 | 109 | 0 |
| FoldedSRAMTemplate_22 | FoldedSRAMTemplate | P2 | `evidence/62fccb92c825/FoldedSRAMTemplate_22/receipt.json` | SUCCEEDED | 443 | 0 | 443 | 0 |
| FoldedSRAMTemplate_24 | FoldedSRAMTemplate | P2 | `evidence/62fccb92c825/FoldedSRAMTemplate_24/receipt.json` | SUCCEEDED | 846 | 0 | 846 | 0 |
| MissReadyGen | DCacheLeaves | P1 | `evidence/414ed06a79c5/MissReadyGen/receipt.json` | SUCCEEDED | 412 | 0 | 412 | 0 |
| PrefetcherMonitor | DCacheLeaves | P1 | `evidence/414ed06a79c5/PrefetcherMonitor/receipt.json` | SUCCEEDED | 96 | 0 | 96 | 0 |
| RecentRequestTable | RecentRequestTable | P1 | `evidence/397a2bc9c8d3/RecentRequestTable/receipt.json` | SUCCEEDED | 97 | 0 | 97 | 0 |
| RecentRequestTable_1 | RecentRequestTable | P1 | `evidence/397a2bc9c8d3/RecentRequestTable_1/receipt.json` | SUCCEEDED | 100 | 0 | 100 | 0 |
| SCTable | SCTable | P2 | `evidence/05394ca211f8/SCTable/receipt.json` | SUCCEEDED | 1123 | 0 | 1123 | 0 |
| SCTable_1 | SCTable | P2 | `evidence/05394ca211f8/SCTable_1/receipt.json` | SUCCEEDED | 1123 | 0 | 1123 | 0 |
| SCTable_2 | SCTable | P2 | `evidence/05394ca211f8/SCTable_2/receipt.json` | SUCCEEDED | 1123 | 0 | 1123 | 0 |
| SCTable_3 | SCTable | P2 | `evidence/05394ca211f8/SCTable_3/receipt.json` | SUCCEEDED | 1123 | 0 | 1123 | 0 |
| SRAMTemplate | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate/receipt.json` | SUCCEEDED | 394 | 0 | 394 | 0 |
| SRAMTemplateWithFixedWidth | SRAMTemplateWithFixedWidth | P1 | `evidence/397a2bc9c8d3/SRAMTemplateWithFixedWidth/receipt.json` | SUCCEEDED | 351 | 0 | 351 | 0 |
| SRAMTemplateWithFixedWidth_12 | SRAMTemplateWithFixedWidth | P1 | `evidence/397a2bc9c8d3/SRAMTemplateWithFixedWidth_12/receipt.json` | SUCCEEDED | 351 | 0 | 351 | 0 |
| SRAMTemplateWithFixedWidth_28 | SRAMTemplateWithFixedWidth | P1 | `evidence/397a2bc9c8d3/SRAMTemplateWithFixedWidth_28/receipt.json` | SUCCEEDED | 351 | 0 | 351 | 0 |
| SRAMTemplateWithFixedWidth_4 | SRAMTemplateWithFixedWidth | P1 | `evidence/397a2bc9c8d3/SRAMTemplateWithFixedWidth_4/receipt.json` | SUCCEEDED | 351 | 0 | 351 | 0 |
| SRAMTemplate_100 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_100/receipt.json` | SUCCEEDED | 301 | 0 | 301 | 0 |
| SRAMTemplate_116 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_116/receipt.json` | SUCCEEDED | 359 | 0 | 359 | 0 |
| SRAMTemplate_124 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_124/receipt.json` | SUCCEEDED | 371 | 0 | 371 | 0 |
| SRAMTemplate_129 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_129/receipt.json` | SUCCEEDED | 468 | 0 | 468 | 0 |
| SRAMTemplate_143 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_143/receipt.json` | SUCCEEDED | 468 | 0 | 468 | 0 |
| SRAMTemplate_145 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_145/receipt.json` | SUCCEEDED | 602 | 0 | 602 | 0 |
| SRAMTemplate_146 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_146/receipt.json` | SUCCEEDED | 75 | 0 | 75 | 0 |
| SRAMTemplate_148 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_148/receipt.json` | SUCCEEDED | 322 | 0 | 322 | 0 |
| SRAMTemplate_150 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_150/receipt.json` | SUCCEEDED | 321 | 0 | 321 | 0 |
| SRAMTemplate_152 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_152/receipt.json` | SUCCEEDED | 440 | 0 | 440 | 0 |
| SRAMTemplate_153 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_153/receipt.json` | SUCCEEDED | 87 | 0 | 87 | 0 |
| SRAMTemplate_154 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_154/receipt.json` | SUCCEEDED | 63 | 0 | 63 | 0 |
| SRAMTemplate_155 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_155/receipt.json` | SUCCEEDED | 569 | 0 | 569 | 0 |
| SRAMTemplate_159 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_159/receipt.json` | SUCCEEDED | 322 | 0 | 322 | 0 |
| SRAMTemplate_16 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_16/receipt.json` | SUCCEEDED | 352 | 0 | 352 | 0 |
| SRAMTemplate_162 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_162/receipt.json` | SUCCEEDED | 322 | 0 | 322 | 0 |
| SRAMTemplate_163 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_163/receipt.json` | SUCCEEDED | 440 | 0 | 440 | 0 |
| SRAMTemplate_164 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_164/receipt.json` | SUCCEEDED | 87 | 0 | 87 | 0 |
| SRAMTemplate_165 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_165/receipt.json` | SUCCEEDED | 63 | 0 | 63 | 0 |
| SRAMTemplate_166 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_166/receipt.json` | SUCCEEDED | 569 | 0 | 569 | 0 |
| SRAMTemplate_178 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_178/receipt.json` | SUCCEEDED | 569 | 0 | 569 | 0 |
| SRAMTemplate_181 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_181/receipt.json` | SUCCEEDED | 322 | 0 | 322 | 0 |
| SRAMTemplate_185 | SRAMTemplateNewForm | P2 | `evidence/170a4d608018/SRAMTemplate_185/receipt.json` | SUCCEEDED | 440 | 0 | 440 | 0 |
| SRAMTemplate_186 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_186/receipt.json` | SUCCEEDED | 87 | 0 | 87 | 0 |
| SRAMTemplate_187 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_187/receipt.json` | SUCCEEDED | 63 | 0 | 63 | 0 |
| SRAMTemplate_2 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_2/receipt.json` | SUCCEEDED | 394 | 0 | 394 | 0 |
| SRAMTemplate_32 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_32/receipt.json` | SUCCEEDED | 352 | 0 | 352 | 0 |
| SRAMTemplate_36 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_36/receipt.json` | SUCCEEDED | 189 | 0 | 189 | 0 |
| SRAMTemplate_4 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_4/receipt.json` | SUCCEEDED | 352 | 0 | 352 | 0 |
| SRAMTemplate_44 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_44/receipt.json` | SUCCEEDED | 120 | 0 | 120 | 0 |
| SRAMTemplate_45 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_45/receipt.json` | SUCCEEDED | 148 | 0 | 148 | 0 |
| SRAMTemplate_64 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_64/receipt.json` | SUCCEEDED | 58 | 0 | 58 | 0 |
| SRAMTemplate_68 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_68/receipt.json` | SUCCEEDED | 145 | 0 | 145 | 0 |
| SRAMTemplate_76 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_76/receipt.json` | SUCCEEDED | 478 | 0 | 478 | 0 |
| SRAMTemplate_78 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_78/receipt.json` | SUCCEEDED | 478 | 0 | 478 | 0 |
| SRAMTemplate_8 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_8/receipt.json` | SUCCEEDED | 352 | 0 | 352 | 0 |
| SRAMTemplate_84 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_84/receipt.json` | SUCCEEDED | 301 | 0 | 301 | 0 |
| SRAMTemplate_86 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_86/receipt.json` | SUCCEEDED | 301 | 0 | 301 | 0 |
| SRAMTemplate_88 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_88/receipt.json` | SUCCEEDED | 301 | 0 | 301 | 0 |
| SRAMTemplate_92 | SRAMTemplate | P2 | `evidence/62fccb92c825/SRAMTemplate_92/receipt.json` | SUCCEEDED | 301 | 0 | 301 | 0 |
| SplittedSRAM | SplittedSRAMBitmap | P1 | `evidence/397a2bc9c8d3/SplittedSRAM/receipt.json` | SUCCEEDED | 1480 | 0 | 1480 | 0 |
| SplittedSRAMTemplate | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate/receipt.json` | SUCCEEDED | 787 | 0 | 787 | 0 |
| SplittedSRAMTemplate_1 | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate_1/receipt.json` | SUCCEEDED | 787 | 0 | 787 | 0 |
| SplittedSRAMTemplate_2 | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate_2/receipt.json` | SUCCEEDED | 1505 | 0 | 1505 | 0 |
| SplittedSRAMTemplate_23 | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate_23/receipt.json` | SUCCEEDED | 110 | 0 | 110 | 0 |
| SplittedSRAMTemplate_25 | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate_25/receipt.json` | SUCCEEDED | 478 | 0 | 478 | 0 |
| SplittedSRAMTemplate_27 | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate_27/receipt.json` | SUCCEEDED | 955 | 0 | 955 | 0 |
| SplittedSRAMTemplate_3 | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate_3/receipt.json` | SUCCEEDED | 120 | 0 | 120 | 0 |
| SplittedSRAMTemplate_4 | SplittedSRAMTemplate | P2 | `evidence/62fccb92c825/SplittedSRAMTemplate_4/receipt.json` | SUCCEEDED | 148 | 0 | 148 | 0 |
| SplittedSRAM_1 | SplittedSRAM | P1 | `evidence/a7c0861e14f7/SplittedSRAM_1/receipt.json` | SUCCEEDED | 2487 | 0 | 2487 | 0 |
| SplittedSRAM_2 | SplittedSRAM | P1 | `evidence/a7c0861e14f7/SplittedSRAM_2/receipt.json` | SUCCEEDED | 7472 | 0 | 7472 | 0 |
| SplittedSRAM_3 | Directory | P1 | `evidence/f49dee3e7949/SplittedSRAM_3/receipt.json` | SUCCEEDED | 1286 | 0 | 1286 | 0 |
| SplittedSRAM_4 | Directory | P1 | `evidence/f49dee3e7949/SplittedSRAM_4/receipt.json` | SUCCEEDED | 1286 | 0 | 1286 | 0 |
| SplittedSRAM_5 | Directory | P1 | `evidence/f49dee3e7949/SplittedSRAM_5/receipt.json` | SUCCEEDED | 1286 | 0 | 1286 | 0 |
| SplittedSRAM_6 | Directory | P1 | `evidence/f49dee3e7949/SplittedSRAM_6/receipt.json` | SUCCEEDED | 1286 | 0 | 1286 | 0 |
| TagArray | TagArray | P2 | `evidence/b25ad3da9f18/TagArray/receipt.json` | SUCCEEDED | 737 | 0 | 737 | 0 |
| TagSRAMBank | TagArray | P2 | `evidence/b25ad3da9f18/TagSRAMBank/receipt.json` | SUCCEEDED | 369 | 0 | 369 | 0 |
| Tage_SC | Tage_SC | P2 | `evidence/05394ca211f8/Tage_SC/receipt.json` | PASS_DEAD_REF | 16112 | 0 | 16112 | 0 |
| TreeArbiter | DCacheLeaves | P1 | `evidence/414ed06a79c5/TreeArbiter/receipt.json` | SUCCEEDED | 981 | 0 | 981 | 0 |

## 3b. 追加登记（证明前，2026-10-04，merge main c712edae 之后）

集成者通知：main c712edae 合入 bpu-tables 的 ITTage 钉点修复（新 receipt `evidence/335a330a9baa/`，钉点文件换新）。
Tage_SC / Composer 的 335a330a9baa receipt 在 D1 前出证，impl 闭包含 `xs_SRAMTemplate_core.sv` 旧字节，已失效。

- **Composer 纳入**（P2，UT Makefile 读 ClockGate.sv）。`stale_impl_targets()` 没列它，原因：仍有一份更早的已跟踪绿 receipt
  `evidence/eb08246eb9a9/Composer/receipt.json`（SUCCEEDED passing 526285，impl 闭包 92 个文件、**不含** xs_SRAMTemplate_core.sv，
  旧证明形态）字节全匹配，于是判"不陈旧"。这是判据的盲点（另报），不影响本 lane 重证。
- 预测基准改用 335a330a9baa（新钉点）的 receipt：

| target | ut | 阶段 | 基准 receipt | 旧 verdict | 旧 passing | 旧 unread_ref / unread_impl | 预测 passing | 预测 verdict |
|---|---|---|---|---|---|---|---|---|
| Composer | Composer | P2 | `335a330a9baa/Composer/receipt.json` | PASS_DEAD_REF | 42060 | 192 / 0 | 42060 | PASS_DEAD_REF（unread_ref=192，unread_impl=0） |
| Tage_SC | Tage_SC | P2 | `335a330a9baa/Tage_SC/receipt.json` | PASS_DEAD_REF | 16112 | 192 / 0 | 16112 | PASS_DEAD_REF（unread_ref=192，unread_impl=0） |

（Tage_SC 原 §3 行引用的 05394ca211f8 receipt 同为 16112，预测不变。）

## 3c. 追加登记（证明前，merge main bd3b7081 之后）

ICache（icache-fm 合入，`evidence/a72794293f57/ICache/receipt.json`，新钉点 gen_icache_pins.py 740+53）在 D1 前出证，
impl 闭包含旧 xs_SRAMTemplate_core.sv ⇒ 失效，纳入 P2（UT Makefile 读 ClockGate.sv）。

| target | ut | 阶段 | 基准 receipt | 旧 verdict | 旧 passing | 旧 unread / unmatched | 预测 passing | 预测 verdict |
|---|---|---|---|---|---|---|---|---|
| ICache | ICache | P2 | `a72794293f57/ICache/receipt.json` | SUCCEEDED | 21174 | 0 / 0 | 21174 | SUCCEEDED（全零） |

## 5. 阶段 2 登记（证明前；main 2e56d8b6 ClockGate 合入后，本分支 merge 3081d84fd）

清单 = 当前 `stale_impl_targets()`（67）∪ `docs/lanes/clockgate_affected_targets.tsv`（103）= **103 个**（stale 全含于 affected）。
集成者说明：旧 receipt 把 golden ClockGate 记成 kind=golden，换本地件后 stale 判据看不出，故以 affected 清单为准。
阶段 1 的 23 个目标所在 UT 目录（DCacheLeaves/Directory/RecentRequestTable/SRAMTemplateWithFixedWidth/SplittedSRAM/SplittedSRAMBitmap）
**都不在** clockgate 改动的 31 个 UT 之列 ⇒ 不需再证。

预测规则：passing_new = 基准 receipt（最新一份已跟踪绿 receipt）的 passing；verdict 不变；failing/unverified/aborted/unmatched=0；
PASS_DEAD_REF 目标的 golden-only unread_ref 不变、unread_impl=0。ClockGate 换本地件（latch+与门，非寄存器比较点）预测对父级 passing 无影响。
例外：SRAMTemplate_128 无已跟踪 receipt（fastlane_ledger 记 WORKING_PASS p2507，未出 receipt）⇒ 预测 2507（属首证）。
Predictor 的 fm_predict 模型给 44750（标"模型适用"），与旧 receipt 528967 不符，模型对它不成立；本 lane 判据仍为"等于旧 receipt"。

| target | ut | 基准 receipt | 旧 verdict | 旧 passing | 旧 unread_ref/impl | 预测 passing | 预测 verdict |
|---|---|---|---|---|---|---|---|
| BankedDataArray | BankedDataArray | `0b523bc0d2bb/BankedDataArray` | SUCCEEDED | 10342 | 0/0 | 10342 | SUCCEEDED |
| BitmapCache | BitmapCache | `397a2bc9c8d3/BitmapCache` | SUCCEEDED | 13069 | 0/0 | 13069 | SUCCEEDED |
| ClockMux | ClockGateCell93 | `6d68c5409244/ClockMux` | SUCCEEDED | 1 | 0/0 | 1 | SUCCEEDED |
| Composer | Composer | `335a330a9baa/Composer` | PASS_DEAD_REF | 42060 | 192/0 | 42060 | PASS_DEAD_REF |
| DCache | DCache | `0dc9c4532cf5/DCache` | SUCCEEDED | 82086 | 0/0 | 82086 | SUCCEEDED |
| DataSRAMBank | DataSRAMBank | `754c1d99ea72/DataSRAMBank` | SUCCEEDED | 1205 | 0/0 | 1205 | SUCCEEDED |
| DataSRAMBank_1 | DataSRAMBank | `754c1d99ea72/DataSRAMBank_1` | SUCCEEDED | 1205 | 0/0 | 1205 | SUCCEEDED |
| DataSRAMBank_2 | DataSRAMBank | `754c1d99ea72/DataSRAMBank_2` | SUCCEEDED | 1205 | 0/0 | 1205 | SUCCEEDED |
| DataSRAMBank_4 | DataSRAMBank | `754c1d99ea72/DataSRAMBank_4` | SUCCEEDED | 1205 | 0/0 | 1205 | SUCCEEDED |
| DataStorage | DataStorage | `0dc9c4532cf5/DataStorage` | SUCCEEDED | 2532 | 0/0 | 2532 | SUCCEEDED |
| DataStorage_1 | DataStorage | `0dc9c4532cf5/DataStorage_1` | SUCCEEDED | 2533 | 0/0 | 2533 | SUCCEEDED |
| DataStorage_2 | DataStorage | `0dc9c4532cf5/DataStorage_2` | SUCCEEDED | 2534 | 0/0 | 2534 | SUCCEEDED |
| DataStorage_3 | DataStorage | `0dc9c4532cf5/DataStorage_3` | SUCCEEDED | 2534 | 0/0 | 2534 | SUCCEEDED |
| DuplicatedTagArray | DuplicatedTagArray | `b25ad3da9f18/DuplicatedTagArray` | SUCCEEDED | 2460 | 0/0 | 2460 | SUCCEEDED |
| FTB | FTB | `397a2bc9c8d3/FTB` | PASS_DEAD_REF | 8605 | 50/0 | 8605 | PASS_DEAD_REF |
| FTBBank | FTBBank | `f40deba9439d/FTBBank` | PASS_DEAD_REF | 3276 | 50/0 | 3276 | PASS_DEAD_REF |
| FoldedSRAMTemplate | FoldedSRAMTemplate | `62fccb92c825/FoldedSRAMTemplate` | SUCCEEDED | 113 | 0/0 | 113 | SUCCEEDED |
| FoldedSRAMTemplate_1 | FoldedSRAMTemplate | `62fccb92c825/FoldedSRAMTemplate_1` | SUCCEEDED | 148 | 0/0 | 148 | SUCCEEDED |
| FoldedSRAMTemplate_20 | FoldedSRAMTemplate | `62fccb92c825/FoldedSRAMTemplate_20` | SUCCEEDED | 109 | 0/0 | 109 | SUCCEEDED |
| FoldedSRAMTemplate_22 | FoldedSRAMTemplate | `62fccb92c825/FoldedSRAMTemplate_22` | SUCCEEDED | 443 | 0/0 | 443 | SUCCEEDED |
| FoldedSRAMTemplate_24 | FoldedSRAMTemplate | `62fccb92c825/FoldedSRAMTemplate_24` | SUCCEEDED | 846 | 0/0 | 846 | SUCCEEDED |
| GatedSplittedSRAM | DataStorage | `0dc9c4532cf5/GatedSplittedSRAM` | SUCCEEDED | 2272 | 0/0 | 2272 | SUCCEEDED |
| GatedSplittedSRAM_1 | DataStorage | `0dc9c4532cf5/GatedSplittedSRAM_1` | SUCCEEDED | 2272 | 0/0 | 2272 | SUCCEEDED |
| GatedSplittedSRAM_2 | DataStorage | `0dc9c4532cf5/GatedSplittedSRAM_2` | SUCCEEDED | 2272 | 0/0 | 2272 | SUCCEEDED |
| GatedSplittedSRAM_3 | DataStorage | `0dc9c4532cf5/GatedSplittedSRAM_3` | SUCCEEDED | 2272 | 0/0 | 2272 | SUCCEEDED |
| ICache | ICache | `a72794293f57/ICache` | SUCCEEDED | 21174 | 0/0 | 21174 | SUCCEEDED |
| ICacheMetaArray | ICacheMetaArray | `76d345fc6c4f/ICacheMetaArray` | SUCCEEDED | 2500 | 0/0 | 2500 | SUCCEEDED |
| ITTage | ITTage | `335a330a9baa/ITTage` | SUCCEEDED | 10426 | 0/0 | 10426 | SUCCEEDED |
| ITTageTable | ITTageTable | `c6573076c5ba/ITTageTable` | SUCCEEDED | 682 | 0/0 | 682 | SUCCEEDED |
| ITTageTable_1 | ITTageTable_1 | `c6573076c5ba/ITTageTable_1` | SUCCEEDED | 682 | 0/0 | 682 | SUCCEEDED |
| ITTageTable_2 | ITTageTable_2 | `c6573076c5ba/ITTageTable_2` | SUCCEEDED | 1014 | 0/0 | 1014 | SUCCEEDED |
| ITTageTable_3 | ITTageTable_3 | `c6573076c5ba/ITTageTable_3` | SUCCEEDED | 1014 | 0/0 | 1014 | SUCCEEDED |
| ITTageTable_4 | ITTageTable_4 | `c6573076c5ba/ITTageTable_4` | SUCCEEDED | 1014 | 0/0 | 1014 | SUCCEEDED |
| L2TLB | L2TLB | `6d4a2ff1e712/L2TLB` | SUCCEEDED | 180735 | 0/0 | 180735 | SUCCEEDED |
| MbistClockGateCell_93 | ClockGateCell93 | `6d68c5409244/MbistClockGateCell_93` | SUCCEEDED | 2 | 0/0 | 2 | SUCCEEDED |
| Predictor | Predictor | `bfd1afc7451e/Predictor` | SUCCEEDED | 528967 | 0/0 | 528967 | SUCCEEDED |
| PtwCache | PtwCache | `22184c5297e2/PtwCache` | SUCCEEDED | 143797 | 0/0 | 143797 | SUCCEEDED |
| SCTable | SCTable | `05394ca211f8/SCTable` | SUCCEEDED | 1123 | 0/0 | 1123 | SUCCEEDED |
| SCTable_1 | SCTable | `05394ca211f8/SCTable_1` | SUCCEEDED | 1123 | 0/0 | 1123 | SUCCEEDED |
| SCTable_2 | SCTable | `05394ca211f8/SCTable_2` | SUCCEEDED | 1123 | 0/0 | 1123 | SUCCEEDED |
| SCTable_3 | SCTable | `05394ca211f8/SCTable_3` | SUCCEEDED | 1123 | 0/0 | 1123 | SUCCEEDED |
| SRAMTemplate | SRAMTemplate | `62fccb92c825/SRAMTemplate` | SUCCEEDED | 394 | 0/0 | 394 | SUCCEEDED |
| SRAMTemplate_100 | SRAMTemplate | `62fccb92c825/SRAMTemplate_100` | SUCCEEDED | 301 | 0/0 | 301 | SUCCEEDED |
| SRAMTemplate_116 | SRAMTemplate | `62fccb92c825/SRAMTemplate_116` | SUCCEEDED | 359 | 0/0 | 359 | SUCCEEDED |
| SRAMTemplate_124 | SRAMTemplate | `62fccb92c825/SRAMTemplate_124` | SUCCEEDED | 371 | 0/0 | 371 | SUCCEEDED |
| SRAMTemplate_128 | SRAMTemplateNewForm | （无已跟踪 receipt） | — | (p2507 fastlane) | — | 2507 | SUCCEEDED |
| SRAMTemplate_129 | SRAMTemplate | `62fccb92c825/SRAMTemplate_129` | SUCCEEDED | 468 | 0/0 | 468 | SUCCEEDED |
| SRAMTemplate_143 | SRAMTemplate | `62fccb92c825/SRAMTemplate_143` | SUCCEEDED | 468 | 0/0 | 468 | SUCCEEDED |
| SRAMTemplate_145 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_145` | SUCCEEDED | 602 | 0/0 | 602 | SUCCEEDED |
| SRAMTemplate_146 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_146` | SUCCEEDED | 75 | 0/0 | 75 | SUCCEEDED |
| SRAMTemplate_148 | SRAMTemplate | `62fccb92c825/SRAMTemplate_148` | SUCCEEDED | 322 | 0/0 | 322 | SUCCEEDED |
| SRAMTemplate_150 | SRAMTemplate | `62fccb92c825/SRAMTemplate_150` | SUCCEEDED | 321 | 0/0 | 321 | SUCCEEDED |
| SRAMTemplate_152 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_152` | SUCCEEDED | 440 | 0/0 | 440 | SUCCEEDED |
| SRAMTemplate_153 | SRAMTemplate | `62fccb92c825/SRAMTemplate_153` | SUCCEEDED | 87 | 0/0 | 87 | SUCCEEDED |
| SRAMTemplate_154 | SRAMTemplate | `62fccb92c825/SRAMTemplate_154` | SUCCEEDED | 63 | 0/0 | 63 | SUCCEEDED |
| SRAMTemplate_155 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_155` | SUCCEEDED | 569 | 0/0 | 569 | SUCCEEDED |
| SRAMTemplate_159 | SRAMTemplate | `62fccb92c825/SRAMTemplate_159` | SUCCEEDED | 322 | 0/0 | 322 | SUCCEEDED |
| SRAMTemplate_16 | SRAMTemplate | `62fccb92c825/SRAMTemplate_16` | SUCCEEDED | 352 | 0/0 | 352 | SUCCEEDED |
| SRAMTemplate_162 | SRAMTemplate | `62fccb92c825/SRAMTemplate_162` | SUCCEEDED | 322 | 0/0 | 322 | SUCCEEDED |
| SRAMTemplate_163 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_163` | SUCCEEDED | 440 | 0/0 | 440 | SUCCEEDED |
| SRAMTemplate_164 | SRAMTemplate | `62fccb92c825/SRAMTemplate_164` | SUCCEEDED | 87 | 0/0 | 87 | SUCCEEDED |
| SRAMTemplate_165 | SRAMTemplate | `62fccb92c825/SRAMTemplate_165` | SUCCEEDED | 63 | 0/0 | 63 | SUCCEEDED |
| SRAMTemplate_166 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_166` | SUCCEEDED | 569 | 0/0 | 569 | SUCCEEDED |
| SRAMTemplate_178 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_178` | SUCCEEDED | 569 | 0/0 | 569 | SUCCEEDED |
| SRAMTemplate_181 | SRAMTemplate | `62fccb92c825/SRAMTemplate_181` | SUCCEEDED | 322 | 0/0 | 322 | SUCCEEDED |
| SRAMTemplate_185 | SRAMTemplateNewForm | `170a4d608018/SRAMTemplate_185` | SUCCEEDED | 440 | 0/0 | 440 | SUCCEEDED |
| SRAMTemplate_186 | SRAMTemplate | `62fccb92c825/SRAMTemplate_186` | SUCCEEDED | 87 | 0/0 | 87 | SUCCEEDED |
| SRAMTemplate_187 | SRAMTemplate | `62fccb92c825/SRAMTemplate_187` | SUCCEEDED | 63 | 0/0 | 63 | SUCCEEDED |
| SRAMTemplate_2 | SRAMTemplate | `62fccb92c825/SRAMTemplate_2` | SUCCEEDED | 394 | 0/0 | 394 | SUCCEEDED |
| SRAMTemplate_32 | SRAMTemplate | `62fccb92c825/SRAMTemplate_32` | SUCCEEDED | 352 | 0/0 | 352 | SUCCEEDED |
| SRAMTemplate_36 | SRAMTemplate | `62fccb92c825/SRAMTemplate_36` | SUCCEEDED | 189 | 0/0 | 189 | SUCCEEDED |
| SRAMTemplate_4 | SRAMTemplate | `62fccb92c825/SRAMTemplate_4` | SUCCEEDED | 352 | 0/0 | 352 | SUCCEEDED |
| SRAMTemplate_44 | SRAMTemplate | `62fccb92c825/SRAMTemplate_44` | SUCCEEDED | 120 | 0/0 | 120 | SUCCEEDED |
| SRAMTemplate_45 | SRAMTemplate | `62fccb92c825/SRAMTemplate_45` | SUCCEEDED | 148 | 0/0 | 148 | SUCCEEDED |
| SRAMTemplate_64 | SRAMTemplate | `62fccb92c825/SRAMTemplate_64` | SUCCEEDED | 58 | 0/0 | 58 | SUCCEEDED |
| SRAMTemplate_68 | SRAMTemplate | `62fccb92c825/SRAMTemplate_68` | SUCCEEDED | 145 | 0/0 | 145 | SUCCEEDED |
| SRAMTemplate_76 | SRAMTemplate | `62fccb92c825/SRAMTemplate_76` | SUCCEEDED | 478 | 0/0 | 478 | SUCCEEDED |
| SRAMTemplate_78 | SRAMTemplate | `62fccb92c825/SRAMTemplate_78` | SUCCEEDED | 478 | 0/0 | 478 | SUCCEEDED |
| SRAMTemplate_8 | SRAMTemplate | `62fccb92c825/SRAMTemplate_8` | SUCCEEDED | 352 | 0/0 | 352 | SUCCEEDED |
| SRAMTemplate_84 | SRAMTemplate | `62fccb92c825/SRAMTemplate_84` | SUCCEEDED | 301 | 0/0 | 301 | SUCCEEDED |
| SRAMTemplate_86 | SRAMTemplate | `62fccb92c825/SRAMTemplate_86` | SUCCEEDED | 301 | 0/0 | 301 | SUCCEEDED |
| SRAMTemplate_88 | SRAMTemplate | `62fccb92c825/SRAMTemplate_88` | SUCCEEDED | 301 | 0/0 | 301 | SUCCEEDED |
| SRAMTemplate_92 | SRAMTemplate | `62fccb92c825/SRAMTemplate_92` | SUCCEEDED | 301 | 0/0 | 301 | SUCCEEDED |
| Slice | Slice | `0dc9c4532cf5/Slice` | SUCCEEDED | 68305 | 0/0 | 68305 | SUCCEEDED |
| Slice_1 | Slice | `0dc9c4532cf5/Slice_1` | SUCCEEDED | 68308 | 0/0 | 68308 | SUCCEEDED |
| Slice_2 | Slice | `0dc9c4532cf5/Slice_2` | SUCCEEDED | 68310 | 0/0 | 68310 | SUCCEEDED |
| Slice_3 | Slice | `0dc9c4532cf5/Slice_3` | SUCCEEDED | 68311 | 0/0 | 68311 | SUCCEEDED |
| SplittedSRAMTemplate | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate` | SUCCEEDED | 787 | 0/0 | 787 | SUCCEEDED |
| SplittedSRAMTemplate_1 | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate_1` | SUCCEEDED | 787 | 0/0 | 787 | SUCCEEDED |
| SplittedSRAMTemplate_2 | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate_2` | SUCCEEDED | 1505 | 0/0 | 1505 | SUCCEEDED |
| SplittedSRAMTemplate_23 | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate_23` | SUCCEEDED | 110 | 0/0 | 110 | SUCCEEDED |
| SplittedSRAMTemplate_25 | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate_25` | SUCCEEDED | 478 | 0/0 | 478 | SUCCEEDED |
| SplittedSRAMTemplate_27 | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate_27` | SUCCEEDED | 955 | 0/0 | 955 | SUCCEEDED |
| SplittedSRAMTemplate_3 | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate_3` | SUCCEEDED | 120 | 0/0 | 120 | SUCCEEDED |
| SplittedSRAMTemplate_4 | SplittedSRAMTemplate | `62fccb92c825/SplittedSRAMTemplate_4` | SUCCEEDED | 148 | 0/0 | 148 | SUCCEEDED |
| TagArray | TagArray | `b25ad3da9f18/TagArray` | SUCCEEDED | 737 | 0/0 | 737 | SUCCEEDED |
| TagSRAMBank | TagArray | `b25ad3da9f18/TagSRAMBank` | SUCCEEDED | 369 | 0/0 | 369 | SUCCEEDED |
| TageBTable | TageBTable | `c6573076c5ba/TageBTable` | SUCCEEDED | 396 | 0/0 | 396 | SUCCEEDED |
| TageTable | TageTable | `e0bc44bf9a73/TageTable` | PASS_DEAD_REF | 1585 | 48/0 | 1585 | PASS_DEAD_REF |
| TageTable_1 | TageTable | `e0bc44bf9a73/TageTable_1` | PASS_DEAD_REF | 1585 | 48/0 | 1585 | PASS_DEAD_REF |
| TageTable_2 | TageTable | `e0bc44bf9a73/TageTable_2` | PASS_DEAD_REF | 1585 | 48/0 | 1585 | PASS_DEAD_REF |
| TageTable_3 | TageTable | `e0bc44bf9a73/TageTable_3` | PASS_DEAD_REF | 1585 | 48/0 | 1585 | PASS_DEAD_REF |
| Tage_SC | Tage_SC | `335a330a9baa/Tage_SC` | PASS_DEAD_REF | 16112 | 192/0 | 16112 | PASS_DEAD_REF |

## 4. 对账


### 4.1 实测（P1 证明提交 4464d4e05，P2 证明提交 68d1a0932）

| target | 阶段 | 旧 passing | 新 passing | 差 | verdict | failing/unv/aborted/unmatched | receipt | sha256 |
|---|---|---|---|---|---|---|---|---|
| Arbiter1_L1BankedDataWriteReq | P1 | 521 | 521 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/Arbiter1_L1BankedDataWriteReq/receipt.json` | `a50083eff2c465ce3e4839043280c7f9d53def86c4799f3febe977338cbfa391` |
| Arbiter1_L1BankedDataWriteReqCtrl | P1 | 53 | 53 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/Arbiter1_L1BankedDataWriteReqCtrl/receipt.json` | `375e0bc6b5cd5d8d63954ec65df9eadc211bdcd48b693c8799ddc85528c537ff` |
| Arbiter1_TagWriteReq | P1 | 49 | 49 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/Arbiter1_TagWriteReq/receipt.json` | `84e18aa3e8c5ed66945ce299ead236edec129f5ded85ad59a5b14b114a238fcd` |
| Directory | P1 | 1953 | 1953 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/Directory/receipt.json` | `db0a603aabc4abec88f6629554fe63642075edb67341745a54114f4b0ef15fb4` |
| Directory_1 | P1 | 1954 | 1954 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/Directory_1/receipt.json` | `f72aaddce5e1dd81d4149a30316c932ef722dca9ee983add56100327b216ee01` |
| Directory_2 | P1 | 1954 | 1954 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/Directory_2/receipt.json` | `a068afebdeba6661b7a329fc022cc715eca7931c3335138a48d4815407022f19` |
| Directory_3 | P1 | 1955 | 1955 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/Directory_3/receipt.json` | `0c29992057c0e5d78b5b4161648f0cde527795990bf2eebbff60538cc4922928` |
| MissReadyGen | P1 | 412 | 412 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/MissReadyGen/receipt.json` | `0f9d7a5db1867ac9bf4ca844cb451bb2cd0b2f73da38d07399af80161e39756b` |
| PrefetcherMonitor | P1 | 96 | 96 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/PrefetcherMonitor/receipt.json` | `55a85f27004d21a7bd7d00fb38943b545e85e1c42655d3fa10344fbdcd0d998e` |
| RecentRequestTable | P1 | 97 | 97 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/RecentRequestTable/receipt.json` | `53a8498c9877a3652cd6ce8cbeb3d225f720604cdf98768e7f2f39e291b3a83c` |
| RecentRequestTable_1 | P1 | 100 | 100 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/RecentRequestTable_1/receipt.json` | `c3ddbeba7c31c38bc667d613ff7063db0fa321c352d832b64fa32bd37fe5a58a` |
| SRAMTemplateWithFixedWidth | P1 | 351 | 351 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SRAMTemplateWithFixedWidth/receipt.json` | `dddae69a3118ac05ed2a184590c31bd2c584c702041ccbe39c0e72df31a20e7b` |
| SRAMTemplateWithFixedWidth_12 | P1 | 351 | 351 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SRAMTemplateWithFixedWidth_12/receipt.json` | `cabf52d23d6f6bd40a52f42dc3a331eb0b7cf48192c76c323903e49f9db6bc11` |
| SRAMTemplateWithFixedWidth_28 | P1 | 351 | 351 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SRAMTemplateWithFixedWidth_28/receipt.json` | `809ee27d02f5ad0c431e0926e7b3a7cb41964d44df57e01b2e5662e0b44c3686` |
| SRAMTemplateWithFixedWidth_4 | P1 | 351 | 351 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SRAMTemplateWithFixedWidth_4/receipt.json` | `e07430a745a810cea4ab99ebcae5f1ad88a5231ba48d44585024befc3c497c7c` |
| SplittedSRAM | P1 | 1480 | 1480 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SplittedSRAM/receipt.json` | `96473248bc13500267bbf687a26a49f243ac81dd5b5d0f0eb98a47d448227a26` |
| SplittedSRAM_1 | P1 | 2487 | 2487 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SplittedSRAM_1/receipt.json` | `c4ac67f939ce5bbdea55966f0e7b9201e827411cd38c8c34e04518214a1c4b6f` |
| SplittedSRAM_2 | P1 | 7472 | 7472 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SplittedSRAM_2/receipt.json` | `a214043934f675bec40006bedc480454b28159ecca870a7127845e882bbc4b40` |
| SplittedSRAM_3 | P1 | 1286 | 1286 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SplittedSRAM_3/receipt.json` | `1c66041786a606c2397fa0a6fa4907d695c06639ae13804b31a8127384a5c12b` |
| SplittedSRAM_4 | P1 | 1286 | 1286 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SplittedSRAM_4/receipt.json` | `e7e57dbcaf6b6130c99ce818b8cbc6a6c7f2e90be27f2300281bbd609d3adc52` |
| SplittedSRAM_5 | P1 | 1286 | 1286 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SplittedSRAM_5/receipt.json` | `a5e8a4e7b0d66d5246a56ac16669914ee923eea17dae61d47c7df6f8655a84ff` |
| SplittedSRAM_6 | P1 | 1286 | 1286 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/SplittedSRAM_6/receipt.json` | `f85757ecafca0ddf34f9ce0ab64aa9240f20932449b9480feede76954a1f01b7` |
| TreeArbiter | P1 | 981 | 981 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/4464d4e059b0/TreeArbiter/receipt.json` | `ce27640dada5453ba17c7cd6e596b0d6bad65b281d4bd465176ac782204a3313` |
| BankedDataArray | P2 | 10342 | 10342 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/BankedDataArray/receipt.json` | `53bffa5d42781cfd70e24a6da96ff0432ae239204ccfbe2519c7fb63693a6b15` |
| BitmapCache | P2 | 13069 | 13069 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/BitmapCache/receipt.json` | `0aad390e53541a79d0879f011f489153d0a1a39acb7cfbb4d5ca6d2666f7f2ea` |
| ClockMux | P2 | 1 | 1 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ClockMux/receipt.json` | `2afc9502ce9759564d4be9b143bbfb67a4ff8cb9b6b3eaf374be808bb3b6e03e` |
| DCache | P2 | 82086 | 82086 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DCache/receipt.json` | `e85050b68efe1e64ec36b124ef88e7663b3ed8c136d3fd98a8262d52a913fb26` |
| DataSRAMBank | P2 | 1205 | 1205 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataSRAMBank/receipt.json` | `b9b68b32a91b414131a1ab169d01932f491874670f6624b37c6c832a01e17469` |
| DataSRAMBank_1 | P2 | 1205 | 1205 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataSRAMBank_1/receipt.json` | `f2daea30f9909cdba2edd421bcd8e786cf4c85c8a21119c58be1d5abf9096a7c` |
| DataSRAMBank_2 | P2 | 1205 | 1205 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataSRAMBank_2/receipt.json` | `0a67226a4f546fe04b7b633acac34f23d0d552d27da7ab610c1b233f12fb2bf7` |
| DataSRAMBank_4 | P2 | 1205 | 1205 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataSRAMBank_4/receipt.json` | `9304820ddceb71117ed1dde53ed39fa93516fbf1cd33a6558d354666a9e4196d` |
| DataStorage | P2 | 2532 | 2532 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataStorage/receipt.json` | `23e0a777ea2f8409fbceb51ca47a7e2ae744844244be48c1b2b59225d87614b5` |
| DataStorage_1 | P2 | 2533 | 2533 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataStorage_1/receipt.json` | `8818e587d36ad82061456d5c816a679539583ba3c99c545391cf6162943dfb37` |
| DataStorage_2 | P2 | 2534 | 2534 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataStorage_2/receipt.json` | `f4daf2dccafb3db4bbc44fe0b57f2733cf5beb520d2f379f62c21e9e502b50c7` |
| DataStorage_3 | P2 | 2534 | 2534 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DataStorage_3/receipt.json` | `3ee8c31d89d0ac77bd01fd7a9fcc8998fe9e082fd484c4e41b691069eb9765c3` |
| DuplicatedTagArray | P2 | 2460 | 2460 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/DuplicatedTagArray/receipt.json` | `fda4c7d363ca13e44744b693a58de15f3984ae4f4bf8f5549072f0bd9675016e` |
| FTB | P2 | 8605 | 8605 | +0 | PASS_DEAD_REF | 0/0/0/0 (unread_ref 50, unread_impl 0) | `evidence/68d1a0932a12/FTB/receipt.json` | `8b0c2d65afd454b50370889407a47578496f7fdae676b33ac4cee56385352234` |
| FTBBank | P2 | 3276 | 3276 | +0 | PASS_DEAD_REF | 0/0/0/0 (unread_ref 50, unread_impl 0) | `evidence/68d1a0932a12/FTBBank/receipt.json` | `9898e35caa670d48d1470f9bf7e4d50b4db229174f441d3f908dfe568379b51d` |
| FoldedSRAMTemplate | P2 | 113 | 113 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/FoldedSRAMTemplate/receipt.json` | `c623417a838aff7d995a4bbe12d9b2eed84096e908807bca76aeb777866eb5b7` |
| FoldedSRAMTemplate_1 | P2 | 148 | 148 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/FoldedSRAMTemplate_1/receipt.json` | `c8a819d33e490c9cf1783e519bfe05ef930b8dd51597b79b55d3eb1978b900be` |
| FoldedSRAMTemplate_20 | P2 | 109 | 109 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/FoldedSRAMTemplate_20/receipt.json` | `b88efd89db1d03f539d729afc2f6e989bb6cc210acc2b3745a1180aed5b122d5` |
| FoldedSRAMTemplate_22 | P2 | 443 | 443 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/FoldedSRAMTemplate_22/receipt.json` | `74f3805e9fc55812d1a0e787466fc2daffc28d865d2e489307cb2b4a1b2bc542` |
| FoldedSRAMTemplate_24 | P2 | 846 | 846 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/FoldedSRAMTemplate_24/receipt.json` | `712a40656f9d631f1b4de97d45f56392739b4fcbf94db4421ee2b309bacab2f9` |
| GatedSplittedSRAM | P2 | 2272 | 2272 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/GatedSplittedSRAM/receipt.json` | `535b17674207a81dba0b89e38fb7f78cd397d5a4f4b93706b8bce1833fa9a90a` |
| GatedSplittedSRAM_1 | P2 | 2272 | 2272 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/GatedSplittedSRAM_1/receipt.json` | `f571980f277619a2e05f8169220227bb229dcf1aefca72eaf3242924062e26f3` |
| GatedSplittedSRAM_2 | P2 | 2272 | 2272 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/GatedSplittedSRAM_2/receipt.json` | `b6e716058ef5e5d3a68b33da5dc910773900b3fd584ef5852328152ec20aeab9` |
| GatedSplittedSRAM_3 | P2 | 2272 | 2272 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/GatedSplittedSRAM_3/receipt.json` | `523c41b1f133f68799a7d8a179e20251d50a03c0aac46fc80bb5c72ba8fb85a1` |
| ICache | P2 | 21174 | 21174 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ICache/receipt.json` | `0cc254c06aa6879675b5e7db21e625b2cd07d63f9e21b35dd786feb75519a152` |
| ICacheMetaArray | P2 | 2500 | 2500 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ICacheMetaArray/receipt.json` | `19bbd98a76cc6a4bdd95723737e042064bb0437e8e909cdd41a32940cceaf50a` |
| ITTage | P2 | 10426 | 10426 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ITTage/receipt.json` | `91d4dba8ea262bca8d923c2e9b7bbc746a9f25259102d81268c842f38a482fa0` |
| ITTageTable | P2 | 682 | 682 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ITTageTable/receipt.json` | `042b0d94c7ac70ae51549700bf52e3a3b4bd553e01534a72628f2d71ba69bd62` |
| ITTageTable_1 | P2 | 682 | 682 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ITTageTable_1/receipt.json` | `7ad568b3b5e6139c80c02bb7ac06302ee54e6e0cf41fe98861c69a5953d66c24` |
| ITTageTable_2 | P2 | 1014 | 1014 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ITTageTable_2/receipt.json` | `0746db7023ddc6bf3772feea9e8f8e3a6ac5f6f25d74228d37233a59fa8c2722` |
| ITTageTable_3 | P2 | 1014 | 1014 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ITTageTable_3/receipt.json` | `f99705a29d6976d1b5fdce0add95d07d4e234b392cb65e447b4576b5d3d43042` |
| ITTageTable_4 | P2 | 1014 | 1014 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/ITTageTable_4/receipt.json` | `d969010349ff0f7e0dceaf23d09e1328b0f6ae85691f0fb0a7f7f7b6c4d047d5` |
| L2TLB | P2 | 180735 | 180735 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/L2TLB/receipt.json` | `2d1d2b42ac7d4c734293fe8552384d38c6ced83b8f5746fc375142d4228d393b` |
| MbistClockGateCell_93 | P2 | 2 | 2 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/MbistClockGateCell_93/receipt.json` | `3bbd4496c197ef3be0c084a25b8f5d3221d53f24595c236a9e7bc7e5fd25a84d` |
| Predictor | P2 | 528967 | 528967 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/Predictor/receipt.json` | `47e7c0faf87fd17269be1b83218d1fcca5ffb6b6351d579fd760bf86062b89ac` |
| PtwCache | P2 | 143797 | 143797 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/PtwCache/receipt.json` | `ba3b3f6a40be19d3c51fb8ffa8dd296e130be77bb8bc4c3c5ec5c26b63dd4a67` |
| SCTable | P2 | 1123 | 1123 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SCTable/receipt.json` | `e1c8a3c88badacf26f3bf0569928ef7153c26a40540449e4b8d4484cdee4c5e4` |
| SCTable_1 | P2 | 1123 | 1123 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SCTable_1/receipt.json` | `b8669069e41c16d4d3601531a64c744443bcaf63ec5460a3804ec831a3df0ee5` |
| SCTable_2 | P2 | 1123 | 1123 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SCTable_2/receipt.json` | `4f0950c76152b270d176cce836b6f707be646bb87e0c2b8bba6dbd1a8b73a9dd` |
| SCTable_3 | P2 | 1123 | 1123 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SCTable_3/receipt.json` | `7041cd43462855396c7c984c587c2c3895e6c1993d19d0264263d0e324909c58` |
| SRAMTemplate | P2 | 394 | 394 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate/receipt.json` | `7c0b99f830c03f8be958e99095baf2aec5946ca983eb60d04488974b1449a0fe` |
| SRAMTemplate_100 | P2 | 301 | 301 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_100/receipt.json` | `122cfab231737df890462d47a58a0dcb789c77720caad8fc7bab20785aec2717` |
| SRAMTemplate_116 | P2 | 359 | 359 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_116/receipt.json` | `c88696e72a54533f14f95dc6780cd9ae556b9e1b0cf22d037fccd1c011c5063c` |
| SRAMTemplate_124 | P2 | 371 | 371 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_124/receipt.json` | `e5510c1f63fbd213dc0d4a1d3ae1b7221a7fc85afb2de33c2e0af2357d925b76` |
| SRAMTemplate_128 | P2 | 2507(fastlane) | 2507 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_128/receipt.json` | `3dcb629a17cc380ee3f6a4b42f90fc053c689b03c1510b3809e74f1bcfe669fd` |
| SRAMTemplate_129 | P2 | 468 | 468 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_129/receipt.json` | `fcce550b458390fed237b6ca9617a83d5659dd4edf671e655d664c3e498c4d95` |
| SRAMTemplate_143 | P2 | 468 | 468 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_143/receipt.json` | `3da050ae5808d7f81ff62c077ceef2871067d70e2f9d637d14641b2ac3d8e597` |
| SRAMTemplate_145 | P2 | 602 | 602 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_145/receipt.json` | `e67280d5a410354a639df596155a4713bf70760d6011b97918d66dc3e6a8f11d` |
| SRAMTemplate_146 | P2 | 75 | 75 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_146/receipt.json` | `15bfcf702130b5ab24721ad56a9bb2e9e4fc417697fae27c37b413f1db6677b4` |
| SRAMTemplate_148 | P2 | 322 | 322 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_148/receipt.json` | `b5007a6a6f9d3f0e0299fb313336c064d0acff4b04abf10c15f97d6860d84b9b` |
| SRAMTemplate_150 | P2 | 321 | 321 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_150/receipt.json` | `5cd8fb7bc82f6f84dfc49f934c46eaaefd9b40e7602745f2a9de0505a9ae2559` |
| SRAMTemplate_152 | P2 | 440 | 440 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_152/receipt.json` | `d44c5d75eb7a35ae6418cc417e3815e629210270398b5376eb0c26dfb3d66c6c` |
| SRAMTemplate_153 | P2 | 87 | 87 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_153/receipt.json` | `1df1e6073500e610224fb70203095ab4d5432b1ade89579cc8b68fea9a8beb9d` |
| SRAMTemplate_154 | P2 | 63 | 63 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_154/receipt.json` | `0ba5d2f4b16850c48a2d7ca6f07ec2373c51c0cd0034f285ced33a21bc1c6450` |
| SRAMTemplate_155 | P2 | 569 | 569 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_155/receipt.json` | `e130f07035a579b0ead446ca5ab324e79ba4b97770328f8c9c6cce093f27fd27` |
| SRAMTemplate_159 | P2 | 322 | 322 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_159/receipt.json` | `20b6c668cd8177809f433a2e1f0034b7f3c4a1591b13deaad5e9bb11057823ee` |
| SRAMTemplate_16 | P2 | 352 | 352 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_16/receipt.json` | `93a85bc3b2ae96cf15de70da5f6981810464862e312eef5b6f6fda1e1e2bad3a` |
| SRAMTemplate_162 | P2 | 322 | 322 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_162/receipt.json` | `d2b1e5fd41f3fded81593764e36d2d252a8c20165c487cb449a3d79efed239c4` |
| SRAMTemplate_163 | P2 | 440 | 440 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_163/receipt.json` | `8554692331897fc6d808d0b7c809985b42ca476155e8fc9a589b3a6cd3e29ea7` |
| SRAMTemplate_164 | P2 | 87 | 87 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_164/receipt.json` | `bf1ff86dbd61ef8d0f5fda0c57f12f350ddcdbb61d94b44a2b97f35b4edf0c28` |
| SRAMTemplate_165 | P2 | 63 | 63 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_165/receipt.json` | `a4a31491e3dd53afdd0ec0e767332f39b90161552f00a911b8d9545d387b5506` |
| SRAMTemplate_166 | P2 | 569 | 569 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_166/receipt.json` | `6e1019e1e90f372d068e9c89f1a38609ddede5aca97bcae5354652a7e2079220` |
| SRAMTemplate_178 | P2 | 569 | 569 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_178/receipt.json` | `1f806de07af34dfbc2c4e2451d754c8681223bda3575ed42691b4a9a3355bab0` |
| SRAMTemplate_181 | P2 | 322 | 322 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_181/receipt.json` | `74ab98aec7fad8859949b0031e4cef19c6c4c9011675d7547de4f11481111710` |
| SRAMTemplate_185 | P2 | 440 | 440 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_185/receipt.json` | `5bd0507027a484f4985bf66d0d79c12ad489cc2c3d244211d9c2b4c841f80599` |
| SRAMTemplate_186 | P2 | 87 | 87 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_186/receipt.json` | `f6cf434468006548ce372ed947c7e3122b4e26196fe50122a408f34d2c19a2b4` |
| SRAMTemplate_187 | P2 | 63 | 63 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_187/receipt.json` | `49db584a66906b6e643f5c92bdaeea5f14893eb280f8b7fe56058cad6cb68214` |
| SRAMTemplate_2 | P2 | 394 | 394 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_2/receipt.json` | `ff2052fa934c1e5f59f0e597a1e439de2c40cb02e15fa7fe7c9df6aad57e16a4` |
| SRAMTemplate_32 | P2 | 352 | 352 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_32/receipt.json` | `a7c41540f1f2dd94be2c9c0c40b4e242cc8a0217ca69d6443544720908921def` |
| SRAMTemplate_36 | P2 | 189 | 189 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_36/receipt.json` | `baf9d7bccd6c8f014f62e0496403724da006fa98a32325364da3535c4ff6ed51` |
| SRAMTemplate_4 | P2 | 352 | 352 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_4/receipt.json` | `9ca5a8d49b2f7544e889300956b428c4d6a399a1f962c2dce647daba44e81e8b` |
| SRAMTemplate_44 | P2 | 120 | 120 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_44/receipt.json` | `6f489e53b9d0492f5e33b800cae63e08821e31031ea8c397ff590571c6cc96a2` |
| SRAMTemplate_45 | P2 | 148 | 148 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_45/receipt.json` | `10fef485abb9e72f16919baeee686eac3ef668aabed60672bd1a21b2c43bbc2d` |
| SRAMTemplate_64 | P2 | 58 | 58 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_64/receipt.json` | `23e08319af18b21ad26d33296b405a8de253d88f6ef2359c90fa484ad782f339` |
| SRAMTemplate_68 | P2 | 145 | 145 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_68/receipt.json` | `01ee8cad68369cb342f64ca0f0308f9463b88efc3975ca49ea35a84a00cee457` |
| SRAMTemplate_76 | P2 | 478 | 478 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_76/receipt.json` | `6656df13147c2815e83a42f1f51da53c8884eb49e7cdf2a4a2b28e316c37fb09` |
| SRAMTemplate_78 | P2 | 478 | 478 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_78/receipt.json` | `56224f87e33bc90720d823436ec7749b12caddd93f2bd50e3fe4d237d1fc75b3` |
| SRAMTemplate_8 | P2 | 352 | 352 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_8/receipt.json` | `d5fdea5f6e039a3c5c89b0d00aef43b584db0cccdcb9d926cfd84ebab46c2d4b` |
| SRAMTemplate_84 | P2 | 301 | 301 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_84/receipt.json` | `206646f921ccd5236830f863ee65bad475ff15f29dc477d59bff2416fa5cbfca` |
| SRAMTemplate_86 | P2 | 301 | 301 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_86/receipt.json` | `8318fc370717d425500e3431bc03586f50540099f81dfab4948b5a03d1e0a032` |
| SRAMTemplate_88 | P2 | 301 | 301 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_88/receipt.json` | `abaa89dd4557d15661a4db6f3a28e5659d307642b94b705cbcb0dfaf757482f1` |
| SRAMTemplate_92 | P2 | 301 | 301 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SRAMTemplate_92/receipt.json` | `0c78052a41c9e3538018ea9f203efcecab793e5310d55af561a70f4e8385f00d` |
| Slice | P2 | 68305 | 68305 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/Slice/receipt.json` | `1a41a584f7c30cbfce9934f08fe6b4f60f173f89b6ba556856274a2780a2b203` |
| Slice_1 | P2 | 68308 | 68308 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/Slice_1/receipt.json` | `e64f79ea33f1296df9ecadb13be96256fddf752b81d3786ce3287b84bc0cfc52` |
| Slice_2 | P2 | 68310 | 68310 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/Slice_2/receipt.json` | `d430600d84d8337ce94da1a9957bffcbfe1cd1acbfb3eea1f4a1c7023c1d4598` |
| Slice_3 | P2 | 68311 | 68311 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/Slice_3/receipt.json` | `3a800c96e0626c32712a42bf61ce0e7bc1b541f38eed4ee2af273a825c3b39ba` |
| SplittedSRAMTemplate | P2 | 787 | 787 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate/receipt.json` | `cf4d564d6f4f29fcc3fa2d780a2d0c63c4383dfaad58b3217f7b7099675fb5c9` |
| SplittedSRAMTemplate_1 | P2 | 787 | 787 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate_1/receipt.json` | `f78df7f27c9f340f56af538a4af20ad407f8815b75bd3c7b272a8ffd2f01e2f1` |
| SplittedSRAMTemplate_2 | P2 | 1505 | 1505 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate_2/receipt.json` | `d1cacda56d07f2cf2e34261564163bf187d6f2f00c35de006c0113560a97d48d` |
| SplittedSRAMTemplate_23 | P2 | 110 | 110 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate_23/receipt.json` | `7448c24871e088e913b7d0c58413765cb1efff3973aa10ddd0352bf3ce4a93af` |
| SplittedSRAMTemplate_25 | P2 | 478 | 478 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate_25/receipt.json` | `7331eb9f928aa8ac44b0ee54112ad7df6ae70e52c5c37f5dbd7238ab09e3daa3` |
| SplittedSRAMTemplate_27 | P2 | 955 | 955 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate_27/receipt.json` | `c62992517a56e5a130ec05536ffb374a69be6e8fb22c893443ab839c990b2d4d` |
| SplittedSRAMTemplate_3 | P2 | 120 | 120 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate_3/receipt.json` | `ea11c61ef96ac5c9a003e236804ab8a087b4391fae974f272de6e3aa6c425fcd` |
| SplittedSRAMTemplate_4 | P2 | 148 | 148 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/SplittedSRAMTemplate_4/receipt.json` | `4fe8af75d944f365c46a7bf535866cc102b038ddfed5664d23b4df9e70696db4` |
| TagArray | P2 | 737 | 737 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/TagArray/receipt.json` | `3ed1b97cef615273bf9b443f3277bfd39c4b1c20c1430244c4b3313aba87ae21` |
| TagSRAMBank | P2 | 369 | 369 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/TagSRAMBank/receipt.json` | `d44598420a782ca26d2c0d31b1328db9ff7a813bd24bb4edcedc0fda526e939c` |
| TageBTable | P2 | 396 | 396 | +0 | SUCCEEDED | 0/0/0/0 (unread_ref 0, unread_impl 0) | `evidence/68d1a0932a12/TageBTable/receipt.json` | `acd090bf9e567c2becd06432ebee962d7c7c8b5343d269b20c661ab56e778641` |
| TageTable | P2 | 1585 | 1585 | +0 | PASS_DEAD_REF | 0/0/0/0 (unread_ref 48, unread_impl 0) | `evidence/68d1a0932a12/TageTable/receipt.json` | `027cca7b806250ee32ed6dcf89c85f3430f8abd9a624ea1dbc9cc0c061dee4db` |
| TageTable_1 | P2 | 1585 | 1585 | +0 | PASS_DEAD_REF | 0/0/0/0 (unread_ref 48, unread_impl 0) | `evidence/68d1a0932a12/TageTable_1/receipt.json` | `030ad69859aba0718bce80a98585cf78a3c9439b48cc7d636676757e89fb10b5` |
| TageTable_2 | P2 | 1585 | 1585 | +0 | PASS_DEAD_REF | 0/0/0/0 (unread_ref 48, unread_impl 0) | `evidence/68d1a0932a12/TageTable_2/receipt.json` | `338d2e01d6395f0a8e15a7f0e5063d8100fcef56044ccef702c2c97f677d7606` |
| TageTable_3 | P2 | 1585 | 1585 | +0 | PASS_DEAD_REF | 0/0/0/0 (unread_ref 48, unread_impl 0) | `evidence/68d1a0932a12/TageTable_3/receipt.json` | `e2b2d3d4baab2e5912e2af40067d6bba132f5be1f0afd0a89780288fcafda2cf` |
| Tage_SC | P2 | 16112 | 16112 | +0 | PASS_DEAD_REF | 0/0/0/0 (unread_ref 192, unread_impl 0) | `evidence/68d1a0932a12/Tage_SC/receipt.json` | `6a79061571a9718c223f93c4e0c1a6e30842715db023e1fb26682ae4b014f5a1` |

### 4.2 结论与异常

- 124 份 receipt（P1 23 + P2 101；P2 含 Predictor）全部**等于预测**：passing 差 0、verdict 不变、failing/unverified/aborted/unmatched=0、unread_impl=0；PASS_DEAD_REF 目标 golden-only unread_ref 不变（FTB/FTBBank 50、TageTable×4 48、Tage_SC 192）。
- D1（删 rdata_last_REG）与 ClockGate 换本地件，对父级 passing 均**无影响**。
- ★Composer 未出证（make_rc=1，非 FM 判定）★：`verif/ut/Composer/fm_pins_pre.tcl` 32 条钉点（来源 `child_pairs/Tage_SC.tsv`，c3c9307d6 从旧 Tage_SC 自证收割）的 impl 侧写死 golden ClockGate 的内部名 `.../rcg/CG/EN_reg`；重写件 `rtl/common/ClockGate.sv` 的锁存器叫 `enableLatched` ⇒ FM-036 Unknown name ×32 ⇒ BPU_CHILD_PIN_FAIL ⇒ 没有 sidecar、没有 receipt。首个最小反例：`r:/WORK/Composer/tage/bt/bt_0/array/array_0_0_0/rcg/CG/EN_reg <-> i:/WORK/Composer/tage/bt/u_core/g_bank[0].bt/array/array_0_0_0/rcg/CG/EN_reg`。本 lane 不改钉点（属 bpu-tables 生成物），Composer 仍 STALE。
- SRAMTemplate_128 是首证（之前没有已跟踪 receipt），实测 2507 = fastlane 记录。


