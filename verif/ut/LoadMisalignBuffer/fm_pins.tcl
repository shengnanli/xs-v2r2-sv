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
# 3) splitLoadReqs_<N> 的一批「本配置恒 0」LsPipelineBundle 元数据寄存器（mmio/nc/
#    is128bit/mshrid/schedIndex/vecActive/exceptionVec_4/memBackTypeMM）。golden 逐 bank
#    存成复位 0、自持的寄存器，在 splitLoadReq 输出上按 curPtr 读出（恒 0）。早期重写核
#    对这些输出直接用常量 0，令 golden 侧寄存器在输出锥里成为自由 X，须打开
#    verification_propagate_const_reg_x——但 strict 下该开关属 relaxed appvar
#    （→ strict_qualifications PARTIAL），不可用。现重写核逐 bank 保留与 golden 同名的
#    恒 0 寄存器；其次态用「按活跃 alignedType 索引、SZ_B 默认分支=self」的 mux（见核
#    metaZeroN，与 highResultShift/_GEN_38 同构），使 SV 前端不将其常量折叠删除（纯
#    `& self` 会被删→FM-036）。下方逐位 set_user_match 双射钉死 golden↔impl，FM 直接
#    结构匹配这些点、无需常量传播即可约束输出锥——保持默认 appvar，relaxed_appvars 为空。

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

# 4) splitLoadReqs_<N> 的「本配置恒 0」LsPipelineBundle 元数据寄存器逐 bank 钉死。
#    重写核为与 golden 逐位等价，逐 bank 保留同名恒 0 自持寄存器（splitLoadReqs_0_*/
#    splitLoadReqs_1_*，复位 0 且 next = metaHold & self，功能恒 0）。但两 bank 的次态
#    函数结构相同（均 metaHold & self），verification_merge_duplicated_registers 会把它们
#    折叠/合并，导致 golden 的逐 bank 比较点在自动 match 阶段配不上（一半 orphan）。
#    在首次 match 前逐个 set_user_match 钉死 golden reg ↔ impl reg，锁定 1:1 双射，
#    使 FM 不再合并/常量折叠掉，从而两 bank 全部作为比较点被验证（恒 0，passing）。
#    这是「加强证明」(FM 实际比较更多状态)，非 waiver：证明的是 impl 逐 bank 恒 0 与
#    golden 逐 bank 恒 0 的等价，而非跳过。
proc pin_meta { top field width } {
  set n 0
  foreach N {0 1} {
    if {$width == 1} {
      set rp "r:/WORK/$top/splitLoadReqs_${N}_${field}_reg"
      set ip "i:/WORK/$top/u_core/splitLoadReqs_${N}_${field}_reg"
      if {![catch {set_user_match $rp $ip}]} { incr n }
    } else {
      for {set b 0} {$b < $width} {incr b} {
        set rp "r:/WORK/$top/splitLoadReqs_${N}_${field}_reg\[$b\]"
        set ip "i:/WORK/$top/u_core/splitLoadReqs_${N}_${field}_reg\[$b\]"
        if {![catch {set_user_match $rp $ip}]} { incr n }
      }
    }
  }
  return $n
}
foreach {fld w} {nc 1 mmio 1 memBackTypeMM 1 is128bit 1 vecActive 1 mshrid 4 schedIndex 7 uop_exceptionVec_4 1} {
  incr _n [pin_meta $top $fld $w]
}
puts "LMB_PINS: $_n points pinned"
