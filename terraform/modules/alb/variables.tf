variable "waf_logs_destination_arn" {
  description = "ARN of the destination (e.g., CloudWatch log group or Kinesis stream) for WAFv2 logging."
  type        = string
}
