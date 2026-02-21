output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_security_group_id" {
  value = module.networking.alb_sg_id
}

output "ecs_security_group_id" {
  value = module.networking.ecs_sg_id
}

output "rds_security_group_id" {
  value = module.networking.rds_sg_id
}

output "rds_endpoint" {
  value = module.database.rds_endpoint
}