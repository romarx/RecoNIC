create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name reg_cmd_cdc_fifo -dir ${ip_build_dir}

set_property -dict {
        CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO}
        CONFIG.Input_Data_Width {18}
        CONFIG.Input_Depth {512}
        CONFIG.Output_Data_Width {18}
        CONFIG.Output_Depth {512}
        CONFIG.Reset_Type {Synchronous_Reset}
        CONFIG.Full_Flags_Reset_Value {0}
        CONFIG.Valid_Flag {true}
        CONFIG.Write_Acknowledge_Flag {true}
        CONFIG.Data_Count_Width {9}
        CONFIG.Write_Data_Count_Width {9}
        CONFIG.Read_Data_Count_Width {9}
        CONFIG.Read_Clock_Frequency {250}
        CONFIG.Write_Clock_Frequency {125}
        CONFIG.Programmable_Full_Type {No_Programmable_Full_Threshold}
        CONFIG.Full_Threshold_Assert_Value {511}
        CONFIG.Full_Threshold_Negate_Value {510}
        CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold}
        CONFIG.Empty_Threshold_Assert_Value {5}
        CONFIG.Empty_Threshold_Negate_Value {6}
        CONFIG.Enable_Safety_Circuit {false}
} [get_ips reg_cmd_cdc_fifo]
