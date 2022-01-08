output "public_url" {
  description = "URL of the static website"
  value       = aws_s3_bucket.bucket.website_endpoint
}

output "hosted_zone_id" {
  value = aws_s3_bucket.bucket.hosted_zone_id
}

output "website_domain" {
  value = aws_s3_bucket.bucket.website_domain
}

output "domain_name" {
  value = aws_s3_bucket.bucket.bucket_domain_name
}