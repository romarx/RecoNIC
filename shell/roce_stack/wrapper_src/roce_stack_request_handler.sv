module roce_stack_request_handler #(
    parameter logic READ = 1'b1
)(
  input  logic          s_rdma_req_valid_i,
  output logic          s_rdma_req_ready_o,
  input  logic  [63:0]  s_rdma_req_vaddr_i,
  input  logic  [27:0]  s_rdma_req_len_i,
  input  logic          s_rdma_req_ctl_i,

  output logic          req_addr_valid_o,
  input  logic          req_addr_ready_i,
  output logic  [63:0]  req_addr_vaddr_o,
  input  logic          resp_addr_valid_i,
  output logic          resp_addr_ready_o,
  input  logic  [115:0] resp_addr_data_i,

  output logic          cmd_valid_o,
  input  logic          cmd_ready_i,
  output logic  [103:0] cmd_data_o,

  input  logic          clk_i,
  input  logic          aresetn_i

);

typedef enum {RQ_IDLE, RQ_GETPADDR, RQ_MIDDLE, RQ_SENDCMD} req_state;
req_state req_state_d, req_state_q;

logic [63:0] base_vaddr_d, base_vaddr_q;
logic [63:0] vaddr_d, vaddr_q;
logic [27:0] len_d, len_q;

logic [63:0] paddr_d, paddr_q;
logic [47:0] buflen_d, buflen_q;
logic [3:0] accessdesc_d, accessdesc_q;

logic [103:0] cmd_data_d, cmd_data_q;
logic first_d, first_q;



//TODO: check accessdesc, check length,
//TODO: write to FIFO, then create cmd inputs for datamover if s_rdma_req does not handle its requests with a fifo itself

always_comb begin
  s_rdma_req_ready_o = 1'b1;
  resp_addr_ready_o = 1'b1;
  req_addr_valid_o = 1'b0;
  cmd_valid_o = 1'b0;
  req_state_d = req_state_q;
  base_vaddr_d = base_vaddr_q;
  vaddr_d = vaddr_q;
  len_d = len_q;
  paddr_d = paddr_q;
  buflen_d = buflen_q;
  accessdesc_d = accessdesc_q;

  case (req_state_q)
    RQ_IDLE: begin
      resp_addr_ready_o = 1'b0;
      //A request can only be handled if an incoming request arrives and the request can be taken
      if (s_rdma_req_valid_i && req_addr_ready_i) begin 
        s_rdma_req_ready_o = 1'b0;
        len_d = s_rdma_req_len_i;
        first_d = s_rdma_req_ctl_i;
        if(first_q) begin
          base_vaddr_d = s_rdma_req_vaddr_i;
          req_state_d = RQ_GETPADDR;
        end else begin
          vaddr_d = s_rdma_req_vaddr_i;
          req_state_d = RQ_MIDDLE;
        end
      end
    end
    RQ_GETPADDR: begin
      s_rdma_req_ready_o = 1'b0;
      req_addr_valid_o = 1'b1;
      if (resp_addr_valid_i) begin
        resp_addr_ready_o = 1'b0;
        paddr_d = resp_addr_data_i[63:0];
        buflen_d = resp_addr_data_i[111:64];
        accessdesc_d = resp_addr_data_i[115:112];
        //In this case, directly send cmd 4b reserved, 4b tag, 64b address, 1b dre realign, 1b EOF, 6b dre stream align, 1b type (fixed, incr), 22b len
        cmd_data_d = {8'b0, resp_addr_data_i[63:0], 1'b0, 1'b1, 6'b0, 1'b1, len_q[22:0]};
        req_state_d = RQ_SENDCMD;
      end
    end
    RQ_MIDDLE: begin
      s_rdma_req_ready_o = 1'b0;
      resp_addr_ready_o = 1'b0;
      cmd_data_d = {8'b0, (paddr_q + (vaddr_q - base_vaddr_q)), 1'b0, 1'b1, 6'b0, 1'b1, len_q[22:0]};
      req_state_d = RQ_SENDCMD;
    end
    RQ_SENDCMD: begin
      s_rdma_req_ready_o = 1'b0;
      resp_addr_ready_o = 1'b0;
      cmd_valid_o = 1'b1;
      if (cmd_ready_i) begin
        req_state_d = RQ_IDLE;
      end
    end
  endcase
end



always_ff @(posedge clk_i, negedge aresetn_i) begin
  if(!aresetn_i) begin
    req_state_q <= RQ_IDLE;
    vaddr_q <= 'd0;
    base_vaddr_q <= 'd0;
    len_q <= 'd0;
    paddr_q <= 'd0;
    buflen_q <= 'd0;
    accessdesc_q <= 'd0;
    cmd_data_q <= 'd0;
    first_q = 1'b1;
  end else begin
    req_state_q <= req_state_d;
    vaddr_q <= vaddr_d;
    base_vaddr_q <= base_vaddr_d;
    len_q <= len_d;
    paddr_q <= paddr_d;
    buflen_q <= buflen_d;
    accessdesc_q <= accessdesc_d;
    cmd_data_q <= cmd_data_d;
    first_q <= first_d;
  end
end

assign req_addr_vaddr_o = base_vaddr_q;
assign cmd_data_o = cmd_data_q;


endmodule: roce_stack_request_handler