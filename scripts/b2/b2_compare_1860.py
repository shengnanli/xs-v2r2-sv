#!/usr/bin/env python3
"""完整 1860 输出比对(canonical 晋升门, 2026-07 四审修订, fail-closed)。

四审堵掉的假绿:
 - **canonical 为默认模式**: 只有 内容+mode(0644)+manifest 全过才 rc=0(CANONICAL_ARTIFACT_REPRODUCED)。
   content-only 须显式 `--content-only`, 且成功 rc=10(与 canonical 的 0 区分, 自动化不会误当 canonical)。
 - 信任锚 = **提交态 TRUST_ANCHORS.tsv 的完整 64-hex**(脚本同目录, 随 repo 提交), 不信传入目录里
   可同步篡改的 manifest/descriptor/16-hex 截断。
 - 拒绝 candidate 里的 symlink/FIFO/socket/目录外类型(os.lstat 全类型扫描, 非 find -type f)。
 - SimTop.fir 用 **literal bytes 替换**, 仅替换 FIRRTL location 前缀 `@[<candidate-root>/`
   → `@[<G0-root>/`(不把路径交给 sed/grep 正则), 并断言替换次数恰为冻结值 6,759,209。
 - 产出机器可读结果 JSON + normalized manifest + tree digest(--out 目录)。

用法: b2_compare_1860.py <G0-quarantine> <candidate-build-rtl> [--content-only] [--out DIR]
退出码: 0=CANONICAL_ARTIFACT_REPRODUCED; 10=CONTENT_REPRODUCED(仅 --content-only);
        1=锚/输入错误; 3=内容不符; 4=mode 不符(canonical); 5=非常规文件类型。
"""
import sys, os, json, hashlib, stat, argparse

HERE = os.path.dirname(os.path.abspath(__file__))
EXPECT_COUNT = 1860
EXPECT_FIR_PATHS = 6_759_209
G0_ROOT = b"home/eda/xs-env/xs-clean"
CANON_MODE = 0o644


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def anchors():
    a = {}
    with open(os.path.join(HERE, "TRUST_ANCHORS.tsv")) as f:
        for ln in f:
            if ln.startswith("#") or ln.startswith("key\t"):
                continue
            k, v = ln.rstrip("\n").split("\t")[:2]
            a[k] = v
    return a


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("quarantine"); ap.add_argument("candidate")
    ap.add_argument("--content-only", action="store_true")
    ap.add_argument("--out", default=None)
    ap.add_argument("--cand-root", default=None,
                    help="candidate 构建根(如 home/eda/xs-env/G0-rebuilt); staging 拷贝时必须显式给出")
    A = ap.parse_args()
    res = {"result": None, "content_mismatch": [], "mode_bad": [], "special_files": [],
           "missing": [], "extra": [], "fir_replacements": None, "manifest_sha256": None}

    def finish(code, label):
        res["result"] = label
        if A.out:
            os.makedirs(A.out, exist_ok=True)
            tmpf = os.path.join(A.out, ".b2_1860_result.json.tmp")
            json.dump(res, open(tmpf, "w"), ensure_ascii=False, indent=1)
            os.replace(tmpf, os.path.join(A.out, "b2_1860_result.json"))
        print(f"RESULT-1860: {label}")
        sys.exit(code)

    anc = anchors()
    mf = os.path.join(A.quarantine, "G0-full-output.manifest.tsv")
    g0dir = os.path.join(A.quarantine, "G0-full-output")
    # ① manifest 信任锚(完整64hex, 提交态)
    if not os.path.isfile(mf):
        print("缺 manifest"); finish(1, "ERROR_no_manifest")
    got = sha256_file(mf)
    if got != anc["g0_full_manifest"]:
        print(f"manifest sha256 {got[:16]} != 提交态锚 {anc['g0_full_manifest'][:16]}")
        finish(1, "ERROR_manifest_anchor")
    res["manifest_sha256"] = got
    rows = [l.rstrip("\n").split("\t") for l in open(mf) if l.strip()]
    if len(rows) != EXPECT_COUNT:
        print(f"manifest 行数 {len(rows)} != {EXPECT_COUNT}"); finish(1, "ERROR_manifest_count")

    # ② candidate 全类型扫描: 拒 symlink/FIFO/socket; 路径集必须与 manifest 完全一致
    cand_files = set()
    for root, dirs, files in os.walk(A.candidate):
        for name in dirs + files:
            p = os.path.join(root, name)
            st_ = os.lstat(p)
            rel = os.path.relpath(p, A.candidate)
            if (stat.S_ISLNK(st_.st_mode) or stat.S_ISFIFO(st_.st_mode) or stat.S_ISSOCK(st_.st_mode)
                    or stat.S_ISCHR(st_.st_mode) or stat.S_ISBLK(st_.st_mode)):
                res["special_files"].append(rel)
            elif stat.S_ISREG(st_.st_mode):
                cand_files.add(rel)
    if res["special_files"]:
        print(f"candidate 含非常规文件类型 {len(res['special_files'])} 个: {res['special_files'][:3]}")
        finish(5, "ERROR_special_file_types")
    want = {r[0] for r in rows}
    # 目录集: manifest 路径的所有父目录; candidate 中的其它目录(含空目录)= extra
    want_dirs = set()
    for w in want:
        d = os.path.dirname(w)
        while d:
            want_dirs.add(d); d = os.path.dirname(d)
    cand_dirs = set()
    for root, dirs, _files in os.walk(A.candidate):
        for dn in dirs:
            cand_dirs.add(os.path.relpath(os.path.join(root, dn), A.candidate))
    res["missing"] = sorted(want - cand_files)
    res["extra"] = sorted(cand_files - want) + sorted("DIR:" + d for d in cand_dirs - want_dirs)
    if res["missing"] or res["extra"]:
        print(f"路径集不一致: 缺{len(res['missing'])} 多{len(res['extra'])}")
        finish(3, "MISMATCH_pathset")

    # candidate root(从目录派生, 用于 literal 替换): <root>/build/rtl
    if A.cand_root:
        cand_root = A.cand_root.strip("/").encode()
    else:
        cand_abs = os.path.abspath(A.candidate)
        cand_root = os.path.dirname(os.path.dirname(cand_abs)).lstrip("/").encode()

    # ③ 内容比对(G0 自身 + candidate; .fir literal 替换仅 location 前缀 "@[<root>/")
    norm_rows = []
    for r in rows:
        f, ty, mo, sz, h = r[0], r[1], r[2], r[3], r[4]
        # G0 自身核验(防归档被改)
        if sha256_file(os.path.join(g0dir, f)) != h:
            res["content_mismatch"].append("G0-SELF:" + f)
            continue
        cf = os.path.join(A.candidate, f)
        if f == "SimTop.fir":
            data = open(cf, "rb").read()
            old, new = b"@[" + cand_root + b"/", b"@[" + G0_ROOT + b"/"
            n = data.count(old)
            res["fir_replacements"] = n
            if n != EXPECT_FIR_PATHS:
                print(f".fir location 替换数 {n} != 冻结值 {EXPECT_FIR_PATHS}")
                finish(3, "MISMATCH_fir_pathcount")
            ch = hashlib.sha256(data.replace(old, new)).hexdigest()
        else:
            ch = sha256_file(cf)
        if ch != h:
            res["content_mismatch"].append(f)
        norm_rows.append((f, ty, "644", sz, h))
    if res["content_mismatch"]:
        print(f"内容不符 {len(res['content_mismatch'])}: {res['content_mismatch'][:5]}")
        finish(3, "MISMATCH_content")

    # 输出 normalized manifest + tree digest
    if A.out:
        os.makedirs(A.out, exist_ok=True)
        nm = os.path.join(A.out, "normalized.manifest.tsv")
        tmpn = nm + ".tmp"
        with open(tmpn, "w") as o:
            for t in norm_rows:
                o.write("\t".join(t) + "\n")
        os.replace(tmpn, nm)
        res["normalized_tree_digest"] = sha256_file(nm)

    if A.content_only:
        finish(10, "CONTENT_REPRODUCED(content-only 模式, 非 canonical)")

    # ④ canonical: mode 必须全 0644
    for r in rows:
        m = stat.S_IMODE(os.lstat(os.path.join(A.candidate, r[0])).st_mode)
        if m != CANON_MODE:
            res["mode_bad"].append(f"{r[0]}:{oct(m)}")
    if res["mode_bad"]:
        print(f"mode!=0644 共 {len(res['mode_bad'])}(canonical 要求 chmod 0644 staging 后复验)")
        finish(4, "MODE_NOT_CANONICAL")
    finish(0, "CANONICAL_ARTIFACT_REPRODUCED")


if __name__ == "__main__":
    main()
