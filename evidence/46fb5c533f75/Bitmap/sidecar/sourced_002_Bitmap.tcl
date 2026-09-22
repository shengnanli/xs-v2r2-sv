# vmucp 白名单条目：Bitmap
#
# 本文件 = Bitmap 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-22，首跑 evidence/36600b5a07b8/Bitmap，impl commit 36600b5a）----
# signoff-strict 首跑 native SUCCEEDED / passing 1761 / failing 0 / unverified 0 /
# unmatched 0（compare 两侧 0）/ constant_reg 3，仅 unread 卡住，两族共 24 点：
#   (a) matched_nc 16 点：io_pmp_req_bits_addr_r_reg[63:48]。golden 用 RegEnable 存了
#       `getBitmapAddr` 的完整 64 位和（Bitmap.sv:2885），输出只取 [47:0]（:3329），
#       高 16 位两侧同名同路径（r:/WORK/Bitmap/<X> ↔ i:/WORK/Bitmap/u_core/<X>），
#       FM 自己按名配好，16↔16 双射，非 matched_nc 项为 0。
#   (b) unmatched unread 8↔8：entries_<i>_id_reg[3]，bMemID 4 位而请求 id 3 位，
#       golden 写 {1'h0, id}（:1517）、读只取 [2:0]（:3328），两侧同为 cone-dead；
#       可读核是数组名 entries_id_reg[<i>][3]，由 verif/ut/Bitmap/fm_pins.tcl 按
#       `entries_(\d+)_id_reg[3] -> entries_id_reg[\1][3]` 显式 set_user_match，
#       期望数 8 机械推导（8 条目 × 1 位），钉点文件 fail-closed。
# 开 vmucp 后这 24 点由 FM 实际比较（加强，不是放过）。
# ★跑前复核判据★：passing 应为 1761 + 24 = 1785，与 docs/fm_predictions/Bitmap.json
# 登记的 1788 之差 3 = constant_reg 3，unread 归零，failing/unmatched 仍 0。

fm_target_vmucp_allow
