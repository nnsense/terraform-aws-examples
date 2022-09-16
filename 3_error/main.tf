#################### Variables


variable "aws_region" {
  type        = string
  description = "Region for AWS Resources"
  default     = "eu-west-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR Block for VPC"
  default     = "10.0.0.0/20"
}


#################### Provider


provider "aws" {
  region = var.aws_region
}


#################### Infrastructure


resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.0.0/24"
  vpc_id     = aws_vpc.vpc.id
}

####################### Break between plan and apply !

data "aws_subnets" "subnet_ids" {
  depends_on = [resource.aws_vpc.vpc]
  filter {
    name   = "vpc-id"
    values = [resource.aws_vpc.vpc.id]
  }
}


resource "aws_internet_gateway" "igw" {
  count  = length(data.aws_subnets.subnet_ids.ids)
  vpc_id = aws_vpc.vpc.id
}

