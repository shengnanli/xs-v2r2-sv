# vmucp 白名单条目：WBArbiter_3
#
# 本文件 = WBArbiter_3 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# WBArbiter_3 / _38 / _58 / _66 加入依据(2026-09-20, agent/fubusy-wbarb 实测)：
# 这四个**恰好是 WBArbiter 家族里 N=1 的全部变体**，其余 9 个(N>=2)本来就
# native+strict 双 SUCCEEDED / unread 0，不在白名单里也不需要。
# 加入前基线(evidence/201cb5db74de/，55 目标一轮跑完)：四个都是
#   native SUCCEEDED / failing 0 / unverified 0 / aborted 0 / 比较点 unmatched 0(0)，
#   唯一卡点是 **2(2) 个 unmatched unread**，四份 unread_points.txt 形状逐字相同：
#     ref  cancelCounter_0_reg[0]        <-> impl u_core/cancel_cnt_q_reg[0][0]
#     ref  hasFull_reg                   <-> impl u_core/has_full_q_reg
#   ref 侧 2 个唯一点对 impl 侧 2 个唯一点，非该形状的项为 0，严格双射。
# 死因两侧同源、且**在签核之前就已定论**：scripts/wbarbiter_reachability.py
#   把 golden 的次态方程原样搬进脚本穷举可达状态，N=1 时可达状态只有 1 个(全 0)
#   —— 只有一路请求 ⇒ 它恒为最高优先级 ⇒ in_ready 恒 1 ⇒ stalled 恒 0 ⇒
#   cancelCounter 永不自增、isFull/hasFull 永不置位。这 5 位是 golden 自己的
#   死逻辑，重写核照抄(xs_WBArbiter_core 不因 N=1 裁剪)，于是对称死。
#   ★不许"把它们删掉图干净"★：删了就从对称死位变成 golden-only 死位，连双射
#   都没有 —— 与 TLBFA 不收窄 reqVpn、RenameBuffer 不只留 head 同一个结论。
#   5 位里另外 3 位(cancelCounter bit1/bit2、isFull)被 FM 常量折叠吃掉，
#   两侧一起消失，既不是比较点也不是未读点。
# 配对在 verif/ut/WBArbiterVariants/fm_pins.tcl(四层 fail-closed，钉不上即 exit 3)；
# unmatched unread 单开 vmucp 必然空转，所以顺序是**先配对、再加强**。
# ★复核判据与实测（判据先写、实测后填，两个数都留着）★
#   写在跑之前的判据是"passing 各 +2"（2→4 / 10→12 / 9→11 / 7→9）——按"钉了 2 点
#   就该多比 2 点"推的。**实测是各 +1**：2→3 / 10→11 / 9→10 / 7→8，
#   另有 `Constant reg 1` 一行。两个点都没有被吞掉，去向是分开的：
#     hasFull_reg ↔ u_core/has_full_q_reg        进 matched DFF，passing +1
#     cancelCounter_0_reg[0] ↔ cancel_cnt_q_reg[0][0]
#                                                FM 判成常量寄存器，落进 Not Compared
#   守恒成立：2 钉点 = 1 passing + 1 Constant reg；unread 0、unmatched 六项全零、failing 0。
#   "Not Compared" 那一个不是盲区，有负控实证：verif/ut/WBArbiterVariants/mutants.py
#   的 F5 把 cancelCounter 的复位值 0 改成 1，它不再是常量，FM 当场报 failing 1
#   （`python3 mutants.py --fm`，该条目指定跑在 WBArbiter_3 上）。
#   一般判据仍然是：passing 不增而 unread 归 0 = 点被吞掉，不算过。

fm_target_vmucp_allow
