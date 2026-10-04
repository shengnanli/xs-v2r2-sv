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

（跑完追加）

