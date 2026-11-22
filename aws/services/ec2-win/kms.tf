module ebs_key {
  source = "git@ssh.dev.azure.com:
v3/crossriverbank/DevOps-IaC/iac-aws-terraform-modules//modules/kms_key"

  alias       = "${local.server_group_name}_ebs"
  description = "Encrypts the ebs volumes for all nodes in server group
${local.server_group_name}"

  role_permissions = var.ebs_kms_role_permissions
  service_permissions = {
    "ec2.amazonaws.com" : "READWRITE"
  }
}