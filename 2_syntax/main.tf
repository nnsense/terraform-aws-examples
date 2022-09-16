provider "aws" {
  region     = var.aws_region
}

#################### Variables


variable "aws_region" {
  type        = string
  description = "Region for AWS Resources"
  default     = "eu-west-1"
}

variable "stage" {
  type        = string
  description = "Deployment stage"
  default     = "DEV"
}

variable "env" {
  type        = string
  description = "Deployment CI target"
  default     = "EU"
}

variable "tags" {
  type     = map
  default  = {
    Name = "Rebura"
    Stage = "Final"
  }
}

variable "names" {
  type     = list(string)
  default  = [ "alfa", "bravo" , "charlie" ]
}


#################### Local variables

locals {
  common_tags = {
    release      = "${var.env}-${var.stage}"
  }

  specs = {
    alfa    = "sg-123123123"
    bravo   = "sg-511351351"
    charlie = "sg-123141242"
  }

  types = [ "t3.micro", "t3.large", "m5.nano"  ]

}


################### Fake resource

resource "null_resource" "null_resource_map" {
    for_each = local.specs
    provisioner "local-exec" {
        command = "echo ${each.key} - ${each.value}"
    }
}


resource "null_resource" "null_resource_list" {
    for_each = toset( local.types )
    provisioner "local-exec" {
        command = "echo ${each.key}"
    }
}

resource "null_resource" "null_resource_count" {
    count = 3
    provisioner "local-exec" {
        command = "echo ${count.index}"
    }
}


################### Showing

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = ["vpc-0932acf5a45deedea"]
  }
}


################### Outputs

output "deployment_name" {
  value = local.common_tags["release"]
}

output "consistent_deployment_name" {
  value = lower(local.common_tags["release"])
}

output "deployment_location" {
  value = "Deployment: %{ if var.env == "EU" }Europe region%{ else }US%{ endif }"
}

output "deployment_list" {
  value = null_resource.null_resource_list[*]
}

output "subnets" {
  value = data.aws_subnets.example[*].ids
}

