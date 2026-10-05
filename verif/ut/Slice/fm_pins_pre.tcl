# Slice 家族 FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_slice.py（勿手改）
#
# 内容 = 各 child 单独签核时 FM 已核实的配对（child_pins.tsv，由 --harvest 从 matched.rpt 收割），
# 只改层次前缀。只钉两侧叶名不同的寄存器位；本层自己的寄存器保留 golden 名，FM 按名自配。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数不等于字面整数就 error。
# 名字用花括号原样传（含 FM 报告里的 \[ 转义），不做任何替换。
set ::SLICE_PIN_OK 0
set ::SLICE_PIN_BAD 0
proc slice_pin {r i} {
  if {[set_user_match $r $i]} { incr ::SLICE_PIN_OK } else {
    incr ::SLICE_PIN_BAD
    if {$::SLICE_PIN_BAD <= 10} { puts "SLICE_PIN_FAIL: $r <-> $i" }
  }
}
proc slice_pinw {r i w} {
  for {set b 0} {$b < $w} {incr b} { slice_pin "${r}\[$b\]" "${i}\[$b\]" }
}
if {$top eq "Slice"} {
  # MSHRCtl 1408, MainPipe_1 1202, GrantBuffer 2026, RequestBuffer 788, RequestArb 766, SinkC 4628, RXSNP 34, TXDAT 26, TXREQ 0, TXRSP 0, MSHRBuffer 8704, MSHRBuffer_1 8704, Directory 412, DataStorage 546, L2Slice 137, EXTRA_PINS 11
  puts "SLICE_PIN_BEGIN Slice expect=29392"
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_0_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[0]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_10_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[10]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_11_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[11]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_12_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[12]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_13_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[13]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_14_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[14]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_15_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[15]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_1_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[1]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_2_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[2]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_3_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[3]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_4_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[4]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_5_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[5]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_6_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[6]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_7_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[7]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_8_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[8]} 10
  slice_pinw {r:/WORK/Slice/mshrCtl/hpm_timers_9_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/hpm_timers_reg[9]} 10
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_0_rdy_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[0]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_0_task_alias_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[0]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_0_task_opcode_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[0]} 3
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_0_task_param_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[0]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_0_task_set_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_0_task_tag_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_0_valid_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[0]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_0_waitG_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[0]} 7
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_1_rdy_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[1]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_1_task_alias_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[1]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_1_task_opcode_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[1]} 3
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_1_task_param_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[1]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_1_task_set_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_1_task_tag_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_1_valid_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[1]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_1_waitG_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[1]} 7
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_2_rdy_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[2]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_2_task_alias_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[2]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_2_task_opcode_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[2]} 3
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_2_task_param_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[2]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_2_task_set_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_2_task_tag_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_2_valid_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[2]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_2_waitG_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[2]} 7
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_3_rdy_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[3]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_3_task_alias_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[3]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_3_task_opcode_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[3]} 3
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_3_task_param_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[3]} 2
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_3_task_set_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_3_task_tag_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice/mshrCtl/sourceB/probes_3_valid_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[3]}
  slice_pinw {r:/WORK/Slice/mshrCtl/sourceB/probes_3_waitG_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[3]} 7
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_0_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_10_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_11_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_12_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_13_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_14_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_15_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_1_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_2_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_3_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_4_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_5_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_6_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_7_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_8_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice/mshrCtl/timers_9_reg} {i:/WORK/Slice/u_core/mshrCtl/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice/mainPipe/REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s3DropValid_d1_reg}
  slice_pin {r:/WORK/Slice/mainPipe/chnl_valid_s4_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/chnlFire_s3_d1_reg}
  slice_pin {r:/WORK/Slice/mainPipe/chnl_valid_s5_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/chnlFire_s3_d1b_reg}
  slice_pin {r:/WORK/Slice/mainPipe/chnl_valid_s5_REG_2_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/chnlFire_s3_d2_reg}
  slice_pin {r:/WORK/Slice/mainPipe/chnl_valid_s5_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/chnlFire_s4_d1_reg}
  slice_pinw {r:/WORK/Slice/mainPipe/customL1Hint/hintQueue/deq_ptr_value_reg} {i:/WORK/Slice/u_core/mainPipe/customL1Hint/hintQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/mainPipe/customL1Hint/hintQueue/enq_ptr_value_reg} {i:/WORK/Slice/u_core/mainPipe/customL1Hint/hintQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/mainPipe/customL1Hint/hint_s1Queue/deq_ptr_value_reg} {i:/WORK/Slice/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/deq_ptr_reg} 2
  slice_pinw {r:/WORK/Slice/mainPipe/customL1Hint/hint_s1Queue/enq_ptr_value_reg} {i:/WORK/Slice/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/enq_ptr_reg} 2
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_0_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[0]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_0_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[0]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_10_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[10]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_10_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[10]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_11_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[11]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_11_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[11]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_12_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[12]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_12_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[12]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_1_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[1]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_1_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[1]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_2_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[2]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_2_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[2]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_3_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[3]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_3_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[3]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_4_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[4]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_4_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[4]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_5_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[5]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_5_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[5]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_6_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[6]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_6_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[6]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_7_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[7]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_7_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[7]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_8_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[8]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_8_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[8]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_9_value_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_reg[9]}
  slice_pin {r:/WORK/Slice/mainPipe/io_perf_9_value_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/perf_d1_reg[9]}
  slice_pin {r:/WORK/Slice/mainPipe/need_write_releaseBuf_s4_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/needWRB_s4_reg}
  slice_pin {r:/WORK/Slice/mainPipe/need_write_releaseBuf_s5_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/needWRB_s5_reg}
  slice_pin {r:/WORK/Slice/mainPipe/reqDropped_s5_REG_1_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/reqDrop_s3_d2_reg}
  slice_pin {r:/WORK/Slice/mainPipe/reqDropped_s5_REG_2_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/reqDrop_s4_d1_reg}
  slice_pin {r:/WORK/Slice/mainPipe/reqDropped_s5_REG_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/reqDrop_s3_d1_reg}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_off_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_param_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_aliasTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_allowRetry_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_bufIdx_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_channel_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_chiOpcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_cmoAll_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_cmoTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_corrupt_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_dbID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_denied_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[denied]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[dirty]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_dsWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[dsWen]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_expCompAck_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_fromL2pft_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_fwdNID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_fwdState_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_fwdTxnID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_homeNID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_isKeyword_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_likelyshared_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_memAttr_allocate_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_memAttr_device_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_memAttr_ewa_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_mergeA_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[mergeA]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_metaWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[metaWen]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_meta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_meta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_meta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_meta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_meta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_meta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_meta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_meta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_mshrId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_mshrRetry_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_mshrTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_needHint_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[needHint]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_needProbeAckData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_off_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[off]} 6
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_opcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_pCrdType_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_param_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[param]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_readProbeDataDown_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_replTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[replTask]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_reqSource_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_resp_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[resp]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_retToSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_set_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[set]} 9
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_size_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[size]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_snpHitRelease_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_sourceId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_srcID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_tagWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_tag_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_tgtID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_traceTag_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_txChannel_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_txnID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_bits_useProbeData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_vaddr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_wayMask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_bits_way_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/req_reg\[way]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s3_valid_hold2_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s3_validHold2_reg} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s3_valid_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s3_valid_reg}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_off_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_param_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_aliasTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_allowRetry_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_bufIdx_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_channel_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_chiOpcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_cmoAll_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_cmoTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_corrupt_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_dbID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_denied_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[denied]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[dirty]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_dsWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[dsWen]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_expCompAck_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_fromL2pft_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_fwdNID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_fwdState_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_fwdTxnID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_homeNID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_isKeyword_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_likelyshared_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_memAttr_allocate_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_memAttr_device_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_memAttr_ewa_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_mergeA_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[mergeA]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_metaWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[metaWen]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_meta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_meta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_meta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_meta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_meta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_meta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_meta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_meta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_mshrId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_mshrRetry_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_mshrTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_needHint_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[needHint]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_needProbeAckData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_off_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[off]} 6
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_opcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_pCrdType_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_param_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[param]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_readProbeDataDown_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_replTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[replTask]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_reqSource_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_resp_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[resp]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_retToSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_set_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[set]} 9
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_size_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[size]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_snpHitRelease_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_sourceId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_srcID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_tagWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_tag_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_tgtID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_traceTag_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_txChannel_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_txnID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_bits_useProbeData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_vaddr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_wayMask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/mainPipe/task_s4_bits_way_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_reg\[way]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s4_valid_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s4_valid_reg}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_off_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_param_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_aliasTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_allowRetry_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_bufIdx_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_channel_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_chiOpcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_cmoAll_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_cmoTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_corrupt_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_dbID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_denied_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[denied]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[dirty]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_dsWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[dsWen]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_expCompAck_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_fromL2pft_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_fwdNID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_fwdState_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_fwdTxnID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_homeNID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_isKeyword_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_likelyshared_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_memAttr_allocate_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_memAttr_device_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_memAttr_ewa_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_mergeA_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[mergeA]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_metaWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[metaWen]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_meta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_meta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_meta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_meta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_meta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_meta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_meta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_meta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_mshrId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_mshrRetry_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_mshrTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_needHint_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[needHint]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_needProbeAckData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_off_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[off]} 6
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_opcode_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_pCrdType_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_param_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[param]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_readProbeDataDown_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_replTask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[replTask]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_reqSource_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_resp_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[resp]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_retToSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_set_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[set]} 9
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_size_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[size]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_snpHitRelease_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_sourceId_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_srcID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_tagWen_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_tag_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_tgtID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_traceTag_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_txChannel_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_txnID_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_bits_useProbeData_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_vaddr_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_wayMask_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/mainPipe/task_s5_bits_way_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_reg\[way]} 3
  slice_pin {r:/WORK/Slice/mainPipe/task_s5_valid_reg} {i:/WORK/Slice/u_core/mainPipe/u_core/s5_valid_reg}
  slice_pin {r:/WORK/Slice/grantBuf/REG_10_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[10]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_11_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[11]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_12_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[12]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_13_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[13]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_14_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[14]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_15_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[15]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_1_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_2_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_3_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_4_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[4]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_5_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[5]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_6_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[6]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_7_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[7]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_8_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[8]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_9_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[9]}
  slice_pin {r:/WORK/Slice/grantBuf/REG_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/validPrev_reg[0]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_10_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[10]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_11_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[11]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_12_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[12]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_13_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[13]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_14_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[14]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_15_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[15]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_1_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_2_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_3_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_4_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[4]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_5_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[5]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_6_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[6]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_7_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[7]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_8_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[8]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_9_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[9]}
  slice_pin {r:/WORK/Slice/grantBuf/enable_REG_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/histValidPrev_reg[0]}
  slice_pin {r:/WORK/Slice/grantBuf/grantBufValid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_valid_reg}
  slice_pinw {r:/WORK/Slice/grantBuf/grantBuf_data_data_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_data_reg} 256
  slice_pinw {r:/WORK/Slice/grantBuf/grantBuf_grantid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_grantid_reg} 8
  slice_pin {r:/WORK/Slice/grantBuf/grantBuf_task_corrupt_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_corrupt_reg}
  slice_pin {r:/WORK/Slice/grantBuf/grantBuf_task_denied_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_denied_reg}
  slice_pin {r:/WORK/Slice/grantBuf/grantBuf_task_isKeyword_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_isKeyword_reg}
  slice_pinw {r:/WORK/Slice/grantBuf/grantBuf_task_opcode_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_opcode_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/grantBuf_task_param_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_param_reg} 3
  slice_pinw {r:/WORK/Slice/grantBuf/grantBuf_task_sourceId_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/gb_sourceId_reg} 7
  slice_pinw {r:/WORK/Slice/grantBuf/grantQueue/deq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/grantQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/grantQueue/enq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/grantQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/grantQueueData0/deq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/grantQueueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/grantQueueData0/enq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/grantQueueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/grantQueueData1/deq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/grantQueueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/grantQueueData1/enq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/grantQueueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_0_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_0_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_0_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[0]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_10_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[10]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_10_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[10]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_10_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[10]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_11_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[11]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_11_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[11]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_11_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[11]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_12_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[12]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_12_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[12]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_12_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[12]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_13_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[13]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_13_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[13]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_13_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[13]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_14_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[14]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_14_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[14]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_14_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[14]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_15_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[15]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_15_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[15]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_15_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[15]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_1_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_1_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_1_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[1]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_2_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_2_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_2_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[2]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_3_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_3_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_3_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[3]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_4_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[4]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_4_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[4]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_4_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[4]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_5_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[5]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_5_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[5]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_5_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[5]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_6_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[6]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_6_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[6]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_6_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[6]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_7_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[7]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_7_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[7]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_7_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[7]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_8_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[8]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_8_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[8]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_8_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[8]}
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_9_bits_set_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_set_reg[9]} 9
  slice_pinw {r:/WORK/Slice/grantBuf/inflightGrant_9_bits_tag_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_tag_reg[9]} 31
  slice_pin {r:/WORK/Slice/grantBuf/inflightGrant_9_valid_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/ig_valid_reg[9]}
  slice_pinw {r:/WORK/Slice/grantBuf/pftRespQueue/deq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/pftRespQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/pftRespQueue/enq_ptr_value_reg} {i:/WORK/Slice/u_core/grantBuf/pftRespQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/grantBuf/timers_0_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_10_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_11_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_12_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_13_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_14_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_15_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_1_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_2_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_3_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_4_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_5_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_6_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_7_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_8_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice/grantBuf/timers_9_reg} {i:/WORK/Slice/u_core/grantBuf/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice/reqBuf/REG_1_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/timerClear_reg[0]}
  slice_pin {r:/WORK/Slice/reqBuf/REG_2_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice/reqBuf/REG_3_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/timerClear_reg[1]}
  slice_pin {r:/WORK/Slice/reqBuf/REG_4_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice/reqBuf/REG_5_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/timerClear_reg[2]}
  slice_pin {r:/WORK/Slice/reqBuf/REG_6_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice/reqBuf/REG_7_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/timerClear_reg[3]}
  slice_pin {r:/WORK/Slice/reqBuf/REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/validPrev_reg[0]}
  slice_pinw {r:/WORK/Slice/reqBuf/bufferTimer_0_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/bufferTimer_reg[0]} 16
  slice_pinw {r:/WORK/Slice/reqBuf/bufferTimer_1_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/bufferTimer_reg[1]} 16
  slice_pinw {r:/WORK/Slice/reqBuf/bufferTimer_2_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/bufferTimer_reg[2]} 16
  slice_pinw {r:/WORK/Slice/reqBuf/bufferTimer_3_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/bufferTimer_reg[3]} 16
  slice_pin {r:/WORK/Slice/reqBuf/buffer_0_rdy_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_rdy_reg[0]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_0_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Valid_reg[2]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_rdy_sameSet_s3_r_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Set_reg[2]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_alias_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[alias_]} 2
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_channel_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_channel_reg[0]} 3
  slice_pin {r:/WORK/Slice/reqBuf/buffer_0_task_corrupt_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[corrupt]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_0_task_fromL2pft_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[fromL2pft]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_0_task_isKeyword_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_0_task_needHint_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[needHint]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_off_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_opcode_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_param_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[param]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_reqSource_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_set_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_size_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_sourceId_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_tag_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_task_vaddr_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[0]\[vaddr]} 44
  slice_pin {r:/WORK/Slice/reqBuf/buffer_0_valid_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_valid_reg[0]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_waitMP_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMP_reg[0]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_0_waitMS_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMS_reg[0]} 16
  slice_pin {r:/WORK/Slice/reqBuf/buffer_1_rdy_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_rdy_reg[1]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_1_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Valid_reg[3]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_rdy_sameSet_s3_r_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Set_reg[3]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_alias_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[alias_]} 2
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_channel_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_channel_reg[1]} 3
  slice_pin {r:/WORK/Slice/reqBuf/buffer_1_task_corrupt_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[corrupt]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_1_task_fromL2pft_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[fromL2pft]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_1_task_isKeyword_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_1_task_needHint_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[needHint]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_off_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_opcode_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_param_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[param]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_reqSource_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_set_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_size_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_sourceId_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_tag_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_task_vaddr_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[1]\[vaddr]} 44
  slice_pin {r:/WORK/Slice/reqBuf/buffer_1_valid_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_valid_reg[1]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_waitMP_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMP_reg[1]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_1_waitMS_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMS_reg[1]} 16
  slice_pin {r:/WORK/Slice/reqBuf/buffer_2_rdy_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_rdy_reg[2]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_2_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Valid_reg[4]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_rdy_sameSet_s3_r_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Set_reg[4]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_alias_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[alias_]} 2
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_channel_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_channel_reg[2]} 3
  slice_pin {r:/WORK/Slice/reqBuf/buffer_2_task_corrupt_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[corrupt]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_2_task_fromL2pft_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[fromL2pft]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_2_task_isKeyword_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_2_task_needHint_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[needHint]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_off_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_opcode_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_param_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[param]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_reqSource_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_set_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_size_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_sourceId_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_tag_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_task_vaddr_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[2]\[vaddr]} 44
  slice_pin {r:/WORK/Slice/reqBuf/buffer_2_valid_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_valid_reg[2]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_waitMP_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMP_reg[2]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_2_waitMS_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMS_reg[2]} 16
  slice_pin {r:/WORK/Slice/reqBuf/buffer_3_rdy_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_rdy_reg[3]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_3_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Valid_reg[5]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_rdy_sameSet_s3_r_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Set_reg[5]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_alias_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[alias_]} 2
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_channel_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_channel_reg[3]} 3
  slice_pin {r:/WORK/Slice/reqBuf/buffer_3_task_corrupt_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[corrupt]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_3_task_fromL2pft_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[fromL2pft]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_3_task_isKeyword_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice/reqBuf/buffer_3_task_needHint_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[needHint]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_off_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_opcode_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_param_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[param]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_reqSource_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_set_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_size_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_sourceId_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_tag_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_task_vaddr_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_task_reg[3]\[vaddr]} 44
  slice_pin {r:/WORK/Slice/reqBuf/buffer_3_valid_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_valid_reg[3]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_waitMP_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMP_reg[3]} 4
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_3_waitMS_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/buffer_waitMS_reg[3]} 16
  slice_pin {r:/WORK/Slice/reqBuf/buffer_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Valid_reg[1]}
  slice_pinw {r:/WORK/Slice/reqBuf/buffer_rdy_sameSet_s3_r_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Set_reg[1]} 9
  slice_pin {r:/WORK/Slice/reqBuf/canFlow_sameSet_s3_REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Valid_reg[0]}
  slice_pinw {r:/WORK/Slice/reqBuf/canFlow_sameSet_s3_r_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/sameSetS3Set_reg[0]} 9
  slice_pin {r:/WORK/Slice/reqBuf/enable_REG_1_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice/reqBuf/enable_REG_2_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice/reqBuf/enable_REG_3_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice/reqBuf/enable_REG_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/histValidPrev_reg[0]}
  slice_pinw {r:/WORK/Slice/reqBuf/io_hasHitPfInMSHR_valid_REG_set_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/hitPfPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice/reqBuf/io_hasHitPfInMSHR_valid_REG_tag_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/hitPfPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice/reqBuf/io_hasMergeA_REG_set_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/mergeAPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice/reqBuf/io_hasMergeA_REG_tag_reg} {i:/WORK/Slice/u_core/reqBuf/u_core/mergeAPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_off_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_param_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_aliasTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_allowRetry_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_bufIdx_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_channel_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_chiOpcode_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_cmoAll_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_cmoTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_corrupt_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_dbID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_denied_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_dsWen_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_expCompAck_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_fromL2pft_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_fwdNID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_fwdState_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_fwdTxnID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_homeNID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_isKeyword_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_likelyshared_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_memAttr_allocate_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_memAttr_device_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_memAttr_ewa_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_mergeA_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_metaWen_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_accessed_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_clients_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_dataErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_prefetch_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_state_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_meta_tagErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_mshrId_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_mshrRetry_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_mshrTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_needHint_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_needProbeAckData_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_off_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_opcode_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_pCrdType_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_param_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_readProbeDataDown_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_replTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_reqSource_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_resp_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_retToSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_set_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_size_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_snpHitRelease_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_sourceId_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_srcID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_tagWen_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_tag_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_tgtID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_traceTag_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_txChannel_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_txnID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice/reqArb/mshr_task_s1_bits_useProbeData_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_vaddr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_wayMask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/reqArb/mshr_task_s1_bits_way_reg} {i:/WORK/Slice/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_off_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_param_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_aliasTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_allowRetry_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_bufIdx_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_channel_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_chiOpcode_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_cmoAll_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_cmoTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_corrupt_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_dbID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_denied_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_dsWen_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_expCompAck_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_fromL2pft_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_fwdNID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_fwdState_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_fwdTxnID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_homeNID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_isKeyword_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_likelyshared_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_memAttr_allocate_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_memAttr_device_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_memAttr_ewa_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_mergeA_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_metaWen_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_meta_accessed_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_meta_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_meta_clients_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_meta_dataErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_meta_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_meta_prefetch_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_meta_state_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_meta_tagErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_mshrId_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_mshrRetry_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_mshrTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_needHint_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_needProbeAckData_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_off_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_opcode_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_pCrdType_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_param_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_readProbeDataDown_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_replTask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_reqSource_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_resp_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_retToSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_set_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_size_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_snpHitRelease_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_sourceId_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_srcID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_tagWen_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_tag_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_tgtID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_traceTag_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_txChannel_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_txnID_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice/reqArb/task_s2_bits_useProbeData_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_vaddr_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_wayMask_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/reqArb/task_s2_bits_way_reg} {i:/WORK/Slice/u_core/reqArb/u_core/task_s2_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice/sinkC/REG_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/bufRespOut_reg[0]} 256
  slice_pin {r:/WORK/Slice/sinkC/REG_1_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskFirePrev_reg}
  slice_pinw {r:/WORK/Slice/sinkC/REG_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/bufRespOut_reg[1]} 256
  slice_pinw {r:/WORK/Slice/sinkC/REG_2_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBufIdxPrev_reg} 2
  slice_pin {r:/WORK/Slice/sinkC/beatValids_0_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[0][0]}
  slice_pin {r:/WORK/Slice/sinkC/beatValids_0_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[0][1]}
  slice_pin {r:/WORK/Slice/sinkC/beatValids_1_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[1][0]}
  slice_pin {r:/WORK/Slice/sinkC/beatValids_1_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[1][1]}
  slice_pin {r:/WORK/Slice/sinkC/beatValids_2_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[2][0]}
  slice_pin {r:/WORK/Slice/sinkC/beatValids_2_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[2][1]}
  slice_pin {r:/WORK/Slice/sinkC/beatValids_3_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[3][0]}
  slice_pin {r:/WORK/Slice/sinkC/beatValids_3_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/beatValids_reg[3][1]}
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_0_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_0_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_1_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_1_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_2_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_2_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_3_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice/sinkC/dataBuf_3_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/dataBuf_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice/sinkC/io_refillBufWrite_bits_data_data_REG_reg} {i:/WORK/Slice/u_core/sinkC/u_core/refillBufIdxReg_reg} 2
  slice_pinw {r:/WORK/Slice/sinkC/io_refillBufWrite_bits_id_REG_reg} {i:/WORK/Slice/u_core/sinkC/u_core/refillIdReg_reg} 4
  slice_pin {r:/WORK/Slice/sinkC/io_refillBufWrite_valid_REG_reg} {i:/WORK/Slice/u_core/sinkC/u_core/refillValidReg_reg}
  slice_pinw {r:/WORK/Slice/sinkC/r_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/bufRespStage_reg[0]} 256
  slice_pinw {r:/WORK/Slice/sinkC/r_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/bufRespStage_reg[1]} 256
  slice_pinw {r:/WORK/Slice/sinkC/taskArb/ctrl_validMask_grantMask_lastGrant_reg} {i:/WORK/Slice/u_core/sinkC/taskArb/u_core/last_grant_q_reg} 2
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_aliasTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[aliasTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[alias_]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_allowRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[allowRetry]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_bufIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_channel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[channel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_chiOpcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_cmoAll_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoAll]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_cmoTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_corrupt_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[corrupt]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_dbID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[dbID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_denied_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[denied]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[dirty]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_dsWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[dsWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_expCompAck_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[expCompAck]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_fromL2pft_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_fwdNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_fwdState_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_fwdTxnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_homeNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[homeNID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_likelyshared_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[likelyshared]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_memAttr_allocate_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_memAttr_device_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_device]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_memAttr_ewa_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_mergeA_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[mergeA]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_metaWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[metaWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_mshrId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrId]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_mshrRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrRetry]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_mshrTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_needHint_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[needHint]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_needProbeAckData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_pCrdType_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[param]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_readProbeDataDown_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_replTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[replTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_reqSource_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_resp_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[resp]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_retToSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[retToSrc]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_set_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_size_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_snpHitRelease_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_srcID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[srcID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_tagWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[tagWen]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_tag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_tgtID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[tgtID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_traceTag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[traceTag]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_txChannel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_txnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[txnID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_0_useProbeData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[useProbeData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_wayMask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_0_way_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[0]\[way]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_aliasTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[aliasTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[alias_]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_allowRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[allowRetry]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_bufIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_channel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[channel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_chiOpcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_cmoAll_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoAll]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_cmoTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_corrupt_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[corrupt]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_dbID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[dbID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_denied_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[denied]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[dirty]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_dsWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[dsWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_expCompAck_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[expCompAck]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_fromL2pft_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_fwdNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_fwdState_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_fwdTxnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_homeNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[homeNID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_likelyshared_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[likelyshared]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_memAttr_allocate_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_memAttr_device_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_device]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_memAttr_ewa_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_mergeA_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[mergeA]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_metaWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[metaWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_mshrId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrId]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_mshrRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrRetry]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_mshrTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_needHint_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[needHint]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_needProbeAckData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_pCrdType_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[param]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_readProbeDataDown_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_replTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[replTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_reqSource_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_resp_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[resp]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_retToSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[retToSrc]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_set_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_size_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_snpHitRelease_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_srcID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[srcID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_tagWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[tagWen]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_tag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_tgtID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[tgtID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_traceTag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[traceTag]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_txChannel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_txnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[txnID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_1_useProbeData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[useProbeData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_wayMask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_1_way_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[1]\[way]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_aliasTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[aliasTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[alias_]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_allowRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[allowRetry]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_bufIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_channel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[channel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_chiOpcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_cmoAll_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoAll]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_cmoTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_corrupt_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[corrupt]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_dbID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[dbID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_denied_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[denied]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[dirty]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_dsWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[dsWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_expCompAck_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[expCompAck]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_fromL2pft_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_fwdNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_fwdState_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_fwdTxnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_homeNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[homeNID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_likelyshared_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[likelyshared]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_memAttr_allocate_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_memAttr_device_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_device]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_memAttr_ewa_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_mergeA_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[mergeA]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_metaWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[metaWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_mshrId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrId]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_mshrRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrRetry]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_mshrTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_needHint_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[needHint]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_needProbeAckData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_pCrdType_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[param]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_readProbeDataDown_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_replTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[replTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_reqSource_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_resp_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[resp]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_retToSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[retToSrc]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_set_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_size_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_snpHitRelease_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_srcID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[srcID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_tagWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[tagWen]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_tag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_tgtID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[tgtID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_traceTag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[traceTag]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_txChannel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_txnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[txnID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_2_useProbeData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[useProbeData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_wayMask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_2_way_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[2]\[way]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_aMergeTask_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_aliasTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[aliasTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[alias_]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_allowRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[allowRetry]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_bufIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_channel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[channel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_chiOpcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_cmoAll_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoAll]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_cmoTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_corrupt_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[corrupt]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_dbID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[dbID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_denied_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[denied]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[dirty]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_dsWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[dsWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_expCompAck_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[expCompAck]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_fromL2pft_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_fwdNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_fwdState_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_fwdTxnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_homeNID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[homeNID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_isKeyword_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_likelyshared_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[likelyshared]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_memAttr_allocate_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_memAttr_cacheable_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_memAttr_device_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_device]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_memAttr_ewa_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_mergeA_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[mergeA]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_metaWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[metaWen]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_meta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_meta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_meta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_meta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_meta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_meta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_meta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_meta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_meta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_mshrId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrId]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_mshrRetry_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrRetry]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_mshrTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrTask]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_needHint_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[needHint]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_needProbeAckData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_off_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_opcode_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_pCrdType_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_param_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[param]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_readProbeDataDown_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_replTask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[replTask]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_reqSource_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_resp_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[resp]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_retToSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[retToSrc]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_set_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_size_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseIdx_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_state_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseToClean_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseToInval_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitReleaseWithData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_snpHitRelease_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_sourceId_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_srcID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[srcID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_tagWen_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[tagWen]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_tag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_tgtID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[tgtID]} 11
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_traceTag_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[traceTag]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_txChannel_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_txnID_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[txnID]} 12
  slice_pin {r:/WORK/Slice/sinkC/taskBuf_3_useProbeData_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[useProbeData]}
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_vaddr_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_wayMask_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice/sinkC/taskBuf_3_way_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskBuf_reg[3]\[way]} 3
  slice_pin {r:/WORK/Slice/sinkC/taskValids_0_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskValids_reg[0]}
  slice_pin {r:/WORK/Slice/sinkC/taskValids_1_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskValids_reg[1]}
  slice_pin {r:/WORK/Slice/sinkC/taskValids_2_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskValids_reg[2]}
  slice_pin {r:/WORK/Slice/sinkC/taskValids_3_reg} {i:/WORK/Slice/u_core/sinkC/u_core/taskValids_reg[3]}
  slice_pin {r:/WORK/Slice/rxsnp/queue/wrap_1_reg} {i:/WORK/Slice/u_core/rxsnp/queue/u_core/deq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice/rxsnp/queue/wrap_reg} {i:/WORK/Slice/u_core/rxsnp/queue/u_core/enq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_10_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[10]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_11_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[11]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_12_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[12]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_13_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[13]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_14_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[14]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_15_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[15]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_1_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[1]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_2_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[2]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_3_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[3]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_4_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[4]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_5_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[5]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_6_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[6]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_7_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[7]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_8_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[8]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_9_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[9]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceBlockSnpMask_REG_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForBlock_reg[0]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_10_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[10]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_11_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[11]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_12_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[12]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_13_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[13]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_14_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[14]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_15_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[15]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_1_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[1]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_2_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[2]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_3_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[3]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_4_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[4]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_5_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[5]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_6_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[6]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_7_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[7]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_8_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[8]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_9_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[9]}
  slice_pin {r:/WORK/Slice/rxsnp/replaceNestSnpMask_REG_reg} {i:/WORK/Slice/u_core/rxsnp/u_core/replPrevForNest_reg[0]}
  slice_pin {r:/WORK/Slice/txdat/beatValids_0_reg} {i:/WORK/Slice/u_core/txdat/u_core/beatValids_reg[0]}
  slice_pin {r:/WORK/Slice/txdat/beatValids_1_reg} {i:/WORK/Slice/u_core/txdat/u_core/beatValids_reg[1]}
  slice_pinw {r:/WORK/Slice/txdat/queue/deq_ptr_value_reg} {i:/WORK/Slice/u_core/txdat/queue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/txdat/queue/enq_ptr_value_reg} {i:/WORK/Slice/u_core/txdat/queue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/txdat/queueData0/deq_ptr_value_reg} {i:/WORK/Slice/u_core/txdat/queueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/txdat/queueData0/enq_ptr_value_reg} {i:/WORK/Slice/u_core/txdat/queueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/txdat/queueData1/deq_ptr_value_reg} {i:/WORK/Slice/u_core/txdat/queueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/txdat/queueData1/enq_ptr_value_reg} {i:/WORK/Slice/u_core/txdat/queueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_0_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_0_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_10_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_10_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_11_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_11_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_12_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_12_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_13_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_13_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_14_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_14_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_15_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_15_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_1_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_1_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_2_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_2_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_3_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_3_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_4_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_4_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_5_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_5_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_6_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_6_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_7_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_7_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_8_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_8_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_9_0_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/buffer_9_1_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice/refillBuf/io_resp_data_data_r_reg} {i:/WORK/Slice/u_core/refillBuf/u_core/r_data_reg} 512
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_0_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_0_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_10_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_10_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_11_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_11_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_12_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_12_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_13_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_13_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_14_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_14_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_15_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_15_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_1_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_1_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_2_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_2_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_3_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_3_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_4_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_4_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_5_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_5_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_6_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_6_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_7_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_7_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_8_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_8_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_9_0_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/buffer_9_1_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice/releaseBuf/io_resp_data_data_r_reg} {i:/WORK/Slice/u_core/releaseBuf/u_core/r_data_reg} 512
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_0_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[0]}
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_1_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[1]}
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_2_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[2]}
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_3_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[3]}
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_4_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[4]}
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_5_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[5]}
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_6_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[6]}
  slice_pin {r:/WORK/Slice/directory/errorAll_s3_7_reg} {i:/WORK/Slice/directory/u_core/errorAll_s3_reg[7]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_0_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[0]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_0_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[0]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_0_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[0]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_0_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[0]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_0_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[0]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_0_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[0]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_0_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[0]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_0_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[0]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_0_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[0]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_1_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[1]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_1_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[1]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_1_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[1]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_1_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[1]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_1_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[1]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_1_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[1]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_1_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[1]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_1_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[1]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_1_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[1]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_2_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[2]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_2_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[2]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_2_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[2]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_2_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[2]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_2_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[2]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_2_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[2]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_2_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[2]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_2_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[2]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_2_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[2]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_3_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[3]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_3_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[3]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_3_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[3]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_3_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[3]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_3_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[3]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_3_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[3]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_3_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[3]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_3_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[3]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_3_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[3]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_4_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[4]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_4_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[4]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_4_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[4]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_4_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[4]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_4_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[4]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_4_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[4]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_4_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[4]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_4_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[4]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_4_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[4]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_5_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[5]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_5_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[5]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_5_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[5]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_5_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[5]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_5_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[5]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_5_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[5]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_5_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[5]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_5_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[5]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_5_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[5]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_6_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[6]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_6_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[6]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_6_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[6]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_6_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[6]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_6_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[6]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_6_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[6]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_6_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[6]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_6_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[6]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_6_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[6]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_7_accessed_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_accessed_reg[7]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_7_alias_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_alias_reg[7]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_7_clients_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_clients_reg[7]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_7_dataErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dataErr_reg[7]}
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_7_dirty_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_dirty_reg[7]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_7_prefetchSrc_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetchSrc_reg[7]} 3
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_7_prefetch_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_prefetch_reg[7]}
  slice_pinw {r:/WORK/Slice/directory/metaAll_s3_7_state_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_state_reg[7]} 2
  slice_pin {r:/WORK/Slice/directory/metaAll_s3_7_tagErr_reg} {i:/WORK/Slice/directory/u_core/metaAll_s3_tagErr_reg[7]}
  slice_pinw {r:/WORK/Slice/directory/origin_bit_opt/_resetSet_reg} {i:/WORK/Slice/directory/origin_bit_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice/directory/origin_bit_opt/_resetState_reg} {i:/WORK/Slice/directory/origin_bit_opt/u_core/resetState_reg}
  slice_pin {r:/WORK/Slice/directory/r_0_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[0]}
  slice_pin {r:/WORK/Slice/directory/r_1_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[1]}
  slice_pin {r:/WORK/Slice/directory/r_2_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[2]}
  slice_pin {r:/WORK/Slice/directory/r_3_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[3]}
  slice_pin {r:/WORK/Slice/directory/r_4_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[4]}
  slice_pin {r:/WORK/Slice/directory/r_5_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[5]}
  slice_pin {r:/WORK/Slice/directory/r_6_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[6]}
  slice_pin {r:/WORK/Slice/directory/r_7_reg} {i:/WORK/Slice/directory/u_core/originHold_reg[7]}
  slice_pinw {r:/WORK/Slice/directory/replacer_sram_opt/_resetSet_reg} {i:/WORK/Slice/directory/replacer_sram_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice/directory/replacer_sram_opt/_resetState_reg} {i:/WORK/Slice/directory/replacer_sram_opt/u_core/resetState_reg}
  slice_pinw {r:/WORK/Slice/directory/req_s2_replacerInfo_channel_reg} {i:/WORK/Slice/directory/u_core/req_s2_channel_reg} 3
  slice_pinw {r:/WORK/Slice/directory/req_s2_replacerInfo_opcode_reg} {i:/WORK/Slice/directory/u_core/req_s2_opcode_reg} 3
  slice_pin {r:/WORK/Slice/directory/req_s2_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice/directory/u_core/req_s2_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice/directory/req_s2_replacerInfo_reqSource_reg} {i:/WORK/Slice/directory/u_core/req_s2_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice/directory/req_s3_replacerInfo_channel_reg} {i:/WORK/Slice/directory/u_core/req_s3_channel_reg} 3
  slice_pinw {r:/WORK/Slice/directory/req_s3_replacerInfo_opcode_reg} {i:/WORK/Slice/directory/u_core/req_s3_opcode_reg} 3
  slice_pin {r:/WORK/Slice/directory/req_s3_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice/directory/u_core/req_s3_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice/directory/req_s3_replacerInfo_reqSource_reg} {i:/WORK/Slice/directory/u_core/req_s3_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_0_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[0]} 31
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_1_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[1]} 31
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_2_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[2]} 31
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_3_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[3]} 31
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_4_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[4]} 31
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_5_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[5]} 31
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_6_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[6]} 31
  slice_pinw {r:/WORK/Slice/directory/tagAll_s3_7_reg} {i:/WORK/Slice/directory/u_core/tagAll_s3_reg[7]} 31
  slice_pin {r:/WORK/Slice/dataStorage/REG_1_reg} {i:/WORK/Slice/dataStorage/u_core/enPrev_reg}
  slice_pinw {r:/WORK/Slice/dataStorage/REG_2_reg} {i:/WORK/Slice/dataStorage/u_core/reqPrev_reg} 14
  slice_pin {r:/WORK/Slice/dataStorage/REG_3_reg} {i:/WORK/Slice/dataStorage/u_core/wrEnPrev_reg}
  slice_pinw {r:/WORK/Slice/dataStorage/REG_4_reg} {i:/WORK/Slice/dataStorage/u_core/wdataPrev_reg} 512
  slice_pin {r:/WORK/Slice/dataStorage/REG_reg} {i:/WORK/Slice/dataStorage/u_core/mcpEnPrev_reg}
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_0/rckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_0/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice/dataStorage/array/array_0_0_0/respReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_0/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_0/wckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_0/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_1/rckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_1/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice/dataStorage/array/array_0_0_1/respReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_1/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_1/wckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_1/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_2/rckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_2/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice/dataStorage/array/array_0_0_2/respReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_2/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_2/wckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_2/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_3/rckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_3/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice/dataStorage/array/array_0_0_3/respReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_3/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice/dataStorage/array/array_0_0_3/wckEnReg_reg} {i:/WORK/Slice/dataStorage/array/array_0_0_3/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice/dataStorage/mbistPl/beReg_reg} {i:/WORK/Slice/dataStorage/mbistPl/u_core/beReg_reg[0]}
  slice_pinw {r:/WORK/Slice/mbistPl/pipelineDataOutReg_reg} {i:/WORK/Slice/mbistPl/u_core/g_node_return.pipelineDataOutReg_reg} 137
  slice_pinw {r:/WORK/Slice/directory/mbistPl/addrReg_reg} {i:/WORK/Slice/directory/mbistPl/u_core/u_ctrl/addrReg_reg} 10
  slice_pin {r:/WORK/Slice/directory/mbistPl/addrRdReg_reg[9]} {i:/WORK/Slice/directory/mbistPl/u_core/u_ctrl/addrRdReg_reg[9]}
  puts "SLICE_PIN_END Slice ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD"
  if {$::SLICE_PIN_BAD != 0 || $::SLICE_PIN_OK != 29392} {
    error "SLICE_PIN_MISMATCH ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD expect=29392"
  }
}
if {$top eq "Slice_1"} {
  # MSHRCtl 1408, MainPipe_1 1202, GrantBuffer 2026, RequestBuffer 788, RequestArb 766, SinkC 4628, RXSNP 34, TXDAT 26, TXREQ 0, TXRSP 0, MSHRBuffer 8704, MSHRBuffer_1 8704, Directory_1 412, DataStorage_1 546, L2Slice_1 137
  puts "SLICE_PIN_BEGIN Slice_1 expect=29381"
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_0_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[0]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_10_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[10]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_11_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[11]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_12_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[12]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_13_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[13]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_14_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[14]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_15_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[15]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_1_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[1]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_2_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[2]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_3_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[3]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_4_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[4]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_5_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[5]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_6_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[6]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_7_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[7]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_8_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[8]} 10
  slice_pinw {r:/WORK/Slice_1/mshrCtl/hpm_timers_9_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/hpm_timers_reg[9]} 10
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_rdy_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[0]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_task_alias_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[0]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_task_opcode_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[0]} 3
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_task_param_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[0]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_task_set_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_task_tag_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_valid_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_0_waitG_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[0]} 7
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_rdy_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[1]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_task_alias_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[1]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_task_opcode_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[1]} 3
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_task_param_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[1]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_task_set_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_task_tag_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_valid_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_1_waitG_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[1]} 7
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_rdy_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[2]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_task_alias_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[2]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_task_opcode_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[2]} 3
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_task_param_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[2]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_task_set_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_task_tag_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_valid_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_2_waitG_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[2]} 7
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_rdy_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[3]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_task_alias_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[3]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_task_opcode_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[3]} 3
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_task_param_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[3]} 2
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_task_set_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_task_tag_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_valid_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_1/mshrCtl/sourceB/probes_3_waitG_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[3]} 7
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_0_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_10_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_11_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_12_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_13_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_14_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_15_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_1_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_2_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_3_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_4_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_5_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_6_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_7_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_8_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice_1/mshrCtl/timers_9_reg} {i:/WORK/Slice_1/u_core/mshrCtl/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice_1/mainPipe/REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s3DropValid_d1_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/chnl_valid_s4_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/chnlFire_s3_d1_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/chnl_valid_s5_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/chnlFire_s3_d1b_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/chnl_valid_s5_REG_2_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/chnlFire_s3_d2_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/chnl_valid_s5_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/chnlFire_s4_d1_reg}
  slice_pinw {r:/WORK/Slice_1/mainPipe/customL1Hint/hintQueue/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/mainPipe/customL1Hint/hintQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/customL1Hint/hintQueue/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/mainPipe/customL1Hint/hintQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/customL1Hint/hint_s1Queue/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/deq_ptr_reg} 2
  slice_pinw {r:/WORK/Slice_1/mainPipe/customL1Hint/hint_s1Queue/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/enq_ptr_reg} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_0_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[0]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_0_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[0]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_10_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[10]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_10_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[10]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_11_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[11]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_11_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[11]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_12_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[12]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_12_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[12]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_1_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[1]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_1_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[1]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_2_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[2]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_2_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[2]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_3_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[3]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_3_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[3]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_4_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[4]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_4_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[4]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_5_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[5]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_5_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[5]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_6_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[6]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_6_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[6]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_7_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[7]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_7_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[7]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_8_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[8]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_8_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[8]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_9_value_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_reg[9]}
  slice_pin {r:/WORK/Slice_1/mainPipe/io_perf_9_value_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/perf_d1_reg[9]}
  slice_pin {r:/WORK/Slice_1/mainPipe/need_write_releaseBuf_s4_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/needWRB_s4_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/need_write_releaseBuf_s5_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/needWRB_s5_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/reqDropped_s5_REG_1_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/reqDrop_s3_d2_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/reqDropped_s5_REG_2_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/reqDrop_s4_d1_reg}
  slice_pin {r:/WORK/Slice_1/mainPipe/reqDropped_s5_REG_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/reqDrop_s3_d1_reg}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_aliasTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_allowRetry_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_bufIdx_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_channel_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_chiOpcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_cmoAll_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_cmoTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_corrupt_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_dbID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_denied_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[denied]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[dirty]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_dsWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_expCompAck_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_fromL2pft_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_fwdNID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_fwdState_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_homeNID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_isKeyword_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_likelyshared_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_memAttr_device_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_mergeA_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_metaWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_mshrId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_mshrRetry_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_mshrTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_needHint_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[needHint]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_off_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_opcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_pCrdType_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_param_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[param]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_replTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_reqSource_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_resp_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_retToSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_set_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_size_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_sourceId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_srcID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_tagWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_tag_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_tgtID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_traceTag_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_txChannel_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_txnID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_bits_useProbeData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_vaddr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_wayMask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_bits_way_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/req_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s3_valid_hold2_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s3_validHold2_reg} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s3_valid_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s3_valid_reg}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_aliasTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_allowRetry_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_bufIdx_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_channel_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_chiOpcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_cmoAll_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_cmoTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_corrupt_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_dbID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_denied_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[denied]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[dirty]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_dsWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_expCompAck_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_fromL2pft_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_fwdNID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_fwdState_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_homeNID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_isKeyword_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_likelyshared_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_memAttr_device_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_mergeA_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_metaWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_mshrId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_mshrRetry_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_mshrTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_needHint_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[needHint]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_off_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_opcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_pCrdType_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_param_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[param]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_replTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_reqSource_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_resp_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_retToSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_set_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_size_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_sourceId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_srcID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_tagWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_tag_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_tgtID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_traceTag_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_txChannel_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_txnID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_bits_useProbeData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_vaddr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_wayMask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s4_bits_way_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_reg\[way]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s4_valid_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s4_valid_reg}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_aliasTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_allowRetry_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_bufIdx_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_channel_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_chiOpcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_cmoAll_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_cmoTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_corrupt_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_dbID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_denied_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[denied]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[dirty]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_dsWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_expCompAck_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_fromL2pft_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_fwdNID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_fwdState_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_homeNID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_isKeyword_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_likelyshared_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_memAttr_device_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_mergeA_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_metaWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_mshrId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_mshrRetry_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_mshrTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_needHint_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[needHint]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_off_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_opcode_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_pCrdType_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_param_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[param]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_replTask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_reqSource_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_resp_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_retToSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_set_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_size_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_sourceId_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_srcID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_tagWen_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_tag_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_tgtID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_traceTag_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_txChannel_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_txnID_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_bits_useProbeData_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_vaddr_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_wayMask_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/mainPipe/task_s5_bits_way_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_reg\[way]} 3
  slice_pin {r:/WORK/Slice_1/mainPipe/task_s5_valid_reg} {i:/WORK/Slice_1/u_core/mainPipe/u_core/s5_valid_reg}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_10_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[10]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_11_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[11]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_12_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[12]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_13_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[13]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_14_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[14]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_15_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[15]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_1_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_2_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_3_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_4_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[4]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_5_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[5]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_6_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[6]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_7_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[7]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_8_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[8]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_9_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[9]}
  slice_pin {r:/WORK/Slice_1/grantBuf/REG_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/validPrev_reg[0]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_10_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[10]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_11_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[11]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_12_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[12]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_13_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[13]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_14_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[14]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_15_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[15]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_1_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_2_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_3_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_4_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[4]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_5_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[5]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_6_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[6]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_7_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[7]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_8_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[8]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_9_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[9]}
  slice_pin {r:/WORK/Slice_1/grantBuf/enable_REG_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/histValidPrev_reg[0]}
  slice_pin {r:/WORK/Slice_1/grantBuf/grantBufValid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_valid_reg}
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantBuf_data_data_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_data_reg} 256
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantBuf_grantid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_grantid_reg} 8
  slice_pin {r:/WORK/Slice_1/grantBuf/grantBuf_task_corrupt_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_corrupt_reg}
  slice_pin {r:/WORK/Slice_1/grantBuf/grantBuf_task_denied_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_denied_reg}
  slice_pin {r:/WORK/Slice_1/grantBuf/grantBuf_task_isKeyword_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_isKeyword_reg}
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantBuf_task_opcode_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_opcode_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantBuf_task_param_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_param_reg} 3
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantBuf_task_sourceId_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/gb_sourceId_reg} 7
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantQueue/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/grantQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantQueue/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/grantQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantQueueData0/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/grantQueueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantQueueData0/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/grantQueueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantQueueData1/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/grantQueueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/grantQueueData1/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/grantQueueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_0_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_0_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_0_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_10_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[10]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_10_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[10]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_10_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[10]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_11_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[11]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_11_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[11]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_11_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[11]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_12_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[12]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_12_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[12]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_12_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[12]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_13_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[13]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_13_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[13]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_13_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[13]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_14_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[14]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_14_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[14]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_14_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[14]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_15_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[15]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_15_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[15]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_15_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[15]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_1_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_1_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_1_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_2_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_2_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_2_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_3_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_3_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_3_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_4_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[4]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_4_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[4]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_4_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[4]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_5_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[5]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_5_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[5]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_5_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[5]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_6_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[6]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_6_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[6]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_6_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[6]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_7_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[7]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_7_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[7]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_7_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[7]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_8_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[8]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_8_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[8]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_8_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[8]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_9_bits_set_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_set_reg[9]} 9
  slice_pinw {r:/WORK/Slice_1/grantBuf/inflightGrant_9_bits_tag_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_tag_reg[9]} 31
  slice_pin {r:/WORK/Slice_1/grantBuf/inflightGrant_9_valid_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/ig_valid_reg[9]}
  slice_pinw {r:/WORK/Slice_1/grantBuf/pftRespQueue/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/pftRespQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/pftRespQueue/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/grantBuf/pftRespQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_0_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_10_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_11_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_12_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_13_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_14_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_15_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_1_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_2_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_3_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_4_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_5_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_6_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_7_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_8_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice_1/grantBuf/timers_9_reg} {i:/WORK/Slice_1/u_core/grantBuf/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_1_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/timerClear_reg[0]}
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_2_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_3_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/timerClear_reg[1]}
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_4_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_5_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/timerClear_reg[2]}
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_6_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_7_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/timerClear_reg[3]}
  slice_pin {r:/WORK/Slice_1/reqBuf/REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/validPrev_reg[0]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/bufferTimer_0_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/bufferTimer_reg[0]} 16
  slice_pinw {r:/WORK/Slice_1/reqBuf/bufferTimer_1_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/bufferTimer_reg[1]} 16
  slice_pinw {r:/WORK/Slice_1/reqBuf/bufferTimer_2_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/bufferTimer_reg[2]} 16
  slice_pinw {r:/WORK/Slice_1/reqBuf/bufferTimer_3_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/bufferTimer_reg[3]} 16
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_0_rdy_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_rdy_reg[0]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_0_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Valid_reg[2]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_alias_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_channel_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_channel_reg[0]} 3
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_0_task_corrupt_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[corrupt]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_0_task_fromL2pft_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_0_task_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_0_task_needHint_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[needHint]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_off_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_opcode_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_param_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[param]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_reqSource_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_set_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_size_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_sourceId_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_tag_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_task_vaddr_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[0]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_0_valid_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_waitMP_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMP_reg[0]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_0_waitMS_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMS_reg[0]} 16
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_1_rdy_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_rdy_reg[1]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_1_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Valid_reg[3]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_alias_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_channel_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_channel_reg[1]} 3
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_1_task_corrupt_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[corrupt]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_1_task_fromL2pft_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_1_task_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_1_task_needHint_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[needHint]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_off_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_opcode_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_param_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[param]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_reqSource_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_set_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_size_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_sourceId_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_tag_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_task_vaddr_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[1]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_1_valid_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_waitMP_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMP_reg[1]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_1_waitMS_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMS_reg[1]} 16
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_2_rdy_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_rdy_reg[2]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_2_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Valid_reg[4]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Set_reg[4]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_alias_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_channel_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_channel_reg[2]} 3
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_2_task_corrupt_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[corrupt]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_2_task_fromL2pft_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_2_task_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_2_task_needHint_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[needHint]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_off_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_opcode_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_param_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[param]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_reqSource_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_set_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_size_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_sourceId_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_tag_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_task_vaddr_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[2]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_2_valid_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_waitMP_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMP_reg[2]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_2_waitMS_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMS_reg[2]} 16
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_3_rdy_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_rdy_reg[3]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_3_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Valid_reg[5]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Set_reg[5]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_alias_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_channel_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_channel_reg[3]} 3
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_3_task_corrupt_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[corrupt]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_3_task_fromL2pft_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_3_task_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_3_task_needHint_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[needHint]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_off_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_opcode_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_param_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[param]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_reqSource_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_set_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_size_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_sourceId_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_tag_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_task_vaddr_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_task_reg[3]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_3_valid_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_waitMP_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMP_reg[3]} 4
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_3_waitMS_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/buffer_waitMS_reg[3]} 16
  slice_pin {r:/WORK/Slice_1/reqBuf/buffer_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Valid_reg[1]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/buffer_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Set_reg[1]} 9
  slice_pin {r:/WORK/Slice_1/reqBuf/canFlow_sameSet_s3_REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Valid_reg[0]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/canFlow_sameSet_s3_r_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/sameSetS3Set_reg[0]} 9
  slice_pin {r:/WORK/Slice_1/reqBuf/enable_REG_1_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice_1/reqBuf/enable_REG_2_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice_1/reqBuf/enable_REG_3_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice_1/reqBuf/enable_REG_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/histValidPrev_reg[0]}
  slice_pinw {r:/WORK/Slice_1/reqBuf/io_hasHitPfInMSHR_valid_REG_set_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/hitPfPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/io_hasHitPfInMSHR_valid_REG_tag_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/hitPfPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice_1/reqBuf/io_hasMergeA_REG_set_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/mergeAPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice_1/reqBuf/io_hasMergeA_REG_tag_reg} {i:/WORK/Slice_1/u_core/reqBuf/u_core/mergeAPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_aliasTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_allowRetry_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_bufIdx_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_channel_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_chiOpcode_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_cmoAll_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_cmoTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_corrupt_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_dbID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_denied_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_dsWen_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_expCompAck_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_fromL2pft_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_fwdNID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_fwdState_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_homeNID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_likelyshared_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_memAttr_device_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_mergeA_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_metaWen_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_accessed_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_clients_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_state_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_mshrId_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_mshrRetry_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_mshrTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_needHint_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_off_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_opcode_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_pCrdType_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_param_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_replTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_reqSource_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_resp_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_retToSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_set_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_size_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_sourceId_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_srcID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_tagWen_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_tag_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_tgtID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_traceTag_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_txChannel_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_txnID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_useProbeData_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_vaddr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_wayMask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/reqArb/mshr_task_s1_bits_way_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_aliasTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_allowRetry_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_bufIdx_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_channel_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_chiOpcode_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_cmoAll_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_cmoTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_corrupt_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_dbID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_denied_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_dsWen_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_expCompAck_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_fromL2pft_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_fwdNID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_fwdState_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_homeNID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_isKeyword_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_likelyshared_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_memAttr_device_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_mergeA_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_metaWen_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_accessed_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_clients_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_state_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_mshrId_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_mshrRetry_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_mshrTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_needHint_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_off_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_opcode_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_pCrdType_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_param_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_replTask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_reqSource_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_resp_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_retToSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_set_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_size_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_sourceId_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_srcID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_tagWen_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_tag_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_tgtID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_traceTag_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_txChannel_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_txnID_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/reqArb/task_s2_bits_useProbeData_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_vaddr_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_wayMask_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/reqArb/task_s2_bits_way_reg} {i:/WORK/Slice_1/u_core/reqArb/u_core/task_s2_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/REG_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/bufRespOut_reg[0]} 256
  slice_pin {r:/WORK/Slice_1/sinkC/REG_1_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskFirePrev_reg}
  slice_pinw {r:/WORK/Slice_1/sinkC/REG_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/bufRespOut_reg[1]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/REG_2_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBufIdxPrev_reg} 2
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_0_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[0][0]}
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_0_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[0][1]}
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_1_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[1][0]}
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_1_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[1][1]}
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_2_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[2][0]}
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_2_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[2][1]}
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_3_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[3][0]}
  slice_pin {r:/WORK/Slice_1/sinkC/beatValids_3_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/beatValids_reg[3][1]}
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_0_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_0_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_1_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_1_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_2_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_2_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_3_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/dataBuf_3_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/dataBuf_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/io_refillBufWrite_bits_data_data_REG_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/refillBufIdxReg_reg} 2
  slice_pinw {r:/WORK/Slice_1/sinkC/io_refillBufWrite_bits_id_REG_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/refillIdReg_reg} 4
  slice_pin {r:/WORK/Slice_1/sinkC/io_refillBufWrite_valid_REG_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/refillValidReg_reg}
  slice_pinw {r:/WORK/Slice_1/sinkC/r_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/bufRespStage_reg[0]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/r_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/bufRespStage_reg[1]} 256
  slice_pinw {r:/WORK/Slice_1/sinkC/taskArb/ctrl_validMask_grantMask_lastGrant_reg} {i:/WORK/Slice_1/u_core/sinkC/taskArb/u_core/last_grant_q_reg} 2
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_aliasTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_allowRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_bufIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_channel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_chiOpcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_cmoAll_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_cmoTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_corrupt_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_dbID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_denied_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[denied]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[dirty]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_dsWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[dsWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_expCompAck_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_fromL2pft_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_fwdNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_fwdState_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_homeNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_likelyshared_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_memAttr_device_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_mergeA_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[mergeA]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_metaWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[metaWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_mshrId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_mshrRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_mshrTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_needHint_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[needHint]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_pCrdType_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[param]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_replTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[replTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_reqSource_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_resp_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[resp]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_retToSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_set_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_size_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_srcID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_tagWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_tag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_tgtID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_traceTag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_txChannel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_txnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_0_useProbeData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_wayMask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_0_way_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[0]\[way]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_aliasTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_allowRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_bufIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_channel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_chiOpcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_cmoAll_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_cmoTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_corrupt_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_dbID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_denied_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[denied]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[dirty]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_dsWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[dsWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_expCompAck_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_fromL2pft_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_fwdNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_fwdState_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_homeNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_likelyshared_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_memAttr_device_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_mergeA_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[mergeA]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_metaWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[metaWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_mshrId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_mshrRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_mshrTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_needHint_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[needHint]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_pCrdType_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[param]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_replTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[replTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_reqSource_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_resp_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[resp]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_retToSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_set_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_size_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_srcID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_tagWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_tag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_tgtID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_traceTag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_txChannel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_txnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_1_useProbeData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_wayMask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_1_way_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[1]\[way]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_aliasTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_allowRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_bufIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_channel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_chiOpcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_cmoAll_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_cmoTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_corrupt_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_dbID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_denied_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[denied]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[dirty]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_dsWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[dsWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_expCompAck_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_fromL2pft_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_fwdNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_fwdState_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_homeNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_likelyshared_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_memAttr_device_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_mergeA_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[mergeA]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_metaWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[metaWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_mshrId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_mshrRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_mshrTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_needHint_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[needHint]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_pCrdType_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[param]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_replTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[replTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_reqSource_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_resp_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[resp]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_retToSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_set_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_size_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_srcID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_tagWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_tag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_tgtID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_traceTag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_txChannel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_txnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_2_useProbeData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_wayMask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_2_way_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[2]\[way]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_aMergeTask_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_aliasTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[alias_]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_allowRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_bufIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_channel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[channel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_chiOpcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_cmoAll_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoAll]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_cmoTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_corrupt_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[corrupt]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_dbID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[dbID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_denied_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[denied]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[dirty]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_dsWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[dsWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_expCompAck_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[expCompAck]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_fromL2pft_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_fwdNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_fwdState_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_fwdTxnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_homeNID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_isKeyword_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_likelyshared_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[likelyshared]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_memAttr_allocate_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_memAttr_cacheable_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_memAttr_device_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_memAttr_ewa_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_mergeA_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[mergeA]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_metaWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[metaWen]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_meta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_mshrId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_mshrRetry_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_mshrTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrTask]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_needHint_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[needHint]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_needProbeAckData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_off_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_opcode_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_pCrdType_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_param_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[param]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_readProbeDataDown_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_replTask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[replTask]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_reqSource_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_resp_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[resp]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_retToSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_set_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_size_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseIdx_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseToClean_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseToInval_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitReleaseWithData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_snpHitRelease_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_sourceId_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_srcID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[srcID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_tagWen_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[tagWen]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_tag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_tgtID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_traceTag_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[traceTag]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_txChannel_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_txnID_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[txnID]} 12
  slice_pin {r:/WORK/Slice_1/sinkC/taskBuf_3_useProbeData_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_vaddr_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_wayMask_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_1/sinkC/taskBuf_3_way_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskBuf_reg[3]\[way]} 3
  slice_pin {r:/WORK/Slice_1/sinkC/taskValids_0_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskValids_reg[0]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskValids_1_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskValids_reg[1]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskValids_2_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskValids_reg[2]}
  slice_pin {r:/WORK/Slice_1/sinkC/taskValids_3_reg} {i:/WORK/Slice_1/u_core/sinkC/u_core/taskValids_reg[3]}
  slice_pin {r:/WORK/Slice_1/rxsnp/queue/wrap_1_reg} {i:/WORK/Slice_1/u_core/rxsnp/queue/u_core/deq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice_1/rxsnp/queue/wrap_reg} {i:/WORK/Slice_1/u_core/rxsnp/queue/u_core/enq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_10_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[10]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_11_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[11]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_12_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[12]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_13_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[13]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_14_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[14]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_15_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[15]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_1_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[1]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_2_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[2]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_3_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[3]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_4_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[4]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_5_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[5]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_6_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[6]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_7_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[7]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_8_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[8]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_9_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[9]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceBlockSnpMask_REG_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForBlock_reg[0]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_10_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[10]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_11_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[11]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_12_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[12]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_13_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[13]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_14_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[14]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_15_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[15]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_1_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[1]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_2_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[2]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_3_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[3]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_4_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[4]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_5_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[5]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_6_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[6]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_7_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[7]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_8_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[8]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_9_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[9]}
  slice_pin {r:/WORK/Slice_1/rxsnp/replaceNestSnpMask_REG_reg} {i:/WORK/Slice_1/u_core/rxsnp/u_core/replPrevForNest_reg[0]}
  slice_pin {r:/WORK/Slice_1/txdat/beatValids_0_reg} {i:/WORK/Slice_1/u_core/txdat/u_core/beatValids_reg[0]}
  slice_pin {r:/WORK/Slice_1/txdat/beatValids_1_reg} {i:/WORK/Slice_1/u_core/txdat/u_core/beatValids_reg[1]}
  slice_pinw {r:/WORK/Slice_1/txdat/queue/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/txdat/queue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/txdat/queue/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/txdat/queue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/txdat/queueData0/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/txdat/queueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/txdat/queueData0/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/txdat/queueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/txdat/queueData1/deq_ptr_value_reg} {i:/WORK/Slice_1/u_core/txdat/queueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/txdat/queueData1/enq_ptr_value_reg} {i:/WORK/Slice_1/u_core/txdat/queueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_0_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_0_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_10_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_10_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_11_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_11_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_12_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_12_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_13_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_13_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_14_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_14_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_15_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_15_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_1_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_1_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_2_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_2_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_3_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_3_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_4_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_4_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_5_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_5_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_6_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_6_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_7_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_7_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_8_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_8_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_9_0_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/buffer_9_1_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice_1/refillBuf/io_resp_data_data_r_reg} {i:/WORK/Slice_1/u_core/refillBuf/u_core/r_data_reg} 512
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_0_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_0_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_10_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_10_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_11_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_11_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_12_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_12_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_13_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_13_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_14_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_14_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_15_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_15_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_1_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_1_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_2_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_2_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_3_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_3_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_4_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_4_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_5_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_5_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_6_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_6_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_7_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_7_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_8_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_8_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_9_0_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/buffer_9_1_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice_1/releaseBuf/io_resp_data_data_r_reg} {i:/WORK/Slice_1/u_core/releaseBuf/u_core/r_data_reg} 512
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_0_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[0]}
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_1_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[1]}
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_2_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[2]}
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_3_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[3]}
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_4_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[4]}
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_5_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[5]}
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_6_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[6]}
  slice_pin {r:/WORK/Slice_1/directory/errorAll_s3_7_reg} {i:/WORK/Slice_1/directory/u_core/errorAll_s3_reg[7]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_0_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[0]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_0_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[0]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_0_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[0]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_0_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[0]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_0_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[0]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_0_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[0]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_0_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[0]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_0_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[0]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_0_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[0]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_1_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[1]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_1_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[1]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_1_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[1]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_1_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[1]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_1_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[1]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_1_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[1]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_1_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[1]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_1_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[1]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_1_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[1]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_2_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[2]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_2_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[2]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_2_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[2]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_2_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[2]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_2_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[2]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_2_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[2]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_2_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[2]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_2_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[2]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_2_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[2]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_3_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[3]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_3_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[3]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_3_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[3]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_3_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[3]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_3_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[3]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_3_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[3]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_3_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[3]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_3_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[3]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_3_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[3]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_4_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[4]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_4_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[4]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_4_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[4]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_4_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[4]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_4_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[4]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_4_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[4]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_4_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[4]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_4_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[4]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_4_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[4]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_5_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[5]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_5_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[5]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_5_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[5]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_5_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[5]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_5_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[5]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_5_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[5]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_5_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[5]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_5_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[5]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_5_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[5]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_6_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[6]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_6_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[6]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_6_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[6]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_6_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[6]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_6_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[6]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_6_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[6]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_6_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[6]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_6_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[6]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_6_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[6]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_7_accessed_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_accessed_reg[7]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_7_alias_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_alias_reg[7]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_7_clients_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_clients_reg[7]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_7_dataErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dataErr_reg[7]}
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_7_dirty_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_dirty_reg[7]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_7_prefetchSrc_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetchSrc_reg[7]} 3
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_7_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_prefetch_reg[7]}
  slice_pinw {r:/WORK/Slice_1/directory/metaAll_s3_7_state_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_state_reg[7]} 2
  slice_pin {r:/WORK/Slice_1/directory/metaAll_s3_7_tagErr_reg} {i:/WORK/Slice_1/directory/u_core/metaAll_s3_tagErr_reg[7]}
  slice_pinw {r:/WORK/Slice_1/directory/origin_bit_opt/_resetSet_reg} {i:/WORK/Slice_1/directory/origin_bit_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice_1/directory/origin_bit_opt/_resetState_reg} {i:/WORK/Slice_1/directory/origin_bit_opt/u_core/resetState_reg}
  slice_pin {r:/WORK/Slice_1/directory/r_0_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[0]}
  slice_pin {r:/WORK/Slice_1/directory/r_1_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[1]}
  slice_pin {r:/WORK/Slice_1/directory/r_2_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[2]}
  slice_pin {r:/WORK/Slice_1/directory/r_3_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[3]}
  slice_pin {r:/WORK/Slice_1/directory/r_4_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[4]}
  slice_pin {r:/WORK/Slice_1/directory/r_5_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[5]}
  slice_pin {r:/WORK/Slice_1/directory/r_6_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[6]}
  slice_pin {r:/WORK/Slice_1/directory/r_7_reg} {i:/WORK/Slice_1/directory/u_core/originHold_reg[7]}
  slice_pinw {r:/WORK/Slice_1/directory/replacer_sram_opt/_resetSet_reg} {i:/WORK/Slice_1/directory/replacer_sram_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice_1/directory/replacer_sram_opt/_resetState_reg} {i:/WORK/Slice_1/directory/replacer_sram_opt/u_core/resetState_reg}
  slice_pinw {r:/WORK/Slice_1/directory/req_s2_replacerInfo_channel_reg} {i:/WORK/Slice_1/directory/u_core/req_s2_channel_reg} 3
  slice_pinw {r:/WORK/Slice_1/directory/req_s2_replacerInfo_opcode_reg} {i:/WORK/Slice_1/directory/u_core/req_s2_opcode_reg} 3
  slice_pin {r:/WORK/Slice_1/directory/req_s2_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/req_s2_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice_1/directory/req_s2_replacerInfo_reqSource_reg} {i:/WORK/Slice_1/directory/u_core/req_s2_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice_1/directory/req_s3_replacerInfo_channel_reg} {i:/WORK/Slice_1/directory/u_core/req_s3_channel_reg} 3
  slice_pinw {r:/WORK/Slice_1/directory/req_s3_replacerInfo_opcode_reg} {i:/WORK/Slice_1/directory/u_core/req_s3_opcode_reg} 3
  slice_pin {r:/WORK/Slice_1/directory/req_s3_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice_1/directory/u_core/req_s3_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice_1/directory/req_s3_replacerInfo_reqSource_reg} {i:/WORK/Slice_1/directory/u_core/req_s3_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_0_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[0]} 31
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_1_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[1]} 31
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_2_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[2]} 31
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_3_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[3]} 31
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_4_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[4]} 31
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_5_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[5]} 31
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_6_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[6]} 31
  slice_pinw {r:/WORK/Slice_1/directory/tagAll_s3_7_reg} {i:/WORK/Slice_1/directory/u_core/tagAll_s3_reg[7]} 31
  slice_pin {r:/WORK/Slice_1/dataStorage/REG_1_reg} {i:/WORK/Slice_1/dataStorage/u_core/enPrev_reg}
  slice_pinw {r:/WORK/Slice_1/dataStorage/REG_2_reg} {i:/WORK/Slice_1/dataStorage/u_core/reqPrev_reg} 14
  slice_pin {r:/WORK/Slice_1/dataStorage/REG_3_reg} {i:/WORK/Slice_1/dataStorage/u_core/wrEnPrev_reg}
  slice_pinw {r:/WORK/Slice_1/dataStorage/REG_4_reg} {i:/WORK/Slice_1/dataStorage/u_core/wdataPrev_reg} 512
  slice_pin {r:/WORK/Slice_1/dataStorage/REG_reg} {i:/WORK/Slice_1/dataStorage/u_core/mcpEnPrev_reg}
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_0/rckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_0/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_1/dataStorage/array/array_0_0_0/respReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_0/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_0/wckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_0/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_1/rckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_1/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_1/dataStorage/array/array_0_0_1/respReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_1/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_1/wckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_1/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_2/rckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_2/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_1/dataStorage/array/array_0_0_2/respReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_2/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_2/wckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_2/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_3/rckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_3/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_1/dataStorage/array/array_0_0_3/respReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_3/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_1/dataStorage/array/array_0_0_3/wckEnReg_reg} {i:/WORK/Slice_1/dataStorage/array/array_0_0_3/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_1/dataStorage/mbistPl/beReg_reg} {i:/WORK/Slice_1/dataStorage/mbistPl/u_core/beReg_reg[0]}
  slice_pinw {r:/WORK/Slice_1/mbistPl/pipelineDataOutReg_reg} {i:/WORK/Slice_1/mbistPl/u_core/g_node_return.pipelineDataOutReg_reg} 137
  puts "SLICE_PIN_END Slice_1 ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD"
  if {$::SLICE_PIN_BAD != 0 || $::SLICE_PIN_OK != 29381} {
    error "SLICE_PIN_MISMATCH ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD expect=29381"
  }
}
if {$top eq "Slice_2"} {
  # MSHRCtl 1408, MainPipe_1 1202, GrantBuffer 2026, RequestBuffer 788, RequestArb 766, SinkC 4628, RXSNP 34, TXDAT 26, TXREQ 0, TXRSP 0, MSHRBuffer 8704, MSHRBuffer_1 8704, Directory_2 412, DataStorage_2 546, L2Slice_2 137
  puts "SLICE_PIN_BEGIN Slice_2 expect=29381"
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_0_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[0]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_10_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[10]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_11_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[11]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_12_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[12]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_13_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[13]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_14_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[14]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_15_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[15]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_1_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[1]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_2_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[2]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_3_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[3]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_4_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[4]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_5_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[5]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_6_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[6]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_7_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[7]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_8_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[8]} 10
  slice_pinw {r:/WORK/Slice_2/mshrCtl/hpm_timers_9_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/hpm_timers_reg[9]} 10
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_rdy_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[0]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_task_alias_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[0]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_task_opcode_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[0]} 3
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_task_param_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[0]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_task_set_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_task_tag_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_valid_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_0_waitG_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[0]} 7
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_rdy_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[1]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_task_alias_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[1]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_task_opcode_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[1]} 3
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_task_param_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[1]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_task_set_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_task_tag_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_valid_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_1_waitG_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[1]} 7
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_rdy_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[2]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_task_alias_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[2]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_task_opcode_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[2]} 3
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_task_param_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[2]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_task_set_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_task_tag_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_valid_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_2_waitG_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[2]} 7
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_rdy_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[3]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_task_alias_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[3]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_task_opcode_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[3]} 3
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_task_param_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[3]} 2
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_task_set_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_task_tag_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_valid_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_2/mshrCtl/sourceB/probes_3_waitG_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[3]} 7
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_0_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_10_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_11_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_12_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_13_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_14_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_15_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_1_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_2_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_3_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_4_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_5_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_6_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_7_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_8_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice_2/mshrCtl/timers_9_reg} {i:/WORK/Slice_2/u_core/mshrCtl/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice_2/mainPipe/REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s3DropValid_d1_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/chnl_valid_s4_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/chnlFire_s3_d1_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/chnl_valid_s5_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/chnlFire_s3_d1b_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/chnl_valid_s5_REG_2_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/chnlFire_s3_d2_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/chnl_valid_s5_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/chnlFire_s4_d1_reg}
  slice_pinw {r:/WORK/Slice_2/mainPipe/customL1Hint/hintQueue/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/mainPipe/customL1Hint/hintQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/customL1Hint/hintQueue/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/mainPipe/customL1Hint/hintQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/customL1Hint/hint_s1Queue/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/deq_ptr_reg} 2
  slice_pinw {r:/WORK/Slice_2/mainPipe/customL1Hint/hint_s1Queue/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/enq_ptr_reg} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_0_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[0]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_0_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[0]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_10_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[10]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_10_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[10]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_11_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[11]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_11_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[11]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_12_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[12]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_12_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[12]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_1_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[1]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_1_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[1]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_2_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[2]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_2_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[2]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_3_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[3]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_3_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[3]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_4_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[4]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_4_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[4]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_5_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[5]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_5_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[5]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_6_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[6]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_6_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[6]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_7_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[7]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_7_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[7]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_8_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[8]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_8_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[8]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_9_value_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_reg[9]}
  slice_pin {r:/WORK/Slice_2/mainPipe/io_perf_9_value_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/perf_d1_reg[9]}
  slice_pin {r:/WORK/Slice_2/mainPipe/need_write_releaseBuf_s4_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/needWRB_s4_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/need_write_releaseBuf_s5_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/needWRB_s5_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/reqDropped_s5_REG_1_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/reqDrop_s3_d2_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/reqDropped_s5_REG_2_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/reqDrop_s4_d1_reg}
  slice_pin {r:/WORK/Slice_2/mainPipe/reqDropped_s5_REG_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/reqDrop_s3_d1_reg}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_aliasTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_allowRetry_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_bufIdx_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_channel_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_chiOpcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_cmoAll_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_cmoTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_corrupt_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_dbID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_denied_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[denied]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[dirty]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_dsWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_expCompAck_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_fromL2pft_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_fwdNID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_fwdState_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_homeNID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_isKeyword_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_likelyshared_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_memAttr_device_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_mergeA_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_metaWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_mshrId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_mshrRetry_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_mshrTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_needHint_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[needHint]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_off_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_opcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_pCrdType_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_param_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[param]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_replTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_reqSource_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_resp_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_retToSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_set_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_size_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_sourceId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_srcID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_tagWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_tag_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_tgtID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_traceTag_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_txChannel_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_txnID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_bits_useProbeData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_vaddr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_wayMask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_bits_way_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/req_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s3_valid_hold2_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s3_validHold2_reg} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s3_valid_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s3_valid_reg}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_aliasTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_allowRetry_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_bufIdx_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_channel_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_chiOpcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_cmoAll_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_cmoTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_corrupt_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_dbID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_denied_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[denied]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[dirty]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_dsWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_expCompAck_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_fromL2pft_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_fwdNID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_fwdState_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_homeNID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_isKeyword_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_likelyshared_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_memAttr_device_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_mergeA_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_metaWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_mshrId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_mshrRetry_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_mshrTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_needHint_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[needHint]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_off_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_opcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_pCrdType_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_param_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[param]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_replTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_reqSource_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_resp_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_retToSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_set_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_size_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_sourceId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_srcID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_tagWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_tag_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_tgtID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_traceTag_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_txChannel_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_txnID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_bits_useProbeData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_vaddr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_wayMask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s4_bits_way_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_reg\[way]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s4_valid_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s4_valid_reg}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_aliasTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_allowRetry_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_bufIdx_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_channel_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_chiOpcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_cmoAll_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_cmoTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_corrupt_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_dbID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_denied_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[denied]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[dirty]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_dsWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_expCompAck_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_fromL2pft_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_fwdNID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_fwdState_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_homeNID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_isKeyword_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_likelyshared_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_memAttr_device_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_mergeA_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_metaWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_mshrId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_mshrRetry_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_mshrTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_needHint_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[needHint]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_off_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_opcode_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_pCrdType_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_param_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[param]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_replTask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_reqSource_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_resp_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_retToSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_set_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_size_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_sourceId_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_srcID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_tagWen_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_tag_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_tgtID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_traceTag_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_txChannel_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_txnID_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_bits_useProbeData_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_vaddr_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_wayMask_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/mainPipe/task_s5_bits_way_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_reg\[way]} 3
  slice_pin {r:/WORK/Slice_2/mainPipe/task_s5_valid_reg} {i:/WORK/Slice_2/u_core/mainPipe/u_core/s5_valid_reg}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_10_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[10]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_11_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[11]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_12_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[12]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_13_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[13]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_14_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[14]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_15_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[15]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_1_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_2_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_3_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_4_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[4]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_5_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[5]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_6_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[6]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_7_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[7]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_8_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[8]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_9_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[9]}
  slice_pin {r:/WORK/Slice_2/grantBuf/REG_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/validPrev_reg[0]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_10_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[10]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_11_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[11]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_12_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[12]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_13_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[13]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_14_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[14]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_15_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[15]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_1_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_2_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_3_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_4_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[4]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_5_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[5]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_6_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[6]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_7_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[7]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_8_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[8]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_9_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[9]}
  slice_pin {r:/WORK/Slice_2/grantBuf/enable_REG_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/histValidPrev_reg[0]}
  slice_pin {r:/WORK/Slice_2/grantBuf/grantBufValid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_valid_reg}
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantBuf_data_data_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_data_reg} 256
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantBuf_grantid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_grantid_reg} 8
  slice_pin {r:/WORK/Slice_2/grantBuf/grantBuf_task_corrupt_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_corrupt_reg}
  slice_pin {r:/WORK/Slice_2/grantBuf/grantBuf_task_denied_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_denied_reg}
  slice_pin {r:/WORK/Slice_2/grantBuf/grantBuf_task_isKeyword_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_isKeyword_reg}
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantBuf_task_opcode_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_opcode_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantBuf_task_param_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_param_reg} 3
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantBuf_task_sourceId_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/gb_sourceId_reg} 7
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantQueue/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/grantQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantQueue/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/grantQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantQueueData0/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/grantQueueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantQueueData0/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/grantQueueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantQueueData1/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/grantQueueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/grantQueueData1/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/grantQueueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_0_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_0_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_0_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_10_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[10]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_10_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[10]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_10_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[10]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_11_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[11]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_11_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[11]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_11_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[11]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_12_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[12]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_12_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[12]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_12_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[12]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_13_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[13]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_13_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[13]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_13_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[13]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_14_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[14]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_14_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[14]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_14_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[14]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_15_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[15]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_15_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[15]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_15_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[15]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_1_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_1_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_1_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_2_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_2_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_2_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_3_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_3_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_3_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_4_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[4]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_4_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[4]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_4_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[4]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_5_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[5]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_5_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[5]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_5_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[5]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_6_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[6]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_6_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[6]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_6_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[6]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_7_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[7]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_7_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[7]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_7_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[7]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_8_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[8]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_8_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[8]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_8_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[8]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_9_bits_set_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_set_reg[9]} 9
  slice_pinw {r:/WORK/Slice_2/grantBuf/inflightGrant_9_bits_tag_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_tag_reg[9]} 31
  slice_pin {r:/WORK/Slice_2/grantBuf/inflightGrant_9_valid_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/ig_valid_reg[9]}
  slice_pinw {r:/WORK/Slice_2/grantBuf/pftRespQueue/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/pftRespQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/pftRespQueue/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/grantBuf/pftRespQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_0_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_10_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_11_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_12_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_13_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_14_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_15_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_1_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_2_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_3_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_4_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_5_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_6_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_7_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_8_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice_2/grantBuf/timers_9_reg} {i:/WORK/Slice_2/u_core/grantBuf/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_1_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/timerClear_reg[0]}
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_2_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_3_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/timerClear_reg[1]}
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_4_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_5_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/timerClear_reg[2]}
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_6_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_7_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/timerClear_reg[3]}
  slice_pin {r:/WORK/Slice_2/reqBuf/REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/validPrev_reg[0]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/bufferTimer_0_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/bufferTimer_reg[0]} 16
  slice_pinw {r:/WORK/Slice_2/reqBuf/bufferTimer_1_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/bufferTimer_reg[1]} 16
  slice_pinw {r:/WORK/Slice_2/reqBuf/bufferTimer_2_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/bufferTimer_reg[2]} 16
  slice_pinw {r:/WORK/Slice_2/reqBuf/bufferTimer_3_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/bufferTimer_reg[3]} 16
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_0_rdy_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_rdy_reg[0]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_0_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Valid_reg[2]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_alias_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_channel_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_channel_reg[0]} 3
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_0_task_corrupt_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[corrupt]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_0_task_fromL2pft_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_0_task_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_0_task_needHint_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[needHint]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_off_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_opcode_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_param_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[param]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_reqSource_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_set_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_size_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_sourceId_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_tag_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_task_vaddr_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[0]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_0_valid_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_waitMP_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMP_reg[0]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_0_waitMS_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMS_reg[0]} 16
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_1_rdy_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_rdy_reg[1]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_1_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Valid_reg[3]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_alias_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_channel_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_channel_reg[1]} 3
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_1_task_corrupt_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[corrupt]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_1_task_fromL2pft_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_1_task_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_1_task_needHint_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[needHint]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_off_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_opcode_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_param_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[param]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_reqSource_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_set_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_size_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_sourceId_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_tag_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_task_vaddr_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[1]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_1_valid_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_waitMP_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMP_reg[1]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_1_waitMS_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMS_reg[1]} 16
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_2_rdy_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_rdy_reg[2]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_2_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Valid_reg[4]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Set_reg[4]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_alias_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_channel_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_channel_reg[2]} 3
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_2_task_corrupt_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[corrupt]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_2_task_fromL2pft_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_2_task_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_2_task_needHint_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[needHint]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_off_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_opcode_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_param_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[param]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_reqSource_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_set_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_size_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_sourceId_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_tag_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_task_vaddr_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[2]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_2_valid_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_waitMP_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMP_reg[2]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_2_waitMS_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMS_reg[2]} 16
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_3_rdy_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_rdy_reg[3]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_3_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Valid_reg[5]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Set_reg[5]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_alias_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_channel_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_channel_reg[3]} 3
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_3_task_corrupt_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[corrupt]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_3_task_fromL2pft_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_3_task_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_3_task_needHint_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[needHint]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_off_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_opcode_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_param_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[param]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_reqSource_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_set_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_size_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_sourceId_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_tag_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_task_vaddr_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_task_reg[3]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_3_valid_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_waitMP_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMP_reg[3]} 4
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_3_waitMS_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/buffer_waitMS_reg[3]} 16
  slice_pin {r:/WORK/Slice_2/reqBuf/buffer_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Valid_reg[1]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/buffer_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Set_reg[1]} 9
  slice_pin {r:/WORK/Slice_2/reqBuf/canFlow_sameSet_s3_REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Valid_reg[0]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/canFlow_sameSet_s3_r_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/sameSetS3Set_reg[0]} 9
  slice_pin {r:/WORK/Slice_2/reqBuf/enable_REG_1_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice_2/reqBuf/enable_REG_2_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice_2/reqBuf/enable_REG_3_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice_2/reqBuf/enable_REG_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/histValidPrev_reg[0]}
  slice_pinw {r:/WORK/Slice_2/reqBuf/io_hasHitPfInMSHR_valid_REG_set_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/hitPfPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/io_hasHitPfInMSHR_valid_REG_tag_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/hitPfPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice_2/reqBuf/io_hasMergeA_REG_set_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/mergeAPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice_2/reqBuf/io_hasMergeA_REG_tag_reg} {i:/WORK/Slice_2/u_core/reqBuf/u_core/mergeAPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_aliasTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_allowRetry_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_bufIdx_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_channel_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_chiOpcode_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_cmoAll_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_cmoTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_corrupt_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_dbID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_denied_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_dsWen_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_expCompAck_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_fromL2pft_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_fwdNID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_fwdState_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_homeNID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_likelyshared_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_memAttr_device_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_mergeA_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_metaWen_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_accessed_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_clients_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_state_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_mshrId_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_mshrRetry_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_mshrTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_needHint_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_off_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_opcode_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_pCrdType_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_param_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_replTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_reqSource_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_resp_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_retToSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_set_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_size_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_sourceId_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_srcID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_tagWen_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_tag_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_tgtID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_traceTag_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_txChannel_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_txnID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_useProbeData_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_vaddr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_wayMask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/reqArb/mshr_task_s1_bits_way_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_aliasTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_allowRetry_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_bufIdx_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_channel_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_chiOpcode_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_cmoAll_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_cmoTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_corrupt_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_dbID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_denied_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_dsWen_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_expCompAck_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_fromL2pft_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_fwdNID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_fwdState_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_homeNID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_isKeyword_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_likelyshared_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_memAttr_device_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_mergeA_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_metaWen_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_accessed_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_clients_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_state_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_mshrId_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_mshrRetry_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_mshrTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_needHint_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_off_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_opcode_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_pCrdType_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_param_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_replTask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_reqSource_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_resp_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_retToSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_set_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_size_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_sourceId_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_srcID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_tagWen_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_tag_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_tgtID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_traceTag_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_txChannel_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_txnID_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/reqArb/task_s2_bits_useProbeData_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_vaddr_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_wayMask_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/reqArb/task_s2_bits_way_reg} {i:/WORK/Slice_2/u_core/reqArb/u_core/task_s2_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/REG_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/bufRespOut_reg[0]} 256
  slice_pin {r:/WORK/Slice_2/sinkC/REG_1_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskFirePrev_reg}
  slice_pinw {r:/WORK/Slice_2/sinkC/REG_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/bufRespOut_reg[1]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/REG_2_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBufIdxPrev_reg} 2
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_0_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[0][0]}
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_0_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[0][1]}
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_1_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[1][0]}
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_1_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[1][1]}
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_2_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[2][0]}
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_2_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[2][1]}
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_3_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[3][0]}
  slice_pin {r:/WORK/Slice_2/sinkC/beatValids_3_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/beatValids_reg[3][1]}
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_0_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_0_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_1_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_1_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_2_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_2_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_3_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/dataBuf_3_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/dataBuf_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/io_refillBufWrite_bits_data_data_REG_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/refillBufIdxReg_reg} 2
  slice_pinw {r:/WORK/Slice_2/sinkC/io_refillBufWrite_bits_id_REG_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/refillIdReg_reg} 4
  slice_pin {r:/WORK/Slice_2/sinkC/io_refillBufWrite_valid_REG_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/refillValidReg_reg}
  slice_pinw {r:/WORK/Slice_2/sinkC/r_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/bufRespStage_reg[0]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/r_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/bufRespStage_reg[1]} 256
  slice_pinw {r:/WORK/Slice_2/sinkC/taskArb/ctrl_validMask_grantMask_lastGrant_reg} {i:/WORK/Slice_2/u_core/sinkC/taskArb/u_core/last_grant_q_reg} 2
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_aliasTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_allowRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_bufIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_channel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_chiOpcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_cmoAll_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_cmoTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_corrupt_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_dbID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_denied_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[denied]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[dirty]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_dsWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[dsWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_expCompAck_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_fromL2pft_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_fwdNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_fwdState_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_homeNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_likelyshared_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_memAttr_device_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_mergeA_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[mergeA]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_metaWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[metaWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_mshrId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_mshrRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_mshrTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_needHint_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[needHint]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_pCrdType_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[param]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_replTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[replTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_reqSource_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_resp_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[resp]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_retToSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_set_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_size_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_srcID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_tagWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_tag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_tgtID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_traceTag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_txChannel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_txnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_0_useProbeData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_wayMask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_0_way_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[0]\[way]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_aliasTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_allowRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_bufIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_channel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_chiOpcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_cmoAll_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_cmoTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_corrupt_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_dbID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_denied_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[denied]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[dirty]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_dsWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[dsWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_expCompAck_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_fromL2pft_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_fwdNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_fwdState_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_homeNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_likelyshared_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_memAttr_device_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_mergeA_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[mergeA]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_metaWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[metaWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_mshrId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_mshrRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_mshrTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_needHint_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[needHint]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_pCrdType_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[param]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_replTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[replTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_reqSource_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_resp_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[resp]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_retToSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_set_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_size_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_srcID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_tagWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_tag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_tgtID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_traceTag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_txChannel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_txnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_1_useProbeData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_wayMask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_1_way_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[1]\[way]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_aliasTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_allowRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_bufIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_channel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_chiOpcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_cmoAll_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_cmoTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_corrupt_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_dbID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_denied_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[denied]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[dirty]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_dsWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[dsWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_expCompAck_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_fromL2pft_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_fwdNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_fwdState_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_homeNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_likelyshared_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_memAttr_device_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_mergeA_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[mergeA]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_metaWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[metaWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_mshrId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_mshrRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_mshrTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_needHint_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[needHint]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_pCrdType_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[param]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_replTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[replTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_reqSource_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_resp_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[resp]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_retToSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_set_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_size_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_srcID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_tagWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_tag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_tgtID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_traceTag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_txChannel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_txnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_2_useProbeData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_wayMask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_2_way_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[2]\[way]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_aMergeTask_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_aliasTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[alias_]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_allowRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_bufIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_channel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[channel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_chiOpcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_cmoAll_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoAll]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_cmoTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_corrupt_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[corrupt]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_dbID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[dbID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_denied_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[denied]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[dirty]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_dsWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[dsWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_expCompAck_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[expCompAck]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_fromL2pft_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_fwdNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_fwdState_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_fwdTxnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_homeNID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_isKeyword_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_likelyshared_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[likelyshared]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_memAttr_allocate_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_memAttr_cacheable_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_memAttr_device_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_memAttr_ewa_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_mergeA_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[mergeA]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_metaWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[metaWen]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_meta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_mshrId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_mshrRetry_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_mshrTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrTask]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_needHint_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[needHint]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_needProbeAckData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_off_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_opcode_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_pCrdType_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_param_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[param]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_readProbeDataDown_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_replTask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[replTask]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_reqSource_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_resp_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[resp]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_retToSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_set_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_size_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseIdx_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseToClean_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseToInval_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitReleaseWithData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_snpHitRelease_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_sourceId_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_srcID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[srcID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_tagWen_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[tagWen]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_tag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_tgtID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_traceTag_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[traceTag]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_txChannel_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_txnID_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[txnID]} 12
  slice_pin {r:/WORK/Slice_2/sinkC/taskBuf_3_useProbeData_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_vaddr_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_wayMask_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_2/sinkC/taskBuf_3_way_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskBuf_reg[3]\[way]} 3
  slice_pin {r:/WORK/Slice_2/sinkC/taskValids_0_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskValids_reg[0]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskValids_1_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskValids_reg[1]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskValids_2_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskValids_reg[2]}
  slice_pin {r:/WORK/Slice_2/sinkC/taskValids_3_reg} {i:/WORK/Slice_2/u_core/sinkC/u_core/taskValids_reg[3]}
  slice_pin {r:/WORK/Slice_2/rxsnp/queue/wrap_1_reg} {i:/WORK/Slice_2/u_core/rxsnp/queue/u_core/deq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice_2/rxsnp/queue/wrap_reg} {i:/WORK/Slice_2/u_core/rxsnp/queue/u_core/enq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_10_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[10]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_11_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[11]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_12_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[12]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_13_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[13]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_14_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[14]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_15_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[15]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_1_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[1]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_2_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[2]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_3_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[3]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_4_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[4]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_5_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[5]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_6_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[6]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_7_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[7]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_8_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[8]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_9_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[9]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceBlockSnpMask_REG_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForBlock_reg[0]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_10_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[10]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_11_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[11]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_12_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[12]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_13_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[13]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_14_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[14]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_15_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[15]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_1_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[1]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_2_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[2]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_3_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[3]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_4_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[4]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_5_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[5]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_6_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[6]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_7_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[7]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_8_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[8]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_9_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[9]}
  slice_pin {r:/WORK/Slice_2/rxsnp/replaceNestSnpMask_REG_reg} {i:/WORK/Slice_2/u_core/rxsnp/u_core/replPrevForNest_reg[0]}
  slice_pin {r:/WORK/Slice_2/txdat/beatValids_0_reg} {i:/WORK/Slice_2/u_core/txdat/u_core/beatValids_reg[0]}
  slice_pin {r:/WORK/Slice_2/txdat/beatValids_1_reg} {i:/WORK/Slice_2/u_core/txdat/u_core/beatValids_reg[1]}
  slice_pinw {r:/WORK/Slice_2/txdat/queue/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/txdat/queue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/txdat/queue/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/txdat/queue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/txdat/queueData0/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/txdat/queueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/txdat/queueData0/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/txdat/queueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/txdat/queueData1/deq_ptr_value_reg} {i:/WORK/Slice_2/u_core/txdat/queueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/txdat/queueData1/enq_ptr_value_reg} {i:/WORK/Slice_2/u_core/txdat/queueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_0_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_0_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_10_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_10_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_11_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_11_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_12_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_12_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_13_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_13_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_14_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_14_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_15_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_15_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_1_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_1_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_2_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_2_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_3_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_3_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_4_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_4_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_5_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_5_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_6_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_6_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_7_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_7_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_8_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_8_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_9_0_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/buffer_9_1_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice_2/refillBuf/io_resp_data_data_r_reg} {i:/WORK/Slice_2/u_core/refillBuf/u_core/r_data_reg} 512
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_0_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_0_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_10_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_10_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_11_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_11_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_12_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_12_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_13_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_13_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_14_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_14_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_15_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_15_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_1_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_1_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_2_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_2_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_3_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_3_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_4_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_4_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_5_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_5_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_6_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_6_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_7_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_7_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_8_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_8_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_9_0_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/buffer_9_1_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice_2/releaseBuf/io_resp_data_data_r_reg} {i:/WORK/Slice_2/u_core/releaseBuf/u_core/r_data_reg} 512
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_0_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[0]}
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_1_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[1]}
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_2_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[2]}
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_3_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[3]}
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_4_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[4]}
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_5_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[5]}
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_6_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[6]}
  slice_pin {r:/WORK/Slice_2/directory/errorAll_s3_7_reg} {i:/WORK/Slice_2/directory/u_core/errorAll_s3_reg[7]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_0_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[0]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_0_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[0]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_0_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[0]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_0_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[0]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_0_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[0]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_0_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[0]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_0_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[0]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_0_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[0]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_0_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[0]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_1_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[1]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_1_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[1]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_1_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[1]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_1_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[1]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_1_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[1]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_1_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[1]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_1_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[1]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_1_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[1]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_1_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[1]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_2_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[2]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_2_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[2]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_2_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[2]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_2_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[2]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_2_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[2]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_2_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[2]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_2_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[2]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_2_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[2]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_2_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[2]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_3_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[3]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_3_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[3]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_3_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[3]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_3_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[3]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_3_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[3]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_3_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[3]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_3_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[3]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_3_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[3]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_3_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[3]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_4_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[4]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_4_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[4]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_4_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[4]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_4_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[4]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_4_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[4]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_4_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[4]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_4_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[4]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_4_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[4]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_4_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[4]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_5_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[5]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_5_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[5]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_5_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[5]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_5_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[5]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_5_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[5]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_5_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[5]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_5_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[5]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_5_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[5]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_5_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[5]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_6_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[6]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_6_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[6]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_6_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[6]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_6_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[6]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_6_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[6]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_6_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[6]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_6_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[6]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_6_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[6]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_6_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[6]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_7_accessed_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_accessed_reg[7]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_7_alias_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_alias_reg[7]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_7_clients_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_clients_reg[7]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_7_dataErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dataErr_reg[7]}
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_7_dirty_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_dirty_reg[7]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_7_prefetchSrc_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetchSrc_reg[7]} 3
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_7_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_prefetch_reg[7]}
  slice_pinw {r:/WORK/Slice_2/directory/metaAll_s3_7_state_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_state_reg[7]} 2
  slice_pin {r:/WORK/Slice_2/directory/metaAll_s3_7_tagErr_reg} {i:/WORK/Slice_2/directory/u_core/metaAll_s3_tagErr_reg[7]}
  slice_pinw {r:/WORK/Slice_2/directory/origin_bit_opt/_resetSet_reg} {i:/WORK/Slice_2/directory/origin_bit_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice_2/directory/origin_bit_opt/_resetState_reg} {i:/WORK/Slice_2/directory/origin_bit_opt/u_core/resetState_reg}
  slice_pin {r:/WORK/Slice_2/directory/r_0_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[0]}
  slice_pin {r:/WORK/Slice_2/directory/r_1_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[1]}
  slice_pin {r:/WORK/Slice_2/directory/r_2_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[2]}
  slice_pin {r:/WORK/Slice_2/directory/r_3_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[3]}
  slice_pin {r:/WORK/Slice_2/directory/r_4_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[4]}
  slice_pin {r:/WORK/Slice_2/directory/r_5_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[5]}
  slice_pin {r:/WORK/Slice_2/directory/r_6_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[6]}
  slice_pin {r:/WORK/Slice_2/directory/r_7_reg} {i:/WORK/Slice_2/directory/u_core/originHold_reg[7]}
  slice_pinw {r:/WORK/Slice_2/directory/replacer_sram_opt/_resetSet_reg} {i:/WORK/Slice_2/directory/replacer_sram_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice_2/directory/replacer_sram_opt/_resetState_reg} {i:/WORK/Slice_2/directory/replacer_sram_opt/u_core/resetState_reg}
  slice_pinw {r:/WORK/Slice_2/directory/req_s2_replacerInfo_channel_reg} {i:/WORK/Slice_2/directory/u_core/req_s2_channel_reg} 3
  slice_pinw {r:/WORK/Slice_2/directory/req_s2_replacerInfo_opcode_reg} {i:/WORK/Slice_2/directory/u_core/req_s2_opcode_reg} 3
  slice_pin {r:/WORK/Slice_2/directory/req_s2_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/req_s2_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice_2/directory/req_s2_replacerInfo_reqSource_reg} {i:/WORK/Slice_2/directory/u_core/req_s2_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice_2/directory/req_s3_replacerInfo_channel_reg} {i:/WORK/Slice_2/directory/u_core/req_s3_channel_reg} 3
  slice_pinw {r:/WORK/Slice_2/directory/req_s3_replacerInfo_opcode_reg} {i:/WORK/Slice_2/directory/u_core/req_s3_opcode_reg} 3
  slice_pin {r:/WORK/Slice_2/directory/req_s3_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice_2/directory/u_core/req_s3_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice_2/directory/req_s3_replacerInfo_reqSource_reg} {i:/WORK/Slice_2/directory/u_core/req_s3_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_0_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[0]} 31
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_1_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[1]} 31
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_2_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[2]} 31
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_3_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[3]} 31
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_4_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[4]} 31
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_5_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[5]} 31
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_6_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[6]} 31
  slice_pinw {r:/WORK/Slice_2/directory/tagAll_s3_7_reg} {i:/WORK/Slice_2/directory/u_core/tagAll_s3_reg[7]} 31
  slice_pin {r:/WORK/Slice_2/dataStorage/REG_1_reg} {i:/WORK/Slice_2/dataStorage/u_core/enPrev_reg}
  slice_pinw {r:/WORK/Slice_2/dataStorage/REG_2_reg} {i:/WORK/Slice_2/dataStorage/u_core/reqPrev_reg} 14
  slice_pin {r:/WORK/Slice_2/dataStorage/REG_3_reg} {i:/WORK/Slice_2/dataStorage/u_core/wrEnPrev_reg}
  slice_pinw {r:/WORK/Slice_2/dataStorage/REG_4_reg} {i:/WORK/Slice_2/dataStorage/u_core/wdataPrev_reg} 512
  slice_pin {r:/WORK/Slice_2/dataStorage/REG_reg} {i:/WORK/Slice_2/dataStorage/u_core/mcpEnPrev_reg}
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_0/rckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_0/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_2/dataStorage/array/array_0_0_0/respReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_0/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_0/wckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_0/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_1/rckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_1/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_2/dataStorage/array/array_0_0_1/respReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_1/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_1/wckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_1/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_2/rckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_2/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_2/dataStorage/array/array_0_0_2/respReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_2/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_2/wckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_2/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_3/rckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_3/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_2/dataStorage/array/array_0_0_3/respReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_3/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_2/dataStorage/array/array_0_0_3/wckEnReg_reg} {i:/WORK/Slice_2/dataStorage/array/array_0_0_3/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_2/dataStorage/mbistPl/beReg_reg} {i:/WORK/Slice_2/dataStorage/mbistPl/u_core/beReg_reg[0]}
  slice_pinw {r:/WORK/Slice_2/mbistPl/pipelineDataOutReg_reg} {i:/WORK/Slice_2/mbistPl/u_core/g_node_return.pipelineDataOutReg_reg} 137
  puts "SLICE_PIN_END Slice_2 ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD"
  if {$::SLICE_PIN_BAD != 0 || $::SLICE_PIN_OK != 29381} {
    error "SLICE_PIN_MISMATCH ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD expect=29381"
  }
}
if {$top eq "Slice_3"} {
  # MSHRCtl 1408, MainPipe_1 1202, GrantBuffer 2026, RequestBuffer 788, RequestArb 766, SinkC 4628, RXSNP 34, TXDAT 26, TXREQ 0, TXRSP 0, MSHRBuffer 8704, MSHRBuffer_1 8704, Directory_3 412, DataStorage_3 546, L2Slice_3 137
  puts "SLICE_PIN_BEGIN Slice_3 expect=29381"
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_0_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[0]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_10_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[10]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_11_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[11]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_12_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[12]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_13_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[13]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_14_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[14]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_15_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[15]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_1_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[1]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_2_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[2]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_3_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[3]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_4_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[4]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_5_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[5]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_6_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[6]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_7_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[7]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_8_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[8]} 10
  slice_pinw {r:/WORK/Slice_3/mshrCtl/hpm_timers_9_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/hpm_timers_reg[9]} 10
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_rdy_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[0]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_task_alias_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[0]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_task_opcode_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[0]} 3
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_task_param_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[0]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_task_set_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_task_tag_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_valid_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_0_waitG_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[0]} 7
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_rdy_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[1]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_task_alias_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[1]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_task_opcode_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[1]} 3
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_task_param_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[1]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_task_set_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_task_tag_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_valid_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_1_waitG_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[1]} 7
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_rdy_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[2]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_task_alias_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[2]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_task_opcode_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[2]} 3
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_task_param_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[2]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_task_set_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_task_tag_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_valid_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_2_waitG_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[2]} 7
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_rdy_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_rdy_reg[3]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_task_alias_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_alias_reg[3]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_task_opcode_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_opcode_reg[3]} 3
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_task_param_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_param_reg[3]} 2
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_task_set_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_task_tag_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_valid_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_3/mshrCtl/sourceB/probes_3_waitG_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/sourceB/u_core/probes_waitG_reg[3]} 7
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_0_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_10_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_11_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_12_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_13_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_14_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_15_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_1_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_2_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_3_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_4_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_5_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_6_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_7_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_8_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice_3/mshrCtl/timers_9_reg} {i:/WORK/Slice_3/u_core/mshrCtl/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice_3/mainPipe/REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s3DropValid_d1_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/chnl_valid_s4_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/chnlFire_s3_d1_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/chnl_valid_s5_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/chnlFire_s3_d1b_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/chnl_valid_s5_REG_2_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/chnlFire_s3_d2_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/chnl_valid_s5_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/chnlFire_s4_d1_reg}
  slice_pinw {r:/WORK/Slice_3/mainPipe/customL1Hint/hintQueue/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/mainPipe/customL1Hint/hintQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/customL1Hint/hintQueue/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/mainPipe/customL1Hint/hintQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/customL1Hint/hint_s1Queue/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/deq_ptr_reg} 2
  slice_pinw {r:/WORK/Slice_3/mainPipe/customL1Hint/hint_s1Queue/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/mainPipe/customL1Hint/hint_s1Queue/u_core/enq_ptr_reg} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_0_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[0]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_0_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[0]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_10_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[10]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_10_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[10]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_11_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[11]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_11_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[11]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_12_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[12]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_12_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[12]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_1_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[1]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_1_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[1]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_2_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[2]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_2_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[2]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_3_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[3]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_3_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[3]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_4_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[4]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_4_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[4]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_5_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[5]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_5_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[5]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_6_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[6]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_6_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[6]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_7_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[7]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_7_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[7]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_8_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[8]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_8_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[8]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_9_value_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_reg[9]}
  slice_pin {r:/WORK/Slice_3/mainPipe/io_perf_9_value_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/perf_d1_reg[9]}
  slice_pin {r:/WORK/Slice_3/mainPipe/need_write_releaseBuf_s4_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/needWRB_s4_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/need_write_releaseBuf_s5_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/needWRB_s5_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/reqDropped_s5_REG_1_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/reqDrop_s3_d2_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/reqDropped_s5_REG_2_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/reqDrop_s4_d1_reg}
  slice_pin {r:/WORK/Slice_3/mainPipe/reqDropped_s5_REG_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/reqDrop_s3_d1_reg}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_aliasTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_allowRetry_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_bufIdx_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_channel_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_chiOpcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_cmoAll_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_cmoTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_corrupt_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_dbID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_denied_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[denied]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[dirty]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_dsWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_expCompAck_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_fromL2pft_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_fwdNID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_fwdState_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_homeNID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_isKeyword_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_likelyshared_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_memAttr_device_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_mergeA_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_metaWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_mshrId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_mshrRetry_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_mshrTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_needHint_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[needHint]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_off_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_opcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_pCrdType_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_param_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[param]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_replTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_reqSource_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_resp_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_retToSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_set_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_size_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_sourceId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_srcID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_tagWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_tag_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_tgtID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_traceTag_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_txChannel_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_txnID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_bits_useProbeData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_vaddr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_wayMask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_bits_way_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/req_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s3_valid_hold2_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s3_validHold2_reg} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s3_valid_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s3_valid_reg}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_aliasTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_allowRetry_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_bufIdx_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_channel_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_chiOpcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_cmoAll_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_cmoTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_corrupt_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_dbID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_denied_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[denied]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[dirty]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_dsWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_expCompAck_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_fromL2pft_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_fwdNID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_fwdState_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_homeNID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_isKeyword_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_likelyshared_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_memAttr_device_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_mergeA_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_metaWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_mshrId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_mshrRetry_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_mshrTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_needHint_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[needHint]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_off_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_opcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_pCrdType_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_param_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[param]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_replTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_reqSource_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_resp_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_retToSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_set_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_size_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_sourceId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_srcID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_tagWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_tag_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_tgtID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_traceTag_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_txChannel_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_txnID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_bits_useProbeData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_vaddr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_wayMask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s4_bits_way_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_reg\[way]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s4_valid_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s4_valid_reg}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_aliasTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_allowRetry_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_bufIdx_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_channel_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_chiOpcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_cmoAll_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_cmoTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_corrupt_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_dbID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_denied_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[denied]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[dirty]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_dsWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_expCompAck_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_fromL2pft_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_fwdNID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_fwdState_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_homeNID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_isKeyword_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_likelyshared_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_memAttr_device_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_mergeA_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_metaWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_mshrId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_mshrRetry_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_mshrTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_needHint_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[needHint]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_off_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_opcode_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_pCrdType_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_param_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[param]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_replTask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_reqSource_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_resp_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_retToSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_set_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_size_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_sourceId_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_srcID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_tagWen_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_tag_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_tgtID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_traceTag_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_txChannel_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_txnID_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_bits_useProbeData_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_vaddr_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_wayMask_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/mainPipe/task_s5_bits_way_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_reg\[way]} 3
  slice_pin {r:/WORK/Slice_3/mainPipe/task_s5_valid_reg} {i:/WORK/Slice_3/u_core/mainPipe/u_core/s5_valid_reg}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_10_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[10]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_11_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[11]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_12_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[12]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_13_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[13]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_14_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[14]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_15_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[15]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_1_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_2_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_3_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_4_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[4]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_5_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[5]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_6_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[6]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_7_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[7]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_8_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[8]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_9_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[9]}
  slice_pin {r:/WORK/Slice_3/grantBuf/REG_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/validPrev_reg[0]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_10_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[10]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_11_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[11]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_12_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[12]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_13_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[13]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_14_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[14]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_15_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[15]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_1_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_2_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_3_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_4_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[4]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_5_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[5]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_6_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[6]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_7_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[7]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_8_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[8]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_9_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[9]}
  slice_pin {r:/WORK/Slice_3/grantBuf/enable_REG_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/histValidPrev_reg[0]}
  slice_pin {r:/WORK/Slice_3/grantBuf/grantBufValid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_valid_reg}
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantBuf_data_data_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_data_reg} 256
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantBuf_grantid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_grantid_reg} 8
  slice_pin {r:/WORK/Slice_3/grantBuf/grantBuf_task_corrupt_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_corrupt_reg}
  slice_pin {r:/WORK/Slice_3/grantBuf/grantBuf_task_denied_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_denied_reg}
  slice_pin {r:/WORK/Slice_3/grantBuf/grantBuf_task_isKeyword_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_isKeyword_reg}
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantBuf_task_opcode_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_opcode_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantBuf_task_param_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_param_reg} 3
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantBuf_task_sourceId_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/gb_sourceId_reg} 7
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantQueue/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/grantQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantQueue/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/grantQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantQueueData0/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/grantQueueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantQueueData0/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/grantQueueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantQueueData1/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/grantQueueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/grantQueueData1/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/grantQueueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_0_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[0]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_0_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[0]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_0_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_10_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[10]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_10_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[10]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_10_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[10]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_11_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[11]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_11_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[11]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_11_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[11]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_12_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[12]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_12_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[12]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_12_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[12]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_13_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[13]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_13_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[13]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_13_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[13]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_14_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[14]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_14_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[14]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_14_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[14]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_15_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[15]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_15_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[15]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_15_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[15]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_1_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[1]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_1_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[1]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_1_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_2_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_2_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[2]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_2_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_3_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_3_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[3]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_3_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_4_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[4]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_4_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[4]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_4_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[4]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_5_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[5]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_5_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[5]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_5_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[5]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_6_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[6]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_6_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[6]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_6_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[6]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_7_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[7]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_7_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[7]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_7_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[7]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_8_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[8]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_8_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[8]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_8_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[8]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_9_bits_set_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_set_reg[9]} 9
  slice_pinw {r:/WORK/Slice_3/grantBuf/inflightGrant_9_bits_tag_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_tag_reg[9]} 31
  slice_pin {r:/WORK/Slice_3/grantBuf/inflightGrant_9_valid_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/ig_valid_reg[9]}
  slice_pinw {r:/WORK/Slice_3/grantBuf/pftRespQueue/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/pftRespQueue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/pftRespQueue/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/grantBuf/pftRespQueue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_0_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[0]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_10_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[10]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_11_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[11]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_12_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[12]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_13_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[13]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_14_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[14]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_15_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[15]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_1_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[1]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_2_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[2]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_3_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[3]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_4_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[4]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_5_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[5]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_6_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[6]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_7_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[7]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_8_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[8]} 64
  slice_pinw {r:/WORK/Slice_3/grantBuf/timers_9_reg} {i:/WORK/Slice_3/u_core/grantBuf/u_core/timers_reg[9]} 64
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_1_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/timerClear_reg[0]}
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_2_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/validPrev_reg[1]}
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_3_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/timerClear_reg[1]}
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_4_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/validPrev_reg[2]}
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_5_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/timerClear_reg[2]}
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_6_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/validPrev_reg[3]}
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_7_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/timerClear_reg[3]}
  slice_pin {r:/WORK/Slice_3/reqBuf/REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/validPrev_reg[0]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/bufferTimer_0_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/bufferTimer_reg[0]} 16
  slice_pinw {r:/WORK/Slice_3/reqBuf/bufferTimer_1_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/bufferTimer_reg[1]} 16
  slice_pinw {r:/WORK/Slice_3/reqBuf/bufferTimer_2_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/bufferTimer_reg[2]} 16
  slice_pinw {r:/WORK/Slice_3/reqBuf/bufferTimer_3_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/bufferTimer_reg[3]} 16
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_0_rdy_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_rdy_reg[0]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_0_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Valid_reg[2]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Set_reg[2]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_alias_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_channel_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_channel_reg[0]} 3
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_0_task_corrupt_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[corrupt]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_0_task_fromL2pft_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_0_task_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_0_task_needHint_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[needHint]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_off_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_opcode_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_param_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[param]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_reqSource_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_set_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_size_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_sourceId_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_tag_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_task_vaddr_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[0]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_0_valid_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_valid_reg[0]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_waitMP_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMP_reg[0]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_0_waitMS_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMS_reg[0]} 16
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_1_rdy_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_rdy_reg[1]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_1_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Valid_reg[3]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Set_reg[3]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_alias_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_channel_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_channel_reg[1]} 3
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_1_task_corrupt_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[corrupt]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_1_task_fromL2pft_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_1_task_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_1_task_needHint_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[needHint]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_off_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_opcode_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_param_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[param]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_reqSource_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_set_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_size_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_sourceId_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_tag_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_task_vaddr_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[1]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_1_valid_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_valid_reg[1]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_waitMP_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMP_reg[1]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_1_waitMS_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMS_reg[1]} 16
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_2_rdy_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_rdy_reg[2]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_2_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Valid_reg[4]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Set_reg[4]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_alias_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_channel_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_channel_reg[2]} 3
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_2_task_corrupt_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[corrupt]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_2_task_fromL2pft_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_2_task_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_2_task_needHint_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[needHint]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_off_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_opcode_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_param_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[param]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_reqSource_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_set_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_size_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_sourceId_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_tag_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_task_vaddr_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[2]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_2_valid_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_valid_reg[2]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_waitMP_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMP_reg[2]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_2_waitMS_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMS_reg[2]} 16
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_3_rdy_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_rdy_reg[3]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_3_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Valid_reg[5]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Set_reg[5]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_alias_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[alias_]} 2
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_channel_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_channel_reg[3]} 3
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_3_task_corrupt_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[corrupt]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_3_task_fromL2pft_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[fromL2pft]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_3_task_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_3_task_needHint_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[needHint]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_off_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_opcode_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_param_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[param]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_reqSource_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_set_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_size_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_sourceId_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_tag_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_task_vaddr_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_task_reg[3]\[vaddr]} 44
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_3_valid_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_valid_reg[3]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_waitMP_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMP_reg[3]} 4
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_3_waitMS_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/buffer_waitMS_reg[3]} 16
  slice_pin {r:/WORK/Slice_3/reqBuf/buffer_rdy_sameSet_s3_REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Valid_reg[1]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/buffer_rdy_sameSet_s3_r_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Set_reg[1]} 9
  slice_pin {r:/WORK/Slice_3/reqBuf/canFlow_sameSet_s3_REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Valid_reg[0]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/canFlow_sameSet_s3_r_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/sameSetS3Set_reg[0]} 9
  slice_pin {r:/WORK/Slice_3/reqBuf/enable_REG_1_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/histValidPrev_reg[1]}
  slice_pin {r:/WORK/Slice_3/reqBuf/enable_REG_2_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/histValidPrev_reg[2]}
  slice_pin {r:/WORK/Slice_3/reqBuf/enable_REG_3_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/histValidPrev_reg[3]}
  slice_pin {r:/WORK/Slice_3/reqBuf/enable_REG_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/histValidPrev_reg[0]}
  slice_pinw {r:/WORK/Slice_3/reqBuf/io_hasHitPfInMSHR_valid_REG_set_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/hitPfPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/io_hasHitPfInMSHR_valid_REG_tag_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/hitPfPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice_3/reqBuf/io_hasMergeA_REG_set_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/mergeAPrev_set_reg} 9
  slice_pinw {r:/WORK/Slice_3/reqBuf/io_hasMergeA_REG_tag_reg} {i:/WORK/Slice_3/u_core/reqBuf/u_core/mergeAPrev_tag_reg} 31
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_aliasTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_allowRetry_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_bufIdx_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_channel_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_chiOpcode_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_cmoAll_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_cmoTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_corrupt_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_dbID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_denied_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_dsWen_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_expCompAck_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_fromL2pft_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_fwdNID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_fwdState_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_homeNID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_likelyshared_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_memAttr_device_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_mergeA_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_metaWen_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_accessed_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_clients_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_state_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_mshrId_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_mshrRetry_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_mshrTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_needHint_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_off_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_opcode_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_pCrdType_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_param_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_replTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_reqSource_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_resp_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_retToSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_set_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_size_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_sourceId_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_srcID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_tagWen_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_tag_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_tgtID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_traceTag_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_txChannel_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_txnID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_useProbeData_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_vaddr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_wayMask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/reqArb/mshr_task_s1_bits_way_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/mshr_task_s1_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_aliasTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_allowRetry_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_bufIdx_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_channel_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_chiOpcode_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_cmoAll_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_cmoTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_corrupt_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_dbID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_denied_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[denied]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[dirty]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_dsWen_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[dsWen]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_expCompAck_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_fromL2pft_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_fwdNID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_fwdState_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_homeNID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_isKeyword_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_likelyshared_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_memAttr_device_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_mergeA_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[mergeA]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_metaWen_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[metaWen]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_accessed_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_clients_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_state_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_mshrId_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_mshrRetry_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_mshrTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_needHint_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[needHint]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_off_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[off]} 6
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_opcode_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_pCrdType_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_param_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[param]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_replTask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[replTask]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_reqSource_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_resp_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[resp]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_retToSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_set_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[set]} 9
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_size_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[size]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_sourceId_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_srcID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_tagWen_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_tag_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_tgtID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_traceTag_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_txChannel_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_txnID_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/reqArb/task_s2_bits_useProbeData_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_vaddr_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_wayMask_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/reqArb/task_s2_bits_way_reg} {i:/WORK/Slice_3/u_core/reqArb/u_core/task_s2_bits_reg\[way]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/REG_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/bufRespOut_reg[0]} 256
  slice_pin {r:/WORK/Slice_3/sinkC/REG_1_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskFirePrev_reg}
  slice_pinw {r:/WORK/Slice_3/sinkC/REG_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/bufRespOut_reg[1]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/REG_2_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBufIdxPrev_reg} 2
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_0_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[0][0]}
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_0_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[0][1]}
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_1_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[1][0]}
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_1_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[1][1]}
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_2_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[2][0]}
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_2_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[2][1]}
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_3_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[3][0]}
  slice_pin {r:/WORK/Slice_3/sinkC/beatValids_3_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/beatValids_reg[3][1]}
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_0_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_0_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_1_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_1_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_2_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_2_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_3_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/dataBuf_3_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/dataBuf_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/io_refillBufWrite_bits_data_data_REG_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/refillBufIdxReg_reg} 2
  slice_pinw {r:/WORK/Slice_3/sinkC/io_refillBufWrite_bits_id_REG_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/refillIdReg_reg} 4
  slice_pin {r:/WORK/Slice_3/sinkC/io_refillBufWrite_valid_REG_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/refillValidReg_reg}
  slice_pinw {r:/WORK/Slice_3/sinkC/r_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/bufRespStage_reg[0]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/r_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/bufRespStage_reg[1]} 256
  slice_pinw {r:/WORK/Slice_3/sinkC/taskArb/ctrl_validMask_grantMask_lastGrant_reg} {i:/WORK/Slice_3/u_core/sinkC/taskArb/u_core/last_grant_q_reg} 2
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_aliasTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_allowRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_bufIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_channel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_chiOpcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_cmoAll_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_cmoTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_corrupt_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_dbID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_denied_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[denied]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[dirty]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_dsWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[dsWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_expCompAck_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_fromL2pft_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_fwdNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_fwdState_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_homeNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_likelyshared_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_memAttr_device_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_mergeA_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[mergeA]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_metaWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[metaWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_mshrId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_mshrRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_mshrTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_needHint_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[needHint]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_pCrdType_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[param]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_replTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[replTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_reqSource_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_resp_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[resp]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_retToSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_set_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_size_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_srcID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_tagWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_tag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_tgtID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_traceTag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_txChannel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_txnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_0_useProbeData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_wayMask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_0_way_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[0]\[way]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_aliasTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_allowRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_bufIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_channel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_chiOpcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_cmoAll_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_cmoTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_corrupt_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_dbID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_denied_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[denied]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[dirty]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_dsWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[dsWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_expCompAck_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_fromL2pft_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_fwdNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_fwdState_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_homeNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_likelyshared_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_memAttr_device_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_mergeA_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[mergeA]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_metaWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[metaWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_mshrId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_mshrRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_mshrTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_needHint_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[needHint]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_pCrdType_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[param]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_replTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[replTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_reqSource_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_resp_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[resp]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_retToSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_set_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_size_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_srcID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_tagWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_tag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_tgtID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_traceTag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_txChannel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_txnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_1_useProbeData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_wayMask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_1_way_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[1]\[way]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_aliasTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_allowRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_bufIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_channel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_chiOpcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_cmoAll_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_cmoTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_corrupt_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_dbID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_denied_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[denied]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[dirty]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_dsWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[dsWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_expCompAck_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_fromL2pft_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_fwdNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_fwdState_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_homeNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_likelyshared_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_memAttr_device_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_mergeA_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[mergeA]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_metaWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[metaWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_mshrId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_mshrRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_mshrTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_needHint_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[needHint]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_pCrdType_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[param]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_replTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[replTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_reqSource_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_resp_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[resp]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_retToSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_set_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_size_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_srcID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_tagWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_tag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_tgtID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_traceTag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_txChannel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_txnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_2_useProbeData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_wayMask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_2_way_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[2]\[way]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_opcode]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_param]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_aMergeTask_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aMergeTask_vaddr]} 44
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_aliasTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[aliasTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[alias_]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_allowRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[allowRetry]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_bufIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[bufIdx]} 2
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_channel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[channel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_chiOpcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[chiOpcode]} 7
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_cmoAll_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoAll]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_cmoTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[cmoTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_corrupt_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[corrupt]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_dbID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[dbID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_denied_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[denied]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[dirty]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_dsWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[dsWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_expCompAck_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[expCompAck]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_fromL2pft_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[fromL2pft]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_fwdNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdNID]} 11
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_fwdState_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdState]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_fwdTxnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[fwdTxnID]} 12
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_homeNID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[homeNID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_isKeyword_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[isKeyword]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_likelyshared_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[likelyshared]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_memAttr_allocate_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_allocate]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_memAttr_cacheable_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_cacheable]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_memAttr_device_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_device]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_memAttr_ewa_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[memAttr_ewa]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_mergeA_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[mergeA]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_metaWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[metaWen]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_meta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[meta_tagErr]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_mshrId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrId]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_mshrRetry_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrRetry]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_mshrTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[mshrTask]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_needHint_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[needHint]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_needProbeAckData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[needProbeAckData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_off_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[off]} 6
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_opcode_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[opcode]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_pCrdType_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[pCrdType]} 4
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_param_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[param]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_readProbeDataDown_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[readProbeDataDown]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_replTask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[replTask]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_reqSource_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[reqSource]} 5
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_resp_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[resp]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_retToSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[retToSrc]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_set_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[set]} 9
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_size_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[size]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseIdx_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseIdx]} 8
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_accessed_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_accessed]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_alias_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_alias]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_clients_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_clients]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_dataErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dataErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_dirty_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_dirty]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_prefetchSrc_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetchSrc]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_prefetch_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_prefetch]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_state_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_state]} 2
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseMeta_tagErr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseMeta_tagErr]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseToClean_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToClean]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseToInval_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseToInval]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitReleaseWithData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitReleaseWithData]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_snpHitRelease_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[snpHitRelease]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_sourceId_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[sourceId]} 7
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_srcID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[srcID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_tagWen_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[tagWen]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_tag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[tag]} 31
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_tgtID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[tgtID]} 11
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_traceTag_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[traceTag]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_txChannel_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[txChannel]} 3
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_txnID_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[txnID]} 12
  slice_pin {r:/WORK/Slice_3/sinkC/taskBuf_3_useProbeData_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[useProbeData]}
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_vaddr_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[vaddr]} 44
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_wayMask_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[wayMask]} 8
  slice_pinw {r:/WORK/Slice_3/sinkC/taskBuf_3_way_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskBuf_reg[3]\[way]} 3
  slice_pin {r:/WORK/Slice_3/sinkC/taskValids_0_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskValids_reg[0]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskValids_1_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskValids_reg[1]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskValids_2_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskValids_reg[2]}
  slice_pin {r:/WORK/Slice_3/sinkC/taskValids_3_reg} {i:/WORK/Slice_3/u_core/sinkC/u_core/taskValids_reg[3]}
  slice_pin {r:/WORK/Slice_3/rxsnp/queue/wrap_1_reg} {i:/WORK/Slice_3/u_core/rxsnp/queue/u_core/deq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice_3/rxsnp/queue/wrap_reg} {i:/WORK/Slice_3/u_core/rxsnp/queue/u_core/enq_ptr_reg[0]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_10_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[10]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_11_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[11]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_12_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[12]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_13_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[13]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_14_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[14]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_15_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[15]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_1_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[1]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_2_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[2]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_3_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[3]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_4_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[4]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_5_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[5]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_6_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[6]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_7_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[7]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_8_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[8]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_9_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[9]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceBlockSnpMask_REG_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForBlock_reg[0]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_10_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[10]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_11_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[11]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_12_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[12]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_13_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[13]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_14_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[14]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_15_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[15]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_1_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[1]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_2_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[2]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_3_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[3]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_4_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[4]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_5_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[5]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_6_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[6]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_7_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[7]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_8_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[8]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_9_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[9]}
  slice_pin {r:/WORK/Slice_3/rxsnp/replaceNestSnpMask_REG_reg} {i:/WORK/Slice_3/u_core/rxsnp/u_core/replPrevForNest_reg[0]}
  slice_pin {r:/WORK/Slice_3/txdat/beatValids_0_reg} {i:/WORK/Slice_3/u_core/txdat/u_core/beatValids_reg[0]}
  slice_pin {r:/WORK/Slice_3/txdat/beatValids_1_reg} {i:/WORK/Slice_3/u_core/txdat/u_core/beatValids_reg[1]}
  slice_pinw {r:/WORK/Slice_3/txdat/queue/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/txdat/queue/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/txdat/queue/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/txdat/queue/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/txdat/queueData0/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/txdat/queueData0/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/txdat/queueData0/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/txdat/queueData0/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/txdat/queueData1/deq_ptr_value_reg} {i:/WORK/Slice_3/u_core/txdat/queueData1/u_core/deq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/txdat/queueData1/enq_ptr_value_reg} {i:/WORK/Slice_3/u_core/txdat/queueData1/u_core/enq_ptr_reg} 4
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_0_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_0_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_10_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_10_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_11_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_11_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_12_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_12_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_13_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_13_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_14_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_14_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_15_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_15_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_1_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_1_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_2_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_2_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_3_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_3_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_4_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_4_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_5_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_5_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_6_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_6_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_7_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_7_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_8_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_8_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_9_0_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/buffer_9_1_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice_3/refillBuf/io_resp_data_data_r_reg} {i:/WORK/Slice_3/u_core/refillBuf/u_core/r_data_reg} 512
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_0_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[0][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_0_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[0][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_10_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[10][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_10_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[10][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_11_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[11][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_11_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[11][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_12_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[12][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_12_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[12][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_13_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[13][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_13_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[13][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_14_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[14][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_14_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[14][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_15_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[15][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_15_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[15][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_1_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[1][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_1_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[1][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_2_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[2][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_2_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[2][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_3_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[3][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_3_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[3][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_4_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[4][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_4_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[4][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_5_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[5][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_5_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[5][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_6_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[6][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_6_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[6][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_7_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[7][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_7_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[7][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_8_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[8][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_8_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[8][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_9_0_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[9][0]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/buffer_9_1_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/buffer_reg[9][1]} 256
  slice_pinw {r:/WORK/Slice_3/releaseBuf/io_resp_data_data_r_reg} {i:/WORK/Slice_3/u_core/releaseBuf/u_core/r_data_reg} 512
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_0_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[0]}
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_1_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[1]}
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_2_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[2]}
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_3_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[3]}
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_4_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[4]}
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_5_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[5]}
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_6_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[6]}
  slice_pin {r:/WORK/Slice_3/directory/errorAll_s3_7_reg} {i:/WORK/Slice_3/directory/u_core/errorAll_s3_reg[7]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_0_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[0]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_0_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[0]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_0_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[0]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_0_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[0]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_0_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[0]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_0_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[0]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_0_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[0]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_0_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[0]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_0_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[0]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_1_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[1]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_1_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[1]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_1_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[1]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_1_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[1]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_1_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[1]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_1_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[1]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_1_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[1]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_1_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[1]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_1_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[1]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_2_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[2]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_2_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[2]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_2_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[2]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_2_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[2]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_2_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[2]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_2_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[2]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_2_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[2]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_2_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[2]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_2_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[2]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_3_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[3]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_3_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[3]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_3_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[3]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_3_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[3]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_3_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[3]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_3_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[3]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_3_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[3]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_3_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[3]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_3_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[3]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_4_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[4]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_4_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[4]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_4_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[4]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_4_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[4]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_4_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[4]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_4_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[4]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_4_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[4]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_4_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[4]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_4_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[4]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_5_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[5]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_5_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[5]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_5_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[5]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_5_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[5]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_5_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[5]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_5_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[5]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_5_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[5]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_5_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[5]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_5_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[5]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_6_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[6]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_6_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[6]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_6_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[6]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_6_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[6]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_6_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[6]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_6_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[6]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_6_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[6]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_6_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[6]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_6_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[6]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_7_accessed_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_accessed_reg[7]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_7_alias_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_alias_reg[7]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_7_clients_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_clients_reg[7]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_7_dataErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dataErr_reg[7]}
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_7_dirty_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_dirty_reg[7]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_7_prefetchSrc_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetchSrc_reg[7]} 3
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_7_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_prefetch_reg[7]}
  slice_pinw {r:/WORK/Slice_3/directory/metaAll_s3_7_state_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_state_reg[7]} 2
  slice_pin {r:/WORK/Slice_3/directory/metaAll_s3_7_tagErr_reg} {i:/WORK/Slice_3/directory/u_core/metaAll_s3_tagErr_reg[7]}
  slice_pinw {r:/WORK/Slice_3/directory/origin_bit_opt/_resetSet_reg} {i:/WORK/Slice_3/directory/origin_bit_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice_3/directory/origin_bit_opt/_resetState_reg} {i:/WORK/Slice_3/directory/origin_bit_opt/u_core/resetState_reg}
  slice_pin {r:/WORK/Slice_3/directory/r_0_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[0]}
  slice_pin {r:/WORK/Slice_3/directory/r_1_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[1]}
  slice_pin {r:/WORK/Slice_3/directory/r_2_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[2]}
  slice_pin {r:/WORK/Slice_3/directory/r_3_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[3]}
  slice_pin {r:/WORK/Slice_3/directory/r_4_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[4]}
  slice_pin {r:/WORK/Slice_3/directory/r_5_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[5]}
  slice_pin {r:/WORK/Slice_3/directory/r_6_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[6]}
  slice_pin {r:/WORK/Slice_3/directory/r_7_reg} {i:/WORK/Slice_3/directory/u_core/originHold_reg[7]}
  slice_pinw {r:/WORK/Slice_3/directory/replacer_sram_opt/_resetSet_reg} {i:/WORK/Slice_3/directory/replacer_sram_opt/u_core/resetSet_reg} 9
  slice_pin {r:/WORK/Slice_3/directory/replacer_sram_opt/_resetState_reg} {i:/WORK/Slice_3/directory/replacer_sram_opt/u_core/resetState_reg}
  slice_pinw {r:/WORK/Slice_3/directory/req_s2_replacerInfo_channel_reg} {i:/WORK/Slice_3/directory/u_core/req_s2_channel_reg} 3
  slice_pinw {r:/WORK/Slice_3/directory/req_s2_replacerInfo_opcode_reg} {i:/WORK/Slice_3/directory/u_core/req_s2_opcode_reg} 3
  slice_pin {r:/WORK/Slice_3/directory/req_s2_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/req_s2_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice_3/directory/req_s2_replacerInfo_reqSource_reg} {i:/WORK/Slice_3/directory/u_core/req_s2_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice_3/directory/req_s3_replacerInfo_channel_reg} {i:/WORK/Slice_3/directory/u_core/req_s3_channel_reg} 3
  slice_pinw {r:/WORK/Slice_3/directory/req_s3_replacerInfo_opcode_reg} {i:/WORK/Slice_3/directory/u_core/req_s3_opcode_reg} 3
  slice_pin {r:/WORK/Slice_3/directory/req_s3_replacerInfo_refill_prefetch_reg} {i:/WORK/Slice_3/directory/u_core/req_s3_refill_prefetch_reg}
  slice_pinw {r:/WORK/Slice_3/directory/req_s3_replacerInfo_reqSource_reg} {i:/WORK/Slice_3/directory/u_core/req_s3_reqSource_reg} 5
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_0_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[0]} 31
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_1_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[1]} 31
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_2_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[2]} 31
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_3_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[3]} 31
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_4_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[4]} 31
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_5_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[5]} 31
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_6_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[6]} 31
  slice_pinw {r:/WORK/Slice_3/directory/tagAll_s3_7_reg} {i:/WORK/Slice_3/directory/u_core/tagAll_s3_reg[7]} 31
  slice_pin {r:/WORK/Slice_3/dataStorage/REG_1_reg} {i:/WORK/Slice_3/dataStorage/u_core/enPrev_reg}
  slice_pinw {r:/WORK/Slice_3/dataStorage/REG_2_reg} {i:/WORK/Slice_3/dataStorage/u_core/reqPrev_reg} 14
  slice_pin {r:/WORK/Slice_3/dataStorage/REG_3_reg} {i:/WORK/Slice_3/dataStorage/u_core/wrEnPrev_reg}
  slice_pinw {r:/WORK/Slice_3/dataStorage/REG_4_reg} {i:/WORK/Slice_3/dataStorage/u_core/wdataPrev_reg} 512
  slice_pin {r:/WORK/Slice_3/dataStorage/REG_reg} {i:/WORK/Slice_3/dataStorage/u_core/mcpEnPrev_reg}
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_0/rckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_0/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_3/dataStorage/array/array_0_0_0/respReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_0/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_0/wckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_0/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_1/rckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_1/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_3/dataStorage/array/array_0_0_1/respReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_1/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_1/wckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_1/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_2/rckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_2/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_3/dataStorage/array/array_0_0_2/respReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_2/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_2/wckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_2/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_3/rckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_3/u_core/g_mcp.rckEnReg_reg}
  slice_pinw {r:/WORK/Slice_3/dataStorage/array/array_0_0_3/respReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_3/u_core/g_mcp.respReg_reg} 2
  slice_pin {r:/WORK/Slice_3/dataStorage/array/array_0_0_3/wckEnReg_reg} {i:/WORK/Slice_3/dataStorage/array/array_0_0_3/u_core/g_mcp.wckEnReg_reg}
  slice_pin {r:/WORK/Slice_3/dataStorage/mbistPl/beReg_reg} {i:/WORK/Slice_3/dataStorage/mbistPl/u_core/beReg_reg[0]}
  slice_pinw {r:/WORK/Slice_3/mbistPl/pipelineDataOutReg_reg} {i:/WORK/Slice_3/mbistPl/u_core/g_node_return.pipelineDataOutReg_reg} 137
  puts "SLICE_PIN_END Slice_3 ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD"
  if {$::SLICE_PIN_BAD != 0 || $::SLICE_PIN_OK != 29381} {
    error "SLICE_PIN_MISMATCH ok=$::SLICE_PIN_OK bad=$::SLICE_PIN_BAD expect=29381"
  }
}
