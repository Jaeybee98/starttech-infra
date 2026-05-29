output "alb_dns_name" {
  value       = aws_lb.backend_alb.dns_name
  description = "The public application address endpoint"
}

output "instance_security_group_id" {
  value       = aws_security_group.instance_sg.id
  description = "The security group mapping context for the compute instances"
}

output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "The host address connection string for the Redis cluster cache instance"
}
