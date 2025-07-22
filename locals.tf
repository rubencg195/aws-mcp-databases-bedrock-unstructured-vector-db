locals {
    project_name = "aws-mcp-bedrock-demo"
    region       = "us-east-1"

    # VPC Configuration
    cidr_block             = "10.0.0.0/16"
    enable_dns_support     = true
    enable_dns_hostnames   = true
    destination_cidr_block = "0.0.0.0/0"
    number_of_subnets      = 4
    flow_logs_retention    = 30


    # Knowledge Base Configuration
    knowledge_base_bucket_name = "${local.project_name}-knowledge-base"
    knowledge_base_local_folder = "knowledge-bases"
    knowledge_base_csv_files = [
        "knowledge-base-1.csv",
    ]

    tags = {
        Owner      = "rubencg195@hotmail.com"
        Project     = local.project_name
        Environment = "dev"
        ManagedBy   = "Terraform"
        Role        = "terraform"
    }
}