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
resource "aws_launch_template" "vault_sandcastle" {
  # Any AMI
  image_id = var.ami_id

  # Any instance type
  instance_type = var.instance_type

  # Any SSH key pair
  key_name = var.ssh_key_name

  # Any security group ID
  vpc_security_group_ids = [var.security_group_id]
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
  target_group_arns = [data.aws_lb_target_group.vault_sandcastle.arn]

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
# resource "aws_lb" "vault_sandcastle" {
#   load_balancer_type = var.load_balancer_type
#   security_groups    = [var.loadbalancer_security_group_id]
#   subnets            = [var.subnet_id_a, var.subnet_id_b]
#   tags = {
#     Name = "4-LOAD_BALANCER"
#   }
# }
data "aws_lb" "vault_sandcastle" {
  tags = {
    Name = "4-LOAD_BALANCER"
  }
}
data "aws_lb_target_group" "vault_sandcastle" {
  tags = {
    Name = "4-LOAD_BALANCER"
  }
}
resource "aws_lb_listener" "vault_sandcastle" {
  load_balancer_arn = data.aws_lb.vault_sandcastle.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.vault_sandcastle.arn
  }
}