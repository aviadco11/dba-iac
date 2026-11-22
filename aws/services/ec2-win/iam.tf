data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sql_instances_iam_role" {
  name               = "ec2-role-${local.server_group_name}"
  assume_role_policy data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name = "sql-instances-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["ec2:DescribeTags", "ec2:CreateTags"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = ["s3:GetObject", "s3:ListBucket"]
          Effect   = "Allow"
          Resource = [
            "${data.aws_s3_bucket.bootstrap-files.arn}",
            "${data.aws_s3_bucket.bootstrap-files.arn}/*"
          ]
        },
        {
          Action = ["secretsmanager:GetSecretValue"]
          Effect   = "Allow"
          Resource = "${data.aws_secretsmanager_secret.ad_join_secret.arn}"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${local.server_group_name}_instance_profile"
  role = aws_iam_role.sql_instances_iam_role.name
}
