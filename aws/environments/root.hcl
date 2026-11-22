## Root Terragrunt configuration

# DO NOT create any include blocks. Nested include blocks are not currently
# supported. See: https://github.com/gruntwork-io/terragrunt/issues/1566

# Global Terragrunt Parameters
locals {
  # Load additional Terragrunt config files that should be read for
variables
  environment_config read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  region_config      read_terragrunt_config(find_in_parent_folders("region.hcl"))
  stack_config       read_terragrunt_config(find_in_parent_folders("stack.hcl", "missing.hcl"),
{ inputs = {} })

  primary_region = local.region_config.locals.primary_region
  backup_region  = local.region_config.locals.backup_region



  git_repo = basename(run_cmd("git", "rev-parse", "--show-toplevel"))

  company_name   = "crossriver"
  cloud_provider = "aws"

  aws_tags = {
    # Tag all resources with the service that created it
    ManagedBy = "${path_relative_to_include()}"
    GitRepo   = "${local.git_repo}"
  }
}

terraform {
  source "${path_relative_from_include("root")}/../services//${basename(get_terragrunt_dir())}"


  # For terraform commands that use locking, set a lock timeout of 10
minutes.
  extra_arguments "lock_retry" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeouts"]
  }
}

# Generate providers block
generate providers {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# AWS required provider config - Set version and only allow
incremental(patch) updates
# Override this as needed in a specific environment.hcl for testing purposes
# Change versioning here only when a different version has become the
standard
terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = {
      # This should be updated in the future to pull from Artifactory
      source = "registry.terraform.io/hashicorp/aws"
      version = "~> 6.26.0"
    }
  }
}

provider aws {
  region = "${local.primary_region}"

  default_tags {
    tags = var.aws_tags
  }
}

provider aws {
  region = "${local.backup_region}"
  alias = "backup"

  default_tags {
    tags = var.aws_tags
  }
}

# The DBA bootstrap-files buckets (crb-{dev,stg,prd}-dba-bootstrap-files)
always
# live in us-east-1. This alias lets data sources read them regardless of
the
# deployment's primary_region (e.g. cross-region envs like il-central-1).
provider aws {
  region = "us-east-1"
  alias = "bootstrap"

  default_tags {
    tags = var.aws_tags
  }
}

variable aws_tags {
   type = map
}
EOF
}

# ACCOUNT CHECK
# ============# This is a control to ensure the account alias matches the current account
being used.
# It relies on the account alias defined in the environment.hcl matching
the current account alias.
# If they don't match the check will trigger a "WRONG ACCOUNT" error
message and stop.
generate account_check {
  path      = "_account_check.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data aws_iam_account_alias _account_check {}

locals {
  _account_check__expected_alias "${read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals.account_alias}"
  _account_check__current_alias data.aws_iam_account_alias._account_check.account_alias

  _account_check__result = (
  local._account_check__expected_alias =local._account_check__current_alias  ?
  "OK" : file("[ERROR]: WRONG ACCOUNT:
$${local._account_check__expected_alias} !$${local._account_check__current_alias}")
  )
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    region         = local.primary_region
    #dynamodb_table = "terraform-state-lock"
    use_lockfile = true
    bucket         = join("-", [lower(local.company_name),
"${get_aws_account_id()}", "terraform", "state"])
    # Path to / file name of Terraform state file within the bucket for
given app / service
    key     = join("/", ["${path_relative_to_include("root")}",
"terraform.tfstate.json"])
    encrypt = true
    # kms_key_id "arn:aws:kms:us-east-1:${get_aws_account_id()}:alias/#UPDATE_ME"
  }
  # Have Terragrunt manage S3 Bucket and DynamoDB table
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Terraform Parameters - global (root level) variables that all resources
can inherit
inputs = merge(
  local.environment_config.locals,
  local.region_config.locals,
  local.stack_config.inputs,
  {
    company_name               = local.company_name
    root_terragrunt_dir        = get_parent_terragrunt_dir("root")
    relative_deployment_path   = path_relative_to_include("root")
    deployment_path_components = compact(split("/",
path_relative_to_include("root")))
    aws_tags                   = local.aws_tags
    aws_account_id             = get_aws_account_id()
  }
)
