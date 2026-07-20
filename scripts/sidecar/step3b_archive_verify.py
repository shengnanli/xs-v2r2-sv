#!/usr/bin/env python3
"""Step 3B 提交态证据**语义**验证(五审)。此前 checker 只证"清单自洽"被裁定可假绿
(native JSON 改 {} / rc=999 / RESULT 伪造后重算 MANIFEST/COMPLETE 仍 OK)。本验证器:
  ① 固定六会话集合; 每会话 MANIFEST 完整性(size/sha/extra/dup/坏路径)+ COMPLETE
  ② 类型化必需 pathset(native 须 facts/envelope/expectation; reject 须刺激且 facts 缺席)
  ③ TOOLS 严格 schema: 键唯一; head 前后 == impl_commit == expected; dirty 全 0;
     infra 行 sha256 == `git show <expected>:<相对路径>` 的 sha256(绑定真实提交字节)
  ④ 对三个 native 会话**实跑提交态 validator**, 交叉 verdict/fm_shell_rc/RESULT/RUNNER_RC
  ⑤ reject 会话: native_facts 缺席 + RUNNER_RC==5 + RESULT 含 NO_NATIVE_FACTS
用法: step3b_archive_verify.py <tree_dir> <expected_impl_commit> <signoff_repo>
"""
import json, os, subprocess, sys, hashlib

NATIVE = ["bku_strict", "bku_unread_true_probe", "imsic_strict"]
REJECT = ["intercept_direct", "intercept_dynamic", "intercept_nested"]
EXPECT_RC = {"bku_strict": 1, "bku_unread_true_probe": 1, "imsic_strict": 1,
             "intercept_direct": 5, "intercept_dynamic": 5, "intercept_nested": 5}
# native 会话的 validator 期望 verdict(smoke expectation 下)
EXPECT_VERDICT = {"bku_strict": "PARTIAL", "bku_unread_true_probe": "ERROR",
                  "imsic_strict": "PARTIAL"}


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()


def git_show_sha(repo, commit, relpath):
    try:
        out = subprocess.run(["git", "-C", repo, "show", f"{commit}:{relpath}"],
                             capture_output=True, check=True).stdout
        return hashlib.sha256(out).hexdigest()
    except subprocess.CalledProcessError:
        return None


def load_json_strict(p):
    with open(p, "rb") as f:
        buf = f.read()
    o = json.loads(buf)  # 非法 JSON 抛异常
    return o, buf


def check_manifest(d, errs, s):
    mf = os.path.join(d, "MANIFEST.tsv")
    comp = os.path.join(d, "COMPLETE")
    if not os.path.isfile(mf) or not os.path.isfile(comp):
        errs.append(f"{s}: MISSING MANIFEST/COMPLETE"); return set()
    if sha256_file(mf) != open(comp).read().strip():
        errs.append(f"{s}: COMPLETE!=sha(MANIFEST)")
    listed = {}
    for line in open(mf, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            errs.append(f"{s}: MANIFEST_BAD_ROW {line}"); continue
        f, sz, h = parts
        if f.startswith("/") or ".." in f or f == "":
            errs.append(f"{s}: BADPATH {f}"); continue
        if f in listed:
            errs.append(f"{s}: DUP {f}"); continue
        listed[f] = (sz, h)
        fp = os.path.join(d, f)
        if not os.path.isfile(fp):
            errs.append(f"{s}: MISSING {f}"); continue
        if str(os.path.getsize(fp)) != sz or sha256_file(fp) != h:
            errs.append(f"{s}: HASH_BAD {f}")
    # extra: 目录内每个常规文件必须在清单(除 MANIFEST/COMPLETE)
    for root, _, files in os.walk(d):
        for fn in files:
            rel = os.path.relpath(os.path.join(root, fn), d)
            if rel in ("MANIFEST.tsv", "COMPLETE"):
                continue
            if rel not in listed:
                errs.append(f"{s}: EXTRA {rel}")
    return set(listed)


def parse_tools(d, errs, s):
    t = os.path.join(d, "TOOLS.tsv")
    kv = {}; infra = []
    dup = set()
    for line in open(t, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line or line.startswith("kind\t"):
            continue
        parts = line.split("\t")
        if parts[0] == "infra" and len(parts) == 3:
            infra.append((parts[1], parts[2]))
        elif len(parts) >= 2:
            if parts[0] in kv:
                dup.add(parts[0])
            kv[parts[0]] = parts[1]
    if dup:
        errs.append(f"{s}: TOOLS_DUP_KEYS {sorted(dup)}")
    return kv, infra


def check_session(tree, s, kind, expected, repo, errs):
    d = os.path.join(tree, s)
    if not os.path.isdir(d):
        errs.append(f"{s}: DIR_MISSING"); return
    listed = check_manifest(d, errs, s)

    req = ["RESULT.txt", "TOOLS.tsv", "RUNNER_RC", "fm_shell.rc", "fm_log.txt",
           "make.out", "script_closure.list", "frozen/scripts/fm_eq.tcl",
           "frozen/scripts/fm_verdict.py", "frozen/scripts/sidecar/fm_native_emit.tcl"]
    if kind == "native":
        req += ["native_facts.json", "verdict.sidecar.json", "expectation.smoke.json"]
    if kind == "reject":
        req += ["stimulus_fm_pins_pre.tcl"]
    for f in req:
        fp = os.path.join(d, f)
        if not (os.path.isfile(fp) and os.path.getsize(fp) > 0):
            errs.append(f"{s}: REQUIRED_MISSING_OR_EMPTY {f}")
    if kind == "native" and not os.path.isfile(os.path.join(d, "probe_nc_unread.list")):
        errs.append(f"{s}: REQUIRED_MISSING probe_nc_unread.list")
    nsnap = sum(1 for f in os.listdir(d) if f.startswith("sourced_"))
    if nsnap < 2:
        errs.append(f"{s}: SNAPSHOTS<2")

    # RUNNER_RC 语义
    try:
        rrc = int(open(os.path.join(d, "RUNNER_RC")).read().strip())
    except Exception:
        rrc = None
    if rrc != EXPECT_RC[s]:
        errs.append(f"{s}: RUNNER_RC={rrc}!={EXPECT_RC[s]}")

    result = ""
    rp = os.path.join(d, "RESULT.txt")
    if os.path.isfile(rp):
        result = open(rp, encoding="utf-8", errors="replace").read()
    if "CLEAN_GATE_FAIL" in result:
        errs.append(f"{s}: CLEAN_GATE_FAIL")
    if f"SESSION_RESULT {s}:" not in result:
        errs.append(f"{s}: RESULT_LINE_MISSING")

    # TOOLS 严格 schema
    kv, infra = parse_tools(d, errs, s)
    for k in ("worktree_head_pre", "worktree_head_post", "impl_commit"):
        if kv.get(k) != expected:
            errs.append(f"{s}: TOOLS_{k}={kv.get(k)}!={expected}")
    for k in ("worktree_tracked_dirty_pre", "worktree_tracked_dirty_post",
              "main_tracked_dirty", "worktree_untracked_files"):
        if kv.get(k) != "0":
            errs.append(f"{s}: TOOLS_{k}={kv.get(k)}!=0")
    # infra hash 绑定 expected commit 真实字节(路径须在 repo 内)
    n_bound = 0
    for path, h in infra:
        if len(h) != 64 or any(c not in "0123456789abcdef" for c in h):
            errs.append(f"{s}: INFRA_HASH_BAD {path}"); continue
        rel = os.path.relpath(path, repo)
        if rel.startswith(".."):
            errs.append(f"{s}: INFRA_PATH_OUTSIDE {path}"); continue
        want = git_show_sha(repo, expected, rel)
        if want is None:
            errs.append(f"{s}: INFRA_NOT_AT_COMMIT {rel}")
        elif want != h:
            errs.append(f"{s}: INFRA_HASH_MISMATCH {rel}")
        else:
            n_bound += 1
    if n_bound < 5:
        errs.append(f"{s}: INFRA_BOUND<5 ({n_bound})")

    if kind == "native":
        # JSON 严格解析 + 实跑提交态 validator + 交叉
        try:
            env, _ = load_json_strict(os.path.join(d, "verdict.sidecar.json"))
            nat, natbuf = load_json_strict(os.path.join(d, "native_facts.json"))
        except Exception as e:
            errs.append(f"{s}: JSON_PARSE_FAIL {type(e).__name__}"); return
        if not isinstance(nat, dict) or "stats" not in nat:
            errs.append(f"{s}: NATIVE_JSON_SHAPE"); return
        # fm_shell.rc 三处一致
        try:
            rcfile = int(open(os.path.join(d, "fm_shell.rc")).read().strip())
        except Exception:
            rcfile = None
        if env.get("fm_shell_rc") != rcfile or rcfile != 0:
            errs.append(f"{s}: FM_SHELL_RC {env.get('fm_shell_rc')}/{rcfile}")
        # native_facts_sha256 绑定
        if env.get("native_facts_sha256") != hashlib.sha256(natbuf).hexdigest():
            errs.append(f"{s}: NATIVE_SHA_UNBOUND")
        # 实跑 validator
        vp = os.path.join(os.path.dirname(__file__), "fm_sidecar_verdict.py")
        r = subprocess.run([sys.executable, vp, os.path.join(d, "verdict.sidecar.json"),
                            "--native-facts", os.path.join(d, "native_facts.json"),
                            "--expectation", os.path.join(d, "expectation.smoke.json"),
                            "--actual-rc", str(rcfile if rcfile is not None else 999)],
                           capture_output=True, text=True)
        verdict = r.stdout.split("\t")[0].strip() if r.stdout else ""
        if verdict != EXPECT_VERDICT[s]:
            errs.append(f"{s}: VALIDATOR_VERDICT={verdict}!={EXPECT_VERDICT[s]}")
    else:
        if os.path.exists(os.path.join(d, "native_facts.json")):
            errs.append(f"{s}: native_facts_MUST_BE_ABSENT")
        if "NO_NATIVE_FACTS" not in result:
            errs.append(f"{s}: REJECT_RESULT_MISMATCH")


def main():
    tree, expected, repo = sys.argv[1], sys.argv[2], sys.argv[3]
    errs = []
    # 集合精确相等
    got = sorted(x for x in os.listdir(tree) if os.path.isdir(os.path.join(tree, x)))
    want = sorted(NATIVE + REJECT)
    if got != want:
        errs.append(f"SESSION_SET {got}!={want}")
    # symlink/非常规
    for root, dirs, files in os.walk(tree):
        for fn in files + dirs:
            p = os.path.join(root, fn)
            if os.path.islink(p):
                errs.append(f"SYMLINK {os.path.relpath(p, tree)}")
    # expected commit 存在
    if subprocess.run(["git", "-C", repo, "cat-file", "-e", expected],
                      capture_output=True).returncode != 0:
        errs.append(f"EXPECTED_COMMIT_MISSING {expected}")
    for s in NATIVE:
        check_session(tree, s, "native", expected, repo, errs)
    for s in REJECT:
        check_session(tree, s, "reject", expected, repo, errs)
    for e in errs:
        print("  " + e)
    print(f"ARCHIVE_VERIFY: bad={len(errs)}")
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
