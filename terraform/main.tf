resource "aws_iam_role" "ecs_execution" {
  name = "${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


module "networking" {
  source               = "./modules/networking"
  vpc_id               = module.vpc.vpc_id
  environment          = var.environment
  rds_cidr             = var.private_subnet_cidr
  s3_vpc_endpoint_cidr = var.s3_vpc_endpoint_cidr
}

module "alb" {
  source = "./modules/alb"
  environment           = var.environment
  subnet_ids            = module.vpc.public_subnets
  alb_logs_bucket       = aws_s3_bucket.alb_logs.bucket
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.networking.alb_sg_id
  waf_logs_destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:waf-logs" # TODO: Replace with your actual log destination ARN
}

module "database" {
  source                          = "./modules/database"
  subnet_ids                      = module.vpc.database_subnets
  rds_security_group_id           = module.networking.rds_sg_id
  environment                     = var.environment
  db_name                         = var.db_name
  db_username                     = var.db_username
  db_password                     = var.db_password
  performance_insights_kms_key_id = var.performance_insights_kms_key_id
  rds_rotation_lambda_arn         = "arn:aws:lambda:us-east-1:123456789012:function:rds-rotation-lambda" # TODO: Replace with your actual Lambda ARN
}

module "ecs" {
  source = "./modules/ecs"
  cluster_name       = "${var.environment}-cluster"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  container_image    = var.container_image
  region             = var.region
  subnet_ids            = module.vpc.private_subnets
  security_group_id     = module.networking.ecs_sg_id
  target_group_arn      = module.alb.target_group_arn
  ecs_security_group_id = module.networking.ecs_sg_id
  db_host               = module.database.rds_endpoint
  db_name               = var.db_name
  db_username           = var.db_username
  db_secret_arn         = module.database.rds_secret_arn
}
module "vpc" {
  source = "../../terraform-aws/modules/vpc"
  name   = var.environment
  cidr   = var.vpc_cidr
  azs    = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  database_subnets = var.database_subnets
  enable_dns_hostnames = true
  enable_dns_support   = true
}


resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.environment}-alb-logs"
  tags = {
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "alb_logs" {
  bucket        = aws_s3_bucket.alb_logs.id
  target_bucket = aws_s3_bucket.alb_logs.id
  target_prefix = "log/"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "alb_logs" {
  description             = "KMS key for ALB logs S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.alb_logs.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_notification" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  # No notification configuration for demo; add Lambda/SNS/SQS for production
}