#!/usr/bin/env python3
"""
eg_fanin_inventory.py — machine-readable ExceptionGen (or any leaf) FANIN
inventory for a cone-DCE Rob partition derivative (codex 0116-B).

WHY
---
The perf-partition FM residual is a handful of `exceptionGen/s0_out_*` compare
points. ExceptionGen is a both-side-elaborated LEAF instance; its s0_out regs
are `RegNext` of the enq/wb inputs gated by `lastCycleFlush <= io_flush`. So any
s0_out value diff must come from a difference in the PARENT-level nets feeding
ExceptionGen's input pins — i.e. its fanin. This tool produces, for one side
(reduced-golden ref OR reduced-impl), the machine-readable fanin inventory so the
two sides can be compared item-by-item:

  (a) reachable ExceptionGen output/instance set              -> eg_instances
  (b) every reachable ExceptionGen INPUT pin -> parent net     -> eg_input_pinmap
      and the set of parent nets feeding those pins            -> eg_input_roots
  (c) transitive FANIN driver closure of those roots down to
      primary inputs / register boundaries (drivers only, NOT
      consumers/fanout)                                        -> fanin_nets /
                                                                  fanin_regs /
                                                                  driver_cells

Each collection is emitted with a sha256 so both sides compare by hash. FANIN
ONLY: we follow upstream drivers (assign RHS, instance input pins, reg next-state
via always_tree). consumer-count / fanout is deliberately NOT computed.

The structural parse reuses the LOCKED cone-slicer (rob_cone_slicer.FlatModule +
always_tree.AlwaysBlock) so the fanin rule is byte-identical to the slicer's own
cone rule. Pure function of the input .sv bytes => deterministic.

USAGE
  eg_fanin_inventory.py --src <reduced.sv> [--module Rob] [--eg-mod ExceptionGen]
                        --out <inventory.json>
  # side files: <out>.fanin_nets.txt / .driver_cells.txt / .input_roots.txt
"""
import argparse, hashlib, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rob_cone_slicer import FlatModule, load_child_pin_dirs


def sha_set(s):
    return hashlib.sha256("\n".join(sorted(s)).encode()).hexdigest()


def build(src, module, eg_mod):
    raw = open(src).read().split('\n')
    fm = FlatModule(raw, module)
    dirs_for = load_child_pin_dirs()
    po_eg, pi_eg = dirs_for(eg_mod)

    # (a)/(b): kept ExceptionGen instances + their input-pin -> parent-net map
    eg_insts = []
    eg_input_roots = set()
    eg_input_pinmap = {}
    for u in fm.units:
        if u['kind'] == 'instance' and u['modname'] == eg_mod:
            eg_insts.append(u['instname'])
            for pin, nets in u['conns']:
                is_out = pin in po_eg
                if not is_out:                      # input or inout/unknown = fanin
                    eg_input_pinmap[pin] = sorted(set(nets))
                    eg_input_roots |= set(nets)

    # driver map (fanin only), exactly like compute_cone
    driver_map = {}
    reg_to_always = {}
    always_units = []

    def add(net, uidx):
        driver_map.setdefault(net, []).append(uidx)

    for uidx, u in enumerate(fm.units):
        k = u['kind']
        if k in ('wire_assign', 'assign'):
            for lhs in u['lhs']:
                add(lhs, uidx)
        elif k == 'always':
            always_units.append(uidx)
            for reg in u['lhs']:
                reg_to_always.setdefault(reg, []).append(uidx)
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
            u['_inst_ins'] = ins
            for net in outs:
                add(net, uidx)

    # BFS fanin closure of eg_input_roots
    in_cone = set()
    keep = set()
    wl = list(eg_input_roots)
    seen = set(wl)
    bcr = {u: set() for u in always_units}
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
                    for r in u.get('_inst_ins', ()):
                        push(r)
            for uidx in reg_to_always.get(net, ()):
                if net not in bcr[uidx]:
                    bcr[uidx].add(net); dirty.add(uidx)
        if not dirty:
            break
        du = dirty.pop()
        for r in fm.units[du]['ab'].fanin_for(bcr[du]):
            push(r)

    # driver-cell signatures (canonical, side-comparable)
    cells = []
    for uidx in sorted(keep):
        u = fm.units[uidx]
        if u['kind'] in ('wire_assign', 'assign'):
            cells.append("assign:" + ",".join(sorted(u['lhs'])))
        elif u['kind'] == 'instance':
            cells.append("inst:%s:%s" % (u['modname'], u['instname']))
    for uidx in sorted(bcr):
        for r in sorted(bcr[uidx]):
            cells.append("reg:" + r)
    cells = sorted(set(cells))
    fanin_regs = sorted({r for u in bcr for r in bcr[u]})

    result = dict(
        src=os.path.basename(src),
        module=module,
        eg_module=eg_mod,
        eg_instances=sorted(eg_insts),
        eg_instances_sha=sha_set(eg_insts),
        eg_input_pins=sorted(eg_input_pinmap.keys()),
        eg_input_pins_count=len(eg_input_pinmap),
        eg_input_pinmap=dict(sorted(eg_input_pinmap.items())),
        eg_input_pinmap_sha=hashlib.sha256(
            json.dumps(dict(sorted(eg_input_pinmap.items())), sort_keys=True).encode()).hexdigest(),
        eg_input_roots=sorted(eg_input_roots),
        eg_input_roots_sha=sha_set(eg_input_roots),
        fanin_nets_count=len(in_cone),
        fanin_nets_sha=sha_set(in_cone),
        fanin_regs=fanin_regs,
        fanin_regs_count=len(fanin_regs),
        fanin_regs_sha=sha_set(fanin_regs),
        driver_cells_count=len(cells),
        driver_cells_sha=sha_set(cells),
    )
    return result, sorted(in_cone), cells, sorted(eg_input_roots)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True)
    ap.add_argument('--module', default='Rob')
    ap.add_argument('--eg-mod', default='ExceptionGen')
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    result, nets, cells, roots = build(args.src, args.module, args.eg_mod)
    open(args.out + ".fanin_nets.txt", "w").write("\n".join(nets) + "\n")
    open(args.out + ".driver_cells.txt", "w").write("\n".join(cells) + "\n")
    open(args.out + ".input_roots.txt", "w").write("\n".join(roots) + "\n")
    json.dump(result, open(args.out, "w"), indent=2)
    print(json.dumps({k: v for k, v in result.items()
                      if k.endswith("_sha") or k.endswith("_count")
                      or k == "eg_instances"}, indent=2))


if __name__ == '__main__':
    main()
