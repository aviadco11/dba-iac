variable "server_group_prefix" {
    type =  string
    description = "Prefix for the server group name"
}

variable "server_group_number" {
    type = string
    description = "Server Group Number"
}

variable "win_ami_id" {
    type = string
    description = "windows ami base"
}

variable "ec2_key_name" {
    type = string
    description = "the ec2 keypair name to encrypt login information"
}

variable "security_groups" {
    type = list(string)
    description = "List of security groups for the server group" #Example
["sg1","sg2","sg3"]
}

variable "node_count" {
    type = string
    description = "How many nodes in the server group"
    default = 1
}

variable "root_block_device" {
    description = "Map of cluster node definitions"
    type        = object({
        volume_size = string
        volume_type = optional(string,"gp3")
    })
}

variable "ebs_volumes" {
    description = "Map of cluster node definitions"
    type        = map(object({
        volume_size = string
        volume_type = optional(string,"gp3")
        volume_iops = optional(string,"3000")
        volume_throughput = optional(string,"500") #Update default value
for throughput on all machines 2/28/2025 per Felix
    }))
}

variable "ebs_kms_role_permissions" {
    type = map(string)
    description = "Maps IAM role ARNs to what they can do with the key"
    # Example : "role_arn" = "ADMIN"
}

variable "instance_type" {
    type = string
    default = "x2iedn.xlarge"
    description = "Instance type for the node(s) in the server group"
}

variable "allowed_zones" {
    type = list(string)
    default = ["a","b"]
    description = "AZ's allwed for deployment of nodes of server group"
}

variable "s3_bootstrap_location" {
    type = string
    description = "Bucket name that holds the bootstrap files for the
deployments"
}

variable "env_OU_overide" { ## Just an example set name to whatever is
least confusing
    type = string
    default = "no_overide_set" ## Just an example set this to whatever is
least confusing
    description = "overides the env for OU purposes" ## write a better
description
}

variable "subnet_selection_pool" {
    type = string
    default = "primary"
    description = "Which subnet pool to use"
}