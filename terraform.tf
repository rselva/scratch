terraform {
  required_version = "~> 1.9.5"

  backend "s3" {
    region               = "us-east-1"
    bucket               = "terraform-backend-290196769792-us-east-1"
    dynamodb_table       = "terraform-backend-locks"
    encrypt              = true
    key                  = "terraform.tfstate"
    workspace_key_prefix = "scratch"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = lookup(var.deploy_role_arn, terraform.workspace)
  }

  default_tags {
    tags = {
      "user:CostCenter"  = "kvhmgr",
      "user:Terminal"    = "na",
      "user:Application" = "scratch",
      "user:Stack"       = terraform.workspace
    }
  }
}
