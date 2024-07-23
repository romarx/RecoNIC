create_ip -name axi_datamover -vendor xilinx.com -library ip -version 5.1 -module_name roce_stack_axi_datamover -dir ${ip_build_dir} 

set_property -dict {
    CONFIG.c_m_axi_mm2s_data_width {512}
    CONFIG.c_m_axis_mm2s_tdata_width {512}
    CONFIG.c_mm2s_burst_size {64}
    CONFIG.c_m_axi_s2mm_data_width {512}
    CONFIG.c_s_axis_s2mm_tdata_width {512}
    CONFIG.c_s2mm_burst_size {64}
    CONFIG.c_m_axi_mm2s_id_width {1}
    CONFIG.c_m_axi_s2mm_id_width {1}
    CONFIG.c_enable_mm2s_adv_sig {0}
    CONFIG.c_addr_width {64}
} [get_ips roce_stack_axi_datamover]

