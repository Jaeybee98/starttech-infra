output "application_load_balancer_url" {
  value = module.compute.alb_dns_name
}

output "cloudfront_cdn_url" {
  value = module.storage.cloudfront_domain_name
}

output "redis_endpoint" {
  value = module.compute.redis_primary_endpoint
}
