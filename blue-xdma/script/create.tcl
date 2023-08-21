if {[llength $argv] != 2} {
    error "Usage: $argv0 <build_dir> <bsc_lib_dir> <pcie_blk_locn>"
}

set build_dir [lindex $argv 0]
set pcie_blk_locn [lindex $argv 1]

# Create project and specify the target device and memory option
create_project -force -quiet -part xcvu13p-fhgb2104-2-i -in_memory

# Create IP and set the IP name, vendor, and module name
create_ip -quiet -name xdma -vendor xilinx.com -library ip -module_name xdma

# Set the IP configuration properties
set_property -dict [ list \
  CONFIG.pl_link_cap_max_link_width {X1} \
  CONFIG.dsc_bypass_rd {0001} \
  CONFIG.dsc_bypass_wr {0001} \
  CONFIG.xdma_axilite_slave {true} \
  CONFIG.pcie_blk_locn $pcie_blk_locn \
] [get_ips xdma]

# Open the example project and specify the IP to use
open_example_project -force -in_process -dir $build_dir [get_ips xdma]

# Copy test files and source files to the project
file copy -force "./sim/tests.vh" [get_files tests.vh]
file copy -force "./sim/xilinx_dma_pcie_ep.sv" [get_files xilinx_dma_pcie_ep.sv]

# Import required files
import_files -fileset sources_1 [list \
  "./src/mkXdmaTestbench.v" \
]

# Import the BSC library
import_files -fileset sources_1 $build_dir
remove_files main.v

# Set the top module
set_property top xilinx_dma_pcie_ep [get_filesets sources_1]

# Import constraint files
import_files -fileset constrs_1 [list \
  "./sim/pcie_${pcie_blk_locn}.xdc" \
]
