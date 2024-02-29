# For terraform-plan.yml in GitHub Actions
variable "AWS_ACCESS_KEY_ID" {
  type = string
  description = "ACCESS KEY-ID for AWS Credential"
}

locals {
  region = "ca-central-1"
  app-name = "hasty-paste"
  app-internal-port = 8000
  admin-cidr = "192.222.189.20/32"
  aws-cidr = "0.0.0.0/0"  # Required; ca-central-1 IPs break Instance Connect 
  # aws-cidr = "13.34.78.160/27"   # AWS in-region IP-range from https://ip-ranges.amazonaws.com/ip-ranges.json
}