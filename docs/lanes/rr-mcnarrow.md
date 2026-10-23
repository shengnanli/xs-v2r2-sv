# Lane rr-mcnarrow：46 个存储叶子 impl 侧 MC 收窄 + 官方重证

Base：main 22cf76370；claim df5b0b600。工作树 /home/eda/xs-env/wt-rr-mcnarrow，分支 agent/rr-mcnarrow。
承 rr-special §3.1（agent/rr-special@9e3da4a35）。判定器用 ledger-cv lane 的 `scripts/proof_currency.py`，只读调用，没有改。
下面的数字都是实测值。

## 0. 结论

| 项 | 结果 |
|---|---|
| 生成器 / Makefile 改动（562dc7bff） | FM 输入变化的目标**恰好是这 46 个**，同目录其余 15 个 variant 的 `make -n fm-<T>` 逐字节不变，UT（simv）命令逐字节不变，rtl/ 薄文件不变 |
| 对已有证明的影响 | 改动的 8 个文件不在任何 tracked 证书或 receipt 的闭包里；proof_currency 没有任何目标降档 |
| 46 个重证（PROOF_COMMIT 562dc7bff） | 46/46 native SUCCEEDED，failing / unverified / aborted / unread_notcompared / unmatched 全 0，passing 与旧 receipt 逐位相同，constant_reg 相同，`fm_predict check` 全部对上 |
| 新证书 | 7 张（新增文件）：Queue16_CHIREQ / Queue16_CHIRSP / Queue4_CHISNP / SRAMTemplate / SRAMTemplate_2 / SplittedSRAMTemplate / SplittedSRAMTemplate_1 |
| proof_currency | 46 个 PROVEN_IN_CONE → PROVEN_DIRECT；其余 1556 个根的档位一个都没变 |
| validate | tracked 证书 511 张（原 504 + 新 7），全部 True |
| gate_all | 两红：round 台账幂等（派生表）、universe 冻结闸 C2（g1_universe.tsv 派生表没随 4 张新证书重出，见 §5）；生成器幂等闸全过 |

## 1. 生成器改动（562dc7bff）

规则：每个 variant 的 `fm-<T>: RTL_GOLDEN_DEPS` 等于它自己的 `FM_REF_DEPS_<T>`（ClockGate 换成本地签核件）。
UT 仍然用整张 RTL_GOLDEN_DEPS。先例是 0591d79d6、cb251a56a、882209fe5、19914dd73。

- `scripts/gen_sram_wrappers.py`：删掉 `MC_SPLIT_VARIANTS` 名单（7 个），改成对全部 variant 生成。原来那 7 行的字节不变。
- `verif/ut/SRAMTemplateNewForm/gen.py`：用同一条规则。
- 手写的 Makefile：UncoreChiQueues（4 行）、FrontendBridgeBuffers（3 行）、SplittedSRAMTemplate（2 行）、SplittedSRAM（2 行），写法跟 cb251a56a 一样。

## 2. 影响面复核

- **字节变化的 tracked 文件**（`git diff --name-only 22cf76370 HEAD`，去掉 evidence/、证书和 lane 文档）：一共 8 个，
  `scripts/gen_sram_wrappers.py`、`verif/ut/SRAMTemplateNewForm/gen.py`，以及 SRAMTemplate、SRAMTemplateNewForm、UncoreChiQueues、
  FrontendBridgeBuffers、SplittedSRAMTemplate、SplittedSRAM 这 6 个目录的 Makefile。rtl/ 没有变化。
- **闭包包含关系**：在 HEAD 上对 tracked 证书和 evidence 全文 `git grep` 这 8 个路径，命中 0 次。所以没有哪一张证书或 receipt
  把它们当作被证输入。
- **间接影响（经 make 改变 FM 输入）**：没有别的 Makefile include 这 6 个 Makefile，`scripts/ut_common.mk` 也没改。
  在 base（`git archive 22cf76370`）和 HEAD 上，对这 6 个目录 FM_VARIANTS 的并集（61 个）逐个跑 `make -n fm-<T>`，
  把根路径和 FM_RUN_ID 归一化之后比较：变了 46 个，正好是这 46 个；没变的 15 个是
  SRAMTemplate_36/44/45/64/68/76/78、Queue40_L2TlbMQBundle、Queue78_PCrdGranted、SplittedSRAMTemplate_2/3/4/23/25/27。
  6 个目录的默认目标（UT simv）`make -n` 也逐字节相同。
- **生成器幂等**：`gen_sram_wrappers.py --check` 报告 35 个产物逐字节一致；`SRAMTemplateNewForm/gen.py --check` OK。
- 结论：HEAD 上原本 current-valid 的证明，没有一个因此失效（§4 proof_currency 无降档，§4 validate 511/511 也印证这一点）。

## 3. 46 个重证结果

用 `batch_reproof run --commit 562dc7bff --jobs 4` 跑，evidence 放在 `evidence/562dc7bfffb4/<T>/`（8e1c67d7d）。
复核时读的是 HEAD 上 tracked 的 receipt.json，没有用 batch 汇总表。逐个检查了这几项：
verdict ∈ {SUCCEEDED, PASS_DEAD_REF}；native SUCCEEDED；stats 和 unmatched 全 0；qualifications（dont_verify / elab147 / relaxed_appvars）为空；
impl_commit = 562dc7bff，且 dirty / provisional 都是 False；passing 和 constant_reg 与旧 receipt 相同。另外独立重跑了 `fm_predict check`，结论是「全部对上」。

| 组 | 目标 | passing（新 = 旧） | 预测 expected / 差 / 可指认 |
|---|---|---|---|
| FrontendBridgeBuffers（旧 3390b6ba80a9） | ICacheBuffer / ICacheCtrlBuffer / InstrUncacheBuffer | 2896 / 992 / 889 | 3203/307/307、997/5/5、972/83/83（merge=false，差额等于 constant_reg） |
| UncoreChiQueues（旧 1fda02fae0f1） | Queue16_CHIREQ / Queue16_CHIRSP / Queue2_PCrdGranted / Queue4_CHISNP | 2290 / 1060 / 50 / 585 | 2344/54/54、1069/9/9、50/0、585/0 |
| SplittedSRAM（旧 4464d4e059b0） | _1 / _2 | 2487 / 7472 | 差 0 |
| SplittedSRAMTemplate（旧 68d1a0932a12） | 无后缀 / _1 | 787 / 787 | 差 0 |
| SRAMTemplate + NewForm（旧 68d1a0932a12） | 35 个 | 与旧值逐个相同 | 32 个差 0；SRAMTemplate_155/166/178 预测 570、实测 569，差 1，是登记时已经写明的 merge_dup 合并（respReg[1] 和 rckEnReg 是一对重复寄存器），落在 merge 带内 |

逐行明细见 `/home/eda/xs-env/tmp-rrm/table.md` 和 `check46.py` 的输出。没有偏差，预测也没有改。

## 4. 新证书（7 张，新增文件，没有改已有证书）

每张证书的 `receipt_sha256` 都与 tracked 的 `evidence/562dc7bfffb4/<T>/receipt.json` 一致，proof_commit 都是 562dc7bff。

| 证书 | sha256 | 挂靠者（`make -n fm-<P>` 的 impl 侧 golden 里有它） |
|---|---|---|
| Queue16_CHIREQ | 99861a156991fa5734fcfe0eec7dde717203f6885ed25824033bc6ec99bf07ec | TXREQ |
| Queue16_CHIRSP | eff3f4f3adca59cb7542082fe467232b765bacc245885d994e7f2b5bc0bc2fa8 | TXRSP |
| Queue4_CHISNP | e5194ad9ff0580d49490e0561c717cae03e5dac38338eda29576bd0de20ff088 | LCredit2Decoupled |
| SRAMTemplate | bc4de781f953eb073fbb9ff5989d834bf72dc63704ce038b23aa930c47a5eb99 | ICacheMetaArray |
| SRAMTemplate_2 | c1a71a428e8dea26ec20af64d59bb3dfed16ffa06019683220fd2fce834c4235 | ICacheMetaArray |
| SplittedSRAMTemplate | c28f111e005769aed3b21c50463317ad411537c507236d381a73363245379f45 | ICacheMetaArray |
| SplittedSRAMTemplate_1 | 96a1d5164481fd2f0f5603177152266427a394a6a42acccb825bfc1299af9f45 | ICacheMetaArray |

TXREQ、TXRSP、LCredit2Decoupled、ICacheMetaArray 本身还没重证，所以仍是 PROVEN_IN_CONE。它们是 rr-small 的范围；ICacheMetaArray
还要等 MbistPipeIcacheTag 的证书。其余 39 张证书没有挂靠者，没有提交（备份在 `/home/eda/xs-env/tmp-rrm/unused_certs/`）。

## 5. 前后对比与 gate

- **proof_currency**：
  - base 用 `/home/eda/xs-env/tmp-rrm/pc_before.tsv`，在 df5b0b600 上跑（= 22cf76370 + claim 文档）。它与 `/home/eda/xs-env/tmp-rrx/before.tsv`
    （rr-special 在 9ce6e3580 上跑的）逐根档位相同。
  - after 用 `/home/eda/xs-env/tmp-rrm/after.tsv`，在 8e1c67d7d 上冷跑（新开 TMPDIR，不复用缓存）。
  - 根都是 1602 个。PROVEN_DIRECT 610 → 656，PROVEN_IN_CONE 862 → 816，NOT_CURRENT 130 → 130。
  - 变档的正好是这 46 个，全部从 IN_CONE 升到 DIRECT。降档 0；NOT_CURRENT 的 detail 一条都没变。
  - current-valid 的来源：经证书 504 → 511，经 receipt 106 → 145。
- **validate**：tracked 证书去掉 POLICY.json 和 schema-v1.json 后共 511 张，`batch_reproof validate` 511/511 True。
- **gate_all**（8e1c67d7d，timeout 9000）：GATE_RC=1，两项红：
  - `round 台账幂等`：docs/fm_round_20260917.tsv 是派生表，本 lane 按规矩不提交它。
  - `universe 冻结闸 C2 CONSERVATION (4)`：docs/g1_universe.tsv 由 `scripts/g1_universe.py` 生成，表头写着「禁止手工编辑」。
    SRAMTemplate、SRAMTemplate_2、SplittedSRAMTemplate、SplittedSRAMTemplate_1 这 4 行在表里记为 UNVERIFIED，按 tracked 证书重算则是
    CERT_REJECTED（policy_freeze_commit_null，与其他证书同样的形态）。这是派生表没随新证书重出。先例是 90ac9de20、20df9ac22：
    由集成者在合并时重出 g1_universe.tsv。本 lane 没有提交它。
  - 其余全部 PASS，包括全部「生成器幂等 *」（其中 sram_wrappers 是本 lane 改的生成器）和「生成器幂等 verif/ut/*」。
- 交接时工作树里有一个未跟踪的 `rtl/_shell_probe_TLToAXI4.sv`（02:20）。它的内容与 `scripts/test_coverage_no_shell_inflation.py:74–77`
  写出的探针 A 逐字相同，而且前一次 gate 正是在「覆盖率空壳闸」处被打断的，所以判定为工具残留，已删除。
