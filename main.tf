variable "feedly_auth_token" {}
variable "saved_later_stream_id" {}

provider "aws" {
  region = "eu-west-2"
}

data "aws_iam_policy_document" "lambda-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "feedly-sender-role" {
  name = "feedly-sender-role"

  assume_role_policy = data.aws_iam_policy_document.lambda-role-policy.json
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

  role = aws_iam_role.feedly-sender-role.arn

  environment {
    variables = {
      FEEDLY_AUTH_TOKEN = var.feedly_auth_token
      SAVED_LATER_STREAM_ID = var.saved_later_stream_id
    }
  }
}