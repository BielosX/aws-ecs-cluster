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

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "../vpc"
  availability-zones = data.aws_availability_zones.available.names
  cidr = "10.0.0.0/16"
  cluster-subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  container-subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  lb-subnets = ["10.0.30.0/24", "10.0.40.0/24"]
  public-subnets = ["10.0.50.0/24", "10.0.60.0/24"]
  name-prefix = "demo-cluster-vpc"
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
  instance-type = "t3.medium"
  max-size = 4
  min-size = 0
  subnet-ids = module.vpc.cluster-subnet-ids
  vpc-id = module.vpc.vpc-id
  warm-pool-min-size = 2
  warm-pool-max-prepared = 2
  warm-pool-state = "Stopped"
  cluster-name = "demo-cluster"
  root-encrypted = false
}