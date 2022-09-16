# ECS Cluster  ####################################################################################

resource "aws_ecs_cluster" "cluster" {
  name = "${var.owner}-cluster"
  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-cluster"
    },
  )
}


# Task execution role  ############################################################################

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_task_assumerole_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test = "ArnLike"

      values = [
        "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      ]

      variable = "aws:SourceArn"
    }

    condition {
      test = "StringEquals"

      values = [
        data.aws_caller_identity.current.account_id
      ]

      variable = "aws:SourceAccount"
    }
  }
}

data "aws_iam_policy" "ecsTaskExecutionRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.owner}-task-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assumerole_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-default-task-policy" {
  role       = aws_iam_role.task_role.name
  policy_arn = data.aws_iam_policy.ecsTaskExecutionRolePolicy.arn
}


# ECS Task Definition  ############################################################################

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.owner}-app"
  requires_compatibilities = ["FARGATE"]
  
  # With Fargate network_mode must be awsvpc
  network_mode             = "awsvpc"
  
  # Required when requires_compatibilities = ["FARGATE"]
  # Note: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  cpu                      = 256
  memory                   = 512

  # operating_system_family is also required with FARGATE:
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  # Since we don't have an EC2 instance to inherit the role from, we need to explicitly set one for the task or it won't be able to pull images from ECR
  execution_role_arn       = aws_iam_role.task_role.arn

  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-app"
    },
  )

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.owner}-app",
    "image": "${var.ecr_image}",
    "cpu": 256,
    "memory": 512,
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 9000,
        "hostPort": 9000
      }
    ]
  }
]
DEFINITION
}


# ECS service  ####################################################################################

resource "aws_ecs_service" "api" {
  name            = "${var.owner}-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs.id]
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    
    # Since we're running on fargate using public subnets, we also need to get a public IP
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.default.arn
    container_name   = "${var.owner}-app"
    container_port   = 9000
  }

  depends_on = [aws_alb_listener.default]
}



# EC2 Security Group  ##########################################################################

resource "aws_security_group" "ecs" {
  name   = "${var.owner}-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 9000
    to_port     = 9000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-api-sg"
    },
  )
}


# EC2 Application Load Balancer ###################################################################

resource "aws_alb" "default" {
  name            = "${var.owner}-alb"
  security_groups = [aws_security_group.ecs.id]

  subnets = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id
  ]
}

resource "aws_alb_target_group" "default" {
  health_check {
    path = "/"
  }

  name     = "${var.owner}-tg"
  port     = 9000
  protocol = "HTTP"

  stickiness {
    type = "lb_cookie"
  }

  vpc_id = aws_vpc.vpc.id
  
  # We're targeting fargate, not an instance
  target_type = "ip"
}


resource "aws_alb_listener" "default" {
  default_action {
    target_group_arn = aws_alb_target_group.default.arn
    type             = "forward"
  }

  load_balancer_arn = aws_alb.default.arn
  port              = 9000
  protocol          = "HTTP"
}


# Outputs #########################################################################################

output "load_balancer_dns" {
  value = aws_alb.default.dns_name
}
