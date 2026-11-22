dependency "aws-backup-rds" {
    config_path = "../aws-backup-rds"
}

# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Set any module specific configuration and/or override values of any
variables
# defined in parent directories
inputs = {
  sns_name      = "CRB_DBA"
}