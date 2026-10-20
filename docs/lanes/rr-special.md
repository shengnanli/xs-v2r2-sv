# Lane rr-special：ledger-cv 判非 current-valid 的 67 个特殊原因目标

Base：main 22cf76370；claim 9ce6e3580。工作树 /home/eda/xs-env/wt-rr-special，分支 agent/rr-special。
判定器用 ledger-cv lane 的 `scripts/proof_currency.py`，只读调用，没有改。本文件的数字都是实测值。

## 0. 结论

| 类 | 个数 | 根因 | 处理 | 结果 |
|---|---|---|---|---|
| 缺 RUN_CONTEXT（ExeUnit_13/14、VIMacU、VIPU） | 4 | receipt 格式老：证据不是 run_proof.sh 产出的 | 重证 | 4/4 PROVEN_DIRECT |
| ICacheDataArray `closure_changed:xs_SRAMTemplate_core.sv` | 1 | impl 真变（8c16962b3 D1），旧证明没证过当前字节 | 重证 | PROVEN_DIRECT，passing 8237（与预测、旧值相同） |
| mc_not_shared：UncoreTLQueues 11 个 | 11 | receipt 老：Makefile 在 cb251a56a（10-11）已逐 variant 收窄 impl MC，旧 receipt 1fda02fae（10-04）早于收窄 | 重证 | 11/11 PROVEN_DIRECT |
| mc_not_shared：其余 46 个 | 46 | **配置设计问题**：现行 Makefile 仍把整个家族的 MC 模型全给每个 variant 的 impl，重跑只会复现 | 没动，待裁定 | 仍是 PROVEN_IN_CONE |
| impl_golden_uncertified：DivUnit | 1 | DivUnit 的 receipt 本身没问题；impl 挂的 5 个 golden 子模块没有证书，而且这 5 个都在 rr-small 名单里 | 没动，等 rr-small | 仍是 PROVEN_IN_CONE |
| impl_golden_uncertified：ICacheMetaArray | 1 | impl 挂的 golden SplittedSRAMTemplate/_1、SRAMTemplate/_2 都属于上面 46 个；MbistPipeIcacheTag 在 rr-small 名单里 | 没动，被阻塞 | 仍是 PROVEN_IN_CONE |
| NO_PROOF：SNXbar、SubDirectory、SubDirectory_1 | 3 | **结构问题**：没有任何 tracked receipt；impl 挂的 golden 子模块既不是 FM target，也不在 MC 登记表里 | 没动，待裁定 | 仍然不是根 |

共重证 16 个：native SUCCEEDED，failing / unmatched / unverified / aborted 全 0，passing 与旧 receipt 逐位相同，`fm_predict check` 全 ok。
新出 3 张证书（新增文件，没有改已有证书）：Queue2_TLBundleA_10 / A_31 / D_11。原因是 rr-small 名单里的 TLBuffer_20 / TLBuffer_22
在现行 Makefile 下以 impl_golden 方式挂这三个 golden（见 §3.3）。
validate：tracked 证书 507 张（原 504 + 新 3），全部 True。

## 1. 诊断方法

- 读每类的 tracked receipt（`impl_closure` 里 kind=golden 的条目和 `golden_closure` 对比），并读判定代码
  `scripts/proof_certificate.py::validate_impl_golden_certified`。MC 分支 L583–596 要求 impl 挂的每份已登记 MC 模型，
  在 ref 侧闭包里有 basename 和 sha 都相同的一份，否则判 `green_child_impl_golden_mc_not_shared`。
  这一条检查的是 impl 闭包里的**每一条** golden，不只是这个 variant 真用到的那几份。
- 「重跑能不能好」的依据：`make_receipt.py` 的 impl_closure 就是 `--impl-srcs` = `$(RTL_SRCS) $(RTL_GOLDEN_DEPS)`。
  所以在 HEAD 上对每个目标跑 `make -n fm-<T>`（只打印，不执行），取出 `--impl-srcs` / `--ref-srcs`，
  就能看到重跑后的 receipt 会带什么样的闭包。逐目标结果（impl 里有、ref 里没有的 golden，标 MC / 非 MC）
  见 TMPDIR `/home/eda/xs-env/tmp-rrx/drycheck.out`。
- 「是不是 FM target」用 `fm_target_universe.targets_at(HEAD, regex)` 查；是否有证书只看 `git ls-files verif/proof_certificates/`。

## 2. 重证（16 个）

- 跑前登记：16 个都已有 `docs/fm_predictions/<T>.json`，不需要补登记，所以 PROOF_COMMIT 就是 claim 提交 **9ce6e3580**，没有单独的 prereg 提交。
  跑前用旧 receipt 预演 `fm_predict check`：Queue2_TLBundleB_1（1061→1018，constant_reg 43）、D_20（854→851，constant_reg 3）、
  ExeUnit_13（16945→16565，constant_reg 380，登记 note 写明 vmucp-on 预期 16565）、VIMacU（3933→3773，constant_reg 160），差额都被逐位指认。
  ICacheDataArray 的登记（merge_dup=true、model_applicable=false、expected 8237）报「登记不早于该次证明」，这是对旧证明说的；
  本次重跑在登记之后，check 结果 ok。
- 命令：`TMPDIR=/home/eda/xs-env/tmp-rrx python3 /home/eda/xs-env/tools/batch_reproof.py run --commit 9ce6e3580 --list <16 行> --jobs 4 --tag rrs`，
  一波跑完，16 个目标之间没有父子依赖。结果「需关注 0 个」。
- evidence/9ce6e35807a4/：16 个目标，加上 RUN_CONTEXT.tsv。所有 receipt 都是 impl_commit=9ce6e3580、impl_worktree_dirty=false、provisional=false。
- 提交 47f86a577：evidence（`git add -f`，同 reproof-171 先例）加 3 张证书。batch_reproof 顺带生成的另外 13 张证书没有提交，
  移到了 `/home/eda/xs-env/tmp-rrx/unused_certs/`。汇总表在 `/home/eda/xs-env/tmp-rrx/reproof_rrs.tsv`。

| target | ut_dir | 旧 receipt | 旧 passing | 新 passing | 预测 expected | verdict | 证书 |
|---|---|---|---|---|---|---|---|
| ExeUnit_13 | ExeUnit_13 | 5ec0626546dd | 16565 | 16565 | 16945（cr 380 指认） | SUCCEEDED | 未出 |
| ExeUnit_14 | ExeUnit_14 | c2901c9d813e | 14448 | 14448 | 14952 | SUCCEEDED | 未出 |
| VIMacU | VIMacU | 2db266cd4a80 | 3773 | 3773 | 3933（cr 160 指认） | SUCCEEDED | 未出 |
| VIPU | VIPU | d242da086eb2 | 4052 | 4052 | 4054 | SUCCEEDED | 未出 |
| ICacheDataArray | ICacheDataArray | 397a2bc9c8d3 | 8237 | 8237 | 8237 | SUCCEEDED | 未出 |
| Queue2_TLBundleA_10 | UncoreTLQueues | 1fda02fae0f1 | 356 | 356 | 356 | SUCCEEDED | `1aa09f2885ab2e18…` |
| Queue2_TLBundleA_12 | UncoreTLQueues | 1fda02fae0f1 | 404 | 404 | 404 | SUCCEEDED | 未出 |
| Queue2_TLBundleA_19 | UncoreTLQueues | 1fda02fae0f1 | 362 | 362 | 362 | SUCCEEDED | 未出 |
| Queue2_TLBundleA_31 | UncoreTLQueues | 1fda02fae0f1 | 416 | 416 | 416 | SUCCEEDED | `66ce19bd2c76abc2…` |
| Queue2_TLBundleA_8 | UncoreTLQueues | 1fda02fae0f1 | 1082 | 1082 | 1082 | SUCCEEDED | 未出 |
| Queue2_TLBundleB_1 | UncoreTLQueues | 1fda02fae0f1 | 1018 | 1018 | 1061（cr 43 指认） | SUCCEEDED | 未出 |
| Queue2_TLBundleC_1 | UncoreTLQueues | 1fda02fae0f1 | 968 | 968 | 968 | SUCCEEDED | 未出 |
| Queue2_TLBundleD_11 | UncoreTLQueues | 1fda02fae0f1 | 245 | 245 | 245 | SUCCEEDED | `d92ad0cd837be3e7…` |
| Queue2_TLBundleD_13 | UncoreTLQueues | 1fda02fae0f1 | 233 | 233 | 233 | SUCCEEDED | 未出 |
| Queue2_TLBundleD_20 | UncoreTLQueues | 1fda02fae0f1 | 851 | 851 | 854（cr 3 指认） | SUCCEEDED | 未出 |
| Queue2_TLBundleE_1 | UncoreTLQueues | 1fda02fae0f1 | 29 | 29 | 29 | SUCCEEDED | 未出 |

ICacheDataArray 的 impl 确实变了：D1 在 holdRead 关时不再生成 rdata_last_REG。旧版里这个寄存器与 respReg 同方程，
被 merge_duplicated_registers 并掉，本来就不占比较点，所以 passing 不变（8237），符合跑前预测。

## 3. 未处理、需要裁定的事项

### 3.1 mc_not_shared 46 个：impl 侧 MC 共读过宽（配置设计问题，不是证明过期）

按 UT 目录分：SRAMTemplate 26（`scripts/gen_sram_wrappers.py` 生成）、SRAMTemplateNewForm 9（`verif/ut/SRAMTemplateNewForm/gen.py` 生成）、
UncoreChiQueues 4（Queue16_CHIREQ / Queue16_CHIRSP / Queue2_PCrdGranted / Queue4_CHISNP）、FrontendBridgeBuffers 3（ICacheBuffer /
ICacheCtrlBuffer / InstrUncacheBuffer）、SplittedSRAMTemplate 2（无后缀和 _1）、SplittedSRAM 2（_1 / _2）。

证据：在 HEAD 上 `make -n fm-<T>`，这 46 个的 `--impl-srcs` 仍然带着整个家族的 MC 模型。例如 SRAMTemplate_8 的 impl
读 31 份 golden（array*.sv、sram_array_*），而 ref 只读 `sram_array_1p256x66m66s1h0l1b_icsh_dat` 和 `array_0`。
多出来的那些都是登记过的 MC，判据要求「impl 挂的每一份 MC，ref 侧都要有同一份」，所以必然报 not_shared。
SRAMTemplate 家族还多出非 MC 的 MbistClockGateCell（它有证书，不构成问题）。**按现行 Makefile 重跑只会得到同样的 receipt**。

已有先例，修法是机械的：0591d79d6（18 个前端 variant，`MC_SPLIT_VARIANTS`）、cb251a56a（UncoreTLQueues，本 lane 已据此重证 11 个）、
882209fe5 / 19914dd73（Queue40 / Queue78）。做法都是让每个 variant 的 `fm-<T>: RTL_GOLDEN_DEPS` 等于它自己的 `FM_REF_DEPS_<T>`，UT 不变。
需要改的路径是 `scripts/gen_sram_wrappers.py`、`verif/ut/SRAMTemplateNewForm/gen.py` 和 4 个 Makefile。
本 lane 的 claim 不覆盖 scripts/，而且这些是被证输入，所以没动。

**建议**：开一个小 lane，把「impl MC = 自己的 ref MC」做成生成器默认行为，而不是继续维护名单（`MC_SPLIT_VARIANTS` 就是一份
会漏的名单，这 35 个就是漏下的）。手写的 4 个 Makefile 按 cb251a56a 的写法补。改完先在幂等闸上验证，再按本 lane 的流程重证 46 个，
passing 应当逐位不变（只是去掉没被例化的定义）。下游影响：rr-small 名单里的 TXREQ / TXRSP / LCredit2Decoupled 在现行 Makefile 下
以 impl_golden 挂 Queue16_CHIREQ / Queue16_CHIRSP / Queue4_CHISNP，这三个需要先收窄、重证、出证书，那几个父才可能 current-valid。

### 3.2 DivUnit、ICacheMetaArray：被依赖阻塞

- **DivUnit**：proof_currency 能走到 impl_golden 判据，说明它的 receipt 已经过了闭包预筛。阻塞的是 impl 挂的 golden 子模块要有证书。
  `make -n fm-DivUnit` 的 impl 挂 7 份 golden：FloatDivider、FloatDividerR64（有证书），以及 CSA3to2_20、CSA3to2_24、ShiftLeftPriorityWithLZDResult、
  r4_qds_v2、r4_qds_v2_spec（是 FM target，有 receipt，**没有证书**，5 个都在 rr-small 名单里）。
  **建议**：rr-small 重证这 5 个之后，由它出证书（新增文件），或者由 integrator 在合并时从它的 evidence 出证书。DivUnit 本身预计不需要重跑。
  本 lane 没有抢跑这 5 个，免得两条 lane 撞名。
- **ICacheMetaArray**：impl 挂的 golden 有 SplittedSRAMTemplate、SplittedSRAMTemplate_1、SRAMTemplate、SRAMTemplate_2（都在 §3.1 的 46 个里）、
  MbistPipeIcacheTag（rr-small 名单，没有证书）、MbistClockGateCell（有证书）。要等 §3.1 那几个收窄重证出证书、rr-small 出 MbistPipeIcacheTag 证书之后再看。

### 3.3 已出的 3 张证书

现行 Makefile 下，rr-small 名单里的 TLBuffer_20 以 impl_golden 挂 Queue2_TLBundleA_10 / D_11，TLBuffer_22 挂 Queue2_TLBundleA_31 / D_11。
没有这三张证书，那两个父重证后会判 impl_golden_uncertified，所以按任务允许的例外出了证书。三张都是新增文件，validate True。

### 3.4 NO_PROOF 3 个（SNXbar、SubDirectory、SubDirectory_1）：结构上补不出来，需要裁定

- 没有任何 tracked receipt 或证书（原来就是 LEGACY_PROVEN_UNANCHORED，codex 0169 D1 当时「暂不收紧」）。
- 补跑也得不到 current-valid：
  - SNXbar 的 impl 两侧同源读 golden FastArbiter_45 / FastArbiter_46；
  - SubDirectory 读 SRAMTemplate_192 / SRAMTemplate_193 / MaxPeriodFibonacciLFSR_3 / array_19 / array_20；
  - SubDirectory_1 读 SRAMTemplate_194 / 195 / 196、array_21 / array_22 / array_0_0。

  这些模块都**不是 FM target**（fm_target_universe 查不到），array_19 / 20 / 21 / 22 / array_0_0 也**不在** `verif/mc_memory_registry.tsv` 里。
  所以判据一定会给 `impl_golden_not_fm_target`。
- **建议**，二选一：
  - (a) 按 ledger-cv 新口径如实记为不 proven（核外 1,897 行）。
  - (b) 开工作：为 FastArbiter_45 / 46、SRAMTemplate_192–196、MaxPeriodFibonacciLFSR_3 建 FM target（或在 impl 侧换成本地重写件），
    把 array_19–22 / array_0_0 按 codex 0222 逐条登记进 MC 表，然后正式补证。

  本 lane 没有跑这 3 个：跑出来的 receipt 也会被判据拒掉，没有意义。

## 4. 复核

### proof_currency

`XSSV_HOME=<本树> python3 /home/eda/xs-env/wt-ledger-cv/scripts/proof_currency.py --out ...`，只读调用。

| | before（9ce6e3580） | after（47f86a577） |
|---|---|---|
| 根 | 1602 | 1602 |
| PROVEN_DIRECT | 610（证书 504 + receipt 106） | 626（证书 507 + receipt 119） |
| PROVEN_IN_CONE | 862 | 847 |
| NOT_CURRENT | 130 | 129 |

- 16 个重证目标全部从 PROVEN_IN_CONE / NOT_CURRENT（ICacheDataArray）变为 PROVEN_DIRECT。
- 其余变化只是 superseded_by 的父换成了更近的 current-valid 父（例如 ExuBlock_2 → ExeUnit_14 / VIMacU；ICache → ICacheDataArray），
  没有任何目标降档。
- 本名单 67 个，after：PROVEN_DIRECT 16、PROVEN_IN_CONE 48、不是根 3。
- before / after 逐行表：`/home/eda/xs-env/tmp-rrx/before.tsv`、`after.tsv`。

### validate

`batch_reproof.py validate`，对 HEAD 47f86a577 上全部 tracked 证书（排除 POLICY / schema-v1），共 507 张：不通过 0。原 504 张仍全部 True。

## 5. gate

（跑完补记。）
