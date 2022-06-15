output "PUBLIC_IP_mi_vm" {
  value = aws_instance.mi_vm.public_ip
}

output "PRIVATE_IP_mi_vm" {
  value = aws_instance.mi_vm.private_ip
}