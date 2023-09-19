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
    # image     = "amazonlinux:latest"
    interactive = true
    port_mappings = [
      {
        name          = local.name
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
    pseudo_terminal = true
    readonly_root_filesystem = false
    enable_cloudwatch_logging = true
    memory_reservation        = 100
    linux_parameters         = var.linux_parameters
    # command = ["ecs-agent", "execute-command"]  # Enable ExecuteCommand
    # linuxParameters= {
    #   "initProcessEnabled": true
    # }

  }
}

  subnet_ids = module.vpc.private_subnets
  
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Product Service Port"
      cidr_blocks              = ["0.0.0.0/0"]
      # source_security_group_id = data.terraform_remote_state.base_resources.outputs.security_group_id
    }

    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
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

resource "aws_iam_role_policy" "task_definition_exec_role-policy" {
  name = "${local.name}-task-definition-role-policy"
  role = module.product_service.tasks_iam_role_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"           
        ],

        "Resource" : "*"
     
      }
    ]
  })
}
