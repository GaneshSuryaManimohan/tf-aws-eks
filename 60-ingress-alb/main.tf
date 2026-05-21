resource "aws_lb" "ingress_alb" {
  name               = "${var.project_name}-${var.environment}-ingress-alb"
  internal           = false #Public ALB
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.ingress_sg_id.value]
  subnets            = split(",", data.aws_ssm_parameter.public_subnet_ids.value) # this will select all private subnets from the comma-separated list
  enable_deletion_protection = false #True for PROD environment
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ingress-alb"
    }
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ingress_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<h1>This is the default response for the INGRESS ALB</h1>"
      status_code  = "200"
  }
}
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ingress_alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn = data.aws_ssm_parameter.acm_certificate_arn.value
  ssl_policy = "ELBSecurityPolicy-2016-08"
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<h1>This is the default response for the INGRESS ALB HTTPS</h1>"
      status_code  = "200"
  }
}
}

resource "aws_lb_target_group" "frontend" {
  name = "${var.project_name}-${var.environment}-frontend-tg"
  port = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  health_check {
    path = "/"
    port = 8080
    protocol = "HTTP"
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
}

resource "aws_lb_listener_rule" "frontend" {
    listener_arn = aws_lb_listener.https.arn
    priority = 100 #less number means higher priority
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.frontend.arn
    }
    condition {
      host_header {
        #expense-surya-devops.online or expense-dev-surya-devops.online goes to frontend target group
        values = ["expense-${var.environment}.${var.zone_name}"]
      }
    }
}

module "zone" {
  source = "terraform-aws-modules/route53/aws"
  create_zone = false # since zone already exists
  records = {
    alb = {
      zone_id = data.aws_route53_zone.existing.zone_id
      name    = "expense-${var.environment}"
      type    = "A"
      allow_overwrite = true
      alias = {
        name                   = aws_lb.ingress_alb.dns_name
        zone_id                = aws_lb.ingress_alb.zone_id
      }
  }
}
}