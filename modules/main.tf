resource "aws_security_group" "instance-sg" {
  vpc_id = var.vpc-id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 443
    to_port = 443
  }
}

data "aws_region" "current" {}

locals {
  region = data.aws_region.current.name
}

resource "aws_ssm_parameter" "cloud-watch-agent-config" {
  name = "/${var.cluster-name}/cloud-watch-agent-config"
  type = "String"
  value = jsonencode({
    metrics: {
      namespace: var.cluster-name,
      metrics_collected: {
        mem: {
          measurement: [
            "mem_used",
            "mem_total"
          ],
          metrics_collection_interval: 60
        },
        procstat: [
          {
            exe: "dockerd|containerd",
            measurement: [
              "cpu_usage",
              "memory_rss",
              "read_bytes",
              "write_bytes",
              "read_count",
              "write_count"
            ],
            metrics_collection_interval: 60
          }
        ]
      },
      append_dimensions: {
        InstanceId: "$${aws:InstanceId}"
      },
      aggregation_dimensions: [["InstanceId"]],
      force_flush_interval: 30
    }
  })
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster-name
}

module "asg" {
  source = "./asg"
  image-version = var.image-version
  instance-role-name = var.instance-role-name
  instance-type = var.instance-type
  max-size = var.max-size
  min-size = var.min-size
  security-group-ids = concat([aws_security_group.instance-sg.id], var.security-group-ids)
  subnet-ids = var.subnet-ids
  warm-pool-min-size = var.warm-pool-min-size
  warm-pool-state = var.warm-pool-state
  cluster-name = aws_ecs_cluster.cluster.name
  root-encrypted = var.root-encrypted
  user-data = <<-EOT
  #!/bin/bash

  yum -y update
  yum -y install wget

  echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
  echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
  echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
  echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config
  echo "ECS_ENABLE_TASK_ENI=true" >> /etc/ecs/ecs.config
  echo "ECS_WARM_POOLS_CHECK=true" >> /etc/ecs/ecs.config

  CW_AGENT="https://s3.${local.region}.amazonaws.com/amazoncloudwatch-agent-${local.region}/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
  wget -nv "$CW_AGENT"
  rpm -U ./amazon-cloudwatch-agent.rpm

  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s -c ssm:${aws_ssm_parameter.cloud-watch-agent-config.name}
  EOT
}

resource "aws_ecs_capacity_provider" "asg-capacity-provider" {
  name = "asg-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg.asg-arn
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      target_capacity = 50
      instance_warmup_period = 10
      status = "ENABLED"
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster-capacity-providers" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.asg-capacity-provider.name]
  default_capacity_provider_strategy {
    capacity_provider =aws_ecs_capacity_provider.asg-capacity-provider.name
    weight = 100
  }
}