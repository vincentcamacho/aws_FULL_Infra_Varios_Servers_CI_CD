variable "REGION" { default = "eu-west-3" }            #OJO si se modifica la region deben adaptarse abajo los AV_ZONES
variable "BLOQUE_CIDR_VPC" { default = "10.0.0.0/16" } #OJO si se modifica la VPC deben adaptarse abajo los CIDR_SUBRED

variable "NOMBRE_PROYECTO" { default = "CI_CD" }
variable "RUTA_LLAVE_PUBLICA" { default = "C:/Users/jvinc/.ssh/id_rsa.pub" }

variable "NRO_DE_SUBREDES" { default = 1 } #OJO si se modifica este numero, tambien debe modificarse/adaptarse las variables de abajo 
variable "AV_ZONES" { default = ["eu-west-3a", "eu-west-3b", "eu-west-3c"] }
variable "CIDR_PRIVADOS_SUBRED" { default = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"] }
variable "CIDR_PUBLICOS_SUBRED" { default = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"] }

variable "ip_jenkins_master" { default = "10.0.3.20" }
variable "ip_jenkins_slave" { default = "10.0.3.21" }
variable "ip_tomcat" { default = "10.0.3.10" }
variable "ip_ansible" { default = "10.0.3.30" }
variable "ip_docker" { default = "10.0.3.50" }
variable "ip_puppet_master" { default = "10.0.3.80" }
variable "ip_puppet_client" { default = "10.0.3.81" }
variable "ip_k8_master" { default = "10.0.3.100" }
variable "ip_k8_worker_1" { default = "10.0.3.103" }
variable "ip_k8_worker_2" { default = "10.0.3.104" }

variable "TIPO_MICRO" { default = "t2.micro" }
variable "TIPO_PEQUENA" { default = "t2.small" }
variable "TIPO_MEDIANA" { default = "t2.medium" }
variable "TIPO_GRANDE" { default = "t2.large" }

variable "WIN_SERVER_AMI" {
  type = map(string)
  default = {
    us-east-1 = "ami-0d80714a054d3360c", # WindowsServer (Northern Virginia)
    us-west-1 = "ami-0fc6888a6bb1dfba6", # WindowsServer (California)
    eu-west-3 = "ami-05fb43e0cf8358e9a"  # WindowsServer (Paris)
  }
}

variable "UBUNTU_AMI" {
  type = map(string)
  default = {
    us-east-1 = "ami-04505e74c0741db8d", # Ubuntu 20.04 (Virginia)
    us-west-1 = "ami-01f87c43e618bf8f0", # Ubuntu 20.04 (California)
    eu-west-3 = "ami-0c6ebbd55ab05f070"  # Ubuntu 20.04 (Paris)
  }
}
# variable "CANTIDAD_INSTANCIAS" { default = 3 }
# variable "INSTANCE_USERNAME" { default = "vincent" }
# variable "INSTANCE_PASSWORD" { default = "Password!1234" }