module each_key {
  for_each = var.kms_keys
  source = "git@ssh.dev.azure.com:
v3/crossriverbank/DevOps-IaC/iac-aws-terraform-modules//modules/kms_key"

  alias       = each.key
  description = each.value.key_description

  role_permissions = each.value.role_permissions
  #service_permissions = each.value.service_permissions
}