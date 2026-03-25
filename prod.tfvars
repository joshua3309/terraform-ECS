# ──────────────────────────────────────────────
# General
# ──────────────────────────────────────────────
environment = "prod"
region      = "us-east-1"

# ──────────────────────────────────────────────
# VPC (adjust CIDR if needed for prod isolation)
# ──────────────────────────────────────────────
vpc_cidr         = "10.10.0.0/16"
public_subnets   = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnets  = ["10.10.11.0/24", "10.10.12.0/24"]

# ──────────────────────────────────────────────
# Container Images (use stable/prod tags)
# ──────────────────────────────────────────────
posts_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/posts:prod-v1.2.3"
threads_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/comments:prod-v1.2.3"
users_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/requests:prod-v1.2.3"

# ──────────────────────────────────────────────
# Task-level resources (higher – what cluster sees)
# ──────────────────────────────────────────────
posts_task_cpu    = "1024"
posts_task_memory = "2048"

threads_task_cpu    = "1024"
threads_task_memory = "2048"

users_task_cpu    = "1024"
users_task_memory = "2048"

# ──────────────────────────────────────────────
# Container-level resources (actual microservice allocation)
# ──────────────────────────────────────────────
# posts_container_cpu               = "512"
# posts_container_memory_reservation = "1024"

# threads_container_cpu               = "512"
# threads_container_memory_reservation = "1024"

# users_container_cpu               = "512"
# users_container_memory_reservation = "1024"

# ──────────────────────────────────────────────
# Initial desired count
# ──────────────────────────────────────────────
posts_desired_count    = 2
threads_desired_count = 2
userss_desired_count = 2

# ──────────────────────────────────────────────
# Application Auto Scaling limits (per service)
# ──────────────────────────────────────────────
# posts_min_capacity    = 1
# posts_max_capacity    = 1

# threads_min_capacity = 1
# threads_max_capacity = 8

# users_min_capacity = 3
# users_max_capacity = 20

# ──────────────────────────────────────────────
# EC2 / ASG (more conservative in prod)
# ──────────────────────────────────────────────
instance_type        = "t3.medium"          # bigger instance for more tasks per host
ecs_optimized_ami    = "ami-0933f1385008d33c4"  # ← replace with actual latest prod AMI
asg_min_size         = 2
asg_max_size         = 5
asg_desired_capacity = 2

# Optional: override if different in prod
app_port = 3000