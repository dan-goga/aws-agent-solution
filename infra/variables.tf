variable "aws_region" {
  description = "AWS region for all resources. The Pluralsight AWS sandbox only permits us-east-1 or us-west-2."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.aws_region)
    error_message = "The Pluralsight AWS sandbox only permits us-east-1 or us-west-2."
  }
}

variable "project_name" {
  description = "Name prefix applied to all resources."
  type        = string
  default     = "aws-agent-poc"
}

variable "ANTHROPIC_KEY" {
  description = "Anthropic API key. Stored in Secrets Manager and injected into the backend container. Set via terraform.tfvars (gitignored) or TF_VAR_ANTHROPIC_KEY."
  type        = string
  sensitive   = true
}

variable "anthropic_model" {
  description = "Claude model id used by the backend agent."
  type        = string
  default     = "claude-haiku-4-5-20251001"
}

variable "langfuse_public_key" {
  description = "Langfuse public key for LLM observability."
  type        = string
  default     = ""
}

variable "langfuse_secret_key" {
  description = "Langfuse secret key for LLM observability."
  type        = string
  default     = ""
  sensitive   = true
}

variable "langfuse_host" {
  description = "Langfuse host URL."
  type        = string
  default     = "https://cloud.langfuse.com"
}

variable "backend_image_tag" {
  description = "Image tag to deploy from the backend ECR repository."
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Image tag to deploy from the frontend ECR repository."
  type        = string
  default     = "latest"
}

variable "backend_container_port" {
  description = "Port the backend FastAPI app listens on inside its container."
  type        = number
  default     = 8000
}

variable "frontend_container_port" {
  description = "Port the Streamlit app listens on inside its container."
  type        = number
  default     = 8501
}

variable "backend_cpu" {
  description = "Fargate CPU units for the backend task (1024 = 1 vCPU)."
  type        = number
  default     = 1024
}

variable "backend_memory" {
  description = "Fargate memory (MB) for the backend task."
  type        = number
  default     = 2048
}

variable "frontend_cpu" {
  description = "Fargate CPU units for the frontend task."
  type        = number
  default     = 512
}

variable "frontend_memory" {
  description = "Fargate memory (MB) for the frontend task."
  type        = number
  default     = 1024
}

variable "lambda_memory_mb" {
  description = "Memory allocated to the tool Lambda function."
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days. Kept short since the sandbox destroys everything at session end anyway."
  type        = number
  default     = 1
}
