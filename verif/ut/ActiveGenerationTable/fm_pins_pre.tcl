# ActiveGenerationTable FM「匹配前」钉点（手写，1 位，fail-closed）
#
# 只钉 golden 里没人读的 s2_do_dcache_evict_last_REG（见 verif/fm_target_config/ActiveGenerationTable.tcl）。
# FM 默认不给 unread 点配对，vmucp 只比 matched 的 unread 点 ——
# 2026-10-02 正式跑 @76a7067b 实测：appvar 已为 true，passing 仍是 1729、unread 仍是 1 对。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：数返回值，拒即 error。进 fm.log 的输出一律 ASCII。
set ::AGT_PIN_EXPECT 1
set ::AGT_PIN_OK 0
if {[set_user_match "r:/WORK/ActiveGenerationTable/s2_do_dcache_evict_last_REG_reg" \
                    "i:/WORK/ActiveGenerationTable/u_core/s2_do_evict_q_reg"]} {
  incr ::AGT_PIN_OK
} else {
  puts "AGT_PIN_FAIL: s2_do_dcache_evict_last_REG_reg <-> u_core/s2_do_evict_q_reg"
}
puts "AGT_PIN_END ActiveGenerationTable ok=$::AGT_PIN_OK expect=$::AGT_PIN_EXPECT"
if {$::AGT_PIN_OK != 1} { error "AGT_PIN_COUNT=$::AGT_PIN_OK expect=1" }
