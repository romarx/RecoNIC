module writeback_cdc_wrapper (
  input  logic        wb_ready_i,
  output logic        wb_valid_o,
  
  input  logic        CQHEADi_wb_valid_i,
  input  logic [39:0] CQHEADi_wb_i,
  input  logic        SQPSNi_wb_valid_i,
  input  logic [39:0] SQPSNi_wb_i,
  input  logic        LSTRQREQi_wb_valid_i,
  input  logic [39:0] LSTRQREQi_wb_i,

  input  logic        INSRRPKTCNT_wb_valid_i,
  input  logic [31:0] INSRRPKTCNT_wb_i,
  input  logic        INAMPKTCNT_wb_valid_i,
  input  logic [31:0] INAMPKTCNT_wb_i,
  input  logic        INNCKPKTSTS_wb_valid_i,
  input  logic [31:0] INNCKPKTSTS_wb_i,

  input  logic        OUTAMPKTCNT_wb_valid_i,
  input  logic [31:0] OUTAMPKTCNT_wb_i,
  input  logic        OUTNAKPKTCNT_wb_valid_i,
  input  logic [15:0] OUTNAKPKTCNT_wb_i,
  input  logic        OUTIOPKTCNT_wb_valid_i,
  input  logic [31:0] OUTIOPKTCNT_wb_i,
  input  logic        OUTRDRSPPKTCNT_wb_valid_i,
  input  logic [31:0] OUTRDRSPPKTCNT_wb_i,

  output logic        CQHEADi_wb_valid_o,
  output logic [39:0] CQHEADi_wb_o,
  output logic        SQPSNi_wb_valid_o,
  output logic [39:0] SQPSNi_wb_o,
  output logic        LSTRQREQi_wb_valid_o,
  output logic [39:0] LSTRQREQi_wb_o,

  output logic        INSRRPKTCNT_wb_valid_o,
  output logic [31:0] INSRRPKTCNT_wb_o,
  output logic        INAMPKTCNT_wb_valid_o,
  output logic [31:0] INAMPKTCNT_wb_o,
  output logic        INNCKPKTSTS_wb_valid_o,
  output logic [31:0] INNCKPKTSTS_wb_o,

  output logic        OUTAMPKTCNT_wb_valid_o,
  output logic [31:0] OUTAMPKTCNT_wb_o,
  output logic        OUTNAKPKTCNT_wb_valid_o,
  output logic [15:0] OUTNAKPKTCNT_wb_o,
  output logic        OUTIOPKTCNT_wb_valid_o,
  output logic [31:0] OUTIOPKTCNT_wb_o,
  output logic        OUTRDRSPPKTCNT_wb_valid_o,
  output logic [31:0] OUTRDRSPPKTCNT_wb_o,
  
  input  logic        in_clk_i,
  input  logic        out_clk_i,
  input  logic        in_rstn_i,
  input  logic        out_rstn_i
);

simple_cdc #(
  .DATA_WIDTH(40)
) inst_cdc_CQHEADi (
  .in_valid_i(CQHEADi_wb_valid_i),
  .in_data_i(CQHEADi_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(CQHEADi_wb_valid_o),
  .out_data_o(CQHEADi_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(40)
) inst_cdc_SQPSNi (
  .in_valid_i(SQPSNi_wb_valid_i),
  .in_data_i(SQPSNi_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(SQPSNi_wb_valid_o),
  .out_data_o(SQPSNi_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(40)
) inst_cdc_LSTRQREQi (
  .in_valid_i(LSTRQREQi_wb_valid_i),
  .in_data_i(LSTRQREQi_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(LSTRQREQi_wb_valid_o),
  .out_data_o(LSTRQREQi_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(32)
) inst_cdc_INSRRPKTCNT (
  .in_valid_i(INSRRPKTCNT_wb_valid_i),
  .in_data_i(INSRRPKTCNT_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(INSRRPKTCNT_wb_valid_o),
  .out_data_o(INSRRPKTCNT_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(32)
) inst_cdc_INAMPKTCNT (
  .in_valid_i(INAMPKTCNT_wb_valid_i),
  .in_data_i(INAMPKTCNT_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(INAMPKTCNT_wb_valid_o),
  .out_data_o(INAMPKTCNT_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(32)
) inst_cdc_INNCKPKTSTS (
  .in_valid_i(INNCKPKTSTS_wb_valid_i),
  .in_data_i(INNCKPKTSTS_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(INNCKPKTSTS_wb_valid_o),
  .out_data_o(INNCKPKTSTS_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(32)
) inst_cdc_OUTAMPKTCNT (
  .in_valid_i(OUTAMPKTCNT_wb_valid_i),
  .in_data_i(OUTAMPKTCNT_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(OUTAMPKTCNT_wb_valid_o),
  .out_data_o(OUTAMPKTCNT_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(16)
) inst_cdc_OUTNAKPKTCNT (
  .in_valid_i(OUTNAKPKTCNT_wb_valid_i),
  .in_data_i(OUTNAKPKTCNT_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(OUTNAKPKTCNT_wb_valid_o),
  .out_data_o(OUTNAKPKTCNT_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(32)
) inst_cdc_OUTIOPKTCNT (
  .in_valid_i(OUTIOPKTCNT_wb_valid_i),
  .in_data_i(OUTIOPKTCNT_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(OUTIOPKTCNT_wb_valid_o),
  .out_data_o(OUTIOPKTCNT_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);

simple_cdc #(
  .DATA_WIDTH(32)
) inst_cdc_OUTRDRSPPKTCNT (
  .in_valid_i(OUTRDRSPPKTCNT_wb_valid_i),
  .in_data_i(OUTRDRSPPKTCNT_wb_i),

  .out_ready_i(wb_ready_i),
  .out_valid_o(OUTRDRSPPKTCNT_wb_valid_o),
  .out_data_o(OUTRDRSPPKTCNT_wb_o),

  .in_clk_i(in_clk_i),
  .out_clk_i(out_clk_i),
  .in_rstn_i(in_rstn_i),
  .out_rstn_i(out_rstn_i)
);



assign wb_valid_o = CQHEADi_wb_valid_o | SQPSNi_wb_valid_o | LSTRQREQi_wb_valid_o | INSRRPKTCNT_wb_valid_o | INAMPKTCNT_wb_valid_o | INNCKPKTSTS_wb_valid_o | 
                    OUTAMPKTCNT_wb_valid_o | OUTNAKPKTCNT_wb_valid_o | OUTIOPKTCNT_wb_valid_o | OUTRDRSPPKTCNT_wb_valid_o;

endmodule: writeback_cdc_wrapper