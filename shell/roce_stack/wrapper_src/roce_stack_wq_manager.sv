import lynxTypes::*;

module roce_stack_wq_manager #()(
    input  logic [7:0]    QPidx_i,
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
    output logic [183:0]  m_rdma_conn_interface_data_o,

    output logic          m_rdma_qp_interface_valid_o, 
    input  logic          m_rdma_qp_interface_ready_i,
    output rdma_req_t     m_rdma_qp_interface_data_o,
    
    output logic          m_rdma_sq_interface_valid_o, 
    input  logic          m_rdma_sq_interface_ready_i,
    output logic [255:0]  m_rdma_sq_interface_data_o,

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

typedef struct packed { 
  logic [7:0]   qp_idx;
  logic [31:0]  src_qp_conf;
  logic [23:0]  dest_qp;
  logic [31:0]  dest_ip_addr;
  logic [23:0]  sq_psn;
  logic [23:0]  dest_sq_psn;
  logic [63:0]  sq_base_addr;
  logic [31:0]  sq_prod_idx;
  logic [31:0]  cq_head_idx;
  logic [63:0]  pd_vaddr;
} QPdata_struct; //336 bits

QPdata_struct qp_fifo_input_d, qp_fifo_input_q, qp_fifo_output;

typedef enum {IDLE, VALID} fifo_state;
fifo_state fifo_wr_d, fifo_wr_q, fifo_rd_d, fifo_rd_q;

logic qp_fifo_full, qp_fifo_wr_en, qp_fifo_wr_ack, qp_fifo_wr_rst_busy;
logic qp_fifo_empty, qp_fifo_rd_en, qp_fifo_rd_valid, qp_fifo_rd_rst_busy;


logic [183:0] conn_reg_d, conn_reg_q;
logic [199:0] qp_reg_d, qp_reg_q;

rdma_req_t sq_reg_d, sq_reg_q;

logic [31:0] localidx_init_d, localidx_init_q;
logic [31:0] localidx_d, localidx_q; 
logic [31:0] mtu_d, mtu_q;

logic [511:0] WQEReg_d, WQEReg_q;


logic qp_done;
logic new_qp_ready;
logic new_wqe_fetched;
logic conn_done;
logic qp_intf_done;


always_comb begin
  qp_fifo_wr_en = 1'b0;
  qp_fifo_input_d = qp_fifo_input_q;
  fifo_wr_d = fifo_wr_q;

  case (fifo_wr_q)
    IDLE: begin
      if(QPidx_i != qp_fifo_input_q.qp_idx || SQPIi_i != qp_fifo_input_q.sq_prod_idx && !qp_fifo_full && !qp_fifo_wr_rst_busy) begin
        qp_fifo_input_d.qp_idx        = QPidx_i;
        qp_fifo_input_d.src_qp_conf   = QPCONFi_i;
        qp_fifo_input_d.dest_qp       = DESTQPCONFi_i;
        qp_fifo_input_d.dest_ip_addr  = IPDESADDR1i_i;
        qp_fifo_input_d.sq_psn        = SQPSNi_i;
        qp_fifo_input_d.dest_sq_psn   = LSTRQREQi_i[23:0];
        qp_fifo_input_d.sq_base_addr  = SQBAi_i;
        qp_fifo_input_d.sq_prod_idx   = SQPIi_i;
        qp_fifo_input_d.cq_head_idx   = CQHEADi_i;
        qp_fifo_input_d.pd_vaddr      = VIRTADDR_i;
        fifo_wr_d = VALID;
      end
    end
    VALID: begin
      qp_fifo_wr_en = 1'b1;
      if(qp_fifo_wr_ack) begin
        fifo_wr_d = IDLE;
      end
    end
  endcase
end

always_comb begin
  qp_fifo_rd_en = 1'b0;
  fifo_rd_d = fifo_rd_q;
  localidx_init_d = localidx_init_q;
  mtu_d = mtu_q;

  case(fifo_rd_q)
    IDLE: begin
      new_qp_ready = 1'b0;
      if(!qp_fifo_empty && qp_done && !qp_fifo_rd_rst_busy) begin
        qp_done = 1'b0;
        qp_fifo_rd_en = 1'b1;
        fifo_rd_d = VALID;
      end
    end
    VALID: begin
      if(qp_fifo_rd_valid) begin
        // only proceed if qp is enabled and mtu conf is valid
        if(qp_fifo_output.src_qp_conf[0] && qp_fifo_output.src_qp_conf[10:8] <= 3'b100) begin
          localidx_init_d = qp_fifo_output.cq_head_idx;
          mtu_d = 'd256 << qp_fifo_output.src_qp_conf[10:8];
          new_qp_ready = 1'b1;
          $display("new qp ready");
        end else begin
          qp_done = 1'b1;
          $display("new qp failed");
        end
        fifo_rd_d = IDLE;
      end
    end
  endcase
end

roce_stack_cdc_fifo_qp_wq inst_roce_stack_cdc_fifo_qp_wq (
.full(qp_fifo_full),
.din(qp_fifo_input_q),
.wr_en(qp_fifo_wr_en),
.wr_ack(qp_fifo_wr_ack),

.empty(qp_fifo_empty),
.dout(qp_fifo_output),
.rd_en(qp_fifo_rd_en),
.valid(qp_fifo_rd_valid),

.wr_clk(axil_aclk_i),
.rd_clk(axis_aclk_i),
.srst(!rstn_i),
.wr_rst_busy(qp_fifo_wr_rst_busy),
.rd_rst_busy(qp_fifo_rd_rst_busy)
);


typedef enum {CONN_IDLE, CONN_VALID, CONN_DONE} conn_state;
conn_state conn_state_d, conn_state_q;

always_comb begin
  conn_reg_d = conn_reg_q;
  conn_state_d = conn_state_q;
  m_rdma_conn_interface_valid_o = 1'b0;

  case (conn_state_q)
    CONN_IDLE: begin
      conn_done = 1'b0;
      //Current WQE changed, potentially also QP, send new conn configuration 
      if(new_wqe_fetched && !qp_done) begin
        conn_reg_d = {16'd0, qp_fifo_output.dest_ip_addr, qp_fifo_output.dest_ip_addr, qp_fifo_output.dest_ip_addr, qp_fifo_output.dest_ip_addr, 16'd0, qp_fifo_output.dest_qp};
        //only reconnect if configuration changed
        if(conn_reg_d != conn_reg_q) begin
          conn_state_d = CONN_VALID;
        end else begin
          conn_state_d = CONN_DONE;
        end
      end
    end
    CONN_VALID: begin
      m_rdma_conn_interface_valid_o = 1'b1;
      if(m_rdma_conn_interface_ready_i) begin
        conn_done = 1'b1;
        conn_state_d = CONN_DONE;
      end
    end
    CONN_DONE: begin
      conn_done = 1'b1;
      conn_state_d = CONN_IDLE;
    end
  endcase
end


typedef enum {QP_IDLE, QP_VALID, QP_DONE} qp_state;
qp_state qp_state_d, qp_state_q;

//QP interface logic (SQ also maybe...)
always_comb begin
  qp_reg_d = qp_reg_q;
  qp_state_d = qp_state_q;
  m_rdma_qp_interface_valid_o = 1'b0;

  case(qp_state_q)
    QP_IDLE: begin
      qp_intf_done = 1'b0;
      //we have a new work queue element
      if(conn_done && !qp_done) begin
        qp_reg_d = {WQEReg_q[255:224], WQEReg_q[223:160], qp_fifo_output.dest_sq_psn, qp_fifo_output.sq_psn, 56'b0}; //TODO: finish with qp num and state or just 0?
        //only reconnect if new state differs from old state
        if(qp_reg_d != qp_reg_q) begin
          qp_state_d = QP_VALID;
        end else begin
          qp_state_d = QP_DONE;
        end
      end
    end
    QP_VALID: begin
      m_rdma_qp_interface_valid_o = 1'b1;
      
      if(m_rdma_qp_interface_ready_i) begin
        qp_intf_done = 1'b1;
        qp_state_d = QP_IDLE;
      end
    end
    QP_DONE: begin
      qp_intf_done = 1'b1;
      qp_state_d = QP_IDLE;
    end
  endcase
end


typedef enum {SQ_IDLE, SQ_VALID, SQ_WRITE, SQ_SEND, SQ_READ} sq_state;
sq_state sq_state_d, sq_state_q;
logic cmplt, last, mode, host;


//TODO: wait for ack or check if first sqe
//TODO: probably need to split it up for each packet, send last signal
logic last_d, last_q;
logic first_d, first_q;
logic [31:0] transfer_length_d, transfer_length_q;
logic [63:0] curr_local_vaddr_d, curr_local_vaddr_q, curr_remote_vaddr_d, curr_remote_vaddr_q;

always_comb begin
  sq_reg_d = sq_reg_q;
  m_rdma_sq_interface_valid_o = 1'b0;
  last_d = last_q;
  first_d = first_q;
  transfer_length_d = transfer_length_q;

  case(sq_state_q)
    SQ_IDLE: begin
      //TODO: FIFO for all WQE's fetched in current execution
      //A new WQE is fetched, start examining it...
      if(qp_intf_done && !qp_done) begin
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
          sq_reg_d.opcode = 5'h0a;
          sq_reg_d.qpn    = 10'h0;
          sq_reg_d.host   = 1'b0;
          sq_reg_d.mode   = 1'b0;
          sq_reg_d.last   = 1'b1;
          sq_reg_d.cmplt  = 1'b0;
          sq_reg_d.ssn    = 24'b0;
          sq_reg_d.offs   = 4'b0;
          sq_reg_d.msg    = {32'b0, WQEReg_q[127:96], qp_fifo_output.pd_vaddr, WQEReg_q[223:160]};
          sq_reg_d.rsrvd  = 'd0;
          
          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        end else begin          
          sq_reg_d.opcode = 5'h06;
          sq_reg_d.qpn    = 10'h0;
          sq_reg_d.host   = 1'b0;
          sq_reg_d.mode   = 1'b0;
          sq_reg_d.last   = 1'b0;
          sq_reg_d.cmplt  = 1'b0;
          sq_reg_d.ssn    = 24'b0;
          sq_reg_d.offs   = 4'b0;
          sq_reg_d.msg    = {32'b0, mtu_q, qp_fifo_output.pd_vaddr, WQEReg_q[223:160]};
          sq_reg_d.rsrvd  = 'd0;
          
          transfer_length_d = WQEReg_q[127:96] - mtu_q;
          curr_local_vaddr_d = qp_fifo_output.pd_vaddr + mtu_q;
          curr_remote_vaddr_d = WQEReg_q[223:160] + mtu_q;
          last_d = 1'b0;
          first_d = 1'b0;
          sq_state_d = SQ_VALID;
        end
      end else begin
        if(transfer_length_q <= mtu_q) begin
          //TODO: vaddr handling
          sq_reg_d.opcode = 5'h08;
          sq_reg_d.qpn    = 10'h0;
          sq_reg_d.host   = 1'b0;
          sq_reg_d.mode   = 1'b0;
          sq_reg_d.last   = 1'b1;
          sq_reg_d.cmplt  = 1'b0;
          sq_reg_d.ssn    = 24'b0;
          sq_reg_d.offs   = 4'b0;
          sq_reg_d.msg    = {32'b0, transfer_length_q, curr_local_vaddr_q, curr_remote_vaddr_q};
          sq_reg_d.rsrvd  = 'd0;
          
          last_d = 1'b1;
          sq_state_d = SQ_VALID;
        end else begin
          //TODO: vaddr handling
          sq_reg_d.opcode = 5'h07;
          sq_reg_d.qpn    = 10'h0;
          sq_reg_d.host   = 1'b0;
          sq_reg_d.mode   = 1'b0;
          sq_reg_d.last   = 1'b0;
          sq_reg_d.cmplt  = 1'b0;
          sq_reg_d.ssn    = 24'b0;
          sq_reg_d.offs   = 4'b0;
          sq_reg_d.msg    = {32'b0, mtu_q, curr_local_vaddr_q, curr_remote_vaddr_q};
          sq_reg_d.rsrvd  = 'd0;
          
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
      sq_reg_d.opcode = 5'h0c;
      sq_reg_d.qpn    = 10'h0;
      sq_reg_d.host   = 1'b0;
      sq_reg_d.mode   = 1'b0;
      sq_reg_d.last   = 1'b1;
      sq_reg_d.cmplt  = 1'b0;
      sq_reg_d.ssn    = 24'b0;
      sq_reg_d.offs   = 4'b0;
      sq_reg_d.msg    = {32'b0, WQEReg_q[127:96], qp_fifo_output.pd_vaddr, WQEReg_q[223:160]};
      sq_reg_d.rsrvd  = 'd0;
      
      
      last_d = 1'b1;
      sq_state_d = SQ_VALID;
    end
    SQ_VALID: begin
      m_rdma_sq_interface_valid_o = 1'b1;
      if(m_rdma_sq_interface_ready_i) begin
        if(last_q) begin
          first_d = 1'b1;
          sq_state_d = SQ_IDLE;
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
logic rd_busy, rd_done;
logic rd_ready;


//TODO: read all wqe's in a burst and put them in a FIFO
//TODO: this fsm might have unnecessary states...
always_comb begin
  m_axi_qp_get_wqe_arvalid_o = 1'b0;
  AddrReg_d = AddrReg_q;
  AddrRd_State_d = AddrRd_State_q;
  localidx_d = localidx_q;

  case(AddrRd_State_q)
    AR_IDLE: begin
      //new elements in work queue
      if (new_qp_ready & !rd_busy) begin
        localidx_d = localidx_init_q;
        AddrRd_State_d = AR_CALC_ADDR; //TODO: state might be unnecessary
      end
    end
    AR_MID: begin
      if(!new_wqe_fetched) begin
        AddrRd_State_d = AR_CALC_ADDR;
      end
    end
    AR_CALC_ADDR: begin
      //64 byte aligned 
      AddrReg_d = {qp_fifo_output.sq_base_addr[63:38], qp_fifo_output.sq_base_addr[37:6] + localidx_q, qp_fifo_output.sq_base_addr[5:0]};
      AddrRd_State_d = AR_VALID;
    end
    AR_VALID: begin
      m_axi_qp_get_wqe_arvalid_o = 1'b1;
      if(m_axi_qp_get_wqe_arready_i) begin
        rd_ready = 1'b1;
        localidx_d = localidx_q + 1;
        AddrRd_State_d = AR_READY;
      end
    end
    AR_READY: begin
      //TODO: this state might be unnecessary, also can maybe read everything in a max 4kb burst (max len = 63)
      rd_ready = 1'b1;
      if(localidx_q < qp_fifo_output.sq_prod_idx) begin
        AddrRd_State_d = AR_MID;
      end else begin
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


assign m_rdma_conn_interface_data_o = conn_reg_q;
assign m_rdma_qp_interface_data_o = qp_reg_q;
assign m_rdma_sq_interface_data_o = sq_reg_q;

//TODO: definitely needs dc fifo or simple cdc inside csr for better timing
//assign CQHEADi_o = localidx_q;



always_ff @(posedge axil_aclk_i, negedge rstn_i) begin
  if(!rstn_i) begin
    fifo_wr_q <= IDLE;
    qp_fifo_input_q <= 'd0;
  end else begin
    fifo_wr_q <= fifo_wr_d;
    qp_fifo_input_q <= qp_fifo_input_d;
  end
end


always_ff @(posedge axis_aclk_i, negedge rstn_i) begin
  if(!rstn_i) begin
    qp_done <= 1'b1;
    new_qp_ready <= 1'b0;
    new_wqe_fetched <= 1'b0;
    conn_done <= 1'b0;
    qp_intf_done <= 1'b0;
    rd_ready <= 1'b0;
    
    fifo_rd_q <= IDLE;
    mtu_q <= 'd0;
    conn_state_q <= CONN_IDLE;
    qp_state_q <= QP_IDLE;
    sq_state_q <= SQ_IDLE;
    conn_reg_q <= 'd0;
    qp_reg_q <= 'd0;
    sq_reg_q = 'd0;
    AddrRd_State_q <= AR_IDLE;
    AddrReg_q <= 'd0;
    localidx_init_q <= 'd0;
    localidx_q <= 'd0;
    Read_State_q <= RD_IDLE;
    WQEReg_q <= 'd0;
    transfer_length_q <= 'd0;
    last_q <= 1'b0;
    first_q <= 1'b1;
  end else begin
    fifo_rd_q <= fifo_rd_d;
    mtu_q <= mtu_d;
    conn_state_q <= conn_state_d;
    qp_state_q <= qp_state_d;
    sq_state_q <= sq_state_d;
    conn_reg_q <= conn_reg_d;
    qp_reg_q = qp_reg_d;
    sq_reg_q = sq_reg_d;
    AddrRd_State_q <= AddrRd_State_d;
    AddrReg_q <= AddrReg_d;
    localidx_init_q <= localidx_init_d;
    localidx_q <= localidx_d;
    Read_State_q <= Read_State_d;
    WQEReg_q <= WQEReg_d;
    transfer_length_q <= transfer_length_d;
    last_q <= last_d;
    first_q <= first_d;
  end
end






endmodule: roce_stack_wq_manager