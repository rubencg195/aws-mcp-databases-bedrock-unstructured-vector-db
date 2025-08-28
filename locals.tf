locals {
    project_name           = "mcp-demo"

    # VPC Configuration
    vpc_name               = local.project_name
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
        # "knowledge-base-1.csv",
        "asset-replacements.csv",
        "asset-replacements.csv.metadata.json",
        # "asset-replacements.xlsm"
    ]
    knowledge_base_input_data_prefix = "input-data/"
    # mcp_client_model_arn   = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0" # ONLY 3 AND 3.5 ARE AVAILABLE FOR ON DEMAND
    mcp_client_model_arn   = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0" # ONLY 3 AND 3.5 ARE AVAILABLE FOR ON DEMAND
    embedding_model_arn    = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.titan-embed-text-v2:0"
    knowledge_base_bucket_storage_uri = "s3://${aws_s3_bucket.knowledge_base_storage.bucket}/"

    # RDS Configuration
    rds_instance_class = "db.r6g.large"
    rds_allocated_storage = 20
    rds_max_allocated_storage = 100
    rds_backup_retention_period = 7
    rds_embedding_dimensions = 1024

    tags = {
        Owner      = "rubencg195@hotmail.com"
        Project     = local.project_name
        Environment = "dev"
        ManagedBy   = "Terraform"
        Role        = "terraform"
    }
}