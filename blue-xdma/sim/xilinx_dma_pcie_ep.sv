`timescale 1ps / 1ps
module xilinx_dma_pcie_ep #(
    parameter PL_LINK_CAP_MAX_LINK_WIDTH = 8,  // 1- X1; 2 - X2; 4 - X4; 8 - X8
    parameter C_DATA_WIDTH = 64,
    parameter AXIS_CCIX_RX_TDATA_WIDTH = 256,
    parameter AXIS_CCIX_TX_TDATA_WIDTH = 256,
    parameter AXIS_CCIX_RX_TUSER_WIDTH = 46,
    parameter AXIS_CCIX_TX_TUSER_WIDTH = 46,
    parameter C_S_AXI_ID_WIDTH = 4,
    parameter C_M_AXI_ID_WIDTH = 4,
    parameter C_S_AXI_DATA_WIDTH = C_DATA_WIDTH,
    parameter C_M_AXI_DATA_WIDTH = C_DATA_WIDTH,
    parameter C_S_AXI_ADDR_WIDTH = 64,
    parameter C_M_AXI_ADDR_WIDTH = 64,
    parameter C_NUM_USR_IRQ = 1
  ) (
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txp,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txn,
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxp,
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_rxn,
    input sys_clk_p,
    input sys_clk_n,
    input sys_rst_n
  );

  wire                              user_clk;
  wire                              user_resetn;
  wire                              sys_clk;
  wire                              sys_clk_gt;
  wire                              sys_rst_n_c;
  reg  [         C_NUM_USR_IRQ-1:0] usr_irq_req;
  wire [         C_NUM_USR_IRQ-1:0] usr_irq_ack;
  wire [    C_M_AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
  wire [      C_M_AXI_ID_WIDTH-1:0] m_axi_awid;
  wire [                       2:0] m_axi_awprot;
  wire [                       1:0] m_axi_awburst;
  wire [                       2:0] m_axi_awsize;
  wire [                       3:0] m_axi_awcache;
  wire [                       7:0] m_axi_awlen;
  wire                              m_axi_awlock;
  wire                              m_axi_awvalid;
  wire                              m_axi_awready;
  wire [    C_M_AXI_DATA_WIDTH-1:0] m_axi_wdata;
  wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb;
  wire                              m_axi_wlast;
  wire                              m_axi_wvalid;
  wire                              m_axi_wready;
  wire                              m_axi_bvalid;
  wire                              m_axi_bready;
  wire [    C_M_AXI_ID_WIDTH-1 : 0] m_axi_bid;
  wire [                       1:0] m_axi_bresp;
  wire [    C_M_AXI_ID_WIDTH-1 : 0] m_axi_arid;
  wire [    C_M_AXI_ADDR_WIDTH-1:0] m_axi_araddr;
  wire [                       7:0] m_axi_arlen;
  wire [                       2:0] m_axi_arsize;
  wire [                       1:0] m_axi_arburst;
  wire [                       2:0] m_axi_arprot;
  wire                              m_axi_arvalid;
  wire                              m_axi_arready;
  wire                              m_axi_arlock;
  wire [                       3:0] m_axi_arcache;
  wire [    C_M_AXI_ID_WIDTH-1 : 0] m_axi_rid;
  wire [    C_M_AXI_DATA_WIDTH-1:0] m_axi_rdata;
  wire [                       1:0] m_axi_rresp;
  wire                              m_axi_rvalid;
  wire                              m_axi_rready;
  wire [                      31:0] s_axil_awaddr;
  wire [                       2:0] s_axil_awprot;
  wire                              s_axil_awvalid;
  wire                              s_axil_awready;
  wire [                      31:0] s_axil_wdata;
  wire [                       3:0] s_axil_wstrb;
  wire                              s_axil_wvalid;
  wire                              s_axil_wready;
  wire                              s_axil_bvalid;
  wire                              s_axil_bready;
  wire [                      31:0] s_axil_araddr;
  wire [                       2:0] s_axil_arprot;
  wire                              s_axil_arvalid;
  wire                              s_axil_arready;
  wire [                      31:0] s_axil_rdata;
  wire [                       1:0] s_axil_rresp;
  wire                              s_axil_rvalid;
  wire                              s_axil_rready;
  wire [                       1:0] s_axil_bresp;
  wire [                       2:0] msi_vector_width;
  wire                              msi_enable;
  wire [                       3:0] leds;
  wire                              free_run_clock;
  wire [                       5:0] cfg_ltssm_state;
  wire                              soft_reset_n;
  wire                              c2h_dsc_byp_load_0;
  wire [                    63 : 0] c2h_dsc_byp_src_addr_0;
  wire [                    63 : 0] c2h_dsc_byp_dst_addr_0;
  wire [                    27 : 0] c2h_dsc_byp_len_0;
  wire [                    15 : 0] c2h_dsc_byp_ctl_0;
  wire                              c2h_dsc_byp_ready_0;
  wire                              h2c_dsc_byp_load_0;
  wire [                    63 : 0] h2c_dsc_byp_src_addr_0;
  wire [                    63 : 0] h2c_dsc_byp_dst_addr_0;
  wire [                    27 : 0] h2c_dsc_byp_len_0;
  wire [                    15 : 0] h2c_dsc_byp_ctl_0;
  wire                              h2c_dsc_byp_ready_0;


  // This module is used to buffer and invert a differential clock signal.
  // The module has several input and output ports, including
  // the differential input ports I and IB,
  // the differential output ports O and ODIV2.
  // The module selects the primary reference clock source.
  IBUFDS_GTE4 #(
                .REFCLK_HROW_CK_SEL(2'b00)
              ) refclk_ibuf (
                .O(sys_clk_gt),
                .ODIV2(sys_clk),
                .I(sys_clk_p),
                .CEB(1'b0),
                .IB(sys_clk_n)
              );

  // This module is used to buffer a single-ended input signal.
  // The module has two ports, the input port I and the output port O.
  // The input port I is connected to the sys_rst_n signal,
  // and the output port O is connected to the sys_rst_n_c signal.
  // The IBUF module is commonly used in FPGA designs to buffer input signals and
  // ensure that they meet the timing requirements of the design.
  IBUF sys_reset_n_ibuf (
         .O(sys_rst_n_c),
         .I(sys_rst_n)
       );

  xdma xdma_i (
         .sys_rst_n(sys_rst_n_c),
         .sys_clk(sys_clk),
         .sys_clk_gt(sys_clk_gt),
         .pci_exp_txn(pci_exp_txn),
         .pci_exp_txp(pci_exp_txp),
         .pci_exp_rxn(pci_exp_rxn),
         .pci_exp_rxp(pci_exp_rxp),
         .m_axi_awid(m_axi_awid),
         .m_axi_awaddr(m_axi_awaddr),
         .m_axi_awlen(m_axi_awlen),
         .m_axi_awsize(m_axi_awsize),
         .m_axi_awburst(m_axi_awburst),
         .m_axi_awprot(m_axi_awprot),
         .m_axi_awvalid(m_axi_awvalid),
         .m_axi_awready(m_axi_awready),
         .m_axi_awlock(m_axi_awlock),
         .m_axi_awcache(m_axi_awcache),
         .m_axi_wdata(m_axi_wdata),
         .m_axi_wstrb(m_axi_wstrb),
         .m_axi_wlast(m_axi_wlast),
         .m_axi_wvalid(m_axi_wvalid),
         .m_axi_wready(m_axi_wready),
         .m_axi_bid(m_axi_bid),
         .m_axi_bresp(m_axi_bresp),
         .m_axi_bvalid(m_axi_bvalid),
         .m_axi_bready(m_axi_bready),
         .m_axi_arid(m_axi_arid),
         .m_axi_araddr(m_axi_araddr),
         .m_axi_arlen(m_axi_arlen),
         .m_axi_arsize(m_axi_arsize),
         .m_axi_arburst(m_axi_arburst),
         .m_axi_arprot(m_axi_arprot),
         .m_axi_arvalid(m_axi_arvalid),
         .m_axi_arready(m_axi_arready),
         .m_axi_arlock(m_axi_arlock),
         .m_axi_arcache(m_axi_arcache),
         .m_axi_rid(m_axi_rid),
         .m_axi_rdata(m_axi_rdata),
         .m_axi_rresp(m_axi_rresp),
         .m_axi_rlast(m_axi_rlast),
         .m_axi_rvalid(m_axi_rvalid),
         .m_axi_rready(m_axi_rready),
         .s_axil_awaddr(s_axil_awaddr),
         .s_axil_awprot(s_axil_awprot),
         .s_axil_awvalid(s_axil_awvalid),
         .s_axil_awready(s_axil_awready),
         .s_axil_wdata(s_axil_wdata),
         .s_axil_wstrb(s_axil_wstrb),
         .s_axil_wvalid(s_axil_wvalid),
         .s_axil_wready(s_axil_wready),
         .s_axil_bvalid(s_axil_bvalid),
         .s_axil_bresp(s_axil_bresp),
         .s_axil_bready(s_axil_bready),
         .s_axil_araddr(s_axil_araddr),
         .s_axil_arprot(s_axil_arprot),
         .s_axil_arvalid(s_axil_arvalid),
         .s_axil_arready(s_axil_arready),
         .s_axil_rdata(s_axil_rdata),
         .s_axil_rresp(s_axil_rresp),
         .s_axil_rvalid(s_axil_rvalid),
         .s_axil_rready(s_axil_rready),
         .c2h_dsc_byp_ready_0(c2h_dsc_byp_ready_0),
         .c2h_dsc_byp_src_addr_0(c2h_dsc_byp_src_addr_0),
         .c2h_dsc_byp_dst_addr_0(c2h_dsc_byp_dst_addr_0),
         .c2h_dsc_byp_len_0(c2h_dsc_byp_len_0),
         .c2h_dsc_byp_ctl_0(c2h_dsc_byp_ctl_0),
         .c2h_dsc_byp_load_0(c2h_dsc_byp_load_0),
         .h2c_dsc_byp_ready_0(h2c_dsc_byp_ready_0),
         .h2c_dsc_byp_src_addr_0(h2c_dsc_byp_src_addr_0),
         .h2c_dsc_byp_dst_addr_0(h2c_dsc_byp_dst_addr_0),
         .h2c_dsc_byp_len_0(h2c_dsc_byp_len_0),
         .h2c_dsc_byp_ctl_0(h2c_dsc_byp_ctl_0),
         .h2c_dsc_byp_load_0(h2c_dsc_byp_load_0),
         .usr_irq_req(usr_irq_req),
         .usr_irq_ack(usr_irq_ack),
         .msi_enable(msi_enable),
         .msi_vector_width(msi_vector_width),
         .cfg_mgmt_addr(19'b0),
         .cfg_mgmt_write(1'b0),
         .cfg_mgmt_write_data(32'b0),
         .cfg_mgmt_byte_enable(4'b0),
         .cfg_mgmt_read(1'b0),
         .cfg_mgmt_read_data(),
         .cfg_mgmt_read_write_done(),
         .axi_aclk(user_clk),
         .axi_aresetn(user_resetn),
         .user_lnk_up(user_lnk_up)
       );

  mkXdmaTestbench mkXdmaTestbench_i (
                    .axi_aclk(user_clk),
                    .axi_aresetn(user_resetn),
                    .m_axil_awready(s_axil_awready),
                    .m_axil_awvalid(s_axil_awvalid),
                    .m_axil_awaddr(s_axil_awaddr),
                    .m_axil_awprot(s_axil_awprot),
                    .m_axil_wready(s_axil_wready),
                    .m_axil_wvalid(s_axil_wvalid),
                    .m_axil_wdata(s_axil_wdata),
                    .m_axil_wstrb(s_axil_wstrb),
                    .m_axil_bvalid(s_axil_bvalid),
                    .m_axil_bready(s_axil_bready),
                    .m_axil_bresp(s_axil_bresp),
                    .m_axil_arvalid(s_axil_arvalid),
                    .m_axil_arready(s_axil_arready),
                    .m_axil_araddr(s_axil_araddr),
                    .m_axil_arprot(s_axil_arprot),
                    .m_axil_rready(s_axil_rready),
                    .m_axil_rvalid(s_axil_rvalid),
                    .m_axil_rdata(s_axil_rdata),
                    .m_axil_rresp(s_axil_rresp),
                    .s_axi_awready(m_axi_awready),
                    .s_axi_awvalid(m_axi_awvalid),
                    .s_axi_awid(m_axi_awid),
                    .s_axi_awaddr(m_axi_awaddr),
                    .s_axi_awlen(m_axi_awlen),
                    .s_axi_awsize(m_axi_awsize),
                    .s_axi_awburst(m_axi_awburst),
                    .s_axi_awlock(m_axi_awlock),
                    .s_axi_awcache(m_axi_awcache),
                    .s_axi_awprot(m_axi_awprot),
                    .s_axi_wready(m_axi_wready),
                    .s_axi_wvalid(m_axi_wvalid),
                    .s_axi_wdata(m_axi_wdata),
                    .s_axi_wstrb(m_axi_wstrb),
                    .s_axi_wlast(m_axi_wlast),
                    .s_axi_bready(m_axi_bready),
                    .s_axi_bvalid(m_axi_bvalid),
                    .s_axi_bresp(m_axi_bresp),
                    .s_axi_bid(m_axi_bid),
                    .s_axi_arvalid(m_axi_arvalid),
                    .s_axi_arready(m_axi_arready),
                    .s_axi_arid(m_axi_arid),
                    .s_axi_araddr(m_axi_araddr),
                    .s_axi_arlen(m_axi_arlen),
                    .s_axi_arsize(m_axi_arsize),
                    .s_axi_arburst(m_axi_arburst),
                    .s_axi_arlock(m_axi_arlock),
                    .s_axi_arcache(m_axi_arcache),
                    .s_axi_arprot(m_axi_arprot),
                    .s_axi_rready(m_axi_rready),
                    .s_axi_rvalid(m_axi_rvalid),
                    .s_axi_rid(m_axi_rid),
                    .s_axi_rdata(m_axi_rdata),
                    .s_axi_rresp(m_axi_rresp),
                    .s_axi_rlast(m_axi_rlast),
                    .c2h_dsc_byp_load(c2h_dsc_byp_load_0),
                    .c2h_dsc_byp_src_addr(c2h_dsc_byp_src_addr_0),
                    .c2h_dsc_byp_dst_addr(c2h_dsc_byp_dst_addr_0),
                    .c2h_dsc_byp_len(c2h_dsc_byp_len_0),
                    .c2h_dsc_byp_ctl(c2h_dsc_byp_ctl_0),
                    .c2h_dsc_byp_ready(c2h_dsc_byp_ready_0),
                    .h2c_dsc_byp_load(h2c_dsc_byp_load_0),
                    .h2c_dsc_byp_src_addr(h2c_dsc_byp_src_addr_0),
                    .h2c_dsc_byp_dst_addr(h2c_dsc_byp_dst_addr_0),
                    .h2c_dsc_byp_len(h2c_dsc_byp_len_0),
                    .h2c_dsc_byp_ctl(h2c_dsc_byp_ctl_0),
                    .h2c_dsc_byp_ready(h2c_dsc_byp_ready_0)
                  );

  always @(negedge sys_rst_n_c)
  begin
    if (~sys_rst_n_c)
    begin
      usr_irq_req <= 0;
    end
  end

endmodule
