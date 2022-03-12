terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.5.0"
    }
  }
  backend "s3" {
    bucket = "nicks-terraform-states"
    key    = "resume_website/website_contents/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

locals {
  url     = var.domain
  url_www = "www.${local.url}"
  tags = {
    Project = "Website CV"
  }
}

provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
  default_tags {
    tags = local.tags
  }
}

# Create a public S3 bucket to host the files.

module "s3_bucket" {
  source        = "./../modules/website_s3_bucket"
  name          = local.url
  source_folder = "${path.root}/../../src"
}

# Create a hosted zone for our domain and point it to CloudFront

resource "aws_route53_zone" "website" {
  name              = local.url
  delegation_set_id = var.delegation_set_id
}

module "alias" {
  source        = "./../modules/website_alias"
  name          = local.url
  zone_id       = aws_route53_zone.website.zone_id
  alias_name    = module.cloudfront.domain_name
  alias_zone_id = module.cloudfront.hosted_zone_id
}

module "alias_www" {
  source        = "./../modules/website_alias"
  name          = local.url_www
  zone_id       = aws_route53_zone.website.zone_id
  alias_name    = module.cloudfront.domain_name
  alias_zone_id = module.cloudfront.hosted_zone_id
}

# Create a CloudFront distribution that redirects to our S3 bucket, and allows SSL

module "cloudfront" {
  source            = "./../modules/website_cloudfront"
  domain_name       = local.url
  alternative_names = [local.url_www]
  s3_url            = module.s3_bucket.public_url
  zone_id           = aws_route53_zone.website.zone_id
  providers = {
    aws = aws.us-east-1
  }
}
