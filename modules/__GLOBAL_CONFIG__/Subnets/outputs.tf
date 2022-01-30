output Rango_de_IPs_Subred { value = aws_subnet.mi_subred[*].cidr_block }
output IDs_subredes { value = aws_subnet.mi_subred[*].id }