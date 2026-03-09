variable "region" {
  type = string
  description = "AWS region to deploy resources."
}

variable "environment" {
  type = string
  description = "Deployment environment name (e.g., dev, prod)."
}

variable "vpc_cidr" {
  type = string
  description = "CIDR block for the VPC."
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
  description = "List of availability zones."
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  type = list(string)
  description = "List of public subnet CIDRs."
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type = list(string)
  description = "List of private subnet CIDRs."
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnets" {
  type = list(string)
  description = "List of isolated/database subnet CIDRs."
  default = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "container_image" {
  type = string
  description = "Container image URI for ECS."
}

variable "db_name" {
  type = string
  description = "Database name."
}

variable "db_username" {
  type = string
  description = "Database username."
}

variable "db_password" {
  type      = string
  sensitive = true
  description = "Database password."
}

variable "performance_insights_kms_key_id" {
  type        = string
  description = "KMS key ARN for encrypting RDS Performance Insights."
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet(s) where RDS resides. Used for security group rules."
  type        = string
  default     = "10.0.11.0/24"
}

variable "s3_vpc_endpoint_cidr" {
  description = "CIDR block for S3 VPC endpoint or allowed HTTPS egress."
  type        = string
  default     = "10.0.0.0/16"
}