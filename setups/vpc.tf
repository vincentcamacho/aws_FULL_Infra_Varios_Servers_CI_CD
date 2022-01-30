resource "aws_vpc" "mi_red" {
  cidr_block           = var.BLOQUE_CIDR_VPC
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-${var.NOMBRE_PROYECTO}" }
}

resource "aws_internet_gateway" "mi_igw" {
  vpc_id = aws_vpc.mi_red.id
  tags   = { Name = "igw-${var.NOMBRE_PROYECTO}" }
}

resource "aws_route_table" "mi_router_de_la_vpc" {
  vpc_id = aws_vpc.mi_red.id
  tags   = { Name = "rt-${var.NOMBRE_PROYECTO}-nuevo" }

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.mi_igw.id
  # }
}
resource "aws_default_route_table" "router_por_defecto" {
  default_route_table_id = aws_vpc.mi_red.default_route_table_id
  tags                   = { Name = "rt-${var.NOMBRE_PROYECTO}-default" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mi_igw.id
  }
}

# resource "aws_route_table_association" "asociar_subnets_privadas_a_nuevo_router" {
#   count          = var.NRO_DE_SUBREDES
#   subnet_id      = module.subredes_privadas.IDs_subredes[count.index]
#   route_table_id = aws_route_table.mi_router_de_la_vpc.id
# }

resource "aws_route_table_association" "asociar_subnets_publicas_a_default_router" {
  count          = var.NRO_DE_SUBREDES
  subnet_id      = module.subredes_publicas.IDs_subredes[count.index]
  route_table_id = aws_default_route_table.router_por_defecto.id
}