###############################################################################
## This file deals with the core Parameter Groups :
###############################################################################

resource "aws_db_parameter_group" "custom-aurora-postgresql" {
  for_each = var.clusters
  name   = each.key
  family = "aurora-postgresql${split(".",each.value.engine_version)[0]}"
  description = "Custom Parameter group value for Postgres Instance"

  parameter {
    apply_method = "pending-reboot"
    name  = "shared_preload_libraries"
    value = "${var.ad_mapping},pg_stat_statements"
  }
}