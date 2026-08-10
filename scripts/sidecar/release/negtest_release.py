#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""RC3 release archive 伪造负测集 (Lane A, codex 0137 §1).

原理: 原 archive 只读(chmod a-w)——绝不改原件. 流程:
  1. base 准备: cp -a 拷贝原 archive → chmod -R u+w → "integrator 补件仿真"
     (可选, --no-repair 关闭):
       - supplement/MSHRCTL_DEPENDENCY_CLOSURE.tsv 追加机器格式行:
         edge\t<FastArbiter_N>\t<sha256(aux-supplement/<t>/verdict.sidecar.json)> ×4
         mshrctl_receipt\ttargets/MSHRCtl/verdict.sidecar.json\t<sha>
       - supplement/CLOSURE_MANIFEST.tsv 依 git 复算两 commit blob sha 生成
         (首行注释含两全 sha; 行: path\trc3\tsupp\tdisposition)
       - tooling/{build_release_archive.sh,verify_release_archive.py,
         negtest_release.py}
       - 重封 ARCHIVE_MANIFEST.tsv + COMPLETE
  2. base 正样本跑 verifier, 断言 0 violations (integrator 真补件后, 用
     --no-repair 直接对成品 archive 终验).
  3. 逐负测: cp -al base → 篡改 → **重封 envelope** (模拟攻击者 reseal, 逼
     语义检查而非只靠外层完整性抓包) → 跑 verifier → 断言非零 violations 且
     预期违例模式出现.

负测清单 (0137 §1):
  a  删一份 supplement receipt (aux-supplement/FastArbiter_5)
  b  改 supplement receipt 一个字节 (FastArbiter_4 verdict json passing 144→145)
  c  多加一份伪造 supplement receipt (FastArbiter_45)
  d  closure 文件 supplement_commit 改错
  e  删一条 MSHRCtl edge (FastArbiter_7)
  f1 rob 加 part.extra 目录
  f2 rob 删 part.lsq
  g  篡改 UNION_RECORD.rc3-fresh.tsv 一行 (golden_src_sha256 翻一位)
  h  CLOSURE_MANIFEST 记录与实际 diff 不符 (改一行 supplement_sha256)

每负测输出 PASS(=verifier 抓到预期违例)/FAIL. 退出码 = FAIL 数
(+baseline 非零算 1). python3.6 兼容 (无 capture_output).

用法:
  negtest_release.py [--archive DIR] [--rc SHA] [--supplement-commit SHA]
      [--repo DIR] [--work DIR] [--verifier PATH] [--builder PATH]
      [--cases a,b,...] [--keep] [--no-repair] [--baseline-only]
"""
import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

DEF_ARCHIVE = "/tmp/release-306-rc3-05787b17"
DEF_RC = "05787b17261d471c2452b0877d0c9a5c8892fef1"
DEF_SUPP = "0a25fc916ec782d50e4a8749c5d26530b21d3f18"
DEF_REPO = "/home/eda/xs-env/xs-signoff"
DEF_WORK = "/tmp/rc3-tooling/negtest-work"
DEF_BUILDER = "/tmp/rc2-prep/laneD/build_release_archive.sh"

SUPP4 = ["FastArbiter_4", "FastArbiter_5", "FastArbiter_7", "FastArbiter_8"]
CHANGED4 = [
    ("scripts/sidecar/run_signoff_target.sh", "modified"),
    ("scripts/sidecar/fm_sidecar_verdict.py", "modified"),
    ("scripts/sidecar/gen_305_manifest.py", "modified"),
    ("verif/signoff/supplement/fastarbiter_whitelist_negtest.py", "added"),
]


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def run(cmd, **kw):
    return subprocess.run(cmd, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT,
                          universal_newlines=True, **kw)


def die(msg):
    print("NEGTEST_ABORT\t%s" % msg)
    sys.exit(2)


def replace_file(path, data):
    """unlink+write: 绝不 in-place 写 (hardlink 安全)."""
    if os.path.exists(path):
        os.unlink(path)
    mode = "w" if isinstance(data, str) else "wb"
    with open(path, mode) as f:
        f.write(data)


def read_text(p):
    with open(p, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def git_blob_sha256(repo, commit, path):
    pr = subprocess.run(["git", "-C", repo, "show",
                         "%s:%s" % (commit, path)],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if pr.returncode != 0:
        return None
    return hashlib.sha256(pr.stdout).hexdigest()


def copy_tree(src, dst, hardlink=False):
    flags = "-al" if hardlink else "-a"
    pr = run(["cp", flags, src, dst])
    if pr.returncode != 0:
        die("copy_tree %s -> %s rc=%d: %s"
            % (src, dst, pr.returncode, pr.stdout[-300:]))


def make_writable_dirs(root):
    """只 chmod 目录(u+w); 文件保持原 perm(全拷贝时另行处理)."""
    for dp, dn, fn in os.walk(root):
        os.chmod(dp, os.stat(dp).st_mode | 0o200)


def reseal(root):
    """重生 ARCHIVE_MANIFEST.tsv + COMPLETE (攻击者视角的干净重封)."""
    rows = []
    for dp, dn, fn in os.walk(root):
        for n in fn:
            fp = os.path.join(dp, n)
            rp = os.path.relpath(fp, root)
            if rp in ("ARCHIVE_MANIFEST.tsv", "COMPLETE"):
                continue
            rows.append((rp, os.path.getsize(fp), sha(fp)))
    rows.sort(key=lambda r: r[0])
    mf = os.path.join(root, "ARCHIVE_MANIFEST.tsv")
    replace_file(mf, "".join("%s\t%d\t%s\n" % r for r in rows))
    replace_file(os.path.join(root, "COMPLETE"), sha(mf) + "\n")


def repair(base, rc, supp, repo, builder):
    """仿真 integrator 补件, 使 base 成为规范正样本."""
    # 1) closure 机器格式行
    cl = os.path.join(base, "supplement/MSHRCTL_DEPENDENCY_CLOSURE.tsv")
    txt = read_text(cl)
    keep = [l for l in txt.splitlines()
            if not l.startswith("edge\t")
            and not l.startswith("mshrctl_receipt\t")]
    lines = list(keep)
    for t in SUPP4:
        vp = os.path.join(base, "aux-supplement", t, "verdict.sidecar.json")
        lines.append("edge\t%s\t%s" % (t, sha(vp)))
    mp = os.path.join(base, "targets/MSHRCtl/verdict.sidecar.json")
    lines.append("mshrctl_receipt\ttargets/MSHRCtl/verdict.sidecar.json\t%s"
                 % sha(mp))
    replace_file(cl, "\n".join(lines) + "\n")
    # 2) CLOSURE_MANIFEST.tsv (git 复算)
    rows = []
    for p, dispo in CHANGED4:
        g3 = git_blob_sha256(repo, rc, p)
        gs = git_blob_sha256(repo, supp, p)
        if gs is None:
            die("repair: %s 在 supplement commit 无 blob" % p)
        if dispo == "added":
            if g3 is not None:
                die("repair: %s 预期 added 但 RC3 存在" % p)
            rows.append((p, "-", gs, dispo))
        else:
            if g3 is None:
                die("repair: %s 在 RC3 无 blob" % p)
            rows.append((p, g3, gs, dispo))
    cmp_ = os.path.join(base, "supplement/CLOSURE_MANIFEST.tsv")
    hdr = ("# closure-manifest-v1 rc3_commit=%s supplement_commit=%s "
           "format=path\\trc3_sha256\\tsupplement_sha256\\tdisposition"
           % (rc, supp))
    replace_file(cmp_, hdr + "\n"
                 + "".join("%s\t%s\t%s\t%s\n" % r for r in rows))
    # 3) tooling/
    tld = os.path.join(base, "tooling")
    if not os.path.isdir(tld):
        os.makedirs(tld)
    pairs = [
        (builder, "build_release_archive.sh"),
        (os.path.join(HERE, "verify_release_archive.py"),
         "verify_release_archive.py"),
        (os.path.join(HERE, "negtest_release.py"), "negtest_release.py"),
    ]
    for src, name in pairs:
        if not os.path.isfile(src):
            die("repair: tooling 源缺失 %s" % src)
        with open(src, "rb") as f:
            replace_file(os.path.join(tld, name), f.read())
    # 4) 重封
    reseal(base)


def run_verifier(verifier, root, rc, supp, repo):
    cmd = [sys.executable, verifier, root, rc,
           "--supplement-commit", supp]
    if repo:
        cmd += ["--repo", repo]
    pr = run(cmd)
    m = re.search(r"ARCHIVE_VIOLATIONS=(\d+)", pr.stdout)
    n = int(m.group(1)) if m else -1
    return n, pr.stdout


# ---------------- 篡改函数 (root = 负测树) ----------------

def t_a(root):
    shutil.rmtree(os.path.join(root, "aux-supplement/FastArbiter_5"))


def t_b(root):
    vp = os.path.join(root, "aux-supplement/FastArbiter_4",
                      "verdict.sidecar.json")
    txt = read_text(vp)
    new = txt.replace('"passing": 144', '"passing": 145', 1)
    if new == txt:
        die("negtest b: 未找到 passing:144 锚点")
    replace_file(vp, new)


def t_c(root):
    copy_tree(os.path.join(root, "aux-supplement/FastArbiter_4"),
              os.path.join(root, "aux-supplement/FastArbiter_45"),
              hardlink=True)


def t_d(root):
    cl = os.path.join(root, "supplement/MSHRCTL_DEPENDENCY_CLOSURE.tsv")
    out = []
    hit = False
    for l in read_text(cl).splitlines():
        if l.startswith("supplement_commit\t"):
            parts = l.split("\t")
            parts[1] = "deadbeef" + parts[1][8:]
            l = "\t".join(parts)
            hit = True
        out.append(l)
    if not hit:
        die("negtest d: closure 无 supplement_commit 行")
    replace_file(cl, "\n".join(out) + "\n")


def t_e(root):
    cl = os.path.join(root, "supplement/MSHRCTL_DEPENDENCY_CLOSURE.tsv")
    out = [l for l in read_text(cl).splitlines()
           if not l.startswith("edge\tFastArbiter_7\t")]
    replace_file(cl, "\n".join(out) + "\n")


def t_f1(root):
    copy_tree(os.path.join(root, "rob/part.lsq"),
              os.path.join(root, "rob/part.extra"), hardlink=True)


def t_f2(root):
    shutil.rmtree(os.path.join(root, "rob/part.lsq"))


def flip_hex(c):
    return "0" if c != "0" else "1"


def t_g(root):
    fp = os.path.join(root, "rob/UNION_RECORD.rc3-fresh.tsv")
    out = []
    hit = False
    for l in read_text(fp).splitlines():
        if l.startswith("golden_src_sha256\t") and not hit:
            parts = l.split("\t")
            parts[1] = flip_hex(parts[1][0]) + parts[1][1:]
            l = "\t".join(parts)
            hit = True
        out.append(l)
    if not hit:
        die("negtest g: rc3-fresh 无 golden_src_sha256 行")
    replace_file(fp, "\n".join(out) + "\n")


def t_h(root):
    fp = os.path.join(root, "supplement/CLOSURE_MANIFEST.tsv")
    out = []
    hit = False
    for l in read_text(fp).splitlines():
        if l.startswith("scripts/sidecar/run_signoff_target.sh\t") and not hit:
            parts = l.split("\t")
            parts[2] = flip_hex(parts[2][0]) + parts[2][1:]
            l = "\t".join(parts)
            hit = True
        out.append(l)
    if not hit:
        die("negtest h: CLOSURE_MANIFEST 无 run_signoff_target.sh 行")
    replace_file(fp, "\n".join(out) + "\n")


CASES = [
    # (name, 说明, tamper_fn, [必现违例正则])
    ("a", "删 supplement receipt FastArbiter_5", t_a,
     [r"supp_receipt_missing: FastArbiter_5"]),
    ("b", "supplement verdict json passing 144→145", t_b,
     [r"supp:FastArbiter_4: receipt_file_drift verdict\.sidecar\.json",
      r"closure_edge_sha_mismatch: FastArbiter_4"]),
    ("c", "伪造 supplement receipt FastArbiter_45", t_c,
     [r"supp_receipt_extra: FastArbiter_45"]),
    ("d", "closure supplement_commit 改错", t_d,
     [r"closure_supplement_commit_mismatch"]),
    ("e", "closure 删 edge FastArbiter_7", t_e,
     [r"closure_edge_missing: FastArbiter_7"]),
    ("f1", "rob 加 part.extra", t_f1,
     [r"rob_parts_extra: part\.extra"]),
    ("f2", "rob 删 part.lsq", t_f2,
     [r"rob_parts_missing: part\.lsq"]),
    ("g", "篡改 UNION_RECORD.rc3-fresh.tsv 一行", t_g,
     [r"rob_fresh_diff"]),
    ("h", "CLOSURE_MANIFEST 一行 sha 与实际不符", t_h,
     [r"cm_sha_mismatch: scripts/sidecar/run_signoff_target\.sh"]),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", default=DEF_ARCHIVE)
    ap.add_argument("--rc", default=DEF_RC)
    ap.add_argument("--supplement-commit", default=DEF_SUPP)
    ap.add_argument("--repo", default=DEF_REPO)
    ap.add_argument("--work", default=DEF_WORK)
    ap.add_argument("--verifier",
                    default=os.path.join(HERE, "verify_release_archive.py"))
    ap.add_argument("--builder", default=DEF_BUILDER)
    ap.add_argument("--cases", help="逗号分隔子集, 缺省全跑")
    ap.add_argument("--keep", action="store_true")
    ap.add_argument("--no-repair", action="store_true",
                    help="integrator 已补件的成品 archive: 不做补件仿真")
    ap.add_argument("--baseline-only", action="store_true")
    a = ap.parse_args()

    if not os.path.isdir(a.archive):
        die("archive 不存在: %s" % a.archive)
    if not os.path.isfile(a.verifier):
        die("verifier 不存在: %s" % a.verifier)
    pr = subprocess.run(["git", "-C", a.repo, "rev-parse", "--verify",
                         "%s^{commit}" % a.rc],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if pr.returncode != 0:
        die("repo 不可用/RC 不可解析: %s" % a.repo)

    if os.path.isdir(a.work):
        shutil.rmtree(a.work)
    os.makedirs(a.work)
    base = os.path.join(a.work, "base")
    print("# 准备 base (cp -a %s)" % a.archive)
    copy_tree(a.archive, base)
    # 全拷贝 → 新 inode: 放开写权(目录+文件)安全
    run(["chmod", "-R", "u+w", base])
    if not a.no_repair:
        print("# integrator 补件仿真 (closure 机器行/CLOSURE_MANIFEST/"
              "tooling/重封)")
        repair(base, a.rc, a.supplement_commit, a.repo, a.builder)

    fails = 0
    n0, out0 = run_verifier(a.verifier, base, a.rc, a.supplement_commit,
                            a.repo)
    print("BASELINE\tviolations=%d\t%s" % (n0, "OK" if n0 == 0 else "NONZERO"))
    if n0 != 0:
        for l in out0.splitlines():
            if l.startswith("VIOL"):
                print("  base " + l)
        fails += 1
    base_viols = set(l for l in out0.splitlines() if l.startswith("VIOL\t"))

    if a.baseline_only:
        sys.exit(min(fails, 120))

    sel = set(a.cases.split(",")) if a.cases else None
    ran = 0
    for name, desc, fn, pats in CASES:
        if sel is not None and name not in sel:
            continue
        ran += 1
        croot = os.path.join(a.work, "case_" + name)
        copy_tree(base, croot, hardlink=True)
        fn(croot)
        reseal(croot)
        n, out = run_verifier(a.verifier, croot, a.rc, a.supplement_commit,
                              a.repo)
        got = set(l for l in out.splitlines() if l.startswith("VIOL\t"))
        new = got - base_viols
        missing = [p for p in pats
                   if not any(re.search(p, v) for v in new)]
        ok = (n > 0) and not missing
        print("CASE %-3s %-44s violations=%d new=%d %s"
              % (name, desc, n, len(new), "PASS" if ok else "FAIL"))
        for v in sorted(new):
            print("    " + v.replace("VIOL\t", "caught: "))
        if missing:
            for p in missing:
                print("    MISSING_EXPECTED: %s" % p)
        if not ok:
            fails += 1
        if ok and not a.keep:
            shutil.rmtree(croot)

    print("NEGTEST_SUMMARY cases=%d fails=%d baseline_violations=%d"
          % (ran, fails - (1 if n0 != 0 else 0), n0))
    if not a.keep and fails == 0:
        shutil.rmtree(a.work)
    sys.exit(min(fails, 120))


if __name__ == "__main__":
    main()
