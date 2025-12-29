#jinja2: trim_blocks:False
[ec2_instances_${env}]
%{~ for ip in ec2_ips ~}
${ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_ed25519
%{~ endfor ~}
