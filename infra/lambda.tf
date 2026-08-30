# Zip-packaged, stdlib-only handler: no dependency layer needed. Runtime is
# pinned to the newest AWS-managed Python runtime rather than the project's
# usual 3.14, since Lambda may not yet offer a python3.14 managed runtime and
# this handler has zero third-party dependencies to be version-sensitive about.
data "archive_file" "tool" {
  type        = "zip"
  source_file = "${path.module}/../lambda_tool/src/handler.py"
  output_path = "${path.module}/build/lambda_tool.zip"
}

resource "aws_lambda_function" "tool" {
  function_name    = "${local.name_prefix}-tool"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.tool.output_path
  source_code_hash = data.archive_file.tool.output_base64sha256
  memory_size      = var.lambda_memory_mb
  timeout          = 10

  depends_on = [aws_cloudwatch_log_group.lambda_tool]
}
