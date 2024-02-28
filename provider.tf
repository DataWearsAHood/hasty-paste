# Adjusted from https://github.com/groorj/aws-dogs-or-cats-demo-iac/tree/main/iac-app

# My terraform provider
provider "aws" {
  region = "ca-central-1"
  profile = "deployer"
  # version = "~> 2.7"
}

# # Terraform state file
# # -- Push tfstate to S3
# terraform {
#   backend "s3" {
#     bucket  = "dogs-or-cats-app"
#     key     = "iac-dogs-or-cats-app/main.tfstate"
#     region  = "ca-central-1"
#     profile = "<your-profile-name>"
#   }
# }

# End;