set_property  ip_repo_paths  ../src/roce_stack/build/hls/ip_handler/ip_handler_prj [current_project]
update_ip_catalog

create_ip -name ip_handler -vendor ethz.systems.fpga -library hls -version 2.0 -module_name ip_handler_ip -dir ${ip_build_dir} 