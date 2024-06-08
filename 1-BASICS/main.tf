resource "aws_instance" "vault_sandcastle" {

  # My chosen AMI (Amazon Linux 2023 AMI)
  ami = "ami-0eb9d67c52f5c80e5"

  # My chosen instance type
  instance_type = "t2.micro"

  # My personal SSH key pair
  key_name = "static-vault-key-pair"

  # My personal security group ID (Allow SSH (:22) and HTTP (:8200) from local IP)
  vpc_security_group_ids = ["sg-04d0d6ceacd9cb479"]

  # My personal subnet ID
  subnet_id = "subnet-0c623711837f700b6"

  # My chosen name for EC2 instance
  tags = { Name = "1_BASICS_vault_sandcastle" }
}