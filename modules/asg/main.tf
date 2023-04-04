data "aws_ami" "amazon-linux-2023" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_instance_profile" "cluster-instance-profile" {
  role = var.instance-role-name
}

resource "aws_launch_template" "cluster-instance-template" {
  image_id = data.aws_ami.amazon-linux-2023.id
  instance_type = var.instance-type
  vpc_security_group_ids = var.security-group-ids
  user_data = var.user-data != "" ? base64encode(var.user-data) : null
  iam_instance_profile {
    arn = aws_iam_instance_profile.cluster-instance-profile.arn
  }
}

resource "aws_autoscaling_group" "cluster-asg" {
  max_size = var.max-size
  min_size = var.min-size
  vpc_zone_identifier = var.subnet-ids
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
}