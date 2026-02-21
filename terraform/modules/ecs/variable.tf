variable "db_host" {
  description = "Database endpoint hostname"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for DB password"
  type        = string
}
variable "ecs_security_group_id" {
  description = "Security group ID for ECS service"
  type        = string
}
variable "cluster_name" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "container_image" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "ECS security group"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}