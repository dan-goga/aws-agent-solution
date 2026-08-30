# One item per conversation turn (session_id + message_ts), so a Query with
# a sort-key range returns the full ordered history for a session.
resource "aws_dynamodb_table" "sessions" {
  name         = "${local.name_prefix}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"
  range_key    = "message_ts"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "message_ts"
    type = "N"
  }

  tags = { Name = "${local.name_prefix}-sessions" }
}
