create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name cdc_fifo_qp -dir ${ip_build_dir} 
set_property -dict {
    CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} 
    CONFIG.Performance_Options {Standard_FIFO} 
    CONFIG.Input_Data_Width {112} 
    CONFIG.Output_Data_Width {112} 
    CONFIG.Valid_Flag {true} 
    CONFIG.Write_Acknowledge_Flag {true} 
    CONFIG.Read_Clock_Frequency {100} 
    CONFIG.Write_Clock_Frequency {200} 
    CONFIG.Full_Threshold_Assert_Value {256} 
    CONFIG.Full_Threshold_Negate_Value {255} 
    CONFIG.Empty_Threshold_Assert_Value {0} 
    CONFIG.Empty_Threshold_Negate_Value {1}
} [get_ips cdc_fifo_qp]

