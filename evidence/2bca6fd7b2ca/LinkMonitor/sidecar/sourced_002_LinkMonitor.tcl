# vmucp 白名单条目：LinkMonitor
#
# 本文件 = LinkMonitor 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 原始加入（如实保留）----
# 本目标最初进白名单时没有把依据写进 fm_eq.tcl（拆分时如实记录，不补写）；
# 那一份依据只能到 git log 里找：`git log -SLinkMonitor -- scripts/fm_eq.tcl`。
#
# ---- 本轮依据（2026-10-04，agent/l2-link lane；跑前登记 docs/lanes/l2-link_prereg.md §4.3/§4.4）----
#   impl = rtl/uncore/LinkMonitor.sv（xs_LinkMonitor_core + 6 个已签重写 child，两侧白盒，无黑盒），
#   FM_MERGE_DUP=false。
#   第一跑 evidence/e78d61e72b1d/LinkMonitor（vmucp 关）：passing 2465 / unread 192，但 192 对全是
#     unmatched_unread（impl 计数器当时是 snake_case 名，无扇出寄存器签名分析配不上）→ 改回 golden 原名。
#   1b 跑   evidence/d0c5e050a61c/LinkMonitor（commit d0c5e050a，vmucp 关，signoff-strict，native SUCCEEDED）：
#     passing 2465 / failing 0 / unverified 0 / aborted 0 / unmatched 0(0) / unread_notcompared 192
#     → strict 判 PARTIAL(strict_unread!=0)。
#   192 个 unread 点全是 matched_unread_notcompared_pairs（unmatched_unread 两侧 0），逐点：
#     r:/WORK/LinkMonitor/retryAckCnt_reg[b]     <-> i:/WORK/LinkMonitor/u_core/retryAckCnt_reg[b]      b∈0..63
#     r:/WORK/LinkMonitor/pCrdGrantCnt_reg[b]    <-> i:/WORK/LinkMonitor/u_core/pCrdGrantCnt_reg[b]     b∈0..63
#     r:/WORK/LinkMonitor/noAllowRetryCnt_reg[b] <-> i:/WORK/LinkMonitor/u_core/noAllowRetryCnt_reg[b]  b∈0..63
#   ★为什么是对称死位★：LinkLayer.scala:414-431 的三个 64 位性能计数器（RetryAck / PCrdGrant 响应数、
#   allowRetry=0 的请求数）只有 dontTouch、没有任何读者；golden 与重写件是同一组 3×64 位寄存器、同一套
#   更新条件（rx.rsp.fire && opcode==3/7、tx.req.fire && !allowRetry），两侧都无扇出。
#   配对是 FM 按名字自动完成的（没有任何 fm_pins / set_user_match）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {retryAckCnt, pCrdGrantCnt, noAllowRetryCnt}[63:0]，恰好 192 位，不含别的寄存器。
#   (2) 双射：192 ref <-> 192 impl，ref/impl 各 192 个互不相同，逐对去掉层次前缀后同名同下标（脚本核对 0 例外）。
#   (3) 真比较：vmucp 开后 passing 必须 2465 -> 2657，正好 +192；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：无 dont_verify、无 elab147、无 relaxed appvar；两侧黑盒集合为空，不新增黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：第二跑 passing 正好 2657、unread 归 0、unmatched 全零、verdict SUCCEEDED。

fm_target_vmucp_allow
