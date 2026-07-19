#!/usr/bin/env python3
"""Coursier 闭包 fetch-then-verify(2026-07)。按 coursier_closure.manifest.tsv 逐 JAR 校验
size+sha256, 并核对整体 closure digest == TRUST_ANCHORS 的完整 64-hex。任何缺失/不符即非零退出。"""
import sys, os, hashlib
HERE = os.path.dirname(os.path.abspath(__file__))
anc = dict(l.rstrip("\n").split("\t")[:2] for l in open(os.path.join(HERE, "TRUST_ANCHORS.tsv"))
           if not l.startswith("#") and not l.startswith("key\t"))
rows = []
for ln in open(os.path.join(HERE, "coursier_closure.manifest.tsv")):
    if ln.startswith("#") or ln.startswith("path\t"): continue
    p, sz, h = ln.rstrip("\n").split("\t")
    rows.append((p, int(sz), h))
bad = 0
h_all = hashlib.sha256()
for p, sz, h in rows:   # 列表本身已 LC_ALL=C 排序(生成时), 串接序=清单序
    try:
        b = open(p, "rb").read()
    except FileNotFoundError:
        print(f"CLOSURE-MISSING {p}"); bad += 1; continue
    if len(b) != sz or hashlib.sha256(b).hexdigest() != h:
        print(f"CLOSURE-MISMATCH {p}"); bad += 1; continue
    h_all.update(b)
if bad:
    print(f"CLOSURE-FAIL: {bad}/{len(rows)}"); sys.exit(1)
full = h_all.hexdigest()
if full != anc["coursier_closure"]:
    print(f"CLOSURE-DIGEST-MISMATCH {full[:16]} != anchor"); sys.exit(1)
print(f"CLOSURE-OK: {len(rows)} jars, digest {full[:16]}... == anchor")
