# For terraform-plan.yml in GitHub Actions
variable "AWS_ACCESS_KEY_ID" {
  type = string
  description = "ACCESS KEY-ID for AWS Credential"
}

locals {
  region = "ca-central-1"
  az_count = 2
  app-name = "hasty-paste"
  app-internal-port = 8000
  admin-cidr = "192.222.189.20/32"
  aws-cidr = "0.0.0.0/0"  # Required; ca-central-1 IPs break Instance Connect 
  # aws-cidr = "13.34.78.160/27"   # AWS in-region IP-range from https://ip-ranges.amazonaws.com/ip-ranges.json
  vpc-cidr = "10.2.0.0/16"
  manual-ecr-repo-url = "471112741621.dkr.ecr.ca-central-1.amazonaws.com/hasty-paste-manual"
  env-time-zone = "Canada/Eastern"
}