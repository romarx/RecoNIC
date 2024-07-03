import roceTypes::*;

//TODO: better control logic for multiple QP's (except maybe for conn interface)
module roce_stack_wq_manager #(
  parameter int NUM_QP = 8
)(
    input  logic [7:0]    SQidx_i,
    input  logic [7:0]    QPidx_i,
    input  logic [7:0]    connidx_i,

    output logic [7:0]    C_SQidx_o,

    input  logic          conn_configured_i,
    input  logic          qp_configured_i,

    input  logic [31:0]   CONF_i,

    input  logic [31:0]   QPCONFi_i,
    input  logic [23:0]   DESTQPCONFi_i,
    input  logic [31:0]   IPDESADDR1i_i,
    input  logic [23:0]   SQPSNi_i,
    input  logic [31:0]   LSTRQREQi_i,

    input  logic [63:0]   SQBAi_i,
    input  logic [31:0]   SQPIi_i,
    input  logic [31:0]   CQHEADi_i,
    input  logic [63:0]   VIRTADDR_i,
    
    output logic [7:0]    wr_ptr_o,
    output logic [31:0]   CQHEADi_o,

    output logic          m_rdma_conn_interface_valid_o, 
    input  logic          m_rdma_conn_interface_ready_i,
    output rdma_qp_conn_t m_rdma_conn_interface_data_o,

    output logic          m_rdma_qp_interface_valid_o, 
    input  logic          m_rdma_qp_interface_ready_i,
    output rdma_qp_ctx_t  m_rdma_qp_interface_data_o,
    
    output logic          m_rdma_sq_interface_valid_o, 
    input  logic          m_rdma_sq_interface_ready_i,
    output dreq_t         m_rdma_sq_interface_data_o,

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

    input  logic          axil_aclk_i,
    input  logic          axis_aclk_i,
    input  logic          rstn_i
);


conndata_struct conn_if_input_d, conn_if_input_q, conn_if_output_d, conn_if_output_q;
QPdata_struct qp_if_input_d, qp_if_input_q, qp_if_output_d, qp_if_output_q;
SQdata_struct sq_if_input_d, sq_if_input_q, sq_if_output_d, sq_if_output_q;

logic [31:0] localidx_d[NUM_QP-1:0], localidx_q[NUM_QP-1:0], localpi_d[NUM_QP-1:0], localpi_q[NUM_QP-1:0];
logic [31:0] SQPIi_tmp;
logic [7:0]  QPidx_tmp;
logic fetch_wqe;
logic fetch_next_wqe;
logic wqe_done;



rdma_qp_conn_t conn_ctx_d, conn_ctx_q;
rdma_qp_ctx_t qp_ctx_d, qp_ctx_q;

dreq_t sq_req_d, sq_req_q;

logic [31:0] mtu_d, mtu_q;

logic [511:0] WQEReg_d, WQEReg_q;


logic new_wqe_fetched;
logic qp_intf_done;


//////////////////////
//                  //
//  CONN INTERFACE  //
//                  //
//////////////////////

//AXIL CLOCK DOMAIN

always_comb begin
  conn_if_input_d = conn_if_input_q;
  if(conn_configured_i) begin
    conn_if_input_d.conn_idx      = connidx_i;
    conn_if_input_d.dest_qp       = DESTQPCONFi_i;
    conn_if_input_d.dest_ip_addr  = IPDESADDR1i_i;
    conn_if_input_d.port          = CONF_i[31:16];
  end
end

//AXIS CLOCK DOMAIN

typedef enum {CONN_IDLE, CONN_IF_VALID, CONN_VALID} conn_state;
conn_state conn_state_d, conn_state_q;

always_comb begin
  
  m_rdma_conn_interface_valid_o = 1'b0;
  conn_if_output_d = conn_if_output_q;
  conn_state_d = conn_state_q;
  conn_ctx_d = conn_ctx_q;

  case(conn_state_q)
    CONN_IDLE: begin
      //should be safe, updating a reg takes a few cycles
      if(conn_if_output_q != conn_if_input_q) begin
        conn_if_output_d = conn_if_input_q;
        conn_state_d = CONN_IF_VALID;
      end
    end
    CONN_IF_VALID: begin
      if(conn_if_output_q.dest_ip_addr != 'd0) begin
        conn_ctx_d.remote_udp_port = conn_if_output_q.port;
        conn_ctx_d.remote_ip_address = {conn_if_output_q.dest_ip_addr, conn_if_output_q.dest_ip_addr, conn_if_output_q.dest_ip_addr, conn_if_output_q.dest_ip_addr};
        conn_ctx_d.remote_qpn = conn_if_output_q.dest_qp - 24'b1;
        conn_ctx_d.local_qpn = {8'b0, conn_if_output_q.conn_idx};
        
        conn_state_d = CONN_VALID;
      end else begin
        conn_state_d = CONN_IDLE;
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


//AXIL CLOCK DOMAIN
always_comb begin
  qp_if_input_d = qp_if_input_q;
  if(qp_configured_i) begin  
      qp_if_input_d.qp_idx        = QPidx_i;
      qp_if_input_d.src_qp_conf   = QPCONFi_i;
      qp_if_input_d.dest_qp       = DESTQPCONFi_i;
      qp_if_input_d.sq_psn        = SQPSNi_i;
      qp_if_input_d.dest_sq_psn   = LSTRQREQi_i[23:0];
  end
   
end


//AXIS CLOCK DOMAIN
typedef enum {QP_IDLE, QP_IF_VALID, QP_VALID, QP_SQ_VALID} qp_state;
qp_state qp_state_d, qp_state_q;

always_comb begin
  qp_state_d = qp_state_q;
  qp_if_output_d = qp_if_output_q;
  mtu_d = mtu_q;
  qp_ctx_d = qp_ctx_q;
  m_rdma_qp_interface_valid_o = 1'b0;
  qp_intf_done = 1'b0;

  case(qp_state_q) //TODO: two things can happen here.....
    QP_IDLE: begin
      if(qp_if_output_q != qp_if_input_q) begin
        qp_if_output_d = qp_if_input_q;
        qp_state_d = QP_IF_VALID;
      end else if (new_wqe_fetched) begin //TODO: take sq idx here!
        if(qp_if_output_q.src_qp_conf[0] && qp_if_output_q.src_qp_conf[10:8] <= 3'b100) begin //if it's wrongly configured, don't proceed.
          qp_ctx_d.vaddr = WQEReg_q[223:160]; //remote vaddr
          qp_ctx_d.r_key = WQEReg_q[255:224]; // remote rkey (tag??)
          qp_ctx_d.local_psn = qp_if_output_q.dest_sq_psn + 24'b1; //TODO: check if this is a simulation problem, probably is
          qp_ctx_d.remote_psn = qp_if_output_q.sq_psn;
          qp_ctx_d.qp_num = {16'b0, qp_if_output_q.qp_idx};
          qp_ctx_d.new_state = 32'b0;
          
          qp_state_d = QP_SQ_VALID;
        end
      end
    end
    QP_IF_VALID: begin
        // only proceed if qp is enabled and mtu conf is valid
        if(qp_if_output_q.src_qp_conf[0] && qp_if_output_q.src_qp_conf[10:8] <= 3'b100) begin
          mtu_d = 'd256 << qp_if_output_q.src_qp_conf[10:8];
          //Maybe WQEReg is not yet set but who cares, these values are pointless anyway.........
          qp_ctx_d.vaddr = WQEReg_q[223:160];
          qp_ctx_d.r_key = WQEReg_q[255:224];
          qp_ctx_d.local_psn = qp_if_output_q.sq_psn;
          qp_ctx_d.remote_psn = qp_if_output_q.dest_sq_psn + 24'b1;
          qp_ctx_d.qp_num = {16'b0, qp_if_output_q.qp_idx};
          qp_ctx_d.new_state = 32'b0;          
          
          qp_state_d = QP_VALID;
        end else begin
          qp_state_d = QP_IDLE;
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
        qp_intf_done = 1'b1;
        qp_state_d = QP_IDLE;
      end
    end
  endcase
end


////////////////////
//                //
//  SQ INTERFACE  //
//                //
////////////////////

//TODO: This interface might actually need a FIFO, if SQPIi updates on another queue but the WQE's of the previous one didn't finish yet.
//also make a separate index for sqpii
//AXIL CLOCK DOMAIN

typedef enum {SQ_FIFO_IDLE, SQ_FIFO_VALID } sq_fifo_st;
sq_fifo_st sq_fifo_state_d, sq_fifo_state_q;

logic sq_fifo_full, sq_fifo_wr_en, sq_fifo_wr_ack, sq_fifo_wr_rst_busy;
logic sq_fifo_empty, sq_fifo_rd_en, sq_fifo_rd_valid, sq_fifo_rd_rst_busy;

always_comb begin
  sq_if_input_d = sq_if_input_q;
  for(int i=0; i < NUM_QP; i++) begin
    localpi_d[i] = localpi_q[i];
  end
  sq_fifo_state_d = sq_fifo_state_q;
  sq_fifo_wr_en = 1'b0;

  case(sq_fifo_state_q)
    SQ_FIFO_IDLE: begin
      if(SQPIi_i > localpi_q[SQidx_i] && !sq_fifo_full && !sq_fifo_wr_rst_busy) begin //Assume all fields are set on SQPIi increase
        localpi_d[SQidx_i] = SQPIi_i;
        sq_if_input_d.sq_prod_idx = SQPIi_i;
        sq_if_input_d.sq_idx = SQidx_i;
        sq_if_input_d.sq_base_addr = SQBAi_i;
        sq_if_input_d.pd_vaddr = VIRTADDR_i;
        sq_fifo_state_d = SQ_FIFO_VALID;
      end
    end
    SQ_FIFO_VALID: begin
      sq_fifo_wr_en = 1'b1;
      if(sq_fifo_wr_ack) begin
        sq_fifo_state_d = SQ_FIFO_IDLE;
      end
    end
  endcase
end


cdc_fifo_sq cdc_fifo_sq_inst (
  .full(sq_fifo_full),
  .din(sq_if_input_q),
  .wr_en(sq_fifo_wr_en),
  .wr_ack(sq_fifo_wr_ack),

  .empty(sq_fifo_empty),
  .dout(sq_if_output_d),
  .rd_en(sq_fifo_rd_en),
  .valid(sq_fifo_rd_valid),

  .wr_clk(axil_aclk_i),
  .rd_clk(axis_aclk_i),
  .srst(!rstn_i),
  .wr_rst_busy(sq_fifo_wr_rst_busy),
  .rd_rst_busy(sq_fifo_rd_rst_busy)
);


//AXIS CLOCK DOMAIN
//TODO: get the values!!!!
typedef enum {SQ_IF_IDLE, SQ_OUT_VALID, SQ_IF_VALID} sq_if_state;
sq_if_state sq_if_state_d, sq_if_state_q;

always_comb begin
  sq_if_state_d = sq_if_state_q;
  fetch_wqe = 1'b0;
  sq_fifo_rd_en = 1'b0;

  case(sq_if_state_q) 
    SQ_IF_IDLE: begin
      if(wqe_done && !sq_fifo_empty && !sq_fifo_rd_rst_busy) begin
        sq_if_state_d = SQ_OUT_VALID;
      end
    end
    SQ_OUT_VALID: begin
      sq_fifo_rd_en = 1'b1;
      if(sq_fifo_rd_valid) begin
        if(sq_if_output_d != sq_if_output_q) begin
          wqe_done = 1'b0;
          sq_if_state_d = SQ_IF_VALID;
        end else begin
          sq_if_state_d = SQ_IF_IDLE;
        end
      end
    end
    SQ_IF_VALID: begin
      fetch_wqe = 1'b1;
      sq_if_state_d = SQ_IF_IDLE;
    end
  endcase
end



typedef enum {SQ_IDLE, SQ_VALID, SQ_WRITE, SQ_SEND, SQ_READ} sq_state;
sq_state sq_state_d, sq_state_q;



//TODO: wait for ack or check if first sqe
logic last_d, last_q;
logic first_d, first_q;
logic [31:0] transfer_length_d, transfer_length_q;
logic [63:0] curr_local_vaddr_d, curr_local_vaddr_q, curr_remote_vaddr_d, curr_remote_vaddr_q;

always_comb begin
  sq_req_d = sq_req_q;
  m_rdma_sq_interface_valid_o = 1'b0;
  last_d = last_q;
  first_d = first_q;
  transfer_length_d = transfer_length_q;
  curr_local_vaddr_d = curr_local_vaddr_q;
  curr_remote_vaddr_d = curr_remote_vaddr_q;
  for(int i=0; i < NUM_QP; i++) begin
    localidx_d[i] = localidx_q[i];
  end
  fetch_next_wqe = 1'b0;

  case(sq_state_q)
    SQ_IDLE: begin
      //TODO: FIFO for all WQE's fetched in current execution
      //A new WQE is fetched, start examining it...
      if(qp_intf_done) begin
        if(WQEReg_q[135:128] == 8'h00) begin
          //WRITE
          $display("write command");
          sq_state_d = SQ_WRITE;
        end else if(WQEReg_q[135:128] == 8'h02) begin
          //TODO: SEND, is this even supported by the rdma stack?
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
        if(WQEReg_q[127:96] <= mtu_q) begin
          sq_req_d.req_1.opcode = 5'h0a;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b1;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = sq_if_output_q.pd_vaddr;
          sq_req_d.req_1.len    = WQEReg_q[127:96];
          sq_req_d.req_1.rsrvd  = 'd0;

          sq_req_d.req_2.vaddr  = WQEReg_q[223:160];
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = WQEReg_q[127:96];
          sq_req_d.req_2.rsrvd        = 'd0;
          
          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        end else begin          
          sq_req_d.req_1.opcode = 5'h06;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b0;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = sq_if_output_q.pd_vaddr;
          sq_req_d.req_1.len    = mtu_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = WQEReg_q[223:160];
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = mtu_q;
          sq_req_d.req_2.rsrvd  = 'd0;


          transfer_length_d = WQEReg_q[127:96] - mtu_q;
          curr_local_vaddr_d = sq_if_output_q.pd_vaddr + mtu_q;
          curr_remote_vaddr_d = WQEReg_q[223:160] + mtu_q;
          last_d = 1'b0;
          first_d = 1'b0;
          sq_state_d = SQ_VALID;
        end
      end else begin
        if(transfer_length_q <= mtu_q) begin
          //TODO: vaddr handling
          sq_req_d.req_1.opcode = 5'h08;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b1;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = curr_local_vaddr_q;
          sq_req_d.req_1.len    = transfer_length_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = curr_remote_vaddr_q;
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = transfer_length_q;
          sq_req_d.req_2.rsrvd  = 'd0;

          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        end else begin
          //TODO: vaddr handling

          sq_req_d.req_1.opcode = 5'h07;
          sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
          sq_req_d.req_1.last   = 1'b0;
          sq_req_d.req_1.offs   = 4'b0;
          sq_req_d.req_1.vaddr  = curr_local_vaddr_q;
          sq_req_d.req_1.len    = mtu_q;
          sq_req_d.req_1.rsrvd  = 'd0;
          
          sq_req_d.req_2.vaddr  = curr_remote_vaddr_q;
          sq_req_d.req_2.offs   = 4'b0;
          sq_req_d.req_2.len    = mtu_q;
          sq_req_d.req_2.rsrvd  = 'd0;
          
          transfer_length_d = transfer_length_q - mtu_q;
          curr_local_vaddr_d = curr_local_vaddr_q + mtu_q;
          curr_remote_vaddr_d = curr_remote_vaddr_q + mtu_q;
          last_d = 1'b0;
          first_d = 1'b0;
          sq_state_d = SQ_VALID;
        end
      end
    end
    SQ_READ: begin
      sq_req_d.req_1.opcode = 5'h0c;
      sq_req_d.req_1.qpn    = {8'b0, sq_if_output_q.sq_idx};
      sq_req_d.req_1.last   = 1'b1;
      sq_req_d.req_1.offs   = 4'b0;
      sq_req_d.req_1.vaddr  = sq_if_output_q.pd_vaddr;
      sq_req_d.req_1.len    = WQEReg_q[127:96];
      sq_req_d.req_1.rsrvd  = 'd0;
          
      sq_req_d.req_2.vaddr  = WQEReg_q[223:160];
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
          sq_state_d = SQ_IDLE;
          localidx_d[sq_if_output_q.sq_idx] = localidx_q[sq_if_output_q.sq_idx] + 1;
          if(localidx_q[sq_if_output_q.sq_idx] + 1 < sq_if_output_q.sq_prod_idx) begin
            fetch_next_wqe = 1'b1;
          end else begin
            wqe_done = 1'b1;
          end
        end else if(WQEReg_q[135:128] == 8'h00) begin
          sq_state_d = SQ_WRITE;
        end else if(WQEReg_q[135:128] == 8'h02) begin
          sq_state_d = SQ_SEND;
        end
      end
    end
  endcase
end



////////////////
//            //
// AXI MASTER //
//            //
////////////////

typedef enum {AR_IDLE, AR_MID, AR_CALC_ADDR, AR_VALID, AR_READY} ar_state;
ar_state AddrRd_State_d, AddrRd_State_q;
logic [63:0] AddrReg_d, AddrReg_q;

typedef enum {RD_IDLE, RD_READING, RD_DONE} rd_state;
rd_state Read_State_d, Read_State_q;
logic rd_busy;
logic rd_ready;


//TODO: read all wqe's in a burst and put them in a FIFO
//TODO: this fsm might have unnecessary states...
always_comb begin
  m_axi_qp_get_wqe_arvalid_o = 1'b0;
  AddrReg_d = AddrReg_q;
  AddrRd_State_d = AddrRd_State_q;
  

  case(AddrRd_State_q)
    AR_IDLE: begin
      //new elements in work queue
      if ((fetch_wqe || fetch_next_wqe) & !rd_busy) begin
        AddrRd_State_d = AR_CALC_ADDR; 
      end
    end
    AR_CALC_ADDR: begin
      //64 byte aligned 
      AddrReg_d = {sq_if_output_q.sq_base_addr[63:38], sq_if_output_q.sq_base_addr[37:6] + localidx_q[sq_if_output_q.sq_idx], sq_if_output_q.sq_base_addr[5:0]};
      AddrRd_State_d = AR_VALID;
    end
    AR_VALID: begin
      m_axi_qp_get_wqe_arvalid_o = 1'b1;
      if(m_axi_qp_get_wqe_arready_i) begin
        rd_ready = 1'b1;
        AddrRd_State_d = AR_IDLE;
      end
    end
  endcase
end

//AXI read ctl logic
//TODO: this needs some logic from the rdma core 

always_comb begin
  m_axi_qp_get_wqe_rready_o = 1'b0;
  rd_busy = 1'b0;
  WQEReg_d = WQEReg_q;

  case(Read_State_q)
    RD_IDLE: begin
      new_wqe_fetched = 1'b0;
      if(rd_ready) begin  
        rd_ready = 1'b0;
        m_axi_qp_get_wqe_rready_o = 1'b1;
        Read_State_d = RD_READING;
      end
    end
    RD_READING: begin
      //TODO: implement fifo for  burst transactions
      new_wqe_fetched = 1'b0;
      rd_busy = 1'b1;
      m_axi_qp_get_wqe_rready_o = 1'b1;
      if(m_axi_qp_get_wqe_rvalid_i) begin
        WQEReg_d = m_axi_qp_get_wqe_rdata_i;
        if(m_axi_qp_get_wqe_rlast_i) begin
          //directly update QP interface after read
          Read_State_d = RD_DONE;
        end
      end
    end
    RD_DONE: begin
      new_wqe_fetched= 1'b1;
      Read_State_d = RD_IDLE;
    end
  endcase
end

//blank write channel
assign m_axi_qp_get_wqe_awid_o = 'd0;
assign m_axi_qp_get_wqe_awaddr_o = 'd0;
assign m_axi_qp_get_wqe_awlen_o = 'd0;
assign m_axi_qp_get_wqe_awsize_o = 'd0;
assign m_axi_qp_get_wqe_awburst_o = 'd0;
assign m_axi_qp_get_wqe_awcache_o = 'd0;
assign m_axi_qp_get_wqe_awprot_o = 'd0;
assign m_axi_qp_get_wqe_awvalid_o = 'd0;
assign m_axi_qp_get_wqe_wdata_o = 'd0;
assign m_axi_qp_get_wqe_wstrb_o = 'd0;
assign m_axi_qp_get_wqe_wlast_o = 'd0;
assign m_axi_qp_get_wqe_wvalid_o = 'd0;
assign m_axi_qp_get_wqe_awlock_o = 'd0;
assign m_axi_qp_get_wqe_bready_o = 'd1;

//settings for ar signal
assign m_axi_qp_get_wqe_arid_o    = 1'b1;
assign m_axi_qp_get_wqe_araddr_o  = AddrReg_q;
assign m_axi_qp_get_wqe_arlen_o   = 'd0;      //TODO: might be able to read all outstanding wqe in one go! (len - 1)
assign m_axi_qp_get_wqe_arsize_o  = 'd6;     //(clog2(512/8))
assign m_axi_qp_get_wqe_arburst_o = 2'b01;  //increment, ignored if no burst
assign m_axi_qp_get_wqe_arcache_o = 4'h2;   // no cache, no buffer
assign m_axi_qp_get_wqe_arprot_o  = 3'b010;  // unpriviledged, nonsecure, data access
assign m_axi_qp_get_wqe_arlock_o  = 1'b0;    // normal signalling


assign m_rdma_conn_interface_data_o = conn_ctx_q;
assign m_rdma_qp_interface_data_o = qp_ctx_q;
assign m_rdma_sq_interface_data_o = sq_req_q;

//TODO: definitely needs dc fifo or simple cdc inside csr for better timing
//assign CQHEADi_o = localidx_q;



always_ff @(posedge axil_aclk_i, negedge rstn_i) begin
  if(!rstn_i) begin
    conn_if_input_q <= 'd0;
    qp_if_input_q <= 'd0;
    sq_if_input_q <= 'd0;
    sq_fifo_state_q <= SQ_FIFO_IDLE;
    for(int i=0; i < NUM_QP; i++) begin
      localpi_q[i] = 'd0;
    end
  end else begin
    conn_if_input_q <= conn_if_input_d;
    qp_if_input_q <= qp_if_input_d;
    sq_if_input_q <= sq_if_input_d;
    sq_fifo_state_q <= sq_fifo_state_d;
    for(int i=0; i < NUM_QP; i++) begin
      localpi_q[i] = localpi_d[i];
    end
  end
end


always_ff @(posedge axis_aclk_i, negedge rstn_i) begin
  if(!rstn_i) begin
    wqe_done = 1'b1;
    new_wqe_fetched <= 1'b0;
    rd_ready <= 1'b0;
    SQPIi_tmp <= 'd0;
    QPidx_tmp <= 'd0;
   
    conn_state_q <= CONN_IDLE;
    conn_if_output_q <= 'd0;
    conn_ctx_q <= 'd0;
    
    mtu_q <= 'd0;
    qp_state_q <= QP_IDLE;
    qp_if_output_q <= 'd0;
    qp_ctx_q <= 'd0;
    
    sq_if_state_q <= SQ_IF_IDLE;
    sq_if_output_q <= 'd0;
    sq_state_q <= SQ_IDLE;
    sq_req_q = 'd0;
    
    AddrRd_State_q <= AR_IDLE;
    AddrReg_q <= 'd0;
    Read_State_q <= RD_IDLE;
    WQEReg_q <= 'd0;
    curr_local_vaddr_q <= 'd0;
    curr_remote_vaddr_q <= 'd0;
    transfer_length_q <= 'd0;
    last_q <= 1'b0;
    first_q <= 1'b1;
    for(int i = 0; i < NUM_QP; i++) begin
      localidx_q[i] <= 'd0;
    end

  end else begin
    conn_state_q <= conn_state_d;
    conn_if_output_q <= conn_if_output_d;
    conn_ctx_q <= conn_ctx_d;
    
    mtu_q <= mtu_d;
    qp_state_q <= qp_state_d;
    qp_if_output_q <= qp_if_output_d;
    qp_ctx_q = qp_ctx_d;
    
    sq_if_state_q <= sq_if_state_d;
    sq_if_output_q <= sq_if_output_d;
    sq_state_q <= sq_state_d;
    sq_req_q = sq_req_d;
    
    AddrRd_State_q <= AddrRd_State_d;
    AddrReg_q <= AddrReg_d;
    Read_State_q <= Read_State_d;
    WQEReg_q <= WQEReg_d;
    curr_local_vaddr_q <= curr_local_vaddr_d;
    curr_remote_vaddr_q <= curr_remote_vaddr_d;
    transfer_length_q <= transfer_length_d;
    last_q <= last_d;
    first_q <= first_d;
    for(int i = 0; i < NUM_QP; i++) begin
      localidx_q[i] <= localidx_d[i];
    end
  end
end






endmodule: roce_stack_wq_manager