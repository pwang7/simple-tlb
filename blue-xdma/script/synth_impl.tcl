set build_dir [lindex $argv 0]

open_project ./$build_dir/xdma_ex/xdma_ex.xpr

launch_runs impl_1 -to_step write_bitstream
wait_on_runs impl_1
