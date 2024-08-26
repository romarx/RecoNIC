module dp_bram #(
  parameter int DATA_WIDTH = 32,
  parameter int BRAM_DEPTH = 256,
  parameter int ADDR_WIDTH = 8
) (
  input  logic                  ena_i,
  input  logic                  wea_i,
  input  logic [ADDR_WIDTH-1:0] addra_i,
  input  logic [DATA_WIDTH-1:0] dia_i,
  output logic [DATA_WIDTH-1:0] douta_o,
  
  input  logic                  enb_i,
  input  logic                  web_i,
  input  logic [ADDR_WIDTH-1:0] addrb_i,
  input  logic [DATA_WIDTH-1:0] dib_i,
  output logic [DATA_WIDTH-1:0] doutb_o,
  
  input  logic                  clk_i,
  input  logic                  rstn_i
);
  
(* ram_style = "block" *) logic [DATA_WIDTH-1:0] ram [BRAM_DEPTH-1:0];
logic [DATA_WIDTH-1:0] douta, doutb;

always @(posedge clk_i) begin
  if(!rstn_i) begin
    for(int i = 0; i < BRAM_DEPTH; i++) begin
      ram[i] <= 'd0;
    end
    douta <= 'd0;
  end else if(ena_i) begin
    if (wea_i) begin
        ram[addra_i] <= dia_i;
    end
    douta <= ram[addra_i];
  end
end

always @(posedge clk_i) begin
  if(!rstn_i) begin
    doutb <= 'd0;
  end else if(enb_i) begin
    if (web_i) begin
        ram[addrb_i] <= dib_i;
    end
    doutb <= ram[addrb_i];
  end
end

assign douta_o = douta;
assign doutb_o = doutb;

endmodule
