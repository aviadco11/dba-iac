# IAM Role for EventBridge to publish to SNS
resource "aws_iam_role" "eventbridge_sns_role" {
  name = "eventbridge-sns-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy" "eventbridge_sns_policy" {
  name = "eventbridge-sns-policy"
  role = aws_iam_role.eventbridge_sns_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sns:Publish",
      Resource = data.aws_sns_topic.aws_sns_topic_arn.arn
    }]
  })
}