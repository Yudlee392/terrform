# VPC ID
output "vpc_id" {
  description = "ID của VPC"
  value       = aws_vpc.fresher_duylnd_vpc.id
}

# Public Subnets
output "public_subnets" {
  description = "Các subnet công khai (public) trong VPC"
  value       = [
    aws_subnet.fresher_duylnd_public_az1.id,
    aws_subnet.fresher_duylnd_public_az2.id
  ]
}

# Private Subnets
output "private_subnets" {
  description = "Các subnet riêng tư (private) trong VPC"
  value       = [
    aws_subnet.fresher_duylnd_private_az1.id,
    aws_subnet.fresher_duylnd_private_az2.id
  ]
}

# ALB DNS Name
output "alb_dns_name" {
  description = "DNS Name của Application Load Balancer"
  value       = aws_lb.fresher_duylnd_alb.dns_name
}

# Target Group ARN
output "target_group_arn" {
  description = "ARN của Target Group"
  value       = aws_lb_target_group.fresher_duylnd_tg.arn
}

# ECS Cluster Name
output "ecs_cluster_name" {
  description = "Tên của ECS Cluster"
  value       = aws_ecs_cluster.sv_terra_cluster.name
}

# ECS Service Name
output "ecs_service_name" {
  description = "Tên của ECS Service"
  value       = aws_ecs_service.fresher_duylnd_service.name
}

# # Route 53 Alias Record
# output "route53_alias" {
#   description = "Tên miền của bản ghi Route 53 trỏ đến ALB"
#   value       = aws_route53_record.alb_alias.fqdn
# }

# NAT Instance ID
output "nat_instance_id" {
  description = "Instance ID của NAT Instance"
  value       = aws_instance.nat_instance.id
}
