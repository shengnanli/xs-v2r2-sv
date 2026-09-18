# Is `verification_set_undriven_signals 0` a relaxation? Measured: yes, narrowly.

I proposed setting this app var to `0` so that golden Rob's 460 dangling signals
stop behaving as free X-valued variables, and argued that "removing the asymmetry
is cleaner than waiving it". **That argument was too optimistic, and this
directory is the measurement that shows where it breaks.**

The app var applies to BOTH containers. So the question is not only "does it fix
the reference side" but "does it hide anything on the implementation side".

## The experiment

Four runs: two reference variants x two app-var settings. The implementation is
the same in all four — it leaves `o2` undriven, i.e. it has a **missing driver**,
the classic rewrite defect this proof exists to catch.

| reference drives `o2` with | `binary:X` (default) | `0` |
|---|---|---|
| `a & b` — real logic | **FAILED** (1 failing) | **FAILED** (1 failing) — caught |
| `a & ~a` — identically 0, a dead driver | **FAILED** (1 failing) | ★**SUCCEEDED** — masked★ |

Both settings catch a missing driver in the ordinary case, because forcing the
implementation's net to constant 0 still compares it against the reference's real
value. The masking needs a coincidence: the reference's driver must itself be
identically 0. Then constant-0 matches constant-0 and the defect disappears.

## What this means for Rob

`0` is **not** unambiguously a strengthening. It is safe exactly when the
implementation has no undriven nets of its own — and note that
`unmatched_impl == 0` does **not** establish that: in the runs above the
implementation's undriven net produced a *matched failing* point, not an
unmatched one, so a check on unmatched counts would have passed it straight
through.

The guard that does work needs no new tooling: **run the proof both ways.**

* same verdict under `binary:X` and under `0` → nothing was masked
* different verdict → the difference IS the masked set, and it has to be looked
  at before either result is used

which is why both the `binary:X` and the `0` run of the Rob self-compare are
archived side by side in the parent directory rather than only the one that
happens to look better.

## Reproducing

```
cd <this directory>
UND=default fm_shell -64 -file run.tcl  < /dev/null   # ref = real logic
UND=0       fm_shell -64 -file run.tcl  < /dev/null
UND=default fm_shell -64 -file run0.tcl < /dev/null   # ref = dead driver
UND=0       fm_shell -64 -file run0.tcl < /dev/null
```

Seconds per run, ~900 MB. `< /dev/null` is mandatory — on a script error
`fm_shell` drops to an interactive prompt and holds a license with the log frozen.
