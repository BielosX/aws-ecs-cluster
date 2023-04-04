resource "aws_security_group" "instance-sg" {
  vpc_id = var.vpc-id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 443
    to_port = 443
  }
}

module "asg" {
  source = "./asg"
  instance-role-name = var.instance-role-name
  instance-type = var.instance-type
  max-size = var.max-size
  min-size = var.min-size
  security-group-ids = concat([aws_security_group.instance-sg.id], var.security-group-ids)
  subnet-ids = var.subnet-ids
  warm-pool-min-size = var.warm-pool-min-size
}