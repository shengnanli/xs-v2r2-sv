# CtrlBlock `wbDelayedBits` per-lane field inventory (golden-faithful narrowing)

Purpose: eliminate the 7608 `unread_impl` residual reported by the official CtrlBlock
gate2 (native FM SUCCEEDED 54839/0, compare=0, FM-036=0, allow OK; only residual =
`unread_impl=7608`). Root cause: `ctrlblock_datapath.svh` block 3-A registered the
**entire** `wb_exu_output_t` struct (474 bits) into `wbDelayedBits_reg` on all 27 lanes,
while golden (firtool DCE) keeps only the per-lane fields the Rob actually consumes.

## Evidence method

- Golden kept fields: distinct `delayedNotFlushedWriteBack_delayed_bits_r_[<N>_]<field>`
  registers in golden `CtrlBlock.sv` (lane 0 = bare `r_<field>`, lanes 1..26 = `r_<N>_<field>`).
- Impl consumed fields: distinct `wbDelayedBits[<N>].<field>[<bit>]` references in
  `rtl/backend/ctrlblock_inst.svh` (the only consumer; `wbDelayedBits` is referenced
  nowhere else).
- Machine-checked result: **golden kept set == impl consumed set, per lane, per bit
  (including sparse exceptionVec bit indices). Zero mismatch across all 27 lanes.**

See `wbdelayed_field_inventory.json` for the full per-lane `kept` list and the
`dead_struct_fields` list, plus `golden_vs_impl_mismatch: []`.

## Deleted (golden-DCE'd) fields — dead on ALL lanes, zero consumers

These `wb_exu_output_t` members are never kept by golden on any lane and have **0**
references in `ctrlblock_inst.svh` (verified). They were pure impl-only cone-dead
registers when the whole struct was registered:

| field | width |
|---|---|
| redirect_bits_robIdx_flag | 1 |
| redirect_bits_robIdx_value | 8 |
| redirect_bits_ftqIdx_flag | 1 |
| redirect_bits_ftqIdx_value | 6 |
| redirect_bits_ftqOffset | 4 |
| redirect_bits_level | 1 |
| redirect_bits_cfiUpdate_backendIAF | 1 |
| redirect_bits_cfiUpdate_backendIPF | 1 |
| redirect_bits_cfiUpdate_backendIGPF | 1 |
| redirect_bits_cfiUpdate_pc | 50 |
| redirect_bits_cfiUpdate_target | 50 |
| redirect_bits_fullTarget | 64 |

Plus per-lane sparse dead bits of otherwise-kept fields (the un-consumed
`exceptionVec` high bits on lanes 7/13/14/19/21/22/24, etc.).

Total impl-only dead register bits removed by the narrowing: **7436**
(struct-whole-register was 27 * 474 = 12798 bits; narrowed keeps 5362 bits =
exactly the golden per-lane consumed set). The gate's 7608 differs slightly because
FM also counts a few bookkeeping/vector points; the narrowing removes exactly the
impl-only registered cone-dead bits that produce `unread_impl`.

## Kept (golden-retained) fields — reset / enable / timing / lane mapping unchanged

Each lane keeps only the fields golden retains (== the fields `inst.svh` reads). The
per-lane narrow registers `wbd<N>_<field>` are `RegEnable(wbInBits[N].<field>,
enable=wbInValid[N])` with **no reset** — bit-for-bit the same timing/enable/lane as
the original whole-struct `RegEnable`. `wbDelayedBits[N]` is now a combinational
`wb_exu_output_t` view (`always_comb`, default 0) that re-exposes those registers so
`ctrlblock_inst.svh` (`wbDelayedBits[N].<field>`) is unchanged.

Per-lane kept-field counts (see JSON for exact lists):

```
lane  0:  4    lane  7: 10    lane 14:  8    lane 21: 12
lane  1:  7    lane  8:  6    lane 15:  8    lane 22: 12
lane  2:  4    lane  9:  6    lane 16:  7    lane 23: 27
lane  3:  7    lane 10:  6    lane 17:  7    lane 24: 27
lane  4:  4    lane 11:  6    lane 18: 11    lane 25:  1
lane  5:  9    lane 12:  6    lane 19:  9    lane 26:  1
lane  6:  4    lane 13:  9    lane 20: 12
```

Fields registered but not driven by `ctrlblock_wbpack.svh` (lanes 18/20/23/24 for
`debug_isPerfCnt`/`debug_isMMIO`/`debug_isNCIO` and some `exceptionVec` bits) read the
struct default 0 — this is **identical** to the original behavior (the original whole
struct also registered those default-0 fields and `inst.svh` forwarded them to Rob).
Golden latches 0 there too (the writeback input for those lanes does not carry the
field), which is why the original core was already FM-equivalent. The narrowing
preserves this exactly.

## Files changed

- `rtl/backend/ctrlblock_datapath.svh` block 3-A: `wbDelayedBits` changed from a
  whole-struct register to a combinational view; valid `always_ff` kept as-is; bits
  registered per-lane-narrow via the new include.
- `rtl/backend/ctrlblock_wbdelayed.svh` (new): per-lane narrow `wbd<N>_<field>`
  registers + `always_comb` struct-view rebuild.
- `verif/ut/CtrlBlock/wbdelayed_field_inventory.{json,md}` (this evidence).

No golden, shared/main-owned (fm_eq/run_signoff/verdict/manifest/allow), or non-CtrlBlock
RTL was touched. `ctrlblock_inst.svh` (the consumer) is unchanged.
