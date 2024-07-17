create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name cdc_fifo_sq -dir ${ip_build_dir} 
set_property -dict {
     CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} 
    CONFIG.Performance_Options {Standard_FIFO} 
    CONFIG.Input_Data_Width {232} 
    CONFIG.Output_Data_Width {232}
    CONFIG.Input_Depth {512}
    CONFIG.Output_Depth {512}
    CONFIG.Data_Count_Width {9}
    CONFIG.Write_Data_Count_Width {9}
    CONFIG.Read_Data_Count_Width {9}
    CONFIG.Valid_Flag {true} 
    CONFIG.Write_Acknowledge_Flag {true} 
    CONFIG.Read_Clock_Frequency {100}
    CONFIG.Write_Clock_Frequency {200}
    CONFIG.Full_Threshold_Assert_Value {511} 
    CONFIG.Full_Threshold_Negate_Value {510} 
    CONFIG.Empty_Threshold_Assert_Value {5} 
    CONFIG.Empty_Threshold_Negate_Value {6}
} [get_ips cdc_fifo_sq]

