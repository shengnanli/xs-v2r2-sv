#!/usr/bin/env python3
"""Golden field name <-> impl rob_entry_t struct field name bijection map.
   Confirms every golden impl-stored field maps to exactly one impl struct field
   with matching width (flagging the ilastsize 1b-vs-2b nuance)."""
import re, json, sys

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv"
PKG    = "/tmp/rob-soa-integ/rtl/backend/rob_pkg.sv"

# golden field -> impl struct field name (snake_case)
NAMEMAP = {
  "valid":"valid","uopNum":"uop_num","stdWritebacked":"std_writebacked",
  "realDestSize":"real_dest_size","needFlush":"need_flush",
  "interrupt_safe":"interrupt_safe","mmio":"mmio","vls":"vls","fflags":"fflags",
  "vxsat":"vxsat","rfWen":"rf_wen","fpWen":"fp_wen","wflags":"wflags",
  "dirtyVs":"dirty_vs","commitType":"commit_type","isRVC":"is_rvc",
  "isVset":"is_vset","isHls":"is_hls","instrSize":"instr_size",
  "ftqIdx_value":"ftq_idx_value","ftqIdx_flag":"ftq_idx_flag","ftqOffset":"ftq_offset",
  "traceBlockInPipe_itype":"itype","traceBlockInPipe_iretire":"iretire",
  "traceBlockInPipe_ilastsize":"ilastsize",
}

# golden widths (entry 0)
pat = re.compile(r'^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?robEntries_0_([A-Za-z_][A-Za-z_0-9]*)\s*;')
gw = {}
for line in open(GOLDEN):
    m = pat.match(line)
    if m:
        hi,lo,f = m.groups()
        gw[f] = 1 if hi is None else int(hi)-int(lo)+1

# impl struct widths — expand params
params = {"UOP_CNT_W":7,"INSTR_SIZE_W":3,"FTQ_PTR_W":6,"FTQ_OFFSET_W":4,
          "IRETIRE_W":4,"ITYPE_W":4,"PTR_W":8}
# parse struct block
txt = open(PKG).read()
m = re.search(r'typedef struct packed \{(.*?)\} rob_entry_t;', txt, re.S)
body = m.group(1)
iw = {}
for line in body.splitlines():
    fm = re.match(r'\s*logic\s+(?:\[([^\]]+)\]\s+)?([a-z_][a-z_0-9]*)\s*;', line)
    if not fm: continue
    rng, name = fm.groups()
    if rng is None:
        w = 1
    else:
        # forms: 4:0  or  PARAM-1:0
        rng = rng.strip()
        hi, lo = rng.split(":")
        def ev(x):
            x = x.strip()
            for p,v in params.items(): x = x.replace(p, str(v))
            return eval(x)
        w = ev(hi)-ev(lo)+1
    iw[name] = w

rows = []
mism = []
for gf, impf in NAMEMAP.items():
    g = gw.get(gf); i = iw.get(impf)
    ok = (g == i)
    note = ""
    if not ok:
        note = f"WIDTH DIFF golden={g} impl_struct={i}"
        mism.append((gf, impf, g, i))
    rows.append({"golden":gf,"impl_struct":impf,"golden_w":g,"impl_struct_w":i,"width_ok":ok,"note":note})

print(json.dumps({"map":rows,"width_mismatches":mism}, indent=2))
