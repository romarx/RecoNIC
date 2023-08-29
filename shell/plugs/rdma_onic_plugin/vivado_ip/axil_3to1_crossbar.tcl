#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
set axil_3to1_crossbar_inst axil_3to1_crossbar

create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name $axil_3to1_crossbar_inst -dir ${ip_build_dir}

set_property -dict {
    CONFIG.NUM_SI {3} 
    CONFIG.NUM_MI {1} 
    CONFIG.PROTOCOL {AXI4LITE}
    CONFIG.CONNECTIVITY_MODE {SASD} 
    CONFIG.ID_WIDTH {0} 
    CONFIG.R_REGISTER {1}
    CONFIG.S00_WRITE_ACCEPTANCE {1} 
    CONFIG.S01_WRITE_ACCEPTANCE {1}
    CONFIG.S02_WRITE_ACCEPTANCE {1} 
    CONFIG.S03_WRITE_ACCEPTANCE {1}
    CONFIG.S04_WRITE_ACCEPTANCE {1} 
    CONFIG.S05_WRITE_ACCEPTANCE {1}
    CONFIG.S06_WRITE_ACCEPTANCE {1} 
    CONFIG.S07_WRITE_ACCEPTANCE {1}
    CONFIG.S08_WRITE_ACCEPTANCE {1} 
    CONFIG.S09_WRITE_ACCEPTANCE {1}
    CONFIG.S10_WRITE_ACCEPTANCE {1} 
    CONFIG.S11_WRITE_ACCEPTANCE {1}
    CONFIG.S12_WRITE_ACCEPTANCE {1} 
    CONFIG.S13_WRITE_ACCEPTANCE {1}
    CONFIG.S14_WRITE_ACCEPTANCE {1} 
    CONFIG.S15_WRITE_ACCEPTANCE {1} 
    CONFIG.S00_READ_ACCEPTANCE {1} 
    CONFIG.S01_READ_ACCEPTANCE {1} 
    CONFIG.S02_READ_ACCEPTANCE {1}
    CONFIG.S03_READ_ACCEPTANCE {1} 
    CONFIG.S04_READ_ACCEPTANCE {1} 
    CONFIG.S05_READ_ACCEPTANCE {1} 
    CONFIG.S06_READ_ACCEPTANCE {1} 
    CONFIG.S07_READ_ACCEPTANCE {1}
    CONFIG.S08_READ_ACCEPTANCE {1} 
    CONFIG.S09_READ_ACCEPTANCE {1} 
    CONFIG.S10_READ_ACCEPTANCE {1} 
    CONFIG.S11_READ_ACCEPTANCE {1} 
    CONFIG.S12_READ_ACCEPTANCE {1}
    CONFIG.S13_READ_ACCEPTANCE {1} 
    CONFIG.S14_READ_ACCEPTANCE {1} 
    CONFIG.S15_READ_ACCEPTANCE {1} 
    CONFIG.M00_WRITE_ISSUING {1} 
    CONFIG.M01_WRITE_ISSUING {1} 
    CONFIG.M02_WRITE_ISSUING {1}
    CONFIG.M03_WRITE_ISSUING {1} 
    CONFIG.M04_WRITE_ISSUING {1} 
    CONFIG.M05_WRITE_ISSUING {1}
    CONFIG.M06_WRITE_ISSUING {1} 
    CONFIG.M07_WRITE_ISSUING {1} 
    CONFIG.M08_WRITE_ISSUING {1}
    CONFIG.M09_WRITE_ISSUING {1} 
    CONFIG.M10_WRITE_ISSUING {1} 
    CONFIG.M11_WRITE_ISSUING {1}
    CONFIG.M12_WRITE_ISSUING {1} 
    CONFIG.M13_WRITE_ISSUING {1} 
    CONFIG.M14_WRITE_ISSUING {1}
    CONFIG.M15_WRITE_ISSUING {1} 
    CONFIG.M00_READ_ISSUING {1} 
    CONFIG.M01_READ_ISSUING {1}
    CONFIG.M02_READ_ISSUING {1} 
    CONFIG.M03_READ_ISSUING {1} 
    CONFIG.M04_READ_ISSUING {1}
    CONFIG.M05_READ_ISSUING {1} 
    CONFIG.M06_READ_ISSUING {1} 
    CONFIG.M07_READ_ISSUING {1}
    CONFIG.M08_READ_ISSUING {1} 
    CONFIG.M09_READ_ISSUING {1} 
    CONFIG.M10_READ_ISSUING {1}
    CONFIG.M11_READ_ISSUING {1} 
    CONFIG.M12_READ_ISSUING {1} 
    CONFIG.M13_READ_ISSUING {1}
    CONFIG.M14_READ_ISSUING {1} 
    CONFIG.M15_READ_ISSUING {1} 
    CONFIG.S00_SINGLE_THREAD {1}
    CONFIG.S01_SINGLE_THREAD {1} 
    CONFIG.M00_A00_ADDR_WIDTH {22}
} [get_ips $axil_3to1_crossbar_inst]