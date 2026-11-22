data "aws_s3_bucket" "bootstrap-files" {
    provider = aws.bootstrap
    bucket   = var.s3_bootstrap_location
}