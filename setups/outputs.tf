# output "El_ID_VPC" { value = aws_vpc.mi_red.id }
# output "Router_Nuevo_ID_VPC" { value = aws_vpc.mi_red.main_route_table_id }
# output "Los_IDs_subredes" { value = module.subredes_publicas.IDs_subredes }

output "Ip_privada_Master_Jenkins" { value = module.vm_jenkins_master.mis_ip_privadas }
output "Ip_PUBLICA_Master_Jenkins" { value = module.vm_jenkins_master.mis_ip_publicas }

# output "Ip_privada_Slave_Jenkins" { value = module.vm_jenkins_slave.mis_ip_privadas }
# output "Ip_PUBLICA_Slave_Jenkins" { value = module.vm_jenkins_slave.mis_ip_publicas }

# output "Ip_privada_Server_Maven" { value = module.vm_maven.mis_ip_privadas }
# output "Ip_PUBLICA_Server_Maven" { value = module.vm_maven.mis_ip_publicas }

# output "Ip_privada_Server_Tomcat" { value = module.vm_tomcat.mis_ip_privadas }
# output "Ip_PUBLICA_Server_Tomcat" { value = module.vm_tomcat.mis_ip_publicas }

output "Ip_privada_Server_Ansible" { value = module.vm_ansible.mis_ip_privadas }
output "Ip_PUBLICA_Server_Ansible" { value = module.vm_ansible.mis_ip_publicas }

output "Ip_privada_Server_Docker" { value = module.vm_docker.mis_ip_privadas }
output "Ip_PUBLICA_Server_Docker" { value = module.vm_docker.mis_ip_publicas }

# output "Ip_privada_PUPPET_MASTER" { value = module.vm_puppet_master.mis_ip_privadas }
# output "Ip_PUBLICA_PUPPET_MASTER" { value = module.vm_puppet_master.mis_ip_publicas }

# output "Ip_privada_PUPPET_Client" { value = module.vm_puppet_client.mis_ip_privadas }
# output "Ip_PUBLICA_PUPPET_Client" { value = module.vm_puppet_client.mis_ip_publicas }

# output "Ip_privada_K8s_MASTER" { value = module.vm_k8_master.mis_ip_privadas }
# output "Ip_PUBLICA_K8s_MASTER" { value = module.vm_k8_master.mis_ip_publicas }

# output "Ip_privada_K8s_Worker_1" { value = module.vm_k8_worker_1.mis_ip_privadas }
# output "Ip_PUBLICA_K8s_Worker_1" { value = module.vm_k8_worker_1.mis_ip_publicas }

# output "Ip_privada_K8s_Worker_2" { value = module.vm_k8_worker_2.mis_ip_privadas }
# output "Ip_PUBLICA_K8s_Worker_2" { value = module.vm_k8_worker_2.mis_ip_publicas }