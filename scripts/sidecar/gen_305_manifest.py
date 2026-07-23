#!/usr/bin/env python3
"""生成 canonical-bound signoff manifest(MANIFEST_RUNNER_PREP, 审查修订版)。

审查铁律(SIGNOFF_MANIFEST_POLICY):
 - **required_verdict 由 proof_mode 机械派生**, 不手设:
     signoff-strict / assembly → SUCCEEDED(唯一合法签核要求)
     shadow                    → SHADOW_CHECK(单独统计, 不算等价通过)
   PARTIAL / FAILED / TIMEOUT / UNVERIFIED **永不**作为正式 required_verdict。
 - **config_status**: CONFIGURED(有 FM 配置)| UNCONFIGURED(有 UT 无 FM, 如 Rob)——
   UNCONFIGURED **不运行、不计通过**, 但显式记录(覆盖完整性)。
 - declarations.tsv 只声明**设计契约**: proof_mode(边界)+ allow_ref(对象 allowlist)
   + target-scoped proof strengthening;
   **不声明 verdict**。测量到的新对象只能形成候选变更, 人工确认后改声明+重跑, 不反向放行。
 - 目标全集须与冻结清单 verif/freeze/fm_targets.tsv 对账(机器 diff, 见 reconcile_universe.py)。

机械字段自 Makefile 枚举(FM_VARIANTS 经 `make --eval` 权威展开, 解析 $(VAR) 引用)。
"""
import argparse, json, os, re, glob, subprocess

BID_LEDGER = "/home/eda/xs-env/G0-canonical/PROMOTION_LEDGER.tsv"
ASSEMBLY_DIRS = {"Backend", "Ftq", "L2TLB", "LsqWrapper", "NewIFU", "OpenLLC", "TL2CHICoupledL2"}
FMBB = {"DCache": "fmbb", "DCacheWrapper": "fmbb", "L2TLBWrapper": "fmbb",
        "MemBlock": "fmbb", "NewCSR": "fmbb", "PtwCache": "fm"}
SHADOW_DIRS = {"Predictor", "Frontend"}
# required_verdict 机械派生表(唯一合法签核要求)
REQUIRED_BY_MODE = {"signoff-strict": "SUCCEEDED", "assembly": "SUCCEEDED",
                    "shadow": "SHADOW_CHECK"}


def canonical_bid():
    for ln in open(BID_LEDGER):
        p = ln.rstrip("\n").split("\t")
        if len(p) == 2 and p[0] == "canonical_baseline_id":
            return p[1]
    raise SystemExit("no canonical_baseline_id")


def load_declarations(path):
    """Read design contracts, never measured verdicts.

    Columns:
      target, proof_mode, allow_ref, rationale,
      verify_matched_unread_compare_points

    The final column is a strengthening (it asks Formality to prove otherwise
    unread matched points); it is not a waiver.  Missing means the frozen 305
    default, false.
    """
    decl = {}
    if not path or not os.path.isfile(path):
        return decl
    for ln in open(path, encoding="utf-8"):
        ln = ln.rstrip("\n")
        if not ln or ln.startswith("#"):
            continue
        p = ln.split("\t")
        if len(p) < 2:
            continue
        if p[0] in decl:
            raise SystemExit(f"duplicate declaration target: {p[0]}")
        vmucp = p[4] if len(p) > 4 and p[4] else "false"
        if vmucp not in ("true", "false"):
            raise SystemExit(f"bad verify_matched_unread_compare_points for {p[0]}: {vmucp}")
        if vmucp == "true" and p[0] not in {"LoadQueueUncache",
                "FastArbiter_46", "FastArbiter_47", "FastArbiter_27", "FastArbiter_44",
                "ICacheCtrlUnit", "ICacheDataArray", "IPrefetchPipe",
                "DivUnit", "FDivSqrt", "InstrMMIOEntry", "InstrUncache", "TXDAT_4", "FAlu", "FCVT", "IssueQueueStdMoud", "MulUnit", "TXREQ", "TlbStorageWrapper", "TlbStorageWrapper_1", "IssueQueueStaMou", "IssueQueueLdu", "TXDAT", "Scheduler_1", "Scheduler", "Scheduler_3", "MSHR", "TageBTable", "Directory", "SCTable", "SCTable_1", "SCTable_2", "SCTable_3"}:
            raise SystemExit(f"target-scoped strengthening forbidden for {p[0]}")
        decl[p[0]] = {"proof_mode": p[1] or None,
                      "allow_ref": p[2] if len(p) > 2 else "",
                      "rationale": p[3] if len(p) > 3 else "",
                      "verify_matched_unread_compare_points": vmucp}
    return decl


def load_auxiliary_targets(path):
    """Read independently-proved leaf targets that are outside the frozen 305 denominator."""
    targets = set()
    if not path or not os.path.isfile(path):
        return targets
    for ln in open(path, encoding="utf-8"):
        ln = ln.rstrip("\n")
        if not ln or ln.startswith("#"):
            continue
        target = ln.split("\t", 1)[0]
        if target in targets:
            raise SystemExit(f"duplicate auxiliary target: {target}")
        targets.add(target)
    return targets


def load_frozen_targets(path):
    targets = set()
    for ln in open(path, encoding="utf-8"):
        ln = ln.rstrip("\n")
        if not ln or ln.startswith("#"):
            continue
        target = ln.split("\t", 1)[0]
        targets.add(target)
    return targets


def has_fm_assignment(makefile):
    txt = re.sub(r"\\\n", " ", open(makefile).read())
    return bool(re.search(r"^FM_VARIANTS\s*[:+]?=", txt, re.M))


def variants_of(makefile):
    d = os.path.dirname(makefile); fn = os.path.basename(makefile)
    if not has_fm_assignment(makefile):
        return []
    try:
        out = subprocess.run(
            ["make", "-f", fn, "--eval=__fmv:;\t@echo $(FM_VARIANTS)", "__fmv"],
            cwd=d, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            universal_newlines=True, timeout=60).stdout
    except Exception:
        return []
    vals = []
    for ln in out.splitlines():
        ln = ln.split("#")[0].strip()
        if ln:
            vals = ln.split()
    return vals


def mk_entry(target, ut_dir, makefile, make_target, entry, pmode, decl, bid, cfg="CONFIGURED"):
    d = decl.get(target, {})
    pm = d.get("proof_mode") or pmode
    return {"target": target, "ut_dir": ut_dir, "makefile": os.path.relpath(makefile) if makefile else "",
            "make_target": make_target, "entry": entry, "proof_mode": pm,
            "config_status": cfg,
            "required_verdict": REQUIRED_BY_MODE.get(pm, "SUCCEEDED") if cfg == "CONFIGURED" else "N/A",
            "allow_ref": d.get("allow_ref", ""), "rationale": d.get("rationale", ""),
            "verify_matched_unread_compare_points":
                d.get("verify_matched_unread_compare_points", "false"),
            "canonical_baseline_id": bid}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ut-root", default="verif/ut")
    ap.add_argument("--declarations", default="scripts/sidecar/manifest_declarations.tsv")
    ap.add_argument("--auxiliary-targets", default="verif/signoff/auxiliary_targets.tsv")
    ap.add_argument("--frozen-targets", default="verif/freeze/fm_targets.tsv")
    ap.add_argument("--out", default="scripts/sidecar/manifest_305.json")
    a = ap.parse_args()
    bid = canonical_bid()
    decl = load_declarations(a.declarations)
    auxiliary_targets = load_auxiliary_targets(a.auxiliary_targets)
    frozen_targets = load_frozen_targets(a.frozen_targets)
    overlap = auxiliary_targets & frozen_targets
    if overlap:
        raise SystemExit(f"auxiliary target is in frozen main universe: {sorted(overlap)}")
    entries = []
    seen = set()
    fm_dirs = set()
    auxiliary_seen = set()

    for mk in sorted(glob.glob(os.path.join(a.ut_root, "*", "Makefile")) +
                     glob.glob(os.path.join(a.ut_root, "*", "Makefile.*"))):
        ut_dir = os.path.basename(os.path.dirname(mk))
        if ut_dir in FMBB and mk.endswith("Makefile"):
            mt = FMBB[ut_dir]
            entry = ("verif/ut/%s/fm_eq_bb.tcl" % ut_dir) if mt == "fmbb" else "scripts/fm_eq.tcl"
            pm = "assembly" if mt == "fmbb" else "signoff-strict"
            key = (ut_dir, ut_dir, mt)
            if key in seen:
                continue
            seen.add(key); fm_dirs.add(ut_dir)
            entries.append(mk_entry(ut_dir, ut_dir, mk, mt, entry, pm, decl, bid))
            continue
        for v in variants_of(mk):
            # Auxiliary child proofs qualify an assembly parent through
            # assembly_depends.tsv, but never expand the frozen 305 denominator.
            if v in auxiliary_targets:
                if v in auxiliary_seen:
                    raise SystemExit(f"auxiliary target has multiple mechanical entries: {v}")
                auxiliary_seen.add(v)
                continue
            key = (ut_dir, v, "fm-%s" % v)
            if key in seen:
                continue
            seen.add(key); fm_dirs.add(ut_dir)
            pm = "assembly" if ut_dir in ASSEMBLY_DIRS else ("shadow" if ut_dir in SHADOW_DIRS else "signoff-strict")
            entries.append(mk_entry(v, ut_dir, mk, "fm-%s" % v, "scripts/fm_eq.tcl", pm, decl, bid))

    # UNCONFIGURED: 有 UT 目录但无任何 FM 配置(如 Rob)——显式记录, 不运行不计通过
    unconfigured = []
    for dd in sorted(glob.glob(os.path.join(a.ut_root, "*"))):
        if not os.path.isdir(dd):
            continue
        ud = os.path.basename(dd)
        if ud in fm_dirs:
            continue
        # 该目录是否有任何 Makefile 含 FM 配置?
        mks = glob.glob(os.path.join(dd, "Makefile")) + glob.glob(os.path.join(dd, "Makefile.*"))
        if any(has_fm_assignment(m) for m in mks):
            continue  # 有 FM 但 variants 为空(另议), 不算 UNCONFIGURED
        unconfigured.append(ud)
        entries.append(mk_entry(ud, ud, "", "-", "-", "n/a", decl, bid, cfg="UNCONFIGURED"))

    unknown_auxiliary = auxiliary_targets - auxiliary_seen
    if unknown_auxiliary:
        raise SystemExit(f"auxiliary target is not mechanically enumerable: {sorted(unknown_auxiliary)}")

    entries.sort(key=lambda e: (e["config_status"], e["ut_dir"], e["target"], e["make_target"]))
    manifest = {"schema": "fm-signoff-manifest-v2", "canonical_baseline_id": bid,
                "count_total": len(entries),
                "count_configured": sum(1 for e in entries if e["config_status"] == "CONFIGURED"),
                "count_unconfigured": sum(1 for e in entries if e["config_status"] == "UNCONFIGURED"),
                "entries": entries}
    with open(a.out, "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    from collections import Counter
    cfg = [e for e in entries if e["config_status"] == "CONFIGURED"]
    by_mode = Counter(e["proof_mode"] for e in cfg)
    by_req = Counter(e["required_verdict"] for e in cfg)
    print(f"configured={len(cfg)} unconfigured={len(unconfigured)} ({unconfigured[:8]}...)")
    print(f"by_mode={dict(by_mode)}  by_required_verdict(派生)={dict(by_req)}")


if __name__ == "__main__":
    main()
