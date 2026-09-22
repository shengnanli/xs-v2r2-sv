set d tb_top.sim.cpu.l_soc.core_with_l2.core.backend.inner_ctrlBlock.dispatch
set names {}
foreach s {reset io_toRenameAllFire io_enqRob_canAccept io_enqRob_isEmpty io_redirect_valid _lsqEnqCtrl_io_enq_canAccept core_toRenameAllFire core_fromRenameReady core_firedVec core_uopBlockByIQ core_iqReady core_uopSelIQ core_allowDispatch core_thisCanActualOut allowDispatch_0 allowDispatch_2 thisCanActualOut_2 uopBlockByIQ_2 conserveFlowTotal_2 _lsqEnqCtrl_io_lqFreeCount _lsqEnqCtrl_io_sqFreeCount} { lappend names $s }
for {set i 0} {$i < 6} {incr i} { foreach p [list io_fromRename_${i}_valid io_fromRename_${i}_ready io_enqRob_req_${i}_valid io_renameIn_${i}_valid io_toMem_lsqEnqIO_req_${i}_valid io_fromRename_${i}_bits_fuType] { lappend names $p } }
for {set i 0} {$i < 34} {incr i} { lappend names io_toIssueQueues_${i}_ready io_toIssueQueues_${i}_valid }
set live {}
foreach n $names { if {[catch {get -radix bin $d.$n} v]} { puts "NOSIG $n" } else { lappend live $n } }
set fh [open samples.txt w]
puts $fh "# [join $live " "]"
run 1ns
for {set c 0} {$c < 3000} {incr c} {
  set row {}
  foreach n $live { lappend row [get -radix bin $d.$n] }
  puts $fh "$c [join $row " "]"
  run 2ns
}
close $fh
puts "SAMPLED"
quit
