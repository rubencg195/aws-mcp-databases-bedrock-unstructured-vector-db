terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.4.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.3"
    }
    archive = {
      source = "hashicorp/archive"
      version = "2.7.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}