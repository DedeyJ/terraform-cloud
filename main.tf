terraform {
  ### Two required providers, AWS for setting up in cloud and docker to help build Docker Images
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
  ### This Bucket is setup before running Terraform. bucket and region should be set correctly here. 
  backend "s3" {
    bucket = "bucket name"
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
