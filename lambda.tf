# Create the Lambda function directory and Python file using templatefile
resource "local_file" "lambda_bedrock_invoke_py" {
  content = templatefile("${path.module}/lambda.py.tmpl", {
    bedrock_region = data.aws_region.current.region
    knowledge_base_bucket = local.knowledge_base_bucket_name
  })
  filename = "${path.module}/lambda/bedrock_invoke/lambda_function.py"
}

# Create __init__.py file for the Lambda package
resource "local_file" "lambda_init_py" {
  content  = ""
  filename = "${path.module}/lambda/bedrock_invoke/__init__.py"
}

data "archive_file" "lambda_bedrock_invoke_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/bedrock_invoke"
  output_path = "${path.module}/lambda/bedrock_invoke.zip"
  depends_on  = [local_file.lambda_bedrock_invoke_py, local_file.lambda_init_py]
}

resource "aws_lambda_function" "bedrock_invoke" {
  function_name    = "${local.project_name}-bedrock-invoke"
  role             = aws_iam_role.lambda_bedrock_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_bedrock_invoke_zip.output_path
  source_code_hash = data.archive_file.lambda_bedrock_invoke_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256
  environment {
    variables = {
      BEDROCK_REGION = data.aws_region.current.region
      KNOWLEDGE_BASE_ID = aws_bedrockagent_knowledge_base.main.id
      MODEL_ARN = local.mcp_client_model_arn
      LOG_LEVEL = "INFO"
    }
  }
  tags = local.tags
}