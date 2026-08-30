output "alb_dns_name" {
  description = "Public DNS name of the load balancer. Open http://<this>/ for the Streamlit UI."
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.sessions.name
}

output "lambda_function_name" {
  value = aws_lambda_function.tool.function_name
}

output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}
