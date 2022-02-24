resource "aws_instance" "mis_vms" {
  ami                         = var.server_ami[var.region] #var.imagen_OS 
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
                sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'
                sed -i /etc/sudoers -re 's/^#includedir.*/## Removed the #include directive! ##"/g'


                echo "alias c='sudo cat'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias md='sudo mkdir'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias nt='sudo netstat -tulpn'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias hs='history'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias hm='cd ~'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias l='ls -la'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias sy='sudo systemctl status'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias sy1='sudo systemctl start'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias sy2='sudo systemctl stop'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias syr='sudo systemctl restart'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias pw='sudo cat /etc/passwd'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias sd='sudo cat /etc/sudoers'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias sd2='sudo cat /etc/sudoers.d/90-cloud-init-users'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias fw='sudo ufw status'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias ai='sudo apt install'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias up1='sudo apt update -y'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias up2='sudo apt update -y && sudo apt upgrade -y'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias sshd='sudo cat /etc/ssh/sshd_config'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias sshda='sudo cat /etc/ssh/sshd_config | grep Authentication'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias vmmc='sudo sysctl vm.max_map_count'" | sudo tee -a /home/ubuntu/.bashrc
                echo "alias ffm='sudo sysctl fs.file-max'" | sudo tee -a /home/ubuntu/.bashrc


                #Agregar otro usuario para que administre Ansible
                usuario=${var.usuario_ansible}
                sudo useradd -U $usuario -m -s /bin/bash -p $usuario -G sudo
                echo "$usuario:${var.contrasena_user}" | sudo chpasswd
                sudo bash -c 'echo "${var.usuario_ansible} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
                sudo bash -c 'echo "${var.usuario_ansible} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users'


                sudo ufw disable
                sudo apt update -y && sudo apt upgrade -y
                sudo apt install tree tldr net-tools -y
                sudo apt install wget unzip -y

                # -----------------------------------------------------------------------------
                # sudo sysctl -w vm.max_map_count=524288
                # sudo sysctl -w fs.file-max=131072
                # ulimit -n 131072
                # ulimit -u 8192

                # sudo bash -c 'echo "sysctl -w vm.max_map_count=524288" >> /etc/sysctl.conf'
                # sudo bash -c 'echo "sysctl -w fs.file-max=131072" >> /etc/sysctl.conf'
                # sudo bash -c 'echo "ulimit -n 131072" >> /etc/sysctl.conf'
                # sudo bash -c 'echo "ulimit -u 8192" >> /etc/sysctl.conf'

                # sudo bash -c 'echo "${var.usuario_admin}   -   nofile   131072" >> /etc/security/limits.conf'
                # sudo bash -c 'echo "${var.usuario_admin}   -   nproc    8192" >> /etc/security/limits.conf'

                # echo "export SONARQUBE_HOME=/opt/sonarqube" | sudo tee -a /etc/profile
                # echo "export SONAR_HOME=/opt/sonarqube" | sudo tee -a /etc/profile
                # echo "export HSO=/opt/sonarqube" | sudo tee -a /etc/profile

                # echo 'export JENKINS_HOME=/var/lib/jenkins' > /etc/profile.d/maven.sh
                # echo 'export JAVA_HOME=/usr/lib/jvm/default-java' >> /etc/profile.d/maven.sh
                # echo 'export M2_HOME=/opt/maven' >> /etc/profile.d/maven.sh
                # echo 'export MAVEN_HOME=/opt/maven' >> /etc/profile.d/maven.sh
                # echo 'export PATH=/opt/maven/bin:$PATH' >> /etc/profile.d/maven.sh
                # source /etc/profile.d/maven.sh

                # sudo cat <<EOF | sudo tee -a /xxx/yyy/zzz.txt
                # lorem ipsum
                # EOF
                # -----------------------------------------------------------------------------



                sudo apt update -y && sudo apt upgrade -y

                

                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}

