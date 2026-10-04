# vmucp 白名单条目：DCache（L1 数据缓存顶层：22 类子模块 + 本层胶水）
#
# 本文件 = DCache 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-02，agent/dcachebody lane，diagnostic-full 试跑，未出 receipt）----
#   首跑（vmucp 关、merge_dup 关、钉点 11629 = 本层 1716 + 子模块收割 9913）：
#   matched by user 4898 / by name 47983 / by signature 15872 / by topology 1032；
#   unmatched compare 0(60)、unmatched unread 1048(1038)、matched_nc 11253。
#   未配对 unread 的来源（两侧对称、同一死因 = 子模块签核时是活点/输出，DCache 把它接成 /* unused */ 或不读）：
#   · mainPipe 24 份 status_dup（s1/s2/s3 set、replace 标志、way_en）720 位；
#   · missQueue 流水寄存器 / 16 个 MSHR 的 vaddr[4:0]（行内偏移）85 位 + CMOUnit req_address[63:48] 16 位；
#   · probeQueue 8 个表项 + selected 的 vaddr[4:0] 45 位；
#   · accessArray 读口 0..3 的 idx 打拍 128 位（extra_meta_resp.access 被 firtool 消掉）；
#   · prefetchArray 读口 3 的旁路选择/旁路数据/idx 48 位；bloomFilter 3 个查询回应打拍 6 位。
#   名字不同的由 verif/ut/DCache/fm_pins_pre.tcl（scripts/gen_dcache.py 的 parent_dead_pins，1048 条）逐位配对；
#   impl 侧另有 60 个未配对点 = 上述 50 个寄存器（配对后归零）+ 10 个 fdpMonitor 黑盒脚（重写件原是空模块，
#   FM 当黑盒；已照 golden 补上三条无人读的 PopCount，不再是黑盒）。
#   matched_nc 11253 = 子模块签核时已由各自 vmucp 真比较过的那批对称死位（CtrlUnit / BankedDataArray /
#   MainPipe / MissQueue 的钉点原样收割）+ 子模块自己按名配上的死位（bloomFilter data 等）。
# ---- 六条证据 ----
#   (1) 精确绑定：配对表逐项写死（本层 1716 + parent_dead 1048 + 收割 9913），计数 fail-closed；
#   (2) 双射：全部一对一（生成器拒绝重复路径、set_user_match 逐条须返回 1）；
#   (3) 真比较：加强后 passing 须恰好增加被真比的 matched_nc 点数（对账见 docs/lanes/dcachebody_prereg.md）；
#   (4) 全零：failing / unverified / aborted / unmatched 全 0；
#   (5) 无放宽：无 dont_verify / elab147 / relaxed appvar；黑盒只有审定过的厂商叶子 array_7_ext ×32 / array_8_ext ×8
#       （verif/allow/DCache.json，从子模块声明收割）；
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
