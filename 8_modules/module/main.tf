module "infrastructure" {
  source                  = "./infrastructure"
  vpc_cidr_block          = var.vpc_cidr_block
  vpc_subnet1_cidr_block  = var.vpc_subnet1_cidr_block
  enable_dns_hostnames    = var.enable_dns_hostnames
  map_public_ip_on_launch = var.map_public_ip_on_launch
  stage                   = var.stage
  release                 = var.release
  owner                   = var.owner
}
