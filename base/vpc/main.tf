terraform {
  backend "s3" {
  bucket = "max-terraform"
  key    = "vpc/terraform.tfstate"
  region = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  }
  required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
  }
}

provider "aws" {
  region = var.region
}

locals {
  private_subnets = ["PRIVATE-SUBNET-A", "PRIVATE-SUBNET-B"]
  subnet_cidr_blocks = ["10.0.0.0/26", "10.0.0.64/26"]
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "private_subnet" {
    count = length(local.private_subnets)
    vpc_id = aws_vpc.vpc.id
    cidr_block = local.subnet_cidr_blocks[count.index]
    tags = {
      Name = "${local.private_subnets[count.index]}"
    }
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "main" {
  count = length(local.private_subnets)
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}