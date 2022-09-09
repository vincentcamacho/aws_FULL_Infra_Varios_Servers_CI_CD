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

                hostnamectl set-hostname ${var.server_role}
                echo "ubuntu:${var.contrasena_user}" | chpasswd

                sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
                sudo service sshd restart

                #Agregar otro usuario para que administre ANSIBLE
                usuario=${var.usuario_ansible}
                sudo useradd -U $usuario -m -s /bin/bash -p $usuario -G sudo
                echo "$usuario:${var.contrasena_user}" | chpasswd

                #Agregar a sudoers al usuario de ANSIBLE
                echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
                echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users

                #Evitar que pida el password a cada rato para usuarios que sean parte del grupo sudo
                sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'
                sed -i /etc/sudoers -re 's/^#includedir.*/## Removed the #include directive! ##"/g'

                sudo ufw disable
                sudo apt update -y && sudo apt upgrade -y && sudo apt install tree -y

                #Install Docker
                sudo apt-get update
                # sudo apt-get upgrade -y
                sudo apt-get remove -y docker docker-engine docker.io containerd runc
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                sudo usermod -aG docker $USER
                sudo systemctl start docker
                # sudo su $USER
                docker run -d --name neoweb -p 8080:80  nginxdemos/hello

                #Agregar usuario para que administre DOCKER
                usuario=${var.usuario_docker}
                sudo useradd -U $usuario -m -s /bin/bash -p $usuario
                sudo usermod -aG docker $usuario
                echo "$usuario:${var.contrasena_user}" | chpasswd

                #Agregar a los archivos sudoers este nuevo usuario
                echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
                echo "$usuario ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users

                #APROVECHEMOS para tambien agregar al usuario ANSIBLE al grupo Docker
                sudo usermod -aG docker ${var.usuario_ansible}

                #Crear alias SUPER UTILES para el usuario nuevo creado
                echo "alias d='docker'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias dp='docker ps'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias dpa='docker ps -a'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias di='docker images'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias ds='docker stop'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias drm='docker rm -f'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias dka='docker rm \$(docker stop \$(docker ps -aq))'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias drd='docker run -d'" | sudo tee -a /home/$usuario/.bashrc
                echo "alias dki='docker rmi -f \$(docker images -aq)'" | sudo tee -a /home/$usuario/.bashrc


                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}
