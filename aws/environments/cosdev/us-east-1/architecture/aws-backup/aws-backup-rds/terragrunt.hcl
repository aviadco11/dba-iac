# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

 # Set any module specific configuration and/or override values of any
variables
# defined in parent directories
inputs = {

  backup_rule_settings = [
    {
      name               = "monthly-backups-kept-for-1-year"
      schedule           = "cron(0 12 17 * ? *)" # This cron runs at 12:00
AM (UTC) on the 17th day of every month every year.
      vault_type         = "monthly"
      cold_storage_after = 90                    # 3 months
      delete_after       = 365                   # cold_storage_after + 3
months (minimum)
    },
    {
      name               = "bianually-backups-keep-for-7-years"
      schedule           = "cron(0 12 16 2,8 ? *)" # This cron runs at
12:00 AM (UTC) on the 16th day of February and August every year.
      vault_type         = "yearly"
      cold_storage_after = 90                      # 3 months
      delete_after       = 2555                    # 7 yeahs
    }
  ]
}
