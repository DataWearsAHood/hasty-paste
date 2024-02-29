# Adjusted from https://github.com/groorj/aws-${local.app-name}-demo-iac/tree/main/iac-app

# My terraform provider
provider "aws" {
  region = "${local.region}"
  # profile = "deployer"  # Use locally only
  # version = "~> 2.7"
}

# End;