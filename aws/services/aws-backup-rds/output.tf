output "backup_rule_name" {
  value = aws_backup_plan.backup-plan.name
}

output "backup_vault_names" {
  value = {
    for k, v in aws_backup_vault.vaults : k => v.name
  }
}

output "backup_rule_settings" {
  value = var.backup_rule_settings
}

output "aurora-select-arn" {
  value = data.aws_rds_clusters.all.cluster_arns
}