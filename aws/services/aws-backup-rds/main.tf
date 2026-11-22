data "aws_rds_clusters" "all" {}

# Dynamic Vault Creation
resource "aws_backup_vault" "vaults" {
  for_each = local.vault_configs
  name     = each.value.name
  tags     = local.tags
}

# Dynamic Vault Lock Configuration
resource "aws_backup_vault_lock_configuration" "vault_locks" {
  for_each            = var.enable_vault_lock ? local.vault_configs : {}
  backup_vault_name   = aws_backup_vault.vaults[each.key].name
  min_retention_days  = each.value.retention_days
  max_retention_days  = each.value.retention_days
  changeable_for_days = each.value.vault_lock_changeable_for_days
}

resource "aws_backup_plan" "backup-plan" {
  name = "${local.tags.Name}-plan"

  dynamic "rule" {
    for_each = var.backup_rule_settings
    content {
      rule_name                = rule.value.name
      target_vault_name        aws_backup_vault.vaults[rule.value.vault_type].name
      schedule                 = rule.value.schedule
      enable_continuous_backup = false
      start_window            = var.start_window
      completion_window       = var.completion_window

      lifecycle {
        cold_storage_after                        rule.value.cold_storage_after
        delete_after                              = rule.value.delete_after
        opt_in_to_archive_for_supported_resources = true
      }
    }
  }

  tags = local.tags
}

resource "aws_backup_selection" "select" {
  iam_role_arn = aws_iam_role.awsbackup-iam-role.arn
  name         = "${local.tags.Name}-${var.aws_backup_name}-selection"
  plan_id      = aws_backup_plan.backup-plan.id
  resources    = data.aws_rds_clusters.all.cluster_arns
}