resource "aws_instance" "mis_vms" {
  ami                         = var.win_server_ami[var.region] #var.imagen_OS 
  instance_type               = var.tipo_instancia
  availability_zone           = var.AZs[0]
  # subnet_id                   = var.los_IDs_subredes[count.index]
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
  private_ips = [var.ip_fija_privada]
  security_groups = [var.los_SG]
}

data "template_file" "userdata_linux_ubuntu" {
  template = <<-EOT
                #!/bin/bash
                INICIO=$(date "+%F %H:%M:%S")
                echo "Hora de inicio del script: $INICIO" > /home/ubuntu/a_${var.server_role}.txt

                sudo timedatectl set-timezone Europe/Paris

                sudo hostnamectl set-hostname ${var.server_role}
                echo "ubuntu:${var.contrasena_user}" | chpasswd

                sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
                sudo service sshd restart

                #Evitar que pida el password a cada rato para usuarios que sean parte del grupo sudo
                sudo sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'
                sudo sed -i /etc/sudoers -re 's/^#includedir.*/## Removed the #include directive! ##"/g'

                #Agregar otro usuario para que administre Ansible
                usuario=${var.usuario_ansible}
                sudo useradd -U ${var.usuario_ansible} -m -s /bin/bash -p $usuario -G sudo
                echo "$usuario:${var.contrasena_user}" | sudo chpasswd
                sudo bash -c 'echo "${var.usuario_ansible} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
                sudo bash -c 'echo "${var.usuario_ansible} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users'

                #Agregar otro usuario para que administre Ansible
                usuario=${var.usuario_artifact}
                sudo useradd -U ${var.usuario_artifact} -m -s /bin/bash -p $usuario -G sudo
                echo "${var.usuario_artifact}:${var.contrasena_user}" | sudo chpasswd
                sudo bash -c 'echo "${var.usuario_artifact} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
                sudo bash -c 'echo "${var.usuario_artifact} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users'

                sudo ufw disable
                sudo apt update -y && sudo apt upgrade -y && sudo apt install tree -y


                sudo apt install wget -y
                sudo apt install default-jdk git -y

                cd /opt/
                sudo wget https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/7.31.13/jfrog-artifactory-oss-7.31.13-linux.tar.gz
                sudo tar -xvf jfrog-artifactory-oss-7.31.13-linux.tar.gz
                sudo mv /opt/artifactory-oss-7.31.13 /opt/artifactory


                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}

