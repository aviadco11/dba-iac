# SNS Topic
data "aws_sns_topic" "aws_sns_topic_arn" {
  name = var.sns_name
}


# EventBridge Rule for Backup Job Failures
resource "aws_cloudwatch_event_rule" "backup_failure_rule" {
  name        = "BackupJobFailureRule"
  description = "Triggers on AWS Backup job failures"
  event_pattern = jsonencode({
    source = ["aws.backup"],
    "detail-type" = ["Backup Job State Change"],
    detail = {
      state = ["FAILED"]
    }
  })
}
# EventBridge Target to SNS
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.backup_failure_rule.name
  target_id = "SendToSNS"
  arn       = data.aws_sns_topic.aws_sns_topic_arn.arn
  role_arn  = aws_iam_role.eventbridge_sns_role.arn
}