#!/usr/bin/env python3
"""Generate CSR-M wrapper blocks from the immutable G1 golden port tables.

The readable ``xs_*_core`` implementations stay hand-written; this script only
regenerates the exact wrapper declaration and named connection block.  ``--check``
performs bidirectional port-set and direction checks before detecting drift.
"""
import argparse
import os
from pathlib import Path
import re
import sys

REPO = Path(__file__).resolve().parent.parent
GOLDEN = Path(os.environ.get("G1_GOLDEN", "/home/eda/xs-env/G1-canonical/golden-rtl"))
OUT = REPO / "rtl" / "backend"
BEGIN = "// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block."
END = "// END GENERATED"

# Core names are semantic; golden names remain exact at the wrapper boundary.
MAPS = {
    "MLevelPermitModule": [
      ("csr_wen", "io_in_csrAccess_wen"), ("csr_addr", "io_in_csrAccess_addr"),
      ("priv_prvm", "io_in_privState_PRVM"), ("priv_v", "io_in_privState_V"),
      ("status_tvm", "io_in_status_tvm"),
      ("status_mstatus_fs_off", "io_in_status_mstatusFSOff"),
      ("status_vsstatus_fs_off", "io_in_status_vsstatusFSOff"),
      ("status_mstatus_vs_off", "io_in_status_mstatusVSOff"),
      ("status_vsstatus_vs_off", "io_in_status_vsstatusVSOff"),
      ("mcounteren", "io_in_xcounteren_mcounteren"),
      ("menvcfg", "io_in_xenvcfg_menvcfg"),
      ("stateen0_se0", "io_in_xstateen_mstateen0_SE0"),
      ("stateen0_envcfg", "io_in_xstateen_mstateen0_ENVCFG"),
      ("stateen0_csrind", "io_in_xstateen_mstateen0_CSRIND"),
      ("stateen0_aia", "io_in_xstateen_mstateen0_AIA"),
      ("stateen0_imsic", "io_in_xstateen_mstateen0_IMSIC"),
      ("stateen0_context", "io_in_xstateen_mstateen0_CONTEXT"),
      ("stateen0_c", "io_in_xstateen_mstateen0_C"),
      ("stateen1_se", "io_in_xstateen_mstateen1_SE"),
      ("stateen2_se", "io_in_xstateen_mstateen2_SE"),
      ("stateen3_se", "io_in_xstateen_mstateen3_SE"),
      ("aia_mvien_seie", "io_in_aia_mvienSEIE"),
      ("mlevel_permit_ex_ii", "io_out_mLevelPermit_EX_II"),
      ("has_legal_write_fcsr", "io_out_hasLegalWriteFcsr"),
      ("has_legal_write_vcsr", "io_out_hasLegalWriteVcsr"),
    ],
    "MbmcModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),("bma","regOut_BMA"),("keyiden","regOut_KEYIDEN"),("bme","regOut_BME"),("bclear","regOut_BCLEAR"),("cmode","regOut_CMODE")],
    "McontextModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),("hcontext","regOut_HCONTEXT"),("from_hcontext_valid","fromHcontext_valid"),("from_hcontext","fromHcontext_bits_HCONTEXT"),("to_hcontext","toHcontext_HCONTEXT")],
    "McorepwrModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),("commit_stuck_check_enable","regOut_COMMIT_STUCK_CHECK_ENABLE"),("power_down_enable","regOut_POWER_DOWN_ENABLE")],
    "McounterenModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),("cy","regOut_CY"),("tm","regOut_TM"),("ir","regOut_IR"),("hpm","regOut_HPM")],
    "McountinhibitModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),("cy","regOut_CY"),("ir","regOut_IR"),("hpm3","regOut_HPM3")],
    "MedelegModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),
      ("ex_iam","regOut_EX_IAM"),("ex_iaf","regOut_EX_IAF"),("ex_ii","regOut_EX_II"),("ex_bp","regOut_EX_BP"),("ex_lam","regOut_EX_LAM"),("ex_laf","regOut_EX_LAF"),("ex_sam","regOut_EX_SAM"),("ex_saf","regOut_EX_SAF"),("ex_ucall","regOut_EX_UCALL"),("ex_hscall","regOut_EX_HSCALL"),("ex_vscall","regOut_EX_VSCALL"),("ex_ipf","regOut_EX_IPF"),("ex_lpf","regOut_EX_LPF"),("ex_spf","regOut_EX_SPF"),("ex_swc","regOut_EX_SWC"),("ex_hwe","regOut_EX_HWE"),("ex_igpf","regOut_EX_IGPF"),("ex_lgpf","regOut_EX_LGPF"),("ex_vi","regOut_EX_VI"),("ex_sgpf","regOut_EX_SGPF")],
    "MenvcfgModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),("stce","regOut_STCE"),("pbmte","regOut_PBMTE"),("dte","regOut_DTE"),("pmm","regOut_PMM"),("cbze","regOut_CBZE"),("cbcfe","regOut_CBCFE"),("cbie","regOut_CBIE")],
    "MflushpwrModule": [("clock","clock"),("reset","reset"),("csr_wen","w_wen"),("csr_wdata","w_wdata"),("rdata","rdata"),("flush_l2_enable","regOut_FLUSH_L2_ENABLE"),("l2_flush_done","regOut_L2_FLUSH_DONE"),("l2_flush_done_in","l2FlushDone")],
}

def die(msg: str) -> None:
    raise SystemExit(f"gen_csr_m_leaves: {msg}")

def ports_from(text: str, top: str):
    m = re.search(r"^module\s+" + re.escape(top) + r"\(\n(.*?)\n\);", text, re.M | re.S)
    if not m: die(f"{top}: module declaration not found")
    ans=[]
    for line in m.group(1).splitlines():
        q=re.match(r"^\s+(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+),?$",line)
        if not q: die(f"{top}: unrecognized port line {line!r}")
        rng = f"[{q.group(2)}:{q.group(3)}]" if q.group(2) else ""
        ans.append((q.group(1),rng,q.group(4)))
    return ans

def core_ports(text: str, top: str):
    m=re.search(r"module\s+xs_"+re.escape(top)+r"_core\s*\((.*?)\n\);",text,re.S)
    if not m: die(f"{top}: core declaration not found")
    body=re.sub(r"//[^\n]*", "", m.group(1))
    # Allow readable one-port lines and compact declarations with several ports.
    pat=re.compile(r"\b(input|output)\s+logic\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)")
    ans=[(q.group(1), (f"[{q.group(2)}:{q.group(3)}]" if q.group(2) else ""), q.group(4))
         for q in pat.finditer(body)]
    if not ans: die(f"{top}: core port table is empty")
    consumed=pat.sub("", body)
    consumed=re.sub(r"[\s,]", "", consumed)
    if consumed: die(f"{top}: unrecognized core port text {consumed!r}")
    return ans

def block(top: str, text: str) -> str:
    gp=ports_from((GOLDEN/f"{top}.sv").read_text(),top)
    cp=core_ports(text,top)
    mp=MAPS[top]
    if len({x[0] for x in mp}) != len(mp) or len({x[1] for x in mp}) != len(mp): die(f"{top}: duplicate mapping")
    gd={n:d for d,_,n in gp}; gn=set(gd)
    cd={n:(d,r) for d,r,n in cp}; cn=set(cd)
    if {g for _,g in mp} != gn: die(f"{top}: mapping/golden mismatch")
    if {c for c,_ in mp} != cn: die(f"{top}: mapping/core mismatch")
    for c,g in mp:
        if cd[c][0] != gd[g]: die(f"{top}: direction mismatch {c}/{g}")
        if cd[c][1] != dict((n,r) for _,r,n in gp)[g]: die(f"{top}: width mismatch {c}/{g}")
    wdir=max(map(lambda x:len(x[0]),gp)); wrng=max(map(lambda x:len(x[1]),gp))
    out=[BEGIN,f"module {top}("]
    for i,(d,r,n) in enumerate(gp): out.append(f"  {d.ljust(wdir)} {r.ljust(wrng)} {n}{',' if i+1<len(gp) else ''}")
    out += [");", "", f"  xs_{top}_core u_core ("]
    wc=max(len(c) for c,_ in mp)
    for i,(c,g) in enumerate(mp): out.append(f"    .{c.ljust(wc)} ({g}){',' if i+1<len(mp) else ''}")
    out += ["  );", "endmodule", END, ""]
    return "\n".join(out)

def main() -> int:
    ap=argparse.ArgumentParser(); ap.add_argument('--check',action='store_true'); args=ap.parse_args()
    drift=0
    for top in MAPS:
        path=OUT/f"{top}.sv"
        if not path.exists(): die(f"missing {path}")
        txt=path.read_text()
        if txt.count(BEGIN)!=1 or txt.count(END)!=1: die(f"{top}: generated markers must occur once")
        before,tail=txt.split(BEGIN,1); _,after=tail.split(END,1)
        new=before+block(top,txt)+after.lstrip("\n")
        if new != txt:
            drift += 1
            if args.check: print(f"DRIFT {path.relative_to(REPO)}")
            else: path.write_text(new); print(f"wrote {path.relative_to(REPO)}")
        else: print(f"  {top}: OK")
    if args.check and drift: print(f"gen_csr_m_leaves --check: DRIFT ({drift})"); return 1
    if args.check: print(f"gen_csr_m_leaves --check: OK ({len(MAPS)} files)")
    return 0

if __name__ == '__main__': sys.exit(main())
