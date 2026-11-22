locals {
    tfstate_bucket = "crossriver-${var.aws_account_id}-terraform-state"
}

data terraform_remote_state kms_keys {
    backend = "s3"
    config  = {
        bucket = local.tfstate_bucket
        key    "${var.account_alias}/${var.primary_region}/${var.app_name}/kms/terraform.tfstate.json"
        region = var.primary_region
    }
}