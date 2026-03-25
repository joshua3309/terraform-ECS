environment = "dev"

posts_image    = "033481624720.dkr.ecr.us-east-1.amazonaws.com/posts:latest"
threads_image = "033481624720.dkr.ecr.us-east-1.amazonaws.com/threads:latest"
users_image = "033481624720.dkr.ecr.us-east-1.amazonaws.com/users:latest"

# posts_min_capacity = 1
# posts_max_capacity = 3

# threads_min_capacity = 1
# threads_max_capacity = 3

# users_min_capacity = 1
# users_max_capacity = 13

# Adjust task/container values as needed
posts_task_cpu    = "512"
posts_task_memory = "1024"
# posts_container_cpu               = "512"
# posts_container_memory_reservation = "1024"

posts_desired_count   = 1
threads_desired_count = 1
users_desired_count   = 1