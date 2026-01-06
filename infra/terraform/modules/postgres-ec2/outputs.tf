output "instance_id" {
  value = aws_instance.postgres.id
}

output "private_ip" {
  value = aws_instance.postgres.private_ip
}

output "security_group_id" {
  value = aws_security_group.this.id
}
