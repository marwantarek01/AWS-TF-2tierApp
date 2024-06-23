resource "aws_route53_zone" "my-zone" {
  name = var.appname
  
}

resource "aws_route53_record" "cloudfront" {
  zone_id = aws_route53_zone.my-zone.id
  name = "cloudfront record"
  type = "A"
  alias {
    zone_id = var.cloudfront_zoneID
    name = var.cloudfront_domain_name
    evaluate_target_health = false
  }
  
}