# ============================================================
# BUSCAR IMAGEN UBUNTU
# ============================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ============================================================
# SSH KEY PAIR
# ============================================================

resource "aws_key_pair" "devops" {
  key_name   = "${var.project_name}-key"
  public_key = file("${path.module}/hola-juan-devops.pub")

  tags = {
    Name = "${var.project_name}-key"
  }
}


# ============================================================
# INSTANCIA EC2
# ============================================================

resource "aws_instance" "devops" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # ==========================================================
  # BOOTSTRAP AUTOMATICO
  # ==========================================================
  # Ejecuta user-data.sh cuando se crea una EC2 nueva.
  # Instala Docker, kubectl, Minikube, AWS CLI y Nginx.
  user_data = file("${path.module}/user-data.sh")


  # ==========================================================
  # SSH
  # ==========================================================

  key_name = aws_key_pair.devops.key_name


  # ==========================================================
  # IAM INSTANCE PROFILE
  # ==========================================================
  # Permite que la EC2 obtenga credenciales temporales
  # mediante IAM Role.
  #
  # Actualmente permite:
  # - Descargar imagenes desde Amazon ECR
  # - Comunicarse con AWS Systems Manager
  # ==========================================================

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


  # ==========================================================
  # RED
  # ==========================================================

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  associate_public_ip_address = true


  # ==========================================================
  # DISCO PRINCIPAL
  # ==========================================================

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }


  # ==========================================================
  # TAGS
  # ==========================================================

  tags = {
    Name = "${var.project_name}-ec2"
  }
}