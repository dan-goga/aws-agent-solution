data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --- ECS task execution role: shared by both backend and frontend task
# definitions. Pulls images from ECR, writes to CloudWatch Logs, and resolves
# the Secrets Manager secret referenced by the backend task def's `secrets`
# block. This is distinct from the *task* role below, which governs what the
# application code itself can do via its container credentials. ---

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.anthropic_api_key.arn]
  }
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name   = "${local.name_prefix}-ecs-execution-secrets"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_execution_secrets.json
}

# --- ECS backend task role: what the backend application code can do via
# its container credentials. Scoped to the exact DynamoDB table and Lambda
# function this POC uses, not wildcarded. The frontend task definition omits
# task_role_arn entirely — it only speaks HTTP to the ALB and needs no AWS
# permissions. ---

resource "aws_iam_role" "ecs_backend_task" {
  name               = "${local.name_prefix}-ecs-backend-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "ecs_backend_task_permissions" {
  statement {
    sid = "DynamoDbAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
    ]
    resources = [aws_dynamodb_table.sessions.arn]
  }

  statement {
    sid       = "InvokeToolLambda"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.tool.arn]
  }
}

resource "aws_iam_role_policy" "ecs_backend_task_permissions" {
  name   = "${local.name_prefix}-ecs-backend-task-permissions"
  role   = aws_iam_role.ecs_backend_task.id
  policy = data.aws_iam_policy_document.ecs_backend_task_permissions.json
}

# --- Lambda execution role: logging only, no other AWS calls needed since
# the tool handler is pure computation. ---

resource "aws_iam_role" "lambda_execution" {
  name               = "${local.name_prefix}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_managed" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
