`timescale 1ns/1ps

//TODO: set actual width for certain registers (by masking at write).
//TODO: some individual bits are read only, these registers need special treatment.
//TODO: check if some debug outputs of RoCE stack can be used
module roce_stack_csr (
  input  logic                            s_axil_awvalid_i,
  input  logic   [AXIL_ADDR_WIDTH-1:0]    s_axil_awaddr_i,
  output logic                            s_axil_awready_o,
  input  logic                            s_axil_wvalid_i,
  input  logic   [AXIL_DATA_WIDTH-1:0]    s_axil_wdata_i,
  input  logic   [AXIL_DATA_WIDTH/8-1:0]  s_axil_wstrb_i,
  output logic                            s_axil_wready_o,
  output logic                            s_axil_bvalid_o,
  output logic  [1:0]                     s_axil_bresp_o,
  input  logic                            s_axil_bready_i,
  input  logic                            s_axil_arvalid_i,
  input  logic   [AXIL_ADDR_WIDTH-1:0]    s_axil_araddr_i,
  output logic                            s_axil_arready_o,
  output logic                            s_axil_rvalid_o,
  output logic  [AXIL_DATA_WIDTH-1:0]     s_axil_rdata_o,
  output logic  [1:0]                     s_axil_rresp_o,
  input  logic                            s_axil_rready_i,

  //Configuration registers
  output logic [31:0]                     CONF_o,
  //output logic [31:0]                     ADCONF_o,
  output logic [47:0]                     MACADD_o,
  output logic [31:0]                     IPv4ADD_o,
  //output logic [31:0]                     INTEN_o, //INTERRUPT ENABLE NOT CONNECTED

  //output logic [63:0]                     ERRBUFBA_o,
  //output logic [31:0]                     ERRBUFSZ_o,

  //output logic [63:0]                     IPKTERRQBA_o,
  //output logic [31:0]                     IPKTERRQSZ_o,

  //output logic [63:0]                     DATBUFBA_o,
  //output logic [31:0]                     DATBUFSZ_o,

  //output logic [63:0]                     RESPERRPKTBA_o,
  //output logic [63:0]                     RESPERRSZ_o,


  //Per QP registers
  output logic [7:0]                      QPidx_o,
  output logic                            conn_configured_o,
  output logic                            qp_configured_o, 
  output logic                            sq_updated_o,

  output logic [31:0]                     QPCONFi_o,
  //output logic [31:0]                     QPADVCONFi_o,
  output logic [63:0]                     RQBAi_o,
  output logic [63:0]                     SQBAi_o,
  output logic [63:0]                     CQBAi_o,
  //output logic [63:0]                     RQWPTRDBADDi_o,
  //output logic [63:0]                     CQDBADDi_o,
  output logic [31:0]                     SQPIi_o,
  output logic [31:0]                     CQHEADi_o,
  //output logic [31:0]                     QDEPTHi_o,
  output logic [23:0]                     SQPSNi_o,
  output logic [31:0]                     LSTRQREQi_o, // contains rq psn[23:0]
  output logic [23:0]                     DESTQPCONFi_o,

  output logic [47:0]                     MACDESADDi_o,             
  output logic [31:0]                     IPDESADDR1i_o, //for IPv4 only

  output logic [63:0]                     VIRTADDR_o,

  input rd_cmd_t                          rd_qp_i,
  input logic                             rd_qp_valid_i,
  output logic                            rd_qp_ready_o,

  //write back
  input  logic                            WB_CQHEADi_valid_i,
  input  logic [39:0]                     WB_CQHEADi_i,
  input  logic                            WB_SQPSNi_valid_i,
  input  logic [39:0]                     WB_SQPSNi_i,
  input  logic                            WB_LSTRQREQi_valid_i,
  input  logic [39:0]                     WB_LSTRQREQi_i,


  input  logic                            WB_INSRRPKTCNT_valid_i,
  input  logic [31:0]                     WB_INSRRPKTCNT_i,
  input  logic                            WB_INAMPKTCNT_valid_i,
  input  logic [31:0]                     WB_INAMPKTCNT_i,
  input  logic                            WB_INNCKPKTSTS_valid_i,
  input  logic [31:0]                     WB_INNCKPKTSTS_i,
  

  input  logic                            WB_OUTAMPKTCNT_valid_i,
  input  logic [31:0]                     WB_OUTAMPKTCNT_i,
  input  logic                            WB_OUTNAKPKTCNT_valid_i,
  input  logic [15:0]                     WB_OUTNAKPKTCNT_i,
  input  logic                            WB_OUTIOPKTCNT_valid_i,
  input  logic [31:0]                     WB_OUTIOPKTCNT_i,
  input  logic                            WB_OUTRDRSPPKTCNT_valid_i,
  input  logic [31:0]                     WB_OUTRDRSPPKTCNT_i,

  //address translation
  input  logic                            rd_req_addr_valid_i,
  output logic                            rd_req_addr_ready_o,
  input  logic [63:0]                     rd_req_addr_vaddr_i,
  input  logic [15:0]                     rd_req_addr_qpn_i,
  output logic                            rd_resp_addr_valid_o,
  input  logic                            rd_resp_addr_ready_i,
  output dma_req_t                        rd_resp_addr_data_o,

  input  logic                            wr_req_addr_valid_i,
  output logic                            wr_req_addr_ready_o,
  input  logic [63:0]                     wr_req_addr_vaddr_i,
  input  logic [15:0]                     wr_req_addr_qpn_i,
  output logic                            wr_resp_addr_valid_o,
  input  logic                            wr_resp_addr_ready_i,
  output dma_req_t                        wr_resp_addr_data_o,

  //input  logic  [7:0]                     wr_ptr_i,


  input logic                             axis_aclk_i,
  input logic                             axil_aclk_i,
  input logic                             axis_rstn_i,
  input logic                             axil_rstn_i

);

//assert (NUM_QP >= 8 && NUM_QP <=256) else begin $error("NUM_QP must be between 8 and 256") end;


localparam int RD_LAT = 1;

////////////////
//            //
//  CDC FIFO  //
//            //
////////////////
rd_cmd_t cmd_fifo_in = 'd0;
rd_cmd_t cmd_fifo_out;
logic cmd_fifo_wr_en, cmd_fifo_rd_en;
logic cmd_fifo_full, cmd_fifo_empty;
logic cmd_fifo_out_valid, cmd_fifo_in_ack;
logic cmd_fifo_wr_rst_busy, cmd_fifo_rd_rst_busy;



////////////////////////
//                    //
// AXIL CLOCK DOMAIN  //
//                    //
////////////////////////

// Protection domain regs: 0x0 - 0x10000
logic [NUM_PD_REGS-1:0] PD_REG_ENA_AXIL = 'd0;
logic [AXIL_DATA_WIDTH_BYTES-1:0] PD_REG_WEA_AXIL = 'd0;
logic [LOG_NUM_PD-1:0] PD_ADDR_AXIL = 'd0;
logic [REG_WIDTH-1:0] PD_WR_REG_AXIL = 'd0;
logic [NUM_PD_REGS-1:0][REG_WIDTH-1:0] PD_RD_REG_AXIL;


//Per QP registers (NUMQP min is 8, max is 256)
logic [NUM_QP_REGS-1:0] QP_REG_ENA_AXIL = 'd0;
logic [AXIL_DATA_WIDTH_BYTES-1:0] QP_REG_WEA_AXIL = 'd0;
logic [LOG_NUM_QP-1:0] QP_ADDR_AXIL = 'd0;
logic [REG_WIDTH-1:0] QP_WR_REG_AXIL = 'd0;
logic [NUM_QP_REGS-1:0][REG_WIDTH-1:0] QP_RD_REG_AXIL;


// Configuration and status regs 0x20000 - 0x201F0
logic GLB_REG_ENA_AXIL = 1'b0;
logic [AXIL_DATA_WIDTH_BYTES-1:0] GLB_REG_WEA_AXIL = 'd0;
logic [7:0] GLB_ADDR_AXIL = 'd0;
logic [REG_WIDTH-1:0] GLB_WR_REG_AXIL = 'd0;
logic [REG_WIDTH-1:0] GLB_RD_REG_AXIL;



///////////////////////
//                   //
//  CONTROL SIGNALS  //
//                   //
///////////////////////

logic reading, writing;
logic[1:0] hold_rd_d, hold_rd_q;
logic[1:0] hold_wr_d, hold_wr_q; //TODO: not sure if needed



logic[CSR_ADDRESS_WIDTH-1:0]  RAddrReg_d, RAddrReg_q;
logic[REG_WIDTH-1:0]          RDataReg_d, RDataReg_q;
logic[1:0]                    RRespReg_d, RRespReg_q;

typedef enum {R_IDLE, R_GETDATA, R_VALID} read_state;
read_state r_state_q, r_state_d;

logic[CSR_ADDRESS_WIDTH-1:0]    WAddrReg_d, WAddrReg_q;
logic[REG_WIDTH-1:0]            WDataReg_d, WDataReg_q;
logic[1:0]                      WRespReg_d, WRespReg_q;
logic[AXIL_DATA_WIDTH_BYTES-1:0] WStrbReg_d, WStrbReg_q;

typedef enum {W_IDLE, W_READY, WRITE, B_RESP} write_state;
write_state w_state_d, w_state_q;








////////////////
//            //
//  READ FSM  //
//            //
////////////////

always_comb begin
  s_axil_arready_o = 1'b0;
  s_axil_rvalid_o = 1'b0;
  reading = 1'b0;
  RAddrReg_d = RAddrReg_q;
  RDataReg_d = RDataReg_q;
  RRespReg_d = RRespReg_q; //OKAY
  r_state_d = r_state_q;
  hold_rd_d = hold_rd_q;

  case(r_state_q)
    R_IDLE: begin
      if(s_axil_arvalid_i && !writing) begin
        RAddrReg_d = s_axil_araddr_i;
        s_axil_arready_o = 1'b1;
        PD_REG_WEA_AXIL = 'd0;
        QP_REG_WEA_AXIL = 'd0;
        GLB_REG_WEA_AXIL = 'd0;
        r_state_d = R_GETDATA;
      end
    end

    R_GETDATA: begin 
      RRespReg_d = 2'b0; //OKAY
      reading = 1'b1;
      //protection domain range
      if(!RAddrReg_q[17]) begin
        PD_ADDR_AXIL = RAddrReg_q[15-:8];
        case(RAddrReg_q[7:0])
          ADDR_PDPDNUM: begin
            PD_REG_ENA_AXIL[PDPDNUM_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[PDPDNUM_idx];
          end
          ADDR_VIRTADDRLSB: begin
            PD_REG_ENA_AXIL[VIRTADDRLSB_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[VIRTADDRLSB_idx];
          end
          ADDR_VIRTADDRMSB: begin
            PD_REG_ENA_AXIL[VIRTADDRMSB_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[VIRTADDRMSB_idx];
          end
          ADDR_BUFBASEADDRLSB: begin
            PD_REG_ENA_AXIL[BUFBASEADDRLSB_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[BUFBASEADDRLSB_idx];
          end
          ADDR_BUFBASEADDRMSB: begin
            PD_REG_ENA_AXIL[BUFBASEADDRMSB_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[BUFBASEADDRMSB_idx];
          end
          ADDR_BUFRKEY: begin
            PD_REG_ENA_AXIL[BUFRKEY_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[BUFRKEY_idx];
          end
          ADDR_WRRDBUFLEN: begin
            PD_REG_ENA_AXIL[WRRDBUFLEN_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[WRRDBUFLEN_idx];
          end
          ADDR_ACCESSDESC: begin
            PD_REG_ENA_AXIL[ACCESSDESC_idx] = 1'b1;
            RDataReg_d = PD_RD_REG_AXIL[ACCESSDESC_idx];
          end
          default: begin
            RDataReg_d = 'd0;
          end
        endcase
      end
      
      //Per QP range
      else if(RAddrReg_q[17-:10] >= 'h202) begin
        QP_ADDR_AXIL = RAddrReg_q[17-:10] - 'h202;
        if(QP_ADDR_AXIL >= NUM_QP) begin
          RDataReg_d = 'd0;
          RRespReg_d = 2'b10; //SLVERR
        end else begin
          case(RAddrReg_q[7:0])
            ADDR_QPCONFi: begin
              QP_REG_ENA_AXIL[QPCONFi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[QPCONFi_idx];
            end
            ADDR_QPADVCONFi: begin
              QP_REG_ENA_AXIL[QPADVCONFi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[QPADVCONFi_idx];
            end
            ADDR_RQBAi: begin
              QP_REG_ENA_AXIL[RQBAi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[RQBAi_idx];
            end
            ADDR_RQBAMSBi: begin
              QP_REG_ENA_AXIL[RQBAMSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[RQBAMSBi_idx];
            end
            ADDR_SQBAi: begin
              QP_REG_ENA_AXIL[SQBAi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[SQBAi_idx];
            end
            ADDR_SQBAMSBi: begin
              QP_REG_ENA_AXIL[SQBAMSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[SQBAMSBi_idx];
            end
            ADDR_CQBAi: begin
              QP_REG_ENA_AXIL[CQBAi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[CQBAi_idx];
            end
            ADDR_CQBAMSBi: begin
              QP_REG_ENA_AXIL[CQBAMSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[CQBAMSBi_idx];
            end
            ADDR_RQWPTRDBADDi: begin
              QP_REG_ENA_AXIL[RQWPTRDBADDi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[RQWPTRDBADDi_idx];
            end
            ADDR_RQWPTRDBADDMSBi: begin
              QP_REG_ENA_AXIL[RQWPTRDBADDMSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[RQWPTRDBADDMSBi_idx];
            end
            ADDR_CQDBADDi: begin
              QP_REG_ENA_AXIL[CQDBADDi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[CQDBADDi_idx];
            end
            ADDR_CQDBADDMSBi: begin
              QP_REG_ENA_AXIL[CQDBADDMSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[CQDBADDMSBi_idx];
            end
            ADDR_CQHEADi: begin
              QP_REG_ENA_AXIL[CQHEADi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[CQHEADi_idx];
            end
            ADDR_RQCIi: begin
              QP_REG_ENA_AXIL[RQCIi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[RQCIi_idx];
            end
            ADDR_SQPIi: begin
              QP_REG_ENA_AXIL[SQPIi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[SQPIi_idx];
            end
            ADDR_QDEPTHi: begin
              QP_REG_ENA_AXIL[QDEPTHi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[QDEPTHi_idx];
            end
            ADDR_SQPSNi: begin
              QP_REG_ENA_AXIL[SQPSNi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[SQPSNi_idx];
            end
            ADDR_LSTRQREQi: begin
              QP_REG_ENA_AXIL[LSTRQREQi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[LSTRQREQi_idx];
            end
            ADDR_DESTQPCONFi: begin
              QP_REG_ENA_AXIL[DESTQPCONFi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[DESTQPCONFi_idx];
            end
            ADDR_MACDESADDLSBi: begin
              QP_REG_ENA_AXIL[MACDESADDLSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[MACDESADDLSBi_idx];
            end
            ADDR_MACDESADDMSBi: begin
              QP_REG_ENA_AXIL[MACDESADDMSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[MACDESADDMSBi_idx];
            end
            ADDR_IPDESADDR1i: begin
              QP_REG_ENA_AXIL[IPDESADDR1i_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[IPDESADDR1i_idx];
            end
            ADDR_IPDESADDR2i: begin
              QP_REG_ENA_AXIL[IPDESADDR2i_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[IPDESADDR2i_idx];
            end
            ADDR_IPDESADDR3i: begin
              QP_REG_ENA_AXIL[IPDESADDR3i_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[IPDESADDR3i_idx];
            end
            ADDR_IPDESADDR4i: begin
              QP_REG_ENA_AXIL[IPDESADDR4i_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[IPDESADDR4i_idx];
            end
            ADDR_TIMEOUTCONFi: begin
              QP_REG_ENA_AXIL[TIMEOUTCONFi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[TIMEOUTCONFi_idx];
            end
            ADDR_STATSSNi: begin
              QP_REG_ENA_AXIL[STATSSNi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATSSNi_idx];
            end
            ADDR_STATMSNi: begin
              QP_REG_ENA_AXIL[STATMSNi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATMSNi_idx];
            end
            ADDR_STATQPi: begin
              QP_REG_ENA_AXIL[STATQPi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATQPi_idx];
            end
            ADDR_STATCURSQPTRi: begin
              QP_REG_ENA_AXIL[STATCURSQPTRi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATCURSQPTRi_idx];
            end
            ADDR_STATRESPSNi: begin
              QP_REG_ENA_AXIL[STATRESPSNi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATRESPSNi_idx];
            end
            ADDR_STATRQBUFCAi: begin
              QP_REG_ENA_AXIL[STATRQBUFCAi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATRQBUFCAi_idx];
            end
            ADDR_STATRQBUFCAMSBi: begin
              QP_REG_ENA_AXIL[STATRQBUFCAMSBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATRQBUFCAMSBi_idx];
            end
            ADDR_STATWQEi: begin
              QP_REG_ENA_AXIL[STATWQEi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATWQEi_idx];
            end
            ADDR_STATRQPIDBi: begin
              QP_REG_ENA_AXIL[STATRQPIDBi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[STATRQPIDBi_idx];
            end
            ADDR_PDNUMi: begin
              QP_REG_ENA_AXIL[PDNUMi_idx] = 1'b1;
              RDataReg_d = QP_RD_REG_AXIL[PDNUMi_idx];
            end
            default: begin
              RDataReg_d = 'd0;
            end
          endcase
        end
      end else begin
        GLB_ADDR_AXIL = RAddrReg_q >> 2; //TODO: does this actually work??
        GLB_REG_ENA_AXIL = 1'b1;
        RDataReg_d = GLB_RD_REG_AXIL;
      end
      //hold this state for rd latency
      if(hold_rd_q == RD_LAT) begin
        r_state_d = R_VALID;
        hold_rd_d = 'd0;
      end else begin
        r_state_d = R_GETDATA;
        hold_rd_d = hold_rd_q + 1;
      end
    end

    R_VALID: begin
      reading = 1'b1;
      PD_REG_ENA_AXIL = 'd0;
      QP_REG_ENA_AXIL = 'd0;
      GLB_REG_ENA_AXIL = 1'b0;
      s_axil_rvalid_o = 1'b1;
      if(s_axil_rready_i) begin
        r_state_d = R_IDLE;
      end
    end
  endcase
end

/////////////////
//             //
//  WRITE FSM  //
//             //
/////////////////


always_comb begin
  s_axil_awready_o = 1'b0;
  s_axil_bvalid_o = 1'b0;
  s_axil_wready_o = 1'b0;
  writing = 1'b0;
  cmd_fifo_wr_en = 1'b0;
  WAddrReg_d = WAddrReg_q;
  WDataReg_d = WDataReg_q;
  WRespReg_d = WRespReg_q;
  WStrbReg_d = WStrbReg_q;
  hold_wr_d = hold_wr_q;
  
  w_state_d = w_state_q;


  case(w_state_q)
    W_IDLE: begin
      //write requests from axil
      if(s_axil_awvalid_i && !reading) begin
        s_axil_awready_o = 1'b1;
        WAddrReg_d = s_axil_awaddr_i;
        writing = 1'b1;
        w_state_d = W_READY;
      end
    end
    
    W_READY: begin
      s_axil_wready_o = 1'b1;
      writing = 1'b1;
      if(s_axil_wvalid_i) begin
        WDataReg_d = s_axil_wdata_i;
        WStrbReg_d = s_axil_wstrb_i;
        w_state_d = WRITE;
      end
    end

    WRITE: begin
      WRespReg_d = 2'b0;
      writing = 1'b1;
      if(~WAddrReg_q[17]) begin
        PD_ADDR_AXIL = WAddrReg_q[15-:8];
        cmd_fifo_in.region = 'd1;
        cmd_fifo_in.address = PD_ADDR_AXIL;
        PD_REG_WEA_AXIL = WStrbReg_q;
        case(WAddrReg_q[7:0])
          ADDR_PDPDNUM: begin
            PD_REG_ENA_AXIL[PDPDNUM_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
            cmd_fifo_in.read_all = 1'b0;
            cmd_fifo_in.bram_idx = PDPDNUM_idx;
            cmd_fifo_wr_en = 1'b1; 
          end
          ADDR_VIRTADDRLSB: begin
            PD_REG_ENA_AXIL[VIRTADDRLSB_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
          end
          ADDR_VIRTADDRMSB: begin
            PD_REG_ENA_AXIL[VIRTADDRMSB_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
          end
          ADDR_BUFBASEADDRLSB: begin
            PD_REG_ENA_AXIL[BUFBASEADDRLSB_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
          end
          ADDR_BUFBASEADDRMSB: begin
            PD_REG_ENA_AXIL[BUFBASEADDRMSB_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
          end
          ADDR_BUFRKEY: begin
            PD_REG_ENA_AXIL[BUFRKEY_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
          end
          ADDR_WRRDBUFLEN: begin
            PD_REG_ENA_AXIL[WRRDBUFLEN_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
          end
          ADDR_ACCESSDESC: begin
            PD_REG_ENA_AXIL[ACCESSDESC_idx] = 1'b1;
            PD_WR_REG_AXIL = WDataReg_q;
          end
          default: begin
            WRespReg_d = 2'b10; //SLVERR
          end
        endcase
      end else if (WAddrReg_q[17-:10] >= 'h202) begin
        QP_ADDR_AXIL = WAddrReg_q[17-:10] - 'h202;
        if(QP_ADDR_AXIL >= NUM_QP) begin
          WRespReg_d = 2'b10; //SLVERR
        end else begin
          QP_REG_WEA_AXIL = WStrbReg_q;
          cmd_fifo_in.region = 'd2;
          cmd_fifo_in.address = QP_ADDR_AXIL;
          case(WAddrReg_q[7:0])
            ADDR_QPCONFi: begin
              QP_REG_ENA_AXIL[QPCONFi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
              cmd_fifo_in.read_all = 1'b1;
              cmd_fifo_in.bram_idx = QPCONFi_idx;
              cmd_fifo_wr_en = 1'b1; 
            end
            ADDR_QPADVCONFi: begin
              QP_REG_ENA_AXIL[QPADVCONFi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_RQBAi: begin
              QP_REG_ENA_AXIL[RQBAi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_RQBAMSBi: begin
              QP_REG_ENA_AXIL[RQBAMSBi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_SQBAi: begin
              QP_REG_ENA_AXIL[SQBAi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_SQBAMSBi: begin
              QP_REG_ENA_AXIL[SQBAMSBi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_CQBAi: begin
              QP_REG_ENA_AXIL[CQBAi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_CQBAMSBi: begin
              QP_REG_ENA_AXIL[CQBAMSBi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_RQWPTRDBADDi: begin
              QP_REG_ENA_AXIL[RQWPTRDBADDi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_RQWPTRDBADDMSBi: begin
              QP_REG_ENA_AXIL[RQWPTRDBADDMSBi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_CQDBADDi: begin
              QP_REG_ENA_AXIL[CQDBADDi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_CQDBADDMSBi: begin
              QP_REG_ENA_AXIL[CQDBADDMSBi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_RQCIi: begin
              QP_REG_ENA_AXIL[RQCIi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_SQPIi: begin
              QP_REG_ENA_AXIL[SQPIi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
              cmd_fifo_in.read_all = 1'b1;
              cmd_fifo_in.bram_idx = SQPIi_idx;
              cmd_fifo_wr_en = 1'b1; 
            end
            ADDR_QDEPTHi: begin
              QP_REG_ENA_AXIL[QDEPTHi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_SQPSNi: begin
              QP_REG_ENA_AXIL[SQPSNi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
              cmd_fifo_in.read_all = 1'b1;
              cmd_fifo_in.bram_idx = SQPSNi_idx;
              cmd_fifo_wr_en = 1'b1; 
            end
            ADDR_LSTRQREQi: begin
              QP_REG_ENA_AXIL[LSTRQREQi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
              cmd_fifo_in.read_all = 1'b1;
              cmd_fifo_in.bram_idx = LSTRQREQi_idx;
              cmd_fifo_wr_en = 1'b1; 
            end
            ADDR_DESTQPCONFi: begin
              QP_REG_ENA_AXIL[DESTQPCONFi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
              cmd_fifo_in.read_all = 1'b1;
              cmd_fifo_in.bram_idx = DESTQPCONFi_idx;
              cmd_fifo_wr_en = 1'b1; 
            end
            ADDR_MACDESADDLSBi: begin
              QP_REG_ENA_AXIL[MACDESADDLSBi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_MACDESADDMSBi: begin
              QP_REG_ENA_AXIL[MACDESADDMSBi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_IPDESADDR1i: begin
              QP_REG_ENA_AXIL[IPDESADDR1i_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
              cmd_fifo_in.read_all = 1'b1;
              cmd_fifo_in.bram_idx = IPDESADDR1i_idx;
              cmd_fifo_wr_en = 1'b1;             
            end
            ADDR_IPDESADDR2i: begin
              QP_REG_ENA_AXIL[IPDESADDR2i_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_IPDESADDR3i: begin
              QP_REG_ENA_AXIL[IPDESADDR3i_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_IPDESADDR4i: begin
              QP_REG_ENA_AXIL[IPDESADDR4i_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_TIMEOUTCONFi: begin
              QP_REG_ENA_AXIL[TIMEOUTCONFi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            ADDR_PDNUMi: begin
              QP_REG_ENA_AXIL[PDNUMi_idx] = 1'b1;
              QP_WR_REG_AXIL = WDataReg_q;
            end
            default: begin
              WRespReg_d = 2'b10; //SLVERR
            end
          endcase
        end
      end else begin
        GLB_REG_WEA_AXIL = WStrbReg_q;
        GLB_ADDR_AXIL = WAddrReg_q >> 2;
        cmd_fifo_in.region = 'd0;
        cmd_fifo_in.read_all = 1'b0;
        cmd_fifo_in.bram_idx = 1'b0;
        case (WAddrReg_q[8:0]) 
          ADDR_CONF: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
            cmd_fifo_in.address = GLB_ADDR_AXIL;
            cmd_fifo_wr_en = 1'b1; 
          end 
          ADDR_ADCONF: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_BUF_THRESHOLD_ROCE: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_PAUSE_CONF: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_MACADDLSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
            cmd_fifo_in.address = GLB_ADDR_AXIL;
            cmd_fifo_wr_en = 1'b1; 
          end 
          ADDR_MACADDMSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
            cmd_fifo_in.address = GLB_ADDR_AXIL;
            cmd_fifo_wr_en = 1'b1; 
          end 
          ADDR_BUF_THRESHOLD_NON_ROCE: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_IPv6ADD1: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end  
          ADDR_IPv6ADD2: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end  
          ADDR_IPv6ADD3: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end  
          ADDR_IPv6ADD4: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end   
          ADDR_ERRBUFBA: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_ERRBUFBAMSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_ERRBUFSZ: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_IPv4ADD: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
            cmd_fifo_in.address = GLB_ADDR_AXIL;
            cmd_fifo_wr_en = 1'b1; 
          end 
          ADDR_OPKTERRQBA: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_OPKTERRQBAMSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_OUTERRSTSQSZ: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_OPTERRSTSQQPTRDB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_IPKTERRQBA: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_IPKTERRQBAMSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_IPKTERRQSZ: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_DATBUFBA: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_DATBUFBAMSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_DATBUFSZ: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_CON_IO_CONF: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_RESPERRPKTBA: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_RESPERRPKTBAMSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_RESPERRSZ: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_RESPERRSZMSB: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          ADDR_INTEN: begin
            GLB_REG_ENA_AXIL = 1'b1;
            GLB_WR_REG_AXIL = WDataReg_q;
          end 
          //W1C
          default: begin
            if(WAddrReg_q >= ADDR_INTSTS && WAddrReg_q <= ADDR_CQINTSTS8) begin
              if(WDataReg_q == 'd1 && GLB_REG_WEA_AXIL[0]) begin
                GLB_REG_ENA_AXIL = 1'b1;
                GLB_WR_REG_AXIL = 'd0;
              end
            end else begin
              WRespReg_d = 2'b10;
            end
          end
          
        endcase
      end
      
      //TODO: not sure if needed
      if(hold_wr_q == 'd1) begin
        w_state_d = B_RESP;
        hold_wr_d = 'd0;
      end else begin
        w_state_d =  WRITE;
        hold_wr_d = hold_wr_q + 1;
      end
      if(cmd_fifo_in_ack) begin
        cmd_fifo_wr_en = 1'b0;
      end
    end
    B_RESP: begin
      PD_REG_ENA_AXIL = 'd0;
      QP_REG_ENA_AXIL = 'd0;
      GLB_REG_ENA_AXIL = 'd0;
      writing = 1'b1;
      s_axil_bvalid_o = 1'b1;
      if(s_axil_bready_i) begin
        w_state_d = W_IDLE;
      end
    end
  endcase
end



always_ff @(posedge axil_aclk_i, negedge axil_rstn_i) begin
  if(!axil_rstn_i) begin    
    r_state_q <= R_IDLE;
    w_state_q <= W_IDLE;
    RAddrReg_q <= 'd0;
    RDataReg_q <= 'd0;
    RRespReg_q <= 'd0;
    hold_rd_q <= 'd0;
    
    WAddrReg_q <= 'd0;
    WDataReg_q <= 'd0;
    WRespReg_q <= 'd0;
    WStrbReg_q <= 'd0;
    hold_wr_q <= 'd0;
  
  end else begin
    r_state_q <= r_state_d;
    w_state_q <= w_state_d;
    RAddrReg_q <= RAddrReg_d;
    RDataReg_q <= RDataReg_d;
    RRespReg_q <= RRespReg_d;
    hold_rd_q <= hold_rd_d;
    
    WAddrReg_q <= WAddrReg_d;
    WDataReg_q <= WDataReg_d;
    WRespReg_q <= WRespReg_d;
    WStrbReg_q <= WStrbReg_d;
    hold_wr_q <= hold_wr_d;

  end
end




////////////////////////
//                    //
// AXIS CLOCK DOMAIN  //
//                    //
////////////////////////



// Protection domain regs: 0x0 - 0x10000
logic [NUM_PD_REGS-1:0] PD_REG_ENB_AXIS;
logic [AXIL_DATA_WIDTH_BYTES-1:0] PD_REG_WEB_AXIS;
logic [LOG_NUM_PD-1:0] PD_ADDR_AXIS;
logic [NUM_PD_REGS-1:0][REG_WIDTH-1:0] PD_RD_REG_AXIS, PD_RD_REG_AXIS_D, PD_RD_REG_AXIS_Q;
logic [REG_WIDTH-1:0] PD_WR_REG_AXIS; //these are never written by the hardware

//Per QP registers (NUMQP min is 8, max is 256)
logic [NUM_QP_REGS-1:0] QP_REG_ENB_AXIS;
logic [AXIL_DATA_WIDTH_BYTES-1:0] QP_REG_WEB_AXIS;
logic [LOG_NUM_QP-1:0] QP_ADDR_AXIS;
logic [NUM_QP_REGS-1:0][REG_WIDTH-1:0] QP_RD_REG_AXIS, QP_RD_REG_AXIS_D, QP_RD_REG_AXIS_Q;
logic [REG_WIDTH-1:0] QP_WR_REG_AXIS;

// Configuration and status regs 0x20000 - 0x201F0
logic GLB_REG_ENB_AXIS;
logic [AXIL_DATA_WIDTH_BYTES-1:0] GLB_REG_WEB_AXIS;
logic [7:0] GLB_ADDR_AXIS;
logic [REG_WIDTH-1:0] GLB_RD_REG_AXIS;
logic [REG_WIDTH-1:0] GLB_WR_REG_AXIS;

//huge table to lookup pdnum
logic [NUM_PD-1:0][23:0] pdnum_table_d, pdnum_table_q; 


//Control signals for r/w fsm
typedef enum {L_IDLE, L_READ_CMD, L_READ_SINGLE, L_READ_MULTI, L_WRITE, L_READ_READY, L_READ_VADDR} logic_reg_state_t;
logic_reg_state_t l_reg_st_d, l_reg_st_q;
rd_cmd_t l_rd_cmd_d, l_rd_cmd_q;
logic [1:0] hold_axis_d, hold_axis_q;

wr_cmd_t l_wr_cmd_d, l_wr_cmd_q;



// lookup physical addresses
typedef enum {VTP_IDLE, VTP_RD_PDN, VTP_RD_PDN_VLD, VTP_RD_PD, VTP_PREP_RESP, VTP_PREP_RESP_VLD, VTP_REQ_PD, VTP_VALID} virt_to_phys_state;
virt_to_phys_state rd_vtp_st_d, rd_vtp_st_q, wr_vtp_st_d, wr_vtp_st_q;
rd_cmd_t find_pd_rd_d, find_pd_rd_q, find_pd_wr_d, find_pd_wr_q;
logic find_pd_rd_valid = 0;
logic find_pd_wr_valid = 0; 
logic find_pd_rd_ready; 
logic find_pd_wr_ready;
dma_req_t rd_resp_addr_data_d, rd_resp_addr_data_q, wr_resp_addr_data_d, wr_resp_addr_data_q;




logic [LOG_NUM_QP-1:0] QPidx_d, QPidx_q;

logic [REG_WIDTH-1:0] CONF_d, CONF_q;
//logic [REG_WIDTH-1:0] ADCONF_d, ADCONF_q;
//logic [REG_WIDTH-1:0] BUF_THRESHOLD_ROCE_d, BUF_THRESHOLD_ROCE_q;
//logic [REG_WIDTH-1:0] PAUSE_CONF_d, PAUSE_CONF_q;
logic [REG_WIDTH-1:0] MACADDLSB_d, MACADDLSB_q;
logic [REG_WIDTH-1:0] MACADDMSB_d, MACADDMSB_q;
//logic [REG_WIDTH-1:0] BUF_THRESHOLD_NON_ROCE_d, BUF_THRESHOLD_NON_ROCE_q;

//logic [REG_WIDTH-1:0] IPv6ADD1_d, IPv6ADD1_q;
//logic [REG_WIDTH-1:0] IPv6ADD2_d, IPv6ADD2_q;
//logic [REG_WIDTH-1:0] IPv6ADD3_d, IPv6ADD3_q;
//logic [REG_WIDTH-1:0] IPv6ADD4_d, IPv6ADD4_q;

//logic [REG_WIDTH-1:0] ERRBUFBA_d, ERRBUFBA_q;
//logic [REG_WIDTH-1:0] ERRBUFBAMSB_d, ERRBUFBAMSB_q;
//logic [REG_WIDTH-1:0] ERRBUFSZ_d, ERRBUFSZ_q;
//logic [REG_WIDTH-1:0] ERRBUFWPTR_d, ERRBUFWPTR_q; 
logic [REG_WIDTH-1:0] IPv4ADD_d, IPv4ADD_q;

//logic [REG_WIDTH-1:0] OPKTERRQBA_d, OPKTERRQBA_q;
//logic [REG_WIDTH-1:0] OPKTERRQBAMSB_d, OPKTERRQBAMSB_q;
//logic [REG_WIDTH-1:0] OUTERRSTSQSZ_d, OUTERRSTSQSZ_q;
//logic [REG_WIDTH-1:0] OPTERRSTSQQPTRDB_d, OPTERRSTSQQPTRDB_q;
//logic [REG_WIDTH-1:0] IPKTERRQBA_d, IPKTERRQBA_q;
//logic [REG_WIDTH-1:0] IPKTERRQBAMSB_d, IPKTERRQBAMSB_q;
//logic [REG_WIDTH-1:0] IPKTERRQSZ_d, IPKTERRQSZ_q;
//logic [REG_WIDTH-1:0] IPKTERRQWPTR_d, IPKTERRQWPTR_q;

//logic [REG_WIDTH-1:0] DATBUFBA_d, DATBUFBA_q;
//logic [REG_WIDTH-1:0] DATBUFBAMSB_d, DATBUFBAMSB_q;
//logic [REG_WIDTH-1:0] DATBUFSZ_d, DATBUFSZ_q;
//logic [REG_WIDTH-1:0] CON_IO_CONF_d, CON_IO_CONF_q;
//logic [REG_WIDTH-1:0] RESPERRPKTBA_d, RESPERRPKTBA_q;
//logic [REG_WIDTH-1:0] RESPERRPKTBAMSB_d, RESPERRPKTBAMSB_q;
//logic [REG_WIDTH-1:0] RESPERRSZ_d, RESPERRSZ_q;
//logic [REG_WIDTH-1:0] RESPERRSZMSB_d, RESPERRSZMSB_q;

//Global status regs
//logic [REG_WIDTH-1:0] INSRRPKTCNT_d, INSRRPKTCNT_q;
//logic [REG_WIDTH-1:0] INAMPKTCNT_d, INAMPKTCNT_q;
//logic [REG_WIDTH-1:0] OUTIOPKTCNT_d, OUTIOPKTCNT_q;
//logic [REG_WIDTH-1:0] OUTAMPKTCNT_d, OUTAMPKTCNT_q;
//logic [REG_WIDTH-1:0] LSTINPKT_d, LSTINPKT_q;
//logic [REG_WIDTH-1:0] LSTOUTPKT_d, LSTOUTPKT_q;
//logic [REG_WIDTH-1:0] ININVDUPCNT_d, ININVDUPCNT_q;
//logic [REG_WIDTH-1:0] INNCKPKTSTS_d, INNCKPKTSTS_q;
//logic [REG_WIDTH-1:0] OUTRNRPKTSTS_d, OUTRNRPKTSTS_q;
//logic [REG_WIDTH-1:0] WQEPROCSTS_d, WQEPROCSTS_q;
//logic [REG_WIDTH-1:0] QPMSTS_d, QPMSTS_q;
//logic [REG_WIDTH-1:0] INALLDRPPKTCNT_d, INALLDRPPKTCNT_q;
//logic [REG_WIDTH-1:0] INNAKPKTCNT_d, INNAKPKTCNT_q;
//logic [REG_WIDTH-1:0] OUTNAKPKTCNT_d, OUTNAKPKTCNT_q;
//logic [REG_WIDTH-1:0] RESPHNDSTS_d, RESPHNDSTS_q;
//logic [REG_WIDTH-1:0] RETRYCNTSTS_d, RETRYCNTSTS_q;

//logic [REG_WIDTH-1:0] INCNPPKTCNT_d, INCNPPKTCNT_q;
//logic [REG_WIDTH-1:0] OUTCNPPKTCNT_d, OUTCNPPKTCNT_q;
//logic [REG_WIDTH-1:0] OUTRDRSPPKTCNT_d, OUTRDRSPPKTCNT_q;
//logic [REG_WIDTH-1:0] INTEN_d, INTEN_q;
//logic [REG_WIDTH-1:0] INTSTS_d, INTSTS_q;

//logic [REG_WIDTH-1:0] RQINTSTS1_d, RQINTSTS1_q; 
//logic [REG_WIDTH-1:0] RQINTSTS2_d, RQINTSTS2_q;
//logic [REG_WIDTH-1:0] RQINTSTS3_d, RQINTSTS3_q;
//logic [REG_WIDTH-1:0] RQINTSTS4_d, RQINTSTS4_q;
//logic [REG_WIDTH-1:0] RQINTSTS5_d, RQINTSTS5_q;
//logic [REG_WIDTH-1:0] RQINTSTS6_d, RQINTSTS6_q;
//logic [REG_WIDTH-1:0] RQINTSTS7_d, RQINTSTS7_q;
//logic [REG_WIDTH-1:0] RQINTSTS8_d, RQINTSTS8_q;
//logic [REG_WIDTH-1:0] CQINTSTS1_d, CQINTSTS1_q;
//logic [REG_WIDTH-1:0] CQINTSTS2_d, CQINTSTS2_q;
//logic [REG_WIDTH-1:0] CQINTSTS3_d, CQINTSTS3_q;
//logic [REG_WIDTH-1:0] CQINTSTS4_d, CQINTSTS4_q;
//logic [REG_WIDTH-1:0] CQINTSTS5_d, CQINTSTS5_q;
//logic [REG_WIDTH-1:0] CQINTSTS6_d, CQINTSTS6_q;
//logic [REG_WIDTH-1:0] CQINTSTS7_d, CQINTSTS7_q;
//logic [REG_WIDTH-1:0] CQINTSTS8_d, CQINTSTS8_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS1REG_d, CNPSCHDSTS1REG_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS2REG_d, CNPSCHDSTS2REG_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS3REG_d, CNPSCHDSTS3REG_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS4REG_d, CNPSCHDSTS4REG_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS5REG_d, CNPSCHDSTS5REG_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS6REG_d, CNPSCHDSTS6REG_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS7REG_d, CNPSCHDSTS7REG_q;
//logic [REG_WIDTH-1:0] CNPSCHDSTS8REG_d, CNPSCHDSTS8REG_q;


typedef enum {WB_IDLE, WB_VALID} gen_wb_cmd_t;

gen_wb_cmd_t wb_CQHEADi_s_d, wb_CQHEADi_s_q;
wr_cmd_t wb_CQHEADi_cmd_d, wb_CQHEADi_cmd_q;
logic wb_CQHEADi_valid = 0;

always_comb begin
  wb_CQHEADi_s_d = wb_CQHEADi_s_q;
  wb_CQHEADi_cmd_d = wb_CQHEADi_cmd_q;
  case(wb_CQHEADi_s_q)
    WB_IDLE: begin
      if(WB_CQHEADi_valid_i) begin
        wb_CQHEADi_cmd_d.region = 'd2;
        wb_CQHEADi_cmd_d.bram_idx = CQHEADi_idx;
        wb_CQHEADi_cmd_d.address = WB_CQHEADi_i[39:32];
        wb_CQHEADi_cmd_d.wstrb = 'hf;
        wb_CQHEADi_cmd_d.data = WB_CQHEADi_i[31:0];
        wb_CQHEADi_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_CQHEADi_valid = 1'b1;
      wb_CQHEADi_s_d = WB_IDLE;
    end
  endcase
end


gen_wb_cmd_t wb_SQPSNi_s_d, wb_SQPSNi_s_q;
wr_cmd_t wb_SQPSNi_cmd_d, wb_SQPSNi_cmd_q;
logic wb_SQPSNi_valid = 0;

always_comb begin
  wb_SQPSNi_s_d = wb_SQPSNi_s_q;
  wb_SQPSNi_cmd_d = wb_SQPSNi_cmd_q;
  case(wb_SQPSNi_s_q)
    WB_IDLE: begin
      if(WB_SQPSNi_valid_i) begin
        wb_SQPSNi_cmd_d.region = 'd2;
        wb_SQPSNi_cmd_d.bram_idx = SQPSNi_idx;
        wb_SQPSNi_cmd_d.address = WB_SQPSNi_i[31:24];
        wb_SQPSNi_cmd_d.wstrb = 'b0111;
        wb_SQPSNi_cmd_d.data = {8'h0, WB_SQPSNi_i[23:0]};
        wb_SQPSNi_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_SQPSNi_valid = 1'b1;
      wb_SQPSNi_s_d = WB_IDLE;
    end
  endcase
end


gen_wb_cmd_t wb_LSTRQREQi_s_d, wb_LSTRQREQi_s_q;
wr_cmd_t wb_LSTRQREQi_cmd_d, wb_LSTRQREQi_cmd_q;
logic wb_LSTRQREQi_valid = 0;

always_comb begin
  wb_LSTRQREQi_s_d = wb_LSTRQREQi_s_q;
  wb_LSTRQREQi_cmd_d = wb_LSTRQREQi_cmd_q;
  case(wb_LSTRQREQi_s_q)
    WB_IDLE: begin
      if(WB_LSTRQREQi_valid_i) begin
        wb_LSTRQREQi_cmd_d.region = 'd2;
        wb_LSTRQREQi_cmd_d.bram_idx = LSTRQREQi_idx;
        wb_LSTRQREQi_cmd_d.address = WB_LSTRQREQi_i[31:24];
        wb_LSTRQREQi_cmd_d.wstrb = 'b0111;
        wb_LSTRQREQi_cmd_d.data = {8'h0, WB_LSTRQREQi_i[23:0]};
        wb_LSTRQREQi_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_LSTRQREQi_valid = 1'b1;
      wb_LSTRQREQi_s_d = WB_IDLE;
    end
  endcase
end


gen_wb_cmd_t wb_INSRRPKTCNT_s_d, wb_INSRRPKTCNT_s_q;
wr_cmd_t wb_INSRRPKTCNT_cmd_d, wb_INSRRPKTCNT_cmd_q;
logic wb_INSRRPKTCNT_valid = 0;

always_comb begin
  wb_INSRRPKTCNT_s_d = wb_INSRRPKTCNT_s_q;
  wb_INSRRPKTCNT_cmd_d = wb_INSRRPKTCNT_cmd_q;
  case(wb_INSRRPKTCNT_s_q)
    WB_IDLE: begin
      if(WB_INSRRPKTCNT_valid_i) begin
        wb_INSRRPKTCNT_cmd_d.region = 'd0;
        wb_INSRRPKTCNT_cmd_d.bram_idx = 'd0;
        wb_INSRRPKTCNT_cmd_d.address = ADDR_INSRRPKTCNT >> 2;
        wb_INSRRPKTCNT_cmd_d.wstrb = 'hf;
        wb_INSRRPKTCNT_cmd_d.data = WB_INSRRPKTCNT_i;
        wb_INSRRPKTCNT_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_INSRRPKTCNT_valid = 1'b1;
      wb_INSRRPKTCNT_s_d = WB_IDLE;
    end
  endcase
end

gen_wb_cmd_t wb_INAMPKTCNT_s_d, wb_INAMPKTCNT_s_q;
wr_cmd_t wb_INAMPKTCNT_cmd_d, wb_INAMPKTCNT_cmd_q;
logic wb_INAMPKTCNT_valid = 0;

always_comb begin
  wb_INAMPKTCNT_s_d = wb_INAMPKTCNT_s_q;
  wb_INAMPKTCNT_cmd_d = wb_INAMPKTCNT_cmd_q;
  case(wb_INAMPKTCNT_s_q)
    WB_IDLE: begin
      if(WB_INAMPKTCNT_valid_i) begin
        wb_INAMPKTCNT_cmd_d.region = 'd0;
        wb_INAMPKTCNT_cmd_d.bram_idx = 'd0;
        wb_INAMPKTCNT_cmd_d.address = ADDR_INAMPKTCNT >> 2;
        wb_INAMPKTCNT_cmd_d.wstrb = 'hf;
        wb_INAMPKTCNT_cmd_d.data = WB_INAMPKTCNT_i;
        wb_INAMPKTCNT_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_INAMPKTCNT_valid = 1'b1;
      wb_INAMPKTCNT_s_d = WB_IDLE;
    end
  endcase
end

gen_wb_cmd_t wb_INNCKPKTSTS_s_d, wb_INNCKPKTSTS_s_q;
wr_cmd_t wb_INNCKPKTSTS_cmd_d, wb_INNCKPKTSTS_cmd_q;
logic wb_INNCKPKTSTS_valid = 0;

always_comb begin
  wb_INNCKPKTSTS_s_d = wb_INNCKPKTSTS_s_q;
  wb_INNCKPKTSTS_cmd_d = wb_INNCKPKTSTS_cmd_q;
  case(wb_INNCKPKTSTS_s_q)
    WB_IDLE: begin
      if(WB_INNCKPKTSTS_valid_i) begin
        wb_INNCKPKTSTS_cmd_d.region = 'd0;
        wb_INNCKPKTSTS_cmd_d.bram_idx = 'd0;
        wb_INNCKPKTSTS_cmd_d.address = ADDR_INNCKPKTSTS >> 2;
        wb_INNCKPKTSTS_cmd_d.wstrb = 'hf;
        wb_INNCKPKTSTS_cmd_d.data = WB_INNCKPKTSTS_i;
        wb_INNCKPKTSTS_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_INNCKPKTSTS_valid = 1'b1;
      wb_INNCKPKTSTS_s_d = WB_IDLE;
    end
  endcase
end


gen_wb_cmd_t wb_OUTAMPKTCNT_s_d, wb_OUTAMPKTCNT_s_q;
wr_cmd_t wb_OUTAMPKTCNT_cmd_d, wb_OUTAMPKTCNT_cmd_q;
logic wb_OUTAMPKTCNT_valid= 0;

always_comb begin
  wb_OUTAMPKTCNT_s_d = wb_OUTAMPKTCNT_s_q;
  wb_OUTAMPKTCNT_cmd_d = wb_OUTAMPKTCNT_cmd_q;
  case(wb_OUTAMPKTCNT_s_q)
    WB_IDLE: begin
      if(WB_OUTAMPKTCNT_valid_i) begin
        wb_OUTAMPKTCNT_cmd_d.region = 'd0;
        wb_OUTAMPKTCNT_cmd_d.bram_idx = 'd0;
        wb_OUTAMPKTCNT_cmd_d.address = ADDR_OUTAMPKTCNT >> 2;
        wb_OUTAMPKTCNT_cmd_d.wstrb = 'hf;
        wb_OUTAMPKTCNT_cmd_d.data = WB_OUTAMPKTCNT_i;
        wb_OUTAMPKTCNT_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_OUTAMPKTCNT_valid = 1'b1;
      wb_OUTAMPKTCNT_s_d = WB_IDLE;
    end
  endcase
end

gen_wb_cmd_t wb_OUTNAKPKTCNT_s_d, wb_OUTNAKPKTCNT_s_q;
wr_cmd_t wb_OUTNAKPKTCNT_cmd_d, wb_OUTNAKPKTCNT_cmd_q;
logic wb_OUTNAKPKTCNT_valid = 0;

always_comb begin
  wb_OUTNAKPKTCNT_s_d = wb_OUTNAKPKTCNT_s_q;
  wb_OUTNAKPKTCNT_cmd_d = wb_OUTNAKPKTCNT_cmd_q;
  case(wb_OUTNAKPKTCNT_s_q)
    WB_IDLE: begin
      if(WB_OUTNAKPKTCNT_valid_i) begin
        wb_OUTNAKPKTCNT_cmd_d.region = 'd0;
        wb_OUTNAKPKTCNT_cmd_d.bram_idx = 'd0;
        wb_OUTNAKPKTCNT_cmd_d.address = ADDR_OUTNAKPKTCNT >> 2;
        wb_OUTNAKPKTCNT_cmd_d.wstrb = 'b0011;
        wb_OUTNAKPKTCNT_cmd_d.data = {16'h0, WB_OUTNAKPKTCNT_i};
        wb_OUTNAKPKTCNT_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_OUTNAKPKTCNT_valid = 1'b1;
      wb_OUTNAKPKTCNT_s_d = WB_IDLE;
    end
  endcase
end

gen_wb_cmd_t wb_OUTIOPKTCNT_s_d, wb_OUTIOPKTCNT_s_q;
wr_cmd_t wb_OUTIOPKTCNT_cmd_d, wb_OUTIOPKTCNT_cmd_q;
logic wb_OUTIOPKTCNT_valid = 0;

always_comb begin
  wb_OUTIOPKTCNT_s_d = wb_OUTIOPKTCNT_s_q;
  wb_OUTIOPKTCNT_cmd_d = wb_OUTIOPKTCNT_cmd_q;
  case(wb_OUTIOPKTCNT_s_q)
    WB_IDLE: begin
      if(WB_OUTIOPKTCNT_valid_i) begin
        wb_OUTIOPKTCNT_cmd_d.region = 'd0;
        wb_OUTIOPKTCNT_cmd_d.bram_idx = 'd0;
        wb_OUTIOPKTCNT_cmd_d.address = ADDR_OUTIOPKTCNT >> 2;
        wb_OUTIOPKTCNT_cmd_d.wstrb = 'hf;
        wb_OUTIOPKTCNT_cmd_d.data = WB_OUTIOPKTCNT_i;
        wb_OUTIOPKTCNT_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_OUTIOPKTCNT_valid = 1'b1;
      wb_OUTIOPKTCNT_s_d = WB_IDLE;
    end
  endcase
end

gen_wb_cmd_t wb_OUTRDRSPPKTCNT_s_d, wb_OUTRDRSPPKTCNT_s_q;
wr_cmd_t wb_OUTRDRSPPKTCNT_cmd_d, wb_OUTRDRSPPKTCNT_cmd_q;
logic wb_OUTRDRSPPKTCNT_valid = 0;

always_comb begin
  wb_OUTRDRSPPKTCNT_s_d = wb_OUTRDRSPPKTCNT_s_q;
  wb_OUTRDRSPPKTCNT_cmd_d = wb_OUTRDRSPPKTCNT_cmd_q;
  case(wb_OUTRDRSPPKTCNT_s_q)
    WB_IDLE: begin
      if(WB_OUTRDRSPPKTCNT_valid_i) begin
        wb_OUTRDRSPPKTCNT_cmd_d.region = 'd0;
        wb_OUTRDRSPPKTCNT_cmd_d.bram_idx = 'd0;
        wb_OUTRDRSPPKTCNT_cmd_d.address = ADDR_OUTRDRSPPKTCNT >> 2;
        wb_OUTRDRSPPKTCNT_cmd_d.wstrb = 'hf;
        wb_OUTRDRSPPKTCNT_cmd_d.data = WB_OUTRDRSPPKTCNT_i;
        wb_OUTRDRSPPKTCNT_s_d = WB_VALID;
      end
    end
    WB_VALID: begin
      wb_OUTRDRSPPKTCNT_valid = 1'b1;
      wb_OUTRDRSPPKTCNT_s_d = WB_IDLE;
    end
  endcase
end


rd_cmd_t rd_sq_vaddr_d, rd_sq_vaddr_q;
logic rd_sq_vaddr_valid_d, rd_sq_vaddr_valid_q;
logic config_sq;

logic [7:0] pd_addr_d, pd_addr_q;
logic find_pd_addr_rd, find_pd_addr_wr;

always_comb begin
  rd_sq_vaddr_d = rd_sq_vaddr_q;
  rd_sq_vaddr_valid_d = rd_sq_vaddr_valid_q;
  l_reg_st_d = l_reg_st_q;
  l_rd_cmd_d = l_rd_cmd_q;
  l_wr_cmd_d = l_wr_cmd_q;

  pdnum_table_d = pdnum_table_q;
  QPidx_d = QPidx_q;
  hold_axis_d = hold_axis_q;
  cmd_fifo_rd_en = 1'b0;
  qp_configured_o = 1'b0;
  conn_configured_o = 1'b0;
  sq_updated_o = 1'b0;
  config_sq = 1'b0;
  rd_qp_ready_o = 1'b0;
  find_pd_rd_ready = 1'b0;
  find_pd_wr_ready = 1'b0;
    
  PD_REG_WEB_AXIS = 'd0;
  PD_REG_ENB_AXIS = 'd0;
  PD_ADDR_AXIS = 'd0;
  PD_WR_REG_AXIS = 'd0;

  QP_REG_WEB_AXIS = 'd0;
  QP_REG_ENB_AXIS = 'd0;
  QP_ADDR_AXIS = 'd0;
  QP_WR_REG_AXIS = 'd0;

  GLB_REG_WEB_AXIS = 'd0;
  GLB_REG_ENB_AXIS = 'd0;
  GLB_ADDR_AXIS = 'd0;
  GLB_WR_REG_AXIS = 'd0;

  CONF_d = CONF_q;
  MACADDLSB_d = MACADDLSB_q;
  MACADDMSB_d = MACADDMSB_q;
  IPv4ADD_d = IPv4ADD_q;

  PD_RD_REG_AXIS_D = PD_RD_REG_AXIS_Q;
  QP_RD_REG_AXIS_D = QP_RD_REG_AXIS_Q;

  case(l_reg_st_q)
    L_IDLE: begin
      if(rd_sq_vaddr_valid_q && !writing) begin
        rd_sq_vaddr_valid_d = 1'b0;
        l_rd_cmd_d = rd_sq_vaddr_q;
        l_reg_st_d = L_READ_MULTI;
      end else if (!cmd_fifo_empty && !writing) begin // && !writing in different clock domain??
        cmd_fifo_rd_en = 1'b1;
        l_reg_st_d = L_READ_CMD;
      end else if(rd_qp_valid_i && !writing) begin
        l_rd_cmd_d = rd_qp_i;
        if(rd_qp_i.read_all) begin
          l_reg_st_d = L_READ_MULTI;
        end else begin
          l_reg_st_d = L_READ_SINGLE;
        end
      end else if(find_pd_rd_valid && !writing) begin
        find_pd_rd_valid = 1'b0;
        l_rd_cmd_d = find_pd_rd_q;
        if(find_pd_rd_q.read_all) begin
          l_reg_st_d = L_READ_MULTI;
        end else begin
          l_reg_st_d = L_READ_SINGLE;
        end
      end else if(find_pd_wr_valid && !writing) begin
        find_pd_wr_valid = 1'b0;
        l_rd_cmd_d = find_pd_wr_q;
        if(find_pd_wr_q.read_all) begin
          l_reg_st_d = L_READ_MULTI;
        end else begin
          l_reg_st_d = L_READ_SINGLE;
        end
      
      end else if(wb_CQHEADi_valid && !writing) begin
        wb_CQHEADi_valid = 1'b0;
        l_wr_cmd_d = wb_CQHEADi_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_SQPSNi_valid && !writing) begin
        wb_SQPSNi_valid = 1'b0;
        l_wr_cmd_d = wb_SQPSNi_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_LSTRQREQi_valid && !writing) begin
        wb_LSTRQREQi_valid = 1'b0;
        l_wr_cmd_d = wb_LSTRQREQi_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_INSRRPKTCNT_valid && !writing) begin
        wb_INSRRPKTCNT_valid = 1'b0;
        l_wr_cmd_d = wb_INSRRPKTCNT_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_INAMPKTCNT_valid && !writing) begin
        wb_INAMPKTCNT_valid = 1'b0;
        l_wr_cmd_d = wb_INAMPKTCNT_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_INNCKPKTSTS_valid && !writing) begin
        wb_INNCKPKTSTS_valid = 1'b0;
        l_wr_cmd_d = wb_INNCKPKTSTS_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_OUTAMPKTCNT_valid && !writing) begin
        wb_OUTAMPKTCNT_valid = 1'b0;
        l_wr_cmd_d = wb_OUTAMPKTCNT_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_OUTNAKPKTCNT_valid && !writing) begin
        wb_OUTNAKPKTCNT_valid = 1'b0;
        l_wr_cmd_d = wb_OUTNAKPKTCNT_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_OUTIOPKTCNT_valid && !writing) begin
        wb_OUTIOPKTCNT_valid = 1'b0;
        l_wr_cmd_d = wb_OUTIOPKTCNT_cmd_q;
        l_reg_st_d = L_WRITE;
      end else if(wb_OUTRDRSPPKTCNT_valid && !writing) begin
        wb_OUTRDRSPPKTCNT_valid = 1'b0;
        l_wr_cmd_d = wb_OUTRDRSPPKTCNT_cmd_q;
        l_reg_st_d = L_WRITE;
      end
    end
    L_READ_CMD: begin
      cmd_fifo_rd_en = 1'b1;
      if(cmd_fifo_out_valid) begin
        cmd_fifo_rd_en = 1'b0;
        l_rd_cmd_d = cmd_fifo_out;
        if( cmd_fifo_out.read_all ) begin
          l_reg_st_d = L_READ_MULTI;
        end else begin
          l_reg_st_d = L_READ_SINGLE;
        end
      end
    end
    L_READ_SINGLE: begin
      if(l_rd_cmd_q.region == 2'b0) begin
        GLB_ADDR_AXIS = l_rd_cmd_q.address;
        GLB_REG_ENB_AXIS = 1'b1;
        case(l_rd_cmd_q.address << 2)
          ADDR_CONF: begin
            CONF_d = GLB_RD_REG_AXIS;
          end
          ADDR_MACADDLSB: begin
            MACADDLSB_d = GLB_RD_REG_AXIS;
          end
          ADDR_MACADDMSB: begin
            MACADDMSB_d = GLB_RD_REG_AXIS;
          end
          ADDR_IPv4ADD: begin
            IPv4ADD_d = GLB_RD_REG_AXIS; 
          end
        endcase
      end else if (l_rd_cmd_q.region == 2'b01) begin
        PD_ADDR_AXIS = l_rd_cmd_q.address;
        PD_REG_ENB_AXIS[l_rd_cmd_q.bram_idx] = 1'b1;
        PD_RD_REG_AXIS_D[l_rd_cmd_q.bram_idx] = PD_RD_REG_AXIS[l_rd_cmd_q.bram_idx];
      end else if (l_rd_cmd_q.region == 2'b10) begin
        QP_ADDR_AXIS = l_rd_cmd_q.address;
        QP_REG_ENB_AXIS[l_rd_cmd_q.bram_idx] = 1'b1;
        QP_RD_REG_AXIS_D[l_rd_cmd_q.bram_idx] = QP_RD_REG_AXIS[l_rd_cmd_q.bram_idx];
      end else begin
        l_reg_st_d = L_IDLE;
      end
      
      if(hold_axis_q == RD_LAT) begin
        hold_axis_d = 'd0;
        l_reg_st_d = L_READ_READY;
      end else begin
        hold_axis_d = hold_axis_q + 'd1;
        l_reg_st_d = L_READ_SINGLE;
      end
    
    end
    L_READ_MULTI: begin
      if (l_rd_cmd_q.region == 2'b01) begin
        PD_ADDR_AXIS = l_rd_cmd_q.address;
        PD_REG_ENB_AXIS = ~0;
        PD_RD_REG_AXIS_D = PD_RD_REG_AXIS;
      end else if (l_rd_cmd_q.region == 2'b10) begin
        QPidx_d = l_rd_cmd_q.address;
        QP_ADDR_AXIS = l_rd_cmd_q.address;
        QP_REG_ENB_AXIS = ~0;
        QP_RD_REG_AXIS_D = QP_RD_REG_AXIS;
      end else begin
        l_reg_st_d = L_IDLE;
      end

      if(hold_axis_q == RD_LAT) begin
        hold_axis_d = 'd0;
        l_reg_st_d = L_READ_READY;
      end else begin
        hold_axis_d = hold_axis_q + 'd1;
        l_reg_st_d = L_READ_MULTI;
      end
    end
    L_READ_READY: begin
      if(l_rd_cmd_q.region == 'd2) begin
        if(l_rd_cmd_q.bram_idx == SQPSNi_idx || l_rd_cmd_q.bram_idx == LSTRQREQi_idx) begin
          qp_configured_o = 1'b1;
          l_reg_st_d = L_IDLE;
        end else if (l_rd_cmd_q.bram_idx == DESTQPCONFi_idx || l_rd_cmd_q.bram_idx == IPDESADDR1i_idx) begin
          conn_configured_o = 1'b1;
          l_reg_st_d = L_IDLE;
        end else if(l_rd_cmd_q.bram_idx == SQPIi_idx) begin
          config_sq = 1'b1;
          l_reg_st_d = L_READ_VADDR;
        end else if (l_rd_cmd_q.bram_idx == NUM_QP_REGS) begin
          rd_qp_ready_o = 1'b1;
          l_reg_st_d = L_IDLE;
        end else if (l_rd_cmd_q.bram_idx == PDNUMi_idx) begin
          find_pd_rd_ready = 1'b1;
          find_pd_wr_ready = 1'b1;
          l_reg_st_d = L_IDLE;
        end else begin
          l_reg_st_d = L_IDLE;
        end
      end else if(l_rd_cmd_q.region == 'd1) begin
        if (l_rd_cmd_q.bram_idx == PDPDNUM_idx) begin
          pdnum_table_d[l_rd_cmd_q.address] = {l_rd_cmd_q.address, PD_RD_REG_AXIS_Q[PDPDNUM_idx][23:0]};
        end else if(l_rd_cmd_q.bram_idx == VIRTADDRLSB_idx) begin
          sq_updated_o = 1'b1;
        end else if (l_rd_cmd_q.bram_idx == PDNUMi_idx) begin //abuse PDNUMi_idx for ready signal in phys addr lookup
          find_pd_rd_ready = 1'b1;
          find_pd_wr_ready = 1'b1;
        end
        l_reg_st_d = L_IDLE;
      end else begin
        l_reg_st_d = L_IDLE;
      end
    end
    L_READ_VADDR: begin
      rd_sq_vaddr_d.region = 'd1;
      rd_sq_vaddr_d.read_all = 1'b1;
      rd_sq_vaddr_d.bram_idx = VIRTADDRLSB_idx;
      rd_sq_vaddr_d.address = pd_addr_q;
      rd_sq_vaddr_valid_d = 1'b1;
      l_reg_st_d = L_IDLE;
    end
    L_WRITE: begin
      if(l_wr_cmd_q.region == 'd0) begin
        GLB_ADDR_AXIS = l_wr_cmd_q.address;
        GLB_REG_WEB_AXIS = l_wr_cmd_q.wstrb;
        GLB_WR_REG_AXIS = l_wr_cmd_q.data;
        GLB_REG_ENB_AXIS = 1'b1;
      end else if (l_wr_cmd_q.region == 'd1) begin
        PD_ADDR_AXIS = l_wr_cmd_q.address;
        PD_REG_WEB_AXIS = l_wr_cmd_q.wstrb;
        PD_WR_REG_AXIS = l_wr_cmd_q.data;
        PD_REG_ENB_AXIS[l_wr_cmd_q.bram_idx] = 1'b1;
      end else if (l_wr_cmd_q.region == 'd2) begin
        QP_ADDR_AXIS = l_wr_cmd_q.address;
        QP_REG_WEB_AXIS = l_wr_cmd_q.wstrb;
        QP_WR_REG_AXIS = l_wr_cmd_q.data;
        QP_REG_ENB_AXIS[l_wr_cmd_q.bram_idx] = 1'b1;
      end
      if(hold_axis_q == 'd1) begin
        hold_axis_d = 'd0;
        l_reg_st_d = L_IDLE;
      end else begin
        hold_axis_d = hold_axis_q + 'd1;
        l_reg_st_d = L_WRITE;
      end
    end
  endcase
end





always_comb begin
  pd_addr_d = pd_addr_q;
  if(find_pd_addr_rd | find_pd_addr_wr | config_sq) begin
    for(int i=0; i < NUM_PD; i++) begin
      if(pdnum_table_q[i] == QP_RD_REG_AXIS_Q[PDNUMi_idx][23:0]) begin
        pd_addr_d = i;
      end
    end
  end
end

always_comb begin
  rd_req_addr_ready_o = 1'b1;
  rd_resp_addr_valid_o = 1'b0;
  rd_resp_addr_data_d = rd_resp_addr_data_q;
  rd_vtp_st_d = rd_vtp_st_q;
  
  find_pd_addr_rd = 1'b0;
  find_pd_rd_d = find_pd_rd_q;


  case(rd_vtp_st_q)
  VTP_IDLE: begin
    if(rd_req_addr_valid_i && rd_req_addr_ready_o) begin
      rd_req_addr_ready_o = 1'b0;
      rd_resp_addr_data_d.accesdesc = ~0;
      rd_resp_addr_data_d.rkey = ~0;
      rd_resp_addr_data_d.buflen = ~0;
      rd_resp_addr_data_d.paddr = ~0;

      if(rd_req_addr_vaddr_i == 'd0) begin
        rd_resp_addr_data_d.accesdesc = 'd0;
        rd_resp_addr_data_d.buflen = ~0;
        rd_resp_addr_data_d.rkey = ~0;
        rd_resp_addr_data_d.paddr = 'd0;
        rd_vtp_st_d = VTP_VALID;
      end else begin
        find_pd_rd_d.region = 'd2;
        find_pd_rd_d.read_all = 1'b1;
        find_pd_rd_d.bram_idx = PDNUMi_idx;
        find_pd_rd_d.address = rd_req_addr_qpn_i[LOG_NUM_QP-1:0];
        rd_vtp_st_d = VTP_RD_PDN_VLD;
      end
    end
  end
  VTP_RD_PDN_VLD: begin
    rd_req_addr_ready_o = 1'b0;
    find_pd_rd_valid = 1'b1;
    rd_vtp_st_d = VTP_RD_PDN;
  end
  VTP_RD_PDN: begin
    rd_req_addr_ready_o = 1'b0;
    if(find_pd_rd_ready) begin
      find_pd_addr_rd = 1'b1;
      rd_vtp_st_d = VTP_REQ_PD;
    end
  end
  VTP_REQ_PD: begin
    rd_req_addr_ready_o = 1'b0;
    find_pd_rd_d.region = 'd1;
    find_pd_rd_d.read_all = 1'b1;
    find_pd_rd_d.bram_idx = PDNUMi_idx;
    find_pd_rd_d.address = pd_addr_q;
    rd_vtp_st_d = VTP_PREP_RESP_VLD;
  end
  VTP_PREP_RESP_VLD: begin
    rd_req_addr_ready_o = 1'b0;
    find_pd_rd_valid = 1'b1;
    rd_vtp_st_d = VTP_PREP_RESP;
  end
  VTP_PREP_RESP: begin
    rd_req_addr_ready_o = 1'b0;
    if(find_pd_rd_ready) begin
      if(rd_req_addr_vaddr_i == {PD_RD_REG_AXIS_Q[VIRTADDRMSB_idx], PD_RD_REG_AXIS_Q[VIRTADDRLSB_idx]}) begin
        rd_resp_addr_data_d.accesdesc = PD_RD_REG_AXIS_Q[ACCESSDESC_idx][3:0];
        rd_resp_addr_data_d.buflen = {PD_RD_REG_AXIS_Q[ACCESSDESC_idx][31:16], PD_RD_REG_AXIS_Q[WRRDBUFLEN_idx]};
        rd_resp_addr_data_d.rkey = PD_RD_REG_AXIS_Q[BUFRKEY_idx][7:0];
        rd_resp_addr_data_d.paddr = {PD_RD_REG_AXIS_Q[BUFBASEADDRMSB_idx], PD_RD_REG_AXIS_Q[BUFBASEADDRLSB_idx]};
      end
      rd_vtp_st_d = VTP_VALID;
    end
  end
  VTP_VALID: begin
    rd_req_addr_ready_o = 1'b0;
    rd_resp_addr_valid_o = 1'b1;
    if(rd_resp_addr_ready_i) begin
      rd_vtp_st_d = VTP_IDLE;
    end
  end
  endcase
end



always_comb begin
  wr_req_addr_ready_o = 1'b1;
  wr_resp_addr_valid_o = 1'b0;
  wr_resp_addr_data_d = wr_resp_addr_data_q;
  wr_vtp_st_d = wr_vtp_st_q;
  find_pd_addr_wr = 1'b0;
  find_pd_wr_d = find_pd_wr_q;


  case(wr_vtp_st_q)
  VTP_IDLE: begin
    if(wr_req_addr_valid_i && wr_req_addr_ready_o) begin
      wr_req_addr_ready_o = 1'b0;
      wr_resp_addr_data_d.accesdesc = ~0;
      wr_resp_addr_data_d.rkey = ~0;
      wr_resp_addr_data_d.buflen = ~0;
      wr_resp_addr_data_d.paddr = ~0;

      //lookup defined qpn of the request of the request
      find_pd_wr_d.region = 'd2;
      find_pd_wr_d.read_all = 1'b1;
      find_pd_wr_d.bram_idx = PDNUMi_idx;
      find_pd_wr_d.address = wr_req_addr_qpn_i[LOG_NUM_QP-1:0];
      wr_vtp_st_d = VTP_RD_PDN_VLD;
    end
  end
  VTP_RD_PDN_VLD: begin
    wr_req_addr_ready_o = 1'b0;
    find_pd_wr_valid = 1'b1;
    wr_vtp_st_d = VTP_RD_PDN;
  end
  VTP_RD_PDN: begin
    wr_req_addr_ready_o = 1'b0;
    if(find_pd_wr_ready) begin
      if(wr_req_addr_vaddr_i == 'd0) begin 
          wr_resp_addr_data_d.accesdesc = 4'b0010;
          wr_resp_addr_data_d.buflen = ~0;
          wr_resp_addr_data_d.rkey = ~0;
          wr_resp_addr_data_d.paddr = {QP_RD_REG_AXIS_Q[RQBAMSBi_idx], QP_RD_REG_AXIS[RQBAi_idx]};
          wr_vtp_st_d = VTP_VALID;
      end else begin
        find_pd_addr_wr = 1'b1;
        wr_vtp_st_d = VTP_REQ_PD;
      end
    end
  end
  VTP_REQ_PD: begin
    wr_req_addr_ready_o = 1'b0;
    find_pd_wr_d.region = 'd1;
    find_pd_wr_d.read_all = 1'b1;
    find_pd_wr_d.bram_idx = PDNUMi_idx;
    find_pd_wr_d.address = pd_addr_q;
    wr_vtp_st_d = VTP_PREP_RESP_VLD;
  end
  VTP_PREP_RESP_VLD: begin
    wr_req_addr_ready_o = 1'b0;
    find_pd_wr_valid = 1'b1;
    wr_vtp_st_d = VTP_PREP_RESP;
  end
  VTP_PREP_RESP: begin
    wr_req_addr_ready_o = 1'b0;
    if(find_pd_wr_ready) begin
      if(wr_req_addr_vaddr_i == {PD_RD_REG_AXIS_Q[VIRTADDRMSB_idx], PD_RD_REG_AXIS_Q[VIRTADDRLSB_idx]}) begin
        wr_resp_addr_data_d.accesdesc = PD_RD_REG_AXIS_Q[ACCESSDESC_idx][3:0];
        wr_resp_addr_data_d.buflen = {PD_RD_REG_AXIS_Q[ACCESSDESC_idx][31:16], PD_RD_REG_AXIS_Q[WRRDBUFLEN_idx]};
        wr_resp_addr_data_d.rkey = PD_RD_REG_AXIS_Q[BUFRKEY_idx][7:0];
        wr_resp_addr_data_d.paddr = {PD_RD_REG_AXIS_Q[BUFBASEADDRMSB_idx], PD_RD_REG_AXIS_Q[BUFBASEADDRLSB_idx]};
      end  
      wr_vtp_st_d = VTP_VALID;
    end
  end
  VTP_VALID: begin
    wr_req_addr_ready_o = 1'b0;
    wr_resp_addr_valid_o = 1'b1;
    if(wr_resp_addr_ready_i) begin
      wr_vtp_st_d = VTP_IDLE;
    end
  end
  endcase
end


always_ff @(posedge axis_aclk_i, negedge axis_rstn_i) begin
  if(!axis_rstn_i) begin
    l_reg_st_q <= L_IDLE;
    l_rd_cmd_q <= 'd0;
    l_wr_cmd_q <= 'd0;
    hold_axis_q <= 'd0;
    QPidx_q <= 'd0;

    rd_sq_vaddr_q <= 'd0;
    rd_sq_vaddr_valid_q <= 'd0;

    CONF_q <= 'd0;
    MACADDLSB_q <= 'd0;
    MACADDMSB_q <= 'd0;
    IPv4ADD_q <= 'd0;

    PD_RD_REG_AXIS_Q <= 'd0;
    QP_RD_REG_AXIS_Q <= 'd0;
    
    rd_vtp_st_q <= VTP_IDLE;
    wr_vtp_st_q <= VTP_IDLE;
    rd_resp_addr_data_q <= 'd0;
    wr_resp_addr_data_q <= 'd0;

    
    find_pd_rd_q <= 'd0;
    find_pd_wr_q <= 'd0;
    pdnum_table_q <= ~0;
    pd_addr_q <= ~0;

    wb_CQHEADi_s_q <= WB_IDLE;
    wb_CQHEADi_cmd_q <= 'd0;

    wb_SQPSNi_s_q <= WB_IDLE;
    wb_SQPSNi_cmd_q <= 'd0;

    wb_LSTRQREQi_s_q <= WB_IDLE;
    wb_LSTRQREQi_cmd_q <= 'd0;

    wb_INSRRPKTCNT_s_q <= WB_IDLE;
    wb_INSRRPKTCNT_cmd_q <= 'd0;

    wb_INAMPKTCNT_s_q <= WB_IDLE;
    wb_INAMPKTCNT_cmd_q <= 'd0;

    wb_INNCKPKTSTS_s_q <= WB_IDLE;
    wb_INNCKPKTSTS_cmd_q <= 'd0;

    wb_OUTAMPKTCNT_s_q <= WB_IDLE;
    wb_OUTAMPKTCNT_cmd_q <= 'd0;

    wb_OUTNAKPKTCNT_s_q <= WB_IDLE;
    wb_OUTNAKPKTCNT_cmd_q <= 'd0;

    wb_OUTIOPKTCNT_s_q <= WB_IDLE;
    wb_OUTIOPKTCNT_cmd_q <= 'd0;

    wb_OUTRDRSPPKTCNT_s_q <= WB_IDLE;
    wb_OUTRDRSPPKTCNT_cmd_q <= 'd0;
  end else begin
    l_reg_st_q <= l_reg_st_d;
    l_rd_cmd_q <= l_rd_cmd_d;
    l_wr_cmd_q <= l_wr_cmd_d;
    hold_axis_q <= hold_axis_d;
    QPidx_q <= QPidx_d;

    rd_sq_vaddr_q <= rd_sq_vaddr_d;
    rd_sq_vaddr_valid_q <= rd_sq_vaddr_valid_d;

    CONF_q <= CONF_d;
    MACADDLSB_q <= MACADDLSB_d;
    MACADDMSB_q <= MACADDMSB_d;
    IPv4ADD_q <= IPv4ADD_d;

    PD_RD_REG_AXIS_Q <= PD_RD_REG_AXIS_D;
    QP_RD_REG_AXIS_Q <= QP_RD_REG_AXIS_D;
   
    rd_vtp_st_q <= rd_vtp_st_d;
    wr_vtp_st_q <= wr_vtp_st_d;
    rd_resp_addr_data_q <= rd_resp_addr_data_d;
    wr_resp_addr_data_q <= wr_resp_addr_data_d;

    find_pd_rd_q <= find_pd_rd_d;
    find_pd_wr_q <= find_pd_wr_d;
    pdnum_table_q <= pdnum_table_d;
    pd_addr_q <= pd_addr_d;

    wb_CQHEADi_s_q <= wb_CQHEADi_s_d;
    wb_CQHEADi_cmd_q <= wb_CQHEADi_cmd_d;

    wb_SQPSNi_s_q <= wb_SQPSNi_s_d;
    wb_SQPSNi_cmd_q <= wb_SQPSNi_cmd_d;

    wb_LSTRQREQi_s_q <= wb_LSTRQREQi_s_d;
    wb_LSTRQREQi_cmd_q <= wb_LSTRQREQi_cmd_d;

    wb_INSRRPKTCNT_s_q <= wb_INSRRPKTCNT_s_d;
    wb_INSRRPKTCNT_cmd_q <= wb_INSRRPKTCNT_cmd_d;

    wb_INAMPKTCNT_s_q <= wb_INAMPKTCNT_s_d;
    wb_INAMPKTCNT_cmd_q <= wb_INAMPKTCNT_cmd_d;

    wb_INNCKPKTSTS_s_q <= wb_INNCKPKTSTS_s_d;
    wb_INNCKPKTSTS_cmd_q <= wb_INNCKPKTSTS_cmd_d;

    wb_OUTAMPKTCNT_s_q <= wb_OUTAMPKTCNT_s_d;
    wb_OUTAMPKTCNT_cmd_q <= wb_OUTAMPKTCNT_cmd_d;

    wb_OUTNAKPKTCNT_s_q <= wb_OUTNAKPKTCNT_s_d;
    wb_OUTNAKPKTCNT_cmd_q <= wb_OUTNAKPKTCNT_cmd_d;

    wb_OUTIOPKTCNT_s_q <= wb_OUTIOPKTCNT_s_d;
    wb_OUTIOPKTCNT_cmd_q <= wb_OUTIOPKTCNT_cmd_d;

    wb_OUTRDRSPPKTCNT_s_q <= wb_OUTRDRSPPKTCNT_s_d;
    wb_OUTRDRSPPKTCNT_cmd_q <= wb_OUTRDRSPPKTCNT_cmd_d;
  end
end

assign rd_resp_addr_data_o = rd_resp_addr_data_q;
assign wr_resp_addr_data_o = wr_resp_addr_data_q;


////////////////////
//                //
//  CDC CMD FIFO  //
//                //
////////////////////
reg_cmd_cdc_fifo reg_cmd_cdc_fifo_inst (
  //write
  .full(cmd_fifo_full),
  .din(cmd_fifo_in),
  .wr_en(cmd_fifo_wr_en),
  .wr_ack(cmd_fifo_in_ack),
  //read
  .empty(cmd_fifo_empty),
  .dout(cmd_fifo_out),
  .rd_en(cmd_fifo_rd_en),
  .valid(cmd_fifo_out_valid),

  .wr_clk(axil_aclk_i),
  .rd_clk(axis_aclk_i),
  .srst(!axil_rstn_i),

  .wr_rst_busy(cmd_fifo_wr_rst_busy),
  .rd_rst_busy(cmd_fifo_rd_rst_busy)
);



////////////////////////////
//                        //
//  REGISTER DEFINITIONS  //
//                        //
////////////////////////////



//Protection Domain
generate
  for (genvar i = 0; i < NUM_PD_REGS; i++) begin : pd_regs
    block_ram_1k PD_CONF_inst (
      .addra(PD_ADDR_AXIL),
      .dina(PD_WR_REG_AXIL),
      .douta(PD_RD_REG_AXIL[i]),
      .ena(PD_REG_ENA_AXIL[i]),
      .wea(PD_REG_WEA_AXIL),
      .clka(axil_aclk_i),
      .rsta(!axil_rstn_i),
      .addrb(PD_ADDR_AXIS),
      .dinb(PD_WR_REG_AXIS),
      .doutb(PD_RD_REG_AXIS[i]),
      .enb(PD_REG_ENB_AXIS[i]),
      .web(PD_REG_WEB_AXIS),
      .clkb(axis_aclk_i)
    );
  end
endgenerate

//GLobal config
block_ram_1k GLBCONF_inst (
  .addra(GLB_ADDR_AXIL),
  .dina(GLB_WR_REG_AXIL),
  .douta(GLB_RD_REG_AXIL),
  .ena(GLB_REG_ENA_AXIL),
  .wea(GLB_REG_WEA_AXIL),
  .clka(axil_aclk_i),
  .rsta(!axil_rstn_i),
  .addrb(GLB_ADDR_AXIS),
  .dinb(GLB_WR_REG_AXIS), 
  .doutb(GLB_RD_REG_AXIS),
  .enb(GLB_REG_ENB_AXIS),
  .web(GLB_REG_WEB_AXIS),
  .clkb(axis_aclk_i)
);

//Per QP config //TODO: make a for loop
generate
  for (genvar i = 0; i < NUM_QP_REGS; i++) begin : qp_regs
    block_ram_1k PER_QP_inst (
      .addra(QP_ADDR_AXIL),
      .dina(QP_WR_REG_AXIL),
      .douta(QP_RD_REG_AXIL[i]),
      .ena(QP_REG_ENA_AXIL[i]),
      .wea(QP_REG_WEA_AXIL),
      .clka(axil_aclk_i),
      .rsta(!axil_rstn_i),
      .addrb(QP_ADDR_AXIS),
      .dinb(QP_WR_REG_AXIS),
      .doutb(QP_RD_REG_AXIS[i]),
      .enb(QP_REG_ENB_AXIS[i]),
      .web(QP_REG_WEB_AXIS),
      .clkb(axis_aclk_i)
    );
  end
endgenerate






//////////////
//          //
//    IO    //
//          //
//////////////

assign s_axil_rdata_o = RDataReg_q;
assign s_axil_rresp_o = RRespReg_q;
assign s_axil_bresp_o = WRespReg_q;

assign CONF_o = CONF_q;
//assign ADCONF_o = ADCONF_q;
assign MACADD_o = {MACADDMSB_q[15:0], MACADDLSB_q};
assign IPv4ADD_o = IPv4ADD_q;
//assign INTEN_o = INTEN_q;
//assign ERRBUFBA_o = {ERRBUFBAMSB_q, ERRBUFBA_q};
//assign ERRBUFSZ_o = ERRBUFSZ_q;
//assign IPKTERRQBA_o = {IPKTERRQBAMSB_q, IPKTERRQBA_q};
//assign IPKTERRQSZ_o = IPKTERRQSZ_q;
//assign DATBUFBA_o = {DATBUFBAMSB_q, DATBUFBA_q};
//assign DATBUFSZ_o = DATBUFSZ_q;
//assign RESPERRPKTBA_o = {RESPERRPKTBAMSB_q, RESPERRPKTBA_q};
//assign RESPERRSZ_o = {RESPERRSZMSB_q, RESPERRSZ_q};

assign QPidx_o = QPidx_q;




//That's a mux...
assign QPCONFi_o      = QP_RD_REG_AXIS_Q[QPCONFi_idx];
//assign QPADVCONFi_o   = QP_RD_REG_AXIS_Q[QPADVCONFi_idx];
assign RQBAi_o        = {QP_RD_REG_AXIS_Q[RQBAMSBi_idx], QP_RD_REG_AXIS_Q[RQBAi_idx]};

assign SQBAi_o        = {QP_RD_REG_AXIS_Q[SQBAMSBi_idx], QP_RD_REG_AXIS_Q[SQBAi_idx]};
assign CQBAi_o        = {QP_RD_REG_AXIS_Q[CQBAMSBi_idx], QP_RD_REG_AXIS_Q[CQBAi_idx]};
assign SQPIi_o        = QP_RD_REG_AXIS_Q[SQPIi_idx];
assign CQHEADi_o      = QP_RD_REG_AXIS_Q[CQHEADi_idx];

//assign RQWPTRDBADDi_o = {QP_RD_REG_AXIS_Q[RQWPTRDBADDMSBi_idx], QP_RD_REG_AXIS_Q[RQWPTRDBADDi_idx]};
//assign CQDBADDi_o     = {QP_RD_REG_AXIS_Q[CQDBADDMSBi_idx],     QP_RD_REG_AXIS_Q[CQDBADDi_idx]};

//assign QDEPTHi_o      = QP_RD_REG_AXIS_Q[QDEPTHi_idx];
assign SQPSNi_o       = QP_RD_REG_AXIS_Q[SQPSNi_idx][23:0];
assign LSTRQREQi_o    = QP_RD_REG_AXIS_Q[LSTRQREQi_idx];
assign DESTQPCONFi_o  = QP_RD_REG_AXIS_Q[DESTQPCONFi_idx][23:0];


assign MACDESADDi_o   = {QP_RD_REG_AXIS_Q[MACDESADDMSBi_idx][15:0], QP_RD_REG_AXIS_Q[MACDESADDLSBi_idx]};
assign IPDESADDR1i_o  = QP_RD_REG_AXIS_Q[IPDESADDR1i_idx];

assign VIRTADDR_o = {PD_RD_REG_AXIS_Q[VIRTADDRMSB_idx], PD_RD_REG_AXIS_Q[VIRTADDRLSB_idx]};


endmodule: roce_stack_csr
