terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.13.0"
    }
  }
  required_version = ">= 0.15"
}
//TODO: Make use of variables.tf for variables storing
provider "aws" {
  region  = "ap-southeast-1"

  //TODO: Place access key in env
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
}

resource "aws_vpc" "main-vpc" {
  cidr_block       = "10.9.0.0/16"

  tags = {
    Name = "main-vpc"
    project = "bytedance-assessment"
    cost-center = "bytedance"
  }
}

resource "aws_subnet" "main-vpc-subnet-1" {
  vpc_id = aws_vpc.main-vpc.id
  cidr_block = "10.9.0.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "main-vpc"
    project = "bytedance-assessment"
    cost-center = "bytedance"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main-vpc.id
}

resource "aws_route_table" "crt" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "prod-public-crt"
  }
}

resource "aws_security_group" "allow-all" {
  vpc_id = aws_vpc.main-vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table_association" "public-subnet-1" {
  subnet_id      = aws_subnet.main-vpc-subnet-1.id
  route_table_id = aws_route_table.crt.id
}

resource "aws_instance" "linux-vm" {
  ami = "ami-0bd6906508e74f692"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.id
  user_data = file("scripts/bootstrap.sh")
  subnet_id = aws_subnet.main-vpc-subnet-1.id
  vpc_security_group_ids = [aws_security_group.allow-all.id]

  tags = {
    Name = "ec2-linux"
    project = "bytedance-assessment"
    cost-center = "bytedance"
  }

  connection {
    type = "ssh"
    user = var.USER
    private_key = var.PRIVATE_KEY_PATH
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["sudo yum install python"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.PRIVATE_KEY_PATH)
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ec2-user -i '${self.public_ip},' --private-key ${var.PRIVATE_KEY_PATH} ansible/playbook.yml"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "ec2-pvt-key"
  public_key = file(var.PUBLIC_KEY_PATH)
}

resource "aws_ebs_volume" "ebs_volume" {
  size              = 10
  availability_zone = aws_instance.linux-vm.availability_zone

  tags = {
    Name = "ec2-linux-EBS"
    project = "bytedance-assessment"
    cost-center = "bytedance"
  }
}

resource "aws_volume_attachment" "volume_attachment" {
  instance_id = aws_instance.linux-vm.id
  volume_id   = aws_ebs_volume.ebs_volume.id
  device_name = "/dev/sdh"
  force_detach = true
}
