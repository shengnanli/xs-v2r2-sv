#!/usr/bin/env python3
# gen_robdeqgroup_pins.py — pRobDeqGroup (codex 0117) head-of-queue commit-state
# ------------------------------------------------------------------------------
# Emits the explicit 1:1 golden<->impl set_user_match bijection + a content-hashed
# manifest for the robDeqGroup head-of-queue state chain:
#   golden FLAT reg   robDeqGroup_<N>_commit_v / _commit_w / _needFlush   (N=0..7)
#   impl  ARRAY member i:/WORK/Rob/u_core/robDeqGroup_reg[<N>][commit_v|commit_w|need_flush]
#
# These are the 8-bank registered line-read merge outputs (robDeqGroup is itself
# the read-pipeline register: rtl/backend/Rob.sv `robDeqGroup[b] <= robDeqGroup_next[b]`;
# golden Rob.sv reg robDeqGroup_<N>_{commit_v,commit_w,needFlush}). golden's flat
# name and impl's array-member name differ => FM never auto-matches them => they
# are compare points in NO partition today. The pRobDeqGroup partition retains
# outputs (io_commits_commitValid_0..7 / io_headNotReady) that READ these regs
# directly (commitValidThisLine_N = commit_v & commit_w & …; commit_block_N =
# ~commit_w & …; allowOnlyOneCommit = |(commit_v & needFlush)), so once pinned
# they become *read* compare points that FM VERIFIES.
#
# NOTE: needFlush<->need_flush is ALSO pinned by the shared foreach-b loop in
# run_partition_checkpoint.sh; this generator records the COMPLETE {commit_v,
# commit_w,needFlush} triad in the manifest for provenance/audit, but the runner
# only *emits* the commit_v/commit_w pins for robdeqgroup (need_flush comes from
# the shared loop) to avoid a double set_user_match. Both are captured here so the
# manifest is the single source of truth for "which head-state regs are matched".
#
# Pure set_user_match, NO dont_verify / NO ref-constraint / NO blackbox. The
# manifest hash lets the runner (or a reviewer) prove the emitted pin set matches
# this locked declaration; FM-036 on any pin is fail-closed by the driver's
# _rob_soa_pin proc + EXTRA_PIN_ASSERT_FAIL exit 7.
import argparse, json, re, hashlib, sys, os

COMMIT_WIDTH = 8

# golden flat suffix  <->  impl robDeqGroup_reg[N][member]
# (all 1-bit; robDeqGroup itself is the line-read/read-pipeline register)
HEAD_STATE = [
    ("commit_v",  "commit_v"),
    ("commit_w",  "commit_w"),
    ("needFlush", "need_flush"),
]


def scan_golden_regs(golden_path):
    """Return set of robDeqGroup_<N>_<field> flat reg names declared in golden."""
    pat = re.compile(
        r'^\s*reg\s+(?:\[\d+:\d+\]\s+)?(robDeqGroup_\d+_[A-Za-z_][A-Za-z_0-9]*)\s*;')
    names = set()
    with open(golden_path) as fh:
        for line in fh:
            m = pat.match(line)
            if m:
                names.add(m.group(1))
    return names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", default="Rob")
    ap.add_argument("--impl-prefix", default="u_core")
    ap.add_argument("--reduced-golden", required=True,
                    help="cone-reduced golden Rob (must retain robDeqGroup head regs)")
    ap.add_argument("--out", required=True, help="output dir")
    # which golden suffixes this generator is *authoritative* for in the manifest.
    # (needFlush is emitted by the shared loop in the runner; commit_v/commit_w by
    #  the runner's robdeqgroup-gated block. Manifest records all three.)
    ap.add_argument("--emit", default="commit_v,commit_w",
                    help="comma-separated golden suffixes to EMIT as pins here")
    a = ap.parse_args()

    present = scan_golden_regs(a.reduced_golden)
    errors = []
    layout = []
    for gold_suf, impl_member in HEAD_STATE:
        for N in range(COMMIT_WIDTH):
            gname = f"robDeqGroup_{N}_{gold_suf}"
            if gname not in present:
                errors.append(f"MISSING golden reg {gname} in reduced golden "
                              f"{a.reduced_golden}")
                continue
            layout.append({
                "entry": N, "golden_suffix": gold_suf, "impl_member": impl_member,
                "golden_reg": f"r:/WORK/{a.top}/{gname}_reg",
                "impl_reg":   f"i:/WORK/{a.top}/{a.impl_prefix}/robDeqGroup_reg[{N}][{impl_member}]",
            })

    os.makedirs(a.out, exist_ok=True)

    # ---- content hash over the full triad bijection (provenance) ----
    body = "\n".join(f"{e['golden_reg']}|{e['impl_reg']}" for e in layout)
    root = hashlib.sha256(body.encode()).hexdigest()

    emit = set(a.emit.split(",")) if a.emit else set()
    emitted = [e for e in layout if e["golden_suffix"] in emit]

    manifest = {
        "generator": "gen_robdeqgroup_pins.py",
        "top": a.top,
        "partition": "robdeqgroup",
        "purpose": "head-of-queue commit-state chain as VERIFIED (read) FM compare "
                   "points; independently decide commit_v/commit_w/need_flush "
                   "golden==impl. NOT a mask of deqVlsCanCommit/exceptionGen/"
                   "blockCommit/s0_out (never pinned).",
        "commit_width": COMMIT_WIDTH,
        "head_state_triad": [f"robDeqGroup_N_{g}<->robDeqGroup_reg[N][{m}]"
                             for g, m in HEAD_STATE],
        "triad_total_pins": len(layout),
        "emitted_here": sorted(emit),
        "emitted_pin_count": len(emitted),
        "note_needFlush": "needFlush<->need_flush is emitted by the shared foreach-b "
                          "loop in run_partition_checkpoint.sh (recorded here for "
                          "provenance; NOT re-emitted to avoid double set_user_match).",
        "no_dont_verify": True,
        "no_ref_constraint": True,
        "no_blackbox_added": True,
        "bijection_ok": len(errors) == 0,
        "errors": errors,
        "head_state_bijection_root_sha256": root,
        "layout": layout,
    }
    with open(f"{a.out}/robdeqgroup_pins_manifest.json", "w") as fh:
        json.dump(manifest, fh, indent=2)

    # ---- human-readable golden<->impl reg-name map ----
    with open(f"{a.out}/robdeqgroup_pins_map.txt", "w") as fh:
        fh.write("# golden_flat_reg  <->  impl_array_member  (emit? EMITTED/shared-loop)\n")
        for e in layout:
            how = "EMITTED-here" if e["golden_suffix"] in emit else "shared-loop"
            fh.write(f"{e['golden_reg']}  <->  {e['impl_reg']}  [{how}]\n")

    # ---- the actual tcl pin fragment for the EMITTED subset (commit_v/commit_w) ----
    #  Uses the driver's _rob_soa_pin proc (FM-036 fail-closed). This fragment is
    #  informational/auditable; the runner emits equivalent lines inline. Written
    #  so a reviewer can diff runner output against this locked declaration.
    with open(f"{a.out}/robdeqgroup_emit_pins.tcl", "w") as fh:
        fh.write("# AUTO-GENERATED by gen_robdeqgroup_pins.py — head-state EMITTED pins\n")
        fh.write(f"# manifest root sha256 = {root}\n")
        fh.write("# _rob_soa_pin is FM-036 fail-closed (see rob_soa_entry_pins.tcl)\n")
        for e in emitted:
            gr = e["golden_reg"]
            ir = e["impl_reg"].replace("[", "\\[").replace("]", "\\]")
            fh.write(f"_rob_soa_pin {gr} {ir}\n")

    print(f"[robdeqgroup-pins] triad regs total={len(layout)} "
          f"(commit_v/commit_w/needFlush x{COMMIT_WIDTH}) "
          f"emitted-here={len(emitted)} ({sorted(emit)}) "
          f"bijection_ok={manifest['bijection_ok']} root={root[:12]}")
    if errors:
        for e in errors[:12]:
            print("  ", e)
        sys.exit(2)


if __name__ == "__main__":
    main()
