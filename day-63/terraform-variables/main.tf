provider "aws" {
  region = var.region
}

# -------------------
# LOCALS
# -------------------
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.extra_tags)
}

# -------------------
# VPC
# -------------------
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# -------------------
# AVAILABILITY ZONES
# -------------------
data "aws_availability_zones" "az" {
  state = "available"
}

# -------------------
# SUBNET
# -------------------
resource "aws_subnet" "my_subnet" {
  cidr_block              = var.subnet_cidr
  vpc_id                  = aws_vpc.my_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.az.names[0]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-subnet"
  })
}

# -------------------
# INTERNET GATEWAY
# -------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# -------------------
# ROUTING
# -------------------
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rt"
  })
}

resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.rt.id
}

# -------------------
# SECURITY GROUP
# -------------------
resource "aws_security_group" "sg" {
  name   = "${local.name_prefix}-sg"
  vpc_id = aws_vpc.my_vpc.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      description = "Allow port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# -------------------
# KEY PAIR
# -------------------
resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_name
  public_key = file("${path.module}/terra-key.pub")
}

# -------------------
# AMI (DATA SOURCE)
# -------------------
data "aws_ami" "ami" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------
# EC2 INSTANCE
# -------------------
resource "aws_instance" "my_ec2" {
  ami           = data.aws_ami.ami.id
  instance_type = var.instance_type

  key_name                    = aws_key_pair.my_key_pair.key_name
  subnet_id                   = aws_subnet.my_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-server"
  })
}

# -------------------
# S3 BUCKET
# -------------------
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bucket"
  })
}