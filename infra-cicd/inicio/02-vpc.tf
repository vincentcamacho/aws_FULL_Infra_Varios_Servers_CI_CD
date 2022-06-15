resource "aws_vpc" "mi_red" {
  tags                 = { Name = "vpc-${var.TIPO_RED}-${var.NOMBRE_PROYECTO}" }
  cidr_block           = var.BLOQUE_CIDR_VPC
  enable_dns_hostnames = true
}

resource "aws_subnet" "mi_subred" {
  tags                    = { Name = "subred-${var.TIPO_RED}-${var.NOMBRE_PROYECTO}" }
  vpc_id                  = aws_vpc.mi_red.id
  cidr_block              = var.BLOQUE_CIDR_SUBRED_PUBLICA
  map_public_ip_on_launch = true
  availability_zone       = var.AV_ZONES[1]
}

resource "aws_internet_gateway" "mi_igw" {
  vpc_id = aws_vpc.mi_red.id
  tags   = { Name = "igw-${var.NOMBRE_PROYECTO}" }
}

resource "aws_route_table" "mi_router" {
  vpc_id = aws_vpc.mi_red.id
  tags   = { Name = "router-${var.TIPO_RED}-${var.NOMBRE_PROYECTO}" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mi_igw.id
  }
}

resource "aws_main_route_table_association" "asociar_router_a_vpc" {
  vpc_id         = aws_vpc.mi_red.id
  route_table_id = aws_route_table.mi_router.id
}
