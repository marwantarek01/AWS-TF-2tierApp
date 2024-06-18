output "cloudfront_zoneID" {
    value = aws_cloudfront_distribution.my_distribution.hosted_zone_id
  
}

output "cloudfront_domain_name" {
    value = aws_cloudfront_distribution.my_distribution.domain_name
}