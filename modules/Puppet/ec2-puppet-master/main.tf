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
              echo "ubuntu:123456" | chpasswd

              sudo apt update -y && sudo apt upgrade -y

              sudo bash -c 'echo "${var.ip_nodos_master[0]} puppetmaster puppet" >> /etc/hosts'
              sudo bash -c 'echo "${var.ip_nodos_client[0]} puppetclient" >> /etc/hosts'

              wget https://apt.puppetlabs.com/puppet7-release-focal.deb
              sudo dpkg -i puppet7-release-focal.deb
              sudo apt update -y
              sudo apt install puppetserver -y

              sudo systemctl start puppetserver
              sudo systemctl enable puppetserver

              sudo cp /opt/puppetlabs/bin/puppet /usr/bin/ -v
              sudo cp /opt/puppetlabs/puppet/bin/gem /usr/bin/ -v

              sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
              sudo service sshd restart

              echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
              FINAL=$(date "+%F %H:%M:%S")
              echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}