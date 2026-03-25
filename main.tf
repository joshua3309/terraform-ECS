# ──────────────────────────────────────────────
# VPC AND NETWORKING
# ──────────────────────────────────────────────

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr =  var.vpc_cidr

  azs             = var.az
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway     = var.environment == "dev"
  one_nat_gateway_per_az = var.environment == "prod"

  tags = {
    Terraform = "true"
    Environment = var.environment
  }
}

# Security Groups
resource "aws_security_group" "ecs" {
  name        = "ecs"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = module.vpc.vpc_id
  tags        = { Environment = var.environment }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  from_port                    = var.container_port
  ip_protocol                  = "tcp"
  to_port                      = var.container_port
  referenced_security_group_id = aws_security_group.alb.id
  tags                         = { Environment = var.environment }
}

resource "aws_security_group_rule" "ecs_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Environment = var.environment }
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS to ALB"
  vpc_id      =  module.vpc.vpc_id
  tags        = { Environment = var.environment }
  
  ingress { 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
  ingress { 
    from_port   = 443
    to_port     = 443
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

# ──────────────────────────────────────────────
# LOAD BALANCER
# ──────────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = var.environment == "prod"
  

  /*
  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }
  */

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-alb"
  }

}
 

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      status_code  = "404"
      content_type = "text/plain"
      message_body = "Route not found"
    }
  }
}

resource "aws_lb_target_group" "posts" {
  name        = "posts-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path     = "/health"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group" "threads" {
  name        = "threads-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path     = "/health"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group" "users" {
  name        = "users-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path     = "/health"
    protocol = "HTTP"
  }
}

# Listener Rules
resource "aws_lb_listener_rule" "home" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.posts.arn
  }
}

resource "aws_lb_listener_rule" "posts" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/api/posts/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.posts.arn
  }
}

resource "aws_lb_listener_rule" "threads" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 11

  condition {
    path_pattern {
      values = ["/api/threads/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.threads.arn
  }
}

resource "aws_lb_listener_rule" "users" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 12

  condition {
    path_pattern {
      values = ["/api/users/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.users.arn
  }
}

# ──────────────────────────────────────────────
# IAM ROLES AND INSTANCE PROFILE
# ──────────────────────────────────────────────

data "aws_iam_role" "ecs_instance_role" {
  name = "${var.environment}-ecs-instance-role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.environment}-ecs-instance-profile"
  role = data.aws_iam_role.ecs_instance_role.name
}

# ──────────────────────────────────────────────
# LAUNCH TEMPLATE + AUTO SCALING GROUP + CAPACITY PROVIDER
# ──────────────────────────────────────────────

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.environment}-ecs-"
  image_id      = var.ecs_optimized_ami
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }


  key_name = var.key["name"]
  depends_on = [aws_key_pair.terraform]

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.ecs.id]
  }

  user_data = base64encode(<<-EOT
  #!/bin/bash
  echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOT
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "terraform" {
  key_name   = var.key["name"]
  public_key = var.key["pub"]
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.environment}-ecs-asg"
  desired_capacity    = length(var.az)
  min_size            = length(var.az)
  max_size            = var.asg_max_size
  vpc_zone_identifier = module.vpc.private_subnets
  protect_from_scale_in =true

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.environment}-ec2-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }
}

# ──────────────────────────────────────────────
# ECS CLUSTER + LOGGING + KMS
# ──────────────────────────────────────────────

resource "aws_kms_key" "ecs_kms" {
  description             = "aws kms key for ecs"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_cloudwatch" {
  name = "${var.environment}-ecs_cloudwatch-log-group"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs_kms.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_cloudwatch.name
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {Environment = var.environment}

}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    aws_ecs_capacity_provider.ec2.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }
}

# ──────────────────────────────────────────────
# ECS TASK ROLES
# ──────────────────────────────────────────────

data "aws_iam_role" "ecs_task_execution" {
  name = "${var.environment}-ecs-task-execution-role"
}

data "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"
}

# ──────────────────────────────────────────────
# ECS TASK DEFINITIONS
# ──────────────────────────────────────────────

resource "aws_ecs_task_definition" "posts" {
  family                   = "${var.environment}-mb-posts-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = data.aws_iam_role.ecs_task_role.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  cpu                      = var.posts_task_cpu
  memory                   = var.posts_task_memory
  container_definitions = jsonencode([
    {
      name                   = "mb-posts-container"
      image                  = var.posts_image
#      cpu                    = var.environment == "prod" ? var.posts_container_cpu : null
#      memoryReservation      = var.environment == "prod" ? var.posts_container_memory_reservation : null
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.host_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_cloudwatch.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "posts"
        }
      }
    }

  ])

  tags = {Environment = var.environment}
}

resource "aws_ecs_task_definition" "threads" {
  family                   = "${var.environment}-mb-threads-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = data.aws_iam_role.ecs_task_role.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  cpu                      = var.threads_task_cpu
  memory                   = var.threads_task_memory
  container_definitions = jsonencode([
    {
      name                   = "mb-threads-container"
      image                  = var.threads_image
#      cpu                    = var.environment == "prod" ? var.threads_container_cpu : null
#      memoryReservation      = var.environment == "prod" ? var.threads_container_memory_reservation : null
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.host_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_cloudwatch.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "threads"
        }
      }
    }

  ])

  tags = {Environment = var.environment}
}

resource "aws_ecs_task_definition" "users" {
  family                   = "${var.environment}-mb-users-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = data.aws_iam_role.ecs_task_role.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  cpu                      = var.users_task_cpu
  memory                   = var.users_task_memory
  container_definitions = jsonencode([
    {
      name                   = "mb-users-container"
      image                  = var.users_image
#      cpu                    = var.environment == "prod" ? var.users_container_cpu : null
#      memoryReservation      = var.environment == "prod" ? var.users_container_memory_reservation : null
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.host_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_cloudwatch.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "users"
        }
      }
    }

  ])

  tags = {Environment = var.environment}
}

# ──────────────────────────────────────────────
# ECS SERVICES
# ──────────────────────────────────────────────

resource "aws_ecs_service" "posts" {
  name            = "mb-posts-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.posts.arn
  desired_count   = var.posts_desired_count
  
  ordered_placement_strategy {
  type  = "spread"
  field = "attribute:ecs.availability-zone"
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.posts
  ]

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.posts.arn
    container_name   = "mb-posts-container"
    container_port   = 3000
  }
}

resource "aws_ecs_service" "threads" {
  name            = "mb-threads-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.threads.arn
  desired_count   = var.threads_desired_count

  ordered_placement_strategy {
  type  = "spread"
  field = "attribute:ecs.availability-zone"
  }
  
  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.threads
  ]

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }


  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.threads.arn
    container_name   = "mb-threads-container"
    container_port   = 3000
  }
}

resource "aws_ecs_service" "users" {
  name            = "mb-users-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.users.arn
  desired_count   = var.users_desired_count

  ordered_placement_strategy {
  type  = "spread"
  field = "attribute:ecs.availability-zone"
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.users
  ]

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }



  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.users.arn
    container_name   = "mb-users-container"
    container_port   = 3000
  }
}

# ──────────────────────────────────────────────
# APPLICATION AUTO SCALING – CPU TARGET TRACKING (PROD ONLY)
# ──────────────────────────────────────────────

# Posts service auto scaling
resource "aws_appautoscaling_target" "posts" {
  count = var.environment == "prod" ? 1 : 0

  depends_on         = [aws_ecs_service.posts]
  max_capacity       = var.posts_max_capacity
  min_capacity       = var.posts_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.posts.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "posts_cpu" {
  count = var.environment == "prod" ? 1 : 0

  name               = "${var.environment}-posts-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.posts[0].resource_id
  scalable_dimension = aws_appautoscaling_target.posts[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.posts[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Comments service auto scaling
resource "aws_appautoscaling_target" "threads" {
  count = var.environment == "prod" ? 1 : 0

  depends_on         = [aws_ecs_service.threads]
  max_capacity       = var.threads_max_capacity
  min_capacity       = var.threads_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.threads.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "threads_cpu" {
  count = var.environment == "prod" ? 1 : 0

  name               = "${var.environment}-threads-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.threads[0].resource_id
  scalable_dimension = aws_appautoscaling_target.threads[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.threads[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Requests service auto scaling
resource "aws_appautoscaling_target" "users" {
  count = var.environment == "prod" ? 1 : 0
  
  depends_on         = [aws_ecs_service.users]
  max_capacity       = var.users_max_capacity
  min_capacity       = var.users_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.users.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "users_cpu" {
  count = var.environment == "prod" ? 1 : 0

  name               = "${var.environment}-users-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.users[0].resource_id
  scalable_dimension = aws_appautoscaling_target.users[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.users[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

