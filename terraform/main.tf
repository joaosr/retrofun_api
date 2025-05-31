resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH and app port"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "fastapi_ec2" {
  ami           = "ami-03250b0e01c28d196"
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "FastAPI-EC2"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y docker.io docker-compose git",
      "sudo usermod -aG docker ubuntu",
      "mkdir -p /home/ubuntu/retrofun_api",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/retrofun_api"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/gitlab-ci")
      host        = self.public_ip
    }
  }
}
