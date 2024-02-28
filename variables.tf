# variable "AWS_ACCESS_KEY_ID" {
#   type = string
#   description = "ACCESS KEY-ID for AWS Credential"
# }

locals {
  region = "ca-central-1"
  app-name = "hasty-paste"
  app-internal-port = 8000
  admin-cidr = "192.222.189.20/32"
  aws-cidr = "0.0.0.0/0"
}