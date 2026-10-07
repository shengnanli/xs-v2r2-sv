# vmucp 白名单条目：Frontend（codex 0226 exact green_child 组合）
#
# ---- 加入依据（2026-10-06，agent/frontend-asm lane，canary3：vmucp 关 / canary2：vmucp 开，同一字节，不产 receipt）----
#   八个直接 child（Predictor/Ftq/ICache/NewIFU/IBuffer/InstrUncache/TLB/PTWFilter）两侧 -interface_only，不产生未读点；
#   vmucp 关：native SUCCEEDED passing 24577 / failing 0 / unmatched 0(0) / constant_reg 259，
#   Not Compared = Unread 5516，全部 matched_nc（另 64 个 golden-only unmatched-unread 走 verif/dead_ref/Frontend.json）。
#   这 5516 对为什么是两侧对称死位：
#     · 3268 = 本层可读核 §7 指令流自检（checkPcMem_0..63 startAddr 64×50 + prevTaken/prevNotTaken 一组 68 位）——golden 只在
#       `ifndef SYNTHESIS 的断言里读，两侧定义 SYNTHESIS 后无读者；可读核照 golden 一位不少地保留（UT 变异 M7 抓不到的那批）；
#     · 1200 = PFEvent 的 24 份 perfEventsModule 事件寄存器（Frontend 不读 PFEvent 的 hpm 输出位）；
#     · 810  = PMP 的 pmpcfg/pmpaddr/pma 存储里本层无读者的位；
#     · 238  = DelayN_8（inner_csrCtrl_delay）里 Frontend 不用的 CSR 控制字段两拍延迟位。
#   配对来源：顶层核 3612 位 + 第二节白盒子模块配对（PMP / PTWRepeaterNB 自己签核的钉点重定位、PFEvent / DelayN_8 /
#   MbistPipeFrontend 由源码结构推出），scripts/gen_frontend.py 生成，全部字面、逐条数返回值；不读任何诊断 matched.rpt。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上述 5516 位，均 matched_nc。
#   (2) 双射：5516 ref <-> 5516 impl matched，两侧独占 0（unmatched-unread impl 侧 0）。
#   (3) 真比较：passing 24577 -> 30093，正好 +5516；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 allow 声明的八个 green child（两侧 16 个对象）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 30093、constant_reg 259、unread 只剩 dead_ref 声明的 64 位 golden 侧点。

fm_target_vmucp_allow
