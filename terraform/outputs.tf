output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID de la subred publica"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID del Security Group"
  value       = aws_security_group.ec2.id
}

output "ec2_instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.devops.id
}

output "ec2_public_ip" {
  description = "IP publica de la instancia EC2"
  value       = aws_instance.devops.public_ip
}

output "application_url" {
  description = "URL publica de la aplicacion"
  value       = "http://${aws_instance.devops.public_ip}"
}