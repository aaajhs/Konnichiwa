/* -------------------- ECS EC2 Instance Launch Template -------------------- */

resource "aws_launch_template" "ecs_node" {
  name                   = "ecs_node"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = local.instance_type
  key_name               = aws_key_pair.ecs_node_key_pair.key_name
  user_data              = base64encode(templatefile("user_data.sh", { ecs_cluster_name = aws_ecs_cluster.komodo_assignment.name }))
  update_default_version = true

  network_interfaces {
    associate_public_ip_address = true # Necessary for internet access, to communicate with ECS
    security_groups             = [aws_security_group.ecs_node.id]
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_node_profile.arn
  }

  monitoring {
    enabled = true
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_key_pair" "ecs_node_key_pair" {
  key_name   = "ecs_node_key_pair"
  public_key = file(local.public_key_location)
}

resource "aws_security_group" "ecs_node" {
  name   = "ecs_node"
  vpc_id = aws_vpc.main.id

  # # Uncomment block for SSH access to instances
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  dynamic "ingress" {
    for_each = local.ec2_ingress_ports

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [aws_subnet.public_a.cidr_block, aws_subnet.public_c.cidr_block]
    }
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* ------------------- Roles & Policies for EC2 Instances ------------------- */

resource "aws_iam_instance_profile" "ecs_node_profile" {
  name = "ecs_node_profile"
  role = aws_iam_role.ecs_node_role.id
}

resource "aws_iam_role" "ecs_node_role" {
  name               = "ecs_node"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_policy.json
}

data "aws_iam_policy_document" "ecs_node_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_node_policy_attachment" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

/* --------------------------- Auto-Scaling Group --------------------------- */

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name                = "ecs_autoscaling_group"
  desired_capacity    = local.desired_instance_count
  max_size            = local.max_instance_count
  min_size            = local.min_instance_count
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_a.id]
  health_check_type   = "EC2"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.ecs_node.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "ecs_autoscaling_group"
    propagate_at_launch = true
  }
}
