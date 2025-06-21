output "alb_dns_name" {
  description = "Public URL to access the app"
  value       = aws_lb.app_alb.dns_name
}

