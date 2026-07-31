#!/usr/bin/env python3
"""Source-verified target-scoped semantic-surface for G0-StorePipe-observable-v1.

codex_0092 §1, option B.  Builds a *semantic-surface wrapper* that exposes ONLY
the 36 source-defined output leaves + the 23 inputs (the 6 perf probes are XMR
`define macros, never ports) as the FM comparison surface, and *excludes* the 14
UNSPECIFIED_BY_SOURCE (invalidate-only) output leaves.

Why a wrapper (not dont_verify, not 0-fill, not a generic exclusion knob):
  The 14 excluded leaves are `invalidate`-only in the source FIRRTL -> the source
  does NOT specify a value.  firtool lowers each `DontCare` to an arbitrary
  constant 0; an honest readable-RTL impl drives X.  Comparing 0-vs-X is a
  spurious FM FAILED.  Instead of forcing the impl to 0 (codex forbids option A)
  or waiving points with dont_verify (a proof relaxation the emitter records as a
  qualification), the surface wrapper leaves those 14 outputs UNCONNECTED at the
  top boundary -- they are genuinely off the observable surface, present in
  neither reference nor implementation as compare points.

  Two wrappers are emitted, one per side, BOTH named `StorePipe_surface`, each
  instantiating the real `StorePipe` (derivative on the ref side, readable core +
  impl wrapper on the impl side) and re-exporting only the surface ports.  FM
  sets the top to `StorePipe_surface` on both sides; the 14 undefined leaves are
  internal dangling nets.  The surface is therefore SYMMETRIC and non-vacuous:
  36 defined outputs are compared, 14 undefined are excluded by construction.

Source-binding (so a leaf that becomes source-defined is caught):
  The excluded set is RE-DERIVED from the committed `StorePipe.module.fir` by
  FIRRTL last-connect-wins and cross-checked against `observable_surface.json`.
  The port WIDTHS come from the committed derivative `StorePipe.sv` port block.
  Both wrapper files + this script are digested into the ledger; the runner
  hash-verifies them before FM.  If a leaf becomes source-`connect`-defined (or a
  name/width drifts), the derived set / widths change, the wrapper bytes change,
  and both `--check` and the runner hash gate fail-closed.

Usage:
  derive_surface.py <ledger_dir>            # (re)generate wrappers
  derive_surface.py <ledger_dir> --check    # assert committed wrappers == derived
Exit non-zero (fail-closed) on ANY drift between source, asserted surface, the
derivative port block, and the emitted/committed wrapper files.
"""
import hashlib
import json
import os
import re
import sys

MODULE = "StorePipe"
SURFACE_MODULE = "StorePipe_surface"
MODULE_FIR = "StorePipe.module.fir"
DERIVATIVE_SV = "StorePipe.sv"
SURFACE_JSON = "observable_surface.json"
REF_WRAPPER = "StorePipe_ref_surface.sv"
IMPL_WRAPPER = "StorePipe_impl_surface.sv"


# ---------------------------------------------------------------------------
# source classification: FIRRTL last-connect-wins over the module body
# ---------------------------------------------------------------------------
def firrtl_unspecified_leaves(fir_path):
    """SV leaf names (dots->underscores) that are UNSPECIFIED_BY_SOURCE."""
    ops = []
    started = False
    for ln in open(fir_path, encoding="utf-8"):
        if re.match(r"\s*module\s+%s\b" % re.escape(MODULE), ln):
            started = True
        m = re.match(r"\s*(connect|invalidate)\s+(io\.[A-Za-z0-9_.]+)", ln)
        if started and m:
            ops.append((m.group(1), m.group(2)))
    if not ops:
        raise SystemExit("SURFACE_ERROR: no io connect/invalidate ops in %s" % fir_path)
    inv_leaves = set(t for k, t in ops if k == "invalidate")

    def covered_after(leaf, idx):
        for j in range(idx + 1, len(ops)):
            k, t = ops[j]
            if k == "connect" and (t == leaf or leaf.startswith(t + ".")):
                return True
        return False

    unspec = []
    for leaf in inv_leaves:
        last_inv = max(i for i, (k, t) in enumerate(ops)
                       if t == leaf and k == "invalidate")
        if not covered_after(leaf, last_inv):
            unspec.append(leaf)
    return sorted(leaf.replace("io.", "io_").replace(".", "_") for leaf in unspec)


def surface_json(surface_path):
    return json.load(open(surface_path, encoding="utf-8"))


# ---------------------------------------------------------------------------
# derivative port block: (dir, width_decl, name) in declaration order
# ---------------------------------------------------------------------------
def derivative_ports(sv_path):
    """Parse the derivative ANSI port block.  firtool groups ports: a leading
    `<dir> [<width>] name,` line sets BOTH direction and width for the group, and
    following bare-identifier lines inherit BOTH (Verilog ANSI semantics: the
    range persists until a new range is given).  A new `<dir>` OR a new `[...]`
    starts a new width context."""
    txt = open(sv_path, encoding="utf-8").read()
    m = re.search(r"module\s+%s\s*\((.*?)\);" % re.escape(MODULE), txt, re.S)
    if not m:
        raise SystemExit("SURFACE_ERROR: cannot find %s port block" % MODULE)
    ports = []
    cur_dir = None
    cur_width = ""
    for ln in m.group(1).splitlines():
        code = ln.split("//")[0].strip().rstrip(",").strip()
        if not code:
            continue
        pm = re.match(r"(?:(input|output)\s+)?(\[[^\]]*\]\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*$", code)
        if not pm:
            continue
        # A new direction keyword OR a new explicit width resets the group width.
        if pm.group(1):
            cur_dir = pm.group(1)
            cur_width = (pm.group(2) or "").strip()
        elif pm.group(2):
            cur_width = pm.group(2).strip()
        # else: bare identifier -> inherit cur_dir and cur_width unchanged.
        if cur_dir is None:
            raise SystemExit("SURFACE_ERROR: port before any direction: %s" % code)
        ports.append((cur_dir, cur_width, pm.group(3)))
    return ports


def render_wrapper(inner_module_comment, ports, excluded):
    """Emit a StorePipe_surface wrapper.

    Surface ports = all inputs + defined outputs (every port not in `excluded`).
    Excluded outputs become internal dangling nets driven by the inner instance
    but not re-exported -> off the FM comparison surface.
    """
    surf_ports = [p for p in ports if p[2] not in excluded]
    excl_ports = [p for p in ports if p[2] in excluded]
    L = []
    L.append("// ====================================================================")
    L.append("// %s -- target-scoped semantic-surface wrapper" % SURFACE_MODULE)
    L.append("// derivative_id : G0-StorePipe-observable-v1")
    L.append("// GENERATED by derive_surface.py (FIRRTL last-connect-wins + derivative")
    L.append("// port widths).  DO NOT hand-edit: regenerate + re-hash in LEDGER.tsv.")
    L.append("//")
    L.append("// %s" % inner_module_comment)
    L.append("// Surface = %d inputs+defined-outputs re-exported; %d UNSPECIFIED_BY_SOURCE"
             % (len(surf_ports), len(excl_ports)))
    L.append("// (invalidate-only) output leaves are LEFT UNCONNECTED (off the compare")
    L.append("// surface).  Not dont_verify, not 0-fill, not a generic exclusion.")
    L.append("// ====================================================================")
    L.append("module %s (" % SURFACE_MODULE)
    body = []
    for d, w, n in surf_ports:
        body.append("  %-7s %s%s" % (d, (w + " ") if w else "", n))
    L.append(",\n".join(body))
    L.append(");")
    L.append("")
    # internal dangling nets for the excluded (source-undefined) outputs
    for d, w, n in excl_ports:
        L.append("  wire %s%s; // UNSPECIFIED_BY_SOURCE: off surface" % ((w + " ") if w else "", n))
    L.append("")
    L.append("  %s u_dut (" % MODULE)
    conns = []
    for d, w, n in ports:
        conns.append("    .%s(%s)" % (n, n))
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


def build(ledger_dir):
    fir = os.path.join(ledger_dir, MODULE_FIR)
    sv = os.path.join(ledger_dir, DERIVATIVE_SV)
    surf = os.path.join(ledger_dir, SURFACE_JSON)

    src_excluded = firrtl_unspecified_leaves(fir)
    spec = surface_json(surf)
    json_excluded = sorted(e["leaf"] for e in spec["unspecified_by_source"])
    json_defined = sorted(e["leaf"] for e in spec["defined_outputs"])

    # (1) source classification must equal the asserted surface.
    if src_excluded != json_excluded:
        print("SURFACE_ERROR: source-derived UNSPECIFIED != observable_surface.json")
        print("  source  :", src_excluded)
        print("  asserted:", json_excluded)
        only_src = sorted(set(src_excluded) - set(json_excluded))
        only_json = sorted(set(json_excluded) - set(src_excluded))
        if only_src:
            print("  source-only (leaf became invalidate-only / misclassified):", only_src)
        if only_json:
            print("  asserted-only (leaf became source-defined -> leave surface):", only_json)
        raise SystemExit(2)

    ports = derivative_ports(sv)
    port_names = set(p[2] for p in ports)
    # (2) every excluded leaf must exist as a derivative output port.
    for lf in src_excluded:
        if lf not in port_names:
            print("SURFACE_ERROR: excluded leaf not a derivative port:", lf)
            raise SystemExit(2)
    # (3) every defined output must be a re-exported (non-excluded) output port.
    out_ports = set(n for d, w, n in ports if d == "output")
    for lf in json_defined:
        if lf not in out_ports:
            print("SURFACE_ERROR: defined output missing from derivative ports:", lf)
            raise SystemExit(2)
        if lf in src_excluded:
            print("SURFACE_ERROR: leaf both defined and excluded:", lf)
            raise SystemExit(2)
    # (4) surface output count must be exactly the 36 defined outputs.
    surf_outs = out_ports - set(src_excluded)
    if len(surf_outs) != len(json_defined):
        print("SURFACE_ERROR: surface output count %d != 36 defined" % len(surf_outs))
        raise SystemExit(2)

    ref = render_wrapper(
        "REF side: instantiates the canonical derivative StorePipe (hash-pinned).",
        ports, set(src_excluded))
    impl = render_wrapper(
        "IMPL side: instantiates the readable-core impl wrapper StorePipe.",
        ports, set(src_excluded))
    return ref, impl, src_excluded, len(surf_outs)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    ledger_dir = sys.argv[1]
    check = "--check" in sys.argv[2:]
    ref, impl, excluded, n_out = build(ledger_dir)
    rp = os.path.join(ledger_dir, REF_WRAPPER)
    ip = os.path.join(ledger_dir, IMPL_WRAPPER)

    def sha(s):
        return hashlib.sha256(s.encode()).hexdigest()

    if check:
        ok = True
        for path, want in ((rp, ref), (ip, impl)):
            if not os.path.isfile(path):
                print("SURFACE_ERROR: %s not committed" % os.path.basename(path)); ok = False; continue
            got = open(path, encoding="utf-8").read()
            if got != want:
                print("SURFACE_ERROR: committed %s drifted from source-derived render"
                      % os.path.basename(path)); ok = False
        if not ok:
            sys.exit(2)
        print("SURFACE_OK: %d excluded (UNSPECIFIED_BY_SOURCE), %d surface outputs; "
              "ref_sha=%s impl_sha=%s" % (len(excluded), n_out, sha(ref)[:12], sha(impl)[:12]))
        sys.exit(0)

    open(rp, "w", encoding="utf-8").write(ref)
    open(ip, "w", encoding="utf-8").write(impl)
    print("wrote %s (%d bytes) %s (%d bytes)" % (REF_WRAPPER, len(ref), IMPL_WRAPPER, len(impl)))
    print("excluded=%d surface_outputs=%d" % (len(excluded), n_out))
    print("ref_surface_sha256=%s" % sha(ref))
    print("impl_surface_sha256=%s" % sha(impl))


if __name__ == "__main__":
    main()
