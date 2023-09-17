data "aws_availability_zones" "available" {}

locals {
  name    = "ejs-bp-test"
  project = "ecs-module-bp"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Name    = local.name
    Project = local.project
    "owner" = "bp-instance"
  }

}

###################################################################### CLUSTER

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.2"

  cluster_name = local.name

  cluster_settings = {
    "name" : "containerInsights",
    "value" : "enabled"
  }

  cloudwatch_log_group_retention_in_days = 90
  create_cloudwatch_log_group            = true

  create_task_exec_policy               = true # Create IAM policy for task execution (Uses Managed AmazonECSTaskExecutionRolePolicy)
  default_capacity_provider_use_fargate = true # Use Fargate as default capacity provider

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.name}"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
  tags = local.tags
}






module "product_service" {
  source                 = "terraform-aws-modules/ecs/aws//modules/service"
  version                = "5.2.2"
  name                   = local.name
  family                 = local.name #unique name for task defination
  cluster_arn            = module.ecs_cluster.arn
  launch_type            = "FARGATE"
  cpu                    = 1024
  memory                 = 2048
  create_iam_role        = true # ECS Service IAM Role: Allows Amazon ECS to make calls to your load balancer on your behalf.
  create_task_definition = true
  create_security_group  = true
  create_tasks_iam_role  = true #ECS Task Role
  desired_count          = 1
  enable_autoscaling     = true
  enable_execute_command = true
  force_new_deployment   = true

  network_mode = "awsvpc"



  container_definitions = {

    (var.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "426857564226.dkr.ecr.us-east-1.amazonaws.com/ecr-image-bp:latest"
      interactive = true
      port_mappings = [
        {
          name          = local.name
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      enable_cloudwatch_logging = true
      memory_reservation        = 100
    }

  }

  subnet_ids = module.vpc.private_subnets




  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}


resource "aws_security_group" "ecs_ssh_sg" {
  name        = "ecs-ssh-sg"
  description = "Security group for SSH access to ECS containers"
  vpc_id      = module.vpc.vpc_id

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

}



resource "aws_instance" "bastion_host" {
  ami           = "ami-04cb4ca688797756f" 
  instance_type = "t2.micro"            
  subnet_id     = module.vpc.public_subnets[0] 
  # associate_public_ip_address = "true"
  key_name      = "hackathon"            
  vpc_security_group_ids = [aws_security_group.ecs_ssh_sg.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "8"
    delete_on_termination = true
  }
  volume_tags = local.tags
  tags = {
    Name    = "bastion-host"
    Project = local.project
    owner = "binay"
  }
}


resource "aws_iam_role" "ssm_instance_role" {
  name = "ssm-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"

  role = aws_iam_role.ssm_instance_role.name
}
