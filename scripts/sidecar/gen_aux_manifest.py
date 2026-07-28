#!/usr/bin/env python3
"""生成独立 AUX signoff manifest(codex_0084): auxiliary_targets.tsv 里的 leaf/child
AUX proof 逐个可经正式 sidecar runner 归档(RESULT/RUNNER_RC/MANIFEST/COMPLETE), 不进
305 主分母。字段机械自各 target 的 UT Makefile 派生(make_target=fm-<T>, proof_mode=FM_MODE,
entry=scripts/fm_eq.tcl, vmucp=FM_VERIFY_MATCHED_UNREAD, allow_ref=FM_ALLOWLIST);
required_verdict 由 aux_targets.tsv 的状态派生(PASS->SUCCEEDED, PASS_DEAD_REF->PASS_DEAD_REF)。
仅归档 aux_targets 状态为 PASS/PASS_DEAD_REF 的(PENDING_CHILD_CLOSURE 不归档)。
用法: gen_aux_manifest.py [--only T1,T2,...] --out manifest_aux.json
"""
import argparse, json, os, re, glob, subprocess
import gen_305_manifest as g

AUX_TSV = "verif/signoff/aux_targets.tsv"
AUXILIARY = "verif/signoff/auxiliary_targets.tsv"


def aux_status():
    st = {}
    for ln in open(AUX_TSV, encoding="utf-8"):
        p = ln.rstrip("\n").split("\t")
        if len(p) >= 2 and p[0] and not p[0].startswith("#"):
            st[p[0]] = p[1]
    return st


def mk_field(makefile, var):
    """从 Makefile 取简单变量值(FM_MODE/FM_ALLOWLIST/FM_VERIFY_MATCHED_UNREAD...)。"""
    if not os.path.isfile(makefile):
        return ""
    txt = re.sub(r"\\\n", " ", open(makefile).read())
    m = re.search(rf"^{re.escape(var)}\s*[:?]?=\s*(.*)$", txt, re.M)
    return m.group(1).split("#")[0].strip() if m else ""


_VAR_INDEX = None


def build_variant_index():
    """一次性建 variant->(makefile, ut_dir) 索引(避免 O(aux*makefiles) 次 make 调用)。"""
    idx = {}
    for mk in sorted(glob.glob("verif/ut/*/Makefile")):
        ut_dir = os.path.basename(os.path.dirname(mk))
        for v in g.variants_of(mk):
            idx.setdefault(v, (mk, ut_dir))
    return idx


def find_ut_makefile(target):
    global _VAR_INDEX
    if _VAR_INDEX is None:
        _VAR_INDEX = build_variant_index()
    return _VAR_INDEX.get(target, (None, None))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--out", default="scripts/sidecar/manifest_aux.json")
    a = ap.parse_args()
    bid = g.canonical_bid()
    st = aux_status()
    only = set(a.only.split(",")) if a.only else None
    entries = []
    for target, status in sorted(st.items()):
        if only and target not in only:
            continue
        if status not in ("PASS", "PASS_DEAD_REF"):
            continue  # PENDING_CHILD_CLOSURE 等不归档
        mk, ut_dir = find_ut_makefile(target)
        if not mk:
            print(f"WARN: {target} 无 UT Makefile(跳过)")
            continue
        pm = mk_field(mk, "FM_MODE") or "signoff-strict"
        vmucp = "true" if mk_field(mk, "FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS") == "true" else "false"
        alr = mk_field(mk, "FM_ALLOWLIST")
        allow_ref = ""
        if alr and alr != "0":
            allow_ref = os.path.normpath(os.path.join(os.path.dirname(mk), alr)) if alr.startswith("..") else alr
        dr = f"verif/signoff/dead_ref/{target}.json"
        dead_ref = dr if os.path.isfile(dr) else ""
        reqv = "PASS_DEAD_REF" if (status == "PASS_DEAD_REF" or dead_ref) else "SUCCEEDED"
        entries.append({
            "target": target, "ut_dir": ut_dir, "makefile": mk,
            "make_target": "fm-%s" % target, "entry": "scripts/fm_eq.tcl",
            "proof_mode": pm, "config_status": "AUX", "required_verdict": reqv,
            "allow_ref": allow_ref, "rationale": "",
            "verify_matched_unread_compare_points": vmucp,
            "dead_ref": dead_ref, "canonical_baseline_id": bid})
    entries.sort(key=lambda e: e["target"])
    manifest = {"schema": "fm-signoff-aux-manifest-v1", "canonical_baseline_id": bid,
                "count_aux": len(entries), "entries": entries}
    with open(a.out, "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    print(f"aux manifest: {len(entries)} entries -> {a.out}")


if __name__ == "__main__":
    main()
