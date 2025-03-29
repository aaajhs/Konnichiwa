/* ------------------------------- ECS Cluster ------------------------------ */

resource "aws_ecs_cluster" "komodo_assignment" {
  name = "komodo_assignment"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_cluster_capacity_providers" "cas" {
  cluster_name       = aws_ecs_cluster.komodo_assignment.name
  capacity_providers = [aws_ecs_capacity_provider.cas.name]
}

resource "aws_ecs_capacity_provider" "cas" {
  name = "cas"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_autoscaling_group.arn
  }
}

/* ------------------------------- ECS Service ------------------------------ */

resource "aws_ecs_service" "konnichiwa" {
  name            = "konnichiwa"
  cluster         = aws_ecs_cluster.komodo_assignment.id
  task_definition = aws_ecs_task_definition.konnichiwa_task_definition.arn
  desired_count   = local.desired_task_count

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  depends_on = [aws_iam_role_policy.ecs_service_role_policy]
}

/* -------------------- Roles & Policies for ECS Service -------------------- */

resource "aws_iam_role" "ecs_service_role" {
  name               = "ecs_service_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_policy.json
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", ]
    }
  }
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = data.aws_iam_policy_document.ecs_service_role_policy.json
  role   = aws_iam_role.ecs_service_role.id
}

data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:DescribeTags",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutSubscriptionFilter",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

/* --------------------------- ECS Task Definition -------------------------- */

resource "aws_ecs_task_definition" "konnichiwa_task_definition" {
  family             = "konnichiwa_task_definition"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_iam_role.arn
  network_mode       = "bridge"

  container_definitions = jsonencode([
    {
      name      = "${local.container_name}"
      image     = "${aws_ecr_repository.ecr.repository_url}:${local.image_tag}"
      cpu       = "${local.container_cpu}"
      memory    = "${local.container_memory}"
      essential = true

      healthCheck = {
        command = ["CMD-SHELL", "python -c 'import urllib.request; exit(0) if urllib.request.urlopen(\"http://localhost:4000/health\").getcode() == 200 else exit(1)'"]
      }
      portMappings = [
        {
          containerPort = "${local.container_port}"
          hostPort      = "${local.container_port}"
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "${local.secret_name}"
          valueFrom = "arn:aws:ssm:${local.region}:${local.aws_account_id}:parameter/${local.secret_name}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "${local.container_log_group}",
          "awslogs-region"        = "${local.region}",
          "awslogs-stream-prefix" = "${local.container_log_stream_prefix}"
        }
      }
    }
  ])
}

/* ---------------- Roles & Policies for ECS Task Definition ---------------- */

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}

data "aws_iam_policy_document" "task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_iam_role" {
  name               = "ecs_task_iam_role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}

resource "aws_iam_policy" "ssm_read" {
  name        = "ssm_read_parameter_policy"
  description = "Allows ECS tasks to read SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${local.region}:${local.aws_account_id}:parameter/${local.secret_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_read" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_read.arn
}
