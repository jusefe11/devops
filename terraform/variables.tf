variable "aws_region" {
  description = "Region AWS donde se desplegara el laboratorio"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "hola-juan-devops"
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Rango de direcciones IP de la subred publica"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.small"
}

variable "my_ip" {
  description = "IP publica autorizada para conectarse por SSH"
  type        = string
  default     = "186.99.234.108"
}