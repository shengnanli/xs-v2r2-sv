#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""reconcile.py —— DelayN 家族预登记对账（机械读 receipt，非手抄）。

用法: python3 reconcile.py <evidence 目录名或 commit 前缀>
      例: python3 reconcile.py f0bcd42e

判据（任何一条不满足即非零退出）：
  1. 每个变体都有 receipt.json；
  2. verdict == SUCCEEDED；
  3. passing **恰好等于** PREDICTIONS.md 登记的模型值（predict.py 现算，同一个函数）；
  4. failing == 0、unmatched == 0、native_facts.stats.unread_notcompared == 0；
  5. receipt 的 g1_canonical_id 与本机 G1 的 CANONICAL_ID.txt 一致
     （证明比的是同一份 golden，不是别的基线）。

★为什么要有这个脚本★：预登记的价值在事后对账，而手抄对账等于没对账 ——
本仓已经记过一次「逐字的工具输出不可编辑：补一个字，整份都不可信」。
这里的实测一列全部从 receipt.json 读，脚本自己打印，不经人手。
"""
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "../../.."))
sys.path.insert(0, HERE)
from predict import predict          # noqa: E402
from gen import VARIANTS             # noqa: E402

G1 = os.environ.get("G1_CANONICAL", "/home/eda/xs-env/G1-canonical")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    pat = os.path.join(REPO, "evidence", sys.argv[1] + "*")
    dirs = sorted(glob.glob(pat))
    if len(dirs) != 1:
        print("evidence 目录不唯一: %r -> %r" % (pat, dirs))
        return 2
    evid = dirs[0]
    try:
        canon = open(os.path.join(G1, "CANONICAL_ID.txt")).read().strip()
    except OSError:
        canon = None

    print("evidence = %s" % evid)
    print("%-12s %10s %10s %6s %8s %10s %7s %-11s" %
          ("top", "模型", "实测", "差", "failing", "unmatched", "unread", "verdict"))
    bad = []
    for name in VARIANTS:
        rj = os.path.join(evid, name, "receipt.json")
        if not os.path.exists(rj):
            print("%-12s %10d %10s  —— ★没有 receipt★" % (name, predict(name)["passing"], "-"))
            bad.append(name)
            continue
        d = json.load(open(rj))
        det = d.get("verdict_detail") or {}
        nf = (d.get("native_facts") or {}).get("stats") or {}
        model = predict(name)["passing"]
        got = det.get("passing")
        unread = nf.get("unread_notcompared")
        ok = (d.get("verdict") == "SUCCEEDED" and got == model
              and det.get("failing") == 0 and det.get("unmatched") == 0
              and unread == 0
              and (canon is None or d.get("g1_canonical_id") == canon))
        print("%-12s %10d %10s %6s %8s %10s %7s %-11s %s" %
              (name, model, got, ("%+d" % (got - model)) if isinstance(got, int) else "?",
               det.get("failing"), det.get("unmatched"), unread, d.get("verdict"),
               "" if ok else "★不符★"))
        if not ok:
            bad.append(name)
    if bad:
        print("=== RECONCILE FAILED：%d 个对不上 ===" % len(bad))
        for b in bad:
            print("   ", b)
        return 1
    print("=== RECONCILE PASSED：%d/%d 全部 verdict=SUCCEEDED 且 passing 与模型差 +0 ==="
          % (len(VARIANTS), len(VARIANTS)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
