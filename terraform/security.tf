# ============================================================
# SECURITY GROUP DE LA EC2
# ============================================================

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-sg"
  description = "Security Group del laboratorio DevOps"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg"
  }
}


# ============================================================
# SSH - SOLO DESDE MI IP
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ec2.id

  description = "SSH desde mi IP"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = "${var.my_ip}/32"
}


# ============================================================
# HTTP - ACCESO A LA APLICACION
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.ec2.id

  description = "HTTP publico"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}


# ============================================================
# SALIDA A INTERNET
# ============================================================

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.ec2.id

  description = "Permitir salida a Internet"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}