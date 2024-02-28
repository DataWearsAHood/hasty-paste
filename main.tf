# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# Based on: https://github.com/hashicorp/learn-terraform-github-actions/blob/main/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "example-org-c73f1f"

    workspaces {
      name = "CD-CD_demo"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "random_pet" "sg" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  # associate_public_ip_address = true  # already done?

  metadata_options {
    http_endpoint               = "disabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = <<-EOF
              #!/bin/sh
              sh /app/entrypoint.sh
              EOF
}

resource "aws_security_group" "web-sg" {
  name = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.222.189.20/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" # TODO: switch to `http` (?)
    cidr_blocks = ["192.222.189.20/32"]
  }
  
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp" # TODO: switch to `http` (?)
    cidr_blocks = ["192.222.189.20/32"]
  }
  // connectivity to ubuntu mirrors is required to run `apt-get update` and `apt-get install apache2`
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "web-address" {
  value = "${aws_instance.web.public_dns}:8000"
}