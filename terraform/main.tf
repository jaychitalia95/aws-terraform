terraform {
  backend "s3" {
    bucket         = "max-terraform"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
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
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform" {
  bucket              = "max-terraform"
  object_lock_enabled = false
  tags = {
    "PROCESS" = "Terraform"
  }
}

resource "aws_dynamodb_table" "terraform" {
  name                        = "terraform-state-lock"
  hash_key                    = "LockID"
  billing_mode                = "PROVISIONED"
  read_capacity               = 1
  write_capacity              = 1
  deletion_protection_enabled = true
  tags = {
    "PROCESS" = "Terraform"
  }
  attribute {
    name = "LockID"
    type = "S"
  }
}