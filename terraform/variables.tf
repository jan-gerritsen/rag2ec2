variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region where the resources will be created"
  type        = string
  sensitive   = true
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  sensitive   = true
}

variable "aws_vpc_id" {
  description = "VPC ID where the resources will be created"
  type        = string
  sensitive   = true
}

variable "aws_subnet_id" {
  description = "Subnet ID where the resources will be created"
  type        = string
  sensitive   = true
}

variable "aws_ebs_rag_volume_id" {
  description = "EBS Volume ID to attach to the RAG EC2 instance"
  type        = string
  sensitive   = true
}

variable "aws_ebs_ollama_volume_id" {
  description = "EBS Volume ID to attach to the Ollama EC2 instance"
  type        = string
  sensitive   = true
}

variable "aws_security_group_ids" {
  description = "List of Security Group IDs to attach to the EC2 instance"
  type        = list(string)
  sensitive   = true
}

variable "ollama_api_key" {
  description = "Ollama API Key for accessing the Ollama service"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Token for accessing ghcr.io ollama repositories"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub Username for accessing ghcr.io ollama repositories"
  type        = string
  sensitive   = true
}