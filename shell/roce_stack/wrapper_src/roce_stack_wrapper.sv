
import lynxTypes::*;

module roce_stack_wrapper # (
  parameter int NUM_QP = 8, //min: 8, max: 256
  parameter int AXIL_ADDR_WIDTH = 32,
  parameter int AXIL_DATA_WIDTH = 32,
  parameter int AXI4S_DATA_WIDTH = 512
)(
  //AXI Lite configuration registers 
  input logic                           s_axil_awvalid_i,
  input logic   [AXIL_ADDR_WIDTH-1:0]   s_axil_awaddr_i,
  output logic                          s_axil_awready_o,
  input logic                           s_axil_wvalid_i,
  input logic   [AXIL_DATA_WIDTH-1:0]   s_axil_wdata_i,
  input logic   [AXIL_ADDR_WIDTH/8-1:0] s_axil_wstrb_i,
  output logic                          s_axil_wready_o,
  output logic                          s_axil_bvalid_o,
  output logic  [1:0]                   s_axil_bresp_o,
  input logic                           s_axil_bready_i,
  input logic                           s_axil_arvalid_i,
  input logic   [AXIL_ADDR_WIDTH-1:0]   s_axil_araddr_i,
  output logic                          s_axil_arready_o,
  output logic                          s_axil_rvalid_o,
  output logic  [AXIL_DATA_WIDTH-1:0]   s_axil_rdata_o,
  output logic  [1:0]                   s_axil_rresp_o,
  input logic                           s_axil_rready_i,

  // RDMA TX interface (including roce and non-roce packets) to CMAC TX path
  output logic  [511:0]                 m_rdma2cmac_axis_tdata_o,
  output logic  [63:0]                  m_rdma2cmac_axis_tkeep_o,
  output logic                          m_rdma2cmac_axis_tvalid_o,
  output logic                          m_rdma2cmac_axis_tlast_o,
  input logic                           m_rdma2cmac_axis_tready_i,

    // Non-RDMA packets from QDMA TX bypassing RDMA TX
  input logic   [511:0]                 s_qdma2rdma_non_roce_axis_tdata_i,
  input logic   [63:0]                  s_qdma2rdma_non_roce_axis_tkeep_i,
  input logic                           s_qdma2rdma_non_roce_axis_tvalid_i,
  input logic                           s_qdma2rdma_non_roce_axis_tlast_i,
  output logic                          s_qdma2rdma_non_roce_axis_tready_o,

  // RDMA RX interface from CMAC RX, no rx backpressure
  input logic   [511:0]                 s_cmac2rdma_roce_axis_tdata_i,
  input logic   [63:0]                  s_cmac2rdma_roce_axis_tkeep_i,
  input logic                           s_cmac2rdma_roce_axis_tvalid_i,
  input logic                           s_cmac2rdma_roce_axis_tlast_i,
  input logic                           s_cmac2rdma_roce_axis_tuser_i,

  //AXI Master to fetch WQEs
  output logic                          m_axi_qp_get_wqe_awid_o,
  output logic  [63:0]                  m_axi_qp_get_wqe_awaddr_o,
  output logic   [7:0]                  m_axi_qp_get_wqe_awlen_o,
  output logic   [2:0]                  m_axi_qp_get_wqe_awsize_o,
  output logic   [1:0]                  m_axi_qp_get_wqe_awburst_o,
  output logic   [3:0]                  m_axi_qp_get_wqe_awcache_o,
  output logic   [2:0]                  m_axi_qp_get_wqe_awprot_o,
  output logic                          m_axi_qp_get_wqe_awvalid_o,
  input  logic                          m_axi_qp_get_wqe_awready_i,
  output logic [511:0]                  m_axi_qp_get_wqe_wdata_o,
  output logic  [63:0]                  m_axi_qp_get_wqe_wstrb_o,
  output logic                          m_axi_qp_get_wqe_wlast_o,
  output logic                          m_axi_qp_get_wqe_wvalid_o,
  input  logic                          m_axi_qp_get_wqe_wready_i,
  output logic                          m_axi_qp_get_wqe_awlock_o,
  input  logic                          m_axi_qp_get_wqe_bid_i,
  input  logic   [1:0]                  m_axi_qp_get_wqe_bresp_i,
  input  logic                          m_axi_qp_get_wqe_bvalid_i,
  output logic                          m_axi_qp_get_wqe_bready_o,
  output logic                          m_axi_qp_get_wqe_arid_o,
  output logic  [63:0]                  m_axi_qp_get_wqe_araddr_o,
  output logic   [7:0]                  m_axi_qp_get_wqe_arlen_o,
  output logic   [2:0]                  m_axi_qp_get_wqe_arsize_o,
  output logic   [1:0]                  m_axi_qp_get_wqe_arburst_o,
  output logic   [3:0]                  m_axi_qp_get_wqe_arcache_o,
  output logic   [2:0]                  m_axi_qp_get_wqe_arprot_o,
  output logic                          m_axi_qp_get_wqe_arvalid_o,
  input  logic                          m_axi_qp_get_wqe_arready_i,
  output logic                          m_axi_qp_get_wqe_arlock_o,
  input  logic                          m_axi_qp_get_wqe_rid_i,
  input  logic [511:0]                  m_axi_qp_get_wqe_rdata_i,
  input  logic   [1:0]                  m_axi_qp_get_wqe_rresp_i,
  input  logic                          m_axi_qp_get_wqe_rlast_i,
  input  logic                          m_axi_qp_get_wqe_rvalid_i,
  output logic                          m_axi_qp_get_wqe_rready_o,

  //AXI Master memory interface
  output logic                          m_axi_data_bus_awid_o,
  output logic  [63:0]                  m_axi_data_bus_awaddr_o,
  output logic   [7:0]                  m_axi_data_bus_awlen_o,
  output logic   [2:0]                  m_axi_data_bus_awsize_o,
  output logic   [1:0]                  m_axi_data_bus_awburst_o,
  output logic   [3:0]                  m_axi_data_bus_awcache_o,
  output logic   [2:0]                  m_axi_data_bus_awprot_o,
  output logic                          m_axi_data_bus_awvalid_o,
  input  logic                          m_axi_data_bus_awready_i,
  output logic [511:0]                  m_axi_data_bus_wdata_o,
  output logic  [63:0]                  m_axi_data_bus_wstrb_o,
  output logic                          m_axi_data_bus_wlast_o,
  output logic                          m_axi_data_bus_wvalid_o,
  input  logic                          m_axi_data_bus_wready_i,
  output logic                          m_axi_data_bus_awlock_o,
  input  logic                          m_axi_data_bus_bid_i,
  input  logic   [1:0]                  m_axi_data_bus_bresp_i,
  input  logic                          m_axi_data_bus_bvalid_i,
  output logic                          m_axi_data_bus_bready_o,
  output logic                          m_axi_data_bus_arid_o,
  output logic  [63:0]                  m_axi_data_bus_araddr_o,
  output logic   [7:0]                  m_axi_data_bus_arlen_o,
  output logic   [2:0]                  m_axi_data_bus_arsize_o,
  output logic   [1:0]                  m_axi_data_bus_arburst_o,
  output logic   [3:0]                  m_axi_data_bus_arcache_o,
  output logic   [2:0]                  m_axi_data_bus_arprot_o,
  output logic                          m_axi_data_bus_arvalid_o,
  input  logic                          m_axi_data_bus_arready_i,
  output logic                          m_axi_data_bus_arlock_o,
  input  logic                          m_axi_data_bus_rid_i,
  input  logic [511:0]                  m_axi_data_bus_rdata_i,
  input  logic   [1:0]                  m_axi_data_bus_rresp_i,
  input  logic                          m_axi_data_bus_rlast_i,
  input  logic                          m_axi_data_bus_rvalid_i,
  output logic                          m_axi_data_bus_rready_o,

  input logic                           axil_aclk_i,
  input logic                           axis_aclk_i,
  input logic                           mod_rstn_i
);

logic [7:0] wr_ptr_wtc;

logic [31:0]  IPv4ADD;
logic [31:0]  IPv4ADD_net;

logic [7:0]   connidx, QPidx;  
logic         conn_configured, qp_configured;

logic [31:0]  CONF;
logic [47:0]  MACADD;

logic [31:0]  QPCONFi;
logic [31:0]  QPADVCONFi;
logic [63:0]  RQBAi;
logic [63:0]  SQBAi;
logic [63:0]  CQBAi;
logic [63:0]  RQWPTRDBADDi;
logic [63:0]  CQDBADDi;
logic [31:0]  SQPIi;
logic [31:0]  CQHEADi_wtc;
logic [31:0]  CQHEADi_ctw;
logic [31:0]  QDEPTHi;
logic [23:0]  SQPSNi;
logic [31:0]  LSTRQREQi;
logic [23:0]  DESTQPCONFi;
logic [47:0]  MACDESADDi;
logic [31:0]  IPDESADDR1i;
logic [31:0]  IPDESADDR1i_net;

logic [63:0] VIRTADDRi;


//TODO: interface definitions for axi4s??
metaIntf #(.STYPE(req_t)) rdma_rd_req ();
metaIntf #(.STYPE(req_t)) rdma_wr_req ();

metaIntf #(.STYPE(logic[183:0])) rdma_conn_interface();
metaIntf #(.STYPE(logic[199:0])) rdma_qp_interface();
metaIntf #(.STYPE(rdma_req_t)) rdma_sq();
metaIntf #(.STYPE(rdma_ack_t)) rdma_ack();

AXI4S #(.AXI4S_DATA_BITS(AXI4S_DATA_WIDTH)) axis_rdma_rd ();
AXI4S #(.AXI4S_DATA_BITS(AXI4S_DATA_WIDTH)) axis_rdma_wr ();
AXI4S #(.AXI4S_DATA_BITS(512)) axis_tx ();
AXI4S #(.AXI4S_DATA_BITS(512)) axis_rx ();


//address requests
logic rd_req_addr_valid, rd_req_addr_ready, wr_req_addr_valid, wr_req_addr_ready;
logic [63:0] rd_req_addr_vaddr, wr_req_addr_vaddr;
//address response
logic rd_resp_addr_valid, rd_resp_addr_ready, wr_resp_addr_valid, wr_resp_addr_ready;
logic [115:0] rd_resp_addr_data, wr_resp_addr_data;

//tx interface from roce stack
logic axis_tx_tvalid, axis_tx_tready, axis_tx_tlast;
logic [511:0] axis_tx_tdata;
logic [63:0] axis_tx_tkeep;

//rx interface to roce stack
assign axis_rx.tdata = s_cmac2rdma_roce_axis_tdata_i;
assign axis_rx.tkeep = s_cmac2rdma_roce_axis_tkeep_i;
assign axis_rx.tvalid = s_cmac2rdma_roce_axis_tvalid_i;
assign axis_rx.tlast = s_cmac2rdma_roce_axis_tlast_i;

//tx interface from roce stack
assign m_rdma2cmac_axis_tvalid_o = axis_tx.tvalid;
assign axis_tx.tready = m_rdma2cmac_axis_tready_i;
assign m_rdma2cmac_axis_tlast_o = axis_tx.tlast;
assign m_rdma2cmac_axis_tdata_o = axis_tx.tdata;
assign m_rdma2cmac_axis_tkeep_o = axis_tx.tkeep;


/*
//tx interface from roce stack
assign axis_tx_tvalid = axis_tx.tvalid;
assign axis_tx.tready = axis_tx_tready;
assign axis_tx_tlast = axis_tx.tlast;
assign axis_tx_tdata = axis_tx.tdata;
assign axis_tx_tkeep = axis_tx.tkeep;

roce_stack_tx_axis_interconnect roce_stack_tx_axis_interconnect_inst (
  .S00_AXIS_TDATA(axis_tx_tdata),
  .S00_AXIS_TKEEP(axis_tx_tkeep),
  .S00_AXIS_TLAST(axis_tx_tlast),
  .S00_AXIS_TREADY(axis_tx_tready),
  .S00_AXIS_TVALID(axis_tx_tvalid),

  .S01_AXIS_TDATA(s_qdma2rdma_non_roce_axis_tdata_i),
  .S01_AXIS_TKEEP(s_qdma2rdma_non_roce_axis_tkeep_i),
  .S01_AXIS_TLAST(s_qdma2rdma_non_roce_axis_tlast_i),
  .S01_AXIS_TREADY(s_qdma2rdma_non_roce_axis_tready_o),
  .S01_AXIS_TVALID(s_qdma2rdma_non_roce_axis_tvalid_i),

  .M00_AXIS_TDATA(m_rdma2cmac_axis_tdata_o),
  .M00_AXIS_TKEEP(m_rdma2cmac_axis_tkeep_o),
  .M00_AXIS_TLAST(m_rdma2cmac_axis_tlast_o),
  .M00_AXIS_TREADY(m_rdma2cmac_axis_tready_i),
  .M00_AXIS_TVALID(m_rdma2cmac_axis_tvalid_o),

  .S00_ARB_REQ_SUPPRESS(1'b0), //TODO: what is that?
  .S01_ARB_REQ_SUPPRESS(1'b0),

  .ACLK(axis_aclk_i),
  .S00_AXIS_ACLK(axis_aclk_i),
  .S01_AXIS_ACLK(axis_aclk_i),
  .M00_AXIS_ACLK(axis_aclk_i),
  
  .ARESETN(mod_rstn_i),
  .S00_AXIS_ARESETN(mod_rstn_i),
  .S01_AXIS_ARESETN(mod_rstn_i),
  .M00_AXIS_ARESETN(mod_rstn_i)
);
*/

roce_stack_csr #(
  .NUM_QP(NUM_QP),
  .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
  .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH)
) inst_roce_stack_csr(
  .s_axil_awvalid_i(s_axil_awvalid_i),
  .s_axil_awaddr_i(s_axil_awaddr_i),
  .s_axil_awready_o(s_axil_awready_o),
  .s_axil_wvalid_i(s_axil_wvalid_i),
  .s_axil_wdata_i(s_axil_wdata_i),
  .s_axil_wstrb_i(s_axil_wstrb_i),
  .s_axil_wready_o(s_axil_wready_o),
  .s_axil_bvalid_o(s_axil_bvalid_o),
  .s_axil_bresp_o(s_axil_bresp_o),
  .s_axil_bready_i(s_axil_bready_i),
  .s_axil_arvalid_i(s_axil_arvalid_i),
  .s_axil_araddr_i(s_axil_araddr_i),
  .s_axil_arready_o(s_axil_arready_o),
  .s_axil_rvalid_o(s_axil_rvalid_o),
  .s_axil_rdata_o(s_axil_rdata_o),
  .s_axil_rresp_o(s_axil_rresp_o),
  .s_axil_rready_i(s_axil_rready_i),
  
  .VIRTADDR_o(VIRTADDRi),

  .CONF_o(CONF),
  .MACADD_o(MACADD),

  .IPv4ADD_o(IPv4ADD),
  .QPidx_o(QPidx),
  .connidx_o(connidx),
  .conn_configured_o(conn_configured),
  .qp_configured_o(qp_configured),
  


  .QPCONFi_o(QPCONFi),
  .QPADVCONFi_o(),
  .RQBAi_o(),
  .SQBAi_o(SQBAi),
  .CQBAi_o(),
  .RQWPTRDBADDi_o(),
  .CQDBADDi_o(),
  .SQPIi_o(SQPIi),
  .CQHEADi_i(CQHEADi_wtc),
  .CQHEADi_o(CQHEADi_ctw),
  .QDEPTHi_o(),
  .SQPSNi_o(SQPSNi),
  .LSTRQREQi_o(LSTRQREQi),
  .DESTQPCONFi_o(DESTQPCONFi),
  .MACDESADDi_o(MACDESADDi),
  .IPDESADDR1i_o(IPDESADDR1i),

  .rd_req_addr_valid_i(rd_req_addr_valid),
  .rd_req_addr_ready_o(rd_req_addr_ready),
  .rd_req_addr_vaddr_i(rd_req_addr_vaddr),
  .rd_resp_addr_valid_o(rd_resp_addr_valid),
  .rd_resp_addr_ready_i(rd_resp_addr_ready),
  .rd_resp_addr_data_o(rd_resp_addr_data),

  .wr_req_addr_valid_i(wr_req_addr_valid),
  .wr_req_addr_ready_o(wr_req_addr_ready),
  .wr_req_addr_vaddr_i(wr_req_addr_vaddr),
  .wr_resp_addr_valid_o(wr_resp_addr_valid),
  .wr_resp_addr_ready_i(wr_resp_addr_ready),
  .wr_resp_addr_data_o(wr_resp_addr_data),




  .axis_aclk_i(axis_aclk_i),
  .axil_aclk_i(axil_aclk_i),
  .rstn_i(mod_rstn_i)
);


//TODO: finish this!
roce_stack_wq_manager #(
  .NUM_QP(NUM_QP)
)inst_roce_stack_wq_manager(
  .QPidx_i(QPidx),
  .connidx_i(connidx),
  .conn_configured_i(conn_configured),
  .qp_configured_i(qp_configured),

  .CONF_i(CONF),

  .QPCONFi_i(QPCONFi),
  .DESTQPCONFi_i(DESTQPCONFi),
  .IPDESADDR1i_i(IPDESADDR1i_net),
  .SQPSNi_i(SQPSNi),
  .CQHEADi_i(CQHEADi_ctw),
  .LSTRQREQi_i(LSTRQREQi),

  .SQBAi_i(SQBAi),
  .SQPIi_i(SQPIi),
  .VIRTADDR_i(VIRTADDRi),
    
  .wr_ptr_o(wr_ptr_wtc),
  .CQHEADi_o(CQHEADi_wtc),

  .m_rdma_conn_interface_valid_o(rdma_conn_interface.valid), 
  .m_rdma_conn_interface_ready_i(rdma_conn_interface.ready),
  .m_rdma_conn_interface_data_o(rdma_conn_interface.data),

  .m_rdma_qp_interface_valid_o(rdma_qp_interface.valid), 
  .m_rdma_qp_interface_ready_i(rdma_qp_interface.ready),
  .m_rdma_qp_interface_data_o(rdma_qp_interface.data),
    
  .m_rdma_sq_interface_valid_o(rdma_sq.valid),
  .m_rdma_sq_interface_ready_i(rdma_sq.ready),
  .m_rdma_sq_interface_data_o(rdma_sq.data),

  .m_axi_qp_get_wqe_awid_o(m_axi_qp_get_wqe_awid_o),
  .m_axi_qp_get_wqe_awaddr_o(m_axi_qp_get_wqe_awaddr_o),
  .m_axi_qp_get_wqe_awlen_o(m_axi_qp_get_wqe_awlen_o),
  .m_axi_qp_get_wqe_awsize_o(m_axi_qp_get_wqe_awsize_o),
  .m_axi_qp_get_wqe_awburst_o(m_axi_qp_get_wqe_awburst_o),
  .m_axi_qp_get_wqe_awcache_o(m_axi_qp_get_wqe_awcache_o),
  .m_axi_qp_get_wqe_awprot_o(m_axi_qp_get_wqe_awprot_o),
  .m_axi_qp_get_wqe_awvalid_o(m_axi_qp_get_wqe_awvalid_o),
  .m_axi_qp_get_wqe_awready_i(m_axi_qp_get_wqe_awready_i),
  .m_axi_qp_get_wqe_wdata_o(m_axi_qp_get_wqe_wdata_o),
  .m_axi_qp_get_wqe_wstrb_o(m_axi_qp_get_wqe_wstrb_o),
  .m_axi_qp_get_wqe_wlast_o(m_axi_qp_get_wqe_wlast_o),
  .m_axi_qp_get_wqe_wvalid_o(m_axi_qp_get_wqe_wvalid_o),
  .m_axi_qp_get_wqe_wready_i(m_axi_qp_get_wqe_wready_i),
  .m_axi_qp_get_wqe_awlock_o(m_axi_qp_get_wqe_awlock_o),
  .m_axi_qp_get_wqe_bid_i(m_axi_qp_get_wqe_bid_i),
  .m_axi_qp_get_wqe_bresp_i(m_axi_qp_get_wqe_bresp_i),
  .m_axi_qp_get_wqe_bvalid_i(m_axi_qp_get_wqe_bvalid_i),
  .m_axi_qp_get_wqe_bready_o(m_axi_qp_get_wqe_bready_o),
  .m_axi_qp_get_wqe_arid_o(m_axi_qp_get_wqe_arid_o),
  .m_axi_qp_get_wqe_araddr_o(m_axi_qp_get_wqe_araddr_o),
  .m_axi_qp_get_wqe_arlen_o(m_axi_qp_get_wqe_arlen_o),
  .m_axi_qp_get_wqe_arsize_o(m_axi_qp_get_wqe_arsize_o),
  .m_axi_qp_get_wqe_arburst_o(m_axi_qp_get_wqe_arburst_o),
  .m_axi_qp_get_wqe_arcache_o(m_axi_qp_get_wqe_arcache_o),
  .m_axi_qp_get_wqe_arprot_o(m_axi_qp_get_wqe_arprot_o),
  .m_axi_qp_get_wqe_arvalid_o(m_axi_qp_get_wqe_arvalid_o),
  .m_axi_qp_get_wqe_arready_i(m_axi_qp_get_wqe_arready_i),
  .m_axi_qp_get_wqe_arlock_o(m_axi_qp_get_wqe_arlock_o),
  .m_axi_qp_get_wqe_rid_i(m_axi_qp_get_wqe_rid_i),
  .m_axi_qp_get_wqe_rdata_i(m_axi_qp_get_wqe_rdata_i),
  .m_axi_qp_get_wqe_rresp_i(m_axi_qp_get_wqe_rresp_i),
  .m_axi_qp_get_wqe_rlast_i(m_axi_qp_get_wqe_rlast_i),
  .m_axi_qp_get_wqe_rvalid_i(m_axi_qp_get_wqe_rvalid_i),
  .m_axi_qp_get_wqe_rready_o(m_axi_qp_get_wqe_rready_o),

  .axil_aclk_i(axil_aclk_i),
  .axis_aclk_i(axis_aclk_i),
  .rstn_i(mod_rstn_i)
);


roce_stack_axis_to_aximm #(
  .AXI4_DATA_WIDTH(AXI4S_DATA_WIDTH)
) inst_roce_stack_axis_to_aximm (
  .s_rdma_rd_req_valid_i(rdma_rd_req.valid),
  .s_rdma_rd_req_ready_o(rdma_rd_req.ready),
  .s_rdma_rd_req_vaddr_i(rdma_rd_req.data.vaddr),
  .s_rdma_rd_req_len_i(rdma_rd_req.data.len),
  .s_rdma_rd_req_ctl_i(rdma_rd_req.data.ctl),

  .s_rdma_wr_req_valid_i(rdma_wr_req.valid),
  .s_rdma_wr_req_ready_o(rdma_wr_req.ready),
  .s_rdma_wr_req_vaddr_i(rdma_wr_req.data.vaddr),
  .s_rdma_wr_req_len_i(rdma_wr_req.data.len),
  .s_rdma_wr_req_ctl_i(rdma_wr_req.data.ctl),

  .m_axis_rdma_rd_tdata_o(axis_rdma_rd.tdata),
  .m_axis_rdma_rd_tkeep_o(axis_rdma_rd.tkeep),
  .m_axis_rdma_rd_tlast_o(axis_rdma_rd.tlast),
  .m_axis_rdma_rd_tvalid_o(axis_rdma_rd.tvalid),
  .m_axis_rdma_rd_tready_i(axis_rdma_rd.tready),

  .s_axis_rdma_wr_tdata_i(axis_rdma_wr.tdata),
  .s_axis_rdma_wr_tkeep_i(axis_rdma_wr.tkeep),
  .s_axis_rdma_wr_tlast_i(axis_rdma_wr.tlast),
  .s_axis_rdma_wr_tvalid_i(axis_rdma_wr.tvalid),
  .s_axis_rdma_wr_tready_o(axis_rdma_wr.tready),

  .rd_req_addr_valid_o(rd_req_addr_valid),
  .rd_req_addr_ready_i(rd_req_addr_ready),
  .rd_req_addr_vaddr_o(rd_req_addr_vaddr),
  .rd_resp_addr_valid_i(rd_resp_addr_valid),
  .rd_resp_addr_ready_o(rd_resp_addr_ready),
  .rd_resp_addr_data_i(rd_resp_addr_data),

  .wr_req_addr_valid_o(wr_req_addr_valid),
  .wr_req_addr_ready_i(wr_req_addr_ready),
  .wr_req_addr_vaddr_o(wr_req_addr_vaddr),
  .wr_resp_addr_valid_i(wr_resp_addr_valid),
  .wr_resp_addr_ready_o(wr_resp_addr_ready),
  .wr_resp_addr_data_i(wr_resp_addr_data),

  .m_axi_data_bus_awid_o(m_axi_data_bus_awid_o),
  .m_axi_data_bus_awaddr_o(m_axi_data_bus_awaddr_o),
  .m_axi_data_bus_awlen_o(m_axi_data_bus_awlen_o),
  .m_axi_data_bus_awsize_o(m_axi_data_bus_awsize_o),
  .m_axi_data_bus_awburst_o(m_axi_data_bus_awburst_o),
  .m_axi_data_bus_awcache_o(m_axi_data_bus_awcache_o),
  .m_axi_data_bus_awprot_o(m_axi_data_bus_awprot_o),
  .m_axi_data_bus_awvalid_o(m_axi_data_bus_awvalid_o),
  .m_axi_data_bus_awready_i(m_axi_data_bus_awready_i),
  .m_axi_data_bus_wdata_o(m_axi_data_bus_wdata_o),
  .m_axi_data_bus_wstrb_o(m_axi_data_bus_wstrb_o),
  .m_axi_data_bus_wlast_o(m_axi_data_bus_wlast_o),
  .m_axi_data_bus_wvalid_o(m_axi_data_bus_wvalid_o),
  .m_axi_data_bus_wready_i(m_axi_data_bus_wready_i),
  .m_axi_data_bus_bid_i(m_axi_data_bus_bid_i),
  .m_axi_data_bus_bresp_i(m_axi_data_bus_bresp_i),
  .m_axi_data_bus_bvalid_i(m_axi_data_bus_bvalid_i),
  .m_axi_data_bus_bready_o(m_axi_data_bus_bready_o),
  .m_axi_data_bus_arid_o(m_axi_data_bus_arid_o),
  .m_axi_data_bus_araddr_o(m_axi_data_bus_araddr_o),
  .m_axi_data_bus_arlen_o(m_axi_data_bus_arlen_o),
  .m_axi_data_bus_arsize_o(m_axi_data_bus_arsize_o),
  .m_axi_data_bus_arburst_o(m_axi_data_bus_arburst_o),
  .m_axi_data_bus_arcache_o(m_axi_data_bus_arcache_o),
  .m_axi_data_bus_arprot_o(m_axi_data_bus_arprot_o),
  .m_axi_data_bus_arvalid_o(m_axi_data_bus_arvalid_o),
  .m_axi_data_bus_arready_i(m_axi_data_bus_arready_i),
  .m_axi_data_bus_rid_i(m_axi_data_bus_rid_i),
  .m_axi_data_bus_rdata_i(m_axi_data_bus_rdata_i),
  .m_axi_data_bus_rresp_i(m_axi_data_bus_rresp_i),
  .m_axi_data_bus_rlast_i(m_axi_data_bus_rlast_i),
  .m_axi_data_bus_rvalid_i(m_axi_data_bus_rvalid_i),
  .m_axi_data_bus_rready_o(m_axi_data_bus_rready_o),

  .axis_aclk_i(axis_aclk_i),
  .aresetn_i(mod_rstn_i)

);



//TODO: definitions for AXI4S, metaIntf....
roce_stack inst_roce_stack (
  .nclk(axis_aclk_i),
  .nresetn(mod_rstn_i),

  // Network interface
  .s_axis_rx(axis_rx),
  .m_axis_tx(axis_tx),

  // User command
  .s_rdma_sq(rdma_sq),
  .m_rdma_ack(rdma_ack),

  // Control
  .s_rdma_qp_interface(rdma_qp_interface),
  .s_rdma_conn_interface(rdma_conn_interface),
  .local_ip_address(IPv4ADD_net),

   // Memory
  .m_rdma_rd_req(rdma_rd_req),
  .m_rdma_wr_req(rdma_wr_req),
  .s_axis_rdma_rd(axis_rdma_rd),
  .m_axis_rdma_wr(axis_rdma_wr),

  .ibv_rx_pkg_count_valid(),
  .ibv_rx_pkg_count_data(),
  .ibv_tx_pkg_count_valid(),
  .ibv_tx_pkg_count_data(),
  .crc_drop_pkg_count_valid(),
  .crc_drop_pkg_count_data(),
  .psn_drop_pkg_count_valid(),
  .psn_drop_pkg_count_data(),
  .retrans_count_valid(),
  .retrans_count_data()
);

//convert to network format before!
assign IPv4ADD_net = {IPv4ADD[7:0], IPv4ADD[15:8], IPv4ADD[23:16], IPv4ADD[31:24]};
assign IPDESADDR1i_net = {IPDESADDR1i[7:0], IPDESADDR1i[15:8], IPDESADDR1i[23:16], IPDESADDR1i[31:24]};

endmodule: roce_stack_wrapper
