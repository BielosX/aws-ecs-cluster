provider "aws" {}

data "aws_vpc" "cluster" {
  filter {
    name = "tag:Name"
    values = ["demo-cluster-vpc"]
  }
}

data "aws_subnets" "container-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.cluster.id]
  }
  filter {
    name = "tag:Name"
    values = ["demo-cluster-vpc-container-subnet"]
  }
}

data "aws_subnets" "lb-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.cluster.id]
  }
  filter {
    name = "tag:Name"
    values = ["demo-cluster-vpc-lb-subnet"]
  }
}

module "ecs-container-definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.2"
  container_image = "nginx:1.23.4-alpine"
  container_name = "nginx"
  container_memory = 512
  container_cpu = 512
  port_mappings = [{
    protocol: "tcp",
    containerPort: 80,
    hostPort: 80
  }]
}

resource "aws_ecs_task_definition" "nginx" {
  network_mode = "awsvpc"
  container_definitions = module.ecs-container-definition.json_map_encoded_list
  family = "nginx"
  requires_compatibilities = ["EC2"]
  cpu = 512
  memory = 512
}

resource "aws_security_group" "lb-sg" {
  vpc_id = data.aws_vpc.cluster.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 80
    to_port = 80
  }
  egress {
    cidr_blocks = [data.aws_vpc.cluster.cidr_block]
    protocol = "tcp"
    from_port = 80
    to_port = 80
  }
}

resource "aws_security_group" "container-sg" {
  vpc_id = data.aws_vpc.cluster.id
  ingress {
    security_groups = [aws_security_group.lb-sg.id]
    protocol = "tcp"
    from_port = 80
    to_port = 80
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 443
    to_port = 443
  }
}

resource "aws_lb" "service-alb" {
  load_balancer_type = "application"
  subnets = data.aws_subnets.lb-subnets.ids
  security_groups = [aws_security_group.lb-sg.id]
}

resource "aws_alb_listener" "service-alb-listener" {
  load_balancer_arn = aws_lb.service-alb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.service-alb-target-group.arn
  }
}

resource "aws_alb_target_group" "service-alb-target-group" {
  target_type = "ip" // Required for awsvpc
  protocol = "HTTP"
  port = "80"
  vpc_id = data.aws_vpc.cluster.id
}

resource "aws_ecs_service" "nginx" {
  launch_type = "EC2"
  name = "nginx"
  desired_count = 2
  task_definition = aws_ecs_task_definition.nginx.arn
  cluster = "demo-cluster"

  ordered_placement_strategy {
    type = "spread"
    field = "instanceId"
  }

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.service-alb-target-group.arn
    container_name = module.ecs-container-definition.json_map_object["name"]
    container_port = 80
  }

  // Same VPC as cluster!!
  network_configuration {
    subnets = data.aws_subnets.container-subnets.ids
    security_groups = [aws_security_group.container-sg.id]
  }

  lifecycle {
    ignore_changes = [capacity_provider_strategy]
  }
}