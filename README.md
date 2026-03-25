# Scalable Microservices Infrastructure for a Payment Processing Platform

## Overview
This project implements a production-ready AWS infrastructure for a microservices-based payment platform using Terraform. It is designed for high availability, scalability, and environment-based deployment (dev vs prod).

---

## Architecture

### Services
- **Posts Service** → `/api/posts/*`
- **Threads Service** → `/api/threads/*`
- **Users Service** → `/api/users/*`

### Routing
| Path              | Service  |
|------------------|----------|
| `/`              | Posts    |
| `/api/posts/*`   | Posts    |
| `/api/threads/*` | Threads  |
| `/api/users/*`   | Users    |

---

## Infrastructure

### Networking
- Custom VPC with public and private subnets
- Multi-AZ deployment
- NAT Gateway:
  - Dev: Single NAT
  - Prod: One NAT per AZ

---

### Compute (ECS + EC2)
- ECS Cluster (EC2 launch type)
- Auto Scaling Group (ASG)
- Capacity Provider enabled

#### Task Placement Strategy
```hcl
ordered_placement_strategy {
  type  = "spread"
  field = "attribute:ecs.availability-zone"
}

---------

Load Balancer
* Application Load Balancer (ALB)
* Path-based routing
* Health checks per service

---------

Auto Scaling
ECS Service Scaling (Production Only)
* Target tracking based on CPU utilization
* Target: 70% CPU
* Automatically adjusts task count

EC2 Scaling
* Managed by ECS Capacity Provider
* Scales EC2 instances when cluster capacity is insufficient

----------

Environment Strategy
Environment	                              Behavior
Dev	                                      Minimal resources, no auto scaling
Prod	                                    Full auto scaling enabled

---------------

Key Features
* Infrastructure as Code (Terraform)
* Multi-service microservices architecture
* High availability across Availability Zones
* Automatic scaling at both:
   * Application level (ECS tasks)
   * Infrastructure level (EC2 instances)
* Secure networking with private subnets

---------

Deployment
Initialize Terraform

</> Bash
terraform init
