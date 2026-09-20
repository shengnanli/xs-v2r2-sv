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
# 空壳不得抬高 proven 覆盖率（2026-09-16）：覆盖率台账原来按「rtl/ 里有同名 module」
# 记账，于是一个只实现两成逻辑的 LoadQueueReplay 骨架就把覆盖率从 7.4% 抬到 11.0%，
# 凭空记 138,860 行 golden。判据已改成按绿判决证据记；这道闸把「改好了」变成「改住了」。
run "覆盖率空壳闸"     python3 scripts/test_coverage_no_shell_inflation.py
# round 台账必须与**已提交的 receipt** 逐字节一致。它是 proven 口径的输入之一，
# 以前是手写的 —— 手写台账必然有两个病：漏记（proven 虚低）与错记（数字与 receipt
# 对不上，而台账才是被引用的那份）。病根都是台账与证据之间隔着一个人。
run "round 台账幂等"   python3 scripts/harvest_round_ledger.py --check --out docs/fm_round_20260917.tsv
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
# FM 钉点文件结构闸：fm_pins_pre.tcl / fm_pins.tcl 是唯一被 source 进 fm_shell 的
# 「模块本地代码」，语法上什么都干得了（放宽比较、钉常量、加黑盒、改 appvar），
# 而 sidecar 下被 source 的脚本**不会**逐行回显进 fm.log，判定未必看得见。
# 第二件事更隐蔽：钉点文件不 fail-closed 就等于没钉 —— 名字一漂，set_user_match 逐条
# 失败、脚本只 puts 一行 miss=N，证明照跑照绿，而那行 miss 没人会看。
# 本闸落地时实测：15 个钉点文件里 12 个是 fail-open 的（期望数量只写在 puts 字符串里）。
run "FM 钉点结构闸"     python3 scripts/test_fm_pins_wellformed.py
# 家族生成器幂等：tlbuffer worker 发现 gen_tlbuffer_ad_family.py --check 一直报 DRIFT
# ——negtest 段是手工贴在生成产物后面的，谁跑一次生成器它就被静默删掉，而那正是该家族
# 唯一病因形态（位宽）的防护。只有挂了 --check 的生成器进这道闸。
# gen_sram_wrappers.py 2026-09-14 进闸：它当时**不是**幂等的——33 个薄文件里的 6 个
# G1_* 锚点和 UT Makefile 的 negtest 段都是手工补在生成产物上的，谁跑一次生成器
# 就全没（与 tlbuffer 同一个病）。并回生成器后才挂上 --check。
# 2026-09-17 补：这个列表原先只有三个，而实测 11 个 scripts/gen_*.py 里有 6 个支持
# --check —— gen_ndaux / gen_npc_missing3 / gen_splittedsram 三个一直在闸外。
# 三个都能跑通、都是幂等的，也就是说漏的不是坏文件，是**没人记得加**。
# 所以除了把它们补进来，下面还加了一道 check_gen_gate_complete.py 专门堵这个形状。
# 2026-09-17 再补三个：check_gen_gate_complete.py 上线当天就抓到的三条 lane 新生成器
# （gen_renamebuffer / gen_tlbfa_family / gen_sbufferdata）。三条 lane 各自都写了 --check
# 却都没人要求它们去登记 —— 正是这道闸设计时说的"忘了加就静默漏"。
# 这里先把名字放进来：`[ -f "$g" ]` 会跳过尚未合入的文件，所以提前登记无害，
# 合入当天自动生效，不用再记得回来加一次。
for g in scripts/gen_tlbuffer_ad_family.py scripts/gen_mbist_pipe_family.py \
         scripts/gen_sram_wrappers.py scripts/gen_ndaux.py \
         scripts/gen_npc_missing3.py scripts/gen_splittedsram.py \
         scripts/gen_renamebuffer.py scripts/gen_tlbfa_family.py \
         scripts/gen_sbufferdata.py scripts/gen_newdispatch.py \
         scripts/gen_newdispatch_tb.py \
         scripts/gen_tlbnb_family.py scripts/gen_predictor.py \
         scripts/gen_rob.py scripts/gen_rob_ut.py \
         scripts/gen_lqreplay.py scripts/gen_lqreplay_ut.py; do
  [ -f "$g" ] && run "生成器幂等 $(basename $g .py | sed 's/^gen_//')" python3 "$g" --check
done
# 闸的完备性闸：任何 scripts/gen_*.py 要么进上面的列表，要么在
# check_gen_gate_complete.py 的 NO_CHECK 豁免表里写明理由，没有第三条路。
run "生成器闸完备性"     python3 scripts/check_gen_gate_complete.py
# UT initreg 棘轮：147 个 UT 里 68 个的 Makefile 完全没提 initreg（2026-09-17 实测），
# 也就是说这些目标的 UT 验收是在"寄存器初值由 VCS 默认决定"下过的。
# 存量一次性补齐要重跑 68 个 UT 且大概率真跑红一批，不在别的工作进行中引爆；
# 所以只做"可见 + 不许再涨"，新 UT 必须合规。
run "UT initreg 棘轮"   python3 scripts/check_ut_initreg.py
# 工具派生态不许进版本控制。.gitignore 单独挡不住，实测三例：
#   (1) 仓库根 FM_INFO/   —— 规则 `/FM_INFO*/` 是它进库之后才加的，ignore 管不住已跟踪文件
#   (2) verif/ut/EntriesAluCsrFenceDiv/fm_diag{,2..7}/ —— 994807 行 / 77.8 MB，
#       占该分支插入行数 86.4%；老规则按**固定深度**写死，深一层就漏
#   (3) verif/ut/NewPipelineConnectPipe/neg_build/ —— ★规则早就在了，文件照样进库★
# (3) 说明光有 ignore 不够：它只拦未跟踪的新文件，拦不住 `git add -f`
# （而 evidence/ 恰恰要靠 -f 提交，养成习惯就会顺手把 scratch 一起拖进来）。
# 故必须有一道**对着已跟踪文件列表**跑的闸。先负测（含"长得像但不是"的反例）再跑真闸。
run "工具派生态负测"     python3 scripts/test_no_tool_scratch_gate.py
run "工具派生态闸"       python3 scripts/check_no_tool_scratch.py
# rtl/ 下不许有 .svh、不许有 `include。CONVENTIONS「单文件规范」早有此禁令，
# 但一直没有闸 —— 靠的是"没人加过"。2026-09-18 审计上一轮时量出真正的危险，
# 而且和当初设想的不是同一回事：
#   上一轮 202 个 .svh / 199,801 非注释行，逐字抄 golden 的**实质逻辑行只有 1.83%**，
#   而 .sv 同口径 8.19% —— ★.svh 的照抄密度只有 .sv 的一半，"svh 是藏赃点"这个假设是错的★。
#   真问题更隐蔽：那 204,373 行（占上轮 rtl 的 29%）**整体绕过了可读性闸**，
#   因为 readability_audit.py 和 prev_round_verbatim_scan.py 都只 rglob('*.sv')。
#   ★是审计盲点，不是藏赃点。★
# 本轮 readability_audit.py 至今仍只扫 *.sv（第 81、313 行），同一个盲点机制原样存在。
# 与其改那个大脚本（风险高），不如在源头堵死：rtl/ 下根本没有 .svh，"只扫 .sv"就等于扫全了。
run "rtl 无 svh 负测"    python3 scripts/test_no_svh_gate.py
run "rtl 无 svh 闸"      python3 scripts/check_no_svh_in_rtl.py
# fm_eq.tcl 的 switch 块必须 tclsh 可解析（2026-09-20，Entries lane 踩到）：
# 一段加错位置的注释（落进 switch 的花括号里）让**本仓每一次 FM 都在 setup 阶段死掉**，
# 而没有任何现成的闸会响。这道闸不需要 Formality，跑一次几十毫秒。
run "fm_eq.tcl 语法负测" python3 scripts/check_fm_eq_tcl_syntax.py --selftest
run "fm_eq.tcl 语法闸"   python3 scripts/check_fm_eq_tcl_syntax.py
# 覆盖台账的证据链：docs/coverage_three_axis.tsv 宣称的每条证明都要能从**版本库**复现。
# 2026-09-18 实测出事状态：轴2 标 PROVEN_DIRECT 133 个，版本库里找得到通过 receipt 的
# 只有 34 个，★189 个找不到★（重算后缺口扩大到 90）。那些证明并非不存在 —— evidence 全
# 躺在主 worktree 磁盘上（当时磁盘 1339 份 receipt，tracked 只有 77 份），根子是
# evidence/ 在 .gitignore 里、必须 git add -f 才进得去，而没人系统地做。
# 后果：clean clone 复现不了台账宣称的绝大多数证明 —— 不是数字不准，是证据链断了。
# 出事前全仓 grep 不到任何 Makefile/CI/脚本校验这张表的新鲜度，两张表脱节 6 天没人发现，
# 因为没有任何机制能发现。先负测（含"universe 之外的目标有 receipt 不算漏记"这个反例）再跑真闸。
run "覆盖证据链负测"     python3 scripts/test_coverage_provenance_gate.py
run "覆盖证据链闸"       python3 scripts/check_coverage_provenance.py --strict
# 上面三条是**逐个**挂 --check 的 scripts/gen_*.py。verif/ut/*/gen.py 那一层有 9 个，
# 其中 8 个根本没有 --check（SRAMTemplateNewForm 是最后一个敞口）。与其逐个改生成器，
# 不如统一验一次：在 HEAD 上开 detached worktree 重跑全部，产物必须逐字不变。
# 好处是新加的生成器自动进闸，不会因为"忘了挂 --check"再敞一个口。
run "生成器幂等 verif/ut/*"  python3 scripts/test_gen_idempotent.py
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
# perf 分档闸（codex 0162 D3）：重绑表只回答"绑上了没有"，不回答"这条差异挡不挡里程碑"。
# D3 把计数器分成"必须相等"和"显式归类后允许不同"两类，而后者的豁免**有有效期**——
# 它只在"持有模块本轮未重写"时成立。没有闸的话，Tage_SC 被重写之后那 6 条 tage
# provider 差异会继续挂着 WAIVED，谁也不会发现豁免早就失效了。
# 这道闸把三件事钉住：台账能从 golden 现场重算 / 不许有"未分类" / 豁免逐条现算。
# 先跑负测（秒级，不扫 golden），再跑真闸（约 80 秒）—— 顺序照层次重绑闸的先例。
run "perf 分档闸负测"    python3 scripts/test_perf_tier_gate.py
run "perf 分档台账闸"    python3 scripts/check_perf_tier.py

rm -f /tmp/gate_$$.out
[ $rc -eq 0 ] && echo "=== 全部机器闸 PASS ===" || echo "=== 有闸未过，见上 ==="
exit $rc
