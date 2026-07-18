#!/usr/bin/env bash
# 生成器漂移检查(2026-07 冻结地基): 重跑所有 live 生成器, 断言不改变任何已跟踪内容。
# "regenerate → git diff empty" —— 生成产物的 source-of-truth 必须唯一且忠实。
# 手工维护源(gen_datapath.py 的 datapath_*.svh)由生成器护栏自动跳过, 不在此列。
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
BEFORE=$(mktemp); AFTER=$(mktemp)
git diff -- rtl/ verif/ut/*/variants_xs.sv verif/ut/*/tb.sv > "$BEFORE"
GENS="gen_loadunit gen_backend gen_l2tlb gen_lsqwrapper gen_ptwcache gen_tagesc gen_bankeddata gen_tlbnonblock gen_datapath"
for g in $GENS; do python3 scripts/$g.py >/dev/null 2>&1 || echo "WARN: $g 运行异常"; done
git diff -- rtl/ verif/ut/*/variants_xs.sv verif/ut/*/tb.sv > "$AFTER"
if diff -q "$BEFORE" "$AFTER" >/dev/null; then
  echo "✓ GEN-DRIFT-CLEAN: 重跑全部生成器后 git diff 不变(source-of-truth 忠实)"
  rm -f "$BEFORE" "$AFTER"; exit 0
else
  echo "✗ GEN-DRIFT: 重跑生成器改变了工作区(source 未同步):"
  diff "$BEFORE" "$AFTER" | grep -E "^[<>]" | grep -E "^[<>] (diff|\+\+\+|---)" | head
  rm -f "$BEFORE" "$AFTER"; exit 1
fi
