variable "feedly_auth_token" {}
variable "saved_later_stream_id" {}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_iam_role" "feedly-sender-role-terraform" {
  name = "feedly-sender-role-terraform"

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

resource "aws_iam_policy" "policy" {
  name        = "log-and-email-policy"
  description = "Policy for a AWS Lambda to send emails and log stuff"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-west-2:884420668197:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-2:884420668197:log-group:/aws/lambda/feedly-sender:*"
            ]
        },
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
  role       = aws_iam_role.feedly-sender-role-terraform.name
  policy_arn = aws_iam_policy.policy.arn
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "src"
  output_path = "dist/function.zip"
}

resource "aws_lambda_function" "feedly-sender-terraform" {
  function_name = "feedly-sender-terraform"
  handler = "lambda_function.lambda_handler"
  runtime = "ruby2.7"
  filename = "dist/function.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.feedly-sender-role-terraform.arn

  environment {
    variables = {
      FEEDLY_AUTH_TOKEN = var.feedly_auth_token
      SAVED_LATER_STREAM_ID = var.saved_later_stream_id
    }
  }
}