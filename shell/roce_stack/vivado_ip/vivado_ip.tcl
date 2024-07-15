set_property  ip_repo_paths  ${root_dir}/shell/roce_stack/build/hls/mac_ip_encode/mac_ip_encode_prj [current_project]
set_property  ip_repo_paths  ${root_dir}/shell/roce_stack/build/hls/ip_handler/ip_handler_prj [current_project]
set_property  ip_repo_paths  ${root_dir}/shell/roce_stack/build/hls/rocev2/rocev2_prj [current_project]
update_ip_catalog

set ips {
  rocev2_ip
  mac_ip_encode_ip
  ip_handler_ip
  roce_stack_axi_datamover
  roce_stack_tx_axis_interconnect
  cdc_fifo_sq
}