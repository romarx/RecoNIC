//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module rdma_rn_roce_wrapper (
// AXIL interface to the RDMA engine
  input         s_axil_rdma_awvalid,
  input  [31:0] s_axil_rdma_awaddr,
  output        s_axil_rdma_awready,
  input         s_axil_rdma_wvalid,
  input  [31:0] s_axil_rdma_wdata,
  output        s_axil_rdma_wready,
  output        s_axil_rdma_bvalid,
  output  [1:0] s_axil_rdma_bresp,
  input         s_axil_rdma_bready,
  input         s_axil_rdma_arvalid,
  input  [31:0] s_axil_rdma_araddr,
  output        s_axil_rdma_arready,
  output        s_axil_rdma_rvalid,
  output [31:0] s_axil_rdma_rdata,
  output  [1:0] s_axil_rdma_rresp,
  input         s_axil_rdma_rready,

// RecoNIC AXI4-Lite register channel
  input         s_axil_rn_awvalid,
  input  [31:0] s_axil_rn_awaddr,
  output        s_axil_rn_awready,
  input         s_axil_rn_wvalid,
  input  [31:0] s_axil_rn_wdata,
  output        s_axil_rn_wready,
  output        s_axil_rn_bvalid,
  output  [1:0] s_axil_rn_bresp,
  input         s_axil_rn_bready,
  input         s_axil_rn_arvalid,
  input  [31:0] s_axil_rn_araddr,
  output        s_axil_rn_arready,
  output        s_axil_rn_rvalid,
  output [31:0] s_axil_rn_rdata,
  output  [1:0] s_axil_rn_rresp,
  input         s_axil_rn_rready,

  // Receive packets from CMAC RX path
  input         s_axis_cmac_rx_tvalid,
  input [511:0] s_axis_cmac_rx_tdata,
  input  [63:0] s_axis_cmac_rx_tkeep,
  input         s_axis_cmac_rx_tlast,
  input  [15:0] s_axis_cmac_rx_tuser_size,
  output        s_axis_cmac_rx_tready,

  // Expose roce packets from CMAC RX path after packet classification, 
  // for debug only
  output [511:0] m_axis_cmac2rdma_roce_tdata,
  output  [63:0] m_axis_cmac2rdma_roce_tkeep,
  output         m_axis_cmac2rdma_roce_tvalid,
  output         m_axis_cmac2rdma_roce_tlast,

  // AXIS data to CMAC TX path
  output [511:0] m_axis_cmac_tx_tdata,
  output  [63:0] m_axis_cmac_tx_tkeep,
  output         m_axis_cmac_tx_tvalid,
  output  [15:0] m_axis_cmac_tx_tuser_size,
  output         m_axis_cmac_tx_tlast,
  input          m_axis_cmac_tx_tready,

  // Get non-roce packets from QDMA tx path
  input         s_axis_qdma_h2c_tvalid,
  input [511:0] s_axis_qdma_h2c_tdata,
  input  [63:0] s_axis_qdma_h2c_tkeep,
  input         s_axis_qdma_h2c_tlast,
  input  [15:0] s_axis_qdma_h2c_tuser_size,
  output        s_axis_qdma_h2c_tready,

  // Send non-roce packets from QDMA rx path
  output         m_axis_qdma_c2h_tvalid,
  output [511:0] m_axis_qdma_c2h_tdata,
  output  [63:0] m_axis_qdma_c2h_tkeep,
  output         m_axis_qdma_c2h_tlast,
  output  [15:0] m_axis_qdma_c2h_tuser_size,
  input          m_axis_qdma_c2h_tready,

  
  // RDMA AXI MM interface used to fetch WQE entries in the senq queue from DDR by the QP manager
  output           m_axi_rdma_get_wqe_awid,
  output  [63 : 0] m_axi_rdma_get_wqe_awaddr,
  output   [7 : 0] m_axi_rdma_get_wqe_awlen,
  output   [2 : 0] m_axi_rdma_get_wqe_awsize,
  output   [1 : 0] m_axi_rdma_get_wqe_awburst,
  output   [3 : 0] m_axi_rdma_get_wqe_awcache,
  output   [2 : 0] m_axi_rdma_get_wqe_awprot,
  output           m_axi_rdma_get_wqe_awvalid,
  input            m_axi_rdma_get_wqe_awready,
  output [511 : 0] m_axi_rdma_get_wqe_wdata,
  output  [63 : 0] m_axi_rdma_get_wqe_wstrb,
  output           m_axi_rdma_get_wqe_wlast,
  output           m_axi_rdma_get_wqe_wvalid,
  input            m_axi_rdma_get_wqe_wready,
  output           m_axi_rdma_get_wqe_awlock,
  input            m_axi_rdma_get_wqe_bid,
  input    [1 : 0] m_axi_rdma_get_wqe_bresp,
  input            m_axi_rdma_get_wqe_bvalid,
  output           m_axi_rdma_get_wqe_bready,
  output           m_axi_rdma_get_wqe_arid,
  output  [63 : 0] m_axi_rdma_get_wqe_araddr,
  output   [7 : 0] m_axi_rdma_get_wqe_arlen,
  output   [2 : 0] m_axi_rdma_get_wqe_arsize,
  output   [1 : 0] m_axi_rdma_get_wqe_arburst,
  output   [3 : 0] m_axi_rdma_get_wqe_arcache,
  output   [2 : 0] m_axi_rdma_get_wqe_arprot,
  output           m_axi_rdma_get_wqe_arvalid,
  input            m_axi_rdma_get_wqe_arready,
  input            m_axi_rdma_get_wqe_rid,
  input  [511 : 0] m_axi_rdma_get_wqe_rdata,
  input    [1 : 0] m_axi_rdma_get_wqe_rresp,
  input            m_axi_rdma_get_wqe_rlast,
  input            m_axi_rdma_get_wqe_rvalid,
  output           m_axi_rdma_get_wqe_rready,
  output           m_axi_rdma_get_wqe_arlock,

  // RDMA AXI MM interface used to write completion entries to a completion queue in the DDR
  output           m_axi_rdma_data_bus_awid,
  output  [63 : 0] m_axi_rdma_data_bus_awaddr,
  output   [7 : 0] m_axi_rdma_data_bus_awlen,
  output   [2 : 0] m_axi_rdma_data_bus_awsize,
  output   [1 : 0] m_axi_rdma_data_bus_awburst,
  output   [3 : 0] m_axi_rdma_data_bus_awcache,
  output   [2 : 0] m_axi_rdma_data_bus_awprot,
  output           m_axi_rdma_data_bus_awvalid,
  input            m_axi_rdma_data_bus_awready,
  output [511 : 0] m_axi_rdma_data_bus_wdata,
  output  [63 : 0] m_axi_rdma_data_bus_wstrb,
  output           m_axi_rdma_data_bus_wlast,
  output           m_axi_rdma_data_bus_wvalid,
  input            m_axi_rdma_data_bus_wready,
  output           m_axi_rdma_data_bus_awlock,
  input            m_axi_rdma_data_bus_bid,
  input    [1 : 0] m_axi_rdma_data_bus_bresp,
  input            m_axi_rdma_data_bus_bvalid,
  output           m_axi_rdma_data_bus_bready,
  output           m_axi_rdma_data_bus_arid,
  output  [63 : 0] m_axi_rdma_data_bus_araddr,
  output   [7 : 0] m_axi_rdma_data_bus_arlen,
  output   [2 : 0] m_axi_rdma_data_bus_arsize,
  output   [1 : 0] m_axi_rdma_data_bus_arburst,
  output   [3 : 0] m_axi_rdma_data_bus_arcache,
  output   [2 : 0] m_axi_rdma_data_bus_arprot,
  output           m_axi_rdma_data_bus_arvalid,
  input            m_axi_rdma_data_bus_arready,
  input            m_axi_rdma_data_bus_rid,
  input  [511 : 0] m_axi_rdma_data_bus_rdata,
  input    [1 : 0] m_axi_rdma_data_bus_rresp,
  input            m_axi_rdma_data_bus_rlast,
  input            m_axi_rdma_data_bus_rvalid,
  output           m_axi_rdma_data_bus_rready,
  output           m_axi_rdma_data_bus_arlock,

  output           m_axi_compute_logic_awid,
  output  [63 : 0] m_axi_compute_logic_awaddr,
  output   [3 : 0] m_axi_compute_logic_awqos,
  output   [7 : 0] m_axi_compute_logic_awlen,
  output   [2 : 0] m_axi_compute_logic_awsize,
  output   [1 : 0] m_axi_compute_logic_awburst,
  output   [3 : 0] m_axi_compute_logic_awcache,
  output   [2 : 0] m_axi_compute_logic_awprot,
  output           m_axi_compute_logic_awvalid,
  input            m_axi_compute_logic_awready,
  output [511 : 0] m_axi_compute_logic_wdata,
  output  [63 : 0] m_axi_compute_logic_wstrb,
  output           m_axi_compute_logic_wlast,
  output           m_axi_compute_logic_wvalid,
  input            m_axi_compute_logic_wready,
  output           m_axi_compute_logic_awlock,
  input            m_axi_compute_logic_bid,
  input    [1 : 0] m_axi_compute_logic_bresp,
  input            m_axi_compute_logic_bvalid,
  output           m_axi_compute_logic_bready,
  output           m_axi_compute_logic_arid,
  output  [63 : 0] m_axi_compute_logic_araddr,
  output   [7 : 0] m_axi_compute_logic_arlen,
  output   [2 : 0] m_axi_compute_logic_arsize,
  output   [1 : 0] m_axi_compute_logic_arburst,
  output   [3 : 0] m_axi_compute_logic_arcache,
  output   [2 : 0] m_axi_compute_logic_arprot,
  output           m_axi_compute_logic_arvalid,
  input            m_axi_compute_logic_arready,
  input            m_axi_compute_logic_rid,
  input  [511 : 0] m_axi_compute_logic_rdata,
  input    [1 : 0] m_axi_compute_logic_rresp,
  input            m_axi_compute_logic_rlast,
  input            m_axi_compute_logic_rvalid,
  output           m_axi_compute_logic_rready,
  output           m_axi_compute_logic_arlock,
  output    [3:0]  m_axi_compute_logic_arqos,

  output rdma_intr,
  input  axil_aclk,
  input  axil_rstn,
  input  axis_aclk,
  input  axis_rstn
);

// Send roce packets from reconic to rdma rx path
logic [511:0] cmac2rdma_roce_axis_tdata;
logic  [63:0] cmac2rdma_roce_axis_tkeep;
logic         cmac2rdma_roce_axis_tvalid;
logic         cmac2rdma_roce_axis_tlast;
logic         cmac2rdma_roce_axis_tuser;
logic         cmac2rdma_roce_axis_tready;

// RDMA TX interface (including roce and non-roce packets) to CMAC TX path
logic [511:0] rdma2cmac_axis_tdata;
logic  [63:0] rdma2cmac_axis_tkeep;
logic         rdma2cmac_axis_tvalid;
logic         rdma2cmac_axis_tlast;
logic         rdma2cmac_axis_tready;

// Non-RDMA packets from QDMA TX bypassing RDMA TX
logic [511:0] qdma2rdma_non_roce_axis_tdata;
logic  [63:0] qdma2rdma_non_roce_axis_tkeep;
logic         qdma2rdma_non_roce_axis_tvalid;
logic         qdma2rdma_non_roce_axis_tlast;
logic         qdma2rdma_non_roce_axis_tready;

// invalidate or immediate data from roce IETH/IMMDT header
logic  [63:0] rdma2user_ieth_immdt_axis_tdata;
logic         rdma2user_ieth_immdt_axis_tlast;
logic         rdma2user_ieth_immdt_axis_tvalid;
logic         rdma2user_ieth_immdt_axis_trdy;

// Send WQE completion queue doorbell
logic         resp_hndler_o_send_cq_db_cnt_valid;
logic   [9:0] resp_hndler_o_send_cq_db_addr;
logic  [31:0] resp_hndler_o_send_cq_db_cnt;
logic         resp_hndler_i_send_cq_db_rdy;

// Send WQE producer index doorbell
logic  [15:0] i_qp_sq_pidb_hndshk;
logic  [31:0] i_qp_sq_pidb_wr_addr_hndshk;
logic         i_qp_sq_pidb_wr_valid_hndshk;
logic         o_qp_sq_pidb_wr_rdy;

// RDMA-Send consumer index doorbell
logic  [15:0] i_qp_rq_cidb_hndshk;
logic  [31:0] i_qp_rq_cidb_wr_addr_hndshk;
logic         i_qp_rq_cidb_wr_valid_hndshk;
logic         o_qp_rq_cidb_wr_rdy;

// RDMA-Send producer index doorbell
logic  [31:0] rx_pkt_hndler_o_rq_db_data;
logic   [9:0] rx_pkt_hndler_o_rq_db_addr;
logic         rx_pkt_hndler_o_rq_db_data_valid;
logic         rx_pkt_hndler_i_rq_db_rdy;

logic  [15:0] user_rst_done;
logic         box_rst_done;

logic         rdma_rstn;
logic         rdma_rst_done;

// RDMA subsystem
roce_stack_wrapper #(
  .NUM_QP(256), //min: 8, max: 256
  .AXIL_ADDR_WIDTH(32),
  .AXIL_DATA_WIDTH(32),
  .AXI4S_DATA_WIDTH(512)
) remote_peer_rdma_inst (
  // AXIL interface for RDMA control register
  .s_axil_awvalid_i (s_axil_rdma_awvalid),
  .s_axil_awaddr_i  (s_axil_rdma_awaddr),
  .s_axil_awready_o (s_axil_rdma_awready),
  .s_axil_wvalid_i  (s_axil_rdma_wvalid),
  .s_axil_wdata_i   (s_axil_rdma_wdata),
  .s_axil_wstrb_i   (4'hf),
  .s_axil_wready_o  (s_axil_rdma_wready),
  .s_axil_bvalid_o  (s_axil_rdma_bvalid),
  .s_axil_bresp_o   (s_axil_rdma_bresp),
  .s_axil_bready_i  (s_axil_rdma_bready),
  .s_axil_arvalid_i (s_axil_rdma_arvalid),
  .s_axil_araddr_i  (s_axil_rdma_araddr),
  .s_axil_arready_o (s_axil_rdma_arready),
  .s_axil_rvalid_o  (s_axil_rdma_rvalid),
  .s_axil_rdata_o   (s_axil_rdma_rdata),
  .s_axil_rresp_o   (s_axil_rdma_rresp),
  .s_axil_rready_i  (s_axil_rdma_rready),

  // RDMA TX interface (including roce and non-roce packets) to CMAC TX path
  .m_rdma2cmac_axis_tdata_o  (rdma2cmac_axis_tdata),
  .m_rdma2cmac_axis_tkeep_o  (rdma2cmac_axis_tkeep),
  .m_rdma2cmac_axis_tvalid_o (rdma2cmac_axis_tvalid),
  .m_rdma2cmac_axis_tlast_o  (rdma2cmac_axis_tlast),
  .m_rdma2cmac_axis_tready_i (rdma2cmac_axis_tready),

  // Non-RDMA packets from QDMA TX bypassing RDMA TX
  .s_qdma2rdma_non_roce_axis_tdata_i    (qdma2rdma_non_roce_axis_tdata),
  .s_qdma2rdma_non_roce_axis_tkeep_i    (qdma2rdma_non_roce_axis_tkeep),
  .s_qdma2rdma_non_roce_axis_tvalid_i   (qdma2rdma_non_roce_axis_tvalid),
  .s_qdma2rdma_non_roce_axis_tlast_i    (qdma2rdma_non_roce_axis_tlast),
  .s_qdma2rdma_non_roce_axis_tready_o   (qdma2rdma_non_roce_axis_tready),

  // RDMA RX interface from CMAC RX, no rx backpressure
  .s_cmac2rdma_roce_axis_tdata_i        (cmac2rdma_roce_axis_tdata),
  .s_cmac2rdma_roce_axis_tkeep_i        (cmac2rdma_roce_axis_tkeep),
  .s_cmac2rdma_roce_axis_tvalid_i       (cmac2rdma_roce_axis_tvalid),
  .s_cmac2rdma_roce_axis_tlast_i        (cmac2rdma_roce_axis_tlast),
  .s_cmac2rdma_roce_axis_tuser_i        (cmac2rdma_roce_axis_tuser),

  //AXI Master to fetch WQEs
  .m_axi_qp_get_wqe_awid_o    (m_axi_rdma_get_wqe_awid),
  .m_axi_qp_get_wqe_awaddr_o  (m_axi_rdma_get_wqe_awaddr),
  .m_axi_qp_get_wqe_awlen_o   (m_axi_rdma_get_wqe_awlen),
  .m_axi_qp_get_wqe_awsize_o  (m_axi_rdma_get_wqe_awsize),
  .m_axi_qp_get_wqe_awburst_o (m_axi_rdma_get_wqe_awburst),
  .m_axi_qp_get_wqe_awcache_o (m_axi_rdma_get_wqe_awcache),
  .m_axi_qp_get_wqe_awprot_o  (m_axi_rdma_get_wqe_awprot),
  .m_axi_qp_get_wqe_awvalid_o (m_axi_rdma_get_wqe_awvalid),
  .m_axi_qp_get_wqe_awready_i (m_axi_rdma_get_wqe_awready),
  .m_axi_qp_get_wqe_wdata_o   (m_axi_rdma_get_wqe_wdata),
  .m_axi_qp_get_wqe_wstrb_o   (m_axi_rdma_get_wqe_wstrb),
  .m_axi_qp_get_wqe_wlast_o   (m_axi_rdma_get_wqe_wlast),
  .m_axi_qp_get_wqe_wvalid_o  (m_axi_rdma_get_wqe_wvalid),
  .m_axi_qp_get_wqe_wready_i  (m_axi_rdma_get_wqe_wready),
  .m_axi_qp_get_wqe_awlock_o  (m_axi_rdma_get_wqe_awlock),
  .m_axi_qp_get_wqe_bid_i     (m_axi_rdma_get_wqe_bid),
  .m_axi_qp_get_wqe_bresp_i   (m_axi_rdma_get_wqe_bresp),
  .m_axi_qp_get_wqe_bvalid_i  (m_axi_rdma_get_wqe_bvalid),
  .m_axi_qp_get_wqe_bready_o  (m_axi_rdma_get_wqe_bready),
  .m_axi_qp_get_wqe_arid_o    (m_axi_rdma_get_wqe_arid),
  .m_axi_qp_get_wqe_araddr_o  (m_axi_rdma_get_wqe_araddr),
  .m_axi_qp_get_wqe_arlen_o   (m_axi_rdma_get_wqe_arlen),
  .m_axi_qp_get_wqe_arsize_o  (m_axi_rdma_get_wqe_arsize),
  .m_axi_qp_get_wqe_arburst_o (m_axi_rdma_get_wqe_arburst),
  .m_axi_qp_get_wqe_arcache_o (m_axi_rdma_get_wqe_arcache),
  .m_axi_qp_get_wqe_arprot_o  (m_axi_rdma_get_wqe_arprot),
  .m_axi_qp_get_wqe_arvalid_o (m_axi_rdma_get_wqe_arvalid),
  .m_axi_qp_get_wqe_arready_i (m_axi_rdma_get_wqe_arready),
  .m_axi_qp_get_wqe_arlock_o  (m_axi_rdma_get_wqe_arlock),
  .m_axi_qp_get_wqe_rid_i     (m_axi_rdma_get_wqe_rid),
  .m_axi_qp_get_wqe_rdata_i   (m_axi_rdma_get_wqe_rdata),
  .m_axi_qp_get_wqe_rresp_i   (m_axi_rdma_get_wqe_rresp),
  .m_axi_qp_get_wqe_rlast_i   (m_axi_rdma_get_wqe_rlast),
  .m_axi_qp_get_wqe_rvalid_i  (m_axi_rdma_get_wqe_rvalid),
  .m_axi_qp_get_wqe_rready_o  (m_axi_rdma_get_wqe_rready),
  
//AXI Master memory interface
  .m_axi_data_bus_awid_o      (m_axi_rdma_data_bus_awid),
  .m_axi_data_bus_awaddr_o    (m_axi_rdma_data_bus_awaddr),
  .m_axi_data_bus_awlen_o     (m_axi_rdma_data_bus_awlen),
  .m_axi_data_bus_awsize_o    (m_axi_rdma_data_bus_awsize),
  .m_axi_data_bus_awburst_o   (m_axi_rdma_data_bus_awburst),
  .m_axi_data_bus_awcache_o   (m_axi_rdma_data_bus_awcache),
  .m_axi_data_bus_awprot_o    (m_axi_rdma_data_bus_awprot),
  .m_axi_data_bus_awvalid_o   (m_axi_rdma_data_bus_awvalid),
  .m_axi_data_bus_awready_i   (m_axi_rdma_data_bus_awready),
  .m_axi_data_bus_wdata_o     (m_axi_rdma_data_bus_wdata),
  .m_axi_data_bus_wstrb_o     (m_axi_rdma_data_bus_wstrb),
  .m_axi_data_bus_wlast_o     (m_axi_rdma_data_bus_wlast),
  .m_axi_data_bus_wvalid_o    (m_axi_rdma_data_bus_wvalid),
  .m_axi_data_bus_wready_i    (m_axi_rdma_data_bus_wready),
  .m_axi_data_bus_awlock_o    (m_axi_rdma_data_bus_awlock),
  .m_axi_data_bus_bid_i       (m_axi_rdma_data_bus_bid),
  .m_axi_data_bus_bresp_i     (m_axi_rdma_data_bus_bresp),
  .m_axi_data_bus_bvalid_i    (m_axi_rdma_data_bus_bvalid),
  .m_axi_data_bus_bready_o    (m_axi_rdma_data_bus_bready),
  .m_axi_data_bus_arid_o      (m_axi_rdma_data_bus_arid),
  .m_axi_data_bus_araddr_o    (m_axi_rdma_data_bus_araddr),
  .m_axi_data_bus_arlen_o     (m_axi_rdma_data_bus_arlen),
  .m_axi_data_bus_arsize_o    (m_axi_rdma_data_bus_arsize),
  .m_axi_data_bus_arburst_o   (m_axi_rdma_data_bus_arburst),
  .m_axi_data_bus_arcache_o   (m_axi_rdma_data_bus_arcache),
  .m_axi_data_bus_arprot_o    (m_axi_rdma_data_bus_arprot),
  .m_axi_data_bus_arvalid_o   (m_axi_rdma_data_bus_arvalid),
  .m_axi_data_bus_arready_i   (m_axi_rdma_data_bus_arready),
  .m_axi_data_bus_arlock_o    (m_axi_rdma_data_bus_arlock),
  .m_axi_data_bus_rid_i       (m_axi_rdma_data_bus_rid),
  .m_axi_data_bus_rdata_i     (m_axi_rdma_data_bus_rdata),
  .m_axi_data_bus_rresp_i     (m_axi_rdma_data_bus_rresp),
  .m_axi_data_bus_rlast_i     (m_axi_rdma_data_bus_rlast),
  .m_axi_data_bus_rvalid_i    (m_axi_rdma_data_bus_rvalid),
  .m_axi_data_bus_rready_o    (m_axi_rdma_data_bus_rready),

  .axil_aclk_i(axil_aclk),
  .axis_aclk_i(axis_aclk),
  .mod_rstn_i(axil_rstn)
);

// reconic wrapper
box_250mhz rn_dut (
  // AXI4-Lite register channel
  .s_axil_awvalid(s_axil_rn_awvalid),
  .s_axil_awaddr (s_axil_rn_awaddr),
  .s_axil_awready(s_axil_rn_awready),
  .s_axil_wvalid (s_axil_rn_wvalid),
  .s_axil_wdata  (s_axil_rn_wdata),
  .s_axil_wready (s_axil_rn_wready),
  .s_axil_bvalid (s_axil_rn_bvalid),
  .s_axil_bresp  (s_axil_rn_bresp),
  .s_axil_bready (s_axil_rn_bready),
  .s_axil_arvalid(s_axil_rn_arvalid),
  .s_axil_araddr (s_axil_rn_araddr),
  .s_axil_arready(s_axil_rn_arready),
  .s_axil_rvalid (s_axil_rn_rvalid),
  .s_axil_rdata  (s_axil_rn_rdata),
  .s_axil_rresp  (s_axil_rn_rresp),
  .s_axil_rready (s_axil_rn_rready),

  .s_axis_qdma_h2c_tvalid           (s_axis_qdma_h2c_tvalid),
  .s_axis_qdma_h2c_tdata            (s_axis_qdma_h2c_tdata),
  .s_axis_qdma_h2c_tkeep            (s_axis_qdma_h2c_tkeep),
  .s_axis_qdma_h2c_tlast            (s_axis_qdma_h2c_tlast),
  .s_axis_qdma_h2c_tuser_size       (s_axis_qdma_h2c_tuser_size),
  .s_axis_qdma_h2c_tuser_src        (16'hffff),
  .s_axis_qdma_h2c_tuser_dst        (16'hffff),
  .s_axis_qdma_h2c_tready           (s_axis_qdma_h2c_tready),

  .m_axis_qdma_c2h_tvalid           (m_axis_qdma_c2h_tvalid),
  .m_axis_qdma_c2h_tdata            (m_axis_qdma_c2h_tdata),
  .m_axis_qdma_c2h_tkeep            (m_axis_qdma_c2h_tkeep),
  .m_axis_qdma_c2h_tlast            (m_axis_qdma_c2h_tlast),
  .m_axis_qdma_c2h_tuser_size       (m_axis_qdma_c2h_tuser_size),
  .m_axis_qdma_c2h_tuser_src        (),
  .m_axis_qdma_c2h_tuser_dst        (),
  .m_axis_qdma_c2h_tready           (m_axis_qdma_c2h_tready),

  // Send packets to CMAC TX path
  .m_axis_adap_tx_250mhz_tvalid     (m_axis_cmac_tx_tvalid),
  .m_axis_adap_tx_250mhz_tdata      (m_axis_cmac_tx_tdata),
  .m_axis_adap_tx_250mhz_tkeep      (m_axis_cmac_tx_tkeep),
  .m_axis_adap_tx_250mhz_tlast      (m_axis_cmac_tx_tlast),
  .m_axis_adap_tx_250mhz_tuser_size (m_axis_cmac_tx_tuser_size),
  .m_axis_adap_tx_250mhz_tuser_src  (),
  .m_axis_adap_tx_250mhz_tuser_dst  (),
  .m_axis_adap_tx_250mhz_tready     (m_axis_cmac_tx_tready),

  // Receive packets from CMAC RX path
  .s_axis_adap_rx_250mhz_tvalid     (s_axis_cmac_rx_tvalid),
  .s_axis_adap_rx_250mhz_tdata      (s_axis_cmac_rx_tdata),
  .s_axis_adap_rx_250mhz_tkeep      (s_axis_cmac_rx_tkeep),
  .s_axis_adap_rx_250mhz_tlast      (s_axis_cmac_rx_tlast),
  .s_axis_adap_rx_250mhz_tuser_size (s_axis_cmac_rx_tuser_size),
  .s_axis_adap_rx_250mhz_tuser_src  (16'hffff),
  .s_axis_adap_rx_250mhz_tuser_dst  (16'hffff),
  .s_axis_adap_rx_250mhz_tready     (s_axis_cmac_rx_tready),

  // RoCEv2 packets from user logic box to rdma
  .m_axis_user2rdma_roce_from_cmac_rx_tvalid (cmac2rdma_roce_axis_tvalid),
  .m_axis_user2rdma_roce_from_cmac_rx_tdata  (cmac2rdma_roce_axis_tdata),
  .m_axis_user2rdma_roce_from_cmac_rx_tkeep  (cmac2rdma_roce_axis_tkeep),
  .m_axis_user2rdma_roce_from_cmac_rx_tlast  (cmac2rdma_roce_axis_tlast),
  .m_axis_user2rdma_roce_from_cmac_rx_tready (cmac2rdma_roce_axis_tready),

  // packets from rdma to user logic
  .s_axis_rdma2user_to_cmac_tx_tvalid        (rdma2cmac_axis_tvalid),
  .s_axis_rdma2user_to_cmac_tx_tdata         (rdma2cmac_axis_tdata),
  .s_axis_rdma2user_to_cmac_tx_tkeep         (rdma2cmac_axis_tkeep),
  .s_axis_rdma2user_to_cmac_tx_tlast         (rdma2cmac_axis_tlast),
  .s_axis_rdma2user_to_cmac_tx_tready        (rdma2cmac_axis_tready),

  // packets from user logic to rdma
  .m_axis_user2rdma_from_qdma_tx_tvalid      (qdma2rdma_non_roce_axis_tvalid),
  .m_axis_user2rdma_from_qdma_tx_tdata       (qdma2rdma_non_roce_axis_tdata),
  .m_axis_user2rdma_from_qdma_tx_tkeep       (qdma2rdma_non_roce_axis_tkeep),
  .m_axis_user2rdma_from_qdma_tx_tlast       (qdma2rdma_non_roce_axis_tlast),
  .m_axis_user2rdma_from_qdma_tx_tready      (qdma2rdma_non_roce_axis_tready),

  // ieth or immdt data from rdma packets
  .s_axis_rdma2user_ieth_immdt_tdata         (rdma2user_ieth_immdt_axis_tdata),
  .s_axis_rdma2user_ieth_immdt_tlast         (rdma2user_ieth_immdt_axis_tlast),
  .s_axis_rdma2user_ieth_immdt_tvalid        (rdma2user_ieth_immdt_axis_tvalid),
  .s_axis_rdma2user_ieth_immdt_trdy          (rdma2user_ieth_immdt_axis_trdy),

  // HW handshaking from user logic: Send WQE completion queue doorbell
  .s_resp_hndler_i_send_cq_db_cnt_valid(resp_hndler_o_send_cq_db_cnt_valid),
  .s_resp_hndler_i_send_cq_db_addr     (resp_hndler_o_send_cq_db_addr),
  .s_resp_hndler_i_send_cq_db_cnt      (resp_hndler_o_send_cq_db_cnt),
  .s_resp_hndler_o_send_cq_db_rdy      (resp_hndler_i_send_cq_db_rdy),

  // HW handshaking from user logic: Send WQE producer index doorbell
  .m_o_qp_sq_pidb_hndshk               (i_qp_sq_pidb_hndshk),
  .m_o_qp_sq_pidb_wr_addr_hndshk       (i_qp_sq_pidb_wr_addr_hndshk),
  .m_o_qp_sq_pidb_wr_valid_hndshk      (i_qp_sq_pidb_wr_valid_hndshk),
  .m_i_qp_sq_pidb_wr_rdy               (o_qp_sq_pidb_wr_rdy),

  // HW handshaking from user logic: RDMA-Send consumer index doorbell
  .m_o_qp_rq_cidb_hndshk               (i_qp_rq_cidb_hndshk),
  .m_o_qp_rq_cidb_wr_addr_hndshk       (i_qp_rq_cidb_wr_addr_hndshk),
  .m_o_qp_rq_cidb_wr_valid_hndshk      (i_qp_rq_cidb_wr_valid_hndshk),
  .m_i_qp_rq_cidb_wr_rdy               (o_qp_rq_cidb_wr_rdy),

  // HW handshaking from user logic: RDMA-Send producer index doorbell
  .s_rx_pkt_hndler_i_rq_db_data        (rx_pkt_hndler_o_rq_db_data),
  .s_rx_pkt_hndler_i_rq_db_addr        (rx_pkt_hndler_o_rq_db_addr),
  .s_rx_pkt_hndler_i_rq_db_data_valid  (rx_pkt_hndler_o_rq_db_data_valid),
  .s_rx_pkt_hndler_o_rq_db_rdy         (rx_pkt_hndler_i_rq_db_rdy),

  // AXI interface from the Compute Logic
  .m_axi_compute_logic_awid            (m_axi_compute_logic_awid),
  .m_axi_compute_logic_awaddr          (m_axi_compute_logic_awaddr),
  .m_axi_compute_logic_awqos           (m_axi_compute_logic_awqos),
  .m_axi_compute_logic_awlen           (m_axi_compute_logic_awlen),
  .m_axi_compute_logic_awsize          (m_axi_compute_logic_awsize),
  .m_axi_compute_logic_awburst         (m_axi_compute_logic_awburst),
  .m_axi_compute_logic_awcache         (m_axi_compute_logic_awcache),
  .m_axi_compute_logic_awprot          (m_axi_compute_logic_awprot),
  .m_axi_compute_logic_awvalid         (m_axi_compute_logic_awvalid),
  .m_axi_compute_logic_awready         (m_axi_compute_logic_awready),
  .m_axi_compute_logic_wdata           (m_axi_compute_logic_wdata),
  .m_axi_compute_logic_wstrb           (m_axi_compute_logic_wstrb),
  .m_axi_compute_logic_wlast           (m_axi_compute_logic_wlast),
  .m_axi_compute_logic_wvalid          (m_axi_compute_logic_wvalid),
  .m_axi_compute_logic_wready          (m_axi_compute_logic_wready),
  .m_axi_compute_logic_awlock          (m_axi_compute_logic_awlock),
  .m_axi_compute_logic_bid             (m_axi_compute_logic_bid),
  .m_axi_compute_logic_bresp           (m_axi_compute_logic_bresp),
  .m_axi_compute_logic_bvalid          (m_axi_compute_logic_bvalid),
  .m_axi_compute_logic_bready          (m_axi_compute_logic_bready),
  .m_axi_compute_logic_arid            (m_axi_compute_logic_arid),
  .m_axi_compute_logic_araddr          (m_axi_compute_logic_araddr),
  .m_axi_compute_logic_arlen           (m_axi_compute_logic_arlen),
  .m_axi_compute_logic_arsize          (m_axi_compute_logic_arsize),
  .m_axi_compute_logic_arburst         (m_axi_compute_logic_arburst),
  .m_axi_compute_logic_arcache         (m_axi_compute_logic_arcache),
  .m_axi_compute_logic_arprot          (m_axi_compute_logic_arprot),
  .m_axi_compute_logic_arvalid         (m_axi_compute_logic_arvalid),
  .m_axi_compute_logic_arready         (m_axi_compute_logic_arready),
  .m_axi_compute_logic_rid             (m_axi_compute_logic_rid),
  .m_axi_compute_logic_rdata           (m_axi_compute_logic_rdata),
  .m_axi_compute_logic_rresp           (m_axi_compute_logic_rresp),
  .m_axi_compute_logic_rlast           (m_axi_compute_logic_rlast),
  .m_axi_compute_logic_rvalid          (m_axi_compute_logic_rvalid),
  .m_axi_compute_logic_rready          (m_axi_compute_logic_rready),
  .m_axi_compute_logic_arlock          (m_axi_compute_logic_arlock),
  .m_axi_compute_logic_arqos           (m_axi_compute_logic_arqos),

  .mod_rstn     ({15'd0, axil_rstn}),
  .mod_rst_done (user_rst_done),

  .box_rstn     (axil_rstn),
  .box_rst_done (box_rst_done),

  .axil_aclk    (axil_aclk),
  .axis_aclk    (axis_aclk)
);

assign cmac2rdma_roce_axis_tuser  = 1'b1;
assign cmac2rdma_roce_axis_tready = 1'b1;

assign m_axis_cmac2rdma_roce_tdata  = cmac2rdma_roce_axis_tdata;
assign m_axis_cmac2rdma_roce_tkeep  = cmac2rdma_roce_axis_tkeep;
assign m_axis_cmac2rdma_roce_tvalid = cmac2rdma_roce_axis_tvalid;
assign m_axis_cmac2rdma_roce_tlast  = cmac2rdma_roce_axis_tlast;

endmodule: rdma_rn_roce_wrapper