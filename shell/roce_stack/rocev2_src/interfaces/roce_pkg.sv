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

    // -----------------------------------------------------------------
    // Static
    // -----------------------------------------------------------------

    // AXI
    parameter integer AXIL_DATA_BITS = 32;
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
        logic [AXIL_DATA_BITS-1:0]    sq_prod_idx; //AXI lite data bits for complete regs
        logic [VADDR_BITS-1:0]        pd_vaddr;
    } SQdata_struct; //232 bits

    typedef struct packed { 
        logic [RDMA_QP_IDX_BITS-1:0]  qp_idx;
        logic [AXIL_DATA_BITS-1:0]    src_qp_conf; //AXI lite data bits for complete regs
        logic [RDMA_IF_QPN_BITS-1:0]  dest_qp;
        logic [RDMA_MSN_BITS-1:0]     sq_psn;
        logic [RDMA_MSN_BITS-1:0]     dest_sq_psn;
    } QPdata_struct; //112 bits

    typedef struct packed {
        logic [ACCESDESC_BITS-1:0] accesdesc;
        logic [BUFLEN_BITS-1:0] buflen;
        logic [PADDR_BITS-1:0] paddr;
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