#!/usr/bin/env python3
# gen_truecommitcnt_inventory.py — trueCommitCnt (codex 0118) field inventory
# ------------------------------------------------------------------------------
# Records the golden<->impl register correspondence for the 10-bit commit counter
# trueCommitCnt_r that the `truecommitcnt` focused partition makes an FM-VERIFIED
# (read) compare point.
#
# ★This generator emits NO set_user_match / NO pin.★ Unlike gen_robdeqgroup_pins.py
# (which pins golden FLAT robDeqGroup_N_commit_v <-> impl ARRAY member because the
# names differ and FM never auto-matches them), trueCommitCnt_r has the SAME leaf
# name on BOTH sides:
#     golden:  r:/WORK/Rob/trueCommitCnt_r_reg          (flat top-level reg [9:0])
#     impl:    i:/WORK/Rob/u_core/trueCommitCnt_r_reg    (reg [9:0] inside xs_Rob_core)
# so FM's name-based auto-matcher pairs them WITHOUT any user pin. The partition's
# sole retained output io_perf_5_value READS the register (io_perf_5_value_REG <=
# retireCounter_probe = isCommitReg_last ? (trueCommitCnt_r + fuseCommitCnt) : 0),
# so trueCommitCnt_r is a *read* matched compare point that FM VERIFIES directly —
# the equality golden==impl is DECIDED by FM, not asserted by a pin.
#
# This script only (a) proves both regs are present in the reduced/impl sources,
# (b) writes a human-readable inventory + a machine manifest for audit, and
# (c) fails closed (rc=2) if trueCommitCnt_r is missing from the reduced golden
# (which would mean the cone did NOT retain the counter -> the partition would not
# actually verify it).
import argparse, json, re, hashlib, sys, os

WIDTH = 10  # trueCommitCnt_r declared [9:0] on BOTH sides (golden L47539 / impl L1767)


def golden_reg_present(path):
    """True + width if `reg [hi:lo] trueCommitCnt_r;` is declared in the file."""
    pat = re.compile(r'^\s*reg\s+\[(\d+):(\d+)\]\s+trueCommitCnt_r\s*;')
    with open(path) as fh:
        for line in fh:
            m = pat.match(line)
            if m:
                return True, int(m.group(1)) - int(m.group(2)) + 1
    return False, 0


def golden_output_reads(path):
    """Confirm io_perf_5_value reads trueCommitCnt_r through retireCounter_probe."""
    txt = open(path).read()
    reads_probe = bool(re.search(r'io_perf_5_value_REG\s*<=\s*retireCounter_probe', txt))
    probe_reads_tcc = bool(re.search(r'retireCounter_probe\s*=[^;]*trueCommitCnt_r', txt, re.S))
    out_reads_reg = bool(re.search(r'assign\s+io_perf_5_value\s*=\s*io_perf_5_value_REG_1', txt))
    return reads_probe and probe_reads_tcc and out_reads_reg


def impl_reg_present(path):
    """True + width if `logic [hi:lo] trueCommitCnt_r;` is declared in impl core."""
    pat = re.compile(r'^\s*logic\s+\[(\d+):(\d+)\]\s+trueCommitCnt_r\s*;')
    with open(path) as fh:
        for line in fh:
            m = pat.match(line)
            if m:
                return True, int(m.group(1)) - int(m.group(2)) + 1
    return False, 0


def impl_output_reads(path):
    """Confirm impl o_perf_5_value reads trueCommitCnt_r via retireCounter->p5r->p5r1."""
    txt = open(path).read()
    rc_reads = bool(re.search(r'retireCounter\s*=[^;]*trueCommitCnt_r', txt, re.S))
    p5_reads_rc = bool(re.search(r'p5r\s*<=\s*retireCounter', txt))
    out_reads = bool(re.search(r'o_perf_5_value\s*=\s*p5r1', txt))
    return rc_reads and p5_reads_rc and out_reads


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", default="Rob")
    ap.add_argument("--impl-prefix", default="u_core")
    ap.add_argument("--reduced-golden", required=True,
                    help="cone-reduced golden Rob (must retain trueCommitCnt_r + io_perf_5_value)")
    ap.add_argument("--impl-core", required=True,
                    help="impl rtl/backend/Rob.sv (xs_Rob_core; declares trueCommitCnt_r)")
    ap.add_argument("--out", required=True, help="output dir")
    a = ap.parse_args()

    errors = []

    g_ok, g_w = golden_reg_present(a.reduced_golden)
    if not g_ok:
        errors.append(f"MISSING golden reg trueCommitCnt_r in reduced golden {a.reduced_golden} "
                      "(cone did not retain the counter -> partition would NOT verify it)")
    elif g_w != WIDTH:
        errors.append(f"golden trueCommitCnt_r width {g_w} != expected {WIDTH}")

    g_read = golden_output_reads(a.reduced_golden)
    if not g_read:
        errors.append("golden io_perf_5_value does NOT read trueCommitCnt_r via "
                      "retireCounter_probe (counter would be UNREAD -> not verified)")

    i_ok, i_w = impl_reg_present(a.impl_core)
    if not i_ok:
        errors.append(f"MISSING impl logic trueCommitCnt_r in {a.impl_core}")
    elif i_w != WIDTH:
        errors.append(f"impl trueCommitCnt_r width {i_w} != expected {WIDTH}")

    i_read = impl_output_reads(a.impl_core)
    if not i_read:
        errors.append("impl o_perf_5_value does NOT read trueCommitCnt_r via "
                      "retireCounter->p5r->p5r1")

    golden_reg = f"r:/WORK/{a.top}/trueCommitCnt_r_reg"
    impl_reg = f"i:/WORK/{a.top}/{a.impl_prefix}/trueCommitCnt_r_reg"

    os.makedirs(a.out, exist_ok=True)
    body = f"{golden_reg}|{impl_reg}|width={WIDTH}|automatch"
    root = hashlib.sha256(body.encode()).hexdigest()

    manifest = {
        "generator": "gen_truecommitcnt_inventory.py",
        "top": a.top,
        "partition": "truecommitcnt",
        "purpose": "make the 10-bit commit counter trueCommitCnt_r an FM-VERIFIED "
                   "(read) compare point via io_perf_5_value; FM decides golden==impl.",
        "counter_width": WIDTH,
        "golden_reg": golden_reg,
        "impl_reg": impl_reg,
        "match_mechanism": "AUTO-MATCH (identical leaf name trueCommitCnt_r_reg on "
                           "both sides) — NO set_user_match / NO pin emitted.",
        "pinned": False,
        "read_by_output": "io_perf_5_value",
        "golden_read_path": "io_perf_5_value = io_perf_5_value_REG_1[5:0]; "
                            "io_perf_5_value_REG <= retireCounter_probe = "
                            "isCommitReg_last_REG ? (trueCommitCnt_r + fuseCommitCnt) : 0",
        "impl_read_path": "o_perf_5_value = p5r1[5:0]; p5r1<=p5r; p5r<=retireCounter = "
                          "isCommitReg_last ? (trueCommitCnt_r + fuseCommitCnt) : 0",
        "golden_reg_present": g_ok, "golden_reg_width": g_w, "golden_output_reads": g_read,
        "impl_reg_present": i_ok, "impl_reg_width": i_w, "impl_output_reads": i_read,
        "no_dont_verify": True,
        "no_ref_constraint": True,
        "no_blackbox_added": True,
        "no_set_user_match_for_counter": True,
        "ready_ok": len(errors) == 0,
        "errors": errors,
        "inventory_root_sha256": root,
    }
    with open(f"{a.out}/truecommitcnt_inventory.json", "w") as fh:
        json.dump(manifest, fh, indent=2)

    with open(f"{a.out}/truecommitcnt_inventory.txt", "w") as fh:
        fh.write("# trueCommitCnt (codex 0118) — golden<->impl reg inventory (AUTO-MATCH, NO PIN)\n")
        fh.write(f"# golden : {golden_reg}   [width {g_w}]\n")
        fh.write(f"# impl   : {impl_reg}   [width {i_w}]\n")
        fh.write(f"# read by: io_perf_5_value  (golden_reads={g_read} impl_reads={i_read})\n")
        fh.write(f"# match  : auto-match by identical leaf name 'trueCommitCnt_r_reg' — NOT pinned\n")
        fh.write(f"# ready  : {'OK' if not errors else 'ERRORS'}\n")

    print(f"[truecommitcnt-inv] golden={golden_reg} (w={g_w},present={g_ok},read={g_read}) "
          f"impl={impl_reg} (w={i_w},present={i_ok},read={i_read}) "
          f"pinned=False ready_ok={manifest['ready_ok']} root={root[:12]}")
    if errors:
        for e in errors:
            print("  ", e)
        sys.exit(2)


if __name__ == "__main__":
    main()
