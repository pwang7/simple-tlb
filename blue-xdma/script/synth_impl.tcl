open_project ./build/xdma_ex/xdma_ex.xpr

launch_runs impl_1 -to_step write_bitstream
wait_on_runs impl_1
