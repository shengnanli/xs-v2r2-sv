# vmucp 白名单条目：DCacheWrapper（DCache 的 LazyModule 外壳：端口直通 + 40 个 perf 计数打两拍）
#
# 本文件 = DCacheWrapper 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-04，agent/l2-mem-parents）----
#   本层自己没有死位：480 位 perf 寄存器全部直达输出口，DCache 的全部端口都接到外壳端口（无 /* unused */）。
#   需要 vmucp 的点全部来自 DCache 子树，且与 DCache 单独签核时是**同一批**：
#   DCache 签核（verif/fm_target_config/DCache.tcl，agent/dcachebody，evidence/0dc9c4532cf5/DCache 等）开着 vmucp，
#   matched_nc 一批 = 子模块签核时已由各自 vmucp 真比较过的对称死位 + parent_dead 钉点那批；外壳把 DCache 的
#   全部端口原样引出，这些点在本层的可观测性与在 DCache 顶层时相同，不会多也不会少。
#   钉点 verif/ut/DCacheWrapper/fm_pins_pre.tcl 由 scripts/gen_dcachewrapper.py 原样收割 DCache 的
#   fm_pins_pre.tcl（换根 /WORK/DCacheWrapper/dcache）+ 本层 480 位 perf 寄存器。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：配对表逐项写死（本层 480 + 收割 DCache 全部），计数 fail-closed；
#   (2) 双射：全部一对一（生成器拒绝重复路径、set_user_match 逐条须返回 1）；
#   (3) 真比较：passing 须等于 DCache 签核读数 + 本层 480（对账见 docs/lanes/l2-mem-parents_prereg.md）；
#   (4) 全零：failing / unverified / aborted / unmatched 全 0；
#   (5) 无放宽：无 dont_verify / elab147 / relaxed appvar；黑盒只有 verif/allow/DCacheWrapper.json 声明的
#       （= DCache.json 换根：厂商叶子 array_7_ext ×32 / array_8_ext ×8 + golden 侧被消空的 StorePipe）；
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
