import roceTypes::*;

//TODO: better control logic for multiple QP's (except maybe for conn interface)
module roce_stack_wq_manager #(
  parameter int NUM_QP = 256
)(
    input  logic [7:0]    QPidx_i,

    input  logic          conn_configured_i,
    input  logic          qp_configured_i,
    input  logic          sq_updated_i,

    input  logic [31:0]   CONF_i,

    input  logic [31:0]   QPCONFi_i,
    input  logic [23:0]   DESTQPCONFi_i,
    input  logic [31:0]   IPDESADDR1i_i,
    input  logic [47:0]   MACDESADDi_i,
    input  logic [23:0]   SQPSNi_i,
    input  logic [31:0]   LSTRQREQi_i,

    input  logic [63:0]   SQBAi_i,
    input  logic [63:0]   CQBAi_i,
    input  logic [31:0]   SQPIi_i,
    input  logic [31:0]   CQHEADi_i,

    output rd_cmd_t       rd_qp_o,
    output logic          rd_qp_valid_o,
    input  logic          rd_qp_ready_i,
    
    output logic [39:0]   WB_CQHEADi_o,
    output logic          WB_CQHEADi_valid_o,

    output logic          m_rdma_conn_interface_valid_o, 
    input  logic          m_rdma_conn_interface_ready_i,
    output rdma_qp_conn_t m_rdma_conn_interface_data_o,

    output logic          m_rdma_qp_interface_valid_o, 
    input  logic          m_rdma_qp_interface_ready_i,
    output rdma_qp_ctx_t  m_rdma_qp_interface_data_o,
    
    output logic          m_rdma_sq_interface_valid_o, 
    input  logic          m_rdma_sq_interface_ready_i,
    output dreq_t         m_rdma_sq_interface_data_o,

    input  logic          s_rdma_ack_valid_i,
    output logic          s_rdma_ack_ready_o,
    input  ack_t          s_rdma_ack_data_i,

    output logic          m_axi_qp_get_wqe_awid_o,
    output logic  [63:0]  m_axi_qp_get_wqe_awaddr_o,
    output logic  [7:0]   m_axi_qp_get_wqe_awlen_o,
    output logic  [2:0]   m_axi_qp_get_wqe_awsize_o,
    output logic  [1:0]   m_axi_qp_get_wqe_awburst_o,
    output logic  [3:0]   m_axi_qp_get_wqe_awcache_o,
    output logic  [2:0]   m_axi_qp_get_wqe_awprot_o,
    output logic          m_axi_qp_get_wqe_awvalid_o,
    input  logic          m_axi_qp_get_wqe_awready_i,
    output logic  [511:0] m_axi_qp_get_wqe_wdata_o,
    output logic  [63:0]  m_axi_qp_get_wqe_wstrb_o,
    output logic          m_axi_qp_get_wqe_wlast_o,
    output logic          m_axi_qp_get_wqe_wvalid_o,
    input  logic          m_axi_qp_get_wqe_wready_i,
    output logic          m_axi_qp_get_wqe_awlock_o,
    input  logic          m_axi_qp_get_wqe_bid_i,
    input  logic  [1:0]   m_axi_qp_get_wqe_bresp_i,
    input  logic          m_axi_qp_get_wqe_bvalid_i,
    output logic          m_axi_qp_get_wqe_bready_o,
    output logic          m_axi_qp_get_wqe_arid_o,
    output logic  [63:0]  m_axi_qp_get_wqe_araddr_o,
    output logic  [7:0]   m_axi_qp_get_wqe_arlen_o,
    output logic  [2:0]   m_axi_qp_get_wqe_arsize_o,
    output logic  [1:0]   m_axi_qp_get_wqe_arburst_o,
    output logic  [3:0]   m_axi_qp_get_wqe_arcache_o,
    output logic  [2:0]   m_axi_qp_get_wqe_arprot_o,
    output logic          m_axi_qp_get_wqe_arvalid_o,
    input  logic          m_axi_qp_get_wqe_arready_i,
    output logic          m_axi_qp_get_wqe_arlock_o,
    input  logic          m_axi_qp_get_wqe_rid_i,
    input  logic  [511:0] m_axi_qp_get_wqe_rdata_i,
    input  logic  [1:0]   m_axi_qp_get_wqe_rresp_i,
    input  logic          m_axi_qp_get_wqe_rlast_i,
    input  logic          m_axi_qp_get_wqe_rvalid_i,
    output logic          m_axi_qp_get_wqe_rready_o,

    input  logic          axis_aclk_i,
    input logic           axis_rstn_i
);



//handshakes between FSMs
logic fetch_wqe_d, fetch_wqe_q, fetch_wqe_ack;
logic new_wqe_fetched_d, new_wqe_fetched_q, new_wqe_fetched_ack;
logic qp_intf_done_d, qp_intf_done_q, qp_intf_done_ack;
logic completion_written;



rdma_qp_conn_t conn_ctx_d, conn_ctx_q;
rdma_qp_ctx_t qp_ctx_d, qp_ctx_q;
rd_cmd_t rd_qp_d, rd_qp_q;

dreq_t sq_req_d, sq_req_q;

logic [31:0] mtu_d, mtu_q;
logic [3:0] log_mtu_d, log_mtu_q;

logic [511:0] WQEReg_d, WQEReg_q;
logic [31:0]  CQReg_d, CQReg_q;



//////////////////////
//                  //
//  CONN INTERFACE  //
//                  //
//////////////////////

typedef enum {CONN_IDLE, CONN_IF_VALID, CONN_VALID} conn_state;
conn_state conn_state_d, conn_state_q;

always_comb begin
  m_rdma_conn_interface_valid_o = 1'b0;

  conn_state_d = conn_state_q;
  conn_ctx_d = conn_ctx_q;

  case(conn_state_q)
    CONN_IDLE: begin
      //should be safe, updating a reg takes a few cycles
      if(conn_configured_i) begin
        if(IPDESADDR1i_i != 'd0) begin
          conn_ctx_d.dest_mac_addr = MACDESADDi_i;
          conn_ctx_d.remote_udp_port = CONF_i[31:16];
          conn_ctx_d.remote_ip_address = {IPDESADDR1i_i, IPDESADDR1i_i, IPDESADDR1i_i, IPDESADDR1i_i};
          conn_ctx_d.remote_qpn = DESTQPCONFi_i;
          conn_ctx_d.local_qpn = {8'b0, QPidx_i};
          conn_state_d = CONN_VALID;
        end
      end
    end
    CONN_VALID: begin
      m_rdma_conn_interface_valid_o = 1'b1;
      if(m_rdma_conn_interface_ready_i) begin
        conn_state_d = CONN_IDLE;
      end
    end
  endcase
end


////////////////////
//                //
//  QP INTERFACE  //
//                //
////////////////////

typedef enum {QP_IDLE, QP_IF_VALID, QP_VALID, QP_SQ_RD_QP, QP_SQ_VALID, QP_SQ_DONE} qp_state;
qp_state qp_state_d, qp_state_q;

always_comb begin
  m_rdma_qp_interface_valid_o = 1'b0;
  rd_qp_valid_o = 1'b0;
  
  qp_state_d = qp_state_q;
  rd_qp_d = rd_qp_q;
  qp_ctx_d = qp_ctx_q;
  
  qp_intf_done_d = 1'b0;
  new_wqe_fetched_ack = 1'b0;

  case(qp_state_q) 
    QP_IDLE: begin
      if(qp_configured_i) begin
        //TODO: this might be unsafe if the FSM is busy, on the other hand, the chance of this breaking is relatively low
        if(QPCONFi_i[0] && QPCONFi_i[10:8] <= 3'b100) begin
          //these values are not necessary for the receiving side
          qp_ctx_d.vaddr = 'd0;
          qp_ctx_d.r_key = 'd0;
          qp_ctx_d.local_psn = SQPSNi_i;
          qp_ctx_d.remote_psn = LSTRQREQi_i[23:0] + 24'b1;
          qp_ctx_d.qp_num = {16'b0, QPidx_i};
          qp_ctx_d.new_state = 32'b0;
          qp_state_d = QP_VALID;
        end else begin
          qp_state_d = QP_IDLE;
        end  
      end else if (new_wqe_fetched_q) begin // update interface
        new_wqe_fetched_ack = 1'b1;
        rd_qp_d.region = 'd2;
        rd_qp_d.read_all = 1'b1;
        rd_qp_d.bram_idx = NUM_QP_REGS; //use max for ready_o
        rd_qp_d.address = sq_if_output_q.sq_idx;
        qp_state_d = QP_SQ_RD_QP;
      end
    end
    QP_SQ_RD_QP: begin
      rd_qp_valid_o = 1'b1;
      if( rd_qp_ready_i ) begin
        if(QPCONFi_i[0] && QPCONFi_i[10:8] <= 3'b100) begin 
          //update vaddr and RKEY of receciving side
          qp_ctx_d.vaddr = WQEReg_q[223:160];
          qp_ctx_d.r_key = WQEReg_q[255:224];
          qp_ctx_d.local_psn = SQPSNi_i;
          qp_ctx_d.remote_psn = LSTRQREQi_i[23:0] + 24'b1;
          qp_ctx_d.qp_num = {16'b0, QPidx_i};
          qp_ctx_d.new_state = 32'b0;
          qp_state_d = QP_SQ_VALID;
        end else begin
          qp_state_d = QP_IDLE;
        end  
      end
    end
    QP_VALID: begin
      m_rdma_qp_interface_valid_o = 1'b1;
      if(m_rdma_qp_interface_ready_i) begin
        qp_state_d = QP_IDLE;
      end
    end
    QP_SQ_VALID: begin
      m_rdma_qp_interface_valid_o = 1'b1;
      if(m_rdma_qp_interface_ready_i) begin
        qp_intf_done_d = 1'b1;
        qp_state_d = QP_SQ_DONE;
      end
    end
    QP_SQ_DONE: begin
      if(qp_intf_done_ack) begin
        qp_state_d = QP_IDLE;
      end else begin
        qp_intf_done_d = 1'b1;
      end
    end
  endcase
end

assign rd_qp_o = rd_qp_q;


////////////////////
//                //
//  SQ INTERFACE  //
//                //
////////////////////

SQdata_struct sq_fifo_input_d, sq_fifo_input_q, sq_fifo_output, sq_fifo_batch_output, sq_if_output_d, sq_if_output_q;
logic sq_fifo_batch_ready_rd, sq_fifo_batch_rd, sq_fifo_batch_ready_wr, sq_fifo_batch_wr;
logic sq_c_ena, sq_c_wea, cq_c_ena, cq_c_wea;
SQdata_struct sq_c_douta, sq_c_douta_d, sq_c_douta_q;
logic sq_c_enb, sq_c_web, cq_c_enb;
SQdata_struct sq_c_doutb, sq_c_doutb_d, sq_c_doutb_q;
logic[31:0] cq_c_doutb, cq_c_doutb_d, cq_c_doutb_q;

typedef enum {SQ_FIFO_IDLE, SQ_FIFO_VALID } sq_fifo_st;
sq_fifo_st sq_fifo_state_d, sq_fifo_state_q;

logic sq_fifo_ready_rd, sq_fifo_rd, sq_fifo_ready_wr, sq_fifo_wr;

always_comb begin
  sq_fifo_state_d = sq_fifo_state_q;
  sq_fifo_input_d = sq_fifo_input_q;
  sq_fifo_wr = 1'b0;

  case(sq_fifo_state_q)
    SQ_FIFO_IDLE: begin
      if(sq_updated_i && sq_fifo_ready_wr) begin //Assume all fields are set!
        sq_fifo_input_d.sq_prod_idx = SQPIi_i;
        sq_fifo_input_d.cq_head_idx = CQHEADi_i;
        sq_fifo_input_d.sq_idx = QPidx_i;
        sq_fifo_input_d.sq_base_addr = SQBAi_i;
        sq_fifo_input_d.cq_base_addr = CQBAi_i;
        sq_fifo_input_d.qp_conf = QPCONFi_i;
        sq_fifo_state_d = SQ_FIFO_VALID;
      end
    end
    SQ_FIFO_VALID: begin
      sq_fifo_wr = 1'b1;
      sq_fifo_state_d = SQ_FIFO_IDLE;
    end
  endcase
end

// fifo for new SQPIi updates
fifo # (
  .DATA_BITS(232),
  .FIFO_SIZE(8)
) sq_fifo (
  .rd(sq_fifo_rd),
	.wr(sq_fifo_wr),

	.ready_rd(sq_fifo_ready_rd),
	.ready_wr(sq_fifo_ready_wr),

	.data_in(sq_fifo_input_q),
  .data_out(sq_fifo_output),

  .aclk(axis_aclk_i),
  .aresetn(axis_rstn_i)
);


// fifo for WQE batch case
fifo # (
  .DATA_BITS(232),
  .FIFO_SIZE(8)
) sq_fifo_batch (
  .rd(sq_fifo_batch_rd),
	.wr(sq_fifo_batch_wr),

	.ready_rd(sq_fifo_batch_ready_rd),
	.ready_wr(sq_fifo_batch_ready_wr),

	.data_in(sq_c_doutb_q),
  .data_out(sq_fifo_batch_output),

  .aclk(axis_aclk_i),
  .aresetn(axis_rstn_i)
);

//Send Queue Cache
dp_bram #(
  .DATA_WIDTH(232),
  .BRAM_DEPTH(256),
  .ADDR_WIDTH(8)
) sq_cache_inst (
  .ena_i(sq_c_ena),
  .wea_i(sq_c_wea),
  .addra_i(sq_if_output_q.sq_idx),
  .dia_i(sq_if_output_q),
  .douta_o(sq_c_douta),
  
  .enb_i(sq_c_enb),
  .web_i(sq_c_web),
  .addrb_i(curr_ack_q.qp_num[7:0]),
  .dib_i(sq_c_doutb_q),
  .doutb_o(sq_c_doutb),
  
  .clk_i(axis_aclk_i),
  .rstn_i(axis_rstn_i)
);

//Completion Queue Cache
dp_bram #(
  .DATA_WIDTH(32),
  .BRAM_DEPTH(256),
  .ADDR_WIDTH(8)
) cq_cache_inst (
  .ena_i(cq_c_ena),
  .wea_i(cq_c_wea),
  .addra_i(sq_if_output_q.sq_idx),
  .dia_i(CQReg_q),
  .douta_o(),
  
  .enb_i(cq_c_enb),
  .web_i(1'b0),
  .addrb_i(curr_ack_q.qp_num[7:0]),
  .dib_i('d0),
  .doutb_o(cq_c_doutb),
  
  .clk_i(axis_aclk_i),
  .rstn_i(axis_rstn_i)
);



typedef enum {SQ_IDLE, SQ_GET_QUEUE, SQ_READ_CACHE, SQ_CHECK_QUEUE_BUSY, SQ_IF_READY, SQ_WAIT_QP, SQ_WRITE, SQ_SEND, SQ_READ, SQ_VALID, SQ_WRITE_CQ_CACHE} sq_state;
sq_state sq_state_d, sq_state_q;


logic last_d, last_q;
logic first_d, first_q;
logic [31:0] transfer_length_d, transfer_length_q;
logic [63:0] curr_local_paddr_d, curr_local_paddr_q, curr_remote_vaddr_d, curr_remote_vaddr_q;
logic [31:0] localidx_d, localidx_q;

always_comb begin
  m_rdma_sq_interface_valid_o = 1'b0;
  
  sq_state_d = sq_state_q;
  sq_if_output_d = sq_if_output_q;
  sq_c_douta_d = sq_c_douta_q;
  localidx_d = localidx_q;
  mtu_d = mtu_q;
  log_mtu_d = log_mtu_q;
  transfer_length_d = transfer_length_q;
  curr_local_paddr_d = curr_local_paddr_q;
  curr_remote_vaddr_d = curr_remote_vaddr_q;
  sq_req_d = sq_req_q;
  CQReg_d = CQReg_q;
  last_d = last_q;
  first_d = first_q;
  
  fetch_wqe_d = 1'b0;
  qp_intf_done_ack = 1'b0;
  
  sq_fifo_rd = 1'b0;
  sq_fifo_batch_rd = 1'b0;
  sq_c_ena = 1'b0;
  sq_c_wea = 1'b0;
  cq_c_ena = 1'b0;
  cq_c_wea = 1'b0;

  case(sq_state_q)
    SQ_IDLE: begin
      if(sq_fifo_ready_rd) begin // this is SQ data updated by the user
        sq_fifo_rd = 1'b1;
        sq_if_output_d = sq_fifo_output; 
        sq_state_d = SQ_GET_QUEUE;
      end else if (sq_fifo_batch_ready_rd) begin
        sq_fifo_batch_rd = 1'b1;
        sq_if_output_d = sq_fifo_batch_output;
        sq_state_d = SQ_IF_READY;
      end
    end
    SQ_GET_QUEUE: begin
      sq_c_ena = 1'b1;
      sq_state_d = SQ_READ_CACHE;
    end
    SQ_READ_CACHE: begin
      sq_c_douta_d = sq_c_douta;
      if(sq_c_douta.sq_prod_idx != 0) begin //cq head idx might be out of sync
        sq_if_output_d.cq_head_idx = sq_c_douta.cq_head_idx;
      end
      sq_state_d = SQ_CHECK_QUEUE_BUSY;
    end
    SQ_CHECK_QUEUE_BUSY: begin
      if(sq_c_douta_q.sq_prod_idx == 'd0) begin //the last actions of the queue were successful or its the first time this queue is used
        sq_state_d = SQ_IF_READY;
      end else begin //in this case, something was updated
        sq_state_d = SQ_IDLE;
      end
      sq_c_ena = 1'b1;
      sq_c_wea = 1'b1;
    end
    SQ_IF_READY: begin
      if(sq_if_output_q.sq_prod_idx <= sq_if_output_q.cq_head_idx) begin //sanity check
        sq_state_d = SQ_IDLE;
      end else begin
        localidx_d = sq_if_output_q.cq_head_idx;
        //mtu_d = 'd256 << sq_if_output_q.qp_conf[10:8];
        //log_mtu_d = 'd8 + {1'b0, sq_if_output_q.qp_conf[10:8]};
        mtu_d = 'd4096; //fix to configured mtu in cmake of roce stack
        log_mtu_d = 'd12;
        if(fetch_wqe_ack) begin
          sq_state_d = SQ_WAIT_QP;
        end else begin
          fetch_wqe_d = 1'b1;
        end
      end
    end
    SQ_WAIT_QP: begin
      //TODO: FIFO for all WQE's fetched in current execution, use burst feature of AXI MM
      //A new WQE is fetched, start examining it...
      if(qp_intf_done_q) begin
        qp_intf_done_ack = 1'b1;
        if(WQEReg_q[135:128] == 8'h00) begin
          //WRITE
          $display("write command");
          sq_state_d = SQ_WRITE;
        end else if(WQEReg_q[135:128] == 8'h02) begin
          $display("send command");
          sq_state_d = SQ_SEND;
        end else if(WQEReg_q[135:128] == 8'h04) begin
          //READ
          $display("read command");
          sq_state_d = SQ_READ;
        end
      end
    end
    SQ_WRITE: begin
      if(first_q) begin
        //case only
        if(WQEReg_q[127:96] <= mtu_q) begin
          sq_req_d.req_1.opcode = RC_RDMA_WRITE_ONLY;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b1;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = WQEReg_q[223:160];
          sq_req_d.req_1.len    = WQEReg_q[127:96];
          sq_req_d.req_1.rsrvd  = 'd0;

          sq_req_d.req_2.vaddr  = WQEReg_q[95:32];
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = WQEReg_q[127:96];
          sq_req_d.req_2.rsrvd  = 'd0;
          
          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        //case first
        end else begin         
          sq_req_d.req_1.opcode = RC_RDMA_WRITE_FIRST;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b0;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = WQEReg_q[223:160];
          sq_req_d.req_1.len    = mtu_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = WQEReg_q[95:32];
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = mtu_q;
          sq_req_d.req_2.rsrvd  = 'd0;


          transfer_length_d = WQEReg_q[127:96] - mtu_q;
          curr_local_paddr_d = WQEReg_q[95:32] + mtu_q;
          curr_remote_vaddr_d = WQEReg_q[223:160] + mtu_q;
          last_d = 1'b0;
          first_d = 1'b0;
          sq_state_d = SQ_VALID;
        end
      end else begin
        //case last
        if(transfer_length_q <= mtu_q) begin
          sq_req_d.req_1.opcode = RC_RDMA_WRITE_LAST;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b1;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = curr_remote_vaddr_q;
          sq_req_d.req_1.len    = transfer_length_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = curr_local_paddr_q;
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = transfer_length_q;
          sq_req_d.req_2.rsrvd  = 'd0;

          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        //case middle
        end else begin
          sq_req_d.req_1.opcode = RC_RDMA_WRITE_MIDDLE;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b0;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = curr_remote_vaddr_q;
          sq_req_d.req_1.len    = mtu_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = curr_local_paddr_q;
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = mtu_q;
          sq_req_d.req_2.rsrvd  = 'd0;
          
          transfer_length_d = transfer_length_q - mtu_q;
          curr_local_paddr_d = curr_local_paddr_q + mtu_q;
          curr_remote_vaddr_d = curr_remote_vaddr_q + mtu_q;
          last_d = 1'b0;
          first_d = 1'b0;
          sq_state_d = SQ_VALID;
        end
      end
    end
    SQ_SEND: begin
      if(first_q) begin
        //case only
        if(WQEReg_q[127:96] <= mtu_q) begin
          sq_req_d.req_1.opcode = RC_SEND_ONLY;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b1;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = 'd0;
          sq_req_d.req_1.len    = WQEReg_q[127:96];
          sq_req_d.req_1.rsrvd  = 'd0;

          sq_req_d.req_2.vaddr  = WQEReg_q[95:32]; 
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = WQEReg_q[127:96];
          sq_req_d.req_2.rsrvd        = 'd0;
          
          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        //case first
        end else begin         
          sq_req_d.req_1.opcode = RC_SEND_FIRST;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b0;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = 'd0;
          sq_req_d.req_1.len    = mtu_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = WQEReg_q[95:32];
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = mtu_q;
          sq_req_d.req_2.rsrvd  = 'd0;


          transfer_length_d = WQEReg_q[127:96] - mtu_q;
          curr_local_paddr_d = WQEReg_q[95:32] + mtu_q;
          last_d = 1'b0;
          first_d = 1'b0;
          sq_state_d = SQ_VALID;
        end
      end else begin
        //case last
        if(transfer_length_q <= mtu_q) begin
          sq_req_d.req_1.opcode = RC_SEND_LAST;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b1;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = 'd0;
          sq_req_d.req_1.len    = transfer_length_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = curr_local_paddr_q;
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = transfer_length_q;
          sq_req_d.req_2.rsrvd  = 'd0;

          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        //case middle
        end else begin
          sq_req_d.req_1.opcode = RC_SEND_MIDDLE;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b0;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = 'd0;
          sq_req_d.req_1.len    = mtu_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = curr_local_paddr_q;
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = mtu_q;
          sq_req_d.req_2.rsrvd  = 'd0;
          
          transfer_length_d = transfer_length_q - mtu_q;
          curr_local_paddr_d = curr_local_paddr_q + mtu_q;
          last_d = 1'b0;
          first_d = 1'b0;
          sq_state_d = SQ_VALID;
        end
      end
    end
    SQ_READ: begin
      sq_req_d.req_1.opcode = RC_RDMA_READ_REQUEST;
      sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
      sq_req_d.req_1.last   = 1'b1;
      sq_req_d.req_1.offs   = 4'b0;
      sq_req_d.req_1.vaddr  = WQEReg_q[223:160];
      sq_req_d.req_1.len    = WQEReg_q[127:96];
      sq_req_d.req_1.rsrvd  = 'd0;
          
      sq_req_d.req_2.vaddr  = WQEReg_q[95:32];
      sq_req_d.req_2.offs   = 4'b0;
      sq_req_d.req_2.len    = WQEReg_q[127:96];
      sq_req_d.req_2.rsrvd  = 'd0;
      
      last_d = 1'b1;
      sq_state_d = SQ_VALID;
    end
    SQ_VALID: begin
      m_rdma_sq_interface_valid_o = 1'b1;
      if(m_rdma_sq_interface_ready_i) begin
        if(last_q) begin
          last_d = 1'b0;
          first_d = 1'b1;
          CQReg_d[15:0] = WQEReg_q[15:0];
          CQReg_d[23:16] = WQEReg_q[135:128];
          CQReg_d[31:24] = 'd0; //TODO: errors??
          sq_state_d = SQ_WRITE_CQ_CACHE;
        end else if(WQEReg_q[135:128] == 8'h00) begin
          sq_state_d = SQ_WRITE;
        end else if(WQEReg_q[135:128] == 8'h02) begin
          sq_state_d = SQ_SEND;
        end
      end
    end
    SQ_WRITE_CQ_CACHE: begin
      cq_c_ena = 1'b1;
      cq_c_wea = 1'b1;
      sq_state_d = SQ_IDLE;
    end
  endcase
end


///////////////////
//               // 
// ACK INTERFACE //
//               //
///////////////////


typedef enum {ACK_IDLE, ACK_GET_CACHES, ACK_READ_CACHES, ACK_UPDATE_CQHEAD, ACK_WRITE_COMPLETION, ACK_WB_FIFO_CACHE, ACK_FINISH} cq_state;
ack_t curr_ack_d, curr_ack_q;
cq_state cq_state_d, cq_state_q;
logic write_completion;

always_comb begin
  WB_CQHEADi_valid_o = 1'b0;
  s_rdma_ack_ready_o = 1'b0;
  
  cq_state_d = cq_state_q;
  curr_ack_d = curr_ack_q;
  sq_c_doutb_d = sq_c_doutb_q;
  cq_c_doutb_d = cq_c_doutb_q;
  
  write_completion = 1'b0;
  sq_c_enb = 1'b0;
  sq_c_web = 1'b0;
  cq_c_enb = 1'b0;
  sq_fifo_batch_wr = 1'b0;

  case(cq_state_q)
    ACK_IDLE: begin
      if(s_rdma_ack_valid_i) begin
        curr_ack_d = s_rdma_ack_data_i;
        s_rdma_ack_ready_o = 1'b1;
        cq_state_d = ACK_GET_CACHES;
      end
    end
    ACK_GET_CACHES: begin
      sq_c_enb = 1'b1;
      cq_c_enb = 1'b1;
      cq_state_d = ACK_READ_CACHES;
    end
    ACK_READ_CACHES: begin
      sq_c_doutb_d = sq_c_doutb;
      sq_c_doutb_d.cq_head_idx = sq_c_doutb.cq_head_idx + 1;
      cq_c_doutb_d = cq_c_doutb;
      cq_state_d = ACK_UPDATE_CQHEAD;
    end
    ACK_UPDATE_CQHEAD: begin
      WB_CQHEADi_valid_o = 1'b1;
      if(sq_c_doutb_q.qp_conf[5]) begin
        write_completion = 1'b1;
        cq_state_d = ACK_WRITE_COMPLETION;
      end else begin
        cq_state_d = ACK_WB_FIFO_CACHE;
      end
    end
    ACK_WRITE_COMPLETION: begin
      if(completion_written) begin 
        cq_state_d = ACK_WB_FIFO_CACHE;
      end
    end
    ACK_WB_FIFO_CACHE: begin
      if(sq_c_doutb_q.cq_head_idx >= sq_c_doutb_q.sq_prod_idx) begin
        sq_c_doutb_d.sq_prod_idx = 'd0; //batch finished, sq prod idx has to be updated by the user
      end
      cq_state_d = ACK_FINISH;
    end
    ACK_FINISH:begin
      sq_c_enb = 1'b1;
      sq_c_web = 1'b1;
      if(sq_c_doutb_q.sq_prod_idx != 'd0) begin
        if(sq_fifo_batch_ready_wr) begin
          sq_fifo_batch_wr = 1'b1;
          cq_state_d = ACK_IDLE;
        end
      end else begin
        cq_state_d = ACK_IDLE;
      end
    end
  endcase
end


assign WB_CQHEADi_o[39:32] = sq_c_doutb_q.sq_idx;
assign WB_CQHEADi_o[31:0]  = sq_c_doutb_q.cq_head_idx;



//////////////////////
//                  //
// AXI MASTER WRITE //
//                  //
//////////////////////

typedef enum {AW_IDLE, AW_CALC_ADDR, AW_VALID, WR_WRITING, WR_BRESP, WR_DONE} aw_state;
aw_state AddrWr_State_d, AddrWr_State_q;
logic [63:0] WrAddrReg_d, WrAddrReg_q;


//TODO: use strb instead of address here (512bits => 64 bytes, here only 4 bytes are written per transaction)
always_comb begin
  m_axi_qp_get_wqe_awvalid_o = 1'b0;
  m_axi_qp_get_wqe_wlast_o = 1'b0;
  m_axi_qp_get_wqe_wvalid_o = 1'b0;
  m_axi_qp_get_wqe_bready_o = 1'b1;
  completion_written = 1'b0;
  WrAddrReg_d = WrAddrReg_q;
  AddrWr_State_d = AddrWr_State_q;
  

  case(AddrWr_State_q)
    AW_IDLE: begin
      if(write_completion) begin
        AddrWr_State_d = AW_CALC_ADDR;
      end
    end
    AW_CALC_ADDR: begin
      WrAddrReg_d = {sq_c_doutb_q.cq_base_addr[63:34], (sq_c_doutb_q.cq_base_addr[33:2] + (sq_c_doutb_q.cq_head_idx - 1)), sq_c_doutb_q.cq_base_addr[1:0]};
      AddrWr_State_d = AW_VALID;
    end
    AW_VALID: begin
      m_axi_qp_get_wqe_awvalid_o = 1'b1;
      if(m_axi_qp_get_wqe_awready_i) begin
        AddrWr_State_d = WR_WRITING;
      end
    end
    WR_WRITING: begin
      m_axi_qp_get_wqe_wlast_o = 1'b1; //only one transaction here
      m_axi_qp_get_wqe_wvalid_o = 1'b1;
      if(m_axi_qp_get_wqe_wready_i) begin
        AddrWr_State_d = WR_DONE; 
      end
    end
    WR_BRESP: begin //TODO: bresp ??
      if(m_axi_qp_get_wqe_bvalid_i) begin
        AddrWr_State_d = WR_DONE;
      end
    end
    WR_DONE: begin
      completion_written = 1'b1;
      AddrWr_State_d = AW_IDLE;
    end
  endcase
end

/////////////////////
//                 //
// AXI MASTER READ //
//                 //
/////////////////////


typedef enum {AR_IDLE, AR_CALC_ADDR, AR_VALID, RD_READING, RD_DONE} ar_state;
ar_state AddrRd_State_d, AddrRd_State_q;
logic [63:0] RdAddrReg_d, RdAddrReg_q;


//TODO: read all wqe's in a burst and put them in a FIFO
always_comb begin
  m_axi_qp_get_wqe_arvalid_o = 1'b0;
  m_axi_qp_get_wqe_rready_o = 1'b0;
  RdAddrReg_d = RdAddrReg_q;
  AddrRd_State_d = AddrRd_State_q;
  fetch_wqe_ack = 1'b0;
  WQEReg_d = WQEReg_q;
  new_wqe_fetched_d = 1'b0;

  case(AddrRd_State_q)
    AR_IDLE: begin
      //new elements in work queue
      if (fetch_wqe_q) begin
        fetch_wqe_ack = 1'b1;
        AddrRd_State_d = AR_CALC_ADDR; 
      end
    end
    AR_CALC_ADDR: begin
      //64 byte aligned 
      RdAddrReg_d = {sq_if_output_q.sq_base_addr[63:38], sq_if_output_q.sq_base_addr[37:6] + localidx_q, sq_if_output_q.sq_base_addr[5:0]};
      AddrRd_State_d = AR_VALID;
    end
    AR_VALID: begin
      m_axi_qp_get_wqe_arvalid_o = 1'b1;
      if(m_axi_qp_get_wqe_arready_i) begin
        m_axi_qp_get_wqe_rready_o = 1'b1;
        AddrRd_State_d = RD_READING;
      end
    end
    RD_READING: begin
      //TODO: implement fifo for burst transactions
      m_axi_qp_get_wqe_rready_o = 1'b1;
      if(m_axi_qp_get_wqe_rvalid_i) begin
        WQEReg_d = m_axi_qp_get_wqe_rdata_i;
        if(m_axi_qp_get_wqe_rlast_i) begin
          //directly update QP interface after read
          AddrRd_State_d = RD_DONE;
          new_wqe_fetched_d = 1'b1;
        end
      end
    end
    RD_DONE: begin
      if(new_wqe_fetched_ack) begin
        AddrRd_State_d = AR_IDLE;
      end else begin
        new_wqe_fetched_d = 1'b1;
      end
    end
  endcase
end


//blank write channel
assign m_axi_qp_get_wqe_awid_o = 1'b0;
assign m_axi_qp_get_wqe_awaddr_o = WrAddrReg_q;
assign m_axi_qp_get_wqe_awlen_o = 'd0;
assign m_axi_qp_get_wqe_awsize_o = 'd2;
assign m_axi_qp_get_wqe_awburst_o = 2'b01;
assign m_axi_qp_get_wqe_awcache_o = 4'h2;
assign m_axi_qp_get_wqe_awprot_o = 3'b010;
assign m_axi_qp_get_wqe_awlock_o = 1'b0;


assign m_axi_qp_get_wqe_wdata_o = {480'd0, cq_c_doutb_q};
assign m_axi_qp_get_wqe_wstrb_o = 'h0000000F;


//settings for ar signal
assign m_axi_qp_get_wqe_arid_o    = 1'b1;
assign m_axi_qp_get_wqe_araddr_o  = RdAddrReg_q;
assign m_axi_qp_get_wqe_arlen_o   = 'd0;      //TODO: might be able to read all outstanding wqe in one go! (len - 1)
assign m_axi_qp_get_wqe_arsize_o  = 'd6;     //(clog2(512/8))
assign m_axi_qp_get_wqe_arburst_o = 2'b01;  //increment, ignored if no burst
assign m_axi_qp_get_wqe_arcache_o = 4'h2;   // no cache, no buffer
assign m_axi_qp_get_wqe_arprot_o  = 3'b010;  // unpriviledged, nonsecure, data access
assign m_axi_qp_get_wqe_arlock_o  = 1'b0;    // normal signaling


assign m_rdma_conn_interface_data_o = conn_ctx_q;
assign m_rdma_qp_interface_data_o = qp_ctx_q;
assign m_rdma_sq_interface_data_o = sq_req_q;

  

always_ff @(posedge axis_aclk_i, negedge axis_rstn_i) begin
  if(!axis_rstn_i) begin
    //conn interface
    conn_state_q        <= CONN_IDLE;
    conn_ctx_q          <= 'd0;
    
    //qp interface
    qp_state_q          <= QP_IDLE;
    rd_qp_q             <= 'd0;
    qp_ctx_q            <= 'd0;
    qp_intf_done_q      <= 1'b0;
    
    //sq fifo
    sq_fifo_state_q     <= SQ_FIFO_IDLE;
    sq_fifo_input_q     <= 'd0;
    
    //sq interface
    sq_state_q          <= SQ_IDLE;
    sq_if_output_q      <= 'd0;
    sq_c_douta_q        <= 'd0;
    localidx_q          <= 'd0;
    mtu_q               <= 'd0;
    log_mtu_q           <= 'd0;
    transfer_length_q   <= 'd0;
    curr_local_paddr_q  <= 'd0;
    curr_remote_vaddr_q <= 'd0;
    sq_req_q            <= 'd0;
    CQReg_q             <= 'd0;
    last_q              <= 1'b0;
    first_q             <= 1'b1;
    fetch_wqe_q         <= 1'b0;
    
    //ack interface
    cq_state_q          <= ACK_IDLE;
    curr_ack_q          <= 'd0;
    sq_c_doutb_q        <= 'd0;
    cq_c_doutb_q        <= 'd0;
    
    //AXI write channel
    AddrWr_State_q      <= AW_IDLE;
    WrAddrReg_q         <= 'd0;

    //AXI read channel
    AddrRd_State_q      <= AR_IDLE;
    RdAddrReg_q         <= 'd0;
    WQEReg_q            <= 'd0;
    new_wqe_fetched_q   <= 1'b0;
  end else begin
    //conn interface
    conn_state_q        <= conn_state_d;
    conn_ctx_q          <= conn_ctx_d;
    
    //qp interface
    qp_state_q          <= qp_state_d;
    rd_qp_q             <= rd_qp_d;
    qp_ctx_q            <= qp_ctx_d;
    qp_intf_done_q      <= qp_intf_done_d;
    
    //sq fifo
    sq_fifo_state_q     <= sq_fifo_state_d;
    sq_fifo_input_q     <= sq_fifo_input_d;
    
    //sq interface
    sq_state_q          <= sq_state_d;
    sq_if_output_q      <= sq_if_output_d;
    sq_c_douta_q        <= sq_c_douta_d;
    localidx_q          <= localidx_d;
    mtu_q               <= mtu_d;
    log_mtu_q           <= log_mtu_d;
    transfer_length_q   <= transfer_length_d;
    curr_local_paddr_q  <= curr_local_paddr_d;
    curr_remote_vaddr_q <= curr_remote_vaddr_d;
    sq_req_q            <= sq_req_d;
    CQReg_q             <= CQReg_d;
    last_q              <= last_d;
    first_q             <= first_d;
    fetch_wqe_q         <= fetch_wqe_d;
    
    //ack interface
    cq_state_q          <= cq_state_d;
    curr_ack_q          <= curr_ack_d;
    sq_c_doutb_q        <= sq_c_doutb_d;
    cq_c_doutb_q        <= cq_c_doutb_d;
    
    //AXI write channel
    AddrWr_State_q      <= AddrWr_State_d;
    WrAddrReg_q         <= WrAddrReg_d;
    
    //AXI read channel
    AddrRd_State_q      <= AddrRd_State_d;
    RdAddrReg_q         <= RdAddrReg_d;
    WQEReg_q            <= WQEReg_d;
    new_wqe_fetched_q   <= new_wqe_fetched_d;
  end
end

endmodule: roce_stack_wq_manager