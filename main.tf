variable "feedly_auth_token" {}
variable "saved_later_stream_id" {}

variable "lambda_name" {
  default = "feedly-sender-terraform"
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_cloudwatch_event_rule" "daily" {
  name                = "daily"
  description         = "Once a day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "send-email-daily" {
  rule      = aws_cloudwatch_event_rule.daily.name
  target_id = "lambda"
  arn       = aws_lambda_function.feedly-sender-terraform.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.feedly-sender-terraform.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}

resource "aws_iam_role" "feedly_sender_role_terraform" {
  name = "feedly_sender_role_terraform"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "send_email_policy" {
  name        = "send_email_policy"
  description = "Policy for a AWS Lambda to send emails"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "does-not-matter" {
  role       = aws_iam_role.feedly_sender_role_terraform.name
  policy_arn = aws_iam_policy.send_email_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 3
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging_policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.feedly_sender_role_terraform.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "src"
  output_path = "dist/function.zip"
}

resource "aws_lambda_function" "feedly-sender-terraform" {
  function_name = var.lambda_name
  handler = "lambda_function.lambda_handler"
  runtime = "ruby2.7"
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.feedly_sender_role_terraform.arn

  environment {
    variables = {
      FEEDLY_AUTH_TOKEN = var.feedly_auth_token
      SAVED_LATER_STREAM_ID = var.saved_later_stream_id
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_logs, aws_cloudwatch_log_group.lambda_log_group]
}