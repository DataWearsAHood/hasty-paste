
# Add ssh key
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDS4u0vd4q6qMCcokVfMGkZ+aM3jt9cnna92KBZ2kfpVgrvLJS1Mq1VTJPZmPzlmNTBXsllTwBI16ePAjKbljfV3AaOwzCBLGMQY6Qwas/Y7zZCYGjm9vgy0MlKpZFgYAEMjgh62Gc7PsFHCrYbk5a1UqLdjg2UltoYH64ladpWf9kgzK8BBGKy5/9DWo7x7Uk9HZqr3s4pWiA0oVgy2HqxeKEaoBS11H8fxgR1tnWAcQk/Iaf+DUJYJ3jUaiZybZozOxSfy3KNm57pLFKB1Z6Yu7JIYrEytLgWvsw+CgLxQaXzGybnwvMP2zsfBWih+M36OG04MeBROZFZvhEvH+G8EQVihkyGM8I6T6fqDeFSrJrvXa3pkIZ0KZDOtHPXvuaUeBE6TyFsqMf0vNB70dX56I61MrUsYo/wrqMbXKfHImKUVPSmkKioNTGi8hljKddcR8PDNIfZ0xMwZ7EhceRCXG5ALBdF2cFkQnMJ1sAk1keSZQzwMVoke/roWWSxxMk="
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
    Name        = "SecurityGroup-Jumphost"
    Application = "dogs-or-cats.com"
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
}
resource "aws_instance" "jumphost" {
  instance_type               = "t2.micro"  # Free Tier
  ami                         = data.aws_ami.ubuntu.id
  vpc_security_group_ids      = [aws_security_group.jumphost.id]
  subnet_id                   = aws_subnet.public-subnet-1.id
  key_name                    = "deployer-key"
  associate_public_ip_address = true
  user_data                   = ""

  tags = {
    Name        = "jumphost"
    Application = "dogs-or-cats.com"
  }
}


# Create Security Group - application
resource "aws_security_group" "dogs-or-cats-app" {
  vpc_id      = aws_vpc.vpc.id
  name        = "SecurityGroup-DogsOrCatsApp"
  description = "Security Group for the dogs-or-cats.com app."

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SecurityGroup-DogsOrCatsApp"
    Application = "dogs-or-cats.com"
  } 
}

# Create EC2 Instance - application
resource "aws_instance" "instance-1" {
  instance_type               = "t2.micro"
  ami                         = data.aws_ami.ubuntu.id
  vpc_security_group_ids      = [aws_security_group.dogs-or-cats-app.id]
  subnet_id                   = aws_subnet.private-subnet-1.id
  key_name                    = "deployer-key"
  associate_public_ip_address = false
  user_data                   = file("user-data.sh")
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name

  tags = {
    Name        = "Prod-DogsOrCatsApp-1"
    Application = "dogs-or-cats.com Web"
    Environment = "Prod"
  }
}

# Output
output "jumphost-public-ip" {
  value = aws_instance.jumphost.public_ip
}

# End;