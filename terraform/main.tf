module "networking" {
  source      = "./modules/networking"
  vpc_id      = var.vpc_id
  environment = var.environment
  rds_cidr    = var.private_subnet_cidr
  s3_vpc_endpoint_cidr = var.s3_vpc_endpoint_cidr
}

module "alb" {
  source = "./modules/alb"

  environment           = var.environment
  subnet_ids            = var.public_subnet_ids
  alb_security_group_id = module.networking.alb_sg_id
  alb_logs_bucket       = aws_s3_bucket.alb_logs.bucket
  vpc_id                = module.networking.vpc_id
}

module "database" {
  source                          = "./modules/database"
  subnet_ids                      = var.private_subnet_ids
  rds_security_group_id           = module.networking.rds_sg_id
  environment                     = var.environment
  db_name                         = var.db_name
  db_username                     = var.db_username
  db_password                     = var.db_password
  performance_insights_kms_key_id = var.performance_insights_kms_key_id
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name       = "${var.environment}-cluster"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  container_image    = var.container_image
  region             = var.region

  subnet_ids            = var.private_subnet_ids
  security_group_id     = module.networking.ecs_sg_id
  target_group_arn      = module.alb.target_group_arn
  ecs_security_group_id = module.networking.ecs_sg_id
  db_host               = module.database.rds_endpoint
  db_name               = var.db_name
  db_username           = var.db_username
  db_secret_arn         = module.database.rds_secret_arn
}

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
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

resource "aws_kms_key" "alb_logs" {
  description             = "KMS key for ALB logs S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
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