# vmucp 白名单条目：SSIT
#
# 本文件 = SSIT 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   SSIT(2026-09-17 加): 本模块**没有任何输出端口**(10 端口全 input)，三组 1024 项
#          影子数组(debug_valid/debug_ssid/debug_strict)的扇出只有自己
#          (debug_valid_i -> _GEN_4122+i -> _GEN_5146+i -> debug_valid_i)，
#          外加 s2_loadStrict(唯一去处是 XSPerfAccumulate，模块内无读者)。
#          它们在 golden 侧同样是自环死位，两侧**对称**。
#          配对靠 auto_match_flattened_arrays 的结构性规则
#          (debug_ssid_reg[1023][4] <-> debug_ssid_1023_reg[4])，不是人工强配。
#          ★复核判据（2026-09-17 按实测改写，原写的 +3073 是错的）★
#              实测 passing 0 -> 14525、failing 0、unread 0、unmatched 0(0)，
#              14525 全在 DFF 列（evidence/82fe3881c4d9/SSIT，commit 82fe388）。
#              下次复跑的判据就是这三个数，不是 +3073。
#          ★为什么原来的 3073 会差 4.7 倍：因为它数的不是同一个东西★
#              3073 是三组影子数组的**条目数**(1024x3+1)；而本模块 0 个输出端口
#              (golden SSIT.sv 实测 10 input / 0 output)，意味着**整个模块的
#              每一个寄存器位**在基线里都是未读点 —— 所以基线 passing 是 0，
#              打开加强后进来的是全模块 14525 个寄存器位，不止那三组数组。
#              这条记在这里是因为它是个方法学教训：影子数组只是"最显眼的那部分"，
#              把它的条目数当成加强后的增量，就会写出一个 4.7 倍偏小的预期值。
#              判据的价值在于事前承诺、事后对账；对不上就必须查清楚再改写判据，
#              不能因为"实测比预期大、方向没错"就放过去。本例查清的结论是
#              两个数在数不同的东西，加强本身没有空转(0 -> 14525 是最强的非空转)。

fm_target_vmucp_allow
