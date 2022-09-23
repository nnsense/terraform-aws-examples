# Ubuntu AMI

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}



# EC2 Security Group  ##########################################################################

resource "aws_security_group" "ecs" {
  name   = "${var.owner}-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
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
      Name = "${var.owner}-app-sg"
    },
  )
}




# EC2 launch configuration  #######################################################################

resource "aws_launch_configuration" "default" {
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "${var.owner}-lc-"

  security_groups = [aws_security_group.ecs.id]
}



# EC2 AutoScaling Group ###########################################################################

resource "aws_autoscaling_group" "default" {
  desired_capacity     = 1
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.default.name
  max_size             = 5
  min_size             = 1
  name                 = "${var.owner}-asg"

  dynamic "tag" {
    for_each = local.common_tags

    content {
      key    =  tag.key
      value   =  tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.owner}-ecs-instances"
  }

  termination_policies = ["OldestInstance"]

  vpc_zone_identifier = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id
  ]
}

