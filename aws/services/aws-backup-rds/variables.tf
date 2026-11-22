variable env_type {
  type = string
  description = "environment"
}

variable "aws_backup_name" {
  type    = string
  default = "rds-backup"
}

variable "backup_rule_settings" {
  type = list(object({
    name               = string
    schedule           = string
    vault_type         = string
    cold_storage_after = number
    delete_after       = number
  }))
  description = "The backup rule settings"

  validation {
    condition = alltrue([
      for rule in var.backup_rule_settings :
      contains(["monthly", "yearly"], rule.vault_type)
    ])
    error_message = "vault_type must be either 'monthly' or 'yearly'"
  }
}

variable "start_window" {
  type        = number
  default     = 480 # 8 hours
  description = "(Optional) The amount of time in minutes before beginning
a backup."
}

variable "completion_window" {
  type        = number
  default     = 10080 # 7 days
  description = "(Optional) The amount of time in minutes AWS Backup
attempts a backup before canceling the job and returning an error."
}

variable "enable_vault_lock" {
  type        = bool
  default     = true
  description = "enable_vault_lock"
}
