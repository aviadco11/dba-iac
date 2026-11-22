# Environment level Terragrunt parameters

# DO NOT create any include blocks. Nested include blocks are not currently
# supported. See: https://github.com/gruntwork-io/terragrunt/issues/1566


locals {
  # account_alias as defined by: aws iam list-account-aliases
  account_alias = "crb-cosdev" # UPDATE_ME
  env_type      = "dev"         # UPDATE_ME
  env_OU_overide = "dev" # This should match env_type, unless you are
landing a machine in a different OU. located in Services>ec2.tf file
  s3_bootstrap_location = "<<bucket_name>>" #dev to dev, prod to prd,
everything else to stg
}
