# ECS Cluster  ####################################################################################

resource "aws_ecs_cluster" "cluster" {
  name = "${var.owner}-cluster"
  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-cluster"
    },
  )
}





# ECS Task Definition  ############################################################################

data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.owner}-app"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
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
    "cpu": 512,
    "memory": 512,
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





# EC2 instance role  ##############################################################################

resource "aws_ecs_service" "api" {
  name            = "${var.owner}-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "EC2"
}


data "aws_iam_policy_document" "ecs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ecs" {
  assume_role_policy = data.aws_iam_policy_document.ecs.json
  name               = "${var.owner}-ecsInstanceRole"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs.name
}





# EC2 AMI  ###########################################################################################

data "aws_ami" "default" {
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.202*-x86_64-ebs"]
  }

  most_recent = true
  owners      = ["amazon"]
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
}




# EC2 Instance  ##########################################################################

resource "aws_instance" "ecs" {
  ami                         = data.aws_ami.default.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.ecs.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ecs.name

  user_data = <<EOF
#!/bin/bash

echo ECS_CLUSTER=${var.owner}-cluster >> /etc/ecs/ecs.config
EOF

  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-ecs-instances"
    },
  )
}
