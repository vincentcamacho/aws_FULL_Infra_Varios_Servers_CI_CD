data "aws_ami" "ubuntu_os" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "mi_vm" {
  tags                   = { Name = "vm-${var.TIPO_RED}-${var.NOMBRE_PROYECTO}" }
  subnet_id              = aws_subnet.mi_subred.id
  ami                    = data.aws_ami.ubuntu_os.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.mi_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.mi_sec_group.id]
}