data "aws_ssm_parameter" "ecs-ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

locals {
  image-id = jsondecode(data.aws_ssm_parameter.ecs-ami.value)["image_id"]
}

resource "aws_iam_instance_profile" "cluster-instance-profile" {
  role = var.instance-role-name
}

resource "aws_launch_template" "cluster-instance-template" {
  image_id = local.image-id
  instance_type = var.instance-type
  vpc_security_group_ids = var.security-group-ids
  user_data = var.user-data != "" ? base64encode(var.user-data) : null
  iam_instance_profile {
    arn = aws_iam_instance_profile.cluster-instance-profile.arn
  }

  dynamic "block_device_mappings" {
    for_each = var.root-encrypted ? [1] : []
    content {
      device_name = "/dev/xvda"
      ebs {
        delete_on_termination = true
        volume_size = 30
        encrypted = var.root-encrypted
        volume_type = "gp2"
      }
    }
  }
}

resource "aws_autoscaling_group" "cluster-asg" {
  max_size = var.max-size
  min_size = var.min-size
  desired_capacity = 0
  vpc_zone_identifier = var.subnet-ids
  default_instance_warmup = 0
  launch_template {
    id = aws_launch_template.cluster-instance-template.id
    version = aws_launch_template.cluster-instance-template.latest_version
  }
  dynamic "warm_pool" {
    for_each = var.warm-pool-min-size > 0 ? [1] : []
    content {
      pool_state = var.warm-pool-state
      min_size = var.warm-pool-min-size
      max_group_prepared_capacity = var.warm-pool-max-prepared
      instance_reuse_policy {
        reuse_on_scale_in = var.warm-pool-reuse-on-scale-in
      }
    }
  }

  tag {
    key = "AmazonECSManaged"
    value = true
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    propagate_at_launch = true
    value = var.cluster-name
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}