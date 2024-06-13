`timescale 1ns/1ps

//TODO: set actual width for certain registers (by masking at write).
//TODO: some individual bits are read only, these registers need special treatment.
//TODO: check if some debug outputs of RoCE stack can be used
module roce_stack_csr # (
  parameter int NUM_QP = 8, // Max 256
  parameter int NUM_PD = 256,
  parameter int AXIL_ADDR_WIDTH = 32,
  parameter int AXIL_DATA_WIDTH = 32
) (
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
  output logic [31:0]                     ADCONF_o,
  output logic [63:0]                     MACADD_o,
  output logic [31:0]                     IPv4ADD_o,
  output logic [31:0]                     INTEN_o, //INTERRUPT ENABLE NOT CONNECTED

  output logic [63:0]                     ERRBUFBA_o,
  output logic [31:0]                     ERRBUFSZ_o,

  output logic [63:0]                     IPKTERRQBA_o,
  output logic [31:0]                     IPKTERRQSZ_o,

  output logic [63:0]                     DATBUFBA_o,
  output logic [31:0]                     DATBUFSZ_o,

  output logic [63:0]                     RESPERRPKTBA_o,
  output logic [63:0]                     RESPERRSZ_o,


  //Protection Domain registers
  output logic [23:0]                     PDPDNUM_o,
  output logic [63:0]                     VIRTADDR_o,
  output logic [63:0]                     BUFBASEADDR_o,
  output logic [7:0]                      BUFRKEY_o,
  output logic [47:0]                     WRRDBUFLEN_o,
  output logic [15:0]                     ACCESSDESC_o,

  //Per QP registers
  output logic [7:0]                      QPidx_o,
  output logic [31:0]                     QPCONFi_o,
  output logic [31:0]                     QPADVCONFi_o,
  output logic [63:0]                     RQBAi_o,
  output logic [63:0]                     SQBAi_o,
  output logic [63:0]                     CQBAi_o,
  output logic [63:0]                     RQWPTRDBADDi_o,
  output logic [63:0]                     CQDBADDi_o,
  output logic [31:0]                     SQPIi_o,
  input  logic [31:0]                     CQHEADi_i,
  output logic [31:0]                     CQHEADi_o,
  output logic [31:0]                     QDEPTHi_o,
  output logic [23:0]                     SQPSNi_o,
  output logic [31:0]                     LSTRQREQi_o, // contains rq psn[23:0]
  output logic [23:0]                     DESTQPCONFi_o,
  output logic [63:0]                     MACDESADDi_o,             
  output logic [31:0]                     IPDESADDR1i_o, //for IPv4 only


  input  logic                            rd_req_addr_valid_i,
  output logic                            rd_req_addr_ready_o,
  input  logic   [63:0]                   rd_req_addr_vaddr_i,
  output logic                            rd_resp_addr_valid_o,
  input  logic                            rd_resp_addr_ready_i,
  output logic  [115 : 0]                 rd_resp_addr_data_o,

  input  logic                            wr_req_addr_valid_i,
  output logic                            wr_req_addr_ready_o,
  input  logic   [63:0]                   wr_req_addr_vaddr_i,
  output logic                            wr_resp_addr_valid_o,
  input  logic                            wr_resp_addr_ready_i,
  output logic  [115 : 0]                 wr_resp_addr_data_o,

  //input  logic  [7:0]                     wr_ptr_i,


  input logic                             axis_aclk_i,
  input logic                             axil_aclk_i,
  input logic                             rstn_i
);

//assert (NUM_QP >= 8 && NUM_QP <=256) else begin $error("NUM_QP must be between 8 and 256") end;

localparam int AXIL_DATA_WIDTH_BYTES = AXIL_DATA_WIDTH/8;
localparam int REG_WIDTH = 32;

localparam int CSR_ADDRESS_SPACE = 262144; //256kb
localparam int CSR_ADDRESS_WIDTH = $clog2(CSR_ADDRESS_SPACE);




/////////////////
//             //
//  ADDRESSES  //
//             //
/////////////////

// Protection domain regs: 0x0 - 0x10000, only compare lower bits
localparam logic [7:0] ADDR_PDPDNUM         = 'h0;
localparam logic [7:0] ADDR_VIRTADDRLSB     = 'h4;
localparam logic [7:0] ADDR_VIRTADDRMSB     = 'h8;
localparam logic [7:0] ADDR_BUFBASEADDRLSB  = 'hC;
localparam logic [7:0] ADDR_BUFBASEADDRMSB  = 'h10;
localparam logic [7:0] ADDR_BUFRKEY         = 'h14;
localparam logic [7:0] ADDR_WRRDBUFLEN      = 'h18;
localparam logic [7:0] ADDR_ACCESSDESC      = 'h1C;

// Configuration and status regs 0x20000 - 0x201F0
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CONF                    = 'h20000;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_ADCONF                  = 'h20004;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_BUF_THRESHOLD_ROCE      = 'h20008;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_PAUSE_CONF              = 'h2000C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_MACADDLSB               = 'h20010;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_MACADDMSB               = 'h20014;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_BUF_THRESHOLD_NON_ROCE  = 'h20018;

localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPv6ADD1                = 'h20020; 
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPv6ADD2                = 'h20024; 
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPv6ADD3                = 'h20028; 
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPv6ADD4                = 'h2002C;  

localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_ERRBUFBA                = 'h20060;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_ERRBUFBAMSB             = 'h20064;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_ERRBUFSZ                = 'h20068;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_ERRBUFWPTR              = 'h2006C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPv4ADD                 = 'h20070;

localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OPKTERRQBA              = 'h20078;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OPKTERRQBAMSB           = 'h2007C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OUTERRSTSQSZ            = 'h20080;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OPTERRSTSQQPTRDB        = 'h20084;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPKTERRQBA              = 'h20088;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPKTERRQBAMSB           = 'h2008C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPKTERRQSZ              = 'h20090;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_IPKTERRQWPTR            = 'h20094;

localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_DATBUFBA                = 'h200A0;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_DATBUFBAMSB             = 'h200A4;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_DATBUFSZ                = 'h200A8;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CON_IO_CONF             = 'h200AC;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RESPERRPKTBA            = 'h200B0;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RESPERRPKTBAMSB         = 'h200B4;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RESPERRSZ               = 'h200B8;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RESPERRSZMSB            = 'h200BC;

//Global status regs
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INSRRPKTCNT             = 'h20100;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INAMPKTCNT              = 'h20104;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OUTIOPKTCNT             = 'h20108;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OUTAMPKTCNT             = 'h2010C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_LSTINPKT                = 'h20110;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_LSTOUTPKT               = 'h20114;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_ININVDUPCNT             = 'h20118;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INNCKPKTSTS             = 'h2011C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OUTRNRPKTSTS            = 'h20120;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_WQEPROCSTS              = 'h20124;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_QPMSTS                  = 'h2012C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INALLDRPPKTCNT          = 'h20130;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INNAKPKTCNT             = 'h20134;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OUTNAKPKTCNT            = 'h20138;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RESPHNDSTS              = 'h2013C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RETRYCNTSTS             = 'h20140;

localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INCNPPKTCNT             = 'h20174;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OUTCNPPKTCNT            = 'h20178;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_OUTRDRSPPKTCNT          = 'h2017C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INTEN                   = 'h20180;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_INTSTS                  = 'h20184;

localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS1               = 'h20190;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS2               = 'h20194;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS3               = 'h20198;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS4               = 'h2019C;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS5               = 'h201A0;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS6               = 'h201A4;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS7               = 'h201A8;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_RQINTSTS8               = 'h201AC;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS1               = 'h201B0;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS2               = 'h201B4;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS3               = 'h201B8;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS4               = 'h201BC;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS5               = 'h201C0;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS6               = 'h201C4;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS7               = 'h201C8;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CQINTSTS8               = 'h201CC;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS1REG          = 'h201D0;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS2REG          = 'h201D4;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS3REG          = 'h201D8;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS4REG          = 'h201DC;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS5REG          = 'h201E0;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS6REG          = 'h201E4;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS7REG          = 'h201E8;
localparam logic [CSR_ADDRESS_WIDTH-1:0] ADDR_CNPSCHDSTS8REG          = 'h201EC;

//Per QP registers (NUMQP min is 8, max is 256) (these actually start at 0x20200), only compare 8 lower bits, idx is upper 10 bits - 0x202
localparam logic [7:0] ADDR_QPCONFi         = 'h0;
localparam logic [7:0] ADDR_QPADVCONFi      = 'h4;
localparam logic [7:0] ADDR_RQBAi           = 'h8;
localparam logic [7:0] ADDR_RQBAMSBi        = 'hC0;
localparam logic [7:0] ADDR_SQBAi           = 'h10;
localparam logic [7:0] ADDR_SQBAMSBi        = 'hC8;
localparam logic [7:0] ADDR_CQBAi           = 'h18;
localparam logic [7:0] ADDR_CQBAMSBi        = 'hD0;
localparam logic [7:0] ADDR_RQWPTRDBADDi    = 'h20;
localparam logic [7:0] ADDR_RQWPTRDBADDMSBi = 'h24;
localparam logic [7:0] ADDR_CQDBADDi        = 'h28;
localparam logic [7:0] ADDR_CQDBADDMSBi     = 'h2C;
localparam logic [7:0] ADDR_CQHEADi         = 'h30;
localparam logic [7:0] ADDR_RQCIi           = 'h34;
localparam logic [7:0] ADDR_SQPIi           = 'h38;
localparam logic [7:0] ADDR_QDEPTHi         = 'h3C;
localparam logic [7:0] ADDR_SQPSNi          = 'h40;
localparam logic [7:0] ADDR_LSTRQREQi       = 'h44;
localparam logic [7:0] ADDR_DESTQPCONFi     = 'h48;
localparam logic [7:0] ADDR_MACDESADDLSBi   = 'h50;
localparam logic [7:0] ADDR_MACDESADDMSBi   = 'h54;
localparam logic [7:0] ADDR_IPDESADDR1i     = 'h60;
localparam logic [7:0] ADDR_IPDESADDR2i     = 'h64;
localparam logic [7:0] ADDR_IPDESADDR3i     = 'h68;
localparam logic [7:0] ADDR_IPDESADDR4i     = 'h6C;
localparam logic [7:0] ADDR_TIMEOUTCONFi    = 'h4C;
localparam logic [7:0] ADDR_STATSSNi        = 'h80;
localparam logic [7:0] ADDR_STATMSNi        = 'h84;
localparam logic [7:0] ADDR_STATQPi         = 'h88;
localparam logic [7:0] ADDR_STATCURSQPTRi   = 'h8C;
localparam logic [7:0] ADDR_STATRESPSNi     = 'h90;
localparam logic [7:0] ADDR_STATRQBUFCAi    = 'h94;
localparam logic [7:0] ADDR_STATRQBUFCAMSBi = 'hD8;
localparam logic [7:0] ADDR_STATWQEi        = 'h98;
localparam logic [7:0] ADDR_STATRQPIDBi     = 'h9C;
localparam logic [7:0] ADDR_PDNUMi          = 'hB0;

////////////////////////////
//                        //
//  REGISTER DEFINITIONS  //
//                        //
////////////////////////////

// Protection domain regs: 0x0 - 0x10000
logic [REG_WIDTH-1:0] PDPDNUM_d[NUM_PD-1:0], PDPDNUM_q[NUM_PD-1:0];
logic [REG_WIDTH-1:0] VIRTADDRLSB_d[NUM_PD-1:0], VIRTADDRLSB_q[NUM_PD-1:0];
logic [REG_WIDTH-1:0] VIRTADDRMSB_d[NUM_PD-1:0], VIRTADDRMSB_q[NUM_PD-1:0];
logic [REG_WIDTH-1:0] BUFBASEADDRLSB_d[NUM_PD-1:0], BUFBASEADDRLSB_q[NUM_PD-1:0];
logic [REG_WIDTH-1:0] BUFBASEADDRMSB_d[NUM_PD-1:0], BUFBASEADDRMSB_q[NUM_PD-1:0];
logic [REG_WIDTH-1:0] BUFRKEY_d[NUM_PD-1:0], BUFRKEY_q[NUM_PD-1:0];
logic [REG_WIDTH-1:0] WRRDBUFLEN_d[NUM_PD-1:0], WRRDBUFLEN_q[NUM_PD-1:0];
logic [REG_WIDTH-1:0] ACCESSDESC_d[NUM_PD-1:0], ACCESSDESC_q[NUM_PD-1:0];

// Configuration and status regs 0x20000 - 0x201F0
logic [REG_WIDTH-1:0] CONF_d, CONF_q;
logic [REG_WIDTH-1:0] ADCONF_d, ADCONF_q;
logic [REG_WIDTH-1:0] BUF_THRESHOLD_ROCE_d, BUF_THRESHOLD_ROCE_q;
logic [REG_WIDTH-1:0] PAUSE_CONF_d, PAUSE_CONF_q;
logic [REG_WIDTH-1:0] MACADDLSB_d, MACADDLSB_q;
logic [REG_WIDTH-1:0] MACADDMSB_d, MACADDMSB_q;
logic [REG_WIDTH-1:0] BUF_THRESHOLD_NON_ROCE_d, BUF_THRESHOLD_NON_ROCE_q;

logic [REG_WIDTH-1:0] IPv6ADD1_d, IPv6ADD1_q;
logic [REG_WIDTH-1:0] IPv6ADD2_d, IPv6ADD2_q;
logic [REG_WIDTH-1:0] IPv6ADD3_d, IPv6ADD3_q;
logic [REG_WIDTH-1:0] IPv6ADD4_d, IPv6ADD4_q;

logic [REG_WIDTH-1:0] ERRBUFBA_d, ERRBUFBA_q;
logic [REG_WIDTH-1:0] ERRBUFBAMSB_d, ERRBUFBAMSB_q;
logic [REG_WIDTH-1:0] ERRBUFSZ_d, ERRBUFSZ_q;
logic [REG_WIDTH-1:0] ERRBUFWPTR_d, ERRBUFWPTR_q; 
logic [REG_WIDTH-1:0] IPv4ADD_d, IPv4ADD_q;

logic [REG_WIDTH-1:0] OPKTERRQBA_d, OPKTERRQBA_q;
logic [REG_WIDTH-1:0] OPKTERRQBAMSB_d, OPKTERRQBAMSB_q;
logic [REG_WIDTH-1:0] OUTERRSTSQSZ_d, OUTERRSTSQSZ_q;
logic [REG_WIDTH-1:0] OPTERRSTSQQPTRDB_d, OPTERRSTSQQPTRDB_q;
logic [REG_WIDTH-1:0] IPKTERRQBA_d, IPKTERRQBA_q;
logic [REG_WIDTH-1:0] IPKTERRQBAMSB_d, IPKTERRQBAMSB_q;
logic [REG_WIDTH-1:0] IPKTERRQSZ_d, IPKTERRQSZ_q;
logic [REG_WIDTH-1:0] IPKTERRQWPTR_d, IPKTERRQWPTR_q;

logic [REG_WIDTH-1:0] DATBUFBA_d, DATBUFBA_q;
logic [REG_WIDTH-1:0] DATBUFBAMSB_d, DATBUFBAMSB_q;
logic [REG_WIDTH-1:0] DATBUFSZ_d, DATBUFSZ_q;
logic [REG_WIDTH-1:0] CON_IO_CONF_d, CON_IO_CONF_q;
logic [REG_WIDTH-1:0] RESPERRPKTBA_d, RESPERRPKTBA_q;
logic [REG_WIDTH-1:0] RESPERRPKTBAMSB_d, RESPERRPKTBAMSB_q;
logic [REG_WIDTH-1:0] RESPERRSZ_d, RESPERRSZ_q;
logic [REG_WIDTH-1:0] RESPERRSZMSB_d, RESPERRSZMSB_q;

//Global status regs
logic [REG_WIDTH-1:0] INSRRPKTCNT_d, INSRRPKTCNT_q;
logic [REG_WIDTH-1:0] INAMPKTCNT_d, INAMPKTCNT_q;
logic [REG_WIDTH-1:0] OUTIOPKTCNT_d, OUTIOPKTCNT_q;
logic [REG_WIDTH-1:0] OUTAMPKTCNT_d, OUTAMPKTCNT_q;
logic [REG_WIDTH-1:0] LSTINPKT_d, LSTINPKT_q;
logic [REG_WIDTH-1:0] LSTOUTPKT_d, LSTOUTPKT_q;
logic [REG_WIDTH-1:0] ININVDUPCNT_d, ININVDUPCNT_q;
logic [REG_WIDTH-1:0] INNCKPKTSTS_d, INNCKPKTSTS_q;
logic [REG_WIDTH-1:0] OUTRNRPKTSTS_d, OUTRNRPKTSTS_q;
logic [REG_WIDTH-1:0] WQEPROCSTS_d, WQEPROCSTS_q;
logic [REG_WIDTH-1:0] QPMSTS_d, QPMSTS_q;
logic [REG_WIDTH-1:0] INALLDRPPKTCNT_d, INALLDRPPKTCNT_q;
logic [REG_WIDTH-1:0] INNAKPKTCNT_d, INNAKPKTCNT_q;
logic [REG_WIDTH-1:0] OUTNAKPKTCNT_d, OUTNAKPKTCNT_q;
logic [REG_WIDTH-1:0] RESPHNDSTS_d, RESPHNDSTS_q;
logic [REG_WIDTH-1:0] RETRYCNTSTS_d, RETRYCNTSTS_q;

logic [REG_WIDTH-1:0] INCNPPKTCNT_d, INCNPPKTCNT_q;
logic [REG_WIDTH-1:0] OUTCNPPKTCNT_d, OUTCNPPKTCNT_q;
logic [REG_WIDTH-1:0] OUTRDRSPPKTCNT_d, OUTRDRSPPKTCNT_q;
logic [REG_WIDTH-1:0] INTEN_d, INTEN_q;
logic [REG_WIDTH-1:0] INTSTS_d, INTSTS_q;

logic [REG_WIDTH-1:0] RQINTSTS1_d, RQINTSTS1_q; 
logic [REG_WIDTH-1:0] RQINTSTS2_d, RQINTSTS2_q;
logic [REG_WIDTH-1:0] RQINTSTS3_d, RQINTSTS3_q;
logic [REG_WIDTH-1:0] RQINTSTS4_d, RQINTSTS4_q;
logic [REG_WIDTH-1:0] RQINTSTS5_d, RQINTSTS5_q;
logic [REG_WIDTH-1:0] RQINTSTS6_d, RQINTSTS6_q;
logic [REG_WIDTH-1:0] RQINTSTS7_d, RQINTSTS7_q;
logic [REG_WIDTH-1:0] RQINTSTS8_d, RQINTSTS8_q;
logic [REG_WIDTH-1:0] CQINTSTS1_d, CQINTSTS1_q;
logic [REG_WIDTH-1:0] CQINTSTS2_d, CQINTSTS2_q;
logic [REG_WIDTH-1:0] CQINTSTS3_d, CQINTSTS3_q;
logic [REG_WIDTH-1:0] CQINTSTS4_d, CQINTSTS4_q;
logic [REG_WIDTH-1:0] CQINTSTS5_d, CQINTSTS5_q;
logic [REG_WIDTH-1:0] CQINTSTS6_d, CQINTSTS6_q;
logic [REG_WIDTH-1:0] CQINTSTS7_d, CQINTSTS7_q;
logic [REG_WIDTH-1:0] CQINTSTS8_d, CQINTSTS8_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS1REG_d, CNPSCHDSTS1REG_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS2REG_d, CNPSCHDSTS2REG_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS3REG_d, CNPSCHDSTS3REG_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS4REG_d, CNPSCHDSTS4REG_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS5REG_d, CNPSCHDSTS5REG_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS6REG_d, CNPSCHDSTS6REG_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS7REG_d, CNPSCHDSTS7REG_q;
logic [REG_WIDTH-1:0] CNPSCHDSTS8REG_d, CNPSCHDSTS8REG_q;

//Per QP registers (NUMQP min is 8, max is 256)
logic [REG_WIDTH-1:0] QPCONFi_d[NUM_QP-1:0], QPCONFi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] QPADVCONFi_d[NUM_QP-1:0], QPADVCONFi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] RQBAi_d[NUM_QP-1:0], RQBAi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] RQBAMSBi_d[NUM_QP-1:0], RQBAMSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] SQBAi_d[NUM_QP-1:0], SQBAi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] SQBAMSBi_d[NUM_QP-1:0],SQBAMSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] CQBAi_d[NUM_QP-1:0], CQBAi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] CQBAMSBi_d[NUM_QP-1:0], CQBAMSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] RQWPTRDBADDi_d[NUM_QP-1:0], RQWPTRDBADDi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] RQWPTRDBADDMSBi_d[NUM_QP-1:0], RQWPTRDBADDMSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] CQDBADDi_d[NUM_QP-1:0], CQDBADDi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] CQDBADDMSBi_d[NUM_QP-1:0], CQDBADDMSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] CQHEADi_d[NUM_QP-1:0], CQHEADi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] RQCIi_d[NUM_QP-1:0],  RQCIi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] SQPIi_d[NUM_QP-1:0], SQPIi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] QDEPTHi_d[NUM_QP-1:0], QDEPTHi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] SQPSNi_d[NUM_QP-1:0], SQPSNi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] LSTRQREQi_d[NUM_QP-1:0], LSTRQREQi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] DESTQPCONFi_d[NUM_QP-1:0], DESTQPCONFi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] MACDESADDLSBi_d[NUM_QP-1:0], MACDESADDLSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] MACDESADDMSBi_d[NUM_QP-1:0], MACDESADDMSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] IPDESADDR1i_d[NUM_QP-1:0], IPDESADDR1i_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] IPDESADDR2i_d[NUM_QP-1:0], IPDESADDR2i_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] IPDESADDR3i_d[NUM_QP-1:0], IPDESADDR3i_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] IPDESADDR4i_d[NUM_QP-1:0], IPDESADDR4i_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] TIMEOUTCONFi_d[NUM_QP-1:0], TIMEOUTCONFi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATSSNi_d[NUM_QP-1:0], STATSSNi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATMSNi_d[NUM_QP-1:0], STATMSNi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATQPi_d[NUM_QP-1:0], STATQPi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATCURSQPTRi_d[NUM_QP-1:0], STATCURSQPTRi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATRESPSNi_d[NUM_QP-1:0], STATRESPSNi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATRQBUFCAi_d[NUM_QP-1:0], STATRQBUFCAi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATRQBUFCAMSBi_d[NUM_QP-1:0], STATRQBUFCAMSBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATWQEi_d[NUM_QP-1:0], STATWQEi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] STATRQPIDBi_d[NUM_QP-1:0], STATRQPIDBi_q[NUM_QP-1:0];
logic [REG_WIDTH-1:0] PDNUMi_d[NUM_QP-1:0], PDNUMi_q[NUM_QP-1:0];

logic [7:0] QPidx_d, QPidx_q;
logic [7:0] PDidx_d, PDidx_q;

///////////////////////
//                   //
//  CONTROL SIGNALS  //
//                   //
///////////////////////


//AXI Lite clock domain
logic reading, writing;

logic[7:0] pdidx_r, pdidx_w;
logic[9:0] qpidx_r, qpidx_w;
logic[AXIL_DATA_WIDTH_BYTES-1:0] mask;

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

  case(r_state_q)
    R_IDLE: begin
      if(s_axil_arvalid_i && !writing) begin
        RAddrReg_d = s_axil_araddr_i;
        s_axil_arready_o = 1'b1;
        r_state_d = R_GETDATA;
      end
    end

    R_GETDATA: begin 
      RRespReg_d = 2'b0; //OKAY
      reading = 1'b1;
      //protection domain range
      if(!RAddrReg_q[17]) begin
        pdidx_r = RAddrReg_q[15-:8];
        case(RAddrReg_q[7:0])
          ADDR_PDPDNUM: begin
            RDataReg_d = PDPDNUM_q[pdidx_r];
          end
          ADDR_VIRTADDRLSB: begin
            RDataReg_d = VIRTADDRLSB_q[pdidx_r];
          end
          ADDR_VIRTADDRMSB: begin
            RDataReg_d = VIRTADDRMSB_q[pdidx_r];
          end
          ADDR_BUFBASEADDRLSB: begin
            RDataReg_d = BUFBASEADDRLSB_q[pdidx_r];
          end
          ADDR_BUFBASEADDRMSB: begin
            RDataReg_d = BUFBASEADDRMSB_q[pdidx_r];
          end
          ADDR_BUFRKEY: begin
            RDataReg_d = BUFRKEY_q[pdidx_r];
          end
          ADDR_WRRDBUFLEN: begin
            RDataReg_d = WRRDBUFLEN_q[pdidx_r];
          end
          ADDR_ACCESSDESC: begin
            RDataReg_d = ACCESSDESC_q[pdidx_r];
          end
          default: begin
            RDataReg_d = 'd0;
            RRespReg_d = 2'b10; //SLVERR
          end
        endcase
      end
      
      //Per QP range
      else if(RAddrReg_q[17-:10] >= 'h202) begin
        qpidx_r = RAddrReg_q[17-:10] - 'h202;
        if(qpidx_r >= NUM_QP) begin
          RDataReg_d = 'd0;
          RRespReg_d = 2'b10; //SLVERR
        end else begin
          case(RAddrReg_q[7:0])
            ADDR_QPCONFi: begin
              RDataReg_d = QPCONFi_q[qpidx_r];
            end
            ADDR_QPADVCONFi: begin
              RDataReg_d = QPADVCONFi_q[qpidx_r];
            end
            ADDR_RQBAi: begin
              RDataReg_d = RQBAi_q[qpidx_r];
            end
            ADDR_RQBAMSBi: begin
              RDataReg_d = RQBAMSBi_q[qpidx_r];
            end
            ADDR_SQBAi: begin
              RDataReg_d = SQBAi_q[qpidx_r];
            end
            ADDR_SQBAMSBi: begin
              RDataReg_d = SQBAMSBi_q[qpidx_r];
            end
            ADDR_CQBAi: begin
              RDataReg_d = CQBAi_q[qpidx_r];
            end
            ADDR_CQBAMSBi: begin
              RDataReg_d = CQBAMSBi_q[qpidx_r];
            end
            ADDR_RQWPTRDBADDi: begin
              RDataReg_d = RQWPTRDBADDi_q[qpidx_r];
            end
            ADDR_RQWPTRDBADDMSBi: begin
              RDataReg_d = RQWPTRDBADDMSBi_q[qpidx_r];
            end
            ADDR_CQDBADDi: begin
              RDataReg_d = CQDBADDi_q[qpidx_r];
            end
            ADDR_CQDBADDMSBi: begin
              RDataReg_d = CQDBADDMSBi_q[qpidx_r];
            end
            ADDR_CQHEADi: begin
              RDataReg_d = CQHEADi_q[qpidx_r];
            end
            ADDR_RQCIi: begin
              RDataReg_d = RQCIi_q[qpidx_r];
            end
            ADDR_SQPIi: begin
              RDataReg_d = SQPIi_q[qpidx_r];
            end
            ADDR_QDEPTHi: begin
              RDataReg_d = QDEPTHi_q[qpidx_r];
            end
            ADDR_SQPSNi: begin
              RDataReg_d = SQPSNi_q[qpidx_r];
            end
            ADDR_LSTRQREQi: begin
              RDataReg_d = LSTRQREQi_q[qpidx_r];
            end
            ADDR_DESTQPCONFi: begin
              RDataReg_d = DESTQPCONFi_q[qpidx_r];
            end
            ADDR_MACDESADDLSBi: begin
              RDataReg_d = MACDESADDLSBi_q[qpidx_r];
            end
            ADDR_MACDESADDMSBi: begin
              RDataReg_d = MACDESADDMSBi_q[qpidx_r];
            end
            ADDR_IPDESADDR1i: begin
              RDataReg_d = IPDESADDR1i_q[qpidx_r];
            end
            ADDR_IPDESADDR2i: begin
              RDataReg_d = IPDESADDR2i_q[qpidx_r];
            end
            ADDR_IPDESADDR3i: begin
              RDataReg_d = IPDESADDR3i_q[qpidx_r];
            end
            ADDR_IPDESADDR4i: begin
              RDataReg_d = IPDESADDR4i_q[qpidx_r];
            end
            ADDR_TIMEOUTCONFi: begin
              RDataReg_d = TIMEOUTCONFi_q[qpidx_r];
            end
            ADDR_STATSSNi: begin
              RDataReg_d = STATSSNi_q[qpidx_r];
            end
            ADDR_STATMSNi: begin
              RDataReg_d =STATMSNi_q[qpidx_r];
            end
            ADDR_STATQPi: begin
              RDataReg_d = STATQPi_q[qpidx_r];
            end
            ADDR_STATCURSQPTRi: begin
              RDataReg_d = STATCURSQPTRi_q[qpidx_r];
            end
            ADDR_STATRESPSNi: begin
              RDataReg_d =STATRESPSNi_q[qpidx_r];
            end
            ADDR_STATRQBUFCAi: begin
              RDataReg_d = STATRQBUFCAi_q[qpidx_r];
            end
            ADDR_STATRQBUFCAMSBi: begin
              RDataReg_d = STATRQBUFCAMSBi_q[qpidx_r];
            end
            ADDR_STATWQEi: begin
              RDataReg_d = STATWQEi_q[qpidx_r];
            end
            ADDR_STATRQPIDBi: begin
              RDataReg_d = STATRQPIDBi_q[qpidx_r];
            end
            ADDR_PDNUMi: begin
              RDataReg_d = PDNUMi_q[qpidx_r];
            end
            default: begin
              RDataReg_d = 'd0;
              RRespReg_d = 2'b10; //SLVERR
            end
          endcase
        end
      end else begin
        case(RAddrReg_q)
          // Configuration and status regs 0x20000 - 0x201F0
          ADDR_CONF: begin
            RDataReg_d = CONF_q; 
          end
          ADDR_ADCONF: begin
            RDataReg_d = ADCONF_q; 
          end
          ADDR_BUF_THRESHOLD_ROCE: begin
            RDataReg_d = BUF_THRESHOLD_ROCE_q; 
          end
          ADDR_PAUSE_CONF: begin
            RDataReg_d = PAUSE_CONF_q; 
          end
          ADDR_MACADDLSB: begin
            RDataReg_d = MACADDLSB_q; 
          end
          ADDR_MACADDMSB: begin
            RDataReg_d = MACADDMSB_q; 
          end
          ADDR_BUF_THRESHOLD_NON_ROCE: begin
            RDataReg_d = BUF_THRESHOLD_NON_ROCE_q; 
          end
          ADDR_IPv6ADD1: begin
            RDataReg_d = IPv6ADD1_q; 
          end 
          ADDR_IPv6ADD2: begin
            RDataReg_d = IPv6ADD2_q; 
          end 
          ADDR_IPv6ADD3: begin
            RDataReg_d = IPv6ADD3_q; 
          end 
          ADDR_IPv6ADD4: begin
            RDataReg_d = IPv6ADD4_q; 
          end  
          ADDR_ERRBUFBA: begin
            RDataReg_d = ERRBUFBA_q; 
          end
          ADDR_ERRBUFBAMSB: begin
            RDataReg_d = ERRBUFBAMSB_q; 
          end
          ADDR_ERRBUFSZ: begin
            RDataReg_d = ERRBUFSZ_q; 
          end
          ADDR_ERRBUFWPTR: begin
            RDataReg_d = ERRBUFWPTR_q; 
          end
          ADDR_IPv4ADD: begin
            RDataReg_d = IPv4ADD_q; 
          end
          ADDR_OPKTERRQBA: begin
            RDataReg_d = OPKTERRQBA_q; 
          end
          ADDR_OPKTERRQBAMSB: begin
            RDataReg_d = OPKTERRQBAMSB_q; 
          end
          ADDR_OUTERRSTSQSZ: begin
            RDataReg_d = OUTERRSTSQSZ_q; 
          end
          ADDR_OPTERRSTSQQPTRDB: begin
            RDataReg_d = OPTERRSTSQQPTRDB_q; 
          end
          ADDR_IPKTERRQBA: begin
            RDataReg_d = IPKTERRQBA_q; 
          end
          ADDR_IPKTERRQBAMSB: begin
            RDataReg_d = IPKTERRQBAMSB_q; 
          end
          ADDR_IPKTERRQSZ: begin
            RDataReg_d = IPKTERRQSZ_q; 
          end
          ADDR_IPKTERRQWPTR: begin
            RDataReg_d = IPKTERRQWPTR_q; 
          end
          ADDR_DATBUFBA: begin
            RDataReg_d = DATBUFBA_q; 
          end
          ADDR_DATBUFBAMSB: begin
            RDataReg_d = DATBUFBAMSB_q; 
          end
          ADDR_DATBUFSZ: begin
            RDataReg_d = DATBUFSZ_q; 
          end
          ADDR_CON_IO_CONF: begin
            RDataReg_d = CON_IO_CONF_q; 
          end
          ADDR_RESPERRPKTBA: begin
            RDataReg_d = RESPERRPKTBA_q; 
          end
          ADDR_RESPERRPKTBAMSB: begin
            RDataReg_d = RESPERRPKTBAMSB_q; 
          end
          ADDR_RESPERRSZ: begin
            RDataReg_d = RESPERRSZ_q; 
          end
          ADDR_RESPERRSZMSB: begin
            RDataReg_d = RESPERRSZMSB_q; 
          end
          //Global status regs
          ADDR_INSRRPKTCNT: begin
            RDataReg_d = INSRRPKTCNT_q;
          end
          ADDR_INAMPKTCNT: begin
            RDataReg_d = INAMPKTCNT_q;
          end
          ADDR_OUTIOPKTCNT: begin
            RDataReg_d = OUTIOPKTCNT_q;
          end
          ADDR_OUTAMPKTCNT: begin
            RDataReg_d = OUTAMPKTCNT_q;
          end
          ADDR_LSTINPKT: begin
            RDataReg_d = LSTINPKT_q;
          end
          ADDR_LSTOUTPKT: begin
            RDataReg_d = LSTOUTPKT_q;
          end
          ADDR_ININVDUPCNT: begin
            RDataReg_d = ININVDUPCNT_q;
          end
          ADDR_INNCKPKTSTS: begin
            RDataReg_d = INNCKPKTSTS_q;
          end
          ADDR_OUTRNRPKTSTS: begin
            RDataReg_d = OUTRNRPKTSTS_q;
          end
          ADDR_WQEPROCSTS: begin
            RDataReg_d = WQEPROCSTS_q;
          end
          ADDR_QPMSTS: begin
            RDataReg_d = QPMSTS_q;
          end
          ADDR_INALLDRPPKTCNT: begin
            RDataReg_d = INALLDRPPKTCNT_q;
          end
          ADDR_INNAKPKTCNT: begin
            RDataReg_d = INNAKPKTCNT_q;
          end
          ADDR_OUTNAKPKTCNT: begin
            RDataReg_d = OUTNAKPKTCNT_q;
          end
          ADDR_RESPHNDSTS: begin
            RDataReg_d = RESPHNDSTS_q;
          end
          ADDR_RETRYCNTSTS: begin
            RDataReg_d = RETRYCNTSTS_q;
          end
          ADDR_INCNPPKTCNT: begin
            RDataReg_d = INCNPPKTCNT_q;
          end
          ADDR_OUTCNPPKTCNT: begin
            RDataReg_d = OUTCNPPKTCNT_q;
          end
          ADDR_OUTRDRSPPKTCNT: begin
            RDataReg_d = OUTRDRSPPKTCNT_q;
          end
          ADDR_INTEN: begin
            RDataReg_d = INTEN_q;
          end
          ADDR_INTSTS: begin
            RDataReg_d = INTSTS_q;
          end
          ADDR_RQINTSTS1: begin
            RDataReg_d = RQINTSTS1_q;
          end
          ADDR_RQINTSTS2: begin
            RDataReg_d = RQINTSTS2_q;
          end
          ADDR_RQINTSTS3: begin
            RDataReg_d = RQINTSTS3_q;
          end
          ADDR_RQINTSTS4: begin
            RDataReg_d = RQINTSTS4_q;
          end
          ADDR_RQINTSTS5: begin
            RDataReg_d = RQINTSTS5_q;
          end
          ADDR_RQINTSTS6: begin
            RDataReg_d = RQINTSTS6_q;
          end
          ADDR_RQINTSTS7: begin
            RDataReg_d = RQINTSTS7_q;
          end
          ADDR_RQINTSTS8: begin
            RDataReg_d = RQINTSTS8_q;
          end
          ADDR_CQINTSTS1: begin
            RDataReg_d = CQINTSTS1_q;
          end
          ADDR_CQINTSTS2: begin
            RDataReg_d = CQINTSTS2_q;
          end
          ADDR_CQINTSTS3: begin
            RDataReg_d = CQINTSTS3_q;
          end
          ADDR_CQINTSTS4: begin
            RDataReg_d = CQINTSTS4_q;
          end
          ADDR_CQINTSTS5: begin
            RDataReg_d = CQINTSTS5_q;
          end
          ADDR_CQINTSTS6: begin
            RDataReg_d = CQINTSTS6_q;
          end
          ADDR_CQINTSTS7: begin
            RDataReg_d = CQINTSTS7_q;
          end
          ADDR_CQINTSTS8: begin
            RDataReg_d = CQINTSTS8_q;
          end
          ADDR_CNPSCHDSTS1REG: begin
            RDataReg_d = CNPSCHDSTS1REG_q;
          end
          ADDR_CNPSCHDSTS2REG: begin
            RDataReg_d = CNPSCHDSTS2REG_q;
          end
          ADDR_CNPSCHDSTS3REG: begin
            RDataReg_d = CNPSCHDSTS3REG_q;
          end
          ADDR_CNPSCHDSTS4REG: begin
            RDataReg_d = CNPSCHDSTS4REG_q;
          end
          ADDR_CNPSCHDSTS5REG: begin
            RDataReg_d = CNPSCHDSTS5REG_q;
          end
          ADDR_CNPSCHDSTS6REG: begin
            RDataReg_d = CNPSCHDSTS6REG_q;
          end
          ADDR_CNPSCHDSTS7REG: begin
            RDataReg_d = CNPSCHDSTS7REG_q;
          end
          ADDR_CNPSCHDSTS8REG: begin
            RDataReg_d = CNPSCHDSTS8REG_q;
          end
          default: begin
            RDataReg_d = 'd0;
            RRespReg_d = 2'b10; //SLVERR
          end
        endcase
      end
      r_state_d = R_VALID;
    end

    R_VALID: begin
      reading = 1'b1;
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


//function to write the regs with strb mask
function [AXIL_DATA_WIDTH-1:0]	apply_wstrb;
	input logic	[AXIL_DATA_WIDTH-1:0] old_data;
	input logic	[AXIL_DATA_WIDTH-1:0] new_data;
	input logic	[AXIL_DATA_WIDTH_BYTES-1:0] wstrb;
	
	for(int i=0; i<AXIL_DATA_WIDTH_BYTES; i++) begin
		apply_wstrb[i*8 +: 8] = wstrb[i] ? new_data[i*8 +: 8] : old_data[i*8 +: 8];
	end
endfunction



always_comb begin
  s_axil_awready_o = 1'b0;
  s_axil_bvalid_o = 1'b0;
  s_axil_wready_o = 1'b0;
  writing = 1'b0;
  WAddrReg_d = WAddrReg_q;
  WDataReg_d = WDataReg_q;
  WRespReg_d = WRespReg_q;
  WStrbReg_d = WStrbReg_q;
  
  w_state_d = w_state_q;
  
  CONF_d = CONF_q;
  ADCONF_d = ADCONF_q;
  BUF_THRESHOLD_ROCE_d = BUF_THRESHOLD_ROCE_q;
  PAUSE_CONF_d = PAUSE_CONF_q;
  MACADDLSB_d = MACADDLSB_q;
  MACADDMSB_d = MACADDMSB_q;
  BUF_THRESHOLD_NON_ROCE_d = BUF_THRESHOLD_NON_ROCE_q;

  IPv6ADD1_d = IPv6ADD1_q;
  IPv6ADD2_d = IPv6ADD2_q;
  IPv6ADD3_d = IPv6ADD3_q;
  IPv6ADD4_d = IPv6ADD4_q;

  ERRBUFBA_d = ERRBUFBA_q;
  ERRBUFBAMSB_d = ERRBUFBAMSB_q;
  ERRBUFSZ_d = ERRBUFSZ_q;
  ERRBUFWPTR_d = ERRBUFWPTR_q; 
  IPv4ADD_d = IPv4ADD_q;

  OPKTERRQBA_d = OPKTERRQBA_q;
  OPKTERRQBAMSB_d = OPKTERRQBAMSB_q;
  OUTERRSTSQSZ_d = OUTERRSTSQSZ_q;
  OPTERRSTSQQPTRDB_d = OPTERRSTSQQPTRDB_q;
  IPKTERRQBA_d = IPKTERRQBA_q;
  IPKTERRQBAMSB_d = IPKTERRQBAMSB_q;
  IPKTERRQSZ_d = IPKTERRQSZ_q;
  IPKTERRQWPTR_d = IPKTERRQWPTR_q;

  DATBUFBA_d = DATBUFBA_q;
  DATBUFBAMSB_d = DATBUFBAMSB_q;
  DATBUFSZ_d = DATBUFSZ_q;
  CON_IO_CONF_d = CON_IO_CONF_q;
  RESPERRPKTBA_d = RESPERRPKTBA_q;
  RESPERRPKTBAMSB_d = RESPERRPKTBAMSB_q;
  RESPERRSZ_d = RESPERRSZ_q;
  RESPERRSZMSB_d = RESPERRSZMSB_q;

  //Global status regs
  INSRRPKTCNT_d = INSRRPKTCNT_q;
  INAMPKTCNT_d = INAMPKTCNT_q;
  OUTIOPKTCNT_d = OUTIOPKTCNT_q;
  OUTAMPKTCNT_d = OUTAMPKTCNT_q;
  LSTINPKT_d = LSTINPKT_q;
  LSTOUTPKT_d = LSTOUTPKT_q;
  ININVDUPCNT_d = ININVDUPCNT_q;
  INNCKPKTSTS_d = INNCKPKTSTS_q;
  OUTRNRPKTSTS_d = OUTRNRPKTSTS_q;
  WQEPROCSTS_d = WQEPROCSTS_q;
  QPMSTS_d = QPMSTS_q;
  INALLDRPPKTCNT_d = INALLDRPPKTCNT_q;
  INNAKPKTCNT_d = INNAKPKTCNT_q;
  OUTNAKPKTCNT_d = OUTNAKPKTCNT_q;
  RESPHNDSTS_d = RESPHNDSTS_q;
  RETRYCNTSTS_d = RETRYCNTSTS_q;

  INCNPPKTCNT_d = INCNPPKTCNT_q;
  OUTCNPPKTCNT_d = OUTCNPPKTCNT_q;
  OUTRDRSPPKTCNT_d = OUTRDRSPPKTCNT_q;
  INTEN_d = INTEN_q;
  INTSTS_d = INTSTS_q;

  RQINTSTS1_d = RQINTSTS1_q; 
  RQINTSTS2_d = RQINTSTS2_q;
  RQINTSTS3_d = RQINTSTS3_q;
  RQINTSTS4_d = RQINTSTS4_q;
  RQINTSTS5_d = RQINTSTS5_q;
  RQINTSTS6_d = RQINTSTS6_q;
  RQINTSTS7_d = RQINTSTS7_q;
  RQINTSTS8_d = RQINTSTS8_q;
  CQINTSTS1_d = CQINTSTS1_q;
  CQINTSTS2_d = CQINTSTS2_q;
  CQINTSTS3_d = CQINTSTS3_q;
  CQINTSTS4_d = CQINTSTS4_q;
  CQINTSTS5_d = CQINTSTS5_q;
  CQINTSTS6_d = CQINTSTS6_q;
  CQINTSTS7_d = CQINTSTS7_q;
  CQINTSTS8_d = CQINTSTS8_q;
  CNPSCHDSTS1REG_d = CNPSCHDSTS1REG_q;
  CNPSCHDSTS2REG_d = CNPSCHDSTS2REG_q;
  CNPSCHDSTS3REG_d = CNPSCHDSTS3REG_q;
  CNPSCHDSTS4REG_d = CNPSCHDSTS4REG_q;
  CNPSCHDSTS5REG_d = CNPSCHDSTS5REG_q;
  CNPSCHDSTS6REG_d = CNPSCHDSTS6REG_q;
  CNPSCHDSTS7REG_d = CNPSCHDSTS7REG_q;
  CNPSCHDSTS8REG_d = CNPSCHDSTS8REG_q;
  
  for(int i = 0; i < NUM_PD; i++) begin
    PDPDNUM_d[i] = PDPDNUM_q[i];
    VIRTADDRLSB_d[i] = VIRTADDRLSB_q[i];
    VIRTADDRMSB_d[i] = VIRTADDRMSB_q[i];
    BUFBASEADDRLSB_d[i] = BUFBASEADDRLSB_q[i];
    BUFBASEADDRMSB_d[i] = BUFBASEADDRMSB_q[i];
    BUFRKEY_d[i] = BUFRKEY_q[i];
    WRRDBUFLEN_d[i] = WRRDBUFLEN_q[i];
    ACCESSDESC_d[i] = ACCESSDESC_q[i];
  end

  for(int i = 0; i < NUM_QP; i++) begin
    QPCONFi_d[i] = QPCONFi_q[i];
    QPADVCONFi_d[i] = QPADVCONFi_q[i];
    RQBAi_d[i] = RQBAi_q[i];
    RQBAMSBi_d[i] = RQBAMSBi_q[i];
    SQBAi_d[i] = SQBAi_q[i];
    SQBAMSBi_d[i] = SQBAMSBi_q[i];
    CQBAi_d[i] = CQBAi_q[i];
    CQBAMSBi_d[i] = CQBAMSBi_q[i];
    RQWPTRDBADDi_d[i] = RQWPTRDBADDi_q[i];
    RQWPTRDBADDMSBi_d[i] = RQWPTRDBADDMSBi_q[i];
    CQDBADDi_d[i] = CQDBADDi_q[i];
    CQDBADDMSBi_d[i] = CQDBADDMSBi_q[i];
    CQHEADi_d[i] = CQHEADi_q[i];
    RQCIi_d[i] =  RQCIi_q[i];
    SQPIi_d[i] = SQPIi_q[i];
    QDEPTHi_d[i] = QDEPTHi_q[i];
    SQPSNi_d[i] = SQPSNi_q[i];
    LSTRQREQi_d[i] = LSTRQREQi_q[i];
    DESTQPCONFi_d[i] = DESTQPCONFi_q[i];
    MACDESADDLSBi_d[i] = MACDESADDLSBi_q[i];
    MACDESADDMSBi_d[i] = MACDESADDMSBi_q[i];
    IPDESADDR1i_d[i] = IPDESADDR1i_q[i];
    IPDESADDR2i_d[i] = IPDESADDR2i_q[i];
    IPDESADDR3i_d[i] = IPDESADDR3i_q[i];
    IPDESADDR4i_d[i] = IPDESADDR4i_q[i];
    TIMEOUTCONFi_d[i] = TIMEOUTCONFi_q[i];
    STATSSNi_d[i] = STATSSNi_q[i];
    STATMSNi_d[i] = STATMSNi_q[i];
    STATQPi_d[i] = STATQPi_q[i];
    STATCURSQPTRi_d[i] = STATCURSQPTRi_q[i];
    STATRESPSNi_d[i] = STATRESPSNi_q[i];
    STATRQBUFCAi_d[i] = STATRQBUFCAi_q[i];
    STATRQBUFCAMSBi_d[i] = STATRQBUFCAMSBi_q[i];
    STATWQEi_d[i] = STATWQEi_q[i];
    STATRQPIDBi_d[i] = STATRQPIDBi_q[i];
    PDNUMi_d[i] = PDNUMi_q[i];
  end

  QPidx_d = QPidx_q;

  case(w_state_q)
    W_IDLE: begin
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
      mask = WStrbReg_q;
      
      if(~WAddrReg_q[17]) begin
        pdidx_w = WAddrReg_q[15-:8];
        case(WAddrReg_q[7:0])
          ADDR_PDPDNUM: begin
            mask = WStrbReg_q & 4'b0111; 
            PDPDNUM_d[pdidx_w] = apply_wstrb(PDPDNUM_q[pdidx_w], WDataReg_q, mask);
            PDPDNUM_d[pdidx_w][24] = 1'b1; //valid bit for idx determination
          end
          ADDR_VIRTADDRLSB: begin
            VIRTADDRLSB_d[pdidx_w] = apply_wstrb(VIRTADDRLSB_q[pdidx_w], WDataReg_q, mask);
          end
          ADDR_VIRTADDRMSB: begin
            VIRTADDRMSB_d[pdidx_w] = apply_wstrb(VIRTADDRMSB_q[pdidx_w], WDataReg_q, mask);
          end
          ADDR_BUFBASEADDRLSB: begin
            BUFBASEADDRLSB_d[pdidx_w] = apply_wstrb(BUFBASEADDRLSB_q[pdidx_w], WDataReg_q, mask);
          end
          ADDR_BUFBASEADDRMSB: begin
            BUFBASEADDRMSB_d[pdidx_w] = apply_wstrb(BUFBASEADDRMSB_q[pdidx_w], WDataReg_q, mask);
          end
          ADDR_BUFRKEY: begin
            BUFRKEY_d[pdidx_w] = apply_wstrb(BUFRKEY_q[pdidx_w], WDataReg_q, mask);
          end
          ADDR_WRRDBUFLEN: begin
            WRRDBUFLEN_d[pdidx_w] = apply_wstrb(WRRDBUFLEN_q[pdidx_w], WDataReg_q, mask);
          end
          ADDR_ACCESSDESC: begin
            ACCESSDESC_d[pdidx_w] = apply_wstrb(ACCESSDESC_q[pdidx_w], WDataReg_q, mask);
          end
          default: begin
            WRespReg_d = 2'b10; //SLVERR
          end
        endcase
      end else if (WAddrReg_q[17-:10] >= 'h202) begin
        qpidx_w = WAddrReg_q[17-:10] - 'h202;
        if(qpidx_w >= NUM_QP) begin
          WRespReg_d = 2'b10; //SLVERR
        end else begin
          case(WAddrReg_q[7:0])
            ADDR_QPCONFi: begin
              QPCONFi_d[qpidx_w] = apply_wstrb(QPCONFi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_QPADVCONFi: begin
              QPADVCONFi_d[qpidx_w] = apply_wstrb(QPADVCONFi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_RQBAi: begin
              RQBAi_d[qpidx_w] = apply_wstrb(RQBAi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_RQBAMSBi: begin
              RQBAMSBi_d[qpidx_w] = apply_wstrb(RQBAMSBi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_SQBAi: begin
              SQBAi_d[qpidx_w] = apply_wstrb(SQBAi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_SQBAMSBi: begin
              SQBAMSBi_d[qpidx_w] = apply_wstrb(SQBAMSBi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_CQBAi: begin
              CQBAi_d[qpidx_w] = apply_wstrb(CQBAi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_CQBAMSBi: begin
              CQBAMSBi_d[qpidx_w] = apply_wstrb(CQBAMSBi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_RQWPTRDBADDi: begin
              RQWPTRDBADDi_d[qpidx_w] = apply_wstrb(RQWPTRDBADDi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_RQWPTRDBADDMSBi: begin
              RQWPTRDBADDMSBi_d[qpidx_w] = apply_wstrb(RQWPTRDBADDMSBi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_CQDBADDi: begin
              CQDBADDi_d[qpidx_w] = apply_wstrb(CQDBADDi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_CQDBADDMSBi: begin
              CQDBADDMSBi_d[qpidx_w] = apply_wstrb(CQDBADDMSBi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_RQCIi: begin
              RQCIi_d[qpidx_w] = apply_wstrb(RQCIi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_SQPIi: begin
              SQPIi_d[qpidx_w] = apply_wstrb(SQPIi_q[qpidx_w], WDataReg_q, mask);
              QPidx_d = qpidx_w[7:0];
            end
            ADDR_QDEPTHi: begin
              QDEPTHi_d[qpidx_w] = apply_wstrb(QDEPTHi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_SQPSNi: begin
              SQPSNi_d[qpidx_w] = apply_wstrb(SQPSNi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_LSTRQREQi: begin
              LSTRQREQi_d[qpidx_w] = apply_wstrb(LSTRQREQi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_DESTQPCONFi: begin
              DESTQPCONFi_d[qpidx_w] = apply_wstrb(DESTQPCONFi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_MACDESADDLSBi: begin
              MACDESADDLSBi_d[qpidx_w] = apply_wstrb(MACDESADDLSBi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_MACDESADDMSBi: begin
              MACDESADDMSBi_d[qpidx_w] = apply_wstrb(MACDESADDMSBi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_IPDESADDR1i: begin
              IPDESADDR1i_d[qpidx_w] = apply_wstrb(IPDESADDR1i_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_IPDESADDR2i: begin
              IPDESADDR2i_d[qpidx_w] = apply_wstrb(IPDESADDR2i_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_IPDESADDR3i: begin
              IPDESADDR3i_d[qpidx_w] = apply_wstrb(IPDESADDR3i_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_IPDESADDR4i: begin
              IPDESADDR4i_d[qpidx_w] = apply_wstrb(IPDESADDR4i_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_TIMEOUTCONFi: begin
              TIMEOUTCONFi_d[qpidx_w] = apply_wstrb(TIMEOUTCONFi_q[qpidx_w], WDataReg_q, mask);
            end
            ADDR_PDNUMi: begin
              PDNUMi_d[qpidx_w] = apply_wstrb(PDNUMi_q[qpidx_w], WDataReg_q, mask);
            end
            default: begin
              WRespReg_d = 2'b10; //SLVERR
            end
          endcase
        end
      end else begin
        case (WAddrReg_q) 
          ADDR_CONF: begin
            CONF_d = apply_wstrb(CONF_q, WDataReg_q, mask);
          end 
          ADDR_ADCONF: begin
            ADCONF_d = apply_wstrb(ADCONF_q, WDataReg_q, mask);
          end 
          ADDR_BUF_THRESHOLD_ROCE: begin
            BUF_THRESHOLD_ROCE_d = apply_wstrb(BUF_THRESHOLD_ROCE_q, WDataReg_q, mask);
          end 
          ADDR_PAUSE_CONF: begin
            PAUSE_CONF_d = apply_wstrb(PAUSE_CONF_q, WDataReg_q, mask);
          end 
          ADDR_MACADDLSB: begin
            MACADDLSB_d = apply_wstrb(MACADDLSB_q, WDataReg_q, mask);
          end 
          ADDR_MACADDMSB: begin
            MACADDMSB_d = apply_wstrb(MACADDMSB_q, WDataReg_q, mask);
          end 
          ADDR_BUF_THRESHOLD_NON_ROCE: begin
            BUF_THRESHOLD_NON_ROCE_d = apply_wstrb(BUF_THRESHOLD_NON_ROCE_q, WDataReg_q, mask);
          end 
          ADDR_IPv6ADD1: begin
            IPv6ADD1_d = apply_wstrb(IPv6ADD1_q, WDataReg_q, mask);
          end  
          ADDR_IPv6ADD2: begin
            IPv6ADD2_d = apply_wstrb(IPv6ADD2_q, WDataReg_q, mask);
          end  
          ADDR_IPv6ADD3: begin
            IPv6ADD3_d = apply_wstrb(IPv6ADD3_q, WDataReg_q, mask);
          end  
          ADDR_IPv6ADD4: begin
            IPv6ADD4_d = apply_wstrb(IPv6ADD4_q, WDataReg_q, mask);
          end   
          ADDR_ERRBUFBA: begin
            ERRBUFBA_d = apply_wstrb(ERRBUFBA_q, WDataReg_q, mask);
          end 
          ADDR_ERRBUFBAMSB: begin
            ERRBUFBAMSB_d = apply_wstrb(ERRBUFBAMSB_q, WDataReg_q, mask);
          end 
          ADDR_ERRBUFSZ: begin
            ERRBUFSZ_d = apply_wstrb(ERRBUFSZ_q, WDataReg_q, mask);
          end 
          ADDR_IPv4ADD: begin
            IPv4ADD_d = apply_wstrb(IPv4ADD_q, WDataReg_q, mask);
          end 
          ADDR_OPKTERRQBA: begin
            OPKTERRQBA_d = apply_wstrb(OPKTERRQBA_q, WDataReg_q, mask);
          end 
          ADDR_OPKTERRQBAMSB: begin
            OPKTERRQBAMSB_d = apply_wstrb(OPKTERRQBAMSB_q, WDataReg_q, mask);
          end 
          ADDR_OUTERRSTSQSZ: begin
            OUTERRSTSQSZ_d = apply_wstrb(OUTERRSTSQSZ_q, WDataReg_q, mask);
          end 
          ADDR_OPTERRSTSQQPTRDB: begin
            OPTERRSTSQQPTRDB_d = apply_wstrb(OPTERRSTSQQPTRDB_q, WDataReg_q, mask);
          end 
          ADDR_IPKTERRQBA: begin
            IPKTERRQBA_d = apply_wstrb(IPKTERRQBA_q, WDataReg_q, mask);
          end 
          ADDR_IPKTERRQBAMSB: begin
            IPKTERRQBAMSB_d = apply_wstrb(IPKTERRQBAMSB_q, WDataReg_q, mask);
          end 
          ADDR_IPKTERRQSZ: begin
            IPKTERRQSZ_d = apply_wstrb(IPKTERRQSZ_q, WDataReg_q, mask);
          end 
          ADDR_DATBUFBA: begin
            DATBUFBA_d = apply_wstrb(DATBUFBA_q, WDataReg_q, mask);
          end 
          ADDR_DATBUFBAMSB: begin
            DATBUFBAMSB_d = apply_wstrb(DATBUFBAMSB_q, WDataReg_q, mask);
          end 
          ADDR_DATBUFSZ: begin
            DATBUFSZ_d = apply_wstrb(DATBUFSZ_q, WDataReg_q, mask);
          end 
          ADDR_CON_IO_CONF: begin
            CON_IO_CONF_d = apply_wstrb(CON_IO_CONF_q, WDataReg_q, mask);
          end 
          ADDR_RESPERRPKTBA: begin
            RESPERRPKTBA_d = apply_wstrb(RESPERRPKTBA_q, WDataReg_q, mask);
          end 
          ADDR_RESPERRPKTBAMSB: begin
            RESPERRPKTBAMSB_d = apply_wstrb(RESPERRPKTBAMSB_q, WDataReg_q, mask);
          end 
          ADDR_RESPERRSZ: begin
            RESPERRSZ_d = apply_wstrb(RESPERRSZ_q, WDataReg_q, mask);
          end 
          ADDR_RESPERRSZMSB: begin
            RESPERRSZMSB_d = apply_wstrb(RESPERRSZMSB_q, WDataReg_q, mask);
          end 
          ADDR_INTEN: begin
            INTEN_d = apply_wstrb(INTEN_q, WDataReg_q, mask);
          end 
          //W1C
          ADDR_RQINTSTS1: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS1_d = 'd0; 
            end 
          end 
          ADDR_RQINTSTS2: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS2_d = 'd0; 
            end 
          end
          ADDR_RQINTSTS3: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS3_d = 'd0; 
            end 
          end
          ADDR_RQINTSTS4: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS4_d = 'd0; 
            end 
          end
          ADDR_RQINTSTS5: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS5_d = 'd0; 
            end 
          end
          ADDR_RQINTSTS6: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS6_d = 'd0; 
            end 
          end
          ADDR_RQINTSTS7: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS7_d = 'd0; 
            end 
          end
          ADDR_RQINTSTS8: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              RQINTSTS8_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS1: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS1_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS2: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS2_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS3: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS3_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS4: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS4_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS5: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS5_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS6: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS6_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS7: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS7_d = 'd0; 
            end 
          end
          ADDR_CQINTSTS8: begin
            if(WDataReg_q == 'd1 && mask[0]) begin 
              CQINTSTS8_d = 'd0; 
            end 
          end
          default: begin
            WRespReg_d = 2'b10;
          end
        endcase
      end
      w_state_d = B_RESP;
    end
    B_RESP: begin
      writing = 1'b1;
      s_axil_bvalid_o = 1'b1;
      if(s_axil_bready_i) begin
        w_state_d = W_IDLE;
      end
    end
  endcase
end

//find PD associated to current QP
always_comb begin
  PDidx_d = PDidx_q;
  if(QPidx_q != QPidx_d || SQPIi_d[QPidx_q] != SQPIi_q[QPidx_q]) begin
    for(int i=0; i < NUM_PD; i++) begin
      if(PDPDNUM_q[i][24:0] == {1'b1, PDNUMi_q[QPidx_q][23:0]}) begin
        PDidx_d = i;
      end
    end
  end
end



always_ff @(posedge axil_aclk_i, negedge rstn_i) begin
  if(!rstn_i) begin
    r_state_q <= R_IDLE;
    w_state_q <= W_IDLE;
    RAddrReg_q <= 'd0;
    RDataReg_q <= 'd0;
    RRespReg_q <= 'd0;
    WAddrReg_q <= 'd0;
    WDataReg_q <= 'd0;
    WRespReg_q <= 'd0;
    WStrbReg_q <= 'd0;

    CONF_q <= 'd0;
    ADCONF_q <= 'd0;
    BUF_THRESHOLD_ROCE_q <= 'd0;
    PAUSE_CONF_q <= 'd0;
    MACADDLSB_q <= 'd0;
    MACADDMSB_q <= 'd0;
    BUF_THRESHOLD_NON_ROCE_q <= 'd0;

    IPv6ADD1_q <= 'd0;
    IPv6ADD2_q <= 'd0;
    IPv6ADD3_q <= 'd0;
    IPv6ADD4_q <= 'd0;

    ERRBUFBA_q <= 'd0;
    ERRBUFBAMSB_q <= 'd0;
    ERRBUFSZ_q <= 'd0;
    ERRBUFWPTR_q <= 'd0;
    IPv4ADD_q <= 'd0;

    OPKTERRQBA_q <= 'd0;
    OPKTERRQBAMSB_q <= 'd0;
    OUTERRSTSQSZ_q <= 'd0;
    OPTERRSTSQQPTRDB_q <= 'd0;
    IPKTERRQBA_q <= 'd0;
    IPKTERRQBAMSB_q <= 'd0;
    IPKTERRQSZ_q <= 'd0;
    IPKTERRQWPTR_q <= 'd0;

    DATBUFBA_q <= 'd0;
    DATBUFBAMSB_q <= 'd0;
    DATBUFSZ_q <= 'd0;
    CON_IO_CONF_q <= 'd0;
    RESPERRPKTBA_q <= 'd0;
    RESPERRPKTBAMSB_q <= 'd0;
    RESPERRSZ_q <= 'd0;
    RESPERRSZMSB_q <= 'd0;

    //Global status regs
    INSRRPKTCNT_q <= 'd0;
    INAMPKTCNT_q <= 'd0;
    OUTIOPKTCNT_q <= 'd0;
    OUTAMPKTCNT_q <= 'd0;
    LSTINPKT_q <= 'd0;
    LSTOUTPKT_q <= 'd0;
    ININVDUPCNT_q <= 'd0;
    INNCKPKTSTS_q <= 'd0;
    OUTRNRPKTSTS_q <= 'd0;
    WQEPROCSTS_q <= 'd0;
    QPMSTS_q <= 'd0;
    INALLDRPPKTCNT_q <= 'd0;
    INNAKPKTCNT_q <= 'd0;
    OUTNAKPKTCNT_q <= 'd0;
    RESPHNDSTS_q <= 'd0;
    RETRYCNTSTS_q <= 'd0;

    INCNPPKTCNT_q <= 'd0;
    OUTCNPPKTCNT_q <= 'd0;
    OUTRDRSPPKTCNT_q <= 'd0;
    INTEN_q <= 'd0;
    INTSTS_q <= 'd0;

    RQINTSTS1_q <= 'd0;
    RQINTSTS2_q <= 'd0;
    RQINTSTS3_q <= 'd0;
    RQINTSTS4_q <= 'd0;
    RQINTSTS5_q <= 'd0;
    RQINTSTS6_q <= 'd0;
    RQINTSTS7_q <= 'd0;
    RQINTSTS8_q <= 'd0;
    CQINTSTS1_q <= 'd0;
    CQINTSTS2_q <= 'd0;
    CQINTSTS3_q <= 'd0;
    CQINTSTS4_q <= 'd0;
    CQINTSTS5_q <= 'd0;
    CQINTSTS6_q <= 'd0;
    CQINTSTS7_q <= 'd0;
    CQINTSTS8_q <= 'd0;
    CNPSCHDSTS1REG_q <= 'd0;
    CNPSCHDSTS2REG_q <= 'd0;
    CNPSCHDSTS3REG_q <= 'd0;
    CNPSCHDSTS4REG_q <= 'd0;
    CNPSCHDSTS5REG_q <= 'd0;
    CNPSCHDSTS6REG_q <= 'd0;
    CNPSCHDSTS7REG_q <= 'd0;
    CNPSCHDSTS8REG_q <= 'd0;
  
    for(int i = 0; i < NUM_PD; i++) begin
      PDPDNUM_q[i] <= 'd0;
      VIRTADDRLSB_q[i] <= 'd0;
      VIRTADDRMSB_q[i] <= 'd0;
      BUFBASEADDRLSB_q[i] <= 'd0;
      BUFBASEADDRMSB_q[i] <= 'd0;
      BUFRKEY_q[i] <= 'd0;
      WRRDBUFLEN_q[i] <= 'd0;
      ACCESSDESC_q[i] <= 'd0;
    end

    for(int i = 0; i < NUM_QP; i++) begin
      QPCONFi_q[i] <= 'd0;
      QPADVCONFi_q[i] <= 'd0;
      RQBAi_q[i] <= 'd0;
      RQBAMSBi_q[i] <= 'd0;
      SQBAi_q[i] <= 'd0;
      SQBAMSBi_q[i] <= 'd0;
      CQBAi_q[i] <= 'd0;
      CQBAMSBi_q[i] <= 'd0;
      RQWPTRDBADDi_q[i] <= 'd0;
      RQWPTRDBADDMSBi_q[i] <= 'd0;
      CQDBADDi_q[i] <= 'd0;
      CQDBADDMSBi_q[i] <= 'd0;
      CQHEADi_q[i] <= 'd0;
      RQCIi_q[i] <= 'd0;
      SQPIi_q[i] <= 'd0;
      QDEPTHi_q[i] <= 'd0;
      SQPSNi_q[i] <= 'd0;
      LSTRQREQi_q[i] <= 'd0;
      DESTQPCONFi_q[i] <= 'd0;
      MACDESADDLSBi_q[i] <= 'd0;
      MACDESADDMSBi_q[i] <= 'd0;
      IPDESADDR1i_q[i] <= 'd0;
      IPDESADDR2i_q[i] <= 'd0;
      IPDESADDR3i_q[i] <= 'd0;
      IPDESADDR4i_q[i] <= 'd0;
      TIMEOUTCONFi_q[i] <= 'd0;
      STATSSNi_q[i] <= 'd0;
      STATMSNi_q[i] <= 'd0;
      STATQPi_q[i] <= 'd0;
      STATCURSQPTRi_q[i] <= 'd0;
      STATRESPSNi_q[i] <= 'd0;
      STATRQBUFCAi_q[i] <= 'd0;
      STATRQBUFCAMSBi_q[i] <= 'd0;
      STATWQEi_q[i] <= 'd0;
      STATRQPIDBi_q[i] <= 'd0;
      PDNUMi_q[i] <= 'd0;
    end

    QPidx_q <= 'd0;
    PDidx_q <= 'd0;
  end else begin
    r_state_q <= r_state_d;
    w_state_q <= w_state_d;
    RAddrReg_q <= RAddrReg_d;
    RDataReg_q <= RDataReg_d;
    RRespReg_q <= RRespReg_d;
    WAddrReg_q <= WAddrReg_d;
    WDataReg_q <= WDataReg_d;
    WRespReg_q <= WRespReg_d;
    WStrbReg_q <= WStrbReg_d;

    CONF_q <= CONF_d;
    ADCONF_q <= ADCONF_d;
    BUF_THRESHOLD_ROCE_q <= BUF_THRESHOLD_ROCE_d;
    PAUSE_CONF_q <= PAUSE_CONF_d;
    MACADDLSB_q <= MACADDLSB_d;
    MACADDMSB_q <= MACADDMSB_d;
    BUF_THRESHOLD_NON_ROCE_q <= BUF_THRESHOLD_NON_ROCE_d;

    IPv6ADD1_q <= IPv6ADD1_d;
    IPv6ADD2_q <= IPv6ADD2_d;
    IPv6ADD3_q <= IPv6ADD3_d;
    IPv6ADD4_q <= IPv6ADD4_d;

    ERRBUFBA_q <= ERRBUFBA_d;
    ERRBUFBAMSB_q <= ERRBUFBAMSB_d;
    ERRBUFSZ_q <= ERRBUFSZ_d;
    ERRBUFWPTR_q <= ERRBUFWPTR_d; 
    IPv4ADD_q <= IPv4ADD_d;

    OPKTERRQBA_q <= OPKTERRQBA_d;
    OPKTERRQBAMSB_q <= OPKTERRQBAMSB_d;
    OUTERRSTSQSZ_q <= OUTERRSTSQSZ_d;
    OPTERRSTSQQPTRDB_q <= OPTERRSTSQQPTRDB_d;
    IPKTERRQBA_q <= IPKTERRQBA_d;
    IPKTERRQBAMSB_q <= IPKTERRQBAMSB_d;
    IPKTERRQSZ_q <= IPKTERRQSZ_d;
    IPKTERRQWPTR_q <= IPKTERRQWPTR_d;

    DATBUFBA_q <= DATBUFBA_d;
    DATBUFBAMSB_q <= DATBUFBAMSB_d;
    DATBUFSZ_q <= DATBUFSZ_d;
    CON_IO_CONF_q <= CON_IO_CONF_d;
    RESPERRPKTBA_q <= RESPERRPKTBA_d;
    RESPERRPKTBAMSB_q <= RESPERRPKTBAMSB_d;
    RESPERRSZ_q <= RESPERRSZ_d;
    RESPERRSZMSB_q <= RESPERRSZMSB_d;

    //Global status regs
    INSRRPKTCNT_q <= INSRRPKTCNT_d;
    INAMPKTCNT_q <= INAMPKTCNT_d;
    OUTIOPKTCNT_q <= OUTIOPKTCNT_d;
    OUTAMPKTCNT_q <= OUTAMPKTCNT_d;
    LSTINPKT_q <= LSTINPKT_d;
    LSTOUTPKT_q <= LSTOUTPKT_d;
    ININVDUPCNT_q <= ININVDUPCNT_d;
    INNCKPKTSTS_q <= INNCKPKTSTS_d;
    OUTRNRPKTSTS_q <= OUTRNRPKTSTS_d;
    WQEPROCSTS_q <= WQEPROCSTS_d;
    QPMSTS_q <= QPMSTS_d;
    INALLDRPPKTCNT_q <= INALLDRPPKTCNT_d;
    INNAKPKTCNT_q <= INNAKPKTCNT_d;
    OUTNAKPKTCNT_q <= OUTNAKPKTCNT_d;
    RESPHNDSTS_q <= RESPHNDSTS_d;
    RETRYCNTSTS_q <= RETRYCNTSTS_d;

    INCNPPKTCNT_q <= INCNPPKTCNT_d;
    OUTCNPPKTCNT_q <= OUTCNPPKTCNT_d;
    OUTRDRSPPKTCNT_q <= OUTRDRSPPKTCNT_d;
    INTEN_q <= INTEN_d;
    INTSTS_q <= INTSTS_d;

    RQINTSTS1_q <= RQINTSTS1_d; 
    RQINTSTS2_q <= RQINTSTS2_d;
    RQINTSTS3_q <= RQINTSTS3_d;
    RQINTSTS4_q <= RQINTSTS4_d;
    RQINTSTS5_q <= RQINTSTS5_d;
    RQINTSTS6_q <= RQINTSTS6_d;
    RQINTSTS7_q <= RQINTSTS7_d;
    RQINTSTS8_q <= RQINTSTS8_d;
    CQINTSTS1_q <= CQINTSTS1_d;
    CQINTSTS2_q <= CQINTSTS2_d;
    CQINTSTS3_q <= CQINTSTS3_d;
    CQINTSTS4_q <= CQINTSTS4_d;
    CQINTSTS5_q <= CQINTSTS5_d;
    CQINTSTS6_q <= CQINTSTS6_d;
    CQINTSTS7_q <= CQINTSTS7_d;
    CQINTSTS8_q <= CQINTSTS8_d;
    CNPSCHDSTS1REG_q <= CNPSCHDSTS1REG_d;
    CNPSCHDSTS2REG_q <= CNPSCHDSTS2REG_d;
    CNPSCHDSTS3REG_q <= CNPSCHDSTS3REG_d;
    CNPSCHDSTS4REG_q <= CNPSCHDSTS4REG_d;
    CNPSCHDSTS5REG_q <= CNPSCHDSTS5REG_d;
    CNPSCHDSTS6REG_q <= CNPSCHDSTS6REG_d;
    CNPSCHDSTS7REG_q <= CNPSCHDSTS7REG_d;
    CNPSCHDSTS8REG_q <= CNPSCHDSTS8REG_d;

    for(int i = 0; i < NUM_PD; i++) begin
      PDPDNUM_q[i] <= PDPDNUM_d[i];
      VIRTADDRLSB_q[i] <= VIRTADDRLSB_d[i];
      VIRTADDRMSB_q[i] <= VIRTADDRMSB_d[i];
      BUFBASEADDRLSB_q[i] <= BUFBASEADDRLSB_d[i];
      BUFBASEADDRMSB_q[i] <= BUFBASEADDRMSB_d[i];
      BUFRKEY_q[i] <= BUFRKEY_d[i];
      WRRDBUFLEN_q[i] <= WRRDBUFLEN_d[i];
      ACCESSDESC_q[i] <= ACCESSDESC_d[i];
    end

    for(int i = 0; i < NUM_QP; i++) begin
      QPCONFi_q[i] <= QPCONFi_d[i];
      QPADVCONFi_q[i] <= QPADVCONFi_d[i];
      RQBAi_q[i] <= RQBAi_d[i];
      RQBAMSBi_q[i] <= RQBAMSBi_d[i];
      SQBAi_q[i] <= SQBAi_d[i];
      SQBAMSBi_q[i] <= SQBAMSBi_d[i];
      CQBAi_q[i] <= CQBAi_d[i];
      CQBAMSBi_q[i] <= CQBAMSBi_d[i];
      RQWPTRDBADDi_q[i] <= RQWPTRDBADDi_d[i];
      RQWPTRDBADDMSBi_q[i] <= RQWPTRDBADDMSBi_d[i];
      CQDBADDi_q[i] <= CQDBADDi_d[i];
      CQDBADDMSBi_q[i] <= CQDBADDMSBi_d[i];
      CQHEADi_q[i] <= CQHEADi_d[i];
      RQCIi_q[i] <=  RQCIi_d[i];
      SQPIi_q[i] <= SQPIi_d[i];
      QDEPTHi_q[i] <= QDEPTHi_d[i];
      SQPSNi_q[i] <= SQPSNi_d[i];
      LSTRQREQi_q[i] <= LSTRQREQi_d[i];
      DESTQPCONFi_q[i] <= DESTQPCONFi_d[i];
      MACDESADDLSBi_q[i] <= MACDESADDLSBi_d[i];
      MACDESADDMSBi_q[i] <= MACDESADDMSBi_d[i];
      IPDESADDR1i_q[i] <= IPDESADDR1i_d[i];
      IPDESADDR2i_q[i] <= IPDESADDR2i_d[i];
      IPDESADDR3i_q[i] <= IPDESADDR3i_d[i];
      IPDESADDR4i_q[i] <= IPDESADDR4i_d[i];
      TIMEOUTCONFi_q[i] <= TIMEOUTCONFi_d[i];
      STATSSNi_q[i] <= STATSSNi_d[i];
      STATMSNi_q[i] <= STATMSNi_d[i];
      STATQPi_q[i] <= STATQPi_d[i];
      STATCURSQPTRi_q[i] <= STATCURSQPTRi_d[i];
      STATRESPSNi_q[i] <= STATRESPSNi_d[i];
      STATRQBUFCAi_q[i] <= STATRQBUFCAi_d[i];
      STATRQBUFCAMSBi_q[i] <= STATRQBUFCAMSBi_d[i];
      STATWQEi_q[i] <= STATWQEi_d[i];
      STATRQPIDBi_q[i] <= STATRQPIDBi_d[i];
      PDNUMi_q[i] <= PDNUMi_d[i];
    end

    QPidx_q <= QPidx_d;
    PDidx_q <= PDidx_d;
  end
end


//////////////
//          //
//    IO    //
//          //
//////////////

assign s_axil_rdata_o = RDataReg_q;
assign s_axil_rresp_o = RRespReg_q;
assign s_axil_bresp_o = WRespReg_q;

assign CONF_o = CONF_q;
assign ADCONF_o = ADCONF_q;
assign MACADD_o = {MACADDMSB_q, MACADDLSB_q};
assign IPv4ADD_o = IPv4ADD_q;
assign INTEN_o = INTEN_q;
assign ERRBUFBA_o = {ERRBUFBAMSB_q, ERRBUFBA_q};
assign ERRBUFSZ_o = ERRBUFSZ_q;
assign IPKTERRQBA_o = {IPKTERRQBAMSB_q, IPKTERRQBA_q};
assign IPKTERRQSZ_o = IPKTERRQSZ_q;
assign DATBUFBA_o = {DATBUFBAMSB_q, DATBUFBA_q};
assign DATBUFSZ_o = DATBUFSZ_q;
assign RESPERRPKTBA_o = {RESPERRPKTBAMSB_q, RESPERRPKTBA_q};
assign RESPERRSZ_o = {RESPERRSZMSB_q, RESPERRSZ_q};

assign QPidx_o = QPidx_q;


assign PDPDNUM_o = PDPDNUM_q[PDidx_q][23:0];
assign VIRTADDR_o = {VIRTADDRMSB_q[PDidx_q], VIRTADDRLSB_q[PDidx_q]};
assign BUFBASEADDR_o = {BUFBASEADDRMSB_q[PDidx_q], BUFBASEADDRLSB_q[PDidx_q]};
assign BUFRKEY_o = BUFRKEY_q[PDidx_q];
assign WRRDBUFLEN_o = {ACCESSDESC_q[PDidx_q][31:16], WRRDBUFLEN_q[PDidx_q]};
assign ACCESSDESC_o = ACCESSDESC_q[PDidx_q][15:0];


//That's a mux...
assign QPCONFi_o = QPCONFi_q[QPidx_q];
assign QPADVCONFi_o = QPADVCONFi_q[QPidx_q];
assign RQBAi_o = {RQBAMSBi_q[QPidx_q], RQBAi_q[QPidx_q]};
assign SQBAi_o = {SQBAMSBi_q[QPidx_q], SQBAi_q[QPidx_q]};
assign CQBAi_o = {CQBAMSBi_q[QPidx_q], CQBAi_q[QPidx_q]};
assign RQWPTRDBADDi_o = {RQWPTRDBADDMSBi_q[QPidx_q], RQWPTRDBADDi_q[QPidx_q]};
assign CQDBADDi_o = {CQDBADDMSBi_q[QPidx_q], CQDBADDi_q[QPidx_q]};
assign SQPIi_o = SQPIi_q[QPidx_q];
assign CQHEADi_o = CQHEADi_q[QPidx_q];
assign QDEPTHi_o = QDEPTHi_q[QPidx_q];
assign SQPSNi_o = SQPSNi_q[QPidx_q][23:0];
assign LSTRQREQi_o = LSTRQREQi_q[QPidx_q];
assign DESTQPCONFi_o = DESTQPCONFi_q[QPidx_q][23:0];
assign MACDESADDi_o = {MACDESADDMSBi_q[QPidx_q], MACDESADDLSBi_q[QPidx_q]};
assign IPDESADDR1i_o = IPDESADDR1i_q[QPidx_q];

/*
//read inputs from logic, async atm
//TODO: maybe needs cdc or dc fifo + handshake
always_comb begin
  for(int i = 0; i < NUM_QP; i++) begin
    CQHEADi_d[i] = CQHEADi_q[i];
  end

  if(!writing && !reading) begin
    CQHEADi_d[QPidx_q] = CQHEADi_i;
  end
end
*/




////////////////////////////
//                        //  
//  AXI MM clock domain   //
//                        //
////////////////////////////

typedef enum {VTP_IDLE, VTP_VALID} virt_to_phys_state;
virt_to_phys_state rd_vtp_st_d, rd_vtp_st_q, wr_vtp_st_d, wr_vtp_st_q;
logic [115:0] rd_resp_addr_data_d, rd_resp_addr_data_q, wr_resp_addr_data_d, wr_resp_addr_data_q;


always_comb begin
  rd_req_addr_ready_o = !writing;
  rd_resp_addr_valid_o = 1'b0;
  rd_resp_addr_data_d = rd_resp_addr_data_q;
  rd_vtp_st_d = rd_vtp_st_q;

  case(rd_vtp_st_q)
    VTP_IDLE: begin
      //wait until read to regs are finished!
      //TODO: check if this can lead to problems
      if(rd_req_addr_valid_i && rd_req_addr_ready_o) begin
        rd_req_addr_ready_o = 1'b0;
        rd_resp_addr_data_d = 'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        for(int i = 0; i < NUM_PD; i++) begin
          if(rd_req_addr_vaddr_i == {VIRTADDRMSB_q[i], VIRTADDRLSB_q[i]}) begin
            rd_resp_addr_data_d = {ACCESSDESC_q[i][3:0], ACCESSDESC_q[i][31:16], WRRDBUFLEN_q[i], BUFBASEADDRMSB_q[i], BUFBASEADDRLSB_q[i]};
          end
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
  wr_req_addr_ready_o = !writing;
  wr_resp_addr_valid_o = 1'b0;
  wr_resp_addr_data_d = wr_resp_addr_data_q;
  wr_vtp_st_d = wr_vtp_st_q;

  case(wr_vtp_st_q)
    VTP_IDLE: begin
      //wait until read to regs are finished!
      //TODO: check if this can lead to problems
      if(wr_req_addr_valid_i && wr_req_addr_ready_o) begin
        wr_req_addr_ready_o = 1'b0;
        wr_resp_addr_data_d = 'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        for(int i = 0; i < NUM_PD; i++) begin
          if(wr_req_addr_vaddr_i == {VIRTADDRMSB_q[i], VIRTADDRLSB_q[i]}) begin
            wr_resp_addr_data_d = {ACCESSDESC_q[i][3:0], ACCESSDESC_q[i][31:16], WRRDBUFLEN_q[i], BUFBASEADDRMSB_q[i], BUFBASEADDRLSB_q[i]};
          end
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

always_ff @(posedge axis_aclk_i, negedge rstn_i) begin
  if(!rstn_i) begin
    rd_vtp_st_q <= VTP_IDLE;
    wr_vtp_st_q <= VTP_IDLE;
    rd_resp_addr_data_q <= 'd0;
    wr_resp_addr_data_q <= 'd0;
  end else begin
    rd_vtp_st_q <= rd_vtp_st_d;
    wr_vtp_st_q <= wr_vtp_st_d;
    rd_resp_addr_data_q <= rd_resp_addr_data_d;
    wr_resp_addr_data_q <= wr_resp_addr_data_d;
  end
end

assign rd_resp_addr_data_o = rd_resp_addr_data_q;
assign wr_resp_addr_data_o = wr_resp_addr_data_q;



endmodule: roce_stack_csr
