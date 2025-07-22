locals {
    # VPC Configuration
    cidr_block             = "10.0.0.0/16"
    enable_dns_support     = true
    enable_dns_hostnames   = true
    destination_cidr_block = "0.0.0.0/0"
    number_of_subnets      = 4
    flow_logs_retention    = 30


    tags = {
        Owner      = "rubencg195@hotmail.com"
        Project     = "aws-mcp-demo"
        Environment = "dev"
        ManagedBy   = "Terraform"
        Role        = "terraform"
    }
}