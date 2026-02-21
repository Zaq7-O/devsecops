variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "rds_cidr" {
  description = "CIDR block for RDS access from ECS. Should match the RDS subnet or private subnet range."
  type        = string
}

variable "s3_vpc_endpoint_cidr" {
  description = "CIDR block for S3 VPC endpoint or allowed HTTPS egress."
  type        = string
}