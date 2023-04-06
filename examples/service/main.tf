provider "aws" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  first-az = data.aws_availability_zones.available.names[0]
  second-az = data.aws_availability_zones.available.names[1]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"
  cidr = "10.0.0.0/16"
  single_nat_gateway = true
  azs = [local.first-az, local.second-az]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_dns_hostnames = true
  enable_dns_support = true
}

module "ecs-container-definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.2"
  container_image = "nginx:1.23.4-alpine"
  container_name = "nginx"
  container_memory = 512
  container_cpu = 512
}

resource "aws_ecs_task_definition" "nginx" {
  network_mode = "bridge"
  container_definitions = module.ecs-container-definition.json_map_encoded_list
  family = "nginx"
  cpu = 512
  memory = 512
}

resource "aws_ecs_service" "nginx" {
  name = "nginx"
  desired_count = 2
  task_definition = aws_ecs_task_definition.nginx.id
  cluster = "demo-cluster"

  ordered_placement_strategy {
    type = "spread"
    field = "instanceId"
  }

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }

  /*
  network_configuration {
    subnets = module.vpc.private_subnets
  }
  */
}