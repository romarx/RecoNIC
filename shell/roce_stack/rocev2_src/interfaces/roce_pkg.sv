`define EN_STRM
`define EN_BPSS
`define EN_AVX
`define EN_RDMA_0
`define EN_RDMA
`define EN_NET_0
`define EN_NET
`define EN_ACLK
`define EN_NCLK
`define EN_XCH_0
`define EN_STATS
`define VITIS_HLS
	
package roceTypes;

    // -----------------------------------------------------------------
    // Functions
    // -----------------------------------------------------------------
    function integer clog2s;
    input [31:0] v;
    reg [31:0] value;
    begin
        value = v;
        if (value == 1) begin
            clog2s = 1;
        end
        else begin
            value = value-1;
            for (clog2s=0; value>0; clog2s=clog2s+1)
                value = value>>1;
        end
    end
    endfunction

    function int max (int x, int y);
        max = x > y ? x : y;
    endfunction
    // -----------------------------------------------------------------
    // Static
    // -----------------------------------------------------------------

    // AXI
    parameter integer AXIL_DATA_WIDTH = 32;
    parameter integer AXIL_ADDR_WIDTH = 32;
    parameter integer AXI_DATA_BITS = 512;
    parameter integer AXI_NET_BITS = 512;
    parameter integer AXI_ADDR_BITS = 64;
    parameter integer AXI_ID_BITS = 6;

    // Data
    parameter integer PADDR_BITS = 64;
    parameter integer VADDR_BITS = 64;
    parameter integer OFFS_BITS = 6;
    parameter integer ACCESDESC_BITS = 4;
    parameter integer BUFLEN_BITS = 48;
    parameter integer RKEY_BITS = 8;
    parameter integer LEN_BITS = 28;
    parameter integer DEST_BITS = 4;
    parameter integer PID_BITS = 6;


    parameter integer RC_SEND_FIRST = 5'h0;
    parameter integer RC_SEND_MIDDLE = 5'h1;
    parameter integer RC_SEND_LAST = 5'h2;
    parameter integer RC_SEND_ONLY = 5'h4;
    parameter integer RC_RDMA_WRITE_FIRST = 5'h6;
    parameter integer RC_RDMA_WRITE_MIDDLE = 5'h7;
    parameter integer RC_RDMA_WRITE_LAST = 5'h8;
    parameter integer RC_RDMA_WRITE_LAST_WITH_IMD = 5'h9;
    parameter integer RC_RDMA_WRITE_ONLY = 5'hA;
    parameter integer RC_RDMA_WRITE_ONLY_WIT_IMD = 5'hB;
    parameter integer RC_RDMA_READ_REQUEST = 5'hC;
    parameter integer RC_RDMA_READ_RESP_FIRST = 5'hD;
    parameter integer RC_RDMA_READ_RESP_MIDDLE = 5'hE;
    parameter integer RC_RDMA_READ_RESP_LAST = 5'hF;
    parameter integer RC_RDMA_READ_RESP_ONLY = 5'h10;
    parameter integer RC_ACK = 5'h11;

    parameter integer STRM_BITS = 2;
    parameter integer RDMA_IF_QPN_BITS = 24;
    parameter integer RDMA_NUM_QP = 256;
    parameter integer RDMA_QP_IDX_BITS = clog2s(RDMA_NUM_QP);
    parameter integer RDMA_ACK_BITS = 64;
    parameter integer RDMA_LEN_BITS = 32;
    parameter integer RDMA_IMM_BITS = 32;
    parameter integer RDMA_ACK_QPN_BITS = 10;
    parameter integer RDMA_ACK_PSN_BITS = 24;
    parameter integer RDMA_ACK_MSN_BITS = 24;
    parameter integer RDMA_REQ_BITS = 248;
    parameter integer RDMA_OPCODE_BITS = 5;
    parameter integer RDMA_QPN_BITS = 16;
    parameter integer RDMA_MSG_BITS = 192;
    parameter integer RDMA_N_RD_OUTSTANDING = 8;
    parameter integer RDMA_N_WR_OUTSTANDING = 16;
    parameter integer RDMA_BASE_REQ_BITS = 160;
    

    parameter integer RDMA_QP_INTF_BITS = 200;
    parameter integer RDMA_QP_CONN_BITS = 184;
    parameter integer RDMA_MSN_BITS = 24;
    parameter integer RDMA_OFFS_BITS = 4;
    
    //NET
    parameter integer IPv4_BITS = 32;
    parameter integer PORT_BITS = 16;


    // Protection domain regs: 0x0 - 0x10000, only compare lower bits
    parameter integer ADDR_PDPDNUM         = 'h0;
    parameter integer ADDR_VIRTADDRLSB     = 'h4;
    parameter integer ADDR_VIRTADDRMSB     = 'h8;
    parameter integer ADDR_BUFBASEADDRLSB  = 'hC;
    parameter integer ADDR_BUFBASEADDRMSB  = 'h10;
    parameter integer ADDR_BUFRKEY         = 'h14;
    parameter integer ADDR_WRRDBUFLEN      = 'h18;
    parameter integer ADDR_ACCESSDESC      = 'h1C;

    // Configuration and status regs 0x20000 - 0x201F0
    parameter integer ADDR_CONF                    = 'h000;
    parameter integer ADDR_ADCONF                  = 'h004;
    parameter integer ADDR_BUF_THRESHOLD_ROCE      = 'h008;
    parameter integer ADDR_PAUSE_CONF              = 'h00C;
    parameter integer ADDR_MACADDLSB               = 'h010;
    parameter integer ADDR_MACADDMSB               = 'h014;
    parameter integer ADDR_BUF_THRESHOLD_NON_ROCE  = 'h018;
    parameter integer ADDR_IPv6ADD1                = 'h020; 
    parameter integer ADDR_IPv6ADD2                = 'h024; 
    parameter integer ADDR_IPv6ADD3                = 'h028; 
    parameter integer ADDR_IPv6ADD4                = 'h02C;  
    parameter integer ADDR_ERRBUFBA                = 'h060;
    parameter integer ADDR_ERRBUFBAMSB             = 'h064;
    parameter integer ADDR_ERRBUFSZ                = 'h068;
    parameter integer ADDR_ERRBUFWPTR              = 'h06C;
    parameter integer ADDR_IPv4ADD                 = 'h070;
    parameter integer ADDR_OPKTERRQBA              = 'h078;
    parameter integer ADDR_OPKTERRQBAMSB           = 'h07C;
    parameter integer ADDR_OUTERRSTSQSZ            = 'h080;
    parameter integer ADDR_OPTERRSTSQQPTRDB        = 'h084;
    parameter integer ADDR_IPKTERRQBA              = 'h088;
    parameter integer ADDR_IPKTERRQBAMSB           = 'h08C;
    parameter integer ADDR_IPKTERRQSZ              = 'h090;
    parameter integer ADDR_IPKTERRQWPTR            = 'h094;
    parameter integer ADDR_DATBUFBA                = 'h0A0;
    parameter integer ADDR_DATBUFBAMSB             = 'h0A4;
    parameter integer ADDR_DATBUFSZ                = 'h0A8;
    parameter integer ADDR_CON_IO_CONF             = 'h0AC;
    parameter integer ADDR_RESPERRPKTBA            = 'h0B0;
    parameter integer ADDR_RESPERRPKTBAMSB         = 'h0B4;
    parameter integer ADDR_RESPERRSZ               = 'h0B8;
    parameter integer ADDR_RESPERRSZMSB            = 'h0BC;
    //Global status regs
    parameter integer ADDR_INSRRPKTCNT             = 'h100;
    parameter integer ADDR_INAMPKTCNT              = 'h104;
    parameter integer ADDR_OUTIOPKTCNT             = 'h108;
    parameter integer ADDR_OUTAMPKTCNT             = 'h10C;
    parameter integer ADDR_LSTINPKT                = 'h110;
    parameter integer ADDR_LSTOUTPKT               = 'h114;
    parameter integer ADDR_ININVDUPCNT             = 'h118;
    parameter integer ADDR_INNCKPKTSTS             = 'h11C;
    parameter integer ADDR_OUTRNRPKTSTS            = 'h120;
    parameter integer ADDR_WQEPROCSTS              = 'h124;
    parameter integer ADDR_QPMSTS                  = 'h12C;
    parameter integer ADDR_INALLDRPPKTCNT          = 'h130;
    parameter integer ADDR_INNAKPKTCNT             = 'h134;
    parameter integer ADDR_OUTNAKPKTCNT            = 'h138;
    parameter integer ADDR_RESPHNDSTS              = 'h13C;
    parameter integer ADDR_RETRYCNTSTS             = 'h140;
    parameter integer ADDR_INCNPPKTCNT             = 'h174;
    parameter integer ADDR_OUTCNPPKTCNT            = 'h178;
    parameter integer ADDR_OUTRDRSPPKTCNT          = 'h17C;
    parameter integer ADDR_INTEN                   = 'h180;
    parameter integer ADDR_INTSTS                  = 'h184;
    parameter integer ADDR_RQINTSTS1               = 'h190;
    parameter integer ADDR_RQINTSTS2               = 'h194;
    parameter integer ADDR_RQINTSTS3               = 'h198;
    parameter integer ADDR_RQINTSTS4               = 'h19C;
    parameter integer ADDR_RQINTSTS5               = 'h1A0;
    parameter integer ADDR_RQINTSTS6               = 'h1A4;
    parameter integer ADDR_RQINTSTS7               = 'h1A8;
    parameter integer ADDR_RQINTSTS8               = 'h1AC;
    parameter integer ADDR_CQINTSTS1               = 'h1B0;
    parameter integer ADDR_CQINTSTS2               = 'h1B4;
    parameter integer ADDR_CQINTSTS3               = 'h1B8;
    parameter integer ADDR_CQINTSTS4               = 'h1BC;
    parameter integer ADDR_CQINTSTS5               = 'h1C0;
    parameter integer ADDR_CQINTSTS6               = 'h1C4;
    parameter integer ADDR_CQINTSTS7               = 'h1C8;
    parameter integer ADDR_CQINTSTS8               = 'h1CC;
    parameter integer ADDR_CNPSCHDSTS1REG          = 'h1D0;
    parameter integer ADDR_CNPSCHDSTS2REG          = 'h1D4;
    parameter integer ADDR_CNPSCHDSTS3REG          = 'h1D8;
    parameter integer ADDR_CNPSCHDSTS4REG          = 'h1DC;
    parameter integer ADDR_CNPSCHDSTS5REG          = 'h1E0;
    parameter integer ADDR_CNPSCHDSTS6REG          = 'h1E4;
    parameter integer ADDR_CNPSCHDSTS7REG          = 'h1E8;
    parameter integer ADDR_CNPSCHDSTS8REG          = 'h1EC;

    //Per QP registers (NUMQP min is 8, max is 256) (these actually start at 0x20200), only compare 8 lower bits, idx is upper 10 bits - 0x202
    parameter integer ADDR_QPCONFi         = 'h0;
    parameter integer ADDR_QPADVCONFi      = 'h4;
    parameter integer ADDR_RQBAi           = 'h8;
    parameter integer ADDR_RQBAMSBi        = 'hC0;
    parameter integer ADDR_SQBAi           = 'h10;
    parameter integer ADDR_SQBAMSBi        = 'hC8;
    parameter integer ADDR_CQBAi           = 'h18;
    parameter integer ADDR_CQBAMSBi        = 'hD0;
    parameter integer ADDR_RQWPTRDBADDi    = 'h20;
    parameter integer ADDR_RQWPTRDBADDMSBi = 'h24;
    parameter integer ADDR_CQDBADDi        = 'h28;
    parameter integer ADDR_CQDBADDMSBi     = 'h2C;
    parameter integer ADDR_CQHEADi         = 'h30;
    parameter integer ADDR_RQCIi           = 'h34;
    parameter integer ADDR_SQPIi           = 'h38;
    parameter integer ADDR_QDEPTHi         = 'h3C;
    parameter integer ADDR_SQPSNi          = 'h40;
    parameter integer ADDR_LSTRQREQi       = 'h44;
    parameter integer ADDR_DESTQPCONFi     = 'h48;
    parameter integer ADDR_MACDESADDLSBi   = 'h50;
    parameter integer ADDR_MACDESADDMSBi   = 'h54;
    parameter integer ADDR_IPDESADDR1i     = 'h60;
    parameter integer ADDR_IPDESADDR2i     = 'h64;
    parameter integer ADDR_IPDESADDR3i     = 'h68;
    parameter integer ADDR_IPDESADDR4i     = 'h6C;
    parameter integer ADDR_TIMEOUTCONFi    = 'h4C;
    parameter integer ADDR_STATSSNi        = 'h80;
    parameter integer ADDR_STATMSNi        = 'h84;
    parameter integer ADDR_STATQPi         = 'h88;
    parameter integer ADDR_STATCURSQPTRi   = 'h8C;
    parameter integer ADDR_STATRESPSNi     = 'h90;
    parameter integer ADDR_STATRQBUFCAi    = 'h94;
    parameter integer ADDR_STATRQBUFCAMSBi = 'hD8;
    parameter integer ADDR_STATWQEi        = 'h98;
    parameter integer ADDR_STATRQPIDBi     = 'h9C;
    parameter integer ADDR_PDNUMi          = 'hB0;

    parameter integer PDPDNUM_idx         = 'd0;
    parameter integer VIRTADDRLSB_idx     = 'd1;
    parameter integer VIRTADDRMSB_idx     = 'd2;
    parameter integer BUFBASEADDRLSB_idx  = 'd3;
    parameter integer BUFBASEADDRMSB_idx  = 'd4;
    parameter integer BUFRKEY_idx         = 'd5;
    parameter integer WRRDBUFLEN_idx      = 'd6;
    parameter integer ACCESSDESC_idx      = 'd7;

    parameter integer QPCONFi_idx         = 'd0;
    parameter integer QPADVCONFi_idx      = 'd1;
    parameter integer RQBAi_idx           = 'd2;
    parameter integer RQBAMSBi_idx        = 'd3;
    parameter integer SQBAi_idx           = 'd4;
    parameter integer SQBAMSBi_idx        = 'd5;
    parameter integer CQBAi_idx           = 'd6;
    parameter integer CQBAMSBi_idx        = 'd7;
    parameter integer RQWPTRDBADDi_idx    = 'd8;
    parameter integer RQWPTRDBADDMSBi_idx = 'd9;
    parameter integer CQDBADDi_idx        = 'd10;
    parameter integer CQDBADDMSBi_idx     = 'd11;
    parameter integer CQHEADi_idx         = 'd12;
    parameter integer RQCIi_idx           = 'd13;
    parameter integer SQPIi_idx           = 'd14;
    parameter integer QDEPTHi_idx         = 'd15;
    parameter integer SQPSNi_idx          = 'd16;
    parameter integer LSTRQREQi_idx       = 'd17;
    parameter integer DESTQPCONFi_idx     = 'd18;
    parameter integer MACDESADDLSBi_idx   = 'd19;
    parameter integer MACDESADDMSBi_idx   = 'd20;
    parameter integer IPDESADDR1i_idx     = 'd21;
    parameter integer IPDESADDR2i_idx     = 'd22;
    parameter integer IPDESADDR3i_idx     = 'd23;
    parameter integer IPDESADDR4i_idx     = 'd24;
    parameter integer TIMEOUTCONFi_idx    = 'd25;
    parameter integer STATSSNi_idx        = 'd26;
    parameter integer STATMSNi_idx        = 'd27;
    parameter integer STATQPi_idx         = 'd28;
    parameter integer STATCURSQPTRi_idx   = 'd29;
    parameter integer STATRESPSNi_idx     = 'd30;
    parameter integer STATRQBUFCAi_idx    = 'd31;
    parameter integer STATRQBUFCAMSBi_idx = 'd32;
    parameter integer STATWQEi_idx        = 'd33;
    parameter integer STATRQPIDBi_idx     = 'd34;
    parameter integer PDNUMi_idx          = 'd35;


    parameter integer NUM_QP = 256;
    parameter integer NUM_PD = 256;
    parameter integer AXIL_DATA_WIDTH_BYTES = AXIL_DATA_WIDTH/8;
    parameter integer REG_WIDTH = 32;

    parameter integer CSR_ADDRESS_SPACE = 262144; //256kb
    parameter integer CSR_ADDRESS_WIDTH = $clog2(CSR_ADDRESS_SPACE);

    parameter integer LOG_NUM_PD = 8;
    parameter integer LOG_NUM_QP = 8; //fix to 8.
    

    parameter integer NUM_PD_REGS = 8;
    parameter integer LOG_NUM_PD_REGS = $clog2(NUM_PD_REGS);
    parameter integer NUM_QP_REGS = 36;
    parameter integer LOG_NUM_QP_REGS = $clog2(NUM_QP_REGS)+1;


    // -----------------------------------------------------------------
    // Dynamic
    // -----------------------------------------------------------------

    // Flow
    parameter integer N_REGIONS_BITS = clog2s(1);

        
    // -----------------------------------------------------------------
    // Structs
    // -----------------------------------------------------------------
    typedef struct packed {
        // Opcode
        logic [RDMA_OPCODE_BITS-1:0] opcode;
        logic [STRM_BITS-1:0] strm;
        logic mode;
        logic rdma;
        logic remote;

        // ID
        logic [DEST_BITS-1:0] vfid; // rsrvd
        logic [PID_BITS-1:0] pid;
        logic [DEST_BITS-1:0] dest;
        logic [RDMA_QPN_BITS-1:0] qpn;

        // FLAGS
        logic last;

        // DESC
        logic [VADDR_BITS-1:0] vaddr;
        logic [LEN_BITS-1:0] len;

        // RSRVD
        logic actv; // rsrvd
        logic host; // rsrvd
        logic [OFFS_BITS-1:0] offs; // rsrvd

        logic [128-OFFS_BITS-2-VADDR_BITS-LEN_BITS-1-2*DEST_BITS-PID_BITS-3-STRM_BITS-RDMA_OPCODE_BITS-1:0] rsrvd;
    } req_t;

    typedef struct packed {
        logic [RDMA_OPCODE_BITS-1:0] opcode;
        logic [RDMA_QPN_BITS-1:0] qpn;
        logic host;
        logic mode;
        logic last;
        logic cmplt;
        logic [RDMA_MSN_BITS-1:0] ssn;
        logic [RDMA_OFFS_BITS-1:0] offs;
        logic [RDMA_MSG_BITS-1:0] msg;
        logic [RDMA_REQ_BITS-RDMA_MSG_BITS-RDMA_OFFS_BITS-RDMA_MSN_BITS-4-RDMA_QPN_BITS-RDMA_OPCODE_BITS-1:0] rsrvd;
    } rdma_req_t;

    typedef struct packed {
        logic rd;
        logic cmplt;
        logic [PID_BITS-1:0] pid;
        logic [DEST_BITS-1:0] vfid;
        logic [RDMA_ACK_MSN_BITS-1:0] ssn;
    } rdma_ack_t;

    typedef struct packed {
        logic [RDMA_QP_IDX_BITS-1:0]  conn_idx;
        logic [RDMA_IF_QPN_BITS-1:0]  dest_qp;
        logic [IPv4_BITS-1:0]         dest_ip_addr;
        logic [PORT_BITS-1:0]         port; //take port from conf (assume it's standard port)
    } conndata_struct; //80 bits


    typedef struct packed {
        logic [RDMA_QP_IDX_BITS-1:0]  sq_idx;
        logic [PADDR_BITS-1:0]        cq_base_addr;
        logic [PADDR_BITS-1:0]        sq_base_addr;
        logic [AXIL_DATA_WIDTH-1:0]    sq_prod_idx; //AXI lite data bits for complete regs
        logic [AXIL_DATA_WIDTH-1:0]    cq_head_idx;
        logic [VADDR_BITS-1:0]        pd_vaddr;
    } SQdata_struct; //232 bits

    
    typedef struct packed { 
        logic [RDMA_QP_IDX_BITS-1:0]  qp_idx;
        logic [AXIL_DATA_WIDTH-1:0]    src_qp_conf; //AXI lite data bits for complete regs
        logic [RDMA_IF_QPN_BITS-1:0]  dest_qp;
        logic [RDMA_MSN_BITS-1:0]     sq_psn;
        logic [RDMA_MSN_BITS-1:0]     dest_sq_psn;
    } QPdata_struct; //112 bits

    typedef struct packed {
      logic [1:0]                 region;   // 0: GLB, 1: PD, 2: QP
      logic                       read_all; // if 1, read all addresses of region (only in PD and QP)
      logic [LOG_NUM_QP_REGS-1:0] bram_idx; // idx of specific register (only in PD and QP)
      logic [LOG_NUM_QP-1:0]      address;  // address to read (0-255)
    } rd_cmd_t;

    typedef struct packed {
      logic [1:0]                 region;   // 0: GLB, 1: PD, 2: QP
      logic [LOG_NUM_QP_REGS-1:0] bram_idx; // idx of specific register (only in PD and QP)
      logic [LOG_NUM_QP-1:0]      address;  // address to read (0-255)
      logic [3:0]                 wstrb;
      logic [REG_WIDTH-1:0]       data;
    } wr_cmd_t;

    typedef struct packed {
        logic [ACCESDESC_BITS-1:0] accesdesc;
        logic [BUFLEN_BITS-1:0] buflen;
        logic [PADDR_BITS-1:0] paddr;
        logic [RKEY_BITS-1:0] rkey;
    }dma_req_t;

    typedef struct packed {
        logic [RDMA_OPCODE_BITS-1:0] opcode;
        logic [STRM_BITS-1:0] strm;
        logic remote;
        logic host;
        logic [DEST_BITS-1:0] dest;
        logic [PID_BITS-1:0] pid;
        logic [DEST_BITS-1:0] vfid;
        logic [32-RDMA_OPCODE_BITS-STRM_BITS-2-DEST_BITS-PID_BITS-DEST_BITS-1:0] rsrvd;
    } ack_t;

    typedef struct packed {
        ack_t ack;
        logic last;
    } dack_t;

    typedef struct packed {
        req_t req_1; // rd, local
        req_t req_2; // wr, remote
    } dreq_t;

    typedef struct packed {
        logic [63:0] vaddr;
        logic [31:0] r_key;
        logic [23:0] remote_psn;
        logic [23:0] local_psn;
        logic [23:0] qp_num;
        logic [31:0] new_state;
    } rdma_qp_ctx_t;

    typedef struct packed {
        logic [15:0] remote_udp_port;
        logic [127:0] remote_ip_address;
        logic [23:0] remote_qpn;
        logic [15:0] local_qpn;
    } rdma_qp_conn_t;


    function logic is_opcode_rd_req;
    input [RDMA_OPCODE_BITS-1:0] opcode;
    begin
        if (opcode == RC_RDMA_READ_REQUEST) begin
            is_opcode_rd_req = 1'b1;
        end
        else begin
            is_opcode_rd_req = 1'b0;
        end
    end
    endfunction

    function logic is_opcode_rd_resp;
    input [RDMA_OPCODE_BITS-1:0] opcode;
    begin
        if (opcode == RC_RDMA_READ_RESP_FIRST ||
            opcode == RC_RDMA_READ_RESP_MIDDLE ||
            opcode == RC_RDMA_READ_RESP_LAST ||
            opcode == RC_RDMA_READ_RESP_ONLY) begin
            is_opcode_rd_resp = 1'b1;
        end
        else begin
            is_opcode_rd_resp = 1'b0;
        end
    end
    endfunction

endpackage