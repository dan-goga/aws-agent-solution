# AWS Agent POC

Agentic LangChain application deployed on AWS via Terraform, running inside a Pluralsight AWS Cloud Sandbox (Cloud+ plan — no Bedrock/SageMaker access, so the agent calls Claude Haiku directly via the Anthropic API).

## Architecture

```
                         ┌─────────────────────────┐
 internet ──HTTP:80──▶   │   Application Load       │
                         │   Balancer (public)       │
                         └───────────┬───────────────┘
                          /          │ /api/*
                    (default)        ▼
              ┌─────────────┐  ┌─────────────┐
              │  Frontend   │  │  Backend    │
              │  Streamlit  │  │  FastAPI +  │
              │  ECS Fargate│  │  LangChain  │
              │             │  │  ECS Fargate│
              └─────────────┘  └──────┬──────┘
                                      │
                     ┌────────────────┼─────────────────┐
                     ▼                ▼                 ▼
             ┌───────────────┐ ┌─────────────┐  ┌────────────────┐
             │ Secrets Mgr   │ │ DynamoDB    │  │ Lambda (tool):  │
             │ Anthropic key │ │ sessions    │  │ price estimator │
             └───────────────┘ └─────────────┘  └────────────────┘
                     │
                     ▼
             api.anthropic.com (Claude Haiku)
```

Both ECS services run as Fargate tasks in public subnets (no NAT Gateway — see `infra/network.tf` for the reasoning), reachable only through the ALB via security groups. IAM roles handle every service-to-service permission (ECS execution role → Secrets Manager; backend task role → DynamoDB + Lambda invoke); no static AWS credentials are used anywhere in the application code.

## Prerequisites

- Terraform 1.16.0
- Python 3.14, `uv`
- Docker
- AWS CLI, configured with the Pluralsight sandbox's `cloud_user` credentials
- An Anthropic API key

## Deploy

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set aws_region (us-east-1 or us-west-2, per your
# sandbox session) and anthropic_api_key

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

The ECS services will come up unhealthy at first — the ECR repos are empty. Build and push both images:

```bash
aws ecr get-login-password --region <region> | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com

cd ../backend
uv lock
docker build -t $(terraform -chdir=../infra output -raw backend_ecr_repository_url):latest .
docker push $(terraform -chdir=../infra output -raw backend_ecr_repository_url):latest

cd ../frontend
uv lock
docker build -t $(terraform -chdir=../infra output -raw frontend_ecr_repository_url):latest .
docker push $(terraform -chdir=../infra output -raw frontend_ecr_repository_url):latest
```

Force ECS to pick up the newly pushed images:

```bash
aws ecs update-service --cluster $(terraform -chdir=infra output -raw ecs_cluster_name) \
  --service aws-agent-poc-backend --force-new-deployment
aws ecs update-service --cluster $(terraform -chdir=infra output -raw ecs_cluster_name) \
  --service aws-agent-poc-frontend --force-new-deployment
```

Open `http://$(terraform -chdir=infra output -raw alb_dns_name)/` once both services report healthy (`aws ecs describe-services ...` / `aws elbv2 describe-target-health ...`).

## Try it

Ask the chat UI something like *"How much would 5 t3.medium instances cost?"* — this routes through the backend's LangChain agent, which calls the `estimate_cost` tool (the Lambda function) rather than guessing, and persists the conversation turn to DynamoDB.

## Tear down

```bash
cd infra
terraform destroy
```

Do this before the ~4-hour Pluralsight sandbox session ends — nothing here is designed to persist past a session (local Terraform state, no remote backend, short CloudWatch log retention, `recovery_window_in_days = 0` on the Secrets Manager secret so re-`apply` with the same name works cleanly next session).

## Repo layout note

Unlike the generic single-`src/` template sketched in the parent `CLAUDE.md`, this POC has three independently deployable Python units (`backend/`, `frontend/`, `lambda_tool/`), each with its own `pyproject.toml`/Dockerfile — a deliberate divergence, since the architecture calls for three separate containers/functions rather than one agent process.
