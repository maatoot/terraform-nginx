provider "aws" {
  region = "eu-west-1"
}

##########################################
# VPC
##########################################

resource "aws_vpc" "main_server_vpc" {
  cidr_block = "192.168.0.0/24"

  tags = {
    Name = "main-server-vpc"
  }
}

##########################################
# Public Subnet
##########################################

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_server_vpc.id
  cidr_block              = "192.168.0.0/28"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

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
# Public Route Table
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
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
# Main Server EC2 Instance
##########################################

resource "aws_key_pair" "main_server_key" {
  key_name   = "main-server-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "main_server" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.main_server_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.main_server_key.key_name

  tags = {
    Name = "main-server"
  }
}

##########################################
# Web Server Key Pair
##########################################

resource "aws_key_pair" "web_key" {
  key_name   = "azoz-web-key"
  public_key = file("~/.ssh/azoz_web_key.pub")
}

##########################################
# Web Server EC2 (Nginx + Custom Page)
##########################################

resource "aws_instance" "web_server" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.main_server_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.web_key.key_name

  user_data = <<-EOF
#!/bin/bash
apt update -y
apt install -y nginx

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat <<HTML > /var/www/html/index.html
<html>
  <head><title>Azoz Nginx Server</title></head>
  <body style="font-family: Arial; text-align: center; margin-top: 50px;">
    <h1>Hello From Azoz Server through Jenkins Pipeline</h1>
    <h2>Private IP: $PRIVATE_IP</h2>
  </body>
</html>
HTML

systemctl restart nginx
systemctl enable nginx
EOF

  tags = {
    Name = "HOSSAM-web-server"
  }
}
