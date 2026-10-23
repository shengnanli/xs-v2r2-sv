# ledger-cv lane：台账 proven 只认 current-valid 证明

分支 `agent/ledger-cv`，基于 main `2d1d134e0`。只改台账脚本、闸和测试，没有改 current-valid 判据
（`proof_certificate.py` / `fm_verdict.py` / `make_proof_certificate.py` / `gen_receipt_harvest.py` 都没动），
没有动 rtl/、G0/G1，也没有提交派生表（`docs/rewrite_coverage.tsv`、`docs/coverage_three_axis.tsv` 等等 integrator 重出）。

## 0. 结论

口径照批准的三条实现了。但影响远大于预期的「171 张」：台账里 1605 个 proven 目标，只有 **440 个**的证明对 HEAD 是
current-valid。另有 **1032 个**降为 PROVEN_IN_CONE(superseded_by)，**133 个**不再 proven。
比 171 多出来的 995 个，几乎全是**只有 receipt、没有证书的根**（原 1098 个里有 929 个只有在旧版 `scripts/fm_eq.tcl` 下跑出的
receipt）。这和那 171 张证书失效是同一个原因，只是它们没有证书，所以 oldcert-triage 的名单里看不到。

| 指标 | 前（2d1d134e0） | 后（本分支） |
|---|---|---|
| unique_design_proven | 989 / 1186 = 83.4% | 246 / 1186 = 20.7% |
| golden_lines_proven（整芯片） | 3,248,480 / 3,901,688 = 83.3% | 1,426,653 = 36.6% |
| incore_golden_lines_written | 3,348,859 / 3,349,310 = 100.0% | 不变 |
| incore_golden_lines_proven | 3,082,317 = 92.0% | 1,426,218 = 42.6% |
| incore_golden_lines_proven_incl_cone | 3,348,544 = 100.0% | 1,692,445 = 50.5%（= proven + Rob 266,227，R1–R10 仍过） |
| incore_golden_lines_superseded_in_cone_uncounted（新） | — | 1,555,327 = 46.4%（单列，不计入以上任何一行） |
| outcore_golden_lines_proven | 166,163 / 552,378 = 30.1% | 435 = 0.1% |
| legacy_proven_unanchored | 3 | 0 |
| 三轴 轴二 PROVEN_DIRECT | 1590 | 440 |
| 三轴 轴二 PROVEN_IN_CONE | 45 | 1035（1032 个 superseded_by + 3 个非根候选） |
| 三轴 轴二 UNPROVEN | 175 | 335（+118 个 not_current 根，+42 个只落在过期 receipt closure 里的非根） |
| 三轴「被证明覆盖」 | 1635 / 1814 = 90.1% | 1475 / 1814 = 81.3% |
| 三轴 轴一 | — | 不变（逐行核对 0 处变化） |

## 1. 判据（复用，不另写）

`scripts/proof_currency.py`：

- **证书**：`fm_verdict._child_cert_current`，内部就是 `proof_certificate.validate_certificate_current`，
  与 batch_reproof validate / green_child 用的是同一个函数。
- **只有 receipt 的根**：用 `make_proof_certificate.build_certificate` 从**已跟踪**的 evidence 目录，在内存里派生一份证书文档。
  生成器自己的拒收条件全部照常生效（缺 RUN_CONTEXT、老格式闭包、dirty/provisional、工具版本解析不到……）。
  派生出来的文档再交给**同一个** `validate_certificate_current` 在 HEAD 上判。派生失败就是不 current-valid。
  同一个 target 有多份 receipt 时，从最新的一份往前试，第一份通过的算数。
- **预筛（只为提速）**：派生之前，先用同样的函数（`recompute_closure_at`、`_relativize_script`）按同样的顺序，
  在 HEAD 上复算 impl 闭包和脚本闭包。这两项都是 validate 的必要条件，所以预筛只会提前拒掉 validate 本来也会拒的。
  测试里另有一例绕过预筛直接派生加 validate，结果同样判红。
- **WB1–WB6**：从 `oldcert_triage.py` 原样抽成 `proof_currency.WhiteBox`，`oldcert_triage.py` 改为 import 它。
  在 HEAD 上重跑 `oldcert_triage.py`，输出与已提交的 `docs/oldcert_triage.tsv` 除生成 commit 那行外逐字一致。
  只加了一条 fail-closed：T 自己的 rtl 依赖集为空时不认白盒父（原先空集 ⊆ 任何集合，会白给）。
  父集合 = 全部 current-valid 证明，包括经 receipt 判为 current-valid 的根（NewCSR / CSR / ExeUnit_7 等），
  所以 superseded_by 取的是**最近**的 current-valid 父，和 oldcert_triage 表里的父可能不同（例如 139 张 NewCSR 字段模块，
  父从 ExuBlock 变成 NewCSR）。
- 性能层，不改语义：`BatchRepo` 用常驻 `git cat-file --batch` 读 blob，与 `Repo.show` 逐字节一致（有测试）；
  fm_target_universe 的两个引擎按 40-hex commit 做结果缓存，`targets_at` 照常交叉校验；
  整次结果只在**已跟踪文件全干净**时按 (HEAD, G1 MANIFEST+CANONICAL_ID) 缓存，脏树一律现算。
  `PROOF_CURRENCY_NO_CACHE=1` 可以强制现算。

## 2. 台账接线

- `rewrite_coverage.py`：`split_current(written ∩ 台账绿判决, cur)` 分三档。
  - **proven**：current-valid，再减去 STALE_IMPL。
  - **superseded**：只单列 `incore_golden_lines_superseded_in_cone_uncounted`，**不并入 proven，也不并入 incl_cone**。
  - **dropped**：如实不计，注释里按原因归类计数。

  核内未计 proven 的模块逐个列出，并标明档位。
  先读过现有规则再定的：`incl_cone` 只认 `verif/proven_in_cone_verified.tsv` 的 R1–R10 核验行，
  如果把 WB 档放进去，就会被当成已核验的行数。所以 WB 档单设一行，见 §5 待裁定 1。
- `coverage_three_axis.py`：轴二只认 current-valid 证明，closure 候选也只取 current-valid 证明的 golden 闭包；
  过期且没有白盒父的根不给 closure 候选（口径 3）。新增第 6 列 `proof_status`：
  `current_valid:<certificate|receipt:…>` / `superseded_by=<父>` / `not_current:<原因>` / `-`。
- `check_coverage_provenance.py`：判据 C（--strict）原来要求「有 tracked 通过 receipt 就必须是 PROVEN_DIRECT」，
  这与新口径直接冲突。现在改为「PROVEN_DIRECT，或者 proof_status 不是 -」都算记过账，
  proof_status 为 - 又不是 DIRECT 的照旧判红。新增判据 D：PROVEN_DIRECT ⟺ current_valid:（防止只手改一侧）。
  用新表在本分支跑：A/B/C 全 OK。

## 3. 测试（`scripts/test_ledger_current_valid.py`，已接入 gate_all.sh，31 条）

- **合成仓**（秒级，注入判据结论，测分档接线）：
  - (a) 脚本闭包过期的证书不再是 PROVEN_DIRECT；
  - (b) 过期但 WB 成立 → PROVEN_IN_CONE(P)，且不进 proven；
  - (c) 过期且没有白盒父 → 不 proven，即使在 closure 候选里也是 UNPROVEN；
  - (d) current-valid → PROVEN_DIRECT；
  - (e) 只有 receipt 的根三档全覆盖；
  - 反例：WB4 的 rtl 字节不同、WB1 父也过期、没有任何证明 → NO_PROOF；
  - 外加 rewrite_coverage.split_current、三轴 axis2 的 vendor / 黑盒 / 非根候选。
- **真仓 HEAD**（不注入，约 2 分钟）：
  - (d) 一张真 current-valid 证书判 True；(a) 把它的 fm_eq.tcl 脚本闭包 sha 改一位（digest 重算、自洽）→ script_closure_changed；
  - (e) 一份只有 receipt 的真根（Arbiter1_L1BankedDataWriteReq）原样副本判 current-valid；
    改 sha → 脚本闭包判红，预筛和直接 validate 两条路都红；
  - (e)(a) 一份真实过期、只有 receipt 的根（AMOALU）绕过预筛直接派生加 validate → script_closure_changed；
  - BatchRepo 与 Repo.show 逐字节一致。
- `test_coverage_provenance_gate.py` 新增 3 个正向例（D 两个方向、6 列表 C 漏记）和 1 个反向例
  （superseded_by / not_current 不算漏记），共正向 7 例、反向 5 例。

## 4. 变化清单（台账 claimed = written ∩ 绿判决 = 1605 个）

全量逐行见 TMPDIR `changes.tsv`（module / 前 / 后 / superseded_by / golden 行 / 核内 / oldcert 父 / via / 原因）。

| 档 | 个数 | golden 行 | 核内行 |
|---|---|---|---|
| 仍 PROVEN_DIRECT | 440（证书 333 + receipt 107） | 1,426,653 | 1,426,218 |
| → PROVEN_IN_CONE(superseded_by) | 1032 | 1,555,327 | 1,555,327 |
| 　其中 oldcert 171 张 | 170 | 36,757 | 36,757 |
| 　其中只有 receipt 的根 | 862 | 1,518,570 | 1,518,570 |
| → 不 proven（NOT_CURRENT） | 130 | 264,603 | 100,772 |
| → 不 proven（NO_PROOF） | 3 | 1,897 | 0 |

- **171 张**：170 张 → PROVEN_IN_CONE。另 1 张 MbistBitmapCache 仍是 PROVEN_DIRECT：它的证书不 current-valid，
  但 tracked receipt `evidence/397a2bc9c8d3/MbistBitmapCache` current-valid，按口径 1（证书**或** receipt）算 DIRECT。
- **171 之外 995 个**：全是只有 receipt 的根。
  - 862 个 superseded，大头按父分：LsqWrapper 48 / 368k 行，Scheduler×4 84 / 646k 行，DCache 17 / 100k 行，
    DataPath 40 / 63k 行，NewCSR 231 / 50k 行，Slice_3 37 / 47k 行……
  - 130 个 NOT_CURRENT：129 个是 `script_closure_changed:scripts/fm_eq.tcl`，最大的几个是 TLFIFOFixer 89k、
    NCBTransactionQueue 30k（核外），核内是 EnqEntry*/OthersEntry*（Entries 家族各 2–3k 行）；
    另 1 个 ICacheDataArray 是 `closure_changed:rtl/common/xs_SRAMTemplate_core.sv`。
  - 3 个 NO_PROOF：SNXbar / SubDirectory / SubDirectory_1，就是原来的 LEGACY_PROVEN_UNANCHORED（核外，1,897 行）。
- 只有 receipt 的根里，有 170 个过了闭包预筛，其中 63 个死在派生或 validate 的后段，现在全部是 superseded：
  - 57 个 `green_child_impl_golden_mc_not_shared`（SRAMTemplate_*、Queue*_TLBundle*、ICacheCtrlBuffer 等）：impl 侧读了 golden ram/array，
    receipt 的 golden_closure 里却没有同一份；
  - 4 个缺 RUN_CONTEXT.tsv（ExeUnit_13/14、VIMacU、VIPU）；
  - 2 个 `impl_golden_uncertified`（DivUnit→CSA3to2_20、ICacheMetaArray→SplittedSRAMTemplate）。

## 5. 待裁定

1. **影响面**：按批准口径，核内 proven 92.0% → 42.6%，incl_cone 100% → 50.5%。另有 46.4% 是 WB 档，单列不计。
   是接受这个下降、再走批量重证（1032 + 133 个），还是对只有 receipt 的根另定口径？
   本 lane 没有放宽，停在这里等裁定。
2. **WB 档要不要计行数**：现在 `incore_golden_lines_superseded_in_cone_uncounted` 单列，不进 proven 和 incl_cone。
   要计的话需要 codex 0238 裁定 2 那一类逐条核验，本 lane 没做。
3. **LEGACY_PROVEN_UNANCHORED 的 3 个**（codex 0169 D1「暂不收紧」）：新口径下没有任何证明就不 proven，
   与 D1 冲突。现在按新口径不计。
4. **mc_not_shared 57 个**：这是 current-valid 判据本身对这批 receipt 的结论（按 receipt 出证书也会被拒），
   本 lane 没动判据。要不要重证、还是先审 golden_closure 的记录口径，请定。
5. **耗时**：proof_currency 冷跑约 27 分钟。主要花在约 44 个 impl_commit 的 target 全集上
   （每个 commit 9 s make + 11 s regex），以及 504 张证书 validate 约 3 分钟。
   有 FTU 盘缓存时约 11 分钟；同一干净 HEAD 有结果缓存时约 0。
   rewrite_coverage --check 和空壳闸各要一次 evaluate，gate 因此会变长。

## 6. gate（`TMPDIR=/home/eda/xs-env/tmp-lcv timeout 9000 bash scripts/gate_all.sh`，GATE_COMMIT=2141ac0745）

GATE_RC=1，262 PASS / 1 FAIL：

- ★FAIL `覆盖率台账幂等`（`rewrite_coverage.py --check`）：`docs/rewrite_coverage.tsv 与重算结果不一致（DRIFT）`。
  这是预期内的：口径改了，派生表等 integrator 重出。本分支 HEAD 上重算出的表在
  `/home/eda/xs-env/tmp-lcv/rewrite_coverage.new.tsv`。
- 新接的 `台账 current-valid 正反测` PASS；`覆盖率空壳闸`、`incl_cone 核验名单正反测`、`覆盖证据链负测` /
  `覆盖证据链闸`（旧表无第 6 列，C/D 照旧语义）都 PASS。
- `coverage_three_axis.tsv` 没有幂等闸（只有 provenance 闸）。用新表在 clone 里跑 `check_coverage_provenance.py --strict`：
  A/B/C 全 OK（440 个 PROVEN_DIRECT 都有 tracked 通过 receipt）。

之后的提交只改了原因串的规范化（去掉本机仓库绝对路径前缀，`_norm_msg`；当前派生表里没有这类原因，数字不变）
和本文档，跑过 `test_ledger_current_valid.py`（31/31）与 `test_coverage_provenance_gate.py`。

重出派生表的顺序（integrator）：`python3 scripts/rewrite_coverage.py`、`python3 scripts/coverage_three_axis.py`。
冷跑各约 27 / 11 分钟；在同一干净 HEAD 上，后一个复用前一个的结果缓存（`$TMPDIR/proof_currency_result/`）。
