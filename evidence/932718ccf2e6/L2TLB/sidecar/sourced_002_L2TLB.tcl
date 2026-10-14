# vmucp 白名单条目：L2TLB
#
# 本文件 = L2TLB 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-21，本机实测，不是外推）----
#
# 打开前的读数（输入 commit 07e6b07eeb47f77ea2ed4810ae1784294deb2437，
#   复跑：bash scripts/run_proof.sh L2TLB L2TLB；
#   证据 evidence/07e6b07eeb47/L2TLB/sidecar/native_facts.json）：
#     native SUCCEEDED
#     passing 28263 / failing 0 / unverified 0 / aborted 0
#     unread_notcompared 809
#     unmatched.compare_ref 0, compare_impl 0, bbout 0/0
#     无 dont_verify、无 relaxed appvar、无 elab147
#
# 这 809 个 matched-unread 点满足 vmucp standing rule 的"精确绑定 + 双射配对"：
# 逐条核过（判据可复跑，见下），**809 条全部**形如
#     r:/WORK/L2TLB/pmp/<X>   <->   i:/WORK/L2TLB/u_core/u_pmp/<X>
# 即：ref 侧 809 条路径互不相同、impl 侧 809 条路径互不相同、两侧去掉各自的顶层
# 前缀（golden 的 `pmp/` 与重写核的 `u_core/u_pmp/`）之后**后缀逐字相同**，
# 一一对应，没有任何人工强配（fm_pins / set_user_match 本目标都没有用）。
#
#   $ python3 - <<'PY'
#     import json
#     j = json.load(open('evidence/07e6b07eeb47/L2TLB/sidecar/native_facts.json'))
#     p = j['objects']['matched_unread_notcompared_pairs']
#     rs = [e['ref_path'][len('r:/WORK/L2TLB/'):]  for e in p]
#     is_ = [e['impl_path'][len('i:/WORK/L2TLB/u_core/'):] for e in p]
#     assert len(p) == 809 and len(set(rs)) == 809 and len(set(is_)) == 809
#     assert all(a.split('/',1)[1:] == b.split('/',1)[1:] for a, b in zip(rs, is_))
#     assert {a.split('/')[0] for a in rs} == {'pmp'}
#     assert {b.split('/')[0] for b in is_} == {'u_pmp'}
#     print('bijection OK, 809/809')
#   PY
#
# 这些点是什么：PMP 里 pmaMapping_* 那批常量化的地址/配置寄存器。PMP 在本证明里是
# **两侧展开**（不在 FM_INTERFACE_ONLY 名单上），所以它内部这批在本层锥内无读者的
# 寄存器会以 matched-unread 的形态出现。上一轮 G0 的同目标证明里是 537 条同类点
# （G1 的 PMP 由 2269 行涨到 4408 行），形态一致。
#
# 打开 vmucp 是**要求 FM 证更多**（unread 点变成真比较点），不是 waiver：
# 预期 passing 由 28263 涨到 28263+809=29072、unread 归零；
# 若打开后出现任何 failing，按 standing rule 立即停下诊断，不得回填白名单绕过。
#
# ---- 第 3 轮更新（2026-10-03，agent/l2tlb-assembly，8 个 child 两侧白盒展开之后）----
# 关闭 vmucp 的读数（evidence/413461528f8f/L2TLB，输入 commit 413461528f8f）：matched-unread
# **1288** 对，逐对核过全是双射（复核脚本逻辑写在 docs/lanes/l2tlb-assembly_prereg.md §9）：
#   1144 对：两侧去掉前缀（r:/WORK/L2TLB/ 与 i:/WORK/L2TLB/u_core/，实例 u_<x>↔<x>、
#            u_csr_delay↔csr_tmp_delay、u_sfence_delay↔sfence_tmp_delay）后后缀逐字相同，
#            或 csr_dup_<n>_<f>_reg[b] ↔ csr_dup_reg[n]\[f][b]（24 对）；
#            pmp 809 / llptw 109 / cache 93 / bitmapcache 42 / bitmap 25 / csr_tmp_delay 24 /
#            sfence_tmp_delay 10 / prefetch 4 / hptw 3 / ptw 1 / csr_dup 24。
#   144 对：verif/ut/L2TLB/fm_pins.tcl（scripts/gen_l2tlb_pins.py）按命名规则钉上的 glue 位。
# 预期打开后 passing 恰增 1288、unread 归零；出现 failing 即停下诊断。
#
# ---- 第 4 轮更新（2026-10-11，agent/l2tlb-gc，codex 0228 exact green_child 组合）----
# 22 种直接 child 中 21 种两侧 -interface_only 黑盒（arb1/Arbiter2_PtwReq 两侧白盒），上一轮那 1288 对里属于
# child 内部的 1144 对随 child 黑盒化不复存在；本层 glue 剩下的「两侧都无读者」点实测正好 128<->128
# （canary 1，worktree，不产 receipt：verif/ut/L2TLB/fm_work/L2TLB/unread_points.txt，vmucp 开时仍是
# unmatched unread，vmucp 对未配对点空转）——全是 resp_pte_sector 一族（8 槽 x 2 半 x 4 PTE x PTE[9:8]）。
# verif/ut/L2TLB/fm_pins.tcl（scripts/gen_l2tlb_pins.py，128 条精确一对一 set_user_match，字面计数 fail-closed）
# 把它们按命名规则配上 => 成为 matched-unread => 由本条 vmucp 实开比较。六条：
#   (1) 精确绑定：128 个 ref 名与 128 个 impl 名逐字等于生成器输出（机检，集合相等）；
#   (2) 双射：ref 侧 128 互异、impl 侧 128 互异、一一对应，无一对多/多对多；
#   (3) FM 实开比较：canary 2（arb1 白盒 + 128 钉点）passing 63052 = canary 1 的 63006 + 1（原唯一 failing 转 passing）
#       + 128（vmucp 实比的钉点对）- 83（arb1 改白盒后不再是黑盒输入引脚的 83 位），逐项对上；
#   (4) 全零：failing 0 / unverified 0 / unmatched（比较点、黑盒输出、unread）两侧 0 / unread 0；
#   (5) 无 dont_verify、无新黑盒（黑盒集合 = allow 声明的 21 design / 28 实例 x 两侧）；
#   (6) 本段即 manifest 摘要。出现 failing 即停下诊断，不得回填白名单绕过。
fm_target_vmucp_allow
