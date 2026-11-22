# AWS Backup for RDS Aurora Terraform Module

This Terraform module configures AWS Backup for RDS Aurora clusters with
monthly and yearly backup strategies, including automated restore testing.

## Features

- Dynamic vault creation for monthly and yearly backups
- Configurable backup retention periods
- Automated restore testing plans
- IAM role configuration for AWS Backup
- Backup selection for Aurora clusters

## Prerequisites

- Terraform >= 0.12
- AWS provider
- Existing Aurora RDS clusters
- Appropriate AWS permissions

## Usage

```hcl
module "aws_backup" {
  source = "path/to/module"

  env_type = "prod"
  aws_backup_name = "rds-backup"

  backup_rule_settings = [
    {
      name = "monthly-backups-kept-for-1-year"
      schedule = "cron(0 12 17 * ? *)" # This cron runs at 12:00 AM (UTC)
on the 17th day of every month
      vault_type = "monthly"
      cold_storage_after = 90
      delete_after = 365
    },
    {
      name = "bianually-backups-keep-for-7-years"
      schedule = "cron(0 12 16 2,8 ? *)" # This cron runs at 12:00 AM (UTC)
on the 16th day of February and August every year.
      vault_type = "yearly"
      cold_storage_after = 90
      delete_after = 2555
    }
  ]
}
```

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| env_type | Environment name | string | - |
| aws_backup_name | Backup plan name prefix | string | "rds-backup" |
| backup_rule_settings | Backup rules configuration | list(object) | - |
| start_window | Backup start window in minutes | number | 480 |
| completion_window | Backup completion window in minutes | number | 10080 |

## Resource Types

- `aws_backup_vault`
- `aws_backup_vault_lock_configuration`
- `aws_backup_plan`
- `aws_backup_selection`
- `aws_backup_restore_testing_plan`
- `aws_backup_restore_testing_selection`
- `aws_iam_role`

## Outputs

| Name | Description |
|------|-------------|
| backup_rule_name | Name of the backup plan |
| backup_vault_names | Map of vault names by type |
| restore_testing_plan_names | Map of restore testing plan names |
| backup_rule_settings | Applied backup rule settings |
| aurora-select-arn | List of Aurora cluster ARNs |
| first_cluster_arn | ARN of the first Aurora cluster |

## Backup Schedule

### Monthly Backups
- Runs on the 17th of each month at 12:00 AM UTC
- Stored in monthly vault

### Yearly Backups
- Runs on February and August 16th day of every year at
  12:00 AM UTC
- Stored in yearly vault

## Restore Testing
- Automated restore testing for both monthly and yearly   backups
- Uses existing subnet groups from source clusters
- IAM role configured with necessary permissions
- Cleanup after testing completion

## Notes
- Vault locks are configured with 3-day change window
- Continuous backup is disabled
- Archive tier enabled for supported resources