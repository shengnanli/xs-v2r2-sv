#!/bin/bash
# gate_all.sh —— 一次跑齐全部机器闸（codex 0151 D61/D62）。
#
# 背景：anti-rot owner 交付时诚实指出"两道闸都没接进任何 Makefile，
# 交付状态下没有任何东西自动运行它们，这是防腐闸的一个真实弱点"。
# 这个脚本就是那条接线。
set -u
cd "$(dirname "$0")/.." || exit 2
rc=0

# ★"跑完了没有"之外，还得答"跑的是哪棵树"★（2026-09-20 实测补上）
# 缘起：本轮同时有三个 gate_all 实例在跑，其中一个是**陈旧**的（它执行的是还没接进
# 新闸的旧脚本、读的是还没修的旧树），它照样打印了一行格式完全正确的 `GATE_RC=1`。
# 那一行**作为"这棵树的判决"是假的**，而从日志上看它和真结果一模一样。
# 也就是说：`GATE_RC=` 解决了「结果存不存在」，但没解决「结果属于谁」。
# 所以再钉两件事：
#   (1) GATE_COMMIT= 记下跑在哪个 commit（带 -dirty 标记）；
#   (2) 开跑时与收尾时各取一次，**不相等就判红** —— 跑的过程中有人改了树，
#       这一轮结果就不属于任何一个确定的树状态，不能当判决用。
gate_stamp() {
  local h d
  h="$(git rev-parse --short=10 HEAD 2>/dev/null || echo nogit)"
  if git diff --quiet HEAD 2>/dev/null; then d=""; else d="-dirty"; fi
  printf '%s%s' "$h" "$d"
}
GATE_COMMIT_BEGIN="$(gate_stamp)"
echo "GATE_BEGIN commit=$GATE_COMMIT_BEGIN"
run() { printf '=== %-28s ' "$1"; shift; if "$@" >/tmp/gate_$$.out 2>&1; then echo PASS; else echo "★FAIL"; sed 's/^/    /' /tmp/gate_$$.out | tail -12; rc=1; fi; }

# 闸自身的树指纹判据负测：`GATE_RC=` 只回答"结果存不存在"，回答不了"结果属于谁"。
# 2026-09-20 实测：一个**陈旧**的 gate_all 实例（跑的是旧脚本、读的是旧树）照样打印了
# 一行格式完全正确的 `GATE_RC=1` —— 作为"这棵树的判决"那是假的，日志上却和真结果
# 长得一模一样。所以加了 GATE_COMMIT= 与"跑动期间树被改过即判红"，并给它配这道负测：
# 树没动必须判同（不能恒红）/ 树动了必须判异（不能恒绿）/ 脏树必须带 -dirty。
run "闸树指纹判据负测"  bash scripts/test_gate_stamp.sh
run "可读性 A-G"        python3 scripts/readability_audit.py --quiet
# A 类禁用命名正则的对照测试。★必须单独有一道★：2026-09-20 收紧那次，收紧前后在
# 全部 448 个 rtl/*.sv 上都命中 0 —— 拿仓库扫一遍对这次改动毫无分辨力。
run "可读性 A 类正则对照"  python3 scripts/test_readability_forbidden.py
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
# 参数覆盖闸（2026-09-20，DelayN lane 实测）：把共享核的参数改个名、例化不跟着改，
# VCS 只给 Warning-[AOUP] 就静默取默认值 —— DelayNWithValid 家族的 elaborate 期
# 守恒不变式就是这么被无声解除武装的（UT 照过、FM 照绿，六道闸没有一道会响）。
run "参数覆盖闸"        python3 scripts/check_param_override.py --quiet
run "参数覆盖闸负测"     python3 scripts/test_param_override_gate.py
# 证明证书（D57 green_child 背书的载体）的判据自测。★这两套测试此前一条都没进 gate_all★
# —— 文件在、能跑、没人跑；`check_gen_gate_complete.py` 只扫 scripts/gen_*.py，扫不到
# test_*.py，所以这个缺口不会有别的闸替它喊。
run "证书判据负测"       python3 scripts/test_proof_certificate.py
# 元负例：把 validator 换成恒 True/恒 [] —— 上面那套必须转红，否则它什么都没在看。
run "证书判据元负例"     env XSSV_CERT_TEST_SABOTAGE=all python3 scripts/test_proof_certificate.py
# child 的 impl 闭包里挂 golden（LqVAddrModule 现场那个形状）：正例 + 四个负例。
# recompute_closure_at 只复算 kind=='repo'，golden 条目被整个跳过 ⇒ D57 原九条一条不响。
run "证书 golden-in-impl" python3 scripts/test_proof_certificate_grandchild.py
run "证书 g-i-i 元负例"   env SABOTAGE_GC=1 python3 scripts/test_proof_certificate_grandchild.py
# 闸的完备性闸：任何 scripts/gen_*.py 要么进上面的列表，要么在
# check_gen_gate_complete.py 的 NO_CHECK 豁免表里写明理由，没有第三条路。
# WBArbiter 反饥饿状态机的可达性表：verif/ut/WBArbiterVariants/tb.sv 的覆盖判据是
# 分档的（N=1 全死 / N=2 只有第 1 路够得着 / N>=3 全可达），依据就是这张表。
# 判据来源必须能机器重算，否则"随机激励没跑到"会被当成"不可达"写进判据里。
run "WBArb 可达性表"     python3 scripts/wbarbiter_reachability.py --check


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
# FM Tcl 输出字符闸：毒字符串闸管的是"注释里写全关键词会污染正则"，
# 这一条管的是另一个机制 —— `puts`/`error` 里的 U+0080..U+00FF（× § · 这类）
# 会原样落成单字节进 fm.log，让 fm_verdict.py 的严格 utf-8 读日志当场崩，
# 于是 verdict 变空、MAKE_RC=2，却照样留下一个看起来齐全的 evidence 目录。
# 2026-09-20 实测踩到（TlbStorageWrapper_2/_3），判据自带双向自测。
run "FM Tcl 输出字符闸"  python3 scripts/test_tcl_output_ascii.py
run "FM Tcl 输出闸负测"  python3 scripts/test_tcl_output_ascii.py --selftest
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
# 钉点「调用序列等价」闸：钉点结构闸管的是"守卫写对没有"，这一条管的是另一件事 ——
# **fm_pins*.tcl 在证明闭包里**（receipt 的 proof_config.pin_scripts 记它的 sha256），
# 所以每次有人动它都要回答"既有 receipt 还算不算数"。判据只有一条：发射出去的
# set_user_match 调用序列有没有变。没变 = 守卫专属，receipt 继续有效；变了 = 新前提，
# 必须重出 receipt。
# ★为什么不能"逐字节比对两版的 set_user_match 行"★：本仓钉点文件多数把调用写在循环里，
# 那一行恰恰就是被改的守卫本身，照字面比等于自问自答。所以改成把 set_user_match 换成
# 记参数的桩、用 tclsh 真跑、逐字节比**实际发生的调用序列**。
# 先跑双向负测（真守卫专属必须判绿 / 真改了钉的点必须判红 —— 只判红的实现和恒等判绿的
# 实现都会在这里露馅），再对着基线表 docs/pin_call_seq.tsv 核对。两条加起来约 12 秒。
run "钉点调用序列闸负测"  python3 scripts/pin_call_equiv.py --selftest
run "钉点调用序列闸"     python3 scripts/pin_call_equiv.py --check
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
         scripts/gen_newdispatch_tb.py scripts/gen_tlbnb_family.py \
         scripts/gen_predictor.py scripts/gen_rob.py \
         scripts/gen_rob_ut.py scripts/gen_sbuffer.py \
         scripts/gen_sbuffer_tb.py scripts/gen_tlbsw_family.py \
         scripts/gen_rob_pins.py scripts/gen_rob_contract.py \
         scripts/gen_rob_iface.py; do
  [ -f "$g" ] && run "生成器幂等 $(basename $g .py | sed 's/^gen_//')" python3 "$g" --check
done
# UT 目录下的生成器不在 check_gen_gate_complete.py 的扫描范围（它只扫 scripts/gen_*.py），
# 所以挂了 --check 的要手动登记。gen_tb_variant.py 生成 tb_1/tb_2/tb_3.sv 三份 tb。
for g in verif/ut/TlbStorageWrapper/gen_tb_variant.py; do
  [ -f "$g" ] && run "UT tb 生成器幂等 $(basename $(dirname $g))" bash -c "cd $(dirname $g) && python3 $(basename $g) --check"
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
# fm_eq.tcl 的 switch 块必须 tclsh 可解析（2026-09-20，Entries lane 踩到）：
# 一段加错位置的注释（落进 switch 的花括号里）让**本仓每一次 FM 都在 setup 阶段死掉**，
# 而没有任何现成的闸会响。这道闸不需要 Formality，跑一次几十毫秒。
# Rob 折叠探针的分词器负测（秒级，不扫 golden）。这把探针的输出被当成"golden 的
# 每条目逻辑能不能折成一个 for 循环"的证据，而它一旦分词错，**不报错、不为空**，
# 只是给出一份形状看着很合理的假语句树（实测：把 160 个并列 if 解成 160 层 else 链）。
# 假证据比没证据更贵，所以它自带负测，负测自带"把修复退回去必须变红"的反测。
run "Rob 折叠探针负测"   python3 scripts/test_rob_fold_probe.py
# Rob robDeqGroup 射程量具的负测（秒级）。它给出的 116/633 与 577/633 两个数是
# 一条工程决定（这一族留不留空）的唯一依据，而让它**偏小且不报错**的那个坑
# ——多维 packed wire `wire [7:0][6:0] X = ...` 被单方括号正则漏掉——实测会把
# 517/667 变成 325/667，两个数看着都合理。所以正则本身要有反测钉住。
run "Rob 射程量具负测"   python3 scripts/rob_deqgroup_blast.py --selftest
# Rob 接口契约的判据自测：三条负例 + 一条元负例（把 classify 换成"什么都算网"，
# PIN 分布必须变）。它挡的是"判定字段名打错 -> 安静地得到一个空子集"——
# 空子集和真结论在表里长得一模一样。
run "Rob 接口契约负测"   python3 scripts/gen_rob_iface.py --selftest
# debug_otherPdest 射程：四条从 golden/Scala 现算的事实（56 输出 / 56 寄存器从不被赋值 /
# ★父层 CtrlBlock 把 56 个全接成 `/* unused */`★ / Scala 源树里只出现 1 次）。
# 它挡的是"金标准变了而结论没跟着变"——这四条是那个待裁设计选择的全部依据。
# 先跑负测（三条种病），再跑真闸。
run "otherPdest 射程负测"  python3 scripts/rob_otherpdest_scope.py --selftest
run "otherPdest 射程闸"    python3 scripts/rob_otherpdest_scope.py --check
run "fm_eq.tcl 语法负测" python3 scripts/check_fm_eq_tcl_syntax.py --selftest
run "fm_eq.tcl 语法闸"   python3 scripts/check_fm_eq_tcl_syntax.py
# per-target 数据不许回到 fm_eq.tcl（2026-09-20 拆分之后的守门人）：
# 那个文件是每条 lane 都在改的共享件，而 child 证书绑着它的 sha256 ——
# 实测 6 份证书里 4 个互不相同的 fm_eq.tcl 哈希、**没有一个**等于 HEAD，
# 而同样被绑的 fm_native_emit.tcl 6 份里有 4 份等于 HEAD。白名单与目标专属 appvar
# 因此搬进 verif/fm_target_config/<top>.tcl；这道闸盯的是"别搬回来"。
run "fm_eq 无目标数据负测" python3 scripts/check_fm_eq_no_target_data.py --selftest
run "fm_eq 无目标数据闸"   python3 scripts/check_fm_eq_no_target_data.py
# 唤醒匹配的判别轴表（E1 作用域的依据）：改共享核的唤醒匹配前必须复跑核对。
# ★判别轴不是"族"，是「每 lane 带几个 wen × 掩码有没有把 kind 不同的源隔开」★
# —— 按族切会漏掉 D 档的 EntriesVlduVstu（VEC 族却要多对+按源分 kind）。
run "唤醒判别轴表"      python3 verif/ut/Entries_field_matrix/wakeup_axis.py --check
# initreg 判据的负测（真跑探针要 VCS，不进 gate_all；这里只把判据本身守住）：
# ★"两轮 initreg 都绿"证明不了复位域★，而"两轮日志 md5 不等"是 fail-open 的
# （命令行里就带着 +vcs+initreg+0/random）。判据见脚本文件头。
run "initreg 判据负测"  python3 scripts/check_initreg_effective.py --selftest
# 变异体计分规则的负测（0920 裁定：编不过是"无效变异体"，分子分母同时剔除）：
# 计分规则出错不会报警，只会让 "抓住 N/M" 里的 M 悄悄变小、成绩悄悄变好看。
run "变异计分负测"      python3 verif/ut/Entries_common/mutants.py --selftest-classify
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
run "StoreQueue 骨架幂等" python3 scripts/gen_storequeue.py --check
run "StoreQueue tb 幂等"  python3 scripts/gen_storequeue_ut.py --check
# perf 分档闸（codex 0162 D3）：重绑表只回答"绑上了没有"，不回答"这条差异挡不挡里程碑"。
# D3 把计数器分成"必须相等"和"显式归类后允许不同"两类，而后者的豁免**有有效期**——
# 它只在"持有模块本轮未重写"时成立。没有闸的话，Tage_SC 被重写之后那 6 条 tage
# provider 差异会继续挂着 WAIVED，谁也不会发现豁免早就失效了。
# 这道闸把三件事钉住：台账能从 golden 现场重算 / 不许有"未分类" / 豁免逐条现算。
# 先跑负测（秒级，不扫 golden），再跑真闸（约 80 秒）—— 顺序照层次重绑闸的先例。
run "perf 分档闸负测"    python3 scripts/test_perf_tier_gate.py
run "perf 分档台账闸"    python3 scripts/check_perf_tier.py

# passing 预测模型自校准（docs/tlbsw23_passing_prediction.md）：
# 模型 = 闭包触发器位数 + 顶层 output 位数。6 个已签核点必须逐位命中，
# 命不中说明量法或模型有问题 —— 那时它做出的预测就不该被引用。
run "passing 模型自校准"  python3 scripts/tlbsw_passing_model.py --check
# ★跑前登记那套工具自己的自证也要进闸★（2026-09-20，agent/provefleet3）
# 落地时这两条都**不在** gate_all 里：`fm_predict --selftest` 从加进来就没人跑，
# `fm_passing_model --selftest` 是本轮新写的。一条没人跑的自证等于没有自证 ——
# 本轮就靠它当场抓到两件事（模型缺 BBPin 项、cmd_register 把展示串写进了 note），
# 而这两件事都是**跑完 FM 才发现**的，正说明缺的是跑在前面的那道闸。
run "passing 模型 BBPin 自证"  python3 scripts/fm_passing_model.py --selftest
run "跑前登记判据负测"      python3 scripts/fm_predict.py --selftest

rm -f /tmp/gate_$$.out

# 收尾再取一次树指纹：与开跑时不同 = 跑的过程中树被改过，这一轮不属于任何确定状态。
GATE_COMMIT_END="$(gate_stamp)"
if [ "$GATE_COMMIT_BEGIN" != "$GATE_COMMIT_END" ]; then
  echo "★树在本轮跑动期间被改过★ begin=$GATE_COMMIT_BEGIN end=$GATE_COMMIT_END"
  echo "  这一轮的 PASS/FAIL 不对应任何一个确定的树状态，不能当判决用 —— 树 settle 后重跑。"
  rc=1
fi
[ $rc -eq 0 ] && echo "=== 全部机器闸 PASS ===" || echo "=== 有闸未过，见上 ==="
echo "GATE_COMMIT=$GATE_COMMIT_END"

# ★终止标记：只有走到脚本结尾才可能打印这一行★（2026-09-20）
# 判读方只认这一行：没有 GATE_RC= 就是「结果不存在」，既不是绿也不是红。
# 缘起：一条 lane 拿还在跑的 stdout 前几行当成了结果，写下「其余闸全 PASS」，
# 跑完实际红三条。「没看见 FAIL」与「还没跑到那一条」在流式输出里长得一模一样。
# 详见 CONVENTIONS.md ★"闸跑完了没有"本身也要有判据★
echo "GATE_RC=$rc"
exit $rc
