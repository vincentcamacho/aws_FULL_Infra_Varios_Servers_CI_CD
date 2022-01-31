module "subredes_publicas" {
  source               = "../modules/__GLOBAL_CONFIG__/Subnets"
  el_id_de_la_VPC      = aws_vpc.mi_red.id
  tipo_subred          = "public"
  proyecto             = var.NOMBRE_PROYECTO
  los_az               = var.AV_ZONES
  cantidad_subredes    = var.NRO_DE_SUBREDES
  rangos_cidr_subredes = var.CIDR_PUBLICOS_SUBRED
  asigna_ip_publica    = true
}

module "vm_jenkins_master" {
  source           = "../modules/Jenkins/ec2-jenkins-slave"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  server_role      = "jenkinsmaster"
  usuario_ansible  = "ansibleadmin"
  contrasena_user  = "123"
  proyecto         = var.NOMBRE_PROYECTO
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_fija_privada  = var.ip_jenkins_master
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_MEDIANA
}

module "vm_jenkins_slave" {
  source           = "../modules/Jenkins/ec2-jenkins-master"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  server_role      = "jenkinsslave"
  usuario_ansible  = "ansibleadmin"
  contrasena_user  = "123"
  proyecto         = var.NOMBRE_PROYECTO
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_fija_privada  = var.ip_jenkins_slave
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_PEQUENA
}

module "vm_tomcat" {
  source           = "../modules/Tomcat_Server/ec2-tomcat"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  server_role      = "tomcat"
  usuario_ansible  = "ansibleadmin"
  contrasena_user  = "123"
  proyecto         = var.NOMBRE_PROYECTO
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_fija_privada  = var.ip_tomcat
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_MICRO
}

module "vm_ansible" {
  source           = "../modules/Ansible/ec2-ansible"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  server_role      = "ansible"
  usuario_ansible  = "ansibleadmin"
  contrasena_user  = "123"
  proyecto         = var.NOMBRE_PROYECTO
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_fija_privada  = var.ip_ansible
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_MEDIANA

  ip_server_docker         = var.ip_docker
  ip_server_tomcat         = var.ip_tomcat
  ip_server_jenkins_master = var.ip_jenkins_master
  ip_server_jenkins_slave  = var.ip_jenkins_slave
  ip_server_k8s_master     = var.ip_k8_master
  ip_server_k8s_worker_1   = var.ip_k8_worker_1
  ip_server_k8s_worker_2   = var.ip_k8_worker_2
  ip_server_puppet_master  = var.ip_puppet_master
  ip_server_puppet_client  = var.ip_puppet_client
}

module "vm_docker" {
  source           = "../modules/Docker/ec2-docker"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  server_role      = "docker"
  usuario_ansible  = "ansibleadmin"
  usuario_docker   = "dockeradmin"
  contrasena_user  = "123"
  proyecto         = var.NOMBRE_PROYECTO
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_fija_privada  = var.ip_docker
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_MEDIANA
}


module "vm_puppet_master" {
  source           = "../modules/Puppet/ec2-puppet-master"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  server_role      = "puppetmaster"
  usuario_ansible  = "ansibleadmin"
  contrasena_user  = "123"
  proyecto         = var.NOMBRE_PROYECTO
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_nodos_master  = [var.ip_puppet_master]
  ip_nodos_client  = [var.ip_puppet_client]
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_MEDIANA
}

module "vm_puppet_client" {
  source           = "../modules/Puppet/ec2-puppet-client"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  proyecto         = var.NOMBRE_PROYECTO
  server_role      = "puppetclient"
  usuario_ansible  = "ansibleadmin"
  contrasena_user  = "123"
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_nodos_master  = [var.ip_puppet_master]
  ip_nodos_client  = [var.ip_puppet_client]
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_PEQUENA
}

module "vm_k8_master" {
  source           = "../modules/Kubernetes/ec2-k8-master"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  proyecto         = var.NOMBRE_PROYECTO
  server_role      = "k8master"
  usuario_ansible  = "ansibleadmin"
  usuario_docker   = "dockeradmin"
  contrasena_user  = "123"
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_nodos_master  = [var.ip_k8_master]
  ip_nodos_worker  = [var.ip_k8_worker_1, var.ip_k8_worker_2]
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_GRANDE
}

module "vm_k8_worker_1" {
  source           = "../modules/Kubernetes/ec2-k8-worker-1"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  proyecto         = var.NOMBRE_PROYECTO
  server_role      = "k8worker1"
  usuario_ansible  = "ansibleadmin"
  usuario_docker   = "dockeradmin"
  contrasena_user  = "123"
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_nodos_master  = [var.ip_k8_master]
  ip_nodos_worker  = [var.ip_k8_worker_1, var.ip_k8_worker_2]
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_MEDIANA
}

module "vm_k8_worker_2" {
  source           = "../modules/Kubernetes/ec2-k8-worker-2"
  llave_ssh        = aws_key_pair.mi_ssh_key.key_name
  proyecto         = var.NOMBRE_PROYECTO
  server_role      = "k8worker2"
  usuario_ansible  = "ansibleadmin"
  usuario_docker   = "dockeradmin"
  contrasena_user  = "123"
  los_IDs_subredes = module.subredes_publicas.IDs_subredes
  ip_nodos_master  = [var.ip_k8_master]
  ip_nodos_worker  = [var.ip_k8_worker_1, var.ip_k8_worker_2]
  los_SG           = aws_security_group.mi_sec_group.id
  AZs              = var.AV_ZONES
  win_server_ami   = var.UBUNTU_AMI
  region           = var.REGION
  tipo_instancia   = var.TIPO_MEDIANA
}