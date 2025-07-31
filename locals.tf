locals {
    project_name = "aws-mcp-bedrock-demo"
    region       = "us-east-1"

    # VPC Configuration
    vpc_name               = "main-vpc"  
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
    mcp_client_model_id   = "anthropic.claude-3-5-sonnet-20241022-v2:0"
    embedding_model_arn   = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    knowledge_base_bucket_storage_uri = "s3://${aws_s3_bucket.knowledge_base_storage.bucket}/"

    # OpenSearch Configuration
    opensearch_collection_name = "${local.project_name}-collection"
    opensearch_policy_encryption_name = "${local.project_name}-kms"
    opensearch_policy_network_name = "${local.project_name}-network"
    opensearch_access_policy_name = "${local.project_name}-access"
    opensearch_index_name = "default-index"
    opensearch_vectorfield = "default-vector-field"
    opensearch_mappingtextfield = "AMAZON_BEDROCK_TEXT_CHUNK"
    opensearch_mappingmetadatafield = "AMAZON_BEDROCK_METADATA"
    opensearch_embedding_dimensions = 1024

    tags = {
        Owner      = "rubencg195@hotmail.com"
        Project     = local.project_name
        Environment = "dev"
        ManagedBy   = "Terraform"
        Role        = "terraform"
    }
}