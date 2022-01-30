resource "aws_subnet" "mi_subred" {
  count                   = var.cantidad_subredes
  vpc_id                  = var.el_id_de_la_VPC
  availability_zone       = var.los_az[count.index]
  cidr_block              = var.rangos_cidr_subredes[count.index]
  map_public_ip_on_launch = var.asigna_ip_publica
  tags                    = { Name = "subnet-${var.tipo_subred}-${count.index+1}-${var.proyecto}" }
}