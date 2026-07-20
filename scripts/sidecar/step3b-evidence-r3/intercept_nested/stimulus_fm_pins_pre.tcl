set __f [open /tmp/.nested_stim.tcl w]
puts $__f {set_app_var verification_timeout_limit 100}
close $__f
source /tmp/.nested_stim.tcl
