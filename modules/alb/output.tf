output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_id" {
  value = aws_lb.alb.id
}

output "alb_tg_arn" {
  value = aws_lb_target_group.alb_tg.arn
  
}