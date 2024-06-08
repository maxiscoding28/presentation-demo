variable "ssh_key_name" { type = string }
variable "security_group_id" { type = string }
variable "subnet_id_a" { type = string }
variable "subnet_id_b" { type = string }
variable "server_name" { type = string }
variable "loadbalancer_security_group_id" { type = string }
variable "vpc_id" { type = string }
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
variable "max_server_count" {
  type    = number
  default = 5
}
variable "min_server_count" {
  type    = number
  default = 0
}
variable "load_balancer_type" {
  type    = string
  default = "application"
}
variable "target_group_port" {
  type    = string
  default = "8200"
}
variable "target_group_protocol" {
  type    = string
  default = "HTTP"
}
variable "target_group_health_check_path" {
  type    = string
  default = "/v1/sys/health"
}
variable "target_group_health_check_codes" {
  type    = string
  default = "200,473"
}
variable "listener_port" {
  type    = string
  default = "80"
}
variable "listener_protocol" {
  type    = string
  default = "HTTP"
}
variable "create_load_balancer" {
  type    = bool
  default = false
}
variable "bootstrap_vault" {
  type    = bool
  default = false
}
variable "vault_version" {
  type    = string
  default = "1.16.0"
}
resource "aws_launch_template" "vault_sandcastle" {
  # Any AMI
  image_id = var.ami_id

  # Any instance type
  instance_type = var.instance_type

  # Any SSH key pair
  key_name = var.ssh_key_name

  # Any security group ID
  vpc_security_group_ids = [var.security_group_id]

  user_data = var.bootstrap_vault ? base64encode(templatefile("${path.module}/bootstrap-vault.sh", {
    vault_version = var.vault_version
  })) : null
}
resource "aws_autoscaling_group" "vault_sandcastle" {

  # Any subnet ID(s)
  vpc_zone_identifier = [var.subnet_id_a]

  # Number of servers to deploy
  desired_capacity = var.server_count

  # Max # of servers you can scale out to
  max_size = var.max_server_count

  # Min # of servers you can scale in to
  min_size = var.min_server_count

  # Association with load balancer target group resource
  target_group_arns = var.create_load_balancer ? [aws_lb_target_group.vault_sandcastle[0].arn] : []

  # Reference to launch template createed above
  launch_template {
    id      = aws_launch_template.vault_sandcastle.id
    version = "$Latest"
  }

  # Any name for EC2 instance
  tag {
    key                 = "Name"
    value               = var.server_name
    propagate_at_launch = true
  }
}
resource "aws_lb" "vault_sandcastle" {
  # IF true, create 1 resource; 
  # ELSE create 0 resources (none)
  count = var.create_load_balancer ? 1 : 0

  load_balancer_type = var.load_balancer_type
  security_groups    = [var.loadbalancer_security_group_id]
  subnets            = [var.subnet_id_a, var.subnet_id_b]
}
resource "aws_lb_target_group" "vault_sandcastle" {
  # IF true, create 1 resource; 
  # ELSE create 0 resources (none)
  count = var.create_load_balancer ? 1 : 0

  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id
  health_check {
    path    = var.target_group_health_check_path
    matcher = var.target_group_health_check_codes
  }
}
resource "aws_lb_listener" "vault_sandcastle" {
  # IF true, create 1 resource; 
  # ELSE create 0 resources (none)
  count = var.create_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.vault_sandcastle[count.index].arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_sandcastle[count.index].arn
  }
}
# For Demonstration Purposes
resource "aws_instance" "vault_sandcastle" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id_a
  tags                   = { Name = "6_STRING_TEMPLATES_extra_demo_instance" }
  user_data = base64encode(<<EOT
#!/bin/bash

# Install Vault
curl --silent -Lo /tmp/vault.zip https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_linux_amd64.zip
unzip /tmp/vault.zip
mv vault /usr/bin
rm -f /tmp/vault.zip
vault server -dev -dev-listen-address=0.0.0.0:8200 > /home/ec2-user/vault-output.log 2>&1 &
    EOT
  )
}