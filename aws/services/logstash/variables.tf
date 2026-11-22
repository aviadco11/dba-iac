variable "environment" {
  type        = string
  description = "environment name (i.e.: `dev`, `prod`)"
  nullable = false
}

variable "cnt_instances" {
  type        = number
  description = "number of servers"
  default = 1
}

variable "key_name" {
  type        = string
  description = "key name"
  default = "ec2-keypair-dev"
}


variable "vpc_id" {
    type = string
    description = "vpc id to provision infra"
    nullable = false
}

variable "instance_type" {
    type = string
    description = "instance t3.medium, t3.large..."
    nullable = false
}

variable "subnet_id" {
  type = string
  description = "subnet id"
}

variable "ami_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
  nullable = false

  validation {
    condition     = length(var.ami_id) > 4 && substr(var.ami_id, 0, 4) ="ami-"
    error_message = "The image_id value must be a valid AMI id, starting
with \"ami-\"."
  }
}

variable "vol_size" {
  type        = number
  description = "vol size ebs"
  nullable = false
}

