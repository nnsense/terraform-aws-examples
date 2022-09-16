resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-vpc"
    },
  )
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-igw"
    },
  )
}


resource "aws_subnet" "subnet1" {
  cidr_block              = var.vpc_subnet1_cidr_block
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-subnet1"
    },
  )
}

resource "aws_subnet" "subnet2" {
  cidr_block              = var.vpc_subnet2_cidr_block
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = "${var.aws_region}b"

  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-subnet2"
    },
  )
}



resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags,
    {
      Name = "${var.owner}-pub-rtb"
    },
  )
}


resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rta-subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rtb.id
}

