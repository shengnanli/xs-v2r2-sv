# vmucp 白名单条目：CMOUnit（DCache MissQueue 里的 CMO 发送单元）
#
# 本文件 = CMOUnit 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28, agent/missq lane 内 diagnostic-full 试跑，未出 receipt）----
# 首跑（vmucp 关、无钉点）：native SUCCEEDED / passing 116 / failing 0 / unmatched 全 0 /
# 无黑盒 / 无 dont_verify；唯一让 strict 判 PARTIAL 的是 matched-unread 16 个：
#   r:/WORK/CMOUnit/req_address_reg[63:48] <-> i:/WORK/CMOUnit/u_core/req_address_q_reg[63:48]
# 死因（两侧相同）：CMOReq.address 是 64 位，请求在 req.fire 拍整条锁存；读取侧只有
# A 通道地址 req.address[47:0]（物理地址 48 位），resp_to_lsq.address 输出父级没人读、
# 被 firtool 删掉 —— 于是高 16 位成了只写不读的寄存器位。可读核照 Scala 保留 64 位锁存
# （同样只在 req.fire 写、同样不复位），与 golden 一一对应。
# vmucp 六条：精确绑定（FM 按名自动 1<->1 配上，16 对逐位同下标）/ 双射（16 对全部一对一）/
#   FM 实比（passing 应 116 -> 132 = +16）/ 加强后 failing 须仍为 0 / 无 dont_verify、
#   无新黑盒 / 摘要写在本文件与 docs/lanes/missq_prereg.md。

fm_target_vmucp_allow
