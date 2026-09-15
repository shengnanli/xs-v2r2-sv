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
# package 作用域闸（codex 0158 §3）：重复/分叉闸只认**模块**重名，看不见 **package**
# 重名 —— 而 package 名在 SystemVerilog 里同样是全局的。实测 rtl/ 下 57 个包里有 2 个
# 重名（vset_pkg / xs_predecode_pkg），UT+FM 全绿、10 道闸全过，整芯片 elaborate 第一次
# 跑就 Error-[SV-PPD]。修完立刻配闸，否则下一个共用包还会这么长出来。
run "package 作用域闸"   python3 scripts/check_pkg_scope.py
# package 闸的负测（codex 0158 §3 续）：闸"跑了且退出 0"不等于"它会响"。
# 这里在临时 rtl 树里逐条判据各种一个病（包重名 / 跨文件共享包 / $unit 作用域 import），
# 要求闸每次都红；同时钉住两种合法的模块头 import 写法不许被误报。
run "package 闸负测"     python3 scripts/test_pkg_scope_gate.py
run "universe 冻结闸"   python3 scripts/check_universe_freeze.py
run "位置依赖闸"       python3 scripts/test_no_location_dependency.py
# 台账行序闸：我写了这条测试却没接进来（2026-09-14 由 bkperf worker 撞上才发现——
# 它追加台账行后 L1 从 181/181 掉到 178/181，而当时没有任何闸会响）。
run "台账行序闸"       python3 scripts/test_ledger_append_only.py
# 覆盖率台账幂等（codex 0161）：三个口径必须能从 golden 与 rtl/ 现场重算。
# 它存在的理由是"253/253"曾被读成"重写完成"，而实测按行数只有 7.4%。
run "覆盖率台账幂等"   python3 scripts/rewrite_coverage.py --check
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
# gen_sram_wrappers.py 2026-09-14 进闸：它当时**不是**幂等的——33 个薄文件里的 6 个
# G1_* 锚点和 UT Makefile 的 negtest 段都是手工补在生成产物上的，谁跑一次生成器
# 就全没（与 tlbuffer 同一个病）。并回生成器后才挂上 --check。
for g in scripts/gen_tlbuffer_ad_family.py scripts/gen_mbist_pipe_family.py \
         scripts/gen_sram_wrappers.py; do
  [ -f "$g" ] && run "生成器幂等 $(basename $g .py | sed 's/^gen_//')" python3 "$g" --check
done
# 仿真 collateral 闸（codex 0160 §Canonical simulation collateral）：
# verif/sim/collateral/ 是「干净 checkout 能跑起仿真」所缺的 13 个生成物（207 KiB）——
# G1-canonical 只冻结 golden-rtl/，不含 generated-src，少了它 VCS 连 golden 侧都编不出来。
# 生成物进版本库就会腐烂：RTL 换一版、DPI 接口跟着变，而库里这份不会自己跟着走。
# 判据 B 把 run_fullchip.sh 的 check_dpic 门禁（dpic 的 v_difftest_* 集合 == golden
# GatewayEndpoint.sv 例化的 DummyDPICWrapper_* 集合）从「跑仿真才发现」提前到「跑闸就发现」
# —— 那个形态实测让 **golden 自己**一跑就 Error-[DPI-DIFNF]，而且长得很像 impl 的 bug。
# 先负测（秒级，不读 golden），再跑真闸，顺序照 package 闸的先例。
run "仿真 collateral 负测"  python3 scripts/check_sim_collateral.py --selftest
run "仿真 collateral 闸"    python3 scripts/check_sim_collateral.py
# 层次重绑映射表幂等（codex 0159 §F-class）：docs/hier_rebind_map.tsv 是
# difftest 探针/故障注入 scope/DFT 存储路径重绑的唯一依据。它由 golden 例化图 +
# 重写件例化图 + docs/hier_rebind_decl.tsv 机械算出 —— 任何一侧动了（多吸收一个
# 子模块、改一个 generate 标号、改一个实例名），表就该跟着变。没有这道闸，表会在
# 无人察觉的情况下变成过期的路径，而过期的探针路径不会报错，只会**静默探到空**。
# 代价：约 90 秒（要扫 1.8 GB golden + 全部重写件）。
# 先跑负测（秒级，不扫 golden），再跑真闸（约 60 秒）—— 顺序照 package 闸的先例。
run "层次重绑闸负测"     python3 scripts/test_hier_map_gate.py
run "层次重绑表幂等"     python3 scripts/hier_map.py --check
# perf 观测重绑（codex 0160 P2）：docs/perf_bore_map.tsv 决定整芯片仿真里
# **哪些 perf 计数器算数、哪些不算数**。它由 golden SimTop 的 XMR 表 + golden
# LogPerfEndpoint 的打印串 + 重写件例化图机械算出 —— 任何一侧动了，表就该跟着变。
# 没有这道闸，表会悄悄过期，而过期的后果不是报错，是**印出一串看着像测量值的 0**。
# 先跑负测（秒级，不扫 golden），再跑真闸（约 90 秒）—— 顺序照层次重绑闸的先例。
run "perf 重绑闸负测"    python3 scripts/test_perf_rebind_gate.py
run "perf 重绑表幂等"    python3 scripts/perf_rebind.py --check

rm -f /tmp/gate_$$.out
[ $rc -eq 0 ] && echo "=== 全部机器闸 PASS ===" || echo "=== 有闸未过，见上 ==="
exit $rc
