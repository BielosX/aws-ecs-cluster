provider "aws" {}

data "aws_iam_policy_document" "ec2-assume-role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_iam_role" "instance-role" {
  assume_role_policy = data.aws_iam_policy_document.ec2-assume-role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}

module "cluster" {
  source = "../../modules"
  instance-role-name = aws_iam_role.instance-role.name
  instance-type = "t3.micro"
  max-size = 4
  min-size = 2
  security-group-ids = []
  subnet-ids = data.aws_subnets.subnets.ids
  vpc-id = data.aws_vpc.default.id
  warm-pool-min-size = 2
  warm-pool-max-prepared = 2
  warm-pool-state = "Hibernated"
  cluster-name = "demo-cluster"
  root-encrypted = true
}