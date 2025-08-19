# Deploy a Flask and Ollama application to AWS EC2 with Terraform

This is a work in progress to deploy a Flask application with Ollama on AWS EC2 using Docker and Terraform. 
Next steps will include adding a RAG (Retrieval Augmented Generation) component to the application.

## Getting ready

A number of prerequisites are required to run this project:
You should have done the following:
- [Install Docker](https://docs.docker.com/get-docker/)
- [Install Docker Compose](https://docs.docker.com/compose/install/)
- [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting

On AWS, you should have created and noted down a few things:
- VPC ID
- Subnet ID
- Security Group ID
- Key Pair Name
- AWS Region (e.g., us-west-2)
- AWS Access Key ID
- AWS Secret Access Key
- AWS Account ID

### Handy hints

To load the environment variables from the .env/.production, you can use the following commands:
```bash
(rag2ec2) jan@Mac rag2ec2 % set -a                              
(rag2ec2) jan@Mac rag2ec2 % source .envs/.production
(rag2ec2) jan@Mac rag2ec2 % set +a     
```
or `set -a && source .envs/.production && set +a`


#### If things go wrong during deployment
If you encounter issues during deployment, you can check the logs on the EC2 instance:
```bash
ssh -i <your-key-pair>.pem ec2-user@<your-ec2-public-ip>
cat /var/log/cloud-init-output.log | more
```
#### Docker issues
If you face issues with Docker, you can try the following commands to troubleshoot:
```bash
docker ps -a  # List all containers
docker logs <container_id>  # View logs of a specific container
```

#### Ollama issues

On the EC2 instance, you can check the Ollama models with:
```bash
docker compose exec ollama ollama list
```
To pull a specific model, you can use:
```bash
docker compose exec ollama ollama pull <model_name>
```

Simple Ollama query via curl:
```bash     
curl -X POST http://localhost:11434/api/generate \
-H "Content-Type: application/json" \
-d '{"model": "<model_name>", "prompt": "What is the capital of France?", "max_tokens": 50}'
```

Checking theb Ollama logs:
```bash
docker compose logs ollama
```


### What you still should do
Add cloudwatch logging to the application.