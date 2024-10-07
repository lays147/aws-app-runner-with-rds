output "iam_role" {
  value       = aws_iam_role.this.arn
  description = "IAM role ARN for the GitHub Actions pipeline"
}
