terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Project = "Website CV"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
  default_tags {
    tags = {
      Project = "Website CV"
    }
  }
}

locals {
  url           = var.url
  url_secondary = "www.${local.url}"
}

# File hosting

module "s3_bucket_primary" {
  source         = "./../modules/website_s3_bucket"
  url            = local.url
  index_document = "index.html"
  source_folder  = "${path.root}/../../src"
}

resource "aws_s3_bucket" "secondary" {
  bucket = local.url_secondary
  website {
    redirect_all_requests_to = "http://${local.url}"
  }
}

# DNS routing

resource "aws_route53_zone" "website" {
  name              = local.url
  delegation_set_id = var.delegation_set_id
}


### Option 1: Alias to S3 bucket (can't use SSL, but simpler)

resource "aws_route53_record" "alias" {
  zone_id = aws_route53_zone.website.zone_id
  name    = local.url
  type    = "A"
  alias {
    name                   = module.s3_bucket_primary.website_domain
    zone_id                = module.s3_bucket_primary.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_secondary" {
  zone_id = aws_route53_zone.website.zone_id
  name    = local.url_secondary
  type    = "A"
  alias {
    name                   = aws_s3_bucket.secondary.website_domain
    zone_id                = aws_s3_bucket.secondary.hosted_zone_id
    evaluate_target_health = false
  }
}

### Option 2: Alias to CloudFront (allow SSL)

# # Allow HTTPS

# resource "aws_acm_certificate" "cert" {
#   # Must be in us-east-1 for use by CloudFront
#   provider                  = aws.us-east-1
#   domain_name               = local.url
#   subject_alternative_names = [local.url_secondary]
#   validation_method         = "DNS"
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "https" {
#   # Create CNAME entries to allow validation of the certificate
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.website.zone_id
# }

# resource "aws_acm_certificate_validation" "https" {
#   provider                = aws.us-east-1
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.https : record.fqdn]
# }

# # Alias to CloudFront

# resource "aws_route53_record" "alias" {
#   zone_id = aws_route53_zone.website.zone_id
#   name    = local.url
#   type    = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.s3_distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# resource "aws_route53_record" "alias_ipv6" {
#   zone_id = aws_route53_zone.website.zone_id
#   name    = local.url
#   type    = "AAAA"
#   alias {
#     name                   = aws_cloudfront_distribution.s3_distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# # Cloudfront

# resource "aws_cloudfront_distribution" "s3_distribution" {
#   # This can take a few minutes to deploy
#   # aliases             = [local.url, local.url_secondary]
#   comment             = "Online resume"
#   default_root_object = "index.html"
#   enabled             = true
#   is_ipv6_enabled     = true
#   price_class         = "PriceClass_100"

#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = "CV"
#     viewer_protocol_policy = "allow-all"
#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }
#   }

#   origin {
#     #domain_name = module.s3_bucket_primary.domain_name    # nickdavesullivan.com.s3.amazonaws.com
#     #domain_name = module.s3_bucket_primary.website_domain # s3-website-ap-southeast-2.amazonaws.com
#     domain_name = module.s3_bucket_primary.public_url      # nickdavesullivan.com.s3-website-ap-southeast-2.amazonaws.com
#     origin_id   = "CV"
#     custom_origin_config {
#       http_port = 80
#       https_port = 443
#       origin_keepalive_timeout = 5
#       origin_protocol_policy = "http-only"
#       origin_read_timeout = 30
#       origin_ssl_protocols = [
#         "TLSv1",
#         "TLSv1.1",
#         "TLSv1.2",
#       ]

#     }
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     acm_certificate_arn = aws_acm_certificate.cert.arn
#     ssl_support_method  = "sni-only"
#   }
# }
