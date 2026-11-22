data "aws_caller_identity" "current" {}

# The bucket itself
resource aws_s3_bucket bucket {
  bucket        = "crb-${var.env_type}-dba-bootstrap-files"
  force_destroy = var.force_destroy
}

# Disable public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure lifecycle to expire old objects or old object versions
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.bucket.bucket

    rule {
      id     = "NonCurrentExpiration"
      status = "Enabled"

      noncurrent_version_expiration {
        noncurrent_days = 30
      }
    }
}

# Set up versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# Access logging
data "aws_ssm_parameter" "log_bucket_name" {
  name = "/account_metadata/access_logs_bucket/name"
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket        = aws_s3_bucket.bucket.bucket
  target_bucket = data.aws_ssm_parameter.log_bucket_name.value
  target_prefix = "${aws_s3_bucket.bucket.bucket}/"
}

# The bucket policy
data "aws_iam_policy_document" "allow_access_from_another_org_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]

    condition {
      test = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = ["o-9ita8g6k5j"]
    }
  }
}

resource aws_s3_bucket_policy allow_access_from_another_account {
  bucket = aws_s3_bucket.bucket.id
  policy data.aws_iam_policy_document.allow_access_from_another_org_account.json
}