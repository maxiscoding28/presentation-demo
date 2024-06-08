variable "ssh_key_name" { type = string }
variable "security_group_id" { type = string }
variable "subnet_id" { type = string }
variable "server_name" { type = string }
variable "ami_id" {
  type    = string
  default = "ami-0eb9d67c52f5c80e5"
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "server_count" {
  type    = string
  default = 1
}
resource "aws_instance" "vault_sandcastle" {

  # Number of servers to deploy
  count = var.server_count

  # Any AMI
  ami = var.ami_id

  # Any instance type
  instance_type = var.instance_type

  # Any SSH key pair
  key_name = var.ssh_key_name

  # Any security group ID
  vpc_security_group_ids = [var.security_group_id]

  # Any subnet ID
  subnet_id = var.subnet_id

  # Any name for EC2 instance
  tags = { Name = "${var.server_name}-${count.index}" }
}