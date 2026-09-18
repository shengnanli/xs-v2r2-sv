# Rob golden-vs-self FM diagnostic — the structural floor for any Rob proof

**This is NOT a receipt and carries NO verdict.** There is no `receipt.json`
here on purpose: `build_receipt_index.py` walks `evidence/**/receipt.json`, so
this directory is invisible to the ledger. It is kept in version control because
it is a **signoff credential** — it defines what "clean" can even mean for Rob —
not because anything was signed off.

## What was run

Golden Rob compared against a **byte-identical copy of itself**, with Rob's 8
child instances left as symmetric unresolved blackboxes.

| | |
|---|---|
| ref | `/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv` |
| impl | a copy of that same file |
| **both sha256** | `4aa8838b95283d5aa1f46161e4abf96de764a6c6cbaff09f189a829ae601f130` |
| lines / ports / registers | 266,227 / 2,200 / 11,639 |
| appvars | `hdlin_unresolved_modules = black_box`, **`verification_merge_duplicated_registers = false`** |
| tool | `fm_shell` V-2023.12-SP3 |
| script | `scripts/rob_fm_scale_probe.tcl` with `ROB_MERGE_DUP=false` |

The two sha256 were checked before the run and again after it.

Why `merge_dup=false`: with the tool default (`true`) the same comparison burned
**5,674 s of CPU** inside "Merging duplicated registers in block i:/WORK/Rob" and
**never reached `match` at all**. Rob has 11,639 registers of which ~79% of the
bits are 160-entry debug arrays with structurally identical next-state
functions — the worst case for duplicate-register merging. Turning merging off
is a **strengthening, not a relaxation**: nothing is blackboxed, no point is
skipped, the reference is not constrained; FM is only required to compare
registers one by one instead of after merging, so compare points can only
increase. Precedent in this repo: RenameBuffer and MulUnit.

## Cost (this is the whole point of running it before writing the core)

```
ref elaborate    622 s
impl elaborate   609 s
match           1973 s    (32.9 min)
verify          1044 s    (17.4 min)
peak memory   14,730 MB
end to end     ~72 min,  fm_shell errors = 0
```

## Result

```
Verification FAILED
 108,209 Passing compare points
      20 Failing compare points (20 matched, 0 unmatched)
       0 Aborted compare points
     440 Unverified compare points
     460 Unmatched REFERENCE compare points, 0 unmatched implementation
     total 108,209 + 20 + 440 = 108,669   and   20 + 440 = 460
```

Matching was **108,669 by name, 0 by signature analysis, 0 by topology** —
inevitable, since both sides are the same file and every name is identical.

The 460 unmatched reference points are all `Und` (undriven), listed in full in
`unmatched_460.rpt`:

```
448  robDeqGroup_<n>_debug_otherPdest_<m>
  7  deqPtrVec_next_<n>_flag
  5  enqPtrVec_<n>_flag
```

## Why this matters

**The baseline for a Rob proof is not "0 failing, 0 unmatched".** Both sides
here are the same bytes, so none of these 20 failing points can be a design
difference. They are a structural floor that no quality of rewrite removes.

> **Until these 460 are classified, a Rob run showing "20 failing" must NOT be
> read as "nearly green".** Someone who does not know this floor exists will see
> 20 failing points and go hunting for a bug in the core.

## Mechanism — FM states it, and an earlier version of this note was wrong

An earlier draft of this note recorded the 20 failing points as
"measured but mechanism unknown". **That was wrong, and the reason is worth
keeping: the explanation was printed in the log and I had not read it.**
`probe.log:221`:

```
ATTENTION: 20 failing compare points have unmatched undriven signals in their
             reference fan-in.  To report such failing points, use
               "report_failing_points -inputs unmatched -inputs undriven".
           To read about undriven signal handling, use
             "man verification_set_undriven_signals".
```

So: golden has 460 dangling (undriven) signals; they are unmatched between the
two containers; 20 compare points have such a signal in their **reference
fan-in**, which leaves those points indeterminate, so they fail. Nothing exotic.

**What is still untested:** whether `verification_set_undriven_signals` (which
FM names above) makes those 20 pass by pinning undriven signals to a fixed value
on both sides. That is a one-appvar experiment and it has NOT been run. Do not
assume it works; equally, do not reach for a dead_ref allowlist before trying
it — an appvar that removes the asymmetry is a cleaner answer than an allowlist
that waives it.

## Reproducing

```
D=<scratch dir with a unique suffix>
cp /home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv $D/Rob_impl.sv
cd $D && ROB_MERGE_DUP=false fm_shell -64 -work_path $D/fmwork \
    -file <repo>/scripts/rob_fm_scale_probe.tcl < /dev/null > $D/probe.log 2>&1
```

The `< /dev/null` is mandatory: on a script error `fm_shell` drops to an
interactive prompt and sits there holding a license with the log frozen.

Budget ~72 minutes and ~15 GB. **That cost is exactly why this list is committed
rather than left to "rerun to regenerate"** — and why the next person, who has
no reason to suspect a floor exists, would never think to spend it.

## Files

| file | what |
|---|---|
| `unmatched_460.rpt` | the 460 unmatched reference points, verbatim from `report_unmatched_points` |
| `fm_summary.txt` | the phase timings and the Formality result block, verbatim |
