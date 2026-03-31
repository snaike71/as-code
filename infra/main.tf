terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "tls_private_key" "registry_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  filename        = "${path.root}/${var.key_name}.pem"
  file_permission = "0400"
  content         = tls_private_key.registry_key.private_key_pem
}

resource "aws_key_pair" "registry_key_pair" {
  key_name_prefix = "${var.key_name}-"
  public_key      = tls_private_key.registry_key.public_key_openssh
}

resource "aws_security_group" "registry_sg" {
  name_prefix = "registry-sg-"
  description = "Allow SSH, HTTP and Docker Registry API"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "HTTP UI"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker Registry API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "registry" {
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.registry_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.registry_sg.id]

  tags = {
    Name = "as-code-simple-registry"
  }
}

output "public_ip" {
  description = "Public IP of the registry EC2 instance"
  value       = aws_instance.registry.public_ip
}

output "private_key_path" {
  description = "Local path to generated private key"
  value       = local_file.private_key_pem.filename
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i ${local_file.private_key_pem.filename} ubuntu@${aws_instance.registry.public_ip}"
}
