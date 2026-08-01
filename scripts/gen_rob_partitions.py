#!/usr/bin/env python3
"""Route B (codex 0094 §4): mechanically split Rob authored outputs into 5
mutually-exclusive output-cone partitions. Each partition = a wrapper module
(module name Rob_p<Fam>) that instantiates the underlying `Rob` and exposes ONLY
that family's outputs; all other Rob outputs are left off-surface (floating).
Input全集一致 (all Rob inputs forwarded verbatim).

union of the 5 partitions' output sets == the full authored output set,
disjoint (no overlap) and total (no omission). Coverage list + hashes emitted.
"""
import re, sys, os, hashlib, json

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv"

def parse_ports(path):
    lines = open(path).read().split('\n')
    start = None
    for i, l in enumerate(lines):
        if re.match(r'^module Rob\(', l):
            start = i; break
    assert start is not None
    outs = []; ins = []
    i = start + 1
    while i < len(lines):
        l = lines[i]
        if re.match(r'^\);', l): break
        m = re.match(r'^\s*(output|input)\s+(?:logic\s+)?(\[[^\]]*\]\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*,?\s*$', l)
        if m:
            width = (m.group(2) or '').strip()
            name = m.group(3)
            (outs if m.group(1) == 'output' else ins).append((name, width))
        i += 1
    return outs, ins

# --- partition classifier: every output -> exactly one family ---
def classify(name):
    # 1) commit / control / head-tail
    if (name.startswith('io_commits_') or
        name.startswith('io_rabCommits_') or
        name.startswith('io_flushOut_') or
        name.startswith('io_robDeqPtr_') or
        name == 'io_headNotReady' or
        name == 'io_cpu_halt' or
        name.startswith('io_enq_') or
        name.startswith('io_wfi_')):
        return 'commit'
    # 2) exception / redirect
    if name.startswith('io_exception_'):
        return 'exception'
    # 3) perf / trace / csr / debug
    if (name.startswith('io_perf_') or
        name.startswith('io_trace_') or
        name.startswith('io_csr_') or
        name.startswith('io_debugTopDown_') or
        name.startswith('io_debugRobHead_')):
        return 'perf'
    # 4) vector exception
    if name.startswith('io_toVecExcpMod_'):
        return 'vecexcp'
    # 5) LSQ / deep entry data / diff / gpaddr / toDecode / error
    if (name.startswith('io_lsq_') or
        name.startswith('io_diffCommits_') or
        name.startswith('io_readGPAMemAddr_') or
        name.startswith('io_toDecode_') or
        name == 'io_error_0'):
        return 'lsq'
    return None  # unclassified => hard error

FAM_ORDER = ['commit', 'exception', 'perf', 'vecexcp', 'lsq']
FAM_MODULE = {
    'commit':    'Rob_pCommit',
    'exception': 'Rob_pException',
    'perf':      'Rob_pPerfTraceCsrDbg',
    'vecexcp':   'Rob_pVecExcp',
    'lsq':       'Rob_pLsqDeep',
}
FAM_DESC = {
    'commit':    'commit/control/head-tail (io_commits_*/io_rabCommits_*/io_flushOut/io_robDeqPtr/io_headNotReady/io_cpu_halt/io_enq_*/io_wfi_*)',
    'exception': 'exception/redirect (io_exception_*)',
    'perf':      'perf/trace/csr/debug (io_perf_*/io_trace_*/io_csr_*/io_debugTopDown_*/io_debugRobHead_*)',
    'vecexcp':   'vector exception (io_toVecExcpMod_*)',
    'lsq':       'LSQ/deep entry data (io_lsq_*/io_diffCommits_*/io_readGPAMemAddr_*/io_toDecode_*/io_error_0)',
}

def main():
    outs, ins = parse_ports(GOLDEN)
    outnames = [o[0] for o in outs]
    # classify
    part = {f: [] for f in FAM_ORDER}
    unclassified = []
    for name, width in outs:
        f = classify(name)
        if f is None:
            unclassified.append(name)
        else:
            part[f].append((name, width))
    if unclassified:
        print("FATAL: unclassified outputs:", unclassified, file=sys.stderr)
        sys.exit(1)

    # union/disjoint/total verification
    seen = {}
    for f in FAM_ORDER:
        for name, _ in part[f]:
            if name in seen:
                print(f"FATAL overlap: {name} in {seen[name]} and {f}", file=sys.stderr)
                sys.exit(1)
            seen[name] = f
    missing = [n for n in outnames if n not in seen]
    if missing:
        print(f"FATAL omission: {len(missing)} outputs in no partition:", missing[:10], file=sys.stderr)
        sys.exit(1)
    assert len(seen) == len(outnames) == 2343, (len(seen), len(outnames))

    outdir = os.path.dirname(os.path.abspath(__file__))
    rtldir = os.path.join(outdir, '..', 'rtl', 'backend')
    # --- emit coverage list ---
    covpath = os.path.join(outdir, '..', 'docs', 'backend', 'rob_partition_coverage.tsv')
    with open(covpath, 'w') as fh:
        fh.write("# Rob Route B (codex 0094 §4) output-cone partition coverage.\n")
        fh.write("# Each of the 2343 authored Rob outputs assigned to EXACTLY ONE partition.\n")
        fh.write("# union == full set (total), no output in >=2 partitions (disjoint).\n")
        fh.write("# columns: output_port\tpartition\tpartition_module\n")
        for name in outnames:  # golden declaration order
            f = seen[name]
            fh.write(f"{name}\t{f}\t{FAM_MODULE[f]}\n")
    # --- per-partition hash of its sorted output set ---
    hashes = {}
    for f in FAM_ORDER:
        names = sorted(n for n, _ in part[f])
        h = hashlib.sha256(('\n'.join(names) + '\n').encode()).hexdigest()
        hashes[f] = {'module': FAM_MODULE[f], 'count': len(names), 'sha256': h}
    union_sorted = sorted(outnames)
    union_hash = hashlib.sha256(('\n'.join(union_sorted) + '\n').encode()).hexdigest()
    manifest = {
        'target': 'Rob',
        'route': 'B',
        'total_authored_outputs': len(outnames),
        'union_output_sha256': union_hash,
        'partitions': hashes,
        'disjoint': True,
        'total_cover': True,
    }
    mpath = os.path.join(outdir, '..', 'docs', 'backend', 'rob_partition_manifest.json')
    json.dump(manifest, open(mpath, 'w'), indent=2)
    print("coverage:", covpath)
    print("manifest:", mpath)
    for f in FAM_ORDER:
        print(f"  {FAM_MODULE[f]:24s} {hashes[f]['count']:5d} outputs  sha={hashes[f]['sha256'][:12]}")
    print(f"  UNION {len(outnames)} outputs sha={union_hash[:12]}")

    # --- emit partition wrapper modules ---
    emit_wrappers(outs, ins, part, seen, rtldir)
    return outs, ins, part, seen


def _decl(kind, name, width):
    w = (width + ' ') if width else ''
    return f"  {kind} {w}{name}"


def emit_wrappers(outs, ins, part, seen, rtldir):
    """One SV file per partition. Module Rob_p<Fam> instantiates the underlying
    `Rob` (golden on ref side / impl wrapper on impl side — same instance name),
    forwards ALL inputs verbatim, exposes ONLY this partition's outputs as module
    ports, and ties every OTHER Rob output to an internal floating wire (off-surface).
    """
    for f in FAM_ORDER:
        mod = FAM_MODULE[f]
        fam_outs = part[f]                       # (name,width) exposed
        fam_out_names = {n for n, _ in fam_outs}
        lines = []
        lines.append(f"// AUTO-GENERATED by scripts/gen_rob_partitions.py — DO NOT EDIT")
        lines.append(f"// Rob Route B partition wrapper (codex 0094 §4).")
        lines.append(f"// Family: {FAM_DESC[f]}")
        lines.append(f"// Exposes {len(fam_outs)} of 2343 Rob outputs; all other Rob outputs off-surface (floating).")
        lines.append(f"// Inputs: full Rob input set ({len(ins)+0}) forwarded verbatim; input constraints identical to full proof.")
        lines.append(f"module {mod}(")
        port_lines = []
        # inputs first (clock/reset lead in golden order already since parsed in order)
        for name, width in ins:
            port_lines.append(_decl('input', name, width))
        for name, width in fam_outs:
            port_lines.append(_decl('output', name, width))
        lines.append(",\n".join(port_lines))
        lines.append(");")
        lines.append("")
        # internal floating wires for every non-family output
        lines.append("  // off-surface Rob outputs (not part of this partition) — left floating")
        for name, width in outs:
            if name in fam_out_names:
                continue
            w = (width + ' ') if width else ''
            lines.append(f"  wire {w}_unused_{name};")
        lines.append("")
        # instantiate underlying Rob by name-based connection
        lines.append("  Rob u_rob (")
        conns = []
        for name, _ in ins:
            conns.append(f"    .{name}({name})")
        for name, _ in outs:
            if name in fam_out_names:
                conns.append(f"    .{name}({name})")
            else:
                conns.append(f"    .{name}(_unused_{name})")
        lines.append(",\n".join(conns))
        lines.append("  );")
        lines.append("")
        lines.append("endmodule")
        lines.append("")
        path = os.path.join(rtldir, mod + "_part.sv")
        open(path, 'w').write("\n".join(lines))
        print(f"  wrote {path} ({len(fam_outs)} outputs, {len(outs)-len(fam_outs)} floated)")


if __name__ == '__main__':
    main()
