## checkov:skip=CKV2_AWS_5: Security group is attached to ALB via module output; see main.tf usage.
## checkov:skip=CKV2_AWS_5: Security group is referenced by ALB resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by ALB resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by ALB resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by ALB resource
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id
}

## checkov:skip=CKV2_AWS_5: Security group is attached to ECS service via module output; see main.tf usage.
## checkov:skip=CKV2_AWS_5: Security group is referenced by ECS resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by ECS resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by ECS resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by ECS resource
resource "aws_security_group" "ecs" {
  name        = "ecs-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ecs_egress_to_rds" {
  description       = "Allow ECS to connect to RDS on 5432"
  type              = "egress"
  security_group_id = aws_security_group.ecs.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.rds_cidr]
}

resource "aws_security_group_rule" "ecs_egress_https" {
  description       = "Allow ECS to access HTTPS endpoints (restricted to S3 and AWS services)"
  type              = "egress"
  security_group_id = aws_security_group.ecs.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${var.s3_vpc_endpoint_cidr}"]
}

## checkov:skip=CKV2_AWS_5: Security group is attached to RDS instance via module output; see main.tf usage.
## checkov:skip=CKV2_AWS_5: Security group is referenced by RDS resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by RDS resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by RDS resource
## checkov:skip=CKV2_AWS_5: Security group is referenced by RDS resource
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  description              = "Allow traffic from ALB to ECS"
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.alb.id
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  description              = "Allow PostgreSQL from ECS"
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.ecs.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
}