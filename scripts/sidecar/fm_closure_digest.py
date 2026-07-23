#!/usr/bin/env python3
"""closure digest(SIDECAR_SCHEMA.md v7 冻结算法, expectation 与 envelope 共用)。

closure-v1(--mode files): FM 读入的全部源文件按 LC_ALL=C 相对路径排序, 逐文件
`relpath<TAB>size<TAB>sha256<LF>`, 追加固定顺序语义要素行(--semantic K=V, 按传入序),
对完整字节流 SHA-256。
script closure(--mode concat): 按 source 顺序串接文件字节后 SHA-256。
tool digest(--mode tool): sha256(解析后的可执行文件字节)。
"""
import argparse, hashlib, os, sys


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["files", "concat", "tool"], required=True)
    ap.add_argument("--root", default="")
    ap.add_argument("--semantic", action="append", default=[])
    ap.add_argument("files", nargs="+")
    a = ap.parse_args()

    if a.mode == "tool":
        p = os.path.realpath(a.files[0])
        print(sha256_file(p))
        return

    if a.mode == "concat":
        h = hashlib.sha256()
        for f in a.files:  # source 顺序, 不排序
            h.update(open(f, "rb").read())
        print(h.hexdigest())
        return

    # files: closure-v1
    entries = []
    for f in a.files:
        p = os.path.realpath(f)
        rel = os.path.relpath(p, a.root) if a.root else p
        entries.append((rel, os.path.getsize(p), sha256_file(p)))
    entries.sort(key=lambda e: e[0].encode())  # LC_ALL=C 序
    buf = b""
    for rel, size, dig in entries:
        buf += f"{rel}\t{size}\t{dig}\n".encode()
    for kv in a.semantic:  # 固定传入顺序
        buf += (kv + "\n").encode()
    print(hashlib.sha256(buf).hexdigest())


if __name__ == "__main__":
    main()
