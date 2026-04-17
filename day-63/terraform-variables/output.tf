output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "subnet_id" {
  value = aws_subnet.my_subnet.id
}

output "instance_id" {
  value = aws_instance.my_ec2.id
}

output "instance_public_ip" {
  value = aws_instance.my_ec2.public_ip
}

output "instance_public_dns" {
  value = aws_instance.my_ec2.public_dns
}

output "security_group_id" {
  value = aws_security_group.sg.id
}