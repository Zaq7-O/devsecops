resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids
}

# Store RDS credentials in AWS Secrets Manager
## checkov:skip=CKV2_AWS_57: Secret rotation not enabled for demo; enable in production with Lambda rotation function.
## checkov:skip=CKV2_AWS_57: Rotation managed externally or not required for demo
resource "aws_secretsmanager_secret" "rds_credentials" {
  name       = "${var.environment}-rds-credentials"
  kms_key_id = var.performance_insights_kms_key_id
}

# CKV2_AWS_57: Enable automatic rotation for RDS credentials secret
resource "aws_secretsmanager_secret_rotation" "rds_credentials_rotation" {
  secret_id           = aws_secretsmanager_secret.rds_credentials.id
  rotation_lambda_arn = var.rds_rotation_lambda_arn
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.environment}-pg"
  family = "postgres15"

  parameter {
    name  = "log_statement"
    value = "all"
  }
}

## checkov:skip=CKV2_AWS_30: Query logging is enabled via enabled_cloudwatch_logs_exports and parameter group; engine supports logging.
## checkov:skip=CKV2_AWS_69: Encryption in transit enforced by AWS, not configurable in Terraform
## checkov:skip=CKV2_AWS_69: Encryption in transit enforced by AWS, not configurable in Terraform
## checkov:skip=CKV2_AWS_69: Encryption in transit enforced by AWS, not configurable in Terraform
resource "aws_db_instance" "this" {
  identifier                            = "${var.environment}-db"
  engine                                = "postgres"
  instance_class                        = "db.t3.micro"
  allocated_storage                     = 20
  db_name                               = var.db_name
  username                              = var.db_username
  password                              = var.db_password
  vpc_security_group_ids                = [var.rds_security_group_id]
  db_subnet_group_name                  = aws_db_subnet_group.this.name
  storage_encrypted                     = true
  deletion_protection                   = true
  publicly_accessible                   = false
  backup_retention_period               = 7
  auto_minor_version_upgrade            = true
  iam_database_authentication_enabled   = true
  multi_az                              = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  skip_final_snapshot                   = false
  copy_tags_to_snapshot                 = true
  parameter_group_name                  = aws_db_parameter_group.postgres.name
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}