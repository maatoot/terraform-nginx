variable "region" {
  default = "eu-west-1"
}

variable "vpc_cidr" {
  default = "192.168.0.0/24"
}

variable "public_subnet_cidr" {
  default = "192.168.0.0/24"
}

variable "az" {
  default = "eu-west-1a"
}

variable "instance_type" {
  default = "t3.small"
}

variable "ami_id" {
  # Ubuntu 22.04 LTS (Jammy) في إيرلندا – تأكد من أحدث AMI ID
  default = "ami-0c1c30571d2dae5c9"
}

variable "key_name" {
  default = "TERRA_KEY" # اسم الـ Key Pair اللي موجود عندك في AWS
}
