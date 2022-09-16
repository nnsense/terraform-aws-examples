variable "owner" {
  type        = string
  description = "Deployment's owner"
  default     = "username"
}

variable "aws_region" {
  type        = string
  description = "Region for AWS Resources"
  default     = "eu-west-1"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
  default     = true
}

variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR Block for VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_subnet1_cidr_block" {
  type        = string
  description = "CIDR Block for Subnet 1 in VPC"
  default     = "10.0.0.0/24"
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Map a public IP address for Subnet instances"
  default     = true
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "stage" {
  type        = string
  description = "Deployment stage"
  default     = "DEV"
}

variable "release" {
  type        = string
  description = "Deployment release"
  default     = "0.1"
}

variable "environment" {
  type        = string
  description = "Deployment release"
  default     = "EU"
}

variable "ecr_image" {
  type        = string
  description = "ECR image:tag to deploy"
}
