variable "aws_region" {
  description = "AWS region where EC2 is created"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name for generated AWS key pair and local pem"
  type        = string
  default     = "registry-key"
}

variable "admin_cidr" {
  description = "CIDR allowed to connect over SSH"
  type        = string
  default     = "0.0.0.0/0"
}
