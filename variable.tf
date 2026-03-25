variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "dev"
  description = "dev or prod"
  type = string    
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az" {
  type = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  type = list(string)
  default = ["10.0.101.0/24", "10.0.103.0/24"]
}

variable "container_port" {
  description = "port the container listen on"
  type = number
  default = 3000
}  

variable "host_port" {
  description = "host port of the container"
  type = number
  default = 3000
}  

variable "key" {
  description  = ""
  default      = {
    "name"     = "terraform"
    "pub"      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdEffxqS3RQQMR0YyQLKWnAQEEc1ThySJWYUhLf7mhXMcgE9dpkAAV6dtNyhrobYHAD2sOh52EG95j6BnjEJXln5Td1053H8se9T2vTxyrnjNmCs0EHyPg5FCIH32YLVZ2iU/iiWaom+1+pf418ouO1HO+lbOi0jwjmUQ+zLxbYxOs1vGCtN3bzzF6tqOPgjOCX7dNr5IySCreshVZbka7IdQFDbHaoqC2HvXJ371asw7W3CbOF9Frn59orCaRneZduKo5LF7EOtx/8QkCRrueNZOAa/RakqlKbb4KfmwAbcAV9JqcWDc63wETv71+oXWLK+rlcJ3jF338hCNLGBkjY54+wMzQWaqdpvRKxOPd2KjcpaCVqZQ2D0L9pUMSbX7UtCBNM5Iczgp2kquVHWgCONrvPC+dKxxPbRVKV05hk3FfZ3qDtTHTL5HDTu1tdGJXYbWhrrcJxmnqQ3cZ92fdxy3CQ6fsr/Kwg6EoKnKwNu6gm9xqQDg809j/gO98+0M= joshua@gbriel-DESKTOP-UV4ETAU"
  }
}

variable "ecs_optimized_ami" {
  description = "ecs ecs optimized AMI ID" 
  type        = string
  default     = "ami-02c8d3a4a8d981199"
}

variable "instance_type" {
  description = "ec2 instance type for ECS CLUSTER"
  type        = string
  default     = "t3.medium"
}

variable "asg_desired_capacity" {
  type     = number
  default  = 2
}

variable "asg_max_size" {
  type    = number
  default = 5
}

variable "asg_min_size" {
  type    = number 
  default = 1
}

variable "posts_image" {
  type   = string
  description = "docker image for the application including tag"
}

variable "threads_image" {
  type   = string
  description = "docker image for the application including tag"
}

variable "users_image" {
  type   = string
  description = "docker image for the application including tag"
}

variable "posts_task_cpu" {
  description = "cpu units for the task "
  type        =   number
  default     = 512
}

variable "posts_task_memory" {
  description  = "memory for the task in MIB"
  type         = string 
  default      = "1024"
}

variable "threads_task_cpu" {
  description = "cpu units for the task "
  type        =   number
  default     = 512
}

variable "threads_task_memory" {
  description  = "memory for the task in MIB"
  type         = string 
  default      = "1024"
}

variable "users_task_cpu" {
  description = "cpu units for the task "
  type        =   number
  default     = 512
}

variable "users_task_memory" {
  description  = "memory for the task in MIB"
  type         = string 
  default      = "1024"
}

variable "posts_desired_count" {
  description = "inial number of task"
  type    = number 
  default = 1
}

variable "threads_desired_count" {
  description = "inial number of task"
  type    = number 
  default = 1
}

variable "users_desired_count" {
  description = "inial number of task"
  type    = number 
  default = 1
}


/*
variable "posts_container_cpu" {
  type     = string
  default  =  "512"
}

variable "posts_container_memory_reservation" {
  type     = string
  default  =  "1024"
}

variable "threads_container_cpu" {
  type     = string
  default  =  "512"
}

variable "threads_container_memory_reservation" {
  type     = string
  default  =  "1024"
}

variable "users_container_cpu" {
  type     = string
  default  =  "512"
}

variable "users_container_memory_reservation" {
  type     = string
  default  =  "1024"
}
*/

variable "posts_min_capacity" { 
  type    = number
  default = 1
}
variable "posts_max_capacity" { 
  type    = number
  default = 6
}

variable "threads_min_capacity" { 
  type    = number
  default = 1
}
variable "threads_max_capacity" { 
  type    = number
  default = 6
}

variable "users_min_capacity" { 
  type    = number
  default = 1
}
variable "users_max_capacity" { 
  type    = number
  default = 6
}



