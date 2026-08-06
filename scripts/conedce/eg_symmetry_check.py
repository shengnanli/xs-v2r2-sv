#!/usr/bin/env python3
"""
eg_symmetry_check.py — ExceptionGen fanin SYMMETRY + COMPLETENESS verdict for a
cone-DCE Rob partition (codex 0116-B).

Consumes the two machine-readable inventories produced by eg_fanin_inventory.py
(reduced-golden ref side vs reduced-impl side) and additionally recomputes, from
the FULL golden Rob, the ExceptionGen io_flush fanin cone, to prove the reduced
golden preserved it COMPLETELY (no cone-slicer over-removal).

Verdict fields (all machine-readable, hashes in the inventories):
  eg_instances_symmetric          same kept EG instance set both sides
  eg_input_pins_identical         same 319 EG input-pin surface both sides
  eg_input_pinmap_diffs_excluding_known_flush_rename
                                  per-pin net-binding diffs, minus the single
                                  known wrapper rename io_flush:
                                  io_flushOut_valid_0 (golden flat wire) ==
                                  o_flushOut_valid (impl u_core output; wrapper
                                  does assign io_flushOut_valid=o_flushOut_valid
                                  and o_eg_flush=o_flushOut_valid) => same signal.
  golden_cone_complete            reduced-golden EG-flush fanin cone == full
                                  golden EG-flush fanin cone (0 nets/regs missing)
  SYMMETRIC_AND_COMPLETE          AND of the above

If SYMMETRIC_AND_COMPLETE is true, the residual exceptionGen/s0_out compare
points are NOT a cone-slicer artifact — the slicer keeps ExceptionGen whole with
its complete, symmetric input fanin — and any remaining value diff is a genuine
golden<->u_core equivalence question inside the flush/canAccept cone (codex
requirement #3: submit as counterexample, do NOT modify the slicer, do NOT pin).

USAGE
  eg_symmetry_check.py --ref <inventory_ref.json> --impl <inventory_impl.json>
       --full-golden <full Rob.sv> --reduced-golden <Rob_golden_perf.sv>
       --out <verdict.json>
"""
import argparse, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rob_cone_slicer import FlatModule, load_child_pin_dirs

FLUSH_RENAME = ("io_flushOut_valid_0", "o_flushOut_valid")


def eg_flush_cone(src, eg_mod="ExceptionGen"):
    """Transitive fanin cone (nets, regs) of the ExceptionGen io_flush pin's
    parent net, using the locked slicer parser."""
    dirs_for = load_child_pin_dirs()
    raw = open(src).read().split('\n')
    fm = FlatModule(raw, "Rob")
    driver_map = {}
    reg_to_always = {}
    au = []

    def add(n, u):
        driver_map.setdefault(n, []).append(u)

    root = None
    for uidx, u in enumerate(fm.units):
        k = u['kind']
        if k in ('wire_assign', 'assign'):
            for l in u['lhs']:
                add(l, uidx)
        elif k == 'always':
            au.append(uidx)
            for r in u['lhs']:
                reg_to_always.setdefault(r, []).append(uidx)
        elif k == 'instance':
            po, pi = dirs_for(u['modname'])
            outs, ins = set(), set()
            for pin, nets in u['conns']:
                if pin in po:
                    outs |= set(nets)
                elif pin in pi:
                    ins |= set(nets)
                else:
                    outs |= set(nets); ins |= set(nets)
            u['_ins'] = ins
            for n in outs:
                add(n, uidx)
            if u['modname'] == eg_mod:
                for pin, nets in u['conns']:
                    if pin == 'io_flush' and nets:
                        root = nets[0]
    assert root is not None, "ExceptionGen io_flush root not found in " + src
    in_cone = set()
    keep = set()
    wl = [root]
    seen = {root}
    bcr = {u: set() for u in au}
    dirty = set()

    def push(n):
        if n not in seen:
            seen.add(n); wl.append(n)

    while True:
        while wl:
            net = wl.pop()
            in_cone.add(net)
            for uidx in driver_map.get(net, ()):
                if uidx in keep:
                    continue
                keep.add(uidx)
                u = fm.units[uidx]
                if u['kind'] in ('wire_assign', 'assign'):
                    for r in u['rhs']:
                        push(r)
                elif u['kind'] == 'instance':
                    for r in u.get('_ins', ()):
                        push(r)
            for uidx in reg_to_always.get(net, ()):
                if net not in bcr[uidx]:
                    bcr[uidx].add(net); dirty.add(uidx)
        if not dirty:
            break
        du = dirty.pop()
        for r in fm.units[du]['ab'].fanin_for(bcr[du]):
            push(r)
    regs = {r for u in bcr for r in bcr[u]}
    return root, in_cone, regs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ref', required=True)
    ap.add_argument('--impl', required=True)
    ap.add_argument('--full-golden', required=True)
    ap.add_argument('--reduced-golden', required=True)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()

    ref = json.load(open(args.ref))
    imp = json.load(open(args.impl))

    rpm, ipm = ref["eg_input_pinmap"], imp["eg_input_pinmap"]
    pin_diffs = []
    for p in sorted(set(rpm) | set(ipm)):
        rv, iv = rpm.get(p), ipm.get(p)
        if rv != iv:
            if p == "io_flush" and rv == [FLUSH_RENAME[0]] and iv == [FLUSH_RENAME[1]]:
                continue
            pin_diffs.append(dict(pin=p, ref=rv, impl=iv))

    _, full_nets, full_regs = eg_flush_cone(args.full_golden)
    _, red_nets, red_regs = eg_flush_cone(args.reduced_golden)

    v = dict(
        partition="perf",
        eg_instances_symmetric=ref["eg_instances"] == imp["eg_instances"],
        eg_instances=ref["eg_instances"],
        eg_input_pins_identical=ref["eg_input_pins"] == imp["eg_input_pins"],
        eg_input_pin_count=ref["eg_input_pins_count"],
        eg_input_pinmap_diffs_excluding_known_flush_rename=pin_diffs,
        known_flush_rename=dict(pin="io_flush", ref=FLUSH_RENAME[0], impl=FLUSH_RENAME[1]),
        golden_flush_cone_full_nets=len(full_nets),
        golden_flush_cone_reduced_nets=len(red_nets),
        golden_flush_cone_nets_missing_from_reduced=sorted(full_nets - red_nets),
        golden_flush_cone_full_regs=len(full_regs),
        golden_flush_cone_reduced_regs=len(red_regs),
        golden_flush_cone_regs_missing_from_reduced=sorted(full_regs - red_regs),
        golden_cone_complete=(full_nets == red_nets and full_regs == red_regs),
        impl_flat_fanin_nets=imp["fanin_nets_count"],
        impl_flat_fanin_regs=imp["fanin_regs_count"],
        impl_flat_note=("impl EG inputs bind to Rob primary inputs + canEnqueueEG "
                        "+ o_flushOut_valid; o_flushOut_valid is xs_Rob_core "
                        "u_core (.*) OUTPUT -> its driver cone lives INSIDE "
                        "u_core (both-side-elaborated by FM), invisible to the "
                        "flat net parser. This flat-count asymmetry is the golden-"
                        "flat vs impl-u_core-hidden representation, NOT a cone-"
                        "slicer trim."),
    )
    v["SYMMETRIC_AND_COMPLETE"] = (
        v["eg_instances_symmetric"] and v["eg_input_pins_identical"]
        and not pin_diffs and v["golden_cone_complete"])
    json.dump(v, open(args.out, "w"), indent=2)
    print(json.dumps(v, indent=2))


if __name__ == '__main__':
    main()
