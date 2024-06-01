import lynxTypes::*;

module roce_stack_axis_to_aximm #(
  parameter int AXI4_DATA_WIDTH = 512
)(
  input  logic                          s_rdma_rd_req_valid_i,
  output logic                          s_rdma_rd_req_ready_o,
  input  logic  [63:0]                  s_rdma_rd_req_vaddr_i,
  input  logic  [27:0]                  s_rdma_rd_req_len_i,
  input  logic                          s_rdma_rd_req_ctl_i,

  input  logic                          s_rdma_wr_req_valid_i,
  output logic                          s_rdma_wr_req_ready_o,
  input  logic  [63:0]                  s_rdma_wr_req_vaddr_i,
  input  logic  [27:0]                  s_rdma_wr_req_len_i,
  input  logic                          s_rdma_wr_req_ctl_i,

  output logic  [AXI4_DATA_WIDTH-1:0]   m_axis_rdma_rd_tdata_o,
  output logic  [AXI4_DATA_WIDTH/8-1:0] m_axis_rdma_rd_tkeep_o,
  output logic                          m_axis_rdma_rd_tlast_o,
  output logic                          m_axis_rdma_rd_tvalid_o,
  input  logic                          m_axis_rdma_rd_tready_i,

  input  logic  [AXI4_DATA_WIDTH-1:0]   s_axis_rdma_wr_tdata_i,
  input  logic  [AXI4_DATA_WIDTH/8-1:0] s_axis_rdma_wr_tkeep_i,
  input  logic                          s_axis_rdma_wr_tlast_i,
  input  logic                          s_axis_rdma_wr_tvalid_i,
  output logic                          s_axis_rdma_wr_tready_o,

  output logic                          rd_req_addr_valid_o,
  input  logic                          rd_req_addr_ready_i,
  output logic  [63:0]                  rd_req_addr_vaddr_o,
  input  logic                          rd_resp_addr_valid_i,
  output logic                          rd_resp_addr_ready_o,
  input  logic  [115:0]                 rd_resp_addr_data_i,

  output logic                          wr_req_addr_valid_o,
  input  logic                          wr_req_addr_ready_i,
  output logic  [63:0]                  wr_req_addr_vaddr_o,
  input  logic                          wr_resp_addr_valid_i,
  output logic                          wr_resp_addr_ready_o,
  input  logic  [115:0]                 wr_resp_addr_data_i,

  output logic                          m_axi_data_bus_awid_o,
  output logic  [63:0]                  m_axi_data_bus_awaddr_o,
  output logic  [7:0]                   m_axi_data_bus_awlen_o,
  output logic  [2:0]                   m_axi_data_bus_awsize_o,
  output logic  [1:0]                   m_axi_data_bus_awburst_o,
  output logic  [3:0]                   m_axi_data_bus_awcache_o,
  output logic  [2:0]                   m_axi_data_bus_awprot_o,
  output logic                          m_axi_data_bus_awvalid_o,
  input  logic                          m_axi_data_bus_awready_i,
  output logic  [AXI4_DATA_WIDTH-1:0]   m_axi_data_bus_wdata_o,
  output logic  [63:0]                  m_axi_data_bus_wstrb_o,
  output logic                          m_axi_data_bus_wlast_o,
  output logic                          m_axi_data_bus_wvalid_o,
  input  logic                          m_axi_data_bus_wready_i,
  output logic                          m_axi_data_bus_awlock_o,
  input  logic                          m_axi_data_bus_bid_i,
  input  logic  [1:0]                   m_axi_data_bus_bresp_i,
  input  logic                          m_axi_data_bus_bvalid_i,
  output logic                          m_axi_data_bus_bready_o,

  output logic                          m_axi_data_bus_arid_o,
  output logic  [63:0]                  m_axi_data_bus_araddr_o,
  output logic  [7:0]                   m_axi_data_bus_arlen_o,
  output logic  [2:0]                   m_axi_data_bus_arsize_o,
  output logic  [1:0]                   m_axi_data_bus_arburst_o,
  output logic  [3:0]                   m_axi_data_bus_arcache_o,
  output logic  [2:0]                   m_axi_data_bus_arprot_o,
  output logic                          m_axi_data_bus_arvalid_o,
  input  logic                          m_axi_data_bus_arready_i,
  output logic                          m_axi_data_bus_arlock_o,
  input  logic                          m_axi_data_bus_rid_i,
  input  logic  [AXI4_DATA_WIDTH-1:0]   m_axi_data_bus_rdata_i,
  input  logic  [1:0]                   m_axi_data_bus_rresp_i,
  input  logic                          m_axi_data_bus_rlast_i,
  input  logic                          m_axi_data_bus_rvalid_i,
  output logic                          m_axi_data_bus_rready_o,

  input  logic                          axis_aclk_i,
  input  logic                          aresetn_i
);

logic [103:0] rd_mm2s_cmd_data, wr_s2mm_cmd_data;
logic rd_mm2s_cmd_valid, rd_mm2s_cmd_ready, wr_s2mm_cmd_valid, wr_s2mm_cmd_ready;

logic [7:0] s2mm_sts_data, mm2s_sts_data;
logic s2mm_sts_valid, s2mm_sts_last, s2mm_sts_keep, mm2s_sts_valid, mm2s_sts_last, mm2s_sts_keep;
logic s2mm_err, mm2s_err;


//READ REQUEST
roce_stack_request_handler #(
  .READ(1'b1)
) roce_stack_request_handler_read_inst (
    .s_rdma_req_valid_i(s_rdma_rd_req_valid_i),
    .s_rdma_req_ready_o(s_rdma_rd_req_ready_o),
    .s_rdma_req_vaddr_i(s_rdma_rd_req_vaddr_i),
    .s_rdma_req_len_i(s_rdma_rd_req_len_i),
    .s_rdma_req_ctl_i(s_rdma_rd_req_ctl_i),
    .req_addr_valid_o(rd_req_addr_valid_o),
    .req_addr_ready_i(rd_req_addr_ready_i),
    .req_addr_vaddr_o(rd_req_addr_vaddr_o),
    .resp_addr_valid_i(rd_resp_addr_valid_i),
    .resp_addr_ready_o(rd_resp_addr_ready_o),
    .resp_addr_data_i(rd_resp_addr_data_i),
    .cmd_valid_o(rd_mm2s_cmd_valid),
    .cmd_ready_i(rd_mm2s_cmd_ready),
    .cmd_data_o(rd_mm2s_cmd_data),
    .clk_i(axis_aclk_i),
    .aresetn_i(aresetn_i)
);


//WRITE REQUEST
roce_stack_request_handler #(
  .READ(1'b0)
) roce_stack_request_handler_write_inst (
    .s_rdma_req_valid_i(s_rdma_wr_req_valid_i),
    .s_rdma_req_ready_o(s_rdma_wr_req_ready_o),
    .s_rdma_req_vaddr_i(s_rdma_wr_req_vaddr_i),
    .s_rdma_req_len_i(s_rdma_wr_req_len_i),
    .s_rdma_req_ctl_i(s_rdma_wr_req_ctl_i),
    .req_addr_valid_o(wr_req_addr_valid_o),
    .req_addr_ready_i(wr_req_addr_ready_i),
    .req_addr_vaddr_o(wr_req_addr_vaddr_o),
    .resp_addr_valid_i(wr_resp_addr_valid_i),
    .resp_addr_ready_o(wr_resp_addr_ready_o),
    .resp_addr_data_i(wr_resp_addr_data_i),
    .cmd_valid_o(wr_s2mm_cmd_valid),
    .cmd_ready_i(wr_s2mm_cmd_ready),
    .cmd_data_o(wr_s2mm_cmd_data),
    .clk_i(axis_aclk_i),
    .aresetn_i(aresetn_i)
);


roce_stack_axi_data_mover roce_stack_axi_data_mover_inst (
  .s_axis_mm2s_cmd_tdata(rd_mm2s_cmd_data), 
  .s_axis_mm2s_cmd_tready(rd_mm2s_cmd_ready),
  .s_axis_mm2s_cmd_tvalid(rd_mm2s_cmd_valid),

  .s_axis_s2mm_cmd_tdata(wr_s2mm_cmd_data),
  .s_axis_s2mm_cmd_tready(wr_s2mm_cmd_ready),
  .s_axis_s2mm_cmd_tvalid(wr_s2mm_cmd_valid),

  .m_axis_s2mm_sts_tdata(s2mm_sts_data),
  .m_axis_s2mm_sts_tkeep(s2mm_sts_keep),
  .m_axis_s2mm_sts_tlast(s2mm_sts_last),
  .m_axis_s2mm_sts_tready(1'b1),
  .m_axis_s2mm_sts_tvalid(s2mm_sts_valid),

  .m_axis_mm2s_sts_tdata(mm2s_sts_data),
  .m_axis_mm2s_sts_tkeep(mm2s_sts_keep),
  .m_axis_mm2s_sts_tlast(mm2s_sts_last),
  .m_axis_mm2s_sts_tready(1'b1),
  .m_axis_mm2s_sts_tvalid(mm2s_sts_valid),

  .m_axis_mm2s_tdata(m_axis_rdma_rd_tdata_o),
  .m_axis_mm2s_tkeep(m_axis_rdma_rd_tkeep_o),
  .m_axis_mm2s_tlast(m_axis_rdma_rd_tlast_o),
  .m_axis_mm2s_tready(m_axis_rdma_rd_tready_i),
  .m_axis_mm2s_tvalid(m_axis_rdma_rd_tvalid_o),
  
  .s_axis_s2mm_tdata(s_axis_rdma_wr_tdata_i),
  .s_axis_s2mm_tkeep(s_axis_rdma_wr_tkeep_i),
  .s_axis_s2mm_tlast(s_axis_rdma_wr_tlast_i),
  .s_axis_s2mm_tready(s_axis_rdma_wr_tready_o),
  .s_axis_s2mm_tvalid(s_axis_rdma_wr_tvalid_i),

  .m_axi_s2mm_awaddr(m_axi_data_bus_awaddr_o),
  .m_axi_s2mm_awburst(m_axi_data_bus_awburst_o),
  .m_axi_s2mm_awcache(m_axi_data_bus_awcache_o),
  .m_axi_s2mm_awid(m_axi_data_bus_awid_o),
  .m_axi_s2mm_awlen(m_axi_data_bus_awlen_o),
  .m_axi_s2mm_awprot(m_axi_data_bus_awprot_o),
  .m_axi_s2mm_awready(m_axi_data_bus_awready_i),
  .m_axi_s2mm_awsize(m_axi_data_bus_awsize_o),
  .m_axi_s2mm_awuser(),
  .m_axi_s2mm_awvalid(m_axi_data_bus_awvalid_o),
  .m_axi_s2mm_bready(m_axi_data_bus_bready_o),
  .m_axi_s2mm_bresp(m_axi_data_bus_bresp_i),
  .m_axi_s2mm_bvalid(m_axi_data_bus_bvalid_i),
  .m_axi_s2mm_wdata(m_axi_data_bus_wdata_o),
  .m_axi_s2mm_wlast(m_axi_data_bus_wlast_o),
  .m_axi_s2mm_wready(m_axi_data_bus_wready_i),
  .m_axi_s2mm_wstrb(m_axi_data_bus_wstrb_o),
  .m_axi_s2mm_wvalid(m_axi_data_bus_wvalid_o),
  
  .m_axi_mm2s_araddr(m_axi_data_bus_araddr_o),
  .m_axi_mm2s_arburst(m_axi_data_bus_arburst_o),
  .m_axi_mm2s_arcache(m_axi_data_bus_arcache_o),
  .m_axi_mm2s_arid(m_axi_data_bus_arid_o),
  .m_axi_mm2s_arlen(m_axi_data_bus_arlen_o),
  .m_axi_mm2s_arprot(m_axi_data_bus_arprot_o),
  .m_axi_mm2s_arready(m_axi_data_bus_arready_i),
  .m_axi_mm2s_arsize(m_axi_data_bus_arsize_o),
  .m_axi_mm2s_aruser(),
  .m_axi_mm2s_arvalid(m_axi_data_bus_arvalid_o),
  .m_axi_mm2s_rdata(m_axi_data_bus_rdata_i),
  .m_axi_mm2s_rlast(m_axi_data_bus_rlast_i),
  .m_axi_mm2s_rready(m_axi_data_bus_rready_o),
  .m_axi_mm2s_rresp(m_axi_data_bus_rresp_i),
  .m_axi_mm2s_rvalid(m_axi_data_bus_rvalid_i),
  
  .m_axi_mm2s_aclk(axis_aclk_i),
  .m_axi_mm2s_aresetn(arestn_i),
  .m_axis_mm2s_cmdsts_aclk(axis_aclk_i),
  .m_axis_mm2s_cmdsts_aresetn(arestn_i),
  .m_axi_s2mm_aclk(axis_aclk_i),
  .m_axi_s2mm_aresetn(arestn_i),
  .m_axis_s2mm_cmdsts_awclk(axis_aclk_i),
  .m_axis_s2mm_cmdsts_aresetn(arestn_i),
  
  .s2mm_err(s2mm_err),
  .mm2s_err(mm2s_err)

);





endmodule: roce_stack_axis_to_aximm