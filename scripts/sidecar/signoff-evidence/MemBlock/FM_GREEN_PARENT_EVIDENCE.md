# MemBlock: FM_GREEN_PARENT_EVIDENCE (NOT a bank)

codex 0089 CRITICAL: 此 parent clean run(shard-A e17隔离worktree RUNNER_RC=0/gate=PASS,
run_id SGN-MemBlock-1785277064)保留为 **parent glue FM-green 证据**, 但**不构成 bank**。

原因(codex 0089独立复核NO-GO): parent archive来自e17, 当前HEAD已改fm_eq/verdict/runner;
且56节点closure依赖的多个child ledger绿是stale/手改/RC1(非当前HEAD clean official gate):
- StorePfWrapper: 当前仓内+/tmp官方gate PARTIAL/RC1(2 golden-only unread_ref), 无dead_ref JSON
- 15目标标PASS_DEAD_REF但manifest要SUCCEEDED/dead_ref空/e17 shard-B gate全RC1
- VfofBuffer/SMSPrefetcher仓内权威归档仍RC2/CLEAN_GATE_FAIL(RC0只在/tmp)

MemBlock ledger回退为PROOF_GAP/PARENT_CLEAN_CHILD_POLICY_GAP。真bank须
MemBlock-closure-integrator在全child current-HEAD clean official gate + dead_ref/allow绑定后,
从同一frozen clean commit fresh parent gate + 第三方只读复核。
