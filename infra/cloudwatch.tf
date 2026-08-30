resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name_prefix}-backend"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name_prefix}-frontend"
  retention_in_days = var.log_retention_days
}

# Created explicitly (and before aws_lambda_function.tool in lambda.tf) so
# that Lambda's own implicit log-group creation on first invocation is a
# no-op, rather than creating an unmanaged group with default infinite
# retention that Terraform can't then reconcile.
resource "aws_cloudwatch_log_group" "lambda_tool" {
  name              = "/aws/lambda/${local.name_prefix}-tool"
  retention_in_days = var.log_retention_days
}
