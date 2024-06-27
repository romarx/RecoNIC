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

    parameter integer RDMA_IF_QPN_BITS = 24;
    parameter integer RDMA_NUM_QP = 256;
    parameter integer RDMA_QP_IDX_BITS = clog2s(RDMA_NUM_QP);
    parameter integer RDMA_ACK_BITS = 40;
    parameter integer RDMA_ACK_QPN_BITS = 10;
    parameter integer RDMA_ACK_PSN_BITS = 24;
    parameter integer RDMA_ACK_MSN_BITS = 24;
    parameter integer RDMA_BASE_REQ_BITS = 96;
    parameter integer RDMA_REQ_BITS = 256;
    parameter integer RDMA_OPCODE_BITS = 5;
    parameter integer RDMA_QPN_BITS = 10;
    parameter integer RDMA_MSG_BITS = 192;
    

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
        logic [VADDR_BITS-1:0] vaddr;
        logic [LEN_BITS-1:0] len;
        logic stream;
        logic sync;
        logic ctl;
        logic host;
        logic [DEST_BITS-1:0] dest;
        logic [PID_BITS-1:0] pid;
        logic [N_REGIONS_BITS-1:0] vfid;
        logic [96-4-N_REGIONS_BITS-VADDR_BITS-LEN_BITS-DEST_BITS-PID_BITS-1:0] rsrvd;
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
        logic [RDMA_QP_IDX_BITS-1:0]   conn_idx;
        logic [RDMA_IF_QPN_BITS-1:0]  dest_qp;
        logic [IPv4_BITS-1:0]  dest_ip_addr;
        logic [PORT_BITS-1:0]  port; //take port from conf (assume it's standard port)
    } conndata_struct; //80 bits


    typedef struct packed {
        logic [RDMA_QP_IDX_BITS-1:0]   qp_idx;
        logic [PADDR_BITS-1:0]  sq_base_addr;
        logic [AXIL_DATA_BITS-1:0]  sq_prod_idx; //AXI lite data bits for complete regs
        logic [VADDR_BITS-1:0]  pd_vaddr;
    } SQdata_struct; //168 bits

    typedef struct packed { 
        logic [RDMA_QP_IDX_BITS-1:0]   qp_idx;
        logic [AXIL_DATA_BITS-1:0]  src_qp_conf; //AXI lite data bits for complete regs
        logic [RDMA_IF_QPN_BITS-1:0] dest_qp;
        logic [RDMA_MSN_BITS-1:0]  sq_psn;
        logic [RDMA_MSN_BITS-1:0]  dest_sq_psn;
    } QPdata_struct; //112 bits

    typedef struct packed {
        logic [ACCESDESC_BITS-1:0] accesdesc;
        logic [BUFLEN_BITS-1:0] buflen;
        logic [PADDR_BITS-1:0] paddr;
    }dma_req_t;

endpackage