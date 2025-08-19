build:
	docker compose -f compose_local.yml.yml build

start:
	docker compose -f compose_local.yml.yml up

stop:
	docker compose -f compose_local.yml.yml stop

logs:
	docker compose -f compose_local.yml.yml logs

# Production specific targets
# Ensure you have the .envs/.production file with the necessary environment variables set

RAG_AWS_ACCOUNT_ID := $(shell grep TF_VAR_aws_account_id .envs/.production | cut -d '=' -f2)
RAG_AWS_DEFAULT_REGION := $(shell grep TF_VAR_aws_region .envs/.production | cut -d '=' -f2)

build_prod_flask:
	docker compose -f compose_production_flask.yml --env-file .envs/.production build

push_prod_flask:
	docker push ${TF_VAR_aws_account_id}.dkr.ecr.${TF_VAR_aws_region}.amazonaws.com/flask:latest

login_to_ecr:
	@echo "Logging in to Amazon ECR..."
	@aws ecr get-login-password --region ${TF_VAR_aws_region} | docker login --username AWS --password-stdin ${TF_VAR_aws_account_id}.dkr.ecr.${TF_VAR_aws_region}.amazonaws.com

load_env_vars:
	@echo "Loading environment variables from .envs/.production"
	@export $(shell grep -v '^#' .envs/.production | xargs)

.PHONY: build build_prod_flask logs start stop push_prod_flask login_to_ecr   build_prod_ollama push_prod_ollama load_env_vars
