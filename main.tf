provider "aws" {
  region = var.region
}

##########################################
# VPC
##########################################

resource "aws_vpc" "main_server_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-server-vpc"
  }
}

##########################################
# Subnet
##########################################

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_server_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = "main-server-public-subnet"
  }
}

##########################################
# Internet Gateway
##########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_server_vpc.id

  tags = {
    Name = "main-server-igw"
  }
}

##########################################
# Route Table
##########################################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_server_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-server-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

##########################################
# Security Group
##########################################

resource "aws_security_group" "main_server_sg" {
  name        = "main-server-sg"
  description = "Allow SSH, HTTP"
  vpc_id      = aws_vpc.main_server_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow All Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main-server-sg"
  }
}

##########################################
# AMI From SSM (Ubuntu 22.04)
##########################################

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

##########################################
# EC2 (بدون SSH)
##########################################

resource "aws_instance" "main_server" {
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.main_server_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
apt update -y
apt install -y nginx
systemctl enable nginx
systemctl restart nginx

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat <<HTML > /var/www/html/index.html
<html>
  <head><title>Main Server</title></head>
  <body style="font-family: Arial; text-align: center; margin-top: 50px;">
    <h1>Hello From Terraform Server</h1>
    <h2>Private IP: $PRIVATE_IP</h2>
  </body>
</html>
HTML
EOF

  tags = {
    Name = "main-server"
  }
}
