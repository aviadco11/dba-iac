locals {
  kms_keys = data.terraform_remote_state.kms_keys.outputs.kms_keys
}
module each_server {
  for_each = var.clusters
  source = "git@ssh.dev.azure.com:
v3/crossriverbank/DevOps-IaC/iac-aws-terraform-modules//modules/postgresql_serverless_v2?ref=verde/posgresql-domain-parameter-addition"

  name           = each.key
  engine_version = each.value.engine_version
  database_name  = each.value.database_name

  master_username     = "<<username>>"
  master_user_kms_key = local.kms_keys[each.value.kms_key_alias].key.id

  # Kerberos configuration items
  domain = each.value.kerberos_domain
  domain_iam_role_name = each.value.kerberos_role

  # Security group allowing access to the database, which runs on port 5432
  security_group_ids = each.value.security_group_ids

  # Remember that these are in UTC
  preferred_backup_window      = "05:00-06:00"
  preferred_maintenance_window = "sun:06:00-sun:07:00"
}
