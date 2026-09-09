terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Bucket donde se almacenara el estado remoto de Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "hola-juan-devops-tfstate-014668143169"

  tags = {
    Name      = "hola-juan-devops-terraform-state"
    Project   = "hola-juan-devops"
    ManagedBy = "Terraform-Bootstrap"
  }
}

# Habilitar versionado
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Habilitar cifrado
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acceso publico
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.id
}