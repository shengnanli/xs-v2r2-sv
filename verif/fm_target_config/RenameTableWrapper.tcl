# vmucp 白名单条目：RenameTableWrapper
#
# 本文件 = RenameTableWrapper 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-27, agent/rtw）----
#   不加强的 assembly 基线（evidence/dc57056bf199/RenameTableWrapper，受理 commit
#   dc57056bf19901fa6d62a0f1349bcf9026855dc5）：native SUCCEEDED / passing 19748 /
#   failing 0 / unverified 0 / aborted 0 / unmatched 0 / 黑盒仅 14 个审定存储宏实例 /
#   无 dont_verify / 无 elab147，只剩 18 个 matched_nc（两侧都匹配上、但两侧都未读所以
#   FM 不比）：
#       r:/WORK/RenameTableWrapper/{v0Rat,vecRat,vlRat}/need_free_{0..5}_reg
#     ↔ i:/WORK/RenameTableWrapper/u_core/{v0Rat,vecRat,vlRat}/u_core/need_free_reg[0..5]
#   来源：RenameTable_2（vec 表）/ RenameTable_3（v0/vl 表）核里的 need_free 寄存器，
#   在 RenameTable 单独作目标时是活的（io_need_free_* 输出），但 golden RenameTableWrapper
#   只把 int/fp 两张表的 need_free 引到顶层（io_int_need_free_* / io_fp_need_free_*），
#   v0/vec/vl 三张表的这 18 位在本层两侧都无读者 —— 两侧同为死位、逐名自动配对
#   （auto_match，无 set_user_match、无强配），18 = 3 表 × 6 路。
#   预测登记 docs/fm_predictions/RenameTableWrapper.json 的 19766 与实测 19748 恰差 18：
#   加强后这 18 点从 unread_notcompared 转入 passing，预期 passing 回到 19766。
#   这是证明加强（多比 18 个状态），不是 waiver；DiffRatStateBuffer 目标不在本白名单
#   （它的 1 个 unread 是 impl 独有的 always_ff 临时量伪影，改 RTL 消掉，不能靠加强）。

fm_target_vmucp_allow
