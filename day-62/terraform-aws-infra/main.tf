resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
    Name = "TerraWeek-VPC"
    }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
   map_public_ip_on_launch = true

  tags = {
    Name = "TerraWeek-Public-Subnet"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route" "default" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}
resource "aws_route_table_association" "rta" {
  subnet_id    = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}
#AWs security group to allow traffic
resource "aws_security_group" "sg" {
  name = "terrawk-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
     }

  tags = {
    Name = "TerraWeek-SG"
  }
}
  resource "aws_instance" "main" {
  ami                         = "ami-045443a70fafb8bbc" # Amazon Linux
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "TerraWeek-Server"
  }
  
}
resource "aws_s3_bucket" "example" {
  bucket = "terrawk-logs-unique-12345"
  depends_on = [aws_instance.main]
  
  
  tags = {
    Name = "TeeraWeek-logs"
}
}
