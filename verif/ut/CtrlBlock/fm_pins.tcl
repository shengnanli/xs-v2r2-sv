# CtrlBlock FM 钉点(FM 审计 2026-07, sidecar-compat 修订 2026-08)
# ----------------------------------------------------------------------------
# golden(firtool 展平字段名)↔ 手写核(struct/unpacked-array 寄存器)自动配对失败的
# 1-1 对应, 按命名规则从**未匹配寄存器集**现场推导后 set_user_match。
# 这些是 same-source 对称常数 0 寄存器(golden 在 SYNTHESIS 下把 debugInfo_*Time /
# 部分 exceptionVec / debug_* 字段硬连 0; 可读核对应 struct 字段也恒 0), 值等价;
# FM 的 auto_match_flattened_arrays 只能处理纯 name_reg[i][j], 处理不了字段名内嵌的
# struct+array 情形 → 1962 对落单 unmatched。set_user_match 后 FM 实证 0==0 passing
# (非 dont_verify, 非 vmucp 掩盖, 非强配)。规则+bijection 见 ctrlblock_pin_manifest.json
# (1962 对, sha256, gen: scripts/gen_ctrlblock_pin_manifest.py)。
#
# ★ sidecar-compat 修订: 旧版用 `redirect -variable um_txt {report_unmatched_points}`
#   捕获**stdout**。官方 signoff runner 在受限 child interp 里 source 本文件, 其
#   redirect shim(sidecar_pin_redirect)捕获的是命令**返回值**, 而 FM 原生
#   report_unmatched_points 把表打到 stdout、返回空串 → um_txt 为空 → 0 pinned
#   (官方 gate 遗留 1962 unmatched 根因)。改用 `report_unmatched_points -reference|
#   -implementation -list`(**返回 Tcl list**, 被 interp eval 正确捕获, 与 emitter 同 API,
#   非 sidecar 直跑亦可)后, 两条路径都能拿到未匹配寄存器集。★
# ----------------------------------------------------------------------------
# 规则表(ref 相对路径 → impl u_core 下规范键):
#   enqRob_req_<k>_bits_r_<field>_reg[b]                      -> enqRobBits_reg[k][<field>][b]
#   delayedNotFlushedWriteBack_delayed_bits_r_<k>_<field>_reg[b]
#                                                             -> wbd<k>_<field>_reg[b]
#   delayedNotFlushedWriteBack_delayed_bits_r_<field>_reg[b]  -> wbd0_<field>_reg[b] (lane0 bare)
#     ★窄化(b490e6b1)后 impl 为 wbd<lane>_<field> 窄寄存器(exceptionVec 逐位标量位号
#     内嵌字段名)。全族 329 寄存器/5362 位正常路径由 fm_pins_pre.tcl **匹配前**钉死
#     (gate3 实证匹配后 impl 常数标量已被 merge/shuffle 不在 unmatched 池, 旧 struct
#     规则 0 pinned/13 un-mappable); 本规则仅作漂移时 unmatched 池兜底。双射清单
#     ctrlblock_wbd_prepin_manifest.json(gen: gen_ctrlblock_pin_manifest.py --wbd)★
#   delayedNotFlushedWriteBackNums_delayed_bits_r_<k>_reg[b]  -> wbNumsBits_reg[k][b] (k 缺省=0)
#   redirectGen_io_oldestExuRedirect_bits_r_<f>_reg[b]        -> oldestExuRedirectBits_reg[<f>][b]
#   s3_s5_redirect_next_bits_r_level/robIdx_flag/robIdx_value -> s3_s5_redirect_{level,robFlag,robValue}_reg
#   s3_s5_redirect_next_valid_last_REG_reg                    -> s3_s5_redirect_valid_reg
#   s2_s4_redirect_next_valid_last_REG_reg                    -> s2_s4_redirect_valid_reg
#   decodeBufBits_<k>_foldpc_reg[b]                           -> decodeBufBits_reg[k][foldpc][b]
#   io_perf_<n>_value_REG_reg[b] / REG_1_reg[b]               -> perfStage0/1_reg[n][b]
proc ctrlblock_pin_unmatched { top } {
    # sidecar-compat: -list 返回 Tcl list(命令返回值), 两条路径都能拿到; 不依赖 stdout。
    # -reference/-implementation(无 -status)返回该侧全部未匹配点(含 compare 与 unread);
    # 只有匹配下方寄存器命名规则的点会被钉, 非寄存器点(黑盒 pin 等)自然跳过。
    array set ilut {}
    foreach ip [report_unmatched_points -implementation -list] {
        set key $ip
        regsub "^i:/WORK/${top}/" $key "" key
        regsub "^u_core/" $key "" key
        set key [string map {\\ ""} $key]
        set ilut($key) $ip
    }
    set refs [report_unmatched_points -reference -list]
    set n 0
    set miss 0
    foreach rp $refs {
        set rel $rp
        regsub "^r:/WORK/${top}/" $rel "" rel
        set key ""
        if {[regexp {^enqRob_req_(\d+)_bits_r_(\w+?)_reg(\[\d+\])?$} $rel -> k f b]} {
            set key "enqRobBits_reg\[$k\]\[$f\]$b"
        } elseif {[regexp {^delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_(\w+?)_reg(\[\d+\])?$} $rel -> k f b]} {
            set key "wbd${k}_${f}_reg$b"
        } elseif {[regexp {^delayedNotFlushedWriteBack_delayed_bits_r_([a-zA-Z]\w*?)_reg(\[\d+\])?$} $rel -> f b]} {
            set key "wbd0_${f}_reg$b"
        } elseif {[regexp {^delayedNotFlushedWriteBackNums_delayed_bits_r_(\d+)_reg(\[\d+\])?$} $rel -> k b]} {
            set key "wbNumsBits_reg\[$k\]$b"
        } elseif {[regexp {^delayedNotFlushedWriteBackNums_delayed_bits_r_reg(\[\d+\])?$} $rel -> b]} {
            set key "wbNumsBits_reg\[0\]$b"
        } elseif {[regexp {^redirectGen_io_oldestExuRedirect_bits_r_(\w+?)_reg(\[\d+\])?$} $rel -> f b]} {
            set key "oldestExuRedirectBits_reg\[$f\]$b"
        } elseif {[regexp {^s3_s5_redirect_next_bits_r_level_reg$} $rel]} {
            set key "s3_s5_redirect_level_reg"
        } elseif {[regexp {^s3_s5_redirect_next_bits_r_robIdx_flag_reg$} $rel]} {
            set key "s3_s5_redirect_robFlag_reg"
        } elseif {[regexp {^s3_s5_redirect_next_bits_r_robIdx_value_reg(\[\d+\])?$} $rel -> b]} {
            set key "s3_s5_redirect_robValue_reg$b"
        } elseif {[regexp {^s3_s5_redirect_next_valid_last_REG_reg$} $rel]} {
            set key "s3_s5_redirect_valid_reg"
        } elseif {[regexp {^s2_s4_redirect_next_valid_last_REG_reg$} $rel]} {
            set key "s2_s4_redirect_valid_reg"
        } elseif {[regexp {^decodeBufBits_(\d+)_foldpc_reg(\[\d+\])?$} $rel -> k b]} {
            set key "decodeBufBits_reg\[$k\]\[foldpc\]$b"
        } elseif {[regexp {^io_perf_(\d+)_value_REG_reg(\[\d+\])?$} $rel -> k b]} {
            set key "perfStage0_reg\[$k\]$b"
        } elseif {[regexp {^io_perf_(\d+)_value_REG_1_reg(\[\d+\])?$} $rel -> k b]} {
            set key "perfStage1_reg\[$k\]$b"
        }
        if {$key eq "" || ![info exists ilut($key)]} { incr miss; continue }
        if {[catch {set_user_match $rp $ilut($key)} msg]} {
            puts "CTRLBLOCK_PIN_FAIL: $rp <-> $ilut($key) ($msg)"
        } else {
            incr n
            unset ilut($key)
        }
    }
    puts "CTRLBLOCK_PINS: $n pinned, $miss ref-side un-mappable"
}
ctrlblock_pin_unmatched $top

# ★ rob 内部 deqHitRedirectReg 钉点已删除(2026-08): Rob 现为 partitioned interface_only
#   黑盒(见 allow/CtrlBlock.json + Makefile FM_INTERFACE_ONLY), 其内部寄存器不 elaborate,
#   钉黑盒内部寄存器会触发 FM-036 Unknown name(官方 gate fm_log:10314-10315 实证), 且
#   违反 partitioned boundary 铁律(禁 pin 黑盒内部)。Rob 等价性由 Rob 自身 305 签核目标
#   证明, 非在此跨边界钉。本文件其余钉点全部作用于 CtrlBlock **glue 层**寄存器(enqRob 打包
#   / writeback 延迟 / redirect / decodeBuf / perf), 无任何黑盒内部或 interface_only 子模块
#   (Rob/Rename/DecodeStage/NewDispatch/... 16 类)内部 reg 引用。
