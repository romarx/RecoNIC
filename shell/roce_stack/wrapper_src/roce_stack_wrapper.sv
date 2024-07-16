
import roceTypes::*;

module roce_stack_wrapper # (
  parameter int NUM_QP = 256, //min: 8, max: 256
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
  input logic                           axil_rstn_i,
  input logic                           axis_rstn_i

);

logic [7:0]   wr_ptr_wtc;

logic [31:0]  IPv4ADD;
logic [31:0]  IPv4ADD_net;

logic [7:0]   connidx, QPidx, SQidx, SQ_SEL_IDX, MACADD_SEL;
logic         conn_configured, qp_configured;

logic [31:0]  CONF;
logic [47:0]  MACADD;
logic [47:0]  MACADD_net;

logic [31:0]  QPCONFi;
logic [31:0]  QPADVCONFi;
logic [63:0]  RQBAi;
logic [63:0]  SQBAi;
logic [63:0]  CQBAi;
logic [63:0]  RQWPTRDBADDi;
logic [63:0]  CQDBADDi;
logic [31:0]  SQPIi;
logic [31:0]  QDEPTHi;
logic [23:0]  SQPSNi;
logic [31:0]  LSTRQREQi;
logic [23:0]  DESTQPCONFi;
logic [47:0]  MACDESADDi;
logic [47:0]  MACDESADDi_net;
logic [31:0]  IPDESADDR1i;
logic [31:0]  IPDESADDR1i_net;

logic [31:0]  SQ_QPCONFi;
logic [23:0]  SQ_SQPSNi;
logic [31:0]  SQ_LSTRQREQi;

logic [63:0] VIRTADDRi;


//write back regs
logic         wb_ready, wb_valid;

logic [39:0]  CQHEADi_wb_axis, CQHEADi_wb_axil;
logic         CQHEADi_wb_axis_valid, CQHEADi_wb_axil_valid;

logic [39:0]  SQPSNi_wb_axil, LSTRQREQi_wb_axil;
logic         SQPSNi_wb_axil_valid, LSTRQREQi_wb_axil_valid;

logic [31:0]  INSRRPKTCNT_wb_axil;
logic         INSRRPKTCNT_wb_axil_valid;

logic [31:0]  INAMPKTCNT_wb_axis, INAMPKTCNT_wb_axil;
logic         INAMPKTCNT_wb_axis_valid, INAMPKTCNT_wb_axil_valid;

logic [31:0]  INNCKPKTSTS_wb_axil;
logic         INNCKPKTSTS_wb_axil_valid;


logic [31:0]  OUTIOPKTCNT_wb_axil;
logic         OUTIOPKTCNT_wb_axil_valid;

logic [31:0]  OUTAMPKTCNT_wb_axis, OUTAMPKTCNT_wb_axil;
logic         OUTAMPKTCNT_wb_axis_valid, OUTAMPKTCNT_wb_axil_valid;

logic [16:0]  OUTNAKPKTCNT_wb_axil;
logic         OUTNAKPKTCNT_wb_axil_valid;

logic [31:0]  OUTRDRSPPKTCNT_wb_axil;
logic         OUTRDRSPPKTCNT_wb_axil_valid;


metaIntf #(.STYPE(req_t)) rdma_rd_req ();
metaIntf #(.STYPE(req_t)) rdma_wr_req ();

metaIntf #(.STYPE(rdma_qp_conn_t)) rdma_conn_interface();
metaIntf #(.STYPE(rdma_qp_ctx_t)) rdma_qp_interface();
metaIntf #(.STYPE(dreq_t)) rdma_sq();
metaIntf #(.STYPE(dack_t)) rdma_ack();

AXI4S #(.AXI4S_DATA_BITS(AXI4S_DATA_WIDTH)) axis_rdma_rd ();
AXI4S #(.AXI4S_DATA_BITS(AXI4S_DATA_WIDTH)) axis_rdma_wr ();
AXI4S #(.AXI4S_DATA_BITS(512)) axis_tx ();
AXI4S #(.AXI4S_DATA_BITS(512)) axis_tx_roce_to_eth ();
AXI4S #(.AXI4S_DATA_BITS(512)) axis_rx ();
AXI4S #(.AXI4S_DATA_BITS(512)) axis_rx_handler_to_roce ();


//address requests
logic rd_req_addr_valid, rd_req_addr_ready, wr_req_addr_valid, wr_req_addr_ready;
logic [63:0] rd_req_addr_vaddr, wr_req_addr_vaddr;
logic [15:0] rd_req_addr_qpn, wr_req_addr_qpn;
//address response
logic rd_resp_addr_valid, rd_resp_addr_ready, wr_resp_addr_valid, wr_resp_addr_ready;
dma_req_t rd_resp_addr_data, wr_resp_addr_data;

logic rx_ack_valid, rx_nack_valid, rx_srr_valid;
logic [15:0] rx_ack_data;
logic [31:0] rx_nack_data, rx_srr_data;

logic tx_ack_valid, tx_nack_valid, tx_srw_valid, tx_rr_valid;
logic [15:0] tx_ack_data, tx_nack_data;
logic [31:0] tx_srw_data, tx_rr_data;

logic epsn_valid, npsn_valid;
logic [39:0] epsn_data, npsn_data;

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
//assign m_rdma2cmac_axis_tvalid_o = axis_tx.tvalid;
//assign axis_tx.tready = m_rdma2cmac_axis_tready_i;
//assign m_rdma2cmac_axis_tlast_o = axis_tx.tlast;
//assign m_rdma2cmac_axis_tdata_o = axis_tx.tdata;
//assign m_rdma2cmac_axis_tkeep_o = axis_tx.tkeep;



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
  
  .ARESETN(axis_rstn_i),
  .S00_AXIS_ARESETN(axis_rstn_i),
  .S01_AXIS_ARESETN(axis_rstn_i),
  .M00_AXIS_ARESETN(axis_rstn_i)
);


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
  
  .SQidx_o(SQidx),
  .QPidx_o(QPidx),
  .connidx_o(connidx),
  .conn_configured_o(conn_configured),
  .qp_configured_o(qp_configured),
  
  .QPCONFi_o(QPCONFi),
  .QPADVCONFi_o(),
  .RQBAi_o(),
  .SQBAi_o(SQBAi),
  .CQBAi_o(CQBAi),
  .RQWPTRDBADDi_o(),
  .CQDBADDi_o(),
  .SQPIi_o(SQPIi),
  .QDEPTHi_o(),
  .SQPSNi_o(SQPSNi),
  .LSTRQREQi_o(LSTRQREQi),
  .DESTQPCONFi_o(DESTQPCONFi),
  
  .MACADD_SEL_i(MACADD_SEL),
  .MACDESADDi_o(MACDESADDi),
  .IPDESADDR1i_o(IPDESADDR1i),

  .C_SQidx_i(SQ_SEL_IDX),
  .SQ_QPCONFi_o(SQ_QPCONFi),
  .SQ_SQPSNi_o(SQ_SQPSNi),
  .SQ_LSTRQREQi_o(SQ_LSTRQREQi),

  .wb_ready_o(wb_ready),
  .wb_valid_i(wb_valid),
  .WB_CQHEADi_i(CQHEADi_wb_axil),
  .WB_CQHEADi_valid_i(CQHEADi_wb_axil_valid),

  .WB_INSRRPKTCNT_i(INSRRPKTCNT_wb_axil),
  .WB_INSRRPKTCNT_valid_i(INSRRPKTCNT_wb_axil_valid),
  .WB_INAMPKTCNT_i(INAMPKTCNT_wb_axil),
  .WB_INAMPKTCNT_valid_i(INAMPKTCNT_wb_axil_valid),
  .WB_INNCKPKTSTS_i(INNCKPKTSTS_wb_axil),
  .WB_INNCKPKTSTS_valid_i(INNCKPKTSTS_wb_axil_valid),

  .WB_OUTAMPKTCNT_i(OUTAMPKTCNT_wb_axil),
  .WB_OUTAMPKTCNT_valid_i(OUTAMPKTCNT_wb_axil_valid),
  .WB_OUTNAKPKTCNT_i(OUTNAKPKTCNT_wb_axil),
  .WB_OUTNAKPKTCNT_valid_i(OUTNAKPKTCNT_wb_axil_valid),
  .WB_OUTIOPKTCNT_i(OUTIOPKTCNT_wb_axil),
  .WB_OUTIOPKTCNT_valid_i(OUTIOPKTCNT_wb_axil_valid),
  .WB_OUTRDRSPPKTCNT_i(OUTRDRSPPKTCNT_wb_axil),
  .WB_OUTRDRSPPKTCNT_valid_i(OUTRDRSPPKTCNT_wb_axil_valid),

  .WB_SQPSNi_i(SQPSNi_wb_axil),
  .WB_SQPSNi_valid_i(SQPSNi_wb_axil_valid),
  .WB_LSTRQREQi_i(LSTRQREQi_wb_axil),
  .WB_LSTRQREQi_valid_i(LSTRQREQi_wb_axil_valid),

  .rd_req_addr_valid_i(rd_req_addr_valid),
  .rd_req_addr_ready_o(rd_req_addr_ready),
  .rd_req_addr_vaddr_i(rd_req_addr_vaddr),
  .rd_req_addr_qpn_i(rd_req_addr_qpn),
  .rd_resp_addr_valid_o(rd_resp_addr_valid),
  .rd_resp_addr_ready_i(rd_resp_addr_ready),
  .rd_resp_addr_data_o(rd_resp_addr_data),

  .wr_req_addr_valid_i(wr_req_addr_valid),
  .wr_req_addr_ready_o(wr_req_addr_ready),
  .wr_req_addr_vaddr_i(wr_req_addr_vaddr),
  .wr_req_addr_qpn_i(wr_req_addr_qpn),
  .wr_resp_addr_valid_o(wr_resp_addr_valid),
  .wr_resp_addr_ready_i(wr_resp_addr_ready),
  .wr_resp_addr_data_o(wr_resp_addr_data),




  .axis_aclk_i(axis_aclk_i),
  .axil_aclk_i(axil_aclk_i),
  .axis_rstn_i(axis_rstn_i),
  .axil_rstn_i(axil_rstn_i)
);

writeback_cdc_wrapper inst_wb_cdc_wrapper (
  .wb_ready_i(wb_ready),
  .wb_valid_o(wb_valid),
  
  .CQHEADi_wb_valid_i(CQHEADi_wb_axis_valid),
  .CQHEADi_wb_i(CQHEADi_wb_axis),
  .SQPSNi_wb_i(npsn_data),
  .SQPSNi_wb_valid_i(npsn_valid),
  .LSTRQREQi_wb_i(epsn_data),
  .LSTRQREQi_wb_valid_i(epsn_valid),

  .INSRRPKTCNT_wb_valid_i(rx_srr_valid),
  .INSRRPKTCNT_wb_i(rx_srr_data),
  .INAMPKTCNT_wb_valid_i(INAMPKTCNT_wb_axis_valid),
  .INAMPKTCNT_wb_i(INAMPKTCNT_wb_axis),
  .INNCKPKTSTS_wb_valid_i(rx_nack_valid),
  .INNCKPKTSTS_wb_i(rx_nack_data),

  .OUTAMPKTCNT_wb_valid_i(OUTAMPKTCNT_wb_axis_valid),
  .OUTAMPKTCNT_wb_i(OUTAMPKTCNT_wb_axis),
  .OUTNAKPKTCNT_wb_valid_i(tx_nack_valid),
  .OUTNAKPKTCNT_wb_i(tx_nack_data),
  .OUTIOPKTCNT_wb_valid_i(tx_srw_valid),
  .OUTIOPKTCNT_wb_i(tx_srw_data),
  .OUTRDRSPPKTCNT_wb_valid_i(tx_rr_valid),
  .OUTRDRSPPKTCNT_wb_i(tx_rr_data),

  .CQHEADi_wb_valid_o(CQHEADi_wb_axil_valid),
  .CQHEADi_wb_o(CQHEADi_wb_axil),
  .SQPSNi_wb_o(SQPSNi_wb_axil),
  .SQPSNi_wb_valid_o(SQPSNi_wb_axil_valid),
  .LSTRQREQi_wb_o(LSTRQREQi_wb_axil),
  .LSTRQREQi_wb_valid_o(LSTRQREQi_wb_axil_valid),

  .INSRRPKTCNT_wb_valid_o(INSRRPKTCNT_wb_axil_valid),
  .INSRRPKTCNT_wb_o(INSRRPKTCNT_wb_axil),
  .INAMPKTCNT_wb_valid_o(INAMPKTCNT_wb_axil_valid),
  .INAMPKTCNT_wb_o(INAMPKTCNT_wb_axil),
  .INNCKPKTSTS_wb_valid_o(INNCKPKTSTS_wb_axil_valid),
  .INNCKPKTSTS_wb_o(INNCKPKTSTS_wb_axil),

  .OUTAMPKTCNT_wb_valid_o(OUTAMPKTCNT_wb_axil_valid),
  .OUTAMPKTCNT_wb_o(OUTAMPKTCNT_wb_axil),
  .OUTNAKPKTCNT_wb_valid_o(OUTNAKPKTCNT_wb_axil_valid),
  .OUTNAKPKTCNT_wb_o(OUTNAKPKTCNT_wb_axil),
  .OUTIOPKTCNT_wb_valid_o(OUTIOPKTCNT_wb_axil_valid),
  .OUTIOPKTCNT_wb_o(OUTIOPKTCNT_wb_axil),
  .OUTRDRSPPKTCNT_wb_valid_o(OUTRDRSPPKTCNT_wb_axil_valid),
  .OUTRDRSPPKTCNT_wb_o(OUTRDRSPPKTCNT_wb_axil),

  .in_clk_i(axis_aclk_i),
  .out_clk_i(axil_aclk_i),
  .in_rstn_i(axis_rstn_i),
  .out_rstn_i(axil_rstn_i)
);



//TODO: finish this!
roce_stack_wq_manager #(
  .NUM_QP(NUM_QP)
)inst_roce_stack_wq_manager(
  .SQidx_i(SQidx),
  .QPidx_i(QPidx),
  .connidx_i(connidx),
  .conn_configured_i(conn_configured),
  .qp_configured_i(qp_configured),

  .CONF_i(CONF),

  .QPCONFi_i(QPCONFi),
  .DESTQPCONFi_i(DESTQPCONFi),
  .IPDESADDR1i_i(IPDESADDR1i_net),
  .SQPSNi_i(SQPSNi),
  .LSTRQREQi_i(LSTRQREQi),

  .C_SQidx_o(SQ_SEL_IDX),
  .SQ_QPCONFi_i(SQ_QPCONFi),
  .SQ_SQPSNi_i(SQ_SQPSNi),
  .SQ_LSTRQREQi_i(SQ_LSTRQREQi),


  .SQBAi_i(SQBAi),
  .CQBAi_i(CQBAi),
  .SQPIi_i(SQPIi),
  .VIRTADDR_i(VIRTADDRi),
   
  .WB_CQHEADi_o(CQHEADi_wb_axis),
  .WB_CQHEADi_valid_o(CQHEADi_wb_axis_valid),

  .rx_ack_valid_i(rx_ack_valid),
  .rx_nack_valid_i(rx_nack_valid),
  .rx_dat_valid_i(rx_srr_valid),

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
  .axil_rstn_i(axil_rstn_i),
  .axis_rstn_i(axis_rstn_i)
);


roce_stack_axis_to_aximm #(
  .AXI4_DATA_WIDTH(AXI4S_DATA_WIDTH)
) inst_roce_stack_axis_to_aximm (
  .s_rdma_rd_req_valid_i(rdma_rd_req.valid),
  .s_rdma_rd_req_ready_o(rdma_rd_req.ready),
  .s_rdma_rd_req_vaddr_i(rdma_rd_req.data.vaddr),
  .s_rdma_rd_req_len_i(rdma_rd_req.data.len),
  .s_rdma_rd_req_qpn_i(rdma_rd_req.data.qpn),
  .s_rdma_rd_req_last_i(rdma_rd_req.data.last),

  .s_rdma_wr_req_valid_i(rdma_wr_req.valid),
  .s_rdma_wr_req_ready_o(rdma_wr_req.ready),
  .s_rdma_wr_req_vaddr_i(rdma_wr_req.data.vaddr),
  .s_rdma_wr_req_len_i(rdma_wr_req.data.len),
  .s_rdma_wr_req_qpn_i(rdma_wr_req.data.qpn),
  .s_rdma_wr_req_last_i(rdma_wr_req.data.last),

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
  .rd_req_addr_qpn_o(rd_req_addr_qpn),
  .rd_resp_addr_valid_i(rd_resp_addr_valid),
  .rd_resp_addr_ready_o(rd_resp_addr_ready),
  .rd_resp_addr_data_i(rd_resp_addr_data),

  .wr_req_addr_valid_o(wr_req_addr_valid),
  .wr_req_addr_ready_i(wr_req_addr_ready),
  .wr_req_addr_vaddr_o(wr_req_addr_vaddr),
  .wr_req_addr_qpn_o(wr_req_addr_qpn),
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
  .aresetn_i(axis_rstn_i)

);

mac_ip_encode_ip mac_ip_encode_inst (
`ifdef VITIS_HLS
    .s_axis_ip_TVALID(axis_tx_roce_to_eth.tvalid),
    .s_axis_ip_TREADY(axis_tx_roce_to_eth.tready),
    .s_axis_ip_TDATA(axis_tx_roce_to_eth.tdata),
    .s_axis_ip_TKEEP(axis_tx_roce_to_eth.tkeep),
    .s_axis_ip_TLAST(axis_tx_roce_to_eth.tlast),
    
    .m_axis_ip_TVALID(axis_tx.tvalid),
    .m_axis_ip_TREADY(axis_tx.tready),
    .m_axis_ip_TDATA(axis_tx.tdata),
    .m_axis_ip_TKEEP(axis_tx.tkeep),
    .m_axis_ip_TLAST(axis_tx.tlast),
  
    .myMacAddress(MACADD_net),
    .theirMacAddress(MACDESADDi_net),
    
    .ap_clk(axis_aclk_i), // input aclk
    .ap_rst_n(axis_rstn_i) // input aresetn
`else
    .s_axis_ip_TVALID(axis_tx_roce_to_eth.tvalid),
    .s_axis_ip_TREADY(axis_tx_roce_to_eth.tready),
    .s_axis_ip_TDATA(axis_tx_roce_to_eth.tdata),
    .s_axis_ip_TKEEP(axis_tx_roce_to_eth.tkeep),
    .s_axis_ip_TLAST(axis_tx_roce_to_eth.tlast),
    
    .m_axis_ip_TVALID(axis_tx.tvalid),
    .m_axis_ip_TREADY(axis_tx.tready),
    .m_axis_ip_TDATA(axis_tx.tdata),
    .m_axis_ip_TKEEP(axis_tx.tkeep),
    .m_axis_ip_TLAST(axis_tx.tlast),
    
    .myMacAddress_V(MACADD_net),
    .theirMacAddress_V(MACDESADDi_net),
    
    .ap_clk(axis_aclk_i), // input aclk
    .ap_rst_n(axis_rstn_i) // input aresetn
`endif
);

AXI4S #(.AXI4S_DATA_BITS(512)) axis_ip_handler_droppedpkg_dbg ();
assign axis_ip_handler_droppedpkg_dbg.tready = 1'b1;
// IP handler
ip_handler_ip ip_handler_inst ( 
    .s_axis_raw_TVALID(axis_rx.tvalid),
    .s_axis_raw_TREADY(axis_rx.tready),
    .s_axis_raw_TDATA(axis_rx.tdata),
    .s_axis_raw_TKEEP(axis_rx.tkeep),
    .s_axis_raw_TLAST(axis_rx.tlast),
    
    .m_axis_roce_TVALID(axis_rx_handler_to_roce.tvalid),
    .m_axis_roce_TREADY(axis_rx_handler_to_roce.tready),
    .m_axis_roce_TDATA(axis_rx_handler_to_roce.tdata),
    .m_axis_roce_TKEEP(axis_rx_handler_to_roce.tkeep),
    .m_axis_roce_TLAST(axis_rx_handler_to_roce.tlast),

    .tx_iph_droppedpackage_debug_TVALID(axis_ip_handler_droppedpkg_dbg.tvalid),
    .tx_iph_droppedpackage_debug_TREADY(axis_ip_handler_droppedpkg_dbg.tready),
    .tx_iph_droppedpackage_debug_TDATA(axis_ip_handler_droppedpkg_dbg.tdata),
    .tx_iph_droppedpackage_debug_TKEEP(axis_ip_handler_droppedpkg_dbg.tkeep),
    .tx_iph_droppedpackage_debug_TLAST(axis_ip_handler_droppedpkg_dbg.tlast),

`ifdef VITIS_HLS
    .myIpAddress(IPv4ADD_net),
`else
    .myIpAddress_V(IPv4ADD_net),
`endif

    .ap_clk(axis_aclk_i), // input aclk
    .ap_rst_n(axis_rstn_i) // input aresetn
); 


assign rdma_ack.ready = 1'b1;
//TODO: definitions for AXI4S, metaIntf....
roce_stack inst_roce_stack (
  .nclk(axis_aclk_i),
  .nresetn(axis_rstn_i),

  // Network interface
  .s_axis_rx(axis_rx_handler_to_roce),
  .m_axis_tx(axis_tx_roce_to_eth),

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
   
  .ibv_rx_ack_count_valid(rx_ack_valid),
  .ibv_rx_ack_count_data(rx_ack_data),
  .ibv_rx_nack_sts_valid(rx_nack_valid),
  .ibv_rx_nack_sts_data(rx_nack_data),
  .ibv_rx_srr_count_valid(rx_srr_valid),
  .ibv_rx_srr_count_data(rx_srr_data),

  .ibv_tx_pkg_count_valid(),
  .ibv_tx_pkg_count_data(),

  .ibv_tx_ack_count_valid(tx_ack_valid),
  .ibv_tx_ack_count_data(tx_ack_data),
  .ibv_tx_nack_count_valid(tx_nack_valid),
  .ibv_tx_nack_count_data(tx_nack_data),
  .ibv_tx_srw_count_valid(tx_srw_valid),
  .ibv_tx_srw_count_data(tx_srw_data),
  .ibv_tx_rr_count_valid(tx_rr_valid), //TODO: rresp 
  .ibv_tx_rr_count_data(tx_rr_data),

  .reg_epsn_valid(epsn_valid),
  .reg_epsn_data(epsn_data),
  .reg_npsn_valid(npsn_valid),
  .reg_npsn_data(npsn_data),

  .crc_drop_pkg_count_valid(),
  .crc_drop_pkg_count_data(),
  .psn_drop_pkg_count_valid(),
  .psn_drop_pkg_count_data(),
  .retrans_count_valid(),
  .retrans_count_data()
);

// a bit hacky but it works ;)
always_comb begin
  if(epsn_valid) begin
    MACADD_SEL = epsn_data[31:24];
  end
  if(npsn_valid) begin
    MACADD_SEL = npsn_data[31:24];
  end
end

assign INAMPKTCNT_wb_axis[15:0] = rx_ack_data;
assign INAMPKTCNT_wb_axis[31:16] = 16'd0; //incoming MAD packets (unsupported)
assign INAMPKTCNT_wb_axis_valid = rx_ack_valid;

assign OUTAMPKTCNT_wb_axis[15:0] = tx_ack_data;
assign OUTAMPKTCNT_wb_axis[31:16] = 16'd0; //incoming MAD packets (unsupported)
assign OUTAMPKTCNT_wb_axis_valid = tx_ack_valid;


//convert to network format
assign IPv4ADD_net = {IPv4ADD[7:0], IPv4ADD[15:8], IPv4ADD[23:16], IPv4ADD[31:24]};
assign IPDESADDR1i_net = {IPDESADDR1i[7:0], IPDESADDR1i[15:8], IPDESADDR1i[23:16], IPDESADDR1i[31:24]};
assign MACADD_net = {MACADD[7:0], MACADD[15:8], MACADD[23:16], MACADD[31:24], MACADD[39:32], MACADD[47:40]};
assign MACDESADDi_net = {MACDESADDi[7:0], MACDESADDi[15:8], MACDESADDi[23:16], MACDESADDi[31:24], MACDESADDi[39:32], MACDESADDi[47:40]};

endmodule: roce_stack_wrapper
