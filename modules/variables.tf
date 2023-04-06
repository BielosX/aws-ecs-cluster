variable "max-size" {
  type = number
}

variable "min-size" {
  type = number
}

variable "instance-type" {
  type = string
}

variable "vpc-id" {
  type = string
}

variable "subnet-ids" {
  type = list(string)
}

variable "security-group-ids" {
  type = list(string)
  default = []
}

variable "instance-role-name" {
  type = string
}

variable "warm-pool-min-size" {
  type = number
  default = 0
}

variable "warm-pool-max-prepared" {
  type = number
  default = 0
}

variable "warm-pool-state" {
  type = string
  default = "Stopped"
}

variable "cluster-name" {
  type = string
}

variable "root-encrypted" {
  type = bool
  default = false
}