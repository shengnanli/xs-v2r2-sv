# vmucp 白名单条目：StoreMisalignBuffer
#
# 本文件 = StoreMisalignBuffer 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-09-28，agent/lmisalign lane) ----
#   跑前登记 docs/lanes/lmisalign_prereg.md §2.3（commit b5f4de91，写于任何 FM 运行之前）预测
#   unread 18 位、constant_reg 2。随后一次诊断跑（make fm-StoreMisalignBuffer，FM_MODE=diagnostic-full、
#   FM_FAILING_LIMIT=0、vmucp 关，commit 5bc7dabf 同字节，不出正式 receipt）实测：native SUCCEEDED
#   passing 4733 / failing 0 / unmatched 0(0) / constant_reg 2 / unread_notcompared 19。
#   19 个点全部 matched_nc（按名配上，两侧独占 0，无 fm_pins、无人工强配），两侧都是同一死位：
#   (a) REG_1（1 位）：RegNext(!req_valid)，只喂 XSPerfAccumulate("alloc")，计数器已 DCE。
#   (b) splitStoreReqs_{0,1}_uop_fuOpType[8:2]（14 位）：发请求时标量只取子访问宽度 [1:0]
#       （再拼 req 的 hsv），向量直接用 req.uop.fuOpType。
#   (c) splitStoreResp_1_paddr[2:0]（3 位）：给 StoreQueue 的是 Cat(paddr(47,3), 0.U(3.W))。
#   (d) req_alignedType[2]（1 位）：只经 alignedType(1,0) 读；store 的 vecWriteBack 没有 alignedType 端口
#       （被 DCE），所以第 2 位无读者。★跑前登记漏列了这一位（预测 18，实测 19），差额 +1 就是它★。
#   重写件照抄 golden 位宽（不收窄）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 19 位（1+14+3+1）。
#   (2) 双射：19 ref <-> 19 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 4733 -> 4752（= 登记模型 4754 - constant_reg 2），正好 +19；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（叶子模块）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 4752、unread 归 0、unmatched 全零、constant_reg 2。

fm_target_vmucp_allow
