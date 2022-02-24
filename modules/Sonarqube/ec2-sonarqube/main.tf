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


                sudo sysctl -w vm.max_map_count=524288
                sudo sysctl -w fs.file-max=131072
                ulimit -n 131072
                ulimit -u 8192

                sudo bash -c 'echo "sysctl -w vm.max_map_count=524288" >> /etc/sysctl.conf'
                sudo bash -c 'echo "sysctl -w fs.file-max=131072" >> /etc/sysctl.conf'
                sudo bash -c 'echo "ulimit -n 131072" >> /etc/sysctl.conf'
                sudo bash -c 'echo "ulimit -u 8192" >> /etc/sysctl.conf'

                sudo bash -c 'echo "${var.usuario_sonarqb}   -   nofile   131072" >> /etc/security/limits.conf'
                sudo bash -c 'echo "${var.usuario_sonarqb}   -   nproc    8192" >> /etc/security/limits.conf'

                sudo apt update -y && sudo apt upgrade -y

                sudo apt install wget unzip -y
                sudo apt install openjdk-11-jdk -y
                #sudo apt install openjdk-11-jre -y

                sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
                wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
                sudo apt update -y
                sudo apt install postgresql -y

                echo "postgres:${var.contrasena_user}" | sudo chpasswd
                sudo bash -c 'echo "postgres ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
                sudo bash -c 'echo "postgres ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users'

                sudo systemctl start postgresql
                sudo systemctl enable postgresql

                # sudo su postgres
                # createuser ${var.postgres_sonar_user}
                # psql
                # ALTER USER sonar WITH ENCRYPTED password '${var.postgres_sonar_pw}';
                # CREATE DATABASE ${var.postgres_db_name} OWNER ${var.postgres_sonar_user};
                # grant all privileges on DATABASE ${var.postgres_db_name} to ${var.postgres_sonar_user};
                # \q
                # exit
                # sudo systemctl restart postgresql

                cd /tmp
                sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.7.52159.zip
                sudo unzip sonarqube-8.9.7.52159.zip -d /opt

                sudo mv /opt/sonarqube-8.9.7.52159 /opt/sonarqube

                sudo groupadd sonar
                usuario=${var.usuario_sonarqb}
                sudo bash -c 'echo "${var.usuario_sonarqb} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
                sudo bash -c 'echo "${var.usuario_sonarqb} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users'
                sudo useradd -c "usuario para SonarQube" -d /opt/sonarqube -g sonar ${var.usuario_sonarqb}
                sudo chown -R ${var.usuario_sonarqb}:sonar /opt/sonarqube
                echo "${var.usuario_sonarqb}:123" | sudo chpasswd
                

                sudo sed -i 's/#sonar.jdbc.username=/sonar.jdbc.username=${var.postgres_sonar_user}/g' /opt/sonarqube/conf/sonar.properties
                sudo sed -i 's/#sonar.jdbc.password=/sonar.jdbc.password=${var.postgres_sonar_pw}/g' /opt/sonarqube/conf/sonar.properties
                sudo sed -i 's/#sonar.jdbc.url=jdbc:postgresql:\/\/localhost\/sonarqube?currentSchema=my_schema/sonar.jdbc.url=jdbc:postgresql:\/\/localhost\/${var.postgres_db_name}/g' /opt/sonarqube/conf/sonar.properties
                sudo sed -i 's/#sonar.web.port=9000/sonar.web.port=9000/g' /opt/sonarqube/conf/sonar.properties
                sudo sed -i 's/#sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError/sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError/g' /opt/sonarqube/conf/sonar.properties

                sudo sed -i 's/#RUN_AS_USER=/RUN_AS_USER=${var.usuario_sonarqb}/g' /opt/sonarqube/bin/linux-x86-64/sonar.sh

                sudo mkdir -p /var/sonarqube/data
                sudo mkdir -p /var/sonarqube/temp
                sudo chown -R ${var.usuario_sonarqb}:sonar /var/sonarqube/data
                sudo chown -R ${var.usuario_sonarqb}:sonar /var/sonarqube/temp

                sudo sed -i 's/#sonar.path.data=data/sonar.path.data=\/var\/sonarqube\/data/g' /opt/sonarqube/conf/sonar.properties
                sudo sed -i 's/#sonar.path.temp=temp/sonar.path.temp=\/var\/sonarqube\/temp/g' /opt/sonarqube/conf/sonar.properties
                
                echo "export SONARQUBE_HOME=/opt/sonarqube" | sudo tee -a /etc/profile
                echo "export SONAR_HOME=/opt/sonarqube" | sudo tee -a /etc/profile
                echo "export HSO=/opt/sonarqube" | sudo tee -a /etc/profile

                sudo cat <<EOF | sudo tee /etc/systemd/system/sonar.service
                [Unit]
                Description=SonarQube service
                After=syslog.target network.target

                [Service]
                Type=forking
                User=${var.usuario_sonarqb}
                Group=sonar
                PermissionsStartOnly=true
                ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start 
                ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
                StandardOutput=syslog
                LimitNOFILE=131072
                LimitNPROC=8192
                TimeoutStartSec=5
                Restart=always

                [Install]
                WantedBy=multi-user.target
                EOF

                #OJO HAY QUE crear la BD primero y luego iniciar el servicio               
                # sudo su postgres
                # createuser sonar
                # psql
                # ALTER USER sonar WITH ENCRYPTED password '123';
                # CREATE DATABASE sonarqube OWNER sonar;
                # grant all privileges on DATABASE sonarqube to sonar;
                # \q
                # exit
                # sudo systemctl restart postgresql
                # sudo /opt/sonarqube/bin/linux-x86-64/sonar.sh start

				#POSIBLES PROBLEMAS TIPICOS
				#No haber configurado bien lo de abajo, ejemplo cuando se reinicia la maquina se pierde esa config
				#sudo sysctl -w vm.max_map_count=524288
                #sudo sysctl -w fs.file-max=131072
                #ulimit -n 131072
                #ulimit -u 8192
				#Hacer troubleshooting viendo los logs en /opt/sonarqube/logs/sonar.FECHAHOY.log

                #ESTO DE ABAJO NO ME FUNCIONO - NO CORRER
                # sudo systemctl start sonar
                # sudo systemctl enable sonar

                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}

