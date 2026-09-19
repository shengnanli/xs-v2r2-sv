set u $env(UND)
if {$u ne "default"} { set_app_var verification_set_undriven_signals $u }
puts "SAFETY_UNDRIVEN [get_app_var verification_set_undriven_signals]"
read_sverilog -container r -libname WORK -05 ./R_ref0.sv
set_top r:/WORK/U
read_sverilog -container i -libname WORK ./R_impl_missing.sv
set_top i:/WORK/U
match
verify
exit 0
