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
  access_key = "AKIASEFQCHMOQ52LVFLO"
  secret_key = "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"
}

resource "aws_vpc" "main-vpc" {
  cidr_block       = "10.9.0.0/16"

  tags = {
    Name = "main-vpc"
    project = "bytedance-assessment"
    cost-center = "bytedance"
  }
}

resource "aws_instance" "linux-vm" {
  ami = "ami-0bd6906508e74f692"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.id
  user_data = file("scripts/bootstrap.sh")

  tags = {
    Name = "ec2-linux"
    project = "bytedance-assessment"
    cost-center = "bytedance"
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
