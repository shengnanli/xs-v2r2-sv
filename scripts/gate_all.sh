#!/bin/bash
# gate_all.sh —— 一次跑齐全部机器闸（codex 0151 D61/D62）。
#
# 背景：anti-rot owner 交付时诚实指出"两道闸都没接进任何 Makefile，
# 交付状态下没有任何东西自动运行它们，这是防腐闸的一个真实弱点"。
# 这个脚本就是那条接线。
set -u
cd "$(dirname "$0")/.." || exit 2
rc=0
run() { printf '=== %-28s ' "$1"; shift; if "$@" >/tmp/gate_$$.out 2>&1; then echo PASS; else echo "★FAIL"; sed 's/^/    /' /tmp/gate_$$.out | tail -12; rc=1; fi; }

run "可读性 A-G"        python3 scripts/readability_audit.py --quiet
run "端口契约闸"        python3 scripts/port_contract_lint.py --all-impl
run "重复/分叉闸"       python3 scripts/equality_dup_lint.py
run "universe 冻结闸"   python3 scripts/check_universe_freeze.py
rm -f /tmp/gate_$$.out
[ $rc -eq 0 ] && echo "=== 全部机器闸 PASS ===" || echo "=== 有闸未过，见上 ==="
exit $rc
