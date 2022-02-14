resource "aws_key_pair" "mi_ssh_key" {
  key_name   = "key-pair-para-instancias-ec2"
  public_key = file(var.RUTA_LLAVE_PUBLICA)
}

locals {
  reglas_ingress = [
    { puerto = 3389, resumen = "Puerto RDP" },
    { puerto = 22, resumen = "Puerto SSH" },
    { puerto = 80, resumen = "Puerto HTTP" },
    { puerto = 53, resumen = "Puerto DNS" },
    { puerto = 443, resumen = "Puerto HTTPS" },
    { puerto = 8080, resumen = "Puerto Jenkins" },
    { puerto = 8081, resumen = "Puerto Nexus" },
    { puerto = 8082, resumen = "Puerto Artifactory" },
    { puerto = 8090, resumen = "Puerto HTTP_4" },
    { puerto = 8140, resumen = "Puerto Puppet" },
    { puerto = 9000, resumen = "Puerto SonarQube" },
    { puerto = 6443, resumen = "K8s API server" },
    { puerto = 2379, resumen = "K8s etcd server client API" },
    { puerto = 2380, resumen = "K8s etcd server client API" },
    { puerto = 10248, resumen = "Curl healthz - Error nulo que me dio" },
    { puerto = 10250, resumen = "K8s Kubelet API" },
    { puerto = 10251, resumen = "K8s kube-scheduler" },
    { puerto = 10252, resumen = "K8s kube-controller-manager" }
  ]
}

resource "aws_security_group" "mi_sec_group" {
  name   = "${var.NOMBRE_PROYECTO}-sg"
  vpc_id = aws_vpc.mi_red.id

  dynamic "ingress" {
    for_each = local.reglas_ingress

    content {
      description = ingress.value.resumen
      from_port   = ingress.value.puerto
      to_port     = ingress.value.puerto
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "Permitir PING"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K8s NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   description = "Lo puse por errores en Ingress K8s"
  #   from_port   = 1025
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  ingress {
    description = "Puerto DNS con UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-${var.NOMBRE_PROYECTO}" }

}

resource "aws_network_acl" "mi_network_acl" {
  vpc_id     = aws_vpc.mi_red.id
  subnet_ids = module.subredes_publicas.IDs_subredes

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = { Name = "nacl-${var.NOMBRE_PROYECTO}" }
}