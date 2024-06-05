create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name roce_stack_cdc_fifo_qp_wq -dir ${ip_build_dir} 
set_property -dict {
    CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} 
    CONFIG.Performance_Options {Standard_FIFO} 
    CONFIG.Input_Data_Width {336} 
    CONFIG.Output_Data_Width {336} 
    CONFIG.Valid_Flag {true} 
    CONFIG.Write_Acknowledge_Flag {true} 
    CONFIG.Read_Clock_Frequency {100} 
    CONFIG.Write_Clock_Frequency {200} 
    CONFIG.Full_Threshold_Assert_Value {1022} 
    CONFIG.Full_Threshold_Negate_Value {1021} 
    CONFIG.Empty_Threshold_Assert_Value {5} 
    CONFIG.Empty_Threshold_Negate_Value {6}
} [get_ips roce_stack_cdc_fifo_qp_wq]

