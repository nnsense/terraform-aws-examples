locals {
  common_tags = {
    deployment = lower("${var.stage}-${var.environment}")
    release    = var.release
    owner      = var.owner
  }
}

