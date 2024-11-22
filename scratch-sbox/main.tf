resource "aws_s3_bucket" "bucket" {
  bucket = "slv-test-109135784337-us-east-1"

  tags = {
    Name        = "slv-test-109135784337-us-east-1"
    Environment = "Sandbox"
  }
}
# resource "aws_s3_bucket_policy" "allow_access_to_sns_topic" {
#   bucket = aws_s3_bucket.bucket.id
#   policy = data.aws_iam_policy_document.allow_access_to_sns_topic.json
# }

# data "aws_iam_policy_document" "allow_access_to_sns_topic" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["s3.amazonaws.com"]
#     }

#     actions   = ["SNS:Publish"]
#     resources = [aws_sns_topic.topic.arn]
#   }
# }
data "aws_iam_policy_document" "topic" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:slv-test-109135784337-us-east-1-event-notification-topic"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.bucket.arn]
    }
  }
}
resource "aws_sns_topic" "topic" {
  name   = "slv-test-109135784337-us-east-1-event-notification-topic"
  policy = data.aws_iam_policy_document.topic.json
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

resource "aws_sns_topic_subscription" "user_uploads_file" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = "selva.home@gmail.com"
}
