create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name block_ram_1k -dir ${ip_build_dir}

set_property -dict {
    CONFIG.Memory_Type {True_Dual_Port_RAM}
    CONFIG.Use_Byte_Write_Enable {true}
    CONFIG.Byte_Size {8}
    CONFIG.Write_Width_A {32}
    CONFIG.Write_Depth_A {256}
    CONFIG.Read_Width_A {32}
    CONFIG.Write_Width_B {32}
    CONFIG.Read_Width_B {32}
    CONFIG.Enable_B {Use_ENB_Pin}
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false}
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false}
    CONFIG.Use_RSTA_Pin {true}
    CONFIG.Use_RSTB_Pin {false}
    CONFIG.Port_B_Clock {250}
    CONFIG.Port_B_Write_Rate {50}
    CONFIG.Port_B_Enable_Rate {100}
    CONFIG.EN_SAFETY_CKT {true}
} [get_ips block_ram_1k]
