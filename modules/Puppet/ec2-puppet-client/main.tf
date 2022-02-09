resource "aws_instance" "mis_vms" {
  ami                         = var.win_server_ami[var.region] #var.imagen_OS 
  instance_type               = var.tipo_instancia
  availability_zone           = var.AZs[0]
  # subnet_id                   = var.los_IDs_subredes[0]
  user_data                   = data.template_file.userdata_linux_ubuntu.rendered
  key_name                    = var.llave_ssh
  tags                        = { Name = "srv-${var.server_role}" }

  network_interface {
    network_interface_id = "${aws_network_interface.mi_nic.id}"
    device_index = 0
  }
}

resource "aws_network_interface" "mi_nic" {
  subnet_id = var.los_IDs_subredes[0]
  private_ips = [var.ip_nodos_client[0]]
  security_groups = [var.los_SG]
}

data "template_file" "userdata_linux_ubuntu" {
  template = <<-EOT
                #!/bin/bash
                INICIO=$(date "+%F %H:%M:%S")
                echo "Hora de inicio del script: $INICIO" > /home/ubuntu/a_${var.server_role}.txt

                sudo timedatectl set-timezone Europe/Paris

                hostnamectl set-hostname ${var.server_role}
                echo "ubuntu:${var.contrasena_user}" | chpasswd

                #Agregar otro usuario para que administre Ansible
                usuario=${var.usuario_ansible}
                sudo useradd -U $usuario -m -s /bin/bash -p $usuario -G sudo
                echo "$usuario:${var.contrasena_user}" | chpasswd

                #Evitar que pida el password a cada rato para usuarios que sean parte del grupo sudo
                sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'
                sed -i /etc/sudoers -re 's/^#includedir.*/## Removed the #include directive! ##"/g'

                #Agregar a los archivos sudoers este nuevo usuario
                echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
                echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users

                sudo ufw disable
                sudo apt update -y && sudo apt upgrade -y && sudo apt install tree -y

                sudo bash -c 'echo "${var.ip_nodos_master[0]} puppetmaster puppet" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_nodos_client[0]} puppetclient" >> /etc/hosts'

                sudo bash -c 'echo "${var.ip_server_docker} docker" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_tomcat} tomcat" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_jenkins_master} jenkinsmaster" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_jenkins_slave} jenkinsslave" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_k8s_master} k8master" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_k8s_worker_1} k8worker1" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_k8s_worker_2} k8worker2" >> /etc/hosts'

                wget https://apt.puppetlabs.com/puppet7-release-focal.deb
                sudo dpkg -i puppet7-release-focal.deb
                sudo apt update -y
                sudo apt install puppet-agent -y

                sudo bash -c 'echo "[main]" >> /etc/puppetlabs/puppet/puppet.conf'
                sudo bash -c 'echo "certname = puppetclient" >> /etc/puppetlabs/puppet/puppet.conf'
                sudo bash -c 'echo "server = puppetmaster" >> /etc/puppetlabs/puppet/puppet.conf'

                sudo systemctl start puppet
                sudo systemctl enable puppet

                sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
                sudo service sshd restart

                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}