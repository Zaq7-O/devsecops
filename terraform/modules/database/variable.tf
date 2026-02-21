variable "rds_security_group_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "performance_insights_kms_key_id" {
  type        = string
  description = "KMS key ARN for encrypting RDS Performance Insights."
}