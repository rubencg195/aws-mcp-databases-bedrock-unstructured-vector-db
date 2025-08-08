# Bedrock Knowledge Base Configuration
resource "aws_bedrockagent_knowledge_base" "main" {
  name        = "${local.project_name}-knowledge-base"
  description = "Knowledge base for MCP client"
  role_arn    = aws_iam_role.bedrock_knowledge_base_role.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = local.embedding_model_arn

             embedding_model_configuration {
         bedrock_embedding_model_configuration {
           dimensions          = local.rds_embedding_dimensions
           embedding_data_type = "FLOAT32"
         }
       }

      supplemental_data_storage_configuration {
        storage_location {
          type = "S3"
          s3_location {
            uri = local.knowledge_base_bucket_storage_uri
          }
        }
      }
    }
  }

  storage_configuration {
    type = "RDS"
    rds_configuration {
      resource_arn = aws_rds_cluster.bedrock_vector_store.arn
      credentials_secret_arn = aws_secretsmanager_secret.rds_credentials.arn
      database_name = aws_rds_cluster.bedrock_vector_store.database_name
      table_name = "bedrock_vectors"
      field_mapping {
        primary_key_field = "id"
        vector_field   = "embedding"
        text_field     = "content"
        metadata_field = "metadata"
      }
    }
  }

  depends_on = [
    aws_rds_cluster.bedrock_vector_store,
    aws_rds_cluster_instance.bedrock_vector_store,
    aws_secretsmanager_secret.rds_credentials,
    aws_secretsmanager_secret_version.rds_credentials,
    aws_kms_key.bedrock_knowledge_base_key,
    aws_s3_bucket.knowledge_base_input_data,
    aws_s3_bucket.knowledge_base_storage
  ]

  tags = local.tags
}


# KMS Key for Bedrock Knowledge Base (still needed for RDS)
resource "aws_kms_key" "bedrock_knowledge_base_key" {
  description = "KMS key for Bedrock Knowledge Base"
  key_usage = "ENCRYPT_DECRYPT"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {   
          AWS = [
            aws_iam_role.bedrock_knowledge_base_role.arn,
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            data.aws_caller_identity.current.arn
          ]
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
  tags = local.tags
}

resource "aws_kms_alias" "bedrock_knowledge_base_key_alias" {
  name = "alias/${local.project_name}-bedrock-kb"
  target_key_id = aws_kms_key.bedrock_knowledge_base_key.key_id
}

resource "aws_bedrockagent_data_source" "example" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = local.project_name
  data_deletion_policy = "RETAIN"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.knowledge_base_input_data.arn
      inclusion_prefixes = [local.knowledge_base_input_data_prefix]
    }
  }
  vector_ingestion_configuration {
    chunking_configuration {
      # SEMANTIC CHUNKING
      # chunking_strategy = "SEMANTIC" 
      # semantic_chunking_configuration {
      #   breakpoint_percentile_threshold = 90
      #   buffer_size = 1
      #   max_token = 1024
      # }

      # FIXED SIZE CHUNKING
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens = 4096
        overlap_percentage = 1
      }

      # HIERARCHICAL CHUNKING
      # chunking_strategy = "HIERARCHICAL"
      # hierarchical_chunking_configuration {
      #   overlap_tokens = 100
      #   level_configuration {
      #     max_tokens = 1024
      #   }
      # }

    }
  }
  depends_on = [
    aws_bedrockagent_knowledge_base.main
  ]
}

# IAM Role for Bedrock Knowledge Base
resource "aws_iam_role" "bedrock_knowledge_base_role" {
  name = "${local.project_name}-bedrock-kb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# IAM Policy for Bedrock Knowledge Base
resource "aws_iam_role_policy" "bedrock_knowledge_base_policy" {
  name = "${local.project_name}-bedrock-kb-policy"
  role = aws_iam_role.bedrock_knowledge_base_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
         aws_s3_bucket.knowledge_base_input_data.arn,
          "${aws_s3_bucket.knowledge_base_input_data.arn}/*",
          aws_s3_bucket.knowledge_base_storage.arn,
          "${aws_s3_bucket.knowledge_base_storage.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterParameters",
          "rds:DescribeDBParameters"
        ]
        Resource = aws_rds_cluster.bedrock_vector_store.arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        Resource = aws_rds_cluster.bedrock_vector_store.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          local.embedding_model_arn,
          "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:*"
        ]
        Resource = [
          aws_kms_key.bedrock_knowledge_base_key.arn
        ]
      }
    ]
  })
}
