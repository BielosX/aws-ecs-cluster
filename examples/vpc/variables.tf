variable "container-subnets" {
  type = list(string)
}

variable "cluster-subnets" {
  type = list(string)
}

variable "lb-subnets" {
  type = list(string)
}

variable "public-subnets" {
  type = list(string)
}

variable "name-prefix" {
  type = string
}

variable "availability-zones" {
  type = list(string)
}

variable "cidr" {
  type = string
}