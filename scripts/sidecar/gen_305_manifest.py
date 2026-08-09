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
SHADOW_DIRS = set()
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
        if vmucp == "true" and p[0] not in {"XSTop", "XSTile", "Backend", "LoadQueueUncache","FastArbiter_46","FastArbiter_47","FastArbiter_27","FastArbiter_44","ICacheCtrlUnit","ICacheDataArray","IPrefetchPipe","DivUnit","FDivSqrt","InstrMMIOEntry","InstrUncache","TXDAT_4","FAlu","FCVT","IssueQueueStdMoud","MulUnit","TXREQ","TlbStorageWrapper","TlbStorageWrapper_1","IssueQueueStaMou","IssueQueueLdu","TXDAT","Scheduler_1","Scheduler","Scheduler_3","MSHR","TageBTable","Directory","SCTable","SCTable_1","SCTable_2","SCTable_3","Tage_SC","ITTage","FauFTB","FTBBank","FTB","Composer","EntriesAluCsrFenceDiv","Bku","SourceB","Predictor","EntriesAluMulBkuBrhJmp","DuplicatedTagArray","PtwCache","WritebackQueue","LinkMonitor","Ftq","LoadQueue","LoadPipe","MissQueue","IssueQueueAluMulBkuBrhJmp","L2TLB","Rename","IssueQueueAluCsrFenceDiv","Scheduler_2","DebugModule","WbDataPath","IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v","Slice","LoadQueueReplay","NewCSR","DCache","DataPath","SnoopUnit","MemUnit","RefillUnit","ResponseUnit","OpenLLC","StoreQueue","FastArbiter_1","FastArbiter_2","FastArbiter_28","FastArbiter_29","Slice_1","Slice_2","Slice_3","Directory_1","Directory_2","Directory_3","PrefetchReqBuffer","RXSNP","Prefetcher","Pipeline_2","Pipeline_3","FusionDecoder","TL2CHICoupledL2","L2Top","PrefetchQueue","VBestOffsetPrefetch","MemCtrl", "Frontend", "CSR", "VLSplitImp", "VSSplitImp", "AtomicsUnit", "VSMergeBufferImp", "VLMergeBufferImp", "PTWNewFilter", "L1Prefetcher", "SMSPrefetcher", "VSegmentUnit", "MemBlock", "HPerfMonitor_2", "FastArbiter_77", "FastArbiter_78", "FastArbiter_79", "TLBNonBlock_1", "TLBNonBlock_2", "ExuBlock_2", "TLBNonBlock", "BankedDataArray", "StorePipe", "RenameBuffer"}:
            raise SystemExit(f"target-scoped strengthening forbidden for {p[0]}")
        # 十四审: 第 6 列(可选)= per-target dead-ref 声明文件路径。声明存在 ⇒ 该 target
        # 的 required_verdict 变为 PASS_DEAD_REF(golden-only 死点已逐点声明+审核)。
        dead_ref = p[5] if len(p) > 5 and p[5] and p[5] != "-" else ""
        # 第 7 列(可选)= reference_kind: golden(默认) | canonical_derivative。
        # 第 8 列(可选)= derivative_id: canonical_derivative 时必填, 定位 committed
        #   verif/freeze/canonical/derivatives/<id> ledger(runner 逐字 hash 校验)。
        # 二者只是设计契约(引用来源), 不声明 verdict; 派生件的可观测参考替换冻结
        # golden 空壳, 但 runner 只从 committed ledger 按 id+hash 取字节, 无 env 覆盖。
        ref_kind = p[6] if len(p) > 6 and p[6] and p[6] != "-" else "golden"
        deriv_id = p[7] if len(p) > 7 and p[7] and p[7] != "-" else ""
        if ref_kind not in ("golden", "canonical_derivative"):
            raise SystemExit(f"bad reference_kind for {p[0]}: {ref_kind}")
        if ref_kind == "canonical_derivative" and not deriv_id:
            raise SystemExit(f"reference_kind=canonical_derivative requires derivative_id for {p[0]}")
        if ref_kind == "golden" and deriv_id:
            raise SystemExit(f"derivative_id set but reference_kind=golden for {p[0]}")
        decl[p[0]] = {"proof_mode": p[1] or None,
                      "allow_ref": p[2] if len(p) > 2 else "",
                      "rationale": p[3] if len(p) > 3 else "",
                      "verify_matched_unread_compare_points": vmucp,
                      "dead_ref": dead_ref,
                      "reference_kind": ref_kind,
                      "derivative_id": deriv_id}
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


def fmbb_tcl_entry(makefile, ut_dir, mt):
    """从 Makefile 的 mt 规则解析实际执行的 `fm_shell ... -file <tcl>`，派生 entry
    路径(相对 xs-signoff 根)。避免硬编码 fm_eq_bb.tcl 与实际 closure 不符(codex_0075:
    NewCSR 实走 fm_eq_parent.tcl)。$(abspath X)->verif/ut/<dir>/X; $(XSSV_HOME)/scripts/X
    ->scripts/X。解析失败回退 None(调用方保留旧默认)。"""
    if not makefile or not os.path.isfile(makefile):
        return None
    lines = open(makefile).read().splitlines()
    inrule = False; body = []
    for ln in lines:
        if re.match(rf"^{re.escape(mt)}\s*:", ln):
            inrule = True; continue
        if inrule:
            seg = ln.split("#")[0]
            if ln and not ln[0].isspace() and ":" in seg and not seg.lstrip().startswith("@"):
                break
            body.append(ln)
    blob = "\n".join(body)
    m = re.search(r"-file\s+\$\(abspath\s+([^\s)]+\.tcl)\)", blob)
    if m:
        return "verif/ut/%s/%s" % (ut_dir, os.path.basename(m.group(1)))
    m = re.search(r"-file\s+\$\(XSSV_HOME\)/(\S+\.tcl)", blob)
    if m:
        return m.group(1)
    m = re.search(r"-file\s+(\S+\.tcl)", blob)
    if m:
        return m.group(1)
    return None


def mk_entry(target, ut_dir, makefile, make_target, entry, pmode, decl, bid, cfg="CONFIGURED"):
    d = decl.get(target, {})
    pm = d.get("proof_mode") or pmode
    dead_ref = d.get("dead_ref", "")
    # 十四审: 声明了 dead-ref ⇒ required_verdict = PASS_DEAD_REF(否则按 mode 默认)。
    if cfg != "CONFIGURED":
        reqv = "N/A"
    elif dead_ref:
        reqv = "PASS_DEAD_REF"
    else:
        reqv = REQUIRED_BY_MODE.get(pm, "SUCCEEDED")
    return {"target": target, "ut_dir": ut_dir, "makefile": os.path.relpath(makefile) if makefile else "",
            "make_target": make_target, "entry": entry, "proof_mode": pm,
            "config_status": cfg,
            "required_verdict": reqv,
            "allow_ref": d.get("allow_ref", ""), "rationale": d.get("rationale", ""),
            "verify_matched_unread_compare_points":
                d.get("verify_matched_unread_compare_points", "false"),
            "dead_ref": dead_ref,
            "reference_kind": d.get("reference_kind", "golden"),
            "derivative_id": d.get("derivative_id", ""),
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
    emptyvar_dirs = set()  # 非 FMBB 且 FM_VARIANTS 真空(如 Rob)——显式 UNCONFIGURED

    # v1 锚语义固化(codex 0123/0133, RC2 blocker-2): Rob 的证明属 cone-DCE partitioned
    # 流程(manifest_306_v2), 永不由 monolithic Makefile entry 表达——即使
    # verif/ut/Rob/Makefile 携带 FM_VARIANTS(分区工作 7310becb 引入)也强制 UNCONFIGURED;
    # verif/ut/Rob_partitions 只放分区脚本、非独立 target, 整目录忽略。
    V1_FORCE_UNCONFIGURED = {"Rob"}
    V1_IGNORE_DIRS = {"Rob_partitions"}

    for mk in sorted(glob.glob(os.path.join(a.ut_root, "*", "Makefile")) +
                     glob.glob(os.path.join(a.ut_root, "*", "Makefile.*"))):
        ut_dir = os.path.basename(os.path.dirname(mk))
        if ut_dir in V1_IGNORE_DIRS:
            continue
        if ut_dir in V1_FORCE_UNCONFIGURED:
            emptyvar_dirs.add(ut_dir)
            continue
        if ut_dir in FMBB and mk.endswith("Makefile"):
            mt = FMBB[ut_dir]
            # entry 从 Makefile mt 规则实际 `-file <tcl>` 派生(codex_0075: provenance 须
            # 与真实执行的 Tcl closure 一致); 派生失败才回退硬编码默认。
            entry = fmbb_tcl_entry(mk, ut_dir, mt) or \
                (("verif/ut/%s/fm_eq_bb.tcl" % ut_dir) if mt == "fmbb" else "scripts/fm_eq.tcl")
            pm = "assembly" if mt == "fmbb" else "signoff-strict"
            key = (ut_dir, ut_dir, mt)
            if key in seen:
                continue
            seen.add(key); fm_dirs.add(ut_dir)
            entries.append(mk_entry(ut_dir, ut_dir, mk, mt, entry, pm, decl, bid))
            continue
        vs = variants_of(mk)
        if not vs and has_fm_assignment(mk):
            # 有 FM_VARIANTS 赋值但真空(非 FMBB): 已知目标但无可跑证明 -> UNCONFIGURED
            emptyvar_dirs.add(ut_dir)
        for v in vs:
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
        if ud in V1_IGNORE_DIRS:
            continue
        if ud in fm_dirs:
            continue
        # 该目录是否有任何 Makefile 含 FM 配置?
        mks = glob.glob(os.path.join(dd, "Makefile")) + glob.glob(os.path.join(dd, "Makefile.*"))
        if any(has_fm_assignment(m) for m in mks) and ud not in emptyvar_dirs:
            continue  # 有 FM 且 variants 经 aux 过滤后为空(如 CSR 位域族全入 AUX), 不算 UNCONFIGURED
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
