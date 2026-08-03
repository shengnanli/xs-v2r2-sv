#!/usr/bin/env python3
"""Freeze Rob SoA field inventory: parse golden Rob.sv reg decls (entry 0 canonical)
   + impl rob_entry_t struct. Confirm 25 impl-stored + 2 golden-only DPI sink,
   and that the 4 groups partition the 25 impl-stored fields exactly (no dup/gap).
   Emit root hash."""
import re, hashlib, json, sys

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv"
IMPL   = "/tmp/rob-soa-integ/rtl/backend/Rob.sv"
ROB_SIZE = 160

# ---- 1. golden reg decls for entry 0 (canonical field set + widths) ----
pat = re.compile(r'^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?robEntries_0_([A-Za-z_][A-Za-z_0-9]*)\s*;')
golden = {}
with open(GOLDEN) as fh:
    for line in fh:
        m = pat.match(line)
        if not m: continue
        hi, lo, field = m.groups()
        w = 1 if hi is None else (int(hi)-int(lo)+1)
        golden[field] = w

# golden-only DPI sinks (debug_ldest/debug_pdest): declared reg in golden but
# impl does not store (fed only to DiffTest DPI, cone-dead in impl).
GOLDEN_ONLY = {"debug_ldest", "debug_pdest"}

impl_stored = {f: w for f, w in golden.items() if f not in GOLDEN_ONLY}

# ---- 2. group assignment (given by integrator, codex 0104) ----
# golden field names (as they appear in golden Rob.sv reg decls)
GROUPS = {
  "G1_lifecycle_control_status": [
    "valid","stdWritebacked","needFlush","interrupt_safe","mmio","isRVC",
    "isVset","isHls","uopNum","realDestSize","instrSize","commitType"],
  "G2_pointers_indices": [
    "ftqIdx_flag","ftqIdx_value","ftqOffset"],
  "G3_exception_vector": [
    "vls","vxsat","dirtyVs","wflags","fflags","rfWen","fpWen"],
  "G4_trace_perf_deep": [
    "traceBlockInPipe_itype","traceBlockInPipe_iretire","traceBlockInPipe_ilastsize"],
}

# ---- 3. audit: partition of 25 impl-stored fields, no dup/gap ----
errors = []
all_grouped = []
for g, fields in GROUPS.items():
    for f in fields:
        all_grouped.append(f)
        if f not in impl_stored:
            errors.append(f"GROUP {g} field '{f}' NOT in impl-stored golden regs")

# duplicates across groups
seen = {}
for g, fields in GROUPS.items():
    for f in fields:
        if f in seen:
            errors.append(f"DUP field '{f}' in {seen[f]} and {g}")
        seen[f] = g

# gaps: impl-stored fields not assigned to any group
for f in impl_stored:
    if f not in seen:
        errors.append(f"GAP impl-stored field '{f}' not in any group")

grouped_count = len(all_grouped)
if grouped_count != 25:
    errors.append(f"GROUP total = {grouped_count} != 25")
if len(impl_stored) != 25:
    errors.append(f"impl-stored count = {len(impl_stored)} != 25")

# ---- 4. bit totals ----
impl_bits = sum(impl_stored.values())
golden_bits = sum(golden.values())
gonly_bits = sum(golden[f] for f in GOLDEN_ONLY)

# ---- 5. canonical root hash (sorted field|width, impl-stored only) ----
body = "\n".join(f"{f}|{impl_stored[f]}" for f in sorted(impl_stored))
root = hashlib.sha256(body.encode()).hexdigest()

# group-level hash (field|width|group)
gbody = "\n".join(f"{f}|{impl_stored[f]}|{seen.get(f,'?')}" for f in sorted(impl_stored))
groot = hashlib.sha256(gbody.encode()).hexdigest()

out = {
  "golden_src": GOLDEN,
  "rob_size": ROB_SIZE,
  "golden_reg_fields_total": len(golden),
  "golden_only_dpi_sink": sorted(GOLDEN_ONLY),
  "golden_only_bits_per_entry": gonly_bits,
  "impl_stored_field_count": len(impl_stored),
  "impl_stored_bits_per_entry": impl_bits,
  "impl_stored_reg_bits_x160": impl_bits*ROB_SIZE,
  "golden_bits_per_entry_all27": golden_bits,
  "groups": {g: [{"field": f, "width": impl_stored.get(f,'?')} for f in fs]
             for g, fs in GROUPS.items()},
  "group_field_counts": {g: len(fs) for g, fs in GROUPS.items()},
  "partition_ok": len(errors) == 0,
  "errors": errors,
  "field_inventory_root_sha256": root,
  "field_inventory_group_root_sha256": groot,
  "impl_stored_fields_sorted": {f: impl_stored[f] for f in sorted(impl_stored)},
}
print(json.dumps(out, indent=2))
if errors:
    print("\n!!! AUDIT ERRORS !!!", file=sys.stderr)
    for e in errors: print("  "+e, file=sys.stderr)
    sys.exit(2)
