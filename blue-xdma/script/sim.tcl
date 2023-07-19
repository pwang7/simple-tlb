set build_dir [lindex $argv 0]

open_project ./$build_dir/xdma_ex/xdma_ex.xpr

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
set_property -name xsim.more_options -value {-testplusarg TESTNAME=bypass_test} -objects [get_filesets sim_1]

launch_simulation
