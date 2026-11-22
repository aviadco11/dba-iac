data "aws_secretsmanager_secret" "ad_join_secret" {
  name = "ad_join_secret"
}

data "aws_secretsmanager_secret_version" "ad_join_secret" {
  secret_id = data.aws_secretsmanager_secret.ad_join_secret.id
}
