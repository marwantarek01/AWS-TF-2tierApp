#create alb
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_sg_id
  subnets            = var.public_subnets_ids
  tags = {
    Name = "alb"
  }
}

#create application load balancer target group
resource "aws_lb_target_group" "alb_tg" {
  name     = "alb_tg"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
   lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "alb-tg"
  }

}

# create a listener on port 80 with fwd action
resource "aws_lb_listener" "alb_listner" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}