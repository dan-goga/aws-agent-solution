# recovery_window_in_days = 0 so `terraform destroy` doesn't leave a pending
# -deletion tombstone that would block re-`apply` with the same name in the
# next sandbox session.
resource "aws_secretsmanager_secret" "anthropic_api_key" {
  name                    = "${local.name_prefix}-anthropic-api-key"
  description             = "Anthropic API key used by the backend agent"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "anthropic_api_key" {
  secret_id     = aws_secretsmanager_secret.anthropic_api_key.id
  secret_string = var.ANTHROPIC_KEY
}
