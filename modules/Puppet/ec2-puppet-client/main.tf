resource "aws_instance" "mis_vms" {
  ami                         = var.win_server_ami[var.region] #var.imagen_OS 
  instance_type               = var.tipo_instancia
  availability_zone           = var.AZs[0]
  # subnet_id                   = var.los_IDs_subredes[0]
  user_data                   = data.template_file.userdata_linux_ubuntu.rendered
  key_name                    = var.llave_ssh
  tags                        = { Name = "srv-${var.server_cliente}" }

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
                echo "Hora de inicio del script: $INICIO" > /home/ubuntu/a_${var.server_cliente}.txt

                sudo timedatectl set-timezone Europe/Paris

                sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
                sudo service sshd restart

                hostnamectl set-hostname ${var.server_cliente}
                echo "ubuntu:${var.pw_user_app}" | chpasswd

                #Evitar que pida el password a cada rato para usuarios que sean parte del grupo sudo
                sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'
                sed -i /etc/sudoers -re 's/^#includedir.*/## Removed the #include directive! ##"/g'

                #Agregar otro usuario para que administre Ansible
                usuario=${var.usuario_app}
                sudo useradd -U $usuario -m -s /bin/bash -p $usuario -G sudo
                echo "$usuario:${var.pw_user_app}" | sudo chpasswd
                sudo bash -c 'echo "${var.usuario_app} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
                sudo bash -c 'echo "${var.usuario_app} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-cloud-init-users'

                sudo ufw disable
                sudo apt update -y && sudo apt upgrade -y
                sudo apt install tree tldr net-tools -y
                sudo apt install wget unzip -y

                sudo bash -c 'echo "${var.ip_nodos_master[0]} ${var.server_master} puppet" >> /etc/hosts'
                sudo bash -c 'echo "${var.ip_nodos_client[0]} ${var.server_cliente}" >> /etc/hosts'

                # ALIAS Basicos
                echo "#ALIAS BASICOS" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias c='sudo cat'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias t='sudo touch'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias md='sudo mkdir'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias nt='sudo netstat -tulpn'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias hs='history'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias hm='cd ~'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias l1='ls -la'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias sy='sudo systemctl status'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias sy1='sudo systemctl start'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias sy2='sudo systemctl stop'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias syr='sudo systemctl restart'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias pw='sudo cat /etc/passwd'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias sd='sudo cat /etc/sudoers'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias sd2='sudo cat /etc/sudoers.d/90-cloud-init-users'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias fws='sudo ufw status'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias ai='sudo apt install'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias up1='sudo apt update -y'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias up2='sudo apt update -y && sudo apt upgrade -y'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias sshd='sudo cat /etc/ssh/sshd_config'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias sshda='cat /etc/ssh/sshd_config | grep 'PubkeyAuthentication\|PasswordAuthentication\|PermitRootLogin\|PermitEmptyPasswords''" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias vmmc='sudo sysctl vm.max_map_count'" | sudo tee -a /home/${var.usuario_app}/.bashrc
                echo "alias ffm='sudo sysctl fs.file-max'" | sudo tee -a /home/${var.usuario_app}/.bashrc

                wget https://apt.puppetlabs.com/puppet7-release-focal.deb
                sudo dpkg -i puppet7-release-focal.deb
                sudo apt update -y
                sudo apt install puppet-agent -y

                sudo bash -c 'echo "[main]" >> /etc/puppetlabs/puppet/puppet.conf'
                sudo bash -c 'echo "certname = ${var.server_cliente}" >> /etc/puppetlabs/puppet/puppet.conf'
                sudo bash -c 'echo "server = ${var.server_master}" >> /etc/puppetlabs/puppet/puppet.conf'

                # Start the Puppet service
                sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

                echo "El rol de este servidor es: ${var.server_cliente}" > /home/ubuntu/b_${var.server_cliente}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_cliente}.txt

              EOT
}