resource "aws_key_pair" "mi_ssh_key" {
  key_name   = "llave-ssh-${var.NOMBRE_PROYECTO}"
  public_key = file(var.RUTA_LLAVE_PUBLICA)
}

locals {
  reglas_ingress = [
    { puerto = 22, resumen = "Puerto SSH" },
    { puerto = 80, resumen = "Puerto HTTP" },
    { puerto = 53, resumen = "Puerto DNS" },
    { puerto = 389, resumen = "Puerto LDAP" },
    { puerto = 443, resumen = "Puerto HTTPS" },
    { puerto = 8080, resumen = "Puerto 8080" },
    { puerto = 8081, resumen = "Puerto 8081" }
  ]
}

resource "aws_security_group" "mi_sec_group" {
  name   = "${var.NOMBRE_PROYECTO}-sg-${var.TIPO_RED}"
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

  tags = { Name = "sg-${var.TIPO_RED}-${var.NOMBRE_PROYECTO}" }

}

resource "aws_network_acl" "mi_acl" {
  vpc_id     = aws_vpc.mi_red.id
  subnet_ids = [aws_subnet.mi_subred.id]

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
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = { Name = "acl-${var.TIPO_RED}-${var.NOMBRE_PROYECTO}" }
}