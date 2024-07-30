module roce_stack_request_handler #(
    parameter logic READ = 1'b1
)(
  metaIntf.s            s_rdma_req,

  output logic          req_addr_valid_o,
  input  logic          req_addr_ready_i,
  output logic  [63:0]  req_addr_vaddr_o,
  output logic  [15:0]  req_addr_qpn_o,
  input  logic          resp_addr_valid_i,
  output logic          resp_addr_ready_o,
  input  dma_req_t      resp_addr_data_i,

  output logic          cmd_valid_o,
  input  logic          cmd_ready_i,
  output logic  [103:0] cmd_data_o,
  output logic          err_st_o,

  output logic  [71:0]  wb_rqbufaddr_o,
  output logic  [39:0]  wb_rqpidb_o,
  output logic          wb_valid_o,
  
  input  logic          clk_i,
  input  logic          aresetn_i

);

typedef enum {RQ_IDLE, RQ_GETPADDR, RQ_MIDDLE, RQ_SENDCMD, RQ_WB_DBADD} req_state;
req_state req_state_d, req_state_q;

logic [63:0] base_vaddr_d, base_vaddr_q;
logic [27:0] len_d, len_q;
logic [47:0] total_len_d, total_len_q;
logic [15:0] qpn_d, qpn_q;

logic [63:0] paddr_d, paddr_q;
logic [63:0] paddr_base_d, paddr_base_q;
logic [47:0] buflen_d, buflen_q;
logic [3:0]  accessdesc_d, accessdesc_q;
logic [31:0] rkey_db_d, rkey_db_q;

logic [103:0] cmd_data_d, cmd_data_q;
logic         err_st_d, err_st_q;
logic         first_d, first_q;




always_comb begin
  s_rdma_req.ready = 1'b1;
  resp_addr_ready_o = 1'b1;
  req_addr_valid_o = 1'b0;
  wb_valid_o = 1'b0;
  cmd_valid_o = 1'b0;
  cmd_data_d = cmd_data_q;
  err_st_d = err_st_q;
  req_state_d = req_state_q;
  base_vaddr_d = base_vaddr_q;
  len_d = len_q;
  total_len_d = total_len_q;
  qpn_d = qpn_q;
  paddr_d = paddr_q;
  paddr_base_d = paddr_base_q;
  buflen_d = buflen_q;
  accessdesc_d = accessdesc_q;
  rkey_db_d = rkey_db_q;
  first_d = first_q;

  case (req_state_q)
    RQ_IDLE: begin
      resp_addr_ready_o = 1'b0;
    
      if (s_rdma_req.valid) begin
        len_d = s_rdma_req.data.len;
        total_len_d = total_len_q + s_rdma_req.data.len;
        first_d = s_rdma_req.data.last;
        
        //If it's a local read or write, the address should be correct
        if((READ && (s_rdma_req.data.opcode == RC_RDMA_WRITE_MIDDLE || s_rdma_req.data.opcode == RC_RDMA_WRITE_FIRST ||
			      s_rdma_req.data.opcode == RC_RDMA_WRITE_LAST || s_rdma_req.data.opcode == RC_RDMA_WRITE_ONLY || s_rdma_req.data.opcode == RC_SEND_ONLY ||
            s_rdma_req.data.opcode == RC_SEND_FIRST || s_rdma_req.data.opcode == RC_SEND_MIDDLE || s_rdma_req.data.opcode == RC_SEND_LAST)) ||
            (!READ && (s_rdma_req.data.opcode == RC_RDMA_READ_RESP_FIRST || s_rdma_req.data.opcode == RC_RDMA_READ_RESP_MIDDLE || 
            s_rdma_req.data.opcode == RC_RDMA_READ_RESP_LAST || s_rdma_req.data.opcode == RC_RDMA_READ_RESP_ONLY))) begin
          if(first_q) begin
            buflen_d = 'h7FFFFFFFFFFF; //hack so it always works
            accessdesc_d = 4'b0010; //same
            paddr_d = s_rdma_req.data.vaddr;
          end
          req_state_d = RQ_MIDDLE;
        //if it's not, find the associated protection domain
        end else if(req_addr_ready_i) begin 
          if(first_q) begin
            qpn_d = s_rdma_req.data.qpn;
            base_vaddr_d = s_rdma_req.data.vaddr;
            req_state_d = RQ_GETPADDR;
          end else begin
            req_state_d = RQ_MIDDLE;
          end
        end
      end
    end
    RQ_GETPADDR: begin
      s_rdma_req.ready = 1'b0;
      req_addr_valid_o = 1'b1;
      if (resp_addr_valid_i) begin
        buflen_d = resp_addr_data_i.buflen;
        accessdesc_d = resp_addr_data_i.accesdesc;
        rkey_db_d = resp_addr_data_i.rkey;
        //In this case, directly send cmd 4b reserved, 4b tag, 64b address, 1b dre realign, 1b EOF, 6b dre stream align, 1b type (fixed, incr), 22b len
        if(total_len_q <= resp_addr_data_i.buflen && (resp_addr_data_i.accesdesc == 4'b0010) || (READ && resp_addr_data_i.accesdesc == 4'b0000) || (!READ && resp_addr_data_i.accesdesc == 4'b0001)) begin
          cmd_data_d = {8'b0, resp_addr_data_i.paddr, 1'b0, 1'b1, 6'b0, 1'b1, len_q[22:0]};
        end else begin
          err_st_d = 1'b1;
        end
        paddr_d = resp_addr_data_i.paddr + len_q;
        paddr_base_d = resp_addr_data_i.paddr;
        req_state_d = RQ_SENDCMD;
      end
    end
    RQ_MIDDLE: begin
      s_rdma_req.ready = 1'b0;
      resp_addr_ready_o = 1'b0;
      if(total_len_q <= buflen_q && (accessdesc_q == 4'b0010) || (READ && accessdesc_q == 4'b0000) || (!READ && accessdesc_q == 4'b0001)) begin
        cmd_data_d = {8'b0, paddr_q, 1'b0, 1'b1, 6'b0, 1'b1, len_q[22:0]};
      end else begin
        err_st_d = 1'b1;
      end
      paddr_d = paddr_q + len_q;
      req_state_d = RQ_SENDCMD;
    end
    RQ_SENDCMD: begin
      s_rdma_req.ready = 1'b0;
      resp_addr_ready_o = 1'b0;
      cmd_valid_o = 1'b1;
      if (cmd_ready_i) begin
        if(first_q) begin //last!
          total_len_d = 'd0;
          err_st_d = 1'b0;
          if(base_vaddr_q == 'd0 && !READ) begin 
            paddr_base_d = paddr_base_q + buflen_q;
            rkey_db_d = rkey_db_q + 1;
            req_state_d = RQ_WB_DBADD;
          end else begin
            req_state_d = RQ_IDLE;
          end
        end else begin
          req_state_d = RQ_IDLE;
        end
      end
    end
    RQ_WB_DBADD: begin
      wb_valid_o = 1'b1;
      req_state_d = RQ_IDLE;
    end
  endcase
end



always_ff @(posedge clk_i, negedge aresetn_i) begin
  if(!aresetn_i) begin
    req_state_q   <= RQ_IDLE;
    base_vaddr_q  <= 'd0;
    len_q         <= 'd0;
    total_len_q   <= 'd0;
    qpn_q         <= 'd0;
    paddr_q       <= 'd0;
    paddr_base_q  <= 'd0;
    buflen_q      <= 'd0;
    accessdesc_q  <= 'd0;
    rkey_db_q     <= 'd0;
    cmd_data_q    <= 'd0;
    err_st_q      <= 'd0;
    first_q       <= 1'b1;
  end else begin
    req_state_q   <= req_state_d;
    base_vaddr_q  <= base_vaddr_d;
    len_q         <= len_d;
    total_len_q   <= total_len_d;
    qpn_q         <= qpn_d;
    paddr_q       <= paddr_d;
    paddr_base_q  <= paddr_base_d;
    buflen_q      <= buflen_d;
    accessdesc_q  <= accessdesc_d;
    rkey_db_q     <= rkey_db_d;
    cmd_data_q    <= cmd_data_d;
    err_st_q      <= err_st_d;
    first_q       <= first_d;
  end
end

assign req_addr_vaddr_o = base_vaddr_q;
assign req_addr_qpn_o = qpn_q;
assign cmd_data_o = cmd_data_q;
assign err_st_o = err_st_q;

assign wb_rqbufaddr_o = {qpn_q, paddr_base_q};
assign wb_rqpidb_o = {qpn_q, rkey_db_q};



endmodule: roce_stack_request_handler