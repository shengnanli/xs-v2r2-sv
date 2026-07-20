# LoadMisalignBuffer FM 钉点（FM 修复 2026-07）
# ------------------------------------------------------------------------------
# 1) golden 拆分寄存器名 splitLoadReqs_<N>_<field> vs 重写核 SV 数组
#    splitReq_<field>_reg[N][b]：名字差异令自动配对只能靠签名、且 low/high 两份
#    值域相近会互相搅乱（约一半点位配错 → 大片 failing）。逐位 set_user_match 钉死。
#    - vaddr: 50b ×2    - mask: 16b ×2
#    - fuOpType[1:0] ↔ splitReq_size[N][1:0]（golden 每份存全 9b fuOpType，但输出只读
#      [1:0]=size；重写核只存 2b size，其余位由 req 现场重建，与 golden 输出结构一致）
# 2) req_uop_fuOpType_reg[1:0] ↔ u_core/req_reg[fuOpType][1:0]：低 2 位（size 段）
#    参与拆分表索引，签名歧义常配不上，一并钉死。
# 3) verification_propagate_const_reg_x：golden 保留一批「常量 0 寄存器」
#    （highResultShift / splitLoadReqs 的 mmio/nc/is128bit/mshrid/schedIndex/vecActive/
#    exceptionVec_4/memBackTypeMM——复位 0 且 D 只会装 0 或自持），重写核按设计意图
#    直接用常量 0。这些 ref 寄存器初值 X（SYNTHESIS 下无随机 init），默认不做常量
#    传播会在输出锥里成为自由变量而误判失配。打开传播（健全分析开关，仅让 FM 证明
#    「恒 0」后按 0 传播，不改变任何设计逻辑；不做 set_constant 之类的人工约束）。
if {[catch {set_app_var verification_propagate_const_reg_x true} msg]} {
  puts "LMB_PINS: set_app_var failed: $msg"
} else {
  puts "LMB_PINS: verification_propagate_const_reg_x=true"
}

set _n 0
# splitLoadReqs_<N>_vaddr / _mask / _uop_fuOpType[1:0] ↔ splitReq_{vaddr,mask,size}_reg[N][b]
foreach N {0 1} {
  for {set b 0} {$b < 50} {incr b} {
    if {![catch {set_user_match "r:/WORK/$top/splitLoadReqs_${N}_vaddr_reg\[$b\]" \
                                "i:/WORK/$top/u_core/splitReq_vaddr_reg\[$N\]\[$b\]"}]} { incr _n }
  }
  for {set b 0} {$b < 16} {incr b} {
    if {![catch {set_user_match "r:/WORK/$top/splitLoadReqs_${N}_mask_reg\[$b\]" \
                                "i:/WORK/$top/u_core/splitReq_mask_reg\[$N\]\[$b\]"}]} { incr _n }
  }
  for {set b 0} {$b < 2} {incr b} {
    if {![catch {set_user_match "r:/WORK/$top/splitLoadReqs_${N}_uop_fuOpType_reg\[$b\]" \
                                "i:/WORK/$top/u_core/splitReq_size_reg\[$N\]\[$b\]"}]} { incr _n }
  }
}
# req_uop_fuOpType[1:0] ↔ req_reg[fuOpType][1:0]（转义叶名）
for {set b 0} {$b < 2} {incr b} {
  if {![catch {set_user_match "r:/WORK/$top/req_uop_fuOpType_reg\[$b\]" \
                              "i:/WORK/$top/u_core/req_reg\\\[fuOpType\]\[$b\]"}]} { incr _n }
}
puts "LMB_PINS: $_n points pinned"
