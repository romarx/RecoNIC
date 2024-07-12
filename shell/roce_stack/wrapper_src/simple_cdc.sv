// very simple cdc without fifo, values can be overwritten
// shouldn't be that much of a problem in this project because
// time between writebacks is usually long enough
// and even if it fails it's not the end of the world ;)

// the input always gets overwritten if valid is asserted.

module simple_cdc #(
    parameter int DATA_WIDTH = 40 //idx + reg_width
) (
  input  logic                    in_valid_i,
  input  logic [DATA_WIDTH-1:0]   in_data_i,

  output logic                    out_valid_o,
  input  logic                    out_ready_i,
  output logic [DATA_WIDTH-1:0]   out_data_o,

  input  logic                    in_clk_i,
  input  logic                    out_clk_i,
  input  logic                    in_rstn_i,
  input  logic                    out_rstn_i
);


logic [DATA_WIDTH-1:0] data_in_d, data_in_q, data_meta, data_out_d, data_out_q;

typedef enum {IDLE, VALID, READY} fsm_state_t;
fsm_state_t out_fsm_state_d, out_fsm_state_q;


//in clk domain
always_comb begin
  data_in_d = data_in_q;
  if (in_valid_i) begin
    data_in_d = in_data_i;
  end
end

//out clk domain
always_comb begin
  out_fsm_state_d = out_fsm_state_q;
  data_out_d = data_out_q;
  out_valid_o = 1'b0;

  case (out_fsm_state_q)
    IDLE: begin
      if(data_meta != data_out_q) begin //input changed
        data_out_d = data_meta;
        out_fsm_state_d = READY;
      end
    end
    READY: begin
      out_valid_o = 1'b1;
      if(out_ready_i) begin
        out_fsm_state_d = IDLE;
      end
    end
  endcase
end

//in region
always_ff @(posedge in_clk_i, negedge in_rstn_i) begin
  if(!in_rstn_i) begin
    data_in_q <= 'd0;
  end else begin
    data_in_q <= data_in_d;
  end
end

//metastable region
always_ff @(posedge out_clk_i, negedge out_rstn_i) begin
  if(!out_rstn_i) begin
    data_meta <= 'd0;
  end else begin
    data_meta <= data_in_q;
  end
end

//out region
always_ff @(posedge out_clk_i, negedge out_rstn_i) begin
  if(!out_rstn_i) begin
    out_fsm_state_q <= IDLE;
    data_out_q <= 'd0;
  end else begin
    out_fsm_state_q <= out_fsm_state_d;
    data_out_q <= data_out_d;
  end
end

assign out_data_o = data_out_q;

endmodule: simple_cdc