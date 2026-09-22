# vmucp 白名单条目：BitmapCache
#
# 本文件 = BitmapCache 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-22，本机实测，不是外推）----
#
# 打开前的读数（输入 commit b48b26b9d70226dc5f048e1636db4d4886b94d0e，signoff-strict，
#   FM_MERGE_DUP=false，黑盒边界为空（SRAM 一路 / MbistBitmapCache / ClockGate 两侧同源）；
#   证据 evidence/b48b26b9d702/BitmapCache/sidecar/native_facts.json）：
#     native SUCCEEDED
#     passing 13027（Port 110 + DFF 12916 + LAT 1）/ failing 0 / unverified 0 / aborted 0
#     unread_notcompared 42
#     unmatched.compare_ref 0, compare_impl 0, unread_ref 0, unread_impl 0, bbout 0/0
#     无 dont_verify、无 relaxed appvar、无 elab147、无 fm_pins / set_user_match
#   验收判定 PARTIAL，理由只有一条 strict_unread!=0。
#
# 这 42 个 matched-unread 点满足 vmucp standing rule 的"精确绑定 + 双射配对"：
# ref 侧 42 条路径互不相同、impl 侧 42 条路径互不相同，两侧去掉各自顶层前缀
# （golden 的 `BitmapCache/` 与重写核的 `BitmapCache/u_core/`）后**后缀逐字相同**：
#
#   $ python3 - <<'PY'
#     import json
#     j = json.load(open('evidence/b48b26b9d702/BitmapCache/sidecar/native_facts.json'))
#     p = j['objects']['matched_unread_notcompared_pairs']
#     rs  = [e['ref_path'][len('r:/WORK/BitmapCache/'):]         for e in p]
#     is_ = [e['impl_path'][len('i:/WORK/BitmapCache/u_core/'):] for e in p]
#     assert len(p) == 42 and len(set(rs)) == 42 and len(set(is_)) == 42
#     assert all(a == b for a, b in zip(rs, is_))
#     print('bijection OK, 42/42')
#   PY
#
# 这些点是什么（按机制分类，不按工具标签）——全是 golden 自身"存了但本锥内无读者"的位，
# 重写核照抄了同样的存储（少存就是 unmatched）：
#   · data_1_tag_reg[35:11] + [2:0]（28 位）：stageResp 级只读 tag[10:6]（组号 → PLRU）与
#     tag[5:3]（选字节），golden 却把整条 36 位 tag 打进了 stageResp 级寄存器；
#   · data_tag_reg[2:0]（3 位）：stageDelay 级比对只用 [35:11]，组号 [10:6] 在 stageReq 级
#     已经用掉，[2:0] 无人读；
#   · mbistBC/addrReg_reg[5:0] + addrRdReg_reg[5]（7 位）：MBIST 分发级把 6 位地址寄存器
#     全存，而下游 SRAM 只有 5 位地址（32 深），高位与读地址的第 5 位无读者；
#   · array_0_*_*/array/array/array_9_ext/reg_RW0_ren_reg（4 个）：厂商 SRAM 行为模型的
#     读使能寄存器，`+define+SYNTHESIS`（RANDOMIZE_GARBAGE_ASSIGN 未定义）下读数据
#     `RW0_rdata = ram[reg_RW0_addr]` 不再受它门控。
#
# 打开 vmucp 是**要求 FM 证更多**（unread 点变成真比较点），不是 waiver：
# 预期 passing 由 13027 涨到 13027+42=13069、unread 归零；
# 若打开后出现任何 failing，按 standing rule 立即停下诊断，不得回填白名单绕过。
fm_target_vmucp_allow
