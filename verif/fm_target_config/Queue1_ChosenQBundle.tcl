# vmucp 白名单条目：Queue1_ChosenQBundle（RequestBuffer 的 chosenQ，1 项 pipe 队列，agent/l2slice lane）
#
# 本文件 = Queue1_ChosenQBundle 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/l2slice lane，commit 4a2638fc 上的正式跑，vmucp 关）----
#   证据：evidence/4a2638fcec95/Queue1_ChosenQBundle（signoff-strict，native SUCCEEDED）
#   passing 503 / failing 0 / unverified 0 / unmatched 0，Constant reg 262，unread 22 -> strict 判 PARTIAL。
#   22 个 unread 点全是 matched_nc（两侧独占 0）：
#     r:/WORK/Queue1_ChosenQBundle/ram_reg[b] <-> i:/WORK/Queue1_ChosenQBundle/u_core/ram_reg[b]
#       b in {0, 1}        io_enq_bits_valid / io_enq_bits_rdy        （2）
#       b in 385..404      io_enq_bits_waitMP[9:0] / waitMS[9:0]    （20）
#   ★为什么是对称死位★：golden 的 407 位整字寄存器 ram 把 enq 的全部字段都存了，但 firtool 删掉了这四个字段的
#   io_deq_bits_* 端口（父模块 RequestBuffer 出队时用不到）—— 存进去的这 22 位没有任何读者。重写件同样存整字
#   （scripts/gen_l2_queues.py 按 golden 字段表拼字，打印 unread=bits_waitMS,bits_waitMP,bits_rdy,bits_valid），
#   同一批寄存器、同一个位号；配对由 FM 按名字自动完成，非人工强配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上表 22 位。
#   (2) 双射：22 ref <-> 22 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 503 -> 525，正好 +22（登记 expected 787 − constant_reg 262）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
