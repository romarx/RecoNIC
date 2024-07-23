#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
VIVADO_DATA_DIR=$VIVADO_DIR/data
XVIP_PATH=$VIVADO_DATA_DIR/xilinx_vip
XVIP_INCLUDE=$XVIP_PATH/include

xvlog_opts="--relax --incr"
xvhdl_opts="--relax --incr"

xvlog $xvlog_opts -work reco -L cam_v2_2_2 -sv -L vitis_net_p4_v1_0_2 \
--include "../build/ip/packet_parser/hdl" --include "../build/ip/packet_parser/src/hw/include" \
--include "$XVIP_INCLUDE" \
"../build/ip/packet_parser/src/verilog/packet_parser_top_pkg.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_pkg.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_sync_fifos.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_header_sequence_identifier.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_header_field_extractor.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_error_check_module.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_parser_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_deparser_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_action_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_lookup_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_axi4lite_interconnect.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_statistics_registers.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_match_action_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_top.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser.sv"

xvhdl $xvhdl_opts -work reco \
"../build/ip/axi_mm_bram/sim/axi_mm_bram.vhd"

xvhdl $xvhdl_opts -work reco \
"../build/ip/axi_sys_mm/sim/axi_sys_mm.vhd"

xvlog $xvlog_opts -work reco --include "../build/ip/reconic_axil_crossbar/hdl" \
"../build/ip/reconic_axil_crossbar/hdl/axi_crossbar_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/axi_data_fifo_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/axi_register_slice_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/fifo_generator_v13_2_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/generic_baseblocks_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/sim/reconic_axil_crossbar.v"

xvlog $xvlog_opts -work reco -L axi_crossbar_v2_1_26 --include "../build/ip/axil_3to1_crossbar/hdl" \
"../build/ip/axil_3to1_crossbar/sim/axil_3to1_crossbar.v" \

xvlog $xvlog_opts -work reco -sv \
"../../base_nics/open-nic-shell/src/utility/generic_reset.sv" \
"../../base_nics/open-nic-shell/src/rdma_subsystem/rdma_subsystem.sv" \
"../../base_nics/open-nic-shell/src/rdma_subsystem/rdma_subsystem_wrapper.sv" \

xvlog $xvlog_opts -work reco -sv -L blk_mem_gen_v8_4_5 -L fifo_generator_v13_2_6 \
-i ../build/ip/axi_protocol_checker/hdl/verilog \
"../build/ip/axi_protocol_checker/hdl/sc_util_v1_0_vl_rfs.sv" \
"../build/ip/axi_protocol_checker/hdl/axi_protocol_checker_v2_0_vl_rfs.sv" \
"../build/ip/axi_protocol_checker/sim/axi_protocol_checker.sv"

xvlog $xvlog_opts -work reco -sv -L fifo_generator_v13_2_6 \
"../build/ip/dev_mem_axi_crossbar/synth/dev_mem_axi_crossbar.v" 

xvlog $xvlog_opts -d DEBUG -work reco -i ../../shell/compute/lookside/interface -f ./interface.f
xvlog $xvlog_opts -d DEBUG -work reco -i ../../shell/compute/lookside/kernel -f ./kernel.f

xvhdl $xvhdl_opts -work reco -L ernic_v3_1_1 \
"../build/ip/rdma_core/hdl/fifo_generator_v13_2_rfs.vhd" \
"../build/ip/rdma_core/hdl/lib_bmg_v1_0_rfs.vhd" \
"../build/ip/rdma_core/hdl/lib_fifo_v1_0_rfs.vhd"

xvlog $xvlog_opts -work reco -sv -L ernic_v3_1_1 -i ../build/ip/rdma_core/hdl/common \
"../build/ip/rdma_core/synth/rdma_core.sv"

xvlog $xvlog_opts -sv -L xpm -L ernic_v3_1_1 -L axi_bram_ctrl_v4_1_6 -d DEBUG -work reco \
"../../shell/utilities/rn_reg_control.sv" \
"../../shell/packet_classification/packet_classification.sv" \
"../../shell/packet_classification/packet_filter.sv" \
"../../shell/compute/lookside/compute_logic_wrapper.sv" \
"../../shell/compute/lookside/control_command_processor.sv" \
"../../base_nics/open-nic-shell/src/utility/axi_interconnect_to_dev_mem.sv" \
"../../base_nics/open-nic-shell/src/utility/axi_interconnect_to_sys_mem.sv" \
"../../shell/plugs/rdma_onic_plugin/reconic_address_map.sv" \
"../../shell/top/reconic.sv" \
"../../shell/plugs/rdma_onic_plugin/box_250mhz.sv" \
"../../shell/plugs/rdma_onic_plugin/rdma_onic_plugin.sv" \

xvlog $xvlog_opts -work reco -L rocev2_ip --include "../build/ip/rocev2_ip/hdl/verilog" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_append_payload_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_Block_split49_proc.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_conn_table_0_s_conn_table_remote_ip_address_V_RAM_AUTO_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_conn_table_0_s_conn_table_remote_qpn_V_RAM_AUTO_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_conn_table_0_s_conn_table_remote_udp_port_V_RAM_AUTO_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_conn_table_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_convert_axis_to_net_axis_512_1.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_convert_axis_to_net_axis_512_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_convert_net_axis_to_axis_512_1.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_convert_net_axis_to_axis_512_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_drop_ooo_ibh_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_entry_proc.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_extract_icrc_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w1_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w2_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w3_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w4_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w16_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w16_d4_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w16_d2000_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w23_d4_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w24_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w32_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w32_d4_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w41_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w45_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w48_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w49_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w50_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w50_d32_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w56_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w64_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w64_d128_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w75_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w96_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w97_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w113_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w119_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w123_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w128_d3_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w128_d16_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w138_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w145_d4_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w145_d8_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w152_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w152_d512_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w153_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w178_d4_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w178_d512_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w192_d8_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w256_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w256_d8_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w256_d32_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w320_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w320_d8_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w384_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w384_d8_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w512_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w1024_d2_S.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w1024_d4_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w1024_d8_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_fifo_w1024_d64_A.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_freelist_handler_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_generate_exh_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_generate_ibh_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_generate_udp_512_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_handle_read_requests_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_hls_deadlock_detection_unit.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_hls_deadlock_idx0_monitor.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_hls_deadlock_idx8_monitor.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_insert_icrc_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_ipUdpMetaHandler_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_ipv4_drop_optional_ip_header_512_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_ipv4_generate_ipv4_512_3.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_ipv4_lshiftWordByOctet_512_2_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_local_req_handler_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_lshiftWordByOctet_512_11_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_lshiftWordByOctet_512_12_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_lshiftWordByOctet_512_13_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_mem_cmd_merger_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_merge_retrans_request.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_merge_rx_meta.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_merge_rx_pkgs_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_meta_merger_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_msn_table_0_s_msn_table_dma_length_V_RAM_2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_msn_table_0_s_msn_table_lst_V_RAM_2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_msn_table_0_s_msn_table_vaddr_V_RAM_2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_msn_table_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_prepend_ibh_header_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_process_ipv4_512_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_process_retransmissions_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_process_udp_512_4.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_qp_interface_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_regslice_both.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_meta_table_0_s_meta_table_localAddr_V_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_meta_table_0_s_meta_table_lst_V_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_meta_table_0_s_meta_table_next_V_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_meta_table_0_s_meta_table_offs_V_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_meta_table_0_s_meta_table_opCode_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_meta_table_0_s_meta_table_psn_V_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_meta_table_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_pointer_table_0_s_ptr_table_head_V_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_pointer_table_0_s_ptr_table_valid_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_retrans_pointer_table_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rshiftWordByOctet_net_axis_512_512_11_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rshiftWordByOctet_net_axis_512_512_12_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rshiftWordByOctet_net_axis_512_512_13_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rx_exh_fsm_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rx_exh_payload_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rx_ibh_fsm_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rx_process_exh_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_rx_process_ibh_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_split_tx_meta.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_state_table_0_s_state_table_req_old_unack_V_RAM_2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_state_table_0_s_state_table_retryCounter_V_RAM_2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_state_table_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_stream_merger_ackEvent_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_transport_timer_0_s_transportTimerTable_RAM_T2P_BRAM_1R1W.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_transport_timer_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_tx_ipUdpMetaMerger_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_tx_pkg_arbiter_512_0_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_udp_lshiftWordByOctet_512_1_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top_udp_rshiftWordByOctet_net_axis_512_512_2_s.v" \
"../build/ip/rocev2_ip/hdl/verilog/rocev2_top.v" \
"../build/ip/rocev2_ip/synth/rocev2_ip.v" \

#xvlog $xvlog_opts -work reco -L rocev2_ip "../build/ip/rocev2_ip/rocev2_ip_sim_netlist.v"

xvlog $xvlog_opts -work reco -L rocev2_ip --include "../build/ip/mac_ip_encode_ip/hdl/verilog" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_convert_axis_to_net_axis_512_s.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_convert_net_axis_to_axis_512_s.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_create_ethernet_header_512_s.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_entry_proc.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_fifo_w16_d16_S.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_fifo_w48_d6_S.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_fifo_w129_d2_S.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_fifo_w577_d2_S.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_fifo_w577_d32_A.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_fifo_w1024_d2_S.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_hls_deadlock_detection_unit.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_hls_deadlock_idx0_monitor.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_insert_ethernet_header_512_s.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_insert_ip_checksum_512_s.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_mac_compute_ipv4_checksum.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_mac_finalize_ipv4_checksum_32_s.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_mac_lshiftWordByOctet_512_1_s.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top_regslice_both.v" \
"../build/ip/mac_ip_encode_ip/hdl/verilog/mac_ip_encode_top.v" \
"../build/ip/mac_ip_encode_ip/synth/mac_ip_encode_ip.v" \

xvlog $xvlog_opts -work reco -L rocev2_ip --include "../build/ip/ip_handler_ip/hdl/verilog" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_convert_axis_to_net_axis_512_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_convert_net_axis_to_axis_512_1.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_convert_net_axis_to_axis_512_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_cut_length.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_detect_eth_protocol_512_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_detect_ipv4_protocol_512_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_entry_proc.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_extract_ip_meta_512_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w1_d4_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w1_d8_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w1_d32_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w8_d32_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w16_d2_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w32_d6_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w544_d2_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w577_d2_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w577_d64_A.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w1024_d2_S.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_fifo_w1024_d4_A.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_hls_deadlock_detection_unit.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_hls_deadlock_idx0_monitor.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_ip_handler_check_ipv4_checksum_32_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_ip_handler_compute_ipv4_checksum.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_ip_handler_rshiftWordByOctet_net_axis_512_512_1_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_ip_invalid_dropper_512_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_mux_646_64_1_1.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_regslice_both.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top_route_by_eth_protocol_512_s.v" \
"../build/ip/ip_handler_ip/hdl/verilog/ip_handler_top.v" \
"../build/ip/ip_handler_ip/synth/ip_handler_ip.v" \

#xvlog $xvlog_opts -work reco -L rocev2_ip "../build/ip/ip_handler_ip/ip_handler_ip_sim_netlist.v"

xvlog $xvlog_opts -work reco -L rocev2_ip \
"../build/ip/roce_stack_axi_datamover/roce_stack_axi_datamover_sim_netlist.v"

xvlog $xvlog_opts -work reco -L axis_interconnect_v1_1_19 -L fifo_generator_v13_2_6 \
"../build/ip/roce_stack_tx_axis_interconnect/roce_stack_tx_axis_interconnect_sim_netlist.v"

xvlog $xvlog_opts -work reco -sv -L rocev2_ip -L axis_interconnect_v1_1_19 \
"../../shell/roce_stack/rocev2_src/interfaces/roce_pkg.sv" \
"../../shell/roce_stack/rocev2_src/interfaces/lynx_intf.sv" \
"../../shell/roce_stack/rocev2_src/interfaces/axi_intf.sv" \
"../../shell/roce_stack/rocev2_src/buffer_fifo.sv" \
"../../shell/roce_stack/rocev2_src/fifo.sv" \
"../../shell/roce_stack/rocev2_src/icrc.sv" \
"../../shell/roce_stack/rocev2_src/queue_meta.sv" \
"../../shell/roce_stack/rocev2_src/rdma_flow.sv" \
"../../shell/roce_stack/rocev2_src/roce_stack.sv" \
"../../shell/roce_stack/rocev2_src/sp_ram_nc.sv" \
"../../shell/roce_stack/wrapper_src/roce_stack_request_handler.sv" \
"../../shell/roce_stack/wrapper_src/roce_stack_axis_to_aximm.sv" \
"../../shell/roce_stack/wrapper_src/roce_stack_csr.sv" \
"../../shell/roce_stack/wrapper_src/roce_stack_wq_manager.sv" \
"../../shell/roce_stack/wrapper_src/roce_stack_wrapper.sv" \


xvlog $xvlog_opts -sv -d DEBUG -L axi_bram_ctrl_v4_1_6 -L xpm -work reco \
"../src/axi_read_verify.sv" \
"../src/axil_reg_stimulus.sv" \
"../src/axil_reg_control.sv" \
"../src/axil_3to1_crossbar_wrapper.sv" \
"../src/init_mem.sv" \
"../src/rdma_rn_wrapper.sv" \
"../src/rdma_rn_roce_wrapper.sv" \
"../src/rn_tb_pkg.sv" \
"../src/rn_tb_generator.sv" \
"../src/rn_tb_driver.sv" \
"../src/rn_tb_checker.sv" \
"../src/rn_tb_top.sv" \
"../src/cl_tb_top.sv" \
"../src/rn_tb_2rdma_top.sv" \
"../src/rn_tb_2rdma_roce_top.sv" \
"../src/axi_3to1_interconnect_to_dev_mem.sv" \
"../src/axi_5to2_interconnect_to_sys_mem.sv" \

xvlog $xvlog_opts -work reco -sv -L fifo_generator_v13_2_6 \
"../build/ip/dev_mem_3to1_axi_crossbar/synth/dev_mem_3to1_axi_crossbar.v"

xvlog $xvlog_opts -work reco -sv -L fifo_generator_v13_2_6 \
"../build/ip/sys_mem_5to2_axi_crossbar/synth/sys_mem_5to2_axi_crossbar.v"

xvlog $xvlog_opts -work reco -L fifo_generator_v13_2_6 \
"../build/ip/reg_cmd_cdc_fifo/sim/reg_cmd_cdc_fifo.v"


xvlog $xvlog_opts -work reco \
"../build/ip/block_ram_1k/block_ram_1k_sim_netlist.v"

xvlog $xvlog_opts -work reco \
"$VIVADO_DATA_DIR/verilog/src/glbl.v"