# Lane rr-small（881 个只有 receipt 的中小目标官方重证）

Base：main 22cf76370；claim 0eedf7c37。工作树 /home/eda/xs-env/wt-rr-small，分支 agent/rr-small。
目标清单 docs/lanes/rr-small_targets.tsv（881 行）。本文件的数字是实测值，写下后不回头改。

## 1. 跑前登记（08c5389ed = PROOF_COMMIT 08c5389ed285）

- 516 张新登记：130 张带 `--ut <ut_dir>`（from_ut 可用）；386 张的 Makefile 用变量给出 FM_VARIANTS，
  from_ut 展开不了，所以按 reproof-171 的先例不带 --ut 登记（`ut=null / merge_dup=null / model_applicable=false`）。
- TLBuffer_20 / _22 原来的登记 207 / 227 是旧模型的快照，按当前模型改成 601 / 661，跑前完成。
- 其余 363 张已有登记：按当前模型复算，expected 没变，没动。

## 2. 重证（0f771caa5）

在 08c5389ed 上跑 run_proof.sh，共 368 次调用，jobs=8（同一 ut_dir 最多 6 个一组）。
evidence/08c5389ed285/RUN_CONTEXT.tsv 记录了每个 run 块。只出 receipt，不出证书。

- 880 个：make_rc=0，native SUCCEEDED。verdict 879 个 SUCCEEDED、1 个 PASS_DEAD_REF（Fence：unread_ref=68，
  是只在 golden 一侧的死 ref，和旧 receipt 相同）。failing / unverified / aborted 全为 0，
  compare/unread_impl/bbout 的 unmatched 全为 0。
- **passing 与旧 receipt 逐位比对**（旧 receipt 取 22cf76370 已跟踪 evidence 中 run_id 最新的一份）：
  880/880 的 verdict 和 passing 都相同，merge_dup / vmucp 入口 appvar 也相同。
  - 只有 DebugModule / RNXbar / TXRSP 三个的 `constant_reg` 字段不一样：旧 receipt 是 None（老格式没记这个字段），
    新的是 24 / 3 / 1。passing 相同。
  - 改用 docs/receipt_harvest.tsv 选中的那份旧 receipt 来比，FCVT / FDivSqrt / TXREQ 的 passing 会不同
    （2514/2040/1492 → 2625/2052/2287）。原因是 harvest 选中的是 merge_dup=true 的较早一轮；
    同一目标较新、merge_dup=false 的那一轮旧 receipt（80e9b96e8eb6 / aef3c7e46bc3 等）与本次逐位相同。所以这不是结果偏差。
- **预测比对**（按 docs/fm_predictions/<T>.json，没改任何预测）：
  - 等于预测（逐位相等）：242
  - 差额可以逐位解释（差额被指认成 constant_reg + unread）：93
  - 预测标了模型不适用（model_applicable=false）：545。其中 532 个落在 merge 带内；
    13 个超出带上界：IntToFP / _1 / _2、IntToFP_postnorm / _1 / _2、IntToFP_prenorm、compare_2to1 / _2、
    compare_3to1 / _1 / _2 / _6。原因是登记时按 golden 单模块建模，把子模块当黑盒，把 bbin 位算进了 expected；
    但实际证明是两侧 elaborate 子模块的白盒（receipt golden_closure 含子模块，black_boxes.rpt 0 实例），
    所以 bbin 不构成比较点。这 13 个的 passing 都与旧 receipt 逐位相同。

### Arbiter1_InsUncacheResp：没出 receipt，属于结构性问题

`[598/881] Arbiter1_InsUncacheResp: make_rc=2 no_receipt`。evidence/08c5389ed285/Arbiter1_InsUncacheResp/fm.log 末行：

    FM_MODE_ERROR: matched-unread strengthening needs an explicit whitelist entry; Arbiter1_InsUncacheResp is not on it

verif/ut/InstrUncache/Makefile 对同一目录的三个变体统一设了 `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true`，
但 verif/fm_target_config/ 下只有 InstrMMIOEntry.tcl 和 InstrUncache.tcl，没有 Arbiter1_InsUncacheResp.tcl，
所以 fm_eq.tcl 的白名单检查直接 exit 3，没有 elaborate，也没有 sidecar。
这个结果是确定性的，重跑也一样，所以没有重跑。旧 receipt（evidence/3b72cb1a8513，2026-09-13）早于这条 vmucp 设置，
当时 vmucp=false，passing=34，matched_unread_notcompared_pairs 为空。
InstrMMIOEntry 在 9e97d8679 遇到过同一个问题，当时是补白名单文件解决的。
要修就得改 verif/fm_target_config 或 Makefile 的判据配置，这超出本 lane 的范围，没做，交 integrator 裁定。
该目标仍是 PROVEN_IN_CONE（InstrUncache），没有降档。

## 3. proof_currency 前后（只读调用 wt-ledger-cv/scripts/proof_currency.py）

| | NOT_CURRENT | PROVEN_IN_CONE | PROVEN_DIRECT（经证书 / 经 receipt） |
|---|---|---|---|
| before @0eedf7c37 | 130 | 862 | 610（504 / 106） |
| after  @0f771caa5 | 12 | 141 | 1449（504 / 945） |

- 清单 881 个：839 个变成 PROVEN_DIRECT，全部经 receipt evidence/08c5389ed285
  （721 个原为 IN_CONE，118 个原为 NOT_CURRENT）。
- 全部 1602 个根降档数 0；清单外目标档位变化数 0。
- 清单内另有 42 个没变 DIRECT，逐个原因如下（都没降档）：
  - **impl_golden_uncertified（子模块缺证书，等 integrator 合并时出证书 / 等其他 lane）**，共 25 个：
    - 子模块在本清单内，已经 DIRECT（经 receipt），还缺证书：
      CSA3to2_20 ← Adder_chain_rnd、FDivSqrt、VIAluDecoder、VIntAdder64b；
      FP_INCVT ← CVT64_1、VCVT、VCVT_8、VectorCvt、VectorCvtTop；
      RoundingUnit ← IntToFP / _1 / _2、IntToFP_postnorm / _1 / _2、IntToFP_prenorm、LZA；
      FarShiftRightWithMuxInvFirst ← FAlu；FastArbiter_26 ← RNXbar（NOT_CURRENT）。
    - 子模块不在本清单（IN_CONE）：Queue16_CHIREQ ← TXREQ；Queue16_CHIRSP ← TXRSP；Queue4_CHISNP ← LCredit2Decoupled
      （这三个由 rr-mcnarrow 出）；ArrayMulDataModule ← MulUnit；Queue2_TLBundleA_10 ← TLBuffer_20；
      Queue2_TLBundleA_31 ← TLBuffer_22。
  - **impl_golden_mc_not_shared（子模块是 RAM 模型，不在共享 MC 登记里）**，共 11 个，都还是 IN_CONE：
    Arbiter3_CHIREQ / Arbiter3_TaskBundle / Arbiter3_TaskWithData / Queue4_HintQueueEntry（ram_16x11），
    Queue10_GrantBuffer_Anon（ram_16x25），Queue16_DSBeat / Queue16_GrantQueueData（ram_16x67），
    Queue16_GrantQueueTask / Queue16_TaskBundle / Queue2_CHISNP（ram_data_16x256），Queue16_HintQueueEntry（ram_4x11）。
  - **impl_golden_not_fm_target（子模块不是 FM 目标）**，共 5 个，都还是 NOT_CURRENT：
    DebugModule（AsyncQueueSink）、LCredit2Decoupled_10（Queue4_CHIDAT）、LCredit2Decoupled_8（Queue4_CHIREQ）、
    TLBuffer（Queue2_TLBundleA）、TLBuffer_2（Queue2_TLBundleA_2）。
  - **没出 receipt**，1 个：Arbiter1_InsUncacheResp（见上节）。

  上面后三类的原因，在 before 表里都被 `script_closure_changed:scripts/fm_eq.tcl` 挡在前面，看不到；
  这次重证把脚本闭包刷新后才暴露出来。它们不是本次重证引入的。

## 4. 证书复核

`batch_reproof.py validate`，覆盖 verif/proof_certificates/ 全部 504 张证书（不含 POLICY.json 和 schema-v1.json）：
@0f771caa5 结果为 504/504 True，不通过 0。最终 HEAD 上的复核和 gate_all 结果，见本 lane 交给 integrator 的汇报。
