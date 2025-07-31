resource "aws_iam_role" "lambda_bedrock_role" {
  name = "${local.project_name}-lambda-bedrock-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_policy" "lambda_bedrock_policy" {
  name        = "${local.project_name}-lambda-bedrock-policy"
  description = "Policy for Lambda to invoke Bedrock models"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
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
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = aws_bedrockagent_knowledge_base.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock_attach" {
  role       = aws_iam_role.lambda_bedrock_role.name
  policy_arn = aws_iam_policy.lambda_bedrock_policy.arn
}