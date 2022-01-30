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

              hostnamectl set-hostname ${var.server_role}
              echo "ubuntu:123456" | chpasswd

              sudo apt update -y && sudo apt upgrade -y

              sudo apt install openjdk-11-jdk -y
              sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
              sudo service sshd restart

              echo "El rol de este servidor Jenkins es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
              FINAL=$(date "+%F %H:%M:%S")
              echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              ssh-keygen -t rsa -N "" -f /home/ubuntu/.ssh/id_rsa
              cd /home/ubuntu/.ssh
              sudo cat id_rsa.pub > authorized_keys
              chmod 700 authorized_keys
              EOT
}