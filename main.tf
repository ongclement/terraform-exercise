terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.13.0"
    }
  }
  required_version = ">= 0.15"
}

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
  }
}

resource "aws_subnet" "main-vpc-subnet" {
  count = 2
  vpc_id = aws_vpc.main-vpc.id
  map_public_ip_on_launch = true
  cidr_block = var.private_subnet[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "main-vpc-subnets"
    project = "bytedance-assessment"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "main-vpc-ig"
    project = "bytedance-assessment"
  }
}

resource "aws_route_table" "crt" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "prod-public-crt"
    project = "bytedance-assessment"
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

  tags = {
    Name = "allow-all-sg"
    project = "bytedance-assessment"
  }
}

resource "aws_route_table_association" "public-subnet-1" {
  count = 2
  subnet_id = element(aws_subnet.main-vpc-subnet.*.id, count.index)
  route_table_id = aws_route_table.crt.id
}

resource "aws_instance" "linux-vm" {
  count = 2
  ami = "ami-0bd6906508e74f692"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.id
  user_data = file("scripts/bootstrap.sh")
  subnet_id = element(aws_subnet.main-vpc-subnet.*.id, count.index)
  vpc_security_group_ids = [aws_security_group.allow-all.id]

  tags = {
    Name = "ec2-linux"
    project = "bytedance-assessment"
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

  tags = {
    Name = "key-pair"
    project = "bytedance-assessment"
  }
}

resource "aws_ebs_volume" "ebs_volume" {
  count = 2
  size              = 10
  availability_zone = element(aws_instance.linux-vm.*.availability_zone, count.index)

  tags = {
    Name = "ebs"
    project = "bytedance-assessment"
  }
}

resource "aws_volume_attachment" "volume_attachment" {
  count = 2
  instance_id = element(aws_instance.linux-vm.*.id, count.index)
  volume_id   = element(aws_ebs_volume.ebs_volume.*.id, count.index)
  device_name = "/dev/sdh"
  force_detach = true
}

resource "aws_lb" "application_load_balancer" {
  load_balancer_type = "application"
  security_groups = [aws_security_group.allow-all.id]
  subnets = aws_subnet.main-vpc-subnet.*.id

  tags = {
    Name = "alb"
    project = "bytedance-assessment"
  }
}

resource "aws_lb_target_group" "web_servers" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-vpc.id

  tags = {
    Name = "alb-tg"
    project = "bytedance-assessment"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }

  tags = {
    Name = "alb-listener"
    project = "bytedance-assessment"
  }
}

resource "aws_lb_target_group_attachment" "tg-attachment" {
  count = 2
  target_group_arn = aws_lb_target_group.web_servers.arn
  target_id = element(aws_instance.linux-vm.*.id, count.index)
  port = 80
}