variable "NOMBRE_PROYECTO" { default = "neo" }

variable "REGION" { default = "eu-west-3" }
variable "AV_ZONES" { default = ["eu-west-3a", "eu-west-3b", "eu-west-3c"] }

variable "BLOQUE_CIDR_VPC" { default = "10.0.0.0/16" }
variable "TIPO_RED" { default = "public" } #public, private
variable "BLOQUE_CIDR_SUBRED_PUBLICA" { default = "10.0.150.0/24" }

variable "RUTA_LLAVE_PUBLICA" { default = "~/.ssh/id_ed25519.pub" }

variable "CIDR_PRIVADOS_SUBRED" { default = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"] }
variable "CIDR_PUBLICOS_SUBRED" { default = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"] }

variable "TIPO_MICRO" { default = "t2.micro" }
variable "TIPO_PEQUENA" { default = "t2.small" }
variable "TIPO_MEDIANA" { default = "t2.medium" }
variable "TIPO_GRANDE" { default = "t2.large" }

# variable "UBUNTU_AMI" {
#   type = map(string)
#   default = {
#     us-east-1 = "ami-04505e74c0741db8d", # Ubuntu 20.04 (Virginia)
#     us-west-1 = "ami-01f87c43e618bf8f0", # Ubuntu 20.04 (California)
#     eu-west-3 = "ami-0c6ebbd55ab05f070"  # Ubuntu 20.04 (Paris)
#   }
# }

# variable "CANTIDAD_INSTANCIAS" { default = 3 }
# variable "INSTANCE_USERNAME" { default = "vincent" }
# variable "INSTANCE_PASSWORD" { default = "Password!1234" }