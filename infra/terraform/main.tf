resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "retrofun-vpc"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH and app port"
  vpc_id      = aws_vpc.main.id

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

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

resource "aws_subnet" "retrofun_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-subnet"
  }
}

resource "aws_internet_gateway" "retrofun_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "retrofun-igw"
  }
}

resource "aws_route_table" "retrofun_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.retrofun_igw.id
  }

  tags = {
    Name = "retrofun-public-rt"
  }
}

resource "aws_route_table_association" "retrofun_rta" {
  subnet_id      = aws_subnet.retrofun_subnet.id
  route_table_id = aws_route_table.retrofun_route_table.id
}

resource "aws_instance" "retrofun_api_ec2" {
  ami                    = "ami-03250b0e01c28d196"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.retrofun_subnet.id

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1

    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release make git

    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ubuntu
    mkdir -p /home/ubuntu/retrofun_api
    chown -R ubuntu:ubuntu /home/ubuntu/retrofun_api
  EOF

  tags = {
    Name = "Retrofun-API-EC2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/gitlab-ci")
    host        = self.public_ip
    timeout     = "5m"
  }
}

resource "aws_network_acl" "retrofun_nacl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.retrofun_subnet.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 50
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8000
    to_port    = 8000
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  tags = {
    Name = "retrofun-nacl"
  }
}
