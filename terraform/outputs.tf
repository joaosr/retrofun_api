output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.retrofun_api_ec2.public_ip
}
