set d tb_top.sim.cpu.l_soc.core_with_l2.core.backend.inner_ctrlBlock.dispatch
run 1ns
run [expr {1132*2}]ns
set fh [open payload.txt w]
for {set q 0} {$q < 34} {incr q} {
  set v [get -radix bin $d.io_toIssueQueues_${q}_valid]
  if {$v ne "'b1"} continue
  puts $fh "q=$q valid=$v"
  foreach leaf {fuType robIdx_value pdest srcState_0 srcState_1 srcState_2 srcState_3 srcState_4 srcType_2 lqIdx_flag lqIdx_value sqIdx_flag sqIdx_value useRegCache_0 useRegCache_1 regCacheIdx_0 regCacheIdx_1 srcLoadDependency_0_0 srcLoadDependency_0_1 srcLoadDependency_0_2 srcLoadDependency_1_0 srcLoadDependency_1_1 srcLoadDependency_1_2} {
    if {[catch {get -radix bin $d.io_toIssueQueues_${q}_bits_$leaf} x]} { set x NOSIG }
    puts $fh "  $leaf = $x"
  }
}
foreach l {lqIdx_value sqIdx_value} { puts $fh "toMem_req_0_bits? [catch {get -radix bin $d.io_toMem_lsqEnqIO_req_0_bits_$l} x] $x" }
close $fh
puts "PAYLOAD_DONE"
quit
