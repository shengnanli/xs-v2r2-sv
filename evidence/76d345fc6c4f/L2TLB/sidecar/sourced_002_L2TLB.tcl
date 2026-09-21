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
fm_target_vmucp_allow
