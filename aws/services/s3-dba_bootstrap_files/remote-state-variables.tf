# These four core variables are required in order to set up any of the
remote
# state definitions.

variable "aws_account_id" {
    type = string
    description = "ID of the AWS account to utilize"
}

variable "env_type" {
    type = string
    description = "The terraform environment"
}

variable "account_alias" {
  type = string
  description = "The aws account alias for the current account"
}

variable "primary_region" {
    type = string
    description = "The AWS region to utilize"
}

# These locals are used to set up the remote state
locals {
    tfstate_bucket = "crossriver-${var.aws_account_id}-terraform-state"
}

## Remote State Data Source for account information
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = local.tfstate_bucket
    key    = "services/dba-core/terraform_state.json"
    region = var.primary_region
  }
}