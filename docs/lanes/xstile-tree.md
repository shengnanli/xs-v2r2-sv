# Lane xstile-tree：XSTile 实际证明依赖树 + 约 21 项去重归类（codex 0244）

分支 `agent/xstile-tree`，base main `ba506f83c`（树在 `0eed655a4` = base + claim 上求得）。
只读分析，没有跑 FM，没有改 rtl/、证书、派生表、`proof_certificate.py`。
新增 `scripts/xstile_proof_tree.py`、`scripts/test_xstile_proof_tree.py` 和本文件。
`docs/xstile_proof_tree.tsv` 是派生表，本 lane 不提交，由 integrator 重出。

## 0. 结论

- 在 `0eed655a4` 上，XSTile 证明依赖树**闭合**：阻塞行 0，交付件里没有证明绑定的也是 0。
- 树里有 1661 个不同的模块，正好等于 XSTile 例化闭包 `docs/xstile_closure.tsv` 的 1661 个，两边逐个相同。
- 交付源表 `docs/xstile_srcmap.tsv` 有 2136 个模块（含 `xs_*_core` 内层核）。其中每个 RTL 模块，都被树里某个 current-valid 证明在 impl 侧以同一文件例化；每个 MEMORY_MODEL 都是树里检查通过的存储节点。唯一的例外是 StorePipe：它是只有输入、没有输出的空壳，按 `disabled_empty_module` 声明接受（见 §4）。
- 约 21 项里，有 13 项在树内（11 个 mc_not_shared、Arbiter1_InsUncacheResp、Rob）。它们都由一个 current-valid 的父证明白盒覆盖，交付源与父证明的 impl 一致，**都不阻塞 XSTile 收尾**。
- 其余 11 项（7 个 not_fm_target、RNXbar、SNXbar、SubDirectory、SubDirectory_1）以及它们挂的 golden 子模块，**都不在 XSTile 例化闭包里**（核外，SoC 级）。按 0244 单列为后续范围，不进本次收尾。
- 关于 cv-recur 修的那个缺口：树对每条 impl_golden 边的子证书**单独**调用 `validate_certificate_current`。树里 199 个这样的子证书全部为 TRUE。所以按现有数据预期，cv-recur 合入后 XSTile 的结论不会变。合入后由 integrator 用同一条命令复跑确认（§6）。

## 1. 树怎么建的（全部来自证书本身绑定的输入，用 git show 读 commit，不读工作树）

| 边 | 来源 | 判据（直接调用，没有另写） | 覆盖方式 |
|---|---|---|---|
| root | `verif/proof_certificates/XSTile.json` | `validate_certificate_current` | DIRECT |
| blackbox-child | 证书 `proof_config.declarations.allow` 里 `class=green_child` 的对象（design→child_target+certificate_sha256），递归往下 | `validate_child_certificate`（与父级 green_child 校验是同一调用，含 sha 比对） | DIRECT |
| impl_golden | 证书 `input_closure.impl` 里 `kind=golden` 的条目。FM target 递归往下，存储模型是叶子 | ① 把父证书的 golden 条目只留这一条，调用 `validate_impl_golden_certified`，得到这条边的结论；② 子证书本身再调用 `validate_certificate_current` | DIRECT / MC_MODEL |
| mc-chain | MC 模型在 G1 里的例化子链（如 `array_9→array_9_ext`） | 随该 impl_golden 边一起判（MC 登记表复算子链） | MC_MODEL |
| blackbox-memory | allow 里 `vendor_macro` / `APPROVED_MEMORY_MACRO_MODEL` / `disabled_empty_module` 的对称黑盒 | 父证书 current-valid（父那一行） | MC_MODEL(…) / EMPTY_MODULE |
| whitebox-in-parent | 父证书 ref 侧 golden 闭包里，从父 variant 例化可达、没有被 allow 切掉、也不是 impl_golden 的模块（用 `proof_currency.reach`，与 WB2 同一函数；另外补扫了 G1 的 `*.v`，例如 PrintCommitIDModule.v） | 父证书 current-valid | WB_IN_PARENT（父配置内集成证明覆盖，**不称**子模块独立证明） |

**交付一致性**（0244 第 2 条：子证明要与该实例实际实现匹配）：

- 交付源取 `docs/xstile_srcmap.tsv`（在本 commit 上 `xstile_srcmap.py --check` 为 OK）。
- 对每个证明 P 求 `impl_reach(P)`：从 P.variant 出发，只在 P 的 impl 闭包里定义的模块中，按 `xstile_srcmap` 的同一组例化正则往下走（含宏实参里的例化）。遇到 allow 黑盒不往下走；遇到 impl 侧的 golden 模块记成叶子，因为交付时它由自己的重写件和自己的证书替代。
- 逐行检查：
  - root / blackbox-child / impl_golden(FM)：交付源等于该节点自己证明里的定义文件。
  - whitebox：如果父证明 impl 侧例化了它，交付源等于父证明 impl 里的定义文件；没有例化，就是 flattened（golden 层次被重写件内联）。
  - 存储节点：交付 kind 为 MEMORY_MODEL，impl_golden 边再比 sha。
- 全局闭合：交付源表的每个 RTL 模块，必须被树里某个 current-valid 证明以同一文件例化。

## 2. 树统计（`0eed655a4`）

| 项 | 数 |
|---|---|
| 行（边）总数 | 2801 |
| 不同模块数 | 1661（= `docs/xstile_closure.tsv`，差集两边都是 0） |
| 展开的证明节点（有证书） | 323（root 1 + blackbox-child 124 个不同模块 + impl_golden FM 199 个不同模块，有重叠），全部 current-valid |
| 边类型 | blackbox-child 126 / impl_golden 652 / mc-chain 252 / blackbox-memory 68 / whitebox-in-parent 1702 / root 1 |
| 各模块的最优覆盖方式 | DIRECT 323 / WB_IN_PARENT 1238 / MC_MODEL 82 + approved_memory 6 + vendor_macro 11 / EMPTY_MODULE 1 |
| 阻塞行 | **0** |
| 交付源表 2136 行中没有证明绑定的 | **0** |
| delivered 列 | ok 2229；impl_golden 中父 RTL 直接例化 139 / 经 impl 侧 golden 模块例化 227 / **父 impl 根本没有例化（宽 filelist 假依赖）28**；flattened_in_parent_impl 166；存储叶子不进源表 12（`*_ext` 黑盒） |

说明：

- 那 28 条宽 filelist 假依赖（如 TLBNonBlock 带着兄弟变体的 TlbStorageWrapper_2/3、Predictor 带着 PriorityMuxModule_*）不阻塞，但子证书仍按 current-valid 检查，比实际需要的更严。全部为 TRUE。
- 166 条 flattened（如 NewIFU 里的 F3Predecoder/PreDecode，Scheduler 里的 EnqEntry*/OthersEntry*）由父证明白盒覆盖。交付件里没有这一层模块，不需要单独绑定。

## 3. 约 21 项去重归类

"在树内"指在本次 XSTile 实际证明依赖树里；"核内"指在 `docs/xstile_closure.tsv` 里。两者在本 commit 上完全一致。

| target | 报告原因 | 在树内？ | 核内？ | 阻塞 XSTile？ | 怎么被覆盖 / 建议动作 |
|---|---|---|---|---|---|
| Arbiter3_CHIREQ | mc_not_shared（ram_16x11） | 是：whitebox←Slice/_1/_2/_3 | 是 | 否 | Slice×4 是 assembly，cv TRUE；交付 `rtl/uncore/Arbiter3_CHIREQ.sv` 在 Slice 的 impl 里，由 MainPipe_1 例化。独立证明是可选项（mc-notshared lane 修好后只影响它自己的档位） |
| Arbiter3_TaskBundle | 同上 | 是：whitebox←Slice×4 | 是 | 否 | 同上（MainPipe_1） |
| Arbiter3_TaskWithData | 同上 | 是：whitebox←Slice×4 | 是 | 否 | 同上（MainPipe_1） |
| Queue4_HintQueueEntry | mc_not_shared（ram_16x11） | 是：whitebox←Slice×4 | 是 | 否 | 同上（CustomL1Hint） |
| Queue16_HintQueueEntry | mc_not_shared（ram_4x11） | 是：whitebox←Slice×4 | 是 | 否 | 同上（CustomL1Hint） |
| Queue10_GrantBuffer_Anon | mc_not_shared（ram_16x25） | 是：whitebox←Slice×4 | 是 | 否 | 同上（GrantBuffer） |
| Queue16_GrantQueueData | mc_not_shared（ram_16x67） | 是：whitebox←Slice×4 | 是 | 否 | 同上（GrantBuffer） |
| Queue16_GrantQueueTask | mc_not_shared（ram_data_16x256） | 是：whitebox←Slice×4 | 是 | 否 | 同上（GrantBuffer） |
| Queue16_DSBeat | mc_not_shared（ram_16x67） | 是：whitebox←Slice×4 | 是 | 否 | 同上（TXDAT） |
| Queue16_TaskBundle | mc_not_shared（ram_data_16x256） | 是：whitebox←Slice×4 | 是 | 否 | 同上（TXDAT） |
| Queue2_CHISNP | mc_not_shared（ram_data_16x256） | 是：whitebox←Slice×4 | 是 | 否 | 同上（RXSNP） |
| Arbiter1_InsUncacheResp | 缺 vmucp 白名单，没出 receipt | 是：whitebox←InstrUncache | 是 | 否 | **核实成立**：InstrUncache 证书是 signoff-strict，SUCCEEDED，passing 205、failing 0，cv TRUE。impl 闭包含 `rtl/frontend/Arbiter1_InsUncacheResp.sv`，由 `rtl/frontend/InstrUncache.sv:114` 以 `resp_arb` 实际例化，与交付源相同。按 0244 接受为配置内覆盖，不另开 vmucp 例外 |
| Rob | （0244 点名） | 是：whitebox←CtrlBlock | 是 | 否 | CtrlBlock 是 assembly，cv TRUE；交付 `rtl/backend/Rob.sv` 在 CtrlBlock 的 impl 里实际例化。不需要独立 Rob 证明 |
| DebugModule（挂 AsyncQueueSink） | not_fm_target | 否 | 否 | 否 | 核外 SoC 级（调试模块），列入后续范围 |
| LCredit2Decoupled_8（挂 Queue4_CHIREQ） | not_fm_target | 否 | 否 | 否 | 核外（CHI 链路 credit 适配，XSTile 闭包不含），后续范围 |
| LCredit2Decoupled_10（挂 Queue4_CHIDAT） | not_fm_target | 否 | 否 | 否 | 同上 |
| TLBuffer（挂 Queue2_TLBundleA） | not_fm_target | 否 | 否 | 否 | 核外（无后缀 TLBuffer 不在 XSTile 闭包里；核内 TLBuffer_* 另有证书），后续范围 |
| TLBuffer_2（挂 Queue2_TLBundleA_2） | not_fm_target | 否 | 否 | 否 | 同上 |
| AXI4Xbar（挂 Queue2_UInt2） | not_fm_target | 否 | 否 | 否 | 核外 AXI 互联，后续范围 |
| AXI4Deinterleaver（挂 Queue2_AXI4BundleR_3） | not_fm_target | 否 | 否 | 否 | 同上 |
| RNXbar | NOT_CURRENT | 否 | 否 | 否 | 核外（L3/CHI 互联），后续范围 |
| SNXbar | NO_PROOF | 否 | 否 | 否 | 核外，后续范围（rr-special §3.4 (a)/(b) 二选一另议） |
| SubDirectory | NO_PROOF | 否 | 否 | 否 | 同上 |
| SubDirectory_1 | NO_PROOF | 否 | 否 | 否 | 同上 |

括号里挂的 golden 子模块（AsyncQueueSink、Queue4_CHIREQ/CHIDAT、Queue2_TLBundleA/_2、Queue2_UInt2、Queue2_AXI4BundleR_3）本身也都不在树内，也都不在核内。

0244 说的"仅名称出现在历史 receipt 中不构成本次依赖"，在这里被机械地证实了：这 11 项核外目标，连同括号里那 7 个 golden 子模块，在树内 323 张证书的 impl/golden 闭包文件名里、在这些证书绑定的 allow 的 design 里，一次都没出现（已逐张核过）。

## 4. 真实剩余阻塞

**在 `0eed655a4` 上是 0 项。** 有三处需要 integrator / codex 知悉，它们不是阻塞：

1. **StorePipe**（DCacheWrapper allow 声明 `disabled_empty_module` ×2）：交付件是 `rtl/memblock/StorePipe.sv` 里的 `module StorePipe(input io_lsu_req_valid)`，脚本已检查它没有 output 端口。DCache 的 `stu_0`/`stu_1` 也只接了这一个输入。它和 golden 的 5 行空壳一样，没有可观测行为。没有 FM 证明绑定这份字节，但它是没有输出的输入空壳，所以按声明接受。脚本的全局闭合只对"disabled_empty_module 且交付件没有 output"的模块放行；交付件一旦带上 output 就会判阻塞（有反测）。
2. **cv-recur 合入后要复跑**：现在树已经独立检查了全部 199 个 impl_golden 子证书的 current-valid（全部 TRUE），预期结论不变。合入后 `validate_impl_golden_certified` 会在每条边里递归检查，树的 cv 列会自动用上新逻辑，不需要改脚本。
3. **mc-notshared lane** 如果改了 `verif/ut/*/Makefile` 或生成器，而这些文件在某张树内证书的 script/impl 闭包里，对应证书会变成不 current-valid。合入后复跑本脚本，就能直接看到树里新出现的阻塞行。

本脚本**不覆盖**的内容（0244 第 3 条）：

- 证明与交付在 define、参数上是否一致。参数已体现在模块名里；SYNTHESIS define 由 `xstile_rtl_elab.sh` 的 elaborate 保证。
- benchmark 的执行闭包是否没变。这由 integrator 的最终发布候选报告另行核对。

## 5. 测试

`scripts/test_xstile_proof_tree.py`：合成环境 12 条，秒级（12/12 OK）；真仓冒烟 1 条（实测 198 s，OK）。

- 正例：全部有效时 0 阻塞、0 unbound；共享子证明只展开一次；MC 子链、vendor_macro、白盒的覆盖方式都正确。
- 反例：
  - green_child 无效；
  - **impl_golden 边本身通过、子证书却不 current-valid**（cv-recur 要堵的那个洞，树必须独立看见）；
  - impl_golden 边给出失败原因；
  - impl_golden 不是 FM target；
  - MC 边无效，连带它的子链；
  - 白盒件的交付源与父证明 impl 不一致；
  - 白盒 flattened 不阻塞；
  - 交付件没有证明绑定；
  - 未知黑盒类别；
  - disabled_empty_module 的交付件带 output；
  - root 证书缺失。
- 真仓冒烟：`XTR_REAL=1`，约 3 分钟。检查 XSTile root 存在，且树覆盖 `docs/xstile_closure.tsv` 的全部模块。

## 6. 复现

```bash
mkdir -p /home/eda/xs-env/tmp-xtr && export TMPDIR=/home/eda/xs-env/tmp-xtr
# 树（约 3 分钟；退出码 0 = 无阻塞且交付全绑定）
python3 scripts/xstile_proof_tree.py --summary --out $TMPDIR/xstile_proof_tree.tsv
# 名单逐项定位（每行一个 target）
python3 scripts/xstile_proof_tree.py --check-list names.txt
# 测试
python3 scripts/test_xstile_proof_tree.py
XTR_REAL=1 python3 scripts/test_xstile_proof_tree.py
# 前提（只读）：交付源表与闭包表在本 commit 一致
python3 scripts/xstile_srcmap.py --check
python3 scripts/gen_xstile_closure.py --check
```

TSV 列：target / edge / parent / depth / design / cert / cv / coverage / blocking / incore / delivered / note。
同一 target 被多处声明时出现多行；每个 target 只展开一次（取深度最小的那一处），后面的出现标 `dup`。
