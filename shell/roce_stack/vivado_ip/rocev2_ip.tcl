set_property  ip_repo_paths  ../src/roce_stack/build/hls/rocev2/rocev2_prj [current_project]
update_ip_catalog

create_ip -name rocev2 -vendor ethz.systems.fpga -library hls -version 0.82 -module_name rocev2_ip -dir ${ip_build_dir} 