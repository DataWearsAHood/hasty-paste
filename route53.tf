# ## Create Route 53 Hosted Zone for the domain of our service including NS records in the top level domain
# resource "aws_route53_zone" "service" {
#   name  = var.domain_name
# }

# resource "aws_route53_record" "service" {
#   zone_id = var.tld_zone_id
#   name    = var.domain_name
#   type    = "NS"
#   ttl     = 300
#   records = [
#     aws_route53_zone.service.name_servers[0],
#     aws_route53_zone.service.name_servers[1],
#     aws_route53_zone.service.name_servers[2],
#     aws_route53_zone.service.name_servers[3]
#   ]
# }

# ## Certificate for Application Load Balancer including validation via CNAME record
# resource "aws_acm_certificate" "alb_certificate" {
#   domain_name               = var.domain_name
#   validation_method         = "DNS"
#   subject_alternative_names = ["*.${var.domain_name}"]
# }

# resource "aws_acm_certificate_validation" "alb_certificate" {
#   certificate_arn         = aws_acm_certificate.alb_certificate.arn
#   validation_record_fqdns = [aws_route53_record.generic_certificate_validation.fqdn]
# }

# ## Certificate for CloudFront Distribution in region us.east-1
# resource "aws_acm_certificate" "cloudfront_certificate" {
#   provider                  = aws.us_east_1
#   domain_name               = var.domain_name
#   validation_method         = "DNS"
#   subject_alternative_names = ["*.${var.domain_name}"]
# }

# resource "aws_acm_certificate_validation" "cloudfront_certificate" {
#   provider                = aws.us_east_1
#   certificate_arn         = aws_acm_certificate.cloudfront_certificate.arn
#   validation_record_fqdns = [aws_route53_record.generic_certificate_validation.fqdn]
# }

# ## We only need one record for the DNS validation for both certificates, as records are the same for all regions
# resource "aws_route53_record" "generic_certificate_validation" {
#   name    = tolist(aws_acm_certificate.alb_certificate.domain_validation_options)[0].resource_record_name
#   type    = tolist(aws_acm_certificate.alb_certificate.domain_validation_options)[0].resource_record_type
#   zone_id = aws_route53_zone.service.id
#   records = [tolist(aws_acm_certificate.alb_certificate.domain_validation_options)[0].resource_record_value]
#   ttl     = 300
# }

# ## Hosted zone for development subdomain of our service
# resource "aws_route53_zone" "environment" {
#   name  = "${var.environment}.${var.domain_name}"
# }

# resource "aws_route53_record" "environment" {
#   zone_id = aws_route53_zone.service.id
#   name    = "${var.environment}.${var.domain_name}"
#   type    = "NS"
#   ttl     = 300
#   records = [
#     aws_route53_zone.environment.name_servers[0],
#     aws_route53_zone.environment.name_servers[1],
#     aws_route53_zone.environment.name_servers[2],
#     aws_route53_zone.environment.name_servers[3]
#   ]
# }

# ## Point A record to CloudFront distribution
# resource "aws_route53_record" "service_record" {
#   name    = "${var.environment}.${var.domain_name}"
#   type    = "A"
#   zone_id = aws_route53_zone.environment.id

#   alias {
#     name                   = aws_cloudfront_distribution.default.domain_name
#     zone_id                = aws_cloudfront_distribution.default.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
