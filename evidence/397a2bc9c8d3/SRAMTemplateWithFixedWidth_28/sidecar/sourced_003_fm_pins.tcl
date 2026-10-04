# SRAMTemplateWithFixedWidth 家族（4 变体）FM「匹配后」钉点 —— 只消一个命名鸿沟，不约束 ref、不放宽 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 对象：内层 SRAM 读保持寄存器的最高位（补位 [65]）。本层写入时把 65 位数据零扩展成 66 位、读回截掉
#   最高位，于是这一位在父级零扇出（unread）。内层 SRAMTemplate_<n> 单独签核时这一位是输出、活着，
#   靠签名分析配上；到了这里零扇出点不做签名分析，名字又不同（golden 展平名 rdata_hold_data_0 /
#   重写核 rdata_hold）⇒ lane 内诊断跑实测两侧各 1 个 unmatched unread。
# 规则：r:/WORK/<top>/srams_0/rdata_hold_data_0_reg[65] <-> i:/WORK/<top>/srams_0/u_core/rdata_hold_reg[65]
#   （4 个变体同一条）；配上后由 vmucp 真比较（verif/fm_target_config/SRAMTemplateWithFixedWidth*.tcl）。
# fail-closed：set_user_match 返回值必须为 1（它从不抛异常，0 = 没配上），总数字面 1。
# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。$top = 当前 FM_TOP。
# ---------------------------------------------------------------------------
proc _sfw_pin_pad_bit { t } {
    set _expect 1
    puts "SFW_PIN_BEGIN $t expect=$_expect"
    set n 0
    set rpath "r:/WORK/$t/srams_0/rdata_hold_data_0_reg\[65\]"
    set ipath "i:/WORK/$t/srams_0/u_core/rdata_hold_reg\[65\]"
    if {![set_user_match $rpath $ipath]} {
        puts "SFW_PIN_FAIL: set_user_match returned 0 for $rpath <-> $ipath"
        error "SFW_PIN_MISS=$rpath"
    }
    incr n
    puts "SFW_PIN_END $t n=$n expect=$_expect"
    if {$n != $_expect} {
        puts "SFW_PIN_ERROR: pinned $n but expected $_expect"
        error "SFW_PIN_COUNT=$n"
    }
}
switch -- $top {
    SRAMTemplateWithFixedWidth -
    SRAMTemplateWithFixedWidth_4 -
    SRAMTemplateWithFixedWidth_12 -
    SRAMTemplateWithFixedWidth_28 { _sfw_pin_pad_bit $top }
    default { error "SFW_PIN_UNKNOWN_TOP=$top" }
}
