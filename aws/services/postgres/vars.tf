variable app_name {
    type = string
    description = "the name of the application stack"
}

variable aws_account_id {
  type = string
  description = "ID of the AWS account to utilize"
}

variable "account_alias" {
  type = string
  description = "The aws account alias for the current account"
}

variable "primary_region" {
    type = string
    description = "The AWS region to utilize"
}

variable "clusters" {
  type = map(object({
    engine_version = string
    database_name = string
    security_group_ids = list(string)
    kms_key_alias = string
    kerberos_domain = optional(string, null)
    kerberos_role = optional(string, null)
  }))
  description = "array of clusters to create"
  # EXAMPLE BELOW
  # "cluster-name" = {
  #   engine_version = "16.3"
  #   database_name = "test_db"
  #   security_group_ids = [
  #     "<<sg_id>>", # dev-aurora-kerb-sg
  #     "<<sg_id>>" # dev-aurora-pg-sg
  #   ]
  #   kms_key_alias = "key alias goes here"
  #}
}

variable ad_mapping {
  type = string
  default = "pg_ad_mapping"
  description = "string value for enabling AD."
}
