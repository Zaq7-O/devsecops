variable "region" {
  type = string
}
variable "environment" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "container_image" {
  type = string
}
variable "db_name" {
  type = string
}
variable "db_username" {
  type = string
}
variable "db_password" {
  type      = string
  sensitive = true
}

variable "performance_insights_kms_key_id" {
  type        = string
  description = "KMS key ARN for encrypting RDS Performance Insights."
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet(s) where RDS resides. Used for security group rules."
  type        = string
}

variable "s3_vpc_endpoint_cidr" {
  description = "CIDR block for S3 VPC endpoint or allowed HTTPS egress."
  type        = string
}