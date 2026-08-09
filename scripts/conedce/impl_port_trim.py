#!/usr/bin/env python3
"""
impl_port_trim.py — produce the impl-side cone-DCE derivative for a Rob partition.

The impl top (`Rob_wrapper.sv`, module `Rob`) is a THIN glue shell around the
compact readable core `xs_Rob_core u_core (.*)` plus the same 7 official-PASS
golden leaves. Its own register population is already small (the deep state lives
in u_core's `rob_entries[160]` struct + leaves — no golden-style flattened
`debug_microOp`/`dt_exuDebug` arrays). So the impl side needs only its OUTPUT
PORT SURFACE trimmed to the partition family (to mirror the reduced golden's
surface); the internal logic stays intact and both-side-elaborated.

This transform is trivially sound: removing OUTPUT ports never changes the
behaviour of the outputs that remain. No logic, no register, no leaf is dropped;
no dont_verify / assumption / blackbox / constant is introduced. The 7 child
leaf instances remain (RenameBuffer/VTypeBuffer/SnapshotGenerator_3/ExceptionGen/
NewRobDeqPtrWrapper/RobEnqPtrWrapper + difftest chain) exactly as in the full
impl — FM keeps the same official child boundaries.

We keep ALL input ports (identical input surface = identical constraints as the
full proof) and only the family's output ports; off-family output ports become
plain internal `wire`s (their drivers stay, harmless unused nets).

USAGE
  impl_port_trim.py --src Rob_wrapper.sv --outputs <fam.txt> --out <reduced_impl.sv>
"""
import argparse, hashlib, re, sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True)
    ap.add_argument('--module', default='Rob')
    ap.add_argument('--outputs', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--report', default=None)
    args = ap.parse_args()

    raw = open(args.src).read().split('\n')
    wanted = set(l.strip() for l in open(args.outputs) if l.strip() and not l.startswith('#'))

    # locate module header
    mstart = None
    for i, l in enumerate(raw):
        if re.match(r'^\s*module\s+' + re.escape(args.module) + r'\s*\(', l):
            mstart = i
            break
    assert mstart is not None, "module header not found"
    hend = None
    for i in range(mstart, len(raw)):
        if re.match(r'^\s*\);\s*$', raw[i]):
            hend = i
            break
    assert hend is not None

    # walk port lines; drop off-family output ports, collect them to re-declare
    # as internal wires (so their drivers remain legal).
    out = list(raw[:mstart + 1])  # up to and including 'module Rob('
    demoted = []   # (width_str, name) of dropped output ports
    port_lines = []
    for j in range(mstart + 1, hend):
        c = raw[j]
        m = re.match(r'^\s*(input|output|inout)\b(\s*\[[^\]]*\])?\s+([A-Za-z_][A-Za-z0-9_$]*)\s*,?\s*$', c)
        if m and m.group(1) == 'output':
            name = m.group(3)
            if name not in wanted:
                width = (m.group(2) or '').strip()
                demoted.append((width, name))
                continue
        port_lines.append(c)
    # strip trailing comma on last kept port line
    for k in range(len(port_lines) - 1, -1, -1):
        s = port_lines[k]
        if re.search(r'[A-Za-z0-9_$\]]\s*,\s*$', s):
            port_lines[k] = re.sub(r',(\s*)$', r'\1', s, count=1)
            break
        if re.search(r'[A-Za-z0-9_$\]]\s*$', s):
            break
    out.extend(port_lines)
    out.append(raw[hend])  # ');'

    # re-declare demoted output ports as internal wires right after the header
    if demoted:
        out.append('  // cone-DCE: off-family outputs demoted to internal wires '
                   '(drivers preserved, ports removed)')
        for width, name in demoted:
            w = (' ' + width + ' ') if width else ' '
            out.append(f'  wire{w}{name};')

    # rest of the module body verbatim
    out.extend(raw[hend + 1:])

    text = '\n'.join(out)
    open(args.out, 'w').write(text)

    if args.report:
        import json
        rep = dict(module=args.module,
                   src_sha256=hashlib.sha256('\n'.join(raw).encode()).hexdigest(),
                   out_sha256=hashlib.sha256(text.encode()).hexdigest(),
                   kept_outputs=len(wanted),
                   demoted_outputs=len(demoted),
                   out_lines=len(out), src_lines=len(raw))
        json.dump(rep, open(args.report, 'w'), indent=2)
    print(f"[impl-trim] {args.out}: kept {len(wanted)} outs, demoted {len(demoted)}, "
          f"{len(out)} lines")


if __name__ == '__main__':
    main()
