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

                sudo apt install tomcat9 tomcat9-admin -y
                sudo sed -i 's|</tomcat-users>|<role rolename="manager-gui"/>\n<role rolename="manager-script"/>\n<role rolename="manager-jmx"/>\n<role rolename="manager-status"/>\n<user username="admin" password="admin" roles="manager-gui, manager-script, manager-jmx, manager-status"/>\n<user username="deployer" password="deployer" roles="manager-script"/>\n<user username="tomcat" password="s3cret" roles="manager-gui"/>\n</tomcat-users>|g' /etc/tomcat9/tomcat-users.xml
                sudo systemctl enable tomcat9

                sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
                sudo service sshd restart

                sudo su -
                cp /var/lib/tomcat9/webapps/ROOT/index.html /var/lib/tomcat9/webapps/ROOT/OLD_index.html
                echo "<h1>Mi servidor Tomcat</h1>" > /var/lib/tomcat9/webapps/ROOT/index.html

                echo "El rol de este servidor es: ${var.server_role}" > /home/ubuntu/b_${var.server_role}.txt
                FINAL=$(date "+%F %H:%M:%S")
                echo "Hora de finalizacion del script: $FINAL" >> /home/ubuntu/a_${var.server_role}.txt

              EOT
}

