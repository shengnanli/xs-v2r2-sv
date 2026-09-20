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

## Result --- both app-var settings, side by side

The same comparison was run twice. Only the treatment of dangling nets differs.

| | `binary:X` (Formality's default) | `0` |
|---|---|---|
| passing | 108,209 | **108,669** |
| failing | **20** (20 matched, 0 unmatched) | **0** |
| unverified | **440** | **0** |
| unmatched reference points | **460** | **0** |
| unmatched implementation points | 0 | 0 |
| verdict | **FAILED** | **SUCCEEDED** |
| ref / impl elaborate | 622 s / 609 s | 616 s / 634 s |
| match / verify | 1973 s / 1044 s | 1991 s / 1024 s |
| peak memory | 14,730 MB | 14,836 MB |

Conservation closes exactly: `108,209 + 20 + 440 = 108,669`. Every point that
was unmatched, unverified or failing under the default became a **passing**
point under `0` --- none was dropped or waived.

Cost is effectively identical, so running BOTH is affordable (~2.4 h total) and
that is the recommendation below.

Matching was **108,669 by name, 0 by signature analysis, 0 by topology** in both
runs --- inevitable, since both sides are the same file and every name matches.

Under the default, the 460 unmatched reference points are all `Und` (undriven)
and listed in full in `run_binaryX/unmatched_460.rpt`:

```
448  robDeqGroup_<n>_debug_otherPdest_<m>
  7  deqPtrVec_next_<n>_flag
  5  enqPtrVec_<n>_flag
```

Under `0` that report is empty (`run_undriven0/unmatched_empty.rpt`).

## ★Do not read the clean run as permission to adopt `0`★

The two runs disagree, and by the rule established in `undriven_safety/` a
disagreement is exactly the set that the app var has hidden. Here that set is
the 460 dangling nets, and in THIS run hiding them is harmless --- reference and
implementation are the same bytes, so there is no implementation-side defect
that could be hiding among them.

**That reasoning does not carry to the real proof.** `undriven_safety/` measures
the case where it breaks: if the rewrite leaves a net undriven and golden's
driver for it is identically 0, `binary:X` fails loudly and `0` reports
SUCCEEDED. A golden-vs-self probe **cannot** exercise that case, because the two
sides are identical by construction --- so this calibration establishes the
floor, and establishes nothing at all about whether `0` is safe to adopt.

The protocol that follows from both directories:

1. run the real Rob proof under **both** settings;
2. if the verdicts agree, nothing was hidden;
3. if they disagree, the difference is the hidden set and must be examined
   before either result is used.

Which is why both runs are archived here rather than only the one that looks
better.

## Label: `ROB_SELF_COMPARE_FLOOR` --- a diagnostic tag, NOT a PASS class

codex 0168: this floor is a tool/modelling baseline artefact. It must **not** be
folded into `PASS_DEAD_REF` and **nothing about Rob may be promoted on the
strength of it**. It is reported under its own non-PASS tag,
`ROB_SELF_COMPARE_FLOOR`, with the two groups below kept separate. The 12
boundary artefacts in particular are **not a permanent waiver**: they must be
re-examined whenever the child blackbox boundary changes.

The formal sign-off still runs under Formality's default (`binary:X`) and still
requires no unexplained residue. "Both undriven settings agreed" is a
consistency report, not an acceptance condition.

## Localisation: where the 460 come from, and whether they are observable

## The 460 are not one thing --- they are 56 + 12, and the two behave differently

460 compare points resolve to **68 distinct base signals** (56 signals x 8 bits,
plus 12 single-bit). Checking each against the golden source --- independently of
FM's own `Und` label --- splits them cleanly:

| | count | what golden actually says |
|---|---|---|
| `robDeqGroup_<n>_debug_otherPdest_<m>` | 56 signals = **448 points** | declared and **never driven by anything**; intrinsically dangling |
| `deqPtrVec_next_<1..7>_flag`, `enqPtrVec_<1..5>_flag` | 12 signals = **12 points** | declared as a bare `wire` whose ONLY other occurrence is a child instance output pin |

The second group is the interesting one. For example:

```
Rob.sv:2301     wire               deqPtrVec_next_1_flag;
Rob.sv:264972     .io_next_out_1_flag   (deqPtrVec_next_1_flag),   // NewRobDeqPtrWrapper
```

★These 12 are undriven **because the 8 children are blackboxed**, not because
golden leaves them dangling.★ With the children elaborated they would be driven
by `NewRobDeqPtrWrapper` / `RobEnqPtrWrapper` outputs. So they are an artifact of
the proof BOUNDARY and would move if the boundary moved; the 448 would not.

### Group A --- 56 signals / 448 points: undriven registers that REACH OUTPUTS

Every occurrence of one of them in golden, e.g.
`robDeqGroup_0_debug_otherPdest_0`:

```
 29948:  reg  [7:0]  robDeqGroup_0_debug_otherPdest_0;      declaration
 30696:     {robDeqGroup_0_debug_otherPdest_0}};            a READER
253750:  robDeqGroup_0_debug_otherPdest_0 = _RANDOM[...];   ← inside RANDOMIZE_REG_INIT
```

The only assignment is in the simulation-only random-init block. Both UT and FM
compile with `+define+SYNTHESIS`, so **in the synthesised design these 56
registers have no driver at all** -- declared, read, never written.

★They are NOT dead.★ The reader chain runs all the way to the port boundary:

```
robDeqGroup_<bank>_debug_otherPdest_<m>
  -> _GEN_41 / _GEN_42 / ...            (8x8 packed bus, one per otherPdest index)
  -> assign io_commits_info_<p>_debug_otherPdest_<m> = _GEN_4x[deqPtrVec_<p>_value[2:0]]
  -> OUTPUT PORT
```

So golden's own `io_commits_info_<p>_debug_otherPdest_<m>` outputs are
**undefined in the synthesised design**. That is a property of golden, and it is
the single most important thing on this page for whoever writes the core:

> ★A rewrite that drives those outputs with anything definite will DIFFER from
> golden, and that difference is real, not floor.★ It must be a deliberate,
> argued decision -- not something absorbed by "the self-compare fails here too".

That is exactly the trap codex 0168 names: the floor must not become a pocket
that swallows genuine rewrite differences.

### Group B --- 12 signals / 12 points: boundary artefacts with NO reader

`deqPtrVec_next_<1..7>_flag`, `enqPtrVec_<1..5>_flag`. Two occurrences each: a
bare `wire` declaration, and one child-instance output pin. **Nothing in Rob
reads them**, so they cannot reach any compare point. They are undriven only
because the 8 children are blackboxed; elaborate the children and they are
driven. ★Re-review required whenever the child boundary moves --- not a permanent
waiver.★

### What is still NOT localised

The exact partition of the 460 into FM's **20 failing** and **440 unverified**
is not established here. The two archived runs predate the
`report_failing_points` call added to the probe (commit 46edc8f), so the failing
points were never named. 56+12 does not line up with 20+440, so the split does
not follow the two groups above and must not be assumed to. Recovering it costs
one re-run with the current probe, and that has NOT been done.

A first pass at this check wrongly reported 448-with-no-driver and
12-with-a-driver, because it compared names like `foo[3]` (carrying FM's bit
index) against driver names that never carry one. Stripping the index first is
what produced the table above --- worth noting because the wrong version looked
perfectly plausible.

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

| path | what |
|---|---|
| `run_binaryX/unmatched_460.rpt` | the 460 unmatched reference points under the default setting, verbatim |
| `run_binaryX/fm_summary.txt` | phase timings and the Formality result block, verbatim |
| `run_undriven0/fm_summary.txt` | the same under `verification_set_undriven_signals 0` |
| `run_undriven0/unmatched_empty.rpt` | the (empty) unmatched report under `0` |
| `undriven_safety/` | the four-run measurement showing where `0` MASKS a real defect |

---

## Addendum 2026-09-20 --- Group A settled at the DESIGN level, from Chisel source

The analysis above was made entirely from the flattened `Rob.sv`. That left one
unexamined possibility: that `debug_otherPdest` was driven in the Chisel design
and only *looked* undriven after firtool. It was not. The Chisel source for the
golden commit is present on this machine and, verified with
`git log b36a1a2a5..HEAD -- src/main/scala/xiangshan/` (empty), **unchanged
since golden was generated**:

| | |
|---|---|
| `src/main/scala/xiangshan/backend/rob/RobBundles.scala` | declares `debug_otherPdest` in `RobCommitEntryBundle` (`Vec(7, UInt(PhyRegIdxWidth.W))`, guarded by `basicDebugEn`) |
| same file, `connectCommitEntry(...)` | copies **every other** field of that bundle from the `RobEntryBundle` --- and **never mentions `debug_otherPdest`** |
| `Rob.scala` | `robDeqGroup = Reg(Vec(bankNum, new RobCommitEntryBundle))`; the only writes to it are the two `connectCommitEntry` calls |

`RobEntryBundle` has no `debug_otherPdest` member at all, so there is nothing
for `connectCommitEntry` to have copied. The field exists on the commit-entry
bundle, is read out to `io.commits.info(i).debug_otherPdest`, and is written by
nobody. ★It is a design-level dangling field, not a firtool artefact and not a
modelling artefact of this proof.★

Note the near-miss that makes this worth stating precisely: `Rob.scala` DOES
maintain a similarly named, genuinely driven array

```scala
val debug_VecOtherPdest = RegInit(VecInit.fill(RobSize)(VecInit.fill(8)(0.U(PhyRegIdxWidth.W))))
vldWBs.map { vldWb => when (vldWb.fire && ...) { debug_VecOtherPdest(vldWbRobIdx)(vldWbvdIdx) := vldWbPdest } }
```

`debug_VecOtherPdest` (160 x 8, reset to 0, written by the two vector-load
writeback ports) is a **different** array that feeds difftest's `otherwpdest`.
Reading the two as one thing --- they differ by a prefix --- would turn a driven
array into "the undriven one" or vice versa. They are separate families in the
register inventory and must stay separate.

### Exact size, measured

| | |
|---|---|
| register fields | `robDeqGroup_<0..7>_debug_otherPdest_<0..6>` = 8 x 7 = **56 registers** |
| register bits | 56 x 8 = **448 bits** |
| output ports reached | `io_commits_info_<0..7>_debug_otherPdest_<0..6>` = **56 ports**, 8 bits each = **448 output bits** |

(448, not 512: the commit-entry vector is `Vec(7, ...)`, not 8. Difftest's
`otherwpdest` takes 8 entries from the *other* array, `debug_VecOtherPdest`;
that is where an "8" in this neighbourhood comes from.)

### What is still open

The design choice itself --- what the rewrite drives onto those 448 undriven
output bits --- is **still unresolved and still needs a ruling**. This addendum
only removes one hypothesis (firtool artefact) and pins the exact width. Until
the ruling lands, the `robDeqGroup` family is the one family deliberately left
unwritten in the core.

---

## Addendum 2026-09-20 (2) --- 留空整个 `robDeqGroup` 族的射程，量出来了

拆活时的说法是"先写 12 族，`robDeqGroup` 等裁定"。那要先知道这一刀切下去有多深，
因为 `robDeqGroup` 不是一个普通的数据族，它是**提交读口**：

```scala
val robDeqGroup = Reg(Vec(bankNum, new RobCommitEntryBundle))
val rawInfo    = VecInit((0 until CommitWidth).map(i => robDeqGroup(deqPtrVec(i).value(2,0))))
val commitInfo = ... 同上 ...
```

`io.commits.info` / `deqPtrEntry`（= `rawInfo(0)`，异常、冲刷、`blockCommit`、
`io.lsq.*` 全从它出发）/ `io.trace` 都挂在它下游。

`scripts/rob_deqgroup_blast.py` 从 golden 做传导染色（组合网 + 寄存器次态），
结果：

| 留空范围 | 核能驱动的输出 |
|---|---|
| **整个 `robDeqGroup` 族（45 字段）** | **116 / 633（18%）** |
| 只留空 `debug_otherPdest_0..6`（7 字段 / 56 寄存器） | **577 / 633（91%）** |
| 差距 | **461 个输出端口** |

（667 个输出里 34 个由子模块引脚直接驱动，不是核的义务，故分母取 633。
按 667 计，`robDeqGroup` 下游是 517 个，78%。）

★结论：留空整族会得到一个只驱动 18% 输出的文件 —— 正是本轮明令要避免的
SCAFFOLD，只是更大一号。★ 而未定的设计选择实际只覆盖 56 个输出端口。

所以在裁定之前，`rtl/backend/Rob.sv` **没有建**。需要的裁定是把留空范围从
"`robDeqGroup` 整族"收窄到"`robDeqGroup.debug_otherPdest_0..6`"；其余 38 个字段
由 `connectCommitEntry` 逐字段完整给出，没有任何待定之处。

### 量具自己的两个坑（都踩过，都配了反测）

1. **多维 packed wire**：firtool 写 `wire [7:0][6:0] _GEN_8 = {...};`。
   只允许一个方括号的驱动式正则会静默漏掉它，染色在那里断掉 ——
   实测 517/667 变成 325/667，**两个数看上去都合理**。
2. **折行的 `if` 头**：寄存器次态要从 always 语句树里取，而 firtool 会把长
   `if` 条件折行、下一行就是它的无 `begin` 单语句体。按"累到分号"合并续行会把
   条件头和语句体粘成一个 token，整棵树错位（把 160 个并列 `if` 解成 160 层
   else 链）。见 `scripts/test_rob_fold_probe.py`。

两条都进了 `gate_all.sh` 的负测。
