# Creates the S3 bucket, adds all files from src, and makes it public.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.name
}

resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.bucket
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.allow_public_get.json
}

data "aws_iam_policy_document" "allow_public_get" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"
    ]
    sid = "PublicReadGetObject"
  }
}

module "template_files" {
  # Calculates the content_type of each file.
  # https://registry.terraform.io/modules/hashicorp/dir/template/latest
  source   = "hashicorp/dir/template"
  base_dir = var.source_folder
}

resource "aws_s3_bucket_object" "static_files" {
  # Loads all files to the s3 bucket
  for_each     = module.template_files.files
  bucket       = aws_s3_bucket.bucket.id
  key          = each.key
  content_type = each.value.content_type
  source       = each.value.source_path
  content      = each.value.content
  etag         = each.value.digests.md5
}


# Log events from the bucket

# resource "aws_s3_bucket" "logging" {
#   bucket = "${var.name}-logs"
# }

# resource "aws_s3_bucket_logging" "logging" {
#   bucket = aws_s3_bucket.bucket.id

#   target_bucket = aws_s3_bucket.logging.id
#   target_prefix = "log/"
# }

# resource "aws_s3_bucket_acl" "logging" {
#   bucket = aws_s3_bucket.logging.id
#   acl    = "log-delivery-write"
# }