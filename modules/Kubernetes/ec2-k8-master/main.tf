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
  private_ips = [var.ip_nodos_master[0]]
  security_groups = [var.los_SG]
}

data "template_file" "userdata_linux_ubuntu" {
  template = <<-EOT
                #!/bin/bash
                INICIO=$(date "+%F %H:%M:%S")
                echo "Hora de inicio del script: $INICIO" > /home/ubuntu/a_${var.server_role}.txt

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

                sudo apt update -y && sudo apt upgrade -y

                sudo bash -c 'echo "${var.ip_nodos_master[0]} k8master" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_nodos_worker[0]} k8worker1" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_nodos_worker[1]} k8worker2" >> /etc/hosts'


                swapoff -a
                sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
                sudo bash -c 'echo "/swapfile" >> /etc/fstab'

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

                #Agregar otro usuario para que administre Docker
                usuario=${var.usuario_docker}
                sudo useradd -U $usuario -m -s /bin/bash -p $usuario
                sudo usermod -aG docker $usuario
                echo "$usuario:${var.contrasena_user}" | chpasswd

                #Tambien agregar al usuario AnsibleAdmin al grupo Docker
                sudo usermod -aG docker ${var.usuario_ansible}

                #Add the Docker Daemon configurations to use systemd as the cgroup driver
                sudo cat <<EOF | sudo tee /etc/docker/daemon.json
                {
                  "exec-opts": ["native.cgroupdriver=systemd"],
                  "log-driver": "json-file",
                  "log-opts": {
                    "max-size": "100m"
                  },
                  "storage-driver": "overlay2"
                }
                EOF

                #Start the Docker service if not started
                sudo systemctl start docker.service

                #Enable Docker service at startup
                sudo systemctl enable docker.service

                #Restart the Docker service
                sudo systemctl restart docker



                #Add Kubernetes GPG key in all node
                sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

                #Add Kubernetes APT Repository on All node
                echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

                #Update the system packages
                sudo apt update -y

                #Install Kubeadm,Kubelet and Kubectl on All Node
                sudo apt install kubelet kubeadm kubectl -y

                #Crear alias para kubectl
                alias k=kubectl
                complete -F __start_kubectl k

                #Hold the packages to being upgrade
                sudo apt-mark hold kubelet kubeadm kubectl



                sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
                sudo service sshd restart

                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt
                
                sudo reboot

              EOT
}

