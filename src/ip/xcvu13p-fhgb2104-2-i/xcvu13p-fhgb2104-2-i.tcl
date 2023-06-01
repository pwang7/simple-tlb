set qsfp_clk_M 161.1328125
set qsfp_lanes 4x25
set cmac_property [list \
    CONFIG.ADD_GT_CNRL_STS_PORTS {true} \
    CONFIG.CMAC_CAUI4_MODE {true} \
    CONFIG.ENABLE_AXI_INTERFACE {false} \
    CONFIG.GT_REF_CLK_FREQ $qsfp_clk_M \
    CONFIG.INCLUDE_RS_FEC {false} \
    CONFIG.INS_LOSS_NYQ {1} \
    CONFIG.NUM_LANES $qsfp_lanes \
    CONFIG.RX_EQ_MODE {DFE} \
    CONFIG.RX_FLOW_CONTROL {false} \
    CONFIG.TX_FLOW_CONTROL {false} \
    CONFIG.TX_FRAME_CRC_CHECKING {Enable FCS Insertion} \
    CONFIG.TX_OTN_INTERFACE {false} \
    CONFIG.USER_INTERFACE {AXIS} \
]
set xdma_property [list \
    CONFIG.mcap_enablement {Tandem_PCIe} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pf0_base_class_menu {Simple_communication_controllers} \
    CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
    CONFIG.pl_link_cap_max_link_width {X16} \
    CONFIG.xdma_axi_intf_mm {AXI_Stream} \
    CONFIG.xdma_axilite_slave {true} \
    CONFIG.xdma_rnum_chnl {1} \
    CONFIG.xdma_sts_ports {false} \
    CONFIG.xdma_wnum_chnl {1} \
]

create_ip -name cmac_usplus -vendor xilinx.com -library ip -module_name cmac_usplus_0
set_property -dict $cmac_property [get_ips cmac_usplus_0]
create_ip -name xdma -vendor xilinx.com -library ip -module_name xdma_0
set_property -dict $xdma_property [get_ips xdma_0]
