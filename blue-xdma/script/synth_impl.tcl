if {[llength $argv] != 1} {
    error "Usage: $argv0 <project_dir>"
}

set project_dir [lindex $argv 0]

open_project $project_dir

launch_runs impl_1 -to_step write_bitstream
wait_on_runs impl_1
