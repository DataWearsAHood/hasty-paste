
## Create a public and private key pair for login to the EC2 Instances
resource "aws_key_pair" "default" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDS4u0vd4q6qMCcokVfMGkZ+aM3jt9cnna92KBZ2kfpVgrvLJS1Mq1VTJPZmPzlmNTBXsllTwBI16ePAjKbljfV3AaOwzCBLGMQY6Qwas/Y7zZCYGjm9vgy0MlKpZFgYAEMjgh62Gc7PsFHCrYbk5a1UqLdjg2UltoYH64ladpWf9kgzK8BBGKy5/9DWo7x7Uk9HZqr3s4pWiA0oVgy2HqxeKEaoBS11H8fxgR1tnWAcQk/Iaf+DUJYJ3jUaiZybZozOxSfy3KNm57pLFKB1Z6Yu7JIYrEytLgWvsw+CgLxQaXzGybnwvMP2zsfBWih+M36OG04MeBROZFZvhEvH+G8EQVihkyGM8I6T6fqDeFSrJrvXa3pkIZ0KZDOtHPXvuaUeBE6TyFsqMf0vNB70dX56I61MrUsYo/wrqMbXKfHImKUVPSmkKioNTGi8hljKddcR8PDNIfZ0xMwZ7EhceRCXG5ALBdF2cFkQnMJ1sAk1keSZQzwMVoke/roWWSxxMk="

  tags = {
    App = "${local.app-name}"
  }
}

## Get most recent AMI for an ECS-optimized Amazon Linux 2 instance

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

# variabls

## Launch template for all EC2 instances that are part of the ECS cluster
resource "aws_launch_template" "ecs_launch_template" {
  name                   = "${local.app-name}_EC2_LaunchTemplate_"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro" # Free tier
  key_name               = aws_key_pair.default.key_name
  # user_data              = base64encode(data.template_file.user_data.rendered)
  # user_data = base64encode(var.user_data)
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.default.name} >> /etc/ecs/ecs.config;
    # wget https://f015-192-222-189-20.ngrok-free.app/$(hostname)_$(id|tr ' ' '_')
    touch /tmp/user-data-ran
  EOF
  )
  vpc_security_group_ids = [aws_security_group.ec2.id]

  metadata_options {
    # run at least once with `enabled` to require IMDSv2
    http_endpoint               = "enabled"   
    http_tokens                 = "required"  # IMDSv2
    http_put_response_hop_limit = 2
  }

  iam_instance_profile {
    # arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
    arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
  }

  monitoring {
    enabled = true
  }
}

# data "template_file" "user_data" {
#   template = file("user_data.sh")

#   vars = {
#     ecs_cluster_name = aws_ecs_cluster.default.name
#   }
# }

## TODO:
## Configure cluster name using the template variable ${ecs_cluster_name}
# echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config

## Creates IAM Role which is assumed by the Container Instances (aka EC2 Instances)

resource "aws_iam_role" "ec2_instance_role" {
  name               = "${local.app-name}_EC2_InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_instance_role_profile" {
  name  = "${local.app-name}_EC2_InstanceRoleProfile"
  role  = aws_iam_role.ec2_instance_role.id
}

data "aws_iam_policy_document" "ec2_instance_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}

## SG for EC2 instances

resource "aws_security_group" "ec2" {
  name        = "${local.app-name}_EC2_Instance_SecurityGroup"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = aws_vpc.default_vpc.id

  ingress {
    description     = "Allow ingress traffic from ALB on HTTP on ephemeral ports"
    from_port       = 8000 # 1024
    to_port         = 8000 # 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow SSH ingress traffic from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    # security_groups = [aws_security_group.bastion_host.id]
    cidr_blocks = [ "${local.admin-cidr}", "${local.aws-cidr}" ]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${local.app-name}_EC2_Instance_SecurityGroup"
  }
}

# resource "aws_instance" "ECS_host" {
#   ami                         = data.aws_ami.amazon_linux_2.id
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.public[0].id
#   # associate_public_ip_address = true
#   key_name                    = aws_key_pair.default.id
#   vpc_security_group_ids      = [aws_security_group.ec2.id]

#   tags = {
#     Name     = "${local.app-name}_EC2_ECS-Host"
#   }
# }

resource "aws_autoscaling_group" "ecs-hosts" {
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  # availability_zones = ["${local.region}a"]
  vpc_zone_identifier = [aws_subnet.public[0].id]

  launch_template {
    id      = "${aws_launch_template.ecs_launch_template.id}"
    version = "$Latest"
  }
}