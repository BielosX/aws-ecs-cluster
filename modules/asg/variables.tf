variable "min-size" {
  type = number
}

variable "max-size" {
  type = number
}

variable "instance-type" {
  type = string
}

variable "security-group-ids" {
  type = list(string)
}

variable "instance-role-name" {
  type = string
}

variable "user-data" {
  type = string
  default = ""
}

variable "subnet-ids" {
  type = list(string)
}

variable "warm-pool-min-size" {
  type = number
  default = 0
}

variable "warm-pool-state" {
  type = string
  default = "Stopped"
}

variable "warm-pool-reuse-on-scale-in" {
  type = bool
  default = false
}

variable "warm-pool-max-prepared" {
  type = number
  default = 0
}