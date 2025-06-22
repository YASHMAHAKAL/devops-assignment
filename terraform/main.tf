terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-new"
    key            = "dev/devops-assignment.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "devops-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_exec_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  lifecycle {
    create_before_destroy = true
    ignore_changes         = [name]
  }
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_ssm_policy" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend"
  retention_in_days = 1
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/backend"
  retention_in_days = 1
  lifecycle {
    prevent_destroy = false
  }
}

# VPC Configuration
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.1.1"
  name                 = "devops-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_dns_hostnames = true
  enable_nat_gateway   = false
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "yash-devops-assignment-alb-logs"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "ALB Logs Bucket"
  }
}

resource "aws_s3_bucket_policy" "alb_logging_policy" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSALBLoggingPermissions",
        Effect    = "Allow",
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}


# Cloud Map DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "dev_namespace" {
  name        = "dev"
  description = "ECS Cloud Map namespace for service discovery"
  vpc         = module.vpc.vpc_id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow ALB HTTP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ALB HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Allow traffic to frontend from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow traffic to backend from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Frontend Target Group
resource "aws_lb_target_group" "frontend_tg" {
  name         = "frontend-tg"
  port         = 3000
  protocol     = "HTTP"
  vpc_id       = module.vpc.vpc_id
  target_type  = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# Backend Target Group and Listener Rule
resource "aws_lb_target_group" "backend_tg" {
  name         = "backend-tg"
  port         = 8000
  protocol     = "HTTP"
  vpc_id       = module.vpc.vpc_id
  target_type  = "ip"
  health_check {
    path                = "/api/message"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener_rule" "backend_listener_rule" {
  listener_arn = aws_lb_listener.frontend_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# ECS Task Definitions and Services
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_exec_role.arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/frontend-app:${var.image_tag}"
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.frontend.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_exec_role.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/backend-app:${var.image_tag}"
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.backend.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_service_discovery_service" "backend_discovery" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dev_namespace.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "frontend_service" {
  name                   = "frontend-service"
  cluster                = aws_ecs_cluster.app_cluster.id
  task_definition        = aws_ecs_task_definition.frontend_task.arn
  launch_type            = "FARGATE"
  desired_count          = 2
  enable_execute_command = true

  network_configuration {
    subnets         = module.vpc.public_subnets
    security_groups = [aws_security_group.frontend_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.frontend_listener]
}

resource "aws_ecs_service" "backend_service" {
  name                   = "backend-service"
  cluster                = aws_ecs_cluster.app_cluster.id
  task_definition        = aws_ecs_task_definition.backend_task.arn
  launch_type            = "FARGATE"
  desired_count          = 2
  enable_execute_command = true

  network_configuration {
    subnets         = module.vpc.public_subnets
    security_groups = [aws_security_group.backend_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener_rule.backend_listener_rule]

  service_registries {
    registry_arn = aws_service_discovery_service.backend_discovery.arn
  }
}
