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
          dimensions          = local.opensearch_embedding_dimensions
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
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      vector_index_name = local.opensearch_index_name
      collection_arn    = aws_opensearchserverless_collection.knowledge_base.arn
      field_mapping {
        vector_field   = local.opensearch_vectorfield
        text_field     = local.opensearch_mappingtextfield
        metadata_field = local.opensearch_mappingmetadatafield
      }
    }
  }

  depends_on = [
    aws_opensearchserverless_collection.knowledge_base,
    aws_opensearchserverless_security_policy.knowledge_base_encryption,
    aws_opensearchserverless_security_policy.knowledge_base_network,
    aws_opensearchserverless_access_policy.knowledge_base,
    aws_kms_key.bedrock_knowledge_base_key,
    local_file.opensearch_collection_info,
    aws_s3_bucket.knowledge_base_input_data,
    aws_s3_bucket.knowledge_base_storage
  ]

  tags = local.tags
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
          "aoss:APIAccessAll"
        ]
        Resource = aws_opensearchserverless_collection.knowledge_base.arn
      },
      {
        Effect = "Allow"
        Action = [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ListIndices",
          "aoss:CreateCollection",
          "aoss:DeleteCollection",
          "aoss:UpdateCollection",
          "aoss:DescribeCollection",
          "aoss:ListCollections"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          local.embedding_model_arn,
          "arn:aws:bedrock:${local.region}::foundation-model/*"
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

# TODO: Automate the ingestion of data into the Bedrock Knowledge Base
# resource "null_resource" "ingest_data_into_bedrock_knowledge_base" {
#   triggers = {
#     collection_id = aws_opensearchserverless_collection.knowledge_base.id
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       aws bedrock-agent create-data-source \
#     --knowledge-base-id "${aws_bedrockagent_knowledge_base.main.name}" \
#     --name "MyS3DataSource" \
#     --data-source-configuration \
#     "type=S3,s3Configuration={bucketArn=\'arn:aws:s3:::${aws_s3_bucket.knowledge_base_input_data.bucket}',inclusionPrefixes=[\'input-data/']}" \
#     --vector-ingestion-configuration "chunkingStrategy=FIXED_SIZE,fixedSizeChunkingConfiguration={maxTokens=500,overlapTokens=100}"
#     EOT
#   }

#   depends_on = [
#     aws_s3_bucket.knowledge_base_input_data,
#     aws_s3_object.csv_upload,
#     aws_bedrockagent_knowledge_base.main,
#   ]
# }
