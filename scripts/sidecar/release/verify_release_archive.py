#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""RC3 release archive 语义校验器 (Lane A, codex 0137 §2 全量精确检查).

扩展自 RC2 Lane D 草案 (A-F), 新增/加强 (逐条对应 0137 §2):

  A. 封装: 零 symlink; ARCHIVE_MANIFEST.tsv 双向精确覆盖(树上文件都在
     manifest / manifest 行都在树上 / size+sha256 全复算 / 无重复行 / 无绝对
     路径或 ..); COMPLETE == sha256(ARCHIVE_MANIFEST.tsv).
  B. main target set 精确 306: 305 清单从归档内 manifests/manifest_305.json
     提取(config_status != UNCONFIGURED, 恰 305, 不含 Rob); targets/ 目录集
     == 该 305 (多/缺/非目录都 violation); Rob 由 rob/ 表达(targets/Rob 违例);
     v2-306 manifest CONFIGURED == 306 且 == 305 ∪ {Rob}.
  C. per-receipt (305 shard): 必备文件 {RESULT.txt, COMPLETE, MANIFEST.tsv,
     TOOLS.tsv, native_facts.json, verdict.sidecar.json, RUNNER_RC};
     COMPLETE == sha256(MANIFEST.tsv); MANIFEST.tsv 条目逐个 size/sha 复算 +
     receipt 目录双向覆盖(除 COMPLETE/MANIFEST.tsv 外); RUNNER_RC == 0;
     RESULT.txt gate=PASS 且 measured==required==manifest required_verdict;
     impl_commit == RC3; manifest_sha256 == sha256(manifests/manifest_305.json).
  D. Rob partitioned: parts 精确 == {part.commit, part.exception, part.perf,
     part.vecexcp, part.lsq} 不多不少; 每 part RUNNER_RC==0 且 fm.log 含
     "Verification SUCCEEDED"; rob/UNION_RECORD.tsv sha256 == v2 manifest Rob
     derivative_id 且含 UNION_STATUS PASS; rob/UNION_RECORD.rc3-fresh.tsv 存在
     且与 canonical 逐行相同(机器比对, 仅 '# generated' 时间行豁免), 其
     UNION_STATUS 行含 PASS.
  E. aux 精确 16 (缺省硬编码清单, 可 --aux-list 覆盖): 同 C 校验 vs
     manifest_aux.json + RC3.
  F. aux-supplement 精确 4 == {FastArbiter_4,5,7,8}: 每份 receipt 全语义:
     必备文件; COMPLETE/MANIFEST 完整性+双向覆盖; RUNNER_RC==0; RESULT.txt
     gate=PASS 且 measured==required==SUCCEEDED; TOOLS.tsv infra 行覆盖
     runner(run_signoff_target.sh)+validator(fm_sidecar_verdict.py); TOOLS.tsv
     allow_ref/dead_ref 行存在且与 manifest_aux entry 一致(strict ⇒ 空);
     receipt allow.json 四类全空; verdict.sidecar.json: native_verdict ==
     SUCCEEDED, stats{failing,unverified,aborted,unread_notcompared} 全 0,
     unmatched 六项全 0, entry_appvars
     verification_verify_matched_unread_compare_points == "true";
     impl_commit(RESULT.txt, TOOLS.tsv 若有须一致) == supplement commit;
     manifest_sha256 == sha256(manifests/manifest_aux.json).
     另: supplement/SUPPLEMENT.tsv 行集 == 4 目标, gate=PASS, impl_commit ==
     supplement commit, evidence 路径存在.
  G. MSHRCtl dependency closure (supplement/MSHRCTL_DEPENDENCY_CLOSURE.tsv,
     机器格式): 可提取 rc3_commit == RC3, supplement_commit == supplement
     commit; `edge\t<target>\t<sha256>` 行精确 4 条 == {FastArbiter_4,5,7,8}
     无缺失/额外/重复; 每条 edge 的 receipt
     aux-supplement/<t>/verdict.sidecar.json 存在且实际 sha256 与记录一致;
     `mshrctl_receipt\ttargets/MSHRCtl/verdict.sidecar.json\t<sha>` 行存在且
     sha 与实际一致.
  H. supplement/CLOSURE_MANIFEST.tsv: 存在; 首行注释含 RC3 与 supplement 两个
     全 sha; 行格式 path\trc3_sha256\tsupplement_sha256\tdisposition
     (added|modified|unchanged-sample); 变更文件集(added|modified) 精确 ==
     {scripts/sidecar/run_signoff_target.sh, scripts/sidecar/fm_sidecar_verdict.py,
      scripts/sidecar/gen_305_manifest.py,
      verif/signoff/supplement/fastarbiter_whitelist_negtest.py};
     有 --repo 时用 git show 逐文件复算两 commit blob 的 sha256 与记录比对
     (added ⇒ RC3 侧不存在且记录为 '-'); 无 --repo 降级为记录内部自洽 + WARN.
  I. tooling provenance: tooling/{build_release_archive.sh,
     verify_release_archive.py, negtest_release.py} 存在(sha 由 A 自然覆盖);
     有 --repo 时与 supplement(回退 RC3) commit 的
     scripts/sidecar/release/<name> 提交态比对(repo 两 commit 均无 ⇒ WARN).
  J. RC.txt: rc_commit == RC3; manifest_sha256 行与归档内 manifests/ 实际
     sha256 逐行一致.
  K. manifests 提交态一致(--repo): manifests/{6 个 json/tsv} 字节 ==
     git show RC3:scripts/sidecar/<name>; manifests/allow/, manifests/dead_ref/
     文件集与字节 == RC3 verif/signoff/{allow,dead_ref}/ 提交态.
  L. reconcile: reconcile/reconcile_v2_306.txt 含 RECONCILE_DIFF=0.
  M. 守恒: manifests/combined_ledger.tsv vs manifests/manifest_306_v2.json
     纯台账交叉审计(目标唯一/集合相等/类别守恒 nSUCC+nPDR+nPART==306/
     per-target measured==required_verdict).

用法:
  verify_release_archive.py <archive_dir> <rc_commit>
      [--supplement-commit SHA] [--aux-list FILE] [--repo DIR]

退出码 = min(violations, 120); WARN 不计入退出码.
python3.6 兼容.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

HEX64 = re.compile(r"^[0-9a-f]{64}$")

DEFAULT_SUPPLEMENT_COMMIT = "0a25fc916ec782d50e4a8749c5d26530b21d3f18"

AUX16_DEFAULT = [
    "Arbiter8_CHIDAT", "Arbiter8_TLBundleD",
    "Directory_1", "Directory_2", "Directory_3",
    "FrontendTrigger",
    "L2Slice_1", "L2Slice_2", "L2Slice_3",
    "MbistPipeL2Prefetcher", "PBestOffsetPrefetch", "Pipeline_1",
    "PredChecker", "PrefetchReceiver", "RRArbiterInit_11",
    "VBestOffsetPrefetch",
]

SUPP4 = ["FastArbiter_4", "FastArbiter_5", "FastArbiter_7", "FastArbiter_8"]

CHANGED4 = [
    "scripts/sidecar/run_signoff_target.sh",
    "scripts/sidecar/fm_sidecar_verdict.py",
    "scripts/sidecar/gen_305_manifest.py",
    "verif/signoff/supplement/fastarbiter_whitelist_negtest.py",
]

RECEIPT_REQUIRED = [
    "RESULT.txt", "COMPLETE", "MANIFEST.tsv", "TOOLS.tsv",
    "native_facts.json", "verdict.sidecar.json", "RUNNER_RC",
]

ROB_PARTS = ["part.commit", "part.exception", "part.perf",
             "part.vecexcp", "part.lsq"]

TOOLING_FILES = ["build_release_archive.sh", "verify_release_archive.py",
                 "negtest_release.py"]
TOOLING_REPO_DIR = "scripts/sidecar/release"

MANIFEST_REPO_MAP = {
    "manifest_305.json": "scripts/sidecar/manifest_305.json",
    "manifest_306_v2.json": "scripts/sidecar/manifest_306_v2.json",
    "manifest_aux.json": "scripts/sidecar/manifest_aux.json",
    "manifest_declarations.tsv": "scripts/sidecar/manifest_declarations.tsv",
    "manifest_declarations_aux.tsv": "scripts/sidecar/manifest_declarations_aux.tsv",
    "combined_ledger.tsv": "scripts/sidecar/combined_ledger.tsv",
}

errs = []
warns = []


def viol(msg):
    errs.append(msg)


def warn(msg):
    warns.append(msg)


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def read_text(p):
    with open(p, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def git_blob_bytes(repo, commit, path):
    """returns bytes or None (path absent at commit / git error)."""
    try:
        pr = subprocess.run(
            ["git", "-C", repo, "show", "%s:%s" % (commit, path)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError:
        return None
    if pr.returncode != 0:
        return None
    return pr.stdout


def git_blob_sha256(repo, commit, path):
    b = git_blob_bytes(repo, commit, path)
    if b is None:
        return None
    return hashlib.sha256(b).hexdigest()


def git_ls_tree(repo, commit, prefix):
    """returns list of paths or None on error."""
    try:
        pr = subprocess.run(
            ["git", "-C", repo, "ls-tree", "-r", "--name-only", commit, prefix],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            universal_newlines=True)
    except OSError:
        return None
    if pr.returncode != 0:
        return None
    return [l for l in pr.stdout.splitlines() if l.strip()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("archive")
    ap.add_argument("rc_commit")
    ap.add_argument("--supplement-commit", default=DEFAULT_SUPPLEMENT_COMMIT)
    ap.add_argument("--aux-list")
    ap.add_argument("--repo",
                    help="xs-signoff repo (只读 git show) 用于提交态复核")
    a = ap.parse_args()
    A = a.archive
    RC = a.rc_commit
    SUPP = a.supplement_commit

    if not os.path.isdir(A):
        viol("archive_dir_missing: %s" % A)
        finish()

    repo = None
    if a.repo:
        try:
            pr = subprocess.run(
                ["git", "-C", a.repo, "rev-parse", "--verify",
                 "%s^{commit}" % RC],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            probe_ok = (pr.returncode == 0)
        except OSError:
            probe_ok = False
        if not probe_ok:
            warn("repo_unusable: %s (RC commit 不可解析, 降级为无 repo 模式)"
                 % a.repo)
        else:
            repo = a.repo

    def commit_ok(got, want):
        if len(want) == 40:
            return got == want
        return got.startswith(want)

    # ================= A. 封装 =================
    for dp, dn, fn in os.walk(A):
        for n in dn + fn:
            if os.path.islink(os.path.join(dp, n)):
                viol("symlink: %s" % os.path.relpath(os.path.join(dp, n), A))
    mf = os.path.join(A, "ARCHIVE_MANIFEST.tsv")
    comp = os.path.join(A, "COMPLETE")
    if not (os.path.isfile(mf) and os.path.isfile(comp)):
        viol("missing_envelope: ARCHIVE_MANIFEST.tsv/COMPLETE")
    else:
        if read_text(comp).strip() != sha(mf):
            viol("COMPLETE != sha256(ARCHIVE_MANIFEST.tsv)")
        listed = {}
        for i, ln in enumerate(read_text(mf).splitlines()):
            if not ln.strip():
                continue
            parts = ln.split("\t")
            if len(parts) != 3:
                viol("archive_manifest_bad_row: L%d" % (i + 1))
                continue
            p, sz, h = parts
            if p.startswith("/") or ".." in p.split("/"):
                viol("bad_path: %s" % p)
            if p in listed:
                viol("dup_path: %s" % p)
            try:
                listed[p] = (int(sz), h)
            except ValueError:
                viol("archive_manifest_bad_size: %s" % p)
        actual = set()
        for dp, dn, fn in os.walk(A):
            for n in fn:
                rp = os.path.relpath(os.path.join(dp, n), A)
                if rp in ("ARCHIVE_MANIFEST.tsv", "COMPLETE"):
                    continue
                actual.add(rp)
        for p in sorted(set(listed) - actual):
            viol("manifest_lists_missing_file: %s" % p)
        for p in sorted(actual - set(listed)):
            viol("file_not_in_manifest: %s" % p)
        for p in sorted(set(listed) & actual):
            fp = os.path.join(A, p)
            if os.path.getsize(fp) != listed[p][0] or sha(fp) != listed[p][1]:
                viol("hash_or_size_drift: %s" % p)

    # ================= B. main target set 精确 306 =================
    m305_path = os.path.join(A, "manifests/manifest_305.json")
    m2_path = os.path.join(A, "manifests/manifest_306_v2.json")
    cfg305 = {}
    m2cfg = {}
    if not os.path.isfile(m305_path):
        viol("manifest_305_missing")
    else:
        try:
            m305 = json.load(open(m305_path))
            ent305 = m305["entries"] if isinstance(m305, dict) else m305
            seen = set()
            for e in ent305:
                t = e.get("target", "?")
                if t in seen:
                    viol("m305_duplicate_target: %s" % t)
                seen.add(t)
                if e.get("config_status") != "UNCONFIGURED":
                    cfg305[t] = e
        except (ValueError, KeyError) as ex:
            viol("manifest_305_parse: %s" % ex)
    if cfg305:
        if len(cfg305) != 305:
            viol("m305_configured=%d!=305" % len(cfg305))
        if "Rob" in cfg305:
            viol("m305_configured_contains_Rob")
    if not os.path.isfile(m2_path):
        viol("manifest_306_v2_missing")
    else:
        try:
            m2 = json.load(open(m2_path))
            m2cfg = {e["target"]: e for e in m2["entries"]
                     if e.get("config_status") == "CONFIGURED"}
        except (ValueError, KeyError) as ex:
            viol("manifest_306_v2_parse: %s" % ex)
    if m2cfg:
        if len(m2cfg) != 306:
            viol("v2_configured=%d!=306" % len(m2cfg))
        if cfg305:
            want306 = set(cfg305) | {"Rob"}
            if set(m2cfg) != want306:
                only2 = sorted(set(m2cfg) - want306)[:5]
                only5 = sorted(want306 - set(m2cfg))[:5]
                viol("v2_vs_305_set_mismatch: v2only=%s 305only=%s"
                     % (only2, only5))

    tdir = os.path.join(A, "targets")
    tdirs = set()
    if not os.path.isdir(tdir):
        viol("targets_dir_missing")
    else:
        for n in sorted(os.listdir(tdir)):
            if not os.path.isdir(os.path.join(tdir, n)):
                viol("targets_stray_file: %s" % n)
            else:
                tdirs.add(n)
    if "Rob" in tdirs:
        viol("targets_contains_Rob (Rob 须由 rob/ 表达)")
    want = set(cfg305)
    for t in sorted(want - tdirs):
        viol("receipt_missing: %s" % t)
    for t in sorted(tdirs - want):
        viol("receipt_extra: %s" % t)

    m305_sha = sha(m305_path) if os.path.isfile(m305_path) else "-"
    maux_path = os.path.join(A, "manifests/manifest_aux.json")
    maux_sha = sha(maux_path) if os.path.isfile(maux_path) else "-"

    # ---------- receipt 通检 ----------
    def check_receipt(d, tag, req_verdict, want_manifest_sha, want_commit):
        """returns parsed RESULT text ('' 若缺)."""
        missing = [f for f in RECEIPT_REQUIRED
                   if not os.path.isfile(os.path.join(d, f))]
        for f in missing:
            viol("%s: receipt_missing_file %s" % (tag, f))
        cm = os.path.join(d, "COMPLETE")
        mm = os.path.join(d, "MANIFEST.tsv")
        if os.path.isfile(cm) and os.path.isfile(mm):
            if read_text(cm).strip() != sha(mm):
                viol("%s: COMPLETE!=sha(MANIFEST.tsv)" % tag)
            rows = {}
            for i, ln in enumerate(read_text(mm).splitlines()):
                if not ln.strip() or ln.startswith("#"):
                    continue
                parts = ln.split("\t")
                if len(parts) != 3:
                    viol("%s: receipt_manifest_bad_row L%d" % (tag, i + 1))
                    continue
                p, sz, h = parts
                if p in rows:
                    viol("%s: receipt_manifest_dup %s" % (tag, p))
                try:
                    rows[p] = (int(sz), h)
                except ValueError:
                    viol("%s: receipt_manifest_bad_size %s" % (tag, p))
            present = set(n for n in os.listdir(d)
                          if os.path.isfile(os.path.join(d, n))
                          and n not in ("COMPLETE", "MANIFEST.tsv"))
            for p in sorted(set(rows) - present):
                viol("%s: receipt_file_missing %s" % (tag, p))
            for p in sorted(present - set(rows)):
                viol("%s: receipt_file_unlisted %s" % (tag, p))
            for p in sorted(set(rows) & present):
                fp = os.path.join(d, p)
                if (os.path.getsize(fp) != rows[p][0]
                        or sha(fp) != rows[p][1]):
                    viol("%s: receipt_file_drift %s" % (tag, p))
        rrc_p = os.path.join(d, "RUNNER_RC")
        rrc = read_text(rrc_p).strip() if os.path.isfile(rrc_p) else "MISSING"
        if rrc != "0":
            viol("%s: RUNNER_RC=%s" % (tag, rrc))
        res_p = os.path.join(d, "RESULT.txt")
        res = read_text(res_p) if os.path.isfile(res_p) else ""
        m = re.search(r"SIGNOFF_RESULT \S+: measured=(\S+) required=(\S+) "
                      r"gate=(\S+)", res)
        if not m:
            viol("%s: RESULT_no_signoff_line" % tag)
        else:
            meas, r_req, gate = m.groups()
            if gate != "PASS" or meas != r_req or meas != req_verdict:
                viol("%s: verdict measured=%s required_result=%s "
                     "manifest_required=%s gate=%s"
                     % (tag, meas, r_req, req_verdict, gate))
        mi = re.search(r"impl_commit: (\S+)", res)
        if not mi or not commit_ok(mi.group(1), want_commit):
            viol("%s: impl_commit=%s!=%s"
                 % (tag, mi.group(1) if mi else "?", want_commit))
        ms = re.search(r"manifest_sha256: (\S+)", res)
        if want_manifest_sha != "-" and (not ms
                                         or ms.group(1) != want_manifest_sha):
            viol("%s: manifest_sha_mismatch" % tag)
        return res

    # ================= C. per-receipt (305 shard) =================
    for t in sorted(tdirs & want):
        check_receipt(os.path.join(A, "targets", t), t,
                      cfg305[t].get("required_verdict", "?"), m305_sha, RC)

    # ================= D. Rob partitioned =================
    robd = os.path.join(A, "rob")
    rob_v2 = m2cfg.get("Rob", {})
    if not os.path.isdir(robd):
        viol("rob_dir_missing")
    else:
        parts = set(n for n in os.listdir(robd)
                    if n.startswith("part.")
                    and os.path.isdir(os.path.join(robd, n)))
        for p in [p for p in ROB_PARTS if p not in parts]:
            viol("rob_parts_missing: %s" % p)
        for p in sorted(parts - set(ROB_PARTS)):
            viol("rob_parts_extra: %s" % p)
        for p in sorted(parts & set(ROB_PARTS)):
            pd = os.path.join(robd, p)
            rrc_p = os.path.join(pd, "RUNNER_RC")
            rrc = (read_text(rrc_p).strip() if os.path.isfile(rrc_p)
                   else "MISSING")
            if rrc != "0":
                viol("rob_part_runner_rc: %s=%s" % (p, rrc))
            fml = os.path.join(pd, "fm.log")
            if not os.path.isfile(fml):
                viol("rob_part_fmlog_missing: %s" % p)
            elif "Verification SUCCEEDED" not in read_text(fml):
                viol("rob_part_fmlog_no_succeeded: %s" % p)
        ur = os.path.join(robd, "UNION_RECORD.tsv")
        canon_lines = None
        if not os.path.isfile(ur):
            viol("rob_union_record_missing")
        else:
            canon_lines = read_text(ur).splitlines()
            if rob_v2:
                if sha(ur) != rob_v2.get("derivative_id"):
                    viol("rob_union_sha_mismatch: sha(UNION_RECORD.tsv)!="
                         "v2_derivative_id")
            else:
                viol("rob_v2_entry_missing (无法核对 derivative_id)")
            if not any(l.startswith("UNION_STATUS\t") and "PASS" in l
                       for l in canon_lines):
                viol("rob_union_status_not_pass")
        fresh = os.path.join(robd, "UNION_RECORD.rc3-fresh.tsv")
        if not os.path.isfile(fresh):
            viol("rob_fresh_missing: UNION_RECORD.rc3-fresh.tsv")
        else:
            fresh_lines = read_text(fresh).splitlines()
            if not any(l.startswith("UNION_STATUS\t") and "PASS" in l
                       for l in fresh_lines):
                viol("rob_fresh_union_status_not_pass")
            if canon_lines is not None:
                cf = [l for l in canon_lines
                      if not l.startswith("# generated")]
                ff = [l for l in fresh_lines
                      if not l.startswith("# generated")]
                if cf != ff:
                    n = None
                    for i in range(min(len(cf), len(ff))):
                        if cf[i] != ff[i]:
                            n = i
                            break
                    if n is None:
                        viol("rob_fresh_diff: line_count %d!=%d"
                             % (len(cf), len(ff)))
                    else:
                        viol("rob_fresh_diff: first_diff_at_filtered_line %d "
                             "canonical=%r fresh=%r"
                             % (n + 1, cf[n][:80], ff[n][:80]))

    # ================= E. aux 精确 16 =================
    if a.aux_list:
        aux_want = set(l.strip() for l in open(a.aux_list)
                       if l.strip() and not l.startswith("#"))
    else:
        aux_want = set(AUX16_DEFAULT)
    if len(aux_want) != 16:
        warn("aux_want_count=%d!=16 (--aux-list 覆盖)" % len(aux_want))
    auxd = os.path.join(A, "aux")
    adirs = set()
    if not os.path.isdir(auxd):
        viol("aux_dir_missing")
    else:
        for n in sorted(os.listdir(auxd)):
            if not os.path.isdir(os.path.join(auxd, n)):
                viol("aux_stray_file: %s" % n)
            else:
                adirs.add(n)
    for t in sorted(aux_want - adirs):
        viol("aux_receipt_missing: %s" % t)
    for t in sorted(adirs - aux_want):
        viol("aux_receipt_extra: %s" % t)
    am = {}
    if os.path.isfile(maux_path):
        try:
            am = {e["target"]: e
                  for e in json.load(open(maux_path))["entries"]}
        except (ValueError, KeyError) as ex:
            viol("manifest_aux_parse: %s" % ex)
    else:
        viol("manifest_aux_missing")
    for t in sorted(adirs & aux_want):
        if t in am:
            check_receipt(os.path.join(A, "aux", t), "aux:%s" % t,
                          am[t].get("required_verdict", "?"), maux_sha, RC)
        else:
            viol("aux:%s: not_in_manifest_aux" % t)

    # ================= F. aux-supplement 精确 4 =================
    sdir = os.path.join(A, "aux-supplement")
    sdirs = set()
    if not os.path.isdir(sdir):
        viol("aux_supplement_dir_missing")
    else:
        for n in sorted(os.listdir(sdir)):
            if not os.path.isdir(os.path.join(sdir, n)):
                viol("supp_stray_file: %s" % n)
            else:
                sdirs.add(n)
    for t in [t for t in SUPP4 if t not in sdirs]:
        viol("supp_receipt_missing: %s" % t)
    for t in sorted(sdirs - set(SUPP4)):
        viol("supp_receipt_extra: %s" % t)

    supp_verdict_sha = {}   # target -> 实际 sha256(verdict.sidecar.json)
    for t in sorted(sdirs & set(SUPP4)):
        d = os.path.join(sdir, t)
        tag = "supp:%s" % t
        req = am[t].get("required_verdict", "SUCCEEDED") if t in am \
            else "SUCCEEDED"
        if req != "SUCCEEDED":
            viol("%s: manifest_aux_required=%s!=SUCCEEDED" % (tag, req))
        res = check_receipt(d, tag, "SUCCEEDED", maux_sha, SUPP)
        # --- TOOLS.tsv: runner/validator 覆盖 + allow/dead_ref 行 ---
        tools_p = os.path.join(d, "TOOLS.tsv")
        if os.path.isfile(tools_p):
            infra_bases = set()
            rows = {}
            tools_impl = None
            for ln in read_text(tools_p).splitlines():
                if not ln.strip() or ln.startswith("#") \
                        or ln.startswith("kind\t"):
                    continue
                parts = ln.split("\t")
                if len(parts) < 2:
                    continue
                if parts[0] == "infra":
                    infra_bases.add(os.path.basename(parts[1]))
                else:
                    rows.setdefault(parts[0], parts[1])
                if parts[0] == "impl_commit":
                    tools_impl = parts[1]
            if "run_signoff_target.sh" not in infra_bases:
                viol("%s: tools_missing_runner" % tag)
            if "fm_sidecar_verdict.py" not in infra_bases:
                viol("%s: tools_missing_validator" % tag)
            for key in ("allow_ref", "dead_ref"):
                if key not in rows:
                    viol("%s: tools_missing_row %s" % (tag, key))
                else:
                    v = rows[key]
                    man_v = am[t].get(key, "") if t in am else ""
                    ok_vals = {"-", ""} if man_v in ("", "-") else {man_v}
                    if v not in ok_vals:
                        viol("%s: tools_%s_unreasonable %r (manifest=%r)"
                             % (tag, key, v, man_v))
            if tools_impl is not None and not commit_ok(tools_impl, SUPP):
                viol("%s: tools_impl_commit=%s!=%s" % (tag, tools_impl, SUPP))
        # --- allow.json 四类全空 (strict) ---
        aj = os.path.join(d, "allow.json")
        if os.path.isfile(aj):
            try:
                aw = json.load(open(aj))
                nonempty = [k for k, v in sorted(aw.items()) if v]
                if nonempty:
                    viol("%s: allow_json_nonempty %s" % (tag, nonempty))
            except ValueError as ex:
                viol("%s: allow_json_parse %s" % (tag, ex))
        # --- verdict.sidecar.json 语义 ---
        vs = os.path.join(d, "verdict.sidecar.json")
        if os.path.isfile(vs):
            supp_verdict_sha[t] = sha(vs)
            try:
                sc = json.load(open(vs))
            except ValueError as ex:
                viol("%s: sidecar_parse %s" % (tag, ex))
                sc = {}
            if sc:
                if sc.get("native_verdict") != "SUCCEEDED":
                    viol("%s: sidecar_native_verdict=%s"
                         % (tag, sc.get("native_verdict")))
                st = sc.get("stats", {})
                for k in ("failing", "unverified", "aborted",
                          "unread_notcompared"):
                    if st.get(k, "MISSING") != 0:
                        viol("%s: sidecar_stats_nonzero %s=%s"
                             % (tag, k, st.get(k, "MISSING")))
                um = sc.get("unmatched", {})
                um_keys = ("compare_ref", "compare_impl", "unread_ref",
                           "unread_impl", "bbout_ref", "bbout_impl")
                if set(um.keys()) != set(um_keys):
                    viol("%s: sidecar_unmatched_keys=%s"
                         % (tag, sorted(um.keys())))
                for k in um_keys:
                    if um.get(k, "MISSING") != 0:
                        viol("%s: sidecar_unmatched_nonzero %s=%s"
                             % (tag, k, um.get(k, "MISSING")))
                av = sc.get("entry_appvars", {})
                if av.get("verification_verify_matched_unread_compare_points") \
                        != "true":
                    viol("%s: sidecar_vmucp_not_true (=%r)" % (tag, av.get(
                        "verification_verify_matched_unread_compare_points")))

    # --- supplement/SUPPLEMENT.tsv ---
    stsv = os.path.join(A, "supplement/SUPPLEMENT.tsv")
    if not os.path.isfile(stsv):
        viol("supplement_tsv_missing")
    else:
        srows = {}
        for ln in read_text(stsv).splitlines():
            if not ln.strip() or ln.startswith("#") \
                    or ln.startswith("target\t"):
                continue
            parts = ln.split("\t")
            if len(parts) < 5:
                viol("supplement_tsv_bad_row: %r" % ln[:60])
                continue
            t = parts[0]
            if t in srows:
                viol("supplement_tsv_dup: %s" % t)
            srows[t] = parts
        for t in [t for t in SUPP4 if t not in srows]:
            viol("supplement_tsv_row_missing: %s" % t)
        for t in sorted(set(srows) - set(SUPP4)):
            viol("supplement_tsv_row_extra: %s" % t)
        for t in [t for t in SUPP4 if t in srows]:
            _, ic, gate, _passing, ev = srows[t][:5]
            if not commit_ok(ic, SUPP):
                viol("supplement_tsv_impl_commit: %s=%s!=%s" % (t, ic, SUPP))
            if gate != "PASS":
                viol("supplement_tsv_gate: %s=%s" % (t, gate))
            if not os.path.isdir(os.path.join(A, ev.rstrip("/"))):
                viol("supplement_tsv_evidence_missing: %s=%s" % (t, ev))

    # ================= G. MSHRCtl dependency closure =================
    cl_p = os.path.join(A, "supplement/MSHRCTL_DEPENDENCY_CLOSURE.tsv")
    if not os.path.isfile(cl_p):
        viol("closure_missing_file: supplement/MSHRCTL_DEPENDENCY_CLOSURE.tsv")
    else:
        cl_rc3 = cl_supp = None
        edges = []            # (target, sha)
        mshr_rows = []        # (path, sha)
        for ln in read_text(cl_p).splitlines():
            if not ln.strip() or ln.startswith("#"):
                continue
            parts = ln.split("\t")
            if parts[0] == "rc3_commit" and len(parts) >= 2:
                cl_rc3 = parts[1]
            elif parts[0] == "supplement_commit" and len(parts) >= 2:
                cl_supp = parts[1]
            elif parts[0] == "edge":
                if len(parts) >= 3:
                    edges.append((parts[1], parts[2]))
                else:
                    viol("closure_edge_bad_row: %r" % ln[:60])
            elif parts[0] == "mshrctl_receipt":
                if len(parts) >= 3:
                    mshr_rows.append((parts[1], parts[2]))
                else:
                    viol("closure_mshrctl_bad_row: %r" % ln[:60])
        if cl_rc3 is None or not commit_ok(cl_rc3, RC):
            viol("closure_rc3_commit_mismatch: %s!=%s" % (cl_rc3, RC))
        if cl_supp is None or not commit_ok(cl_supp, SUPP):
            viol("closure_supplement_commit_mismatch: %s!=%s"
                 % (cl_supp, SUPP))
        etargets = [t for t, _ in edges]
        for t in sorted(set(etargets)):
            if etargets.count(t) > 1:
                viol("closure_edge_dup: %s" % t)
        for t in [t for t in SUPP4 if t not in etargets]:
            viol("closure_edge_missing: %s" % t)
        for t in sorted(set(etargets) - set(SUPP4)):
            viol("closure_edge_extra: %s" % t)
        for t, h in edges:
            if t not in SUPP4:
                continue
            vp = os.path.join(A, "aux-supplement", t, "verdict.sidecar.json")
            if not os.path.isfile(vp):
                viol("closure_edge_receipt_missing: %s" % t)
            elif sha(vp) != h:
                viol("closure_edge_sha_mismatch: %s recorded=%s actual=%s"
                     % (t, h[:16], sha(vp)[:16]))
        if not mshr_rows:
            viol("closure_mshrctl_receipt_row_missing")
        else:
            if len(mshr_rows) > 1:
                viol("closure_mshrctl_receipt_dup")
            p, h = mshr_rows[0]
            if p != "targets/MSHRCtl/verdict.sidecar.json":
                viol("closure_mshrctl_receipt_path: %s" % p)
            fp = os.path.join(A, p)
            if not os.path.isfile(fp):
                viol("closure_mshrctl_receipt_file_missing: %s" % p)
            elif sha(fp) != h:
                viol("closure_mshrctl_sha_mismatch: recorded=%s actual=%s"
                     % (h[:16], sha(fp)[:16]))

    # ================= H. CLOSURE_MANIFEST.tsv =================
    cm_p = os.path.join(A, "supplement/CLOSURE_MANIFEST.tsv")
    if not os.path.isfile(cm_p):
        viol("cm_missing: supplement/CLOSURE_MANIFEST.tsv")
    else:
        cm_lines = read_text(cm_p).splitlines()
        if not cm_lines or not cm_lines[0].startswith("#"):
            viol("cm_header_not_comment")
        else:
            hdr = cm_lines[0]
            if RC not in hdr:
                viol("cm_header_no_rc3_commit")
            if SUPP not in hdr:
                viol("cm_header_no_supplement_commit")
        cm_rows = []   # (path, rc3sha, suppsha, dispo)
        seen_paths = set()
        for i, ln in enumerate(cm_lines):
            if not ln.strip() or ln.startswith("#"):
                continue
            parts = ln.split("\t")
            if len(parts) != 4:
                viol("cm_row_bad: L%d" % (i + 1))
                continue
            p, r3, sp, dispo = parts
            if dispo not in ("added", "modified", "unchanged-sample"):
                viol("cm_disposition_bad: %s=%s" % (p, dispo))
                continue
            if p in seen_paths:
                viol("cm_row_dup: %s" % p)
            seen_paths.add(p)
            cm_rows.append((p, r3, sp, dispo))
        changed = set(p for p, _, _, d in cm_rows
                      if d in ("added", "modified"))
        for p in [p for p in CHANGED4 if p not in changed]:
            viol("cm_changed_missing: %s" % p)
        for p in sorted(changed - set(CHANGED4)):
            viol("cm_changed_extra: %s" % p)
        for p, r3, sp, dispo in cm_rows:
            # 记录形状自洽
            if dispo == "added":
                if r3 not in ("-", ""):
                    viol("cm_selfcheck: %s added_but_rc3_sha=%s" % (p, r3))
                if not HEX64.match(sp):
                    viol("cm_selfcheck: %s bad_supp_sha" % p)
            elif dispo == "modified":
                if not HEX64.match(r3) or not HEX64.match(sp):
                    viol("cm_selfcheck: %s bad_sha_fields" % p)
                elif r3 == sp:
                    viol("cm_selfcheck: %s modified_but_equal_sha" % p)
            else:  # unchanged-sample
                if not HEX64.match(r3) or r3 != sp:
                    viol("cm_selfcheck: %s unchanged_but_sha_differs" % p)
            if repo:
                g3 = git_blob_sha256(repo, RC, p)
                gs = git_blob_sha256(repo, SUPP, p)
                if dispo == "added":
                    if g3 is not None:
                        viol("cm_sha_mismatch: %s added_but_exists_at_rc3" % p)
                    if gs is None:
                        viol("cm_sha_mismatch: %s missing_at_supplement" % p)
                    elif gs != sp:
                        viol("cm_sha_mismatch: %s supp recorded=%s git=%s"
                             % (p, sp[:16], gs[:16]))
                else:
                    if g3 is None:
                        viol("cm_sha_mismatch: %s missing_at_rc3" % p)
                    elif g3 != r3:
                        viol("cm_sha_mismatch: %s rc3 recorded=%s git=%s"
                             % (p, r3[:16], g3[:16]))
                    if gs is None:
                        viol("cm_sha_mismatch: %s missing_at_supplement" % p)
                    elif gs != sp:
                        viol("cm_sha_mismatch: %s supp recorded=%s git=%s"
                             % (p, sp[:16], gs[:16]))
        if not repo:
            warn("cm_repo_degraded: 无 --repo, CLOSURE_MANIFEST 仅做记录内部"
                 "自洽校验")
        # 与实际 diff 集一致性 (repo 模式): git diff --name-only RC..SUPP
        if repo:
            try:
                pr = subprocess.run(
                    ["git", "-C", repo, "diff", "--name-only", RC, SUPP],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                    universal_newlines=True)
                if pr.returncode == 0:
                    actual_diff = set(l for l in pr.stdout.splitlines()
                                      if l.strip())
                    for p in sorted(actual_diff - changed):
                        viol("cm_diff_uncovered: %s (在 git diff 中但未记为 "
                             "added/modified)" % p)
                    for p in sorted(changed - actual_diff):
                        viol("cm_diff_phantom: %s (记为变更但 git diff 无)"
                             % p)
                else:
                    warn("cm_git_diff_failed rc=%d" % pr.returncode)
            except OSError as ex:
                warn("cm_git_diff_error: %s" % ex)

    # ================= I. tooling provenance =================
    tld = os.path.join(A, "tooling")
    if not os.path.isdir(tld):
        for n in TOOLING_FILES:
            viol("tooling_missing: tooling/%s" % n)
    else:
        for n in TOOLING_FILES:
            fp = os.path.join(tld, n)
            if not os.path.isfile(fp):
                viol("tooling_missing: tooling/%s" % n)
                continue
            if repo:
                rp = "%s/%s" % (TOOLING_REPO_DIR, n)
                gs = git_blob_sha256(repo, SUPP, rp)
                if gs is None:
                    gs = git_blob_sha256(repo, RC, rp)
                if gs is None:
                    warn("tooling_not_in_repo: %s (supplement/RC3 两提交均无 "
                         "%s)" % (n, rp))
                elif gs != sha(fp):
                    viol("tooling_repo_mismatch: %s archive=%s git=%s"
                         % (n, sha(fp)[:16], gs[:16]))

    # ================= J. RC.txt =================
    rc_p = os.path.join(A, "RC.txt")
    if not os.path.isfile(rc_p):
        viol("rc_txt_missing")
    else:
        rc_commit_seen = None
        for ln in read_text(rc_p).splitlines():
            parts = ln.split("\t")
            if parts[0] == "rc_commit" and len(parts) >= 2:
                rc_commit_seen = parts[1]
            elif parts[0] == "manifest_sha256" and len(parts) >= 3:
                fp = os.path.join(A, "manifests", parts[1])
                if not os.path.isfile(fp):
                    viol("rc_manifest_row_missing_file: %s" % parts[1])
                elif sha(fp) != parts[2]:
                    viol("rc_manifest_row_mismatch: %s" % parts[1])
        if rc_commit_seen is None or not commit_ok(rc_commit_seen, RC):
            viol("rc_commit_mismatch: RC.txt=%s!=%s" % (rc_commit_seen, RC))

    # ================= K. manifests 提交态一致 (--repo) =================
    if repo:
        for name, rpath in sorted(MANIFEST_REPO_MAP.items()):
            fp = os.path.join(A, "manifests", name)
            if not os.path.isfile(fp):
                viol("manifest_file_missing: %s" % name)
                continue
            gb = git_blob_bytes(repo, RC, rpath)
            if gb is None:
                viol("manifest_commit_state_drift: %s 在 RC3 提交无 %s"
                     % (name, rpath))
            else:
                with open(fp, "rb") as f:
                    if f.read() != gb:
                        viol("manifest_commit_state_drift: %s != git show "
                             "RC3:%s" % (name, rpath))
        for dname in ("allow", "dead_ref"):
            ad = os.path.join(A, "manifests", dname)
            arch_set = set(os.listdir(ad)) if os.path.isdir(ad) else set()
            git_files = git_ls_tree(repo, RC, "verif/signoff/%s/" % dname)
            if git_files is None:
                warn("%s_dir_ls_tree_failed" % dname)
                continue
            git_map = dict((os.path.basename(p), p) for p in git_files)
            for n in sorted(set(git_map) - arch_set):
                viol("%s_dir_drift: missing_in_archive %s" % (dname, n))
            for n in sorted(arch_set - set(git_map)):
                viol("%s_dir_drift: extra_in_archive %s" % (dname, n))
            for n in sorted(arch_set & set(git_map)):
                gb = git_blob_bytes(repo, RC, git_map[n])
                with open(os.path.join(ad, n), "rb") as f:
                    if gb is None or f.read() != gb:
                        viol("%s_dir_drift: bytes %s" % (dname, n))
    else:
        warn("no_repo: manifests 提交态/CLOSURE_MANIFEST git 复算/tooling "
             "提交态检查被降级")

    # ================= L. reconcile =================
    rp = os.path.join(A, "reconcile/reconcile_v2_306.txt")
    if not os.path.isfile(rp) or "RECONCILE_DIFF=0" not in read_text(rp):
        viol("reconcile_v2_306: missing_or_DIFF!=0")

    # ================= M. 守恒 (combined_ledger vs v2 manifest) ==========
    led_p = os.path.join(A, "manifests/combined_ledger.tsv")
    if not os.path.isfile(led_p):
        viol("cons_ledger_missing")
    elif m2cfg:
        led = {}
        for i, ln in enumerate(read_text(led_p).splitlines()):
            if not ln.strip() or ln.startswith("#") \
                    or ln.startswith("target\t"):
                continue
            parts = ln.split("\t")
            if len(parts) < 3:
                viol("cons_ledger_row_short: L%d" % (i + 1))
                continue
            t, measured, cls = parts[0], parts[1], parts[2]
            if t in led:
                viol("cons_ledger_duplicate: %s" % t)
            led[t] = (measured, cls)
        for t in sorted(set(led) - set(m2cfg)):
            viol("cons_ledger_target_not_in_manifest: %s" % t)
        for t in sorted(set(m2cfg) - set(led)):
            viol("cons_manifest_target_not_in_ledger: %s" % t)
        n_succ = n_pdr = n_part = 0
        for t in sorted(set(led) & set(m2cfg)):
            measured, cls = led[t]
            req = m2cfg[t].get("required_verdict")
            if measured == "SUCCEEDED":
                n_succ += 1
            elif measured == "PASS_DEAD_REF":
                n_pdr += 1
            elif measured == "PARTITIONED_SUCCEEDED":
                n_part += 1
            else:
                viol("cons_unknown_measured: %s=%s" % (t, measured))
            if measured != req:
                viol("cons_measured_required_mismatch: %s ledger=%s "
                     "manifest=%s" % (t, measured, req))
            if cls not in ("SIGNOFF_PASS", "PARTITIONED_SUCCEEDED"):
                viol("cons_unknown_class: %s=%s" % (t, cls))
        print("# 守恒: SUCCEEDED=%d PASS_DEAD_REF=%d PARTITIONED=%d "
              "sum=%d 期望=%d" % (n_succ, n_pdr, n_part,
                                  n_succ + n_pdr + n_part, len(m2cfg)))
        if n_succ + n_pdr + n_part != len(m2cfg):
            viol("cons_sum_mismatch: %d!=%d"
                 % (n_succ + n_pdr + n_part, len(m2cfg)))

    finish()


def finish():
    for w in warns:
        print("WARN\t" + w)
    for e in errs:
        print("VIOL\t" + e)
    print("ARCHIVE_WARNINGS=%d" % len(warns))
    print("ARCHIVE_VIOLATIONS=%d" % len(errs))
    sys.exit(min(len(errs), 120))


if __name__ == "__main__":
    main()
