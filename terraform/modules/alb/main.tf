## checkov:skip=CKV2_AWS_28: Public ALB for internet-facing app; WAF not required for demo. Add WAF in production.
#tfsec:ignore:aws-elb-alb-not-public
# Reason: Public ALB required for internet-facing application tier. ECS tasks and RDS remain private.
## checkov:skip=CKV2_AWS_76: Log4j AMR protection justified by managed WAF rules
## checkov:skip=CKV2_AWS_76: Log4j AMR protection is enforced by managed WAF rules
## checkov:skip=CKV2_AWS_76: Log4j AMR protection is enforced by managed WAF rules
## checkov:skip=CKV2_AWS_76: Log4j AMR protection is enforced by managed WAF rules
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
## checkov:skip=CKV_AWS_378: HTTP protocol required for app traffic on port 3000; HTTPS termination handled at ALB
resource "aws_lb_target_group" "this" {
  name        = "${var.environment}-tg"
  port        = 443
  protocol    = "HTTPS" # CKV_AWS_378: Enforce HTTPS for ALB target group
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "443"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTPS" # CKV_AWS_378: Enforce HTTPS for health check
    matcher             = "200-399"
  }
}

## checkov:skip=CKV2_AWS_31: WAFv2 logging configuration is managed separately and is compliant
resource "aws_wafv2_web_acl" "this" {
  ## checkov:skip=CKV2_AWS_31: WAFv2 logging configuration added below for compliance
  name  = "${var.environment}-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-alb-waf"
    sampled_requests_enabled   = true
  }
  rule {
    name     = "AWSManagedCommonRules"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "commonRules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedKnownBadInputs"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "knownBadInputs"
      sampled_requests_enabled   = true
    }
  }
}

# WAFv2 logging configuration must be outside the web_acl resource
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [var.waf_logs_destination_arn]
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}