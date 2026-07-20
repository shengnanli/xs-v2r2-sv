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
# native 会话 validator 期望 (verdict, reason)——六审: 不能只比大类(重复 JSON 键致
# load ERROR 亦是 ERROR); reason 精确绑定。
EXPECT = {
    "bku_strict": ("PARTIAL", "strict_unverified/aborted/unread"),
    "bku_unread_true_probe": ("ERROR", "expect_frozen_semantics:verification_verify_unread_compare_points"),
    "imsic_strict": ("PARTIAL", "strict_has_objects"),
}
# 六审: infra 精确唯一 pathset(五条重复同一合法文件曾满足 n_bound>=5)
INFRA_REL = sorted([
    "scripts/sidecar/fm_sidecar_run.sh",
    "scripts/ut_common.mk",
    "scripts/sidecar/fm_closure_digest.py",
    "scripts/sidecar/fm_sidecar_verdict.py",
    "scripts/sidecar/step3b_archive_check.sh",
])


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()


def git_show_sha(repo, commit, relpath):
    try:
        out = subprocess.run(["git", "-C", repo, "show", f"{commit}:{relpath}"],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout
        return hashlib.sha256(out).hexdigest()
    except subprocess.CalledProcessError:
        return None


def _dup_hook(pairs):
    d = {}
    for k, v in pairs:
        if k in d:
            raise ValueError("duplicate_key:" + k)
        d[k] = v
    return d


def load_json_strict(p):
    with open(p, "rb") as f:
        buf = f.read()
    o = json.loads(buf, object_pairs_hook=_dup_hook)  # 非法 JSON / 重复键抛异常
    return o, buf


def git_extract(repo, commit, relpath, dest):
    """把 expected commit 的文件字节提取到 dest; 失败返回 False。"""
    try:
        out = subprocess.run(["git", "-C", repo, "show", f"{commit}:{relpath}"],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout
    except subprocess.CalledProcessError:
        return False
    with open(dest, "wb") as f:
        f.write(out)
    return True


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
        if parts[0] in ("infra", "executed_snapshot") and len(parts) == 3:
            if parts[0] == "infra":
                infra.append((parts[1], parts[2]))
            # executed_snapshot 是多行族, 不入 kv/dup 检查
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
    # 六审洞1: RESULT 的 SESSION_RESULT 行必须精确声明 verdict\treason(不能声称 SUCCEEDED)
    res_line = ""
    for ln in result.splitlines():
        if ln.startswith(f"SESSION_RESULT {s}:"):
            res_line = ln; break
    if not res_line:
        errs.append(f"{s}: RESULT_LINE_MISSING")

    # TOOLS 严格 schema
    kv, infra = parse_tools(d, errs, s)
    for k in ("worktree_head_pre", "worktree_head_post", "impl_commit"):
        if kv.get(k) != expected:
            errs.append(f"{s}: TOOLS_{k}={kv.get(k)}!={expected}")
    # tracked cleanliness 是硬闸(所有会话); untracked 仅 native 须 0——reject 会话注入的
    # 刺激文件(fm_pins_pre/inner.tcl)本就是未跟踪测试输入, 已入证据 stimulus_*(可追溯)。
    for k in ("worktree_tracked_dirty_pre", "worktree_tracked_dirty_post", "main_tracked_dirty"):
        if kv.get(k) != "0":
            errs.append(f"{s}: TOOLS_{k}={kv.get(k)}!=0")
    if kind == "native" and kv.get("worktree_untracked_files") != "0":
        errs.append(f"{s}: TOOLS_worktree_untracked_files={kv.get('worktree_untracked_files')}!=0")
    if kind == "reject":
        # reject: 未跟踪数须 == 注入刺激数(fm_pins_pre.tcl 必有, fm_pins_inner.tcl 可选)。
        # 注: stimulus_fm_pins.tcl 是 Bku 的 tracked 正常 pin, 不计入注入未跟踪数。
        inj = [f for f in os.listdir(d)
               if f in ("stimulus_fm_pins_pre.tcl", "stimulus_fm_pins_inner.tcl")]
        if "stimulus_fm_pins_pre.tcl" not in inj:
            errs.append(f"{s}: MISSING injected stimulus_fm_pins_pre.tcl")
        if kv.get("worktree_untracked_files") != str(len(inj)):
            errs.append(f"{s}: UNTRACKED={kv.get('worktree_untracked_files')}!=injected({len(inj)})")
    # 六审洞4: infra 精确唯一 pathset —— 相对路径去重后必须恰等于 INFRA_REL,
    # 且每条 hash == git show <expected>:<rel>(不再"数够 5 条重复即可")
    infra_rel_seen = []
    for path, h in infra:
        if len(h) != 64 or any(c not in "0123456789abcdef" for c in h):
            errs.append(f"{s}: INFRA_HASH_BAD {path}"); continue
        rel = os.path.relpath(path, repo)
        if rel.startswith(".."):
            errs.append(f"{s}: INFRA_PATH_OUTSIDE {path}"); continue
        infra_rel_seen.append(rel)
        want = git_show_sha(repo, expected, rel)
        if want is None:
            errs.append(f"{s}: INFRA_NOT_AT_COMMIT {rel}")
        elif want != h:
            errs.append(f"{s}: INFRA_HASH_MISMATCH {rel}")
    if sorted(infra_rel_seen) != INFRA_REL:
        errs.append(f"{s}: INFRA_PATHSET!=exact {sorted(set(infra_rel_seen))}")

    # 六审洞6: 独立重算完整 script closure(不信任 envelope 自报), 逐快照字节 hash 核对,
    # 顺序取自 script_closure.list; 再与 envelope.script_sha256 + expectation.script_digest 双绑定。
    def recompute_closure():
        clp = os.path.join(d, "script_closure.list")
        rows = []
        for line in open(clp, encoding="utf-8"):
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) != 3:
                errs.append(f"{s}: CLOSURE_ROW_BAD {line}"); return None
            rows.append(parts)  # (orig, snap, ledger_hash)
        cat = b""
        snaps_seen = set()
        # executed_snapshot TOOLS 行须与 closure list 精确一致(snap+hash); 逐行 strip 换行
        es_map = {}
        for ln in open(os.path.join(d, "TOOLS.tsv"), encoding="utf-8"):
            ln = ln.rstrip("\n")
            if not ln.startswith("executed_snapshot\t"):
                continue
            p = ln.split("\t")
            if len(p) == 3:
                es_map[p[1]] = p[2]
        for orig, snap, lhash in rows:
            if snap in snaps_seen:
                errs.append(f"{s}: CLOSURE_SNAP_DUP {snap}"); return None
            snaps_seen.add(snap)
            sp = os.path.join(d, snap)
            if not os.path.isfile(sp):
                errs.append(f"{s}: CLOSURE_SNAP_MISSING {snap}"); return None
            actual = sha256_file(sp)
            if actual != lhash:
                errs.append(f"{s}: CLOSURE_SNAP_TAMPERED {snap}"); return None
            if es_map.get(snap) != lhash:
                errs.append(f"{s}: EXECUTED_SNAPSHOT_MISMATCH {snap}"); return None
            with open(sp, "rb") as f:
                cat += f.read()
        return hashlib.sha256(cat).hexdigest()

    if kind == "native":
        # 六审洞3: 重复 JSON 键 → load_json_strict 抛异常(dup-key hook)→ 判 JSON_PARSE_FAIL
        try:
            env, _ = load_json_strict(os.path.join(d, "verdict.sidecar.json"))
            nat, natbuf = load_json_strict(os.path.join(d, "native_facts.json"))
            exp, _ = load_json_strict(os.path.join(d, "expectation.smoke.json"))
        except Exception as e:
            errs.append(f"{s}: JSON_PARSE_FAIL {e}"); return
        if not isinstance(nat, dict) or "stats" not in nat:
            errs.append(f"{s}: NATIVE_JSON_SHAPE"); return
        try:
            rcfile = int(open(os.path.join(d, "fm_shell.rc")).read().strip())
        except Exception:
            rcfile = None
        if env.get("fm_shell_rc") != rcfile or rcfile != 0:
            errs.append(f"{s}: FM_SHELL_RC {env.get('fm_shell_rc')}/{rcfile}")
        if env.get("native_facts_sha256") != hashlib.sha256(natbuf).hexdigest():
            errs.append(f"{s}: NATIVE_SHA_UNBOUND")
        # 独立重算 closure 双绑定
        cl = recompute_closure()
        if cl is not None:
            if cl != env.get("script_sha256"):
                errs.append(f"{s}: CLOSURE!=envelope.script_sha256")
            if cl != exp.get("script_digest"):
                errs.append(f"{s}: CLOSURE!=expectation.script_digest")
        # 六审洞5: 用 **expected commit 提取的** validator 字节运行(非工作树)
        import tempfile
        vdir = tempfile.mkdtemp()
        vp = os.path.join(vdir, "fm_sidecar_verdict.py")
        if not git_extract(repo, expected, "scripts/sidecar/fm_sidecar_verdict.py", vp):
            errs.append(f"{s}: VALIDATOR_NOT_AT_COMMIT")
        else:
            r = subprocess.run([sys.executable, vp, os.path.join(d, "verdict.sidecar.json"),
                                "--native-facts", os.path.join(d, "native_facts.json"),
                                "--expectation", os.path.join(d, "expectation.smoke.json"),
                                "--actual-rc", str(rcfile if rcfile is not None else 999)],
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            parts = (r.stdout or "").split("\t", 1)
            verdict = parts[0].strip() if parts else ""
            reason = parts[1].strip() if len(parts) > 1 else ""
            want_v, want_r = EXPECT[s]
            # 六审洞1/3: verdict + reason + validator rc(SUCCEEDED→0 其余→1)全绑定
            if verdict != want_v:
                errs.append(f"{s}: VALIDATOR_VERDICT={verdict}!={want_v}")
            if reason != want_r:
                errs.append(f"{s}: VALIDATOR_REASON={reason}!={want_r}")
            want_rc = 0 if want_v == "SUCCEEDED" else 1
            if r.returncode != want_rc:
                errs.append(f"{s}: VALIDATOR_RC={r.returncode}!={want_rc}")
            # RESULT 声称的 verdict\treason 必须与 validator 一致(堵"声称 SUCCEEDED")
            if f": {want_v}\t{want_r}" not in res_line:
                errs.append(f"{s}: RESULT_VERDICT_FORGED [{res_line}]")
        import shutil; shutil.rmtree(vdir, ignore_errors=True)
    else:
        if os.path.exists(os.path.join(d, "native_facts.json")):
            errs.append(f"{s}: native_facts_MUST_BE_ABSENT")
        if "NO_NATIVE_FACTS" not in result:
            errs.append(f"{s}: REJECT_RESULT_MISMATCH")
        # 六审洞2: reject 严格 fm_shell.rc==3 / RUNNER_RC==5
        try:
            rcfile = int(open(os.path.join(d, "fm_shell.rc")).read().strip())
        except Exception:
            rcfile = None
        if rcfile != 3:
            errs.append(f"{s}: REJECT_FM_SHELL_RC={rcfile}!=3")
        # reject 也独立核 closure 快照未被篡改(拒产会话亦有入口/emitter/pin 快照)
        recompute_closure()


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
                      stdout=subprocess.PIPE, stderr=subprocess.PIPE).returncode != 0:
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
