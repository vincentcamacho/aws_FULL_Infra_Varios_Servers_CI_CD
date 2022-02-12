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


                sudo sysctl -w vm.max_map_count=262144
                sudo sysctl -w fs.file-max=65536
                ulimit -n 65536Copy
                ulimit -u 4096

                sudo bash -c 'echo "sonarqube   -   nofile   65536" >> /etc/security/limits.conf'
                sudo bash -c 'echo "sonarqube   -   nproc    4096" >> /etc/security/limits.conf'

                sudo apt update -y && sudo apt upgrade -y

                sudo apt install wget unzip -y
                sudo apt install openjdk-11-jdk -y
                sudo apt install openjdk-11-jre -y

                sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'

                wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

                sudo apt install postgresql postgresql-contrib -y

                sudo systemctl start postgresql
                sudo systemctl enable postgresql
                echo "postgres:${var.contrasena_user}" | sudo chpasswd

                cd /tmp
                sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.7.52159.zip
                sudo unzip sonarqube-8.9.7.52159.zip -d /opt

                sudo mv /opt/sonarqube-8.9.7.52159 /opt/sonarqube

                sudo groupadd sonar
                usuario=${var.usuario_sonarqb}
                echo "${var.usuario_sonarqb} ALL=(ALL) NOPASSWD: ALL" >> sudo /etc/sudoers
                echo "${var.usuario_sonarqb} ALL=(ALL) NOPASSWD: ALL" >> sudo /etc/sudoers.d/90-cloud-init-users
                sudo useradd -c "usuario para SonarQube" -d /opt/sonarqube -g sonar ${var.usuario_sonarqb}
                sudo chown $usuario:sonar /opt/sonarqube -R
                echo "${var.usuario_sonarqb}:123" | sudo chpasswd
                

                sudo sed -i 's/#sonar.jdbc.username=/sonar.jdbc.username=${var.usuario_sonarqb}/g' /opt/sonarqube/conf/sonar.properties
                sudo sed -i 's/#sonar.jdbc.password=/sonar.jdbc.password=${var.contrasena_user}/g' /opt/sonarqube/conf/sonar.properties
                sudo sed -i 's/#sonar.jdbc.url=jdbc:postgresql:\/\/localhost\/sonarqube?currentSchema=my_schema/sonar.jdbc.url=jdbc:postgresql:\/\/localhost:5432\/sonarqube/g' /opt/sonarqube/conf/sonar.properties

                sudo sed -i 's/#RUN_AS_USER=/RUN_AS_USER=${var.usuario_sonarqb}/g' /opt/sonarqube/bin/linux-x86-64/sonar.sh



                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}

