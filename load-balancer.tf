
## Application Load Balancer in public subnets with HTTP default listener that redirects traffic to HTTPS
resource "aws_alb" "alb" {
  name            = "${local.app-name}-ALB"
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public.*.id
}

## Default HTTPS listener that blocks all traffic without valid custom origin header
resource "aws_alb_listener" "alb_default_listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  # port              = "443"
  # protocol          = "HTTPS"
  # certificate_arn   = aws_acm_certificate.alb_certificate.arn
  # ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }
  
  # depends_on = [aws_acm_certificate.alb_certificate]
}

## HTTPS Listener Rule to only allow traffic with a valid custom origin header coming from CloudFront
resource "aws_lb_listener_rule" "http_listener_rule" {
  listener_arn = aws_alb_listener.alb_default_listener_http.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.service_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
  #   host_header {
  #     values = ["${local.app-name}.${var.domain_name}"]
    }
  }

  # condition {
  #   http_header {
  #     http_header_name = "X-Custom-Header"
  #     values           = [var.custom_origin_host_header]
  #   }
  # }
}

## Target Group for our service
resource "aws_alb_target_group" "service_target_group" {
  name                 = "${local.app-name}-TargetGroup"
  port                 = "8000"
  protocol             = "HTTP"
  vpc_id               = aws_vpc.default_vpc.id
  deregistration_delay = 120

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    interval            = "60"
    # matcher             = var.healthcheck_matcher
    # path                = var.healthcheck_endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "30"
  }
  
  depends_on = [aws_alb.alb]
}

## SG for ALB
resource "aws_security_group" "alb" {
  name        = "${local.app-name}_ALB_SecurityGroup"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.default_vpc.id

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${local.app-name}_ALB_SecurityGroup"
  }
}

# data "aws_ec2_managed_prefix_list" "cloudfront" {
#   name = "com.amazonaws.global.cloudfront.origin-facing"
# }

# ## We only allow incoming traffic on HTTP and HTTPS from known CloudFront CIDR blocks
# resource "aws_security_group_rule" "alb_cloudfront_https_ingress_only" {
#   security_group_id = aws_security_group.alb.id
#   description       = "Allow HTTPS access only from CloudFront CIDR blocks"
#   from_port         = 443
#   protocol          = "tcp"
#   prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
#   to_port           = 443
#   type              = "ingress"
# }
