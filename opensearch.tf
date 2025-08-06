# OpenSearch Serverless Collection
resource "aws_opensearchserverless_collection" "knowledge_base" {
  name = local.opensearch_collection_name
  type = "VECTORSEARCH"
  
  depends_on = [
    aws_opensearchserverless_security_policy.knowledge_base_encryption,
    aws_opensearchserverless_security_policy.knowledge_base_network,
    aws_opensearchserverless_access_policy.knowledge_base
  ]
  
  tags = local.tags
}

# # Create the OpenSearch index using AWS CLI
# resource "null_resource" "create_opensearch_index" {
#   triggers = {
#     collection_id = aws_opensearchserverless_collection.knowledge_base.id
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       aws opensearchserverless create-index \
#         --collection-id ${aws_opensearchserverless_collection.knowledge_base.id} \
#         --name ${aws_opensearchserverless_collection.knowledge_base.name} \
#         --type VECTORSEARCH \
#         --region ${local.region}
#     EOT
#   }

#   depends_on = [
#     aws_opensearchserverless_collection.knowledge_base,
#     aws_opensearchserverless_security_policy.knowledge_base_encryption,
#     aws_opensearchserverless_security_policy.knowledge_base_network,
#     aws_opensearchserverless_access_policy.knowledge_base
#   ]
# }

# OpenSearch Serverless Encription Security Policy
resource "aws_opensearchserverless_security_policy" "knowledge_base_encryption" {
  name = local.opensearch_policy_encryption_name
  type        = "encryption"
  description = "encryption security policy using customer KMS key"

  policy = jsonencode({
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.opensearch_collection_name}",
          ]
        }
      ],
      AWSOwnedKey = false
      KmsARN      = aws_kms_key.bedrock_knowledge_base_key.arn
    })
}

# OpenSearch Serverless Network Security Policy
resource "aws_opensearchserverless_security_policy" "knowledge_base_network" {
  name = local.opensearch_policy_network_name
  type        = "network"
  description = "VPC access"

  policy = jsonencode([
      {
        Description = "VPC access to collection and Dashboards endpoint for example collection",
        Rules = [
          {
            ResourceType = "collection"
            Resource = [
              "collection/${local.opensearch_collection_name}",
            ]
          }
        ]
        AllowFromPublic = true
        # TODO: Lock down to VPC Endpoint
        # AllowFromPublic = false
        # SourceVPCEs = [
        #   "vpce-050f79086ee71ac05"
        # ]
    }
  ])
}


# OpenSearch Serverless Access Policy
resource "aws_opensearchserverless_access_policy" "knowledge_base" {
  name = local.opensearch_access_policy_name
  type = "data"
  policy = jsonencode([
    {
      Rules = [
         {
          ResourceType = "index"
          Resource = [
            "index/${local.opensearch_collection_name}/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.opensearch_collection_name}"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
          data.aws_caller_identity.current.arn,
          aws_iam_role.bedrock_knowledge_base_role.arn,
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/bedrock.amazonaws.com/AWSServiceRoleForBedrock",
          "bedrock.amazonaws.com"
      ]
    }
  ])
}

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
  name = "alias/${local.opensearch_collection_name}"
  target_key_id = aws_kms_key.bedrock_knowledge_base_key.key_id
}

resource "local_file" "opensearch_collection_info" {
  filename = "${path.module}/.opensearch_collection.txt"
  content  = <<EOT
OpenSearch Collection Endpoint:
${aws_opensearchserverless_collection.knowledge_base.collection_endpoint}

OpenSearch Collection ID:
${aws_opensearchserverless_collection.knowledge_base.id}

OpenSearch Collection ARN:
${aws_opensearchserverless_collection.knowledge_base.arn}
EOT
}

