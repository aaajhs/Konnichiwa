/* ------------------------ Application Load Balancer ----------------------- */

resource "aws_lb" "alb" {
  name                       = "alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  enable_deletion_protection = false

  enable_cross_zone_load_balancing = true
}

resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.alb_ingress_ports

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* ---------------------------- ALB Target Groups --------------------------- */

resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = local.container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "ecs-target-group"
  }
}

resource "aws_lb_listener" "alb_listener" {
  for_each = toset(local.alb_ingress_ports)

  load_balancer_arn = aws_lb.alb.arn
  port              = each.key
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}
