# PBestOffsetPrefetch FM 钉点 (RC2 prep Lane C, 2026-08)
# --------------------------------------------------------------------------
# delayQueue(DelayQueue/xs_DelayQueue_core) 16 条目 42 位地址寄存器:
#   golden : firtool 逐条目具名标量 queue_<e>_addrNoOffset(reg [41:0])
#   手写核 : 可读 SV 数组 queue_addr[0:15](reg [41:0]), FM 展平名 queue_addr_reg[e][b]
# 本 target 内 delayQueue 输出 {addr,6'h0} 只被 rrTable 写路径的低位消费, 高位
# addrNoOffset[41:20] 两侧对称 cone-dead(golden 与手写核 bug-for-bug 一致的死位)。
# 死位无 fanout cone → FM 签名分析配不上; 词干不同(addrNoOffset vs addr)+ 下标位置
# 不同(名中缀 _<e>_ vs 数组下标 [e])令 auto_match_flattened_arrays 的命名规则也无法
# 配对 → 352(ref)+352(impl) 对称 unmatched-unread(RC1 native_facts 实证, 完整
# 16 条目 × 位 [41:20] 网格, 两侧下标集合逐点相同)。
# 按名逐位 set_user_match 建 1:1 双射(仅消名差, 不约束 ref, 不 dont_verify, 不扩黑盒);
# 配合 Makefile FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true(vmucp, 证明加强非
# waiver)让 FM **实际比较**这 352 点 + 既有 1 对 matched-unread(rrTable REG 单口
# 读写冲突检测寄存器)→ 全部转 passing, unread 全零。
# 同型先例: ICacheCtrlUnit out_back_q ram_reg↔slot_reg[data] 死位双射 + vmucp。
# 位级 set_user_match 抛错被 catch 吞掉(路径不存在时无副作用), 末行 puts 报配对数。
# --------------------------------------------------------------------------
set _n 0
for {set e 0} {$e < 16} {incr e} {
  for {set b 20} {$b <= 41} {incr b} {
    if {![catch {set_user_match \
          "r:/WORK/$top/delayQueue/queue_${e}_addrNoOffset_reg\[$b\]" \
          "i:/WORK/$top/u_core/delayQueue/queue_addr_reg\[$e\]\[$b\]"}]} { incr _n }
  }
}
puts "PBOP_PINS: delayQueue addrNoOffset dead bits 41:20 $_n / 352 points pinned"
