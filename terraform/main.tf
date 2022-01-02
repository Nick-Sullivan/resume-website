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

locals {
  url           = "nickdavesullivan.com"
  url_secondary = "www.${local.url}"
}

module "s3_bucket_primary" {
  source         = "./modules/website_s3_bucket"
  url            = local.url
  index_document = "index.html"
  source_folder  = "${path.root}/../src"
}

resource "aws_s3_bucket" "secondary" {
  bucket = local.url_secondary
  website {
    redirect_all_requests_to = "http://${local.url}"
  }
}


# Route 53 routing

resource "aws_route53_zone" "website" {
  name = local.url
}

resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.website.zone_id
  name    = local.url
  type    = "A"
  alias {
    name                   = module.s3_bucket_primary.website_domain
    zone_id                = module.s3_bucket_primary.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_secondary" {
  zone_id = aws_route53_zone.website.zone_id
  name    = local.url_secondary
  type    = "A"
  alias {
    name                   = aws_s3_bucket.secondary.website_domain
    zone_id                = aws_s3_bucket.secondary.hosted_zone_id
    evaluate_target_health = false
  }
}