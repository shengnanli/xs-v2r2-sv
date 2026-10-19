# Lane reproof-chain（codex 0242 裁定 2，选 (a)）

Base：main ff7650336 + merge agent/assert-hdr（badc1579b）。claim e0106ce8f。工作树 /home/eda/xs-env/wt-reproof-chain，分支 agent/reproof-chain。
本文件记录每层 official 的实测数字；数字一旦写下不回改（后续变化另起一节）。

## 1. 冻结组合提交（HEAD badc1579b）

`batch_reproof.py validate` 对 `verif/proof_certificates/` 下全部 506 个文件逐张复核（列表 = 文件名，含 POLICY.json）：
- 与 A 线 `/home/eda/xs-env/tmp-ah/validate_final.txt`（@0277d4d1f）逐行 diff：**唯一差异是多出 `POLICY`**（`green_child_not_fm_target:POLICY`——
  POLICY.json 是证书策略文件不是证书，A 线列表没放它）。其余 505 行结果完全相同。
- 即：合入 main 的 C 线改动（verif/sim/**、scripts/xstile_rtl_elab.sh）没有让任何证书的 current-valid 变化；A 线 evidence 不需要补。
- 非 True 的 179 张（除 POLICY）= 基线既有 175 张 + 本链 4 张（ExuBlock / Backend / XSCore / XSTile，原因同 assert-hdr.md）。
- 本链各父证明的 green child（allow 里的 design 去重：Backend 31 / XSCore 3 / XSTile 5）除 ExuBlock / Backend / XSCore 本链外**全部 True**，
  没有一个落在 175 张旧证书里——不需要 oldcert-triage 协调。
- ExuBlock 自身无 allow（全白盒 signoff-strict + dead_ref）；impl 侧借用的 golden 件（CryptoModule / AsyncResetSynchronizerShiftReg_w1_d3_i0 /
  AsyncResetSynchronizerPrimitiveShiftReg_d3_i0）证书均 True。

## 2. ExuBlock（commit 7c449d50e）

`TMPDIR=/home/eda/xs-env/tmp-rc/p PROOF_COMMIT=badc1579b bash scripts/run_proof.sh ExuBlock ExuBlock < /dev/null`；预测登记沿用
`docs/fm_predictions/ExuBlock.json`（0da19ca59 登记，未改）。

| 项 | 上一份（2e0390dff） | 本次（badc1579b） |
|---|---|---|
| native / verdict | SUCCEEDED / PASS_DEAD_REF | **SUCCEEDED / PASS_DEAD_REF** |
| passing / failing / unmatched | 52811 / 0 / 0 | **52811 / 0 / 0** |
| unread（= dead_ref）/ constant_reg / blackbox_out | 258 / 1985 / 0 | **258 / 1985 / 0** |
| dont_verify / elab147 | false / false | false / false |
| 用时 | 4050 s | 4471 s |

- fm_predict check：余额 47 = 登记时写明的 PrintCommitIDModule 模型偏差（模型把它当黑盒计 47 输入点，实际两侧 elaborate），与上一份相同。
- receipt `evidence/badc1579b320/ExuBlock/receipt.json` sha256 `6ae548db74f2154b21e1970ab4cdeac6ac3c5852b64ed3ea4dbb6c04d3f1d3ea`
- 证书 `verif/proof_certificates/ExuBlock.json` sha256 `c933f24173649f97d8ec05674c804ad215c79eba2a044898806e448ac263643f`（PROOF_COMMIT badc1579b）
- `make_proof_certificate.py --stamp-allow verif/allow/Backend.json`：只改 ExuBlock 两条（r/i）的 certificate_sha256（5436c747… → c933f241…）。

## 3. NewCSR / CSR / ExeUnit_7 —— 判定：是当前交付依赖的证明根，本轮补齐

- **不是**任何证书的 green_child：全部 506 份证书与全部 allow 里都不出现这三个名字；ExuBlock 是全白盒证明，它们的逻辑在 ExuBlock 闭包里被直接证明。
- **但**它们自己的 receipt 是覆盖率台账的唯一依据：`rewrite_coverage.py` 按模块记 proven，ExuBlock 的 receipt 只给 ExuBlock 本身（3634 行）记账，
  golden 模块 NewCSR（15945 行）/ CSR（1774）/ ExeUnit_7（2400）只靠各自 receipt。在 badc1579b 上用临时 worktree 复算（不提交）：
  不重跑时 unique_design_proven 989→987、golden_lines_proven 3,248,480→3,224,727、incore_proven_incl_cone 100.0%→99.3%（未计 proven 增加
  CSR / ExeUnit_7 / ExuBlock / NewCSR 共 23,753 行）；NewCSR / CSR 还在 legacy_proven_unanchored 名单里。所以按"当前交付仍依赖"算，三者都补。
- 三者 official @badc1579b（与 ExuBlock 同一份 PROOF_COMMIT，并行跑），结果与旧 receipt 逐项相同：

| target | native / verdict | passing | failing / unmatched | unread(=dead_ref) | constant_reg | 用时 | receipt sha256 |
|---|---|---|---|---|---|---|---|
| CSR | SUCCEEDED / PASS_DEAD_REF | 27176（旧 86c70db32986 同） | 0 / 0 | 190 | 1057 | 2458 s | `d0c6ab04323d1d33bba032c22c61e145f22a373535c36c40b2a8ee6faae57c82` |
| ExeUnit_7 | SUCCEEDED / PASS_DEAD_REF | 30273（旧 52257043735e 同） | 0 / 0 | 258 | 1011 | 3270 s | `b68463ac09ae23620e861323879d223557b6230196c862d6ef5086e2bc84e428` |
| NewCSR | SUCCEEDED / PASS_DEAD_REF | 19193（旧 814fe410e15a 同） | 0 / 0 | 142 | 465 | 4737 s | `e9cb3b3e44b0356cb0c99aefc4fc1084ea77ccab811d6feb9eec8fc486cf7473` |

  fm_predict check 三者都是余额 47（同一 PrintCommitIDModule 模型偏差；passing 与旧 receipt 相同，故余额与旧一致）。
- 只提交 receipt/evidence，**没有出证书**（之前也没有 tracked 证书；不是任何父证明的 child，不需要）。
- 复核（8163fad07，临时 worktree 重出三张派生表，不提交）：四者 receipt_harvest 回到 COLLECTED；rewrite_coverage 回到
  989 / 3,248,480，与 main 已提交的表相同。此时 NEEDS_RERUN 新增的只有 Backend（allow 已重盖，待 Backend official）。

## 4. Backend（PROOF_COMMIT 7c449d50e）

跑前：在 7c449d50e 上 `batch_reproof.py validate` 对 Backend allow 里全部 31 个 green child（含新 ExuBlock 证书）→ **31/31 True**。
预测沿用 `docs/fm_predictions/Backend.json`（expected 280043，未改）。

| 项 | 预测 | 上一份（a47c23dc5c5b） | 本次（7c449d50e） |
|---|---|---|---|
| native / verdict | SUCCEEDED | SUCCEEDED / SUCCEEDED | **SUCCEEDED / SUCCEEDED** |
| passing | 280043 | 280043 | **280043**（fm_predict check 逐位相等） |
| failing / unmatched / blackbox_out / unread | 0 | 0 | **0 / 0 / 0 / 0** |
| 钉点 | 1297 | ok=1297 bad=0 | ok=1297 bad=0 |
| 黑盒对象 | 92 | 92 | 92 |
| 用时 | — | 11738 s | 11681 s |

- receipt `evidence/7c449d50e39e/Backend/receipt.json` sha256 `ea354d871849b0669462e4e3b68d958aec56f33148ed711db86327f6af58b787`
- 证书 `verif/proof_certificates/Backend.json` sha256 `783840fc9e40bce27f631f903da5a45a38cbb158bca08c09ab8e60089a5c9bf9`
- `--stamp-allow verif/allow/XSCore.json`：只改 backend 两条（21f29741… → 783840fc…）。

## 5. XSCore（PROOF_COMMIT 526949ca3）

跑前：526949ca3 上 validate XSCore 的 3 个 green child（Backend 新证书 / Frontend / MemBlock）→ **3/3 True**。预测沿用 `docs/fm_predictions/XSCore.json`（99241）。

| 项 | 预测 | 上一份（b56cfb91c416） | 本次（526949ca3） |
|---|---|---|---|
| native / verdict | SUCCEEDED | SUCCEEDED / SUCCEEDED | **SUCCEEDED / SUCCEEDED** |
| passing | 99241 | 99241 | **99241**（fm_predict check 逐位相等） |
| failing / unmatched / blackbox_out | 0 | 0 | **0 / 0 / 0** |
| 黑盒对象 | 6 | 6 | 6 |
| 用时 | — | 4039 s | 3902 s |

- receipt `evidence/526949ca36be/XSCore/receipt.json` sha256 `4caa6068859f3b571f7e9e01ab392b4cbf839c86fc7fd7daa4841cc1a0920830`
- 证书 `verif/proof_certificates/XSCore.json` sha256 `cd0dc0855c560430b0975ec14ed159451d38007181a4c4e2e8f5dd27f6d92ebc`
- `--stamp-allow verif/allow/XSTile.json`：只改 core 两条（81ef38ce… → cd0dc085…）。

## 6. XSTile（PROOF_COMMIT 338aaf21a）

跑前：338aaf21a 上 validate XSTile 的 5 个 green child（XSCore 新证书 / L2Top / IntBuffer / IntBuffer_1 / IntBuffer_2）→ **5/5 True**。预测沿用 `docs/fm_predictions/XSTile.json`（71909）。

| 项 | 预测 | 上一份（760c0859ab36） | 本次（338aaf21a） |
|---|---|---|---|
| native / verdict | SUCCEEDED | SUCCEEDED / SUCCEEDED | **SUCCEEDED / SUCCEEDED** |
| passing | 71909 | 71909 | **71909**（fm_predict check 逐位相等） |
| failing / unmatched / blackbox_out | 0 | 0 | **0 / 0 / 0** |
| 黑盒对象 | 12 | 12 | 12 |
| 用时 | — | 1318 s | 1292 s |

- receipt `evidence/338aaf21ad03/XSTile/receipt.json` sha256 `249daf5f686b866eeb125ccbcbf72467e4f6908552a5f33132281d28f03457a8`
- 证书 `verif/proof_certificates/XSTile.json` sha256 `04e17144598c5746adc2d71245c6decafe9b4c040f64ffed67d8acd8b9beea75`
