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
run "位置依赖闸"       python3 scripts/test_no_location_dependency.py
# 台账行序闸：我写了这条测试却没接进来（2026-09-14 由 bkperf worker 撞上才发现——
# 它追加台账行后 L1 从 181/181 掉到 178/181，而当时没有任何闸会响）。
run "台账行序闸"       python3 scripts/test_ledger_append_only.py
# FM Tcl 毒字符串闸：fm_shell 把入口 Tcl **逐行回显**进 fm.log（注释也不例外），
# 而 fm_verdict.py 的 _ELAB147/_DONTVERIFY 是在整份日志上做正则 —— 于是在注释里
# 完整写出这些串会让**每个目标**的判定中毒。agent/err3 实测撞到过：写全之后
# MuxBundle 当场从 SUCCEEDED 翻成 elab147=true 的 PARTIAL，而 RTL 一字未动。
run "FM Tcl 毒字符串闸"  python3 scripts/test_tcl_no_poison.py
# fm_eq.tcl 结构闸：该文件是多 worker 并行改的共享件，冲突全集中在 vmucp 白名单那行。
# 我两次处理错（"两侧都留"留出两条串联 if 互相拒目标；git add -A 提交了带冲突标记的
# 文件）。两次都修好却没加闸，于是下次合并原样复发。这道闸把"修好"变成"修住"。
run "fm_eq 结构闸"     python3 scripts/test_fm_eq_wellformed.py
# 家族生成器幂等：tlbuffer worker 发现 gen_tlbuffer_ad_family.py --check 一直报 DRIFT
# ——negtest 段是手工贴在生成产物后面的，谁跑一次生成器它就被静默删掉，而那正是该家族
# 唯一病因形态（位宽）的防护。只有挂了 --check 的生成器进这道闸。
for g in scripts/gen_tlbuffer_ad_family.py scripts/gen_mbist_pipe_family.py; do
  [ -f "$g" ] && run "生成器幂等 $(basename $g .py | sed 's/^gen_//')" python3 "$g" --check
done
rm -f /tmp/gate_$$.out
[ $rc -eq 0 ] && echo "=== 全部机器闸 PASS ===" || echo "=== 有闸未过，见上 ==="
exit $rc
