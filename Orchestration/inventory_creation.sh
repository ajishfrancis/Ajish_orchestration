#!/bin/sh
mkdir /home/Orchestration/inventory/
input="/home/Orchestration/dpc_change_wavesheet.csv"
while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29 f30 f31 f32 f33 f34 f35 f36 f37 f38 f39 f40 f41 f42
do
 if [[ $f1 == "windows" ]]
 then
   echo " $f2 vmname=$f2 ansible_host=$f3 ansible_ssh_user=$f4 ansible_ssh_pass=$f5 ansible_ssh_port=$f6 ansible_connection=$f7 host_key_checking=$f8 ansible_winrm_server_cert_validation=$f9 ansible_winrm_transport=$f10 disksize_required=$f11 timezone_required=$f12 vcenter_hostname=$f16 vcenter_username=$f17 vcenter_password=$f18 vmstate=$f19 vmstate_off=$f20 vmstate_on=$f21 datacenter=$f22 hotcpu_required=$f23 memory_mb=$f24 num_cpus=$f25 hotadd_cpu=$f26 hotadd_memory=$f27 change_hw_version=$f28 version_required=$f29 remove_cdroms=$f30 win_admin_username=$f31 win_admin_password=$f32 pagefile_initial_size=$f33 pagefile_maximum_size=$f34 mcafee_product_id=$f35 adapter_name=$f36 dns_suffix_name=$f37" >> /home/Orchestration/inventory/windows.yml
 elif [[ $f1 == "linux" ]]
 then
   echo " $f2 vmname=$f2 ansible_host=$f3 ansible_ssh_user=$f4 ansible_ssh_pass=$f5 ansible_ssh_port=$f6 ansible_connection=$f7 host_key_checking=$f8 disksize_required=$f11 timezone_required=$f12 Host_file_path=$f13 Old_IP_FQDN=$f14 New_IP_FQDN=$f15 vcenter_hostname=$f16 vcenter_username=$f17 vcenter_password=$f18 vmstate=$f19 vmstate_off=$f20 vmstate_on=$f21 datacenter=$f22 hotcpu_required=$f23 memory_mb=$f24 num_cpus=$f25 hotadd_cpu=$f26 hotadd_memory=$f27  change_hw_version=$f28 version_required=$f29 remove_cdroms=$f30" >> /home/Orchestration/inventory/linux.yml
 else
 echo "Inventory creation from csv to yaml"
 fi

done < "$input"


