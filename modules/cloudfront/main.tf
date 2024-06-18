#..................................cloudfront..................................

resource "aws_cloudfront_distribution" "my_distribution" {
  enabled = true
  origin {
    domain_name = var.alb_dns_name
    origin_id = var.alb_id
     custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [ "TLSv1.2" ]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD" ]
    cached_methods         = ["GET", "HEAD" ]
    target_origin_id       = var.alb_id
    viewer_protocol_policy = "redirect-to-https"  
  }
   restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  
}

