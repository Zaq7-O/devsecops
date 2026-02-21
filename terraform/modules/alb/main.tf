## checkov:skip=CKV2_AWS_28: Public ALB for internet-facing app; WAF not required for demo. Add WAF in production.
#tfsec:ignore:aws-elb-alb-not-public
# Reason: Public ALB required for internet-facing application tier. ECS tasks and RDS remain private.
resource "aws_lb" "this" {
  name               = "${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.alb_security_group_id]

  internal                   = false
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  access_logs {
    enabled = true
    bucket  = var.alb_logs_bucket
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

## checkov:skip=CKV_AWS_378: HTTP protocol required for app traffic on port 3000; HTTPS termination handled at ALB.
resource "aws_lb_target_group" "this" {
  name        = "${var.environment}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "3000"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-399"
  }
}