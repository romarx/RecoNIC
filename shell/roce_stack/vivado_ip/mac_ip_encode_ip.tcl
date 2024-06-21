set_property  ip_repo_paths  ${root_dir}/shell/roce_stack/build/hls/mac_ip_encode/mac_ip_encode_prj [current_project]
update_ip_catalog
create_ip -name mac_ip_encode -vendor ethz.systems.fpga -library hls -version 2.0 -module_name mac_ip_encode_ip -dir ${ip_build_dir} 