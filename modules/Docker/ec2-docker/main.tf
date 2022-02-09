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

                #Uninstall old Docker versions
                sudo apt remove docker docker.io containerd runc -y

                #Before you install Docker Engine for the first time on a new host machine, you need to set up the Docker repository. Afterward, you can install and update Docker from the repository
                sudo apt install ca-certificates curl gnupg lsb-release apt-transport-https -y

                sudo apt autoremove -y

                #Add Docker's official GPG key:
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

                #Use the following command to set up the stable repository. To add the nightly or test repository, add the word nightly or test (or both) after the word stable in the commands below
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                #Install Docker Engine
                sudo apt update -y
                sudo apt install docker-ce docker-ce-cli containerd.io -y

                #Add your user to the docker group
                sudo usermod -aG docker $USER

                #Change the docker.sock permission
                sudo chmod 666 /var/run/docker.sock

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

                #Change the docker.sock permission
                sudo chmod 666 /var/run/docker.sock

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