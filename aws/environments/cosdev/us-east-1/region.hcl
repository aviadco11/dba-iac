# Region level Terragrunt parameters

locals {
  primary_region = "us-east-1"
  backup_region  = "us-east-2"
  primary_subnet_ids = ["<<subnet_id>>", "<<subnet_id>>"]
  backup_subnet_ids = null
}