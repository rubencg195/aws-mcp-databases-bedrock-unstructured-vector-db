terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.6.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.3"
    }
    archive = {
      source = "hashicorp/archive"
      version = "2.7.1"
    }
    # opensearch = {
    #   source = "opensearch-project/opensearch"
    #   version = "2.3.2"
    # }
  }
}

provider "aws" {
  region = "us-east-1"
}


# TODO: Find a way to automate the creation of the index in OpenSearch. Currently the credentials are failing to be fetched
# provider "opensearch" { 
#   url         = aws_opensearchserverless_collection.knowledge_base.collection_endpoint 
#   healthcheck = false 
#   aws_region  = "us-east-1" 
#   # aws_profile = "default" 
#   # sign_aws_requests = true
#   aws_access_key_id     = "ccccc"
#   aws_secret_access_key = "cccc"
# }