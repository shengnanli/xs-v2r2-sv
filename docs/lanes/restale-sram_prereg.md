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

## 4. 对账

（跑完追加）

