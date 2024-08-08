create_ip -name axis_interconnect -vendor xilinx.com -library ip -version 1.1 -module_name roce_stack_tx_axis_interconnect -dir ${ip_build_dir} 
set_property -dict {
    CONFIG.C_NUM_SI_SLOTS {2}
    CONFIG.SWITCH_TDATA_NUM_BYTES {64}
    CONFIG.HAS_TSTRB {false}
    CONFIG.HAS_TID {false}
    CONFIG.HAS_TDEST {false}
    CONFIG.SWITCH_USE_ACLKEN {false}
    CONFIG.SWITCH_PACKET_MODE {true}
    CONFIG.C_SWITCH_MAX_XFERS_PER_ARB {0}
    CONFIG.C_SWITCH_MI_REG_CONFIG {1}
    CONFIG.C_SWITCH_NUM_CYCLES_TIMEOUT {0}
    CONFIG.M00_AXIS_TDATA_NUM_BYTES {64}
    CONFIG.S00_AXIS_TDATA_NUM_BYTES {64}
    CONFIG.S01_AXIS_TDATA_NUM_BYTES {64}
    CONFIG.M00_S01_CONNECTIVITY {true}
} [get_ips roce_stack_tx_axis_interconnect]


