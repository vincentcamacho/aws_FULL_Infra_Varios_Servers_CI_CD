resource "aws_instance" "mis_vms" {
  ami                         = var.win_server_ami[var.region] #var.imagen_OS 
  instance_type               = var.tipo_instancia
  availability_zone           = var.AZs[0]
  # subnet_id                   = var.los_IDs_subredes[count.index]
  user_data                   = data.template_file.userdata_linux_ubuntu.rendered
  key_name                    = var.llave_ssh
  tags                        = { Name = "srv-${var.server_role}-${var.proyecto}" }

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

                #Agregar un usuario de Ansible que permitira instalar cosas aca
                usuario=ansibleadmin
                sudo useradd -U $usuario -m -s /bin/bash -p $usuario -G sudo
                echo "$usuario:123" | chpasswd

                sudo ufw disable
                sudo apt update -y && sudo apt upgrade -y && sudo apt install tree -y

                sudo bash -c 'echo "${var.ip_server_docker} docker" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_tomcat} tomcat" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_ansible} ansible" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_jenkins_slave} jenkinsslave" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_k8s_master} k8master" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_k8s_worker_1} k8worker1" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_k8s_worker_2} k8worker2" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_puppet_master} puppetmaster" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_puppet_client} puppetclient" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_server_maven} maven" >> /etc/hosts'

                #Install OpenJDK - Maven 3.3+ requires JDK 1.7 or above to be installed.
                sudo apt install default-jdk git -y

                #Download latest Apache Maven version (04/02/2022 today is 3.8.4). Before continuing with the next step, visit the Maven download page to check latest version
                sudo wget -P /tmp https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz

                #Once the download is completed, extract the archive in the /opt directory:
                sudo tar -xf /tmp/apache-maven-3.8.4-bin.tar.gz -C /opt

                #To have more control over Maven versions and updates, we will create a symbolic link maven that will point to the Maven installation directory:
                sudo ln -s /opt/apache-maven-3.8.4 /opt/maven

                echo 'export JENKINS_HOME=/var/lib/jenkins' > /etc/profile.d/maven.sh
                echo 'export JAVA_HOME=/usr/lib/jvm/default-java' >> /etc/profile.d/maven.sh
                echo 'export M2_HOME=/opt/maven' >> /etc/profile.d/maven.sh
                echo 'export MAVEN_HOME=/opt/maven' >> /etc/profile.d/maven.sh
                echo 'export PATH=/opt/maven/bin:$PATH' >> /etc/profile.d/maven.sh
                source /etc/profile.d/maven.sh

                echo "export JENKINS_HOME=/var/lib/jenkins" | sudo tee -a /etc/profile
                echo "export JAVA_HOME=/usr/lib/jvm/default-java" | sudo tee -a /etc/profile
                echo "export MAVEN_HOME=/opt/maven" | sudo tee -a /etc/profile
                echo "export GIT_HOME=/usr/bin/git" | sudo tee -a /etc/profile

                # wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
                # sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
                
                curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
                echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
                sudo apt update -y
                # sudo apt install jenkins -y
                # sudo systemctl start jenkins
                # chmod +r /var/lib/jenkins/secrets/initialAdminPassword
                # sudo cp /var/lib/jenkins/secrets/initialAdminPassword /home/ubuntu
                
                sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
                sudo service sshd restart

                echo "El rol de este servidor Jenkins es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt
              EOT
}

