if {[llength $argv] != 1} {
    error "Usage: $argv0 <project_dir>"
}

set project_dir [lindex $argv 0]

open_project $project_dir

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
set_property -name xsim.more_options -value {-testplusarg TESTNAME=bypass_test} -objects [get_filesets sim_1]

launch_simulation
