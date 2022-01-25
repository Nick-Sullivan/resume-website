#

This creates all the AWS resources to host a static website.


# Running

1. Create an s3 bucket to store your terraform state files

   We shouldn't commit state files to source control, as they can store passwords in plaintext. I use a private S3 bucket to store all the state files.

   Edit the `backend "s3"` sections of `website_contents/main.tf` and `website_domain/main.tf`. Or if you want to store state files locally, comment out those sections.

1. [Register a domain.](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register-update.html)

   When you register a domain, AWS assigns the domain a *delegation set*. A delegation set is four name servers, responsible for converting from human-readable URLs into IP addresses.

   AWS also automatically creates a hosted zone, a collection of records belonging to a single domain. The name server records are populated with the delegation set for our domain.

   When it comes to terraform, there are two things to note

   - Terraform **does not** support creation/deletion of domains. Domains aren't designed to be regularly destroyed.
   - Terraform **does** support creation/deletion of hosted zones. But, it will generate a **new** delegation set. If the delegation set does not match the one used by the domain, it will not work.

   The workaround is in the folder `website_domain`, which creates a new delegation set. 

1. Manually delete the automatically created [hosted zone](https://console.aws.amazon.com/route53/v2/hostedzones#).

1. Create a new hosted zone, managed by terraform:
   ```bash
   cd terraform/website_domain
   terraform init
   terraform apply
   ```

1. Manually copy the name servers displayed in the output, and paste them into AWS ([Route53](https://console.aws.amazon.com/route53/home#DomainListing:) -> Registered domains -> Click your domain -> Add or edit name servers)

1. Save the delegation set ID as a variable in `website_contents/variables.tf`, and edit the name your domain.

   This means we can create/destroy all resources in the `website_contents` (including the hosted zone), and be confident that the name servers will match up with the domain. If we ever destroy `website_domain`, we will need to manually edit the domain name servers again.

1. Create the rest of the resources
   ```bash
   cd terraform/website_contents
   terraform init
   terraform apply
   ```

   This creates an S3 bucket with our files, a CloudFront distribution so anyone can access it, and all permissions/redirects to connect the two.


# Notes

There are two common ways to host a public website in S3

1. Alias to S3 bucket 

   - Requires that the bucket is the same name as your domain (nickdavesullivan.com)
   - Any redirects require an extra bucket (e.g. www.nickdavesullivan.com)
   - Can't use SSL
   - Simpler

1. Alias to CloudFront (used in this repo)

   - Bucket can be any name
   - Only need a single bucket
   - More complicated 

# Prerequisites 

- [git](https://git-scm.com/download/win)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

# Guides I used

https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started-s3.html
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-cloudfront-distribution.html
https://towardsdatascience.com/static-hosting-with-ssl-on-s3-a4b66fb7cd00






