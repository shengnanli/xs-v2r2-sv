# Rob SoA ★2-GROUP CHECKPOINT★ (codex 0104) — G1+G2 absorbed (15/25 fields SoA)

Run: pCommit(commit-partition) cone-DCE FM, ref = agent/rob-conedce locked
derivative `Rob_golden_commit.sv` (manifest hash d4e4b9a7…, verified), impl =
**committed** SoA core @c40ae823 (G1+G2, 15/25 fields SoA) + locked trimmed
wrapper `Rob_impl_commit.sv` (e4e013ef…, `xs_Rob_core u_core (.*)` port surface
unchanged by SoA). Pinned tcl = `fm_conedce_partition_pinned.tcl` (verbatim from
agent/rob-conedce@803cb5b). Evidence:
`/tmp/rob-soa-integ2-evidence/checkpoint_g1g2/` (fm.log/time.log/pins/unmatched.rpt).

## Measured vs baseline (packed impl, unpinned; pCommit_match_evidence.txt)

| metric | baseline (packed) | checkpoint (15-field SoA + pins) |
|---|---|---|
| field-map pins | n/a (FM-036 wall, 9263/9440 unresolvable) | **5440/5440 applied, fail=0, FM-036=0, FM-013=0** |
| match candidate/compare total | 60714 | **≈16512** (12162 matched CP + 1225 ref-unm + 3125 impl-unm) = **-73 %, < 30k 目标达成** |
| matched by | (signature grind) | **5280 user-pin + 6882 name + 0 signature + 0 topology** |
| match phase | 13 % @ 54 min, killed (never finished) | **COMPLETED ≈21 min** (30-min matched % = 100 %) |
| model building | (reached) | ≈8 min |
| peak memory | 4740 MB | 4389 MB (bounded) |
| golden ref reg bits | 7079 (16x cone-DCE) | same derivative |
| impl-side unread (cone-dead, not compared) | — | 28585 |

★判定: compare points 明显沿 <30k 方向降(16.5k) + mapping 零失败 → **继续吸收 G3/G4**★

## Verify phase (bonus — baseline never reached it): FAILED, 已诊断为既有 X-guard 缺口

`verify` ran to the default failing limit (20F/0A/700P/11442U, 5 %) → FAILED.
All 20 failing points fall in ONE class — **impl 'x-guard vs golden firtool
out-of-range-index lowering** on 8-bit robIdx read paths:

- `u_core/robDeqGroup_reg[0|6|7]\[commit_v|commit_w|interrupt_safe]` — deq-bank
  read pipeline: impl `rob_entries_next[160..255] = 'x` (Rob.sv §594-597) and
  `index_in_range → 'x` guards (§765-770, §1876-1881); golden's firtool lowering
  fills out-of-range Vec reads with real-entry aliases (entry-0 default).
- `u_core/rob_uop_num_reg[0][*]` / `rob_uop_num_reg[103][*]` — entry 0 = firtool
  default alias target, entry 103 = bit-truncation alias (e.g. 231 & 0x7F = 103).

FM proves per-cone with register inputs FREE → the runtime-unreachable ≥160
pointer space (ring pointers mod-160, documented Rob.sv §293-298) IS reachable
in the proof, and impl-'x (free) ≠ golden-alias ⇒ not-equivalent. This gap:

1. **predates G1/G2** (all cited lines are canary/base-era, base a63efe4);
2. is **orthogonal to SoA** (storage migration does not touch read-index
   lowering; co-sim vs packed_ref seed1/7/42 errors=0 proves absorbed groups
   changed nothing behaviourally);
3. was **never adjudicated** before — the monolithic/route-B/baseline cone-DCE
   FMs all died in `match`; this checkpoint is the FIRST Rob FM to reach verify.

Residual (future round, NOT this integrator's scope): make the readable core's
out-of-range read semantics mirror golden's firtool lowering exactly (per read
vector: entry-0 default / index-truncation alias) instead of 'x — assumptions/
constraints are banned by discipline, so the fix is RTL-side. Until then a full
Rob FM PASS is blocked by this class even though match now converges.
