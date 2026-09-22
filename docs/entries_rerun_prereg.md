# Entries* 九变体重验批次 —— 跑前登记（预测在前，结果在后）

lane: agent/entrerun   worktree: /home/eda/xs-env/wt-entrerun
基线 commit（起跑）: 9b6f73cbe313ea8282b0faaafeb91e6c67501435
G1 golden: /home/eda/xs-env/G1-canonical/golden-rtl（只读；harvest 关二 chk_golden=same）

## 为什么重跑（不是"没证过"）

`docs/receipt_harvest.tsv` 里这 9 行 `chk_impl=DIFFER`，why 列逐个写着
「main 里字节已变: rtl/backend/<变体>.sv, rtl/backend/xs_iq_entries_core.sv」。
codex 0170 选 A：`chk_impl != same` 一律不计当前 proven，统一 `STALE_IMPL_NEEDS_RERUN`。
所以要重证的不是"有没有证据"，而是"证据认证的字节还在不在仓里"。

## 权威旧 receipt（本批次的预测依据）

被 harvest 选中的 lead 全部是 `wt-entries3:29dd150aa166`（同一批、同一 commit
`29dd150aa166d2bf31676d622e83aeb27ace9d90` 上成批重出，9/9 齐）。
它们的 `impl_closure` 里共享核 sha256 前缀 `3853f76e0f80`。

## 从 29dd150aa166 到 9b6f73cb 的实现侧字节差（机械核对，命令见下）

(a) 9 个变体薄文件：**注释以外 0 行差**。
    `git diff 29dd150aa166 HEAD -- rtl/backend/<T>.sv | grep -E '^[+-]' | grep -v '^\(+++\|---\)' | grep -vcE '^[+-][[:space:]]*//'` == 0（9/9）
    差的是文件头「唤醒路由」注释的措辞（`（fpWen），门控 srcType[1]` -> `匹配 srcType[1]&fpWen`）。

(b) 共享核 `rtl/backend/xs_iq_entries_core.sv`：注释以外的差 = 新增 `HAS_DBG_OUT`
    参数（默认 `1'b0`）与 `xs_iq_entry` 的 7 组 `o_dbg_*` 输出端口，
    `HAS_DBG_OUT=0` 时走 `g_no_dbg_out` 分支全部钉常数 0。
    **本批 9 个变体没有一个给 HAS_DBG_OUT**（`grep -l HAS_DBG_OUT rtl/backend/Entries*.sv` 为空），
    且 §4 条目例化的端口表里**没有连任何 `o_dbg_*`**（`awk 'NR>1374 && /o_dbg/'` 为空）。

(c) 任务书点名的真 bug 修复 `609baba5d551c73d40ba727baf6e99ec7a107383`
    （perfWakeupByWB 门控改用 currentStatus）落在 `g_dbg_out` 分支里，
    即 `HAS_DBG_OUT=1` 才生成的代码。对本批 9 个变体它是**不生成的代码**。

## 预测（★在起跑前写定，跑完不许改★）

依据 (a)(b)(c)：本批 9 个目标的**有效实现逻辑与 29dd150aa166 那一版逐门等价**，
故预测每个目标的 passing **精确等于**旧 receipt 的数，不是一个区间：

| target | 预测 passing | 预测 failing/unverified/aborted/unread_notcompared | 预测 unmatched 六项 | 预测 verdict |
|---|---|---|---|---|
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | 25300 | 0 | 0 | SUCCEEDED |
| EntriesAluMulBkuBrhJmp | 25010 | 0 | 0 | SUCCEEDED |
| EntriesAluCsrFenceDiv | 25001 | 0 | 0 | SUCCEEDED |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 18755 | 0 | 0 | SUCCEEDED |
| EntriesVfmaVialuFixVfalu | 18369 | 0 | 0 | SUCCEEDED |
| EntriesFaluFcvtF2vFmacFdiv | 16619 | 0 | 0 | SUCCEEDED |
| EntriesFaluFmacFdiv | 16549 | 0 | 0 | SUCCEEDED |
| EntriesFaluFmac | 15934 | 0 | 0 | SUCCEEDED |
| EntriesVfdivVidiv | 12136 | 0 | 0 | SUCCEEDED |

容差：**0**。预测的是"同一个数"，不是"差不多"。

★这个预测可能错的地方（先写下来，免得事后找补）★
1. 端口表没连 `o_dbg_*` ⇒ 它们在 impl 侧是悬空输出。若 FM 把 `xs_iq_entry` 的悬空
   输出算成 unread 点，strict 下会直接 PARTIAL、passing 也会变。我的判断是常数 0
   不是寄存器、不产生比较点；**若实测出现 unread_notcompared != 0，就是这一条判断错了**，
   我会如实记成预测失败，并去查 g_no_dbg_out 而不是去放宽判据。
2. 钉点脚本 `verif/ut/*/fm_pins_pre.tcl` 字节变了（catch 空守卫 -> 用返回值 fail-closed
   + expect 常数）。harvest 关二 chk_pins=`bridged`：`scripts/fm_pins_trace.tcl` 差分跑
   判定**调用序列逐字节相同**。若新守卫在实跑里抛 `IQE_PIN_FAIL`，那说明"序列相同"
   与"名字都存在"是两件事，passing 会掉 —— 同样记成预测失败。
3. `scripts/fm_eq.tcl` 白名单搬到了 `verif/fm_target_config/<top>.tcl`（harvest
   chk_fm_eq=`trace_equal`）。若实跑点数与旧值有整齐的偏移，先查这里。

## 复跑命令

    cd /home/eda/xs-env/wt-entrerun/verif/ut/<TARGET> && make fm-<TARGET>
    # FM_MODE 默认 signoff-strict；GOLDEN_RTL 默认 /home/eda/xs-env/G1-canonical/golden-rtl
    # 判定权威 scripts/fm_verdict.py（fail-closed），receipt 由 scripts/make_receipt.py 出

## 实测（跑完回填，见本文件 ACTUAL 段与 docs/entries_rerun_actual.tsv）

---

## ACTUAL（跑完回填。★上面的预测一字未改★：git log --follow docs/entries_rerun_prereg.md
##   在本次追加之前只有 fc1f3cdd 一个 commit，就是写下预测的那一次。）

**9/9 SUCCEEDED，9/9 passing 与预测逐位相同，delta 全 0，容差 0 的预测全中。**
逐条读数在 `docs/entries_rerun_actual.tsv`，UT 在 `docs/entries_rerun_ut.tsv`，
receipt 在 `evidence/fc1f3cddb64e/<target>/`（已 `git add -f`）。

预测里写下的三条「可能证伪它」，实跑逐条落空——这三条是**先写后验**的，不是事后补的：
1. 悬空 `o_dbg_*` 没产生任何 unread 点：9/9 `unread_notcompared=0`，strict 铁律下 allowlist 为空。
2. 新的钉点 fail-closed 守卫 9/9 `miss=0` 且 `n` 恰等于生成时钉死的 `expect`；
   9 份 fm.log 行首 `Error:` 计数全为 0。
3. 白名单迁到 `verif/fm_target_config/` 没有造成任何点数偏移。

**D2 措辞规矩在本批不触发**（记下来是为了说明我核对过、而不是忘了）：
`failing == limit` 的截断措辞只在失败计数被截断时才用；本批 9/9 的
`native_facts.failures.failing.total == 0` 且 `truncated == False`，
没有任何一个数是截断值，所以 passing 可以按完整规模读。

**验收**：在 main worktree 里只读重跑 `gen_receipt_harvest.py`，9 行全部
`chk_impl=same`、`verdict=COLLECTED`、证据指向 `wt-entrerun:fc1f3cddb64e`；
全表 `NEEDS_RERUN` 由 25 降到 16，正好少这 9 个。

**证明期间实现字节没动过**：起跑前对 10 个 impl 文件取的 sha256 快照，
在最后一份 receipt 产出之后 `sha256sum -c` 逐个复核仍全部一致；
全程 `git status --porcelain -- rtl verif scripts` 为空（本 lane 只提交 docs/ 与 evidence/）。
