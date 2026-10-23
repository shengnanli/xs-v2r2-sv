# Lane rr-big（47 个只有 receipt 的大目标官方重证）

Base：main 22cf76370；claim 941cbec6f。清单 docs/lanes/rr-big_targets.tsv（golden ≥5000 行，47 个）。
（lane agent 两次被会话结束打断；最后一步由 integrator 收尾，数字均为实测。）

## 提交
- 1a7b9b58b：跑前补 14 份 fm_predict（PROOF_COMMIT 1a7b9b58bb92）。
- 30625f094：46 个目标 evidence（evidence/1a7b9b58bb92/），只出 receipt 不出证书。
- fff476191：verif/allow/LoadQueueReplay.json 回填 3 个 green_child 证书 sha（AgeDetector_38 / FreeList_5 / LqVAddrModule，
  reproof-171 重出证书后 allow 未跟上；integrator 批准）= LoadQueueReplay 的 PROOF_COMMIT fff476191ab4。
- 本提交：LoadQueueReplay evidence（evidence/fff476191ab4/）+ 本文件。

## 结果
- 46 个（PROOF_COMMIT 1a7b9b58b）：全部 native SUCCEEDED，failing/unverified/aborted/unmatched 0，passing 与旧 receipt 逐位相同。
  预测三类：等于预测 15 / 差额 = constant_reg 29 / 模型不适用 2（StoreQueue、ICacheReplacer）。逐目标见 /home/eda/xs-env/tmp-rrb/compare_mine.tsv。
- LoadQueueReplay（PROOF_COMMIT fff476191）：native SUCCEEDED，passing 114160（= 旧 receipt 7e8081ff298c），failing/unverified/aborted/
  unread_notcompared 0，unmatched 全 0，dirty=False，provisional=False，用时 4047 s；fm_predict check ok（登记 114222，model_applicable=false，merge 带内）。
- 第一次尝试（PROOF_COMMIT 1a7b9b58b）FM 同样 SUCCEEDED 114160，但出 receipt 被拒：green_child_certificate_sha_mismatch:AgeDetector_38。现场 /home/eda/xs-env/tmp-rrb/failed_lqr_attempt1/。
- validate（fff476191）：504/504 True（/home/eda/xs-env/tmp-rrb/validate_fff.txt）。
- proof_currency（30625f094 vs 941cbec6f）：降档 0，升档 44 个（全在清单内）。

## 结构性遗留（重证解决不了）
- AXI4Xbar、AXI4Deinterleaver：impl 复用 golden Queue2_UInt2 / Queue2_AXI4BundleR_3，二者不是 FM target → impl_golden_not_fm_target。
- proof_currency 与 gate 在 integrator 合入 main 后统一跑。
