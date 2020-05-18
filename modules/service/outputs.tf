output "arn" {
  description = "ARN of the bucket"
  value = aws_lambda_function.sender-function.arn
}