resource "aws_security_group" "instance-sg" {
  vpc_id = var.vpc-id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 443
    to_port = 443
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster-name
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
  cluster-name = aws_ecs_cluster.cluster.name
  user-data = templatefile("${path.module}/init.sh", {
    cluster_name: aws_ecs_cluster.cluster.name
  })
}

resource "aws_ecs_capacity_provider" "asg-capacity-provider" {
  name = "asg-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg.asg-arn
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      target_capacity = 100
      instance_warmup_period = 30
      status = "ENABLED"
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster-capacity-providers" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.asg-capacity-provider.name]
}