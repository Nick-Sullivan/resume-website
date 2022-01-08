
### 

This creates all the AWS resources to hosting a static website.


### Running

Create the long-lived domain variables. Terraform does not support registered domains, so this requires a manual step every time it is destroyed and recreated.
```
cd terraform/website_domain
terraform init
terraform apply
```

- Copy the `delegation_set_id` into the `website_contents/variables.tf` file.

- Open the AWS console (https://console.aws.amazon.com/route53/home#DomainListing:), and edit the name servers to the `name_servers` values. This will take a minute or so to apply.

Create the website contents, which can be destroyed and recreated automatically

```
cd terraform/website_contents
terraform init
terraform apply
```


### Guide I Followed

https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started-s3.html
https://towardsdatascience.com/static-hosting-with-ssl-on-s3-a4b66fb7cd00



### Prerequisites 

- Install git (https://git-scm.com/download/win)

- Installed VSCode
- Installed Live Server extension (https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)

- Install Chocolatey (https://chocolatey.org/install#individual)
- Install Terraform 
- Install AWS CLI

- Add new terraform user in AWS
- Set up Terraform (https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started)
- aws configure
- terraform init
- terraform apply




