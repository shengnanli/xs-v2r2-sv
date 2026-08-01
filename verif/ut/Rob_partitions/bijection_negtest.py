#!/usr/bin/env python3
# Negative tests for gen_rob_fieldmap bijection self-check.
# We import the generator module and mutate its IMPL_FIELDS to prove that
# a SWAPPED pin (two fields exchange widths -> overlap/gap) and a DROPPED
# pin (a field removed -> golden-only unexpected + coverage gap) both make
# bijection_ok=False (i.e. the self-check catches them, so it is a real gate).
import importlib.util, sys, copy, os, json, tempfile
_HERE = os.path.dirname(os.path.abspath(__file__))
_GEN = os.path.normpath(os.path.join(_HERE, "..", "..", "..", "scripts", "gen_rob_fieldmap.py"))
spec = importlib.util.spec_from_file_location("genfm", _GEN)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

G = "/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv"
ORIG = copy.deepcopy(mod.IMPL_FIELDS)

def run_check(fields, label):
    mod.IMPL_FIELDS = fields
    layout, W = mod.compute_layout()
    golden = mod.parse_golden(G)
    errors = []
    mapped = set()
    impl_hits = {}; gold_hits = {}
    for N in range(mod.ROB_SIZE):
        for impl_f, gold_suf, w, lo, hi in layout:
            key = (N, gold_suf)
            if key not in golden:
                errors.append(f"MISSING golden reg robEntries_{N}_{gold_suf}"); continue
            if golden[key] != w:
                errors.append(f"WIDTH MISMATCH {gold_suf}: g={golden[key]} i={w}")
            mapped.add(key)
            for b in range(w):
                impl_hits[(N,lo+b)] = impl_hits.get((N,lo+b),0)+1
                gold_hits[(N,gold_suf,b)] = gold_hits.get((N,gold_suf,b),0)+1
    for (N,suf),gw in golden.items():
        if (N,suf) not in mapped and suf not in mod.GOLDEN_ONLY:
            errors.append(f"UNEXPECTED unmapped golden robEntries_{N}_{suf}")
    for k,c in impl_hits.items():
        if c!=1: errors.append(f"IMPL bit reused {k} x{c}")
    for k,c in gold_hits.items():
        if c!=1: errors.append(f"GOLD bit reused {k} x{c}")
    for N in range(mod.ROB_SIZE):
        cov = sorted(b for (nn,b) in impl_hits if nn==N)
        if cov != list(range(W)): errors.append(f"IMPL entry {N} coverage gap")
    ok = len(errors)==0
    print(f"[{label}] bijection_ok={ok}  n_errors={len(errors)}  sample={errors[:2]}")
    return ok

# 0) baseline (unmutated) must PASS
b0 = run_check(copy.deepcopy(ORIG), "BASELINE")

# 1) SWAP two golden suffixes between adjacent fields -> width mismatch / bit reuse
#    swap uop_num(7,uopNum) golden-suffix with real_dest_size(7,realDestSize):
#    same widths so bit-slice ok, but golden suffix swapped => the mapped golden
#    key changes; check a genuinely detectable swap = swap uopNum<->fflags (7 vs 5).
mut1 = copy.deepcopy(ORIG)
# indices: find uop_num and fflags
i_uop = next(i for i,f in enumerate(mut1) if f[0]=="uop_num")
i_ff  = next(i for i,f in enumerate(mut1) if f[0]=="fflags")
# swap golden suffix only (keep impl width) -> width mismatch golden 7 vs impl slice
a=mut1[i_uop]; b=mut1[i_ff]
mut1[i_uop]=(a[0],a[1],a[2],b[2])  # nonsense tuple guard; instead do proper swap of gold suffix
# proper: swap the golden_suffix strings
mut1 = copy.deepcopy(ORIG)
au=list(mut1[i_uop]); af=list(mut1[i_ff])
au[2], af[2] = af[2], au[2]  # swap golden suffixes (uopNum<->fflags)
mut1[i_uop]=tuple(au); mut1[i_ff]=tuple(af)
b1 = run_check(mut1, "SWAP-suffix uopNum<->fflags (width 7 vs 5)")

# 2) SWAP two SAME-width golden suffixes: uopNum(7) <-> realDestSize(7)
#    widths match so no width error, but the map now pins golden uopNum bits to
#    the realDestSize impl slice and vice versa -> a genuine wrong pin. The
#    self-check catches it only if it changes coverage; same width same slice =>
#    self-check alone can't (bijection still holds structurally). This proves the
#    self-check gates STRUCTURE, and semantic swaps need the FM verify (documented).
mut2 = copy.deepcopy(ORIG)
i_rd = next(i for i,f in enumerate(mut2) if f[0]=="real_dest_size")
au=list(mut2[i_uop]); ar=list(mut2[i_rd])
au[2], ar[2] = ar[2], au[2]
mut2[i_uop]=tuple(au); mut2[i_rd]=tuple(ar)
b2 = run_check(mut2, "SWAP-suffix uopNum<->realDestSize (both width 7)")

# 3) DROP a field (remove valid) -> golden robEntries_N_valid unmapped+unexpected + coverage gap
mut3 = [f for f in copy.deepcopy(ORIG) if f[0]!="need_flush"]
b3 = run_check(mut3, "DROP need_flush field")

print("\n=== NEGATIVE TEST VERDICT ===")
print(f"baseline PASS               : {b0}  (expect True)")
print(f"swap diff-width caught      : {not b1}  (expect True)")
print(f"swap same-width struct-caught: {not b2}  (structural self-check; expect False=needs FM semantic verify)")
print(f"drop field caught           : {not b3}  (expect True)")
sys.exit(0 if (b0 and (not b1) and (not b3)) else 1)
