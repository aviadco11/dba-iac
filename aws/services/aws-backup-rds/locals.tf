locals {
  tags = {
    Terraform   = "true"
    Name        = "aws-backup-rds-${var.env_type}"
    Environment = var.env_type
  }

  # Get retention days from backup rule settings
  retention_days = {
    for rule in var.backup_rule_settings : rule.vault_type =>
rule.delete_after
  }

  vault_configs = {
    monthly = {
      name = "${local.tags.Name}-vault-monthly"
      retention_days = local.retention_days["monthly"]
      vault_lock_changeable_for_days = 3
    }
    yearly = {
      name = "${local.tags.Name}-vault-yearly"
      retention_days = local.retention_days["yearly"]
      vault_lock_changeable_for_days = 3
    }
  }
}