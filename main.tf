terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  
  }
  backend "s3" {
    bucket = "dedeyjbucket"
    key    = "test/terraform.tfstate"
    region = "eu-west-1"
  }
  required_version = ">= 1.5"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

provider "docker" {
}
