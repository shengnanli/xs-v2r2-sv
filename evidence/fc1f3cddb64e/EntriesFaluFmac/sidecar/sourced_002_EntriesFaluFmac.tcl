# vmucp 白名单条目：EntriesFaluFmac
#
# 本文件 = EntriesFaluFmac 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   ★Entries* 家族其余 7 个变体(2026-09-20 加，本轮一次性 7 个)★
#          与上面 EntriesAluCsrFenceDiv / EntriesVfdivVidiv **同一物种、同一份生成器**：
#          golden 把条目负载展平成逐字段寄存器，其中"只为 transEntry 存、本变体发射口
#          看不见"的那一段在 Entries 这一层没有任何输出锥 ⇒ 两侧都没人读 ⇒ matched_nc。
#          钉点由 verif/ut/<变体>/gen_fm_pins.py 从 golden 实例连线**机械提取**
#          （与生成 RTL 用的是同一张 Variant.pl_off 偏移表），不是人工列表。
#
#          七个变体的六条证据逐个采齐（verif/ut/Entries_common/vmucp_evidence.py，
#          每个都打印"申请条件齐备"），加强前的实测如下：
#
#            变体                                  passing  unread  期望 passing
#            EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v  19184    6116  -> 25300
#            EntriesAluMulBkuBrhJmp                   18782    6228  -> 25010
#            EntriesFaluFcvtF2vFmacFdiv               13491    3128  -> 16619
#            EntriesFaluFmacFdiv                      13413    3136  -> 16549
#            EntriesFaluFmac                          12794    3140  -> 15934
#            EntriesVfmaVialuFixVfalu                 16017    2352  -> 18369
#            EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf
#                                                     16411    2344  -> 18755
#
#          七个都满足：unmatched unread **ref/impl 双 0**（不是"先配对再加强"那类，
#          本来就全是 matched_nc）；ref/impl 双射严格 1:1；配对**全部**是钉点文件的
#          子集、FM 自行猜配 **0 对**；`^ *Error:` 行数 0；unmatched 六项全零；
#          dont_verify / elab147 / relaxed_appvars 三项全空；黑盒输出 0；native SUCCEEDED。
#
#          ★复核判据（事前写死，passing 不增即空转、按 fail 处理）★：
#          passing 恰好 +unread、failing 仍 0、unread 归 0、unmatched 六项保持全零。
#
#          ☆同一个"两行"读数陷阱☆：结果表里 `Constant reg` 与 `Unread` 是两行
#          （Alu* 各 12 / Falu* 各 74 / Vfma* 各 134），vmucp 只清 unread 那一行，
#          常量寄存器留着**不拦 verdict**。所以期望值是 +unread，不是 +两行之和。

fm_target_vmucp_allow
